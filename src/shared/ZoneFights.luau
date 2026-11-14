--!strict
-- The fights of the big world's zones (docs/WORLD.md §7, M5; numbers in Config.World): what each wave of a zone sends, what
-- its guard pays, when a player may fight it and what a win opens. A zone's fight is a short Slime Dungeon run in the open
-- (shared/Dungeon makes the monsters and rolls the drops; the run itself is server/Dungeon's). Pure.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Dungeon = if script then require(script.Parent.Dungeon) else require("./Dungeon")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local WorldPacks = if script then require(script.Parent.WorldPacks) else require("./WorldPacks")
local WorldPlan = if script then require(script.Parent.WorldPlan) else require("./WorldPlan")

type Farm = typeof(FarmState.newFarm(0))
type Monster = typeof(Dungeon.monster({ attack = 1, defence = 1, speed = 1, hp = 1 }, 1, 1, ""))
-- zone id -> the time of the player's last win (farm.world.beaten on the server, the Zone_ attributes on a client)
export type Beaten = { [string]: number }

local W = Config.World

local ZoneFights = {}

-- A zone's numbers (Config.World.Zones) and its place in the world (WorldPlan.Zones); nil, nil for an id that is no zone.
function ZoneFights.zone(id: any): (any, any)
	local numbers = if type(id) == "string" then (W.Zones :: any)[id] else nil
	if not numbers then
		return nil, nil
	end
	return numbers, WorldPlan.find(id)
end

-- The middle of a zone's fight, flat, in world studs.
function ZoneFights.middle(id: string): (number, number)
	local numbers, place = ZoneFights.zone(id)
	local offset = numbers.offset or { x = 0, z = 0 }
	return WorldPlan.world(place.x + offset.x, place.z + offset.z)
end

function ZoneFights.waves(id: string): number
	return #(W.Zones :: any)[id].waves
end

-- What a wave sends, in the Dungeon's words: "normal" a crowd, "boss" the zone's guard (the last wave), "miniboss" a
-- monster that stands alone before it.
function ZoneFights.waveKind(id: string, wave: number): string
	local waves = (W.Zones :: any)[id].waves
	if not waves[wave].guard then
		return "normal"
	end
	return if wave == #waves then "boss" else "miniboss"
end

-- The level a zone shows, on its sign and over every monster of its fight: the level of the packs standing round it
-- (the owner, 2026-11-14: a guard matches the monsters about it); the Heart's, the packs' highest. Its monsters are made
-- for a team of that level (Config.World.Zones `level`).
function ZoneFights.level(id: string): number
	local _, place = ZoneFights.zone(id)
	if place.kind == "mega" then
		return W.Packs.LevelMax
	end
	return WorldPacks.levelAt(place.x, place.z)
end

-- The monsters of wave `wave` of a zone, in the order they come. The same seed makes the same wave.
function ZoneFights.plan(id: string, wave: number, seed: number): { Monster }
	local numbers = (W.Zones :: any)[id]
	local entry = numbers.waves[wave]
	local monsters: { Monster }
	if entry.guard then
		local def = assert(Dungeon.defOf(numbers.map, entry.guard), "unknown guard " .. tostring(entry.guard))
		monsters = { Dungeon.monster(def, numbers.level, entry.wave, "m" .. entry.wave .. "-1", entry.power) }
	else
		monsters = Dungeon.plan(numbers.map, numbers.level, entry.wave, seed)
	end
	-- (a monster's level is only what it shows: every one of a zone shows the zone's)
	local level = ZoneFights.level(id)
	for _, monster in monsters do
		monster.level = level
	end
	return monsters
end

-- What the zone's guard pays: Config.World.Reward of the zone's kind, the coins raised by the zone's level as a pack
-- monster's are (WorldPacks.killReward) and "trophy" turned into the region's own (dropped where the region has none).
function ZoneFights.reward(id: string): { any }
	local _, place = ZoneFights.zone(id)
	local grow = 1 + ZoneFights.level(id) * Config.Economy.SellLevelStep
	local out: { any } = {}
	for _, line in (W.Reward :: any)[place.kind] do
		local item = if line.item == "trophy" then (W.Trophy :: any)[place.region] else line.item
		if item then
			local scale = if item == "coins" then grow else 1
			table.insert(out, {
				item = item,
				chance = line.chance,
				min = math.floor(line.min * scale + 0.5),
				max = math.floor(line.max * scale + 0.5),
			})
		end
	end
	return out
end

-- What a fallen monster of a zone rolls its drops from (as a def: `drops`): the guard pays the zone's reward, every other
-- monster what its own def says.
function ZoneFights.dropDef(id: string, wave: number, def: any): any
	if wave >= ZoneFights.waves(id) then
		return { drops = ZoneFights.reward(id) }
	end
	return def
end

-- Seconds the zone still rests for a player who won it at `beatenAt` (0 or nil: never), 0 when it may be fought.
function ZoneFights.restLeft(id: string, beatenAt: number?, now: number): number
	local _, place = ZoneFights.zone(id)
	if not beatenAt or beatenAt <= 0 then
		return 0
	end
	return math.max(0, beatenAt + (W.Rest :: any)[place.kind] - now)
end

-- Why the zone may not be fought now: "ZONE_UNKNOWN" (no such zone), "ZONE_LOCKED" (a zone it needs is not won yet) or
-- "ZONE_RESTING"; nil when it may.
function ZoneFights.block(beaten: Beaten, id: any, now: number): string?
	local numbers = ZoneFights.zone(id)
	if not numbers then
		return "ZONE_UNKNOWN"
	end
	for _, need in numbers.needs or {} do
		if (beaten[need] or 0) <= 0 then
			return "ZONE_LOCKED"
		end
	end
	if ZoneFights.restLeft(id, beaten[id], now) > 0 then
		return "ZONE_RESTING"
	end
	return nil
end

-- The defs a zone's fight can drop from, for the list a screen shows: every common monster of its crowds' map, each
-- monster that stands alone before the guard, and the guard's reward.
function ZoneFights.dropDefs(id: string): { any }
	local numbers = (W.Zones :: any)[id]
	local out: { any } = {}
	local crowd = false
	for index, entry in numbers.waves do
		if index == #numbers.waves then
			table.insert(out, { drops = ZoneFights.reward(id) })
		elseif entry.guard then
			table.insert(out, Dungeon.defOf(numbers.map, entry.guard))
		elseif not crowd then
			crowd = true
			for _, def in (Config.Dungeon.Maps :: any)[numbers.map].monsters do
				if def.role ~= "miniboss" and def.role ~= "boss" then
					table.insert(out, def)
				end
			end
		end
	end
	return out
end

-- The zone is won: the time is written (it opens what needs the zone, and the zone rests from now).
function ZoneFights.recordClear(farm: Farm, id: string, now: number)
	farm.world.beaten[id] = now
end

-- Whether a gate of the Heart (a WorldPlan.Sites id) is open for a player: its boss zone is won.
function ZoneFights.gateOpen(beaten: Beaten, gateId: string): boolean
	local zone = (W.Gates :: any)[gateId]
	return zone ~= nil and (beaten[zone] or 0) > 0
end

-- ===== the waystones (Config.World.Waystones) =====

-- Where a zone's waystone stands, flat, in world studs: beside the pad, towards the hub.
function ZoneFights.waystone(id: string): (number, number)
	local x, z = ZoneFights.middle(id)
	local hubX, hubZ = WorldPlan.world(WorldPlan.Hub.x, WorldPlan.Hub.z)
	local dx, dz = hubX - x, hubZ - z
	local d = math.sqrt(dx * dx + dz * dz)
	return x + dx / d * W.Waystones.OutStuds, z + dz / d * W.Waystones.OutStuds
end

-- Where a traveller lands at a zone's waystone, flat: ArriveStuds from it, towards the pad.
function ZoneFights.landing(id: string): (number, number)
	local x, z = ZoneFights.middle(id)
	local stoneX, stoneZ = ZoneFights.waystone(id)
	local dx, dz = x - stoneX, z - stoneZ
	local d = math.sqrt(dx * dx + dz * dz)
	return stoneX + dx / d * W.Waystones.ArriveStuds, stoneZ + dz / d * W.Waystones.ArriveStuds
end

-- Why a player may not travel to a zone's waystone: "ZONE_UNKNOWN", or "ZONE_LOCKED" (its guard is not beaten yet); nil
-- when they may.
function ZoneFights.travelBlock(beaten: Beaten, id: any): string?
	if not ZoneFights.zone(id) then
		return "ZONE_UNKNOWN"
	elseif (beaten[id] or 0) <= 0 then
		return "ZONE_LOCKED"
	end
	return nil
end

return ZoneFights
