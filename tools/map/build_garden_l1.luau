-- The level-1 vegetable garden of one home plot, built in Studio through MCP (Edit mode) in the
-- plot's garden area (back-right). Same style as the fishing pond: two raised wooden beds with young
-- vegetables, ONE work spot between them where a slime tends the beds, a low picket fence open at the
-- front, the area's signpost (carrot icon), and a few props. Rebuilds itself each run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local area = Layout.plotAreaFrame(PLOT, 1, 1)
local plotModel = workspace.Map:FindFirstChild("Plot" .. PLOT)

-- Clear the greybox garden (rows, sprouts, scarecrow) and any previous build.
if plotModel then
	for _, c in plotModel:GetChildren() do
		if c.Name == "Row" or c.Name == "Sprout" or c.Name == "Scarecrow" or c.Name == "GardenL1" then
			c:Destroy()
		end
	end
end

local HONEY = Color3.fromRGB(205, 146, 82)
local HONEY_DARK = Color3.fromRGB(170, 112, 58)
local WOOD_DARK = Color3.fromRGB(120, 78, 44)
local SOIL = Color3.fromRGB(110, 72, 44)
local LEAF = Color3.fromRGB(96, 176, 70)
local LEAF_LIGHT = Color3.fromRGB(150, 210, 90)
local CARROT = Color3.fromRGB(240, 130, 40)

local model = Instance.new("Model")
model.Name = "GardenL1"

-- Local placement in the area: x across (+x = left seen from the gate), z depth (+z = back).
local function at(x: number, y: number, z: number): CFrame
	return area * CFrame.new(x, y, z)
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
	p.CastShadow = size.Magnitude > 6
	p.Parent = model
	return p
end

-- An upright cylinder (Roblox cylinders run along X).
local function post(name: string, cf: CFrame, height: number, diameter: number, colour: Color3): Part
	return part(name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.PartType.Cylinder)
end

-- ===== two raised beds =====
local BED_W, BED_L, BED_H = 6, 12, 1.4
local function bed(x: number, z: number, crop: string)
	-- frame: two long and two short planks around a soil block
	for _, s in { -1, 1 } do
		part("BedPlank", Vector3.new(0.6, BED_H, BED_L + 0.6), at(x + s * BED_W / 2, BED_H / 2, z), HONEY_DARK, nil, Enum.Material.Wood)
		part("BedPlank", Vector3.new(BED_W, BED_H, 0.6), at(x, BED_H / 2, z + s * BED_L / 2), HONEY, nil, Enum.Material.Wood)
	end
	part("Soil", Vector3.new(BED_W - 0.6, BED_H - 0.3, BED_L - 0.6), at(x, (BED_H - 0.3) / 2, z), SOIL, nil, Enum.Material.Ground)
	-- two rows of young vegetables
	for row = -1, 1, 2 do
		for k = -2, 2 do
			local cf = at(x + row * 1.4, BED_H, z + k * 2.2)
			if crop == "carrot" then
				-- a carrot's orange shoulder showing under a green tuft
				post("CarrotTop", cf * CFrame.new(0, 0.1, 0), 0.5, 0.8, CARROT)
				for t = 1, 3 do
					local a = t * 2.1
					part("Tuft", Vector3.new(0.35, 1.3, 0.35), cf * CFrame.new(math.cos(a) * 0.2, 0.9, math.sin(a) * 0.2) * CFrame.Angles(math.sin(a) * 0.35, 0, math.cos(a) * 0.35), LEAF)
				end
			else
				-- a small round cabbage
				part("Cabbage", Vector3.new(1.4, 1.1, 1.4), cf * CFrame.new(0, 0.45, 0), LEAF_LIGHT, Enum.PartType.Ball)
				part("CabbageLeaf", Vector3.new(1.8, 0.4, 1.8), cf * CFrame.new(0, 0.15, 0), LEAF, Enum.PartType.Ball)
			end
		end
	end
end
bed(-6, 4, "carrot")
bed(6, 4, "cabbage")

-- ===== the work spot (one) =====
-- A round straw mat on the path between the beds: where a working slime tends the garden.
local spotCf = at(0, 0.1, 2)
local spot = post("GardenSpot1", spotCf, 0.15, 3.6, Color3.fromRGB(232, 200, 120))
spot.Material = Enum.Material.Fabric
local mark = Instance.new("Attachment")
mark.Name = "WorkSpot1"
mark.Parent = spot

-- A watering can beside the mat.
post("CanBody", at(1.8, 0.75, -0.4), 1.3, 1.3, Color3.fromRGB(90, 140, 200)).Material = Enum.Material.Metal
part("CanSpout", Vector3.new(0.25, 0.25, 1.6), at(1.8, 1.1, -1.4) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(90, 140, 200), nil, Enum.Material.Metal)

-- A navy slime stand-in on the spot (the real slime model comes later).
local slime = part("SlimeStandIn", Vector3.new(4, 3.4, 4), spotCf * CFrame.new(0, 1.8, 0), Color3.fromRGB(28, 70, 214), Enum.PartType.Ball)
slime.Reflectance = 0.15
part("SlimeTip", Vector3.new(1.2, 1.4, 1.2), spotCf * CFrame.new(0, 3.6, 0), Color3.fromRGB(28, 70, 214), Enum.PartType.Ball).Reflectance = 0.15

-- ===== low picket fence, open at the front =====
local FX, FZ0, FZ1 = 13, -9, 15
local function fenceRun(x0: number, z0: number, x1: number, z1: number)
	local from, to = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
	local len = (to - from).Magnitude
	local dir = (to - from).Unit
	local n = math.floor(len / 2)
	for k = 0, n do
		local p = from + dir * (k * len / n)
		part("Picket", Vector3.new(0.5, 2.2, 0.5), at(p.X, 1.1, p.Z), Color3.fromRGB(240, 226, 196))
	end
	local mid = (from + to) / 2
	local yaw = math.atan2(dir.X, dir.Z)
	for _, y in { 0.7, 1.6 } do
		part("Rail", Vector3.new(0.3, 0.3, len), at(mid.X, y, mid.Z) * CFrame.Angles(0, yaw, 0), Color3.fromRGB(225, 208, 172))
	end
end
fenceRun(-FX, FZ1, FX, FZ1) -- back
fenceRun(-FX, FZ0, -FX, FZ1) -- left side
fenceRun(FX, FZ0, FX, FZ1) -- right side
fenceRun(-FX, FZ0, -4, FZ0) -- front, left of the opening
fenceRun(4, FZ0, FX, FZ0) -- front, right of the opening

-- A path of three stepping stones from the opening to the mat.
for k, z in { -8, -5, -2 } do
	post("SteppingStone", at(math.sin(k) * 0.6, 0.08, z), 0.16, 2.2, Color3.fromRGB(196, 190, 176)).Material = Enum.Material.Slate
end

-- ===== the area's signpost (carrot icon) and props =====
local signCf = at(-6.5, 0, FZ0 - 1.5)
post("SignPost", signCf * CFrame.new(0, 2, 0), 4, 0.6, HONEY_DARK)
local sign = part("Sign", Vector3.new(3, 2, 0.35), signCf * CFrame.new(0, 3.6, -0.4), HONEY)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(150, 100)
gui.LightInfluence = 0.6
local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromScale(1, 1)
icon.BackgroundTransparency = 1
icon.Text = "🥕"
icon.TextScaled = true
icon.Parent = gui
gui.Parent = sign

-- A seed sack and a water barrel inside the fence corners.
part("SeedSack", Vector3.new(2, 2.4, 1.8), at(10, 1.1, -6), Color3.fromRGB(226, 206, 160), Enum.PartType.Ball, Enum.Material.Fabric)
part("SackTie", Vector3.new(0.8, 0.4, 0.8), at(10, 2.35, -6), WOOD_DARK, Enum.PartType.Ball)
post("Barrel", at(-10.5, 1.4, 12.5), 2.8, 2.6, HONEY_DARK).Material = Enum.Material.Wood
post("BarrelWater", at(-10.5, 2.82, 12.5), 0.05, 2.2, Color3.fromRGB(90, 170, 220))
for _, y in { 0.5, 2.3 } do
	post("BarrelHoop", at(-10.5, y, 12.5), 0.25, 2.75, Color3.fromRGB(110, 110, 116))
end

-- One flowering bush outside the fence corner.
for k, o in { { 0, 0, 1 }, { 1.1, 0.4, 0.8 }, { -1, 0.3, 0.75 } } do
	part("Bush", Vector3.one * 3.4 * o[3], at(16.5 + o[1], 1.6 * o[3], 13 + o[2]), if k == 1 then LEAF else LEAF_LIGHT, Enum.PartType.Ball)
end
for k = 1, 3 do
	part("Flower", Vector3.one * 0.6, at(16.5 + math.sin(k * 2) * 1.6, 3.1, 13 + math.cos(k * 2) * 1.2), Color3.fromRGB(255, 252, 240), Enum.PartType.Ball)
end

model.Parent = plotModel or workspace
return "garden L1 built: " .. #model:GetChildren() .. " parts, area at " .. tostring(area.Position)
