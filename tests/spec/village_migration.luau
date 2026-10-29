--!strict
local Config = require("../../src/shared/Config")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local ProfileLogic = require("../../src/shared/ProfileLogic")

return function(T: any)
	T.test("schema 4 to 5 adds empty garden plots without losing other progress", function()
		local now = 1000000
		local old = FarmState.newFarm(now)
		old.work.garden.plots = nil
		old.work.garden.slots[1].progress = 67
		old.work.garden.box = { carrot = 3 }
		old.coins = 12345
		old.areas.garden.level = 25
		local load = ProfileLogic.prepareLoad(
			{ schemaVersion = 4, savedAt = now, data = old },
			FarmSave.hooks(),
			now + 1
		)
		T.ok(load.ok)
		T.ok(load.migrated)
		T.eq(load.data.coins, 12345)
		T.eq(load.data.areas.garden.level, 25)
		T.eq(load.data.work.garden.box.carrot, 3)
		T.eq(load.data.work.garden.slots[1].progress, 67)
		T.eq(#load.data.work.garden.plots, Config.Work.GardenPlotCount)
		T.same(load.data.work.garden.plots[1], { crop = "", stage = 0, progress = 0, watered = false })
		T.eq(old.work.garden.plots, nil, "migration never alters old snapshot")
	end)

	T.test("existing healthy crops survive normal schema five load", function()
		local now = 1000000
		local farm = FarmState.newFarm(now)
		local plots = farm.work.garden.plots
		assert(plots)
		plots[2] = { crop = "cabbage", stage = 3, progress = 20, watered = true }
		local loaded = ProfileLogic.prepareLoad(
			{ schemaVersion = Config.Save.SchemaVersion, savedAt = now, data = farm },
			FarmSave.hooks(), now + 1
		)
		T.ok(loaded.ok)
		T.same(loaded.data.work.garden.plots[2], plots[2])
	end)
end
