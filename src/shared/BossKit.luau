-- What a BOSS's own motion is built from, beside Shared.MotionKit (the legs, the clock, the springs): a boss is
-- an animal with a module of its own (Shared.Creatures.boss_<zoneId>, see Shared.Creature and docs/MOTION.md,
-- Part 2, "How to give a boss its motion") that also sleeps on its nest, wakes with a start, chases, fetches
-- and carries an egg, walks home and looks at somebody. Pure numbers: no Roblox, the tests and the tools run
-- it. Nothing here knows an animal.
--
--   1. `mind`, `think`       WHAT IT IS DOING, as numbers that never jump: the server only says a state
--                            ("Sleep" | "Wake" | "Chase" | "Fetch" | "Carry" | "Return"); `think`
--                            turns it, frame by frame, into how asleep it is, how furious, whether it runs the
--                            full stride, carries, and where it looks. They are fields of the
--                            module's own state, where the client's effects read them (GuardianLife).
--   2. `posture`, `lie`   A POSE WRITTEN ON NAMED JOINTS: the angles of a few bones by their names, the
--                            left side mirrored from the right. `lie` takes the whole body a share of the way
--                            to one (asleep).
--   3. `limb`, `key`         the same for ONE chain (an arm, a wing, a claw), given for the right side: a few
--                            keys and code in between is how an arm is moved.
--   4. `ground`, `settle`    THE BODY ON THE GROUND, measured on the skinned MESH (Shared.BossBodies, its thinned
--                            copy): asleep the lowest point of the mesh lies on the ground, whatever the pose;
--                            awake nothing of it is ever under the ground.
--   5. `aim`, `turnOf`, `hold`, `place`   A HEAD THAT IS LEVEL AND LOOKS: where a point is from the head, as a yaw
--                            and a pitch within the animal's limits; how a bone is turned in the model; the turn
--                            that holds a bone at an angle in the MODEL whatever its parents do; where a bone is.
--   6. `reach`, `under`      A BODY THAT TURNS ITS HIPS (a biped, a waddler) is carried no higher than its legs
--                            reach from where its hips really are.
--   7. `launch`, `soften`    A RUN ON SHORT LEGS: from a stand straight into the run the server sets a boss off
--                            at, and a knee in the air that folds at the speed of a knee.
--
-- The order of a boss's `step`: `think`; the kit's `gait` and `launch`; the trunk's turns; `reach` and `under`
-- for the root's rise; the kit's `solve` and `soften`; arms and whatever else by keys; the head (`hold`); `lie`
-- into the sleeping pose; `settle` on the ground; `place` for where the head is.
--
-- Space, poses and signs are MotionKit's: the creature looks along -z, +x is its right, +y up; a pose is
-- `rx`, `ry`, `rz` a bone (R = Ry * Rx * Rz about the model's axes at the bone's rest joint, adding up down
-- the tree) and `bob`, `ox`, `oz` for the root. A positive `rx` tips the top BACK (a nose goes up, a hanging
-- limb swings forward), a positive `ry` turns to its left, a positive `rz` lifts its right side.
local Kit = if script then require(script.Parent.MotionKit) else require("./MotionKit")
local BossBodies = if script then require(script.Parent.BossBodies) else require("./BossBodies")

local Boss = {}

local sin, cos, sqrt, min, max, atan2, asin, pi =
	math.sin, math.cos, math.sqrt, math.min, math.max, math.atan2, math.asin, math.pi
local clamp, smooth = Kit.clamp, Kit.smooth

local SETTLE = 2.4 -- seconds to lie down when the module does not say
local RISE_MIN = 0.35 -- the least seconds a boss takes to get up (under the server's half-second wake x 0.85)
local RISE_SLEW = 6 -- the most the sleep may change in a second (a jump of the target is not seen)
local RAGE_UP, RAGE_DOWN = 0.3, 0.9 -- seconds to get furious, to calm down
local WALK_RATE = 6 -- how fast "it is going" comes and goes (1/s)
local LOOK_RATE = 3 -- how fast it takes up a look and lets it go (1/s)
local TURN_WAKE, TURN = 12, 7 -- how fast the head follows what it looks at (1/s): startled, and after
local BELLY = 0.012 -- share of the height the lowest point of the mesh lies UNDER the ground: a body that weighs

-- how furious each state is; which states run the full stride (a chase, but also fetching and carrying)
local RAGE_OF = { Wake = 0.6, Chase = 1 }
local RUN_OF = { Chase = 1, Fetch = 1, Carry = 1 }

local function toward(value, target, step)
	if value < target then
		return min(target, value + step)
	end
	return max(target, value - step)
end

-- 1. The mind ---------------------------------------------------------------------------------------------
-- `Boss.mind(S, rig, spec)` gives a module's state `S` the fields below; `Boss.think(S, dt, input)` moves
-- them on, once a frame, BEFORE the module poses anything. `spec`: { settle (seconds to lie down), head (the
-- name of the bone its eyes are in: where it looks FROM, and where the effects hang), look = { yaw, up, down
-- (radians: how far it looks to a side, up and down) } }.
--   state, prev, age     what the server says it does, did before, and for how long (a creature that is told
--                        no state, as in a test of pets, is awake and calm: "Return")
--   sleepP               0 awake to 1 fast asleep, in a straight line (the effects and the client's budget)
--   sleep                the share of its SLEEPING POSE it is in: eased both ways as it lies down; getting up
--                        most of it goes off in the first third of the time: a start, not a slow rise
--   rise                 0, up to 1 in the middle of getting up, and 0 again: the startled hop
--   rage                 0 to 1: Wake 0.6, Chase 1 (the effects' steam)
--   run                  0 to 1: the states the server runs it in (Chase, Fetch, Carry)
--   carry                0 to 1: it carries an egg
--   startle              0 to 1 while it wakes
--   walk                 0 to 1: its model really moves (the effects' dust)
--   lookW, yaw, pitch    how much it looks at something (0 to 1) and where (radians from straight ahead, eased:
--                        a head does not snap; yaw positive to its left)
--   headX, headY, headZ  where its head is in the model (the module sets them: `Boss.place`)
function Boss.mind(S, rig, spec)
	S.spec = spec
	S.eye = Kit.bone(rig, spec.head)
	S.eyeX, S.eyeY, S.eyeZ = rig.px[S.eye], rig.py[S.eye], rig.pz[S.eye]
	S.headX, S.headY, S.headZ = S.eyeX, S.eyeY, S.eyeZ
	S.primed = false
	S.state, S.prev, S.age = "Return", "", 0
	S.sleepP, S.sleep, S.rise, S.owed = 0, 0, 0, 0
	S.rage, S.run, S.carry, S.startle = 0, 0, 0, 0
	S.walk = 0
	S.lookW, S.yaw, S.pitch = 0, 0, 0
	S.yawS, S.pitchS = { x = 0, v = 0 }, { x = 0, v = 0 }
	return S
end

-- The mind jumps to what the state says (a boss seen for the first time, or again after a long while).
local function snap(S, state)
	S.sleepP = if state == "Sleep" then 1 else 0
	S.sleep, S.rise, S.owed = S.sleepP, 0, 0
	S.rage = RAGE_OF[state] or 0
	S.run = RUN_OF[state] or 0
	S.carry = if state == "Carry" then 1 else 0
	S.startle, S.walk, S.lookW = 0, 0, 0
	S.yaw, S.pitch = 0, 0
	S.yawS.x, S.yawS.v, S.pitchS.x, S.pitchS.v = 0, 0, 0, 0
end

-- Where to look: the yaw (positive to its left) and the pitch (positive up) that point along (dx, dy, dz), an
-- offset in the model's space, within `look` = { yaw, up, down }.
function Boss.aim(look, dx, dy, dz)
	if dx * dx + dz * dz < 1e-6 then
		return 0, 0
	end
	local yaw = atan2(-dx, -dz)
	local pitch = atan2(dy, sqrt(dx * dx + dz * dz))
	if yaw ~= yaw or pitch ~= pitch then
		return 0, 0
	end
	local most = (look and look.yaw) or 1.1
	return clamp(yaw, -most, most), clamp(pitch, -((look and look.down) or 0.4), (look and look.up) or 0.4)
end

-- One frame of the mind. `input` is what the client hands a boss's module (GuardianLife): { state, prev, age,
-- wake (seconds it has to get up in), speed, look (true when it looks at something), lookX, lookY, lookZ
-- (that point, in the model's space), fresh (be where the server says at once) } beside what a pet's gets.
function Boss.think(S, dt, input)
	local spec = S.spec
	local state = input.state or "Return"
	if not S.primed or input.fresh then
		S.primed = true
		snap(S, state)
	end
	-- (a boss asleep is only moved a few times a second: the first move that finds it awake comes after a long
	-- frame, which must not be taken out of its getting up in one jump. It starts to rise at that move, and
	-- makes the time up over the next ones, so that it is still up when the server sets it off.)
	local step = dt
	if state == "Sleep" then
		S.owed = 0
	elseif S.state == "Sleep" then
		step = min(dt, 1 / 60)
		S.owed = dt - step
	elseif S.owed > 0 then
		local pay = min(S.owed, 0.5 * dt)
		step, S.owed = dt + pay, S.owed - pay
	end
	S.state, S.prev, S.age = state, input.prev or "", input.age or 0
	-- asleep, or getting up over the time the server allows
	if state == "Sleep" then
		S.sleepP = min(1, S.sleepP + step / (spec.settle or SETTLE))
	else
		S.sleepP = max(0, S.sleepP - step / max(RISE_MIN, input.wake or 0.85))
	end
	-- (lying down eases in and out; getting up is a START: no jump in its first frame, most of the way in the
	-- first third of the time, and settling at the end)
	local p = S.sleepP
	S.sleep = toward(S.sleep, if state == "Sleep" then smooth(p) else 1 - smooth((1 - p) ^ 0.6), step * RISE_SLEW)
	S.rise = toward(S.rise, if state ~= "Sleep" and p > 0 then sin(pi * (1 - p)) else 0, dt * 8)
	-- fury, the full stride, the egg
	local rage = RAGE_OF[state] or 0
	S.rage = toward(S.rage, rage, dt / (if rage > S.rage then RAGE_UP else RAGE_DOWN))
	local run = RUN_OF[state] or 0
	S.run = toward(S.run, run, dt / (if run > S.run then RAGE_UP else RAGE_DOWN))
	S.carry = toward(S.carry, if state == "Carry" then 1 else 0, dt / 0.3)
	S.startle = toward(S.startle, if state == "Wake" then 1 else 0, dt * 3.5)
	-- how much it moves
	local moving = if (input.speed or 0) > 0.5 and state ~= "Sleep" then 1 else 0
	S.walk += (moving - S.walk) * min(1, dt * WALK_RATE)
	if S.walk < 0.01 and moving == 0 then
		S.walk = 0
	end
	-- where it looks: the thief, the hub; the head follows on a spring that does not swing past
	local has = input.look == true and input.lookX ~= nil and state ~= "Sleep"
	S.lookW = toward(S.lookW, if has then 1 else 0, dt * LOOK_RATE)
	if has then
		local yaw, pitch = Boss.aim(spec.look, input.lookX - S.eyeX, input.lookY - S.eyeY, input.lookZ - S.eyeZ)
		local rate = if state == "Wake" then TURN_WAKE else TURN
		S.yaw = Kit.spring(S.yawS, yaw, rate, 1, dt)
		S.pitch = Kit.spring(S.pitchS, pitch, rate, 1, dt)
	elseif S.lookW <= 0 then
		S.yaw, S.pitch = 0, 0
		S.yawS.x, S.yawS.v, S.pitchS.x, S.pitchS.v = 0, 0, 0, 0
	end
end

-- 2. A pose written on named joints -----------------------------------------------------------------------------
-- `list`: rows of { "name", rx, ry, rz } (one bone on the middle line) or { "right", "left", rx, ry, rz } (a
-- pair: the angles are the RIGHT one's, the left one gets them mirrored: rx, -ry, -rz). Radians; what is left
-- out is 0. Every bone may be named once. Returns the posture: `rx`, `ry`, `rz` for every bone of the rig (0
-- for the ones it does not name) and `list`, the places it names.
function Boss.posture(rig, list)
	local n = rig.n
	local P = { n = n, list = {}, rx = table.create(n, 0), ry = table.create(n, 0), rz = table.create(n, 0) }
	local seen = {}
	local function put(name, x, y, z)
		local i = Kit.bone(rig, name)
		assert(not seen[i], `a posture names the bone {name} twice`)
		seen[i] = true
		P.rx[i], P.ry[i], P.rz[i] = x, y, z
		table.insert(P.list, i)
	end
	for _, row in list do
		if type(row[2]) == "string" then
			local x, y, z = row[3] or 0, row[4] or 0, row[5] or 0
			put(row[1], x, y, z)
			put(row[2], x, -y, -z)
		else
			put(row[1], row[2] or 0, row[3] or 0, row[4] or 0)
		end
	end
	return P
end

-- Takes EVERY bone the share `s` of the way from where the pose has it to the posture (a bone the posture does
-- not name goes to its rest): how a body lies down into its sleeping pose and gets up out of it.
function Boss.lie(pose, P, s)
	if s <= 0 then
		return
	end
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local px, py, pz = P.rx, P.ry, P.rz
	for i = 1, P.n do
		rx[i] += (px[i] - rx[i]) * s
		ry[i] += (py[i] - ry[i]) * s
		rz[i] += (pz[i] - rz[i]) * s
	end
end

-- 3. One chain by keys ------------------------------------------------------------------------------------------
-- A limb is a chain of named bones, body to tip, of the RIGHT side or (`left` true) its mirror image. A key
-- is the turn of each of its bones, first to last, written for the right side: { { rx, ry, rz }, { ... } }.
-- `Boss.key` adds `weight` of a key to the pose (mirrored for a left limb); the weights of the keys a module
-- blends add up to 1. Zero the limb first (`Kit.zero(pose, limb.bones)`).
-- (They are the kit's own now, so that a pet's module has them too: Shared.MotionKit, "One chain by keys".)
Boss.limb, Boss.key = Kit.limb, Kit.key

-- 4. The body on the ground ---------------------------------------------------------------------------------
-- The bones lie inside the flesh: a body laid down by its bones would be half in the ground. So the clearance
-- is measured on the MESH: Shared.BossBodies holds a thinned copy of each boss's skinned mesh (300 points with
-- their bones and weights, tools/body_data.luau), which is posed here as the engine skins it.

-- The thinned mesh of a zone's boss fitted to `rig` (its points are found by the bones' real names, and are
-- the size of this rig). nil when there is none, or the rig has not the bones of the data.
local function bodyOf(rig, zoneId)
	local data = BossBodies[zoneId]
	local label = rig.label
	if not data or not label then
		return nil
	end
	local index = {}
	for i = 1, rig.n do
		index[label[i]] = i
	end
	local map, k = {}, 0
	for name in string.gmatch(data.bones, "%S+") do
		k += 1
		-- (a bone the game's file lacks is no loss as long as no point of the mesh hangs on it: Studio leaves
		-- out a leaf that drives no vertex now and then; a point that does hang on one is refused below)
		map[k] = index[name] or false
	end
	local numbers: { number } = {}
	for value in string.gmatch(data.rest, "%S+") do
		table.insert(numbers, tonumber(value) or 0)
	end
	local scale = rig.height / data.height
	local body = { n = 0, count = {}, bone = {}, weight = {}, dx = {}, dy = {}, dz = {} }
	for line in string.gmatch(data.points, "[^\n]+") do
		local v: { number } = {}
		for value in string.gmatch(line, "%S+") do
			table.insert(v, tonumber(value) or 0)
		end
		if #v >= 4 then
			body.n += 1
			local at = body.n
			local count = v[4]
			body.count[at] = count
			for j = 1, count do
				local b = v[3 + 2 * j]
				local slot = (at - 1) * 4 + j
				local weight = v[4 + 2 * j]
				if not map[b] then
					-- a point that hangs a little on a bone this rig lacks keeps its other bones; one that
					-- hangs mostly on it cannot be placed
					if weight > 0.2 then
						return nil
					end
					b, weight = v[5], 0
					if not map[b] then
						return nil
					end
				end
				body.bone[slot] = map[b]
				body.weight[slot] = weight
				body.dx[slot] = (v[1] - numbers[b * 3 - 2]) * scale
				body.dy[slot] = (v[2] - numbers[b * 3 - 1]) * scale
				body.dz[slot] = (v[3] - numbers[b * 3]) * scale
			end
		end
	end
	return if body.n > 0 then body else nil
end

-- What `settle` works with: the rig, the thinned mesh of the zone's boss (nil for a model that is not the
-- owner's: nothing is corrected then), and the places of every bone (`fk`, MotionKit.forward).
function Boss.ground(rig, zoneId)
	return { rig = rig, body = bodyOf(rig, zoneId), fk = Kit.newFk(rig), all = rig.order, low = 0 }
end

-- Where every bone of the rig stands in the pose (`G.fk`), and the height of the lowest point of the mesh
-- over the ground (studs; `nil` without a mesh).
function Boss.lowest(G, pose)
	Kit.forward(G.rig, pose, G.all, G.fk)
	local body = G.body
	if not body then
		return nil
	end
	local rot, qy = G.fk.m, G.fk.y
	local bone, weight, dx, dy, dz = body.bone, body.weight, body.dx, body.dy, body.dz
	local lowest = math.huge
	for at = 1, body.n do
		local sum, total = 0, 0
		for j = 1, body.count[at] do
			local slot = (at - 1) * 4 + j
			local i = bone[slot]
			local base = (i - 1) * 9
			sum += weight[slot] * (qy[i] + rot[base + 4] * dx[slot] + rot[base + 5] * dy[slot] + rot[base + 6] * dz[slot])
			total += weight[slot]
		end
		if total > 0 and sum / total < lowest then
			lowest = sum / total
		end
	end
	return lowest
end

-- Puts the posed body on the ground: call it LAST, when every turn and the root's offset are in `pose`. A part
-- of the mesh that is under the ground lifts the whole body by as much, always (a foot that tilts, a paw that
-- swings low). `pin` (0 to 1): the share by which a body that hangs OVER the ground is put down on it: 1 asleep
-- (it lies ON the ground, whatever its pose), 0 awake (its legs carry it). `belly`: the share of the height the
-- lowest point of the mesh may lie under the ground (0.012). Afterwards `G.fk` has every bone's place (the
-- root's new rise included) and `G.low` the height the lowest point was found at.
function Boss.settle(G, pose, pin, belly)
	local low = Boss.lowest(G, pose)
	if not low then
		return
	end
	G.low = low
	local need = -(belly or BELLY) * G.rig.height - low
	local lift = if need > 0 then need else need * pin
	if lift ~= 0 then
		pose.bob += lift
		local y = G.fk.y
		for i = 1, G.rig.n do
			y[i] += lift
		end
	end
end

-- 5. A head that is level, and looks ----------------------------------------------------------------------------

-- How a bone is turned in the model, from rest (`fk` forwarded): rx, ry, rz of R = Ry * Rx * Rz.
function Boss.turnOf(fk, i)
	local m = fk.m
	local b = (i - 1) * 9
	return asin(clamp(-m[b + 6], -1, 1)), atan2(m[b + 3], m[b + 9]), atan2(m[b + 4], m[b + 5])
end

-- Sets the turn of bone `i` so that it stands turned (rx, ry, rz) from rest IN THE MODEL, whatever the bones it
-- hangs on do: a head held level while the trunk under it leans, rolls and twists. `fk` must hold the bone's
-- parent (MotionKit.forward on a path that ends there).
function Boss.hold(rig, pose, fk, i, rx, ry, rz)
	local p = rig.parent[i]
	local cx, sx = cos(rx), sin(rx)
	local cy, sy = cos(ry), sin(ry)
	local cz, sz = cos(rz), sin(rz)
	-- (the turn that is wanted, D = Ry * Rx * Rz ...)
	local d11, d12, d13 = cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx
	local d21, d22, d23 = cx * sz, cx * cz, -sx
	local d31, d32, d33 = -sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx
	if p ~= 0 then
		-- (... seen from the parent: its turn, undone)
		local m = fk.m
		local a = (p - 1) * 9
		local p11, p12, p13 = m[a + 1], m[a + 2], m[a + 3]
		local p21, p22, p23 = m[a + 4], m[a + 5], m[a + 6]
		local p31, p32, p33 = m[a + 7], m[a + 8], m[a + 9]
		d11, d12, d13, d21, d22, d23, d31, d32, d33 =
			p11 * d11 + p21 * d21 + p31 * d31,
			p11 * d12 + p21 * d22 + p31 * d32,
			p11 * d13 + p21 * d23 + p31 * d33,
			p12 * d11 + p22 * d21 + p32 * d31,
			p12 * d12 + p22 * d22 + p32 * d32,
			p12 * d13 + p22 * d23 + p32 * d33,
			p13 * d11 + p23 * d21 + p33 * d31,
			p13 * d12 + p23 * d22 + p33 * d32,
			p13 * d13 + p23 * d23 + p33 * d33
	end
	pose.rx[i] = asin(clamp(-d23, -1, 1))
	pose.ry[i] = atan2(d13, d33)
	pose.rz[i] = atan2(d21, d22)
end

-- Where a point of a bone is in the model (`fk` forwarded for that bone): the bone's place and (ox, oy, oz),
-- an offset from it in the bone's own rest frame. The module writes its head's place into `S.headX`, `S.headY`,
-- `S.headZ` with it, for the effects that hang over the head.
function Boss.place(fk, i, ox, oy, oz)
	local m = fk.m
	local b = (i - 1) * 9
	ox, oy, oz = ox or 0, oy or 0, oz or 0
	return fk.x[i] + m[b + 1] * ox + m[b + 2] * oy + m[b + 3] * oz,
		fk.y[i] + m[b + 4] * ox + m[b + 5] * oy + m[b + 6] * oz,
		fk.z[i] + m[b + 7] * ox + m[b + 8] * oy + m[b + 9] * oz
end

-- A wave that is 1 at the moment `at` of a cycle and -1 half a cycle later (`phase` and `at` in cycles): what
-- a body does once a stride (its sway over the foot that stands, the turn of its hips).
function Boss.wave(phase, at)
	return cos(Kit.TAU * (phase - at))
end

-- 6. A body that turns its hips ---------------------------------------------------------------------------------
-- How far (studs, 0 or more) the body must come down for its feet to reach the ground, with the trunk turned
-- as `pose` has it NOW. The kit's own measure (`leg.drop`, `MotionKit.girdle`) takes every hip to be where it
-- stands at rest, which is right for a quadruped whose trunk stays level; a body that turns its hips with the
-- leg that reaches, leans or rolls (a biped, a waddler) asks this one: call it after `MotionKit.gait` and
-- after the trunk's turns and the root's `ox`, `oz` are in the pose, set `pose.bob` no higher than minus
-- what it returns (`Boss.under`), then `MotionKit.solve`. A foot that stands asks what its leg needs from where
-- its hip really is. A foot in the air asks as the kit's does: it lets go of what it asked when it left, and
-- comes down for where it lands (the design's `letGo`, `comeDown`, `comfy`); `ahead` and `lower` are how far
-- (studs) the module's turns of the trunk will have carried a hip forward of its rest place, and under it,
-- when its foot lands (what is left out of them shows as a small corner in the rise as each foot lands).
function Boss.reach(W, pose, ahead, lower)
	local rig, fk, D = W.rig, W.fk, W.design
	local keep = pose.bob
	pose.bob = 0
	Kit.forward(rig, pose, W.trunk, fk)
	pose.bob = keep
	local m = fk.m
	local comfy, letGo, comeDown = D.comfy or 0.995, D.letGo or 0.8, D.comeDown or 0.35
	local stanceT = W.duty / max(W.f, 0.2 / W.tick)
	local sum = 0
	for _, leg in W.legs do
		local long = leg.longD * comfy
		local drop
		if leg.mode == "down" then
			local a = (leg.par - 1) * 9
			local hx = fk.x[leg.par] + m[a + 1] * leg.offX + m[a + 2] * leg.offY + m[a + 3] * leg.offZ
			local hy = fk.y[leg.par] + m[a + 4] * leg.offX + m[a + 5] * leg.offY + m[a + 6] * leg.offZ
			local hz = fk.z[leg.par] + m[a + 7] * leg.offX + m[a + 8] * leg.offY + m[a + 9] * leg.offZ
			-- (the ankle of a foot that stands: from its planted point and the pitch of its sole)
			local cs, ss = cos(leg.sigma), sin(leg.sigma)
			local ay = leg.ty - (leg.u1y * cs - leg.u1z * ss)
			local az = leg.tz - (leg.u1y * ss + leg.u1z * cs)
			if leg.two then
				ay -= leg.u2y * cs - leg.u2z * ss
				az -= leg.u2y * ss + leg.u2z * cs
			end
			local dx, dz = leg.tx - leg.u1x - leg.u2x - hx - leg.xr, az - hz
			drop = max(0, hy - ay - sqrt(max(long * long - dx * dx - dz * dz, 0.01 * long * long)))
			leg.asked = drop
		else
			local reach = stanceT * leg.front * W.speed
				- (leg.restAnkleZ + leg.centre * W.amount - leg.hipZ)
				- (ahead or 0)
			local land = max(
				0,
				leg.hipY - (lower or 0) - leg.restAnkleY - sqrt(max(long * long - reach * reach, 0.01 * long * long))
			)
			drop =
				max((leg.asked or 0) * (1 - smooth(leg.s / letGo)), land * smooth((leg.s - comeDown) / (1 - comeDown)))
		end
		sum += drop * drop * drop * drop
	end
	return sqrt(sqrt(sum))
end

-- The lower of two rises of the body with no corner where one takes over from the other: `rise` is what the
-- design wants (0 or less: studs under its standing height), `need` what its feet ask (`Boss.reach`).
function Boss.under(rise, need)
	local a = max(0, -rise)
	local a2, b2 = a * a, need * need
	return -sqrt(sqrt(a2 * a2 + b2 * b2))
end

-- 7. A run on short legs ----------------------------------------------------------------------------------------

-- From a stand straight into a run: the server sets a boss off at full speed from one frame to the next. The
-- kit measures a speed over a few frames, and walks the first stride of any start with a foot down nearly all
-- of it: at such a speed that drags the foot that stands far behind the body (and then puts it back under the
-- hip in one frame). Call this right after `MotionKit.gait` with the model's velocity THIS frame (`vx`, `vz`:
-- studs a second in the world; the module keeps the place it was told last): a creature that is in its first
-- stride and already as fast as it runs is taken into its run at once, at that speed. With two legs the stride
-- is also turned to where the standing foot is in ITS stance (it stood under the hip, the middle of a stance:
-- it leaves the ground a moment later), and the foot that leads goes on with its swing, or takes its step, so
-- as to land half a stride after that. Returns true the frame it does so.
function Boss.launch(W, vx, vz)
	local trot = W.design.trot
	if not (trot and W.moving and W.since < 0.75) then
		return false
	end
	local speed = sqrt(vx * vx + vz * vz)
	local froude = speed * speed / (Kit.G * W.h)
	-- (a model that was put somewhere else, or a frame of no time, is not a start)
	if froude <= trot.from or froude > 400 then
		return false
	end
	-- the kit is told how fast it goes, and that it runs
	W.vx, W.vz, W.speed, W.veff, W.fr = vx, vz, speed, speed, froude
	W.g, W.trotting, W.since = 1, true, 1
	local legs = W.legs
	local A, B = legs[1], legs[2]
	if #legs == 2 and (B.mode ~= "down" or (A.mode == "down" and A.phi < B.phi)) then
		A, B = B, A
	end
	if #legs ~= 2 or B.mode ~= "down" or (A.mode ~= "down" and A.mode ~= "swing") then
		return true
	end
	-- the run's own duty and stride at this speed (as the kit works them out from the next frame on)
	local duty = trot.duty
	local b = clamp(duty.at - duty.slope * math.log(froude / duty.ref), duty.least, duty.most)
	local length = W.h * trot.stride[1] * froude ^ trot.stride[2]
	local sweep = (trot.sweep or W.design.sweep) * W.h
	if b * length > sweep then
		length = sweep / b
	end
	-- how far behind its home the standing foot has been left, along the way the body goes
	local cy, sy = cos(W.yaw), sin(W.yaw)
	local hx = W.x + B.homeX * cy + B.homeZ * sy
	local hz = W.z - B.homeX * sy + B.homeZ * cy
	local behind = ((hx - B.wx) * vx + (hz - B.wz) * vz) / speed
	local phiB = b * clamp(B.front + behind / (b * length), 0.2, 0.98)
	W.phase = phiB + B.offW + B.offD
	B.phi = phiB
	local phiA = Kit.frac(W.phase - A.offW - A.offD)
	if A.mode == "swing" then
		-- (its swing goes on from where it is, and ends as the stride comes round)
		A.phase0 = (phiA - A.s) / max(1 - A.s, 0.05)
	else
		-- (it has not lifted yet: it takes its step now, and lands as the stride comes round)
		Kit.step(W, A, (1 - phiA) * length / speed / W.tick)
		A.liftNow = A.liftTrot * W.h
		-- (this frame's target was its planted point: from now on it is its ankle, where it leaves the ground)
		local dx, dz = A.lx - W.x, A.lz - W.z
		A.tx, A.ty, A.tz = dx * cy - dz * sy, A.ly, dx * sy + dz * cy
	end
	A.phi = phiA
	return true
end

-- A RUN THAT SURGES. At a run of ten leg lengths a second and more, a foot is on the ground for four or five
-- frames of a sixtieth and the body passes over it so fast that the leg turns half a radian a frame, and it
-- must fold and open again as fast as the body comes over it. So the body is carried a little slower while
-- a foot stands and a little quicker in the flight between two (what a runner's body does, made a little
-- more of): `oz`, studs behind where the kit's walker is (the root's `pose.oz`), once for every stance;
-- `share` of the stride sets how much (0.045: the body goes about a third slower while a foot stands). The
-- second number is `oz` as a foot lands, for `Boss.reach` and `Boss.swing`. Both are 0 when it walks.
function Boss.surge(W, share)
	local size = share * W.stride * W.amount * Kit.smooth(W.g)
	local function at(theta)
		-- (a second harmonic flattens the slow part over the whole stance)
		return size * (sin(theta) - 0.25 * sin(2 * theta))
	end
	return at(Kit.TAU * (2 * W.phase - W.duty)), at(-Kit.TAU * W.duty)
end

-- A FOOT IN THE AIR GOES FORWARD WITH THE BODY. The kit carries a foot from where it left the ground to where
-- it lands along the ground, eased in time: at a run the body goes on at once while the foot is still where
-- it left, the leg is left stretched behind and must then whip forward through far more angle. Call this
-- after `MotionKit.gait` and before `MotionKit.solve`, with what `Boss.surge` gave: the way the walker has
-- gone since the foot left, and what the surge has moved the body, are taken off the part of the swing that
-- is still to come, `share` of it (0 the kit's swing, 1 a swing eased as the BODY sees it). `memory`: a table
-- of the module's own, one a leg. The foot lands exactly where the kit puts it.
function Boss.swing(W, memory, oz, landOz, share, dt)
	for k, leg in W.legs do
		local m = memory[k]
		if leg.mode == "swing" then
			if not m.on then
				m.on, m.way, m.oz = true, 0, oz
			else
				m.way += W.speed * dt
			end
			local e = Kit.ease(leg.s ^ 0.9)
			local still = (1 - leg.phi) * W.stride
			leg.tz += share * ((still - landOz + oz) * e - (m.way + m.oz - oz) * (1 - e))
		else
			m.on = false
		end
	end
end

-- A leg in the air that does not snap. The kit carries a foot through the air along a line and folds the leg
-- to wherever it is: where a short leg swings past its hip at a run, its knee would shut and open again in
-- two frames each. Call this for a leg after `MotionKit.solve`: while its foot is in the air its folding
-- joints (the 2nd down to the one above the ankle) FOLLOW what the solver asks, at `rate` (1/s), and are
-- exactly what it asks again as the foot comes down to land (over the last quarter of its swing); the ankle
-- is turned back by what they are behind, so that the sole keeps the pitch it is held at. A foot on the ground
-- is left as it was solved. `memory`: a table of the module's own, one a leg.
function Boss.soften(leg, pose, memory, dt, rate)
	local rx = pose.rx
	local b = leg.b
	if leg.mode == "down" then
		for j = 2, leg.k do
			memory[j] = rx[b[j]]
		end
		return
	end
	local exact = smooth((leg.s - 0.75) / 0.25)
	local share = 1 - math.exp(-rate * dt)
	local behind = 0
	for j = 2, leg.k do
		local i = b[j]
		local want = rx[i]
		local had = memory[j] or want
		had += (want - had) * share
		memory[j] = had
		local got = had + (want - had) * exact
		rx[i] = got
		behind += want - got
	end
	rx[b[leg.ankle]] += behind
end

return Boss
