--!nocheck
-- How teams of four fare in full 10-wave runs of the four dungeons on the real Combat and Dungeon rules (squad_run: positional
-- as in play, each slime with its class's weapon of the tier a player has at that level, wounds kept from wave to wave).
-- For each dungeon level: the share of runs cleared by a team of the level's main monster level (and, with side=on, five
-- levels above and below) and the median length of a cleared run (the owner's targets, 2026-11-15: about 85-90 in 100 at
-- the level, nearly every run five above, a third five below; a run of 5-6 minutes).
--   lune run tools/balance/dungeon_sim.luau [seeds] [levels] [key=value ...]
-- `levels` is a list joined by "/" (1/10/20/40/80/150 when left out). key=value tries other numbers without editing
-- Config: rf (times every RoleFactor), mini / boss (their RoleFactor), minihp / bosshp (RoleHp), grow (WaveGrowth), maps (a
-- "/" list of Config.Dungeon.Maps ids), teams (a "/" list of team letters, squad_run's), side=on, and fit=on: the power of
-- each level at which its team clears Config.Dungeon.FitShare of the runs, printed as a PowerCurve to copy into Config.
local process = require("@lune/process")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local SquadRun = require("./squad_run")

local D = Config.Dungeon

local function list(text: string?, default: { any }, number: boolean): { any }
	if not text or text == "" then
		return default
	end
	local out = {}
	for part in string.gmatch(text, "[^/]+") do
		table.insert(out, if number then tonumber(part) else part)
	end
	return out
end

local SEEDS = tonumber(process.args[1]) or 20
local LEVELS = list(process.args[2], { 1, 10, 20, 40, 80, 150 }, true)
local options: { [string]: string } = {}
for index = 3, #process.args do
	local key, value = string.match(process.args[index], "^(%w+)=(.+)$")
	if key then
		options[key] = value
	end
end
if options.rf then
	for role, factor in D.RoleFactor do
		D.RoleFactor[role] = factor * tonumber(options.rf)
	end
end
D.RoleFactor.miniboss = tonumber(options.mini) or D.RoleFactor.miniboss
D.RoleFactor.boss = tonumber(options.boss) or D.RoleFactor.boss
D.RoleHp.miniboss = tonumber(options.minihp) or D.RoleHp.miniboss
D.RoleHp.boss = tonumber(options.bosshp) or D.RoleHp.boss
D.WaveGrowth = tonumber(options.grow) or D.WaveGrowth
local MAPS = list(options.maps, D.MapOrder, false)
local TEAMS = list(options.teams, { "GWRH", "WRMA", "GGHA", "GMMH", "WWRM" }, false)
local SIDE = options.side == "on"

-- Over every team and map: the share cleared, the average waves cleared and the median length of a cleared run.
local function measure(teamLevel: number, level: number): (number, number, number)
	local cleared, waves, runs = 0, 0, 0
	local lengths = {}
	for _, mapId in MAPS do
		for _, letters in TEAMS do
			for seed = 1, SEEDS do
				local won, done, seconds = SquadRun.run(SquadRun.team(letters, teamLevel), D.Waves, function(wave)
					return Dungeon.plan(mapId, level, wave, seed * 31)
				end, seed)
				runs += 1
				waves += done
				if won then
					cleared += 1
					table.insert(lengths, seconds)
				end
			end
		end
	end
	table.sort(lengths)
	local median = if #lengths > 0 then lengths[math.max(1, math.floor(#lengths / 2))] else 0
	return cleared / runs, waves / runs, median
end

print(
	string.format(
		"Four dungeons (%s), teams %s, %d seeds each; RoleFactor regular %.2f armoured %.2f mini %.2f boss %.2f, RoleHp mini %.1f boss %.1f, WaveGrowth %.3f",
		table.concat(MAPS, " "),
		table.concat(TEAMS, " "),
		SEEDS,
		D.RoleFactor.swarmer,
		D.RoleFactor.armoured,
		D.RoleFactor.miniboss,
		D.RoleFactor.boss,
		D.RoleHp.miniboss,
		D.RoleHp.boss,
		D.WaveGrowth
	)
)
-- fit=on: for each level, the power at which a team of its main level clears FitShare of the runs (every monster of the
-- run at that power), to copy into Config.Dungeon.PowerCurve
if options.fit == "on" then
	local points = {}
	for _, level in LEVELS do
		local main = Dungeon.mainLevel(level)
		local lo, hi = 0.05, 1.5
		for _ = 1, 7 do
			D.PowerCurve = { { 1, (lo + hi) / 2 } }
			if measure(main, level) >= D.FitShare then
				lo = (lo + hi) / 2
			else
				hi = (lo + hi) / 2
			end
		end
		local power = math.floor(lo * 100 + 0.5) / 100
		print(string.format("level %d (monsters %d, %s): power %.2f", level, main, SquadRun.tierAt(main), power))
		table.insert(points, string.format("{ %d, %.2f }", main, power))
	end
	print("PowerCurve = { " .. table.concat(points, ", ") .. " },")
	return
end

print("| dungeon level | team (tier) | cleared | waves | median run | team 5 above | team 5 below |")
print("|---|---|---|---|---|---|---|")
for _, level in LEVELS do
	local main = Dungeon.mainLevel(level)
	local share, waves, median = measure(main, level)
	local above, below = "-", "-"
	if SIDE then
		above = string.format("%.0f%%", measure(main + 5, level) * 100)
		below = string.format("%.0f%%", measure(math.max(1, main - 5), level) * 100)
	end
	print(
		string.format(
			"| %d | %d (%s) | %.0f%% | %.1f | %.1f min | %s | %s |",
			level,
			main,
			SquadRun.tierAt(main),
			share * 100,
			waves,
			median / 60,
			above,
			below
		)
	)
end
