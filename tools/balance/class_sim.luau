--!nocheck
-- The weapon classes on the real Combat (docs/WEAPONS.md §10):
--   dungeon: each team of four (four of one class, Brawlers, mixed) in full 10-wave runs on the meadow, positional as in
--     the Slime Dungeon: the highest dungeon level it clears in half the runs or more; then, at that level, the share of
--     the time Rangers and Mages stand out of the danger range, the skills cast and each class's share of the damage.
--   teams: team against team as the Arena fights them (ArenaFight.simulate: not positional, heals fading, the timeout
--     decided by who stands): the hard match-ups of §10 and four of one class against a mixed team. The first team's share
--     of wins (it attacks on odd seeds, defends on even ones), its healing as a share of the damage it took, the length.
--   tiers: each tier's team against the same team with Common weapons, at the same slime stats and at the same Arena power
--     (the Common slimes get the level points the better weapons add, as the Arena's matching counts them).
--   lune run tools/balance/class_sim.luau [seeds] [part] [slimeLevel]
-- (a team is its letters: G guardian, W warrior, R ranger, M mage, H healer, A alchemist, B a Brawler with no weapon;
-- `part` is dungeon, teams or tiers, all when left out; the slimes are level 20 when slimeLevel is left out)
local process = require("@lune/process")
local ArenaFight = require("../../src/shared/ArenaFight")
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
local LETTERS = { G = "guardian", W = "warrior", R = "ranger", M = "mage", H = "healer", A = "alchemist" }
local FAMILY = {}
for family, class in K.Families do
	FAMILY[class] = family
end

-- A slime of LEVEL (and `extra` level points; spread evenly over its stats, as dungeon_sim) holding its class's weapon
-- of `tier`; a Brawler holds none and fights by its strongest stat, as today.
local function slime(id: string, letter: string, tier: string, seed: number, extra: number?): any
	local share = (LEVEL + (extra or 0)) / #Stats.Keys
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

-- The level points a weapon adds, as the Arena's power counts them (hp per level).
local function points(letter: string, tier: string): number
	local class = LETTERS[letter]
	if not class then
		return 0
	end
	local sum = 0
	for key, n in Config.Smithy.Gear[FAMILY[class] .. "-" .. tier].stats do
		sum += if key == "hp" then n / Config.Stats.HpPerLevel else n
	end
	return sum
end

-- The team in the dungeon's squad row; `flip` stands it on the far side of the middle (the other team of a match-up).
-- `extras` are each slime's extra level points.
local function team(letters: string, tier: string, prefix: string, seed: number, flip: boolean, extras: { number }?): { any }
	local out = {}
	for index = 1, #letters do
		local f = slime(prefix .. index, letters:sub(index, index), tier, seed + index, extras and extras[index])
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

-- One match-up as the Arena fights it: the first team attacks on odd seeds and defends on even ones. Its win share, the
-- share of fights that ran to the time limit, its healing as a share of the damage it took, and the average length.
-- `extras` are the second team's slimes' extra level points.
local function matchUp(a: string, tierA: string, b: string, tierB: string, extras: { number }?): (number, number, number, number)
	local wins, timeouts, seconds, healed, taken = 0, 0, 0, 0, 0
	for seed = 1, SEEDS do
		local aAttacks = seed % 2 == 1
		local first = team(a, tierA, "a", seed, false)
		local second = team(b, tierB, "b", seed * 7, false, extras)
		local replay = if aAttacks
			then ArenaFight.simulate(first, second, seed)
			else ArenaFight.simulate(second, first, seed)
		seconds += replay.seconds
		timeouts += if replay.seconds >= Config.Arena.MaxFightSeconds - 1e-6 then 1 else 0
		wins += if replay.won == aAttacks then 1 else 0
		-- (the first team's fighters are "a:a1" or "d:a1": the letter after the side's prefix)
		for _, step in replay.steps do
			for _, event in step.events do
				if event.kind == "heal" and event.amount and event.from:sub(3, 3) == "a" then
					healed += event.amount
				elseif event.kind == "hit" and event.amount and event.to:sub(3, 3) == "a" then
					taken += event.amount
				end
			end
		end
	end
	return wins / SEEDS, timeouts / SEEDS, healed / math.max(1e-9, taken), seconds / SEEDS
end

local function matchRow(a: string, tierA: string, b: string, tierB: string, question: string, extras: { number }?)
	local win, timeout, heal, seconds = matchUp(a, tierA, b, tierB, extras)
	print(
		string.format(
			"| %s %s | %s %s | %s | %.0f%% | %.0f%% | %.0f%% | %.0f |",
			a,
			tierA,
			b,
			tierB,
			question,
			win * 100,
			timeout * 100,
			heal * 100,
			seconds
		)
	)
end

local HEADER = "| first team | second team | question | first wins | to the limit | first healed / taken | seconds |"

if PART == nil or PART == "teams" then
	print(string.format("## Team against team (the Arena's fight), slimes level %d, %d seeds", LEVEL, SEEDS))
	print("")
	print(HEADER)
	print("|---|---|---|---|---|---|---|")
	local rows = {
		{ "GWRH", "wood", "GWRH", "wood", "the mirror (50%)" },
		{ "GHHR", "wood", "WRMA", "wood", "can healing stall?" },
		{ "RRMH", "wood", "WWGA", "wood", "ranged against melee" },
		{ "GGHA", "wood", "WRMA", "wood", "protected back row (65-70% at most)" },
		{ "HHGW", "wood", "WWRM", "wood", "two Healers against hitters" },
		{ "GWRH", "wood", "GMAH", "wood", "both have a way to win" },
		{ "GMMH", "wood", "GWRH", "wood", "tank and mages clump" },
		{ "GWRH", "wood", "WRMA", "wood", "one Healer against none" },
	}
	for _, letter in { "W", "G", "R", "M", "H", "A", "B" } do
		table.insert(rows, { string.rep(letter, 4), "wood", "GWRH", "wood", "four of one class never the best" })
	end
	table.insert(rows, { "GWRH", "wood", "BBBB", "wood", "weapons over none, same stats" })
	for _, row in rows do
		matchRow(row[1], row[2], row[3], row[4], row[5])
	end
	print("")
end

if PART == nil or PART == "tiers" then
	print(string.format("## Tiers against Common (the Arena's fight), slimes level %d, %d seeds", LEVEL, SEEDS))
	print("")
	print(HEADER)
	print("|---|---|---|---|---|---|---|")
	for _, letters in { "GWRH", "WRMA" } do
		for index = 2, #Config.Smithy.TierOrder do
			local tier = Config.Smithy.TierOrder[index]
			matchRow(letters, tier, letters, "wood", "same stats")
			local extras = {}
			for slot = 1, #letters do
				local letter = letters:sub(slot, slot)
				extras[slot] = points(letter, tier) - points(letter, "wood")
			end
			matchRow(letters, tier, letters, "wood", "same Arena power", extras)
		end
	end
	-- a well-built Common team against badly built Mythic and Legendary ones, at the same slime stats
	for _, letter in { "W", "G", "M", "A", "H" } do
		for _, tier in { "bramble", "legend" } do
			matchRow("GWRH", "wood", string.rep(letter, 4), tier, "a good Common build against a poor one")
		end
	end
	-- (the Brawlers get the level points the Common weapons add: the class against none at the same power)
	local extras = {}
	for slot = 1, 4 do
		extras[slot] = points(("GWRH"):sub(slot, slot), "wood")
	end
	matchRow("GWRH", "wood", "BBBB", "wood", "weapons over none, same Arena power", extras)
	print("")
end
