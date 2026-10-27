--!strict
-- The fishing pond's 50 levels (the owner, 2026-10-27): ten eras of five levels. The first level of
-- an era is its remodel (the dock's material and size, the work spots, the era's landmarks); the
-- next four each add one thing, in order: a decoration, rails along the dock, a fishing tool, lights
-- or glow. `build` makes the layer that sits on the pond for one level; the pond itself (water, shore,
-- fish, the sign) stays. Kit models come from ServerStorage (PropKit / OwnerKit / NatureKit in the
-- work place, ServerStorage.Kit.* in the built game); a missing model is skipped.
-- Used by AreaUpgrade.server.luau (the game) and tools/map/build_pond_showcase.luau (the showcase).
local ServerStorage = game:GetService("ServerStorage")

local PondStages = {}

PondStages.MaxLevel = 50

local function kit(name: string): Instance?
	local direct = ServerStorage:FindFirstChild(name)
	if direct then
		return direct
	end
	local bundle = ServerStorage:FindFirstChild("Kit")
	return bundle and bundle:FindFirstChild(name)
end

-- kit model, local x, z, height, turn, lift (the showcase only: the real pond has its own dressing)
local NATURE: { { any } } = {
	{ "FloweringBush", -22, 26, 5, 10 },
	{ "BerryBush", 24, 26, 4.5, 80 },
	{ "MossyBoulder", 26, 18, 3.6, 40 },
	{ "SmallRocks", -20, -12, 1.8, 0 },
	{ "Fern", -25, 20, 3.4, 0 },
	{ "GrassTuft", 20, -14, 2.4, 30 },
	{ "FlowerPatch", -12, -16, 1.6, 0 },
	{ "FlowerPatch", 14, -18, 1.5, 90 },
	{ "WaterLily", -12, 8, 0.8, 30, 0.05 },
	{ "WaterLily", 15, 6, 0.7, 120, 0.05 },
}

-- each era: the dock's look, its length and width, how many work spots, the landmarks on the shore
-- (kit model, local x, z, height, turn), the decoration, the tool and the light of its small steps
type Era = {
	name: string,
	plank: { Color3 },
	material: Enum.Material,
	post: Color3,
	head: Color3?, -- a stone / brick / marble pier head at the dock's end
	trim: Color3?, -- neon trim along the dock (modern eras)
	length: number,
	width: number,
	spots: number,
	landmarks: { { any } },
	decor: string,
	tool: string,
	light: string, -- "lamps", "neon", "goo", "gold"
}
local ERAS: { Era } = {
	{
		name = "Rustic wood",
		plank = { Color3.fromRGB(205, 146, 82), Color3.fromRGB(170, 112, 58) },
		material = Enum.Material.Wood,
		post = Color3.fromRGB(120, 78, 44),
		length = 16,
		width = 6,
		spots = 1,
		landmarks = {},
		decor = "FlowerPot",
		tool = "FishBucket",
		light = "lamps",
	},
	{
		name = "Painted wood",
		plank = { Color3.fromRGB(245, 240, 228), Color3.fromRGB(120, 170, 220) },
		material = Enum.Material.WoodPlanks,
		post = Color3.fromRGB(70, 110, 160),
		length = 17,
		width = 6,
		spots = 1,
		landmarks = { { "NetRack", -30, 4, 4.5 } },
		decor = "Planter",
		tool = "FishBucket",
		light = "lamps",
	},
	{
		name = "Stone and timber",
		plank = { Color3.fromRGB(150, 100, 60), Color3.fromRGB(125, 82, 48) },
		material = Enum.Material.Wood,
		post = Color3.fromRGB(150, 146, 140),
		head = Color3.fromRGB(170, 166, 158),
		length = 18,
		width = 7,
		spots = 2,
		landmarks = { { "NetRack", -30, 4, 4.5 }, { "FishingHut", 30, -6, 7.5 } },
		decor = "LogBench",
		tool = "CrateStack",
		light = "lamps",
	},
	{
		name = "Brick village",
		plank = { Color3.fromRGB(176, 120, 76), Color3.fromRGB(150, 98, 60) },
		material = Enum.Material.WoodPlanks,
		post = Color3.fromRGB(160, 80, 60),
		head = Color3.fromRGB(184, 92, 70),
		length = 19,
		width = 7,
		spots = 2,
		landmarks = { { "Boathouse", -31, 12, 9 }, { "RowBoat", 13, 15, 1.6, 20 } },
		decor = "BannerFlag",
		tool = "CrateStack",
		light = "lamps",
	},
	{
		name = "Workshop",
		plank = { Color3.fromRGB(160, 110, 66), Color3.fromRGB(110, 110, 116) },
		material = Enum.Material.Wood,
		post = Color3.fromRGB(90, 90, 96),
		head = Color3.fromRGB(150, 146, 140),
		length = 20,
		width = 8,
		spots = 3,
		landmarks = { { "WaterWheel", -30, 6, 9 }, { "NetCrane", 29, 2, 8 }, { "RowBoat", 13, 15, 1.6, 20 } },
		decor = "WoodBarrel",
		tool = "FishBucket",
		light = "lamps",
	},
	{
		name = "Glass house",
		plank = { Color3.fromRGB(235, 220, 196), Color3.fromRGB(220, 204, 178) },
		material = Enum.Material.WoodPlanks,
		post = Color3.fromRGB(240, 240, 240),
		head = Color3.fromRGB(230, 230, 226),
		length = 21,
		width = 8,
		spots = 3,
		landmarks = { { "GlassPavilion", -31, 12, 9 }, { "FishTank", 29, -4, 4 } },
		decor = "Planter",
		tool = "FishBucket",
		light = "lamps",
	},
	{
		name = "Modern farm",
		plank = { Color3.fromRGB(150, 156, 164), Color3.fromRGB(120, 126, 134) },
		material = Enum.Material.DiamondPlate,
		post = Color3.fromRGB(70, 74, 80),
		head = Color3.fromRGB(200, 204, 210),
		trim = Color3.fromRGB(255, 220, 140),
		length = 22,
		width = 9,
		spots = 4,
		landmarks = { { "ModernKiosk", -31, 10, 8.5 }, { "FishCooler", 28, -8, 2.2 } },
		decor = "Planter",
		tool = "FishCooler",
		light = "neon",
	},
	{
		name = "Tech",
		plank = { Color3.fromRGB(70, 76, 90), Color3.fromRGB(56, 60, 72) },
		material = Enum.Material.DiamondPlate,
		post = Color3.fromRGB(40, 44, 54),
		head = Color3.fromRGB(90, 96, 110),
		trim = Color3.fromRGB(80, 200, 255),
		length = 23,
		width = 9,
		spots = 4,
		landmarks = { { "AutoReel", -29, 0, 6 }, { "Drone", 10, 10, 2, 0, 7 }, { "ModernKiosk", 31, 10, 8.5 } },
		decor = "FishCooler",
		tool = "AutoReel",
		light = "neon",
	},
	{
		name = "Slime tech",
		plank = { Color3.fromRGB(40, 90, 96), Color3.fromRGB(30, 70, 76) },
		material = Enum.Material.DiamondPlate,
		post = Color3.fromRGB(24, 50, 56),
		head = Color3.fromRGB(60, 120, 126),
		trim = Color3.fromRGB(120, 255, 150),
		length = 24,
		width = 10,
		spots = 4,
		landmarks = {
			{ "GooPump", -31, 10, 8 },
			{ "CrystalBuoy", 9, 12, 3.5, 0, -0.6 },
			{ "CrystalBuoy", -6, 16, 3, 40, -0.6 },
			{ "Drone", 4, 6, 2, 0, 8 },
		},
		decor = "FishTank",
		tool = "AutoReel",
		light = "goo",
	},
	{
		name = "Grand",
		plank = { Color3.fromRGB(246, 242, 236), Color3.fromRGB(226, 220, 212) },
		material = Enum.Material.Marble,
		post = Color3.fromRGB(230, 190, 80),
		head = Color3.fromRGB(250, 248, 244),
		trim = Color3.fromRGB(255, 210, 90),
		length = 24,
		width = 10,
		spots = 4,
		landmarks = {
			{ "Lighthouse", -31, 16, 14 },
			{ "GoldFountain", 29, -6, 5 },
			{ "CrystalBuoy", 9, 12, 3.5, 0, -0.6 },
		},
		decor = "GoldFountain",
		tool = "AutoReel",
		light = "gold",
	},
}

PondStages.Eras = ERAS

local GRASS = Color3.fromRGB(104, 178, 62)
local SAND = Color3.fromRGB(232, 206, 142)
local WATER = { Color3.fromRGB(96, 196, 235), Color3.fromRGB(56, 156, 222), Color3.fromRGB(34, 118, 204) }

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
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.CastShadow = size.Magnitude > 4
	p.Parent = parent
	return p
end

-- a kit model standing at local (x, z) of the cell, `height` tall; no turn: its front faces the dock
local function place(
	parent: Instance,
	cell: CFrame,
	key: string,
	x: number,
	z: number,
	height: number,
	turn: number?,
	y: number?
): Model?
	local src: Instance? = nil
	for _, name in { "PropKit", "OwnerKit", "NatureKit" } do
		local k = kit(name)
		if not src and k then
			src = k:FindFirstChild(key)
		end
	end
	if not src or not src:IsA("Model") then
		return nil
	end
	local m = src:Clone() :: Model
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d:IsA("MeshPart") then
				d.DoubleSided = true
			end
		end
	end
	local _, s0 = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * height / s0.Y)
	local pivot = m:GetPivot()
	local yaw = if turn then math.rad(turn) else math.atan2(x, z)
	m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, yaw, 0) * pivot.Rotation)
	local box, size = m:GetBoundingBox()
	local target = (cell * CFrame.new(x, (y or 0) + size.Y / 2, z)).Position
	m:PivotTo(m:GetPivot() + (target - box.Position))
	m.Parent = parent
	return m
end

local function lamp(parent: Instance, cell: CFrame, x: number, z: number)
	local m = place(parent, cell, "VillageLamp", x, z, 6.5, 0)
	if m then
		local box, size = m:GetBoundingBox()
		local glow = part(
			m,
			"LampLight",
			Vector3.one * 0.4,
			CFrame.new(box.Position + Vector3.new(0, size.Y / 2 - 1, 0)),
			Color3.new(1, 1, 1)
		)
		glow.Transparency = 1
		glow.CanCollide = false
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 200, 120)
		l.Range = 12
		l.Parent = glow
	end
end

-- The era (1..10) and the step inside it (1..5) of a level.
function PondStages.stage(level: number): (number, number)
	local era = math.clamp(math.ceil(level / 5), 1, #ERAS)
	return era, level - (era - 1) * 5
end

-- The layer for one level, its dock along +Z from the shore at `cell` (y = the ground's top).
-- showcase = true also lays a grass slab, painted water, bushes and a label (the floating showcase);
-- shore = two spots (left, right as local x, z) for the big landmarks.
function PondStages.build(level: number, cell: CFrame, showcase: boolean?, shore: { Vector2 }?): Model
	local era, step = PondStages.stage(level)
	local e = ERAS[era]
	local m = Instance.new("Model")
	m.Name = "PondStage"
	m:SetAttribute("Level", level)

	if showcase then
		local slab =
			part(m, "Ground", Vector3.new(76, 2, 58), cell * CFrame.new(0, -1, 5), GRASS, Enum.Material.Plastic)
		slab.TopSurface = Enum.SurfaceType.Studs
		local grow = 1 + (era - 1) * 0.025
		local lobes = { { 0, 5, 16 }, { 9, 11, 11 }, { -9, 2, 11 } }
		local function disc(name: string, x: number, z: number, r: number, y: number, colour: Color3)
			local d = part(
				m,
				name,
				Vector3.new(0.1, r * 2, r * 2),
				cell * CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90)),
				colour,
				Enum.Material.SmoothPlastic,
				Enum.PartType.Cylinder
			)
			d.CastShadow = false
		end
		for _, l in lobes do
			disc("Sand", l[1], l[2], (l[3] + 2) * grow, 0.02, SAND)
		end
		for t, inset in { 0.3, 2.6, 5.5 } do
			for _, l in lobes do
				disc("Water", l[1], l[2], (l[3] - inset) * grow, 0.04 + t * 0.01, WATER[t])
			end
		end
		for _, n in NATURE do
			place(m, cell, n[1], n[2], n[3], n[4], n[5], n[6])
		end
	end

	-- the dock: planks across, posts down into the water, a pier head at the end in the later eras
	local dock = Instance.new("Model")
	dock.Name = "Dock"
	local z0 = -14
	local z1 = z0 + e.length
	local plankDepth = 1.4
	local i = 0
	local z = z0
	while z < z1 do
		i += 1
		part(
			dock,
			"Plank",
			Vector3.new(e.width, 0.5, plankDepth),
			cell * CFrame.new(0, 0.9, z + plankDepth / 2),
			e.plank[(i % 2) + 1],
			e.material
		)
		z += plankDepth + 0.12
	end
	for _, s in { -1, 1 } do
		for _, pz in { z0 + 1, (z0 + z1) / 2, z1 - 0.6 } do
			part(
				dock,
				"Post",
				Vector3.new(0.9, 5, 0.9),
				cell * CFrame.new(s * (e.width / 2 - 0.3), -1.2, pz),
				e.post,
				e.material
			)
		end
	end
	if e.head then
		part(
			dock,
			"PierHead",
			Vector3.new(e.width + 3, 0.8, 5),
			cell * CFrame.new(0, 0.75, z1 + 1.5),
			e.head,
			if era == 10 then Enum.Material.Marble else Enum.Material.Slate
		)
	end
	-- a cross branch for the extra work spots (era 3 on)
	local spotsAt = { Vector3.new(0, 1.2, z1 + (if e.head then 3 else 0)) }
	if e.spots >= 2 then
		local bz = (z0 + z1) / 2 + 2
		local reach = e.width / 2 + 6
		for _, s in { -1, 1 } do
			part(
				dock,
				"Branch",
				Vector3.new(6, 0.5, 3),
				cell * CFrame.new(s * (e.width / 2 + 3), 0.9, bz),
				e.plank[1],
				e.material
			)
		end
		table.insert(spotsAt, Vector3.new(-reach + 0.5, 1.2, bz))
		if e.spots >= 3 then
			table.insert(spotsAt, Vector3.new(reach - 0.5, 1.2, bz))
		end
		if e.spots >= 4 then
			table.insert(spotsAt, Vector3.new(0, 1.2, z1 + (if e.head then 3 else 0) - 3.5))
			spotsAt[1] += Vector3.new(e.width / 2 - 1, 0, 0)
			spotsAt[4] += Vector3.new(-(e.width / 2 - 1), 0, 3.5)
		end
	end
	-- step 3: rails along the dock
	if step >= 3 then
		for _, s in { -1, 1 } do
			part(
				dock,
				"Rail",
				Vector3.new(0.35, 0.35, e.length - 2),
				cell * CFrame.new(s * (e.width / 2 - 0.3), 2.2, (z0 + z1) / 2 - 1),
				e.post,
				e.material
			)
		end
	end
	-- step 5: light strips along the dock (the modern eras)
	local trim = e.trim
	if step >= 5 and trim then
		for _, s in { -1, 1 } do
			local strip = part(
				dock,
				"Trim",
				Vector3.new(0.25, 0.2, e.length),
				cell * CFrame.new(s * (e.width / 2 + 0.05), 1.05, (z0 + z1) / 2),
				trim,
				Enum.Material.Neon
			)
			strip.CastShadow = false
		end
	end
	dock.Parent = m

	-- the work spots: an invisible marker (WorkSpot1..4) and a rod over the water at each
	for k, p in spotsAt do
		local mark = part(m, "WorkSpot" .. k, Vector3.new(2, 0.2, 2), cell * CFrame.new(p), Color3.new(1, 1, 1))
		mark.Transparency = 1
		mark.CanCollide = false
		local base = (cell * CFrame.new(p)).Position
		local outward = cell:VectorToWorldSpace(Vector3.new(p.X, 0, p.Z - z0))
		local dir = if outward.Magnitude > 1e-3 then outward.Unit else cell.LookVector
		local tip = base + dir * 4 + Vector3.new(0, 3, 0)
		local rod = part(
			m,
			"Rod",
			Vector3.new(0.15, 0.15, (tip - base).Magnitude),
			CFrame.lookAt((base + tip) / 2, tip),
			Color3.fromRGB(120, 78, 44)
		)
		rod.CastShadow = false
	end

	-- the era's landmarks on the shore; the big ones (|x| >= 25, either side of the pond) go to the
	-- caller's shore spots when given (a home plot's pond has no room beside it, only in front)
	for _, l in e.landmarks do
		local lx, lz = l[2], l[3]
		if shore and math.abs(lx) >= 25 then
			local spot = if lx < 0 then shore[1] else shore[2]
			lx, lz = spot.X, spot.Y
		end
		local lm = place(m, cell, l[1], lx, lz, l[4], l[5], l[6])
		if lm then
			lm:SetAttribute("Landmark", true)
		end
	end
	-- step 2: a decoration by the shore end of the dock
	if step >= 2 then
		place(m, cell, e.decor, -(e.width / 2 + 3), z0 - 2, if e.decor == "GoldFountain" then 3.5 else 2.4, 20)
	end
	-- step 4: the era's fishing tool beside the first spot
	if step >= 4 then
		local p = spotsAt[1]
		place(
			m,
			cell,
			e.tool,
			p.X + (e.width / 2 - 1.5) * (if p.X > 0 then -1 else 1),
			p.Z - 2.5,
			if e.tool == "AutoReel" then 3 else 2,
			180,
			1.15
		)
	end
	-- step 5: lamps on the shore (the early eras), a glow of goo or gold (the late ones)
	if step >= 5 then
		if e.light == "lamps" then
			lamp(m, cell, e.width / 2 + 2.5, z0 - 1)
			lamp(m, cell, -(e.width / 2 + 2.5), z0 - 1)
		else
			local core = part(m, "Glow", Vector3.one, cell * CFrame.new(0, 2.5, (z0 + z1) / 2), Color3.new(1, 1, 1))
			core.Transparency = 1
			core.CanCollide = false
			local l = Instance.new("PointLight")
			l.Color = trim or Color3.new(1, 1, 1)
			l.Range = 20
			l.Brightness = 0.6 -- (brighter lit the pond bed white)
			l.Parent = core
			if e.light == "goo" or e.light == "gold" then
				local fx = Instance.new("ParticleEmitter")
				fx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				fx.Color = ColorSequence.new(trim or Color3.new(1, 1, 1))
				fx.LightEmission = 1
				fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
				fx.Lifetime = NumberRange.new(1.5, 2.5)
				fx.Rate = 6
				fx.Speed = NumberRange.new(0.5, 1.2)
				fx.SpreadAngle = Vector2.new(180, 180)
				fx.Parent = core
			end
		end
	end

	if showcase then
		local tag = part(m, "Label", Vector3.new(14, 3, 0.4), cell * CFrame.new(0, 14, -30), Color3.new(1, 1, 1))
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
		text.Text = string.format("Level %d · %s", level, e.name)
		text.Parent = gui
		gui.Parent = tag
	end
	return m
end

return PondStages
