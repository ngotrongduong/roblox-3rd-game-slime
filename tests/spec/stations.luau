local Stations = require("../../src/shared/Stations")
local FarmKit = require("../lib/FarmKit")
return function(T)
	T.test("work slots grow only at the three milestones", function()
		for _, row in { {1,1},{10,1},{11,2},{21,3},{31,4},{50,4} } do
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
end
