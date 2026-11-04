-- The Sunny Meadow's plan (shared/DungeonArenaPlan): the fight's centre is clear, the four path mouths are open, nothing
-- overlaps, the rim scenery stands outside the wall, and the same plan comes out every time.
local Config = require("../../src/shared/Config")
local Plan = require("../../src/shared/DungeonArenaPlan")

local A = Config.Dungeon.Arena

local function flat(x: number, z: number): number
	return math.sqrt(x * x + z * z)
end

return function(T: any)
	local items = Plan.build()

	-- one entry a group, with its footprint
	local seen: { [number]: any } = {}
	local order: { any } = {}
	for _, item in items do
		if not seen[item.group] then
			seen[item.group] = item
			table.insert(order, item)
		end
	end

	T.test("the same plan comes out every time", function()
		local again = Plan.build()
		T.eq(#again, #items)
		for index, item in items do
			T.eq(again[index].x, item.x)
			T.eq(again[index].z, item.z)
			T.eq(again[index].model, item.model)
		end
	end)

	T.test("every piece of the painting is there: corners, pines, rocks, bushes, clumps", function()
		local count: { [string]: number } = {}
		for _, item in items do
			if item.zone == "rim" then
				count[item.kind] = (count[item.kind] or 0) + 1
			end
		end
		T.eq(count.round, 4, "a round tree in each corner (its others stand behind, in the far ring)")
		T.eq(count.pine, 4, "two pines beside each of the left and right paths")
		T.ok((count.rock or 0) >= 4 * (2 * A.PerCorner.RockPairs + A.PerCorner.Rocks), "rocks, singles and pairs")
		T.ok((count.bush or 0) >= 4 * A.PerCorner.Bushes - 1, "bushes")
		T.ok((count.flower or 0) >= 4 * A.PerCorner.Clumps * 2 - 2, "flower clumps")
	end)

	T.test("nothing stands in the fight's centre", function()
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

	T.test("the rim scenery stands outside the wall and inside the band", function()
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

	T.test("the four path mouths stay open", function()
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
					Plan.lateral(item.gx, item.gz) >= Plan.pathHalf(r),
					"tiny piece off the path, group " .. item.group
				)
			end
		end
	end)

	T.test("no two pieces overlap", function()
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

	T.test("the far ring stays on the floor and out of the path mouths", function()
		local backdrop = 0
		for _, item in order do
			if item.zone == "backdrop" then
				backdrop += 1
				T.ok(math.abs(item.gx) <= A.FloorHalf - 4 and math.abs(item.gz) <= A.FloorHalf - 4, "on the floor")
				T.ok(flat(item.gx, item.gz) - item.foot > A.RimInner, "beyond the rim")
			end
		end
		T.ok(backdrop >= A.BackdropCount * 0.6, "most of the ring stands, " .. backdrop)
	end)

	T.test("every piece is a kit model of its kind, with a plain size", function()
		for _, item in items do
			local names: { string } = (A.Models :: any)[item.kind]
			T.ok(names and table.find(names, item.model) ~= nil, item.kind .. " " .. item.model)
			T.ok(item.size > 0.5 and item.size < 40, item.kind .. " size " .. item.size)
		end
	end)

	T.test("four paths that stop before the middle and narrow toward it", function()
		local paths = Plan.paths()
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
end
