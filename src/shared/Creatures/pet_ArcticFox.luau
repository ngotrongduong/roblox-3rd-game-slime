-- The Arctic Fox of the Peaks (art/models/ready/pet_ArcticFox.glb, 37 bones, a skeleton written here: a small
-- white fox with a head as big as its trunk on a ruff, short legs, and THREE bushy tails as big as the rest of
-- it). Its joint map, and the MOTION OF THE FAIRY FOX (pet_FairyFox.luau: its gait, its head, its tail of
-- springs) on the leg of the finished cats (pet_JadeTiger.luau: the same names and tree of four joints a leg),
-- changed only where this body is another: it stands in a step (no leg mirrors: every leg has its own rest
-- numbers, as the Panther's), its forelegs stand straight, a hip may go only 30 degrees back (the thigh enters
-- the side tail), and the tail is three. docs/motion/pet_ArcticFox.md says where and why ("For the motion" is
-- the frozen geometry and the bend table). Look at art/models/rigs/pet_ArcticFox_left.png beside this file.
-- Space: +x its right, +y up, it looks along -z.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, pi = math.sin, math.cos, math.pi
local TAU = pi * 2 -- one whole stride in radians

local Fox = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Fox.map = {
	count = 37, -- the frozen ready skeleton; every joint is named below
	tree = 608736264, -- the print of that skeleton's tree (names and parents)
	-- Root is the handle on the pelvis: it drives nothing and everything hangs on it. Body_01 is the PELVIS
	-- (the hind legs and the three tails hang on it), Body_02 the CHEST, which turns at the loin (the forelegs
	-- and the neck hang on it)
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- the foot of the neck inside the ruff, its thinnest place; then the base of the skull (skull, muzzle,
	-- both ears and the fan of cheek fur are one rigid lump on it: 617 vertices)
	neck = { "Neck_01", "Neck_02" },
	head = { "Head" },
	-- the MIDDLE tail, which stands up behind the rump: its stalk, where the brush begins, three up the brush
	tail = { "Tail_01", "Tail_02", "Tail_03", "Tail_04", "Tail_05" },
	legs = {
		-- foreleg, from the body down: the SHOULDER (inside the chest: it aims the leg), the ELBOW (where the
		-- leg leaves the chest: it folds the forearm back), the WRIST (the thinnest place over the paw: it folds
		-- the short pastern forward), the TOES (at the heel of the paw: the paw follows it). The last joint is 6% of the rig's height over
		-- the ground: under the kit's 12%, so all four are `legs`
		LF = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" },
		RF = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" },
		-- hind leg: the HIP (inside the rump), the STIFLE (the knee, its knob forward), the HOCK (it points
		-- back), the PAW (at its heel)
		LH = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" },
		RH = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" },
	},
	-- the two SIDE tails, which leave the rump sideways and back and curl up: chains with the role of a tail
	-- (the map has one `tail`; the Hippocampus's fins and the Parrot's plumes are written so)
	limbs = {
		tailLeft = {
			role = "tail",
			bones = { "TailLeft_01", "TailLeft_02", "TailLeft_03", "TailLeft_04", "TailLeft_05" },
		},
		tailRight = {
			role = "tail",
			bones = { "TailRight_01", "TailRight_02", "TailRight_03", "TailRight_04", "TailRight_05" },
		},
	},
	-- (no `pairs`: it stands in a step, the right legs 0.02 and 0.09 further forward than the left, and the
	-- two side tails are no twins: nothing below the body is the mirror of its twin)
}

-- HOW IT STROLLS in its plot: the Fairy Fox's light walk (Froude 0.06, rests of 3 to 10 seconds, 0.9 of the
-- plot). Its leg: the four top joints are 0.3155 up on average, the highest bone (the middle tail's tip joint)
-- 0.666.
Fox.stroll = { froude = 0.06, leg = 0.3155 / 0.666, rest = { 3, 10 }, radius = 0.9 }

-- THE LEGS --------------------------------------------------------------------------------------------------
-- (fold: radians each joint turns for one radian of fold, + tips the joint's lower end forward. `tip` and
-- `centre` are shares of the RIG's height, 0.666 in the units of the file.)
-- The chains are the Jade Tiger's (four joints, the same names), the hind leg's shape is its too; the numbers
-- of gait, lift and timing are the Fairy Fox's. Each leg has its own `below`, `ahead` and `centre`, read from
-- the skeleton: the model stands in a step.
local function fore(id, name, chain, below, ahead, centre)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the PAW is held against the ground, as the hind one and as the Fairy Fox's: elbow and wrist above it
		-- fold. NOT the Tiger's foreleg, whose wrist holds a long paw and whose elbow alone folds: tried, and
		-- this straight column then has nothing to give: its elbow stood bent 29 degrees through the first
		-- third of every stance and snapped 22 degrees in a frame)
		ankle = 4,
		front = 0.5, -- half the stance reaches forward, half pushes back
		-- (the planted point: the ground under the toes' tip, ahead of the paw's joint at its heel. Rolling up
		-- on it is the only way this leg gets longer)
		tip = { below = below, ahead = ahead },
		-- (it stands with its paws' joints 0.015 to 0.02 ahead of its shoulders: walking, they step under them)
		centre = centre,
		-- elbow (back) and wrist (forward) fold and open together, on the ground as in the air: the hind leg's
		-- shares. The wrist stands bent 23 degrees that way, so the leg gets shorter from the first degree of
		-- fold and gives smoothly under the body; looked at folded -70 / +50 (stage A's stride sheet): clean
		-- (0.85 of the elbow at the wrist, where the hind leg has 0.95: at 0.95 the wrist came to 58 degrees in a
		-- walk, and 60 is all it has)
		-- ON THE GROUND ONLY THE WRIST GIVES (the Camel's idea: its carpus is locked and its pastern sinks):
		-- with the elbow in the stance's fold too, the column stood on an elbow bent 20 to 34 degrees for half
		-- of every stance, whatever the paw's place and curve. The wrist alone takes 3.5% of the leg in 20
		-- degrees, which is all the chest ever comes down
		fold = { swing = { 0, -1.0, 0.85, 0 }, stance = { 0, 0, 1.0, 0 } },
		sink = 0, -- the paw is one lump: no pastern under the held joint
		-- (shoulder, elbow and wrist stand over each other to 0.01, and opening the fold bends the elbow the
		-- other way, which makes the leg SHORTER: a forepaw cannot reach further than it stands)
		open = 0,
		-- (a leg that stands at its full length: its fold is eased in and out at the two ends of a swing, the
		-- Camel's)
		ease = true,
		-- (shares of the leg; under the Fairy Fox's 0.1 and 0.12: its legs stand bent, and this column needs 60
		-- degrees of elbow for a tenth. The paw leaves with its heel already 7% up: this comes on top of it)
		lift = { walk = 0.055, trot = 0.06 },
		-- (the paw is highest at 0.45 of its swing, not at the kit's 0.40: the fold of an eased leg comes in over
		-- the first 0.18 of the swing and goes out over the last 0.22, and with the height as great at one end
		-- as at the other neither end turns the elbow more than it must in a frame. At the Tiger's 0.95 the
		-- landing end snapped)
		liftSkew = 0.84,
		-- the paw (phase, radians against the ground; the Fairy Fox's curve, sooner and further up on its toes):
		-- flat through 0.55 of the stance, its heel 0.1 up at 0.8 and 0.25 as it leaves (the Fairy Fox's: flat
		-- to 0.75, then 0.15. This leg cannot get longer, and behind its shoulder a paw is reached only by
		-- rolling up on its toes: 0.25 rad lifts the paw's joint 7% of the leg, what the leg lacks at the end
		-- of its stance, and 0.1 what it lacks at 0.8 of it; sooner or further, and the leg folds to make room
		-- for the heel),
		-- carried forward nearly level (0.2 down at 0.45, where the Fairy Fox's long hand hangs 0.8: at 0.8
		-- this paw's joint came to 59 degrees of its 60, and every degree its toes hang is paid in elbow, to
		-- keep them off the ground: 65 degrees at 0.35), its toes a little up (0.1 at 0.85) as it reaches,
		-- flat to land
		pitch = {
			stance = { 0, 0, 0.55, 0, 0.8, -0.1, 1, -0.25 },
			swing = { 0, -0.25, 0.45, -0.2, 0.85, 0.1, 1, 0 },
		},
	}
end

local function hind(id, name, chain, below, ahead, centre)
	return {
		id = id,
		name = name,
		chain = chain,
		-- (the paw is held against the ground; stifle and hock above it fold, as the Fairy Fox's)
		ankle = 4,
		front = 0.5, -- half the stance reaches forward, half pushes back
		-- (the planted point: the ground under the toes' tip, ahead of the paw's joint at its heel)
		tip = { below = below, ahead = ahead },
		-- (it stands with its hind paws behind its hips, the left one far behind: walking, they step under them)
		centre = centre,
		-- stifle (back) and hock (forward) fold and open together, on the ground as in the air (the Fairy
		-- Fox's shares; looked at folded -60 / +55: clean)
		fold = { swing = { 0, -1.0, 0.95 }, stance = { 0, -1.0, 0.95 } },
		sink = 0, -- the paw is one lump: no pastern to give
		-- (radians: the stifle stands bent 25 to 29 degrees and may open 17 of them to reach. At the Fairy
		-- Fox's 0.2 the right paw was out of reach at the end of every stance)
		open = 0.3,
		-- (under the Fairy Fox's 0.09 and 0.11: at those the hock came to 54 degrees walking, and 60 is its limit)
		lift = { walk = 0.07, trot = 0.095 },
		-- the paw, a short flat lump (the Tiger's curve, not the Fairy Fox's long foot's): flat to 0.35 of the
		-- stance, its heel rising 0.3 to the end; carried nearly level in the air (0.2 down at 0.35), its
		-- toes 0.12 up at 0.8 as it reaches, flat to land. The paw's joint bends 60 that way and 45 the other
		pitch = { stance = { 0, 0, 0.35, 0, 1, -0.3 }, swing = { 0, -0.3, 0.35, -0.2, 0.8, 0.12, 1, 0 } },
	}
end

Fox.legs = {
	-- (the left forepaw's joint is 0.037 over the ground, its toes' tip 0.079 ahead of the joint; the right
	-- one's 0.041 and 0.071 (its toes point inward). Both step 0.057 behind where they stand: 0.02 would put
	-- the middle of the stance under the shoulder, and then the chest came down 3.4% of the leg at every
	-- landing for a paw this leg cannot reach, and the leg that stood folded its elbow 34 degrees under it.
	-- A quarter of the stance in front of the shoulder, three quarters behind it, where the toes give the reach)
	fore("LF", "front left leg", Fox.map.legs.LF, 0.037 / 0.666, 0.079 / 0.666, 0.057 / 0.666),
	fore("RF", "front right leg", Fox.map.legs.RF, 0.041 / 0.666, 0.071 / 0.666, 0.057 / 0.666),
	-- (the left hind paw: its joint 0.042 up, its toes' tip 0.076 ahead of the joint, and it stands STRETCHED,
	-- 0.109 behind its hip. Its step is 0.04 ahead of where it stands, not the 0.10 that would put it under
	-- its hip: every turn is counted from the modelled pose, and stepping there the hip went 45 degrees
	-- forward, into the belly (41 at 0.055). The right one: 0.045 up, its toes (turned out) 0.057 ahead,
	-- 0.041 behind its hip: its step is 0.02 ahead of where it stands. This leg is all but straight (it can get
	-- 3% longer, no more): stepping where it stands it was out of reach behind, 0.04 ahead in front, by 1.1%
	-- of the leg either way, and 0.055 ahead by 1.6%)
	hind("LH", "hind left leg", Fox.map.legs.LH, 0.042 / 0.666, 0.076 / 0.666, -0.04 / 0.666),
	hind("RH", "hind right leg", Fox.map.legs.RH, 0.045 / 0.666, 0.057 / 0.666, -0.02 / 0.666),
}

-- THE GAITS (the legs in the order above: LF, RF, LH, RH): the Fairy Fox's -----------------------------------
local DESIGN = {
	start = 0.004, -- the Froude number at which it starts to step
	stop = 0.0015, -- ... and stops: lower, so that it does not chatter
	-- a walk in lateral sequence: left hind, left fore, right hind, right fore (the fox's 0.22 of a stride
	-- from a hind paw to the fore paw of its side)
	walk = {
		offsets = { 0.22, 0.72, 0, 0.5 },
		duty = { at = 0.62, slope = 0.03, ref = 0.35, least = 0.58, most = 0.66 }, -- two or three paws down
		-- (stride = 3.3 x leg x sqrt(Froude): under its stroll it keeps its cadence and takes shorter steps)
		stride = { 3.3, 0.5 },
	},
	-- a trot, its travelling gait: the diagonal pairs land and leave together, with a flight between
	trot = {
		offsets = { 0.5, 0, 0, 0.5 },
		duty = { at = 0.4, slope = 0.05, ref = 1, least = 0.34, most = 0.46 }, -- a flight between the pairs
		stride = { 2.3, 0.3 }, -- stride = 2.3 x leg x Froude^0.3
		-- (the most a paw travels on the ground in a trot's stance, in leg lengths. Under the Fairy Fox's 0.58:
		-- at 0.58 a hip went 44 degrees forward, into the belly, and the right hind paw, which stands under
		-- its hip, was out of reach by 3% of the leg at the end of every stance; at 0.46 still by 2%, and it
		-- landed late: the two pairs were 0.453 of a stride apart)
		sweep = 0.42,
		from = 0.32, -- the Froude number at which it changes up
		back = 0.22, -- ... and down again
		shift = 0.35, -- seconds the change of footfalls takes
	},
	-- (the most a paw travels on the ground in a walk's stance, in leg lengths. Under the Fairy Fox's 0.52, and
	-- so a little quicker: the right hind leg, all but straight, was out of reach by 1.1% of the leg)
	sweep = 0.48,
	finish = 0.25, -- the clock's pace at which a step is finished when it stops
	settle = { far = 0.14, time = 1.5, least = 2, mean = 5, most = 14 }, -- a paw left far from home steps back
	-- (the kit has no default. The forelegs stand straight: a leg that hangs comfortably is as long as it
	-- stands, so it stands exactly as it was modelled; the Fairy Fox's 0.995 would bend wrists and knees, and
	-- at the Tiger's 0.999 a joint stood turned 1.4 degrees)
	comfy = 0.9997,
	letGo = 0.6, -- the body rises from a paw that left over the first 60% of its swing
	comeDown = 0.4, -- ... and comes down for its landing from 40% of it on
}

-- THE BODY, THE HEAD, THE TAILS (the Fairy Fox's numbers, but for those marked) ------------------------------
local WALK_BOB = 0.016 -- shares of its leg an end sinks at each paw's landing, walking
local TROT_BOB = 0.035 -- ... and over the middle of each stance, trotting
local HIP_DROP = 0.06 -- radians the rump drops on the side whose hind leg is in the air
local SHOULDER_DROP = 0.02 -- ... and the chest for a foreleg
local HIP_YAW = 0.05 -- radians the pelvis turns to bring a hind leg forward, once a stride
local CHEST_YAW = 0.025 -- ... and the chest for a foreleg
-- (under the Fairy Fox's 0.003, and about the SHOULDERS: straight forelegs would tick their elbows with every
-- breath; the hind knees give without it showing. The Camel's, the Tiger's)
local BREATH = 0.0015 -- radians: barely there (at 0.002 a hind joint turned 1.03 degrees with every breath)
-- (a hunter on watch: still for long; now and then one quick look aside, held a few seconds, and back. 0.6 rad
-- of yaw is 34 degrees: with the lead into a turn below, 52 over the three joints, under the 60 of the table)
local LOOK = { yaw = 0.6, up = 0.14, down = 0.12, turn = 0.36, least = 2, mean = 14, aside = 3, most = 40, home = 0.9 }
local ASIDE = { 1.4, 2.6, 7 } -- seconds a look aside is held: at least, on average, at most
local TILT, TILT_CHANCE = 0.2, 0.4 -- radians it cocks its head as it looks at something, and how often it does
-- (NOT the Fairy Fox's 0.14 / 0.24 / 0.62: there the skull took 0.62 of 57 degrees, and this Head yaws 30
-- cleanly. A big rigid head on a ruff: every turn is shared in thirds over the three joints, as the Tiger's;
-- three times 20 of yaw was looked at and is good)
local NECK_SHARE = { 1 / 3, 1 / 3 }
local HEAD_SHARE = { 1 / 3 }
local TURN_LEAD = 0.3 -- radians its head goes into a turn before the body, at most (the Fairy Fox's 0.4: 57 in all)
local TAIL_SWING = 0.1 -- radians its root swings the tails to a side, once a stride
local TAIL_RATE = 3.4 -- how quickly a bone of a tail follows the one before (in units of sqrt(G / leg))
local TAIL_DAMP = 0.5 -- under 1: it swings past a little and goes on after the fox has stopped
-- (the Fairy Fox's 0.3 is 17 degrees a joint: here five times 10 was looked at and is good, five times 20
-- crosses the brushes. 9.7 degrees a joint, 49 over the five: under the 50 of the table)
local TAIL_MOST = 0.17
local SWISH = 0.24 -- radians its root swings the tails in one swish, standing (all three: never one alone)
-- THE SIDE TAILS follow the middle one, joint for joint, a little later: 3 per sqrt(leg / G) is a lag of a
-- third of that unit, a tenth of a walking stride (which is 3.3 of them)
local SIDE_RATE = 3
-- ... and never far from it: what a side tail's joint differs from the middle tail's by is eased towards 2.9
-- degrees (unchanged up to 1.7). Five joints of it move a tip as 9 degrees at the stalk would; the brushes
-- touch at 15
local SIDE_KNEE, SIDE_MOST = 0.03, 0.05

-- SKIN-SAFE CURVES, NOT CLAMPS (the Tiger's): the last tenth of each permitted bend eases towards the limit of
-- the bend table and never reaches it. A steady stride lies under these knees and keeps its full travel; a
-- direct fast departure or a change of gait can ask more.
-- Fore: shoulder 45 both ways, elbow -70 / +60, wrist 60, toes 60.
local FORE_BENDS = { { -45, 45 }, { -70, 60 }, { -60, 60 }, { -60, 60 } }
-- Hind: the hip only 30 BACK (the thigh enters the side tail of its side) and 45 forward (the belly), stifle
-- 60, hock 60, the paw 60 down and 45 up (the toes enter the shank).
local HIND_BENDS = { { -30, 45 }, { -60, 60 }, { -60, 60 }, { -60, 45 } }
-- Roll (the lean of a leg's top joint to reach a paw that is not under it; + swings a LEFT leg inward): a
-- shoulder 10 inward and 20 outward, a hip 10 both ways; not their own 40 outward: the paw under each is turned
-- back by as much to lie flat, and a forepaw's joint rolls 20, a hind paw's 10.
local FORE_ROLL = { 10, 20 } -- inward, outward
local HIND_ROLL = { 10, 10 }
local function bend(value, low, high)
	local most = math.rad(if value < 0 then -low else high)
	return Kit.bound(value, 0.9 * most, most) -- the last 10% is the eased approach, with no corner
end
local function safeLeg(pose, leg, bounds, roll)
	for j, i in leg.b do
		pose.rx[i] = bend(pose.rx[i], bounds[j][1], bounds[j][2])
	end
	local top, foot = leg.b[1], leg.b[leg.ankle]
	local low, high = if leg.side < 0 then -roll[2] else -roll[1], if leg.side < 0 then roll[1] else roll[2]
	pose.rz[top] = bend(pose.rz[top], low, high)
	pose.rz[foot] = -pose.rz[top] -- the paw stays level across its width under that softened lean
end

-- A SIDE TAIL (local: the kit's `chainFollow` leads one chain by a root; this follows another CHAIN joint for
-- joint). Each joint goes after the middle tail's joint of the same place, later by `share` of the way a
-- frame, and is never further from it than SIDE_MOST. `lag`: one number a joint, kept with the fox.
local function sideTail(pose, chain, lag, middle, share, reset)
	for k, i in chain do
		local want = pose.ry[middle[k]]
		if reset then
			lag[k] = want
		end
		lag[k] += (want - lag[k]) * share
		pose.rx[i], pose.ry[i], pose.rz[i] = 0, want + Kit.bound(lag[k] - want, SIDE_KNEE, SIDE_MOST), 0
	end
end

function Fox.new(rig, info)
	local seed = info.seed or 0 -- its own clock; 0 when nobody gives one
	local legs = {}
	for k, spec in Fox.legs do
		legs[k] = Kit.leg(rig, spec)
	end
	local W = Kit.walker(rig, DESIGN, legs, seed)
	local dice = Kit.dice(seed)
	local tail = Kit.chain(rig, "the tail")
	return {
		pose = Kit.newPose(rig),
		walker = W,
		dice = dice,
		seed = seed,
		phase = 0, -- it starts in the stand it was modelled in
		root = rig.root,
		pelvis = Kit.bone(rig, "Body_01"),
		chest = Kit.bone(rig, "Body_02"),
		neck = Kit.chain(rig, "the neck"),
		head = Kit.chain(rig, "the head"),
		tail = tail,
		tailLeft = Kit.chain(rig, "tailLeft"),
		tailRight = Kit.chain(rig, "tailRight"),
		follow = Kit.springRow(#tail),
		lagLeft = table.create(#tail, 0), -- the side tails start where the middle one is: straight
		lagRight = table.create(#tail, 0),
		-- (which paw it sets off with from a stand: a hind one, the left or the right by its own seed)
		lead = Kit.lead(seed),
		-- the means of each pair's top joints: where the body rides
		zFront = (legs[1].hipZ + legs[2].hipZ) / 2,
		zHind = (legs[3].hipZ + legs[4].hipZ) / 2,
		zRoot = rig.pz[rig.root],
		gaze = Kit.newGaze(),
		lookTurn = { x = 0, v = 0 }, -- the spring of the lead into a turn, at rest
		tilt = 0, -- no cock until the first look aside
		tiltFrom = 0,
		tiltTo = 0,
		tiltAt = -100, -- long ago: no look has begun
		swishAt = -100, -- long ago: no swish is under way
		swishSide = 1, -- drawn again at the first swish
		swishNext = 5 + 20 * Kit.roll(dice), -- the first swish after 5 to 25 seconds
	}
end

function Fox.step(S, dt, input)
	local W, pose = S.walker, S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local legs = W.legs
	local t = input.t
	local tick = W.tick

	-- THE FEET
	local stoodUp = W.fresh or input.jump or dt <= 0 or dt > 0.4 -- (as the kit: after a long frame it stands anew)
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
	-- (one breath in ten of its units of time, begun by its seed; the root is at the hips, but it breathes
	-- about its SHOULDERS)
	local breath = BREATH * sin(t * TAU * 0.1 / tick + S.seed * TAU) * (1 - amount)
	-- (the forefeet leave or enter the ground from 10 degrees of the trunk's pitch: eased towards 12)
	local lean = Kit.bound(pitch + breath, math.rad(10), math.rad(12))
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
		if k <= 2 then -- the first pair is the forelegs
			safeLeg(pose, leg, FORE_BENDS, FORE_ROLL)
		else
			safeLeg(pose, leg, HIND_BENDS, HIND_ROLL)
		end
	end

	-- THE HEAD: the steadiest part, and here the biggest. The neck undoes ALL the trunk does (its lean, the
	-- chest's turn and roll), a third at each joint, so the head stands still over a body that walks;
	-- standing, it is still and now and then looks somewhere.
	local neck, head = S.neck, S.head
	Kit.zero(pose, neck)
	Kit.zero(pose, head)
	Kit.spread(pose, neck, NECK_SHARE, -lean, -chestYaw, -chestDrop)
	Kit.spread(pose, head, HEAD_SHARE, -lean, -chestYaw, -chestDrop)
	local gaze = S.gaze
	local yaw, look = Kit.gaze(gaze, t, S.dice, LOOK, not W.moving)
	Kit.asideHold(gaze, t, S.dice, LOOK.turn, ASIDE)
	-- (into a turn the head goes first: 0.3 seconds of the turn ahead, on a spring of rate 5 at a unit of time
	-- of 0.29, without overshoot: the Fairy Fox's)
	yaw += Kit.spring(S.lookTurn, Kit.clamp(0.3 * W.w, -TURN_LEAD, TURN_LEAD) * amount, 5 / (tick / 0.29), 1, dt)
	Kit.spread(pose, neck, NECK_SHARE, look, yaw, 0)
	Kit.spread(pose, head, HEAD_SHARE, look, yaw, 0)
	-- (now and then, as it looks at something, it cocks its head, and holds that as long as the look: shared
	-- in thirds too. 11.5 degrees in all; 20 was looked at)
	local cock = Kit.cock(S, t, W.moving, LOOK.turn, TILT, TILT_CHANCE)
	Kit.spread(pose, neck, NECK_SHARE, 0, 0, cock)
	Kit.spread(pose, head, HEAD_SHARE, 0, 0, cock)

	-- THE TAILS (the Fairy Fox's brush, three times). The MIDDLE one leads: its root swings it from side to
	-- side once a stride; every bone after it follows the one before on a spring, a little later and a little
	-- further, and goes on after the fox has stopped; in a turn it stays behind. The two SIDE ones do what the
	-- middle one does, joint for joint, a tenth of a stride later and never far from it: the three sway the
	-- same way and keep their gaps. Nothing ever pitches a tail: laid back, the three tips come together.
	local tail = S.tail
	if not W.moving and t >= S.swishNext then
		S.swishAt, S.swishSide = t, if Kit.roll(S.dice) < 0.5 then -1 else 1
		S.swishNext = t + Kit.wait(S.dice, 8, 20, 50) -- seconds between two swishes: at least, mean, at most
	end
	-- (half the swing at a trot, a tenth of a stride after the pelvis; a swish lasts five of its units of time)
	local lead = hipYaw
		+ TAIL_SWING * amount * (1 - 0.5 * W.g) * sin(TAU * (W.phase - 0.1))
		+ SWISH * S.swishSide * Kit.pulse(t, S.swishAt, 5 * tick)
	local reset = input.jump or dt <= 0
	Kit.chainFollow(
		pose,
		tail,
		S.follow,
		lead,
		hipYaw,
		TAIL_RATE / tick,
		TAIL_DAMP,
		TAIL_MOST,
		W.w * math.min(dt, 0.1), -- (a frame counts as a tenth of a second at most for what a turn leaves behind)
		dt,
		input.jump
	)
	local share = Kit.follow(SIDE_RATE / tick, math.max(dt, 0))
	sideTail(pose, S.tailLeft, S.lagLeft, tail, share, reset)
	sideTail(pose, S.tailRight, S.lagRight, tail, share, reset)
end

return Fox
