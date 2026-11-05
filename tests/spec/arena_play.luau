--!strict
-- shared/ArenaPlay: the pure parts of the Arena's server service.
local ArenaBots = require("../../src/shared/ArenaBots")
local ArenaFight = require("../../src/shared/ArenaFight")
local ArenaLadder = require("../../src/shared/ArenaLadder")
local ArenaPlay = require("../../src/shared/ArenaPlay")
local ArenaSeason = require("../../src/shared/ArenaSeason")
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local ProfileLogic = require("../../src/shared/ProfileLogic")

local A = Config.Arena
local SEASON = 202611
local NOW = ArenaSeason.seasonStart(SEASON) + 9 * 86400 + 12 * 3600

-- slimes s1..s6 with growing stats (s6 the strongest)
local function farmOfSix(): any
	local slimes = {}
	for i = 1, 6 do
		table.insert(slimes, FarmKit.slime("s" .. i, { stats = { attack = i, defence = i, speed = i, hp = 10 * i } }))
	end
	return FarmKit.farm(NOW, slimes)
end

return function(T: any)
	T.test("a request id is a short plain string", function()
		T.ok(ArenaPlay.validRequestId("tap-1"))
		T.ok(ArenaPlay.validRequestId("dbg:12.5_a"))
		T.ok(not ArenaPlay.validRequestId(""))
		T.ok(not ArenaPlay.validRequestId(string.rep("a", A.RequestIdMaxLength + 1)))
		T.ok(ArenaPlay.validRequestId(string.rep("a", A.RequestIdMaxLength)))
		T.ok(not ArenaPlay.validRequestId(12))
		T.ok(not ArenaPlay.validRequestId("a b"))
		T.ok(not ArenaPlay.validRequestId("x\n"))
	end)

	T.test("the best team is the four strongest slimes that are not ghosts", function()
		local farm = farmOfSix()
		T.same(ArenaPlay.bestTeam(farm, NOW), { "s6", "s5", "s4", "s3" })
		farm.slimes[5].ghostUntil = NOW + 60
		T.same(ArenaPlay.bestTeam(farm, NOW), { "s6", "s4", "s3", "s2" })
		-- a ghost in the team does not fight
		farm.arena.team = { "s6", "s5" }
		T.same(ArenaPlay.fightTeam(farm, NOW), { "s6" })
		T.same(ArenaPlay.fightTeam(farm, NOW + 61), { "s6", "s5" })
		T.eq(ArenaPlay.teamKey({ "s6", "s5" }), "s6,s5")
	end)

	T.test("a snapshot survives the store's round trip; a broken one is refused, its power never trusted", function()
		local farm = farmOfSix()
		local snap = assert(ArenaPlay.snapshotDoc(farm, { "s6", "s1" }, "Pip"))
		T.eq(snap.name, "Pip")
		T.eq(snap.v, A.SnapshotVersion)
		T.eq(#snap.fighters, 2)
		T.eq(snap.power, ArenaFight.power(snap.fighters))
		local back = assert(ArenaPlay.cleanSnapshot(ProfileLogic.deepCopy(snap)))
		T.same(back, snap)
		T.eq(ArenaPlay.snapshotDoc(farm, {}, "Pip"), nil)
		T.eq(ArenaPlay.snapshotDoc(farm, { "s1", "s1" }, "Pip"), nil)
		T.eq(ArenaPlay.snapshotDoc(farm, { "nope" }, "Pip"), nil)
		T.eq(ArenaPlay.cleanSnapshot(nil), nil)
		T.eq(ArenaPlay.cleanSnapshot({ fighters = {}, looks = {} }), nil)
		local function broken(change: (any) -> ()): any
			local copy = ProfileLogic.deepCopy(snap)
			change(copy)
			return ArenaPlay.cleanSnapshot(copy)
		end
		T.eq(
			broken(function(s)
				s.fighters[2].id = s.fighters[1].id
			end),
			nil,
			"a repeated id"
		)
		T.eq(
			broken(function(s)
				s.fighters[1].attack = 0 / 0
			end),
			nil,
			"NaN"
		)
		T.eq(
			broken(function(s)
				s.fighters[1].hp = 0
			end),
			nil,
			"no hp"
		)
		T.eq(
			broken(function(s)
				s.looks[2] = nil
			end),
			nil,
			"a look missing"
		)
		T.eq(
			broken(function(s)
				for _ = 1, A.TeamSize do
					table.insert(s.fighters, s.fighters[1])
					table.insert(s.looks, s.looks[1])
				end
			end),
			nil,
			"too many"
		)
		local cheat = assert(broken(function(s)
			s.power = 999999
		end))
		T.eq(cheat.power, snap.power)
	end)

	T.test("offered opponents: NPCs field their season team; an unreadable player gives way to a champion", function()
		local doc = ArenaLadder.new(SEASON)
		ArenaLadder.join(doc, "101", "Mia", 30)
		ArenaLadder.join(doc, "102", "Leo", 30)
		local farm = farmOfSix()
		local snap = assert(ArenaPlay.snapshotDoc(farm, { "s6", "s5" }, "Old name"))
		local reads = {}
		local picks = {
			{ id = "b10", rank = 10, above = true },
			{ id = "101", rank = 1001, above = true },
			{ id = "102", rank = 1002, above = false },
			{ id = "c1", above = false },
		}
		local list = ArenaPlay.offer(doc, picks, SEASON, function(userId: number): any
			table.insert(reads, userId)
			return if userId == 101 then snap else nil
		end)
		T.same(reads, { 101, 102 })
		T.eq(#list, #picks, "the list keeps its length")
		T.eq(list[1].id, "b10")
		T.eq(list[1].name, ArenaBots.name("b10"))
		T.eq(list[1].power, ArenaBots.team(SEASON, "b10").power)
		T.eq(#list[1].fighters, A.TeamSize)
		T.eq(list[2].id, "101")
		T.eq(list[2].name, "Mia", "the ladder's name")
		T.eq(list[2].power, snap.power)
		T.eq(list[2].above, true)
		T.eq(list[3].id, "c1")
		T.eq(list[4].id, "c2", "the champion already offered is not offered twice")
		T.eq(list[4].rank, nil)
		local shown = ArenaPlay.public(list[2])
		T.eq(shown.fighters, nil, "the fighters stay on the server")
		T.eq(shown.name, "Mia")
		T.eq(ArenaPlay.find(list, "101"), list[2])
		T.eq(ArenaPlay.find(list, "103"), nil)
		local info = ArenaPlay.attackInfo(7, list[1], true, list[1].power - 1, 42, "tap-1")
		T.eq(info.stronger, true)
		T.eq(info.defenderRank, 10)
		T.eq(ArenaPlay.attackInfo(7, list[3], true, 1e9, 42, "tap-1").defenderRank, 0)
		T.eq(ArenaPlay.attackInfo(7, list[3], true, 1e9, 42, "tap-1").stronger, false)
	end)

	T.test("quest progress of a day, week or season that is over reads 0", function()
		local farm = farmOfSix()
		local q = farm.arena.quests
		q.counts.daily_win, q.done.daily_win = 1, true
		q.counts.weekly_wins = 3
		q.counts.season_10 = 4
		local function find(list: any, id: string): any
			for _, row in list do
				if row.id == id then
					return row
				end
			end
			return nil
		end
		local today = ArenaPlay.quests(farm, NOW)
		T.eq(#today, #A.Quests)
		T.eq(find(today, "daily_win").count, 1)
		T.eq(find(today, "daily_win").done, true)
		T.eq(find(today, "weekly_wins").count, 3)
		local tomorrow = ArenaPlay.quests(farm, NOW + 86400)
		T.eq(find(tomorrow, "daily_win").count, 0)
		T.eq(find(tomorrow, "daily_win").done, false)
		T.eq(find(tomorrow, "season_10").count, 4)
		local nextSeason = ArenaPlay.quests(farm, ArenaSeason.seasonEnd(SEASON) + 60)
		T.eq(find(nextSeason, "season_10").count, 0)
	end)

	T.test("the pending summary and the top of the ladder", function()
		local farm = farmOfSix()
		T.eq(ArenaPlay.pendingSummary(farm), nil)
		farm.arena.pending = {
			matchId = "7:3",
			seq = 3,
			season = SEASON,
			defender = "b5",
			defenderName = "Rival X",
			defenderRank = 5,
			above = true,
			stronger = false,
			won = true,
			power = 10,
			seed = 1,
			at = NOW,
			sentAt = NOW,
			requestId = "tap",
		}
		T.same(
			ArenaPlay.pendingSummary(farm),
			{ matchId = "7:3", won = true, defenderName = "Rival X", status = "confirming" }
		)
		local doc = ArenaLadder.new(SEASON)
		ArenaLadder.join(doc, "101", "Mia", 30)
		table.remove(doc.order)
		table.insert(doc.order, 2, "101")
		doc.players["101"].sp = 55
		local top = ArenaPlay.top(doc, 3)
		T.eq(#top, 3)
		T.same(top[2], { rank = 2, id = "101", name = "Mia", power = 30, points = 55 })
		T.eq(top[1].name, ArenaBots.name("b1"))
		T.eq(top[3].id, "b2")
		T.eq(top[3].rank, 3)
	end)

	T.test("log entries: the defender gets one only when it is a player", function()
		local pending = { matchId = "7:3", defender = "101", defenderName = "Mia" }
		local mine, theirs = ArenaPlay.logEntries(pending, { won = true, rankAfter = 4 }, "7", "Pip", 30, NOW)
		T.same(
			mine,
			{ kind = "attack", at = NOW, matchId = "7:3", vs = "Mia", vsId = "101", won = true, points = 30, rank = 4 }
		)
		T.same(theirs, { kind = "defence", at = NOW, matchId = "7:3", vs = "Pip", vsId = "7", held = false })
		local _, none = ArenaPlay.logEntries(
			{ matchId = "7:4", defender = "b9", defenderName = "R" },
			{ won = false },
			"7",
			"Pip",
			5,
			NOW
		)
		T.eq(none, nil)
	end)

	T.test("defence counters: wins from the ladder, the streak from the log's tail, the best kept", function()
		local farm = farmOfSix()
		local d = farm.arena.defense
		local function entry(held: boolean): any
			return { kind = "defence", held = held }
		end
		T.eq(ArenaPlay.applyDefence(farm, 3, { entry(false), entry(true), { kind = "attack" }, entry(true) }), true)
		T.same(d, { wins = 3, streak = 2, best = 2 })
		T.eq(ArenaPlay.applyDefence(farm, 3, nil), false, "nothing new")
		-- a log with no loss in it never shortens the streak
		d.streak, d.best = 12, 12
		ArenaPlay.applyDefence(farm, nil, { entry(true), entry(true) })
		T.eq(d.streak, 12)
		ArenaPlay.applyDefence(farm, nil, { entry(true), entry(false) })
		T.eq(d.streak, 0)
		T.eq(d.best, 12)
		T.eq(d.wins, 3)
		ArenaPlay.applyDefence(farm, 0 / 0, nil)
		T.eq(d.wins, 3, "a broken number is ignored")
	end)
end
