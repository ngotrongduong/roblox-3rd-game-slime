--!strict
local Config = require("../../src/shared/Config")
local PlotSlots = require("../../src/shared/PlotSlots")

return function(T: any)
	T.test("a new player gets the first free plot, in order", function()
		local owners: { [number]: number } = {}
		for index = 1, Config.Map.PlotCount do
			T.eq(PlotSlots.assign(owners, 1000 + index), index)
		end
	end)
	T.test("the same player keeps the plot they hold", function()
		local owners: { [number]: number } = {}
		T.eq(PlotSlots.assign(owners, 7), 1)
		T.eq(PlotSlots.assign(owners, 8), 2)
		T.eq(PlotSlots.assign(owners, 7), 1)
		T.eq(PlotSlots.plotOf(owners, 8), 2)
		T.eq(PlotSlots.plotOf(owners, 9), nil)
	end)
	T.test("a plot freed by a player who left goes to the next one, the lowest first", function()
		local owners: { [number]: number } = {}
		for index = 1, 5 do
			PlotSlots.assign(owners, index)
		end
		T.eq(PlotSlots.release(owners, 2), 2)
		T.eq(PlotSlots.release(owners, 4), 4)
		T.eq(PlotSlots.release(owners, 4), nil, "freed once")
		T.eq(PlotSlots.assign(owners, 50), 2)
		T.eq(PlotSlots.assign(owners, 51), 4)
		T.eq(PlotSlots.assign(owners, 52), 6)
		T.eq(owners[1], 1, "the others keep theirs")
	end)
	T.test("a ninth player gets no plot and takes none from the eight", function()
		local owners: { [number]: number } = {}
		for index = 1, Config.Map.PlotCount do
			PlotSlots.assign(owners, index)
		end
		T.eq(PlotSlots.assign(owners, 99), nil)
		T.eq(PlotSlots.firstFree(owners), nil)
		for index = 1, Config.Map.PlotCount do
			T.eq(owners[index], index)
		end
	end)
	T.test("a plot is not part of a save: any plot serves any farm", function()
		local FarmState = require("../../src/shared/FarmState")
		local farm = FarmState.newFarm(1000)
		for key in farm :: any do
			T.ok(string.lower(tostring(key)) ~= "plot", "no plot in the save")
		end
	end)
end
