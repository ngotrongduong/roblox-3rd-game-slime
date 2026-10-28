--!strict
-- The fishing pond's 50 levels (the owner, 2026-10-27, second pass): the dock keeps its size and only
-- grows in parts and in the quality of its materials. Five parts, each from its own level and never
-- taken away again:
--   1 the deck (planks and the posts under it)   2 rails along both sides   3 lamps at both ends
--   4 a bait box   5 bollards with rope at the far end (and light strips in the modern tiers)
-- Levels 1-5 add the parts one by one in the first tier (rustic wood). From level 6 on, every five
-- levels are a new material tier, and each level of the tier moves one part up to it, in the same
-- order: level 6 the deck, 7 the rails, 8 the lamps, 9 the box, 10 the bollards; and so on to marble
-- and gold at 50. No rods and no side platforms: the slimes carry their own rods and fish from spots
-- on the dock itself (invisible markers WorkSpot1..4 at its open far end, more as the tiers go up).
-- Used by AreaUpgrade.server.luau (the game) and tools/map/build_pond_showcase.luau (the showcase).
local PondStages = {}

PondStages.MaxLevel = 50
-- the kit placer (PantryStages.place), handed over by PantryStages when it loads
PondStages.kitPlace = nil :: ((Instance, CFrame, string, number, number, number, number, number?) -> Model?)?

-- the dock, in the pond's frame: along +Z from the shore, the same size as the level-1 dock
local WIDTH = 6
local Z0, Z1 = -15, 4
local DECK_Y = 1.1

export type Tier = {
	name: string,
	planks: { Color3 },
	deck: Enum.Material,
	frame: Color3, -- posts, rail posts, lamp posts, bollards
	frameMat: Enum.Material,
	accent: Color3, -- rail tops, lamp caps, the box's lid and bands
	accentMat: Enum.Material,
	box: Color3,
	boxMat: Enum.Material,
	light: Color3,
	trim: Color3?, -- light strips along the deck's edges
}

local TIERS: { Tier } = {
	{
		name = "Rustic wood",
		planks = { Color3.fromRGB(205, 146, 82), Color3.fromRGB(170, 112, 58) },
		deck = Enum.Material.Wood,
		frame = Color3.fromRGB(120, 78, 44),
		frameMat = Enum.Material.Wood,
		accent = Color3.fromRGB(150, 98, 52),
		accentMat = Enum.Material.Wood,
		box = Color3.fromRGB(176, 120, 70),
		boxMat = Enum.Material.WoodPlanks,
		light = Color3.fromRGB(255, 200, 120),
	},
	{
		name = "Painted wood",
		planks = { Color3.fromRGB(245, 240, 228), Color3.fromRGB(226, 220, 206) },
		deck = Enum.Material.WoodPlanks,
		frame = Color3.fromRGB(70, 110, 160),
		frameMat = Enum.Material.WoodPlanks,
		accent = Color3.fromRGB(245, 240, 228),
		accentMat = Enum.Material.WoodPlanks,
		box = Color3.fromRGB(110, 160, 210),
		boxMat = Enum.Material.WoodPlanks,
		light = Color3.fromRGB(255, 210, 140),
	},
	{
		name = "Stone and timber",
		planks = { Color3.fromRGB(150, 100, 60), Color3.fromRGB(128, 84, 50) },
		deck = Enum.Material.Wood,
		frame = Color3.fromRGB(160, 156, 148),
		frameMat = Enum.Material.Slate,
		accent = Color3.fromRGB(120, 80, 48),
		accentMat = Enum.Material.Wood,
		box = Color3.fromRGB(140, 96, 58),
		boxMat = Enum.Material.Wood,
		light = Color3.fromRGB(255, 200, 120),
	},
	{
		name = "Brick village",
		planks = { Color3.fromRGB(176, 120, 76), Color3.fromRGB(156, 102, 64) },
		deck = Enum.Material.WoodPlanks,
		frame = Color3.fromRGB(176, 86, 64),
		frameMat = Enum.Material.Brick,
		accent = Color3.fromRGB(70, 66, 64),
		accentMat = Enum.Material.Metal,
		box = Color3.fromRGB(150, 100, 64),
		boxMat = Enum.Material.WoodPlanks,
		light = Color3.fromRGB(255, 196, 110),
	},
	{
		name = "Workshop",
		planks = { Color3.fromRGB(160, 112, 70), Color3.fromRGB(138, 96, 60) },
		deck = Enum.Material.Wood,
		frame = Color3.fromRGB(86, 88, 94),
		frameMat = Enum.Material.Metal,
		accent = Color3.fromRGB(180, 130, 60),
		accentMat = Enum.Material.Metal,
		box = Color3.fromRGB(96, 98, 104),
		boxMat = Enum.Material.DiamondPlate,
		light = Color3.fromRGB(255, 210, 150),
	},
	{
		name = "Glass house",
		planks = { Color3.fromRGB(240, 228, 206), Color3.fromRGB(226, 212, 188) },
		deck = Enum.Material.WoodPlanks,
		frame = Color3.fromRGB(244, 244, 244),
		frameMat = Enum.Material.SmoothPlastic,
		accent = Color3.fromRGB(190, 230, 250),
		accentMat = Enum.Material.Glass,
		box = Color3.fromRGB(236, 236, 236),
		boxMat = Enum.Material.SmoothPlastic,
		light = Color3.fromRGB(255, 240, 210),
	},
	{
		name = "Modern farm",
		planks = { Color3.fromRGB(150, 156, 164), Color3.fromRGB(132, 138, 146) },
		deck = Enum.Material.DiamondPlate,
		frame = Color3.fromRGB(70, 74, 80),
		frameMat = Enum.Material.Metal,
		accent = Color3.fromRGB(210, 214, 220),
		accentMat = Enum.Material.Metal,
		box = Color3.fromRGB(60, 120, 200),
		boxMat = Enum.Material.SmoothPlastic,
		light = Color3.fromRGB(255, 230, 170),
		trim = Color3.fromRGB(255, 220, 140),
	},
	{
		name = "Tech",
		planks = { Color3.fromRGB(70, 76, 90), Color3.fromRGB(58, 62, 74) },
		deck = Enum.Material.DiamondPlate,
		frame = Color3.fromRGB(40, 44, 54),
		frameMat = Enum.Material.Metal,
		accent = Color3.fromRGB(80, 200, 255),
		accentMat = Enum.Material.Neon,
		box = Color3.fromRGB(46, 50, 60),
		boxMat = Enum.Material.Metal,
		light = Color3.fromRGB(120, 210, 255),
		trim = Color3.fromRGB(80, 200, 255),
	},
	{
		name = "Slime tech",
		planks = { Color3.fromRGB(40, 92, 98), Color3.fromRGB(32, 74, 80) },
		deck = Enum.Material.DiamondPlate,
		frame = Color3.fromRGB(26, 54, 60),
		frameMat = Enum.Material.Metal,
		accent = Color3.fromRGB(120, 255, 150),
		accentMat = Enum.Material.Neon,
		box = Color3.fromRGB(60, 130, 120),
		boxMat = Enum.Material.Glass,
		light = Color3.fromRGB(140, 255, 170),
		trim = Color3.fromRGB(120, 255, 150),
	},
	{
		name = "Grand",
		planks = { Color3.fromRGB(248, 245, 240), Color3.fromRGB(230, 226, 218) },
		deck = Enum.Material.Marble,
		frame = Color3.fromRGB(240, 238, 232),
		frameMat = Enum.Material.Marble,
		accent = Color3.fromRGB(232, 190, 80),
		accentMat = Enum.Material.Foil,
		box = Color3.fromRGB(250, 248, 244),
		boxMat = Enum.Material.Marble,
		light = Color3.fromRGB(255, 220, 140),
		trim = Color3.fromRGB(255, 210, 90),
	},
}
PondStages.Tiers = TIERS

-- The classic stud look (the owner chose it for the whole plot): every built part is Plastic with
-- studs on top, and a tier shows in its colours. Glass, light (Neon), rope (Fabric) and soil
-- (Ground) keep their own material. Shared by AreaStages and PantryStages.
local KEEP = {
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.Fabric] = true,
	[Enum.Material.Ground] = true,
}
function PondStages.studLook(p: BasePart, material: Enum.Material?)
	if material and KEEP[material] then
		p.Material = material
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
	else
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Studs
		p.BottomSurface = Enum.SurfaceType.Inlet
	end
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	colour: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Anchored = true
	PondStages.studLook(p, material)
	if shape then
		p.Shape = shape
	end
	p.CastShadow = size.Magnitude > 4
	p.Parent = parent
	return p
end

-- an upright cylinder (Roblox cylinders run along X)
local function pole(
	parent: Instance,
	name: string,
	cf: CFrame,
	height: number,
	diameter: number,
	colour: Color3,
	material: Enum.Material?
): Part
	return part(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		cf * CFrame.Angles(0, 0, math.rad(90)),
		colour,
		material,
		Enum.PartType.Cylinder
	)
end

-- The tier name of a level (the tier its newest part reached).
function PondStages.tierName(level: number): string
	return TIERS[math.clamp(math.ceil(level / 5), 1, #TIERS)].name
end

-- Which tier each of the five parts is at on a level (0: not built yet).
function PondStages.parts(level: number): { number }
	local tier = math.clamp(math.ceil(level / 5), 1, #TIERS)
	local step = level - (tier - 1) * 5
	local out = {}
	for k = 1, 5 do
		if tier == 1 then
			out[k] = if k <= step then 1 else 0
		else
			out[k] = if k <= step then tier else tier - 1
		end
	end
	return out
end

-- The pond grows as well as the dock (the owner, 2026-10-28: "the fishing area is more than the dock;
-- the lawn round the pond may be used, and the pond may grow"), never smaller again: a lobe on its
-- left at 21 and one on its right at 41 (area-local x, z, radius, from which level), carved out of the
-- stud floor and filled with real water like the level-1 pond (tools/map/pond_water_l1).
local LOBES = { { 0, 5, 16 }, { 9, 11, 11 }, { -9, 2, 11 } }
local GROW = { { 15, 1, 7.5, 21 }, { -14, -5, 7, 41 } }
local DOCK_X = -3 -- the dock's line in the area (AreaUpgrade's DOCK_X)
local WATER_Y = -2.3 -- the water's surface in the area's frame
-- Life round the pond, growing each era and never taken away (kit model, x, z, real height, the
-- widest it may be, turn, from which level, lift): a bench on the bank; a rowboat moored by the
-- dock, a fishing hut and a net rack at the front; on the new left lobe a cooler; a water wheel at
-- its far edge; a glowing buoy in the right lobe, an auto reel on its bank and a small lighthouse
-- on the right bank behind it.
local SHORE: { { any } } = {
	{ "LogBench", 8.5, -13, 1.8, 4.6, 180, 1 },
	{ "RowBoat", -8.4, -7, 1.6, 4.8, 0, 11, WATER_Y - 0.4 },
	{ "FishingHut", 15.5, -17.5, 6.5, 7, 0, 11 },
	{ "NetRack", 20.5, -13, 2.6, 2.8, -90, 11 },
	{ "FishCooler", 18.6, -8.6, 2, 2, 0, 21 },
	{ "WaterWheel", 22.6, 2, 4.8, 4.8, 90, 31, -1.6 },
	{ "CrystalBuoy", -14.5, -3.5, 3, 1.4, 0, 41, WATER_Y - 0.8 },
	{ "AutoReel", -16, -13.5, 3.6, 3, 180, 41 },
	{ "Lighthouse", -21.5, 10, 10, 4.4, 0, 41 },
}

-- Grows the pond to `level` (its lobes from GROW, once each) and clears the scenery standing where
-- the water and the shore life come. `pond` is the area model, `frame` its frame at the ground's top.
function PondStages.grow(pond: Instance, frame: CFrame, level: number)
	local plot: Instance = pond.Parent or pond
	local lawn: Instance = plot:FindFirstChild("StudLawn") or pond
	local nature: Instance = pond:FindFirstChild("Nature") or pond
	for i, g in GROW do
		if level >= g[4] and not pond:GetAttribute("Lobe" .. i) then
			pond:SetAttribute("Lobe" .. i, true)
			local function dist(x: number, z: number): number
				local best = math.huge
				for _, l in LOBES do
					best = math.min(best, Vector2.new(x - l[1], z - l[2]).Magnitude - l[3])
				end
				for k = 1, i do
					local l = GROW[k]
					best = math.min(best, Vector2.new(x - l[1], z - l[2]).Magnitude - l[3])
				end
				return best
			end
			-- the floor's fine tiles: gone over the water, two sand steps at its bank
			local top = frame.Position.Y
			for _, t in lawn:GetChildren() do
				if t:IsA("BasePart") and t.Name == "Tile" and t.Size.X < 3 then
					local q = frame:PointToObjectSpace(t.Position)
					if Vector2.new(q.X - g[1], q.Z - g[2]).Magnitude < g[3] + 3 then
						local d = dist(q.X, q.Z)
						if d <= 0 then
							t:Destroy()
						elseif d < 2.4 then
							t.Color = Color3.fromRGB(232, 206, 142)
							local drop = if d < 1.2 then 1.6 else 0.8
							t.Position = Vector3.new(t.Position.X, top - drop - t.Size.Y / 2, t.Position.Z)
						end
					end
				end
			end
			-- real water, as the level-1 pond's lobes
			local terrain = workspace.Terrain
			local c = (frame * CFrame.new(g[1], 0, g[2])).Position
			local flat = CFrame.new(c.X, 0, c.Z)
			local surface = top - 0.3
			terrain:FillCylinder(flat + Vector3.new(0, surface - 8, 0), 4, g[3], Enum.Material.Sand)
			terrain:FillCylinder(flat + Vector3.new(0, surface - 3, 0), 6, g[3] + 1, Enum.Material.Air)
			terrain:FillCylinder(flat + Vector3.new(0, surface - 3, 0), 6, g[3] + 1, Enum.Material.Water)
		end
	end
	-- the scenery where water or shore life now is (the lilies stay, they float)
	for _, n in nature:GetChildren() do
		if n:IsA("Model") and n.Name ~= "WaterLily" then
			local q = frame:PointToObjectSpace(n:GetPivot().Position)
			local clear = false
			for _, g in GROW do
				if level >= g[4] and Vector2.new(q.X - g[1], q.Z - g[2]).Magnitude < g[3] + 2.5 then
					clear = true
				end
			end
			for _, s in SHORE do
				if level >= s[7] and Vector2.new(q.X - s[2], q.Z - s[3]).Magnitude < s[5] / 2 + 2 then
					clear = true
				end
			end
			if clear then
				n.Parent = nil
			end
		end
	end
end

-- how many slimes can fish at a level
local function spots(level: number): number
	if level >= 31 then
		return 4
	elseif level >= 21 then
		return 3
	elseif level >= 11 then
		return 2
	end
	return 1
end

-- The dock for one level, built along +Z from the pond's shore at `cell` (y = the ground's top).
-- showcase = true also lays a grass slab, painted water and a label (the floating showcase).
function PondStages.build(level: number, cell: CFrame, showcase: boolean?): Model
	local at = PondStages.parts(level)
	local m = Instance.new("Model")
	m.Name = "PondStage"
	m:SetAttribute("Level", level)

	if showcase then
		local slab = part(
			m,
			"Ground",
			Vector3.new(44, 2, 44),
			cell * CFrame.new(0, -1, -2),
			Color3.fromRGB(104, 178, 62),
			Enum.Material.Plastic
		)
		slab.TopSurface = Enum.SurfaceType.Studs
		local water = { Color3.fromRGB(96, 196, 235), Color3.fromRGB(56, 156, 222), Color3.fromRGB(34, 118, 204) }
		for t, r in { 15, 12.5, 9.5 } do
			local d = part(
				m,
				"Water",
				Vector3.new(0.1, r * 2, r * 2),
				cell * CFrame.new(0, 0.04 + t * 0.01, 2) * CFrame.Angles(0, 0, math.rad(90)),
				water[t],
				nil,
				Enum.PartType.Cylinder
			)
			d.CastShadow = false
		end
	end

	-- 1 the deck: planks across, two beams and posts down into the water
	local t = TIERS[at[1]]
	local i = 0
	local z = Z0
	while z < Z1 do
		i += 1
		part(
			m,
			"Plank",
			Vector3.new(WIDTH, 0.5, 1.4),
			cell * CFrame.new(0, DECK_Y, z + 0.7),
			t.planks[(i % 2) + 1],
			t.deck
		)
		z += 1.52
	end
	for _, s in { -1, 1 } do
		part(
			m,
			"Beam",
			Vector3.new(0.6, 0.6, Z1 - Z0),
			cell * CFrame.new(s * 2.2, DECK_Y - 0.55, (Z0 + Z1) / 2),
			t.frame,
			t.frameMat
		)
		for _, pz in { Z0 + 0.6, (Z0 + Z1) / 2, Z1 - 0.6 } do
			pole(m, "Post", cell * CFrame.new(s * (WIDTH / 2 - 0.4), DECK_Y - 2, pz), 4, 1, t.frame, t.frameMat)
		end
	end

	-- 2 rails along both sides, open over the last five studs where the slimes fish
	if at[2] > 0 then
		local r = TIERS[at[2]]
		local zr0, zr1 = Z0 + 0.6, Z1 - 5
		for _, s in { -1, 1 } do
			local x = s * (WIDTH / 2 - 0.3)
			for k = 0, 4 do
				local pz = zr0 + (zr1 - zr0) * k / 4
				part(
					m,
					"RailPost",
					Vector3.new(0.4, 1.8, 0.4),
					cell * CFrame.new(x, DECK_Y + 1.15, pz),
					r.frame,
					r.frameMat
				)
			end
			part(
				m,
				"Rail",
				Vector3.new(0.35, 0.3, zr1 - zr0 + 0.4),
				cell * CFrame.new(x, DECK_Y + 2.1, (zr0 + zr1) / 2),
				r.accent,
				r.accentMat
			)
			part(
				m,
				"RailLow",
				Vector3.new(0.25, 0.2, zr1 - zr0),
				cell * CFrame.new(x, DECK_Y + 1.1, (zr0 + zr1) / 2),
				r.frame,
				r.frameMat
			)
		end
	end

	-- 3 lamps at both ends of the dock
	if at[3] > 0 then
		local l = TIERS[at[3]]
		for _, pz in { Z0 + 0.4, Z1 - 5.2 } do
			for _, s in { -1, 1 } do
				local base = cell * CFrame.new(s * (WIDTH / 2 - 0.3), DECK_Y + 0.25, pz)
				pole(m, "LampPost", base * CFrame.new(0, 1.6, 0), 3.2, 0.35, l.frame, l.frameMat)
				local head = part(
					m,
					"Lamp",
					Vector3.new(0.7, 0.8, 0.7),
					base * CFrame.new(0, 3.55, 0),
					l.light,
					Enum.Material.Neon
				)
				head.CastShadow = false
				part(m, "LampCap", Vector3.new(0.95, 0.25, 0.95), base * CFrame.new(0, 4.05, 0), l.accent, l.accentMat)
				local light = Instance.new("PointLight")
				light.Color = l.light
				light.Range = 9
				light.Brightness = 0.8
				light.Parent = head
			end
		end
	end

	-- 4 a bait box by the shore end of the deck
	if at[4] > 0 then
		local b = TIERS[at[4]]
		local base = cell * CFrame.new(1.4, DECK_Y + 0.25, Z0 + 3)
		part(m, "BaitBox", Vector3.new(1.8, 1, 1.2), base * CFrame.new(0, 0.5, 0), b.box, b.boxMat)
		part(m, "BaitLid", Vector3.new(1.95, 0.2, 1.35), base * CFrame.new(0, 1.1, 0), b.accent, b.accentMat)
		for _, dx in { -0.6, 0.6 } do
			part(m, "BaitBand", Vector3.new(0.15, 1.02, 1.25), base * CFrame.new(dx, 0.5, 0), b.accent, b.accentMat)
		end
	end

	-- 5 bollards with rope at the far end, and light strips in the modern tiers
	if at[5] > 0 then
		local o = TIERS[at[5]]
		for _, s in { -1, 1 } do
			local base = cell * CFrame.new(s * (WIDTH / 2 - 0.5), DECK_Y + 0.25, Z1 - 0.5)
			pole(m, "Bollard", base * CFrame.new(0, 0.5, 0), 1, 0.7, o.frame, o.frameMat)
			pole(m, "BollardCap", base * CFrame.new(0, 1.05, 0), 0.2, 0.9, o.accent, o.accentMat)
			pole(
				m,
				"Rope",
				base * CFrame.new(0, 0.55, 0),
				0.3,
				0.85,
				Color3.fromRGB(226, 196, 140),
				Enum.Material.Fabric
			)
		end
		local trim = o.trim
		if trim then
			for _, s in { -1, 1 } do
				local strip = part(
					m,
					"Trim",
					Vector3.new(0.15, 0.15, Z1 - Z0),
					cell * CFrame.new(s * (WIDTH / 2 + 0.02), DECK_Y, (Z0 + Z1) / 2),
					trim,
					Enum.Material.Neon
				)
				strip.CastShadow = false
			end
		end
	end

	-- the work spots: invisible markers on the dock's open far end (no side platforms)
	local SPOTS = {
		Vector3.new(-1.3, 0, Z1 - 1.2),
		Vector3.new(1.3, 0, Z1 - 1.2),
		Vector3.new(-1.6, 0, Z1 - 3.6),
		Vector3.new(1.6, 0, Z1 - 3.6),
	}
	for k = 1, spots(level) do
		local p = SPOTS[k]
		local mark = part(
			m,
			"WorkSpot" .. k,
			Vector3.new(1.6, 0.2, 1.6),
			cell * CFrame.new(p.X, DECK_Y + 0.4, p.Z),
			Color3.new(1, 1, 1)
		)
		mark.Transparency = 1
		mark.CanCollide = false
	end

	-- the life round the pond (SHORE), in the area's frame (the dock's cell is DOCK_X along it); the
	-- kit placer is the pantry's, handed over by PantryStages (which requires this module)
	local area = cell * CFrame.new(-DOCK_X, 0, 0)
	local place = PondStages.kitPlace
	for _, s in SHORE do
		if place and level >= s[7] then
			local model = place(m, area, s[1], s[2], s[3], s[4], s[5], s[8])
			if model and s[6] ~= 0 then
				local box = model:GetBoundingBox()
				local centre = CFrame.new(box.Position)
				model:PivotTo(centre * CFrame.Angles(0, math.rad(s[6]), 0) * centre:ToObjectSpace(model:GetPivot()))
			end
		end
	end
	-- from 21 a small fishing jetty out into the new left lobe, in the dock's deck tier, two posts and
	-- a bollard at its end
	if level >= 21 then
		local j = TIERS[at[1]]
		local jx, jz0, jz1 = 15, -8.6, -3
		local k = 0
		local jz = jz0
		while jz < jz1 do
			k += 1
			part(
				m,
				"JettyPlank",
				Vector3.new(3, 0.5, 1.4),
				area * CFrame.new(jx, DECK_Y, jz + 0.7),
				j.planks[(k % 2) + 1],
				j.deck
			)
			jz += 1.52
		end
		for _, s in { -1, 1 } do
			pole(m, "JettyPost", area * CFrame.new(jx + s * 1.2, DECK_Y - 2, jz1 - 0.6), 4, 0.7, j.frame, j.frameMat)
		end
		pole(m, "JettyBollard", area * CFrame.new(jx + 1, DECK_Y + 0.75, jz1 - 0.5), 1, 0.6, j.frame, j.frameMat)
	end

	if showcase then
		local tag = part(m, "Label", Vector3.new(14, 3, 0.4), cell * CFrame.new(0, 9, -24), Color3.new(1, 1, 1))
		tag.Transparency = 1
		tag.CanCollide = false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(560, 120)
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.Font = Enum.Font.FredokaOne
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0.3
		text.Text = string.format("Level %d · %s", level, PondStages.tierName(level))
		text.Parent = gui
		gui.Parent = tag
	end
	return m
end

return PondStages
