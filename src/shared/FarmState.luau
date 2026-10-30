--!strict
-- The schema-five living village: load-safe slimes, area levels, jobs, food and breeding.
-- All clocks are server epoch seconds, and repairs keep valid unrelated progress intact.

local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local Config = if script then require(script.Parent.Config) else require("./Config")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local GardenPlots = if script then require(script.Parent.GardenPlots) else require("./GardenPlots")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local StatsModule = if script then require(script.Parent.Stats) else require("./Stats")

local FarmState = {}

-- Sibling types come through typeof: an exported type cannot be read through the if-require.
-- Modules that need the farm types do the same, e.g. typeof(FarmState.newFarm(0)).
export type Stats = typeof(StatsModule.starter())
export type ColourGenotype = typeof(Genetics.homozygous(""))
export type Appearance = typeof(Mutations.none())

export type Needs = { fullness: number, energy: number, fun: number }
export type Buff = { stat: string, percent: number, untilTime: number }

-- Gear is kept for the future fight phase; the fallen state is replaced by a timed ghost.
export type Loadout = { head: string?, hand: string?, tail: string? }
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
	ghostUntil: number?,
	-- A resting slime stays asleep until rested; its state survives offline steps.
	sleeping: boolean?,
	createdAt: number,
	breedReadyAt: number,
	loadout: Loadout,
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
	cookedAllowed: { string },
	breeding: Pairing,
	lastSimulatedAt: number,
	coins: number,
	items: { Item },
	materials: { [string]: number },

	lifetime: Lifetime,
	avatar: Avatar,
	-- nil on legacy saves means the tour is done.
	tutorialDone: boolean?,
	tutorialDoneAt: number?,
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

function FarmState.villageLevel(areas: Areas): number
	local total = 0
	for _, id in Config.Village.Areas do
		total += (areas :: any)[id].level
	end
	return math.floor(total / #Config.Village.Areas)
end

function FarmState.populationLimit(areas: Areas): number
	local villageLevel = FarmState.villageLevel(areas)
	local limit = Config.Village.PopulationCaps[1]
	for index, threshold in Config.Village.PopulationMilestones do
		if villageLevel >= threshold then
			limit = Config.Village.PopulationCaps[index]
		end
	end
	return limit
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
			ghostUntil = nil,
			createdAt = createdAt,
			breedReadyAt = 0,
			loadout = FarmState.emptyLoadout(),
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
		cookedAllowed = {},
		breeding = FarmState.newPairing(areas.breeding.level),
		lastSimulatedAt = now,
		coins = f.StartingCoins,
		items = items,
		materials = {},
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
		return { stat = raw.stat, percent = math.clamp(raw.percent, 0, Config.Needs.Max), untilTime = raw.untilTime }
	end
	return nil
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
		ghostUntil = if isNum(raw.ghostUntil) and raw.ghostUntil > 0 then raw.ghostUntil else nil,
		createdAt = createdAt,
		breedReadyAt = breedReadyAt,
		loadout = validateLoadout(raw.loadout, FarmState.SlimeSlots, warnings, id) :: Loadout,
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

local function storeCapacity(level: number): number
	return Config.Food.StorehouseBase + Config.Food.StorehousePerLevel * (level - Config.Village.StartLevel)
end

local function fridgeCapacity(level: number): number
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
						egg.hatchAt = now + math.max(0, egg.hatchAt - now) * Config.Breeding.NestSlowFactor
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
		areas = areas,
		work = work,
		storehouse = validateStock(data.storehouse, Config.Food.RawOrder, storeCapacity(areas.pantry.level)),
		counter = validateStock(data.counter, Config.Food.RawOrder, Config.Food.CounterCapacity),
		fridge = validateStock(data.fridge, Config.Food.DishOrder, fridgeCapacity(areas.kitchen.level)),
		cookedAllowed = stringList(data.cookedAllowed, function(id)
			return slimeIds[id] == true
		end),
		breeding = breeding,
		lastSimulatedAt = if isNum(data.lastSimulatedAt) and data.lastSimulatedAt > 0
			then data.lastSimulatedAt
			else now,
		coins = coins,
		items = items,
		materials = materials,
		lifetime = lifetime,
		avatar = validateAvatar(data.avatar, now, warnings),
		tutorialDone = if type(data.tutorialDone) == "boolean" then data.tutorialDone else nil,
		tutorialDoneAt = if isNum(data.tutorialDoneAt) then data.tutorialDoneAt else nil,
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
