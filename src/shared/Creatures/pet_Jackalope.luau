-- The Jackalope (art/models/ready/pet_Jackalope.glb, 44 bones: a rabbit with antlers): its joint map and its
-- own motion. It is a rabbit, and a rabbit does not walk: it has ONE gait at every speed, the half-bound
-- (docs/MOTION.md, section 6), and the kit's legs are a walker's, so the hop itself is written here: a body
-- that leaps from where it sits to where it lands while its pivot glides on at the pace the game moves it,
-- feet that stay in the world where they were put down, and a back that curls and stretches. The kit gives
-- the joint map, the solver that folds a leg onto its foot, the head that looks and the small things. This
-- module started as a copy of the Rabbit's and stands alone: its skeleton is another (a back of two bones,
-- longer feet, forelegs that stand to one side of where a mirror would put them, antlers), and its numbers
-- were set on its own film strips. docs/motion/pet_Jackalope.md says what was learned on it.
-- Look at art/models/rigs/pet_Jackalope_left.png.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, sqrt, abs, min, max, floor, exp, atan2, pi =
	math.sin, math.cos, math.sqrt, math.abs, math.min, math.max, math.floor, math.exp, math.atan2, math.pi
local TAU = pi * 2
local clamp, smooth, ease, wrap = Kit.clamp, Kit.smooth, Kit.ease, Kit.wrap

local Jackalope = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "022" is Bone_022)
Jackalope.map = {
	prefix = "Bone_",
	count = 44,
	tree = 566557603,
	-- 000 sits between the hips and drives nothing; 001 is the pelvis, behind it (the hind legs, the tail and
	-- the whole back hang on it); 016 and 015 are the back, hips to shoulders; 014 is the chest, between the
	-- shoulders (the collar bones and the neck hang on it)
	root = "000",
	spine = { "000", "001", "016", "015", "014" },
	-- 031 is the throat (it drives nothing by itself), 030 the skull: the whole head hangs on it
	neck = { "031" },
	head = { "030" },
	-- the scut: a ball on two bones
	tail = { "003", "002" },
	legs = {
		-- foreleg, from the body down: shoulder joint (aims the leg), ELBOW (folds the forearm forward and up),
		-- WRIST (folds the hand back), the PAW (it lies flat on the ground), the tip of the toes
		LF = { "027", "026", "025", "024", "023" },
		RF = { "021", "020", "019", "018", "017" },
		-- hind leg: hip, KNEE (points forward: folds the shank back and up), HEEL (points backward: folds the
		-- foot forward and up), the PAW (the toes: this model stands on them, its heel off the ground), the tip
		LH = { "008", "007", "006", "005", "004" },
		RH = { "013", "012", "011", "010", "009" },
	},
	-- the two ears and the two antlers, chains from the crown of the head: named so that every one of their
	-- bones is accounted for, and NEVER moved (nothing above the head moves by itself: they are rigid with the
	-- skull)
	limbs = {
		earL = { role = "extra", bones = { "043", "042", "041" } },
		earR = { role = "extra", bones = { "040", "039", "038" } },
		antlerL = { role = "extra", bones = { "037", "036" } },
		antlerR = { role = "extra", bones = { "035", "034" } },
	},
	-- (only the hind legs mirror each other: this skeleton veers to its right toward the front, and its
	-- forelegs stand 0.036 of the model's units to the right of where a mirror would put them)
	pairs = { { "LH", "RH" } },
	-- rigid: the collar bones (022, 028: from the chest out to the shoulder joints) and the crown of the head
	-- (029), which the ears and the antlers stand on, with the face (033, 032) that hangs on it
	rigid = { "022", "028", "029" },
}

-- HOW IT STROLLS in its plot: short hops with a pause after each, and long sits between two strolls. (The
-- speed is the one at which a hop of its usual length fills about two thirds of the time.)
-- (pace 1: it hops and sits; the walkers' half as fast again made it hop without a pause)
Jackalope.stroll = { froude = 0.03, leg = 0.285, rest = { 4, 11 }, radius = 0.7, pace = 1 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward. Every leg is
-- solved by the kit as a leg that stands, in the air too: see `step`)
local function fore(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		tip = { below = 0.0218, ahead = 0.03 },
		-- the elbow gives and the wrist folds back under it
		fold = { swing = { 0, 1.0, -0.8 }, stance = { 0, 1.0, -0.8 } },
		sink = 0,
		open = 0.1,
	}
end

local function hind(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		tip = { below = 0.0259, ahead = 0.035 },
		-- knee and heel fold and open together: a Z that closes in the crouch and opens in the push
		fold = { swing = { 0, -1.0, 1.0 }, stance = { 0, -1.0, 1.0 } },
		sink = 0,
		open = 0.5,
	}
end

Jackalope.legs = {
	fore("LF", "front left leg", Jackalope.map.legs.LF),
	fore("RF", "front right leg", Jackalope.map.legs.RF),
	hind("LH", "hind left leg", Jackalope.map.legs.LH),
	hind("RH", "hind right leg", Jackalope.map.legs.RH),
}

-- THE HOP ---------------------------------------------------------------------------------------------------
-- Lengths are in LEG LENGTHS (the mean height of its four top joints), times in units of sqrt(leg / G): a
-- rabbit of any size hops alike, a big one slower.
local HOP = {
	time = 5.5, -- a slow hop, from sitting to sitting
	quick = 2.5, -- the quickest bound: from there on more speed is longer bounds only
	length = 1.4, -- how far a slow hop goes
	-- (slower than length / time it pauses after every hop; faster, its hops get longer and quicker)
	bound = 1.5, -- this many times that speed further on it bounds for good: the body no longer stops between two
	far = 1.7, -- no hop is longer than this many times what its speed asks for
	start = 0.0015, -- the Froude numbers at which it starts and stops hopping after its pivot
	stop = 0.0006,
	chain = 0.03, -- a hop that ends this share of a hop before the next is due goes straight on into it
	settle = 0.4, -- sitting this share of a slow hop behind or beside its pivot, it hops up to it
	turned = 0.6, -- radians: sitting this far turned from its pivot, it hops round
	wait = 1.2, -- how long its pivot must have stood before it does either
	aim = 2, -- a hop under way moves the place it will land at this many times its own pace at most ...
	aimTurn = 4, -- ... and the way it will look by this many radians a second
	lost = 2.1, -- radians from the way its pivot looks, and hops from its pivot, at which it is put back on it
	lostFar = 4,
}
-- When things happen in a hop (shares of it; the slow hop, then the full bound). u = 0 is the bottom of the
-- crouch: all its weight on the folded hind legs.
local EVENTS = {
	hindOff = { 0.42, 0.16 }, -- the hind feet leave the ground, together
	foreLand = { 0.60, 0.50 }, -- the first forefoot lands
	hindLand = { 0.86, 0.90 }, -- the hind feet land, together
	foreOff = { 1.08, 0.72 }, -- the forefeet leave (over 1: in the next hop)
	pushFrom = { 0.10, 0 }, -- the hind legs begin to open
}
local STAGGER = 0.05 -- the second forefoot lands and leaves this share of a hop after the first
-- The body through a hop, as curves that come back on themselves (u, value, u, value ...; the first key is
-- at u = 0). Heights are those of the hips and of the shoulders over where they are in the rest pose.
local HIPS = {
	slow = { 0, -0.19, 0.10, -0.19, 0.42, 0.14, 0.54, 0.24, 0.86, -0.02 },
	fast = { 0, -0.10, 0.03, -0.10, 0.16, 0.06, 0.42, 0.16, 0.90, 0.02 },
}
local CHEST = {
	slow = { 0, -0.02, 0.08, -0.02, 0.41, 0.2, 0.63, -0.11, 0.78, -0.05 },
	fast = { 0, 0.03, 0.05, 0.05, 0.30, 0.12, 0.50, -0.07, 0.60, -0.12 },
}
-- (radians the back is curled, + rounded: most stretched in the flight, most rounded as the hind feet come down)
local FLEX = {
	slow = { 0, 0.30, 0.10, 0.30, 0.46, -0.18, 0.84, 0.50 },
	fast = { 0, 0.40, 0.03, 0.40, 0.34, -0.30, 0.88, 0.55 },
}
local PELVIS = 0.5 -- the share of the curl that tucks the pelvis under; the rest tips the chest down
local BACK = { 0.4, 0.4, 0.2 } -- how the two bones of its back and its chest share it
-- (the model stands with its hind toes under its hips, where a sitting rabbit's are well ahead of them)
local SIT_FWD = 0.3 -- sitting, its hind feet are this far further under it than in the rest pose
local AMP = { 0.45, 1.1 } -- a short hop is a low one
local TURN_FROM = 0.1 -- it turns in a hop from here until its forefeet land

-- THE FEET
local HIND = {
	lift = 0.4, -- how high the toes come in the air
	skew = 1.35,
	roll = -0.8, -- radians the foot rolls up onto its toes in the push, at most
	full = 1.07, -- the push opens the leg to this share of its rest length ...
	power = 1.3, -- ... quicker and quicker (the share of the push to this power)
	land = -0.25, -- it comes down on its toes, a little
	touch = 1.1, -- ... once its leg can reach the place at this share of its rest length
	-- the foot in the air: it trails, toes back, then folds up under the body and reaches forward
	sole = { 0, -0.8, 0.3, -1.15, 0.75, -0.5, 1, -0.25 },
	-- its length in the air, shares of its rest length (see `tether`): the leg that has just pushed off goes on
	-- opening to its full length over the first fifth of its swing, trails, and is folded up between two
	-- moments of the swing
	most = { 1.1, 0.9, 0.1, 0.7 },
	least = { 1.1, 0.84, 0.1, 0.7 },
	free = { 0.9, 1.1, 0.75, 0.95 }, -- (and it may be let out again to reach the ground)
	ease = 0.2,
	reach = 0.5, -- bounding, how far ahead of its place under the body it lands, at most
}
local FORE = {
	lift = 0.17,
	skew = 0.9,
	roll = -0.2,
	land = 0,
	touch = 0.97, -- it comes down once its leg can reach the place still a little bent (it does not snap straight)
	sole = { 0, -0.2, 0.4, -0.8, 0.85, 0.1, 1, 0 },
	reach = 0.45,
	-- a forefoot is carried along under its shoulder, folded, and only reaches for the ground at the end
	carry = 0.3, -- the share of its swing by which it is under the shoulder
	reachFrom = 0.5, -- ... and from which it reaches for where it lands
	-- its length in the air, shares of its rest length (see `tether`): folded by the first quarter of its
	-- swing, then let out to nearly straight between two moments of it (never quite: it stays a little bent)
	most = { 0.86, 0.97, 0.35, 0.92 },
	least = { 0, 0, 0, 1 },
	ease = 0.25,
}
local OVER = 0.01 -- a planted foot that is out of reach by this much lifts
local WIDE = 0.4 -- ... and one that is this far to the side of its leg (shares of the leg's rest length)
-- sitting, now and then it lifts a forefoot and sets it down again (seconds between two; the lift in units of
-- sqrt(leg / G); how much of a hop's lift)
local SHIFT = { least = 9, mean = 28, most = 90, time = 2.6, high = 0.55 }

-- THE HEAD
local HEAD_KEEP = 0.2 -- the share of the chest's pitch the head keeps
local LOOK =
	{ yaw = 0.75, up = 0.1, down = 0.12, turn = 0.3, least = 1.5, mean = 12, aside = 3.5, most = 36, home = 0.8 }
local NECK_SHARE = { 0.35 }
local HEAD_SHARE = { 0.65 }
local BREATH = 0.006 -- radians of curl: barely there

-- (the kit's walker is only what the solver and the tools read; its gaits are never played)
local PLAIN = { walk = { offsets = { 0, 0, 0, 0 } } }

-- Curves that come back on themselves ----------------------------------------------------------------------
-- The slope at every key of `keys`: a key that is a top or a bottom (or next to an equal one) is flat, any
-- other is passed without the curve ever going beyond its neighbours.
local function slopes(keys, m)
	local n = #keys // 2
	for i = 1, n do
		local p = if i == 1 then n else i - 1
		local q = if i == n then 1 else i + 1
		local u, y = keys[2 * i - 1], keys[2 * i]
		local before = u - keys[2 * p - 1] + (if i == 1 then 1 else 0)
		local after = keys[2 * q - 1] - u + (if i == n then 1 else 0)
		local s0, s1 = (y - keys[2 * p]) / before, (keys[2 * q] - y) / after
		if s0 * s1 <= 0 then
			m[i] = 0
		else
			m[i] = 3 * (before + after) / ((2 * after + before) / s0 + (after + 2 * before) / s1)
		end
	end
end

local function along(keys, m, u)
	local n = #keys // 2
	u -= floor(u)
	local i = n
	for k = 2, n do
		if u < keys[2 * k - 1] then
			i = k - 1
			break
		end
	end
	local q = if i == n then 1 else i + 1
	local u0 = keys[2 * i - 1]
	local span = (if i == n then 1 else keys[2 * q - 1]) - u0
	local t = (u - u0) / span
	local t2, t3 = t * t, t * t * t
	return (2 * t3 - 3 * t2 + 1) * keys[2 * i]
		+ (t3 - 2 * t2 + t) * span * m[i]
		+ (3 * t2 - 2 * t3) * keys[2 * q]
		+ (t3 - t2) * span * m[q]
end

-- The keys of a curve between its slow shape and its fast one.
local function blend(curve, c, keys, m)
	local slow, fast = curve.slow, curve.fast
	for i = 1, #slow do
		keys[i] = slow[i] + (fast[i] - slow[i]) * c
	end
	slopes(keys, m)
end

local function mix(pair, c)
	return pair[1] + (pair[2] - pair[1]) * c
end

-- How far along its hop the body is: it leaves and arrives softly; a bound goes on at one pace.
local function progress(c, u)
	return (1 - c) * ease(u / 0.84) + c * clamp(u, 0, 1)
end

-- The pace of its hops at a speed: how far one cycle goes (studs), how long a hop lasts (seconds), and how
-- much of a bound it is (0 a hop that stops, 1 a bound).
local function pace(W, speed)
	local time, length = HOP.time * W.tick, HOP.length * W.h
	local r = speed * time / length
	if r <= 1 then
		return length, time, 0
	end
	local quick = time * max(r ^ -0.5, HOP.quick / HOP.time)
	return speed * quick, quick, clamp((r - 1) / HOP.bound, 0, 1)
end

function Jackalope.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Jackalope.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, PLAIN, legs, seed)
	W.amount = 1
	local dice = Kit.dice(seed)
	local h = W.h
	-- (which forefoot lands first is this rabbit's own)
	local first = if Kit.roll(dice) < 0.5 then 1 else 2
	local air = {}
	for k, leg in legs do
		local isHind = k > 2
		local design = if isHind then HIND else FORE
		air[k] = {
			hind = isHind,
			design = design,
			up = false, -- it is in the air
			s = 0, -- how far through its swing
			dur = 1, -- seconds its swing lasts
			fx = 0, -- where it left the ground
			fz = 0,
			sig0 = 0, -- the pitch of its sole as it left, or as it landed
			long = 1, -- how long its leg was as it left (shares of its rest length)
			high = 1, -- how much of its usual lift this swing has (a small shift of a foot is a low one)
			hang = 0, -- seconds it has waited over the place it lands at for its leg to reach it
			lx = 0, -- that place
			lz = 0,
			since = 10, -- seconds since it landed
			liftAt = math.huge, -- the moment of this hop it leaves
			late = if isHind or k == first then 0 else STAGGER,
			-- its place under the sitting body, in the body's own frame
			sitX = leg.homeX,
			sitZ = leg.homeZ - (if isHind then SIT_FWD * h else 0),
			share = 0, -- bounding: the share of a bound it lands ahead of that place
		}
	end
	local n = #HIPS.slow
	-- (a big one turns its head more slowly)
	local look = table.clone(LOOK)
	look.turn = LOOK.turn * max(1, sqrt(W.tick / 0.14))
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		fresh = true,
		moving = false,
		still = 0,
		clock = 0, -- hops' worth of ground its pivot has covered
		nextHop = 0, -- the clock at which the next hop is due
		-- where the body is in the world (its own pivot and the way it looks), which is not where the model's is
		bx = 0,
		bz = 0,
		byaw = 0,
		shiftAt = nil, -- when it next shifts a forefoot (on its own clock) ...
		shiftIn = 4 + 24 * Kit.roll(dice), -- ... and how long after its first frame the first time
		rested = 10, -- seconds since its last hop ended
		endH = HIPS.slow[2], -- the pose that hop ended in
		endF = CHEST.slow[2],
		endX = FLEX.slow[2],
		hop = {
			active = false,
			u = 0,
			T = 1,
			c = 0,
			n = 0,
			x0 = 0,
			z0 = 0,
			yaw0 = 0,
			x1 = 0,
			z1 = 0,
			yaw1 = 0,
			turn = 0,
			far = 0,
			amp = 1,
			hindOff = 0,
			hindLand = 0,
			foreLand = 0,
			foreOff = 0,
			pushFrom = 0,
			hips = table.create(n, 0),
			hipsM = table.create(n // 2, 0),
			chest = table.create(#CHEST.slow, 0),
			chestM = table.create(#CHEST.slow // 2, 0),
			flex = table.create(#FLEX.slow, 0),
			flexM = table.create(#FLEX.slow // 2, 0),
		},
		air = air,
		root = rig.root,
		rootX = rig.px[rig.root],
		rootZ = rig.pz[rig.root],
		back = { Kit.bone(rig, "016"), Kit.bone(rig, "015"), Kit.bone(rig, "014") },
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		hindZ = (air[3].sitZ + air[4].sitZ) / 2, -- where the point between its hind feet is along the sitting body
		gaze = Kit.newGaze(),
		look = look,
	}
end

-- It sits on its pivot, its feet under it: the first frame, and a model that was put somewhere else.
local function seat(S, x, z, yaw)
	local W, H = S.walker, S.hop
	S.bx, S.bz, S.byaw = x, z, yaw
	S.rested, S.endH, S.endF, S.endX = 10, HIPS.slow[2], CHEST.slow[2], FLEX.slow[2]
	H.active = false
	local c, s = cos(yaw), sin(yaw)
	for k, leg in W.legs do
		local A = S.air[k]
		A.up, A.s, A.liftAt, A.since, A.sig0 = false, 0, math.huge, 10, 0
		leg.wx = x + A.sitX * c + A.sitZ * s
		leg.wz = z - A.sitX * s + A.sitZ * c
		leg.sigma = 0
	end
end

-- Where the hop that is under way ends: where its pivot will be by then, and as far ahead of it as it will
-- then sit behind it before the next hop is due (so that it is never far from its pivot either way).
local function aim(S, length, time, speed, dt)
	local W, H = S.walker, S.hop
	local left = (1 - H.u) * H.T
	local yaw = W.yaw + clamp(W.w * left, -1.2, 1.2)
	-- (none of that lead when its pivot is all but standing: it then comes to sit ON its pivot)
	local lead = max(0, (length - speed * time) / 2) * clamp(speed * time / (0.35 * length), 0, 1)
	local x = W.x + W.vx * left - sin(yaw) * lead
	local z = W.z + W.vz * left - cos(yaw) * lead
	local turn = wrap(yaw - H.yaw0)
	if dt then
		-- (a hop under way cannot change its mind in an instant)
		local most = HOP.aim * length / time * dt
		local mx, mz = x - H.x1, z - H.z1
		local moved = sqrt(mx * mx + mz * mz)
		if moved > most then
			x, z = H.x1 + mx * most / moved, H.z1 + mz * most / moved
		end
		turn = H.turn + clamp(turn - H.turn, -HOP.aimTurn * dt, HOP.aimTurn * dt)
	end
	local dx, dz = x - H.x0, z - H.z0
	local far = sqrt(dx * dx + dz * dz)
	local most = HOP.far * length
	if far > most then
		x, z, far = H.x0 + dx * most / far, H.z0 + dz * most / far, most
	end
	H.x1, H.z1, H.far = x, z, far
	H.turn = turn
	H.yaw1 = H.yaw0 + turn
	H.amp = clamp((far / (HOP.length * W.h)) ^ 0.6, AMP[1], AMP[2])
end

-- A hop begins. `carry`: the share of it that is already over (the frame it began in).
local function leap(S, carry, length, time, speed, c)
	local W, H = S.walker, S.hop
	H.active, H.u, H.T, H.c = true, carry, time, c
	-- (which hop of the clock this is: the one that was due, or the nearest when it is far out of step)
	local due = S.nextHop
	if abs(S.clock - due) > 0.5 then
		due = floor(S.clock + 0.5)
	end
	H.n, S.nextHop = due, due + 1
	H.x0, H.z0, H.yaw0 = S.bx, S.bz, S.byaw
	blend(HIPS, c, H.hips, H.hipsM)
	blend(CHEST, c, H.chest, H.chestM)
	blend(FLEX, c, H.flex, H.flexM)
	H.hindOff, H.hindLand = mix(EVENTS.hindOff, c), mix(EVENTS.hindLand, c)
	H.foreLand, H.foreOff = mix(EVENTS.foreLand, c), mix(EVENTS.foreOff, c)
	H.pushFrom = mix(EVENTS.pushFrom, c)
	aim(S, length, time, speed)
	for k in W.legs do
		local A = S.air[k]
		A.pushed = nil
		if A.up then
			A.liftAt = math.huge -- (it leaves again once it has landed)
		elseif A.hind then
			A.liftAt = H.hindOff
			A.share = 0.5 * (H.hindOff + 1 - H.hindLand)
		else
			A.liftAt = (if H.foreOff >= 1 then H.foreOff - 1 else 0.02) + A.late
			A.share = 0.5 * (H.foreOff - H.foreLand)
		end
	end
end

-- Where the body is at the moment `u` of the hop under way, and which way it looks. The hop is the path of
-- the point BETWEEN ITS HIND FEET: a rabbit that turns as it hops swings its front round over its haunches
-- while its hind feet still stand, so its hips stay over them.
local function place(S, u)
	local H = S.hop
	local s = progress(H.c, u)
	local yaw = H.yaw0 + H.turn * smooth((u - TURN_FROM) / (H.foreLand - TURN_FROM))
	local back = S.hindZ
	local x0, z0 = H.x0 + back * sin(H.yaw0), H.z0 + back * cos(H.yaw0)
	local x1, z1 = H.x1 + back * sin(H.yaw1), H.z1 + back * cos(H.yaw1)
	return x0 + (x1 - x0) * s - back * sin(yaw), z0 + (z1 - z0) * s - back * cos(yaw), yaw
end

-- A foot leaves the ground, to land at `landU` of this hop (over 1: in the next).
local function lift(S, k, leg, landU)
	local A, H = S.air[k], S.hop
	A.up, A.s, A.high, A.hang = true, 0, 1, 0
	A.fx, A.fz, A.sig0 = leg.wx, leg.wz, leg.sigma
	A.dur = max(landU - H.u, 0.12) * H.T
	A.liftAt = math.huge
end

local function landingOf(H, A)
	if A.hind then
		return H.hindLand
	end
	local land = H.foreLand + A.late
	return if H.u < land - 0.1 then land else 1 + land
end

-- Where a foot in the air comes down, `left` seconds from now: its place under the body as the body will
-- be. A hop that stops puts it where the body will SIT; a bound puts it ahead of the body, which goes on
-- over it.
local function landing(S, A, left)
	local W, H = S.walker, S.hop
	local x, z, yaw = S.bx, S.bz, S.byaw
	local reach = 0
	if H.active then
		local u = H.u + left / H.T
		if u <= 1 then
			x, z, yaw = place(S, u + (1 - H.c) * (1 - u))
		else
			-- (in the next bound: it goes on as its pivot goes)
			local on = if S.moving then (u - 1) * H.T else 0
			x, z, yaw = H.x1 + W.vx * on, H.z1 + W.vz * on, H.yaw1
		end
		reach = H.c * clamp(A.share * H.far - (if A.hind then SIT_FWD * W.h else 0), 0, A.design.reach * W.h)
	end
	local c, s = cos(yaw), sin(yaw)
	local hz = A.sitZ - reach
	return x + A.sitX * c + hz * s, z - A.sitX * s + hz * c
end

-- Keeps the target of a foot in the air between `least` and `most` of its leg's rest length from the top
-- joint (call it once the trunk stands in `W.fk`), and returns the share it asked for. A leg in the air is
-- solved from where its foot is told to be, and the body under it moves fast: left to that alone a foreleg
-- snaps from folded to straight in two frames as it reaches for a place far ahead (it stands nearly
-- straight, and turns its joints by many degrees for its last hundredth of length), and a hind leg snaps
-- from stretched to folded as its foot is swung forward. So in the air a leg's length is LET OUT and TAKEN
-- IN over the swing, by the curves of its design.
local function tether(W, leg, least, most)
	local fk, par = W.fk, leg.par
	local m, a = fk.m, (par - 1) * 9
	local r11, r12, r13 = m[a + 1], m[a + 2], m[a + 3]
	local r21, r22, r23 = m[a + 4], m[a + 5], m[a + 6]
	local r31, r32, r33 = m[a + 7], m[a + 8], m[a + 9]
	local dx = leg.tx - (fk.x[par] + r11 * leg.offX + r12 * leg.offY + r13 * leg.offZ)
	local dy = leg.ty - (fk.y[par] + r21 * leg.offX + r22 * leg.offY + r23 * leg.offZ)
	local dz = leg.tz - (fk.z[par] + r31 * leg.offX + r32 * leg.offY + r33 * leg.offZ)
	-- (the ankle from the top joint, in the frame of what the leg hangs on: as the kit's solver sees it)
	local lx = r11 * dx + r21 * dy + r31 * dz
	local ly = r12 * dx + r22 * dy + r32 * dz
	local lz = r13 * dx + r23 * dy + r33 * dz
	local sg = leg.sigma + atan2(r23, r22)
	local c1, s1 = cos(sg), sin(sg)
	local ax = lx - leg.u1x
	local ay = ly - (leg.u1y * c1 - leg.u1z * s1)
	local az = lz - (leg.u1y * s1 + leg.u1z * c1)
	local flat = sqrt(ay * ay + az * az)
	local far = sqrt(max(flat * flat + ax * ax - leg.xr * leg.xr, 0))
	-- (and how far to the side of where it hangs the foot is: a leg only leans so far)
	local aside = (ax - leg.xr) / leg.restD
	if not least then
		return far / leg.restD, aside
	end
	local want = clamp(far, least * leg.restD, most * leg.restD)
	if want ~= far and flat > 1e-6 then
		-- (along its own line, to or from the top joint; never into the ground)
		local back = (far - want) / flat
		local sy, sz = -ay * back, -az * back
		leg.tx += r12 * sy + r13 * sz
		leg.ty = max(leg.ty + r22 * sy + r23 * sz, leg.homeY)
		leg.tz += r32 * sy + r33 * sz
	end
	if abs(aside) > WIDE then
		local over = (clamp(aside, -WIDE, WIDE) - aside) * leg.restD
		leg.tx += r11 * over
		leg.ty = max(leg.ty + r21 * over, leg.homeY)
		leg.tz += r31 * over
	end
	return far / leg.restD, aside
end

local function ramp(keys, s)
	return keys[1] + (keys[2] - keys[1]) * smooth((s - keys[3]) / (keys[4] - keys[3]))
end

-- The pitch of the sole of a foot that stands, between `flat` and `rolled` (up on its toes), at which its leg
-- is `want` of its rest length long. A foot that rolls up onto its toes lifts its ankle after the body, so
-- the leg above it need not be so long: this is how the PUSH is shared between the leg's joints. The leg
-- opens by the curve of its design, and the foot rolls up by as much as that leaves to do (see `step`).
local function rollFor(W, leg, want, rolled, flat)
	local fk, par = W.fk, leg.par
	local m, a = fk.m, (par - 1) * 9
	local r11, r12, r13 = m[a + 1], m[a + 2], m[a + 3]
	local r21, r22, r23 = m[a + 4], m[a + 5], m[a + 6]
	local r31, r32, r33 = m[a + 7], m[a + 8], m[a + 9]
	local dx = leg.tx - (fk.x[par] + r11 * leg.offX + r12 * leg.offY + r13 * leg.offZ)
	local dy = leg.ty - (fk.y[par] + r21 * leg.offX + r22 * leg.offY + r23 * leg.offZ)
	local dz = leg.tz - (fk.z[par] + r31 * leg.offX + r32 * leg.offY + r33 * leg.offZ)
	local lx = r11 * dx + r21 * dy + r31 * dz
	local ly = r12 * dx + r22 * dy + r32 * dz
	local lz = r13 * dx + r23 * dy + r33 * dz
	local level = atan2(r23, r22)
	local side = (lx - leg.u1x) ^ 2 - leg.xr * leg.xr
	local goal = (want * leg.restD) ^ 2
	local lo, hi = rolled, flat
	for pass = 1, 14 do
		-- (the two ends first: flat when even that leaves the leg short enough, all the way up when even
		-- that leaves it too long)
		local sigma = if pass == 1 then flat elseif pass == 2 then rolled else (lo + hi) / 2
		local c1, s1 = cos(sigma + level), sin(sigma + level)
		local ay = ly - (leg.u1y * c1 - leg.u1z * s1)
		local az = lz - (leg.u1y * s1 + leg.u1z * c1)
		local long = ay * ay + az * az + side > goal
		if pass == 1 then
			if not long then
				return flat
			end
		elseif pass == 2 then
			if long then
				return rolled
			end
		elseif long then
			hi = sigma
		else
			lo = sigma
		end
	end
	return (lo + hi) / 2
end

function Jackalope.step(S, dt, input)
	local W, pose, H = S.walker, S.pose, S.hop
	local rx, ry = pose.rx, pose.ry
	local legs, air = W.legs, S.air
	local x, z, yaw, t = input.x, input.z, input.yaw, input.t
	local h, tick = W.h, W.tick

	-- HOW ITS PIVOT GOES (the game moves the model's pivot at an even pace; the rabbit hops after it)
	S.shiftAt = S.shiftAt or t + S.shiftIn
	if S.fresh or input.jump or dt <= 0 or dt > 0.4 then
		S.fresh, S.moving, S.still = false, false, 0
		W.vx, W.vz, W.w = 0, 0, 0
		seat(S, x, z, yaw)
		dt = 0
	else
		local k = 1 - exp(-12 * dt)
		W.vx += ((x - W.x) / dt - W.vx) * k
		W.vz += ((z - W.z) / dt - W.vz) * k
		W.w += (wrap(yaw - W.yaw) / dt - W.w) * k
	end
	W.x, W.z, W.yaw = x, z, yaw
	local speed = sqrt(W.vx * W.vx + W.vz * W.vz)
	local fr = speed * speed / (Kit.G * h)
	W.speed, W.fr = speed, fr
	if S.moving then
		S.moving = fr >= HOP.stop
	else
		S.moving = fr > HOP.start and dt > 0
	end
	W.moving = S.moving
	local length, time, c = pace(W, speed)
	do
		-- (spun round or carried off faster than any rabbit hops: it is put on its pivot again, not dragged after it)
		local dx, dz = x - S.bx, z - S.bz
		if abs(wrap(S.byaw - yaw)) > HOP.lost or dx * dx + dz * dz > (HOP.lostFar * length) ^ 2 then
			seat(S, x, z, yaw)
		end
	end
	-- THE CLOCK OF ITS HOPS: the ground its pivot covers, in hops. A hop is due at every whole number.
	local rate = if S.moving then speed / length else 0
	local step = rate * dt
	S.clock += step
	W.stride, W.f = length, rate

	-- A HOP ENDS, AND THE NEXT BEGINS
	if H.active then
		H.u += dt / H.T
		if H.u >= 1 then
			local over = (H.u - 1) * H.T
			S.bx, S.bz, S.byaw = H.x1, H.z1, H.yaw1
			S.endH = HIPS.slow[2] + H.amp * (along(H.hips, H.hipsM, 1) - HIPS.slow[2])
			S.endF = CHEST.slow[2] + H.amp * (along(H.chest, H.chestM, 1) - CHEST.slow[2])
			S.endX = FLEX.slow[2] + H.amp * (along(H.flex, H.flexM, 1) - FLEX.slow[2])
			H.active = false
			S.rested = over
			if S.moving and S.clock >= S.nextHop - HOP.chain then
				-- (it goes straight on: what this hop ran over is the next one's)
				leap(S, min(over / time, 0.5), length, time, speed, c)
			end
		end
	elseif S.moving and S.clock >= S.nextHop then
		leap(S, min((S.clock - S.nextHop) / (rate * time), 0.5), length, time, speed, c)
	end
	if H.active then
		if H.u < H.hindOff then
			aim(S, length, time, speed, dt) -- (until it has left the ground it can still change where it lands)
		end
		if S.moving then
			-- (the clock keeps step with the hops themselves: when its pace has changed and a hop begins early or
			-- late, the clock runs a little quicker or slower for a moment; it never jumps and never runs back)
			local ahead = H.n + H.u * H.T * rate - S.clock
			S.clock += clamp(ahead * (1 - exp(-6 * dt)), -0.8 * step, 2 * step)
		end
		S.still = 0
	else
		S.rested += dt
		if S.moving then
			S.still = 0
		else
			-- its pivot stands: once everything has landed the clock waits at a whole hop, and if it sits far
			-- behind its pivot, beside it or turned from it, it hops up to it
			S.still += dt
			local down = true
			for k in legs do
				down = down and not air[k].up
			end
			if down then
				S.clock = math.ceil(S.clock - 1e-9)
				S.nextHop = S.clock
				if S.still > HOP.wait * tick then
					local dx, dz = x - S.bx, z - S.bz
					local ahead = -(dx * sin(yaw) + dz * cos(yaw))
					local aside = abs(dx * cos(yaw) - dz * sin(yaw))
					local reach = HOP.settle * HOP.length * h
					if ahead > reach or aside > reach or abs(wrap(yaw - S.byaw)) > HOP.turned then
						leap(S, 0, length, time, 0, 0)
					elseif t >= S.shiftAt then
						-- A RARE SMALL SHIFT: it lifts one forefoot a little and sets it down again where it was
						local k = if Kit.roll(S.dice) < 0.5 then 1 else 2
						local A = air[k]
						A.up, A.s, A.long, A.high, A.hang = true, 0, nil, SHIFT.high, 0
						A.fx, A.fz, A.sig0 = legs[k].wx, legs[k].wz, legs[k].sigma
						A.dur = SHIFT.time * tick
						S.shiftAt = t + Kit.wait(S.dice, SHIFT.least, SHIFT.mean, SHIFT.most)
					end
				end
			end
		end
	end

	-- THE BODY: where it is, how high its two ends are, how far its back is curled
	local sitH, sitF, sitX = HIPS.slow[2], CHEST.slow[2], FLEX.slow[2]
	local yH, yF, flex
	if H.active then
		local u = H.u
		S.bx, S.bz, S.byaw = place(S, u)
		yH = sitH + H.amp * (along(H.hips, H.hipsM, u) - sitH)
		yF = sitF + H.amp * (along(H.chest, H.chestM, u) - sitF)
		flex = sitX + H.amp * (along(H.flex, H.flexM, u) - sitX)
	else
		-- (what was left of a bound's pose goes out as it sits down)
		local out = 1 - smooth(S.rested / (1.5 * tick))
		yH, yF, flex = sitH + (S.endH - sitH) * out, sitF + (S.endF - sitF) * out, sitX + (S.endX - sitX) * out
		flex += BREATH * sin(t * TAU * 0.11 / tick + S.seed * TAU)
	end
	local bob, pitch = Kit.carry(yF * h, yH * h, S.zFront, S.zHind, S.zRoot)
	local cy, sy = cos(yaw), sin(yaw)
	do
		-- the body's own place and heading, as an offset and a turn of the root in the model
		local dx, dz = S.bx - x, S.bz - z
		local turn = wrap(S.byaw - yaw)
		local ct, st = cos(turn), sin(turn)
		pose.ox = dx * cy - dz * sy + S.rootX * ct + S.rootZ * st - S.rootX
		pose.oz = dx * sy + dz * cy - S.rootX * st + S.rootZ * ct - S.rootZ
		pose.bob = bob
		rx[S.root], ry[S.root] = pitch + PELVIS * flex, turn
	end
	for k, i in S.back do
		rx[i] = -flex * BACK[k]
	end

	-- THE FEET: each stays in the world where it was put down until its moment of the hop, and then swings to
	-- where it will be needed
	Kit.forward(W.rig, pose, W.trunk, W.fk)
	for k, leg in legs do
		local A = air[k]
		local design = A.design
		if A.up then
			A.s += dt / A.dur
			if A.s >= 1 then
				-- (it comes down when its leg can reach the place, which is settled now: until then it hangs over it
				-- a moment longer)
				if A.hang == 0 then
					A.lx, A.lz = landing(S, A, 0)
				end
				local dx, dz = A.lx - x, A.lz - z
				leg.tx, leg.ty, leg.tz = dx * cy - dz * sy, leg.homeY, dx * sy + dz * cy
				leg.sigma = design.land
				if tether(W, leg) > min(design.touch, leg.longD / leg.restD) and A.hang < 0.5 * A.dur then
					A.s, A.hang = 1, A.hang + max(dt, 1e-6)
				end
			end
			if A.s > 1 then
				A.up, A.since, A.sig0 = false, (A.s - 1) * A.dur, design.land
				leg.wx, leg.wz = A.lx, A.lz
				if H.active and not A.hind then
					-- (a forefoot that lands in a hop leaves again in it: a bound's, after the body has gone over it;
					-- one that was only late for a hop, as soon as it can)
					if H.foreOff < 1 then
						A.liftAt = H.foreOff + A.late
					elseif H.u < 0.3 then
						A.liftAt = max(H.foreOff - 1 + A.late, H.u + 0.02)
					end
				end
			end
		elseif H.active and H.u >= A.liftAt then
			lift(S, k, leg, landingOf(H, A))
		end
		if not A.up then
			A.since += dt
			local dx, dz = leg.wx - x, leg.wz - z
			leg.tx, leg.ty, leg.tz = dx * cy - dz * sy, leg.homeY, dx * sy + dz * cy
			-- flat on the ground (a hind foot comes down a little on its toes, and settles)
			local sigma = A.sig0 * (1 - smooth(A.since / (0.6 * tick)))
			leg.sigma = sigma
			A.long = nil
			if H.active then
				if A.liftAt == math.huge then
					A.pushed = nil -- (it has done its part in this hop)
				elseif not A.hind then
					-- (a forefoot peels off the ground as it leaves)
					leg.sigma = sigma + FORE.roll * smooth((H.u - A.liftAt + 0.07) / 0.07)
				elseif H.u >= H.pushFrom then
					-- THE PUSH: the leg opens from the length it has in the crouch to its full length as the hind
					-- feet leave, by a curve of its own, and the foot rolls up onto its toes by as much as the body's
					-- going leaves to do: hip, knee, heel and toes open together, the toes last
					if not A.pushed then
						A.pushed = tether(W, leg)
					end
					local share = clamp((H.u - H.pushFrom) / (A.liftAt - H.pushFrom), 0, 1)
					local want = A.pushed + (max(HIND.full, A.pushed) - A.pushed) * share ^ HIND.power
					leg.sigma = rollFor(W, leg, want, HIND.roll, sigma)
				end
				-- (how long the leg is now: the length it leaves the ground with. And a foot the body has turned
				-- too far away from, to the side, lets go at once: its leg cannot lean after it)
				local long, aside = tether(W, leg)
				A.long = long
				if abs(aside) > WIDE then
					lift(S, k, leg, landingOf(H, A))
				end
			end
		end
		if A.up then
			local tx, tz = A.lx, A.lz
			if A.hang == 0 then
				tx, tz = landing(S, A, (1 - A.s) * A.dur)
			end
			local wx, wz = A.fx, A.fz
			local e = ease(A.s)
			if design.carry then
				local cb, sb = cos(S.byaw), sin(S.byaw)
				local carried = smooth(A.s / design.carry)
				wx += (S.bx + A.sitX * cb + A.sitZ * sb - wx) * carried
				wz += (S.bz - A.sitX * sb + A.sitZ * cb - wz) * carried
				e = ease((A.s - design.reachFrom) / (1 - design.reachFrom))
			end
			wx, wz = wx + (tx - wx) * e, wz + (tz - wz) * e
			local up = sin(pi * A.s ^ design.skew)
			leg.ty = leg.homeY + design.lift * h * A.high * (if H.active then H.amp else 1) * up * up
			leg.sigma = A.sig0 + (Kit.curve(design.sole, A.s) * A.high - A.sig0) * smooth(A.s / 0.25)
			local dx, dz = wx - x, wz - z
			leg.tx, leg.tz = dx * cy - dz * sy, dx * sy + dz * cy
			-- (how long the leg may be at this moment of its swing, and how short: from the length it left the
			-- ground with)
			if not A.long then
				A.long = tether(W, leg)
			end
			local most = ramp(design.most, A.s)
			if design.free then
				most = max(most, ramp(design.free, A.s))
			end
			most = A.long + (most - A.long) * smooth(A.s / design.ease)
			tether(W, leg, min(ramp(design.least, A.s), A.long, most), most)
		end
		leg.mode = "down" -- (for the kit's solver every leg stands: a leg in the air must be free to be longer than at rest)
	end
	Kit.solve(W, pose)
	for k, leg in legs do
		local A = air[k]
		-- (a foot the body has gone too far from lets go)
		if not A.up and H.active and leg.over > OVER * h then
			lift(S, k, leg, landingOf(H, A))
		end
		leg.mode, leg.s = if A.up then "swing" else "down", A.s
	end
	S.phase, W.phase = S.clock, S.clock

	-- THE HEAD: the steadiest part. It cancels most of what the chest does; sitting, it is still and now and
	-- then looks somewhere.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	local level = -(1 - HEAD_KEEP) * (pitch + (PELVIS - 1) * flex)
	rx[neck[1]] = 0.5 * level
	rx[head[1]] = 0.5 * level
	local look, nod = Kit.gaze(S.gaze, t, S.dice, S.look, not H.active and not S.moving)
	Kit.spread(pose, neck, NECK_SHARE, nod, look, 0)
	Kit.spread(pose, head, HEAD_SHARE, nod, look, 0)
end

return Jackalope
