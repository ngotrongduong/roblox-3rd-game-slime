--!strict
-- The treasure chests of the open world (Config.World.Chests; the owner, 2026-11-16): where a new one may lie and what it
-- pays. Pure rules; the server (server/Treasure) puts the chests on the real ground and pays. Positions are the plan's
-- (x east, z south).
local Config = if script then require(script.Parent.Config) else require("./Config")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local WorldPacks = if script then require(script.Parent.WorldPacks) else require("./WorldPacks")

type Rng = typeof(Rng.new(0))

local C = Config.World.Chests

local Treasure = {}

local cells: { { id: string, x: number, z: number } }? = nil

-- The coins a chest lying at this plan point pays: Coins raised by the spot's level as a pack monster's are.
function Treasure.coins(x: number, z: number): number
	local level = WorldPacks.levelAt(x, z)
	return math.floor(C.Coins * (1 + level * Config.Economy.SellLevelStep))
end

-- A spot for a new chest, or nil when Tries tries found none: a random cell of the packs' grid, a random point within the
-- packs' jitter of its middle, clear of places by the packs' rules, at least Apart from every point of `taken` ({ x, z }
-- each) and, when given, accepted by `ground` (the server's look at the real land there).
function Treasure.spot(
	rng: Rng,
	taken: { { number } },
	ground: ((x: number, z: number) -> boolean)?
): (number?, number?)
	local all = cells or WorldPacks.cells()
	cells = all
	local jitter = Config.World.Packs.JitterStuds
	for _ = 1, C.Tries do
		local cell = rng:pick(all)
		local x = cell.x + (rng:next() * 2 - 1) * jitter
		local z = cell.z + (rng:next() * 2 - 1) * jitter
		local free = WorldPacks.clear(x, z)
		if free then
			for _, other in taken do
				if (x - other[1]) ^ 2 + (z - other[2]) ^ 2 < C.Apart ^ 2 then
					free = false
					break
				end
			end
		end
		if free and (ground == nil or ground(x, z)) then
			return x, z
		end
	end
	return nil, nil
end

return Treasure
