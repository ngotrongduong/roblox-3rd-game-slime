local Config = require("../../src/shared/Config")
local Breeding = require("../../src/shared/Breeding")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rng = require("../../src/shared/Rng")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")

local NOW = 1000000
return function(T)
	T.test("8h offline with one fisher feeds four starters", function()
		local farm = FarmKit.farm(NOW)
		T.ok(Stations.assign(farm, "slime-1", "fishing", 1, false, NOW))
		local after, events = VillageSim.catchUp(farm, NOW, NOW + Config.Village.OfflineCapSeconds, Rng.new(19))
		T.eq(after.lastSimulatedAt, NOW + Config.Village.OfflineCapSeconds)
		T.ok(#events > 0)
		T.ok(after.slimes[1].needs.fullness > 0)
		T.eq(farm.slimes[1].needs.fullness, 100, "offline simulation is pure")
	end)
	T.test("full pantry does not lose box inventory", function()
		local farm = FarmKit.farm(NOW)
		farm.storehouse = { fish = 100 }
		farm.work.fishing.box = { fish = 10 }
		local after = VillageSim.step(farm, NOW + 60, 60, Rng.new(3), { errands = true })
		-- The cook may pull fish to the counter, which frees room for some of the box; no fish is ever lost.
		T.eq(after.storehouse.fish, 100)
		local total = after.storehouse.fish + (after.work.fishing.box.fish or 0) + (after.counter.fish or 0)
		T.eq(total, 110)
		T.ok((after.work.fishing.box.fish or 0) > 0, "the box keeps what does not fit")
		T.eq(farm.work.fishing.box.fish, 10)
	end)
	T.test("pair to egg to incubator to hatch to adult", function()
		local farm = FarmKit.farm(NOW)
		T.ok(Breeding.setPair(farm, 1, "slime-1", "slime-2", NOW))
		farm = VillageSim.step(farm, NOW, 0, Rng.new(1), { errands = true })
		T.eq(farm.breeding.pairs[1].courtingUntil, NOW + 60)
		farm = VillageSim.step(farm, NOW + 60, 60, Rng.new(1), { errands = true })
		T.eq(#farm.eggs, 1)
		T.eq(farm.eggs[1].place, "incubator")
		farm = VillageSim.step(farm, NOW + 180, 60, Rng.new(1), { errands = true })
		T.eq(#farm.eggs, 0)
		T.eq(#farm.slimes, 5)
		T.ok(farm.slimes[5].createdAt > NOW)
		farm = VillageSim.step(farm, NOW + 500, 60, Rng.new(1), { errands = true })
		T.ok(not Breeding.isBaby(farm, farm.slimes[5], NOW + 500))
	end)
	T.test("online no-errands waits for brain arrivals to eat or sleep", function()
		local farm = FarmKit.farm(NOW)
		farm.slimes[1].needs.fullness = Config.Needs.WantsFood
		farm.slimes[1].needs.energy = Config.Needs.Tired
		local after = VillageSim.step(farm, NOW + 60, 60, Rng.new(2), { errands = false })
		T.eq(after.slimes[1].sleeping, nil)
		T.ok(after.slimes[1].needs.fullness < farm.slimes[1].needs.fullness)
		T.eq(after.storehouse.fish, farm.storehouse.fish)
		T.ok(after.slimes[1].needs.energy < farm.slimes[1].needs.energy)
		local offline = VillageSim.step(farm, NOW + 60, 60, Rng.new(2), { errands = true })
		T.eq(offline.slimes[1].sleeping, true)
		T.ok(offline.slimes[1].needs.fullness > farm.slimes[1].needs.fullness)
	end)
	T.test("online work waits for an actor at its station", function()
		local farm = FarmKit.farm(NOW)
		T.ok(Stations.assign(farm, "slime-1", "fishing", 1, false, NOW))
		local waiting = VillageSim.step(farm, NOW + 60, 60, Rng.new(2), {
			errands = false,
			workReady = {},
		})
		T.eq(waiting.work.fishing.box.fish, nil)
		local arrived = VillageSim.step(farm, NOW + 60, 60, Rng.new(2), {
			errands = false,
			workReady = { ["slime-1"] = "work:fishing:1" },
		})
		T.eq(arrived.work.fishing.box.fish, nil, "online fish cannot enter the bin before the carrier arrives")
		T.eq(arrived.work.fishing.slots[1].pending, "fish", "arriving worker has caught a fish to carry")
	end)
	T.test("online pairs wait for both parents at the breeding house", function()
		local farm = FarmKit.farm(NOW)
		T.ok(Breeding.setPair(farm, 1, "slime-1", "slime-2", NOW))
		local waiting = VillageSim.step(farm, NOW, 0, Rng.new(2), { errands = false })
		T.eq(waiting.breeding.pairs[1].courtingUntil, nil)
		local arrived = VillageSim.step(farm, NOW, 0, Rng.new(2), {
			errands = false,
			courtReady = { [1] = true },
		})
		T.eq(arrived.breeding.pairs[1].courtingUntil, NOW + Config.Breeding.CourtshipSeconds)
	end)
	T.test("ghost revives and schema three saves migrate", function()
		local farm = FarmKit.farm(NOW)
		farm.slimes[1].ghostUntil = NOW + 30
		local after, events = VillageSim.step(farm, NOW + 60, 60, Rng.new(3), { errands = false })
		T.eq(after.slimes[1].ghostUntil, nil)
		T.ok(#events > 0)
		local legacy = ProfileLogic.deepCopy(farm)
		legacy.food = { basicFood = 35, capacity = 100 }
		legacy.slimes[2].needs = { hunger = 27, hungerState = "hungry" }
		local saved = { schemaVersion = 3, savedAt = NOW, data = legacy }
		local loaded = ProfileLogic.prepareLoad(saved, FarmSave.hooks(), NOW + 60)
		T.ok(loaded.ok and loaded.migrated)
		T.eq(loaded.data.slimes[2].needs.fullness, 27)
		T.eq(loaded.data.storehouse.fish, 35)
		T.eq(loaded.data.areas.breeding.level, 1)
		T.eq(loaded.data.work.fishing.slots[1].progress, 0)
	end)
	T.test(
		"an old nest egg without a clock starts at the nest rate; offline, a nest egg hatches in its nest",
		function()
			local farm = FarmKit.farm(NOW)
			local made = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
			T.ok(made.ok)
			local old = made.farm
			old.eggs[1].hatchAt = nil -- saved before the nest rule
			-- no incubator in reach: the breeding area keeps none free
			local nestTime = Breeding.nestSeconds(old.eggs[1], old.areas.breeding.level)
			local started = VillageSim.step(old, NOW + 10, 0, Rng.new(1), { errands = false })
			T.eq(started.eggs[1].hatchAt, NOW + 10 + nestTime)
			T.eq(started.eggs[1].place, "nest")
			local after, events = VillageSim.step(started, NOW + 10 + nestTime, 0, Rng.new(1), { errands = false })
			T.eq(#after.eggs, 0, "it hatched in the nest")
			local hatched = false
			for _, e in events do
				hatched = hatched or e.kind == "hatched"
			end
			T.ok(hatched)
		end
	)
	T.test("offline errands move a nest egg into a free incubator, keeping its progress", function()
		local farm = FarmKit.farm(NOW)
		local made = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		local egg = made.farm.eggs[1]
		local full = Breeding.nestSeconds(egg, made.farm.areas.breeding.level) / Config.Breeding.NestSlowFactor
		local after = VillageSim.catchUp(made.farm, NOW, NOW + Config.Village.StepSeconds, Rng.new(1))
		local moved = after.eggs[1]
		if moved then
			T.eq(moved.place, "incubator")
			-- faster than staying in the nest, never faster than a full incubation from laying
			T.ok(moved.hatchAt < NOW + full * Config.Breeding.NestSlowFactor and moved.hatchAt >= NOW + full)
		end
	end)
end
