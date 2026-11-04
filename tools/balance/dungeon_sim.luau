--!nocheck
-- How teams of 4 fare in a full 10-wave Slime Dungeon run on the real Combat and Dungeon rules: the average wave they
-- reach (the wave they fell in, 10 for a cleared run), the share of runs cleared and the average length. The team keeps its
-- health from wave to wave. Spawning as in play: one monster every SpawnSeconds while fewer than MaxAlive stand.
--   lune run tools/balance/dungeon_sim.luau [seeds] [dungeonLevel] [StatScale] [WaveGrowth]
-- (the last two try other values of Config.Dungeon's without editing it)
local process = require("@lune/process")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")

local SEEDS = tonumber(process.args[1]) or 20
local LEVEL = tonumber(process.args[2]) or 1
local D = Config.Dungeon
D.StatScale = tonumber(process.args[3]) or D.StatScale
D.WaveGrowth = tonumber(process.args[4]) or D.WaveGrowth
local STEP = Config.Zombies.FightStepSeconds

-- A team of 4: `slimeLevel` nil is the four starters, otherwise the level shared evenly over the four stats (as fight_sim).
-- `tier` puts that tier's three pieces of gear on every slime (Config.Smithy).
local function team(slimeLevel: number?, tier: string?): { any }
	local out = {}
	for index = 1, Config.Zombies.TeamSize do
		local stats = Stats.starter()
		if slimeLevel then
			local share = slimeLevel / #Stats.Keys
			stats = { attack = share, defence = share, speed = share, hp = share * Config.Stats.HpPerLevel }
		end
		if tier then
			for _, piece in Config.Smithy.Gear do
				if piece.tier == tier then
					for key, points in piece.stats do
						stats[key] += points
					end
				end
			end
		end
		table.insert(out, {
			id = "s" .. index,
			attack = stats.attack,
			defence = stats.defence,
			speed = stats.speed,
			hp = stats.hp,
			-- (one slime of each way of fighting, as a mixed team)
			role = Config.Combat.Roles[(index - 1) % #Config.Combat.Roles + 1],
		})
	end
	return out
end

-- One run: returns the wave it ended in, whether it was cleared and its length in seconds.
local function run(slimeLevel: number?, tier: string?, seed: number): (number, boolean, number)
	local fight = Combat.new(team(slimeLevel, tier), {}, Rng.new(seed))
	fight.open = true
	local waveSeed = seed * 31
	for wave = 1, D.Waves do
		local queue = Dungeon.plan("meadow", LEVEL, wave, waveSeed)
		local next = 1
		local sinceSpawn = D.SpawnSeconds
		local started = fight.seconds
		while true do
			local alive = 0
			for _, unit in fight.units do
				if unit.side == "foe" and unit.hp > 0 then
					alive += 1
				end
			end
			if next > #queue and alive == 0 then
				break
			end
			sinceSpawn += STEP
			if next <= #queue and alive < D.MaxAlive and sinceSpawn >= D.SpawnSeconds then
				Combat.add(fight, queue[next], "foe")
				next += 1
				sinceSpawn = 0
			end
			Combat.step(fight, STEP)
			if fight.winner == "foe" or fight.seconds - started > Config.Zombies.FightMaxSeconds then
				return wave, false, fight.seconds
			end
		end
		-- the pause before the next wave: the team heals nothing, but healers of the next wave are not yet there
		for _ = 1, math.floor(D.PauseSeconds / STEP) do
			Combat.step(fight, STEP)
		end
	end
	return D.Waves, true, fight.seconds
end

print(
	string.format(
		"Slime Dungeon, dungeon level %d, %d seeds a team (StatScale %.2f, WaveGrowth %.2f)",
		LEVEL,
		SEEDS,
		D.StatScale,
		D.WaveGrowth
	)
)
print("team                 avg wave reached  cleared%  avg seconds")
local rows = {
	{ "4 starters (level 4)", nil },
	{ "starters, wood gear", nil, "wood" },
	{ "starters, iron gear", nil, "iron" },
	{ "4 slimes level 10", 10 },
	{ "4 slimes level 20", 20 },
	-- (stronger teams, to see where a first clear lies)
	{ "4 slimes level 40", 40 },
	{ "4 slimes level 80", 80 },
}
for _, row in rows do
	local waves, cleared, seconds = 0, 0, 0
	for seed = 1, SEEDS do
		local reached, won, length = run(row[2], row[3], seed)
		waves += reached
		cleared += if won then 1 else 0
		seconds += length
	end
	print(string.format("%-20s %16.1f %9.0f %12.0f", row[1], waves / SEEDS, cleared / SEEDS * 100, seconds / SEEDS))
end
