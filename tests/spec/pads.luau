local Config = require("../../src/shared/Config")
-- The upgrade pads and work places (docs/GAMEPLAY.md §10): every upgradable area has one pad, standing beside
-- the way in and not on it; the bins hold what an area's box holds.
return function(T)
	-- x of the path into each area, in the area's frame (AreaUpgrade's entrance points)
	local PATH_X = { fishing = -3, garden = 0, pantry = 0, kitchen = 0, training = 0, breeding = 4 }
	T.test("every area has a pad beside its path, not on it", function()
		for _, area in Config.Village.Areas do
			local spot = Config.Pads.Spots[area]
			T.ok(spot ~= nil, area .. " has a pad spot")
			T.ok(math.abs(spot[1] - PATH_X[area]) >= Config.Pads.Radius + 2, area .. " pad clear of the path")
			T.ok(spot[2] < 0, area .. " pad outside the area, on the entrance side")
		end
	end)
	T.test("bins hold the same as the work boxes", function()
		T.eq(Config.WorkPlaces.BinCapacity, Config.Work.BoxCapacity)
	end)
	T.test("the brain finds the bins by name", function()
		T.ok(table.find(Config.Village.SpotNames.Box, "FishBin") ~= nil)
		T.ok(table.find(Config.Village.SpotNames.Box, "VegBin") ~= nil)
	end)
end
