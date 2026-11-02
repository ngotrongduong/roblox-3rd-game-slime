local Config = require("../../src/shared/Config")
local Fake = require("../lib/FakeDataStore")
local FarmKit = require("../lib/FarmKit")
local Board = require("../../src/shared/Leaderboard")
local LeaderboardStore = require("../../src/server/LeaderboardStore")

local L = Config.Leaderboard

-- A slime of this level (attack carries it: 1 + 1 + 1 + 10 / 10 is level 4, so attack = level - 3).
local function slime(id: string, level: number, opts: { [string]: any }?)
	local o = opts or {}
	o.stats = { attack = level - 3, defence = 1, speed = 1, hp = 10 }
	return FarmKit.slime(id, o)
end

local function entry(userId: number, level: number, at: number, player: string?, name: string?)
	return {
		userId = userId,
		player = player or ("p" .. userId),
		slime = name or ("s" .. userId),
		level = level,
		at = at,
	}
end

return function(T)
	T.test("the best slime of a farm is the highest level", function()
		local farm = FarmKit.farm(0, { slime("a", 10), slime("b", 40, { name = "Big One" }), slime("c", 25) })
		local best = Board.bestSlime(farm, 100)
		T.eq(best.id, "b")
		T.eq(best.name, "Big One")
		T.eq(best.level, 40)
	end)

	T.test("a dead slime does not count, a risen one does", function()
		local farm = FarmKit.farm(0, { slime("a", 10), slime("b", 40, { ghostUntil = 500 }) })
		T.eq(Board.bestSlime(farm, 100).id, "a", "still a ghost")
		T.eq(Board.bestSlime(farm, 500).id, "b", "the time is over")
		T.eq(Board.bestSlime(FarmKit.farm(0, { slime("a", 10, { ghostUntil = 900 }) }), 100), nil, "all dead")
		T.eq(Board.bestSlime(FarmKit.farm(0, {}), 100), nil, "none")
	end)

	T.test("a tie goes to the older slime, then the smaller id, whatever the order", function()
		local older = slime("z", 20, { createdAt = 5 })
		local newer = slime("a", 20, { createdAt = 9 })
		T.eq(Board.bestSlime(FarmKit.farm(0, { newer, older }), 0).id, "z")
		T.eq(Board.bestSlime(FarmKit.farm(0, { older, newer }), 0).id, "z")
		local x, y = slime("x", 20, { createdAt = 5 }), slime("y", 20, { createdAt = 5 })
		T.eq(Board.bestSlime(FarmKit.farm(0, { y, x }), 0).id, "x")
		T.eq(Board.bestSlime(FarmKit.farm(0, { x, y }), 0).id, "x")
	end)

	T.test("a name is cleaned, cut and given a fallback", function()
		T.eq(Board.cleanName("  Goo\tFriend\n ", "Slime"), "Goo Friend")
		T.eq(Board.cleanName("", "Slime"), "Slime")
		T.eq(Board.cleanName("   ", "Slime"), "Slime")
		T.eq(Board.cleanName(nil, "Slime"), "Slime")
		T.eq(Board.cleanName(42, "Slime"), "Slime")
		T.eq(Board.cleanName(string.rep("a", L.MaxNameLength + 10), "x"), string.rep("a", L.MaxNameLength))
		local long = string.rep("é", L.MaxNameLength + 3)
		T.eq(utf8.len(Board.cleanName(long, "x")), L.MaxNameLength, "cut between letters, not inside one")
		T.eq(Board.cleanName("\255\255", "Slime"), "Slime", "not text")
	end)

	T.test("a slime without a name shows the fallback", function()
		T.eq(Board.slimeName({ name = "" }), L.FallbackSlime)
		T.eq(Board.slimeName({ name = "Slime 4" }), "Slime 4")
	end)

	T.test("a score keeps the level, then the earlier second; it survives the round trip", function()
		local score = Board.encode(123, 1_700_000_000)
		local level, at = Board.decode(score)
		T.eq(level, 123)
		T.eq(at, 1_700_000_000)
		T.ok(Board.encode(5, 1_900_000_000) > Board.encode(4, 1), "a higher level beats any time")
		T.ok(Board.encode(5, 100) > Board.encode(5, 200), "the earlier second is higher")
		T.eq(score % 1, 0, "a whole number")
		local top = Board.encode(1296, 0)
		T.ok(top < 2 ^ 53, "the biggest level fits a double exactly")
		T.eq(Board.decode(top), 1296)
	end)

	T.test("ranking: level, then the earlier second, then the smaller user id; cut to the count", function()
		local list = {
			entry(3, 10, 50),
			entry(1, 10, 50),
			entry(2, 10, 40),
			entry(4, 30, 99),
			entry(5, 2, 1),
		}
		local ranked = Board.rank(list, 4)
		T.eq(#ranked, 4)
		T.eq(ranked[1].userId, 4)
		T.eq(ranked[2].userId, 2, "earlier second")
		T.eq(ranked[3].userId, 1, "smaller id")
		T.eq(ranked[4].userId, 3)
		T.eq(list[1].userId, 3, "the list given is left as it was")
		T.eq(#Board.rank({}, 10), 0)
	end)

	T.test("merging: a live level above the stored one wins, a lower one does not, one line a player", function()
		local stored = { entry(1, 30, 10, "Ann", "Old"), entry(2, 20, 10, "Bo", "Bo's") }
		local live =
			{ entry(1, 35, 500, "Ann", "New"), entry(2, 5, 600, "Bo", "Tiny"), entry(3, 22, 700, "Cy", "Cy's") }
		local merged = Board.merge(stored, live, 10)
		T.eq(#merged, 3)
		T.eq(merged[1].userId, 1)
		T.eq(merged[1].level, 35)
		T.eq(merged[1].slime, "New")
		T.eq(merged[2].userId, 3, "a player not stored yet appears")
		T.eq(merged[3].userId, 2)
		T.eq(merged[3].slime, "Bo's", "a sold best is not forgotten")
	end)

	T.test("merging: the same level takes the live names and the earlier second", function()
		local merged = Board.merge({ entry(1, 30, 10, "Ann", "Old") }, { entry(1, 30, 500, "Ann", "Fresh") }, 10)
		T.eq(#merged, 1)
		T.eq(merged[1].slime, "Fresh")
		T.eq(merged[1].at, 10)
	end)

	T.test("merging cuts to the rows and works with no store at all", function()
		local live = {}
		for id = 1, 15 do
			table.insert(live, entry(id, id + 5, 100))
		end
		local merged = Board.merge({}, live, L.Rows)
		T.eq(#merged, L.Rows)
		T.eq(merged[1].userId, 15)
		T.eq(merged[L.Rows].userId, 16 - L.Rows)
		T.eq(#Board.merge({}, {}, L.Rows), 0)
	end)

	T.test("a best is sent only when it improved and a minute has passed; leaving never waits", function()
		T.ok(Board.writeDue(0, nil, 4, 1000, false), "the first one goes at once")
		T.ok(not Board.writeDue(10, 1000, 10, 5000, false), "not better")
		T.ok(not Board.writeDue(10, 1000, 8, 5000, true), "not better, even leaving")
		T.ok(not Board.writeDue(10, 1000, 11, 1000 + L.WriteGapSeconds - 1, false), "too soon")
		T.ok(Board.writeDue(10, 1000, 11, 1000 + L.WriteGapSeconds, false), "a minute later")
		T.ok(Board.writeDue(10, 1000, 11, 1001, true), "leaving")
	end)

	T.test("a line travels as one short text and back", function()
		local text = Board.encodeRow(entry(1, 77, 5, "Ann", "Slime 9"))
		T.eq(text, "Ann\tSlime 9\t77")
		local player, name, level = Board.decodeRow(text)
		T.eq(player, "Ann")
		T.eq(name, "Slime 9")
		T.eq(level, 77)
		T.eq(Board.decodeRow("nonsense"), nil)
		T.eq(Board.decodeRow(nil), nil)
		T.eq(Board.decodeRow("a\tb\tx"), nil)
		T.ok(
			#Board.encodeRow(entry(1, 1296, 5, string.rep("a", L.MaxNameLength), string.rep("b", L.MaxNameLength)))
				< 200
		)
	end)

	-- ===== the stores =====

	local function newStore()
		local logs = {}
		local scores, names = Fake.new(), Fake.new()
		local store = LeaderboardStore.new({
			scores = scores,
			names = names,
			log = function(line)
				table.insert(logs, line)
			end,
		})
		return store, scores, names, logs
	end

	T.test("a first best is stored with its names; the top reads it back", function()
		local store, scores, names = newStore()
		local wrote, err = store.submit(entry(7, 40, 1000, "Ann", "Big"))
		T.eq(wrote, true)
		T.eq(err, nil)
		T.eq(scores.peek("7"), Board.encode(40, 1000))
		T.eq(names.peek("7").p, "Ann")
		local top = store.top(10)
		T.eq(#top, 1)
		T.eq(top[1].userId, 7)
		T.eq(top[1].player, "Ann")
		T.eq(top[1].slime, "Big")
		T.eq(top[1].level, 40)
		T.eq(top[1].at, 1000)
	end)

	T.test("a best that is not higher changes nothing, a higher one replaces it", function()
		local store, scores, names = newStore()
		store.submit(entry(7, 40, 1000, "Ann", "Big"))
		local before = scores.peek("7")
		local wrote, err = store.submit(entry(7, 40, 2000, "Ann", "Same level"))
		T.eq(wrote, false)
		T.eq(err, nil)
		T.eq(scores.peek("7"), before, "the earlier second stays")
		T.eq(names.peek("7").s, "Big", "the names stay with the score")
		wrote = store.submit(entry(7, 12, 3000, "Ann", "Lower"))
		T.eq(wrote, false, "a lower level from a new session cannot overwrite a record")
		wrote = store.submit(entry(7, 41, 4000, "Ann", "Bigger"))
		T.eq(wrote, true)
		T.eq(names.peek("7").s, "Bigger")
		T.eq(Board.decode(scores.peek("7")), 41)
	end)

	T.test("the top is in board order, cut to the count", function()
		local store = newStore()
		for id = 1, 5 do
			store.submit(entry(id, id * 10, 100 + id))
		end
		store.submit(entry(9, 30, 50))
		local top = store.top(3)
		T.eq(#top, 3)
		T.eq(top[1].userId, 5)
		T.eq(top[2].userId, 4)
		T.eq(top[3].userId, 9, "level 30 reached earlier than player 3's")
	end)

	T.test("names are read again only when the score moved", function()
		local store, _, names = newStore()
		store.submit(entry(1, 10, 1, "Ann", "A"))
		store.top(10)
		local calls = names.calls
		store.top(10)
		store.top(10)
		T.eq(names.calls, calls, "no more name reads while the level is the same")
		store.submit(entry(1, 11, 2, "Ann", "B"))
		local top = store.top(10)
		T.ok(names.calls > calls, "read after the level changed")
		T.eq(top[1].slime, "B")
	end)

	T.test("a failed send or read is logged with the prefix, changes nothing and does not throw", function()
		local store, scores, names, logs = newStore()
		scores.failNext(1)
		local wrote, err = store.submit(entry(1, 10, 1))
		T.eq(wrote, false)
		T.ok(err ~= nil, "the reason comes back")
		T.eq(scores.peek("1"), nil)
		T.eq(#logs, 1)
		T.eq(string.sub(logs[1], 1, #Config.LogPrefix), Config.LogPrefix)

		-- the names failing leaves the score stored and the call a success
		names.failNext(1)
		wrote, err = store.submit(entry(1, 10, 1))
		T.eq(wrote, true)
		T.eq(err, nil)
		T.ok(scores.peek("1") ~= nil)

		scores.failNext(1)
		local top, why = store.top(10)
		T.eq(top, nil)
		T.ok(why ~= nil)
		T.eq(string.sub(logs[#logs], 1, #Config.LogPrefix), Config.LogPrefix)

		-- a name read failing still gives the line, with fallback names
		names.failNext(1)
		local lines = store.top(10)
		T.eq(#lines, 1)
		T.eq(lines[1].player, L.FallbackPlayer)
		T.eq(lines[1].level, 10)
	end)

	T.test("the memory pair (Studio) behaves like the real stores", function()
		local scores, names = LeaderboardStore.memory()
		local store = LeaderboardStore.new({
			scores = scores,
			names = names,
			log = function() end,
		})
		T.eq(#store.top(10), 0)
		T.eq(store.submit(entry(1, 20, 5, "Ann", "A")), true)
		T.eq(store.submit(entry(2, 30, 6, "Bo", "B")), true)
		T.eq(store.submit(entry(1, 20, 9, "Ann", "A2")), false)
		T.eq(store.submit(entry(1, 25, 9, "Ann", "A3")), true)
		local top = store.top(10)
		T.eq(#top, 2)
		T.eq(top[1].userId, 2)
		T.eq(top[2].slime, "A3")
	end)
end
