--!nocheck
-- A second stage beside the slime stage in the MapWork place (`node tools/studio_mcp.js run`, Edit): the
-- slime body in the materials the owner kept (2026-10-29), labelled. Re-runnable: it replaces
-- Workspace.SlimeMaterials.
--
-- Front row: metals and see-through looks on a SurfaceAppearance. Each metal twice, for the owner to
-- compare: "engine" = standard PBR (metalness 1, the measured base colour, roughness 0.10) - Roblox
-- reflects only a blurred sky, so it reads milky; "Mirror" = metalness 1, roughness 0.03 and the
-- chrome reflection map (tools/skins/make_mirror.ps1: bright sky above, dark horizon line at the widest
-- ring, ground below) tinted per metal. Ice and Jelly see-through. Back row: Roblox's own materials,
-- with their built-in maps and gloss, in a natural colour.
-- Maps (owner's account): white 71688274727636 (also metalness 1), normal 79029102102054, mirror
-- 138184721337623; roughness 0.03 135625603344269, 0.10 105770337560670.

local IS = game:GetService("InsertService")
local WHITE = "rbxassetid://71688274727636"
local NORMAL = "rbxassetid://79029102102054"
local MIRROR = "rbxassetid://138184721337623"
local R003 = "rbxassetid://135625603344269"
local R010 = "rbxassetid://105770337560670"
local HULL_SHADE = 0.6
local HEIGHT = 3
local BASE = Vector3.new(75, 300, -800)
local NAVY = "#1b4fd8"

-- { name, colour, colour map, metal, roughness map, transparency }
local LOOKS = {
	{ "Gold", "#ffe29b", WHITE, true, R010, 0 },
	{ "Gold Mirror", "#ffcf5a", MIRROR, true, R003, 0 },
	{ "Silver", "#fcfaf5", WHITE, true, R010, 0 },
	{ "Silver Mirror", "#e9ecf0", MIRROR, true, R003, 0 },
	{ "Chrome", "#c4c5c5", WHITE, true, R003, 0 },
	{ "Chrome Mirror", "#ffffff", MIRROR, true, R003, 0 },
	{ "Ice", "#cfefff", WHITE, false, R003, 0.35 },
	{ "Jelly", NAVY, WHITE, false, R010, 0.35 },
}

-- Roblox materials kept, with a natural colour
local KEPT = {
	{ "Neon", "#3f9ff0" },
	{ "Wood", "#a0703f" },
	{ "Marble", "#e9e6df" },
	{ "CrackedLava", "#d8402f" },
	{ "Brick", "#a5523c" },
	{ "Granite", "#8d8780" },
	{ "Mud", "#5a4532" },
	{ "Fabric", "#d8402f" },
	{ "Sand", "#e0c58f" },
	{ "Grass", "#5ea53e" },
	{ "Glass", "#bfe6ff" },
	{ "ForceField", "#3f9ff0" },
	{ "ClayRoofTiles", "#b5563a" },
	{ "Leather", "#6b4026" },
}
local SEE_THROUGH = { Glass = 0.4 }
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
plate.Size = Vector3.new(66, 1, 34)
plate.CFrame = CFrame.new(BASE + Vector3.new(0, -0.5, -5))
plate.Color = Color3.fromRGB(122, 178, 92)
plate.Material = Enum.Material.Grass
plate.Parent = root

local bodySrc = IS:LoadAsset(71117254607762):FindFirstChildWhichIsA("MeshPart", true)
local hullSrc = IS:LoadAsset(99817746239640):FindFirstChildWhichIsA("MeshPart", true)

local function label(m, text)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 22)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.3, 0)
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

for i, p in LOOKS do
	make(p[1], p[2], slot(i), function(body, col)
		local sa = Instance.new("SurfaceAppearance")
		sa.ColorMap = p[3]
		sa.NormalMap = NORMAL
		sa.RoughnessMap = p[5]
		if p[4] then
			sa.MetalnessMap = WHITE
		end
		sa.Color = col
		sa.Parent = body
		body.Transparency = p[6]
	end, p[6] == 0)
end
-- Roblox's own materials start on the next row
for k, p in KEPT do
	local mat = Enum.Material[p[1]]
	make(p[1], p[2], slot(11 + k), function(body)
		body.Material = mat
		body.Transparency = SEE_THROUGH[p[1]] or 0
	end, not NO_HULL[p[1]])
end
root.Parent = workspace
return ("SlimeMaterials built: %d looks, %d Roblox materials"):format(#LOOKS, #KEPT)
