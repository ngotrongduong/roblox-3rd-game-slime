--!strict
-- The Lucky Wheel (docs/MONETIZATION.md §3): pure rules, the server rolls and pays. Spins come from two places: the free
-- spins of the UTC day (Config.Wheel.FreePerDay, a VIP has VipFreePerDay more; one not used by midnight is lost) and the
-- bank (`farm.rewards.wheel.bank`), which check-in days, quests, the 60-minute online gift, the wheel itself and Robux fill
-- and which never expires. A spin uses a free one first. The prize is a Config.Wheel slice, paid through Rewards.pay.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local RngModule = if script then require(script.Parent.Rng) else require("./Rng")
local Rewards = if script then require(script.Parent.Rewards) else require("./Rewards")

type Farm = typeof(FarmState.newFarm(0))
type Rng = typeof(RngModule.new(0))
-- (Rewards' exported types cannot be read through the Lune-friendly require)
type Grant = typeof(Rewards.grant(nil, (nil :: any) :: Farm))

local W = Config.Wheel

local Wheel = {}

-- The free spins of the day and the most there can be (a VIP has more).
function Wheel.freeMax(isVip: boolean?): number
	return W.FreePerDay + (if isVip then W.VipFreePerDay else 0)
end

-- Free spins left today.
function Wheel.freeSpins(farm: Farm, now: number, isVip: boolean?): number
	local wheel = farm.rewards.wheel
	local used = if wheel.day == Rewards.dayOf(now) then wheel.used else 0
	return math.max(0, Wheel.freeMax(isVip) - used)
end

-- Every spin the player can make now: the free ones and the bank.
function Wheel.spinsLeft(farm: Farm, now: number, isVip: boolean?): number
	return Wheel.freeSpins(farm, now, isVip) + farm.rewards.wheel.bank
end

-- The sum of the slices' weights (the odds shown on the wheel are weight / this).
function Wheel.totalWeight(): number
	local total = 0
	for _, slice in W.Slices do
		total += slice.weight
	end
	return total
end

-- One spin. `seedOrRng`: a seed number (made into the game's own Rng) or an Rng. Returns (true, nil, the slice's index,
-- what it paid) or (false, "NO_SPIN") and changes nothing.
function Wheel.spin(
	farm: Farm,
	seedOrRng: number | Rng,
	now: number,
	isVip: boolean?
): (boolean, string?, number?, Grant?)
	local wheel = farm.rewards.wheel
	local free = Wheel.freeSpins(farm, now, isVip)
	if free <= 0 and wheel.bank <= 0 then
		return false, "NO_SPIN", nil, nil
	end
	local rng: Rng = if type(seedOrRng) == "number" then RngModule.new(seedOrRng) else seedOrRng
	local slice = rng:weighted(W.Slices, function(entry)
		return entry.weight
	end)
	local index = table.find(W.Slices, slice) :: number
	if free > 0 then
		local today = Rewards.dayOf(now)
		if wheel.day ~= today then
			wheel.day, wheel.used = today, 0
		end
		wheel.used += 1
	else
		wheel.bank -= 1
	end
	local grant = Rewards.grant(slice.reward, farm)
	Rewards.pay(farm, grant, now)
	farm.lifetime.wheelSpins += 1
	return true, nil, index, grant
end

-- What the client draws: the spins left (free, the most free, the bank), the server time the free ones come back, and the
-- slices in the order of the wheel with their chance (percent) and what each pays now.
--   { free, freeMax, bank, reset, slices = { { id, name, chance, coins, luck, spins, items } } }
function Wheel.view(farm: Farm, now: number, isVip: boolean?): { [string]: any }
	local total = Wheel.totalWeight()
	local slices = {}
	for _, slice in W.Slices do
		local grant = Rewards.grant(slice.reward, farm)
		table.insert(slices, {
			id = slice.id,
			name = slice.name,
			chance = slice.weight / total * 100,
			coins = grant.coins,
			luck = grant.luck,
			spins = grant.spins,
			items = grant.items,
		})
	end
	return {
		free = Wheel.freeSpins(farm, now, isVip),
		freeMax = Wheel.freeMax(isVip),
		bank = farm.rewards.wheel.bank,
		reset = (Rewards.dayOf(now) + 1) * 86400,
		slices = slices,
	}
end

return Wheel
