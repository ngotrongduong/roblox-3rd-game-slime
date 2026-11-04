--!strict
-- Several simulated servers sharing ONE DataStore (tests/lib/FakeDataStore) and ONE MemoryStore (server/ArenaMemory), on a
-- fake clock; the attacker's side is played by shared/ArenaRules as the server service will.
local ArenaLadder = require("../../src/shared/ArenaLadder")
local ArenaMemory = require("../../src/server/ArenaMemory")
local ArenaStore = require("../../src/server/ArenaStore")
local Config = require("../../src/shared/Config")
local Fake = require("../lib/FakeDataStore")
local FarmKit = require("../lib/FarmKit")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rng = require("../../src/shared/Rng")
local Rules = require("../../src/shared/ArenaRules")
local Season = require("../../src/shared/ArenaSeason")

local A = Config.Arena
local SEASON = 202611
-- 2026-11-10 12:00 UTC
local NOW = Season.seasonStart(SEASON) + 9 * 86400 + 12 * 3600
local KEY = ArenaStore.ladderKey(SEASON)

local function newWorld(start: number): any
	local w: any = { now = start, lines = {} }
	local function clock(): number
		return w.now
	end
	w.backing = Fake.newBacking()
	w.memory = ArenaMemory.new(clock)
	w.queue = w.memory:GetQueue(A.QueueName, A.InvisibleSeconds)
	-- a server; `data` may wrap its fake DataStore
	function w.server(id: string, wrap: ((any) -> any)?): any
		local fake = Fake.new(w.backing)
		local data = if wrap then wrap(fake) else fake
		return {
			id = id,
			fake = fake,
			data = data,
			store = ArenaStore.new({
				data = data,
				queue = w.queue,
				lease = w.memory:GetHashMap(A.LeaseMapName),
				serverId = id,
				clock = clock,
				log = function(line: string)
					table.insert(w.lines, line)
				end,
			}),
		}
	end
	function w.player(server: any, userId: number): any
		local farm = FarmKit.farm(w.now, FarmKit.many(4))
		assert(Rules.setTeam(farm, { "s1", "s2" }, w.now))
		return { id = userId, name = "P" .. userId, farm = farm, server = server, ladder = 0, granted = 0, confirms = 0 }
	end
	-- the attack request of the server service: the fight's result is given; a new match is sent to the queue
	function w.attack(
		p: any,
		defender: string,
		won: boolean,
		requestId: string?,
		above: boolean?
	): (boolean, string?, any)
		local ok, reason, pending = Rules.beginAttack(p.farm, w.now, {
			userId = p.id,
			defender = defender,
			defenderName = defender,
			defenderRank = 0,
			above = if above == nil then true else above,
			stronger = false,
			won = won,
			power = 10,
			seed = 1,
			requestId = requestId or ("r" .. p.id .. "-" .. (p.farm.arena.seq + 1)),
		})
		if ok then
			p.server.store.submit(Rules.result(p.farm, p.id, p.name))
		end
		return ok, reason, pending
	end
	-- the attacker's server looking at the ladder for its match in flight
	function w.settle(p: any, maxAge: number?): string
		local pending = p.farm.arena.pending
		if not pending then
			return "none"
		end
		local doc = p.server.store.readLadder(pending.season, maxAge or 0)
		local action, out = Rules.settle(p.farm, doc, p.id, w.now)
		if action == "confirm" and out then
			p.granted += Rules.confirm(p.farm, w.now, out)
			p.ladder += out.points
			p.confirms += 1
		elseif action == "void" then
			Rules.void(p.farm, w.now)
		elseif action == "resend" then
			p.server.store.submit(assert(Rules.result(p.farm, p.id, p.name)))
			Rules.markSent(p.farm, w.now)
		end
		return action
	end
	-- every server's leader tick; returns the ids that lead after it
	function w.tick(servers: { any }): { string }
		local leaders = {}
		for _, s in servers do
			if s.store.leaderTick(w.now).leader then
				table.insert(leaders, s.id)
			end
		end
		return leaders
	end
	function w.doc(season: number?): any
		return w.backing.values[ArenaStore.ladderKey(season or SEASON)]
	end
	return w
end

-- No id twice in the order, every player's metadata once in it.
local function consistent(T: any, doc: any)
	local seen = {}
	for _, id in doc.order do
		T.ok(not seen[id], "twice in the order: " .. id)
		seen[id] = true
	end
	for id in doc.players do
		T.ok(seen[id], "a player missing from the order: " .. id)
	end
end

return function(T)
	T.test("one leader at a time; another takes over within the lease when it stops", function()
		local w = newWorld(NOW)
		local a, b, c = w.server("A"), w.server("B"), w.server("C")
		T.same(w.tick({ a, b, c }), { "A" })
		local lastRenew = w.now
		for _ = 1, 6 do
			w.now += 5
			T.same(w.tick({ a, b, c }), { "A" })
			lastRenew = w.now
		end
		-- A stops (a crash): B or C leads once the lease runs out, never earlier
		local takeover: number? = nil
		while not takeover do
			w.now += 5
			local leaders = w.tick({ b, c })
			T.ok(#leaders <= 1, "two leaders")
			if #leaders == 1 then
				takeover = w.now
				T.eq(leaders[1], "B")
			end
			T.ok(w.now - lastRenew <= A.LeaseSeconds + 5, "nobody took over")
		end
		T.ok((takeover :: number) - lastRenew >= A.LeaseSeconds, "taken over before the lease ran out")
		-- A comes back: it sees B's lease and steps down
		w.now += 5
		T.same(w.tick({ a, b, c }), { "B" })
		T.eq(a.store.isLeader(), false)
	end)

	T.test("two attacks back to back: one match, the second is PENDING with the same request", function()
		local w = newWorld(NOW)
		local s = w.server("A")
		local p = w.player(s, 101)
		local ok1 = w.attack(p, "b1000", true, "tap-1")
		local ok2, reason, held = w.attack(p, "b999", true, "tap-2")
		T.eq(ok1, true)
		T.eq(ok2, false)
		T.eq(reason, "PENDING")
		T.eq(held.requestId, "tap-1")
		-- the same request re-sent is recognised by its id, and no second match is made
		local ok3, reason3, again = w.attack(p, "b1000", true, "tap-1")
		T.eq(ok3, false)
		T.eq(reason3, "PENDING")
		T.eq(again.requestId, "tap-1", "the caller sees its own request in flight")
		T.eq(w.queue.size(), 1)
		T.eq(p.farm.arena.used, 1)
		w.tick({ s })
		T.eq(w.settle(p), "confirm")
		T.eq(p.ladder, Season.winPoints(true, 1, true))
		T.eq(w.doc().players["101"].sp, p.ladder)
		T.eq(w.queue.size(), 0)
	end)

	T.test("a write that errors after it was stored: items come back as dup, nothing counted twice", function()
		local w = newWorld(NOW)
		local function flaky(fake: any): any
			local proxy: any = setmetatable({ errorsAfter = 0 }, { __index = fake })
			function proxy.UpdateAsync(_self: any, key: string, transform: any): any
				local result = fake:UpdateAsync(key, transform)
				if key == KEY and proxy.errorsAfter > 0 then
					proxy.errorsAfter -= 1
					error("502: timed out after the write (fake)")
				end
				return result
			end
			return proxy
		end
		local s = w.server("A", flaky)
		local p1, p2 = w.player(s, 101), w.player(s, 102)
		w.attack(p1, "b1000", true)
		w.attack(p2, "b999", false)
		s.data.errorsAfter = 1
		local first = s.store.leaderTick(w.now)
		T.eq(first.ok, false)
		T.eq(w.backing.writes, 1, "the write did happen")
		T.eq(w.queue.size(), 2, "nothing removed")
		-- the attacker's server already sees the outcome and grants it
		T.eq(w.settle(p1), "confirm")
		T.eq(w.settle(p2), "confirm")
		-- the leader waits out the invisibility window, reads the same items again and finds them applied
		w.now += 15
		T.eq(s.store.leaderTick(w.now).read, 0, "nothing read before the items come back")
		w.now += A.InvisibleSeconds
		local again = s.store.leaderTick(w.now)
		T.eq(again.ok, true)
		T.eq(again.read, 2)
		T.eq(again.dup, 2)
		T.eq(again.applied, 0)
		T.eq(again.writes, 0, "nothing changed, nothing written")
		T.eq(w.backing.writes, 1)
		T.eq(w.queue.size(), 0)
		local doc = w.doc()
		T.eq(doc.players["101"].sp, p1.ladder)
		T.eq(doc.players["102"].sp, p2.ladder)
		T.eq(doc.players["101"].seq, 1)
		T.eq(p1.confirms, 1)
		T.eq(p1.farm.arena.points, p1.granted, "points granted once")
		T.eq(w.settle(p1), "none")
		consistent(T, doc)
	end)

	T.test("a lost queue item is sent again after ResendSeconds and applied once", function()
		local w = newWorld(NOW)
		local s = w.server("A")
		local p = w.player(s, 101)
		w.queue.dropNext(1)
		w.attack(p, "b1000", true)
		T.eq(w.queue.size(), 0, "the message was lost")
		for _ = 1, 3 do
			w.now += 15
			w.tick({ s })
			if w.now - p.farm.arena.pending.at < A.ResendSeconds then
				T.eq(w.settle(p), "wait")
			end
		end
		w.now += 15
		T.eq(w.settle(p), "resend")
		-- a second copy also arrives (a resend racing a slow first send): still one match
		s.store.submit(assert(Rules.result(p.farm, p.id, p.name)))
		T.eq(w.queue.size(), 2)
		local info = s.store.leaderTick(w.now)
		T.eq(info.applied, 1)
		T.eq(info.dup, 1)
		T.eq(w.settle(p), "confirm")
		T.eq(p.confirms, 1)
		T.eq(w.doc().players["101"].sp, p.ladder)
		T.eq(p.ladder, Season.winPoints(true, 1, true))
	end)

	T.test("the order changed between the fight and the apply: points by the real climb", function()
		local w = newWorld(NOW)
		local s = w.server("A")
		local p1, p2 = w.player(s, 101), w.player(s, 102)
		-- 101 then 102 join under the bots: ranks 1001, 1002
		s.store.join("101", "P101", 10)
		s.store.join("102", "P102", 10)
		w.tick({ s })
		local doc = s.store.readLadder(SEASON, 0)
		T.eq(ArenaLadder.rankOf(doc, "101"), 1001)
		T.eq(ArenaLadder.rankOf(doc, "102"), 1002)
		-- 102 fights b999 at rank 999 (a climb of 3 when it fought); before its result is applied, 101 (between them)
		-- beats b998 and lands above b999, pushing b999 down one: 102 climbs only 2, and is paid for 2
		w.attack(p1, "b998", true)
		w.attack(p2, "b999", true)
		w.now += 15
		w.tick({ s })
		local after = s.store.readLadder(SEASON, 0)
		T.eq(ArenaLadder.rankOf(after, "101"), 998)
		T.eq(ArenaLadder.rankOf(after, "b998"), 999)
		T.eq(ArenaLadder.rankOf(after, "102"), 1000, "not the 999 it fought for")
		T.eq(ArenaLadder.rankOf(after, "b999"), 1001)
		T.eq(w.settle(p1), "confirm")
		T.eq(w.settle(p2), "confirm")
		T.eq(p1.ladder, Season.winPoints(true, 3, true))
		T.eq(p2.ladder, Season.winPoints(true, 2, true), "points by the real climb")
		T.ok(p2.ladder < Season.winPoints(true, 3, true))
		T.eq(after.players["102"].out.climbed, 2)
		-- a champion is never on the ladder: a win over one never climbs
		w.attack(p2, "c1", true, nil, false)
		w.now += 15
		w.tick({ s })
		local before = p2.ladder
		T.eq(w.settle(p2), "confirm")
		T.eq(p2.ladder - before, Season.winPoints(true, 0, false))
		local final = s.store.readLadder(SEASON, 0)
		T.eq(ArenaLadder.rankOf(final, "102"), 1000)
		T.eq(final.players["101"].sp, p1.ladder)
		T.eq(final.players["102"].sp, p2.ladder)
		consistent(T, final)
	end)

	T.test("season end: a match begun before the lock lands in the old season; one sent after final is void", function()
		local finish = Season.seasonEnd(SEASON)
		local w = newWorld(finish - 600)
		local s = w.server("A")
		local p1, p2, p3 = w.player(s, 101), w.player(s, 102), w.player(s, 103)
		-- 101 attacks 6 minutes before the end, 102 and 103 at 5 min 10 s (before the lock); 102's and 103's results are lost
		w.now = finish - 360
		T.eq(w.attack(p1, "b1000", true), true)
		w.now = finish - 310
		w.queue.dropNext(2)
		T.eq(w.attack(p2, "b1000", true), true)
		T.eq(w.attack(p3, "b999", true), true)
		-- inside the lock nobody begins a match
		w.now = finish - 10
		local late = w.player(s, 104)
		T.same({ w.attack(late, "b1000", true) }, { false, "SEASON_ENDING" })
		-- 23:59:50 on the last day: the leader applies 101's result to the old season
		w.tick({ s })
		T.eq(w.settle(p1), "confirm")
		T.eq(p1.farm.arena.seasonWins, 1)
		-- after midnight: 102 sends again and is applied to the old season before final
		w.now = finish + 60
		T.eq(w.settle(p2), "resend")
		w.tick({ s })
		T.eq(w.settle(p2), "confirm")
		T.eq(p2.confirms, 1)
		T.eq(p2.farm.arena.seasonWins, 1, "counted in the old season")
		-- final: the leader closes the season by itself
		w.now = Season.finalAt(SEASON)
		w.tick({ s })
		T.eq(w.doc().final, true)
		local closed = ProfileLogic.deepCopy(w.doc())
		-- 103's server was busy: its resend reaches the queue only after final; the leader voids it and writes nothing
		w.now = Season.finalAt(SEASON) + 30
		s.store.submit(assert(Rules.result(p3.farm, p3.id, p3.name)))
		local info = s.store.leaderTick(w.now)
		T.eq(info.void, 1)
		T.eq(info.writes, 0, "a void result changes nothing")
		T.same(w.doc(), closed)
		T.eq(w.settle(p3), "void")
		T.eq(p3.farm.arena.pending, nil)
		T.eq(p3.farm.arena.used, 1, "used on another UTC day: not given back")
		T.eq(p3.confirms, 0)
		T.eq(w.doc().players["103"], nil)
		-- the same void on the day it was used gives the ticket back (shared/ArenaRules.void)
		local same = w.player(s, 105)
		w.now = Season.finalAt(SEASON) + 60
		w.queue.dropNext(1)
		w.attack(same, "b1000", true)
		local doc = { season = SEASON + 1, players = {}, final = true }
		T.eq(Rules.settle(same.farm, doc, 105, w.now), "void")
		T.same({ Rules.void(same.farm, w.now) }, { true, true })
		T.eq(same.farm.arena.used, 0)
		consistent(T, w.doc())
	end)

	T.test("season rewards are claimed once even when two logins both claim", function()
		local finish = Season.seasonEnd(SEASON)
		local w = newWorld(finish - 900)
		local s = w.server("A")
		local p = w.player(s, 101)
		w.attack(p, "b1", true)
		w.tick({ s })
		w.settle(p)
		w.now = Season.finalAt(SEASON)
		w.tick({ s })
		local doc = s.store.readLadder(SEASON, 0)
		T.eq(doc.final, true)
		local rank = ArenaLadder.rankOf(doc, "101")
		T.eq(rank, 1)
		-- login 1 claims and saves; login 2 (another server, the saved farm) claims again
		local function login(farm: any): number
			local total = 0
			for _, season in Rules.unclaimed(farm, w.now) do
				local ladder = s.store.readLadder(season, 60)
				if ladder and ladder.final then
					total += Rules.claimSeason(farm, season, ArenaLadder.rankOf(ladder, "101"))
				end
			end
			Rules.newSeason(farm, Season.seasonOf(w.now))
			return total
		end
		local first = login(p.farm)
		T.eq(first, (Season.rewardFor(1)))
		local saved = ProfileLogic.deepCopy(p.farm)
		w.now += 60
		T.eq(login(saved), 0)
		T.eq(saved.arena.points, p.farm.arena.points)
		T.same(saved.arena.history, { { season = SEASON, rank = 1, badge = "Champion", wins = 1 } })
	end)

	-- `serverCount` servers x 10 players, each attacking once a minute (10 matches a minute a server) for 5 minutes, then
	-- settling. Returns the most ladder bytes and writes in a minute, and the final ladder.
	local function load(T: any, prefill: number, serverCount: number): (number, number, any)
		local w = newWorld(NOW)
		if prefill > 0 then
			local doc = ArenaLadder.new(SEASON)
			for i = 1, prefill do
				ArenaLadder.join(doc, tostring(900000 + i), "Filler " .. i, 20)
			end
			Fake.new(w.backing).put(KEY, doc)
		end
		local servers, players = {}, {}
		for i = 1, serverCount do
			local s = w.server("S" .. i)
			table.insert(servers, s)
			for j = 1, 10 do
				local p = w.player(s, i * 100 + j)
				p.offset = ((i * 10 + j) * 7) % 60
				table.insert(players, p)
			end
		end
		local rng = Rng.new(2026)
		local minuteBytes: { number } = {}
		local minuteWrites: { number } = {}
		local function ladder(): (number, number)
			local bytes, writes = 0, 0
			for _, s in servers do
				bytes += s.store.stats.bytes[KEY] or 0
				writes += s.store.stats.writes[KEY] or 0
			end
			return bytes, writes
		end
		local start = w.now
		local lastBytes, lastWrites = ladder()
		local attacks = 0
		for step = 0, (7 * 60) / 5 - 1 do
			w.now = start + step * 5
			local attacking = w.now - start < 5 * 60
			for _, p in players do
				if p.farm.arena.pending then
					w.settle(p, 10)
				elseif attacking and (w.now - start) % 60 == p.offset - p.offset % 5 then
					local doc = p.server.store.readLadder(SEASON, 10)
					local pick = ArenaLadder.opponents(doc, tostring(p.id), rng, 5)[rng:int(1, 5)]
					if w.attack(p, pick.id, rng:next() < 0.5, nil, pick.above) then
						attacks += 1
					end
				end
			end
			for i, s in servers do
				if (step + i) % 3 == 0 then
					s.store.leaderTick(w.now)
				end
			end
			if (w.now - start) % 60 == 55 then
				local bytes, writes = ladder()
				table.insert(minuteBytes, bytes - lastBytes)
				table.insert(minuteWrites, writes - lastWrites)
				lastBytes, lastWrites = bytes, writes
			end
		end
		T.eq(attacks, serverCount * 10 * 5, "every player attacked once a minute")
		local worst, mostWrites = 0, 0
		for i, bytes in minuteBytes do
			worst = math.max(worst, bytes)
			mostWrites = math.max(mostWrites, minuteWrites[i])
		end
		T.ok(worst <= A.WriteBytesPerMinute, "ladder bytes a minute " .. worst)
		local doc = w.doc()
		consistent(T, doc)
		for _, p in players do
			T.eq(p.farm.arena.pending, nil, "settled: " .. p.id)
			T.eq(p.confirms, 5)
			T.eq(doc.players[tostring(p.id)].sp, p.ladder, "ladder points once: " .. p.id)
			T.eq(p.farm.arena.points, p.granted)
		end
		T.eq(w.queue.size(), 0)
		return worst, mostWrites, doc
	end

	T.test("load: 50 servers x 10 matches a minute for 5 minutes stay within 1 MB of ladder a minute", function()
		local worst, writes, doc = load(T, 0, 50)
		T.eq(#doc.order, A.Bots + 500)
		T.ok(writes <= 60 / A.TickSeconds, "at most one write a tick")
		print(
			string.format(
				"[GooLineage] arena load test: %d ladder bytes, %d writes in the busiest minute (%d byte ladder)",
				worst,
				writes,
				ProfileLogic.estimateSize(doc)
			)
		)
	end)

	T.test("load on a ladder over 250 KB: writes stretch and nothing is lost", function()
		local worst, writes, doc = load(T, 4000, 20)
		T.ok(ProfileLogic.estimateSize(doc) > 250000, "the ladder is big")
		T.ok(writes < 60 / A.TickSeconds, "written less often than every tick")
		print(
			string.format(
				"[GooLineage] arena load test: %d ladder bytes, %d writes in the busiest minute (%d byte ladder)",
				worst,
				writes,
				ProfileLogic.estimateSize(doc)
			)
		)
	end)
end
