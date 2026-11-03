--!strict
-- The rules of every request a player can send through the Village remote, without services so a test can hold them:
-- valid checks the shape of what arrived, run decides and changes the farm. What only the server can know (where the
-- character stands, who is out marching) comes in through env. Rate limit, saving and effects: server/VillageRemotes.
local Breeding = if script then require(script.Parent.Breeding) else require("./Breeding")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Shop = if script then require(script.Parent.Shop) else require("./Shop")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Village = if script then require(script.Parent.Village) else require("./Village")
local Zombies = if script then require(script.Parent.Zombies) else require("./Zombies")

export type Env = {
	isOut: (slimeId: string) -> boolean,
	atMarket: () -> boolean,
	nearGate: () -> boolean,
	teamOut: (team: number) -> boolean,
	attack: (farm: any, team: number, groupId: string, now: number) -> (boolean, string?),
	clearWounds: (slimeId: string) -> (),
	freeUpgrades: boolean,
}

local VillageRequests = {}

local function integer(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge and n % 1 == 0
end

-- A team number: a whole number from 1 to the number of teams.
local function teamNumber(n: any): boolean
	return integer(n) and n >= 1 and n <= Config.Zombies.Teams
end

-- A plain list of text ids no longer than a team.
local function idList(value: any): boolean
	if type(value) ~= "table" or #value > Config.Zombies.TeamSize then
		return false
	end
	local count = 0
	for key, id in value do
		if type(key) ~= "number" or type(id) ~= "string" then
			return false
		end
		count += 1
	end
	return count == #value
end

-- hasPlot: the player holds a plot (upgrades and teams need one).
function VillageRequests.valid(data: any, hasPlot: boolean): boolean
	local action = data.action
	if action == "SetPair" then
		return integer(data.index)
			and (data.a == nil or type(data.a) == "string")
			and (data.b == nil or type(data.b) == "string")
	elseif action == "Assign" then
		return type(data.area) == "string"
			and integer(data.slot)
			and type(data.slimeId) == "string"
			and type(data.asReserve) == "boolean"
	elseif action == "Unassign" or action == "Revive" or action == "Sell" then
		return type(data.slimeId) == "string"
	elseif action == "SetTrainingStat" then
		return integer(data.slot) and type(data.stat) == "string"
	elseif action == "SetCookRecipe" then
		return integer(data.slot) and type(data.recipe) == "string"
	elseif action == "FeedDish" or action == "SetAutoDish" then
		return type(data.slimeId) == "string"
			and (action == "SetAutoDish" and data.dish == nil or type(data.dish) == "string")
	elseif action == "SellDish" then
		return type(data.dish) == "string"
			and integer(data.count)
			and data.count >= 1
			and data.count <= Food.fridgeCapacity(Config.Village.MaxLevel)
	elseif action == "UpgradeArea" then
		return type(data.areaId) == "string" and table.find(Config.Village.Areas, data.areaId) ~= nil and hasPlot
	elseif action == "SetTeam" then
		return teamNumber(data.team) and idList(data.slimeIds) and hasPlot
	elseif action == "SetTeamRepeat" then
		return teamNumber(data.team) and type(data.on) == "boolean" and hasPlot
	elseif action == "AttackGroup" then
		return teamNumber(data.team)
			and type(data.groupId) == "string"
			and #data.groupId <= Config.Zombies.TargetIdMaxLength
			and hasPlot
	end
	return false
end

local function unassign(farm: any, slimeId: string): (boolean, string?)
	if not FarmState.findSlime(farm, slimeId) then
		return false, "MISSING_SLIME"
	end
	for _, area in Config.Work.Areas do
		for index, slot in farm.work[area].slots do
			if slot.worker == slimeId and Stations.unassign(farm, area, index, false) then
				return true, nil
			elseif slot.reserve == slimeId and Stations.unassign(farm, area, index, true) then
				return true, nil
			end
		end
	end
	return false, "NOT_ASSIGNED"
end

-- Runs a valid request on the farm: whether it went, why not, and the coins paid (a sale). A refusal changes nothing.
function VillageRequests.run(farm: any, data: any, now: number, env: Env): (boolean, string?, number?)
	local action = data.action
	if action == "SetPair" then
		if (data.a and env.isOut(data.a)) or (data.b and env.isOut(data.b)) then
			return false, "OUT"
		end
		return Breeding.setPair(farm, data.index, data.a, data.b, now)
	elseif action == "Assign" then
		if env.isOut(data.slimeId) then
			return false, "OUT"
		end
		return Stations.assign(farm, data.slimeId, data.area, data.slot, data.asReserve, now)
	elseif action == "Unassign" then
		return unassign(farm, data.slimeId)
	elseif action == "SetTrainingStat" then
		if Stations.setTrainingStat(farm, data.slot, data.stat) then
			return true, nil
		end
		return false, "INVALID_STAT_OR_SLOT"
	elseif action == "SetCookRecipe" then
		if Stations.setCookRecipe(farm, data.slot, data.recipe) then
			return true, nil
		end
		return false, "INVALID_RECIPE_OR_SLOT"
	elseif action == "FeedDish" then
		if env.isOut(data.slimeId) then
			return false, "OUT"
		end
		return Food.feed(farm, data.slimeId, data.dish, now)
	elseif action == "SetAutoDish" then
		return Food.setAutoDish(farm, data.slimeId, data.dish)
	elseif action == "SellDish" then
		if not env.atMarket() then
			return false, "TOO_FAR"
		elseif data.count > Food.fridgeCapacity(farm.areas.kitchen.level) then
			return false, "INVALID_ARGUMENT"
		end
		local value, why = Shop.sellDish(farm, data.dish, data.count)
		return value ~= nil, why, value
	elseif action == "UpgradeArea" then
		return Village.upgrade(farm, data.areaId, env.freeUpgrades)
	elseif action == "SetTeam" then
		-- the line-ups are set at the village gate, never while that team is out
		if not env.nearGate() then
			return false, "TOO_FAR"
		elseif env.teamOut(data.team) then
			return false, "TEAM_OUT"
		end
		return Zombies.setTeam(farm, data.team, data.slimeIds, now, env.isOut)
	elseif action == "SetTeamRepeat" then
		local team = farm.teams[data.team]
		if data.on and not Zombies.teamOpen(farm, data.team) then
			return false, "LOCKED"
		elseif data.on and #team.members == 0 then
			return false, "NO_MEMBERS"
		end
		team.repeatOn = data.on
		return true, nil
	elseif action == "AttackGroup" then
		return env.attack(farm, data.team, data.groupId, now)
	elseif action == "Revive" then
		if env.isOut(data.slimeId) then
			return false, "OUT"
		end
		local ok, why = Zombies.revive(farm, data.slimeId, now)
		if ok then
			env.clearWounds(data.slimeId)
		end
		return ok, why
	elseif action == "Sell" then
		if not env.atMarket() then
			return false, "TOO_FAR"
		elseif env.isOut(data.slimeId) then
			return false, "OUT"
		end
		local value, why = Shop.sell(farm, data.slimeId, now)
		return value ~= nil, why, value
	end
	return false, "BAD_REQUEST"
end

return VillageRequests
