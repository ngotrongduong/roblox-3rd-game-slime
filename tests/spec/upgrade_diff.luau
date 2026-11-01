--!strict
local UpgradeDiff = require("../../src/shared/UpgradeDiff")

return function(T: any)
	T.test("a piece added early does not mark the same-named pieces after it", function()
		local before = { "Post@1", "Post@2", "Post@3" }
		local after = {
			{ signature = "Post@0", size = 1 },
			{ signature = "Post@1", size = 1 },
			{ signature = "Post@2", size = 1 },
			{ signature = "Post@3", size = 1 },
		}
		T.same(UpgradeDiff.changed(before, after, 10), { 1 })
	end)
	T.test("equal pieces match once each, so a second copy counts as new", function()
		T.same(
			UpgradeDiff.changed(
				{ "Crate" },
				{ { signature = "Crate", size = 1 }, { signature = "Crate", size = 1 } },
				10
			),
			{ 2 }
		)
	end)
	T.test("the limit keeps the biggest pieces, the ones a player sees", function()
		local after = {
			{ signature = "Small", size = 1 },
			{ signature = "Roof", size = 900 },
			{ signature = "Wall", size = 300 },
		}
		T.same(UpgradeDiff.changed({}, after, 2), { 2, 3 })
	end)
	T.test("a stage that did not change marks nothing", function()
		T.same(
			UpgradeDiff.changed({ "A", "B" }, { { signature = "B", size = 1 }, { signature = "A", size = 1 } }, 10),
			{}
		)
	end)
end
