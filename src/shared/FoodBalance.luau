--!strict
-- Estimate the raw nutritional supply of starter-speed producers, with a conservative
-- fraction of time available after walking, transport, sleep and full collection bins.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")

local FoodBalance = {}

function FoodBalance.weightedFullness(group: string): number
	local kinds = Config.Food.Kinds :: any
	local ids = if group == "fish" then Config.Food.FishOrder else Config.Food.VegOrder
	local nutrition, weights = 0, 0
	for _, id in ids do
		nutrition += kinds[id].weight * kinds[id].fullness
		weights += kinds[id].weight
	end
	return if weights > 0 then nutrition / weights else 0
end

function FoodBalance.rawSupplyPerMinute(fishingLevel: number, gardenLevel: number): number
	local fishRate = FarmState.slotCount(fishingLevel) * Config.Work.FishingYield * Config.Village.StepSeconds
		/ Stations.cycleSeconds("fishing", fishingLevel)
	local actionSeconds = Config.Work.GardenActionSeconds
		* Config.Work.CycleLevelFactor ^ (gardenLevel - Config.Village.StartLevel)
	local vegRate = FarmState.slotCount(gardenLevel) * Config.Village.StepSeconds
		/ (actionSeconds * Config.Work.GardenActionsPerHarvest)
	return (fishRate * FoodBalance.weightedFullness("fish")
		+ vegRate * FoodBalance.weightedFullness("veg")) * Config.FoodBalance.ProductiveTimeFraction
end

function FoodBalance.demandPerMinute(population: number, workers: number): number
	return population * Config.Needs.IdleFullnessPerMinute
		+ workers * (Config.Needs.WorkFullnessPerMinute - Config.Needs.IdleFullnessPerMinute)
end

return FoodBalance
