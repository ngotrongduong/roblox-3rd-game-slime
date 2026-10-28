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
-- dock and a net rack by the fishing shed; a cooler by the jetty on the new left lobe; a glowing buoy
-- in the right lobe and an auto reel at the fishing spot on its bank. (The shed, the paths, the
-- fishing spot, the back bank and the beacon are built from parts in `build`.)
local SHORE: { { any } } = {
	{ "LogBench", 8.5, -12, 1.8, 4.6, 180, 1 },
	{ "RowBoat", -9, -5.6, 1.6, 4.8, 30, 11, WATER_Y - 0.4 },
	{ "NetRack", 20.6, -17.6, 2.6, 2.8, 180, 11 },
	{ "FishCooler", 18.6, -8.6, 2, 2, 0, 21 },
	{ "CrystalBuoy", -14.5, -3.5, 3, 1.4, 0, 41, WATER_Y - 0.8 },
	{ "AutoReel", -16.6, -12.6, 4.4, 3.6, 180, 41 },
}

-- room kept clear of scenery for what `build` makes from parts (x, z, radius, from which level)
local CLEAR = {
	{ 16.2, -19.2, 5.5, 11 },
	{ 8, -15, 6, 11 },
	{ 15.5, -12, 2.5, 21 },
	{ -12.6, -12, 2.5, 1 },
	{ -14, -14.6, 2.5, 41 },
	{ -21.5, 10, 3, 41 },
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
			for _, c in CLEAR do
				if level >= c[4] and Vector2.new(q.X - c[1], q.Z - c[2]).Magnitude < c[3] then
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
					-- (along the fishing end only: the whole length outshone the pond; ChatGPT's 1st review)
					Vector3.new(0.15, 0.15, 6),
					cell * CFrame.new(s * (WIDTH / 2 + 0.02), DECK_Y, Z1 - 3),
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
		local jx, jz0, jz1 = 15, -8.6, 0.4 -- (8 studs out: a real second fishing spot)
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
			for _, pz in { jz1 - 0.6, (jz0 + jz1) / 2 } do
				pole(m, "JettyPost", area * CFrame.new(jx + s * 1.2, DECK_Y - 2, pz), 4, 0.7, j.frame, j.frameMat)
			end
		end
		pole(m, "JettyBollard", area * CFrame.new(jx + 1, DECK_Y + 0.75, jz1 - 0.5), 1, 0.6, j.frame, j.frameMat)
	end

	-- The working banks (ChatGPT's 1st pond review): a plank path from the entrance along the front-left
	-- bank to the fishing shed and, from 21, on to the jetty; an open fishing shed at the path's end; a
	-- small fishing spot on the near-right bank from the start (a stool, a two-rod holder over the water,
	-- a bait bucket), moved to the new right lobe's bank at 41; reeds, stones and a half-sunk log on the
	-- back bank from 31; the rowboat tied to the dock with oars in it; a pond beacon on the back-right
	-- bank at 41.
	local wood, woodMat = Color3.fromRGB(176, 128, 84), Enum.Material.Wood
	local dark = Color3.fromRGB(110, 76, 48)
	local rope = Color3.fromRGB(226, 196, 140)
	local function at2(px: number, py: number, pz: number): CFrame
		return area * CFrame.new(px, py, pz)
	end
	local function plankRun(name: string, x0: number, z0: number, x1: number, z1: number, w: number)
		local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
		local len = (b - a).Magnitude
		local dir = (b - a).Unit
		local n = math.max(1, math.floor(len / 1.1))
		for k = 0, n - 1 do
			local p = a + dir * (len * (k + 0.5) / n)
			part(
				m,
				name,
				Vector3.new(w, 0.12, 0.95),
				at2(p.X, 0.06, p.Z) * CFrame.lookAt(Vector3.zero, dir),
				if k % 2 == 0 then wood else Color3.fromRGB(196, 146, 96),
				woodMat
			).CastShadow =
				false
		end
	end
	if level >= 11 then
		plankRun("BankPath", -0.6, -15.4, 13, -15.4, 2.6)
		-- the open fishing shed, turned toward the entrance so its open front, counter and net face the
		-- path and the way in (ChatGPT's 2nd pond review): four posts, a roof sloping to the back, a
		-- back wall, a bait counter at the front with fish on it, a net hung inside, a rod by a post
		local shed = area * CFrame.new(16.2, 0, -19.2) * CFrame.Angles(0, math.rad(35), 0) -- its -z: the front
		local function sh(px: number, py: number, pz: number): CFrame
			return shed * CFrame.new(px, py, pz)
		end
		local hw, hd = 3.4, 2.3
		for _, cx in { -hw, hw } do
			for _, cz in { -hd, hd } do
				local h = if cz < 0 then 6.6 else 5.6 -- (high over the open front)
				part(m, "ShedPost", Vector3.new(0.6, h, 0.6), sh(cx, h / 2, cz), dark, woodMat)
			end
		end
		part(
			m,
			"ShedRoof",
			Vector3.new(hw * 2 + 1.4, 0.4, hd * 2 + 1.8),
			sh(0, 6.35, 0) * CFrame.Angles(math.atan2(1, hd * 2), 0, 0),
			Color3.fromRGB(196, 96, 64),
			woodMat
		)
		part(m, "ShedBack", Vector3.new(hw * 2, 5, 0.3), sh(0, 2.5, hd), wood, woodMat)
		part(m, "Counter", Vector3.new(hw * 2 - 0.6, 0.35, 1.2), sh(0, 2.6, -hd + 0.7), wood, woodMat)
		part(m, "CounterFront", Vector3.new(hw * 2 - 0.6, 2.3, 0.2), sh(0, 1.3, -hd + 0.15), wood, woodMat)
		for k, dx in { -1.6, 0.2 } do
			local fish = part(
				m,
				"FishOnCounter",
				Vector3.new(1.2, 0.4, 0.5),
				sh(dx, 2.98, -hd + 0.7) * CFrame.Angles(0, k * 0.3, 0),
				if k == 1 then Color3.fromRGB(110, 170, 210) else Color3.fromRGB(240, 150, 90)
			) :: Part
			fish.Shape = Enum.PartType.Ball
		end
		part(m, "Board", Vector3.new(1.2, 0.15, 0.8), sh(1.8, 2.85, -hd + 0.7), Color3.fromRGB(214, 176, 124), woodMat)
		part(
			m,
			"HungNet",
			Vector3.new(2.8, 2.2, 0.1),
			sh(0, 4, hd - 0.25),
			Color3.fromRGB(230, 220, 190),
			Enum.Material.Fabric
		).Transparency =
			0.3
		part(
			m,
			"ShedRod",
			Vector3.new(0.12, 5, 0.12),
			sh(hw - 0.4, 2.6, hd - 0.5) * CFrame.Angles(-0.15, 0, -0.15),
			dark,
			woodMat
		)
		-- the boat tied to the dock: a line from its bow to the dock's side, two oars in it
		part(
			m,
			"MooringLine",
			Vector3.new(0.1, 0.1, 2.6),
			at2(-6.9, WATER_Y + 0.9, -8.4) * CFrame.Angles(0.2, -0.7, 0),
			rope,
			Enum.Material.Fabric
		)
		for _, ox in { -0.35, 0.35 } do
			part(
				m,
				"Oar",
				Vector3.new(0.15, 0.1, 3.2),
				at2(-9 + ox, WATER_Y + 0.5, -5.6) * CFrame.Angles(0, math.rad(30) + ox * 0.3, 0),
				dark,
				woodMat
			)
		end
	end
	if level >= 21 then
		plankRun("BankPath", 13, -15.4, 15, -9.4, 2.6)
	end
	-- the near-right fishing spot: a stool, a rod holder with two rods leaning out over the water, lines
	-- and bobbers, a bait bucket; on the new right lobe's bank from 41 (where the auto reel joins it)
	local fx, fz, toward = -12.6, -12, Vector3.new(-9, 0, 2)
	if level >= 41 then
		fx, fz, toward = -14, -14.6, Vector3.new(-14, 0, -5)
	end
	local face = (toward - Vector3.new(fx, 0, fz)).Unit
	local base = at2(fx, 0, fz) * CFrame.lookAt(Vector3.zero, face)
	part(m, "SpotPad", Vector3.new(3.4, 0.08, 3.4), base * CFrame.new(0, 0.04, 0), Color3.fromRGB(214, 190, 140)).CastShadow =
		false
	part(m, "Stool", Vector3.new(1.3, 0.4, 1.3), base * CFrame.new(-0.9, 1.9, 0.5), wood, woodMat)
	for _, o in { { -1.4, 0 }, { -0.4, 0 }, { -1.4, 1 }, { -0.4, 1 } } do
		part(m, "StoolLeg", Vector3.new(0.25, 1.7, 0.25), base * CFrame.new(o[1], 0.85, o[2]), dark, woodMat)
	end
	part(m, "RodHolder", Vector3.new(1.6, 0.5, 0.4), base * CFrame.new(0.6, 0.6, -0.8), dark, woodMat)
	for _, dx in { 0.2, 1 } do
		local rod = base * CFrame.new(dx, 2.2, -2.6) * CFrame.Angles(math.rad(-58), 0, 0)
		part(m, "Rod", Vector3.new(0.12, 0.12, 4.6), rod * CFrame.new(0, 0, 0), dark, woodMat)
		local tip = (rod * CFrame.new(0, 0, -2.3)).Position
		local water = Vector3.new(tip.X, (area * CFrame.new(0, WATER_Y, 0)).Position.Y, tip.Z)
		part(
			m,
			"Line",
			Vector3.new(0.05, (tip - water).Magnitude, 0.05),
			CFrame.new((tip + water) / 2),
			Color3.fromRGB(240, 240, 240)
		)
		local bob = part(
			m,
			"Bobber",
			Vector3.one * 0.45,
			CFrame.new(water + Vector3.new(0, 0.2, 0)),
			Color3.fromRGB(230, 60, 50)
		) :: Part
		bob.Shape = Enum.PartType.Ball
	end
	if place and level < 41 then
		place(m, area, "FishBucket", fx + face.Z * 2.4, fz - face.X * 2.4, 1.8, 1.5, 0)
	end
	-- the back bank, left natural: reeds, round stones at the water's edge, a log half sunk
	if level >= 31 then
		local reedGreen, cattail = Color3.fromRGB(96, 150, 70), Color3.fromRGB(120, 76, 46)
		for c, r in { { 5, 21.4 }, { -6, 20.6 }, { 15.5, 19.5 } } do
			for k = 0, 4 do
				local ang = k * 1.3 + c
				local px, pz = r[1] + math.cos(ang) * 0.6, r[2] + math.sin(ang) * 0.5
				local h = 2.4 + (k % 3) * 0.4
				part(
					m,
					"Reed",
					Vector3.new(0.5, h, 0.1), -- (a broad blade, not a thin line)
					at2(px, WATER_Y + h / 2 + 0.3, pz) * CFrame.Angles(0, ang, (k - 2) * 0.1),
					reedGreen,
					Enum.Material.SmoothPlastic
				).CastShadow =
					false
				if k % 2 == 0 then
					part(
						m,
						"Cattail",
						Vector3.new(0.45, 0.9, 0.45),
						at2(px, WATER_Y + h + 0.45, pz),
						cattail,
						Enum.Material.SmoothPlastic
					).CastShadow =
						false
				end
			end
		end
		for k, st in { { -3, 21.2, 0.9 }, { -1.6, 21.6, 0.6 }, { 11.5, 21.6, 0.8 } } do
			local stone = part(
				m,
				"BankStone",
				Vector3.new(st[3] * 1.4, st[3], st[3] * 1.2),
				at2(st[1], WATER_Y + 0.2, st[2]) * CFrame.Angles(0, k, 0),
				Color3.fromRGB(150, 146, 140),
				Enum.Material.Slate
			) :: Part
			stone.Shape = Enum.PartType.Ball
		end
		-- (a round log, one end up on the sand step, the other dipping into the water)
		local sunk = part(
			m,
			"SunkLog",
			Vector3.new(5, 1.1, 1.1),
			at2(11.4, WATER_Y + 0.1, 18.6) * CFrame.Angles(0, 0.5, 0.12),
			Color3.fromRGB(130, 92, 58),
			woodMat
		) :: Part
		sunk.Shape = Enum.PartType.Cylinder
	end
	-- the pond beacon on the back-right bank: a square stone base, a tapered striped tower, a lantern
	-- room with its light, a roof, and a life ring on its base
	if level >= 41 then
		local bx, bz = -21.5, 10
		local stone = Color3.fromRGB(176, 170, 160)
		part(m, "BeaconBase", Vector3.new(3.6, 1.2, 3.6), at2(bx, 0.6, bz), stone, Enum.Material.Slate)
		for k = 0, 4 do
			local w = 2.4 - k * 0.22
			part(
				m,
				"BeaconTower",
				Vector3.new(w, 1, w),
				at2(bx, 1.7 + k, bz),
				if k % 2 == 0 then Color3.fromRGB(245, 245, 240) else Color3.fromRGB(70, 120, 200)
			)
		end
		part(m, "BeaconGallery", Vector3.new(2.4, 0.25, 2.4), at2(bx, 6.3, bz), stone, Enum.Material.Slate)
		local lamp = part(
			m,
			"BeaconLight",
			Vector3.new(1.7, 1.2, 1.7),
			at2(bx, 7, bz),
			Color3.fromRGB(255, 226, 150),
			Enum.Material.Neon
		)
		lamp.CastShadow = false
		part(m, "BeaconRoof", Vector3.new(2.5, 0.6, 2.5), at2(bx, 7.9, bz), Color3.fromRGB(200, 60, 50))
		part(m, "BeaconCap", Vector3.new(1, 0.6, 1), at2(bx, 8.5, bz), Color3.fromRGB(200, 60, 50))
		-- the buoy floats on a dark ring so it reads against the bright water
		local float = part(
			m,
			"BuoyFloat",
			Vector3.new(0.5, 2.4, 2.4),
			at2(-14.5, WATER_Y + 0.15, -3.5) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(40, 60, 80)
		) :: Part
		float.Shape = Enum.PartType.Cylinder
		local ring = part(
			m,
			"LifeRing",
			Vector3.new(0.25, 1.1, 1.1),
			at2(bx + 1.85, 0.8, bz) * CFrame.Angles(0, 0, 0),
			Color3.fromRGB(240, 90, 60)
		) :: Part
		ring.Shape = Enum.PartType.Cylinder
	end
	-- the jetty's two rod holders at its end
	if level >= 21 then
		for _, dx in { -0.8, 0.8 } do
			part(m, "JettyRodHolder", Vector3.new(0.3, 1, 0.3), at2(15 + dx, DECK_Y + 0.75, 0), dark, woodMat)
			local rod = at2(15 + dx * 1.6, DECK_Y + 2.2, 1.9) * CFrame.Angles(math.rad(30), dx * 0.25, 0)
			part(m, "JettyRod", Vector3.new(0.14, 0.14, 4.4), rod, dark, woodMat)
			local tip = (rod * CFrame.new(0, 0, 2.2)).Position
			local water = Vector3.new(tip.X, (area * CFrame.new(0, WATER_Y, 0)).Position.Y, tip.Z)
			part(
				m,
				"Line",
				Vector3.new(0.06, (tip - water).Magnitude, 0.06),
				CFrame.new((tip + water) / 2),
				Color3.fromRGB(240, 240, 240)
			)
			local bob = part(
				m,
				"Bobber",
				Vector3.one * 0.55,
				CFrame.new(water + Vector3.new(0, 0.25, 0)),
				Color3.fromRGB(230, 60, 50)
			) :: Part
			bob.Shape = Enum.PartType.Ball
		end
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
