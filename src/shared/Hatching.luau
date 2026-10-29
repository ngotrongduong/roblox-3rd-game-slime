--!strict
-- Hatching (docs/reference/01-core-farm.md §4.5, §5.7, §11.1): a ready egg becomes exactly one
-- slime with the embryo decided at laying time (never rerolled). Idempotent: the egg is the single
-- source of truth, so once it is gone a repeat call returns MISSING_EGG and adds nothing.
-- The server commits at once; the client plays the reveal from the result.

local Breeding = if script then require(script.Parent.Breeding) else require("./Breeding")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

-- Sibling types come through typeof: an exported type cannot be read through the if-require.
type Farm = typeof(FarmState.newFarm(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])
type Egg = typeof(FarmState.newFarm(0).eggs[1])
type Discoveries = typeof(FarmState.emptyDiscoveries())
type DiscoveryBucket = typeof(FarmState.emptyDiscoveries().base)
type Appearance = typeof(Mutations.none())

local Hatching = {}

export type HatchResult = {
	ok: boolean,
	-- "MISSING_EGG" or "NOT_READY" when not ok.
	reason: string?,
	-- The farm after the hatch (the unchanged input farm on failure).
	farm: Farm,
	slime: Slime?,
	-- The dual/secret appearance when this hatch discovered it for the first time.
	firstDiscovery: Appearance?,
	-- True when the base colour was seen for the first time.
	newColour: boolean?,
	-- Stats where the baby beats both parents (empty when a parent is gone).
	improvedStats: { string }?,
	-- The avatar rank went up with this hatch.
	rankUp: boolean?,
}

-- "Slime N" where N is one more than the highest "Slime <n>" on the farm.
function Hatching.nextName(farm: Farm): string
	local best = 0
	for _, s in farm.slimes do
		local n = string.match(s.name, "^Slime (%d+)$")
		if n then
			best = math.max(best, tonumber(n) or 0)
		end
	end
	return "Slime " .. (best + 1)
end

local function copyDiscoveries(d: Discoveries): Discoveries
	return {
		base = table.clone(d.base),
		dual = table.clone(d.dual),
		secret = table.clone(d.secret),
		material = table.clone(d.material),
	}
end

local function bump(bucket: DiscoveryBucket, id: string, now: number): boolean
	local existing = bucket[id]
	if existing then
		bucket[id] = { firstDiscoveredAt = existing.firstDiscoveredAt, hatchCount = existing.hatchCount + 1 }
		return false
	end
	bucket[id] = { firstDiscoveredAt = now, hatchCount = 1 }
	return true
end

-- Registers a dual/secret/material appearance (nothing for "none"). Returns the new discoveries and
-- whether this was the first one of its kind.
function Hatching.registerDiscovery(
	discoveries: Discoveries,
	appearance: Appearance,
	now: number
): (Discoveries, boolean)
	local id = appearance.definitionId
	if appearance.type == "none" or id == nil then
		return discoveries, false
	end
	local out = copyDiscoveries(discoveries)
	local bucket = if appearance.type == "dual"
		then out.dual
		elseif appearance.type == "material" then out.material
		else out.secret
	return out, bump(bucket, id, now)
end

-- Registers a plain baby in the base-colour collection.
function Hatching.registerBase(discoveries: Discoveries, colour: string, now: number): (Discoveries, boolean)
	local out = copyDiscoveries(discoveries)
	return out, bump(out.base, colour, now)
end

-- Every collection entry counts toward avatar rank, including the starters.
function Hatching.totalHatched(discoveries: Discoveries): number
	local n = 0
	for _, bucket in { discoveries.base, discoveries.dual, discoveries.secret, discoveries.material } do
		for _, rec in bucket do
			n += rec.hatchCount
		end
	end
	return n
end

function Hatching.avatarRank(discoveries: Discoveries): number
	return 1 + math.floor(Hatching.totalHatched(discoveries) / Config.Farm.AvatarHatchesPerRank)
end

-- The egg auto-hatch takes next: the oldest ready one (nil when none is ready).
function Hatching.nextReadyEgg(farm: Farm, now: number): Egg?
	local best: Egg? = nil
	for _, egg in farm.eggs do
		if now >= egg.hatchAt and (best == nil or egg.createdAt < best.createdAt) then
			best = egg
		end
	end
	return best
end

-- The baby an egg becomes (does not touch the farm).
function Hatching.babyFromEgg(farm: Farm, egg: Egg, now: number): Slime
	local embryo = egg.embryo
	local colour = Genetics.visibleColour(embryo.appearanceMutation, embryo.colourGenotype)
	return {
		id = egg.offspringId,
		name = Hatching.nextName(farm),
		seed = Rng.hash(egg.offspringId),
		assetId = Mutations.assetId(embryo.appearanceMutation, colour),
		stats = Stats.copy(embryo.stats),
		colourGenotype = Genetics.copy(embryo.colourGenotype),
		-- The design determines which of its base colours is visible.
		visibleColour = colour,
		appearanceMutation = Mutations.copy(embryo.appearanceMutation),
		isFavourite = false,
		needs = FarmState.fullNeeds(),
		createdAt = now,
		-- Rested at once; the baby rule still keeps it from breeding until it grows up.
		breedReadyAt = now,
		loadout = FarmState.emptyLoadout(),
		fallen = false,
		previousLoadout = nil,
	}
end

-- Hatches one egg: removes it, adds the baby, registers discoveries, raises the best level.
function Hatching.hatch(farm: Farm, eggId: string, now: number): HatchResult
	local egg, index = FarmState.findEgg(farm, eggId)
	if egg == nil or index == nil then
		return { ok = false, reason = "MISSING_EGG", farm = farm }
	end
	if now < egg.hatchAt then
		return { ok = false, reason = "NOT_READY", farm = farm }
	end
	local slime = Hatching.babyFromEgg(farm, egg, now)

	local rankBefore = Hatching.avatarRank(farm.discoveries)
	local discoveries, firstRare = Hatching.registerDiscovery(farm.discoveries, slime.appearanceMutation, now)
	local newColour = false
	if slime.appearanceMutation.type == "none" then
		discoveries, newColour = Hatching.registerBase(discoveries, slime.visibleColour, now)
	end

	local improved = {}
	local parentA = FarmState.findSlime(farm, egg.parentIds[1])
	local parentB = FarmState.findSlime(farm, egg.parentIds[2])
	if parentA and parentB then
		improved = Breeding.improvedStats(slime.stats, parentA.stats, parentB.stats)
	end

	local after = table.clone(farm)
	after.eggs = table.clone(farm.eggs)
	table.remove(after.eggs, index)
	after.slimes = table.clone(farm.slimes)
	table.insert(after.slimes, slime)
	after.discoveries = discoveries
	after.lifetime = table.clone(farm.lifetime)
	after.lifetime.bestSlimeLevel = math.max(farm.lifetime.bestSlimeLevel, Stats.level(slime.stats))

	return {
		ok = true,
		farm = after,
		slime = slime,
		firstDiscovery = if firstRare then Mutations.copy(slime.appearanceMutation) else nil,
		newColour = newColour,
		improvedStats = improved,
		rankUp = Hatching.avatarRank(discoveries) > rankBefore,
	}
end

return Hatching
