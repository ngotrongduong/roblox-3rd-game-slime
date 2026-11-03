--!strict
-- Raw food, recipes and bounded transfers; work boxes and counters are not allowed to invent stock.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")

local RngModule = if script then require(script.Parent.Rng) else require("./Rng")

type Farm = typeof(FarmState.newFarm(0))
type Rng = typeof(RngModule.new(0))
local Food = {}

Food.storehouseCapacity = FarmState.storehouseCapacity
Food.fridgeCapacity = FarmState.fridgeCapacity

-- Which raw kind a catch or a planting is: one roll over the weights of the group ("fish" or "veg"), in Config order.
-- Luck does not affect rarity; pond or garden level alone changes the distribution.
function Food.roll(group: string, rng: Rng, level: number): string
	local order: { string } = if group == "fish" then Config.Food.FishOrder else Config.Food.VegOrder
	local kinds = Config.Food.Kinds :: any
	local fraction =
		math.clamp((level - Config.Village.StartLevel) / (Config.Village.MaxLevel - Config.Village.StartLevel), 0, 1)
	local total = 0
	for _, id in order do
		local kind = kinds[id]
		total += kind.weight + (kind.topWeight - kind.weight) * fraction
	end
	local at = rng:next() * total
	for _, id in order do
		local kind = kinds[id]
		at -= kind.weight + (kind.topWeight - kind.weight) * fraction
		if at < 0 then
			return id
		end
	end
	return order[#order]
end

function Food.total(stock: { [string]: number }): number
	local total = 0
	for _, value in stock do
		total += math.max(0, value)
	end
	return total
end

function Food.add(stock: { [string]: number }, item: string, amount: number, capacity: number): number
	if (Config.Food.Raw :: any)[item] == nil and (Config.Food.Dishes :: any)[item] == nil then
		return 0
	end
	local amountToAdd = if type(amount) == "number"
			and amount == amount
			and amount ~= math.huge
			and amount ~= -math.huge
		then math.max(0, math.floor(amount))
		else 0
	local moved = math.min(amountToAdd, math.max(0, capacity - Food.total(stock)))
	if moved > 0 then
		stock[item] = math.max(0, stock[item] or 0) + moved
	end
	return moved
end

function Food.take(stock: { [string]: number }, item: string, amount: number): number
	if (Config.Food.Raw :: any)[item] == nil and (Config.Food.Dishes :: any)[item] == nil then
		return 0
	end
	local existing = math.max(0, stock[item] or 0)
	if existing == 0 then
		stock[item] = nil
	end
	local requested = if amount == amount
			and amount ~= math.huge
			and amount ~= -math.huge
		then math.max(0, math.floor(amount))
		else 0
	local moved = math.min(requested, existing)
	if moved > 0 then
		local remaining = (stock[item] or 0) - moved
		if remaining == 0 then
			stock[item] = nil
		else
			stock[item] = remaining
		end
	end
	return moved
end

-- Unknown or still-locked selections safely cook the starter recipe.
function Food.recipeUnlocked(id: string, kitchenLevel: number): boolean
	local dish = (Config.Food.Dishes :: any)[id]
	return dish ~= nil and kitchenLevel >= (Config.Food.DishRarities :: any)[dish.rarity].kitchenLevel
end

function Food.slotRecipe(slot: { recipe: string? }, kitchenLevel: number): string
	local id = slot.recipe
	return if id and Food.recipeUnlocked(id, kitchenLevel) then id else Config.Food.DefaultRecipe
end

function Food.cookSeconds(id: string, kitchenLevel: number): number
	local dish = (Config.Food.Dishes :: any)[id]
	if not dish then
		return math.huge
	end
	local rarity = (Config.Food.DishRarities :: any)[dish.rarity]
	return rarity.cookSeconds * Config.Work.CycleLevelFactor ^ (kitchenLevel - Config.Village.StartLevel)
end

function Food.canCook(farm: Farm): boolean
	return Food.total(farm.fridge) + Food.total(farm.work.kitchen.box) < Food.fridgeCapacity(farm.areas.kitchen.level)
end

-- Every staffed recipe gets its own ingredients; none may be spent twice in one request.
-- The storehouse retains a raw-food reserve for the slimes even when cooks are busy.
function Food.ingredientsWanted(farm: Farm): { [string]: number }
	local reserve = #farm.slimes * Config.Food.CookReservePerSlime
	local storeTotal = Food.total(farm.storehouse)
	if storeTotal < reserve or not Food.canCook(farm) then
		return {}
	end
	local pantry = table.clone(farm.storehouse)
	local counter = table.clone(farm.counter)
	local spare = math.max(0, storeTotal - reserve)
	local space = math.max(0, Config.Food.CounterCapacity - Food.total(farm.counter))
	local wanted: { [string]: number } = {}
	for _, slot in farm.work.kitchen.slots do
		if not (slot.worker or slot.reserve) then
			continue
		end
		local dish = (Config.Food.Dishes :: any)[Food.slotRecipe(slot, farm.areas.kitchen.level)]
		local missing: { [string]: number } = {}
		local totalMissing = 0
		local possible = true
		for item, count in dish.ingredients do
			local need = math.max(0, count - (counter[item] or 0))
			if need > (pantry[item] or 0) then
				possible = false
				break
			end
			missing[item] = need
			totalMissing += need
		end
		if possible and totalMissing <= space and totalMissing <= spare then
			for item, count in dish.ingredients do
				counter[item] = math.max(0, (counter[item] or 0) - count)
				local amount = missing[item] or 0
				pantry[item] = (pantry[item] or 0) - amount
				if amount > 0 then
					wanted[item] = (wanted[item] or 0) + amount
				end
			end
			space -= totalMissing
			spare -= totalMissing
		end
	end
	return wanted
end

-- Lower rarity wins; within that, the most plentiful kind, then Config order.
function Food.cheapestRaw(stock: { [string]: number }): string?
	local best: string? = nil
	local rarityRank, biggest = math.huge, 0
	for _, id in Config.Food.RawOrder do
		local count = stock[id] or 0
		if count > 0 then
			local kind = (Config.Food.Kinds :: any)[id]
			local rank = (Config.Food.Rarities :: any)[kind.rarity].order
			if rank < rarityRank or (rank == rarityRank and count > biggest) then
				best, rarityRank, biggest = id, rank, count
			end
		end
	end
	return best
end

function Food.chooseMeal(farm: Farm, slimeId: string): (string?, string?)
	local slime = FarmState.findSlime(farm, slimeId)
	if slime and slime.autoDish and (farm.fridge[slime.autoDish] or 0) > 0 then
		return slime.autoDish, "fridge"
	end
	local raw = Food.cheapestRaw(farm.storehouse)
	return raw, if raw then "storehouse" else nil
end

-- One consumption path for automatic meals and manual feeding, including buff replacement.
local function consume(farm: Farm, slimeId: string, item: string, from: string, now: number): boolean
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or (slime.ghostUntil and slime.ghostUntil > now) then
		return false
	end
	local stock = if from == "fridge" then farm.fridge else farm.storehouse
	if (stock[item] or 0) <= 0 or Food.take(stock, item, 1) == 0 then
		return false
	end
	local dish = (Config.Food.Dishes :: any)[item]
	slime.needs = Needs.eatValue(slime.needs, if dish then dish.fullness else (Config.Food.Raw :: any)[item])
	if dish then
		local rarity = (Config.Food.DishRarities :: any)[dish.rarity]
		slime.buff = { stat = dish.stat, percent = rarity.percent, untilTime = now + rarity.buffSeconds, dish = item }
	end
	return true
end

function Food.eat(farm: Farm, slimeId: string, now: number): string?
	local item, from = Food.chooseMeal(farm, slimeId)
	if item and from and consume(farm, slimeId, item, from, now) then
		return item
	end
	return nil
end

function Food.feed(farm: Farm, slimeId: string, dishId: string, now: number): (boolean, string?)
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime then
		return false, "NO_SLIME"
	end
	if slime.ghostUntil and slime.ghostUntil > now then
		return false, "DEAD"
	end
	if (Config.Food.Dishes :: any)[dishId] == nil then
		return false, "UNKNOWN_DISH"
	end
	if (farm.fridge[dishId] or 0) <= 0 then
		return false, "NO_DISH"
	end
	return consume(farm, slimeId, dishId, "fridge", now), nil
end

function Food.setAutoDish(farm: Farm, slimeId: string, dishId: string?): (boolean, string?)
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime then
		return false, "NO_SLIME"
	end
	if dishId ~= nil and (Config.Food.Dishes :: any)[dishId] == nil then
		return false, "UNKNOWN_DISH"
	end
	slime.autoDish = dishId
	return true, nil
end

return Food
