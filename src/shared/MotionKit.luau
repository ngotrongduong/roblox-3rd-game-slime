-- The kit every creature's own motion is built from (Shared.Creatures.<name>, one module an animal; see
-- Shared.Creature for how one is found and played, and docs/MOTION.md, Part 2, for how one is written).
-- Pure numbers: no Roblox, so the tests and the tools run it. Nothing here knows an animal: a module hands
-- over its JOINT MAP (which bone is which joint) and its own numbers, and gets back
--
--   1. `rig(bones, map)`      the skeleton with every mapped bone found, or nil and why the map does not fit
--                             (`problems` lists everything: the tests call it for every map)
--   2. `forward`              where some bones stand in a pose (the trunk, before the legs are solved)
--   3. `leg`, `walker`, `gait`, `sag`, `girdle`, `solve`
--                             LEGS THAT WORK LIKE LEGS: a clock that turns speed into strides (Froude, the
--                             animal's own leg length), feet that are PLANTED IN THE WORLD while they stand
--                             and swing along an arc when they do not, a body that is carried by the legs
--                             that stand, and a solver that folds every joint in its own direction so that
--                             the foot is where it was planted; a pivot that goes on slower than a
--                             walk (the client's slow turn) is walked with in small steps
--      `straighten`          a foot longer than its leg kept as the solver meant it
--      `sprawl`, `reachOut`   the solver of a leg that sticks out to the SIDE (a crab's, a beetle's; with
--                             `tiptoe` one that stands on its point)
--      `both`, `ride`        the designed sink beside the legs' yield; `lead`, `leadFeet` start a square stand
--      `toes`                 a joint in the ball of a paw held flat as its heel rolls up
--   4. `gaze`, `spread`       a head that is still and now and then looks somewhere
--      `asideHold`, `cock`, `holdLook`   short holds aside, a cocked head, separate holds ahead and aside
--   5. `chainWave`, `pulse`   a tail that follows with lag and overlap
--      `springRow`, `chainFollow`, `chainTrail`, `chainSpring`   rows of springs and trailing values
--      `hoverSwell`, `drift`  a floater's swell and its travel into go and push
--      `newBeat`, `beat`      rounds of wingbeats and glides
--      `limb`, `key`          one chain posed by keys that are blended (a wing folded or spread, a leg tucked)
--      `sense`, `pieces`, `layout`, `swell`, `wave`, `lay`   a body that lies on the ground, laid out behind its front and waved
--                             by the way it has gone (a snake, a wyrm)
--   6. `spring`, `curve`, `bound`, `dice`, `roll`, `smooth`, `ease` ...   the small things
--
-- Space: the model's own, the pivot on the ground under the middle of the creature, +y up, it looks along
-- -z, +x is its right. A pose is the one of Shared.RigMotion (`rx`, `ry`, `rz` a bone: the turn R = Ry * Rx *
-- Rz about the model's axes at the bone's rest joint, adding up down the tree; `bob`, `ox`, `oz` move the
-- root), so PetAnimator, RigMotion.forward and the tools take it as it is. Signs: a positive `rx` tips the top
-- BACK (a trunk's nose goes up, a hanging leg swings forward, a hoof's toe lifts); a positive `ry` turns to its
-- left; a positive `rz` lifts its right side.
--
-- Cost (Lune, one core): a four-legged pose with trunk, legs, neck and tail is about 6 microseconds, a model
-- of one part under 1; nothing is allocated after `walker` and `leg` have made their tables.
local Kit = {}

local sin, cos, abs, sqrt, floor, min, max, atan2, pi, log, exp =
	math.sin, math.cos, math.abs, math.sqrt, math.floor, math.min, math.max, math.atan2, math.pi, math.log, math.exp
local asin, acos = math.asin, math.acos
local TAU = pi * 2

Kit.G = 35 -- studs/s^2: real gravity at Roblox's scale (docs/MOTION.md, section 2), NOT Workspace.Gravity
Kit.TAU = TAU

-- Small things ----------------------------------------------------------------------------------------------

local function clamp(x, lo, hi)
	return if x < lo then lo elseif x > hi then hi else x
end

-- 0 to 1, eased at both ends (no corner at either).
local function smooth(x)
	if x <= 0 then
		return 0
	elseif x >= 1 then
		return 1
	end
	return x * x * (3 - 2 * x)
end

-- The same with no acceleration at the ends either: a move that starts and stops softly, never overshoots.
local function ease(x)
	if x <= 0 then
		return 0
	elseif x >= 1 then
		return 1
	end
	return x * x * x * (x * (x * 6 - 15) + 10)
end

local function wrap(a)
	return (a + pi) % TAU - pi
end

local function frac(x)
	return x - floor(x)
end

Kit.clamp, Kit.smooth, Kit.ease, Kit.wrap, Kit.frac = clamp, smooth, ease, wrap, frac

-- A number that follows another without a jump: the share of the way it goes in `dt` at `rate` a second.
function Kit.follow(rate, dt)
	return 1 - exp(-rate * dt)
end

-- A curve through keys `{ x1, y1, x2, y2, ... }` (x rising), eased between them and flat at every key: what a
-- joint does over a stance or a swing, written as the few values of a table of docs/MOTION.md.
function Kit.curve(keys, x)
	if x <= keys[1] then
		return keys[2]
	end
	for i = 3, #keys, 2 do
		if x <= keys[i] then
			local x0, y0 = keys[i - 2], keys[i - 1]
			local u = (x - x0) / (keys[i] - x0)
			return y0 + (keys[i + 1] - y0) * (u * u * (3 - 2 * u))
		end
	end
	return keys[#keys]
end

-- A creature's own dice (never math.random: two clients, the tools and the tests throw the same).
function Kit.dice(seed)
	return { s = floor((seed % 1) * 2147483000) % 2147483646 + 1 }
end

function Kit.roll(dice)
	local s = (dice.s * 16807) % 2147483647
	dice.s = s
	return s / 2147483647
end

-- A time drawn with a long tail: mostly near `least`, now and then much longer (never over `most`).
function Kit.wait(dice, least, mean, most)
	local u = max(Kit.roll(dice), 1e-6)
	return min(most, least - (mean - least) * log(u))
end

-- A spring `{ x, v }` that follows `target`: `rate` rad/s, `damping` 1 = no overshoot, under 1 it swings past.
function Kit.spring(s, target, rate, damping, dt)
	local left = min(dt, 0.25)
	while left > 0 do
		local step = min(left, 1 / 45)
		left -= step
		s.v += (rate * rate * (target - s.x) - 2 * damping * rate * s.v) * step
		s.x += s.v * step
	end
	return s.x
end

-- One short event: 0 before `t0`, up and down again over `length` seconds (eased both ways), 0 after.
function Kit.pulse(t, t0, length)
	local u = (t - t0) / length
	if u <= 0 or u >= 1 then
		return 0
	end
	local s = sin(pi * u)
	return s * s
end

-- A row of springs for a chain, made once with the creature.
function Kit.springRow(count)
	local row = {}
	for k = 1, count do
		row[k] = { x = 0, v = 0 }
	end
	return row
end

-- The bigger of two, without a corner where one takes over from the other.
function Kit.both(a, b)
	local a2, b2 = a * a, b * b
	return sqrt(sqrt(a2 * a2 + b2 * b2))
end

-- How far an end rides down: a walk's landing, a trot's middle of stance, and its own crouch.
function Kit.ride(W, g, phi, walkBob, trotBob, crouch)
	local walk = walkBob * (0.5 + 0.5 * cos(2 * TAU * phi))
	local trot = trotBob * (0.5 + 0.5 * cos(2 * TAU * (phi - 0.5 * W.duty)))
	return W.amount * W.h * (crouch + walk + (trot - walk) * g)
end

-- Which hind paw leads from a square stand (legs ordered left fore, right fore, left hind, right hind).
function Kit.lead(seed)
	return if seed % 1 < 0.5 then { 2, 1, 4, 3 } else { 1, 2, 3, 4 }
end

-- Put the planted feet a hair behind home, the leading paw furthest. Call just after a fresh gait.
function Kit.leadFeet(W, lead, yaw)
	local sy, cy = sin(yaw), cos(yaw)
	for k, leg in W.legs do
		local back = lead[k] * 1e-5 * W.h
		leg.wx += back * sy
		leg.wz += back * cy
	end
end

-- A look aside is held for its own short time, whatever long hold preceded it.
function Kit.asideHold(gaze, t, dice, turn, aside)
	if gaze.t0 == t and (gaze.y1 ~= 0 or gaze.p1 ~= 0) then
		gaze.next = t + turn + Kit.wait(dice, aside[1], aside[2], aside[3])
	end
end

-- Cock the head now and then with its look. The creature keeps tilt, tiltFrom, tiltTo and tiltAt.
function Kit.cock(S, t, moving, turn, tilt, chance)
	local gaze = S.gaze
	if gaze.t0 ~= S.tiltAt then
		S.tiltAt, S.tiltFrom = gaze.t0, S.tilt
		local aside = not moving and (gaze.y1 ~= 0 or gaze.p1 ~= 0)
		S.tiltTo = if aside and Kit.roll(S.dice) < chance then tilt * (if Kit.roll(S.dice) < 0.5 then -1 else 1) else 0
	end
	S.tilt = S.tiltFrom + (S.tiltTo - S.tiltFrom) * ease((t - S.tiltAt) / turn)
	return S.tilt
end

-- A paw with a joint in its ball: toes flat as the heel rolls up, letting go early in the swing.
function Kit.toes(pose, leg, hang, release, low, high)
	local flat = -(leg.sigma + leg.tau)
	if leg.mode ~= "down" then
		flat *= 1 - hang * smooth(leg.s / release)
	end
	local i = leg.b[leg.n]
	pose.rx[i], pose.ry[i], pose.rz[i] = clamp(flat, low, high), 0, 0
end

-- Each joint follows the preceding spring, with lag, turn slip and a limit on its own bend.
function Kit.chainFollow(pose, chain, row, lead, before, rate, damping, most, slip, dt, reset)
	for k, i in chain do
		local s = row[k]
		if reset or dt <= 0 then
			s.x, s.v = lead, 0
		end
		s.x = clamp(s.x - slip, lead - most, lead + most)
		local at = Kit.spring(s, lead, rate, damping, dt)
		local own = clamp(at - before, -most, most)
		pose.rx[i], pose.ry[i], pose.rz[i] = 0, own, 0
		before += own
		lead = before
	end
end

-- One swell: up in a third of the cycle, down in two thirds, soft at both ends (-1 to 1).
function Kit.hoverSwell(u)
	u = frac(u)
	if u < 1 / 3 then
		return -cos(pi * u * 3)
	end
	return cos(pi * (u - 1 / 3) * 1.5)
end

-- A chain of values, each following the preceding one a little later.
function Kit.chainTrail(list, target, rates, tick, dt)
	for k = 1, #list do
		list[k] += (target - list[k]) * (1 - exp(-dt * rates[k] / tick))
		target = list[k]
	end
end

-- Ahead and aside each draw their hold from their own numbers (S.gaze, S.look, S.dice).
function Kit.holdLook(S, t)
	local gaze, look = S.gaze, S.look
	if gaze.t0 == t then
		local held
		if gaze.y1 ~= 0 or gaze.p1 ~= 0 then
			held = Kit.wait(S.dice, look.asideLeast, look.aside, look.asideMost)
		else
			held = Kit.wait(S.dice, look.least, look.mean, look.most)
		end
		gaze.next = t + look.turn + held
	end
end

-- Unchanged up to the knee, then eased towards a limit it never reaches, with no corner.
function Kit.bound(value, knee, most)
	local over = abs(value) - knee
	if over <= 0 then
		return value
	end
	local room = most - knee
	local kept = knee + room * (1 - exp(-over / room))
	return if value < 0 then -kept else kept
end

-- Pivot travel into a floater's go and push. Returns the safe dt, go, travel, pace share and push.
-- With press, a start advances phase to the next paddle; a smoke chain leaves its clock alone.
function Kit.drift(S, dt, input, tick, goStart, goStop, press)
	local x, z, yaw = input.x, input.z, input.yaw
	if S.fresh or input.jump or dt <= 0 or dt > 0.4 then
		S.fresh = false
		S.vx, S.vz, S.w = 0, 0, 0
		S.speed, S.push = 0, 0
		dt = 0
	else
		local k = 1 - exp(-10 * dt)
		S.vx += ((x - S.x) / dt - S.vx) * k
		S.vz += ((z - S.z) / dt - S.vz) * k
		S.w += (wrap(yaw - S.yaw) / dt - S.w) * k
	end
	S.x, S.z, S.yaw = x, z, yaw
	local speed = sqrt(S.vx * S.vx + S.vz * S.vz)
	local share = speed / S.pace
	if S.going then
		S.going = share > goStop
	else
		S.going = share > goStart
	end
	-- (how much it travels, 0 hovering to 1 at its pace and a little over: everything of the travel goes with it)
	local want = if S.going then clamp(share, 0, 1.4) else 0
	if press and want > 0 and S.go <= 0 then
		S.phase = floor(S.phase) + 1 -- (it sets off with a press)
	end
	S.go += (want - S.go) * (1 - exp(-dt * 1.6 / tick))
	if want == 0 and S.go < 0.002 then
		S.go = 0
	end
	local go = S.go
	local travel = smooth(go)
	-- (how fast it gains or loses speed, in paces a tick: what tips it and slings its limbs)
	if dt > 0 then
		local gain = (speed - S.speed) / dt * tick / S.pace
		S.push += (clamp(gain, -0.6, 0.6) - S.push) * (1 - exp(-dt * 2.5 / tick))
	end
	S.speed = speed
	local push = S.push * smooth(4 * (go + share))
	return dt, go, travel, share, push
end

-- A row of springs down a chain: the next follows what the previous one reached in this frame.
function Kit.chainSpring(row, target, rates, damping, tick, dt)
	for k, s in row do
		target = Kit.spring(s, target, rates[k] / tick, damping[k], dt)
	end
end

-- Start a round-of-beats clock on the creature (phase, beat, flaps, beating); dice, tick and pace are its own.
function Kit.newBeat(S, seed, spec)
	S.phase = 0
	S.beat = seed * spec.cycle
	S.flaps = spec.flaps[1]
	S.beating = { x = 1, v = 0 }
end

-- A few beats, then a glide; hovering, climbing and getting up must beat. Returns beating and the wave.
function Kit.beat(S, dt, go, aloft, climb, spec)
	local tick = S.tick
	local before = S.beat
	S.beat += dt * spec.flap / tick * (1 + spec.quick * (1 - go))
	S.phase = S.beat / spec.cycle
	if floor(S.beat / spec.cycle) ~= floor(before / spec.cycle) then
		S.flaps = spec.flaps[1] + floor(Kit.roll(S.dice) * (spec.flaps[2] - spec.flaps[1] + 1))
	end
	local must = go < 0.7 or aloft < 0.97 or climb > spec.climb * S.pace
	local beating = clamp(
		Kit.spring(S.beating, if must or S.beat % spec.cycle < S.flaps then 1 else 0, spec.on / tick, 1, dt),
		0,
		1
	)
	return beating, TAU * S.beat
end

-- The joint map ---------------------------------------------------------------------------------------------
-- A map says what every bone of ONE model is (`Shared.Creatures.<name>.map`):
--   prefix   put before every name below ("Bone_": the map then says "022")
--   count, tree   how many bones the skeleton has and the print of its tree (`treeHash`): a model the owner
--            has replaced does not pass, whatever its bones are called
--   root     the root bone
--   spine    the bones of the trunk, in any order (each hangs on the root or on another of them)
--   neck, head, tail   chains, base first (each bone is the child of the one before it)
--   legs     { LF = { ... }, ... }: chains from the body down to the tip
--   limbs    { name = { role = "arm", bones = { ... } } }: other chains (arms, wings, tentacles)
--   pairs    { { "LF", "RF" }, ... }: legs or limbs that mirror each other; a third entry "pair" checks
--            about the first joints' midpoint instead of the root (the same line down the whole pair)
--   rigid    bones that never turn by themselves; everything below one that is not named elsewhere is
--            rigid with it (ears, horns, a mane, the face)
-- Every bone of the skeleton must be in the map, moved or rigid.

local MIRROR = 0.04 -- share of the height two mirrored joints may differ by

-- The print of a skeleton's tree: every bone with its parent, whatever order they are listed in.
-- `skip` (a set of labels) leaves bones out: the print of the skeleton as it is without them.
function Kit.treeHash(bones, skip)
	local labelOf = {}
	for _, bone in bones do
		labelOf[bone.name] = bone.label or bone.name
	end
	local lines = {}
	for _, bone in bones do
		local own = bone.label or bone.name
		if not (skip and skip[own]) then
			table.insert(lines, own .. "<" .. (if bone.parent then labelOf[bone.parent] or "?" else ""))
		end
	end
	table.sort(lines)
	local h = 7
	for _, line in lines do
		for k = 1, #line do
			h = (h * 31 + string.byte(line, k)) % 2147483647
		end
		h = (h * 31 + 10) % 2147483647
	end
	return h
end

-- Reads a list of bones `{ name, label (its real name, when `name` is only a number), parent (a `name`), x,
-- y, z }` against a map. Returns what a rig is made of, and the list of what is wrong.
local function read(bones, map)
	local n = #bones
	local problems = {}
	local function wrong(text)
		table.insert(problems, text)
	end
	local byName, at, label = {}, {}, table.create(n)
	for i, bone in bones do
		byName[bone.name] = i
		label[i] = bone.label or bone.name
		at[label[i]] = i
	end
	local parent, children = table.create(n, 0), table.create(n)
	for i = 1, n do
		children[i] = {}
	end
	local roots = {}
	for i, bone in bones do
		local p = if bone.parent then byName[bone.parent] else nil
		if p and p ~= i then
			parent[i] = p
			table.insert(children[p], i)
		else
			table.insert(roots, i)
		end
	end
	local order, head = table.clone(roots), 1
	while head <= #order do
		for _, child in children[order[head]] do
			table.insert(order, child)
		end
		head += 1
	end
	if #order ~= n then
		wrong("the bones do not hang on a root")
	end
	local prefix = map.prefix or ""
	-- `map.lost`: bones Studio is known to leave out when it imports this model (a leaf that drives no vertex).
	-- The game's file then has fewer bones than the .glb the map was written from: the skeleton is accepted with
	-- or without them, and `map.treeLost` is the print of its tree without them.
	local lost, lostGone = {}, 0
	for _, name in map.lost or {} do
		lost[prefix .. name] = true
		if not at[prefix .. name] then
			lostGone += 1
		end
	end
	if map.count and map.count - lostGone ~= n then
		wrong(`the map was written for {map.count} bones, the skeleton has {n}`)
	end
	if map.tree and #problems == 0 then
		local tree = Kit.treeHash(bones)
		local want = if lostGone > 0 then map.treeLost else map.tree
		if tree ~= want then
			wrong(`the tree of the skeleton is not the one the map was written for (print {tree}, the map says {want})`)
		end
	end
	local used, role = {}, table.create(n, "rigid")
	local function find(name, group)
		local i = at[prefix .. name]
		if not i then
			if not lost[prefix .. name] then
				wrong(`{group}: there is no bone {prefix}{name}`)
			end
			return nil
		end
		if used[i] then
			wrong(`{prefix}{name} is in {used[i]} and in {group}`)
			return nil
		end
		used[i] = group
		return i
	end
	local chains = {} -- [group] = the indices of a chain
	local function chain(group, names, what)
		local list = {}
		for k, name in names do
			local i = find(name, group)
			if not i then
				return
			end
			if k > 1 and parent[i] ~= list[k - 1] then
				wrong(`{group}: {prefix}{name} does not hang on {prefix}{names[k - 1]}`)
			end
			role[i] = what
			list[k] = i
		end
		chains[group] = list
	end
	local rootIndex = find(map.root, "the root")
	if rootIndex then
		role[rootIndex] = "spine"
		if parent[rootIndex] ~= 0 then
			wrong(`the root {prefix}{map.root} hangs on another bone`)
		end
	end
	local spine = {}
	for _, name in map.spine or {} do
		local i = if prefix .. name == prefix .. map.root then rootIndex else find(name, "the spine")
		if i then
			role[i] = "spine"
			spine[i] = true
		end
	end
	if rootIndex then
		spine[rootIndex] = true
	end
	for i in spine do
		if i ~= rootIndex and not spine[parent[i]] then
			wrong(`the spine: {label[i]} hangs on no other bone of the spine`)
		end
	end
	if map.neck then
		chain("the neck", map.neck, "neck")
	end
	if map.head then
		chain("the head", map.head, "head")
	end
	if map.tail then
		chain("the tail", map.tail, "tail")
	end
	local ids = {}
	for id in map.legs or {} do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		chain(id, map.legs[id], "leg")
	end
	ids = {}
	for id in map.limbs or {} do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		chain(id, map.limbs[id].bones, map.limbs[id].role or "arm")
	end
	-- what is rigid, and whether every bone is accounted for
	local rigid = {}
	local function freeze(i)
		rigid[i] = true
		for _, child in children[i] do
			if not used[child] then
				freeze(child)
			end
		end
	end
	for _, name in map.rigid or {} do
		local i = find(name, "the rigid bones")
		if i then
			freeze(i)
		end
	end
	local loose = {}
	for i = 1, n do
		if not used[i] and not rigid[i] then
			table.insert(loose, label[i])
		end
	end
	if #loose > 0 then
		table.sort(loose)
		wrong(`{#loose} bones are neither moved nor declared rigid: {table.concat(loose, ", ", 1, min(#loose, 12))}`)
	end
	-- the size, the middle line, and the pairs that mirror each other
	local low, high = 0, -math.huge
	for _, bone in bones do
		low, high = min(low, bone.y), max(high, bone.y)
	end
	local height = max(high - low, 1e-3)
	local middle = if rootIndex then bones[rootIndex].x else 0
	for _, pair in map.pairs or {} do
		local a, b = chains[pair[1]], chains[pair[2]]
		if not a or not b then
			wrong(`the pair {pair[1]} / {pair[2]}: one of them is not a chain of the map`)
		elseif #a ~= #b then
			wrong(`the pair {pair[1]} / {pair[2]}: {#a} bones against {#b}`)
		else
			local line = if pair[3] == "pair" and #a > 0 then (bones[a[1]].x + bones[b[1]].x) / 2 else middle
			for k = 1, #a do
				local p, q = bones[a[k]], bones[b[k]]
				local off = max(abs(p.x + q.x - 2 * line), abs(p.y - q.y), abs(p.z - q.z)) / height
				if off > MIRROR or (p.x - line) * (q.x - line) > 0 then
					wrong(
						`the pair {pair[1]} / {pair[2]}: {label[a[k]]} and {label[b[k]]} do not mirror each other ({string.format(
							"%.3f",
							off
						)} of the height)`
					)
				end
			end
		end
	end
	-- a leg ends on the ground and starts well over it
	for id in map.legs or {} do
		local list = chains[id]
		if list then
			local top, tip = bones[list[1]], bones[list[#list]]
			if (tip.y - low) > 0.12 * height or (top.y - low) < 0.2 * height then
				wrong(`{id}: it does not run from the body down to the ground`)
			end
		end
	end
	return {
		n = n,
		at = at,
		label = label,
		parent = parent,
		children = children,
		order = order,
		root = rootIndex,
		role = role,
		chains = chains,
		height = height,
		middle = middle,
		prefix = prefix,
	},
		problems
end

-- Everything that is wrong with a map for these bones (an empty list: it fits).
function Kit.problems(bones, map)
	local _, problems = read(bones, map)
	return problems
end

-- The rig of a skeleton by its map: what RigMotion.forward and PetAnimator need (`n`, `px`, `py`, `pz`,
-- `parent`, `order`, `root`, `height`, `label`, `role`) and `at` (a bone's place in the list by the name the
-- map gives it) and `chains` (the legs, the neck ... as lists of places). nil and a sentence when the map
-- does not fit: the caller then moves the model by the generic reader, never wrongly by a map.
function Kit.rig(bones, map)
	local info, problems = read(bones, map)
	if #problems > 0 then
		return nil, problems[1]
	end
	local n = info.n
	local px, py, pz = table.create(n, 0), table.create(n, 0), table.create(n, 0)
	for i, bone in bones do
		px[i], py[i], pz[i] = bone.x, bone.y, bone.z
	end
	local at, prefix = {}, info.prefix
	for name, i in info.at do
		at[name] = i
		if prefix ~= "" and string.sub(name, 1, #prefix) == prefix then
			at[string.sub(name, #prefix + 1)] = i
		end
	end
	return {
		n = n,
		px = px,
		py = py,
		pz = pz,
		parent = info.parent,
		order = info.order,
		root = info.root,
		height = info.height,
		middle = info.middle,
		label = info.label,
		role = info.role,
		at = at,
		chains = info.chains,
		mapped = true,
	}
end

-- The rig of a model of ONE part with no bones (a store model): place 1 is the pivot, place 2 the part,
-- which turns about `pivot` (x, y, z in the model's space). `sx`, `sy`, `sz`: the size of its box.
function Kit.single(sx, sy, sz, pivotX, pivotY, pivotZ)
	return {
		n = 2,
		single = true,
		px = { 0, pivotX },
		py = { 0, pivotY },
		pz = { 0, pivotZ },
		parent = { 0, 1 },
		order = { 1, 2 },
		root = 1,
		height = sy,
		width = sx,
		length = sz,
		middle = 0,
		label = { "Root", "Body" },
		role = { "spine", "spine" },
		at = { Root = 1, Body = 2 },
		chains = {},
	}
end

function Kit.newPose(rig)
	local n = rig.n
	return { rx = table.create(n, 0), ry = table.create(n, 0), rz = table.create(n, 0), bob = 0, ox = 0, oz = 0 }
end

-- The places of a chain of the map, and of one bone.
function Kit.chain(rig, group)
	return rig.chains[group] or error(`the map has no chain called {group}`)
end

function Kit.bone(rig, name)
	return rig.at[name] or error(`the skeleton has no bone called {name}`)
end

-- Where bones stand in a pose ----------------------------------------------------------------------------------

-- The bones from the root down to each of `ends` (places), parents first: what `forward` has to work out
-- before those bones' own children can be solved.
function Kit.path(rig, ends)
	local wanted = {}
	for _, i in ends do
		local node = i
		while node ~= 0 and not wanted[node] do
			wanted[node] = true
			node = rig.parent[node]
		end
	end
	local list = {}
	for _, i in rig.order do
		if wanted[i] then
			table.insert(list, i)
		end
	end
	return list
end

function Kit.newFk(rig)
	local n = rig.n
	return { x = table.create(n, 0), y = table.create(n, 0), z = table.create(n, 0), m = table.create(n * 9, 0) }
end

-- Where the bones of `list` (parents first, every parent in it) stand in `pose`, and how each is turned
-- (`fk.m`, nine numbers a bone, rows first): the sums of RigMotion.forward, for a few bones only.
function Kit.forward(rig, pose, list, fk)
	local px, py, pz, parent = rig.px, rig.py, rig.pz, rig.parent
	local ox, oy, oz, rot = fk.x, fk.y, fk.z, fk.m
	local prx, pry, prz = pose.rx, pose.ry, pose.rz
	for _, i in list do
		local cx, sx = cos(prx[i]), sin(prx[i])
		local cy, sy = cos(pry[i]), sin(pry[i])
		local cz, sz = cos(prz[i]), sin(prz[i])
		local m11, m12, m13 = cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx
		local m21, m22, m23 = cx * sz, cx * cz, -sx
		local m31, m32, m33 = -sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx
		local b = (i - 1) * 9
		local p = parent[i]
		if p == 0 then
			ox[i], oy[i], oz[i] = px[i] + pose.ox, py[i] + pose.bob, pz[i] + pose.oz
			rot[b + 1], rot[b + 2], rot[b + 3] = m11, m12, m13
			rot[b + 4], rot[b + 5], rot[b + 6] = m21, m22, m23
			rot[b + 7], rot[b + 8], rot[b + 9] = m31, m32, m33
		else
			local a = (p - 1) * 9
			local r11, r12, r13 = rot[a + 1], rot[a + 2], rot[a + 3]
			local r21, r22, r23 = rot[a + 4], rot[a + 5], rot[a + 6]
			local r31, r32, r33 = rot[a + 7], rot[a + 8], rot[a + 9]
			local dx, dy, dz = px[i] - px[p], py[i] - py[p], pz[i] - pz[p]
			ox[i] = ox[p] + r11 * dx + r12 * dy + r13 * dz
			oy[i] = oy[p] + r21 * dx + r22 * dy + r23 * dz
			oz[i] = oz[p] + r31 * dx + r32 * dy + r33 * dz
			rot[b + 1], rot[b + 2], rot[b + 3] =
				r11 * m11 + r12 * m21 + r13 * m31, r11 * m12 + r12 * m22 + r13 * m32, r11 * m13 + r12 * m23 + r13 * m33
			rot[b + 4], rot[b + 5], rot[b + 6] =
				r21 * m11 + r22 * m21 + r23 * m31, r21 * m12 + r22 * m22 + r23 * m32, r21 * m13 + r22 * m23 + r23 * m33
			rot[b + 7], rot[b + 8], rot[b + 9] =
				r31 * m11 + r32 * m21 + r33 * m31, r31 * m12 + r32 * m22 + r33 * m32, r31 * m13 + r32 * m23 + r33 * m33
		end
	end
end

-- Legs ----------------------------------------------------------------------------------------------------
-- A leg is a chain of the map seen from the side (every joint turns about the model's x; the top joint
-- may also lean a little to the side to reach a foot that is not under it). From the body down:
--   the UPPER joints, 1 to `ankle - 1`: the first one only aims the leg; the others FOLD together in the
--     proportions of the animal's design (`fold.swing`, `fold.stance`: radians each turns for one radian of
--     fold `q`, signed the way that joint really folds; `fold.skew` moves a joint's share to the start of
--     the swing (over 0) or to its end (under 0), so that the joints of one leg do not peak together), plus
--     what a table says they do by themselves (`extra`)
--   the ANKLE (the fetlock of a hoof, the wrist of a paw): from here down the foot is not solved but HELD:
--     the `sole` bone (the one that carries the hoof or the paw; the ankle itself when the foot is one bone)
--     keeps the pitch it is told against the GROUND (flat while it stands, on its toe before it leaves,
--     flipped back while it swings), whatever the trunk and the leg above do
--   the CONTACT (the tip of the chain, or the bone `contact` names): the point that stays where it was
--     planted
-- While a foot stands, a body that comes down on it is taken up first by the SINK of the pastern (the piece
-- between the ankle and the sole; a foot of one bone tilts instead), up to `sink` radians, and only then by
-- folding the leg: that is what a real fetlock does, and a straight leg cannot fold a little without it
-- showing.

local FOLD_STEP = 0.05 -- radians of fold between two looks for how far a leg can fold
local FOLD_DEEP = 0.74 -- a leg folds to this share of its length at most
local FOLD_FINE = 0.002 -- radians: how well a fold is found
local SINK_FINE = 0.004

-- The end of the upper chain (the ankle) from the top joint for a fold `q`, before the leg is aimed: y, z,
-- and the sum of the joints' turns.
local function reach(leg, q)
	local sy, sz, c, e = leg.sy, leg.sz, leg.c, leg.e
	local y, z = sy[1], sz[1]
	local a = 0
	for j = 2, leg.k do
		a += c[j] * q + e[j]
		local ca, sa = cos(a), sin(a)
		local py, pz = sy[j], sz[j]
		y += py * ca - pz * sa
		z += py * sa + pz * ca
	end
	return y, z, a
end

-- The fold at which the ankle is `d2` (squared) from the top joint, between `lo` (the leg at its longest)
-- and `hi`; the leg gets shorter as it folds.
local function foldFor(leg, d2, lo, hi, near)
	local y, z = reach(leg, lo)
	local flo = y * y + z * z - d2
	if flo <= 0 then
		return lo, sqrt(d2) - sqrt(y * y + z * z) -- (it cannot be that long: the foot is out of reach by this much)
	end
	-- (where it was found last is nearly it)
	if near - 0.12 > lo then
		y, z = reach(leg, near - 0.12)
		local f = y * y + z * z - d2
		if f > 0 then
			lo, flo = near - 0.12, f
		end
	end
	local fhi
	if near + 0.12 < hi then
		y, z = reach(leg, near + 0.12)
		fhi = y * y + z * z - d2
		if fhi < 0 then
			hi = near + 0.12
		else
			fhi = nil
		end
	end
	if not fhi then
		y, z = reach(leg, hi)
		fhi = y * y + z * z - d2
		if fhi >= 0 then
			return hi, 0
		end
	end
	while hi - lo > FOLD_FINE do
		local mid = (lo + hi) / 2
		y, z = reach(leg, mid)
		local f = y * y + z * z - d2
		if f > 0 then
			lo, flo = mid, f
		else
			hi, fhi = mid, f
		end
	end
	return lo + (hi - lo) * flo / (flo - fhi), 0
end

-- A leg of a rig. `spec`: { id, chain (the names of the map, body to tip), ankle (its place in the chain),
-- sole (the place of the bone that carries the hoof; the ankle when left out), contact (a bone whose rest
-- place is the point that is planted; the tip when left out), centre (how far behind its rest place the middle of its stance is when it walks, a share of the rig's height: under the hip, where the model stands with its feet elsewhere), front (the share of a stance the foot spends
-- in front of its home, 0.5), fold = { swing, stance, skew }, sink, open (radians the leg may open past its
-- rest shape), lift = { walk, trot } (how high the ankle swings, shares of the leg's length), liftSkew,
-- pitch = { stance, swing } and pastern = { swing } (curves of pitch in radians: of the sole against the
-- ground, of the pastern against the sole), extra = { [joint] = { stance, swing } } (curves a joint adds by
-- itself), curl (the pitch of what hangs below the sole), tip = { below, ahead } (where the planted point is
-- from the contact bone, shares of the rig's height: the toe of the mesh on the ground, so that a hoof that
-- rolls onto its toe does not roll into the ground), ease (true for a leg that stands STRAIGHT: such a leg
-- gets no shorter for the first degrees of its fold, so asked to lift it would snap its knee by 25 degrees in
-- one frame. The solver eases the fold of a leg that stands PAST straight in and out over the two ends of its
-- swing by itself; with `ease` a leg that stands exactly straight, or a hair short of it, is eased the same
-- way: the Camel's forelegs, of which one stood past straight and its twin did not) }.
function Kit.leg(rig, spec)
	local at, px, py, pz = rig.at, rig.px, rig.py, rig.pz
	local b = {}
	for j, name in spec.chain do
		b[j] = at[name] or error(`leg {spec.id}: no bone {name}`)
	end
	local n = #b
	local ankle = spec.ankle
	local sole = spec.sole or ankle
	assert(
		ankle >= 2 and ankle <= n and sole >= ankle and sole <= n,
		`leg {spec.id}: its ankle and sole are not in its chain`
	)
	local contact = if spec.contact then (at[spec.contact] or error(`leg {spec.id}: no bone {spec.contact}`)) else b[n]
	local k = ankle - 1
	local sy, sz = table.create(k, 0), table.create(k, 0)
	for j = 1, k do
		sy[j], sz[j] = py[b[j + 1]] - py[b[j]], pz[b[j + 1]] - pz[b[j]]
	end
	local A, S, top = b[ankle], b[sole], b[1]
	-- (the point that is planted: the contact bone's place, or a point of the sole a little below and ahead
	-- of it, where the toe of the mesh really meets the ground)
	local tip = spec.tip or {}
	local cx, cy, cz =
		px[contact], py[contact] - (tip.below or 0) * rig.height, pz[contact] - (tip.ahead or 0) * rig.height
	local fold = spec.fold or {}
	local function numbers(list)
		local out = table.create(k, 0)
		for j = 2, k do
			out[j] = (list and list[j]) or 0
		end
		return out
	end
	local leg = {
		id = spec.id,
		b = b,
		n = n,
		k = k,
		ankle = ankle,
		sole = sole,
		two = sole ~= ankle,
		contact = contact,
		par = rig.parent[top],
		sy = sy,
		sz = sz,
		-- the foot: from the contact up to the sole joint, and from there up to the ankle
		u1x = cx - px[S],
		u1y = cy - py[S],
		u1z = cz - pz[S],
		u2x = px[S] - px[A],
		u2y = py[S] - py[A],
		u2z = pz[S] - pz[A],
		xr = px[A] - px[top], -- how far to the side of the top joint the ankle stands
		offX = px[top] - px[rig.parent[top]],
		offY = py[top] - py[rig.parent[top]],
		offZ = pz[top] - pz[rig.parent[top]],
		hipX = px[top],
		hipY = py[top],
		hipZ = pz[top],
		homeX = cx,
		homeY = cy,
		homeZ = cz,
		restAnkleY = py[A],
		restAnkleZ = pz[A],
		side = if px[contact] >= rig.middle then 1 else -1,
		-- the design
		front = spec.front or 0.5,
		centre = (spec.centre or 0) * rig.height,
		cs = numbers(fold.stance),
		cw = numbers(fold.swing),
		sk = numbers(fold.skew),
		sinkMax = spec.sink or 0,
		qLo = -(spec.open or 0),
		liftWalk = (spec.lift and spec.lift.walk) or 0.08,
		liftTrot = (spec.lift and spec.lift.trot) or (spec.lift and spec.lift.walk) or 0.12,
		liftSkew = spec.liftSkew or 0.76,
		soleStance = spec.pitch and spec.pitch.stance,
		soleSwing = spec.pitch and spec.pitch.swing,
		pasternSwing = spec.pastern and spec.pastern.swing,
		extra = spec.extra,
		toe = spec.curl or 0,
		-- what it is doing
		c = table.create(k, 0),
		e = table.create(k, 0),
		mode = "down",
		phi = 0,
		phase0 = 0,
		s = 0,
		u = 0,
		downT = 1,
		stepT = 0.4,
		wx = 0, -- where its contact is planted, in the world
		wz = 0,
		lx = 0, -- where its ankle left the ground (world x and z, height over the ground)
		ly = 0,
		lz = 0,
		sig0 = 0,
		tau0 = 0,
		liftNow = 0,
		tx = 0, -- this frame's target in the model: the contact while it stands, the ankle while it swings
		ty = 0,
		tz = 0,
		sigma = 0,
		rho = 0,
		tilt = 0, -- what the creature's own design adds to the sole's pitch (a hind leg at rest on its toe)
		drop = 0,
		dropOff = 0,
		q = 0,
		tau = 0,
		over = 0,
	}
	-- the length of the leg at rest, and how far it can fold
	local y0, z0 = sy[1], sz[1]
	for j = 2, k do
		y0 += sy[j]
		z0 += sz[j]
	end
	leg.restD = sqrt(y0 * y0 + z0 * z0)
	leg.span = max(leg.restD, leg.hipY) -- what a displacement of its foot is measured by (see `gait`, the slow walk)
	-- How far it folds, in the air (`qKnee`, `qMax`) and on the ground (`qMaxS`). A leg that stands a little
	-- past straight (a horse's foreleg, back at the knee) first gets LONGER as it folds: `qKnee` is the fold
	-- from which it is shorter than at rest, and only shortens.
	local function span(set)
		for j = 2, k do
			leg.c[j] = set[j]
		end
		local q, last, knee, below = 0, leg.restD, 0, false
		while q < 2.4 do
			local y, z = reach(leg, q + FOLD_STEP)
			local d = sqrt(y * y + z * z)
			if d < FOLD_DEEP * leg.restD or (below and d >= last) then
				break
			end
			if d >= leg.restD and not below then
				if q > 0.6 then
					break -- (this set does not fold the leg at all)
				end
			elseif not below then
				below = true
				-- (where it is as long as at rest again, between the two looks: two rigs of the same model
				-- that differ by a hair must not differ by a whole look here)
				knee = if last > leg.restD then q + FOLD_STEP * (last - leg.restD) / (last - d) else 0
			end
			q, last = q + FOLD_STEP, d
		end
		if not below then
			return 0, 0
		end
		return knee, max(q, knee)
	end
	local _, standing = span(leg.cs)
	leg.qMaxS = standing
	-- (the longest it gets on the ground: a leg that may open past its rest shape reaches further)
	local ly, lz = reach(leg, leg.qLo)
	leg.longD = max(leg.restD, sqrt(ly * ly + lz * lz))
	leg.qKnee, leg.qMax = span(leg.cw)
	-- (`ease`: a leg that stands STRAIGHT, not past it, is eased at lift as one that stands past straight is)
	if spec.ease and leg.qKnee <= 0 then
		leg.qKnee = 1e-3
	end
	leg.near, leg.q0 = leg.qKnee, 0
	return leg
end

-- The walker: a clock, and feet planted in the world --------------------------------------------------------
-- `design`:
--   start, stop    the Froude numbers (speed^2 / (G x leg length)) at which it starts and stops stepping
--   walk = { offsets (the share of a stride at which each leg, in the order of the legs, touches down),
--            duty = { at, slope, ref, least, most } (the share of a stride a foot is down: `at` at the Froude
--            number `ref`, falling by `slope` for each e-fold of speed), stride = { k, p } (stride length =
--            k x leg x Froude^p) }
--   trot = the same and { from, back (the Froude numbers at which it changes up and down), shift (seconds
--            the change takes) }; left out for an animal that only walks
--   sweep          the most a foot travels on the ground in one stance, shares of the leg's length: a stride
--                  that would need more makes the legs go quicker instead
--   finish         strides (in units of sqrt(G / leg)) at which a step is finished when it stops
--   settle = { far (shares of the leg: a foot left further than this from its home steps back to it), time
--            (the step, in units of sqrt(leg / G)), least, mean, most (the wait before one, same units) }
--   trot.sweep     the same for the trot, when it may reach further than the walk
--   letGo, comeDown   the body between two steps of one pair of legs: it rises from where a foot left over the
--                  first `letGo` of that foot's swing (0.8) and comes down for where it lands from `comeDown`
--                  of it on (0.35). Sooner up and later down is a bigger rise over the standing leg and a
--                  quicker one; later up and sooner down presses the standing leg (its pastern sinks)
--   comfy          the share of its rest length a leg stands at when the body hangs from it (0.995)
--   turnArm        studs from the pivot at which a turn on the spot counts as walking (half the wheelbase)
--   (nothing to set) A PIVOT THAT GOES ON SLOWER THAN `start`, at a steady pace, is walked with all the same, in
--                  small steps: the client's slow turn is a fifth of the stroll pace (see `gait`, "a pivot that
--                  keeps going is walking"). `start` and `stop` need not be lowered for it.
--   firstStep      (left out: nothing) for a SMALL, QUICK walker: the step it sets off with, in units of
--                  sqrt(leg / G), when the foot that should lead a walk missed its moment (see the end of `gait`)
function Kit.walker(rig, design, legs, seed)
	local h = 0
	local zMin, zMax = math.huge, -math.huge
	local tops = {}
	for i, leg in legs do
		h += leg.hipY
		zMin, zMax = min(zMin, leg.homeZ), max(zMax, leg.homeZ)
		tops[i] = leg.b[1]
	end
	h /= #legs
	local W = {
		rig = rig,
		design = design,
		legs = legs,
		n = #legs,
		h = h, -- the leg length every tempo is worked out from
		tick = sqrt(h / Kit.G), -- its unit of time
		arm = design.turnArm or max(0.25 * h, 0.5 * (zMax - zMin)),
		trunk = Kit.path(rig, tops),
		fk = Kit.newFk(rig),
		dice = Kit.dice((seed or 0) * 0.731 + 0.137),
		fresh = true,
		x = 0,
		z = 0,
		yaw = 0,
		vx = 0,
		vz = 0,
		w = 0,
		speed = 0,
		veff = 0,
		fr = 0,
		phase = 0,
		f = 0,
		g = 0, -- 0 walk to 1 trot
		trotting = false,
		moving = false,
		amount = 0, -- 0 standing to 1 walking, eased: what the body's swing is scaled by
		duty = 0.7,
		stride = h,
		since = 1, -- strides since it started to walk
		settleAt = 0,
		clock = 0,
		frWas = 0, -- its Froude number in the frame before
		crept = 0, -- how far a foot's home has gone, slower than a walk, since it last stepped, in legs (see `gait`)
		slow = nil :: number?, -- the Froude number it was caught creeping at, while it walks that slowly
		going = false, -- (`firstStep`) whether it walked in the frame before; `late` is the foot it put off
	}
	for i, leg in legs do
		local ow = design.walk.offsets[i]
		local ot = if design.trot then design.trot.offsets[i] else ow
		leg.offW = ow
		leg.offD = (ot - ow + 0.5) % 1 - 0.5 -- the short way round
	end
	return W
end

-- The ankle of a foot that stands (in the model, the trunk taken as level): from its contact, the pitch of
-- its sole and the sink of its pastern.
local function ankleOf(leg, cx, cy, cz, sigma, sunk)
	if not leg.two then
		sigma += sunk -- (a foot of one bone tilts as a whole)
	end
	local cs, ss = cos(sigma), sin(sigma)
	local y = cy - (leg.u1y * cs - leg.u1z * ss)
	local z = cz - (leg.u1y * ss + leg.u1z * cs)
	if leg.two then
		local b = sigma + sunk
		local cb, sb = cos(b), sin(b)
		y -= leg.u2y * cb - leg.u2z * sb
		z -= leg.u2y * sb + leg.u2z * cb
	end
	return cx - leg.u1x - leg.u2x, y, z
end

-- The slow walk (see `gait`, "a pivot that keeps going is walking")
local CREEP = 0.03 -- of its own leg: how far the home of a foot goes, under `start`, before the walker steps all the same
local SLOW_STRIDE = 0.12 -- of the leg: the longest stride of a walk it was caught creeping into
local STEADY = 1.2 -- a second: its pace is steady while its Froude number changes by less than this share of itself
local STILL = 0.15 -- of the Froude number it was caught creeping at: under this it stands again
local CREEP_REST = 0.02 -- of `stop`: a pivot slower than this stands, and what it crept is forgotten

local function plantAtHome(leg, x, z, cy, sy)
	leg.mode, leg.s, leg.u, leg.downT = "down", 0, 0.4, 1
	leg.wx = x + leg.homeX * cy + leg.homeZ * sy
	leg.wz = z - leg.homeX * sy + leg.homeZ * cy
	leg.sigma, leg.rho, leg.sig0, leg.tau0 = 0, 0, 0, 0
	leg.dropOff = 0
end

-- One frame of the clock and the feet. `input`: { x, z, yaw (where the model's pivot is in the world and
-- which way it looks), jump (it was put somewhere else) }. After it every leg has its target for `solve`
-- (`tx`, `ty`, `tz`, `sigma`, `rho`) and `drop` (how far its hip must come down for it, for `girdle`).
function Kit.gait(W, dt, input)
	local D = W.design
	local legs = W.legs
	-- (it was just stood on its feet: said here, before `dt` and `fresh` are changed below)
	local stood = W.fresh or input.jump or dt <= 0 or dt > 0.4
	if W.late then
		-- (the first step of a walk, put off by a frame: `firstStep`, at the end)
		Kit.step(W, W.late, D.firstStep)
		W.late = nil
	end
	local x, z, yaw = input.x, input.z, input.yaw
	local cy, sy = cos(yaw), sin(yaw)
	if stood then
		W.fresh = false
		W.vx, W.vz, W.w, W.f, W.moving, W.amount = 0, 0, 0, 0, false, 0
		W.crept, W.slow, W.frWas = 0, nil, 0
		for _, leg in legs do
			plantAtHome(leg, x, z, cy, sy)
		end
		dt = 0
	else
		local k = 1 - exp(-12 * dt)
		W.vx += ((x - W.x) / dt - W.vx) * k
		W.vz += ((z - W.z) / dt - W.vz) * k
		W.w += (wrap(yaw - W.yaw) / dt - W.w) * k
	end
	W.x, W.z, W.yaw = x, z, yaw
	W.clock += dt
	local h, tick = W.h, W.tick
	local speed = sqrt(W.vx * W.vx + W.vz * W.vz)
	local veff = speed + abs(W.w) * W.arm
	local fr = veff * veff / (Kit.G * h)
	W.speed, W.veff, W.fr = speed, veff, fr

	-- walk or trot
	local trot = D.trot
	if trot then
		if W.trotting then
			W.trotting = fr > trot.back
		else
			W.trotting = fr > trot.from
		end
		local want = if W.trotting then 1 else 0
		W.g = clamp(W.g + clamp(want - W.g, -dt / trot.shift, dt / trot.shift), 0, 1)
	end
	local g = smooth(W.g)

	-- how long a foot is down, how long a stride is
	local safe = max(fr, 1e-4)
	local wd = D.walk.duty
	local b = clamp(wd.at - wd.slope * log(safe / wd.ref), wd.least, wd.most)
	local length = h * D.walk.stride[1] * safe ^ D.walk.stride[2]
	if trot then
		local td = trot.duty
		local bt = clamp(td.at - td.slope * log(safe / td.ref), td.least, td.most)
		b += (bt - b) * g
		length += (h * trot.stride[1] * safe ^ trot.stride[2] - length) * g
	end
	-- (the first stride after a start keeps three feet down)
	if W.since < 0.75 then
		b = max(b, 0.76)
	end
	-- (the legs can only sweep so far: beyond that they go quicker)
	local sweep = D.sweep * h
	if trot and trot.sweep then
		sweep += (trot.sweep - D.sweep) * h * g
	end
	if b * length > sweep then
		length = sweep / b
	end
	-- (a walk slower than a walk, see below: small steps, so that no foot is left far however it turns; they
	-- grow into the strides of its walk as it gathers speed, `quick` 1 to 0)
	local quick = if W.slow then 1 - smooth((fr - W.slow) / max(D.start - W.slow, 1e-6)) else 0
	if quick > 0 then
		local short = min(length, SLOW_STRIDE * h)
		length = short + (length - short) * (1 - quick)
	end
	length = max(length, 0.05 * h)
	W.duty, W.stride = b, length

	-- starting and stopping
	local anySwing, anyStep = false, false
	for _, leg in legs do
		anySwing = anySwing or leg.mode == "swing"
		anyStep = anyStep or leg.mode == "step"
	end
	-- A PIVOT THAT KEEPS GOING IS WALKING, HOWEVER SLOWLY. `start` and `stop` tell a walk from a stand by the
	-- speed alone, and the client's slow turn (a fifth of the stroll pace, for many seconds: PetWander) lies
	-- UNDER them for most animals: the feet then stood where they were while the body went on, the legs were
	-- stretched after them and the body sank into the ground. So how far the feet are being left is counted too
	-- (`crept`: the way the home of the fastest foot has gone since the walker last stepped, in its own legs; a
	-- turn on the spot carries the feet far from the pivot furthest): once that is `CREEP` and the pivot goes on
	-- at a STEADY pace (it is neither gathering speed, which takes it over `start` by itself, nor coming to
	-- rest), the walker steps, whatever its speed, the foot furthest from its home first, in strides no longer
	-- than `SLOW_STRIDE` and as quick as that foot needs. It then walks on until the pivot all but stands
	-- (`STILL` of the Froude number it was caught at: a turn that changes sides halves it, a stop takes it to
	-- nothing), or goes fast enough for `start` and `stop` to hold again. An ordinary start and an ordinary
	-- stop are never steady under `start` (their pace changes by 3.5 of itself a second and more): neither is
	-- touched, and every animal's walk at its pace is what it was.
	local steady = abs(fr - W.frWas) <= STEADY * fr * dt
	W.frWas = fr
	-- (the foot whose home goes fastest, by its own leg: a short hind leg far from the pivot is the one a turn
	-- on the spot leaves behind first)
	local pace = 0
	if W.slow or not W.moving then
		for _, leg in legs do
			local ox, oz = leg.homeX * cy + leg.homeZ * sy, -leg.homeX * sy + leg.homeZ * cy
			local ux, uz = W.vx + W.w * oz, W.vz - W.w * ox
			pace = max(pace, sqrt(ux * ux + uz * uz) / leg.span)
		end
	end
	if W.moving or fr < CREEP_REST * D.stop then
		W.crept = 0
	else
		W.crept += pace * dt
	end
	if W.moving then
		if fr >= D.start then
			W.slow = nil
		end
		if fr < (if W.slow then min(D.stop, STILL * W.slow) else D.stop) then
			W.moving, W.slow = false, nil
			W.settleAt = W.clock + Kit.wait(W.dice, D.settle.least, D.settle.mean, D.settle.most) * tick
		end
	elseif (fr > D.start or (steady and W.crept > CREEP)) and dt > 0 then
		W.slow = if fr > D.start then nil else fr
		W.moving = true
		if not anySwing then
			-- the leg that is furthest behind its home lifts first; nobody else is in the air at that moment
			-- (from a square stand, where none is behind, its own dice say which)
			local first = 1 + floor(Kit.roll(W.dice) * #legs) % #legs
			local far = 0.03 * h
			local fx, fz = W.vx / max(speed, 1e-6), W.vz / max(speed, 1e-6)
			for i, leg in legs do
				local hx = x + leg.homeX * cy + leg.homeZ * sy
				local hz = z - leg.homeX * sy + leg.homeZ * cy
				-- (caught creeping, it may be turning on the spot: then no foot is "behind", the one furthest from
				-- its home goes)
				local behind = if W.slow
					then sqrt((hx - leg.wx) ^ 2 + (hz - leg.wz) ^ 2) * h / leg.span
					else (hx - leg.wx) * fx + (hz - leg.wz) * fz
				if behind > far then
					first, far = i, behind
				end
			end
			local leg = legs[first]
			W.phase = frac(max(b, 0.76) + leg.offW + leg.offD * g + 1e-4)
			W.since = 0
			for _, other in legs do
				other.phi = frac(W.phase - other.offW - other.offD * g)
			end
		end
	end
	local f = 0
	if W.moving then
		-- (caught creeping, its steps keep up with the foot that is left behind fastest)
		f = (veff + max(pace * h - veff, 0) * quick) / length
	elseif anySwing then
		f = D.finish / tick -- (a step that has begun is finished)
	end
	W.f = f
	W.phase += f * dt
	W.since += f * dt
	W.amount += ((if W.moving then 1 else 0) - W.amount) * (1 - exp(-dt * 2.2 / tick))

	-- a foot that was left far from its home steps back to it, one at a time, when it has stood a while
	if not W.moving and not anySwing and not anyStep and dt > 0 and W.clock >= W.settleAt then
		local worst, far = nil, D.settle.far * h
		for _, leg in legs do
			local hx = x + leg.homeX * cy + leg.homeZ * sy
			local hz = z - leg.homeX * sy + leg.homeZ * cy
			local gap = sqrt((hx - leg.wx) ^ 2 + (hz - leg.wz) ^ 2)
			if gap > far then
				worst, far = leg, gap
			end
		end
		if worst then
			Kit.step(W, worst, D.settle.time)
		end
		W.settleAt = W.clock + Kit.wait(W.dice, D.settle.least, D.settle.mean, D.settle.most) * tick
	end

	local stanceT = b / max(f, 0.2 / tick)
	local travel = if W.moving then b * length * speed / max(veff, 1e-6) else 0
	local liftShare = clamp(travel / (0.5 * sweep), 0.4, 1)
	for _, leg in legs do
		local phi = frac(W.phase - leg.offW - leg.offD * g)
		local mode = leg.mode
		local wrapped = phi < leg.phi - 0.5
		leg.phi = phi
		if mode == "down" then
			leg.downT += dt
			if f > 0 and W.moving and phi >= b and phi < b + (1 - b) * 0.35 then
				mode = "swing"
				leg.phase0 = phi
				-- it leaves the ground: where its ankle is now, in the world
				local dx, dz = leg.wx - x, leg.wz - z
				local ax, ay, az = ankleOf(leg, dx * cy - dz * sy, leg.homeY, dx * sy + dz * cy, leg.sigma, leg.tau)
				leg.lx, leg.ly, leg.lz = x + ax * cy + az * sy, ay, z - ax * sy + az * cy
				leg.sig0, leg.tau0, leg.dropOff = leg.sigma, leg.tau, leg.drop
				leg.q0, leg.near = leg.q, leg.qKnee
				leg.mode, leg.s = "swing", 0
				leg.liftNow = (leg.liftWalk + (leg.liftTrot - leg.liftWalk) * g) * h * liftShare
			end
		elseif mode == "swing" then
			if wrapped then
				mode = "land"
			else
				leg.s = clamp((phi - leg.phase0) / (1 - leg.phase0), leg.s, 1)
			end
		elseif mode == "step" then
			leg.s += dt / leg.stepT
			if leg.s >= 1 then
				mode = "land"
			end
		end

		if mode == "swing" or mode == "step" or mode == "land" then
			-- where it will come down: its home as the body will stand over it in the middle of its stance
			local s = leg.s
			local left = if mode == "step"
				then (1 - s) * leg.stepT
				elseif mode == "land" then 0
				else (1 - phi) / max(f, 0.2 / tick)
			left = min(left, 3 * tick)
			local ahead = left + (if W.moving then stanceT * leg.front else 0)
			local fyaw = yaw + clamp(W.w * ahead, -0.5, 0.5)
			local fc, fs = cos(fyaw), sin(fyaw)
			local cx = x + W.vx * ahead + leg.homeX * fc + (leg.homeZ + leg.centre * W.amount) * fs
			local cz = z + W.vz * ahead - leg.homeX * fs + (leg.homeZ + leg.centre * W.amount) * fc
			if mode == "land" then
				leg.mode, leg.s, leg.u, leg.downT = "down", 0, 0, 0
				leg.wx, leg.wz = cx, cz
				leg.sigma, leg.rho, leg.sig0, leg.tau0 = 0, 0, 0, 0
				mode = "down"
			else
				-- the ankle of the foot as it will stand there, flat
				local lyaw = yaw + clamp(W.w * left, -0.5, 0.5)
				local lc, ls = cos(lyaw), sin(lyaw)
				local ox, oz = -(leg.u1x + leg.u2x), -(leg.u1z + leg.u2z)
				local ax, az = cx + ox * lc + oz * ls, cz - ox * ls + oz * lc
				local e = ease(s ^ 0.9)
				local wx, wz = leg.lx + (ax - leg.lx) * e, leg.lz + (az - leg.lz) * e
				local up = sin(pi * s ^ leg.liftSkew)
				local dx, dz = wx - x, wz - z
				leg.tx, leg.tz = dx * cy - dz * sy, dx * sy + dz * cy
				leg.ty = leg.ly + (leg.restAnkleY - leg.ly) * smooth(s) + leg.liftNow * up * up
				-- the sole and the pastern: flipped back, then forward again to land flat
				local fade = 1 - smooth(s / 0.25)
				local sole = if leg.soleSwing then Kit.curve(leg.soleSwing, s) * liftShare else 0
				local sole0 = if leg.soleSwing then leg.soleSwing[2] * liftShare else 0
				leg.sigma = sole + (leg.sig0 - sole0) * fade + leg.tilt * (1 - smooth(s * 4))
				leg.rho = (if leg.pasternSwing then Kit.curve(leg.pasternSwing, s) * liftShare else 0) + leg.tau0 * fade
				-- what its hip asks of the body: let go of where it left, come down for where it lands
				local dTd = (stanceT * leg.front * speed) - (leg.restAnkleZ + leg.centre * W.amount - leg.hipZ)
				local long = leg.longD * D.comfy
				local dropLand =
					max(0, leg.hipY - leg.restAnkleY - sqrt(max(long * long - dTd * dTd, 0.01 * long * long)))
				local letGo, comeDown = D.letGo or 0.8, D.comeDown or 0.35
				leg.drop =
					max(leg.dropOff * (1 - smooth(s / letGo)), dropLand * smooth((s - comeDown) / (1 - comeDown)))
			end
		end
		if mode == "down" then
			local dx, dz = leg.wx - x, leg.wz - z
			leg.tx, leg.ty, leg.tz = dx * cy - dz * sy, leg.homeY, dx * sy + dz * cy
			local u = if f > 0 and W.moving then min(phi / b, 1) else leg.u
			leg.u = u
			local want = leg.tilt
			if f > 0 and W.moving and leg.soleStance then
				want += Kit.curve(leg.soleStance, u) * liftShare
			end
			leg.sigma += (want - leg.sigma) * (1 - exp(-dt * 6 / tick))
			leg.rho = 0
			-- how far its hip must come down for it to reach
			local ax, ay, az = ankleOf(leg, leg.tx, leg.ty, leg.tz, leg.sigma, 0)
			local ddx, ddz = ax - leg.hipX - leg.xr, az - leg.hipZ
			local long = leg.longD * D.comfy
			if ddx * ddx + ddz * ddz > 1.2 * long * long then
				-- (a foot left far from its leg: the model was spun on the spot, or pushed about at a few frames a
				-- second. It is put under its hip again rather than stretched after)
				plantAtHome(leg, x, z, cy, sy)
				leg.tx, leg.tz = leg.homeX, leg.homeZ
				ax, ay, az = ankleOf(leg, leg.tx, leg.ty, leg.tz, 0, 0)
				ddx, ddz = ax - leg.hipX - leg.xr, az - leg.hipZ
			end
			leg.drop = max(0, leg.hipY - ay - sqrt(max(long * long - ddx * ddx - ddz * ddz, 0.01 * long * long)))
		end
	end

	-- THE FIRST STEP OF A SMALL, QUICK WALKER (`design.firstStep`; an animal that leaves it out is untouched).
	-- The foot that leads a walk is lifted within a small window of its stride (above: from `b` to a third of
	-- the swing past it). An animal that takes three strides a second and more is carried past that window by
	-- ONE frame: the foot the clock chose then stands through a whole stride, the rump squats to reach it and
	-- the trunk pitches at every start (the Lizard: 5.7% of its height, 6.6 degrees). So a walk that has begun
	-- with no foot in the air steps that foot, the one furthest through its stride, at the start of the next
	-- frame, in a step of `firstStep` (about as long as a foot is in the air walking: 0.75).
	if D.firstStep then
		if W.moving and not W.going and not stood then
			local lead, lifted = legs[1], false
			for _, leg in legs do
				lifted = lifted or leg.mode ~= "down"
				if leg.phi > lead.phi then
					lead = leg
				end
			end
			if not lifted then
				W.late = lead
			end
		end
		W.going = W.moving
		if stood then
			W.late = nil
		end
	end
end

-- Makes one foot step back to its home now (a creature that stands shifts a leg). `time`: the step, in
-- units of sqrt(leg / G). Nothing happens while another foot is in the air.
function Kit.step(W, leg, time)
	for _, other in W.legs do
		if other.mode ~= "down" then
			return false
		end
	end
	local x, z, cy, sy = W.x, W.z, cos(W.yaw), sin(W.yaw)
	local dx, dz = leg.wx - x, leg.wz - z
	local ax, ay, az = ankleOf(leg, dx * cy - dz * sy, leg.homeY, dx * sy + dz * cy, leg.sigma, leg.tau)
	leg.lx, leg.ly, leg.lz = x + ax * cy + az * sy, ay, z - ax * sy + az * cy
	leg.sig0, leg.tau0, leg.dropOff = leg.sigma, leg.tau, leg.drop
	leg.q0, leg.near = leg.q, leg.qKnee
	leg.mode, leg.s, leg.stepT = "step", 0, time * W.tick
	leg.liftNow = leg.liftWalk * W.h * 0.45
	return true
end

-- How far a pair of hips must come down for both its feet: the bigger of the two asks, without a corner
-- where one takes over from the other.
function Kit.girdle(W, i, j)
	local a, b = W.legs[i].drop, W.legs[j].drop
	local a2, b2 = a * a, b * b
	return sqrt(sqrt(a2 * a2 + b2 * b2))
end

-- How much of its swing a leg is through, as a bump: 0 on the ground, 1 at the top of its arc.
function Kit.lifted(leg)
	if leg.mode == "down" then
		return 0
	end
	local up = sin(pi * leg.s ^ leg.liftSkew)
	return up * up
end

-- Solves one leg: turns its bones in `pose` so that its foot is at this frame's target, the trunk being
-- where `fk` says.
local function solveLeg(W, leg, pose)
	local fk = W.fk
	local m = fk.m
	local par = leg.par
	local a = (par - 1) * 9
	local r11, r12, r13 = m[a + 1], m[a + 2], m[a + 3]
	local r21, r22, r23 = m[a + 4], m[a + 5], m[a + 6]
	local r31, r32, r33 = m[a + 7], m[a + 8], m[a + 9]
	-- the top joint, and the target in the frame of what the leg hangs on
	local dx = leg.tx - (fk.x[par] + r11 * leg.offX + r12 * leg.offY + r13 * leg.offZ)
	local dy = leg.ty - (fk.y[par] + r21 * leg.offX + r22 * leg.offY + r23 * leg.offZ)
	local dz = leg.tz - (fk.z[par] + r31 * leg.offX + r32 * leg.offY + r33 * leg.offZ)
	local lx = r11 * dx + r21 * dy + r31 * dz
	local ly = r12 * dx + r22 * dy + r32 * dz
	local lz = r13 * dx + r23 * dy + r33 * dz
	-- (the turn in that frame that is level in the world: the sole is held against the ground, not the trunk)
	local level = atan2(r23, r22)
	local k = leg.k
	local c, e, sk = leg.c, leg.e, leg.sk
	local swinging = leg.mode ~= "down"
	local s = leg.s
	-- how the joints share the fold: the stance's way on the ground, the swing's in the air
	local set = if swinging then leg.cw else leg.cs
	local extra = leg.extra
	for j = 2, k do
		c[j] = if swinging then set[j] * (1 + sk[j] * (1 - 2 * s)) else set[j]
		local add = 0
		if extra and extra[j] then
			local curves = extra[j]
			if swinging then
				add = if curves.swing then Kit.curve(curves.swing, s) else 0
			else
				add = if curves.stance then Kit.curve(curves.stance, leg.u) * W.amount else 0
			end
		end
		e[j] = add
	end
	local sg = leg.sigma + level
	local q, tau, over = 0, 0, 0
	local ax, ay, az
	-- (what a foot that is not under its leg adds to the length the leg must have: see the lean below)
	local lat = 0
	if swinging then
		-- in the air the leg folds as far as its ankle is near. A leg that stands PAST straight cannot do that
		-- from the first moment (it would first have to get longer): it leaves the ground and comes back to it in
		-- the shape it stands in, and its fold comes in over the start of the swing and goes out over its end
		-- (for those moments it is a hair longer than asked: nobody sees it)
		ax, ay, az = lx, ly, lz
		lat = ax * ax - leg.xr * leg.xr
		local found
		found, over = foldFor(leg, (ay * ay + az * az + lat), leg.qKnee, leg.qMax, leg.near)
		leg.near = found
		if leg.qKnee > 0 then
			q = found * smooth(s / 0.18) * (1 - smooth((s - 0.78) / 0.22)) + leg.q0 * (1 - smooth(s / 0.25))
			over = 0
		else
			q = found
		end
		if not leg.two then
			tau = leg.tau0 * (1 - smooth(s / 0.25)) -- (what its one bone had tilted goes out as it lifts)
		end
	else
		-- the sole joint from the contact, then the ankle with the pastern as it stands
		local c1, s1 = cos(sg), sin(sg)
		local vy, vz, px, pz = leg.u1y, leg.u1z, ly, lz
		if leg.two then
			px, pz = ly - (leg.u1y * c1 - leg.u1z * s1), lz - (leg.u1y * s1 + leg.u1z * c1)
			vy, vz = leg.u2y, leg.u2z
		end
		ax = lx - leg.u1x - leg.u2x
		lat = ax * ax - leg.xr * leg.xr
		ay, az = px - (vy * c1 - vz * s1), pz - (vy * s1 + vz * c1)
		local ry, rz = reach(leg, 0)
		local d0 = ry * ry + rz * rz
		if (ay * ay + az * az + lat) >= d0 then
			-- at full length (or beyond): nothing sinks; a leg that may open past its rest shape does
			q, over = foldFor(leg, (ay * ay + az * az + lat), leg.qLo, 0, leg.q)
		else
			-- the body is lower than the leg is long: the pastern sinks, and what it cannot take the leg folds
			-- (a foot that has just landed has not sunk yet: what there is to take, the fold takes for that moment)
			local most = leg.sinkMax * smooth(leg.downT / (0.5 * W.tick))
			local cm, sm = cos(sg + most), sin(sg + most)
			local my, mz = px - (vy * cm - vz * sm), pz - (vy * sm + vz * cm)
			if most > 0 and (my * my + mz * mz + lat) >= d0 then
				local lo, hi = 0, most
				local flo, fhi = (ay * ay + az * az + lat) - d0, (my * my + mz * mz + lat) - d0
				while hi - lo > SINK_FINE do
					local mid = (lo + hi) / 2
					local ct, st = cos(sg + mid), sin(sg + mid)
					local ty, tz = px - (vy * ct - vz * st), pz - (vy * st + vz * ct)
					local f = (ty * ty + tz * tz + lat) - d0
					if f < 0 then
						lo, flo = mid, f
					else
						hi, fhi = mid, f
					end
				end
				-- (to a hair: a body that only breathes must not make a hoof tick)
				tau = if fhi > flo then lo + (hi - lo) * -flo / (fhi - flo) else (lo + hi) / 2
				local ct, st = cos(sg + tau), sin(sg + tau)
				ay, az = px - (vy * ct - vz * st), pz - (vy * st + vz * ct)
			else
				-- (all the sink there is, if sinking helps at all: a pastern that lies nearly flat gives nothing)
				if (my * my + mz * mz) > (ay * ay + az * az) then
					tau = most
					ay, az = my, mz
				end
				q = foldFor(leg, (ay * ay + az * az + lat), 0, leg.qMaxS, max(leg.q, 0))
			end
		end
	end
	leg.q, leg.tau, leg.over = q, tau, over
	local ey, ez, sum = reach(leg, q)
	-- to the side, when the foot is not under the leg: the top joint leans (about the leg's own forward axis,
	-- before it is aimed) until the ankle is as far to the side as its target, and the leg is aimed as it then
	-- lies. (No leg is aimed or leant absurdly far, whatever is asked of it.)
	local xr = leg.xr
	local across = sqrt(xr * xr + ey * ey)
	local side = clamp(-math.acos(clamp(ax / max(across, 1e-6), -1, 1)) - atan2(ey, xr), -0.6, 0.6)
	local aim = clamp(wrap(atan2(az, ay) - atan2(ez, xr * sin(side) + ey * cos(side))), -1.5, 1.5)
	local b = leg.b
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	rx[b[1]], ry[b[1]], rz[b[1]] = aim, 0, side
	for j = 2, k do
		local i = b[j]
		rx[i], ry[i], rz[i] = c[j] * q + e[j], 0, 0
	end
	-- the foot: held against the ground
	local turned = aim + sum
	local ankle, sole = leg.ankle, leg.sole
	if leg.two then
		local pastern = sg + (if swinging then leg.rho else tau)
		rx[b[ankle]], ry[b[ankle]], rz[b[ankle]] = wrap(pastern - turned), 0, -side
		for j = ankle + 1, sole - 1 do
			local i = b[j]
			rx[i], ry[i], rz[i] = 0, 0, 0
		end
		rx[b[sole]], ry[b[sole]], rz[b[sole]] = wrap(sg - pastern), 0, 0
	else
		rx[b[ankle]], ry[b[ankle]], rz[b[ankle]] = wrap(sg + tau - turned), 0, -side
	end
	for j = sole + 1, leg.n do
		local i = b[j]
		rx[i], ry[i], rz[i] = leg.toe, 0, 0
	end
end

-- Solves every leg: call it once the trunk's turns and the root's offset are in `pose`.
function Kit.solve(W, pose)
	Kit.forward(W.rig, pose, W.trunk, W.fk)
	for _, leg in W.legs do
		solveLeg(W, leg, pose)
	end
end

-- A LONG FOOT KEPT STRAIGHT: call it for a leg after `solve`. The solver leans a leg sideways at its top joint
-- and takes the lean out again at the ankle. Between the two the leg is pitched, so the two turns do not quite
-- cancel: a hoof does not show it, a foot longer than the leg does (its toe swings to the side while it
-- stands: the Twigling's, the Sand Golem's boots, the Meerkat's). This turns the foot bone so that the foot is
-- exactly what the solver meant: pitched against the ground, and nothing else.
function Kit.straighten(pose, leg)
	local b = leg.b
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local side = rz[b[1]]
	local sum = 0
	for j = 2, leg.k do
		sum += rx[b[j]]
	end
	local foot = b[leg.ankle]
	local pitch = rx[foot] + sum -- (the foot's pitch, less the aim of the top joint: the aim is before the lean)
	local ca, sa = cos(-sum), sin(-sum)
	local cs, ss = cos(-side), sin(-side)
	local cp, sp = cos(pitch), sin(pitch)
	local yaw, roll = atan2(ss * sp, -sa * cs * sp + ca * cp), atan2(ca * ss, ca * cs * cp - sa * sp)
	-- (a leg that was left lying far out, by a model spun on the spot, keeps the solver's own answer)
	if abs(yaw) < 0.7 and abs(roll) < 0.7 then
		rx[foot], ry[foot], rz[foot] = asin(clamp(ca * cs * sp + sa * cp, -1, 1)), yaw, roll
	end
end

-- A leg that sticks out to the SIDE (a crab's, a beetle's, a spider's) ----------------------------------------
-- `leg`, `walker` and `gait` serve such a leg as any other: they say where its point stands, when it lifts
-- and where it lands. What does not fit it is `solve`, which folds a leg seen from the side. A leg that
-- sprawls is three bones (HIP, KNEE, POINT: `ankle = 3` in its spec) and is solved as a crab's leg works
-- (docs/MOTION.md, section 16):
--   the KNEE is one hinge about the axis across the leg's own plane at rest (the plane of its two pieces): it
--     is bent as far as the point is from the hip, between `open` and `shut`;
--   the HIP then swings the leg about the upright of what it hangs on until it points at the target, and
--     lifts or lowers it (two hinges at right angles).
-- `sprawl(rig, leg, spec)` gives a leg of `Kit.leg` what that takes. `spec`: { open, shut (radians the knee is
-- bent at least and at most), swing, lift (radians the hip swings and lifts at most, whatever its foot asks),
-- tiptoe (true: the leg STANDS ON ITS POINT, below) }.
--   A leg modelled all but straight with the heel of its foot near the ground (the Sun Scarab's: each within 3%
--   of its full length) has nothing to step with the way it was made: bent that way, its foot lies flatter the
--   nearer its hip comes and the heel goes into the ground. With `tiptoe` its joint is bent on the FAR side of
--   straight (through straight, and as far beyond as the point is near): the foot tips onto its point and its
--   heel rises; and its hip is turned the SHORTEST way that points the leg at its target (`swing` is then the
--   most it turns at all), not about the upright from the heading of the bent leg: folded this way a point
--   comes in under its hip, where a heading is nothing to turn from, and the hip would jump.
-- It returns the lengths of the leg's two pieces: a module that stands its animal lower than it was modelled
-- (a leg that hangs in the air in the model) works out from them where each point stands, and writes that
-- into `homeX`, `homeY`, `homeZ`, `restAnkleY` and `xr` of the leg before it makes the walker.
function Kit.sprawl(rig, leg, spec)
	local px, py, pz = rig.px, rig.py, rig.pz
	local hip, knee, tip = leg.b[1], leg.b[2], leg.b[3]
	assert(tip and leg.ankle == 3, `leg {leg.id}: a leg that sprawls is a hip, a knee and a point (ankle = 3)`)
	-- its two pieces at rest, and the axis of its knee: across the plane they lie in
	local ax, ay, az = px[knee] - px[hip], py[knee] - py[hip], pz[knee] - pz[hip]
	local bx, by, bz = px[tip] - px[knee], py[tip] - py[knee], pz[tip] - pz[knee]
	local A, B = sqrt(ax * ax + ay * ay + az * az), sqrt(bx * bx + by * by + bz * bz)
	local nx, ny, nz = ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
	local n = max(sqrt(nx * nx + ny * ny + nz * nz), 1e-9)
	nx, ny, nz = nx / n, ny / n, nz / n
	leg.ax, leg.ay, leg.az = ax, ay, az
	leg.bx, leg.by, leg.bz = bx, by, bz
	leg.nx, leg.ny, leg.nz = nx, ny, nz
	-- (the lower piece turned a quarter about that axis: what a bend adds to it)
	leg.cx, leg.cy, leg.cz = ny * bz - nz * by, nz * bx - nx * bz, nx * by - ny * bx
	leg.A2, leg.B2, leg.AB2 = A * A, B * B, 2 * A * B
	leg.bend0 = acos(clamp((ax * bx + ay * by + az * bz) / (A * B), -1, 1))
	leg.kneeOpen, leg.kneeShut = spec.open, spec.shut
	leg.swingMost, leg.liftMost = spec.swing, spec.lift
	leg.long = sqrt(A * A + B * B + 2 * A * B * cos(spec.open))
	leg.short = sqrt(A * A + B * B + 2 * A * B * cos(spec.shut))
	leg.tiptoe = spec.tiptoe == true
	return A, B
end

-- Puts the point of a leg that sprawls at this frame's target of `gait` (`tx`, `ty`, `tz`, in the model), the
-- trunk being where `W.fk` says: call `forward(W.rig, pose, W.trunk, W.fk)` once the trunk's turns and the
-- root's offset are in `pose`, then this for each such leg, INSTEAD of `solve`. It is exact: a planted point
-- does not slide and is never under the ground. `leg.over` is how far the point is from its target when the
-- leg cannot reach it. (A leg set up with `tiptoe` is bent on the far side of straight and its hip turned the
-- shortest way: see `sprawl`.)
function Kit.reachOut(W, leg, pose)
	local fk = W.fk
	local m = fk.m
	local par = leg.par
	local p = (par - 1) * 9
	local r11, r12, r13 = m[p + 1], m[p + 2], m[p + 3]
	local r21, r22, r23 = m[p + 4], m[p + 5], m[p + 6]
	local r31, r32, r33 = m[p + 7], m[p + 8], m[p + 9]
	-- the target from the hip, in the frame of what the leg hangs on
	local dx = leg.tx - (fk.x[par] + r11 * leg.offX + r12 * leg.offY + r13 * leg.offZ)
	local dy = leg.ty - (fk.y[par] + r21 * leg.offX + r22 * leg.offY + r23 * leg.offZ)
	local dz = leg.tz - (fk.z[par] + r31 * leg.offX + r32 * leg.offY + r33 * leg.offZ)
	local lx = r11 * dx + r21 * dy + r31 * dz
	local ly = r12 * dx + r22 * dy + r32 * dz
	local lz = r13 * dx + r23 * dy + r33 * dz
	local d = sqrt(lx * lx + ly * ly + lz * lz)
	-- the knee: the bend that makes the leg as long as that
	local long, short = leg.long, leg.short
	local bend
	if d >= long then
		bend, leg.over = leg.kneeOpen, d - long
	elseif d <= short then
		bend, leg.over = leg.kneeShut, short - d
	else
		bend, leg.over = acos(clamp((d * d - leg.A2 - leg.B2) / leg.AB2, -1, 1)), 0
	end
	-- (a leg that stands on its point: the model has it bent `bend0` about the hinge's axis; through straight,
	-- and `bend` beyond)
	local theta = if leg.tiptoe then -(bend + leg.bend0) else bend - leg.bend0
	local c, s = cos(theta), sin(theta)
	local nx, ny, nz = leg.nx, leg.ny, leg.nz
	local k = 1 - c
	local b = leg.b
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local knee = b[2]
	rx[knee] = asin(clamp(nx * s - ny * nz * k, -1, 1))
	ry[knee] = atan2(nx * nz * k + ny * s, c + nz * nz * k)
	rz[knee] = atan2(ny * nx * k + nz * s, c + ny * ny * k)
	-- the leg from its hip to its point with that knee, the hip still at rest
	local vx = leg.ax + leg.bx * c + leg.cx * s
	local vy = leg.ay + leg.by * c + leg.cy * s
	local vz = leg.az + leg.bz * c + leg.cz * s
	if leg.tiptoe then
		-- the hip, the shortest way: about the axis across the leg as it lies and the way to its target, by the
		-- angle between the two
		local v = max(sqrt(vx * vx + vy * vy + vz * vz), 1e-9)
		vx, vy, vz = vx / v, vy / v, vz / v
		local l = max(d, 1e-9)
		lx, ly, lz = lx / l, ly / l, lz / l
		local ax, ay, az = vy * lz - vz * ly, vz * lx - vx * lz, vx * ly - vy * lx
		local across = sqrt(ax * ax + ay * ay + az * az)
		local hip = b[1]
		if across < 1e-9 then
			rx[hip], ry[hip], rz[hip] = 0, 0, 0
			return
		end
		ax, ay, az = ax / across, ay / across, az / across
		local angle = min(atan2(across, vx * lx + vy * ly + vz * lz), leg.swingMost)
		c, s = cos(angle), sin(angle)
		k = 1 - c
		rx[hip] = asin(clamp(ax * s - ay * az * k, -1, 1))
		ry[hip] = atan2(ax * az * k + ay * s, c + az * az * k)
		rz[hip] = atan2(ay * ax * k + az * s, c + ay * ay * k)
		return
	end
	-- the hip: the swing about the upright, and the lift
	local from = atan2(vx, vz)
	local swing = clamp(wrap(atan2(lx, lz) - from), -leg.swingMost, leg.swingMost)
	local lift =
		clamp(atan2(ly, sqrt(lx * lx + lz * lz)) - atan2(vy, sqrt(vx * vx + vz * vz)), -leg.liftMost, leg.liftMost)
	-- (the turn Ry(from + swing) x Rx(-lift) x Ry(-from), as the angles of a pose)
	local c1, s1 = cos(from + swing), sin(from + swing)
	local c2, s2 = cos(from), sin(from)
	local cd, sd = cos(lift), sin(lift)
	local hip = b[1]
	rx[hip] = asin(clamp(-sd * c2, -1, 1))
	ry[hip] = atan2(-c1 * s2 + s1 * cd * c2, s1 * s2 + c1 * cd * c2)
	rz[hip] = atan2(sd * s2, cd)
end

-- The root's rise and the trunk's pitch that put the fore hips `front` studs and the hind hips `hind`
-- studs over where they stand at rest. `zFront`, `zHind`, `zRoot`: where the two pairs and the root are
-- along the body. Returns bob, pitch (a positive pitch lifts the nose).
function Kit.carry(front, hind, zFront, zHind, zRoot)
	local pitch = (front - hind) / (zHind - zFront)
	return front + pitch * (zFront - zRoot), pitch
end

-- A head that is still, and looks ---------------------------------------------------------------------------
-- `gaze` is a head's own will: it holds perfectly still, and now and then it turns to look somewhere, in one
-- eased move with no overshoot, and holds that. `look`: { yaw, up, down (radians: how far it looks to a
-- side, up and down), turn (seconds a turn takes, whatever its size), least, mean, most (seconds it holds:
-- drawn with a long tail, and a long hold tends to follow a long one), home (the chance that a look is back
-- to straight ahead) }. `active` false: it comes back to straight ahead and stays (a creature that walks).
function Kit.newGaze()
	return {
		yaw = 0,
		pitch = 0,
		y0 = 0,
		p0 = 0,
		y1 = 0,
		p1 = 0,
		t0 = -100,
		next = 0,
		hold = 3,
		turning = 0,
		primed = false,
	}
end

function Kit.gaze(g, t, dice, look, active)
	if not g.primed then
		g.primed = true
		g.next = t + Kit.wait(dice, look.least, look.mean, look.most) * Kit.roll(dice)
	end
	local turn = look.turn
	if active then
		if t >= g.next then
			local yaw, pitch = 0, 0
			local off = abs(g.y1) > 0.05 or abs(g.p1) > 0.05
			if not off or Kit.roll(dice) > look.home then
				-- (somewhere else: not a twitch next to where it looks now)
				yaw = (0.3 + 0.7 * Kit.roll(dice)) * look.yaw * (if Kit.roll(dice) < 0.5 then -1 else 1)
				if abs(yaw - g.y1) < 0.3 * look.yaw then
					yaw = -yaw
				end
				pitch = -look.down + (look.up + look.down) * Kit.roll(dice)
			end
			g.y0, g.p0, g.y1, g.p1, g.t0 = g.yaw, g.pitch, yaw, pitch, t
			-- (it looks aside for a moment, and straight ahead for long)
			local aside = yaw ~= 0 or pitch ~= 0
			local hold = Kit.wait(dice, look.least, if aside then look.aside or look.mean else look.mean, look.most)
			hold = 0.4 * g.hold + 0.6 * hold
			g.hold = hold
			g.next = t + turn + hold
		end
	elseif g.y1 ~= 0 or g.p1 ~= 0 then
		g.y0, g.p0, g.y1, g.p1, g.t0 = g.yaw, g.pitch, 0, 0, t
		g.next = t + turn + look.least
	else
		g.next = max(g.next, t + look.least)
	end
	local u = ease((t - g.t0) / turn)
	g.yaw = g.y0 + (g.y1 - g.y0) * u
	g.pitch = g.p0 + (g.p1 - g.p0) * u
	g.turning = if t - g.t0 < turn then 1 else 0
	return g.yaw, g.pitch
end

-- Shares a turn out over a chain: bone `k` of `list` (places) takes `shares[k]` of it, added to what is there.
function Kit.spread(pose, list, shares, rx, ry, rz)
	local prx, pry, prz = pose.rx, pose.ry, pose.rz
	for k, i in list do
		local share = shares[k] or 0
		prx[i] += rx * share
		pry[i] += ry * share
		prz[i] += rz * share
	end
end

function Kit.zero(pose, list)
	local prx, pry, prz = pose.rx, pose.ry, pose.rz
	for _, i in list do
		prx[i], pry[i], prz[i] = 0, 0, 0
	end
end

-- A tail that follows ---------------------------------------------------------------------------------------
-- Every bone does what the one before it did, a little later and a little more (docs/MOTION.md, section 21).
-- `chainWave` adds to the bones of `list` one swing of the base that runs down the chain: bone k turns
-- `amount x gain^(k-1) x sin(phase - (k-1) x lag)` (radians; `lag` in radians of the swing a bone), no bone
-- more than `most`. `axis`: "y" (side to side), "x" (up and down) or "z" (about the body's length: a wing
-- that beats is a chain that waves about z, shoulder first).

-- The turns of a pose about one axis of the model.
local function about(pose, axis)
	return if axis == "y" then pose.ry elseif axis == "z" then pose.rz else pose.rx
end

function Kit.chainWave(pose, list, axis, amount, phase, lag, gain, most)
	local r = about(pose, axis)
	local a = amount
	for k, i in list do
		r[i] += clamp(a * sin(phase - (k - 1) * lag), -most, most)
		a *= gain
	end
end

-- The same for one event that starts at `t0` and lasts `length` seconds a bone: a swish that runs down the
-- tail, each bone `delay` seconds after the one before.
function Kit.chainPulse(pose, list, axis, amount, t, t0, length, delay, gain, most)
	local r = about(pose, axis)
	local a = amount
	for k, i in list do
		local u = (t - t0 - (k - 1) * delay) / length
		if u > 0 and u < 1 then
			-- (out to one side and back through the middle a little to the other: a swish, not a nod)
			r[i] += clamp(a * sin(TAU * u) * sin(pi * u), -most, most)
		end
		a *= gain
	end
end

-- One chain by keys ---------------------------------------------------------------------------------------------
-- A limb that is not solved but POSED: a wing folded or spread, a leg tucked or hanging, an arm held. Its poses
-- are KEYS, looked at on the mesh one at a time (tools\pose_look.ps1) and blended by weights that add up to 1.
-- A limb is a chain of named bones, body to tip, of the RIGHT side or (`left` true) its mirror image. A key is
-- the turn of each of its bones, first to last, written for the right side: { { rx, ry, rz }, { ... } }.
-- `key` adds `weight` of a key to the pose (mirrored for a left limb: rx, -ry, -rz). Zero the limb first
-- (`zero(pose, limb.bones)`). (Shared.BossKit hands these two on as `Boss.limb` and `Boss.key`.)
function Kit.limb(rig, names, left)
	local bones = {}
	for k, name in names do
		bones[k] = Kit.bone(rig, name)
	end
	return { bones = bones, mirror = if left then -1 else 1 }
end

function Kit.key(pose, limb, key, weight)
	if weight == 0 then
		return
	end
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local m = limb.mirror * weight
	for k, i in limb.bones do
		local turn = key[k]
		if turn then
			rx[i] += weight * turn[1]
			ry[i] += m * turn[2]
			rz[i] += m * turn[3]
		end
	end
end

-- A model of one part ----------------------------------------------------------------------------------------
-- A store model with no bones can only be moved as a whole (rig place 2 turns about the module's pivot, the
-- root rises and falls), so its motion is honest rigid-body motion and nothing else: no pretended steps, no
-- wag, no shake. Its way, with the module's own numbers:
--   `soar`   one that swims or flies: it follows a line that waves gently up and down as it goes, its nose
--            along the slope of that line, and banks into its turns
-- `glider(rig, seed)` is the state of it.
-- An animal WITH bones that flies or swims takes the same path and bank for its whole body: `soar` with the
-- place of the bone that carries everything (its root) as the last argument, and `glider({ length = .. }, seed)`.
function Kit.glider(rig, seed)
	return {
		rig = rig,
		wave = (seed or 0) * TAU,
		phase = (seed or 0),
		yaw = 0,
		w = 0,
		speed = 0,
		fresh = true,
		pitch = { x = 0, v = 0 },
		roll = { x = 0, v = 0 },
		surge = { x = 0, v = 0 },
	}
end

-- How fast it turns (rad/s, smoothed) and how fast it speeds up (studs/s^2, smoothed), from what it is told.
local function drift(G, dt, input)
	if G.fresh or input.jump or dt <= 0 or dt > 0.4 then
		G.fresh, G.w, G.yaw, G.speed, G.push = false, 0, input.yaw, input.speed, 0
		return 0
	end
	local k = 1 - exp(-6 * dt)
	G.w += (wrap(input.yaw - G.yaw) / dt - G.w) * k
	G.push = (G.push or 0) + ((input.speed - G.speed) / dt - (G.push or 0)) * k
	G.yaw, G.speed = input.yaw, input.speed
	return dt
end

-- `spec`: { wave (how high the line waves, a share of its length), every (body lengths between two rises),
-- steep (radians its nose tips at most), bank (radians it rolls for a turn of one radian a second), most
-- (radians it rolls at most), quick (how fast it follows, 1/s) }. Returns how much it is going, 0 to 1.
-- `place`: the bone that is tipped and banked (left out: 2, the part of a model of one part).
function Kit.soar(G, pose, dt, input, spec, place)
	dt = drift(G, dt, input)
	local length = G.rig.length
	local v = input.speed
	local go = smooth(v / (0.2 * length))
	G.wave += TAU * v * dt / (spec.every * length)
	local air = input.air or 1
	-- (the slope of the line it follows: what the wave adds, and how its layer rises or sinks)
	local slope = spec.wave * TAU / spec.every * cos(G.wave) * go + (input.climb or 0) / max(v, 0.3 * length)
	local quick = spec.quick or 4
	local pitch = Kit.spring(G.pitch, clamp(math.atan(slope), -spec.steep, spec.steep) * air, quick, 1, dt)
	local roll = Kit.spring(G.roll, clamp(spec.bank * G.w, -spec.most, spec.most) * air, quick * 0.75, 0.9, dt)
	pose.bob, pose.ox, pose.oz = spec.wave * length * sin(G.wave) * air, 0, 0
	local i = place or 2
	pose.rx[i], pose.ry[i], pose.rz[i] = pitch, 0, roll
	return go
end

-- A constant turn shared along a chain with a gain (a tail that lifts, a tail that leans away from a turn).
function Kit.chainBend(pose, list, axis, amount, gain)
	local r = about(pose, axis)
	local a = amount
	for _, i in list do
		r[i] += a
		a *= gain
	end
end

-- A body that lies on the ground and is LAID OUT (a snake, a wyrm; written for the Cobra) -------------------
-- A serpent's body was modelled in some curl. To go, it is laid out behind its front and waved; the chain
-- functions above add turns about ONE axis of the model and cannot do that: a piece that already heads aside
-- and is then turned about the upright does not stay on the ground. `lay` gives every piece of a chain the
-- DIRECTION it shall have in the model, whatever the pieces before it do.
--   `sense(s, dt, input, pace)`    what the pivot is doing: how fast it turns (`s.w`, rad/s to its left) and how
--                                  far it WENT along the way it looks since the last frame (studs): a wave on
--                                  the ground is driven by the way gone, not by a clock, so a snake that stands
--                                  does not wiggle. `s`: any table that starts with `fresh = true` (the
--                                  animal's own state will do: it keeps `w`, `yaw`, `x`, `z` in it); `pace`:
--                                  the speed it strolls at. Returns the time that may be played (none when it
--                                  was put somewhere else or not moved for long) and that way
--   `pieces(rig, list, count)`     the first `count` bones of a chain (places, base first: `Kit.chain`) as
--                                  pieces, each a bone and the stretch of body from it to the next: { bone,
--                                  length, dx, dy, dz (the way it runs at rest), from (studs of body before
--                                  it), heading (radians it heads off straight back at rest, to its right),
--                                  rest (the frame that looks along it at rest, undone), rise, level (the
--                                  slope it has when laid out, as sine and cosine: flat until the module says
--                                  otherwise) }; and how long they are together
--   `swell(pieces, long, full)`    how much of a wave each piece has, by where its middle lies: nothing at the
--                                  base, all of it from the share `full` of the way on (`arc`, `grow`, `slope`)
--   `wave(pieces, heads, at, turns, size)`   the heading of a wave at every piece, into `heads`: the body swings
--                                  `size` studs to each side, `turns` radians of the wave a stud of GROUND, `at`
--                                  radians gone by. It is counted where the middle of a piece lies ON THE
--                                  GROUND behind the base, not along the body: a piece that heads aside covers
--                                  less of the way, and a wave counted along the body would creep
--   `lay(pose, pieces, heads, share)`   turns every bone so that its piece has gone `share` of the way from
--                                  how it lies at rest to the heading `heads[k]` and its laid-out slope. No
--                                  piece is twisted about its own length. The first bone must hang on a bone
--                                  that is not turned.
function Kit.sense(s, dt, input, pace)
	if s.fresh or input.jump or dt <= 0 or dt > 0.4 then
		s.fresh, s.w, s.yaw, s.x, s.z = false, 0, input.yaw, input.x, input.z
		return 0, 0
	end
	s.w += (wrap(input.yaw - s.yaw) / dt - s.w) * (1 - exp(-6 * dt))
	local gone = -(input.x - s.x) * sin(input.yaw) - (input.z - s.z) * cos(input.yaw)
	s.yaw, s.x, s.z = input.yaw, input.x, input.z
	-- (a move no walk makes is not a way gone: it was put somewhere else and nobody said so)
	if gone < 0 or gone > 4 * (input.speed + pace) * dt then
		gone = input.speed * dt
	end
	return dt, gone
end

function Kit.pieces(rig, list, count)
	local px, py, pz = rig.px, rig.py, rig.pz
	local pieces, long = {}, 0
	for k = 1, count do
		local a, b = list[k], list[k + 1]
		local x, y, z = px[b] - px[a], py[b] - py[a], pz[b] - pz[a]
		local length = sqrt(x * x + y * y + z * z)
		pieces[k] = { bone = a, length = length, dx = x / length, dy = y / length, dz = z / length, from = long }
		long += length
	end
	for _, piece in pieces do
		-- the frame that looks along it at rest, undone (its transpose)
		local h, p = atan2(piece.dx, piece.dz), asin(piece.dy)
		local ch, sh, cq, sq = cos(h), sin(h), cos(p), sin(p)
		piece.rest = { ch, 0, -sh, -sh * sq, cq, -ch * sq, sh * cq, sq, ch * cq }
		piece.heading = h
		piece.rise, piece.level = 0, 1
	end
	return pieces, long
end

-- Set a laid-out chain's slope and heading, and return where its last joint lies (x, z).
-- Without thick(u), keep each piece's slope and share the swing into line over the first keep joints,
-- straight being the share laid out. With thick(u), lay down on that taper and retain diminishing headings.
function Kit.layout(pieces, long, x, z, keep, straight, thick)
	local swing = pieces[keep].heading
	for k, piece in pieces do
		if thick then
			local rise = (thick((piece.from + piece.length) / long) - thick(piece.from / long)) / piece.length
			piece.rise = clamp(rise, -0.9, 0.9)
			piece.level = sqrt(1 - piece.rise * piece.rise)
			piece.keep = piece.heading * max(0, 1 - k / keep)
		else
			piece.rise = piece.dy
			piece.level = sqrt(1 - piece.dy * piece.dy)
			local laid = if k < keep then piece.heading - swing * k / keep else 0
			piece.keep = piece.heading + (laid - piece.heading) * straight
		end
		x += piece.length * piece.level * sin(piece.keep)
		z += piece.length * piece.level * cos(piece.keep)
	end
	return x, z
end

-- Where the wave grows, a piece heads off by up to 1.5 x WAVE / WAVE_FULL radians besides its full wave.
function Kit.swell(pieces, long, full)
	for _, piece in pieces do
		local middle = piece.from + piece.length / 2
		local u = middle / long
		local share = clamp(u / full, 0, 1)
		piece.arc = middle
		piece.grow = share * share * (3 - 2 * share)
		piece.slope = 6 * share * (1 - share) / (full * long)
	end
end

function Kit.wave(pieces, heads, at, turns, size)
	local behind, level = 0, 1
	for k, piece in pieces do
		local here = at - turns * (behind + 0.5 * piece.length * level)
		local wave = math.atan(size * (piece.slope * sin(here) - piece.grow * turns * cos(here)))
		level = cos(wave)
		behind += piece.length * level
		heads[k] = wave
	end
end

function Kit.lay(pose, pieces, heads, share)
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	-- (how the piece before is turned in the model: rows first)
	local p11, p12, p13, p21, p22, p23, p31, p32, p33 = 1, 0, 0, 0, 1, 0, 0, 0, 1
	for k, piece in pieces do
		-- the direction: from rest towards laid out
		local cp = piece.level
		local x = piece.dx + (sin(heads[k]) * cp - piece.dx) * share
		local y = piece.dy + (piece.rise - piece.dy) * share
		local z = piece.dz + (cos(heads[k]) * cp - piece.dz) * share
		local length = sqrt(x * x + y * y + z * z)
		y = clamp(y / length, -1, 1)
		local h, p = atan2(x, z), asin(y)
		-- the frame that looks along it with no roll (a turn to the side, then a tip), times the same frame of
		-- the piece at rest undone
		local ch, sh, cq, sq = cos(h), sin(h), cos(p), sin(p)
		local q11, q12, q13 = ch, -sh * sq, sh * cq
		local q22, q23 = cq, sq
		local q31, q32, q33 = -sh, -ch * sq, ch * cq
		local a = piece.rest
		local c11 = q11 * a[1] + q12 * a[4] + q13 * a[7]
		local c12 = q11 * a[2] + q12 * a[5] + q13 * a[8]
		local c13 = q11 * a[3] + q12 * a[6] + q13 * a[9]
		local c21 = q22 * a[4] + q23 * a[7]
		local c22 = q22 * a[5] + q23 * a[8]
		local c23 = q22 * a[6] + q23 * a[9]
		local c31 = q31 * a[1] + q32 * a[4] + q33 * a[7]
		local c32 = q31 * a[2] + q32 * a[5] + q33 * a[8]
		local c33 = q31 * a[3] + q32 * a[6] + q33 * a[9]
		-- what this bone turns by itself: that, seen from the piece before (R = Ry x Rx x Rz)
		local m13 = p11 * c13 + p21 * c23 + p31 * c33
		local m21 = p12 * c11 + p22 * c21 + p32 * c31
		local m22 = p12 * c12 + p22 * c22 + p32 * c32
		local m23 = p12 * c13 + p22 * c23 + p32 * c33
		local m33 = p13 * c13 + p23 * c23 + p33 * c33
		local bone = piece.bone
		rx[bone] = asin(clamp(-m23, -1, 1))
		ry[bone] = atan2(m13, m33)
		rz[bone] = atan2(m21, m22)
		p11, p12, p13, p21, p22, p23, p31, p32, p33 = c11, c12, c13, c21, c22, c23, c31, c32, c33
	end
end

-- KEYS MADE IN BLENDER --------------------------------------------------------------------------------------
-- A creature's motion keyed on its own armature in Blender (tools\anim_blender.ps1: a reference run copied frame by
-- frame, tools/blender/ref_retarget.py, or the owner's own keys) and read back by tools/blender/anim_take.py into a
-- shared module (`src/shared/<Art>GallopAnim.luau`): `frames` keys a loop, `phase0` the walker's moment of its stride
-- at key 1, `stride` legs a stride (the paws' own), `quats[bone] = { w, x, y, z }` lists (each bone's turn against
-- its parent about the model's axes), `offset = { x, y, z }` lists (the root's place from rest, studs).

-- A loop of values at the moment `u` (0 to 1) of it, on a curve through them (Catmull-Rom).
function Kit.curveAt(values, u)
	local n = #values
	local x = (u % 1) * n
	local i = floor(x)
	local f = x - i
	local p0, p1 = values[(i - 1) % n + 1], values[i % n + 1]
	local p2, p3 = values[(i + 1) % n + 1], values[(i + 2) % n + 1]
	return p1 + 0.5 * f * (p2 - p0 + f * (2 * p0 - 5 * p1 + 4 * p2 - p3 + f * (3 * (p1 - p2) + p3 - p0)))
end

-- The angles of CFrame.fromEulerAnglesYXZ (Ry * Rx * Rz) of a turn given as a quaternion (not of unit length: it
-- is made so). Every turn has two sets of angles, a pitch past a right angle (an elbow folded far) being
-- (pi - x, y + pi, z + pi) as well as (x, y, z): the one nearest to (nx, ny, nz), the angles of the frame before, so
-- that they never leap; with none, the one that turns least about the other two axes (the gallop's joints only
-- pitch)
function Kit.keyAngles(qw, qx, qy, qz, nx: number?, ny: number?, nz: number?)
	local m = sqrt(qw * qw + qx * qx + qy * qy + qz * qz)
	if m < 1e-9 then
		return 0, 0, 0
	end
	qw, qx, qy, qz = qw / m, qx / m, qy / m, qz / m
	local m02 = 2 * (qx * qz + qw * qy)
	local m12 = 2 * (qy * qz - qw * qx)
	local m22 = 1 - 2 * (qx * qx + qy * qy)
	local m10 = 2 * (qx * qy + qw * qz)
	local m11 = 1 - 2 * (qx * qx + qz * qz)
	local x = asin(clamp(-m12, -1, 1))
	local y, z = atan2(m02, m22), atan2(m10, m11)
	if not (nx and ny and nz) then
		local by, bz = (y + TAU) % TAU - pi, (z + TAU) % TAU - pi -- (y + pi and z + pi, within a half turn)
		if abs(by) + abs(bz) < abs(y) + abs(z) then
			return pi - x, by, bz
		end
		return x, y, z
	end
	local function near(a, b)
		return a + TAU * floor((b - a) / TAU + 0.5)
	end
	local ax, ay, az = near(x, nx), near(y, ny), near(z, nz)
	local bx, by, bz = near(pi - x, nx), near(y + pi, ny), near(z + pi, nz)
	local da = (ax - nx) ^ 2 + (ay - ny) ^ 2 + (az - nz) ^ 2
	local db = (bx - nx) ^ 2 + (by - ny) ^ 2 + (bz - nz) ^ 2
	if db < da then
		return bx, by, bz
	end
	return ax, ay, az
end

-- The keys at the walker's moment `phase` of its stride put on the pose by the share `w` (1: the keys alone): every
-- bone the keys name and the rig has, and the root's place (`landing`, the crouch of a landing, kept under it). The
-- keys are read between frames as quaternions and only then made angles, each bone's the set nearest to its angles
-- of the frame before (kept in `S.keyAngles`): a joint folded past a right angle never twists.
function Kit.playKeys(S, keys, phase, w, landing)
	local pose, rigAt = S.pose, S.rig.at
	local rx, ry, rz = pose.rx, pose.ry, pose.rz
	local at = (phase - keys.phase0) % 1
	local last = S.keyAngles or {}
	S.keyAngles = last
	for name, lists in keys.quats do
		local i = rigAt[name]
		if i then
			local before = last[i]
			local x, y, z = Kit.keyAngles(
				Kit.curveAt(lists[1], at),
				Kit.curveAt(lists[2], at),
				Kit.curveAt(lists[3], at),
				Kit.curveAt(lists[4], at),
				before and before[1],
				before and before[2],
				before and before[3]
			)
			last[i] = { x, y, z }
			rx[i] += (x - rx[i]) * w
			ry[i] += (y - ry[i]) * w
			rz[i] += (z - rz[i]) * w
		end
	end
	local offset = keys.offset
	pose.ox += (Kit.curveAt(offset[1], at) - pose.ox) * w
	pose.bob += (Kit.curveAt(offset[2], at) - (landing or 0) - pose.bob) * w
	pose.oz += (Kit.curveAt(offset[3], at) - pose.oz) * w
end

return Kit
