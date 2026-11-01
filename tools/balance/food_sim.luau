--!strict
-- Runs the real VillageSim (not an estimate) on a full village at starter SPD and prints whether it stays fed.
-- lune run tools/balance/food_sim.luau [hours] [productive fraction: 1 = no walking, 0.55 = 45% of time lost]
local process = require("@lune/process")
local Config = require("../../src/shared/Config")
local Rng = require("../../src/shared/Rng")
local VillageSim = require("../../src/shared/VillageSim")
local FarmKit = require("../../tests/lib/FarmKit")

local hours = tonumber(process.args[1]) or 24
local productive = tonumber(process.args[2]) or 1
-- Walking and hauling are not in the offline step: slow the work down by the same share instead.
Config.Work.CycleSeconds.fishing /= productive
Config.Work.GardenActionSeconds /= productive

local function total(stock: { [string]: number }): number
	local sum = 0
	for _, count in stock do
		sum += count
	end
	return sum
end

print(string.format("%d hours, productive fraction %.2f", hours, productive))
print("level  slimes workers  avgFull minFull hungry  store  fish/h veg/h ate/h")
for _, level in { 1, 6, 7, 10, 11, 15, 20, 21, 30, 31, 40, 41, 50 } do
	local now = 1000000
	local farm, workers = FarmKit.fullVillage(now, level)
	local rng = Rng.new(level)
	local counts = { fish = 0, veg = 0, ate = 0 }
	local steps = hours * 3600 / Config.Village.StepSeconds
	for step = 1, steps do
		local at = now + step * Config.Village.StepSeconds
		local events
		farm, events = VillageSim.step(farm, at, Config.Village.StepSeconds, rng, { errands = true })
		for _, event in events do
			if event.kind == "collected" and event.area == "fishing" then
				counts.fish += 1
			elseif event.kind == "collected" and event.area == "garden" then
				counts.veg += 1
			elseif event.kind == "ate" then
				counts.ate += 1
			end
		end
	end
	local sum, lowest, hungry = 0, math.huge, 0
	for _, slime in farm.slimes do
		sum += slime.needs.fullness
		lowest = math.min(lowest, slime.needs.fullness)
		if slime.needs.fullness <= Config.Needs.Hungry then
			hungry += 1
		end
	end
	print(
		string.format(
			"%5d %7d %7d %8.1f %7.1f %6d %6d %7.1f %5.1f %5.1f",
			level,
			#farm.slimes,
			workers,
			sum / #farm.slimes,
			lowest,
			hungry,
			total(farm.storehouse),
			counts.fish / hours,
			counts.veg / hours,
			counts.ate / hours
		)
	)
end
