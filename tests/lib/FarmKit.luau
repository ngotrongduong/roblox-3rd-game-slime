-- Builders for the farm-rules specs: farms, slimes and an id counter.
local FarmState = require("../../src/shared/FarmState")
local Genetics = require("../../src/shared/Genetics")

local FarmKit = {}

-- An id function like the server's counter: "egg-1", "slime-2", ...
function FarmKit.ids(): (string) -> string
	local n = 0
	return function(kind: string): string
		n += 1
		return kind .. "-id" .. n
	end
end

-- An adult, rested slime. colours = { allele1, allele2 }.
function FarmKit.slime(id: string, opts: { [string]: any }?): any
	local o = opts or {}
	local colours = o.colours or { "navy", "navy" }
	local genotype = { alleles = { colours[1], colours[2] } }
	local appearance = o.appearance or { type = "none" }
	return {
		id = id,
		name = o.name or id,
		seed = o.seed or 1,
		assetId = "slime.base." .. Genetics.visibleColour(appearance, genotype),
		stats = o.stats or { attack = 1, defence = 1, speed = 1, hp = 10 },
		colourGenotype = genotype,
		visibleColour = Genetics.visibleColour(appearance, genotype),
		appearanceMutation = appearance,
		isFavourite = false,
		needs = o.needs or FarmState.fullNeeds(),
		trait = FarmState.traitForSeed(o.seed or 1),
		friends = {},
		buff = nil,
		autoDish = nil,
		ghostUntil = o.ghostUntil,
		createdAt = o.createdAt or 0,
		breedReadyAt = o.breedReadyAt or 0,
		loadout = {},
	}
end

-- A fresh farm at `now` with the tutorial already done (no first-egg boost, luck ×1), holding
-- the given slimes (the four starters when none are given).
function FarmKit.farm(now: number, slimes: { any }?): any
	local farm = FarmState.newFarm(now)
	farm.tutorialDone = true
	if slimes then
		farm.slimes = slimes
	end
	return farm
end

-- n plain navy slimes named s1..sn.
function FarmKit.many(n: number): { any }
	local out = {}
	for i = 1, n do
		table.insert(out, FarmKit.slime("s" .. i))
	end
	return out
end

-- A village at its population limit with every area at `level`; every fishing and garden slot has a starter-SPD worker
-- and reserve. Returns the farm and how many slimes it staffed.
function FarmKit.fullVillage(now: number, level: number): (any, number)
	local Stations = require("../../src/shared/Stations")
	local farm = FarmKit.farm(now)
	for _, area in farm.areas do
		area.level = level
	end
	farm.slimes = FarmKit.many(FarmState.populationLimit(farm.areas))
	local staffed = 0
	for _, areaId in { "fishing", "garden" } do
		local work = farm.work[areaId]
		while #work.slots < FarmState.slotCount(level) do
			table.insert(work.slots, { progress = 0 })
		end
		for slot = 1, #work.slots do
			assert(Stations.assign(farm, "s" .. (staffed + 1), areaId, slot, false, now))
			assert(Stations.assign(farm, "s" .. (staffed + 2), areaId, slot, true, now))
			staffed += 2
		end
	end
	return farm, staffed
end

return FarmKit
