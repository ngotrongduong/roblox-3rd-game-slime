local Config = require("../../src/shared/Config")
local Rng = require("../../src/shared/Rng")
local Treasure = require("../../src/shared/Treasure")
local WorldPacks = require("../../src/shared/WorldPacks")
local WorldPlan = require("../../src/shared/WorldPlan")

local C = Config.World.Chests

return function(T)
	T.test("a chest pays Coins near a village and more the farther out it lies", function()
		local v = WorldPlan.Villages[1]
		local near = Treasure.coins(v.x, v.z)
		T.eq(near, math.floor(C.Coins * (1 + Config.World.Packs.LevelMin * Config.Economy.SellLevelStep)))
		-- (the farthest pack of the play test, 2026-11-17: level LevelMax)
		local far = Treasure.coins(371.76, -1786.7)
		T.eq(far, math.floor(C.Coins * (1 + Config.World.Packs.LevelMax * Config.Economy.SellLevelStep)))
		T.ok(far > near * 5, "far " .. far .. " near " .. near)
	end)

	T.test("Count chests find spots: clear of places, Apart from each other, where the ground says yes", function()
		local rng = Rng.new(7)
		local taken = {}
		for _ = 1, C.Count do
			local x, z = Treasure.spot(rng, taken)
			T.ok(x ~= nil and z ~= nil, "a spot for chest " .. (#taken + 1))
			if x and z then
				T.ok(WorldPacks.clear(x, z), "clear at " .. x .. "," .. z)
				for _, other in taken do
					T.ok((x - other[1]) ^ 2 + (z - other[2]) ^ 2 >= C.Apart ^ 2, "apart")
				end
				table.insert(taken, { x, z })
			end
		end
		-- a ground that refuses everything: no spot, no endless loop
		local x = Treasure.spot(rng, {}, function()
			return false
		end)
		T.eq(x, nil)
	end)
end
