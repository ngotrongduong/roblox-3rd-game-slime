--!strict
-- The farm save shape (docs/reference/01-core-farm.md §2), a fresh farm, and the load repair.
-- Differences from the original: times are server epoch seconds; the cosmetic fields (x, y,
-- targetX, targetY, selectedId, avatar x/y) are gone; station progress is in seconds.
-- Battle, food and job fields are kept with the original defaults so later phases need no
-- migration, but no logic for them lives here.

local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local Config = if script then require(script.Parent.Config) else require("./Config")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local StatsModule = if script then require(script.Parent.Stats) else require("./Stats")

local FarmState = {}

-- Sibling types come through typeof: an exported type cannot be read through the if-require.
-- Modules that need the farm types do the same, e.g. typeof(FarmState.newFarm(0)).
export type Stats = typeof(StatsModule.starter())
export type ColourGenotype = typeof(Genetics.homozygous(""))
export type PatternGenotype = typeof(Genetics.solid())
export type Appearance = typeof(Mutations.none())

-- hungerState is derived from hunger: "full", "hungry" or "starving".
export type Needs = { hunger: number, hungerState: string }

-- Item ids in each gear slot (battle).
export type Loadout = { head: string?, hand: string?, tail: string? }

export type Slime = {
	id: string,
	name: string,
	-- Per-slime seed for client-side moods and movement.
	seed: number,
	assetId: string,
	stats: Stats,
	colourGenotype: ColourGenotype,
	patternGenotype: PatternGenotype,
	-- Always the phenotype of colourGenotype; recomputed on load.
	visibleColour: string,
	appearanceMutation: Appearance,
	isFavourite: boolean,
	needs: Needs,
	createdAt: number,
	-- 0 = ready; else the time the breeding rest ends.
	breedReadyAt: number,
	loadout: Loadout,
	fallen: boolean,
	previousLoadout: Loadout?,
}

export type Embryo = {
	stats: Stats,
	colourGenotype: ColourGenotype,
	patternGenotype: PatternGenotype,
	appearanceMutation: Appearance,
}

export type Egg = {
	id: string,
	parentIds: { string },
	createdAt: number,
	hatchAt: number,
	offspringId: string,
	-- Fully decided when the egg is laid; never rerolled.
	embryo: Embryo,
	-- "incubating" or "ready"; derived from hatchAt, never trusted from a save.
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

export type Food = { basicFood: number, capacity: number }

export type Workstation = {
	id: string,
	definitionId: string,
	assignedSlimeIds: { string },
	progressSeconds: number,
	pendingOutput: number,
}

export type Upgrades = {
	foodStorage: number,
	incubationSpeed: number,
	breedCooldown: number,
	growthSpeed: number,
	slimeStorage: number,
	-- Retired in the original (auto-hatch is free); kept for save compatibility.
	autoHatch: number,
	specializedBreeding: number,
}

-- kind: "INVENTORY", "EQUIPPED_TO_SLIME" (with slimeId and slot), "BATTLE_ESCROW", "PENDING_RETURN".
export type ItemOwnership = { kind: string, slimeId: string?, slot: string? }
export type Item = { id: string, definitionId: string, ownership: ItemOwnership }

export type NestPair = { ids: { string }, pickedAt: number }
export type Nest = {
	nestId: string,
	enabled: boolean,
	-- "level", "atk", "def", "hp" or "spd".
	specialty: string,
	memberSlimeIds: { string },
	currentEggId: string?,
	pausedReason: string?,
	pendingPair: NestPair?,
}

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
	food: Food,
	workstations: { Workstation },
	unlockedStations: { string },
	lastSimulatedAt: number,
	coins: number,
	items: { Item },
	materials: { [string]: number },
	upgrades: Upgrades,
	nest: Nest?,
	lifetime: Lifetime,
	avatar: Avatar,
	-- nil on legacy saves means the tour is done.
	tutorialDone: boolean?,
	tutorialDoneAt: number?,
	lastSiegeTeam: { string }?,
	wbKingSlain: boolean?,
}

FarmState.SlimeSlots = { "head", "hand", "tail" }
FarmState.AvatarSlots = { "hand", "head", "tail", "back", "wings", "aura" }
FarmState.NestSpecialties = { "level", "atk", "def", "hp", "spd" }
FarmState.UpgradeKeys = {
	"foodStorage",
	"incubationSpeed",
	"breedCooldown",
	"growthSpeed",
	"slimeStorage",
	"autoHatch",
	"specializedBreeding",
}

-- ===== small shared helpers =====

-- UTC calendar day of a server time. os.date("!*t") is the one form both Roblox and Lune accept.
function FarmState.dayKey(now: number): string
	local t = os.date("!*t", math.floor(now)) :: any
	return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

function FarmState.hungerState(hunger: number): string
	if hunger <= 0 then
		return "starving"
	elseif hunger <= Config.Farm.HungryThreshold then
		return "hungry"
	end
	return "full"
end

function FarmState.fullNeeds(): Needs
	local h = Config.Farm.StartingHunger
	return { hunger = h, hungerState = FarmState.hungerState(h) }
end

function FarmState.emptyLoadout(): Loadout
	return {}
end

function FarmState.emptyUpgrades(): Upgrades
	return {
		foodStorage = 0,
		incubationSpeed = 0,
		breedCooldown = 0,
		growthSpeed = 0,
		slimeStorage = 0,
		autoHatch = 0,
		specializedBreeding = 0,
	}
end

function FarmState.emptyDiscoveries(): Discoveries
	return { base = {}, dual = {}, secret = {}, material = {} }
end

-- Pantry size after the Food Storage upgrade.
function FarmState.foodCapacity(upgrades: Upgrades): number
	return Config.Farm.FoodCapacityBase + upgrades.foodStorage * Config.Farm.FoodCapacityPerLevel
end

-- Slime slots after the More Slime Slots upgrade (20 .. 220).
function FarmState.populationLimit(upgrades: Upgrades): number
	local b = Config.Breeding
	return b.PopulationBase + math.min(b.PopulationMaxLevel, upgrades.slimeStorage) * b.PopulationPerLevel
end

-- Egg status is derived, never stored truth.
function FarmState.eggStatus(egg: Egg, now: number): string
	return if now >= egg.hatchAt then "ready" else "incubating"
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

function FarmState.newWorkstations(): { Workstation }
	local out = {}
	for i, definitionId in Config.Farm.Stations do
		table.insert(out, {
			id = "station-" .. i,
			definitionId = definitionId,
			assignedSlimeIds = {},
			progressSeconds = 0,
			pendingOutput = 0,
		})
	end
	return out
end

function FarmState.newStarters(now: number): { Slime }
	local colour = Config.Farm.StarterColour
	local stats = StatsModule.starter()
	-- Starters are adults from the first second: born one full grow-up ago. (The original used
	-- now - 300 s, which left level-4 starters babies for 3 s, against its own "already adult".)
	local createdAt = now - Growth.growUpSeconds(StatsModule.level(stats), 0)
	local out = {}
	for i = 1, Config.Farm.StarterCount do
		table.insert(out, {
			id = "slime-" .. i,
			name = "Slime " .. i,
			seed = starterSeed(i),
			assetId = "slime.base." .. colour,
			stats = StatsModule.starter(),
			colourGenotype = Genetics.homozygous(colour),
			patternGenotype = Genetics.solid(),
			visibleColour = colour,
			appearanceMutation = Mutations.none(),
			isFavourite = false,
			needs = FarmState.fullNeeds(),
			createdAt = createdAt,
			breedReadyAt = 0,
			loadout = FarmState.emptyLoadout(),
			fallen = false,
			previousLoadout = nil,
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
	local upgrades = FarmState.emptyUpgrades()
	local starters = FarmState.newStarters(now)
	return {
		slimes = starters,
		eggs = {},
		breedsSinceMutation = 0,
		discoveries = discoveries,
		food = { basicFood = f.StartingFood, capacity = FarmState.foodCapacity(upgrades) },
		workstations = FarmState.newWorkstations(),
		unlockedStations = table.clone(f.StartUnlockedStations),
		lastSimulatedAt = now,
		coins = f.StartingCoins,
		items = items,
		materials = {},
		upgrades = upgrades,
		nest = nil,
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
		},
		avatar = FarmState.newAvatar(now),
		tutorialDone = false,
		tutorialDoneAt = nil,
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
	if type(raw) ~= "table" then
		table.insert(warnings, prefix .. ": needs missing, full hunger applied")
		return FarmState.fullNeeds()
	end
	local hunger = if isNum(raw.hunger) then raw.hunger else Config.Farm.StartingHunger
	local clamped = math.clamp(hunger, 0, Config.Farm.MaxHunger)
	if clamped ~= raw.hunger and isNum(raw.hunger) then
		table.insert(warnings, prefix .. ": hunger out of range, clamped")
	end
	return { hunger = clamped, hungerState = FarmState.hungerState(clamped) }
end

local function validateSlime(raw: any, index: number, now: number, warnings: { string }): Slime?
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
	-- The visible colour is always recomputed from the genes.
	local visibleColour = Genetics.phenotype(genotype)
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
	local appearance = Mutations.validate(raw.appearanceMutation)
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
		patternGenotype = Genetics.validatePattern(raw.patternGenotype, warnings, id),
		visibleColour = visibleColour,
		appearanceMutation = appearance,
		isFavourite = raw.isFavourite == true,
		needs = validateNeeds(raw.needs, warnings, id),
		createdAt = createdAt,
		breedReadyAt = breedReadyAt,
		loadout = validateLoadout(raw.loadout, FarmState.SlimeSlots, warnings, id) :: Loadout,
		fallen = raw.fallen == true,
		previousLoadout = if type(raw.previousLoadout) == "table"
			then validateLoadout(raw.previousLoadout, FarmState.SlimeSlots, warnings, id) :: Loadout
			else nil,
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
	local hatchOk = isNum(raw.hatchAt) and raw.hatchAt > 0
	if not (parentsOk and createdOk and hatchOk and isText(raw.offspringId)) then
		table.insert(warnings, "egg " .. id .. ": invalid parents, times or offspring id, dropped")
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
	if not Mutations.isKnown(appearance) then
		table.insert(warnings, "egg " .. id .. ": unknown " .. appearance.type .. " design kept (placeholder art)")
	end
	-- Never restart or extend the timer.
	local hatchAt = math.max(raw.hatchAt, raw.createdAt)
	local egg: Egg = {
		id = id,
		parentIds = { parents[1], parents[2] },
		createdAt = raw.createdAt,
		hatchAt = hatchAt,
		offspringId = raw.offspringId,
		embryo = {
			stats = StatsModule.validate(embryo.stats, warnings, "egg " .. id .. ".embryo"),
			colourGenotype = genotype,
			patternGenotype = Genetics.validatePattern(embryo.patternGenotype, warnings, "egg " .. id),
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

local function validateUpgrades(raw: any, warnings: { string }): Upgrades
	local out = FarmState.emptyUpgrades()
	if raw == nil then
		return out
	end
	if type(raw) ~= "table" then
		table.insert(warnings, "upgrades invalid, reset")
		return out
	end
	-- Never drop this block: the original once rebuilt farms without it and erased upgrades.
	for _, key in FarmState.UpgradeKeys do
		local v = raw[key]
		if v ~= nil then
			if isNum(v) and v >= 0 then
				(out :: any)[key] = math.floor(v)
			else
				table.insert(warnings, "upgrades." .. key .. " invalid, reset to 0")
			end
		end
	end
	return out
end

local function validateFood(raw: any, upgrades: Upgrades, warnings: { string }): Food
	-- The capacity is always re-derived from the upgrade level; food above it is cut.
	local capacity = FarmState.foodCapacity(upgrades)
	if type(raw) ~= "table" then
		table.insert(warnings, "food missing, starting stock applied")
		return { basicFood = math.min(Config.Farm.StartingFood, capacity), capacity = capacity }
	end
	local food = if isNum(raw.basicFood) then math.floor(raw.basicFood) else Config.Farm.StartingFood
	if food < 0 then
		table.insert(warnings, "food below zero, clamped")
		food = 0
	elseif food > capacity then
		table.insert(warnings, "food above capacity, clamped")
		food = capacity
	end
	return { basicFood = food, capacity = capacity }
end

local function validateWorkstations(raw: any, slimeIds: { [string]: boolean }, warnings: { string }): { Workstation }
	local known = {}
	for _, id in Config.Farm.Stations do
		known[id] = true
	end
	local out = {}
	if raw ~= nil and type(raw) ~= "table" then
		table.insert(warnings, "workstations invalid, defaults created")
	end
	if type(raw) == "table" then
		local seen = {}
		for i, w in raw do
			if type(w) == "table" and type(i) == "number" then
				local id = if isText(w.id) then w.id else "station-" .. i
				if not known[w.definitionId] then
					table.insert(warnings, "workstation " .. id .. ": unknown definition, dropped")
				elseif seen[id] then
					table.insert(warnings, "workstation " .. id .. ": duplicate, dropped")
				else
					seen[id] = true
					local workers = stringList(w.assignedSlimeIds, function(s)
						return slimeIds[s] == true
					end)
					while #workers > Config.Farm.StationMaxWorkers do
						table.remove(workers)
					end
					-- Saves written by this port store seconds.
					local progress = if isNum(w.progressSeconds) and w.progressSeconds >= 0
						then w.progressSeconds
						else 0
					table.insert(out, {
						id = id,
						definitionId = w.definitionId,
						assignedSlimeIds = workers,
						progressSeconds = progress,
						pendingOutput = nonNegInt(w.pendingOutput, 0),
					})
				end
			end
		end
	end
	if #out == 0 then
		return FarmState.newWorkstations()
	end
	return out
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

local function validateNest(raw: any, slimeIds: { [string]: boolean }, warnings: { string }): Nest?
	if raw == nil then
		return nil
	end
	if type(raw) ~= "table" or type(raw.nestId) ~= "string" or type(raw.enabled) ~= "boolean" then
		table.insert(warnings, "nest invalid, removed")
		return nil
	end
	if not table.find(FarmState.NestSpecialties, raw.specialty) then
		table.insert(warnings, "nest specialty invalid, removed")
		return nil
	end
	local nest: Nest = {
		nestId = raw.nestId,
		enabled = raw.enabled,
		specialty = raw.specialty,
		memberSlimeIds = stringList(raw.memberSlimeIds, function(s)
			return slimeIds[s] == true
		end),
		currentEggId = if type(raw.currentEggId) == "string" then raw.currentEggId else nil,
		pausedReason = if raw.pausedReason == "PAUSED" then "PAUSED" else nil,
		pendingPair = nil,
	}
	local pp = raw.pendingPair
	if type(pp) == "table" then
		local ids = stringList(pp.ids, function(s)
			return slimeIds[s] == true
		end)
		if #ids == 2 and isNum(pp.pickedAt) then
			nest.pendingPair = { ids = ids, pickedAt = pp.pickedAt }
		else
			table.insert(warnings, "nest.pendingPair invalid, dropped")
		end
	end
	return nest
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

	local upgrades = validateUpgrades(data.upgrades, warnings)
	-- Only absurd arrays are cut: the gameplay caps apply when breeding, never on load.
	local slimeCap = math.max(FarmState.populationLimit(upgrades), Config.Farm.RepairSlimeHardCap)
	local slimes: { Slime } = {}
	local slimeIds: { [string]: boolean } = {}
	for i, raw in data.slimes do
		if type(i) == "number" then
			if #slimes >= slimeCap then
				table.insert(warnings, "slimes beyond " .. slimeCap .. " dropped")
				break
			end
			local slime = validateSlime(raw, i, now, warnings)
			if slime then
				if slimeIds[slime.id] then
					table.insert(warnings, slime.id .. ": duplicate id, dropped")
				else
					slimeIds[slime.id] = true
					table.insert(slimes, slime)
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

	local workstations = validateWorkstations(data.workstations, slimeIds, warnings)
	local knownStations = {}
	for _, id in Config.Farm.Stations do
		knownStations[id] = true
	end
	-- The first station is always unlocked; a legacy save without the list keeps every station
	-- that already has workers, so no crew is evicted.
	local unlocked = table.clone(Config.Farm.StartUnlockedStations)
	local function unlock(id: string)
		if knownStations[id] and not table.find(unlocked, id) then
			table.insert(unlocked, id)
		end
	end
	if type(data.unlockedStations) == "table" then
		for _, id in stringList(data.unlockedStations) do
			unlock(id)
		end
	else
		if data.unlockedStations ~= nil then
			table.insert(warnings, "station unlocks invalid, inferred from crews")
		end
		for _, w in workstations do
			if #w.assignedSlimeIds > 0 then
				unlock(w.definitionId)
			end
		end
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
		}
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
		food = validateFood(data.food, upgrades, warnings),
		workstations = workstations,
		unlockedStations = unlocked,
		lastSimulatedAt = if isNum(data.lastSimulatedAt) and data.lastSimulatedAt > 0
			then data.lastSimulatedAt
			else now,
		coins = coins,
		items = items,
		materials = materials,
		upgrades = upgrades,
		nest = validateNest(data.nest, slimeIds, warnings),
		lifetime = lifetime,
		avatar = validateAvatar(data.avatar, now, warnings),
		tutorialDone = if type(data.tutorialDone) == "boolean" then data.tutorialDone else nil,
		tutorialDoneAt = if isNum(data.tutorialDoneAt) then data.tutorialDoneAt else nil,
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
