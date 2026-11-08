--!strict
-- Where everything of the Slime Dungeon's Sunny Meadow stands (the owner's painting, battle.map.meadow.png; numbers in
-- Config.Dungeon.Arena). Pure: the same plan every time, flat studs from the arena's middle (x, z; yaw turns about Y), so a
-- test can prove the fight's centre is clear, the four path mouths are open and nothing overlaps. server/DungeonArena turns
-- the plan into parts and models.
--
-- The painting: a round bright clearing; four dirt paths on the four axes that fade out before the middle; round trees in the
-- four corners; pines beside the left and right paths; rocks (single and in pairs), flower clumps, bushes, a stump and a log
-- round the rim, thickest at the corners; a few tiny flowers in the open middle. Not in the painting but needed by the game's
-- camera (it sits at the rim and looks across): two rows of woods behind the rim, a row of big bushes, a ring of hills.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

local A = Config.Dungeon.Arena
local DEG = math.pi / 180
local HALF_PI = math.pi / 2

-- One model to stand: its kind (a key of Config.Dungeon.Arena.Models), the model picked, where, how big (the height of a
-- tree, tuft or flower clump, the width when `wide`), a tint (hex) when the kind wears one, and the group it belongs to (a
-- clump is several models) with the group's middle and footprint radius.
type Item = {
	kind: string,
	model: string,
	zone: string, -- "rim" | "backdrop" | "tiny" | "mouth"
	x: number,
	z: number,
	yaw: number,
	size: number,
	wide: boolean,
	tint: string?,
	group: number,
	gx: number,
	gz: number,
	foot: number,
}

-- One flat block of a dirt path: its middle, how long (along its axis) and wide it is, its yaw, how far it fades toward the
-- grass (0 = full dirt), and its number along the path from the outside in (1 = outermost, to lift by).
type Segment = {
	axis: number,
	index: number,
	x: number,
	z: number,
	length: number,
	width: number,
	yaw: number,
	fade: number,
}

-- One hill of the far horizon: a flattened ball of grass, its middle, its width and its height (a part of it sinks under the
-- floor).
type Hill = { x: number, z: number, wide: number, tall: number }

local ArenaPlan = {}

-- How far a point is from the nearest of the four axes (the paths' middle lines).
function ArenaPlan.lateral(x: number, z: number): number
	return math.min(math.abs(x), math.abs(z))
end

-- Half the width of a path at `radius` from the middle.
function ArenaPlan.pathHalf(radius: number): number
	local t = math.clamp((radius - A.PathInner) / (A.PathOuter - A.PathInner), 0, 1)
	return (A.PathWidthInner + (A.PathWidthOuter - A.PathWidthInner) * t) / 2
end

-- The blocks of the four paths.
function ArenaPlan.paths(): { Segment }
	local out: { Segment } = {}
	local count = A.PathSegments
	local span = A.PathOuter - A.PathInner
	for axis = 0, 3 do
		local a = axis * HALF_PI
		local ux, uz = math.cos(a), math.sin(a)
		for k = 1, count do
			local t0, t1 = (k - 1) / count, k / count
			local r0, r1 = A.PathOuter - span * t0, A.PathOuter - span * t1
			local mid, tm = (r0 + r1) / 2, (t0 + t1) / 2
			-- a gentle drift off the line and a small turn, so the path is not a ruler's line
			local side = A.PathWobble * math.sin(k * 1.9 + axis * 2.3)
			table.insert(out, {
				axis = axis,
				index = k,
				x = ux * mid - uz * side,
				z = uz * mid + ux * side,
				length = (r0 - r1) + 2,
				width = A.PathWidthOuter + (A.PathWidthInner - A.PathWidthOuter) * tm,
				yaw = HALF_PI - a + 0.06 * math.sin(k * 2.7 + axis),
				fade = A.PathFade * tm * tm,
			})
		end
	end
	return out
end

-- The ring of hills behind the woods, round the whole circle (a path runs off into the woods and a hill, never into the sky).
function ArenaPlan.hills(): { Hill }
	local H = A.Hills
	local rng = Rng.new(A.Seed + 7)
	local out: { Hill } = {}
	for k = 1, H.Count do
		local angle = (k - 0.5 + (rng:next() - 0.5) * 0.5) / H.Count * math.pi * 2
		local r = H.Radius + (rng:next() - 0.5) * 2 * H.Jitter
		table.insert(out, {
			x = math.cos(angle) * r,
			z = math.sin(angle) * r,
			wide = H.Wide[1] + rng:next() * (H.Wide[2] - H.Wide[1]),
			tall = H.Tall[1] + rng:next() * (H.Tall[2] - H.Tall[1]),
		})
	end
	return out
end

-- Everything that stands on the meadow, in the order it was placed. `names` is the model list of each kind (default
-- Config.Dungeon.Arena.Models); a kind with no list or an empty one is left out.
function ArenaPlan.build(names: { [string]: { string } }?): { Item }
	local list: { [string]: { string } } = names or (A.Models :: any)
	local rng = Rng.new(A.Seed)
	local items: { Item } = {}
	local placed: { { x: number, z: number, foot: number } } = {}
	local groups = 0

	local function between(range: { number }): number
		return range[1] + rng:next() * (range[2] - range[1])
	end

	local function has(kind: string): boolean
		local models = list[kind]
		return models ~= nil and #models > 0
	end

	-- Is there room for a footprint of `foot` at (x, z) beside everything placed?
	local function free(x: number, z: number, foot: number): boolean
		for _, other in placed do
			local need = other.foot + foot + A.Gap
			local dx, dz = other.x - x, other.z - z
			if dx * dx + dz * dz < need * need then
				return false
			end
		end
		return true
	end

	-- A group: its footprint is claimed, and its models are added to it.
	local function group(zone: string, x: number, z: number, foot: number)
		groups += 1
		table.insert(placed, { x = x, z = z, foot = foot })
		local id = groups
		return function(kind: string, at_x: number, at_z: number, size: number, wide: boolean)
			if not has(kind) then
				return
			end
			local tints = (A.Tints :: any)[kind]
			table.insert(items, {
				kind = kind,
				model = rng:pick(list[kind]),
				zone = zone,
				x = at_x,
				z = at_z,
				yaw = rng:next() * math.pi * 2,
				size = size,
				wide = wide,
				tint = if tints then rng:pick(tints) else nil,
				group = id,
				gx = x,
				gz = z,
				foot = foot,
			})
		end
	end

	-- A spot for a footprint in the rim band round `centre` (radians): angles are drawn triangular, so the corner of a quadrant
	-- gets the most, as in the painting; a spot that closes a path mouth or sits on another piece is drawn again.
	local function spot(centre: number, spread: number, foot: number, rIn: number, rOut: number): (number?, number?)
		for _ = 1, A.Tries do
			local angle = centre + (rng:next() - rng:next()) * spread
			local r = rIn + foot + rng:next() * math.max(rOut - rIn - 2 * foot, 0)
			local x, z = math.cos(angle) * r, math.sin(angle) * r
			if ArenaPlan.lateral(x, z) >= A.MouthHalf + foot and free(x, z, foot) then
				return x, z
			end
		end
		return nil, nil
	end

	local function tuftBeside(add: (string, number, number, number, boolean) -> (), x: number, z: number, away: number)
		local angle = rng:next() * math.pi * 2
		add("tuft", x + math.cos(angle) * away, z + math.sin(angle) * away, between(A.Tuft), false)
	end

	-- 1. The two pines beside the left and right paths (first: their spots are narrow), then the first round tree in each
	-- corner; the corners' other trees (the painting packs two or three together) come after the rocks and flowers.
	if has("pine") then
		for _, axis in { 0, 180 } do
			for _, side in { -1, 1 } do
				local size = between(A.Pine)
				local foot = size * 0.33
				local x, z = spot((axis + side * 23) * DEG, 5 * DEG, foot, A.RimInner + 3, A.RimOuter + 2)
				if x and z then
					group("rim", x, z, foot)("pine", x, z, size, false)
				end
			end
		end
	end
	local function cornerTrees(zone: string, count: number, spread: number, rIn: number, rOut: number)
		if not has("round") then
			return
		end
		for q = 0, 3 do
			for _ = 1, count do
				local size = between(A.Round)
				local foot = size * 0.3
				local x, z = spot((q + 0.5) * HALF_PI, spread, foot, rIn, rOut)
				if x and z then
					group(zone, x, z, foot)("round", x, z, size, false)
				end
			end
		end
	end
	cornerTrees("rim", 1, 5 * DEG, A.RimInner + 3, A.RimOuter + 2)

	-- 2. Per corner: rock pairs, single rocks (each in a tuft of grass), bushes, flower clumps, a stump and a log.
	local each = A.PerCorner
	local spread = 42 * DEG
	for q = 0, 3 do
		local centre = (q + 0.5) * HALF_PI
		for _ = 1, each.RockPairs do
			local foot = 9
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				local turn = rng:next() * math.pi
				local ux, uz = math.cos(turn), math.sin(turn)
				add("rock", x - ux * 2.8, z - uz * 2.8, between(A.RockBig), true)
				add("rock", x + ux * 4.2, z + uz * 4.2, between(A.RockSmall), true)
				add("tuft", x - uz * 4.4, z + ux * 4.4, between(A.Tuft), false)
			end
		end
		for _ = 1, each.Logs do
			local size = between(A.Log)
			local foot = size * 0.35
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				group("rim", x, z, foot)("log", x, z, size, true)
			end
		end
		for _ = 1, each.Stumps do
			local size = between(A.Stump)
			local foot = size / 2 + 0.6
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				add("stump", x, z, size, true)
				tuftBeside(add, x, z, size * 0.5 + 0.4)
			end
		end
		for _ = 1, each.Rocks do
			local size = between(A.RockSingle)
			local foot = size / 2 + 1.5
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				add("rock", x, z, size, true)
				tuftBeside(add, x, z, size * 0.5 + 0.4)
			end
		end
		for _ = 1, each.Bushes do
			local size = between(A.Bush)
			local foot = size / 2 + 0.3
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				group("rim", x, z, foot)("bush", x, z, size, true)
			end
		end
		for _ = 1, each.Clumps do
			-- two or three flower groups in a short row, with a tuft of grass beside them
			local foot = 3.6
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				local turn = rng:next() * math.pi
				local ux, uz = math.cos(turn), math.sin(turn)
				local flowers = rng:int(2, 3)
				for k = 1, flowers do
					local along = (k - (flowers + 1) / 2) * 2.2
					add("flower", x + ux * along, z + uz * along, between(A.Flower), false)
				end
				add("tuft", x - uz * 1.6, z + ux * 1.6, between(A.Tuft), false)
			end
		end
	end

	-- the corners' other trees stand just behind the rim's flowers and rocks, part of the far woods
	cornerTrees("backdrop", A.PerCorner.Trees - 1, 30 * DEG, A.RimOuter - 8, A.BackdropInner + 14)

	-- 3. The tiny flowers, tufts and pebbles of the open middle band, clear of the fight's centre and of the paths.
	local tinyFoot = (A.TinyApart - A.Gap) / 2
	local function tiny(kind: string, range: { number }, wide: boolean, count: number)
		if not has(kind) then
			return
		end
		for _ = 1, count do
			for _ = 1, A.Tries do
				local angle = rng:next() * math.pi * 2
				local r = A.TinyFrom + rng:next() * (A.TinyTo - A.TinyFrom)
				local x, z = math.cos(angle) * r, math.sin(angle) * r
				if ArenaPlan.lateral(x, z) >= ArenaPlan.pathHalf(r) + A.PathWobble + 2 and free(x, z, tinyFoot) then
					group("tiny", x, z, tinyFoot)(kind, x, z, between(range), wide)
					break
				end
			end
		end
	end
	tiny("flower", A.TinyFlower, false, A.TinyFlowers)
	tiny("tuft", A.TinyTuft, false, A.TinyTufts)
	tiny("pebble", A.TinyPebble, true, A.TinyPebbles)

	-- 4a. Past each path's outer end, a pair of trees closes the view, so a path runs off into the woods, never into the sky.
	if has("round") then
		for q = 0, 3 do
			local axis = q * HALF_PI
			local ax, az = math.cos(axis), math.sin(axis)
			for _, side in { -1, 1 } do
				local size = between(A.BackdropRound)
				local foot = size * 0.2
				local r = A.PathOuter + foot + A.MouthBehind
				local x, z = ax * r - az * side * A.MouthTreeApart, az * r + ax * side * A.MouthTreeApart
				if free(x, z, foot) then
					group("mouth", x, z, foot)("round", x, z, size, false)
				end
			end
		end
	end

	-- 4b. The woods behind: rows of trees round the whole circle but the four path mouths, taller toward the back, their trunks
	-- close but their crowns overlapping: they hide the floor's edge from the player's camera.
	for _, row in A.BackdropRows do
		for k = 1, row.count do
			local angle = (k - 0.5 + (rng:next() - 0.5) * 0.6) / row.count * math.pi * 2
			local pine = has("pine") and (not has("round") or rng:next() < A.BackdropPine)
			local kind = if pine then "pine" else "round"
			if has(kind) then
				local size = between(row.tall)
				local foot = size * A.BackdropFoot
				for _ = 1, 8 do
					local r = row.from + rng:next() * (row.to - row.from)
					local x, z = math.cos(angle) * r, math.sin(angle) * r
					if ArenaPlan.lateral(x, z) >= A.MouthHalf + foot and free(x, z, foot) then
						group("backdrop", x, z, foot)(kind, x, z, size, false)
						break
					end
				end
			end
		end
	end

	-- ...and a row of big bushes just behind the far trees, so no sky shows between their trunks.
	for k = 1, A.BackdropBushes do
		local angle = (k - 0.5 + (rng:next() - 0.5) * 0.6) / A.BackdropBushes * math.pi * 2
		local size = between(A.BackdropBush)
		local foot = size / 3
		local r = A.BackdropOuter + foot + rng:next() * A.BushRowDepth
		local x, z = math.cos(angle) * r, math.sin(angle) * r
		if ArenaPlan.lateral(x, z) >= A.MouthHalf + foot and free(x, z, foot) then
			group("backdrop", x, z, foot)("bush", x, z, size, true)
		end
	end

	return items
end

return ArenaPlan
