--!strict
-- Pure path cleanup and hop clock shared by server routes and client presentation.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Gaits = if script then require(script.Parent.Gaits) else require("./Gaits")
local VillagePath = {}
export type Point = {
	id: string,
	area: string,
	x: number,
	y: number,
	z: number,
	fx: number?,
	fy: number?,
	fz: number?,
}

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

-- Seconds in the air of one hop of this gait, and of one whole hop (crouch, air, rest).
function VillagePath.airSeconds(gait: string?): number
	local g = Gaits.get(gait)
	return math.sqrt(8 * g.HopHeight / g.Gravity)
end

function VillagePath.cycle(gait: string?): number
	local g = Gaits.get(gait)
	return g.CrouchSeconds + math.sqrt(8 * g.HopHeight / g.Gravity) + g.Rest
end

-- Average studs a second of the gait at this speed factor (Gaits.factor).
function VillagePath.speed(gait: string?, factor: number): number
	local g = Gaits.get(gait)
	if g.GlideSpeed then
		return g.GlideSpeed * factor
	end
	return g.HopStuds * factor / VillagePath.cycle(gait)
end

-- Whole hops of a hop gait for this distance (a glide counts as one).
function VillagePath.hops(distanceStuds: number, factor: number, gait: string?): number
	if distanceStuds <= Config.Village.PathPointEpsilon then
		return 0
	end
	local g = Gaits.get(gait)
	if g.GlideSpeed then
		return 1
	end
	return math.max(1, math.ceil(distanceStuds / (g.HopStuds * factor)))
end

-- Seconds a leg takes: whole hops of the gait's cycle, or a glide's distance at its speed plus the ramps up and down.
function VillagePath.duration(distanceStuds: number, factor: number, gait: string?): number
	if distanceStuds <= Config.Village.PathPointEpsilon then
		return 0
	end
	local g = Gaits.get(gait)
	if g.GlideSpeed then
		return distanceStuds / (g.GlideSpeed * factor) + g.GlideRampSeconds
	end
	return VillagePath.hops(distanceStuds, factor, gait) * VillagePath.cycle(gait)
end

-- Distance covered by a glide that accelerates at a constant rate to speed v over r seconds, `e` seconds in.
local function ramped(e: number, v: number, r: number): number
	if e <= 0 then
		return 0
	elseif e < r then
		return v * e * e / (2 * r)
	end
	return v * (r / 2 + e - r)
end

-- How far along the leg (0..1) and which hop (0-based; a glide is always 0; -1 for a leg of no length).
-- A hop gait keeps the feet planted while crouching and after landing: only the airborne portion advances.
function VillagePath.progress(startTime: number, endTime: number, now: number, gait: string?): (number, number)
	if endTime <= startTime then
		return 1, -1
	end
	local g = Gaits.get(gait)
	local total = endTime - startTime
	local elapsed = math.clamp(now - startTime, 0, total)
	if g.GlideSpeed then
		if elapsed >= total then
			return 1, 0
		end
		-- the distance is what the cruise speed covers in the leg's time less one ramp (see duration)
		local r = g.GlideRampSeconds
		local length = g.GlideSpeed * (total - r)
		local covered = math.min(ramped(elapsed, g.GlideSpeed, r), length - ramped(total - elapsed, g.GlideSpeed, r))
		return math.clamp(covered / length, 0, 1), 0
	end
	local cycle = VillagePath.cycle(gait)
	local count = math.max(1, math.round(total / cycle))
	if elapsed >= total then
		return 1, count
	end
	local index = math.min(count - 1, math.floor(elapsed / cycle))
	local phase = elapsed - index * cycle
	local airborne = math.sqrt(8 * g.HopHeight / g.Gravity)
	local t = math.clamp((phase - g.CrouchSeconds) / airborne, 0, 1)
	if g.Ease then
		t = t * t * (3 - 2 * t)
	end
	return (index + t) / count, index
end

-- A glide's speed now as a fraction of its cruise speed (0 at the ends of the leg, 1 between the ramps; 0 for a hop gait).
function VillagePath.glideSpeedFraction(startTime: number, endTime: number, now: number, gait: string?): number
	local g = Gaits.get(gait)
	if not g.GlideSpeed or endTime <= startTime or now <= startTime or now >= endTime then
		return 0
	end
	local r = g.GlideRampSeconds
	return math.clamp(math.min((now - startTime) / r, (endTime - now) / r), 0, 1)
end

return VillagePath
