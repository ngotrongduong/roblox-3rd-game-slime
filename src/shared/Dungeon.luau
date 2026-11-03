--!strict
-- The Slime Dungeon's rules (the owner, 2026-11-04; docs/reference/02-battle.md §5 waves, §6 level ladder, §13 loot): what
-- each wave sends, how strong it is, what it drops and how the drops reach the farm. Pure and seeded; the arena itself
-- (spawning, the fight, the screens) is the server's and the client's.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Food = if script then require(script.Parent.Food) else require("./Food")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local Zombies = if script then require(script.Parent.Zombies) else require("./Zombies")

type Farm = typeof(FarmState.newFarm(0))
type Rng = typeof(Rng.new(0))
-- A monster as Combat takes it (id, stats, kind) with what the screens need: its def, its role and its shown level.
-- (`defRole` and not `role`: Combat reads a fighter's `role` as its way of fighting.)
export type Monster = {
	id: string,
	defId: string,
	name: string,
	defRole: string,
	kind: string,
	attack: number,
	defence: number,
	speed: number,
	hp: number,
	level: number,
}
export type Drop = { item: string, amount: number }
-- A wave's drops wait in the ledger ("open") until the wave is cleared ("committed", once) or lost ("discarded").
type WaveLedger = { state: string, drops: { [string]: number } }
export type Ledger = { waves: { [number]: WaveLedger } }
-- What a committed wave gave the farm: coins paid, food stored, food lost to a full pantry, and the materials by id.
export type Paid = { coins: number, food: number, lost: number, materials: { [string]: number } }

local Dungeon = {}

local D = Config.Dungeon

local function map(mapId: string): any
	local found = (D.Maps :: any)[mapId]
	assert(found, "unknown dungeon map " .. tostring(mapId))
	return found
end

-- "normal", "miniboss" or "boss": what a wave sends.
function Dungeon.waveKind(wave: number): string
	if wave == D.BossWave then
		return "boss"
	elseif wave == D.MiniBossWave then
		return "miniboss"
	end
	return "normal"
end

-- The cost a normal wave may spend, nil on the waves that send one big monster alone.
function Dungeon.budget(wave: number): number?
	if Dungeon.waveKind(wave) ~= "normal" then
		return nil
	end
	local late = if wave >= D.BudgetLateFrom then D.BudgetLateFactor else 1
	return math.min(math.floor((D.BudgetBase + D.BudgetPerWave * (wave - 1)) * late + 0.5), D.BudgetMax)
end

-- A def's stats on this dungeon level in this wave: HP and attack grow with the wave and with the level, defence and speed
-- stay as they are.
function Dungeon.scale(def: any, level: number, wave: number): typeof(Stats.starter())
	local factor = D.StatScale * D.WaveGrowth ^ (wave - 1) * D.LevelPower ^ (level - 1)
	return { attack = def.attack * factor, defence = def.defence, speed = def.speed, hp = def.hp * factor }
end

-- The level a monster shows: its scaled stats read as a slime's would, so it rises every wave.
function Dungeon.monsterLevel(def: any, level: number, wave: number): number
	return Stats.level(Dungeon.scale(def, level, wave))
end

local function monster(def: any, level: number, wave: number, id: string): Monster
	local stats = Dungeon.scale(def, level, wave)
	return {
		id = id,
		defId = def.id,
		name = def.name,
		defRole = def.role,
		kind = def.kind,
		attack = stats.attack,
		defence = stats.defence,
		speed = stats.speed,
		hp = stats.hp,
		level = Stats.level(stats),
	}
end

-- The monsters of one wave, in the order they come. Wave 5 is the mini-boss alone, wave 10 the boss alone; the others draw
-- from every def that is no mini-boss or boss until the budget is spent, and stop at the first def that would not fit
-- (it does not look for a cheaper one). The same seed makes the same wave.
function Dungeon.plan(mapId: string, level: number, wave: number, seed: number): { Monster }
	local defs: { any } = map(mapId).monsters
	local out: { Monster } = {}
	local kind = Dungeon.waveKind(wave)
	if kind ~= "normal" then
		for _, def in defs do
			if def.role == kind then
				table.insert(out, monster(def, level, wave, "m" .. wave .. "-1"))
				break
			end
		end
		return out
	end
	local pool: { any } = {}
	for _, def in defs do
		if def.role ~= "miniboss" and def.role ~= "boss" then
			table.insert(pool, def)
		end
	end
	local rng = Rng.new(seed + wave * D.WaveSeedStep)
	local left = Dungeon.budget(wave) :: number
	while #pool > 0 do
		local def = rng:pick(pool)
		if def.cost > left then
			break
		end
		left -= def.cost
		table.insert(out, monster(def, level, wave, "m" .. wave .. "-" .. (#out + 1)))
	end
	return out
end

-- ===== the arena =====

-- Where the next monster comes in, flat from the arena's middle: a random point of the edge band (SpawnMinFromCentre to
-- ArenaRadius - SpawnInset from the middle) at least SpawnMinApart from every point in `taken`. When SpawnTries tries find
-- no such point, the one that stood farthest from the others is taken.
function Dungeon.spawnPoint(rng: Rng, taken: { { x: number, z: number } }): (number, number)
	local outer = D.ArenaRadius - D.SpawnInset
	local bestX, bestZ, bestGap = 0, 0, -1
	for _ = 1, D.SpawnTries do
		local angle = rng:next() * math.pi * 2
		local radius = D.SpawnMinFromCentre + rng:next() * (outer - D.SpawnMinFromCentre)
		local x, z = math.sin(angle) * radius, -math.cos(angle) * radius
		local gap = math.huge
		for _, other in taken do
			gap = math.min(gap, math.sqrt((other.x - x) ^ 2 + (other.z - z) ^ 2))
		end
		if gap >= D.SpawnMinApart then
			return x, z
		end
		if gap > bestGap then
			bestX, bestZ, bestGap = x, z, gap
		end
	end
	return bestX, bestZ
end

-- The def of a monster by its id on a map (the plan's monsters carry the id only), nil when there is none.
function Dungeon.defOf(mapId: string, defId: string): any
	local defs: { any } = map(mapId).monsters
	for _, def in defs do
		if def.id == defId then
			return def
		end
	end
	return nil
end

-- Loot luck of a dungeon level: 1 at the first, more above.
function Dungeon.luck(level: number): number
	return 1 + D.LuckPerLevel * (level - 1)
end

-- A monster's own stream of rolls: its id and the run's seed, so a drop is the same however often it is asked for.
local function stream(enemyId: string, seed: number): Rng
	return Rng.new(Rng.hash(enemyId) + seed)
end

-- The row of windows a def rolls on, by its role.
local function lootRow(def: any): { any }
	local class = (D.LootClass :: any)[def.role] or "normal"
	return (D.Loot :: any)[class]
end

-- A monster's one regular drop (nil for nothing): the first window the roll falls in; the first window of its row is
-- stretched or shrunk by the level's luck (never past the next window).
function Dungeon.rollDrop(def: any, level: number, enemyId: string, seed: number): Drop?
	local row = lootRow(def)
	local rng = stream(enemyId, seed)
	local r = rng:next()
	local luck = Dungeon.luck(level)
	for index, window in row do
		local upTo = window.upTo
		if index == 1 and window.luck == "times" then
			upTo *= luck
		elseif index == 1 and window.luck == "over" then
			upTo /= luck
		end
		local nextUpTo = if row[index + 1] then row[index + 1].upTo else 1
		if r < math.min(upTo, nextUpTo) or index == #row then
			if not window.item then
				return nil
			end
			return { item = window.item, amount = rng:int(window.min, window.max) }
		end
	end
	return nil
end

-- The map's own material from a monster: a boss always gives BossMapMaterial, a mini-boss or an elite has a
-- MapMaterialChance of one, any other nothing. Returns the amount and the material's id.
function Dungeon.rollMapMaterial(def: any, enemyId: string, seed: number, mapId: string): (number, string)
	local material = map(mapId).material
	if def.role == "boss" then
		return D.BossMapMaterial, material
	end
	if not (D.MapMaterialRoles :: any)[def.role] then
		return 0, material
	end
	-- (the original's seed XOR 0x5bd1e995 for this roll)
	local salted = bit32.bxor(math.floor(seed) % 4294967296, 0x5bd1e995)
	return if Rng.new(Rng.hash(enemyId) + salted):next() < D.MapMaterialChance then 1 else 0, material
end

-- ===== the ledger =====

function Dungeon.newLedger(): Ledger
	return { waves = {} }
end

-- A drop waits in its wave's page. Refused (false) for an item that is not a drop, an amount that is not a whole number
-- above zero, or a wave that is already paid or lost.
function Dungeon.addDrop(ledger: Ledger, wave: number, drop: Drop): boolean
	if (D.Materials :: any)[drop.item] == nil or drop.amount < 1 or drop.amount % 1 ~= 0 then
		return false
	end
	local page = ledger.waves[wave]
	if not page then
		page = { state = "open", drops = {} }
		ledger.waves[wave] = page
	end
	if page.state ~= "open" then
		return false
	end
	page.drops[drop.item] = (page.drops[drop.item] or 0) + drop.amount
	return true
end

-- The wave is cleared: its drops reach the farm, once. Coins go to the purse (up to its ceiling, Zombies.pay), food into
-- the storehouse (what does not fit is lost), everything else into farm.materials. Nil when the wave was already paid or
-- lost; a wave with nothing in it pays nothing and is closed all the same.
function Dungeon.commitWave(farm: Farm, ledger: Ledger, wave: number): Paid?
	local page = ledger.waves[wave]
	if not page then
		page = { state = "open", drops = {} }
		ledger.waves[wave] = page
	end
	if page.state ~= "open" then
		return nil
	end
	page.state = "committed"
	local paid: Paid = { coins = 0, food = 0, lost = 0, materials = {} }
	for item, amount in page.drops do
		local kind = (D.Materials :: any)[item].kind
		if kind == "coins" then
			paid.coins += Zombies.pay(farm, amount)
		elseif kind == "food" then
			local moved =
				Food.add(farm.storehouse, D.FoodItem, amount, Food.storehouseCapacity(farm.areas.pantry.level))
			paid.food += moved
			paid.lost += amount - moved
		else
			farm.materials[item] = (farm.materials[item] or 0) + amount
			paid.materials[item] = amount
		end
	end
	return paid
end

-- The run was lost or left: the wave in play gives nothing (earlier waves were paid when they cleared). True when
-- something was dropped.
function Dungeon.discardWave(ledger: Ledger, wave: number): boolean
	local page = ledger.waves[wave]
	if not page then
		page = { state = "open", drops = {} }
		ledger.waves[wave] = page
	end
	if page.state ~= "open" then
		return false
	end
	page.state = "discarded"
	page.drops = {}
	return true
end

-- ===== the ladder =====

-- A dungeon level is open when it is a whole number from the first to one above the best cleared.
function Dungeon.canEnter(farm: Farm, level: number): boolean
	return type(level) == "number"
		and level % 1 == 0
		and level >= D.FirstLevel
		and level <= farm.dungeon.best + D.FirstLevel
end

-- A level was cleared: the best moves up when this is the best so far (and was open). True when it did.
function Dungeon.recordClear(farm: Farm, level: number): boolean
	if Dungeon.canEnter(farm, level) and level > farm.dungeon.best then
		farm.dungeon.best = level
		return true
	end
	return false
end

return Dungeon
