-- Checks the hand-built village (the template, workspace.Map.Plot5) so that no tree, bush or small plant of its scenery stands where
-- any upgrade puts a piece at ANY level of ANY area, nor in the way of a path, a door, a work place or a slime's lane (the owner,
-- 2026-11-02: the trees and bushes of the village use the valley's assets; every area and the village change their props by level).
-- Run in Edit mode through Studio's MCP, with the library text handed over as LIB:
--   node tools/studio_mcp.js run tools/map/check_village_trees.luau <studio_id> Edit LIB=tools/map/village_footprints.luau
-- It prints VILLAGE TREES OK, or one line a clash. Read only (the stages run on a clone of the template).
--
-- How the footprints are gathered (tools/map/village_footprints.luau): the stage modules of the pond, garden, pantry, kitchen,
-- breeding house, training ground (50 levels each) and of the village (50 levels: fence, gate, plaza, paths, lamps, benches, stalls)
-- are run level by level on a clone, as AreaUpgrade runs them, and every part of every layer is put in a one-stud grid with the
-- heights it fills; with the plot's own parts, the scenery that stays, the pond's water (grown lobes too), the pads and entrances
-- with working room, and the stages' invisible markers (work spots, nests). A plant's trunk, low branches and bush are tested against
-- it with a margin by kind (a lane keeps a slime's step), a crown may overhang only when it clears the head of what is below by 1.5.
-- Also reported: scenery an upgrade removes or moves (the existing mechanisms of PantryStages, PondStages, GardenStages), and village
-- pieces that find no room because of the scenery (VillageStages' "Skipped") but would find it without.
local ServerStorage = game:GetService("ServerStorage")

if not LIB then
	error("hand over the library: ... run tools/map/check_village_trees.luau <id> Edit LIB=tools/map/village_footprints.luau")
end
local holder = Instance.new("ModuleScript")
holder.Name = "VillageFootprintsLib"
holder.Source = LIB
holder.Parent = ServerStorage
local lib = require(holder)
holder:Destroy()

local began = os.clock()
local template = workspace.Map:FindFirstChild("Plot" .. lib.TEMPLATE)
if not template then
	error("workspace.Map.Plot" .. lib.TEMPLATE .. " (the village template) is missing")
end
local grid, info = lib.gather({ template = template })
local lines = {}
local problems = 0
local inverse = lib.frame:Inverse()

-- every tree, bush and small plant of the scenery
local seen = { tree = 0, bush = 0, small = 0 }
local profiles: { [string]: any } = {}
for _, folder in lib.sceneryFolders(template) do
	for _, item in folder:GetChildren() do
		local class = lib.classify(item)
		if class and (item:IsA("Model") or item:IsA("BasePart")) then
			seen[class] += 1
			local q = inverse * item:GetPivot()
			local profile = lib.profile(item)
			local text = lib.clash(grid, profile, class, q.Position.X, q.Position.Z)
			if text then
				problems += 1
				if problems <= 80 then
					table.insert(
						lines,
						string.format("CLASH %s %s (%s) at (%.1f, %.1f): %s", folder.Parent and folder.Parent.Name or "?", item.Name, class, q.Position.X, q.Position.Z, text)
					)
				end
			end
		end
	end
	task.wait()
end

-- scenery the pond's growth takes away (PondStages.grow: the water, the shore life, the parts built at the shore): the real rule, at level 50
do
	local Layout = require(game:GetService("ReplicatedStorage").Shared.Layout)
	local P = require(game:GetService("ServerScriptService").Server.PondStages)
	local pond = template:FindFirstChild("FishingPondL1")
	local nature = pond and pond:FindFirstChild("Nature")
	local pframe = Layout.plotAreaFacing(lib.TEMPLATE, -1, 1)
	for _, n in (if nature then nature:GetChildren() else {}) do
		if lib.classify(n) and n:IsA("Model") and n.Name ~= "WaterLily" then
			local q = pframe:PointToObjectSpace(n:GetPivot().Position)
			if P.clears(q.X, q.Z, 50) then
				problems += 1
				table.insert(lines, string.format("UPGRADE REMOVED: %s (%s) in the pond's scenery is cleared by PondStages.grow at level 50", n.Name, n:GetAttribute("Role") or lib.classify(n)))
			end
		end
	end
end

-- scenery the stages remove or move
local byWhat = 0
for _, r in info.removed do
	byWhat += 1
	problems += 1
	if byWhat <= 40 then
		table.insert(lines, string.format("UPGRADE %s: %s %s (%s) at (%.1f, %.1f) by the %s stage at level %d", string.upper(r.what), r.name, "", r.role, r.x, r.z, r.by, r.level))
	end
end

-- village pieces that the scenery crowds out
local crowded = 0
for level, real in info.skippedReal do
	local ideal = info.skippedIdeal[level] or ""
	for entry in string.gmatch(real, "%S+") do
		if not string.find(ideal, entry, 1, true) then
			crowded += 1
			problems += 1
			table.insert(lines, string.format("CROWDED village level %d: %s found no room (it would with no scenery)", level, entry))
		end
	end
end

table.insert(
	lines,
	string.format(
		"checked %d trees, %d bushes, %d small plants against %d footprint cells from %d stage builds (%.0f s)",
		seen.tree,
		seen.bush,
		seen.small,
		info.cells,
		info.builds,
		os.clock() - began
	)
)
if problems == 0 then
	table.insert(lines, "VILLAGE TREES OK")
else
	table.insert(lines, string.format("%d problems", problems))
end
return table.concat(lines, "\n")
