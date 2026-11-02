--!strict
-- Selling a slime at the Market (docs/reference/01-core-farm.md §8.1): by its level and rarity. A slime at a job or a
-- nest, a favourite, a dead one or one of the last two is refused, and nothing changes on a refusal.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Farm = typeof(FarmState.newFarm(0))
local Shop = {}

function Shop.canSell(farm: Farm, slimeId: string, now: number): (boolean, string?)
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime then
		return false, "NO_SLIME"
	elseif slime.isFavourite then
		return false, "FAVOURITE"
	elseif slime.ghostUntil and slime.ghostUntil > now then
		return false, "DEAD"
	elseif Stations.isBusy(farm, slimeId) then
		return false, "AT_WORK"
	elseif #farm.slimes <= Config.Zombies.MinSlimes then
		return false, "LAST_SLIMES"
	end
	for _, pair in farm.breeding.pairs do
		if pair.a == slimeId or pair.b == slimeId then
			return false, "IN_PAIR"
		end
	end
	return true, nil
end

-- Returns the coins paid, or nil and why not.
function Shop.sell(farm: Farm, slimeId: string, now: number): (number?, string?)
	local ok, why = Shop.canSell(farm, slimeId, now)
	if not ok then
		return nil, why
	end
	local slime = FarmState.findSlime(farm, slimeId) :: any
	local value = Mutations.sellValue(slime.appearanceMutation, Stats.level(slime.stats))
	FarmState.removeSlime(farm, slimeId)
	farm.coins += value
	farm.lifetime.coinsEarned += value
	return value, nil
end

-- Dish sales are not limited by the combat coin vault.
function Shop.sellDish(farm: Farm, dishId: string, count: number): (number?, string?)
	local dish = (Config.Food.Dishes :: any)[dishId]
	if not dish then return nil, "UNKNOWN_DISH" end
	if type(count) ~= "number" or count ~= count or count % 1 ~= 0 or count < 1 then
		return nil, "INVALID_COUNT"
	end
	local held = farm.fridge[dishId] or 0
	if held <= 0 then return nil, "NO_DISH" end
	local sold = math.min(count, held)
	local price = (Config.Food.DishRarities :: any)[dish.rarity].price
	local value = price * sold
	Food.take(farm.fridge, dishId, sold)
	farm.coins += value
	farm.lifetime.coinsEarned += value
	return value, nil
end

return Shop
