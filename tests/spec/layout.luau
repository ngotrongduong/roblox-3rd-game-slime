local Config = require("../../src/shared/Config")
local Vector3 = require("@lune/roblox").Vector3

return function(T)
	local ok, Layout = pcall(require, "../../src/shared/Layout")
	T.test("Layout loads with the Roblox datatypes", function()
		T.ok(ok, tostring(Layout))
	end)
	if not ok then
		return
	end
	local M = Config.Map

	T.test("the Market is north and plot 1 follows clockwise", function()
		local market = Layout.marketFrame().Position
		T.near(market.X, 0, 1e-3)
		T.near(market.Z, -M.RimRadius, 1e-3)
		local p1 = Layout.plotFrame(1).Position
		T.ok(p1.X > 0 and p1.Z < 0, "plot 1 is north-east")
	end)

	T.test("every rim slot faces the valley centre", function()
		for slot = 0, M.PlotCount do
			local frame = Layout.slotFrame(slot)
			local toCentre = -frame.Position.Unit
			T.near(frame.LookVector:Dot(toCentre), 1, 1e-4, "slot " .. slot)
		end
	end)

	T.test("plots do not overlap their neighbours and stay on the floor", function()
		local spacing = (Layout.plotFrame(1).Position - Layout.plotFrame(2).Position).Magnitude
		T.ok(spacing > M.PlotSize * 1.2, "neighbours " .. spacing .. " apart")
		T.ok(M.RimRadius + M.PlotSize / 2 * math.sqrt(2) < M.FloorRadius, "plot corners on the floor")
		T.ok(M.RimRadius - M.PlotSize / 2 > M.RingRoadRadius + M.RingRoadWidth / 2, "gate beyond the road")
		T.ok(M.RingRoadRadius - M.RingRoadWidth / 2 > M.WildRadius, "road outside the Wild Garden")
	end)

	T.test("the gate is on the plot side nearest the centre", function()
		for plot = 1, M.PlotCount do
			local gate = Layout.plotGate(plot).Position.Magnitude
			T.near(gate, M.RimRadius - M.PlotSize / 2, 1e-3)
		end
	end)

	T.test("the back row of a plot is farther from the centre than the front row", function()
		local back = Layout.plotAreaFrame(3, 0, 1).Position.Magnitude
		local front = Layout.plotAreaFrame(3, 0, -1).Position.Magnitude
		T.ok(back > front)
	end)

	T.test("every area faces the plot's middle, corners diagonally", function()
		local centre = Layout.plotFrame(4).Position
		for col = -1, 1 do
			for row = -1, 1 do
				local f = Layout.plotAreaFacing(4, col, row)
				T.near((f.Position - Layout.plotAreaFrame(4, col, row).Position).Magnitude, 0, 1e-4)
				if col ~= 0 or row ~= 0 then
					local d = (centre - f.Position) * Vector3.new(1, 0, 1)
					T.near(f.LookVector:Dot(d.Unit), 1, 1e-4, col .. "," .. row)
				end
			end
		end
		local corner = Layout.plotAreaFacing(4, 1, 1).LookVector
		local side = Layout.plotAreaFacing(4, 1, 0).LookVector
		T.near(math.deg(math.acos(math.clamp(corner:Dot(side), -1, 1))), 45, 1e-3)
	end)

	T.test("quarters: north-east is the meadow, nothing outside the Wild Garden", function()
		T.eq(Layout.quarterAt(Layout.polar(45, 150)).id, "meadow")
		T.eq(Layout.quarterAt(Layout.polar(135, 150)).id, "ember")
		T.eq(Layout.quarterAt(Layout.polar(225, 150)).id, "frost")
		T.eq(Layout.quarterAt(Layout.polar(315, 150)).id, "mushroom")
		T.eq(Layout.quarterAt(Layout.polar(45, M.WildRadius + 5)), nil)
		T.eq(Layout.quarterAt(Layout.polar(45, 5)), nil)
	end)

	T.test("monster depth grows toward the Heart", function()
		T.near(Layout.depthAt(Layout.polar(10, M.WildRadius)), 0, 1e-6)
		T.near(Layout.depthAt(Layout.polar(10, M.HeartRadius)), 1, 1e-6)
	end)
end
