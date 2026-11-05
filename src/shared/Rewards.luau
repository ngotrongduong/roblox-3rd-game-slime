--!strict
-- Rewards for coming back (docs/GAMEPLAY.md §13, docs/MONETIZATION.md §4): the daily check-in and its milestones, four daily
-- quests with a free redraw, weekly quests and their chest, the online gifts and the Goals. The server runs them
-- (server/Rewards) and publishes what the client draws (client/UiRewards); every claim is decided here. The Lucky Wheel
-- (shared/Wheel) pays through the same grant and pay.
--
-- A day is the UTC day (os.time() // 86400), a week the Arena's (Monday 00:00 UTC). A quest is measured from the farm's own
-- lifetime counts: when the day's list is made each quest keeps the count of that moment (`mark`), and its progress is the
-- count now minus the mark, so nothing else in the game has to report to it. Coins are a share of the price of the
-- village's cheapest next upgrade.
local ArenaSeason = if script then require(script.Parent.ArenaSeason) else require("./ArenaSeason")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Gear = if script then require(script.Parent.Gear) else require("./Gear")
local Hatching = if script then require(script.Parent.Hatching) else require("./Hatching")
local VillageRules = if script then require(script.Parent.Village) else require("./Village")

type Farm = typeof(FarmState.newFarm(0))
type Quest = typeof(FarmState.newRewards().quests.list[1])

-- One thing a reward pays besides coins: kind "food" | "dish" | "material" | "gear", the id in its Config table, how many.
export type Item = { kind: string, id: string, count: number }
-- What a reward pays, as the client shows it: coins, minutes of the luck potion, wheel spins and items.
export type Grant = { coins: number, luck: number, spins: number?, items: { Item }? }

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

-- A reward of Config (`{ coins = share, luck = minutes, spins = n, items = { ... } }`) as paid to this farm now.
function Rewards.grant(spec: any, farm: Farm): Grant
	local share = spec.coins or 0
	local coins = if share > 0 then math.max(R.CoinFloor, nice(share * Rewards.coinBase(farm))) else 0
	local items: { Item } = {}
	if spec.items then
		for _, item in spec.items do
			table.insert(items, { kind = item.kind, id = item.id, count = item.count })
		end
	end
	return { coins = coins, luck = spec.luck or 0, spins = spec.spins or 0, items = items }
end

-- One item into the farm, the way the game already keeps it: a material in farm.materials, a piece of gear in the bag, a
-- raw food in the storehouse and a dish in the fridge (what does not fit is lost). Returns how many did not go in.
local function payItem(farm: Farm, item: Item): number
	local count = math.floor(item.count)
	if count < 1 then
		return 0
	end
	if item.kind == "material" then
		local known = (Config.Dungeon.Materials :: any)[item.id]
		if known and known.kind == "material" then
			farm.materials[item.id] = (farm.materials[item.id] or 0) + count
			return 0
		end
	elseif item.kind == "gear" then
		if Gear.give(farm, item.id, count) then
			return 0
		end
	elseif item.kind == "food" and (Config.Food.Raw :: any)[item.id] ~= nil then
		local moved = Food.add(farm.storehouse, item.id, count, Food.storehouseCapacity(farm.areas.pantry.level))
		return count - moved
	elseif item.kind == "dish" and (Config.Food.Dishes :: any)[item.id] ~= nil then
		local moved = Food.add(farm.fridge, item.id, count, Food.fridgeCapacity(farm.areas.kitchen.level))
		return count - moved
	end
	warn(Config.LogPrefix, "rewards: unknown item", item.kind, item.id)
	return 0
end

-- Pays a grant: coins (not held by the vault, like a sale), luck potion minutes added to what is left, spins into the
-- wheel's bank and the items. Returns how many food or dishes did not fit.
function Rewards.pay(farm: Farm, grant: Grant, now: number): number
	if grant.coins > 0 then
		farm.coins += grant.coins
		farm.lifetime.coinsEarned += grant.coins
	end
	if grant.luck > 0 then
		local from = math.max(now, farm.luckPotionUntil or 0)
		farm.luckPotionUntil = math.min(from + grant.luck * 60, now + R.LuckMaxMinutes * 60)
	end
	local spins = grant.spins or 0
	if spins > 0 then
		local wheel = farm.rewards.wheel
		wheel.bank = math.min(wheel.bank + spins, Config.Wheel.BankCap)
	end
	local lost = 0
	local items: { Item } = grant.items or {}
	for _, item in items do
		lost += payItem(farm, item)
	end
	return lost
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
	farm.rewards.checkins += 1
	return true, nil, grant.coins
end

-- 0: not enough check-ins yet; 1: it waits; 2: taken.
function Rewards.milestoneState(farm: Farm, index: number): number
	local milestone = R.CheckinMilestones[index]
	if not milestone then
		return 0
	elseif table.find(farm.rewards.milestones, index) then
		return 2
	end
	return if farm.rewards.checkins >= milestone.total then 1 else 0
end

function Rewards.claimMilestone(farm: Farm, index: number, now: number): (boolean, string?, number?)
	if not R.CheckinMilestones[index] then
		return false, "NO_MILESTONE"
	end
	local state = Rewards.milestoneState(farm, index)
	if state == 2 then
		return false, "TAKEN"
	elseif state == 0 then
		return false, "NOT_DONE"
	end
	local grant = Rewards.grant(R.CheckinMilestones[index], farm)
	Rewards.pay(farm, grant, now)
	table.insert(farm.rewards.milestones, index)
	return true, nil, grant.coins
end

-- ===== daily quests =====

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

-- The lifetime count a kind of quest (or goal) measures.
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
	elseif kind == "wave" then
		return farm.lifetime.dungeonWaves
	elseif kind == "arena" then
		return farm.lifetime.arenaAttacks
	elseif kind == "craft" then
		return farm.lifetime.gearCrafted
	elseif kind == "cook" then
		return farm.lifetime.dishesCooked
	elseif kind == "fish" then
		return farm.lifetime.fishCaught
	elseif kind == "harvest" then
		return farm.lifetime.cropsHarvested
	elseif kind == "find" then
		return Rewards.found(farm)
	elseif kind == "spin" then
		return farm.lifetime.wheelSpins
	elseif kind == "play" then
		return math.floor(farm.lifetime.secsPlayed / 60)
	end
	return 0
end

-- Whether a slime works in the area (a cook, an angler or a gardener).
local function worked(farm: Farm, area: string): boolean
	for _, slot in (farm.work :: any)[area].slots do
		if slot.worker then
			return true
		end
	end
	return false
end

local function fits(farm: Farm, kind: string): boolean
	if kind == "sell" then
		return #farm.slimes >= R.QuestSellMinSlimes
	elseif kind == "upgrade" then
		return FarmState.villageLevel(farm.areas) < Config.Village.MaxLevel
	end
	local least = (R.QuestMinVillage :: any)[kind]
	if least and FarmState.villageLevel(farm.areas) < least then
		return false
	end
	local area = (R.QuestWorkArea :: any)[kind]
	if area and not worked(farm, area) then
		return false
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

-- The quest of this kind that tier n of QuestCount asks: the n-th share of the kind's range, counted from now.
local function newQuest(farm: Farm, kind: string, tier: number): Quest
	local range = (R.QuestNeed :: any)[kind]
	local need = range[1] + (range[2] - range[1]) * (tier - 1) / math.max(1, R.QuestCount - 1)
	return { kind = kind, need = math.floor(need + 0.5), mark = Rewards.count(farm, kind), claimed = false }
end

-- The kinds that fit the farm, in a shuffle that is the same for the same dice.
local function shuffledKinds(farm: Farm, throw: () -> number, skip: { [string]: boolean }?): { string }
	local kinds = {}
	for _, kind in R.QuestKinds do
		if fits(farm, kind) and not (skip and skip[kind]) then
			table.insert(kinds, kind)
		end
	end
	for place = #kinds, 2, -1 do
		local other = math.floor(throw() * place) + 1
		kinds[place], kinds[other] = kinds[other], kinds[place]
	end
	return kinds
end

-- The quests of one day for this farm: QuestCount different kinds that fit, quest n asking the n-th share of its range.
function Rewards.makeQuests(farm: Farm, seed: number, day: number): { Quest }
	local kinds = shuffledKinds(farm, dice(seed, day))
	local list: { Quest } = {}
	for tier = 1, math.min(R.QuestCount, #kinds) do
		table.insert(list, newQuest(farm, kinds[tier], tier))
	end
	return list
end

-- The five weekly quests, counted from now.
function Rewards.makeWeekly(farm: Farm): { Quest }
	local list: { Quest } = {}
	for _, def in R.Weekly do
		table.insert(list, { kind = def.kind, need = def.need, mark = Rewards.count(farm, def.kind), claimed = false })
	end
	return list
end

-- Whether today's quests or this week's are missing (the server looks, then calls ensureQuests).
function Rewards.stale(farm: Farm, now: number): boolean
	local quests, weekly = farm.rewards.quests, farm.rewards.weekly
	return farm.tutorialDone ~= false
		and (
			quests.day ~= Rewards.dayOf(now)
			or #quests.list == 0
			or weekly.week ~= ArenaSeason.weekOf(now)
			or #weekly.list == 0
		)
end

-- Makes today's quests (and this week's) if the farm has none for today (a new player gets them once the tutorial is over).
-- Returns whether it did either.
function Rewards.ensureQuests(farm: Farm, seed: number, now: number): boolean
	if farm.tutorialDone == false then
		return false
	end
	local made = false
	local day = Rewards.dayOf(now)
	local quests = farm.rewards.quests
	if quests.day ~= day or #quests.list == 0 then
		farm.rewards.quests =
			{ day = day, list = Rewards.makeQuests(farm, seed, day), bonus = false, rerolls = 0, freeUsed = 0 }
		made = true
	end
	local week = ArenaSeason.weekOf(now)
	local weekly = farm.rewards.weekly
	if weekly.week ~= week or #weekly.list == 0 then
		farm.rewards.weekly = { week = week, list = Rewards.makeWeekly(farm), chest = false }
		made = true
	end
	return made
end

local function todays(farm: Farm, now: number): boolean
	return farm.rewards.quests.day == Rewards.dayOf(now)
end

-- Whether the redraw of the day that costs nothing is still there.
function Rewards.freeRerollLeft(farm: Farm, now: number): boolean
	return todays(farm, now) and farm.rewards.quests.freeUsed < R.FreeRerolls
end

-- Draws quest `index` of today again: a kind that fits and that no other quest of the day asks, counted from now. The free
-- redraw of the day is used unless `paid` (the Robux code calls it with paid = true after the receipt is granted; a refusal
-- changes nothing, so a purchase is only taken when this returns true). (ok, reason?): "NO_QUEST", "TAKEN" (its reward was
-- claimed), "NO_REROLL" (the free one is used) or "NO_KIND" (nothing else fits).
function Rewards.rerollQuest(farm: Farm, index: number, seed: number, now: number, paid: boolean?): (boolean, string?)
	local quests = farm.rewards.quests
	local quest = quests.list[index]
	if not todays(farm, now) or not quest then
		return false, "NO_QUEST"
	elseif quest.claimed then
		return false, "TAKEN"
	elseif not paid and quests.freeUsed >= R.FreeRerolls then
		return false, "NO_REROLL"
	end
	local skip: { [string]: boolean } = {}
	for _, other in quests.list do
		skip[other.kind] = true
	end
	local kinds = shuffledKinds(farm, dice(seed * 8 + index, quests.day * 8 + quests.rerolls + 1), skip)
	if #kinds == 0 then
		return false, "NO_KIND"
	end
	quests.list[index] = newQuest(farm, kinds[1], index)
	quests.rerolls += 1
	if not paid then
		quests.freeUsed += 1
	end
	return true, nil
end

-- How far a quest is: never more than its need.
function Rewards.progress(farm: Farm, quest: Quest): number
	return math.clamp(Rewards.count(farm, quest.kind) - quest.mark, 0, quest.need)
end

-- What a quest of a kind says, for n of it.
local function askText(kind: string, n: number): string
	local function many(one: string, more: string): string
		return if n == 1 then one else more
	end
	if kind == "breed" then
		return "Lay " .. n .. many(" egg", " eggs")
	elseif kind == "hatch" then
		return "Hatch " .. n .. many(" egg", " eggs")
	elseif kind == "sell" then
		return "Sell " .. n .. many(" slime", " slimes")
	elseif kind == "feed" then
		return "Slimes eat " .. n .. " meals"
	elseif kind == "win" then
		return "Beat " .. n .. many(" zombie", " zombies")
	elseif kind == "wave" then
		return "Clear " .. n .. many(" Dungeon wave", " Dungeon waves")
	elseif kind == "arena" then
		return "Attack in the Arena " .. n .. many(" time", " times")
	elseif kind == "craft" then
		return "Craft " .. n .. many(" piece of gear", " pieces of gear")
	elseif kind == "cook" then
		return "Cook " .. n .. many(" dish", " dishes")
	elseif kind == "fish" then
		return "Catch " .. n .. many(" fish", " fish")
	elseif kind == "harvest" then
		return "Harvest " .. n .. many(" crop", " crops")
	elseif kind == "find" then
		return "Find " .. n .. many(" new kind of slime", " new kinds of slime")
	elseif kind == "spin" then
		return "Spin the Lucky Wheel " .. n .. many(" time", " times")
	elseif kind == "play" then
		return "Play for " .. n .. many(" minute", " minutes")
	end
	return "Upgrade " .. n .. many(" time", " times")
end

function Rewards.questText(quest: Quest): string
	return askText(quest.kind, quest.need)
end

-- The reward of the daily quest at this place of the list.
local function questReward(index: number): any
	return R.QuestRewards[index] or R.QuestRewards[#R.QuestRewards]
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
	local grant = Rewards.grant(questReward(index), farm)
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

-- ===== weekly quests =====

local function thisWeek(farm: Farm, now: number): boolean
	return farm.rewards.weekly.week == ArenaSeason.weekOf(now) and #farm.rewards.weekly.list > 0
end

function Rewards.claimWeekly(farm: Farm, index: number, now: number): (boolean, string?, number?)
	local quest = farm.rewards.weekly.list[index]
	if not thisWeek(farm, now) or not quest then
		return false, "NO_QUEST"
	elseif quest.claimed then
		return false, "TAKEN"
	elseif Rewards.progress(farm, quest) < quest.need then
		return false, "NOT_DONE"
	end
	local grant = Rewards.grant(R.Weekly[index].reward, farm)
	Rewards.pay(farm, grant, now)
	quest.claimed = true
	return true, nil, grant.coins
end

-- 0: not every weekly quest is claimed yet; 1: the Weekly Chest waits; 2: taken.
function Rewards.chestState(farm: Farm, now: number): number
	local weekly = farm.rewards.weekly
	if not thisWeek(farm, now) then
		return 0
	elseif weekly.chest then
		return 2
	end
	for _, quest in weekly.list do
		if not quest.claimed then
			return 0
		end
	end
	return 1
end

function Rewards.claimChest(farm: Farm, now: number): (boolean, string?, number?)
	local state = Rewards.chestState(farm, now)
	if state == 2 then
		return false, "TAKEN"
	elseif state == 0 then
		return false, "NOT_DONE"
	end
	local grant = Rewards.grant(R.WeeklyChest, farm)
	Rewards.pay(farm, grant, now)
	farm.rewards.weekly.chest = true
	return true, nil, grant.coins
end

-- ===== online gifts =====

-- Adds `elapsed` seconds of play ending now. A new UTC day starts the clock and the gifts again, counting only the part of
-- `elapsed` after midnight. Every second also counts in the lifetime play time (the quests of kind "play").
function Rewards.addPlayed(farm: Farm, now: number, elapsed: number)
	local online = farm.rewards.online
	local today = Rewards.dayOf(now)
	local seconds = math.max(0, elapsed)
	farm.lifetime.secsPlayed += math.floor(seconds)
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

-- ===== goals =====

local goalIds: { [string]: any } = {}
for _, goal in Config.Goals.List do
	goalIds[goal.id] = goal
end

-- What a goal's kind counts: the village level and the Dungeon's best level are read as they are, the eggs hatched are the
-- Index's without the starters, the rest are quest counts.
function Rewards.goalCount(farm: Farm, kind: string): number
	if kind == "village" then
		return FarmState.villageLevel(farm.areas)
	elseif kind == "dungeon" then
		return farm.dungeon.best
	elseif kind == "hatch" then
		-- (the starters count as hatched in the Index but nobody hatched them)
		return math.max(0, Rewards.count(farm, kind) - Config.Farm.StarterCount)
	end
	return Rewards.count(farm, kind)
end

function Rewards.goalText(goal: { kind: string, need: number }): string
	local n = goal.need
	local function many(one: string, more: string): string
		return if n == 1 then one else more
	end
	if goal.kind == "village" then
		return "Reach village level " .. n
	elseif goal.kind == "dungeon" then
		return "Clear Dungeon level " .. n
	elseif goal.kind == "find" then
		return "Find " .. n .. " kinds of slime"
	elseif goal.kind == "arena" then
		return "Attack in the Arena " .. n .. many(" time", " times")
	end
	return askText(goal.kind, n)
end

-- 0: not reached; 1: reached, waiting to be claimed; 2: taken.
function Rewards.goalState(farm: Farm, goal: { id: string, kind: string, need: number }): number
	if farm.rewards.goals[goal.id] then
		return 2
	end
	return if Rewards.goalCount(farm, goal.kind) >= goal.need then 1 else 0
end

function Rewards.claimGoal(farm: Farm, id: string, now: number): (boolean, string?, number?)
	local goal = goalIds[id]
	if not goal then
		return false, "NO_GOAL"
	end
	local state = Rewards.goalState(farm, goal)
	if state == 2 then
		return false, "TAKEN"
	elseif state == 0 then
		return false, "NOT_DONE"
	end
	local grant = Rewards.grant(goal, farm)
	Rewards.pay(farm, grant, now)
	farm.rewards.goals[id] = true
	return true, nil, grant.coins
end

-- ===== what waits =====

-- How many rewards can be claimed now (the badge on the Rewards button). `unsaved`: seconds played that the server has not
-- written into the save yet. (The wheel's free spin is its own badge: shared/Wheel.)
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
	if thisWeek(farm, now) then
		for _, quest in farm.rewards.weekly.list do
			if not quest.claimed and Rewards.progress(farm, quest) >= quest.need then
				count += 1
			end
		end
	end
	if Rewards.chestState(farm, now) == 1 then
		count += 1
	end
	for index in R.CheckinMilestones do
		if Rewards.milestoneState(farm, index) == 1 then
			count += 1
		end
	end
	for _, goal in Config.Goals.List do
		if Rewards.goalState(farm, goal) == 1 then
			count += 1
		end
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

-- ===== what the client draws =====

-- The reward part of a row: coins, luck minutes, spins and the items ({ kind, id, count } objects).
local function paysOf(grant: Grant): { any }
	return { grant.coins, grant.luck, grant.spins or 0, grant.items or {} }
end

-- A row with a state in front of the reward: { state, coins, luck, spins, items }.
local function stateRow(state: number, grant: Grant): { any }
	return { state, grant.coins, grant.luck, grant.spins or 0, grant.items or {} }
end

-- A quest as a row: { text, progress, need, claimed, coins, kind, luck, spins, items }.
local function questRow(farm: Farm, quest: Quest, spec: any): { any }
	local grant = Rewards.grant(spec, farm)
	return {
		Rewards.questText(quest),
		Rewards.progress(farm, quest),
		quest.need,
		quest.claimed,
		grant.coins,
		quest.kind,
		grant.luck,
		grant.spins or 0,
		grant.items or {},
	}
end

-- What the client draws, as plain rows (the server sends them as JSON). Rows are arrays, so the old screen keeps reading
-- its columns; each row's reward is ... coins, luck, spins, items at the end (see each).
--   day, taken          the check-in's day and whether it was taken today; checkins: all taken
--   daily               { coins, luck, spins, items } for each of the seven days
--   milestones          { { total, state (0 wait, 1 ready, 2 taken), coins, luck, spins, items } } (named)
--   quests              { text, progress, need, claimed, coins, kind, luck, spins, items } for each of today's quests
--   rerollFree          the free redraw of today is still there
--   bonus               { state, coins, luck, spins, items }
--   online              { minutes, coins, luck, taken, spins, items }
--   weekly              { quests = rows as quests, chest = as bonus, reset = server time of Monday 00:00 }
--   goals               { { id, kind, text, progress, need, state (0, 1, 2), coins, luck, spins, items } } (named)
--   reset               the server time of the next midnight (new quests, a new check-in, the gifts again)
function Rewards.view(farm: Farm, now: number): { [string]: any }
	local day, taken = Rewards.dailyDay(farm, now)
	local daily = {}
	for _, spec in R.Daily do
		table.insert(daily, paysOf(Rewards.grant(spec, farm)))
	end
	local milestones = {}
	for index, milestone in R.CheckinMilestones do
		local grant = Rewards.grant(milestone, farm)
		table.insert(milestones, {
			total = milestone.total,
			state = Rewards.milestoneState(farm, index),
			coins = grant.coins,
			luck = grant.luck,
			spins = grant.spins,
			items = grant.items,
		})
	end
	local quests: { { any } } = {}
	if todays(farm, now) then
		for index, quest in farm.rewards.quests.list do
			table.insert(quests, questRow(farm, quest, questReward(index)))
		end
	end
	local online: { { any } } = {}
	for step, gift in R.Online do
		local grant = Rewards.grant(gift :: any, farm)
		local row: { any } = {
			gift.minutes,
			grant.coins,
			grant.luck,
			Rewards.onlineTaken(farm, now, step),
			grant.spins,
			grant.items,
		}
		table.insert(online, row)
	end
	local weeklyRows: { { any } } = {}
	if thisWeek(farm, now) then
		for index, quest in farm.rewards.weekly.list do
			table.insert(weeklyRows, questRow(farm, quest, R.Weekly[index].reward))
		end
	end
	local chest = Rewards.grant(R.WeeklyChest, farm)
	local goals = {}
	for _, goal in Config.Goals.List do
		local grant = Rewards.grant(goal, farm)
		table.insert(goals, {
			id = goal.id,
			kind = goal.kind,
			text = Rewards.goalText(goal),
			progress = math.min(Rewards.goalCount(farm, goal.kind), goal.need),
			need = goal.need,
			state = Rewards.goalState(farm, goal),
			coins = grant.coins,
			luck = grant.luck,
			spins = grant.spins,
			items = grant.items,
		})
	end
	local bonus = Rewards.grant(R.QuestBonus, farm)
	return {
		day = day,
		taken = taken,
		checkins = farm.rewards.checkins,
		daily = daily,
		milestones = milestones,
		quests = quests,
		rerollFree = Rewards.freeRerollLeft(farm, now),
		bonus = stateRow(Rewards.bonusState(farm, now), bonus),
		online = online,
		weekly = {
			quests = weeklyRows,
			chest = stateRow(Rewards.chestState(farm, now), chest),
			reset = ArenaSeason.weekEnd(ArenaSeason.weekOf(now)),
		},
		goals = goals,
		reset = (Rewards.dayOf(now) + 1) * DAY,
	}
end

return Rewards
