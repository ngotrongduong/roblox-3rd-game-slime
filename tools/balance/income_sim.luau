--!strict
-- What a village earns from selling its babies, on the real VillageSim: every breeding place filled with two plain
-- slimes of different colours, every food slot staffed, each baby sold the moment it hatches.
-- lune run tools/balance/income_sim.luau [hours]
local process = require("@lune/process")
local Breeding = require("../../src/shared/Breeding")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Mutations = require("../../src/shared/Mutations")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")
local VillageSim = require("../../src/shared/VillageSim")
local FarmKit = require("../../tests/lib/FarmKit")

local hours = tonumber(process.args[1]) or 6
local STEP = 15

print(string.format("%d hours, one step %d s, plain parents, level 4 babies", hours, STEP))
print("level pairs slimes  eggs/h coins/h coins/egg  plain  dual material secret  minFull store")
for _, level in { 1, 10, 11, 20, 21, 30, 40, 41, 50 } do
	local now = 1000000
	local farm, staffed = FarmKit.fullVillage(now, level)
	local limit = FarmState.populationLimit(farm.areas)
	while #farm.breeding.pairs < FarmState.breedingCount(level) do
		table.insert(farm.breeding.pairs, {})
	end
	-- Room for the eggs on the way: the rest of the village stays full, so it eats as a full village does.
	local keep = math.max(staffed + 2 * #farm.breeding.pairs, limit - Config.Breeding.MaxActiveEggs)
	while #farm.slimes > keep do
		table.remove(farm.slimes)
	end
	while #farm.slimes < keep do
		table.insert(farm.slimes, FarmKit.slime("s" .. (#farm.slimes + 1)))
	end
	for index in farm.breeding.pairs do
		local a = farm.slimes[staffed + 2 * index - 1]
		local b = farm.slimes[staffed + 2 * index]
		a.colourGenotype = { alleles = { "black", "black" } }
		a.visibleColour = "black"
		assert(Breeding.setPair(farm, index, a.id, b.id, now))
	end

	local rng = Rng.new(level)
	local counts = { none = 0, dual = 0, material = 0, secret = 0 }
	local coins, eggs = 0, 0
	for step = 1, hours * 3600 / STEP do
		local events
		farm, events = VillageSim.step(farm, now + step * STEP, STEP, rng, { errands = true })
		for _, event in events do
			if event.kind == "laid" then
				eggs += 1
			elseif event.kind == "hatched" and event.slimeId then
				local slime, at = FarmState.findSlime(farm, event.slimeId)
				if slime and at then
					local kind = slime.appearanceMutation.type
					counts[kind] = (counts[kind] or 0) + 1
					coins += Mutations.sellValue(slime.appearanceMutation, Stats.level(slime.stats))
					table.remove(farm.slimes, at)
				end
			end
		end
	end
	local lowest = math.huge
	for _, slime in farm.slimes do
		lowest = math.min(lowest, slime.needs.fullness)
	end
	local stored = 0
	for _, count in farm.storehouse do
		stored += count
	end
	print(
		string.format(
			"%5d %5d %6d %7.1f %7.0f %9.1f %6d %5d %8d %6d %8.1f %5d",
			level,
			#farm.breeding.pairs,
			#farm.slimes,
			eggs / hours,
			coins / hours,
			coins / math.max(1, eggs),
			counts.none,
			counts.dual,
			counts.material,
			counts.secret,
			lowest,
			stored
		)
	)
end
