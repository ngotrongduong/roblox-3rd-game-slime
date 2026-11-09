-- The Slime Dungeon's arena and its requests: where the arenas stand, where a monster comes in, where a leaving player is
-- put, the shape of the four requests, and the ghost rule for a slime that falls in the arena.
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local FarmKit = require("../lib/FarmKit")
local Layout = require("../../src/shared/Layout")
local Rng = require("../../src/shared/Rng")
local Vector3 = require("@lune/roblox").Vector3
local VillageRequests = require("../../src/shared/VillageRequests")
local Zombies = require("../../src/shared/Zombies")

local D = Config.Dungeon
local M = Config.Map
local NOW = 1_000_000

return function(T: any)
	T.test("a monster comes in on the edge band, and apart from the ones that stand", function()
		for seed = 1, 200 do
			local rng = Rng.new(seed)
			local taken: { { x: number, z: number } } = {}
			for count = 1, D.MaxAlive do
				local x, z = Dungeon.spawnPoint(rng, taken)
				local radius = math.sqrt(x * x + z * z)
				T.ok(radius >= D.SpawnMinFromCentre - 1e-6, "far enough from the middle, seed " .. seed)
				T.ok(radius <= D.ArenaRadius - D.SpawnInset + 1e-6, "inside the rim, seed " .. seed)
				for _, other in taken do
					local gap = math.sqrt((other.x - x) ^ 2 + (other.z - z) ^ 2)
					T.ok(gap >= D.SpawnMinApart, "apart (" .. gap .. "), seed " .. seed .. ", monster " .. count)
				end
				table.insert(taken, { x = x, z = z })
			end
		end
	end)

	T.test("a crowded band still gives a point on it, the farthest from the others", function()
		local rng = Rng.new(5)
		local taken: { { x: number, z: number } } = {}
		-- far more monsters than the band can hold apart
		for _ = 1, 60 do
			local x, z = Dungeon.spawnPoint(rng, taken)
			local radius = math.sqrt(x * x + z * z)
			T.ok(radius >= D.SpawnMinFromCentre - 1e-6 and radius <= D.ArenaRadius - D.SpawnInset + 1e-6)
			table.insert(taken, { x = x, z = z })
		end
	end)

	T.test("the same seed brings the monsters in at the same points", function()
		local function walk(seed: number): { number }
			local rng = Rng.new(seed)
			local taken: { { x: number, z: number } } = {}
			local out: { number } = {}
			for _ = 1, 6 do
				local x, z = Dungeon.spawnPoint(rng, taken)
				table.insert(taken, { x = x, z = z })
				table.insert(out, x)
				table.insert(out, z)
			end
			return out
		end
		T.same(walk(9), walk(9))
	end)

	T.test("arenas stand far from the valley and never overlap each other", function()
		local reach = D.ArenaRadius + D.ArenaRimThickness
		for plot = 1, M.PlotCount do
			local at = Layout.arenaFrame(plot).Position
			T.ok(at.Magnitude - reach > M.HillOuterRadius + 200, "plot " .. plot .. "'s arena is beyond the hills")
			for other = plot + 1, M.PlotCount do
				local gap = (Layout.arenaFrame(other).Position - at).Magnitude
				T.ok(gap > reach * 2 + 100, "arenas " .. plot .. " and " .. other .. " are " .. gap .. " apart")
			end
		end
	end)

	T.test("the player's spot is inside the arena, facing its middle", function()
		for plot = 1, M.PlotCount do
			local frame = Layout.arenaFrame(plot)
			local spot = Layout.arenaPlayerSpot(plot)
			local flat = spot.Position - frame.Position
			T.ok(math.sqrt(flat.X ^ 2 + flat.Z ^ 2) < D.ArenaRadius - D.SpawnInset, "inside the arena")
			local toward = Vector3.new(frame.Position.X - spot.Position.X, 0, frame.Position.Z - spot.Position.Z)
			T.near(spot.LookVector:Dot(toward), toward.Magnitude, 1e-3, "facing the middle")
		end
	end)

	T.test("the one portal stands in the Market, its opening turned to the square's middle", function()
		local frame = Layout.marketPortal()
		local market = Layout.marketFrame().Position
		local toward = Vector3.new(market.X - frame.Position.X, 0, market.Z - frame.Position.Z)
		T.ok(toward.Magnitude < M.PlotSize / 2, "inside the Market's slice")
		T.ok(frame:VectorToObjectSpace(toward).Z > 0.99 * toward.Magnitude, "the opening (+Z) faces the middle")
		T.near(frame.Position.Y, M.GroundY, 1e-6)
	end)

	T.test("a player who leaves lands ExitOut studs in front of the portal's opening, facing away", function()
		local frame = Layout.marketPortal()
		local portal = frame.Position
		local landing = Layout.portalLanding()
		local flat = landing.Position - portal
		T.near(math.sqrt(flat.X ^ 2 + flat.Z ^ 2), D.ExitOut, 0.01)
		T.ok(frame:VectorToObjectSpace(Vector3.new(flat.X, 0, flat.Z)).Z > 0, "the opening's side")
		T.ok(landing.LookVector:Dot(Vector3.new(flat.X, 0, flat.Z).Unit) > 0.99, "facing away from the portal")
		T.near(landing.Position.Y, M.GroundY + D.ExitLift, 1e-6)
	end)

	T.test("Dungeon requests have the shape the server checks", function()
		T.ok(VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 1 } }, true))
		T.ok(VillageRequests.valid({ action = "DungeonEnter", level = 3, teams = { 4 } }, true))
		-- (one team a run: Config.Dungeon.RunTeams)
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 3, teams = { 1, 2 } }, true), "two teams")
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 1 } }, false), "needs a plot")
		T.ok(
			not VillageRequests.valid({ action = "DungeonEnter", level = 0, teams = { 1 } }, true),
			"level below the first"
		)
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1.5, teams = { 1 } }, true))
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 0 / 0, teams = { 1 } }, true))
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = {} }, true), "no team")
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 1, 1 } }, true), "a team twice")
		T.ok(VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 6 } }, true), "a pass team")
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 7 } }, true), "no such team")
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 0 } }, true))
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 1, 2, 3, 4, 1 } }, true))
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { a = 1 } }, true))
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = "1" }, true))
		T.ok(not VillageRequests.valid({ action = "DungeonEnter", level = 1 }, true))
		for _, action in { "DungeonNext", "DungeonReplay", "DungeonLeave" } do
			T.ok(VillageRequests.valid({ action = action }, true), action)
			T.ok(not VillageRequests.valid({ action = action }, false), action .. " needs a plot")
		end
	end)

	T.test("a slime that falls in the arena becomes a ghost and pays nothing, once", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(3))
		T.ok(Zombies.ghost(farm, "s1", NOW))
		T.eq(farm.slimes[1].ghostUntil, NOW + Config.Village.GhostSeconds)
		T.eq(farm.coins, 0, "no death reward")
		T.ok(not Zombies.ghost(farm, "s1", NOW + 5), "already a ghost")
		T.eq(farm.slimes[1].ghostUntil, NOW + Config.Village.GhostSeconds, "the time does not restart")
		T.ok(not Zombies.ghost(farm, "nobody", NOW))
		T.ok(
			Zombies.ghost(farm, "s1", NOW + Config.Village.GhostSeconds + 1),
			"a ghost whose time ran out can fall again"
		)
	end)

	T.test("a monster's def is found by its id", function()
		local def = Dungeon.defOf("meadow", "green_boar")
		T.eq(def.role, "boss")
		T.eq(Dungeon.defOf("meadow", "nobody"), nil)
	end)
end
