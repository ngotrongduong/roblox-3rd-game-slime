--!nocheck
-- A team of four in a run of waves on the real Combat, positional as the Slime Dungeon and the zones are fought: what
-- dungeon_sim and zone_sim share. Each slime holds its class's weapon of the tier a player has at its level; the team keeps
-- its wounds from wave to wave; monsters come in one every SpawnSeconds while fewer than MaxAlive stand.
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")

local D = Config.Dungeon
local K = Config.Classes
local STEP = Config.Zombies.FightStepSeconds
local LETTERS = { G = "guardian", W = "warrior", R = "ranger", M = "mage", H = "healer", A = "alchemist" }
local FAMILY = {}
for family, class in K.Families do
	FAMILY[class] = family
end

local SquadRun = {}

-- The weapon tier a player holds at this slime level (the stages of the 2026-11-15 plan, docs/SMITHY.md).
function SquadRun.tierAt(level: number): string
	if level < 8 then
		return "wood"
	elseif level < 23 then
		return "iron"
	elseif level < 68 then
		return "core"
	elseif level < 110 then
		return "bramble"
	end
	return "legend"
end

-- A team of four of this level (spread evenly over the stats) by its letters (G guardian, W warrior, R ranger, M mage,
-- H healer, A alchemist), each with its class's weapon of the level's tier, in the dungeon's squad rows.
function SquadRun.team(letters: string, level: number): { any }
	local tier = SquadRun.tierAt(level)
	local out, rows = {}, {}
	for index = 1, #letters do
		local share = math.max(level, 1) / #Stats.Keys
		local f: any = {
			id = "s" .. index,
			attack = share,
			defence = share,
			speed = share,
			hp = share * Config.Stats.HpPerLevel,
		}
		local class = LETTERS[letters:sub(index, index)]
		for key, points in Config.Smithy.Gear[FAMILY[class] .. "-" .. tier].stats do
			f[key] += points
		end
		f.class, f.tier, f.skills, f.role = class, K.Tiers[tier], {}, class
		f.maxHp = f.hp
		f.row = K.Rows.Default[class]
		table.insert(out, f)
		table.insert(rows, f.row)
	end
	local spots = Dungeon.squadSpots(rows)
	for index, f in out do
		f.x, f.z = spots[index].x, spots[index].z
	end
	return out
end

-- One run of `waves` waves, `plan(wave)` giving each wave's monsters: whether it was won, the waves cleared and its length
-- in seconds.
function SquadRun.run(squad: { any }, waves: number, plan: (number) -> { any }, seed: number): (boolean, number, number)
	local rng = Rng.new(seed)
	local fight = Combat.new(squad, {}, rng, {
		moves = true,
		radius = D.ArenaRadius,
		tactics = { squad = "balanced" },
	})
	fight.open = true
	for wave = 1, waves do
		local queue = plan(wave)
		local next = 1
		local sinceSpawn = D.SpawnSeconds
		local started = fight.seconds
		while true do
			local alive = 0
			local taken = {}
			for _, u in fight.units do
				if u.hp > 0 then
					table.insert(taken, u)
					alive += if u.side == "foe" then 1 else 0
				end
			end
			if next > #queue and alive == 0 then
				break
			end
			sinceSpawn += STEP
			if next <= #queue and alive < D.MaxAlive and sinceSpawn >= D.SpawnSeconds then
				local monster = table.clone(queue[next])
				monster.x, monster.z = Dungeon.spawnPoint(rng, taken)
				Combat.add(fight, monster, "foe")
				next += 1
				sinceSpawn = 0
			end
			Combat.step(fight, STEP)
			if fight.winner == "foe" or fight.seconds - started > D.WaveMaxSeconds then
				return false, wave - 1, fight.seconds
			end
		end
		for _ = 1, math.floor(D.PauseSeconds / STEP) do
			Combat.step(fight, STEP)
		end
	end
	return true, waves, fight.seconds
end

return SquadRun
