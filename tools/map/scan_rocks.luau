-- Lists every rock or boulder in the home plot (saved dressing and the server's stages) whose base does not
-- reach the ground somewhere under its edge (it looks like it floats), with the worst gap. Read only; the
-- same measure as src/server/RockSeat.luau. Run after sync_all, in Edit or in a play test (Server):
--   node tools/studio_mcp.js run tools/map/scan_rocks.luau <studio_id> Server
local RockSeat = require(game:GetService("ServerScriptService").Server.RockSeat)
local plot = workspace.Map:FindFirstChild("Plot5")
local rocks = RockSeat.rocks(plot)
local out = {}
for _, r in rocks do
	local gap = RockSeat.gap(r)
	if gap > 0.05 then
		table.insert(out, string.format("%.2f  %s", gap, (r:GetFullName():gsub(plot:GetFullName() .. ".", "", 1))))
	end
end
table.sort(out, function(a, b)
	return a > b
end)
table.insert(out, 1, "ROCKS " .. #rocks .. ", with a gap under an edge: " .. #out)
return table.concat(out, "\n")
