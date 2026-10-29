local Needs = require("../../src/shared/Needs")
local Config = require("../../src/shared/Config")
return function(T)
	T.test("idle and working needs fall at configured rates", function()
		local n = { fullness = 100, energy = 100, fun = 100 }
		T.same(Needs.tick(n, "idle", 60), { fullness = 98, energy = 99.5, fun = 99.5 })
		T.same(Needs.tick(n, "work", 60), { fullness = 97, energy = 98, fun = 99.5 })
		T.eq(n.fullness, 100, "tick does not modify its input")
		T.eq(Needs.tick({ fullness = 10, energy = 20, fun = 0 }, "sleep", 120).energy, 30)
	end)
	T.test("continuous sleep reaches rested energy without interrupted shifts", function()
		local VillageSim = require("../../src/shared/VillageSim")
		local FarmKit = require("../lib/FarmKit")
		local Rng = require("../../src/shared/Rng")
		local Stations = require("../../src/shared/Stations")
		local farm = FarmKit.farm(1000000)
		farm.slimes[1].needs.energy = 20
		T.ok(Stations.assign(farm, "slime-1", "fishing", 1, false, 1000000))
		for i = 1, 10 do
			farm = VillageSim.step(farm, 1000000 + i * 60, 60, Rng.new(i), { errands = false })
		end
		T.eq(farm.slimes[1].needs.energy, 70)
		T.ok(farm.slimes[1].sleeping)
		for i = 11, 14 do
			farm = VillageSim.step(farm, 1000000 + i * 60, 60, Rng.new(i), { errands = false })
		end
		T.eq(farm.slimes[1].needs.energy, 90)
		T.eq(farm.slimes[1].sleeping, nil)
	end)
	T.test("threshold boundaries, hunger and baby multiplier", function()
		local n = { fullness = 50, energy = 21, fun = 50 }
		T.ok(Needs.wantsFood(n))
		T.ok(not Needs.isHungry(n))
		n.fullness = 25
		T.ok(Needs.isHungry(n))
		T.eq(Needs.workFactor(n), 0.5)
		n.fullness = 60
		T.ok(Needs.canPair(n))
		n.energy = 20
		T.ok(Needs.isTired(n))
		T.ok(not Needs.canPair(n))
		n.energy = 90
		T.ok(Needs.rested(n))
		T.eq(Needs.tick({ fullness = 100, energy = 100, fun = 100 }, "idle", 60, true).fullness, 99)
		T.eq(Needs.eatValue(n, 999).fullness, Config.Needs.Max)
	end)
end
