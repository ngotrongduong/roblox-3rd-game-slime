-- Builds the Goo Valley's terrain in the open Studio place from Shared.Layout and Config.Map
-- (docs/MAP.md). Run it in Edit mode through Studio's MCP (execute_luau); it clears the terrain
-- first, so running it again gives the same valley. Yields between chunks to keep Studio alive.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local M = Config.Map
local terrain = workspace.Terrain
local rng = Random.new(20261027)

-- Cartoon palette matching the owner's paintings: saturated, warm, soft.
local COLOURS = {
	[Enum.Material.Grass] = Color3.fromRGB(126, 196, 72),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(168, 214, 84),
	[Enum.Material.Sandstone] = Color3.fromRGB(214, 180, 120),
	[Enum.Material.Mud] = Color3.fromRGB(74, 112, 96),
	[Enum.Material.Ground] = Color3.fromRGB(176, 102, 66),
	[Enum.Material.Snow] = Color3.fromRGB(236, 244, 252),
	[Enum.Material.Limestone] = Color3.fromRGB(226, 208, 168),
	[Enum.Material.Rock] = Color3.fromRGB(138, 132, 122),
	[Enum.Material.Sand] = Color3.fromRGB(232, 210, 150),
	[Enum.Material.CrackedLava] = Color3.fromRGB(232, 96, 40),
	[Enum.Material.Basalt] = Color3.fromRGB(92, 70, 64),
}

-- The ground of each Wild Garden quarter.
local QUARTER_MATERIAL = {
	meadow = Enum.Material.LeafyGrass,
	mushroom = Enum.Material.Mud,
	ember = Enum.Material.Ground,
	frost = Enum.Material.Snow,
}

local function setLook()
	for material, colour in COLOURS do
		terrain:SetMaterialColor(material, colour)
	end
	terrain.WaterColor = Color3.fromRGB(70, 170, 210)
	terrain.WaterTransparency = 0.35
	terrain.WaterWaveSize = 0.08
	terrain.WaterWaveSpeed = 6
	terrain.WaterReflectance = 0.4
end

local function floor()
	-- The valley floor: grass, top at y = 0, out to under the hills.
	terrain:Clear()
	task.wait()
	terrain:FillCylinder(CFrame.new(0, -8, 0), 16, M.HillOuterRadius + 80, Enum.Material.Grass)
	task.wait()
end

local function hills()
	-- A ring of round hills closes the valley in; rock shows on the steeper outer ones.
	local count = 0
	for angle = 0, 359, 4 do
		for _ = 1, 3 do
			local r = rng:NextNumber(M.FloorRadius + 50, M.HillOuterRadius + 20)
			local size = rng:NextNumber(36, 64) * (0.7 + (r - M.FloorRadius) / (M.HillOuterRadius - M.FloorRadius) * 0.6)
			local height = (r - M.FloorRadius) / (M.HillOuterRadius - M.FloorRadius) * M.HillHeight
			local pos = Layout.polar(angle + rng:NextNumber(-2, 2), r) + Vector3.new(0, height - size * 0.55, 0)
			local material = if rng:NextNumber() < 0.18 then Enum.Material.Rock else Enum.Material.Grass
			terrain:FillBall(pos, size, material)
			count += 1
		end
		if angle % 40 == 0 then
			task.wait()
		end
	end
	-- An outer wall of leafy forest hills, so no edge of the world shows.
	for angle = 0, 359, 6 do
		local pos = Layout.polar(angle, M.HillOuterRadius + 60) + Vector3.new(0, M.HillHeight * 0.6, 0)
		terrain:FillBall(pos, rng:NextNumber(60, 80), Enum.Material.Grass)
	end
	task.wait()
	return count
end

-- Paints the top layer (keeps the ground flat). It is one whole 4-stud voxel deep: a thinner
-- fill leaves a full grass voxel grass.
local function paint(cf: CFrame, size: Vector3, material: Enum.Material)
	local deep = Vector3.new(size.X, 4, size.Z)
	terrain:FillBlock(cf * CFrame.new(0, -2, 0), deep, material)
end

local function wildGarden()
	-- Quarters: each 8-stud cell takes its quarter's ground; the borders wobble so they look grown.
	local cell = 8
	local n = 0
	for x = -M.WildRadius, M.WildRadius, cell do
		for z = -M.WildRadius, M.WildRadius, cell do
			local pos = Vector3.new(x, 0, z)
			local r = pos.Magnitude
			if r <= M.WildRadius then
				local angle = (math.deg(math.atan2(x, -z)) + math.noise(x / 60, z / 60) * 22) % 360
				local quarter = Layout.Quarters[math.floor(angle / 90) + 1]
				paint(CFrame.new(pos), Vector3.new(cell, 4, cell), QUARTER_MATERIAL[quarter.id])
				n += 1
				if n % 400 == 0 then
					task.wait()
				end
			end
		end
	end
	-- The Heart: a pale stone clearing with a goo spring in the middle.
	terrain:FillCylinder(CFrame.new(0, -1.5, 0), 3, M.HeartRadius, Enum.Material.Limestone)
	terrain:FillCylinder(CFrame.new(0, -3, 0), 6, 12, Enum.Material.Air)
	terrain:FillCylinder(CFrame.new(0, -4, 0), 4, 12, Enum.Material.Water)
	-- The two Duel Rings at the Heart's south side.
	for _, angle in { 160, 200 } do
		local pos = Layout.polar(angle, M.DuelRingDistance)
		terrain:FillCylinder(CFrame.new(pos + Vector3.new(0, -1, 0)), 2, M.DuelRingRadius, Enum.Material.Sand)
	end
	task.wait()
end

local function streams()
	-- Four streams run from near the Heart to the Wild Garden's rim along the quarter borders,
	-- winding a little; the ember one runs with warm lava between stone banks instead of water.
	for _, angle in { 0, 90, 180, 270 } do
		for r = M.HeartRadius + 16, M.WildRadius - 6, 3 do
			local wobble = math.sin(r / 23 + angle) * 9
			local pos = Layout.polar(angle + math.deg(wobble / r), r)
			terrain:FillBall(pos + Vector3.new(0, -2.5, 0), 6.5, Enum.Material.Air)
			terrain:FillBall(pos + Vector3.new(0, -4.5, 0), 5.5, Enum.Material.Water)
		end
		task.wait()
	end
	-- Lava rills in the Ember Garden, kept in basalt channels (no open lava floor).
	for i = 1, 3 do
		local base = 135 + (i - 2) * 22
		for r = 90, 200, 3 do
			local pos = Layout.polar(base + math.sin(r / 17 + i) * 4, r)
			terrain:FillBall(pos + Vector3.new(0, -2, 0), 4, Enum.Material.Basalt)
			terrain:FillBall(pos + Vector3.new(0, -2.6, 0), 2.6, Enum.Material.CrackedLava)
		end
		task.wait()
	end
end

local function roads()
	-- The ring road.
	local w = M.RingRoadWidth
	for angle = 0, 359, 1.5 do
		local pos = Layout.polar(angle, M.RingRoadRadius)
		local cf = CFrame.new(pos) * CFrame.Angles(0, -math.rad(angle), 0)
		paint(cf, Vector3.new(10, 4, w), Enum.Material.Sandstone)
		if angle % 30 == 0 then
			task.wait()
		end
	end
	-- A short path from the road to each plot's gate and a wide one to the Market.
	for slot = 0, M.PlotCount do
		local angle = Layout.slotAngle(slot)
		local inner = M.RingRoadRadius
		local outer = M.RimRadius - M.PlotSize / 2 + 6
		local width = if slot == 0 then 40 else 12
		local mid = Layout.polar(angle, (inner + outer) / 2)
		local cf = CFrame.new(mid) * CFrame.Angles(0, -math.rad(angle), 0)
		paint(cf, Vector3.new(width, 4, outer - inner), Enum.Material.Sandstone)
	end
	task.wait()
end

local function plotGround()
	-- Each plot's ground is fresh grass; the Market square is paved sand.
	for slot = 0, M.PlotCount do
		local frame = Layout.slotFrame(slot)
		if slot == 0 then
			paint(frame, Vector3.new(M.MarketWidth, 3, M.MarketDepth), Enum.Material.Sand)
		else
			-- A pond at the back-left corner, where the fishing area is.
			local pond = Layout.plotAreaFrame(slot, -1, 1)
			terrain:FillCylinder(pond * CFrame.new(0, -3, 0), 6, 18, Enum.Material.Air)
			terrain:FillCylinder(pond * CFrame.new(0, -4, 0), 4, 18, Enum.Material.Water)
		end
		task.wait()
	end
end

setLook()
floor()
local hillCount = hills()
wildGarden()
streams()
roads()
plotGround()
return "terrain built: " .. hillCount .. " hill balls"
