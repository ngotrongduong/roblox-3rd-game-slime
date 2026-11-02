--!strict
local Breeding = require("../../src/shared/Breeding")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")
local VillageSim = require("../../src/shared/VillageSim")
local FarmKit = require("../lib/FarmKit")
local Food = require("../../src/shared/Food")
local Stations = require("../../src/shared/Stations")

-- The offline step has no walking, so the work is slowed by the share of time a slime loses walking and hauling.
local LOST_TO_WALKING = 0.55

return function(T: any)
	T.test("a full village of starter-SPD slimes stays fed in the real simulation", function()
		local fishing, action = Config.Work.CycleSeconds.fishing, Config.Work.GardenActionSeconds
		Config.Work.CycleSeconds.fishing = fishing / LOST_TO_WALKING
		Config.Work.GardenActionSeconds = action / LOST_TO_WALKING
		for _, level in { 1, 10, 11, 50 } do
			local now = 1000000
			local farm, staffed = FarmKit.fullVillage(now, level)
			-- A real cook competes for the same raw inventory; food still has to feed the entire village.
			T.ok(Stations.assign(farm, "s" .. (staffed + 1), "kitchen", 1, false, now))
			local rng = Rng.new(level)
			for step = 1, 6 * 3600 / Config.Village.StepSeconds do
				local at = now + step * Config.Village.StepSeconds
				farm = VillageSim.step(farm, at, Config.Village.StepSeconds, rng, { errands = true })
			end
			for _, slime in farm.slimes do
				T.ok(slime.needs.fullness > Config.Needs.Hungry, slime.id .. " is hungry at level " .. level)
			end
			T.ok(Food.total(farm.fridge) + Food.total(farm.work.kitchen.box) > 0,
				"the staffed kitchen cooks at level " .. level)
		end
		Config.Work.CycleSeconds.fishing = fishing
		Config.Work.GardenActionSeconds = action
	end)
	T.test("existing saves above the lowered population cap retain all slimes", function()
		local now = 1000000
		local oldSlimes = FarmKit.many(20)
		for _, slime in oldSlimes do
			-- Saved adults have positive historical timestamps; 0 is repaired as a newborn.
			slime.createdAt = now - 1000
		end
		local farm = FarmKit.farm(now, oldSlimes)
		local restored = FarmState.repair(farm, now)
		T.eq(#restored.slimes, 20)
		T.eq(FarmState.populationLimit(restored.areas), 12)
		T.eq(Breeding.check(restored, "s1", "s2", now).reason, "SLIME_CAP_REACHED")
	end)
end
