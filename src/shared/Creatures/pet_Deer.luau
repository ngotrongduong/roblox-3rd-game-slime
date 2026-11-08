-- The Deer (art/models/ready/pet_Deer.glb, 62 bones: a fawn with a big head): its joint map and its own
-- motion. A hoofed quadruped like the Unicorn, and it started from that module, but its skeleton is another
-- (a spine of six bones from the hips to the chest, real pasterns on all four legs, a stub of a tail) and
-- every number here was set on its own film strips. docs/MOTION.md sections 1 to 4 and 21 are what it is
-- designed from, docs/motion/pet_Deer.md what was learned on it. Look at art/models/rigs/pet_Deer_left.png.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Deer = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "022" is Bone_022. The skeleton stands 0.03 to its right of the mesh's
-- middle: its middle line is the root's x)
Deer.map = {
	prefix = "Bone_",
	count = 62,
	tree = 2117987616,
	-- 000 sits over the hips and drives nothing to speak of; 001 is the pelvis (the hind legs, the tail and
	-- the whole spine hang on it); 012 to 008 are the back, hips to withers; 007 is the chest (the forelegs and
	-- the neck hang on it)
	root = "000",
	spine = { "000", "001", "012", "011", "010", "009", "008", "007" },
	-- a neck of five short bones, 030 in the chest, 026 under the skull
	neck = { "030", "029", "028", "027", "026" },
	-- 025 is the skull: everything of the head hangs on it
	head = { "025" },
	-- a stub of a tail; 002 is its folded tip
	tail = { "006", "005", "004", "003", "002" },
	legs = {
		-- foreleg, from the body down: shoulder joint (aims the leg), ELBOW (folds the forearm forward and up),
		-- CARPUS (the "knee": folds the cannon back and up, never forward), FETLOCK (the pastern), a second bone
		-- in the pastern, the tip of the toe, and the bone that carries the hoof (it hangs back from the toe)
		LF = { "037", "036", "035", "034", "033", "032", "031" },
		RF = { "044", "043", "042", "041", "040", "039", "038" },
		-- hind leg: hip, STIFLE (the true knee, points forward: folds the shank back and up), HOCK (the heel,
		-- points backward: folds the cannon forward and up), FETLOCK (it stands very low in this model), the
		-- tip of the toe, the bone that carries the hoof
		LH = { "024", "023", "022", "021", "020", "019" },
		RH = { "018", "017", "016", "015", "014", "013" },
	},
	pairs = { { "LF", "RF" }, { "LH", "RH" } },
	-- rigid with the skull: the two sides of the face and the eyes (045, 047, 049, 051), the muzzle and jaw
	-- (053, which drives a fifth of the whole mesh), the ears and the antlers (056, 059)
	rigid = { "045", "047", "049", "051", "053", "056", "059" },
}

-- HOW IT STROLLS in its plot: a slow walk for its own short legs, and it stands and watches a good while.
Deer.stroll = { froude = 0.045, leg = 0.4, rest = { 4, 12 }, radius = 0.9 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward)
local function fore(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		sole = 7,
		contact = chain[6],
		front = 0.5,
		tip = { below = 0.0135, ahead = 0.008 },
		-- (the fawn stands with its forefeet out in front: walking, the middle of a step is under the shoulder)
		centre = 0.05,
		-- in the air elbow and carpus fold together, the carpus first; on the ground nothing folds (the carpus
		-- is locked): its pastern sinks instead, which this model has a bone for
		fold = { swing = { 0, 1.0, -1.25 }, skew = { 0, -0.4, 0.4 } },
		sink = 0.4,
		lift = { walk = 0.05, trot = 0.1 },
		pitch = { stance = { 0, 0, 0.65, 0, 1, -0.35 }, swing = { 0, -0.35, 0.3, -1.0, 0.85, 0.05, 1, 0 } },
		pastern = { swing = { 0, 0, 0.3, 0.45, 0.85, 0, 1, 0 } },
	}
end

local function hind(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		sole = 6,
		contact = chain[5],
		front = 0.5,
		tip = { below = 0.002, ahead = 0.008 },
		-- stifle and hock fold and open together, on the ground as in the air (its hind leg is a deep zigzag:
		-- it gives easily), the hock a touch earlier
		fold = { swing = { 0, -1.0, 0.95 }, stance = { 0, -1.0, 0.95 }, skew = { 0, -0.25, 0.25 } },
		-- (its fetlock stands almost on the ground and its pastern lies nearly flat: there is nothing to sink)
		sink = 0,
		open = 0.08,
		lift = { walk = 0.1, trot = 0.16 },
		pitch = { stance = { 0, 0, 0.7, 0, 1, -0.4 }, swing = { 0, -0.4, 0.3, -0.9, 0.85, 0.05, 1, 0 } },
		pastern = { swing = { 0, 0, 0.3, 0.3, 0.85, 0, 1, 0 } },
	}
end

Deer.legs = {
	fore("LF", "front left leg", Deer.map.legs.LF),
	fore("RF", "front right leg", Deer.map.legs.RF),
	hind("LH", "hind left leg", Deer.map.legs.LH),
	hind("RH", "hind right leg", Deer.map.legs.RH),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH) ---------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- a walk of four even beats in lateral sequence: left hind, left fore, right hind, right fore
	walk = {
		offsets = { 0.25, 0.75, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 },
		stride = { 2.3, 0.3 },
	},
	-- a trot of two beats: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.44, slope = 0.06, ref = 1, least = 0.34, most = 0.5 },
		stride = { 2.3, 0.3 },
		sweep = 0.62,
		from = 0.42,
		back = 0.3,
		shift = 0.4,
	},
	sweep = 0.46,
	finish = 0.25,
	settle = { far = 0.14, time = 1.6, least = 2, mean = 5, most = 14 },
	comfy = 0.997,
	letGo = 0.55,
	comeDown = 0.45,
}

-- THE BODY, THE HEAD, THE TAIL ------------------------------------------------------------------------------
local LEVEL = 0.6 -- the share of the croup's rise over the withers that its hind legs take up
local LEVEL_FORE = 0.3 -- ... and of the withers' rise over the croup that its fore pasterns do
local HIP_DROP = 0.05 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02
local BREATH = 0.004 -- radians: barely there
local HEAD_KEEP = 0.15 -- the share of the trunk's pitch the head keeps
local NOD = 0.03 -- radians the neck nods at the walk, twice a stride
-- (a fawn on watch: it looks about more often than a horse, and holds the look)
local LOOK =
	{ yaw = 0.8, up = 0.12, down = 0.18, turn = 0.38, least = 1.5, mean = 12, aside = 3.5, most = 36, home = 0.85 }
local NECK_SHARE = { 0.05, 0.07, 0.1, 0.12, 0.14 } -- of a look: the neck does a little less than half ...
local HEAD_SHARE = { 0.52 } -- ... and the head the rest
local NOD_NECK = { 0.4, 0.3, 0.3, 0, 0 }
local NOD_HEAD = { -0.8 } -- (the face stays as it was while the neck nods)
local TAIL_UP = 0.5 -- radians its tail stands up along its bones when it trots off
local FLICK = 0.3 -- radians a flick of the tail goes to a side

function Deer.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Deer.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local tail = table.clone(Kit.chain(rig, "the tail"))
	table.remove(tail) -- (the folded tip follows)
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		root = rig.root,
		chest = Kit.bone(rig, "007"),
		pelvis = Kit.bone(rig, "001"),
		loin = Kit.bone(rig, "012"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = tail,
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		flickAt = -100,
		flickSide = 1,
		flickNext = 4 + 14 * Kit.roll(dice),
	}
end

function Deer.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, rz = pose.rx, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it (lowest as a hoof lands, highest over the middle of its
	-- stance: twice a stride, the two ends out of step). Its root is over the hips: the pitch turns about them.
	local front, back = -Kit.girdle(W, 1, 2), -Kit.girdle(W, 3, 4)
	if back > front then
		back -= LEVEL * (back - front)
	else
		front -= LEVEL_FORE * (front - back)
	end
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	pose.bob, pose.ox, pose.oz = bob, 0, 0
	rx[S.root] = pitch + BREATH * sin(t * TAU * 0.09 / tick + S.seed * TAU) * (1 - amount)
	-- (the pelvis carries the whole spine: what it rolls, the loin rolls back, so that the chest stays level)
	local hip = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	rz[S.pelvis] = hip
	rz[S.loin] = -0.8 * hip
	rz[S.chest] = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	Kit.solve(W, pose)

	-- THE HEAD: the steadiest part. It cancels what the trunk does; at the walk the neck nods a little twice a
	-- stride while the face keeps its angle; standing, it is still and now and then looks somewhere.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	rx[neck[1]] = -(1 - HEAD_KEEP) * pitch
	rz[neck[1]] = -(1 - HEAD_KEEP) * (rz[S.chest] + 0.2 * hip)
	local nod = NOD * amount * (1 - W.g) * cos(2 * TAU * legs[1].phi)
	Kit.spread(pose, neck, NOD_NECK, nod, 0, 0)
	Kit.spread(pose, head, NOD_HEAD, nod, 0, 0)
	local yaw, look = Kit.gaze(S.gaze, t, S.dice, LOOK, not W.moving)
	-- (into a turn the head goes first)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -0.4, 0.4) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)

	-- THE TAIL: a deer's tail hangs still. It flicks now and then while it stands (twice, quickly), and stands
	-- up like a flag when it trots off.
	local tail = S.tail
	Kit.zero(pose, tail)
	Kit.chainBend(pose, tail, "x", TAIL_UP * W.g * amount, 0.8)
	if not W.moving and t >= S.flickNext then
		S.flickAt, S.flickSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.flickNext = t + Kit.wait(S.dice, 6, 16, 45)
	end
	local span = 0.24 * tick / 0.24
	Kit.chainPulse(pose, tail, "y", FLICK * S.flickSide, t, S.flickAt, span, 0.02, 1.1, 0.5)
	Kit.chainPulse(pose, tail, "y", -FLICK * S.flickSide, t, S.flickAt + span * 1.1, span, 0.02, 1.1, 0.5)
end

return Deer
