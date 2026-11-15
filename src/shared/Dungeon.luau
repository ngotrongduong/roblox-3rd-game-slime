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
	-- its specials (keys of Config.Combat.Skills), taken in turn by Combat
	skills: { string }?,
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

-- The four group materials ("basics"), one a map: the ones the clear bonus counts.
local BASICS: { [string]: boolean } = {}
for _, each in D.Maps :: { [string]: any } do
	BASICS[each.basic] = true
end

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

-- ===== monster levels =====

-- The band of monster levels dungeon level `level` draws from, low and high (Config.Dungeon BandSize: 1-10 hold
-- FirstBandLow..FirstBandHigh, 11-20 hold 10-20, 21-30 20-30, ...).
function Dungeon.band(level: number): (number, number)
	if level <= D.BandSize then
		return D.FirstBandLow, D.FirstBandHigh
	end
	local low = D.BandSize * math.floor((level - 1) / D.BandSize)
	return low, low + D.BandSize
end

-- The main monster level of a dungeon level: the level itself, past the first band; in it, FirstBandLow on level 1 rising
-- evenly to FirstBandHigh on level BandSize.
function Dungeon.mainLevel(level: number): number
	if level > D.BandSize then
		return level
	end
	local step = (D.FirstBandHigh - D.FirstBandLow) / (D.BandSize - 1)
	return math.floor(D.FirstBandLow + (level - 1) * step + 0.5)
end

-- The power of a monster's level (Config.Dungeon.PowerCurve): straight between its points, the end ones held past the ends.
function Dungeon.power(level: number): number
	local curve: { { number } } = D.PowerCurve
	if level <= curve[1][1] then
		return curve[1][2]
	end
	for index = 2, #curve do
		local low, high = curve[index - 1], curve[index]
		if level <= high[1] then
			return low[2] + (high[2] - low[2]) * (level - low[1]) / (high[1] - low[1])
		end
	end
	return curve[#curve][2]
end

-- The stats of a monster of this level and role in this wave: an even slime of the level (every stat level / 4, HP
-- x HpPerLevel, as the world's packs) times its role's RoleFactor and the power of `runLevel` (its own level when left
-- out), HP times RoleHp, attack and HP x WaveGrowth^(wave - 1).
function Dungeon.stats(level: number, role: string?, wave: number, runLevel: number?): typeof(Stats.starter())
	local factor = (D.RoleFactor :: any)[role or ""] or D.RoleFactor.swarmer
	local share = level / #Stats.Keys * factor * Dungeon.power(runLevel or level)
	local grow = D.WaveGrowth ^ (wave - 1)
	return {
		attack = share * grow,
		defence = share,
		speed = share,
		hp = math.max(1, share * Config.Stats.HpPerLevel * ((D.RoleHp :: any)[role or ""] or 1) * grow),
	}
end

-- One monster of a wave, of this level (the one it shows). `power` multiplies its HP and attack once more (a common monster
-- standing guard over a zone: shared/ZoneFights). `runLevel`: the level whose power it takes (Dungeon.plan: the run's main
-- level, so the whole run is as strong as the fit measured and a boss above it never steps into the next tier's power).
function Dungeon.monster(def: any, level: number, wave: number, id: string, power: number?, runLevel: number?): Monster
	local stats = Dungeon.stats(level, def.role, wave, runLevel)
	if power then
		stats.attack *= power
		stats.hp *= power
	end
	return {
		id = id,
		defId = def.id,
		name = def.name,
		defRole = def.role,
		kind = def.kind,
		skills = def.skills,
		attack = stats.attack,
		defence = stats.defence,
		speed = stats.speed,
		hp = stats.hp,
		level = level,
	}
end

-- The monsters of one wave of dungeon level `level`, in the order they come. Wave 5 is the mini-boss alone (MiniBossAbove the
-- main level), wave 10 the boss alone (BossAbove); the others draw from every def that is no mini-boss or boss until the
-- budget is spent, and stop at the first def that would not fit (it does not look for a cheaper one). A crowd's monster
-- stands within NearSpread of the main level NearShare of the time, else anywhere in the level's band; never on wave 1, and
-- at most one a wave above the near levels. The same seed makes the same wave.
function Dungeon.plan(mapId: string, level: number, wave: number, seed: number): { Monster }
	local defs: { any } = map(mapId).monsters
	local out: { Monster } = {}
	local kind = Dungeon.waveKind(wave)
	local main = Dungeon.mainLevel(level)
	if kind ~= "normal" then
		local above = if kind == "boss" then D.BossAbove else D.MiniBossAbove
		for _, def in defs do
			if def.role == kind then
				table.insert(out, Dungeon.monster(def, main + above, wave, "m" .. wave .. "-1", nil, main))
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
	local low, high = Dungeon.band(level)
	local left = Dungeon.budget(wave) :: number
	local over = false
	while #pool > 0 do
		local def = rng:pick(pool)
		-- (every monster spends the same three rolls, so one monster's level never moves another's)
		local near = rng:next() < D.NearShare
		local offset = rng:int(-D.NearSpread, D.NearSpread)
		local spread = rng:int(low, high)
		if def.cost > left then
			break
		end
		left -= def.cost
		local at = math.clamp(main + offset, low, high)
		if not near and wave > 1 then
			if spread <= main + D.NearSpread then
				at = spread
			elseif not over then
				at, over = spread, true
			end
		end
		table.insert(out, Dungeon.monster(def, at, wave, "m" .. wave .. "-" .. (#out + 1), nil, main))
	end
	return out
end

-- ===== the arena =====

-- Where the next monster comes in, flat from the arena's middle: a random point of the edge band (SpawnMinFromCentre to
-- ArenaRadius - SpawnInset from the middle) at least SpawnMinApart from every point in `taken`. When SpawnTries tries find
-- no such point, the one that stood farthest from the others is taken. `inner` and `outer` give another band (a zone's
-- fight in the open keeps to the flat middle of its pad).
function Dungeon.spawnPoint(
	rng: Rng,
	taken: { { x: number, z: number } },
	inner: number?,
	outer: number?
): (number, number)
	local from = inner or D.SpawnMinFromCentre
	local to = outer or (D.ArenaRadius - D.SpawnInset)
	local bestX, bestZ, bestGap = 0, 0, -1
	for _ = 1, D.SpawnTries do
		local angle = rng:next() * math.pi * 2
		local radius = from + rng:next() * (to - from)
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

-- Where squad member `index` of `count` starts, flat from the arena's middle: a row across the middle, SquadBack studs
-- toward the player (the side PlayerSpot is on), every other slime a little further in. The server places the fighters
-- here and the client stands the bodies here, so both agree.
function Dungeon.squadSpot(index: number, count: number): (number, number)
	local spot = D.PlayerSpot
	local length = math.sqrt(spot.x * spot.x + spot.z * spot.z)
	local toX, toZ = 0, 1
	if length > 1e-3 then
		toX, toZ = spot.x / length, spot.z / length
	end
	local view = Config.Zombies.View
	local along = (index - (count + 1) / 2) * view.FormationSpacing
	local back = D.View.SquadBack - (index % 2) * view.FormationStagger
	return -toZ * along + toX * back, toX * along + toZ * back
end

-- The team sheet's rows face the monsters: the middle and back rows stand further towards the player.
-- Keep squadSpot above for the old client and balance runner until they adopt the new list.
function Dungeon.squadSpots(rows: { string }): { { x: number, z: number } }
	local spot = D.PlayerSpot
	local length = math.sqrt(spot.x * spot.x + spot.z * spot.z)
	local toX, toZ = 0, 1
	if length > 1e-3 then
		toX, toZ = spot.x / length, spot.z / length
	end
	local spots: { { x: number, z: number } } = {}
	for index, row in Zombies.rowSpots(rows) do
		local back = D.View.SquadBack + row.back
		spots[index] = { x = -toZ * row.across + toX * back, z = toX * row.across + toZ * back }
	end
	return spots
end

-- The def of a monster by its id (the plan's monsters carry the id only): looked for on this map first, then on the others
-- (the Heart's guards come from every map); nil when there is none.
function Dungeon.defOf(mapId: string, defId: string): any
	for _, def in map(mapId).monsters :: { any } do
		if def.id == defId then
			return def
		end
	end
	for _, other in D.Maps :: { [string]: any } do
		for _, def in other.monsters :: { any } do
			if def.id == defId then
				return def
			end
		end
	end
	return nil
end

-- A monster's own stream of rolls: its id and the run's seed, so a drop is the same however often it is asked for.
local function stream(enemyId: string, seed: number): Rng
	return Rng.new(Rng.hash(enemyId) + seed)
end

-- The chance of a Loot line on dungeon level `level` (the steps of Config.Dungeon.Loot): the last step that starts at or below
-- the level, rising evenly to its `chanceTo` at its `to`.
local function chanceAt(steps: { any }, level: number): number
	local found: any = nil
	for _, step in steps do
		if step.from <= level then
			found = step
		end
	end
	if not found then
		return 0
	end
	if found.to then
		return found.chance
			+ (found.chanceTo - found.chance) * (math.min(level, found.to) - found.from) / (found.to - found.from)
	end
	return found.chance
end

-- The materials a monster of this role may drop on a run of `level` in map `mapId`: lines { item, chance, min, max }, the
-- map's own "basic" and "trophy" named. A line is listed even when its chance is 0 here, so the rolls of a stream never shift.
function Dungeon.lootLines(mapId: string, role: string, level: number): { any }
	local found = map(mapId)
	local out: { any } = {}
	for _, line in D.Loot.Lines :: { any } do
		if line.role == (if role == "miniboss" or role == "boss" then role else "regular") then
			local item = if line.item == "basic" or line.item == "trophy" then found[line.item] else line.item
			table.insert(out, { item = item, chance = chanceAt(line.chance, level), min = line.min, max = line.max })
		end
	end
	return out
end

-- Every drop of a fallen monster: the lines of its def (coins, food), then, when `mapId` is given (a Dungeon run; a zone's
-- fight gives only the def's lines), the materials of Loot. Each line is rolled on its own and always spends its two numbers
-- from the monster's stream, hit or not, so one line never moves another's roll.
function Dungeon.rollDrops(def: any, level: number, enemyId: string, seed: number, mapId: string?): { Drop }
	local out: { Drop } = {}
	local rng = stream(enemyId, seed)
	local lines: { any } = table.clone(def.drops or {})
	if mapId then
		local loot = Dungeon.lootLines(mapId, def.role, level)
		table.move(loot, 1, #loot, #lines + 1, lines)
	end
	for _, line in lines do
		local r = rng:next()
		local amount = rng:int(line.min, line.max)
		if r < line.chance then
			table.insert(out, { item = line.item, amount = amount })
		end
	end
	return out
end

-- What a Dungeon run of `mapId` at `level` may drop, as the range of each item: { [item] = { min, max } }. The gate sheet
-- lists it. Items whose chance is 0 at this level are left out.
function Dungeon.dropTable(mapId: string, level: number): { [string]: { number } }
	local found: { [string]: { number } } = {}
	local function add(line: any)
		local seen = found[line.item]
		if seen then
			seen[1], seen[2] = math.min(seen[1], line.min), math.max(seen[2], line.max)
		elseif line.chance > 0 then
			found[line.item] = { line.min, line.max }
		end
	end
	for _, def in map(mapId).monsters :: { any } do
		for _, line in def.drops do
			add(line)
		end
		for _, line in Dungeon.lootLines(mapId, def.role, level) do
			add(line)
		end
	end
	return found
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
-- lost; a wave with nothing in it pays nothing and is closed all the same. `now` (server seconds) lets VIP and a Gold Potion
-- multiply the coins; left out, they are paid unboosted.
function Dungeon.commitWave(farm: Farm, ledger: Ledger, wave: number, now: number?): Paid?
	local page = ledger.waves[wave]
	if not page then
		page = { state = "open", drops = {} }
		ledger.waves[wave] = page
	end
	if page.state ~= "open" then
		return nil
	end
	page.state = "committed"
	-- (the quests and goals of Rewards count the waves cleared)
	farm.lifetime.dungeonWaves += 1
	local paid: Paid = { coins = 0, food = 0, lost = 0, materials = {} }
	for item, amount in page.drops do
		local kind = (D.Materials :: any)[item].kind
		if kind == "coins" then
			paid.coins += Zombies.pay(farm, amount, now)
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
	if wave == D.Waves then
		-- the clear bonus: the basics the run collected (the waves paid before and this one) grow by ClearBonus
		local basics: { [string]: number } = {}
		for _, each in ledger.waves do
			if each.state == "committed" then
				for item, amount in each.drops do
					if BASICS[item] then
						basics[item] = (basics[item] or 0) + amount
					end
				end
			end
		end
		for item, amount in basics do
			local bonus = math.floor(amount * D.Loot.ClearBonus + 0.5)
			farm.materials[item] = (farm.materials[item] or 0) + bonus
			paid.materials[item] = (paid.materials[item] or 0) + bonus
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

-- The highest dungeon level open to a player whose best is `best`: the checkpoint above it (Config.Dungeon CheckpointEvery),
-- never past MaxLevel.
function Dungeon.maxOpen(best: number): number
	return math.min(D.MaxLevel, D.CheckpointEvery * (math.floor(best / D.CheckpointEvery) + 1))
end

-- Where Next Checkpoint goes from `level`: the next multiple of CheckpointEvery above it, if that is open, else the highest
-- open level (no higher than `level` when nothing above is open).
function Dungeon.nextCheckpoint(level: number, best: number): number
	return math.max(
		level,
		math.min(D.CheckpointEvery * (math.floor(level / D.CheckpointEvery) + 1), Dungeon.maxOpen(best))
	)
end

-- A dungeon level is open when it is a whole number from the first to the highest open (maxOpen).
function Dungeon.canEnter(farm: Farm, level: number): boolean
	return type(level) == "number"
		and level % 1 == 0
		and level >= D.FirstLevel
		and level <= Dungeon.maxOpen(farm.dungeon.best)
end

-- A dungeon id the player may pick.
function Dungeon.isMap(mapId: any): boolean
	return type(mapId) == "string" and (D.Maps :: any)[mapId] ~= nil
end

-- Why this farm may not go into the Dungeon at all: "FEW_SLIMES" or "VILLAGE_LEVEL"; nil when it may.
function Dungeon.entryBlock(farm: Farm): string?
	if #farm.slimes < D.EnterMinSlimes then
		return "FEW_SLIMES"
	elseif FarmState.villageLevel(farm.areas) < D.EnterMinVillageLevel then
		return "VILLAGE_LEVEL"
	end
	return nil
end

-- A level of dungeon `mapId` was cleared: that dungeon's record and the shared best move up when this beats them (and the
-- level was open). True when the best moved.
function Dungeon.recordClear(farm: Farm, mapId: string, level: number): boolean
	if not Dungeon.canEnter(farm, level) or not Dungeon.isMap(mapId) then
		return false
	end
	local dungeon = farm.dungeon
	dungeon.maps[mapId] = math.max(dungeon.maps[mapId] or 0, level)
	if level > dungeon.best then
		dungeon.best = level
		return true
	end
	return false
end

return Dungeon
