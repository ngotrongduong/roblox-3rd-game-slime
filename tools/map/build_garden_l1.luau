-- The level-1 vegetable garden of one home plot, built in Studio through MCP (Edit mode) in the
-- plot's garden area (back-right). Same style as the fishing pond: two raised wooden beds with young
-- vegetables, ONE work spot between them where a slime tends the beds, a low picket fence open at the
-- front, the area's signpost (carrot icon), and a few props. Rebuilds itself each run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY
local area = Layout.plotAreaFacing(PLOT, 1, 1)
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

-- Local placement in the area: x across (+x = left seen from the gate), z depth (+z = back), y up
-- from the ground's surface.
local function at(x: number, y: number, z: number): CFrame
	return area * CFrame.new(x, y + GROUND, z)
end

-- (the garden's own earth floor is laid below, turned with the area)

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

-- ===== the garden's earth floor (stud), inside the fence =====
-- (the village scale, 2026-10-30: the garden spread by 1.4, fence x +-18, z -12..21; src/server/GardenStages)
local earth = part("Floor", Vector3.new(36, 0.2, 33), at(0, 0.1, 4.5),Color3.fromRGB(150, 104, 66), nil, Enum.Material.Plastic)
earth.TopSurface = Enum.SurfaceType.Studs
earth.CastShadow = false

-- ===== the crop kit: each vegetable at four growth stages =====
-- Low-poly models from generate_mesh, kept in the work place's ServerStorage.CropKit as Carrot1..4 and
-- Cabbage1..4 (pivot at the foot, standing upright). A plant here is a model with attributes Crop and
-- Stage, tagged "Crop", the hook the growing system will use.
local cropKit = game:GetService("ServerStorage"):FindFirstChild("CropKit")
local function plant(crop: string, stage: number, spot: CFrame, turn: number)
	local src = cropKit and cropKit:FindFirstChild(crop .. stage)
	if not src then
		return
	end
	local m = src:Clone()
	m.Name = "Crop"
	m:PivotTo(spot * CFrame.Angles(0, math.rad(turn), 0))
	m:SetAttribute("Crop", crop)
	m:SetAttribute("Stage", stage)
	m:AddTag("Crop")
	m.Parent = model
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
	-- two rows of five plants, each a model of the crop kit at one growth stage (1 seedling, 2 young,
	-- 3 growing, 4 ripe). The game will grow them: it sets a plant's Stage and swaps in the next stage's
	-- model, scaling it up from the last one, so a bed goes from sprouts to a harvest. For now the
	-- rows show the stages side by side.
	for row = -1, 1, 2 do
		for k = -2, 2 do
			local stage = math.clamp(k + 3 + (if row == 1 then 0 else -1), 1, 4)
			local spot = at(x + row * 1.4, BED_H - 0.3, z + k * 2.2)
			plant(crop, stage, spot, (row * 7 + k) * 53)
		end
	end
end
bed(-8.5, 5.7, "Carrot")
bed(8.5, 5.7, "Cabbage")

-- ===== the work spot (one) =====
-- A round straw mat on the path between the beds: where a working slime tends the garden.
local spotCf = at(0, 0.3, 2.8) -- (on top of the earth floor)
local spot = post("GardenSpot1", spotCf, 0.15, 3.6, Color3.fromRGB(232, 200, 120))
spot.Material = Enum.Material.Fabric
local mark = Instance.new("Attachment")
mark.Name = "WorkSpot1"
mark.Parent = spot

-- A watering can beside the mat.
post("CanBody", at(1.8, 0.75, -0.4), 1.3, 1.3, Color3.fromRGB(90, 140, 200)).Material = Enum.Material.Metal
part("CanSpout", Vector3.new(0.25, 0.25, 1.6), at(1.8, 1.1, -1.4) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(90, 140, 200), nil, Enum.Material.Metal)


-- ===== low picket fence, open at the front =====
local FX, FZ0, FZ1 = 18, -12, 21
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

-- A straight line of three flat stepping stones on the earth, from the opening to the mat.
for _, z in { -10.6, -6.7, -2.8 } do
	post("SteppingStone", at(0, 0.3, z), 0.2, 2.2, Color3.fromRGB(196, 190, 176)).Material = Enum.Material.Slate
end

-- ===== the area's signpost (carrot icon) and props =====
local signCf = at(-9, 0, FZ0 - 1.5)
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

-- A water barrel inside the fence corner (the round seed sack was taken out: the owner, no balls).
post("Barrel", at(-14.7, 1.4, 17.5), 2.8, 2.6, HONEY_DARK).Material = Enum.Material.Wood
post("BarrelWater", at(-14.7, 2.82, 17.5), 0.05, 2.2, Color3.fromRGB(90, 170, 220))
for _, y in { 0.5, 2.3 } do
	post("BarrelHoop", at(-14.7, y, 17.5), 0.25, 2.75, Color3.fromRGB(110, 110, 116))
end

-- One flowering bush outside the fence corner.
for k, o in { { 0, 0, 1 }, { 1.1, 0.4, 0.8 }, { -1, 0.3, 0.75 } } do
	part("Bush", Vector3.one * 3.4 * o[3], at(21.5 + o[1], 1.6 * o[3], 18 + o[2]), if k == 1 then LEAF else LEAF_LIGHT, Enum.PartType.Ball)
end
for k = 1, 3 do
	part("Flower", Vector3.one * 0.6, at(21.5 + math.sin(k * 2) * 1.6, 3.1, 18 + math.cos(k * 2) * 1.2), Color3.fromRGB(255, 252, 240), Enum.PartType.Ball)
end

model.Parent = plotModel or workspace
return "garden L1 built: " .. #model:GetChildren() .. " parts, area at " .. tostring(area.Position)
