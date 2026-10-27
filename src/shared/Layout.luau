--!strict
-- Where everything in the Goo Valley is (docs/MAP.md, approved by the owner 2026-10-27). Pure
-- geometry in studs, shared by the map builder, the server (plot ownership, monster areas) and the
-- client (quick travel). The valley centre is the world origin, the ground is y = 0, north is -Z.
-- Positions on the rim are numbered clockwise seen from above: slot 0 (north) is the Market,
-- slots 1..8 are the home plots.

local Config = if script then require(script.Parent.Config) else require("./Config")

-- In Lune (tests) the Roblox datatypes come from its roblox library instead of globals.
local LuneRoblox = if script then nil else (require :: any)("@lune/roblox")
local Vector3: typeof(Vector3) = if LuneRoblox then LuneRoblox.Vector3 else Vector3
local CFrame: typeof(CFrame) = if LuneRoblox then LuneRoblox.CFrame else CFrame

local M = Config.Map

local Layout = {}

export type Quarter = {
	id: string,
	name: string,
	-- Centre direction in degrees, clockwise from north seen from above.
	angle: number,
	-- The enemy family of the original game that lives there.
	family: string,
}

-- The four moods of the Wild Garden, by quarter (north-east first, clockwise).
local quarters: { Quarter } = {
	{ id = "meadow", name = "Sunny Meadow", angle = 45, family = "greenfield" },
	{ id = "ember", name = "Ember Garden", angle = 135, family = "volcano" },
	{ id = "frost", name = "Frost Glade", angle = 225, family = "ice" },
	{ id = "mushroom", name = "Mushroom Grove", angle = 315, family = "darkforest" },
}
Layout.Quarters = quarters

-- The areas of a home plot on its 3x3 grid. col: -1 left .. 1 right, row: -1 front (the gate,
-- toward the valley centre) .. 1 back (the valley edge), as seen standing at the gate facing in.
Layout.PlotAreas = {
	{ id = "fishing", col = -1, row = 1 },
	{ id = "pantry", col = 0, row = 1 },
	{ id = "garden", col = 1, row = 1 },
	{ id = "kitchen", col = -1, row = 0 },
	{ id = "meadow", col = 0, row = 0 },
	{ id = "breeding", col = 1, row = 0 },
	{ id = "training", col = -1, row = -1 },
	{ id = "gate", col = 0, row = -1 },
	{ id = "hatchery", col = 1, row = -1 },
}

-- Point on the ground at a compass angle (degrees clockwise from north) and a radius.
function Layout.polar(angleDeg: number, radius: number): Vector3
	local a = math.rad(angleDeg)
	return Vector3.new(math.sin(a) * radius, 0, -math.cos(a) * radius)
end

-- Compass angle of rim slot i (0 = Market, 1..8 = plots).
function Layout.slotAngle(slot: number): number
	return slot * 360 / (M.PlotCount + 1)
end

-- The frame of a rim slot: at its centre on the ground, looking toward the valley centre, so its
-- -Z (LookVector) points at the middle and its gate side is the front.
function Layout.slotFrame(slot: number): CFrame
	local angle = Layout.slotAngle(slot)
	-- Yaw by hand rather than CFrame.lookAt (Lune's lookAt points the other way): a yaw of
	-- pi - angle turns the LookVector (-sin, 0, -cos) of the yaw toward the centre.
	return CFrame.new(Layout.polar(angle, M.RimRadius)) * CFrame.Angles(0, math.pi - math.rad(angle), 0)
end

function Layout.plotFrame(plot: number): CFrame
	assert(plot >= 1 and plot <= M.PlotCount, "plot out of range")
	return Layout.slotFrame(plot)
end

function Layout.marketFrame(): CFrame
	return Layout.slotFrame(0)
end

-- Centre of an area of a plot, in world space. A plot's row 1 lies away from the valley centre.
function Layout.plotAreaFrame(plot: number, col: number, row: number): CFrame
	local step = M.PlotSize / 3
	-- The plot frame faces the centre, so the front (row -1) is local -Z and the back is +Z. Someone
	-- at the gate looking in faces +Z, so their right (col 1) is local -X.
	return Layout.plotFrame(plot) * CFrame.new(-col * step, 0, row * step)
end

-- The gate of a plot: on its front edge, facing the valley centre.
function Layout.plotGate(plot: number): CFrame
	return Layout.plotFrame(plot) * CFrame.new(0, 0, -M.PlotSize / 2)
end

-- Which Wild Garden quarter a point is in, or nil outside the Wild Garden.
function Layout.quarterAt(pos: Vector3): Quarter?
	local flat = Vector3.new(pos.X, 0, pos.Z)
	local r = flat.Magnitude
	if r > M.WildRadius or r < M.HeartRadius then
		return nil
	end
	-- Compass angle clockwise from north (-Z).
	local angle = math.deg(math.atan2(flat.X, -flat.Z)) % 360
	return Layout.Quarters[math.floor(angle / 90) + 1]
end

-- How deep into the Wild Garden a point is: 0 at its rim, 1 at the Heart. Monsters get stronger
-- with it.
function Layout.depthAt(pos: Vector3): number
	local r = Vector3.new(pos.X, 0, pos.Z).Magnitude
	return math.clamp((M.WildRadius - r) / (M.WildRadius - M.HeartRadius), 0, 1)
end

return Layout
