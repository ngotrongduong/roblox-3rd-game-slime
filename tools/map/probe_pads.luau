-- For each upgrade pad: what stands inside its disc (props, benches, plants), whether it sits on a path, and the
-- nearest clear spot in its area's frame (x, z as in Config.Pads.Spots). Read only; run in a play test (Server)
-- at the level to check:
--   node tools/studio_mcp.js run tools/map/probe_pads.luau <studio_id> Server
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Layout = require(RS.Shared.Layout)
local PLOT = Config.Village.DevPlot
local AREAS = {
	fishing = { -1, 1 },
	garden = { 1, 1 },
	pantry = { 0, 1 },
	kitchen = { -1, 0 },
	breeding = { 1, 0 },
	training = { -1, -1 },
}
local plot = workspace.Map:FindFirstChild("Plot" .. PLOT)
local pads = plot:FindFirstChild("UpgradePads")
local R = Config.Pads.Radius
local probe = Instance.new("Part")
probe.Shape = Enum.PartType.Cylinder
probe.Size = Vector3.new(3, 2 * R + 0.6, 2 * R + 0.6)
local function blockers(at: Vector3): { string }
	probe.CFrame = CFrame.new(at + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pads, workspace:FindFirstChild("Villages") }
	local names = {}
	for _, hit in workspace:GetPartsInPart(probe, params) do
		if hit.Transparency < 0.95 and not hit:IsA("Terrain") then
			table.insert(names, (hit:GetFullName():gsub(plot:GetFullName() .. ".", "", 1)))
		end
	end
	return names
end
local function onPath(at: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pads, workspace:FindFirstChild("Villages") }
	for _, d in { Vector3.zero, Vector3.new(R, 0, 0), Vector3.new(-R, 0, 0), Vector3.new(0, 0, R), Vector3.new(0, 0, -R) } do
		local hit = workspace:Raycast(at + d + Vector3.new(0, 3, 0), Vector3.new(0, -5, 0), params)
		if hit and (string.find(hit.Instance.Name, "Paving") or string.find(hit.Instance.Name, "Path")) then
			return true
		end
	end
	return false
end
local out = {}
for areaId, cell in AREAS do
	local frame = Layout.plotAreaFacing(PLOT, cell[1], cell[2]) * CFrame.new(0, Config.Map.GroundY, 0)
	local spot = Config.Pads.Spots[areaId]
	local here = frame:PointToWorldSpace(Vector3.new(spot[1], 0, spot[2]))
	local now = blockers(here)
	local line = string.format("%s at (%g, %g): %s%s", areaId, spot[1], spot[2], #now > 0 and table.concat(now, ", ") or "clear", onPath(here) and " ON PATH" or "")
	if #now > 0 or onPath(here) then
		local best, bestD = nil, math.huge
		for dx = -8, 8, 0.5 do
			for dz = -8, 8, 0.5 do
				local d = math.sqrt(dx * dx + dz * dz)
				if d < bestD then
					local p = frame:PointToWorldSpace(Vector3.new(spot[1] + dx, 0, spot[2] + dz))
					if #blockers(p) == 0 and not onPath(p) then
						best, bestD = { spot[1] + dx, spot[2] + dz }, d
					end
				end
			end
		end
		line ..= if best then string.format(" -> nearest clear (%g, %g)", best[1], best[2]) else " -> none clear within 8"
	end
	table.insert(out, line)
end
return table.concat(out, "\n")
