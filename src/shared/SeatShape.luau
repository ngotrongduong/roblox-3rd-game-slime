--!strict
-- Where on a bench, a log or a stump a slime sits, from rays dropped across its footprint (pure, so Lune checks it).
-- The seat is the largest flat band of hits between SeatMinRise and SeatMaxRise above the ground; hits clearly
-- above it are the backrest, and the slime faces away from it (the owner, 2026-10-30: sit on the seat, never on
-- the backrest).
local Config = if script then require(script.Parent.Config) else require("./Config")

local V = Config.Village

-- x, z: where the ray fell (any horizontal frame); h: the hit's height above the ground; flat = false: a steep face
-- (the round side of a log, a slanted backrest), never sat on but still part of a backrest.
export type Sample = { x: number, z: number, h: number, flat: boolean? }
export type Fit = {
	height: number,
	x: number,
	z: number,
	-- what the sitter faces (unit, horizontal); nil when there is no backrest (the caller decides)
	faceX: number?,
	faceZ: number?,
	places: { { x: number, z: number } },
}

local SeatShape = {}

function SeatShape.fit(samples: { Sample }, step: number): Fit?
	local kept: { Sample } = {}
	for _, s in samples do
		if s.flat ~= false and s.h >= V.SeatMinRise and s.h <= V.SeatMaxRise then
			table.insert(kept, s)
		end
	end
	-- the most crowded band; a tie goes to the lower one (a seat, not a backrest's top)
	local bestH, bestCount = 0, 0
	for _, s in kept do
		local count = 0
		for _, o in kept do
			if math.abs(o.h - s.h) <= V.SeatBand then
				count += 1
			end
		end
		if count > bestCount or (count == bestCount and s.h < bestH) then
			bestH, bestCount = s.h, count
		end
	end
	if bestCount < V.SeatMinHits then
		return nil
	end
	local seat: { Sample } = {}
	local sumH, sumX, sumZ = 0, 0, 0
	for _, s in kept do
		if math.abs(s.h - bestH) <= V.SeatBand then
			table.insert(seat, s)
			sumH += s.h
			sumX += s.x
			sumZ += s.z
		end
	end
	local height, cx, cz = sumH / #seat, sumX / #seat, sumZ / #seat
	local backX, backZ, backs = 0, 0, 0
	for _, s in samples do
		if s.h > height + V.SeatBackRise then
			backX += s.x
			backZ += s.z
			backs += 1
		end
	end
	local faceX: number?, faceZ: number? = nil, nil
	if backs > 0 then
		local dx, dz = cx - backX / backs, cz - backZ / backs
		local length = math.sqrt(dx * dx + dz * dz)
		if length > step * 0.25 then
			faceX, faceZ = dx / length, dz / length
		end
	end
	-- Places side by side along the seat: across the facing, or along the longer spread without a back.
	local ax, az = 1, 0
	if faceX and faceZ then
		ax, az = -faceZ, faceX
	else
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, s in seat do
			minX, maxX = math.min(minX, s.x), math.max(maxX, s.x)
			minZ, maxZ = math.min(minZ, s.z), math.max(maxZ, s.z)
		end
		if maxZ - minZ > maxX - minX then
			ax, az = 0, 1
		end
	end
	local low, high = math.huge, -math.huge
	for _, s in seat do
		local along = (s.x - cx) * ax + (s.z - cz) * az
		low, high = math.min(low, along), math.max(high, along)
	end
	local length = high - low + step
	local count = math.clamp(math.floor(length / V.SeatPlaceStuds), 1, V.SeatMaxPlaces)
	local middle = (low + high) / 2
	local places: { { x: number, z: number } } = {}
	for index = 1, count do
		local offset = middle + (index - (count + 1) / 2) * (length / count)
		table.insert(places, { x = cx + ax * offset, z = cz + az * offset })
	end
	return { height = height, x = cx, z = cz, faceX = faceX, faceZ = faceZ, places = places }
end

return SeatShape
