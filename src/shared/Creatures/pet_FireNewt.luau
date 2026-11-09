-- The Fire Newt of the Ember Rim (art/models/ready/pet_FireNewt.glb, 30 bones, built here: a low sprawling
-- newt with legs of THREE joints (shoulder, elbow, wrist with the foot; hip, knee, ankle with the foot), a head
-- on a short neck, and TWO tails from one stump that curl up into two flames). Its joint map, and the MOTION OF
-- THE LIZARD (pet_Lizard.luau: the Fox's gait on a sprawler with short legs) on it, changed only where this body
-- is another: docs/motion/pet_FireNewt.md says where. Look at art/models/rigs/pet_FireNewt_left.png.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Newt = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Newt.map = {
	count = 30,
	tree = 1126120206, -- the print of the frozen ready skeleton's tree (names and parents)
	-- Root lies on Body_01 and drives nothing. ONE chain from the hips forward: Body_01 the PELVIS (the hind
	-- legs and the tails hang on it), Body_02 the WAIST, Body_03 the CHEST (the forelegs and the neck hang on
	-- it). What turns the pelvis turns the chest with it: the waist undoes it (the Lizard's)
	root = "Root",
	spine = { "Root", "Body_01", "Body_02", "Body_03" },
	neck = { "Neck_01", "Neck_02" },
	head = { "Head" },
	-- the LEFT tail, from the stump: Tail_01 (the stump, both tails hang on it) and the left tail's five joints,
	-- the last the flame. Six joints, as the Lizard's tail: the whole of the Lizard's tail motion drives it
	tail = { "Tail_01", "Tail_L_02", "Tail_L_03", "Tail_L_04", "Tail_L_05", "Tail_L_06" },
	-- the RIGHT tail: five joints with the role of a tail, which follow the left tail's joints of the same place
	-- (the Arctic Fox's side tails are written so)
	-- THE FOUR LEGS ARE LISTED UNDER `limbs`, NOT UNDER `legs`, for the way the Bloom Sprite's are: the kit
	-- refuses a chain of `legs` whose last joint is more than 12% of the RIG's height over the ground, and this
	-- rig's height is its highest joint (the left flame's, 0.47 of the file's units, while the model is 0.713
	-- high): the right wrist is 0.064 up, 14%. A chain of `limbs` is read the same and not measured.
	limbs = {
		tailRight = {
			role = "tail",
			bones = { "Tail_R_02", "Tail_R_03", "Tail_R_04", "Tail_R_05", "Tail_R_06" },
		},
		-- foreleg, from the body down: the SHOULDER (it aims the upper arm out and down), the ELBOW (it folds the
		-- shank), the WRIST (a leaf with the whole foot on it: the ankle and the sole are this one joint)
		LF = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03" } },
		RF = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03" } },
		-- hind leg: the HIP, the KNEE, the ANKLE (with the foot)
		LH = { role = "leg", bones = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03" } },
		RH = { role = "leg", bones = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03" } },
	},
	-- NO pairs: the right legs stand forward of the left ones (the right fore 0.11 and the right hind 0.13 of the
	-- length) and no leg is the mirror of its twin (as the Lizard's)
	pairs = {},
	-- nothing is rigid by a bone of its own: the feet and the flames are leaves that ride their joints
	rigid = {},
}

-- HOW IT STROLLS in its plot: the Lizard's walk (quick little steps, wide arcs, long rests). `leg`: the four top
-- joints are 0.19 up on average, over the rig's height 0.47: 0.40 (the Lizard's is 0.38).
Newt.stroll = { froude = 0.06, leg = 0.4, rest = { 3, 10 }, radius = 2 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- Each leg is a hip, a knee and a point, SOLVED AS THE CRAB'S (`Kit.sprawl`, `Kit.reachOut`): the upper piece runs
-- OUT from the body and the shank straight down, so that seen from the side the leg is a stick with no room to
-- fold (the Lizard's solver, which folds a leg seen from the side, slid its feet and sank them 14% of a leg).
-- The point is the foot's joint (the wrist, the ankle): it lies 0.04 to 0.064 over the ground with the foot flat
-- under it, and it is held at that height, so the foot stands where the model has it. `lift`: how high the point
-- swings, a share of the leg.
local function fore(id, name, chain)
	-- (`chain`: the names, hip to point)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the wrist is the ankle AND the sole of this leg: one joint carries the foot)
		ankle = 3,
		front = 0.5,
		-- (its hands stand where they were modelled, the left under its shoulder and the right 0.07 of the
		-- length ahead of its: its stance is about that place)
		centre = 0,
		lift = { walk = 0.1, trot = 0.13 },
	}
end

local function hind(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 3,
		front = 0.5,
		-- (a hind foot stands behind its hip already, 0.34 and 0.07 studs at the size of 5 studs: its stance is
		-- about the place it was modelled in, and the hip would have to reach further back for any other)
		centre = 0,
		lift = { walk = 0.09, trot = 0.12 },
	}
end

Newt.legs = {
	fore("LF", "front left leg", Newt.map.limbs.LF.bones),
	fore("RF", "front right leg", Newt.map.limbs.RF.bones),
	hind("LH", "hind left leg", Newt.map.limbs.LH.bones),
	hind("RH", "hind right leg", Newt.map.limbs.RH.bones),
}

-- HOW IT STANDS: all four legs were modelled all but straight (the hip to the point is 0.94 to 0.97 of the two
-- pieces added up, the fore left 0.95, the right 0.94), with nothing left to step with, as the Sun Scarab's.
-- So it stands LOWER than modelled, its feet where they are: this share of the rig's height (0.47) lower, 0.03
-- of the file's units, which bends every leg to 0.74 to 0.82 of its length; its belly (a trunk about 0.14 thick
-- over joints 0.20 up) is then still 0.03 over the ground.
local DROP = 0.03

-- (the kit's `sprawl`: radians a knee is bent at least and at most, the hip swings and lifts at most. The pieces
-- are bent about 40 to 90 degrees at rest: a foot is lifted by bending further, and put down reaches out by
-- opening to nearly straight)
-- (`shut` is read by the local solver: the most the shank turns about its hinge, 57 degrees, which is a roll of
-- 45 to 55 at a knee whose hinge is tilted. The write-up's table lets a joint turn 60)
local REACH = { open = 0.1, shut = 1.0, swing = 1.0, lift = 1.0 }

-- THE GAITS (the legs in the order above: LF, RF, LH, RH): the Lizard's ---------------------------------------
local DESIGN = {
	-- (the Lizard's: its legs are as short, so it creeps a sixth of a leg before a higher speed is reached)
	start = 0.0015,
	stop = 0.0006,
	-- a walk in lateral sequence: left hind, left fore, right hind, right fore
	walk = {
		offsets = { 0.22, 0.72, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 },
		-- (the Lizard's 3.3 x leg x sqrt(Froude), shortened: a foot here is out to the side of its hip, and the
		-- hip would have to swing the leg 60 degrees each way, the most its skin bends, for a longer step)
		stride = { 2.9, 0.5 },
	},
	-- a trot: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.4, slope = 0.05, ref = 1, least = 0.34, most = 0.46 },
		stride = { 2.3, 0.3 },
		sweep = 0.55,
		from = 0.32,
		back = 0.22,
		shift = 0.35,
	},
	sweep = 0.5,
	finish = 0.25,
	settle = { far = 0.14, time = 1.5, least = 2, mean = 5, most = 14 },
	comfy = 0.995,
	letGo = 0.6,
	comeDown = 0.4,
	-- (the Lizard's `firstStep`: a quick small walker steps its first foot in the next frame)
	firstStep = 0.75,
}

-- THE BODY, THE HEAD, THE TAILS: the Lizard's numbers, the spine's S a little deeper ------------------------
local CROUCH = 0 -- shares of its leg the body rides lower when it walks than when it stands
local WALK_BOB = 0.016 -- ... and sinks at each foot's landing, walking
local TROT_BOB = 0.035 -- ... and over the middle of each stance, trotting
local HIP_DROP = 0.06 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02
-- (a newt waves its spine from side to side as it walks: more than the Lizard's 0.05 and 0.025; the table of
-- its skin allows 40 degrees at the waist and chest, this is 4 and 2)
local HIP_YAW = 0.07 -- radians the pelvis turns to bring a hind leg forward, once a stride
local CHEST_YAW = 0.04 -- ... and the chest for a foreleg
local BREATH = 0.0012 -- radians: barely there (the Lizard's)
local HEAD_KEEP = 0.15 -- the share of the trunk's pitch the head keeps
-- (the head's skin bends 40 degrees at most each way: its looks stay far inside)
local LOOK = { yaw = 0.6, up = 0.14, down = 0.12, turn = 0.36, least = 2, mean = 14, aside = 3, most = 40, home = 0.9 }
local ASIDE = { 1.4, 2.6, 7 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.2, 0.4 -- radians it cocks its head as it looks at something, and how often it does
local NECK_SHARE = { 0.14, 0.24 }
local HEAD_SHARE = { 0.62 }
local TAIL_SWING = 0.1 -- radians its root swings the tails to a side, once a stride
local TAIL_RATE = 3.4 -- how quickly a bone of the tail follows the one before (in units of sqrt(G / leg))
local TAIL_DAMP = 0.5
local TAIL_MOST = 0.3 -- radians a bone of it turns by itself at most
local SWISH = 0.24 -- radians its root swings the tails in one swish, standing

local FOOT_MOST = math.rad(38) -- radians a foot is turned about y or z by itself at most

-- A turn of the pose's convention (the one of `Kit.forward`: x, then z, then y) as nine numbers, rows first.
local function turn(x, y, z)
	local cx, sx = cos(x), sin(x)
	local cy, sy = cos(y), sin(y)
	local cz, sz = cos(z), sin(z)
	return {
		cy * cz + sy * sx * sz,
		-cy * sz + sy * sx * cz,
		sy * cx,
		cx * sz,
		cx * cz,
		-sx,
		-sy * cz + cy * sx * sz,
		sy * sz + cy * sx * cz,
		cy * cx,
	}
end

-- LOCAL to this module (the kit lacks it: `reachOut` plants the point but leaves the foot to ride the shank): the
-- foot is held as it was modelled, flat on the ground and pointing along the heading, whatever the trunk, the hip
-- and the knee above it do. The ankle turns by the inverse of what is above it. `m` is the nine numbers a bone of
-- `Kit.forward`'s answer; `leg.par` is the bone the hip hangs on.
local function levelFoot(m, leg, pose)
	local p = (leg.par - 1) * 9
	local a = turn(pose.rx[leg.b[1]], pose.ry[leg.b[1]], pose.rz[leg.b[1]])
	local b = turn(pose.rx[leg.b[2]], pose.ry[leg.b[2]], pose.rz[leg.b[2]])
	-- up = parent x hip x knee, row by row
	local ab = table.create(9, 0)
	for r = 0, 2 do
		for c = 1, 3 do
			ab[r * 3 + c] = a[r * 3 + 1] * b[c] + a[r * 3 + 2] * b[3 + c] + a[r * 3 + 3] * b[6 + c]
		end
	end
	local up = table.create(9, 0)
	for r = 0, 2 do
		for c = 1, 3 do
			up[r * 3 + c] = m[p + r * 3 + 1] * ab[c] + m[p + r * 3 + 2] * ab[3 + c] + m[p + r * 3 + 3] * ab[6 + c]
		end
	end
	-- the foot's own turn is the transpose of that (the inverse of a turn), and the angles of it
	local rx = math.asin(math.clamp(-up[8], -1, 1)) -- (transpose m23 = up m32)
	local ry = math.atan2(up[7], up[9]) -- (transpose m13 = up m31, m33 = up m33)
	local rz = math.atan2(up[2], up[5]) -- (transpose m21 = up m12, m22 = up m22)
	local foot = leg.b[3]
	-- (the right hind foot's skin tears at the toes past 40 degrees of yaw or roll: no foot is turned beyond 38 of
	-- either, and in a spin or a hard turn it follows its shank for the rest)
	pose.rx[foot], pose.ry[foot], pose.rz[foot] =
		rx, math.clamp(ry, -FOOT_MOST, FOOT_MOST), math.clamp(rz, -FOOT_MOST, FOOT_MOST)
end

-- LOCAL to this module (the kit lacks it): THE KNEE'S HINGE ACROSS THE BODY. `Kit.sprawl` hinges the knee about
-- the normal of the plane of the leg's two pieces at rest; here the pieces are modelled nearly parallel (the
-- upper one 45 degrees down and out, the shank straight down: 38 to 45 degrees between them), the normal is
-- dominated by the small fore-and-aft slants of the joints, and folding the leg swung the shank round a tilted
-- axis, so that the hip had to turn the whole leg 60 degrees about the upright to put the foot back (the
-- planted feet slid, the hips went to 116 degrees). A newt's elbow and knee hinge about the axis ACROSS the
-- body, level and fore-and-aft, so the hinge is that (the z axis, taken square to the shank), and the solver
-- below is `Kit.reachOut` with the rotation of the shank about an axis that is not square to the upper piece:
-- the distance from the hip to the point is K0 + K1 cos t + K2 sin t for a shank turned by t, which is solved
-- exactly.
local function hinge(leg)
	local ax, ay, az, bx, by, bz = leg.ax, leg.ay, leg.az, leg.bx, leg.by, leg.bz
	local B = math.sqrt(bx * bx + by * by + bz * bz)
	local hx, hy, hz = bx / B, by / B, bz / B
	-- the z axis, made square to the shank
	local nx, ny, nz = -hz * hx, -hz * hy, 1 - hz * hz
	local n = math.sqrt(nx * nx + ny * ny + nz * nz)
	nx, ny, nz = nx / n, ny / n, nz / n
	leg.nx, leg.ny, leg.nz = nx, ny, nz
	-- (the shank turned a quarter about that axis: n x b)
	local cx, cy, cz = ny * bz - nz * by, nz * bx - nx * bz, nx * by - ny * bx
	leg.cx, leg.cy, leg.cz = cx, cy, cz
	local K0 = (ax * nx + ay * ny + az * nz) * (nx * bx + ny * by + nz * bz)
	local K1 = ax * bx + ay * by + az * bz - K0
	local K2 = ax * cx + ay * cy + az * cz
	leg.hK0, leg.hK1, leg.hK2 = K0, K1, K2
	leg.hM, leg.hPsi = math.sqrt(K1 * K1 + K2 * K2), math.atan2(K2, K1)
end

local function wrap(a)
	return (a + pi) % TAU - pi
end

-- Puts the point of a leg at this frame's target of `gait`, as `Kit.reachOut`, hinged as `hinge` says. `shut`
-- is the most the shank turns, whichever way it closes. The hip is the kit's: a swing about the upright, then a
-- lift.
local function reachOut(W, leg, pose)
	local fk = W.fk
	local m = fk.m
	local p = (leg.par - 1) * 9
	local r11, r12, r13, r21, r22, r23, r31, r32, r33 =
		m[p + 1], m[p + 2], m[p + 3], m[p + 4], m[p + 5], m[p + 6], m[p + 7], m[p + 8], m[p + 9]
	local dx = leg.tx - (fk.x[leg.par] + r11 * leg.offX + r12 * leg.offY + r13 * leg.offZ)
	local dy = leg.ty - (fk.y[leg.par] + r21 * leg.offX + r22 * leg.offY + r23 * leg.offZ)
	local dz = leg.tz - (fk.z[leg.par] + r31 * leg.offX + r32 * leg.offY + r33 * leg.offZ)
	local lx = r11 * dx + r21 * dy + r31 * dz
	local ly = r12 * dx + r22 * dy + r32 * dz
	local lz = r13 * dx + r23 * dy + r33 * dz
	local d = math.sqrt(lx * lx + ly * ly + lz * lz)
	-- the shank's turn t that makes the leg as long as that
	local K0, M, psi = leg.hK0, leg.hM, leg.hPsi
	local c = (0.5 * (d * d - leg.A2 - leg.B2) - K0) / M
	local t
	if c >= 1 then
		t, leg.over = psi, d - math.sqrt(leg.A2 + leg.B2 + 2 * (K0 + M))
	elseif c <= -1 then
		t, leg.over = psi + pi, math.sqrt(math.max(leg.A2 + leg.B2 + 2 * (K0 - M), 0)) - d
	else
		local u = math.acos(c)
		-- (the branch the model stands on: t = 0 at rest is psi less its own sign times the angle at rest)
		t, leg.over = psi - (if psi < 0 then -u else u), 0
	end
	-- (the shank turns as far as its skin lets it, REACH.shut; a leg asked for more is short of its point by the
	-- difference, which `over` says as the kit's legs do)
	t = math.clamp(wrap(t), -REACH.shut, REACH.shut)
	local s, co = sin(t), cos(t)
	leg.over = math.max(
		leg.over,
		math.abs(d - math.sqrt(math.max(leg.A2 + leg.B2 + 2 * (K0 + leg.hK1 * co + leg.hK2 * s), 0)))
	)
	local nx, ny, nz = leg.nx, leg.ny, leg.nz
	local k = 1 - co
	local knee = leg.b[2]
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	rx[knee] = math.asin(math.clamp(nx * s - ny * nz * k, -1, 1))
	ry[knee] = math.atan2(nx * nz * k + ny * s, co + nz * nz * k)
	rz[knee] = math.atan2(ny * nx * k + nz * s, co + ny * ny * k)
	-- the leg from its hip to its point with that knee, the hip still at rest
	local nb = nx * leg.bx + ny * leg.by + nz * leg.bz
	local vx = leg.ax + leg.bx * co + leg.cx * s + nx * nb * k
	local vy = leg.ay + leg.by * co + leg.cy * s + ny * nb * k
	local vz = leg.az + leg.bz * co + leg.cz * s + nz * nb * k
	-- the hip: the SHORTEST turn from the leg as it lies to the way its target lies (the kit's two hinges, a swing
	-- about the upright and a lift, are ill-conditioned for a leg that points nearly straight down: its heading
	-- is nothing to turn from)
	local v = math.max(math.sqrt(vx * vx + vy * vy + vz * vz), 1e-9)
	vx, vy, vz = vx / v, vy / v, vz / v
	local l = math.max(d, 1e-9)
	lx, ly, lz = lx / l, ly / l, lz / l
	local ax, ay, az = vy * lz - vz * ly, vz * lx - vx * lz, vx * ly - vy * lx
	local across = math.sqrt(ax * ax + ay * ay + az * az)
	local hip = leg.b[1]
	if across < 1e-9 then
		rx[hip], ry[hip], rz[hip] = 0, 0, 0
		return
	end
	ax, ay, az = ax / across, ay / across, az / across
	local angle = math.min(math.atan2(across, vx * lx + vy * ly + vz * lz), leg.swingMost)
	local ca, sa = cos(angle), sin(angle)
	local q = 1 - ca
	rx[hip] = math.asin(math.clamp(ax * sa - ay * az * q, -1, 1))
	ry[hip] = math.atan2(ax * az * q + ay * sa, ca + az * az * q)
	rz[hip] = math.atan2(ay * ax * q + az * sa, ca + ay * ay * q)
end

function Newt.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Newt.legs do
		local one = Kit.leg(rig, spec)
		Kit.sprawl(rig, one, REACH)
		hinge(one)
		legs[k] = one
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
		drop = DROP * rig.height,
		root = rig.root,
		pelvis = Kit.bone(rig, "Body_01"),
		waist = Kit.bone(rig, "Body_02"),
		chest = Kit.bone(rig, "Body_03"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = tail,
		tailRight = Kit.chain(rig, "tailRight"),
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

function Newt.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	local stoodUp = W.fresh or input.jump or dt <= 0 or dt > 0.4
	Kit.gait(W, dt, input)
	if stoodUp then
		-- (just stood on its four feet: each a hair behind its place, a hind foot furthest, so that a hind foot
		-- leads: the Lizard's)
		local sy, cy = sin(input.yaw), cos(input.yaw)
		for k, leg in legs do
			local back = S.lead[k] * 1e-5 * W.h
			leg.wx += back * sy
			leg.wz += back * cy
		end
	end
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it; the back waves from side to side (the Lizard's)
	local g = Kit.smooth(W.g)
	local function ride(phi)
		local walk = WALK_BOB * (0.5 + 0.5 * cos(2 * TAU * phi))
		local trot = TROT_BOB * (0.5 + 0.5 * cos(2 * TAU * (phi - 0.5 * W.duty)))
		return amount * W.h * (CROUCH + walk + (trot - walk) * g)
	end
	-- (not the kit's `girdle`, what a hip must come down for a foot to reach: a leg that sprawls is solved exactly
	-- at any height, as the Crab's and the Scarab's, and the body is carried at one)
	local front = -ride(legs[1].phi)
	local back = -ride(legs[3].phi)
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	local breath = BREATH * sin(t * TAU * 0.1 / tick + S.seed * TAU) * (1 - amount)
	pose.bob, pose.ox, pose.oz = bob - S.drop - breath * (S.zRoot - 0.5 * (S.zFront + S.zHind)), 0, 0
	rx[S.root] = pitch + breath
	local hipYaw = -HIP_YAW * amount * cos(TAU * legs[3].phi)
	local chestYaw = -CHEST_YAW * amount * cos(TAU * legs[1].phi)
	local hipRoll = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local chestRoll = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	rz[S.pelvis] = hipRoll
	ry[S.pelvis] = hipYaw
	-- (the chest hangs on the pelvis: the waist undoes the pelvis's turn before the chest makes its own)
	rz[S.waist] = -hipRoll
	ry[S.waist] = -hipYaw
	rz[S.chest] = chestRoll
	ry[S.chest] = chestYaw
	-- THE LEGS: each point where the kit planted it, or where it swings (the trunk's turns are in `pose`)
	Kit.forward(W.rig, pose, W.trunk, W.fk)
	for _, one in legs do
		reachOut(W, one, pose)
		levelFoot(W.fk.m, one, pose)
	end

	-- THE HEAD: the steadiest part (the Lizard's)
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	rx[neck[1]] = -(1 - HEAD_KEEP) * pitch
	ry[neck[1]] = -chestYaw
	rz[neck[1]] = -(1 - HEAD_KEEP) * chestRoll
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	if gaze.t0 == t and (gaze.y1 ~= 0 or gaze.p1 ~= 0) then
		gaze.next = t + LOOK.turn + Kit.wait(S.dice, ASIDE[1], ASIDE[2], ASIDE[3])
	end
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -0.4, 0.4) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)
	if gaze.t0 ~= S.tiltAt then
		S.tiltAt, S.tiltFrom = gaze.t0, S.tilt
		local aside = not W.moving and (gaze.y1 ~= 0 or gaze.p1 ~= 0)
		S.tiltTo = if aside and Kit.roll(S.dice) < TILT_CHANCE
			then TILT * (if Kit.roll(S.dice) < 0.5 then -1 else 1)
			else 0
	end
	S.tilt = S.tiltFrom + (S.tiltTo - S.tiltFrom) * Kit.ease((t - S.tiltAt) / LOOK.turn)
	rz[head[1]] += S.tilt

	-- THE TAILS: the left tail is the Lizard's (it follows the hips on a spring, bone after bone, and goes on
	-- after the newt has stopped; in a turn it stays behind); the right tail does what the left does, joint for
	-- joint, so that the two sway TOGETHER and keep their gap (rolled into each other they pass through one
	-- another, so nothing ever rolls or pitches a tail)
	local tail, follow = S.tail, S.follow
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 8, 20, 50)
	end
	local lead = hipYaw
		+ TAIL_SWING * amount * (1 - 0.5 * W.g) * sin(TAU * (W.phase - 0.1))
		+ SWISH * S.swishSide * Kit.pulse(t, S.swishAt, 0.9 * tick / 0.18)
	local before = hipYaw
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
	-- (the right tail's joint k is the left tail's joint k + 1: the stump comes first in the left chain)
	for k, i in S.tailRight do
		rx[i], ry[i], rz[i] = 0, ry[tail[k + 1]], 0
	end
end

return Newt
