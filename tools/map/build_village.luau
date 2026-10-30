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
-- (one part per 2-stud cell: VillageStages recolours the paving cell by cell for each era's pattern)
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
-- (docs/VILLAGE_SCALE.md: the plaza grows with the plot, paths are sized to the slime)
local PLAZA = math.floor(15 * Config.Map.PlotSize / 160 + 0.5)
local PATH_W = Config.Map.PathWidth
local MAIN_W = Config.Map.MainPathWidth
local PLAZA_CELLS = math.ceil(PLAZA / 2)
for gx = -PLAZA_CELLS, PLAZA_CELLS - 1 do
	for gz = -PLAZA_CELLS, PLAZA_CELLS - 1 do
		local r = Vector2.new(gx * 2 + 1, gz * 2 + 1).Magnitude
		if r <= PLAZA then
			tile(gx, gz, if r > PLAZA - 2.2 then STONE_DARK else STONE)
		end
	end
end

-- paths: from the plaza's edge to a point in front of each area, `width` studs wide
local function path(from: Vector3, to: Vector3, width: number?)
	local d = to - from
	local steps = math.ceil(d.Magnitude / 1)
	local reach = (width or PATH_W) / 2 - 1
	for k = 0, steps do
		local p = from + d * (k / steps)
		for ox = -reach, reach, 2 do
			for oz = -reach, reach, 2 do
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
path(Vector3.new(0, 0, -(PLAZA - 1)), Vector3.new(0, 0, -HALF + 1), MAIN_W) -- to the gate

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
	local side = Vector3.new(t.Z, 0, -t.X).Unit * (PATH_W / 2 + 2)
	local p = t * 0.62 + side
	lamp(p.X, p.Z)
end
lamp(-(MAIN_W / 2 + 2), -HALF + 14)
lamp(MAIN_W / 2 + 2, -HALF + 14)

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
	m.Parent = nature
end
-- a ring of trees inside the fence, between the areas, with a bush at each foot
local CELL = Config.Map.PlotSize / 3
local ring = {}
for _, s in { -1, 1 } do
	-- (the corner areas are turned 45 degrees, so their corners reach in toward the middles)
	table.insert(ring, { s * CELL / 2, HALF - 8 })
	table.insert(ring, { s * (CELL / 2 - 4), -HALF + 8 })
	table.insert(ring, { HALF - 8, s * CELL * 0.45 })
	table.insert(ring, { -HALF + 8, s * CELL * 0.45 })
end
-- (the trees themselves are the owner's, placed below with `place`)
for i, p in ring do
	put(if i % 2 == 0 then "FloweringBush" else "BerryBush", p[1] + 4, p[2] - 2, 0.8, i * 30)
	put("GrassTuft", p[1] - 3.5, p[2] + 1, 1.4, i * 60)
end
-- the campfire in the empty front-right cell (the owner, 2026-10-27): built below
-- flower patches along both sides of each path, and either side of the gate
for i, t in pathEnds do
	local side = Vector3.new(t.Z, 0, -t.X).Unit * (PATH_W / 2 + 2.5)
	local p = t * 0.4 - side
	put("FlowerPatch", p.X, p.Z, 1.1, i * 40)
	local q = t * 0.85 - side
	put("GrassTuft", q.X, q.Z, 1.3, i * 70)
end
for _, s in { -1, 1 } do
	put("FloweringBush", s * (MAIN_W / 2 + 4), -HALF + 6, 0.9, 0)
	put("FlowerPatch", s * (MAIN_W / 2 + 3), -HALF + 20, 1.2, 0)
end
nature.Parent = village

-- ===== the campfire (the owner, 2026-10-27) in the empty front-right cell =====
-- A round earth floor with a stone ring, a log teepee with fire from the owner's VFX, small seats
-- round it (the owner's log benches and kit stumps, all turned to the fire), lantern posts, and tall
-- trees from the owner's library behind. The owner's models live in ServerStorage.OwnerKit (inserted
-- from his inventory with the MCP insert_asset tool, scripts removed).
local ownerKit = game:GetService("ServerStorage"):FindFirstChild("OwnerKit")
local camp = Vector3.new(-CELL, 0, -CELL)
local CAMP_R = 11
local EARTH = Color3.fromRGB(176, 128, 84)
local EARTH_DARK = Color3.fromRGB(150, 104, 66)
for gx = -6, 5 do
	for gz = -6, 5 do
		local x, z = gx * 2 + 1, gz * 2 + 1
		local r = Vector2.new(x, z).Magnitude
		if r <= CAMP_R then
			tile(math.floor((camp.X + x) / 2), math.floor((camp.Z + z) / 2), if r > CAMP_R - 2.2 then EARTH_DARK else EARTH)
		end
	end
end
-- a path from the plaza to the campfire's edge (its direction is the plaza's one free gap)
local toCamp = camp.Unit
path(toCamp * (PLAZA - 1), camp - toCamp * (CAMP_R - 1))

-- Places a model of a kit standing on the ground at plot (x, z), `height` studs tall, turned so that
-- its longer side runs along `along` (a flat direction) when given, else by `turn` degrees.
local function place(src: Instance?, x: number, z: number, height: number, turn: number?, along: Vector3?): Model?
	if not src or not src:IsA("Model") then
		return nil
	end
	local m = src:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local _, size0 = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * height / size0.Y)
	local box, size = m:GetBoundingBox()
	local yaw = math.rad(turn or 0)
	if along then
		local long = if size.X >= size.Z then box.RightVector else box.LookVector
		local function heading(v: Vector3): number
			return math.atan2(-v.Z, v.X)
		end
		yaw = heading(along) - heading(long)
	end
	local pivot = m:GetPivot()
	m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, yaw, 0) * pivot.Rotation)
	box, size = m:GetBoundingBox()
	local target = at(x, size.Y / 2, z).Position
	m:PivotTo(m:GetPivot() + (target - box.Position))
	m.Parent = nature
	return m
end

local fire = at(camp.X, 0.3, camp.Z)
-- the stone ring
for k = 0, 9 do
	local a = k * math.pi / 5
	local s = part("FireStone", Vector3.new(1.5, 0.9, 1.3), fire * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.45, 2.3), if k % 2 == 0 then STONE else STONE_DARK, nil, Enum.Material.Plastic)
	s.TopSurface = Enum.SurfaceType.Studs
end
part("Embers", Vector3.new(0.2, 3.4, 3.4), fire * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 120, 40), Enum.PartType.Cylinder, Enum.Material.Neon)
-- a teepee of five logs leaning in, and two lying across under it
for k = 0, 4 do
	local a = k * math.pi * 2 / 5
	pole("FireLog", fire * CFrame.Angles(0, a, 0) * CFrame.new(0, 1.2, 0.75) * CFrame.Angles(math.rad(-32), 0, 0), 2.8, 0.45, WOOD_DARK, Enum.Material.Wood)
end
for _, a in { 0.4, 2.0 } do
	part("FireLogFlat", Vector3.new(3.2, 0.5, 0.5), fire * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.35, 0) * CFrame.Angles(math.rad(90), 0, 0), HONEY_DARK, Enum.PartType.Cylinder, Enum.Material.Wood)
end

-- A real-looking fire (the owner: "fire like real"), the same recipe as the kitchen stove's: the glow,
-- embers and heat of the "Realistic Fire VFX" pack in the owner's inventory (OwnerKit.CampFlame,
-- scaled, its bloom calmed and its flame tongues kept low), and two layers of licking flames with
-- Roblox's own flame texture. The light is tagged "Flicker" for the client's FireFlicker.
local function addFire(parent: Instance, base: CFrame, scale: number): BasePart
	local core = Instance.new("Part")
	core.Name = "FireCore"
	core.Size = Vector3.one * scale
	core.CFrame = base
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.Parent = parent
	local pack = ownerKit and ownerKit:FindFirstChild("CampFlame")
	if pack then
		local m = pack:Clone()
		m:ScaleTo(0.45 * scale)
		m:PivotTo(base - Vector3.new(0, 0.5 * scale, 0))
		for _, d in m:GetDescendants() do
			if d:IsA("ParticleEmitter") and d.Name == "bloom" then
				d.Rate = 12
				d.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.92), NumberSequenceKeypoint.new(1, 1) })
			elseif d:IsA("ParticleEmitter") and d.Name == "smoke" then
				d.Speed = NumberRange.new(4.5 * scale, 6 * scale)
			elseif d:IsA("Light") then
				d:Destroy() -- (one light, below)
			end
		end
		m.Parent = parent
	end
	local at0 = Instance.new("Attachment")
	at0.Name = "Flames"
	at0.Parent = core
	local function flames(c0: Color3, c1: Color3, size: number, life: number, rate: number, speed: number)
		local e = Instance.new("ParticleEmitter")
		e.Name = "Flame"
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Color = ColorSequence.new(c0, c1)
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(0.4, size * 1.1), NumberSequenceKeypoint.new(1, size * 0.15) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(0.75, 0.35), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(life * 0.7, life)
		e.Rate = rate
		e.Speed = NumberRange.new(speed * 0.7, speed)
		e.SpreadAngle = Vector2.new(10, 10)
		e.Rotation = NumberRange.new(-15, 15)
		e.RotSpeed = NumberRange.new(-30, 30)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = at0
	end
	flames(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 80, 20), 2.8 * scale, 0.9, 22, 3.6 * scale)
	flames(Color3.fromRGB(255, 250, 200), Color3.fromRGB(255, 170, 60), 1.4 * scale, 0.6, 18, 2.8 * scale)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 70)
	light.Brightness = 2
	light.Range = 18 * scale
	light.Parent = core
	light:AddTag("Flicker")
	return core
end
addFire(village, fire * CFrame.new(0, 0.6, 0), 1)

-- small seats round the fire, turned to it: log benches and stumps by turns
for k = 0, 5 do
	local a = math.rad(15) + k * math.pi / 3
	local dir = Vector3.new(math.sin(a), 0, math.cos(a))
	local p = camp + dir * 6.8
	local tangent = Vector3.new(dir.Z, 0, -dir.X)
	if k % 2 == 0 then
		place(ownerKit and ownerKit:FindFirstChild("LogBench"), p.X, p.Z, 2.2, nil, tangent)
	else
		put("Stump", p.X, p.Z, 0.65, k * 50)
	end
end
-- lantern posts and tall trees on the far side, toward the fence corner
for _, s in { -1, 1 } do
	local a = math.rad(225) + s * math.rad(50)
	local p = camp + Vector3.new(math.sin(a), 0, math.cos(a)) * (CAMP_R + 1.5)
	lamp(p.X, p.Z) -- (replace_props swaps it for the kit lamp post, as on the plaza)
end
local BIG = { { "TallPineLarge", 225, 21, 26 }, { "BroadleafTree", 175, 21, 22 }, { "TallPineDense", 275, 21, 24 }, { "TallPineLarge", 135, 22, 21 } }
for i, t in BIG do
	local a = math.rad(t[2])
	local p = camp + Vector3.new(math.sin(a), 0, math.cos(a)) * t[3]
	place(ownerKit and ownerKit:FindFirstChild(t[1]), p.X, p.Z, t[4], i * 70)
end
-- the ring of big trees inside the fence: the owner's trees (the owner: trees from his library, tall)
local RING_TREES = { "BroadleafTree", "TallPineLarge", "BanyanTree", "TallPineDense", "TallPineSlender", "TallPineSparse" }
for i, p in ring do
	place(ownerKit and ownerKit:FindFirstChild(RING_TREES[(i - 1) % #RING_TREES + 1]), p[1], p[2], 22 + (i % 3) * 3, i * 47)
end
for k = 0, 3 do
	local a = math.rad(200) + k * math.rad(25)
	local p = camp + Vector3.new(math.sin(a), 0, math.cos(a)) * (CAMP_R + 3)
	put(if k % 2 == 0 then "FlowerPatch" else "Fern", p.X, p.Z, 1.3, k * 80)
end

-- ===== the tall fence round the plot =====
local EDGE = HALF -- (on the floor's very edge, so the fence hides it: the owner saw the floor showing outside)
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
-- (no name sign over the gate: the owner, 2026-10-28)

village.Parent = plot
return "village built: " .. #village:GetChildren() .. " parts"
