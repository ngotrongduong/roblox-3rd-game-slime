--!strict
local Ladder = require("../../src/shared/ArenaLadder")
local Season = require("../../src/shared/ArenaSeason")
local Config = require("../../src/shared/Config")
local Rng = require("../../src/shared/Rng")

local function small(): any
	local doc = Ladder.new(202611)
	doc.order = {}
	for i = 1, 10 do
		Ladder.join(doc, tostring(i), "Player " .. i, 16)
	end
	return doc
end

local function result(attacker: string, defender: string, won: boolean, seq: number?): any
	return {
		attacker = attacker,
		defender = defender,
		won = won,
		seq = seq or 1,
		above = true,
		season = 202611,
		name = "Player",
		power = 20,
	}
end

return function(T)
	T.test("a new ladder is ordered bots with no player metadata", function()
		local doc = Ladder.new(202611)
		T.eq(doc.v, Config.Arena.Version)
		T.eq(#doc.order, Config.Arena.Bots)
		T.eq(doc.order[1], "b1")
		T.eq(doc.order[#doc.order], "b" .. Config.Arena.Bots)
		T.same(doc.players, {})
	end)
	T.test("rank 9 beats rank 2 and moves everyone between down exactly one", function()
		local doc = small()
		local status, out = Ladder.apply(doc, result("9", "2", true))
		T.eq(status, "applied")
		T.same(doc.order, { "1", "9", "2", "3", "4", "5", "6", "7", "8", "10" })
		T.eq(out.rankAfter, 2)
		T.eq(out.climbed, 7)
		T.eq(doc.players["9"].sp, Season.winPoints(true, 7, true))
	end)
	T.test("beating a lower defender keeps every rank", function()
		local doc = small()
		local before = table.clone(doc.order)
		local r = result("2", "9", true)
		r.above = false
		local _, out = Ladder.apply(doc, r)
		T.same(doc.order, before)
		T.eq(out.climbed, 0)
		T.eq(out.points, Season.winPoints(true, 0, false))
	end)
	T.test("duplicate and older sequences return the identical stored outcome", function()
		local doc = small()
		local r = result("9", "2", true, 4)
		local _, first = Ladder.apply(doc, r)
		local before = table.clone(doc.order)
		local status, again = Ladder.apply(doc, r)
		T.eq(status, "dup")
		T.eq(first, again)
		T.same(doc.order, before)
		T.eq(doc.players["9"].sp, first.points)
		local stale = result("9", "1", true, 3)
		stale.name, stale.power = "Old name", 0
		local oldStatus, oldOut = Ladder.apply(doc, stale)
		T.eq(oldStatus, "dup")
		T.eq(oldOut, first)
		T.eq(doc.players["9"].p, 20)
		T.eq(doc.players["9"].seq, 4)
	end)
	T.test("a stale above target now below pays a win without a climb", function()
		local doc = small()
		local pending = result("9", "2", true, 2)
		Ladder.apply(doc, result("9", "1", true))
		local _, out = Ladder.apply(doc, pending)
		T.eq(out.climbed, 0)
		T.eq(out.rankAfter, 1)
		T.eq(out.points, Config.Arena.WinPoints)
	end)
	T.test("a lost attack credits the player defender once", function()
		local doc = small()
		local r = result("9", "2", false)
		local _, out = Ladder.apply(doc, r)
		Ladder.apply(doc, r)
		T.eq(out.points, Config.Arena.LossPoints)
		T.eq(doc.players["2"].dw, 1)
		T.eq(Ladder.rankOf(doc, "9"), 9)
	end)
	T.test("final and wrong-season results are void and leave the whole document alone", function()
		for _, final in { false, true } do
			local doc = small()
			doc.final = final
			local r = result("9", "2", true)
			if not final then
				r.season = 202610
			end
			local status, out = Ladder.apply(doc, r)
			T.eq(status, "void")
			T.eq(out.void, true)
			T.eq(out.points, 0)
			T.eq(out.rankAfter, 9)
			T.same(doc.order, small().order)
			T.same(doc.players, small().players)
			r.attacker = "missing"
			local _, missing = Ladder.apply(doc, r)
			T.eq(missing.rankAfter, 0)
			T.eq(doc.players.missing, nil)
		end
	end)
	T.test("join appends and updates identity without resetting progress", function()
		local doc = small()
		T.eq(Ladder.join(doc, "11", "New", 40), 11)
		T.same(doc.players["11"], { n = "New", p = 40, sp = 0, dw = 0, seq = 0 })
		Ladder.apply(doc, result("11", "2", true))
		T.eq(Ladder.join(doc, "11", "Renamed", 50), 2)
		T.eq(doc.players["11"].seq, 1)
		T.eq(doc.players["11"].n, "Renamed")
		T.eq(doc.players["11"].p, 50)
		T.eq(#doc.order, 11)
	end)
	T.test("apply joins a missing attacker and tolerates a vanished defender", function()
		local doc = small()
		local _, out = Ladder.apply(doc, result("11", "missing", true))
		T.eq(out.rankAfter, 11)
		T.eq(out.climbed, 0)
		T.eq(out.points, Config.Arena.WinPoints)
	end)
	T.test("rank maps and top are ordered copies", function()
		local doc = small()
		local ranks = Ladder.ranks(doc)
		for rank, id in doc.order do
			T.eq(ranks[id], rank)
		end
		T.eq(Ladder.rankOf(doc, "unknown"), nil)
		T.same(Ladder.top(doc, 2), { { rank = 1, id = "1" }, { rank = 2, id = "2" } })
		T.eq(#Ladder.top(doc, 100), #doc.order)
		T.same(Ladder.top(doc, 0), {})
	end)
	for _, rank in { 1, 2, 5, 50, 1001 } do
		T.test("opponents at rank " .. rank .. " are unique and never self", function()
			local doc = Ladder.new(202611)
			local id = if rank == 1001 then "1001" else "b" .. rank
			local picks = Ladder.opponents(doc, id, Rng.new(123), 5)
			T.eq(#picks, 5)
			local seen = {}
			for _, pick in picks do
				T.ok(pick.id ~= id)
				T.ok(not seen[pick.id])
				seen[pick.id] = true
				if pick.above then
					T.ok(pick.rank >= math.floor(rank * Config.Arena.AboveShare) and pick.rank < rank)
				else
					T.ok(pick.rank == nil or pick.rank > rank)
				end
				if rank == 50 then
					T.ok(pick.rank >= 37 and pick.rank <= 49)
				end
			end
			T.same(picks, Ladder.opponents(doc, id, Rng.new(123), 5))
		end)
	end
	T.test("large windows choose one hard, two middle and the rest easy", function()
		local picks = Ladder.opponents(Ladder.new(202611), "b50", Rng.new(1), 5)
		local bands = { 0, 0, 0 }
		for _, pick in picks do
			local band = math.floor((pick.rank - 37) * 3 / 13) + 1
			bands[band] += 1
		end
		T.same(bands, { 1, 2, 2 })
	end)
	T.test("short windows use every rank above then below then champions", function()
		local doc = small()
		T.same(Ladder.opponents(doc, "2", Rng.new(1), 3), {
			{ id = "1", rank = 1, above = true },
			{ id = "3", rank = 3, above = false },
			{ id = "4", rank = 4, above = false },
		})
		doc.order = { "1" }
		local picks = Ladder.opponents(doc, "1", Rng.new(1), 5)
		for i, pick in picks do
			T.same(pick, { id = "c" .. i, above = false })
		end
		T.eq(#doc.order, 1)
		T.throws(function()
			Ladder.join(doc, "c1", "Champion", 1)
		end)
	end)
end
