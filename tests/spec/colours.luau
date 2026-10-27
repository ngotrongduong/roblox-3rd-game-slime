local Colours = require("../../src/shared/Colours")

return function(T)
	T.test("11 base colours in the original order", function()
		T.eq(#Colours.List, 11)
		T.same(
			Colours.Ids,
			{ "black", "gray", "navy", "purple", "red", "orange", "yellow", "green", "pink", "blue", "white" }
		)
	end)

	T.test("dominance and tie priority run 11 down to 1 and are unique", function()
		local seen = {}
		for i, c in Colours.List do
			T.eq(c.dominance, 12 - i, c.id)
			T.eq(c.tiePriority, 12 - i, c.id)
			T.ok(not seen[c.tiePriority], "duplicate tie priority")
			seen[c.tiePriority] = true
		end
	end)

	T.test("names, assets and swatches", function()
		local navy = Colours.get("navy")
		T.ok(navy)
		assert(navy)
		T.eq(navy.name, "Navy")
		T.eq(navy.assetId, "slime.base.navy")
		T.eq(navy.swatch, "#1b4fd8")
		local white = Colours.get("white")
		assert(white)
		T.eq(white.swatch, "#f5f2ea")
		for _, c in Colours.List do
			T.ok(string.match(c.swatch, "^#%x%x%x%x%x%x$"), c.id .. " swatch")
		end
	end)

	T.test("validity, pair keys and asset parsing", function()
		T.ok(Colours.isValid("pink"))
		T.ok(not Colours.isValid("teal"))
		T.ok(not Colours.isValid(nil))
		T.eq(Colours.pairKey("white", "black"), "black|white")
		T.eq(Colours.pairKey("black", "white"), "black|white")
		T.eq(Colours.pairKey("red", "red"), "red|red")
		T.eq(Colours.fromAssetId("slime.base.navy"), "navy")
		T.eq(Colours.fromAssetId("slime.dual.01"), nil)
		T.eq(Colours.fromAssetId("slime.base.teal"), nil)
	end)
end
