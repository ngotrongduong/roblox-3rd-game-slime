-- The level-1 training ground of one home plot (front-left area, beside the gate), built in Studio
-- through MCP (Edit mode) in the classic stud look (docs/areas/training.md): a packed-sand stud yard
-- with a low fence open to the front, ONE training spot facing a straw dummy, an archery target, a
-- weapon rack, and a banner pole where the squad gathers before going out to the Wild Garden.
-- No slimes (the owner adds them later). Rebuilds itself each run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local area = Layout.plotAreaFacing(PLOT, -1, -1)
local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)

-- Clear the greybox (yard, dummies) and any previous build.
if plotModel then
	for _, c in plotModel:GetChildren() do
		if c.Name == "Yard" or c.Name == "Dummy" or c.Name:match("^Training") then
			c:Destroy()
		end
	end
end

local SAND = Color3.fromRGB(230, 196, 132)
local SAND_DARK = Color3.fromRGB(196, 158, 98)
local HONEY = Color3.fromRGB(205, 146, 82)
local HONEY_DARK = Color3.fromRGB(150, 98, 52)
local WOOD_DARK = Color3.fromRGB(110, 70, 40)
local BURLAP = Color3.fromRGB(214, 176, 110)
local ROPE = Color3.fromRGB(176, 134, 78)
local RED = Color3.fromRGB(220, 64, 56)
local WHITE = Color3.fromRGB(250, 246, 236)
local ROYAL = Color3.fromRGB(46, 96, 200)
local STEEL = Color3.fromRGB(200, 206, 214)

local model = Instance.new("Model")
model.Name = "TrainingL1"

-- Local placement: x across (-x toward the plot's gate), z depth (+z back), y up from the floor.
local function at(x: number, y: number, z: number): CFrame
	return area * CFrame.new(x, y + GROUND, z)
end

local function part(name: string, size: Vector3, cf: CFrame, colour: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.CastShadow = size.Magnitude > 4
	p.Parent = model
	return p
end

-- An upright cylinder (Roblox cylinders run along X).
local function pole(name: string, cf: CFrame, height: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.PartType.Cylinder, material)
end

-- A cylinder facing front (-z).
local function plate(name: string, cf: CFrame, thick: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(thick, diameter, diameter), cf * CFrame.Angles(0, math.rad(90), 0), colour, Enum.PartType.Cylinder, material)
end

-- ===== the yard: packed sand studs, a darker border =====
local W, D = 26, 24
local floor = part("Floor", Vector3.new(W, 0.4, D), at(0, 0.2, 0), SAND, nil, Enum.Material.Plastic)
floor.TopSurface = Enum.SurfaceType.Studs
floor.CastShadow = false
for _, b in { { 0, D / 2 + 0.5, W + 2, 1 }, { 0, -D / 2 - 0.5, W + 2, 1 }, { W / 2 + 0.5, 0, 1, D }, { -W / 2 - 0.5, 0, 1, D } } do
	local e = part("FloorEdge", Vector3.new(b[3], 0.6, b[4]), at(b[1], 0.3, b[2]), SAND_DARK, nil, Enum.Material.Plastic)
	e.TopSurface = Enum.SurfaceType.Studs
	e.CastShadow = false
end

-- ===== a low fence (posts and one rail), open at the front =====
local function fence(x0: number, z0: number, x1: number, z1: number)
	local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
	local size = if math.abs(x1 - x0) > 0 then Vector3.new(len, 0.45, 0.35) else Vector3.new(0.35, 0.45, len)
	part("FenceRail", size, at((x0 + x1) / 2, 2, (z0 + z1) / 2), HONEY, nil, Enum.Material.Wood)
	local n = math.floor(len / 4)
	for k = 0, n do
		local t = k / n
		part("FencePost", Vector3.new(0.8, 2.8, 0.8), at(x0 + (x1 - x0) * t, 1.4, z0 + (z1 - z0) * t), HONEY_DARK, nil, Enum.Material.Wood)
	end
end
local fx, fz = W / 2 + 0.5, D / 2 + 0.5
fence(-fx, fz, fx, fz) -- back
fence(-fx, -fz, -fx, fz) -- gate side
fence(fx, -fz, fx, fz) -- outer side
fence(-fx, -fz, -fx + 7, -fz) -- front, a wide opening in the middle
fence(fx - 7, -fz, fx, -fz)

-- ===== the training dummy (back middle), built at 1 and scaled up 1.3 about its foot =====
local dummy = at(0, 0.4, 6)
local dummyParts = {
	part("DummyBase", Vector3.new(3, 0.6, 3), dummy * CFrame.new(0, 0.3, 0), WOOD_DARK, nil, Enum.Material.Wood),
	pole("DummyPost", dummy * CFrame.new(0, 2.6, 0), 4.6, 0.7, HONEY_DARK, Enum.Material.Wood),
	part("DummyBody", Vector3.new(3, 3.6, 2.4), dummy * CFrame.new(0, 4.3, 0), BURLAP, Enum.PartType.Ball),
	part("DummyHead", Vector3.new(2, 2, 2), dummy * CFrame.new(0, 6.7, 0), BURLAP, Enum.PartType.Ball),
	-- a rope tied at the neck and the waist
	pole("DummyRope", dummy * CFrame.new(0, 5.75, 0), 0.3, 1.4, ROPE),
	pole("DummyRope", dummy * CFrame.new(0, 3.3, 0), 0.3, 2.4, ROPE),
	-- arms: one log across the shoulders
	part("DummyArms", Vector3.new(5.6, 0.6, 0.6), dummy * CFrame.new(0, 5.1, 0), HONEY_DARK, Enum.PartType.Cylinder, Enum.Material.Wood),
	-- a red and white target painted on the chest
	plate("DummyTarget", dummy * CFrame.new(0, 4.4, -1.18), 0.1, 1.8, WHITE),
	plate("DummyTarget", dummy * CFrame.new(0, 4.4, -1.24), 0.1, 1.2, RED),
	plate("DummyTarget", dummy * CFrame.new(0, 4.4, -1.3), 0.1, 0.5, WHITE),
}
local dummyModel = Instance.new("Model")
dummyModel.Name = "Dummy"
for _, p in dummyParts do
	p.Parent = dummyModel
end
dummyModel.WorldPivot = dummy
dummyModel.Parent = model
dummyModel:ScaleTo(1.3)

-- ===== the training spot (one) facing the dummy =====
local spot = pole("TrainSpot1", at(0, 0.45, 1), 0.12, 3.6, Color3.fromRGB(232, 200, 120), Enum.Material.Fabric)
local mark = Instance.new("Attachment")
mark.Name = "WorkSpot1"
mark.Parent = spot

-- ===== an archery target (outer side) =====
local target = at(8.5, 0.4, 4) * CFrame.Angles(0, math.rad(-25), 0)
for _, dx in { -1, 1 } do
	part("TargetLeg", Vector3.new(0.4, 4.6, 0.4), target * CFrame.new(dx * 1.1, 2.2, 0.6) * CFrame.Angles(math.rad(-14), 0, 0), HONEY_DARK, nil, Enum.Material.Wood)
end
part("TargetBackLeg", Vector3.new(0.4, 4.4, 0.4), target * CFrame.new(0, 2, 1.6) * CFrame.Angles(math.rad(22), 0, 0), HONEY_DARK, nil, Enum.Material.Wood)
local face = target * CFrame.new(0, 3.6, 0) * CFrame.Angles(math.rad(-12), 0, 0)
plate("TargetFace", face, 0.5, 3.6, BURLAP)
for k, c in { WHITE, RED, WHITE, RED } do
	plate("TargetRing", face * CFrame.new(0, 0, -0.26 - k * 0.03), 0.06, 3.2 - (k - 1) * 0.8, c)
end
-- an arrow stuck near the middle
part("Arrow", Vector3.new(0.12, 0.12, 2), face * CFrame.new(0.3, 0.2, -1.1), HONEY)
part("ArrowFletch", Vector3.new(0.4, 0.4, 0.4), face * CFrame.new(0.3, 0.2, -2.1) * CFrame.Angles(0, 0, math.rad(45)), RED)

-- ===== a weapon rack (gate side, against the fence) =====
local rack = at(-9.5, 0.4, 4) * CFrame.Angles(0, math.rad(90), 0)
for _, dx in { -2.4, 2.4 } do
	part("RackPost", Vector3.new(0.6, 4.4, 0.6), rack * CFrame.new(dx, 2.2, 0), HONEY_DARK, nil, Enum.Material.Wood)
end
part("RackBar", Vector3.new(5.6, 0.5, 0.6), rack * CFrame.new(0, 4.1, 0), HONEY, nil, Enum.Material.Wood)
part("RackBar", Vector3.new(5.6, 0.5, 0.6), rack * CFrame.new(0, 0.9, 0), HONEY, nil, Enum.Material.Wood)
-- a wooden sword, a staff and a round shield leaning on it
local sword = rack * CFrame.new(-1.4, 2.3, -0.5) * CFrame.Angles(math.rad(-8), 0, 0)
part("SwordBlade", Vector3.new(0.5, 3, 0.15), sword * CFrame.new(0, 0.6, 0), Color3.fromRGB(226, 190, 140), nil, Enum.Material.Wood)
part("SwordGuard", Vector3.new(1.4, 0.3, 0.3), sword * CFrame.new(0, -0.95, 0), WOOD_DARK)
part("SwordGrip", Vector3.new(0.3, 0.9, 0.3), sword * CFrame.new(0, -1.55, 0), RED)
part("Staff", Vector3.new(0.3, 4, 0.3), rack * CFrame.new(0.2, 2.2, -0.5) * CFrame.Angles(math.rad(-8), 0, 0), HONEY_DARK, nil, Enum.Material.Wood)
part("StaffGem", Vector3.new(0.6, 0.6, 0.6), rack * CFrame.new(0.2, 4.2, -0.8), Color3.fromRGB(120, 200, 255), Enum.PartType.Ball, Enum.Material.Neon)
local shield = rack * CFrame.new(1.7, 1.8, -0.7) * CFrame.Angles(math.rad(-10), 0, 0)
plate("Shield", shield, 0.3, 2.4, ROYAL)
plate("ShieldRim", shield * CFrame.new(0, 0, 0.02), 0.25, 2.7, STEEL)
plate("ShieldBoss", shield * CFrame.new(0, 0, -0.18), 0.2, 0.7, Color3.fromRGB(240, 196, 70))

-- ===== the squad's banner pole by the opening: where the squad gathers =====
local flagCf = at(-6.5, 0.4, -8.5)
local flagBase = part("FlagBase", Vector3.new(1.6, 0.5, 1.6), flagCf * CFrame.new(0, 0.25, 0), WOOD_DARK, nil, Enum.Material.Wood)
pole("FlagPole", flagCf * CFrame.new(0, 4.5, 0), 8.5, 0.45, HONEY_DARK, Enum.Material.Wood)
part("FlagTop", Vector3.new(0.8, 0.8, 0.8), flagCf * CFrame.new(0, 8.9, 0), Color3.fromRGB(240, 196, 70), Enum.PartType.Ball)
part("Flag", Vector3.new(3.4, 2.2, 0.12), flagCf * CFrame.new(1.9, 7.4, 0), ROYAL, nil, Enum.Material.Fabric)
part("FlagStripe", Vector3.new(3.4, 0.4, 0.14), flagCf * CFrame.new(1.9, 7.4, 0), Color3.fromRGB(240, 196, 70))
local gather = Instance.new("Attachment")
gather.Name = "SquadPoint"
gather.Parent = flagBase

-- ===== the area's signpost (crossed swords) by the opening =====
local signCf = at(6.5, 0, -14)
pole("SignPost", signCf * CFrame.new(0, 2, 0), 4, 0.6, HONEY_DARK)
local sign = part("Sign", Vector3.new(3, 2, 0.35), signCf * CFrame.new(0, 3.6, -0.4), HONEY)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(150, 100)
gui.LightInfluence = 0.6
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "⚔️"
icon.TextScaled = true
icon.Parent = gui
gui.Parent = sign

model.Parent = plotModel or workspace

-- ===== dressing outside the fence =====
local lib = ServerStorage:FindFirstChild("NatureKit")
if lib then
	local nature = Instance.new("Folder")
	nature.Name = "Nature"
	local function put(key: string, x: number, z: number, scale: number, turn: number)
		local m = (lib:FindFirstChild(key) :: Model):Clone()
		m:ScaleTo(scale)
		local pivot = m:GetPivot()
		m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.rad(turn), 0) * pivot.Rotation)
		local box, size = m:GetBoundingBox()
		local t = (area * CFrame.new(x, GROUND + size.Y / 2, z)).Position
		m:PivotTo(m:GetPivot() + (t - box.Position))
		m.Parent = nature
	end
	put("Bush", 17, 10, 0.8, 0)
	put("BerryBush", 17, -6, 0.75, 60)
	put("SmallRocks", 16.5, 2, 1.0, 0)
	put("GrassTuft", -16, 9, 1.3, 0)
	put("FlowerPatch", -2, -15.5, 1.0, 0)
	put("Stump", 16, -14, 0.8, 0)
	nature.Parent = model
end

return "training L1 built at " .. tostring(area.Position)
