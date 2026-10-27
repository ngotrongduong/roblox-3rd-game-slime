local Growth = require("../../src/shared/Growth")

return function(T)
	T.test("grow-up time: 300 s + 1 s per level above 1", function()
		T.eq(Growth.growUpSeconds(4, 0), 303)
		T.eq(Growth.growUpSeconds(1, 0), 300)
		T.eq(Growth.growUpSeconds(0, 0), 300)
		T.eq(Growth.growUpSeconds(101, nil), 400)
	end)

	T.test("Faster Growth: x0.95 per level, capped at level 20, rounded to ms", function()
		-- round(303000 * 0.95) = 287850 ms
		T.near(Growth.growUpSeconds(4, 1), 287.85, 1e-9)
		-- round(303000 * 0.95^20) = 108621 ms
		T.near(Growth.growUpSeconds(4, 20), 108.621, 1e-9)
		T.eq(Growth.growUpSeconds(4, 40), Growth.growUpSeconds(4, 20))
	end)

	T.test("a baby until grown up", function()
		T.ok(Growth.isBaby(1000, 1000, 4, 0))
		T.ok(Growth.isBaby(1000, 1302.9, 4, 0))
		T.ok(not Growth.isBaby(1000, 1303, 4, 0))
		T.eq(Growth.remainingSeconds(1000, 1100, 4, 0), 203)
		T.eq(Growth.remainingSeconds(1000, 5000, 4, 0), 0)
		-- a clock before createdAt never makes the wait longer than a full grow-up
		T.eq(Growth.remainingSeconds(1000, 900, 4, 0), 303)
	end)

	T.test("baby scale eases 0.62 to 1", function()
		T.near(Growth.scale(0, 0, 1, 0), 0.62, 1e-12)
		T.near(Growth.scale(0, 150, 1, 0), 0.81, 1e-12)
		T.near(Growth.scale(0, 300, 1, 0), 1, 1e-12)
		T.near(Growth.scale(0, 9000, 1, 0), 1, 1e-12)
		T.near(Growth.scale(100, 0, 1, 0), 0.62, 1e-12)
	end)
end
