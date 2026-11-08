-- Mama Bear, the boss of the Woods (art/models/ready/boss_Woods.glb, 48 bones): her joint map and her own
-- motion. A bear built STANDING UP: a barrel of a body on two very short legs, two thick arms held out to the
-- sides at rest, a short neck, a stub of a tail. docs/MOTION.md sections 1 to 3, 8 (the bear) and 10 (heavy
-- bipeds) are what she is designed from, docs/motion/boss_Woods.md what was learned on her. Look at
-- art/models/rigs/boss_Woods_left.png and _front.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")
local Boss = if script then require(script.Parent.Parent.BossKit) else require("../BossKit")

local sin, cos, max, pi = math.sin, math.cos, math.max, math.pi
local TAU = pi * 2
local smooth = Kit.smooth

local Bear = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "022" is Bone_022)
Bear.map = {
	prefix = "Bone_",
	count = 48,
	tree = 613416118,
	-- 000 is the middle of the barrel; 001 the pelvis and the belly (both legs, the tail and everything above
	-- hang on it); 005 the waist, where the chest starts (it drives nothing itself); 004 the chest (both
	-- shoulders and the neck hang on it)
	root = "000",
	spine = { "000", "001", "005", "004" },
	-- 018 the base of the neck (it drives the top of the chest), 017 its top (drives nothing)
	neck = { "018", "017" },
	-- 016 the skull: the muzzle and the ears hang on it
	head = { "016" },
	limbs = {
		-- a leg, from the body down: HIP (the thigh hangs straight down in the flank), KNEE (points forward: it
		-- folds the shank back and up; it stands 33 degrees bent), ANKLE (the heel: the foot lies flat on the
		-- ground from here forward, a bear walks on its whole sole), the BALL of the foot (where the toes bend),
		-- the tip of the toes. (Her hip is only 0.19 of her height up, under the map's own measure of a leg,
		-- which wants 0.2: so the legs are written here, as limbs that are legs.)
		L = { role = "leg", bones = { "010", "009", "008", "007", "006" } },
		R = { role = "leg", bones = { "015", "014", "013", "012", "011" } },
		-- an arm, held straight out to the side at rest: SHOULDER, ELBOW (it folds the forearm forward when the
		-- arm is out, forward and up when it hangs), WRIST (drives nothing), the PAW (three chains of claws
		-- hang on it)
		armL = { role = "arm", bones = { "026", "025", "024", "023" } },
		armR = { role = "arm", bones = { "022", "021", "020", "019" } },
	},
	pairs = { { "L", "R" }, { "armL", "armR" } },
	-- rigid with what they hang on: the stub of a tail (003: six vertices), the muzzle (029), the ears (032,
	-- 035: the flower sits behind the left one), the claws of both paws (037, 039, 041 and 043, 045, 047)
	rigid = { "003", "029", "032", "035", "037", "039", "041", "043", "045", "047" },
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
		-- foot leaves, and what the hips turn while she stands on it, the foot turns about it
		contact = chain[4],
		tip = { below = 0.0296, ahead = 0 },
		front = 0.54,
		-- one joint folds, the knee: in the air and under her weight
		fold = { swing = { 0, -1 }, stance = { 0, -1 } },
		-- (the leg stands bent, and reaches by the body coming down, hardly by opening: a knee that opens to land
		-- shuts again in the next frame, which is a tick at every step)
		open = 0.1,
		lift = { walk = 0.1, trot = 0.22 },
		-- the sole: flat, the heel up before it leaves, level again as it passes under her, flat to land
		pitch = { stance = { 0, 0, 0.55, 0, 1, -0.6 }, swing = { 0, -0.6, 0.3, -0.3, 0.6, 0.08, 1, 0 } },
	}
end

Bear.legs = {
	leg("L", "left leg", Bear.map.limbs.L.bones),
	leg("R", "right leg", Bear.map.limbs.R.bones),
}

-- THE GAITS (the legs in the order above: left, right) ------------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- a walk: one foot, then the other, each down well over half of the stride
	walk = {
		offsets = { 0, 0.5 },
		duty = { at = 0.62, slope = 0.04, ref = 0.2, least = 0.56, most = 0.68 },
		stride = { 2.3, 0.3 },
	},
	-- a run: her legs are a fifth of her height, so at the speed the server moves her she is always far past
	-- the speed a biped walks at. The step is as long as legs and hips can make it (`sweep`), the cadence
	-- stays, and more speed is a longer flight between two feet.
	trot = {
		offsets = { 0, 0.5 },
		duty = { at = 0.372, slope = 0.165, ref = 1.52, least = 0.24, most = 0.5 },
		stride = { 3.6, 0.3 },
		sweep = 1.38,
		from = 0.62,
		back = 0.48,
		shift = 0.4,
	},
	sweep = 1.0,
	-- (a run that is stopped short is finished quickly: the foot in the air comes down at once)
	finish = 0.5,
	settle = { far = 0.2, time = 1.6, least = 2, mean = 5, most = 14 },
	comfy = 0.99,
	letGo = 0.6,
	comeDown = 0.4,
}

-- THE BODY --------------------------------------------------------------------------------------------------
-- (shares of her height unless they are radians)
local CROUCH = 0.004 -- how far under her standing height she rides when she runs
local DIP = 0.014 -- how far she sinks into the leg that carries her, running
local SWAY = 0.012 -- how far she shifts over the foot that stands
local ROLL = { walk = 0.07, run = 0.05 } -- radians she tips over the foot that stands
local YAW = { walk = 0.08, run = 0.2 } -- radians her hips turn with the leg that reaches
local SQUARE = 0.85 -- the share of that turn her chest turns back
local LEAN = { walk = 0.04, run = 0.1, rage = 0.22 } -- radians she leans into it
local NOD = 0.02 -- radians her trunk dips as her weight comes down, twice a stride
local KNEE = 22 -- how fast a knee in the air follows what its foot asks (1/s)
local HIP = 16 -- swing hip follows its target, as on the Yeti
local LEG_SLEW = 23.4 -- radians/s; a bounded final recovery at faster run speeds
local REACH = 30 -- how fast her rise follows what her legs can reach (1/s)
local BREATH = 0.006 -- radians, standing
local ARM_LAG = 0.08 -- of a stride: her arms are heavy and late
local HOP = 0.008 -- the start of waking lifts her off her seat for a moment
local BELLY = 0.012 -- the share of her height her seat lies under the ground, asleep
-- (awake: the skin of her heels hangs on her shanks and thighs, and goes this far under the ground when a leg
-- reaches or folds deep; only more than that lifts her)
local HEELS = 0.03

-- WHERE SHE LOOKS: at her thief, at the hub
local MIND = { settle = 2.4, head = "016", look = { yaw = 1.1, up = 0.35, down = 0.5 } }
local NECK_SHARE = 0.3 -- of a look: the base of the neck; the skull is held exactly
local CHEST_SHARE = 0.2 -- ... and her chest turns a little with it

-- THE ARMS: keys for the RIGHT arm (shoulder, elbow, wrist, paw), the left one mirrors them. An arm that
-- hangs is { swing forward, 0, how far it is lowered from straight out }; the elbow folds about y.
local CALM_F = { { 0.1, 0, -1.13 }, { 0, 0.6, 0 } }
local CALM_B = { { -0.45, 0, -1.13 }, { 0, 0.35, 0 } }
local RUN_F = { { 0.55, 0, -1.1 }, { 0, 1.3, 0 } }
local RUN_B = { { -0.55, 0, -1.05 }, { 0, 1.1, 0 } }
local RAGE_F = { { 1.02, 0, -0.85 }, { 0, 1.6, 0 } }
local RAGE_B = { { -0.5, 0, -0.8 }, { 0, 0.95, 0 } }
local CARRY_F = { { 0.12, 0, -1.0 }, { 0, 0.95, 0 } }
local CARRY_B = { { -0.12, 0, -1.0 }, { 0, 0.85, 0 } }
local STARTLE = { { 0.5, 0, -0.25 }, { 0, 1.2, 0 } }
-- ASLEEP: she sits on the ground, slumped forward, her legs out in front, her chin on her chest and her paws
-- on her belly (pairs: the right bone, the left bone, the right one's turn)
local SLEEP = {
	{ "000", -0.1, 0, 0 },
	{ "005", -0.2, 0, 0 },
	{ "004", -0.1, 0, 0 },
	{ "018", -0.4, 0, 0 },
	{ "017", -0.15, 0, 0 },
	{ "016", -0.4, 0, 0 },
	{ "015", "010", 1.45, 0, 0.4 },
	{ "014", "009", 0.35, 0, 0 },
	{ "022", "026", -0.22, 0.73, -0.83 },
	{ "021", "025", 0, 0.9, 0 },
}
local SLEEP_BREATH = 0.035 -- radians her chest rises and falls
local SLEEP_HZ = 0.22 -- a breath in four and a half seconds

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

function Bear.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Bear.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	-- (her own copy of the design: the feet stand two studs to the sides of her middle, which is what a turn
	-- on the spot moves them by)
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
	local chest = Kit.bone(rig, "004")
	local S = {
		pose = Kit.newPose(rig),
		walker = W,
		seed = seed,
		phase = 0,
		H = rig.height,
		root = root,
		pelvis = Kit.bone(rig, "001"),
		waist = Kit.bone(rig, "005"),
		chest = chest,
		neck = neck,
		head = Kit.bone(rig, "016"),
		toes = { Kit.bone(rig, "007"), Kit.bone(rig, "012") },
		knees = { {}, {} },
		lastLeg = {},
		need = 0,
		lastX = 0,
		lastZ = 0,
		armL = Boss.limb(rig, Bear.map.limbs.armL.bones, true),
		armR = Boss.limb(rig, Bear.map.limbs.armR.bones, false),
		free = free,
		hipBelow = rig.py[root] - (legs[1].hipY + legs[2].hipY) / 2,
		hipOut = math.abs(legs[1].hipX - legs[2].hipX) / 2,
		fk = Kit.newFk(rig),
		chestPath = Kit.path(rig, { chest }),
		neckPath = { neck[1], neck[2] },
		sleepPose = Boss.posture(rig, SLEEP),
		ground = Boss.ground(rig, "Woods"),
	}
	return Boss.mind(S, rig, MIND)
end

-- One arm: its keys by her mood, and between the forward and the backward one by its swing (-1 to 1).
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

function Bear.step(S, dt, input)
	Boss.think(S, dt, input)
	local W, pose = S.walker, S.pose
	local rig = W.rig
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local H = S.H
	local t = input.t
	Kit.zero(pose, S.free)

	-- THE FEET (the server sets her off at full speed: she is in her run at once)
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
	-- (the stride begins as the left foot lands; `mid` is the moment that foot is in the middle of its stance)
	local mid = W.duty / 2
	local over = Boss.wave(W.phase, mid) -- 1 over the left foot, -1 over the right
	local load = cos(2 * TAU * (W.phase - mid)) -- 1 over the middle of either stance, -1 between two

	-- THE BODY. Walking it is carried by its legs (highest over the foot that stands); running it sinks into
	-- the leg that lands and flies between two: once down and up for each foot, with no corner in it.
	local running = -(CROUCH + DIP * 0.5 * (1 + load)) * H * amount * g
	local lean = -(LEAN.walk * amount + LEAN.run * g * amount + LEAN.rage * fury) * (1 - 0.6 * carry)
	local low = 0.45 * lean - NOD * g * amount * cos(2 * TAU * (W.phase - mid) - 0.5)
	rx[S.root] = low
	rx[S.waist] = 0.55 * lean + BREATH * (1 - amount) * sin(t * TAU * 0.25 + S.seed * TAU)
	-- her hips turn with the leg that reaches (the left hip is forward as the left foot lands), and her chest
	-- turns back, so that her shoulders stay nearly square
	local turning = (YAW.walk + (YAW.run - YAW.walk) * g) * amount
	local turn = -turning * Boss.wave(W.phase, 0)
	ry[S.pelvis] = turn
	ry[S.waist] = -SQUARE * turn
	-- she tips and shifts over the foot that stands: the waddle
	local tipping = (ROLL.walk + (ROLL.run - ROLL.walk) * g) * amount
	local roll = tipping * over
	rz[S.root] = roll
	rz[S.chest] = -0.5 * roll
	pose.ox = -SWAY * H * amount * over * (1 - sleep)
	-- (leaning from the middle of the barrel would carry the hips back: they stay over the feet)
	pose.oz = S.hipBelow * sin(low) * (1 - sleep)
	-- (and never higher than her legs reach, with her hips turned as they are: as a foot lands its hip is turned
	-- forward, and tipped down by what the trunk tips at that moment. What the legs ask comes in over a frame or
	-- two, so that a foot that lands makes no corner in her rise)
	local need = Boss.reach(W, pose, S.hipOut * sin(turning), S.hipOut * sin(tipping * cos(TAU * mid)))
	S.need += (need - S.need) * Kit.follow(REACH, dt)
	pose.bob = Boss.under(running, S.need)
	Kit.solve(W, pose)
	for k, one in legs do
		-- (a knee in the air folds and opens at the speed of a knee, however fast the foot is carried past her hip)
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

	-- THE ARMS: they hang and swing against the legs when she is calm, pump when she runs, come up in front of
	-- her when she is furious, stay low and quiet under the egg she carries; the start of waking throws them out
	local swing = Kit.clamp(Boss.wave(W.phase - ARM_LAG, 0) * amount, -1, 1)
	local startle = 0.7 * S.rise
	local rest = 1 - startle
	local wCarry = carry * rest
	local wRage = fury * (1 - carry) * rest
	local wRun = smooth(S.run) * g * amount * (1 - fury) * (1 - carry) * rest
	local wCalm = rest - wCarry - wRage - wRun
	arm(pose, S.armR, swing, wCalm, wRun, wRage, wCarry, startle)
	arm(pose, S.armL, -swing, wCalm, wRun, wRage, wCarry, startle)

	-- THE HEAD: level, whatever the trunk does, and on what she looks at
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

	-- ASLEEP: all of her goes to the pose she sleeps in, and breathes
	if sleep > 0 then
		Boss.lie(pose, S.sleepPose, sleep)
		local breath = sleep * SLEEP_BREATH * sin(TAU * SLEEP_HZ * t + S.seed * TAU)
		rx[S.waist] += breath
		rx[S.neck[1]] -= 0.5 * breath
		rx[S.armL.bones[1]] += 0.6 * breath
		rx[S.armR.bones[1]] += 0.6 * breath
	end

	-- THE GROUND: asleep her seat lies on it; awake nothing of her is under it
	-- (while she gets up she stays on it: first her seat, then her heels, carry her)
	local pin = smooth(sleep / 0.04)
	Boss.settle(S.ground, pose, pin, HEELS + (BELLY - HEELS) * pin)
	local hop = S.rise * HOP * H
	pose.bob += hop
	S.headX, S.headY, S.headZ = Boss.place(S.ground.fk, S.head, 0, 0, 0)
	S.headY += hop
end

return Bear
