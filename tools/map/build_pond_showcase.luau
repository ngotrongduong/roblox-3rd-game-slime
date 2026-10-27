-- A showcase of the fishing pond's 50 levels (the owner, 2026-10-27), built from the same stages the
-- game uses (src/server/PondStages.luau, copied into the work place by sync_server.luau): floating
-- ponds west of the valley. Row 1: each material tier at its last level (5, 10 ... 50). Row 2: the levels
-- 1-5 (STEP_ERA = 1: the parts appearing one by one). Run in Edit mode through MCP.
local ServerScriptService = game:GetService("ServerScriptService")

local PondStages = require(ServerScriptService.Server.PondStages)

local ORIGIN = Vector3.new(-2600, 120, 300)
local SPACING = 52
local STEP_ERA = 1

local showcase = workspace:FindFirstChild("PondShowcase")
if showcase then
	showcase:Destroy()
end
showcase = Instance.new("Folder")
showcase.Name = "PondShowcase"

local function pond(level: number, cell: CFrame)
	local m = PondStages.build(level, cell, true)
	m.Name = string.format("Level%02d", level)
	m.Parent = showcase
end

for era = 1, #PondStages.Tiers do
	pond(era * 5, CFrame.new(ORIGIN + Vector3.new((era - 1) * SPACING, 0, 0)))
	task.wait()
end
for k = 1, 5 do
	pond((STEP_ERA - 1) * 5 + k, CFrame.new(ORIGIN + Vector3.new((k - 1) * SPACING, 0, 60)))
	task.wait()
end
showcase.Parent = workspace
return "pond showcase: " .. #showcase:GetChildren() .. " ponds"
