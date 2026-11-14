local Config = require("../../src/shared/Config")
local WorldPlan = require("../../src/shared/WorldPlan")
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
	local FLAT = Vector3.new(1, 0, 1)
	local hubX, hubZ = WorldPlan.world(WorldPlan.Hub.x, WorldPlan.Hub.z)
	local hub = Vector3.new(hubX, 0, hubZ)

	T.test("the Market stands on the hub with its way in to the north", function()
		local market = Layout.marketFrame()
		T.ok((market.Position - hub).Magnitude < WorldPlan.Hub.radius / 2, "on the hub")
		T.near(market.LookVector:Dot(Vector3.new(0, 0, -1)), 1, 1e-6, "the front is north")
	end)

	T.test("plot n is village n of the plan, its gate side towards the hub", function()
		T.eq(#WorldPlan.Villages, M.PlotCount)
		for plot = 1, M.PlotCount do
			local village = WorldPlan.Villages[plot]
			local frame = Layout.plotFrame(plot)
			local x, z = WorldPlan.world(village.x, village.z)
			T.near((frame.Position - Vector3.new(x, 0, z)).Magnitude, 0, 1e-3, "plot " .. plot)
			T.near(
				frame.LookVector:Dot(((hub - frame.Position) * FLAT).Unit),
				1,
				1e-4,
				"plot " .. plot .. " faces the hub"
			)
			-- the whole square lies on the flat pad
			T.ok(M.PlotSize / 2 * math.sqrt(2) < WorldPlan.Village.PadRadius, "plot corners on the pad")
		end
	end)

	-- The open gap between two footprints (rectangles given by centre, yaw frame and half sizes) along the line
	-- joining their centres: positive when they are apart (a separating axis).
	local function gapAlongCentres(fa, ha: { number }, fb, hb: { number }): number
		local d = (fb.Position - fa.Position) * FLAT
		local axis = d.Unit
		local function extent(f, h)
			return h[1] * math.abs(f.RightVector:Dot(axis)) + h[2] * math.abs(f.LookVector:Dot(axis))
		end
		return d.Magnitude - extent(fa, ha) - extent(fb, hb)
	end

	T.test("the village scale: every plot and the Market keep an open lane from all the others", function()
		local plotHalf = { M.PlotSize / 2, M.PlotSize / 2 }
		local marketHalf = { M.MarketWidth / 2, M.MarketDepth / 2 }
		for a = 0, M.PlotCount do
			for b = a + 1, M.PlotCount do
				local gap = gapAlongCentres(
					Layout.slotFrame(a),
					if a == 0 then marketHalf else plotHalf,
					Layout.slotFrame(b),
					plotHalf
				)
				T.ok(gap >= M.PlotLane, "slots " .. a .. " and " .. b .. " lane " .. gap)
			end
		end
	end)

	T.test("the village scale: about twice the old area, paths sized to the slime", function()
		T.ok(M.PlotSize * M.PlotSize >= 2 * 160 * 160, "plot area doubled")
		T.near(Layout.cellSize() * 3, M.PlotSize, 1e-9)
		T.ok(M.PlazaRadius > M.MainPathWidth and M.PlazaRadius * 2 < Layout.cellSize(), "the plaza fits its cell")
		T.ok(M.MainPathWidth >= M.PathWidth)
		T.ok(M.WorkFront >= 2 * M.SlimeWidth and M.PropGap >= 2 * M.SlimeWidth, "two slimes pass")
	end)

	T.test("the gate is on the plot side nearest the hub, the back row farthest from it", function()
		for plot = 1, M.PlotCount do
			local centre = Layout.plotFrame(plot).Position
			local gate = Layout.plotGate(plot).Position
			T.near((gate - centre).Magnitude, M.PlotSize / 2, 1e-3)
			T.near((centre - hub).Magnitude - (gate - hub).Magnitude, M.PlotSize / 2, 1e-3, "plot " .. plot)
			local back = (Layout.plotAreaFrame(plot, 0, 1).Position - hub).Magnitude
			local front = (Layout.plotAreaFrame(plot, 0, -1).Position - hub).Magnitude
			T.ok(back > front)
		end
	end)

	T.test("every area faces the plot's middle, corners diagonally", function()
		local centre = Layout.plotFrame(4).Position
		for col = -1, 1 do
			for row = -1, 1 do
				local f = Layout.plotAreaFacing(4, col, row)
				T.near((f.Position - Layout.plotAreaFrame(4, col, row).Position).Magnitude, 0, 1e-4)
				if col ~= 0 or row ~= 0 then
					local d = (centre - f.Position) * FLAT
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
		-- (single-precision frames some 6,000 studs from the origin)
		T.near((a.Position - b.Position).Magnitude, 0, 1e-2, msg .. " position")
		T.near(a.LookVector:Dot(b.LookVector), 1, 1e-6, msg .. " look")
		T.near(a.RightVector:Dot(b.RightVector), 1, 1e-6, msg .. " right")
		T.near(a.UpVector:Dot(b.UpVector), 1, 1e-6, msg .. " up")
	end

	T.test("the hand-built plot moved by plotTurn is every other plot, frame by frame", function()
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

	T.test("every slice, the Market's too, has a gate on its front edge, facing out", function()
		for slice = 0, M.PlotCount do
			local frame = Layout.slotFrame(slice)
			local gate = Layout.sliceGate(slice)
			T.near((gate.Position - frame.Position).Magnitude, M.PlotSize / 2, 1e-3, "slice " .. slice)
			T.near(gate.LookVector:Dot(((gate.Position - frame.Position) * FLAT).Unit), 1, 1e-4, "slice " .. slice)
		end
		sameFrame(Layout.sliceGate(3), Layout.plotGate(3), "a plot's gate is its slice's")
		T.throws(function()
			Layout.sliceGate(M.PlotCount + 1)
		end)
	end)

	-- The flat distance from a plan point to the river's middle line.
	local function toRiver(x: number, z: number): number
		local best = math.huge
		local points = WorldPlan.River.points
		for i = 1, #points - 1 do
			local ax, az, bx, bz = points[i][1], points[i][2], points[i + 1][1], points[i + 1][2]
			local dx, dz = bx - ax, bz - az
			local t = math.clamp(((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz), 0, 1)
			best = math.min(best, math.sqrt((x - ax - dx * t) ^ 2 + (z - az - dz * t) ^ 2))
		end
		return best
	end

	T.test("the groups of every slice stand on free land in front of its own gate, apart from all others", function()
		local Zombies = require("../../src/shared/Zombies")
		local Z = Config.Zombies
		local all = {}
		for slice = 0, M.PlotCount do
			local gate = Layout.campFrame(slice)
			for camp = 1, #Z.LevelOffsets do
				for index = 1, #Z.Homes[camp] do
					local across, forward = Zombies.homeOffset(slice, camp, index)
					local at = (gate * CFrame.new(across, 0, -forward)).Position
					local name = "slice " .. slice .. " camp " .. camp .. " group " .. index
					T.ok(forward > 0, name .. " in front of the gate")
					-- (a group roams 12 studs round its home)
					local x, z = at.X - WorldPlan.Origin.x, at.Z - WorldPlan.Origin.z
					T.ok(toRiver(x, z) > WorldPlan.River.Width / 2 + 20, name .. " clear of the river")
					for other = 0, M.PlotCount do
						local reach = if other == 0 then WorldPlan.Hub.radius else M.PlotSize / 2 * math.sqrt(2)
						local away = ((at - Layout.slotFrame(other).Position) * FLAT).Magnitude
						T.ok(away > reach + 12, name .. " clear of slot " .. other)
					end
					table.insert(all, { at = at, name = name })
				end
			end
		end
		for i = 1, #all do
			for j = i + 1, #all do
				local apart = (all[i].at - all[j].at).Magnitude
				T.ok(apart > 30, all[i].name .. " and " .. all[j].name .. " are " .. apart .. " apart")
			end
		end
		T.eq(#all, (M.PlotCount + 1) * (4 + 3 + 2), "4, 3 and 2 groups in the three rings")
	end)
end
