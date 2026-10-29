-- Seats every rock and boulder saved in the home plot on the ground (src/server/RockSeat.luau): no gap under
-- any edge. Stage rocks are seated by the server when a stage is built. Re-runnable. Run in Edit after
-- tools/map/sync_all.ps1, then save the place (Ctrl+S):
--   node tools/studio_mcp.js run tools/map/fix_rocks.luau <studio_id> Edit
local RockSeat = require(game:GetService("ServerScriptService").Server.RockSeat)
local plot = workspace.Map:FindFirstChild("Plot5")
local moved, left = 0, {}
for _, rock in RockSeat.rocks(plot) do
	-- (the stages are rebuilt by the server on play; only the saved dressing is fixed here)
	if not rock:FindFirstAncestor("AreaStage") and not rock:FindFirstAncestor("PondStage") then
		local before = rock:GetPivot()
		local gap = RockSeat.seat(rock)
		if (rock:GetPivot().Position - before.Position).Magnitude > 1e-3 then
			moved += 1
		end
		if gap > 0.05 then
			table.insert(left, string.format("%s %.2f", rock:GetFullName(), gap))
		end
	end
end
return "[GooLineage] fix_rocks: seated " .. moved .. " rocks; still floating: " .. #left .. "\n" .. table.concat(left, "\n")
