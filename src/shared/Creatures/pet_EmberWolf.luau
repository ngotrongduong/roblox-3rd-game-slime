-- The Ember Wolf of the Volcano (art/models/ready/pet_EmberWolf.glb, 27 bones, a skeleton written here: a
-- charcoal wolf under a mane of flames that is the top 40% of it, short legs with flame tufts, and ONE flame
-- tail that leaves the rump to its left and curls up). Its joint map, and the MOTION OF THE ARCTIC FOX
-- (pet_ArcticFox.luau: the same names and tree, its gait, its legs, its head, its tail of springs), changed
-- only where this body is another: one tail and not three, a neck stiffer than the fox's (the mane is welded
-- across it), a right shoulder that goes 20 degrees forward only, and its own stride (it stands with its right
-- legs ahead: every leg has its own rest numbers). docs/motion/pet_EmberWolf.md says where and why ("For the
-- motion" is the frozen geometry and the bend table). Look at art/models/rigs/pet_EmberWolf_left.png beside
-- this file. Space: +x its right, +y up, it looks along -z.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2 -- one whole stride in radians

local Wolf = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Wolf.map = {
	count = 27, -- the frozen ready skeleton; every joint is named below
	tree = 1343955143, -- the print of that skeleton's tree (names and parents)
	-- Root is the handle on the pelvis: it drives nothing and everything hangs on it. Body_01 is the PELVIS
	-- (the hind legs and the tail hang on it), Body_02 the CHEST, which turns at the loin (the forelegs and
	-- the neck hang on it)
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- inside the mane: the foot of the neck and its middle; then the base of the skull (skull, muzzle, ears
	-- and face are one rigid lump on it; the mane behind it is the neck's and the chest's)
	neck = { "Neck_01", "Neck_02" },
	head = { "Head" },
	-- the one flame tail: its root on the rump, back and left (02), out to the left (03), up (04, 05)
	tail = { "Tail_01", "Tail_02", "Tail_03", "Tail_04", "Tail_05" },
	legs = {
		-- foreleg, from the body down: the SHOULDER (inside the chest: it aims the leg), the ELBOW (it folds the
		-- forearm back), the WRIST (at the flame tuft: it folds the pastern forward), the TOES (the paw follows
		-- it). The last joint is 10% of the rig's height over the ground (0.067 of 0.657, the tail's tip joint,
		-- which is higher than the Head's 0.603): under the kit's 12%, so all four are `legs`
		LF = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" },
		RF = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" },
		-- hind leg: the HIP, the STIFLE (the knee, its knob forward), the HOCK (it points back), the PAW
		LH = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" },
		RH = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" },
	},
	-- (no `pairs`: it stands in a stride, the right legs ahead of the left, and the tail is on one side:
	-- nothing is the mirror of its twin)
}

-- The rig's height in the units of the file: its highest joint, the tail's tip joint (`Tail_05`).
local RIG = 0.657

-- HOW IT STROLLS in its plot: the Arctic Fox's light walk (Froude 0.06, rests of 3 to 10 seconds, 0.9 of the
-- plot). Its leg: the four top joints are 0.337 up on average (0.337, 0.346, 0.337, 0.328).
Wolf.stroll = { froude = 0.06, leg = 0.337 / RIG, rest = { 3, 10 }, radius = 0.9 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward. `tip` and
-- `centre` are shares of the RIG's height.) The Arctic Fox's two legs, number for number but for those
-- marked; each leg has its own `below`, `ahead` and `centre`, read from the skeleton.
local function fore(id, name, chain, below, ahead, centre, lift)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4, -- the PAW is held against the ground; elbow and wrist above it fold (the Fox's)
		front = 0.5, -- half the stance reaches forward, half pushes back
		-- (the planted point: the ground under the toes' tip, ahead of the paw's joint at its heel)
		tip = { below = below, ahead = ahead },
		centre = centre,
		-- in the air elbow (back) and wrist (forward) fold together; on the ground only the wrist gives (the
		-- Fox's: a straight column that folds its elbow under load stands on a bent elbow)
		fold = { swing = { 0, -1.0, 0.85, 0 }, stance = { 0, 0, 1.0, 0 } },
		sink = 0, -- the paw is one lump: no pastern under the held joint
		open = 0, -- shoulder, elbow and wrist stand over each other: opening the fold makes the leg shorter
		ease = true, -- a leg that stands at its full length: its fold is eased in and out of a swing
		lift = lift, -- shares of the leg, each foreleg its own (below)
		liftSkew = 0.84, -- the paw is highest at 0.45 of its swing (the Fox's, for the eased fold)
		-- the paw (phase, radians against the ground; the Fox's curve): flat through 0.55 of the stance, its
		-- heel 0.1 up at 0.8 and 0.25 as it leaves; carried nearly level, its toes a little up as it reaches
		pitch = {
			stance = { 0, 0, 0.55, 0, 0.8, -0.1, 1, -0.25 },
			swing = { 0, -0.25, 0.45, -0.2, 0.85, 0.1, 1, 0 },
		},
	}
end

local function hind(id, name, chain, below, ahead, centre, open, heel)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4, -- the paw is held against the ground; stifle and hock above it fold
		front = 0.5, -- half the stance reaches forward, half pushes back
		tip = { below = below, ahead = ahead },
		centre = centre,
		-- stifle (back) and hock (forward) fold and open together, on the ground as in the air (the Fox's)
		fold = { swing = { 0, -1.0, 0.95 }, stance = { 0, -1.0, 0.95 } },
		sink = 0, -- the paw is one lump: no pastern to give
		open = open, -- radians the stifle may open to reach, each hind leg its own (below)
		lift = { walk = 0.07, trot = 0.095 }, -- shares of the leg (the Fox's)
		-- the paw, a short flat lump (the Fox's curve): flat to 0.35 of the stance, its heel rising `heel`
		-- radians to the end (the Fox's 0.3; each hind leg its own, below); carried nearly level in the air
		-- (0.2 down at 0.35), its toes 0.12 up at 0.8 as it reaches, flat to land
		pitch = { stance = { 0, 0, 0.35, 0, 1, -heel }, swing = { 0, -heel, 0.35, -0.2, 0.8, 0.12, 1, 0 } },
	}
end

Wolf.legs = {
	-- (the left forepaw's joint is 0.067 over the ground, its toes' tip 0.085 ahead of the joint (the recipe's
	-- bone end); it stands 0.015 ahead of its shoulder and steps 0.042 behind where it stands: the middle of
	-- its stance is 0.027 behind the shoulder, near the Fox's 0.037; at 0.03 its shoulder swung back only 18
	-- degrees in a trot. Its lift is a little over the Fox's 0.055 / 0.06 and the right one's far under: see
	-- the right one.)
	-- (THE RIGHT FOREPAW: its joint 0.062 up, its toes 0.072 ahead; it was modelled 0.07 AHEAD of its
	-- shoulder, a leg 3% longer than its shoulder is high, which must fold to pass under it. It steps 0.06
	-- behind where it stands: it lands where it was modelled (a leg never lands longer than it was given),
	-- and its shoulder goes 33 back and 15 forward of the modelled pose. At 0.05 with a shoulder held to the
	-- table's 20 back the paw slid 29% of a stride; at 0.068 and more it never came back to the modelled
	-- length and its wrist stood bent for ever. It folds for its length already, so it is asked to lift
	-- 0.025 / 0.03 of the leg only: at the Fox's 0.055 it lifted half as high again as the left one and its
	-- shoulder swung 8 degrees further.)
	fore(
		"LF",
		"front left leg",
		Wolf.map.legs.LF,
		0.067 / RIG,
		0.085 / RIG,
		0.042 / RIG,
		{ walk = 0.065, trot = 0.07 }
	),
	fore(
		"RF",
		"front right leg",
		Wolf.map.legs.RF,
		0.062 / RIG,
		0.072 / RIG,
		0.06 / RIG,
		{ walk = 0.025, trot = 0.03 }
	),
	-- (THE LEFT HIND PAW: its joint 0.066 up; the paw is turned out and back, so its planted point is under
	-- its joint (0.01 ahead). It was modelled STRETCHED, 0.088 behind its hip, and steps 0.06 ahead of where
	-- it stands (at 0.04 it was out of reach by 2.5% of the leg at the end of every stance, at 0.055 by 1.1%;
	-- at 0.065 its hip went 37 forward of its 40). Its stifle stands bent 62 degrees and may open 0.45 rad of
	-- them. Its heel rises 0.2 rad only: a paw whose planted point is under its joint gains no reach by
	-- rolling up, and the paw's joint is turned 18 to 31 degrees through the whole stance as it is.)
	hind("LH", "hind left leg", Wolf.map.legs.LH, 0.066 / RIG, 0.01 / RIG, -0.06 / RIG, 0.45, 0.2),
	-- (the right hind paw: 0.067 up, its toes 0.03 ahead, 0.085 behind its hip; it steps 0.04 ahead of where
	-- it stands, the Fox's stretched leg's number; the Fox's 0.3 of opening and of heel)
	hind("RH", "hind right leg", Wolf.map.legs.RH, 0.067 / RIG, 0.03 / RIG, -0.04 / RIG, 0.3, 0.3),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH): the Arctic Fox's, every number -------------------
local DESIGN = {
	-- (the kit steps a walker in a slow pivot by itself: these are not lowered for it)
	start = 0.004, -- the Froude number at which it starts to step
	stop = 0.0015, -- ... and stops: lower, so that it does not chatter
	-- a walk in lateral sequence: left hind, left fore, right hind, right fore
	walk = {
		offsets = { 0.22, 0.72, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 }, -- two or three paws down
		stride = { 3.3, 0.5 }, -- stride = 3.3 x leg x sqrt(Froude)
	},
	-- a trot, its travelling gait: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.4, slope = 0.05, ref = 1, least = 0.34, most = 0.46 }, -- a flight between the pairs
		stride = { 2.3, 0.3 }, -- stride = 2.3 x leg x Froude^0.3
		sweep = 0.42, -- the most a paw travels on the ground in a trot's stance, in leg lengths
		from = 0.32, -- the Froude number at which it changes up
		back = 0.22, -- ... and down again
		shift = 0.35, -- seconds the change of footfalls takes
	},
	sweep = 0.48, -- the most a paw travels on the ground in a walk's stance, in leg lengths
	finish = 0.25, -- the clock's pace at which a step is finished when it stops
	settle = { far = 0.14, time = 1.5, least = 2, mean = 5, most = 14 }, -- a paw left far from home steps back
	comfy = 0.9997, -- (the kit has no default) straight forelegs: it stands exactly as it was modelled
	letGo = 0.6, -- the body rises from a paw that left over the first 60% of its swing
	comeDown = 0.4, -- ... and comes down for its landing from 40% of it on
}

-- THE BODY, THE HEAD, THE TAIL (the Arctic Fox's numbers, but for those marked) ------------------------------
local WALK_BOB = 0.016 -- shares of its leg an end sinks at each paw's landing, walking
local TROT_BOB = 0.035 -- ... and over the middle of each stance, trotting
local HIP_DROP = 0.06 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02 -- ... and the chest for a foreleg
local HIP_YAW = 0.05 -- radians the pelvis turns to bring a hind leg forward, once a stride
local CHEST_YAW = 0.025 -- ... and the chest for a foreleg
-- (radians, about its shoulders: barely there. Under the Fox's 0.0015: at 0.0015 a leg joint of this body
-- turned 1.04 degrees with a breath; the mane is what shows it)
local BREATH = 0.001
-- (NOT the Fox's 0.6 of yaw in 0.36 seconds: the mane is welded across the neck and each of its joints is
-- clean to 30 degrees only. A wolf's look is slow and short: 0.42 rad is 24 degrees, with the lead into a turn
-- below 35.5 over the three joints, 12 a joint, which was looked at as 3 x 13 with the head cocked and
-- raised (art/models/poses/pet_EmberWolf_pose_motion.png) and is good; it takes 0.7 seconds)
local LOOK = { yaw = 0.42, up = 0.12, down = 0.12, turn = 0.7, least = 2, mean = 14, aside = 3, most = 40, home = 0.9 }
local ASIDE = { 1.4, 2.6, 7 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.2, 0.4 -- radians it cocks its head as it looks (11.5 degrees of the 20), how often
-- (every turn is shared in thirds over the three joints, as the Fox's)
local NECK_SHARE = { 1 / 3, 1 / 3 }
local HEAD_SHARE = { 1 / 3 }
local TURN_LEAD = 0.2 -- radians its head goes into a turn before the body, at most (the Fox's 0.3: a stiff neck)
-- (under the Fox's 0.1: a flame curled to one side, which must never swing its root to the left thigh)
local TAIL_SWING = 0.06 -- radians its root swings the tail to a side, once a stride
local TAIL_RATE = 3.4 -- how quickly a bone of the tail follows the one before (in units of sqrt(G / leg))
local TAIL_DAMP = 0.5 -- under 1: it swings past a little and goes on after the wolf has stopped
-- (the brief of stage A: 0.1 rad a joint at most. 5.7 degrees a joint, 29 over the five: under the 50 of the
-- table; five times 8 either way was looked at on the same sheet and is good)
local TAIL_MOST = 0.1
local SWISH = 0.14 -- radians its root swings the tail in one swish, standing (the Fox's 0.24: see TAIL_SWING)

-- SKIN-SAFE CURVES, NOT CLAMPS (the Fox's): the last tenth of each permitted bend eases towards the limit of
-- the bend table and never reaches it. Each leg its own row (LF, RF, LH, RH), top joint first.
local BENDS = {
	{ { -40, 40 }, { -60, 60 }, { -60, 60 }, { -60, 60 } }, -- LF: from 40 the arm passes into the chest
	-- RF: 20 FORWARD (the arm passes into the chest). BACK 40, NOT the table's 20: a walking step turns a
	-- shoulder through 44 to 48 degrees, so no walk fits in 40; the scan the table was written from is
	-- clean to 60 that way and first passes into the chest at -40, as the left one. Reported to stage A.
	{ { -40, 20 }, { -60, 60 }, { -60, 60 }, { -60, 60 } },
	{ { -30, 40 }, { -60, 60 }, { -60, 60 }, { -60, 45 } }, -- LH: a hip 30 back (the tail's root), 40 forward
	{ { -30, 40 }, { -60, 60 }, { -60, 60 }, { -60, 45 } }, -- RH
}
-- Roll (the lean of a leg's top joint to reach a paw that is not under it; + swings a LEFT leg inward): a
-- shoulder 10 inward and 20 outward, a hip 10 both ways (the Fox's; the table gives 30 and 20).
local FORE_ROLL = { 10, 20 } -- inward, outward
local HIND_ROLL = { 10, 10 }
local function bend(value, low, high)
	local most = math.rad(if value < 0 then -low else high)
	return Kit.bound(value, 0.9 * most, most) -- the last 10% is the eased approach, with no corner
end
local function safeLeg(pose, leg, bounds, roll)
	for j, i in leg.b do
		pose.rx[i] = bend(pose.rx[i], bounds[j][1], bounds[j][2])
	end
	local top, foot = leg.b[1], leg.b[leg.ankle]
	local low, high = if leg.side < 0 then -roll[2] else -roll[1], if leg.side < 0 then roll[1] else roll[2]
	pose.rz[top] = bend(pose.rz[top], low, high)
	pose.rz[foot] = -pose.rz[top] -- the paw stays level across its width under that softened lean
end

function Wolf.new(rig, info)
	local seed = info.seed or 0 -- its own clock; 0 when nobody gives one
	local legs = {}
	for k, spec in Wolf.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local tail = Kit.chain(rig, "the tail")
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0, -- it starts in the stand it was modelled in
		root = rig.root,
		pelvis = Kit.bone(rig, "Body_01"),
		chest = Kit.bone(rig, "Body_02"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = tail,
		follow = Kit.springRow(#tail),
		-- (which paw it sets off with from a stand: a hind one, the left or the right by its own seed)
		lead = Kit.lead(seed),
		-- the means of each pair's top joints: where the body rides
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 }, -- the spring of the lead into a turn, at rest
		tilt = 0, -- no cock until the first look aside
		tiltFrom = 0,
		tiltTo = 0,
		tiltAt = -100, -- long ago: no look has begun
		swishAt = -100, -- long ago: no swish is under way
		swishSide = 1, -- drawn again at the first swish
		swishNext = 5 + 20 * Kit.roll(dice), -- the first swish after 5 to 25 seconds
	}
end

function Wolf.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	local stoodUp = W.fresh or input.jump or dt <= 0 or dt > 0.4 -- (as the kit: after a long frame it stands anew)
	Kit.gait(W, dt, input)
	if stoodUp then
		Kit.leadFeet(W, S.lead, input.yaw)
	end
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it. The rump drops on the side whose hind leg is in the air
	-- and turns to bring it forward; the chest does the same, less, for a foreleg. The chest hangs ON the
	-- pelvis, so it is given its own turn less the pelvis's.
	local g = Kit.smooth(W.g)
	local front = -Kit.both(Kit.girdle(W, 1, 2), Kit.ride(W, g, legs[1].phi, WALK_BOB, TROT_BOB, 0))
	local back = -Kit.both(Kit.girdle(W, 3, 4), Kit.ride(W, g, legs[3].phi, WALK_BOB, TROT_BOB, 0))
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (one breath in ten of its units of time, begun by its seed; it breathes about its SHOULDERS)
	local breath = BREATH * sin(t * TAU * 0.1 / tick + S.seed * TAU) * (1 - amount)
	-- (the paws leave the ground from 10 degrees of the trunk's pitch: eased towards 12)
	local lean = Kit.bound(pitch + breath, math.rad(10), math.rad(12))
	pose.bob, pose.ox, pose.oz = bob - breath * (S.zRoot - S.zFront), 0, 0
	rx[S.root] = lean
	local hipYaw = -HIP_YAW * amount * cos(TAU * legs[3].phi)
	local chestYaw = -CHEST_YAW * amount * cos(TAU * legs[1].phi)
	local hipDrop = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local chestDrop = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	rz[S.pelvis], ry[S.pelvis] = hipDrop, hipYaw
	rz[S.chest], ry[S.chest] = chestDrop - hipDrop, chestYaw - hipYaw
	Kit.solve(W, pose)
	for k, leg in legs do
		safeLeg(pose, leg, BENDS[k], if k <= 2 then FORE_ROLL else HIND_ROLL) -- the first pair is the forelegs
	end

	-- THE HEAD: the steadiest part. The neck undoes ALL the trunk does (its lean, the chest's turn and roll),
	-- a third at each joint, so the head stands still over a body that walks; standing, it is still and now
	-- and then looks somewhere, slowly and not far.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	Kit.spread(pose, neck, NECK_SHARE, -lean, -chestYaw, -chestDrop)
	Kit.spread(pose, head, HEAD_SHARE, -lean, -chestYaw, -chestDrop)
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	Kit.asideHold(gaze, t, S.dice, LOOK.turn, ASIDE)
	-- (into a turn the head goes first: 0.3 seconds of the turn ahead, on a spring of rate 5 at a unit of time
	-- of 0.29, without overshoot: the Fox's)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -TURN_LEAD, TURN_LEAD) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)
	-- (now and then, as it looks at something, it cocks its head, and holds that as long as the look)
	local cock = Kit.cock(S, t, W.moving, LOOK.turn, TILT, TILT_CHANCE)
	Kit.spread(pose, neck, NECK_SHARE, 0, 0, cock)
	Kit.spread(pose, head, HEAD_SHARE, 0, 0, cock)

	-- THE TAIL (the Fox's middle brush, alone): its root swings it from side to side once a stride; every bone
	-- after it follows the one before on a spring, a little later and a little further, and goes on after the
	-- wolf has stopped; in a turn it stays behind. Nothing ever pitches it: the flame stays curled up.
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 8, 20, 50) -- seconds between two swishes: at least, mean, at most
	end
	-- (half the swing at a trot, a tenth of a stride after the pelvis; a swish lasts five of its units of time)
	local lead = hipYaw
		+ TAIL_SWING * amount * (1 - 0.5 * W.g) * sin(TAU * (W.phase - 0.1))
		+ SWISH * S.swishSide * Kit.pulse(t, S.swishAt, 5 * tick)
	Kit.chainFollow(
		pose,
		S.tail,
		S.follow,
		lead,
		hipYaw,
		TAIL_RATE / tick,
		TAIL_DAMP,
		TAIL_MOST,
		W.w * math.min(dt, 0.1), -- (a frame counts as a tenth of a second at most for what a turn leaves behind)
		dt,
		input.jump
	)
end

return Wolf
