local Colours = require("../../src/shared/Colours")
local Genetics = require("../../src/shared/Genetics")
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
	local counts = { secret = 0, dual = 0, base = 0, normal = 0 }
	for _ = 1, n do
		local out = Mutations.resolveOffspring(p, rng, luck)
		counts[out.rolled] += 1
	end
	return {
		secret = counts.secret / n,
		dual = counts.dual / n,
		base = counts.base / n,
		normal = counts.normal / n,
	}
end

return function(T)
	T.test("chances: secret 1%, dual 5% (cross colours only), base 10%; luck multiplies and caps", function()
		local c = Mutations.chances("white", "black", 1)
		T.eq(c.secret, 0.01)
		T.eq(c.dual, 0.05)
		T.eq(c.base, 0.10)
		T.eq(#c.secrets, 1)
		local same = Mutations.chances("navy", "navy", 1)
		T.eq(same.dual, 0)
		T.eq(#same.duals, 0)
		T.eq(same.secret, 0.01)
		local lucky = Mutations.chances("white", "black", 5)
		T.near(lucky.secret, 0.05, 1e-12)
		T.near(lucky.dual, 0.25, 1e-12)
		T.eq(lucky.base, 0.10, "luck never touches the base-colour mutation")
		local capped = Mutations.chances("white", "black", 1000)
		T.eq(capped.secret, 0.95)
		T.eq(capped.dual, 0.95)
	end)

	T.test("a secret roll wins before dual and base; only one outcome", function()
		-- colour A, colour B, pattern A, pattern B, secret roll (hits), recipe pick
		local out = Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.005, 0 }), 1)
		T.eq(out.rolled, "secret")
		T.same(out.appearance, { type = "secret", definitionId = "secret-black-white" })
		T.same(out.colourGenotype, g("white", "black"), "a secret keeps the inherited genes")
		T.same(out.patternGenotype, Genetics.solid())
		T.ok(out.hadSecret and out.hadDual)
	end)

	T.test("a dual roll comes second and makes the baby duochrome", function()
		local out = Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.01, 0 }), 1)
		T.eq(out.rolled, "dual")
		-- white + black has no exact design: the pool is every design with white or black; 01 first
		T.same(out.appearance, { type = "dual", definitionId = "dual-green-white-01" })
		T.same(out.patternGenotype, Genetics.duochrome())
		T.same(out.colourGenotype, g("white", "black"))
	end)

	T.test("a base-colour mutation comes third: a new homozygous colour, no appearance", function()
		local out =
			Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.05, 0 }), 1)
		T.eq(out.rolled, "base")
		-- the baby's own colour (black) is excluded; the first of the others is gray
		T.same(out.colourGenotype, g("gray", "gray"))
		T.same(out.appearance, { type = "none" })
		T.same(out.patternGenotype, Genetics.solid(), "pattern genes are kept")
	end)

	T.test("a base-colour mutation never keeps the baby's colour", function()
		for _, c in Colours.Ids do
			for pick = 0, 0.95, 0.1 do
				local out = Mutations.resolveOffspring(parents(c, c), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.01, pick }), 1)
				T.eq(out.rolled, "base")
				T.ok(out.colourGenotype.alleles[1] ~= c, "mutated to its own colour " .. c)
				T.eq(out.colourGenotype.alleles[1], out.colourGenotype.alleles[2])
			end
		end
	end)

	T.test("plain otherwise", function()
		local out =
			Mutations.resolveOffspring(parents("white", "black"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5 }), 1)
		T.eq(out.rolled, "normal")
		T.same(out.appearance, { type = "none" })
		T.same(out.colourGenotype, g("white", "black"))
	end)

	T.test("same-colour parents spend no dual roll", function()
		-- secret misses, then the next roll is already the base roll (misses): plain, no more rolls
		local out = Mutations.resolveOffspring(parents("navy", "navy"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5 }), 1)
		T.eq(out.rolled, "normal")
		T.ok(out.hadSecret)
		T.ok(not out.hadDual)
	end)

	T.test("carriers: a duochrome/duochrome baby shows an exact Dual for its two alleles", function()
		local carrier = g("solid", "duochrome")
		-- colours white + green, pattern picks the duochrome allele from both, all rolls miss, pick
		local out = Mutations.resolveOffspring(
			parents("white", "green", carrier, carrier),
			Rng.sequence({ 0, 0, 0.9, 0.9, 0.5, 0.5, 0.5, 0 }),
			1
		)
		T.eq(out.rolled, "normal")
		T.same(out.appearance, { type = "dual", definitionId = "dual-green-white-01" })
		T.same(out.patternGenotype, Genetics.duochrome())
	end)

	T.test("carriers: no exact design or identical alleles means no Dual", function()
		local duo = Genetics.duochrome()
		local none = Mutations.resolveOffspring(
			parents("white", "black", duo, duo),
			Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5, 0.5 }),
			1
		)
		T.same(none.appearance, { type = "none" })
		local same =
			Mutations.resolveOffspring(parents("navy", "navy", duo, duo), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5 }), 1)
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

	T.test("statistics: different colours at luck 1 land near 1% / 4.95% / 9.405%", function()
		local r = rates(parents("white", "black"), 1, 40000, 101)
		T.near(r.secret, 0.01, 0.003, "secret")
		T.near(r.dual, 0.0495, 0.006, "dual")
		T.near(r.base, 0.09405, 0.008, "base")
		T.near(r.normal, 0.84645, 0.012, "normal")
	end)

	T.test("statistics: different colours at luck 5 land near 5% / 23.75% / 7.125%", function()
		local r = rates(parents("red", "yellow"), 5, 40000, 202)
		T.near(r.secret, 0.05, 0.006, "secret")
		T.near(r.dual, 0.2375, 0.012, "dual")
		T.near(r.base, 0.07125, 0.007, "base")
	end)

	T.test("statistics: same colour at luck 1 lands near 1% / 0 / 9.9%", function()
		local r = rates(parents("navy", "navy"), 1, 40000, 303)
		T.near(r.secret, 0.01, 0.003, "secret")
		T.eq(r.dual, 0, "dual")
		T.near(r.base, 0.099, 0.008, "base")
	end)

	T.test("the same seed gives the same outcome", function()
		local p = parents("purple", "pink", g("solid", "duochrome"), g("duochrome", "solid"))
		local a, b = Rng.new(55), Rng.new(55)
		for _ = 1, 200 do
			T.same(Mutations.resolveOffspring(p, a, 3), Mutations.resolveOffspring(p, b, 3))
		end
	end)

	T.test("pity: same colour gives a secret; cross colours 10% secret, else a duochrome Dual", function()
		local plain = Mutations.resolveOffspring(parents("navy", "navy"), Rng.sequence({ 0, 0, 0, 0, 0.5, 0.5 }), 1)
		local forced = Mutations.applyPity(plain, "navy", "navy", Rng.sequence({ 0 }))
		T.same(forced.appearance, { type = "secret", definitionId = "secret-navy-navy" })
		local rng = Rng.new(404)
		local secrets, duals = 0, 0
		for _ = 1, 10000 do
			local out = Mutations.applyPity(plain, "red", "pink", rng)
			if out.appearance.type == "secret" then
				secrets += 1
				T.eq(out.appearance.definitionId, "secret-pink-red")
			else
				T.eq(out.appearance.type, "dual")
				T.eq(out.appearance.definitionId, "dual-pink-red-03")
				T.same(out.patternGenotype, Genetics.duochrome())
				duals += 1
			end
		end
		T.near(secrets / 10000, 0.10, 0.012)
		T.eq(secrets + duals, 10000)
	end)

	T.test("appearance asset: secret > dual > base; unknown ids are kept but show the base", function()
		T.eq(
			Mutations.assetId({ type = "secret", definitionId = "secret-navy-navy" }, "navy"),
			"slime.secret.navy-navy"
		)
		T.eq(Mutations.assetId({ type = "dual", definitionId = "dual-pink-red-03" }, "red"), "slime.dual.03")
		T.eq(Mutations.assetId({ type = "none" }, "red"), "slime.base.red")
		T.eq(Mutations.assetId({ type = "dual", definitionId = "dual-future-99" }, "red"), "slime.base.red")
		T.same(Mutations.validate({ type = "dual", definitionId = "dual-future-99" }), {
			type = "dual",
			definitionId = "dual-future-99",
		})
		T.ok(not Mutations.isKnown({ type = "dual", definitionId = "dual-future-99" }))
		T.same(Mutations.validate({ type = "secret" }), { type = "none" })
		T.same(Mutations.validate("junk"), { type = "none" })
		T.eq(Mutations.rarity({ type = "secret", definitionId = "x" }), "secret")
		T.eq(Mutations.rarity({ type = "none" }), "base")
	end)
end
