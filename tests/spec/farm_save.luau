local Genetics = require("../../src/shared/Genetics")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Config = require("../../src/shared/Config")

local function envelope(data: any, lastGood: any?): any
	return { schemaVersion = Config.Save.SchemaVersion, savedAt = 0, data = data, lastGood = lastGood }
end

return function(T)
	T.test("v2 to v3 removes pattern genes and rewrites slimes and embryos without losing progress", function()
		local farm = FarmState.newFarm(1000)
		farm.coins = 4321
		farm.luckPotionUntil = 9000
		local appearances = {
			{ type = "none" },
			{ type = "material", definitionId = "gold" },
			{ type = "dual", definitionId = "dual-navy-red-21" },
			{ type = "secret", definitionId = "secret-navy-red" },
			{ type = "secret", definitionId = "secret-white-white" },
			{ type = "dual", definitionId = "dual-future" },
		}
		local expected = {
			{ "pink", "pink" },
			{ "pink", "pink" },
			{ "navy", "red" },
			{ "red", "navy" },
			{ "white", "white" },
			{ "pink", "pink" },
		}
		local visible = { "pink", "pink", "red", "red", "white", "pink" }
		for i, appearance in appearances do
			local slime = FarmState.newStarters(1000)[1]
			slime.id = "s" .. i
			slime.visibleColour = "pink"
			slime.colourGenotype = { alleles = { "white", "black" } }
			slime.patternGenotype = { alleles = { "solid", "duochrome" } }
			slime.appearanceMutation = appearance
			slime.isFavourite = true
			slime.breedReadyAt = 3000
			farm.slimes[i] = slime
			farm.eggs[i] = {
				id = "e" .. i,
				parentIds = { "s1", "s2" },
				offspringId = "baby" .. i,
				createdAt = 1000,
				hatchAt = 5000,
				status = "incubating",
				embryo = {
					stats = slime.stats,
					colourGenotype = slime.colourGenotype,
					patternGenotype = slime.patternGenotype,
					appearanceMutation = appearance,
				},
			}
		end
		local before = ProfileLogic.deepCopy(farm)
		local ok, migrated = ProfileLogic.migrate(farm, 2, 3, FarmSave.hooks().migrations, 2000)
		T.ok(ok)
		for i in appearances do
			T.eq(migrated.slimes[i].patternGenotype, nil)
			T.eq(migrated.eggs[i].embryo.patternGenotype, nil)
			T.same(migrated.slimes[i].colourGenotype.alleles, expected[i])
			local eggGenes = if i == 1 or i == 2 or i == 6 then { "black", "black" } else expected[i]
			T.same(
				migrated.eggs[i].embryo.colourGenotype.alleles,
				eggGenes,
				"old plain embryos preserve their previously visible colour"
			)
		end
		local loaded =
			ProfileLogic.prepareLoad({ schemaVersion = 2, savedAt = 1000, data = farm }, FarmSave.hooks(), 2000)
		T.ok(loaded.ok and loaded.migrated)
		T.eq(loaded.data.coins, 4321)
		T.eq(loaded.data.luckPotionUntil, 9000)
		for i, appearance in appearances do
			local slime, egg = loaded.data.slimes[i], loaded.data.eggs[i]
			T.same(slime.appearanceMutation, appearance)
			T.eq(slime.visibleColour, visible[i])
			T.eq(slime.isFavourite, true)
			T.eq(slime.breedReadyAt, 3000)
			T.eq(egg.createdAt, 1000)
			T.eq(egg.hatchAt, if i <= 2 then 5000 else nil)
			T.same(egg.embryo.appearanceMutation, appearance)
			T.same(slime.colourGenotype, Genetics.fromAppearance(appearance, slime.colourGenotype))
		end
		T.same(farm, before, "migration and repair never mutate the stored snapshot")
		T.same(ProfileLogic.migrateInheritance(migrated, 2000), migrated, "migration is idempotent")
	end)

	T.test("a version 2 last-good snapshot also migrates", function()
		local farm = FarmState.newFarm(1000)
		farm.slimes[1].patternGenotype = { alleles = { "solid", "solid" } }
		local result = ProfileLogic.prepareLoad(
			{ schemaVersion = 2, data = { slimes = {} }, lastGood = { schemaVersion = 2, savedAt = 1000, data = farm } },
			FarmSave.hooks(),
			2000
		)
		T.ok(result.ok and result.usedLastGood and result.migrated)
		T.eq(result.data.slimes[1].patternGenotype, nil)
	end)

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

	T.test(
		"a version 1 save migrates all steps to version 4 and keeps its collection",
		function()
			T.eq(Config.Save.SchemaVersion, 4)
			local farm = FarmState.newFarm(1000)
			farm.coins = 4321
			farm.discoveries.dual["dual-green-white-01"] = { firstDiscoveredAt = 5, hatchCount = 3 }
			farm.slimes[1].appearanceMutation = { type = "dual", definitionId = "dual-green-white-01" }
			local stored = FarmState.repair(farm, 1000)
			stored.discoveries.material = nil
			local env = { schemaVersion = 1, savedAt = 0, data = stored }
			local result = ProfileLogic.prepareLoad(env, FarmSave.hooks(), 2000)
			T.ok(result.ok)
			T.ok(result.migrated)
			T.eq(result.data.coins, 4321)
			T.same(result.data.discoveries.material, {})
			T.eq(result.data.discoveries.dual["dual-green-white-01"].hatchCount, 3, "old dual ids kept")
			T.eq(result.data.slimes[1].appearanceMutation.definitionId, "dual-green-white-01", "never converted")
			T.eq(stored.discoveries.material, nil, "the stored copy is not changed in place")
		end
	)

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
