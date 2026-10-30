local Breeding = require("../../src/shared/Breeding")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")

local NOW = 1000000

return function(T)
	T.test("incubation waits for the incubator and scales by baby and breeding levels", function()
		T.eq(Breeding.incubationSeconds(4, 1), 60)
		T.eq(Breeding.incubationSeconds(5, 1), 61)
		T.eq(Breeding.incubationSeconds(9, 1), 65)
		T.eq(Breeding.incubationSeconds(4, 50), math.round(60 * 0.98 ^ 49))
	end)

	T.test("parent cooldown: 63 s for starters, x0.95 per level, capped at level 20", function()
		T.eq(Breeding.cooldownSeconds(4, 0), 63)
		T.eq(Breeding.cooldownSeconds(1, 0), 60)
		T.eq(Breeding.cooldownSeconds(30, 0), 89)
		-- round(63000 * 0.95) = 59850 ms
		T.near(Breeding.cooldownSeconds(4, 1), 59.85, 1e-9)
		-- round(63000 * 0.95^20) = 22585 ms
		T.near(Breeding.cooldownSeconds(4, 20), 22.585, 1e-9)
		T.eq(Breeding.cooldownSeconds(4, 25), Breeding.cooldownSeconds(4, 20))
	end)

	T.test("eligibility validates parents, ghosts, growth, cooldown, nest and population", function()
		local farm = FarmKit.farm(NOW)
		T.eq(Breeding.check(farm, "missing", "missing", NOW).reason, "SAME_PARENT")
		T.eq(Breeding.check(farm, "slime-1", "missing", NOW).reason, "MISSING_PARENT")
		farm.slimes[1].stats.attack = 0
		T.eq(Breeding.check(farm, "slime-1", "slime-2", NOW).reason, "INVALID_PARENT_DATA")
		farm.slimes[1].stats.attack = 1
		farm.slimes[1].ghostUntil = NOW + 1
		T.eq(Breeding.check(farm, "slime-1", "slime-2", NOW).reason, "PARENT_FALLEN")
		farm.slimes[1].ghostUntil = nil
		farm.slimes[1].createdAt = NOW
		T.eq(Breeding.check(farm, "slime-1", "slime-2", NOW).reason, "PARENT_TOO_YOUNG")
		farm.slimes[1].createdAt = NOW - 400
		farm.slimes[1].breedReadyAt = NOW + 20
		T.eq(Breeding.check(farm, "slime-1", "slime-2", NOW).reason, "PARENT_ON_COOLDOWN")
		farm.slimes[1].breedReadyAt = 0
		local full = FarmKit.farm(NOW, FarmKit.many(FarmState.populationLimit(FarmState.newAreas())))
		T.eq(Breeding.check(full, "s1", "s2", NOW).reason, "SLIME_CAP_REACHED")
		local one = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(2), FarmKit.ids())
		assert(one.ok)
		local two = Breeding.createEgg(one.farm, "slime-3", "slime-4", NOW, Rng.new(2), FarmKit.ids())
		assert(two.ok)
		T.eq(Breeding.check(two.farm, "slime-1", "slime-3", NOW + 100).reason, "EGG_CAP_REACHED")
	end)

	T.test("reason codes carry the player texts", function()
		local r = Breeding.check(FarmKit.farm(NOW), "slime-1", "slime-1", NOW)
		T.eq(r.ok, false)
		T.eq(r.message, "A slime cannot breed with itself.")
		T.eq(Breeding.Messages.MISSING_PARENT, "Pick two different slimes.")
		T.eq(Breeding.Messages.PARENT_TOO_YOUNG, "A parent is still growing up.")
		T.eq(Breeding.Messages.PARENT_ON_COOLDOWN, "One parent is still resting.")
		T.eq(Breeding.Messages.SLIME_CAP_REACHED, "The farm is full — no room for a baby.")
		T.eq(Breeding.Messages.EGG_CAP_REACHED, "The nest is full.")
		T.ok(Breeding.Messages.PARENT_FALLEN ~= nil)
	end)

	T.test("eggs reserve population spaces as village levels grow", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(11))
		table.insert(farm.eggs, { id = "e1", place = "incubator", slot = 1 })
		T.eq(Breeding.check(farm, "s1", "s2", NOW).reason, "SLIME_CAP_REACHED")
		T.eq(FarmState.populationLimit(farm.areas), 12)
		for _, id in { "fishing", "garden", "kitchen", "pantry", "training", "breeding" } do
			farm.areas[id].level = 2
		end
		T.eq(FarmState.populationLimit(farm.areas), 13)
		T.ok(Breeding.check(farm, "s1", "s2", NOW).ok)
	end)

	T.test("starters can breed on a fresh farm", function()
		local farm = FarmState.newFarm(NOW)
		T.ok(Breeding.check(farm, "slime-1", "slime-2", NOW).ok)
	end)

	T.test("stat inheritance: each stat between the parents, at most one improved beyond", function()
		local a = { attack = 5, defence = 1, speed = 10, hp = 100 }
		local b = { attack = 1, defence = 9, speed = 10, hp = 200 }
		local rng = Rng.new(21)
		local improved = 0
		for _ = 1, 5000 do
			local s = Breeding.inheritStats(a, b, rng, 1)
			local beyond = Breeding.improvedStats(s, a, b)
			T.ok(#beyond <= 1, "more than one stat improved")
			if #beyond == 1 then
				improved += 1
				local key = beyond[1]
				local best = math.max(Stats.get(a, key), Stats.get(b, key))
				local bonus = Stats.get(s, key) - best
				if key == "hp" then
					T.ok(bonus >= 10 and bonus <= 30, "hp bonus " .. bonus)
				else
					T.ok(bonus >= 1 and bonus <= 3, key .. " bonus " .. bonus)
				end
			end
			for _, key in Stats.Keys do
				local v = Stats.get(s, key)
				T.eq(v, math.floor(v), "integer")
				if not table.find(beyond, key) then
					local lo = math.min(Stats.get(a, key), Stats.get(b, key))
					T.ok(v >= lo, key .. " below the weaker parent")
					T.ok(v <= math.max(Stats.get(a, key), Stats.get(b, key)), key .. " above range")
				end
			end
		end
		-- the improvement (bonus >= 1, no limit in reach) always beats both parents: 10% of eggs
		T.near(improved / 5000, 0.10, 0.015)
	end)

	T.test("stat improvement chance scales with luck and caps at 0.95", function()
		local a = Stats.starter()
		local function rate(luck: number)
			local rng = Rng.new(99)
			local n = 0
			for _ = 1, 4000 do
				if #Breeding.improvedStats(Breeding.inheritStats(a, a, rng, luck), a, a) > 0 then
					n += 1
				end
			end
			return n / 4000
		end
		T.near(rate(5), 0.5, 0.03)
		T.near(rate(50), 0.95, 0.015)
	end)

	T.test("stats never pass the limits", function()
		local top = { attack = 99, defence = 99, speed = 99, hp = 9990 }
		local rng = Rng.new(5)
		for _ = 1, 500 do
			T.same(Breeding.inheritStats(top, top, rng, 100), top)
		end
	end)

	T.test("createEgg: an egg with a decided embryo, parents rest, counters move", function()
		local farm = FarmKit.farm(NOW)
		local before = FarmState.newFarm(NOW)
		before.tutorialDone = true
		local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		T.ok(res.ok)
		local egg = res.egg
		assert(egg)
		T.eq(egg.id, "egg-id1")
		T.eq(egg.offspringId, "slime-id2")
		T.same(egg.parentIds, { "slime-1", "slime-2" })
		T.eq(egg.createdAt, NOW)
		T.eq(egg.hatchAt, NOW + Breeding.nestSeconds(egg, 1), "the nest clock starts at laying")
		T.eq(egg.status, "nest")
		T.ok(egg.embryo.stats and egg.embryo.colourGenotype)
		T.eq(res.parentsReadyAt, NOW + 63)
		local after = res.farm
		T.eq(#after.eggs, 1)
		T.eq(after.slimes[1].breedReadyAt, NOW + 63)
		T.eq(after.slimes[2].breedReadyAt, NOW + 63)
		T.eq(after.slimes[3].breedReadyAt, 0)
		T.eq(after.lifetime.breeds, 1)
		T.eq(after.breedsSinceMutation, if egg.embryo.appearanceMutation.type == "none" then 1 else 0)
		T.same(farm, before, "the input farm is not changed")
		-- the parents now rest
		T.eq(Breeding.check(after, "slime-1", "slime-3", NOW + 10).reason, "PARENT_ON_COOLDOWN")
		T.ok(Breeding.check(after, "slime-1", "slime-3", NOW + 63).ok)
	end)

	T.test("createEgg failures return the reason and the unchanged farm", function()
		local farm = FarmKit.farm(NOW)
		local res = Breeding.createEgg(farm, "slime-1", "nope", NOW, Rng.new(1), FarmKit.ids())
		T.eq(res.ok, false)
		T.eq(res.reason, "MISSING_PARENT")
		T.eq(res.farm, farm)
		local clash = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), function()
			return "slime-1"
		end)
		T.eq(clash.reason, "ID_UNAVAILABLE")
	end)

	T.test("breeding level shortens cooldown; eggs remain unincubated in nests", function()
		local farm = FarmKit.farm(NOW)
		farm.areas.breeding.level = 21
		local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		assert(res.egg)
		T.eq(res.egg.place, "nest")
		T.ok((res.egg.hatchAt :: number) > NOW, "the nest clock starts at laying")
		T.near(res.parentsReadyAt :: number, NOW + Breeding.cooldownSeconds(4, 20), 1e-6)
	end)

	T.test("the same seed lays the same egg", function()
		local p = { colours = { "red", "white" } }
		local q = { colours = { "blue", "green" } }
		local farm = FarmKit.farm(NOW, { FarmKit.slime("a", p), FarmKit.slime("b", q) })
		local one = Breeding.createEgg(farm, "a", "b", NOW, Rng.new(31337), FarmKit.ids())
		local two = Breeding.createEgg(farm, "a", "b", NOW, Rng.new(31337), FarmKit.ids())
		T.same(one.egg, two.egg)
	end)

	T.test("pity: the 25th plain egg in a row is forced rare and resets the counter", function()
		for seed = 1, 60 do
			local farm = FarmKit.farm(NOW, {
				FarmKit.slime("a", { colours = { "red", "red" } }),
				FarmKit.slime("b", { colours = { "pink", "pink" } }),
			})
			farm.breedsSinceMutation = 24
			local res = Breeding.createEgg(farm, "a", "b", NOW, Rng.new(seed), FarmKit.ids())
			assert(res.egg)
			local kind = res.egg.embryo.appearanceMutation.type
			-- a material is only ever the egg's own 2% roll (pity never gives one) and also resets the counter
			T.ok(kind == "dual" or kind == "secret" or kind == "material", "seed " .. seed .. " gave " .. kind)
			if kind == "dual" then
				T.same(res.egg.embryo.colourGenotype.alleles, { "red", "pink" })
			end
			T.eq(res.farm.breedsSinceMutation, 0)
		end
		-- same colour: always the pair's secret
		local same = FarmKit.farm(NOW)
		same.breedsSinceMutation = 30
		local res = Breeding.createEgg(same, "slime-1", "slime-2", NOW, Rng.new(4), FarmKit.ids())
		assert(res.egg)
		T.same(res.egg.embryo.appearanceMutation, { type = "secret", definitionId = "secret-navy-navy" })
	end)

	T.test("pity eggs: material only when the egg rolled it itself, never from the pity", function()
		local natural, forced = 0, 0
		for seed = 1, 400 do
			local farm = FarmKit.farm(NOW, {
				FarmKit.slime("a", { colours = { "red", "red" } }),
				FarmKit.slime("b", { colours = { "pink", "pink" } }),
			})
			farm.breedsSinceMutation = 24
			local res = Breeding.createEgg(farm, "a", "b", NOW, Rng.new(seed), FarmKit.ids())
			assert(res.egg)
			local kind = res.egg.embryo.appearanceMutation.type
			if kind == "material" then
				natural += 1
			else
				-- the pity itself only ever forces a Dual or a Secret
				T.ok(kind == "dual" or kind == "secret", "pity egg came out " .. kind)
				forced += 1
			end
		end
		-- 2% of 400 is about 8: far from a pity share
		T.ok(natural < 30, "materials on pity eggs: " .. natural)
		T.ok(forced > 370, "forced rare pity eggs: " .. forced)
	end)

	T.test("a material slime breeds as its base colour and passes nothing on", function()
		for seed = 1, 60 do
			local plainFarm = FarmKit.farm(NOW, {
				FarmKit.slime("a", { colours = { "red", "red" } }),
				FarmKit.slime("b", { colours = { "pink", "pink" } }),
			})
			local materialFarm = FarmKit.farm(NOW, {
				FarmKit.slime(
					"a",
					{ colours = { "red", "red" }, appearance = { type = "material", definitionId = "gold" } }
				),
				FarmKit.slime(
					"b",
					{ colours = { "pink", "pink" }, appearance = { type = "material", definitionId = "mud" } }
				),
			})
			local one = Breeding.createEgg(plainFarm, "a", "b", NOW, Rng.new(seed), FarmKit.ids())
			local two = Breeding.createEgg(materialFarm, "a", "b", NOW, Rng.new(seed), FarmKit.ids())
			T.same(one.egg, two.egg, "seed " .. seed)
		end
	end)

	T.test("pity does not fire before the 25th egg", function()
		local plain = 0
		for seed = 1, 200 do
			local farm = FarmKit.farm(NOW)
			farm.breedsSinceMutation = 23
			local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(seed), FarmKit.ids())
			assert(res.egg)
			if res.egg.embryo.appearanceMutation.type == "none" then
				plain += 1
				T.eq(res.farm.breedsSinceMutation, 24)
			end
		end
		T.ok(plain > 150, "most eggs stay plain")
	end)

	T.test("tutorial first egg: new homozygous colour and two boosted stats before incubation", function()
		for seed = 1, 40 do
			local farm = FarmState.newFarm(NOW)
			T.ok(Breeding.isTutorialFirstEgg(farm))
			local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(seed), FarmKit.ids())
			assert(res.egg)
			local embryo = res.egg.embryo
			T.ok(res.boosted)
			T.ok((res.egg.hatchAt :: number) > NOW)
			T.eq(embryo.colourGenotype.alleles[1], embryo.colourGenotype.alleles[2])
			T.ok(embryo.colourGenotype.alleles[1] ~= "navy")
			T.same(embryo.appearanceMutation, { type = "none" })
			local starter = Stats.starter()
			T.ok(#Breeding.improvedStats(embryo.stats, starter, starter) >= 2)
			T.eq(res.farm.breedsSinceMutation, 1, "the boosted egg still fills the pity counter")
			-- only the first egg
			local second = Breeding.createEgg(res.farm, "slime-3", "slime-4", NOW, Rng.new(seed), FarmKit.ids())
			T.ok(not second.boosted)
		end
	end)

	T.test("no tutorial boost on legacy saves or once the tour is done", function()
		local farm = FarmState.newFarm(NOW)
		farm.tutorialDone = nil
		T.ok(not Breeding.isTutorialFirstEgg(farm))
		farm.tutorialDone = true
		T.ok(not Breeding.isTutorialFirstEgg(farm))
		local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		T.ok(not res.boosted)
		assert(res.egg)
		T.ok((res.egg.hatchAt :: number) > NOW)
	end)

	T.test("new-player luck raises the rare rate of real eggs", function()
		local function rareRate(doneAt: number?)
			local rare = 0
			local rng = Rng.new(8)
			for _ = 1, 3000 do
				local farm = FarmKit.farm(NOW, {
					FarmKit.slime("a", { colours = { "red", "red" } }),
					FarmKit.slime("b", { colours = { "white", "white" } }),
				})
				farm.tutorialDoneAt = doneAt
				local res = Breeding.createEgg(farm, "a", "b", NOW, rng, FarmKit.ids())
				assert(res.egg)
				if res.egg.embryo.appearanceMutation.type ~= "none" then
					rare += 1
				end
			end
			return rare / 3000
		end
		-- Secret + Dual + Plain times the conditional material chance.
		T.near(rareRate(nil), 0.067, 0.015)
		T.near(rareRate(NOW - 60), 0.315, 0.03)
	end)

	T.test("preview text", function()
		local a = FarmKit.slime("a", { stats = { attack = 3, defence = 1, speed = 2, hp = 40 } })
		local b = FarmKit.slime("b")
		local text = Breeding.previewText(a, b, 24)
		T.ok(string.find(text, "Baby ranges: ATK 1–3 · DEF 1–1 · SPD 1–2 · HP 10–40", 1, true))
		T.ok(string.find(text, "10% chance one stat improves", 1, true))
		T.ok(string.find(text, "A rare discovery may be possible.", 1, true))
		T.ok(string.find(text, "FULL", 1, true))
		T.ok(string.find(Breeding.previewText(a, b, 3), "3/25", 1, true))
	end)
end
