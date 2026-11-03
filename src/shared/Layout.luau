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
	{ id = "mushroom", name = "Mushroom Grove", angle = 135, family = "darkforest" },
	{ id = "ember", name = "Ember Garden", angle = 225, family = "volcano" },
	{ id = "frost", name = "Frost Glade", angle = 315, family = "ice" },
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

-- A spot of the Market (one of Config.Market's { x, z }, local to the Market's frame) as a world position, on the ground.
function Layout.marketPoint(spot: { x: number, z: number }): Vector3
	local at = (Layout.marketFrame() * CFrame.new(spot.x, 0, spot.z)).Position
	return Vector3.new(at.X, M.GroundY, at.Z)
end

-- Where quick travel puts a character at the Market: at the landing spot, `lift` studs up, facing the back of the square
-- (the leaderboard). The Market's frame looks at the valley centre, so a half turn faces the other way.
function Layout.marketLanding(lift: number): CFrame
	local spot = Config.Market.Landing
	return Layout.marketFrame() * CFrame.new(spot.x, M.GroundY + lift, spot.z) * CFrame.Angles(0, math.pi, 0)
end

-- Where quick travel puts a character at home: in the plot's gate opening, `inside` studs in from its front edge, `lift`
-- studs up, facing in. The gate looks at the valley centre, so a half turn faces into the plot.
function Layout.homeLanding(plot: number, lift: number, inside: number): CFrame
	return Layout.plotGate(plot) * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, M.GroundY + lift, -inside)
end

-- The side of one cell of a plot's 3x3 grid (one area).
function Layout.cellSize(): number
	return M.PlotSize / 3
end

-- Centre of an area of a plot, in world space. A plot's row 1 lies away from the valley centre.
function Layout.plotAreaFrame(plot: number, col: number, row: number): CFrame
	local step = Layout.cellSize()
	-- The plot frame faces the centre, so the front (row -1) is local -Z and the back is +Z. Someone
	-- at the gate looking in faces +Z, so their right (col 1) is local -X.
	return Layout.plotFrame(plot) * CFrame.new(-col * step, 0, row * step)
end

-- An area of a plot turned to face the plot's middle (the owner, 2026-10-27: "all of them turned in
-- toward the player's middle area, like a small village"). Same centre as plotAreaFrame; its -Z
-- (LookVector, the area's front) points at the plot's centre, so corner areas face it diagonally.
-- The middle cell itself keeps the plot's own frame.
function Layout.plotAreaFacing(plot: number, col: number, row: number): CFrame
	local frame = Layout.plotAreaFrame(plot, col, row)
	if col == 0 and row == 0 then
		return frame
	end
	local d = Layout.plotFrame(plot).Position - frame.Position
	-- A yaw's LookVector is (-sin, 0, -cos): yaw = atan2(-dx, -dz) looks along d.
	return CFrame.new(frame.Position) * CFrame.Angles(0, math.atan2(-d.X, -d.Z), 0)
end

-- The turn about the valley centre that carries everything of plot `from` onto plot `plot` (a clone of the hand-built village
-- is turned by it): `turn * Layout.plotFrame(from)` is `Layout.plotFrame(plot)`, and the same for every frame of the plot.
function Layout.plotTurn(plot: number, from: number): CFrame
	assert(plot >= 1 and plot <= M.PlotCount and from >= 1 and from <= M.PlotCount, "plot out of range")
	return CFrame.Angles(0, math.rad(Layout.slotAngle(from) - Layout.slotAngle(plot)), 0)
end

-- The gate of a rim slice (0 is the Market's, 1..8 the plots'): on its front edge, facing the valley centre. The groups of
-- zombies of the slice stand out from it (docs/MAP.md 1.4).
function Layout.sliceGate(slice: number): CFrame
	assert(slice >= 0 and slice <= M.PlotCount, "slice out of range")
	return Layout.slotFrame(slice) * CFrame.new(0, 0, -M.PlotSize / 2)
end

-- The gate of a plot: on its front edge, facing the valley centre.
function Layout.plotGate(plot: number): CFrame
	assert(plot >= 1 and plot <= M.PlotCount, "plot out of range")
	return Layout.sliceGate(plot)
end

-- The team banner of a plot, on the ground just inside its gate, facing into the village (Config.Zombies.Muster*).
function Layout.plotMuster(plot: number): CFrame
	local Z = Config.Zombies
	return Layout.plotGate(plot) * CFrame.new(Z.MusterAcross, M.GroundY, Z.MusterIn) * CFrame.Angles(0, math.pi, 0)
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
