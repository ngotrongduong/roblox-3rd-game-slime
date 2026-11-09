-- The Frost Wisp of the Peaks (art/models/ready/pet_FrostWisp.glb, 8 bones, built and skinned for it: see
-- docs/motion/pet_FrostWisp.md): its joint map, and the MOTION OF THE DJINN (pet_Djinn.luau, itself the Tide
-- Sprite's: a floater over the ground with its height its own) on it, changed only where this body is another.
-- A flame of ice: ONE rigid lump that is body and head at once (the face is cut into its front, eight shards of
-- ice stand on it), a flame that leaves its top and curls back, and a shorter wisp that leaves its bottom. No
-- arms, no legs, no neck. It FLOATS just over the ground (its layer is the ground: the height is its own),
-- hovers on a slow swell that is no metronome, tips into its travel and comes upright again with one small
-- overshoot, lets its wisp trail and its flame stream back, and sways both softly, never in step. Look at
-- art/models/rigs/pet_FrostWisp_left.png and art/models/poses/pet_FrostWisp_pose_sway.png beside this file.
--
-- What this body changes of the Djinn's motion:
--   * its smoke of five joints is the WISP of three (`Tail_01` .. `Tail_03`): the same springs in a row, the
--     same slow wave about z, the same swing out of a turn, the same lazy swish
--   * the FLAME is a second such chain that stands UP (`Flame_01` .. `Flame_03`): it streams BACK as it goes
--     (the opposite sign of pitch for the same "behind"), swings forward past its rest when it stops, and
--     hovering it wavers on a clock of its own, a little quicker than the wisp's, so that the two never sway
--     in step. It never whips: every turn of it is a spring or a slow wave
--   * NO WAIST, NO NECK, NO HEAD JOINT: the lean, the roll into a turn and every look are turns of the lump
--     (`Body_01`); nothing gives the lean back, so the lean is a little less than the Djinn's; a look is a
--     small slow yaw of the whole lump, held, then back
--   * NO ARMS: the breath is left out
-- The kit carries the shared swell, travel, trailing chains and holds of a look.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, sqrt, pi = math.sin, math.sqrt, math.pi
local TAU = pi * 2
local clamp = Kit.clamp

local FrostWisp = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
FrostWisp.map = {
	count = 8,
	tree = 2110222826,
	-- Root is the handle, in the middle of the lump at the height of the eyes: it drives nothing. Body_01, at
	-- the same place, is the LUMP: body and head in one, the face and all eight shards rigid on it. The flame
	-- and the wisp hang on it: its turn is the turn of the whole animal
	root = "Root",
	spine = { "Root", "Body_01" },
	-- the wisp, from under the chin down: where it leaves the lump (01), its fat part (02), its CORNER (03: the
	-- point comes forward from there and is the lowest thing of the model). Nothing of it mirrors
	tail = { "Tail_01", "Tail_02", "Tail_03" },
	limbs = {
		-- the flame, from the top of the lump up: its foot (01), its middle (02), its CORNER (03: the point at the
		-- very top rides on it). A tail that points up: it has no twin
		F = { role = "flame", bones = { "Flame_01", "Flame_02", "Flame_03" } },
	},
	pairs = {},
	rigid = {},
}

-- (what the tools draw and measure as its "foot": the wisp. It hangs, it is never planted)
FrostWisp.legs = {
	{ id = "T", name = "wisp", chain = FrostWisp.map.tail, contact = "Tail_03" },
}

-- It lives over the GROUND, and says so: the height it floats at is its own (`HOVER`), no layer's.
FrostWisp.layer = "ground"

-- The wisp is this many times as tall as its skeleton: its top joint is the corner of the flame at 0.879 of its
-- height, and the point of the flame stands over that with no joint. Every length and the tempo below are of
-- ITS height.
local TALL = 1 / 0.879

-- HOW IT STROLLS in its plot: the Djinn's (the Tide Sprite's) slow drift, 0.45 of its height a second (its
-- "leg" is its whole height: the measure its pace and its tempo come from); it hovers a good while between two.
FrostWisp.stroll = { froude = 0.0128, leg = TALL, rest = { 4, 11 }, radius = 0.6 * TALL }

-- THE DESIGN (lengths are shares of its height, angles radians, rates per tick of its size: sqrt(height / G), a
-- quarter of a second for a wisp of 2.4 studs). The numbers are the Djinn's wherever it has one ---------------
-- hovering
local HOVER = 0.12 -- how high over the ground the point of its wisp hangs (the Djinn's: the point is thin)
local SWELL = 0.03 -- how far it rises and sinks about that
local SWELL_RATE = 0.085 -- swells in one tick (one every three seconds at 2.4 studs) ...
local SWELL_SECOND = 0.61 -- ... and a second, slower one that is never in step with the first
local SWELL_GOING = 0.5 -- the share of the swell it keeps while it travels
local SWAY = 0.012 -- radians it rocks, slower still
-- travelling
local LEAN = 0.17 -- radians the lump tips into its travel at its own pace (10 degrees: the Djinn's 11.5 less a
-- little, because no chest and no head give any of it back here: the FACE tips with it) ...
local LEAN_RATE, LEAN_DAMPING = 2.3, 0.55 -- ... on a spring that goes a little past and comes back once
local PUSH = 2.0 -- speeding up tips it further, braking tips it back: twice the lean of a pace gained in a tick ...
local SLING = 2.6 -- ... and its wisp and its flame are left behind by a start and swing on past a stop, more than that
local BANK = 0.9 -- radians it rolls into a turn of one radian in one tick
local BANK_MOST = 0.22
local GO_START, GO_STOP = 0.14, 0.06 -- shares of its pace at which it starts and stops travelling
-- the wisp, root to tip (the write-up's table: 18 degrees of pitch a joint and 54 together are fine, 12 of roll
-- a joint and 36 together; `Tail_01` under 30 whatever the axis: an edge under the chin stretches at 40)
local TRAIL = { 0.225, 0.182, 0.12 } -- radians each joint trails at its pace: 12.9, 10.4, 6.9 degrees (the
-- sheet's row "floating forward" is 14, 10, 7; the root a degree less keeps it where the Djinn's root is)
local TRAIL_RATE = { 2.0, 3.25, 4.5 } -- each on a spring that follows the one before it (the Djinn's first,
-- middle and last) ...
local TRAIL_DAMPING = { 0.42, 0.6, 0.8 } -- ... the root swings past and back when it stops, the tip least
local PITCH_KNEE, PITCH_MOST = 0.235, 0.29 -- a start slings it further: eased from 13.5 degrees on, never 16.6
local WAVE_RATE = 0.07 -- waves down the wisp in one tick while it hovers (one every 3.7 s at 2.4 studs) ...
local WAVE_GOING = 0.5 -- ... and this much quicker at its pace
local WAVE = 0.08 -- radians each joint rolls with it (4.6 degrees) ...
local WAVE_LAG = 0.8 -- ... each this far (radians of the wave) after the one before
local WAVE_SECOND, WAVE_SECOND_RATE, WAVE_SECOND_LAG = 0.035, 0.61, 0.5 -- a second wave, never in step
local SWING = 0.2 -- radians each joint swings OUT of a turn of one radian in one tick ...
local SWING_MOST = 0.035
local SWING_RATE = { 4.0, 2.9, 2.2 } -- ... each later than the one before (the Djinn's first, middle and last)
local SWISH = 0.06 -- hovering, now and then: one lazy swish that runs down the wisp
local ROLL_KNEE, ROLL_MOST = 0.14, 0.2 -- no joint of the wisp ever rolls 11.5 degrees (eased from 8 on)
-- the flame, foot to point (the table: 15 degrees of pitch a joint and 45 together, 10 of roll a joint and 30
-- together; beyond, it folds over the lump and stops being a flame)
local STREAM = { 0.175, 0.14, 0.105 } -- radians each joint streams BACK at its pace: 10, 8, 6 degrees (the sheet's)
local STREAM_RATE = { 2.6, 3.6, 4.6 } -- springs as the wisp's, a little quicker: a flame is lighter than a tail ...
local STREAM_DAMPING = { 0.45, 0.6, 0.8 } -- ... it swings forward past its rest when the wisp stops, once
local FLAME_PITCH_KNEE, FLAME_PITCH_MOST = 0.2, 0.255 -- eased from 11.5 degrees on, never 14.6
local FLICKER_RATE = 0.093 -- waves up the flame in one tick (one every 2.7 s at 2.4 studs): a third quicker
-- than the wisp's, and no multiple of it: the two are in step for a moment and out of it the next
local FLICKER = 0.06 -- radians each joint rolls with it (3.4 degrees: three of them move the point a tenth of
-- its height) ...
local FLICKER_LAG = 0.9 -- ... each this far after the one before: the foot leads, the point follows
local FLICKER_SECOND, FLICKER_SECOND_RATE, FLICKER_SECOND_LAG = 0.025, 0.57, 0.6 -- a second wave, never in step
local WAVER = 0.03 -- radians each joint nods back and forth with it besides (1.7 degrees), hovering and going
local WAVER_RATE = 0.71 -- ... at this share of the flicker's rate: the point draws no line and no circle
local FLAME_SWING_RATE = { 4.4, 3.2, 2.4 } -- it swings out of a turn as the wisp does, a moment sooner
local FLAME_ROLL_KNEE, FLAME_ROLL_MOST = 0.12, 0.17 -- no joint of the flame ever rolls 9.7 degrees (eased from 6.9)
-- the look: the whole lump turns, so it is SMALL and SLOW (the Djinn's head goes 26 degrees in 0.65 s)
local LOOK = {
	yaw = 0.3, -- 17 degrees to a side at the most
	-- (it looks neither up nor down: that would be the lean of a start, with the flame and the wisp on it)
	up = 0,
	down = 0,
	turn = 1.1, -- seconds a look takes: 17 degrees in that is slower than anything of its chains
	-- (seconds it looks straight ahead: the least, the mean, the most ...)
	least = 6,
	mean = 30,
	most = 90,
	-- (... and aside)
	asideLeast = 2,
	aside = 4,
	asideMost = 10,
	home = 0.75,
}
local LOOK_TURN, LOOK_TURN_MOST = 0.4, 0.15 -- into a turn its face goes first: the Djinn's head's share, and
-- half its most (8.6 degrees): here it is the whole animal that turns ahead of its way

-- The state -------------------------------------------------------------------------------------------------

function FrostWisp.new(rig, info)
	local seed = info.seed or 0
	local dice = Kit.dice(seed)
	local H = rig.height * TALL
	local tick = sqrt(H / Kit.G)
	local tempo = tick / 0.25 -- 1 for a wisp of 2.4 studs: a bigger one takes its time
	local at = rig.at
	-- (a big wisp turns more slowly, and looks about less often)
	local look = table.clone(LOOK)
	local slow = clamp(sqrt(tempo), 0.8, 2.4)
	for _, key in { "turn", "least", "mean", "most", "asideLeast", "aside", "asideMost" } do
		look[key] *= slow
	end
	local tail, flame = {}, {}
	for k, name in FrostWisp.map.tail do
		tail[k] = at[name]
	end
	for k, name in FrostWisp.map.limbs.F.bones do
		flame[k] = at[name]
	end
	return {
		pose = Kit.newPose(rig),
		dice = dice,
		seed = seed,
		phase = 0, -- waves down its wisp so far: what the tools take for its stride
		flicker = 0, -- waves up its flame so far
		H = H,
		tick = tick,
		tempo = tempo,
		look = look,
		pace = sqrt(FrostWisp.stroll.froude * Kit.G * FrostWisp.stroll.leg * rig.height),
		hips = at.Body_01, -- (the lump: the Djinn's hips, chest and head in one)
		tail = tail,
		flame = flame,
		-- what it is doing
		fresh = true,
		x = 0,
		z = 0,
		yaw = 0,
		vx = 0,
		vz = 0,
		w = 0,
		go = 0,
		going = false,
		speed = 0,
		push = 0,
		lean = { x = 0, v = 0 },
		bank = { x = 0, v = 0 },
		trail = Kit.springRow(#tail), -- how far each joint of the wisp trails, 0 to 1 and a little past
		stream = Kit.springRow(#flame), -- how far each joint of the flame streams back, the same
		swing = { 0, 0, 0 }, -- how far each joint of the wisp swings out of a turn (radians)
		flameSwing = { 0, 0, 0 }, -- ... and of the flame
		lookTurn = { x = 0, v = 0 },
		gaze = Kit.newGaze(),
		swishAt = -100,
		swishNext = (18 + 60 * Kit.roll(dice)) * tempo,
	}
end

-- One frame ---------------------------------------------------------------------------------------------------

function FrostWisp.step(S, dt, input)
	local pose = S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local H, tick, tempo = S.H, S.tick, S.tempo
	local t = input.t

	-- HOW FAST IT GOES, from where its pivot is
	local go, travel, _, push
	dt, go, travel, _, push = Kit.drift(S, dt, input, tick, GO_START, GO_STOP, false)

	-- THE CLOCKS OF ITS WISP AND OF ITS FLAME: they never stop, and run a little quicker when it travels
	local quicker = 1 + WAVE_GOING * travel
	S.phase += dt * WAVE_RATE / tick * quicker
	S.flicker += dt * FLICKER_RATE / tick * quicker

	-- THE SWELL it hovers on: two slow waves that are never in step, so that no two rises are alike
	local clock = t / tick
	local wave = 0.62 * Kit.hoverSwell(clock * SWELL_RATE + S.seed)
		+ 0.38 * sin(TAU * (clock * SWELL_RATE * SWELL_SECOND + 2.3 * S.seed))
	local keep = 1 - (1 - SWELL_GOING) * travel
	pose.bob, pose.ox, pose.oz = (HOVER + SWELL * wave * keep) * H, 0, 0

	-- THE LUMP tips into its travel and comes upright again when it stops, a little past and back once; it rolls
	-- into a turn; hovering it rocks, barely. And it is the head: hovering it is still, and now and then it looks
	-- somewhere, slowly, and holds that; into a turn its face goes first
	local lean = Kit.spring(S.lean, -LEAN * (go + PUSH * push), LEAN_RATE / tick, LEAN_DAMPING, dt)
	local bank = Kit.spring(S.bank, clamp(BANK * S.w * tick, -BANK_MOST, BANK_MOST) * travel, 2.2 / tick, 0.8, dt)
	local sway = SWAY * (1 - travel) * sin(TAU * (clock * SWELL_RATE * 0.37 + 1.7 * S.seed))
	local lookYaw = Kit.gaze(S.gaze, t, S.dice, S.look, not S.going and go < 0.05)
	Kit.holdLook(S, t)
	lookYaw += Kit.spring(
		S.lookTurn,
		clamp(LOOK_TURN * S.w * tick, -LOOK_TURN_MOST, LOOK_TURN_MOST) * travel,
		5 / tick,
		1,
		dt
	)
	local hips = S.hips
	rx[hips], ry[hips], rz[hips] = lean, lookYaw, bank + sway

	-- THE WISP trails behind when it travels, more at its root than at its tip, each joint a moment after the
	-- one before; it is left behind by a start and swings on past where it hangs when it stops
	local tail = S.tail
	local drag = go + SLING * push
	Kit.chainSpring(S.trail, drag, TRAIL_RATE, TRAIL_DAMPING, tick, dt)
	for k, bone in tail do
		rx[bone], ry[bone] = Kit.bound(-TRAIL[k] * S.trail[k].x, PITCH_KNEE, PITCH_MOST), 0
	end
	-- ... and sideways: it swings OUT of a turn (to its right in a turn to its left, as the roll of the lump
	-- swings it), a slow wave runs down it all the time, and hovering, now and then, one lazy swish
	local out = clamp(SWING * S.w * tick, -SWING_MOST, SWING_MOST) * travel
	Kit.chainTrail(S.swing, out, SWING_RATE, tick, dt)
	for k, bone in tail do
		rz[bone] = S.swing[k]
	end
	Kit.chainWave(pose, tail, "z", WAVE, TAU * (S.phase + S.seed), WAVE_LAG, 1, WAVE)
	Kit.chainWave(
		pose,
		tail,
		"z",
		WAVE_SECOND,
		TAU * (S.phase * WAVE_SECOND_RATE + 2.3 * S.seed),
		WAVE_SECOND_LAG,
		1,
		WAVE_SECOND
	)
	if go <= 0 and t >= S.swishNext then
		S.swishAt = t
		S.swishNext = t + Kit.wait(S.dice, 35, 80, 220) * tempo
	end
	Kit.chainPulse(pose, tail, "z", -SWISH, t, S.swishAt, 1.6 * tempo, 0.12 * tempo, 1, SWISH)
	-- (the bounds of this mesh: curves, not clamps)
	for _, bone in tail do
		rz[bone] = Kit.bound(rz[bone], ROLL_KNEE, ROLL_MOST)
	end

	-- THE FLAME is the same chain standing up: it streams BACK when the wisp travels (a positive pitch lays it
	-- back), more at its foot than at its point, and swings forward past its rest when the wisp stops; all the
	-- time it nods a little, slowly
	local flame = S.flame
	Kit.chainSpring(S.stream, drag, STREAM_RATE, STREAM_DAMPING, tick, dt)
	for k, bone in flame do
		rx[bone], ry[bone] = STREAM[k] * S.stream[k].x, 0
	end
	Kit.chainWave(pose, flame, "x", WAVER, TAU * (S.flicker * WAVER_RATE + 3.1 * S.seed), FLICKER_LAG, 1, WAVER)
	for _, bone in flame do
		rx[bone] = Kit.bound(rx[bone], FLAME_PITCH_KNEE, FLAME_PITCH_MOST)
	end
	-- ... and sideways: its point swings OUT of a turn too (a NEGATIVE roll sends the point of what stands up to
	-- its right), and it wavers on its own clock: the foot leads, the point follows
	Kit.chainTrail(S.flameSwing, -out, FLAME_SWING_RATE, tick, dt)
	for k, bone in flame do
		rz[bone] = S.flameSwing[k]
	end
	Kit.chainWave(pose, flame, "z", FLICKER, TAU * (S.flicker + 1.9 * S.seed + 0.37), FLICKER_LAG, 1, FLICKER)
	Kit.chainWave(
		pose,
		flame,
		"z",
		FLICKER_SECOND,
		TAU * (S.flicker * FLICKER_SECOND_RATE + 4.1 * S.seed),
		FLICKER_SECOND_LAG,
		1,
		FLICKER_SECOND
	)
	for _, bone in flame do
		rz[bone] = Kit.bound(rz[bone], FLAME_ROLL_KNEE, FLAME_ROLL_MOST)
	end
end

return FrostWisp
