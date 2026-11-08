-- The Cave Bat (art/models/ready/pet_CaveBat.glb, 24 bones: a small bat modelled STANDING on four short legs
-- like a gargoyle, 38 degrees nose up, its wings spread flat as in flight, big ears, a thin tail that ends in
-- a diamond; its skeleton was built here by the recipe art/models/rig/pet_CaveBat.json). Its joint map and its
-- motion. Look at art/models/rigs/pet_CaveBat_front.png and at art/models/poses/pet_CaveBat_pose_flight.png
-- beside this file; docs/motion/pet_CaveBat.md says what was learned on it.
--
-- Its motion is the Parrot's (pet_Parrot.luau, which is the Seagull's frame on the kit's `limb` and `key`: the
-- kit's `soar` for the path and the bank, a beat by `chainWave` from the shoulder with the joints after it,
-- the trunk tipped about its hips to go, the head held level, legs by keys, a tail that sways and trails).
-- What THIS body forces:
--   * it FLIES AND ONLY FLIES (the owner's rule for a pet with wings): it has no pose for the ground. The
--     Parrot's `aloft` is 1 here, and what is left of it (`high`) only says how HIGH it holds itself where no
--     layer does (as the Frost Dragon);
--   * its wings are spread FLAT at rest (the Seagull's, not the Parrot's upright plane): rest is the glide, the
--     beat is about rest and not under it, and it needs next to no sweep;
--   * a wing has FOUR joints (shoulder, elbow, wrist, finger): the beat's wave runs one joint further;
--   * a bat never glides: every beat of a round is beaten (the Parrot's own note for it);
--   * it stands 38 degrees nose up: to go it tips 30 degrees about its hips, and its head, with no neck, takes
--     that out again inside the 30 degrees its chin and its nape allow; so the path waves less and it banks less;
--   * FOUR legs of two joints, all tucked back in every state; the hind pair trails further back when it goes;
--   * its tail is ONE chain of three and lies BACK (the Parrot's hangs down): it streams with the trunk with no
--     key, and sways and trails from side to side about the upright (yaw);
--   * two big ears of one joint each, which the Parrot has not: they lean back a little as it goes;
--   * the mesh does NOT mirror itself: the wings are not a pair in the map, and only TURNS are mirrored.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, sqrt, max, pi = math.sin, math.sqrt, math.max, math.pi
local TAU = pi * 2

local Bat = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Bat.map = {
	count = 24,
	tree = 1023340613,
	-- Root is the handle in the middle of the trunk (it drives nothing); Body_01 is the WHOLE trunk, one piece.
	-- Its joint lies on the line through the two hips: tipping it levels the animal about its hips
	root = "Root",
	spine = { "Root", "Body_01" },
	-- (no neck: the head sits on the chest)
	-- Head at the base of the skull: skull, face and fangs turn on it as one piece, and the ears hang on it
	head = { "Head" },
	-- the root at the rump, the middle of the thin stalk, where the stalk turns up into the diamond (rigid on it)
	tail = { "Tail_01", "Tail_02", "Tail_03" },
	limbs = {
		-- a wing: SHOULDER (just inside the body's side), ELBOW (where the arm's line turns upward), WRIST (the
		-- top of the wing, where the thumb stands), FINGER (where the long finger turns down to the tip). Arm,
		-- finger and membrane are one plate
		wingL = { role = "arm", bones = { "Wing_L_01", "Wing_L_02", "Wing_L_03", "Wing_L_04" } },
		wingR = { role = "arm", bones = { "Wing_R_01", "Wing_R_02", "Wing_R_03", "Wing_R_04" } },
		-- a front leg: its top in the chest, its ANKLE (the foot and its three toes ride on it)
		frontL = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02" } },
		frontR = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02" } },
		-- a hind leg: the HIP in the rump, its ANKLE
		hindL = { role = "leg", bones = { "HindLeg_L_01", "HindLeg_L_02" } },
		hindR = { role = "leg", bones = { "HindLeg_R_01", "HindLeg_R_02" } },
		-- an ear: one joint at its base, where the plate leaves the skull
		earL = { role = "ear", bones = { "Ear_L_01" } },
		earR = { role = "ear", bones = { "Ear_R_01" } },
	},
	-- (the wings are NOT a pair: the right elbow lies half as far out again as the left one)
	pairs = { { "frontL", "frontR" }, { "hindL", "hindR" }, { "earL", "earR" } },
}

Bat.layer = "fly"

-- HOW IT STROLLS in its plot: as the Seagull and the Parrot, it cruises and never stops. `lengths` and `radius`
-- count in heights of its skeleton, which is 0.685 of the model's (its highest joint is the base of an ear):
-- 4.3 of the model's heights a second and circles of 7 of them, which are the Parrot's.
Bat.stroll = { lengths = 6.3, rest = { 0, 0 }, radius = 10, cruise = true }

-- (what the tools draw and measure as its legs)
Bat.legs = {
	{ id = "LF", name = "left front leg", chain = Bat.map.limbs.frontL.bones },
	{ id = "RF", name = "right front leg", chain = Bat.map.limbs.frontR.bones },
	{ id = "LH", name = "left hind leg", chain = Bat.map.limbs.hindL.bones },
	{ id = "RH", name = "right hind leg", chain = Bat.map.limbs.hindR.bones },
}

-- ITS TIME, ITS SIZE ----------------------------------------------------------------------------------------
-- Every tempo is counted in its own unit of time, the square root of (half its skeleton's height / G), as the
-- Parrot's: 0.12 s for a bat of 1.5 studs (its skeleton 1.03). A big one beats slowly.
local SIZE = 0.5
-- nose to the tail's tip as it flies, in heights of its skeleton (0.83 of 0.473 in the file; the kit's `soar`
-- counts in these)
local LENGTH = 1.7

-- HOW HIGH, where no layer holds it (an animal of the zones, a picture of it) ----------------------------------
local MOVE = 0.12 -- body lengths a second: moved faster than this it rises to its full height (the Parrot's)
local RISE = 0.9 -- how quickly it is up, and down again (1 / its unit of time; the Parrot's)
-- heights of its skeleton it holds itself up while it hovers with no layer: at the bottom of a beat the wing
-- tips are the lowest of it, 0.15 under where the ground was (measured); this keeps a hand's breadth under them
local LOW_STILL = 0.25
-- ... and while it is moved: banked 24 degrees at the bottom of a beat a wing's tip is 0.53 under it, and the
-- wave of its path takes it 0.14 lower still (measured, the turn to its right, whose wing is the longer)
local LOW = 0.8

-- THE BODY --------------------------------------------------------------------------------------------------
-- (the path: a rise and a dip every 6 body lengths, lower than the Parrot's, so that the head, which is at its
-- limit when the trunk is tipped, does not have to nod with it; a bank of up to 24 degrees, which is what the
-- head's roll (limit 25) can take out again. The Aurora Owl's numbers, for the same two reasons)
local PATH = { wave = 0.08, every = 6, steep = 0.2, bank = 0.7, most = 0.42, quick = 3 }
-- (it is modelled 38 degrees nose up: that is how it hovers. To go it tips 30 degrees forward about its hips,
-- which leaves it 8 degrees nose up: the glide stage A looked at)
local LEVEL = 0.524
local HEAVE = 0.02 -- heights it rises on each downstroke (the Parrot's)

-- THE WINGS: a key of shoulder, elbow, wrist, finger, { rx, ry, rz } written for the RIGHT wing (radians from
-- the spread wing it is modelled with: a negative rz lowers it, a positive ry sweeps it forward) -----------
-- the middle of a beat: rest, with the wrist and the finger 2.5 degrees down, so that they give more at the
-- bottom of a beat than at the top (stage A's two ends of a beat: 10 up, 15 down)
local STROKE = { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, -0.044 }, { 0, 0, -0.044 } }
-- radians the shoulder beats, each way: 34 degrees over rest to 34 under it (stage A looked at 35 and 35; the
-- limits are 40 up, where the wing crosses the ear, and 50 down)
local BEAT = 0.59
local BEAT_HOVER = 0.625 -- ... while it hovers: 38 at the top (2 inside the ears' limit), as deep at the bottom
-- each joint beats this share of the one before it (the Parrot's): elbow 19, wrist 10, finger 6 degrees each
-- way, inside their 30; the four together 47 at the same moment, inside the 65 up and 75 down of the whole wing
local BEAT_GAIN = 0.55
local BEAT_LAG = 0.9 -- radians of the beat each is behind the one before (the Parrot's)
local BEAT_MOST = 0.8
-- the share of a beat that is also a sweep about the upright: 5 degrees each way at the shoulder. The plates
-- lie flat, so a beat moves them through the air as they are (the Parrot's upright wings need 0.4)
local SWEEP = 0.15
-- radians of the beat the sweep is AHEAD of it: the wing is furthest forward a little before it is lowest and
-- goes back as it rises, so its tip goes round a narrow loop (down and forward, up and back) and not to and
-- fro along one line. A beat that never stops needs it: with no lead the two ends of the line are alike
local SWEEP_LEAD = 0.5
-- beats in one unit of its time: 3.7 a second at 1.5 studs. No quicker than the Parrot (0.5), though a bat's
-- beat is quick: its swing is wider (68 degrees against 60), and at 60 frames a second the shoulder must not
-- turn more than a quarter of a radian in a frame
local FLAP = 0.45
local QUICK = 0.2 -- how much quicker it beats while it hovers (the Parrot's)
local CYCLE = 14 -- beats one round takes (the Parrot's) ...
local FLAPS = { CYCLE, CYCLE } -- ... and it beats every one of them: a bat never glides
local CLIMB = 0.25 -- (climbing faster than this share of its pace it beats all the time: it does anyway)
local BEAT_ON = 1.2 -- how quickly the beat comes in (1 / its unit of time; the Parrot's)
local BEATING = { flap = FLAP, quick = QUICK, cycle = CYCLE, flaps = FLAPS, climb = CLIMB, on = BEAT_ON }

-- THE LEGS: keys of the top joint and the ankle (pitch only: a negative turn swings a leg BACK) ---------------
-- a front leg, in every state: 45 degrees back along the belly, the foot 30 more, toes trailing (stage A's
-- key, looked at; the limits are 50 and 45)
local FRONT_TUCK = { { -0.785, 0, 0 }, { -0.524, 0, 0 } }
-- a hind leg while it hovers: 20 degrees back, the foot 30 more ...
local HIND_HANG = { { -0.349, 0, 0 }, { -0.524, 0, 0 } }
-- ... and 20 more at the hip as it goes: trailing 40 back under the tail's root (stage A's key; the limit is 50)
local HIND_TRAIL = { { -0.349, 0, 0 } }
local TRAIL_SWING = 0.8 -- how softly they are laid back as it goes (1 = no swing past; the Parrot's)

-- THE HEAD --------------------------------------------------------------------------------------------------
local HEAD_STILL = 0.9 -- the share of the body's tip and bank it takes out again (it has no neck to share with)
-- radians it tips: freely to 26 degrees, then eased towards 30, which it never reaches (from 30 the chin passes
-- into the chest or the nape into the back)
local HEAD_KNEE = 0.45
local HEAD_MOST = 0.524
-- ... and rolls: freely to 20 degrees, eased towards 25 (from 30 the ears pass into the wings' roots)
local ROLL_KNEE = 0.35
local ROLL_MOST = 0.436
-- it looks about while it hovers, as the Parrot, but 29 degrees to a side (the Parrot 40: this head's limit is
-- 40, and the lead into a turn comes on top)
local LOOK =
	{ yaw = 0.5, up = 0.15, down = 0.25, turn = 0.22, least = 1.2, mean = 5, aside = 2, most = 16, home = 0.75 }
local LEAD = 0.25 -- radians the head goes ahead into a turn of one radian a second (the Parrot's) ...
local LEAD_MOST = 0.15 -- ... at most: 9 degrees (the Parrot 17)

-- THE EARS ----------------------------------------------------------------------------------------------------
local EAR_BACK = 0.14 -- radians they lean back as it goes (8 degrees; a flick may be 30)
local EAR_BEAT = 0.03 -- radians they nod with every beat (the body heaves and they are late) ...
local EAR_LAG = 1.2 -- ... this much of the beat behind the wings

-- THE TAIL: its root, the middle of its stalk, its diamond ----------------------------------------------------
-- (it lies BACK: a positive ry swings it to its right. Tipped with the trunk it streams level: no key)
local TAIL_TURN = 0.25 -- radians the root trails behind a turn of one radian a second (the Parrot's) ...
local TAIL_MOST = 0.25 -- ... at most
local TAIL_GAIN = 0.6 -- ... and the middle that share of it again, the diamond of the middle's
local SWAY = 0.06 -- radians the root sways from side to side (the Parrot's) ...
local SWAY_RATE = 0.06 -- ... times in one unit of its time (once in 2 s at 1.5 studs)
local NOD = 0.05 -- radians the root nods with every beat (the body heaves and the tail is late)
local NOD_LAG = 1.2 -- radians of the beat the root is behind the wings
-- the middle swings this share of the root, the diamond of the middle: each a little more (the Parrot's
-- feathers). With the trail 20 degrees a joint at the very most, of the 40 each may, and 60 the first two
local PLUME_GAIN = 1.3
local PLUME_LAG = 0.7 -- ... and this much of the swing later
local PLUME_MOST = 0.35

function Bat.new(rig, info)
	local seed = info.seed or 0
	local dice = Kit.dice(seed)
	local h = rig.height
	local tick = sqrt(SIZE * h / Kit.G)
	local length = LENGTH * h
	local tail = Kit.chain(rig, "the tail")
	local all = {}
	for i = 1, rig.n do
		all[i] = i
	end
	local limbs = Bat.map.limbs
	local S = {
		pose = Kit.newPose(rig),
		dice = dice,
		seed = seed,
		h = h,
		tick = tick,
		length = length,
		pace = Bat.stroll.lengths * h,
		all = all,
		root = rig.root,
		body = Kit.bone(rig, "Body_01"),
		head = Kit.chain(rig, "the head")[1],
		tail = tail[1],
		stalk = { tail[2], tail[3] },
		ears = { Kit.chain(rig, "earL")[1], Kit.chain(rig, "earR")[1] },
		front = {
			Kit.limb(rig, limbs.frontR.bones),
			Kit.limb(rig, limbs.frontL.bones, true),
		},
		hind = {
			Kit.limb(rig, limbs.hindR.bones),
			Kit.limb(rig, limbs.hindL.bones, true),
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
		laid = { x = 0, v = 0 },
		lead = { x = 0, v = 0 },
		trail = { x = 0, v = 0 },
		gaze = Kit.newGaze(),
	}
	Kit.newBeat(S, seed, BEATING)
	return S
end

function Bat.step(S, dt, input)
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

	-- THE BODY: the kit's path and bank on the root; the trunk tipped about its hips: as modelled (nose up)
	-- when it hovers, forward when it goes
	local flight = S.flight
	-- (`high` is also the share of the path's wave and of the bank it gets: hovering on the spot with no layer
	-- it hangs where it is)
	flight.yaw, flight.speed, flight.jump, flight.air, flight.climb = input.yaw, v, input.jump, high, climb
	local go = Kit.soar(S.glider, pose, dt, flight, PATH, S.root)
	local turning = S.glider.w
	local roll = rz[S.root]
	pose.bob = pose.bob + (LOW_STILL + (LOW - LOW_STILL) * high) * h * (1 - air)
	local tip = -LEVEL * go
	rx[S.body] = tip
	local pitch = rx[S.root] + tip

	-- THE BEAT: it never glides (every beat of a round is beaten)
	local beating, wave = Kit.beat(S, dt, go, 1, climb, BEATING)
	pose.bob -= HEAVE * h * beating * sin(wave - 0.5)

	-- THE WINGS: spread as modelled, beating about that from the shoulder, the elbow, the wrist and the finger
	-- after it; a little forward on the way down and back on the way up
	local more = (BEAT_HOVER - BEAT) * (1 - go)
	local amount = (BEAT + more) * beating
	for _, wing in S.wings do
		local side = wing.mirror
		Kit.key(pose, wing, STROKE, beating)
		-- (hovering it beats higher, not deeper: the middle of the beat rises by what the beat grows)
		rz[wing.bones[1]] += side * more * beating
		Kit.chainWave(pose, wing.bones, "z", side * amount, wave, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
		Kit.chainWave(pose, wing.bones, "y", -side * SWEEP * amount, wave + SWEEP_LEAD, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
	end

	-- THE LEGS: tucked in every state; the hind pair hangs a little while it hovers and trails when it goes
	local laid = Kit.clamp(Kit.spring(S.laid, go, 0.6 / tick, TRAIL_SWING, dt), 0, 1)
	for _, leg in S.front do
		Kit.key(pose, leg, FRONT_TUCK, 1)
	end
	for _, leg in S.hind do
		Kit.key(pose, leg, HIND_HANG, 1)
		Kit.key(pose, leg, HIND_TRAIL, laid)
	end

	-- THE HEAD: level and still over a body that tips and banks, inside what its chin and its nape allow (eased
	-- towards the limit, never clamped at it); into a turn it goes first; hovering it now and then looks
	-- somewhere, in one move, and holds that
	local head = S.head
	local yaw, look = Kit.gaze(S.gaze, t, S.dice, LOOK, go < 0.05)
	yaw += Kit.spring(S.lead, Kit.clamp(LEAD * turning, -LEAD_MOST, LEAD_MOST) * go, 0.5 / tick, 1, dt)
	rx[head] = Kit.bound(look - HEAD_STILL * pitch, HEAD_KNEE, HEAD_MOST)
	ry[head] = yaw
	rz[head] = Kit.bound(-HEAD_STILL * roll, ROLL_KNEE, ROLL_MOST)

	-- THE EARS: leaning back as it goes, nodding a little after every beat
	local flick = EAR_BACK * go + EAR_BEAT * beating * sin(wave - EAR_LAG)
	for _, ear in S.ears do
		rx[ear] = flick
	end

	-- THE TAIL: streaming with the trunk; behind a turn it trails, it sways from side to side and nods with the
	-- beat, and the middle and the diamond do what the root does a little later and a little more
	local tail, stalk = S.tail, S.stalk
	local trail = Kit.spring(S.trail, Kit.clamp(-TAIL_TURN * turning, -TAIL_MOST, TAIL_MOST), 0.5 / tick, 0.7, dt)
	local swing = TAU * (SWAY_RATE * t / tick + S.seed)
	local nod = NOD * beating
	rx[tail] = nod * sin(wave - NOD_LAG)
	ry[tail] = trail + SWAY * sin(swing)
	Kit.chainBend(pose, stalk, "y", trail * TAIL_GAIN, TAIL_GAIN)
	Kit.chainWave(pose, stalk, "y", SWAY * PLUME_GAIN, swing - PLUME_LAG, PLUME_LAG, PLUME_GAIN, PLUME_MOST)
	Kit.chainWave(pose, stalk, "x", nod * PLUME_GAIN, wave - NOD_LAG - PLUME_LAG, PLUME_LAG, PLUME_GAIN, PLUME_MOST)
end

return Bat
