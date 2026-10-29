--!nocheck
-- The movement lab in the MapWork place (`node tools/studio_mcp.js run`, Edit): eight lanes of 40 studs, one slime in each
-- hopping (or gliding) from one end to the other and back forever, each lane its own style of motion, each with a big sign
-- on the floor at its start (letter and name, and the numbers on two small lines). The stage floats at x 160, y 300,
-- z -800 beside the other review stages, with a walkway from the materials stage (x 75). Re-runnable: it replaces
-- Workspace.SlimeMotionLab and StarterPlayerScripts.SlimeMotionLab (and nothing else).
--
-- It runs its OWN copies of the motion code (tools/slime/hop_lab_client.luau with the lane table
-- tools/slime/hop_lab_lanes.luau; the face is the game's SlimeFace), so the game's SlimeActor / SlimeMotion are untouched.
-- The shared modules the face needs (ReplicatedStorage.Shared.{Config, Expressions, FaceArt, SlimeShape}) are installed
-- only when missing: the emotion stage's copies are used otherwise.
-- Afterwards it steps the lab by hand in Edit mode so the stage can be shot without a play test.
--
-- Assets as in emotions.luau: SlimeBody model 71117254607762, outline 99817746239640, white 71688274727636, flat
-- normal 79029102102054, roughness 0.10 = 105770337560670.
-- Expects locals CONFIG_SRC, EXPRESSIONS_SRC, FACEART_SRC, SLIMESHAPE_SRC, SLIMEFACE_SRC, LANES_SRC, LAB_SRC.

local IS = game:GetService("InsertService")
local RS = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local WHITE = "rbxassetid://71688274727636"
local NORMAL = "rbxassetid://79029102102054"
local ROUGH = "rbxassetid://105770337560670"
local HULL_SHADE = 0.6
local HEIGHT = 3 -- the largest village slime (Config.VillageClient.BodyHeight)
local CENTRE = Vector3.new(160, 300, -800)
local PLATE_X, PLATE_Z = 80, 80
local FLOOR_Y = CENTRE.Y + 0.05 -- the lane strips lie 0.05 above the plate; the feet stand on them
local LANE_START_X = 140
local SIGN_X = 129 -- the middle of the sign (it ends at 138, where the lane's path begins)
local SIGN_LENGTH, SIGN_DEPTH = 18, 7

local function install(parent, class, name, src, onlyIfMissing)
	local old = parent:FindFirstChild(name)
	if old then
		if onlyIfMissing then
			return old
		end
		old:Destroy()
	end
	local s = Instance.new(class)
	s.Name = name
	s.Source = src
	s.Parent = parent
	return s
end

-- the code
local shared = RS:FindFirstChild("Shared")
if not shared then
	shared = Instance.new("Folder")
	shared.Name = "Shared"
	shared.Parent = RS
end
install(shared, "ModuleScript", "Config", CONFIG_SRC, true)
install(shared, "ModuleScript", "Expressions", EXPRESSIONS_SRC, true)
install(shared, "ModuleScript", "FaceArt", FACEART_SRC, true)
install(shared, "ModuleScript", "SlimeShape", SLIMESHAPE_SRC, true)
local oldClient = SPS:FindFirstChild("SlimeMotionLab")
if oldClient then
	oldClient:Destroy()
end
local client = Instance.new("Folder")
client.Name = "SlimeMotionLab"
install(client, "ModuleScript", "SlimeFace", SLIMEFACE_SRC)
install(client, "ModuleScript", "Lanes", LANES_SRC)
install(client, "ModuleScript", "LabRun", LAB_SRC)
install(
	client,
	"LocalScript",
	"Stage",
	[[
local stage = workspace:WaitForChild("SlimeMotionLab", 10)
if not stage then
	return
end
local Lab = require(script.Parent.LabRun)
Lab.build(stage)
Lab.start()
-- one way out: the stage going away (a rebuild, the place closing) takes the loop and the faces down
stage.Destroying:Connect(Lab.stop)
print("[GooLineage] movement lab running")
]]
)
client.Parent = SPS
local Lanes = require(client.Lanes)

-- the stage
local old = workspace:FindFirstChild("SlimeMotionLab")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "SlimeMotionLab"
local plate = Instance.new("Part")
plate.Name = "Stage"
plate.Anchored = true
plate.Size = Vector3.new(PLATE_X, 1, PLATE_Z)
plate.CFrame = CFrame.new(CENTRE + Vector3.new(0, -0.5, 0))
plate.Color = Color3.fromRGB(122, 178, 92)
plate.Material = Enum.Material.Grass
plate.Parent = root
-- a walkway over the gap to the materials stage (it ends at x 108; this stage starts at x 120)
local bridge = plate:Clone()
bridge.Name = "Bridge"
bridge.Size = Vector3.new(12, 1, 12)
bridge.CFrame = CFrame.new(114, CENTRE.Y - 0.5, CENTRE.Z)
bridge.Parent = root

local bodySrc = IS:LoadAsset(71117254607762):FindFirstChildWhichIsA("MeshPart", true)
local hullSrc = IS:LoadAsset(99817746239640):FindFirstChildWhichIsA("MeshPart", true)

local function textLine(parent, text, y0, h, font)
	local t = Instance.new("TextLabel")
	t.Position = UDim2.fromScale(0.02, y0)
	t.Size = UDim2.fromScale(0.96, h)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Font = font
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent
end

local function sign(spec, pos)
	local p = Instance.new("Part")
	p.Name = "Sign_" .. spec.key
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	-- (the Top face's UI runs along the part's -Z: turn the part so the text reads along +X; see emotions.luau)
	p.Size = Vector3.new(SIGN_DEPTH, 0.2, SIGN_LENGTH)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, -math.pi / 2, 0)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = p
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
	back.BackgroundTransparency = 0.25
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = back
	textLine(back, spec.key .. "   " .. spec.name, 0.02, 0.32, Enum.Font.FredokaOne)
	for i, line in Lanes.describe(spec) do
		textLine(back, line, 0.35 + (i - 1) * 0.16, 0.14, Enum.Font.GothamMedium)
	end
	p.Parent = root
end

for i, spec in Lanes.List do
	local z = CENTRE.Z + (i - (#Lanes.List + 1) / 2) * Lanes.Spacing
	-- the lane's path
	local strip = Instance.new("Part")
	strip.Name = "Lane_" .. spec.key
	strip.Anchored = true
	strip.CanCollide = false
	strip.Size = Vector3.new(Lanes.Length + 3, 0.1, 5)
	strip.CFrame = CFrame.new(LANE_START_X + Lanes.Length / 2, CENTRE.Y, z)
	strip.Color = Color3.fromRGB(219, 200, 150)
	strip.Material = Enum.Material.Sand
	strip.Parent = root
	sign(spec, Vector3.new(SIGN_X, CENTRE.Y + 0.1, z))

	local colour = Color3.fromHex(spec.colour)
	local m = Instance.new("Model")
	m.Name = "Lane_" .. spec.key
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
	body.Color = colour
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = WHITE
	sa.NormalMap = NORMAL
	sa.RoughnessMap = ROUGH
	sa.Color = colour
	sa.Parent = body
	hull.Color = Color3.new(colour.R * HULL_SHADE, colour.G * HULL_SHADE, colour.B * HULL_SHADE)
	hull.Material = Enum.Material.SmoothPlastic
	hull.CastShadow = false
	m.WorldPivot = CFrame.new()
	m:ScaleTo(HEIGHT)
	-- standing at the lane's start, facing +X (the look vector)
	m:PivotTo(CFrame.new(LANE_START_X, FLOOR_Y, z) * CFrame.Angles(0, -math.pi / 2, 0))
	m:SetAttribute("Lane", i)
	m.Parent = root
end
game:GetService("Lighting").EnvironmentSpecularScale = 1
root.Parent = workspace

-- put every slime in its first pose, so the lab can be shot in Edit mode
local Lab = require(client.LabRun)
Lab.build(root)
local urls = {}
for _, s in require(shared.FaceArt).Sprites do
	table.insert(urls, "rbxassetid://" .. s.id)
end
game:GetService("ContentProvider"):PreloadAsync(urls)
-- (the pose is only for pictures: the loop stays off in Edit mode and Stage starts its own in a play test)
for _ = 1, 30 do
	Lab.step(1 / 60)
end
return ("SlimeMotionLab built: %d lanes"):format(#Lanes.List)
