--!strict
-- One deterministic simulation for online ticks and offline catch-up. No services or wall clock.
local Breeding = if script then require(script.Parent.Breeding) else require("./Breeding")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Hatching = if script then require(script.Parent.Hatching) else require("./Hatching")
local Luck = if script then require(script.Parent.Luck) else require("./Luck")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")
local ProfileLogic = if script then require(script.Parent.ProfileLogic) else require("./ProfileLogic")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local Training = if script then require(script.Parent.Training) else require("./Training")

type Farm = typeof(FarmState.newFarm(0))
type Rng = typeof(Rng.new(0))
export type Event = { kind: string, item: string?, slimeId: string?, eggId: string? }
export type Options = { errands: boolean }
local VillageSim = {}

local function carry(from: { [string]: number }, to: { [string]: number }, keys: { string }, capacity: number)
	for _, item in keys do
		local available = from[item] or 0
		if available > 0 then
			local moved = Food.add(to, item, available, capacity)
			if moved > 0 then Food.take(from, item, moved) end
		end
	end
end

local function errands(farm: Farm, now: number)
	carry(farm.work.fishing.box, farm.storehouse, Config.Food.RawOrder,
		Food.storehouseCapacity(farm.areas.pantry.level))
	carry(farm.work.garden.box, farm.storehouse, Config.Food.RawOrder,
		Food.storehouseCapacity(farm.areas.pantry.level))
	local wanted = Food.ingredientsWanted(farm)
	for _, item in Config.Food.RawOrder do
		local qty = wanted[item] or 0
		if qty > 0 then
			local moved = Food.add(farm.counter, item, math.min(qty, farm.storehouse[item] or 0),
				Config.Food.CounterCapacity)
			if moved > 0 then Food.take(farm.storehouse, item, moved) end
		end
	end
	carry(farm.work.kitchen.box, farm.fridge, Config.Food.DishOrder,
		Food.fridgeCapacity(farm.areas.kitchen.level))
	-- Move the oldest waiting nest egg first; a ready incubator never restarts.
	for _, egg in farm.eggs do
		if egg.place == "nest" then
			Breeding.placeInIncubator(farm, egg.id, now)
		end
	end
end

local function doWork(farm: Farm, now: number, seconds: number, rng: Rng, events: { Event })
	for _, areaId in Config.Work.Areas do
		local workArea = (farm.work :: any)[areaId]
		local level = (farm.areas :: any)[areaId].level
		local cycle = Stations.cycleSeconds(areaId, level)
		for _, slot in workArea.slots do
			local worker = Stations.activeWorker(farm, slot, now)
			if not worker or (areaId == "training" and not slot.stat) then continue end
			if (areaId == "fishing" or areaId == "garden" or areaId == "kitchen")
				and Food.total(workArea.box) >= Config.Work.BoxCapacity then continue end
			local progress = slot.progress + math.max(0, seconds) * Needs.workFactor(worker.needs)
			while progress >= cycle do
				-- A batch never partly fits: leave progress waiting until a carrier empties the box.
				local output = if areaId == "garden" then Config.Work.GardenYield else Config.Work.FishingYield
				if (areaId == "fishing" or areaId == "garden")
					and Food.total(workArea.box) + output > Config.Work.BoxCapacity then
					progress = cycle
					break
				end
				if areaId == "fishing" then
					Food.add(workArea.box, "fish", Config.Work.FishingYield, Config.Work.BoxCapacity)
					table.insert(events, { kind = "collected", item = "fish" })
				elseif areaId == "garden" then
					local item = if rng:next() < Config.Work.GardenCarrotChance then "carrot" else "cabbage"
					Food.add(workArea.box, item, Config.Work.GardenYield, Config.Work.BoxCapacity)
					table.insert(events, { kind = "collected", item = item })
				elseif areaId == "kitchen" then
					local id = Food.bestDish(farm.counter)
					if id == nil then progress = 0; break end
					local dish = (Config.Food.Dishes :: any)[id]
					for item, count in dish.ingredients do
						Food.take(farm.counter, item, count)
					end
					Food.add(workArea.box, id, Config.Work.KitchenYield, Config.Work.BoxCapacity)
					table.insert(events, { kind = "cooked", item = id })
				elseif areaId == "training" then
					local statKey = slot.stat
					local before = Stats.get(worker.stats, statKey)
					local chance = Training.gainChance(statKey, before, level, Luck.multiplier(farm, now))
					worker.stats = Training.finishSession(worker.stats, statKey, rng, chance)
				end
				progress -= cycle
			end
			slot.progress = progress
		end
	end
end

function VillageSim.step(input: Farm, now: number, seconds: number, rng: Rng, opts: Options): (Farm, { Event })
	local farm: Farm = (ProfileLogic.deepCopy(input) :: any) :: Farm
	local events: { Event } = {}
	local duration = math.max(0, seconds)
	local active: { [string]: boolean } = {}
	for _, areaId in Config.Work.Areas do
		for _, slot in (farm.work :: any)[areaId].slots do
			local worker = Stations.activeWorker(farm, slot, now)
			if worker then active[worker.id] = true end
		end
	end
	for _, slime in farm.slimes do
		local wasGhost = slime.ghostUntil ~= nil and slime.ghostUntil <= now
		if slime.ghostUntil == nil then
			local baby = Growth.isBaby(slime.createdAt, now, Stats.level(slime.stats),
				farm.areas.breeding.level - Config.Village.StartLevel)
			local activity = if Needs.isTired(slime.needs) then "sleep"
				elseif active[slime.id] then "work" else "idle"
			slime.needs = Needs.tick(slime.needs, activity, duration, baby)
			if Needs.wantsFood(slime.needs) then
				local item = Food.eat(farm, slime.id, now)
				if item then table.insert(events, { kind = "ate", item = item, slimeId = slime.id }) end
			end
		end
		if wasGhost then
			slime.ghostUntil = nil
			slime.needs.fullness = Config.Needs.Start
			slime.needs.energy = Config.Needs.Start
			table.insert(events, { kind = "revived", slimeId = slime.id })
		end
	end
	doWork(farm, now, duration, rng, events)
	if opts.errands then errands(farm, now) end
	-- Automatic courtship and laying use the genetics/pity path shared with manual breeding.
	local serial = farm.lifetime.breeds * Config.Breeding.IdAttempts
	local function newId(kind: string): string
		serial += 1
		return kind .. "-village-" .. tostring(math.floor(now)) .. "-" .. tostring(serial)
	end
	for index, pair in farm.breeding.pairs do
		if pair.a and pair.b then
			if pair.courtingUntil and now >= pair.courtingUntil then
				local result = Breeding.layEgg(farm, index, now, rng, newId)
				if result.ok then
					farm = result.farm
					table.insert(events, { kind = "laid", eggId = if result.egg then result.egg.id else nil })
				end
			elseif not pair.courtingUntil and Breeding.pairReady(farm, index, now).ok then
				Breeding.startCourtship(farm, index, now)
			end
		end
	end
	-- Errand mode places newly laid eggs on the same tick when space exists.
	if opts.errands then errands(farm, now) end
	while true do
		local egg = Hatching.nextReadyEgg(farm, now)
		if not egg then break end
		local result = Hatching.hatch(farm, egg.id, now)
		if not result.ok then break end
		farm = result.farm
		table.insert(events, { kind = "hatched", eggId = egg.id, slimeId = if result.slime then result.slime.id else nil })
	end
	farm.lastSimulatedAt = now
	return farm, events
end

function VillageSim.catchUp(input: Farm, lastSimulatedAt: number, now: number, rng: Rng): (Farm, { Event })
	local elapsed = math.clamp(now - lastSimulatedAt, 0, Config.Village.OfflineCapSeconds)
	local interval = Config.Village.StepSeconds
	local start = now - elapsed
	local farm = input
	local events: { Event } = {}
	local steps = math.floor(elapsed / interval)
	for i = 1, steps do
		local batch: { Event }
		farm, batch = VillageSim.step(farm, start + i * interval, interval, rng, { errands = true })
		for _, event in batch do table.insert(events, event) end
	end
	if steps == 0 then farm = (ProfileLogic.deepCopy(input) :: any) :: Farm end
	farm.lastSimulatedAt = now
	return farm, events
end

return VillageSim
