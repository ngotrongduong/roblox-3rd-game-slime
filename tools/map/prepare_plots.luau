-- Gets the ground of the eight home plots ready to receive a copy of the hand-built village (the owner, 2026-11-02: up to 8
-- players, a plot each; src/server/Plots.luau copies workspace.Map.Plot<Config.Plots.TemplatePlot> into a player's plot when
-- they join). Run once in the work place, in Edit mode, through Studio's MCP, after the code is synced (it reads Layout):
--   node tools/studio_mcp.js run tools/map/prepare_plots.luau <studio_id> Edit
-- Then save the place. Rerunnable: it gives the same result each time.
--
-- What it does, for every plot (in the big world every plot stands on a flat pad of plain land, the hand-built one too):
--   1. the plots other than the hand-built one become empty containers (workspace.Map.Plot<n>, the Model the server fills);
--   2. the terrain gets what the hand-built village was made on: the ground of tools/map/stud_floor.luau (flat under the
--      plot, sunk to y = -2 under the floor tiles, a ring of the land's own ground raised to the floor's height round it) and
--      the pond of tools/map/pond_water_l1.luau (the three lobes of the fishing pond, sand at the bottom, real water),
--      placed by the plot's own frames, so the copy of the village (moved by Layout.plotTurn) sits on a pond basin exactly
--      where its fishing pond is.
-- The stud floor itself is part of the village (StudLawn) and comes with every copy. An empty plot shows one flat
-- stud-lawn part over the sunken ground (made by the server in play, never saved here), so it looks like plain ground; the
-- pond lobes that open at fishing levels 21 and 41 are carved at run time by PondStages.grow, as they always were.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)

local TEMPLATE = Config.Plots.TemplatePlot
local GROUND = Config.Map.GroundY or 2
local RING = 16
-- the pond, fishing-area local x, z, r (src/server/PondStages LOBES, the village scale)
local LOBES = { { 0, 6.5, 20.8 }, { 11.7, 14.3, 14.3 }, { -11.7, 2.6, 14.3 } }
local terrain = workspace.Terrain
local half = Config.Map.PlotSize / 2

local map = workspace:FindFirstChild("Map")
if not map then
	error("workspace.Map is missing: build the map first")
end

-- ===== 1. an empty container =====
local function emptyContainer(plot: number): number
	local found = map:FindFirstChild("Plot" .. plot)
	local removed = 0
	if found and found:IsA("Model") then
		removed = #found:GetChildren()
		found:ClearAllChildren()
	else
		if found then
			found:Destroy()
		end
		found = Instance.new("Model")
		found.Name = "Plot" .. plot
		found.Parent = map
	end
	found:SetAttribute("Plot", plot)
	return removed
end

-- ===== 2. the ground, as stud_floor.luau lays it =====
local onlyTerrain = RaycastParams.new()
onlyTerrain.FilterType = Enum.RaycastFilterType.Include
onlyTerrain.FilterDescendantsInstances = { terrain }

local function flatten(plot: number)
	local plotFrame = Layout.plotFrame(plot)
	local flat = plotFrame - Vector3.new(0, plotFrame.Position.Y, 0)
	-- the ring keeps the ground the land has there (read just outside it, behind the plot: a road comes to its front)
	local outside = (flat * CFrame.new(0, 0, half + RING + 8)).Position
	local hit = workspace:Raycast(outside + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), onlyTerrain)
	local ground = if hit and hit.Material ~= Enum.Material.Water then hit.Material else Enum.Material.Grass
	-- Only the plot itself is cut down; a ring of ground round it is raised to the floor's height, so the land outside the
	-- fence meets the stud floor with no step. Whole 4-stud voxels only: air from y = -2 up, ground below.
	for _, side in { -1, 1 } do
		terrain:FillBlock(
			flat * CFrame.new(side * (half + RING / 2), 6, 0),
			Vector3.new(RING, 12, half * 2 + RING * 2),
			Enum.Material.Air
		)
		terrain:FillBlock(
			flat * CFrame.new(0, 6, side * (half + RING / 2)),
			Vector3.new(half * 2, 12, RING),
			Enum.Material.Air
		)
		terrain:FillBlock(
			flat * CFrame.new(side * (half + RING / 2), -3.7, 0),
			Vector3.new(RING, 8.6, half * 2 + RING * 2),
			ground
		)
		terrain:FillBlock(flat * CFrame.new(0, -3.7, side * (half + RING / 2)), Vector3.new(half * 2, 8.6, RING), ground)
	end
	terrain:FillBlock(flat + Vector3.new(0, 4, 0), Vector3.new(half * 2, 12, half * 2), Enum.Material.Air)
	terrain:FillBlock(flat + Vector3.new(0, -6, 0), Vector3.new(half * 2, 8, half * 2), ground)
end

-- ===== 3. the pond, as pond_water_l1.luau fills it =====
local function pond(plot: number)
	local top = GROUND - 0.3 -- the water's surface, just under the floor
	local area = Layout.plotAreaFacing(plot, -1, 1)
	for _, l in LOBES do
		local p = (area * CFrame.new(l[1], 0, l[2])).Position
		local c = CFrame.new(p.X, 0, p.Z)
		local deep = 6
		terrain:FillCylinder(c + Vector3.new(0, top - deep - 2, 0), 4, l[3], Enum.Material.Sand)
		-- (a water fill does not replace solid terrain, so the ground is cleared to air first)
		terrain:FillCylinder(c + Vector3.new(0, top - deep / 2, 0), deep, l[3] + 3, Enum.Material.Air)
		terrain:FillCylinder(c + Vector3.new(0, top - deep / 2, 0), deep, l[3] + 3, Enum.Material.Water)
		terrain:FillCylinder(c + Vector3.new(0, top - deep - 0.5, 0), 1, l[3] * 0.6, Enum.Material.Water)
	end
end

local summary = {}
for plot = 1, Config.Map.PlotCount do
	local removed = if plot == TEMPLATE then 0 else emptyContainer(plot)
	flatten(plot)
	task.wait()
	pond(plot)
	task.wait()
	table.insert(summary, plot .. ":" .. removed)
end
return "plots prepared (plot:greybox pieces removed) " .. table.concat(summary, " ") .. "; the village of plot " .. TEMPLATE .. " untouched"
