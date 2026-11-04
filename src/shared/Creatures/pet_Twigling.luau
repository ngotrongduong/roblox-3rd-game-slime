-- The Twigling (art/models/ready/pet_Twigling.glb, 37 bones: a sapling that walks): its joint map and its own
-- motion. A small biped with a head as big as the rest of it, legs an eighth of its height, feet longer than
-- its legs, and two twig arms that stand out to the sides. docs/MOTION.md sections 1 to 3 and 10 are what it is
-- designed from, docs/motion/pet_Twigling.md what was learned on it. Look at art/models/rigs/pet_Twigling_left.png
-- and _front.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2

local Twigling = {}

-- (A LONG FOOT KEPT STRAIGHT: `Kit.straighten`, written for this animal and since moved into the kit. The
-- solver leans a leg sideways at its top joint and takes the lean out again at the ankle; a foot longer than
-- the leg shows the little that is left, its toe swinging to the side while it stands.)

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the numbers are the bones' names: "022" is Bone_022. The skeleton stands 0.04 to its right of the mesh's
-- middle: its middle line is the root's x)
--
-- THE GAME'S FILE OF THIS MODEL IS NOT THE .GLB'S SKELETON. assets/Pets/Twigling.rbxm has 36 bones, the .glb
-- (and so tests/data/skeletons.json, the rig sheet and the tools) 37: the import left out Bone_032, the tip of
-- the right eye's chain, which drives no vertex. Every bone this map names is in both, and 032 is only rigid
-- with the head, so the map fits both; what cannot fit both is the count and the print of the tree. They are
-- given where the .glb's skeleton is read (the tests and the tools: Lune, where there is no `script`) and
-- left out in the game, which would otherwise refuse the map and move the Twigling by the generic reader.
-- The names and parents of the 26 bones named here are still checked there. Give both lines their numbers
-- back, unconditionally, once the two files hold the same skeleton.
Twigling.map = {
	prefix = "Bone_",
	count = 37,
	tree = 1675611961,
	-- (the game's file lacks Bone_032: `lost` names it and `treeLost` is the print without it, from
	-- `lune run tools/tree_lost.luau pet_Twigling Bone_032`, so the map fits both files and both are checked)
	lost = { "032" },
	treeLost = 1520885261,
	-- 000 sits in the belly and drives nothing; 001 is the pelvis (the legs AND the whole trunk hang on it);
	-- 007 is the waist (it stands on the root's own place), 006 the chest, 005 the top of the trunk; 004 hangs
	-- back DOWN from 005 into the chest and is what the arms and the neck hang on; 029 is the base of the neck
	root = "000",
	spine = { "000", "001", "007", "006", "005", "004", "029" },
	-- 028 is the neck, where the head sits on the trunk; 027 the middle of the head
	neck = { "028" },
	head = { "027" },
	limbs = {
		-- a leg, from the body down: HIP (aims the leg), KNEE (points forward: folds the shank back and up),
		-- ANKLE (the foot: flat on the ground, and longer than the leg above it), the tip of the toe.
		-- (They are the legs, written here as limbs: the map's check of a leg wants its hip a fifth of the
		-- skeleton's height up, and this one's hips are at a sixth.)
		LL = { role = "leg", bones = { "015", "014", "013", "012" } },
		RL = { role = "leg", bones = { "011", "010", "009", "008" } },
		-- an arm: a bone inside the chest, SHOULDER, ELBOW (it carries the forearm and the forked hand), the
		-- wrist (drives nothing), the tip of the twig
		LA = { role = "arm", bones = { "020", "019", "018", "017", "016" } },
		RA = { role = "arm", bones = { "025", "024", "023", "022", "021" } },
	},
	pairs = { { "LL", "RL" }, { "LA", "RA" } },
	-- rigid: the stub at its back (003, with 002), and everything of the head above its middle (026: the
	-- skull, the two eyes 031 and 033, the sprout with its leaves 036)
	rigid = { "003", "026" },
}

-- HOW IT STROLLS in its plot: an unhurried toddle for legs that short, and it stands a good while (a plant).
Twigling.stroll = { froude = 0.045, leg = 0.162, rest = { 5, 14 }, radius = 0.9 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward)
local HEEL_DOWN = 0.04 -- of the skeleton's height: the ground under the ankle bone ...
local HEEL_BACK = 0.05 -- ... and how far behind it the heel is
local TOES_UP = 0.3 -- radians its toes are up as the heel lands
local SLAP = 0.8 -- how long the foot takes to come flat after that, in units of sqrt(leg / G)

local function leg(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 3,
		front = 0.5,
		-- THE POINT THAT IS PLANTED IS ITS HEEL: the ground under the back of the foot, a little behind the ankle
		-- bone. Its foot is longer than its leg, so it cannot roll off its toe (the heel would have to rise
		-- further than the leg can fold): it lands on its heel with its toes up, slaps flat, and lifts off flat.
		contact = chain[3],
		tip = { below = HEEL_DOWN, ahead = -HEEL_BACK },
		-- (it stands with its ankles a little behind its hips: walking, the middle of a step is under the hip)
		centre = -0.014,
		-- the knee is its one fold, on the ground as in the air; it stands bent (38 degrees) and may open most of
		-- the way as the leg reaches out in front and behind: that is what keeps the body from pumping
		fold = { swing = { 0, -1.0 }, stance = { 0, -1.0 } },
		sink = 0,
		open = 0.25,
		lift = { walk = 0.14, trot = 0.22 },
		-- the foot in the air: level (a toe that hung down would drag: the foot is that long), then its toes come
		-- up to land on the heel. What it does on the ground is in `step` (the kit lands every foot flat)
		pitch = { swing = { 0, 0, 0.4, 0, 0.8, TOES_UP, 1, TOES_UP } },
	}
end

Twigling.legs = {
	leg("LL", "left leg", Twigling.map.limbs.LL.bones),
	leg("RL", "right leg", Twigling.map.limbs.RL.bones),
}

-- THE GAITS (the legs in the order above: left, right) ------------------------------------------------------
local DESIGN = {
	start = 0.004,
	stop = 0.0015,
	-- a walk: the two legs half a stride apart, both feet down for a moment after each landing. (Its steps are
	-- as long as its legs can sweep, longer than the rule of docs/MOTION.md gives so slow a walk: a person
	-- strolling does the same, and legs this short patter otherwise)
	walk = {
		offsets = { 0, 0.5 },
		duty = { at = 0.6, slope = 0.03, ref = 0.1, least = 0.56, most = 0.62 },
		stride = { 2.9, 0.3 },
	},
	-- a run: the same order with a flight after each step (the kit calls its second gait a trot). Its steps
	-- come at one rate whatever the speed (legs this short cannot go quicker and still be seen): going faster
	-- is a longer flight and a shorter time on the ground
	trot = {
		offsets = { 0, 0.5 },
		duty = { at = 0.3, slope = 0.1, ref = 1, least = 0.12, most = 0.38 },
		stride = { 3.0, 0.5 },
		sweep = 0.9,
		from = 0.5,
		back = 0.38,
		shift = 0.4,
	},
	sweep = 0.66,
	finish = 0.25,
	settle = { far = 0.16, time = 1.6, least = 2, mean = 5, most = 14 },
	comfy = 0.99,
	letGo = 0.55,
	comeDown = 0.45,
}

-- THE BODY, THE ARMS, THE HEAD ------------------------------------------------------------------------------
local GIVE = 0.045 -- of its leg: how far the body sinks into each step besides what the legs' reach asks
local GIVE_AT = 0.13 -- of a stride after a foot lands: when it is lowest
local RISE = 0.08 -- of its leg in a sqrt(leg / G): the fastest its body ever rises
local LET_UP = 0.035 -- the same for what a leg's reach had asked of it
local SWAY = 0.07 -- of its leg: how far the body goes over the foot that stands
local HIP_DROP = 0.03 -- radians the pelvis drops on the side whose leg is in the air
local PELVIS_YAW = 0.0 -- radians the pelvis turns forward with the leg that swings
local CHEST_YAW = 0.07 -- radians the chest turns the other way
local LEAN = 0.03 -- radians it leans into its walk ...
local LEAN_RUN = 0.14 -- ... and into its run
local RUN_DIP = 0.1 -- of its leg: how far the body sinks over the leg it runs on
local ARM = 0.3 -- radians a shoulder swings each way at the walk ...
local ARM_RUN = 0.55 -- ... and at the run
local ARM_LAG = 0.07 -- of a stride: the arms are a little behind the legs
local ELBOW_RUN = 0.35 -- radians the elbows bend when it runs
local WHIP = 1.0 -- how much of what its forearm is behind (a spring) shows at the elbow: the springy tip
local WHIP_MOST = 0.4 -- radians, at most
local LOOK = { yaw = 0.7, up = 0.1, down = 0.12, turn = 0.5, least = 4, mean = 16, aside = 5, most = 50, home = 0.7 }
local NECK_SHARE = { 0.4 } -- of a look
local HEAD_SHARE = { 0.6 }
local BREEZE = 0.1 -- radians its trunk leans in a breeze, at the waist

function Twigling.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Twigling.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local armL, armR = Kit.chain(rig, "LA"), Kit.chain(rig, "RA")
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		root = rig.root,
		pelvis = Kit.bone(rig, "001"),
		waist = Kit.bone(rig, "007"),
		chest = Kit.bone(rig, "006"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		armL = armL,
		armR = armR,
		halfHips = 0.5 * math.abs(legs[2].hipX - legs[1].hipX),
		heelBack = HEEL_BACK * rig.height,
		heelDown = HEEL_DOWN * rig.height,
		toes = { 0, 0 }, -- how far each foot's toes were up when it last was in the air
		bob = 0,
		need = 0,
		-- (its own pace: every time of it is in units of this, so that a big one is slow)
		tempo = W.tick / 0.096,
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		whipL = { x = 0, v = 0 },
		whipR = { x = 0, v = 0 },
		hang = { x = 0, v = 0 },
		breezeAt = -100,
		breezeSide = 1,
		breezeNext = 6 + 30 * Kit.roll(dice),
	}
end

function Twigling.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick, tempo = W.tick, S.tempo

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	local amount = W.amount
	-- (heel first: in the air the toes come up, and the ankle is carried where it will be over the planted heel;
	-- on the ground the foot slaps flat in a moment and stays flat)
	for k, one in legs do
		if one.mode == "down" then
			one.sigma = S.toes[k] * (1 - Kit.smooth(one.downT / (SLAP * tick)))
		else
			S.toes[k] = one.sigma
			local up = sin(math.max(one.sigma, 0))
			one.ty += S.heelBack * up
			one.tz += S.heelDown * up
		end
	end
	local run = Kit.smooth(W.g) * amount
	local left, right = legs[1], legs[2]
	local phi, duty = left.phi, W.duty
	local swing = cos(TAU * phi) -- (+1 as the left foot lands in front, -1 as the right one does)

	-- THE BODY hangs from the legs that stand: lowest with both feet down, highest over the middle of a step.
	-- Running, it sinks over the leg it lands on instead and is highest in the flight.
	-- (walking, the knee of the leg that has just landed gives a little more than it must: the springy step)
	-- (what a leg's reach asks of the body is given at once and taken back slowly: the kit asks for a flat foot's
	-- reach until the foot is down, and this one lands with its toes up, which is a shorter one)
	local need = Kit.girdle(W, 1, 2)
	if need < S.need and dt > 0 and not input.jump then
		need = math.max(need, S.need - LET_UP * W.h * dt / tick)
	end
	S.need = need
	local hang = need + GIVE * W.h * (amount - run) * (0.5 + 0.5 * cos(2 * TAU * (phi - GIVE_AT)))
	local dip = RUN_DIP * W.h * run * (0.5 + 0.5 * cos(2 * TAU * (phi - 0.5 * duty)))
	-- the pelvis drops on the side of the leg in the air and turns forward with it; the waist takes both out
	-- again and turns the chest the other way. (It drops about the hip that STANDS: its middle comes down.)
	local drop = HIP_DROP * (Kit.lifted(left) - Kit.lifted(right))
	local yaw = PELVIS_YAW * amount * swing
	rz[S.pelvis], ry[S.pelvis] = drop, -yaw
	-- (it comes down as soon as a leg asks and never pops up: it rises at a pace of its own)
	local bob = -math.sqrt(math.sqrt(hang ^ 4 + dip ^ 4)) - S.halfHips * math.abs(sin(drop))
	if bob > S.bob and dt > 0 and not input.jump then
		bob = math.min(bob, S.bob + RISE * W.h * dt / tick)
	end
	S.bob = bob
	pose.bob = bob
	-- (it goes over the foot that stands)
	pose.ox = -SWAY * W.h * amount * (1 - 0.6 * run) * cos(TAU * (phi - 0.5 * duty))
	pose.oz = 0
	rx[S.root] = -(LEAN * amount + (LEAN_RUN - LEAN) * run)
	Kit.solve(W, pose)
	Kit.straighten(pose, left)
	Kit.straighten(pose, right)

	-- A BREEZE, now and then while it stands: the trunk leans over and comes back, twice, less each time
	if not W.moving and t >= S.breezeNext then
		S.breezeAt, S.breezeSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.breezeNext = t + Kit.wait(S.dice, 14, 32, 90) * tempo
	end
	local gust = (t - S.breezeAt) / (3.2 * tempo)
	local lean = 0
	if gust > 0 and gust < 1 then
		lean = BREEZE * S.breezeSide * sin(TAU * 2 * gust) * sin(pi * gust) ^ 2 * (1 - 0.5 * gust)
	end
	rz[S.waist], ry[S.waist] = -0.75 * drop + lean, yaw + CHEST_YAW * amount * swing
	rz[S.chest], ry[S.chest] = 0.6 * lean, 0

	-- THE ARMS swing against the legs, a little late, from the shoulder; the forearm is a springy twig: it
	-- follows the shoulder on a spring and whips past where the shoulder stops. In a breeze they hang behind.
	local reach = (ARM * amount + (ARM_RUN - ARM) * run) * cos(TAU * (phi - ARM_LAG))
	local rate = 2.4 / tick
	local lateL = Kit.clamp(Kit.spring(S.whipL, -reach, rate, 0.28, dt) + reach, -WHIP_MOST, WHIP_MOST)
	local lateR = Kit.clamp(Kit.spring(S.whipR, reach, rate, 0.28, dt) - reach, -WHIP_MOST, WHIP_MOST)
	local hung = Kit.spring(S.hang, lean, 2.2 / tick, 0.35, dt)
	local armL, armR = S.armL, S.armR
	Kit.zero(pose, armL)
	Kit.zero(pose, armR)
	rx[armL[2]], rx[armR[2]] = -reach, reach
	rx[armL[3]] = WHIP * lateL + ELBOW_RUN * run
	rx[armR[3]] = WHIP * lateR + ELBOW_RUN * run
	rz[armL[2]], rz[armR[2]] = -1.6 * hung, -1.6 * hung

	-- THE HEAD: the steadiest part. It takes out what the trunk under it does, and standing it is still and
	-- now and then looks somewhere, calmly.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	rx[neck[1]] = -0.85 * rx[S.root]
	ry[neck[1]] = -CHEST_YAW * amount * swing
	rz[neck[1]] = -0.25 * drop - 0.9 * lean
	local look, pitch = Kit.gaze(S.gaze, t / tempo, S.dice, LOOK, not W.moving)
	-- (into a turn the head goes first)
	look += Kit.spring(S.lookTurn, Kit.clamp(0.25 * W.w * tempo, -0.35, 0.35) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, pitch, look, 0)
	Kit.spread(pose, head, HEAD_SHARE, pitch, look, 0)
end

return Twigling
