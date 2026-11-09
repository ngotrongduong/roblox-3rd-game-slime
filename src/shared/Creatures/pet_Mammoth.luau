-- The Mammoth of the Peaks (art/models/ready/pet_Mammoth.glb, 25 bones built here: ONE bone for the trunk of
-- the body under the cap of snow, NO neck, NO tail, ears fused to the skull, four column legs of four joints
-- and a nose of six). Its joint map, and the CAMEL's motion (pet_Camel.luau: a tall heavy walker on column legs
-- with one trunk bone) on it, changed only where this body is another: docs/motion/pet_Mammoth.md says where.
-- Look at art/models/rigs/pet_Mammoth_left.png beside this file.
-- "Trunk_01..06" are the NOSE (it hangs from the head); the tools' label "Trunk" is the body.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Mammoth = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Mammoth.map = {
	count = 25,
	tree = 764796299, -- (the print of the ready skeleton's tree)
	-- Root lies at mid body and drives nothing. Body_01 is the WHOLE TRUNK, hips to withers: the cap of snow
	-- and its icicles are one rigid mass on it and nothing may bend under them
	root = "Root",
	spine = { "Root", "Body_01" },
	-- (no neck: the head turns about ONE joint, the back of the skull; the ears, the crown and the four tusks
	-- are its skin)
	head = { "Head" },
	-- the NOSE, six joints hanging from the head: where it comes free of the face, then down to the start of the
	-- curl, the bottom of the curl and the tip. The kit's tail chain is what moves it ("the tail" below)
	tail = { "Trunk_01", "Trunk_02", "Trunk_03", "Trunk_04", "Trunk_05", "Trunk_06" },
	legs = {
		-- shoulder (inside the chest), elbow (where the column leaves the belly), wrist, foot (a flat round pad)
		LF = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" },
		RF = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" },
		-- hip, stifle, hock, foot
		LH = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" },
		RH = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" },
	},
	-- (no `pairs`: no joint of the two sides is the mirror of the other, to 0.01 .. 0.03)
	rigid = {},
}

-- HOW IT STROLLS in its plot: very slowly, and it stands a good while between two strolls.
Mammoth.stroll = { froude = 0.03, leg = 0.68, rest = { 6, 16 }, radius = 1.2 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- File units of the ready model (the rig's height, its highest joint, is 0.508): every joint was read off
-- docs/motion/pet_Mammoth.md. `centre` is how far BEHIND the rest place of the contact the middle of a step is, so that
-- it lies under the hip: the model stands with its fore feet ahead of the shoulders and its hind feet behind
-- the hips, by a different amount each leg.
local H = 0.508
local BALL = 0.025 -- the ball of the foot lies this far ahead of the foot joint: the pad rolls over it
local function centre(hipZ, footZ)
	return (hipZ - (footZ - BALL)) / H
end

local function fore(id, name, chain, hipZ, footZ)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4, -- the foot joint holds the whole pad (one bone, no pastern)
		front = 0.5,
		-- (the sole is 0.037 under the foot joint: the pad's flat underside on the ground)
		tip = { below = 0.037 / H, ahead = BALL / H },
		centre = centre(hipZ, footZ),
		-- the column stays near straight under load and bends a little in the air: the elbow forward, the wrist back
		-- (the foot comes up and under, never swung out), no fold on the ground
		fold = { swing = { 0, 0.9, -1.15 }, stance = { 0, 0.9, -1.15 }, skew = { 0, -0.3, 0.3 } },
		sink = 0, -- (the pad does not tilt under the load)
		-- (a column that stands straight: the fold is eased in and out over the ends of the swing, the Camel's)
		ease = true,
		-- (a foot that lifts 5% of the leg: an elephant's step is a shuffle, not a stride over something)
		lift = { walk = 0.04, trot = 0.045 },
		-- the pad stays flat, its heel comes up a very little as it pushes off, hangs a very little in the air
		pitch = {
			stance = { 0, 0, 0.75, 0, 1, -0.1 },
			swing = { 0, -0.1, 0.3, -0.12, 0.85, 0.04, 1, 0 },
		},
	}
end

local function hind(id, name, chain, hipZ, footZ)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		front = 0.5,
		tip = { below = 0.037 / H, ahead = BALL / H },
		centre = centre(hipZ, footZ),
		-- stifle and hock fold and open together, on the ground as in the air (the hind leg is a slight Z)
		fold = { swing = { 0, -1.0, 0.9 }, stance = { 0, -1.0, 0.9 }, skew = { 0, -0.25, 0.25 } },
		sink = 0,
		open = 0.05,
		lift = { walk = 0.04, trot = 0.045 },
		pitch = {
			stance = { 0, 0, 0.75, 0, 1, -0.12 },
			swing = { 0, -0.12, 0.3, -0.15, 0.85, 0.04, 1, 0 },
		},
	}
end

-- (hip z, foot joint z of each leg, from the table of the write-up: the sides are not alike)
Mammoth.legs = {
	fore("LF", "front left leg", Mammoth.map.legs.LF, 0.000, -0.030),
	fore("RF", "front right leg", Mammoth.map.legs.RF, 0.010, -0.013),
	hind("LH", "hind left leg", Mammoth.map.legs.LH, 0.337, 0.377),
	hind("RH", "hind right leg", Mammoth.map.legs.RH, 0.347, 0.389),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH) ---------------------------------------------------
-- An elephant WALKS in a lateral sequence (the hind foot lands, the fore foot of its side a sixth of a stride
-- after it, the other side half a stride later) and never runs: its fast gait is a quicker walk with a longer
-- step in which a foot is always on the ground. The kit's second gait is used for that (the "trot" slot) with
-- the SAME footfalls and a duty that never falls under a half: two feet down at least, never a flight.
local DESIGN = {
	-- (lower than the Camel's 0.004 and 0.0015: it strolls at a Froude number of 0.03 and turns on the spot at
	-- a fifth of that; stopping its steps while it still moved left its feet behind and under the ground)
	start = 0.002,
	stop = 0.0007,
	walk = {
		offsets = { 0.16, 0.66, 0, 0.5 },
		duty = { at = 0.66, slope = 0.03, ref = 0.35, least = 0.6, most = 0.68 },
		stride = { 2.3, 0.3 },
	},
	trot = {
		offsets = { 0.16, 0.66, 0, 0.5 },
		duty = { at = 0.58, slope = 0.04, ref = 0.3, least = 0.52, most = 0.62 },
		stride = { 2.3, 0.3 },
		sweep = 0.5, -- (a longer step, but a hip swinging 20 degrees at most of the 30 its skin takes)
		from = 0.15,
		back = 0.1,
		shift = 0.8,
	},
	sweep = 0.42,
	finish = 0.25,
	settle = { far = 0.14, time = 2, least = 3, mean = 8, most = 18 },
	comfy = 1, -- (a column that stands straight: it stands exactly as long as it was modelled, and no fold is asked of it standing)
	letGo = 0.55,
	comeDown = 0.45,
}

-- THE BODY, THE HEAD, THE NOSE ------------------------------------------------------------------------------
local LEVEL = 0.6 -- the share of the croup's rise over the withers that its hind legs take up (the Camel's)
local LEVEL_FORE = 0 -- (its fore legs are straight columns: they cannot take up what the withers would rise over the croup)
local SWAY = 0.025 -- radians the trunk rolls to the side whose legs are in the air (heavy: a degree and a half)
local SHIFT = 0.006 -- shares of its leg the trunk moves over the side that stands
local BREATH = 0.004 -- radians: barely there
local HEAD_KEEP = 0.15 -- the share of the trunk's pitch the head keeps
local NOD = 0.02 -- radians the head nods at the walk, twice a stride
-- (the skull and the ears touch the cap of snow past 15 degrees: it looks about seldom, little, and slowly)
local LOOK = { yaw = 0.25, up = 0.06, down = 0.1, turn = 0.9, least = 3, mean = 16, aside = 4, most = 45, home = 0.85 }
-- THE NOSE: it swings forward and back once a stride and sways a little side to side, each joint a little
-- later and a little more than the one above it (a lagged wave, never a whip), and every so often it lifts
-- and curls while the Mammoth stands.
local NOSE_SWING = 0.05 -- radians of pitch at the first joint, once a stride
local NOSE_SWAY = 0.035 -- radians of roll at the first joint, once a stride (it hangs: roll is its side to side)
local NOSE_LAG = 0.55 -- radians of the swing a joint is behind the one above
local NOSE_GAIN = 1.12
local NOSE_MOST = 0.16 -- radians a joint turns by a wave at most (9 degrees; 30 is what its skin takes)
local NOSE_IDLE_SWAY = 0.03 -- radians it sways on its own, standing, once in 7 seconds
local NOSE_CURL = 0.09 -- radians of pitch at the first joint of a lift and curl
local NOSE_CURL_GAIN = 1.15
local NOSE_CURL_MOST = 0.3 -- 17 degrees a joint; the sum of six stays under 100

-- Skin-safe curves, not clamps (the Snow Leopard's): unchanged to nine tenths of the bend its skin takes
-- cleanly (docs/motion/pet_Mammoth.md, the bend-limit table: a shoulder or hip 30, the joints below 45, a
-- hip's roll 10 degrees), then eased towards it, so that the foot of a fast step is off the ground by a hair
-- rather than a skin torn. Steady strides lie under the knees.
local TOP_PITCH, LOWER_PITCH, TOP_ROLL = math.rad(30), math.rad(45), math.rad(10)
local function safeLeg(pose, leg)
	for j, i in leg.b do
		local most = if j == 1 then TOP_PITCH else LOWER_PITCH
		pose.rx[i] = Kit.bound(pose.rx[i], 0.9 * most, most)
	end
	local top, foot = leg.b[1], leg.b[leg.n]
	pose.rz[top] = Kit.bound(pose.rz[top], 0.9 * TOP_ROLL, TOP_ROLL)
	pose.rz[foot] = -pose.rz[top] -- the pad stays level across its width under that lean
end

function Mammoth.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Mammoth.legs do
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
		trunk = Kit.bone(rig, "Body_01"),
		head = Kit.chain(rig, "the head"),
		tail = Kit.chain(rig, "the tail"), -- (the nose)
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		noseTurn = { x = 0, v = 0 },
		curlAt = -100,
		curlNext = 6 + 14 * Kit.roll(dice),
	}
end

function Mammoth.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it (the Camel's); it sways once a stride towards the side
	-- whose legs stand, a little
	local front, back = -Kit.girdle(W, 1, 2), -Kit.girdle(W, 3, 4)
	if back > front then
		back -= LEVEL * (back - front)
	else
		front -= LEVEL_FORE * (front - back)
	end
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (the first step of a walk sets three feet down for a moment and the see-saw jumps to ten degrees: it is
	-- eased towards nine, a curve with no corner; the steady see-saw of a walk is two or three and lies under the knee)
	local eased = Kit.bound(pitch, math.rad(6), math.rad(9))
	bob, pitch = bob + (eased - pitch) * (S.zFront - S.zRoot), eased
	local side = 0.5 * (Kit.lifted(legs[1]) + Kit.lifted(legs[3]) - Kit.lifted(legs[2]) - Kit.lifted(legs[4]))
	local sway = SWAY * side
	local breath = BREATH * sin(t * TAU * 0.07 / tick + S.seed * TAU) * (1 - amount)
	pose.bob, pose.ox, pose.oz = bob - breath * (S.zRoot - S.zFront), SHIFT * W.h * side, 0
	rx[S.root] = pitch + breath
	rz[S.trunk] = sway
	Kit.solve(W, pose)
	for _, leg in legs do
		safeLeg(pose, leg)
	end

	-- THE HEAD (one joint): it cancels what the trunk does, nods a very little at the walk, and now and then
	-- looks somewhere, never further than 15 degrees
	local head = S.head
	Kit.zero(pose, head)
	local h = head[1]
	rx[h] = -(1 - HEAD_KEEP) * pitch + NOD * amount * (1 - W.g) * cos(2 * TAU * legs[1].phi)
	rz[h] = -(1 - HEAD_KEEP) * sway
	local yaw, look = Kit.gaze(S.gaze, t, S.dice, LOOK, not W.moving)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.2 * W.w, -0.25, 0.25) * amount, 5 / (tick / 0.29), 1, dt)
	rx[h] = Kit.bound(rx[h] + look, math.rad(9), math.rad(12)) -- (a curve with no corner, never past 12)
	ry[h] = yaw

	-- THE NOSE: lagged waves down the chain, a lean away from a turn, and now and then a lift and curl
	local nose = S.tail
	Kit.zero(pose, nose)
	-- (the swing is scaled by the strides a second, in units of its size: a slow stroll (0.28 a tick) swings it
	-- whole, the quicker strides of the fast walk less, so that a joint never turns faster than 60 degrees a second)
	-- (and a small one, whose strides are quick, swings it less: the tick of the size the game shows it at is 0.37)
	local calm = amount * amount * Kit.clamp(0.3 / math.max(W.f * tick, 0.01), 0, 1) * math.min(1, tick / 0.37)
	Kit.chainWave(pose, nose, "x", NOSE_SWING * calm, TAU * (W.phase - 0.1), NOSE_LAG, NOSE_GAIN, NOSE_MOST)
	Kit.chainWave(pose, nose, "z", NOSE_SWAY * calm, TAU * (W.phase - 0.35), NOSE_LAG, NOSE_GAIN, NOSE_MOST)
	-- (standing, it sways on its own, slowly, each joint behind the one above)
	Kit.chainWave(
		pose,
		nose,
		"z",
		NOSE_IDLE_SWAY * (1 - amount),
		t * TAU / (7 * tick / 0.29) + S.seed * TAU,
		0.5,
		1.1,
		NOSE_MOST
	)
	Kit.chainBend(
		pose,
		nose,
		"z",
		Kit.spring(S.noseTurn, -0.025 * Kit.clamp(W.w, -2.5, 2.5), 3 / (tick / 0.29), 0.6, dt),
		1.1
	)
	if not W.moving and t >= S.curlNext then
		S.curlAt = t
		-- (never sooner than the last curl has run down the whole nose: 9 s and half a second a joint, in the
		-- unit of its size, so that a new one does not cut an old one off)
		local unit = tick / 0.29
		S.curlNext = t + Kit.wait(S.dice, 12 * unit, 22 * unit, 50 * unit)
	end
	Kit.chainPulse(
		pose,
		nose,
		"x",
		NOSE_CURL,
		t,
		S.curlAt,
		9 * tick / 0.29,
		0.5 * tick / 0.29,
		NOSE_CURL_GAIN,
		NOSE_CURL_MOST
	)
end

return Mammoth
