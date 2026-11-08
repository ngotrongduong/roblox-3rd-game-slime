-- Builds the Sunny Meadow in Edit mode at ORIGIN (a point in the sky of the work place, so no valley is in the way) for a look,
-- the way the server builds it (server/DungeonArena). Run in Edit, after the scripts are synced into the place
-- (tools/map/sync_all.ps1 or a .Source set). Returns the counts. Re-run to rebuild: the old preview is destroyed.
local ServerScriptService = game:GetService("ServerScriptService")
local old = workspace:FindFirstChild("ArenaPreview")
if old then
	old:Destroy()
end
-- (fresh copies of the three modules each run, wired to each other: require keeps the first run's modules, and their cached
-- template, whatever the Source is set to afterwards)
local shared = game:GetService("ReplicatedStorage").Shared
local original = ServerScriptService.Server.DungeonArena
local config = shared.Config:Clone()
config.Name = "ConfigPv"
config.Parent = shared
local plan = shared.DungeonArenaPlan:Clone()
plan.Name = "DungeonArenaPlanPv"
plan.Source = string.gsub(plan.Source, "script%.Parent%.Config%)", "script.Parent.ConfigPv)")
plan.Parent = shared
local copy = original:Clone()
copy.Name = "DungeonArenaPreviewCopy"
copy.Source = string.gsub(
	string.gsub(copy.Source, "Shared%.Config%)", "Shared.ConfigPv)"),
	"Shared%.DungeonArenaPlan%)",
	"Shared.DungeonArenaPlanPv)"
)
copy.Parent = original.Parent
local module = require(copy)
local template = module.template()
copy:Destroy()
plan:Destroy()
config:Destroy()
if not template then
	return "no template (see the output)"
end
local arena = template:Clone()
arena.Name = "ArenaPreview"
arena:PivotTo(CFrame.new(0, 2000, 0))
arena.Parent = workspace
local parts, meshes, tris = 0, 0, 0
for _, d in arena:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
		if d:IsA("MeshPart") then
			meshes += 1
		end
	end
end
local models = 0
for _, f in arena:GetChildren() do
	if f:IsA("Folder") and f.Name ~= "Floor" and f.Name ~= "Paths" and f.Name ~= "Wall" and f.Name ~= "Hills" then
		models += #f:GetChildren()
	end
end
return string.format("parts %d meshparts %d scenery models %d", parts, meshes, models)
