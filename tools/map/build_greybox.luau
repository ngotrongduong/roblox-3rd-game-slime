-- Greybox of the Goo Valley (docs/MAP.md): simple block shapes for the Market, the eight home
-- plots and their areas, the Heart, goo springs and trees, plus the lighting, so the layout and its
-- scale can be judged before real models replace the blocks. Run in Edit mode through Studio's MCP
-- after build_terrain; it rebuilds Workspace.Map from scratch each time.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local M = Config.Map
local rng = Random.new(7)

local old = workspace:FindFirstChild("Map")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "Map"

local WOOD = Color3.fromRGB(196, 140, 78)
local DARKWOOD = Color3.fromRGB(122, 82, 48)
local CREAM = Color3.fromRGB(250, 238, 210)
local ROYAL = Color3.fromRGB(46, 84, 186)
local GOLD = Color3.fromRGB(240, 196, 70)
local HEDGE = Color3.fromRGB(78, 150, 64)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	-- Small pieces cast no shadow: cheaper on phones.
	p.CastShadow = size.Magnitude > 12
	p.Parent = parent
	return p
end

local function wedge(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = colour
	w.Material = Enum.Material.SmoothPlastic
	w.Parent = parent
end

-- A pitched roof over a box: two wedges back to back.
local function hut(parent: Instance, name: string, cf: CFrame, w: number, h: number, d: number, wall: Color3, roof: Color3)
	part(parent, name .. "Walls", Vector3.new(w, h, d), cf * CFrame.new(0, h / 2, 0), wall)
	local rh = h * 0.55
	wedge(parent, name .. "RoofA", Vector3.new(w + 2, rh, d / 2 + 1), cf * CFrame.new(0, h + rh / 2, d / 4 + 0.5), roof)
	wedge(parent, name .. "RoofB", Vector3.new(w + 2, rh, d / 2 + 1), cf * CFrame.new(0, h + rh / 2, -d / 4 - 0.5) * CFrame.Angles(0, math.pi, 0), roof)
end

-- A floating name over a place (greybox only; the real game names things by their looks).
local function label(adornee: BasePart, text: string, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.MaxDistance = 260
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.fromRGB(255, 248, 230)
	t.TextStrokeTransparency = 0.2
	t.TextStrokeColor3 = Color3.fromRGB(90, 56, 30)
	t.Parent = gui
	gui.Adornee = adornee
	gui.Parent = adornee
end

-- Trees are the owner's own models (ServerStorage.OwnerKit; the owner, 2026-10-27: no code-built
-- trees), by kind: the rim's mixed wood or a Wild Garden quarter. A trunk and ball crown only stand in
-- when the kit is missing. (replace_greybox_trees.luau did the same swap on the built map.)
local TREE_KINDS = {
	rim = { "TallPineLarge", "TallPineDense", "BroadleafTree", "TallPineSparse", "TallPineSlender", "TallPineWindswept" },
	meadow = { "BroadleafTree", "BanyanTree", "BroadleafTree" },
	mushroom = { "VineTree", "BanyanTree" },
	ember = { "TallPineWindswept", "TallPineSparse" },
	frost = { "FrozenDeadTree", "TallPineSlender" },
}
local ownerKit = game:GetService("ServerStorage"):FindFirstChild("OwnerKit")
local function tree(parent: Instance, pos: Vector3, scale: number, leaves: Color3, kind: string)
	local kinds = TREE_KINDS[kind] or TREE_KINDS.rim
	local src = ownerKit and ownerKit:FindFirstChild(kinds[rng:NextInteger(1, #kinds)])
	if src and src:IsA("Model") then
		local m = src:Clone()
		local _, size0 = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * 16 * scale / size0.Y)
		local pivot = m:GetPivot()
		m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) * pivot.Rotation)
		local box, size = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + (pos + Vector3.new(0, size.Y / 2, 0) - box.Position))
		m.Name = "Tree"
		m.Parent = parent
		return
	end
	-- (a cylinder's length is its X size, so it is laid on its side and turned upright)
	part(parent, "Trunk", Vector3.new(9, 2.2, 2.2) * scale, CFrame.new(pos + Vector3.new(0, 4.5 * scale, 0)), DARKWOOD, Enum.PartType.Cylinder):PivotTo(
		CFrame.new(pos + Vector3.new(0, 4.5 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90))
	)
	part(parent, "Crown", Vector3.one * 10 * scale, CFrame.new(pos + Vector3.new(0, 11 * scale, 0)), leaves, Enum.PartType.Ball)
end

-- ===== a home plot =====
local AREA_NAMES = {
	fishing = "Fishing Pond",
	pantry = "Pantry",
	garden = "Garden",
	kitchen = "Kitchen",
	meadow = "Slime Meadow",
	breeding = "Breeding House",
	training = "Training Ground",
	gate = "Gate",
	hatchery = "Hatchery",
}

local function buildPlot(plot: number)
	local folder = Instance.new("Model")
	folder.Name = "Plot" .. plot
	local frame = Layout.plotFrame(plot)
	local half = M.PlotSize / 2

	-- A low hedge around the plot, open at the gate.
	local gateGap = 18
	for _, side in { { 0, half, M.PlotSize, 0 }, { -half, 0, M.PlotSize, 90 }, { half, 0, M.PlotSize, 90 } } do
		part(folder, "Hedge", Vector3.new(side[3], 3.5, 3), frame * CFrame.new(side[1], 1.75, side[2]) * CFrame.Angles(0, math.rad(side[4]), 0), HEDGE, nil, Enum.Material.LeafyGrass)
	end
	local frontLen = (M.PlotSize - gateGap) / 2
	for _, x in { -(gateGap / 2 + frontLen / 2), gateGap / 2 + frontLen / 2 } do
		part(folder, "Hedge", Vector3.new(frontLen, 3.5, 3), frame * CFrame.new(x, 1.75, -half), HEDGE, nil, Enum.Material.LeafyGrass)
	end

	for _, area in Layout.PlotAreas do
		local cf = Layout.plotAreaFrame(plot, area.col, area.row)
		local anchor: BasePart
		if area.id == "fishing" then
			anchor = part(folder, "Dock", Vector3.new(6, 1, 22), cf * CFrame.new(16, 0.6, -6), WOOD)
			part(folder, "Seat", Vector3.new(3, 2, 3), cf * CFrame.new(16, 2, 2), DARKWOOD)
		elseif area.id == "pantry" then
			hut(folder, "Pantry", cf, 22, 14, 16, WOOD, DARKWOOD)
			anchor = folder:FindFirstChild("PantryWalls") :: BasePart
		elseif area.id == "garden" then
			for i = -1, 1 do
				part(folder, "Row", Vector3.new(30, 1, 6), cf * CFrame.new(0, 0.5, i * 11), Color3.fromRGB(120, 78, 44), nil, Enum.Material.Ground)
				for j = -2, 2 do
					part(folder, "Sprout", Vector3.one * 2.4, cf * CFrame.new(j * 6, 2, i * 11), Color3.fromRGB(96, 186, 70), Enum.PartType.Ball)
				end
			end
			anchor = part(folder, "Scarecrow", Vector3.new(1, 8, 1), cf * CFrame.new(18, 4, 18), WOOD)
		elseif area.id == "kitchen" then
			hut(folder, "Kitchen", cf, 18, 10, 14, CREAM, Color3.fromRGB(196, 74, 56))
			part(folder, "Chimney", Vector3.new(3, 8, 3), cf * CFrame.new(5, 14, 3), Color3.fromRGB(150, 140, 130))
			anchor = folder:FindFirstChild("KitchenWalls") :: BasePart
		elseif area.id == "meadow" then
			hut(folder, "Home", cf * CFrame.new(0, 0, 12), 20, 14, 16, CREAM, ROYAL)
			anchor = folder:FindFirstChild("HomeWalls") :: BasePart
		elseif area.id == "breeding" then
			hut(folder, "Breeding", cf, 18, 12, 16, CREAM, Color3.fromRGB(232, 120, 160))
			anchor = folder:FindFirstChild("BreedingWalls") :: BasePart
		elseif area.id == "training" then
			for i = -1, 1 do
				part(folder, "Dummy", Vector3.new(6, 3, 3), cf * CFrame.new(i * 10, 3, 6), Color3.fromRGB(214, 176, 110), Enum.PartType.Cylinder):PivotTo(
					cf * CFrame.new(i * 10, 3, 6) * CFrame.Angles(0, 0, math.rad(90))
				)
			end
			anchor = part(folder, "Yard", Vector3.new(40, 0.4, 36), cf * CFrame.new(0, 0.2, 0), Color3.fromRGB(222, 196, 140), nil, Enum.Material.Sand)
		elseif area.id == "gate" then
			part(folder, "PostL", Vector3.new(2, 12, 2), frame * CFrame.new(-gateGap / 2, 6, -half), WOOD)
			part(folder, "PostR", Vector3.new(2, 12, 2), frame * CFrame.new(gateGap / 2, 6, -half), WOOD)
			anchor = part(folder, "Sign", Vector3.new(gateGap + 4, 3, 1), frame * CFrame.new(0, 12, -half), DARKWOOD)
		elseif area.id == "hatchery" then
			part(folder, "Nest", Vector3.new(3, 18, 18), cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(214, 176, 92), Enum.PartType.Cylinder, Enum.Material.Fabric)
			for k = 1, 4 do
				local a = k * math.pi / 2
				part(folder, "Egg", Vector3.new(3, 4, 3), cf * CFrame.new(math.cos(a) * 4, 4, math.sin(a) * 4), Color3.fromRGB(250, 246, 236), Enum.PartType.Ball)
			end
			anchor = folder:FindFirstChild("Nest") :: BasePart
		end
		local text = if area.id == "gate" then "Plot " .. plot else AREA_NAMES[area.id]
		label(anchor, text, if area.id == "gate" then 5 else 16)
	end
	folder.Parent = root
end

-- ===== the Market =====
local function buildMarket()
	local m = Instance.new("Model")
	m.Name = "Market"
	local frame = Layout.marketFrame()
	-- Stalls in an arc around the fountain; the open side faces the valley.
	local function stall(name: string, text: string, x: number, z: number, roof: Color3)
		local cf = frame * CFrame.new(x, 0, z) * CFrame.Angles(0, math.pi, 0)
		part(m, name .. "Counter", Vector3.new(16, 4, 6), cf * CFrame.new(0, 2, 0), WOOD)
		for _, px in { -7.5, 7.5 } do
			part(m, name .. "Post", Vector3.new(1, 10, 1), cf * CFrame.new(px, 5, 2.5), DARKWOOD)
		end
		wedge(m, name .. "Awning", Vector3.new(18, 3, 9), cf * CFrame.new(0, 11.5, 0) * CFrame.Angles(0, math.pi, 0), roof)
		local anchor = m:FindFirstChild(name .. "Counter") :: BasePart
		label(anchor, text, 14)
	end
	stall("Shop", "Shop", -50, 40, ROYAL)
	stall("Merchant", "Merchant", 50, 40, Color3.fromRGB(150, 70, 160))
	for i = 1, 4 do
		stall("Trade" .. i, "Trading Stall", -54 + (i - 1) * 36, 66, CREAM)
	end
	-- The Smithy: a stone forge with a chimney.
	hut(m, "Smithy", frame * CFrame.new(0, 0, 58), 24, 14, 18, Color3.fromRGB(150, 140, 130), DARKWOOD)
	part(m, "Forge", Vector3.new(4, 16, 4), frame * CFrame.new(8, 20, 60), Color3.fromRGB(110, 100, 96))
	label(m:FindFirstChild("SmithyWalls") :: BasePart, "Smithy", 18)
	-- Notice board.
	local board = part(m, "Board", Vector3.new(14, 9, 1), frame * CFrame.new(-80, 6, 10), WOOD)
	label(board, "Leaderboard", 8)
	-- The fountain and the spawn.
	part(m, "FountainBase", Vector3.new(3, 22, 22), frame * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(220, 214, 200), Enum.PartType.Cylinder)
	local top = part(m, "FountainTop", Vector3.new(8, 4, 4), frame * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.PartType.Cylinder)
	label(top, "Market", 10)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = frame * CFrame.new(0, 0.5, -22)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Parent = m
	m.Parent = root
end

-- ===== the Wild Garden =====
local LEAVES = {
	meadow = Color3.fromRGB(110, 190, 80),
	mushroom = Color3.fromRGB(150, 90, 200),
	ember = Color3.fromRGB(226, 110, 52),
	frost = Color3.fromRGB(230, 240, 250),
}

local function buildWild()
	local w = Instance.new("Folder")
	w.Name = "WildGarden"
	-- The Heart's altar stones.
	for k = 1, 8 do
		local a = Layout.polar(k * 45, M.HeartRadius - 4)
		part(w, "Stone", Vector3.new(4, 7, 4), CFrame.new(a + Vector3.new(0, 3.5, 0)), Color3.fromRGB(200, 190, 170), nil, Enum.Material.Slate)
	end
	label(w:FindFirstChild("Stone") :: BasePart, "The Heart (World Boss)", 8)
	-- Trees (or giant mushrooms) per quarter; goo springs where monsters bubble up.
	for _, quarter in Layout.Quarters do
		for _ = 1, 22 do
			local angle = quarter.angle + rng:NextNumber(-38, 38)
			local r = rng:NextNumber(M.HeartRadius + 30, M.WildRadius - 12)
			local pos = Layout.polar(angle, r)
			if math.abs((angle % 90) - 45) < 40 then
				tree(w, pos, rng:NextNumber(0.8, 1.4), LEAVES[quarter.id], quarter.id)
			end
		end
		for s = 1, 3 do
			local pos = Layout.polar(quarter.angle + (s - 2) * 22, M.WildRadius * (0.35 + s * 0.17))
			local spring = part(w, "GooSpring", Vector3.new(0.6, 9, 9), CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 220, 170), Enum.PartType.Cylinder, Enum.Material.Glass)
			spring.Transparency = 0.25
		end
		local marker = part(w, "QuarterMarker", Vector3.new(1, 1, 1), CFrame.new(Layout.polar(quarter.angle, M.WildRadius * 0.55) + Vector3.new(0, 1, 0)), Color3.new(1, 1, 1))
		marker.Transparency = 1
		local names = { meadow = "Sunny Meadow", mushroom = "Mushroom Grove", ember = "Ember Garden", frost = "Frost Glade" }
		label(marker, names[quarter.id], 22)
	end
	w.Parent = root
end

local function buildRimTrees()
	local f = Instance.new("Folder")
	f.Name = "RimTrees"
	for angle = 0, 359, 7 do
		local r = M.FloorRadius + rng:NextNumber(-6, 26)
		tree(f, Layout.polar(angle + rng:NextNumber(-3, 3), r), rng:NextNumber(1.2, 2), Color3.fromRGB(70, 150, 70), "rim")
	end
	f.Parent = root
end

local function lighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(118, 108, 96)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 142, 130)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	for _, c in Lighting:GetChildren() do
		if c:IsA("PostEffect") or c:IsA("Atmosphere") then
			c:Destroy()
		end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.26
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(205, 228, 255)
	atmosphere.Decay = Color3.fromRGB(120, 150, 190)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Threshold = 1.5
	bloom.Size = 24
	bloom.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.Contrast = 0.05
	cc.Parent = Lighting
end

for plot = 1, M.PlotCount do
	buildPlot(plot)
	task.wait()
end
buildMarket()
buildWild()
buildRimTrees()
lighting()
root.Parent = workspace
return "greybox built: " .. #root:GetDescendants() .. " instances"
