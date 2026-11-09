-- The Yeti, the boss of the Frozen Peaks (art/models/ready/boss_Peaks.glb, 62 bones): its joint map and its own
-- motion. It is Mama Bear's motion (boss_Woods) on another skeleton: a heavy biped on two short legs that stand
-- bent, a barrel of a chest, two long arms that HANG (the bear's are held out to the sides), a stub of a tail.
-- What differs from her is only what the skeleton forces: which bone is which, one bone for the neck, the keys of
-- the arms (they hang, so a swing is a turn about x), the sleeping pose's rows, and the foot's height off the
-- ground. docs/motion/boss_Peaks.md says what and why; look at art/models/rigs/boss_Peaks_left.png and _front.png
-- beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")
local Boss = if script then require(script.Parent.Parent.BossKit) else require("../BossKit")

local sin, cos, max, pi = math.sin, math.cos, math.max, math.pi
local TAU = pi * 2
local smooth = Kit.smooth

local Yeti = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "021" is Bone_021)
Yeti.map = {
	prefix = "Bone_",
	count = 62,
	tree = 1626440161,
	-- 000 the middle of the barrel (drives nothing); 001 the pelvis (both legs and the tail hang on it); 007, 006
	-- the lower spine (drive nothing); 005 the chest (both arms, the neck, the beard and the mane hang on it)
	root = "000",
	spine = { "000", "001", "007", "006", "005" },
	-- 021 the neck (and the mane round it), the one bone between the chest and the skull
	neck = { "021" },
	-- 020 the skull: the face (037, 036), the crest (035, 034) hang on it
	head = { "020" },
	limbs = {
		-- a leg, from the body down: HIP, KNEE (points forward: it folds the shank back and up; it stands bent a
		-- long way), ANKLE (the heel), the BALL of the foot, the tip of the toes
		L = { role = "leg", bones = { "017", "016", "015", "014", "013" } },
		R = { role = "leg", bones = { "012", "011", "010", "009", "008" } },
		-- an arm, hanging at the side: the COLLAR (the base of the shoulder, on the chest), SHOULDER, ELBOW, WRIST
		-- (drives nothing), the HAND (four chains of fingers hang on it)
		armL = { role = "arm", bones = { "033", "032", "031", "030", "029" } },
		armR = { role = "arm", bones = { "028", "027", "026", "025", "024" } },
	},
	-- (no pair of arms: the two hands stand 0.05 of the height apart front to back, which the map's check of a
	-- mirror does not allow)
	pairs = { { "L", "R" } },
	-- rigid with what they hang on: the stub of a tail (004, 003, 002), the tuft on the back (019, 018), the
	-- beard (023, 022), the crest (035, 034), the face (037, 036) and the fingers of both hands
	rigid = {
		"004",
		"019",
		"023",
		"035",
		"037",
		"040",
		"043",
		"046",
		"049",
		"052",
		"055",
		"058",
		"061",
	},
}

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians the knee turns for one radian of fold, + tips the joint's lower end forward)
local function leg(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 3,
		-- the point that stays planted is the BALL of the foot on the ground: the heel lifts about it before the
		-- foot leaves, and what the hips turn while it stands, the foot turns about it
		contact = chain[4],
		tip = { below = 0.0256, ahead = 0 },
		front = 0.54,
		-- one joint folds, the knee: in the air and under its weight
		fold = { swing = { 0, -1 }, stance = { 0, -1 } },
		open = 0.1,
		lift = { walk = 0.1, trot = 0.22 },
		-- the sole: flat, the heel up before it leaves, level again as it passes under, flat to land
		pitch = { stance = { 0, 0, 0.55, 0, 1, -0.6 }, swing = { 0, -0.6, 0.3, -0.3, 0.6, 0.08, 1, 0 } },
	}
end

Yeti.legs = {
	leg("L", "left leg", Yeti.map.limbs.L.bones),
	leg("R", "right leg", Yeti.map.limbs.R.bones),
}

-- THE GAITS (the legs in the order above: left, right): the bear's -------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	walk = {
		offsets = { 0, 0.5 },
		duty = { at = 0.62, slope = 0.04, ref = 0.2, least = 0.56, most = 0.68 },
		stride = { 2.3, 0.3 },
	},
	trot = {
		offsets = { 0, 0.5 },
		duty = { at = 0.372, slope = 0.165, ref = 1.52, least = 0.22, most = 0.5 },
		stride = { 3.6, 0.3 },
		sweep = 1.38,
		from = 0.62,
		back = 0.48,
		shift = 0.4,
	},
	sweep = 1.0,
	finish = 0.5,
	settle = { far = 0.2, time = 1.6, least = 2, mean = 5, most = 14 },
	comfy = 0.99,
	letGo = 0.6,
	comeDown = 0.4,
}

-- THE BODY: the bear's -----------------------------------------------------------------------------------------
-- (shares of its height unless they are radians)
local CROUCH = 0.004
local DIP = 0.011
local SWAY = 0.012
local ROLL = { walk = 0.07, run = 0.05 }
local YAW = { walk = 0.08, run = 0.2 }
local SQUARE = 0.85
local LEAN = { walk = 0.04, run = 0.1, rage = 0.22 }
local NOD = 0.02
local KNEE = 24
local HIP = 16 -- how fast a hip in the air follows what its foot asks (1/s): the Yeti runs at 2 heights a second
local LEG_SLEW = 26.4 -- radians/s; a bounded final recovery at faster run speeds
local REACH = 40
local BREATH = 0.006
local ARM_LAG = 0.08
local HOP = 0.008
local BELLY = 0.012
local HEELS = 0.03

-- WHERE IT LOOKS: at its thief, at the hub
local MIND = { settle = 2.4, head = "020", look = { yaw = 1.1, up = 0.35, down = 0.5 } }
local NECK_SHARE = 0.3
local CHEST_SHARE = 0.2

-- THE ARMS: keys for the RIGHT arm (collar, shoulder, elbow), the left one mirrors them. The arm HANGS: a turn of
-- the shoulder about x swings it forward (+) or back (-), the elbow folds the forearm forward (+) about x, and a
-- turn about z takes it out (+) or in (-). The keys are the bear's moods on a hanging arm.
local CALM_F = { { 0, 0, 0 }, { 0.3, 0, 0 }, { 0.25, 0, 0 } }
local CALM_B = { { 0, 0, 0 }, { -0.35, 0, 0 }, { 0.1, 0, 0 } }
local RUN_F = { { 0, 0, 0 }, { 1.0, 0, -0.1 }, { 1.3, 0, 0 } }
local RUN_B = { { 0, 0, 0 }, { -0.7, 0, 0 }, { 1.0, 0, 0 } }
local RAGE_F = { { 0, 0, 0 }, { 1.4, 0, -0.6 }, { 0.9, 0, 0 } }
local RAGE_B = { { 0, 0, 0 }, { 0.4, 0, -0.2 }, { 0.4, 0, 0 } }
local CARRY_F = { { 0, 0, 0 }, { 0.4, 0, -0.2 }, { 0.6, 0, 0 } }
local CARRY_B = { { 0, 0, 0 }, { 0.2, 0, -0.2 }, { 0.5, 0, 0 } }
local STARTLE = { { 0, 0, 0 }, { 0.3, 0, 1.2 }, { 0.3, 0, 0 } }
-- ASLEEP: it sits on the ground, slumped forward, its legs out in front, its chin on its chest and its paws on
-- its belly (pairs: the right bone, the left bone, the right one's turn)
local SLEEP = {
	{ "000", -0.1, 0, 0 },
	{ "007", -0.2, 0, 0 },
	{ "005", -0.1, 0, 0 },
	{ "021", -0.4, 0, 0 },
	{ "020", -0.4, 0, 0 },
	{ "012", "017", 1.45, 0, 0.4 },
	{ "011", "016", 0.7, 0, 0 },
	{ "027", "032", 0.6, 0, -0.5 },
	{ "026", "031", 1.4, 0, 0 },
}
local SLEEP_BREATH = 0.035
local SLEEP_HZ = 0.22

-- A HIP IN THE AIR THAT DOES NOT SCISSOR. `BossKit.soften` lets a knee follow what the solver asks; the hip is the
-- joint that aims the leg and it is not softened there. At 30 studs a second a foot passes under a hip 3.7 studs up
-- in four frames and the thigh turns more than half a radian in one of them. Like the knee, a hip in the air follows
-- what its foot asks at `rate` and is exactly it again over the last quarter of the swing; what it is behind is
-- taken off the ankle, so that the sole keeps the pitch it is held at. A foot on the ground is left as solved.
local function softenHip(one, pose, memory, dt, rate)
	local rx = pose.rx
	local i = one.b[1]
	if one.mode == "down" then
		memory.hip = rx[i]
		return
	end
	local want = rx[i]
	local had = memory.hip or want
	had += (want - had) * (1 - math.exp(-rate * dt))
	memory.hip = had
	local got = had + (want - had) * smooth((one.s - 0.75) / 0.25)
	rx[i] = got
	rx[one.b[one.ankle]] += want - got
end

function Yeti.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Yeti.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local design = table.clone(DESIGN)
	design.turnArm = math.abs(legs[1].homeX)
	local W = Kit.walker(rig, design, legs, seed)
	local root = rig.root
	local inLeg = {}
	for _, one in legs do
		for _, i in one.b do
			inLeg[i] = true
		end
	end
	local free = {}
	for i = 1, rig.n do
		if not inLeg[i] then
			table.insert(free, i)
		end
	end
	local neck = Kit.chain(rig, "the neck")
	local chest = Kit.bone(rig, "005")
	local S = {
		pose = Kit.newPose(rig),
		walker = W,
		seed = seed,
		phase = 0,
		H = rig.height,
		root = root,
		pelvis = Kit.bone(rig, "001"),
		waist = Kit.bone(rig, "007"),
		chest = chest,
		neck = neck,
		head = Kit.bone(rig, "020"),
		toes = { Kit.bone(rig, "014"), Kit.bone(rig, "009") },
		knees = { {}, {} },
		lastLeg = {},
		need = 0,
		lastX = 0,
		lastZ = 0,
		armL = Boss.limb(rig, Yeti.map.limbs.armL.bones, true),
		armR = Boss.limb(rig, Yeti.map.limbs.armR.bones, false),
		free = free,
		hipBelow = rig.py[root] - (legs[1].hipY + legs[2].hipY) / 2,
		hipOut = math.abs(legs[1].hipX - legs[2].hipX) / 2,
		fk = Kit.newFk(rig),
		chestPath = Kit.path(rig, { chest }),
		neckPath = { neck[1] },
		sleepPose = Boss.posture(rig, SLEEP),
		ground = Boss.ground(rig, "Peaks"),
	}
	return Boss.mind(S, rig, MIND)
end

-- One arm: its keys by its mood, and between the forward and the backward one by its swing (-1 to 1).
local function arm(pose, limb, swing, calm, run, rage, carry, startle)
	local f = 0.5 + 0.5 * swing
	local b = 1 - f
	Boss.key(pose, limb, CALM_F, calm * f)
	Boss.key(pose, limb, CALM_B, calm * b)
	Boss.key(pose, limb, RUN_F, run * f)
	Boss.key(pose, limb, RUN_B, run * b)
	Boss.key(pose, limb, RAGE_F, rage * f)
	Boss.key(pose, limb, RAGE_B, rage * b)
	Boss.key(pose, limb, CARRY_F, carry * f)
	Boss.key(pose, limb, CARRY_B, carry * b)
	Boss.key(pose, limb, STARTLE, startle)
end

function Yeti.step(S, dt, input)
	Boss.think(S, dt, input)
	local W, pose = S.walker, S.pose
	local rig = W.rig
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local H = S.H
	local t = input.t
	Kit.zero(pose, S.free)

	-- THE FEET (the server sets it off at full speed: it is in its run at once)
	local vx, vz = 0, 0
	if dt > 0 and not input.jump then
		vx, vz = (input.x - S.lastX) / dt, (input.z - S.lastZ) / dt
	end
	S.lastX, S.lastZ = input.x, input.z
	Kit.gait(W, dt, input)
	Boss.launch(W, vx, vz)
	S.phase = W.phase
	local amount, g = W.amount, smooth(W.g)
	local fury, carry, sleep = smooth(S.rage), smooth(S.carry), S.sleep
	local mid = W.duty / 2
	local over = Boss.wave(W.phase, mid) -- 1 over the left foot, -1 over the right
	local load = cos(2 * TAU * (W.phase - mid)) -- 1 over the middle of either stance, -1 between two

	-- THE BODY (the bear's): down and up once for each foot, a tip and a shift over the foot that stands, hips that
	-- turn with the leg that reaches and a chest that turns back
	local running = -(CROUCH + DIP * 0.5 * (1 + load)) * H * amount * g
	local lean = -(LEAN.walk * amount + LEAN.run * g * amount + LEAN.rage * fury) * (1 - 0.6 * carry)
	local low = 0.45 * lean - NOD * g * amount * cos(2 * TAU * (W.phase - mid) - 0.5)
	rx[S.root] = low
	rx[S.waist] = 0.55 * lean + BREATH * (1 - amount) * sin(t * TAU * 0.25 + S.seed * TAU)
	local turning = (YAW.walk + (YAW.run - YAW.walk) * g) * amount
	local turn = -turning * Boss.wave(W.phase, 0)
	ry[S.pelvis] = turn
	ry[S.waist] = -SQUARE * turn
	local tipping = (ROLL.walk + (ROLL.run - ROLL.walk) * g) * amount
	local roll = tipping * over
	rz[S.root] = roll
	rz[S.chest] = -0.5 * roll
	pose.ox = -SWAY * H * amount * over * (1 - sleep)
	pose.oz = S.hipBelow * sin(low) * (1 - sleep)
	local need = Boss.reach(W, pose, S.hipOut * sin(turning), S.hipOut * sin(tipping * cos(TAU * mid)))
	S.need += (need - S.need) * Kit.follow(REACH, dt)
	pose.bob = Boss.under(running, S.need)
	Kit.solve(W, pose)
	for k, one in legs do
		Boss.soften(one, pose, S.knees[k], dt, KNEE)
		softenHip(one, pose, S.knees[k], dt, HIP)
		-- the toes stay flat on the ground while the heel rises
		local up = max(0, -one.sigma)
		if one.mode ~= "down" then
			up *= 1 - smooth(one.s * 2.5)
		end
		rx[S.toes[k]] = up
	end

	-- Bound the last few radians of recovery without changing the planted-foot solver.
	local limit = LEG_SLEW * dt
	for _, one in legs do
		for _, i in one.b do
			local was = S.lastLeg[i]
			if was and not input.jump and dt > 0 and dt < 0.4 then
				rx[i] = Kit.clamp(rx[i], was - limit, was + limit)
			end
			S.lastLeg[i] = rx[i]
		end
	end

	-- THE ARMS: they hang and swing against the legs when it is calm, pump when it runs, come up in front of it
	-- when it is furious, stay low and quiet under the egg it carries; the start of waking throws them out
	local swing = Kit.clamp(Boss.wave(W.phase - ARM_LAG, 0) * amount, -1, 1)
	local startle = 0.7 * S.rise
	local rest = 1 - startle
	local wCarry = carry * rest
	local wRage = fury * (1 - carry) * rest
	local wRun = smooth(S.run) * g * amount * (1 - fury) * (1 - carry) * rest
	local wCalm = rest - wCarry - wRage - wRun
	arm(pose, S.armR, swing, wCalm, wRun, wRage, wCarry, startle)
	arm(pose, S.armL, -swing, wCalm, wRun, wRage, wCarry, startle)

	-- THE HEAD: level, whatever the trunk does, and on what it looks at
	local yaw, pitch = S.yaw * S.lookW, S.pitch * S.lookW
	ry[S.chest] += CHEST_SHARE * yaw
	Kit.forward(rig, pose, S.chestPath, S.fk)
	local cx, cy, cz = Boss.turnOf(S.fk, S.chest)
	local base = S.neck[1]
	rx[base] = -0.5 * cx + NECK_SHARE * pitch
	ry[base] = -0.5 * (cy - CHEST_SHARE * yaw) + NECK_SHARE * yaw
	rz[base] = -0.5 * cz
	Kit.forward(rig, pose, S.neckPath, S.fk)
	Boss.hold(rig, pose, S.fk, S.head, pitch, yaw, 0)

	-- ASLEEP: all of it goes to the pose it sleeps in, and breathes
	if sleep > 0 then
		Boss.lie(pose, S.sleepPose, sleep)
		local breath = sleep * SLEEP_BREATH * sin(TAU * SLEEP_HZ * t + S.seed * TAU)
		rx[S.waist] += breath
		rx[S.neck[1]] -= 0.5 * breath
		rx[S.armL.bones[2]] += 0.6 * breath
		rx[S.armR.bones[2]] += 0.6 * breath
	end

	-- THE GROUND: asleep its seat lies on it; awake nothing of it is under it
	local pin = smooth(sleep / 0.04)
	Boss.settle(S.ground, pose, pin, HEELS + (BELLY - HEELS) * pin)
	local hop = S.rise * HOP * H
	pose.bob += hop
	S.headX, S.headY, S.headZ = Boss.place(S.ground.fk, S.head, 0, 0, 0)
	S.headY += hop
end

return Yeti
