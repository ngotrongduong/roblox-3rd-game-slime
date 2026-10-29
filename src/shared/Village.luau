--!strict
-- Village upgrade costs and derived population capacity, with no currency changes on failure.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")

type Farm = typeof(FarmState.newFarm(0))
local Village = {}
Village.Areas = Config.Village.Areas

function Village.level(farm: Farm): number
	return FarmState.villageLevel(farm.areas)
end

function Village.populationLimit(farm: Farm): number
	return FarmState.populationLimit(farm.areas)
end

function Village.upgradeCost(level: number): number
	local v = Config.Village
	local cost = v.UpgradeBase * (v.UpgradeMaxCost / v.UpgradeBase) ^ ((level - v.StartLevel) / (v.UpgradeLastFromLevel - v.StartLevel))
	return math.floor(cost / v.CostRoundTo + 0.5) * v.CostRoundTo
end

function Village.upgrade(farm: Farm, areaId: string): (boolean, string?)
	local area = (farm.areas :: any)[areaId]
	if not table.find(Village.Areas, areaId) or not area then return false, "NO_AREA" end
	if area.level >= Config.Village.MaxLevel then return false, "MAX_LEVEL" end
	local price = Village.upgradeCost(area.level)
	if farm.coins < price then return false, "NO_COINS" end
	farm.coins -= price
	area.level += 1
	-- Retain all assigned slots and progress; only grow the arrays.
	local work = (farm.work :: any)[areaId]
	if work then
		while #work.slots < FarmState.slotCount(area.level) do
			table.insert(work.slots, { progress = 0 })
		end
	end
	if areaId == "breeding" then
		while #farm.breeding.pairs < FarmState.breedingCount(area.level) do
			table.insert(farm.breeding.pairs, {})
		end
	end
	return true, nil
end

return Village
