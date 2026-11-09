--!strict
-- Where everything of a Slime Dungeon map stands (the owner's paintings, battle.map.meadow.png and battle.map.mushroom.png;
-- numbers in Config.Dungeon.Arenas.<map>, the Meadow's when no map is named). Pure: the same plan every time, flat studs from
-- the arena's middle (x, z; yaw turns about Y), so a test can prove the fight's centre is clear, the four path mouths are open
-- and nothing overlaps. server/DungeonArena turns the plan into parts and models. The Mushroom Grove is the same ring plan
-- with ruins, roots, glowing clusters, flagstones (`stones`) and rune circles (`runes`) besides. Ember Lava (its painting,
-- battle.map.lava.png) is the ring again with no path drawn (the lanes stay open), basalt for the trees, and lava: pools
-- at the rim that carry the map's few lights, and flat veins that run to the corners, bigger and so thicker toward them.
--
-- The Meadow's painting: a round bright clearing; four dirt paths on the four axes that fade out before the middle; round trees in the
-- four corners; pines beside the left and right paths; rocks (single and in pairs), flower clumps, bushes, a stump and a log
-- round the rim, thickest at the corners; a few tiny flowers in the open middle. Not in the painting but needed by the game's
-- camera (it sits at the rim and looks across): two rows of woods behind the rim, a row of big bushes, a ring of hills.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")

local DEG = math.pi / 180
local HALF_PI = math.pi / 2

-- One map's block of numbers (Config.Dungeon.Arenas.<id>); the Meadow's when no map is named.
local function arenaOf(mapId: string?): any
	local found = (Config.Dungeon.Arenas :: any)[mapId or "meadow"]
	assert(found, "unknown arena map " .. tostring(mapId))
	return found
end

-- One model to stand: its kind (a key of Config.Dungeon.Arenas.<map>.Models), the model picked, where, how big (the height of
-- a tree, tuft or flower clump, the width when `wide`), a tint (hex) when the kind wears one, whether it carries a point light
-- (a glowing mushroom) and the group it belongs to (a clump is several models) with the group's middle and footprint radius.
export type Item = {
	kind: string,
	model: string,
	zone: string, -- "rim" | "backdrop" | "tiny" | "mouth" | "floor" (flat lava veins: they claim no ground)
	x: number,
	z: number,
	yaw: number,
	size: number,
	wide: boolean,
	tint: string?,
	light: boolean?,
	group: number,
	gx: number,
	gz: number,
	foot: number,
}

-- One flat block of a dirt path: its middle, how long (along its axis) and wide it is, its yaw, how far it fades toward the
-- grass (0 = full dirt), and its number along the path from the outside in (1 = outermost, to lift by).
export type Segment = {
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
-- (`layer` 1 is the map's Hills ring, 2 its Hills.Far ring behind it; `colour` the ring's own hex.)
export type Hill = { x: number, z: number, wide: number, tall: number, layer: number, colour: string }

-- One flagstone of a stone path: its middle, size, yaw, a little pitch and roll in radians (for it to sit uneven), how far its
-- colour fades toward the grass (0 = full stone), whether it is mossy, its grey (a share, -1 to 1, darker to lighter) and its
-- number along the path from the outside in.
export type Stone = {
	axis: number,
	index: number,
	x: number,
	z: number,
	wide: number,
	deep: number,
	yaw: number,
	pitch: number,
	roll: number,
	fade: number,
	mossy: boolean,
	shade: number,
}

-- One rune circle: its middle and radius, and the yaw its marks start at.
export type Circle = { x: number, z: number, radius: number, yaw: number }

local ArenaPlan = {}

-- How far a point is from the nearest of the four axes (the paths' middle lines).
function ArenaPlan.lateral(x: number, z: number): number
	return math.min(math.abs(x), math.abs(z))
end

-- Half the width of a path at `radius` from the middle.
function ArenaPlan.pathHalf(radius: number, mapId: string?): number
	local A = arenaOf(mapId)
	local t = math.clamp((radius - A.PathInner) / (A.PathOuter - A.PathInner), 0, 1)
	return (A.PathWidthInner + (A.PathWidthOuter - A.PathWidthInner) * t) / 2
end

-- The blocks of the four paths.
function ArenaPlan.paths(mapId: string?): { Segment }
	local A = arenaOf(mapId)
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
function ArenaPlan.hills(mapId: string?): { Hill }
	local A = arenaOf(mapId)
	local rng = Rng.new(A.Seed + 7)
	local out: { Hill } = {}
	-- (Ember Lava has a second ring, Hills.Far, taller, further out and darker, so two layers of hills overlap on the horizon)
	local rings: { any } = { A.Hills }
	if A.Hills.Far then
		table.insert(rings, A.Hills.Far)
	end
	for layer, H in rings do
		for k = 1, H.Count do
			local angle = (k - 0.5 + (rng:next() - 0.5) * 0.5) / H.Count * math.pi * 2
			local r = H.Radius + (rng:next() - 0.5) * 2 * H.Jitter
			table.insert(out, {
				x = math.cos(angle) * r,
				z = math.sin(angle) * r,
				wide = H.Wide[1] + rng:next() * (H.Wide[2] - H.Wide[1]),
				tall = H.Tall[1] + rng:next() * (H.Tall[2] - H.Tall[1]),
				layer = layer,
				colour = H.Colour,
			})
		end
	end
	return out
end

-- The flagstones of the four paths (a map whose PathStyle is "stones"; none for any other): one stone every Stones.Step along
-- each path's length, as many across as the path is wide at that point, each a little off its line and turned; toward the inner
-- end more of them are left out, so the path breaks up before the middle.
function ArenaPlan.stones(mapId: string?): { Stone }
	local A = arenaOf(mapId)
	local S = A.Stones
	local out: { Stone } = {}
	if A.PathStyle ~= "stones" or not S then
		return out
	end
	local rng = Rng.new(A.Seed + 11)
	local span = A.PathOuter - A.PathInner
	local rows = math.floor(span / S.Step)
	for axis = 0, 3 do
		local a = axis * HALF_PI
		local ux, uz = math.cos(a), math.sin(a)
		for k = 1, rows do
			local t = (k - 0.5) / rows
			local r = A.PathOuter - span * t
			local half = ArenaPlan.pathHalf(r, mapId)
			-- the same drift off the line the dirt path has
			local drift = A.PathWobble * math.sin(k * 1.9 + axis * 2.3)
			local across = math.max(1, math.floor(half * 2 / (S.Size[1] + S.Gap) + 0.5))
			local cell = half * 2 / across
			for c = 1, across do
				if rng:next() >= S.Skip * t * t then
					local side = (c - 0.5) * cell - half + (rng:next() - 0.5) * S.Gap * 2
					local along = (rng:next() - 0.5) * S.Gap * 2
					local wide = math.min(S.Size[1] + rng:next() * (S.Size[2] - S.Size[1]), cell - S.Gap * 0.5)
					local deep = S.Depth[1] + rng:next() * (S.Depth[2] - S.Depth[1])
					table.insert(out, {
						axis = axis,
						index = k,
						x = ux * (r + along) - uz * (side + drift),
						z = uz * (r + along) + ux * (side + drift),
						wide = math.max(wide, 1.2),
						deep = math.min(deep, S.Step * 1.1),
						yaw = HALF_PI - a + (rng:next() - 0.5) * 0.7,
						pitch = (rng:next() - 0.5) * 2 * S.Tilt * DEG,
						roll = (rng:next() - 0.5) * 2 * S.Tilt * DEG,
						fade = A.PathFade * t * t,
						mossy = rng:next() < S.Moss,
						shade = (rng:next() - 0.5) * 2,
					})
				end
			end
		end
	end
	return out
end

-- The rune circles, one in the middle of each quarter (none for a map without `Runes`), clear of the fight, the paths and
-- each other.
function ArenaPlan.runes(mapId: string?): { Circle }
	local A = arenaOf(mapId)
	local R = A.Runes
	local out: { Circle } = {}
	if not R then
		return out
	end
	local rng = Rng.new(A.Seed + 13)
	for q = 0, 3 do
		local angle = (q + 0.5) * HALF_PI
		table.insert(out, {
			x = math.cos(angle) * R.At,
			z = math.sin(angle) * R.At,
			radius = R.Radius,
			yaw = rng:next() * math.pi * 2,
		})
	end
	return out
end

-- Everything that stands on the map, in the order it was placed. `names` is the model list of each kind (default the map's
-- Config.Dungeon.Arenas.<map>.Models); a kind with no list or an empty one is left out.
function ArenaPlan.build(names: { [string]: { string } }?, mapId: string?): { Item }
	local A = arenaOf(mapId)
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

	-- A group: its footprint is claimed (unless `claims` is false: flat lava lies under everything), and its models are
	-- added to it. A model may be turned to a `turn` (radians) instead of a drawn yaw.
	local function group(zone: string, x: number, z: number, foot: number, claims: boolean?)
		groups += 1
		if claims ~= false then
			table.insert(placed, { x = x, z = z, foot = foot })
		end
		local id = groups
		return function(
			kind: string,
			at_x: number,
			at_z: number,
			size: number,
			wide: boolean,
			light: boolean?,
			turn: number?
		)
			if not has(kind) then
				return
			end
			-- (a map may tint its far woods apart from the near trees: BackdropTints, same kinds as Tints)
			local far = (A :: any).BackdropTints
			local tints = (if zone == "backdrop" and far and far[kind] then far else A.Tints :: any)[kind]
			table.insert(items, {
				kind = kind,
				model = rng:pick(list[kind]),
				zone = zone,
				x = at_x,
				z = at_z,
				yaw = if turn then turn else rng:next() * math.pi * 2,
				size = size,
				wide = wide,
				tint = if tints then rng:pick(tints) else nil,
				light = light,
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

	local function tuftBeside(
		add: (string, number, number, number, boolean, boolean?, number?) -> (),
		x: number,
		z: number,
		away: number
	)
		local angle = rng:next() * math.pi * 2
		add("tuft", x + math.cos(angle) * away, z + math.sin(angle) * away, between(A.Tuft), false)
	end

	-- 0. The rune circles are only floor, but nothing else may stand on them: their ground is claimed first.
	for _, circle in ArenaPlan.runes(mapId) do
		group("rune", circle.x, circle.z, circle.radius + 1)
	end

	-- 0b. Ember Lava's lava comes before everything else, so nothing stands where a fissure leads: one fissure system in each
	-- quarter, flat and claiming nothing, its thin tip at VeinTip from the middle and its thick end (the mesh's -X) toward the
	-- corner; a pool at that thick end, so the lava is connected; then the quarter's other pools, claiming their ground. The
	-- first few pools of each quarter carry one of the map's point lights, Glow.Lights. `Pools` is a number for every quarter
	-- or a list, one for each.
	local each = A.PerCorner
	local spread = 42 * DEG
	for q = 0, 3 do
		local centre = (q + 0.5) * HALF_PI
		local litPools = 0
		local poolLights = if A.Glow then A.Glow.Lights[q + 1] or 0 else 0
		local poolsHere: number = if type(each.Pools) == "table" then each.Pools[q + 1] or 0 else each.Pools or 0
		local function poolIn(x: number, z: number, size: number, turn: number?)
			local foot = size / 2 + 1
			local light = litPools < poolLights
			group("rim", x, z, foot)("pool", x, z, size, true, light, turn)
			if light then
				litPools += 1
			end
			poolsHere -= 1
		end
		for _ = 1, each.Veins or 0 do
			for _ = 1, A.Tries do
				local angle = centre + (rng:next() - rng:next()) * spread
				local size = between(A.Vein)
				local r = between(A.VeinTip) + size / 2
				local x, z = math.cos(angle) * r, math.sin(angle) * r
				if ArenaPlan.lateral(x, z) >= A.MouthHalf + 4 then
					local turn = math.atan2(z, -x) + (rng:next() - 0.5) * 0.25
					group("floor", x, z, 0, false)("vein", x, z, size, true, nil, turn)
					if poolsHere > 0 then
						local psize = between(A.Pool)
						-- (the mesh's +X, toward the middle, is (cos turn, -sin turn) on the floor)
						local back = size / 2 - psize * 0.05
						local px, pz = x - math.cos(turn) * back, z + math.sin(turn) * back
						local foot = psize / 2 + 1
						local pr = math.sqrt(px * px + pz * pz)
						if
							pr - foot >= A.WallRadius
							and pr <= A.RimOuter
							and ArenaPlan.lateral(px, pz) >= A.MouthHalf + foot
							and free(px, pz, foot)
						then
							poolIn(px, pz, psize, turn)
						end
					end
					break
				end
			end
		end
		for _ = 1, poolsHere do
			local size = between(A.Pool)
			local foot = size / 2 + 1
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				poolIn(x, z, size)
			end
		end
	end

	-- 1. The two pines beside the left and right paths (first: their spots are narrow), then the first round tree in each
	-- corner; the corners' other trees (the painting packs two or three together) come after the rocks and flowers.
	if has("pine") then
		for _, axis in { 0, 180 } do
			for _, side in { -1, 1 } do
				local size = between(A.Pine)
				local foot = size * (A.PineFoot or 0.33)
				local x, z = spot((axis + side * 23) * DEG, 5 * DEG, foot, A.RimInner + 3, A.RimOuter + 2)
				if x and z then
					group("rim", x, z, foot)("pine", x, z, size, false)
				end
			end
		end
	end
	local function cornerTrees(zone: string, count: number, aside: number, rIn: number, rOut: number)
		if not has("round") then
			return
		end
		for q = 0, 3 do
			for _ = 1, count do
				local size = between(A.Round)
				local foot = size * 0.3
				local x, z = spot((q + 0.5) * HALF_PI, aside, foot, rIn, rOut)
				if x and z then
					group(zone, x, z, foot)("round", x, z, size, false)
				end
			end
		end
	end
	cornerTrees("rim", 1, 5 * DEG, A.RimInner + 3, A.RimOuter + 2)

	-- 2. Per corner: rock pairs, single rocks (each in a tuft of grass), bushes, flower clumps, a stump and a log.
	for q = 0, 3 do
		local centre = (q + 0.5) * HALF_PI
		-- (the Grove's: the ruins first, the corner's great pieces, each with a root lying across its foot half the time)
		for _ = 1, each.Ruins or 0 do
			local size = between(A.Ruin)
			local foot = size * (A.RuinFoot or 0.3) + 1.5
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				add("ruin", x, z, size, false)
				if rng:next() < 0.5 then
					local turn = rng:next() * math.pi
					add("root", x + math.cos(turn) * 3.5, z + math.sin(turn) * 3.5, between(A.Root) * 0.6, true)
				end
			end
		end
		for _ = 1, each.Roots or 0 do
			local size = between(A.Root)
			local foot = size * 0.3
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				group("rim", x, z, foot)("root", x, z, size, true)
			end
		end
		for _ = 1, each.RockPairs do
			local foot = A.RockPairFoot or 9
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
			local foot = size * (A.StumpFoot or 0.5) + 0.6
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
		-- (the Grove's glowing clusters come after the ruins, roots and rocks and before the bushes and flowers: the first few
		-- carry a light; Glow.Lights lists how many for each quarter, the two in front of the player's camera first)
		local lit = 0
		local lights = if A.Glow then A.Glow.Lights[q + 1] or 0 else 0
		for _ = 1, each.Glows or 0 do
			local reach = A.GlowSpread
			local foot = reach + 1.2
			local x, z = spot(centre, spread, foot, A.RimInner, A.RimOuter)
			if x and z then
				local add = group("rim", x, z, foot)
				local count = rng:int(A.GlowCount[1], A.GlowCount[2])
				local turn = rng:next() * math.pi * 2
				for k = 1, count do
					local angle = turn + k / count * math.pi * 2
					local r = if k == 1 then 0 else reach * (0.5 + rng:next() * 0.5)
					local light = k == 1 and lit < lights
					add("glow", x + math.cos(angle) * r, z + math.sin(angle) * r, between(A.GlowSize), false, light)
					if light then
						lit += 1
					end
				end
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
				if
					ArenaPlan.lateral(x, z) >= ArenaPlan.pathHalf(r, mapId) + A.PathWobble + 2 and free(x, z, tinyFoot)
				then
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
	-- (Ember Lava closes them with low basalt masses, MouthKind, not with tall peaks)
	local mouthKind = A.MouthKind or "round"
	if has(mouthKind) then
		for q = 0, 3 do
			local axis = q * HALF_PI
			local ax, az = math.cos(axis), math.sin(axis)
			for _, side in { -1, 1 } do
				local size = between(A.BackdropRound)
				local foot = size * (if A.MouthKind then 0.6 else 0.2)
				local r = A.PathOuter + foot + A.MouthBehind
				local x, z = ax * r - az * side * A.MouthTreeApart, az * r + ax * side * A.MouthTreeApart
				if free(x, z, foot) then
					group("mouth", x, z, foot)(mouthKind, x, z, size, false)
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
				-- (Ember Lava: the masses straight behind the monsters, along the four axes, stand lower so a boss reads against
				-- the sky; the ones in the corners, framing the view, keep their height)
				local low = (A :: any).BackdropLow
				if low then
					local lateral = ArenaPlan.lateral(math.cos(angle), math.sin(angle)) * (row.from + row.to) / 2
					size *= low.Factor + (1 - low.Factor) * math.clamp(lateral / low.Lateral, 0, 1)
				end
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
