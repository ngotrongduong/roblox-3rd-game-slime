--!nocheck
-- How teams of 4 fare in the zones of the big world (Config.World.Zones) on the real Combat, Dungeon and ZoneFights rules,
-- as dungeon_sim does for the Dungeon: spawning one monster every SpawnSeconds while fewer than MaxAlive stand, health
-- kept from wave to wave.
--   lune run tools/balance/zone_sim.luau [seeds]            every zone as Config.World has it, against its target team
--   lune run tools/balance/zone_sim.luau [seeds] fit [win]  the `level` of every zone at which the target team wins `win`
--                                                           (0.75) of its fights, to copy into Config.World.Zones
-- The target team of a zone is four even slimes of the level the zone shows (ZoneFights.level: the level of the packs
-- standing round it; docs/WORLD.md §7).
local process = require("@lune/process")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")
local WorldPlan = require("../../src/shared/WorldPlan")
local ZoneFights = require("../../src/shared/ZoneFights")

local SEEDS = tonumber(process.args[1]) or 40
local FIT = process.args[2] == "fit"
local WIN = tonumber(process.args[3]) or 0.75
local D = Config.Dungeon
local STEP = Config.Zombies.FightStepSeconds

local function team(slimeLevel: number): { any }
	local out = {}
	local share = slimeLevel / #Stats.Keys
	for index = 1, Config.Zombies.TeamSize do
		table.insert(out, {
			id = "s" .. index,
			attack = share,
			defence = share,
			speed = share,
			hp = share * Config.Stats.HpPerLevel,
			role = Config.Combat.Roles[(index - 1) % #Config.Combat.Roles + 1],
		})
	end
	return out
end

-- One fight: whether it was won, and its length in seconds.
local function run(zone: string, slimeLevel: number, seed: number): (boolean, number)
	local fight = Combat.new(team(slimeLevel), {}, Rng.new(seed))
	fight.open = true
	for wave = 1, ZoneFights.waves(zone) do
		local queue = ZoneFights.plan(zone, wave, seed * 31)
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
			if fight.winner == "foe" or fight.seconds - started > D.WaveMaxSeconds then
				return false, fight.seconds
			end
		end
		for _ = 1, math.floor(D.PauseSeconds / STEP) do
			Combat.step(fight, STEP)
		end
	end
	return true, fight.seconds
end

local function rate(zone: string, slimeLevel: number): (number, number)
	local won, seconds = 0, 0
	for seed = 1, SEEDS do
		local ok, length = run(zone, slimeLevel, seed)
		won += if ok then 1 else 0
		seconds += length
	end
	return won / SEEDS, seconds / SEEDS
end

print(string.format("Zones of the big world, %d seeds a row%s", SEEDS, if FIT then ", fitted to win " .. WIN else ""))
print("zone   tier team  level  win%  seconds   weaker team win%   stronger team win%")
for _, place in WorldPlan.Zones do
	local numbers = Config.World.Zones[place.id]
	local target = ZoneFights.level(place.id)
	if FIT then
		-- the win rate falls as the level rises: halve the bracket
		local lo, hi = -6, 40
		for _ = 1, 12 do
			numbers.level = (lo + hi) / 2
			if rate(place.id, target) >= WIN then
				lo = numbers.level
			else
				hi = numbers.level
			end
		end
		numbers.level = math.floor(lo * 20 + 0.5) / 20
	end
	local win, seconds = rate(place.id, target)
	local weak = rate(place.id, math.max(4, target - 4))
	local strong = rate(place.id, target + 4)
	print(
		string.format(
			"%-6s %4d %4d %6.2f %5.0f %8.0f %18.0f %20.0f",
			place.id,
			place.tier,
			target,
			numbers.level,
			win * 100,
			seconds,
			weak * 100,
			strong * 100
		)
	)
end
