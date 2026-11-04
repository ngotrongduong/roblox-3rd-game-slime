--!strict
-- Where everything of the Slime Dungeon's Sunny Meadow stands (the owner's painting, battle.map.meadow.png; numbers in
-- Config.Dungeon.Arena). Pure: the same plan every time, flat studs from the arena's middle (x, z; yaw turns about Y), so a
-- test can prove the fight's centre is clear, the four path mouths are open and nothing overlaps. server/DungeonArena turns
-- the plan into parts and kit models.
--
-- The painting: a round bright clearing; four dirt paths on the four axes that fade out before the middle; round trees in the
-- four corners; pines beside the left and right paths; rocks (single and in pairs), flower clumps and bushes round the rim,
-- thickest at the corners; a few tiny flowers in the open middle.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

local A = Config.Dungeon.Arena
local DEG = math.pi / 180
local HALF_PI = math.pi / 2

-- One kit model to stand: its kind (a key of Config.Dungeon.Arena.Models), the model picked, where, how big (the height of a
-- tree or tuft, the width when `wide`), a tint (hex) when the kind wears one, and the group it belongs to (a clump is several
-- models) with the group's middle and footprint radius.
type Item = {
	kind: string,
	model: string,
	zone: string, -- "rim" | "backdrop" | "tiny"
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

local ArenaPlan = {}

local function models(kind: string): { string }
	return (A.Models :: any)[kind]
end

local function tints(kind: string): { string }?
	return (A.Tints :: any)[kind]
end

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

-- Everything that stands on the meadow, in the order it was placed.
function ArenaPlan.build(): { Item }
	local rng = Rng.new(A.Seed)
	local items: { Item } = {}
	local placed: { { x: number, z: number, foot: number } } = {}
	local groups = 0

	local function between(range: { number }): number
		return range[1] + rng:next() * (range[2] - range[1])
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
			local list = tints(kind)
			table.insert(items, {
				kind = kind,
				model = rng:pick(models(kind)),
				zone = zone,
				x = at_x,
				z = at_z,
				yaw = rng:next() * math.pi * 2,
				size = size,
				wide = wide,
				tint = if list then rng:pick(list) else nil,
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
	local function cornerTrees(zone: string, count: number, spread: number, rIn: number, rOut: number)
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

	-- 2. Per corner: rock pairs, single rocks (each in a tuft of grass), bushes, flower clumps.
	local each = A.PerCorner
	local spread = 42 * DEG
	for q = 0, 3 do
		local centre = (q + 0.5) * HALF_PI
		for _ = 1, each.RockPairs do
			local foot = 7
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				local turn = rng:next() * math.pi
				local ux, uz = math.cos(turn), math.sin(turn)
				add("rock", x - ux * 2.2, z - uz * 2.2, between(A.RockBig), true)
				add("rock", x + ux * 3.2, z + uz * 3.2, between(A.RockSmall), true)
				add("tuft", x - uz * 3.4, z + ux * 3.4, between(A.Tuft), false)
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
			local foot = 4.2
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				local turn = rng:next() * math.pi
				local ux, uz = math.cos(turn), math.sin(turn)
				local flowers = rng:int(2, 3)
				for k = 1, flowers do
					local along = (k - (flowers + 1) / 2) * 2.2
					add("flower", x + ux * along, z + uz * along, between(A.Flower), true)
				end
				add("tuft", x - uz * 1.6, z + ux * 1.6, between(A.Tuft), false)
			end
		end
	end

	-- the corners' other trees stand just behind the rim's flowers and rocks, part of the far ring
	cornerTrees("backdrop", A.PerCorner.Trees - 1, 30 * DEG, A.RimOuter - 8, A.BackdropInner + 14)

	-- 3. The tiny flowers, tufts and pebbles of the open middle band, clear of the fight's centre and of the paths.
	local tinyFoot = (A.TinyApart - A.Gap) / 2
	local function tiny(kind: string, range: { number }, wide: boolean, count: number)
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
	tiny("flower", A.TinyFlower, true, A.TinyFlowers)
	tiny("tuft", A.TinyTuft, false, A.TinyTufts)
	tiny("pebble", A.TinyPebble, true, A.TinyPebbles)

	-- 4. The far ring of trees, taller than the rim's, round the whole circle but the four path mouths: it hides the floor's edge
	-- from the player's camera.
	local count = A.BackdropCount
	for k = 1, count do
		local angle = (k - 0.5 + (rng:next() - 0.5) * 0.4) / count * math.pi * 2
		local pine = k % 2 == 1
		local size = between(if pine then A.BackdropPine else A.BackdropRound)
		local foot = size * (if pine then 0.33 else 0.3)
		local r = A.BackdropInner + foot * 0.5 + rng:next() * (A.BackdropOuter - A.BackdropInner)
		local x, z = math.cos(angle) * r, math.sin(angle) * r
		if ArenaPlan.lateral(x, z) >= A.MouthHalf + foot and free(x, z, foot) then
			group("backdrop", x, z, foot)(if pine then "pine" else "round", x, z, size, false)
		end
	end

	-- ...and a row of big bushes just behind the far trees, so no sky shows between their trunks.
	for k = 1, A.BackdropBushes do
		local angle = (k - 0.5 + (rng:next() - 0.5) * 0.6) / A.BackdropBushes * math.pi * 2
		local size = between(A.BackdropBush)
		local foot = size / 2
		local r = A.BackdropOuter + foot * 0.5 + rng:next() * A.BushRowDepth
		local x, z = math.cos(angle) * r, math.sin(angle) * r
		if ArenaPlan.lateral(x, z) >= A.MouthHalf + foot and free(x, z, foot) then
			group("backdrop", x, z, foot)("bush", x, z, size, true)
		end
	end

	-- 5. Past each path's outer end, a pair of trees closes the view, so a path runs off into the woods, never into the sky.
	for q = 0, 3 do
		local axis = q * HALF_PI
		local ax, az = math.cos(axis), math.sin(axis)
		for _, side in { -1, 1 } do
			local size = between(A.BackdropRound)
			local foot = size * 0.3
			local r = A.PathOuter + foot + A.MouthBehind
			local x, z = ax * r - az * side * A.MouthTreeApart, az * r + ax * side * A.MouthTreeApart
			if free(x, z, foot) then
				group("mouth", x, z, foot)("round", x, z, size, false)
			end
		end
	end

	return items
end

return ArenaPlan
