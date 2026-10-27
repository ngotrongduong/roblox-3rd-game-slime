-- The classic Roblox stud look for a home plot (the owner, 2026-10-27: "players seem to prefer
-- Roblox's stud texture"). The whole plot is floored with Plastic tiles whose top surface is the
-- legacy Studs surface (it still renders; an image Texture from a stud decal id did not):
--   * 8 x 8 grass tiles over the open lawn,
--   * a 2 x 2 grid over the fishing cell, leaving the pond's lobes open as a sunken pool with a
--     ring of sand-coloured tiles at its edge (stepped stud edges, the classic look),
--   * earth-coloured tiles inside the garden's fence.
-- The terrain under the plot is flattened to y = 0 so nothing pokes through; the painted water
-- parts of the pond sit in the pool. Run in Edit mode through MCP after the area builders,
-- dress_plot_nature and pond_water_l1. Rerunnable.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2 -- the floor's top (or 2 in a work place with an older Config)
local THICK = 2 -- tiles reach down to GROUND - THICK, so the pool shows green walls
local COARSE, FINE = 8, 2
local GRASS = Color3.fromRGB(104, 178, 62)
local SAND = Color3.fromRGB(232, 206, 142)
local EARTH = Color3.fromRGB(150, 104, 66)
local WATER_TOP = GROUND - 0.8 -- the pool's surface, below the floor
local LOBES = { { 0, 5, 16 }, { 9, 11, 11 }, { -9, 2, 11 } } -- the pond, fishing-area local x, z, r

local half = Config.Map.PlotSize / 2
local plotFrame = Layout.plotFrame(PLOT)
local plot = workspace.Map["Plot" .. PLOT]
local fishing = Layout.plotAreaFrame(PLOT, -1, 1)
local garden = Layout.plotAreaFrame(PLOT, 1, 1)

-- ===== terrain: flat at y = 0 under the whole plot =====
-- Whole 4-stud voxels only (centres on multiples of 4): air from y = -2 up, ground below, so the
-- terrain's surface is at -2, hidden under the tiles (a half-voxel fill came up through them).
local terrain = workspace.Terrain
local flat = plotFrame - Vector3.new(0, plotFrame.Position.Y, 0)
terrain:FillBlock(flat + Vector3.new(0, 4, 0), Vector3.new(half * 2 + 8, 12, half * 2 + 8), Enum.Material.Air)
terrain:FillBlock(flat + Vector3.new(0, -6, 0), Vector3.new(half * 2 + 8, 8, half * 2 + 8), Enum.Material.Ground)
task.wait()

local old = plot:FindFirstChild("StudLawn")
if old then
	old:Destroy()
end
local floor = Instance.new("Model")
floor.Name = "StudLawn"

local count = 0
local function tile(cf: CFrame, size: number, colour: Color3)
	local t = Instance.new("Part")
	t.Name = "Tile"
	t.Size = Vector3.new(size, THICK, size)
	t.CFrame = cf * CFrame.new(0, GROUND - THICK / 2, 0)
	t.Color = colour
	t.Material = Enum.Material.Plastic
	t.TopSurface = Enum.SurfaceType.Studs
	t.BottomSurface = Enum.SurfaceType.Smooth
	t.Anchored = true
	t.CastShadow = false
	t.Parent = floor
	count += 1
end

-- How far outside the pond a point (fishing-area local) is; negative = in the water.
local function pondDistance(x: number, z: number): number
	local best = math.huge
	for _, l in LOBES do
		best = math.min(best, Vector2.new(x - l[1], z - l[2]).Magnitude - l[3])
	end
	return best
end

-- The fishing cell in plot coordinates (col -1 = +x, row 1 = +z): coarse tiles whose centre is
-- at 28 or more on both axes are replaced by the fine grid over [24, 80].
local FISH_MIN = 24
for x = -half + COARSE / 2, half - COARSE / 2, COARSE do
	for z = -half + COARSE / 2, half - COARSE / 2, COARSE do
		if not (x > FISH_MIN and z > FISH_MIN) then
			local cf = plotFrame * CFrame.new(x, 0, z)
			local g = garden:PointToObjectSpace(cf.Position)
			-- inside the garden fence (x +-13, z -9..15): earth
			local colour = if math.abs(g.X) < 13 and g.Z > -9 and g.Z < 15 then EARTH else GRASS
			tile(cf, COARSE, colour)
		end
	end
end
task.wait()

-- fishing area origin in plot coordinates (for converting the fine grid)
local fishOrigin = plotFrame:PointToObjectSpace(fishing.Position)
for x = FISH_MIN + FINE / 2, half - FINE / 2, FINE do
	for z = FISH_MIN + FINE / 2, half - FINE / 2, FINE do
		local d = pondDistance(x - fishOrigin.X, z - fishOrigin.Z)
		if d > 0 then
			tile(plotFrame * CFrame.new(x, 0, z), FINE, if d < 2.2 then SAND else GRASS)
		end
	end
end
floor.Parent = plot

-- ===== the pool's water =====
local pond = plot:FindFirstChild("FishingPondL1")
local water = pond and pond:FindFirstChild("Water")
if water then
	-- Absolute heights: a model's GetBoundingBox follows its pivot's turn, and these cylinders lie on
	-- their side, so its "height" is the pool's width. Tones by size: largest = shallow rim, lowest.
	local tones = {}
	for _, p in water:GetChildren() do
		if p.Name == "WaterTone" then
			table.insert(tones, p)
		end
	end
	table.sort(tones, function(a, b)
		return a.Size.Y > b.Size.Y
	end)
	local oldTop = if #tones > 0 then tones[#tones].Position.Y else WATER_TOP
	for i, p in tones do
		local tier = math.ceil(i * 3 / #tones) -- 1 shallow .. 3 deep
		p.Position = Vector3.new(p.Position.X, WATER_TOP - 0.06 + tier * 0.02, p.Position.Z)
	end
	local dy = WATER_TOP - oldTop
	-- a deep floor under the painted tones, so no gap shows at the pool's walls
	local bed = water:FindFirstChild("PoolBed") or Instance.new("Part")
	bed.Name = "PoolBed"
	bed.Size = Vector3.new(60, 0.4, 60)
	bed.CFrame = fishing * CFrame.new(0, WATER_TOP - 0.5 - fishing.Position.Y, 6)
	bed.Color = Color3.fromRGB(30, 110, 196)
	bed.Material = Enum.Material.SmoothPlastic
	bed.Anchored = true
	bed.CastShadow = false
	bed.Parent = water
	-- floating things follow the water
	for _, m in (pond:FindFirstChild("Nature") or pond):GetChildren() do
		if m.Name == "WaterLily" and m:IsA("Model") then
			m:PivotTo(m:GetPivot() + Vector3.new(0, dy, 0))
		end
	end
	for _, n in { "BobberTop", "BobberBottom" } do
		local b = pond:FindFirstChild(n)
		if b then
			b.Position += Vector3.new(0, dy, 0)
		end
	end
	local rod, line, bob = pond:FindFirstChild("Rod"), pond:FindFirstChild("Line"), pond:FindFirstChild("BobberTop")
	if rod and line and bob then
		local e1 = rod.Position + rod.CFrame.RightVector * rod.Size.X / 2
		local e2 = rod.Position - rod.CFrame.RightVector * rod.Size.X / 2
		local tip = if e1.Y > e2.Y then e1 else e2
		line.Size = Vector3.new(0.05, (tip - bob.Position).Magnitude, 0.05)
		line.CFrame = CFrame.lookAt((tip + bob.Position) / 2, bob.Position) * CFrame.Angles(math.rad(90), 0, 0)
	end
end

-- Blob shadows sit just on the floor.
for _, areaName in { "FishingPondL1", "GardenL1" } do
	local nature = plot:FindFirstChild(areaName) and plot[areaName]:FindFirstChild("Nature")
	if nature then
		for _, b in nature:GetChildren() do
			if b.Name == "BlobShadow" then
				b.Position = Vector3.new(b.Position.X, GROUND + 0.1, b.Position.Z)
			end
		end
	end
end

local test = workspace:FindFirstChild("StudTest")
if test then
	test:Destroy()
end
return "stud floor: " .. count .. " tiles"
