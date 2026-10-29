--!strict
-- Pure, deterministic smart-object choices. Only arrival applies resources or friendship.
local Breeding = if script then require(script.Parent.Breeding) else require("./Breeding")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Needs = if script then require(script.Parent.Needs) else require("./Needs")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Farm = typeof(FarmState.newFarm(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])
type Rng = typeof(Rng.new(0))
export type Point = { x: number, y: number, z: number }
export type Spot = { id: string, area: string, x: number, y: number, z: number }
export type Context = { spots: { [string]: Spot }?, nearby: { string }?, player: Point? }
export type Action = {
	kind: string,
	spot: string,
	seconds: number,
	emotion: string,
	carry: { item: string, count: number }?,
	partner: string?,
	source: string?,
	eggId: string?,
}

local Brain = {}

local function adult(farm: Farm, slime: Slime, now: number): boolean
	return not Growth.isBaby(
		slime.createdAt,
		now,
		Stats.level(slime.stats),
		farm.areas.breeding.level - Config.Village.StartLevel
	)
end

local function make(kind: string, spot: string, emotion: string): Action
	return {
		kind = kind,
		spot = spot,
		emotion = emotion,
		seconds = (Config.Brain.Duration :: { [string]: number })[kind] or Config.Brain.IdleSeconds,
	}
end

local function eligible(farm: Farm, slimeId: string, now: number): boolean
	local s = FarmState.findSlime(farm, slimeId)
	return s ~= nil and not (s.ghostUntil ~= nil and s.ghostUntil > now)
end

function Brain.choose(farm: Farm, slimeId: string, ctx: Context, now: number, rng: Rng): Action
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or (slime.ghostUntil and slime.ghostUntil > now) then
		return make("ghost", "gate", "sad")
	end
	-- Babies remain in the nursery; only an accompanying adult can take them outside.
	if not adult(farm, slime, now) then
		return make("nursery", "nursery", "curious")
	end
	if slime.sleeping or Needs.isTired(slime.needs) then
		return make("sleep", "nap", "sleepy")
	end
	if Needs.wantsFood(slime.needs) then
		local item, location = Food.chooseMeal(farm, slimeId)
		if item and location then
			local action = make("eat", location, "hungry")
			action.carry = { item = item, count = 1 }
			return action
		end
	end
	for index, pair in farm.breeding.pairs do
		if (pair.a == slimeId or pair.b == slimeId)
			and (pair.courtingUntil or Breeding.pairReady(farm, index, now).ok)
		then
			local a = make("court", "breeding", "loved")
			a.partner = if pair.a == slimeId then pair.b else pair.a
			return a
		end
	end
	for _, area in Config.Work.Areas do
		for index, slot in (farm.work :: any)[area].slots do
			local worker = Stations.activeWorker(farm, slot, now)
			if worker and worker.id == slimeId then
				-- A full box stops production: the worker must haul it if no idle carrier did.
				if Food.total((farm.work :: any)[area].box) >= Config.Work.BoxCapacity then
					if area == "fishing" or area == "garden" then
						for _, item in Config.Food.RawOrder do
							if ((farm.work :: any)[area].box[item] or 0) > 0
								and Food.total(farm.storehouse) < Food.storehouseCapacity(farm.areas.pantry.level)
							then
								local a = make("carryBox", "storehouse", "proud")
								a.source = area
								a.carry = { item = item, count = Config.Brain.CarryAmount }
								return a
							end
						end
					elseif area == "kitchen" and Food.total(farm.fridge) < Food.fridgeCapacity(farm.areas.kitchen.level) then
						for _, item in Config.Food.DishOrder do
							if (farm.work.kitchen.box[item] or 0) > 0 then
								local a = make("carryDish", "fridge", "proud")
								a.carry = { item = item, count = Config.Brain.CarryAmount }
								return a
							end
						end
					end
				end
				return make("work", "work:" .. area .. ":" .. index, "proud")
			end
		end
	end

	local weights = (Config.Brain.TraitWeights :: any)[slime.trait] or Config.Brain.TraitWeights.hardworking
	local best = make("wander", "plaza", "normal")
	local bestScore = -math.huge
	local function offer(action: Action, group: string, base: number)
		local funUrgency = (Config.Needs.Max - slime.needs.fun) / Config.Needs.Max * Config.Brain.FunScore
		local urgency = if group == "play" or group == "social" then funUrgency else 0
		local score = base * (weights[group] or 1) + urgency + rng:next() * Config.Brain.Noise
		if score > bestScore then
			bestScore = score
			best = action
		end
	end

	-- The urgent tasks stay above idle entertainment, but the trait chooses between similar jobs.
	for _, area in { "fishing", "garden" } do
		for _, item in Config.Food.RawOrder do
			if ((farm.work :: any)[area].box[item] or 0) > 0
				and Food.total(farm.storehouse) < Food.storehouseCapacity(farm.areas.pantry.level)
			then
				local a = make("carryBox", "storehouse", "proud")
				a.source = area
				a.carry = { item = item, count = Config.Brain.CarryAmount }
				offer(a, "errands", Config.Brain.ErrandScore)
			end
		end
	end
	for _, item in Config.Food.RawOrder do
		if (Food.ingredientsWanted(farm)[item] or 0) > 0 then
			local a = make("carryKitchen", "counter", "proud")
			a.carry = { item = item, count = Config.Brain.CarryAmount }
			offer(a, "errands", Config.Brain.ErrandScore)
		end
	end
	for _, item in Config.Food.DishOrder do
		if (farm.work.kitchen.box[item] or 0) > 0
			and Food.total(farm.fridge) < Food.fridgeCapacity(farm.areas.kitchen.level)
		then
			local a = make("carryDish", "fridge", "proud")
			a.carry = { item = item, count = Config.Brain.CarryAmount }
			offer(a, "errands", Config.Brain.ErrandScore)
		end
	end
	local freeIncubator: number? = nil
	for slot = 1, FarmState.breedingCount(farm.areas.breeding.level) do
		local occupied = false
		for _, egg in farm.eggs do
			if egg.place == "incubator" and egg.slot == slot then
				occupied = true
				break
			end
		end
		if not occupied then
			freeIncubator = slot
			break
		end
	end
	if freeIncubator then
		for _, egg in farm.eggs do
			if egg.place == "nest" then
				local a = make("carryEgg", "incubator:" .. tostring(freeIncubator), "curious")
				a.eggId = egg.id
				a.source = "nest:" .. tostring(egg.slot)
				offer(a, "errands", Config.Brain.EggScore)
				break
			end
		end
	end
	for _, baby in farm.slimes do
		if baby.id ~= slimeId and adult(farm, slime, now) and not adult(farm, baby, now) then
			if Needs.wantsFood(baby.needs) and Food.chooseMeal(farm, baby.id) ~= nil then
				local a = make("feedBaby", "nursery", "loved")
				a.partner = baby.id
				local _, source = Food.chooseMeal(farm, baby.id)
				a.source = source
				offer(a, "care", Config.Brain.BabyFoodScore)
			end
			local play = make("playBaby", "nursery", "happy")
			play.partner = baby.id
			offer(play, "care", Config.Brain.PlayScore)
			local walk = make("walkBaby", "plaza", "happy")
			walk.partner = baby.id
			walk.source = "nursery"
			offer(walk, "care", Config.Brain.PlayScore)
		end
	end
	if ctx.nearby then
		for _, other in ctx.nearby do
			if other ~= slimeId and eligible(farm, other, now) then
				local a = make("chat", "plaza", "happy")
				a.partner = other
				offer(a, "social", Config.Brain.SocialScore)
				local tag = make("tag", "plaza", "exciting")
				tag.partner = other
				offer(tag, "play", Config.Brain.PlayScore)
				local greet = make("greet", "plaza", "wink")
				greet.partner = other
				offer(greet, "social", Config.Brain.SocialScore)
				if (slime.friends[other] or 0) > 0 then
					local a2 = make("makeup", "plaza", "loved")
					a2.partner = other
					offer(a2, "social", Config.Brain.SocialScore)
				else
					local a2 = make("argue", "plaza", "angry")
					a2.partner = other
					offer(a2, "social", Config.Brain.SocialScore)
				end
			end
		end
	end
	offer(make("watchFish", "pond", "curious"), "daily", Config.Brain.DailyScore)
	offer(make("flowers", "flowers", "happy"), "daily", Config.Brain.DailyScore)
	offer(make("splash", "fountain", "laughing"), "play", Config.Brain.PlayScore)
	offer(make("warm", "campfire", "full"), "daily", Config.Brain.DailyScore)
	offer(make("wander", "plaza", "normal"), "daily", Config.Brain.DailyScore)
	if ctx.player then
		offer(make("player", "player", "exciting"), "social", Config.Brain.PlayerScore)
	end
	return best
end

-- Arrival never trusts the snapshot taken at decision time; another slime may have moved the item.
function Brain.arrive(farm: Farm, slimeId: string, action: Action, now: number): (Farm, boolean)
	local slime = FarmState.findSlime(farm, slimeId)
	if not slime or (slime.ghostUntil and slime.ghostUntil > now) then
		return farm, false
	end
	if action.kind == "sleep" then
		if not slime.sleeping and not Needs.isTired(slime.needs) then
			return farm, false
		end
		slime.sleeping = true
		return farm, true
	elseif action.kind == "eat" then
		if not Needs.wantsFood(slime.needs) or not action.carry then
			return farm, false
		end
		local item, place = Food.chooseMeal(farm, slimeId)
		if item ~= action.carry.item or place ~= action.spot then
			return farm, false
		end
		return farm, Food.eat(farm, slimeId, now) ~= nil
	elseif action.kind == "carryBox" or action.kind == "carryKitchen" or action.kind == "carryDish" then
		if not action.carry or not adult(farm, slime, now) then
			return farm, false
		end
		local from: { [string]: number }
		local to: { [string]: number }
		local capacity: number
		if action.kind == "carryBox" then
			if action.source ~= "fishing" and action.source ~= "garden" then
				return farm, false
			end
			from = (farm.work :: any)[action.source].box
			to = farm.storehouse
			capacity = Food.storehouseCapacity(farm.areas.pantry.level)
		elseif action.kind == "carryKitchen" then
			from, to, capacity = farm.storehouse, farm.counter, Config.Food.CounterCapacity
			if (Food.ingredientsWanted(farm)[action.carry.item] or 0) <= 0 then
				return farm, false
			end
		else
			from, to, capacity = farm.work.kitchen.box, farm.fridge, Food.fridgeCapacity(farm.areas.kitchen.level)
		end
		local wanted = math.min(Config.Brain.CarryAmount, action.carry.count, from[action.carry.item] or 0)
		if action.kind == "carryKitchen" then
			wanted = math.min(wanted, Food.ingredientsWanted(farm)[action.carry.item] or 0)
		end
		if wanted <= 0 then
			return farm, false
		end
		local moved = Food.add(to, action.carry.item, wanted, capacity)
		if moved <= 0 then
			return farm, false
		end
		Food.take(from, action.carry.item, moved)
		return farm, true
	elseif action.kind == "carryEgg" then
		if not action.eggId or not adult(farm, slime, now) then
			return farm, false
		end
		-- A newly occupied target slot makes this route stale, even if another slot is free.
		local slot = tonumber(string.match(action.spot, "^incubator:(%d+)$"))
		if not slot then
			return farm, false
		end
		for index = 1, FarmState.breedingCount(farm.areas.breeding.level) do
			local occupied = false
			for _, egg in farm.eggs do
				if egg.place == "incubator" and egg.slot == index then
					occupied = true
					break
				end
			end
			if not occupied then
				if index ~= slot then
					return farm, false
				end
				break
			end
		end
		local ok = Breeding.placeInIncubator(farm, action.eggId, now)
		return farm, ok
	elseif action.kind == "feedBaby" or action.kind == "playBaby" or action.kind == "walkBaby" then
		if not action.partner or not adult(farm, slime, now) then
			return farm, false
		end
		local baby = FarmState.findSlime(farm, action.partner)
		if not baby or adult(farm, baby, now) or (baby.ghostUntil and baby.ghostUntil > now) then
			return farm, false
		end
		if action.kind == "feedBaby" then
			if not Needs.wantsFood(baby.needs) then
				return farm, false
			end
			return farm, Food.eat(farm, baby.id, now) ~= nil
		end
		baby.needs.fun = math.min(Config.Needs.Max, baby.needs.fun + Config.Brain.FunGain)
		slime.needs.fun = math.min(Config.Needs.Max, slime.needs.fun + Config.Brain.FunGain)
		return farm, true
	elseif action.kind == "chat" or action.kind == "tag" or action.kind == "greet"
		or action.kind == "argue" or action.kind == "makeup"
	then
		if not action.partner or not eligible(farm, action.partner, now) or action.partner == slimeId then
			return farm, false
		end
		local partner = FarmState.findSlime(farm, action.partner)
		if not partner then
			return farm, false
		end
		local function bond(a: Slime, b: Slime)
			if a.friends[b.id] == nil then
				local count = 0
				for _ in a.friends do
					count += 1
				end
				if count >= Config.Brain.MaxFriends then
					return
				end
			end
			local score = (a.friends[b.id] or 0)
				+ (if action.kind == "argue" then -Config.Brain.FriendLoss else Config.Brain.FriendGain)
			-- A zero bond is not one of the slime's three best friends.
			a.friends[b.id] = if score > 0 then score else nil
		end
		bond(slime, partner)
		bond(partner, slime)
		slime.needs.fun = math.min(Config.Needs.Max, slime.needs.fun + Config.Brain.FunGain)
		partner.needs.fun = math.min(Config.Needs.Max, partner.needs.fun + Config.Brain.FunGain)
		return farm, true
	elseif action.kind == "splash" then
		slime.needs.fun = math.min(Config.Needs.Max, slime.needs.fun + Config.Brain.FunGain)
		return farm, true
	end
	-- Watching, wandering and courting are visual actions; the simulator owns their timers.
	return farm, false
end

return Brain
