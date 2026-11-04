--!strict
local Quests = require("../../src/shared/ArenaQuests")
local Season = require("../../src/shared/ArenaSeason")
local Config = require("../../src/shared/Config")

local MONDAY = 1704067200
local function granted(grants: { any }, id: string): boolean
	for _, grant in grants do
		if grant.id == id then
			return true
		end
	end
	return false
end

return function(T)
	T.test("new quest state carries explicit UTC periods and empty progress", function()
		T.same(
			Quests.new(MONDAY),
			{ day = Season.dayOf(MONDAY), week = Season.weekOf(MONDAY), season = 202401, counts = {}, done = {} }
		)
	end)
	T.test("losses never count even against a stronger defender", function()
		local state = Quests.new(MONDAY)
		T.same(Quests.record(state, MONDAY, { won = false, stronger = true }), {})
		T.same(state.counts, {})
		T.same(state.done, {})
	end)
	T.test("daily and stronger wins grant once, and weekly wins finish on the fifth", function()
		local state = Quests.new(MONDAY)
		local first = Quests.record(state, MONDAY, { won = true, stronger = false })
		T.eq(#first, 1)
		T.eq(first[1].id, "daily_win")
		T.eq(state.counts.weekly_stronger, nil)
		local second = Quests.record(state, MONDAY, { won = true, stronger = true })
		T.eq(#second, 1)
		T.eq(second[1].id, "weekly_stronger")
		for _ = 3, 4 do
			T.same(Quests.record(state, MONDAY, { won = true, stronger = true }), {})
		end
		local fifth = Quests.record(state, MONDAY, { won = true, stronger = true })
		T.eq(#fifth, 1)
		T.eq(fifth[1].id, "weekly_wins")
		T.same(Quests.record(state, MONDAY, { won = true, stronger = true }), {})
	end)
	T.test("all seasonal milestones grant exactly once and counters stay capped", function()
		local state = Quests.new(MONDAY)
		local rewards = {}
		for win = 1, 100 do
			local grants = Quests.record(state, MONDAY, { won = true, stronger = true })
			if win == 10 then
				T.ok(granted(grants, "season_10"))
			end
			if win == 25 then
				T.ok(granted(grants, "season_25"))
			end
			if win == 50 then
				T.ok(granted(grants, "season_50"))
			end
			for _, grant in grants do
				T.eq(rewards[grant.id], nil)
				rewards[grant.id] = grant.points
			end
		end
		for _, quest in Config.Arena.Quests do
			T.eq(rewards[quest.id], quest.points)
			T.eq(state.counts[quest.id], quest.wins)
			T.eq(state.done[quest.id], true)
		end
	end)
	T.test("daily rollover leaves weekly and seasonal progress intact", function()
		local state = Quests.new(MONDAY)
		Quests.record(state, MONDAY, { won = true, stronger = true })
		local grants = Quests.record(state, MONDAY + 86400, { won = true, stronger = true })
		T.eq(#grants, 1)
		T.eq(grants[1].id, "daily_win")
		T.eq(state.counts.weekly_wins, 2)
		T.eq(state.counts.weekly_stronger, 1)
		T.eq(state.counts.season_10, 2)
	end)
	T.test("Monday resets weekly quests, including done, without resetting the season", function()
		local state = Quests.new(MONDAY)
		for _ = 1, 5 do
			Quests.record(state, MONDAY, { won = true, stronger = true })
		end
		local nextMonday = MONDAY + 7 * 86400
		local grants = Quests.record(state, nextMonday, { won = true, stronger = true })
		T.ok(granted(grants, "daily_win"))
		T.ok(granted(grants, "weekly_stronger"))
		T.eq(state.counts.weekly_wins, 1)
		T.eq(state.done.weekly_wins, nil)
		T.eq(state.counts.season_10, 6)
	end)
	T.test("month rollover resets only seasonal and daily quests when the week stays", function()
		local january = Season.seasonEnd(202401) - 1
		local february = january + 1
		T.eq(Season.weekOf(january), Season.weekOf(february))
		local state = Quests.new(january)
		for _ = 1, 50 do
			Quests.record(state, january, { won = true, stronger = true })
		end
		local grants = Quests.record(state, february, { won = false, stronger = false })
		T.same(grants, {})
		T.eq(state.counts.daily_win, 0)
		T.eq(state.done.daily_win, nil)
		T.eq(state.counts.weekly_wins, 5)
		T.eq(state.done.weekly_wins, true)
		for _, id in { "season_10", "season_25", "season_50" } do
			T.eq(state.counts[id], 0)
			T.eq(state.done[id], nil)
		end
		T.eq(state.season, 202402)
	end)
	T.test("a long absence resets all periods before counting the next win", function()
		local state = Quests.new(MONDAY)
		for _ = 1, 50 do
			Quests.record(state, MONDAY, { won = true, stronger = true })
		end
		local now = Season.seasonStart(202501)
		local grants = Quests.record(state, now, { won = true, stronger = true })
		T.eq(#grants, 2)
		for _, quest in Config.Arena.Quests do
			T.eq(state.counts[quest.id], 1)
		end
		T.eq(state.day, Season.dayOf(now))
		T.eq(state.week, Season.weekOf(now))
		T.eq(state.season, 202501)
	end)
end
