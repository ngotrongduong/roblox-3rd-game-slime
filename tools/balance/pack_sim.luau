--!nocheck
-- How a 4-slime team of one level fares against the world's packs of another level (3-5 monsters of the Sunny Meadow, as
-- WorldPacks rolls them), on the real Combat, Zombies and WorldPacks rules: wins, slimes that fall, length, coins. Teams
-- have even stats and one slime of each way of fighting. Used to choose Config.World.Packs.StatFactor and to feed
-- road_sim.luau.
--   lune run tools/balance/pack_sim.luau [fights] [StatFactor]
-- (StatFactor tries another value of Config.World.Packs' without editing it)
local process = require("@lune/process")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Mutations = require("../../src/shared/Mutations")
local Rng = require("../../src/shared/Rng")
local WorldPacks = require("../../src/shared/WorldPacks")
local Zombies = require("../../src/shared/Zombies")

local Sim = {}

-- One batch: returns win share, slimes fallen a fight, seconds a fight, coins a fight (kills and our own falls), the win
-- share against packs of five and the slimes fallen a fight against them.
function Sim.batch(teamLevel: number, packLevel: number, fights: number)
	local wins, deaths, seconds, coins = 0, 0, 0, 0
	local fiveFights, fiveWins, fiveDeaths = 0, 0, 0
	for seed = 1, fights do
		local rng = Rng.new(seed * 7 + teamLevel * 131 + packLevel)
		local share = teamLevel / 4
		local squad = {}
		for index = 1, Config.Zombies.TeamSize do
			local slime = {
				id = "s" .. index,
				seed = index,
				stats = { attack = share, defence = share, speed = share, hp = share * Config.Stats.HpPerLevel },
				needs = FarmState.fullNeeds(),
			}
			local fighter: any = Zombies.fighter(slime, 0, 1)
			fighter.role = Config.Combat.Roles[(index - 1) % #Config.Combat.Roles + 1]
			table.insert(squad, fighter)
		end
		local group = WorldPacks.pack("z", "meadow", packLevel, rng)
		local byId = {}
		for _, monster in group do
			byId[monster.id] = monster
		end
		local fight = Combat.new(squad, group, rng)
		local fell = 0
		while not fight.winner and fight.seconds < Config.Zombies.FightMaxSeconds do
			for _, event in Combat.step(fight, Config.Zombies.FightStepSeconds) do
				if event.kind == "fallen" then
					local monster = byId[event.to]
					if monster then
						coins += WorldPacks.killReward(monster.defRole, monster.level)
					else
						fell += 1
						coins += Mutations.sellValue({ type = "none" } :: any, teamLevel)
					end
				end
			end
		end
		deaths += fell
		seconds += fight.seconds
		local won = fight.winner == "squad"
		if won then
			wins += 1
		end
		if #group == 5 then
			fiveFights += 1
			fiveDeaths += fell
			if won then
				fiveWins += 1
			end
		end
	end
	return wins / fights,
		deaths / fights,
		seconds / fights,
		coins / fights,
		fiveWins / math.max(1, fiveFights),
		fiveDeaths / math.max(1, fiveFights)
end

if process.args[1] ~= "lib" then
	local FIGHTS = tonumber(process.args[1]) or 300
	Config.World.Packs.StatFactor = tonumber(process.args[2]) or Config.World.Packs.StatFactor
	print(string.format("StatFactor %.2f, %d fights a row", Config.World.Packs.StatFactor, FIGHTS))
	print("team  pack  win%  fall/fight  seconds  coins/fight | packs of five: win%  fall/fight")
	for _, teamLevel in { 4, 8, 12, 20, 40, 80 } do
		local seen = {}
		for _, ratio in { 0.6, 0.8, 1, 1.2, 1.4, 1.7 } do
			local packLevel = math.max(Config.World.Packs.LevelMin, math.floor(teamLevel * ratio + 0.5))
			if not seen[packLevel] then
				seen[packLevel] = true
				local win, deaths, seconds, coins, fiveWin, fiveDeaths = Sim.batch(teamLevel, packLevel, FIGHTS)
				print(
					string.format(
						"%4d %5d %5.0f %11.2f %8.0f %12.0f | %19.0f %11.2f",
						teamLevel,
						packLevel,
						win * 100,
						deaths,
						seconds,
						coins,
						fiveWin * 100,
						fiveDeaths
					)
				)
			end
		end
	end
end

return Sim
