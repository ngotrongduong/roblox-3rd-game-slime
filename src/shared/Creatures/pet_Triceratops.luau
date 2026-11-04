-- The Triceratops of the Valley (art/models/ready/pet_Triceratops.glb, 24 bones built here). A heavy dinosaur on
-- four short column legs (the leg is 30% of its height; the forelegs sprawl a little, the upper arm going out at
-- the elbow), standing SQUARE, with a skull, three horns and a huge frill that are ONE lump fused to the shoulders
-- and ride on ONE joint, and a long tail of four joints. Its joint map, and the MOTION OF THE MAGMA BULL
-- (pet_MagmaBull.luau: a heavy beast on short columns with a fused head, the Coral Kirin's walk slowed and
-- weighted as the Mammoth's), changed only where this body is another: docs/motion/pet_Triceratops.md says where.
-- What rules it is the FUSED HEAD: the frill sweeps into the shoulders beyond 10 to 15 degrees, so a look is 14
-- degrees at most, slow, and the frill stays still while it walks. There is no neck and no breath. Look at
-- art/models/rigs/pet_Triceratops_left.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local rad = math.rad
local TAU = math.pi * 2

local Dino = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Dino.map = {
	count = 24,
	tree = 2056266235,
	-- Root is the handle in the middle of the body: it drives nothing. Body_01 is the PELVIS (the hind legs and
	-- the tail hang on it), Body_02 the CHEST (the forelegs and the head hang on it)
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- (no neck: the frill sits on the shoulders) the skull, horns and frill are one lump on this joint (2,054
	-- vertices)
	head = { "Head" },
	-- the dock, two down the tail, the curl at its tip
	tail = { "Tail_01", "Tail_02", "Tail_03", "Tail_04" },
	-- THE FOUR LEGS ARE LISTED UNDER `limbs`, NOT UNDER `legs` (the Magma Bull's way round): the kit refuses a
	-- chain of `legs` whose last joint is more than 12% of the RIG's height over the ground, and the rig's height
	-- is the skull's joint, 0.765, with the fore feet at 0.102 and 0.111 (13 to 15%).
	limbs = {
		-- foreleg: the SHOULDER (inside the body), the ELBOW (the upper arm leaves the body sideways), the WRIST
		-- (the gold band), the FOOT (its claws are rigid on it)
		LF = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" } },
		RF = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" } },
		-- hind leg: the HIP, the STIFLE, the HOCK (it points back), the FOOT
		LH = { role = "leg", bones = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" } },
		RH = { role = "leg", bones = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" } },
	},
	-- (no `pairs`: the mesh's legs differ by 1 to 4%: each leg has its own numbers below)
	rigid = {},
}

-- HOW IT STROLLS in its plot: the Mammoth's very slow walk (a Froude number of 0.03, so that the game's run at
-- three times the speed is a Froude number of 0.27) for its own leg, 0.667 of the rig's height (0.510 of 0.765).
-- It stands a good while between two strolls and turns in a circle of 1.5 of the rig's height: the frill is
-- swept by every turn of the body.
Dino.stroll = { froude = 0.03, leg = 0.667, rest = { 5, 14 }, radius = 1.5 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- File units of the ready model, read off the write-up's table; the rig's height (its highest joint, the skull)
-- is 0.765. `centre` is how far BEHIND its rest place the middle of a step is, so that the planted point lies
-- under the hip: (hip z - foot z) / the rig. A hind foot stands 0.089 BEHIND its hip: the middle of its step is
-- `behind` of the way back to where it stands (0.08 of the file).
local H = 0.765
local TOE = 0.04 -- the claws lie this far ahead of the foot joint
local function centre(hipZ, footZ, behind)
	return (hipZ - footZ + (behind or 0)) / H
end
-- (foot height over the ground: the toe is on the ground, so the planted point is this far below it)
local function below(footY)
	return footY / H
end

local function fore(id, name, chain, hipZ, footZ, footY, elbow, wrist)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the foot is the LAST joint and carries the claws: it is the bone that is held against the ground)
		ankle = 4,
		front = 0.5,
		tip = { below = below(footY), ahead = TOE / H },
		centre = centre(hipZ, footZ),
		-- in the air elbow and wrist fold together, the wrist the more; on the ground nothing folds and
		-- nothing sinks. (The right foot reaches 0.109 forward of its wrist, the left 0.089: with the Bull's
		-- -1.55 the right leg gets LONGER as it folds, so the kit gave it no fold at all; `wrist` is the share.)
		fold = { swing = { 0, elbow, wrist }, skew = { 0, -0.2, 0.2 } },
		sink = 0,
		-- (a straight column)
		ease = true,
		-- (lifted low: a heavy beast on short legs shuffles)
		lift = { walk = 0.022, trot = 0.035 },
		-- the foot: flat, onto its toes late in the stance, hanging a little in the air
		pitch = {
			stance = { 0, 0, 0.72, 0, 1, -0.18 },
			swing = { 0, -0.18, 0.25, -0.2, 0.5, -0.08, 0.85, 0.05, 1, 0 },
		},
	}
end

local function hind(id, name, chain, hipZ, footZ, footY)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		front = 0.5,
		tip = { below = below(footY), ahead = TOE / H },
		centre = centre(hipZ, footZ, 0.08),
		-- stifle and hock fold and open together, on the ground as in the air (a zigzag)
		fold = { swing = { 0, -1.0, 1.2 }, stance = { 0, -1.0, 1.2 }, skew = { 0, -0.25, 0.25 } },
		sink = 0,
		open = 0.3,
		lift = { walk = 0.045, trot = 0.045 },
		liftSkew = 0.65,
		pitch = {
			stance = { 0, 0, 0.7, 0, 1, -0.25 },
			swing = { 0, -0.25, 0.35, -0.2, 0.8, 0.1, 1, 0 },
		},
	}
end

local CHAINS = Dino.map.limbs
-- (hip z, foot z, foot y of each leg, from the table of the write-up: the sides are not alike)
Dino.legs = {
	fore("LF", "front left leg", CHAINS.LF.bones, -0.632, -0.691, 0.102, 1.0, -1.3),
	fore("RF", "front right leg", CHAINS.RF.bones, -0.632, -0.720, 0.111, 1.0, -0.85),
	hind("LH", "hind left leg", CHAINS.LH.bones, 0.029, 0.118, 0.068),
	hind("RH", "hind right leg", CHAINS.RH.bones, 0.029, 0.118, 0.068),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH): the Magma Bull's lateral walk of long stances, and a
-- trot -------------------------------------------------------------------------------------------------------
local DESIGN = {
	-- (the kit steps a walker in the client's slow turn by itself: these are not lowered for it)
	start = 0.004,
	stop = 0.0015,
	-- a walk of four even beats in lateral sequence: left hind, left fore, right hind, right fore
	walk = {
		offsets = { 0.25, 0.75, 0, 0.5 },
		duty = { at = 0.66, slope = 0.03, ref = 0.35, least = 0.6, most = 0.68 },
		stride = { 2.3, 0.3 },
	},
	-- a trot of two beats: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.44, slope = 0.06, ref = 1, least = 0.34, most = 0.5 },
		stride = { 2.3, 0.3 },
		sweep = 0.44,
		from = 0.2,
		back = 0.14,
		shift = 0.4,
	},
	sweep = 0.41,
	finish = 0.25,
	settle = { far = 0.05, time = 1.6, least = 2, mean = 4, most = 10 },
	comfy = 0.999,
	letGo = 0.55,
	comeDown = 0.6,
}

-- THE BODY, THE HEAD, THE TAIL ------------------------------------------------------------------------------
local LEVEL = 0.6 -- the share of the croup's rise over the withers that its hind legs take up
local RUMP_MOST = 0.02 -- shares of its leg the rump comes down for a hind foot, at most
local HIP_DROP = 0.012 -- radians the rump drops on the side whose hind leg is in the air (heavy)
local SHOULDER_DROP = 0.005 -- ... and the chest for a foreleg
-- ITS LOOKS: skull, horns and frill are one lump with the shoulders (the Head is clean to 10 to 20 degrees; the
-- frill's rim tears at 30 and sweeps into the shoulders from 10 of pitch or yaw): a look is 14 degrees at most,
-- SLOW (1.8 seconds) and rare, and held long.
local LOOK = { yaw = 0.22, up = 0.05, down = 0.07, turn = 1.8, least = 3, mean = 30, aside = 5, most = 50, home = 0.85 }
local HEAD_SHARE = { 1 }
-- (what the one joint does is curved, never stopped dead: 12 degrees of yaw pass as they are, 14 are never
-- reached; the scan's yaw is +-15, its pitch -10 to +15)
local YAW_KNEE, YAW_MOST = rad(12), rad(14)
local PITCH_KNEE, PITCH_MOST = rad(7), rad(9)
local TURN_LEAD = 0.07 -- radians its head goes into a turn before the body, at most: 4 degrees
local TURN_RATE = 1.6 -- how quickly it does (the Bull's 2: a frill is not thrown into a turn)
-- THE TAIL, a long taper that sways as a chain, the dock first, the rest trailing. It is NEVER LOWERED (+ pitch
-- swings it down, into the ground from +20). Its joints are clean to 60 degrees, the sway is held to 15.
local TAIL_SWING = 0.05 -- radians at the dock, once a stride
local TAIL_LAG = 0.6 -- radians of the swing a joint is behind the one before
local TAIL_GAIN = 0.7 -- what a joint does of what the one before it does
local TAIL_UP = 0.2 -- radians the dock lifts the tail when it trots off (the dock passes into the haunch at -20)
local TAIL_SPEED = 0.11 -- the fastest the dock sways, radians in one sqrt(leg / G)
local TAIL_TURN = 0.03 -- radians at the dock for each radian a second it turns: the tail stays behind
local TAIL_RATE = 1.2 -- how quickly the tail follows a turn and lifts, at its size a second
local SWISH = 0.2 -- radians a swish goes to a side at the dock, standing: one, slowly
local SWISH_TIME = 12 -- how long it takes a joint, in units of sqrt(leg / G)
local SWISH_LATE = 1.5 -- ... and how much later each joint begins
local TAIL_KNEE, TAIL_MOST = rad(11), rad(15) -- a joint's turn to a side, curved over its last degrees
-- HOW FAR A LEG'S TOP JOINT MAY LEAN (the bend scan, docs/motion/pet_Triceratops.md): 15 degrees in (from 30 the
-- shoulder passes into the trunk), 30 out for a foreleg and 20 for a hind one (the haunch from 30). In a tight
-- spin the solver asks more: the lean is curved towards the limit there.
local LEAN_IN, LEAN_OUT_FORE, LEAN_OUT_HIND = rad(15), rad(30), rad(20)
local LEAN_KNEE = rad(4) -- ... over its last 4 degrees
-- HOW FAR EACH JOINT OF A LEG MAY PITCH, top joint first (degrees back, forward): the scan's, where the
-- shoulder passes into the trunk at -40 and the claws into themselves from 40.
local FORE_BENDS = { { -35, 30 }, { -40, 40 }, { -60, 60 }, { -40, 40 } } -- shoulder, elbow, wrist, foot
local HIND_BENDS = { { -40, 40 }, { -60, 60 }, { -60, 60 }, { -40, 40 } } -- hip, stifle, hock, foot
local BEND_KNEE = rad(4)
-- (a FORELEG cannot give)
local WITHERS_MOST = 0.035

-- A turn kept inside its two limits (`low` under 0, `high` over 0), curved over the last `knee` of each.
local function within(value, low, high, knee)
	if value < 0 then
		return Kit.bound(value, -low - knee, -low)
	end
	return Kit.bound(value, high - knee, high)
end

function Dino.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Dino.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		root = rig.root,
		pelvis = Kit.bone(rig, "Body_01"),
		chest = Kit.bone(rig, "Body_02"),
		head = Kit.chain(rig, "the head"),
		tail = Kit.chain(rig, "the tail"),
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		tailTurn = { x = 0, v = 0 },
		tailLift = { x = 0, v = 0 },
		tailSway = { x = 0, v = 0 },
		swishAt = -100,
		swishSide = 1,
		swishNext = 6 + 24 * Kit.roll(dice),
	}
end

function Dino.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it. The rump never sits down for a foot.
	local most = RUMP_MOST * W.h
	local least = WITHERS_MOST * W.h
	local front = -Kit.both(math.min(legs[1].drop, least), math.min(legs[2].drop, least))
	local back = -Kit.both(math.min(legs[3].drop, most), math.min(legs[4].drop, most))
	if back > front then
		back -= LEVEL * (back - front)
	end
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (NO BREATH: the columns have no slack, a heavy beast stands as stone)
	local lean = pitch
	pose.bob, pose.ox, pose.oz = bob, 0, 0
	rx[S.root] = lean
	-- (the pelvis carries the chest: what it rolls, the chest's one joint at the loin rolls back)
	local hip = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local shoulder = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	rz[S.pelvis] = hip
	rz[S.chest] = shoulder - 0.8 * hip
	Kit.solve(W, pose)
	-- (a leg leans no further in than its twin lets it, nor further out than its skin: curved, and the foot
	-- takes out again exactly what is left of the lean, so the sole stays level across)
	for k, leg in legs do
		local bends = if k <= 2 then FORE_BENDS else HIND_BENDS
		local out = if k <= 2 then LEAN_OUT_FORE else LEAN_OUT_HIND
		for j, i in leg.b do
			rx[i] = within(rx[i], rad(bends[j][1]), rad(bends[j][2]), BEND_KNEE)
		end
		local top, foot = leg.b[1], leg.b[leg.ankle]
		local lean1 = if leg.side < 0
			then within(rz[top], -out, LEAN_IN, LEAN_KNEE)
			else within(rz[top], -LEAN_IN, out, LEAN_KNEE)
		rz[top], rz[foot] = lean1, -lean1
	end

	-- THE HEAD: ONE joint with the whole frill on it, the steadiest part. The head undoes ALL the trunk does, its
	-- lean and its roll, so the frill is level and still over a body that walks; it looks where it goes; standing,
	-- it is still, and now and then turns slowly to look somewhere, never from one side straight to the other.
	local head = S.head
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	if gaze.t0 == t and gaze.y0 * gaze.y1 < 0 then
		-- (a look across from one side to the other would be twice the turn in the same time: it comes back to
		-- straight ahead first)
		gaze.y1, gaze.p1 = 0, 0
		yaw, look = gaze.y0, gaze.p0
	end
	-- (into a turn the head goes first: a little, and slowly)
	yaw += Kit.spring(
		S.lookTurn,
		Kit.clamp(0.3 * W.w, -TURN_LEAD, TURN_LEAD) * amount,
		TURN_RATE / (tick / 0.29),
		1,
		dt
	)
	yaw = Kit.bound(yaw, YAW_KNEE, YAW_MOST)
	local nod = Kit.bound(look - lean, PITCH_KNEE, PITCH_MOST)
	local roll = -(shoulder + 0.2 * hip)
	Kit.zero(pose, head)
	Kit.spread(pose, head, HEAD_SHARE, nod, yaw, roll)

	-- THE TAIL: it sways on its dock once a stride and stays behind in a turn, each joint a little later and less
	-- than the one before; it lifts a little when it trots off and, standing, swishes now and then: once,
	-- slowly. It is never lowered and never whips.
	local tail = S.tail
	Kit.zero(pose, tail)
	-- (the dock never sways FASTER than it does at the stroll: the quicker the strides the smaller the sway)
	local swaying = Kit.clamp(Kit.spring(S.tailSway, amount, TAIL_RATE / (tick / 0.29), 1, dt), 0, 1)
	local sway = swaying * math.min(TAIL_SWING, TAIL_SPEED / (TAU * math.max(W.f * tick, 1e-3)))
	Kit.chainWave(pose, tail, "y", sway, TAU * (W.phase - 0.15), TAIL_LAG, TAIL_GAIN, TAIL_MOST)
	Kit.chainBend(
		pose,
		tail,
		"y",
		Kit.spring(S.tailTurn, -TAIL_TURN * Kit.clamp(W.w, -2, 2), TAIL_RATE / (tick / 0.29), 1, dt),
		TAIL_GAIN
	)
	-- (it lifts and comes down slowly, on a spring that does not overshoot)
	Kit.chainBend(
		pose,
		tail,
		"x",
		-TAIL_UP * Kit.clamp(Kit.spring(S.tailLift, W.g * amount, TAIL_RATE / (tick / 0.29), 1, dt), 0, 1),
		TAIL_GAIN
	)
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 12, 30, 70)
	end
	Kit.chainPulse(
		pose,
		tail,
		"y",
		SWISH * S.swishSide,
		t,
		S.swishAt,
		SWISH_TIME * tick,
		SWISH_LATE * tick,
		TAIL_GAIN,
		TAIL_MOST
	)
	for _, i in tail do
		ry[i] = Kit.bound(ry[i], TAIL_KNEE, TAIL_MOST)
	end
end

return Dino
