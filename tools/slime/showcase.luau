--!nocheck
-- Puts the 11 single-colour slimes on a stage high above the map in the MapWork place (Studio MCP
-- execute_luau, Edit), for looking at the slime body under the game's real light. Re-runnable: it
-- replaces Workspace.SlimeShowcase.
--
-- The look (owner, 2026-10-28): one shared body, the colour is Colours.luau's swatch, nothing painted
-- on - the highlights and the shading come from the light (Lighting.EnvironmentSpecularScale 1) on a
-- glossy SurfaceAppearance (flat roughness 0.10). The outline hull is the body colour x 0.6.
--
-- Assets (owner's account): SlimeBody model 89067624889078, SlimeBodyOutline model 125941562766782
-- (art/models/slime_body/*.fbx); white 71688274727636, flat normal 79029102102054, roughness 0.03 /
-- 0.10 / 0.20 = 135625603344269 / 105770337560670 / 137845974952300 (16x16 PNGs).
-- The imported MeshParts carry a rotated PivotOffset (Blender's Z-up rig): reset it before moving them.

local IS = game:GetService("InsertService")
local WHITE = "rbxassetid://71688274727636"
local NORMAL = "rbxassetid://79029102102054"
local ROUGH = "rbxassetid://105770337560670"
local HULL_SHADE = 0.6
local HEIGHT = 3
local BASE = Vector3.new(0, 300, -800)

local old = workspace:FindFirstChild("SlimeShowcase")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "SlimeShowcase"
local plate = Instance.new("Part")
plate.Name = "Stage"
plate.Anchored = true
plate.Size = Vector3.new(70, 1, 30)
plate.CFrame = CFrame.new(BASE - Vector3.new(0, 0.5, 0))
plate.Color = Color3.fromRGB(122, 178, 92)
plate.Material = Enum.Material.Grass
plate.Parent = root

local bodySrc = IS:LoadAsset(89067624889078):FindFirstChild("SlimeBody")
local hullSrc = IS:LoadAsset(125941562766782):FindFirstChild("SlimeBodyOutline")
-- Colours.luau's swatches, in its order.
local COLS = {
	{ "black", "#2b2b33" },
	{ "gray", "#9aa0a8" },
	{ "navy", "#1b4fd8" },
	{ "purple", "#8a4fd0" },
	{ "red", "#d8402f" },
	{ "orange", "#f08a24" },
	{ "yellow", "#f2d13d" },
	{ "green", "#54b848" },
	{ "pink", "#f27fb6" },
	{ "blue", "#3f9ff0" },
	{ "white", "#f5f2ea" },
}

local function make(name, hex, pos)
	local m = Instance.new("Model")
	m.Name = name
	local body = bodySrc:FindFirstChild("SlimeBody"):Clone()
	local hull = hullSrc:FindFirstChild("SlimeBodyOutline"):Clone()
	for _, c in { body, hull } do
		c.Anchored = true
		c.CanCollide = false
		c.PivotOffset = CFrame.new()
		c.CFrame = CFrame.new(0, 0.49996650218963623, 0)
		c.Parent = m
	end
	local col = Color3.fromHex(hex)
	body.Color = col
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = WHITE
	sa.NormalMap = NORMAL
	sa.RoughnessMap = ROUGH
	sa.Color = col
	sa.Parent = body
	hull.Color = Color3.new(col.R * HULL_SHADE, col.G * HULL_SHADE, col.B * HULL_SHADE)
	hull.Material = Enum.Material.SmoothPlastic
	hull.CastShadow = false
	m.WorldPivot = CFrame.new()
	m:ScaleTo(HEIGHT)
	-- the body's front is -Z: turn it to face a camera on the +Z side
	m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.pi, 0))
	m.Parent = root
end

for i, c in COLS do
	make("Slime_" .. c[1], c[2], BASE + Vector3.new((i - 6) * 5, 0, 4))
end
game:GetService("Lighting").EnvironmentSpecularScale = 1
root.Parent = workspace
return "SlimeShowcase built"
