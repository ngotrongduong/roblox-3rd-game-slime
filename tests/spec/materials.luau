local Config = require("../../src/shared/Config")
local Materials = require("../../src/shared/Materials")

return function(T)
	T.test("19 materials in the doc's tiers, weights and sell bases", function()
		T.eq(#Materials.List, 19)
		local tiers = { common = 0, rare = 0, precious = 0 }
		local total = 0
		for _, m in Materials.List do
			tiers[m.tier] += 1
			total += m.weight
			T.eq(Materials.get(m.id), m)
			T.eq(m.assetId, "slime.material." .. m.id)
			if m.tier == "common" then
				T.eq(m.weight, 6)
				T.eq(m.sellBase, 150)
			elseif m.tier == "rare" then
				T.eq(m.weight, 3)
				T.eq(m.sellBase, 300)
			else
				T.eq(m.weight, 1)
				T.eq(m.sellBase, 800)
			end
		end
		T.eq(tiers.common, 10)
		T.eq(tiers.rare, 6)
		T.eq(tiers.precious, 3)
		T.eq(total, 10 * 6 + 6 * 3 + 3)
		T.eq(Config.Material.SellBase.common, 150)
	end)

	T.test("look data from the doc's table", function()
		local gold = Materials.get("gold") :: any
		T.eq(gold.draw, "mirror")
		T.eq(gold.colour, "#ffcf5a")
		T.eq(gold.metalness, 1)
		T.eq(gold.roughness, 0.03)
		T.ok(not gold.tinted)
		local jelly = Materials.get("jelly") :: any
		T.eq(jelly.draw, "surface")
		T.ok(jelly.tinted)
		T.eq(jelly.transparency, 0.35)
		T.eq(jelly.roughness, 0.10)
		local glass = Materials.get("glass") :: any
		T.eq(glass.robloxMaterial, "Glass")
		T.eq(glass.transparency, 0.4)
		T.ok(glass.tinted)
		T.eq(Materials.get("clayroof").robloxMaterial, "ClayRoofTiles")
		T.eq(Materials.get("lava").robloxMaterial, "CrackedLava")
		T.eq(Materials.get("lava").colour, "#d8402f")
		-- the outline hull is off for exactly Neon, Force Field and Glass
		for _, m in Materials.List do
			T.eq(m.hull, not (m.id == "neon" or m.id == "forcefield" or m.id == "glass"), m.id)
			if m.draw == "roblox" then
				T.ok(m.robloxMaterial ~= nil, m.id)
			end
		end
		-- tinted: Jelly, Glass, Neon, Force Field, Fabric
		local tinted = 0
		for _, m in Materials.List do
			if m.tinted then
				tinted += 1
			end
		end
		T.eq(tinted, 5)
	end)
end
