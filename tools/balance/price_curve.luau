--!nocheck
-- Works out the upgrade price of every area level from how long the owner wants the road to be and what a village
-- earns from zombie fights then (coins per fight measured by fight_sim.luau), then walks the road again with the rounded
-- prices to check the times. Then it walks the real prices in Config (Village.upgradeCost) with the three incomes
-- (fights, slime sales, dishes from kitchen_lib on the real VillageSim) and checks the coin vault never blocks buying.
-- lune run tools/balance/price_curve.luau
local Config = require("../../src/shared/Config")
local Village = require("../../src/shared/Village")
local Kitchen = require("./kitchen_lib")
local Model = require("./income_model")

local AREAS = 6
local FIRST_UPGRADE_SECONDS = 30
-- village level reached -> active hours played
local TARGETS = { { 20, 2 }, { 40, 12 }, { 50, 28 } }

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

-- Dish sales a village makes an hour at several levels, measured on the real VillageSim (fighters' hunger in).
Kitchen.setProductive(0.55)
local DISH_HOURS = 6
local dishPoints: { { number } } = {}
for _, at in { 1, 10, 20, 30, 40, 50 } do
	local r = Kitchen.run(at, { hours = DISH_HOURS, mode = "sell", fighters = true })
	table.insert(dishPoints, { at, r.coins })
end
-- Everything a village earns an hour: fights, slimes sold, dishes sold.
local function income(at: number): number
	return Model.fightIncome(at) + Model.slimeIncome(at) + Model.lerp(dishPoints, at)
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

print("area level -> price | all income/h (fights + slimes + dishes) | one upgrade | village reached at (active hours)")
local clock, total, last = 0, 0, 0
for at = 1, 49 do
	local earning = income(at)
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

-- ===== The real prices (Config.Village.UpgradePrices) with the three incomes =====
print("\nThe real prices with three incomes (dishes: kitchen_lib, fighters' hunger in, 0.55 productive)")
print("area  price | fights/h  slimes/h  dishes/h  dish%  | cap  cap/price  fill min | max pantry lag")
local clocks = { fights = 0, all = 0 }
local reached: { [string]: { [number]: number } } = { fights = {}, all = {} }
local blocked = 0
for at = 1, 49 do
	local price = Village.upgradeCost(at)
	local fights = Model.fightIncome(at)
	local slimes = Model.slimeIncome(at)
	local dishes = Model.lerp(dishPoints, at)
	clocks.fights += price * AREAS / fights
	clocks.all += price * AREAS / (fights + slimes + dishes)
	reached.fights[at + 1] = clocks.fights
	reached.all[at + 1] = clocks.all
	-- Equal levels: the vault holds CoinCap(at); the pantry may trail by this many levels before its cap is under the price.
	local cap = Village.coinCap(at)
	local lag = 0
	while at - lag - 1 >= 1 and Village.coinCap(at - lag - 1) >= price do
		lag += 1
	end
	if cap <= price then
		blocked += 1
	end
	if at <= 2 or at % 5 == 0 or at == 19 or at == 39 or at == 49 then
		print(
			string.format(
				"%4d %6d | %8.0f %9.0f %9.0f %5.1f%% | %6d %8.1f %9.1f | %d levels",
				at,
				price,
				fights,
				slimes,
				dishes,
				dishes / fights * 100,
				cap,
				cap / price,
				cap / (fights / 60),
				lag
			)
		)
	end
end
print(string.format("levels where the vault is not above the next price (equal pantry): %d of 49", blocked))
print("village level reached | hours: fights only | all three incomes | target")
for _, row in { { 20, "2" }, { 40, "12" }, { 50, "28" } } do
	print(string.format("%21d | %18.2f | %18.2f | %s", row[1], reached.fights[row[1]], reached.all[row[1]], row[2]))
end
print(string.format("Config: CoinCapMin %d, CoinCapPriceFactor %d", Config.Village.CoinCapMin, Config.Village.CoinCapPriceFactor))
