-- The Magma Golem, the boss of the Ember Volcano (art/models/ready/boss_Volcano.glb, 48 bones): its joint map and
-- its own motion. It is Mama Bear's motion (boss_Woods) on another skeleton: a heavy biped of rocks on two short
-- legs that stand a little bent, a barrel of a chest, two arms that HANG (the bear's are held out to the sides)
-- and NO NECK: the head is one bone on the chest. What differs from her is only what the skeleton forces: which
-- bone is which, the head hung straight on the chest, the keys of the arms (they hang, so a swing is a turn about
-- x), the sleeping pose's rows, and the foot's height off the ground. docs/motion/boss_Volcano.md says what and
-- why; look at art/models/rigs/boss_Volcano_left.png and _front.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")
local Boss = if script then require(script.Parent.Parent.BossKit) else require("../BossKit")

local sin, cos, max, pi = math.sin, math.cos, math.max, math.pi
local TAU = pi * 2
local smooth = Kit.smooth

local Golem = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "015" is Bone_015)
Golem.map = {
	prefix = "Bone_",
	count = 48,
	tree = 719676241,
	-- 000 the root (drives nothing); 001 the pelvis (both legs and the belly hang on it); 003 the belly and
	-- waist; 002 the chest (both arms and the head hang on it)
	root = "000",
	spine = { "000", "001", "003", "002" },
	-- 015 the head: the face (014) hangs on it. There is no neck.
	head = { "015" },
	limbs = {
		-- a leg, from the body down: HIP, KNEE (points forward: it folds the shank back and up), ANKLE (the foot's
		-- big rock hangs on it), the BALL of the foot, the tip of the toes
		L = { role = "leg", bones = { "008", "007", "006", "005", "004" } },
		R = { role = "leg", bones = { "013", "012", "011", "010", "009" } },
		-- an arm, hanging at the side: SHOULDER, ELBOW, WRIST (drives nothing much), the FIST (four chains of
		-- fingers hang on it)
		armL = { role = "arm", bones = { "023", "022", "021", "020" } },
		armR = { role = "arm", bones = { "019", "018", "017", "016" } },
	},
	-- (no pairs: the legs and the hands stand 0.04 to 0.05 of the height apart front to back, which the map's check
	-- of a mirror does not allow)
	-- rigid with what they hang on: the face (014) and the fingers of both fists
	rigid = { "014", "026", "029", "032", "035", "038", "041", "044", "047" },
}

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians the knee turns for one radian of fold, + tips the joint's lower end forward)
local function leg(id, name, chain, centre)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 3,
		centre = centre,
		-- the point that stays planted is the BALL of the foot on the ground: the heel lifts about it before the
		-- foot leaves, and what the hips turn while it stands, the foot turns about it
		contact = chain[4],
		tip = { below = 0.0654, ahead = 0 },
		front = 0.54,
		-- one joint folds, the knee: in the air and under its weight
		fold = { swing = { 0, -1 }, stance = { 0, -1 } },
		open = 0.1,
		lift = { walk = 0.1, trot = 0.22 },
		-- the sole: flat, the heel up before it leaves, level again as it passes under, flat to land
		pitch = { stance = { 0, 0, 0.55, 0, 1, -0.6 }, swing = { 0, -0.6, 0.3, -0.3, 0.6, 0.08, 1, 0 } },
	}
end

Golem.legs = {
	leg("L", "left leg", Golem.map.limbs.L.bones, 0),
	-- (the right foot stands 0.04 of the height further back than the left: its stance is centred where the left
	-- one's is, or at a run it never stretches the knee and the right leg runs bent)
	leg("R", "right leg", Golem.map.limbs.R.bones, -0.039),
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
	-- (since 2026-10-14 it runs at 44 to 63 studs a second: a foot is down 0.22 of a stride and the stride is 2.2
	-- of its height, 1.8 to 2.6 strides a second)
	trot = {
		offsets = { 0, 0.5 },
		duty = { at = 0.372, slope = 0.165, ref = 1.52, least = 0.22, most = 0.5 },
		stride = { 3.6, 0.3 },
		sweep = 1.46,
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
local KNEE = 28
local HIP = 20 -- how fast a hip in the air follows what its foot asks (1/s): the Golem runs at 3 heights a second
local ANKLE = 40 -- and its ankle
-- (the speeds of 2026-10-14, 55 studs a second chasing: `BossKit.surge` and `BossKit.swing`)
local SURGE = 0.05 -- the share of a stride the body surges by: about a third slower while a foot stands
local BODY_SWING = 0.3 -- the share of a swing eased as the body sees it
local LAND_TIME = 0.18 -- seconds after a foot comes down in which its knee and ankle are rate-limited
local LAND_SPEED = 14 -- the most they turn in a second at first (rad/s: 0.23 in a frame)
local REACH = 40
local BREATH = 0.006
local ARM_LAG = 0.08
local HOP = 0.008
local BELLY = 0.012
local HEELS = 0.03

-- WHERE IT LOOKS: at its thief, at the hub
local MIND = { settle = 2.4, head = "015", look = { yaw = 1.1, up = 0.35, down = 0.5 } }
local CHEST_SHARE = 0.2

-- THE ARMS: keys for the RIGHT arm (shoulder, elbow), the left one mirrors them. The arm HANGS: a turn of the
-- shoulder about x swings it forward (+) or back (-), the elbow folds the forearm forward (+) about x, and a turn
-- about z takes it out (+) or in (-). The keys are the bear's moods on a hanging arm (the Yeti's, one bone nearer
-- the chest).
local CALM_F = { { 0.3, 0, 0 }, { 0.25, 0, 0 } }
local CALM_B = { { -0.35, 0, 0 }, { 0.1, 0, 0 } }
local RUN_F = { { 1.0, 0, -0.1 }, { 1.3, 0, 0 } }
local RUN_B = { { -0.7, 0, 0 }, { 1.0, 0, 0 } }
local RAGE_F = { { 1.4, 0, -0.6 }, { 0.9, 0, 0 } }
local RAGE_B = { { 0.4, 0, -0.2 }, { 0.4, 0, 0 } }
local CARRY_F = { { 0.4, 0, -0.2 }, { 0.6, 0, 0 } }
local CARRY_B = { { 0.2, 0, -0.2 }, { 0.5, 0, 0 } }
local STARTLE = { { 0.3, 0, 1.2 }, { 0.3, 0, 0 } }
-- ASLEEP: it sits on the ground, slumped forward, its legs out in front, its chin on its chest and its fists on
-- its belly (pairs: the right bone, the left bone, the right one's turn)
local SLEEP = {
	{ "000", -0.1, 0, 0 },
	{ "003", -0.2, 0, 0 },
	{ "002", -0.1, 0, 0 },
	{ "015", -0.6, 0, 0 },
	{ "013", "008", 1.45, 0, 0.4 },
	{ "012", "007", 0.35, 0, 0 },
	{ "019", "023", 0.6, 0, -0.5 },
	{ "018", "022", 1.4, 0, 0 },
}
local SLEEP_BREATH = 0.035
local SLEEP_HZ = 0.22

-- A HIP IN THE AIR THAT DOES NOT SCISSOR. `BossKit.soften` lets a knee follow what the solver asks; the hip is the
-- joint that aims the leg and it is not softened there. At 36 studs a second a foot passes under a hip 3.6 studs up
-- in four frames and the thigh turns more than half a radian in one of them. Like the knee, a hip in the air follows
-- what its foot asks at `rate` and is exactly it again over the last quarter of the swing; what it is behind is
-- taken off the ankle, so that the sole keeps the pitch it is held at. A foot on the ground is left as solved.
local function softenHip(one, pose, memory, dt, rate)
	local rx = pose.rx
	local i = one.b[1]
	if one.mode == "down" then
		memory.hip = rx[i]
		memory.ankle = rx[one.b[one.ankle]]
		return
	end
	local want = rx[i]
	local had = memory.hip or want
	had += (want - had) * (1 - math.exp(-rate * dt))
	memory.hip = had
	local exact = smooth((one.s - 0.75) / 0.25)
	local got = had + (want - had) * exact
	rx[i] = got
	rx[one.b[one.ankle]] += want - got
	-- (and the ankle, which takes up what the hip and the knee are behind, follows too: its sole is a little off its
	-- pitch while the foot is in the air, exact again as it lands)
	local a = one.b[one.ankle]
	local wantA = rx[a]
	local hadA = memory.ankle or wantA
	hadA += (wantA - hadA) * (1 - math.exp(-ANKLE * dt))
	memory.ankle = hadA
	rx[a] = hadA + (wantA - hadA) * exact
end

-- A LANDING THAT DOES NOT SNAP. The kit solves a foot that has just come down as a leg that gives under the whole
-- weight of the body: the knee folds and the ankle turns half a radian in the one frame after the swing ends (a run
-- of 40 studs a second). For `LAND_TIME` seconds after a foot comes down the knee and the ankle turn no faster
-- than `LAND_SPEED` (rad/s, and more and more as the time goes): the foot is a little off the place it lands on
-- for two or three frames, and then it is exactly where the solver puts it.
local function landing(one, pose, memory, dt)
	local rx, b = pose.rx, one.b
	local last = memory.last
	if not last then
		last = { rx[b[1]], rx[b[2]], rx[b[3]] }
		memory.last, memory.down = last, LAND_TIME
	end
	if one.mode == "down" then
		memory.down += dt
		if memory.down < LAND_TIME then
			-- (the limit eases off, so that a joint that fell behind is not let go in a jump)
			local most = LAND_SPEED * dt * (1 + 3 * memory.down / LAND_TIME)
			for j = 2, 3 do
				local i = b[j]
				rx[i] = last[j] + Kit.clamp(rx[i] - last[j], -most, most)
			end
		end
	else
		memory.down = 0
	end
	for j = 1, 3 do
		last[j] = rx[b[j]]
	end
end

function Golem.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Golem.legs do
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
	local chest = Kit.bone(rig, "002")
	local S = {
		pose = Kit.newPose(rig),
		walker = W,
		seed = seed,
		phase = 0,
		H = rig.height,
		root = root,
		pelvis = Kit.bone(rig, "001"),
		waist = Kit.bone(rig, "003"),
		chest = chest,
		head = Kit.bone(rig, "015"),
		toes = { Kit.bone(rig, "005"), Kit.bone(rig, "010") },
		knees = { {}, {} },
		swing = { {}, {} },
		need = 0,
		lastX = 0,
		lastZ = 0,
		armL = Boss.limb(rig, Golem.map.limbs.armL.bones, true),
		armR = Boss.limb(rig, Golem.map.limbs.armR.bones, false),
		free = free,
		hipBelow = rig.py[root] - (legs[1].hipY + legs[2].hipY) / 2,
		hipOut = math.abs(legs[1].hipX - legs[2].hipX) / 2,
		fk = Kit.newFk(rig),
		chestPath = Kit.path(rig, { chest }),
		sleepPose = Boss.posture(rig, SLEEP),
		ground = Boss.ground(rig, "Volcano"),
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

function Golem.step(S, dt, input)
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
	-- (at 55 to 63 studs a second it surges: slower while a foot stands, quicker in the flight; see BossKit)
	local oz, landOz = Boss.surge(W, SURGE)
	oz, landOz = oz * (1 - sleep), landOz * (1 - sleep)
	pose.oz = S.hipBelow * sin(low) * (1 - sleep) + oz
	local need = Boss.reach(W, pose, S.hipOut * sin(turning) - landOz, S.hipOut * sin(tipping * cos(TAU * mid)))
	S.need += (need - S.need) * Kit.follow(REACH, dt)
	pose.bob = Boss.under(running, S.need)
	Boss.swing(W, S.swing, oz, landOz, BODY_SWING, dt)
	Kit.solve(W, pose)
	for k, one in legs do
		Boss.soften(one, pose, S.knees[k], dt, KNEE)
		softenHip(one, pose, S.knees[k], dt, HIP)
		landing(one, pose, S.knees[k], dt)
		-- the toes stay flat on the ground while the heel rises
		local up = max(0, -one.sigma)
		if one.mode ~= "down" then
			up *= 1 - smooth(one.s * 2.5)
		end
		rx[S.toes[k]] = up
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

	-- THE HEAD: level, whatever the trunk does, and on what it looks at. It hangs straight on the chest (no neck),
	-- which takes a share of a look.
	local yaw, pitch = S.yaw * S.lookW, S.pitch * S.lookW
	ry[S.chest] += CHEST_SHARE * yaw
	Kit.forward(rig, pose, S.chestPath, S.fk)
	Boss.hold(rig, pose, S.fk, S.head, pitch, yaw, 0)

	-- ASLEEP: all of it goes to the pose it sleeps in, and breathes
	if sleep > 0 then
		Boss.lie(pose, S.sleepPose, sleep)
		local breath = sleep * SLEEP_BREATH * sin(TAU * SLEEP_HZ * t + S.seed * TAU)
		rx[S.waist] += breath
		rx[S.chest] -= 0.5 * breath
		rx[S.armL.bones[1]] += 0.6 * breath
		rx[S.armR.bones[1]] += 0.6 * breath
	end

	-- THE GROUND: asleep its seat lies on it; awake nothing of it is under it
	local pin = smooth(sleep / 0.04)
	Boss.settle(S.ground, pose, pin, HEELS + (BELLY - HEELS) * pin)
	local hop = S.rise * HOP * H
	pose.bob += hop
	S.headX, S.headY, S.headZ = Boss.place(S.ground.fk, S.head, 0, 0, 0)
	S.headY += hop
end

return Golem
