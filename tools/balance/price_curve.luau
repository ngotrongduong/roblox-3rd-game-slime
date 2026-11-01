--!strict
-- Works out the upgrade price of every area level from how long the owner wants the road to be and what a village
-- earns then (measured by income_sim.luau), then walks the road again with the rounded prices to check the times.
-- lune run tools/balance/price_curve.luau
local AREAS = 6
local FIRST_UPGRADE_SECONDS = 30
-- village level reached -> active hours played
-- (asked for: 2, 12 and 28; the levels where prices wait for the luck to run out add about 0.4 h, taken off here)
local TARGETS = { { 20, 1.6 }, { 40, 11.6 }, { 50, 27.6 } }
-- 9 eggs an hour a pair in income_sim; slimes walk online, the simulation's step does not: take a fifth off (assumed).
local EGGS_PER_PAIR_HOUR = 9 * 0.8
-- What a baby sells for at sell values x10, as the player moves on to better parents (assumed, see docs/ECONOMY.md).
local COINS_PER_EGG = { { 1, 330 }, { 10, 600 }, { 20, 1000 }, { 30, 1500 }, { 40, 2000 }, { 50, 3000 } }

-- New-player luck multiplies the rare chances (Config.Luck): worked out per egg from Config.Inheritance, luck x5 pays
-- 3.4 times a normal egg for the first half hour, luck x3 pays 2.2 times for the next.
local function luckFactor(hour: number): number
	return if hour < 0.5 then 3.4 elseif hour < 1 then 2.2 else 1
end

local function coinsPerEgg(level: number): number
	for index = 2, #COINS_PER_EGG do
		local low, high = COINS_PER_EGG[index - 1], COINS_PER_EGG[index]
		if level <= high[1] then
			return low[2] + (high[2] - low[2]) * (level - low[1]) / (high[1] - low[1])
		end
	end
	return COINS_PER_EGG[#COINS_PER_EGG][2]
end

local function incomePerHour(level: number): number
	local pairs = if level >= 41 then 4 elseif level >= 21 then 3 else 2
	return pairs * EGGS_PER_PAIR_HOUR * coinsPerEgg(level)
end

local function geometricSum(first: number, growth: number, count: number): number
	local sum, term = 0, first
	for _ = 1, count do
		sum += term
		term *= growth
	end
	return sum
end

local function solveGrowth(first: number, count: number, total: number): number
	local low, high = 0.5, 3
	for _ = 1, 60 do
		local middle = (low + high) / 2
		if geometricSum(first, middle, count) < total then
			low = middle
		else
			high = middle
		end
	end
	return low
end

local function nice(value: number): number
	local step = 10 ^ math.max(0, math.floor(math.log10(math.max(value, 1))) - 1)
	return math.max(step, math.floor(value / step + 0.5) * step)
end

local seconds: { [number]: number } = {}
local level, first, hoursBefore = 1, FIRST_UPGRADE_SECONDS, 0
for _, target in TARGETS do
	local count = target[1] - level
	local budget = (target[2] - hoursBefore) * 3600 / AREAS
	local growth = solveGrowth(first, count, budget)
	local term = first
	for at = level, target[1] - 1 do
		seconds[at] = term
		term *= growth
	end
	print(string.format("levels %d-%d: each level's upgrades take %.1f%% longer", level, target[1], (growth - 1) * 100))
	level, first, hoursBefore = target[1], term, target[2]
end

print("area level -> price | income/h | one upgrade | village reached at (active hours)")
local clock, total, last = 0, 0, 0
for at = 1, 49 do
	local earning = incomePerHour(at) * luckFactor(clock)
	-- (a price never falls when the luck runs out: those levels just take a little longer)
	local price = math.max(last, nice(earning * seconds[at] / 3600))
	last = price
	local spent = price * AREAS / earning
	clock += spent
	total += price
	if at <= 3 or at % 5 == 0 or at == 49 then
		print(
			string.format(
				"%3d -> %8d | %7.0f | %6.0f s | village %2d at %5.2f h",
				at,
				price,
				earning,
				spent / AREAS * 3600,
				at + 1,
				clock
			)
		)
	end
end
print(string.format("one area, 1 to 50: %d coins; the whole village: %d coins", total, total * AREAS))
