--!nocheck
-- The Arena's bots, points and shop against player teams at realistic stages, on the real ArenaFight / ArenaBots /
-- ArenaLadder / ArenaQuests / ArenaSeason rules (ECONOMY.md's road and income_model's slime levels).
--   lune run tools/balance/arena_sim.luau [samples] [seasonRuns] [policy] [name=value ...]
-- samples: fights a cell (default 100); seasonRuns: seasons a stage plays (default 5); policy: "safe" (default: the
-- best-ranked rival that does not read as danger on the card), "bold" (always the hard one) or "easy" (the weakest).
-- Overrides, to try numbers without editing Config: growth=0.5 (levels an hour past village 50), hours=1.5 (hours a day),
-- grid=0 (skip the win-rate grid), champ=60 (the Champion's level), or any number in Config.Arena by name, for example
-- BotLevelMin=9 WinPoints=25 (a table in Config.Arena cannot be overridden here).
--
-- ASSUMED (not measured; the largest unknowns first):
--   * a plain player plays `hours` a day; village level comes from ECONOMY.md's table of hours, the strongest slimes'
--     level from income_model.SLIME_LEVEL; past village 50 (28 h) a team keeps growing `growth` levels an hour (breeding
--     alone can give more: about 1.8 an hour for a pair kept on the best parent, income_sim's 9 eggs an hour x 10% x 2)
--   * the Dungeon opens at village 15; DUNGEON_SHARE of play is dungeon runs of RUN_MINUTES; the gear a stage owns is what
--     that many runs of Config.Dungeon drops can craft (STAGES, one tier per slime, all three slots)
--   * a team's stats are spread as the bots' are (a random favourite worth twice the others), integers, never below the
--     starters
--   * "static" season: the team of that stage, unchanged, 10 tickets a day for 30 days, a fresh list of 5 rivals a fight.
--     "growing" season: the same player who keeps playing `hours` a day, so level and gear rise day by day (gear = the
--     latest stage's whose hours he has reached)
local process = require("@lune/process")
local ArenaBots = require("../../src/shared/ArenaBots")
local ArenaFight = require("../../src/shared/ArenaFight")
local ArenaLadder = require("../../src/shared/ArenaLadder")
local ArenaQuests = require("../../src/shared/ArenaQuests")
local ArenaSeason = require("../../src/shared/ArenaSeason")
local Config = require("../../src/shared/Config")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")
local FarmKit = require("../../tests/lib/FarmKit")
local Model = require("./income_model")

local SAMPLES = tonumber(process.args[1]) or 100
local SEASON_RUNS = tonumber(process.args[2]) or 5
local POLICY = process.args[3] or "safe"
local A = Config.Arena

local HOURS_PER_DAY = 1.5
local LEVEL_PER_HOUR = 0.5
local DUNGEON_SHARE = 0.2
local RUN_MINUTES = 4
local SHOW_GRID = true
local BRIEF = false
for index = 4, #process.args do
	local key, value = string.match(process.args[index], "^([%w_]+)=([%d%.%-]+)$")
	assert(key, "bad argument " .. process.args[index])
	local number = tonumber(value) :: number
	if key == "growth" then
		LEVEL_PER_HOUR = number
	elseif key == "hours" then
		HOURS_PER_DAY = number
	elseif key == "grid" then
		SHOW_GRID = number ~= 0
	elseif key == "brief" then
		BRIEF = number ~= 0
	elseif key == "champ" then
		A.ChampionLevel = function(_season: number): number
			return number
		end
	else
		assert((A :: any)[key] ~= nil, "no Config.Arena." .. key)
		;(A :: any)[key] = number
	end
end

-- brief=1: only one line of settle ranks and points a day (to scan many numbers), printed by `say`
local say = print
if BRIEF then
	print = function(...) end
end
-- ECONOMY.md's road: active hours -> village level
local ROAD = { { 0, 1 }, { 0.17, 5 }, { 0.5, 10 }, { 2.9, 20 }, { 3.5, 26 }, { 5.5, 31 }, { 8.5, 36 }, { 12, 40 }, { 20, 46 }, { 28, 50 } }

local function slimeLevelAt(hours: number): (number, number)
	local village = Model.lerp(ROAD, hours)
	local level = Model.lerp(Model.SLIME_LEVEL, village)
	if hours > 28 then
		level = 40 + (hours - 28) * LEVEL_PER_HOUR
	end
	return village, level
end

-- gear: the tier each of the four slimes wears (all three slots), none when missing. Reasoned from the recipes and the drops
-- per run in docs/SMITHY.md (core gear about 10 runs, bramble gear a handful of boss kills a slime; 4 slimes x 3 slots).
local STAGES = {
	{ name = "start", hours = 0, gear = {} },
	{ name = "30 min", hours = 0.5, gear = {} },
	{ name = "day 1", hours = 1 * HOURS_PER_DAY, gear = {} },
	{ name = "day 3", hours = 3 * HOURS_PER_DAY, gear = { "iron", "wood", "wood", "wood" } },
	{ name = "week 1", hours = 7 * HOURS_PER_DAY, gear = { "core", "iron", "iron", "iron" } },
	{ name = "week 2", hours = 14 * HOURS_PER_DAY, gear = { "core", "core", "core", "iron" } },
	{ name = "month 1", hours = 30 * HOURS_PER_DAY, gear = { "bramble", "core", "core", "core" } },
	{ name = "month 3", hours = 90 * HOURS_PER_DAY, gear = { "bramble", "bramble", "bramble", "bramble" } },
}

local function gearAt(hours: number): { string }
	local out = {}
	for _, stage in STAGES do
		if stage.hours <= hours then
			out = stage.gear
		end
	end
	return out
end

local function gearSet(tier: string?): { [string]: string }
	local worn = {}
	if not tier then
		return worn
	end
	for id, piece in Config.Smithy.Gear do
		if piece.tier == tier then
			worn[piece.slot] = id
		end
	end
	return worn
end

-- The player's four slimes as the real ArenaFight.snapshot reads them from a farm.
local function playerTeam(key: string, level: number, gear: { string }, seed: number)
	local rng = Rng.new(Rng.hash("sim:" .. key .. ":" .. seed))
	local slimes, ids = {}, {}
	for index = 1, A.TeamSize do
		local stats = Stats.starter()
		if level > 4 then
			local varied = level * (1 + (rng:next() * 2 - 1) * A.BotLevelSpread)
			local favourite = rng:pick(Stats.Keys)
			local total = #Stats.Keys - 1 + A.BotFavouriteWeight
			for _, stat in Stats.Keys do
				local value = varied * (if stat == favourite then A.BotFavouriteWeight else 1) / total
				local min = (Config.Stats.Starter :: any)[stat]
				Stats.set(stats, stat, math.max(min, math.round(value * (if stat == "hp" then Config.Stats.HpPerLevel else 1))))
			end
		end
		local slime = FarmKit.slime("p" .. index, { stats = stats, seed = rng:int(1, 1000000) })
		slime.gear = gearSet(gear[index])
		table.insert(slimes, slime)
		table.insert(ids, slime.id)
	end
	local farm = FarmKit.farm(0, slimes)
	return assert(ArenaFight.snapshot(farm, ids))
end

local npcCache: { [string]: any } = {}
local function npc(season: number, id: string)
	local key = season .. ":" .. id
	if not npcCache[key] then
		npcCache[key] = ArenaBots.team(season, id)
	end
	return npcCache[key]
end

local function median(list: { number }): number
	table.sort(list)
	return list[math.ceil(#list / 2)]
end

-- ===== 1. the win-rate grid =====
local RANKS = { 1000, 900, 750, 500, 250, 100, 50, 10, 1 }
local function opponentId(column: number): string
	return if column > #RANKS then "c1" else "b" .. RANKS[column]
end

print("[GooLineage] arena_sim: " .. SAMPLES .. " fights a cell, policy " .. POLICY .. ", " .. HOURS_PER_DAY .. " h a day, growth " .. LEVEL_PER_HOUR .. " levels an hour past village 50")
print(
	string.format(
		"[GooLineage] Config.Arena: bot level %g..%g ^%g, champion %g, win %d, loss %d, below %.2f, climb %d/step (cap %d)",
		A.BotLevelMin,
		A.BotLevelMax,
		A.BotLevelExponent,
		A.ChampionLevel(0),
		A.WinPoints,
		A.LossPoints,
		A.BelowShare,
		A.ClimbBonusPerStep,
		A.ClimbBonusCap
	)
)
print("Bot level (one slime) and team power (four) by rank:")
local header = ""
local levelLine = ""
local powerLine = ""
for column = 1, #RANKS + 1 do
	local id = opponentId(column)
	header ..= string.format("%7s", if id == "c1" then "Champ" else tostring(RANKS[column]))
	local team = npc(202611, id)
	local lvl = if id == "c1" then A.ChampionLevel(202611) else ArenaBots.level(id)
	levelLine ..= string.format("%7.1f", lvl)
	powerLine ..= string.format("%7d", team.power)
end
print("rank                         " .. header)
print("level                        " .. levelLine)
print("power                        " .. powerLine)

print("Win rate % of a stage's team (attacking) against the bots at each rank; first = the five rivals a new rank-1001 player is offered")
print("stage     h   vil  lvl  pwr first" .. header)
local stageInfo = {}
for _, stage in STAGES do
	local village, level = slimeLevelAt(stage.hours)
	local teamPower = {}
	for sample = 1, math.min(SAMPLES, 25) do
		table.insert(teamPower, playerTeam(stage.name, level, stage.gear, sample).power)
	end
	stageInfo[stage.name] = { level = level, power = median(teamPower), village = village }
	local line = ""
	local first = ""
	if SHOW_GRID then
		local firstWins, firstFights = 0, 0
		for sample = 1, SAMPLES do
			local snap = playerTeam(stage.name, level, stage.gear, sample)
			local season = 202600 + sample
			local doc = ArenaLadder.new(season)
			for _, pick in ArenaLadder.opponents(doc, "1", Rng.new(sample), A.Opponents) do
				local replay = ArenaFight.simulate(snap.fighters, npc(season, pick.id).fighters, sample * 31 + firstFights)
				firstWins += if replay.won then 1 else 0
				firstFights += 1
			end
		end
		first = string.format("%5.0f", firstWins / firstFights * 100)
		for column = 1, #RANKS + 1 do
			local wins = 0
			for sample = 1, SAMPLES do
				local snap = playerTeam(stage.name, level, stage.gear, sample)
				local season = 202600 + sample
				local replay = ArenaFight.simulate(snap.fighters, npc(season, opponentId(column)).fighters, sample * 977 + column)
				wins += if replay.won then 1 else 0
			end
			line ..= string.format("%7.0f", wins / SAMPLES * 100)
		end
	end
	local info = stageInfo[stage.name]
	print(string.format("%-8s %5.1f %4.0f %5.1f %4d %s%s", stage.name, stage.hours, village, level, info.power, first, line))
end

-- ===== 2. a season =====
local function choose(entries: { any }, power: number): any
	if POLICY == "bold" then
		return entries[1]
	end
	local best, weakest = nil, entries[1]
	for _, e in entries do
		if e.power < weakest.power then
			weakest = e
		end
		if e.power <= power * A.View.DangerRatio and e.rank and (best == nil or e.rank < best.rank) then
			best = e
		end
	end
	if POLICY == "easy" then
		return weakest
	end
	return best or weakest
end

-- teamAt(day) is the player's team that day (day 0 .. 29)
local function playSeason(teamAt: (number) -> any, seed: number)
	local season = 202611
	local start = ArenaSeason.seasonStart(season)
	local doc = ArenaLadder.new(season)
	local rng = Rng.new(Rng.hash("season:" .. seed))
	local pid = "1"
	local quests = ArenaQuests.new(start)
	local seq = 0
	local days = {}
	local questPoints, wins, fights = 0, 0, 0
	for day = 0, 29 do
		local snap = teamAt(day)
		local dayPoints, dayWins = 0, 0
		for ticket = 1, A.TicketsPerDay do
			local now = start + day * 86400 + 12 * 3600 + ticket * 60
			local picks = ArenaLadder.opponents(doc, pid, rng, A.Opponents)
			local entries = {}
			for _, pick in picks do
				local team = npc(seed % 12 + 1 + 202600, pick.id)
				table.insert(entries, { id = pick.id, rank = pick.rank, above = pick.above, power = team.power, team = team })
			end
			local entry = choose(entries, snap.power)
			local replay = ArenaFight.simulate(snap.fighters, entry.team.fighters, rng:int(1, 2 ^ 30))
			seq += 1
			local _, out = ArenaLadder.apply(doc, {
				attacker = pid,
				seq = seq,
				defender = entry.id,
				won = replay.won,
				above = entry.above,
				season = season,
				name = "Player",
				power = snap.power,
			})
			local points = out.points
			for _, grant in ArenaQuests.record(quests, now, { won = replay.won, stronger = entry.power > snap.power }) do
				points += grant.points
				questPoints += grant.points
			end
			dayPoints += points
			fights += 1
			if replay.won then
				wins += 1
				dayWins += 1
			end
		end
		days[day + 1] = { rank = ArenaLadder.rankOf(doc, pid), points = dayPoints, wins = dayWins }
	end
	return { days = days, quests = questPoints, wins = wins, fights = fights, final = ArenaLadder.rankOf(doc, pid) }
end

local seasonResults = {}
local function seasonTable(mode: string)
	print("")
	print(
		"[GooLineage] "
			.. (if mode == "static" then "STATIC team (settles where it stops winning)" else "GROWING player (keeps playing " .. HOURS_PER_DAY .. " h a day)")
			.. ", 30 days x "
			.. A.TicketsPerDay
			.. " tickets, "
			.. SEASON_RUNS
			.. " runs a stage, medians"
	)
	print("stage       rank after: d1   d3   d7  d14  d30 | win% | pts/day: d1-7 d8-14 d22-30 all | quests/day | season reward")
	seasonResults[mode] = {}
	for _, stage in STAGES do
		local info = stageInfo[stage.name]
		local at = { {}, {}, {}, {}, {} }
		local winRates, early, mid, late, whole, quests, rewards = {}, {}, {}, {}, {}, {}, {}
		for run = 1, SEASON_RUNS do
			local function teamAt(day: number): any
				if mode == "static" then
					return playerTeam(stage.name, info.level, stage.gear, 5000 + run)
				end
				local hours = stage.hours + day * HOURS_PER_DAY
				local _, level = slimeLevelAt(hours)
				return playerTeam("grow:" .. stage.name, level, gearAt(hours), 5000 + run)
			end
			local result = playSeason(teamAt, run)
			for i, day in { 1, 3, 7, 14, 30 } do
				table.insert(at[i], result.days[day].rank)
			end
			table.insert(winRates, result.wins / result.fights * 100)
			local function avg(from: number, to: number): number
				local sum = 0
				for d = from, to do
					sum += result.days[d].points
				end
				return sum / (to - from + 1)
			end
			table.insert(early, avg(1, 7))
			table.insert(mid, avg(8, 14))
			table.insert(late, avg(22, 30))
			table.insert(whole, avg(1, 30))
			table.insert(quests, result.quests / 30)
			table.insert(rewards, (ArenaSeason.rewardFor(result.final)))
		end
		seasonResults[mode][stage.name] =
			{ whole = median(whole), reward = median(rewards), rank = median(at[5]), d7 = median(at[3]), wins = median(winRates) }
		print(
			string.format(
				"%-8s %16d %4d %4d %4d %4d | %4.0f | %17.0f %5.0f %6.0f %4.0f | %10.1f | %5d",
				stage.name,
				median(at[1]),
				median(at[2]),
				median(at[3]),
				median(at[4]),
				median(at[5]),
				median(winRates),
				median(early),
				median(mid),
				median(late),
				median(whole),
				median(quests),
				median(rewards)
			)
		)
	end
end
seasonTable("static")
seasonTable("growing")
if BRIEF then
	local line = string.format("BRIEF min %g max %g exp %g champ %g | static rank: ", A.BotLevelMin, A.BotLevelMax, A.BotLevelExponent, A.ChampionLevel(0))
	for _, stage in STAGES do
		line ..= string.format("%s %d, ", stage.name, seasonResults.static[stage.name].rank)
	end
	line ..= "| growing d7/d30 rank, pts/day: "
	for _, stage in STAGES do
		local g = seasonResults.growing[stage.name]
		line ..= string.format("%s %d/%d %.0f, ", stage.name, g.d7, g.rank, g.whole + g.reward / 30)
	end
	say(line)
	return
end

-- ===== 3. the shop =====
-- Drops of one full clear of dungeon level 1 (docs/SMITHY.md section 2, "roughly"): the Arena shop's worth in runs.
local PER_RUN = { ore = 8, rare_part = 4, monster_core = 0.8, boar_tusk = 2.2, boss_essence = 0.25, wood = 5 }
local runsPerWeek = HOURS_PER_DAY * 7 * DUNGEON_SHARE * 60 / RUN_MINUTES
print("")
print(
	string.format(
		"[GooLineage] Shop: a plain player runs the dungeon about %.0f times a week (%.0f%% of %.1f h a day, %d min a run)",
		runsPerWeek,
		DUNGEON_SHARE * 100,
		HOURS_PER_DAY,
		RUN_MINUTES
	)
)
print("row          price limit/wk  runs of drops a buy  runs a week at limit  points a week at limit")
local cap, capRuns = 0, 0
for _, row in A.Shop do
	local perRun = (PER_RUN :: any)[row.item]
	local runs = if perRun then row.count / perRun else 0
	cap += row.price * row.weeklyLimit
	capRuns += runs * row.weeklyLimit
	print(
		string.format(
			"%-12s %5d %8d %20.1f %21.1f %23d",
			row.id,
			row.price,
			row.weeklyLimit,
			runs,
			runs * row.weeklyLimit,
			row.price * row.weeklyLimit
		)
	)
end
print(string.format("all rows at their limits: %d points a week, worth %.1f dungeon runs of drops", cap, capRuns))
print("GROWING player: points a day (month's average + the reward spread over 30 days), what a week buys")
print("stage     pts/day  pts/week  days to charm_core  share of weekly cap  runs a week the best buys replace")
for _, stage in STAGES do
	local r = seasonResults.growing[stage.name]
	local perDay = r.whole + r.reward / 30
	local week = perDay * 7
	-- the best a player can do with a week's points: the most runs of drops per point first
	local rank = {}
	for _, row in A.Shop do
		local perRun = (PER_RUN :: any)[row.item]
		if perRun then
			table.insert(rank, { row = row, value = (row.count / perRun) / row.price })
		end
	end
	table.sort(rank, function(a, b)
		return a.value > b.value
	end)
	local left, replaced = week, 0
	for _, entry in rank do
		local buys = math.min(entry.row.weeklyLimit, math.floor(left / entry.row.price))
		left -= buys * entry.row.price
		replaced += buys * entry.value * entry.row.price
	end
	print(string.format("%-8s %8.0f %9.0f %19.1f %19.0f%% %34.1f", stage.name, perDay, week, 900 / perDay, week / cap * 100, replaced))
end
print("[GooLineage] done")
