local Breeding = require("../../src/shared/Breeding")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")

-- 2026-10-27 00:00:00 UTC + 1 hour
local NOW = 1793059200 + 3600

return function(T)
	T.test("newFarm: four identical navy starters, adult and rested", function()
		local farm = FarmState.newFarm(NOW)
		T.eq(#farm.slimes, 4)
		local seeds = { 2654435769, 467448786, 2514546031, 267659000 }
		for i, s in farm.slimes do
			T.eq(s.id, "slime-" .. i)
			T.eq(s.name, "Slime " .. i)
			T.eq(s.seed, seeds[i], "seed " .. i)
			T.eq(s.assetId, "slime.base.navy")
			T.same(s.stats, { attack = 1, defence = 1, speed = 1, hp = 10 })
			T.same(s.colourGenotype, { alleles = { "navy", "navy" } })
			T.eq(s.visibleColour, "navy")
			T.same(s.appearanceMutation, { type = "none" })
			T.eq(s.isFavourite, false)
			T.same(s.needs, { hunger = 100, hungerState = "full" })
			T.eq(s.breedReadyAt, 0)
			T.same(s.loadout, {})
			T.eq(s.fallen, false)
			T.eq(s.previousLoadout, nil)
			T.ok(not Breeding.isBaby(farm, s, NOW), "starters are adults at once")
		end
	end)

	T.test("newFarm: the rest of the farm matches the original defaults", function()
		local farm = FarmState.newFarm(NOW)
		T.same(farm.eggs, {})
		T.eq(farm.breedsSinceMutation, 0)
		T.same(farm.discoveries, {
			base = { navy = { firstDiscoveredAt = NOW, hatchCount = 4 } },
			dual = {},
			secret = {},
			material = {},
		})
		T.same(farm.food, { basicFood = 20, capacity = 100 })
		T.eq(#farm.workstations, 4)
		T.same(farm.workstations[1], {
			id = "station-1",
			definitionId = "ws.berry-bush",
			assignedSlimeIds = {},
			progressSeconds = 0,
			pendingOutput = 0,
		})
		T.eq(farm.workstations[4].definitionId, "ws.cooking-kitchen")
		T.same(farm.unlockedStations, { "ws.berry-bush" })
		T.eq(farm.lastSimulatedAt, NOW)
		T.eq(farm.coins, 0)
		T.eq(#farm.items, 9)
		T.same(farm.items[1], { id = "item-sword-1", definitionId = "sword", ownership = { kind = "INVENTORY" } })
		T.eq(farm.items[9].id, "item-kit-2")
		T.same(farm.materials, {})
		T.same(farm.upgrades, {
			foodStorage = 0,
			incubationSpeed = 0,
			breedCooldown = 0,
			growthSpeed = 0,
			slimeStorage = 0,
			autoHatch = 0,
			specializedBreeding = 0,
		})
		T.eq(farm.nest, nil)
		T.same(farm.lifetime, {
			coinsEarned = 0,
			foodFarmed = 0,
			bestSlimeLevel = 4,
			daysPlayed = 1,
			lastPlayedDay = "2026-10-27",
			mobsKilled = 0,
			bossesKilled = 0,
			breeds = 0,
			bestRaidKillSec = 0,
		})
		T.same(farm.avatar, {
			name = "You",
			assetId = "slime.base.navy",
			stats = { attack = 1, defence = 1, speed = 1, hp = 10 },
			spentPoints = 0,
			loadout = {},
			createdAt = NOW,
			frame = "wood",
			bg = "meadow",
			ownedFrames = {},
			ownedBgs = {},
		})
		T.eq(farm.tutorialDone, false)
		T.eq(farm.tutorialDoneAt, nil)
		T.eq(farm.lastSiegeTeam, nil)
		T.eq(farm.wbKingSlain, nil)
	end)

	T.test("repair keeps a healthy farm as it is", function()
		local farm = FarmState.newFarm(NOW)
		local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(3), FarmKit.ids())
		local repaired, warnings = FarmState.repair(res.farm, NOW + 1)
		T.same(repaired, res.farm)
		T.same(warnings, {})
	end)

	T.test("repair keeps the good slimes when one is broken", function()
		local farm = FarmState.newFarm(NOW)
		local broken = table.clone(farm.slimes[2])
		broken.stats = "junk"
		broken.colourGenotype = { alleles = { "navy", "teal" } }
		broken.needs = nil
		farm.slimes[2] = broken
		farm.slimes[5] = { name = "no id" }
		farm.slimes[6] = "garbage"
		farm.slimes[7] = table.clone(farm.slimes[1])
		local repaired, warnings = FarmState.repair(farm, NOW)
		T.eq(#repaired.slimes, 4, "dropped: no id, not a table, duplicate")
		T.same(repaired.slimes[1], FarmState.newFarm(NOW).slimes[1])
		local fixed = repaired.slimes[2]
		T.eq(fixed.id, "slime-2")
		T.same(fixed.stats, { attack = 1, defence = 1, speed = 1, hp = 10 })
		T.same(fixed.colourGenotype, { alleles = { "navy", "navy" } })
		T.eq(fixed.visibleColour, "navy")
		T.same(fixed.needs, { hunger = 100, hungerState = "full" })
		T.ok(#warnings >= 5)
		T.eq(#repaired.items, 9, "unrelated blocks are untouched")
	end)

	T.test("repair recomputes derived values", function()
		local farm = FarmState.newFarm(NOW)
		farm.slimes[1].colourGenotype = { alleles = { "white", "black" } }
		farm.slimes[1].visibleColour = "black"
		farm.slimes[2].needs = { hunger = 20, hungerState = "full" }
		farm.slimes[3].needs = { hunger = -5, hungerState = "full" }
		farm.upgrades.foodStorage = 2
		farm.food = { basicFood = 9999, capacity = 100 }
		farm.eggs = {
			{
				id = "e1",
				parentIds = { "slime-1", "slime-2" },
				createdAt = NOW - 10,
				hatchAt = NOW + 50,
				offspringId = "b1",
				embryo = {
					stats = { attack = 1, defence = 1, speed = 1, hp = 10 },
					colourGenotype = { alleles = { "red", "red" } },
					appearanceMutation = { type = "none" },
				},
				status = "ready",
			},
		}
		local r = FarmState.repair(farm, NOW)
		T.eq(r.slimes[1].visibleColour, "white")
		T.eq(r.slimes[2].needs.hungerState, "hungry")
		T.same(r.slimes[3].needs, { hunger = 0, hungerState = "starving" })
		T.same(r.food, { basicFood = 300, capacity = 300 })
		T.eq(r.eggs[1].status, "incubating", "egg status is never trusted from the save")
		T.eq(FarmState.repair(farm, NOW + 50).eggs[1].status, "ready")
	end)

	T.test("repair drops only the broken egg and never extends a timer", function()
		local farm = FarmState.newFarm(NOW)
		local good = {
			id = "ok",
			parentIds = { "a", "b" },
			createdAt = NOW,
			hatchAt = NOW - 100,
			offspringId = "kid",
			embryo = {
				stats = { attack = 2.4, defence = 1, speed = 1, hp = 10 },
				colourGenotype = { alleles = { "pink", "pink" } },
				appearanceMutation = { type = "secret", definitionId = "secret-future" },
			},
		}
		farm.eggs = {
			good,
			{ id = "noembryo", parentIds = { "a", "b" }, createdAt = NOW, hatchAt = NOW, offspringId = "k2" },
			{ id = "noparents", createdAt = NOW, hatchAt = NOW, offspringId = "k3", embryo = good.embryo },
			"junk",
			table.clone(good),
		}
		local r = FarmState.repair(farm, NOW)
		T.eq(#r.eggs, 1)
		local e = r.eggs[1]
		T.eq(e.id, "ok")
		T.eq(e.hatchAt, NOW, "hatchAt before createdAt becomes createdAt")
		T.eq(e.embryo.stats.attack, 2)
		T.same(e.embryo.appearanceMutation, { type = "secret", definitionId = "secret-future" }, "unknown ids kept")
		T.eq(#r.slimes, 4)
	end)

	T.test(
		"repair keeps material appearances (known or not) on slimes and eggs, and old saves get a material bucket",
		function()
			local farm = FarmState.newFarm(NOW)
			farm.slimes[1].appearanceMutation = { type = "material", definitionId = "gold" }
			farm.slimes[2].appearanceMutation = { type = "material", definitionId = "unobtainium" }
			farm.slimes[3].appearanceMutation = { type = "dual", definitionId = "dual-green-white-01" }
			farm.slimes[4].appearanceMutation = { type = "material" }
			farm.eggs = {
				{
					id = "e1",
					parentIds = { "slime-1", "slime-2" },
					createdAt = NOW - 10,
					hatchAt = NOW + 50,
					offspringId = "b1",
					embryo = {
						stats = { attack = 1, defence = 1, speed = 1, hp = 10 },
						colourGenotype = { alleles = { "red", "red" } },
						appearanceMutation = { type = "material", definitionId = "jelly" },
					},
					status = "incubating",
				},
			}
			farm.discoveries.material = {
				gold = { firstDiscoveredAt = NOW, hatchCount = 2 },
				junk = { hatchCount = 0 },
			}
			local r, warnings = FarmState.repair(farm, NOW)
			T.same(r.slimes[1].appearanceMutation, { type = "material", definitionId = "gold" })
			T.same(r.slimes[2].appearanceMutation, { type = "material", definitionId = "unobtainium" }, "unknown kept")
			T.same(
				r.slimes[3].appearanceMutation,
				{ type = "dual", definitionId = "dual-green-white-01" },
				"old dual ids kept"
			)
			T.same(r.slimes[4].appearanceMutation, { type = "none" }, "a material with no id is malformed")
			T.same(r.eggs[1].embryo.appearanceMutation, { type = "material", definitionId = "jelly" })
			T.same(r.discoveries.material, { gold = { firstDiscoveredAt = NOW, hatchCount = 2 } })
			T.ok(#warnings > 0)
			-- an old save without the bucket
			local old = FarmState.newFarm(NOW)
			old.discoveries.material = nil
			local fixed = FarmState.repair(old, NOW)
			T.same(fixed.discoveries.material, {})
			T.same(fixed.discoveries.base, { navy = { firstDiscoveredAt = NOW, hatchCount = 4 } })
		end
	)

	T.test("repair never wipes the farm for one bad block", function()
		local farm = FarmState.newFarm(NOW)
		farm.coins = 1234.7
		farm.upgrades = { slimeStorage = 3, incubationSpeed = "x", growthSpeed = -1 }
		farm.discoveries = {
			base = { navy = { firstDiscoveredAt = NOW, hatchCount = 4 }, red = { hatchCount = 0 } },
			dual = "junk",
		}
		farm.eggs = "junk"
		farm.workstations = "junk"
		farm.items = 5
		farm.avatar = "junk"
		farm.lifetime = nil
		farm.tutorialDone = nil
		farm.tutorialDoneAt = NOW - 5
		local r, warnings = FarmState.repair(farm, NOW)
		T.eq(#r.slimes, 4)
		T.eq(r.coins, 1234)
		T.eq(r.upgrades.slimeStorage, 3)
		T.eq(r.upgrades.incubationSpeed, 0)
		T.eq(r.upgrades.growthSpeed, 0)
		T.same(r.discoveries, {
			base = { navy = { firstDiscoveredAt = NOW, hatchCount = 4 } },
			dual = {},
			secret = {},
			material = {},
		})
		T.same(r.eggs, {})
		T.eq(#r.workstations, 4)
		T.same(r.items, {})
		T.eq(r.avatar.name, "You")
		T.eq(r.lifetime.bestSlimeLevel, 4)
		T.eq(r.lifetime.coinsEarned, 1234)
		T.eq(r.tutorialDone, nil, "a legacy save stays tour-done")
		T.eq(r.tutorialDoneAt, NOW - 5)
		T.ok(#warnings > 0)
	end)

	T.test("repair starts over only when no slime is usable", function()
		local fresh, w1 = FarmState.repair("junk", NOW)
		T.same(fresh, FarmState.newFarm(NOW))
		T.eq(#w1, 1)
		local empty = FarmState.repair({ slimes = { { name = "no id" } }, coins = 50 }, NOW)
		T.eq(empty.coins, 0)
		T.eq(#empty.slimes, 4)
	end)

	T.test("repair: gear, stations, nest and battle fields", function()
		local farm = FarmState.newFarm(NOW)
		farm.slimes[1].loadout = { hand = "item-sword-1", head = "item-gone" }
		farm.slimes[2].loadout = { hand = "item-sword-1" }
		farm.items[2].ownership = { kind = "EQUIPPED_TO_SLIME", slimeId = "slime-3", slot = "hand" }
		farm.items[3].ownership = { kind = "BATTLE_ESCROW" }
		table.insert(farm.items, { id = "old", definitionId = "sword-2", ownership = { kind = "INVENTORY" } })
		farm.workstations[1].assignedSlimeIds = { "slime-1", "ghost", "slime-1" }
		farm.workstations[2].definitionId = "ws.unknown"
		farm.unlockedStations = { "ws.farm-plot", "ws.nope" }
		farm.nest = { nestId = "main", enabled = true, specialty = "atk", memberSlimeIds = { "slime-2", "ghost" } }
		farm.lastSiegeTeam = { "slime-1", "ghost" }
		farm.materials = { crown_shard = 1, bad = -1 }
		local r = FarmState.repair(farm, NOW)
		T.same(r.slimes[1].loadout, { hand = "item-sword-1" })
		T.same(r.slimes[2].loadout, {}, "an item claimed twice stays with the first slime")
		T.same(r.items[1].ownership, { kind = "EQUIPPED_TO_SLIME", slimeId = "slime-1", slot = "hand" })
		T.same(r.items[2].ownership, { kind = "INVENTORY" })
		T.same(r.items[3].ownership, { kind = "INVENTORY" })
		T.eq(#r.items, 9, "retired gear removed")
		T.same(r.workstations[1].assignedSlimeIds, { "slime-1" })
		T.eq(#r.workstations, 3)
		T.same(r.unlockedStations, { "ws.berry-bush", "ws.farm-plot" })
		T.same(r.nest, {
			nestId = "main",
			enabled = true,
			specialty = "atk",
			memberSlimeIds = { "slime-2" },
		})
		T.same(r.lastSiegeTeam, { "slime-1" })
		T.same(r.materials, { crown_shard = 1 })
		T.eq(r.wbKingSlain, true, "crown shards prove a King kill")
	end)

	T.test("repair caps only absurd slime arrays", function()
		local farm = FarmState.newFarm(NOW)
		farm.slimes = FarmKit.many(600)
		local r = FarmState.repair(farm, NOW)
		T.eq(#r.slimes, 500)
		local small = FarmState.newFarm(NOW)
		small.slimes = FarmKit.many(60)
		T.eq(#FarmState.repair(small, NOW).slimes, 60, "slimes beyond the slot limit are never dropped on load")
	end)

	T.test("derived helpers", function()
		T.eq(FarmState.hungerState(100), "full")
		T.eq(FarmState.hungerState(36), "full")
		T.eq(FarmState.hungerState(35), "hungry")
		T.eq(FarmState.hungerState(0.1), "hungry")
		T.eq(FarmState.hungerState(0), "starving")
		T.eq(FarmState.dayKey(1793059200), "2026-10-27")
		T.eq(FarmState.dayKey(1793059200 - 1), "2026-10-26")
		local u = FarmState.emptyUpgrades()
		u.foodStorage = 20
		T.eq(FarmState.foodCapacity(u), 2100)
	end)
end
