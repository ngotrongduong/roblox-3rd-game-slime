local Colours = require("../../src/shared/Colours")
local Genetics = require("../../src/shared/Genetics")
local Rng = require("../../src/shared/Rng")

local function g(a: string, b: string)
	return { alleles = { a, b } }
end

return function(T)
	T.test("phenotype: the more dominant allele shows", function()
		T.eq(Genetics.phenotype(g("black", "white")), "black")
		T.eq(Genetics.phenotype(g("white", "black")), "black")
		T.eq(Genetics.phenotype(g("navy", "blue")), "navy")
		T.eq(Genetics.phenotype(g("pink", "pink")), "pink")
		T.eq(Genetics.phenotype(g("yellow", "orange")), "orange")
	end)

	T.test("phenotype of every pair follows the dominance table", function()
		for _, a in Colours.List do
			for _, b in Colours.List do
				local expected = if a.dominance >= b.dominance then a.id else b.id
				T.eq(Genetics.phenotype(g(a.id, b.id)), expected, a.id .. "/" .. b.id)
			end
		end
	end)

	T.test("phenotype never fails on bad alleles", function()
		T.eq(Genetics.phenotype(g("teal", "red")), "red")
		T.eq(Genetics.phenotype(g("red", "teal")), "red")
		T.eq(Genetics.phenotype(g("teal", "mauve")), "blue")
	end)

	T.test("a baby only gets alleles its parents carry, one from each", function()
		local a, b = g("red", "white"), g("blue", "green")
		local seen = {}
		local rng = Rng.new(11)
		for _ = 1, 400 do
			local baby = Genetics.inheritColour(a, b, rng)
			T.ok(baby.alleles[1] == "red" or baby.alleles[1] == "white", "first allele from A")
			T.ok(baby.alleles[2] == "blue" or baby.alleles[2] == "green", "second allele from B")
			seen[baby.alleles[1] .. "/" .. baby.alleles[2]] = true
		end
		for _, combo in { "red/blue", "red/green", "white/blue", "white/green" } do
			T.ok(seen[combo], "never got " .. combo)
		end
		T.same(a, g("red", "white"), "parents are not changed")
	end)

	T.test("a recessive colour is carried silently and can come back", function()
		-- black/white looks black; two such parents give white/white a quarter of the time
		T.eq(Genetics.phenotype(g("black", "white")), "black")
		local rng = Rng.new(3)
		local white = 0
		for _ = 1, 4000 do
			local baby = Genetics.inheritColour(g("black", "white"), g("black", "white"), rng)
			if Genetics.phenotype(baby) == "white" then
				white += 1
			end
		end
		T.near(white / 4000, 0.25, 0.03)
	end)

	T.test("each allele is a 50/50 pick, A's roll first", function()
		local baby = Genetics.inheritColour(g("red", "white"), g("blue", "green"), Rng.sequence({ 0.2, 0.7 }))
		T.same(baby, g("red", "green"))
	end)

	T.test("pattern: only duochrome/duochrome expresses, solid/duochrome is a carrier", function()
		T.ok(Genetics.isDuochrome(Genetics.duochrome()))
		T.ok(not Genetics.isDuochrome(g("solid", "duochrome")))
		T.ok(Genetics.isCarrier(g("solid", "duochrome")))
		T.ok(Genetics.isCarrier(g("duochrome", "solid")))
		T.ok(not Genetics.isCarrier(Genetics.solid()))
		T.ok(not Genetics.isCarrier(Genetics.duochrome()))
	end)

	T.test("pattern inheritance: carriers make duochrome a quarter of the time, solid never", function()
		local rng = Rng.new(8)
		local duo = 0
		for _ = 1, 4000 do
			if Genetics.isDuochrome(Genetics.inheritPattern(g("solid", "duochrome"), g("solid", "duochrome"), rng)) then
				duo += 1
			end
			T.ok(
				not Genetics.isDuochrome(Genetics.inheritPattern(g("solid", "duochrome"), Genetics.solid(), rng)),
				"a solid/solid parent always passes solid"
			)
		end
		T.near(duo / 4000, 0.25, 0.03)
	end)

	T.test("validate repairs genotypes field by field", function()
		local w = {}
		T.same(Genetics.validateColour(g("red", "teal"), w, "x"), g("red", "blue"))
		T.eq(#w, 1)
		T.eq(Genetics.validateColour({ alleles = { "red" } }, {}, "x"), nil)
		T.eq(Genetics.validateColour("junk", {}, "x"), nil)
		T.same(Genetics.validatePattern(g("solid", "duochrome"), {}, "x"), g("solid", "duochrome"))
		local w2 = {}
		T.same(Genetics.validatePattern(g("solid", "striped"), w2, "x"), Genetics.solid())
		T.eq(#w2, 1)
	end)

	T.test("breeding-usable genotypes", function()
		T.ok(Genetics.isUsableColour(g("red", "navy")))
		T.ok(not Genetics.isUsableColour(g("red", "teal")))
		T.ok(not Genetics.isUsableColour({ alleles = { "red" } }))
		T.ok(Genetics.isUsablePattern(Genetics.solid()))
		T.ok(not Genetics.isUsablePattern({ alleles = {} }))
	end)
end
