--!strict
-- Works out the upgrade price of every area level from how long the owner wants the road to be and what a village
-- earns from zombie fights then (coins per fight measured by fight_sim.luau), then walks the road again with the rounded
-- prices to check the times. lune run tools/balance/price_curve.luau
local AREAS = 6
local FIRST_UPGRADE_SECONDS = 30
-- village level reached -> active hours played
local TARGETS = { { 20, 2 }, { 40, 12 }, { 50, 28 } }
-- A fight of the middle camp takes 36 s and the squad needs about 30 s to get back and go out again; a player who also
-- runs the village has a squad out about half the time (assumed).
local FIGHTS_PER_SQUAD_HOUR = 3600 / (36 + 30) * 0.5
-- Measured in fight_sim: slime level -> coins a fight in the middle camp.
local COINS_PER_FIGHT = { { 4, 1900 }, { 8, 2230 }, { 12, 2350 }, { 20, 2900 }, { 30, 3700 }, { 40, 4280 }, { 60, 5830 } }
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

local function incomePerHour(level: number): number
	return squads(level) * FIGHTS_PER_SQUAD_HOUR * lerp(COINS_PER_FIGHT, lerp(SLIME_LEVEL, level))
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
