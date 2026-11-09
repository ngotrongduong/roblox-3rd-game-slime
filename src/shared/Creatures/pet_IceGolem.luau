-- The Ice Golem (art/models/ready/pet_IceGolem.glb, 14 bones, built and skinned for it: see
-- docs/motion/pet_IceGolem.md): its joint map, and the MOTION OF THE TOTEM GOLEM (pet_TotemGolem.luau: the
-- finished heavy biped of rigid blocks with the same names and tree, legs that stand straight and slant out,
-- long flat feet, a pelvis that tips) on it, changed only where this body is another. A hulking golem of ice
-- blocks: short legs wide apart on feet as long as it is deep, a small pelvis, a narrow waist, a barrel chest
-- whose shoulders carry two towers of crystal as high as the head, an arm that is a stub and a boulder, a
-- small head with a crown of blades. Look at art/models/rigs/pet_IceGolem_front.png and
-- art/models/poses/pet_IceGolem_pose_step.png beside this file.
--
-- What this body changes of the Totem Golem's motion:
--   * THE ARM IS TWO JOINTS: a shoulder under the pauldron and an elbow that holds forearm and fist as one
--     boulder. There is no wrist (the Totem Golem's is in its map and is never turned): the arm's swing, the
--     forearm that is late, the sag at a landing and the bend of the run are on the same two joints as there
--   * THE LEG HAS A REAL THIGH (0.133 of the height against a shin of 0.159; the Totem Golem's is 0.060 of
--     0.225): its knee buys length as a knee does. The numbers that were set on a rod are set on this leg:
--     how short of straight it stands (`comfy`) and how much shorter a leg in the air is carried (`FOLD`), each
--     for the SAME ANGLE of knee as the Totem Golem's (12 degrees standing, 30 in the air). The body carried on
--     each hip (`room`) and the pelvis that tips are as they were: the leg still stands straight and slants out
--   * the knee stands a hair SHORT of straight in this model (5 degrees, the right way), so nothing has to be
--     told to the kit about a knee past straight
--   * THE FOOT: the ankle is over the MIDDLE of a foot 0.33 long (the Totem Golem's over the back third of one
--     0.19 long): the front edge it leaves over is 0.24 of the rig's height in front of the ankle
--   * the head has a short neck and stands free of the towers: its looks are a little wider (17 degrees against
--     14) and its bounds this body's own (20 round and nodding, 12 tilted)
--   * each pauldron with its tower of crystal RIDES ON ITS UPPER ARM (the owner's decision, 2026-10-13), as the
--     Totem Golem's shoulder plates: a tower rocks as its arm swings. A shoulder is clean to 20 degrees of swing
--     (the mass is one with the chest) and 10 out (the tower meets the crown): the run's swing is 0.34, not 0.4
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Golem = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the skeleton's top joint is the neck, at 0.72 of the golem's height: head and crown stand over it. "The
-- rig's height" below is that 0.72; "its leg" is the hip's height, 0.39 of the golem's)
Golem.map = {
	count = 14,
	tree = 1453464320,
	-- Root is the handle, in the pelvis: it drives nothing. Body_01, at the same place, is the HIPS (the pelvis
	-- block; the legs and the waist hang on it). Body_02's joint is the WAIST: it holds the chest between
	-- the pauldrons, and carries both arms and the head
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- one joint in the short neck: the face, the chin and the crown of blades are one block on it
	head = { "Head" },
	limbs = {
		-- a leg, from the body down: HIP (inside the pelvis: aims the leg), KNEE (folds the shin block back and
		-- up, never the other way), ANKLE (the foot: one block, flat on the ground). They are legs, and are
		-- listed here because the map calls a chain a leg only when it ends under 12% of the rig's height: the
		-- ankle is at 14.6% of it (the rig ends at the neck).
		LL = { role = "leg", bones = { "Leg_L_01", "Leg_L_02", "Leg_L_03" } },
		RL = { role = "leg", bones = { "Leg_R_01", "Leg_R_02", "Leg_R_03" } },
		-- an arm, from the body down: SHOULDER (under the pauldron: it holds the pauldron and
		-- its tower of crystal, one rigid piece), ELBOW (the boulder: forearm and fist in one). No wrist: the boulder has no neck
		LA = { role = "arm", bones = { "Arm_L_01", "Arm_L_02" } },
		RA = { role = "arm", bones = { "Arm_R_01", "Arm_R_02" } },
	},
	-- (the skeleton is mirrored exactly, the mesh to a hair)
	pairs = { { "LL", "RL" }, { "LA", "RA" } },
	rigid = {},
}

-- HOW IT STROLLS in its plot: slowly (the Totem Golem's Froude number: a sixth of its height a second on this
-- longer leg), and it stands a long while. (Its leg is 0.39 of its height, 0.542 of the rig's.)
Golem.stroll = { froude = 0.015, leg = 0.542, rest = { 6, 16 }, radius = 1.1 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward)
local SOLE_DOWN = 0.146 -- of the rig's height: the ground under the ankle bone (0.105 of the golem's) ...
-- ... and how far in front of it the front edge of the sole is (0.173 of the golem's: the sole ends 0.18 in
-- front of the ankle, measured on the mesh at the height of the ground; a hair inside that edge)
local TOE_AHEAD = 0.24
local HEEL_UP = 0.16 -- radians the heel is up as the foot leaves the ground (the ankle is clean to 20 degrees)
local LIFT, LIFT_RUN = 0.075, 0.07 -- of its leg: how high the ankle swings

local function leg(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 3,
		-- (it lands a third of its step in front of where it stands and leaves two thirds behind: the hip is
		-- let down to the foot that lands, the foot that leaves has its heel to rise on)
		front = 0.365,
		-- THE POINT THAT IS PLANTED IS THE FRONT EDGE OF THE SOLE, as the Totem Golem's: the leg that trails has
		-- its HEEL RISE over the last third of its stance, the foot turning about its front edge, and leaves the
		-- ground from there. It lands FLAT (the kit lands every foot flat): turned about its front edge a toe
		-- that is up is a heel in the ground.
		contact = chain[3],
		tip = { below = SOLE_DOWN, ahead = TOE_AHEAD },
		-- the knee is its one fold, and it folds one way: the shin back (the other way the knee's crystal is in
		-- the thigh). It stands straight, so nothing opens
		fold = { swing = { 0, -1.0 }, stance = { 0, -1.0 } },
		sink = 0,
		-- (a foot of ice on a short leg: a thirteenth of the leg, and the pelvis carries it)
		lift = { walk = LIFT, trot = LIFT_RUN },
		-- the foot against the ground: flat for two thirds of its stance, then the heel comes up; in the air it
		-- comes level again and lands flat. (It hangs heel up through the first third of its swing, where the
		-- Totem Golem's is already coming level: the knee folds there with the thigh still behind, and a foot
		-- brought level under that shin is bent 21 degrees at an ankle whose crystals meet the shin from 20.)
		pitch = {
			stance = { 0, 0, 0.62, 0, 1, -HEEL_UP },
			swing = { 0, -HEEL_UP, 0.3, -HEEL_UP, 0.75, 0, 1, 0 },
		},
	}
end

Golem.legs = {
	leg("LL", "left leg", Golem.map.limbs.LL.bones),
	leg("RL", "right leg", Golem.map.limbs.RL.bones),
}

-- THE GAITS (the legs in the order above: left, right) ------------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- a walk: short steps, two thirds of the stride on the ground, both feet down for a sixth of it after
	-- each landing
	walk = {
		offsets = { 0, 0.5 },
		duty = { at = 0.66, slope = 0.03, ref = 0.05, least = 0.6, most = 0.68 },
		-- (the Totem Golem's stride, in legs: the hip turns the same angles for it)
		stride = { 2.1, 0.3 },
	},
	-- a run (the kit calls its second gait a trot): the same order, half the stride on the ground, a flight
	-- that is barely one
	trot = {
		offsets = { 0, 0.5 },
		duty = { at = 0.46, slope = 0.05, ref = 1, least = 0.4, most = 0.5 },
		stride = { 2.3, 0.3 },
		-- (the Totem Golem's reach: a hip that turns 30 degrees and no more)
		sweep = 0.3,
		from = 0.5,
		back = 0.4,
		shift = 0.6,
	},
	sweep = 0.46,
	finish = 0.25,
	settle = { far = 0.16, time = 2.0, least = 2, mean = 6, most = 16 },
	-- A HAIR SHORT OF STRAIGHT (the kit has no number of its own for this: it must be given). A straight leg
	-- gets no shorter for the first degrees of its knee: at its full length a hair of the body's height is ten
	-- degrees of knee in one frame. At 0.995 of it this knee stands 12 degrees bent, the bend the Totem Golem
	-- stands with (whose rod of a leg needs 0.997 for it), and is past that corner.
	comfy = 0.995,
	letGo = 0.55,
	comeDown = 0.45,
}

-- THE BODY, THE ARMS, THE HEAD ------------------------------------------------------------------------------
-- (of its leg: how much shorter than it reaches a leg is carried in the air. 30 degrees of knee, as the Totem
-- Golem's: on this leg, whose thigh is nearly half of it, that is 0.022 of the leg and not 0.013)
local FOLD = 0.022
local FOLD_RUN = 0.017 -- ... and when it runs (no more: the hip that is let down to the landing foot folds it besides)
local RUN_DIP = 0.006 -- of its leg: how far the body sinks over the leg it runs on
local SWAY = 0.07 -- of its leg: how far the body goes over the foot that stands
local TIP, TIP_MOST = 0.16, 0.26 -- radians the pelvis tips freely, and never
local WAIST = 0.7 -- the share of that tip the waist gives back: the chest and the towers stay nearly upright
local WAIST_ROLL, WAIST_MOST = 0.12, 0.17 -- radians the waist rolls freely, and never (the boulders meet the legs)
local CHEST_YAW = 0.07 -- radians the chest turns against the legs (its shoulders against its hips)
local LEAN = 0.03 -- radians it leans into its walk ...
local LEAN_RUN = 0.1 -- ... and into its run
local ARM = 0.2 -- radians a shoulder swings each way at the walk (the boulder's end goes 0.09 of the height) ...
local ARM_RUN = 0.34 -- ... and at the run (19.5 degrees: a shoulder that carries its tower is clean to 20)
local ARM_LAG = 0.1 -- of a stride: the arms are behind the legs ...
local FIST_LAG = 0.12 -- ... and the boulder behind the arm
local ELBOW = 0.1 -- radians the elbow gives each way as the arm swings
local ELBOW_RUN = 0.3 -- radians the elbows bend when it runs
local JOLT = 0.03 -- radians the arms sag at the elbow as a foot lands
local ARM_IN = 0.07 -- radians an arm is rolled towards the leg at the very most (5 degrees is in the leg)
-- (the head's looks: a little wider than the Totem Golem's, 17 degrees against 14: this head has a neck and
-- stands free of the towers, and its crown is 0.26 high, not 0.42)
local LOOK = { yaw = 0.3, up = 0.04, down = 0.05, turn = 0.9, least = 4, mean = 14, aside = 5, most = 45, home = 0.7 }
-- radians the head is never turned past, about each axis (this body's table: 20, 20 and 12 degrees)
local HEAD_YAW, HEAD_PITCH, HEAD_ROLL = 0.34, 0.3, 0.19
local SHIFT = 0.085 -- of its leg: how far it stands over one foot when it rests its weight on it
local SHIFT_ROLL = 0.012 -- radians it leans with that

function Golem.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Golem.legs do
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
		armL = Kit.chain(rig, "LA"),
		armR = Kit.chain(rig, "RA"),
		halfHips = 0.5 * math.abs(legs[2].hipX - legs[1].hipX),
		pelvisY = rig.py[Kit.bone(rig, "Body_01")],
		tip = 0, -- radians the pelvis was tipped in the frame before (+ lifts its right side)
		heelL = 0, -- radians each heel is up for a leg that trails (`heel`)
		heelR = 0,
		-- (its own pace: every time of it is in units of this, so that a big one is slower still; 0.241 is the
		-- golems' common measure, the Sand Golem's)
		tempo = W.tick / 0.241,
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		-- the weight it rests on one foot while it stands: -1 the left, 1 the right, 0 both
		weight = 0,
		weightFrom = 0,
		weightTo = 0,
		weightAt = -100,
		weightNext = 8 + 20 * Kit.roll(dice),
	}
end

-- How far over where it stands at rest a leg's HIP is when the leg, at the length it is comfortable at, reaches
-- where its foot is: on the ground (told by the front edge of its sole: the ankle goes up and forward as the
-- heel rises) or in the air (told by its ankle). The body is `ox` to the side of where it stands. Under 0: the
-- hip must come down (the foot is far in front, behind, or out to the side); over 0: it goes up (the legs
-- slant OUT at rest, and over the foot that stands a leg is upright).
local function room(one, ox, comfy, tipped, pelvisY)
	-- (the hips hang a little under the joint the pelvis tips about: tipped, they also go to the side)
	ox += one.hipX * (cos(tipped) - 1) - (one.hipY - pelvisY) * sin(tipped)
	local fore, rise = one.tz - one.hipZ, 0
	if one.mode == "down" then
		local c, s = cos(one.sigma), sin(one.sigma)
		fore -= one.u1y * s + one.u1z * c
		rise = one.homeY - (one.u1y * c - one.u1z * s) - one.restAnkleY
	else
		rise = one.ty - one.restAnkleY
	end
	local across, home = one.tx - one.hipX - ox, one.homeX - one.hipX
	local long = one.longD * comfy
	local left = long * long - fore * fore - (across * across - home * home)
	return math.sqrt(math.max(left, 0.01 * long * long)) - (one.hipY - one.restAnkleY) + rise
end

-- How much of its fold a leg in the air has, 0 to 1: most a third of the way through its swing, and little left
-- when it reaches forward to land (a folded knee throws the thigh forward, half a degree for each of its own,
-- and the hip is to turn 30 degrees and no more).
local function folded(one)
	if one.mode == "down" then
		return 0
	end
	local up = sin(pi * one.s ^ 0.6)
	return up * up
end

-- A FOOT FLAT UNDER A PELVIS THAT TIPS. The kit solves a leg in the frame of what it hangs on and holds the
-- foot against the ground as that frame sees it: under a pelvis rolled by `a` the foot is rolled with it (an
-- edge of the sole in the ground), and its ankle is where a rolled foot puts it. Two halves:
--   `plant`, BEFORE `Kit.solve`, for a foot on the ground: tells the solver the planted point where the rolled
--     foot would need it, so that the ankle comes to lie where the ankle of a FLAT foot is;
--   `flat`, AFTER it, in place of `Kit.straighten`: turns the foot bone so that the foot is pitched against
--     the ground as the solver meant and nothing else, whatever the pelvis and the leg above it do.
local function plant(one, a)
	if one.mode == "down" then
		-- (how far under its ankle the planted point of the pitched foot is)
		local under = one.u1y * cos(one.sigma) - one.u1z * sin(one.sigma)
		one.tx -= under * sin(a)
		one.ty += under * (cos(a) - 1)
	end
end

-- (a vector turned back through the foot's pitch, the pelvis's roll, the hip's aim and lean, the knee)
local function back(cp, sp, ca, sa, cm, sm, cs, ss, ck, sk, x, y, z)
	y, z = y * cp - z * sp, y * sp + z * cp
	x, y = x * ca + y * sa, -x * sa + y * ca
	y, z = y * cm + z * sm, -y * sm + z * cm
	x, y = x * cs + y * ss, -x * ss + y * cs
	y, z = y * ck + z * sk, -y * sk + z * ck
	return x, y, z
end

local function flat(pose, one, a)
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local hip, knee, foot = one.b[1], one.b[2], one.b[3]
	local aim, side, fold = rx[hip], rz[hip], rx[knee]
	local pitch = rx[foot] + aim + fold -- (the foot's pitch against the ground, as the solver set it)
	local cp, sp, ca, sa = cos(pitch), sin(pitch), cos(a), sin(a)
	local cm, sm, cs, ss, ck, sk = cos(aim), sin(aim), cos(side), sin(side), cos(fold), sin(fold)
	local _, r21 = back(cp, sp, ca, sa, cm, sm, cs, ss, ck, sk, 1, 0, 0)
	local _, r22 = back(cp, sp, ca, sa, cm, sm, cs, ss, ck, sk, 0, 1, 0)
	local r13, r23, r33 = back(cp, sp, ca, sa, cm, sm, cs, ss, ck, sk, 0, 0, 1)
	local yaw, roll = math.atan2(r13, r33), math.atan2(r21, r22)
	-- (a leg that was left lying far out, by a model spun on the spot, keeps the solver's own answer)
	if math.abs(yaw) < 0.7 and math.abs(roll) < 0.7 then
		rx[foot], ry[foot], rz[foot] = math.asin(Kit.clamp(-r23, -1, 1)), yaw, roll
	end
end

-- THE HEEL RISES AS FAR AS THE LEG TRAILS (this body's own: its ankle is clean to 20 degrees, where a crystal of
-- the foot meets the shin; the Totem Golem's to 30). The kit lifts the heel by the clock, 9 degrees over the
-- last third of a stance. That is all a steady stroll needs; setting off, turning and walking fast leave a foot
-- further behind its hip, and a flat foot under a shin that leans back 25 degrees is bent 25 degrees at the
-- ankle. So, AFTER `Kit.gait` and before anything reads the foot's pitch, a foot on the ground is turned about
-- its front edge by what its leg trails past `TRAIL_FREE`, where that is more than the clock asks (it comes in
-- without a corner, and follows on a short spring so that a foot put back under its hip does not snap).
-- radians the planted edge of the sole is behind where it stands at rest, seen from the hip, before the heel
-- rises for it (13 degrees: the steady stroll ends its stance at 19, where this asks 7 degrees of heel and the
-- clock 9)
local TRAIL_FREE = 0.22
local TRAIL_RISE = 1.5 -- radians of heel for each radian the leg trails past that
local TRAIL_SOFT = 0.05 -- radians over which that comes in
local function heel(one, was, dt, tick)
	local want = 0
	if one.mode == "down" then
		local trail = math.atan2(one.tz - one.homeZ, one.hipY - one.restAnkleY) - TRAIL_FREE
		if trail > 0 then
			want = TRAIL_RISE * trail * trail / (trail + TRAIL_SOFT)
		end
	end
	local rise = was + (want - was) * (1 - math.exp(-dt * 12 / tick))
	if one.mode == "down" and one.sigma > -rise then
		one.sigma = -rise
	end
	return rise
end

-- AND IN THE AIR THE FOOT HANGS FROM A SHIN THAT LEANS: the knee folds while the thigh is still behind, and a
-- foot held level under it would be bent past what the ankle allows. AFTER `Kit.solve`, the ankle's bend is
-- bound (a curve, not a clamp): what is over it is the heel hanging higher. Free to 15 degrees, never 19.
local ANKLE_FREE, ANKLE_MOST = 0.26, 0.33
local function dangle(pose, one)
	local foot = one.b[3]
	if one.mode ~= "down" and pose.rx[foot] > ANKLE_FREE then
		pose.rx[foot] = Kit.bound(pose.rx[foot], ANKLE_FREE, ANKLE_MOST)
	end
end

-- How much the arms sag, 0 to 1, `d` of a stride after a foot landed (the next one lands at 0.5): into the
-- landing, held while both feet stand, out slowly (the Sand Golem's `sunk`).
local SAG_KEYS = { 0, 0, 0.13, 1, 0.28, 1, 0.44, 0, 0.5, 0 }
local function sag(d)
	return Kit.curve(SAG_KEYS, (d + 0.08) % 0.5)
end

function Golem.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick, tempo = W.tick, S.tempo

	-- THE WEIGHT ON ONE FOOT: standing, it now and then moves its weight over one foot, slowly, and stays there
	if not W.moving and t >= S.weightNext then
		local to = if S.weightTo ~= 0
			then (if Kit.roll(S.dice) < 0.5 then 0 else -S.weightTo)
			elseif Kit.roll(S.dice) < 0.5 then -1
			else 1
		S.weightFrom, S.weightTo, S.weightAt = S.weight, to, t
		S.weightNext = t + Kit.wait(S.dice, 12, 28, 80) * tempo
	elseif W.moving and S.weightTo ~= 0 then
		S.weightFrom, S.weightTo, S.weightAt = S.weight, 0, t
	end
	S.weight = S.weightFrom
		+ (S.weightTo - S.weightFrom) * Kit.ease((t - S.weightAt) / ((if W.moving then 0.6 else 2.2) * tempo))

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	S.heelL = heel(legs[1], S.heelL, dt, tick)
	S.heelR = heel(legs[2], S.heelR, dt, tick)
	local amount = W.amount
	local run = Kit.smooth(W.g) * amount
	local left, right = legs[1], legs[2]
	local phi, duty = left.phi, W.duty
	local swing = cos(TAU * phi) -- (+1 as the left foot lands in front, -1 as the right one does)

	-- THE BODY goes over the foot that stands
	local since = math.min(phi % 1, (phi + 0.5) % 1) -- (of a stride since a foot last landed)
	local over = -cos(TAU * (phi - 0.5 * duty)) * amount * (1 - 0.5 * run)
	local rest = Kit.clamp(S.weight, -1, 1)
	local ox = SWAY * W.h * over + SHIFT * W.h * rest
	pose.ox, pose.oz = ox, 0
	-- EACH HIP AT THE HEIGHT ITS LEG REACHES FROM. On the ground that is where the leg is as long as it likes to
	-- be; in the air it is that less the fold the knee is to have (`FOLD`), so the hip goes up with its foot.
	-- The body is carried at the mean of the two, and the pelvis tips by their difference about the middle of
	-- the hips (+ roll lifts its right side): down to the foot that lands, up with the leg in the air. Running,
	-- it sinks a little over the leg it lands on.
	local comfy = W.design.comfy
	local fold = (FOLD + (FOLD_RUN - FOLD) * run) * W.h
	local hipL = room(left, ox, comfy, S.tip, S.pelvisY) - fold * folded(left)
	local hipR = room(right, ox, comfy, S.tip, S.pelvisY) - fold * folded(right)
	local tip = Kit.bound(math.asin(Kit.clamp((hipR - hipL) / (2 * S.halfHips), -1, 1)), TIP, TIP_MOST)
	S.tip = tip
	-- (where the tip is held back, in a run, the body is as low as the lower of the two hips asks: a leg on
	-- the ground is never out of reach, the one in the air folds a little more)
	local half = S.halfHips * sin(tip)
	local dip = RUN_DIP * W.h * run * (0.5 + 0.5 * cos(2 * TAU * (phi - 0.5 * duty)))
	pose.bob = math.min(hipL + half, hipR - half) - dip
	rx[S.root] = 0
	rz[S.root] = 0
	rz[S.pelvis] = tip
	plant(left, tip)
	plant(right, tip)
	Kit.solve(W, pose)
	dangle(pose, left)
	dangle(pose, right)
	flat(pose, left, tip)
	flat(pose, right, tip)

	-- THE WAIST gives most of the pelvis's tip back, turns the chest against the legs, and leans into the walk
	local turn = CHEST_YAW * amount * swing
	local forward = -(LEAN * amount + (LEAN_RUN - LEAN) * run)
	rx[S.chest] = forward
	ry[S.chest] = turn
	-- (and where it rests its weight on one foot, the chest leans over that foot a little)
	local lean = (1 - WAIST) * tip - SHIFT_ROLL * rest -- (what the chest leans to its left)
	rz[S.chest] = Kit.bound(lean - tip, WAIST_ROLL, WAIST_MOST)

	-- THE ARMS swing against the legs, slowly and late, from the shoulder; the boulder is later still, and
	-- sags a little at the elbow as a foot lands
	local reach = ARM * amount + (ARM_RUN - ARM) * run
	local arm = reach * cos(TAU * (phi - ARM_LAG))
	local fist = ELBOW * amount * cos(TAU * (phi - ARM_LAG - FIST_LAG))
	local jolt = JOLT * (amount - run) * sag(since)
	local armL, armR = S.armL, S.armR
	Kit.zero(pose, armL)
	Kit.zero(pose, armR)
	rx[armL[1]], rx[armR[1]] = -arm, arm
	rx[armL[2]] = -fist + ELBOW_RUN * run - jolt
	rx[armR[2]] = fist + ELBOW_RUN * run - jolt
	-- (they hang: what the chest leans, the shoulders give back in part. + roll brings the LEFT arm in and
	-- takes the right one out; neither is ever brought in further than `ARM_IN`)
	local hang = -0.5 * lean
	rz[armL[1]] = if hang > 0 then Kit.bound(hang, 0.5 * ARM_IN, ARM_IN) else hang
	rz[armR[1]] = if hang < 0 then Kit.bound(hang, 0.5 * ARM_IN, ARM_IN) else hang

	-- THE HEAD is one joint in a short neck: it takes out the chest's turn and the trunk's lean, and that is
	-- all it does while it walks. Standing, it is still and now and then looks somewhere, slowly. No turn of it
	-- goes past what the ice between the towers allows.
	local head = S.head
	local look, pitch = Kit.gaze(S.gaze, t / tempo, S.dice, LOOK, not W.moving)
	-- (into a turn the head goes first)
	look += Kit.spring(S.lookTurn, Kit.clamp(0.2 * W.w * tempo, -0.12, 0.12) * amount, 3 / (tick / 0.29), 1, dt)
	rx[head[1]] = Kit.bound(-0.8 * forward + pitch, 0.6 * HEAD_PITCH, HEAD_PITCH)
	ry[head[1]] = Kit.bound(-turn + look, 0.6 * HEAD_YAW, HEAD_YAW)
	rz[head[1]] = Kit.bound(-lean, 0.6 * HEAD_ROLL, HEAD_ROLL)
end

return Golem
