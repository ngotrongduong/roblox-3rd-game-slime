-- The Hedgehog (art/models/ready/pet_Hedgehog.glb, 34 bones: a round body of spines on four short legs, a
-- long snout). Its joint map and its own motion. A small flat-footed shuffler: docs/MOTION.md sections 1 to
-- 3 and 7 are what it is designed from, docs/motion/pet_Hedgehog.md what was learned on it. Look at
-- art/models/rigs/pet_Hedgehog_left.png and _quarter.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Hog = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "022" is Bone_022)
Hog.map = {
	prefix = "Bone_",
	count = 34,
	tree = 647479804,
	-- 000 sits at the rear, between the hips; 002 and 001 (the top of the back) carry the coat of spines; 004
	-- and 003 run forward to the shoulders and drive nothing (the forelegs and the head hang on 003; the hind
	-- legs and the tail hang on 001)
	root = "000",
	spine = { "000", "002", "001", "004", "003" },
	-- 021 the neck (short, inside the head's mass), 020 the skull with the long snout
	neck = { "021" },
	head = { "020" },
	-- a stub under the last spines: it never moves by itself
	tail = { "019", "018", "017", "016" },
	legs = {
		-- foreleg, from the body down: the UPPER ARM (it aims the leg; it carries the leg down to the wrist's
		-- height and the skin of the chest beside it), the ELBOW (its bone carries the forearm's lower end: it
		-- folds forward and up), the WRIST (on the ground, it drives nothing: the hand lies flat), the TOES (a
		-- leaf that carries the paw)
		LF = { "029", "028", "027", "026" },
		RF = { "025", "024", "023", "022" },
		-- hind leg: the SHANK (it aims the leg, and it carries the WHOLE hind foot but its toes, a flat boot
		-- under the hip, and the flank above it), the HEEL and the BALL of the foot (they drive nothing), the
		-- TOES (a leaf that carries the little cap of the toes)
		LH = { "015", "014", "013", "012" },
		RH = { "011", "010", "009", "008" },
	},
	pairs = { { "LF", "RF" }, { "LH", "RH" } },
	-- rigid: the two ears (031, 033), and a chain under the belly behind the hind legs that drives one vertex
	-- (007, with 006 and 005: the generic reader took it for a fifth leg)
	rigid = { "031", "033", "007" },
}

-- HOW IT STROLLS in its plot: a slow, busy shuffle, with stops. (Its circle is wide for its size: in a
-- tighter one its outer feet would have to hurry, and it would break into its scurry.)
-- (pace 1.2, not the walkers' 1.5: at 1.5 a planted foot slid a third of a stud in the client's slow turn)
Hog.stroll = { froude = 0.024, leg = 0.38, rest = { 3, 9 }, radius = 1.3, pace = 1.2 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward)
local function fore(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 3,
		sole = 4,
		front = 0.5,
		-- (the paw lies on the ground in front of the bone that carries it: the planted point is under the
		-- middle of it, where the hand rolls off the ground)
		tip = { below = 0.025, ahead = 0.07 },
		-- (it stands with its forepaws out in front of its shoulders: walking, they step back under them)
		centre = 0.11,
		-- the elbow folds, in the air and (the yield) on the ground
		fold = { swing = { 0, 1.0 }, stance = { 0, 1.0 } },
		sink = 0,
		open = 0.2,
		lift = { walk = 0.17, trot = 0.2 },
		-- the hand: flat, its heel a little up as it leaves (it is a long hand: more would haul the wrist up),
		-- hanging from the wrist in the air, flat again to land
		pitch = { stance = { 0, 0, 0.65, 0, 1, -0.15 }, swing = { 0, -0.15, 0.3, -0.4, 0.78, 0.12, 1, 0 } },
	}
end

local function hind(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 3,
		sole = 4,
		front = 0.5,
		tip = { below = 0.025, ahead = 0.07 },
		-- (the middle of a step is a little behind where it stands: a boot that landed further ahead would pull
		-- the hind end down at every step, for it cannot get longer)
		centre = 0.022,
		-- The foot is a boot that is one piece with the shank: it rocks about the hip (heel first, flat, then up
		-- on its toes) while the cap of the toes stays flat on the ground. The heel's joint only moves that cap:
		-- it gives a little under the hip and lifts the toes in the air, and it never opens (a leg that reached
		-- further would rock the boot, and the flank, further).
		fold = { swing = { 0, 1.0 }, stance = { 0, 1.0 } },
		sink = 0,
		open = 0,
		lift = { walk = 0.06, trot = 0.08 },
		pitch = { stance = { 0, 0, 1, 0 }, swing = { 0, 0, 0.35, -0.3, 0.8, 0.1, 1, 0 } },
	}
end

Hog.legs = {
	fore("LF", "front left leg", Hog.map.legs.LF),
	fore("RF", "front right leg", Hog.map.legs.RF),
	hind("LH", "hind left leg", Hog.map.legs.LH),
	hind("RH", "hind right leg", Hog.map.legs.RH),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH) ---------------------------------------------------
local DESIGN = {
	start = 0.002,
	stop = 0.0008,
	-- its shuffle: a walk of four even beats in lateral sequence (left hind, left fore, right hind, right
	-- fore), small quick steps
	walk = {
		offsets = { 0.25, 0.75, 0, 0.5 },
		duty = { at = 0.66, slope = 0.02, ref = 0.03, least = 0.62, most = 0.68 },
		-- (stride = 3 x leg x sqrt(Froude): under its stroll it keeps its cadence and takes shorter steps: it
		-- sets off and stops on tiny ones, and no foot that stood is left far behind the body)
		stride = { 3, 0.5 },
	},
	-- its scurry: as soon as it hurries the walk slides into a trot (diagonal pairs), with longer strides
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.44, slope = 0.07, ref = 1, least = 0.34, most = 0.5 },
		stride = { 2.3, 0.3 },
		sweep = 0.8,
		from = 0.07,
		back = 0.05,
		shift = 0.25,
	},
	-- (the hind boot can only rock about its hip: a foot that travelled further on the ground would rock the
	-- flank and its spines with it)
	sweep = 0.3,
	finish = 0.25,
	settle = { far = 0.12, time = 1.4, least = 2, mean = 5, most = 14 },
	comfy = 0.997,
	letGo = 0.6,
	comeDown = 0.4,
}

-- THE BODY, THE HEAD ----------------------------------------------------------------------------------------
local BOB = 0.012 -- shares of its leg the body sinks at each foot's landing: it barely rises
local REAR_UP = 0.045 -- shares of its leg its hind end rides higher when it scurries (the boots then clear the ground)
local ROCK, ROCK_MOST = 0.32, 0.42 -- radians a hind boot rocks freely, and at the very most (beyond, it skids)
local PADDLE = 0.3 -- radians the hind boots swing each way when it scurries
local WADDLE_ROLL = 0.022 -- radians the body rolls onto the side whose hind foot stands, once a stride
local WADDLE_YAW = 0.03 -- radians it turns to bring a hind foot forward
local BREATH = 0.002 -- radians, about its middle: barely there
local NOSE_DOWN = 0.1 -- radians the snout is carried lower when it goes
local HEAD_KEEP = 0.2
-- (it looks about seldom, and not far: its world is what is under its nose)
local LOOK = { yaw = 0.5, up = 0.1, down = 0.12, turn = 0.3, least = 2, mean = 16, aside = 3, most = 45, home = 0.92 }
local ASIDE = { 1.2, 2.2, 6 } -- seconds a look aside is held: at least, on average, at most
local NECK_SHARE = { 0.4 }
local HEAD_SHARE = { 0.6 }
local SNIFF_UP = 0.22 -- radians it lifts its nose to smell the air
local SNIFF_TWITCH = 0.035 -- ... and the small quick nods of a sniff

-- The bigger of two, without a corner where one takes over from the other.
local function both(a, b)
	local a2, b2 = a * a, b * b
	return math.sqrt(math.sqrt(a2 * a2 + b2 * b2))
end

-- A turn that is itself up to `free` and never more than `most`, without a corner between the two.
local function limited(a, free, most)
	local size = math.abs(a)
	if size <= free then
		return a
	end
	local room = most - free
	return (if a < 0 then -1 else 1) * (free + room * math.tanh((size - free) / room))
end

function Hog.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Hog.legs do
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
		-- (which foot it sets off with from a square stand: a hind one, the left or the right by its own seed.
		-- Its hind boots cannot trail far; its forepaws stand well ahead of its shoulders and can wait)
		lead = if seed % 1 < 0.5 then { 2, 1, 4, 3 } else { 1, 2, 3, 4 },
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		hipHalf = math.abs(legs[3].hipX - legs[4].hipX) / 2,
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		sniffAt = -100,
		sniffFor = 1,
		sniffNext = 4 + 12 * Kit.roll(dice),
	}
end

function Hog.step(S, dt, input)
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
		-- So each stands a hair behind its place, a hind foot furthest: that one leads)
		local sy, cy = sin(input.yaw), cos(input.yaw)
		for k, leg in legs do
			local back = S.lead[k] * 1e-5 * W.h
			leg.wx += back * sy
			leg.wz += back * cy
		end
	end
	S.phase = W.phase
	local amount = W.amount
	local scurry = Kit.smooth(W.g) * amount -- 0 its shuffle to 1 its scurry

	-- THE BODY: a steady round body on busy legs. It barely rises and falls; it rolls a little onto the side
	-- whose hind foot stands and turns a little to bring the other forward (the waddle), about its middle.
	-- Scurrying, its hind end rides a little higher and no longer waits for its hind feet (they paddle).
	local function ride(phi)
		return amount * W.h * BOB * (0.5 + 0.5 * cos(2 * TAU * phi))
	end
	local hindPhi = legs[3].phi
	local roll = WADDLE_ROLL * amount * cos(TAU * (hindPhi - 0.5 * (1 + W.duty)))
	local yaw = -WADDLE_YAW * amount * cos(TAU * hindPhi)
	local rideBack = ride(hindPhi)
	local front = -both(Kit.girdle(W, 1, 2), ride(legs[1].phi))
	local back = REAR_UP * W.h * scurry - (rideBack + (both(Kit.girdle(W, 3, 4), rideBack) - rideBack) * (1 - scurry))
	-- (the roll lets the hip of the hind leg in the air drop; the one over the standing boot, which cannot
	-- get longer, keeps its height)
	back -= math.abs(roll) * S.hipHalf
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (the root is at the rear: the body turns, and breathes, about its middle, between shoulders and hips)
	local arm = S.zRoot - 0.5 * (S.zFront + S.zHind)
	local breath = BREATH * sin(t * TAU * 0.1 / tick + S.seed * TAU) * (1 - amount)
	pose.bob, pose.oz = bob - breath * arm, 0
	pose.ox = yaw * arm
	rx[S.root] = pitch + breath
	ry[S.root] = yaw
	rz[S.root] = roll
	Kit.solve(W, pose)
	-- (a hind boot rocks about its hip, and takes the flank with it: only so far, whatever its foot asks. When
	-- it scurries the boots cannot follow the ground at all: they paddle, forward as they land and back as
	-- they leave, and skid)
	for k = 3, 4 do
		local leg = legs[k]
		local top = leg.b[1]
		local own = limited(rx[top], ROCK, ROCK_MOST)
		local paddle = PADDLE * cos(TAU * (leg.phi - 0.5 * (W.duty - 0.5)))
		rx[top] = own + (paddle - own) * scurry
	end

	-- THE HEAD: the snout leads, low and steady; the neck cancels what the body does. Standing it is still;
	-- now and then it looks somewhere, or lifts its nose and sniffs the air.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	if not W.moving and t >= S.sniffNext then
		S.sniffAt, S.sniffFor = t, (1.1 + 0.8 * Kit.roll(S.dice)) * tick / 0.125
		S.sniffNext = t + S.sniffFor + Kit.wait(S.dice, 10, 26, 70)
	end
	local sniff = 0
	local u = (t - S.sniffAt) / S.sniffFor
	if u > 0 and u < 1 then
		-- (up in a quarter of it, held with three or four quick small nods, down again)
		local up = Kit.ease(u / 0.25) * (1 - Kit.ease((u - 0.75) / 0.25))
		sniff = up * (SNIFF_UP + SNIFF_TWITCH * sin(TAU * 4.5 * u))
	end
	rx[neck[1]] = -(1 - HEAD_KEEP) * pitch
	ry[neck[1]] = -yaw
	rz[neck[1]] = -(1 - HEAD_KEEP) * roll
	local gaze = S.gaze
	local lookYaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	if gaze.t0 == t and (gaze.y1 ~= 0 or gaze.p1 ~= 0) then
		-- (a look aside has just begun. The kit would hold it for a good part of the long hold before it, and
		-- the head would be turned a third of the time: it is held a few seconds, whatever came before)
		gaze.next = t + LOOK.turn + Kit.wait(S.dice, ASIDE[1], ASIDE[2], ASIDE[3])
	end
	-- (into a turn the snout goes first)
	lookYaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -0.35, 0.35) * amount, 5 / (tick / 0.29), 1, dt)
	local nose = look + sniff - NOSE_DOWN * amount
	Kit.spread(pose, neck, NECK_SHARE, nose, lookYaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, nose, lookYaw, 0)
end

return Hog
