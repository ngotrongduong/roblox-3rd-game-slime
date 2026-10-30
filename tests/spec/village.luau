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
	T.test("population rises in single or double increments, never jumping 15 at a milestone", function()
		local farm = FarmKit.farm(1000)
		local previous = 12
		local gainedOne = false
		local gainedTwo = false
		for level = 1, 50 do
			for _, area in farm.areas do
				area.level = level
			end
			local capacity = Village.populationLimit(farm)
			local added = capacity - previous
			T.ok(added >= 0 and added <= 2, "village level " .. level .. " must unlock at most two slimes")
			if added == 1 then
				gainedOne = true
			elseif added == 2 then
				gainedTwo = true
			end
			previous = capacity
		end
		T.eq(previous, 72)
		T.ok(gainedOne and gainedTwo, "most upgrades add one slime, some add two")
	end)
	T.test("population progression respects food production tier boundaries", function()
		local farm = FarmKit.farm(1000)
		for _, milestone in {
			{ 1, 12 }, { 6, 12 }, { 7, 13 }, { 10, 13 },
			{ 11, 14 }, { 12, 15 }, { 15, 20 }, { 20, 27 },
			{ 21, 28 }, { 25, 34 }, { 30, 42 }, { 31, 43 },
			{ 35, 49 }, { 40, 57 }, { 41, 58 }, { 45, 64 }, { 50, 72 },
		} do
			for _, area in farm.areas do
				area.level = milestone[1]
			end
			T.eq(Village.populationLimit(farm), milestone[2], "village level " .. milestone[1])
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
