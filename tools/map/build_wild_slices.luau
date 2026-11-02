-- The shared middle of the valley (docs/MAP.md 1.4). The zones of art/concept/valley-middle.png stay (9 slices, 3 rings, four
-- moods), its look comes from art/concept/wild-1..4.png: real terrain textures blended by noise, winding dirt trails painted in
-- the terrain, tight dioramas of trees and props with open natural glades between them. Nothing marks a zombie group's home.
-- The owner's rejection of the first rebuild (2026-11-02): no circles, no straight paths, no flat colour, no simple trees.
-- Run in Edit mode through Studio's MCP; it rewrites the terrain inside the gates' radius and everything in
-- workspace.Map.WildGarden, so running it again gives the same map. Check it with tools/map/check_wild_slices.luau; the models
-- come from OwnerKit, NatureKit, KitCache, PropKit and WildKit (tools/map/wild_kit.luau).
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Zombies = require(ReplicatedStorage.Shared.Zombies)

local M = Config.Map
local terrain = workspace.Terrain
local rng = Random.new(20261103)
local Mat = Enum.Material

-- ===== the plan =====
-- What must stay free (the zombies' roam, a team's stand and march; the slime is 3.5 wide).
local HOME_CLEAR = 16 -- no collidable thing nearer a home
local GLADE_CLEAR = 13 -- no plant or low prop nearer a home: a glade is open ground
local LINE_CLEAR = 2.5 -- half a slime and a little: nothing that stands up nearer a march line
local CROWN_OVER_GLADE = 0.7 -- the share of a crown that must stay outside HOME_CLEAR, so a camera sees the group under it
local LOW_BOUGH = 3.5 -- a part starting under this over the ground stands in a slime's way
local CROWN_OVER_TRAIL = 0.42 -- likewise over a trail: trails stay open to the sky, as in the references
local HEART_CLEAR = 42 -- the boss rises here later: nothing at all stands inside
local RIM = 338 -- where the scenery stops, short of the ring road

-- Terrain. Voxels are 4 studs; columns filled from y = -16 up to y = 0 show their surface at GroundY (2), and the occupancy of
-- the next voxel up raises it: surface = 2 + 4 * occupancy (measured 2026-11-02).
local CELL = 4
local CHUNK = 64
local TERRAIN_BOTTOM = -16
local TERRAIN_TOP = 16
local SOLID_CELLS = 4
local WRITE_RADIUS = 384
local ROAD_RADIUS = M.RingRoadRadius
local ROAD_HALF = M.RingRoadWidth / 2
local RING_OUTER = 261 -- the rings' borders on the ground (they wander by RING_WOBBLE)
local RING_INNER = 191
local RING_WOBBLE = 20
local MOOD_WOBBLE = 22 -- degrees the quarters' borders wander by, broad then fine, so they blend
local MOOD_FINE = 9
local SWELL = 7 -- the gentle swells' height, away from every march line and home
local SWELL_LINE_FROM, SWELL_LINE_TO = 6, 30 -- no swell within the first distance of a line, full beyond the second
local SWELL_HOME_FROM, SWELL_HOME_TO = 20, 44

-- Terrain colours. Each material is one colour across the whole place: Grass and Rock belong to the valley and keep theirs, Sand
-- and Sandstone the Market's and the old roads'; the others are free inside this ring (tools/map/build_terrain.luau named them
-- for the old quarters, which this map replaced). Each has its own painted texture, and the materials' colours make the tones.
local COLOURS = {
	[Mat.Grass] = Color3.fromRGB(112, 182, 66),
	[Mat.Rock] = Color3.fromRGB(138, 132, 122),
	[Mat.Slate] = Color3.fromRGB(158, 146, 112), -- the Heart's floor: Rock's texture reads pink and noisy this close
	[Mat.Basalt] = Color3.fromRGB(92, 70, 64),
	[Mat.Sand] = Color3.fromRGB(232, 210, 150),
	[Mat.Sandstone] = Color3.fromRGB(204, 158, 98), -- the dirt roads: the old tan, warmed so it sits beside the rust instead of patching it
	[Mat.Ground] = Color3.fromRGB(158, 98, 50), -- worn earth: the rust of the references' trails ((176, 102, 66), build_terrain's own, reads pink)
	[Mat.LeafyGrass] = Color3.fromRGB(176, 170, 58), -- ember: dry golden grass
	[Mat.Limestone] = Color3.fromRGB(104, 128, 40), -- meadow: the sunny patches
	[Mat.Mud] = Color3.fromRGB(96, 98, 26), -- moss under the trees, the wood's floor
			[Mat.Snow] = Color3.fromRGB(236, 244, 252),
	[Mat.Glacier] = Color3.fromRGB(170, 215, 235),
	[Mat.CrackedLava] = Color3.fromRGB(244, 136, 40),
}
-- Materials this map does not use go back to Roblox's defaults (an earlier run tinted them).
local DEFAULT_COLOURS = {
	[Mat.Concrete] = Color3.fromRGB(127, 102, 63),
	[Mat.Asphalt] = Color3.fromRGB(115, 123, 107),
	[Mat.Salt] = Color3.fromRGB(198, 189, 181),
	[Mat.Pavement] = Color3.fromRGB(148, 148, 140),
	[Mat.Brick] = Color3.fromRGB(138, 86, 62),
	[Mat.Cobblestone] = Color3.fromRGB(132, 123, 90),
	[Mat.Ice] = Color3.fromRGB(129, 194, 224),
}

-- Each zone's ground, by share: which material a cell takes depends on broad and fine noise, so patches run into each other.
local GROUND = {
	meadow_outer = { { Mat.Grass, 0.62 }, { Mat.Limestone, 0.28 }, { Mat.Mud, 0.1 } },
	meadow_middle = { { Mat.Grass, 0.55 }, { Mat.Mud, 0.3 }, { Mat.Limestone, 0.15 } },
	mushroom_outer = { { Mat.Grass, 0.55 }, { Mat.Limestone, 0.2 }, { Mat.Mud, 0.25 } },
	mushroom_middle = { { Mat.Mud, 0.45 }, { Mat.Grass, 0.4 }, { Mat.Limestone, 0.15 } },
	ember_outer = { { Mat.LeafyGrass, 0.8 }, { Mat.Ground, 0.2 } },
	ember_middle = { { Mat.LeafyGrass, 0.68 }, { Mat.Ground, 0.32 } },
	frost_outer = { { Mat.Snow, 0.74 }, { Mat.Glacier, 0.2 }, { Mat.Mud, 0.06 } },
	frost_middle = { { Mat.Snow, 0.5 }, { Mat.Mud, 0.28 }, { Mat.Glacier, 0.22 } },
	inner = { { Mat.Mud, 0.78 }, { Mat.Grass, 0.1 }, { Mat.Ground, 0.12 } },
}
-- The worn earth and moss laid under a cluster of trees.
local UNDER_TREES = {
	meadow_outer = Mat.Mud,
	meadow_middle = Mat.Mud,
	mushroom_outer = Mat.Mud,
	mushroom_middle = Mat.Mud,
	ember_outer = Mat.Ground,
	ember_middle = Mat.Ground,
	frost_outer = Mat.Snow,
	frost_middle = Mat.Mud,
	inner = Mat.Mud,
}
local UNDER_RADIUS = 13
local HERO_SHARE = 0.6 -- how many clusters are led by one of the owner's big trees
local WORN_NOISE = 0.46 -- broad noise over this wears the ground to earth anywhere (never on snow)

-- Clockwise from north, as in the reference.
local MOODS = { "meadow", "mushroom", "ember", "frost" }

-- The trails. Which slices' main trail reaches the Heart; the others join a neighbour's on the way in.
local TRAIL_WIDTH = 7 -- drawn at about the owner's 6 studs: terrain blurs an edge away by a little each side
local BRANCH_WIDTH = 5.5
-- Cells this near a centre line are always trail, so a narrow stretch never breaks at 4-stud voxels. (Trails look broken into
-- dashes in any shot from a camera that has not rested: terrain near a camera takes seconds to get its fine mesh.)
local TRAIL_MIN_CELL = 3.9
local TRAIL_EDGE_NOISE = 1.7
local TRAIL_STEP = 3
local MERGE_GAP = 14 -- a home this near a trail needs no branch of its own
local REACH_HEART = { [0] = true, [2] = true, [3] = true, [5] = true, [7] = true }
local STONE_SHARE = 0.55 -- of the dressed spots along a trail, how many also have a flat stone lying in it
local RUT_NOISE = 0.34 -- darker earth runs along stretches of the trails and the road

-- Lava: a very few cracks on the free strip between two ember slices, where no march runs: { angle, from, to }.
local LAVA = { { 220, 272, 332 }, { 220, 196, 244 } }
local LAVA_WIDTH = 3.2
local LAVA_BANK = 5.6
local LAVA_WANDER = 2.2

-- ===== where things are =====
local function flat(p: Vector3): Vector3
	return Vector3.new(p.X, 0, p.Z)
end

local function polar(angle: number, radius: number): Vector3
	return flat(Layout.polar(angle, radius))
end

local function smooth(from: number, to: number, x: number): number
	local t = math.clamp((x - from) / (to - from), 0, 1)
	return t * t * (3 - 2 * t)
end

local homes: { Vector3 } = {}
local lines: { { Vector3 } } = {}
local homesOfSlice: { [number]: { { Vector3 } } } = {}
local gates: { [number]: Vector3 } = {}
for slice = 0, M.PlotCount do
	local gate = Layout.sliceGate(slice)
	gates[slice] = flat(gate.Position)
	homesOfSlice[slice] = {}
	for camp = 1, #Config.Zombies.LevelOffsets do
		homesOfSlice[slice][camp] = {}
		for index = 1, #Config.Zombies.Homes[camp] do
			local across, forward = Zombies.homeOffset(slice, camp, index)
			local home = flat((gate * CFrame.new(across, 0, -forward)).Position)
			table.insert(homes, home)
			table.insert(homesOfSlice[slice][camp], home)
			table.insert(lines, { flat(gate.Position), home })
		end
	end
end

local function toSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local function homeDistance(p: Vector3): number
	local best = math.huge
	for _, home in homes do
		local d = (p - home).Magnitude
		if d < best then
			best = d
		end
	end
	return best
end

local function lineDistance(p: Vector3): number
	local best = math.huge
	for _, line in lines do
		local d = toSegment(p, line[1], line[2])
		if d < best then
			best = d
		end
	end
	return best
end

local function moodAt(x: number, z: number): string
	local a = math.deg(math.atan2(x, -z))
		+ math.noise(x / 80, z / 80, 3.1) * MOOD_WOBBLE
		+ math.noise(x / 18, z / 18, 7.7) * MOOD_FINE
	return MOODS[math.floor((a % 360) / 90) + 1]
end

local function zoneAt(x: number, z: number): string
	local r = math.sqrt(x * x + z * z) + math.noise(x / 60, z / 60, 13.1) * RING_WOBBLE + math.noise(x / 17, z / 17, 2.2) * 6
	if r < RING_INNER then
		return "inner"
	end
	return moodAt(x, z) .. (if r < RING_OUTER then "_middle" else "_outer")
end

local function cellKey(x: number, z: number): number
	return math.floor(x / CELL) * 4096 + math.floor(z / CELL)
end

-- ===== the trails =====
-- The distance from each cell near a trail to that trail's edge (negative inside), and every sample, for joining and dressing.
local trailField: { [number]: number } = {}
local trailCore: { [number]: number } = {} -- the plain distance to a trail's centre
local trails: { { { at: Vector3, width: number } } } = {}
local samplesBySlice: { [number]: { { at: Vector3, width: number } } } = {}

local function stampTrail(at: Vector3, width: number)
	local reach = math.ceil((width / 2 + 14) / CELL)
	local cx, cz = math.floor(at.X / CELL), math.floor(at.Z / CELL)
	for i = cx - reach, cx + reach do
		for j = cz - reach, cz + reach do
			local x, z = i * CELL + CELL / 2, j * CELL + CELL / 2
			local key = i * 4096 + j
			local d = (Vector3.new(x, 0, z) - at).Magnitude
			local gap = d - width / 2
			if not trailField[key] or gap < trailField[key] then
				trailField[key] = gap
			end
			if not trailCore[key] or d < trailCore[key] then
				trailCore[key] = d
			end
		end
	end
end

local function trailGap(p: Vector3): number
	return trailField[cellKey(p.X, p.Z)] or 99
end

local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (3 * p1 - p0 - 3 * p2 + p3) * t * t * t)
end

-- A trail through these points: meandering between them, bent further by noise along its length, of varying width.
local function addTrail(points: { Vector3 }, width: number, slice: number, keepEnds: boolean?)
	local seed = rng:NextNumber(0, 500)
	local pts = { points[1] }
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		local length = (b - a).Magnitude
		local pieces = math.floor(length / 42)
		local side = (b - a).Unit:Cross(Vector3.yAxis)
		for k = 1, pieces - 1 do
			local swing = rng:NextNumber(-1, 1) * math.min(16, length * 0.2)
			table.insert(pts, a + (b - a) * (k / pieces) + side * swing)
		end
		table.insert(pts, b)
	end
	local line = {}
	for i = 1, #pts - 1 do
		local p0, p1, p2, p3 = pts[math.max(i - 1, 1)], pts[i], pts[i + 1], pts[math.min(i + 2, #pts)]
		local steps = math.max(1, math.ceil((p2 - p1).Magnitude / TRAIL_STEP))
		for s = 0, steps - 1 do
			table.insert(line, catmull(p0, p1, p2, p3, s / steps))
		end
	end
	table.insert(line, pts[#pts])
	local total = 0
	for i = 2, #line do
		total += (line[i] - line[i - 1]).Magnitude
	end
	local arc = 0
	local samples = {}
	for i, p in line do
		if i > 1 then
			arc += (p - line[i - 1]).Magnitude
		end
		local ahead = line[math.min(i + 1, #line)] - line[math.max(i - 1, 1)]
		local side = if ahead.Magnitude > 0 then ahead.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
		local fade = math.clamp(math.min(arc, total - arc) / 22, 0, 1)
		local bend = math.noise(arc / 36, seed) * 13 + math.noise(arc / 11, seed + 9) * 2.6
		local here = p + side * bend * fade
		local w = width * math.clamp(0.95 + math.noise(arc / 27, seed + 3) * 0.75, 0.62, 1.4)
		if not keepEnds then
			w *= 0.55 + 0.45 * math.clamp((total - arc) / 18, 0, 1) -- a branch thins out as it ends
		end
		stampTrail(here, w)
		table.insert(samples, { at = here, width = w })
	end
	table.insert(trails, samples)
	samplesBySlice[slice] = samplesBySlice[slice] or {}
	for _, s in samples do
		table.insert(samplesBySlice[slice], s)
	end
	return samples
end

local function nearestSample(samples, p: Vector3, least: number?)
	local best, bestGap = nil, math.huge
	for _, s in samples do
		local gap = (s.at - p).Magnitude
		if gap < bestGap and (not least or s.at.Magnitude > least) then
			best, bestGap = s, gap
		end
	end
	return best, bestGap
end

local function besideHome(home: Vector3, towards: Vector3): Vector3
	-- A point at a glade's edge, on the way a trail comes from, a little to one side: the trail skirts the home, never crosses it.
	local way = (towards - home).Unit
	local angle = rng:NextNumber(0.5, 1.2) * (if rng:NextNumber() < 0.5 then -1 else 1)
	local turned = CFrame.Angles(0, angle, 0):VectorToWorldSpace(way)
	return home + turned * rng:NextNumber(11, 15)
end

local function planTrails()
	-- The Heart's trails first, so the others have something to join.
	local order = {}
	for slice = 0, M.PlotCount do
		if REACH_HEART[slice] then
			table.insert(order, slice)
		end
	end
	for slice = 0, M.PlotCount do
		if not REACH_HEART[slice] then
			table.insert(order, slice)
		end
	end
	local visited: { [Vector3]: boolean } = {}
	for _, slice in order do
		local angle = Layout.slotAngle(slice)
		local drift = rng:NextNumber(-3, 3)
		local points = {
			polar(angle, 386),
			polar(angle + drift * 0.2, 372),
			polar(angle + drift, 344),
		}
		local from = points[#points]
		for camp = 1, 3 do
			local list = homesOfSlice[slice][camp]
			local picks = if camp == 1 and rng:NextNumber() < 0.6 then 2 else 1
			local start = rng:NextInteger(1, #list)
			for k = 0, picks - 1 do
				local home = list[(start + k - 1) % #list + 1]
				if not visited[home] then
					visited[home] = true
					local spot = besideHome(home, from)
					table.insert(points, spot)
					from = spot
				end
			end
		end
		if REACH_HEART[slice] then
			table.insert(points, polar(angle + rng:NextNumber(-24, 24), 56))
		else
			-- Join whichever trail of another slice lies nearest further in.
			local best, bestGap = nil, math.huge
			for other, samples in samplesBySlice do
				if other ~= slice then
					for _, s in samples do
						local r = s.at.Magnitude
						if r > 72 and r < from.Magnitude - 16 then
							local gap = (s.at - from).Magnitude
							if gap < bestGap then
								best, bestGap = s, gap
							end
						end
					end
				end
			end
			if best then
				table.insert(points, best.at)
			end
		end
		addTrail(points, TRAIL_WIDTH, slice, true)
		task.wait()
	end
	-- A branch to every home no trail passes yet; some run on to the trail of the next slice.
	for _, slice in order do
		for camp = 1, 3 do
			for _, home in homesOfSlice[slice][camp] do
				if not visited[home] then
					visited[home] = true
					local _, gap = nearestSample(samplesBySlice[slice], home)
					if gap > MERGE_GAP + 8 then
						local root = nearestSample(samplesBySlice[slice], home)
						local spot = besideHome(home, root.at)
						local points = { root.at, spot }
						if rng:NextNumber() < 0.4 then
							local other = (slice + (if rng:NextNumber() < 0.5 then 1 else M.PlotCount)) % (M.PlotCount + 1)
							local far, farGap = nearestSample(samplesBySlice[other], home, home.Magnitude - 30)
							if far and farGap < 95 then
								table.insert(points, far.at)
							end
						end
						addTrail(points, BRANCH_WIDTH, slice, #points > 2)
					end
				end
			end
		end
		task.wait()
	end
end

-- ===== the clusters =====
-- { kit, name, least height, most height, tints, trunk share of height, foot share of width }. Tints go to the canopy only.
local LIME = { Color3.fromRGB(158, 210, 66), Color3.fromRGB(128, 196, 58), Color3.fromRGB(178, 216, 78) }
local LEAF = { Color3.fromRGB(96, 176, 62), Color3.fromRGB(74, 160, 70), Color3.fromRGB(118, 186, 60) }
local TEAL = { Color3.fromRGB(46, 150, 112), Color3.fromRGB(60, 168, 110), Color3.fromRGB(38, 134, 122) }
local AUTUMN = { Color3.fromRGB(222, 62, 40), Color3.fromRGB(238, 118, 34), Color3.fromRGB(240, 158, 40), Color3.fromRGB(206, 46, 44) }
local DUSK = { Color3.fromRGB(126, 62, 126), Color3.fromRGB(104, 60, 122), Color3.fromRGB(150, 78, 138) }
local ICE = { Color3.fromRGB(196, 228, 240), Color3.fromRGB(170, 212, 232) }
local PINEGREEN = { Color3.fromRGB(70, 140, 110) }
local BARK = Color3.fromRGB(150, 104, 72)
local BARK_DUSK = Color3.fromRGB(112, 84, 80)

-- Yasu's trees are drawn slim; the references' are wide and thick in the trunk, so they are stretched this much across.
local YASU_STRETCH = 1.4
local function yasu(n: number, low: number, high: number, tints, bare: boolean?)
	return {
		kit = "WildKit",
		name = string.format("YasuTree%02d", n),
		low = low,
		high = high,
		tints = tints,
		bare = bare,
		trunk = 0.05,
		foot = 0.06,
		roots = true,
		stretch = YASU_STRETCH,
	}
end
local function owner(name: string, low: number, high: number, trunk: number?, foot: number?)
	return { kit = "OwnerKit", name = name, low = low, high = high, trunk = trunk or 0.07, foot = foot or 0.3 }
end
local function nature(name: string, low: number, high: number)
	return { kit = "NatureKit", name = name, low = low, high = high, trunk = 0.07, foot = 0.6 } -- (their boughs reach the ground)
end

local ROUND_TREES = { 1, 3, 5, 6, 13, 15, 17, 18 }
local function rounds(low: number, high: number, tints)
	local out = {}
	for _, n in ROUND_TREES do
		table.insert(out, yasu(n, low, high, tints))
	end
	return out
end
local function join(...)
	local out = {}
	for _, list in { ... } do
		for _, x in list do
			table.insert(out, x)
		end
	end
	return out
end

-- Plants and rocks: { kit, name, least height, most height, kind, tints }. A "rock" tilts and may collide, a "plant" never.
local function plant(kit: string, name: string, low: number, high: number, tints)
	return { kit = kit, name = name, low = low, high = high, kind = "plant", tints = tints }
end
local function rock(kit: string, name: string, low: number, high: number, tints)
	return { kit = kit, name = name, low = low, high = high, kind = "rock", tints = tints }
end

local TUFT_GREEN = { Color3.fromRGB(240, 255, 170), Color3.fromRGB(220, 250, 160) }
local TUFT_MOSS = { Color3.fromRGB(210, 220, 130), Color3.fromRGB(190, 210, 130) }
local TUFT_GOLD = { Color3.fromRGB(255, 220, 110), Color3.fromRGB(255, 190, 90) }
local TUFT_ICE = { Color3.fromRGB(235, 245, 255) }
local TUFT_TEAL = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(225, 250, 225) }
local SPIKE_VIOLET = { Color3.fromRGB(176, 120, 240), Color3.fromRGB(140, 100, 230) }
local SPIKE_PINK = { Color3.fromRGB(245, 130, 190), Color3.fromRGB(230, 110, 210) }
local SPIKE_RED = { Color3.fromRGB(240, 90, 60), Color3.fromRGB(240, 150, 50) }
local SPIKE_ICE = { Color3.fromRGB(190, 220, 250) }
local BUSH_RED = { Color3.fromRGB(226, 70, 44), Color3.fromRGB(240, 130, 44), Color3.fromRGB(246, 170, 50) }
local BUSH_GREEN = { Color3.fromRGB(110, 180, 64), Color3.fromRGB(78, 164, 74) }
local BUSH_TEAL = { Color3.fromRGB(50, 150, 110) }
local BUSH_DUSK = { Color3.fromRGB(150, 70, 150), Color3.fromRGB(110, 70, 160), Color3.fromRGB(70, 110, 70) }
local MUSHROOM_TINT = { Color3.fromRGB(170, 255, 200), Color3.fromRGB(190, 255, 190) }
local AMETHYST = { Color3.fromRGB(176, 110, 240) }

local function tufts(tints, low: number?, high: number?)
	local out = {}
	for _ = 1, 3 do
		table.insert(out, plant("NatureKit", "GrassTuft", low or 2.6, high or 4.2, tints))
	end
	return out
end
local function spikes(tints)
	return { plant("WildKit", "DokiFlower3", 4.4, 6.4, tints), plant("WildKit", "DokiFlower4", 4.4, 7, tints) }
end

-- The references' signature is a round grey boulder capped with moss. The kit's nearest: the owner's chunky rocks (3,000 triangles
-- each) and NatureKit's MossyBoulder, tan by itself, tinted grey here. (KitCache's rock_boulder_mossy is a flat pancake: not used.)
local STONE = { Color3.fromRGB(176, 178, 190), Color3.fromRGB(158, 162, 176) }
local ROCKS = {
	rock("OwnerKit", "WideBoulder", 3.8, 6.5),
	rock("OwnerKit", "StackedRocks", 3.8, 6.5),
	rock("OwnerKit", "JaggedRocks", 3.8, 6.5),
	rock("NatureKit", "MossyBoulder", 3, 6, STONE),
	rock("NatureKit", "MossyBoulder", 2.4, 4.6, STONE),
	rock("NatureKit", "MossyBoulder", 3.6, 6.5, STONE),
	rock("NatureKit", "MossyBoulder", 2, 3.4, STONE),
}
local SNOW_ROCKS = {
	rock("NatureKit", "SnowyBoulder", 2.5, 5.5),
	rock("NatureKit", "SnowyMediumRock", 2, 4.5),
}
local PEBBLES = { rock("KitCache", "rock_boulder_big", 0.8, 1.8, STONE) }
local SNOW_PEBBLES = { rock("NatureKit", "SnowyMediumRock", 0.8, 1.6) }
local LOGS = { rock("PropKit", "MossyLog", 4.4, 6), rock("NatureKit", "Log", 2.6, 3.6), rock("NatureKit", "Stump", 2.4, 3.6) }

local FLOWERS_MEADOW = join(
	spikes(SPIKE_VIOLET),
	spikes(SPIKE_PINK),
	{
		plant("KitCache", "flower_daisies", 3.4, 5),
		plant("KitCache", "flower_tulips_red", 3, 4.4),
		plant("PropKit", "PinkDaisies", 3.4, 5.4),
		plant("PropKit", "PinkDaisies", 2.6, 4),
	}
)
local AUTUMN_PLANT = plant("PropKit", "AutumnPlant", 3.6, 6.4)

local RECIPES = {
	meadow_outer = {
		hero = { owner("BroadleafTree", 42, 56), owner("BanyanTree", 40, 52) },
		spacing = 62,
		trees = join(rounds(30, 46, LIME), { owner("BroadleafTree", 30, 42) }),
		count = { 1, 2 },
		under = 7,
		plants = join(FLOWERS_MEADOW, tufts(TUFT_GREEN), { plant("NatureKit", "Fern", 3.6, 5.6) }),
		rocks = ROCKS,
		logs = 0.12,
		tufts = TUFT_GREEN,
		bank = FLOWERS_MEADOW,
	},
	meadow_middle = {
		hero = { owner("BroadleafTree", 42, 56), owner("BanyanTree", 42, 54), owner("VineTree", 40, 52) },
		spacing = 44,
		trees = join(rounds(26, 44, LEAF), { owner("BroadleafTree", 28, 42), owner("BanyanTree", 28, 40) }),
		count = { 2, 4 },
		under = 7,
		plants = join(
			{ plant("NatureKit", "Fern", 3.6, 5.6), plant("WildKit", "YasuBush01", 4, 7, BUSH_GREEN), plant("WildKit", "YasuBush02", 4, 6, BUSH_GREEN) },
			tufts(TUFT_GREEN),
			FLOWERS_MEADOW
		),
		rocks = ROCKS,
		logs = 0.15,
		tufts = TUFT_GREEN,
		bank = FLOWERS_MEADOW,
	},
	mushroom_outer = {
		hero = { owner("BanyanTree", 44, 58), owner("VineTree", 44, 58) },
		spacing = 52,
		trees = join({ owner("BanyanTree", 32, 44), owner("VineTree", 32, 44) }, rounds(28, 42, TEAL)),
		count = { 1, 3 },
		under = 7,
		plants = join(
			{ plant("PropKit", "GlowMushrooms", 5, 12, MUSHROOM_TINT), plant("PropKit", "GlowMushrooms", 3.5, 6, MUSHROOM_TINT), plant("NatureKit", "Fern", 4, 6) },
			tufts(TUFT_TEAL),
			spikes(SPIKE_VIOLET)
		),
		rocks = ROCKS,
		logs = 0.2,
		tufts = TUFT_TEAL,
		bank = join(spikes(SPIKE_VIOLET), { plant("PropKit", "GlowMushrooms", 3, 5.5, MUSHROOM_TINT) }),
	},
	mushroom_middle = {
		hero = { owner("BanyanTree", 46, 60), owner("VineTree", 46, 60), owner("BroadleafTree", 44, 56) },
		spacing = 38,
		trees = join({ owner("BanyanTree", 34, 48), owner("VineTree", 34, 48), owner("BroadleafTree", 30, 44) }, rounds(30, 46, TEAL)),
		count = { 3, 4 },
		under = 7,
		plants = join(
			{ plant("PropKit", "GlowMushrooms", 6, 14, MUSHROOM_TINT), plant("PropKit", "GlowMushrooms", 3.5, 6, MUSHROOM_TINT), plant("NatureKit", "Fern", 4, 6.5) },
			tufts(TUFT_TEAL)
		),
		rocks = ROCKS,
		logs = 0.25,
		tufts = TUFT_TEAL,
		bank = join(spikes(SPIKE_VIOLET), { plant("PropKit", "GlowMushrooms", 3, 5.5, MUSHROOM_TINT) }),
	},
	ember_outer = {
		spacing = 56,
		trees = rounds(28, 44, AUTUMN),
		count = { 1, 3 },
		under = 7,
		plants = join(
			{ AUTUMN_PLANT, AUTUMN_PLANT, plant("WildKit", "YasuBush01", 3, 6, BUSH_RED), plant("WildKit", "YasuBush02", 3, 5, BUSH_RED), plant("NatureKit", "DryBush", 2.5, 4), plant("KitCache", "flower_daisies", 3.2, 4.6) },
			tufts(TUFT_GOLD)
		),
		rocks = ROCKS,
		logs = 0.2,
		tufts = TUFT_GOLD,
		bank = { AUTUMN_PLANT, AUTUMN_PLANT, plant("KitCache", "flower_daisies", 3.2, 4.6), plant("WildKit", "YasuBush03", 3, 5, BUSH_RED) },
	},
	ember_middle = {
		spacing = 40,
		trees = rounds(28, 46, AUTUMN),
		count = { 2, 4 },
		under = 7,
		plants = join(
			{ AUTUMN_PLANT, AUTUMN_PLANT, plant("WildKit", "YasuBush01", 3, 6, BUSH_RED), plant("WildKit", "YasuBush03", 3, 5, BUSH_RED), plant("NatureKit", "DryBush", 2.5, 4), plant("NatureKit", "Fern", 3.4, 5) },
			tufts(TUFT_GOLD)
		),
		rocks = ROCKS,
		logs = 0.25,
		tufts = TUFT_GOLD,
		bank = { AUTUMN_PLANT, plant("KitCache", "flower_daisies", 3.2, 4.6), plant("WildKit", "YasuBush03", 3, 5, BUSH_RED) },
	},
	frost_outer = {
		spacing = 48,
		trees = {
			nature("SnowCoveredPine", 22, 38),
			nature("SnowCoveredPine", 18, 30),
			nature("SnowyPine", 20, 32),
			owner("FrozenDeadTree", 24, 34, 0.04, 0.25),
			yasu(10, 34, 46, ICE),
			nature("SnowCoveredOak", 22, 30),
		},
		count = { 2, 4 },
		under = 6,
		plants = join(
			{ plant("NatureKit", "SnowyBerryBush", 2.4, 4), plant("NatureKit", "SnowyBerryBush", 2, 3.4), plant("PropKit", "CrystalCluster", 3.4, 7) },
			tufts(TUFT_ICE, 2, 3.2)
		),
		rocks = SNOW_ROCKS,
		logs = 0,
		tufts = TUFT_ICE,
		bank = join(spikes(SPIKE_ICE), { plant("NatureKit", "SnowyBerryBush", 2, 3.2) }),
	},
	frost_middle = {
		spacing = 36,
		trees = {
			owner("TallPineLarge", 30, 44, 0.05, 0.2),
			owner("TallPineDense", 28, 42, 0.05, 0.2),
			owner("TallPineSparse", 28, 40, 0.04, 0.15),
			owner("TallPineSlender", 28, 40, 0.04, 0.15),
			nature("SnowCoveredPine", 24, 36),
			nature("SnowCoveredPine", 20, 30),
			yasu(10, 36, 48, PINEGREEN),
		},
		count = { 3, 5 },
		under = 6,
		plants = join(
			{ plant("NatureKit", "SnowyBerryBush", 2.4, 4), owner("PineBerryBush", 2.4, 4), plant("PropKit", "CrystalCluster", 3.4, 7) },
			tufts(TUFT_ICE, 2, 3.2)
		),
		rocks = SNOW_ROCKS,
		logs = 0,
		tufts = TUFT_ICE,
		bank = join(spikes(SPIKE_ICE), { plant("NatureKit", "SnowyBerryBush", 2, 3.2) }),
	},
	inner = {
		spacing = 30,
		trees = join({
			yasu(9, 30, 44, nil, true),
			yasu(19, 34, 48, nil, true),
			yasu(13, 28, 40, nil, true),
			yasu(17, 28, 40, nil, true),
			yasu(9, 32, 46, DUSK),
			yasu(19, 36, 50, DUSK),
			yasu(14, 28, 40, DUSK),
		}, { yasu(1, 30, 44, DUSK), yasu(5, 30, 42, DUSK), yasu(13, 30, 42, DUSK), yasu(17, 30, 44, DUSK), yasu(6, 30, 44, nil, true), yasu(3, 28, 40, nil, true) }, { owner("VineTree", 30, 40) }),
		count = { 2, 4 },
		under = 7,
		plants = join(
			{ plant("WildKit", "YasuBush01", 3, 6, BUSH_DUSK), plant("WildKit", "YasuBush03", 3, 5, BUSH_DUSK), plant("NatureKit", "Fern", 4, 6), plant("PropKit", "AmethystRocks", 4.4, 8) },
			tufts(TUFT_MOSS),
			spikes(SPIKE_VIOLET)
		),
		rocks = ROCKS,
		logs = 0.3,
		tufts = TUFT_MOSS,
		bank = join(spikes(SPIKE_VIOLET), { plant("PropKit", "AmethystRocks", 3, 5.5), plant("WildKit", "DokiFlower1", 1.8, 2.8, SPIKE_VIOLET) }),
	},
}
local RECIPE_BY_NAME = RECIPES

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
local sceneryFolder = folder("Scenery")
local heartFolder = folder("Heart")

local function source(kit: string, name: string): Instance?
	local k = ServerStorage:FindFirstChild(kit)
	return k and k:FindFirstChild(name)
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { terrain }
local function groundY(p: Vector3): (number, boolean)
	local hit = workspace:Raycast(Vector3.new(p.X, 60, p.Z), Vector3.new(0, -120, 0), rp)
	if hit then
		return hit.Position.Y, true
	end
	return M.GroundY, false
end

-- A size per model at its own scale, measured in world axes.
local measured: { [Instance]: Vector3 } = {}
local function measure(src: Instance): Vector3
	if measured[src] then
		return measured[src]
	end
	local copy = src:Clone()
	local model = copy
	if not copy:IsA("Model") then
		model = Instance.new("Model")
		copy.Parent = model
	end
	model.PrimaryPart = nil
	model.WorldPivot = CFrame.new()
	local _, size = model:GetBoundingBox()
	model:Destroy()
	measured[src] = size
	return size
end

local placedCount, missingNames = 0, {}

local function setTint(part: BasePart, tint: Color3)
	local sa = part:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		sa.Color = tint
	else
		part.Color = tint
	end
end

-- A clone stood on the probed ground as bare parts (no Model per copy: half the instances).
type Options = {
	tilt: number?,
	sink: number?,
	tint: Color3?,
	canopy: Color3?,
	bark: Color3?,
	bare: boolean?,
	shadow: boolean?,
	collide: boolean?,
	parent: Instance?,
	stretch: number?,
}
local function place(kit: string, name: string, at: Vector3, height: number, yaw: number, options: Options)
	local src = source(kit, name)
	if not src then
		missingNames[name] = true
		return nil
	end
	local size = measure(src)
	local copy = src:Clone()
	local model = copy
	if not copy:IsA("Model") then
		model = Instance.new("Model")
		copy.Parent = model
	end
	model.PrimaryPart = nil
	model.WorldPivot = CFrame.new()
	model:ScaleTo(model:GetScale() * height / math.max(size.Y, 0.01))
	local box, scaled = model:GetBoundingBox()
	local foot = box.Position - Vector3.new(0, scaled.Y / 2, 0)
	if options.stretch then
		for _, d in model:GetDescendants() do
			if d:IsA('BasePart') then
				local rel = d.Position - foot
				d.Size = Vector3.new(d.Size.X * options.stretch, d.Size.Y, d.Size.Z * options.stretch)
				d.Position = foot + Vector3.new(rel.X * options.stretch, rel.Y, rel.Z * options.stretch)
			end
		end
	end
	model.WorldPivot = CFrame.new(foot)
	local y = groundY(at)
	local tilt = options.tilt or 0
	local turn = CFrame.Angles(rng:NextNumber(-tilt, tilt), yaw, rng:NextNumber(-tilt, tilt))
	model:PivotTo(CFrame.new(at.X, y - (options.sink or 0.2), at.Z) * turn)
	local kept: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = false
			d.CanCollide = options.collide == true
			d.CastShadow = options.shadow == true
			local lower = string.lower(d.Name)
			local woody = string.find(lower, "trunk") or string.find(lower, "branch") or string.find(lower, "root")
			if woody and options.bark then
				setTint(d, options.bark)
			elseif not woody and options.canopy then
				setTint(d, options.canopy)
			elseif options.tint then
				setTint(d, options.tint)
			end
			if options.bare and not woody then
				d:Destroy()
			else
				d.Parent = options.parent or sceneryFolder
				table.insert(kept, d)
			end
		end
	end
	model:Destroy()
	placedCount += 1
	if placedCount % 30 == 0 then
		task.wait()
	end
	return kept
end

-- What stands where, on a coarse grid, so nothing piles up by accident.
local GRID = 16
local standing: { [number]: { { at: Vector3, r: number } } } = {}
local function gridKey(x: number, z: number): number
	return math.floor(x / GRID) * 4096 + math.floor(z / GRID)
end
local function crowded(p: Vector3, r: number, gap: number): boolean
	local cx, cz = math.floor(p.X / GRID), math.floor(p.Z / GRID)
	local reach = math.ceil((r + gap + 20) / GRID)
	for i = cx - reach, cx + reach do
		for j = cz - reach, cz + reach do
			local list = standing[i * 4096 + j]
			if list then
				for _, s in list do
					if (s.at - p).Magnitude < s.r + r + gap then
						return true
					end
				end
			end
		end
	end
	return false
end
local function stand(p: Vector3, r: number)
	local key = gridKey(p.X, p.Z)
	standing[key] = standing[key] or {}
	table.insert(standing[key], { at = p, r = r })
end

local function inArea(p: Vector3, reach: number): boolean
	local r = p.Magnitude
	return r + reach < RIM and r - reach > M.HeartRadius + 6
end

local function pickOf(list)
	return list[rng:NextInteger(1, #list)]
end

-- ----- a tree -----
local treeSpots: { { at: Vector3, zone: string } } = {}
local function tryTree(entry, p: Vector3, height: number, zone: string): boolean
	local src = source(entry.kit, entry.name)
	if not src then
		missingNames[entry.name] = true
		return false
	end
	local size = measure(src)
	local spread = math.max(size.X, size.Z) * height / size.Y / 2 * (entry.stretch or 1)
	local trunk = height * entry.trunk
	local foot = spread * entry.foot + trunk
	if not inArea(p, foot) then
		return false
	end
	local fromHome = homeDistance(p)
	if fromHome < HOME_CLEAR + foot or fromHome < HOME_CLEAR + spread * CROWN_OVER_GLADE then
		return false
	end
	if lineDistance(p) < LINE_CLEAR + foot then
		return false
	end
	if trailGap(p) < math.max(foot, spread * CROWN_OVER_TRAIL) then
		return false
	end
	if crowded(p, spread * 0.42, 0) then
		return false
	end
	local yaw = rng:NextNumber(0, math.pi * 2)
	local options: Options = {
		shadow = true,
		stretch = entry.stretch,
		sink = if entry.roots then 0.8 else 0.25,
		tilt = if entry.roots then 0.02 else 0,
		bare = entry.bare,
		canopy = entry.tints and pickOf(entry.tints) or nil,
		bark = if entry.roots then (if zone == "inner" then BARK_DUSK else BARK) else nil,
	}
	local kept = place(entry.kit, entry.name, p, height, yaw, options)
	-- A leaning trunk or a low bough can stand well off its foot: the real parts are measured, as the checker does.
	for _, part in kept or {} do
		local at = flat(part.Position)
		local low = part.Position.Y - part.Size.Y / 2 < M.GroundY + LOW_BOUGH and part.Size.Y < 25
		if low and lineDistance(at) < LINE_CLEAR + math.min(part.Size.X, part.Size.Z) / 4 then
			for _, q in kept do
				q:Destroy()
			end
			placedCount -= 1
			return false
		end
	end
	if entry.roots then
		-- Yasu's trunks end in a stake: a root flare gives them a foot, as the references' trees have.
		local rootName = pickOf({ "YasuRootsLarge01", "YasuRootsLarge02", "YasuRootsSmall01", "YasuRootsSmall02", "YasuRootsSmall03" })
		local rootHeight = math.max(4, height * 0.17)
		place("WildKit", rootName, p, rootHeight, rng:NextNumber(0, math.pi * 2), {
			sink = rootHeight * 0.42,
			bark = if zone == "inner" then BARK_DUSK else BARK,
			tint = if zone == "inner" then BARK_DUSK else BARK,
		})
	end
	-- The solid part of a tree is an invisible block round its trunk: the mesh itself is not walked against.
	local block = Instance.new("Part")
	block.Name = "TrunkBlock"
	block.Shape = Enum.PartType.Cylinder
	block.Anchored = true
	block.CanTouch = false
	block.CanQuery = false
	block.CastShadow = false
	block.Transparency = 1
	block.Size = Vector3.new(12, trunk * 2, trunk * 2)
	block.CFrame = CFrame.new(p.X, groundY(p) + 6, p.Z) * CFrame.Angles(0, 0, math.pi / 2)
	block.Parent = sceneryFolder
	stand(p, spread * 0.42)
	table.insert(treeSpots, { at = p, zone = zone })
	return true
end

-- ----- what stands round a tree or a glade -----
local function tryPlant(entry, p: Vector3, zone: string): boolean
	local kit, name = entry.kit, entry.name
	local src = source(kit, name)
	if not src then
		missingNames[name] = true
		return false
	end
	local height = rng:NextNumber(entry.low, entry.high)
	local size = measure(src)
	local r = math.max(size.X, size.Z) * height / size.Y / 2
	if not inArea(p, r) or homeDistance(p) < GLADE_CLEAR + r then
		return false
	end
	if height > 2 and lineDistance(p) < LINE_CLEAR + r * 0.8 then
		return false
	end
	if trailGap(p) < r * 0.5 then
		return false
	end
	if crowded(p, r * 0.3, 0) then
		return false
	end
	place(kit, name, p, height, rng:NextNumber(0, math.pi * 2), {
		tint = entry.tints and pickOf(entry.tints) or nil,
		sink = 0.15,
		shadow = height > 5,
	})
	stand(p, r * 0.3)
	return true
end

local function tryRock(entry, p: Vector3, big: boolean?): boolean
	local src = source(entry.kit, entry.name)
	if not src then
		missingNames[entry.name] = true
		return false
	end
	local height = rng:NextNumber(entry.low, entry.high)
	local size = measure(src)
	local r = math.max(size.X, size.Z) * height / size.Y / 2
	local solid = height >= 3.6 and big ~= false
	if not inArea(p, r) or homeDistance(p) < (if solid then HOME_CLEAR else GLADE_CLEAR) + r then
		return false
	end
	if lineDistance(p) < LINE_CLEAR + r then
		return false
	end
	if trailGap(p) < r * 0.6 then
		return false
	end
	if crowded(p, r * 0.7, 0) then
		return false
	end
	place(entry.kit, entry.name, p, height, rng:NextNumber(0, math.pi * 2), {
		tint = entry.tints and pickOf(entry.tints) or nil,
		tilt = 0.14,
		sink = height * 0.2,
		collide = solid,
		shadow = height > 2.4,
	})
	stand(p, r * 0.7)
	return true
end

-- A drift: several of one kind close together with tufts among them, never one flower alone on a lawn.
local function drift(list, tuftTints, centre: Vector3, zone: string)
	local entry = pickOf(list)
	for _ = 1, rng:NextInteger(2, 4) do
		tryPlant(entry, centre + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)), zone)
	end
	do
		tryPlant({
			kit = 'NatureKit',
			name = 'GrassTuft',
			low = 2.4,
			high = 3.8,
			tints = tuftTints,
		}, centre + Vector3.new(rng:NextNumber(-5, 5), 0, rng:NextNumber(-5, 5)), zone)
	end
end

local function ringPoint(centre: Vector3, from: number, to: number): Vector3
	local a = rng:NextNumber(0, math.pi * 2)
	local d = rng:NextNumber(from, to)
	return centre + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
end

-- ===== the clusters' places, planned before the terrain so the ground under them can follow =====
type Cluster = { at: Vector3, zone: string, recipe: any }
local clusters: { Cluster } = {}
local function planClusters()
	local tries = 2600
	local spots: { Cluster } = {}
	for k = 1, tries do
		local r = math.sqrt(rng:NextNumber((M.HeartRadius + 14) ^ 2, RIM ^ 2))
		local p = polar(rng:NextNumber(0, 360), r)
		local zone = zoneAt(p.X, p.Z)
		local recipe = RECIPE_BY_NAME[zone]
		-- A broad noise leaves whole stretches of open meadow and thickens others, so nothing is evenly spaced.
		local thick = math.noise(p.X / 70, p.Z / 70, 41.3)
		local spacing = recipe.spacing * (1 - thick * 0.55)
		if homeDistance(p) > HOME_CLEAR + 8 and lineDistance(p) > 3 and trailGap(p) > 2 then
			local ok = thick > -0.38
			if ok then
				for _, c in spots do
					if (c.at - p).Magnitude < spacing then
						ok = false
						break
					end
				end
			end
			if ok then
				table.insert(spots, { at = p, zone = zone, recipe = recipe })
			end
		end
		if k % 200 == 0 then
			task.wait()
		end
	end
	clusters = spots
end

local underField: { [number]: Enum.Material } = {}
local function planUnder()
	for _, c in clusters do
		local material = UNDER_TREES[c.zone]
		local cx, cz = math.floor(c.at.X / CELL), math.floor(c.at.Z / CELL)
		local reach = math.ceil(UNDER_RADIUS / CELL) + 3
		for i = cx - reach, cx + reach do
			for j = cz - reach, cz + reach do
				local x, z = i * CELL + CELL / 2, j * CELL + CELL / 2
				local d = (Vector3.new(x, 0, z) - c.at).Magnitude
				if d < UNDER_RADIUS + math.noise(x / 9, z / 9, 7.7) * 9 then
					underField[i * 4096 + j] = material
				end
			end
		end
	end
end

-- ===== lava =====
local lavaField: { [number]: Enum.Material } = {}
local lavaLine: { Vector3 } = {}
local function planLava()
	local function stampLava(centre: Vector3, radius: number, material: Enum.Material)
		local reach = math.ceil(radius / CELL) + 1
		local cx, cz = math.floor(centre.X / CELL), math.floor(centre.Z / CELL)
		for i = cx - reach, cx + reach do
			for j = cz - reach, cz + reach do
				local x, z = i * CELL + CELL / 2, j * CELL + CELL / 2
				if (Vector3.new(x, 0, z) - centre).Magnitude <= radius + math.noise(x / 7, z / 7, 3.3) * 1.5 then
					if trailGap(Vector3.new(x, 0, z)) > 2 then
						lavaField[i * 4096 + j] = material
					end
				end
			end
		end
	end
	for _, lava in LAVA do
		for r = lava[2], lava[3], 2 do
			local a = lava[1] + math.sin(r / 13 + lava[2]) * LAVA_WANDER
			local p = polar(a, r)
			stampLava(p, LAVA_BANK, Mat.Ground)
			table.insert(lavaLine, p)
		end
	end
	for _, lava in LAVA do
		for r = lava[2], lava[3], 2 do
			local a = lava[1] + math.sin(r / 13 + lava[2]) * LAVA_WANDER
			stampLava(polar(a, r), LAVA_WIDTH * (0.75 + math.noise(r / 12, 4.2) * 0.8), Mat.CrackedLava)
		end
	end
end

-- ===== terrain =====
local function pickGround(zone: string, x: number, z: number): Enum.Material
	local list = GROUND[zone]
	-- broad patches with a fine frayed edge; math.noise sits mostly within -0.5..0.5
	local v = math.noise(x / 42, z / 42, 19.7) * 0.8 + math.noise(x / 13, z / 13, 6.1) * 0.35
	local at = math.clamp(v + 0.5, 0, 0.9999)
	local sum = 0
	for _, entry in list do
		sum += entry[2]
		if at < sum then
			return entry[1]
		end
	end
	return list[#list][1]
end

local function heartEdge(x: number, z: number): number
	local a = math.atan2(x, z)
	return M.HeartRadius - 4 + math.noise(math.cos(a) * 2.1, math.sin(a) * 2.1, 8.8) * 12
end

local function surface(x: number, z: number, was: Enum.Material): (Enum.Material, boolean)
	local r = math.sqrt(x * x + z * z)
	local key = cellKey(x, z)
	local trail = trailField[key]
	local edgeNoise = math.noise(x / 8, z / 8, 12.5) * TRAIL_EDGE_NOISE
	local onTrail = false
	if trail then
		onTrail = trail + edgeNoise < 0 or trailCore[key] < TRAIL_MIN_CELL
	end
	local dirt = if math.noise(x / 19, z / 19, 27.1) > RUT_NOISE then Mat.Ground else Mat.Sandstone
	-- The ring road: a circle, with an uneven worn edge and grass creeping in at it.
	local a = math.atan2(x, z)
	local roadEdge = ROAD_HALF
		- 0.5
		+ math.noise(math.cos(a) * 16, math.sin(a) * 16, 5.2) * 3.2
		+ math.noise(x / 9, z / 9, 15.1) * 2.2
	local fromRoad = math.abs(r - ROAD_RADIUS)
	if r > ROAD_RADIUS + ROAD_HALF + 5 then
		if onTrail and was ~= Mat.Sand then
			return Mat.Sandstone, true
		end
		return if was == Mat.Sand then was else Mat.Grass, false
	elseif fromRoad < roadEdge then
		if was == Mat.Sand then
			return was, true -- the Market's own wide way across the road stays
		end
		return dirt, true
	elseif r > ROAD_RADIUS then
		return if was == Mat.Sand then was elseif onTrail then Mat.Sandstone else Mat.Grass, onTrail
	end
	if onTrail then
		-- (the pale road earth reads as a yellow stripe on snow)
		return if string.find(zoneAt(x, z), "frost") then Mat.Ground else dirt, true
	end
	if r < heartEdge(x, z) then
		local v = math.noise(x / 15, z / 15, 31.3) + math.noise(x / 6, z / 6, 8.3) * 0.25
		if r > 46 and math.noise(x / 12, z / 12, 17.7) > 0.05 then
			return Mat.Mud, false
		end
		-- (worn earth with moss and paler patches: grey stone islands and cracked yellow read as a car park)
		return if v > 0.38 then Mat.Mud elseif v < -0.38 then Mat.Sandstone else Mat.Ground, false
	end
	if lavaField[key] then
		return lavaField[key], false
	end
	local zone = zoneAt(x, z)
	if underField[key] then
		return underField[key], false
	end
	local worn = math.noise(x / 24, z / 24, 51.9)
	if worn > WORN_NOISE and zone ~= "frost_outer" and zone ~= "frost_middle" then
		return Mat.Ground, false
	end
	return pickGround(zone, x, z), false
end

-- A trail rides over the swells with the ground round it: a cell lower than its neighbours would be buried by them.
local function heightAt(x: number, z: number): number
	local r = math.sqrt(x * x + z * z)
	if r > RIM + 6 or r < M.HeartRadius + 2 then
		return 0
	end
	local p = Vector3.new(x, 0, z)
	local mask = smooth(M.HeartRadius + 4, M.HeartRadius + 36, r) * (1 - smooth(RIM - 30, RIM, r))
	if mask <= 0 then
		return 0
	end
	local swell = math.noise(x / 62, z / 62, 21.7) + 0.2
	swell = swell * SWELL + math.noise(x / 24, z / 24, 4.4) * 1.4
	if swell <= 0 then
		return 0
	end
	mask *= smooth(SWELL_HOME_FROM, SWELL_HOME_TO, homeDistance(p))
	if mask <= 0 then
		return 0
	end
	mask *= smooth(SWELL_LINE_FROM, SWELL_LINE_TO, lineDistance(p))
	return swell * mask
end

local function buildTerrain()
	for material, colour in COLOURS do
		terrain:SetMaterialColor(material, colour)
	end
	for material, colour in DEFAULT_COLOURS do
		terrain:SetMaterialColor(material, colour)
	end
	-- The first rebuild's flat-colour variants are gone for good.
	for _, v in MaterialService:GetChildren() do
		if v:IsA("MaterialVariant") and string.sub(v.Name, 1, 8) == "WildFlat" then
			local base = v.BaseMaterial
			pcall(function()
				MaterialService:SetBaseMaterialOverride(base, "")
			end)
			v:Destroy()
		end
	end
	-- Scraps of the moods an older run painted beyond this map's reach (a run of lava, of ice by the villages) go back to grass.
	local whole = Region3.new(Vector3.new(-1024, -24, -1024), Vector3.new(1024, 40, 1024))
	for _, scrap in { Mat.CrackedLava, Mat.Basalt, Mat.Glacier, Mat.Snow, Mat.Limestone, Mat.Mud, Mat.Concrete, Mat.Asphalt, Mat.Salt, Mat.Pavement, Mat.LeafyGrass, Mat.Ground } do
		terrain:ReplaceMaterial(whole, CELL, scrap, Mat.Grass)
		task.wait()
	end
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
						local was = Mat.Air
						for y = rows, 1, -1 do
							if mats[i][y][k] ~= Mat.Air and mats[i][y][k] ~= Mat.Water then
								was = mats[i][y][k]
								break
							end
						end
						local top = surface(x, z, was)
						local h = heightAt(x, z)
						for y = 1, rows do
							local occupancy = 0
							if y <= SOLID_CELLS then
								occupancy = 1
							else
								occupancy = math.clamp((h - (y - SOLID_CELLS - 1) * CELL) / CELL, 0, 1)
							end
							if occupancy > 0 then
								mats[i][y][k] = if y >= SOLID_CELLS then top else Mat.Grass
								occs[i][y][k] = occupancy
							else
								mats[i][y][k] = Mat.Air
								occs[i][y][k] = 0
							end
						end
					end
				end
				if i % 16 == 0 then
					task.wait()
				end
			end
			if touched then
				terrain:WriteVoxels(region, CELL, mats, occs)
			end
		end
		task.wait()
	end
end

-- ===== dressing =====
-- The references' unit of dressing: a boulder with a drift of flowers hugging its foot.
local function boulder(recipe, p: Vector3, zone: string)
	if tryRock(pickOf(recipe.rocks), p) then
		drift(recipe.bank, recipe.tufts, ringPoint(p, 3.5, 6), zone)
	end
end

local function dressClusters()
	for index, c in clusters do
		local recipe = c.recipe
		local wanted = rng:NextInteger(recipe.count[1], recipe.count[2])
		local placed = {}
		for n = 1, wanted do
			for _ = 1, 8 do
				local entry = if n == 1 and recipe.hero and rng:NextNumber() < HERO_SHARE then pickOf(recipe.hero) else pickOf(recipe.trees)
				local p = if n == 1 then c.at else ringPoint(c.at, 9, 20 + 4 * n)
				local height = rng:NextNumber(entry.low, entry.high) * (if n == 1 then 1 else rng:NextNumber(0.68, 1))
				if tryTree(entry, p, height, c.zone) then
					table.insert(placed, p)
					break
				end
			end
		end
		-- Hugging the bases, thick on one side: a skirt, not a ring.
		local side = rng:NextNumber(0, math.pi * 2)
		for _, at in if #placed > 0 then placed else { c.at } do
			local count = if #placed > 2 then 1 else 2
			for _ = 1, count do
				local a = side + rng:NextNumber(-1.5, 1.5)
				local d = rng:NextNumber(4, 12)
				drift(recipe.plants, recipe.tufts, at + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d), c.zone)
			end
			local roll = rng:NextNumber()
			if roll < 0.8 then
				boulder(recipe, ringPoint(at, 6, 13), c.zone)
			end
			if roll < 0.3 then
				boulder(recipe, ringPoint(at, 7, 15), c.zone)
			end
			if recipe.logs > 0 and rng:NextNumber() < recipe.logs then
				tryRock(pickOf(LOGS), ringPoint(at, 8, 16), false)
			end
		end
		if index % 6 == 0 then
			task.wait()
		end
	end
end

local function zoneRecipe(p: Vector3)
	return RECIPE_BY_NAME[zoneAt(p.X, p.Z)]
end

-- A glade is what stands round it: drifts of flowers and a rock or two on some sides, an open way towards its gate.
local function dressGlades()
	for _, home in homes do
		local recipe = zoneRecipe(home)
		for _ = 1, rng:NextInteger(1, 3) do
			local a = rng:NextNumber(0, math.pi * 2)
			local centre = home + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(GLADE_CLEAR + 4, GLADE_CLEAR + 9)
			drift(recipe.bank, recipe.tufts, centre, '')
		end
		for _ = 1, rng:NextInteger(1, 2) do
			boulder(recipe, ringPoint(home, HOME_CLEAR + 5, HOME_CLEAR + 11), "")
		end
		task.wait()
	end
end

-- Rocks and tufts along the trails, never at a regular step.
local function dressTrails()
	for _, samples in trails do
		local i = rng:NextInteger(1, 8)
		while i < #samples do
			local s = samples[i]
			local p = s.at
			local recipe = if p.Magnitude < RIM then zoneRecipe(p) else nil
			if recipe then
				if rng:NextNumber() < STONE_SHARE and homeDistance(p) > GLADE_CLEAR and p.Magnitude > M.HeartRadius + 4 then
					local offset = Vector3.new(rng:NextNumber(-1.8, 1.8), 0, rng:NextNumber(-1.8, 1.8))
					place("KitCache", "rock_boulder_big", p + offset, 0.9, rng:NextNumber(0, math.pi * 2), {
						stretch = rng:NextNumber(1.8, 2.6),
						sink = 0.42,
						tint = pickOf(STONE),
					})
				end
				local nextOne = samples[math.min(i + 1, #samples)]
				local dir = nextOne.at - p
				if dir.Magnitude > 0 then
					local side = dir.Unit:Cross(Vector3.yAxis) * (if rng:NextNumber() < 0.5 then -1 else 1)
					local out = s.width / 2 + rng:NextNumber(1.2, 3.4)
					local where = p + side * out
					local roll = rng:NextNumber()
					if roll < 0.42 then
						tryRock(pickOf(if recipe.rocks == SNOW_ROCKS then SNOW_PEBBLES else PEBBLES), where, false)
					elseif roll < 0.82 then
						tryPlant({
							kit = "NatureKit",
							name = "GrassTuft",
							low = 2.4,
							high = 3.8,
							tints = recipe.tufts,
						}, where, "")
					else
						drift(recipe.bank, recipe.tufts, where + side * 3, '')
					end
				end
			end
			i += rng:NextInteger(8, 20)
		end
		task.wait()
	end
end

-- A very few cracks of lava, kept by rough rocks and autumn plants.
local function dressLava()
	local step = 0
	for _, p in lavaLine do
		step += 1
		if step % 6 == 0 then
			local side = polar(rng:NextNumber(0, 360), 1)
			if rng:NextNumber() < 0.55 then
				tryRock(rock("OwnerKit", "JaggedRocks", 2.4, 4), p + side * rng:NextNumber(7, 11), false)
			else
				tryPlant(plant("PropKit", "AutumnPlant", 2.2, 4), p + side * rng:NextNumber(7, 12), "")
			end
		end
	end
end

-- ===== the Heart =====
-- A round open clearing of stone and earth; the old spring and the ruins stand at its edge, the middle is the boss's.
local SPRING_ANGLE = 14
local SPRING_RADIUS = 7
local SPRING_COLOUR = Color3.fromRGB(96, 210, 66)
local HEART_ROCKS = { 40, 66, 96, 128, 160, 186, 218, 246, 276, 308, 338 }
local function buildHeart()
	local spring = polar(SPRING_ANGLE, HEART_CLEAR + 11)
	local y = groundY(spring)
	local basin = source("PropKit", "GooBasin")
	if basin then
		place("PropKit", "GooBasin", spring, 2.6, 0.6, { parent = heartFolder, collide = true, shadow = true, sink = 0.3 })
		for _, p in heartFolder:GetChildren() do
			if p:IsA("BasePart") then
				local s = p.Size
				local k = (SPRING_RADIUS * 2.5) / math.max(s.X, s.Z)
				p.Size = Vector3.new(s.X * k, s.Y, s.Z * k)
			end
		end
	end
	local pool = Instance.new("Part")
	pool.Name = "Spring"
	pool.Shape = Enum.PartType.Cylinder
	pool.Anchored = true
	pool.CanCollide = false
	pool.CanTouch = false
	pool.CanQuery = false
	pool.CastShadow = false
	pool.Material = Mat.Neon
	pool.Color = SPRING_COLOUR
	pool.Size = Vector3.new(0.3, SPRING_RADIUS * 2, SPRING_RADIUS * 2)
	pool.CFrame = CFrame.new(spring.X, y + 1.9, spring.Z) * CFrame.Angles(0, 0, math.pi / 2)
	pool.Parent = heartFolder
	local light = Instance.new("PointLight")
	light.Color = SPRING_COLOUR
	light.Range = 26
	light.Brightness = 1.2
	light.Parent = pool
	-- The ruin arch stands behind the spring, facing it from the outer side.
	local arch = polar(SPRING_ANGLE - 2, HEART_CLEAR + 21)
	place("PropKit", "RuinArch", arch, 26, math.rad(180 - SPRING_ANGLE), {
		parent = heartFolder,
		collide = true,
		shadow = true,
		sink = 0.4,
	})
	for _, angle in HEART_ROCKS do
		if math.abs((angle - SPRING_ANGLE + 180) % 360 - 180) > 24 then
			local a = angle + rng:NextNumber(-7, 7)
			local r = rng:NextNumber(HEART_CLEAR + 8, M.HeartRadius + 2)
			local p = polar(a, r)
			if trailGap(p) > 3 then
				-- (not the kit's FlatBoulder: under that name it holds a wooden lamp post)
				local entry = pickOf({ "WideBoulder", "StackedRocks", "JaggedRocks" })
				place("OwnerKit", entry, p, rng:NextNumber(4, 8), rng:NextNumber(0, 6.28), {
					parent = heartFolder,
					tilt = 0.08,
					collide = true,
					shadow = true,
					sink = 0.4,
				})
			end
		end
	end
end

-- ===== build =====
local viewer = workspace:FindFirstChild("KitViewer") -- (a stand left in the sky by a kit check)
if viewer then
	viewer:Destroy()
end
planTrails()
planClusters()
planUnder()
planLava()
buildTerrain()
task.wait(1)
dressClusters()
dressGlades()
dressTrails()
dressLava()
buildHeart()

local parts, meshes, shadows, collide = 0, 0, 0, 0
local byMesh: { [string]: number } = {}
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
		if d:IsA("MeshPart") then
			meshes += 1
			byMesh[d.MeshId] = (byMesh[d.MeshId] or 0) + 1
		end
		if d.CastShadow then
			shadows += 1
		end
		if d.CanCollide then
			collide += 1
		end
	end
end
local unique = 0
for _ in byMesh do
	unique += 1
end
local missing = {}
for name in missingNames do
	table.insert(missing, name)
end
return string.format(
	"wild built: %d placed, %d clusters, %d trees, %d trails, %d parts (%d meshes of %d shapes), %d cast shadows, %d collide; missing kit: %s",
	placedCount,
	#clusters,
	#treeSpots,
	#trails,
	parts,
	meshes,
	unique,
	shadows,
	collide,
	table.concat(missing, ",")
)
