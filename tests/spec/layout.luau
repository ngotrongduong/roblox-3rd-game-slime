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

	-- The open gap between two footprints (rectangles given by centre, yaw frame and half sizes) along the line
	-- joining their centres: positive when they are apart (a separating axis).
	local function gapAlongCentres(fa, ha: { number }, fb, hb: { number }): number
		local d = (fb.Position - fa.Position) * Vector3.new(1, 0, 1)
		local axis = d.Unit
		local function extent(f, h)
			return h[1] * math.abs(f.RightVector:Dot(axis)) + h[2] * math.abs(f.LookVector:Dot(axis))
		end
		return d.Magnitude - extent(fa, ha) - extent(fb, hb)
	end

	T.test("the village scale: every rim neighbour keeps an open lane", function()
		local plotHalf = { M.PlotSize / 2, M.PlotSize / 2 }
		local marketHalf = { M.MarketWidth / 2, M.MarketDepth / 2 }
		for slot = 1, M.PlotCount do
			local nextSlot = slot % (M.PlotCount + 1) + 1
			local nextHalf = if nextSlot == M.PlotCount + 1 then marketHalf else plotHalf
			local nextFrame = if nextSlot == M.PlotCount + 1 then Layout.slotFrame(0) else Layout.slotFrame(nextSlot)
			local gap = gapAlongCentres(Layout.slotFrame(slot), plotHalf, nextFrame, nextHalf)
			T.ok(gap >= M.PlotLane, "slot " .. slot .. " lane " .. gap)
		end
		T.ok(gapAlongCentres(Layout.slotFrame(0), marketHalf, Layout.slotFrame(1), plotHalf) >= M.PlotLane, "market")
		local market = M.RimRadius + M.MarketDepth / 2
		T.ok(math.sqrt(market * market + (M.MarketWidth / 2) ^ 2) < M.FloorRadius, "market corners on the floor")
	end)

	T.test("the village scale: about twice the old area, paths sized to the slime", function()
		T.ok(M.PlotSize * M.PlotSize >= 2 * 160 * 160, "plot area doubled")
		T.near(Layout.cellSize() * 3, M.PlotSize, 1e-9)
		T.ok(M.PlazaRadius > M.MainPathWidth and M.PlazaRadius * 2 < Layout.cellSize(), "the plaza fits its cell")
		T.ok(M.MainPathWidth >= M.PathWidth and M.RingRoadWidth >= M.MainPathWidth)
		T.ok(M.WorkFront >= 2 * M.SlimeWidth and M.PropGap >= 2 * M.SlimeWidth, "two slimes pass")
		T.ok(M.HeartRadius < M.DuelRingDistance - M.DuelRingRadius, "duel rings clear of the Heart")
		T.ok(M.DuelRingDistance + M.DuelRingRadius < M.WildRadius, "duel rings in the Wild Garden")
		T.ok(M.HillOuterRadius > M.FloorRadius)
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
