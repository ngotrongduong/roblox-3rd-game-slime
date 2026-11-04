-- The Gorilla of the Jungle (art/models/ready/pet_Gorilla.glb, 18 bones: the owner's rig service's 22 with
-- every limb remade, one joint of the back and the neck taken out; a big gorilla on its knuckles, forearms of
-- carved stone, a garden with a tree rigid on its back, no neck, no tail). Its joint map, and the MOTION OF
-- THE SPHINX CAT (pet_SphinxCat.luau, itself the Fairy Fox's walk) on it, changed only where this body is
-- another: docs/motion/pet_Gorilla.md says where. Look at art/models/rigs/pet_Gorilla_left.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Gorilla = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Gorilla.map = {
	count = 18,
	tree = 2063972819,
	-- Root is the service's handle inside the pelvis: it drives nothing. Body_01 is the PELVIS (the hind legs
	-- hang on it), Body_02 the CHEST, which turns at the loin: the garden is rigid on it, and both arms and
	-- the head hang on it
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- there is no neck: the base of the skull is the one joint of the head, and the whole head rigid on it
	head = { "Head" },
	legs = {
		-- hind leg, plantigrade: the HIP (inside the haunch), the KNEE (it points forward and folds the shank
		-- back and up), the ANKLE (its bone is the rear half of the flat foot), the TOES (at the ball)
		LH = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" },
		RH = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" },
	},
	-- the arms: the SHOULDER (in the shoulder's dome), the ELBOW (its bone is the whole stone forearm; it
	-- folds the forearm forward and up), the WRIST (in the lower mouth of the stone: the fist). They are legs
	-- of the walker, but a wrist lies 17% of the rig's height up, over what the map lets a leg end at (12%):
	-- so they are limbs that keep the role of a leg
	limbs = {
		LA = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03" } },
		RA = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03" } },
	},
	-- (no `pairs`: the model stands in a stride and nothing of it mirrors)
	rigid = {},
}

-- HOW IT STROLLS in its plot: slowly and heavily, and it stands a good while between two.
-- (pace 1.1, not the walkers' 1.5: at 1.5 a joint left its limits in the client's slow turn)
Gorilla.stroll = { froude = 0.04, leg = 0.756, rest = { 4, 12 }, radius = 1, pace = 1.1 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward. `tip` is a
-- share of the RIG's height, which is 0.640 of the model's: the skull's joint is its highest. Every limb has
-- its own numbers. `centre`: a hind leg strides about its own modelled place; a hand lands about where it was
-- modelled and comes back from there, the middle of its stance 8% (left) and 7% (right) of the height behind
-- it: an arm that stands as a prop at its whole length reaches no further forward without the chest falling
-- 3% of the height onto it and the other elbow folding 50 degrees to follow)
local function arm(id, name, chain, open, below, ahead, centre)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the Cat's foreleg: the shoulder aims, the elbow is the ONE fold, the wrist holds the fist)
		ankle = 3,
		front = 0.5,
		-- (the planted point: the knuckles on the ground, below and ahead of the wrist)
		tip = { below = below, ahead = ahead },
		centre = centre,
		fold = { swing = { 0, 1.0 }, stance = { 0, 1.0 } },
		sink = 0.05,
		open = open,
		-- (the right arm stands straight: the Camel's forelegs)
		ease = true,
		-- (the forearm is twice the upper arm: a little elbow lifts the fist far. A heavy, low lift)
		lift = { walk = 0.025, trot = 0.006 },
		liftSkew = 0.95,
		-- the fist stays flat, rolls a little onto its knuckles as it leaves; in the air the wrist is bounded
		-- below (`WRIST`), so the fist goes with its stone
		pitch = { stance = { 0, 0, 0.75, 0, 1, -0.1 }, swing = { 0, -0.1, 0.4, 0, 1, 0 } },
	}
end

local function hind(id, name, chain, below)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the Cat's FORELEG behind as well: the hip aims, the knee is the one fold (back), the ankle holds
		-- the flat foot; the toes are the module's, `Kit.toes`)
		ankle = 3,
		front = 0.5,
		-- (the planted point: the sole under the ball of the foot. The soles lie 2% of the height over the
		-- plane of the knuckles, as the model was made: a foot is planted at its own height)
		tip = { below = below, ahead = 0 },
		centre = 0,
		fold = { swing = { 0, -1.0 }, stance = { 0, -1.0 } },
		sink = 0,
		-- (the knees stand bent 28 to 30 degrees and may open by 10)
		open = 0.17,
		-- (a low step: the hips swing 35 degrees forward and no more)
		lift = { walk = 0.04, trot = 0.04 },
		liftSkew = 0.95,
		-- the foot: flat, its heel rising at the end of the push, hanging a little in the air, flat to land
		pitch = { stance = { 0, 0, 0.7, 0, 1, -0.25 }, swing = { 0, -0.25, 0.42, -0.3, 0.85, 0.06, 1, 0 } },
	}
end

-- (the walker's order: left arm, right arm, left hind, right hind)
Gorilla.legs = {
	arm("LA", "left arm", Gorilla.map.limbs.LA.bones, 0.3, 0.171, 0.136, 0.128),
	-- (the right arm stands straight: it has nothing to open, and asked for a hair more it would snap to
	-- whatever it were allowed)
	arm("RA", "right arm", Gorilla.map.limbs.RA.bones, 0, 0.171, 0.136, 0.11),
	hind("LH", "hind left leg", Gorilla.map.legs.LH, 0.0485),
	hind("RH", "hind right leg", Gorilla.map.legs.RH, 0.0436),
}

-- THE GAITS (the legs in the order above: LA, RA, LH, RH) ---------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- an ape's walk, in DIAGONAL sequence: left hind, right arm, right hind, left arm, a quarter of a stride
	-- apart (the Cat's table with the two arms changed over)
	walk = {
		offsets = { 0.75, 0.25, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 },
		stride = { 3.3, 0.5 },
	},
	-- the Cat's trot for its run: the diagonal pairs together
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.4, slope = 0.05, ref = 1, least = 0.34, most = 0.46 },
		stride = { 2.3, 0.3 },
		sweep = 0.27,
		from = 0.32,
		back = 0.22,
		shift = 0.35,
	},
	-- (short steps: the arms stand as props, leaning forward, and reach no further)
	sweep = 0.31,
	finish = 0.25,
	-- (a hand left a little behind its place stands with its fist tipped: it steps back sooner than a cat's)
	settle = { far = 0.04, time = 1.5, least = 2, mean = 5, most = 14 },
	-- (the right arm stands straight and cannot open: only at its whole length does it stand as modelled)
	comfy = 1,
	letGo = 0.6,
	comeDown = 0.4,
}

-- THE BODY AND THE HEAD -------------------------------------------------------------------------------------
local WALK_BOB = 0.012 -- shares of its leg an end sinks at each landing, walking
local TROT_BOB = 0.025 -- ... and over the middle of each stance, trotting
-- (the tree stands half the height over the loin: every degree of the chest shows at its top)
local HIP_DROP = 0.035 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_KNEE, SHOULDER_MOST = 0.025, 0.05 -- radians the chest rolls as each shoulder rides on its own arm
local HIP_YAW = 0.04 -- radians the pelvis turns to bring a hind leg forward, once a stride
local CHEST_YAW = 0.02 -- ... and the chest for an arm
-- (its right arm stands STRAIGHT and its fist is planted: a breath of the trunk that moves that shoulder by a
-- hair ticks the elbow 3 degrees, whatever it turns about. So the trunk does not breathe; the head nods instead)
local HEAD_BREATH = 0.012 -- radians the head rises and settles with its breath, standing
-- (no neck: a look is the skull's alone, 30 degrees is its reach; slow and seldom)
local LOOK = { yaw = 0.42, up = 0.12, down = 0.12, turn = 0.6, least = 2, mean = 14, aside = 3, most = 40, home = 0.9 }
local ASIDE = { 1.6, 3, 8 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.08, 0.3
local TURN_LEAD = 0.2 -- radians its head goes into a turn before the body, at most
local HEAD_KNEE, HEAD_MOST = 0.4, 0.48 -- radians: the head's yaw is eased towards its limit
-- (the fist sits in the stone: it tips 20 degrees and no more. Past 11 the wrist is eased towards 19, and the
-- fist rolls over its knuckles with the forearm)
local WRIST_KNEE, WRIST_MOST = 0.26, 0.35
local TOES_HANG = 0.4 -- the share of the foot's hang its toes take in the air
local HOLD = 0.5 -- the share of an arm's swing its shoulder keeps the height it left at
local RISE_RATE = 7.5 -- how quickly the chest follows what its arms allow (in units of sqrt(G / leg))

-- THE CHEST ON ITS ARMS (the kit hangs a body from its legs: it only ever comes DOWN for a foot out of reach.
-- These arms stand as props, leaning forward at their whole length, so the shoulders stand lower than the
-- arms are long: a hand that comes back under its shoulder would have to fold its elbow 40 degrees and more
-- under the load, and with ONE folding joint under a short upper arm the shoulder then swings 60 back.)
-- How far over (or under) its rest height an arm that stands lets its shoulder be at the length it stands at:
-- nothing where it was modelled.
local ARM_BACK_KNEE, ARM_BACK_MOST = math.rad(28.5), math.rad(30) -- the left shoulder's swing back

local function allow(leg, dx, dz)
	local d2 = leg.restD * leg.restD
	return math.sqrt(math.max(d2 - dx * dx - dz * dz, 0.25 * d2)) - (leg.hipY - leg.restAnkleY)
end

-- One shoulder's height over rest: what its arm allows while it stands, and while it is in the air what it
-- will allow where it lands; followed without a step (`spring` is { x }). Each shoulder rides on its OWN arm
-- (the chest rolls by the difference: the shoulders of a knuckle-walker roll), for the two arms are not alike.
local function shoulder(spring, W, leg, dt, reset)
	local want
	if leg.mode == "down" then
		want = allow(leg, leg.tx - leg.u1x - leg.hipX - leg.xr, leg.tz - leg.u1z - leg.hipZ)
	elseif leg.s < HOLD then
		-- (the shoulder stays up while its hand passes under it: the arm has to fold the less)
		want = spring.x
	else
		local reach = if W.moving then leg.front * W.duty * W.stride else 0
		want = allow(leg, 0, leg.restAnkleZ + leg.centre * W.amount - leg.hipZ - reach)
	end
	if reset then
		spring.x = want
	else
		spring.x += (want - spring.x) * Kit.follow(RISE_RATE / W.tick, math.min(dt, 0.25))
	end
	return spring.x
end

function Gorilla.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Gorilla.legs do
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
		wristL = Kit.bone(rig, "FrontLeg_L_03"),
		wristR = Kit.bone(rig, "FrontLeg_R_03"),
		-- (it stands in a stride, its left hind leg stretched back: that one sets off, then the right arm)
		lead = { 1, 3, 4, 2 },
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		riseL = { x = 0 },
		riseR = { x = 0 },
		across = legs[2].hipX - legs[1].hipX,
		tilt = 0,
		tiltFrom = 0,
		tiltTo = 0,
		tiltAt = -100,
	}
end

function Gorilla.step(S, dt, input)
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

	-- THE BODY (the Cat's): each end rides on the limbs under it; the rump drops on the side whose hind leg is
	-- in the air and turns to bring it forward, the chest the same, less, for an arm. The chest hangs ON the
	-- pelvis: it is given its own turn less the pelvis's.
	local g = Kit.smooth(W.g)
	local riseL = shoulder(S.riseL, W, legs[1], dt, stoodUp)
	local riseR = shoulder(S.riseR, W, legs[2], dt, stoodUp)
	local front = (riseL + riseR) / 2 - Kit.ride(W, g, legs[1].phi, WALK_BOB, TROT_BOB, 0)
	local back = -Kit.both(Kit.girdle(W, 3, 4), Kit.ride(W, g, legs[3].phi, WALK_BOB, TROT_BOB, 0))
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	local breathing = sin(t * TAU * 0.08 / tick + S.seed * TAU) * (1 - amount)
	local lean = pitch
	pose.bob, pose.ox, pose.oz = bob, 0, 0
	rx[S.root] = lean
	local hipYaw = -HIP_YAW * amount * cos(TAU * legs[3].phi)
	local chestYaw = -CHEST_YAW * amount * cos(TAU * legs[1].phi)
	local hipDrop = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local chestDrop = Kit.bound((riseR - riseL) / S.across, SHOULDER_KNEE, SHOULDER_MOST)
	rz[S.pelvis], ry[S.pelvis] = hipDrop, hipYaw
	rz[S.chest], ry[S.chest] = chestDrop - hipDrop, chestYaw - hipYaw
	Kit.solve(W, pose)
	-- (its LEFT shoulder swings back 30 degrees and no further, the right 35: the bend table. Where a turn
	-- changes sides at its walk the left arm asked 31: `tools/motion_turn.luau`. Eased from 28.5)
	local shoulderL = legs[1].b[1]
	if rx[shoulderL] < 0 then
		rx[shoulderL] = Kit.bound(rx[shoulderL], ARM_BACK_KNEE, ARM_BACK_MOST)
	end
	-- (the fists in their stone, the toes flat under a heel that rises)
	rx[S.wristL] = Kit.bound(rx[S.wristL], WRIST_KNEE, WRIST_MOST)
	rx[S.wristR] = Kit.bound(rx[S.wristR], WRIST_KNEE, WRIST_MOST)
	Kit.toes(pose, legs[3], TOES_HANG, 0.25, -0.3, 0.6)
	Kit.toes(pose, legs[4], TOES_HANG, 0.25, -0.3, 0.6)

	-- THE HEAD: low between the shoulders and still. Its one joint undoes what the trunk does; standing, it now
	-- and then looks somewhere, slowly.
	local head = S.head
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	Kit.asideHold(gaze, t, S.dice, LOOK.turn, ASIDE)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -TURN_LEAD, TURN_LEAD) * amount, 5 / (tick / 0.29), 1, dt)
	local i = head[1]
	rx[i] = look - lean + HEAD_BREATH * breathing
	ry[i] = Kit.bound(yaw, HEAD_KNEE, HEAD_MOST) - chestYaw
	rz[i] = Kit.cock(S, t, W.moving, LOOK.turn, TILT, TILT_CHANCE) - chestDrop
end

return Gorilla
