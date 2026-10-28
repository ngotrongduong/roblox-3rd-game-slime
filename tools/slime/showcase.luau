--!nocheck
-- Puts the slimes on a stage high above the map in the MapWork place (Studio MCP execute_luau, Edit),
-- for looking at them under the game's real light: the 11 single colours in the front row, the 55
-- Duals behind in 5 rows of 11 in docs/DUALS.md's order (left to right seen from the front).
-- Re-runnable: it replaces Workspace.SlimeShowcase.
--
-- The look (owner, 2026-10-28): one shared body, nothing painted for light - the highlights and the
-- shading come from the light (Lighting.EnvironmentSpecularScale 1) on a glossy SurfaceAppearance
-- (flat roughness 0.10). Singles: Colours.luau's swatch as the tint of a white map. Duals: the skin
-- from tools/skins/make_skins.py (ids in art/models/slime_body/skins/asset_ids.json) untinted. The
-- outline hull is the body colour x 0.6.
--
-- Assets (owner's account): SlimeBody model 71117254607762, SlimeBodyOutline model 99817746239640
-- (art/models/slime_body/*.fbx, all-round UV, 2026-10-29); white 71688274727636, flat normal
-- 79029102102054, roughness 0.10 = 105770337560670 (16x16 PNGs).
-- The imported MeshParts carry a rotated PivotOffset (Blender's Z-up rig): reset it before moving them.

local IS = game:GetService("InsertService")
local WHITE = "rbxassetid://71688274727636"
local NORMAL = "rbxassetid://79029102102054"
local ROUGH = "rbxassetid://105770337560670"
local HULL_SHADE = 0.6
local HEIGHT = 3
local BASE = Vector3.new(0, 300, -800)

local SWATCH = {
	black = "#2b2b33",
	gray = "#9aa0a8",
	navy = "#1b4fd8",
	purple = "#8a4fd0",
	red = "#d8402f",
	orange = "#f08a24",
	yellow = "#f2d13d",
	green = "#54b848",
	pink = "#f27fb6",
	blue = "#3f9ff0",
	white = "#f5f2ea",
}
local SINGLES = { "black", "gray", "navy", "purple", "red", "orange", "yellow", "green", "pink", "blue", "white" }
-- docs/DUALS.md: { skin image id, body colour } for #1..#55
local DUALS = {
	{ 89952599143576, "black" },
	{ 78911880301169, "navy" },
	{ 135602593178768, "purple" },
	{ 122329431100644, "red" },
	{ 98681283390195, "orange" },
	{ 83169753905851, "yellow" },
	{ 87842064303233, "green" },
	{ 93058163770764, "pink" },
	{ 120307790880431, "black" },
	{ 83942793414374, "white" },
	{ 120768957608783, "gray" },
	{ 136014969272863, "gray" },
	{ 137382364771985, "red" },
	{ 83409385187979, "gray" },
	{ 74522284829798, "gray" },
	{ 93998607563144, "green" },
	{ 138083391003592, "gray" },
	{ 71315372895466, "blue" },
	{ 113287707481993, "white" },
	{ 93989830474457, "navy" },
	{ 132460595399220, "red" },
	{ 106495854459969, "navy" },
	{ 123335344714942, "navy" },
	{ 92739554649735, "green" },
	{ 116536890329904, "navy" },
	{ 132243388481469, "navy" },
	{ 136574783335565, "navy" },
	{ 116419390796139, "purple" },
	{ 130912901670589, "purple" },
	{ 93444734673332, "purple" },
	{ 78624296327420, "purple" },
	{ 71460078306755, "pink" },
	{ 106735662034787, "purple" },
	{ 136884962087543, "purple" },
	{ 82709759548786, "red" },
	{ 115370966662338, "red" },
	{ 81654410845000, "red" },
	{ 89055759958890, "pink" },
	{ 96722304481260, "red" },
	{ 120471321624837, "red" },
	{ 107469466269169, "yellow" },
	{ 103958460706197, "orange" },
	{ 129886566891760, "orange" },
	{ 78077936913306, "blue" },
	{ 78124300533277, "orange" },
	{ 99976669173207, "green" },
	{ 134950817122563, "yellow" },
	{ 135887544093214, "blue" },
	{ 117446377654778, "yellow" },
	{ 75084361754596, "pink" },
	{ 107541366868093, "blue" },
	{ 80563759483953, "green" },
	{ 83241373341690, "pink" },
	{ 90956872420325, "pink" },
	{ 113397081813545, "white" },
}

local old = workspace:FindFirstChild("SlimeShowcase")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "SlimeShowcase"
local plate = Instance.new("Part")
plate.Name = "Stage"
plate.Anchored = true
plate.Size = Vector3.new(66, 1, 48)
plate.CFrame = CFrame.new(BASE + Vector3.new(0, -0.5, -11))
plate.Color = Color3.fromRGB(122, 178, 92)
plate.Material = Enum.Material.Grass
plate.Parent = root

local bodySrc = IS:LoadAsset(71117254607762):FindFirstChildWhichIsA("MeshPart", true)
local hullSrc = IS:LoadAsset(99817746239640):FindFirstChildWhichIsA("MeshPart", true)

local function make(name, map, tint, bodyHex, pos)
	local m = Instance.new("Model")
	m.Name = name
	local body = bodySrc:Clone()
	local hull = hullSrc:Clone()
	body.Name = "SlimeBody"
	hull.Name = "SlimeBodyOutline"
	for _, c in { body, hull } do
		c.Anchored = true
		c.CanCollide = false
		c.PivotOffset = CFrame.new()
		c.CFrame = CFrame.new(0, 0.49996650218963623, 0)
		c.Parent = m
	end
	local col = Color3.fromHex(bodyHex)
	body.Color = tint
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = map
	sa.NormalMap = NORMAL
	sa.RoughnessMap = ROUGH
	sa.Color = tint
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

for i, id in SINGLES do
	make("Slime_" .. id, WHITE, Color3.fromHex(SWATCH[id]), SWATCH[id], BASE + Vector3.new((i - 6) * 5.5, 0, 6))
end
for n, d in DUALS do
	local col, row = (n - 1) % 11, (n - 1) // 11
	make(
		string.format("Dual_%02d", n),
		"rbxassetid://" .. d[1],
		Color3.new(1, 1, 1),
		SWATCH[d[2]],
		BASE + Vector3.new((col - 5) * 5.5, 0, -2 - row * 6.5)
	)
	if n % 11 == 0 then
		task.wait()
	end
end
game:GetService("Lighting").EnvironmentSpecularScale = 1
root.Parent = workspace
return "SlimeShowcase built: " .. #SINGLES .. " singles, " .. #DUALS .. " duals"
