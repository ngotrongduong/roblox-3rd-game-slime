-- The home plot as a small village (the owner, 2026-10-27): every area turned to face the plot's
-- middle (Layout.plotAreaFacing), a round stone stud plaza with a well in the middle, stone stud paths
-- from the plaza to each area's front and to the gate, and a tall wooden fence all round with a big
-- gate at the front. Run in Edit mode through MCP after the area builders, then stud_floor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2
local HALF = Config.Map.PlotSize / 2
local plotFrame = Layout.plotFrame(PLOT)
local plot = workspace.Map["Plot" .. PLOT]

-- Clear the greybox left in the plot (hedge, gate posts, meadow house, hatchery nest) and any
-- previous village.
local GREYBOX = {
	Hedge = true,
	PostL = true,
	PostR = true,
	Sign = true,
	HomeWalls = true,
	HomeRoofA = true,
	HomeRoofB = true,
	Nest = true,
	Egg = true,
	Village = true,
}
for _, c in plot:GetChildren() do
	if GREYBOX[c.Name] then
		c:Destroy()
	end
end

local STONE = Color3.fromRGB(196, 192, 182)
local STONE_DARK = Color3.fromRGB(160, 156, 148)
local PATH = Color3.fromRGB(214, 200, 168)
local HONEY = Color3.fromRGB(205, 146, 82)
local HONEY_DARK = Color3.fromRGB(150, 98, 52)
local WOOD_DARK = Color3.fromRGB(110, 70, 40)
local ROOF = Color3.fromRGB(196, 96, 64)
local GOLD = Color3.fromRGB(240, 196, 70)

local village = Instance.new("Model")
village.Name = "Village"

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
	p.Parent = village
	return p
end

local function pole(name: string, cf: CFrame, height: number, diameter: number, colour: Color3, material: Enum.Material?): Part
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
	w.Parent = village
end

-- Plot-local placement, y up from the ground's surface.
local function at(x: number, y: number, z: number): CFrame
	return plotFrame * CFrame.new(x, y + GROUND, z)
end

-- ===== stone stud tiles on a 2-stud grid (plaza and paths share it, so they never overlap) =====
local laid: { [string]: boolean } = {}
local function tile(gx: number, gz: number, colour: Color3)
	local key = gx .. "," .. gz
	if laid[key] then
		return
	end
	laid[key] = true
	local t = part("Paving", Vector3.new(2, 0.3, 2), at(gx * 2 + 1, 0.15, gz * 2 + 1), colour, nil, Enum.Material.Plastic)
	t.TopSurface = Enum.SurfaceType.Studs
	t.CastShadow = false
end

-- the plaza: a round patch of stone, a darker ring at its edge
local PLAZA = 15
for gx = -9, 8 do
	for gz = -9, 8 do
		local r = Vector2.new(gx * 2 + 1, gz * 2 + 1).Magnitude
		if r <= PLAZA then
			tile(gx, gz, if r > PLAZA - 2.2 then STONE_DARK else STONE)
		end
	end
end

-- paths: from the plaza's edge to a point in front of each area, 6 studs wide
local function path(from: Vector3, to: Vector3)
	local d = to - from
	local steps = math.ceil(d.Magnitude / 1)
	for k = 0, steps do
		local p = from + d * (k / steps)
		for ox = -2, 2, 2 do
			for oz = -2, 2, 2 do
				tile(math.floor((p.X + ox) / 2), math.floor((p.Z + oz) / 2), PATH)
			end
		end
	end
end
-- each area's front point in its own (facing) frame, where its entrance is
local FRONTS = {
	{ -1, 1, -3, -18 }, -- fishing pond: the shore end of the dock
	{ 0, 1, 0, -11.5 }, -- pantry
	{ 1, 1, 0, -10 }, -- garden: the fence opening
	{ -1, 0, 0, -10.5 }, -- kitchen
	{ 1, 0, 4, -14 }, -- breeding pen: its gate
	{ -1, -1, 0, -13.5 }, -- training ground: its opening
}
local pathEnds: { Vector3 } = {}
for _, f in FRONTS do
	local world = (Layout.plotAreaFacing(PLOT, f[1], f[2]) * CFrame.new(f[3], 0, f[4])).Position
	local target = plotFrame:PointToObjectSpace(world)
	local flat = Vector3.new(target.X, 0, target.Z)
	path(flat.Unit * (PLAZA - 1), flat)
	table.insert(pathEnds, flat)
end
path(Vector3.new(0, 0, -(PLAZA - 1)), Vector3.new(0, 0, -HALF + 1)) -- to the gate

-- ===== the well in the middle of the plaza =====
local well = at(0, 0.3, 0)
for k = 0, 11 do
	local a = k * math.pi / 6
	part("WellStone", Vector3.new(1.9, 2.4, 1.2), well * CFrame.Angles(0, a, 0) * CFrame.new(0, 1.2, 2.6), if k % 2 == 0 then STONE else STONE_DARK, nil, Enum.Material.Plastic).TopSurface =
		Enum.SurfaceType.Studs
end
pole("WellWater", well * CFrame.new(0, 1.7, 0), 0.1, 4.6, Color3.fromRGB(70, 160, 220))
for _, s in { -1, 1 } do
	part("WellPost", Vector3.new(0.6, 6, 0.6), well * CFrame.new(s * 2.9, 3, 0), HONEY_DARK, nil, Enum.Material.Wood)
end
part("WellBeam", Vector3.new(6.4, 0.5, 0.5), well * CFrame.new(0, 5.4, 0), HONEY_DARK, nil, Enum.Material.Wood)
wedge("WellRoof", Vector3.new(7.4, 1.8, 2.4), well * CFrame.new(0, 6.6, -1.2), ROOF)
wedge("WellRoof", Vector3.new(7.4, 1.8, 2.4), well * CFrame.new(0, 6.6, 1.2) * CFrame.Angles(0, math.pi, 0), ROOF)
part("WellRope", Vector3.new(0.15, 2.2, 0.15), well * CFrame.new(0, 4.2, 0), Color3.fromRGB(226, 196, 140))
pole("WellBucket", well * CFrame.new(0, 2.8, 0), 1, 1, HONEY, Enum.Material.Wood)

-- ===== lamp posts, planters round the plaza =====
local function lamp(x: number, z: number)
	local base = at(x, 0.3, z)
	pole("LampPost", base * CFrame.new(0, 3.5, 0), 7, 0.5, WOOD_DARK, Enum.Material.Wood)
	local bulb = part("Lamp", Vector3.new(1, 1.3, 1), base * CFrame.new(0, 7.4, 0), Color3.fromRGB(255, 214, 120), nil, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 120)
	light.Brightness = 1
	light.Range = 14
	light.Parent = bulb
	part("LampCap", Vector3.new(1.5, 0.4, 1.5), base * CFrame.new(0, 8.2, 0), WOOD_DARK)
end
local FLOWERS = { Color3.fromRGB(240, 132, 168), Color3.fromRGB(255, 252, 240), GOLD, Color3.fromRGB(150, 196, 236) }
-- the paths leave the plaza every 45 degrees (one gap: the empty front-right cell), so the lamps
-- stand halfway between them, each with a planter of flowers on the well's side
for k = 0, 3 do
	local a = math.rad(22.5) + k * math.pi / 2
	local dir = Vector3.new(math.sin(a), 0, math.cos(a))
	local p = dir * (PLAZA - 2)
	lamp(p.X, p.Z)
	local q = dir * (PLAZA - 5)
	local planter = at(q.X, 0.3, q.Z)
	part("Planter", Vector3.new(2.4, 1.2, 2.4), planter * CFrame.new(0, 0.6, 0), HONEY, nil, Enum.Material.Wood)
	for f = 0, 3 do
		local fa = f * math.pi / 2
		part("PlanterFlower", Vector3.one * 0.8, planter * CFrame.new(math.cos(fa) * 0.6, 1.5, math.sin(fa) * 0.6), FLOWERS[f + 1], Enum.PartType.Ball)
	end
end
-- a lamp beside each path, two thirds of the way out, and one each side of the gate path
for _, t in pathEnds do
	local side = Vector3.new(t.Z, 0, -t.X).Unit * 5
	local p = t * 0.62 + side
	lamp(p.X, p.Z)
end
lamp(-5, -HALF + 14)
lamp(5, -HALF + 14)

-- ===== trees, bushes and flowers from the nature kit =====
-- (ServerStorage.NatureKit: the free Creator Store "Nature stylized Pack", see dress_plot_nature)
local kit = game:GetService("ServerStorage"):FindFirstChild("NatureKit")
local nature = Instance.new("Folder")
nature.Name = "Nature"
local function put(key: string, x: number, z: number, scale: number, turn: number?)
	local src = kit and kit:FindFirstChild(key)
	if not src then
		return
	end
	local m = src:Clone()
	m:ScaleTo(scale)
	local pivot = m:GetPivot()
	m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.rad(turn or 0), 0) * pivot.Rotation)
	local box, size = m:GetBoundingBox()
	local target = at(x, size.Y / 2, z).Position
	m:PivotTo(m:GetPivot() + (target - box.Position))
	if key:find("Tree") or key:find("Pine") then
		m:AddTag("Sway")
	end
	m.Parent = nature
end
-- a ring of trees inside the fence, between the areas, with a bush at each foot
local CELL = Config.Map.PlotSize / 3
local TREES = { "OakTree", "BirchTree", "AutumnTree", "TallPine" }
local ring = {}
for _, s in { -1, 1 } do
	-- (the corner areas are turned 45 degrees, so their corners reach in toward the middles)
	table.insert(ring, { s * CELL / 2, HALF - 8 })
	table.insert(ring, { s * (CELL / 2 - 4), -HALF + 8 })
	table.insert(ring, { HALF - 8, s * 24 })
	table.insert(ring, { -HALF + 8, s * 24 })
end
for i, p in ring do
	put(TREES[(i - 1) % #TREES + 1], p[1], p[2], 0.9 + (i % 3) * 0.1, i * 47)
	put(if i % 2 == 0 then "FloweringBush" else "BerryBush", p[1] + 4, p[2] - 2, 0.8, i * 30)
	put("GrassTuft", p[1] - 3.5, p[2] + 1, 1.4, i * 60)
end
-- the empty front-right cell (kept for a later area): a little grove with a log and flowers
local grove = { -CELL, -CELL }
put("AutumnTree", grove[1] + 6, grove[2] + 4, 1, 20)
put("BirchTree", grove[1] - 8, grove[2] - 5, 0.9, 80)
put("Log", grove[1] - 1, grove[2] + 6, 1.2, 35)
put("Stump", grove[1] + 2, grove[2] - 8, 1, 0)
put("FlowerPatch", grove[1] - 4, grove[2] + 1, 1.6, 0)
put("FlowerPatch", grove[1] + 7, grove[2] - 6, 1.4, 90)
put("SmallRocks", grove[1] - 10, grove[2] + 8, 1.2, 0)
-- flower patches along both sides of each path, and either side of the gate
for i, t in pathEnds do
	local side = Vector3.new(t.Z, 0, -t.X).Unit * 5.5
	local p = t * 0.4 - side
	put("FlowerPatch", p.X, p.Z, 1.1, i * 40)
	local q = t * 0.85 - side
	put("GrassTuft", q.X, q.Z, 1.3, i * 70)
end
for _, s in { -1, 1 } do
	put("FloweringBush", s * 9, -HALF + 6, 0.9, 0)
	put("FlowerPatch", s * 8, -HALF + 20, 1.2, 0)
end
nature.Parent = village

-- ===== the tall fence round the plot =====
local EDGE = HALF - 1
local GATE = 18
local H = 10
local function fenceRun(x0: number, z0: number, x1: number, z1: number)
	local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
	local alongX = math.abs(x1 - x0) > 0
	local n = math.max(1, math.floor(len / 8 + 0.5))
	for k = 0, n do
		local t = k / n
		local x, z = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
		part("FencePost", Vector3.new(2, H + 1.5, 2), at(x, (H + 1.5) / 2, z), WOOD_DARK, nil, Enum.Material.Wood)
		part("FencePostCap", Vector3.new(2.6, 0.6, 2.6), at(x, H + 1.8, z), HONEY_DARK)
		if k < n then
			local mx, mz = x + (x1 - x0) / n / 2, z + (z1 - z0) / n / 2
			local w = len / n - 2
			local size = if alongX then Vector3.new(w, H, 0.6) else Vector3.new(0.6, H, w)
			part("FencePanel", size, at(mx, H / 2, mz), HONEY, nil, Enum.Material.WoodPlanks)
			for _, y in { 1.2, H - 1.2 } do
				local rail = if alongX then Vector3.new(w, 0.7, 0.9) else Vector3.new(0.9, 0.7, w)
				part("FenceRail", rail, at(mx, y, mz), HONEY_DARK, nil, Enum.Material.Wood)
			end
		end
	end
end
fenceRun(-EDGE, EDGE, EDGE, EDGE) -- back
fenceRun(-EDGE, -EDGE, -EDGE, EDGE) -- sides
fenceRun(EDGE, -EDGE, EDGE, EDGE)
fenceRun(-EDGE, -EDGE, -GATE / 2 - 1.5, -EDGE) -- front, either side of the gate
fenceRun(GATE / 2 + 1.5, -EDGE, EDGE, -EDGE)

-- ===== the gate: two towers and a beam with the plot's sign =====
for _, s in { -1, 1 } do
	local tower = at(s * (GATE / 2 + 1.5), 0, -EDGE)
	part("GateTower", Vector3.new(3, H + 5, 3), tower * CFrame.new(0, (H + 5) / 2, 0), WOOD_DARK, nil, Enum.Material.Wood)
	part("GateTowerCap", Vector3.new(4, 0.8, 4), tower * CFrame.new(0, H + 5.4, 0), HONEY_DARK)
	wedge("GateTowerRoof", Vector3.new(4, 2, 2), tower * CFrame.new(0, H + 6.8, -1), ROOF)
	wedge("GateTowerRoof", Vector3.new(4, 2, 2), tower * CFrame.new(0, H + 6.8, 1) * CFrame.Angles(0, math.pi, 0), ROOF)
	local lamp = part("GateLamp", Vector3.new(1, 1.3, 1), tower * CFrame.new(0, H - 1, -2), Color3.fromRGB(255, 214, 120), nil, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 120)
	light.Range = 12
	light.Parent = lamp
end
part("GateBeam", Vector3.new(GATE + 6, 1.6, 1.6), at(0, H + 3.2, -EDGE), HONEY_DARK, nil, Enum.Material.Wood)
local board = part("GateSign", Vector3.new(10, 3, 0.5), at(0, H + 0.8, -EDGE - 0.4), HONEY, nil, Enum.Material.Wood)
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
gui.CanvasSize = Vector2.new(400, 120)
gui.LightInfluence = 0.6
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "Plot " .. PLOT -- the owner's name goes here in the game
label.TextScaled = true
label.Font = Enum.Font.FredokaOne
label.TextColor3 = Color3.fromRGB(110, 70, 40)
label.Parent = gui
gui.Parent = board

village.Parent = plot
return "village built: " .. #village:GetChildren() .. " parts"
