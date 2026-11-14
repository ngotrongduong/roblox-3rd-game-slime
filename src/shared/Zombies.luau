--!strict
-- The teams that fight the packs of the open world (the owner, 2026-11-02; the packs are WorldPacks): the squad's line-up,
-- its march, its wounds, and coins for every slime killed on its side.
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
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local VillagePath = if script then require(script.Parent.VillagePath) else require("./VillagePath")
local VillageRules = if script then require(script.Parent.Village) else require("./Village")

type Farm = typeof(FarmState.newFarm(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])
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

-- The weapon sets the default row; a slime without a valid weapon is always in front.
function Zombies.defaultRow(slime: Slime?): string
	local class = if slime then Classes.ofSlime(slime) else nil
	return if class
		then (Config.Classes.Rows.Default :: any)[class] or Config.Classes.Rows.Brawler
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
	local slime = FarmState.findSlime(farm, slimeId)
	return Zombies.defaultRow(slime)
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

-- Where a pack fight's fighters stand as it begins, flat from the group's position; the server places the fight by these
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
