local Colours = require("../../src/shared/Colours")
local DualDesigns = require("../../src/shared/DualDesigns")
local Genetics = require("../../src/shared/Genetics")
local SecretRecipes = require("../../src/shared/SecretRecipes")

local function parent(kind, id, a, b)
	return { appearanceMutation = { type = kind, definitionId = id }, colourGenotype = { alleles = { a, b } } }
end

return function(T)
	T.test("plain genes have no hidden colour or dominance", function()
		for _, a in Colours.Ids do
			for _, b in Colours.Ids do
				T.eq(Genetics.phenotype({ alleles = { a, b } }), a)
				T.same(Genetics.baseColours(parent("none", nil, a, b)), { a })
			end
		end
	end)

	T.test("every rare definition supplies its genes and visible colour", function()
		for _, design in DualDesigns.List do
			local p = parent("dual", design.id, "blue", "blue")
			T.same(Genetics.baseColours(p), design.parentPair)
			T.same(Genetics.fromAppearance(p.appearanceMutation, p.colourGenotype).alleles, design.parentPair)
			T.eq(Genetics.visibleColour(p.appearanceMutation, p.colourGenotype), design.bodyColour)
		end
		for _, recipe in SecretRecipes.List do
			local p = parent("secret", recipe.id, "blue", "blue")
			local a, b = recipe.parentPair[1], recipe.parentPair[2]
			T.same(Genetics.baseColours(p), if a == b then { a } else { a, b })
			T.same(Genetics.fromAppearance(p.appearanceMutation, p.colourGenotype).alleles, recipe.parentPair)
			T.eq(Genetics.visibleColour(p.appearanceMutation, p.colourGenotype), a)
		end
	end)

	T.test("materials and unknown appearances keep one usable base colour", function()
		for _, kind in { "material", "dual", "secret" } do
			local p = parent(kind, "unknown", "red", "white")
			T.same(Genetics.baseColours(p), { "red" })
			T.same(Genetics.fromAppearance(p.appearanceMutation, p.colourGenotype), Genetics.homozygous("red"))
		end
	end)

	T.test("colour union is deduplicated and follows Colours.Ids independent of parent order", function()
		local a = parent("dual", "dual-navy-red-21", "blue", "blue")
		local b = parent("dual", "dual-yellow-white-49", "blue", "blue")
		T.same(Genetics.colourSet(a, b), { "navy", "red", "yellow", "white" })
		T.same(Genetics.colourSet(a, b), Genetics.colourSet(b, a))
		T.same(Genetics.colourSet(a, a), { "navy", "red" })
	end)

	T.test("validate repairs malformed colour genes and copy owns its alleles", function()
		local w = {}
		T.same(Genetics.validateColour({ alleles = { "red", "teal" } }, w, "x"), { alleles = { "red", "blue" } })
		T.eq(#w, 1)
		T.eq(Genetics.validateColour({ alleles = { "red" } }, {}, "x"), nil)
		T.eq(Genetics.validateColour("junk", {}, "x"), nil)
		T.ok(Genetics.isUsableColour({ alleles = { "red", "navy" } }))
		T.ok(not Genetics.isUsableColour({ alleles = { "red", "teal" } }))
		T.ok(not Genetics.isUsableColour({ alleles = { "red" } }))
		local original = Genetics.homozygous("red")
		local copy = Genetics.copy(original)
		copy.alleles[1] = "navy"
		T.eq(original.alleles[1], "red")
	end)
end
