-- The level-1 breeding house of one home plot (middle-right area), built in Studio through MCP
-- (Edit mode) in the classic stud look (docs/areas/breeding.md). It holds ONE pair: two spots in
-- front of the door where the chosen slimes meet. A soft pink stud yard, a round cream cottage with a
-- stepped pink roof (stacked discs, the stud way of making a cone), a heart over the arched door, warm
-- windows, pink sparkles drifting up between the pair, a flowering hedge round the back, the area's
-- signpost (heart icon). Rebuilds itself each run.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local area = Layout.plotAreaFrame(PLOT, 1, 0)
local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)

if plotModel then
	for _, c in plotModel:GetChildren() do
		if c.Name:match("^Breeding") then
			c:Destroy()
		end
	end
end

local CREAM = Color3.fromRGB(250, 238, 214)
local CREAM_DARK = Color3.fromRGB(226, 206, 176)
local PINK = Color3.fromRGB(240, 132, 168)
local PINK_DARK = Color3.fromRGB(206, 96, 136)
local PINK_SOFT = Color3.fromRGB(246, 206, 218)
local HONEY_DARK = Color3.fromRGB(150, 98, 52)
local WOOD_DARK = Color3.fromRGB(110, 70, 40)
local HEART = Color3.fromRGB(232, 60, 90)
local GOLD = Color3.fromRGB(240, 196, 70)

local model = Instance.new("Model")
model.Name = "BreedingL1"

-- Local placement: x across, z depth (+z = the house's back), y up from the floor's top.
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
local function disc(name: string, cf: CFrame, height: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.PartType.Cylinder, material)
end

-- A cylinder facing front (-z), for round things on a wall.
local function plate(name: string, cf: CFrame, thick: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(thick, diameter, diameter), cf * CFrame.Angles(0, math.rad(90), 0), colour, Enum.PartType.Cylinder, material)
end

-- A heart facing front: two balls and a square turned 45 degrees.
local function heart(name: string, cf: CFrame, s: number, colour: Color3, material: Enum.Material?)
	part(name, Vector3.new(s, s, s * 0.5), cf * CFrame.new(-s * 0.32, s * 0.2, 0), colour, Enum.PartType.Ball, material)
	part(name, Vector3.new(s, s, s * 0.5), cf * CFrame.new(s * 0.32, s * 0.2, 0), colour, Enum.PartType.Ball, material)
	part(name, Vector3.new(s * 0.78, s * 0.78, s * 0.45), cf * CFrame.new(0, -s * 0.12, 0) * CFrame.Angles(0, 0, math.rad(45)), colour, nil, material)
end

-- ===== the yard: soft pink studs with a cream border =====
local yard = part("Floor", Vector3.new(24, 0.4, 22), at(0, 0.2, 0), PINK_SOFT, nil, Enum.Material.Plastic)
yard.TopSurface = Enum.SurfaceType.Studs
yard.CastShadow = false
for _, b in { { 0, 11.5, 26, 1 }, { 0, -11.5, 26, 1 }, { 12.5, 0, 1, 22 }, { -12.5, 0, 1, 22 } } do
	local e = part("FloorEdge", Vector3.new(b[3], 0.6, b[4]), at(b[1], 0.3, b[2]), CREAM_DARK, nil, Enum.Material.Plastic)
	e.TopSurface = Enum.SurfaceType.Studs
	e.CastShadow = false
end

-- ===== the round cottage (back of the yard, door to the front) =====
local R, H = 5.5, 6.5
local house = at(0, 0.4, 4.5)
disc("Base", house * CFrame.new(0, 0.4, 0), 0.8, R * 2 + 1, CREAM_DARK, Enum.Material.Plastic)
disc("Walls", house * CFrame.new(0, H / 2, 0), H, R * 2, CREAM, Enum.Material.SmoothPlastic)
-- a band of pink under the eaves
disc("Band", house * CFrame.new(0, H - 0.4, 0), 0.6, R * 2 + 0.2, PINK_DARK)
-- the stepped roof: discs shrinking upward, overhanging first
local roofY = H
local steps = { { R + 1.4, 1.1 }, { R + 0.4, 1.1 }, { R - 0.8, 1.1 }, { R - 2.1, 1.1 }, { R - 3.4, 1.1 } }
for i, s in steps do
	disc("Roof", house * CFrame.new(0, roofY + s[2] / 2, 0), s[2], s[1] * 2, if i % 2 == 1 then PINK else PINK_DARK)
	roofY += s[2]
end
-- a little heart on the top
heart("RoofHeart", house * CFrame.new(0, roofY + 1, 0), 1.4, HEART, Enum.Material.SmoothPlastic)
disc("RoofTip", house * CFrame.new(0, roofY + 0.15, 0), 0.3, 0.8, GOLD)

-- the arched door
local doorZ = -R + 0.15
part("Door", Vector3.new(2.6, 3.6, 0.4), house * CFrame.new(0, 2.2, doorZ), WOOD_DARK, nil, Enum.Material.Wood)
plate("DoorArch", house * CFrame.new(0, 4, doorZ), 0.4, 2.6, WOOD_DARK, Enum.Material.Wood)
plate("DoorKnob", house * CFrame.new(0.8, 2.3, doorZ - 0.25), 0.2, 0.4, GOLD)
part("Step", Vector3.new(3.6, 0.4, 1.4), house * CFrame.new(0, 0.2, doorZ - 0.9), CREAM_DARK, nil, Enum.Material.Plastic).TopSurface = Enum.SurfaceType.Studs
-- the heart over the door
heart("DoorHeart", house * CFrame.new(0, 5.4, doorZ - 0.15), 1.2, HEART)
-- two round warm windows either side of the door, on the curve of the wall
for _, side in { -1, 1 } do
	local a = math.rad(side * 48)
	local cf = house * CFrame.Angles(0, -a, 0) * CFrame.new(0, 3.6, -R + 0.05)
	plate("WindowFrame", cf, 0.25, 2.1, PINK_DARK)
	plate("Window", cf * CFrame.new(0, 0, -0.08), 0.2, 1.6, Color3.fromRGB(255, 226, 150), Enum.Material.Neon)
end

-- ===== the pair's spots (one pair at level 1) =====
-- Two straw mats in front of the door, turned a little toward each other: where the chosen slimes
-- meet. Pink sparkles drift up between them.
for i, side in { -1, 1 } do
	local spotCf = at(side * 2.6, 0.45, -3.2) * CFrame.Angles(0, math.rad(side * 20), 0)
	local mat = disc("PairSpot" .. i, spotCf, 0.12, 3.4, Color3.fromRGB(244, 196, 160), Enum.Material.Fabric)
	local mark = Instance.new("Attachment")
	mark.Name = "BreedSpot" .. i
	mark.Parent = mat
	local slime = part("SlimeStandIn", Vector3.new(3.6, 3.1, 3.6), spotCf * CFrame.new(0, 1.65, 0), Color3.fromRGB(28, 70, 214), Enum.PartType.Ball)
	slime.Reflectance = 0.15
	part("SlimeTip", Vector3.new(1.1, 1.3, 1.1), spotCf * CFrame.new(0, 3.3, 0), Color3.fromRGB(28, 70, 214), Enum.PartType.Ball).Reflectance = 0.15
end
local glowPoint = part("LoveGlow", Vector3.new(0.2, 0.2, 0.2), at(0, 3.5, -3.2), PINK, nil, Enum.Material.Neon)
glowPoint.Transparency = 1
local sparkles = Instance.new("ParticleEmitter")
sparkles.Name = "LoveSparkles"
sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 150, 190), Color3.fromRGB(255, 220, 235))
sparkles.LightEmission = 0.6
sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
sparkles.Lifetime = NumberRange.new(1.6, 2.4)
sparkles.Rate = 3
sparkles.Speed = NumberRange.new(0.8, 1.4)
sparkles.SpreadAngle = Vector2.new(20, 20)
sparkles.EmissionDirection = Enum.NormalId.Top
sparkles.Parent = glowPoint

-- ===== flower pots by the door =====
for _, side in { -1, 1 } do
	local potCf = at(side * 3, 0.4, 0.2)
	disc("FlowerPot", potCf * CFrame.new(0, 0.7, 0), 1.4, 1.6, Color3.fromRGB(206, 118, 76))
	for k = 0, 2 do
		local a = k * 2.1
		part("PotFlower", Vector3.one * 0.7, potCf * CFrame.new(math.cos(a) * 0.4, 1.8, math.sin(a) * 0.4), if k == 1 then Color3.fromRGB(255, 252, 240) else PINK, Enum.PartType.Ball)
	end
end

-- ===== the area's signpost (heart icon) =====
local signCf = at(7.5, 0, -12.5)
disc("SignPost", signCf * CFrame.new(0, 2, 0), 4, 0.6, HONEY_DARK)
local sign = part("Sign", Vector3.new(3, 2, 0.35), signCf * CFrame.new(0, 3.6, -0.4), Color3.fromRGB(205, 146, 82))
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(150, 100)
gui.LightInfluence = 0.6
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "💗"
icon.TextScaled = true
icon.Parent = gui
gui.Parent = sign

model.Parent = plotModel or workspace

-- ===== dressing: a flowering hedge round the back, a few tufts =====
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
		if key == "FloweringBush" or key == "Bush" then
			local bb, bs = m:GetBoundingBox()
			local d = math.max(bs.X, bs.Z) * 0.95
			local s = Instance.new("Part")
			s.Name = "BlobShadow"
			s.Shape = Enum.PartType.Cylinder
			s.Size = Vector3.new(0.06, d, d * 0.85)
			s.CFrame = CFrame.new(bb.Position.X, GROUND + 0.45, bb.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
			s.Color = Color3.fromRGB(214, 160, 178)
			s.Material = Enum.Material.SmoothPlastic
			s.Anchored = true
			s.CanCollide = false
			s.CanQuery = false
			s.CanTouch = false
			s.CastShadow = false
			s.Parent = nature
		end
	end
	put("FloweringBush", -9.5, 9.5, 0.8, 0)
	put("FloweringBush", 9.5, 9.5, 0.8, 70)
	put("FloweringBush", -10, 2, 0.7, 140)
	put("FloweringBush", 10, 2, 0.7, 200)
	put("FlowerPatch", -9, -9, 1.1, 0)
	put("FlowerPatch", 3, -10.5, 1.0, 60)
	put("GrassTuft", 15, -4, 1.3, 0)
	put("Fern", -15.5, -6, 1.2, 30)
	nature.Parent = model
end

return "breeding L1 built at " .. tostring(area.Position)
