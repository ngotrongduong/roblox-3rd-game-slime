--!strict
-- The owner's debug presets: jumps to any stage of the game and single gifts, to save him replaying the first hour. Pure
-- farm rules, built from the game's own pieces (FarmState, Stations, Gear, Zombies, Hatching, Growth): every function
-- changes the farm table it is given in place, takes the server time `now` as an argument and leaves a farm that
-- FarmState.repair passes unchanged. The Studio-only server side is server/OwnerDebug (it keeps an undo copy and makes the
-- world follow); this module never touches Roblox.
-- It stays in the published place (it is harmless without OwnerDebug and UiDebug, which tools/build_publish.luau removes).
local Config = if script then require(script.Parent.Config) else require("./Config")
local DualDesigns = if script then require(script.Parent.DualDesigns) else require("./DualDesigns")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Colours = if script then require(script.Parent.Colours) else require("./Colours")
local Gear = if script then require(script.Parent.Gear) else require("./Gear")
local Genetics = if script then require(script.Parent.Genetics) else require("./Genetics")
local Growth = if script then require(script.Parent.Growth) else require("./Growth")
local Hatching = if script then require(script.Parent.Hatching) else require("./Hatching")
local Mutations = if script then require(script.Parent.Mutations) else require("./Mutations")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local SecretRecipes = if script then require(script.Parent.SecretRecipes) else require("./SecretRecipes")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")
local Zombies = if script then require(script.Parent.Zombies) else require("./Zombies")

type Farm = typeof(FarmState.newFarm(0))
type Slime = typeof(FarmState.newFarm(0).slimes[1])
type Appearance = typeof(Mutations.none())

local DebugPresets = {}

-- ===== the numbers of the debug menu (a test tool, so they live here and not in Config) =====
DebugPresets.Numbers = {
	-- the two coin gifts
	CoinsSmall = 10_000,
	CoinsBig = 1_000_000,
	-- how many of every dungeon material one "materials" tap gives
	MaterialsEach = 50,
	-- the highest slime level the menu makes (the stat limits allow more; this keeps every stat below its cap) and the most
	-- slimes one tap adds
	MaxLevel = 300,
	MaxAdd = 60,
	-- the level of the one Dual and the one Secret slime
	RareLevel = 10,
}
local N = DebugPresets.Numbers

-- The three stages. areaLevel: every area's level (so the village level); slimes and slimeLevel: how many grown slimes the
-- farm holds and the level they are; coins and materials (each dungeon material): what the farm holds; food: the storehouse
-- is filled; gearTier: the team members wear that tier's three pieces (and the bag holds one of every piece); dungeonBest:
-- the highest dungeon level cleared. Every open team is filled, in order, with four of the slimes.
local PRESETS = {
	early = {
		areaLevel = 5,
		slimes = 8,
		slimeLevel = 8,
		coins = 2_000,
		materials = 0,
		food = false,
		gearTier = nil,
		dungeonBest = 0,
	},
	mid = {
		areaLevel = 16,
		slimes = 20,
		slimeLevel = 30,
		coins = 50_000,
		materials = 30,
		food = true,
		gearTier = "iron",
		dungeonBest = 0,
	},
	late = {
		areaLevel = 40,
		slimes = 40,
		slimeLevel = 80,
		coins = 1_000_000,
		materials = 200,
		food = true,
		gearTier = "bramble",
		dungeonBest = 5,
	},
} :: {
	[string]: {
		areaLevel: number,
		slimes: number,
		slimeLevel: number,
		coins: number,
		materials: number,
		food: boolean,
		gearTier: string?,
		dungeonBest: number,
	},
}

-- ===== small helpers =====

-- The stats of a slime of exactly this level, spread evenly (hp counted per HpPerLevel, as the level formula does), each
-- stat inside its limit. A level below the starter's 4 is 4; above N.MaxLevel it is N.MaxLevel.
function DebugPresets.statsFor(level: number): typeof(Stats.starter())
	local clamped = math.clamp(math.floor(level), 4, N.MaxLevel)
	local points = clamped - 4
	local each, rest = points // 4, points % 4
	return {
		attack = 1 + each + (if rest >= 1 then 1 else 0),
		defence = 1 + each + (if rest >= 2 then 1 else 0),
		speed = 1 + each + (if rest >= 3 then 1 else 0),
		hp = Config.Stats.Starter.hp + Config.Stats.HpPerLevel * each,
	}
end

-- The birth time of a slime that is grown at any breeding level: one second more than its slowest grow-up ago.
local function grownAt(level: number, now: number): number
	return math.max(1, now - Growth.growUpSeconds(level, 0) - 1)
end

-- An id no slime of the farm has. (The server's own ids are "slime-n" and "egg-village-..."; these never meet them.)
local function newId(farm: Farm, now: number): string
	local n = #farm.slimes + 1
	while true do
		local id = string.format("dbg-%d-%d", math.floor(now), n)
		if not FarmState.findSlime(farm, id) then
			return id
		end
		n += 1
	end
end

-- Puts the kind in the Index when it is not there yet (the count of hatches, which sets the avatar's rank, is left alone).
local function discover(farm: Farm, appearance: Appearance, colour: string, now: number)
	if appearance.type == "none" then
		if farm.discoveries.base[colour] == nil then
			farm.discoveries = Hatching.registerBase(farm.discoveries, colour, now)
		end
		return
	end
	local id = appearance.definitionId
	local bucket = if appearance.type == "dual"
		then farm.discoveries.dual
		elseif appearance.type == "material" then farm.discoveries.material
		else farm.discoveries.secret
	if id and bucket[id] == nil then
		farm.discoveries = Hatching.registerDiscovery(farm.discoveries, appearance, now)
	end
end

-- A grown, rested slime of the given level in the given colour (or design), added to the farm. Returns it.
local function addSlime(farm: Farm, now: number, level: number, colour: string, appearance: Appearance?): Slime
	local design = appearance or Mutations.none()
	local genotype = Genetics.fromAppearance(design, Genetics.homozygous(colour))
	local visible = Genetics.visibleColour(design, genotype)
	local id = newId(farm, now)
	local seed = Rng.hash(id)
	local stats = DebugPresets.statsFor(level)
	local slime: Slime = {
		id = id,
		name = Hatching.nextName(farm),
		seed = seed,
		assetId = Mutations.assetId(design, visible),
		stats = stats,
		colourGenotype = genotype,
		visibleColour = visible,
		appearanceMutation = design,
		isFavourite = false,
		needs = FarmState.fullNeeds(),
		trait = FarmState.traitForSeed(seed),
		friends = {},
		buff = nil,
		autoDish = nil,
		ghostUntil = nil,
		createdAt = grownAt(level, now),
		breedReadyAt = 0,
		loadout = FarmState.emptyLoadout(),
		gear = FarmState.emptyGear(),
	}
	table.insert(farm.slimes, slime)
	discover(farm, design, visible, now)
	farm.lifetime.bestSlimeLevel = math.max(farm.lifetime.bestSlimeLevel, Stats.level(slime.stats))
	return slime
end

-- Cuts a stock to a capacity, in the order the game keeps it (the same cut FarmState.repair makes).
local function clampStock(stock: { [string]: number }, order: { string }, capacity: number)
	local left = capacity
	local loose: { [string]: number? } = stock
	for _, key in order do
		local keep = math.min(stock[key] or 0, left)
		loose[key] = if keep > 0 then keep else nil
		left -= keep
	end
end

-- The slots, pairs and stocks as many and as big as the area levels allow (an upgrade grows them; a lower level cuts them).
local function fitToLevels(farm: Farm)
	local work: any = farm.work
	for _, areaId in Config.Work.Areas do
		local slots = work[areaId].slots
		local want = FarmState.slotCount((farm.areas :: any)[areaId].level)
		while #slots < want do
			table.insert(slots, { progress = 0 })
		end
		while #slots > want do
			table.remove(slots)
		end
	end
	local pairs = farm.breeding.pairs
	local places = FarmState.breedingCount(farm.areas.breeding.level)
	while #pairs < places do
		table.insert(pairs, {})
	end
	while #pairs > places do
		table.remove(pairs)
	end
	clampStock(farm.storehouse, Config.Food.RawOrder, FarmState.storehouseCapacity(farm.areas.pantry.level))
	clampStock(farm.fridge, Config.Food.DishOrder, FarmState.fridgeCapacity(farm.areas.kitchen.level))
end

-- Everybody leaves their job, pair and team (the slimes are about to be replaced).
local function clearJobs(farm: Farm)
	local work: any = farm.work
	for _, areaId in Config.Work.Areas do
		local slots = work[areaId].slots
		for i = 1, #slots do
			slots[i] = { progress = 0 }
		end
	end
	for i = 1, #farm.breeding.pairs do
		farm.breeding.pairs[i] = {}
	end
	farm.teams = FarmState.newTeams()
end

-- Gear that legacy items claim for a slime that is gone goes back to the inventory.
local function releaseItems(farm: Farm)
	for _, item in farm.items do
		local own = item.ownership
		-- ("avatar" is the player's own slime, not a farm slime: it keeps its items)
		if
			own.kind == "EQUIPPED_TO_SLIME"
			and own.slimeId ~= nil
			and own.slimeId ~= "avatar"
			and FarmState.findSlime(farm, own.slimeId) == nil
		then
			item.ownership = { kind = "INVENTORY" }
		end
	end
end

-- The tutorial is over. `longAgo`: it ended before the new-player luck window, so luck is x1 (a preset is a stage of an old
-- farm, not a new player), and every intro counts as seen, so the screen stays clear.
local function finishGuide(farm: Farm, now: number, longAgo: boolean)
	local guide = farm.guide
	guide.step = "done"
	guide.mark = 0
	farm.tutorialDone = true
	farm.tutorialDoneAt = if longAgo then math.max(1, now - 2 * Config.Luck.WindowSeconds - 1) else now
	if longAgo then
		for _, id in Config.Guide.Intros do
			guide.seen[id] = true
		end
		guide.intro = nil
		guide.introMark = 0
	end
end

local function materialIds(): { string }
	local out = {}
	for _, id in Config.Dungeon.DropOrder do
		local entry: any = (Config.Dungeon.Materials :: any)[id]
		if entry and entry.kind == "material" then
			table.insert(out, id)
		end
	end
	return out
end

local function giveGearSet(farm: Farm)
	for _, id in Config.Smithy.GearOrder do
		farm.gear[id] = (farm.gear[id] or 0) + 1
	end
end

local function fillStorehouse(farm: Farm)
	local kinds = Config.Food.RawOrder
	local each = math.floor(FarmState.storehouseCapacity(farm.areas.pantry.level) / #kinds)
	for _, kind in kinds do
		(farm.storehouse :: any)[kind] = if each > 0 then each else nil
	end
end

-- Every open team gets four slimes, in order, from the farm's slimes.
local function fillTeams(farm: Farm, now: number)
	local at = 1
	for team = 1, Config.Zombies.Teams do
		if not Zombies.teamOpen(farm, team) then
			break
		end
		local ids = {}
		for _ = 1, Config.Zombies.TeamSize do
			local slime = farm.slimes[at]
			if not slime then
				break
			end
			table.insert(ids, slime.id)
			at += 1
		end
		if #ids > 0 then
			Zombies.setTeam(farm, team, ids, now, nil)
		end
	end
end

-- Every team member wears the three pieces of one tier (one more of each is made for it; the bag keeps its own).
local function wearTier(farm: Farm, tier: string)
	for _, team in farm.teams do
		for _, slimeId in team.members do
			for _, gearId in Config.Smithy.GearOrder do
				local def: any = Gear.get(gearId)
				if def and def.tier == tier then
					farm.gear[gearId] = (farm.gear[gearId] or 0) + 1
					Gear.equip(farm, slimeId, gearId)
				end
			end
		end
	end
end

-- ===== the presets =====

-- Sets the farm to a stage: "early", "mid" or "late". The slimes, eggs, jobs, pairs, teams and the gear bag are made again
-- (the old slimes' gear goes back first), the area levels, coins and materials are set to the stage's numbers (not added),
-- the tutorial is done. The Index and the lifetime counters keep what they had.
function DebugPresets.preset(farm: Farm, name: string, now: number): (boolean, string)
	local p = PRESETS[name]
	if not p then
		return false, "Unknown preset"
	end
	for _, slime in farm.slimes do
		FarmState.returnGear(farm, slime)
	end
	for _, id in Config.Village.Areas do
		(farm.areas :: any)[id].level = p.areaLevel
	end
	farm.eggs = {}
	farm.slimes = {}
	farm.gear = {}
	releaseItems(farm)
	clearJobs(farm)
	fitToLevels(farm)
	for i = 1, p.slimes do
		addSlime(farm, now, p.slimeLevel, Colours.Ids[(i - 1) % #Colours.Ids + 1], nil)
	end
	fillTeams(farm, now)
	farm.coins = p.coins
	for _, id in materialIds() do
		(farm.materials :: any)[id] = if p.materials > 0 then p.materials else nil
	end
	if p.gearTier then
		giveGearSet(farm)
		wearTier(farm, p.gearTier)
	end
	if p.food then
		fillStorehouse(farm)
	end
	farm.dungeon.best = p.dungeonBest
	finishGuide(farm, now, true)
	return true,
		string.format(
			"%s: village %d, %d slimes of level %d",
			string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2),
			FarmState.villageLevel(farm.areas),
			#farm.slimes,
			p.slimeLevel
		)
end

-- ===== single actions =====

function DebugPresets.addCoins(farm: Farm, amount: number): (boolean, string)
	-- (the vault's ceiling, Village.coinCap, limits fight income only; sales and gifts go over it, and so does this)
	farm.coins += math.max(0, math.floor(amount))
	return true, "+" .. math.floor(amount) .. " coins"
end

function DebugPresets.addMaterials(farm: Farm, amount: number): (boolean, string)
	local each = math.max(0, math.floor(amount))
	for _, id in materialIds() do
		farm.materials[id] = (farm.materials[id] or 0) + each
	end
	return true, "+" .. each .. " of every material"
end

function DebugPresets.addGear(farm: Farm): (boolean, string)
	giveGearSet(farm)
	return true, "One of every gear piece"
end

function DebugPresets.fillFood(farm: Farm): (boolean, string)
	fillStorehouse(farm)
	return true, "Storehouse filled"
end

-- Hunger, energy and fun full, everybody awake.
function DebugPresets.fillNeeds(farm: Farm): (boolean, string)
	for _, slime in farm.slimes do
		slime.needs = FarmState.fullNeeds()
		slime.sleeping = nil
	end
	return true, "Hunger and energy full"
end

-- Every timer the save holds runs out now: eggs are ready, babies are grown, parents have rested, courtships end (the egg
-- is laid at the next village step), a fisher's or trainee's cycle is complete, naps end, and a fallen slime is REVIVED (a
-- ghost whose time ran out would be lost for good, which is the opposite of what a test wants). Area upgrades have no
-- timer (they are paid with coins), so there is nothing to finish there.
function DebugPresets.finishTimers(farm: Farm, now: number): (boolean, string)
	local eggs, babies, ghosts, naps, courtships, cycles = 0, 0, 0, 0, 0, 0
	for _, egg in farm.eggs do
		if egg.hatchAt == nil or egg.hatchAt > now then
			eggs += 1
		end
		egg.hatchAt = math.max(egg.createdAt, math.min(egg.hatchAt or now, now))
		egg.status = FarmState.eggStatus(egg, now)
	end
	for _, slime in farm.slimes do
		local level = Stats.level(slime.stats)
		if Growth.isBaby(slime.createdAt, now, level, farm.areas.breeding.level - Config.Village.StartLevel) then
			babies += 1
		end
		slime.createdAt = math.max(1, math.min(slime.createdAt, grownAt(level, now)))
		slime.breedReadyAt = math.min(slime.breedReadyAt, now)
		if slime.ghostUntil ~= nil then
			ghosts += 1
			slime.ghostUntil = nil
			slime.needs = FarmState.fullNeeds()
		end
		if slime.sleeping then
			naps += 1
			slime.sleeping = nil
			slime.needs.energy = Config.Needs.Start
		end
	end
	for _, pair in farm.breeding.pairs do
		if pair.courtingUntil ~= nil and pair.courtingUntil > now then
			courtships += 1
			pair.courtingUntil = now
		end
	end
	local work: any = farm.work
	for _, areaId in { "fishing", "training" } do
		local level = (farm.areas :: any)[areaId].level
		for _, slot in work[areaId].slots do
			if slot.worker ~= nil and (areaId ~= "training" or slot.stat ~= nil) then
				cycles += 1
				slot.progress = math.max(slot.progress, Stations.cycleSeconds(areaId, level))
			end
		end
	end
	return true,
		string.format(
			"Timers done: %d eggs, %d babies, %d courtships, %d cycles, %d revived, %d naps",
			eggs,
			babies,
			courtships,
			cycles,
			ghosts,
			naps
		)
end

-- Adds `count` grown slimes of `level` in plain colours (one after the other through the eleven colours). The population
-- limit is not asked (a test tool), only the repair's hard cap.
function DebugPresets.addSlimes(farm: Farm, now: number, count: any, level: any): (boolean, string)
	if type(count) ~= "number" or type(level) ~= "number" or count ~= count or level ~= level then
		return false, "Bad numbers"
	end
	local howMany = math.floor(count)
	if howMany < 1 or howMany > N.MaxAdd then
		return false, "From 1 to " .. N.MaxAdd .. " slimes"
	end
	if #farm.slimes + howMany > Config.Farm.RepairSlimeHardCap then
		return false, "Too many slimes"
	end
	local made = math.clamp(math.floor(level), 4, N.MaxLevel)
	for _ = 1, howMany do
		addSlime(farm, now, made, Colours.Ids[#farm.slimes % #Colours.Ids + 1], nil)
	end
	return true, string.format("+%d slimes of level %d", howMany, made)
end

-- The first design (or recipe) no slime of the farm shows yet, else the next one round.
local function pickRare(farm: Farm, kind: string): (string, { string })
	local list: { { id: string, parentPair: { string } } } = if kind == "dual"
		then DualDesigns.List :: any
		else SecretRecipes.List :: any
	local used: { [string]: boolean } = {}
	for _, slime in farm.slimes do
		if slime.appearanceMutation.type == kind and slime.appearanceMutation.definitionId then
			used[slime.appearanceMutation.definitionId] = true
		end
	end
	for _, row in list do
		if not used[row.id] then
			return row.id, row.parentPair
		end
	end
	local row = list[#farm.slimes % #list + 1]
	return row.id, row.parentPair
end

-- One Dual or Secret slime ("dual" or "secret") of the next design the farm does not show, valid by the game's own pools.
function DebugPresets.addRare(farm: Farm, now: number, kind: string): (boolean, string)
	if kind ~= "dual" and kind ~= "secret" then
		return false, "Unknown kind"
	end
	if #farm.slimes + 1 > Config.Farm.RepairSlimeHardCap then
		return false, "Too many slimes"
	end
	local id, pair = pickRare(farm, kind)
	local slime = addSlime(farm, now, N.RareLevel, pair[1], { type = kind, definitionId = id } :: any)
	return true, string.format("Added %s (%s)", slime.name, id)
end

-- Skips the tutorial the way its Skip button does (the new-player luck starts now).
function DebugPresets.skipGuide(farm: Farm, now: number): (boolean, string)
	finishGuide(farm, now, false)
	return true, "Tutorial skipped"
end

-- Starts the tutorial again from its first step (the intros come back too).
function DebugPresets.resetGuide(farm: Farm): (boolean, string)
	farm.tutorialDone = false
	farm.tutorialDoneAt = nil
	farm.guide = FarmState.newGuide(false)
	return true, "Tutorial reset"
end

-- ===== the menu =====
-- What the Studio panel shows, in order: groups of items. `kind`: "farm" runs here (DebugPresets.run); "undo", "fresh" and
-- "travel" are done by the server (OwnerDebug) because they need the stored copy, a new farm or the character; "arena" goes
-- to the Arena service's debug calls (server/Arena, through OwnerDebug). `args` are sent
-- with the tap. `danger` draws the red button.
DebugPresets.Menu = {
	{
		group = "Presets",
		items = {
			{ id = "early", text = "Early", kind = "farm" },
			{ id = "mid", text = "Mid", kind = "farm" },
			{ id = "late", text = "Late", kind = "farm" },
			{ id = "undo", text = "Undo", kind = "undo" },
		},
	},
	{
		group = "Give",
		items = {
			{ id = "coins_small", text = "+10K coins", kind = "farm" },
			{ id = "coins_big", text = "+1M coins", kind = "farm" },
			{ id = "materials", text = "Materials +50", kind = "farm" },
			{ id = "gear", text = "Gear set", kind = "farm" },
			{ id = "food", text = "Fill food", kind = "farm" },
		},
	},
	{
		group = "Time",
		items = {
			{ id = "timers", text = "Finish timers", kind = "farm" },
			{ id = "needs", text = "Fill needs", kind = "farm" },
		},
	},
	{
		group = "Slimes",
		items = {
			{ id = "slimes", text = "+5 Lv 10", kind = "farm", args = { count = 5, level = 10 } },
			{ id = "slimes", text = "+5 Lv 40", kind = "farm", args = { count = 5, level = 40 } },
			{ id = "slimes", text = "+10 Lv 100", kind = "farm", args = { count = 10, level = 100 } },
			{ id = "dual", text = "+1 Dual", kind = "farm" },
			{ id = "secret", text = "+1 Secret", kind = "farm" },
		},
	},
	{
		group = "Guide",
		items = {
			{ id = "guide_skip", text = "Skip tutorial", kind = "farm" },
			{ id = "guide_reset", text = "Reset tutorial", kind = "farm" },
		},
	},
	{
		-- (kind "arena": server/OwnerDebug hands it to server/Arena's Studio-only debug calls)
		group = "Arena",
		items = {
			{ id = "arena_team", text = "Team: best 4", kind = "arena" },
			{ id = "arena_opponents", text = "Opponents", kind = "arena" },
			{ id = "arena_attack", text = "Attack 1st", kind = "arena" },
			{ id = "arena_state", text = "Arena state", kind = "arena" },
			{ id = "arena_tickets", text = "Tickets 10", kind = "arena" },
			{ id = "arena_rank", text = "Rank 1", kind = "arena", args = { rank = 1 } },
			{ id = "arena_rank", text = "Rank 7", kind = "arena", args = { rank = 7 } },
			{ id = "arena_rank", text = "Rank 50", kind = "arena", args = { rank = 50 } },
			{ id = "arena_points", text = "+1000 Arena points", kind = "arena" },
			{ id = "arena_end_season", text = "End season", kind = "arena" },
			{ id = "arena_clock_reset", text = "Clock reset", kind = "arena" },
			{ id = "arena_fake", text = "Fake servers x5", kind = "arena" },
			{ id = "arena_pause", text = "Pause leader", kind = "arena" },
		},
	},
	{
		group = "Go to",
		items = {
			{ id = "Market", text = "Market", kind = "travel" },
			{ id = "Home", text = "Home", kind = "travel" },
			{ id = "Portal", text = "Dungeon portal", kind = "travel" },
		},
	},
	{
		group = "Danger",
		items = {
			{ id = "fresh", text = "Fresh farm", kind = "fresh", danger = true },
		},
	},
} :: {
	{
		group: string,
		items: { { id: string, text: string, kind: string, args: { [string]: any }?, danger: boolean? } },
	}
}

-- Runs one "farm" action of the menu on the farm. Returns whether it ran and the line to show. Never throws on a bad id.
function DebugPresets.run(farm: Farm, id: any, now: number, args: any): (boolean, string)
	if type(id) ~= "string" then
		return false, "Bad action"
	end
	if PRESETS[id] then
		return DebugPresets.preset(farm, id, now)
	elseif id == "coins_small" then
		return DebugPresets.addCoins(farm, N.CoinsSmall)
	elseif id == "coins_big" then
		return DebugPresets.addCoins(farm, N.CoinsBig)
	elseif id == "materials" then
		return DebugPresets.addMaterials(farm, N.MaterialsEach)
	elseif id == "gear" then
		return DebugPresets.addGear(farm)
	elseif id == "food" then
		return DebugPresets.fillFood(farm)
	elseif id == "timers" then
		return DebugPresets.finishTimers(farm, now)
	elseif id == "needs" then
		return DebugPresets.fillNeeds(farm)
	elseif id == "slimes" then
		local a = if type(args) == "table" then args else {}
		return DebugPresets.addSlimes(farm, now, a.count, a.level)
	elseif id == "dual" or id == "secret" then
		return DebugPresets.addRare(farm, now, id)
	elseif id == "guide_skip" then
		return DebugPresets.skipGuide(farm, now)
	elseif id == "guide_reset" then
		return DebugPresets.resetGuide(farm)
	end
	return false, "Unknown action"
end

return DebugPresets
