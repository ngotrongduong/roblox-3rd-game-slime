-- Every seat place the slimes can sit on in the dev plot (Spots.seats): what it sits on, its area, the seat surface
-- height, the height above the ground in front of it, and which way it faces. Read only; run in a play test (Server)
-- at the level to check, after tools/map/sync_all.ps1:
--   node tools/studio_mcp.js run tools/map/probe_seats.luau <studio_id> Server
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Spots = require(SSS.Server.Spots)
local plot = workspace.Map:FindFirstChild("Plot" .. Config.Village.DevPlot)
local spots = Spots.build(Config.Village.DevPlot, plot)
local fire = spots.campfire
local seats = Spots.seats(
	plot,
	if fire then Vector3.new(fire.x, fire.y, fire.z) else nil,
	Vector3.new(spots.plaza.x, spots.plaza.y, spots.plaza.z)
)
local lines = { "seats: " .. #seats }
for _, seat in seats do
	local s, f = seat.spot, seat.foot
	local face = Vector3.new((s.fx or s.x) - s.x, 0, (s.fz or s.z) - s.z)
	table.insert(
		lines,
		string.format(
			"%s %s (%s) at %.1f, %.1f, %.1f  seat %.2f above the foot  faces %.2f, %.2f",
			s.id,
			seat.model,
			s.area,
			s.x,
			s.y,
			s.z,
			s.y - f.y,
			if face.Magnitude > 0 then face.Unit.X else 0,
			if face.Magnitude > 0 then face.Unit.Z else 0
		)
	)
end
local sign = Spots.storehouseSign(plot)
table.insert(lines, "storehouse sign: " .. tostring(sign) .. "  storehouse spot: " .. string.format("%.1f, %.1f, %.1f", spots.storehouse.x, spots.storehouse.y, spots.storehouse.z))
return table.concat(lines, "\n")
