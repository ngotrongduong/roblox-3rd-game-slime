--!nocheck
-- The emotion review stage in the MapWork place (`node tools/studio_mcp.js run`, Edit): one navy slime per emotion in
-- four rows of six, each labelled on the floor, each looping its emotion and the body motion that goes with it, eyes
-- following the nearest player. A walkway joins it to the slime stage (tools/slime/showcase.luau). Re-runnable: it
-- replaces Workspace.SlimeEmotions and the scripts it installs.
--
-- The face code it runs is the repo's own: the sources are passed in as strings and become ModuleScripts
--   ReplicatedStorage.Shared.{Config, Expressions, FaceArt, SlimeShape, SlimeMotion}   (src/shared)
--   StarterPlayer.StarterPlayerScripts.SlimeFaceStage.{SlimeFace, SlimeActor, Stage}   (src/client, tools/slime/emotions_client.luau)
-- so a play test shows exactly what the game will. Build with tools/slime/emotions.ps1 (it passes the files).
-- Afterwards it steps the actors by hand in Edit mode so the faces can be shot without a play test.
--
-- Assets as in showcase.luau: SlimeBody model 71117254607762, outline 99817746239640, white 71688274727636, flat
-- normal 79029102102054, roughness 0.10 = 105770337560670.
-- Expects locals CONFIG_SRC, EXPRESSIONS_SRC, FACEART_SRC, SLIMESHAPE_SRC, SLIMEMOTION_SRC, SLIMEFACE_SRC,
-- SLIMEACTOR_SRC, STAGE_SRC (the `NAME=file` arguments of studio_mcp.js run).

local IS = game:GetService("InsertService")
local RS = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

local WHITE = "rbxassetid://71688274727636"
local NORMAL = "rbxassetid://79029102102054"
local ROUGH = "rbxassetid://105770337560670"
local HULL_SHADE = 0.6
local HEIGHT = 3
local BASE = Vector3.new(-75, 300, -800)
local NAVY = Color3.fromHex("#1b4fd8")
local ORDER = {
	"normal", "happy", "laughing", "exciting", "wink", "admiring",
	"loved", "shy", "proud", "dare", "curious", "surprise",
	"scared", "angry", "sulking", "sad", "crying", "dizzy",
	"sleepy", "sleep", "bored", "hungry", "eating", "full",
}
local COLS, SPACING_X, SPACING_Z = 6, 9, 11

local function install(parent, class, name, src)
	local old = parent:FindFirstChild(name)
	if old then
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
install(shared, "ModuleScript", "Config", CONFIG_SRC)
install(shared, "ModuleScript", "Expressions", EXPRESSIONS_SRC)
install(shared, "ModuleScript", "FaceArt", FACEART_SRC)
install(shared, "ModuleScript", "SlimeShape", SLIMESHAPE_SRC)
install(shared, "ModuleScript", "SlimeMotion", SLIMEMOTION_SRC)
local oldClient = SPS:FindFirstChild("SlimeFaceStage")
if oldClient then
	oldClient:Destroy()
end
local client = Instance.new("Folder")
client.Name = "SlimeFaceStage"
install(client, "ModuleScript", "SlimeFace", SLIMEFACE_SRC)
install(client, "ModuleScript", "SlimeActor", SLIMEACTOR_SRC)
install(client, "LocalScript", "Stage", STAGE_SRC)
client.Parent = SPS

-- the stage
local old = workspace:FindFirstChild("SlimeEmotions")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "SlimeEmotions"
local plate = Instance.new("Part")
plate.Name = "Stage"
plate.Anchored = true
plate.Size = Vector3.new(66, 1, 44)
plate.CFrame = CFrame.new(BASE + Vector3.new(0, -0.5, -12))
plate.Color = Color3.fromRGB(122, 178, 92)
plate.Material = Enum.Material.Grass
plate.Parent = root
-- a walkway over the gap to the slime stage (66 wide at x 0)
local bridge = plate:Clone()
bridge.Name = "Bridge"
bridge.Size = Vector3.new(12, 1, 34)
bridge.CFrame = CFrame.new(Vector3.new(-37.5, BASE.Y - 0.5, BASE.Z - 5))
bridge.Parent = root

local bodySrc = IS:LoadAsset(71117254607762):FindFirstChildWhichIsA("MeshPart", true)
local hullSrc = IS:LoadAsset(99817746239640):FindFirstChildWhichIsA("MeshPart", true)

local function label(text, pos)
	local p = Instance.new("Part")
	p.Name = "Label_" .. text
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	-- (the Top face's UI runs along the part's -Z with its top toward -X: turn the part so the text reads along +X)
	p.Size = Vector3.new(2, 0.2, 7)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, -math.pi / 2, 0)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Parent = gui
	p.Parent = root
end

for i, id in ORDER do
	local col, row = (i - 1) % COLS, (i - 1) // COLS
	local pos = BASE + Vector3.new((col - (COLS - 1) / 2) * SPACING_X, 0, 6 - row * SPACING_Z)
	local m = Instance.new("Model")
	m.Name = id
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
	body.Color = NAVY
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = WHITE
	sa.NormalMap = NORMAL
	sa.RoughnessMap = ROUGH
	sa.Color = NAVY
	sa.Parent = body
	hull.Color = Color3.new(NAVY.R * HULL_SHADE, NAVY.G * HULL_SHADE, NAVY.B * HULL_SHADE)
	hull.Material = Enum.Material.SmoothPlastic
	hull.CastShadow = false
	m.WorldPivot = CFrame.new()
	m:ScaleTo(HEIGHT)
	-- the slime's front (its look vector) toward +Z, where the camera stands
	m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.pi, 0))
	m:SetAttribute("Emotion", id)
	m.Parent = root
	label(id, pos + Vector3.new(0, 0.1, 3.4))
end
game:GetService("Lighting").EnvironmentSpecularScale = 1
root.Parent = workspace

-- put every slime in its first pose, so the faces can be shot in Edit mode
local Actor = require(client.SlimeActor)
local n = 0
for _, m in root:GetChildren() do
	if m:IsA("Model") and Actor.new(m, m:GetAttribute("Emotion")) then
		n += 1
	end
end
-- wait for the face pictures, so a shot straight after shows them
local urls = {}
for _, s in require(shared.FaceArt).Sprites do
	table.insert(urls, "rbxassetid://" .. s.id)
end
game:GetService("ContentProvider"):PreloadAsync(urls)
for _ = 1, 45 do
	Actor.stepAll(1 / 60, true)
end
-- (the edit-mode loop stops here: the slimes stand posed; a play test starts the real loop in Stage)
Actor.pauseLoop()
return ("SlimeEmotions built: %d slimes with faces"):format(n)
