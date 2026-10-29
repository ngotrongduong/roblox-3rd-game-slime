local Village = require("../../src/shared/Village")
local FarmKit = require("../lib/FarmKit")
return function(T)
	T.test("village level is the floored six-area average, eggs consume space", function()
		local farm = FarmKit.farm(1000)
		T.eq(Village.level(farm), 1)
		T.eq(Village.populationLimit(farm), 20)
		farm.areas.fishing.level = 7
		T.eq(Village.level(farm), 2)
		T.eq(Village.populationLimit(farm), 24)
	end)
	T.test("upgrade table endpoints and spending rules", function()
		T.eq(Village.upgradeCost(1), 100)
		T.eq(Village.upgradeCost(49), 20000)
		T.ok(Village.upgradeCost(2) > 100)
		T.ok(Village.upgradeCost(25) > Village.upgradeCost(2))
		local farm = FarmKit.farm(1000)
		T.eq(select(2, Village.upgrade(farm, "wrong")), "NO_AREA")
		T.eq(select(2, Village.upgrade(farm, "fishing")), "NO_COINS")
		farm.coins = 99999999
		for _ = 1, 10 do T.ok(Village.upgrade(farm, "fishing")) end
		T.eq(farm.areas.fishing.level, 11)
		T.eq(#farm.work.fishing.slots, 2)
		farm.areas.garden.level = 50
		T.eq(select(2, Village.upgrade(farm, "garden")), "MAX_LEVEL")
	end)
end
