--!strict
-- Pure path cleanup and hop clock shared by server routes and client presentation.
local Config = if script then require(script.Parent.Config) else require("./Config")
local VillagePath = {}
export type Point = { id: string, area: string, x: number, y: number, z: number }

local function distance(a: Point, b: Point): number
	local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Drop a waypoint only if it is nearly collinear; always retain destination identifiers.
function VillagePath.merge(start: Point, waypoints: { Point }): { Point }
	local result: { Point } = {}
	local previous = start
	for _, nextPoint in waypoints do
		local previousPoint = result[#result]
		if previousPoint and previousPoint.id == "via" and nextPoint.id == "via" then
			local ax, az = previousPoint.x - previous.x, previousPoint.z - previous.z
			local bx, bz = nextPoint.x - previousPoint.x, nextPoint.z - previousPoint.z
			local cross = math.abs(ax * bz - az * bx)
			local length = math.sqrt(ax * ax + az * az) * math.sqrt(bx * bx + bz * bz)
			if length > 0 and cross / length < Config.Village.PathStraightTolerance and ax * bx + az * bz > 0 then
				result[#result] = nextPoint
			else
				table.insert(result, nextPoint)
			end
		elseif distance(previousPoint or previous, nextPoint) > Config.Village.PathPointEpsilon then
			table.insert(result, nextPoint)
		elseif nextPoint.id ~= "via" and previousPoint then
			result[#result] = nextPoint
		end
		previous = if #result > 1 then result[#result - 1] else start
	end
	return result
end

function VillagePath.hops(distanceStuds: number, speed: number): number
	if distanceStuds <= Config.Village.PathPointEpsilon then
		return 0
	end
	return math.max(1, math.ceil(distanceStuds / (speed * Config.Village.HopSeconds)))
end

function VillagePath.duration(distanceStuds: number, speed: number): number
	return VillagePath.hops(distanceStuds, speed) * Config.Village.HopSeconds
end

-- The feet stay planted while crouching and after landing. Only the airborne portion advances.
function VillagePath.progress(startTime: number, endTime: number, now: number): (number, number)
	if endTime <= startTime then
		return 1, -1
	end
	local count = math.max(1, math.round((endTime - startTime) / Config.Village.HopSeconds))
	local elapsed = math.clamp(now - startTime, 0, endTime - startTime)
	if elapsed >= endTime - startTime then
		return 1, count
	end
	local index = math.min(count - 1, math.floor(elapsed / Config.Village.HopSeconds))
	local phase = elapsed - index * Config.Village.HopSeconds
	local airborne = math.sqrt(8 * Config.VillageClient.HopHeight / Config.Slime.Gravity)
	local t = math.clamp((phase - Config.Slime.CrouchSeconds) / airborne, 0, 1)
	local smooth = t * t * (3 - 2 * t)
	return (index + smooth) / count, index
end

return VillagePath
