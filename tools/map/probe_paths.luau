-- Plans a path from the plaza to every village spot of the home plot as it stands now (any level) and
-- lists the spots that fail: no path, no ground under them, or inside a model. Read only; the same agent
-- the village uses (src/server/Village.luau). Run during a play test, after upgrading as wanted:
--   node tools/studio_mcp.js run tools/map/probe_paths.luau <studio_id> Server
local PathfindingService = game:GetService("PathfindingService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Spots = require(game:GetService("ServerScriptService").Server.Spots)
local V = Config.Village
local spots = Spots.build(V.DevPlot, workspace.Map:FindFirstChild("Plot" .. V.DevPlot))
local plaza = spots.plaza
local start = Vector3.new(plaza.x, plaza.y, plaza.z)
local ids = {}
for id in spots do
	-- (rod:N is where a rod stand is, not a place to stand)
	if string.sub(id, 1, 4) ~= "rod:" then
		table.insert(ids, id)
	end
end
table.sort(ids)
local fails = {}
local ok = 0
for _, id in ids do
	local s = spots[id]
	local p = Vector3.new(s.x, s.y, s.z)
	local problems = {}
	local ground = Spots.ground(p, 1)
	if not ground then
		table.insert(problems, "no ground")
	elseif math.abs(ground.Y - p.Y) > 0.3 then
		table.insert(problems, string.format("off the ground by %.2f", p.Y - ground.Y))
	end
	if ground and not Spots.free(ground) then
		table.insert(problems, "inside a model")
	end
	local path = PathfindingService:CreatePath({
		AgentRadius = V.PathMinRadius,
		AgentHeight = V.PathHeightPerScale,
		AgentCanJump = false,
		WaypointSpacing = V.PathWaypointStuds,
		Costs = { Water = V.PathWaterCost },
	})
	local done = pcall(function()
		path:ComputeAsync(start, p)
	end)
	-- (a spot on the plaza itself needs no path)
	if (p - start).Magnitude > 1 and (not done or path.Status ~= Enum.PathStatus.Success) then
		table.insert(problems, "no path (" .. tostring(path.Status) .. ")")
	end
	if #problems > 0 then
		table.insert(fails, string.format("%s (%.1f %.1f %.1f): %s", id, s.x, s.y, s.z, table.concat(problems, ", ")))
	else
		ok += 1
	end
end
local root = workspace:FindFirstChild("Villages")
local village = root and root:GetChildren()[1]
local levels = village and village:GetAttribute("Areas") or "?"
table.insert(fails, 1, "PROBE levels " .. tostring(levels) .. ": " .. ok .. " ok, " .. (#ids - ok) .. " failing")
return table.concat(fails, "\n")
