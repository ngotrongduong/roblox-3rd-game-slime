--!nocheck
-- How 4-slime squads fare against zombie groups at each player level: wins, losses, length and coins, on the real
-- Combat and Zombies rules. Squads have even stats. Then the same with the dish buffs on the squad (Zombies.fighter applies
-- them, as in play): every rarity's buff, with the four slimes on four different stats ("mixed", one dish each) and all
-- four on one stat. lune run tools/balance/fight_sim.luau [fights]
local process = require("@lune/process")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Mutations = require("../../src/shared/Mutations")
local Rng = require("../../src/shared/Rng")
local Zombies = require("../../src/shared/Zombies")

local FIGHTS = tonumber(process.args[1]) or 500
local STATS = { "attack", "defence", "speed", "hp" }
local RARITIES = { "common", "uncommon", "rare", "epic" }

-- buff: nil, or { rarity = "epic", stat = "attack" | "mixed" }
local function batch(level: number, camp: number, offset: number, buff: { rarity: string, stat: string }?)
	local wins, deaths, seconds, coins = 0, 0, 0, 0
	for seed = 1, FIGHTS do
		local rng = Rng.new(seed * 7 + level + offset)
		local share = level / 4
		local squad = {}
		for index = 1, Config.Zombies.TeamSize do
			local slime = {
				id = "s" .. index,
				stats = { attack = share, defence = share, speed = share, hp = share * Config.Stats.HpPerLevel },
				needs = FarmState.fullNeeds(),
				buff = nil :: any,
			}
			if buff then
				local stat = if buff.stat == "mixed" then STATS[(index - 1) % #STATS + 1] else buff.stat
				slime.buff = {
					stat = stat,
					percent = Config.Food.DishRarities[buff.rarity].percent,
					untilTime = math.huge,
					dish = "x",
				}
			end
			table.insert(squad, Zombies.fighter(slime, 0, 1))
		end
		local group = Zombies.group("z", level, camp, rng)
		local byId = {}
		for _, zombie in group do
			byId[zombie.id] = zombie
		end
		local fight = Combat.new(squad, group, rng)
		while not fight.winner do
			for _, event in Combat.step(fight, 0.1) do
				if event.kind == "fallen" then
					local zombie = byId[event.to]
					if zombie then
						coins += Zombies.killReward(zombie.kind, zombie.level)
					else
						deaths += 1
						coins += Mutations.sellValue({ type = "none" } :: any, level)
					end
				end
			end
		end
		seconds += fight.seconds
		if fight.winner == "squad" then
			wins += 1
		end
	end
	return wins / FIGHTS * 100, deaths / FIGHTS, seconds / FIGHTS, coins / FIGHTS, coins / seconds * 60
end

print("level group  win%  deaths/fight  seconds  coins/fight  coins/min")
for _, level in { 4, 8, 12, 20, 30, 40, 60 } do
	for camp, offset in Config.Zombies.LevelOffsets do
		local win, deaths, seconds, coins, perMinute = batch(level, camp, offset, nil)
		print(string.format("%5d %5d %5.0f %13.2f %8.0f %12.0f %10.0f", level, level + offset, win, deaths, seconds, coins, perMinute))
	end
end

print("\nWith dish buffs on the squad (the buff lasts the whole fight)")
print("level group  buff               win%  deaths/fight  seconds  coins/min  (coins/min vs none)")
local rows = { { "none", nil } }
for _, rarity in RARITIES do
	table.insert(rows, { rarity .. " mixed", { rarity = rarity, stat = "mixed" } })
end
for _, stat in STATS do
	table.insert(rows, { "epic all " .. stat, { rarity = "epic", stat = stat } })
end
for _, level in { 4, 20, 60 } do
	for camp, offset in Config.Zombies.LevelOffsets do
		local base = 0
		for _, row in rows do
			local win, deaths, seconds, _, perMinute = batch(level, camp, offset, row[2])
			if row[1] == "none" then
				base = perMinute
			end
			print(
				string.format(
					"%5d %5d  %-17s %5.0f %13.2f %8.0f %10.0f  %+5.1f%%",
					level,
					level + offset,
					row[1],
					win,
					deaths,
					seconds,
					perMinute,
					(perMinute / base - 1) * 100
				)
			)
		end
	end
end
