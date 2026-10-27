-- Copies server code from the repo into the work place open in Studio (ServerScriptService.Server),
-- so a play test there runs it (the map lives only in the work place). Run with the files passed as
-- strings, NAME=path for each:
--   node tools/studio_mcp.js run tools/map/sync_server.luau <studio_id> Edit PondStages=src/server/PondStages.luau AreaStages=src/server/AreaStages.luau PantryStages=src/server/PantryStages.luau GardenStages=src/server/GardenStages.luau BreedingStages=src/server/BreedingStages.luau KitchenStages=src/server/KitchenStages.luau TrainingStages=src/server/TrainingStages.luau VillageStages=src/server/VillageStages.luau AreaUpgrade=src/server/AreaUpgrade.server.luau
local ServerScriptService = game:GetService("ServerScriptService")

local folder = ServerScriptService:FindFirstChild("Server")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Server"
	folder.Parent = ServerScriptService
end
-- name, source, class (".server" files are Scripts, the rest ModuleScripts)
local sources = {
	{ "AreaStages", AreaStages, "ModuleScript" },
	{ "PantryStages", PantryStages, "ModuleScript" },
	{ "GardenStages", GardenStages, "ModuleScript" },
	{ "BreedingStages", BreedingStages, "ModuleScript" },
	{ "KitchenStages", KitchenStages, "ModuleScript" },
	{ "TrainingStages", TrainingStages, "ModuleScript" },
	{ "VillageStages", VillageStages, "ModuleScript" },
	{ "PondStages", PondStages, "ModuleScript" },
	{ "AreaUpgrade", AreaUpgrade, "Script" },
}
local done = {}
for _, s in sources do
	if s[2] then
		local old = folder:FindFirstChild(s[1])
		if old then
			old:Destroy()
		end
		local inst = Instance.new(s[3])
		inst.Name = s[1]
		inst.Source = s[2]
		inst.Parent = folder
		table.insert(done, s[1])
	end
end
return "server scripts: " .. table.concat(done, ", ")
