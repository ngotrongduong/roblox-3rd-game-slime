--!strict
local Config = require("../../src/shared/Config")
local GardenPlots = require("../../src/shared/GardenPlots")
local FarmKit = require("../lib/FarmKit")
local Rng = require("../../src/shared/Rng")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")

return function(T: any)
	T.test("new garden plots hoe, plant, water, grow and harvest in order", function()
		local plots = GardenPlots.new(Config.Work.GardenPlotCount)
		T.eq(#plots, Config.Work.GardenPlotCount)
		T.same(plots[1], { crop = "", stage = 0, progress = 0, watered = false })
		T.eq(select(2, GardenPlots.choose(plots)), "hoe")
		GardenPlots.apply(plots, 1, "water", "")
		T.eq(plots[1].stage, 0, "cannot water bare ground")
		GardenPlots.apply(plots, 1, "hoe", "")
		T.eq(plots[1].stage, -1)
		GardenPlots.apply(plots, 1, "hoe", "")
		T.eq(plots[1].stage, -1, "hoeing twice does not plant")
		GardenPlots.apply(plots, 1, "plant", "fish")
		T.eq(plots[1].stage, -1, "a fish is not a crop")
		GardenPlots.apply(plots, 1, "plant", "carrot")
		T.same(plots[1], { crop = "carrot", stage = 1, progress = 0, watered = false })
		GardenPlots.apply(plots, 1, "plant", "tomato")
		T.eq(plots[1].crop, "carrot", "cannot replace a planted crop")
		T.eq(GardenPlots.apply(plots, 1, "harvest", ""), nil, "unripe crop cannot be picked")
		GardenPlots.apply(plots, 1, "water", "")
		T.ok(plots[1].watered)
		for stage = 2, 4 do
			GardenPlots.grow(plots, Config.Work.GardenStageSeconds)
			T.eq(plots[1].stage, stage)
			if stage < 4 then
				T.eq(plots[1].watered, false)
				GardenPlots.apply(plots, 1, "water", "")
			end
		end
		T.eq(GardenPlots.apply(plots, 1, "harvest", ""), "carrot")
		T.same(plots[1], { crop = "", stage = 0, progress = 0, watered = false })
	end)

	T.test("dry crops grow slowly; watered crops advance quickly", function()
		local dry = GardenPlots.new(1)
		local wet = GardenPlots.new(1)
		for _, plots in { dry, wet } do
			GardenPlots.apply(plots, 1, "hoe", "")
			GardenPlots.apply(plots, 1, "plant", "cabbage")
		end
		GardenPlots.apply(wet, 1, "water", "")
		GardenPlots.grow(dry, Config.Work.GardenStageSeconds)
		GardenPlots.grow(wet, Config.Work.GardenStageSeconds)
		T.eq(dry[1].stage, 1)
		T.eq(wet[1].stage, 2)
		local developmentDry = (dry[1].stage - 1) * Config.Work.GardenStageSeconds + dry[1].progress
		local developmentWet = (wet[1].stage - 1) * Config.Work.GardenStageSeconds + wet[1].progress
		T.ok(developmentWet > developmentDry, "watering advances overall crop maturity despite stage progress reset")
	end)

	T.test("one slime establishes several beds rather than monopolising the first crop", function()
		local plots = GardenPlots.new(Config.Work.GardenPlotCount)
		-- An older stage-two plant should not block a newly available bed.
		plots[1] = { crop = "carrot", stage = 2, progress = 0, watered = false }
		for expected = 2, 7 do
			local index, action = GardenPlots.choose(plots)
			T.eq(index, expected)
			T.eq(action, "hoe")
			GardenPlots.apply(plots, index :: number, action :: string, "")
			index, action = GardenPlots.choose(plots)
			T.eq(index, expected)
			T.eq(action, "plant")
			GardenPlots.apply(plots, index :: number, action :: string, "cabbage")
			index, action = GardenPlots.choose(plots)
			T.eq(index, expected)
			T.eq(action, "water")
			GardenPlots.apply(plots, index :: number, action :: string, "")
		end
		for index = 2, 7 do
			T.eq(plots[index].crop, "cabbage")
			T.ok(plots[index].watered)
		end
	end)

	T.test("one offline gardener plants multiple real plots", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.ok(Stations.assign(farm, "slime-1", "garden", 1, false, now))
		local grown = VillageSim.step(farm, now + 420, 420, Rng.new(8), { errands = false })
		local sown = 0
		for _, plot in grown.work.garden.plots do
			if plot.crop ~= "" then
				sown += 1
			end
		end
		T.ok(sown >= 4, "one gardener should have several crops in the ground after seven minutes")
		T.eq(farm.work.garden.plots[1].crop, "", "sim remains pure")
	end)

	T.test("large time steps consume water only for the first growth stage", function()
		local plots = GardenPlots.new(1)
		GardenPlots.apply(plots, 1, "hoe", "")
		GardenPlots.apply(plots, 1, "plant", "cabbage")
		GardenPlots.apply(plots, 1, "water", "")
		GardenPlots.grow(plots, Config.Work.GardenStageSeconds * 2)
		T.eq(plots[1].stage, 2)
		T.ok(plots[1].progress < Config.Work.GardenStageSeconds)
		T.eq(plots[1].watered, false)
	end)

	T.test("invalid garden plots repair independently without touching healthy plants", function()
		local raw = {
			{ crop = "cabbage", stage = 3, progress = 12, watered = true },
			{ crop = "fake", stage = 99, progress = -6, watered = true },
			{ crop = "carrot", stage = -1, progress = 0 / 0, watered = false },
			{ crop = "pumpkin", stage = 4, progress = 0, watered = false },
			{ crop = "trout", stage = 2, progress = 3, watered = false },
		}
		local out = GardenPlots.repair(raw, 5)
		T.same(out[1], raw[1])
		T.same(out[2], { crop = "", stage = 0, progress = 0, watered = false })
		T.eq(out[3].stage, 1)
		T.eq(out[3].progress, 0)
		T.same(out[4], raw[4], "a new vegetable kind survives repair")
		T.same(out[5], { crop = "", stage = 0, progress = 0, watered = false }, "a fish is not a crop")
	end)

	T.test("online garden work defers crop changes until the visible chore, offline resumes it", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.ok(Stations.assign(farm, "slime-1", "garden", 1, false, now))
		local online, events = VillageSim.step(farm, now + 20, 20, Rng.new(6), {
			errands = false,
			workReady = { ["slime-1"] = "work:garden:1" },
		})
		T.eq(online.work.garden.slots[1].task, "hoe")
		T.eq(online.work.garden.plots[1].stage, 0, "crop is not changed before arrival")
		T.eq(events[1].phase, "hoe")
		local offline = VillageSim.step(online, now + 21, 1, Rng.new(6), { errands = true })
		T.eq(offline.work.garden.slots[1].task, nil)
		T.eq(offline.work.garden.plots[1].stage, -1)
	end)

	T.test("online fish are pending until the bin handoff, then offline reconnect recovers them", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.ok(Stations.assign(farm, "slime-1", "fishing", 1, false, now))
		local after, events = VillageSim.step(farm, now + 60, 60, Rng.new(2), {
			errands = false,
			workReady = { ["slime-1"] = "work:fishing:1" },
		})
		local caught = after.work.fishing.slots[1].pending
		T.ok(caught ~= nil and Config.Food.Kinds[caught].group == "fish", "the catch is one of the fish kinds")
		T.eq(after.work.fishing.box[caught], nil)
		T.eq(events[1].kind, "collected")
		T.eq(events[1].item, caught)
		-- Offline errands may move stock from the bin to the storehouse and onward to the
		-- kitchen counter. Count all three destinations, not just the first two.
		local function fishStock(snapshot: any): number
			return (snapshot.work.fishing.box[caught] or 0)
				+ (snapshot.storehouse[caught] or 0)
				+ (snapshot.counter[caught] or 0)
		end
		local originalStock = fishStock(after)
		local offline = VillageSim.step(after, now + 61, 0, Rng.new(3), { errands = true })
		T.eq(offline.work.fishing.slots[1].pending, nil)
		T.eq(fishStock(offline), originalStock + Config.Work.FishingYield, "recovered fish is neither lost nor doubled")
		T.eq(after.work.fishing.slots[1].pending, caught, "the input state remains unchanged")
		local again = VillageSim.step(offline, now + 62, 0, Rng.new(3), { errands = true })
		T.eq(fishStock(again), fishStock(offline), "replaying offline transfer never deposits the same fish twice")
		T.eq(again.work.fishing.slots[1].pending, nil)
	end)

	T.test("offline village grows real plots and collects vegetables", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.ok(Stations.assign(farm, "slime-1", "garden", 1, false, now))
		local after, events = VillageSim.catchUp(farm, now, now + Config.Village.OfflineCapSeconds, Rng.new(7))
		local grown = 0
		for _, event in events do
			if
				event.kind == "collected"
				and event.area == "garden"
				and Config.Food.Kinds[event.item].group == "veg"
			then
				grown += 1
			end
		end
		T.ok(grown > 0, "offline gardener collects actual ripe crops")
		T.eq(#after.work.garden.plots, Config.Work.GardenPlotCount)
		T.eq(farm.work.garden.plots[1].stage, 0, "input is immutable")
	end)
end
