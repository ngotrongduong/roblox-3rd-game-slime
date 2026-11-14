--!strict
-- The map picture's geometry (client/UiMap): where a place stands on the picture of the whole world, and which square of
-- it a small map shows. Pure. Positions are the plan's (x east, z south) unless said; the picture is Config.World.Map.
local Config = if script then require(script.Parent.Config) else require("./Config")
local WorldPlan = if script then require(script.Parent.WorldPlan) else require("./WorldPlan")

local M = Config.World.Map

local MapView = {}

-- A world position (a part's Position) as the plan's coordinates.
function MapView.plan(worldX: number, worldZ: number): (number, number)
	return worldX - WorldPlan.Origin.x, worldZ - WorldPlan.Origin.z
end

-- Where a plan point is on the whole picture, 0..1 from its north-west corner (outside 0..1 when off the picture).
function MapView.uv(x: number, z: number): (number, number)
	return (x - M.MinX) / M.Size, (z - M.MinZ) / M.Size
end

-- The square of the picture (`picture` pixels a side) that shows `studs` studs across, centred on a plan point and pushed
-- back inside the picture: its north-west corner and its side, in picture pixels (ImageRectOffset, ImageRectSize).
function MapView.crop(x: number, z: number, studs: number, picture: number): (number, number, number)
	local size = math.min(studs / M.Size * picture, picture)
	local u, v = MapView.uv(x, z)
	return math.clamp(u * picture - size / 2, 0, picture - size),
		math.clamp(v * picture - size / 2, 0, picture - size),
		size
end

-- Where a plan point falls inside such a crop, 0..1 across it (outside 0..1 when the point is not in view).
function MapView.inCrop(
	x: number,
	z: number,
	cropX: number,
	cropY: number,
	size: number,
	picture: number
): (number, number)
	local u, v = MapView.uv(x, z)
	return (u * picture - cropX) / size, (v * picture - cropY) / size
end

return MapView
