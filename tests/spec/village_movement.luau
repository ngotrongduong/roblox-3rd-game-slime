local Config = require("../../src/shared/Config")
local Path = require("../../src/shared/VillagePath")
local Carry = require("../../src/shared/VillageCarry")

return function(T)
	T.test("collinear path points merge but a bend and final spot survive", function()
		local start = { id = "start", area = "plaza", x = 0, y = 2, z = 0 }
		local points = {
			{ id = "via", area = "plaza", x = 2, y = 2, z = 0 },
			{ id = "via", area = "plaza", x = 4, y = 2, z = 0 },
			{ id = "via", area = "plaza", x = 4, y = 2, z = 3 },
			{ id = "target", area = "garden", x = 4, y = 2, z = 5 },
		}
		local merged = Path.merge(start, points)
		T.ok(#merged == 3)
		T.ok(merged[1].x == 4 and merged[1].z == 0)
		T.ok(merged[3].id == "target")
	end)

	T.test("each hop advances only after crouching and before landing", function()
		local gait = Config.Gaits.walk
		local length = gait.HopStuds * 3 - Config.Village.PathPointEpsilon
		local duration = Path.duration(length, 1, "walk")
		local cycle = Path.cycle("walk")
		T.near(duration, 3 * cycle, 0.0001)
		local start = 100
		local p0 = Path.progress(start, start + duration, start + gait.CrouchSeconds / 2, "walk")
		local p1 = Path.progress(start, start + duration, start + cycle, "walk")
		local p2 = Path.progress(start, start + duration, start + duration, "walk")
		T.near(p0, 0, 0.0001)
		T.near(p1, 1 / 3, 0.0001)
		T.near(p2, 1, 0.0001)
	end)

	T.test("carrying permits only matching source and destination", function()
		T.ok(Carry.allowed("fish", "box:fishing", "counter"))
		T.ok(Carry.allowed("carrot", "box:garden", "storehouse"))
		T.ok(Carry.allowed("grilledFish", "counter", "fridge"))
		T.ok(Carry.allowed("Egg", "nest:1", "incubator:2"))
		T.ok(not Carry.allowed("Egg", "nest:1", "storehouse"))
		T.ok(not Carry.allowed("fish", "fridge", "storehouse"))
		T.ok(not Carry.allowed("grilledFish", "counter", "storehouse"))
		T.ok(not Carry.allowed("carrot", "counter", "counter"))
	end)

	T.test("carry prompts show only with something to take or somewhere to put it", function()
		T.ok(not Carry.promptOpen("box:fishing", false, false, false, true), "an empty bin")
		T.ok(Carry.promptOpen("box:fishing", false, false, true, false), "a bin with fish")
		T.ok(not Carry.promptOpen("box:fishing", true, false, true, true), "holding what it does not take")
		T.ok(not Carry.promptOpen("fridge", true, true, false, false), "no fridge built")
		T.ok(not Carry.promptOpen("fridge", false, false, false, true), "a fridge is never a source")
		T.ok(Carry.promptOpen("fridge", true, true, false, true), "a dish to a real fridge")
		T.ok(not Carry.promptOpen("counter", false, false, true, false), "a dish could go nowhere")
		T.ok(Carry.promptOpen("counter", false, false, true, true), "a dish to take to the fridge")
		T.ok(Carry.promptOpen("counter", true, true, false, false), "the counter still takes ingredients")
		T.ok(not Carry.promptOpen("incubator:1", false, false, false, true), "an incubator is not a source")
	end)
end
