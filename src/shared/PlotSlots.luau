--!strict
-- Who holds which home plot of a server (docs/MAP.md section 3: 8 players, a plot each). A plot is never saved: a farm works
-- in any plot, so the hand-out is only this table, `owners[plot] = userId`, rebuilt as players come and go.
local Config = if script then require(script.Parent.Config) else require("./Config")

local PlotSlots = {}

-- The plot this user holds, nil when none.
function PlotSlots.plotOf(owners: { [number]: number }, userId: number): number?
	for plot = 1, Config.Map.PlotCount do
		if owners[plot] == userId then
			return plot
		end
	end
	return nil
end

-- The lowest plot nobody holds, nil when all are taken.
function PlotSlots.firstFree(owners: { [number]: number }): number?
	for plot = 1, Config.Map.PlotCount do
		if owners[plot] == nil then
			return plot
		end
	end
	return nil
end

-- Gives the user a plot: the one already held, else the first free. Returns it, nil when the server is full.
function PlotSlots.assign(owners: { [number]: number }, userId: number): number?
	local held = PlotSlots.plotOf(owners, userId)
	if held then
		return held
	end
	local plot = PlotSlots.firstFree(owners)
	if plot then
		owners[plot] = userId
	end
	return plot
end

-- Frees the user's plot. Returns the plot it was, nil when the user held none.
function PlotSlots.release(owners: { [number]: number }, userId: number): number?
	local plot = PlotSlots.plotOf(owners, userId)
	if plot then
		owners[plot] = nil
	end
	return plot
end

return PlotSlots
