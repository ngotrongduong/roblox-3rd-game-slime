--!strict
-- The zombie slimes outside the village (the owner, 2026-11-02): groups a little around the player's own level, rarer
-- kinds worth more, and coins for every slime killed on either side, by its level and rarity.
local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")
local Classes = if script then require(script.Parent.Classes) else require("./Classes")
local Combat = if script then require(script.Parent.Combat) else require("./Combat")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Gaits = if script then require(script.Parent.Gaits) else require("./Gaits")
local Gear = if script then require(script.Parent.Gear) else require("./Gear")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local VillagePath = if script then require(script.Parent.VillagePath) else require("./VillagePath")
local VillageRules = if script then require(script.Parent.Village) else require("./Village")

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
	local count = math.min(#levels, Config.Zombies.LevelTeams * Config.Zombies.TeamSize)
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

-- A group's id is unique across the server and short (a saved team target names one): "s<slice>c<camp>g<index>", the slice
-- 0 for the Market's and 1..8 for the plots'.
function Zombies.groupId(slice: number, camp: number, index: number): string
	return "s" .. slice .. "c" .. camp .. "g" .. index
end

-- The slice, camp and index an id names, all nil when it is not a group of this server (an id of the old single-village
-- camps, "c1g1", or any other text).
function Zombies.parseGroupId(id: any): (number?, number?, number?)
	if type(id) ~= "string" then
		return nil, nil, nil
	end
	local slice, camp, index = string.match(id, "^s(%d+)c(%d+)g(%d+)$")
	if not slice then
		return nil, nil, nil
	end
	local s, c, i = tonumber(slice) :: number, tonumber(camp) :: number, tonumber(index) :: number
	if
		s > Config.Map.PlotCount
		or c < 1
		or c > #Config.Zombies.LevelOffsets
		or i < 1
		or i > #Config.Zombies.Homes[c]
	then
		return nil, nil, nil
	end
	return s, c, i
end

-- Whether a team's saved target still fits a player in this plot: it names a group of that plot's own slice. A target of an
-- old plot, of the old camps or of nothing known is dropped when the player's camps open.
function Zombies.targetFits(target: any, plot: number): boolean
	local slice = Zombies.parseGroupId(target)
	return slice == plot
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

-- Coins won in a fight, up to what the vault holds. `now` (server seconds) lets VIP and a Gold Potion multiply the win before
-- the vault is looked at; left out (tools without a clock), the win is paid unboosted.
function Zombies.pay(farm: Farm, amount: number, now: number?): number
	local room = math.max(0, VillageRules.coinCap(farm.areas.pantry.level) - farm.coins)
	local won = math.max(0, amount)
	if now then
		won = Boosts.earn(farm, won, now)
	end
	local paid = math.min(won, room)
	farm.coins += paid
	farm.lifetime.coinsEarned += paid
	return paid
end

-- Whether a team member can march right now: grown up, alive, awake and not tired. (A slime in a team is never at a job
-- or in a pair, FarmState.teamOf; a team member is not refused for being in its team.)
function Zombies.canSend(farm: Farm, slime: Slime, now: number): boolean
	if not canFight(farm, slime, now) or slime.sleeping or Needs.isTired(slime.needs) then
		return false
	end
	return not Stations.isBusy(farm, slime.id) and not FarmState.inPair(farm, slime.id)
end

-- How many teams a village of this level can set and send (Config.Zombies.TeamOpensAt), plus the `extra` the Extra Team passes
-- add (Boosts.extraTeams), never above Config.Zombies.Teams: teams 1..this.
function Zombies.teamsOpen(villageLevel: number, extra: number?): number
	local open = 1
	for index, level in Config.Zombies.TeamOpensAt do
		if villageLevel >= level then
			open = math.max(open, index)
		end
	end
	return math.min(open + (extra or 0), Config.Zombies.Teams)
end

-- Whether team `teamIndex` of this farm is open yet.
function Zombies.teamOpen(farm: Farm, teamIndex: number): boolean
	return teamIndex <= Zombies.teamsOpen(FarmState.villageLevel(farm.areas), Boosts.extraTeams(farm))
end

-- Sets the line-up of team `teamIndex` to these slimes (none empties it). A slime already in another team moves here.
-- `isOut` says which slimes are away on a march. Returns whether it was set, else why not; nothing changes on a refusal:
-- BAD_TEAM, LOCKED (the village is not big enough for it yet; it can still be emptied), BAD_SIZE, DUPLICATE, NO_SLIME,
-- BABY, DEAD, BUSY (at a job or in a pair), OUT.
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
	elseif #ids > 0 and not Zombies.teamOpen(farm, teamIndex) then
		return false, "LOCKED"
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
		elseif Stations.isBusy(farm, id) or FarmState.inPair(farm, id) then
			return false, "BUSY"
		end
	end
	for _, other in farm.teams do
		if other ~= team then
			for _, id in ids do
				local at = table.find(other.members, id)
				if at then
					table.remove(other.members, at)
					if other.formation then
						other.formation[id] = nil
						if next(other.formation) == nil then
							other.formation = nil
						end
					end
				end
			end
		end
	end
	local kept: { [string]: string } = {}
	for _, id in ids do
		local row = if team.formation then team.formation[id] else nil
		if row then
			kept[id] = row
		end
	end
	team.members = table.clone(ids)
	team.formation = if next(kept) then kept else nil
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

-- Where a group lives, as (across, forward) studs from its slice's gate towards the valley centre: Config.Zombies.Homes,
-- mirrored on odd slices and shifted a little by slice, always the same for the same group.
function Zombies.homeOffset(slice: number, camp: number, index: number): (number, number)
	local z = Config.Zombies
	local home = z.Homes[camp][index]
	local wobble = math.sin(slice * 12.9898 + camp * 78.233 + index * 37.719) * z.HomeJitterDegrees
	local angle = math.rad((home[1] + wobble) * (if slice % 2 == 1 then -1 else 1))
	local gateRadius = Config.Map.RimRadius - Config.Map.PlotSize / 2
	local radius = gateRadius - z.CampFirstDistance - (camp - 1) * z.CampSpacing + home[2]
	return radius * math.sin(angle), gateRadius - radius * math.cos(angle)
end

-- The weapon sets the default row; a slime without a valid weapon is always in front.
function Zombies.defaultRow(slime: Slime?): string
	local class = if slime then Classes.ofSlime(slime) else nil
	return if class then (Config.Classes.Rows.Default :: any)[class] or Config.Classes.Rows.Brawler
		else Config.Classes.Rows.Brawler
end

-- A saved override belongs to this team only; otherwise the weapon sets the row.
function Zombies.rowOf(farm: Farm, slimeId: string): string
	local teamIndex = FarmState.teamOf(farm, slimeId)
	local team = if teamIndex then farm.teams[teamIndex] else nil
	local chosen = if team and team.formation then team.formation[slimeId] else nil
	if chosen and table.find(Config.Classes.Rows.Order, chosen) then
		return chosen
	end
	return Zombies.defaultRow(FarmState.findSlime(farm, slimeId))
end

-- A missing tactic deliberately has the same combat behavior as the original rules.
function Zombies.tacticOf(team: { tactic: string? }?): string
	local selected = if team then team.tactic else nil
	return if selected and table.find(Config.Classes.Tactics.Order, selected) then selected else "balanced"
end

-- Fight positions: centre each row independently and keep the team's original order within it.
function Zombies.rowSpots(rows: { string }): { { across: number, back: number } }
	local result: { { across: number, back: number } } = {}
	local counts: { [string]: number } = {}
	local seen: { [string]: number } = {}
	local K = Config.Classes.Rows
	for _, row in rows do
		local name = if table.find(K.Order, row) then row else K.Brawler
		counts[name] = (counts[name] or 0) + 1
	end
	for index, row in rows do
		local name = if table.find(K.Order, row) then row else K.Brawler
		seen[name] = (seen[name] or 0) + 1
		local across = (seen[name] - ((counts[name] or 0) + 1) / 2) * Config.Zombies.View.FormationSpacing
		local depth = (table.find(K.Order, name) or 1) - 1
		result[index] = { across = across, back = depth * K.Depth }
	end
	return result
end

-- Where a camp fight's fighters stand as it begins, flat from the group's position; the server places the fight by these
-- and the client its bodies, so both agree. A team member: at the far end of its march (`endX, endZ`, come the way
-- `dirX, dirZ`), side by side across that way, every other one a step behind.
function Zombies.formation(
	endX: number,
	endZ: number,
	dirX: number,
	dirZ: number,
	slot: number,
	count: number
): (number, number)
	local V = Config.Zombies.View
	local across = (slot - (count + 1) / 2) * V.FormationSpacing
	local back = (slot % 2) * V.FormationStagger
	return endX - dirZ * across - dirX * back, endZ + dirX * across - dirZ * back
end

-- One of the group's zombies (`index` of `count`, in id order): on a ring round the group's position.
function Zombies.ringSpot(index: number, count: number): (number, number)
	if count <= 1 then
		return 0, 0
	end
	local angle = (index - 1) / count * math.pi * 2 + math.pi / 4
	local spread = Config.Zombies.View.SpreadStuds
	return math.cos(angle) * spread, math.sin(angle) * spread
end

-- A slime as it fights: hungry at half strength (docs/MAP.md), its dish buff on top, and the health it has left
-- (`hpShare`, 0 to 1 of its full health; a wound is kept after a fight).
function Zombies.fighter(
	slime: Slime,
	now: number,
	hpShare: number
): {
	id: string,
	attack: number,
	defence: number,
	speed: number,
	hp: number,
	maxHp: number,
	role: string?,
	class: string?,
	tier: number?,
	skills: { string }?,
}
	local factor = if Needs.isHungry(slime.needs) then Config.Needs.HungryWorkFactor else 1
	local stats =
		{ attack = slime.stats.attack, defence = slime.stats.defence, speed = slime.stats.speed, hp = slime.stats.hp }
	local buff = slime.buff
	if buff and buff.untilTime > now and (stats :: any)[buff.stat] then
		(stats :: any)[buff.stat] *= 1 + buff.percent / 100
	end
	-- the gear it wears adds flat points on top (the slime's own stats, level and price do not change)
	local bonus = Gear.bonus(slime)
	for key, points in bonus do
		(stats :: any)[key] += points
	end
	local class, tier = Classes.ofSlime(slime)
	local fighter: any = {
		id = slime.id,
		attack = stats.attack * factor,
		defence = stats.defence,
		speed = stats.speed,
		hp = stats.hp * math.clamp(hpShare, 0, 1),
		maxHp = stats.hp,
		class = class,
		tier = tier,
		skills = if class then {} else nil,
	}
	fighter.role = class or Combat.role(fighter, slime.seed)
	return fighter
end

-- A slime becomes a ghost: its 15 minutes start (the village's one rule for a fallen slime). False when it is gone or is
-- one already.
function Zombies.ghost(farm: Farm, slimeId: string, now: number): boolean
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or (slime.ghostUntil and slime.ghostUntil > now) then
		return false
	end
	slime.ghostUntil = now + Config.Village.GhostSeconds
	slime.sleeping = nil
	return true
end

-- A slime falls: it pays by its level and rarity, and its 15 minutes start.
function Zombies.fall(farm: Farm, slimeId: string, now: number): number
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or not Zombies.ghost(farm, slimeId, now) then
		return 0
	end
	local reward = Zombies.deathReward(slime)
	return Zombies.pay(farm, reward, now)
end

function Zombies.reviveCost(level: number): number
	return math.ceil(1 + math.max(0, level) / Config.Zombies.ReviveLevelsPerFood)
end

-- Pays with the lowest-rarity raw food first, all or nothing, and brings the slime back.
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
		local best = Food.cheapestRaw(farm.storehouse)
		Food.take(farm.storehouse, best :: string, 1)
	end
	slime.ghostUntil = nil
	slime.needs.fullness = Config.Needs.Start
	slime.needs.energy = Config.Needs.Start
	return true, nil
end

return Zombies
