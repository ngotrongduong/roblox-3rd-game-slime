-- Dresses the big world's ground (docs/WORLD.md) with the kits already in the work place: groves of trees with plants
-- and rocks under them, open ground between, flowers along the roads. It reads the land back by raycast (the ground's
-- material says which region a spot is in; roads, pads, sand, water and cliffs stay bare), so it follows whatever
-- tools/world/build_terrain.luau wrote. Scenery goes into workspace.World.Scenery, one folder a 512-stud cell, and a
-- run clears the cells it writes: the same call gives the same world.
--
--   node tools/studio_mcp.js run tools/world/build_scatter.luau <studio_id> Edit PLAN=src/shared/WorldPlan.luau ARGS=<file>
--
-- ARGS: "rows A B" dresses the coarse rows A..B (0..8, north to south); "count" prints what stands.
-- The kit names, heights and tints are the ones proved in the Wild Garden (tools/map/build_wild_slices.luau).
local ServerStorage = game:GetService("ServerStorage")
local Plan = loadstring(PLAN)()
local args = string.split(ARGS or "count", " ")

local terrain = workspace.Terrain
local B, O = Plan.Bounds, Plan.Origin
local M = Enum.Material
local noise = math.noise
local FINE, COARSE = 64, 512

local world = workspace:FindFirstChild("World") or Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local scenery = world:FindFirstChild("Scenery") or Instance.new("Folder")
scenery.Name = "Scenery"
scenery.Parent = world

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local WHITE = rgb(255, 255, 255)
local LIME = { rgb(158, 210, 66), rgb(128, 196, 58), rgb(178, 216, 78) }
local LEAF = { rgb(96, 176, 62), rgb(74, 160, 70), rgb(118, 186, 60) }
local TEAL = { rgb(46, 150, 112), rgb(60, 168, 110), rgb(38, 134, 122) }
local AUTUMN = { rgb(222, 62, 40), rgb(238, 118, 34), rgb(240, 158, 40), rgb(206, 46, 44) }
local QT_WHITE = { WHITE, rgb(240, 240, 240) }
local QT_GREEN = { WHITE, rgb(240, 255, 200), rgb(225, 250, 190) }
local QT_PINE = { WHITE, rgb(210, 235, 225) }
local TUFT_GREEN = { rgb(240, 255, 200), rgb(225, 250, 190) }
local TUFT_GOLD = { WHITE, rgb(255, 240, 200) }
local TUFT_ICE = { rgb(235, 245, 255) }
local TUFT_TEAL = { rgb(225, 255, 235), rgb(210, 250, 230) }
local SPIKE_VIOLET = { rgb(176, 120, 240), rgb(140, 100, 230) }
local SPIKE_PINK = { rgb(245, 130, 190), rgb(230, 110, 210) }
local BUSH_RED = { rgb(226, 70, 44), rgb(240, 130, 44), rgb(246, 170, 50) }
local BUSH_GREEN = { rgb(110, 180, 64), rgb(78, 164, 74) }
local MUSHROOM_TINT = { rgb(140, 255, 215), rgb(170, 255, 225) }
local FERN_GOLD = { rgb(255, 235, 150), rgb(240, 220, 130) }
local FERN_ICE = { rgb(190, 225, 215), rgb(175, 215, 210) }
local FROST_BERRY = { rgb(165, 135, 135), rgb(185, 150, 150) }
local ROCK_WARM = { rgb(255, 232, 196), rgb(255, 240, 210), rgb(250, 226, 190) }

-- An entry: kit, name, least and most size (height, or width when wide), and how it is stood.
type Entry = { kit: string, name: string, low: number, high: number, tints: { Color3 }?, wide: boolean?, stretch: number?, sink: number?, rock: boolean? }
local function e(kit: string, name: string, low: number, high: number, tints: { Color3 }?, wide: boolean?): Entry
	return { kit = kit, name = name, low = low, high = high, tints = tints, wide = wide }
end
local function yasu(n: number, low: number, high: number, tints): Entry
	local entry = e("WildKit", string.format("YasuTree%02d", n), low, high, tints)
	entry.stretch = 1.4 -- (drawn slim; the references' trees are wide)
	return entry
end
local function rounds(low: number, high: number, tints, only: number): { Entry }
	local out = {}
	for i, n in { 1, 3, 5, 6, 13, 15, 17, 18 } do
		if i <= only then
			table.insert(out, yasu(n, low, high, tints))
		end
	end
	return out
end
local function rock(kit: string, name: string, low: number, high: number, tints: { Color3 }?, wide: boolean?): Entry
	local entry = e(kit, name, low, high, tints, wide)
	entry.rock = true
	return entry
end
local function sunk(entry: Entry, depth: number): Entry
	entry.sink = depth
	return entry
end
local function join(...): { Entry }
	local out = {}
	for _, list in { ... } do
		for _, x in list do
			table.insert(out, x)
		end
	end
	return out
end
local function tufts(tints, k: number, dry: boolean?): { Entry }
	if dry then
		return { e("WildKit", "QtGrass_Wispy_Short", 3 * k, 4.2 * k, tints), e("WildKit", "QtGrass_Common_Tall", 3 * k, 4.4 * k, tints) }
	end
	return {
		e("WildKit", "QtGrass_Common_Short", 2.6 * k, 3.8 * k, tints),
		e("WildKit", "QtGrass_Common_Tall", 3 * k, 4.4 * k, tints),
		e("WildKit", "QtClover_1", 2 * k, 3 * k, tints, true),
	}
end

local QTROCKS = {
	rock("WildKit", "QtRock_Medium_1", 3.2, 5.6, ROCK_WARM),
	rock("WildKit", "QtRock_Medium_2", 2.8, 4.8, ROCK_WARM),
	rock("WildKit", "QtRock_Medium_3", 3.2, 5.6, ROCK_WARM),
	rock("WildKit", "QtRock_Medium_2", 2.2, 3.6, ROCK_WARM),
	rock("WildKit", "QtPebble_Round_1", 1.4, 2.4, nil, true),
}
local FLOWERS = {
	e("WildKit", "DokiFlower4", 4.4, 7, SPIKE_VIOLET),
	e("WildKit", "DokiFlower4", 4.4, 7, SPIKE_PINK),
	e("KitCache", "flower_daisies", 3.4, 5),
	e("KitCache", "flower_tulips_red", 3, 4.4),
	e("PropKit", "PinkDaisies", 3, 5.4),
	e("WildKit", "QtFlower_3_Group", 2.4, 3.6, nil, true),
	e("WildKit", "QtFlower_4_Group", 2.4, 3.6, nil, true),
}
local GREENS = {
	e("WildKit", "QtFern_1", 4, 7, nil, true),
	e("WildKit", "QtPlant_1_Big", 3.6, 5.4, nil, true),
	e("WildKit", "QtPlant_7_Big", 4, 6, nil, true),
	e("WildKit", "QtBush_Common_Flowers", 4.4, 6.4, nil, true),
}
local RED_BUSH = e("WildKit", "QtBush_Common", 3.6, 5.6, nil, true)

-- A recipe: how thick its groves are (trees a 64-stud cell at the thickest), how much open ground is wooded (the
-- noise level a grove starts at), plants under a tree, and plants and rocks on open ground.
local RECIPES = {
	vale = {
		thick = 2,
		starts = 0.12,
		hero = { e("OwnerKit", "BroadleafTree", 40, 52) },
		trees = join(rounds(26, 40, LIME, 5), { e("WildKit", "QtCommonTree_1", 32, 44, QT_GREEN), e("WildKit", "QtCommonTree_3", 30, 42, QT_GREEN), e("WildKit", "QtCommonTree_5", 32, 44, QT_GREEN) }),
		under = 3,
		plants = join(FLOWERS, tufts(TUFT_GREEN, 1), { e("WildKit", "YasuBush01", 4, 7, BUSH_GREEN), e("WildKit", "QtBush_Common_Flowers", 4.4, 6.4, nil, true) }),
		open = 1.2,
		rocks = QTROCKS,
	},
	meadow = {
		thick = 3,
		starts = 0.02,
		hero = { e("OwnerKit", "BroadleafTree", 42, 56), e("OwnerKit", "BanyanTree", 42, 54) },
		trees = join(rounds(28, 46, LEAF, 6), { e("WildKit", "QtCommonTree_1", 34, 50, QT_GREEN), e("WildKit", "QtCommonTree_5", 34, 50, QT_GREEN), e("OwnerKit", "BroadleafTree", 30, 42) }),
		under = 4,
		plants = join(FLOWERS, FLOWERS, GREENS, tufts(TUFT_GREEN, 1), { e("WildKit", "YasuBush01", 4, 7, BUSH_GREEN) }),
		open = 1.6,
		rocks = join(QTROCKS, { rock("WildKit", "OwnMossyRockStack", 5, 8), rock("PropKit", "MossyLog", 4.4, 6) }),
	},
	mushroom = {
		thick = 4,
		starts = -0.08,
		hero = { e("PropKit", "GiantMushroom", 30, 48, MUSHROOM_TINT), e("WildKit", "OwnAncientJungleTree", 32, 44), e("OwnerKit", "VineTree", 44, 58) },
		trees = join(rounds(28, 44, TEAL, 4), {
			e("WildKit", "QtCommonTree_1_Teal", 34, 48, QT_WHITE),
			e("WildKit", "QtCommonTree_5_Teal", 34, 48, QT_WHITE),
			e("WildKit", "QtCommonTree_3_Purple", 32, 46, QT_WHITE),
			e("WildKit", "QtTwistedTree_1_Purple", 28, 42, QT_WHITE),
			e("WildKit", "QtTwistedTree_3_Purple", 28, 42, QT_WHITE),
			e("PropKit", "GiantMushroom", 18, 30, MUSHROOM_TINT),
		}),
		under = 4,
		plants = join({
			e("PropKit", "GlowMushrooms", 5, 13, MUSHROOM_TINT),
			e("WildKit", "OwnMushBlue", 4.5, 10, MUSHROOM_TINT),
			e("WildKit", "OwnMushPurple", 3.5, 6.5),
			e("WildKit", "OwnMushPink", 3.5, 6.5),
			e("WildKit", "OwnMushPurpleSpotted", 3.5, 6),
			e("WildKit", "QtFern_1", 4.5, 7.5, nil, true),
			e("WildKit", "QtMushroom_Common", 2.2, 3.4, nil, true),
			e("WildKit", "DokiFlower4", 4.4, 7, SPIKE_VIOLET),
		}, tufts(TUFT_TEAL, 1)),
		open = 1.4,
		rocks = join(QTROCKS, { rock("PropKit", "MossyLog", 4.4, 6), rock("WildKit", "OwnJungleStoneShelf", 6, 9, nil, true) }),
	},
	ember = {
		thick = 2,
		starts = 0.1,
		hero = { rock("WildKit", "OwnMoltenPlateau", 9, 14, nil, true), rock("WildKit", "OwnMagmaCrystalCluster", 7, 12) },
		trees = join(rounds(28, 42, AUTUMN, 3), {
			e("WildKit", "QtDeadTree_1", 28, 42),
			e("WildKit", "QtDeadTree_3", 30, 44),
			e("WildKit", "QtDeadTree_5", 28, 40),
			e("WildKit", "QtTwistedTree_2_Orange", 28, 42, QT_WHITE),
			e("WildKit", "QtTwistedTree_3_Gold", 28, 42, QT_WHITE),
			e("WildKit", "QtTwistedTree_1", 28, 42, QT_WHITE),
		}),
		under = 3,
		plants = join({
			e("PropKit", "AutumnPlant", 3.6, 6.4),
			RED_BUSH,
			e("WildKit", "YasuBush01", 3, 6, BUSH_RED),
			e("NatureKit", "DryBush", 2.5, 4),
			e("WildKit", "OwnFiregrass", 3, 5),
			e("WildKit", "QtFern_1", 4, 6, FERN_GOLD, true),
			sunk(e("WildKit", "OwnCrystalRed", 4, 7), 0.9),
		}, tufts(TUFT_GOLD, 1, true)),
		open = 1.1,
		rocks = join(QTROCKS, { rock("WildKit", "OwnStackedBasalt", 3.4, 6), rock("OwnerKit", "JaggedRocks", 3.2, 6), sunk(rock("WildKit", "OwnEmberCrystalPatch", 5, 8, nil, true), 0.4) }),
	},
	frost = {
		thick = 3,
		starts = 0.04,
		hero = { rock("WildKit", "OwnIceCrystalSpire", 12, 20), rock("WildKit", "OwnFrozenRockSpire", 9, 15) },
		trees = {
			e("OwnerKit", "TallPineLarge", 30, 44),
			e("OwnerKit", "TallPineSparse", 28, 40),
			e("WildKit", "QtPine_1", 26, 42, QT_PINE),
			e("WildKit", "QtPine_5", 24, 38, QT_PINE),
			e("WildKit", "QtPine_1", 22, 32, QT_PINE),
			e("NatureKit", "SnowCoveredPine", 22, 38),
			e("NatureKit", "SnowyPine", 20, 32),
			e("OwnerKit", "FrozenDeadTree", 24, 34),
		},
		under = 2,
		plants = join({
			e("WildKit", "QtBush_Common", 2.6, 4, FROST_BERRY, true),
			sunk(e("PropKit", "CrystalCluster", 3.4, 7), 0.9),
			sunk(e("WildKit", "OwnCrystalBlue", 4, 7), 0.9),
			sunk(e("WildKit", "OwnCrystalPaleBlue", 4, 7), 0.9),
			e("WildKit", "QtFern_1", 3.4, 5, FERN_ICE, true),
		}, tufts(TUFT_ICE, 0.8)),
		open = 0.9,
		rocks = join(QTROCKS, { rock("NatureKit", "SnowyBoulder", 2.5, 5), rock("WildKit", "OwnIceCrystalCluster", 4, 7) }),
	},
	-- The rim mountains' slopes: pines only, thin.
	slope = {
		thick = 2,
		starts = 0.05,
		trees = { e("WildKit", "QtPine_1", 28, 44, QT_PINE), e("WildKit", "QtPine_5", 26, 40, QT_PINE), e("OwnerKit", "TallPineSlender", 28, 40) },
		under = 0,
		plants = {},
		open = 0.3,
		rocks = QTROCKS,
	},
}

local function source(kit: string, name: string): Instance?
	local k = ServerStorage:FindFirstChild(kit)
	return k and k:FindFirstChild(name)
end
local missing: { [string]: boolean } = {}
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
local function setTint(part: BasePart, tint: Color3)
	local sa = part:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		sa.Color = tint
	else
		part.Color = tint
	end
end

local placed = 0
-- A clone stood at a ground point as bare parts (no Model per copy: half the instances).
local function place(entry: Entry, at: Vector3, rng: Random, parent: Instance, scale: number?): boolean
	local src = source(entry.kit, entry.name)
	if not src then
		missing[entry.name] = true
		return false
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
	local want = rng:NextNumber(entry.low, entry.high) * (scale or 1)
	local ref = if entry.wide then math.max(size.X, size.Z) else size.Y
	model:ScaleTo(model:GetScale() * want / math.max(ref, 0.01))
	local box, scaled = model:GetBoundingBox()
	local foot = box.Position - Vector3.new(0, scaled.Y / 2, 0)
	if entry.stretch then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				local rel = d.Position - foot
				d.Size = Vector3.new(d.Size.X * entry.stretch, d.Size.Y, d.Size.Z * entry.stretch)
				d.Position = foot + Vector3.new(rel.X * entry.stretch, rel.Y, rel.Z * entry.stretch)
			end
		end
	end
	model.WorldPivot = CFrame.new(foot)
	local tilt = if entry.rock then 0.12 else 0
	local turn = CFrame.Angles(rng:NextNumber(-tilt, tilt), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-tilt, tilt))
	model:PivotTo(CFrame.new(at.X, at.Y - (entry.sink or 0.25) * (if entry.sink then want else 1), at.Z) * turn)
	local tint = entry.tints and entry.tints[rng:NextInteger(1, #entry.tints)]
	local big = entry.rock and want >= 4 and not entry.wide
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = false
			d.CanCollide = big == true
			d.CastShadow = want >= 18
			if tint then
				local lower = string.lower(d.Name)
				local woody = string.find(lower, "trunk") or string.find(lower, "branch") or string.find(lower, "root") or string.find(lower, "bark")
				if not woody then
					setTint(d, tint)
				end
			end
			d.Parent = parent
		end
	end
	model:Destroy()
	placed += 1
	if placed % 40 == 0 then
		task.wait()
	end
	return true
end

-- Roads, as the terrain builder draws them: columns near one know how far its middle line is.
local function curve(points: { { number } }, step: number): { { number } }
	local out = {}
	local n = #points
	for i = 1, n - 1 do
		local p0, p1, p2, p3 = points[math.max(i - 1, 1)], points[i], points[i + 1], points[math.min(i + 2, n)]
		local count = math.max(1, math.ceil(math.sqrt((p2[1] - p1[1]) ^ 2 + (p2[2] - p1[2]) ^ 2) / step))
		for k = 0, count - 1 do
			local t = k / count
			local t2, t3 = t * t, t * t * t
			local x = 0.5 * (2 * p1[1] + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t3)
			local z = 0.5 * (2 * p1[2] + (p2[2] - p0[2]) * t + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t2 + (3 * p1[2] - p0[2] - 3 * p2[2] + p3[2]) * t3)
			table.insert(out, { x, z })
		end
	end
	table.insert(out, { points[n][1], points[n][2] })
	return out
end
local NEAR = 8 -- studs a cell of the road grid
local NXN = math.ceil((B.maxX - B.minX) / NEAR)
local roadNear: { [number]: number } = {}
local roadSamples: { { number } } = {}
for _, road in Plan.Roads do
	local samples = curve(Plan.roadPoints(road), 4)
	for i, p in samples do
		local ix, iz = math.floor((p[1] - B.minX) / NEAR), math.floor((p[2] - B.minZ) / NEAR)
		for dz = -3, 3 do
			for dx = -3, 3 do
				local cx, cz = B.minX + (ix + dx + 0.5) * NEAR, B.minZ + (iz + dz + 0.5) * NEAR
				local d = math.sqrt((cx - p[1]) ^ 2 + (cz - p[2]) ^ 2) - road.width / 2
				local index = (ix + dx) + (iz + dz) * NXN
				if d < (roadNear[index] or math.huge) then
					roadNear[index] = d
				end
			end
		end
		if i % 9 == 0 and i < #samples then
			local q = samples[i + 1]
			local dx, dz = q[1] - p[1], q[2] - p[2]
			local l = math.sqrt(dx * dx + dz * dz)
			table.insert(roadSamples, { p[1], p[2], -dz / l, dx / l, road.width / 2 })
		end
	end
end
local function roadGap(x: number, z: number): number
	return roadNear[math.floor((x - B.minX) / NEAR) + math.floor((z - B.minZ) / NEAR) * NXN] or math.huge
end

-- Pads stay clear: the game builds the villages, the fights get their own dressing (tools/world/build_sites.luau).
local clear = {}
for _, place in Plan.places() do
	if place.kind ~= "junction" and place.kind ~= "bridge" and place.kind ~= "gate" then
		table.insert(clear, { place.x, place.z, place.radius + (if place.kind == "village" then 4 else 10) })
	end
end
local function onPad(x: number, z: number): boolean
	for _, c in clear do
		if (x - c[1]) ^ 2 + (z - c[2]) ^ 2 < c[3] ^ 2 then
			return true
		end
	end
	return false
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { terrain }
rp.IgnoreWater = false
local GREEN = { [M.Grass] = true, [M.LeafyGrass] = true }
local RECIPE_OF = { [M.Mud] = "mushroom", [M.Basalt] = "ember", [M.Ground] = "ember", [M.Snow] = "frost", [M.Glacier] = "frost" }
local Rim, Hub = Plan.Rim, Plan.Hub

-- The ground at a local point: position, and the recipe that grows there (nil: nothing does).
local function ground(x: number, z: number): (Vector3?, string?, number)
	local hit = workspace:Raycast(Vector3.new(O.x + x, 520, O.z + z), Vector3.new(0, -600, 0), rp)
	if not hit then
		return nil, nil, 0
	end
	local name = RECIPE_OF[hit.Material]
	if GREEN[hit.Material] then
		name = if (x - Hub.x) ^ 2 + (z - Hub.z) ^ 2 < 820 ^ 2 and z > 480 then "vale" else "meadow"
	end
	if name then
		local rim = (math.abs(x - Rim.x) / Rim.radius) ^ Rim.power + (math.abs(z - Rim.z) / Rim.radius) ^ Rim.power
		if rim > 1.2 or hit.Position.Y > 250 then
			name = nil -- the far side of the mountains: nobody stands there
		elseif rim > 0.92 and name ~= "frost" then
			name = "slope"
		end
	end
	return hit.Position, name, hit.Normal.Y
end

local function pick(list: { Entry }, rng: Random): Entry
	return list[rng:NextInteger(1, #list)]
end

local function dressCell(ix: number, iz: number, parent: Instance)
	local rng = Random.new(ix * 7919 + iz * 104729 + 17)
	local x0, z0 = B.minX + ix * FINE, B.minZ + iz * FINE
	local cx, cz = x0 + FINE / 2, z0 + FINE / 2
	local _, name = ground(cx, cz)
	if not name then
		return
	end
	local recipe = RECIPES[name]
	local forest = noise(cx / 420, cz / 420, 12.3) + 0.5 * noise(cx / 150, cz / 150, 4.5)
	local wooded = math.clamp((forest - recipe.starts) / 0.3, 0, 1)
	local count = math.floor(wooded * recipe.thick + rng:NextNumber())
	local stood = {}
	for _ = 1, count do
		local x, z = x0 + rng:NextNumber(4, FINE - 4), z0 + rng:NextNumber(4, FINE - 4)
		local at, here, up = ground(x, z)
		local free = at and here == name and up > 0.8 and roadGap(x, z) > 9 and not onPad(x, z)
		for _, s in stood do
			if (s[1] - x) ^ 2 + (s[2] - z) ^ 2 < 18 ^ 2 then
				free = false
			end
		end
		if free then
			local entry = if recipe.hero and rng:NextNumber() < 0.07 then pick(recipe.hero, rng) else pick(recipe.trees, rng)
			if place(entry, at :: Vector3, rng, parent) then
				table.insert(stood, { x, z })
				-- What grows and lies round its foot.
				for _ = 1, rng:NextInteger(0, recipe.under) do
					local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(5, 13)
					local px, pz = x + math.cos(a) * r, z + math.sin(a) * r
					local pat, phere, pup = ground(px, pz)
					if pat and phere == name and pup > 0.75 and roadGap(px, pz) > 1.5 and not onPad(px, pz) then
						place(if rng:NextNumber() < 0.22 then pick(recipe.rocks, rng) else pick(recipe.plants, rng), pat, rng, parent)
					end
				end
			end
		end
	end
	-- Open ground: a few plants and stones, more where the grove's edge is near.
	local open = recipe.open * (0.5 + wooded)
	for _ = 1, math.floor(open + rng:NextNumber()) do
		local x, z = x0 + rng:NextNumber(0, FINE), z0 + rng:NextNumber(0, FINE)
		local at, here, up = ground(x, z)
		if at and here == name and up > 0.75 and roadGap(x, z) > 1.5 and not onPad(x, z) and #recipe.plants > 0 then
			place(if rng:NextNumber() < 0.3 then pick(recipe.rocks, rng) else pick(recipe.plants, rng), at, rng, parent)
		elseif at and here == name and up > 0.6 and roadGap(x, z) > 3 and not onPad(x, z) then
			place(pick(recipe.rocks, rng), at, rng, parent)
		end
	end
end

if args[1] == "rows" then
	local started = os.clock()
	local a, b = tonumber(args[2]) :: number, tonumber(args[3]) :: number
	local per = COARSE / FINE
	for cz = a, b do
		for cx = 0, math.ceil((B.maxX - B.minX) / COARSE) - 1 do
			local name = string.format("C%d_%d", cx, cz)
			local old = scenery:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			local folder = Instance.new("Folder")
			folder.Name = name
			for iz = cz * per, cz * per + per - 1 do
				for ix = cx * per, cx * per + per - 1 do
					if B.minX + ix * FINE < B.maxX and B.minZ + iz * FINE < B.maxZ then
						dressCell(ix, iz, folder)
					end
				end
			end
			-- Flowers and tufts along the roads that cross this cell: the path is where a player looks.
			local rng = Random.new(cx * 31 + cz * 977 + 5)
			for _, s in roadSamples do
				if math.floor((s[1] - B.minX) / COARSE) == cx and math.floor((s[2] - B.minZ) / COARSE) == cz then
					for side = -1, 1, 2 do
						if rng:NextNumber() < 0.55 then
							local off = s[5] + rng:NextNumber(2.5, 9)
							local x, z = s[1] + s[3] * off * side + rng:NextNumber(-5, 5), s[2] + s[4] * off * side + rng:NextNumber(-5, 5)
							local at, here, up = ground(x, z)
							if at and here and up > 0.8 and roadGap(x, z) > 1.5 and not onPad(x, z) and #RECIPES[here].plants > 0 then
								place(pick(RECIPES[here].plants, rng), at, rng, folder)
							end
						end
					end
				end
			end
			folder.Parent = scenery
			task.wait()
		end
	end
	local names = {}
	for name in missing do
		table.insert(names, name)
	end
	return string.format("rows %d..%d: %d placed in %.1f s; missing: %s", a, b, placed, os.clock() - started, table.concat(names, " "))
end

local parts, folders = 0, 0
for _, folder in scenery:GetChildren() do
	folders += 1
	parts += #folder:GetChildren()
end
return string.format("scenery: %d parts in %d cells", parts, folders)
