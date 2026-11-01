--!strict
-- The zombie slimes outside the village (the owner, 2026-11-02): groups a little around the player's own level, rarer
-- kinds worth more, and coins for every slime killed on either side, by its level and rarity.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Farm = typeof(FarmState.newFarm(0))
type Rng = typeof(Rng.new(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])
export type Zombie = {
	id: string,
	kind: string,
	level: number,
	attack: number,
	defence: number,
	speed: number,
	hp: number,
}

local Zombies = {}

local function canFight(farm: Farm, slime: Slime, now: number): boolean
	if slime.ghostUntil and slime.ghostUntil > now then
		return false
	end
	return not Growth.isBaby(
		slime.createdAt,
		now,
		Stats.level(slime.stats),
		farm.areas.breeding.level - Config.Village.StartLevel
	)
end

-- The average level of the strongest slimes one trip can send, so keeping weak slimes at home cannot make zombies easier.
function Zombies.playerLevel(farm: Farm, now: number): number
	local levels: { number } = {}
	for _, slime in farm.slimes do
		if canFight(farm, slime, now) then
			table.insert(levels, Stats.level(slime.stats))
		end
	end
	if #levels == 0 then
		return Stats.level(Stats.starter())
	end
	table.sort(levels, function(a: number, b: number): boolean
		return a > b
	end)
	local count = math.min(#levels, Config.Zombies.Teams * Config.Zombies.TeamSize)
	local sum = 0
	for index = 1, count do
		sum += levels[index]
	end
	return math.floor(sum / count)
end

-- The level of each camp for a player of this level: the same, a little above, far above.
function Zombies.campLevels(playerLevel: number): { number }
	local out: { number } = {}
	for _, offset in Config.Zombies.LevelOffsets do
		table.insert(out, playerLevel + offset)
	end
	return out
end

function Zombies.rollKind(camp: number, rng: Rng): string
	local z = Config.Zombies
	local sum = 0
	for _, id in z.KindOrder do
		sum += (z.Kinds :: any)[id].weights[camp]
	end
	local at = rng:next() * sum
	for _, id in z.KindOrder do
		at -= (z.Kinds :: any)[id].weights[camp]
		if at < 0 then
			return id
		end
	end
	return z.KindOrder[1]
end

-- Stats share a level the way a slime's do (level = attack + defence + speed + hp / 10), scaled by the camp so a squad of
-- the same level usually wins and the top camp is a real risk at any level.
function Zombies.make(id: string, kind: string, playerLevel: number, camp: number): Zombie
	local share = playerLevel / #Stats.Keys * Config.Zombies.StatFactors[camp]
	return {
		id = id,
		kind = kind,
		level = playerLevel + Config.Zombies.LevelOffsets[camp],
		attack = share,
		defence = share,
		speed = share,
		hp = math.max(1, share * Config.Stats.HpPerLevel),
	}
end

-- A group of the camp (1..#LevelOffsets) for a player of this level.
function Zombies.group(prefix: string, playerLevel: number, camp: number, rng: Rng): { Zombie }
	local out: { Zombie } = {}
	for index = 1, Config.Zombies.TeamSize do
		table.insert(out, Zombies.make(prefix .. "-" .. index, Zombies.rollKind(camp, rng), playerLevel, camp))
	end
	return out
end

-- Coins for a dead slime on either side follow one rule: its rarity's base, raised by its level (Mutations.sellValue).
function Zombies.killReward(kind: string, level: number): number
	local factor = 1 + math.max(0, level) * Config.Economy.SellLevelStep
	return math.floor((Config.Zombies.Kinds :: any)[kind].base * factor)
end

function Zombies.deathReward(slime: Slime): number
	return Mutations.sellValue(slime.appearanceMutation, Stats.level(slime.stats))
end

return Zombies
