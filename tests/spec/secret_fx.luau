-- The Secret slimes' signature effects (VfxLib aura.secret_signature): a variant for each, none the same. (The
-- library's Schema needs the engine's Enum, so the effect's schema and budget are checked in Studio and in the library.)
local SecretRecipes = require("../../src/shared/SecretRecipes")
local SecretFx = require("../../src/shared/SecretFx")
local effect = require("../../src/shared/VfxLib/Effects/aura/secret_signature")

return function(T)
	T.test("every Secret slime has its own variant", function()
		T.eq(effect.id, SecretFx.Effect)
		local count = 0
		for _ in effect.variants do
			count += 1
		end
		T.eq(count, #SecretRecipes.List)
		for _, recipe in SecretRecipes.List do
			local name = SecretFx.variant(recipe.id)
			T.ok(name ~= nil and effect.variants[name] ~= nil, recipe.name)
		end
		T.eq(SecretFx.variant("secret-black-orange"), "jack_o_slime")
		T.eq(SecretFx.variant("white"), nil)
	end)

	-- (mid since 2026-11-11, the owner asking for more and companions: an aura's caps, 6 emitters and 40 a second)
	T.test("each variant is one to six pieces, an aura's rate", function()
		T.eq(effect.tier, "mid")
		for name, variant in effect.variants do
			T.ok(#variant.pieces >= 1 and #variant.pieces <= 6, name)
			local rate = 0
			for _, piece in variant.pieces do
				rate += piece.rate
			end
			T.ok(rate <= 40, `{name} gives {rate} a second`)
		end
	end)

	T.test("no two variants are the same design", function()
		local seen = {}
		for name, variant in effect.variants do
			local words = {}
			for _, piece in variant.pieces do
				local motion = if piece.orbit then "orbit" else piece.at or "body"
				table.insert(words, `{piece.texture}/{motion}`)
			end
			-- (its fish are part of its design)
			for _, swimmer in variant.swimmers or {} do
				table.insert(words, `fish:{swimmer.model}`)
			end
			table.sort(words)
			local key = table.concat(words, "+")
			T.ok(seen[key] == nil, `{name} repeats {seen[key]}`)
			seen[key] = name
		end
	end)
end
