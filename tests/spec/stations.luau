local Stations = require("../../src/shared/Stations")
local FarmKit = require("../lib/FarmKit")
local Rng = require("../../src/shared/Rng")
local VillageSim = require("../../src/shared/VillageSim")
return function(T)
	T.test("a trainee with no stat chosen trains its weakest stat", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		farm.slimes[1].stats = { attack = 5, defence = 2, speed = 4, hp = 60 }
		farm.slimes[1].createdAt = now - 10000 -- grown up at its higher level
		T.ok(Stations.assign(farm, "slime-1", "training", 1, false, now))
		T.eq(farm.work.training.slots[1].stat, "defence")
		-- an old save with a trainee and no stat gets one on the next step
		farm.work.training.slots[1].stat = nil
		farm = VillageSim.step(farm, now + 60, 60, Rng.new(1), { errands = true })
		T.eq(farm.work.training.slots[1].stat, "defence")
		T.ok(farm.work.training.slots[1].progress > 0, "it trains")
	end)
	T.test("work slots grow only at the three milestones", function()
		for _, row in { { 1, 1 }, { 10, 1 }, { 11, 2 }, { 21, 3 }, { 31, 4 }, { 50, 4 } } do
			T.eq(Stations.slotCount(row[1]), row[2])
		end
	end)
	T.test("reasons, exclusive assignments and reserve handoff", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.eq(select(2, Stations.canAssign(farm, "bad", "fishing", 1, false, now)), "MISSING_SLIME")
		T.eq(select(2, Stations.canAssign(farm, "slime-1", "fishing", 5, false, now)), "NO_SLOT")
		local ok = Stations.assign(farm, "slime-1", "fishing", 1, false, now)
		T.ok(ok)
		T.eq(select(2, Stations.canAssign(farm, "slime-1", "garden", 1, false, now)), "ALREADY_ASSIGNED")
		T.ok(Stations.assign(farm, "slime-2", "fishing", 1, true, now))
		T.eq(Stations.activeWorker(farm, farm.work.fishing.slots[1], now).id, "slime-1")
		farm.slimes[1].needs.energy = 20
		T.eq(Stations.activeWorker(farm, farm.work.fishing.slots[1], now).id, "slime-2")
		farm.slimes[1].needs.energy = 100
		farm.slimes[1].needs.fullness = 25
		T.eq(Stations.activeWorker(farm, farm.work.fishing.slots[1], now).id, "slime-2")
		farm.slimes[2].needs.fullness = 25
		T.eq(Stations.activeWorker(farm, farm.work.fishing.slots[1], now).id, "slime-1")
		T.ok(Stations.unassign(farm, "fishing", 1, false))
		T.ok(Stations.setTrainingStat(farm, 1, "hp"))
		T.eq(farm.work.training.slots[1].stat, "hp")
		local baby = FarmKit.slime("baby", { createdAt = now })
		table.insert(farm.slimes, baby)
		T.eq(select(2, Stations.canAssign(farm, "baby", "garden", 1, false, now)), "BABY")
		farm.slimes[3].ghostUntil = now + 100
		T.eq(select(2, Stations.canAssign(farm, "slime-3", "garden", 1, false, now)), "GHOST")
	end)
	T.test("a full box pauses the producer and a kitchen without ingredients waits", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.ok(Stations.assign(farm, "slime-1", "fishing", 1, false, now))
		T.ok(Stations.assign(farm, "slime-2", "kitchen", 1, false, now))
		farm.work.fishing.box = { fish = 10 }
		local after = VillageSim.step(farm, now + 240, 240, Rng.new(5), { errands = false })
		T.eq(after.work.fishing.box.fish, 10)
		T.eq(after.work.fishing.slots[1].progress, 0)
		T.same(after.work.kitchen.box, {})
		T.eq(after.work.kitchen.slots[1].progress, 0)
		after.counter = { fish = 2 }
		local cooked = VillageSim.step(after, now + 360, 120, Rng.new(5), { errands = false })
		T.eq(cooked.work.kitchen.box.grilledFish, 1)
		T.eq(cooked.counter.fish, nil)
	end)
end
