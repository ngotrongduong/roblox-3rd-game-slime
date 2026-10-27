-- The level-1 pantry of one home plot (back-middle area, between the pond and the garden), built in
-- Studio through MCP (Edit mode) in the classic stud look (docs/areas/pantry.md). No workers: it
-- stores the food. A grey stone stud yard, a small honey-plank shed with a terracotta roof, a door
-- with a lantern, and the stock in front of it (crates of fish and vegetables, barrels, sacks) so a
-- full pantry looks full. The area's signpost (box icon) at the front. Rebuilds itself each run.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local area = Layout.plotAreaFrame(PLOT, 0, 1)
local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)

if plotModel then
	for _, c in plotModel:GetChildren() do
		if c.Name:match("^Pantry") then
			c:Destroy()
		end
	end
end

local HONEY = Color3.fromRGB(205, 146, 82)
local HONEY_DARK = Color3.fromRGB(150, 98, 52)
local WOOD_DARK = Color3.fromRGB(110, 70, 40)
local ROOF = Color3.fromRGB(196, 96, 64)
local ROOF_DARK = Color3.fromRGB(160, 72, 50)
local STONE = Color3.fromRGB(184, 180, 170)
local IRON = Color3.fromRGB(96, 96, 104)
local SACK = Color3.fromRGB(232, 214, 168)

local model = Instance.new("Model")
model.Name = "PantryL1"

-- Local placement: x across, z depth (+z toward the valley's edge, the shed's back), y up from the
-- floor's top.
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

local function post(name: string, cf: CFrame, height: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.PartType.Cylinder, material)
end

local function wedge(name: string, size: Vector3, cf: CFrame, colour: Color3)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = colour
	w.Material = Enum.Material.SmoothPlastic
	w.Anchored = true
	w.Parent = model
end

-- ===== the yard: grey stone studs =====
local yard = part("Floor", Vector3.new(24, 0.4, 20), at(0, 0.2, 0), STONE, nil, Enum.Material.Plastic)
yard.TopSurface = Enum.SurfaceType.Studs
yard.CastShadow = false
for _, b in { { 0, 10.5, 26, 1 }, { 0, -10.5, 26, 1 }, { 12.5, 0, 1, 20 }, { -12.5, 0, 1, 20 } } do
	local e = part("FloorEdge", Vector3.new(b[3], 0.6, b[4]), at(b[1], 0.3, b[2]), Color3.fromRGB(150, 146, 138), nil, Enum.Material.Plastic)
	e.TopSurface = Enum.SurfaceType.Studs
	e.CastShadow = false
end

-- ===== the shed (back half of the yard, its door to the front) =====
local W, D, H = 11, 8, 7
local shed = at(0, 0.4, 4.5)
part("Walls", Vector3.new(W, H, D), shed * CFrame.new(0, H / 2, 0), HONEY, nil, Enum.Material.WoodPlanks)
-- chunky corner posts
for _, cx in { -1, 1 } do
	for _, cz in { -1, 1 } do
		part("CornerPost", Vector3.new(1, H + 0.2, 1), shed * CFrame.new(cx * W / 2, H / 2, cz * D / 2), HONEY_DARK, nil, Enum.Material.Wood)
	end
end
-- a beam along the top of the front wall
part("Lintel", Vector3.new(W + 0.6, 0.7, 0.8), shed * CFrame.new(0, H - 0.2, -D / 2), HONEY_DARK, nil, Enum.Material.Wood)
-- the roof: two wedges meeting at a ridge along x, overhanging all round
local RH, OVER = 3.4, 1.2
local half = D / 2 + OVER
-- (a WedgePart is tallest at its +Z face: the front half as is, the back half turned round)
wedge("RoofFront", Vector3.new(W + OVER * 2, RH, half), shed * CFrame.new(0, H + RH / 2, -half / 2), ROOF)
wedge("RoofBack", Vector3.new(W + OVER * 2, RH, half), shed * CFrame.new(0, H + RH / 2, half / 2) * CFrame.Angles(0, math.rad(180), 0), ROOF)
part("Ridge", Vector3.new(W + OVER * 2 + 0.2, 0.6, 0.8), shed * CFrame.new(0, H + RH, 0), ROOF_DARK)
-- gable ends filled in plank colour
for _, side in { -1, 1 } do
	wedge("Gable", Vector3.new(0.4, RH, D / 2), shed * CFrame.new(side * (W / 2 - 0.1), H + RH / 2, -D / 4), HONEY)
	wedge("Gable", Vector3.new(0.4, RH, D / 2), shed * CFrame.new(side * (W / 2 - 0.1), H + RH / 2, D / 4) * CFrame.Angles(0, math.rad(180), 0), HONEY)
end
-- the door (double, darker) with an iron ring and a step
part("Door", Vector3.new(3.6, 5, 0.3), shed * CFrame.new(0, 2.5, -D / 2 - 0.1), WOOD_DARK, nil, Enum.Material.Wood)
part("DoorSplit", Vector3.new(0.15, 5, 0.35), shed * CFrame.new(0, 2.5, -D / 2 - 0.15), Color3.fromRGB(80, 50, 28))
-- (a cylinder's axis is its X: turned 90 degrees about Y it faces front)
part("DoorRing", Vector3.new(0.12, 0.6, 0.6), shed * CFrame.new(0.6, 2.6, -D / 2 - 0.3) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(230, 190, 80), Enum.PartType.Cylinder)
part("Step", Vector3.new(4.4, 0.4, 1.2), shed * CFrame.new(0, 0.2, -D / 2 - 0.7), STONE, nil, Enum.Material.Slate)
-- a round window on each side
for _, side in { -1, 1 } do
	part("Window", Vector3.new(0.2, 2, 2), shed * CFrame.new(side * (W / 2 + 0.1), 4.4, 0), Color3.fromRGB(255, 226, 150), Enum.PartType.Cylinder, Enum.Material.Neon)
	part("WindowFrame", Vector3.new(0.15, 2.5, 2.5), shed * CFrame.new(side * (W / 2 + 0.03), 4.4, 0), HONEY_DARK, Enum.PartType.Cylinder)
end
-- a lantern by the door
local lamp = part("Lantern", Vector3.new(0.8, 1, 0.8), shed * CFrame.new(2.6, 5, -D / 2 - 0.6), Color3.fromRGB(255, 210, 120), nil, Enum.Material.Neon)
local light = Instance.new("PointLight")
light.Color = Color3.fromRGB(255, 200, 120)
light.Brightness = 1
light.Range = 10
light.Parent = lamp
part("LanternArm", Vector3.new(0.3, 0.3, 1), shed * CFrame.new(2.6, 5.6, -D / 2 - 0.2), WOOD_DARK)

-- ===== the stock in the yard =====
local function crate(name: string, cf: CFrame, s: number, produce: Color3?)
	part(name, Vector3.new(s, s * 0.8, s), cf * CFrame.new(0, s * 0.4, 0), HONEY, nil, Enum.Material.WoodPlanks)
	-- darker frame strips on the front and back
	for _, dz in { -s / 2, s / 2 } do
		part(name .. "Band", Vector3.new(s + 0.1, 0.25, 0.1), cf * CFrame.new(0, s * 0.75, dz), HONEY_DARK)
		part(name .. "Band", Vector3.new(s + 0.1, 0.25, 0.1), cf * CFrame.new(0, s * 0.08, dz), HONEY_DARK)
	end
	if produce then
		for k = 0, 2 do
			part("Produce", Vector3.one * s * 0.32, cf * CFrame.new((k - 1) * s * 0.28, s * 0.85, (k % 2) * 0.2 - 0.1), produce, Enum.PartType.Ball)
		end
	end
end
crate("Crate", at(-7.5, 0.4, -1), 2.6, Color3.fromRGB(240, 130, 40)) -- carrots
crate("Crate", at(-7.5, 0.4, -4.2), 2.6, Color3.fromRGB(110, 170, 225)) -- fish
crate("Crate", at(-7.5, 2.48, -2.6), 2.2, Color3.fromRGB(150, 210, 90)) -- cabbages on top

local function barrel(cf: CFrame)
	post("Barrel", cf * CFrame.new(0, 1.4, 0), 2.8, 2.4, HONEY_DARK, Enum.Material.Wood)
	for _, y in { 0.45, 2.35 } do
		post("Hoop", cf * CFrame.new(0, y, 0), 0.25, 2.5, IRON)
	end
	post("BarrelLid", cf * CFrame.new(0, 2.84, 0), 0.1, 2.1, HONEY)
end
barrel(at(7.5, 0.4, -1.5))
barrel(at(8.2, 0.4, -4.4))
-- two sacks of grain, one tied
part("Sack", Vector3.new(2, 2.6, 1.8), at(5, 1.6, -4.8), SACK, Enum.PartType.Ball) -- (Fabric renders sacks dark)
part("SackTie", Vector3.new(0.8, 0.5, 0.8), at(5, 2.95, -4.8), WOOD_DARK, Enum.PartType.Ball)
part("Sack", Vector3.new(2, 2.2, 1.8), at(5.6, 1.4, -2.4), SACK, Enum.PartType.Ball) -- (Fabric renders sacks dark)

-- ===== the area's signpost (box icon) =====
local signCf = at(-3.5, 0, -11.5)
post("SignPost", signCf * CFrame.new(0, 2, 0), 4, 0.6, HONEY_DARK)
local sign = part("Sign", Vector3.new(3, 2, 0.35), signCf * CFrame.new(0, 3.6, -0.4), HONEY)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(150, 100)
gui.LightInfluence = 0.6
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "📦"
icon.TextScaled = true
icon.Parent = gui
gui.Parent = sign

model.Parent = plotModel or workspace

-- ===== dressing =====
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
		local target = (area * CFrame.new(x, GROUND + size.Y / 2, z)).Position
		m:PivotTo(m:GetPivot() + (target - box.Position))
		m.Parent = nature
		if key == "Fern" or key == "GrassTuft" or key == "FlowerPatch" or key == "FloweringBush" then
			CollectionService:AddTag(m, "Sway")
		end
		if key == "Bush" or key == "BerryBush" or key == "FloweringBush" or key == "MossyBoulder" then
			local bb, bs = m:GetBoundingBox()
			local d = math.max(bs.X, bs.Z) * 0.95
			local s = Instance.new("Part")
			s.Name = "BlobShadow"
			s.Shape = Enum.PartType.Cylinder
			s.Size = Vector3.new(0.06, d, d * 0.85)
			s.CFrame = CFrame.new(bb.Position.X, GROUND + 0.1, bb.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
			s.Color = Color3.fromRGB(70, 128, 46)
			s.Material = Enum.Material.SmoothPlastic
			s.Anchored = true
			s.CanCollide = false
			s.CanQuery = false
			s.CanTouch = false
			s.CastShadow = false
			s.Parent = nature
		end
	end
	put("Bush", -15, 10, 0.85, 0)
	put("FloweringBush", 15.5, 9, 0.8, 40)
	put("Fern", -14.5, -6, 1.2, 0)
	put("GrassTuft", 14.5, -7, 1.3, 70)
	put("FlowerPatch", 3, -12, 1.1, 0)
	put("FlowerPatch", -10, -12.5, 1.0, 120)
	nature.Parent = model
end

return "pantry L1 built"
