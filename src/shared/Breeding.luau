--!strict
-- Breeding (docs/reference/01-core-farm.md §4): eligibility, timers, stat inheritance and
-- laying an egg whose baby is fully decided at once. Pure: every roll uses the injected Rng,
-- every id comes from the injected id function, and the result carries the new farm (the input
-- farm is never changed). Failures are returned, never thrown.

local Config = if script then require(script.Parent.Config) else require("./Config")
local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Luck = if script then require(script.Parent.Luck) else require("./Luck")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")

-- Sibling types come through typeof: an exported type cannot be read through the if-require.
type Farm = typeof(FarmState.newFarm(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])
type Egg = typeof(FarmState.newFarm(0).eggs[1])
type Rng = typeof(Rng.new(0))
type SlimeStats = typeof(Stats.starter())

local Breeding = {}

-- Makes a new unique id; kind is "egg" or "slime". The server passes a counter or a GUID.
export type IdFn = (kind: string) -> string

export type CheckResult = { ok: boolean, reason: string?, message: string? }

export type BreedResult = {
	ok: boolean,
	reason: string?,
	message: string?,
	-- The farm after breeding (the unchanged input farm on failure).
	farm: Farm,
	egg: Egg?,
	parentsReadyAt: number?,
	-- True when the tutorial's first-egg boost shaped this egg.
	boosted: boolean?,
}

-- Player texts per reason code (the original breeding panel's words).
Breeding.Messages = {
	SAME_PARENT = "A slime cannot breed with itself.",
	MISSING_PARENT = "Pick two different slimes.",
	INVALID_PARENT_DATA = "A parent has invalid data.",
	-- The original had no text for this one (its picker hid fallen slimes).
	PARENT_FALLEN = "A parent is a ghost.",
	PARENT_TOO_YOUNG = "A parent is still growing up.",
	PARENT_ON_COOLDOWN = "One parent is still resting.",
	SLIME_CAP_REACHED = "The farm is full — no room for a baby.",
	EGG_CAP_REACHED = "The nest is full.",
	ID_UNAVAILABLE = "Something went wrong. Please try again.",
}

local function fail(reason: string): CheckResult
	return { ok = false, reason = reason, message = (Breeding.Messages :: any)[reason] }
end

-- ===== timers (seconds) =====

-- Rounds to whole milliseconds, like the original, so the numbers match it exactly.
local function roundMs(seconds: number): number
	return math.round(seconds * 1000) / 1000
end

-- Incubation begins only after an egg has entered a free incubator.
function Breeding.incubationSeconds(babyLevel: number, breedingLevel: number?): number
	local b = Config.Breeding
	local base = b.IncubationSeconds + math.max(0, babyLevel - b.IncubationLevelBase) * b.IncubationPerBabyLevel
	return math.round(base * b.IncubationAreaFactor ^ ((breedingLevel or Config.Village.StartLevel) - Config.Village.StartLevel))
end

-- Both parents rest this long: 63 s for level-4 starters, less with Quicker Breeding.
function Breeding.cooldownSeconds(bestParentLevel: number, cooldownLevel: number?): number
	local b = Config.Breeding
	local base = b.CooldownSeconds + math.max(0, bestParentLevel - 1) * b.CooldownPerLevelSeconds
	local mult = b.CooldownUpgradeFactor ^ math.min(b.CooldownMaxLevel, cooldownLevel or 0)
	return roundMs(base * mult)
end

-- ===== eligibility =====

local function usableParent(s: Slime): boolean
	return Stats.isUsable(s.stats) and Genetics.isUsableColour(s.colourGenotype)
end

function Breeding.isBaby(farm: Farm, slime: Slime, now: number): boolean
	return Growth.isBaby(slime.createdAt, now, Stats.level(slime.stats), farm.areas.breeding.level - Config.Village.StartLevel)
end

-- Checked in the original's order; the first failure wins.
function Breeding.check(farm: Farm, idA: string, idB: string, now: number): CheckResult
	if idA == idB then
		return fail("SAME_PARENT")
	end
	local a = FarmState.findSlime(farm, idA)
	local b = FarmState.findSlime(farm, idB)
	if a == nil or b == nil then
		return fail("MISSING_PARENT")
	end
	if not usableParent(a) or not usableParent(b) then
		return fail("INVALID_PARENT_DATA")
	end
	if (a.ghostUntil and a.ghostUntil > now) or (b.ghostUntil and b.ghostUntil > now) then
		return fail("PARENT_FALLEN")
	end
	if Breeding.isBaby(farm, a, now) or Breeding.isBaby(farm, b, now) then
		return fail("PARENT_TOO_YOUNG")
	end
	if now < a.breedReadyAt or now < b.breedReadyAt then
		return fail("PARENT_ON_COOLDOWN")
	end
	-- Each egg holds a slot for its baby.
	if #farm.slimes + #farm.eggs + 1 > FarmState.populationLimit(farm.areas) then
		return fail("SLIME_CAP_REACHED")
	end
	local used: { [number]: boolean } = {}
	for _, egg in farm.eggs do
		if egg.place == "nest" then used[egg.slot] = true end
	end
	local free = false
	for slot = 1, FarmState.breedingCount(farm.areas.breeding.level) do
		if not used[slot] then free = true; break end
	end
	if not free then return fail("EGG_CAP_REACHED") end

	return { ok = true }
end

-- ===== stats =====

local function bonusFor(key: string, rng: Rng): number
	local b = Config.Breeding
	if key == "hp" then
		return rng:int(b.HpBonusMin, b.HpBonusMax)
	end
	return rng:int(b.StatBonusMin, b.StatBonusMax)
end

-- Each stat: a whole number between the parents' values (inclusive). Then one roll
-- (ImproveChance × luck, capped) lifts one random stat to the stronger parent + a bonus
-- (+1..3, HP +10..30). Everything clamped to the limits.
function Breeding.inheritStats(a: SlimeStats, b: SlimeStats, rng: Rng, luck: number): SlimeStats
	local out = {}
	for _, key in Stats.Keys do
		local x, y = Stats.get(a, key), Stats.get(b, key)
		out[key] = rng:int(math.min(x, y), math.max(x, y))
	end
	if rng:next() < Luck.chance(Config.Breeding.ImproveChance, luck) then
		local key = Stats.Keys[rng:int(1, #Stats.Keys)]
		out[key] = math.max(Stats.get(a, key), Stats.get(b, key)) + bonusFor(key, rng)
	end
	return Stats.clampAll((out :: any) :: SlimeStats)
end

-- Stats where the baby beats BOTH parents (the reveal's orbit icons).
function Breeding.improvedStats(baby: SlimeStats, a: SlimeStats, b: SlimeStats): { string }
	local out = {}
	for _, key in { "attack", "defence", "hp", "speed" } do
		if Stats.get(baby, key) > math.max(Stats.get(a, key), Stats.get(b, key)) then
			table.insert(out, key)
		end
	end
	return out
end

-- ===== the tutorial's first egg =====

-- The tour's first egg is a sure surprise: applies while the tour runs, with no egg yet and only
-- the starters on the farm.
function Breeding.isTutorialFirstEgg(farm: Farm): boolean
	return farm.tutorialDone == false and #farm.eggs == 0 and #farm.slimes == Config.Farm.StarterCount
end

-- A colour other than the starters', made homozygous; no rare appearance; TutorialBoostedStats
-- different stats beat the stronger parent; a short hatch.
local function boostFirstEgg(egg: Egg, a: Slime, b: Slime, rng: Rng)
	local colours = {}
	for _, id in Colours.Ids do
		if id ~= Config.Farm.StarterColour then
			table.insert(colours, id)
		end
	end
	local colour = rng:pick(colours)
	local keys = table.clone(Stats.Keys)
	local stats = Stats.copy(egg.embryo.stats)
	for _ = 1, math.min(Config.Breeding.TutorialBoostedStats, #keys) do
		local key = table.remove(keys, rng:int(1, #keys)) :: string
		local best = math.max(Stats.get(a.stats, key), Stats.get(b.stats, key))
		Stats.set(stats, key, Stats.clamp(key, best + bonusFor(key, rng)))
	end
	egg.embryo.stats = stats
	egg.embryo.colourGenotype = Genetics.homozygous(colour)
	egg.embryo.appearanceMutation = Mutations.none()
end

-- ===== laying an egg =====

local function freshId(kind: string, newId: IdFn, taken: { [string]: boolean }): string?
	for _ = 1, Config.Breeding.IdAttempts do
		local id = newId(kind)
		if type(id) == "string" and id ~= "" and not taken[id] then
			taken[id] = true
			return id
		end
	end
	return nil
end

-- Breeds two slimes: checks eligibility, decides the whole baby (genes, appearance with luck
-- and pity, stats), applies the tutorial boost, rests both parents, bumps the pity counter and
-- the lifetime breed count. Returns the new farm; the input farm is not changed.
function Breeding.createEgg(farm: Farm, idA: string, idB: string, now: number, rng: Rng, newId: IdFn): BreedResult
	local check = Breeding.check(farm, idA, idB, now)
	if not check.ok then
		return { ok = false, reason = check.reason, message = check.message, farm = farm }
	end
	-- The check above guarantees both parents exist.
	local a = FarmState.findSlime(farm, idA) :: Slime
	local b = FarmState.findSlime(farm, idB) :: Slime

	local luck = Luck.multiplier(farm, now)
	local outcome = Mutations.resolveOffspring(a, b, rng, luck)
	if outcome.appearance.type == "none" and farm.breedsSinceMutation + 1 >= Config.Mutation.PityThreshold then
		outcome = Mutations.applyPity(outcome, a, b, rng)
	end

	local taken: { [string]: boolean } = {}
	for _, s in farm.slimes do
		taken[s.id] = true
	end
	for _, e in farm.eggs do
		taken[e.id] = true
		taken[e.offspringId] = true
	end
	local eggId = freshId("egg", newId, taken)
	local offspringId = freshId("slime", newId, taken)
	if eggId == nil or offspringId == nil then
		local f = fail("ID_UNAVAILABLE")
		return { ok = false, reason = f.reason, message = f.message, farm = farm }
	end

	local egg: Egg = {
		id = eggId,
		parentIds = { idA, idB },
		createdAt = now,
		hatchAt = nil,
		place = "nest",
		slot = 1,
		offspringId = offspringId,
		embryo = {
			stats = Breeding.inheritStats(a.stats, b.stats, rng, luck),
			colourGenotype = outcome.colourGenotype,
			appearanceMutation = outcome.appearance,
		},
		status = "incubating",
	}
	local occupied: { [number]: boolean } = {}
	for _, e in farm.eggs do
		if e.place == "nest" then occupied[e.slot] = true end
	end
	for index = 1, FarmState.breedingCount(farm.areas.breeding.level) do
		if not occupied[index] then egg.slot = index; break end
	end
	local boosted = Breeding.isTutorialFirstEgg(farm)
	if boosted then
		boostFirstEgg(egg, a, b, rng)
	end
	egg.status = FarmState.eggStatus(egg, now)

	local bestLevel = math.max(Stats.level(a.stats), Stats.level(b.stats))
	local readyAt = now + Breeding.cooldownSeconds(bestLevel, farm.areas.breeding.level - Config.Village.StartLevel)

	local after = table.clone(farm)
	after.slimes = table.clone(farm.slimes)
	for i, s in after.slimes do
		if s.id == idA or s.id == idB then
			local rested = table.clone(s)
			rested.breedReadyAt = readyAt
			after.slimes[i] = rested
		end
	end
	after.eggs = table.clone(farm.eggs)
	table.insert(after.eggs, egg)
	-- A rare embryo empties the pity counter; a plain one (the tutorial egg too) fills it.
	after.breedsSinceMutation = if egg.embryo.appearanceMutation.type ~= "none" then 0 else farm.breedsSinceMutation + 1
	after.lifetime = table.clone(farm.lifetime)
	after.lifetime.breeds += 1

	return { ok = true, farm = after, egg = egg, parentsReadyAt = readyAt, boosted = boosted }
end

-- One pair per place; a worker, reserve or already paired slime cannot be committed twice.
function Breeding.setPair(farm: Farm, index: number, idA: string?, idB: string?, now: number?): (boolean, string?)
	local pair = farm.breeding.pairs[index]
	if not pair then return false, "NO_PAIR_PLACE" end
	if idA == nil and idB == nil then
		farm.breeding.pairs[index] = {}
		return true, nil
	end
	if not idA or not idB or idA == idB then return false, "SAME_PARENT" end
	local a = FarmState.findSlime(farm, idA)
	local b = FarmState.findSlime(farm, idB)
	if not a or not b then return false, "MISSING_PARENT" end
	local time = now or 0
	if Breeding.isBaby(farm, a, time) or Breeding.isBaby(farm, b, time) then return false, "PARENT_TOO_YOUNG" end
	if (a.ghostUntil and a.ghostUntil > time) or (b.ghostUntil and b.ghostUntil > time) then return false, "PARENT_FALLEN" end
	if Stations.isBusy(farm, idA) or Stations.isBusy(farm, idB) then return false, "ALREADY_ASSIGNED" end
	for i, other in farm.breeding.pairs do
		if i ~= index and (other.a == idA or other.b == idA or other.a == idB or other.b == idB) then
			return false, "IN_PAIR"
		end
	end
	farm.breeding.pairs[index] = { a = idA, b = idB }
	return true, nil
end

function Breeding.pairReady(farm: Farm, index: number, now: number): CheckResult
	local pair = farm.breeding.pairs[index]
	if not pair or not pair.a or not pair.b then return fail("MISSING_PARENT") end
	local check = Breeding.check(farm, pair.a, pair.b, now)
	if not check.ok then return check end
	local a = FarmState.findSlime(farm, pair.a) :: Slime
	local b = FarmState.findSlime(farm, pair.b) :: Slime
	if Stations.isBusy(farm, pair.a) or Stations.isBusy(farm, pair.b) then return fail("PARENT_ON_COOLDOWN") end
	if not Needs.canPair(a.needs) or not Needs.canPair(b.needs) then return fail("PARENT_ON_COOLDOWN") end
	return { ok = true }
end

function Breeding.startCourtship(farm: Farm, index: number, now: number): CheckResult
	local ready = Breeding.pairReady(farm, index, now)
	if ready.ok then
		farm.breeding.pairs[index].courtingUntil = now + Config.Breeding.CourtshipSeconds
	end
	return ready
end

function Breeding.layEgg(farm: Farm, index: number, now: number, rng: Rng, newId: IdFn): BreedResult
	local pair = farm.breeding.pairs[index]
	if not pair or not pair.a or not pair.b or not pair.courtingUntil or now < pair.courtingUntil then
		return { ok = false, reason = "NOT_COURTED", farm = farm }
	end
	local result = Breeding.createEgg(farm, pair.a, pair.b, now, rng, newId)
	if not result.ok then return result end
	result.farm.breeding = { pairs = table.clone(farm.breeding.pairs) }
	result.farm.breeding.pairs[index] = { a = pair.a, b = pair.b }
	for i, slime in result.farm.slimes do
		if slime.id == pair.a or slime.id == pair.b then
			local parent = table.clone(slime)
			parent.needs = table.clone(slime.needs)
			parent.needs.energy = math.max(0, slime.needs.energy - Config.Breeding.LayEnergy)
			result.farm.slimes[i] = parent
		end
	end
	return result
end

function Breeding.placeInIncubator(farm: Farm, eggId: string, now: number): (boolean, string?)
	local egg = FarmState.findEgg(farm, eggId)
	if not egg then return false, "MISSING_EGG" end
	if egg.place ~= "nest" then return false, "ALREADY_INCUBATING" end
	local occupied: { [number]: boolean } = {}
	for _, other in farm.eggs do
		if other.place == "incubator" then occupied[other.slot] = true end
	end
	for slot = 1, FarmState.breedingCount(farm.areas.breeding.level) do
		if not occupied[slot] then
			egg.place, egg.slot = "incubator", slot
			egg.hatchAt = now + Breeding.incubationSeconds(Stats.level(egg.embryo.stats), farm.areas.breeding.level)
			egg.status = FarmState.eggStatus(egg, now)
			return true, nil
		end
	end
	return false, "NO_INCUBATOR"
end

-- Player-facing preview: stat ranges and hints, never the embryo itself.
function Breeding.previewText(a: Slime, b: Slime, breedsSinceMutation: number?): string
	local function range(key: string): string
		local x, y = Stats.get(a.stats, key), Stats.get(b.stats, key)
		return math.min(x, y) .. "–" .. math.max(x, y)
	end
	local lines = {
		"Baby ranges: ATK "
			.. range("attack")
			.. " · DEF "
			.. range("defence")
			.. " · SPD "
			.. range("speed")
			.. " · HP "
			.. range("hp"),
		math.round(Config.Breeding.ImproveChance * 100) .. "% chance one stat improves beyond the stronger parent.",
	}
	local c = Mutations.chances(a, b, 1)
	if #c.secrets > 0 or #c.duals > 0 then
		table.insert(lines, "A rare discovery may be possible.")
	end
	-- every pair can give a material, so it is its own line rather than the hint above
	if c.material > 0 then
		table.insert(lines, "Material on a plain baby: " .. math.round(c.material * 100) .. "%")
	end
	if breedsSinceMutation ~= nil then
		local threshold = Config.Mutation.PityThreshold
		local n = math.min(breedsSinceMutation, threshold - 1)
		if n >= threshold - 1 then
			table.insert(lines, "✨ Lucky charm FULL — the next egg is guaranteed a rare mutation!")
		else
			table.insert(
				lines,
				"✨ Lucky charm: " .. n .. "/" .. threshold .. " — fills with plain eggs, guarantees a rare baby."
			)
		end
	end
	return table.concat(lines, "\n")
end

return Breeding
