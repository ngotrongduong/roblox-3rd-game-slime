--!strict
-- The world's clock (Config.World.DayNight): the hour from the server's time, so every player and every server sees the
-- same one, and how much night it is at an hour. client/DayNight draws it, client/WorldLights lights the lamps by it.
local Config = if script then require(script.Parent.Config) else require("./Config")

local DayClock = {}

-- The hour (0 up to 24) at server time `now` (seconds): 06:00 to 18:00 takes DayMinutes, 18:00 to 06:00 NightMinutes.
function DayClock.hour(now: number): number
	local D = Config.World.DayNight
	local day, night = D.DayMinutes * 60, D.NightMinutes * 60
	local t = now % (day + night)
	if t < day then
		return 6 + 12 * t / day
	end
	return (18 + 12 * (t - day) / night) % 24
end

local function smooth(from: number, to: number, x: number): number
	local k = math.clamp((x - from) / (to - from), 0, 1)
	return k * k * (3 - 2 * k)
end

-- How much night it is at `hour`: 0 by day, 1 at full night, eased through dusk and dawn.
function DayClock.night(hour: number): number
	local D = Config.World.DayNight
	if hour >= 12 then
		return smooth(D.DuskFrom, D.DuskTo, hour)
	end
	return 1 - smooth(D.DawnFrom, D.DawnTo, hour)
end

return DayClock
