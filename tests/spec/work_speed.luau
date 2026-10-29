--!strict
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local Rng = require("../../src/shared/Rng")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")

return function(T: any)
	T.test("SPD work time decreases and caps at the original 3x bonus", function()
		T.near(Stations.speedTimeFactor(1), 1, 0.000001)
		T.near(Stations.speedTimeFactor(2), 1 / (1 + Config.Work.SpeedBonusPerSpd), 0.000001)
		T.near(Stations.speedTimeFactor(11), 1 / (1 + 10 * Config.Work.SpeedBonusPerSpd), 0.000001)
		T.near(Stations.speedTimeFactor(99), 1 / (1 + Config.Work.SpeedBonusMax), 0.000001)
	end)

	T.test("faster fisher completes a real cycle sooner", function()
		local now = 1000000
		local slow = FarmKit.farm(now)
		local fast = FarmKit.farm(now)
		T.ok(Stations.assign(slow, "slime-1", "fishing", 1, false, now))
		T.ok(Stations.assign(fast, "slime-1", "fishing", 1, false, now))
		fast.slimes[1].stats.speed = 4
		local seconds = 55
		local ready = { ["slime-1"] = "work:fishing:1" }
		local a = VillageSim.step(slow, now + seconds, seconds, Rng.new(10), { errands = false, workReady = ready })
		local b = VillageSim.step(fast, now + seconds, seconds, Rng.new(10), { errands = false, workReady = ready })
		T.eq(a.work.fishing.box.fish, nil)
		T.eq(b.work.fishing.box.fish, Config.Work.FishingYield)
	end)

	T.test("faster kitchen and training accumulate more progress", function()
		local now = 1000000
		local slow = FarmKit.farm(now)
		local fast = FarmKit.farm(now)
		T.ok(Stations.assign(slow, "slime-1", "kitchen", 1, false, now))
		T.ok(Stations.assign(fast, "slime-1", "kitchen", 1, false, now))
		fast.slimes[1].stats.speed = 10
		local a = VillageSim.step(slow, now + 40, 40, Rng.new(1), { errands = false })
		local b = VillageSim.step(fast, now + 40, 40, Rng.new(1), { errands = false })
		T.ok(b.work.kitchen.slots[1].progress > a.work.kitchen.slots[1].progress)
	end)
end
