--!strict
-- Where the game's own places stand in the big world (docs/WORLD.md; the plan is WorldPlan). Pure geometry in
-- studs, shared by the builders, the server (plot ownership, camps) and the client (quick travel). North is -Z;
-- frames lie at y = 0 and the ground of every pad is Config.Map.GroundY above it. Slot 0 is the Market at the hub,
-- slots 1..8 are the home plots: WorldPlan.Villages in their order.

local Config = if script then require(script.Parent.Config) else require("./Config")
local WorldPlan = if script then require(script.Parent.WorldPlan) else require("./WorldPlan")

-- In Lune (tests) the Roblox datatypes come from its roblox library instead of globals.
local LuneRoblox = if script then nil else (require :: any)("@lune/roblox")
local Vector3: typeof(Vector3) = if LuneRoblox then LuneRoblox.Vector3 else Vector3
local CFrame: typeof(CFrame) = if LuneRoblox then LuneRoblox.CFrame else CFrame

local M = Config.Map

local Layout = {}

-- The areas of a home plot on its 3x3 grid. col: -1 left .. 1 right, row: -1 front (the gate,
-- toward the hub) .. 1 back, as seen standing at the gate facing in.
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

-- A frame at a plan position (x east, z south) whose -Z (LookVector) points along (dx, dz).
local function facing(x: number, z: number, dx: number, dz: number): CFrame
	-- Yaw by hand rather than CFrame.lookAt (Lune's lookAt points the other way): a yaw's LookVector is
	-- (-sin, 0, -cos).
	local wx, wz = WorldPlan.world(x, z)
	return CFrame.new(wx, 0, wz) * CFrame.Angles(0, math.atan2(-dx, -dz), 0)
end

-- The frame of a slot: at its middle, its -Z (LookVector) the front. The Market's way in looks north, up the
-- King's Road; a village's gate looks at the hub.
function Layout.slotFrame(slot: number): CFrame
	if slot == 0 then
		return facing(WorldPlan.Market.x, WorldPlan.Market.z, 0, -1)
	end
	local village = WorldPlan.Villages[slot]
	local dx, dz = WorldPlan.villageFacing(village)
	return facing(village.x, village.z, dx, dz)
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
-- (the leaderboard). The Market's frame looks out of its way in, so a half turn faces the other way.
function Layout.marketLanding(lift: number): CFrame
	local spot = Config.Market.Landing
	return Layout.marketFrame() * CFrame.new(spot.x, M.GroundY + lift, spot.z) * CFrame.Angles(0, math.pi, 0)
end

-- Where quick travel puts a character at home: in the plot's gate opening, `inside` studs in from its front edge, `lift`
-- studs up, facing in. The gate looks out at the hub, so a half turn faces into the plot.
function Layout.homeLanding(plot: number, lift: number, inside: number): CFrame
	return Layout.plotGate(plot) * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, M.GroundY + lift, -inside)
end

-- The side of one cell of a plot's 3x3 grid (one area).
function Layout.cellSize(): number
	return M.PlotSize / 3
end

-- Centre of an area of a plot, in world space. A plot's row 1 lies away from the hub.
function Layout.plotAreaFrame(plot: number, col: number, row: number): CFrame
	local step = Layout.cellSize()
	-- The plot frame faces the hub, so the front (row -1) is local -Z and the back is +Z. Someone
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

-- The move that carries everything of plot `from` onto plot `plot` (a clone of the hand-built village is moved by it):
-- `turn * Layout.plotFrame(from)` is `Layout.plotFrame(plot)`, and the same for every frame of the plot.
function Layout.plotTurn(plot: number, from: number): CFrame
	assert(plot >= 1 and plot <= M.PlotCount and from >= 1 and from <= M.PlotCount, "plot out of range")
	return Layout.plotFrame(plot) * Layout.plotFrame(from):Inverse()
end

-- The gate of a slice (0 is the Market's, 1..8 the plots'): on its front edge, facing out.
function Layout.sliceGate(slice: number): CFrame
	assert(slice >= 0 and slice <= M.PlotCount, "slice out of range")
	return Layout.slotFrame(slice) * CFrame.new(0, 0, -M.PlotSize / 2)
end

-- Where the groups of zombies of a slice stand out from (Zombies.homeOffset): its gate, turned by the village's
-- `camps` degrees where the land straight ahead is not free (WorldPlan.Villages).
function Layout.campFrame(slice: number): CFrame
	local village = WorldPlan.Villages[slice] :: { camps: number? }?
	return Layout.sliceGate(slice) * CFrame.Angles(0, math.rad(if village then village.camps or 0 else 0), 0)
end

-- The gate of a plot: on its front edge, facing the hub.
function Layout.plotGate(plot: number): CFrame
	assert(plot >= 1 and plot <= M.PlotCount, "plot out of range")
	return Layout.sliceGate(plot)
end

-- The team banner of a plot, on the ground just inside its gate, facing into the village (Config.Zombies.Muster*).
function Layout.plotMuster(plot: number): CFrame
	local Z = Config.Zombies
	return Layout.plotGate(plot) * CFrame.new(Z.MusterAcross, M.GroundY, Z.MusterIn) * CFrame.Angles(0, math.pi, 0)
end

-- The one Dungeon Portal, in the Market (Config.Dungeon.Portal.Market): its foot on the ground, its opening (+Z) turned to
-- the square's middle.
function Layout.marketPortal(): CFrame
	local at = Layout.marketPoint(Config.Dungeon.Portal.Market)
	local centre = Layout.marketFrame().Position
	local toward = Vector3.new(centre.X - at.X, 0, centre.Z - at.Z)
	-- (yaw by hand: a yaw's LookVector is (-sin, 0, -cos), so this one's +Z looks along `toward`)
	return CFrame.new(at) * CFrame.Angles(0, math.atan2(toward.X, toward.Z), 0)
end

-- Where a player is put when they leave the Dungeon: Config.Dungeon.ExitOut studs in front of the portal's opening (its
-- +Z), ExitLift up, turned away from the portal.
function Layout.portalLanding(): CFrame
	local D = Config.Dungeon
	local portal = Layout.marketPortal()
	local at = (portal * CFrame.new(0, 0, D.ExitOut)).Position
	local away = at - portal.Position
	-- (yaw by hand, as slotFrame does: a yaw's LookVector is (-sin, 0, -cos))
	return CFrame.new(at.X, M.GroundY + D.ExitLift, at.Z) * CFrame.Angles(0, math.atan2(-away.X, -away.Z), 0)
end

-- The frame of plot `plot`'s Dungeon arena: the middle of its floor's top, far from the valley (Config.Dungeon.Arena*).
function Layout.arenaFrame(plot: number): CFrame
	assert(plot >= 1 and plot <= M.PlotCount, "plot out of range")
	local D = Config.Dungeon
	return CFrame.new(D.ArenaOrigin.x + (plot - 1) * D.ArenaSpacing, D.ArenaOrigin.y, D.ArenaOrigin.z)
end

-- Where a player stands in an arena whose middle is `frame`: Config.Dungeon.PlayerSpot, PlayerLift up, facing the middle.
function Layout.arenaSpot(frame: CFrame): CFrame
	local D = Config.Dungeon
	local at = (frame * CFrame.new(D.PlayerSpot.x, D.PlayerLift, D.PlayerSpot.z)).Position
	local toward = frame.Position - at
	return CFrame.new(at) * CFrame.Angles(0, math.atan2(-toward.X, -toward.Z), 0)
end

function Layout.arenaPlayerSpot(plot: number): CFrame
	return Layout.arenaSpot(Layout.arenaFrame(plot))
end

return Layout
