-- The Slime Dungeon maps' plans (shared/DungeonArenaPlan), the Sunny Meadow and the Mushroom Grove alike: the fight's centre
-- is clear, the four path mouths are open, nothing overlaps, the rim scenery stands outside the wall, and the same plan
-- comes out every time. The Grove's own parts (flagstones, rune circles, ruins, roots, glowing clusters) follow.
local Config = require("../../src/shared/Config")
local Plan = require("../../src/shared/DungeonArenaPlan")

local function flat(x: number, z: number): number
	return math.sqrt(x * x + z * z)
end

local function suite(T: any, mapId: string)
	local A: any = (Config.Dungeon.Arenas :: any)[mapId]
	local items = Plan.build(nil, mapId)

	local function test(name: string, run: () -> ())
		T.test(mapId .. ": " .. name, run)
	end

	-- one entry a group, with its footprint
	local seen: { [number]: any } = {}
	local order: { any } = {}
	for _, item in items do
		if not seen[item.group] then
			seen[item.group] = item
			table.insert(order, item)
		end
	end

	test("the same plan comes out every time", function()
		local again = Plan.build(nil, mapId)
		T.eq(#again, #items)
		for index, item in items do
			T.eq(again[index].x, item.x)
			T.eq(again[index].z, item.z)
			T.eq(again[index].model, item.model)
		end
	end)

	test("every piece of the painting is there: corners, pines, rocks, bushes, clumps", function()
		local count: { [string]: number } = {}
		for _, item in items do
			if item.zone == "rim" then
				count[item.kind] = (count[item.kind] or 0) + 1
			end
		end
		local each = A.PerCorner
		T.eq(count.round, 4, "a round tree in each corner (its others stand behind, in the far ring)")
		T.eq(count.pine, 4, "two pines beside each of the left and right paths")
		-- a crowded corner may drop a piece that finds no room, so a few under the full number pass
		T.ok((count.rock or 0) >= 3 * (2 * each.RockPairs + each.Rocks), "rocks, singles and pairs")
		T.ok((count.bush or 0) >= 3 * each.Bushes, "bushes")
		T.ok((count.flower or 0) >= 3 * each.Clumps * 2, "flower clumps")
		T.ok((count.stump or 0) >= 3 * each.Stumps, "stumps")
		T.ok((count.log or 0) >= 3 * each.Logs, "logs")
		T.ok((count.ruin or 0) >= 3 * (each.Ruins or 0), "ruins")
		T.ok((count.root or 0) >= 3 * (each.Roots or 0), "roots")
		T.ok((count.glow or 0) >= 3 * (each.Glows or 0), "glowing mushrooms")
	end)

	test("a kind with no models is left out, the rest stands as before", function()
		local names: { [string]: { string } } = {}
		for kind, list in A.Models :: any do
			names[kind] = if kind == "log" or kind == "stump" or kind == "rock" then {} else list
		end
		local without = Plan.build(names, mapId)
		for _, item in without do
			T.ok(item.kind ~= "log" and item.kind ~= "stump" and item.kind ~= "rock", "no " .. item.kind)
		end
		-- (what is left out frees room, so the rest may even grow: only that it still stands is certain)
		T.ok(#without > 0)
	end)

	test("a ring of hills round the whole circle, far behind the woods", function()
		local hills = Plan.hills(mapId)
		T.eq(#hills, A.Hills.Count)
		local quarters: { [number]: number } = {}
		for _, hill in hills do
			T.ok(flat(hill.x, hill.z) >= A.BackdropOuter, "behind the woods")
			T.ok(hill.tall >= A.Hills.Tall[1] and hill.wide >= A.Hills.Wide[1], "its size")
			local q = math.floor((math.atan2(hill.z, hill.x) % (2 * math.pi)) / (math.pi / 2))
			quarters[q] = (quarters[q] or 0) + 1
		end
		for q = 0, 3 do
			T.ok((quarters[q] or 0) >= A.Hills.Count / 8, "hills in quarter " .. q)
		end
	end)

	test("nothing stands in the fight's centre", function()
		for _, item in items do
			T.ok(flat(item.x, item.z) >= A.FightClear, item.kind .. " at " .. flat(item.x, item.z))
		end
		for _, item in order do
			if item.zone == "tiny" then
				T.ok(
					flat(item.gx, item.gz) >= A.TinyFrom - 1e-6 and flat(item.gx, item.gz) <= A.TinyTo + 1e-6,
					"tiny band"
				)
			end
		end
	end)

	test("the rim scenery stands outside the wall and inside the band", function()
		for _, item in order do
			if item.zone == "rim" then
				local r = flat(item.gx, item.gz)
				T.ok(r - item.foot >= A.WallRadius, "outside the wall, group " .. item.group .. " r " .. r)
				T.ok(r <= A.RimOuter, "inside the band, group " .. item.group .. " r " .. r)
			end
		end
		T.ok(A.WallRadius < Config.Dungeon.ArenaRadius, "the wall holds the arena")
		T.ok(
			A.WallRadius >= Config.Dungeon.ArenaRadius - Config.Dungeon.SpawnInset - 1,
			"the wall is not far past the spawns"
		)
	end)

	test("the four path mouths stay open", function()
		for _, item in order do
			if item.zone == "mouth" then
				T.ok(
					flat(item.gx, item.gz) - item.foot > A.PathOuter,
					"mouth tree past the path's end, group " .. item.group
				)
			elseif item.zone ~= "tiny" then
				local lateral = Plan.lateral(item.gx, item.gz)
				T.ok(lateral >= A.MouthHalf + item.foot - 1e-6, "mouth, group " .. item.group .. " lateral " .. lateral)
			else
				local r = flat(item.gx, item.gz)
				T.ok(
					Plan.lateral(item.gx, item.gz) >= Plan.pathHalf(r, mapId),
					"tiny piece off the path, group " .. item.group
				)
			end
		end
	end)

	test("no two pieces overlap", function()
		for i = 1, #order do
			for j = i + 1, #order do
				local a, b = order[i], order[j]
				local gap = flat(a.gx - b.gx, a.gz - b.gz)
				T.ok(
					gap >= a.foot + b.foot + A.Gap - 1e-6,
					"groups " .. a.group .. " and " .. b.group .. " are " .. gap
				)
			end
		end
	end)

	test("the far ring stays on the floor and out of the path mouths", function()
		local backdrop = 0
		for _, item in order do
			if item.zone == "backdrop" then
				backdrop += 1
				T.ok(math.abs(item.gx) <= A.FloorHalf - 4 and math.abs(item.gz) <= A.FloorHalf - 4, "on the floor")
				T.ok(flat(item.gx, item.gz) - item.foot > A.RimInner, "beyond the rim")
			end
		end
		local wanted = 0
		for _, row in A.BackdropRows do
			wanted += row.count
		end
		T.ok(backdrop >= wanted * 0.6, "most of the woods stand, " .. backdrop .. " of " .. wanted)
	end)

	test("every piece is a kit model of its kind, with a plain size", function()
		for _, item in items do
			local names: { string } = (A.Models :: any)[item.kind]
			T.ok(names and table.find(names, item.model) ~= nil, item.kind .. " " .. item.model)
			T.ok(item.size > 0.5 and item.size < 53, item.kind .. " size " .. item.size)
		end
	end)

	test("four paths that stop before the middle and narrow toward it", function()
		local paths = Plan.paths(mapId)
		T.eq(#paths, 4 * A.PathSegments)
		local axes: { [number]: boolean } = {}
		for _, seg in paths do
			axes[seg.axis] = true
			local r = flat(seg.x, seg.z)
			T.ok(r + seg.length / 2 <= A.PathOuter + 1.5 + A.PathWobble, "starts inside the outer end")
			T.ok(r - seg.length / 2 >= A.PathInner - 1.5 - A.PathWobble, "stops at the inner end")
			T.ok(seg.width >= A.PathWidthInner - 1e-6 and seg.width <= A.PathWidthOuter + 1e-6, "width")
			T.ok(seg.fade >= 0 and seg.fade <= A.PathFade + 1e-6, "fade")
		end
		for axis = 0, 3 do
			T.ok(axes[axis], "path " .. axis)
		end
		T.ok(A.PathInner >= A.FightClear - 10, "the paths fade out before the fight's centre")
	end)

	test("flagstones lie on the paths of a stone map, none on a dirt one", function()
		local stones = Plan.stones(mapId)
		if A.PathStyle ~= "stones" then
			T.eq(#stones, 0)
			return
		end
		T.ok(#stones > 4 * (A.PathOuter - A.PathInner) / A.Stones.Step, "a stone or more across every step")
		local outer, inner = 0, 0
		local middle = (A.PathOuter + A.PathInner) / 2
		for _, stone in stones do
			local r = flat(stone.x, stone.z)
			T.ok(r <= A.PathOuter + A.Stones.Step and r >= A.PathInner - A.Stones.Step, "within the path's length")
			T.ok(
				Plan.lateral(stone.x, stone.z) <= Plan.pathHalf(r, mapId) + A.PathWobble + A.Stones.Gap * 2 + 1,
				"within the path's width"
			)
			T.ok(stone.wide >= 1.2 and stone.deep > 0, "its size")
			T.ok(math.abs(stone.pitch) <= A.Stones.Tilt * math.pi / 180 + 1e-6, "only a little uneven")
			T.ok(stone.shade >= -1 and stone.shade <= 1, "its grey")
			if r > middle then
				outer += 1
			else
				inner += 1
			end
		end
		T.ok(outer > inner, "the path breaks up toward the middle: " .. outer .. " outside, " .. inner .. " inside")
		local again = Plan.stones(mapId)
		T.eq(#again, #stones)
		T.eq(again[#again].x, stones[#stones].x)
	end)

	test("rune circles keep to their quarters, clear of the fight, the paths and everything else", function()
		local circles = Plan.runes(mapId)
		if not A.Runes then
			T.eq(#circles, 0)
			return
		end
		T.eq(#circles, 4)
		for _, circle in circles do
			T.ok(flat(circle.x, circle.z) - circle.radius >= A.FightClear, "clear of the fight")
			T.ok(
				Plan.lateral(circle.x, circle.z) - circle.radius
					>= Plan.pathHalf(flat(circle.x, circle.z), mapId) + A.PathWobble,
				"clear of the paths"
			)
			for _, item in order do
				if item.zone ~= "mouth" then
					local gap = flat(item.gx - circle.x, item.gz - circle.z)
					T.ok(
						gap >= circle.radius + 1 + item.foot + A.Gap - 1e-6,
						item.kind .. " is off the circle, gap " .. gap
					)
				end
			end
		end
	end)

	test("glowing clusters carry a few lights, the others none", function()
		local lit = 0
		for _, item in items do
			if item.light then
				lit += 1
				T.ok(item.kind == "glow", "only a glowing mushroom is lit")
			end
		end
		if A.Glow then
			local most = 0
			for _, n in A.Glow.Lights do
				most += n
			end
			T.ok(lit > 0 and lit <= most and most <= 6, "lights " .. lit)
			for _, hex in A.Glow.Colours do
				T.ok(string.match(hex, "^#%x%x%x%x%x%x$") ~= nil, "a colour " .. hex)
			end
		else
			T.eq(lit, 0)
		end
	end)
end

return function(T: any)
	for _, mapId in Config.Dungeon.MapOrder do
		suite(T, mapId)
	end

	T.test("the Meadow stays the Meadow: no stones, no runes, no ruins, roots or glow", function()
		local meadow = Plan.build(nil, "meadow")
		for _, item in meadow do
			T.ok(item.kind ~= "ruin" and item.kind ~= "root" and item.kind ~= "glow" and not item.light, item.kind)
		end
		T.eq(#Plan.stones("meadow"), 0)
		T.eq(#Plan.runes("meadow"), 0)
		T.eq(#Plan.build(), #meadow, "no map named is the Meadow")
	end)

	T.test("the Grove has its own set of ruins, roots and glowing mushrooms", function()
		local seen: { [string]: number } = {}
		for _, item in Plan.build(nil, "mushroom") do
			seen[item.kind] = (seen[item.kind] or 0) + 1
		end
		T.ok((seen.ruin or 0) > 0 and (seen.root or 0) > 0 and (seen.glow or 0) > 0)
		T.ok(#Plan.stones("mushroom") > 0 and #Plan.runes("mushroom") == 4)
	end)
end
