local Colours = require("../../src/shared/Colours")
local Config = require("../../src/shared/Config")
local Genetics = require("../../src/shared/Genetics")
local Mutations = require("../../src/shared/Mutations")
local Rng = require("../../src/shared/Rng")

local function parent(colour, kind, id)
	local appearance = { type = kind or "none", definitionId = id }
	return {
		appearanceMutation = appearance,
		colourGenotype = Genetics.fromAppearance(appearance, Genetics.homozygous(colour)),
	}
end

local navy = parent("navy")
local red = parent("red")
local tartan = parent("navy", "dual", "dual-navy-red-21")
local daisy = parent("yellow", "dual", "dual-yellow-white-49")
local chimera = parent("red", "secret", "secret-navy-red")
local chick = parent("white", "secret", "secret-white-yellow")
-- Independent spec values: these assertions must catch changes to Config as well as the resolver.
local rows = {
	{ "plainSame", navy, navy, 0.01, 0, 0.89, 0.10 },
	{ "plainOther", navy, red, 0.01, 0.04, 0.85, 0.10 },
	{ "dualPlain", tartan, parent("yellow"), 0.02, 0.25, 0.63, 0.10 },
	{ "dualSame", tartan, tartan, 0.03, 0.50, 0.37, 0.10 },
	{ "dualOther", tartan, daisy, 0.04, 0.40, 0.46, 0.10 },
	{ "secretPlain", chimera, parent("yellow"), 0.03, 0.20, 0.67, 0.10 },
	{ "secretDual", chimera, daisy, 0.05, 0.40, 0.45, 0.10 },
	{ "secretSame", chimera, chimera, 0.10, 0.60, 0.20, 0.10 },
	{ "secretOther", chimera, chick, 0.07, 0.45, 0.38, 0.10 },
}

return function(T)
	T.test("one through four colours have 0/1, 1/3, 3/6 and 6/10 pools", function()
		local colours = { "navy", "red", "yellow", "white" }
		local set = {}
		for n, colour in colours do
			table.insert(set, colour)
			local duals, secrets = Genetics.dualPool(set), Genetics.secretPool(set)
			T.eq(#duals, n * (n - 1) / 2)
			T.eq(#secrets, n * (n + 1) / 2)
			local seen = {}
			for _, pool in { duals, secrets } do
				for _, definition in pool do
					T.ok(not seen[definition.id], "duplicate pool entry")
					seen[definition.id] = true
					for _, base in definition.parentPair do
						T.ok(table.find(set, base), "pool escaped the parent colours")
					end
				end
			end
		end
	end)

	for i, row in rows do
		T.test(row[1] .. ": 100,000 eggs match all four category shares within 0.5 percentage points", function()
			local a, b = row[2], row[3]
			T.eq(Mutations.pairingKind(a, b), row[1])
			T.eq(Mutations.pairingKind(b, a), row[1])
			local chances = Mutations.chances(a, b, 1)
			local counts = { secret = 0, dual = 0, plain = 0, random = 0 }
			local byColour, bySecret, byDual, material = {}, {}, {}, 0
			local set = Genetics.colourSet(a, b)
			local rng = Rng.new(7000 + i)
			for _ = 1, 100000 do
				local out = Mutations.resolveOffspring(a, b, rng, 1)
				counts[out.rolled] += 1
				local colour = out.colourGenotype.alleles[1]
				if out.rolled == "random" then
					T.eq(out.appearance.type, "none", "Random never gets a rare appearance")
					T.ok(not table.find(set, colour), "Random never repeats a parent's carried colour")
					T.ok(Colours.isValid(colour))
				elseif out.rolled == "plain" then
					T.ok(table.find(set, colour))
					byColour[colour] = (byColour[colour] or 0) + 1
					if out.appearance.type == "material" then
						material += 1
					end
				elseif out.rolled == "secret" then
					local id = out.appearance.definitionId
					bySecret[id] = (bySecret[id] or 0) + 1
				elseif out.rolled == "dual" then
					local id = out.appearance.definitionId
					byDual[id] = (byDual[id] or 0) + 1
				end
				T.same(out.colourGenotype, Genetics.fromAppearance(out.appearance, out.colourGenotype))
				if out.rolled ~= "random" then
					for _, base in out.colourGenotype.alleles do
						T.ok(table.find(set, base), "inherited genes stay inside the parent colour set")
					end
				end
			end
			for j, kind in { "secret", "dual", "plain", "random" } do
				T.near(chances[kind], row[j + 3], 1e-12, kind .. " configured chance")
				T.near(counts[kind] / 100000, row[j + 3], 0.005, kind .. " frequency")
			end
			T.near(material / counts.plain, Config.Mutation.MaterialChance, 0.005, "material is conditional on Plain")
			for _, design in chances.duals do
				T.near((byDual[design.id] or 0) / 100000, row[5] / #chances.duals, 0.005, "uniform Dual pick")
			end
			for _, recipe in chances.secrets do
				T.near((bySecret[recipe.id] or 0) / 100000, row[4] / #chances.secrets, 0.005, "uniform Secret pick")
			end
			if row[1] == "plainOther" or row[1] == "dualSame" then
				-- Owner examples count the Plain category before its separate material roll.
				T.near(byColour.navy / 100000, row[6] / 2, 0.005)
				T.near(byColour.red / 100000, row[6] / 2, 0.005)
				for _, recipe in chances.secrets do
					T.near(bySecret[recipe.id] / counts.secret, 1 / 3, 0.04, recipe.id .. " uniform within Secrets")
				end
			end
		end)
	end

	T.test("luck five raises Secret and Dual, reduces only Plain, and leaves Random fixed", function()
		local a, b = Mutations.chances(navy, red, 1), Mutations.chances(navy, red, 5)
		T.near(b.secret, 0.05, 1e-12)
		T.near(b.dual, 0.20, 1e-12)
		T.near(b.plain, 0.65, 1e-12)
		T.eq(b.random, a.random)
		T.near(a.plain - b.plain, b.secret - a.secret + b.dual - a.dual, 1e-12)
		for _, row in rows do
			local normal = Mutations.chances(row[2], row[3], 1)
			local lucky = Mutations.chances(row[2], row[3], 5)
			T.ok(lucky.secret > normal.secret)
			T.ok(lucky.dual >= normal.dual)
			T.ok(lucky.plain < normal.plain)
			for _, luck in { 0, 1, 5, 1000 } do
				local c = Mutations.chances(row[2], row[3], luck)
				T.near(c.secret + c.dual + c.plain + c.random, 1, 1e-12)
				T.ok(c.plain >= 0)
				T.ok(c.secret <= Config.Mutation.ChanceCap and c.dual <= Config.Mutation.ChanceCap)
				T.eq(c.random, 0.10)
			end
		end
	end)

	T.test("same-colour Secrets transfer their unavailable Dual share to Plain", function()
		local snow = parent("white", "secret", "secret-white-white")
		local c = Mutations.chances(snow, snow, 1)
		T.eq(Mutations.pairingKind(snow, snow), "secretSame")
		T.eq(#c.duals, 0)
		T.eq(#c.secrets, 1)
		T.eq(c.dual, 0)
		T.near(c.plain, 0.80, 1e-12)
		local rng = Rng.new(803)
		for _ = 1, 10000 do
			T.ok(Mutations.resolveOffspring(snow, snow, rng, 5).appearance.type ~= "dual")
		end
	end)

	T.test("materials count as Plain regardless of definition id", function()
		local gold = parent("navy", "material", "gold")
		local mud = parent("navy", "material", "mud")
		T.eq(Mutations.pairingKind(gold, mud), "plainSame")
		T.eq(Mutations.pairingKind(gold, red), "plainOther")
		T.eq(Mutations.pairingKind(gold, tartan), "dualPlain")
		T.eq(Mutations.pairingKind(gold, chimera), "secretPlain")
		local a, b = Rng.new(99), Rng.new(99)
		for _ = 1, 100 do
			T.same(Mutations.resolveOffspring(gold, mud, a, 1), Mutations.resolveOffspring(navy, navy, b, 1))
		end
	end)
end
