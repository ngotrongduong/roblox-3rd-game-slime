local Colours = require("../../src/shared/Colours")
local DualDesigns = require("../../src/shared/DualDesigns")

return function(T)
	T.test("55 designs with ids, assets, skins and weight 1", function()
		T.eq(#DualDesigns.List, 55)
		local first = DualDesigns.List[1]
		T.eq(first.id, "dual-black-gray-01")
		T.eq(first.name, "Pinstripe")
		T.eq(first.skin, "01_pinstripe")
		T.eq(first.assetId, "slime.dual.01")
		T.eq(first.bodyColour, "black")
		T.eq(first.patternColour, "gray")
		local wild = DualDesigns.List[8]
		T.eq(wild.skin, "08_wild_rosette")
		T.eq(wild.bodyColour, "pink")
		T.eq(wild.patternColour, "black")
		local last = DualDesigns.List[55]
		T.eq(last.id, "dual-blue-white-55")
		T.eq(last.name, "Frostbolt")
		T.eq(last.skin, "55_frostbolt")
		T.eq(last.bodyColour, "white")
		T.eq(last.patternColour, "blue")
		local ids, assets = {}, {}
		for i, d in DualDesigns.List do
			T.eq(d.weight, 1)
			T.ok(d.enabled)
			T.eq(DualDesigns.get(d.id), d)
			T.eq(d.number, string.format("%02d", i), "numbered in order")
			T.ok(not ids[d.id] and not assets[d.assetId], "unique " .. d.id)
			ids[d.id], assets[d.assetId] = true, true
			T.ok(d.bodyColour ~= d.patternColour)
			T.ok(d.bodyColour == d.parentPair[1] or d.bodyColour == d.parentPair[2])
			T.ok(d.patternColour == d.parentPair[1] or d.patternColour == d.parentPair[2])
		end
	end)

	T.test("every pair of different colours has exactly one design, in either order", function()
		local count = 0
		for i, a in Colours.Ids do
			for j = i + 1, #Colours.Ids do
				local b = Colours.Ids[j]
				count += 1
				T.eq(#DualDesigns.exact(a, b), 1, a .. "+" .. b)
				T.eq(DualDesigns.exact(a, b)[1], DualDesigns.exact(b, a)[1])
				T.eq(DualDesigns.pool(a, b)[1], DualDesigns.exact(a, b)[1], "the pool is just that design")
				T.eq(#DualDesigns.pool(b, a), 1)
			end
		end
		T.eq(count, 55)
		-- and no pair is used twice
		local seen = {}
		for _, d in DualDesigns.List do
			local key = Colours.pairKey(d.parentPair[1], d.parentPair[2])
			T.ok(not seen[key], "pair used twice " .. key)
			seen[key] = true
		end
	end)

	T.test("the doc's rows: owner paintings moved to their pair, names per pair", function()
		T.eq(DualDesigns.exact("red", "pink")[1].name, "Sweetheart")
		T.eq(DualDesigns.exact("white", "blue")[1].name, "Frostbolt")
		T.eq(DualDesigns.exact("green", "white")[1].name, "Mint Chip")
		T.eq(DualDesigns.exact("blue", "green")[1].name, "Seafoam")
		T.eq(DualDesigns.exact("black", "white")[1].name, "Moo")
	end)

	T.test("same-colour pairs have no design; the fallback pool is gone", function()
		for _, c in Colours.Ids do
			T.eq(#DualDesigns.exact(c, c), 0)
			T.eq(#DualDesigns.pool(c, c), 0)
		end
	end)
end
