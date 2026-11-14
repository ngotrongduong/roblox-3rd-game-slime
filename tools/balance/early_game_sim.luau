--!nocheck
-- The first hours of a new player, on the real rules: the starting farm (FarmState.newFarm, 8 starter slimes), one team of
-- four on Repeat against one pack of the Sunny Meadow, two slimes fishing and gardening, a pair breeding whose babies are sold the
-- moment they hatch, the online gifts and the daily quests claimed as soon as they are ready, and every coin spent at once
-- on the cheapest area upgrade (the lowest-level area; all areas cost the same). Records how long the team spends marching,
-- fighting and waiting (why), where the coins come from and when the village reaches level 5, 10 and 20.
-- Assumed: the tutorial leaves the player with workers and a pair at minute 1 and the first team out at minute 4; a revive
-- is paid at once if the food is there; the player never trains (levels stay 4); one team only (the second opens at
-- village level 10 but the starters have no more free slimes); the farm runs at productive 0.55 as kitchen_sim does.
-- lune run tools/balance/early_game_sim.luau [hours] [packLevelOffset] [firstFightSeconds] [seed] [quiet|full] [cook]
-- ("cook": the pair becomes a cook at the kitchen and its dishes are sold, instead of breeding babies for sale)
local process = require("@lune/process")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Breeding = require("../../src/shared/Breeding")
local Rewards = require("../../src/shared/Rewards")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local Stations = require("../../src/shared/Stations")
local VillageRules = require("../../src/shared/Village")
local VillageSim = require("../../src/shared/VillageSim")
local WorldPacks = require("../../src/shared/WorldPacks")
local Zombies = require("../../src/shared/Zombies")
local Kitchen = require("./kitchen_lib")

local HOURS = tonumber(process.args[1]) or 30
local CAMP = tonumber(process.args[2]) or 0 -- levels the pack stands above the squad
local FIRST_FIGHT = tonumber(process.args[3]) or 240
local SEED = tonumber(process.args[4]) or 1
local SETUP = 60
local VILLAGE_STEP = 10
local MILESTONES = { 5, 10, 20 }

Kitchen.setProductive(0.55)

local BASE = 19800 * 86400 + 8 * 3600
local rng = Rng.new(SEED)
local fightRng = Rng.new(SEED * 31 + 7)
local campRng = Rng.new(SEED * 101 + 3)
local farm = FarmState.newFarm(BASE)
local now = BASE

-- ===== a plain player's set-up =====
local TEAM = { "slime-1", "slime-2", "slime-3", "slime-4" }
local setupDone = false
local function setup()
	setupDone = true
	assert(Stations.assign(farm, "slime-5", "fishing", 1, false, now))
	assert(Stations.assign(farm, "slime-6", "garden", 1, false, now))
	if process.args[6] == "cook" then
		-- variant: the pair becomes a cook (the kitchen's first slot), its dishes sold at once
		assert(Stations.assign(farm, "slime-7", "kitchen", 1, false, now))
	else
		assert(Breeding.setPair(farm, 1, "slime-7", "slime-8", now))
	end
end

-- ===== bookkeeping =====
local income = { fights = 0, sales = 0, daily = 0, online = 0, quests = 0, lostToCap = 0, dishes = 0 }
local dishCount = 0
local spent = 0
local firstEgg, firstHatch, firstSale
local babies = 0
local deaths, revives, losses, fights, wins = 0, 0, 0, 0, 0
local fightSeconds, marchSeconds = 0, 0
local waited = { health = 0, hungry = 0, tired = 0, group = 0, sleeping = 0 }
local seconds = { march = 0, fight = 0, wait = 0 }
local milestone: { [number]: number } = {}
local snaps: { [number]: string } = {}
local SNAP_AT = { 600, 1800, 3600, 7200, 14400 }

-- ===== the team =====
local team = { state = "home", legEnd = 0, members = {}, fight = nil, group = nil, groupAt = 0, byId = {}, cheerEnd = 0 }
local wounds: { [string]: number } = {}
local groupBase = 0
local campGroup: { any } = {}
local groupGoneUntil = 0

-- One way, studs: a team sets out at most MarchMostStuds from its pack and stops the stand-off short of it.
local distance = Config.World.Packs.MarchMostStuds - Config.Zombies.MarchStandOffStuds

local function spawn()
	groupBase = Zombies.playerLevel(farm, now) + CAMP
	campGroup = WorldPacks.pack("z", "meadow", groupBase, campRng)
	groupGoneUntil = 0
end
spawn()

local function slimeOf(id: string)
	return (FarmState.findSlime(farm, id))
end

local function isGhost(slime): boolean
	return slime.ghostUntil ~= nil and slime.ghostUntil > now
end

local function march(): number
	local speeds = {}
	for _, id in team.members do
		local slime = slimeOf(id)
		if slime then
			table.insert(speeds, slime.stats.speed)
		end
	end
	return Zombies.marchSeconds(distance, speeds)
end

-- Why a repeating team at home has not set out: the worst reason among its living members, as the server shows it.
local RANK = { health = 1, hungry = 2, tired = 3 }
local function whyWaiting(): string?
	local why = nil
	local alive = 0
	for _, id in farm.teams[1].members do
		local slime = slimeOf(id)
		if slime and not isGhost(slime) then
			alive += 1
			local ready, reason = Zombies.readyAgain(slime, now, wounds[id] or 0)
			if not ready and (why == nil or (RANK[reason] or 99) < (RANK[why] or 99)) then
				why = reason
			end
		end
	end
	if alive == 0 then
		return "dead"
	end
	return why
end

local function launch()
	local going = {}
	for _, id in farm.teams[1].members do
		local slime = slimeOf(id)
		if slime and Zombies.canSend(farm, slime, now) then
			table.insert(going, id)
		end
	end
	if #going == 0 then
		return false
	end
	team.members = going
	team.state = "going"
	local trip = march()
	team.legEnd = now + trip
	marchSeconds += trip
	return true
end

local function pay(amount: number): number
	local room = math.max(0, VillageRules.coinCap(farm.areas.pantry.level) - farm.coins)
	local paid = Zombies.pay(farm, amount)
	income.lostToCap += math.max(0, amount - room)
	return paid
end

-- The whole fight is run at once on arrival; its coins and falls count at its end.
local function beginFight()
	local fighters, roles = {}, {}
	for _, id in team.members do
		local slime = slimeOf(id)
		-- (a member sold or lost while the team marched does not fight)
		if slime then
			local fighter = Zombies.fighter(slime, now, 1 - (wounds[id] or 0))
			fighter.role = Combat.role(fighter, slime.seed)
			table.insert(fighters, fighter)
		end
	end
	if #fighters == 0 then
		team.members = {}
		team.state = "home"
		return
	end
	local group = campGroup
	local byId = {}
	for _, zombie in group do
		byId[zombie.id] = zombie
	end
	local fight = Combat.new(fighters, group, fightRng)
	local coins, fallen = 0, {}
	while not fight.winner and fight.seconds < Config.Zombies.FightMaxSeconds do
		for _, event in Combat.step(fight, Config.Zombies.FightStepSeconds) do
			if event.kind == "fallen" then
				local zombie = byId[event.to]
				if zombie then
					coins += WorldPacks.killReward(zombie.defRole, zombie.level)
				else
					table.insert(fallen, event.to)
				end
			end
		end
	end
	fights += 1
	fightSeconds += fight.seconds
	local survivors = {}
	for _, unit in fight.units do
		if unit.side == "squad" then
			if unit.hp > 0 then
				table.insert(survivors, unit.id)
				local lost = 1 - unit.hp / unit.maxHp
				wounds[unit.id] = if lost > 0 then lost else nil
			else
				wounds[unit.id] = nil
			end
		end
	end
	for _, id in fallen do
		deaths += 1
		coins += Zombies.deathReward(slimeOf(id))
		Zombies.ghost(farm, id, now)
	end
	income.fights += pay(coins)
	for _, id in survivors do
		local slime = slimeOf(id)
		slime.needs.energy = math.max(0, slime.needs.energy - Config.Zombies.FightEnergy)
		slime.needs.fullness = math.max(0, slime.needs.fullness - Config.Zombies.FightFullness)
	end
	team.members = survivors
	if fight.winner == "squad" then
		wins += 1
		groupGoneUntil = now + Config.Zombies.RespawnSeconds
	else
		spawn()
	end
	team.state = "fighting"
	seconds.fight += fight.seconds
	team.legEnd = now + fight.seconds + (if fight.winner == "squad" then Config.Zombies.CheerSeconds else 0)
end

local function stepTeam()
	-- wounds heal at home only
	if team.state == "home" then
		for id, hurt in wounds do
			local left = Zombies.heal(hurt, 1)
			wounds[id] = if left > 0 then left else nil
		end
	end
	if team.state == "home" then
		if now < BASE + FIRST_FIGHT then
			return
		end
		if groupGoneUntil > 0 and now >= groupGoneUntil then
			spawn()
		end
		local why = whyWaiting()
		if why == "dead" then
			return
		end
		if why then
			waited[why] += 1
			seconds.wait += 1
			return
		end
		if groupGoneUntil > 0 then
			waited.group += 1
			seconds.wait += 1
			return
		end
		launch()
	elseif team.state == "going" then
		seconds.march += 1
		if now >= team.legEnd then
			beginFight()
		end
	elseif team.state == "fighting" then
		if now >= team.legEnd then
			if #team.members == 0 then
				team.state = "home"
			else
				team.state = "returning"
				local trip = march()
				team.legEnd = now + trip
				marchSeconds += trip
			end
		end
	elseif team.state == "returning" then
		seconds.march += 1
		if now >= team.legEnd then
			team.state = "home"
		end
	end
end

-- ===== upkeep: revive, upgrades, rewards =====
local function tryRevive()
	for _, id in farm.teams[1].members do
		local slime = slimeOf(id)
		if slime and isGhost(slime) and Zombies.revive(farm, id, now) then
			revives += 1
			wounds[id] = nil
		end
	end
end

local function cheapestArea(): string
	local best, bestLevel = nil, math.huge
	for _, id in Config.Village.Areas do
		local level = farm.areas[id].level
		if level < bestLevel then
			best, bestLevel = id, level
		end
	end
	return best
end

local function upgrades()
	while true do
		local area = cheapestArea()
		local price = VillageRules.upgradeCost(farm.areas[area].level)
		if farm.coins < price then
			return
		end
		assert(VillageRules.upgrade(farm, area))
		spent += price
	end
end

local function claims()
	local ok, _, coins = Rewards.claimDaily(farm, now)
	if ok then
		income.daily += coins
	end
	for step in Config.Rewards.Online do
		local done, _, got = Rewards.claimOnline(farm, step, now)
		if done then
			income.online += got
		end
	end
	if Rewards.ensureQuests(farm, 12345, now) or true then
		for index in farm.rewards.quests.list do
			local done, _, got = Rewards.claimQuest(farm, index, now)
			if done then
				income.quests += got
			end
		end
		local done, _, got = Rewards.claimBonus(farm, now)
		if done then
			income.quests += got
		end
	end
end

local function report(label: string, t: number)
	local minutes = math.max(1, t / 60)
	snaps[t] = string.format(
		"%-6s fights %7.0f (%.0f/min)  sales %6.0f  rewards %6.0f  spent %7.0f  village level %2d  fights %3d  deaths %3d",
		label,
		income.fights,
		income.fights / minutes,
		income.sales + income.dishes,
		income.daily + income.online + income.quests,
		spent,
		FarmState.villageLevel(farm.areas),
		fights,
		deaths
	)
end

-- ===== the run =====
local total = HOURS * 3600
local snapIndex = 1
for t = 1, total do
	now = BASE + t
	if t == SETUP and not setupDone then
		setup()
	end
	if t == FIRST_FIGHT then
		farm.tutorialDone = true
		assert(Zombies.setTeam(farm, 1, TEAM, now))
		farm.teams[1].repeatOn = true
	end
	if t % VILLAGE_STEP == 0 then
		local events
		farm, events = VillageSim.step(farm, now, VILLAGE_STEP, rng, { errands = true })
		for _, event in events do
			if event.kind == "laid" then
				firstEgg = firstEgg or t
			elseif event.kind == "hatched" and event.slimeId then
				firstHatch = firstHatch or t
				local value = Shop.sell(farm, event.slimeId, now)
				if value then
					firstSale = firstSale or t
					income.sales += value
					babies += 1
				end
			elseif event.kind == "lost" then
				losses += 1
			end
		end
	end
	if t % VILLAGE_STEP == 0 then
		for id, held in table.clone(farm.fridge) do
			local value = Shop.sellDish(farm, id, held)
			if value then
				income.dishes += value
				dishCount += held
			end
		end
	end
	Rewards.addPlayed(farm, now, 1)
	if t % 2 == 0 then
		claims()
		tryRevive()
	end
	stepTeam()
	upgrades()
	local level = FarmState.villageLevel(farm.areas)
	for _, want in MILESTONES do
		if level >= want and not milestone[want] then
			milestone[want] = t
		end
	end
	if SNAP_AT[snapIndex] and t == SNAP_AT[snapIndex] then
		report(string.format("%dmin", t / 60), t)
		snapIndex += 1
	end
	if milestone[20] and t > milestone[20] + 60 then
		total = t
		break
	end
end

-- ===== report =====
local function minutes(value: number?): string
	return if value then string.format("%.1f", value / 60) else "-"
end
print(
	string.format(
		"pack level offset %d, seed %d, first fight at %d s, one-way march %.0f studs = %.1f s, group level %d, run %.1f h",
		CAMP,
		SEED,
		FIRST_FIGHT,
		distance,
		Zombies.marchSeconds(distance, { 1, 1, 1, 1 }),
		groupBase,
		total / 3600
	)
)
print(
	string.format(
		"first egg %s min, first hatch %s min, first sale %s min, babies sold %d",
		minutes(firstEgg),
		minutes(firstHatch),
		minutes(firstSale),
		babies
	)
)
for _, t in SNAP_AT do
	if snaps[t] then
		print(snaps[t])
	end
end
for _, want in MILESTONES do
	print(string.format("all areas at level %d (village level %d) after %s min = %s h", want, want, minutes(milestone[want]), if milestone[want] then string.format("%.1f", milestone[want] / 3600) else "-"))
end
local active = seconds.march + seconds.fight + seconds.wait
print(
	string.format(
		"fights %d (won %d), slimes fell %d (%.2f a fight), revived %d, lost for good %d, coins a fight %.0f",
		fights,
		wins,
		deaths,
		deaths / math.max(1, fights),
		revives,
		losses,
		income.fights / math.max(1, fights)
	)
)
print(
	string.format(
		"team time: marching %.0f%%, fighting %.0f%%, waiting %.0f%% | wait by reason: health %.0f%%, hungry %.0f%%, tired %.0f%%, group %.0f%%",
		seconds.march / active * 100,
		seconds.fight / active * 100,
		seconds.wait / active * 100,
		waited.health / active * 100,
		waited.hungry / active * 100,
		waited.tired / active * 100,
		waited.group / active * 100
	)
)
print(
	string.format(
		"per fight: fight %.1f s, march both ways %.1f s, cheer %.1f s, waiting %.1f s -> a cycle %.1f s",
		fightSeconds / math.max(1, fights),
		marchSeconds / math.max(1, fights),
		Config.Zombies.CheerSeconds,
		seconds.wait / math.max(1, fights),
		(fightSeconds + marchSeconds + seconds.wait) / math.max(1, fights) + Config.Zombies.CheerSeconds
	)
)
print(
	string.format(
		"coins in: fights %.0f, babies %.0f, dishes %.0f (%d), daily %.0f, online gifts %.0f, quests %.0f | lost to the vault ceiling %.0f | spent %.0f",
		income.fights,
		income.sales,
		income.dishes,
		dishCount,
		income.daily,
		income.online,
		income.quests,
		income.lostToCap,
		spent
	)
)
print("slimes left", #farm.slimes, "storehouse food", (function()
	local sum = 0
	for _, n in farm.storehouse do
		sum += n
	end
	return sum
end)())

if process.args[5] == "quiet" then
	return
end
print("\nprice of the upgrade FROM level n (every area), and the coins to bring one area / all six area to level n+1")
print("level  price   one area, cumulative   all six, cumulative")
local one, six = 0, 0
for level = 1, 20 do
	local price = VillageRules.upgradeCost(level)
	one += price
	six += price * #Config.Village.Areas
	print(string.format("%2d->%2d %7d %12d %20d", level, level + 1, price, one, six))
end
