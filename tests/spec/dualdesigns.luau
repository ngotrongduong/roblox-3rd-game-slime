local DualDesigns = require("../../src/shared/DualDesigns")
local Colours = require("../../src/shared/Colours")

return function(T)
	T.test("20 designs with ids, assets and weight 1", function()
		T.eq(#DualDesigns.List, 20)
		local first = DualDesigns.List[1]
		T.eq(first.id, "dual-green-white-01")
		T.eq(first.name, "Mint Chip")
		T.eq(first.pattern, "dots")
		T.eq(first.assetId, "slime.dual.01")
		local last = DualDesigns.List[20]
		T.eq(last.id, "dual-green-navy-20")
		T.eq(last.name, "Forestpatch")
		for _, d in DualDesigns.List do
			T.eq(d.weight, 1)
			T.ok(d.enabled)
			T.eq(DualDesigns.get(d.id), d)
		end
	end)

	T.test("18 distinct exact pairs; blue+white and blue+green have two", function()
		local pairs = {}
		local count = 0
		for _, d in DualDesigns.List do
			local key = Colours.pairKey(d.parentPair[1], d.parentPair[2])
			if not pairs[key] then
				count += 1
			end
			pairs[key] = true
		end
		T.eq(count, 18)
		T.eq(#DualDesigns.exact("white", "blue"), 2)
		T.eq(#DualDesigns.exact("green", "blue"), 2)
		T.eq(#DualDesigns.exact("red", "pink"), 1)
		T.eq(DualDesigns.exact("red", "pink")[1].name, "Sweetheart")
	end)

	T.test("the pool: exact designs first, else every design sharing a colour", function()
		T.eq(#DualDesigns.pool("white", "green"), 1)
		-- yellow + black has no exact design: designs with yellow (05, 13) or black (09, 14)
		local pool = DualDesigns.pool("yellow", "black")
		T.eq(#pool, 4)
		for _, d in pool do
			local p = d.parentPair
			T.ok(p[1] == "yellow" or p[2] == "yellow" or p[1] == "black" or p[2] == "black")
		end
		T.eq(#DualDesigns.pool("navy", "navy"), 0)
	end)

	T.test("37 of the 55 cross pairs have no exact design, and every cross pair has a pool", function()
		local missing = 0
		for i, a in Colours.Ids do
			for j = i + 1, #Colours.Ids do
				local b = Colours.Ids[j]
				if #DualDesigns.exact(a, b) == 0 then
					missing += 1
				end
				T.ok(#DualDesigns.pool(a, b) > 0, a .. "+" .. b)
			end
		end
		T.eq(missing, 37)
	end)
end
