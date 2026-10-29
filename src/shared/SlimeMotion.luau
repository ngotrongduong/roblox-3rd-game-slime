--!strict
-- How a slime body moves, as a soft jelly with weight (the owner, 2026-10-29: the 2D original's "no squash before a
-- hop, no landing squash" vetoes do not apply in 3D). Pure numbers, no Roblox datatypes, so Lune tests it.
--
-- The body is a few damped springs (squash, lean forward, lean sideways, turn, width puff) plus a ballistic hop.
-- A motion does not play a curve: it moves the springs' TARGETS (a sway, a droop, a puff) and calls `hop`, and the
-- springs ring and settle by themselves, so a landing squashes and wobbles and a sudden target wobbles too. A hop is
-- crouch (anticipation) -> launch -> stretch in the air -> land (a kick into the squash spring) -> the wobble.
-- Blinks and emotion swaps nudge the springs a little (`kick`).
--
-- `step` returns the pose: sy / sx (height and width factors), leanFwd / leanSide (tip shear, body heights, see
-- SlimeShape), yaw (radians about the feet), lift (body heights). The client turns it into Bone.Transform.

local Config = if script then require(script.Parent.Config) else require("./Config")

local C = Config.Slime

local SlimeMotion = {}

type Spring = { x: number, v: number, to: number }

export type State = {
	t: number, -- seconds since the slime appeared
	phase: number, -- this slime's own offset so a crowd does not breathe in step
	motion: string,
	motionT: number, -- seconds in this motion
	sq: Spring, -- squash: log of the height factor
	lf: Spring, -- tip leans toward the front
	ls: Spring, -- tip leans toward the slime's left (the viewer's right)
	yw: Spring, -- turn about the feet
	pf: Spring, -- extra width (an angry puff)
	y: number, -- lift in body heights
	vy: number,
	hop: { stage: string, t: number, h: number }?,
	hopCount: number,
	evT: number, -- countdown a motion uses for its recurring events
	landed: boolean, -- set on touchdown; the caller clears it
	launched: boolean,
	walking: boolean,
	-- The gait being walked (one Config.Gaits entry; nil = the default numbers of Config.Slime): this slime's own
	-- hop and spring numbers, so no gait ever changes a global.
	gait: any,
	-- While a glide slides: its bob (a squash wave), Hz, forward lean, and how fast it goes now (0..1).
	glide: { bob: number, hz: number, lean: number, k: number }?,
}

export type Ctx = {
	dirFwd: number, -- toward the target: unit direction in the slime's own frame (0, 0 = no target)
	dirSide: number,
}

export type Pose = {
	sy: number,
	sx: number,
	leanFwd: number,
	leanSide: number,
	yaw: number,
	lift: number,
}

local TAU = math.pi * 2

local function spring(): Spring
	return { x = 0, v = 0, to = 0 }
end

-- (a tiny seeded generator: the Roblox `Random` is not in Lune)
local function unitFrom(seed: number, salt: number): number
	local s = (math.floor(seed) * 7919 + salt * 104729 + 12345) % 2147483647
	s = (s * 1103515245 + 12345) % 2147483647
	s = (s * 1103515245 + 12345) % 2147483647
	return s / 2147483647
end

function SlimeMotion.new(seed: number?): State
	local sd = seed or 1
	return {
		t = unitFrom(sd, 1) * 10,
		phase = unitFrom(sd, 2) * TAU,
		motion = "idle",
		motionT = 0,
		sq = spring(),
		lf = spring(),
		ls = spring(),
		yw = spring(),
		pf = spring(),
		y = 0,
		vy = 0,
		hop = nil,
		hopCount = 0,
		evT = unitFrom(sd, 3) * 2,
		landed = false,
		launched = false,
		walking = false,
		gait = nil,
		glide = nil,
	}
end

function SlimeMotion.set(st: State, motion: string)
	if st.motion ~= motion then
		st.motion = motion
		st.motionT = 0
	end
end

-- A small shove into a spring: "squash" (negative = squash, positive = stretch), "lean", "turn", "puff".
function SlimeMotion.kick(st: State, what: string, amount: number)
	if what == "squash" then
		st.sq.v += amount
	elseif what == "lean" then
		st.lf.v += amount
	elseif what == "side" then
		st.ls.v += amount
	elseif what == "turn" then
		st.yw.v += amount
	elseif what == "puff" then
		st.pf.v += amount
	end
end

-- A hop of height h (body heights): crouch first, unless `snap` (a startle jumps with no warning).
function SlimeMotion.hop(st: State, h: number, snap: boolean?)
	if st.hop or st.y > 0 then
		return
	end
	st.hop = { stage = if snap then "launch" else "crouch", t = 0, h = h }
end

local function launch(st: State, h: number)
	local P = st.gait or C
	st.vy = math.sqrt(2 * P.Gravity * h)
	st.y = 1e-4
	st.sq.v += 2.2
	st.launched = true
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function pulse(x: number): number
	local s = math.max(0, math.sin(x))
	return s * s
end

-- Count down an event timer and tell the motion when it fires.
local function every(st: State, dt: number, seconds: number, jitter: number): boolean
	st.evT -= dt
	if st.evT <= 0 then
		st.evT = seconds * (1 + jitter * (math.random() - 0.5))
		return true
	end
	return false
end

local function hopLoop(st: State, dt: number, seconds: number, h: number, jitter: number)
	if not st.walking and st.hop == nil and st.y == 0 and every(st, dt, seconds, jitter) then
		st.hopCount += 1
		SlimeMotion.hop(st, h)
	end
end

-- The motions: each sets the springs' targets from the time. t = st.t, p = st.phase.
type Driver = (st: State, dt: number, ctx: Ctx) -> ()

local function breathe(st: State, amp: number, hz: number)
	st.sq.to += amp * math.sin(TAU * hz * st.t + st.phase)
end

local drivers: { [string]: Driver } = {}

-- Working motions move the existing jelly springs, never spawn another rig.
drivers.workCast = function(st)
	st.lf.to = -math.rad(Config.Work.WorkShakeDegrees)
	st.sq.to = math.sin(TAU * Config.Work.WorkShakeHz * st.motionT) * Config.Work.WorkBobStuds
end

drivers.workWait = function(st)
	breathe(st, Config.Work.WorkBobStuds, Config.Work.WorkBobHz)
end

drivers.workReel = function(st)
	st.lf.to = math.rad(Config.Work.WorkShakeDegrees) * math.sin(TAU * Config.Work.WorkShakeHz * st.motionT)
	st.sq.to = Config.Work.WorkBobStuds * math.sin(TAU * Config.Work.WorkShakeHz * st.motionT)
end

drivers.workHoe = function(st)
	st.lf.to = math.rad(Config.Work.WorkShakeDegrees) * math.sin(TAU * Config.Work.WorkShakeHz * st.motionT)
	st.sq.to = -Config.Work.WorkBobStuds * math.abs(math.sin(TAU * Config.Work.WorkShakeHz * st.motionT))
end

drivers.workPlant = function(st)
	st.lf.to = math.rad(Config.Work.WorkShakeDegrees)
	st.sq.to = -Config.Work.WorkBobStuds
end

drivers.workWater = function(st)
	st.ls.to = Config.Work.WorkBobStuds * math.sin(TAU * Config.Work.WorkBobHz * st.motionT)
	st.lf.to = -math.rad(Config.Work.WorkShakeDegrees)
end

drivers.workHarvest = function(st)
	st.lf.to = math.rad(Config.Work.WorkShakeDegrees) * math.sin(TAU * Config.Work.WorkShakeHz * st.motionT)
	st.sq.to = Config.Work.WorkBobStuds * math.sin(TAU * Config.Work.WorkShakeHz * st.motionT)
end

drivers.idle = function(st)
	breathe(st, 0.028, 0.55)
end

drivers.bounce = function(st, dt)
	breathe(st, 0.015, 0.7)
	hopLoop(st, dt, 1.15, 0.2, 0.3)
end

drivers.excited = function(st, dt)
	breathe(st, 0.01, 1)
	st.ls.to = 0.03 * math.sin(TAU * 1.6 * st.t)
	hopLoop(st, dt, 0.62, 0.3 + (if st.hopCount % 3 == 2 then 0.12 else 0), 0.2)
end

drivers.laugh = function(st, dt)
	st.sq.to = 0.09 * math.sin(TAU * 5.5 * st.t)
	st.ls.to = 0.06 * math.sin(TAU * 2.75 * st.t + st.phase)
	st.pf.to = 0.02
	hopLoop(st, dt, 1.7, 0.1, 0.5)
end

drivers.love = function(st, dt)
	st.ls.to = 0.1 * math.sin(TAU * 0.45 * st.t + st.phase)
	st.lf.to = 0.02
	breathe(st, 0.03, 0.9)
	hopLoop(st, dt, 2.6, 0.12, 0.4)
end

drivers.admire = function(st, dt)
	st.sq.to = 0.05 + 0.025 * math.sin(TAU * 0.8 * st.t + st.phase)
	st.ls.to = 0.05 * math.sin(TAU * 0.4 * st.t)
	hopLoop(st, dt, 2.1, 0.15, 0.5)
end

drivers.droop = function(st)
	st.sq.to = -0.14 + 0.02 * math.sin(TAU * 0.25 * st.t + st.phase)
	st.lf.to = 0.12 + 0.07 * pulse(TAU * st.t / 11)
	st.pf.to = 0.05
end

drivers.sulk = function(st, dt)
	st.yw.to = 0.95 + 0.03 * math.sin(TAU * 9 * st.t)
	st.sq.to = -0.07 + 0.015 * math.sin(TAU * 0.4 * st.t)
	st.lf.to = 0.07
	if every(st, dt, 4.2, 0.5) then
		st.sq.v -= 2
	end
end

drivers.shiver = function(st)
	st.sq.to = -0.06 + 0.02 * math.sin(TAU * 15 * st.t)
	st.ls.to = 0.035 * math.sin(TAU * 13 * st.t + st.phase)
	st.lf.to = -0.08
	st.pf.to = 0.03
end

drivers.angry = function(st, dt)
	local c = (st.motionT % 1.9) / 1.9
	local env = if c < 0.6 then (c / 0.6) ^ 2 else math.max(0, 1 - (c - 0.6) / 0.4) ^ 2
	st.pf.to = 0.11 * env
	st.sq.to = -0.05 * env + 0.012 * math.sin(TAU * 23 * st.t)
	st.ls.to = 0.02 * env * math.sin(TAU * 19 * st.t)
	if not st.walking and st.hop == nil and st.y == 0 and every(st, dt, 1.9, 0) then
		SlimeMotion.hop(st, 0.07, true)
	end
end

drivers.proud = function(st, dt)
	st.sq.to = 0.07 + 0.015 * math.sin(TAU * 0.6 * st.t)
	st.lf.to = -0.07
	st.pf.to = -0.015
	st.ls.to = 0.03 * math.sin(TAU * 0.35 * st.t)
	hopLoop(st, dt, 3.4, 0.1, 0.3)
end

drivers.sleepy = function(st, dt)
	st.sq.to = -0.06 + 0.05 * math.sin(TAU * 0.28 * st.t + st.phase)
	local period = 4.6
	local since = period - st.evT
	st.lf.to = 0.04 + 0.17 * math.min(since / 2.4, 1) ^ 2
	st.evT -= dt
	if st.evT <= 0 then
		st.evT = period
		st.lf.v -= 1.2
		st.sq.v += 1
	end
end

drivers.sleep = function(st)
	st.sq.to = -0.09 + 0.045 * math.sin(TAU * 0.22 * st.t + st.phase)
	st.lf.to = 0.06 + 0.02 * math.sin(TAU * 0.1 * st.t)
	st.ls.to = 0.02 * math.sin(TAU * 0.07 * st.t)
end

drivers.dizzy = function(st)
	local w = TAU * 0.75
	st.ls.to = 0.13 * math.cos(w * st.t)
	st.lf.to = 0.13 * math.sin(w * st.t)
	st.yw.to = 0.35 * math.sin(TAU * 0.5 * st.t)
	st.sq.to = -0.03 + 0.03 * math.sin(2 * w * st.t)
end

drivers.curious = function(st, dt, ctx)
	st.ls.to = 0.17 * ctx.dirSide + 0.03 * math.sin(TAU * 0.6 * st.t)
	st.lf.to = 0.17 * ctx.dirFwd
	st.sq.to = 0.06
	hopLoop(st, dt, 3.6, 0.1, 0.4)
end

drivers.eat = function(st)
	local s = math.sin(TAU * 2.3 * st.t)
	st.sq.to = 0.07 * s
	st.lf.to = 0.05 + 0.03 * s
	st.pf.to = 0.02 * math.sin(TAU * 2.3 * st.t + 1)
end

drivers.shy = function(st)
	local s = math.sin(TAU * 1.3 * st.t)
	st.yw.to = 0.2 + 0.12 * s
	st.ls.to = 0.06 * s
	st.sq.to = -0.06 + 0.02 * math.sin(TAU * 0.6 * st.t)
end

drivers.startle = function(st, dt)
	local period = 3.4
	local since = period - st.evT
	breathe(st, 0.02, 0.55)
	st.sq.to += 0.06 * math.exp(-since / 0.9)
	st.evT -= dt
	if st.evT <= 0 then
		st.evT = period
		SlimeMotion.hop(st, 0.28, true)
	end
end

drivers.swagger = function(st, dt)
	st.ls.to = 0.08 * math.sin(TAU * 0.55 * st.t + st.phase)
	st.lf.to = -0.04
	st.sq.to = 0.03 + 0.02 * math.sin(TAU * 1.1 * st.t)
	hopLoop(st, dt, 2.8, 0.1, 0.4)
end

drivers.hungry = function(st)
	local c = st.motionT % 2.6
	local env = if c < 0.9 then pulse(math.pi * c / 0.3) else 0
	st.sq.to = -0.07 - 0.05 * env
	st.lf.to = 0.07
	st.pf.to = 0.04 * env
end

drivers.content = function(st, dt)
	st.sq.to = 0.02 + 0.04 * math.sin(TAU * 0.6 * st.t)
	st.pf.to = 0.04
	st.ls.to = 0.04 * math.sin(TAU * 0.35 * st.t)
	hopLoop(st, dt, 3.5, 0.08, 0.4)
end

drivers.bored = function(st)
	local c = st.motionT % 5
	st.ls.to = 0.11 * math.sin(TAU * 0.18 * st.t)
	st.sq.to = -0.05 + (if c < 1.6 then 0.05 * pulse(math.pi * c / 1.6) else 0)
	st.lf.to = 0.05
end

drivers.sob = function(st)
	st.sq.to = -0.08 + 0.05 * math.sin(TAU * 2.8 * st.t) * (0.6 + 0.4 * math.sin(TAU * 0.3 * st.t))
	st.lf.to = 0.1
	st.pf.to = 0.03
end

-- The names a face can ask for.
SlimeMotion.Motions = {} :: { string }
for name in drivers do
	table.insert(SlimeMotion.Motions, name)
end
table.sort(SlimeMotion.Motions)

local function integrate(sp: Spring, hz: number, damping: number, dt: number)
	local w = TAU * hz
	local n = math.max(1, math.ceil(dt / C.SubStep))
	local h = dt / n
	for _ = 1, n do
		local a = w * w * (sp.to - sp.x) - 2 * damping * w * sp.v
		sp.v += a * h
		sp.x += sp.v * h
	end
end

local NO_TARGET: Ctx = { dirFwd = 0, dirSide = 0 }

function SlimeMotion.step(st: State, dt: number, ctx: Ctx?): Pose
	dt = math.clamp(dt, 0, C.MaxStep)
	st.t += dt
	st.motionT += dt
	st.sq.to, st.lf.to, st.ls.to, st.yw.to, st.pf.to = 0, 0, 0, 0, 0
	local driver = drivers[st.motion] or drivers.idle
	driver(st, dt, ctx or NO_TARGET)

	-- a glide: a slide with a bob and a lean forward, on top of the feeling's own motion
	local glide = st.glide
	if glide then
		st.sq.to += glide.bob * math.sin(TAU * glide.hz * st.t) + 0.03 * glide.k
		st.lf.to += glide.lean * glide.k
		st.ls.to += 0.02 * glide.k * math.sin(TAU * glide.hz * 0.5 * st.t)
	end

	-- the hop: crouch, launch, fly, land (with this slime's gait numbers while it walks one)
	local P = st.gait or C
	local hopLean = P.HopLean or 0
	local hop = st.hop
	if hop then
		if hop.stage == "crouch" then
			hop.t += dt
			local k = if P.CrouchSeconds > 0 then smooth(hop.t / P.CrouchSeconds) else 1
			st.sq.to = P.CrouchSquash * k
			st.lf.to -= hopLean * 0.6 * k
			if hop.t >= P.CrouchSeconds then
				hop.stage = "launch"
			end
		end
		if hop.stage == "launch" then
			launch(st, hop.h)
			hop.stage = "air"
		elseif hop.stage == "air" then
			local v0 = math.sqrt(2 * P.Gravity * hop.h)
			st.sq.to = P.AirStretch * math.min(math.abs(st.vy) / v0, 1)
			st.lf.to += hopLean
			st.vy -= P.Gravity * dt
			st.y += st.vy * dt
			if st.y <= 0 and st.vy < 0 then
				st.sq.v -= P.LandKick * -st.vy
				st.pf.v += 0.6 * -st.vy
				st.y = 0
				st.vy = 0
				st.hop = nil
				st.landed = true
			end
		end
	end

	integrate(st.sq, P.SquashHz, P.SquashDamping, dt)
	integrate(st.lf, P.LeanHz, P.LeanDamping, dt)
	integrate(st.ls, P.LeanHz, P.LeanDamping, dt)
	integrate(st.yw, C.YawHz, C.YawDamping, dt)
	integrate(st.pf, C.PuffHz, C.PuffDamping, dt)

	local sq = math.clamp(st.sq.x, -0.7, 0.45)
	return {
		sy = math.exp(sq),
		sx = math.exp(-P.VolumeBulge * sq + math.clamp(st.pf.x, -0.2, 0.3)),
		leanFwd = math.clamp(st.lf.x, -0.4, 0.4),
		leanSide = math.clamp(st.ls.x, -0.4, 0.4),
		yaw = st.yw.x,
		lift = st.y,
	}
end

return SlimeMotion
