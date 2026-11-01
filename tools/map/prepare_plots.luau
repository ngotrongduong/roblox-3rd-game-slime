-- Gets the seven other home plots ready to receive a copy of the hand-built village (the owner, 2026-11-02: up to 8 players,
-- a plot each; src/server/Plots.luau copies workspace.Map.Plot5 into a player's plot when they join). Run once in the work
-- place, in Edit mode, through Studio's MCP, after the hand-built plot's terrain exists (stud_floor and pond_water_l1 on plot 5):
--   node tools/studio_mcp.js run tools/map/prepare_plots.luau <studio_id> Edit
-- Then save the place (Ctrl+S, by the owner). Rerunnable: it gives the same result each time.
--
-- What it does, for every plot except Config.Plots.TemplatePlot (the hand-built one is left as it is):
--   1. the greybox in workspace.Map.Plot<n> goes (its children are destroyed; the empty Model stays, as the container the
--      server fills); everything that is not a plot (Market, WildGarden, RimTrees, the other plots) is kept;
--   2. its terrain gets what plot 5 has: the same ground as tools/map/stud_floor.luau (flat under the plot, sunk to y = -2
--      under the floor tiles, a ring of grass raised to the floor's height round it) and the same pond as
--      tools/map/pond_water_l1.luau (the three lobes of the fishing pond, sand at the bottom, real water), placed by the
--      plot's own frames, so the copy of the village (turned about the valley centre by Layout.plotTurn) sits on a
--      pond basin exactly where its fishing pond is.
-- The stud floor itself is part of the village (Plot5.StudLawn) and comes with every copy. An empty plot shows one flat
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
local function flatten(plot: number)
	local plotFrame = Layout.plotFrame(plot)
	local flat = plotFrame - Vector3.new(0, plotFrame.Position.Y, 0)
	-- Only the plot itself is cut down; a ring of grass round it is raised to the floor's height, so the ground outside the
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
			Enum.Material.Grass
		)
		terrain:FillBlock(
			flat * CFrame.new(0, -3.7, side * (half + RING / 2)),
			Vector3.new(half * 2, 8.6, RING),
			Enum.Material.Grass
		)
	end
	terrain:FillBlock(flat + Vector3.new(0, 4, 0), Vector3.new(half * 2, 12, half * 2), Enum.Material.Air)
	terrain:FillBlock(flat + Vector3.new(0, -6, 0), Vector3.new(half * 2, 8, half * 2), Enum.Material.Grass)
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
	if plot ~= TEMPLATE then
		local removed = emptyContainer(plot)
		flatten(plot)
		task.wait()
		pond(plot)
		task.wait()
		table.insert(summary, plot .. ":" .. removed)
	end
end
-- (the hand-built plot keeps its terrain and its model; the server moves the model out of the world when a game starts)
return "plots prepared (plot:greybox pieces removed) " .. table.concat(summary, " ") .. "; plot " .. TEMPLATE .. " untouched"
