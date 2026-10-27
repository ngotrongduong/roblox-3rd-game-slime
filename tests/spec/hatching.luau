local Breeding = require("../../src/shared/Breeding")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Growth = require("../../src/shared/Growth")
local Hatching = require("../../src/shared/Hatching")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")

local NOW = 2000000

-- A farm (tour done) with one egg laid by slime-1 x slime-2 at NOW.
local function farmWithEgg(seed: number?)
	local farm = FarmKit.farm(NOW)
	local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(seed or 1), FarmKit.ids())
	assert(res.ok and res.egg)
	return res.farm, res.egg
end

-- An egg with a chosen embryo, ready at NOW.
local function egg(id: string, appearance: any, colours: { string }?)
	local c = colours or { "red", "white" }
	return {
		id = id,
		parentIds = { "slime-1", "slime-2" },
		createdAt = NOW - 60,
		hatchAt = NOW,
		offspringId = "baby-" .. id,
		embryo = {
			stats = { attack = 4, defence = 2, speed = 1, hp = 30 },
			colourGenotype = { alleles = { c[1], c[2] } },
			patternGenotype = { alleles = { "solid", "duochrome" } },
			appearanceMutation = appearance or { type = "none" },
		},
		status = "ready",
	}
end

return function(T)
	T.test("not ready before hatchAt; a missing egg is reported", function()
		local farm, e = farmWithEgg()
		local early = Hatching.hatch(farm, e.id, e.hatchAt - 0.5)
		T.eq(early.ok, false)
		T.eq(early.reason, "NOT_READY")
		T.eq(early.farm, farm)
		T.eq(Hatching.hatch(farm, "egg-nope", NOW + 100).reason, "MISSING_EGG")
	end)

	T.test("hatching makes exactly the embryo, and only once", function()
		local farm, e = farmWithEgg(7)
		local embryo = e.embryo
		local res = Hatching.hatch(farm, e.id, e.hatchAt)
		T.ok(res.ok)
		local baby = res.slime
		assert(baby)
		T.eq(baby.id, e.offspringId)
		T.eq(baby.name, "Slime 5")
		T.same(baby.stats, embryo.stats)
		T.same(baby.colourGenotype, embryo.colourGenotype)
		T.same(baby.patternGenotype, embryo.patternGenotype)
		T.same(baby.appearanceMutation, embryo.appearanceMutation)
		T.eq(baby.createdAt, e.hatchAt)
		T.eq(baby.breedReadyAt, e.hatchAt)
		T.eq(baby.needs.hunger, 100)
		T.eq(baby.seed, Rng.hash(baby.id))
		T.ok(Growth.isBaby(baby.createdAt, e.hatchAt + 1, Stats.level(baby.stats), 0), "a hatchling is a baby")
		local after = res.farm
		T.eq(#after.eggs, 0)
		T.eq(#after.slimes, 5)
		T.eq(#farm.slimes, 4, "the input farm is not changed")
		T.eq(#farm.eggs, 1)
		-- a second call is refused and adds nothing
		local again = Hatching.hatch(after, e.id, e.hatchAt + 10)
		T.eq(again.reason, "MISSING_EGG")
		T.eq(#again.farm.slimes, 5)
	end)

	T.test("the embryo is never rerolled: hatching any time later gives the same baby", function()
		local farm, e = farmWithEgg(99)
		local a = Hatching.hatch(farm, e.id, e.hatchAt)
		local b = Hatching.hatch(farm, e.id, e.hatchAt + 5000)
		assert(a.slime and b.slime)
		T.same(a.slime.stats, b.slime.stats)
		T.same(a.slime.colourGenotype, b.slime.colourGenotype)
		T.same(a.slime.appearanceMutation, b.slime.appearanceMutation)
	end)

	T.test("visible colour, asset and appearance", function()
		local farm = FarmKit.farm(NOW)
		farm.eggs = {
			egg("e1", { type = "dual", definitionId = "dual-pink-red-03" }),
			egg("e2", { type = "secret", definitionId = "secret-red-white" }),
			egg("e3", nil, { "white", "black" }),
		}
		local r1 = Hatching.hatch(farm, "e1", NOW)
		assert(r1.slime)
		T.eq(r1.slime.visibleColour, "red", "the base colour stays the phenotype")
		T.eq(r1.slime.assetId, "slime.dual.03")
		local r2 = Hatching.hatch(r1.farm, "e2", NOW)
		assert(r2.slime)
		T.eq(r2.slime.assetId, "slime.secret.red-white")
		local r3 = Hatching.hatch(r2.farm, "e3", NOW)
		assert(r3.slime)
		T.eq(r3.slime.visibleColour, "black")
		T.eq(r3.slime.assetId, "slime.base.black")
	end)

	T.test("discoveries: base always counts, dual/secret register once then count", function()
		local farm = FarmKit.farm(NOW)
		local dual = { type = "dual", definitionId = "dual-pink-red-03" }
		farm.eggs = { egg("e1", dual), egg("e2", dual), egg("e3", nil, { "navy", "navy" }) }
		local r1 = Hatching.hatch(farm, "e1", NOW)
		T.same(r1.firstDiscovery, dual)
		T.ok(r1.newColour, "red is new")
		T.same(r1.farm.discoveries.dual["dual-pink-red-03"], { firstDiscoveredAt = NOW, hatchCount = 1 })
		T.same(r1.farm.discoveries.base.red, { firstDiscoveredAt = NOW, hatchCount = 1 })
		local r2 = Hatching.hatch(r1.farm, "e2", NOW + 9)
		T.eq(r2.firstDiscovery, nil)
		T.ok(not r2.newColour)
		T.same(r2.farm.discoveries.dual["dual-pink-red-03"], { firstDiscoveredAt = NOW, hatchCount = 2 })
		T.eq(r2.farm.discoveries.base.red.hatchCount, 2)
		local r3 = Hatching.hatch(r2.farm, "e3", NOW)
		T.eq(r3.farm.discoveries.base.navy.hatchCount, 5, "4 starters + 1")
		T.eq(farm.discoveries.base.navy.hatchCount, 4, "the input discoveries are not changed")
	end)

	T.test("best level and improved stats", function()
		local farm = FarmKit.farm(NOW)
		farm.eggs = { egg("e1") }
		local res = Hatching.hatch(farm, "e1", NOW)
		-- 4 + 2 + 1 + 30/10 = 10
		T.eq(res.farm.lifetime.bestSlimeLevel, 10)
		T.same(res.improvedStats, { "attack", "defence", "hp" })
		-- a sold parent means no icons, never a crash
		local orphan = FarmKit.farm(NOW, { FarmKit.slime("x") })
		orphan.eggs = { egg("e2") }
		T.same(Hatching.hatch(orphan, "e2", NOW).improvedStats, {})
	end)

	T.test("baby names continue the highest Slime N", function()
		local farm = FarmKit.farm(NOW, {
			FarmKit.slime("a", { name = "Slime 7" }),
			FarmKit.slime("b", { name = "Bob" }),
			FarmKit.slime("c", { name = "Slime 3" }),
			FarmKit.slime("d", { name = "Slime 12x" }),
		})
		T.eq(Hatching.nextName(farm), "Slime 8")
		T.eq(Hatching.nextName(FarmKit.farm(NOW, {})), "Slime 1")
	end)

	T.test("the next egg to auto-hatch is the oldest ready one", function()
		local farm = FarmKit.farm(NOW)
		local a, b, c = egg("a"), egg("b"), egg("c")
		a.createdAt, a.hatchAt = NOW - 10, NOW + 50
		b.createdAt, b.hatchAt = NOW - 30, NOW - 1
		c.createdAt, c.hatchAt = NOW - 40, NOW - 5
		farm.eggs = { a, b, c }
		T.eq(Hatching.nextReadyEgg(farm, NOW), c)
		farm.eggs = { a }
		T.eq(Hatching.nextReadyEgg(farm, NOW), nil)
	end)

	T.test("avatar rank: one per 50 hatches over all books", function()
		local d = FarmState.emptyDiscoveries()
		d.base.navy = { firstDiscoveredAt = 0, hatchCount = 4 }
		T.eq(Hatching.totalHatched(d), 4)
		T.eq(Hatching.avatarRank(d), 1)
		d.base.red = { firstDiscoveredAt = 0, hatchCount = 44 }
		d.dual.x = { firstDiscoveredAt = 0, hatchCount = 1 }
		T.eq(Hatching.avatarRank(d), 1)
		local farm = FarmKit.farm(NOW)
		farm.discoveries = d
		farm.eggs = { egg("e1") }
		local res = Hatching.hatch(farm, "e1", NOW)
		T.ok(res.rankUp)
		T.eq(Hatching.avatarRank(res.farm.discoveries), 2)
	end)
end
