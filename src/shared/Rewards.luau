--!strict
-- Rewards for coming back (docs/GAMEPLAY.md §13): the daily check-in, three daily quests and the online gifts. The server
-- runs them (server/Rewards) and publishes what the client draws (client/UiRewards); every claim is decided here.
--
-- A day is the UTC day (os.time() // 86400). A quest is measured from the farm's own lifetime counts: when the day's list
-- is made each quest keeps the count of that moment (`mark`), and its progress is the count now minus the mark, so
-- nothing else in the game has to report to it. Coins are a share of the price of the village's cheapest next upgrade.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Hatching = if script then require(script.Parent.Hatching) else require("./Hatching")
local VillageRules = if script then require(script.Parent.Village) else require("./Village")

type Farm = typeof(FarmState.newFarm(0))
type Quest = typeof(FarmState.newRewards().quests.list[1])

-- What a reward pays, as the client shows it: coins and minutes of the luck potion.
export type Grant = { coins: number, luck: number }

local R = Config.Rewards
local DAY = 86400
local MODULUS = 2147483647

local Rewards = {}

function Rewards.dayOf(now: number): number
	return math.floor(now / DAY)
end

-- Seconds until the next UTC midnight.
function Rewards.secondsLeft(now: number): number
	return DAY - math.floor(now) % DAY
end

-- ===== what a reward pays =====

-- Two figures: 1234 -> 1200, 155 -> 160.
local function nice(value: number): number
	if value < 10 then
		return math.floor(value + 0.5)
	end
	local magnitude = 10 ^ (math.floor(math.log10(value)) - 1)
	return math.floor(value / magnitude + 0.5) * magnitude
end

-- The price of the cheapest upgrade the village can still buy (the last price when every area is at the top).
function Rewards.coinBase(farm: Farm): number
	local best = math.huge
	for _, id in Config.Village.Areas do
		local level = (farm.areas :: any)[id].level
		if level < Config.Village.MaxLevel then
			best = math.min(best, VillageRules.upgradeCost(level))
		end
	end
	return if best == math.huge then VillageRules.upgradeCost(Config.Village.MaxLevel - 1) else best
end

-- A reward of Config (`{ coins = share, luck = minutes }`) as paid to this farm now.
function Rewards.grant(spec: { [string]: number }, farm: Farm): Grant
	local share = spec.coins or 0
	local coins = if share > 0 then math.max(R.CoinFloor, nice(share * Rewards.coinBase(farm))) else 0
	return { coins = coins, luck = spec.luck or 0 }
end

-- Pays a grant: coins (not held by the vault, like a sale) and luck potion minutes added to what is left.
function Rewards.pay(farm: Farm, grant: Grant, now: number)
	if grant.coins > 0 then
		farm.coins += grant.coins
		farm.lifetime.coinsEarned += grant.coins
	end
	if grant.luck > 0 then
		local from = math.max(now, farm.luckPotionUntil or 0)
		farm.luckPotionUntil = math.min(from + grant.luck * 60, now + R.LuckMaxMinutes * 60)
	end
end

-- ===== the daily check-in =====

-- The day of the run that today's check-in is (or was, once taken), and whether it was taken today.
function Rewards.dailyDay(farm: Farm, now: number): (number, boolean)
	local daily = farm.rewards.daily
	local today = Rewards.dayOf(now)
	if daily.day == today then
		return math.max(1, daily.streak), true
	elseif daily.day == today - 1 then
		return daily.streak % #R.Daily + 1, false
	end
	return 1, false
end

function Rewards.claimDaily(farm: Farm, now: number): (boolean, string?, number?)
	local day, taken = Rewards.dailyDay(farm, now)
	if taken then
		return false, "TAKEN"
	end
	local grant = Rewards.grant(R.Daily[day], farm)
	Rewards.pay(farm, grant, now)
	farm.rewards.daily = { streak = day, day = Rewards.dayOf(now) }
	return true, nil, grant.coins
end

-- ===== daily quests =====

-- The lifetime count a kind of quest measures.
function Rewards.count(farm: Farm, kind: string): number
	if kind == "breed" then
		return farm.lifetime.breeds
	elseif kind == "hatch" then
		return Hatching.totalHatched(farm.discoveries)
	elseif kind == "sell" then
		return farm.lifetime.slimesSold
	elseif kind == "feed" then
		return farm.lifetime.meals
	elseif kind == "win" then
		return farm.lifetime.mobsKilled
	elseif kind == "upgrade" then
		local total = 0
		for _, id in Config.Village.Areas do
			total += (farm.areas :: any)[id].level
		end
		return total
	end
	return 0
end

local function fits(farm: Farm, kind: string): boolean
	if kind == "sell" then
		return #farm.slimes >= R.QuestSellMinSlimes
	elseif kind == "upgrade" then
		return FarmState.villageLevel(farm.areas) < Config.Village.MaxLevel
	end
	return true
end

-- A seeded dice (Park-Miller): the same player on the same day always throws the same numbers (0 up to 1).
local function dice(seed: number, day: number): () -> number
	local state = (math.abs(math.floor(seed)) % MODULUS * 7919 + day * 104729 + 977) % (MODULUS - 1) + 1
	local function throw(): number
		state = state * 48271 % MODULUS
		return state / MODULUS
	end
	for _ = 1, 4 do
		throw()
	end
	return throw
end

-- The quests of one day for this farm: QuestCount different kinds that fit, quest n asking the n-th share of its range.
function Rewards.makeQuests(farm: Farm, seed: number, day: number): { Quest }
	local throw = dice(seed, day)
	local kinds = {}
	for _, kind in R.QuestKinds do
		if fits(farm, kind) then
			table.insert(kinds, kind)
		end
	end
	for place = #kinds, 2, -1 do
		local other = math.floor(throw() * place) + 1
		kinds[place], kinds[other] = kinds[other], kinds[place]
	end
	local list: { Quest } = {}
	for tier = 1, math.min(R.QuestCount, #kinds) do
		local kind = kinds[tier]
		local range = (R.QuestNeed :: any)[kind]
		local need = range[1] + (range[2] - range[1]) * (tier - 1) / math.max(1, R.QuestCount - 1)
		table.insert(
			list,
			{ kind = kind, need = math.floor(need + 0.5), mark = Rewards.count(farm, kind), claimed = false }
		)
	end
	return list
end

-- Makes today's quests if the farm has none for today (a new player gets them once the tutorial is over). Returns
-- whether it did.
function Rewards.ensureQuests(farm: Farm, seed: number, now: number): boolean
	local day = Rewards.dayOf(now)
	local quests = farm.rewards.quests
	if farm.tutorialDone == false or (quests.day == day and #quests.list > 0) then
		return false
	end
	farm.rewards.quests = { day = day, list = Rewards.makeQuests(farm, seed, day), bonus = false }
	return true
end

-- How far a quest is: never more than its need.
function Rewards.progress(farm: Farm, quest: Quest): number
	return math.clamp(Rewards.count(farm, quest.kind) - quest.mark, 0, quest.need)
end

function Rewards.questText(quest: Quest): string
	local n = quest.need
	local function many(one: string, more: string): string
		return if n == 1 then one else more
	end
	if quest.kind == "breed" then
		return "Lay " .. n .. many(" egg", " eggs")
	elseif quest.kind == "hatch" then
		return "Hatch " .. n .. many(" egg", " eggs")
	elseif quest.kind == "sell" then
		return "Sell " .. n .. many(" slime", " slimes")
	elseif quest.kind == "feed" then
		return "Slimes eat " .. n .. " meals"
	elseif quest.kind == "win" then
		return "Beat " .. n .. many(" zombie", " zombies")
	end
	return "Upgrade " .. n .. many(" time", " times")
end

local function todays(farm: Farm, now: number): boolean
	return farm.rewards.quests.day == Rewards.dayOf(now)
end

function Rewards.claimQuest(farm: Farm, index: number, now: number): (boolean, string?, number?)
	local quest = farm.rewards.quests.list[index]
	if not todays(farm, now) or not quest then
		return false, "NO_QUEST"
	elseif quest.claimed then
		return false, "TAKEN"
	elseif Rewards.progress(farm, quest) < quest.need then
		return false, "NOT_DONE"
	end
	local grant = Rewards.grant({ coins = R.QuestCoins[index] or R.QuestCoins[#R.QuestCoins] }, farm)
	Rewards.pay(farm, grant, now)
	quest.claimed = true
	return true, nil, grant.coins
end

-- 0: not every quest is claimed yet; 1: the bonus waits; 2: taken.
function Rewards.bonusState(farm: Farm, now: number): number
	local quests = farm.rewards.quests
	if not todays(farm, now) or #quests.list == 0 then
		return 0
	elseif quests.bonus then
		return 2
	end
	for _, quest in quests.list do
		if not quest.claimed then
			return 0
		end
	end
	return 1
end

function Rewards.claimBonus(farm: Farm, now: number): (boolean, string?, number?)
	local state = Rewards.bonusState(farm, now)
	if state == 2 then
		return false, "TAKEN"
	elseif state == 0 then
		return false, "NOT_DONE"
	end
	local grant = Rewards.grant(R.QuestBonus, farm)
	Rewards.pay(farm, grant, now)
	farm.rewards.quests.bonus = true
	return true, nil, grant.coins
end

-- ===== online gifts =====

-- Adds `elapsed` seconds of play ending now. A new UTC day starts the clock and the gifts again, counting only the part of
-- `elapsed` after midnight.
function Rewards.addPlayed(farm: Farm, now: number, elapsed: number)
	local online = farm.rewards.online
	local today = Rewards.dayOf(now)
	local seconds = math.max(0, elapsed)
	if online.day ~= today then
		farm.rewards.online = { day = today, secs = math.min(seconds, now - today * DAY), claimed = {} }
	else
		online.secs += seconds
	end
end

-- Seconds played today, as saved (the server adds the time since its last write before every check).
function Rewards.played(farm: Farm, now: number): number
	local online = farm.rewards.online
	return if online.day == Rewards.dayOf(now) then online.secs else 0
end

function Rewards.onlineTaken(farm: Farm, now: number, step: number): boolean
	return farm.rewards.online.day == Rewards.dayOf(now) and table.find(farm.rewards.online.claimed, step) ~= nil
end

function Rewards.claimOnline(farm: Farm, step: number, now: number): (boolean, string?, number?)
	local gift = R.Online[step]
	if not gift then
		return false, "NO_GIFT"
	elseif Rewards.onlineTaken(farm, now, step) then
		return false, "TAKEN"
	elseif Rewards.played(farm, now) < gift.minutes * 60 then
		return false, "NOT_YET"
	end
	local grant = Rewards.grant(gift :: any, farm)
	Rewards.pay(farm, grant, now)
	table.insert(farm.rewards.online.claimed, step)
	return true, nil, grant.coins
end

-- ===== what waits =====

-- How many rewards can be claimed now (the badge on the Rewards button). `unsaved`: seconds played that the server has not
-- written into the save yet.
function Rewards.ready(farm: Farm, now: number, unsaved: number?): number
	local count = 0
	if not select(2, Rewards.dailyDay(farm, now)) then
		count += 1
	end
	if todays(farm, now) then
		for _, quest in farm.rewards.quests.list do
			if not quest.claimed and Rewards.progress(farm, quest) >= quest.need then
				count += 1
			end
		end
	end
	if Rewards.bonusState(farm, now) == 1 then
		count += 1
	end
	local played = Rewards.played(farm, now) + (unsaved or 0)
	for step, gift in R.Online do
		if played >= gift.minutes * 60 and not Rewards.onlineTaken(farm, now, step) then
			count += 1
		end
	end
	return count
end

-- Whether the player ever took a reward (the rewards intro is done then).
function Rewards.everClaimed(farm: Farm): boolean
	local rewards = farm.rewards
	if rewards.daily.day > 0 or #rewards.online.claimed > 0 then
		return true
	end
	for _, quest in rewards.quests.list do
		if quest.claimed then
			return true
		end
	end
	return false
end

-- How many kinds of slime the farm has found (the Index), every bucket together.
function Rewards.found(farm: Farm): number
	local count = 0
	for _, bucket in
		{ farm.discoveries.base, farm.discoveries.dual, farm.discoveries.secret, farm.discoveries.material }
	do
		for _ in bucket do
			count += 1
		end
	end
	return count
end

-- What the client draws, as plain rows (the server sends them as JSON): the check-in's seven days, today's quests and the
-- bonus, the online gifts. Coins are what a claim would pay now.
function Rewards.view(farm: Farm, now: number): { [string]: any }
	local day, taken = Rewards.dailyDay(farm, now)
	local daily = {}
	for _, spec in R.Daily do
		local grant = Rewards.grant(spec, farm)
		table.insert(daily, { grant.coins, grant.luck })
	end
	local quests: { { any } } = {}
	if todays(farm, now) then
		for index, quest in farm.rewards.quests.list do
			local grant = Rewards.grant({ coins = R.QuestCoins[index] or 0 }, farm)
			local row: { any } = {
				Rewards.questText(quest),
				Rewards.progress(farm, quest),
				quest.need,
				quest.claimed,
				grant.coins,
				quest.kind,
			}
			table.insert(quests, row)
		end
	end
	local online: { { any } } = {}
	for step, gift in R.Online do
		local grant = Rewards.grant(gift :: any, farm)
		local row: { any } = { gift.minutes, grant.coins, grant.luck, Rewards.onlineTaken(farm, now, step) }
		table.insert(online, row)
	end
	local bonus = Rewards.grant(R.QuestBonus, farm)
	return {
		day = day,
		taken = taken,
		daily = daily,
		quests = quests,
		bonus = { Rewards.bonusState(farm, now), bonus.coins, bonus.luck },
		online = online,
		-- (the server time of the next midnight: new quests, a new check-in, the gifts again)
		reset = (Rewards.dayOf(now) + 1) * DAY,
	}
end

return Rewards
