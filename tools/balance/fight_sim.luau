--!strict
-- How 4-slime squads fare against zombie groups at each player level: wins, losses, length and coins, on the real
-- Combat and Zombies rules. Squads have even stats. lune run tools/balance/fight_sim.luau [fights]
local process = require("@lune/process")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Mutations = require("../../src/shared/Mutations")
local Rng = require("../../src/shared/Rng")
local Zombies = require("../../src/shared/Zombies")

local FIGHTS = tonumber(process.args[1]) or 500

print("level group  win%  deaths/fight  seconds  coins/fight  coins/min")
for _, level in { 4, 8, 12, 20, 30, 40, 60 } do
	for camp, offset in Config.Zombies.LevelOffsets do
		local wins, deaths, seconds, coins = 0, 0, 0, 0
		for seed = 1, FIGHTS do
			local rng = Rng.new(seed * 7 + level + offset)
			local share = level / 4
			local squad = {}
			for index = 1, Config.Zombies.TeamSize do
				table.insert(squad, {
					id = "s" .. index,
					attack = share,
					defence = share,
					speed = share,
					hp = share * Config.Stats.HpPerLevel,
				})
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
		print(
			string.format(
				"%5d %5d %5.0f %13.2f %8.0f %12.0f %10.0f",
				level,
				level + offset,
				wins / FIGHTS * 100,
				deaths / FIGHTS,
				seconds / FIGHTS,
				coins / FIGHTS,
				coins / seconds * 60
			)
		)
	end
end
