-- The Aurora Owl (art/models/ready/pet_AuroraOwl.glb, 34 bones: a big round owl modelled STANDING, upright,
-- its wings half open and drooped 34 degrees, a tail of three ribbon feathers with a star each lying back
-- from its rump, and a streamer of star threads trailing from each flank; its skeleton was built here by the
-- recipe art/models/rig/pet_AuroraOwl.json). Its joint map and its motion. Look at
-- art/models/rigs/pet_AuroraOwl_left.png and _front.png and at
-- art/models/poses/pet_AuroraOwl_pose_air_and_ground.png beside this file; docs/motion/pet_AuroraOwl.md says
-- what was learned on it.
--
-- Its motion is the Parrot's (pet_Parrot.luau, which is the Seagull's frame on the kit's `limb` and `key`: the
-- kit's `soar` for the path and the bank, a beat by `chainWave` from the shoulder with the elbow and the wrist
-- after it and a share of sweep, rounds of beats and a glide, the head held level, legs and wings by keys, a
-- tail that branches moved in one loop). What THIS body forces:
--   * it is modelled STANDING: rest is the ground pose and the AIR is the key (the Parrot is the other way
--     round). On the ground nothing is turned but the wings, which fold, and the flank streamers, lifted 6
--     degrees because a star of theirs, not the feet, is the lowest point of the mesh;
--   * it stands upright, so to go it tips 40 degrees about its hips (Body_01), which is what its head, with
--     no neck, can take out again;
--   * its wings hang half open: a level wing is 34 degrees UP from rest, and the beat is about a middle 30
--     degrees up, from the wing as modelled to 58 up (hovering 62; 64 is where it reaches the ear tufts);
--   * its tail and its streamers lie BACK, not down: tipped with the trunk they would point up, so going
--     they are brought down again into the body's line, and they swing from side to side about the upright
--     (yaw), not about the body's length;
--   * the tail is a root and THREE ribbons of four joints, and each flank has a streamer of three joints on
--     the trunk itself: each follows softly, a little later and a little more down its chain, and never whips;
--   * an owl beats slowly and glides long: 4 or 5 beats of a round of 10, at 0.3 beats a unit of its time.
-- (The band from each flank to the star at the wing's tip has no bone: it follows the wing.)
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, sqrt, max, pi = math.sin, math.sqrt, math.max, math.pi
local TAU = pi * 2

local Owl = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (the mesh does NOT mirror itself: its middle is at x +0.005, the wings and the legs are twins to 0.002,
-- the ribbons to 0.03 of the skeleton's height; the two flank streamers lie differently and are not a pair)
Owl.map = {
	count = 34,
	tree = 306619651,
	-- Root is the handle in the middle of the trunk (it drives nothing); Body_01 is the WHOLE trunk, one ball.
	-- Its joint lies on the line through the two hips: the trunk tips there over legs that stand
	root = "Root",
	spine = { "Root", "Body_01" },
	-- (no neck: the head ball sits on the body behind a ruff)
	-- Head at the base of the skull: head, beak, brow and both ear tufts turn on it as one piece
	head = { "Head" },
	-- the tail's root inside the rump, where the three stems meet: it swings all three ribbons
	tail = { "Tail_01" },
	limbs = {
		-- a wing: SHOULDER (just inside the body's side), ELBOW (the top of the wing's arch), WRIST (where the
		-- leading band turns down to the tip). The feather plate is one piece on these three
		wingL = { role = "arm", bones = { "Wing_L_01", "Wing_L_02", "Wing_L_03" } },
		wingR = { role = "arm", bones = { "Wing_R_01", "Wing_R_02", "Wing_R_03" } },
		-- a leg: HIP (hidden in the belly, on the trunk's joint line), the top of the bare SHANK (the bird's
		-- ankle: it folds back), the FOOT under the gold cuff (a positive turn lifts the toes)
		legL = { role = "leg", bones = { "Leg_L_01", "Leg_L_02", "Leg_L_03" } },
		legR = { role = "leg", bones = { "Leg_R_01", "Leg_R_02", "Leg_R_03" } },
		-- a ribbon of the tail: where its stem leaves the rump, the neck of its blade, the middle of the blade,
		-- the neck of its star (rigid on it). The centre one level, the side ones out and down
		ribbonC = {
			role = "tail",
			bones = { "TailFeather_C_01", "TailFeather_C_02", "TailFeather_C_03", "TailFeather_C_04" },
		},
		ribbonL = {
			role = "tail",
			bones = { "TailFeather_L_01", "TailFeather_L_02", "TailFeather_L_03", "TailFeather_L_04" },
		},
		ribbonR = {
			role = "tail",
			bones = { "TailFeather_R_01", "TailFeather_R_02", "TailFeather_R_03", "TailFeather_R_04" },
		},
		-- the two star threads of a flank, one chain (their stars touch): the root at the flank behind the leg,
		-- their middle, the neck of the stars. They hang on the trunk, not on the tail
		streamerL = { role = "tail", bones = { "Streamer_L_01", "Streamer_L_02", "Streamer_L_03" } },
		streamerR = { role = "tail", bones = { "Streamer_R_01", "Streamer_R_02", "Streamer_R_03" } },
	},
	pairs = { { "wingL", "wingR" }, { "legL", "legR" }, { "ribbonL", "ribbonR" } },
}

Owl.layer = "fly"

-- HOW IT STROLLS in its plot: as the Seagull and the Parrot, it cruises and never stops (the owner's decision
-- for the two). THIS LINE IS THE SWITCH: with `cruise` off and a `rest` (seconds, least and most) it lands now
-- and then and stands with its wings folded, which this module already plays (it is its rest pose).
-- `lengths` and `radius` count in heights of its skeleton, which is 0.64 of the model's: 2.9 of its heights a
-- second (the Parrot 4.3, the gull 4.9: a round heavy bird), on circles no tighter than 5 of them.
Owl.stroll = { lengths = 4.5, rest = { 0, 0 }, radius = 8, cruise = true }

-- (what the tools draw and measure as its legs)
Owl.legs = {
	{ id = "L", name = "left leg", chain = Owl.map.limbs.legL.bones },
	{ id = "R", name = "right leg", chain = Owl.map.limbs.legR.bones },
}

-- ITS TIME, ITS SIZE ----------------------------------------------------------------------------------------
-- Every tempo is counted in its own unit of time, the square root of (half its skeleton's height / G), as the
-- Parrot's and the Seagull's. A big one beats slowly.
local SIZE = 0.5
local LENGTH = 1.5 -- beak to the centre star as it flies, in heights of its skeleton (the kit's `soar` counts in these)

-- IN THE AIR OR NOT -----------------------------------------------------------------------------------------
local MOVE = 0.12 -- body lengths a second: moved faster than this along the ground, it flies (the Parrot's)
local RISE = 0.8 -- how quickly it is up, and down again (1 / its unit of time; the Parrot 0.9: it is heavier)
local LOW = 0.6 -- heights of its skeleton it lifts itself when no layer holds it (the animals of the zones)

-- THE BODY --------------------------------------------------------------------------------------------------
-- (the path: a rise and a dip every 6 body lengths, lower than the Parrot's, so that the head, which is near
-- its limit when the trunk is tipped, does not have to nod with it; a bank of up to 24 degrees, which is what
-- the head's roll (limit 25) can take out again)
local PATH = { wave = 0.08, every = 6, steep = 0.2, bank = 0.7, most = 0.42, quick = 3 }
-- (it is modelled upright: that is how it stands and how it hovers. To go it tips forward about its hips: 40
-- degrees, the most its head can take out with no neck. Stage A looked at 50 with the head at its limit)
local LEVEL = 0.70
-- how quickly it tips to go and comes upright again (1 / its unit of time): half a second for a small one. The
-- tail and the streamers are brought down by the same number, so a bird that stops does not whip them
local TIP = 0.6
local HEAVE = 0.02 -- heights it rises on each downstroke (the Parrot's)
local BREATH = 0.010 -- radians its trunk tips about its hips as it stands (0.6 degrees each way)
-- heights of its skeleton the soles lie under the foot's joint (0.0595 of 0.587 in the file): what it comes
-- DOWN by to stand on its feet and not on the star of its right streamer (0.030 of the model's height)
local SOLE = 0.101

-- THE WINGS: keys of shoulder, elbow, wrist, { rx, ry, rz } written for the RIGHT wing (radians from the
-- half open wing it is modelled with: a positive rz raises it, a positive ry sweeps it forward) -------------
-- FOLDED on the ground: shoulder 30, elbow 25, wrist 25 degrees down, the fan closing onto the flank (looked
-- at in stage A, the last row of its pose sheet; the limits are 35, 40, 40)
local FOLD = { { 0, 0, -0.524 }, { 0, 0, -0.436 }, { 0, 0, -0.436 } }
-- gliding: the wing level (34 degrees up from rest), the hand drooping a little
local GLIDE = { { 0, 0, 0.593 }, { 0, 0, 0 }, { 0, 0, -0.09 } }
-- the middle of a beat: 30 degrees over rest, elbow and wrist 3 degrees down so that they give more at the
-- bottom of the beat than at the top (stage A: "the elbow and the wrist following by up to 15 down")
local STROKE = { { 0, 0, 0.524 }, { 0, 0, -0.05 }, { 0, 0, -0.05 } }
-- radians the shoulder beats, each way: from 2 degrees over rest (the wing as modelled: the bottom that was
-- looked at) to 58 over it; the limit is 64 up, where the wing reaches the ear tufts
local BEAT = 0.489
local BEAT_HOVER = 0.524 -- ... while it hovers: higher at the top (62), as deep at the bottom
local BEAT_GAIN = 0.55 -- the elbow beats this share of the shoulder, the wrist of the elbow (the Parrot's)
local BEAT_LAG = 0.9 -- radians of the beat each is behind the one before (the Parrot's)
local BEAT_MOST = 0.8
-- the share of a beat that is also a sweep about the upright (the Parrot's): the wing comes FORWARD on its way
-- down and goes back on its way up. 12 degrees each way at the shoulder at most, of the 30 it may
local SWEEP = 0.4
local FLAP = 0.3 -- beats in one unit of its time (the Parrot 0.5, the gull 0.36): an owl beats slowly
local QUICK = 0.2 -- how much quicker it beats while it hovers
local CYCLE = 10 -- beats one round takes: a few beats, then a long glide (the gull's round)
local FLAPS = { 4, 5 } -- beats of a round: at least, at most (the gull 3 or 4, the Parrot 10 or 11 of 14)
local CLIMB = 0.25 -- climbing faster than this share of its pace, it beats all the time
local BEAT_ON = 1.2 -- how quickly the beat comes in and goes out (1 / its unit of time)
local BEATING = { flap = FLAP, quick = QUICK, cycle = CYCLE, flaps = FLAPS, climb = CLIMB, on = BEAT_ON }

-- THE LEGS: a key of hip, shank, foot (it stands on them as modelled, and they hang so while it hovers) ----
-- going: tucked under the tail: the hip 45 degrees back (its limit is 50), the shank 30 back, the toes
-- lifted 40 (stage A's key, looked at, with the hip 5 degrees inside it)
local TUCK = { { -0.785, 0, 0 }, { -0.524, 0, 0 }, { 0.698, 0, 0 } }
local TRAIL_SWING = 0.8 -- how softly they are laid back as it goes (1 = no swing past)

-- THE HEAD --------------------------------------------------------------------------------------------------
local HEAD_STILL = 0.9 -- the share of the body's tip and bank it takes out again (it has no neck to share with)
-- radians it tips: freely to 34 degrees, then eased towards 40, which it never reaches (past it the nape tears)
local HEAD_KNEE = 0.6
local HEAD_MOST = 0.698
-- ... and rolls: freely to 20 degrees, eased towards 25 (the ruff passes into the shoulders)
local ROLL_KNEE = 0.35
local ROLL_MOST = 0.436
-- an owl looks about with its whole head, slowly, and holds: 34 degrees to a side (its limit is 45, and the
-- lead into a turn comes on top)
local LOOK =
	{ yaw = 0.6, up = 0.15, down = 0.2, turn = 0.35, least = 1.5, mean = 6, aside = 2.5, most = 18, home = 0.7 }
local LEAD = 0.25 -- radians the head goes ahead into a turn of one radian a second ...
local LEAD_MOST = 0.15 -- ... at most

-- THE TAIL: its root, three ribbons of four joints; and the two flank streamers of three ----------------------
-- (they lie BACK: a positive rx swings them DOWN, a positive ry to its right)
-- going, the trunk's tip of 40 degrees would point them all up: the root comes down 23 degrees (its limit is
-- 30), each ribbon's stem 8 and the neck of its blade 6 more, so the tail streams in the body's line
local TAIL_STREAM = 0.40
local RIBBON_STREAM = { 0.14, 0.10, 0, 0 }
local STREAMER_STREAM = { 0.44, 0.17, 0 } -- ... and each streamer's root 25 degrees, its middle 10 (40 a joint)
-- on the ground the streamers' roots are lifted 7 degrees: with the body lowered onto its soles their stars
-- hang over the ground, not in it (stage A tried 6, which leaves the lowest star 0.3% of the skeleton's height
-- over it; a degree more for the eye)
local STREAMER_GROUND = -0.122
local TAIL_TURN = 0.25 -- radians the root trails behind a turn of one radian a second ...
local TAIL_MOST = 0.2 -- ... at most (its limit is 25 degrees, and the sway comes on top)
local TAIL_GAIN = 0.6 -- ... and a ribbon's stem that share of it again, every joint after it of the one before
local SWAY = 0.05 -- radians the root sways from side to side while it is in the air ...
local SWAY_RATE = 0.05 -- ... times in one unit of its time (slower than the Parrot's 0.06)
local NOD = 0.04 -- radians the root nods with every beat (the body heaves and the tail is late)
local NOD_LAG = 1.2 -- radians of the beat the root is behind the wings
-- a joint swings this share of the one before it: a little more, down four joints (the Parrot's 1.3 down two
-- would make the stars whip)
local RIBBON_GAIN = 1.15
local RIBBON_LAG = 0.6 -- ... and this much of the swing later
local RIBBON_MOST = 0.2 -- radians a joint sways or nods at most (the stems' limit is 20 degrees with the trail)
-- (radians of the swing each is later still, so that they do not move as one board: the centre ribbon, the
-- left and the right ribbon; the left and the right streamer, which come last)
local LATE = { 0, 0.35, 0.55, 0.9, 1.1 }

function Owl.new(rig, info)
	local seed = info.seed or 0
	local dice = Kit.dice(seed)
	local h = rig.height
	local tick = sqrt(SIZE * h / Kit.G)
	local length = LENGTH * h
	local body = Kit.bone(rig, "Body_01")
	local legs = {
		Kit.limb(rig, Owl.map.limbs.legR.bones),
		Kit.limb(rig, Owl.map.limbs.legL.bones, true),
	}
	-- how far it comes DOWN for its soles to stand on the ground: once, from the skeleton (the trunk is not
	-- tipped on the ground, so the feet's joints are where they are at rest)
	local stand = 0
	for _, leg in legs do
		stand += (SOLE * h - rig.py[leg.bones[3]]) / #legs
	end
	-- the five chains that trail: the three ribbons hang on the tail's root, the two streamers on the trunk
	local trails = {}
	for k, name in { "ribbonC", "ribbonL", "ribbonR", "streamerL", "streamerR" } do
		local ribbon = k <= 3
		trails[k] = {
			bones = Kit.chain(rig, name),
			late = LATE[k],
			stream = if ribbon then RIBBON_STREAM else STREAMER_STREAM,
			ground = if ribbon then 0 else STREAMER_GROUND,
			still = if ribbon then 0 else 1,
			-- (a ribbon swings a share of its root; a streamer has no root but the trunk and swings as the tail's
			-- root does)
			share = if ribbon then RIBBON_GAIN else 1,
			bend = if ribbon then TAIL_GAIN else 1,
		}
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
		pace = Owl.stroll.lengths * h,
		all = all,
		root = rig.root,
		body = body,
		head = Kit.chain(rig, "the head")[1],
		tail = Kit.chain(rig, "the tail")[1],
		trails = trails,
		legs = legs,
		wings = {
			Kit.limb(rig, Owl.map.limbs.wingR.bones),
			Kit.limb(rig, Owl.map.limbs.wingL.bones, true),
		},
		stand = stand,
		fresh = true,
		-- what the kit's `soar` is handed (it writes the path and the bank onto the root)
		glider = Kit.glider({ length = length }, seed),
		flight = { yaw = 0, speed = 0, jump = false, air = 0, climb = 0 },
		aloft = { x = 0, v = 0 },
		tipped = { x = 0, v = 0 },
		laid = { x = 0, v = 0 },
		lead = { x = 0, v = 0 },
		trail = { x = 0, v = 0 },
		gaze = Kit.newGaze(),
	}
	Kit.newBeat(S, seed, BEATING)
	return S
end

function Owl.step(S, dt, input)
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
	local reset = S.fresh or input.jump or dt <= 0 or dt > 0.4
	if reset then
		S.fresh = false
		S.aloft.x, S.aloft.v = want, 0
		aloft = want
		dt = max(dt, 0)
	else
		aloft = Kit.clamp(Kit.spring(S.aloft, want, RISE / tick, 1, dt), 0, 1)
	end

	-- THE BODY: the kit's path and bank on the root; the trunk tipped about its hips: as modelled (upright)
	-- when it stands and when it hovers, forward when it goes
	local flight = S.flight
	flight.yaw, flight.speed, flight.jump, flight.air, flight.climb = input.yaw, v, input.jump, aloft, climb
	local go = Kit.soar(S.glider, pose, dt, flight, PATH, S.root)
	local turning = S.glider.w
	local roll = rz[S.root]
	pose.bob = pose.bob + LOW * h * aloft * (1 - air) + S.stand * (1 - aloft)
	-- (standing, it breathes: the trunk tips about its hips, and the hips, which lie on that line, take it out)
	local breath = BREATH * sin(t * TAU * 0.09 / tick + S.seed * TAU) * (1 - aloft)
	-- (how far it is tipped to go, 0 to 1: it follows `go` softly, and at once when it was put somewhere)
	if reset then
		S.tipped.x, S.tipped.v = go, 0
	end
	local stream = Kit.clamp(Kit.spring(S.tipped, go, TIP / tick, 1, dt), 0, 1) * aloft
	local tip = breath - LEVEL * stream
	rx[S.body] = tip
	local pitch = rx[S.root] + tip

	-- THE BEAT: rounds of a few beats and a long glide; hovering, climbing and getting up it beats all the time
	local beating, wave = Kit.beat(S, dt, go, aloft, climb, BEATING)
	pose.bob -= HEAVE * h * beating * aloft * sin(wave - 0.5)

	-- THE WINGS: folded on the ground; aloft raised to their glide or to the middle of their beat, and beating
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

	-- THE LEGS: as modelled on the ground and while it hovers (they hang), tucked back when it goes
	local laid = Kit.clamp(Kit.spring(S.laid, go, 0.6 / tick, TRAIL_SWING, dt), 0, 1)
	for _, leg in S.legs do
		Kit.key(pose, leg, TUCK, aloft * laid)
		rx[leg.bones[1]] -= breath
	end

	-- THE HEAD: level and still over a body that tips and banks, inside what its nape allows (eased towards
	-- the limit, never clamped at it); into a turn it goes first; standing or hovering it now and then looks
	-- somewhere, in one move, and holds that
	local head = S.head
	local yaw, look = Kit.gaze(S.gaze, t, S.dice, LOOK, go < 0.05)
	yaw += Kit.spring(S.lead, Kit.clamp(LEAD * turning, -LEAD_MOST, LEAD_MOST) * go, 0.5 / tick, 1, dt)
	rx[head] = Kit.bound(look - HEAD_STILL * pitch, HEAD_KNEE, HEAD_MOST)
	ry[head] = yaw
	rz[head] = Kit.bound(-HEAD_STILL * roll, ROLL_KNEE, ROLL_MOST)

	-- THE TAIL AND THE STREAMERS: as modelled on the ground (the streamers lifted off it) and while it hovers;
	-- brought down into the body's line when it goes; behind a turn they trail, in the air they sway and nod
	-- with the beat, and every joint does what the one before it does a little later and a little more
	local tail = S.tail
	local trail = Kit.spring(S.trail, Kit.clamp(-TAIL_TURN * turning, -TAIL_MOST, TAIL_MOST) * aloft, 0.5 / tick, 1, dt)
	local sway = SWAY * aloft
	local swing = TAU * (SWAY_RATE * t / tick + S.seed)
	local nod = NOD * beating * aloft
	rx[tail] = TAIL_STREAM * stream + nod * sin(wave - NOD_LAG)
	ry[tail] = trail + sway * sin(swing)
	for _, chain in S.trails do
		local b = chain.bones
		-- (a streamer's root is lifted on the ground and takes the breath out, as the hips do: its star hangs
		-- a hair over the ground and must not dip into it)
		rx[b[1]] = (chain.ground - breath) * chain.still * (1 - aloft)
		for k, i in b do
			rx[i] += chain.stream[k] * stream
		end
		Kit.chainBend(pose, b, "y", trail * chain.bend, TAIL_GAIN)
		local late = RIBBON_LAG + chain.late
		Kit.chainWave(pose, b, "y", sway * chain.share, swing - late, RIBBON_LAG, RIBBON_GAIN, RIBBON_MOST)
		Kit.chainWave(pose, b, "x", nod * chain.share, wave - NOD_LAG - late, RIBBON_LAG, RIBBON_GAIN, RIBBON_MOST)
	end
end

return Owl
