-- The Parrot (art/models/ready/pet_Parrot.glb, 26 bones: a macaw modelled as a bird that brakes to land:
-- UPRIGHT, its wings spread and raised in one upright plane behind its back, its claws reaching forward, a
-- tail of five feathers hanging under it; its skeleton was built here by the recipe
-- art/models/rig/pet_Parrot.json). Its joint map and its motion. Look at art/models/rigs/pet_Parrot_left.png
-- and _front.png and at art/models/poses/pet_Parrot_pose_ground_and_air.png beside this file;
-- docs/motion/pet_Parrot.md says what was learned on it.
--
-- Its motion is the Seagull's (pet_Seagull.luau: a bird modelled in the air with wings of three bones, in the
-- high layer: the kit's `soar` for the path and the bank, a beat by `chainWave` from the shoulder with the
-- elbow and the wrist after it, a few beats and a glide, the head held level, the legs and the folded wings
-- by keys, a pose for the ground because the mesh stands in the air). What THIS body forces:
--   * it stands 60 degrees nose up, so to go it tips much further (40 degrees), and about its HIPS (Body_01),
--     not at the root: the bank then stays a roll about the way it flies;
--   * it has no neck: the head alone takes the body's tip and bank out again, inside what its nape allows;
--   * its wings stand in an upright plane, so a beat about the body's length moves each wing IN its own
--     plane; a share of every beat is therefore a sweep (yaw at the shoulder): down and forward, up and back;
--   * the fan's inner corner lies on the rump, so the beat is about a middle below rest and never deeper
--     than 40 degrees under it;
--   * its legs are hip, ankle, knuckles: as modelled they hang, flying they are tucked back at the hip, and
--     on the ground only the toes open (tipping the trunk 30 degrees is what puts the claws under the hips);
--   * its tail is a root and five feathers of two joints: it hangs while it hovers, streams in the body's
--     line when it goes, and every feather follows its root a little later and a little more;
--   * a parrot beats faster and glides less than a gull: more beats in a unit of its time, 10 or 11 beats of
--     a round of 14 (the gull: 3 or 4 of 10), a lower wave in its path.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, cos, sqrt, max, pi = math.sin, math.cos, math.sqrt, math.max, math.pi
local TAU = pi * 2

local Parrot = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the mesh mirrors itself exactly: every right joint is the mirror image of its left one)
Parrot.map = {
	count = 26,
	tree = 786297059,
	-- Root is the handle in the middle of the trunk (it drives nothing); Body_01 is the WHOLE trunk, one piece as
	-- a bird's is. Its joint lies on the line through the two hips: the trunk tips there over legs that stand
	root = "Root",
	spine = { "Root", "Body_01" },
	-- (no neck: the head ball sits on the shoulders)
	-- Head at the base of the skull: the ball, the beak and the whole crest turn on it as one piece
	head = { "Head" },
	-- the root of the stub at the rump: it swings all five feathers
	tail = { "Tail_01" },
	limbs = {
		-- a wing: SHOULDER (just inside the body's side, in the middle of the plate's thickness), ELBOW (where the
		-- arm's line turns upward), WRIST (where the thick arm ends; the hand is the longest piece). The fan is one
		-- plate, rigid on these three
		wingL = { role = "arm", bones = { "Wing_L_01", "Wing_L_02", "Wing_L_03" } },
		wingR = { role = "arm", bones = { "Wing_R_01", "Wing_R_02", "Wing_R_03" } },
		-- a leg: HIP (hidden in the belly, on the leg's own line and on the trunk's joint line), ANKLE (where the
		-- red cuff ends and the grey claw begins), KNUCKLES (the three toes, one joint: a positive turn opens them)
		legL = { role = "leg", bones = { "Leg_L_01", "Leg_L_02", "Leg_L_03" } },
		legR = { role = "leg", bones = { "Leg_R_01", "Leg_R_02", "Leg_R_03" } },
		-- a feather of the tail: where its stem leaves the stub, where the stem widens into the leaf (rigid on it).
		-- The long centre plume, the plume each side of it, the two short feathers that point back
		plumeC = { role = "tail", bones = { "TailFeather_C_01", "TailFeather_C_02" } },
		plumeL = { role = "tail", bones = { "TailFeather_L_01", "TailFeather_L_02" } },
		plumeR = { role = "tail", bones = { "TailFeather_R_01", "TailFeather_R_02" } },
		backL = { role = "tail", bones = { "TailBack_L_01", "TailBack_L_02" } },
		backR = { role = "tail", bones = { "TailBack_R_01", "TailBack_R_02" } },
	},
	pairs = { { "wingL", "wingR" }, { "legL", "legR" }, { "plumeL", "plumeR" }, { "backL", "backR" } },
}

Parrot.layer = "fly"

-- HOW IT STROLLS in its plot: as the Seagull, it cruises and never stops (the owner's decision for the gull;
-- for this bird the question is open: docs/motion/pet_Parrot.md). `lengths` and `radius` count in heights of
-- its skeleton, which is 0.79 of the model's: 4.3 of its heights a second, a little under the gull's 4.9.
Parrot.stroll = { lengths = 5.5, rest = { 0, 0 }, radius = 9, cruise = true }

-- (what the tools draw and measure as its legs)
Parrot.legs = {
	{ id = "L", name = "left leg", chain = Parrot.map.limbs.legL.bones },
	{ id = "R", name = "right leg", chain = Parrot.map.limbs.legR.bones },
}

-- ITS TIME, ITS SIZE ----------------------------------------------------------------------------------------
-- Every tempo is counted in its own unit of time, the square root of (half its skeleton's height / G), as the
-- Seagull's: 0.13 s for a parrot of 1.5 studs (its skeleton 1.19). A big one beats slowly.
local SIZE = 0.5
local LENGTH = 1 -- beak to the tail's tip as it flies, in heights of its skeleton (the kit's `soar` counts in these)

-- IN THE AIR OR NOT -----------------------------------------------------------------------------------------
local MOVE = 0.12 -- body lengths a second: moved faster than this along the ground, it flies
local RISE = 0.9 -- how quickly it is up, and down again (1 / its unit of time)
local LOW = 0.6 -- heights of its skeleton it lifts itself when no layer holds it (the animals of the zones)

-- THE BODY --------------------------------------------------------------------------------------------------
-- (the path: a rise and a dip every 6 body lengths, lower than the gull's; a bank of up to 31 degrees, which
-- is what the head can take out again)
local PATH = { wave = 0.1, every = 6, steep = 0.3, bank = 0.8, most = 0.55, quick = 4 }
-- (it is modelled upright, 60 degrees nose up: that is how it hovers. To go it tips forward about its hips;
-- on the ground it tips less, which alone puts its claws under its hips. Both were looked at on the mesh)
local LEVEL = 0.70
local GROUND = 0.52
local HEAVE = 0.02 -- heights it rises on each downstroke
local BREATH = 0.012 -- radians its trunk tips about its hips as it stands
local SOLE = 0.083 -- heights of its skeleton the tips of its opened toes lie under the knuckles' joint

-- THE WINGS: keys of shoulder, elbow, wrist, { rx, ry, rz } written for the RIGHT wing (radians from the V it
-- is modelled in: a negative rz lowers it, a negative ry sweeps it back) -----------------------------------
-- FOLDED: the shoulder alone, lowered 60 degrees and swept back 85 along the flank (the fan is one plate and
-- cannot fold on itself). Looked at on the mesh.
local FOLD = { { 0, -1.484, -1.047 } }
local GLIDE = { { 0, 0, -0.35 }, { 0, 0, 0 }, { 0, 0, -0.25 } } -- gliding: the V half closed, the hand drooping
local STROKE = { { 0, 0, -0.17 }, { 0, 0, 0 }, { 0, 0, -0.10 } } -- the middle of a beat: 10 degrees under rest
-- radians the shoulder beats, each way: from 20 degrees over rest to 40 under it, and no deeper (there the
-- fan's inner corner comes over the rump)
local BEAT = 0.52
local BEAT_HOVER = 0.6 -- ... while it hovers: higher at the top, as deep at the bottom
local BEAT_GAIN = 0.55 -- the elbow beats this share of the shoulder, the wrist of the elbow
local BEAT_LAG = 0.9 -- radians of the beat each is behind the one before
local BEAT_MOST = 0.8
-- the share of a beat that is also a sweep about the upright: the wing comes FORWARD on its way down and goes
-- back on its way up, so that it moves through the air and not only along its own plane
local SWEEP = 0.4
local FLAP = 0.5 -- beats in one unit of its time (the gull: 0.36): 3.8 a second at 1.5 studs, 1.9 at 6
local QUICK = 0.2 -- how much quicker it beats while it hovers
local CYCLE = 14 -- beats one round takes: most of it beats, then a short glide
local FLAPS = { 10, 11 } -- beats of a round: at least, at most (the gull: 3 or 4 of 10)
local CLIMB = 0.25 -- climbing faster than this share of its pace, it beats all the time
local BEAT_ON = 1.2 -- how quickly the beat comes in and goes out (1 / its unit of time)
local BEATING = { flap = FLAP, quick = QUICK, cycle = CYCLE, flaps = FLAPS, climb = CLIMB, on = BEAT_ON }

-- THE LEGS: keys of hip, ankle, knuckles, from the way the model holds them (hanging, reaching forward) ----
local STAND = { { 0, 0, 0 }, { 0, 0, 0 }, { 0.70, 0, 0 } } -- on the ground: only the toes open, the claw reads as a foot
local TUCK = { { -0.52, 0, 0 } } -- going: the claws laid back under the belly
local TRAIL_SWING = 0.8 -- how softly they are laid back as it goes (1 = no swing past)

-- THE HEAD --------------------------------------------------------------------------------------------------
local HEAD_STILL = 0.9 -- the share of the body's tip and bank it takes out again (it has no neck to share with)
local HEAD_MOST = 0.68 -- radians it tips at most, either way: past 40 degrees the crease at the nape opens
local LOOK =
	{ yaw = 0.7, up = 0.15, down = 0.25, turn = 0.22, least = 1.2, mean = 5, aside = 2, most = 16, home = 0.75 }
local LEAD = 0.25 -- radians the head goes ahead into a turn of one radian a second ...
local LEAD_MOST = 0.3 -- ... at most

-- THE TAIL: its root, and five feathers of a stem and a leaf -------------------------------------------------
local TAIL_GROUND = 0.70 -- radians the root is swung back on the ground: the tail trails level behind it ...
local PLUME_GROUND = 0.44 -- ... and every feather's stem that much further
local TAIL_STREAM = 0.70 -- radians the root is swung back as it goes: the tail streams in the body's line ...
local PLUME_STREAM = { 0.10, 0.15 } -- ... and the stem and the leaf of every feather a little more
local TAIL_TURN = 0.25 -- radians the root trails behind a turn of one radian a second ...
local TAIL_MOST = 0.25 -- ... at most
local TAIL_GAIN = 0.6 -- ... and a feather's stem that share of it again, its leaf of the stem's
local SWAY = 0.06 -- radians the root sways from side to side while it is in the air ...
local SWAY_RATE = 0.06 -- ... times in one unit of its time (once in 2.2 s at 1.5 studs)
local NOD = 0.05 -- radians the root nods with every beat (the body heaves and the tail is late)
local NOD_LAG = 1.2 -- radians of the beat the root is behind the wings
local PLUME_GAIN = 1.3 -- a stem swings this share of the root, a leaf of its stem: each a little more ...
local PLUME_LAG = 0.7 -- ... and this much of the swing later
local PLUME_MOST = 0.35
-- (radians of the swing each feather is later still, so that the five do not move as one board: the centre
-- plume, the left and the right plume, the left and the right back feather)
local LATE = { 0, 0.35, 0.5, 0.8, 0.65 }

function Parrot.new(rig, info)
	local seed = info.seed or 0
	local dice = Kit.dice(seed)
	local h = rig.height
	local tick = sqrt(SIZE * h / Kit.G)
	local length = LENGTH * h
	local body = Kit.bone(rig, "Body_01")
	local legs = {
		Kit.limb(rig, Parrot.map.limbs.legR.bones),
		Kit.limb(rig, Parrot.map.limbs.legL.bones, true),
	}
	-- how far it comes DOWN for the tips of its toes to stand on the ground: once, from the skeleton (where the
	-- knuckles are when the trunk is tipped about its joint, which lies on the hips' line)
	local stand = 0
	for _, leg in legs do
		local knuckles = leg.bones[3]
		local dy, dz = rig.py[knuckles] - rig.py[body], rig.pz[knuckles] - rig.pz[body]
		local y = rig.py[body] + dy * cos(GROUND) + dz * sin(GROUND)
		stand += (SOLE * h - y) / #legs
	end
	local plumes = {}
	for k, name in { "plumeC", "plumeL", "plumeR", "backL", "backR" } do
		plumes[k] = { bones = Kit.chain(rig, name), late = LATE[k] }
	end
	local all = {}
	for i = 1, rig.n do
		all[i] = i
	end
	local S = {
		pose = Kit.newPose(rig),
		dice = dice,
		seed = seed,
		h = h,
		tick = tick,
		length = length,
		pace = Parrot.stroll.lengths * h,
		all = all,
		root = rig.root,
		body = body,
		head = Kit.chain(rig, "the head")[1],
		tail = Kit.chain(rig, "the tail")[1],
		plumes = plumes,
		legs = legs,
		wings = {
			Kit.limb(rig, Parrot.map.limbs.wingR.bones),
			Kit.limb(rig, Parrot.map.limbs.wingL.bones, true),
		},
		stand = stand,
		fresh = true,
		-- what the kit's `soar` is handed (it writes the path and the bank onto the root)
		glider = Kit.glider({ length = length }, seed),
		flight = { yaw = 0, speed = 0, jump = false, air = 0, climb = 0 },
		aloft = { x = 0, v = 0 },
		laid = { x = 0, v = 0 },
		lead = { x = 0, v = 0 },
		trail = { x = 0, v = 0 },
		gaze = Kit.newGaze(),
	}
	Kit.newBeat(S, seed, BEATING)
	return S
end

function Parrot.step(S, dt, input)
	local pose = S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local t, tick, h = input.t, S.tick, S.h
	local air = input.air or 0
	local climb = input.climb or 0
	local v = input.speed
	Kit.zero(pose, S.all)

	-- IN THE AIR OR NOT: in its layer, or moved along the ground (0 standing to 1 flying, eased)
	local want = max(air, Kit.smooth(v / (MOVE * S.length)))
	local aloft
	if S.fresh or input.jump or dt <= 0 or dt > 0.4 then
		S.fresh = false
		S.aloft.x, S.aloft.v = want, 0
		aloft = want
		dt = max(dt, 0)
	else
		aloft = Kit.clamp(Kit.spring(S.aloft, want, RISE / tick, 1, dt), 0, 1)
	end

	-- THE BODY: the kit's path and bank on the root; the trunk tipped about its hips: as modelled (upright)
	-- when it hovers, forward when it goes, a little less on the ground
	local flight = S.flight
	flight.yaw, flight.speed, flight.jump, flight.air, flight.climb = input.yaw, v, input.jump, aloft, climb
	local go = Kit.soar(S.glider, pose, dt, flight, PATH, S.root)
	local turning = S.glider.w
	local roll = rz[S.root]
	pose.bob = pose.bob + LOW * h * aloft * (1 - air) + S.stand * (1 - aloft)
	-- (standing, it breathes: the trunk tips about its hips, and the hips, which lie on that line, take it out)
	local breath = BREATH * sin(t * TAU * 0.09 / tick + S.seed * TAU) * (1 - aloft)
	local tip = breath - GROUND * (1 - aloft) - LEVEL * go * aloft
	rx[S.body] = tip
	local pitch = rx[S.root] + tip

	-- THE BEAT: rounds of many beats and a short glide; hovering, climbing and getting up it beats all the time
	local beating, wave = Kit.beat(S, dt, go, aloft, climb, BEATING)
	pose.bob -= HEAVE * h * beating * aloft * sin(wave - 0.5)

	-- THE WINGS: folded on the ground; aloft lowered to their glide or to the middle of their beat, and beating
	-- from the shoulder, the elbow and the wrist after it; down and forward, up and back
	local more = (BEAT_HOVER - BEAT) * (1 - go)
	local amount = (BEAT + more) * beating * aloft
	for _, wing in S.wings do
		local side = wing.mirror
		Kit.key(pose, wing, FOLD, 1 - aloft)
		Kit.key(pose, wing, GLIDE, aloft * (1 - beating))
		Kit.key(pose, wing, STROKE, aloft * beating)
		-- (hovering it beats higher, not deeper: the middle of the beat rises by what the beat grows)
		rz[wing.bones[1]] += side * more * beating * aloft
		Kit.chainWave(pose, wing.bones, "z", side * amount, wave, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
		Kit.chainWave(pose, wing.bones, "y", -side * SWEEP * amount, wave, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
	end

	-- THE LEGS: as modelled (hanging) while it hovers, tucked back when it goes; on the ground the toes open
	local laid = Kit.clamp(Kit.spring(S.laid, go, 0.6 / tick, TRAIL_SWING, dt), 0, 1)
	for _, leg in S.legs do
		Kit.key(pose, leg, STAND, 1 - aloft)
		Kit.key(pose, leg, TUCK, aloft * laid)
		rx[leg.bones[1]] -= breath
	end

	-- THE HEAD: level and still over a body that tips and banks; into a turn it goes first; standing or
	-- hovering it now and then looks somewhere, in one move, and holds that
	local head = S.head
	local yaw, look = Kit.gaze(S.gaze, t, S.dice, LOOK, go < 0.05)
	yaw += Kit.spring(S.lead, Kit.clamp(LEAD * turning, -LEAD_MOST, LEAD_MOST) * go, 0.5 / tick, 1, dt)
	rx[head] = Kit.clamp(look - HEAD_STILL * pitch, -HEAD_MOST, HEAD_MOST)
	ry[head] = yaw
	rz[head] = -HEAD_STILL * roll

	-- THE TAIL: hanging as modelled while it hovers, streaming in the body's line when it goes, trailing level
	-- on the ground; behind a turn it trails, in the air it sways and nods with the beat, and every feather
	-- does what the root does a little later and a little more
	local tail = S.tail
	local trail =
		Kit.spring(S.trail, Kit.clamp(-TAIL_TURN * turning, -TAIL_MOST, TAIL_MOST) * aloft, 0.5 / tick, 0.7, dt)
	local stream = go * aloft
	local sway = SWAY * aloft
	local swing = TAU * (SWAY_RATE * t / tick + S.seed)
	local nod = NOD * beating * aloft
	rx[tail] = -TAIL_GROUND * (1 - aloft) - TAIL_STREAM * stream + nod * sin(wave - NOD_LAG)
	rz[tail] = trail + sway * sin(swing)
	for _, plume in S.plumes do
		local b = plume.bones
		rx[b[1]] = -PLUME_GROUND * (1 - aloft) - PLUME_STREAM[1] * stream
		rx[b[2]] = -PLUME_STREAM[2] * stream
		Kit.chainBend(pose, b, "z", trail * TAIL_GAIN, TAIL_GAIN)
		local late = PLUME_LAG + plume.late
		Kit.chainWave(pose, b, "z", sway * PLUME_GAIN, swing - late, PLUME_LAG, PLUME_GAIN, PLUME_MOST)
		Kit.chainWave(pose, b, "x", nod * PLUME_GAIN, wave - NOD_LAG - late, PLUME_LAG, PLUME_GAIN, PLUME_MOST)
	end
end

return Parrot
