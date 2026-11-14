--!strict
-- The plan of the big world, "the Goo Lands" (docs/WORLD.md, the owner 2026-11-14: a world about ten times the old
-- valley, natural, with 8 villages, 1 shopping hub, 10 mini-boss zones, 3 boss zones and 1 mega-boss zone). Pure data
-- and plain geometry, read by the Studio builders (tools/world/*.luau), the tests and, at the cut-over, by Layout.
-- Positions are local: x east, z south (north is -Z, as in Layout), in studs from the plan's own middle; `Origin`
-- places the plan in the work place, far from the old valley, so both can stand until the game moves over.
-- Nothing here sits on a grid or a mirror line on purpose (the owner: "natural, not squares like a chessboard").

local WorldPlan = {}

WorldPlan.Origin = { x = 0, y = 0, z = -6000 }
-- The land the builders write, and the line where the rim mountains start to rise (a rounded square).
WorldPlan.Bounds = { minX = -2300, maxX = 2300, minZ = -2400, maxZ = 2000 }
WorldPlan.Rim = { x = 0, z = -150, radius = 2000, power = 3 }
WorldPlan.SeaZ = 1640 -- the South Bay opens beyond this line

-- A home plot is Config.Map.PlotSize square; the ground is flat within PadRadius of its middle. GateOut is how far
-- in front of the plot's middle the Village Lane passes (the gate is PlotSize / 2 out).
WorldPlan.Village = { PadRadius = 176, GateOut = 150 }

export type Place = { id: string, name: string, kind: string, x: number, z: number, radius: number }

-- The shopping hub, in the middle of the Home Vale, on the river.
WorldPlan.Hub = { id = "hub", name = "Goo Market", kind = "hub", x = 0, z = 980, radius = 120 }
-- The middle of the Market's square (Layout.marketFrame; Config.Market's spots are measured from it). The builder
-- centred the Market's whole model on the hub, which leaves its square here (measured in the work place).
WorldPlan.Market = { x = -0.87, z = 1002.78 }

-- The 8 villages: a loose ring round the hub, open to the north where the King's Road leaves and to the south where
-- the river runs to the bay. Not on a clock face: each sits in its own fold of the land.
WorldPlan.Villages = {
	{ id = "v1", name = "Hillfoot", kind = "village", x = -520, z = 610, radius = 176 },
	{ id = "v2", name = "Westmeadow", kind = "village", x = -760, z = 930, radius = 176 },
	{ id = "v3", name = "Orchard End", kind = "village", x = -620, z = 1300, radius = 176 },
	{ id = "v4", name = "Reedbank", kind = "village", x = -270, z = 1500, radius = 176 },
	-- (`camps`: the river runs between Baywatch and the hub, so its zombie camps lie turned this many degrees off the
	-- gate's line, up the east bank: Layout.campFrame)
	{ id = "v5", name = "Baywatch", kind = "village", x = 300, z = 1520, radius = 176, camps = -28 },
	{ id = "v6", name = "Sunny Rise", kind = "village", x = 640, z = 1290, radius = 176 },
	{ id = "v7", name = "Eastfield", kind = "village", x = 770, z = 920, radius = 176 },
	{ id = "v8", name = "Millbrook", kind = "village", x = 510, z = 590, radius = 176, camps = 20 },
}

-- The regions. `at` are the seeds the builder grows each region's ground from (nearest seed wins, frayed by noise);
-- `lift` is how high its ground stands over the Vale's, `swell` how much it rolls. The Grove is the widest and lowest,
-- the Ember land smaller and higher: the two sides of the Heart are not alike.
WorldPlan.Regions = {
	{
		id = "vale",
		name = "Home Vale",
		lift = 0,
		swell = 5,
		at = { { 0, 1050 }, { -500, 1000 }, { 500, 1000 }, { 0, 1450 } },
	},
	{
		id = "meadow",
		name = "Sunny Meadow",
		lift = 4,
		swell = 16,
		at = { { 0, 200 }, { -700, 260 }, { 760, 340 }, { -1300, 700 }, { 1300, 700 } },
	},
	{
		id = "mushroom",
		name = "Mushroom Grove",
		lift = 2,
		swell = 10,
		at = { { -1150, -300 }, { -1640, -400 }, { -900, -720 }, { -1700, 100 }, { -1400, -1000 } },
	},
	{
		id = "ember",
		name = "Ember Lava",
		lift = 22,
		swell = 26,
		at = { { 1150, -300 }, { 1620, -840 }, { 850, -860 }, { 1750, -60 }, { 1180, -1230 } },
	},
	{
		id = "frost",
		name = "Frozen Ice",
		lift = 52,
		swell = 30,
		at = { { -30, -1500 }, { -650, -1790 }, { 560, -1700 }, { -1250, -1560 }, { 1250, -1620 }, { 0, -2100 } },
	},
}

-- Fight zones, in the order a player meets them. `tier` orders the difficulty; `guard` names a monster of the game's
-- own roster that fits (docs/MONSTER-SLIMES.md), a suggestion for the gameplay work, not a rule.
WorldPlan.Zones = {
	{
		id = "m1",
		name = "Bramble Hollow",
		kind = "mini",
		region = "meadow",
		tier = 1,
		guard = "boar",
		x = -700,
		z = 180,
		radius = 70,
	},
	{
		id = "m2",
		name = "Turtle Pond",
		kind = "mini",
		region = "meadow",
		tier = 2,
		guard = "turtle",
		x = 850,
		z = 400,
		radius = 70,
	},
	{
		id = "m3",
		name = "Sporelight Glade",
		kind = "mini",
		region = "mushroom",
		tier = 3,
		guard = "wyrm",
		x = -1080,
		z = -120,
		radius = 70,
	},
	{
		id = "m4",
		name = "Webwood Hollow",
		kind = "mini",
		region = "mushroom",
		tier = 4,
		guard = "golem",
		x = -1640,
		z = -400,
		radius = 70,
	},
	{
		id = "b1",
		name = "Gloomroot Throne",
		kind = "boss",
		region = "mushroom",
		tier = 5,
		guard = "bear",
		x = -860,
		z = -740,
		radius = 110,
	},
	{
		id = "m5",
		name = "Cinder Terraces",
		kind = "mini",
		region = "ember",
		tier = 6,
		guard = "bull",
		x = 1060,
		z = -180,
		radius = 70,
	},
	{
		id = "m6",
		name = "Emberglass Field",
		kind = "mini",
		region = "ember",
		tier = 7,
		guard = "tortoise",
		x = 1620,
		z = -840,
		radius = 70,
	},
	{
		id = "b2",
		name = "Molten Throne",
		kind = "boss",
		region = "ember",
		tier = 8,
		guard = "magma golem",
		x = 820,
		z = -880,
		radius = 110,
	},
	{
		id = "m7",
		name = "Sunken Ruins",
		kind = "mini",
		region = "mushroom",
		tier = 9,
		guard = "totem golem",
		x = -1330,
		z = -1180,
		radius = 70,
	},
	{
		id = "m8",
		name = "Ashen Pass",
		kind = "mini",
		region = "ember",
		tier = 10,
		guard = "phoenix",
		x = 980,
		z = -1430,
		radius = 70,
	},
	{
		id = "m9",
		name = "Crystal Hollow",
		kind = "mini",
		region = "frost",
		tier = 11,
		guard = "ice golem",
		x = -650,
		z = -1790,
		radius = 70,
	},
	{
		id = "m10",
		name = "Frostfang Ridge",
		kind = "mini",
		region = "frost",
		tier = 12,
		guard = "mammoth",
		x = 470,
		z = -1610,
		radius = 70,
	},
	{
		id = "b3",
		name = "Glacier Throne",
		kind = "boss",
		region = "frost",
		tier = 13,
		guard = "yeti",
		x = -30,
		z = -1450,
		radius = 110,
	},
	{
		id = "heart",
		name = "The Heart",
		kind = "mega",
		region = "heart",
		tier = 14,
		guard = "King Goo",
		x = 0,
		z = -620,
		radius = 130,
	},
}

-- The Heart: a high crater between the three hard regions, seen from everywhere. Its lake spills south as Crownfall,
-- the river that waters the Vale. Three gates in its rim, one behind each boss.
WorldPlan.Heart = {
	x = 0,
	z = -620,
	RimRadius = 372, -- the crest of the crater's rim
	FootRadius = 470, -- where its outer cliffs meet the land
	Top = 130, -- the crater floor over the Vale's ground (84 read as a low hill from the Cross)
	RimRise = 46, -- the rim's crest over the crater floor
	LakeInner = 160, -- the goo lake lies between these two radii, round the island
	LakeOuter = 300,
	GateWidth = 44,
	Fall = { x = 0, z = -250 }, -- where Crownfall leaves the rim
	Pool = { x = 0, z = -170, radius = 46 },
}

-- The volcano at the Ember land's far edge and the high peaks behind the ice: the far landmarks.
WorldPlan.Volcano = { x = 1930, z = -420, radius = 330, height = 250, crater = 60 }
WorldPlan.Peaks = { { -700, -2180, 300 }, { 80, -2250, 340 }, { 820, -2150, 290 } } -- { x, z, height }

-- Places that are not fights: junctions, bridges, gates and views.
WorldPlan.Sites = {
	{ id = "cross", name = "Wayfarers' Cross", kind = "landmark", x = -10, z = 250, radius = 46 },
	{ id = "vale_north", name = "North Gate", kind = "junction", x = -50, z = 705, radius = 24 },
	{ id = "vale_south", name = "South Gate", kind = "junction", x = -60, z = 1372, radius = 20 },
	{ id = "quay", name = "South Quay", kind = "landmark", x = -100, z = 1700, radius = 50 },
	{ id = "lookout", name = "Crownfall Lookout", kind = "landmark", x = -90, z = -110, radius = 30 },
	{ id = "fork_w", name = "Grove Fork", kind = "junction", x = -1250, z = -340, radius = 20 },
	{ id = "fork_e", name = "Ember Fork", kind = "junction", x = 1320, z = -520, radius = 20 },
	{ id = "gate_w", name = "Root Gate", kind = "gate", x = -372, z = -660, radius = 30 },
	{ id = "gate_e", name = "Ember Gate", kind = "gate", x = 368, z = -676, radius = 30 },
	{ id = "gate_n", name = "Frost Gate", kind = "gate", x = -8, z = -992, radius = 30 },
	{ id = "br_market", name = "Market Bridge", kind = "bridge", x = 203, z = 985, radius = 24 },
	{ id = "br_north", name = "Mill Bridge", kind = "bridge", x = 178, z = 650, radius = 24 },
	{ id = "br_south", name = "Reed Bridge", kind = "bridge", x = 57, z = 1378, radius = 24 },
	{ id = "br_meadow", name = "Old Stone Bridge", kind = "bridge", x = 166, z = 255, radius = 24 },
}

-- The river, from Crownfall's pool through the meadow and the Vale to the bay. One level all the way.
WorldPlan.River = {
	Width = 26,
	points = {
		{ 0, -170 },
		{ 110, 80 },
		{ 190, 330 },
		{ 170, 600 },
		{ 205, 850 },
		{ 200, 1100 },
		{ 70, 1340 },
		{ 15, 1520 },
		{ 0, 1780 },
	},
}

-- Roads. A path is a list of place ids (a village id means the lane's point before its gate) and bare { x, z } points
-- the road bends through. Two ids that follow each other in a path are joined: that is the world's road graph.
WorldPlan.Roads = {
	{
		id = "kings_road",
		name = "King's Road",
		kind = "main",
		width = 14,
		path = { "hub", "vale_north", { -40, 470 }, "cross" },
	},
	{
		id = "lane",
		name = "Village Lane",
		kind = "lane",
		width = 10,
		path = {
			"vale_north",
			"v1",
			"v2",
			"v3",
			"v4",
			"vale_south",
			"br_south",
			"v5",
			"v6",
			"v7",
			"v8",
			"br_north",
			"vale_north",
		},
	},
	{ id = "spoke_west", name = "West Row", kind = "lane", width = 10, path = { "hub", { -320, 1000 }, "v2" } },
	{
		id = "spoke_east",
		name = "East Row",
		kind = "lane",
		width = 10,
		path = { "hub", "br_market", { 420, 950 }, "v7" },
	},
	{
		id = "spoke_south",
		name = "Quay Road",
		kind = "lane",
		width = 10,
		path = { "vale_south", { -70, 1560 }, "quay" },
	}, -- (from the lane: the Market's back wall faces south)
	{ id = "meadow_west", name = "Bramble Way", kind = "trail", width = 10, path = { "cross", { -360, 310 }, "m1" } },
	{
		id = "meadow_east",
		name = "Pond Way",
		kind = "trail",
		width = 10,
		path = { "cross", "br_meadow", { 500, 250 }, "m2" },
	},
	{
		id = "falls_path",
		name = "Riverside Path",
		kind = "trail",
		width = 8,
		path = { "cross", { -70, 70 }, "lookout" },
	},
	{
		id = "west_road",
		name = "Grove Road",
		kind = "trail",
		width = 10,
		path = { "m1", { -930, 60 }, "m3", "fork_w", { -1090, -600 }, "b1" },
	},
	{
		id = "west_far",
		name = "Webwood Track",
		kind = "trail",
		width = 8,
		path = { "fork_w", "m4", { -1640, -820 }, "m7" },
	},
	{
		id = "east_road",
		name = "Cinder Road",
		kind = "trail",
		width = 10,
		path = { "m2", { 1040, 150 }, "m5", "fork_e", { 1120, -740 }, "b2" },
	},
	{
		id = "east_far",
		name = "Emberglass Track",
		kind = "trail",
		width = 8,
		path = { "fork_e", "m6", { 1400, -1180 }, "m8" },
	},
	{
		id = "north_west",
		name = "Frost Road West",
		kind = "trail",
		width = 10,
		path = { "m7", { -1050, -1560 }, "m9", { -300, -1630 }, "b3" },
	},
	{
		id = "north_east",
		name = "Frost Road East",
		kind = "trail",
		width = 10,
		path = { "m8", { 740, -1570 }, "m10", { 230, -1540 }, "b3" },
	},
	{ id = "cause_w", name = "Root Causeway", kind = "causeway", width = 12, path = { "b1", "gate_w", "heart" } },
	{ id = "cause_e", name = "Ember Causeway", kind = "causeway", width = 12, path = { "b2", "gate_e", "heart" } },
	{
		id = "cause_n",
		name = "Frost Causeway",
		kind = "causeway",
		width = 12,
		path = { "b3", { -40, -1210 }, "gate_n", "heart" },
	},
} :: { { id: string, name: string, kind: string, width: number, path: { any } } }

-- Every place with a pad, in one list.
function WorldPlan.places(): { Place }
	local all: { Place } = { WorldPlan.Hub }
	for _, list in { WorldPlan.Villages, WorldPlan.Zones, WorldPlan.Sites } do
		for _, place in list :: { any } do
			table.insert(all, place)
		end
	end
	return all
end

function WorldPlan.find(id: string): Place?
	for _, place in WorldPlan.places() do
		if place.id == id then
			return place
		end
	end
	return nil
end

-- The unit direction (x, z) from a village's middle to the hub: its gate faces that way.
function WorldPlan.villageFacing(village: Place): (number, number)
	local dx, dz = WorldPlan.Hub.x - village.x, WorldPlan.Hub.z - village.z
	local d = math.sqrt(dx * dx + dz * dz)
	return dx / d, dz / d
end

-- Where a road meets a place: its middle, or for a village the lane's point in front of its gate.
function WorldPlan.point(id: string): (number, number)
	local place = assert(WorldPlan.find(id), "no place " .. id)
	if place.kind == "village" then
		local fx, fz = WorldPlan.villageFacing(place)
		return place.x + fx * WorldPlan.Village.GateOut, place.z + fz * WorldPlan.Village.GateOut
	end
	return place.x, place.z
end

-- A road's bends as { x, z } points.
function WorldPlan.roadPoints(road: { path: { any } }): { { number } }
	local points = {}
	for _, step in road.path do
		if type(step) == "string" then
			local x, z = WorldPlan.point(step)
			table.insert(points, { x, z })
		else
			table.insert(points, { step[1], step[2] })
		end
	end
	return points
end

-- The road graph: for each place id, the ids one road leg away.
function WorldPlan.graph(): { [string]: { [string]: boolean } }
	local graph: { [string]: { [string]: boolean } } = {}
	for _, road in WorldPlan.Roads do
		local last: string? = nil
		for _, step in road.path :: { any } do
			if type(step) == "string" then
				graph[step] = graph[step] or {}
				if last then
					graph[step][last] = true
					graph[last][step] = true
				end
				last = step
			end
		end
	end
	return graph
end

-- A place's position in the work place (the ground height is the builder's to give).
function WorldPlan.world(x: number, z: number): (number, number)
	return WorldPlan.Origin.x + x, WorldPlan.Origin.z + z
end

return WorldPlan
