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
	PARENT_FALLEN = "A parent has fallen in battle.",
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

-- 60 s; 5 s less per Faster Incubation level up to level 5 (35 s); never under 5 s.
function Breeding.incubationSeconds(incubationLevel: number?): number
	local b = Config.Breeding
	local level = math.min(b.IncubationMaxLevel, incubationLevel or 0)
	return math.max(b.IncubationMinSeconds, b.IncubationSeconds - level * b.IncubationStepSeconds)
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
	return Stats.isUsable(s.stats)
		and Genetics.isUsableColour(s.colourGenotype)
		and Genetics.isUsablePattern(s.patternGenotype)
end

function Breeding.isBaby(farm: Farm, slime: Slime, now: number): boolean
	return Growth.isBaby(slime.createdAt, now, Stats.level(slime.stats), farm.upgrades.growthSpeed)
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
	if a.fallen or b.fallen then
		return fail("PARENT_FALLEN")
	end
	if Breeding.isBaby(farm, a, now) or Breeding.isBaby(farm, b, now) then
		return fail("PARENT_TOO_YOUNG")
	end
	if now < a.breedReadyAt or now < b.breedReadyAt then
		return fail("PARENT_ON_COOLDOWN")
	end
	-- Each egg holds a slot for its baby.
	if #farm.slimes + #farm.eggs + 1 > FarmState.populationLimit(farm.upgrades) then
		return fail("SLIME_CAP_REACHED")
	end
	if #farm.eggs >= Config.Breeding.MaxActiveEggs then
		return fail("EGG_CAP_REACHED")
	end
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
-- different stats beat the stronger parent; a short hatch. The pattern genes are kept.
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
	egg.hatchAt = egg.createdAt + Config.Breeding.TutorialHatchSeconds
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
	-- Parents breed with their base (visible) colour: appearances are never inherited.
	local outcome = Mutations.resolveOffspring({
		colourA = a.visibleColour,
		colourB = b.visibleColour,
		genotypeA = a.colourGenotype,
		genotypeB = b.colourGenotype,
		patternA = a.patternGenotype,
		patternB = b.patternGenotype,
	}, rng, luck)
	if outcome.appearance.type == "none" and farm.breedsSinceMutation + 1 >= Config.Mutation.PityThreshold then
		outcome = Mutations.applyPity(outcome, a.visibleColour, b.visibleColour, rng)
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
		hatchAt = now + Breeding.incubationSeconds(farm.upgrades.incubationSpeed),
		offspringId = offspringId,
		embryo = {
			stats = Breeding.inheritStats(a.stats, b.stats, rng, luck),
			colourGenotype = outcome.colourGenotype,
			patternGenotype = outcome.patternGenotype,
			appearanceMutation = outcome.appearance,
		},
		status = "incubating",
	}
	local boosted = Breeding.isTutorialFirstEgg(farm)
	if boosted then
		boostFirstEgg(egg, a, b, rng)
	end
	egg.status = FarmState.eggStatus(egg, now)

	local bestLevel = math.max(Stats.level(a.stats), Stats.level(b.stats))
	local readyAt = now + Breeding.cooldownSeconds(bestLevel, farm.upgrades.breedCooldown)

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
	local c = Mutations.chances(a.visibleColour, b.visibleColour, 1)
	if #c.secrets > 0 or #c.duals > 0 then
		table.insert(lines, "A rare discovery may be possible.")
	end
	if breedsSinceMutation ~= nil then
		local threshold = Config.Mutation.PityThreshold
		local n = math.min(breedsSinceMutation, threshold - 1)
		if n >= threshold - 1 then
			table.insert(lines, "✨ Lucky charm FULL — the next egg is guaranteed a rare mutation!")
		else
			table.insert(
				lines,
				"✨ Lucky charm: " .. n .. "/" .. threshold .. " — fills with every egg, guarantees a rare baby."
			)
		end
	end
	return table.concat(lines, "\n")
end

return Breeding
