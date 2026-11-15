local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Village = require("../../src/shared/Village")
local WorldPacks = require("../../src/shared/WorldPacks")
local FarmKit = require("../lib/FarmKit")
return function(T)
	T.test("village level is the floored six-area average, eggs consume space", function()
		local farm = FarmKit.farm(1000)
		T.eq(Village.level(farm), 1)
		T.eq(Village.populationLimit(farm), 12)
		farm.areas.fishing.level = 7
		T.eq(Village.level(farm), 2)
		T.eq(Village.populationLimit(farm), 13)
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
		for _, milestone in
			{
				{ 1, 12 },
				{ 6, 17 },
				{ 7, 18 },
				{ 10, 21 },
				{ 11, 22 },
				{ 12, 23 },
				{ 15, 26 },
				{ 20, 31 },
				{ 21, 32 },
				{ 25, 37 },
				{ 30, 43 },
				{ 31, 44 },
				{ 35, 50 },
				{ 40, 57 },
				{ 41, 58 },
				{ 45, 64 },
				{ 50, 72 },
			}
		do
			for _, area in farm.areas do
				area.level = milestone[1]
			end
			T.eq(Village.populationLimit(farm), milestone[2], "village level " .. milestone[1])
		end
	end)
	T.test("village progress counts the upgrades towards the next level", function()
		local farm = FarmKit.farm(1000)
		T.same({ FarmState.villageProgress(farm.areas) }, { 0, 6 })
		farm.areas.fishing.level = 3
		T.same({ FarmState.villageProgress(farm.areas) }, { 2, 6 })
		-- the sixth upgrade tips the average over: the village levels up and the bar starts again
		farm.areas.fishing.level = 7
		T.eq(Village.level(farm), 2)
		T.same({ FarmState.villageProgress(farm.areas) }, { 0, 6 })
		for _, area in farm.areas do
			area.level = 50
		end
		T.same({ FarmState.villageProgress(farm.areas) }, { 6, 6 })
	end)
	T.test("upgrade table endpoints and spending rules", function()
		T.eq(Village.upgradeCost(1), 70)
		T.eq(Village.upgradeCost(49), 700000)
		T.ok(Village.upgradeCost(2) >= 70)
		T.eq(Village.upgradeCost(25), 9500)
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
	-- The owner's road (2026-11-15): village levels 1-20 within about an hour, 21-30 in 2-4 hours more, every level after
	-- that slower than the one before. tools/balance/road_sim.luau walks it in minutes; this guards the coins behind them.
	T.test("the owner's road: 20 levels cost an hour of the first packs, every later stretch far more", function()
		local function stretch(from: number, to: number): number
			local sum = 0
			for level = from, to do
				sum += Village.upgradeCost(level) * #Config.Village.Areas
			end
			return sum
		end
		-- a won fight with the weakest pack, the average of the Sunny Meadow's roster
		local P = Config.World.Packs
		local roster = WorldPacks.roster("meadow")
		local fight = 0
		for _, def in roster do
			fight += WorldPacks.killReward(def.role, P.LevelMin) / #roster * (P.SizeMin + P.SizeMax) / 2
		end
		local first, second, third, last = stretch(1, 19), stretch(20, 29), stretch(30, 39), stretch(40, 49)
		-- a team wins about 40 such fights an hour and the second team opens at level 10
		T.ok(first <= 80 * fight, `levels 1-20 cost {first / fight} first-pack fights`)
		-- income grows three to four times over each of the next two stretches (more teams, stronger packs) and no more
		-- after level 38, so these keep every stretch slower than the one before
		T.ok(second >= 6 * first and second <= 14 * first, `levels 20-30 cost {second / first} times levels 1-20`)
		T.ok(third >= 6 * second, `levels 30-40 cost {third / second} times levels 20-30`)
		T.ok(last >= 3 * third, `levels 40-50 cost {last / third} times levels 30-40`)
		for level = 2, Config.Village.MaxLevel - 1 do
			T.ok(
				Village.upgradeCost(level) > Village.upgradeCost(level - 1),
				"level " .. level .. " costs more than level " .. level - 1
			)
		end
	end)
end
