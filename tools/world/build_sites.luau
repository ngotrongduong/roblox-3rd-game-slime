-- Builds what stands at the big world's named places (docs/WORLD.md) from the kits already in the work place: the
-- Market moved to the hub (it stays workspace.Map.Market), the four bridges, a ring of its region's own pieces round each of the 13 fights, the
-- landmarks (Wayfarers' Cross, South Quay, Crownfall's lookout, the mill), and the signs and lamps that lead a player
-- along the roads. Everything goes into workspace.World.Sites and a run rebuilds it whole, except the Heart (its
-- gates, crown, arena and Crownfall): that is tools/world/build_heart.luau's folder, kept as it is here. Places and
-- roads come from src/shared/WorldPlan.luau; heights are read off the terrain.
--
--   node tools/studio_mcp.js run tools/world/build_sites.luau <studio_id> Edit PLAN=src/shared/WorldPlan.luau
--
-- Interim pieces, until their own models exist (docs/WORLD.md "Missing assets"): the bridges (parts).
local ServerStorage = game:GetService("ServerStorage")
local Plan = loadstring(PLAN)()
local terrain = workspace.Terrain
local O = Plan.Origin
local TAU = math.pi * 2
local rng = Random.new(20261114)

local world = workspace:FindFirstChild("World") or Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local old = world:FindFirstChild("Sites")
local keptHeart = old and old:FindFirstChild("Heart") -- build_heart.luau's work, carried into the new folder
if keptHeart then
	keptHeart.Parent = nil
end
if old then
	old:Destroy()
end
local sites = Instance.new("Folder")
sites.Name = "Sites"
local function folder(name: string, parent: Instance?): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or sites
	return f
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { terrain }
rp.IgnoreWater = true
local function groundAt(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(O.x + x, 600, O.z + z), Vector3.new(0, -700, 0), rp)
	return if hit then hit.Position.Y else 2
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local MUSHROOM = rgb(140, 255, 215)

local missing: { [string]: boolean } = {}
local count = 0
type Options = { wide: boolean?, y: number?, sink: number?, soft: boolean?, tint: Color3?, name: string?, tall: number? }
-- A kit model stood at a local point, `height` studs tall, its through-axis (Z) along `facing` (or turned by chance).
local function put(parent: Instance, kit: string, name: string, x: number, z: number, height: number, facing: { number }?, options: Options?): Model?
	local opts: Options = options or {}
	local src = ServerStorage[kit]:FindFirstChild(name)
	if not src then
		missing[name] = true
		return nil
	end
	local copy = src:Clone()
	local model = copy
	if not copy:IsA("Model") then
		model = Instance.new("Model")
		copy.Parent = model
	end
	model.Name = opts.name or name
	model.PrimaryPart = nil
	model.WorldPivot = CFrame.new()
	local _, size = model:GetBoundingBox()
	local ref = if opts.wide then math.max(size.X, size.Z) else size.Y
	model:ScaleTo(model:GetScale() * height / math.max(ref, 0.01))
	local box, scaled = model:GetBoundingBox()
	local foot = box.Position - Vector3.new(0, scaled.Y / 2, 0)
	if opts.tall then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Size = Vector3.new(d.Size.X, d.Size.Y * opts.tall, d.Size.Z)
				d.Position = Vector3.new(d.Position.X, foot.Y + (d.Position.Y - foot.Y) * opts.tall, d.Position.Z)
			end
		end
	end
	model.WorldPivot = CFrame.new(foot)
	local turn = if facing then CFrame.lookAt(Vector3.zero, Vector3.new(facing[1], 0, facing[2])) else CFrame.Angles(0, rng:NextNumber(0, TAU), 0)
	model:PivotTo(CFrame.new(O.x + x, (opts.y or groundAt(x, z)) - (opts.sink or 0.3), O.z + z) * turn)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanCollide = not opts.soft
			d.CastShadow = scaled.Y >= 10
			if opts.tint then
				local sa = d:FindFirstChildOfClass("SurfaceAppearance")
				if sa then
					sa.Color = opts.tint
				else
					d.Color = opts.tint
				end
			end
		end
	end
	model.Parent = parent
	count += 1
	if count % 25 == 0 then
		task.wait()
	end
	return model
end

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?, studs: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.Plastic
	p.TopSurface = if studs then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanTouch = false
	p.Parent = parent
	return p
end

-- Roads as the terrain builder draws them (the same Catmull-Rom curve).
local function curve(points: { { number } }, step: number): { { number } }
	local out = {}
	local n = #points
	for i = 1, n - 1 do
		local p0, p1, p2, p3 = points[math.max(i - 1, 1)], points[i], points[i + 1], points[math.min(i + 2, n)]
		local parts = math.max(1, math.ceil(math.sqrt((p2[1] - p1[1]) ^ 2 + (p2[2] - p1[2]) ^ 2) / step))
		for k = 0, parts - 1 do
			local t = k / parts
			local t2, t3 = t * t, t * t * t
			local x = 0.5 * (2 * p1[1] + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t3)
			local z = 0.5 * (2 * p1[2] + (p2[2] - p0[2]) * t + (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t2 + (3 * p1[2] - p0[2] - 3 * p2[2] + p3[2]) * t3)
			table.insert(out, { x, z })
		end
	end
	table.insert(out, { points[n][1], points[n][2] })
	return out
end
local lines: { { road: any, samples: { { number } } } } = {}
for _, road in Plan.Roads do
	table.insert(lines, { road = road, samples = curve(Plan.roadPoints(road), 3) })
end
-- Where roads cross a circle: { angle, the road's width }.
local function crossings(x: number, z: number, radius: number): { { number } }
	local out = {}
	for _, line in lines do
		local last: number? = nil
		for _, s in line.samples do
			local d = math.sqrt((s[1] - x) ^ 2 + (s[2] - z) ^ 2) - radius
			if last and (last < 0) ~= (d < 0) then
				table.insert(out, { math.atan2(s[2] - z, s[1] - x), line.road.width })
			end
			last = d
		end
	end
	return out
end
-- The road through a point: its direction there and its width.
local function roadAt(x: number, z: number): (number, number, number)
	local best, bx, bz, width = math.huge, 1, 0, 10
	for _, line in lines do
		for i = 2, #line.samples - 1 do
			local s = line.samples[i]
			local d = (s[1] - x) ^ 2 + (s[2] - z) ^ 2
			if d < best then
				local a, b = line.samples[i - 1], line.samples[i + 1]
				local l = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
				best, bx, bz, width = d, (b[1] - a[1]) / l, (b[2] - a[2]) / l, line.road.width
			end
		end
	end
	return bx, bz, width
end

---------------------------------------------------------------------------------------------------------------------
-- 1. The Market, moved to the hub and turned to face north: the King's Road, the Cross and the Heart. It is the
-- game's own workspace.Map.Market, moved once from its place in the old valley (WorldPlan.Market is where the middle
-- of its square then lies); a run after that leaves it alone.
do
	local market = workspace.Map.Market
	if not market:GetAttribute("AtHub") then
		local box = market:GetBoundingBox()
		local move = CFrame.new(O.x + Plan.Hub.x, 0, O.z + Plan.Hub.z) * CFrame.Angles(0, math.pi, 0) * CFrame.new(-box.Position.X, 0, -box.Position.Z)
		market:PivotTo(move * market:GetPivot())
		market:SetAttribute("AtHub", true)
	end
	task.wait()
end

---------------------------------------------------------------------------------------------------------------------
-- 2. Bridges: an arched plank deck on stone, along the road that crosses there.
local PLANK, RAIL, STONE = rgb(176, 124, 78), rgb(120, 82, 52), rgb(168, 160, 150)
local bridges = folder("Bridges")
for _, site in Plan.Sites do
	if site.kind == "bridge" then
		local model = Instance.new("Model")
		model.Name = site.name
		local dx, dz, roadWidth = roadAt(site.x, site.z)
		local width, half, rise, steps = roadWidth + 4, 34, 4, 10
		local base = math.max(groundAt(site.x - dx * half, site.z - dz * half), groundAt(site.x + dx * half, site.z + dz * half)) + 0.4
		local frame = CFrame.lookAt(Vector3.new(O.x + site.x, base, O.z + site.z), Vector3.new(O.x + site.x + dx, base, O.z + site.z + dz))
		-- (along the bridge is the frame's -Z)
		local function at(t: number, side: number, up: number): Vector3
			return (frame * CFrame.new(side, rise * (1 - t * t) + up, -t * half)).Position
		end
		for i = 0, steps - 1 do
			local t0, t1 = -1 + 2 * i / steps, -1 + 2 * (i + 1) / steps
			local a, b = at(t0, 0, 0), at(t1, 0, 0)
			block(model, "Deck", Vector3.new(width, 1, (b - a).Magnitude + 0.4), CFrame.lookAt((a + b) / 2, b), PLANK, Enum.Material.WoodPlanks, true)
			for side = -1, 1, 2 do
				local s = side * (width / 2 - 0.7)
				local ra, rb = at(t0, s, 4), at(t1, s, 4)
				block(model, "Rail", Vector3.new(0.8, 0.8, (rb - ra).Magnitude + 0.3), CFrame.lookAt((ra + rb) / 2, rb), RAIL, Enum.Material.Wood)
				block(model, "Post", Vector3.new(1.2, 4.4, 1.2), CFrame.new(at(t0, s, 2.2)) * frame.Rotation, RAIL, Enum.Material.Wood)
				if i == steps - 1 then
					block(model, "Post", Vector3.new(1.2, 4.4, 1.2), CFrame.new(at(t1, s, 2.2)) * frame.Rotation, RAIL, Enum.Material.Wood)
				end
			end
		end
		for _, t in { -1, 1 } do
			block(model, "Abutment", Vector3.new(width + 4, 9, 9), CFrame.new(at(t, 0, -4.4)) * frame.Rotation, STONE, Enum.Material.Slate)
		end
		for _, t in { -0.36, 0.36 } do
			block(model, "Pier", Vector3.new(width - 2, 16, 4), CFrame.new(at(t, 0, -8.4)) * frame.Rotation, STONE, Enum.Material.Slate)
		end
		model.Parent = bridges
		task.wait()
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 3. The fights: a ring of the region's own pieces, open where roads come in, torches at each way in. A boss has
-- bigger pieces and a throne of three behind the ring, in the widest gap between its roads.
type Piece = { any } -- { kit, name, least height, most height, tint? }
type Theme = { ring: { Piece }, throne: { Piece }? }
local THEMES: { [string]: Theme } = {
	meadow = { ring = { { "WildKit", "OwnMossyRockStack", 6, 10 }, { "OwnerKit", "StackedRocks", 5, 8 }, { "OwnerKit", "WideBoulder", 3, 5 } } },
	mushroom = { ring = { { "WildKit", "OwnMushPurple", 9, 16 }, { "WildKit", "OwnMushBlue", 9, 16, MUSHROOM }, { "PropKit", "GiantMushroom", 14, 24, MUSHROOM }, { "WildKit", "OwnMossyRockStack", 5, 8 } } },
	ember = { ring = { { "WildKit", "OwnStackedBasalt", 6, 11 }, { "WildKit", "OwnMagmaCrystalCluster", 7, 12 }, { "OwnerKit", "JaggedRocks", 6, 10 } } },
	frost = { ring = { { "WildKit", "OwnFrozenRockSpire", 8, 14 }, { "WildKit", "OwnIceCrystalCluster", 5, 9 }, { "NatureKit", "SnowyBoulder", 5, 8 } } },
	m7 = { ring = { { "PropKit", "RuinArch", 16, 22 }, { "PropKit", "DryStoneWall", 6, 8 }, { "WildKit", "OwnMossyRockStack", 5, 8 }, { "PropKit", "DryStoneWall", 5, 7 } } },
	m8 = { ring = { { "WildKit", "QtDeadTree_3", 22, 34 }, { "WildKit", "OwnStackedBasalt", 8, 14 }, { "OwnerKit", "JaggedRocks", 6, 10 } } },
	b1 = {
		ring = { { "PropKit", "GiantMushroom", 24, 40, MUSHROOM }, { "PropKit", "TwistedTree", 26, 36 }, { "WildKit", "OwnMushPurple", 12, 18 } },
		throne = { { "PropKit", "GiantMushroom", 84, 84, MUSHROOM }, { "PropKit", "GiantMushroom", 56, 56, MUSHROOM }, { "WildKit", "OwnMushPurple", 48, 48 } },
	},
	b2 = {
		ring = { { "WildKit", "OwnStackedBasalt", 10, 18 }, { "WildKit", "OwnMagmaCrystalCluster", 12, 20 }, { "OwnerKit", "JaggedRocks", 9, 14 } },
		throne = { { "WildKit", "OwnMagmaCrystalCluster", 60, 60 }, { "WildKit", "OwnStackedBasalt", 40, 40 }, { "WildKit", "OwnMagmaCrystalCluster", 38, 38 } },
	},
	b3 = {
		ring = { { "WildKit", "OwnIceCrystalSpire", 16, 28 }, { "WildKit", "OwnFrozenRockSpire", 12, 20 }, { "WildKit", "OwnIceCrystalCluster", 8, 12 } },
		throne = { { "WildKit", "OwnIceCrystalSpire", 80, 80 }, { "WildKit", "OwnIceCrystalSpire", 52, 52 }, { "WildKit", "OwnFrozenRockSpire", 40, 40 } },
	},
}
local zones = folder("Zones")
for _, zone in Plan.Zones do
	if zone.kind == "mega" then
		continue
	end
	local theme = THEMES[zone.id] or THEMES[zone.region]
	local into = folder(zone.name, zones)
	local radius = zone.radius - 5
	local ways = crossings(zone.x, zone.z, radius)
	local function open(angle: number, margin: number): boolean
		for _, way in ways do
			local off = math.abs((angle - way[1] + math.pi) % TAU - math.pi)
			if off < (way[2] / 2 + margin) / radius then
				return true
			end
		end
		return false
	end
	local n = math.floor(TAU * radius / (if zone.kind == "boss" then 21 else 17))
	for i = 1, n do
		local angle = (i + rng:NextNumber(-0.25, 0.25)) / n * TAU
		if not open(angle, 9) then
			local piece = theme.ring[rng:NextInteger(1, #theme.ring)]
			local r = radius + rng:NextNumber(-2, 4)
			put(into, piece[1], piece[2], zone.x + math.cos(angle) * r, zone.z + math.sin(angle) * r, rng:NextNumber(piece[3], piece[4]), { -math.cos(angle), -math.sin(angle) }, { tint = piece[5], sink = 0.6 })
		end
	end
	for _, way in ways do
		for side = -1, 1, 2 do
			local angle = way[1] + side * (way[2] / 2 + 6) / radius
			put(into, "PropKit", "TorchSconce", zone.x + math.cos(angle) * radius, zone.z + math.sin(angle) * radius, if zone.kind == "boss" then 13 else 10, { -math.cos(angle), -math.sin(angle) })
		end
	end
	if ways[1] then
		local angle = ways[1][1] + (ways[1][2] / 2 + 12) / radius
		put(into, "PropKit", "Signpost", zone.x + math.cos(angle) * (radius + 12), zone.z + math.sin(angle) * (radius + 12), 7, { math.cos(angle), math.sin(angle) })
	end
	if theme.throne then
		-- The widest gap between its roads: the middle of it is behind the boss.
		local angles = {}
		for _, way in ways do
			table.insert(angles, way[1])
		end
		table.sort(angles)
		local back, widest = 0, -1
		for i, a in angles do
			local gap = ((angles[i % #angles + 1] - a) % TAU + TAU) % TAU
			if #angles == 1 then
				gap = TAU
			end
			if gap > widest then
				back, widest = a + gap / 2, gap
			end
		end
		for i, piece in theme.throne do
			local angle = back + ({ 0, -0.34, 0.34 })[i]
			local r = radius + ({ 22, 12, 12 })[i]
			put(into, piece[1], piece[2], zone.x + math.cos(angle) * r, zone.z + math.sin(angle) * r, piece[3], { -math.cos(angle), -math.sin(angle) }, { tint = piece[5], sink = 1.5 })
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 4, 5. The Heart and Crownfall: tools/world/build_heart.luau.

---------------------------------------------------------------------------------------------------------------------
-- 6. Landmarks.
local marks = folder("Landmarks")
do
	local cross = Plan.find("cross")
	put(marks, "OwnerKit", "BanyanTree", cross.x - 44, cross.z - 30, 96, nil, { name = "GreatOak", sink = 2 })
	put(marks, "PropKit", "Signpost", cross.x + 11, cross.z + 10, 8, { 0, 1 })
	put(marks, "PropKit", "NoticeBoard", cross.x - 13, cross.z + 12, 7, { 0, 1 })
	put(marks, "OwnerKit", "LogBench", cross.x - 26, cross.z - 6, 2.4, { 1, 0.6 })
	put(marks, "OwnerKit", "LogBench", cross.x - 34, cross.z + 2, 2.4, { 0.4, 1 })
	put(marks, "PropKit", "VillageLamp", cross.x + 12, cross.z - 11, 12)
	put(marks, "PropKit", "VillageLamp", cross.x - 16, cross.z - 14, 12)

	local lookout = Plan.find("lookout")
	put(marks, "PropKit", "PavilionWood", lookout.x, lookout.z - 4, 22, { 0, -1 }, { name = "CrownfallLookout" })
	put(marks, "OwnerKit", "LogBench", lookout.x - 14, lookout.z + 10, 2.4, { 0, -1 })
	put(marks, "OwnerKit", "LogBench", lookout.x + 14, lookout.z + 10, 2.4, { 0, -1 })
	put(marks, "PropKit", "VillageLamp", lookout.x + 18, lookout.z + 18, 12)

	put(marks, "PropKit", "FarmWindmill", 330, 480, 64, { -0.6, 0.8 }, { name = "Mill" })

	-- South Quay: lighthouse, boathouse, a pier out over the bay with boats.
	local quay = Plan.find("quay")
	put(marks, "PropKit", "Lighthouse", quay.x + 30, quay.z + 8, 84, nil)
	put(marks, "PropKit", "Boathouse", quay.x - 30, quay.z - 6, 24, { 0, 1 })
	put(marks, "PropKit", "FishingHut", quay.x + 4, quay.z - 30, 15, { 0, 1 })
	put(marks, "PropKit", "VillageLamp", quay.x - 8, quay.z + 26, 12)
	local shore = quay.z + 30
	while groundAt(quay.x - 6, shore) > 0.5 and shore < quay.z + 160 do
		shore += 4
	end
	local pier = Instance.new("Model")
	pier.Name = "Pier"
	local from, length = shore - 14, 64
	local frame = CFrame.new(O.x + quay.x - 6, 2.6, O.z + from + length / 2)
	block(pier, "Deck", Vector3.new(10, 1, length), frame, PLANK, Enum.Material.WoodPlanks, true)
	for z = -length / 2 + 4, length / 2, 12 do
		for side = -1, 1, 2 do
			block(pier, "Post", Vector3.new(1.4, 14, 1.4), frame * CFrame.new(side * 4.6, -4.5, z), RAIL, Enum.Material.Wood)
		end
	end
	pier.Parent = marks
	put(marks, "PropKit", "RowBoat", quay.x - 16, from + length - 12, 3.6, { 0.2, 1 }, { y = 0.2, sink = 0.9 })
	put(marks, "PropKit", "RowBoat", quay.x + 5, from + length - 26, 3.6, { -0.3, 1 }, { y = 0.2, sink = 0.9 })
end

---------------------------------------------------------------------------------------------------------------------
-- 7. Wayfinding: a gate, a sign and lamps where the lane meets each village; signs at the junctions; lamps along the
-- King's Road (the way a new player first walks).
local villages = folder("Villages")
for _, village in Plan.Villages do
	local fx, fz = Plan.villageFacing(village)
	local out = Plan.Village.GateOut - 14
	put(villages, "PropKit", "VillageGate", village.x + fx * out, village.z + fz * out, 15, { fx, fz }, { name = village.name .. " Gate" })
	for side = -1, 1, 2 do
		put(villages, "PropKit", "VillageLamp", village.x + fx * (out + 5) - fz * side * 13, village.z + fz * (out + 5) + fx * side * 13, 12)
	end
	put(villages, "PropKit", "Signpost", village.x + fx * (out + 8) - fz * 19, village.z + fz * (out + 8) + fx * 19, 7, { fx, fz })
end
local wayside = folder("Wayside")
for _, site in Plan.Sites do
	if site.kind == "junction" then
		local dx, dz, width = roadAt(site.x, site.z)
		put(wayside, "PropKit", "Signpost", site.x - dz * (width / 2 + 5), site.z + dx * (width / 2 + 5), 7, { dx, dz })
		put(wayside, "PropKit", "VillageLamp", site.x + dz * (width / 2 + 5), site.z - dx * (width / 2 + 5), 12)
	end
end
for _, line in lines do
	if line.road.id == "kings_road" then
		for i = 30, #line.samples - 20, 24 do
			local s, a, b = line.samples[i], line.samples[i - 1], line.samples[i + 1]
			local l = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
			local side = if (i // 24) % 2 == 0 then 1 else -1
			local off = (line.road.width / 2 + 4) * side
			local x, z = s[1] - (b[2] - a[2]) / l * off, s[2] + (b[1] - a[1]) / l * off
			if (x - Plan.Hub.x) ^ 2 + (z - Plan.Hub.z) ^ 2 > (Plan.Hub.radius + 20) ^ 2 then
				put(wayside, "PropKit", "VillageLamp", x, z, 12)
			end
		end
	end
end

if keptHeart then
	keptHeart.Parent = sites
end
sites.Parent = world
local names = {}
for name in missing do
	table.insert(names, name)
end
return string.format("sites: %d kit pieces, %d instances; missing: %s", count, #sites:GetDescendants(), table.concat(names, " "))
