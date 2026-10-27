-- A showcase of the fishing pond's 50 levels (the owner, 2026-10-27: 50 levels, a small change every
-- level and a big remodel every 5, from rustic to modern; built straight in Studio to look at, no
-- picture first). Ten eras of five levels; inside an era the levels add, in order:
--   1 the era's remodel (dock material and size, work spots, the era's landmark)
--   2 a decoration   3 rails along the dock (the material step)   4 a fishing tool   5 lights / glow
-- Row 1: each era at its last level (5, 10 ... 50). Row 2: the five levels of one era (STEP_ERA).
-- Built on floating stud platforms away from the valley, painted water, kit models from
-- ServerStorage.PropKit / OwnerKit (a missing model is skipped). Run in Edit mode through MCP.
local ServerStorage = game:GetService("ServerStorage")

local ORIGIN = Vector3.new(-2600, 120, 300)
local SPACING = 92
local STEP_ERA = 4

local propKit = ServerStorage:FindFirstChild("PropKit")
local ownerKit = ServerStorage:FindFirstChild("OwnerKit")
local natureKit = ServerStorage:FindFirstChild("NatureKit")
-- kit model, local x, z, height, turn, lift
local NATURE = {
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

local GRASS = Color3.fromRGB(104, 178, 62)
local SAND = Color3.fromRGB(232, 206, 142)
local WATER = { Color3.fromRGB(96, 196, 235), Color3.fromRGB(56, 156, 222), Color3.fromRGB(34, 118, 204) }

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
		landmarks = { { "GooPump", -31, 10, 8 }, { "CrystalBuoy", 9, 12, 3.5, 0, -0.6 }, { "CrystalBuoy", -6, 16, 3, 40, -0.6 }, { "Drone", 4, 6, 2, 0, 8 } },
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
		landmarks = { { "Lighthouse", -31, 16, 14 }, { "GoldFountain", 29, -6, 5 }, { "CrystalBuoy", 9, 12, 3.5, 0, -0.6 } },
		decor = "GoldFountain",
		tool = "AutoReel",
		light = "gold",
	},
}

local showcase = workspace:FindFirstChild("PondShowcase")
if showcase then
	showcase:Destroy()
end
showcase = Instance.new("Folder")
showcase.Name = "PondShowcase"

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
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

-- a kit model standing at local (x, z) of the cell, `height` tall, turned; y lifts it
local function place(parent: Instance, cell: CFrame, key: string, x: number, z: number, height: number, turn: number?, y: number?): Model?
	local src = (propKit and propKit:FindFirstChild(key)) or (ownerKit and ownerKit:FindFirstChild(key)) or (natureKit and natureKit:FindFirstChild(key))
	if not src or not src:IsA("Model") then
		return nil
	end
	local m = src:Clone()
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
	-- no turn given: its front (-Z) faces the dock
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
		local glow = part(m, "LampLight", Vector3.one * 0.4, CFrame.new(box.Position + Vector3.new(0, size.Y / 2 - 1, 0)), Color3.new(1, 1, 1))
		glow.Transparency = 1
		glow.CanCollide = false
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 200, 120)
		l.Range = 12
		l.Parent = glow
	end
end

-- One pond at a level, its cell centred at `cell` (front of the area toward -Z).
local function pond(level: number, cell: CFrame)
	local era = math.clamp(math.ceil(level / 5), 1, #ERAS)
	local step = level - (era - 1) * 5
	local e = ERAS[era]
	local m = Instance.new("Model")
	m.Name = string.format("Level%02d", level)

	-- the ground: one stud grass slab, the pond painted on it with a sand rim
	local slab = part(m, "Ground", Vector3.new(76, 2, 58), cell * CFrame.new(0, -1, 5), GRASS, Enum.Material.Plastic)
	slab.TopSurface = Enum.SurfaceType.Studs
	local grow = 1 + (era - 1) * 0.025
	local lobes = { { 0, 5, 16 }, { 9, 11, 11 }, { -9, 2, 11 } }
	local function disc(name: string, x: number, z: number, r: number, y: number, colour: Color3)
		part(m, name, Vector3.new(0.1, r * 2, r * 2), cell * CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90)), colour, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder).CastShadow =
			false
	end
	for _, l in lobes do
		disc("Sand", l[1], l[2], (l[3] + 2) * grow, 0.02, SAND)
	end
	for t, inset in { 0.3, 2.6, 5.5 } do
		for _, l in lobes do
			disc("Water", l[1], l[2], (l[3] - inset) * grow, 0.04 + t * 0.01, WATER[t])
		end
	end

	-- the dock: planks across, posts, a pier head at the end in the later eras
	local dock = Instance.new("Model")
	dock.Name = "Dock"
	local z0 = -14
	local z1 = z0 + e.length
	local plankDepth = 1.4
	local i = 0
	local z = z0
	while z < z1 do
		i += 1
		part(dock, "Plank", Vector3.new(e.width, 0.5, plankDepth), cell * CFrame.new(0, 0.9, z + plankDepth / 2), e.plank[(i % 2) + 1], e.material)
		z += plankDepth + 0.12
	end
	for _, s in { -1, 1 } do
		for _, pz in { z0 + 1, (z0 + z1) / 2, z1 - 0.6 } do
			part(dock, "Post", Vector3.new(0.9, 2.6, 0.9), cell * CFrame.new(s * (e.width / 2 - 0.3), 0, pz), e.post, e.material)
		end
	end
	if e.head then
		part(dock, "PierHead", Vector3.new(e.width + 3, 0.8, 5), cell * CFrame.new(0, 0.75, z1 + 1.5), e.head, if era == 10 then Enum.Material.Marble else Enum.Material.Slate)
	end
	-- a cross branch for the extra work spots (era 3 on)
	local spotsAt = { Vector3.new(0, 1.2, z1 + (if e.head then 3 else 0)) }
	if e.spots >= 2 then
		local bz = (z0 + z1) / 2 + 2
		local reach = e.width / 2 + 6
		for _, s in { -1, 1 } do
			part(dock, "Branch", Vector3.new(6, 0.5, 3), cell * CFrame.new(s * (e.width / 2 + 3), 0.9, bz), e.plank[1], e.material)
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
			part(dock, "Rail", Vector3.new(0.35, 0.35, e.length - 2), cell * CFrame.new(s * (e.width / 2 - 0.3), 2.2, (z0 + z1) / 2 - 1), e.post, e.material)
		end
	end
	-- step 5: lights or glow along the dock
	if step >= 5 and e.trim then
		for _, s in { -1, 1 } do
			local strip = part(dock, "Trim", Vector3.new(0.25, 0.2, e.length), cell * CFrame.new(s * (e.width / 2 + 0.05), 1.05, (z0 + z1) / 2), e.trim, Enum.Material.Neon)
			strip.CastShadow = false
		end
	end
	dock.Parent = m

	-- the work spots: an invisible marker and a rod over the water at each
	for k, p in spotsAt do
		local mark = part(m, "WorkSpot" .. k, Vector3.new(2, 0.2, 2), cell * CFrame.new(p), Color3.new(1, 1, 1))
		mark.Transparency = 1
		mark.CanCollide = false
		local outward = (cell * CFrame.new(p)).Position - cell.Position
		local dir = Vector3.new(outward.X, 0, outward.Z).Unit
		local base = (cell * CFrame.new(p)).Position
		local tip = base + dir * 4 + Vector3.new(0, 3, 0)
		local rod = part(m, "Rod", Vector3.new(0.15, 0.15, (tip - base).Magnitude), CFrame.lookAt((base + tip) / 2, tip), Color3.fromRGB(120, 78, 44))
		rod.CastShadow = false
	end

	-- the era's landmarks on the shore
	for _, l in e.landmarks do
		place(m, cell, l[1], l[2], l[3], l[4], l[5], l[6])
	end
	-- the same bushes, rocks and lilies round every level, so each reads like the real pond
	for _, n in NATURE do
		place(m, cell, n[1], n[2], n[3], n[4], n[5], n[6])
	end
	-- step 2: a decoration by the shore end of the dock
	if step >= 2 then
		place(m, cell, e.decor, -(e.width / 2 + 3), z0 - 2, if e.decor == "GoldFountain" then 3.5 else 2.4, 20)
	end
	-- step 4: the era's fishing tool beside the first spot
	if step >= 4 then
		local p = spotsAt[1]
		place(m, cell, e.tool, p.X + (e.width / 2 - 1.5) * (if p.X > 0 then -1 else 1), p.Z - 2.5, if e.tool == "AutoReel" then 3 else 2, 180, 1.15)
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
			l.Color = e.trim or Color3.new(1, 1, 1)
			l.Range = 20
			l.Brightness = 1.5
			l.Parent = core
			if e.light == "goo" or e.light == "gold" then
				local fx = Instance.new("ParticleEmitter")
				fx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				fx.Color = ColorSequence.new(e.trim or Color3.new(1, 1, 1))
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

	-- a floating label (the showcase only)
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

	m.Parent = showcase
end

for era = 1, #ERAS do
	pond(era * 5, CFrame.new(ORIGIN + Vector3.new((era - 1) * SPACING, 0, 0)))
	task.wait()
end
for k = 1, 5 do
	local level = (STEP_ERA - 1) * 5 + k
	pond(level, CFrame.new(ORIGIN + Vector3.new((k - 1) * SPACING, 0, 110)))
	task.wait()
end
showcase.Parent = workspace
return "pond showcase: " .. #showcase:GetChildren() .. " ponds"
