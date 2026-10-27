local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Config = require("../../src/shared/Config")

local function envelope(data: any, lastGood: any?): any
	return { schemaVersion = Config.Save.SchemaVersion, savedAt = 0, data = data, lastGood = lastGood }
end

return function(T)
	T.test("a new player gets the four starters", function()
		local result = ProfileLogic.prepareLoad(nil, FarmSave.hooks(), 1000)
		T.ok(result.ok)
		T.ok(result.isNew)
		T.eq(#result.data.slimes, Config.Farm.StarterCount)
	end)

	T.test("a stored farm loads and keeps its coins", function()
		local farm = FarmState.newFarm(1000)
		farm.coins = 1234
		local result = ProfileLogic.prepareLoad(envelope(farm), FarmSave.hooks(), 2000)
		T.ok(result.ok)
		T.eq(result.data.coins, 1234)
		T.eq(result.isNew, false)
	end)

	T.test("an unreadable farm is never replaced by a fresh one", function()
		local result = ProfileLogic.prepareLoad(envelope({ coins = 5 }), FarmSave.hooks(), 2000)
		T.eq(result.ok, false)
		T.eq(result.data, nil)
	end)

	T.test("a farm whose slimes are all broken falls back to the last-good copy", function()
		local good = FarmState.newFarm(1000)
		good.coins = 77
		local broken = FarmState.newFarm(1000)
		broken.slimes = { { id = 5 }, "junk" }
		local result = ProfileLogic.prepareLoad(envelope(broken, envelope(good)), FarmSave.hooks(), 2000)
		T.ok(result.ok)
		T.ok(result.usedLastGood)
		T.eq(result.data.coins, 77)
	end)

	T.test("repairs are logged, a clean farm is not", function()
		local lines = {}
		local hooks = FarmSave.hooks(function(line)
			table.insert(lines, line)
		end)
		local farm = FarmState.newFarm(1000)
		hooks.repair(farm, 2000)
		T.eq(#lines, 0)
		farm.coins = -5
		hooks.repair(farm, 2000)
		T.eq(#lines, 1)
	end)
end
