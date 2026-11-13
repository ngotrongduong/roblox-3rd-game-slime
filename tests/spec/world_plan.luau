local Config = require("../../src/shared/Config")
local WorldPlan = require("../../src/shared/WorldPlan")

local function dist(ax: number, az: number, bx: number, bz: number): number
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
end

-- Distance from a point to a segment.
local function toSegment(px: number, pz: number, a: { number }, b: { number }): number
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local t = math.clamp(((px - a[1]) * dx + (pz - a[2]) * dz) / (dx * dx + dz * dz), 0, 1)
	return dist(px, pz, a[1] + dx * t, a[2] + dz * t)
end

local function toLine(px: number, pz: number, points: { { number } }): number
	local best = math.huge
	for i = 1, #points - 1 do
		best = math.min(best, toSegment(px, pz, points[i], points[i + 1]))
	end
	return best
end

return function(T)
	local M = Config.Map

	T.test("the world holds what the owner asked for", function()
		local count = {}
		for _, zone in WorldPlan.Zones do
			count[zone.kind] = (count[zone.kind] or 0) + 1
		end
		T.eq(#WorldPlan.Villages, M.PlotCount, "villages")
		T.eq(count.mini, 10, "mini-boss zones")
		T.eq(count.boss, 3, "boss zones")
		T.eq(count.mega, 1, "mega-boss zone")
		T.eq(WorldPlan.Hub.kind, "hub")
	end)

	T.test("place ids are unique and inside the land", function()
		local seen = {}
		local B, R = WorldPlan.Bounds, WorldPlan.Rim
		for _, place in WorldPlan.places() do
			T.ok(not seen[place.id], "twice: " .. place.id)
			seen[place.id] = true
			T.ok(
				place.x > B.minX and place.x < B.maxX and place.z > B.minZ and place.z < B.maxZ,
				place.id .. " in bounds"
			)
			local rim = (math.abs(place.x - R.x) / R.radius) ^ R.power + (math.abs(place.z - R.z) / R.radius) ^ R.power
			T.ok(rim < 0.85, place.id .. " clear of the rim mountains: " .. rim)
		end
	end)

	T.test("villages have room for a plot and a lane between them", function()
		local need = M.PlotSize * math.sqrt(2) + M.PlotLane
		T.ok(WorldPlan.Village.PadRadius >= M.PlotSize / 2 * math.sqrt(2) + 10, "a plot's corners stand on its pad")
		T.ok(WorldPlan.Village.GateOut > M.PlotSize / 2 + 20, "the lane passes in front of the gate")
		for i, a in WorldPlan.Villages do
			for j = i + 1, #WorldPlan.Villages do
				local b = WorldPlan.Villages[j]
				T.ok(dist(a.x, a.z, b.x, b.z) >= need, a.id .. " and " .. b.id .. " too close")
			end
		end
	end)

	T.test("no village is much further from the hub than another", function()
		local near, far = math.huge, 0
		for _, v in WorldPlan.Villages do
			local d = dist(v.x, v.z, WorldPlan.Hub.x, WorldPlan.Hub.z)
			near, far = math.min(near, d), math.max(far, d)
		end
		T.ok(near >= 520, "nearest " .. near)
		T.ok(far <= 800 and far / near <= 1.35, "furthest " .. far .. ", nearest " .. near)
	end)

	T.test("pads do not overlap", function()
		local all = WorldPlan.places()
		for i, a in all do
			for j = i + 1, #all do
				local b = all[j]
				-- A gate sits in the Heart's rim and the Heart's own pad is its island: only fights, villages, the hub
				-- and landmarks are held apart.
				local padded = function(kind: string): boolean
					return kind ~= "junction" and kind ~= "bridge" and kind ~= "gate"
				end
				if padded(a.kind) and padded(b.kind) then
					T.ok(dist(a.x, a.z, b.x, b.z) >= a.radius + b.radius + 20, a.id .. " overlaps " .. b.id)
				end
			end
		end
	end)

	T.test("the river keeps off villages, the hub and fights, and every bridge is on it", function()
		local river = WorldPlan.River.points
		local half = WorldPlan.River.Width / 2
		for _, place in WorldPlan.places() do
			local d = toLine(place.x, place.z, river)
			if place.kind == "bridge" then
				T.ok(d <= half, place.id .. " is " .. d .. " from the river")
			elseif place.kind == "village" or place.kind == "hub" or place.kind == "mini" or place.kind == "boss" then
				T.ok(d >= place.radius + half + 15, place.id .. " in the river: " .. d)
			end
		end
	end)

	T.test("every road names real places and the whole world is joined", function()
		for _, road in WorldPlan.Roads do
			for _, step in road.path do
				if type(step) == "string" then
					T.ok(WorldPlan.find(step) ~= nil, road.id .. " names " .. step)
				end
			end
			T.ok(#WorldPlan.roadPoints(road) >= 2, road.id)
		end
		local graph = WorldPlan.graph()
		local reached = { hub = true }
		local queue = { "hub" }
		while #queue > 0 do
			local at = table.remove(queue) :: string
			for next in graph[at] do
				if not reached[next] then
					reached[next] = true
					table.insert(queue, next)
				end
			end
		end
		for _, place in WorldPlan.places() do
			T.ok(reached[place.id], place.id .. " has no road from the hub")
		end
	end)

	T.test("the Heart opens only through its three gates, one behind each boss", function()
		local graph = WorldPlan.graph()
		local gates = 0
		for id in graph.heart do
			local gate = assert(WorldPlan.find(id))
			T.eq(gate.kind, "gate", id)
			gates += 1
			local bosses = 0
			for other in graph[id] do
				if other ~= "heart" then
					T.eq((assert(WorldPlan.find(other))).kind, "boss", id .. " leads to " .. other)
					bosses += 1
				end
			end
			T.eq(bosses, 1, id)
			local H = WorldPlan.Heart
			T.near(dist(gate.x, gate.z, H.x, H.z), H.RimRadius, 12, id .. " on the rim")
		end
		T.eq(gates, 3)
	end)

	T.test("harder zones lie further from the hub along the roads", function()
		-- Road legs from the hub (breadth first): a boss is never nearer than the first fight of its region.
		local graph = WorldPlan.graph()
		local legs = { hub = 0 }
		local queue = { "hub" }
		local head = 1
		while queue[head] do
			local at = queue[head]
			head += 1
			for next in graph[at] do
				if legs[next] == nil then
					legs[next] = legs[at] + 1
					table.insert(queue, next)
				end
			end
		end
		T.ok(legs.m1 < legs.m3 and legs.m3 < legs.b1, "west: meadow, grove, its boss")
		T.ok(legs.m2 < legs.m5 and legs.m5 < legs.b2, "east: meadow, ember, its boss")
		T.ok(legs.m7 < legs.m9 and legs.m8 < legs.m10, "the passes come before the ice")
		-- (The Frost boss is deeper in than the Heart's nearest gate: the Heart is behind a boss, not behind all three.)
		T.ok(legs.heart > legs.b1 and legs.heart > legs.b2, "the Heart lies behind a boss")
		T.ok(legs.b3 > legs.b1 and legs.b3 > legs.b2, "the Frost boss is the last of the three")
	end)
end
