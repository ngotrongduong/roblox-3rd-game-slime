--!strict
local Bots = require("../../src/shared/ArenaBots")
local Fight = require("../../src/shared/ArenaFight")
local Colours = require("../../src/shared/Colours")
local Config = require("../../src/shared/Config")
local Stats = require("../../src/shared/Stats")

return function(T)
	T.test("bot levels are fixed to id and clamp at both ends", function()
		local c = Config.Arena
		T.eq(Bots.level("b1"), c.BotLevelMax)
		T.eq(Bots.level("b" .. c.Bots), c.BotLevelMin)
		T.eq(Bots.level("b1001"), c.BotLevelMin)
		T.eq(Bots.level("b0"), c.BotLevelMax)
		T.eq(Bots.level("b-12"), c.BotLevelMax)
		T.near(
			Bots.level("b500"),
			c.BotLevelMin + (c.BotLevelMax - c.BotLevelMin) * ((c.Bots - 500) / (c.Bots - 1)) ^ c.BotLevelExponent,
			1e-9
		)
	end)
	T.test("the level pyramid has far more beginners than summit rivals", function()
		local c = Config.Arena
		local low, high, previous = 0, 0, math.huge
		local fifth = (c.BotLevelMax - c.BotLevelMin) / 5
		for index = 1, c.Bots do
			local level = Bots.level("b" .. index)
			T.ok(level <= previous and level >= c.BotLevelMin and level <= c.BotLevelMax)
			previous = level
			if level <= c.BotLevelMin + fifth then
				low += 1
			end
			if level >= c.BotLevelMax - fifth then
				high += 1
			end
		end
		T.ok(low > high * 5, "bottom fifth should be at least five times the top fifth")
	end)
	T.test("a season and id rebuild the exact team, a new season changes it", function()
		for _, id in { "b1", "b500", "b1000", "c1" } do
			local first = Bots.team(202611, id)
			T.same(first, Bots.team(202611, id))
			local nextTeam = Bots.team(202612, id)
			local different = false
			for index, fighter in first.fighters do
				if fighter.attack ~= nextTeam.fighters[index].attack then
					different = true
				end
			end
			T.ok(different)
			T.eq(first.name, nextTeam.name)
		end
	end)
	T.test("NPCs use full-health common slimes with stats measured in slime levels", function()
		local c = Config.Arena
		for _, id in { "b1", "b200", "b500", "b1000", "c1" } do
			local team = Bots.team(202611, id)
			local base = if Bots.isChampion(id) then c.ChampionLevel(202611) else Bots.level(id)
			T.eq(#team.fighters, c.TeamSize)
			T.eq(#team.looks, c.TeamSize)
			T.eq(team.power, Fight.power(team.fighters))
			local seen = {}
			for index, fighter in team.fighters do
				T.ok(not seen[fighter.id])
				seen[fighter.id] = true
				T.eq(fighter.hp, fighter.maxHp)
				local level = Stats.level(fighter)
				T.ok(level >= math.floor(base * (1 - c.BotLevelSpread)))
				T.ok(level <= math.ceil(base * (1 + c.BotLevelSpread)))
				T.ok(Colours.isValid(team.looks[index].Colour))
				T.eq(team.looks[index].DualId, nil)
				T.eq(team.looks[index].SecretId, nil)
				T.eq(team.looks[index].Material, nil)
			end
		end
	end)
	T.test("NPCs hold weapons: different classes, the tier of their level", function()
		local c = Config.Arena
		T.eq(Bots.tier(c.BotLevelMin), 1)
		T.eq(Bots.tier(c.BotLevelMax), 4)
		T.eq(Bots.tier(c.ChampionLevel(202611)), 5)
		local classes = {}
		for _, id in { "b1", "b200", "b500", "b1000", "c1" } do
			local team = Bots.team(202611, id)
			local base = if Bots.isChampion(id) then c.ChampionLevel(202611) else Bots.level(id)
			local inTeam = {}
			for index, fighter in team.fighters do
				local class = fighter.class :: string
				T.ok(Config.Classes.Kinds[class] ~= nil)
				T.ok(not inTeam[class], "a team's classes differ")
				inTeam[class], classes[class] = true, true
				T.eq(fighter.role, class)
				T.eq(fighter.tier, Bots.tier(base))
				T.same(fighter.skills, {})
				-- the replay shows that weapon in hand
				T.ok(Fight.view(team.fighters, "d:")[index].hand ~= nil)
			end
		end
		local count = 0
		for _ in classes do
			count += 1
		end
		T.ok(count >= 5, "the teams use most classes")
	end)
	T.test("NPC names and identifiers clearly distinguish rivals and champions", function()
		T.ok(Bots.isBot("b1"))
		T.ok(Bots.isBot("b1000"))
		for _, id in { "c1", "123", "b0", "b1001", "b-1", "b01", "b1junk" } do
			T.eq(Bots.isBot(id), false)
		end
		T.ok(Bots.isChampion("c1"))
		T.ok(Bots.isChampion("c10000"))
		for _, id in { "b1", "c0", "c01", "c-1", "12", "c1junk" } do
			T.eq(Bots.isChampion(id), false)
		end
		T.eq(string.sub(Bots.name("b1"), 1, 6), "Rival ")
		T.eq(string.sub(Bots.name("c1"), 1, 9), "Champion ")
		T.eq(Bots.name("b20"), Bots.name("b20"))
	end)
end
