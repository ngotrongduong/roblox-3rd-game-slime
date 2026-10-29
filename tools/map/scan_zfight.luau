-- Lists the coplanar overlaps left in the home plot: pairs of visible block parts whose top faces lie within
-- Config.Map.ZFightTolerance of each other, overlap in plan and look different (they flicker). Read only;
-- the same rule as src/server/ZFight.luau. Run after sync_all, in Edit or in a play test (Server):
--   node tools/studio_mcp.js run tools/map/scan_zfight.luau <studio_id> Server
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight)
local plot = workspace.Map:FindFirstChild("Plot5")
local parts = {}
for _, p in plot:GetDescendants() do
	if
		p:IsA("Part")
		and p.Shape == Enum.PartType.Block
		and p.Transparency < 0.99
		and math.abs(p.CFrame.UpVector.Y) > 0.999
		and p.Size.X > 0.05
		and p.Size.Z > 0.05
	then
		table.insert(parts, p)
	end
end
local groups = {}
local found = ZFight.pairs(parts)
local prefix = plot:GetFullName() .. "."
for _, pr in found do
	local a = (pr[1]:GetFullName():gsub(prefix, "", 1))
	local b = (pr[2]:GetFullName():gsub(prefix, "", 1))
	local key = if a < b then a .. "  <>  " .. b else b .. "  <>  " .. a
	groups[key] = (groups[key] or 0) + 1
end
local out = {}
for key, n in groups do
	table.insert(out, n .. "x " .. key)
end
table.sort(out)
table.insert(out, 1, "ZFIGHT pairs: " .. #found .. " (parts scanned " .. #parts .. ")")
return table.concat(out, "\n")
