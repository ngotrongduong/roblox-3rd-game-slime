--!strict
-- Raw food, recipes and bounded transfers; work boxes and counters are not allowed to invent stock.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")

type Farm = typeof(FarmState.newFarm(0))
local Food = {}

function Food.storehouseCapacity(level: number): number
	return Config.Food.StorehouseBase + Config.Food.StorehousePerLevel * (level - Config.Village.StartLevel)
end

function Food.fridgeCapacity(level: number): number
	return Config.Food.FridgeBase + Config.Food.FridgePerLevel * (level - Config.Village.StartLevel)
end

function Food.total(stock: { [string]: number }): number
	local total = 0
	for _, value in stock do
		total += math.max(0, value)
	end
	return total
end

function Food.add(stock: { [string]: number }, item: string, amount: number, capacity: number): number
	if Config.Food.Raw[item] == nil and Config.Food.Dishes[item] == nil then return 0 end
	local moved = math.min(math.max(0, math.floor(amount)), math.max(0, capacity - Food.total(stock)))
	if moved > 0 then stock[item] = (stock[item] or 0) + moved end
	return moved
end

function Food.take(stock: { [string]: number }, item: string, amount: number): number
	if Config.Food.Raw[item] == nil and Config.Food.Dishes[item] == nil then return 0 end
	local moved = math.min(math.max(0, math.floor(amount)), math.max(0, stock[item] or 0))
	if moved > 0 then
		local remaining = (stock[item] or 0) - moved
		if remaining == 0 then stock[item] = nil else stock[item] = remaining end
	end
	return moved
end

function Food.bestDish(stock: { [string]: number }): string?
	for _, id in Config.Food.DishOrder do
		local dish = Config.Food.Dishes[id]
		local ready = true
		for item, count in dish.ingredients do
			if (stock[item] or 0) < count then ready = false; break end
		end
		if ready then return id end
	end
	return nil
end

-- A kitchen orders only a dish it could complete using the counter and current pantry.
function Food.ingredientsWanted(farm: Farm): { [string]: number }
	for _, id in Config.Food.DishOrder do
		local recipe = Config.Food.Dishes[id]
		local possible = true
		for item, count in recipe.ingredients do
			if (farm.counter[item] or 0) + (farm.storehouse[item] or 0) < count then
				possible = false
				break
			end
		end
		if possible then
			local needed: { [string]: number } = {}
			for item, count in recipe.ingredients do
				local missing = math.max(0, count - (farm.counter[item] or 0))
				if missing > 0 then needed[item] = missing end
			end
			return needed
		end
	end
	return {}
end

-- Returns item and inventory name; ties follow the Config order for repeatable offline runs.
function Food.chooseMeal(farm: Farm, slimeId: string): (string?, string?)
	if table.find(farm.cookedAllowed, slimeId) then
		for _, id in Config.Food.DishOrder do
			if (farm.fridge[id] or 0) > 0 then return id, "fridge" end
		end
	end
	local best: string? = nil
	local highest = 0
	for _, id in Config.Food.RawOrder do
		local count = farm.storehouse[id] or 0
		if count > highest then best, highest = id, count end
	end
	if best then return best, "storehouse" end
	return nil, nil
end

-- Mutates the supplied farm; callers that promise purity must copy it first.
function Food.eat(farm: Farm, slimeId: string, now: number): string?
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or (slime.ghostUntil and slime.ghostUntil > now) then return nil end
	local item, location = Food.chooseMeal(farm, slimeId)
	if not item then return nil end
	local stock = if location == "fridge" then farm.fridge else farm.storehouse
	if Food.take(stock, item, 1) == 0 then return nil end
	local dish = Config.Food.Dishes[item]
	slime.needs = Needs.eatValue(slime.needs, if dish then dish.fullness else Config.Food.Raw[item])
	if dish then
		slime.buff = { stat = dish.stat, percent = dish.percent, untilTime = now + Config.Food.BuffSeconds }
	end
	return item
end

return Food
