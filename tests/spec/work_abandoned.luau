--!strict
-- A catch or a garden chore whose slime is gone must never jam its work place while the player stays online.
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local Rng = require("../../src/shared/Rng")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")

local NOW = 1000000

return function(T: any)
	T.test("a catch nobody carries goes in the bin and the place works again", function()
		local farm: any = FarmKit.farm(NOW)
		local slot = farm.work.fishing.slots[1]
		slot.worker = "slime-1"
		slot.pending = "fish"
		local ready = { ["slime-1"] = "work:fishing:1" }
		local jammed: any = VillageSim.step(farm, NOW + 1, 1, Rng.new(1), { errands = false, workReady = ready })
		T.eq(jammed.work.fishing.slots[1].pending, "fish", "the jam this guards against")
		T.eq(jammed.work.fishing.slots[1].progress, 0)

		Stations.freeAbandoned(farm, {})
		T.eq(slot.pending, nil)
		T.eq(farm.work.fishing.box.fish, 1)
		local after: any = VillageSim.step(farm, NOW + 1, 1, Rng.new(1), { errands = false, workReady = ready })
		T.ok(after.work.fishing.slots[1].progress > 0, "the next worker starts")
	end)

	T.test("a slime on its way keeps its item", function()
		local farm: any = FarmKit.farm(NOW)
		local fishing = farm.work.fishing.slots[1]
		local garden = farm.work.garden.slots[1]
		fishing.pending = "fish"
		garden.plot, garden.task = 1, "harvest"
		Stations.freeAbandoned(farm, { ["work:fishing:1"] = true, ["work:garden:1"] = true })
		T.eq(fishing.pending, "fish")
		T.eq(garden.task, "harvest")
		T.eq(garden.plot, 1)
		T.same(farm.work.fishing.box, {})
	end)

	T.test("an abandoned garden chore frees the place and leaves the crop for the next worker", function()
		local farm: any = FarmKit.farm(NOW)
		local garden = farm.work.garden.slots[1]
		local before = table.clone(farm.work.garden.plots[1])
		garden.plot, garden.task = 1, "harvest"
		Stations.freeAbandoned(farm, {})
		T.eq(garden.task, nil)
		T.eq(garden.plot, nil)
		T.same(farm.work.garden.plots[1], before)
	end)

	T.test("a full bin keeps the catch saved until there is room", function()
		local farm: any = FarmKit.farm(NOW)
		local slot = farm.work.fishing.slots[1]
		slot.pending = "salmon"
		farm.work.fishing.box = { fish = Config.Work.BoxCapacity }
		Stations.freeAbandoned(farm, {})
		T.eq(slot.pending, "salmon")
		farm.work.fishing.box = {}
		Stations.freeAbandoned(farm, {})
		T.eq(slot.pending, nil)
		T.eq(farm.work.fishing.box.salmon, 1)
	end)

	T.test("the Studio switch for the real store stays off", function()
		T.eq(Config.Save.StudioUsesRealStore, false)
	end)
end
