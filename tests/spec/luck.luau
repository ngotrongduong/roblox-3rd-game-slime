local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Luck = require("../../src/shared/Luck")

return function(T)
	T.test("server, potion and VIP multiply luck even outside the tutorial windows", function()
		local farm = { tutorialDone = true, tutorialDoneAt = 10000, luckPotionUntil = 20000 }
		T.eq(Config.Luck.ServerBonus, 1)
		T.eq(Config.Luck.Vip, 1)
		T.eq(Luck.multiplier(farm, 10000, 2), 5 * 2 * Config.Luck.Potion * Config.Luck.Vip)
		T.eq(Luck.multiplier(farm, 15000), Config.Luck.ServerBonus * Config.Luck.Potion * Config.Luck.Vip)
		T.eq(Luck.multiplier(farm, 20000), Config.Luck.ServerBonus * Config.Luck.Vip)
		T.eq(Luck.multiplier({ luckPotionUntil = 20000 }, 10000, 3), 3 * Config.Luck.Potion * Config.Luck.Vip)
	end)

	T.test("repair preserves finite nonnegative potion expiry, rejects invalid values", function()
		local farm = FarmState.newFarm(10000)
		T.eq(farm.luckPotionUntil, nil)
		farm.luckPotionUntil = 20000
		T.eq(FarmState.repair(farm, 10000).luckPotionUntil, 20000)
		for _, bad in { -1, math.huge, -math.huge, 0 / 0, "bad", {} } do
			farm.luckPotionUntil = bad
			T.eq(FarmState.repair(farm, 10000).luckPotionUntil, nil)
		end
	end)

	local done = 10000

	T.test("x5 for the first 30 minutes after the tutorial, x3 for the next 30, then x1", function()
		local farm = { tutorialDone = true, tutorialDoneAt = done }
		T.eq(Luck.multiplier(farm, done), 5)
		T.eq(Luck.multiplier(farm, done + 1799), 5)
		T.eq(Luck.multiplier(farm, done + 1800), 3)
		T.eq(Luck.multiplier(farm, done + 3599.5), 3)
		T.eq(Luck.multiplier(farm, done + 3600), 1)
		T.eq(Luck.multiplier(farm, done + 999999), 1)
	end)

	T.test("no boost without a finished tutorial or with a clock before it", function()
		T.eq(Luck.multiplier({ tutorialDone = true }, done), 1)
		T.eq(Luck.multiplier({ tutorialDone = false, tutorialDoneAt = done }, done), 1)
		T.eq(Luck.multiplier({ tutorialDoneAt = done }, done), 1)
		T.eq(Luck.multiplier({ tutorialDone = true, tutorialDoneAt = 0 }, done), 1)
		T.eq(Luck.multiplier({ tutorialDone = true, tutorialDoneAt = done }, done - 5), 1)
	end)

	T.test("seconds left in the boosted window", function()
		local farm = { tutorialDone = true, tutorialDoneAt = done }
		T.eq(Luck.secondsLeft(farm, done + 100), 1700)
		T.eq(Luck.secondsLeft(farm, done + 2000), 1600)
		T.eq(Luck.secondsLeft(farm, done + 4000), 0)
		T.eq(Luck.secondsLeft({ tutorialDone = false }, done), 0)
	end)

	T.test("luck-multiplied chances cap at 0.95", function()
		T.near(Luck.chance(0.05, 5), 0.25, 1e-12)
		T.eq(Luck.chance(0.1, 20), 0.95)
		T.eq(Luck.chance(0.5, 1000), 0.95)
		T.eq(Luck.chance(0.01, 1), 0.01)
	end)
end
