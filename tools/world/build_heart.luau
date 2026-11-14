-- Builds the Heart (docs/WORLD.md, reference pictures docs/references/heart/): the crater in the middle of the world.
-- Three gates where the causeways cut the rim, kerbs and crystal lanterns along the causeways, the Crown (a shrine
-- crowned with crystals) at the island's north end, a paved arena with a ring of rune stones round
-- the fight, crowned stone guardians at every way in, slime-head spouts pouring into the lake, crystals, ruins, trees
-- and flowers on the shores, and Crownfall leaving south. Everything goes into workspace.World.Sites.Heart and a run
-- rebuilds that folder whole (tools/world/build_sites.luau keeps it). The models of its own come from
-- tools/world/take_gates.luau and tools/world/take_heart.luau; the rest is the kit. Places come from
-- src/shared/WorldPlan.luau; heights are read off the terrain.
--
--   node tools/studio_mcp.js run tools/world/build_heart.luau <studio_id> Edit PLAN=src/shared/WorldPlan.luau
--
-- The fight stands on the TERRAIN at the island's middle (server/ZoneGuards): nothing built stands within ARENA studs
-- of it, and the arena's floor is a quarter of a stud thick.
local ServerStorage = game:GetService("ServerStorage")
local Plan = loadstring(PLAN)()
local terrain = workspace.Terrain
local O, Heart = Plan.Origin, Plan.Heart
local TAU = math.pi * 2
local rng = Random.new(20261114)

local MEDALLION = "rbxassetid://139392512230048" -- the arena's floor, drawn by ChatGPT (art/world/heart_medallion.png)
local PICTURE = 48 -- its radius: the fight's own ring
local MEDALLION_TURN = math.pi -- the turn that points the picture's crown north (seen in Studio: unturned it points south)
local STREAKS = "rbxassetid://1610017834" -- falling water streaks (the village fountain's)
local ARENA = 60 -- the floor's radius; the fight's own ring is 48

local world = workspace:FindFirstChild("World") or Instance.new("Folder")
world.Name = "World"
world.Parent = workspace
local sites = world:FindFirstChild("Sites") or Instance.new("Folder")
sites.Name = "Sites"
sites.Parent = world
local old = sites:FindFirstChild("Heart")
if old then
	old:Destroy()
end
local heart = Instance.new("Folder")
heart.Name = "Heart"
local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = heart
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
local FLOOR = groundAt(Heart.x, Heart.z)
local LAKE = FLOOR - 4 -- the water's surface (read in Studio)

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
-- The kit's crystals are blue in their texture and a tint cannot reach turquoise: they are painted (texture off, one
-- flat colour, the facets come from the game's light), the colour of the crystals on the shrine's roof.
local TURQUOISE = rgb(70, 225, 215)
local MUSHROOM = rgb(140, 255, 215)
local STONE, STONE_DARK, STONE_PALE = rgb(205, 170, 150), rgb(160, 128, 120), rgb(192, 158, 140) -- the floor picture's sandstone
local GOLD = rgb(236, 180, 60)
local WATER, FOAM = rgb(140, 214, 244), rgb(245, 252, 255)

local missing: { [string]: boolean } = {}
local count = 0
type Options = { wide: boolean?, y: number?, sink: number?, soft: boolean?, tint: Color3?, paint: Color3?, name: string?, tall: number?, turn: number? }
-- A kit model stood at a local point, `height` studs tall, its front (-Z) looking along `facing` (or turned by chance).
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
	local turn = if facing then CFrame.lookAt(Vector3.zero, Vector3.new(facing[1], 0, facing[2])) else CFrame.Angles(0, opts.turn or rng:NextNumber(0, TAU), 0)
	model:PivotTo(CFrame.new(O.x + x, (opts.y or groundAt(x, z)) - (opts.sink or 0.3), O.z + z) * turn)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanCollide = not opts.soft
			d.CanQuery = not opts.soft
			d.CastShadow = scaled.Y >= 10
			if opts.paint and d:IsA("MeshPart") then
				d.TextureID = ""
				d.Material = Enum.Material.SmoothPlastic
				d.Reflectance = 0.1
				d.Color = opts.paint
			elseif opts.tint then
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

-- A Meshy model does not collide (its automatic hulls are poor): an unseen block of part of its box stands in for it.
local function solid(model: Model?, wide: number, tall: number, deep: number)
	if not model then
		return
	end
	local box, size = model:GetBoundingBox()
	local at = box * CFrame.new(0, -size.Y / 2 + size.Y * tall / 2, 0)
	local hull = block(model, "Hull", Vector3.new(size.X * wide, size.Y * tall, size.Z * deep), at, STONE)
	hull.Transparency = 1
	hull.CastShadow = false
end

local function light(model: Model?, up: number, range: number, brightness: number)
	if not model then
		return
	end
	local box, size = model:GetBoundingBox()
	local holder = block(model, "Glow", Vector3.one * 0.2, box * CFrame.new(0, size.Y * (up - 0.5), 0), TURQUOISE)
	holder.Transparency = 1
	holder.CanCollide = false
	holder.CanQuery = false
	local l = Instance.new("PointLight")
	l.Color = rgb(110, 240, 225)
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = holder
end

-- Local point at `r` studs from the Heart's middle along `angle` (0 east, a quarter turn south).
local function polar(angle: number, r: number): (number, number)
	return Heart.x + math.cos(angle) * r, Heart.z + math.sin(angle) * r
end
local function deg(d: number): number
	return d / 360 * TAU
end
local function apart(a: number, b: number): number
	return math.abs((a - b + math.pi) % TAU - math.pi)
end

-- The ways in and out, as angles from the middle: the three causeways and Crownfall's notch.
local gates = {}
local ways = { math.atan2(Heart.Fall.z - Heart.z, Heart.Fall.x - Heart.x) }
for _, site in Plan.Sites do
	if site.kind == "gate" then
		table.insert(gates, site)
		table.insert(ways, math.atan2(site.z - Heart.z, site.x - Heart.x))
	end
end
-- Angles already taken on a ring, so pieces scattered by chance keep clear of ways, spouts and ruins.
local function clear(angle: number, taken: { number }, margin: number): boolean
	for _, t in taken do
		if apart(angle, t) < margin then
			return false
		end
	end
	return true
end

---------------------------------------------------------------------------------------------------------------------
-- 1. The gates: each causeway's own gate where it cuts the rim, dressed in the land it comes from.
do
	local parent = folder("Gates")
	local DRESS = {
		gate_w = { { "PropKit", "GiantMushroom", 26, MUSHROOM }, { "PropKit", "GlowMushrooms", 12, MUSHROOM } },
		gate_e = { { "WildKit", "OwnMagmaCrystalCluster", 20 }, { "WildKit", "OwnStackedBasalt", 13 } },
		gate_n = { { "WildKit", "OwnIceCrystalSpire", 24 }, { "WildKit", "OwnIceCrystalCluster", 10 } },
	}
	local OWN = { gate_w = "RootGate", gate_e = "EmberGate", gate_n = "FrostGate" }
	for _, site in gates do
		local dx, dz = Heart.x - site.x, Heart.z - site.z
		local l = math.sqrt(dx * dx + dz * dz)
		dx, dz = dx / l, dz / l
		-- The gate's front, the lantern side, looks down the causeway. The mesh does not collide: its automatic hulls
		-- left a passage one character wide (measured). Two unseen pillars stand in the legs and leave the middle 14
		-- studs free. The Root and Frost Gates' files face the other way round from the Ember Gate's.
		local f = if site.id == "gate_e" then 1 else -1
		put(parent, "WorldKit", OWN[site.id], site.x, site.z, 42, { dx * f, dz * f }, { name = site.name, sink = 1.5, soft = true })
		for side = -1, 1, 2 do
			local x, z = site.x - dz * side * 14.5, site.z + dx * side * 14.5
			local at = Vector3.new(O.x + x, groundAt(site.x, site.z) + 15, O.z + z)
			block(parent, "GateLeg", Vector3.new(15, 30, 16), CFrame.lookAt(at, at + Vector3.new(dx, 0, dz)), STONE).Transparency = 1
		end
		for side = -1, 1, 2 do
			for i, piece in DRESS[site.id] do
				local out, across = 26 + i * 14, side * (13 + i * 3)
				put(parent, piece[1], piece[2], site.x - dx * out - dz * across, site.z - dz * out + dx * across, piece[3], { dx, dz }, { tint = piece[4], sink = 0.8 })
			end
			put(parent, "PropKit", "TorchSconce", site.x - dx * 20 - dz * side * 9, site.z - dz * 20 + dx * side * 9, 13, { dx, dz })
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 2. The causeways: kerbs and crystal lanterns along both edges over the lake, a pair of guardians where each one
-- lands on the island.
do
	local parent = folder("Causeways")
	for _, site in gates do
		local angle = math.atan2(site.z - Heart.z, site.x - Heart.x)
		local ox, oz = math.cos(angle), math.sin(angle) -- out, from the middle to the gate
		for side = -1, 1, 2 do
			local ax, az = -oz * side * 9.6, ox * side * 9.6
			for r = Heart.LakeInner + 6, Heart.LakeOuter - 2, 8.5 do
				local x, z = Heart.x + ox * r + ax, Heart.z + oz * r + az
				local y = groundAt(x, z)
				if y > FLOOR - 1.5 then
					local lamp = (r - Heart.LakeInner - 6) % 34 < 8.5
					local at = Vector3.new(O.x + x, y, O.z + z)
					local face = CFrame.lookAt(at, at + Vector3.new(ox, 0, oz))
					if lamp then
						block(parent, "KerbPost", Vector3.new(3, 2.4, 3), face * CFrame.new(0, 0.9, 0), STONE_DARK, nil, true)
						local lantern = put(parent, "WorldKit", "CrystalLantern", x, z, 11, { -oz * -side, ox * -side }, { y = y + 2.1, sink = 0, soft = true })
						light(lantern, 0.72, 18, 0.9)
					else
						block(parent, "Kerb", Vector3.new(1.8, 1.5, 7), face * CFrame.new(0, 0.45, 0), if (r // 8.5) % 2 == 0 then STONE else STONE_PALE, nil, true)
					end
				end
			end
			-- where it lands: a crowned guardian each side, looking at who comes
			local gx, gz = Heart.x + ox * (Heart.LakeInner - 13) - oz * side * 21, Heart.z + oz * (Heart.LakeInner - 13) + ox * side * 21
			solid(put(parent, "WorldKit", "HeartGuardian", gx, gz, 28, { ox, oz }, { soft = true, sink = 0.6 }), 0.8, 0.9, 0.8)
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 3. The Crown: the shrine at the island's north end, looking south over the arena, a guardian and crystals at each
-- side.
do
	local parent = folder("Crown")
	local shrine = put(parent, "WorldKit", "CrownShrine", Heart.x, Heart.z - 98, 104, { 0, 1 }, { soft = true, sink = 1.2 })
	solid(shrine, 0.78, 0.5, 0.74)
	light(shrine, 0.8, 60, 1.2)
	-- (No spire on the roof: the owner did not like a giant crystal over a roof that has its own crystals, 2026-11-14.)
	for side = -1, 1, 2 do
		solid(put(parent, "WorldKit", "HeartGuardian", Heart.x + side * 68, Heart.z - 58, 40, { -side * 0.35, 1 }, { soft = true, sink = 0.8, name = "CrownGuardian" }), 0.8, 0.9, 0.8)
		put(parent, "PropKit", "CrystalCluster", Heart.x + side * 84, Heart.z - 100, 36, nil, { paint = TURQUOISE, sink = 1.5 })
		put(parent, "WildKit", "OwnCrystalBlue", Heart.x + side * 66, Heart.z - 118, 22, nil, { paint = TURQUOISE, sink = 1 })
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 4. The arena: a floor of stone rings round the middle, and rune stones standing round it, open at every way in.
do
	local parent = folder("Arena")
	-- A tenth of a stud over the land: the zone fight stands its fighters on the TERRAIN (ZoneGuards.ground), so a
	-- thicker floor would swallow their feet and whatever the fight draws on the ground.
	local top = FLOOR + 0.1
	local cx, cz = O.x + Heart.x, O.z + Heart.z
	local function ring(name: string, r0: number, r1: number, n: number, colour: Color3, lift: number)
		local length = 2 * r1 * math.tan(math.pi / n) + 0.05
		for i = 0, n - 1 do
			local a = (i + 0.5) / n * TAU
			local rm = (r0 + r1) / 2
			-- every other slab a hair higher, so where they overlap one is plainly on top
			local y = top - 0.15 + lift + (i % 2) * 0.02
			local at = Vector3.new(cx + math.cos(a) * rm, y, cz + math.sin(a) * rm)
			local shade = if colour == STONE and i % 2 == 1 then STONE_PALE else colour -- paving: slab by slab
			block(parent, name, Vector3.new(length, 0.3, r1 - r0), CFrame.lookAt(at, Vector3.new(cx, y, cz)), shade, nil, true)
		end
		task.wait()
	end
	ring("Slab", PICTURE - 1, ARENA - 3, 32, STONE, 0)
	ring("Rim", ARENA - 3, ARENA, 36, GOLD, 0.06)
	-- The middle is one picture (a paved disc with the crowned slime's crest), on a plain stone disc that shows until
	-- the picture has loaded. Its crown points north, at the shrine.
	local disc = block(parent, "Middle", Vector3.new(0.3, PICTURE * 2, PICTURE * 2), CFrame.new(cx, top - 0.2, cz) * CFrame.Angles(0, 0, math.pi / 2), STONE)
	disc.Shape = Enum.PartType.Cylinder
	local face = block(parent, "Medallion", Vector3.new(PICTURE * 2, 0.1, PICTURE * 2), CFrame.new(cx, top - 0.05, cz) * CFrame.Angles(0, MEDALLION_TURN, 0), STONE)
	face.Transparency = 1
	face.CanCollide = false
	face.CanQuery = false
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = MEDALLION
	decal.Parent = face

	-- Rune stones: three between each pair of ways, the outer two a little off the way itself. The north belongs to the
	-- Crown, so the two stones that would flank it are left out.
	local sorted = table.clone(ways)
	table.sort(sorted)
	local north = deg(270)
	for i, from in sorted do
		local to = sorted[i % #sorted + 1]
		local span = (to - from) % TAU
		for _, t in { 17, -17, 0 } do
			local a = if t > 0 then from + deg(t) elseif t < 0 then to + deg(t) else from + span / 2
			if apart(a, north) > deg(40) then
				local x, z = polar(a, ARENA + 13)
				solid(put(parent, "WorldKit", "RuneStone", x, z, 22, { -math.cos(a), -math.sin(a) }, { soft = true, sink = 0.4 }), 0.75, 0.8, 0.75)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 5. The island: crystals and boulders on its shore, flowers, bushes and a few trees in its meadows. Paths, the arena
-- and the Crown stay clear.
do
	local parent = folder("Island")
	local function free(x: number, z: number): boolean
		local dx, dz = x - Heart.x, z - Heart.z
		local r = math.sqrt(dx * dx + dz * dz)
		if r < ARENA + 22 then
			return false
		end
		if math.abs(dx) < 100 and dz < -36 then -- the Crown and its guardians
			return false
		end
		for _, way in ways do
			if apart(math.atan2(dz, dx), way) < math.asin(math.min(1, 17 / r)) then
				return false
			end
		end
		return true
	end
	local CRYSTALS = { { "PropKit", "CrystalCluster", 14, 24 }, { "WildKit", "OwnCrystalPaleBlue", 12, 20 }, { "WildKit", "OwnCrystalBlue", 9, 14 } }
	local ROCKS = { { "OwnerKit", "FlatBoulder", 4, 6 }, { "OwnerKit", "StackedRocks", 6, 10 }, { "WildKit", "OwnMossyRockStack", 7, 11 }, { "OwnerKit", "WideBoulder", 4, 7 } }
	for i = 1, 22 do
		local a = i / 22 * TAU + rng:NextNumber(-0.06, 0.06)
		local x, z = polar(a, Heart.LakeInner - rng:NextNumber(3, 9))
		if free(x, z) then
			if i % 2 == 0 then
				local c = CRYSTALS[rng:NextInteger(1, #CRYSTALS)]
				put(parent, c[1], c[2], x, z, rng:NextNumber(c[3], c[4]), nil, { paint = TURQUOISE, sink = 1.2 })
			else
				local c = ROCKS[rng:NextInteger(1, #ROCKS)]
				local rx, rz = polar(a, Heart.LakeInner + rng:NextNumber(0, 5))
				put(parent, c[1], c[2], rx, rz, rng:NextNumber(c[3], c[4]), nil, { y = FLOOR - 1, sink = 1.2 })
			end
		end
	end
	local TREES = { { "QtTwistedTree_1_Purple", 36, 46 }, { "QtCommonTree_1_Teal", 36, 46 }, { "QtCommonTree_3_Teal", 40, 52 }, { "QtTwistedTree_3_Purple", 34, 44 } }
	for i = 1, 14 do
		local a = i / 14 * TAU + 0.2
		local x, z = polar(a, rng:NextNumber(106, 138))
		if free(x, z) then
			local t = TREES[i % #TREES + 1]
			put(parent, "WildKit", t[1], x, z, rng:NextNumber(t[2], t[3]), nil, { soft = true, sink = 0.6 })
		end
	end
	-- Flower beds: a flowering bush with a drift of one kind of flower round it. One ring of beds hugs the rune stones,
	-- the rest lie over the meadows.
	local FLOWERS = { { "WildKit", "DokiFlower1", 4.6 }, { "WildKit", "DokiFlower2", 4.6 }, { "WildKit", "DokiFlower3", 5.4 }, { "WildKit", "DokiFlower4", 6 }, { "WildKit", "QtFlower_3_Group", 4.2 }, { "WildKit", "QtFlower_4_Group", 4.2 }, { "KitCache", "flower_daisies", 5.5 } }
	local BUSHES = { { "KitCache", "bush_flower_pink", 7.5 }, { "WildKit", "YasuBush01", 8 }, { "KitCache", "bush_flower_pink", 6 }, { "NatureKit", "FloweringBush", 6.5 }, { "WildKit", "YasuBush03", 6 } }
	local function bed(mx: number, mz: number, i: number)
		if not free(mx, mz) then
			return
		end
		local bush = BUSHES[i % #BUSHES + 1]
		put(parent, bush[1], bush[2], mx, mz, bush[3] * rng:NextNumber(0.9, 1.2), nil, { soft = true, sink = 0.5 })
		local kind = FLOWERS[i % #FLOWERS + 1]
		for k = 1, 6 do
			local a, r = k / 6 * TAU + rng:NextNumber(-0.3, 0.3), rng:NextNumber(5.5, 11)
			put(parent, kind[1], kind[2], mx + math.cos(a) * r, mz + math.sin(a) * r, kind[3] * rng:NextNumber(0.85, 1.2), nil, { soft = true, sink = 0.15 })
		end
	end
	for i = 1, 20 do
		local x, z = polar((i + 0.5) / 20 * TAU, ARENA + rng:NextNumber(27, 34))
		bed(x, z, i)
	end
	for i = 1, 22 do
		local x, z = polar(i / 22 * TAU + rng:NextNumber(-0.08, 0.08), rng:NextNumber(ARENA + 48, Heart.LakeInner - 16))
		bed(x, z, i + 3)
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 6. The lake: crystal islets, lily pads by both shores.
do
	local parent = folder("Lake")
	for i = 1, 9 do
		local a = i / 9 * TAU + 0.26
		if clear(a, ways, deg(11)) then
			local r = rng:NextNumber(Heart.LakeInner + 46, Heart.LakeOuter - 44)
			local x, z = polar(a, r)
			put(parent, "OwnerKit", "WideBoulder", x, z, 7, nil, { y = LAKE - 4.2, sink = 0, wide = false, name = "Islet" })
			put(parent, "PropKit", "CrystalCluster", x, z, rng:NextNumber(24, 36), nil, { paint = TURQUOISE, y = LAKE - 2.5, sink = 0 })
			for k = 1, 2 do
				local a2 = k * 2.4 + i
				put(parent, "WildKit", "OwnCrystalBlue", x + math.cos(a2) * 11, z + math.sin(a2) * 11, rng:NextNumber(10, 16), nil, { paint = TURQUOISE, y = LAKE - 2, sink = 0 })
				put(parent, "OwnerKit", "FlatBoulder", x + math.cos(a2 + 1.3) * 12, z + math.sin(a2 + 1.3) * 12, 5, nil, { y = LAKE - 2.4, sink = 0, name = "IsletRock" })
			end
		end
	end
	for i = 1, 40 do
		local a = i / 40 * TAU + rng:NextNumber(-0.06, 0.06)
		local r = if i % 2 == 0 then rng:NextNumber(Heart.LakeInner + 8, Heart.LakeInner + 26) else rng:NextNumber(Heart.LakeOuter - 24, Heart.LakeOuter - 8)
		if clear(a, ways, deg(if r > 200 then 8 else 12)) then
			local x, z = polar(a, r)
			if groundAt(x, z) < LAKE - 1 then
				put(parent, "KitCache", "flower_lily_pads", x, z, rng:NextNumber(8, 12), nil, { wide = true, y = LAKE - 0.25, sink = 0, soft = true })
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 7. The far shore, under the rim: four slime-head spouts pouring into the lake, ruined colonnades, crystals growing
-- out of the rock, and trees, bushes and flowers between them.
local shoreTaken = table.clone(ways)
do
	local parent = folder("Shore")
	local band = Heart.LakeOuter + 12 -- the middle of the flat strip between the water and the rock
	for _, d in { 45, 135, 225, 315 } do
		local a = deg(d)
		table.insert(shoreTaken, a)
		local ix, iz = -math.cos(a), -math.sin(a) -- in, toward the lake
		-- It sits at the water's edge, its front on the sand, so the water drops straight into the lake.
		local x, z = polar(a, Heart.LakeOuter + 17)
		local fx, fz = polar(a, Heart.LakeOuter + 1)
		local foot = math.max(groundAt(fx, fz), LAKE) - 1
		local spout = put(parent, "WorldKit", "SlimeSpout", x, z, 38, { ix, iz }, { y = foot, sink = 0, soft = true })
		solid(spout, 0.8, 0.8, 0.8)
		-- The water comes from INSIDE the mouth (the owner, 2026-11-14): it wells up at the back of the throat, runs
		-- over the tongue to the lower lip, and falls from the lip into the lake. The places are read off the model's
		-- own side profile at 38 studs tall: the mouth's floor is 16-18 up, its back wall 3 in front of the middle,
		-- the lip's edge 17 in front.
		local inward = Vector3.new(ix, 0, iz)
		local across = Vector3.new(-iz, 0, ix)
		local middle = Vector3.new(O.x + x, foot, O.z + z)
		local throat = middle + inward * 3.6 + Vector3.new(0, 18.8, 0)
		local lip = middle + inward * 17.2 + Vector3.new(0, 17, 0)
		local land = Vector3.new(O.x + x + ix * 30, LAKE + 0.2, O.z + z + iz * 30)
		local holder = block(parent, "SpoutWater", Vector3.one * 0.2, CFrame.new(lip), WATER)
		holder.Transparency = 1
		holder.CanCollide = false
		holder.CanQuery = false
		-- (an Attachment's World* properties mean nothing until it has a parent: parent first)
		local function at(position: Vector3, axis: Vector3): Attachment
			local a = Instance.new("Attachment")
			a.Parent = holder
			a.WorldPosition = position
			a.WorldAxis = axis
			a.WorldSecondaryAxis = across
			return a
		end
		local function pour(a0: Attachment, a1: Attachment, curve0: number, curve1: number, wide0: number, wide1: number, wells: boolean?)
			for layer = 1, 2 do
				local b = Instance.new("Beam")
				b.Name = if layer == 1 then "Sheet" else "Streaks"
				b.Attachment0 = a0
				b.Attachment1 = a1
				b.FaceCamera = false
				b.Segments = 12
				b.CurveSize0 = curve0
				b.CurveSize1 = curve1
				b.Width0 = if layer == 1 then wide0 else wide0 + 0.6
				b.Width1 = if layer == 1 then wide1 else wide1 + 0.6
				b.Color = ColorSequence.new(if layer == 1 then WATER else FOAM)
				local thin = if layer == 1 then 0.25 else 0.1
				-- (welling up out of the dark throat: no hard edge where the sheet begins)
				b.Transparency = if wells then NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, thin), NumberSequenceKeypoint.new(1, thin) }) else NumberSequence.new(thin)
				b.LightEmission = 0.4 -- as bright as the lake it falls into
				b.LightInfluence = 0.8
				if layer == 2 then
					b.Texture = STREAKS
					b.TextureMode = Enum.TextureMode.Wrap
					b.TextureLength = 7
					b.TextureSpeed = 1.3
					b.ZOffset = 0.3
				end
				b.Parent = holder
			end
		end
		local edge = at(lip, inward)
		pour(at(throat, (lip - throat).Unit), edge, 0, 0, 9, 10, true) -- over the tongue
		pour(edge, at(land, Vector3.new(0, -1, 0)), 7, 9, 10, 12) -- off the lip, down into the lake
		for i = 1, 4 do
			local foam = block(parent, "Foam", Vector3.one * rng:NextNumber(4, 6.5), CFrame.new(land + across * (i - 2.5) * 3.4 + Vector3.new(ix, 0, iz) * rng:NextNumber(-2, 3) - Vector3.new(0, 1.5, 0)), FOAM, Enum.Material.SmoothPlastic)
			foam.Shape = Enum.PartType.Ball
			foam.CanCollide = false
			foam.CastShadow = false
		end
	end
	for _, d in { 21, 68, 112, 158, 247, 292 } do
		local a = deg(d)
		table.insert(shoreTaken, a)
		local x, z = polar(a, band + 4)
		solid(put(parent, "WorldKit", "RuinColonnade", x, z, 24, { -math.cos(a), -math.sin(a) }, { soft = true, sink = 0.7 }), 0.9, 0.7, 0.5)
	end
	-- crystals growing out of the rock above the strip
	for i = 1, 14 do
		local a = i / 14 * TAU + 0.5
		if clear(a, ways, deg(9)) and clear(a, shoreTaken, deg(6)) then
			local x, z = polar(a, band + 26)
			put(parent, "PropKit", "CrystalCluster", x, z, rng:NextNumber(34, 50), nil, { paint = TURQUOISE, sink = 5, name = "RimCrystal" })
		end
	end
	-- Trees in two rows: one near the water, between the spouts and the ruins, one up the slope under the rock.
	local TREES = { { "QtTwistedTree_1_Purple", 38, 50 }, { "QtCommonTree_1_Teal", 38, 50 }, { "QtCommonTree_3_Teal", 42, 56 }, { "QtTwistedTree_3_Purple", 36, 46 }, { "QtCommonTree_5_Teal", 34, 44 }, { "QtCommonTree_3_Purple", 38, 50 } }
	for i = 1, 52 do
		local a = i / 52 * TAU + rng:NextNumber(-0.03, 0.03)
		if clear(a, shoreTaken, deg(6.5)) then
			local x, z = polar(a, band + rng:NextNumber(-3, 6))
			local t = TREES[i % #TREES + 1]
			put(parent, "WildKit", t[1], x, z, rng:NextNumber(t[2], t[3]), nil, { soft = true, sink = 0.6 })
		end
	end
	for i = 1, 40 do
		local a = (i + 0.5) / 40 * TAU + rng:NextNumber(-0.04, 0.04)
		if clear(a, ways, deg(8)) then
			local x, z = polar(a, band + rng:NextNumber(16, 30))
			local t = TREES[(i + 2) % #TREES + 1]
			put(parent, "WildKit", t[1], x, z, rng:NextNumber(t[2], t[3]), nil, { soft = true, sink = 1 })
		end
	end
	-- Flowering bushes and drifts of flowers along the strip, thickest by the water.
	local SMALL = { { "KitCache", "bush_flower_pink", 8 }, { "WildKit", "YasuBush01", 9 }, { "WildKit", "DokiFlower3", 5.4 }, { "KitCache", "flower_daisies", 6 }, { "KitCache", "bush_flower_pink", 6.5 }, { "WildKit", "DokiFlower4", 6 }, { "WildKit", "YasuBush02", 8 }, { "WildKit", "DokiFlower1", 4.6 } }
	for i = 1, 150 do
		local a = i / 150 * TAU + rng:NextNumber(-0.015, 0.015)
		if clear(a, ways, deg(5.5)) then
			local x, z = polar(a, band + (if i % 3 == 0 then rng:NextNumber(8, 24) else rng:NextNumber(-10, 4)))
			local s = SMALL[i % #SMALL + 1]
			if groundAt(x, z) > LAKE + 2 then
				put(parent, s[1], s[2], x, z, s[3] * rng:NextNumber(0.85, 1.2), nil, { soft = true, sink = 0.3 })
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- 8. Crownfall: the lake's water down the south cliff into the river's first pool: sheets laid on the cliff's own
-- profile, streaks of white water running down them.
do
	local fall = Instance.new("Model")
	fall.Name = "Crownfall"
	local points = {}
	for z = Heart.Fall.z - 4, Heart.Pool.z - 8, 4 do
		local y = math.min(groundAt(Heart.Fall.x, z), LAKE)
		if #points == 0 or y < points[#points].Y - 0.5 or z >= Heart.Pool.z - 30 then
			table.insert(points, Vector3.new(O.x + Heart.Fall.x, math.max(y, 0) + 1.4, O.z + z + 1.5))
		end
	end
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local cf = CFrame.lookAt((a + b) / 2, b)
		local length = (b - a).Magnitude + 1.2
		local sheet = block(fall, "Water", Vector3.new(18, 1, length), cf, WATER, Enum.Material.SmoothPlastic)
		sheet.Transparency = 0.2
		sheet.CanCollide = false
		sheet.CastShadow = false
		-- (a beam's texture runs from Attachment0 to Attachment1: a0 at the sheet's upstream end, so the streaks fall;
		-- the other way round they climbed the cliff. A flat beam lays its width along its attachments' Y axis: Y
		-- across the sheet, or the streaks stood up off it as a wall; the owner, 2026-11-15)
		local along, across = Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)
		local a0 = Instance.new("Attachment")
		a0.CFrame = CFrame.fromMatrix(Vector3.new(0, 0.62, length / 2 - 0.6), along, across)
		a0.Parent = sheet
		local a1 = Instance.new("Attachment")
		a1.CFrame = CFrame.fromMatrix(Vector3.new(0, 0.62, -length / 2 + 0.6), along, across)
		a1.Parent = sheet
		local beam = Instance.new("Beam")
		beam.Name = "Streaks"
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.FaceCamera = false
		beam.Width0 = 18
		beam.Width1 = 18
		beam.Texture = STREAKS
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 9
		beam.TextureSpeed = 1.5
		beam.Color = ColorSequence.new(FOAM)
		beam.Transparency = NumberSequence.new(0.05)
		beam.LightEmission = 0.2
		beam.LightInfluence = 0.8
		beam.Parent = sheet
	end
	local foot = points[#points]
	for i = 1, 6 do
		local foam = block(fall, "Foam", Vector3.one * rng:NextNumber(6, 10), CFrame.new(foot.X + (i - 3.5) * 4.4, 0.4, foot.Z + rng:NextNumber(-3, 5)), FOAM, Enum.Material.SmoothPlastic)
		foam.Shape = Enum.PartType.Ball
		foam.CanCollide = false
		foam.CastShadow = false
	end
	fall.Parent = heart
end

heart.Parent = sites
local names = {}
for name in missing do
	table.insert(names, name)
end
local parts, lights, beams = 0, 0, 0
for _, d in heart:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	elseif d:IsA("PointLight") then
		lights += 1
	elseif d:IsA("Beam") then
		beams += 1
	end
end
return string.format("heart: %d kit pieces, %d parts, %d lights, %d beams; floor %.1f lake %.1f; missing: %s", count, parts, lights, beams, FLOOR, LAKE, table.concat(names, " "))
