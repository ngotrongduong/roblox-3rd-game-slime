-- The level-1 breeding pen of one home plot (middle-right area), built in Studio through MCP (Edit
-- mode) in the classic stud look (docs/areas/breeding.md, the owner's design of 2026-10-27):
-- the round pink "cupcake" cottage kept as the pen's house, a rectangular pen round it with a
-- wooden fence frame; inside, nests like hen's nests; beside it, egg incubators. The player moves
-- slimes into the pen; there they pair up by themselves and after a while lay an egg in a nest; the
-- egg goes to an incubator; after a while it hatches into a new slime. Level 1: 2 nests,
-- 2 incubators. Rebuilds itself each run.
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

local HONEY = Color3.fromRGB(205, 146, 82)
local HONEY_DARK = Color3.fromRGB(150, 98, 52)
local HAY = Color3.fromRGB(236, 206, 126)
local STRAW = Color3.fromRGB(222, 182, 98)
local STRAW_DARK = Color3.fromRGB(184, 140, 70)
local CREAM = Color3.fromRGB(250, 240, 222)
local CREAM_DARK = Color3.fromRGB(226, 206, 176)
local PINK = Color3.fromRGB(240, 132, 168)
local PINK_DARK = Color3.fromRGB(206, 96, 136)
local WOOD_DARK = Color3.fromRGB(110, 70, 40)
local HEART = Color3.fromRGB(232, 60, 90)
local EGG = Color3.fromRGB(252, 246, 232)
local SPECK = Color3.fromRGB(150, 196, 236)
local GOLD = Color3.fromRGB(240, 196, 70)

local model = Instance.new("Model")
model.Name = "BreedingL1"

-- Local placement: x across (-x toward the plot's outer hedge), z depth (+z back), y up from the
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

-- An upright cylinder (Roblox cylinders run along X).
local function disc(name: string, cf: CFrame, height: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.PartType.Cylinder, material)
end

-- A cylinder facing front (-z).
local function plate(name: string, cf: CFrame, thick: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	return part(name, Vector3.new(thick, diameter, diameter), cf * CFrame.Angles(0, math.rad(90), 0), colour, Enum.PartType.Cylinder, material)
end

-- A heart facing front: two balls and a square turned 45 degrees.
local function heart(name: string, cf: CFrame, s: number, colour: Color3, material: Enum.Material?)
	part(name, Vector3.new(s, s, s * 0.5), cf * CFrame.new(-s * 0.32, s * 0.2, 0), colour, Enum.PartType.Ball, material)
	part(name, Vector3.new(s, s, s * 0.5), cf * CFrame.new(s * 0.32, s * 0.2, 0), colour, Enum.PartType.Ball, material)
	part(name, Vector3.new(s * 0.78, s * 0.78, s * 0.45), cf * CFrame.new(0, -s * 0.12, 0) * CFrame.Angles(0, 0, math.rad(45)), colour, nil, material)
end

-- A speckled egg standing on its end.
local function egg(name: string, cf: CFrame, s: number)
	part(name, Vector3.new(s, s * 1.3, s), cf * CFrame.new(0, s * 0.62, 0), EGG, Enum.PartType.Ball)
	for k = 1, 4 do
		local a = k * 1.7
		local y = s * (0.45 + (k % 2) * 0.35)
		part(name .. "Speck", Vector3.one * s * 0.18, cf * CFrame.new(math.cos(a) * s * 0.47, y, math.sin(a) * s * 0.47), SPECK, Enum.PartType.Ball).CastShadow = false
	end
end

-- ===== the pen =====
local PX, PW, PD = 4, 30, 26 -- centre x, width, depth
local GATE = 8 -- the opening in the front fence
-- hay floor with studs
local floor = part("PenFloor", Vector3.new(PW, 0.4, PD), at(PX, 0.2, 0), HAY, nil, Enum.Material.Plastic)
floor.TopSurface = Enum.SurfaceType.Studs
floor.CastShadow = false

-- fence: chunky posts every 4 studs, two rails, a cap on each post
local function fencePost(x: number, z: number, tall: boolean?)
	local h = if tall then 6 else 4
	part("FencePost", Vector3.new(1, h, 1), at(x, h / 2, z), HONEY_DARK, nil, Enum.Material.Wood)
	part("PostCap", Vector3.new(1.3, 0.4, 1.3), at(x, h + 0.2, z), HONEY)
end
local function rail(x0: number, z0: number, x1: number, z1: number)
	local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
	local along = if math.abs(x1 - x0) > 0 then Vector3.new(len, 0.5, 0.4) else Vector3.new(0.4, 0.5, len)
	for _, y in { 1.4, 3 } do
		part("FenceRail", along, at((x0 + x1) / 2, y, (z0 + z1) / 2), HONEY, nil, Enum.Material.Wood)
	end
	local steps = math.floor(len / 4)
	for k = 0, steps do
		local t = k / steps
		fencePost(x0 + (x1 - x0) * t, z0 + (z1 - z0) * t)
	end
end
local x0, x1 = PX - PW / 2, PX + PW / 2
local zb, zf = PD / 2, -PD / 2
rail(x0, zb, x1, zb) -- back
rail(x0, zf, x0, zb) -- outer side
rail(x1, zf, x1, zb) -- meadow side
rail(x0, zf, PX - GATE / 2, zf) -- front, either side of the gate
rail(PX + GATE / 2, zf, x1, zf)
-- the gate: two tall posts and an arch board with a heart
fencePost(PX - GATE / 2, zf, true)
fencePost(PX + GATE / 2, zf, true)
part("GateBoard", Vector3.new(GATE + 1.6, 1.4, 0.5), at(PX, 6.6, zf), HONEY, nil, Enum.Material.Wood)
local heartCf = at(PX, 6.6, zf - 0.35)
part("GateHeart", Vector3.new(0.9, 0.9, 0.3), heartCf * CFrame.new(-0.28, 0.18, 0), PINK, Enum.PartType.Ball)
part("GateHeart", Vector3.new(0.9, 0.9, 0.3), heartCf * CFrame.new(0.28, 0.18, 0), PINK, Enum.PartType.Ball)
part("GateHeart", Vector3.new(0.7, 0.7, 0.28), heartCf * CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.rad(45)), PINK)

-- ===== the round cottage: the pen's house, at the back, door to the front =====
local R, H = 5.5, 6.5
local house = at(PX, 0.4, 5.5)
disc("Base", house * CFrame.new(0, 0.4, 0), 0.8, R * 2 + 1, CREAM_DARK, Enum.Material.Plastic)
disc("Walls", house * CFrame.new(0, H / 2, 0), H, R * 2, CREAM, Enum.Material.SmoothPlastic)
disc("Band", house * CFrame.new(0, H - 0.4, 0), 0.6, R * 2 + 0.2, PINK_DARK)
-- the stepped roof: discs shrinking upward, overhanging first
local roofY = H
local steps = { { R + 1.4, 1.1 }, { R + 0.4, 1.1 }, { R - 0.8, 1.1 }, { R - 2.1, 1.1 }, { R - 3.4, 1.1 } }
for i, s in steps do
	disc("Roof", house * CFrame.new(0, roofY + s[2] / 2, 0), s[2], s[1] * 2, if i % 2 == 1 then PINK else PINK_DARK)
	roofY += s[2]
end
heart("RoofHeart", house * CFrame.new(0, roofY + 1, 0), 1.4, HEART, Enum.Material.SmoothPlastic)
disc("RoofTip", house * CFrame.new(0, roofY + 0.15, 0), 0.3, 0.8, GOLD)
local doorZ = -R + 0.15
part("Door", Vector3.new(2.6, 3.6, 0.4), house * CFrame.new(0, 2.2, doorZ), WOOD_DARK, nil, Enum.Material.Wood)
plate("DoorArch", house * CFrame.new(0, 4, doorZ), 0.4, 2.6, WOOD_DARK, Enum.Material.Wood)
plate("DoorKnob", house * CFrame.new(0.8, 2.3, doorZ - 0.25), 0.2, 0.4, GOLD)
part("Step", Vector3.new(3.6, 0.4, 1.4), house * CFrame.new(0, 0.2, doorZ - 0.9), CREAM_DARK, nil, Enum.Material.Plastic).TopSurface = Enum.SurfaceType.Studs
heart("DoorHeart", house * CFrame.new(0, 5.4, doorZ - 0.15), 1.2, HEART)
for _, side in { -1, 1 } do
	local a = math.rad(side * 48)
	local cf = house * CFrame.Angles(0, -a, 0) * CFrame.new(0, 3.6, -R + 0.05)
	plate("WindowFrame", cf, 0.25, 2.1, PINK_DARK)
	plate("Window", cf * CFrame.new(0, 0, -0.08), 0.2, 1.6, Color3.fromRGB(255, 226, 150), Enum.Material.Neon)
end
-- flower pots by the door
for _, side in { -1, 1 } do
	local potCf = house * CFrame.new(side * 3, 0, -R - 0.3)
	disc("FlowerPot", potCf * CFrame.new(0, 0.7, 0), 1.4, 1.6, Color3.fromRGB(206, 118, 76))
	for k = 0, 2 do
		local a = k * 2.1
		part("PotFlower", Vector3.one * 0.7, potCf * CFrame.new(math.cos(a) * 0.4, 1.8, math.sin(a) * 0.4), if k == 1 then Color3.fromRGB(255, 252, 240) else PINK, Enum.PartType.Ball)
	end
end

-- ===== nests (hen's nests of straw), level 1: two =====
local function nest(i: number, x: number, z: number, withEgg: boolean)
	local cf = at(x, 0.4, z)
	disc("NestBase", cf * CFrame.new(0, 0.35, 0), 0.7, 4.6, STRAW, Enum.Material.Plastic)
	-- a woven rim of straw lumps
	for k = 0, 9 do
		local a = k * math.pi / 5
		part("NestRim", Vector3.new(1.3, 0.9, 1.1), cf * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.85, 2) * CFrame.Angles(0, 0, math.rad(if k % 2 == 0 then 12 else -12)), if k % 2 == 0 then STRAW else STRAW_DARK, Enum.PartType.Ball)
	end
	-- the hollow carries the nest's Attachment (where a laid egg sits)
	local hollow = disc("NestHollow" .. i, cf * CFrame.new(0, 0.72, 0), 0.06, 3, STRAW_DARK)
	local mark = Instance.new("Attachment")
	mark.Name = "Nest" .. i
	mark.Parent = hollow
	if withEgg then
		egg("Egg", cf * CFrame.new(0.2, 0.7, 0), 1.3)
	end
end
nest(1, PX - 9.5, -2, true)
nest(2, PX + 9.5, -2, false)

-- a water trough and a little hay bale inside the pen
part("Trough", Vector3.new(5, 1.2, 1.6), at(PX - 10, 1, 8), HONEY_DARK, nil, Enum.Material.Wood)
part("TroughWater", Vector3.new(4.4, 0.1, 1.1), at(PX - 10, 1.62, 8), Color3.fromRGB(96, 186, 230))
part("HayBale", Vector3.new(3, 2, 2.2), at(PX + 10.5, 1.4, 8), HAY, nil, Enum.Material.Plastic).TopSurface = Enum.SurfaceType.Studs
part("HayBand", Vector3.new(3.05, 2.05, 0.3), at(PX + 10.5, 1.4, 8), STRAW_DARK)

-- ===== incubators beside the pen (toward the outer hedge), level 1: two =====
local pad = part("IncubatorPad", Vector3.new(7, 0.4, 18), at(-17, 0.2, 1), CREAM, nil, Enum.Material.Plastic)
pad.TopSurface = Enum.SurfaceType.Studs
pad.CastShadow = false
local function incubator(i: number, z: number, withEgg: boolean)
	-- facing the front (the gate side), so the player sees the gauge on the way in
	local cf = at(-17, 0.4, z)
	part("IncBase", Vector3.new(4, 2.4, 4), cf * CFrame.new(0, 1.2, 0), CREAM, nil, Enum.Material.Plastic).TopSurface = Enum.SurfaceType.Studs
	part("IncTrim", Vector3.new(4.2, 0.4, 4.2), cf * CFrame.new(0, 2.5, 0), PINK)
	-- the straw bed and the egg under a glass dome
	local bed = disc("IncBed" .. i, cf * CFrame.new(0, 2.8, 0), 0.3, 2.6, STRAW)
	if withEgg then
		egg("IncEgg", cf * CFrame.new(0, 2.95, 0), 1.2)
	end
	local dome = part("IncDome", Vector3.new(3.4, 3.4, 3.4), cf * CFrame.new(0, 2.7, 0), Color3.fromRGB(200, 236, 255), Enum.PartType.Ball, Enum.Material.Glass)
	dome.Transparency = 0.55
	dome.CastShadow = false
	-- a warm lamp in the top of the dome
	local lamp = part("IncLamp", Vector3.new(0.6, 0.6, 0.6), cf * CFrame.new(0, 4.2, 0), Color3.fromRGB(255, 186, 96), Enum.PartType.Ball, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 90)
	light.Brightness = 1.2
	light.Range = 7
	light.Parent = lamp
	disc("IncCap", cf * CFrame.new(0, 4.5, 0), 0.4, 1.1, GOLD)
	-- the front panel: a gauge and a little red button
	plate("Gauge", cf * CFrame.new(-0.6, 1.3, -2.05), 0.15, 1.2, CREAM)
	part("GaugeNeedle", Vector3.new(0.08, 0.5, 0.06), cf * CFrame.new(-0.6, 1.4, -2.14) * CFrame.Angles(0, 0, math.rad(30)), Color3.fromRGB(220, 60, 60))
	plate("GaugeRim", cf * CFrame.new(-0.6, 1.3, -2.02), 0.12, 1.4, Color3.fromRGB(150, 150, 160))
	plate("Button", cf * CFrame.new(0.9, 1.3, -2.08), 0.25, 0.6, Color3.fromRGB(230, 70, 70))
	local mark = Instance.new("Attachment")
	mark.Name = "Incubator" .. i
	mark.Parent = bed
end
incubator(1, -3.5, true)
incubator(2, 5.5, false)

-- ===== the area's signpost (heart icon) at the gate =====
local signCf = at(PX + GATE / 2 + 3, 0, zf - 2)
disc("SignPost", signCf * CFrame.new(0, 2, 0), 4, 0.6, HONEY_DARK)
local sign = part("Sign", Vector3.new(3, 2, 0.35), signCf * CFrame.new(0, 3.6, -0.4), HONEY)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(150, 100)
gui.LightInfluence = 0.6
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "🥚"
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
		local target = (area * CFrame.new(x, GROUND + size.Y / 2, z)).Position
		m:PivotTo(m:GetPivot() + (target - box.Position))
		m.Parent = nature
		if key == "Fern" or key == "GrassTuft" or key == "FlowerPatch" or key == "FloweringBush" then
			CollectionService:AddTag(m, "Sway")
		end
	end
	-- flowering bushes along the fence outside, as the cottage's old yard had round it
	put("FloweringBush", x1 + 2.5, zb - 2, 0.8, 0)
	put("FloweringBush", x1 + 2.5, zf + 4, 0.7, 90)
	put("FloweringBush", PX - 6, zb + 2.5, 0.75, 150)
	put("FloweringBush", PX + 7, zb + 2.5, 0.7, 30)
	put("FlowerPatch", PX - GATE / 2 - 3, zf - 2, 1.1, 0)
	put("FlowerPatch", -17, -11, 1.0, 40)
	put("GrassTuft", -18, 12, 1.3, 0)
	put("Fern", x1 + 2.5, 2, 1.1, 0)
	nature.Parent = model
end

return "breeding pen L1 built at " .. tostring(area.Position)
