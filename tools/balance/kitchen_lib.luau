--!nocheck
-- The kitchen on the real VillageSim (never an estimate): a full village at one level, every kitchen slot staffed, a
-- script that picks each cook's recipe, and either the fridge sold dish by dish or the slimes eating from it.
-- Used by kitchen_sim.luau and price_curve.luau.
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Food = require("../../src/shared/Food")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")
local FarmKit = require("../../tests/lib/FarmKit")
local Model = require("./income_model")

local Kitchen = {}

local originals: { fishing: number, garden: number, cook: { [string]: number } }? = nil

-- Walking and hauling are not in the offline step: slow the work down by the same share instead (as food_sim does).
-- The cooks walk too, so a dish takes 1 / productive as long.
function Kitchen.setProductive(productive: number)
	if not originals then
		local cook = {}
		for id, rarity in Config.Food.DishRarities do
			cook[id] = rarity.cookSeconds
		end
		originals = {
			fishing = Config.Work.CycleSeconds.fishing,
			garden = Config.Work.GardenActionSeconds,
			cook = cook,
		}
	end
	local o = originals :: any
	Config.Work.CycleSeconds.fishing = o.fishing / productive
	Config.Work.GardenActionSeconds = o.garden / productive
	for id, rarity in Config.Food.DishRarities do
		rarity.cookSeconds = o.cook[id] / productive
	end
end

local function total(stock: { [string]: number }): number
	local sum = 0
	for _, count in stock do
		sum += count
	end
	return sum
end

local function priceOf(id: string): number
	return Config.Food.DishRarities[Config.Food.Dishes[id].rarity].price
end

-- Each staffed cook gets the best-priced unlocked recipe the stock can complete, counted as the kitchen counts it (the
-- counter first, then the pantry beyond the reserve), each ingredient given to one cook only.
local function chooseRecipes(farm: any)
	local level = farm.areas.kitchen.level
	local reserve = #farm.slimes * Config.Food.CookReservePerSlime
	local pantry = table.clone(farm.storehouse)
	local counter = table.clone(farm.counter)
	local spare = math.max(0, total(farm.storehouse) - reserve)
	local space = math.max(0, Config.Food.CounterCapacity - total(farm.counter))
	for index, slot in farm.work.kitchen.slots do
		if not (slot.worker or slot.reserve) then
			continue
		end
		local function missing(id: string): number?
			local dish = Config.Food.Dishes[id]
			local sum = 0
			for item, count in dish.ingredients do
				local need = math.max(0, count - (counter[item] or 0))
				if need > (pantry[item] or 0) then
					return nil
				end
				sum += need
			end
			if sum > space or sum > spare then
				return nil
			end
			return sum
		end
		local current = Food.slotRecipe(slot, level)
		local best, bestPrice, bestStock = nil, -1, -1
		for _, id in Config.Food.DishOrder do
			if Food.recipeUnlocked(id, level) and missing(id) then
				local price = priceOf(id)
				-- among equal prices, the most plentiful ingredients (the scarcest one counts)
				local stock = math.huge
				for item, count in Config.Food.Dishes[id].ingredients do
					stock = math.min(stock, ((pantry[item] or 0) + (counter[item] or 0)) / count)
				end
				if price > bestPrice or (price == bestPrice and (id == current or stock > bestStock) and not (best == current)) then
					best, bestPrice, bestStock = id, price, stock
				end
			end
		end
		local pick = current
		if best and (missing(current) == nil or bestPrice > priceOf(current)) then
			pick = best
		end
		if pick ~= current then
			Stations.setCookRecipe(farm, index, pick)
			-- (setCookRecipe may have returned unneeded counter stock to the pantry)
			pantry = table.clone(farm.storehouse)
			counter = table.clone(farm.counter)
		end
		local need = missing(pick)
		if need then
			for item, count in Config.Food.Dishes[pick].ingredients do
				local take = math.max(0, count - (counter[item] or 0))
				counter[item] = math.max(0, (counter[item] or 0) - count)
				pantry[item] = (pantry[item] or 0) - take
			end
			space -= need
			spare -= need
		end
	end
end

-- opts: hours (measured), warmup (hours before measuring), mode ("sell" | "autoDish"), fighters (bool: the squads' extra
-- hunger), seed. Returns the measured rates an hour.
function Kitchen.run(level: number, opts: { [string]: any }): { [string]: any }
	local hours = opts.hours or 12
	local warmup = opts.warmup or 4
	local mode = opts.mode or "sell"
	local now = 1000000
	local farm, staffed = FarmKit.fullVillage(now, level)
	local work = farm.work.kitchen
	while #work.slots < FarmState.slotCount(level) do
		table.insert(work.slots, { progress = 0 })
	end
	local used = staffed
	for slot = 1, #work.slots do
		assert(Stations.assign(farm, "s" .. (used + 1), "kitchen", slot, false, now))
		assert(Stations.assign(farm, "s" .. (used + 2), "kitchen", slot, true, now))
		used += 2
	end
	local fighters: { string } = {}
	if opts.fighters then
		local want = Model.squads(level) * Config.Zombies.TeamSize
		for index = #farm.slimes, used + 1, -1 do
			if #fighters < want then
				table.insert(fighters, farm.slimes[index].id)
			end
		end
	end
	-- Fights an hour per fighter (the brief: about 25), each costing FightFullness.
	local fightLoss = Config.Zombies.FightFullness * (opts.fightsPerHour or 25) / 3600 * Config.Village.StepSeconds
	local rng = Rng.new(opts.seed or level)
	local step = Config.Village.StepSeconds
	local sum = {
		raw = 0,
		rawEaten = 0,
		dishEaten = 0,
		coins = 0,
		cooked = { common = 0, uncommon = 0, rare = 0, epic = 0 },
		ingredientsUsed = 0,
		hungrySteps = 0,
		hungryMax = 0,
		hungrySlimeSteps = 0,
		lowest = math.huge,
		fridgeEnd = 0,
	}
	local steps = (warmup + hours) * 3600 / step
	local measureFrom = warmup * 3600 / step
	for index = 1, steps do
		if mode == "autoDish" then
			local best, count = nil, 0
			for id, held in farm.fridge do
				if held > count then
					best, count = id, held
				end
			end
			for _, slime in farm.slimes do
				slime.autoDish = best
			end
		end
		local byId: { [string]: boolean } = {}
		for _, id in fighters do
			byId[id] = true
		end
		for _, slime in farm.slimes do
			if byId[slime.id] then
				slime.needs.fullness = math.max(0, slime.needs.fullness - fightLoss)
			end
		end
		chooseRecipes(farm)
		local events
		farm, events = VillageSim.step(farm, now + index * step, step, rng, { errands = true })
		local measuring = index > measureFrom
		for _, event in events do
			if not measuring then
				continue
			end
			if event.kind == "collected" then
				sum.raw += 1
			elseif event.kind == "ate" then
				if Config.Food.Dishes[event.item] then
					sum.dishEaten += 1
				else
					sum.rawEaten += 1
				end
			elseif event.kind == "cooked" then
				local dish = Config.Food.Dishes[event.item]
				sum.cooked[dish.rarity] += 1
				for _, count in dish.ingredients do
					sum.ingredientsUsed += count
				end
			end
		end
		if mode == "sell" then
			for id, held in table.clone(farm.fridge) do
				local value = Shop.sellDish(farm, id, held)
				if value and measuring then
					sum.coins += value
				end
			end
		end
		if measuring then
			local hungry = 0
			for _, slime in farm.slimes do
				sum.lowest = math.min(sum.lowest, slime.needs.fullness)
				if slime.needs.fullness <= Config.Needs.Hungry then
					hungry += 1
				end
			end
			sum.hungrySlimeSteps += hungry
			if hungry > 0 then
				sum.hungrySteps += 1
			end
			sum.hungryMax = math.max(sum.hungryMax, hungry)
		end
	end
	local measuredSteps = steps - measureFrom
	local made = 0
	for _, count in sum.cooked do
		made += count
	end
	return {
		slimes = #farm.slimes,
		fighters = #fighters,
		cooks = #work.slots,
		hungryMax = sum.hungryMax,
		hungryShare = sum.hungrySteps / measuredSteps,
		hungryAvg = sum.hungrySlimeSteps / measuredSteps,
		lowest = sum.lowest,
		raw = sum.raw / hours,
		rawEaten = sum.rawEaten / hours,
		dishEaten = sum.dishEaten / hours,
		rawIntoDishes = sum.ingredientsUsed / hours,
		cooked = sum.cooked,
		made = made / hours,
		coins = sum.coins / hours,
		hours = hours,
		fridge = total(farm.fridge),
		store = total(farm.storehouse),
	}
end

return Kitchen
