--!strict
-- The zombie slimes outside the village (the owner, 2026-11-02): groups a little around the player's own level, rarer
-- kinds worth more, and coins for every slime killed on either side, by its level and rarity.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Gaits = if script then require(script.Parent.Gaits) else require("./Gaits")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local VillagePath = if script then require(script.Parent.VillagePath) else require("./VillagePath")

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

local function isBaby(farm: Farm, slime: Slime, now: number): boolean
	return Growth.isBaby(
		slime.createdAt,
		now,
		Stats.level(slime.stats),
		farm.areas.breeding.level - Config.Village.StartLevel
	)
end

local function isDead(slime: Slime, now: number): boolean
	return slime.ghostUntil ~= nil and slime.ghostUntil > now
end

local function inPair(farm: Farm, slimeId: string): boolean
	for _, pair in farm.breeding.pairs do
		if pair.a == slimeId or pair.b == slimeId then
			return true
		end
	end
	return false
end

local function canFight(farm: Farm, slime: Slime, now: number): boolean
	return not isDead(slime, now) and not isBaby(farm, slime, now)
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

-- The base level of a slice of the valley (docs/MAP.md 1.4): its owner's level. A slice with no owner rolls between the
-- average and the highest level of the players in the server; `owners` maps a plot to its owner's level.
function Zombies.sliceLevel(plot: number, owners: { [number]: number }, rng: Rng): number
	local own = owners[plot]
	if own then
		return own
	end
	local low, high = Zombies.serverRange(owners)
	return low + math.floor(rng:next() * (high - low + 1))
end

-- The average (rounded down) and the highest level of the players in the server; the starter level when nobody is in.
function Zombies.serverRange(owners: { [number]: number }): (number, number)
	local sum, count, high = 0, 0, 0
	for _, level in owners do
		sum += level
		count += 1
		high = math.max(high, level)
	end
	if count == 0 then
		local starter = Stats.level(Stats.starter())
		return starter, starter
	end
	return math.floor(sum / count), high
end

-- Whether a group waiting since `quietSince` should take its slice's level now. A fight is never touched (the caller
-- only asks of waiting groups), a new spawn always reads the level of its moment, and a group nobody attacked for
-- IdleResetSeconds goes back to what its slice should hold: a low player who moved in behind a strong one that left
-- gets zombies to fit. A group in an ownerless slice that is still inside the server's range stays as it rolled.
function Zombies.shouldRelevel(
	base: number,
	plot: number,
	owners: { [number]: number },
	quietSince: number,
	now: number
): boolean
	if now - quietSince < Config.Zombies.IdleResetSeconds then
		return false
	end
	local own = owners[plot]
	if own then
		return base ~= own
	end
	local low, high = Zombies.serverRange(owners)
	return base < low or base > high
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

-- Whether a team member can march right now: grown up, alive, awake and not tired. (A slime in a team is never at a job
-- or in a pair, FarmState.teamOf; a team member is not refused for being in its team.)
function Zombies.canSend(farm: Farm, slime: Slime, now: number): boolean
	if not canFight(farm, slime, now) or slime.sleeping or Needs.isTired(slime.needs) then
		return false
	end
	return not Stations.isBusy(farm, slime.id) and not inPair(farm, slime.id)
end

-- Sets the line-up of team `teamIndex` to these slimes (none empties it). A slime already in another team moves here.
-- `isOut` says which slimes are away on a march. Returns whether it was set, else why not; nothing changes on a refusal:
-- BAD_TEAM, BAD_SIZE, DUPLICATE, NO_SLIME, BABY, DEAD, BUSY (at a job or in a pair), OUT.
function Zombies.setTeam(
	farm: Farm,
	teamIndex: number,
	ids: { string },
	now: number,
	isOut: ((string) -> boolean)?
): (boolean, string?)
	local team = if teamIndex % 1 == 0 then farm.teams[teamIndex] else nil
	if not team then
		return false, "BAD_TEAM"
	elseif #ids > Config.Zombies.TeamSize then
		return false, "BAD_SIZE"
	end
	local seen: { [string]: boolean } = {}
	for _, id in ids do
		if seen[id] then
			return false, "DUPLICATE"
		end
		seen[id] = true
		local slime = FarmState.findSlime(farm, id)
		if not slime then
			return false, "NO_SLIME"
		elseif isOut and isOut(id) then
			return false, "OUT"
		elseif isBaby(farm, slime, now) then
			return false, "BABY"
		elseif isDead(slime, now) then
			return false, "DEAD"
		elseif Stations.isBusy(farm, id) or inPair(farm, id) then
			return false, "BUSY"
		end
	end
	for _, other in farm.teams do
		for _, id in ids do
			local at = table.find(other.members, id)
			if at then
				table.remove(other.members, at)
			end
		end
	end
	team.members = table.clone(ids)
	return true, nil
end

-- Whether a slime is fit to go again by itself (the repeat option): full health (`hurt` is the share of its health it
-- has lost), fed above the line where it asks for food, awake and not tired. Else why not, as the word the screen shows:
-- "dead" (the caller skips the dead), "health", "hungry" or "tired".
function Zombies.readyAgain(slime: Slime, now: number, hurt: number): (boolean, string?)
	if isDead(slime, now) then
		return false, "dead"
	elseif hurt > 0 then
		return false, "health"
	elseif Needs.wantsFood(slime.needs) then
		return false, "hungry"
	elseif slime.sleeping or Needs.isTired(slime.needs) then
		return false, "tired"
	end
	return true, nil
end

-- A wound after `seconds` at home.
function Zombies.heal(hurt: number, seconds: number): number
	return math.max(0, hurt - Config.Zombies.HealPerMinute * seconds / Config.Village.StepSeconds)
end

-- Seconds a team takes to walk `distance` studs when its members have these speed stats: the slowest sets the pace, in
-- the village's own walk (VillagePath), so it matches what the village would do over the same ground.
function Zombies.marchSeconds(distance: number, speeds: { number }): number
	local slowest = math.huge
	for _, speed in speeds do
		slowest = math.min(slowest, Gaits.factor(speed))
	end
	if slowest == math.huge then
		return 0
	end
	return VillagePath.duration(distance, slowest, Config.Zombies.MarchGait)
end

-- Where a group stands, as (across, forward) studs from the plot's gate towards the valley centre: camp 1..#LevelOffsets
-- further out each, the groups of a camp spread across the way and centred on it.
function Zombies.campOffset(camp: number, index: number): (number, number)
	local z = Config.Zombies
	local forward = z.CampFirstDistance + (camp - 1) * z.CampSpacing
	-- Groups spread by angle, so a camp stays inside its plot's slice of the valley as the slice narrows to the middle.
	local radius = Config.Map.RimRadius - Config.Map.PlotSize / 2 - forward
	return (index - (z.GroupsPerCamp + 1) / 2) * radius * math.rad(z.GroupSpreadDegrees), forward
end

-- A slime as it fights: hungry at half strength (docs/MAP.md), its dish buff on top, and the health it has left
-- (`hpShare`, 0 to 1 of its full health; a wound is kept after a fight).
function Zombies.fighter(
	slime: Slime,
	now: number,
	hpShare: number
): { id: string, attack: number, defence: number, speed: number, hp: number, maxHp: number }
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
		hp = stats.hp * math.clamp(hpShare, 0, 1),
		maxHp = stats.hp,
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
