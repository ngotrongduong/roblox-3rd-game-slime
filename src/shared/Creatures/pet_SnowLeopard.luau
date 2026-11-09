-- Snow Leopard: the Panther's 29-joint tree on the Jade Tiger's long walk and trot, with each hind leg's own rest.
-- The chest holds the ice crystals; look and trunk compensation share three pivots through the fused ruff.
-- Frozen geometry and bend limits: docs/motion/pet_SnowLeopard.md, For the motion.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2 -- one whole stride in radians

local Cat = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Cat.map = {
	count = 29, -- frozen ready skeleton; every joint is assigned below
	tree = 58826663, -- Panther tree hash: identical names, parentage and file order
	-- Root is the service's handle between the hips: it drives nothing and everything hangs on it. Body_01
	-- is the PELVIS (the hind legs and the tail hang on it), Body_02 the CHEST, which turns at the loin: the
	-- shoulder crystals are rigid on it; neck and forelegs hang on it
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- a neck nobody sees from the front (the jaw lies on the collar): its base, its middle; then the base of
	-- the skull (face, ears and front cheek ruff are rigid on it)
	neck = { "Neck_01", "Neck_02" },
	head = { "Head" },
	-- Seven links along the hanging tail and its upward curl; the blue end is flexible fur.
	tail = { "Tail_01", "Tail_02", "Tail_03", "Tail_04", "Tail_05", "Tail_06", "Tail_07" },
	legs = {
		-- foreleg, from the body down: the SHOULDER (inside the chest: it aims the leg), the ELBOW (it points
		-- back and folds the forearm forward and up), the WRIST (at the top of the long paw: its bone is the
		-- back half of the paw), the TOES (in the ball of the paw)
		LF = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" },
		RF = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" },
		-- Hip, stifle, hock, paw. The last joint is 7.2% of rig height: below the kit's 12% gate.
		LH = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" },
		RH = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" },
	},
	-- Forelegs mirror about their own midpoint (+0.048), never the box; hind legs differ.
	pairs = { { "LF", "RF", "pair" } },
}

-- Sphinx stroll: Froude 0.06, rests 3..10 seconds, radius 0.9 of the plot.
-- Mean hip/shoulder height 0.267 divided by highest bone 0.442 gives its own leg share.
Cat.stroll = { froude = 0.06, leg = 0.267 / 0.442, rest = { 3, 10 }, radius = 0.9 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward. `tip` and
-- `centre` are shares of the RIG's height, which is 0.442 of the file's long side: the skull's joint is its highest)
local function fore(id, name, chain)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the wrist holds the paw against the ground, as the fox's one paw bone does; the toes are the
		-- module's own: `toes` below)
		ankle = 3, -- wrist, with the toes as the planted contact below it
		front = 0.5, -- half the stance reaches forward, half pushes back
		-- (the planted point is the ground under the ball of the paw: the back half rolls up about it)
		tip = { below = 0.023 / 0.442, ahead = 0 }, -- measured ball height; no extra forward offset
		-- (the wrist stands 0.005 ahead of the shoulder: centre is an OFFSET from that home, not from the hip)
		centre = 0, -- preserve the forepaw's modeled fore-aft track
		-- ONE joint folds, the elbow, in the air and (a little: the yield) on the ground
		fold = { swing = { 0, 1.0 }, stance = { 0, 1.0 } },
		sink = 0.05, -- inherited small wrist yield before the elbow takes a stance load
		-- (it stands bent 37 degrees: the inherited 0.17 rad opening leaves bend to spare)
		open = 0.17,
		-- (a leg at 94% length still benefits from the inherited easing at departure)
		ease = true,
		-- Keep the Sphinx lift: 0.10 walking, 0.095 trotting, with a late 0.95 rise.
		-- The longer forearm clears with the same inherited lift and late rise.
		lift = { walk = 0.1, trot = 0.095 },
		liftSkew = 0.95,
		-- the paw: flat, its back half rolling up over the toes as it leaves (the wrist of a straight leg rises
		-- and comes forward: just what such a leg needs at the end of its reach), hanging back in the air, flat
		-- again to land
		-- Curve pairs are phase/pitch radians: flat through 0.7 stance, heel up 0.25 at lift;
		-- swing hangs 0.35 at 0.42, toes up 0.06 at 0.85, flat at phase 1.
		pitch = { stance = { 0, 0, 0.7, 0, 1, -0.25 }, swing = { 0, -0.25, 0.42, -0.35, 0.85, 0.06, 1, 0 } },
	}
end

local function hind(id, name, chain, ahead, centre, lift, hock)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the paw is held against the ground; stifle and hock above it are the fox's)
		ankle = 4, -- heel joint holds the entire hind paw
		front = 0.5, -- half the stance reaches forward, half pushes back
		-- (the planted point: the ground under the toes, ahead of the paw's joint at its heel)
		tip = { below = 0.032 / 0.442, ahead = ahead }, -- each heel height and own toe reach, measured in file units
		-- Left heel stands 0.105 behind its hip, right heel 0.030: offset each own home, not the hip.
		centre = centre, -- offset from this leg's own modeled heel; never mirror the hind tracks
		-- stifle and hock fold and open together (never one without the other), on the ground as in the air
		fold = { swing = { 0, -1.0, hock }, stance = { 0, -1.0, hock } }, -- own shank/hock proportions
		sink = 0, -- the hind paw is one rigid lump, with no separate pastern yield
		open = 0.2, -- 11.5 degrees: safely below the modeled stifle bends of about 50
		-- Real zigzags allow the Sphinx lift; the right leg needs its own fold distribution.
		lift = { walk = lift, trot = 0.095 }, -- each zigzag leg folds from its own modeled reach
		-- the paw (a short flat lump, where the fox has hock to toes in one long bone): flat, then its heel
		-- rising through the second half of the stance (the push; less far than the fox's long foot), carried
		-- forward nearly level in the air (the leg above it swings 40 degrees forward, and the paw's joint
		-- bends 35 cleanly: the inherited small hang stays within it), its toes a little up as it
		-- reaches, flat to land
		-- Sphinx phase/pitch keys: flat until 0.35 stance, heel up 0.3 at phase 1;
		-- hang 0.2 at 0.35 swing, toes up 0.12 at 0.8, flat at phase 1.
		pitch = { stance = { 0, 0, 0.35, 0, 1, -0.3 }, swing = { 0, -0.3, 0.35, -0.2, 0.8, 0.12, 1, 0 } },
	}
end

Cat.legs = {
	fore("LF", "front left leg", Cat.map.legs.LF),
	fore("RF", "front right leg", Cat.map.legs.RF),
	hind("LH", "hind left leg", Cat.map.legs.LH, 0.075 / 0.442, -0.055, 0.11, 0.95), -- left: 0.075 toe reach, inherited 0.055 forward offset, 0.11 lift and 0.95 hock share
	hind("RH", "hind right leg", Cat.map.legs.RH, 0.085 / 0.442, 0, 0.14, 0.8), -- right: 0.085 toe reach, own home, 0.14 lift and 0.8 hock share bring hip reach to 25 degrees
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH) ---------------------------------------------------
local DESIGN = {
	start = 0.004, -- inherited Froude threshold to start stepping
	stop = 0.0015, -- lower threshold prevents stop/start chatter
	-- a walk in lateral sequence: left hind, left fore, right hind, right fore, a quarter of a stride apart
	-- (docs/MOTION.md, section 5: the cat's 0.25, where the fox has 0.22)
	walk = {
		offsets = { 0.25, 0.75, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 }, -- inherited slow fall with speed; two or three paws down
		-- (the fox's: under its stroll it keeps its cadence and takes shorter steps)
		stride = { 3.3, 0.5 },
	},
	-- a trot, its travelling gait: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.4, slope = 0.05, ref = 1, least = 0.34, most = 0.46 }, -- inherited diagonal stance with flight
		stride = { 2.3, 0.3 }, -- Sphinx stride law, leg-scaled Froude power
		-- Full Jade Tiger sweep: 0.5 leg during stance; own shoulder and hip limits still allow it.
		sweep = 0.5,
		from = 0.32, -- inherited Froude change up to diagonal trot
		back = 0.22, -- inherited lower change-down threshold
		shift = 0.35, -- inherited seconds to blend the footfall phases
	},
	sweep = 0.52, -- full Sphinx walk stance travel in leg lengths
	finish = 0.25, -- inherited clock speed to finish a swing after stopping
	settle = { far = 0.14, time = 1.5, least = 2, mean = 5, most = 14 }, -- inherited home-step distance and tick-scaled timing
	-- (with its forelegs opened as far as they go, a leg that hangs comfortably is still as long as it
	-- stands: it stands exactly as it was modelled)
	comfy = 0.999, -- explicit: nearly the opened length, so the square stand needs no crouch
	letGo = 0.6, -- inherited release over the first 60% of a swing
	comeDown = 0.4, -- inherited landing sink begins at 40% of swing
}

-- THE BODY, THE HEAD, THE TAIL -------------------------------------------------------------------
local WALK_BOB = 0.016 -- shares of its leg an end sinks at each paw's landing, walking
local TROT_BOB = 0.035 -- ... and over the middle of each stance, trotting
local HIP_DROP = 0.06 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02 -- ... and the chest for a foreleg (the ice crystals ride on it)
local HIP_YAW = 0.05 -- radians the pelvis turns to bring a hind leg forward, once a stride
local CHEST_YAW = 0.025 -- ... and the chest for a foreleg
local BREATH = 0.002 -- radians: inherit the Jade Tiger's quiet breath to preserve the one-degree rest check
-- Ruff and nape crystal limit every neck pivot: keep the Sphinx look (0.6 yaw, 0.08 up, 0.12 down),
-- eased over 0.45 seconds; pauses 2/14/40, aside after 3, home chance 0.9 are its unchanged gaze law.
local LOOK = { yaw = 0.6, up = 0.08, down = 0.12, turn = 0.45, least = 2, mean = 14, aside = 3, most = 40, home = 0.9 }
local ASIDE = { 1.4, 2.6, 7 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.09, 0.4 -- radians it cocks its head as it looks at something, and how often it does
-- (fused ruff: compensation, look and cock all share exactly one third per pivot)
local NECK_SHARE = { 1 / 3, 1 / 3 }
local HEAD_SHARE = { 1 / 3 }
local TURN_LEAD = 0.3 -- radians its head goes into a turn before the body, at most
local TAIL_SWING = 0.1 -- radians its root swings the tail to a side, once a stride
local TAIL_RATE = 3.4 -- how quickly a bone of the tail follows the one before (in units of sqrt(G / leg))
local TAIL_DAMP = 0.5 -- inherited spring damping, to follow without a stiff wag
local TAIL_MOST = 0.17 -- 9.7 degrees: below the ten-degree summed-chain trial, keeping every link inside the combined-chain yaw trial
local SWISH = 0.2 -- radians its root swings the tail in one swish, standing

-- THE TOES OF A FOREPAW (the kit holds a foot of one bone; this paw has a second joint in its ball). While
-- the wrist's bone rolls up about the ball, the toes stay flat on the ground; in the air they let go a
-- little over the first quarter of the swing and hang a little with the paw (all the way, and their tips
-- would be the lowest of the paw: they would drag).
local TOES_HANG = 0.4 -- the share of the paw's hang its toes take in the air

-- Skin-safe curves, not clamps: the last tenth of each permitted bend eases toward
-- the frozen limit. The kit solver can ask too much during a direct fast departure or
-- a gait change; steady stride angles lie below these knees and keep their full travel.
-- Fore rows: shoulder ±50, elbow -20/+60, wrist -60/+30, toes ±35, from the frozen bend table.
local FORE_BENDS = { { -50, 50 }, { -20, 60 }, { -60, 30 }, { -35, 35 } }
local RIGHT_FORE_BENDS = { { -40, 50 }, { -20, 60 }, { -60, 30 }, { -35, 35 } } -- right shoulder clean only to 40 back
-- Hind rows: own hip back/forward limits, stifle -60/+20, hock -40/+60, paw ±35, from that same table.
local HIND_BENDS = { { -40, 60 }, { -60, 20 }, { -40, 60 }, { -35, 35 } } -- left hip meets tail beyond 40 back
local RIGHT_HIND_BENDS = { { -50, 50 }, { -60, 20 }, { -40, 60 }, { -35, 35 } } -- right hip forward bound is 50
local function bend(value, low, high)
	local most = math.rad(if value < 0 then -low else high)
	return Kit.bound(value, 0.9 * most, most) -- final 10% is the exponential approach, with continuous slope
end
local function safeLeg(pose, leg, bounds)
	for j, i in leg.b do
		pose.rx[i] = bend(pose.rx[i], bounds[j][1], bounds[j][2])
	end
	local top, foot = leg.b[1], leg.b[leg.ankle]
	local low, high = if leg.side < 0 then -30 else -20, if leg.side < 0 then 20 else 30
	pose.rz[top] = bend(pose.rz[top], low, high) -- 30 out, 20 in: the wide modeled tracks
	pose.rz[foot] = -pose.rz[top] -- the paw stays level across its width under that softened lean
end

function Cat.new(rig, info)
	local seed = info.seed or 0 -- deterministic default individual clock
	local legs = {}
	for k, spec in Cat.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local tail = Kit.chain(rig, "the tail")
	local follow = Kit.springRow(#tail)
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0, -- starts in the modeled square stand
		root = rig.root,
		pelvis = Kit.bone(rig, "Body_01"),
		chest = Kit.bone(rig, "Body_02"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = tail,
		follow = follow,
		-- (which paw it sets off with from a square stand: a hind one, the left or the right by its own seed)
		lead = Kit.lead(seed),
		-- Pair means: the two fore and two hind hips define where the body rides.
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 }, -- turn-lead spring starts at rest
		tilt = 0, -- no cock until the first aside
		tiltFrom = 0, -- eased cock begins straight
		tiltTo = 0, -- first target is straight
		tiltAt = -100, -- sentinel: no look has begun
		swishAt = -100, -- sentinel: no swish is active
		swishSide = 1, -- initial rightward sign, redrawn at the first swish
		swishNext = 5 + 20 * Kit.roll(dice), -- first swish after 5..25 seconds, as the Sphinx
	}
end

function Cat.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	local stoodUp = W.fresh or input.jump or dt <= 0 or dt > 0.4 -- match the kit's reset after a long frame
	Kit.gait(W, dt, input)
	if stoodUp then
		Kit.leadFeet(W, S.lead, input.yaw)
	end
	S.phase = W.phase
	local amount = W.amount

	-- THE BODY: each end rides on the legs under it. The rump drops on the side whose hind leg is in the air
	-- and turns to bring it forward; the chest does the same, less, for a foreleg. The chest hangs ON the
	-- pelvis here, so it is given its own turn less the pelvis's: its one joint, at the loin, is where the
	-- back bends from side to side.
	local g = Kit.smooth(W.g)
	local front = -Kit.both(Kit.girdle(W, 1, 2), Kit.ride(W, g, legs[1].phi, WALK_BOB, TROT_BOB, 0))
	local back = -Kit.both(Kit.girdle(W, 3, 4), Kit.ride(W, g, legs[3].phi, WALK_BOB, TROT_BOB, 0))
	local bob, pitch = Kit.carry(front, back, S.zFront, S.zHind, S.zRoot)
	-- (the root is at the hips, but it breathes about its SHOULDERS: its forelegs stand straight and would
	-- tick their elbows with every breath, the hind knees give without moving the fore wrist. The Camel's)
	-- Sphinx breath: 0.1 cycles per tick; seed shifts its individual starting breath.
	local breathAt = t * TAU * 0.1 / tick + S.seed * TAU
	local breath = BREATH * sin(breathAt) * (1 - amount)
	local lean = Kit.bound(pitch + breath, math.rad(10), math.rad(12)) -- transient ride bends smoothly; steady see-saw stays intact
	pose.bob, pose.ox, pose.oz = bob - breath * (S.zRoot - S.zFront), 0, 0
	rx[S.root] = lean
	local hipYaw = -HIP_YAW * amount * cos(TAU * legs[3].phi)
	local chestYaw = -CHEST_YAW * amount * cos(TAU * legs[1].phi)
	local hipDrop = HIP_DROP * (Kit.lifted(legs[3]) - Kit.lifted(legs[4]))
	local chestDrop = SHOULDER_DROP * (Kit.lifted(legs[1]) - Kit.lifted(legs[2]))
	rz[S.pelvis], ry[S.pelvis] = hipDrop, hipYaw
	rz[S.chest], ry[S.chest] = chestDrop - hipDrop, chestYaw - hipYaw
	Kit.solve(W, pose)
	for k, leg in legs do
		safeLeg(
			pose,
			leg,
			if k == 1
				then FORE_BENDS
				elseif k == 2 then RIGHT_FORE_BENDS
				elseif k == 3 then HIND_BENDS
				else RIGHT_HIND_BENDS
		) -- first pair fore, second pair hind
	end
	-- Inherited quarter-swing toe release; -0.5/+0.6 rad lies inside the ±35-degree toes bound.
	Kit.toes(pose, legs[1], TOES_HANG, 0.25, -0.5, 0.6)
	Kit.toes(pose, legs[2], TOES_HANG, 0.25, -0.5, 0.6)

	-- THE HEAD: the steadiest part, and here the heaviest. The neck undoes ALL the trunk does (its lean, the
	-- chest's turn and roll), so the head stands still over a body that walks; standing, it is still and now
	-- and then looks somewhere.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	-- Equal thirds undo the trunk through the ruff; no neck pivot bears the correction alone.
	Kit.spread(pose, neck, NECK_SHARE, -lean, -chestYaw, -chestDrop)
	Kit.spread(pose, head, HEAD_SHARE, -lean, -chestYaw, -chestDrop)
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	Kit.asideHold(gaze, t, S.dice, LOOK.turn, ASIDE)
	-- Sphinx turn lead: 0.3 seconds ahead, spring rate 5 at a reference tick of 0.29, damping 1.
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -TURN_LEAD, TURN_LEAD) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)
	-- (now and then, as it looks at something, it cocks its head a little, and holds that as long as the look)
	local cock = Kit.cock(S, t, W.moving, LOOK.turn, TILT, TILT_CHANCE)
	Kit.spread(pose, neck, NECK_SHARE, 0, 0, cock)
	Kit.spread(pose, head, HEAD_SHARE, 0, 0, cock)

	-- THE TAIL (the Fox's brush, on seven joints): its root swings it from side to side once a stride; every
	-- bone after it follows the one before on a spring, a little later and a little further, and goes on
	-- after the cat has stopped. In a turn it stays behind. It rises during travel to keep the low
	-- modeled curl above the ground as the trunk rides down; no joint pitches downward or twists.
	local tail, follow = S.tail, S.follow
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 8, 20, 50) -- inherited minimum/mean/maximum seconds between swishes
	end
	-- Inherited half-strength wag at trot, 0.1 stride late, and a swish pulse of five ticks.
	local lead = hipYaw
		+ TAIL_SWING * amount * (1 - 0.5 * W.g) * sin(TAU * (W.phase - 0.1))
		+ SWISH * S.swishSide * Kit.pulse(t, S.swishAt, 5 * tick)
	Kit.chainFollow(
		pose,
		tail,
		follow,
		lead,
		hipYaw,
		TAIL_RATE / tick,
		TAIL_DAMP,
		TAIL_MOST,
		W.w * math.min(dt, 0.1), -- limit the turn-slip integration to a tenth-second frame
		dt,
		input.jump
	)
	-- Lift only: 0.5 rad (28.6 degrees) at full travel gives the low tail room over the riding trunk.
	rx[tail[1]] = -0.5 * amount
end

return Cat
