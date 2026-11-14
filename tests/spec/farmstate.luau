local Breeding = require("../../src/shared/Breeding")
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")

local NOW = 1793059200 + 3600

return function(T)
	T.test("the navy starters are adults with fixed traits and complete needs", function()
		local farm = FarmState.newFarm(NOW)
		local seeds = { 2654435769, 467448786, 2514546031, 267659000 }
		T.eq(#farm.slimes, Config.Farm.StarterCount)
		local seen = {}
		for i, slime in farm.slimes do
			T.eq(slime.id, "slime-" .. i)
			T.eq(slime.name, "Slime " .. i)
			if seeds[i] then
				T.eq(slime.seed, seeds[i])
			end
			T.ok(not seen[slime.seed], "every starter has its own seed")
			seen[slime.seed] = true
			T.same(slime.stats, { attack = 1, defence = 1, speed = 1, hp = 10 })
			T.same(slime.colourGenotype, { alleles = { "navy", "navy" } })
			T.same(slime.appearanceMutation, { type = "none" })
			T.eq(slime.visibleColour, "navy")
			T.same(slime.needs, { fullness = 100, energy = 100, fun = 100 })
			T.eq(slime.trait, FarmState.traitForSeed(slime.seed))
			T.same(slime.friends, {})
			T.eq(slime.ghostUntil, nil)
			T.eq(slime.buff, nil)
			T.same(slime.loadout, {})
			T.ok(not Breeding.isBaby(farm, slime, NOW))
			T.eq(slime.fallen, nil)
			T.eq(slime.previousLoadout, nil)
		end
	end)

	T.test("new village has all areas, work, food, pair places and preserved other state", function()
		local farm = FarmState.newFarm(NOW)
		T.same(farm.eggs, {})
		T.same(farm.discoveries, {
			base = { navy = { firstDiscoveredAt = NOW, hatchCount = Config.Farm.StarterCount } },
			dual = {},
			secret = {},
			material = {},
		})
		T.same(farm.storehouse, { fish = 10, carrot = 10 })
		T.same(farm.counter, {})
		T.same(farm.fridge, {})
		T.eq((farm :: any).cookedAllowed, nil)
		T.eq(#farm.breeding.pairs, 2)
		T.same(farm.breeding.pairs[1], {})
		for _, id in Config.Village.Areas do
			T.eq(farm.areas[id].level, 1)
		end
		for _, id in Config.Work.Areas do
			T.eq(#farm.work[id].slots, 1)
			T.same(farm.work[id].slots[1], { progress = 0 })
			T.same(farm.work[id].box, {})
		end
		T.eq(farm.food, nil)
		T.eq(farm.workstations, nil)
		T.eq(farm.unlockedStations, nil)
		T.eq(farm.upgrades, nil)
		T.eq(farm.nest, nil)
		T.eq(farm.coins, 0)
		T.eq(#farm.items, 9)
		T.same(farm.items[1], { id = "item-sword-1", definitionId = "sword", ownership = { kind = "INVENTORY" } })
		T.same(farm.materials, {})
		T.eq(farm.lastSimulatedAt, NOW)
		T.eq(farm.lifetime.bestSlimeLevel, 4)
		T.eq(farm.avatar.name, "You")
		T.eq(farm.tutorialDone, false)
	end)

	T.test("healthy farm and nest egg survive repair without warnings", function()
		local farm = FarmState.newFarm(NOW)
		local result = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(3), FarmKit.ids())
		T.ok(result.ok)
		local repaired, warnings, replaced = FarmState.repair(result.farm, NOW + 1)
		T.same(repaired, result.farm)
		T.same(warnings, {})
		T.eq(replaced, false)
	end)

	T.test("one broken slime is repaired without erasing good slimes, items or coins", function()
		local farm = FarmState.newFarm(NOW)
		while #farm.slimes > 4 do
			table.remove(farm.slimes)
		end
		farm.coins = 1234.7
		local broken = table.clone(farm.slimes[2])
		broken.stats = "junk"
		broken.colourGenotype = { alleles = { "navy", "teal" } }
		broken.needs = nil
		farm.slimes[2] = broken
		farm.slimes[5] = { name = "no id" }
		farm.slimes[6] = "garbage"
		farm.slimes[7] = table.clone(farm.slimes[1])
		local repaired, warnings, replaced = FarmState.repair(farm, NOW)
		T.eq(#repaired.slimes, 4)
		T.eq(repaired.coins, 1234)
		T.eq(replaced, false)
		T.same(repaired.slimes[1], FarmState.newFarm(NOW).slimes[1])
		T.same(repaired.slimes[2].stats, { attack = 1, defence = 1, speed = 1, hp = 10 })
		T.same(repaired.slimes[2].needs, { fullness = 100, energy = 100, fun = 100 })
		T.same(repaired.slimes[2].colourGenotype.alleles, { "navy", "navy" })
		T.eq(#repaired.items, 9)
		T.ok(#warnings >= 5)
	end)

	T.test("needs, friendships, traits, area levels and inventory repair independently", function()
		local farm = FarmState.newFarm(NOW)
		farm.slimes[1].needs = { fullness = -5, energy = 999, fun = 45 }
		farm.slimes[1].trait = "made-up"
		farm.slimes[1].friends = {
			a = 100,
			b = 1,
			c = 60,
			d = 70,
			e = 80,
			f = 90,
			g = 99,
			h = 98,
			i = 20,
		}
		farm.areas.fishing.level = 99
		farm.areas.garden.level = -10
		farm.storehouse = { fish = 900, carrot = 500, junk = 5 }
		farm.counter = { fish = 100, cabbage = 100 }
		farm.fridge = { grilledFish = 500, fake = 10 }
		local out = FarmState.repair(farm, NOW)
		T.same(out.slimes[1].needs, { fullness = 0, energy = 100, fun = 45 })
		T.eq(out.slimes[1].trait, FarmState.traitForSeed(out.slimes[1].seed))
		T.eq(out.slimes[1].friends.b, nil)
		T.eq(out.slimes[1].friends.a, 100)
		T.eq(out.areas.fishing.level, 50)
		T.eq(out.areas.garden.level, 1)
		T.eq(#out.work.fishing.slots, 4)
		T.eq(out.storehouse.fish, 100)
		T.eq(out.storehouse.junk, nil)
		T.eq(out.counter.fish, 10)
		T.eq(out.fridge.grilledFish, 20)
		T.eq(out.fridge.fake, nil)
	end)

	T.test("bad work assignments clear duplicates, missing babies and ghosts", function()
		local farm = FarmState.newFarm(NOW)
		farm.areas.fishing.level = 11
		farm.work.fishing.slots = {
			{ worker = "slime-1", reserve = "slime-2", progress = 25 },
			{ worker = "slime-1", reserve = "ghost", progress = -3 },
		}
		farm.work.training.slots[1] = { worker = "slime-3", stat = "hp", progress = 15 }
		farm.slimes[3].ghostUntil = NOW + 100
		farm.breeding.pairs = {
			{ a = "slime-1", b = "slime-4" },
			{ a = "slime-2", b = "slime-4" },
		}
		local out = FarmState.repair(farm, NOW)
		T.eq(out.work.fishing.slots[1].worker, "slime-1")
		T.eq(out.work.fishing.slots[1].reserve, "slime-2")
		T.eq(out.work.fishing.slots[2].worker, nil)
		T.eq(out.work.fishing.slots[2].reserve, nil)
		T.eq(out.work.fishing.slots[2].progress, 0)
		T.eq(out.work.training.slots[1].worker, nil)
		T.same(out.breeding.pairs, { {}, {} })
	end)

	T.test("egg embryos and timers survive repair, but invalid eggs do not", function()
		local farm = FarmState.newFarm(NOW)
		local good = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		assert(good.egg)
		good.farm.eggs[1].place = "incubator"
		good.farm.eggs[1].slot = 1
		good.farm.eggs[1].hatchAt = NOW + 50
		table.insert(good.farm.eggs, { id = "bad", parentIds = { "a", "b" }, createdAt = NOW, hatchAt = NOW })
		local out = FarmState.repair(good.farm, NOW + 70)
		T.eq(#out.eggs, 1)
		T.eq(out.eggs[1].hatchAt, NOW + 50, "incubation is never restarted")
		T.eq(out.eggs[1].status, "ready")
		T.same(out.eggs[1].embryo, good.egg.embryo)
	end)

	T.test("discoveries and equipment are repaired without wiping unrelated fields", function()
		local farm = FarmState.newFarm(NOW)
		farm.discoveries.material = {
			gold = { firstDiscoveredAt = NOW, hatchCount = 2 },
			junk = { hatchCount = 0 },
		}
		farm.slimes[1].appearanceMutation = { type = "material", definitionId = "unobtainium" }
		farm.slimes[1].loadout = { hand = "item-sword-1", head = "item-missing" }
		farm.slimes[2].loadout = { hand = "item-sword-1" }
		farm.items[3].ownership = { kind = "BATTLE_ESCROW" }
		table.insert(farm.items, { id = "old", definitionId = "sword-2", ownership = { kind = "INVENTORY" } })
		farm.materials = { crown_shard = 1, bad = -1 }
		local out, warnings = FarmState.repair(farm, NOW)
		T.same(out.slimes[1].appearanceMutation, { type = "material", definitionId = "unobtainium" })
		T.same(out.discoveries.material, { gold = { firstDiscoveredAt = NOW, hatchCount = 2 } })
		T.same(out.slimes[1].loadout, { hand = "item-sword-1" })
		T.same(out.slimes[2].loadout, {})
		T.same(out.items[1].ownership, { kind = "EQUIPPED_TO_SLIME", slimeId = "slime-1", slot = "hand" })
		T.eq(#out.items, 9)
		T.same(out.materials, { crown_shard = 1 })
		T.eq(out.wbKingSlain, true)
		T.ok(#warnings > 0)
	end)

	T.test("unusable saved farms never silently replace a player's progress", function()
		local fresh, warnings, replaced = FarmState.repair("junk", NOW)
		T.same(fresh, FarmState.newFarm(NOW))
		T.ok(#warnings > 0)
		T.eq(replaced, true)
		local empty, _, replacedEmpty = FarmState.repair({ slimes = { { name = "no id" } }, coins = 50 }, NOW)
		T.eq(empty.coins, 0)
		T.eq(replacedEmpty, true)
	end)

	T.test("repair only cuts absurd arrays and day keys are UTC", function()
		local farm = FarmState.newFarm(NOW)
		farm.slimes = FarmKit.many(600)
		T.eq(#FarmState.repair(farm, NOW).slimes, 500)
		farm.slimes = FarmKit.many(60)
		T.eq(#FarmState.repair(farm, NOW).slimes, 60)
		T.eq(FarmState.dayKey(1793059200), "2026-10-27")
		T.eq(FarmState.dayKey(1793059200 - 1), "2026-10-26")
	end)

	T.test("teams: a fresh farm has empty ones, an old save gets them, a repair keeps the good members only", function()
		local farm = FarmState.newFarm(NOW)
		T.eq(#farm.teams, Config.Zombies.Teams)
		for _, team in farm.teams do
			T.same(team, { members = {}, repeatOn = false })
		end

		local old = FarmState.newFarm(NOW)
		old.teams = nil :: any
		local fromOld, _, replacedOld = FarmState.repair(old, NOW)
		T.eq(replacedOld, false, "an old save is not an unreadable one")
		T.eq(#fromOld.teams, Config.Zombies.Teams)
		T.same(fromOld.teams[1], { members = {}, repeatOn = false })
		local junk = FarmState.newFarm(NOW)
		junk.teams = "junk" :: any
		T.eq(#FarmState.repair(junk, NOW).teams, Config.Zombies.Teams)

		local messy = FarmState.newFarm(NOW)
		messy.slimes = FarmKit.many(10)
		for _, slime in messy.slimes do
			slime.createdAt = NOW - 100000 -- repair makes a slime with no birth time a baby
		end
		messy.work.fishing.slots[1].worker = "s9"
		messy.breeding.pairs[1] = { a = "s8", b = "s7" }
		messy.teams = {
			{ members = { "s1", "ghost-of-a-lost-one", "s1", "s2", "s9", "s3" }, repeatOn = true, target = "c2g3" },
			{ members = { "s2", "s4", "s7", "s5", "s6", "s10" }, repeatOn = "yes" :: any, target = 5 :: any },
			{ members = {} },
		} :: any
		local out = FarmState.repair(messy, NOW)
		T.eq(#out.teams, Config.Zombies.Teams)
		T.same(out.teams[1], { members = { "s1", "s2", "s3" }, repeatOn = true, target = "c2g3" })
		T.same(out.teams[2], { members = { "s4", "s5", "s6", "s10" }, repeatOn = false }, "full, none twice")
		T.same(out.teams[3], { members = {}, repeatOn = false })
		T.same(out.teams[4], { members = {}, repeatOn = false })
		T.eq(out.work.fishing.slots[1].worker, "s9", "the job kept its worker")
	end)

	T.test("removeSlime takes the slime out of its team too", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(5))
		farm.teams[2].members = { "s1", "s2" }
		T.eq(FarmState.teamOf(farm, "s2"), 2)
		T.eq(FarmState.teamOf(farm, "s3"), nil)
		T.ok(FarmState.removeSlime(farm, "s1"))
		T.same(farm.teams[2].members, { "s2" })
		T.eq(FarmState.teamOf(farm, "s1"), nil)
	end)

	T.test("team sheet repair keeps valid rows and tactics but discards stale or bad overrides", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(5))
		farm.teams[1] = {
			members = { "s1", "s2" },
			repeatOn = false,
			formation = { s1 = "back", s2 = "elsewhere", ghost = "middle" },
			tactic = "focus",
		}
		farm.teams[2] = {
			members = { "s3" },
			repeatOn = false,
			formation = { ghost = "front", s3 = "side" },
			tactic = "nonsense",
		}
		farm.teams[3] = { members = { "s4" }, repeatOn = false, tactic = "protect" }
		farm.teams[4] = { members = { "s5" }, repeatOn = false, tactic = "balanced" }
		local repaired = FarmState.repair(farm, NOW)
		T.same(repaired.teams[1].formation, { s1 = "back" })
		T.eq(repaired.teams[1].tactic, "focus")
		T.eq(repaired.teams[2].formation, nil, "an empty override map does not survive repair")
		T.eq(repaired.teams[2].tactic, nil)
		T.eq(repaired.teams[3].tactic, "protect")
		T.eq(repaired.teams[4].tactic, nil, "Balanced is the absence of an override")
	end)

	T.test("a team's exploring survives repair only as a real band", function()
		local farm: any = FarmKit.farm(NOW, FarmKit.many(3))
		farm.teams[1] = { members = { "s1" }, repeatOn = false, explore = 2 }
		farm.teams[2] = { members = { "s2" }, repeatOn = false, explore = 0 }
		farm.teams[3] = { members = { "s3" }, repeatOn = false, explore = 999 }
		farm.teams[4] = { members = {}, repeatOn = false, explore = "far" }
		local repaired = FarmState.repair(farm, NOW)
		T.eq(repaired.teams[1].explore, 2)
		T.eq(repaired.teams[2].explore, nil)
		T.eq(repaired.teams[3].explore, nil)
		T.eq(repaired.teams[4].explore, nil)
	end)

	T.test("removing a slime prunes its team row without disturbing another member", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(4))
		farm.teams[1].members = { "s1", "s2" }
		farm.teams[1].formation = { s1 = "back", s2 = "middle" }
		farm.teams[1].tactic = "protect"
		T.ok(FarmState.removeSlime(farm, "s1"))
		T.same(farm.teams[1].members, { "s2" })
		T.same(farm.teams[1].formation, { s2 = "middle" })
		T.eq(farm.teams[1].tactic, "protect")
		T.ok(FarmState.removeSlime(farm, "s2"))
		T.eq(farm.teams[1].formation, nil)
	end)
end
