local Config = require("../../src/shared/Config")
local DayClock = require("../../src/shared/DayClock")

return function(T)
	local D = Config.World.DayNight
	local day, night = D.DayMinutes * 60, D.NightMinutes * 60

	T.test(
		"the clock: 06:00 at the start of a cycle, 18:00 when the day is over, midnight halfway through the night",
		function()
			T.near(DayClock.hour(0), 6, 1e-9)
			T.near(DayClock.hour(day / 2), 12, 1e-9)
			T.near(DayClock.hour(day), 18, 1e-9)
			T.near(DayClock.hour(day + night / 2), 0, 1e-9)
			T.near(DayClock.hour(day + night * 0.75), 3, 1e-9)
			T.near(DayClock.hour(day + night + 1), DayClock.hour(1), 1e-9, "the next cycle repeats the first")
		end
	)

	T.test("night: none by day, full in the dead of night, between at dusk and dawn", function()
		T.eq(DayClock.night(12), 0)
		T.eq(DayClock.night(D.DuskFrom), 0)
		T.eq(DayClock.night(22), 1)
		T.eq(DayClock.night(0), 1)
		T.eq(DayClock.night(3), 1)
		T.eq(DayClock.night(D.DawnTo), 0)
		local dusk = DayClock.night((D.DuskFrom + D.DuskTo) / 2)
		local dawn = DayClock.night((D.DawnFrom + D.DawnTo) / 2)
		T.ok(dusk > 0.4 and dusk < 0.6, "half dark halfway through dusk: " .. dusk)
		T.ok(dawn > 0.4 and dawn < 0.6, "half dark halfway through dawn: " .. dawn)
	end)
end
