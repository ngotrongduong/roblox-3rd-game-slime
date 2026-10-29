-- Raises the smaller of every pair of coplanar overlapping parts saved in the home plot (no flicker), with
-- the same rule the server applies to the stages it builds (src/server/ZFight.luau). Re-runnable: a second
-- run finds nothing. Run in Edit after tools/map/sync_all.ps1, then save the place (Ctrl+S):
--   node tools/studio_mcp.js run tools/map/fix_zfight.luau <studio_id> Edit
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight)
local plot = workspace.Map:FindFirstChild("Plot5")
local moved = ZFight.resolve(plot)
return "[GooLineage] fix_zfight: raised " .. moved .. " parts in " .. plot:GetFullName()
