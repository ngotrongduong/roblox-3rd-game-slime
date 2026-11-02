-- The shared middle of the valley (docs/MAP.md 1.4, reference art/concept/valley-middle.png): paths from the 9 gates to
-- the Heart and two circles, three rings each harder going in, the four mood quarters blending across them, one clearing
-- with a glowing puddle at each of the 108 homes of the zombie groups, and the old goo spring at the Heart. Run in Edit
-- mode through Studio's MCP; it rewrites the terrain inside the ring road's outer side and everything in
-- workspace.Map.WildGarden, so running it again gives the same map. Check it with tools/map/check_wild_slices.luau.
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Zombies = require(ReplicatedStorage.Shared.Zombies)

local M = Config.Map
local terrain = workspace.Terrain
local GROUND = M.GroundY

-- ===== the plan =====
local OUTER_PATH_RADIUS = 261
local INNER_PATH_RADIUS = 191
local PATH_WIDTH = M.PathWidth
local PATH_RAISE = 0.2 -- the slab's top above the ground: enough not to flicker, too little to step over
local ROAD_RAISE = 0.6 -- the road strip lies over sand and grass, whose bumps and blades stand a little over the ground
local PATH_THICK = 0.4
local PATH_COLOUR = Color3.fromRGB(226, 196, 146)
local RADIAL_SEGMENT = 64 -- a long part streams badly: radial paths come in pieces this long
local CIRCLE_SEGMENTS = { [OUTER_PATH_RADIUS] = 60, [INNER_PATH_RADIUS] = 48, [M.HeartRadius] = 28 }
local ROAD_SEGMENTS = 96

-- What must stay free (the zombies' roam, a team's stand and march; the slime is 3.5 wide).
local HOME_CLEAR = 16
local LINE_CLEAR = 3
local PATH_CLEAR = 1

-- Terrain. Voxels are 4 studs; columns filled from y = -16 up to y = 0 show their surface at GroundY (2).
local CELL = 4
local CHUNK = 64
local TERRAIN_BOTTOM = -16
local TERRAIN_TOP = 16
local SOLID_CELLS = 4
local WRITE_RADIUS = 384 -- up to the gates: outside the road only its height is flattened, its material stays
local ROAD_INNER = M.RingRoadRadius - M.RingRoadWidth / 2
local ROAD_OUTER = M.RingRoadRadius + M.RingRoadWidth / 2
local ROAD_TUCK = 3 -- the road's terrain ends this far inside the clean strip's edge
local GATE_SAND = 4 -- the sand under a path between the road and its gate
local MOOD_WOBBLE = 22 -- degrees the quarters' borders wander by, broad then fine, so they blend
local MOOD_FINE = 9
local SNOW_NOISE = 0.5

local COLOURS = {
	[Enum.Material.LeafyGrass] = Color3.fromRGB(108, 164, 34), -- meadow, outer
	[Enum.Material.Mud] = Color3.fromRGB(46, 142, 94), -- mushroom, outer
	[Enum.Material.Ground] = Color3.fromRGB(132, 130, 34), -- ember, outer
	[Enum.Material.Concrete] = Color3.fromRGB(126, 88, 30), -- ember, groves
	[Enum.Material.Glacier] = Color3.fromRGB(70, 146, 164), -- frost, outer
	[Enum.Material.Asphalt] = Color3.fromRGB(30, 100, 106), -- frost and mushroom, groves
	[Enum.Material.Snow] = Color3.fromRGB(226, 238, 250), -- frost drifts
	[Enum.Material.Salt] = Color3.fromRGB(62, 44, 102), -- inner ring
	[Enum.Material.Pavement] = Color3.fromRGB(48, 34, 82), -- inner ring, its dark blots
	[Enum.Material.Limestone] = Color3.fromRGB(72, 138, 42), -- meadow, groves
	[Enum.Material.Sand] = Color3.fromRGB(232, 210, 150), -- clearings (also the Market's)
	[Enum.Material.Sandstone] = Color3.fromRGB(226, 196, 146), -- the ring road
	[Enum.Material.CrackedLava] = Color3.fromRGB(240, 110, 36),
	[Enum.Material.Basalt] = Color3.fromRGB(92, 70, 64),
}
-- A soft mottled near-white picture (made by script, uploaded for this map), tinted by the terrain colour: a variant with no
-- map at all draws lime whatever the colour, and terrain's own textures bring their own hue.
local FLAT_MAP = "rbxassetid://138249545071236"
local FLAT_TILE = 90 -- studs: the tile is broad, soft mottling
local FLAT_MATERIALS = {
	Enum.Material.LeafyGrass,
	Enum.Material.Mud,
	Enum.Material.Ground,
	Enum.Material.Concrete,
	Enum.Material.Glacier,
	Enum.Material.Asphalt,
	Enum.Material.Snow,
	Enum.Material.Salt,
	Enum.Material.Pavement,
	Enum.Material.Limestone,
	Enum.Material.CrackedLava,
	Enum.Material.Basalt,
}
local GROUND_OF = {
	meadow = { Enum.Material.LeafyGrass, Enum.Material.Limestone },
	mushroom = { Enum.Material.Mud, Enum.Material.Asphalt },
	ember = { Enum.Material.Ground, Enum.Material.Concrete },
	frost = { Enum.Material.Glacier, Enum.Material.Asphalt },
}
-- Clockwise from north, as in the reference (not Layout.Quarters, which has an older order).
local MOODS = { "meadow", "mushroom", "ember", "frost" }

-- Lava lies flat in the ground along the lines between two slices, where no march runs: { angle, from, to }.
local LAVA = { { 220, 266, 342 }, { 220, 196, 258 } }
local LAVA_WIDTH = 5.5
local LAVA_BANK = 8.5
local LAVA_WANDER = 2 -- degrees: the homes either side of the line are only 5 degrees off it
-- The inner ring's goo: flat pools in a chain, at these angles.
local GOO_ANGLES = { 60, 100, 140, 180, 260, 340 }
local GOO_FROM, GOO_TO, GOO_STEP = 78, 134, 14
local GOO_COLOUR = Color3.fromRGB(84, 190, 50)

-- A puddle in each clearing: a flat disc lit by its material (no lights: 108 of them would cost phones).
local PUDDLE_SIZE = 8
local PUDDLE_COLOUR = Color3.fromRGB(44, 176, 70)
local CLEARING_DISC = 20
local CLEARING_COLOUR = Color3.fromRGB(198, 160, 100)
local PUDDLE_THICK = 0.3
local PUDDLE_RAISE = 0.12

-- Scenery, per wedge of the valley between two paths: how many big and small things each ring tries to hold.
local SEED = 20261102
local WEDGES = 9
local TRIES = 160
local SPACING = 3 -- free ground between two things
local BIG_PER_WEDGE = { outer = 5, middle = 12, inner = 6 }
local SMALL_PER_WEDGE = { outer = 14, middle = 8, inner = 5 }
local RINGS = {
	outer = { from = OUTER_PATH_RADIUS, to = ROAD_INNER },
	middle = { from = INNER_PATH_RADIUS, to = OUTER_PATH_RADIUS },
	inner = { from = M.HeartRadius, to = INNER_PATH_RADIUS },
}
-- { kit, name, least scale, most scale, tint }.
local RED = Color3.fromRGB(206, 62, 44)
local LEAF = Color3.fromRGB(62, 150, 54)
local LEAF_DEEP = Color3.fromRGB(38, 118, 58)
local AMETHYST = Color3.fromRGB(150, 92, 220)
local BIG = {
	outer = {
		meadow = { { "NatureKit", "OakTree", 1.5, 2, LEAF } },
		mushroom = { { "PropKit", "GiantMushroom", 0.9, 1.3 } },
		ember = { { "NatureKit", "AutumnTree", 1.2, 1.5 }, { "NatureKit", "MediumRock", 2.5, 3.5 } },
		frost = { { "NatureKit", "SnowCoveredPine", 1.1, 1.6 }, { "NatureKit", "SnowyPine", 1, 1.4 } },
	},
	middle = {
		meadow = { { "NatureKit", "OakTree", 1, 1.5, LEAF }, { "NatureKit", "OakTree", 0.9, 1.3, LEAF_DEEP } },
		mushroom = { { "NatureKit", "OakTree", 0.9, 1.3, LEAF_DEEP }, { "PropKit", "GiantMushroom", 0.7, 1 } },
		ember = {
			{ "NatureKit", "AutumnTree", 1, 1.5 },
			{ "NatureKit", "AutumnTree", 0.9, 1.3, RED },
			{ "NatureKit", "OakTree", 0.9, 1.2, LEAF },
		},
		frost = {
			{ "NatureKit", "TallPine", 1.2, 1.7 },
			{ "NatureKit", "SnowCoveredPine", 1.1, 1.5 },
			{ "NatureKit", "SnowyPine", 1.1, 1.5 },
		},
	},
}
local INNER_BIG = { { "PropKit", "TwistedTree", 1, 1.4 } }
local SMALL = {
	meadow = {
		{ "NatureKit", "FloweringBush", 1.1, 1.5 },
		{ "KitCache", "flower_daisies", 0.55, 0.8 },
		{ "KitCache", "flower_tulips_red", 0.4, 0.55 },
		{ "NatureKit", "Bush", 0.7, 1 },
	},
	mushroom = {
		{ "PropKit", "GiantMushroom", 0.25, 0.5 },
		{ "NatureKit", "FloweringBush", 1, 1.4 },
		{ "NatureKit", "Fern", 1.8, 2.5 },
	},
	ember = {
		{ "PropKit", "EmberPlant", 0.4, 0.7 },
		{ "NatureKit", "MediumRock", 1.2, 2 },
		{ "PropKit", "EmberPlant", 0.3, 0.5 },
	},
	frost = {
		{ "NatureKit", "SnowyBush", 1.1, 1.6 },
		{ "PropKit", "CrystalCluster", 0.35, 0.7 },
		{ "NatureKit", "SnowyMediumRock", 1.2, 2 },
	},
}
local INNER_SMALL = { { "PropKit", "CrystalCluster", 0.3, 0.6, AMETHYST } }
-- The share of a thing's spread that stands low enough to stop a slime: the rest is crown over their heads.
local UNDER = { OakTree = 0.52, AutumnTree = 0.52, GiantMushroom = 0.4, TwistedTree = 0.45 }
local BIG_SHADOW = true -- big trees keep their shadow, small things never

-- The Heart.
local HEART_FLOOR = Color3.fromRGB(150, 136, 150)
local HEART_TUCK = 6 -- the sand under the Heart's floor stops short of its edge, or it bleeds out past the rim path
local SPRING_RADIUS = 13
local SPRING_COLOUR = Color3.fromRGB(84, 196, 58)
local SPRING_CORE = Color3.fromRGB(150, 226, 90)
local SPRING_LIGHT_RANGE = 34
local SPRING_LIGHT = 1.4
local ARCH_DISTANCE = 30
local ARCH_SCALE = 2
local BASIN_SIZE = 32
local BASIN_HEIGHT = 3.2
local SPRING_LIFT = 1.2
local HEART_STONES = { { 62, 44, 3.2 }, { 118, 46, 2.6 }, { 240, 45, 3 }, { 300, 44, 2.8 }, { 180, 47, 2.4 } }

-- ===== where things are =====
local function flat(p: Vector3): Vector3
	return Vector3.new(p.X, 0, p.Z)
end

local homes = {}
local lines = {}
for slice = 0, M.PlotCount do
	local gate = Layout.sliceGate(slice)
	for camp = 1, #Config.Zombies.LevelOffsets do
		for index = 1, Config.Zombies.GroupsPerCamp do
			local across, forward = Zombies.campOffset(camp, index)
			local home = flat((gate * CFrame.new(across, 0, -forward)).Position)
			table.insert(homes, home)
			table.insert(lines, { flat(gate.Position), home })
		end
	end
end
local gates = {}
for slice = 0, M.PlotCount do
	table.insert(gates, flat(Layout.sliceGate(slice).Position))
end

local function toSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

-- Whether a thing may stand here: radius is its whole spread, under what is left of it below a slime's head (a tree's
-- crown may reach over a march line, its trunk not; nothing reaches over a home).
local function free(p: Vector3, radius: number, under: number): boolean
	local r = p.Magnitude
	for _, ring in { OUTER_PATH_RADIUS, INNER_PATH_RADIUS, M.HeartRadius } do
		if math.abs(r - ring) < PATH_WIDTH / 2 + PATH_CLEAR + radius then
			return false
		end
	end
	if r + radius > ROAD_INNER - 2 then
		return false
	end
	for _, home in homes do
		if (p - home).Magnitude < HOME_CLEAR + radius then
			return false
		end
	end
	for _, line in lines do
		if toSegment(p, line[1], line[2]) < LINE_CLEAR + under then
			return false
		end
	end
	for _, gate in gates do
		if toSegment(p, gate, gate.Unit * M.HeartRadius) < PATH_WIDTH / 2 + PATH_CLEAR + radius then
			return false
		end
	end
	return true
end

local function angleOf(x: number, z: number): number
	return math.deg(math.atan2(x, -z)) % 360
end

local function moodAt(x: number, z: number): string
	local a = angleOf(x, z)
		+ math.noise(x / 80, z / 80, 3.1) * MOOD_WOBBLE
		+ math.noise(x / 18, z / 18, 7.7) * MOOD_FINE
	return MOODS[math.floor((a % 360) / 90) + 1]
end

-- ===== terrain =====
local function cellKey(x: number, z: number): number
	return math.floor(x / CELL) * 4096 + math.floor(z / CELL)
end

-- What is painted over a ring's ground: lava and clearings, later over earlier.
local painted: { [number]: Enum.Material } = {}
local function stamp(centre: Vector3, radius: number, material: Enum.Material)
	local reach = math.ceil(radius / CELL) + 1
	local cx, cz = math.floor(centre.X / CELL), math.floor(centre.Z / CELL)
	for i = cx - reach, cx + reach do
		for j = cz - reach, cz + reach do
			local x, z = i * CELL + CELL / 2, j * CELL + CELL / 2
			if (Vector3.new(x, 0, z) - centre).Magnitude <= radius then
				painted[cellKey(x, z)] = material
			end
		end
	end
end

local function planPaint()
	for _, gate in gates do
		local dir = gate.Unit
		for r = ROAD_OUTER - 2, gate.Magnitude, 2 do
			stamp(dir * r, GATE_SAND, Enum.Material.Sandstone)
		end
	end
	for _, lava in LAVA do
		for r = lava[2], lava[3], 2 do
			local a = lava[1] + math.sin(r / 19 + lava[2]) * LAVA_WANDER
			stamp(Layout.polar(a, r), LAVA_BANK, Enum.Material.Basalt)
		end
	end
	for _, lava in LAVA do
		for r = lava[2], lava[3], 2 do
			local a = lava[1] + math.sin(r / 19 + lava[2]) * LAVA_WANDER
			stamp(Layout.polar(a, r), LAVA_WIDTH, Enum.Material.CrackedLava)
		end
	end
end

local function surface(x: number, z: number, was: Enum.Material): Enum.Material
	local r = math.sqrt(x * x + z * z)
	if r > ROAD_OUTER - ROAD_TUCK then
		if was ~= Enum.Material.Sand and painted[cellKey(x, z)] == Enum.Material.Sandstone then
			return Enum.Material.Sandstone
		end
		return if was == Enum.Material.Air or was == Enum.Material.Sandstone then Enum.Material.Grass else was
	elseif r >= ROAD_INNER + ROAD_TUCK and r <= ROAD_OUTER - ROAD_TUCK then
		-- (the Market's own wide way across the road stays)
		return if was == Enum.Material.Sand then was else Enum.Material.Sandstone
	elseif r < M.HeartRadius - HEART_TUCK then
		return Enum.Material.Sandstone
	end
	local stamped = painted[cellKey(x, z)]
	if stamped then
		return stamped
	end
	if r < INNER_PATH_RADIUS then
		return if math.noise(x / 26, z / 26, 11.3) > 0.12 then Enum.Material.Pavement else Enum.Material.Salt
	end
	local mood = moodAt(x, z)
	local outer = r >= OUTER_PATH_RADIUS
	if mood == "frost" and outer and math.noise(x / 22, z / 22, 5.5) > SNOW_NOISE then
		return Enum.Material.Snow
	end
	return GROUND_OF[mood][if outer then 1 else 2]
end

local function buildTerrain()
	for material, colour in COLOURS do
		terrain:SetMaterialColor(material, colour)
	end
	-- Terrain textures bring their own hue and bumps (a Salt that stays pale, a Slate that lifts over the paths): a variant
	-- with no maps draws the ground as the flat colour above.
	for _, material in FLAT_MATERIALS do
		local name = "WildFlat" .. material.Name
		local variant = MaterialService:FindFirstChild(name) :: MaterialVariant?
		if variant then
			variant:Destroy()
		end
		do
			local made = Instance.new("MaterialVariant")
			made.Name = name
			made.BaseMaterial = material
			made.ColorMap = FLAT_MAP
			made.StudsPerTile = FLAT_TILE
			made.Parent = MaterialService
		end
		MaterialService:SetBaseMaterialOverride(material, name)
	end
	planPaint()
	local size = CHUNK * CELL
	local reach = math.ceil(WRITE_RADIUS / size) * size
	for x0 = -reach, reach - size, size do
		for z0 = -reach, reach - size, size do
			local region = Region3.new(
				Vector3.new(x0, TERRAIN_BOTTOM, z0),
				Vector3.new(x0 + size, TERRAIN_TOP, z0 + size)
			)
			local mats, occs = terrain:ReadVoxels(region, CELL)
			local rows = mats.Size.Y
			local touched = false
			for i = 1, mats.Size.X do
				for k = 1, mats.Size.Z do
					local x = x0 + (i - 1) * CELL + CELL / 2
					local z = z0 + (k - 1) * CELL + CELL / 2
					if math.sqrt(x * x + z * z) <= WRITE_RADIUS then
						touched = true
						local was = Enum.Material.Air
						for y = rows, 1, -1 do
							if mats[i][y][k] ~= Enum.Material.Air and mats[i][y][k] ~= Enum.Material.Water then
								was = mats[i][y][k]
								break
							end
						end
						local top = surface(x, z, was)
						for y = 1, rows do
							if y <= SOLID_CELLS then
								mats[i][y][k] = if y == SOLID_CELLS then top else Enum.Material.Grass
								occs[i][y][k] = 1
							else
								mats[i][y][k] = Enum.Material.Air
								occs[i][y][k] = 0
							end
						end
					end
				end
			end
			if touched then
				terrain:WriteVoxels(region, CELL, mats, occs)
			end
		end
		task.wait()
	end
end

-- ===== parts =====
local map = workspace:WaitForChild("Map")
local root = map:FindFirstChild("WildGarden")
if root then
	root:ClearAllChildren()
else
	root = Instance.new("Folder")
	root.Name = "WildGarden"
	root.Parent = map
end
local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	return f
end
local pathsFolder = folder("Paths")
local puddlesFolder = folder("Puddles")
local gooFolder = folder("Goo")
local sceneryFolder = folder("Scenery")
local heartFolder = folder("Heart")

local function plain(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function slab(a: Vector3, b: Vector3)
	local mid = (a + b) / 2 + Vector3.new(0, GROUND + PATH_RAISE - PATH_THICK / 2, 0)
	plain(
		pathsFolder,
		"Path",
		Vector3.new(PATH_WIDTH, PATH_THICK, (b - a).Magnitude),
		CFrame.lookAt(mid, mid + (b - a)),
		PATH_COLOUR,
		Enum.Material.SmoothPlastic
	)
end

local function buildPaths()
	for _, gate in gates do
		local dir = gate.Unit
		local length = gate.Magnitude - M.HeartRadius
		local pieces = math.ceil(length / RADIAL_SEGMENT)
		for i = 1, pieces do
			local from = M.HeartRadius + (i - 1) * length / pieces
			local to = M.HeartRadius + i * length / pieces
			slab(dir * from, dir * to)
			if to > ROAD_OUTER then
				-- (from the road to the gate it lies over sand, as the road does)
				local last = pathsFolder:GetChildren()
				local p = last[#last] :: BasePart
				p.Position += Vector3.new(0, ROAD_RAISE - PATH_RAISE, 0)
			end
		end
	end
	-- The ring road, on the same principle: its terrain edge wanders by a voxel, so a clean strip lies over it.
	for i = 1, ROAD_SEGMENTS do
		local a = Layout.polar((i - 1) * 360 / ROAD_SEGMENTS, M.RingRoadRadius)
		local b = Layout.polar(i * 360 / ROAD_SEGMENTS, M.RingRoadRadius)
		local over = (b - a).Unit * 0.8
		local mid = (a + b) / 2 + Vector3.new(0, GROUND + ROAD_RAISE - PATH_THICK / 2, 0)
		plain(pathsFolder, "Road", Vector3.new(M.RingRoadWidth, PATH_THICK, (b - a).Magnitude + 2 * over.Magnitude), CFrame.lookAt(mid, mid + (b - a)), PATH_COLOUR, Enum.Material.SmoothPlastic)
	end
	for radius, count in CIRCLE_SEGMENTS do
		for i = 1, count do
			-- A little longer than the chord, so the joints close on the outside of the curve.
			local a0, a1 = (i - 1) * 360 / count, i * 360 / count
			local a, b = Layout.polar(a0, radius), Layout.polar(a1, radius)
			local over = (b - a).Unit * 0.4
			slab(a - over, b + over)
		end
	end
end

local function disc(parent: Instance, name: string, centre: Vector3, across: number, along: number, thick: number, yaw: number, colour: Color3, material: Enum.Material): Part
	-- (a cylinder's axis is its X: turned upright, its Y and Z sizes make the oval)
	return plain(
		parent,
		name,
		Vector3.new(thick, across, along),
		CFrame.new(centre) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.rad(90)),
		colour,
		material
	)
end

local function round(p: Part): Part
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function buildPuddles(rng: Random)
	for _, home in homes do
		local y = GROUND + PUDDLE_RAISE - PUDDLE_THICK / 2
		local yaw = rng:NextNumber(0, math.pi)
		-- The worn ground: a clean disc (a terrain one came out as a blurred diamond at 4-stud voxels).
		round(disc(puddlesFolder, "Clearing", home + Vector3.new(0, y - 0.04, 0), CLEARING_DISC, CLEARING_DISC * 0.88, PUDDLE_THICK, yaw, CLEARING_COLOUR, Enum.Material.SmoothPlastic))
		round(disc(puddlesFolder, "Puddle", home + Vector3.new(0, y, 0), PUDDLE_SIZE, PUDDLE_SIZE * 0.78, PUDDLE_THICK, yaw, PUDDLE_COLOUR, Enum.Material.Neon))
	end
end

local function buildGoo(rng: Random)
	for _, angle in GOO_ANGLES do
		local r = GOO_FROM
		while r <= GOO_TO do
			local a = angle + math.sin(r / 17 + angle) * 7
			local p = Layout.polar(a, r) + Vector3.new(0, GROUND + PUDDLE_RAISE - PUDDLE_THICK / 2, 0)
			local across = rng:NextNumber(5, 8)
			round(disc(gooFolder, "Goo", p, across, rng:NextNumber(18, 24), PUDDLE_THICK, math.rad(-a + rng:NextNumber(-20, 20)), GOO_COLOUR, Enum.Material.Neon))
			r += GOO_STEP
		end
	end
end

-- ===== scenery =====
local function source(entry): Instance?
	local kit = ServerStorage:FindFirstChild(entry[1])
	return kit and kit:FindFirstChild(entry[2])
end

local radii: { [Instance]: number } = {}
local function footRadius(src: Instance): number
	if radii[src] then
		return radii[src]
	end
	local size = if src:IsA("Model") then select(2, src:GetBoundingBox()) else (src :: BasePart).Size
	local r = math.max(size.X, size.Z) / 2
	radii[src] = r
	return r
end

local function dress(part: BasePart, big: boolean, tint: Color3?)
	part.Anchored = true
	part.CanTouch = false
	part.CanQuery = false
	part.CanCollide = big and part.Name == "Trunk"
	part.CastShadow = big and BIG_SHADOW
	if tint then
		local sa = part:FindFirstChildOfClass("SurfaceAppearance")
		if sa then
			sa:Destroy()
		end
		if part:IsA("MeshPart") and part.Name ~= "Trunk" then
			part.TextureID = ""
		end
		if part.Name ~= "Trunk" then
			part.Material = Enum.Material.SmoothPlastic
			part.Color = tint
		end
	end
end

-- A clone laid on the ground, as bare parts in the scenery folder (no Model per copy: half the instances).
local function place(entry, at: Vector3, yaw: number, scale: number, big: boolean, parent: Instance?)
	local src = source(entry)
	if not src then
		return
	end
	local copy = src:Clone()
	local holder = copy
	if not copy:IsA("Model") then
		holder = Instance.new("Model")
		copy.Parent = holder
	end
	holder:ScaleTo(holder:GetScale() * scale)
	holder:PivotTo(CFrame.new(holder:GetPivot().Position) * CFrame.Angles(0, yaw, 0) * holder:GetPivot().Rotation)
	local box, size = holder:GetBoundingBox()
	local foot = at + Vector3.new(0, GROUND - 0.25 + size.Y / 2, 0)
	holder:PivotTo(holder:GetPivot() + (foot - box.Position))
	for _, d in holder:GetDescendants() do
		if d:IsA("BasePart") then
			dress(d, big, entry[5])
			if UNDER[entry[2]] and d.Name ~= "Foliage" and d.Name ~= "Trunk" then
				d:SetAttribute("Kit", entry[2])
			end
			d.Parent = parent or sceneryFolder
		end
	end
	holder:Destroy()
end

local function buildScenery(rng: Random): (number, { string })
	local standing: { { Vector3 | number } } = {}
	local placed = 0
	local missing = {}
	local checks = 0
	local function scatter(ringName: string, wedge: number, count: number, pick: (string) -> { any }, big: boolean)
		local ring = RINGS[ringName]
		local centre = (wedge - 0.5) * 360 / WEDGES
		for _ = 1, count do
			for _ = 1, TRIES do
				checks += 1
				if checks % 400 == 0 then
					task.wait()
				end
				local a = centre + rng:NextNumber(-20, 20)
				local r = rng:NextNumber(ring.from, ring.to)
				local p = flat(Layout.polar(a, r))
				local choices = pick(moodAt(p.X, p.Z))
				local entry = choices[rng:NextInteger(1, #choices)]
				local src = source(entry)
				if not src then
					missing[entry[2]] = true
					break
				end
				local scale = rng:NextNumber(entry[3], entry[4])
				local radius = footRadius(src) * scale
				local ok = free(p, radius, radius * (UNDER[entry[2]] or 1))
				if ok then
					for _, s in standing do
						if ((s[1] :: Vector3) - p).Magnitude < (s[2] :: number) + radius + SPACING then
							ok = false
							break
						end
					end
				end
				if ok then
					place(entry, p, rng:NextNumber(0, math.pi * 2), scale, big)
					table.insert(standing, { p, radius })
					placed += 1
					break
				end
			end
		end
	end
	for wedge = 1, WEDGES do
		for ringName, _ in RINGS do
			local pickBig = function(mood: string)
				if ringName == "inner" then
					return INNER_BIG
				end
				return BIG[ringName][mood]
			end
			scatter(ringName, wedge, BIG_PER_WEDGE[ringName], pickBig, true)
		end
	end
	for wedge = 1, WEDGES do
		for ringName, _ in RINGS do
			local pickSmall = function(mood: string)
				return if ringName == "inner" then INNER_SMALL else SMALL[mood]
			end
			scatter(ringName, wedge, SMALL_PER_WEDGE[ringName], pickSmall, false)
		end
	end
	local names = {}
	for name in missing do
		table.insert(names, name)
	end
	return placed, names
end

-- ===== the Heart =====
local function buildHeart()
	local y = GROUND + PUDDLE_RAISE - PUDDLE_THICK / 2
	round(disc(heartFolder, "Floor", Vector3.new(0, y - 0.04, 0), M.HeartRadius * 2, M.HeartRadius * 2, PUDDLE_THICK, 0, HEART_FLOOR, Enum.Material.Slate))
	place({ "PropKit", "GooBasin", 1, 1 }, Vector3.zero, 0, 1, true, heartFolder)
	local basin = ServerStorage.PropKit:FindFirstChild("GooBasin")
	if basin then
		-- The kit model is fitted to BASIN_SIZE across here.
		for _, p in heartFolder:GetChildren() do
			if p:IsA("BasePart") and p.Name ~= "Floor" then
				p:Destroy()
			end
		end
		local _, size = basin:GetBoundingBox()
		place({ "PropKit", "GooBasin", 1, 1 }, Vector3.zero, 0, BASIN_SIZE / math.max(size.X, size.Z), true, heartFolder)
		-- Wide and low: pressed down on its own axis so the rim stays under a slime's chin.
		for _, p in heartFolder:GetChildren() do
			if p:IsA("BasePart") and p.Name ~= "Floor" then
				p.Size = Vector3.new(p.Size.X, BASIN_HEIGHT, p.Size.Z)
				p.Position = Vector3.new(p.Position.X, GROUND + BASIN_HEIGHT / 2 - 0.2, p.Position.Z)
			end
		end
	end
	local lift = SPRING_LIFT
	local pool = round(disc(heartFolder, "Spring", Vector3.new(0, y + lift, 0), SPRING_RADIUS * 2, SPRING_RADIUS * 2, PUDDLE_THICK, 0, SPRING_COLOUR, Enum.Material.Neon))
	round(disc(heartFolder, "SpringRing", Vector3.new(0, y + lift + 0.04, 0), SPRING_RADIUS * 1.1, SPRING_RADIUS * 1.1, PUDDLE_THICK, 0, SPRING_CORE, Enum.Material.Neon))
	round(disc(heartFolder, "SpringEye", Vector3.new(0, y + lift + 0.08, 0), SPRING_RADIUS * 0.75, SPRING_RADIUS * 0.75, PUDDLE_THICK, 0, SPRING_COLOUR, Enum.Material.Neon))
	local light = Instance.new("PointLight")
	light.Color = SPRING_COLOUR
	light.Range = SPRING_LIGHT_RANGE
	light.Brightness = SPRING_LIGHT
	light.Parent = pool
	-- The arch faces the spring from the north.
	place({ "PropKit", "RuinArch", 1, 1 }, Layout.polar(0, ARCH_DISTANCE), math.pi, ARCH_SCALE, true, heartFolder)
	for _, stone in HEART_STONES do
		place({ "NatureKit", "MossyBoulder", 1, 1 }, Layout.polar(stone[1], stone[2]), stone[1], stone[3], true, heartFolder)
	end
end

-- ===== build =====
local rng = Random.new(SEED)
buildTerrain()
buildPaths()
buildPuddles(rng)
buildGoo(rng)
task.wait()
local placed, missing = buildScenery(rng)
buildHeart()

local parts, meshes, shadows, collide = 0, 0, 0, 0
local unique: { [string]: boolean } = {}
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
		if d:IsA("MeshPart") then
			meshes += 1
			unique[d.MeshId] = true
		end
		if d.CastShadow then
			shadows += 1
		end
		if d.CanCollide then
			collide += 1
		end
	end
end
local uniqueCount = 0
for _ in unique do
	uniqueCount += 1
end
return string.format(
	"wild slices built: %d things placed, %d instances, %d parts (%d meshes of %d shapes, paths %d, puddles %d, goo %d, scenery %d), %d cast shadows, %d collide; missing kit: %s",
	placed,
	#root:GetDescendants(),
	parts,
	meshes,
	uniqueCount,
	#pathsFolder:GetChildren(),
	#puddlesFolder:GetChildren(),
	#gooFolder:GetChildren(),
	#sceneryFolder:GetChildren(),
	shadows,
	collide,
	table.concat(missing, ",")
)
