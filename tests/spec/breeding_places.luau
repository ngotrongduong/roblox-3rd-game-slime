--!strict
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")

return function(T: any)
	T.test("breeding starts with four assigned slime places and ends at eight", function()
		for _, row in { { 1, 2 }, { 20, 2 }, { 21, 3 }, { 40, 3 }, { 41, 4 }, { 50, 4 } } do
			T.eq(FarmState.breedingCount(row[1]), row[2])
			T.eq(#FarmState.newPairing(row[1]).pairs, row[2])
		end
		T.eq(#Config.Breeding.SlotLevels, 2)
	end)

	T.test("schema repair preserves four nest pairs at the highest level", function()
		local farm = FarmState.newFarm(1000000)
		farm.areas.breeding.level = 50
		local recovered = FarmState.repair(farm, 1000000)
		T.eq(#recovered.breeding.pairs, 4)
	end)
end
