local Colours = require("../../src/shared/Colours")
local SecretRecipes = require("../../src/shared/SecretRecipes")

return function(T)
	T.test("66 recipes: every colour pair exactly once", function()
		T.eq(#SecretRecipes.List, 66)
		for i, a in Colours.Ids do
			for j = i, #Colours.Ids do
				local b = Colours.Ids[j]
				T.eq(#SecretRecipes.forPair(a, b), 1, a .. "+" .. b)
				T.eq(#SecretRecipes.forPair(b, a), 1, b .. "+" .. a)
			end
		end
	end)

	T.test("ids and assets use the alphabetical pair", function()
		local r = SecretRecipes.forPair("white", "black")[1]
		T.eq(r.id, "secret-black-white")
		T.eq(r.assetId, "slime.secret.black-white")
		T.eq(r.name, "Yin-Yang Koi")
		T.eq(SecretRecipes.get("secret-navy-navy").name, "Deep-Sea Leviathan")
		T.eq(SecretRecipes.get("secret-black-blue").name, "Tempest Dragon")
		T.eq(SecretRecipes.get("secret-black-orange").name, "Jack-o'-Slime")
		local ids = {}
		for _, rec in SecretRecipes.List do
			T.ok(not ids[rec.id], "duplicate " .. rec.id)
			ids[rec.id] = true
			T.eq(rec.weight, 1)
			T.ok(rec.description ~= "")
		end
	end)

	T.test("the 16 big-body secrets", function()
		local expected = {
			"yellow-yellow",
			"purple-yellow",
			"black-blue",
			"black-navy",
			"black-pink",
			"black-purple",
			"blue-gray",
			"blue-green",
			"blue-white",
			"gray-purple",
			"navy-purple",
			"orange-pink",
			"orange-red",
			"orange-yellow",
			"pink-purple",
			"pink-red",
		}
		local big = 0
		for _, rec in SecretRecipes.List do
			if rec.big then
				big += 1
			end
		end
		T.eq(big, 16)
		for _, suffix in expected do
			local rec = SecretRecipes.get("secret-" .. suffix)
			T.ok(rec and rec.big, suffix)
		end
	end)
end
