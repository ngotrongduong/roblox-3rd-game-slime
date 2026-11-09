-- The Magma Bull of the Volcano (art/models/ready/pet_MagmaBull.glb, 26 bones built here under the cats' names
-- the Coral Kirin and the Ibex have). A heavy bull of dark stone that stands SQUARE on four short column legs
-- (the leg is 36% of its height), a hump of neck, mane, collar and dewlap fused with the shoulders, two huge
-- lava horns rigid on the skull (0.24 to each side of it: a third of its width), a whip of a tail with a rigid
-- flame. Its joint map, and the MOTION OF THE CORAL KIRIN (pet_CoralKirin.luau: a hoofed beast that stands
-- square and walks in lateral sequence) on it, slowed and weighted as the Mammoth is (a duty that is longer, a
-- run that is a quick trot, low lifts), changed only where this body is another: docs/motion/pet_MagmaBull.md
-- says where. What rules it is the FUSED NECK: neck and skull are clean to 10 degrees a joint, so a look is 20
-- degrees at most and slow. Look at art/models/rigs/pet_MagmaBull_left.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local rad = math.rad
local TAU = math.pi * 2

local Bull = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Bull.map = {
	count = 26,
	tree = 855521665,
	-- Root is the handle in the middle of the body: it drives nothing. Body_01 is the PELVIS (the hind legs and
	-- the tail hang on it), Body_02 the LOIN AND CHEST (the forelegs and the neck hang on it)
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- the neck: its foot low in the chest, its middle; then the base of the skull (head, ring and both horns are
	-- rigid on it: 953 vertices)
	neck = { "Neck_01", "Neck_02" },
	head = { "Head" },
	-- the dock, two on the whip, the base of the rigid flame
	tail = { "Tail_01", "Tail_02", "Tail_03", "Tail_04" },
	-- THE FOUR LEGS ARE LISTED UNDER `limbs`, NOT UNDER `legs` (the Bloom Sprite's and the Coral Kirin's way
	-- round): the kit refuses a chain of `legs` whose last joint is more than 12% of the RIG's height over the
	-- ground. The rig's height is the skull's joint, 0.484, and the fetlocks are 0.066 to 0.081 up: 14 to 17%.
	limbs = {
		-- foreleg: the SHOULDER (inside the body), the ELBOW (where the column leaves the chest), the CARPUS, the
		-- FETLOCK (the hoof is rigid on it)
		LF = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" } },
		RF = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" } },
		-- hind leg: the HIP, the STIFLE (forward), the HOCK (it points back), the FETLOCK
		LH = { role = "leg", bones = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" } },
		RH = { role = "leg", bones = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" } },
	},
	-- (no `pairs`: the mesh's legs differ by 1 to 4%: each leg has its own numbers below)
	rigid = {},
}

-- HOW IT STROLLS in its plot: the Mammoth's very slow walk (a Froude number of 0.03, so that the game's run at
-- three times the speed is a Froude number of 0.27) for its own leg, 0.514 of the rig's height (0.249 of 0.484).
-- It stands a good while between two strolls and turns in a circle of 1.5 of the rig's height: the horns are
-- swept by every turn of the body.
Bull.stroll = { froude = 0.03, leg = 0.514, rest = { 5, 14 }, radius = 1.5 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- File units of the ready model, read off the write-up's table; the rig's height (its highest joint, the skull)
-- is 0.484. `centre` is how far BEHIND its rest place the middle of a step is, so that the planted point lies
-- under the hip: the middle of a step puts the FETLOCK (the bone that is held) under the hip, (hip z - fetlock
-- z) / the rig. (The Mammoth's formula adds the reach of its ball: here that put the shoulder's swing at -29 to
-- -2 degrees, all behind its stand, where the Kirin's is -24 to +12.)
local H = 0.484
local TOE = 0.03 -- the toe of a hoof lies this far ahead of its fetlock (a hoof 0.06 long, a gold band above)
-- (a hind leg is a zigzag whose fetlock stands 0.075 BEHIND its hip: put under the hip it asked the hip for 15
-- to 40 degrees forward all the time and the hoof slid 12 to 22% of the stride. The middle of its step is
-- `behind` of the way back to where it stands: 0.058 of the file, the stifle's reach.)
local function centre(hipZ, fetlockZ, behind)
	return (hipZ - fetlockZ + (behind or 0)) / H
end
-- (fetlock height over the ground: the toe is on the ground, so the planted point is this far below it)
local function below(fetlockY)
	return fetlockY / H
end

local function fore(id, name, chain, hipZ, fetlockZ, fetlockY)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the fetlock is the LAST joint and carries the hoof: it is the bone that is held against the ground)
		ankle = 4,
		front = 0.5,
		tip = { below = below(fetlockY), ahead = TOE / H },
		centre = centre(hipZ, fetlockZ),
		-- in the air elbow and carpus fold together, the carpus the more; on the ground nothing folds and
		-- nothing sinks (the Kirin's: a hoof tilted about its toe would push its heel into the ground)
		fold = { swing = { 0, 1.0, -1.55 }, skew = { 0, -0.2, 0.2 } },
		sink = 0,
		-- (a straight column, as the Kirin's and the Camel's)
		ease = true,
		-- (lifted low: a heavy beast on short legs shuffles)
		lift = { walk = 0.022, trot = 0.035 },
		-- the hoof: flat, onto its toe late in the stance, hanging a little in the air (the Kirin's)
		pitch = {
			stance = { 0, 0, 0.72, 0, 1, -0.18 },
			swing = { 0, -0.18, 0.25, -0.2, 0.5, -0.08, 0.85, 0.05, 1, 0 },
		},
	}
end

local function hind(id, name, chain, hipZ, fetlockZ, fetlockY)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		front = 0.5,
		tip = { below = below(fetlockY), ahead = TOE / H },
		centre = centre(hipZ, fetlockZ, 0.062),
		-- stifle and hock fold and open together, on the ground as in the air (the Kirin's zigzag)
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

local CHAINS = Bull.map.limbs
-- (hip z, fetlock z, fetlock y of each leg, from the table of the write-up: the sides are not alike)
Bull.legs = {
	fore("LF", "front left leg", CHAINS.LF.bones, -0.240, -0.270, 0.066),
	fore("RF", "front right leg", CHAINS.RF.bones, -0.240, -0.271, 0.069),
	hind("LH", "hind left leg", CHAINS.LH.bones, 0.150, 0.225, 0.071),
	hind("RH", "hind right leg", CHAINS.RH.bones, 0.150, 0.228, 0.081),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH): the Kirin's lateral walk with the Mammoth's longer
-- stance, and a trot -------------------------------------------------------------------------------------------
local DESIGN = {
	-- (the kit steps a walker in the client's slow turn by itself: these are not lowered for it)
	start = 0.004,
	stop = 0.0015,
	-- a walk of four even beats in lateral sequence: left hind, left fore, right hind, right fore
	walk = {
		offsets = { 0.25, 0.75, 0, 0.5 },
		-- (the Mammoth's duty: a heavy beast is longer on the ground)
		duty = { at = 0.66, slope = 0.03, ref = 0.35, least = 0.6, most = 0.68 },
		stride = { 2.3, 0.3 },
	},
	-- a trot of two beats: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.44, slope = 0.06, ref = 1, least = 0.34, most = 0.5 },
		stride = { 2.3, 0.3 },
		sweep = 0.44,
		-- (the game's run is a Froude number of 0.27 here: it trots from 0.2, the Mammoth's 0.15 and the Kirin's
		-- 0.3 being the two ends)
		from = 0.2,
		back = 0.14,
		shift = 0.4,
	},
	-- (the Kirin's 0.42, shorter: a hind leg that is a short zigzag runs out of reach at the end of its push)
	sweep = 0.41,
	finish = 0.25,
	settle = { far = 0.05, time = 1.6, least = 2, mean = 4, most = 10 },
	comfy = 0.999,
	letGo = 0.55,
	comeDown = 0.6,
}

-- THE BODY, THE HEAD, THE TAIL ------------------------------------------------------------------------------
local LEVEL = 0.6 -- the share of the croup's rise over the withers that its hind legs take up
local RUMP_MOST = 0.02 -- shares of its leg the rump comes down for a hind hoof, at most
local HIP_DROP = 0.012 -- radians the rump drops on the side whose hind leg is in the air (heavy: the Kirin's 0.04)
local SHOULDER_DROP = 0.005 -- ... and the chest for a foreleg
-- ITS LOOKS: neck and skull are one lump with the hump (clean to 10 degrees a joint, the skull to 20), and the
-- horns span the whole width: a look is 17 degrees at most, SLOW (1.6 seconds) and rare, and held long.
local LOOK = { yaw = 0.3, up = 0.05, down = 0.08, turn = 1.6, least = 3, mean = 30, aside = 5, most = 50, home = 0.85 }
-- (a look is shared over the three joints, the skull most: of 20 degrees the first joint of the neck has 4, the
-- second 6, the skull 10; the scan's limits are 10, 10 and 20 for a turn, +5, +10 and +15 for a nod down, which
-- is why the first joint, the tightest, has the least)
local NECK_SHARE = { 0.2, 0.3 }
local HEAD_SHARE = { 0.5 }
-- (what the three do together is curved, never stopped dead: 17 degrees of yaw pass as they are, 20 are never
-- reached)
local YAW_KNEE, YAW_MOST = rad(17), rad(20)
-- (the same for the pitch: the look and all of the trunk's lean undone, as the Kirin's; 18 degrees shared
-- 0.2, 0.3, 0.5 are 3.6, 5.4 and 9 against the scan's +5, +10 and +15 down)
local PITCH_KNEE, PITCH_MOST = rad(12), rad(18)
local TURN_LEAD = 0.1 -- radians its head goes into a turn before the body, at most: 6 degrees
local TURN_RATE = 2 -- how quickly it does (the Kirin's 2.5: horns are not thrown into a turn)
-- THE TAIL, a thin whip with a flame: it sways as a chain, the dock first, the rest trailing; the flame must
-- keep out of the hind legs (it is never lowered). Its joints are clean to 60 degrees, the sway is held to 15.
local TAIL_SWING = 0.05 -- radians at the dock, once a stride (the Kirin's: 0.07 made the whole tail turn too fast in a spin)
local TAIL_LAG = 0.6 -- radians of the swing a joint is behind the one before
local TAIL_GAIN = 0.7 -- what a joint does of what the one before it does
local TAIL_UP = 0.22 -- radians the dock lifts the whip when it trots off
local TAIL_SPEED = 0.11 -- the fastest the dock sways, radians in one sqrt(leg / G)
local TAIL_TURN = 0.03 -- radians at the dock for each radian a second it turns: the whip stays behind
local TAIL_RATE = 1.2 -- how quickly the whip follows a turn and lifts, at its size a second (the Kirin's 1.5)
local SWISH = 0.2 -- radians a swish goes to a side at the dock, standing: one, slowly
local SWISH_TIME = 12 -- how long it takes a joint, in units of sqrt(leg / G)
local SWISH_LATE = 1.5 -- ... and how much later each joint begins
local TAIL_KNEE, TAIL_MOST = rad(11), rad(15) -- a joint's turn to a side, curved over its last degrees
-- HOW FAR A LEG'S TOP JOINT MAY LEAN (the bend scan, docs/motion/pet_MagmaBull.md): 15 degrees in (from 30 the
-- left shoulder passes into the hump), 30 out for a foreleg and 20 for a hind one (the right hip passes into the
-- belly at 30). In a tight spin the solver asks more: the lean is curved towards the limit there.
local LEAN_IN, LEAN_OUT_FORE, LEAN_OUT_HIND = rad(15), rad(30), rad(20)
local LEAN_KNEE = rad(4) -- ... over its last 4 degrees
-- HOW FAR EACH JOINT OF A LEG MAY PITCH, top joint first (degrees back, forward): the scan's, where the right
-- shoulder passes into the hump from +20 and a fetlock into its own hoof from 40.
local FORE_BENDS = { { -30, 15 }, { -40, 25 }, { -60, 30 }, { -30, 35 } } -- shoulder, elbow, carpus, fetlock
local HIND_BENDS = { { -40, 40 }, { -45, 45 }, { -30, 60 }, { -40, 30 } } -- hip, stifle, hock, fetlock
local BEND_KNEE = rad(4)
-- (a FORELEG cannot give: as the Kirin's)
local WITHERS_MOST = 0.035

-- A turn kept inside its two limits (`low` under 0, `high` over 0), curved over the last `knee` of each.
local function within(value, low, high, knee)
	if value < 0 then
		return Kit.bound(value, -low - knee, -low)
	end
	return Kit.bound(value, high - knee, high)
end

function Bull.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Bull.legs do
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
		neck = Kit.chain(rig, "the neck"),
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

function Bull.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it (the Kirin's). The rump never sits down for a hoof.
	local most = RUMP_MOST * W.h
	local least = WITHERS_MOST * W.h
	local front = -Kit.both(math.min(legs[1].drop, least), math.min(legs[2].drop, least))
	local back = -Kit.both(math.min(legs[3].drop, most), math.min(legs[4].drop, most))
	if back > front then
		back -= LEVEL * (back - front)
	end
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (NO BREATH, which the Kirin has: its columns are only 4% longer than its hips are high, so the least turn of
	-- the root asks a leg to give and the legs moved 39% of the time it stood. A heavy bull stands as stone)
	local lean = pitch
	pose.bob, pose.ox, pose.oz = bob, 0, 0
	rx[S.root] = lean
	-- (the pelvis carries the chest: what it rolls, the chest's one joint at the loin rolls back)
	local hip = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local shoulder = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	rz[S.pelvis] = hip
	rz[S.chest] = shoulder - 0.8 * hip
	Kit.solve(W, pose)
	-- (a leg leans no further in than its twin lets it, nor further out than its skin: curved, and the fetlock
	-- takes out again exactly what is left of the lean, so the hoof stays level across)
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

	-- THE HEAD: the steadiest part, and here the one with the narrowest skin: a degree at the skull is a hand's
	-- breadth at the tip of a horn. The neck undoes ALL the trunk does, its lean and its roll, so the head is
	-- level and still over a body that walks; it looks where it goes; standing, it is still, and now and then
	-- turns slowly to look somewhere, never from one side straight to the other.
	local neck, head = S.neck, S.head
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
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	Kit.spread(pose, neck, NECK_SHARE, nod, yaw, roll)
	Kit.spread(pose, head, HEAD_SHARE, nod, yaw, roll)

	-- THE TAIL: the whip sways on its dock once a stride and stays behind in a turn, each joint a little later
	-- and less than the one before (the Kirin's wave); it lifts a little when it trots off and, standing,
	-- swishes now and then: once, slowly. It is never lowered and never whips.
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

return Bull
