-- The Phoenix (art/models/ready/pet_Phoenix.glb, 35 bones: a fire bird modelled STANDING, its wings raised and
-- swept back, a crest, a train of seven long feathers behind it; its skeleton was built here by the recipe
-- art/models/rig/pet_Phoenix.json). Its joint map and its motion. Look at art/models/rigs/pet_Phoenix_left.png
-- and _top.png and at art/models/poses/pet_Phoenix_pose_flight.png beside this file;
-- docs/motion/pet_Phoenix.md says what was learned on it.
--
-- Its motion is the Parrot's (pet_Parrot.luau, which is the Seagull's frame on the kit's `limb` and `key`: the
-- kit's `soar` for the path and the bank, a beat by `chainWave` from the shoulder with the elbow and the wrist
-- after it, a share of every beat a sweep, rounds of beats and a glide, the trunk tipped about its hips to go,
-- the head held level, legs by keys, a tail's root and feathers that follow it later and further). What THIS
-- body forces:
--   * it FLIES AND ONLY FLIES (the owner's rule for a pet with wings): it has no pose for the ground. The
--     Parrot's `aloft` is 1 here, and what is left of it (`high`) only says how HIGH it holds itself where no
--     layer does (as the Cave Bat and the Frost Dragon);
--   * it is modelled STANDING, upright: it is tipped forward in EVERY state, 15 degrees to hover and 35 to go
--     (the Parrot hovers as modelled and tips 40);
--   * it has a NECK: the neck and the head share what the Parrot's head took alone (the gull's 0.4 and 0.6);
--   * its wings are modelled RAISED, so the beat is about a middle that is down from rest (as the Parrot's,
--     whose fan lay on its rump), and the glide is a key further down and swept forward: the long feathers
--     then point out, not back;
--   * a big bird: the gull's beat, slower than the Parrot's, in the Parrot's rounds (10 or 11 beats of 14);
--   * its legs are hip, hock, foot: folded up under the belly, hovering or going (the owner's answer). The two legs are not each other's mirror in the mesh; only TURNS are mirrored;
--   * its tail lies BACK (the Parrot's hangs down): it sways and trails from side to side about the upright
--     (yaw, as the Cave Bat's), and its root is swung DOWN as the trunk tips so that the train stays level;
--   * the train is SEVEN feathers, of three, two and one joint, close at their roots: each follows the root a
--     little later than its neighbour, the root sways at two rates that never meet again, so the seven are
--     neither one board nor clockwork; gliding they fan out (stage A's key, less far: the sway needs room).
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, sqrt, max, pi = math.sin, math.sqrt, math.max, math.pi
local TAU = pi * 2

local Phoenix = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
-- (its left is -x. The wings mirror each other, the inner tail feathers nearly; the legs, the outer feathers
-- and the short feather under the right outer one do not)
Phoenix.map = {
	count = 35,
	tree = 1786393397,
	-- Root is the handle over the hips (it drives nothing); Body_01 is the WHOLE trunk, one piece as a bird's
	-- is. Its joint lies on the line through the two hips: the trunk tips there
	root = "Root",
	spine = { "Root", "Body_01" },
	-- the base of the neck, on the shoulders
	neck = { "Neck_01" },
	-- Head at the base of the skull: the skull, the beak and the whole crest turn on it as one piece
	head = { "Head" },
	-- the rump: it swings the whole train
	tail = { "Tail_01" },
	limbs = {
		-- a wing: SHOULDER, ELBOW, WRIST (the five long feathers are rigid on it). The fan is one plate
		wingL = { role = "arm", bones = { "Wing_L_01", "Wing_L_02", "Wing_L_03" } },
		wingR = { role = "arm", bones = { "Wing_R_01", "Wing_R_02", "Wing_R_03" } },
		-- a leg: HIP, HOCK (the thin shank begins), FOOT (the hub of the four toes)
		legL = { role = "leg", bones = { "Leg_L_01", "Leg_L_02", "Leg_L_03" } },
		legR = { role = "leg", bones = { "Leg_R_01", "Leg_R_02", "Leg_R_03" } },
		-- the centre feather: its root, its stem behind the branch, its gem leaf
		featherC = { role = "tail", bones = { "TailFeather_C_01", "TailFeather_C_02", "TailFeather_C_03" } },
		-- the top feather, which leaves the centre one at its first joint: where it leaves, its leaf
		top = { role = "tail", bones = { "TailTop_01", "TailTop_02" } },
		-- the inner feather each side of the centre one: its root, its middle, its last third
		featherL = { role = "tail", bones = { "TailFeather_L_01", "TailFeather_L_02", "TailFeather_L_03" } },
		featherR = { role = "tail", bones = { "TailFeather_R_01", "TailFeather_R_02", "TailFeather_R_03" } },
		-- the outer feather each side: its root, where its strap begins, its gem leaf
		outerL = { role = "tail", bones = { "TailOuter_L_01", "TailOuter_L_02", "TailOuter_L_03" } },
		outerR = { role = "tail", bones = { "TailOuter_R_01", "TailOuter_R_02", "TailOuter_R_03" } },
		-- the short feather under the right outer one, which it hangs on: a rigid spike of one joint, no twin
		low = { role = "tail", bones = { "TailLow_R_01" } },
	},
	-- (the legs and the outer feathers are NOT pairs: the right foot stands ahead of the left one, the right
	-- outer feather's root lies further forward)
	pairs = { { "wingL", "wingR" }, { "featherL", "featherR" } },
}

Phoenix.layer = "fly"

-- HOW IT STROLLS in its plot: as the Seagull and the Parrot, it cruises and never stops. `lengths` and `radius`
-- count in heights of its skeleton, which is 0.77 of the model's (its highest joint is a wrist): 4.3 of the
-- model's heights a second and circles of 7 of them, which are the Parrot's.
Phoenix.stroll = { lengths = 5.6, rest = { 0, 0 }, radius = 9, cruise = true }

-- (what the tools draw and measure as its legs)
Phoenix.legs = {
	{ id = "L", name = "left leg", chain = Phoenix.map.limbs.legL.bones },
	{ id = "R", name = "right leg", chain = Phoenix.map.limbs.legR.bones },
}

-- ITS TIME, ITS SIZE ----------------------------------------------------------------------------------------
-- Every tempo is counted in its own unit of time, the square root of (half its skeleton's height / G), as the
-- Parrot's: 0.13 s for a phoenix of 1.5 studs (its skeleton 1.16). A big one beats slowly.
local SIZE = 0.5
-- beak to the tip of the train as it flies, in heights of its skeleton (0.95 of 0.671 in the file; the kit's
-- `soar` counts in these)
local LENGTH = 1.4

-- HOW HIGH, where no layer holds it (an animal of the zones, a picture of it) ----------------------------------
local MOVE = 0.12 -- body lengths a second: moved faster than this it rises to its full height (the Parrot's)
local RISE = 0.9 -- how quickly it is up, and down again (1 / its unit of time; the Parrot's)
-- heights of its skeleton it holds itself up while it hovers with no layer: its hanging toes and the tips of
-- its train are then the lowest of it (measured by its test: nothing under the ground)
local LOW_STILL = 0.25
-- ... and while it is moved: banked, a wing's tip at the bottom of a beat and the wave of its path (the Parrot
-- lifts itself 0.6; the Cave Bat's number)
local LOW = 0.8

-- THE BODY --------------------------------------------------------------------------------------------------
-- (the path and the bank are the Parrot's: a rise and a dip every 6 body lengths; a bank of up to 31 degrees,
-- which the neck (11 of its 25) and the head (17 of its 30) take out again)
local PATH = { wave = 0.1, every = 6, steep = 0.3, bank = 0.8, most = 0.55, quick = 4 }
-- (it is modelled standing upright. To go it tips 35 degrees forward about its hips: stage A's key of flight,
-- looked at on the mesh; a hair under 35, which is the bound ...)
local LEVEL = 0.61
-- ... and hovering it comes up to 15 degrees (stage A: "hovering it may come up to about -15"): never upright,
-- the pose it stands in
local HOVER = 0.262
local HEAVE = 0.02 -- heights it rises on each downstroke (the Parrot's)

-- THE WINGS: keys of shoulder, elbow, wrist, { rx, ry, rz } written for the RIGHT wing (radians from the raised
-- wing it is modelled with: a negative rz lowers it, a positive ry sweeps it forward) -----------------------
-- gliding: stage A's key, looked at: the shoulder 30 degrees down and 25 forward, elbow and wrist straight:
-- the wing a little under the level, the long feathers pointing out
local GLIDE = { { 0, 0.436, -0.524 } }
-- the middle of a beat: the shoulder 13.5 degrees under rest and 12 forward, the elbow and the wrist 5 down
-- (stage A's two ends of a beat: 15 up and 45 down at the shoulder, 8 up and 15 down at the other two)
local STROKE = { { 0, 0.209, -0.236 }, { 0, 0, -0.087 }, { 0, 0, -0.087 } }
-- radians the shoulder beats, each way: 28 degrees, from 14.5 over rest to 41.5 under it (stage A looked at 15
-- and 45; 45 is the limit, where the inner feathers come to the trunk, and the Parrot's bound of 42 is kept)
local BEAT = 0.489
-- ... while it hovers: 33 degrees, 24.5 at the top and as deep at the bottom (the shoulder alone may 45 up; the
-- whole wing then stands 30 over rest at most, of the 31 that were looked at)
local BEAT_HOVER = 0.576
-- the elbow beats this share of the shoulder, the wrist of the elbow (the Parrot's): 15 and 8.5 degrees each
-- way about 5 down: the elbow 20 down and 10 up of its 30 and 20, the wrist 13.5 and 3.5 of its 25 and 20; the
-- three together 65 down at the same moment, of the 75 at which the wing lies level
local BEAT_GAIN = 0.55
local BEAT_LAG = 0.9 -- radians of the beat each is behind the one before (the Parrot's)
local BEAT_MOST = 0.8
-- the share of a beat that is also a sweep about the upright (the Parrot's: its plate stands upright too): 11
-- degrees each way about the 12 forward of the middle, so 23 forward at the bottom of a beat (the glide's 25,
-- which brings the long feathers out to the side) and 1 at the top; hovering 25 of the 35 it may
local SWEEP = 0.4
-- radians of the beat the sweep is AHEAD of it (the Cave Bat's): the wing is furthest forward a little before
-- it is lowest, so its tip goes round a narrow loop, down and forward, up and back
local SWEEP_LEAD = 0.5
-- beats in one unit of its time: the gull's, a big bird's (the Parrot 0.5): 2.8 a second at 1.5 studs, 1.4 at 6
local FLAP = 0.36
local QUICK = 0.2 -- how much quicker it beats while it hovers (the Parrot's)
local CYCLE = 14 -- beats one round takes (the Parrot's; the owner's answer of 2026-10-13: it beats more) ...
-- ... of which it beats 10 or 11 and glides the rest (the Parrot's; the gull 3 or 4 of 10)
local FLAPS = { 10, 11 }
local CLIMB = 0.25 -- climbing faster than this share of its pace, it beats all the time (the Parrot's)
local BEAT_ON = 1.2 -- how quickly the beat comes in and goes out (1 / its unit of time; the Parrot's)
local BEATING = { flap = FLAP, quick = QUICK, cycle = CYCLE, flaps = FLAPS, climb = CLIMB, on = BEAT_ON }

-- THE LEGS: keys of hip, hock, foot (pitch only: a negative turn swings a joint BACK, a positive one at the
-- hock folds the shank up under the body) -------------------------------------------------------------------
-- tucked, hovering AND going (stage A's key, looked at; the owner's answer of 2026-10-13: hovering too): the
-- thigh 30 back, the shank folded 68 up under the belly (the key says 70, which is the limit: 2 inside it), the
-- toes hanging 30
local TUCK = { { -0.524, 0, 0 }, { 1.187, 0, 0 }, { -0.524, 0, 0 } }

-- THE NECK AND THE HEAD -------------------------------------------------------------------------------------
local HEAD_STILL = 0.9 -- the share of the body's tip and bank they take out again (the Parrot's)
-- the neck's share of it, the head taking the rest (the gull's; stage A's key is 15 and 20 of the 35)
local NECK_SHARE = 0.4
-- radians the neck tips: freely to 22 degrees, eased towards 25, which it never reaches (from 30 the ruff
-- passes into the chest; the other way it may 35). Flying it asks 19 at the steepest of its path
local NECK_KNEE = 0.39
local NECK_MOST = 0.436
-- ... and the head: freely to 31 degrees, eased towards 35 (the nape; it asks 28 at the steepest)
local HEAD_KNEE = 0.55
local HEAD_MOST = 0.611
-- the neck's share of a look to a side (a third: 11 degrees of its 20, the head 23 of its 40, and the lead
-- into a turn comes on top)
local NECK_TURN = 1 / 3
-- it looks about while it hovers, as the Parrot, but 34 degrees to a side (the Parrot 40)
local LOOK =
	{ yaw = 0.6, up = 0.15, down = 0.25, turn = 0.22, least = 1.2, mean = 5, aside = 2, most = 16, home = 0.75 }
-- radians the neck and the head go ahead into a turn of one radian a second (the Parrot 0.25: here the turn is
-- shared by two joints under a body that is tipped and banked, and less of it is left to see: measured) ...
local LEAD = 0.35
local LEAD_MOST = 0.3 -- ... at most: 17 degrees (the Parrot's); with a look, 34 at the head and 17 at the neck

-- THE TAIL: its root, and seven feathers -----------------------------------------------------------------------
-- (it lies BACK: a positive rx swings it DOWN, a positive ry to its RIGHT)
-- radians the root is swung down as it goes: stage A's key, 25 degrees: the train streams level behind a trunk
-- that is tipped 35 ...
local TAIL_STREAM = 0.436
-- ... and 5 degrees while it hovers, tipped 15: the train is as level then
local TAIL_HOVER = 0.087
local TAIL_TURN = 0.25 -- radians the root trails behind a turn of one radian a second (the Parrot's) ...
local TAIL_MOST = 0.25 -- ... at most: 14 degrees of its 30
-- ... and every joint of a feather this share of the root's again (the Parrot 0.6 at the stem: here a root may
-- only 10 degrees inward before it passes into its neighbour, and the sway comes on top): 3.6 degrees a joint
local FEATHER_TRAIL = 0.25
local SWAY = 0.06 -- radians the root sways from side to side (the Parrot's) ...
local SWAY_RATE = 0.06 -- ... times in one unit of its time (once in 2.2 s at 1.5 studs)
-- ... and a quarter of that sway goes at this share of the rate, which never comes round with the first: the
-- train does not swing like a pendulum
local SWAY_SLOW = 0.618
local SWAY_PART = 0.25
local NOD = 0.05 -- radians the root nods with every beat (the body heaves and the tail is late; the Parrot's)
local NOD_LAG = 1.2 -- radians of the beat the root is behind the wings
-- a feather's first joint swings this share of the root, each joint after it of the one before: each a little
-- more (the Parrot's): 4.5, 5.8 and 7.6 degrees of sway
local PLUME_GAIN = 1.3
local PLUME_LAG = 0.7 -- ... and this much of the swing later
local PLUME_MOST = 0.3 -- radians a joint of a feather waves at most: 17 degrees of the 20 it may
-- THE SEVEN: `late`: radians of the swing it is later still than a feather is anyway, so that they do not move
-- as one board (the Parrot's five numbers, the outer pair later than the inner); `share`: of the wave (the top
-- feather rides the centre one's first joint and the short one the right outer one's: they wave less of their
-- own); `pitch`, `yaw`: the turn of its first joint when the train is SPREAD, gliding (stage A's key: every
-- feather 10 degrees down and the top one 15 UP off the centre one; outward 12 the inner and 20 the outer,
-- of which HALF is taken here: 20 is where the roots meet, and the sway and the trail need 9 of it)
local FEATHERS = {
	{ name = "featherC", late = 0, share = 1, pitch = 0.175, yaw = 0 },
	{ name = "top", late = 0.9, share = 0.5, pitch = -0.262, yaw = 0 },
	{ name = "featherL", late = 0.35, share = 1, pitch = 0.175, yaw = -0.105 },
	{ name = "featherR", late = 0.5, share = 1, pitch = 0.175, yaw = 0.105 },
	{ name = "outerL", late = 0.8, share = 1, pitch = 0.175, yaw = -0.175 },
	{ name = "outerR", late = 0.65, share = 1, pitch = 0.175, yaw = 0.175 },
	{ name = "low", late = 1.1, share = 0.4, pitch = 0, yaw = 0 },
}

function Phoenix.new(rig, info)
	local seed = info.seed or 0
	local dice = Kit.dice(seed)
	local h = rig.height
	local tick = sqrt(SIZE * h / Kit.G)
	local length = LENGTH * h
	local limbs = Phoenix.map.limbs
	local feathers = {}
	for k, feather in FEATHERS do
		feathers[k] = {
			bones = Kit.chain(rig, feather.name),
			late = feather.late,
			share = feather.share,
			pitch = feather.pitch,
			yaw = feather.yaw,
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
		pace = Phoenix.stroll.lengths * h,
		all = all,
		root = rig.root,
		body = Kit.bone(rig, "Body_01"),
		neck = Kit.chain(rig, "the neck")[1],
		head = Kit.chain(rig, "the head")[1],
		tail = Kit.chain(rig, "the tail")[1],
		feathers = feathers,
		legs = {
			Kit.limb(rig, limbs.legR.bones),
			Kit.limb(rig, limbs.legL.bones, true),
		},
		wings = {
			Kit.limb(rig, limbs.wingR.bones),
			Kit.limb(rig, limbs.wingL.bones, true),
		},
		fresh = true,
		-- what the kit's `soar` is handed (it writes the path and the bank onto the root)
		glider = Kit.glider({ length = length }, seed),
		flight = { yaw = 0, speed = 0, jump = false, air = 0, climb = 0 },
		high = { x = 0, v = 0 },
		lead = { x = 0, v = 0 },
		trail = { x = 0, v = 0 },
		gaze = Kit.newGaze(),
	}
	Kit.newBeat(S, seed, BEATING)
	return S
end

function Phoenix.step(S, dt, input)
	local pose = S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local t, tick, h = input.t, S.tick, S.h
	local air = input.air or 0
	local climb = input.climb or 0
	local v = input.speed
	Kit.zero(pose, S.all)

	-- HOW HIGH: it is always in the air. `high` is 1 in its layer and when it is moved, 0 while it hovers on the
	-- spot with no layer (eased): there it holds itself up a little, moved with no layer it holds itself up more
	local want = max(air, Kit.smooth(v / (MOVE * S.length)))
	local high
	if S.fresh or input.jump or dt <= 0 or dt > 0.4 then
		S.fresh = false
		S.high.x, S.high.v = want, 0
		high = want
		dt = max(dt, 0)
	else
		high = Kit.clamp(Kit.spring(S.high, want, RISE / tick, 1, dt), 0, 1)
	end

	-- THE BODY: the kit's path and bank on the root; the trunk tipped about its hips: a little when it hovers,
	-- forward when it goes
	local flight = S.flight
	-- (`high` is also the share of the path's wave and of the bank it gets: hovering on the spot with no layer
	-- it hangs where it is)
	flight.yaw, flight.speed, flight.jump, flight.air, flight.climb = input.yaw, v, input.jump, high, climb
	local go = Kit.soar(S.glider, pose, dt, flight, PATH, S.root)
	local turning = S.glider.w
	local roll = rz[S.root]
	pose.bob = pose.bob + (LOW_STILL + (LOW - LOW_STILL) * high) * h * (1 - air)
	local tip = -HOVER - (LEVEL - HOVER) * go
	rx[S.body] = tip
	local pitch = rx[S.root] + tip

	-- THE BEAT: rounds of some beats and a long glide; hovering, climbing and getting up it beats all the time
	local beating, wave = Kit.beat(S, dt, go, 1, climb, BEATING)
	pose.bob -= HEAVE * h * beating * sin(wave - 0.5)

	-- THE WINGS: lowered to their glide or to the middle of their beat, and beating from the shoulder, the elbow
	-- and the wrist after it; down and forward, up and back
	local more = (BEAT_HOVER - BEAT) * (1 - go)
	local amount = (BEAT + more) * beating
	for _, wing in S.wings do
		local side = wing.mirror
		Kit.key(pose, wing, GLIDE, 1 - beating)
		Kit.key(pose, wing, STROKE, beating)
		-- (hovering it beats higher, not deeper: the middle of the beat rises by what the beat grows)
		rz[wing.bones[1]] += side * more * beating
		Kit.chainWave(pose, wing.bones, "z", side * amount, wave, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
		Kit.chainWave(pose, wing.bones, "y", -side * SWEEP * amount, wave + SWEEP_LEAD, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
	end

	-- THE LEGS: folded up under the belly, hovering or going
	for _, leg in S.legs do
		Kit.key(pose, leg, TUCK, 1)
	end

	-- THE NECK AND THE HEAD: level and still over a body that tips and banks, the two sharing it, each inside
	-- what it allows (eased towards the limit, never clamped at it); into a turn they go first; hovering it now
	-- and then looks somewhere, in one move, and holds that
	local neck, head = S.neck, S.head
	local yaw, look = Kit.gaze(S.gaze, t, S.dice, LOOK, go < 0.05)
	yaw += Kit.spring(S.lead, Kit.clamp(LEAD * turning, -LEAD_MOST, LEAD_MOST) * go, 0.5 / tick, 1, dt)
	local level = look - HEAD_STILL * pitch
	local bank = -HEAD_STILL * roll
	rx[neck] = Kit.bound(NECK_SHARE * level, NECK_KNEE, NECK_MOST)
	ry[neck] = NECK_TURN * yaw
	rz[neck] = NECK_SHARE * bank
	rx[head] = Kit.bound((1 - NECK_SHARE) * level, HEAD_KNEE, HEAD_MOST)
	ry[head] = (1 - NECK_TURN) * yaw
	rz[head] = (1 - NECK_SHARE) * bank

	-- THE TAIL: its root swung down as the trunk tips, so that the train streams level; behind a turn it trails,
	-- it sways from side to side and nods with the beat, and every feather does what the root does a little
	-- later and a little more, each a little later than its neighbour; gliding, the train is spread
	local tail = S.tail
	local trail = Kit.spring(S.trail, Kit.clamp(-TAIL_TURN * turning, -TAIL_MOST, TAIL_MOST), 0.5 / tick, 0.7, dt)
	local swing = TAU * (SWAY_RATE * t / tick + S.seed)
	local slow = SWAY_SLOW * swing
	local sway, swaySlow = SWAY * (1 - SWAY_PART), SWAY * SWAY_PART
	local nod = NOD * beating
	local spread = 1 - beating
	rx[tail] = TAIL_HOVER + (TAIL_STREAM - TAIL_HOVER) * go + nod * sin(wave - NOD_LAG)
	ry[tail] = trail + sway * sin(swing) + swaySlow * sin(slow)
	for _, feather in S.feathers do
		local b = feather.bones
		local gain = PLUME_GAIN * feather.share
		local late = PLUME_LAG + feather.late
		rx[b[1]] += feather.pitch * spread
		ry[b[1]] += feather.yaw * spread
		Kit.chainBend(pose, b, "y", trail * FEATHER_TRAIL * feather.share, 1)
		Kit.chainWave(pose, b, "y", sway * gain, swing - late, PLUME_LAG, PLUME_GAIN, PLUME_MOST)
		Kit.chainWave(pose, b, "y", swaySlow * gain, slow - late, PLUME_LAG, PLUME_GAIN, PLUME_MOST)
		Kit.chainWave(pose, b, "x", nod * gain, wave - NOD_LAG - late, PLUME_LAG, PLUME_GAIN, PLUME_MOST)
	end
end

return Phoenix
