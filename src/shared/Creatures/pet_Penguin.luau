-- The Penguin of the Frozen Peaks (art/models/ready/pet_Penguin.glb, 16 bones, built and skinned for it: see
-- docs/motion/pet_Penguin.md): its joint map, and the MOTION OF THE SAND GOLEM (pet_SandGolem.luau: the finished
-- heavy biped whose body goes right over the foot that stands) on it, changed only where this body is another.
-- A stiff egg of a trunk on two legs a seventh of its height: a hip inside the belly, an ankle, toes, and NO
-- KNEE. It WADDLES: the whole bird rocks over the foot that stands, which lifts the other hip and with it the
-- other foot; the head and its tall crest of ice stay upright; the flippers hang, and the one on the side that
-- rises lifts out. Look at art/models/rigs/pet_Penguin_front.png and art/models/poses/pet_Penguin_pose_waddle.png
-- beside this file.
--
-- What this body changes of the Sand Golem's motion:
--   * A LEG THAT CANNOT FOLD. The Golem's knee takes up whatever its body does; here a leg is one stiff piece
--     from the hip to the ankle, so nothing may be left to it. The height of the body is not designed but
--     WORKED OUT at every frame: as high as the stiff legs let it be (`step`, "the height"), and a planted foot
--     whose hip is higher than it reaches flat ROLLS UP ONTO ITS TOES (the heel lifts about the ball, the toes
--     stay down: `heel`). A foot in the air is carried by its hip alone: it is lifted by the rock, not folded.
--   * THE ROCK IS BIGGER THAN THE STEP (6 degrees against the Golem's 2), and it is what lifts a foot. It
--     passes level a moment before a foot lands, so that the foot comes down as the bird comes level.
--   * FEET THAT STAY FLAT UNDER HIPS THAT ROLL: each hip gives the rock back (`unroll`), or the big flat feet
--     would tilt with the body, their edges in the ground.
--   * no boot that lands on its heel edge: a flat foot is put down flat.
--   * flippers for arms (out on the side that rises, held out and back when it hurries), a stub of a tail that
--     wags against the steps, a neck: a look is shared a third and two thirds.
--   * no flight when it hurries: stiff legs cannot throw it off the ground. Its run is the waddle, quicker
--     and calmer.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, sqrt, asin, atan2, pi = math.sin, math.cos, math.sqrt, math.asin, math.atan2, math.pi
local max = math.max
local TAU = pi * 2

local Penguin = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Penguin.map = {
	count = 16,
	tree = 677445085,
	-- Root is the handle, between and just over the hips: it drives nothing. Body_01, at the same place, is the
	-- HIPS (the lower belly, rigid on it, and the rump; the legs and the tail hang on it). Body_02's joint is the
	-- WAIST: the chest; the flippers and the neck hang on it
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- the foot of the neck (a pivot: it drives next to nothing by itself) and the base of the skull: the head,
	-- the beak and the whole crest of ice are the head's skin (no bone above it)
	neck = { "Neck_01" },
	head = { "Head" },
	-- a stub: one joint in the rump, its bone back and down to the tip
	tail = { "Tail_01" },
	legs = {
		-- a leg, from the body down: the HIP (inside the belly), the ANKLE (in the stub between belly and foot:
		-- the hind half of the foot and the heel), the TOES (where the three part). There is no knee
		LL = { "Leg_L_01", "Leg_L_02", "Leg_L_03" },
		RL = { "Leg_R_01", "Leg_R_02", "Leg_R_03" },
	},
	limbs = {
		-- a flipper: the SHOULDER inside the flank, and one joint half way along the free blade
		LW = { role = "arm", bones = { "Wing_L_01", "Wing_L_02" } },
		RW = { role = "arm", bones = { "Wing_R_01", "Wing_R_02" } },
	},
	pairs = { { "LL", "RL" }, { "LW", "RW" } },
	rigid = {},
}

-- The top joint is the base of the skull, 0.63 of the model: the head and the crest stand over it. What the
-- kit calls the rig's height is that; the lengths below are of the LEG (the hip's height, 0.15 of the model)
-- unless they say otherwise.
local TOP = 0.63

-- HOW IT STROLLS in its plot: a sixth of its height a second in tiny quick steps (three a second for one of 4
-- studs), and it stands a while. (`leg` is a share of the skeleton's height, as the kit's lengths are.)
Penguin.stroll = { froude = 0.02, leg = 0.15 / TOP, rest = { 3, 10 }, radius = 0.7 }

-- THE LEGS --------------------------------------------------------------------------------------------------
local BALL_DOWN = 0.025 / TOP -- of the skeleton's height: the ground under the joint where the toes part
local BALL_AHEAD = 0.012 / TOP -- ... and this far ahead of it: what the heel lifts about
local HEEL_MOST = 0.56 -- radians a heel lifts about the ball at the most (32 degrees; the skin allows 40)
local HEEL_DOWN = 0.6 -- the share of its swing over which a heel that left the ground lifted comes level
local TOES_LOW, TOES_HIGH = -0.25, 0.65 -- radians the toes bend against the foot (the skin allows 40 degrees)
local BEHIND = 0.01 / TOP -- of the skeleton's height: the middle of a stance is this far behind where it stands
-- what the skin allows (docs/motion/pet_Penguin.md, the bend table), radians: unchanged up to the first number,
-- eased towards the second and never past it
local HIP_FREE, HIP_MOST = 0.36, 0.43 -- a hip swings 25 degrees forward or back: beyond, the foot is in the belly
local IN_FREE, IN_MOST = 0.1, 0.17 -- a leg leans 10 degrees in ...
local OUT_FREE, OUT_MOST = 0.4, 0.52 -- ... and 30 out
local FOOT_FREE, FOOT_MOST = 0.25, 0.34 -- an ankle rolls 20 degrees
local TOES_UP_FREE, TOES_UP_MOST = 0.36, 0.43 -- a foot comes up 25 degrees at its ankle ...
local HEEL_FREE, HEEL_UP_MOST = 0.56, 0.69 -- ... and goes down 40

local function leg(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		-- the ankle is the SECOND joint: above it there is the hip and nothing to fold
		ankle = 2,
		front = 0.5,
		-- (a leg a tenth of its height long may swing 25 degrees forward and no further, and its heel lifts at the
		-- end of a stance, which brings its ankle forward: the feet work a little behind the hips, and the hip
		-- then swings as far forward as back)
		centre = BEHIND,
		-- THE POINT THAT IS PLANTED IS THE BALL OF THE FOOT, the ground under the joint of the toes: the foot
		-- stands flat on it, and the heel lifts about it
		contact = chain[3],
		tip = { below = BALL_DOWN, ahead = BALL_AHEAD },
		fold = {},
		sink = 0,
		open = 0,
		-- (what the kit aims a foot in the air at: `step` says how high it really is, by its hip)
		lift = { walk = 0.16, trot = 0.12 },
	}
end

Penguin.legs = {
	leg("LL", "left leg", Penguin.map.legs.LL),
	leg("RL", "right leg", Penguin.map.legs.RL),
}

-- THE GAITS (the legs in the order above: left, right) ------------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- a waddle: tiny steps (a leg of a tenth of its height swings 20 degrees each way and no further), three
	-- fifths of the stride on the ground
	walk = {
		offsets = { 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.05, least = 0.58, most = 0.64 },
		stride = { 2.3, 0.3 },
	},
	-- hurrying (the kit calls its second gait a trot), from two and a half times its stroll: the same order, the
	-- legs swing no further, only quicker, and a foot is always down (stiff legs cannot throw it off the ground)
	trot = {
		offsets = { 0, 0.5 },
		duty = { at = 0.54, slope = 0.03, ref = 1, least = 0.52, most = 0.56 },
		stride = { 2.3, 0.3 },
		sweep = 0.44,
		from = 0.12,
		back = 0.09,
		shift = 0.4,
	},
	sweep = 0.44,
	finish = 0.25,
	settle = { far = 0.16, time = 2.0, least = 2, mean = 6, most = 16 },
	comfy = 0.99,
	letGo = 0.55,
	comeDown = 0.45,
}

-- THE BODY, THE FLIPPERS, THE HEAD ----------------------------------------------------------------------------
local SWAY = 0.1 -- of its leg: how far the body goes over the foot that stands
local ROLL = 0.105 -- radians the whole bird rocks over that foot (6 degrees; 8 were looked at)
local EARLY = 0.03 -- of a stride: the rock is level this long before a foot lands
local RUN_CALM = 0.45 -- the share of the rock and the sway that goes when it hurries
local CHEST_BACK = 1 / 3 -- the share of the rock the chest gives back (the neck and the head give the rest)
local CHEST_YAW = 0.05 -- radians the chest turns against the legs
local LEAN = 0.03 -- radians it leans into its walk ...
local LEAN_RUN = 0.14 -- ... and when it hurries
local FLIP = 0.3 -- radians the flipper on the side that rises lifts out (17 degrees) ...
local FLIP_TIP = 0.4 -- ... and its blade that share more
local FLIP_LAG = 0.06 -- of a stride: the flippers are behind the rock
local FLIP_HANG = 0.5 -- the share of the chest's lean a shoulder gives back: they hang
local FLIP_RUN = 0.22 -- radians both are held out when it hurries ...
local FLIP_RUN_BACK = 0.3 -- ... and back
local TAIL_WAG = 0.14 -- radians the tail wags against the steps ...
local TAIL_LAG = 0.1 -- ... this share of a stride behind them
local TAIL_UP = 0.12 -- radians it lifts as the bird goes ...
local TAIL_UP_RUN = 0.3 -- ... and hurries
local LOOK = { yaw = 0.5, up = 0.06, down = 0.08, turn = 0.45, least = 2, mean = 7, aside = 2.5, most = 24, home = 0.7 }
local LOOK_NECK = { 1 / 3, 2 / 3 } -- how the neck and the head share a look
local SHIFT = 0.09 -- of its leg: how far it stands over one foot when it rests its weight on it
local SHIFT_ROLL = 0.02 -- radians it leans with that
local TICK = 0.13 -- seconds: sqrt(leg / G) of a penguin of 3.92 studs, the size the game shows one of weight 1 at

function Penguin.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Penguin.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local root = rig.root
	local hips, keep = {}, {}
	for k, one in legs do
		-- (where its hip is from the root's joint, at rest; the hips' own joint lies in the root's)
		local top = one.b[1]
		hips[k] = {
			fromX = rig.px[top] - rig.px[root],
			fromY = rig.py[top] - rig.py[root],
			fromZ = rig.pz[top] - rig.pz[root],
			x = 0,
			y = 0,
			z = 0,
		}
		keep[k] = { 0, 0, 0, 0, 0, 0, 0 }
	end
	local neck, head = Kit.chain(rig, "the neck"), Kit.chain(rig, "the head")
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		root = root,
		rootX = rig.px[root],
		rootY = rig.py[root],
		rootZ = rig.pz[root],
		chest = Kit.bone(rig, "Body_02"),
		neckHead = { neck[1], head[1] },
		tail = Kit.bone(rig, "Tail_01"),
		wingL = Kit.chain(rig, "LW"),
		wingR = Kit.chain(rig, "RW"),
		hips = hips,
		keep = keep,
		-- (its own pace: every time of it is in units of this, so that a big one is slower)
		tempo = W.tick / TICK,
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		bob = 0,
		-- the weight it rests on one foot while it stands: -1 the left, 1 the right, 0 both
		weight = 0,
		weightFrom = 0,
		weightTo = 0,
		weightAt = -100,
		weightNext = 4 + 10 * Kit.roll(dice),
	}
end

-- THE HEEL OF A FOOT THAT STANDS. The hip is at (hx, hy, hz) in the model and the ball of the foot is planted:
-- the pitch of the foot about its ball (0 flat, under 0 the heel up) at which the ankle is exactly the leg's
-- length from the hip. A hip no higher than the leg reaches flat: 0.
local function heel(one, hx, hy, hz, long2)
	local u1y, u1z = one.u1y, one.u1z
	local dx = hx - (one.tx - one.u1x)
	local dy, dz = hy - (one.homeY - u1y), hz - (one.tz - u1z)
	if dx * dx + dy * dy + dz * dz - long2 <= 1e-9 * long2 then
		return 0
	end
	local lo, hi = -HEEL_MOST, 0
	local c, s = cos(lo), sin(lo)
	dy, dz = hy - (one.homeY - (u1y * c - u1z * s)), hz - (one.tz - (u1y * s + u1z * c))
	if dx * dx + dy * dy + dz * dz - long2 >= 0 then
		return lo -- (out of reach even so: it has been pushed about)
	end
	for _ = 1, 18 do
		local mid = (lo + hi) / 2
		c, s = cos(mid), sin(mid)
		dy, dz = hy - (one.homeY - (u1y * c - u1z * s)), hz - (one.tz - (u1y * s + u1z * c))
		if dx * dx + dy * dy + dz * dz - long2 > 0 then
			hi = mid
		else
			lo = mid
		end
	end
	return (lo + hi) / 2
end

-- A HIP GIVES THE ROCK BACK. The kit has solved a leg under hips that are level; they are rolled by `roll`:
-- the turn of the hip joint that leaves the leg and its foot as they were solved (the roll undone, then the
-- kit's aim and lean, as ONE turn in the order a pose is read in).
local function unroll(pose, i, roll)
	local a, s = pose.rx[i], pose.rz[i]
	local ca, sa, cs, ss = cos(a), sin(a), cos(s), sin(s)
	local cr, sr = cos(roll), sin(roll)
	pose.rx[i] = asin(Kit.clamp(cr * sa, -1, 1))
	pose.ry[i] = atan2(-sr * sa, ca)
	pose.rz[i] = atan2(-sr * cs + cr * ca * ss, sr * ss + cr * ca * cs)
end

function Penguin.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tempo = S.tempo

	-- THE WEIGHT ON ONE FOOT: standing, it now and then moves its weight over one foot, and stays there
	if not W.moving and t >= S.weightNext then
		local to = if S.weightTo ~= 0
			then (if Kit.roll(S.dice) < 0.5 then 0 else -S.weightTo)
			elseif Kit.roll(S.dice) < 0.5 then -1
			else 1
		S.weightFrom, S.weightTo, S.weightAt = S.weight, to, t
		S.weightNext = t + Kit.wait(S.dice, 6, 14, 40) * tempo
	elseif W.moving and S.weightTo ~= 0 then
		S.weightFrom, S.weightTo, S.weightAt = S.weight, 0, t
	end
	S.weight = S.weightFrom
		+ (S.weightTo - S.weightFrom) * Kit.ease((t - S.weightAt) / ((if W.moving then 0.4 else 1.2) * tempo))

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	local amount = W.amount
	local run = Kit.smooth(W.g) * amount
	local left = legs[1]
	local phi = left.phi
	local swing = cos(TAU * phi) -- (+1 as the left foot lands in front, -1 as the right one does)

	-- THE ROCK: the whole bird goes over the foot that stands and leans over it, which lifts the other hip
	-- (`over`: -1 over the left foot, 1 over the right; level a moment before a foot lands)
	local calm = amount * (1 - RUN_CALM * run)
	local over = -sin(TAU * (phi + EARLY)) * calm
	local rest = Kit.clamp(S.weight, -1, 1)
	local ox = SWAY * W.h * over + SHIFT * W.h * rest
	local roll = -ROLL * over - SHIFT_ROLL * rest
	local lean = -(LEAN * amount + (LEAN_RUN - LEAN) * run)

	-- THE HEIGHT. A leg is one stiff piece, so each leg says how high the body may be, and the body is exactly
	-- as high as the one that asks most: a foot that stands flat is then at its leg's length (never in the
	-- ground), and a foot in the air is never under it. First where each hip is, the body at its rest height
	-- (the root's turn is its lean, then its roll).
	local cr, sr, cl, sl = cos(roll), sin(roll), cos(lean), sin(lean)
	local long2 = left.restD * left.restD + left.xr * left.xr
	local bob = -math.huge
	for k, one in legs do
		local hip = S.hips[k]
		local x1, y1 = hip.fromX * cr - hip.fromY * sr, hip.fromX * sr + hip.fromY * cr
		hip.x = S.rootX + ox + x1
		hip.y = S.rootY + y1 * cl - hip.fromZ * sl
		hip.z = S.rootZ + y1 * sl + hip.fromZ * cl
		-- (its ankle: over its planted ball with the foot flat; in the air where the kit carries it, no lower
		-- than its ball, pitched as it is, comes to the ground)
		local ax, ay, az
		if one.mode == "down" then
			ax, ay, az = one.tx - one.u1x, one.homeY - one.u1y, one.tz - one.u1z
		else
			-- (the heel it left the ground with comes down slowly: the kit would have the foot level in a quarter
			-- of its swing, three frames of so quick a step)
			one.sigma = one.sig0 * (1 - Kit.smooth(one.s / HEEL_DOWN))
			ax, az = one.tx, one.tz
			ay = one.homeY - (one.u1y * cos(one.sigma) - one.u1z * sin(one.sigma))
		end
		local dx, dz = hip.x - ax, hip.z - az
		bob = max(bob, ay + sqrt(max(long2 - dx * dx - dz * dz, 0.04 * long2)) - hip.y)
	end
	S.bob = bob
	for k, one in legs do
		local hip = S.hips[k]
		if one.mode == "down" then
			-- (a hip higher than its foot reaches flat: the heel lifts)
			one.sigma = heel(one, hip.x, hip.y + bob, hip.z, long2)
		else
			-- (a foot in the air hangs from its hip at the leg's length: that is how high it is)
			local dx, dz = hip.x - one.tx, hip.z - one.tz
			one.ty = hip.y + bob - sqrt(max(long2 - dx * dx - dz * dz, 0.04 * long2))
		end
	end

	-- THE LEGS, solved under hips that are level and stand where the rolled ones do (one leg at a time: each
	-- hip is somewhere else), then each hip gives the rock back
	local root = S.root
	rx[root], ry[root], rz[root] = lean, 0, 0
	for k, one in legs do
		local hip, keep = S.hips[k], S.keep[k]
		pose.ox = hip.x - S.rootX - hip.fromX
		pose.bob = hip.y + bob - S.rootY - (hip.fromY * cl - hip.fromZ * sl)
		pose.oz = hip.z - S.rootZ - (hip.fromY * sl + hip.fromZ * cl)
		Kit.solve(W, pose)
		local top, foot = one.b[1], one.b[2]
		-- (WHAT ITS SKIN ALLOWS, as curves: walking, no joint comes near them; pushed about or spun on the spot
		-- a leg is asked for more, and then gives what it has. The foot keeps what the hip does not take.)
		local aim = rx[top]
		rx[top] = Kit.bound(aim, HIP_FREE, HIP_MOST)
		rx[foot] += aim - rx[top]
		Kit.straighten(pose, one)
		unroll(pose, top, roll)
		local inward = -one.side * rz[top]
		local held = if inward > 0 then Kit.bound(inward, IN_FREE, IN_MOST) else Kit.bound(inward, OUT_FREE, OUT_MOST)
		rz[top] = -one.side * held
		rz[foot] = Kit.bound(rz[foot] - one.side * (inward - held), FOOT_FREE, FOOT_MOST)
		rx[foot] = if rx[foot] > 0
			then Kit.bound(rx[foot], TOES_UP_FREE, TOES_UP_MOST)
			else Kit.bound(rx[foot], HEEL_FREE, HEEL_UP_MOST)
		keep[1], keep[2], keep[3] = rx[top], ry[top], rz[top]
		keep[4], keep[5], keep[6] = rx[foot], ry[foot], rz[foot]
		keep[7] = one.over
	end
	for k, one in legs do
		local keep = S.keep[k]
		local top, foot = one.b[1], one.b[2]
		rx[top], ry[top], rz[top] = keep[1], keep[2], keep[3]
		rx[foot], ry[foot], rz[foot] = keep[4], keep[5], keep[6]
		one.over = keep[7]
		-- the toes stay on the ground while the heel lifts, and let go as the foot leaves
		Kit.toes(pose, one, 1, HEEL_DOWN, TOES_LOW, TOES_HIGH)
	end
	pose.ox, pose.bob, pose.oz = ox, bob, 0
	rz[root] = roll

	-- THE CHEST gives a third of the rock back and turns a little against the legs
	local turn = CHEST_YAW * amount * swing
	local chest = S.chest
	rx[chest], ry[chest], rz[chest] = 0, turn, -CHEST_BACK * roll

	-- THE FLIPPERS hang; the one on the side that rises lifts out, a little late, and its blade a little more.
	-- Hurrying, both are held out and back. (Out is under 0 for the left, over 0 for the right; never in.)
	local late = -sin(TAU * (phi + EARLY - FLIP_LAG)) * calm
	local hang = -FLIP_HANG * (1 - CHEST_BACK) * roll
	local outL = 0.5 * FLIP * (amount + late) + FLIP_RUN * run
	local outR = 0.5 * FLIP * (amount - late) + FLIP_RUN * run
	local wingL, wingR = S.wingL, S.wingR
	Kit.zero(pose, wingL)
	Kit.zero(pose, wingR)
	rz[wingL[1]], rz[wingR[1]] = -outL + hang, outR + hang
	rz[wingL[2]], rz[wingR[2]] = -FLIP_TIP * outL, FLIP_TIP * outR
	rx[wingL[1]], rx[wingR[1]] = -FLIP_RUN_BACK * run, -FLIP_RUN_BACK * run

	-- THE TAIL wags against the steps and lifts as the bird goes
	local tail = S.tail
	rx[tail] = -(TAIL_UP * amount + (TAIL_UP_RUN - TAIL_UP) * run)
	ry[tail] = -TAIL_WAG * amount * cos(TAU * (phi - TAIL_LAG))
	rz[tail] = 0

	-- THE NECK AND THE HEAD take out the rest of the rock, the chest's turn and the trunk's lean: the head and
	-- its crest stay upright and look ahead, and that is all they do while it walks. Standing, the head is
	-- still and now and then looks somewhere.
	local neckHead = S.neckHead
	Kit.zero(pose, neckHead)
	local look, pitch = Kit.gaze(S.gaze, t / tempo, S.dice, LOOK, not W.moving)
	-- (into a turn the head goes first)
	look += Kit.spring(S.lookTurn, Kit.clamp(0.2 * W.w * tempo, -0.25, 0.25) * amount, 3 / tempo, 1, dt)
	Kit.spread(pose, neckHead, LOOK_NECK, pitch - 0.8 * lean, look - turn, 0)
	local back = -0.5 * (1 - CHEST_BACK) * roll
	rz[neckHead[1]], rz[neckHead[2]] = back, back
end

return Penguin
