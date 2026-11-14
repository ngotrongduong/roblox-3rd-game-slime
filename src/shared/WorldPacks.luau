--!strict
-- The monsters of the open world (docs/WORLD.md §7 "M5b"): packs spread over the whole plan, one to a cell, each with a
-- fixed level by how far it stands from the nearest village. Pure rules; the server (server/ZombieFights) drops the
-- spots on the real ground and runs the fights. Positions are the plan's (x east, z south) unless said.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local WorldPlan = if script then require(script.Parent.WorldPlan) else require("./WorldPlan")

type Rng = typeof(Rng.new(0))

local P = Config.World.Packs
local TWO_32 = 4294967296

local WorldPacks = {}

local function dist(ax: number, az: number, bx: number, bz: number): number
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
end

-- The id of the region whose nearest seed is nearest (the same rule the builder grows the ground by, without the noise).
function WorldPacks.region(x: number, z: number): string
	local best, bestId = math.huge, WorldPlan.Regions[1].id
	for _, region in WorldPlan.Regions do
		for _, seed in region.at do
			local d = dist(x, z, seed[1], seed[2])
			if d < best then
				best, bestId = d, region.id
			end
		end
	end
	return bestId
end

-- The Config.Dungeon.Maps id whose monsters stand there.
function WorldPacks.mapOf(x: number, z: number): string
	return (P.Maps :: { [string]: string })[WorldPacks.region(x, z)]
end

-- Studs to the middle of the nearest village.
function WorldPacks.villageDistance(x: number, z: number): number
	local best = math.huge
	for _, village in WorldPlan.Villages do
		best = math.min(best, dist(x, z, village.x, village.z))
	end
	return best
end

-- One cell every GridStuds over the land: the middles, ids "p<col>x<row>" (a saved team may name one, so they are short).
function WorldPacks.cells(): { { id: string, x: number, z: number } }
	local B = WorldPlan.Bounds
	local out = {}
	for col = 1, math.ceil((B.maxX - B.minX) / P.GridStuds) do
		for row = 1, math.ceil((B.maxZ - B.minZ) / P.GridStuds) do
			table.insert(out, {
				id = "p" .. col .. "x" .. row,
				x = B.minX + (col - 0.5) * P.GridStuds,
				z = B.minZ + (row - 0.5) * P.GridStuds,
			})
		end
	end
	return out
end

-- The cell's middle moved by a hash of its id and the try: the same every time, another place each try.
function WorldPacks.candidate(cell: { id: string, x: number, z: number }, try: number): (number, number)
	local dx = Rng.hash(cell.id .. ":x" .. try) / TWO_32
	local dz = Rng.hash(cell.id .. ":z" .. try) / TWO_32
	return cell.x + (dx * 2 - 1) * P.JitterStuds, cell.z + (dz * 2 - 1) * P.JitterStuds
end

-- Whether a pack may stand here by the plan alone (the ground, water and slope are the server's to look at).
function WorldPacks.clear(x: number, z: number): boolean
	local R = WorldPlan.Rim
	local radius = R.radius - P.RimClear
	if (math.abs(x - R.x) / radius) ^ R.power + (math.abs(z - R.z) / radius) ^ R.power > 1 then
		return false
	end
	for _, place in WorldPlan.Villages do
		if dist(x, z, place.x, place.z) <= place.radius + P.VillageClear then
			return false
		end
	end
	local hub = WorldPlan.Hub
	if dist(x, z, hub.x, hub.z) <= hub.radius + P.HubClear then
		return false
	end
	for _, place in WorldPlan.Zones do
		if dist(x, z, place.x, place.z) <= place.radius + P.ZoneClear then
			return false
		end
	end
	local heart = WorldPlan.Heart
	if dist(x, z, heart.x, heart.z) <= heart.FootRadius + P.HeartClear then
		return false
	end
	for _, place in WorldPlan.Sites do
		if dist(x, z, place.x, place.z) <= place.radius + P.SiteClear then
			return false
		end
	end
	return true
end

-- A pack's level: LevelMin near a village, LevelMax at the farthest pack, between by the share of the way ^ Curve.
function WorldPacks.level(distance: number, farthest: number): number
	if distance <= P.NearStuds or farthest <= P.NearStuds then
		return P.LevelMin
	end
	local share = math.clamp((distance - P.NearStuds) / (farthest - P.NearStuds), 0, 1)
	local level = P.LevelMin + (P.LevelMax - P.LevelMin) * share ^ P.Curve
	return math.clamp(math.floor(level + 0.5), P.LevelMin, P.LevelMax)
end

-- The village distance that holds LevelMax: the farthest pack that really stands (a measured number, so the server and
-- the client's map agree without either looking at the ground).
function WorldPacks.farthest(): number
	return P.FarStuds
end

-- The level of a pack standing at this plan point.
function WorldPacks.levelAt(x: number, z: number): number
	return WorldPacks.level(WorldPacks.villageDistance(x, z), WorldPacks.farthest())
end

-- How many bands of BandLevels there are: the last one holds LevelMax.
function WorldPacks.bands(): number
	return math.floor(P.LevelMax / P.BandLevels) + 1
end

function WorldPacks.band(level: number): number
	return math.min(math.floor(level / P.BandLevels) + 1, WorldPacks.bands())
end

function WorldPacks.bandName(band: number): string
	local low = if band == 1 then 1 else (band - 1) * P.BandLevels
	return "Lv " .. low .. "-" .. math.min(band * P.BandLevels, P.LevelMax)
end

-- The map's common monsters: its mini-boss and boss guard the zones, not the open world.
function WorldPacks.roster(mapId: string): { any }
	local out = {}
	for _, def in (Config.Dungeon.Maps :: any)[mapId].monsters do
		if def.role ~= "miniboss" and def.role ~= "boss" then
			table.insert(out, def)
		end
	end
	return out
end

-- A foe for Combat, shaped as Dungeon.monster's, with every stat the same share of the level as a slime's are counted.
function WorldPacks.monster(def: any, level: number, id: string)
	local share = level / #Stats.Keys * P.StatFactor
	return {
		id = id,
		defId = def.id :: string,
		name = def.name :: string,
		defRole = def.role :: string,
		kind = def.kind :: string,
		skills = def.skills :: { string }?,
		attack = share,
		defence = share,
		speed = share,
		hp = math.max(1, share * Config.Stats.HpPerLevel),
		level = level,
	}
end

-- A fresh roll of a pack: SizeMin..SizeMax monsters of the map's roster, all at the pack's level.
function WorldPacks.pack(prefix: string, mapId: string, level: number, rng: Rng)
	local roster = WorldPacks.roster(mapId)
	local out = {}
	for index = 1, rng:int(P.SizeMin, P.SizeMax) do
		table.insert(out, WorldPacks.monster(rng:pick(roster), level, prefix .. "-" .. index))
	end
	return out
end

-- Coins for a fallen monster: its role's base, raised by its level as a slime's sale is.
function WorldPacks.killReward(defRole: string?, level: number): number
	local base = (P.CoinBase :: { [string]: number })[defRole or "swarmer"] or P.CoinBase.swarmer
	return math.floor(base * (1 + math.max(0, level) * Config.Economy.SellLevelStep))
end

-- Where a team sets out from: on the line from the pack to the gate, at most MarchMostStuds from the pack. Any one
-- coordinate space.
function WorldPacks.musterSpot(packX: number, packZ: number, gateX: number, gateZ: number): (number, number)
	local d = dist(packX, packZ, gateX, gateZ)
	if d <= P.MarchMostStuds then
		return gateX, gateZ
	end
	local k = P.MarchMostStuds / d
	return packX + (gateX - packX) * k, packZ + (gateZ - packZ) * k
end

return WorldPacks
