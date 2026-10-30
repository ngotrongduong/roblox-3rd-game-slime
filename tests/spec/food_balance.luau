--!strict
-- Food balance is checked without SPD bonuses, cooked dishes, or free food grants.
-- The paper budget cannot represent travel/hauling; the offline simulation is a second gate.
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")

local NOW = 1000000

local function expectedFullness(group: string): number
	local order = if group == "fish" then Config.Food.FishOrder else Config.Food.VegOrder
	local total = 0
	for _, id in order do
		local kind = (Config.Food.Kinds :: any)[id]
		total += kind.weight * kind.fullness
	end
	return total / 100
end

local function fullFarm(level: number): any
	local farm = FarmKit.farm(NOW)
	for _, id in Config.Village.Areas do
		(farm.areas :: any)[id].level = level
	end
	local population = FarmState.populationLimit(farm.areas)
	farm.slimes = FarmKit.many(population)
	-- These are adults; starting with a baby would understate food consumption.
	for _, slime in farm.slimes do
		slime.createdAt = NOW - 10000
	end
	farm.work = FarmState.newWork(farm.areas)
	local nextWorker = 1
	for _, areaId in Config.Work.Areas do
		for i = 1, #((farm.work :: any)[areaId].slots) do
			local slime = farm.slimes[nextWorker]
			assert(Stations.assign(farm, slime.id, areaId, i, false, NOW))
			nextWorker += 1
		end
	end
	return farm
end

return function(T: any)
	T.test("SPD-one raw output covers a full village before each new worker unlock", function()
		local fish = expectedFullness("fish")
		local veg = expectedFullness("veg")
		for _, level in { 1, 10, 11, 20, 21, 30, 31, 40, 41, 50 } do
			local farm = fullFarm(level)
			local slots = FarmState.slotCount(level)
			local fishPerMinute = slots * fish * Config.Village.StepSeconds / Stations.cycleSeconds("fishing", level)
			-- One harvest requires hoe, plant, three water actions and a final harvest.
			local gardenPerMinute = slots * veg * Config.Village.StepSeconds
				/ (Config.Work.GardenActionSeconds * 6 * Config.Work.CycleLevelFactor ^ (level - 1))
			local active = slots * #Config.Work.Areas
			local demand = #farm.slimes * Config.Needs.IdleFullnessPerMinute
				+ active * (Config.Needs.WorkFullnessPerMinute - Config.Needs.IdleFullnessPerMinute)
			T.ok(
				fishPerMinute + gardenPerMinute >= demand * 1.4,
				"the pre-unlock level must leave headroom for walking and rest: level " .. level
			)
			T.eq(#farm.slimes, FarmState.populationLimit(farm.areas))
		end
	end)

	T.test("full low-SPD villages keep eating during two hours of offline production", function()
		for _, level in { 10, 30, 50 } do
			local farm = fullFarm(level)
			local after = VillageSim.catchUp(farm, NOW, NOW + 120 * Config.Village.StepSeconds, Rng.new(41))
			local hungry = 0
			for _, slime in after.slimes do
				if slime.needs.fullness <= 0 then
					hungry += 1
				end
			end
			T.eq(hungry, 0, "no resident should run out of food at level " .. level)
			T.eq(farm.slimes[1].needs.fullness, Config.Needs.Start, "offline simulation keeps its input immutable")
		end
	end)
end
