--!nocheck
-- Writes what the map's picture is drawn from (tools/world/map_picture.py) as JSON: the plan's places, regions, river
-- and roads, the square the picture covers, and the numbers the level bands come from.
--   lune run tools/world/export_plan.luau <out.json>
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local Config = require("../../src/shared/Config")
local WorldPacks = require("../../src/shared/WorldPacks")
local WorldPlan = require("../../src/shared/WorldPlan")

local out = assert(process.args[1], "usage: lune run tools/world/export_plan.luau <out.json>")
local P = Config.World.Packs

local roads = {}
for _, road in WorldPlan.Roads do
	table.insert(roads, { kind = road.kind, width = road.width, points = WorldPlan.roadPoints(road) })
end

fs.writeFile(
	out,
	serde.encode("json", {
		map = Config.World.Map,
		rim = WorldPlan.Rim,
		seaZ = WorldPlan.SeaZ,
		hub = WorldPlan.Hub,
		villages = WorldPlan.Villages,
		zones = WorldPlan.Zones,
		sites = WorldPlan.Sites,
		regions = WorldPlan.Regions,
		heart = WorldPlan.Heart,
		volcano = WorldPlan.Volcano,
		peaks = WorldPlan.Peaks,
		river = WorldPlan.River,
		roads = roads,
		packs = {
			levelMin = P.LevelMin,
			levelMax = P.LevelMax,
			nearStuds = P.NearStuds,
			curve = P.Curve,
			bandLevels = P.BandLevels,
			bandColours = P.BandColours,
			farthest = WorldPacks.farthest(),
		},
	})
)
print("plan written to", out)
