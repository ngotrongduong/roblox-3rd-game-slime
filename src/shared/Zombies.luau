--!strict
-- The zombie slimes outside the village (the owner, 2026-11-02): groups a little around the player's own level, rarer
-- kinds worth more, and coins for every slime killed on either side, by its level and rarity.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
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

function Zombies.pay(farm: Farm, amount: number)
	farm.coins += amount
	farm.lifetime.coinsEarned += amount
end

-- Whether a slime can join a squad: grown up, alive, awake and not busy at a job or a nest.
function Zombies.canSend(farm: Farm, slime: Slime, now: number): boolean
	if not canFight(farm, slime, now) or slime.sleeping or Needs.isTired(slime.needs) then
		return false
	end
	if Stations.isBusy(farm, slime.id) then
		return false
	end
	for _, pair in farm.breeding.pairs do
		if pair.a == slime.id or pair.b == slime.id then
			return false
		end
	end
	return true
end

-- A slime as it fights: hungry at half strength (docs/MAP.md), its dish buff on top.
function Zombies.fighter(
	slime: Slime,
	now: number
): { id: string, attack: number, defence: number, speed: number, hp: number }
	local factor = if Needs.isHungry(slime.needs) then Config.Needs.HungryWorkFactor else 1
	local stats =
		{ attack = slime.stats.attack, defence = slime.stats.defence, speed = slime.stats.speed, hp = slime.stats.hp }
	local buff = slime.buff
	if buff and buff.untilTime > now and (stats :: any)[buff.stat] then
		(stats :: any)[buff.stat] *= 1 + buff.percent / 100
	end
	return {
		id = slime.id,
		attack = stats.attack * factor,
		defence = stats.defence,
		speed = stats.speed,
		hp = stats.hp,
	}
end

-- A slime falls: it pays by its level and rarity, and its 15 minutes start.
function Zombies.fall(farm: Farm, slimeId: string, now: number): number
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or (slime.ghostUntil and slime.ghostUntil > now) then
		return 0
	end
	slime.ghostUntil = now + Config.Village.GhostSeconds
	slime.sleeping = nil
	local reward = Zombies.deathReward(slime)
	Zombies.pay(farm, reward)
	return reward
end

function Zombies.reviveCost(level: number): number
	return math.ceil(1 + math.max(0, level) / Config.Zombies.ReviveLevelsPerFood)
end

-- Pays with the raw food there is most of, all or nothing, and brings the slime back.
function Zombies.revive(farm: Farm, slimeId: string, now: number): (boolean, string?)
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or not slime.ghostUntil or slime.ghostUntil <= now then
		return false, "NOT_DEAD"
	end
	local cost = Zombies.reviveCost(Stats.level(slime.stats))
	local have = 0
	for _, id in Config.Food.RawOrder do
		have += farm.storehouse[id] or 0
	end
	if have < cost then
		return false, "NO_FOOD"
	end
	for _ = 1, cost do
		local best, most = nil, 0
		for _, id in Config.Food.RawOrder do
			local count = farm.storehouse[id] or 0
			if count > most then
				best, most = id, count
			end
		end
		Food.take(farm.storehouse, best :: string, 1)
	end
	slime.ghostUntil = nil
	slime.needs.fullness = Config.Needs.Start
	slime.needs.energy = Config.Needs.Start
	return true, nil
end

return Zombies
