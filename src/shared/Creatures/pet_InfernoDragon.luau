-- The Inferno Dragon (art/models/ready/pet_InfernoDragon.glb, 37 bones: a spiked fire dragon of the Volcano
-- modelled STANDING on four legs, its neck leaning forward, its wings standing UP from its back with the long
-- finger of each hanging DOWN from a wrist, a tail of eight that curls round to its left and ends in a flame
-- blade beside the left wing's tip; its skeleton was built here by the recipe
-- art/models/rig/pet_InfernoDragon.json). Its joint map and its motion. Look at
-- art/models/rigs/pet_InfernoDragon_left.png and _front.png and at
-- art/models/poses/pet_InfernoDragon_pose_flight.png beside this file; docs/motion/pet_InfernoDragon.md says
-- what was learned on it.
--
-- IT FLIES, AND ONLY FLIES (the owner, 2026-10-13): there is no walk and no standing pose here. Its motion is
-- the Frost Dragon's (pet_FrostDragon.luau, which is the Aurora Owl's: the kit's `soar` for the path and the
-- bank, rounds of beats and a glide by the kit's `beat`, a beat by `chainWave` from the shoulder with the
-- joints after it and a share of sweep, legs and wings by keys, the trunk tipped through a spring of its own,
-- a head held level, a tail that trails and sways as a chain). What THIS body forces:
--   * its wing has a THIRD joint, a real wrist, and as modelled the finger hangs down from it: the wrist is
--     turned OUT as a key (55 degrees gliding, which lays the wing level; 42.5 beating) and 25 forward, and the
--     beat rides on that: the shoulder 27 degrees each way about 5.5 under the wing as modelled (its limits are
--     25 up and 35 down), the elbow 42% of that, the wrist 42% of the elbow and later still (the tip trails);
--   * its two wings ARE a pair (they mirror to 0.003), the legs are not (it is modelled in a walking stance):
--     the legs are keyed by turns only, which mirror;
--   * its neck is shorter and already leans forward: the S is 18 forward at the base and 12 back at the top,
--     and the skull has 20 degrees every way and no more (a horn's foot is fused to a shoulder spike);
--   * its tail is ONE chain of eight and curls right round to its left: six of its joints are eased 8 degrees
--     towards straight (the looked-at key), which also takes the flame blade away from the left wing; the
--     trail and the sway on top are smaller than the Frost Dragon's, to stay inside the sum of 80;
--   * its highest joint is a wing's wrist (0.89 of the model's height), not the skull: every number counted
--     in heights of its skeleton is counted in THAT height.
-- Nothing is mirrored about x 0 but the wings: every key is a TURN, which mirrors.
local Kit = if script then require(script.Parent.Parent.MotionKit) else require("../MotionKit")

local sin, sqrt, max, pi = math.sin, math.sqrt, math.max, math.pi
local TAU = pi * 2
local RAD = pi / 180

local Dragon = {}

-- THE JOINT MAP ---------------------------------------------------------------------------------------------
Dragon.map = {
	count = 37,
	tree = 1665078232,
	-- Root is the handle at the pelvis (it drives nothing); Body_01 the PELVIS (hind legs, tail, the rump),
	-- Body_02 the CHEST, turning just behind the wings' roots (neck, forelegs, wings): it carries so much that
	-- it is never turned
	root = "Root",
	spine = { "Root", "Body_01", "Body_02" },
	-- the neck, leaning forward: its base on the chest, its middle, its top
	neck = { "Neck_01", "Neck_02", "Neck_03" },
	-- the base of the skull: skull, jaw and the crown of horns turn on it as one piece
	head = { "Head" },
	-- the dock to the neck under the flame blade (rigid on the last)
	tail = { "Tail_01", "Tail_02", "Tail_03", "Tail_04", "Tail_05", "Tail_06", "Tail_07", "Tail_08" },
	limbs = {
		-- a wing: its SHOULDER inside the back, its ELBOW, its WRIST in the knob under the claw (the long finger
		-- and most of the pane follow the wrist)
		wingL = { role = "arm", bones = { "Wing_L_01", "Wing_L_02", "Wing_L_03" } },
		wingR = { role = "arm", bones = { "Wing_R_01", "Wing_R_02", "Wing_R_03" } },
		-- a foreleg: shoulder, ELBOW (it points back: a negative turn opens it), wrist, toes
		foreL = { role = "leg", bones = { "FrontLeg_L_01", "FrontLeg_L_02", "FrontLeg_L_03", "FrontLeg_L_04" } },
		foreR = { role = "leg", bones = { "FrontLeg_R_01", "FrontLeg_R_02", "FrontLeg_R_03", "FrontLeg_R_04" } },
		-- a hind leg: hip, STIFLE (it points forward: a positive turn opens it), hock, paw
		hindL = { role = "leg", bones = { "HindLeg_L_01", "HindLeg_L_02", "HindLeg_L_03", "HindLeg_L_04" } },
		hindR = { role = "leg", bones = { "HindLeg_R_01", "HindLeg_R_02", "HindLeg_R_03", "HindLeg_R_04" } },
	},
	-- (the WINGS are twins about the middle between their shoulders, to 0.003 of the file. The LEGS are not a
	-- pair: the right ones stand 0.04 to 0.075 further forward, a walking stance)
	pairs = { { "wingL", "wingR", "pair" } },
}

Dragon.layer = "fly"

-- HOW IT STROLLS in its plot: it cruises and never stops, as the Frost Dragon. `lengths` and `radius` count in
-- heights of its skeleton, which is 0.89 of the model's (the Frost Dragon's 0.695): 2.5 of the MODEL's heights
-- a second and circles no tighter than 6.3 of them, the Frost Dragon's, are 2.8 and 7 of these.
Dragon.stroll = { lengths = 2.8, rest = { 0, 0 }, radius = 7, cruise = true }

-- (what the tools draw and measure as its legs)
Dragon.legs = {
	{ id = "LF", name = "left foreleg", chain = Dragon.map.limbs.foreL.bones },
	{ id = "RF", name = "right foreleg", chain = Dragon.map.limbs.foreR.bones },
	{ id = "LH", name = "left hind leg", chain = Dragon.map.limbs.hindL.bones },
	{ id = "RH", name = "right hind leg", chain = Dragon.map.limbs.hindR.bones },
}

-- ITS TIME, ITS SIZE ----------------------------------------------------------------------------------------
-- Every tempo is counted in its own unit of time, the square root of (half the height of its skull / G), as
-- the Frost Dragon's. Its skeleton's height is a wing's wrist; the skull's joint is at 0.82 of that: half is 0.41.
local SIZE = 0.41
local LENGTH = 1.3 -- nose to the tail's bend, in heights of its skeleton (0.954 of 0.743 in the file; `soar` counts in these)

-- HOW HIGH, where no layer holds it (an animal of the zones, a picture of it) ----------------------------------
local MOVE = 0.12 -- body lengths a second: moved faster than this it rises to its full height (the Frost Dragon's)
local RISE = 0.7 -- how quickly it is up, and down again (1 / its unit of time; the Frost Dragon's)
-- heights of its skeleton it holds itself up while it hangs still (the Frost Dragon's): the deepest beat
-- going leaves its wing tips 6.3% of the model's height (7% of the skeleton's) UNDER the ground with no lift
-- at all (looked at); hanging still, 7 degrees steeper, the lowest of its mesh is 3% under it (measured):
-- this keeps a hand's breadth, 0.12, under that
local LOW_STILL = 0.15
-- ... and while it is moved: banked 23 degrees, a wing's tip is 0.26 of its height lower (the Frost Dragon's 0.6)
local LOW = 0.6

-- THE BODY --------------------------------------------------------------------------------------------------
-- (the path: a rise and a dip every 7 body lengths, low and flat, because the skull has 3 degrees left to
-- hold the head level with; a bank of up to 23 degrees, which the neck's roll can take out: the Frost Dragon's)
local PATH = { wave = 0.06, every = 7, steep = 0.1, bank = 0.7, most = 0.4, quick = 2.5 }
-- radians its trunk is tipped nose down about its pelvis to go: 12 degrees, which lays its back level (it is
-- modelled rising 16 to 20 to the front; the looked-at key) ...
local LEVEL = 12 * RAD
-- ... and while it hovers: 5 degrees, steeper in the air as a heavy flyer hangs on its wings (the Frost Dragon's)
local HOVER = 5 * RAD
local TIP = 0.5 -- how quickly it tips to go and comes up again (1 / its unit of time; the Frost Dragon's)
local HEAVE = 0.023 -- heights it rises on each downstroke (the Frost Dragon's 0.03 of a skeleton 0.695 of its model)

-- THE WINGS: keys of shoulder, elbow and wrist, { rx, ry, rz } written for the RIGHT wing (radians from the
-- wing it is modelled with, standing up with its finger hanging: a positive rz raises it and turns the wrist
-- OUT, a positive ry sweeps it forward) ------------------------------------------------------------------------
-- gliding: the shoulder 5 degrees down, the wrist 30 OUT (a clear V, the wings about 20 degrees over level,
-- half way between level and the wing as modelled) and 25 forward (which opens the sweep); the looked-at key
-- OWNER 2026-10-13: was 55 out (its limit), which laid the raised wing level; he wants it held higher
local GLIDE = { { 0, 0, -5 * RAD }, { 0, 0, 0 }, { 0, 25 * RAD, 30 * RAD } }
-- the middle of a beat: the shoulder 5.5 down (between its 25 up and 35 down, with room both ways), the elbow
-- 2.5 down (between its 10 up and 15 down), the wrist 42.5 out (the looked-at keys have 45 at the top of the
-- beat and 40 at the bottom) and the same 25 forward
local STROKE = { { 0, 0, -5.5 * RAD }, { 0, 0, -2.5 * RAD }, { 0, 25 * RAD, 42.5 * RAD } }
-- radians the shoulder beats, each way: from 32.5 degrees under the wing as modelled to 21.5 over it (the
-- limits are 35 and 25; the looked-at top and bottom are 35 and 25)
local BEAT = 27 * RAD
local BEAT_HOVER = 28.6 * RAD -- ... while it hovers: higher at the top (24.7 of the 25), as deep at the bottom
-- a joint of the wing beats this share of the one before it: the elbow 11.3 degrees (8.8 up, 13.8 down; the
-- Frost Dragon's 0.45 passes its 10 up while it hovers), the wrist 4.8 about its key (38 to 47 out)
local BEAT_GAIN = 0.42
local BEAT_LAG = 0.9 -- radians of the beat a joint is behind the one before it (the Frost Dragon's): the tip trails
local BEAT_MOST = 0.8 -- radians a joint of the wing beats at most (the kit's cap; never reached)
-- the share of a beat that is also a sweep about the upright (the Frost Dragon's): forward on its way down,
-- back on its way up. 10.8 degrees each way at the shoulder, of the 30 it allows; the wrist 27 of its 30
local SWEEP = 0.4
local FLAP = 0.24 -- beats in one unit of its time (the Frost Dragon's): slow
local QUICK = 0.2 -- how much quicker it beats while it hovers (the Frost Dragon's)
local CYCLE = 9 -- beats one round takes: a few beats, then a long glide (the Frost Dragon's)
local FLAPS = { 3, 4 } -- beats of a round: at least, at most (the Frost Dragon's)
local CLIMB = 0.25 -- climbing faster than this share of its pace, it beats all the time (the Frost Dragon's)
local BEAT_ON = 1.0 -- how quickly the beat comes in and goes out (1 / its unit of time; the Frost Dragon's)
local BEATING = { flap = FLAP, quick = QUICK, cycle = CYCLE, flaps = FLAPS, climb = CLIMB, on = BEAT_ON }

-- THE LEGS: laid back along the belly, always (keys, looked at; radians) -------------------------------------
-- a foreleg: the shoulder 42 degrees back (its limit is 45), the elbow opened 15, wrist and toes curled 30, 20
local FORE = { { -42 * RAD, 0, 0 }, { -15 * RAD, 0, 0 }, { -30 * RAD, 0, 0 }, { -20 * RAD, 0, 0 } }
-- a hind leg: the hip 42 back (45), the stifle opened 15, hock and paw stretched back 30 and 30 (60, 40)
local HIND = { { -42 * RAD, 0, 0 }, { 15 * RAD, 0, 0 }, { -30 * RAD, 0, 0 }, { -30 * RAD, 0, 0 } }
-- radians a leg's top joint gives with every beat (1 degree: the body heaves and the legs are late) ...
local LEG_NOD = 1 * RAD
local LEG_LAG = 1.6 -- ... radians of the beat behind the wings (the Frost Dragon's)

-- THE NECK AND THE HEAD ----------------------------------------------------------------------------------------
-- the S that brings the head forward and low: base, middle, top (radians; the base may go 30 forward, the top
-- 20 back; looked at)
local NECK = { -18 * RAD, 0, 12 * RAD }
local NECK_STILL = 0.6 -- the share of the path's tip the middle of the neck takes out (it has room both ways) ...
local HEAD_STILL = 0.9 -- ... and of the whole tip that is taken out in the end (the Frost Dragon's)
-- radians the skull tips back: freely to 17 degrees, eased towards 20, which it never reaches (past it the
-- fused foot of a horn stretches)
local HEAD_KNEE = 17 * RAD
local HEAD_MOST = 20 * RAD
local ROLL_STILL = 0.9 -- the share of the bank the neck takes out ...
local ROLL_SHARE = { 0, 0.25, 0.25, 0.5 } -- ... base, middle, top, skull (10 degrees at the skull at most, of its 20)
-- it looks about while it hovers, slowly, with the whole neck: 30 degrees to a side (the neck's sum is 45,
-- and the lead into a turn comes on top; the skull takes 30% of it, 13 of its 20), hardly up (the skull is
-- near its limit) and a little down. `turn` is counted in units of ITS time here and made seconds when it is
-- made: a heavy head turns slowly (the Frost Dragon's, all of it)
local LOOK = { yaw = 0.52, up = 0.04, down = 0.15, turn = 4, least = 1.5, mean = 6, aside = 2.5, most = 18, home = 0.7 }
local YAW_SHARE = { 0.2, 0.25, 0.25, 0.3 } -- how a look is shared: base, middle, top, skull
-- radians the head goes ahead into a turn of one radian a second (the Frost Dragon's) ...
local LEAD = 0.4
local LEAD_MOST = 0.22 -- ... at most (12.6 degrees: with a look of 30 inside the neck's 45)

-- THE TAIL: eight joints, the flame blade rigid on the last ---------------------------------------------------------
-- (it lies BACK: a positive rx swings it DOWN, a positive ry to its RIGHT, which is towards straight)
-- radians its dock and the joint after it are lifted (5.5 and 4 degrees; the looked-at key has 6 and 4, and
-- half a degree less keeps the dock inside the 0.1 radians "its tail hangs as modelled" allows hovering; the
-- dock may be lifted 15, beyond it passes into the left wing) ...
local TAIL_LIFT = { -5.5 * RAD, -4 * RAD }
-- ... and the second to the seventh joint are eased towards straight: 8 degrees each, 48 in all (the
-- looked-at key: the blade is then clear of the left wing in every row; the sum of the eight may be 80 with
-- the trail and the sway on top). The blade's own joint is left as it is
local TAIL_EASE = 8 * RAD
local TAIL_EASED = 7 -- the last joint that is eased
local TAIL_TURN = 0.25 -- radians the dock trails behind a turn of one radian a second (the Frost Dragon's) ...
-- ... at most (6.9 degrees, 17 down the chain; the Frost Dragon's 0.15 would pass the sum of 80 in a turn to
-- its right, where the trail goes the way of the ease)
local TAIL_MOST = 0.12
local TAIL_GAIN = 0.6 -- ... and every joint after it that share of the one before (the Frost Dragon's)
-- radians the dock sways from side to side (2.3 degrees, 11 down the chain of eight; the Frost Dragon's 0.05
-- on seven joints): towards its left a sway takes the ease back, and the blade towards the wing ...
local SWAY = 0.04
local SWAY_RATE = 0.04 -- ... times in one unit of its time (the Frost Dragon's)
local NOD = 0.025 -- radians the dock nods with every beat (the Frost Dragon's; it may lift 15 and drop 20)
local NOD_LAG = 1.2 -- radians of the beat the dock is behind the wings (the Frost Dragon's)
local CHAIN_GAIN = 1.15 -- a joint swings this share of the one before it (the Frost Dragon's)
local CHAIN_LAG = 0.6 -- ... and this much of the swing later (the Frost Dragon's)
local CHAIN_MOST = 0.2 -- radians a joint sways or nods at most (the Frost Dragon's)

function Dragon.new(rig, info)
	local seed = info.seed or 0
	local dice = Kit.dice(seed)
	local h = rig.height
	local tick = sqrt(SIZE * h / Kit.G)
	local length = LENGTH * h
	local limbs = Dragon.map.limbs
	local all = {}
	for i = 1, rig.n do
		all[i] = i
	end
	local neck = Kit.chain(rig, "the neck")
	local head = Kit.chain(rig, "the head")[1]
	local look = table.clone(LOOK)
	look.turn = LOOK.turn * tick
	local S = {
		pose = Kit.newPose(rig),
		dice = dice,
		seed = seed,
		h = h,
		tick = tick,
		length = length,
		pace = Dragon.stroll.lengths * h,
		all = all,
		root = rig.root,
		body = Kit.bone(rig, "Body_01"),
		neck = neck,
		head = head,
		column = { neck[1], neck[2], neck[3], head },
		tail = Kit.chain(rig, "the tail"),
		look = look,
		legs = {
			{ limb = Kit.limb(rig, limbs.foreR.bones), key = FORE },
			{ limb = Kit.limb(rig, limbs.foreL.bones, true), key = FORE },
			{ limb = Kit.limb(rig, limbs.hindR.bones), key = HIND },
			{ limb = Kit.limb(rig, limbs.hindL.bones, true), key = HIND },
		},
		wings = {
			Kit.limb(rig, limbs.wingR.bones),
			Kit.limb(rig, limbs.wingL.bones, true),
		},
		fresh = true,
		-- what the kit's `soar` is handed (it writes the path and the bank onto the root)
		glider = Kit.glider({ length = length }, seed),
		flight = { yaw = 0, speed = 0, jump = false, air = 1, climb = 0 },
		high = { x = 0, v = 0 },
		tipped = { x = 0, v = 0 },
		lead = { x = 0, v = 0 },
		trail = { x = 0, v = 0 },
		gaze = Kit.newGaze(),
	}
	Kit.newBeat(S, seed, BEATING)
	return S
end

function Dragon.step(S, dt, input)
	local pose = S.pose
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local t, tick, h = input.t, S.tick, S.h
	local air = input.air or 0
	local climb = input.climb or 0
	local v = input.speed
	Kit.zero(pose, S.all)

	-- HOW HIGH: it is always in the air. `high` is 1 in its layer and when it is moved, 0 while it hangs still
	-- with no layer (eased): there it holds itself up a little, moved with no layer it holds itself up more
	local want = max(air, Kit.smooth(v / (MOVE * S.length)))
	local high
	local reset = S.fresh or input.jump or dt <= 0 or dt > 0.4
	if reset then
		S.fresh = false
		S.high.x, S.high.v = want, 0
		high = want
		dt = max(dt, 0)
	else
		high = Kit.clamp(Kit.spring(S.high, want, RISE / tick, 1, dt), 0, 1)
	end

	-- THE BODY: the kit's path and bank on the root; the trunk tipped nose down about its pelvis: a little
	-- while it hovers, level when it goes
	local flight = S.flight
	-- (`high` is also the share of the path's wave and of the bank it gets: hanging still with no layer it
	-- hangs where it is, not at the height of a wave it is not flying)
	flight.yaw, flight.speed, flight.jump, flight.air, flight.climb = input.yaw, v, input.jump, high, climb
	local go = Kit.soar(S.glider, pose, dt, flight, PATH, S.root)
	local turning = S.glider.w
	local lean, roll = rx[S.root], rz[S.root]
	pose.bob = pose.bob + (LOW_STILL + (LOW - LOW_STILL) * high) * h * (1 - air)
	-- (how far it is tipped to go, 0 to 1: it follows `go` softly, and at once when it was put somewhere)
	if reset then
		S.tipped.x, S.tipped.v = go, 0
	end
	local stream = Kit.clamp(Kit.spring(S.tipped, go, TIP / tick, 1, dt), 0, 1)
	local tip = -(HOVER + (LEVEL - HOVER) * stream)
	rx[S.body] = tip

	-- THE BEAT: rounds of a few beats and a long glide; hovering and climbing it beats all the time
	local beating, wave = Kit.beat(S, dt, go, 1, climb, BEATING)
	pose.bob -= HEAVE * h * beating * sin(wave - 0.5)

	-- THE WINGS: laid level to glide or at the middle of their beat, and beating from the shoulder, the elbow
	-- after it and the wrist after that; down and forward, up and back
	local more = (BEAT_HOVER - BEAT) * (1 - go)
	local amount = (BEAT + more) * beating
	for _, wing in S.wings do
		local side = wing.mirror
		Kit.key(pose, wing, GLIDE, 1 - beating)
		Kit.key(pose, wing, STROKE, beating)
		-- (hovering it beats higher, not deeper: the middle of the beat rises by what the beat grows)
		rz[wing.bones[1]] += side * more * beating
		Kit.chainWave(pose, wing.bones, "z", side * amount, wave, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
		Kit.chainWave(pose, wing.bones, "y", -side * SWEEP * amount, wave, BEAT_LAG, BEAT_GAIN, BEAT_MOST)
	end

	-- THE LEGS: laid back along the belly, all four, always; they give a degree with every beat
	local give = LEG_NOD * beating * sin(wave - LEG_LAG)
	for _, leg in S.legs do
		Kit.key(pose, leg.limb, leg.key, 1)
		rx[leg.limb.bones[1]] += give
	end

	-- THE NECK AND THE HEAD: the S that brings the head forward and low; the middle of the neck takes out most
	-- of what the path tips the body, the skull the rest and the trunk's tip, inside what it allows (eased
	-- towards the limit, never clamped at it); the bank is taken out up the neck; into a turn the head goes
	-- first; hovering it now and then looks somewhere, in one slow move, and holds that
	local neck, head = S.neck, S.head
	local yaw, look = Kit.gaze(S.gaze, t, S.dice, S.look, go < 0.05)
	yaw += Kit.spring(S.lead, Kit.clamp(LEAD * turning, -LEAD_MOST, LEAD_MOST) * go, 0.5 / tick, 1, dt)
	rx[neck[1]] = NECK[1]
	rx[neck[2]] = NECK[2] + NECK_STILL * (look - HEAD_STILL * lean)
	rx[neck[3]] = NECK[3]
	local bent = rx[neck[1]] + rx[neck[2]] + rx[neck[3]]
	rx[head] = Kit.bound(look - HEAD_STILL * (lean + tip) - bent, HEAD_KNEE, HEAD_MOST)
	Kit.spread(pose, S.column, YAW_SHARE, 0, yaw, 0)
	Kit.spread(pose, S.column, ROLL_SHARE, 0, 0, -ROLL_STILL * roll)

	-- THE TAIL: lifted a little at its dock and eased towards straight; behind a turn it trails, it sways
	-- slowly and nods with the beat, and every joint does what the one before it does a little later and a
	-- little more
	local tail = S.tail
	local trail = Kit.spring(S.trail, Kit.clamp(-TAIL_TURN * turning, -TAIL_MOST, TAIL_MOST), 0.5 / tick, 1, dt)
	for k, i in tail do
		rx[i] = TAIL_LIFT[k] or 0
		ry[i] = if k > 1 and k <= TAIL_EASED then TAIL_EASE else 0
	end
	Kit.chainBend(pose, tail, "y", trail, TAIL_GAIN)
	Kit.chainWave(pose, tail, "y", SWAY, TAU * (SWAY_RATE * t / tick + S.seed), CHAIN_LAG, CHAIN_GAIN, CHAIN_MOST)
	Kit.chainWave(pose, tail, "x", NOD * beating, wave - NOD_LAG, CHAIN_LAG, CHAIN_GAIN, CHAIN_MOST)
end

return Dragon
