local Stats = require("../../src/shared/Stats")

return function(T)
	T.test("starter stats are level 4", function()
		local s = Stats.starter()
		T.same(s, { attack = 1, defence = 1, speed = 1, hp = 10 })
		T.eq(Stats.level(s), 4)
		s.attack = 50
		T.eq(Stats.starter().attack, 1, "starter() returns a fresh copy")
	end)

	T.test("level = floor(atk + def + spd + hp/10)", function()
		T.eq(Stats.level({ attack = 1, defence = 1, speed = 1, hp = 15 }), 4)
		T.eq(Stats.level({ attack = 1, defence = 1, speed = 1, hp = 20 }), 5)
		T.eq(Stats.level({ attack = 10, defence = 5, speed = 3, hp = 123 }), 30)
		T.eq(Stats.level({ attack = 99, defence = 99, speed = 99, hp = 9990 }), 1296)
	end)

	T.test("clamp to the limits", function()
		T.eq(Stats.clamp("attack", 0), 1)
		T.eq(Stats.clamp("attack", 120), 99)
		T.eq(Stats.clamp("hp", 5), 10)
		T.eq(Stats.clamp("hp", 10000), 9990)
		T.same(
			Stats.clampAll({ attack = 200, defence = -3, speed = 50, hp = 1 }),
			{ attack = 99, defence = 1, speed = 50, hp = 10 }
		)
	end)

	T.test("usable stats are finite numbers above zero", function()
		T.ok(Stats.isUsable(Stats.starter()))
		T.ok(not Stats.isUsable({ attack = 0, defence = 1, speed = 1, hp = 10 }))
		T.ok(not Stats.isUsable({ attack = 0 / 0, defence = 1, speed = 1, hp = 10 }))
		T.ok(not Stats.isUsable({ attack = math.huge, defence = 1, speed = 1, hp = 10 }))
		T.ok(not Stats.isUsable({ attack = 1, defence = 1, speed = 1 }))
		T.ok(not Stats.isUsable("junk"))
	end)

	T.test("validate repairs each stat on its own", function()
		local warnings = {}
		local s = Stats.validate({ attack = 2.6, defence = "x", speed = 500, hp = 42 }, warnings, "s")
		T.same(s, { attack = 3, defence = 1, speed = 99, hp = 42 })
		T.eq(#warnings, 3)
		local w2 = {}
		T.same(Stats.validate(nil, w2, "s"), Stats.starter())
		T.eq(#w2, 1)
		local w3 = {}
		T.same(Stats.validate({ attack = 5, defence = 6, speed = 7, hp = 80 }, w3, "s"), {
			attack = 5,
			defence = 6,
			speed = 7,
			hp = 80,
		})
		T.eq(#w3, 0, "valid stats raise no warning")
	end)
end
