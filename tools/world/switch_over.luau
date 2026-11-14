-- The one move that takes the game out of the old valley into the big world (docs/WORLD.md, M4). Run in the work place,
-- in Edit mode, after the code is synced (it reads Layout):
--   node tools/studio_mcp.js run tools/world/switch_over.luau <studio_id> Edit
-- Rerunnable: a piece that has moved carries an attribute and is left alone.
--   1. the hand-built village, workspace.Map.Plot<Config.Plots.TemplatePlot>, goes from its place on the old valley's rim
--      to its own plot's frame in the new world, with the world positions kept in attributes inside it
--      (Config.Plots.Turned) and the DevSpawn that stood in it;
--   2. the old valley's scenery (Map.WildGarden, Map.RimTrees) is parked in ServerStorage.OldValley: out of the game,
--      still in the file;
--   3. the old valley's terrain is cleared (the file as it was before the move is kept outside the repo).
-- The Market is moved by tools/world/build_sites.luau, the ground under the plots is made by
-- tools/map/prepare_plots.luau: run both after this, then save the place.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
assert(
	ReplicatedStorage.Shared:FindFirstChild("WorldPlan"),
	"ReplicatedStorage.Shared is the old valley's: sync the code first"
)

-- The old valley: nine slots (the Market and eight plots) on a rim round the origin, each facing the middle.
local OLD_RADIUS = 500
local OLD_SLOTS = 9

local map = workspace:FindFirstChild("Map")
assert(map, "workspace.Map is missing")
local report = {}

-- ===== 1. the hand-built village =====
local plot = Config.Plots.TemplatePlot
local village = map:FindFirstChild("Plot" .. plot)
assert(village and village:IsA("Model"), "the hand-built village Map.Plot" .. plot .. " is missing")
if village:GetAttribute("InWorld") then
	table.insert(report, "village already in the world")
else
	local angle = math.rad(plot * 360 / OLD_SLOTS)
	local old = CFrame.new(math.sin(angle) * OLD_RADIUS, 0, -math.cos(angle) * OLD_RADIUS) * CFrame.Angles(0, math.pi - angle, 0)
	local move = Layout.plotFrame(plot) * old:Inverse()
	village:PivotTo(move * village:GetPivot())
	task.wait()
	local turned = 0
	for _, d in village:GetDescendants() do
		for tag, names in Config.Plots.Turned do
			if d:IsA("Model") and CollectionService:HasTag(d, tag) then
				for _, name in names do
					local value = d:GetAttribute(name)
					if typeof(value) == "Vector3" then
						d:SetAttribute(name, move * value)
						turned += 1
					end
				end
			end
		end
	end
	local spawn = workspace:FindFirstChild("DevSpawn")
	if spawn and spawn:IsA("SpawnLocation") then
		spawn.CFrame = move * spawn.CFrame
	end
	village:SetAttribute("InWorld", true)
	local at = village:GetPivot().Position
	table.insert(report, string.format("village moved to (%.0f, %.0f, %.0f), %d positions turned", at.X, at.Y, at.Z, turned))
end

-- ===== 2. the old valley's scenery leaves the game =====
local parked = ServerStorage:FindFirstChild("OldValley")
for _, name in { "WildGarden", "RimTrees" } do
	local found = map:FindFirstChild(name)
	if found then
		if not parked then
			parked = Instance.new("Folder")
			parked.Name = "OldValley"
			parked.Parent = ServerStorage
		end
		found.Parent = parked
		task.wait()
		table.insert(report, name .. " parked")
	end
end

-- ===== 3. the old valley's ground goes =====
-- It lay round the origin (measured: x -960..920, z -920..920, top 129) and showed from the new world as a slab on the
-- south horizon. The labs of the work place float above it (y 299 and up) and are not touched.
local OLD = { half = 1040, bottom = -256, top = 280, step = 260 }
local terrain = workspace.Terrain
local onlyTerrain = RaycastParams.new()
onlyTerrain.FilterType = Enum.RaycastFilterType.Include
onlyTerrain.FilterDescendantsInstances = { terrain }
local cleared = 0
for x = -OLD.half + OLD.step / 2, OLD.half, OLD.step do
	for z = -OLD.half + OLD.step / 2, OLD.half, OLD.step do
		local some = false
		for dx = -OLD.step / 2, OLD.step / 2, 20 do
			for dz = -OLD.step / 2, OLD.step / 2, 20 do
				if workspace:Raycast(Vector3.new(x + dx, OLD.top, z + dz), Vector3.new(0, OLD.bottom - OLD.top, 0), onlyTerrain) then
					some = true
					break
				end
			end
			if some then
				break
			end
		end
		if some then
			terrain:FillBlock(
				CFrame.new(x, (OLD.top + OLD.bottom) / 2, z),
				Vector3.new(OLD.step, OLD.top - OLD.bottom, OLD.step),
				Enum.Material.Air
			)
			cleared += 1
			task.wait()
		end
	end
end
table.insert(report, "old valley ground cleared in " .. cleared .. " blocks")

return table.concat(report, "; ")
