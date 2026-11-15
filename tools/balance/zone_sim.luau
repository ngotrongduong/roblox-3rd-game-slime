--!nocheck
-- How teams of four fare in the zones of the big world (Config.World.Zones) on the real Combat, Dungeon and ZoneFights rules,
-- as dungeon_sim does for the Dungeon (squad_run: positional, each slime with its class's weapon of its level's tier,
-- wounds kept from wave to wave).
--   lune run tools/balance/zone_sim.luau [seeds]            every zone as Config.World has it, against its target team
--   lune run tools/balance/zone_sim.luau [seeds] fit [win]  the `power` of every zone at which the target team wins `win`
--                                                           (0.75) of its fights, to copy into Config.World.Zones
-- The target team of a zone is a mixed team (TEAMS) of the level the zone shows (ZoneFights.level: the level of the packs
-- standing round it; docs/WORLD.md §7).
local process = require("@lune/process")
local Config = require("../../src/shared/Config")
local SquadRun = require("./squad_run")
local WorldPlan = require("../../src/shared/WorldPlan")
local ZoneFights = require("../../src/shared/ZoneFights")

local SEEDS = tonumber(process.args[1]) or 20
local FIT = process.args[2] == "fit"
local WIN = tonumber(process.args[3]) or 0.75
local TEAMS = { "GWRH", "WRMA", "GGHA" }

local function rate(zone: string, slimeLevel: number): (number, number)
	local won, seconds, runs = 0, 0, 0
	for _, letters in TEAMS do
		for seed = 1, SEEDS do
			local ok, _, length = SquadRun.run(SquadRun.team(letters, slimeLevel), ZoneFights.waves(zone), function(wave)
				return ZoneFights.plan(zone, wave, seed * 31)
			end, seed)
			runs += 1
			won += if ok then 1 else 0
			seconds += length
		end
	end
	return won / runs, seconds / runs
end

print(string.format("Zones of the big world, %d seeds a team%s", SEEDS, if FIT then ", fitted to win " .. WIN else ""))
print("| zone | tier | team | power | win | seconds | team 4 below | team 4 above |")
print("|---|---|---|---|---|---|---|---|")
for _, place in WorldPlan.Zones do
	local numbers = Config.World.Zones[place.id]
	local target = ZoneFights.level(place.id)
	if FIT then
		-- the win rate falls as the power rises: halve the bracket (in steps of a twentieth)
		local lo, hi = 0.1, 6
		for _ = 1, 10 do
			numbers.power = (lo + hi) / 2
			if rate(place.id, target) >= WIN then
				lo = numbers.power
			else
				hi = numbers.power
			end
		end
		numbers.power = math.floor(lo * 20) / 20
	end
	local win, seconds = rate(place.id, target)
	local weak = rate(place.id, math.max(4, target - 4))
	local strong = rate(place.id, target + 4)
	print(
		string.format(
			"| %s | %d | %d | %.2f | %.0f%% | %.0f | %.0f%% | %.0f%% |",
			place.id,
			place.tier,
			target,
			numbers.power or 1,
			win * 100,
			seconds,
			weak * 100,
			strong * 100
		)
	)
end
