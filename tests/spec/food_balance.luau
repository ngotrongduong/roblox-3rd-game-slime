--!strict
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local FoodBalance = require("../../src/shared/FoodBalance")
local FarmKit = require("../lib/FarmKit")
local Breeding = require("../../src/shared/Breeding")

return function(T: any)
	T.test("starter SPD raw supply maintains headroom at every population tier", function()
		for level = 1, Config.Village.MaxLevel do
			local areas = FarmState.newAreas()
			for _, area in areas do
				area.level = level
			end
			local population = FarmState.populationLimit(areas)
			local workers = 4 * FarmState.slotCount(level)
			local supply = FoodBalance.rawSupplyPerMinute(level, level)
			local demand = FoodBalance.demandPerMinute(population, workers)
			T.ok(supply >= demand * 1.15, "starter SPD food margin at level " .. level)
		end
	end)
	T.test("nutrition model counts one vegetable per six tending actions", function()
		T.eq(Config.Work.GardenYield, 1)
		T.eq(Config.Work.GardenActionsPerHarvest, 6)
		T.ok(FoodBalance.weightedFullness("fish") > 20)
		T.ok(FoodBalance.weightedFullness("veg") > 20)
	end)
	T.test("existing saves above the lowered population cap retain all slimes", function()
		local farm = FarmKit.farm(1000000, FarmKit.many(20))
		local restored = FarmState.repair(farm, 1000000)
		T.eq(#restored.slimes, 20)
		T.eq(FarmState.populationLimit(restored.areas), 12)
		T.eq(Breeding.check(restored, "s1", "s2", 1000000).reason, "SLIME_CAP_REACHED")
	end)
end
