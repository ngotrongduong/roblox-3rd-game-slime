-- The classic Roblox stud look for a home plot (the owner, 2026-10-27: "players seem to prefer
-- Roblox's stud texture"). The whole plot is floored with Plastic tiles whose top surface is the
-- legacy Studs surface (it still renders; an image Texture from a stud decal id did not):
--   * 8 x 8 grass tiles over the open lawn,
--   * a 2 x 2 grid over the fishing cell, leaving the pond's lobes open as a sunken pool with a
--     ring of sand-coloured tiles at its edge (stepped stud edges, the classic look),
--   (areas lay their own floors on top of it)
-- The terrain under the plot is flattened to y = 0 so nothing pokes through; the real
-- terrain water of the pond fills the pool (pond_water_l1, run after this). Run after the area builders,
-- dress_plot_nature and build_village. Rerunnable.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local PLOT = 5
local GROUND = Config.Map.GroundY or 2 -- the floor's top (or 2 in a work place with an older Config)
local THICK = 2 -- tiles reach down to GROUND - THICK, so the pool shows green walls
local COARSE, FINE = 8, 2
local GRASS = Color3.fromRGB(104, 178, 62)
local SAND = Color3.fromRGB(232, 206, 142)
local LOBES = { { 0, 5, 16 }, { 9, 11, 11 }, { -9, 2, 11 } } -- the pond, fishing-area local x, z, r

local half = Config.Map.PlotSize / 2
local plotFrame = Layout.plotFrame(PLOT)
local plot = workspace.Map["Plot" .. PLOT]
local fishing = Layout.plotAreaFacing(PLOT, -1, 1)

-- ===== terrain: flat at y = 0 under the whole plot =====
-- Whole 4-stud voxels only (centres on multiples of 4): air from y = -2 up, ground below, so the
-- terrain's surface is at -2, hidden under the tiles (a half-voxel fill came up through them).
local terrain = workspace.Terrain
local flat = plotFrame - Vector3.new(0, plotFrame.Position.Y, 0)
-- Only the plot itself is cut down; a ring of grass round it is then raised to the floor's height,
-- so the ground outside the fence meets the stud floor with no step (a fill up to y = 0.6 leaves the
-- top voxel a little filled, its surface at about y = 2, the floor's top; measured) (the owner, 2026-10-27: the
-- plot's edge and the foot of the fence showed).
local RING = 16
for _, side in { -1, 1 } do
	-- (cleared first: a higher fill of an earlier run would stay)
	terrain:FillBlock(flat * CFrame.new(side * (half + RING / 2), 6, 0), Vector3.new(RING, 12, half * 2 + RING * 2), Enum.Material.Air)
	terrain:FillBlock(flat * CFrame.new(0, 6, side * (half + RING / 2)), Vector3.new(half * 2, 12, RING), Enum.Material.Air)
	terrain:FillBlock(flat * CFrame.new(side * (half + RING / 2), -3.7, 0), Vector3.new(RING, 8.6, half * 2 + RING * 2), Enum.Material.Grass)
	terrain:FillBlock(flat * CFrame.new(0, -3.7, side * (half + RING / 2)), Vector3.new(half * 2, 8.6, RING), Enum.Material.Grass)
end
terrain:FillBlock(flat + Vector3.new(0, 4, 0), Vector3.new(half * 2, 12, half * 2), Enum.Material.Air)
terrain:FillBlock(flat + Vector3.new(0, -6, 0), Vector3.new(half * 2, 8, half * 2), Enum.Material.Grass)
task.wait()

local old = plot:FindFirstChild("StudLawn")
if old then
	old:Destroy()
end
local floor = Instance.new("Model")
floor.Name = "StudLawn"

local count = 0
local function tile(cf: CFrame, size: number, colour: Color3, drop: number?)
	local t = Instance.new("Part")
	t.Name = "Tile"
	t.Size = Vector3.new(size, THICK, size)
	t.CFrame = cf * CFrame.new(0, GROUND - (drop or 0) - THICK / 2, 0)
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
			-- (areas lay their own floors on top: the garden its earth, the village its plaza and paths)
			tile(plotFrame * CFrame.new(x, 0, z), COARSE, GRASS)
		end
	end
end
task.wait()

-- (the fishing area is turned to face the plot's middle, so each fine tile is measured in its frame)
for x = FISH_MIN + FINE / 2, half - FINE / 2, FINE do
	for z = FISH_MIN + FINE / 2, half - FINE / 2, FINE do
		local p = fishing:PointToObjectSpace((plotFrame * CFrame.new(x, 0, z)).Position)
		local d = pondDistance(p.X, p.Z)
		-- the bank steps down to the water in two sand steps: terrain water fills whole 4-stud voxels,
		-- so its surface sits near y = 0, two studs under the floor (the owner: hide the grass walls)
		if d > 0 then
			if d < 1.2 then
				tile(plotFrame * CFrame.new(x, 0, z), FINE, SAND, 1.6)
			elseif d < 2.4 then
				tile(plotFrame * CFrame.new(x, 0, z), FINE, SAND, 0.8)
			else
				tile(plotFrame * CFrame.new(x, 0, z), FINE, GRASS)
			end
		end
	end
end
-- The floor stops a stud short of the plot's edge, so its side is hidden inside the fence that stands
-- on the edge (the owner, 2026-10-27: a strip of green floor showed under the fence).
local LIMIT = half - 1
for _, t in floor:GetChildren() do
	local p = plotFrame:PointToObjectSpace(t.Position)
	local lo = Vector3.new(p.X - t.Size.X / 2, 0, p.Z - t.Size.Z / 2)
	local hi = Vector3.new(p.X + t.Size.X / 2, 0, p.Z + t.Size.Z / 2)
	local lo2 = Vector3.new(math.max(lo.X, -LIMIT), 0, math.max(lo.Z, -LIMIT))
	local hi2 = Vector3.new(math.min(hi.X, LIMIT), 0, math.min(hi.Z, LIMIT))
	if lo2 ~= lo or hi2 ~= hi then
		local mid = (lo2 + hi2) / 2
		t.Size = Vector3.new(hi2.X - lo2.X, t.Size.Y, hi2.Z - lo2.Z)
		t.CFrame = plotFrame * CFrame.new(mid.X, p.Y, mid.Z)
	end
end
floor.Parent = plot

-- (the pool's water is real terrain water, filled by pond_water_l1 after this script)


local test = workspace:FindFirstChild("StudTest")
if test then
	test:Destroy()
end
return "stud floor: " .. count .. " tiles"
