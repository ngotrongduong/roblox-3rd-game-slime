local Village = require("../../src/shared/Village")
local FarmKit = require("../lib/FarmKit")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
return function(T)
	T.test("village level is the floored six-area average, eggs consume space", function()
		local farm = FarmKit.farm(1000)
		T.eq(Village.level(farm), 1)
		T.eq(Village.populationLimit(farm), 12)
		farm.areas.fishing.level = 7
		T.eq(Village.level(farm), 2)
		T.eq(Village.populationLimit(farm), 13)
	end)
	T.test("maximum village holds 70 slimes with whole slots and milestone headroom", function()
		local farm = FarmKit.farm(1000)
		for _, row in { { 1, 12 }, { 10, 22 }, { 11, 24 }, { 20, 34 }, { 21, 36 }, { 31, 48 }, { 41, 60 }, { 50, 70 } } do
			for _, id in Config.Village.Areas do
				farm.areas[id].level = row[1]
			end
			T.eq(Village.populationLimit(farm), row[2])
			T.eq(Village.populationLimit(farm) % 1, 0)
		end
	end)
	T.test("lower population limit never erases slimes from existing saves", function()
		local original = FarmKit.farm(1000, FarmKit.many(90))
		local repaired = FarmState.repair(original, 1000)
		T.eq(#repaired.slimes, 90)
		T.eq(Village.populationLimit(repaired), 12)
	end)
	T.test("upgrade table endpoints and spending rules", function()
		T.eq(Village.upgradeCost(1), 100)
		T.eq(Village.upgradeCost(49), 20000)
		T.eq(Village.upgradeCost(2), 110)
		T.eq(Village.upgradeCost(25), 1410)
		local farm = FarmKit.farm(1000)
		T.eq(select(2, Village.upgrade(farm, "wrong")), "NO_AREA")
		T.eq(select(2, Village.upgrade(farm, "fishing")), "NO_COINS")
		farm.coins = 99999999
		for _ = 1, 10 do
			T.ok(Village.upgrade(farm, "fishing"))
		end
		T.eq(farm.areas.fishing.level, 11)
		T.eq(#farm.work.fishing.slots, 2)
		farm.areas.garden.level = 50
		T.eq(select(2, Village.upgrade(farm, "garden")), "MAX_LEVEL")
	end)
end
