-- The Bloom Sprite of the Jungle (art/models/ready/pet_BloomSprite.glb, 25 bones: the owner's rig service's
-- 26 with every joint of the legs, the trunk and the neck moved into its limb and one joint of the tail
-- taken out). It is called a sprite and it is a FAWN: four thin legs on hooves like little boots, a short
-- level trunk, a big head on a short neck inside a ring of pink petals, a bud of leaves on a stalk for a
-- tail. Its joint map, and the MOTION OF THE DEER (pet_Deer.luau: a hoofed quadruped, a walk in lateral
-- sequence and a trot) on it, written over the service's names as the Camel's is (no `pairs`, each leg its
-- own `centre` and `tip`), with the Sphinx Cat's way of carrying a heavy head on a short neck, changed only
-- where this body is another: docs/motion/pet_BloomSprite.md says where. Look at
-- art/models/rigs/pet_BloomSprite_left.png beside this file.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, rad = math.sin, math.rad
local TAU = math.pi * 2

local Bloom = {}

-- THE ONE NUMBER THE OWNER DECIDES. The head was MODELLED turned 27 degrees to its left. 1: it looks where
-- it goes (neck and skull turn it straight while it walks, runs and stands at ease; the modelled look is
-- then one of the looks it takes standing). 0: it keeps the modelled turn always, walking too. Anything
-- between is that share of the way.
local STRAIGHT = 1

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Bloom.map = {
	count = 25,
	tree = 197151405,
	-- Root is the service's handle at the rump: it drives nothing and everything hangs on it. Body_01 is the
	-- PELVIS (the hind legs and the tail hang on it), Body_02 the LOIN, Body_03 the CHEST (the collar of
	-- leaves and its gem ride on it; the neck and the forelegs hang on it)
	root = "Root",
	spine = { "Root", "Body_01", "Body_02", "Body_03" },
	-- the foot of a neck nobody sees, inside the ring of petals; then the base of the skull: the face, both
	-- ears, the blossom and the whole ring are rigid on it, more than half the model
	neck = { "Neck_01" },
	head = { "Head" },
	-- the stalk (where the bud is attached to the rump), the fat of the bud, where its three long leaves part
	tail = { "Tail_01", "Tail_02", "Tail_03" },
	-- THE FOUR LEGS ARE LISTED UNDER `limbs`, NOT UNDER `legs`, and that is a way round, not a design: the
	-- kit refuses a chain of `legs` whose last joint is more than 12% of the RIG's height over the ground
	-- ("it does not run from the body down to the ground"). This rig's height is the skull's joint, half of
	-- the model's (nothing above it has a bone), and its last leg joint is the fetlock at the top of a hoof
	-- like a boot: 15%. A chain of `limbs` is read the same and not measured. When the kit measures a leg
	-- against the model, they go back under `legs`.
	limbs = {
		-- foreleg, from the body down: the SHOULDER (inside the chest: it aims the leg), the ELBOW (where the
		-- leg leaves the chest: it folds the forearm forward and up), the CARPUS (the "knee": it folds the
		-- cannon back and up, never forward), the FETLOCK (at the top of the hoof: the hoof is rigid on it, and
		-- there is no pastern and no joint below)
		LF = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" } },
		RF = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" } },
		-- hind leg: the HIP (inside the haunch), the STIFLE (the true knee, it points forward: it folds the
		-- shank back and up), the HOCK (the heel in the air, it points backward: it folds the cannon forward
		-- and up), the FETLOCK (at the top of the hoof)
		LH = { role = "leg", bones = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" } },
		RH = { role = "leg", bones = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" } },
	},
	-- (no `pairs`: the head is turned and the chest a hair with it, the right forefoot stands ahead of the
	-- left one, and every joint was placed on its own limb: a left joint is not the mirror image of its right)
	rigid = {},
}

-- HOW IT STROLLS in its plot: the fawn's slow walk for its own short legs (`leg` and `radius` are shares of
-- the RIG's height, which is half of the model's: the skull's joint is its highest), and it stands and
-- watches a good while.
-- (pace 1, not the walkers' 1.5: above 1 a joint left its limits in the client's slow turn)
Bloom.stroll = { froude = 0.045, leg = 0.66, rest = { 4, 12 }, radius = 1.6, pace = 1 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward. `tip` and
-- `centre` are shares of the RIG's height, 0.508 of the model's, and each leg's own)
local function fore(id, name, chain, centre, tip)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the fetlock is the LAST joint and carries the hoof: it is the bone that is held against the ground)
		ankle = 4,
		front = 0.5,
		-- (the toe of the hoof on the ground, below and ahead of the fetlock)
		tip = tip,
		-- (the middle of a step is a little BEHIND the shoulder, where the Deer's is under it: nothing of this
		-- leg gives, so the two forelegs must ask the same height of the body at the moment one lands, the one
		-- that lands as far ahead of its shoulder as the other is behind its own)
		centre = centre,
		-- in the air elbow and carpus fold together (the Deer's carpus leads by more: here that asked 37
		-- degrees of the fetlock, which bends 40); on the ground nothing folds (the carpus is locked) and
		-- nothing sinks: there is no pastern, and a hoof this long tilted about its toe would push its heel
		-- into the ground
		fold = { swing = { 0, 1.0, -1.25 }, skew = { 0, -0.2, 0.2 } },
		sink = 0,
		-- (it stands at 98% of its length with its carpus 15 to 17 degrees PAST straight: asked to lift, such a
		-- leg would snap its carpus in a frame. The Camel's forelegs)
		ease = true,
		-- (the hoof is a boot: its toe lies a quarter of the leg ahead of the fetlock. The Camel's long foot: it
		-- stays flat until late and rolls onto its toe only as far as keeps this leg asking what the other
		-- foreleg asks; in the air it hangs a little and is level again by the middle of the swing. The lift is
		-- LOW: this leg is three short pieces, a hundredth of lift is five degrees of elbow, and the elbow
		-- folds 60)
		lift = { walk = 0.035, trot = 0.045 },
		pitch = {
			stance = { 0, 0, 0.72, 0, 1, -0.18 },
			swing = { 0, -0.18, 0.25, -0.2, 0.5, -0.08, 0.85, 0.05, 1, 0 },
		},
	}
end

local function hind(id, name, chain, centre, tip)
	return {
		id = id,
		name = name,
		chain = chain,
		ankle = 4,
		front = 0.5,
		tip = tip,
		centre = centre,
		-- stifle and hock fold and open together, on the ground as in the air (the leg is a zigzag: it gives
		-- easily), the hock a touch earlier
		fold = { swing = { 0, -1.0, 0.95 }, stance = { 0, -1.0, 0.95 }, skew = { 0, -0.25, 0.25 } },
		sink = 0,
		-- (it stands on a deep zigzag a quarter of the leg behind its hip: at a start the leg that waits its
		-- turn opens as far as stifle and hock go, 17 degrees; walking steadily it does not open at all)
		open = 0.3,
		-- (lifted low and early: the thigh comes forward as the shank folds, and 40 degrees is the hip's reach)
		lift = { walk = 0.055, trot = 0.07 },
		liftSkew = 0.65,
		pitch = {
			stance = { 0, 0, 0.7, 0, 1, -0.25 },
			swing = { 0, -0.25, 0.35, -0.2, 0.8, 0.1, 1, 0 },
		},
	}
end

local CHAINS = Bloom.map.limbs
Bloom.legs = {
	fore("LF", "front left leg", CHAINS.LF.bones, 0.077, { below = 0.1535, ahead = 0.148 }),
	fore("RF", "front right leg", CHAINS.RF.bones, 0.087, { below = 0.1535, ahead = 0.167 }),
	hind("LH", "hind left leg", CHAINS.LH.bones, -0.045, { below = 0.1476, ahead = 0.128 }),
	hind("RH", "hind right leg", CHAINS.RH.bones, -0.045, { below = 0.1476, ahead = 0.128 }),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH): the Deer's ------------------------------------
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
		-- (shorter steps than the Deer's 0.62 of the leg: its hips turn inside a short body, 40 degrees each
		-- way is their reach. The Sphinx Cat's)
		sweep = 0.48,
		-- (sooner than a deer trots: it is small, the game's run is a Froude number of 0.4 only for its leg, and
		-- a walk at that speed is a shuffle of five and a half strides a second. The Camel's)
		from = 0.3,
		back = 0.2,
		shift = 0.4,
	},
	sweep = 0.46,
	finish = 0.25,
	-- (it squares up sooner than the Deer, whose 0.14 it was: it stands with its hind hooves a quarter of
	-- the leg behind its hips, and one that a stop left further back still stood on a leg stretched straight
	-- and was out of reach at the next start, so that the rump sat down)
	settle = { far = 0.05, time = 1.6, least = 2, mean = 4, most = 10 },
	comfy = 0.997,
	letGo = 0.55,
	comeDown = 0.6,
}

-- THE BODY, THE HEAD, THE TAIL ------------------------------------------------------------------------------
local LEVEL = 0.6 -- the share of the croup's rise over the withers that its hind legs take up
local RUMP_MOST = 0.02 -- shares of its leg the rump comes down for a hind hoof, at most
local HIP_DROP = 0.05 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02
local BREATH = 0.003 -- radians: barely there
-- (a fawn on watch: it looks about more often than a horse, and holds the look)
local LOOK =
	{ yaw = 0.8, up = 0.12, down = 0.18, turn = 0.38, least = 1.5, mean = 12, aside = 3.5, most = 36, home = 0.85 }
-- THE HEAD AS IT WAS MODELLED, and how far the skin lets it turn from there (docs/motion/pet_BloomSprite.md,
-- "How far each joint bends"; degrees, a positive yaw is to its left): what turns it straight, what each
-- of its two joints may do, and what both may do together.
local TURNED = rad(27) -- how far to its left the head was modelled
local NECK_STRAIGHT, HEAD_STRAIGHT = rad(-13), rad(-14) -- the turn that undoes it, as it was looked at
local YAW_RIGHT, YAW_LEFT = rad(30), rad(25) -- one joint, from the pose as modelled
local YAW_KNEE = rad(5) -- a joint's turn is curved over its last degrees, never stopped dead
local ALL_RIGHT, ALL_LEFT = rad(55), rad(45) -- neck and skull together (their limits are 60 and 50)
local MODELLED_LOOK = 0.5 -- the chance that a look to its left is the look it was modelled in
-- (past 45 degrees to its right of the modelled pose the head may not be lifted at all, or the tip of a
-- petal that is welded to the collar shows: a look far to its right comes with a small nod, never a lift)
local RIGHT_NOD = 0.035 -- radians
local RIGHT_FROM, RIGHT_FULL = rad(35), rad(43) -- where the lift goes out and the nod comes in, from the modelled pose
local TURN_LEAD = 0.3 -- radians its head goes into a turn before the body, at most
local NECK_SHARE = { 0.5 } -- of a look: neck and skull share it evenly
local HEAD_SHARE = { 0.5 }
-- (the tail is a bud of leaves on a thin stalk, where the Deer has a stub: it sways ON ITS STALK, and the
-- two joints in the bud follow by a few degrees, or the leaves curl like a rope)
local TAIL_SWING = 0.07 -- radians at the stalk, once a stride
local TAIL_LAG = 0.6 -- radians of the swing a joint is behind the one before
local TAIL_GAIN = 0.45 -- what a joint of the bud does of what the one before it does
local TAIL_UP = 0.3 -- radians the stalk lifts the bud when it trots off
local FLICK = 0.24 -- radians a flick of the tail goes to a side, at the stalk
local STALK_KNEE, STALK_MOST = rad(15), rad(19.5) -- the stalk bends 20 degrees to a side cleanly
local BUD_KNEE, BUD_MOST = rad(7), rad(9.8) -- a joint of the bud 10

-- A turn kept inside its two limits (`low` under 0, `high` over 0), curved over the last `knee` of each.
local function within(value, low, high, knee)
	if value < 0 then
		return Kit.bound(value, -low - knee, -low)
	end
	return Kit.bound(value, high - knee, high)
end

function Bloom.new(rig, info)
	local seed = info.seed or 0
	local legs = {}
	for k, spec in Bloom.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	-- how far it looks to each side OF STRAIGHT: as far as a fawn does, or as far as the skin lets it
	local base = STRAIGHT * (NECK_STRAIGHT + HEAD_STRAIGHT)
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0,
		root = rig.root,
		pelvis = Kit.bone(rig, "Body_01"),
		loin = Kit.bone(rig, "Body_02"),
		chest = Kit.bone(rig, "Body_03"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = Kit.chain(rig, "the tail"),
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 },
		toRight = math.min(1, (ALL_RIGHT + base) / LOOK.yaw),
		toLeft = math.min(1, (ALL_LEFT - base) / LOOK.yaw),
		tailTurn = { x = 0, v = 0 },
		flickAt = -100,
		flickSide = 1,
		flickNext = 4 + 14 * Kit.roll(dice),
	}
end

function Bloom.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	Kit.gait(W, dt, input)
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it (lowest as a hoof lands, highest over the middle of its
	-- stance: twice a stride, the two ends out of step). Its root is over the hips: the pitch turns about them.
	-- (THE RUMP NEVER SITS DOWN FOR A HOOF. It stands with its hind hooves a quarter of the leg behind its
	-- hips, all but at the end of their reach: in the first stride of every start the hind leg that waits its
	-- turn is left further back than a leg can be, and the kit then lowers the hips as far as they go, the
	-- whole rump onto its hocks. What a hind leg may ask is bounded: beyond it the leg opens straight and its
	-- hoof comes a little off its place for the moments until it lifts)
	local most = RUMP_MOST * W.h
	local front = -Kit.girdle(W, 1, 2)
	local back = -Kit.both(math.min(legs[3].drop, most), math.min(legs[4].drop, most))
	if back > front then
		back -= LEVEL * (back - front)
	end
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (the root is at the hips, but it breathes about its SHOULDERS: its forelegs stand straight on hooves
	-- that cannot give, the zigzag of the hind legs gives without showing it. The Camel's)
	local breath = BREATH * sin(t * TAU * 0.09 / tick + S.seed * TAU) * (1 - amount)
	local lean = pitch + breath
	pose.bob, pose.ox, pose.oz = bob - breath * (S.zRoot - S.zFront), 0, 0
	rx[S.root] = lean
	-- (the pelvis carries the loin and the chest: what it rolls, the loin rolls back, so that the chest stays
	-- level but for its own small drop)
	local hip = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local shoulder = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	rz[S.pelvis] = hip
	rz[S.loin] = -0.8 * hip
	rz[S.chest] = shoulder
	Kit.solve(W, pose)

	-- THE HEAD: the steadiest part, and here the heaviest (a ring of petals half the model wide: a degree at
	-- the skull shows at an ear's tip). The neck undoes ALL the trunk does, its lean and its roll (the Sphinx
	-- Cat's); it walks out of the turn it was modelled in and looks where it goes; standing, it is still and
	-- now and then looks somewhere, further to its left than to its right, and sometimes as it was modelled.
	local neck, head = S.neck, S.head
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	if gaze.t0 == t and gaze.y1 > 0 and STRAIGHT > 0 and Kit.roll(S.dice) < MODELLED_LOOK then
		gaze.y1, gaze.p1 = STRAIGHT * TURNED / S.toLeft, 0
	end
	yaw *= if yaw < 0 then S.toRight else S.toLeft
	-- (into a turn the head goes first)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -TURN_LEAD, TURN_LEAD) * amount, 5 / (tick / 0.29), 1, dt)
	local neckYaw = within(STRAIGHT * NECK_STRAIGHT + NECK_SHARE[1] * yaw, -YAW_RIGHT, YAW_LEFT, YAW_KNEE)
	local headYaw = within(STRAIGHT * HEAD_STRAIGHT + HEAD_SHARE[1] * yaw, -YAW_RIGHT, YAW_LEFT, YAW_KNEE)
	-- (far to its right it nods a little and never lifts)
	local right = Kit.smooth((-(neckYaw + headYaw) - RIGHT_FROM) / (RIGHT_FULL - RIGHT_FROM))
	look = math.min(look, look * (1 - right)) - RIGHT_NOD * right
	rx[neck[1]], ry[neck[1]], rz[neck[1]] = NECK_SHARE[1] * look - lean, neckYaw, -(shoulder + 0.2 * hip)
	rx[head[1]], ry[head[1]], rz[head[1]] = HEAD_SHARE[1] * look, headYaw, 0

	-- THE TAIL: the bud sways on its stalk once a stride and stays behind in a turn, its two joints following
	-- a little later and less (the Unicorn's tail, with a bud's small angles); it lifts when it trots off and,
	-- standing, flicks now and then, twice, quickly (the Deer's). It is never lowered.
	local tail = S.tail
	Kit.zero(pose, tail)
	Kit.chainWave(pose, tail, "y", TAIL_SWING * amount, TAU * (W.phase - 0.15), TAIL_LAG, TAIL_GAIN, BUD_MOST)
	Kit.chainBend(
		pose,
		tail,
		"y",
		Kit.spring(S.tailTurn, -0.05 * Kit.clamp(W.w, -2.5, 2.5), 4 / (tick / 0.29), 0.45, dt),
		TAIL_GAIN
	)
	Kit.chainBend(pose, tail, "x", -TAIL_UP * W.g * amount, TAIL_GAIN)
	if not W.moving and t >= S.flickNext then
		S.flickAt, S.flickSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.flickNext = t + Kit.wait(S.dice, 6, 16, 45)
	end
	local span, late = 1.25 * tick, 0.12 * tick
	Kit.chainPulse(pose, tail, "y", FLICK * S.flickSide, t, S.flickAt, span, late, TAIL_GAIN, STALK_MOST)
	Kit.chainPulse(pose, tail, "y", -FLICK * S.flickSide, t, S.flickAt + span * 1.1, span, late, TAIL_GAIN, STALK_MOST)
	ry[tail[1]] = Kit.bound(ry[tail[1]], STALK_KNEE, STALK_MOST)
	ry[tail[2]] = Kit.bound(ry[tail[2]], BUD_KNEE, BUD_MOST)
	ry[tail[3]] = Kit.bound(ry[tail[3]], BUD_KNEE, BUD_MOST)
end

return Bloom
