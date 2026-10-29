local Training = require("../../src/shared/Training")
local Rng = require("../../src/shared/Rng")
local Stats = require("../../src/shared/Stats")
return function(T)
	T.test("soft cap, HP scaling and area multiplier", function()
		for _, row in { { 1, 0.60 }, { 10, 0.315789 }, { 20, 0.206897 }, { 50, 0.101695 }, { 99, 0.055556 } } do
			T.near(Training.gainChance("attack", row[1], 1, 1), row[2], 0.0001)
		end
		T.near(Training.gainChance("hp", 100, 1, 1), Training.gainChance("attack", 10, 1, 1), 0.00001)
		T.near(Training.gainChance("attack", 50, 50, 1), 2 * Training.gainChance("attack", 50, 1, 1), 0.00001)
	end)
	T.test("100000 seeded sessions agree within half a percentage point", function()
		local n = 100000
		local rng = Rng.new(77)
		local before = Stats.starter()
		local chance = Training.gainChance("attack", 10, 1, 1)
		local successes = 0
		for _ = 1, n do
			local after = Training.finishSession(before, "attack", rng, chance)
			if after.attack > before.attack then
				successes += 1
			end
		end
		T.near(successes / n, chance, 0.005)
		T.eq(
			Training.finishSession({ attack = 99, defence = 1, speed = 1, hp = 10 }, "attack", Rng.new(1), 1).attack,
			99
		)
	end)
end
