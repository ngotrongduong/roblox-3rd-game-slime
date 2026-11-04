--!strict
local ArenaFight = if script then require(script.Parent.ArenaFight) else require("./ArenaFight")
local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local Combat = if script then require(script.Parent.Combat) else require("./Combat")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Fighter = typeof(ArenaFight.fighter(FarmState.newFarm(0).slimes[1], ""))
export type Look = { Colour: string, Material: string?, DualId: string?, SecretId: string? }
export type Team = { name: string, power: number, fighters: { Fighter }, looks: { Look } }
local ArenaBots = {}

function ArenaBots.isBot(id: string): boolean
	local index = tonumber(string.match(id, "^b([1-9]%d*)$"))
	return index ~= nil and index <= Config.Arena.Bots
end

function ArenaBots.isChampion(id: string): boolean
	return string.match(id, "^c[1-9]%d*$") ~= nil
end

function ArenaBots.level(botId: string): number
	local c = Config.Arena
	local index = math.clamp(tonumber(string.match(botId, "^b(%-?%d+)$")) or c.Bots, 1, c.Bots)
	local share = if c.Bots > 1 then (c.Bots - index) / (c.Bots - 1) else 1
	return math.clamp(
		c.BotLevelMin + (c.BotLevelMax - c.BotLevelMin) * share ^ c.BotLevelExponent,
		c.BotLevelMin,
		c.BotLevelMax
	)
end

function ArenaBots.name(id: string): string
	local rng = Rng.new(Rng.hash("arena:name:" .. id))
	local c = Config.Arena
	local prefix = if ArenaBots.isChampion(id) then "Champion " else "Rival "
	return prefix .. rng:pick(c.NameStarts) .. rng:pick(c.NameEnds)
end

function ArenaBots.team(season: number, id: string): Team
	assert(ArenaBots.isBot(id) or ArenaBots.isChampion(id), "Unknown Arena NPC")
	local c = Config.Arena
	local level = if ArenaBots.isChampion(id) then c.ChampionLevel(season) else ArenaBots.level(id)
	local rng = Rng.new(Rng.hash("arena:" .. season .. ":" .. id))
	local fighters: { Fighter } = {}
	local looks: { Look } = {}
	for index = 1, c.TeamSize do
		local seed = Rng.hash("arena:" .. season .. ":" .. id .. ":" .. index)
		local varied = math.max(c.BotLevelMin, level * (1 + (rng:next() * 2 - 1) * c.BotLevelSpread))
		local favourite = rng:pick(Stats.Keys)
		local total = #Stats.Keys - 1 + c.BotFavouriteWeight
		local stats = Stats.starter()
		for _, key in Stats.Keys do
			local value = varied * (if key == favourite then c.BotFavouriteWeight else 1) / total
			Stats.set(stats, key, value * (if key == "hp" then Config.Stats.HpPerLevel else 1))
		end
		local fighter: Fighter = {
			id = id .. ":" .. index,
			attack = stats.attack,
			defence = stats.defence,
			speed = stats.speed,
			hp = stats.hp,
			maxHp = stats.hp,
		}
		fighter.role = Combat.role(fighter, seed)
		table.insert(fighters, fighter)
		table.insert(looks, { Colour = rng:pick(Colours.Ids) })
	end
	return { name = ArenaBots.name(id), power = ArenaFight.power(fighters), fighters = fighters, looks = looks }
end

return ArenaBots
