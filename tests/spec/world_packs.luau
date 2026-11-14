local Config = require("../../src/shared/Config")
local Rng = require("../../src/shared/Rng")
local WorldPacks = require("../../src/shared/WorldPacks")
local WorldPlan = require("../../src/shared/WorldPlan")

local P = Config.World.Packs

local function dist(ax: number, az: number, bx: number, bz: number): number
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
end

return function(T)
	T.test(
		"a pack's level is LevelMin near a village, LevelMax at the farthest, and never falls with distance",
		function()
			local far = 2000
			T.eq(WorldPacks.level(0, far), P.LevelMin)
			T.eq(WorldPacks.level(P.NearStuds, far), P.LevelMin)
			T.eq(WorldPacks.level(far, far), P.LevelMax)
			T.eq(WorldPacks.level(far * 2, far), P.LevelMax, "never above the top")
			local last = 0
			for distance = 0, far, 10 do
				local level = WorldPacks.level(distance, far)
				T.ok(level >= last, "falls at " .. distance)
				last = level
			end
		end
	)

	T.test(
		"levels by the plan alone: LevelMin at a village, never above LevelMax, a far place is deep in the bands",
		function()
			T.ok(WorldPacks.farthest() > P.NearStuds, "farthest " .. WorldPacks.farthest())
			-- (the farthest pack of the play test, 2026-11-14: cell p5x3)
			T.eq(WorldPacks.levelAt(-1078, -1747), P.LevelMax)
			local v = WorldPlan.Villages[1]
			T.eq(WorldPacks.levelAt(v.x, v.z), P.LevelMin)
			for x = -2300, 2300, 100 do
				for z = -2400, 2000, 100 do
					local level = WorldPacks.levelAt(x, z)
					T.ok(level >= P.LevelMin and level <= P.LevelMax, "level " .. level .. " at " .. x .. "," .. z)
				end
			end
			T.ok(WorldPacks.levelAt(0, -1500) > 100, "the Frost land is high level")
		end
	)

	T.test("bands are 20 levels wide and the last one ends at LevelMax", function()
		T.eq(WorldPacks.bands(), 8)
		T.eq(WorldPacks.band(4), 1)
		T.eq(WorldPacks.band(19), 1)
		T.eq(WorldPacks.band(20), 2)
		T.eq(WorldPacks.band(139), 7)
		T.eq(WorldPacks.band(140), 8)
		T.eq(WorldPacks.band(150), 8)
		T.eq(WorldPacks.bandName(1), "Lv 1-20")
		T.eq(WorldPacks.bandName(2), "Lv 20-40")
		T.eq(WorldPacks.bandName(8), "Lv 140-150")
		T.eq(#P.BandColours, WorldPacks.bands(), "a colour for every band")
	end)

	T.test("clear() refuses villages, the hub, zones, the Heart and the rim, and takes open meadow", function()
		local v = WorldPlan.Villages[3]
		T.ok(not WorldPacks.clear(v.x, v.z), "village")
		T.ok(not WorldPacks.clear(v.x + v.radius + P.VillageClear - 1, v.z), "a village's edge")
		T.ok(not WorldPacks.clear(WorldPlan.Hub.x, WorldPlan.Hub.z), "hub")
		for _, zone in WorldPlan.Zones do
			T.ok(not WorldPacks.clear(zone.x, zone.z), zone.id)
		end
		T.ok(not WorldPacks.clear(WorldPlan.Heart.x, WorldPlan.Heart.z), "the Heart")
		T.ok(
			not WorldPacks.clear(WorldPlan.Heart.x + WorldPlan.Heart.FootRadius, WorldPlan.Heart.z),
			"the Heart's foot"
		)
		for _, site in WorldPlan.Sites do
			T.ok(not WorldPacks.clear(site.x, site.z), site.id)
		end
		T.ok(not WorldPacks.clear(WorldPlan.Rim.x + WorldPlan.Rim.radius, WorldPlan.Rim.z), "on the rim")
		T.ok(not WorldPacks.clear(WorldPlan.Bounds.maxX, 0), "outside")
		T.ok(WorldPacks.clear(-300, 320), "open meadow")
	end)

	T.test("candidates are the same every time, differ between tries and stay within JitterStuds", function()
		local cells = WorldPacks.cells()
		local moved = 0
		for _, cell in cells do
			local ax, az = WorldPacks.candidate(cell, 1)
			local bx, bz = WorldPacks.candidate(cell, 1)
			T.ok(ax == bx and az == bz, "same twice " .. cell.id)
			local cx, cz = WorldPacks.candidate(cell, 2)
			if cx ~= ax or cz ~= az then
				moved += 1
			end
			for try = 1, P.Tries do
				local x, z = WorldPacks.candidate(cell, try)
				T.ok(
					math.abs(x - cell.x) <= P.JitterStuds and math.abs(z - cell.z) <= P.JitterStuds,
					"jitter " .. cell.id
				)
			end
		end
		T.eq(moved, #cells, "another place each try")
	end)

	T.test("cells cover the land with short unique ids", function()
		local seen: { [string]: boolean } = {}
		local cells = WorldPacks.cells()
		T.ok(#cells > 100, "cells " .. #cells)
		for _, cell in cells do
			T.ok(not seen[cell.id], "twice " .. cell.id)
			seen[cell.id] = true
			T.ok(#cell.id <= Config.Zombies.TargetIdMaxLength, "short " .. cell.id)
		end
		local standing = 0
		for _, cell in cells do
			if WorldPacks.clear(WorldPacks.candidate(cell, 1)) then
				standing += 1
			end
		end
		T.ok(standing > 40, "packs standing on try 1: " .. standing)
	end)

	T.test("a region and a map by the nearest seed", function()
		local maps = { vale = "meadow", meadow = "meadow", mushroom = "mushroom", ember = "lava", frost = "ice" }
		for _, region in WorldPlan.Regions do
			local seed = region.at[1]
			T.eq(WorldPacks.region(seed[1], seed[2]), region.id)
			T.eq(WorldPacks.mapOf(seed[1], seed[2]), maps[region.id])
		end
		local v = WorldPlan.Villages[2]
		T.eq(WorldPacks.villageDistance(v.x, v.z), 0)
		T.near(WorldPacks.villageDistance(v.x + 30, v.z), 30, 1e-9)
	end)

	T.test("a pack is 3 to 5 common monsters of its map, at its level, with equal stat shares", function()
		local rng = Rng.new(7)
		local sizes: { [number]: boolean } = {}
		for _, mapId in { "meadow", "mushroom", "lava", "ice" } do
			local roster = WorldPacks.roster(mapId)
			T.ok(#roster > 0, mapId)
			for _, def in roster do
				T.ok(def.role ~= "miniboss" and def.role ~= "boss", def.id)
			end
			for _ = 1, 50 do
				local pack = WorldPacks.pack("p", mapId, 30, rng)
				T.ok(#pack >= P.SizeMin and #pack <= P.SizeMax, "size " .. #pack)
				sizes[#pack] = true
				for index, monster in pack do
					T.eq(monster.id, "p-" .. index)
					T.eq(monster.level, 30)
					local fromRoster = false
					for _, def in roster do
						fromRoster = fromRoster or def.id == monster.defId
					end
					T.ok(fromRoster, monster.defId .. " is not of " .. mapId)
					T.eq(monster.attack, monster.defence)
					T.eq(monster.defence, monster.speed)
					T.near(monster.attack, 30 / 4 * P.StatFactor, 1e-9)
					T.near(monster.hp, monster.attack * Config.Stats.HpPerLevel, 1e-9)
				end
			end
		end
		T.ok(sizes[3] and sizes[4] and sizes[5], "every size comes up")
	end)

	T.test("a kill pays more by level and by role", function()
		T.ok(WorldPacks.killReward("swarmer", 20) > WorldPacks.killReward("swarmer", 10))
		T.ok(WorldPacks.killReward("armoured", 10) > WorldPacks.killReward("swarmer", 10))
		T.eq(WorldPacks.killReward(nil, 0), P.CoinBase.swarmer)
		T.eq(WorldPacks.killReward("unknown", 0), P.CoinBase.swarmer)
	end)

	T.test("a team sets out at most MarchMostStuds from its pack, on the line to the gate", function()
		local gx, gz = WorldPacks.musterSpot(0, 0, P.MarchMostStuds - 10, 0)
		T.same({ gx, gz }, { P.MarchMostStuds - 10, 0 })
		local x, z = WorldPacks.musterSpot(0, 0, 300, 400)
		T.near(dist(0, 0, x, z), P.MarchMostStuds, 1e-9)
		T.near(x / z, 300 / 400, 1e-9, "on the line")
		T.ok(x > 0 and z > 0)
	end)
end
