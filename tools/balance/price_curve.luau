--!strict
-- Works out the upgrade price of every area level from how long the owner wants the road to be and what a village
-- earns from zombie fights then (coins per fight measured by fight_sim.luau), then walks the road again with the rounded
-- prices to check the times. lune run tools/balance/price_curve.luau
local AREAS = 6
local FIRST_UPGRADE_SECONDS = 30
-- village level reached -> active hours played
local TARGETS = { { 20, 2 }, { 40, 12 }, { 50, 28 } }
-- With repeat on, a team is out all the time; heal is how long it waits for its wounds (HealPerMinute, assumed by loss).
local BUSY_SHARE = 1
-- Measured in fight_sim, per camp: slimes lost a fight, seconds a fight, slime level -> coins a fight. march is one way at
-- starter SPD (seen in play: 26 s to the first camp; the server's report for the others), the march counted both ways.
local CAMPS = {
	{ deaths = 0.25, fight = 23, march = 26, heal = 60, coins = { { 4, 858 }, { 8, 915 }, { 12, 1063 }, { 20, 1367 }, { 30, 1665 }, { 40, 1966 }, { 60, 2819 } } },
	{ deaths = 1.05, fight = 30, march = 46, heal = 90, coins = { { 4, 1874 }, { 8, 2228 }, { 12, 2336 }, { 20, 2895 }, { 30, 3652 }, { 40, 4176 }, { 60, 5750 } } },
	{ deaths = 3.0, fight = 40, march = 66, heal = 120, coins = { { 4, 3103 }, { 8, 3267 }, { 12, 3722 }, { 20, 4292 }, { 30, 5883 }, { 40, 6300 }, { 60, 8398 } } },
}
-- Dead slimes must be made good or the village runs out: 9 eggs an hour a pair (income_sim), a fifth lost to walking
-- (assumed), and about 10 revives an hour from the food a staffed village has to spare.
local EGGS_PER_PAIR_HOUR = 9 * 0.8
local REVIVES_PER_HOUR = 10
-- Assumed until a play test measures it: village level -> the average level of the strongest slimes.
local SLIME_LEVEL = { { 1, 4 }, { 10, 8 }, { 20, 12 }, { 30, 20 }, { 40, 30 }, { 50, 40 } }

local function lerp(points: { { number } }, at: number): number
	for index = 2, #points do
		local low, high = points[index - 1], points[index]
		if at <= high[1] then
			return low[2] + (high[2] - low[2]) * (at - low[1]) / (high[1] - low[1])
		end
	end
	return points[#points][2]
end

-- Squads a village can spare beside its workers, from its population limit.
local function squads(level: number): number
	return if level >= 20 then 4 elseif level >= 15 then 3 elseif level >= 6 then 2 else 1
end

-- The best the player can do at this level: as many fights as the squads have time for and the village can lose slimes
-- to, in whichever camp pays most.
local function incomePerHour(level: number): number
	local pairs = if level >= 41 then 4 elseif level >= 21 then 3 else 2
	local replaced = pairs * EGGS_PER_PAIR_HOUR + REVIVES_PER_HOUR
	local slimeLevel = lerp(SLIME_LEVEL, level)
	local best = 0
	for _, camp in CAMPS do
		local inTime = squads(level) * 3600 / (camp.fight + 2 * camp.march + camp.heal) * BUSY_SHARE
		local fights = math.min(inTime, replaced / camp.deaths)
		best = math.max(best, fights * lerp(camp.coins, slimeLevel))
	end
	return best
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
	local earning = incomePerHour(at)
	-- (a price never falls)
	local price = math.max(last, nice(earning * seconds[at] / 3600))
	last = price
	local spent = price * AREAS / earning
	clock += spent
	total += price
	if at <= 2 or at % 5 == 0 or at == 19 or at == 39 or at == 49 then
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
