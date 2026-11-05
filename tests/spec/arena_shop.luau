--!strict
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Gear = require("../../src/shared/Gear")
local Rules = require("../../src/shared/ArenaRules")
local Season = require("../../src/shared/ArenaSeason")

local A = Config.Arena
local DAY = 86400
-- 2026-11-10 12:00 UTC, a Tuesday; its week ends on Monday 2026-11-16 00:00
local NOW = Season.seasonStart(202611) + 9 * DAY + 12 * 3600
local MONDAY = Season.seasonStart(202611) + 15 * DAY

local function farm(points: number): any
	local f: any = FarmKit.farm(NOW, FarmKit.many(2))
	f.arena.points = points
	return f
end

local function offer(id: string): any
	for _, o in A.Shop do
		if o.id == id then
			return o
		end
	end
	error("no shop item " .. id)
end

return function(T)
	T.test("the shop list: unique ids, real materials and gear, sane numbers", function()
		local seen: { [string]: boolean } = {}
		for _, o in A.Shop do
			T.ok(not seen[o.id], "id " .. o.id .. " is unique")
			seen[o.id] = true
			T.ok(o.count >= 1 and o.price >= 1 and o.weeklyLimit >= 1)
			if o.kind == "material" then
				T.ok((Config.Dungeon.Materials :: any)[o.item] ~= nil, o.id .. " names a dungeon material")
			else
				T.eq(o.kind, "gear")
				T.ok(Gear.get(o.item) ~= nil, o.id .. " names a gear piece")
			end
		end
	end)

	T.test("the week ends on Monday 00:00 UTC", function()
		T.eq(Season.weekEnd(Season.weekOf(NOW)), MONDAY)
		T.eq(Season.weekOf(MONDAY - 1), Season.weekOf(NOW))
		T.eq(Season.weekOf(MONDAY), Season.weekOf(NOW) + 1)
	end)

	T.test("a material buy takes the points and gives the item, once per limit", function()
		local f = farm(10000)
		local o = offer("ore5")
		for i = 1, o.weeklyLimit do
			T.same({ Rules.buy(f, NOW, "ore5") }, { true })
			T.eq(f.materials.ore, o.count * i)
			T.eq(f.arena.points, 10000 - o.price * i)
			T.eq(f.arena.bought.ore5, i)
		end
		local points = f.arena.points
		T.same({ Rules.buy(f, NOW, "ore5") }, { false, "SOLD_OUT" })
		T.eq(f.materials.ore, o.count * o.weeklyLimit, "a refusal gives nothing")
		T.eq(f.arena.points, points, "a refusal takes nothing")
	end)

	T.test("a new week (Monday 00:00 UTC) starts the limits over", function()
		local f = farm(10000)
		T.ok((Rules.buy(f, NOW, "charm_core")))
		T.same({ Rules.buy(f, MONDAY - 1, "charm_core") }, { false, "SOLD_OUT" })
		T.same({ Rules.buy(f, MONDAY, "charm_core") }, { true })
		T.eq(f.arena.week, Season.weekOf(MONDAY))
		T.eq(f.arena.bought.charm_core, 1)
		T.eq(f.gear["charm-core"], 2)
	end)

	T.test("refusals: unknown item, not enough points, points never below zero", function()
		local f = farm(offer("core1").price - 1)
		T.same({ Rules.buy(f, NOW, "nope") }, { false, "UNKNOWN_ITEM" })
		T.same({ Rules.buy(f, NOW, 7) }, { false, "UNKNOWN_ITEM" })
		T.same({ Rules.buy(f, NOW, nil) }, { false, "UNKNOWN_ITEM" })
		T.same({ Rules.buy(f, NOW, "core1") }, { false, "NO_POINTS" })
		T.eq(f.arena.points, offer("core1").price - 1)
		T.same(f.materials, {})
		T.same(f.arena.bought, {})
		f.arena.points = offer("core1").price
		T.ok((Rules.buy(f, NOW, "core1")))
		T.eq(f.arena.points, 0)
		T.same({ Rules.buy(f, NOW, "core1") }, { false, "NO_POINTS" })
		T.eq(f.arena.points, 0)
	end)

	T.test("a gear buy puts a valid piece in the bag and the farm survives repair", function()
		local f = farm(5000)
		local before = f.gear["charm-core"] or 0
		T.same({ Rules.buy(f, NOW, "charm_core") }, { true })
		T.eq(f.gear["charm-core"], before + 1)
		T.eq(f.arena.points, 5000 - offer("charm_core").price)
		local kept = FarmState.repair(f, NOW)
		T.same(kept.gear, f.gear)
		T.same(kept.materials, f.materials)
		T.same(kept.arena.bought, f.arena.bought)
		T.eq(kept.arena.points, f.arena.points)
		-- the piece can be worn
		local slot = Gear.equip(f, "s1", "charm-core")
		T.ok(slot ~= nil)
	end)

	T.test("shop() lists the rows with what is left and what the points reach", function()
		local f = farm(100)
		local rows = Rules.shop(f, NOW)
		T.eq(#rows, #A.Shop)
		for i, row in rows do
			T.eq(row.id, A.Shop[i].id, "list order")
		end
		T.eq(rows[1].left, offer("ore5").weeklyLimit)
		T.eq(rows[1].affordable, true)
		T.eq(rows[6].affordable, false)
		T.ok(Rules.buy(f, NOW, "ore5"))
		T.eq(Rules.shop(f, NOW)[1].left, offer("ore5").weeklyLimit - 1)
		-- next week every row is whole again, and looking changed nothing
		local nextWeek = Rules.shop(f, MONDAY)
		T.eq(nextWeek[1].left, offer("ore5").weeklyLimit)
		T.eq(f.arena.bought.ore5, 1)
		f.arena.bought.ore5 = offer("ore5").weeklyLimit
		T.eq(Rules.shop(f, NOW)[1].left, 0)
		T.eq(Rules.shop(f, NOW)[1].affordable, false, "sold out is not affordable")
	end)

	T.test("Gear.give refuses an unknown piece and a count below one", function()
		local f = farm(0)
		T.eq(Gear.give(f, "nope", 1), false)
		T.eq(Gear.give(f, "charm-core", 0), false)
		T.same(f.gear, {})
		T.eq(Gear.give(f, "charm-core", 2), true)
		T.eq(f.gear["charm-core"], 2)
	end)
end
