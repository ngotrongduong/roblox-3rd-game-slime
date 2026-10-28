local Colours = require("../../src/shared/Colours")
local Config = require("../../src/shared/Config")
local Genetics = require("../../src/shared/Genetics")
local Materials = require("../../src/shared/Materials")
local Mutations = require("../../src/shared/Mutations")
local Rng = require("../../src/shared/Rng")

local function g(a: string, b: string)
	return { alleles = { a, b } }
end

-- Two homozygous parents of colours a and b, with the given pattern genotypes.
local function parents(a: string, b: string, patternA: any?, patternB: any?)
	return {
		colourA = a,
		colourB = b,
		genotypeA = g(a, a),
		genotypeB = g(b, b),
		patternA = patternA or Genetics.solid(),
		patternB = patternB or Genetics.solid(),
	}
end

-- Share of each outcome over n seeded eggs.
local function rates(p: any, luck: number, n: number, seed: number)
	local rng = Rng.new(seed)
	local counts = { secret = 0, material = 0, dual = 0, base = 0, normal = 0 }
	for _ = 1, n do
		local out = Mutations.resolveOffspring(p, rng, luck)
		counts[out.rolled] += 1
	end
	return {
		secret = counts.secret / n,
		material = counts.material / n,
		dual = counts.dual / n,
		base = counts.base / n,
		normal = counts.normal / n,
	}
end

return function(T)
	T.test(
		"chances: secret 1%, material 2%, dual 5% (cross colours only), base 10%; luck multiplies and caps",
		function()
			local c = Mutations.chances("white", "black", 1)
			T.eq(c.secret, 0.01)
			T.eq(c.material, 0.02)
			T.eq(c.dual, 0.05)
			T.eq(c.base, 0.10)
			T.eq(#c.secrets, 1)
			T.eq(#c.materials, 18)
			T.eq(#c.duals, 1, "a pair has exactly one Dual design")
			local same = Mutations.chances("navy", "navy", 1)
			T.eq(same.dual, 0)
			T.eq(#same.duals, 0)
			T.eq(same.secret, 0.01)
			T.eq(same.material, 0.02, "same colour can give a material")
			local lucky = Mutations.chances("white", "black", 5)
			T.near(lucky.secret, 0.05, 1e-12)
			T.near(lucky.material, 0.10, 1e-12)
			T.near(lucky.dual, 0.25, 1e-12)
			T.eq(lucky.base, 0.10, "luck never touches the base-colour mutation")
			local capped = Mutations.chances("white", "black", 1000)
			T.eq(capped.secret, 0.95)
			T.eq(capped.material, 0.95)
			T.eq(capped.dual, 0.95)
		end
	)

	T.test("a secret roll wins before material, dual and base; only one outcome", function()
		-- colour A, colour B, pattern A, pattern B, secret roll (hits), recipe pick
		local out = Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.005, 0 }), 1)
		T.eq(out.rolled, "secret")
		T.same(out.appearance, { type = "secret", definitionId = "secret-black-white" })
		T.same(out.colourGenotype, g("white", "black"), "a secret keeps the inherited genes")
		T.same(out.patternGenotype, Genetics.solid())
		T.ok(out.hadSecret and out.hadDual)
	end)

	T.test("a material roll comes second, keeps the genes and picks by weight", function()
		-- secret misses, material hits (0.015 < 0.02), then the weighted pick
		local first =
			Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.015, 0 }), 1)
		T.eq(first.rolled, "material")
		T.same(first.appearance, { type = "material", definitionId = "gold" })
		T.same(first.colourGenotype, g("white", "black"), "a material keeps the inherited genes")
		T.same(first.patternGenotype, Genetics.solid(), "and does not make the baby duochrome")
		-- 1.5 / 80 lands in silver (gold 1, silver 1, ...); the last roll lands in the last entry
		local silver =
			Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.0, 1.5 / 80 }), 1)
		T.eq(silver.appearance.definitionId, "silver")
		local last =
			Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.0, 0.9999 }), 1)
		T.eq(last.appearance.definitionId, "leather")
		-- a same-colour pair spends the same rolls on it
		local same = Mutations.resolveOffspring(parents("navy", "navy"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.0, 0 }), 1)
		T.eq(same.rolled, "material")
	end)

	T.test("a dual roll comes third and makes the baby duochrome", function()
		local out =
			Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.01, 0 }), 1)
		T.eq(out.rolled, "dual")
		-- white + black: its one design (10, Moo)
		T.same(out.appearance, { type = "dual", definitionId = "dual-black-white-10" })
		T.same(out.patternGenotype, Genetics.duochrome())
		T.same(out.colourGenotype, g("white", "black"))
	end)

	T.test("a base-colour mutation comes last: a new homozygous colour, no appearance", function()
		local out = Mutations.resolveOffspring(
			parents("white", "black"),
			Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5, 0.05, 0 }),
			1
		)
		T.eq(out.rolled, "base")
		-- the baby's own colour (black) is excluded; the first of the others is gray
		T.same(out.colourGenotype, g("gray", "gray"))
		T.same(out.appearance, { type = "none" })
		T.same(out.patternGenotype, Genetics.solid(), "pattern genes are kept")
	end)

	T.test("a base-colour mutation never keeps the baby's colour", function()
		for _, c in Colours.Ids do
			for pick = 0, 0.95, 0.1 do
				local out =
					Mutations.resolveOffspring(parents(c, c), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.01, pick }), 1)
				T.eq(out.rolled, "base")
				T.ok(out.colourGenotype.alleles[1] ~= c, "mutated to its own colour " .. c)
				T.eq(out.colourGenotype.alleles[1], out.colourGenotype.alleles[2])
			end
		end
	end)

	T.test("plain otherwise", function()
		local out = Mutations.resolveOffspring(
			parents("white", "black"),
			Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5, 0.5, 0.5 }),
			1
		)
		T.eq(out.rolled, "normal")
		T.same(out.appearance, { type = "none" })
		T.same(out.colourGenotype, g("white", "black"))
	end)

	T.test("same-colour parents spend no dual roll", function()
		-- secret, material and base miss: plain, no more rolls
		local out = Mutations.resolveOffspring(parents("navy", "navy"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5 }), 1)
		T.eq(out.rolled, "normal")
		T.ok(out.hadSecret)
		T.ok(not out.hadDual)
	end)

	T.test("carriers: a duochrome/duochrome baby shows its pair's Dual", function()
		local carrier = g("solid", "duochrome")
		-- colours white + green, pattern picks the duochrome allele from both, all rolls miss, pick
		local out = Mutations.resolveOffspring(
			parents("white", "green", carrier, carrier),
			Rng.sequence({ 0, 0, 0.9, 0.9, 0.5, 0.5, 0.5, 0.5, 0.5, 0 }),
			1
		)
		T.eq(out.rolled, "normal")
		T.same(out.appearance, { type = "dual", definitionId = "dual-green-white-52" })
		T.same(out.patternGenotype, Genetics.duochrome())
		-- every different-colour pair has a design, so any duochrome pair shows one
		local duo = Genetics.duochrome()
		local black = Mutations.resolveOffspring(
			parents("white", "black", duo, duo),
			Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5, 0.5, 0.5, 0 }),
			1
		)
		T.same(black.appearance, { type = "dual", definitionId = "dual-black-white-10" })
	end)

	T.test("carriers: identical alleles or a solid parent never show a Dual", function()
		local duo = Genetics.duochrome()
		local same = Mutations.resolveOffspring(
			parents("navy", "navy", duo, duo),
			Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5 }),
			1
		)
		T.same(same.appearance, { type = "none" })
		-- solid x carrier never gives duochrome, so never a carrier Dual
		local rng = Rng.new(17)
		for _ = 1, 2000 do
			local out = Mutations.resolveOffspring(
				parents("white", "green", Genetics.solid(), g("duochrome", "duochrome")),
				rng,
				1
			)
			if out.rolled == "normal" then
				T.same(out.appearance, { type = "none" })
			end
		end
	end)

	T.test("statistics: different colours at luck 1 land near 1% / 1.98% / 4.85% / 9.2%", function()
		local r = rates(parents("white", "black"), 1, 60000, 101)
		T.near(r.secret, 0.01, 0.003, "secret")
		T.near(r.material, 0.0198, 0.004, "material")
		T.near(r.dual, 0.04851, 0.006, "dual")
		T.near(r.base, 0.092169, 0.008, "base")
		T.near(r.normal, 0.829521, 0.012, "normal")
	end)

	T.test("statistics: different colours at luck 5 land near 5% / 9.5% / 21.4% / 6.4%", function()
		local r = rates(parents("red", "yellow"), 5, 60000, 202)
		T.near(r.secret, 0.05, 0.006, "secret")
		T.near(r.material, 0.095, 0.008, "material")
		T.near(r.dual, 0.21375, 0.012, "dual")
		T.near(r.base, 0.064125, 0.007, "base")
	end)

	T.test("statistics: same colour at luck 1 lands near 1% / 1.98% / 0 / 9.7%", function()
		local r = rates(parents("navy", "navy"), 1, 60000, 303)
		T.near(r.secret, 0.01, 0.003, "secret")
		T.near(r.material, 0.0198, 0.004, "material")
		T.eq(r.dual, 0, "dual")
		T.near(r.base, 0.09702, 0.008, "base")
	end)

	T.test("statistics: which material follows the tier weights", function()
		local rng = Rng.new(909)
		local counts: { [string]: number } = {}
		local n = 40000
		for _ = 1, n do
			local m = rng:weighted(Materials.List, Materials.weight)
			counts[m.id] = (counts[m.id] or 0) + 1
		end
		T.near(counts.wood / n, 6 / 80, 0.006)
		T.near(counts.glass / n, 3 / 80, 0.005)
		T.near(counts.gold / n, 1 / 80, 0.003)
		-- gold is 1 egg in 4,000 at luck 1: 2% x 1/80
		T.near(Config.Mutation.MaterialChance / 80, 1 / 4000, 1e-6)
	end)

	T.test("the same seed gives the same outcome", function()
		local p = parents("purple", "pink", g("solid", "duochrome"), g("duochrome", "solid"))
		local a, b = Rng.new(55), Rng.new(55)
		for _ = 1, 200 do
			T.same(Mutations.resolveOffspring(p, a, 3), Mutations.resolveOffspring(p, b, 3))
		end
	end)

	T.test(
		"pity: same colour gives a secret; cross colours 10% secret, else a duochrome Dual; never a material",
		function()
			local plain =
				Mutations.resolveOffspring(parents("navy", "navy"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5 }), 1)
			local forced = Mutations.applyPity(plain, "navy", "navy", Rng.sequence({ 0 }))
			T.same(forced.appearance, { type = "secret", definitionId = "secret-navy-navy" })
			local rng = Rng.new(404)
			local secrets, duals = 0, 0
			for _ = 1, 10000 do
				local out = Mutations.applyPity(plain, "red", "pink", rng)
				T.ok(out.appearance.type ~= "material")
				if out.appearance.type == "secret" then
					secrets += 1
					T.eq(out.appearance.definitionId, "secret-pink-red")
				else
					T.eq(out.appearance.type, "dual")
					T.eq(out.appearance.definitionId, "dual-red-pink-38")
					T.same(out.patternGenotype, Genetics.duochrome())
					duals += 1
				end
			end
			T.near(secrets / 10000, 0.10, 0.012)
			T.eq(secrets + duals, 10000)
		end
	)

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
