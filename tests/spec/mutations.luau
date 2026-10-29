local Config = require("../../src/shared/Config")
local Genetics = require("../../src/shared/Genetics")
local Materials = require("../../src/shared/Materials")
local Mutations = require("../../src/shared/Mutations")
local Rng = require("../../src/shared/Rng")

local function plain(colour)
	return { colourGenotype = Genetics.homozygous(colour), appearanceMutation = Mutations.none() }
end

return function(T)
	T.test("one category roll followed by a uniform pool pick", function()
		local a, b = plain("navy"), plain("red")
		local secret = Mutations.resolveOffspring(a, b, Rng.sequence({ 0.005, 0.5 }), 1)
		T.same(secret.appearance, { type = "secret", definitionId = "secret-navy-red" })
		T.same(secret.colourGenotype.alleles, { "red", "navy" })
		local dual = Mutations.resolveOffspring(a, b, Rng.sequence({ 0.02, 0 }), 1)
		T.same(dual.appearance, { type = "dual", definitionId = "dual-navy-red-21" })
		T.same(dual.colourGenotype.alleles, { "navy", "red" })
		local ordinary = Mutations.resolveOffspring(a, b, Rng.sequence({ 0.5, 0.99, 0.99 }), 1)
		T.eq(ordinary.rolled, "plain")
		T.same(ordinary.appearance, Mutations.none())
		T.same(ordinary.colourGenotype, Genetics.homozygous("red"))
		local random = Mutations.resolveOffspring(a, b, Rng.sequence({ 0.95, 0 }), 1)
		T.eq(random.rolled, "random")
		T.same(random.appearance, Mutations.none())
		T.same(random.colourGenotype, Genetics.homozygous("black"))
	end)

	T.test("material is a separate Plain-only roll with the existing tier weights", function()
		local a, b = plain("white"), plain("black")
		for _, row in { { 0, "gold" }, { 1.5 / 80, "silver" }, { 0.9999, "leather" } } do
			local out = Mutations.resolveOffspring(a, b, Rng.sequence({ 0.5, 0.99, 0, row[1] }), 1)
			T.eq(out.rolled, "plain")
			T.same(out.appearance, { type = "material", definitionId = row[2] })
			T.same(out.colourGenotype, Genetics.homozygous("white"))
		end
		T.near(Mutations.chances(a, b, 5).material, Config.Mutation.MaterialChance * 5, 1e-12)
		T.eq(Mutations.chances(a, b, 1000).material, Config.Mutation.ChanceCap)
		local rng = Rng.new(909)
		local counts = {}
		for _ = 1, 40000 do
			local m = rng:weighted(Materials.List, Materials.weight)
			counts[m.id] = (counts[m.id] or 0) + 1
		end
		T.near(counts.wood / 40000, 6 / 80, 0.006)
		T.near(counts.glass / 40000, 3 / 80, 0.005)
		T.near(counts.gold / 40000, 1 / 80, 0.003)
	end)

	T.test("pity uses the full pools, rewrites genes and never converts a material", function()
		local a, b = plain("red"), plain("pink")
		local ordinary = Mutations.resolveOffspring(a, b, Rng.sequence({ 0.5, 0, 0.99 }), 1)
		local forced = Mutations.applyPity(ordinary, a, a, Rng.new(1))
		T.same(forced.appearance, { type = "secret", definitionId = "secret-red-red" })
		T.same(forced.colourGenotype, Genetics.homozygous("red"))
		local rng, secrets, seen = Rng.new(404), 0, {}
		for _ = 1, 10000 do
			local out = Mutations.applyPity(ordinary, a, b, rng)
			T.eq(out.rolled, "pity")
			T.same(out.colourGenotype, Genetics.fromAppearance(out.appearance, ordinary.colourGenotype))
			if out.appearance.type == "secret" then
				secrets += 1
				seen[out.appearance.definitionId] = true
			else
				T.eq(out.appearance.type, "dual")
				T.eq(out.appearance.definitionId, "dual-red-pink-38")
			end
		end
		T.near(secrets / 10000, Config.Mutation.PitySecretShare, 0.012)
		T.ok(seen["secret-pink-pink"] and seen["secret-pink-red"] and seen["secret-red-red"])
		local material = Mutations.resolveOffspring(a, b, Rng.sequence({ 0.5, 0, 0, 0 }), 1)
		T.eq(Mutations.applyPity(material, a, b, Rng.new(1)), material)
		T.same(ordinary.appearance, Mutations.none(), "pity does not change its input")
	end)

	T.test("same seed yields the same offspring without changing either parent", function()
		local a, b = plain("purple"), plain("pink")
		local one, two = Rng.new(55), Rng.new(55)
		for _ = 1, 200 do
			T.same(Mutations.resolveOffspring(a, b, one, 3), Mutations.resolveOffspring(a, b, two, 3))
		end
		T.same(a, plain("purple"))
		T.same(b, plain("pink"))
	end)

	T.test("appearance asset: secret > material > dual > base; unknown ids are kept but show the base", function()
		T.eq(
			Mutations.assetId({ type = "secret", definitionId = "secret-navy-navy" }, "navy"),
			"slime.secret.navy-navy"
		)
		T.eq(Mutations.assetId({ type = "dual", definitionId = "dual-red-pink-38" }, "pink"), "slime.dual.38")
		T.eq(Mutations.assetId({ type = "material", definitionId = "gold" }, "red"), "slime.material.gold")
		T.eq(Mutations.assetId({ type = "none" }, "red"), "slime.base.red")
		T.eq(Mutations.assetId({ type = "dual", definitionId = "dual-future-99" }, "red"), "slime.base.red")
		T.eq(Mutations.assetId({ type = "dual", definitionId = "dual-green-white-01" }, "red"), "slime.base.red")
		T.eq(Mutations.assetId({ type = "material", definitionId = "unobtainium" }, "red"), "slime.base.red")
		T.same(Mutations.validate({ type = "dual", definitionId = "dual-future-99" }), {
			type = "dual",
			definitionId = "dual-future-99",
		})
		T.same(Mutations.validate({ type = "material", definitionId = "unobtainium" }), {
			type = "material",
			definitionId = "unobtainium",
		})
		T.same(Mutations.validate({ type = "material", definitionId = "gold", junk = 1 }), {
			type = "material",
			definitionId = "gold",
		})
		T.ok(not Mutations.isKnown({ type = "dual", definitionId = "dual-future-99" }))
		T.ok(not Mutations.isKnown({ type = "material", definitionId = "unobtainium" }))
		T.ok(Mutations.isKnown({ type = "material", definitionId = "gold" }))
		T.same(Mutations.validate({ type = "secret" }), { type = "none" })
		T.same(Mutations.validate({ type = "material" }), { type = "none" })
		T.same(Mutations.validate("junk"), { type = "none" })
		T.eq(Mutations.rarity({ type = "secret", definitionId = "x" }), "secret")
		T.eq(Mutations.rarity({ type = "material", definitionId = "gold" }), "material")
		T.eq(Mutations.rarity({ type = "none" }), "base")
	end)

	T.test("selling: base by kind and material tier, times the level factor; rare kinds ask first", function()
		local none = { type = "none" }
		local dual = { type = "dual", definitionId = "dual-red-pink-38" }
		local secret = { type = "secret", definitionId = "secret-navy-navy" }
		T.eq(Mutations.sellValue(none, 4), 12)
		T.eq(Mutations.sellValue(dual, 4), 120)
		T.eq(Mutations.sellValue(secret, 4), 1200)
		T.eq(Mutations.sellValue({ type = "material", definitionId = "wood" }, 4), 180, "common 150")
		T.eq(Mutations.sellValue({ type = "material", definitionId = "glass" }, 4), 360, "rare 300")
		T.eq(Mutations.sellValue({ type = "material", definitionId = "gold" }, 4), 960, "precious 800")
		T.eq(Mutations.sellValue({ type = "material", definitionId = "gold" }, 100), 4800)
		T.eq(Mutations.sellValue({ type = "material", definitionId = "unobtainium" }, 4), 180, "unknown = common")
		T.eq(Mutations.sellBase({ type = "material", definitionId = "silver" }), 800)
		T.ok(Mutations.needsSellConfirm(dual))
		T.ok(Mutations.needsSellConfirm(secret))
		T.ok(Mutations.needsSellConfirm({ type = "material", definitionId = "mud" }))
		T.ok(not Mutations.needsSellConfirm(none))
	end)
end
