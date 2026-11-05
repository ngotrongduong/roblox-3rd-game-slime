--!strict
local ArenaQuests = require("../../src/shared/ArenaQuests")
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rules = require("../../src/shared/ArenaRules")
local Season = require("../../src/shared/ArenaSeason")

local A = Config.Arena
-- 2026-11-10 12:00 UTC, mid season 202611
local NOW = Season.seasonStart(202611) + 9 * 86400 + 12 * 3600
local DAY = 86400

local function farm(now: number?): any
	local f = FarmKit.farm(now or NOW, FarmKit.many(6))
	assert(Rules.setTeam(f, { "s1", "s2" }, now or NOW))
	return f
end

local function info(overrides: { [string]: any }?): any
	local out: any = {
		userId = 42,
		defender = "b900",
		defenderName = "Mossling",
		defenderRank = 900,
		above = true,
		stronger = false,
		won = true,
		power = 30,
		seed = 7,
		requestId = "req-1",
	}
	for k, v in overrides or {} do
		out[k] = v
	end
	return out
end

local function out(seq: number, points: number, overrides: { [string]: any }?): any
	local o: any = { seq = seq, won = true, rankAfter = 900, climbed = 101, points = points }
	for k, v in overrides or {} do
		o[k] = v
	end
	return o
end

return function(T)
	T.test("a new farm has an empty Arena with every ticket", function()
		local f = FarmState.newFarm(NOW)
		T.same(f.arena, {
			points = 0,
			team = {},
			day = Season.dayOf(NOW),
			used = 0,
			seq = 0,
			claimed = {},
			history = {},
			quests = ArenaQuests.new(NOW),
			season = 202611,
			seasonWins = 0,
			bestRank = 0,
			defense = { wins = 0, streak = 0, best = 0 },
			week = Season.weekOf(NOW),
			bought = {},
			snapshotAt = 0,
		})
		T.eq(Rules.ticketsLeft(f, NOW), A.TicketsPerDay)
	end)

	T.test("tickets: ten a UTC day, used ones come back the next day", function()
		local f = farm()
		for i = 1, A.TicketsPerDay do
			local ok = Rules.beginAttack(f, NOW, info({ requestId = "r" .. i }))
			T.ok(ok)
			Rules.confirm(f, NOW, out(i, 5))
			T.eq(Rules.ticketsLeft(f, NOW), A.TicketsPerDay - i)
		end
		local ok, reason = Rules.beginAttack(f, NOW, info())
		T.eq(ok, false)
		T.eq(reason, "NO_TICKETS")
		local tomorrow = (Season.dayOf(NOW) + 1) * DAY
		T.eq(Rules.ticketsLeft(f, tomorrow), A.TicketsPerDay)
		T.eq(Rules.ticketsLeft(f, tomorrow - 1), 0, "23:59:59 is still the same day")
		T.ok((Rules.beginAttack(f, tomorrow, info())))
		T.eq(f.arena.used, 1)
		T.eq(f.arena.day, Season.dayOf(tomorrow))
	end)

	T.test("setTeam takes 1..TeamSize own living slimes, each once", function()
		local f = FarmKit.farm(NOW, FarmKit.many(6))
		f.slimes[6].ghostUntil = NOW + 60
		T.same({ Rules.setTeam(f, { "s1", "s2", "s3", "s4" }, NOW) }, { true })
		T.same(f.arena.team, { "s1", "s2", "s3", "s4" })
		T.same({ Rules.setTeam(f, {}, NOW) }, { false, "TEAM_SIZE" })
		T.same({ Rules.setTeam(f, { "s1", "s2", "s3", "s4", "s5" }, NOW) }, { false, "TEAM_SIZE" })
		T.same({ Rules.setTeam(f, { "s1", "s1" }, NOW) }, { false, "DUPLICATE" })
		T.same({ Rules.setTeam(f, { "s1", "nobody" }, NOW) }, { false, "NOT_OWNED" })
		T.same({ Rules.setTeam(f, { "s6" }, NOW) }, { false, "GHOST" })
		T.same({ Rules.setTeam(f, { "s6" }, NOW + 61) }, { true }, "a ghost that came back may fight")
		T.same({ Rules.setTeam(f, "s1", NOW) }, { false, "BAD_TEAM" })
		T.same({ Rules.setTeam(f, { x = "s1" }, NOW) }, { false, "BAD_TEAM" })
		T.same({ Rules.setTeam(f, { 5 }, NOW) }, { false, "BAD_TEAM" })
		T.same(f.arena.team, { "s6" }, "a refused team changes nothing")
		FarmState.removeSlime(f, "s6")
		T.same(f.arena.team, {}, "a sold slime leaves the Arena team")
	end)

	T.test("beginAttack refuses a second match, no tickets, the season's end and no team", function()
		local f = farm()
		local ok, reason, pending = Rules.beginAttack(f, NOW, info())
		T.eq(ok, true)
		T.eq(reason, nil)
		T.same(pending, {
			matchId = "42:1",
			seq = 1,
			season = 202611,
			defender = "b900",
			defenderName = "Mossling",
			defenderRank = 900,
			above = true,
			stronger = false,
			won = true,
			power = 30,
			seed = 7,
			at = NOW,
			sentAt = NOW,
			requestId = "req-1",
		})
		T.eq(f.arena.pending, pending)
		T.eq(f.arena.used, 1)
		local again, why, held = Rules.beginAttack(f, NOW + 1, info({ requestId = "req-1" }))
		T.eq(again, false)
		T.eq(why, "PENDING")
		T.eq(held, pending, "a re-sent request finds its own match")
		T.eq(held and held.requestId, "req-1")
		T.eq(f.arena.used, 1, "no second ticket")
		T.eq(f.arena.seq, 1, "no second match")

		local locked = farm(Season.seasonEnd(202611) - A.LockSeconds)
		local l1, lr = Rules.beginAttack(locked, Season.seasonEnd(202611) - A.LockSeconds, info())
		T.same({ l1, lr }, { false, "SEASON_ENDING" })
		local l2 = Rules.beginAttack(locked, Season.seasonEnd(202611) - A.LockSeconds - 1, info())
		T.eq(l2, true, "one second before the lock still fights")

		local alone = FarmKit.farm(NOW, FarmKit.many(2))
		T.same({ Rules.beginAttack(alone, NOW, info()) }, { false, "NO_TEAM" })
		alone.arena.team = { "gone" }
		T.same({ Rules.beginAttack(alone, NOW, info()) }, { false, "NO_TEAM" }, "a team of sold slimes is no team")
	end)

	T.test("confirm grants the match's points once, with quests, season wins and best rank", function()
		local f = farm()
		Rules.beginAttack(f, NOW, info({ stronger = true }))
		T.same({ Rules.confirm(f, NOW, out(2, 40)) }, { 0, {} }, "another match's outcome grants nothing")
		T.same({ Rules.confirm(f, NOW, nil) }, { 0, {} })
		T.ok(f.arena.pending ~= nil)
		local granted, grants = Rules.confirm(f, NOW + 20, out(1, 40))
		-- daily_win and weekly_stronger finish on the first win
		local quest = {}
		for _, q in A.Quests do
			quest[q.id] = q.points
		end
		T.eq(#grants, 2)
		T.eq(granted, 40 + quest.daily_win + quest.weekly_stronger)
		T.eq(f.arena.points, granted)
		T.eq(f.arena.seasonWins, 1)
		T.eq(f.arena.bestRank, 900)
		T.eq(f.arena.pending, nil)
		T.same({ Rules.confirm(f, NOW + 21, out(1, 40)) }, { 0, {} }, "the same outcome twice grants once")
		T.eq(f.arena.points, granted)
		-- a loss: participation points, no win, best rank kept when lower is not reached
		Rules.beginAttack(f, NOW + 30, info({ requestId = "req-2", won = false }))
		T.eq(Rules.confirm(f, NOW + 40, out(2, A.LossPoints, { won = false, rankAfter = 950 })), A.LossPoints)
		T.eq(f.arena.seasonWins, 1)
		T.eq(f.arena.bestRank, 900)
		-- a void outcome is a void
		Rules.beginAttack(f, NOW + 50, info({ requestId = "req-3" }))
		T.eq(Rules.confirm(f, NOW + 60, out(3, 0, { void = true })), 0)
		T.eq(f.arena.pending, nil)
		T.eq(f.arena.used, 2, "the void gave its ticket back")
	end)

	T.test("void clears the match; the ticket comes back only on the same UTC day", function()
		local f = farm()
		T.same({ Rules.void(f, NOW) }, { false, false })
		Rules.beginAttack(f, NOW, info())
		T.same({ Rules.void(f, NOW + 600) }, { true, true })
		T.eq(f.arena.used, 0)
		T.eq(f.arena.pending, nil)
		Rules.beginAttack(f, NOW, info({ requestId = "req-2" }))
		T.same({ Rules.void(f, NOW + DAY) }, { true, false })
		T.eq(f.arena.used, 1, "yesterday's ticket stays used")
		T.eq(f.arena.seq, 2, "a void match keeps its number")
	end)

	T.test("settle: confirm on the same seq, void when final or passed, resend after ResendSeconds", function()
		local f = farm()
		T.eq(Rules.settle(f, nil, 42, NOW), "none")
		Rules.beginAttack(f, NOW, info())
		local doc: any = { season = 202611, players = {} }
		T.eq(Rules.settle(f, nil, 42, NOW), "wait")
		T.eq(
			Rules.settle(f, { season = 202610, players = {} }, 42, NOW),
			"wait",
			"another season's ladder says nothing"
		)
		T.eq(Rules.settle(f, doc, 42, NOW + A.ResendSeconds - 1), "wait")
		T.eq(Rules.settle(f, doc, 42, NOW + A.ResendSeconds), "resend")
		Rules.markSent(f, NOW + A.ResendSeconds)
		T.eq(Rules.settle(f, doc, 42, NOW + A.ResendSeconds + 1), "wait")
		doc.players["42"] = { n = "P", p = 1, sp = 25, dw = 0, seq = 1, out = out(1, 25) }
		local action, o = Rules.settle(f, doc, 42, NOW)
		T.eq(action, "confirm")
		T.eq(o and o.points, 25)
		doc.players["42"] = { n = "P", p = 1, sp = 25, dw = 0, seq = 2, out = out(2, 25) }
		T.eq(Rules.settle(f, doc, 42, NOW), "void", "the ladder moved past this match")
		doc.players["42"] = nil
		doc.final = true
		T.eq(Rules.settle(f, doc, 42, NOW), "void")
	end)

	T.test("result and syncSeq: the ladder result of the match in flight, a number never behind the ladder", function()
		local f = farm()
		T.eq(Rules.result(f, 42, "P"), nil)
		Rules.beginAttack(f, NOW, info())
		T.same(Rules.result(f, 42, "Pip"), {
			attacker = "42",
			seq = 1,
			defender = "b900",
			won = true,
			above = true,
			season = 202611,
			name = "Pip",
			power = 30,
		})
		T.eq(Rules.syncSeq(f, 0), false)
		T.eq(Rules.syncSeq(f, 7), true)
		T.eq(f.arena.seq, 7)
	end)

	T.test("season rewards are claimed once, written in the history", function()
		local f = farm()
		Rules.beginAttack(f, NOW, info())
		Rules.confirm(f, NOW, out(1, 40, { rankAfter = 2 }))
		local before = f.arena.points
		-- the next season starts: this one's wins wait in the history for the reward
		local december = Season.seasonStart(202612) + Config.Arena.FinalizeSeconds
		T.eq(Rules.newSeason(f, 202612), true)
		T.eq(Rules.newSeason(f, 202612), false)
		T.eq(f.arena.seasonWins, 0)
		T.eq(f.arena.bestRank, 0)
		T.same(f.arena.history, { { season = 202611, rank = 0, wins = 1 } })
		T.same(Rules.unclaimed(f, december - 1), { 202610, 202609 }, "202611 is not final yet")
		T.same(Rules.unclaimed(f, december), { 202611, 202610, 202609 })
		local points, badge = Rules.claimSeason(f, 202611, 2)
		T.eq(points, 750)
		T.eq(badge, "Podium")
		T.eq(f.arena.points, before + 750)
		T.same(f.arena.history, { { season = 202611, rank = 2, badge = "Podium", wins = 1 } })
		T.same({ Rules.claimSeason(f, 202611, 1) }, { 0 }, "twice grants once")
		T.eq(f.arena.points, before + 750)
		T.same(Rules.unclaimed(f, december), { 202610, 202609 })
		-- a season without a rank is marked claimed and pays nothing
		T.same({ Rules.claimSeason(f, 202610, nil) }, { 0 })
		T.eq(f.arena.claimed["202610"], true)
		T.eq(#f.arena.history, 1)
		-- the claimed map keeps the newest KeepSeasons seasons
		for season = 202501, 202512 do
			Rules.claimSeason(f, season, 600)
		end
		local count = 0
		for key in f.arena.claimed do
			count += 1
			T.ok(tonumber(key) >= 202512 - A.KeepSeasons + 3, "kept " .. key)
		end
		T.eq(count, A.KeepSeasons)
	end)

	T.test("repair keeps a sound Arena, mends each damaged part alone and never throws", function()
		local f = farm()
		Rules.beginAttack(f, NOW, info())
		f.arena.claimed["202610"] = true
		f.arena.history = { { season = 202610, rank = 3, badge = "Podium", wins = 4 } }
		f.arena.bought = { sticker = 2 }
		local kept = FarmState.repair(f, NOW)
		T.same(kept.arena, f.arena)
		T.same(FarmState.repair(kept, NOW).arena, kept.arena, "repairing a repaired farm changes nothing")

		local broken: any = farm()
		broken.arena.team = { "s1", "s1", "ghost", "s2", "s3", "s4", "s5" }
		broken.arena.points = -5
		broken.arena.used = 99
		broken.arena.seq = 0
		broken.arena.pending = { matchId = "42:3", seq = 3, season = 202611, defender = "b9", at = NOW, won = "yes" }
		broken.arena.claimed = { ["202611"] = true, x = true, ["202610"] = "yes" }
		broken.arena.history = { "x", { season = 202609, rank = -1, wins = 2 }, { season = 202609 } }
		broken.arena.quests = { day = "x", counts = { daily_win = 99, nope = 3 }, done = { daily_win = true } }
		broken.arena.defense = "x"
		broken.arena.bought = { a = -1, b = 2.5, [3] = 1 }
		local fixed = FarmState.repair(broken, NOW).arena
		T.same(fixed.team, { "s1", "s2", "s3", "s4" })
		T.eq(fixed.points, 0)
		T.eq(fixed.used, A.TicketsPerDay)
		T.eq(fixed.seq, 3, "the number catches up with the match in flight")
		T.eq(fixed.pending and fixed.pending.won, false)
		T.eq(fixed.pending and fixed.pending.sentAt, NOW)
		T.same(fixed.claimed, { ["202611"] = true })
		T.same(fixed.history, { { season = 202609, rank = 0, wins = 2 } })
		T.eq(fixed.quests.day, Season.dayOf(NOW))
		T.same(fixed.quests.counts, { daily_win = 1 })
		T.same(fixed.quests.done, { daily_win = true })
		T.same(fixed.defense, { wins = 0, streak = 0, best = 0 })
		T.same(fixed.bought, { b = 2 })

		local lost: any = farm()
		lost.arena.pending = { seq = "x" }
		local dropped, warnings = FarmState.repair(lost, NOW)
		T.eq(dropped.arena.pending, nil)
		T.ok(string.find(table.concat(warnings, ";"), "match in flight", 1, true) ~= nil)
		for _, bad in { "x", 5, true, { team = 5, history = 5, claimed = 5, quests = 5, pending = 5 } } do
			local g: any = farm()
			g.arena = bad
			local ok, repaired = pcall(FarmState.repair, g, NOW)
			T.ok(ok, "repair threw on " .. tostring(bad))
			T.eq(type(repaired.arena), "table")
		end
	end)

	T.test("a schema 10 save migrates to 11 with an empty Arena, keeping everything else", function()
		T.eq(Config.Save.SchemaVersion, 11)
		local old: any = FarmState.newFarm(NOW)
		old.arena = nil
		old.coins = 4242
		old.dungeon = { best = 3 }
		local load =
			ProfileLogic.prepareLoad({ schemaVersion = 10, savedAt = NOW, data = old }, FarmSave.hooks(), NOW + 5)
		T.ok(load.ok and load.migrated)
		T.eq(load.fromVersion, 10)
		T.eq(load.data.coins, 4242)
		T.same(load.data.dungeon, { best = 3 })
		T.same(load.data.arena, FarmState.newArena(NOW + 5))
		T.eq(old.arena, nil, "migration never alters the stored snapshot")
	end)
end
