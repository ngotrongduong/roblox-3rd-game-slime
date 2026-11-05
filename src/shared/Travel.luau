--!strict
-- Quick travel (the HUD's Home and Market buttons, docs/UI.md): where a character lands and how often it may go. Plain
-- rules; the server (QuickTravel) moves the character and the client only asks.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Layout = if script then require(script.Parent.Layout) else require("./Layout")

local Travel = {}

Travel.Places = { "Market", "Home", "Arena" }

function Travel.isPlace(place: any): boolean
	return type(place) == "string" and table.find(Travel.Places, place) ~= nil
end

-- Seconds before the player may travel again (0: now). `lastAt` is the server time of their last move, nil for none yet.
function Travel.cooldownLeft(lastAt: number?, now: number): number
	if lastAt == nil then
		return 0
	end
	return math.max(0, lastAt + Config.Travel.CooldownSeconds - now)
end

-- Where `place` puts a character. For Home `plot` is the player's own plot (nil: they have none, so no landing).
function Travel.destination(place: string, plot: number?): (typeof(Layout.marketLanding(0))?, string?)
	local T = Config.Travel
	if place == "Market" then
		return Layout.marketLanding(T.LiftStuds), nil
	elseif place == "Home" then
		if plot == nil then
			return nil, "NO_PLOT"
		end
		return Layout.homeLanding(plot, T.LiftStuds, T.HomeInsideStuds), nil
	elseif place == "Arena" then
		return Layout.arenaLanding(T.LiftStuds), nil
	end
	return nil, "BAD_REQUEST"
end

return Travel
