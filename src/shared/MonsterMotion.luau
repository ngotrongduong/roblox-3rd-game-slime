--!strict
-- How a Slime Dungeon monster's pieces move (the owner's monster paintings built in Blender as rigid pieces, one per
-- moving part, art/models/monsters/MOTION.md). Pure: the client (SlimeActor's creature) turns each piece about its joint
-- by these angles every frame; no animation asset is uploaded. A piece's spec (Config.Dungeon.Looks):
--   axis   "x" (pitch: legs swing, heads nod), "y" (yaw: heads turn) or "z" (roll: wings flap, sprouts sway); the model's
--          front is -Z
--   amp    degrees either way; hz cycles a second; phase 0..1 of a cycle (the left and right halves run apart)
--   sign   -1 mirrors the turn (a left wing flaps against the right one)
--   walk   true: the full swing only while the monster moves, IdleShare of it standing
--   hit    extra degrees the piece throws into an attack (an ear flick, a leg stamp)
local MonsterMotion = {}

export type Piece = {
	axis: string?,
	amp: number?,
	hz: number?,
	phase: number?,
	sign: number?,
	walk: boolean?,
	hit: number?,
}

-- A walking piece standing still keeps this share of its swing (it breathes, never freezes).
MonsterMotion.IdleShare = 0.15

-- The piece's turn at time `now` (seconds), as radians about X, Y and Z. `moving`: the monster is walking; `attack`
-- 0..1: how far into an attack it is.
function MonsterMotion.angles(piece: Piece, now: number, moving: boolean, attack: number): (number, number, number)
	local amp = piece.amp or 0
	if piece.walk and not moving then
		amp *= MonsterMotion.IdleShare
	end
	local wave = math.sin(2 * math.pi * ((piece.hz or 0) * now + (piece.phase or 0)))
	local degrees = (amp * wave + (piece.hit or 0) * math.clamp(attack, 0, 1)) * (piece.sign or 1)
	local turn = math.rad(degrees)
	local axis = piece.axis or "z"
	if axis == "x" then
		return turn, 0, 0
	elseif axis == "y" then
		return 0, turn, 0
	end
	return 0, 0, turn
end

-- The whole monster's rise over its ground spot: its hover plus a bob of `bob` studs at `hz`.
function MonsterMotion.lift(hover: number, bob: number, hz: number, now: number): number
	return hover + bob * math.sin(2 * math.pi * hz * now)
end

return MonsterMotion
