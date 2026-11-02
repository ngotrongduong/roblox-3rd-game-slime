local Config = require("../../src/shared/Config")
local Vector3 = require("@lune/roblox").Vector3
local CFrame = require("@lune/roblox").CFrame

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

	-- Two frames are the same place and heading.
	local function sameFrame(a, b, msg: string)
		T.near((a.Position - b.Position).Magnitude, 0, 1e-3, msg .. " position")
		T.near(a.LookVector:Dot(b.LookVector), 1, 1e-6, msg .. " look")
		T.near(a.RightVector:Dot(b.RightVector), 1, 1e-6, msg .. " right")
		T.near(a.UpVector:Dot(b.UpVector), 1, 1e-6, msg .. " up")
	end

	T.test("the hand-built plot turned about the valley centre is every other plot, frame by frame", function()
		local template = Config.Plots.TemplatePlot
		for plot = 1, M.PlotCount do
			local turn = Layout.plotTurn(plot, template)
			sameFrame(turn * Layout.plotFrame(template), Layout.plotFrame(plot), "plot " .. plot .. " frame")
			sameFrame(turn * Layout.plotGate(template), Layout.plotGate(plot), "plot " .. plot .. " gate")
			for col = -1, 1 do
				for row = -1, 1 do
					sameFrame(
						turn * Layout.plotAreaFrame(template, col, row),
						Layout.plotAreaFrame(plot, col, row),
						"plot " .. plot .. " area " .. col .. "," .. row
					)
					sameFrame(
						turn * Layout.plotAreaFacing(template, col, row),
						Layout.plotAreaFacing(plot, col, row),
						"plot " .. plot .. " facing " .. col .. "," .. row
					)
				end
			end
		end
		sameFrame(Layout.plotTurn(template, template), CFrame.new(), "no turn")
		T.throws(function()
			Layout.plotTurn(0, template)
		end)
		T.throws(function()
			Layout.plotTurn(M.PlotCount + 1, template)
		end)
	end)

	T.test("every slice, the Market's too, has a gate facing the centre on the plot-side edge", function()
		for slice = 0, M.PlotCount do
			local gate = Layout.sliceGate(slice)
			T.near(gate.Position.Magnitude, M.RimRadius - M.PlotSize / 2, 1e-3, "slice " .. slice)
			T.near(gate.LookVector:Dot(-gate.Position.Unit), 1, 1e-4, "slice " .. slice)
		end
		sameFrame(Layout.sliceGate(3), Layout.plotGate(3), "a plot's gate is its slice's")
		T.throws(function()
			Layout.sliceGate(M.PlotCount + 1)
		end)
	end)

	T.test(
		"the groups of every slice stand in front of its own gate, inside the Wild Garden, apart from all others",
		function()
			local Zombies = require("../../src/shared/Zombies")
			local Z = Config.Zombies
			local all = {}
			for slice = 0, M.PlotCount do
				local gate = Layout.sliceGate(slice)
				for camp = 1, #Z.LevelOffsets do
					for index = 1, #Z.Homes[camp] do
						local across, forward = Zombies.homeOffset(slice, camp, index)
						local at = (gate * CFrame.new(across, 0, -forward)).Position
						-- (the slice is 40 degrees wide: 360 / 9 places on the rim)
						local angle = math.deg(math.atan2(at.X, -at.Z))
						local off = math.abs((angle - Layout.slotAngle(slice) + 180) % 360 - 180)
						T.ok(
							off < 360 / (M.PlotCount + 1) / 2,
							"slice " .. slice .. " camp " .. camp .. " group " .. index
						)
						T.ok(at.Magnitude < M.WildRadius and at.Magnitude > M.HeartRadius, "inside the Wild Garden")
						table.insert(all, at)
					end
				end
			end
			for i = 1, #all do
				for j = i + 1, #all do
					-- (a group roams 12 studs round its home: two must not mix)
					T.ok((all[i] - all[j]).Magnitude > 30, "two groups too close")
				end
			end
			T.eq(#all, (M.PlotCount + 1) * (4 + 3 + 2), "4, 3 and 2 groups in the three rings")
		end
	)

	T.test("quarters: north-east is the meadow, nothing outside the Wild Garden", function()
		T.eq(Layout.quarterAt(Layout.polar(45, 150)).id, "meadow")
		T.eq(Layout.quarterAt(Layout.polar(135, 150)).id, "mushroom")
		T.eq(Layout.quarterAt(Layout.polar(225, 150)).id, "ember")
		T.eq(Layout.quarterAt(Layout.polar(315, 150)).id, "frost")
		T.eq(Layout.quarterAt(Layout.polar(45, M.WildRadius + 5)), nil)
		T.eq(Layout.quarterAt(Layout.polar(45, 5)), nil)
	end)

	T.test("monster depth grows toward the Heart", function()
		T.near(Layout.depthAt(Layout.polar(10, M.WildRadius)), 0, 1e-6)
		T.near(Layout.depthAt(Layout.polar(10, M.HeartRadius)), 1, 1e-6)
	end)
end
