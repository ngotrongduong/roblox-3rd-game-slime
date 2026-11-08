-- The Fairy Fox (art/models/ready/pet_FairyFox.glb, 44 bones: a small fox with a big head, a brush of a tail
-- curled round to its left, and four little wings that have no bones). Its joint map and its own motion. A
-- pawed quadruped that walks on its toes: docs/MOTION.md sections 1 to 3, 5 and 21 are what it is designed
-- from, docs/motion/pet_FairyFox.md what was learned on it. Look at art/models/rigs/pet_FairyFox_left.png.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Fox = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "022" is Bone_022. The skeleton stands 0.054 to its right of the mesh's
-- middle: its middle line is the root's x)
Fox.map = {
	prefix = "Bone_",
	count = 44,
	tree = 1497333789,
	-- 000 is the barrel; 001 (low in the belly) and 003 are helpers; 002 is the chest (the forelegs and the neck
	-- hang on it); 005 sits on the root's own place, 004 is the pelvis (the hind legs and the tail hang on it).
	-- The wings have no bones: they ride on 000, 005 and 004
	root = "000",
	spine = { "000", "001", "003", "002", "005", "004" },
	-- a short neck inside the ruff: 008 its base (it drives nothing), 007 under the skull
	neck = { "008", "007" },
	-- 006 is the skull: the face and the ears hang on it
	head = { "006" },
	-- the brush: 035 its root on the rump, 034 where the brush begins, 033 and 032 up through it, 031 its tip
	-- (a leaf that drives the tip's vertices: it turns too)
	tail = { "035", "034", "033", "032", "031" },
	legs = {
		-- foreleg, from the body down: SHOULDER BLADE (it aims the leg, from the withers), SHOULDER JOINT (the
		-- upper arm hangs straight down in this model; it closes: the elbow goes back), ELBOW (folds the forearm
		-- forward and up), WRIST (a short link forward that drives nothing: it stays with the forearm), the PAW
		-- (hand and fingers in ONE bone, from the wrist down to the toes), the tip of the toes
		LF = { "014", "013", "012", "011", "010", "009" },
		RF = { "020", "019", "018", "017", "016", "015" },
		-- hind leg: HIP, STIFLE (the true knee, points forward: folds the shank back and up), HOCK (the heel,
		-- points backward; a short link forward that drives nothing), the FOOT (hock to toes in ONE bone), the
		-- tip of the toes
		LH = { "030", "029", "028", "027", "026" },
		RH = { "025", "024", "023", "022", "021" },
	},
	pairs = { { "LF", "RF" }, { "LH", "RH" } },
	-- rigid with the skull: the whole face (037: it drives the head's 1,800 vertices), the two ears (040, 043)
	rigid = { "037", "040", "043" },
}

-- HOW IT STROLLS in its plot: a light, quick walk for its own leg, and it stands and watches between two.
Fox.stroll = { froude = 0.06, leg = 0.46, rest = { 3, 10 }, radius = 0.9 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward)
local function fore(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 5,
		front = 0.5,
		-- (the toes of the mesh reach the ground a little below and ahead of the last bone)
		tip = { below = 0.015, ahead = 0.02 },
		-- (it stands with its forepaws out in front of its shoulders: walking, they step back under them)
		centre = 0.11,
		-- shoulder joint and elbow fold together, in the air and (a little: the yield) on the ground. (No skew in
		-- time: the same shares on the ground and in the air, so nothing ticks as a paw leaves)
		fold = { swing = { 0, -0.5, 1.0, 0 }, stance = { 0, -0.5, 1.0, 0 } },
		-- (hand and fingers are ONE bone: a wrist that sank would tip the toes up, so it sinks only a little)
		sink = 0.1,
		open = 0.2,
		lift = { walk = 0.1, trot = 0.12 },
		-- the paw: flat, up on its toes as it leaves, hanging back from the wrist in the air, flat again to land
		pitch = { stance = { 0, 0, 0.75, 0, 1, -0.15 }, swing = { 0, -0.15, 0.45, -0.8, 0.85, 0.1, 1, 0 } },
	}
end

local function hind(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		front = 0.5,
		tip = { below = 0.002, ahead = 0.025 },
		-- (the model stands with its hind feet out behind: walking, they step further under the body)
		centre = -0.04,
		-- stifle and hock fold and open together (never one without the other), on the ground as in the air
		fold = { swing = { 0, -1.0, 0.95 }, stance = { 0, -1.0, 0.95 } },
		sink = 0,
		open = 0.2,
		lift = { walk = 0.09, trot = 0.11 },
		-- the foot (hock to toes in one bone): flat, then tipping forward over its toes through the second half
		-- of the stance (the hock rises: the push), hanging back in the air, flat again to land
		pitch = { stance = { 0, 0, 0.35, 0, 1, -0.5 }, swing = { 0, -0.5, 0.3, -0.85, 0.85, 0.05, 1, 0 } },
	}
end

Fox.legs = {
	fore("LF", "front left leg", Fox.map.legs.LF),
	fore("RF", "front right leg", Fox.map.legs.RF),
	hind("LH", "hind left leg", Fox.map.legs.LH),
	hind("RH", "hind right leg", Fox.map.legs.RH),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH) ---------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- a walk in lateral sequence: left hind, left fore, right hind, right fore
	walk = {
		offsets = { 0.22, 0.72, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 },
		-- (stride = 3.3 x leg x sqrt(Froude): under its stroll it keeps its cadence and takes shorter steps.
		-- It sets off, stops and turns on small steps, and no paw that stood is left far behind the body)
		stride = { 3.3, 0.5 },
	},
	-- a trot, its travelling gait: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.4, slope = 0.05, ref = 1, least = 0.34, most = 0.46 },
		stride = { 2.3, 0.3 },
		-- (as far as its short legs reach from the height it trots at, and no further: a longer step would
		-- pull the body down at every landing)
		sweep = 0.58,
		from = 0.32,
		back = 0.22,
		shift = 0.35,
	},
	sweep = 0.52,
	finish = 0.25,
	settle = { far = 0.14, time = 1.5, least = 2, mean = 5, most = 14 },
	comfy = 0.995,
	letGo = 0.6,
	comeDown = 0.4,
}

-- THE BODY, THE HEAD, THE TAIL ------------------------------------------------------------------------------
local CROUCH = 0 -- shares of its leg the body rides lower when it walks than when it stands
local WALK_BOB = 0.016 -- ... and sinks at each paw's landing, walking
local TROT_BOB = 0.035 -- ... and over the middle of each stance, trotting
local HIP_DROP = 0.06 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02
local HIP_YAW = 0.05 -- radians the pelvis turns to bring a hind leg forward, once a stride
local CHEST_YAW = 0.025 -- ... and the chest for a foreleg
local BREATH = 0.003 -- radians: barely there
local HEAD_KEEP = 0.15 -- the share of the trunk's pitch the head keeps
-- (a hunter on watch: still for long; now and then one quick look aside, held a few seconds, and back)
local LOOK = { yaw = 0.6, up = 0.14, down = 0.12, turn = 0.36, least = 2, mean = 14, aside = 3, most = 40, home = 0.9 }
local ASIDE = { 1.4, 2.6, 7 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.2, 0.4 -- radians it cocks its head as it looks at something, and how often it does
local NECK_SHARE = { 0.14, 0.24 } -- of a look: the neck does a good third ...
local HEAD_SHARE = { 0.62 } -- ... and the head the rest
local TAIL_SWING = 0.1 -- radians its root swings the brush to a side, once a stride
local TAIL_RATE = 3.4 -- how quickly a bone of the brush follows the one before (in units of sqrt(G / leg))
local TAIL_DAMP = 0.5
local TAIL_MOST = 0.3 -- radians a bone of it turns by itself at most
local SWISH = 0.24 -- radians its root swings the brush in one swish, standing

function Fox.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Fox.legs do
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
		chest = Kit.bone(rig, "002"),
		chestTurn = Kit.bone(rig, "003"),
		pelvis = Kit.bone(rig, "005"),
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

function Fox.step(S, dt, input)
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

	-- THE BODY: each end rides on the legs under it. Its legs fold and open as it goes over them, so it stays
	-- nearly level; the rump drops on the side whose hind leg is in the air and turns to bring it forward, the
	-- chest does the same, less, for a foreleg: the back bends a little from side to side
	local g = Kit.smooth(W.g)
	local front = -Kit.both(Kit.girdle(W, 1, 2), Kit.ride(W, g, legs[1].phi, WALK_BOB, TROT_BOB, CROUCH))
	local back = -Kit.both(Kit.girdle(W, 3, 4), Kit.ride(W, g, legs[3].phi, WALK_BOB, TROT_BOB, CROUCH))
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	pose.bob, pose.ox, pose.oz = bob, 0, 0
	rx[S.root] = pitch + BREATH * sin(t * TAU * 0.1 / tick + S.seed * TAU) * (1 - amount)
	local hipYaw = -HIP_YAW * amount * cos(TAU * legs[3].phi)
	local chestYaw = -CHEST_YAW * amount * cos(TAU * legs[1].phi)
	rz[S.pelvis] = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	ry[S.pelvis] = hipYaw
	rz[S.chest] = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	ry[S.chestTurn] = chestYaw
	Kit.solve(W, pose)

	-- THE HEAD: the steadiest part. It cancels what the trunk does and looks where it goes; standing, it is
	-- still and now and then looks somewhere.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	rx[neck[1]] = -(1 - HEAD_KEEP) * pitch
	ry[neck[1]] = -chestYaw
	rz[neck[1]] = -(1 - HEAD_KEEP) * rz[S.chest]
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	Kit.asideHold(gaze, t, S.dice, LOOK.turn, ASIDE)
	-- (into a turn the head goes first)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -0.4, 0.4) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)
	-- (now and then, as it looks at something, it cocks its head, and holds that as long as the look)
	rz[head[1]] += Kit.cock(S, t, W.moving, LOOK.turn, TILT, TILT_CHANCE)

	-- THE TAIL: a brush that follows. Its root swings it from side to side once a stride; every bone after it
	-- follows the one before on a spring, a little later and a little further, and goes on after the fox has
	-- stopped. In a turn it stays behind.
	local tail, follow = S.tail, S.follow
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 8, 20, 50)
	end
	local lead = hipYaw
		+ TAIL_SWING * amount * (1 - 0.5 * W.g) * sin(TAU * (W.phase - 0.1))
		+ SWISH * S.swishSide * Kit.pulse(t, S.swishAt, 0.9 * tick / 0.18)
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
end

return Fox
