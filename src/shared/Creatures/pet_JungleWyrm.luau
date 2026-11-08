-- The Jungle Wyrm of the Jungle (art/models/ready/pet_JungleWyrm.glb, 31 bones: the owner's rig service's 29
-- with every leg remade as shoulder, elbow, wrist, toes / hip, stifle, hock, toes, the trunk, the neck and the
-- tail laid on one measured line; a long emerald dragon on FOUR short legs that splay out to the sides, with an
-- upright neck in a ruff of leaves, a head that carries branching antlers, a ridge of petals along its back and
-- a long low tail that turns up into a fan of leaves). Its joint map, and the MOTION OF THE SPHINX CAT
-- (pet_SphinxCat.luau, which is the Fairy Fox's walk in a cat's footfalls) on it, changed only where this body
-- is another: no wings, a trunk of three joints that shares its turns, a neck of three, short steps for short
-- legs under a long body, and a tail that is carried a little higher while it goes.
-- docs/motion/pet_JungleWyrm.md says where and why. Look at art/models/rigs/pet_JungleWyrm_left.png beside
-- this file.
-- Space: +x its right, +y up, it looks along -z.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Wyrm = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the rig's height, for every share below, is its highest BONE: the skull's joint at 0.435 in the units of
-- the file, 0.60 of the model's 0.728: the antlers stand over it)
local RIG = 0.435

Wyrm.map = {
	count = 31,
	tree = 1353783784,
	-- Root is the service's handle above the pelvis: it drives nothing and everything hangs on it. Body_01 is
	-- the PELVIS (the hind legs and the tail hang on it), Body_02 the LOIN, the top of the back's arch,
	-- Body_03 the CHEST between the shoulders (the forelegs and the neck hang on it)
	root = "Root",
	spine = { "Root", "Body_01", "Body_02", "Body_03" },
	-- an upright neck in a ruff of leaves: its base (where the body turns up), a third up, two thirds up; then
	-- the base of the skull (the face, the antlers with their blossoms, the whiskers and the upper half of the
	-- ruff are rigid on it)
	neck = { "Neck_01", "Neck_02", "Neck_03" },
	head = { "Head" },
	-- the dock, three joints down to the lowest of the tail, the turn up, the upturn, and the neck under the
	-- fan (the whole fan of leaves is rigid on the last)
	tail = { "Tail_01", "Tail_02", "Tail_03", "Tail_04", "Tail_05", "Tail_06", "Tail_07" },
	legs = {
		-- foreleg, from the body down: the SHOULDER (inside the chest: it aims the leg), the ELBOW (where the
		-- leg leaves the chest; it points back and folds the forearm forward and up), the WRIST (at the neck
		-- of the leg: its bone is the back of the long paw), the TOES (in the ball of the paw)
		LF = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" },
		RF = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" },
		-- hind leg: the HIP (inside the haunch), the STIFLE (the true knee, it points forward: it folds the
		-- shank back and up), the HOCK (the heel in the air: it folds the short piece under it forward and
		-- up), the TOES (at the heel of the paw: the whole paw follows it)
		LH = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" },
		RH = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" },
	},
	-- (Root lies in the middle, and the mesh mirrors itself)
	pairs = {
		{ "LF", "RF" },
		{ "LH", "RH" },
	},
}

-- HOW IT STROLLS in its plot: slower than the Sphinx Cat (the Camel's and the Deer's 0.045 for the cat's 0.06:
-- its steps are short, a paw travels 0.3 of the leg, and at the cat's pace they came 1.7 a second on a dragon
-- 11 studs tall; so 1.5), on its own short legs (the four top joints of its legs are 0.2235 up on
-- average), and it stands and watches between two. It turns no tighter than a circle
-- of one and a half body lengths (the cat's 0.9: this body is 1.4 times as long as it is tall, its pivot is
-- at its hips and its shoulders walk a third of its length ahead of it: in a turn the forepaws step
-- sideways, and legs this short have little reach for that).
Wyrm.stroll = { froude = 0.045, leg = 0.2235 / RIG, rest = { 3, 10 }, radius = 1.5 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward. `tip` and
-- `centre` are shares of the RIG's height. Every leg slopes outward, its foot 0.09 further out than its top
-- joint: that is the rest pose, and a leg swung about x keeps it.)
local function fore(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the wrist holds the long paw against the ground; the toes are moved after the solve: `Kit.toes`)
		ankle = 3,
		front = 0.5,
		-- (the planted point is the ground under the ball of the paw, where the toes' joint is)
		tip = { below = 0.020 / RIG, ahead = 0 },
		-- (the wrist stands 0.031 BEHIND the shoulder: walking, the middle of its step is 0.025 ahead of
		-- that, all but under the shoulder, or the leg was out of reach at the end of every push)
		centre = -0.025 / RIG,
		-- ONE joint folds, the elbow, in the air and (a little: the yield) on the ground
		fold = { swing = { 0, 1.0 }, stance = { 0, 1.0 } },
		sink = 0.05,
		-- (it stands with its elbow bent 14 degrees and may open by 13 to reach. It slopes outward, so it
		-- stands at 98.6% of its length all the same: `ease`, the Camel's, or the elbow snapped into its
		-- fold as the paw left the ground, 0.35 rad in a frame)
		open = 0.23,
		ease = true,
		lift = { walk = 0.04, trot = 0.04 },
		-- (lifted less than half as high as the Sphinx Cat's 0.1: ONE joint folds this leg, every hundredth of
		-- lift is four degrees of elbow, and the short upper arm swings back as the elbow folds: at 0.1 the
		-- shoulder went 31 degrees back and the wrist 54, and 25 and 40 are what the write-up allows)
		liftSkew = 0.95,
		-- the paw: flat, its back rolling up over the toes as it leaves, all but level in the air (the Sphinx
		-- Cat's hangs back 0.35 rad: here the wrist is already turned back by what elbow and shoulder leave
		-- it, and 40 degrees is its bound), flat again to land
		pitch = { stance = { 0, 0, 0.7, 0, 1, -0.25 }, swing = { 0, -0.25, 0.42, -0.04, 0.85, 0.06, 1, 0 } },
	}
end

local function hind(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the paw is held against the ground; stifle and hock above it are the Fox's)
		ankle = 4,
		front = 0.5,
		-- (the planted point: the ground under the claw tips, ahead of the paw's joint at its heel. This paw
		-- has no joint in its ball: planted further back, at 0.04, the claws went 0.13 studs into the ground
		-- as the heel rose)
		tip = { below = 0.025 / RIG, ahead = 0.063 / RIG },
		-- (the paw's joint stands all but under the hip: where it stands is the middle of a step)
		centre = 0,
		-- stifle and hock fold and open together (never one without the other), on the ground as in the air
		fold = { swing = { 0, -1.0, 0.95 }, stance = { 0, -1.0, 0.95 } },
		sink = 0,
		open = 0.2,
		lift = { walk = 0.11, trot = 0.095 },
		-- the paw: flat, its heel rising through the second half of the stance, carried forward nearly level,
		-- its toes a little up as it reaches, flat to land (the Sphinx Cat's)
		pitch = { stance = { 0, 0, 0.35, 0, 1, -0.3 }, swing = { 0, -0.3, 0.35, -0.2, 0.8, 0.12, 1, 0 } },
	}
end

Wyrm.legs = {
	fore("LF", "front left leg", Wyrm.map.legs.LF),
	fore("RF", "front right leg", Wyrm.map.legs.RF),
	hind("LH", "hind left leg", Wyrm.map.legs.LH),
	hind("RH", "hind right leg", Wyrm.map.legs.RH),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH) ---------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- a walk in lateral sequence: left hind, left fore, right hind, right fore, a quarter of a stride apart
	walk = {
		offsets = { 0.25, 0.75, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 },
		stride = { 3.3, 0.5 },
	},
	-- a trot, its travelling gait: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.4, slope = 0.05, ref = 1, least = 0.34, most = 0.46 },
		stride = { 2.3, 0.3 },
		-- (the Sphinx Cat's 0.5: the shoulder's 25 degrees back)
		sweep = 0.38,
		from = 0.32,
		back = 0.22,
		shift = 0.35,
	},
	-- (the Sphinx Cat's 0.52 of the leg. The forelegs are short, 0.145 from shoulder to wrist under legs that
	-- count as 0.2235, and they slope outward: a paw that travels 0.3 swings the shoulder 15 degrees back and
	-- 23 forward, 25 and 29 on the inside of its tightest turn, and 25 and 30 are its bounds)
	sweep = 0.3,
	finish = 0.25,
	settle = { far = 0.14, time = 1.5, least = 2, mean = 5, most = 14 },
	-- (a leg that hangs comfortably is as long as it stands: it stands exactly as it was modelled)
	comfy = 0.997,
	letGo = 0.6,
	comeDown = 0.4,
}

-- THE BODY, THE HEAD, THE TAIL (the Sphinx Cat's numbers, but for those marked) -----------------------------
local WALK_BOB = 0.016 -- shares of its leg an end sinks at each paw's landing, walking
-- (the Sphinx Cat's 0.035: every hundredth the chest sinks is elbow, and at 0.035 the elbow folded 57 degrees
-- under the trot and the shoulder went 29 back)
local TROT_BOB = 0.015 -- ... and over the middle of each stance, trotting
local HIP_DROP = 0.06 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02 -- ... and the chest for a foreleg (the ruff and the neck ride on it)
local HIP_YAW = 0.05 -- radians the pelvis turns to bring a hind leg forward, once a stride
local CHEST_YAW = 0.025 -- ... and the chest for a foreleg
local BREATH = 0.002 -- radians: barely there
-- (the head carries the antlers and half the ruff, a lump whose top is two thirds of the rig's height over
-- its joint: the neck takes ALL of what the trunk does. A look is shared by the three joints of the neck and
-- the skull, and is smaller and slower than the cat's: a joint of the neck yaws 10 degrees and the skull 20
-- before the leaves of the ruff pass into each other. Backward there is all but no room: `up` is small)
local LOOK = { yaw = 0.5, up = 0.05, down = 0.12, turn = 0.55, least = 2, mean = 14, aside = 3, most = 40, home = 0.9 }
local ASIDE = { 1.4, 2.6, 7 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.09, 0.4 -- radians it cocks its head as it looks at something, and how often it does
local NECK_SHARE = { 0.2, 0.2, 0.2 }
local HEAD_SHARE = { 0.4 }
local TURN_LEAD = 0.2 -- radians its head goes into a turn before the body, at most
local TAIL_SWING = 0.1 -- radians its root swings the tail to a side, once a stride
local TAIL_RATE = 3.4 -- how quickly a bone of the tail follows the one before (in units of sqrt(G / leg))
local TAIL_DAMP = 0.5
local TAIL_MOST = 0.19 -- radians a bone of it turns by itself at most (12 degrees at every joint is clean)
local SWISH = 0.16 -- radians its root swings the tail in one swish, standing
-- (the tail's belly runs 0.055 over the ground, an eighth of the rig's height, behind a rump that drops and
-- see-saws: while it goes, the first joints of the tail carry it a little higher. It is never lowered.)
local TAIL_CARRY = 0.02 -- radians each of its first four joints lifts while it goes (twice that trotting)
local TAIL_CARRIED = 4

local TOES_HANG = 0.4 -- the share of the paw's hang its toes take in the air

local SHOULDER_BACK_KNEE, SHOULDER_BACK_MOST = math.rad(22), math.rad(25) -- a shoulder's swing back

function Wyrm.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Wyrm.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local tail = Kit.chain(rig, "the tail")
	local follow = Kit.springRow(#tail)
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		root = rig.root,
		pelvis = Kit.bone(rig, "Body_01"),
		loin = Kit.bone(rig, "Body_02"),
		chest = Kit.bone(rig, "Body_03"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = tail,
		follow = follow,
		-- (which paw it sets off with from a square stand: a hind one, the left or the right by its own seed)
		lead = Kit.lead(seed),
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

function Wyrm.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	local stoodUp = W.fresh or input.jump or dt <= 0 or dt > 0.4
	Kit.gait(W, dt, input)
	if stoodUp then
		Kit.leadFeet(W, S.lead, input.yaw)
	end
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it. The rump drops on the side whose hind leg is in the air
	-- and turns to bring it forward; the chest does the same, less, for a foreleg. The chest hangs on the loin
	-- and the loin on the pelvis: the chest's own turn less the pelvis's is SHARED by the two joints ahead of
	-- the pelvis, half each, so the long back bends from side to side in one even curve (a small sideways
	-- wave, once a stride) and the petals of the back fan a little, each rigid on its own link.
	local g = Kit.smooth(W.g)
	local front = -Kit.both(Kit.girdle(W, 1, 2), Kit.ride(W, g, legs[1].phi, WALK_BOB, TROT_BOB, 0))
	local back = -Kit.both(Kit.girdle(W, 3, 4), Kit.ride(W, g, legs[3].phi, WALK_BOB, TROT_BOB, 0))
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (the root is at the hips, but it breathes about its SHOULDERS, as the Sphinx Cat does)
	local breathAt = t * TAU * 0.1 / tick + S.seed * TAU
	local breath = BREATH * sin(breathAt) * (1 - amount)
	local lean = pitch + breath
	pose.bob, pose.ox, pose.oz = bob - breath * (S.zRoot - S.zFront), 0, 0
	rx[S.root] = lean
	local hipYaw = -HIP_YAW * amount * cos(TAU * legs[3].phi)
	local chestYaw = -CHEST_YAW * amount * cos(TAU * legs[1].phi)
	local hipDrop = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local chestDrop = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	rz[S.pelvis], ry[S.pelvis] = hipDrop, hipYaw
	local halfRoll, halfYaw = 0.5 * (chestDrop - hipDrop), 0.5 * (chestYaw - hipYaw)
	rz[S.loin], ry[S.loin] = halfRoll, halfYaw
	rz[S.chest], ry[S.chest] = halfRoll, halfYaw
	Kit.solve(W, pose)
	-- (a shoulder swings back 25 degrees and no further: the bend table. Walking straight it swings 22; on the
	-- client's tightest circle at its stroll, and where a turn ends or changes sides, the forepaws step sideways
	-- and it asked 29 to 32: `tools/motion_turn.luau`. Eased from 22, never past 25; the paw then stands a
	-- little ahead of where it was planted for the last moments of its stance)
	for k = 1, 2 do
		local shoulder = legs[k].b[1]
		if rx[shoulder] < 0 then
			rx[shoulder] = Kit.bound(rx[shoulder], SHOULDER_BACK_KNEE, SHOULDER_BACK_MOST)
		end
	end
	Kit.toes(pose, legs[1], TOES_HANG, 0.25, -0.5, 0.6)
	Kit.toes(pose, legs[2], TOES_HANG, 0.25, -0.5, 0.6)

	-- THE HEAD: the steadiest part, and the heaviest. The neck undoes ALL the trunk does (its lean, the chest's
	-- turn and roll), so the antlers stand still over a body that walks; standing, it is still and now and
	-- then looks somewhere.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	rx[neck[1]] = -lean
	ry[neck[1]] = -chestYaw
	rz[neck[1]] = -chestDrop
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	Kit.asideHold(gaze, t, S.dice, LOOK.turn, ASIDE)
	-- (into a turn the head goes first)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -TURN_LEAD, TURN_LEAD) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)
	-- (now and then, as it looks at something, it cocks its head a little, and holds that as long as the look)
	rz[head[1]] += Kit.cock(S, t, W.moving, LOOK.turn, TILT, TILT_CHANCE)

	-- THE TAIL (the Sphinx Cat's, on the same seven joints): its root swings it from side to side once a
	-- stride; every bone after it follows the one before on a spring, a little later and a little further,
	-- and goes on after the wyrm has stopped; the fan rides on the last. In a turn it stays behind. While it
	-- goes its first joints carry it a little higher; nothing ever lowers it.
	local tail, follow = S.tail, S.follow
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 8, 20, 50)
	end
	local lead = hipYaw
		+ TAIL_SWING * amount * (1 - 0.5 * W.g) * sin(TAU * (W.phase - 0.1))
		+ SWISH * S.swishSide * Kit.pulse(t, S.swishAt, 5 * tick)
	Kit.chainFollow(
		pose,
		tail,
		follow,
		lead,
		hipYaw,
		TAIL_RATE / tick,
		TAIL_DAMP,
		TAIL_MOST,
		W.w * math.min(dt, 0.1),
		dt,
		input.jump
	)
	local carried = -TAIL_CARRY * amount * (1 + g)
	for k = 1, TAIL_CARRIED do
		rx[tail[k]] = carried
	end
end

return Wyrm
