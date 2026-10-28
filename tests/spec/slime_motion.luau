local Config = require("../../src/shared/Config")
local SlimeMotion = require("../../src/shared/SlimeMotion")

local DT = 1 / 60

return function(T)
	T.test("every motion stays finite and in range for thirty seconds", function()
		for _, m in SlimeMotion.Motions do
			local st = SlimeMotion.new(7)
			SlimeMotion.set(st, m)
			for i = 1, 30 * 60 do
				local p = SlimeMotion.step(st, DT, { dirFwd = 0.6, dirSide = -0.4 })
				for k, v in p do
					T.ok(v == v and math.abs(v) < 10, m .. " " .. k .. " at " .. i)
				end
				T.ok(p.sy > 0.45 and p.sy < 1.7, m .. " sy " .. p.sy)
				T.ok(p.sx > 0.7 and p.sx < 1.6, m .. " sx " .. p.sx)
				T.ok(p.lift >= 0 and p.lift < 1, m .. " lift " .. p.lift)
			end
		end
	end)

	T.test("a hop crouches first, flies, and lands squashing and wobbling", function()
		local st = SlimeMotion.new(3)
		SlimeMotion.set(st, "idle")
		for _ = 1, 120 do
			SlimeMotion.step(st, DT)
		end
		SlimeMotion.hop(st, 0.3)
		local crouched, flew, minAfter, landedAt = 1, false, 1, nil
		local maxLift = 0
		for i = 1, 240 do
			local p = SlimeMotion.step(st, DT)
			if p.lift == 0 and not flew then
				crouched = math.min(crouched, p.sy)
			end
			if p.lift > 0 then
				flew = true
				maxLift = math.max(maxLift, p.lift)
			end
			if flew and st.landed and not landedAt then
				landedAt = i
			end
			if landedAt then
				minAfter = math.min(minAfter, p.sy)
			end
		end
		T.ok(crouched < 0.9, "squashes before the jump: " .. crouched)
		T.ok(flew and landedAt, "leaves the ground and comes back")
		T.near(maxLift, 0.3, 0.03, "reaches the height asked for")
		T.ok(minAfter < 0.85, "a landing squash: " .. minAfter)
	end)

	T.test("the wobble dies down", function()
		local st = SlimeMotion.new(5)
		SlimeMotion.set(st, "idle")
		SlimeMotion.kick(st, "squash", -8)
		local early, late = 0, 0
		for i = 1, 6 * 60 do
			local p = SlimeMotion.step(st, DT)
			if i < 60 then
				early = math.max(early, math.abs(math.log(p.sy)))
			elseif i > 5 * 60 then
				late = math.max(late, math.abs(math.log(p.sy) - 0.028 * math.sin(2 * math.pi * 0.55 * st.t + st.phase)))
			end
		end
		T.ok(early > 0.2, "a hard kick squashes: " .. early)
		T.ok(late < 0.06, "and settles to the breathing: " .. late)
	end)

	T.test("a long step is the same as short ones (the physics never blows up)", function()
		local st = SlimeMotion.new(9)
		SlimeMotion.set(st, "excited")
		for _ = 1, 600 do
			local p = SlimeMotion.step(st, 0.5)
			T.ok(p.sy == p.sy and p.sy > 0.4 and p.sy < 1.8)
		end
		T.ok(Config.Slime.MaxStep < 0.1)
	end)

	T.test("curious leans toward the target", function()
		local st = SlimeMotion.new(11)
		SlimeMotion.set(st, "curious")
		local p
		for _ = 1, 180 do
			p = SlimeMotion.step(st, DT, { dirFwd = 1, dirSide = 0 })
		end
		T.ok(p.leanFwd > 0.08, "toward it: " .. p.leanFwd)
	end)

	T.test("sulking turns away", function()
		local st = SlimeMotion.new(13)
		SlimeMotion.set(st, "sulk")
		local p
		for _ = 1, 240 do
			p = SlimeMotion.step(st, DT)
		end
		T.ok(math.abs(p.yaw) > 0.7, "turned: " .. p.yaw)
	end)
end
