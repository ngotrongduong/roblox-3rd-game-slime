--!strict
-- The schema-six living village: load-safe slimes, area levels, jobs, food and breeding.
-- All clocks are server epoch seconds, and repairs keep valid unrelated progress intact.

local ArenaQuests = if script then require(script.Parent.ArenaQuests) else require("./ArenaQuests")
local ArenaSeason = if script then require(script.Parent.ArenaSeason) else require("./ArenaSeason")
local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")
local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local Config = if script then require(script.Parent.Config) else require("./Config")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local GardenPlots = if script then require(script.Parent.GardenPlots) else require("./GardenPlots")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local StatsModule = if script then require(script.Parent.Stats) else require("./Stats")
local WorldPacks = if script then require(script.Parent.WorldPacks) else require("./WorldPacks")

local FarmState = {}

-- Sibling types come through typeof: an exported type cannot be read through the if-require.
-- Modules that need the farm types do the same, e.g. typeof(FarmState.newFarm(0)).
export type Stats = typeof(StatsModule.starter())
export type ColourGenotype = typeof(Genetics.homozygous(""))
export type Appearance = typeof(Mutations.none())

export type Needs = { fullness: number, energy: number, fun: number }
export type Buff = { stat: string, percent: number, untilTime: number, dish: string? }

-- Gear is kept for the future fight phase; the fallen state is replaced by a timed ghost.
export type Loadout = { head: string?, hand: string?, tail: string? }
-- The Smithy's gear a slime wears (Config.Smithy.Gear ids, one a slot; shared/Gear). Not the old `loadout` above.
export type WornGear = { hand: string?, head: string?, tail: string? }
export type Slime = {
	id: string,
	name: string,
	seed: number,
	assetId: string,
	stats: Stats,
	colourGenotype: ColourGenotype,
	visibleColour: string,
	appearanceMutation: Appearance,
	isFavourite: boolean,
	needs: Needs,
	trait: string,
	friends: { [string]: number },
	buff: Buff?,
	autoDish: string?,
	ghostUntil: number?,
	-- A resting slime stays asleep until rested; its state survives offline steps.
	sleeping: boolean?,
	createdAt: number,
	breedReadyAt: number,
	loadout: Loadout,
	gear: WornGear,
}

export type Embryo = {
	stats: Stats,
	colourGenotype: ColourGenotype,
	appearanceMutation: Appearance,
}
export type Egg = {
	id: string,
	parentIds: { string },
	createdAt: number,
	hatchAt: number?,
	-- When the hatch clock started (its bar runs from here to hatchAt); kept in step when hatchAt moves (retimeEgg).
	hatchStart: number?,
	place: string,
	slot: number,
	offspringId: string,
	embryo: Embryo,
	status: string,
	injected: boolean?,
	statBoosted: boolean?,
}

export type DiscoveryRecord = { firstDiscoveredAt: number, hatchCount: number }
export type DiscoveryBucket = { [string]: DiscoveryRecord }
export type Discoveries = {
	base: DiscoveryBucket,
	dual: DiscoveryBucket,
	secret: DiscoveryBucket,
	material: DiscoveryBucket,
}

export type Area = { level: number }
export type Areas = {
	fishing: Area,
	garden: Area,
	kitchen: Area,
	pantry: Area,
	training: Area,
	breeding: Area,
}
export type WorkSlot = {
	worker: string?,
	reserve: string?,
	progress: number,
	stat: string?,
	recipe: string?,
	plot: number?,
	task: string?,
	pending: string?,
}
export type WorkArea = { slots: { WorkSlot }, box: { [string]: number } }
export type GardenWorkArea = { slots: { WorkSlot }, box: { [string]: number }, plots: typeof(GardenPlots.new(1)) }
export type Work = {
	fishing: WorkArea,
	garden: GardenWorkArea,
	kitchen: WorkArea,
	training: WorkArea,
}
export type Pair = { a: string?, b: string?, courtingUntil: number? }
export type Pairing = { pairs: { Pair } }
-- A fighting team (Config.Zombies.Teams of them, always): its line-up, whether it attacks again by itself, and the
-- id of the zombie group it was last ordered at (ZombieFights; a group id is stable, so the order survives a rejoin).
export type Team = {
	members: { string },
	repeatOn: boolean,
	target: string?,
	-- Only overridden rows are saved; absent means the weapon's row. Balanced is also absent.
	formation: { [string]: string }?,
	tactic: string?,
	-- The band of packs (WorldPacks.band) the team explores by itself until it is called back; absent when it does not.
	explore: number?,
}
-- The tutorial (shared/Guide): its step (Config.Guide.Steps, or "done"), the number the step measures from, the intro on
-- screen and the number it measures from, and the intros already done or put away.
export type Guide = { step: string, mark: number, intro: string?, introMark: number, seen: { [string]: boolean } }
-- Rewards for coming back (shared/Rewards). Days are UTC day numbers, 0 for never. daily: the day of the run last taken
-- and when; a quest: its kind, how many it asks, the lifetime count it is measured from, whether its reward was taken;
-- online: seconds played that day and the gifts taken. indexSeen: the Index was opened (its intro is done). Schema 12:
-- quests.rerolls/freeUsed: redraws of today's list (all, and the free ones among them); checkins: check-ins taken in all,
-- milestones: the Config.Rewards.CheckinMilestones indexes taken; weekly: the UTC week (ArenaSeason.weekOf) the five weekly
-- quests were made for, and whether the Weekly Chest was taken; goals: Config.Goals ids taken; wheel (shared/Wheel): the UTC
-- day of the free spins, how many were used that day, and the bank of spins that never expires. Schema 14: social: the
-- community rewards taken (shared/Social), each paid once.
export type Quest = { kind: string, need: number, mark: number, claimed: boolean }
export type Rewards = {
	daily: { streak: number, day: number },
	quests: { day: number, list: { Quest }, bonus: boolean, rerolls: number, freeUsed: number },
	online: { day: number, secs: number, claimed: { number } },
	indexSeen: boolean,
	checkins: number,
	milestones: { number },
	weekly: { week: number, list: { Quest }, chest: boolean },
	goals: { [string]: boolean },
	wheel: { day: number, used: number, bank: number },
	social: { favorite: boolean, group: boolean },
}
-- The Slime Dungeon (shared/Dungeon): the highest dungeon level cleared, 0 for none (level best + 1 is the next to open).
export type Dungeon = { best: number }
-- The zones of the big world (schema 15; shared/ZoneFights): beaten[zone id] = the server time (os.time) of the player's
-- last win there. A zone that is not in it was never won.
export type World = { beaten: { [string]: number } }

-- What Robux sells (schema 13; shared/Boosts, shared/Products, server/Purchases). boosts: when the Gold and the Hatch Potion
-- run out (the luck potion's end is farm.luckPotionUntil, which the rewards also pay), 0 for never. robux: receipts = the
-- ids of the purchases already granted, newest last, at most Config.Robux.ReceiptsKept (a receipt is never granted twice);
-- passes = the game passes Roblox said the player owns, by key (asked again at every join); starterBought = the Starter Pack
-- was bought (once an account); rerolls / savers = quest redraws and Streak Savers paid for and not used yet; drinks /
-- hatchAlls = Energy Drinks and Hatch All Nows that did nothing when the receipt came (nobody tired, no egg growing).
export type Boosts = { gold: number, hatch: number }
export type Robux = {
	receipts: { string },
	passes: { [string]: boolean },
	starterBought: boolean,
	rerolls: number,
	savers: number,
	drinks: number,
	hatchAlls: number,
}

-- The Arena (shared/ArenaRules; schema 11). Times are server seconds, days and weeks ArenaSeason.dayOf / weekOf numbers,
-- seasons ArenaSeason.seasonOf numbers (yyyymm). The match in flight: who was attacked, at which rank (0 for a champion),
-- the fight's result and seed, when it began and was last sent, and the client's request id; it is cleared only when the
-- ladder shows its outcome (points granted) or it is void.
export type ArenaPending = {
	matchId: string,
	seq: number,
	season: number,
	defender: string,
	defenderName: string,
	defenderRank: number,
	above: boolean,
	stronger: boolean,
	won: boolean,
	power: number,
	seed: number,
	at: number,
	sentAt: number,
	requestId: string,
}
-- One finished season: the final rank (0 for none), its badge and the wins in it.
export type ArenaSeasonRecord = { season: number, rank: number, badge: string?, wins: number }
export type ArenaQuestState = typeof(ArenaQuests.new(0))
-- points: the Arena's currency; team: slime ids; day/used: the tickets used that UTC day; seq: the last match number
-- (never below the ladder's); claimed: season rewards taken, by tostring(season); season/seasonWins/bestRank: this season's
-- counters (bestRank 0 for none); defense: defences won, the current and the best run; week/bought: the shop's week and what
-- was bought in it, by item id; snapshotAt: when the defence team was last published.
export type Arena = {
	points: number,
	team: { string },
	day: number,
	used: number,
	seq: number,
	pending: ArenaPending?,
	claimed: { [string]: boolean },
	history: { ArenaSeasonRecord },
	quests: ArenaQuestState,
	season: number,
	seasonWins: number,
	bestRank: number,
	defense: { wins: number, streak: number, best: number },
	week: number,
	bought: { [string]: number },
	snapshotAt: number,
}

-- kind: "INVENTORY", "EQUIPPED_TO_SLIME" (with slimeId and slot), "BATTLE_ESCROW", "PENDING_RETURN".
export type ItemOwnership = { kind: string, slimeId: string?, slot: string? }
export type Item = { id: string, definitionId: string, ownership: ItemOwnership }

export type Lifetime = {
	coinsEarned: number,
	foodFarmed: number,
	bestSlimeLevel: number,
	daysPlayed: number,
	-- UTC day "YYYY-MM-DD" (the original used the local day).
	lastPlayedDay: string,
	mobsKilled: number,
	bossesKilled: number,
	breeds: number,
	bestRaidKillSec: number,
	slimesSold: number,
	meals: number,
	-- Schema 12: what the quests and goals measure (shared/Rewards.count).
	dungeonWaves: number,
	arenaAttacks: number,
	gearCrafted: number,
	dishesCooked: number,
	fishCaught: number,
	cropsHarvested: number,
	wheelSpins: number,
	secsPlayed: number,
}

export type AvatarLoadout = {
	head: string?,
	hand: string?,
	tail: string?,
	back: string?,
	wings: string?,
	aura: string?,
}

export type Avatar = {
	name: string,
	assetId: string,
	stats: Stats,
	spentPoints: number,
	loadout: AvatarLoadout,
	createdAt: number,
	frame: string,
	bg: string,
	ownedFrames: { string },
	ownedBgs: { string },
}

export type Farm = {
	slimes: { Slime },
	eggs: { Egg },
	breedsSinceMutation: number,
	discoveries: Discoveries,
	areas: Areas,
	work: Work,
	storehouse: { [string]: number },
	counter: { [string]: number },
	fridge: { [string]: number },
	breeding: Pairing,
	teams: { Team },
	lastSimulatedAt: number,
	coins: number,
	items: { Item },
	materials: { [string]: number },
	-- The gear bag: crafted pieces nobody wears, by gear id (schema 10; shared/Gear).
	gear: { [string]: number },

	lifetime: Lifetime,
	avatar: Avatar,
	-- nil on legacy saves means the tour is done.
	tutorialDone: boolean?,
	tutorialDoneAt: number?,
	guide: Guide,
	rewards: Rewards,
	dungeon: Dungeon,
	world: World,
	arena: Arena,
	boosts: Boosts,
	robux: Robux,
	luckPotionUntil: number?,
	lastSiegeTeam: { string }?,
	wbKingSlain: boolean?,
}

FarmState.SlimeSlots = { "head", "hand", "tail" }
FarmState.AvatarSlots = { "hand", "head", "tail", "back", "wings", "aura" }

-- ===== small shared helpers =====

-- UTC calendar day of a server time. os.date("!*t") is the one form both Roblox and Lune accept.
function FarmState.dayKey(now: number): string
	local t = os.date("!*t", math.floor(now)) :: any
	return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

function FarmState.fullNeeds(): Needs
	local n = Config.Needs.Start
	return { fullness = n, energy = n, fun = n }
end

function FarmState.traitForSeed(seed: number): string
	local traits = Config.Village.Traits
	return traits[math.floor(seed % #traits) + 1]
end

function FarmState.slotCount(level: number): number
	local count = Config.Work.BaseSlots
	for _, threshold in Config.Work.SlotLevels do
		if level >= threshold then
			count += 1
		end
	end
	return count
end

function FarmState.breedingCount(level: number): number
	local count = Config.Breeding.BasePlaces
	for _, threshold in Config.Breeding.SlotLevels do
		if level >= threshold then
			count += 1
		end
	end
	return count
end

function FarmState.newAreas(): Areas
	local out: any = {}
	for _, id in Config.Village.Areas do
		out[id] = { level = Config.Village.StartLevel }
	end
	return out :: Areas
end

function FarmState.newPairing(level: number): Pairing
	local pairs: { Pair } = {}
	for _ = 1, FarmState.breedingCount(level) do
		table.insert(pairs, {})
	end
	return { pairs = pairs }
end

-- A tutorial at its first step, or already over (`done`: a farm that has played without one).
function FarmState.newGuide(done: boolean): Guide
	return { step = if done then "done" else Config.Guide.Steps[1], mark = 0, introMark = 0, seen = {} }
end

function FarmState.newRewards(): Rewards
	return {
		daily = { streak = 0, day = 0 },
		quests = { day = 0, list = {}, bonus = false, rerolls = 0, freeUsed = 0 },
		online = { day = 0, secs = 0, claimed = {} },
		indexSeen = false,
		checkins = 0,
		milestones = {},
		weekly = { week = 0, list = {}, chest = false },
		goals = {},
		wheel = { day = 0, used = 0, bank = 0 },
		social = { favorite = false, group = false },
	}
end

function FarmState.newDungeon(): Dungeon
	return { best = 0 }
end

function FarmState.newWorld(): World
	return { beaten = {} }
end

function FarmState.newBoosts(): Boosts
	return { gold = 0, hatch = 0 }
end

function FarmState.newRobux(): Robux
	return { receipts = {}, passes = {}, starterBought = false, rerolls = 0, savers = 0, drinks = 0, hatchAlls = 0 }
end

function FarmState.newArena(now: number): Arena
	return {
		points = 0,
		team = {},
		day = ArenaSeason.dayOf(now),
		used = 0,
		seq = 0,
		pending = nil,
		claimed = {},
		history = {},
		quests = ArenaQuests.new(now),
		season = ArenaSeason.seasonOf(now),
		seasonWins = 0,
		bestRank = 0,
		defense = { wins = 0, streak = 0, best = 0 },
		week = ArenaSeason.weekOf(now),
		bought = {},
		snapshotAt = 0,
	}
end

function FarmState.newTeams(): { Team }
	local teams: { Team } = {}
	for _ = 1, Config.Zombies.Teams do
		table.insert(teams, { members = {}, repeatOn = false })
	end
	return teams
end

-- The number of the team a slime stands in, nil when it is in none.
function FarmState.inPair(farm: Farm, slimeId: string): boolean
	for _, pair in farm.breeding.pairs do
		if pair.a == slimeId or pair.b == slimeId then
			return true
		end
	end
	return false
end

function FarmState.teamOf(farm: Farm, slimeId: string): number?
	for index, team in farm.teams do
		if table.find(team.members, slimeId) then
			return index
		end
	end
	return nil
end

function FarmState.newWork(areas: Areas): Work
	local out: any = {}
	for _, id in Config.Work.Areas do
		local slots: { WorkSlot } = {}
		for _ = 1, FarmState.slotCount((areas :: any)[id].level) do
			table.insert(slots, { progress = 0 })
		end
		out[id] = {
			slots = slots,
			box = {},
			plots = if id == "garden" then GardenPlots.new(Config.Work.GardenPlotCount) else nil,
		}
	end
	return out :: Work
end

function FarmState.emptyLoadout(): Loadout
	return {}
end

function FarmState.emptyGear(): WornGear
	return {}
end

-- Every piece the slime wears goes back to the farm's bag (it is sold, lost or released).
function FarmState.returnGear(farm: Farm, slime: Slime)
	local worn: any = slime.gear
	if type(worn) ~= "table" then
		return
	end
	for _, slot in Config.Smithy.Slots do
		local id = worn[slot]
		if type(id) == "string" then
			farm.gear[id] = (farm.gear[id] or 0) + 1
			worn[slot] = nil
		end
	end
end

function FarmState.emptyDiscoveries(): Discoveries
	return { base = {}, dual = {}, secret = {}, material = {} }
end

-- A nest egg hatches too, at the nest's slower rate (Breeding.nestSeconds); "nest" until it is ready.
function FarmState.eggStatus(egg: Egg, now: number): string
	if egg.hatchAt ~= nil and now >= egg.hatchAt then
		return "ready"
	end
	return if egg.place == "incubator" and egg.hatchAt ~= nil then "incubating" else "nest"
end

-- Moves an egg's hatch time to `hatchAt` and moves its clock start with it, so the hatch bar keeps the fraction it had (a
-- potion starting or ending, a move between nest and incubator). An egg with no start stays without one.
function FarmState.retimeEgg(egg: Egg, now: number, hatchAt: number)
	local old, start = egg.hatchAt, egg.hatchStart
	if old ~= nil and start ~= nil and old > now and start < now then
		egg.hatchStart = now - (now - start) * (hatchAt - now) / (old - now)
	end
	egg.hatchAt = hatchAt
end

function FarmState.villageLevel(areas: Areas): number
	local total = 0
	for _, id in Config.Village.Areas do
		total += (areas :: any)[id].level
	end
	return math.floor(total / #Config.Village.Areas)
end

-- How far the village is towards its next level: one area upgrade adds one to the sum of the area levels, so every
-- village level takes as many upgrades as there are areas. Returns upgrades done since this level, and upgrades a level.
function FarmState.villageProgress(areas: Areas): (number, number)
	local level = FarmState.villageLevel(areas)
	local count = #Config.Village.Areas
	if level >= Config.Village.MaxLevel then
		return count, count
	end
	local total = 0
	for _, id in Config.Village.Areas do
		total += (areas :: any)[id].level
	end
	return total - level * count, count
end

-- Takes a slime out of the farm and out of every place that names it. Returns whether it was there.
function FarmState.removeSlime(farm: Farm, id: string): boolean
	local found, at = FarmState.findSlime(farm, id)
	if not found or not at then
		return false
	end
	-- (what it wore is not lost with it)
	FarmState.returnGear(farm, found)
	table.remove(farm.slimes, at)
	for _, areaId in Config.Work.Areas do
		for _, slot in (farm.work :: any)[areaId].slots do
			if slot.worker == id then
				slot.worker = nil
			end
			if slot.reserve == id then
				slot.reserve = nil
			end
		end
	end
	for _, pair in farm.breeding.pairs do
		if pair.a == id or pair.b == id then
			pair.a, pair.b = nil, nil
			pair.courtingUntil = nil
		end
	end
	for _, team in farm.teams do
		local inTeam = table.find(team.members, id)
		if inTeam then
			table.remove(team.members, inTeam)
		end
		if team.formation then
			team.formation[id] = nil
			if next(team.formation) == nil then
				team.formation = nil
			end
		end
	end
	-- (farms built by hand in older specs may have no arena)
	local arena = (farm :: any).arena
	if type(arena) == "table" and type(arena.team) == "table" then
		local inArena = table.find(arena.team, id)
		if inArena then
			table.remove(arena.team, inArena)
		end
	end
	return true
end

-- The slimes (and the eggs that will be slimes) a farm can hold: what its village allows (populationLimit) plus the
-- slots of the Bigger Ranch pass.
function FarmState.capacity(farm: Farm): number
	return FarmState.populationLimit(farm.areas) + Boosts.extraSlots(farm)
end

function FarmState.populationLimit(areas: Areas): number
	local villageLevel = FarmState.villageLevel(areas)
	local steps = Config.Village.PopulationProgression
	local previous = steps[1]
	for _, nextStep in steps do
		if villageLevel < nextStep.level then
			-- Whole-slime increments per village level, with no jumps larger than two.
			local span = nextStep.level - previous.level
			return previous.cap + math.floor((nextStep.cap - previous.cap) * (villageLevel - previous.level) / span)
		end
		previous = nextStep
	end
	return previous.cap
end

function FarmState.findSlime(farm: Farm, id: string): (Slime?, number?)
	for i, s in farm.slimes do
		if s.id == id then
			return s, i
		end
	end
	return nil, nil
end

function FarmState.findEgg(farm: Farm, id: string): (Egg?, number?)
	for i, e in farm.eggs do
		if e.id == id then
			return e, i
		end
	end
	return nil, nil
end

-- The original's starter seeds: 0x9e3779b9 xor (i * 0x85ebca6b), as unsigned 32-bit.
local function starterSeed(index: number): number
	return bit32.bxor(0x9e3779b9, ((index - 1) * 0x85ebca6b) % 4294967296)
end

-- ===== a fresh farm =====

function FarmState.newAvatar(now: number): Avatar
	local s = Config.Farm.AvatarStats
	return {
		name = Config.Farm.AvatarName,
		assetId = "slime.base." .. Config.Farm.StarterColour,
		stats = { attack = s.attack, defence = s.defence, speed = s.speed, hp = s.hp },
		spentPoints = 0,
		loadout = {},
		createdAt = now,
		frame = Config.Farm.AvatarFrame,
		bg = Config.Farm.AvatarBackground,
		ownedFrames = {},
		ownedBgs = {},
	}
end

function FarmState.newStarters(now: number): { Slime }
	local colour = Config.Farm.StarterColour
	local stats = StatsModule.starter()
	-- Starters are adults from the first second: born one full grow-up ago. (The original used
	-- now - 300 s, which left level-4 starters babies for 3 s, against its own "already adult".)
	local createdAt = now - Growth.growUpSeconds(StatsModule.level(stats), Config.Village.StartLevel - 1)
	local out = {}
	for i = 1, Config.Farm.StarterCount do
		table.insert(out, {
			id = "slime-" .. i,
			name = "Slime " .. i,
			seed = starterSeed(i),
			assetId = "slime.base." .. colour,
			stats = StatsModule.starter(),
			colourGenotype = Genetics.homozygous(colour),
			visibleColour = colour,
			appearanceMutation = Mutations.none(),
			isFavourite = false,
			needs = FarmState.fullNeeds(),
			trait = FarmState.traitForSeed(starterSeed(i)),
			friends = {},
			buff = nil,
			autoDish = nil,
			ghostUntil = nil,
			createdAt = createdAt,
			breedReadyAt = 0,
			loadout = FarmState.emptyLoadout(),
			gear = FarmState.emptyGear(),
		})
	end
	return out
end

function FarmState.newFarm(now: number): Farm
	local f = Config.Farm
	local discoveries = FarmState.emptyDiscoveries()
	-- The starters make their colour known from the start.
	discoveries.base[f.StarterColour] = { firstDiscoveredAt = now, hatchCount = f.StarterCount }
	local items = {}
	for _, row in f.StarterItems do
		table.insert(items, { id = row[1], definitionId = row[2], ownership = { kind = "INVENTORY" } })
	end
	local areas = FarmState.newAreas()
	local starters = FarmState.newStarters(now)
	return {
		slimes = starters,
		eggs = {},
		breedsSinceMutation = 0,
		discoveries = discoveries,
		areas = areas,
		work = FarmState.newWork(areas),
		storehouse = table.clone(Config.Food.Start),
		counter = {},
		fridge = {},
		breeding = FarmState.newPairing(areas.breeding.level),
		teams = FarmState.newTeams(),
		lastSimulatedAt = now,
		coins = f.StartingCoins,
		items = items,
		materials = {},
		gear = {},
		lifetime = {
			coinsEarned = 0,
			foodFarmed = 0,
			bestSlimeLevel = StatsModule.level(starters[1].stats),
			daysPlayed = 1,
			lastPlayedDay = FarmState.dayKey(now),
			mobsKilled = 0,
			bossesKilled = 0,
			breeds = 0,
			bestRaidKillSec = 0,
			slimesSold = 0,
			meals = 0,
			dungeonWaves = 0,
			arenaAttacks = 0,
			gearCrafted = 0,
			dishesCooked = 0,
			fishCaught = 0,
			cropsHarvested = 0,
			wheelSpins = 0,
			secsPlayed = 0,
		},
		avatar = FarmState.newAvatar(now),
		tutorialDone = false,
		tutorialDoneAt = nil,
		guide = FarmState.newGuide(false),
		rewards = FarmState.newRewards(),
		dungeon = FarmState.newDungeon(),
		world = FarmState.newWorld(),
		arena = FarmState.newArena(now),
		boosts = FarmState.newBoosts(),
		robux = FarmState.newRobux(),
		luckPotionUntil = nil,
		lastSiegeTeam = nil,
		wbKingSlain = nil,
	}
end

-- ===== load repair =====
-- Rule (from the original): repair the broken field, keep every unrelated valid field; one bad
-- slime, egg or block never erases the farm. Only a farm with no usable slime at all starts over.

local function isNum(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function isText(v: any): boolean
	return type(v) == "string" and v ~= ""
end

local function nonNegInt(v: any, default: number): number
	if isNum(v) and v >= 0 then
		return math.floor(v)
	end
	return default
end

local function stringList(raw: any, keep: ((string) -> boolean)?): { string }
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	local seen = {}
	for _, v in raw do
		if type(v) == "string" and not seen[v] and (keep == nil or keep(v)) then
			seen[v] = true
			table.insert(out, v)
		end
	end
	return out
end

local function validateLoadout(raw: any, slots: { string }, warnings: { string }, prefix: string): { [string]: string }
	local out = {}
	if type(raw) ~= "table" then
		if raw ~= nil then
			table.insert(warnings, prefix .. ": invalid loadout, emptied")
		end
		return out
	end
	for _, slot in slots do
		if isText(raw[slot]) then
			out[slot] = raw[slot]
		end
	end
	return out
end

local function validateNeeds(raw: any, warnings: { string }, prefix: string): Needs
	local out = FarmState.fullNeeds()
	for _, key in { "fullness", "energy", "fun" } do
		local value = if type(raw) == "table" then raw[key] else nil
		if isNum(value) then
			(out :: any)[key] = math.clamp(value, 0, Config.Needs.Max)
			if value ~= (out :: any)[key] then
				table.insert(warnings, prefix .. "." .. key .. ": clamped")
			end
		elseif type(raw) ~= "table" or value == nil then
			table.insert(warnings, prefix .. "." .. key .. ": missing, filled")
		end
	end
	return out
end

local function validateFriends(raw: any, selfId: string): { [string]: number }
	local ranked: { { id: string, score: number } } = {}
	if type(raw) == "table" then
		for id, value in raw do
			if type(id) == "string" and id ~= selfId and isNum(value) then
				table.insert(ranked, { id = id, score = math.clamp(value, 0, Config.Needs.Max) })
			end
		end
	end
	table.sort(ranked, function(a, b)
		if a.score == b.score then
			return a.id < b.id
		end
		return a.score > b.score
	end)
	local out: { [string]: number } = {}
	for i = 1, math.min(#ranked, Config.Village.MaxFriends) do
		out[ranked[i].id] = ranked[i].score
	end
	return out
end

local function validateBuff(raw: any): Buff?
	if
		type(raw) == "table"
		and table.find(StatsModule.Keys, raw.stat)
		and isNum(raw.percent)
		and isNum(raw.untilTime)
		and raw.untilTime >= 0
	then
		return {
			stat = raw.stat,
			percent = math.clamp(raw.percent, 0, Config.Needs.Max),
			untilTime = raw.untilTime,
			dish = if type(raw.dish) == "string" and (Config.Food.Dishes :: any)[raw.dish] then raw.dish else nil,
		}
	end
	return nil
end

-- The gear a slime wears: a known piece in the slot it belongs to stays; a known piece in the wrong slot goes back to the
-- bag (`returned`); an unknown id is dropped.
local function validateWornGear(
	raw: any,
	returned: { [string]: number },
	warnings: { string },
	prefix: string
): WornGear
	local out: { [string]: string } = {}
	if type(raw) ~= "table" then
		if raw ~= nil then
			table.insert(warnings, prefix .. ": invalid gear, emptied")
		end
		return out
	end
	for _, slot in Config.Smithy.Slots do
		local id = raw[slot]
		if id ~= nil then
			local piece = if type(id) == "string" then (Config.Smithy.Gear :: any)[id] else nil
			if piece and piece.slot == slot then
				out[slot] = id
			elseif piece then
				returned[id] = (returned[id] or 0) + 1
				table.insert(warnings, prefix .. ": " .. id .. " was in the wrong slot, back in the bag")
			else
				table.insert(warnings, prefix .. ": unknown gear " .. tostring(id) .. " dropped")
			end
		end
	end
	return out :: WornGear
end

-- The gear bag: known pieces with whole counts above zero; anything else is dropped.
local function validateBag(raw: any, warnings: { string }): { [string]: number }
	local out: { [string]: number } = {}
	if type(raw) ~= "table" then
		if raw ~= nil then
			table.insert(warnings, "gear bag: not a table, emptied")
		end
		return out
	end
	for id, count in raw do
		if
			type(id) == "string"
			and (Config.Smithy.Gear :: any)[id]
			and isNum(count)
			and count % 1 == 0
			and count > 0
		then
			out[id] = count
		else
			table.insert(warnings, "gear bag: " .. tostring(id) .. " dropped")
		end
	end
	return out
end

local function validateSlime(
	raw: any,
	index: number,
	now: number,
	warnings: { string },
	returned: { [string]: number }
): Slime?
	if type(raw) ~= "table" then
		table.insert(warnings, "slime[" .. index .. "]: not a table, dropped")
		return nil
	end
	local id = raw.id
	if not isText(id) then
		table.insert(warnings, "slime[" .. index .. "]: missing id, dropped")
		return nil
	end
	local stats = StatsModule.validate(raw.stats, warnings, id .. ".stats")
	local assetId = if isText(raw.assetId) then raw.assetId else "slime.base." .. Config.Farm.StarterColour
	local repairedGenotype = Genetics.validateColour(raw.colourGenotype, warnings, id)
	local genotype: ColourGenotype
	if repairedGenotype then
		genotype = repairedGenotype
	else
		-- Unusable genes: rebuild them from the stored colour or the asset, as the original did.
		local derived = if Colours.isValid(raw.visibleColour)
			then raw.visibleColour
			else Colours.fromAssetId(assetId) or Colours.Fallback
		genotype = Genetics.homozygous(derived)
		table.insert(warnings, id .. ": colour genotype unusable, set to " .. derived .. "/" .. derived)
	end
	local appearance = Mutations.validate(raw.appearanceMutation)
	genotype = Genetics.fromAppearance(appearance, genotype)
	local visibleColour = Genetics.visibleColour(appearance, genotype)
	if raw.visibleColour ~= nil and raw.visibleColour ~= visibleColour then
		table.insert(warnings, id .. ": stored colour differs from the genes, recomputed")
	end
	local createdAt = if isNum(raw.createdAt) and raw.createdAt > 0 then raw.createdAt else now
	if createdAt ~= raw.createdAt then
		table.insert(warnings, id .. ": createdAt invalid, set to now")
	end
	local breedReadyAt = if isNum(raw.breedReadyAt) and raw.breedReadyAt >= 0 then raw.breedReadyAt else 0
	if breedReadyAt ~= raw.breedReadyAt then
		table.insert(warnings, id .. ": breedReadyAt invalid, set to ready")
	end
	if not Mutations.isKnown(appearance) then
		table.insert(warnings, id .. ": unknown " .. appearance.type .. " design kept (placeholder art)")
	end
	return {
		id = id,
		name = if isText(raw.name) then raw.name else "Slime " .. index,
		seed = if isNum(raw.seed) then raw.seed else Rng.hash(id),
		assetId = assetId,
		stats = stats,
		colourGenotype = genotype,
		visibleColour = visibleColour,
		appearanceMutation = appearance,
		isFavourite = raw.isFavourite == true,
		needs = validateNeeds(raw.needs, warnings, id),
		trait = if table.find(Config.Village.Traits, raw.trait)
			then raw.trait
			else FarmState.traitForSeed(if isNum(raw.seed) then raw.seed else Rng.hash(id)),
		friends = validateFriends(raw.friends, id),
		buff = validateBuff(raw.buff),
		autoDish = if type(raw.autoDish) == "string" and (Config.Food.Dishes :: any)[raw.autoDish]
			then raw.autoDish
			else nil,
		ghostUntil = if isNum(raw.ghostUntil) and raw.ghostUntil > 0 then raw.ghostUntil else nil,
		createdAt = createdAt,
		breedReadyAt = breedReadyAt,
		loadout = validateLoadout(raw.loadout, FarmState.SlimeSlots, warnings, id) :: Loadout,
		gear = validateWornGear(raw.gear, returned, warnings, id),
	}
end

local function validateEgg(raw: any, now: number, warnings: { string }): Egg?
	if type(raw) ~= "table" then
		table.insert(warnings, "egg: not a table, dropped")
		return nil
	end
	local id = raw.id
	if not isText(id) then
		table.insert(warnings, "egg: missing id, dropped")
		return nil
	end
	local parents = raw.parentIds
	local parentsOk = type(parents) == "table"
		and #parents == 2
		and type(parents[1]) == "string"
		and type(parents[2]) == "string"
	local createdOk = isNum(raw.createdAt) and raw.createdAt > 0
	local place = if raw.place == "nest" then "nest" else "incubator"
	if place == "incubator" and not (isNum(raw.hatchAt) and raw.hatchAt > 0) then
		-- Recover a valid embryo as a waiting nest egg when its timer is corrupt.
		place = "nest"
		table.insert(warnings, "egg " .. id .. ": invalid incubation, returned to nest")
	end
	if not (parentsOk and createdOk and isText(raw.offspringId)) then
		table.insert(warnings, "egg " .. id .. ": invalid parents, times, slot or offspring id, dropped")
		return nil
	end

	local embryo = raw.embryo
	local genotype = if type(embryo) == "table"
		then Genetics.validateColour(embryo.colourGenotype, warnings, "egg " .. id)
		else nil
	if genotype == nil then
		table.insert(warnings, "egg " .. id .. ": embryo unusable, dropped")
		return nil
	end
	-- The embryo was decided when the egg was laid: it is repaired, never rerolled.
	local appearance = Mutations.validate(embryo.appearanceMutation)
	genotype = Genetics.fromAppearance(appearance, genotype)
	if not Mutations.isKnown(appearance) then
		table.insert(warnings, "egg " .. id .. ": unknown " .. appearance.type .. " design kept (placeholder art)")
	end
	-- Never restart or extend the timer.
	-- (a nest egg keeps its clock too: it hatches in the nest, slower; one without a clock gets one from the
	-- village simulation, which starts it at the nest rate)
	local hatchAt = if isNum(raw.hatchAt) and raw.hatchAt > 0 then math.max(raw.hatchAt, raw.createdAt) else nil
	local egg: Egg = {
		id = id,
		parentIds = { parents[1], parents[2] },
		createdAt = raw.createdAt,
		hatchAt = hatchAt,
		hatchStart = if hatchAt ~= nil
				and isNum(raw.hatchStart)
				and raw.hatchStart < hatchAt
			then raw.hatchStart
			else nil,
		place = place,
		slot = if isNum(raw.slot) and raw.slot >= 1 then math.floor(raw.slot) else 1,
		offspringId = raw.offspringId,
		embryo = {
			stats = StatsModule.validate(embryo.stats, warnings, "egg " .. id .. ".embryo"),
			colourGenotype = genotype,
			appearanceMutation = appearance,
		},
		status = "incubating",
		injected = if raw.injected == true then true else nil,
		statBoosted = if raw.statBoosted == true then true else nil,
	}
	egg.status = FarmState.eggStatus(egg, now)
	return egg
end

local function validateDiscoveries(raw: any, warnings: { string }): Discoveries
	local out = FarmState.emptyDiscoveries()
	if raw == nil then
		return out
	end
	if type(raw) ~= "table" then
		table.insert(warnings, "discoveries invalid, emptied")
		return out
	end
	for _, kind in { "base", "dual", "secret", "material" } do
		local bucket = raw[kind]
		if type(bucket) == "table" then
			local target = (out :: any)[kind]
			for id, rec in bucket do
				if
					type(id) == "string"
					and type(rec) == "table"
					and isNum(rec.firstDiscoveredAt)
					and isNum(rec.hatchCount)
					and rec.hatchCount >= 1
				then
					target[id] = { firstDiscoveredAt = rec.firstDiscoveredAt, hatchCount = math.floor(rec.hatchCount) }
				else
					table.insert(warnings, "discoveries." .. kind .. "." .. tostring(id) .. ": invalid record, dropped")
				end
			end
		end
	end
	return out
end

local function validCount(v: any): number
	return if isNum(v) and v > 0 then math.floor(v) else 0
end

local function validateAreas(raw: any): Areas
	local areas = FarmState.newAreas()
	for _, id in Config.Village.Areas do
		local row = if type(raw) == "table" then raw[id] else nil
		if type(row) == "table" and isNum(row.level) then
			(areas :: any)[id].level =
				math.clamp(math.floor(row.level), Config.Village.StartLevel, Config.Village.MaxLevel)
		end
	end
	return areas
end

function FarmState.storehouseCapacity(level: number): number
	return Config.Food.StorehouseBase + Config.Food.StorehousePerLevel * (level - Config.Village.StartLevel)
end

function FarmState.fridgeCapacity(level: number): number
	return Config.Food.FridgeBase + Config.Food.FridgePerLevel * (level - Config.Village.StartLevel)
end

local function validateStock(raw: any, keys: { string }, capacity: number): { [string]: number }
	local out: { [string]: number } = {}
	local left = capacity
	for _, key in keys do
		local value = if type(raw) == "table" then validCount(raw[key]) else 0
		local keep = math.min(value, left)
		if keep > 0 then
			out[key] = keep
			left -= keep
		end
	end
	return out
end

local function validateWork(raw: any, areas: Areas, slimes: { Slime }, now: number): Work
	local out = FarmState.newWork(areas)
	local taken: { [string]: boolean } = {}
	local known: { [string]: Slime } = {}
	for _, slime in slimes do
		known[slime.id] = slime
	end
	for _, id in Config.Work.Areas do
		local w = if type(raw) == "table" then raw[id] else nil
		local area = (out :: any)[id] :: WorkArea & { plots: typeof(GardenPlots.new(1))? }
		if id == "garden" then
			local rawPlots = if type(w) == "table" then w.plots else nil
			local count = Config.Work.GardenPlotCount
			if type(rawPlots) == "table" then
				count = math.clamp(math.max(count, #rawPlots), 1, Config.Work.GardenMaxPlotCount)
			end
			area.plots = GardenPlots.repair(rawPlots, count)
		end
		if type(w) == "table" then
			area.box = validateStock(w.box, Config.Food.RawOrder, Config.Work.BoxCapacity)
			if id == "kitchen" then
				area.box = validateStock(w.box, Config.Food.DishOrder, Config.Work.BoxCapacity)
			elseif id == "training" then
				area.box = {}
			end
			for i, slot in area.slots do
				local old = if type(w.slots) == "table" then w.slots[i] else nil
				if type(old) == "table" then
					slot.progress = if isNum(old.progress) then math.max(0, old.progress) else 0
					local pendingKind = if type(old.pending) == "string"
						then (Config.Food.Kinds :: any)[old.pending]
						else nil
					if
						pendingKind
						and (
							(id == "fishing" and pendingKind.group == "fish")
							or (id == "garden" and pendingKind.group == "veg")
						)
					then
						slot.pending = old.pending
					end
					if
						id == "garden"
						and type(old.plot) == "number"
						and old.plot % 1 == 0
						and old.plot >= 1
						and old.plot <= (if area.plots then #area.plots else 0)
						and table.find({ "hoe", "plant", "water", "harvest" }, old.task)
					then
						slot.plot, slot.task = old.plot, old.task
					end
					if id == "kitchen" and type(old.recipe) == "string" and (Config.Food.Dishes :: any)[old.recipe] then
						slot.recipe = old.recipe
					end
					if id == "training" and table.find(StatsModule.Keys, old.stat) then
						slot.stat = old.stat
					end
					for _, role in { "worker", "reserve" } do
						local sid = old[role]
						local slime = if type(sid) == "string" then known[sid] else nil
						if
							slime
							and not taken[sid]
							and (slime.ghostUntil == nil or slime.ghostUntil <= now)
							and not Growth.isBaby(
								slime.createdAt,
								now,
								StatsModule.level(slime.stats),
								(areas :: any).breeding.level - Config.Village.StartLevel
							)
						then
							(slot :: any)[role] = sid
							taken[sid] = true
						end
					end
				end
			end
		end
	end
	return out
end

local function validatePairs(raw: any, areas: Areas, slimes: { Slime }, work: Work, now: number): Pairing
	local pairs: { Pair } = {}
	local taken: { [string]: boolean } = {}
	local known: { [string]: Slime } = {}
	for _, s in slimes do
		known[s.id] = s
	end
	for _, id in Config.Work.Areas do
		for _, slot in (work :: any)[id].slots do
			if slot.worker then
				taken[slot.worker] = true
			end
			if slot.reserve then
				taken[slot.reserve] = true
			end
		end
	end
	for i = 1, FarmState.breedingCount(areas.breeding.level) do
		local p = if type(raw) == "table" and type(raw.pairs) == "table" then raw.pairs[i] else nil
		local a = if type(p) == "table" then p.a else nil
		local b = if type(p) == "table" then p.b else nil
		local sa = if type(a) == "string" then known[a] else nil
		local sb = if type(b) == "string" then known[b] else nil
		if
			sa
			and sb
			and a ~= b
			and not taken[a]
			and not taken[b]
			and (sa.ghostUntil == nil or sa.ghostUntil <= now)
			and (sb.ghostUntil == nil or sb.ghostUntil <= now)
			and not Growth.isBaby(sa.createdAt, now, StatsModule.level(sa.stats), areas.breeding.level - 1)
			and not Growth.isBaby(sb.createdAt, now, StatsModule.level(sb.stats), areas.breeding.level - 1)
		then
			table.insert(pairs, {
				a = a,
				b = b,
				courtingUntil = if isNum(p.courtingUntil) and p.courtingUntil >= 0 then p.courtingUntil else nil,
			})
			taken[a], taken[b] = true, true
		else
			table.insert(pairs, {})
		end
	end
	return { pairs = pairs }
end

-- The teams: exactly Config.Zombies.Teams of them. A member must be a slime of the farm (one lost for good is gone from it),
-- in one team only and not at a job or in a pair (those won the slime first); the rest of a team survives a bad member.
local function validateTeams(raw: any, slimes: { Slime }, work: Work, pairing: Pairing, warnings: { string }): { Team }
	local known: { [string]: boolean } = {}
	for _, slime in slimes do
		known[slime.id] = true
	end
	local taken: { [string]: boolean } = {}
	for _, id in Config.Work.Areas do
		for _, slot in (work :: any)[id].slots do
			if slot.worker then
				taken[slot.worker] = true
			end
			if slot.reserve then
				taken[slot.reserve] = true
			end
		end
	end
	for _, pair in pairing.pairs do
		if pair.a then
			taken[pair.a] = true
		end
		if pair.b then
			taken[pair.b] = true
		end
	end
	local teams = FarmState.newTeams()
	if raw ~= nil and type(raw) ~= "table" then
		table.insert(warnings, "teams invalid, emptied")
		return teams
	end
	for index, team in teams do
		local row = if type(raw) == "table" then raw[index] else nil
		if type(row) == "table" then
			if type(row.members) == "table" then
				for _, id in row.members do
					if #team.members >= Config.Zombies.TeamSize then
						break
					end
					if type(id) == "string" and known[id] and not taken[id] then
						taken[id] = true
						table.insert(team.members, id)
					else
						table.insert(warnings, "team " .. index .. ": a member dropped")
					end
				end
			end
			team.repeatOn = row.repeatOn == true
			if isText(row.target) and #row.target <= Config.Zombies.TargetIdMaxLength then
				team.target = row.target
			end
			if type(row.formation) == "table" then
				local formation: { [string]: string } = {}
				for id, chosen in row.formation do
					if
						type(id) == "string"
						and table.find(team.members, id)
						and type(chosen) == "string"
						and table.find(Config.Classes.Rows.Order, chosen)
					then
						formation[id] = chosen
					end
				end
				if next(formation) then
					team.formation = formation
				end
			end
			if row.tactic == "focus" or row.tactic == "protect" then
				team.tactic = row.tactic
			end
			local band = row.explore
			if type(band) == "number" and band % 1 == 0 and band >= 1 and band <= WorldPacks.bands() then
				team.explore = band
			end
		end
	end
	return teams
end

local function validateItems(raw: any, warnings: { string }): { Item }
	local out = {}
	if raw == nil then
		return out
	end
	if type(raw) ~= "table" then
		table.insert(warnings, "items invalid, emptied")
		return out
	end
	local removed = {}
	for _, id in Config.Farm.RemovedItemDefinitions do
		removed[id] = true
	end
	local seen = {}
	for _, it in raw do
		if type(it) ~= "table" or not isText(it.id) then
			table.insert(warnings, "item: invalid, dropped")
		elseif seen[it.id] then
			table.insert(warnings, "item " .. it.id .. ": duplicate, dropped")
		else
			seen[it.id] = true
			local definitionId = if type(it.definitionId) == "string" then it.definitionId else ""
			if removed[definitionId] then
				table.insert(warnings, "item " .. it.id .. ": retired gear, removed")
			else
				local own = it.ownership
				local ownership: ItemOwnership = { kind = "INVENTORY" }
				local slotOk = type(own) == "table" and (own.slot == "head" or own.slot == "hand" or own.slot == "tail")
				if
					type(own) == "table"
					and own.kind == "EQUIPPED_TO_SLIME"
					and type(own.slimeId) == "string"
					and slotOk
				then
					ownership = { kind = "EQUIPPED_TO_SLIME", slimeId = own.slimeId, slot = own.slot }
				elseif type(own) == "table" and (own.kind == "BATTLE_ESCROW" or own.kind == "PENDING_RETURN") then
					-- A save is never loaded mid-battle: escrowed gear would be stuck forever.
					table.insert(warnings, "item " .. it.id .. ": released from " .. own.kind)
				end
				table.insert(out, { id = it.id, definitionId = definitionId, ownership = ownership })
			end
		end
	end
	return out
end

local function validateAvatar(raw: any, now: number, warnings: { string }): Avatar
	if type(raw) ~= "table" then
		return FarmState.newAvatar(now)
	end
	local st = if type(raw.stats) == "table" then raw.stats else {}
	local function stat(v: any, min: number): number
		return math.max(min, if isNum(v) then v else min)
	end
	local stats = {
		attack = stat(st.attack, 1),
		defence = stat(st.defence, 1),
		speed = stat(st.speed, 1),
		hp = stat(st.hp, 10),
	}
	if stats.attack ~= st.attack or stats.hp ~= st.hp then
		table.insert(warnings, "avatar: stats repaired")
	end
	local name = if isText(raw.name)
		then string.sub(raw.name, 1, Config.Farm.AvatarNameMaxLength)
		else Config.Farm.AvatarName
	return {
		name = name,
		assetId = if type(raw.assetId) == "string" then raw.assetId else "slime.base." .. Config.Farm.StarterColour,
		stats = stats,
		spentPoints = nonNegInt(raw.spentPoints, 0),
		loadout = validateLoadout(raw.loadout, FarmState.AvatarSlots, warnings, "avatar") :: AvatarLoadout,
		createdAt = if isNum(raw.createdAt) then raw.createdAt else now,
		frame = if type(raw.frame) == "string" then raw.frame else Config.Farm.AvatarFrame,
		bg = if type(raw.bg) == "string" then raw.bg else Config.Farm.AvatarBackground,
		ownedFrames = stringList(raw.ownedFrames),
		ownedBgs = stringList(raw.ownedBgs),
	}
end

-- Each part of the rewards is repaired alone; a quest list is kept only whole (a damaged one is made again the next time
-- the server looks, from that moment's counts).
local function validateRewards(raw: any, warnings: { string }): Rewards
	local out = FarmState.newRewards()
	if type(raw) ~= "table" then
		if raw ~= nil then
			table.insert(warnings, "rewards: not a table, reset")
		end
		return out
	end
	local daily = raw.daily
	if type(daily) == "table" then
		out.daily = {
			streak = math.min(nonNegInt(daily.streak, 0), #Config.Rewards.Daily),
			day = nonNegInt(daily.day, 0),
		}
	end
	-- A list of quests, kept only whole (nil when any is damaged or the list is longer than `most`).
	local function questList(rawList: any, most: number, kindAt: (number, string) -> boolean): { Quest }?
		if type(rawList) ~= "table" or #rawList > most then
			return nil
		end
		local list: { Quest } = {}
		for index, q in rawList do
			if
				type(index) == "number"
				and type(q) == "table"
				and type(q.kind) == "string"
				and kindAt(index, q.kind)
				and isNum(q.need)
				and q.need >= 1
				and isNum(q.mark)
			then
				table.insert(
					list,
					{ kind = q.kind, need = math.floor(q.need), mark = q.mark, claimed = q.claimed == true }
				)
			else
				return nil
			end
		end
		return list
	end
	local quests = raw.quests
	if type(quests) == "table" and type(quests.list) == "table" then
		local list = questList(quests.list, Config.Rewards.QuestCount, function(_, kind)
			return table.find(Config.Rewards.QuestKinds, kind) ~= nil
		end)
		if list then
			out.quests = {
				day = nonNegInt(quests.day, 0),
				list = list,
				bonus = quests.bonus == true,
				rerolls = nonNegInt(quests.rerolls, 0),
				freeUsed = nonNegInt(quests.freeUsed, 0),
			}
		else
			table.insert(warnings, "rewards: quests damaged, made again")
		end
	end
	local weekly = raw.weekly
	if type(weekly) == "table" then
		local list = questList(weekly.list, #Config.Rewards.Weekly, function(index, kind)
			return Config.Rewards.Weekly[index].kind == kind
		end)
		if list and (#list == #Config.Rewards.Weekly or #list == 0) then
			out.weekly = { week = nonNegInt(weekly.week, 0), list = list, chest = weekly.chest == true }
		else
			table.insert(warnings, "rewards: weekly quests damaged, made again")
		end
	end
	out.checkins = nonNegInt(raw.checkins, 0)
	if type(raw.milestones) == "table" then
		for _, index in raw.milestones do
			if
				isNum(index)
				and index % 1 == 0
				and Config.Rewards.CheckinMilestones[index] ~= nil
				and not table.find(out.milestones, index)
			then
				table.insert(out.milestones, index)
			end
		end
	end
	if type(raw.goals) == "table" then
		for _, goal in Config.Goals.List do
			if raw.goals[goal.id] == true then
				out.goals[goal.id] = true
			end
		end
	end
	if type(raw.wheel) == "table" then
		out.wheel = {
			day = nonNegInt(raw.wheel.day, 0),
			used = nonNegInt(raw.wheel.used, 0),
			bank = math.min(nonNegInt(raw.wheel.bank, 0), Config.Wheel.BankCap),
		}
	end
	local online = raw.online
	if type(online) == "table" then
		local claimed: { number } = {}
		if type(online.claimed) == "table" then
			for _, step in online.claimed do
				if
					isNum(step)
					and step % 1 == 0
					and Config.Rewards.Online[step] ~= nil
					and not table.find(claimed, step)
				then
					table.insert(claimed, step)
				end
			end
		end
		out.online = { day = nonNegInt(online.day, 0), secs = nonNegInt(online.secs, 0), claimed = claimed }
	end
	out.indexSeen = raw.indexSeen == true
	if type(raw.social) == "table" then
		out.social = { favorite = raw.social.favorite == true, group = raw.social.group == true }
	end
	return out
end

-- The dungeon's best level is a whole number, never negative; anything else starts the ladder over (nothing else is stored).
local function validateDungeon(raw: any, warnings: { string }): Dungeon
	if type(raw) ~= "table" then
		if raw ~= nil then
			table.insert(warnings, "dungeon: not a table, reset")
		end
		return FarmState.newDungeon()
	end
	if raw.best ~= nil and not (isNum(raw.best) and raw.best >= 0 and raw.best % 1 == 0) then
		table.insert(warnings, "dungeon: best level damaged, repaired")
	end
	return { best = nonNegInt(raw.best, 0) }
end

-- The zones won: a known zone id and the whole, positive time of the win; anything else is dropped.
local function validateWorld(raw: any, warnings: { string }): World
	local out = FarmState.newWorld()
	if type(raw) ~= "table" or type(raw.beaten) ~= "table" then
		if raw ~= nil then
			table.insert(warnings, "world: damaged, reset")
		end
		return out
	end
	for id, at in raw.beaten do
		if type(id) == "string" and (Config.World.Zones :: any)[id] and isNum(at) and at > 0 and at % 1 == 0 then
			out.beaten[id] = at
		else
			table.insert(warnings, "world: a damaged win dropped")
		end
	end
	return out
end

-- The Gold and Hatch Potion end times: a time or 0 each.
local function validateBoosts(raw: any): Boosts
	local out = FarmState.newBoosts()
	if type(raw) == "table" then
		out.gold = nonNegInt(raw.gold, 0)
		out.hatch = nonNegInt(raw.hatch, 0)
	end
	return out
end

-- The Robux part of the save, each field repaired alone. Receipts keep their order (newest last) and are cut to the newest
-- Config.Robux.ReceiptsKept; passes keep only the keys of Config.Robux.Products of kind "pass".
local function validateRobux(raw: any): Robux
	local out = FarmState.newRobux()
	if type(raw) ~= "table" then
		return out
	end
	out.receipts = stringList(raw.receipts)
	while #out.receipts > Config.Robux.ReceiptsKept do
		table.remove(out.receipts, 1)
	end
	if type(raw.passes) == "table" then
		for _, product in Config.Robux.Products do
			if product.kind == "pass" and raw.passes[product.key] == true then
				out.passes[product.key] = true
			end
		end
	end
	out.starterBought = raw.starterBought == true
	out.rerolls = nonNegInt(raw.rerolls, 0)
	out.savers = nonNegInt(raw.savers, 0)
	out.drinks = nonNegInt(raw.drinks, 0)
	out.hatchAlls = nonNegInt(raw.hatchAlls, 0)
	return out
end

-- The keys of a { [tostring(season)]: true } map, newest kept, at most Config.Arena.KeepSeasons.
local function validateClaimed(raw: any): { [string]: boolean }
	local seasons: { number } = {}
	if type(raw) == "table" then
		for key, value in raw do
			local season = if type(key) == "string" and string.match(key, "^%d+$") then tonumber(key) else nil
			if value == true and season then
				table.insert(seasons, season)
			end
		end
	end
	table.sort(seasons, function(a, b)
		return a > b
	end)
	local out: { [string]: boolean } = {}
	for i = 1, math.min(#seasons, Config.Arena.KeepSeasons) do
		out[tostring(seasons[i])] = true
	end
	return out
end

local function validateArenaQuests(raw: any, now: number): ArenaQuestState
	local out = ArenaQuests.new(now)
	if type(raw) ~= "table" then
		return out
	end
	out.day = nonNegInt(raw.day, out.day)
	out.week = nonNegInt(raw.week, out.week)
	out.season = nonNegInt(raw.season, out.season)
	for _, quest in Config.Arena.Quests do
		if type(raw.counts) == "table" and isNum(raw.counts[quest.id]) then
			out.counts[quest.id] = math.min(nonNegInt(raw.counts[quest.id], 0), quest.wins)
		end
		if type(raw.done) == "table" and raw.done[quest.id] == true then
			out.done[quest.id] = true
		end
	end
	return out
end

-- A match in flight is kept whenever what finds its outcome is readable (its number, season, defender and start); a
-- damaged detail gets a neutral default. Dropping it would lose the match's points.
local function validatePending(raw: any, warnings: { string }): ArenaPending?
	if raw == nil then
		return nil
	end
	if
		type(raw) ~= "table"
		or not (isNum(raw.seq) and raw.seq >= 1 and raw.seq % 1 == 0)
		or not (isNum(raw.season) and raw.season >= 0)
		or not isText(raw.matchId)
		or not isText(raw.defender)
		or not isNum(raw.at)
	then
		table.insert(warnings, "arena: match in flight unreadable, dropped")
		return nil
	end
	return {
		matchId = raw.matchId,
		seq = raw.seq,
		season = math.floor(raw.season),
		defender = raw.defender,
		defenderName = if type(raw.defenderName) == "string" then raw.defenderName else "",
		defenderRank = nonNegInt(raw.defenderRank, 0),
		above = raw.above == true,
		stronger = raw.stronger == true,
		won = raw.won == true,
		power = if isNum(raw.power) and raw.power >= 0 then raw.power else 0,
		seed = if isNum(raw.seed) then raw.seed else 0,
		at = raw.at,
		sentAt = if isNum(raw.sentAt) then raw.sentAt else raw.at,
		requestId = if type(raw.requestId) == "string" then raw.requestId else "",
	}
end

-- Each part of the Arena is repaired alone; a team keeps only own slimes, at most TeamSize, once each.
local function validateArena(raw: any, slimeIds: { [string]: boolean }, now: number, warnings: { string }): Arena
	local out = FarmState.newArena(now)
	if type(raw) ~= "table" then
		if raw ~= nil then
			table.insert(warnings, "arena: not a table, reset")
		end
		return out
	end
	out.points = nonNegInt(raw.points, 0)
	local team = stringList(raw.team, function(s)
		return slimeIds[s] == true
	end)
	for i = #team, Config.Arena.TeamSize + 1, -1 do
		team[i] = nil
	end
	out.team = team
	out.day = nonNegInt(raw.day, out.day)
	out.used = math.min(nonNegInt(raw.used, 0), Config.Arena.TicketsPerDay)
	out.pending = validatePending(raw.pending, warnings)
	-- (the farm's number never falls behind its match in flight, or the next match would read as old)
	out.seq = math.max(nonNegInt(raw.seq, 0), if out.pending then out.pending.seq else 0)
	out.claimed = validateClaimed(raw.claimed)
	local history: { ArenaSeasonRecord } = {}
	local seen: { [number]: boolean } = {}
	if type(raw.history) == "table" then
		for _, entry in raw.history do
			if type(entry) == "table" and isNum(entry.season) and entry.season % 1 == 0 and not seen[entry.season] then
				seen[entry.season] = true
				table.insert(history, {
					season = entry.season,
					rank = nonNegInt(entry.rank, 0),
					badge = if isText(entry.badge) then entry.badge else nil,
					wins = nonNegInt(entry.wins, 0),
				})
			end
		end
	end
	table.sort(history, function(a, b)
		return a.season < b.season
	end)
	while #history > Config.Arena.KeepSeasons do
		table.remove(history, 1)
	end
	out.history = history
	out.quests = validateArenaQuests(raw.quests, now)
	out.season = nonNegInt(raw.season, out.season)
	out.seasonWins = nonNegInt(raw.seasonWins, 0)
	out.bestRank = nonNegInt(raw.bestRank, 0)
	local defense = if type(raw.defense) == "table" then raw.defense else {}
	out.defense = {
		wins = nonNegInt(defense.wins, 0),
		streak = nonNegInt(defense.streak, 0),
		best = nonNegInt(defense.best, 0),
	}
	out.week = nonNegInt(raw.week, out.week)
	if type(raw.bought) == "table" then
		for id, count in raw.bought do
			if isText(id) and isNum(count) and count >= 1 then
				out.bought[id] = math.floor(count)
			end
		end
	end
	out.snapshotAt = if isNum(raw.snapshotAt) and raw.snapshotAt >= 0 then raw.snapshotAt else 0
	return out
end

-- Gear bookkeeping: an item is equipped only while a loadout names it. A loadout slot naming a
-- missing item (or one already claimed; the avatar claims first) is cleared; item ownership is
-- then re-stamped from the claims. Returns how many fixes were made.
local function reconcileItems(farm: Farm): number
	local itemIds = {}
	for _, item in farm.items do
		itemIds[item.id] = true
	end
	local claims: { [string]: { slimeId: string, slot: string } } = {}
	local repaired = 0
	local avatarLoadout = farm.avatar.loadout :: any
	for _, slot in FarmState.AvatarSlots do
		local id = avatarLoadout[slot]
		if id then
			if not itemIds[id] or claims[id] then
				avatarLoadout[slot] = nil
				repaired += 1
			else
				claims[id] = { slimeId = "avatar", slot = slot }
			end
		end
	end
	for _, slime in farm.slimes do
		local loadout = slime.loadout :: any
		for _, slot in FarmState.SlimeSlots do
			local id = loadout[slot]
			if id then
				if not itemIds[id] or claims[id] then
					loadout[slot] = nil
					repaired += 1
				else
					claims[id] = { slimeId = slime.id, slot = slot }
				end
			end
		end
	end
	for _, item in farm.items do
		local claim = claims[item.id]
		local own = item.ownership
		if claim then
			if not (own.kind == "EQUIPPED_TO_SLIME" and own.slimeId == claim.slimeId and own.slot == claim.slot) then
				item.ownership = { kind = "EQUIPPED_TO_SLIME", slimeId = claim.slimeId, slot = claim.slot }
				repaired += 1
			end
		elseif own.kind ~= "INVENTORY" then
			item.ownership = { kind = "INVENTORY" }
			repaired += 1
		end
	end
	return repaired
end

-- Repairs a loaded farm field by field and recomputes derived values (visible colours, egg
-- status, food capacity). Returns the farm, a list of what was repaired (for the log), and whether
-- the stored farm was unusable and replaced by a fresh one: a caller that loads a save must treat
-- that as a failure (fall back to the last-good copy) rather than write the fresh farm over it.
-- Never throws.
function FarmState.repair(data: any, now: number): (Farm, { string }, boolean)
	local warnings: { string } = {}
	if type(data) ~= "table" or type(data.slimes) ~= "table" then
		table.insert(warnings, "farm unreadable, started a fresh farm")
		return FarmState.newFarm(now), warnings, true
	end

	local areas = validateAreas(data.areas)
	-- Only absurd arrays are cut; the population cap limits new births, not recovered saves.
	local slimeCap = math.max(FarmState.populationLimit(areas), Config.Farm.RepairSlimeHardCap)

	local slimes: { Slime } = {}
	local slimeIds: { [string]: boolean } = {}
	-- pieces a slime wore in a slot they do not fit, back to the bag
	local returnedGear: { [string]: number } = {}
	for i, raw in data.slimes do
		if type(i) == "number" then
			if #slimes >= slimeCap then
				table.insert(warnings, "slimes beyond " .. slimeCap .. " dropped")
				break
			end
			local scratch: { [string]: number } = {}
			local slime = validateSlime(raw, i, now, warnings, scratch)
			if slime then
				if slimeIds[slime.id] then
					table.insert(warnings, slime.id .. ": duplicate id, dropped")
				else
					slimeIds[slime.id] = true
					table.insert(slimes, slime)
					for id, count in scratch do
						returnedGear[id] = (returnedGear[id] or 0) + count
					end
				end
			end
		end
	end
	if #slimes == 0 then
		table.insert(warnings, "no usable slime, started a fresh farm")
		return FarmState.newFarm(now), warnings, true
	end

	local eggs: { Egg } = {}
	if data.eggs ~= nil and type(data.eggs) ~= "table" then
		table.insert(warnings, "eggs invalid, emptied")
	elseif type(data.eggs) == "table" then
		local eggIds = {}
		for _, raw in data.eggs do
			local egg = validateEgg(raw, now, warnings)
			if egg then
				if eggIds[egg.id] then
					table.insert(warnings, "egg " .. egg.id .. ": duplicate, dropped")
				else
					eggIds[egg.id] = true
					table.insert(eggs, egg)
				end
			end
		end
	end

	-- A slime claimed by multiple slots is kept in the first valid one.
	local work = validateWork(data.work, areas, slimes, now)
	local breeding = validatePairs(data.breeding, areas, slimes, work, now)

	-- Incumbent incubators keep their clocks; extra eggs fall back to nests, then overflow
	-- places outside the visible slots rather than having their embryos deleted.
	local limit = FarmState.breedingCount(areas.breeding.level)
	local occupiedNest: { [number]: boolean } = {}
	local occupiedIncubator: { [number]: boolean } = {}
	local overflow = limit
	for _, egg in eggs do
		if egg.place == "incubator" then
			local slot = egg.slot
			if slot > limit or occupiedIncubator[slot] then
				local free: number? = nil
				for i = 1, limit do
					if not occupiedIncubator[i] then
						free = i
						break
					end
				end
				if free then
					egg.slot = free
				else
					egg.place = "nest"
					-- (back in a nest, the rest of its time runs at the nest's slower rate)
					if egg.hatchAt then
						FarmState.retimeEgg(
							egg,
							now,
							now + math.max(0, egg.hatchAt - now) * Config.Breeding.NestSlowFactor
						)
					end
				end
			end
			if egg.place == "incubator" then
				occupiedIncubator[egg.slot] = true
			end
		end
		if egg.place == "nest" then
			if egg.slot > limit or occupiedNest[egg.slot] then
				local free: number? = nil
				for i = 1, limit do
					if not occupiedNest[i] then
						free = i
						break
					end
				end
				if free then
					egg.slot = free
				else
					overflow += 1
					egg.slot = overflow
				end
			end
			occupiedNest[egg.slot] = true
		end
		egg.status = FarmState.eggStatus(egg, now)
	end

	local coins = nonNegInt(data.coins, 0)
	if data.coins ~= nil and coins ~= data.coins then
		table.insert(warnings, "coins invalid, clamped")
	end

	local materials: { [string]: number } = {}
	if type(data.materials) == "table" then
		for k, v in data.materials do
			if type(k) == "string" and isNum(v) and v >= 0 then
				materials[k] = v
			end
		end
	end

	local items = validateItems(data.items, warnings)

	local gearBag = validateBag(data.gear, warnings)
	for id, count in returnedGear do
		gearBag[id] = (gearBag[id] or 0) + count
	end

	-- Lifetime counters: each field repaired alone; a legacy save gets honest floors.
	local liveBest = 0
	for _, s in slimes do
		liveBest = math.max(liveBest, StatsModule.level(s.stats))
	end
	local lifetime: Lifetime
	local lt = data.lifetime
	if type(lt) == "table" then
		lifetime = {
			coinsEarned = nonNegInt(lt.coinsEarned, coins),
			foodFarmed = nonNegInt(lt.foodFarmed, 0),
			bestSlimeLevel = math.max(nonNegInt(lt.bestSlimeLevel, 0), liveBest),
			daysPlayed = math.max(1, nonNegInt(lt.daysPlayed, 1)),
			lastPlayedDay = if type(lt.lastPlayedDay) == "string" then lt.lastPlayedDay else "",
			mobsKilled = nonNegInt(lt.mobsKilled, 0),
			bossesKilled = nonNegInt(lt.bossesKilled, 0),
			breeds = nonNegInt(lt.breeds, 0),
			bestRaidKillSec = nonNegInt(lt.bestRaidKillSec, 0),
			slimesSold = nonNegInt(lt.slimesSold, 0),
			meals = nonNegInt(lt.meals, 0),
			dungeonWaves = nonNegInt(lt.dungeonWaves, 0),
			arenaAttacks = nonNegInt(lt.arenaAttacks, 0),
			gearCrafted = nonNegInt(lt.gearCrafted, 0),
			dishesCooked = nonNegInt(lt.dishesCooked, 0),
			fishCaught = nonNegInt(lt.fishCaught, 0),
			cropsHarvested = nonNegInt(lt.cropsHarvested, 0),
			wheelSpins = nonNegInt(lt.wheelSpins, 0),
			secsPlayed = nonNegInt(lt.secsPlayed, 0),
		}
	else
		lifetime = {
			coinsEarned = coins,
			foodFarmed = 0,
			bestSlimeLevel = liveBest,
			daysPlayed = 1,
			lastPlayedDay = FarmState.dayKey(now),
			mobsKilled = 0,
			bossesKilled = 0,
			breeds = 0,
			bestRaidKillSec = 0,
			slimesSold = 0,
			meals = 0,
			dungeonWaves = 0,
			arenaAttacks = 0,
			gearCrafted = 0,
			dishesCooked = 0,
			fishCaught = 0,
			cropsHarvested = 0,
			wheelSpins = 0,
			secsPlayed = 0,
		}
	end

	-- The tutorial: a known step or "done", in step with tutorialDone (nil on a legacy save means the tour is done).
	local tutorialDone = if type(data.tutorialDone) == "boolean" then data.tutorialDone else nil
	local guide = FarmState.newGuide(tutorialDone ~= false)
	local rawGuide = data.guide
	if type(rawGuide) == "table" then
		local step = rawGuide.step
		local known = step == "done" or table.find(Config.Guide.Steps, step) ~= nil
		if known and (step == "done") == (tutorialDone ~= false) then
			guide.step = step
			guide.mark = if isNum(rawGuide.mark) then rawGuide.mark else 0
		elseif step ~= nil then
			table.insert(warnings, "guide: step " .. tostring(step) .. " reset")
		end
		if type(rawGuide.intro) == "string" and table.find(Config.Guide.Intros, rawGuide.intro) then
			guide.intro = rawGuide.intro
			guide.introMark = if isNum(rawGuide.introMark) then rawGuide.introMark else 0
		end
		if type(rawGuide.seen) == "table" then
			for id, value in rawGuide.seen do
				if value == true and type(id) == "string" and table.find(Config.Guide.Intros, id) then
					guide.seen[id] = true
				end
			end
		end
	elseif rawGuide ~= nil then
		table.insert(warnings, "guide: not a table, reset")
	end

	-- The Queen raid unlock: an explicit flag, or evidence only a King kill leaves behind.
	local kingSlain = data.wbKingSlain == true or (materials.crown_shard or 0) > 0 or (materials.royal_jelly or 0) > 0
	for _, item in items do
		if item.definitionId == "helm-royal" then
			kingSlain = true
		end
	end

	local farm: Farm = {
		slimes = slimes,
		eggs = eggs,
		breedsSinceMutation = nonNegInt(data.breedsSinceMutation, 0),
		discoveries = validateDiscoveries(data.discoveries, warnings),
		areas = areas,
		work = work,
		storehouse = validateStock(
			data.storehouse,
			Config.Food.RawOrder,
			FarmState.storehouseCapacity(areas.pantry.level)
		),
		counter = validateStock(data.counter, Config.Food.RawOrder, Config.Food.CounterCapacity),
		fridge = validateStock(data.fridge, Config.Food.DishOrder, FarmState.fridgeCapacity(areas.kitchen.level)),
		breeding = breeding,
		teams = validateTeams(data.teams, slimes, work, breeding, warnings),
		lastSimulatedAt = if isNum(data.lastSimulatedAt) and data.lastSimulatedAt > 0
			then data.lastSimulatedAt
			else now,
		coins = coins,
		items = items,
		materials = materials,
		gear = gearBag,
		lifetime = lifetime,
		avatar = validateAvatar(data.avatar, now, warnings),
		tutorialDone = tutorialDone,
		tutorialDoneAt = if isNum(data.tutorialDoneAt) then data.tutorialDoneAt else nil,
		guide = guide,
		rewards = validateRewards(data.rewards, warnings),
		dungeon = validateDungeon(data.dungeon, warnings),
		world = validateWorld(data.world, warnings),
		arena = validateArena(data.arena, slimeIds, now, warnings),
		boosts = validateBoosts(data.boosts),
		robux = validateRobux(data.robux),
		luckPotionUntil = if isNum(data.luckPotionUntil) and data.luckPotionUntil >= 0
			then data.luckPotionUntil
			else nil,
		lastSiegeTeam = if type(data.lastSiegeTeam) == "table"
			then stringList(data.lastSiegeTeam, function(s)
				return slimeIds[s] == true
			end)
			else nil,
		wbKingSlain = if kingSlain then true else nil,
	}
	local fixed = reconcileItems(farm)
	if fixed > 0 then
		table.insert(warnings, "items: " .. fixed .. " ownership mismatch(es) repaired")
	end
	return farm, warnings, false
end

return FarmState
