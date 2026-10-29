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
		local speed = Config.Village.WalkSpeed
		local length = speed * Config.Village.HopSeconds * 3 - Config.Village.PathPointEpsilon
		local duration = Path.duration(length, speed)
		T.near(duration, 3 * Config.Village.HopSeconds, 0.0001)
		local start = 100
		local p0 = Path.progress(start, start + duration, start + Config.Slime.CrouchSeconds / 2)
		local p1 = Path.progress(start, start + duration, start + Config.Village.HopSeconds)
		local p2 = Path.progress(start, start + duration, start + duration)
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
end
