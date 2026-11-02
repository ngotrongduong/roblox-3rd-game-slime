--!strict
-- What a village earns an hour from zombie fights and from selling slimes, at each village level. Shared by price_curve and
-- kitchen_sim, so the fight income they compare dishes against is the same number.
local Model = {}

-- Measured in fight_sim, per camp: slimes lost a fight, seconds a fight, slime level -> coins a fight. march is one way at
-- starter SPD (seen in play: 26 s to the first camp; the server's report for the others), the march counted both ways.
Model.CAMPS = {
	{ deaths = 0.25, fight = 23, march = 26, heal = 60, coins = { { 4, 858 }, { 8, 915 }, { 12, 1063 }, { 20, 1367 }, { 30, 1665 }, { 40, 1966 }, { 60, 2819 } } },
	{ deaths = 1.05, fight = 30, march = 46, heal = 90, coins = { { 4, 1874 }, { 8, 2228 }, { 12, 2336 }, { 20, 2895 }, { 30, 3652 }, { 40, 4176 }, { 60, 5750 } } },
	{ deaths = 3.0, fight = 40, march = 66, heal = 120, coins = { { 4, 3103 }, { 8, 3267 }, { 12, 3722 }, { 20, 4292 }, { 30, 5883 }, { 40, 6300 }, { 60, 8398 } } },
}
-- Dead slimes must be made good or the village runs out: 9 eggs an hour a pair (income_sim), a fifth lost to walking
-- (assumed), and about 10 revives an hour from the food a staffed village has to spare.
Model.EGGS_PER_PAIR_HOUR = 9 * 0.8
Model.REVIVES_PER_HOUR = 10
-- Assumed until a play test measures it: village level -> the average level of the strongest slimes.
Model.SLIME_LEVEL = { { 1, 4 }, { 10, 8 }, { 20, 12 }, { 30, 20 }, { 40, 30 }, { 50, 40 } }
-- Selling every baby the moment it hatches, plain parents: coins an hour by village level, from income_sim.luau (4 h runs;
-- it swings with the odd Dual or Secret, level 50 most).
Model.SLIME_SALES = { { 1, 3500 }, { 10, 9400 }, { 20, 9900 }, { 30, 11400 }, { 40, 10000 }, { 50, 14000 } }

function Model.lerp(points: { { number } }, at: number): number
	for index = 2, #points do
		local low, high = points[index - 1], points[index]
		if at <= high[1] then
			return low[2] + (high[2] - low[2]) * (at - low[1]) / (high[1] - low[1])
		end
	end
	return points[#points][2]
end

-- Squads a village can spare beside its workers, from its population limit.
function Model.squads(level: number): number
	return if level >= 20 then 4 elseif level >= 15 then 3 elseif level >= 6 then 2 else 1
end

-- The best the player can do at this level: as many fights as the squads have time for and the village can lose slimes
-- to, in whichever camp pays most. With repeat on, a team is out all the time; heal is how long it waits for its wounds.
function Model.fightIncome(level: number): number
	local pairs = if level >= 41 then 4 elseif level >= 21 then 3 else 2
	local replaced = pairs * Model.EGGS_PER_PAIR_HOUR + Model.REVIVES_PER_HOUR
	local slimeLevel = Model.lerp(Model.SLIME_LEVEL, level)
	local best = 0
	for _, camp in Model.CAMPS do
		local inTime = Model.squads(level) * 3600 / (camp.fight + 2 * camp.march + camp.heal)
		local fights = math.min(inTime, replaced / camp.deaths)
		best = math.max(best, fights * Model.lerp(camp.coins, slimeLevel))
	end
	return best
end

function Model.slimeIncome(level: number): number
	return Model.lerp(Model.SLIME_SALES, level)
end

return Model
