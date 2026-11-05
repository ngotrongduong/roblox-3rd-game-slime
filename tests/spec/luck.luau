local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Luck = require("../../src/shared/Luck")

return function(T)
	T.test(
		"server bonus and potion multiply into a label; the chances get the curve of it, outside the tutorial windows too",
		function()
			local farm = { tutorialDone = true, tutorialDoneAt = 10000, luckPotionUntil = 20000 }
			T.eq(Config.Luck.ServerBonus, 1)
			T.eq(Config.Luck.Vip, 1.5)
			T.eq(Config.Luck.Potion, 2)
			-- (the new-player x5 is a real factor outside the curve; the label here is server 2 x potion 2 = 4)
			T.near(Luck.multiplier(farm, 10000, 2), 5 * Luck.real(2 * Config.Luck.Potion), 1e-9)
			T.near(Luck.multiplier(farm, 15000), Luck.real(Config.Luck.Potion), 1e-9)
			T.eq(Luck.multiplier(farm, 20000), 1, "the potion ran out")
			T.near(Luck.multiplier({ luckPotionUntil = 20000 }, 10000, 3), Luck.real(3 * Config.Luck.Potion), 1e-9)
		end
	)

	T.test("the luck curve: real = 1 + 0.4 * log2(label), a label of 1 is 1", function()
		T.eq(Config.Luck.PerDoubling, 0.4)
		T.eq(Luck.real(1), 1)
		T.eq(Luck.real(0.5), 1, "never below 1")
		T.near(Luck.real(2), 1.4, 1e-9)
		T.near(Luck.real(4), 1.8, 1e-9)
		T.near(Luck.real(8), 2.2, 1e-9)
		T.near(Luck.real(12), 2.434, 0.001)
		T.near(Luck.real(24), 2.834, 0.001)
	end)

	T.test("labels multiply: Perm Luck (highest tier only), VIP x1.5, Luck Potion x2, the server bonus", function()
		local function farmWith(passes: { string }, potion: number?): any
			local owned = {}
			for _, key in passes do
				owned[key] = true
			end
			return { robux = { passes = owned }, luckPotionUntil = potion }
		end
		T.eq(Luck.label({}, 100), 1)
		T.eq(Luck.label(farmWith({ "luck2" }), 100), 2)
		T.eq(Luck.label(farmWith({ "luck2", "luck4" }), 100), 4, "the highest tier, never stacked")
		T.eq(Luck.label(farmWith({ "luck2", "luck4", "luck8" }), 100), 8, "x2 x4 x8 is x8, not x64")
		T.eq(Luck.label(farmWith({ "vip" }), 100), 1.5)
		T.eq(Luck.label(farmWith({}, 200), 100), 2, "a Luck Potion running")
		T.eq(Luck.label(farmWith({}, 100), 100), 1, "one that has just run out")
		T.eq(Luck.label(farmWith({ "luck4" }), 100, 3), 12, "x4 with a server bonus of x3")
		T.eq(Luck.label(farmWith({ "luck8", "vip" }), 100), 12, "Luck x8 and VIP")
		T.eq(Luck.label(farmWith({ "luck8", "vip" }, 200), 100), 24, "and a potion on top")
		local label, real = Luck.view(farmWith({ "luck8", "vip" }, 200), 100)
		T.eq(label, 24)
		T.near(real, 2.834, 0.001)
		T.near(Luck.multiplier(farmWith({ "luck2" }), 100), 1.4, 1e-9, "no new-player boost, only the curve")
		T.eq(Luck.chance(0.9, Luck.multiplier(farmWith({ "luck8", "vip" }, 200), 100)), 0.95, "the cap stays")
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
