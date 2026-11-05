--!strict
local Config = if script then require(script.Parent.Config) else require("./Config")

local ArenaSeason = {}
local SECONDS_PER_DAY = 86400

-- Gregorian eras keep all boundaries UTC, including leap centuries and dates before the epoch.
local function daysFromCivil(year: number, month: number, day: number): number
	year -= if month <= 2 then 1 else 0
	local era = math.floor(year / 400)
	local y = year - era * 400
	local m = month + (if month > 2 then -3 else 9)
	local doy = math.floor((153 * m + 2) / 5) + day - 1
	return era * 146097 + y * 365 + math.floor(y / 4) - math.floor(y / 100) + doy - 719468
end

function ArenaSeason.dayOf(now: number): number
	return math.floor(now / SECONDS_PER_DAY)
end

function ArenaSeason.weekOf(now: number): number
	-- Epoch day zero was Thursday, three days after the start of its Monday week.
	return math.floor((ArenaSeason.dayOf(now) + 3) / 7)
end

-- The second the given week ends (the next Monday 00:00 UTC).
function ArenaSeason.weekEnd(week: number): number
	return ((week + 1) * 7 - 3) * SECONDS_PER_DAY
end

function ArenaSeason.seasonOf(now: number): number
	local days = ArenaSeason.dayOf(now) + 719468
	local era = math.floor(days / 146097)
	local doe = days - era * 146097
	local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
	local year = yoe + era * 400
	local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
	local mp = math.floor((5 * doy + 2) / 153)
	local month = mp + (if mp < 10 then 3 else -9)
	year += if month <= 2 then 1 else 0
	return year * 100 + month
end

function ArenaSeason.seasonStart(season: number): number
	return daysFromCivil(math.floor(season / 100), season % 100, 1) * SECONDS_PER_DAY
end

function ArenaSeason.nextOf(season: number): number
	return if season % 100 == 12 then (math.floor(season / 100) + 1) * 100 + 1 else season + 1
end

function ArenaSeason.previous(season: number): number
	return if season % 100 == 1 then (math.floor(season / 100) - 1) * 100 + 12 else season - 1
end

function ArenaSeason.seasonEnd(season: number): number
	return ArenaSeason.seasonStart(ArenaSeason.nextOf(season))
end

function ArenaSeason.locked(now: number): boolean
	return now >= ArenaSeason.seasonEnd(ArenaSeason.seasonOf(now)) - Config.Arena.LockSeconds
end

function ArenaSeason.finalAt(season: number): number
	return ArenaSeason.seasonEnd(season) + Config.Arena.FinalizeSeconds
end

function ArenaSeason.winPoints(won: boolean, climbed: number, above: boolean): number
	local c = Config.Arena
	if not won then
		return c.LossPoints
	elseif not above then
		return math.floor(c.WinPoints * c.BelowShare)
	end
	return c.WinPoints + math.min(c.ClimbBonusCap, math.max(0, climbed) * c.ClimbBonusPerStep)
end

function ArenaSeason.rewardFor(rank: number?): (number, string?)
	if not rank or rank < 1 then
		return 0, nil
	end
	for _, reward in Config.Arena.SeasonRewards do
		if rank <= reward.upTo then
			return reward.points, reward.badge
		end
	end
	return 0, nil
end

return ArenaSeason
