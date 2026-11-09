-- The Rock Tortoise of the Volcano (art/models/ready/pet_RockTortoise.glb, 17 bones built in stage A: ONE bone,
-- the Root, for the whole shell, chest and belly; a neck of one joint and the head; four short column legs of
-- three joints; a stub of a tail of two). Its joint map, and the MOTION OF THE LIZARD (pet_Lizard.luau: four
-- legs, a walk in lateral sequence, the legs spread a little) on it, slowed and made heavy as the Mammoth
-- (pet_Mammoth.luau), changed only where this body is another: docs/motion/pet_RockTortoise.md says where.
-- Look at art/models/rigs/pet_RockTortoise_left.png and _top.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Tortoise = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Tortoise.map = {
	count = 17,
	tree = 498582923, -- (the print of the ready skeleton's tree)
	-- Root IS the trunk: the shell, its rim and spikes, the chest and the belly are rigid on it, and every other
	-- chain hangs on it. There is no Body bone: what would turn a pelvis or a chest turns the whole animal
	root = "Root",
	spine = { "Root" },
	-- next to no neck: one joint at the shell's front opening, then the skull (horn and eyes are its skin)
	neck = { "Neck_01" },
	head = { "Head" },
	-- a stub: its root and its middle
	tail = { "Tail_01", "Tail_02" },
	-- THE LEGS are mapped as `limbs` of the role "leg" (the Bloom Sprite's way), not as `legs`: the kit refuses
	-- a leg of the map whose last joint lies higher than 12% of the HIGHEST JOINT over the ground, and here the
	-- highest joint is the Head at half the animal's height (the shell above it has no bone), so that ankles
	-- 8 to 10% of the animal's height up count as 17 to 20%. They are walked as legs all the same (`Kit.leg`)
	limbs = {
		-- a column of stone: the SHOULDER (where it leaves the shell), the ELBOW (the gold band), the WRIST (the
		-- heel of the foot: its bone carries the whole foot and its three claws)
		LF = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03" } },
		RF = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03" } },
		-- the HIP, the KNEE (the gold band), the ANKLE (the whole foot, its claws point back)
		LH = { role = "leg", bones = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03" } },
		RH = { role = "leg", bones = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03" } },
	},
	-- NO pairs: the two sides are not alike (the right foreleg is a quarter longer than the left and its foot
	-- stands 0.118 of the file's units further forward): every joint was measured on its own limb
	pairs = {},
	-- nothing is rigid by a bone of its own: the shell is the Root's skin
	rigid = {},
}

-- HOW IT STROLLS in its plot: slower still than the Mammoth (a Froude number of 0.012 against 0.03 and the
-- Lizard's 0.06: its step is so short, below, that anything faster is a patter of the feet), and it stands a good
-- while between two strolls (the Mammoth's rests). `leg`: its leg, hip to ground, as a share of the rig's height
-- (the highest joint, the Head, half way up the animal): 0.2 of 0.374 file units.
Tortoise.stroll = { froude = 0.012, leg = 0.53, rest = { 6, 16 }, radius = 1.5 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- File units of the ready model, from "For the motion" of the write-up; the kit takes shares of the rig's
-- height, its highest joint: the Head, 0.374.
local H = 0.374
-- (the ball of a fore foot lies this far ahead of the wrist, half way to the claws: the planted point)
local BALL = 0.03

-- (`wrist`: how high the joint of the foot is over the ground; `ahead`: how far ahead of it the planted point
-- is; `centre`: how far behind where it stands the middle of its stance is, a share of the rig's height;
-- `open`: radians its middle joint may open past its rest; `lift`: how high the foot swings, a share of the leg.)
local function leg(id, name, chain, wrist, ahead, centre, open, lift)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (three joints: the foot is ONE bone, the Lizard's hind leg)
		ankle = 3,
		front = 0.5,
		tip = { below = wrist / H, ahead = ahead / H },
		centre = centre,
		-- (one joint folds this leg, the elbow or the knee at the gold band: it folds the lower leg forward, the
		-- Lizard's hock. + tips a joint's lower end forward)
		fold = { swing = { 0, 1.0 }, stance = { 0, 1.0 } },
		sink = 0, -- (a foot of stone does not give under the load)
		-- (the right foreleg's three joints lie on one line: the fold of a leg that stands straight is eased in
		-- and out over the ends of its swing, the Camel's and the Mammoth's. The other three stand bent)
		ease = open == 0,
		open = open,
		-- (in its run a foot swings a seventh higher, the Lizard's share)
		lift = { walk = lift, trot = lift * 1.15 },
		-- the foot: FLAT, on the ground and in the air. It is a stump with claws: any tip of it puts the claws or
		-- the heel under the ground (the fault stage A named), so the ankle undoes all the leg above it does
		pitch = { stance = { 0, 0, 1, 0 }, swing = { 0, 0, 0.4, -0.06, 0.85, 0.02, 1, 0 } },
	}
end

-- Wrist heights 0.076, 0.075, 0.063, 0.064. A fore foot's claws point forward: its planted point is the ball;
-- a hind foot's point back: it is planted under its ankle.
-- THESE LEGS ARE COLUMNS, hip to ankle 0.13 to 0.17 of the file's units: a column that must get 3% shorter
-- folds 28 degrees, and one that must get longer cannot. So each leg steps where it never has to be longer
-- than it stands, and the body keeps its height (no crouch, no bob to speak of):
-- LF stands all but under its shoulder (its wrist 0.012 ahead): its stance is centred under the shoulder
--    (0.012 / 0.374), and its elbow, which stands bent 19 degrees, OPENS 0.3 rad for the two ends of it.
-- RF is another leg: it stands STRAIGHT and leans 31 degrees forward and as far out (its wrist 0.080 ahead of
--    the shoulder). It cannot reach a hair further forward, so its stance ends just short of where it stands
--    (centre 0.07: 0.026 back, a little over half the step), and coming back under the shoulder it is up to
--    10% too long: its upper arm turns back 50 degrees and its elbow folds 55 to 60, every stance. Folding the
--    other way (the elbow forward) was tried, to keep the shoulder under 35 degrees: the forearm then leant 35
--    to 45 degrees back over the foot, and the skin of the foot, which is half the forearm's, put its claws 3
--    to 3.6% of the height under the ground. Its foot is lifted least (0.03): from that fold a higher swing
--    asks more of the elbow than the 60 it takes.
-- LH, RH stand with their feet 0.029 and 0.039 behind their hips, near the end of their reach: their stance
--    lies forward of where they stand, its middle 0.012 and 0.010 AHEAD of the hip (-0.041 and -0.049 / 0.374),
--    so that the foot that waits while the others set off has 0.02 to spare behind it; their knees (bent 15 and
--    32 degrees as they stand) may open for the rest.
-- Lifts: half the Lizard's 0.14 to 0.17 (a heavy tread, and a column folds far to rise a little).
Tortoise.legs = {
	leg("LF", "front left leg", Tortoise.map.limbs.LF.bones, 0.076, BALL, 0.032, 0.3, 0.08),
	leg("RF", "front right leg", Tortoise.map.limbs.RF.bones, 0.075, BALL, 0.07, 0, 0.03),
	leg("LH", "hind left leg", Tortoise.map.limbs.LH.bones, 0.063, 0, -0.11, 0.25, 0.07),
	leg("RH", "hind right leg", Tortoise.map.limbs.RH.bones, 0.064, 0, -0.13, 0.5, 0.07),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH) ---------------------------------------------------
local DESIGN = {
	-- (a tenth of the Froude number of its stroll, as the Lizard's are of its own: with the Camel's 0.004 it had
	-- crept 0.4 s on four standing feet before it stepped, its hind legs, which stand near the end of their
	-- reach, pulled the rump down 1.6% of the height. Not lowered for the slow pivot: the kit steps that itself)
	start = 0.0012,
	stop = 0.0005,
	-- the Lizard's walk in lateral sequence: left hind, left fore, right hind, right fore
	walk = {
		offsets = { 0.22, 0.72, 0, 0.5 },
		-- (the Mammoth's long contact: a foot is down two thirds of the stride)
		duty = { at = 0.66, slope = 0.03, ref = 0.35, least = 0.6, most = 0.68 },
		-- (the Lizard's law, stride = 3.3 x leg x sqrt(Froude): 0.36 of a leg at its stroll, of which `sweep`
		-- below lets it take 0.32)
		stride = { 3.3, 0.5 },
	},
	-- ITS RUN: the Lizard's trot of diagonal pairs that land together, but with a foot down more than half the
	-- stride (the Mammoth's fast walk): a tortoise of stone never leaves the ground
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.56, slope = 0.04, ref = 0.3, least = 0.53, most = 0.6 },
		stride = { 2.3, 0.3 },
		-- (the step of its walk, no longer: with a fifth more its legs were out of reach by 1% of the leg and
		-- a foot went 1.2% of the height under the ground. It runs by stepping quicker)
		sweep = 0.22,
		-- (the Mammoth's: its walk has reached its longest step long before)
		from = 0.15,
		back = 0.1,
		shift = 0.8,
	},
	-- (a foot travels 0.22 of the leg on the ground, 0.044 of the file's units: under half the Lizard's 0.5. The
	-- kit's leg is hip to ground, 0.2, but what swings is hip to ANKLE, 0.13: that is 20 degrees of the hip, the
	-- 20 to 25 stage A looked at, and the most the right foreleg's elbow can fold away (above))
	sweep = 0.22,
	finish = 0.25,
	-- (the Mammoth's: it shifts a foot seldom and slowly)
	settle = { far = 0.14, time = 2, least = 3, mean = 8, most = 18 },
	-- (a column: it stands exactly as long as it was modelled, no fold is asked of it standing)
	comfy = 1,
	letGo = 0.55,
	comeDown = 0.45,
	-- (the Lizard's: a walk that has begun with no foot in the air steps that foot in the next frame. Here the
	-- hind feet wait at the very end of their reach: without it the rump sank 1.6% of the height setting off)
	firstStep = 0.75,
}

-- THE BODY, THE HEAD, THE TAIL: the Lizard's, less of everything -------------------------------------------
-- (a crouch of 2% of the leg was tried, to keep the knees from snapping straight: it folded them 45 to 55
-- degrees in the middle of every stance and pressed the right foreleg past its 60)
local CROUCH = 0 -- shares of its leg the body rides lower when it walks than when it stands (the Lizard's)
local WALK_BOB = 0.008 -- shares of its leg the body sinks at each foot's landing, walking (half the Lizard's)
local TROT_BOB = 0.02 -- ... and over the middle of each stance in its run
local ROCK = 0.02 -- radians the whole animal rolls to the side whose legs are in the air (the Mammoth's sway)
-- (NO breath: the Lizard's 0.0012 rad of pitch about the middle of the trunk lifted these hips a hair, and
-- column legs answer a hair with degrees: a leg was moving 22% of the time it stood. A shell of stone is still)
local HEAD_KEEP = 0.15 -- the share of the trunk's pitch the head keeps
-- (still for long; now and then one SLOW look aside, held, and back: 29 degrees, of which the neck does 12
-- and the head 17, of the 40 and 45 their skin takes)
local LOOK = { yaw = 0.5, up = 0.1, down = 0.1, turn = 0.7, least = 3, mean = 16, aside = 4, most = 45, home = 0.9 }
local ASIDE = { 2, 4, 9 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.12, 0.4 -- radians it cocks its head as it looks at something, and how often it does
local NECK_SHARE = { 0.4 } -- of a look: the one joint of the neck does two fifths ...
local HEAD_SHARE = { 0.6 } -- ... and the head the rest
local TAIL_SWING = 0.09 -- radians its root swings the stub to a side, once a stride
local TAIL_RATE = 3.4 -- how quickly a bone of the tail follows the one before (in units of sqrt(G / leg))
local TAIL_DAMP = 0.5
local TAIL_MOST = 0.26 -- radians a bone of it turns by itself at most (15 degrees: what stage A looked at)
local SWISH = 0.2 -- radians its root swings the tail in one swish, standing

-- Skin-safe curves, not clamps (the Mammoth's): unchanged to nine tenths of the bend the skin takes cleanly
-- (the bend table of the write-up: the joints below the top one 60; a foot passes into the belly at a roll
-- of 40), then eased towards it. Steady strides lie under the knees, but for the right elbow's last degrees.
local LOWER_PITCH, TOP_ROLL = math.rad(60), math.rad(30)
-- (the top joints: the left shoulder 35; the RIGHT shoulder the table's whole 60, for it goes back 50 degrees
-- with its elbow folded, see the legs above; the hips 40, the least of the table's four numbers for them)
local TOP_PITCH = { LF = math.rad(35), RF = math.rad(60), LH = math.rad(40), RH = math.rad(40) }
-- How far under its top joint the ankle of a leg hangs, seen from the side, its top joint turned `a` and its
-- middle joint `b` (the kit's leg has the two pieces as `sy`, `sz`; + tips a lower end forward, to -z).
local function hang(one, a, b)
	b += a
	return one.sy[1] * cos(a) - one.sz[1] * sin(a) + one.sy[2] * cos(b) - one.sz[2] * sin(b)
end
-- A LACK OF THE KIT, kept here: a leg whose fold a curve has eased is LONGER than the kit asked, and its foot
-- would go that much under the ground (the fault stage A named; the right foreleg, its shoulder at 60 degrees
-- as it left a slow turn for a run, put its foot 1.2% of the height under). So the top joint turns the leg
-- until its ankle hangs as high as it was asked to (the foot is then a hair off its place along the ground: a
-- slide of a hair, not a sink), and the foot's own joint gives back all that the two above it were changed
-- by: it stays level.
local function safeLeg(pose, one)
	local top, mid, foot = one.b[1], one.b[2], one.b[3]
	local a, b = pose.rx[top], pose.rx[mid]
	local fold = Kit.bound(b, 0.9 * LOWER_PITCH, LOWER_PITCH)
	local want = hang(one, a, b)
	-- (the turn of one joint, near `from`, at which the ankle hangs as asked: Newton's steps on a smooth curve,
	-- three are exact to a thousandth of a degree; never further than 0.3 rad from where it began)
	local function settle(from, height)
		local x = from
		for _ = 1, 3 do
			local slope = (height(x + 1e-4) - height(x - 1e-4)) / 2e-4
			if math.abs(slope) < 1e-6 then
				break
			end
			x = Kit.clamp(x + (want - height(x)) / slope, from - 0.3, from + 0.3)
		end
		return x
	end
	local aim = a
	if fold ~= b then
		aim = settle(a, function(x)
			return hang(one, x, fold)
		end)
	end
	local most = TOP_PITCH[one.id]
	local held = Kit.bound(aim, 0.9 * most, most)
	if held ~= aim then
		-- (and where the top joint is what was eased, the fold makes it up, as far as it may)
		fold = Kit.bound(
			settle(fold, function(x)
				return hang(one, held, x)
			end),
			0.9 * LOWER_PITCH,
			LOWER_PITCH
		)
	end
	aim = held
	pose.rx[top], pose.rx[mid] = aim, fold
	pose.rx[foot] = Kit.bound(pose.rx[foot] + (a - aim) + (b - fold), 0.9 * LOWER_PITCH, LOWER_PITCH)
	pose.rz[top] = Kit.bound(pose.rz[top], 0.9 * TOP_ROLL, TOP_ROLL)
	pose.rz[foot] = -pose.rz[top] -- the foot stays level across its width under that lean
end

-- The bigger of two, without a corner where one takes over from the other.
local function both(a, b)
	local a2, b2 = a * a, b * b
	return math.sqrt(math.sqrt(a2 * a2 + b2 * b2))
end

function Tortoise.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Tortoise.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local tail = Kit.chain(rig, "the tail")
	local follow = {}
	for k = 1, #tail do
		follow[k] = { x = 0, v = 0 }
	end
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		root = rig.root,
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = tail,
		follow = follow,
		-- (which foot it sets off with from a square stand: a hind one, the left or the right by its own seed)
		lead = if seed % 1 < 0.5 then { 2, 1, 4, 3 } else { 1, 2, 3, 4 },
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		tilt = 0,
		tiltFrom = 0,
		tiltTo = 0,
		tiltAt = -100,
		swishAt = -100,
		swishSide = 1,
		swishNext = 5 + 20 * Kit.roll(dice),
	}
end

function Tortoise.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	local stoodUp = W.fresh or input.jump or dt <= 0 or dt > 0.4
	Kit.gait(W, dt, input)
	if stoodUp then
		-- (it has just been stood on its four feet, each exactly on its place: as it sets off every one of them
		-- is as far behind as every other, and which the kit lifts first would hang on the last bit of a sum.
		-- So each stands a hair behind its place, a hind foot furthest: that one leads. The Lizard's)
		local sy, cy = sin(input.yaw), cos(input.yaw)
		for k, one in legs do
			local back = S.lead[k] * 1e-5 * W.h
			one.wx += back * sy
			one.wz += back * cy
		end
	end
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: ONE rigid piece. Each end rides on the legs under it; the whole animal rocks a little, as one
	-- piece, to the side whose legs are in the air (the Lizard dropped its rump and its chest apart and turned
	-- them to bring a leg forward: there is no joint here to do that with).
	local g = Kit.smooth(W.g)
	local function ride(phi)
		local walk = WALK_BOB * (0.5 + 0.5 * cos(2 * TAU * phi))
		local trot = TROT_BOB * (0.5 + 0.5 * cos(2 * TAU * (phi - 0.5 * W.duty)))
		return amount * W.h * (CROUCH + walk + (trot - walk) * g)
	end
	local front = -both(Kit.girdle(W, 1, 2), ride(legs[1].phi))
	local back = -both(Kit.girdle(W, 3, 4), ride(legs[3].phi))
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (the first step of a walk and a sprint see-saw it most: eased towards 5 degrees, a curve with no corner,
	-- the Mammoth's; the steady see-saw of its walk is half a degree)
	local eased = Kit.bound(pitch, math.rad(3), math.rad(5))
	bob, pitch = bob + (eased - pitch) * (S.zFront - S.zRoot), eased
	local rock = ROCK * 0.5 * (Kit.lifted(legs[1]) + Kit.lifted(legs[3]) - Kit.lifted(legs[2]) - Kit.lifted(legs[4]))
	pose.bob, pose.ox, pose.oz = bob, 0, 0
	rx[S.root], ry[S.root], rz[S.root] = pitch, 0, rock
	Kit.solve(W, pose)
	for _, one in legs do
		safeLeg(pose, one)
	end

	-- THE HEAD: the steadiest part. It cancels what the trunk does and looks where it goes; standing, it is
	-- still and now and then looks somewhere, slowly.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	rx[neck[1]] = -(1 - HEAD_KEEP) * pitch
	rz[neck[1]] = -(1 - HEAD_KEEP) * rock
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	if gaze.t0 == t and (gaze.y1 ~= 0 or gaze.p1 ~= 0) then
		-- (a look aside has just begun. The kit would hold it for a good part of the long hold before it:
		-- it is held a few seconds, whatever came before)
		gaze.next = t + LOOK.turn + Kit.wait(S.dice, ASIDE[1], ASIDE[2], ASIDE[3])
	end
	-- (into a turn the head goes first: a little, 14 degrees at most, on a slow spring)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.2 * W.w, -0.25, 0.25) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)
	-- (now and then, as it looks at something, it cocks its head, and holds that as long as the look)
	if gaze.t0 ~= S.tiltAt then
		S.tiltAt, S.tiltFrom = gaze.t0, S.tilt
		local aside = not W.moving and (gaze.y1 ~= 0 or gaze.p1 ~= 0)
		S.tiltTo = if aside and Kit.roll(S.dice) < TILT_CHANCE
			then TILT * (if Kit.roll(S.dice) < 0.5 then -1 else 1)
			else 0
	end
	S.tilt = S.tiltFrom + (S.tiltTo - S.tiltFrom) * Kit.ease((t - S.tiltAt) / LOOK.turn)
	rz[head[1]] += S.tilt

	-- THE TAIL: it follows. Its root swings it from side to side once a stride; the bone after it follows on a
	-- spring, a little later and a little further, and goes on after the tortoise has stopped. In a turn it
	-- stays behind.
	local tail, follow = S.tail, S.follow
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 8, 20, 50)
	end
	local lead = TAIL_SWING * amount * (1 - 0.5 * W.g) * sin(TAU * (W.phase - 0.1))
		+ SWISH * S.swishSide * Kit.pulse(t, S.swishAt, 0.9 * tick / 0.18)
	local before = 0
	local rate = TAIL_RATE / tick
	local slip = W.w * math.min(dt, 0.1)
	for k, i in tail do
		local s = follow[k]
		if input.jump or dt <= 0 then
			s.x, s.v = lead, 0
		end
		s.x = Kit.clamp(s.x - slip, lead - TAIL_MOST, lead + TAIL_MOST)
		local at = Kit.spring(s, lead, rate, TAIL_DAMP, dt)
		local own = Kit.clamp(at - before, -TAIL_MOST, TAIL_MOST)
		rx[i], ry[i], rz[i] = 0, own, 0
		before += own
		lead = before
	end
end

return Tortoise
