--!nocheck
-- The weapon classes on the real Combat (docs/WEAPONS.md §10), positional as in the Slime Dungeon. First sweep:
--   dungeon: each team of four (four of one class, Brawlers, mixed) in full 10-wave runs on the meadow: the highest
--     dungeon level it clears in half the runs or more; then, at that level, the share of the time Rangers and Mages stand
--     out of the danger range, the skills cast and each class's share of the damage.
--   teams: team against team (the hard match-ups of §10, rarity, four of one class against a mixed team): the first team's
--     share of wins with the sides swapped every other seed, the draws (past 90 s, §7) and the average length.
--   lune run tools/balance/class_sim.luau [seeds] [part] [slimeLevel]
-- (a team is its letters: G guardian, W warrior, R ranger, M mage, H healer, A alchemist, B a Brawler with no weapon;
-- `part` is dungeon or teams, both when left out; the slimes are level 20 when slimeLevel is left out)
local process = require("@lune/process")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")

local SEEDS = tonumber(process.args[1]) or 40
local PART = process.args[2]
local LEVEL = tonumber(process.args[3]) or 20
local D = Config.Dungeon
local K = Config.Classes
local STEP = Config.Zombies.FightStepSeconds
local MAP = "meadow"
local DRAW_SECONDS = 90
local LETTERS = { G = "guardian", W = "warrior", R = "ranger", M = "mage", H = "healer", A = "alchemist" }
local FAMILY = {}
for family, class in K.Families do
	FAMILY[class] = family
end

-- A slime of `level` (spread evenly over its stats, as dungeon_sim) holding its class's weapon of `tier`; a Brawler holds
-- none and fights by its strongest stat, as today.
local function slime(id: string, letter: string, tier: string, seed: number): any
	local share = LEVEL / #Stats.Keys
	local f: any = { id = id, attack = share, defence = share, speed = share, hp = share * Config.Stats.HpPerLevel }
	local class = LETTERS[letter]
	if class then
		for key, points in Config.Smithy.Gear[FAMILY[class] .. "-" .. tier].stats do
			f[key] += points
		end
		f.class, f.tier, f.skills, f.role = class, K.Tiers[tier], {}, class
	end
	f.maxHp = f.hp
	if not class then
		f.role = Combat.role(f, seed)
	end
	return f
end

-- The team in the dungeon's squad row; `flip` stands it on the far side of the middle (the other team of a match-up).
local function team(letters: string, tier: string, prefix: string, seed: number, flip: boolean): { any }
	local out = {}
	for index = 1, #letters do
		local f = slime(prefix .. index, letters:sub(index, index), tier, seed + index)
		local x, z = Dungeon.squadSpot(index, #letters)
		f.x, f.z = if flip then -x else x, if flip then -z else z
		table.insert(out, f)
	end
	return out
end

local function newTally(): any
	return { ranged = 0, safe = 0, casts = {}, damage = {}, total = 0, healed = 0, hops = 0, dashes = 0 }
end

-- One step's events and the ranged units' places into the tally.
local function count(fight: any, events: { any }, tally: any, classOf: { [string]: string })
	for _, event in events do
		local class = classOf[event.from]
		if class then
			if event.kind == "hit" and event.amount then
				tally.damage[class] = (tally.damage[class] or 0) + event.amount
				tally.total += event.amount
			elseif event.kind == "heal" and event.amount then
				tally.healed += event.amount
			elseif event.kind == "move" and event.hop then
				tally.hops += 1
			elseif event.kind == "move" and event.dash then
				tally.dashes += 1
			end
			if event.kind == "aim" and event.skill then
				tally.casts[event.skill] = (tally.casts[event.skill] or 0) + 1
			end
		end
	end
	for _, u in fight.units do
		if u.hp > 0 and (u.class == "ranger" or u.class == "mage") and classOf[u.id] then
			local nearest = math.huge
			for _, other in fight.units do
				if other.side ~= u.side and other.hp > 0 then
					nearest = math.min(nearest, math.sqrt((u.x - other.x) ^ 2 + (u.z - other.z) ^ 2))
				end
			end
			if nearest < math.huge then
				tally.ranged += 1
				tally.safe += if nearest >= K.DangerStuds then 1 else 0
			end
		end
	end
end

-- One 10-wave run at this dungeon level, spawning as in play (dungeon_sim): the waves it cleared (D.Waves: all).
local function dungeonRun(letters: string, tier: string, level: number, seed: number, tally: any): number
	local rng = Rng.new(seed)
	local squad = team(letters, tier, "s", seed, false)
	local classOf = {}
	for _, f in squad do
		classOf[f.id] = f.class or "brawler"
	end
	local fight = Combat.new(squad, {}, rng, { moves = true, radius = D.ArenaRadius })
	fight.open = true
	for wave = 1, D.Waves do
		local queue = Dungeon.plan(MAP, level, wave, seed * 31)
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
			count(fight, Combat.step(fight, STEP), tally, classOf)
			if fight.winner == "foe" or fight.seconds - started > Config.Zombies.FightMaxSeconds then
				return wave - 1
			end
		end
		for _ = 1, math.floor(D.PauseSeconds / STEP) do
			Combat.step(fight, STEP)
		end
	end
	return D.Waves
end

-- The share of runs cleared and the average waves cleared.
local function clearShare(letters: string, tier: string, level: number, tally: any): (number, number)
	local cleared, waves = 0, 0
	for seed = 1, SEEDS do
		local done = dungeonRun(letters, tier, level, seed, tally)
		cleared += if done == D.Waves then 1 else 0
		waves += done
	end
	return cleared / SEEDS, waves / SEEDS
end

-- The highest level cleared in half the runs: up in doubling steps, then halving the gap.
local function bestLevel(letters: string, tier: string): number
	local low, high = 0, 1
	while high <= 512 and clearShare(letters, tier, high, newTally()) >= 0.5 do
		low, high = high, high * 2
	end
	while high - low > 1 do
		local mid = (low + high) // 2
		if clearShare(letters, tier, mid, newTally()) >= 0.5 then
			low = mid
		else
			high = mid
		end
	end
	return low
end

local function casts(tally: any): string
	local out = {}
	for key, n in tally.casts do
		table.insert(out, string.format("%s %.1f", key, n / SEEDS))
	end
	table.sort(out)
	return table.concat(out, ", ")
end

local function shares(tally: any): string
	local out = {}
	for class, amount in tally.damage do
		table.insert(out, string.format("%s %.0f%%", class, amount / math.max(1e-9, tally.total) * 100))
	end
	table.sort(out)
	return table.concat(out, ", ")
end

if PART == nil or PART == "dungeon" then
	print(string.format("## Dungeon (%s), slimes level %d, %d seeds a probe", MAP, LEVEL, SEEDS))
	print("")
	print(
		"| team | tier | best level | waves cleared a level up | ranged out of danger | skills a run | damage share | healed a run |"
	)
	print("|---|---|---|---|---|---|---|---|")
	local rows = {
		{ "WWWW", "wood" },
		{ "GGGG", "wood" },
		{ "RRRR", "wood" },
		{ "MMMM", "wood" },
		{ "HHHH", "wood" },
		{ "AAAA", "wood" },
		{ "BBBB", "wood" },
		{ "GWRH", "wood" },
		{ "GMMH", "wood" },
		{ "WRMA", "wood" },
		{ "GGHA", "wood" },
		{ "GWRH", "bramble" },
	}
	for _, row in rows do
		local best = bestLevel(row[1], row[2])
		local _, above = clearShare(row[1], row[2], best + 1, newTally())
		local tally = newTally()
		clearShare(row[1], row[2], math.max(1, best), tally)
		print(
			string.format(
				"| %s | %s | %d | %.1f | %s | %s | %s | %.0f |",
				row[1],
				row[2],
				best,
				above,
				if tally.ranged > 0 then string.format("%.0f%%", tally.safe / tally.ranged * 100) else "-",
				casts(tally),
				shares(tally),
				tally.healed / SEEDS
			)
		)
	end
	print("")
end

-- One match-up: the first team's win share, the draw share and the average length (sides swapped every other seed).
local function matchUp(a: string, tierA: string, b: string, tierB: string): (number, number, number)
	local wins, draws, seconds = 0, 0, 0
	for seed = 1, SEEDS do
		local aFirst = seed % 2 == 1
		local first = team(a, tierA, "a", seed, not aFirst)
		local second = team(b, tierB, "b", seed * 7, aFirst)
		local fight = if aFirst
			then Combat.new(first, second, Rng.new(seed), { moves = true, radius = D.ArenaRadius })
			else Combat.new(second, first, Rng.new(seed), { moves = true, radius = D.ArenaRadius })
		while not fight.winner and fight.seconds < DRAW_SECONDS do
			Combat.step(fight, STEP)
		end
		seconds += fight.seconds
		if not fight.winner then
			draws += 1
		elseif (fight.winner == "squad") == aFirst then
			wins += 1
		end
	end
	return wins / SEEDS, draws / SEEDS, seconds / SEEDS
end

if PART == nil or PART == "teams" then
	print(string.format("## Team against team, slimes level %d, %d seeds", LEVEL, SEEDS))
	print("")
	print("| first team | second team | question | first wins | draws | seconds |")
	print("|---|---|---|---|---|---|")
	local rows = {
		{ "GHHR", "wood", "WRMA", "wood", "can healing stall?" },
		{ "RRMH", "wood", "WWGA", "wood", "can melee reach range?" },
		{ "GGHA", "wood", "WRMA", "wood", "protected back row (65-70% at most)" },
		{ "GGHA", "iron", "WRMA", "iron", "protected back row (65-70% at most)" },
		{ "GGHA", "core", "WRMA", "core", "protected back row (65-70% at most)" },
		{ "GGHA", "bramble", "WRMA", "bramble", "protected back row (65-70% at most)" },
		{ "HHGW", "wood", "WWRM", "wood", "two Healers against hitters" },
		{ "GWRH", "wood", "GMAH", "wood", "both have a way to win" },
		{ "GMMH", "wood", "GWRH", "wood", "tank and mages clump" },
		{ "GWRH", "bramble", "GWRH", "wood", "Mythic over Common (60-65%)" },
	}
	for _, letter in { "W", "G", "R", "M", "H", "A", "B" } do
		table.insert(rows, { string.rep(letter, 4), "wood", "GWRH", "wood", "four of one class never the best" })
	end
	for _, row in rows do
		local win, draw, seconds = matchUp(row[1], row[2], row[3], row[4])
		print(
			string.format(
				"| %s %s | %s %s | %s | %.0f%% | %.0f%% | %.0f |",
				row[1],
				row[2],
				row[3],
				row[4],
				row[5],
				win * 100,
				draw * 100,
				seconds
			)
		)
	end
end
