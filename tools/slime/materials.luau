--!nocheck
-- A second stage beside the slime stage in the MapWork place (Studio MCP execute_luau, Edit or
-- `node tools/studio_mcp.js run`): the slime body in every material we can make, labelled, for the
-- owner to pick from. Re-runnable: it replaces Workspace.SlimeMaterials.
--
-- Front two rows: physically based looks on a SurfaceAppearance with the standard values (metals:
-- metalness 1 and the usual measured base colours - gold 255,226,155, silver 252,250,245 ... -
-- polished roughness 0.2, chrome 0.03, brushed 0.35-0.5; non-metals: metalness 0, roughness from
-- 0.03 glazed to 0.9 rubber; glass, ice, crystal and jelly see-through). Back rows: every Roblox
-- material, with its own built-in maps and gloss, in a natural colour.
-- Flat maps (owner's account): white 71688274727636 (also metalness 1), normal 79029102102054;
-- roughness 0.03 135625603344269, 0.10 105770337560670, 0.20 137845974952300, 0.35 111496012830507,
-- 0.50 91392044804647, 0.80 103459254064764, 0.90 138017851681358.

local IS = game:GetService("InsertService")
local WHITE = "rbxassetid://71688274727636"
local NORMAL = "rbxassetid://79029102102054"
local R = {
	[0.03] = "rbxassetid://135625603344269",
	[0.10] = "rbxassetid://105770337560670",
	[0.20] = "rbxassetid://137845974952300",
	[0.35] = "rbxassetid://111496012830507",
	[0.50] = "rbxassetid://91392044804647",
	[0.80] = "rbxassetid://103459254064764",
	[0.90] = "rbxassetid://138017851681358",
}
local HULL_SHADE = 0.6
local HEIGHT = 3
local BASE = Vector3.new(75, 300, -800)
local NAVY = "#1b4fd8"

-- { name, colour, metal, roughness, transparency }
local PBR = {
	{ "Gold", "#ffe29b", true, 0.20, 0 },
	{ "Silver", "#fcfaf5", true, 0.20, 0 },
	{ "Platinum", "#d5d0c8", true, 0.20, 0 },
	{ "Copper", "#fad0c0", true, 0.20, 0 },
	{ "Nickel", "#d3cbbe", true, 0.20, 0 },
	{ "Chrome", "#c4c5c5", true, 0.03, 0 },
	{ "Titanium", "#c1bab1", true, 0.35, 0 },
	{ "Aluminium", "#f5f6f6", true, 0.35, 0 },
	{ "Iron", "#c6c6c8", true, 0.50, 0 },
	{ "Glossy", NAVY, false, 0.10, 0 },
	{ "Satin", NAVY, false, 0.35, 0 },
	{ "Matte", NAVY, false, 0.80, 0 },
	{ "Rubber", NAVY, false, 0.90, 0 },
	{ "Porcelain", "#f7f7f2", false, 0.03, 0 },
	{ "Pearl", "#f0ebe3", false, 0.20, 0 },
	{ "Obsidian", "#15121a", false, 0.03, 0 },
	{ "Clay", "#c87a4f", false, 0.90, 0 },
	{ "Jelly", NAVY, false, 0.10, 0.35 },
	{ "Glass", "#ffffff", false, 0.03, 0.7 },
	{ "Ice", "#cfefff", false, 0.10, 0.3 },
	{ "Crystal", "#e7d7ff", false, 0.03, 0.45 },
}

-- natural colours for Roblox's own materials (anything not listed gets navy)
local NATURAL = {
	Plastic = NAVY,
	SmoothPlastic = NAVY,
	Neon = "#3f9ff0",
	Wood = "#a0703f",
	WoodPlanks = "#a77b4a",
	Marble = "#e9e6df",
	Slate = "#6b6e73",
	Concrete = "#a3a29c",
	Granite = "#8d8780",
	Brick = "#a5523c",
	Pebble = "#a49b8d",
	Cobblestone = "#8a857c",
	Rock = "#7d7468",
	Sandstone = "#d1a873",
	Basalt = "#3c3b3f",
	CrackedLava = "#d8402f",
	Asphalt = "#3a3a3d",
	LeafyGrass = "#5a9a3c",
	Salt = "#e8e4dc",
	Limestone = "#d8cfb8",
	Pavement = "#8f8f8f",
	Snow = "#f4f7fb",
	Mud = "#5a4532",
	Ground = "#6e5a3e",
	Glacier = "#a8d8f0",
	Grass = "#5ea53e",
	Sand = "#e0c58f",
	Fabric = "#d8402f",
	Ice = "#bfe6ff",
	CorrodedMetal = "#7b5a3a",
	DiamondPlate = "#a7a9ab",
	Foil = "#ffd27a",
	Metal = "#9fa3a8",
	Glass = "#bfe6ff",
	ForceField = "#3f9ff0",
	Cardboard = "#b98d5e",
	Carpet = "#8a4fd0",
	CeramicTiles = "#e8e4dc",
	ClayRoofTiles = "#b5563a",
	RoofShingles = "#5a5e66",
	Leather = "#6b4026",
	Plaster = "#ece6dc",
	Rubber = "#2b2b33",
}
local SEE_THROUGH = { Glass = 0.4, ForceField = 0 }
local NO_HULL = { Neon = true, ForceField = true, Glass = true }

local old = workspace:FindFirstChild("SlimeMaterials")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "SlimeMaterials"
local plate = Instance.new("Part")
plate.Name = "Stage"
plate.Anchored = true
plate.Size = Vector3.new(66, 1, 56)
plate.CFrame = CFrame.new(BASE + Vector3.new(0, -0.5, -16))
plate.Color = Color3.fromRGB(122, 178, 92)
plate.Material = Enum.Material.Grass
plate.Parent = root

local bodySrc = IS:LoadAsset(71117254607762):FindFirstChildWhichIsA("MeshPart", true)
local hullSrc = IS:LoadAsset(99817746239640):FindFirstChildWhichIsA("MeshPart", true)

local function label(m, text)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(110, 22)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.3, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 60
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Parent = bb
	bb.Parent = m.SlimeBody
end

local function make(name, hex, pos, setup, hull)
	local m = Instance.new("Model")
	m.Name = name
	local body = bodySrc:Clone()
	body.Name = "SlimeBody"
	local parts = { body }
	local h
	if hull then
		h = hullSrc:Clone()
		h.Name = "SlimeBodyOutline"
		table.insert(parts, h)
	end
	for _, c in parts do
		c.Anchored = true
		c.CanCollide = false
		c.PivotOffset = CFrame.new()
		c.CFrame = CFrame.new(0, 0.49996650218963623, 0)
		c.Parent = m
	end
	local col = Color3.fromHex(hex)
	body.Color = col
	setup(body, col)
	if h then
		h.Color = Color3.new(col.R * HULL_SHADE, col.G * HULL_SHADE, col.B * HULL_SHADE)
		h.Material = Enum.Material.SmoothPlastic
		h.CastShadow = false
	end
	-- (no PrimaryPart: the pivot must stay at the feet)
	m.WorldPivot = CFrame.new()
	m:ScaleTo(HEIGHT)
	m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.pi, 0))
	label(m, name)
	m.Parent = root
end

local function slot(i)
	local col, row = (i - 1) % 11, (i - 1) // 11
	return BASE + Vector3.new((col - 5) * 5.5, 0, 6 - row * 7)
end

for i, p in PBR do
	make(p[1], p[2], slot(i), function(body, col)
		local sa = Instance.new("SurfaceAppearance")
		sa.ColorMap = WHITE
		sa.NormalMap = NORMAL
		sa.RoughnessMap = R[p[4]]
		if p[3] then
			sa.MetalnessMap = WHITE
		end
		sa.Color = col
		sa.Parent = body
		body.Transparency = p[5]
	end, p[5] == 0)
end
-- Roblox's own materials start on a fresh row
local i = 22
local skipped = {}
for _, mat in Enum.Material:GetEnumItems() do
	if mat == Enum.Material.Air or mat == Enum.Material.Water then
		continue
	end
	local ok = pcall(function()
		local probe = Instance.new("Part")
		probe.Material = mat
		probe:Destroy()
	end)
	if not ok then
		table.insert(skipped, mat.Name)
		continue
	end
	i += 1
	make(mat.Name, NATURAL[mat.Name] or NAVY, slot(i), function(body)
		body.Material = mat
		body.Transparency = SEE_THROUGH[mat.Name] or 0
	end, not NO_HULL[mat.Name])
	if i % 11 == 0 then
		task.wait()
	end
end
root.Parent = workspace
return ("SlimeMaterials built: %d looks, %d Roblox materials; skipped %s"):format(#PBR, i - 22, table.concat(skipped, ","))
