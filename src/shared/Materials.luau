--!strict
-- The 19 material slimes (docs/MATERIALS.md): a rare appearance on hatching, next to Dual and Secret.
-- Each is the slime body drawn in a material (the owner's material stage, tools/slime/materials.luau).
-- The look data is for the client; the server only needs id, tier, weight and the sell base.

local Config = if script then require(script.Parent.Config) else require("./Config")

local Materials = {}

-- How the client draws it: "mirror" (a SurfaceAppearance with the chrome reflection map, metalness 1),
-- "surface" (a SurfaceAppearance, see-through), "roblox" (a Roblox material on the MeshPart).
export type Material = {
	id: string,
	name: string,
	-- "common", "rare" or "precious".
	tier: string,
	-- The pick's weight and the sell base, both from Config.Material by tier.
	weight: number,
	sellBase: number,
	assetId: string,
	draw: string,
	-- The Enum.Material name for draw "roblox" (nil otherwise).
	robloxMaterial: string?,
	-- A hex colour for "own colour" materials; nil for tinted ones (they take the slime's colour).
	colour: string?,
	tinted: boolean,
	metalness: number,
	roughness: number?,
	transparency: number,
	-- The outline hull is the drawn colour x Config.Material.HullShade; off for Neon, Force Field and Glass.
	hull: boolean,
}

-- { id, name, tier, draw, roblox material, colour, metalness, roughness, transparency, hull }
-- in the doc's table order. A nil colour is a tinted material.
local PLAN: { { any } } = {
	{ "gold", "Gold", "precious", "mirror", nil, "#ffcf5a", 1, 0.03, 0, true },
	{ "silver", "Silver", "precious", "mirror", nil, "#e9ecf0", 1, 0.03, 0, true },
	{ "chrome", "Chrome", "precious", "mirror", nil, "#ffffff", 1, 0.03, 0, true },
	{ "ice", "Ice", "rare", "surface", nil, "#cfefff", 0, 0.03, 0.35, true },
	{ "jelly", "Jelly", "rare", "surface", nil, nil, 0, 0.10, 0.35, true },
	{ "glass", "Glass", "rare", "roblox", "Glass", nil, 0, nil, 0.4, false },
	{ "neon", "Neon", "rare", "roblox", "Neon", nil, 0, nil, 0, false },
	{ "forcefield", "Force Field", "rare", "roblox", "ForceField", nil, 0, nil, 0, false },
	{ "lava", "Lava", "rare", "roblox", "CrackedLava", "#d8402f", 0, nil, 0, true },
	{ "wood", "Wood", "common", "roblox", "Wood", "#a0703f", 0, nil, 0, true },
	{ "marble", "Marble", "common", "roblox", "Marble", "#e9e6df", 0, nil, 0, true },
	{ "brick", "Brick", "common", "roblox", "Brick", "#a5523c", 0, nil, 0, true },
	{ "granite", "Granite", "common", "roblox", "Granite", "#8d8780", 0, nil, 0, true },
	{ "mud", "Mud", "common", "roblox", "Mud", "#5a4532", 0, nil, 0, true },
	{ "fabric", "Fabric", "common", "roblox", "Fabric", nil, 0, nil, 0, true },
	{ "sand", "Sand", "common", "roblox", "Sand", "#e0c58f", 0, nil, 0, true },
	{ "grass", "Grass", "common", "roblox", "Grass", "#5ea53e", 0, nil, 0, true },
	{ "clayroof", "Clay Roof", "common", "roblox", "ClayRoofTiles", "#b5563a", 0, nil, 0, true },
	{ "leather", "Leather", "common", "roblox", "Leather", "#6b4026", 0, nil, 0, true },
}

Materials.List = {} :: { Material }

local byId: { [string]: Material } = {}
for _, row in PLAN do
	local tier = row[3] :: string
	local material: Material = {
		id = row[1],
		name = row[2],
		tier = tier,
		weight = (Config.Material.TierWeight :: any)[tier],
		sellBase = (Config.Material.SellBase :: any)[tier],
		assetId = "slime.material." .. row[1],
		draw = row[4],
		robloxMaterial = row[5],
		colour = row[6],
		tinted = row[6] == nil,
		metalness = row[7],
		roughness = row[8],
		transparency = row[9],
		hull = row[10],
	}
	table.insert(Materials.List, material)
	byId[material.id] = material
end

function Materials.get(id: string): Material?
	return byId[id]
end

function Materials.weight(material: Material): number
	return material.weight
end

return Materials
