local DualDesigns = require("../../src/shared/DualDesigns")
local SkinIds = require("../../src/shared/SkinIds")

return function(T)
	T.test("all 55 Dual definitions have their uploaded skin", function()
		T.eq(#DualDesigns.List, 55)
		local seen = {}
		for _, design in DualDesigns.List do
			local id = SkinIds.get(design.id)
			T.ok(type(id) == "number" and id > 0, design.id)
			T.ok(not seen[id], "duplicate skin for " .. design.id)
			seen[id] = true
		end
		T.eq(SkinIds.get("not-a-dual"), nil)
	end)

	T.test("specific skin numbers match the owner's upload manifest", function()
		T.eq(SkinIds.get(DualDesigns.List[1].id), 89952599143576)
		T.eq(SkinIds.get(DualDesigns.List[55].id), 113397081813545)
	end)
end
