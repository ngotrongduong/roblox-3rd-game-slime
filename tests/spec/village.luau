local Village = require("../../src/shared/Village")
local FarmKit = require("../lib/FarmKit")
return function(T)
	T.test("village level is the floored six-area average, eggs consume space", function()
		local farm = FarmKit.farm(1000)
		T.eq(Village.level(farm), 1)
		T.eq(Village.populationLimit(farm), 12)
		farm.areas.fishing.level = 7
		T.eq(Village.level(farm), 2)
		T.eq(Village.populationLimit(farm), 12)
	end)
	T.test("population caps follow food worker unlocks", function()
		local farm = FarmKit.farm(1000)
		for _, milestone in { { 1, 12 }, { 10, 12 }, { 11, 27 }, { 20, 27 }, { 21, 42 }, { 30, 42 }, { 31, 57 }, { 40, 57 }, { 41, 72 }, { 50, 72 } } do
			for _, area in farm.areas do
				area.level = milestone[1]
			end
			T.eq(Village.populationLimit(farm), milestone[2])
		end
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
