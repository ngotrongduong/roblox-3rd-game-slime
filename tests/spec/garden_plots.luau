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
		GardenPlots.apply(plots, 1, "water", true)
		T.eq(plots[1].stage, 0, "cannot water bare ground")
		GardenPlots.apply(plots, 1, "hoe", true)
		T.eq(plots[1].stage, -1)
		GardenPlots.apply(plots, 1, "hoe", true)
		T.eq(plots[1].stage, -1, "hoeing twice does not plant")
		GardenPlots.apply(plots, 1, "plant", true)
		T.same(plots[1], { crop = "carrot", stage = 1, progress = 0, watered = false })
		GardenPlots.apply(plots, 1, "plant", false)
		T.eq(plots[1].crop, "carrot", "cannot replace a planted crop")
		T.eq(GardenPlots.apply(plots, 1, "harvest", true), nil, "unripe crop cannot be picked")
		GardenPlots.apply(plots, 1, "water", true)
		T.ok(plots[1].watered)
		for stage = 2, 4 do
			GardenPlots.grow(plots, Config.Work.GardenStageSeconds)
			T.eq(plots[1].stage, stage)
			if stage < 4 then
				T.eq(plots[1].watered, false)
				GardenPlots.apply(plots, 1, "water", true)
			end
		end
		T.eq(GardenPlots.apply(plots, 1, "harvest", false), "carrot")
		T.same(plots[1], { crop = "", stage = 0, progress = 0, watered = false })
	end)

	T.test("dry crops grow slowly; watered crops advance quickly", function()
		local dry = GardenPlots.new(1)
		local wet = GardenPlots.new(1)
		for _, plots in { dry, wet } do
			GardenPlots.apply(plots, 1, "hoe", true)
			GardenPlots.apply(plots, 1, "plant", false)
		end
		GardenPlots.apply(wet, 1, "water", true)
		GardenPlots.grow(dry, Config.Work.GardenStageSeconds)
		GardenPlots.grow(wet, Config.Work.GardenStageSeconds)
		T.eq(dry[1].stage, 1)
		T.eq(wet[1].stage, 2)
		T.ok(wet[1].progress >= dry[1].progress)
	end)

	T.test("invalid garden plots repair independently without touching healthy plants", function()
		local raw = {
			{ crop = "cabbage", stage = 3, progress = 12, watered = true },
			{ crop = "fake", stage = 99, progress = -6, watered = true },
			{ crop = "carrot", stage = -1, progress = 0 / 0, watered = false },
		}
		local out = GardenPlots.repair(raw, 3)
		T.same(out[1], raw[1])
		T.same(out[2], { crop = "", stage = 0, progress = 0, watered = false })
		T.eq(out[3].stage, 1)
		T.eq(out[3].progress, 0)
	end)

	T.test("online fish are pending until the bin handoff, then offline reconnect recovers them", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.ok(Stations.assign(farm, "slime-1", "fishing", 1, false, now))
		local after, events = VillageSim.step(farm, now + 60, 60, Rng.new(2), {
			errands = false,
			workReady = { ["slime-1"] = "work:fishing:1" },
		})
		T.eq(after.work.fishing.box.fish, nil)
		T.eq(after.work.fishing.slots[1].pending, "fish")
		T.eq(events[1].kind, "collected")
		local offline = VillageSim.step(after, now + 61, 1, Rng.new(3), { errands = true })
		T.eq(offline.work.fishing.slots[1].pending, nil)
		T.eq(offline.work.fishing.box.fish, 1)
	end)

	T.test("offline village grows real plots and collects vegetables", function()
		local now = 1000000
		local farm = FarmKit.farm(now)
		T.ok(Stations.assign(farm, "slime-1", "garden", 1, false, now))
		local after, events = VillageSim.catchUp(farm, now, now + Config.Village.OfflineCapSeconds, Rng.new(7))
		local grown = 0
		for _, event in events do
			if event.kind == "collected" and (event.item == "carrot" or event.item == "cabbage") then
				grown += 1
			end
		end
		T.ok(grown > 0, "offline gardener collects actual ripe crops")
		T.eq(#after.work.garden.plots, Config.Work.GardenPlotCount)
		T.eq(farm.work.garden.plots[1].stage, 0, "input is immutable")
	end)
end
