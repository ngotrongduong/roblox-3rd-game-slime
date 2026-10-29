-- Builds the work tools (the fishing rod and the hoe, from src/server/WorkProps.luau) into the work place's
-- ServerStorage.PropKit, next to the WateringCan, so the next kit export (tools/kit/export_kit.luau) keeps them and
-- tools/kit/export_client_kit.luau puts all three in ReplicatedStorage.ClientKit.Items. Run in Edit mode after
-- tools/map/sync_all.ps1:
--   node tools/studio_mcp.js run tools/kit/make_tools.luau <studio_id> Edit
local WorkProps = require(game:GetService("ServerScriptService").Server.WorkProps)
local kit = game:GetService("ServerStorage"):FindFirstChild("PropKit")
local out = {}
for _, build in { WorkProps.fishingRod, WorkProps.hoe } do
	local m = build()
	local old = kit:FindFirstChild(m.Name)
	if old then
		old:Destroy()
	end
	m.Parent = kit
	local _, size = m:GetBoundingBox()
	table.insert(out, string.format("%s %.1f x %.1f x %.1f, %d parts", m.Name, size.X, size.Y, size.Z, #m:GetChildren()))
end
local can = kit:FindFirstChild("WateringCan")
table.insert(out, "WateringCan " .. (if can then "present" else "MISSING"))
return table.concat(out, "\n")
