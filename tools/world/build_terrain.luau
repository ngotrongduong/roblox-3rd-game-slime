-- Builds the ground of the big world, "the Goo Lands" (docs/WORLD.md), in the open work place from
-- src/shared/WorldPlan.luau: land, rim mountains, the Heart's crater and lake, the river, the bay,
-- pads for every village and fight, and the roads, all as one height field written with WriteVoxels.
-- It writes only inside the plan's own bounds (far from the old valley) and clears each chunk first,
-- so running it again gives the same world.
--
--   node tools/studio_mcp.js run tools/world/build_terrain.luau <studio_id> Edit PLAN=src/shared/WorldPlan.luau ARGS=<file>
--
-- ARGS is a text file: "rows A B" writes the chunk rows A..B (0..34, north to south; a call must stay
-- under the client's 180 s), "sea" fills the open sea south of the bounds, "probe X Z" prints the
-- column at a local point. The MCP context cannot require the game's modules, so the plan comes in
-- as a string.
local Plan = loadstring(PLAN)()
local args = string.split(ARGS or "rows 0 0", " ")

local terrain = workspace.Terrain
local B, O = Plan.Bounds, Plan.Origin
local CELL = 4
local NX = (B.maxX - B.minX) / CELL
local NZ = (B.maxZ - B.minZ) / CELL
local CH = 32 -- columns along a chunk's side
local BASE_Y = -32 -- the ground is solid from here up
local GROUND = 2 -- the Vale's surface (Config.Map.GroundY)
local WATER_Y = 0 -- the river's and the sea's level
local BED_Y = -10

local M = Enum.Material
local noise = math.noise
local abs, sqrt, floor, min, max, exp = math.abs, math.sqrt, math.floor, math.min, math.max, math.exp

local function smooth(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end
local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end
local function fbm(x: number, z: number, seed: number): number
	return noise(x, z, seed) + 0.5 * noise(x * 2.03, z * 2.03, seed + 7) + 0.25 * noise(x * 4.1, z * 4.1, seed + 13)
end

-- One colour a material in the whole place: the old valley's palette, and the new world's own extras.
local function setLook()
	local colours = {
		[M.Grass] = Color3.fromRGB(126, 196, 72),
		[M.LeafyGrass] = Color3.fromRGB(168, 214, 84),
		[M.Sandstone] = Color3.fromRGB(214, 180, 120),
		[M.Mud] = Color3.fromRGB(74, 112, 96),
		[M.Ground] = Color3.fromRGB(176, 102, 66),
		[M.Snow] = Color3.fromRGB(236, 244, 252),
		[M.Limestone] = Color3.fromRGB(226, 208, 168),
		[M.Rock] = Color3.fromRGB(138, 132, 122),
		[M.Sand] = Color3.fromRGB(232, 210, 150),
		[M.CrackedLava] = Color3.fromRGB(232, 96, 40),
		[M.Basalt] = Color3.fromRGB(92, 70, 64),
		[M.Cobblestone] = Color3.fromRGB(156, 150, 142),
		[M.Glacier] = Color3.fromRGB(176, 220, 244),
	}
	for material, colour in colours do
		terrain:SetMaterialColor(material, colour)
	end
end

-- Catmull-Rom through a list of { x, z } points, a sample about every `step` studs.
local function curve(points: { { number } }, step: number): { { number } }
	local out = {}
	local n = #points
	for i = 1, n - 1 do
		local p0, p1, p2, p3 = points[max(i - 1, 1)], points[i], points[i + 1], points[min(i + 2, n)]
		local length = sqrt((p2[1] - p1[1]) ^ 2 + (p2[2] - p1[2]) ^ 2)
		local count = max(1, math.ceil(length / step))
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

local function cellIndex(x: number, z: number): number
	return floor((x - B.minX) / CELL) + floor((z - B.minZ) / CELL) * NX
end

-- Calls fn(index, distance) for every column whose middle is within `radius` of (x, z).
local function around(x: number, z: number, radius: number, fn: (number, number) -> ())
	local ix0, ix1 = floor((x - radius - B.minX) / CELL), floor((x + radius - B.minX) / CELL)
	local iz0, iz1 = floor((z - radius - B.minZ) / CELL), floor((z + radius - B.minZ) / CELL)
	for iz = max(iz0, 0), min(iz1, NZ - 1) do
		local cz = B.minZ + iz * CELL + 2
		for ix = max(ix0, 0), min(ix1, NX - 1) do
			local cx = B.minX + ix * CELL + 2
			local d = sqrt((cx - x) ^ 2 + (cz - z) ^ 2)
			if d <= radius then
				fn(ix + iz * NX, d)
			end
		end
	end
end

-- The river: how far each column near it is from its middle line.
local River = Plan.River
local riverD: { [number]: number } = {}
for _, p in curve(River.points, 6) do
	around(p[1], p[2], River.Width / 2 + 124, function(index, d)
		if d < (riverD[index] or math.huge) then
			riverD[index] = d
		end
	end)
end

-- Regions: the nearest seed wins, the borders frayed by noise; heights blend softly across them.
local Regions = Plan.Regions
local seeds = {}
local regionIndex = {}
for ri, region in Regions do
	regionIndex[region.id] = ri
	for _, at in region.at do
		table.insert(seeds, { at[1], at[2], ri })
	end
end
-- Every fight and village is a seed of its own region too, so the wandering borders never leave one outside.
for _, zone in Plan.Zones do
	if regionIndex[zone.region] then
		table.insert(seeds, { zone.x, zone.z, regionIndex[zone.region] })
	end
end
for _, village in Plan.Villages do
	table.insert(seeds, { village.x, village.z, regionIndex.vale })
end
local EMBER, FROST, VALE, MEADOW, MUSHROOM =regionIndex.ember, regionIndex.frost, regionIndex.vale, regionIndex.meadow, regionIndex.mushroom
local BLEND = 90
local nearest = table.create(#Regions, 0)

local Heart = Plan.Heart
local FLOOR_Y = GROUND + Heart.Top -- the crater floor
local LAKE_Y = FLOOR_Y - 2 -- the goo lake's level (a voxel line)
local Volcano = Plan.Volcano
local Rim = Plan.Rim

-- Pads: flat ground under every village, fight, the hub and the landmarks.
type Pad = { x: number, z: number, r: number, h: number?, material: Enum.Material?, lift: number }
local pads: { Pad } = {}
-- (A village's pad keeps the land's own grass: a ring of another green showed from above as a stamped circle.)
local padMaterial = { hub = M.Sand, mini = M.Sandstone, boss = M.Cobblestone }
for _, place in Plan.places() do
	if place.kind == "village" or place.kind == "hub" or place.kind == "mini" or place.kind == "boss" or place.kind == "landmark" then
		table.insert(pads, {
			x = place.x,
			z = place.z,
			r = place.radius,
			h = if place.kind == "village" or place.kind == "hub" or place.id == "quay" then GROUND else nil,
			material = padMaterial[place.kind],
			lift = if place.id == "lookout" then 14 else 0, -- a knoll over Crownfall's pool
		})
	end
end

-- The Heart's gates: a notch in the rim, a land bridge over the lake inside, a ramp down outside.
local gates = {}
do
	local next = { gate_w = "b1", gate_e = "b2", gate_n = { -40, -1210 } }
	for id, toward in next do
		local gate = assert(Plan.find(id))
		local tx, tz
		if type(toward) == "string" then
			tx, tz = Plan.point(toward)
		else
			tx, tz = toward[1], toward[2]
		end
		local ox, oz = tx - gate.x, tz - gate.z
		local ol = sqrt(ox * ox + oz * oz)
		local ix, iz = Heart.x - gate.x, Heart.z - gate.z
		local il = sqrt(ix * ix + iz * iz)
		table.insert(gates, { x = gate.x, z = gate.z, ox = ox / ol, oz = oz / ol, ix = ix / il, iz = iz / il, inLength = il })
	end
end
local RAMP_SLOPE = 0.42

-- What land() tells finish() besides the height.
local info = { region = 1, ember = 0, pad = nil :: Enum.Material?, heart = math.huge, special = nil :: Enum.Material?, sea = 0 }

-- The land before roads and the river's channel.
local function land(x: number, z: number, skipPads: boolean?): number
	-- 1. The region and its height.
	-- (A weak warp left the borders ruler-straight from above: they must wander by hundreds of studs.)
	local wx = x + 460 * noise(x / 640, z / 640, 3.3) + 130 * noise(x / 210, z / 210, 5.1) + 24 * noise(x / 48, z / 48, 7.7)
	local wz = z + 460 * noise(x / 640, z / 640, 11.7) + 130 * noise(x / 210, z / 210, 17.9) + 24 * noise(x / 48, z / 48, 19.3)
	for i = 1, #Regions do
		nearest[i] = math.huge
	end
	for _, s in seeds do
		local dx, dz = wx - s[1], wz - s[2]
		local d = sqrt(dx * dx + dz * dz)
		if d < nearest[s[3]] then
			nearest[s[3]] = d
		end
	end
	local best, dmin = 1, math.huge
	for i, d in nearest do
		if d < dmin then
			best, dmin = i, d
		end
	end
	local wsum, lift, swell, ember = 0, 0, 0, 0
	for i, d in nearest do
		local w = exp(-(d - dmin) / BLEND)
		wsum += w
		lift += w * Regions[i].lift
		swell += w * Regions[i].swell
		if i == EMBER then
			ember = w
		end
	end
	lift, swell, ember = lift / wsum, swell / wsum, ember / wsum
	local roll = math.clamp(0.5 + 0.55 * fbm(x / 230, z / 230, 1.5), 0, 1)
	local h = GROUND + lift + swell * roll
	-- 2. The Ember land steps down in terraces.
	if ember > 0.05 then
		h = lerp(h, floor(h / 9 + 0.5) * 9, 0.7 * ember)
	end
	info.region, info.ember, info.pad, info.special, info.sea = best, ember, nil, nil, 0

	-- 3. The river's valley: the land comes down to it.
	local rd = riverD[cellIndex(x, z)]
	if rd then
		h = lerp(GROUND + 0.5, h, smooth(River.Width / 2 + 8, River.Width / 2 + 120, rd))
	end

	-- 4. The rim mountains, the volcano and the peaks behind the ice.
	local rim = (abs(x - Rim.x) / Rim.radius) ^ Rim.power + (abs(z - Rim.z) / Rim.radius) ^ Rim.power
	local mount = smooth(0.86, 1.42, rim + 0.07 * noise(x / 170, z / 170, 23.4))
	if mount > 0 then
		local ridge = 1 - abs(noise(x / 150, z / 150, 41.2)) * 1.6
		h += mount * (130 + 70 * roll + 60 * ridge)
	end
	local dv = sqrt((x - Volcano.x) ^ 2 + (z - Volcano.z) ^ 2)
	if dv < Volcano.radius then
		local t = 1 - dv / Volcano.radius
		local cone = GROUND + 22 + Volcano.height * t ^ 1.35
		cone -= 46 * smooth(Volcano.crater * 1.5, Volcano.crater * 0.4, dv)
		if cone > h then
			h = cone
		end
		-- The crater's lava and three streams down the side that faces the Ember land.
		if dv < Volcano.crater * 0.8 then
			info.special = M.CrackedLava
		else
			local angle = math.atan2(z - Volcano.z, x - Volcano.x)
			for _, a in { 2.65, -3.0, -2.45 } do
				local off = abs(((angle - a + math.pi) % (2 * math.pi)) - math.pi) * dv
				if off < 7 + 5 * noise(dv / 40, a, 9.9) and dv < Volcano.radius * 0.92 then
					info.special = M.CrackedLava
				end
			end
		end
	end
	for _, peak in Plan.Peaks do
		local d = sqrt((x - peak[1]) ^ 2 + (z - peak[2]) ^ 2)
		if d < 440 then
			local top = GROUND + 52 + peak[3] * (1 - d / 440) ^ 1.3
			if top > h then
				h = top
			end
		end
	end

	-- 5. The South Bay.
	-- (Its shore is a curve that runs out to the south on both sides: a round bay, not a cut-out.)
	local shore = Plan.SeaZ + 380 * (abs(x) / 1000) ^ 3 + 55 * noise(x / 170, z / 170, 51.3) + 16 * noise(x / 45, z / 45, 53.1)
	local sea = smooth(-30, 90, z - shore)
	if sea > 0 then
		h = lerp(h, BED_Y - 4, sea)
		info.sea = sea
	end

	-- 6. The Heart: island, lake, rim, cliffs.
	local dh = sqrt((x - Heart.x) ^ 2 + (z - Heart.z) ^ 2)
	info.heart = dh
	local ground = h -- the land the Heart stands on
	if dh < Heart.FootRadius + 40 then
		local wobble = noise(x / 60, z / 60, 71.1)
		-- Steeper where Crownfall drops, so the water falls instead of sliding.
		local south = if z > Heart.z then smooth(70, 20, abs(x - Heart.Fall.x)) else 0
		local foot = Heart.FootRadius + 30 * wobble - 62 * south
		local crest = FLOOR_Y + Heart.RimRise + 9 * noise(x / 45, z / 45, 77.7)
		if dh <= Heart.LakeInner then
			h = FLOOR_Y
		elseif dh <= Heart.LakeOuter then
			local shore = min(dh - Heart.LakeInner, Heart.LakeOuter - dh)
			h = lerp(FLOOR_Y, FLOOR_Y - 12, smooth(0, 26, shore))
		elseif dh <= Heart.RimRadius then
			h = lerp(FLOOR_Y, crest, smooth(Heart.LakeOuter + 8, Heart.RimRadius, dh))
		elseif dh < foot then
			local t = smooth(Heart.RimRadius, foot, dh)
			h = lerp(crest, ground, t)
			-- Ledges on the way down.
			h = lerp(h, floor(h / 24 + 0.5) * 24, 0.55 * (1 - abs(2 * t - 1)))
		end
	end

	-- 7. Pads.
	if not skipPads then
		for _, pad in pads do
			local dx, dz = x - pad.x, z - pad.z
			if abs(dx) < pad.r + 60 and abs(dz) < pad.r + 60 then
				local d = sqrt(dx * dx + dz * dz)
				if d < pad.r + 56 then
					h = lerp(pad.h :: number, h, smooth(pad.r, pad.r + 56, d))
					if pad.material and d < pad.r - 3 + 5 * noise(x / 14, z / 14, 6.6) then
						info.pad = pad.material
					end
				end
			end
		end
	end

	-- 8. The gates.
	for _, gate in gates do
		local px, pz = x - gate.x, z - gate.z
		if abs(px) < 470 and abs(pz) < 470 then
			local half = Heart.GateWidth / 2
			-- Outside: a ramp along the causeway, down to the land.
			local s = px * gate.ox + pz * gate.oz
			if s >= -6 and s < 440 then
				local lat = abs(pz * gate.ox - px * gate.oz)
				if lat < half + 22 then
					local target = max(FLOOR_Y - RAMP_SLOPE * max(0, s - 14), ground)
					h = lerp(target, h, smooth(half - 6, half + 20, lat))
				end
			end
			-- Inside: level through the rim, then a land bridge over the lake to the island.
			local si = px * gate.ix + pz * gate.iz
			if si >= -6 and si < gate.inLength - Heart.LakeInner + 12 then
				local lat = abs(pz * gate.ix - px * gate.iz)
				local width = if si < Heart.RimRadius - Heart.LakeOuter + 6 then half else 11
				if lat < width + 16 then
					h = lerp(FLOOR_Y, h, smooth(width - 4, width + 14, lat))
				end
			end
		end
	end
	return h
end

-- Pads take the height of the land under their middle.
for _, pad in pads do
	if not pad.h then
		pad.h = floor(land(pad.x, pad.z, true) + 0.5) + pad.lift
	end
end

-- Roads: each column near one knows how far the middle line is, how high it runs and how wide it is.
local roadD: { [number]: number } = {}
local roadH: { [number]: number } = {}
local roadW: { [number]: number } = {}
local roadM: { [number]: Enum.Material } = {}
for _, road in Plan.Roads do
	local samples = curve(Plan.roadPoints(road), 3)
	local heights = table.create(#samples, 0)
	for i, p in samples do
		heights[i] = land(p[1], p[2])
	end
	local material = if road.kind == "causeway" then M.Cobblestone else M.Sandstone
	local half = road.width / 2
	for i, p in samples do
		-- The road's own height: the land's, smoothed along the way.
		local sum, count = 0, 0
		for k = max(1, i - 9), min(#samples, i + 9) do
			sum += heights[k]
			count += 1
		end
		local h = sum / count
		around(p[1], p[2], half + 16, function(index, d)
			if d < (roadD[index] or math.huge) then
				roadD[index], roadH[index], roadW[index], roadM[index] = d, h, half, material
			end
		end)
	end
	task.wait()
end

-- A column as it is written: surface height, top material, water level (or nil).
local Pool = Heart.Pool
local function finish(x: number, z: number): (number, Enum.Material, number?, number)
	local h = land(x, z)
	local region, ember, pad, special, dh, sea = info.region, info.ember, info.pad, info.special, info.heart, info.sea
	local index = cellIndex(x, z)
	local material: Enum.Material? = pad or special

	local rd = roadD[index]
	local onRoad = false
	if rd then
		local half = roadW[index]
		h = lerp(roadH[index], h, smooth(half + 1, half + 14, rd))
		if rd < half + 1.6 * noise(x / 9, z / 9, 8.8) then
			material = roadM[index]
			onRoad = true
		end
	end

	-- The river's channel, Crownfall's pool, and the notch the lake spills through.
	local wet = false
	local riv = riverD[index]
	if riv and riv < River.Width / 2 + 24 then
		local t = smooth(River.Width / 2 - 4, River.Width / 2 + 16, riv + 3 * noise(x / 30, z / 30, 4.4))
		h = lerp(BED_Y, h, t)
		wet = t < 0.9
	end
	local dp = sqrt((x - Pool.x) ^ 2 + (z - Pool.z) ^ 2)
	if dp < Pool.radius + 16 then
		local t = smooth(Pool.radius - 8, Pool.radius + 14, dp)
		h = lerp(BED_Y, h, t)
		wet = wet or t < 0.9
	end
	if abs(x - Heart.Fall.x) < 24 and z > Heart.z + Heart.LakeOuter - 30 and z < Heart.Fall.z + 6 then
		h = lerp(FLOOR_Y - 8, h, smooth(11, 21, abs(x - Heart.Fall.x)))
	end

	local water: number? = nil
	if dh < Heart.RimRadius + 4 then
		if h < LAKE_Y then
			water = LAKE_Y
		end
	elseif h < WATER_Y then
		water = WATER_Y
	end

	if not material or (wet and h < GROUND - 0.5) then
		if h < GROUND + 1.4 and (sea > 0.02 or wet) then
			material = M.Sand
		elseif dh < Heart.LakeOuter + 4 and dh > Heart.LakeInner - 4 and h < FLOOR_Y - 1 then
			material = M.Sand
		elseif dh < 64 + 4 * noise(x / 12, z / 12, 2.2) then
			material = M.Limestone -- the mega-boss's floor
		elseif dh < Heart.FootRadius + 40 and h > FLOOR_Y - 30 then
			material = M.LeafyGrass
		elseif region == VALE then
			material = if noise(x / 95, z / 95, 81.5) > 0.22 then M.LeafyGrass else M.Grass
		elseif region == MEADOW then
			material = if noise(x / 95, z / 95, 81.5) > 0.3 then M.Grass else M.LeafyGrass
		elseif region == MUSHROOM then
			material = M.Mud
		elseif region == EMBER then
			if ember > 0.85 and abs(noise(x / 58, z / 58, 91.9)) < 0.03 then
				material = M.CrackedLava
			else
				material = if noise(x / 70, z / 70, 33.3) > 0.4 then M.Ground else M.Basalt
			end
		else
			material = if noise(x / 80, z / 80, 55.5) > 0.38 then M.Glacier else M.Snow
		end
		-- Snow on the high ground of the north.
		if h > 150 and z < -1100 and material ~= M.CrackedLava then
			material = M.Snow
		end
	end
	-- The last value tells the cliff pass what this column is: 1 a road or pad (never rock), 4 the Heart's own
	-- cliffs (rock on gentler faces too), 2 Ember, 3 Frost, 0 the rest.
	local kind = if onRoad or pad ~= nil
		then 1
		elseif dh < Heart.FootRadius + 40 and dh > Heart.RimRadius - 30 then 4
		elseif region == EMBER then 2
		elseif region == FROST then 3
		else 0
	return h, material :: Enum.Material, water, kind
end

-- Steep ground shows its rock.
local CLIFF = { [0] = M.Rock, [2] = M.Basalt, [3] = M.Rock, [4] = M.Rock }

local function writeChunk(cx: number, cz: number): number
	local ix0, iz0 = cx * CH, cz * CH
	local nx, nz = min(CH, NX - ix0), min(CH, NZ - iz0)
	local w = nx + 2
	local heights, materials, waters, kinds = {}, {}, {}, {}
	local low, high = math.huge, -math.huge
	for j = 0, nz + 1 do
		local z = B.minZ + (iz0 + j - 1) * CELL + 2
		for i = 0, nx + 1 do
			local x = B.minX + (ix0 + i - 1) * CELL + 2
			local h, material, water, kind = finish(math.clamp(x, B.minX + 2, B.maxX - 2), math.clamp(z, B.minZ + 2, B.maxZ - 2))
			local at = i + j * w
			heights[at], materials[at], waters[at], kinds[at] = h, material, water, kind
			low = min(low, h)
			high = max(high, h, water or -math.huge)
		end
	end
	local y0 = max(BASE_Y, floor((low - 14) / CELL) * CELL)
	local y1 = (floor(high / CELL) + 2) * CELL
	local ny = (y1 - y0) / CELL
	local mats, occs = table.create(nx), table.create(nx)
	for i = 1, nx do
		local mx, ox = table.create(ny), table.create(ny)
		for y = 1, ny do
			mx[y], ox[y] = table.create(nz, M.Air), table.create(nz, 0)
		end
		mats[i], occs[i] = mx, ox
	end
	for j = 1, nz do
		for i = 1, nx do
			local at = i + j * w
			local h, material, water, kind = heights[at], materials[at], waters[at], kinds[at]
			if kind ~= 1 then
				local steep = max(abs(heights[at - 1] - h), abs(heights[at + 1] - h), abs(heights[at - w] - h), abs(heights[at + w] - h))
				if steep > (if kind == 4 then 2.6 else 4.6) and material ~= M.CrackedLava then
					material = CLIFF[kind]
				end
			end
			-- A surface at h: voxels full below b, and the voxel from b up filled (h - 2 - b) / 4 (measured in Studio).
			local b = floor((h - 2) / CELL) * CELL
			local top = (b - y0) / CELL + 1
			local mx, ox = mats[i], occs[i]
			for y = 1, min(top - 1, ny) do
				mx[y][j], ox[y][j] = material, 1
			end
			local part = (h - 2 - b) / CELL
			local from = top
			if part > 0.02 and top <= ny then
				mx[top][j], ox[top][j] = material, part
				from = top + 1
			end
			if water then
				for y = from, min((water - y0) / CELL, ny) do
					mx[y][j], ox[y][j] = M.Water, 1
				end
			end
		end
	end
	local wx, wz = O.x + B.minX + ix0 * CELL, O.z + B.minZ + iz0 * CELL
	local sx, sz = nx * CELL, nz * CELL
	terrain:FillBlock(CFrame.new(wx + sx / 2, 220, wz + sz / 2), Vector3.new(sx, 520, sz), M.Air)
	terrain:WriteVoxels(Region3.new(Vector3.new(wx, y0, wz), Vector3.new(wx + sx, y1, wz + sz)), CELL, mats, occs)
	return ny
end

if args[1] == "probe" then
	local x, z = tonumber(args[2]) :: number, tonumber(args[3]) :: number
	local h, material, water = finish(x, z)
	return string.format("(%d, %d): surface %.1f %s water %s region %s", x, z, h, material.Name, tostring(water), Regions[info.region].id)
elseif args[1] == "sea" then
	-- Open water beyond the bay, so no edge of the world shows from the quay.
	for step = 0, 5 do
		local z0 = B.maxZ + step * 200
		terrain:FillBlock(CFrame.new(O.x, (BED_Y - 4 + WATER_Y) / 2, O.z + z0 + 100), Vector3.new(3600, WATER_Y - (BED_Y - 4), 200), M.Water)
		task.wait()
	end
	return "sea filled"
elseif args[1] == "rows" then
	setLook()
	local started = os.clock()
	local a, b = tonumber(args[2]) :: number, tonumber(args[3]) :: number
	local chunks = 0
	for cz = a, b do
		for cx = 0, math.ceil(NX / CH) - 1 do
			writeChunk(cx, cz)
			chunks += 1
			if chunks % 3 == 0 then
				task.wait()
			end
		end
	end
	return string.format("rows %d..%d: %d chunks in %.1f s", a, b, chunks, os.clock() - started)
end
return "nothing to do: " .. table.concat(args, " ")
