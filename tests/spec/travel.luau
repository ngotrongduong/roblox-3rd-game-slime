local Config = require("../../src/shared/Config")
local Vector3 = require("@lune/roblox").Vector3

return function(T)
	local okLayout, Layout = pcall(require, "../../src/shared/Layout")
	local okTravel, Travel = pcall(require, "../../src/shared/Travel")
	T.test("Layout and Travel load with the Roblox datatypes", function()
		T.ok(okLayout, tostring(Layout))
		T.ok(okTravel, tostring(Travel))
	end)
	if not (okLayout and okTravel) then
		return
	end
	local M = Config.Map
	local K = Config.Market
	local cooldown = Config.Travel.CooldownSeconds

	T.test("the cooldown: free at first, closed for the cooldown after a move, free again after it", function()
		T.eq(Travel.cooldownLeft(nil, 100), 0)
		T.near(Travel.cooldownLeft(100, 100), cooldown, 1e-9)
		T.near(Travel.cooldownLeft(100, 101), cooldown - 1, 1e-9)
		T.eq(Travel.cooldownLeft(100, 100 + cooldown), 0)
		T.eq(Travel.cooldownLeft(100, 100 + cooldown + 50), 0)
		T.eq(cooldown, 3, "the owner's brief: three seconds")
	end)

	T.test("only Market and Home are places", function()
		T.ok(Travel.isPlace("Market"))
		T.ok(Travel.isPlace("Home"))
		T.ok(not Travel.isPlace("Arena"))
		T.ok(not Travel.isPlace("market"))
		T.ok(not Travel.isPlace("Wild Garden"))
		T.ok(not Travel.isPlace(nil))
		T.ok(not Travel.isPlace(5))
		T.ok(not Travel.isPlace({}))
	end)

	T.test("the Market spots are inside the square, buyer and VIP either side, the board at the back", function()
		local halfWidth, halfDepth = M.MarketWidth / 2, M.MarketDepth / 2
		for name, spot in { Landing = K.Landing, Buyer = K.Buyer, Vip = K.Vip, Board = K.Board } do
			T.ok(math.abs(spot.x) <= halfWidth - 10, name .. " is inside the square's width")
			T.ok(math.abs(spot.z) <= halfDepth - 10, name .. " is inside the square's depth")
		end
		T.ok(K.Buyer.x * K.Vip.x < 0, "either side")
		T.near(K.Board.x, 0, 1e-9, "the middle")
		T.ok(K.Board.z > 0 and K.Landing.z < 0, "the board at the back, the landing at the front")
		-- clear of each other: a prompt reaches 40 studs, the stalls must not share one
		T.ok(
			(Vector3.new(K.Buyer.x, 0, K.Buyer.z) - Vector3.new(K.Vip.x, 0, K.Vip.z)).Magnitude
				> 2 * Config.Zombies.ShopRangeStuds
		)
	end)

	T.test("the Market frame: the front is north (the King's Road), the back south", function()
		local middle = Layout.marketFrame().Position
		local landing = Layout.marketPoint(K.Landing)
		local board = Layout.marketPoint(K.Board)
		T.ok(landing.Z < middle.Z and board.Z > middle.Z, "the landing north of the middle, the board south of it")
		T.near(landing.Y, M.GroundY, 1e-9, "on the ground")
		-- the buyer (+x) is on the left of someone walking in from the north (facing south)
		T.ok(Layout.marketPoint(K.Buyer).X > middle.X, "+x is world east, a visitor's left when they face south")
	end)

	T.test("the Market landing stands at the landing spot, lifted, facing the board", function()
		local lift = Config.Travel.LiftStuds
		local landing = Layout.marketLanding(lift)
		local spot = Layout.marketPoint(K.Landing)
		T.near(landing.Position.X, spot.X, 1e-3)
		T.near(landing.Position.Z, spot.Z, 1e-3)
		T.near(landing.Position.Y, M.GroundY + lift, 1e-3)
		local toBoard = (Layout.marketPoint(K.Board) - spot) * Vector3.new(1, 0, 1)
		T.near(landing.LookVector:Dot(toBoard.Unit), 1, 1e-4, "facing the board")
		T.ok(lift > 0 and lift < 8, "a little above the ground")
	end)

	T.test("home lands just inside the player's own gate, facing in, in every plot", function()
		local T3 = Config.Travel
		for plot = 1, M.PlotCount do
			local landing = Layout.homeLanding(plot, T3.LiftStuds, T3.HomeInsideStuds)
			local gate = Layout.plotGate(plot)
			local flat = (landing.Position - gate.Position) * Vector3.new(1, 0, 1)
			T.near(flat.Magnitude, T3.HomeInsideStuds, 1e-3, "plot " .. plot .. " distance from the gate")
			-- in the gate's opening (on its middle line)
			T.near(math.abs(gate.RightVector:Dot(flat)), 0, 1e-3, "plot " .. plot .. " on the middle line")
			-- inside the plot: nearer its middle than the gate, and within its square
			local toMiddle = (Layout.plotFrame(plot).Position - landing.Position) * Vector3.new(1, 0, 1)
			T.ok(toMiddle.Magnitude < M.PlotSize / 2, "plot " .. plot .. " is inside")
			T.ok(T3.HomeInsideStuds < M.PlotSize / 2)
			-- facing in, at the plot's middle
			T.ok(landing.LookVector:Dot(toMiddle.Unit) > 0.99, "plot " .. plot .. " faces in")
			T.near(landing.Position.Y, M.GroundY + T3.LiftStuds, 1e-3)
		end
	end)

	T.test("destinations: the Market always, Home only with a plot, nothing for anything else", function()
		local market, why = Travel.destination("Market", nil)
		T.ok(market ~= nil and why == nil)
		local home, whyHome = Travel.destination("Home", nil)
		T.eq(home, nil)
		T.eq(whyHome, "NO_PLOT")
		local own = Travel.destination("Home", 3)
		T.near((own.Position - Layout.plotGate(3).Position).Magnitude, Config.Travel.HomeInsideStuds, 1.5)
		-- the Arena is a scene drawn on the client, not a place to travel to
		local arena, whyArena = Travel.destination("Arena", nil)
		T.eq(arena, nil)
		T.eq(whyArena, "BAD_REQUEST")
		local nothing, whyElse = Travel.destination("Moon", 3)
		T.eq(nothing, nil)
		T.eq(whyElse, "BAD_REQUEST")
	end)

	T.test("the travel icons have their pictures", function()
		T.ok(Config.Ui.Icons.home > 0)
		T.ok(Config.Ui.Icons.market > 0)
	end)
end
