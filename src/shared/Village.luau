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
	local anchors = Config.Village.UpgradePrices
	if level <= anchors[1].level then
		return anchors[1].price
	end
	for index = 2, #anchors do
		local high = anchors[index]
		local low = anchors[index - 1]
		if level <= high.level then
			-- Exact anchors are preserved; intermediate values get two significant digits.
			if level == high.level then
				return high.price
			end
			local fraction = (level - low.level) / (high.level - low.level)
			local value = low.price * (high.price / low.price) ^ fraction
			local magnitude = 10 ^ (math.floor(math.log10(value)) - 1)
			local rounded = math.floor(value / magnitude + 0.5) * magnitude
			return math.max(low.price, math.min(high.price, rounded))
		end
	end
	return anchors[#anchors].price
end

-- Battle income fills the vault only to its ceiling; selling may go over it.
function Village.coinCap(pantryLevel: number): number
	return math.max(Config.Village.CoinCapMin, Config.Village.CoinCapPriceFactor * Village.upgradeCost(pantryLevel))
end

function Village.upgrade(farm: Farm, areaId: string, free: boolean?): (boolean, string?)
	local area = (farm.areas :: any)[areaId]
	if not table.find(Village.Areas, areaId) or not area then
		return false, "NO_AREA"
	end
	if area.level >= Config.Village.MaxLevel then
		return false, "MAX_LEVEL"
	end
	local price = Village.upgradeCost(area.level)
	if not free and farm.coins < price then
		return false, "NO_COINS"
	end
	if not free then
		farm.coins -= price
	end
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
