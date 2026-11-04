--!strict
local Season = require("../../src/shared/ArenaSeason")
local Config = require("../../src/shared/Config")

return function(T)
	T.test("December rolls over to January at the known UTC epoch", function()
		T.eq(Season.seasonStart(202401), 1704067200)
		T.eq(Season.seasonEnd(202312), 1704067200)
		T.eq(Season.seasonOf(1704067199), 202312)
		T.eq(Season.seasonOf(1704067200), 202401)
		T.eq(Season.previous(202401), 202312)
		T.eq(Season.nextOf(202312), 202401)
		T.eq(Season.nextOf(202411), 202412)
		T.eq(Season.previous(202411), 202410)
	end)
	T.test("February handles leap years and Gregorian centuries", function()
		T.eq(Season.seasonStart(202402), 1706745600)
		T.eq(Season.seasonEnd(202402), 1709251200)
		T.eq(Season.seasonOf(1709251199), 202402)
		T.eq(Season.seasonOf(1709251200), 202403)
		for _, year in { 1900, 2000, 2023, 2024, 2100 } do
			local days = if year == 2000 or year == 2024 then 29 else 28
			T.eq(Season.seasonEnd(year * 100 + 2) - Season.seasonStart(year * 100 + 2), days * 86400)
		end
	end)
	T.test("calendar conversion roundtrips all months across century boundaries", function()
		for year = 1899, 2101 do
			for month = 1, 12 do
				local season = year * 100 + month
				T.eq(Season.seasonOf(Season.seasonStart(season)), season)
				T.eq(Season.seasonOf(Season.seasonEnd(season) - 1), season)
			end
		end
	end)
	T.test("lock is exactly the last five minutes and finalization follows the season", function()
		local ending = Season.seasonEnd(202611)
		T.eq(Season.locked(ending - 301), false)
		T.eq(Season.locked(ending - 300), true)
		T.eq(Season.locked(ending - 1), true)
		T.eq(Season.locked(ending), false)
		T.eq(Season.finalAt(202611), ending + Config.Arena.FinalizeSeconds)
	end)
	T.test("UTC days and Monday weeks change at midnight", function()
		local monday = 1704067200
		T.eq(Season.dayOf(0), 0)
		T.eq(Season.dayOf(-1), -1)
		T.eq(Season.seasonOf(-1), 196912)
		T.eq(Season.weekOf(monday) - Season.weekOf(monday - 1), 1)
		T.eq(Season.weekOf(monday + 7 * 86400 - 1), Season.weekOf(monday))
		T.eq(Season.weekOf(monday + 7 * 86400), Season.weekOf(monday) + 1)
		T.eq(Season.dayOf(monday) - Season.dayOf(monday - 1), 1)
	end)
	T.test("win points distinguish losses, climbing, stale wins and below wins", function()
		local c = Config.Arena
		T.eq(Season.winPoints(false, 1000, true), c.LossPoints)
		T.eq(Season.winPoints(true, 0, true), c.WinPoints)
		T.eq(Season.winPoints(true, 7, true), c.WinPoints + 7 * c.ClimbBonusPerStep)
		T.eq(Season.winPoints(true, 1000, true), c.WinPoints + c.ClimbBonusCap)
		T.eq(Season.winPoints(true, 1000, false), math.floor(c.WinPoints * c.BelowShare))
	end)
	T.test("season rewards include every boundary and participation", function()
		local previous = 0
		for _, reward in Config.Arena.SeasonRewards do
			local points, badge = Season.rewardFor(previous + 1)
			T.eq(points, reward.points)
			T.eq(badge, reward.badge)
			if reward.upTo ~= math.huge then
				T.eq(Season.rewardFor(reward.upTo), reward.points)
			end
			previous = reward.upTo
		end
		local points, badge = Season.rewardFor(nil)
		T.eq(points, 0)
		T.eq(badge, nil)
	end)
end
