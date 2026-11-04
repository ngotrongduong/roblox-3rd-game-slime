--!strict
-- The first-time tutorial and the intros of later features (docs/GAMEPLAY.md §12): what each step says, what it points at,
-- and the real farm state that finishes it. The server runs it once a second (server/Guide) and publishes the step on the
-- village folder; the client only draws it (client/UiGuide). The order of both lists is Config.Guide's.
--
-- A step is finished by the farm itself (a worker at the pond, an egg laid, coins from a fight), by where the character
-- stands (env), by the player opening a screen the server cannot see (`ui`: the client says so) or by a Next tap (`tip`).
-- Skip ends the tutorial at once; the close button puts an intro away for good. Finishing or skipping the tutorial starts
-- the new-player luck (shared/Luck), as in the original.
local Breeding = if script then require(script.Parent.Breeding) else require("./Breeding")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Rewards = if script then require(script.Parent.Rewards) else require("./Rewards")
local Stations = if script then require(script.Parent.Stations) else require("./Stations")
local VillageRules = if script then require(script.Parent.Village) else require("./Village")
local Zombies = if script then require(script.Parent.Zombies) else require("./Zombies")

type Farm = typeof(FarmState.newFarm(0))

-- What only the server knows: where the player's character stands.
export type Env = { atMarket: boolean, atHome: boolean }

-- What the client draws: the line, what it points at (client/UiGuide reads the target), and the buttons.
export type View = { id: string, kind: string, line: string, target: string, next: boolean }

type Step = {
	line: string,
	-- "hud:<button>", "spot:<area>", "breeding", "banner", "market", "group", "pad" (the cheapest) or "pad:<area>"
	target: string,
	-- the line while the step cannot be done yet
	wait: string?,
	blocked: ((Farm, number) -> boolean)?,
	ui: boolean?,
	tip: boolean?,
	-- the number the check measures from, taken when the step opens (`previous` is the last step's)
	mark: ((Farm, number) -> number)?,
	done: ((Farm, Env, number, number) -> boolean)?,
}

type Intro = {
	line: string,
	target: string,
	-- whether the feature matters now; while it does not, the intro is not shown
	when: (Farm, number) -> boolean,
	mark: ((Farm) -> number)?,
	done: (Farm, number, number) -> boolean,
}

local Guide = {}

Guide.Done = "done"

-- ===== what the checks look at =====

local function hasWorker(farm: Farm, area: string): boolean
	for _, slot in (farm.work :: any)[area].slots do
		if slot.worker ~= nil then
			return true
		end
	end
	return false
end

local function hasPair(farm: Farm): boolean
	for _, pair in farm.breeding.pairs do
		if pair.a ~= nil and pair.b ~= nil then
			return true
		end
	end
	return false
end

local function isGhost(slime: any, now: number): boolean
	return slime.ghostUntil ~= nil and slime.ghostUntil > now
end

-- A grown, living slime with no job, no pair and no team: one the player can give something to do.
local function hasFreeAdult(farm: Farm, now: number): boolean
	for _, slime in farm.slimes do
		if
			not isGhost(slime, now)
			and not Breeding.isBaby(farm, slime, now)
			and not Stations.isBusy(farm, slime.id)
			and not FarmState.inPair(farm, slime.id)
			and FarmState.teamOf(farm, slime.id) == nil
		then
			return true
		end
	end
	return false
end

local function hasBaby(farm: Farm, now: number): boolean
	for _, slime in farm.slimes do
		if Breeding.isBaby(farm, slime, now) then
			return true
		end
	end
	return false
end

local function ghosts(farm: Farm, now: number): number
	local count = 0
	for _, slime in farm.slimes do
		if isGhost(slime, now) then
			count += 1
		end
	end
	return count
end

local function hasTeam(farm: Farm): boolean
	for _, team in farm.teams do
		if #team.members > 0 then
			return true
		end
	end
	return false
end

local function levelSum(farm: Farm): number
	local total = 0
	for _, id in Config.Village.Areas do
		total += (farm.areas :: any)[id].level
	end
	return total
end

-- The price of the cheapest upgrade the village can still buy.
local function cheapestUpgrade(farm: Farm): number
	local best = math.huge
	for _, id in Config.Village.Areas do
		local level = (farm.areas :: any)[id].level
		if level < Config.Village.MaxLevel then
			best = math.min(best, VillageRules.upgradeCost(level))
		end
	end
	return best
end

local function hasDish(farm: Farm): boolean
	for _, count in farm.fridge do
		if count > 0 then
			return true
		end
	end
	return false
end

local function coinsEarned(farm: Farm): number
	return farm.lifetime.coinsEarned
end

-- ===== the tutorial =====

local steps: { [string]: Step } = {
	book = { line = "Meet your slimes! Tap the slime book.", target = "hud:slimes", ui = true },
	fish = {
		line = "Slimes need food: pick a fisher at the pond.",
		target = "spot:fishing",
		done = function(farm)
			return hasWorker(farm, "fishing")
		end,
	},
	garden = {
		line = "Now pick a gardener at the garden.",
		target = "spot:garden",
		done = function(farm)
			return hasWorker(farm, "garden")
		end,
	},
	food = { line = "Fish and vegetables fill your storehouse. Tap Food.", target = "hud:food", ui = true },
	pair = {
		line = "Pair your two free slimes at the breeding house.",
		target = "breeding",
		done = function(farm)
			return hasPair(farm)
		end,
	},
	egg = {
		line = "They court, then lay an egg. Watch!",
		target = "breeding",
		mark = function(farm)
			return farm.lifetime.breeds
		end,
		done = function(farm, _, mark)
			return farm.lifetime.breeds > mark or #farm.eggs > 0
		end,
	},
	hatch = {
		line = "The egg hatches in the incubator. Your first baby!",
		target = "breeding",
		mark = function(farm)
			return #farm.slimes
		end,
		done = function(farm, _, mark, now)
			return #farm.slimes > mark or hasBaby(farm, now)
		end,
	},
	market = {
		line = "Tap Market to travel there.",
		target = "hud:market",
		done = function(_, env)
			return env.atMarket
		end,
	},
	sell = { line = "Sell spare slimes and dishes here for coins.", target = "market", tip = true },
	home = {
		line = "Tap Home to go back.",
		target = "hud:home",
		done = function(_, env)
			return env.atHome
		end,
	},
	pads = { line = "Coins upgrade your farm: step on a pad.", target = "pad", tip = true },
	team = {
		line = "Make a team at the banner by the gate.",
		target = "banner",
		wait = "Your baby grows up soon, then team it up at the banner.",
		blocked = function(farm, now)
			return not hasTeam(farm) and not hasFreeAdult(farm, now)
		end,
		done = function(farm)
			return hasTeam(farm)
		end,
	},
	attack = {
		line = "Walk to a zombie group and send your team!",
		target = "group",
		mark = coinsEarned,
		done = function(farm, _, mark)
			for _, team in farm.teams do
				if team.target ~= nil then
					return true
				end
			end
			return coinsEarned(farm) > mark
		end,
	},
	win = {
		line = "Your team fights by itself. Every zombie pays coins!",
		target = "group",
		-- (measured from when the team was sent: coins that came in that first second count)
		mark = function(_, previous)
			return previous
		end,
		done = function(farm, _, mark)
			return coinsEarned(farm) > mark
		end,
	},
}

-- ===== the intros =====

local function teamIntro(index: number): Intro
	return {
		line = "Team " .. index .. " is open! Fill it at the banner.",
		target = "banner",
		when = function(farm)
			return Zombies.teamOpen(farm, index) and #farm.teams[index].members == 0
		end,
		done = function(farm)
			return #farm.teams[index].members > 0
		end,
	}
end

local intros: { [string]: Intro } = {
	ghost = {
		line = "A slime fell! Tap the skull and revive it with food.",
		target = "hud:skull",
		when = function(farm, now)
			return ghosts(farm, now) > 0
		end,
		done = function(farm, _, now)
			return ghosts(farm, now) == 0
		end,
	},
	vault = {
		line = "The vault is full! Upgrade the pantry to hold more coins.",
		target = "pad:pantry",
		when = function(farm)
			return farm.coins >= VillageRules.coinCap(farm.areas.pantry.level)
		end,
		mark = function(farm)
			return farm.areas.pantry.level
		end,
		done = function(farm, mark)
			return farm.areas.pantry.level > mark
		end,
	},
	full = {
		line = "Your village is full. Sell spare slimes at the Market.",
		target = "hud:market",
		when = function(farm)
			return #farm.slimes + #farm.eggs >= VillageRules.populationLimit(farm)
		end,
		done = function(farm)
			return #farm.slimes + #farm.eggs < VillageRules.populationLimit(farm)
		end,
	},
	upgrade = {
		line = "You have the coins! Step on a pad to upgrade.",
		target = "pad",
		when = function(farm)
			return farm.coins >= cheapestUpgrade(farm)
		end,
		mark = levelSum,
		done = function(farm, mark)
			return levelSum(farm) > mark
		end,
	},
	["repeat"] = {
		line = "Turn on Repeat at the banner: your team keeps fighting.",
		target = "banner",
		when = function(farm)
			return hasTeam(farm) and coinsEarned(farm) > 0
		end,
		done = function(farm)
			for _, team in farm.teams do
				if team.repeatOn then
					return true
				end
			end
			return false
		end,
	},
	team2 = teamIntro(2),
	team3 = teamIntro(3),
	team4 = teamIntro(4),
	kitchen = {
		line = "Give the kitchen a cook. Dishes make fighters stronger.",
		target = "spot:kitchen",
		when = function(farm, now)
			return not hasWorker(farm, "kitchen") and hasFreeAdult(farm, now)
		end,
		done = function(farm)
			return hasWorker(farm, "kitchen")
		end,
	},
	dish = {
		line = "A dish is ready! Tap Food and feed it to a fighter.",
		target = "hud:food",
		when = hasDish,
		done = function(farm, _, now)
			for _, slime in farm.slimes do
				if slime.autoDish ~= nil or (slime.buff ~= nil and slime.buff.untilTime > now) then
					return true
				end
			end
			return false
		end,
	},
	training = {
		line = "Train a slime here to raise its stats.",
		target = "spot:training",
		when = function(farm, now)
			return not hasWorker(farm, "training") and hasFreeAdult(farm, now)
		end,
		done = function(farm)
			return hasWorker(farm, "training")
		end,
	},
	rewards = {
		line = "A gift waits! Tap the trophy: daily gifts, quests and play rewards.",
		target = "hud:rewards",
		when = function(farm, now)
			return Rewards.ready(farm, now) > 0
		end,
		done = function(farm)
			return Rewards.everClaimed(farm)
		end,
	},
	index = {
		line = "A new kind of slime! See every kind you found in the Index.",
		target = "hud:slimes",
		when = function(farm)
			return Rewards.found(farm) > 1
		end,
		done = function(farm)
			return farm.rewards.indexSeen
		end,
	},
	dungeon = {
		line = "The Dungeon is open! Step into the portal.",
		target = "portal",
		-- only once the farm may go in (Config.Dungeon.EnterMinSlimes, EnterMinVillageLevel)
		when = function(farm)
			return hasTeam(farm)
				and #farm.slimes >= Config.Dungeon.EnterMinSlimes
				and FarmState.villageLevel(farm.areas) >= Config.Dungeon.EnterMinVillageLevel
		end,
		done = function(farm)
			return farm.dungeon.best >= 1
		end,
	},
	recipes = {
		line = "New recipes! Choose one at a cook's spot.",
		target = "spot:kitchen",
		when = function(farm)
			return farm.areas.kitchen.level >= Config.Food.DishRarities.uncommon.kitchenLevel
				and hasWorker(farm, "kitchen")
		end,
		done = function(farm)
			for _, slot in farm.work.kitchen.slots do
				local recipe = (slot :: any).recipe
				if recipe ~= nil and recipe ~= Config.Food.DefaultRecipe then
					return true
				end
			end
			return false
		end,
	},
}

-- Every id in Config.Guide has its words and checks here (the spec holds this).
function Guide.known(): (boolean, string?)
	for _, id in Config.Guide.Steps do
		if not steps[id] then
			return false, id
		end
	end
	for _, id in Config.Guide.Intros do
		if not intros[id] then
			return false, id
		end
	end
	return true, nil
end

-- ===== moving on =====

local function finish(farm: Farm, now: number)
	farm.guide.step = Guide.Done
	farm.guide.mark = 0
	farm.tutorialDone = true
	farm.tutorialDoneAt = now
end

-- The step after the current one opens (with its mark), or the tutorial ends.
local function advance(farm: Farm, now: number)
	local at = table.find(Config.Guide.Steps, farm.guide.step)
	local nextId = if at then Config.Guide.Steps[at + 1] else nil
	if not nextId then
		finish(farm, now)
		return
	end
	local step = steps[nextId]
	farm.guide.mark = if step.mark then step.mark(farm, farm.guide.mark) else 0
	farm.guide.step = nextId
end

-- Moves the tutorial on as far as the farm already allows (a rejoin can pass several steps at once), then opens, closes or
-- finishes an intro. Returns whether anything changed.
function Guide.update(farm: Farm, now: number, env: Env): boolean
	local guide = farm.guide
	local changed = false
	for _ = 1, #Config.Guide.Steps do
		local step = steps[guide.step]
		if not step or not step.done or not step.done(farm, env, guide.mark, now) then
			break
		end
		advance(farm, now)
		changed = true
	end
	if guide.step ~= Guide.Done then
		return changed
	end
	local openId = guide.intro
	local open = if openId then intros[openId] else nil
	if open and openId then
		if open.done(farm, guide.introMark, now) then
			guide.seen[openId] = true
			guide.intro = nil
			guide.introMark = 0
			changed = true
		elseif not open.when(farm, now) then
			-- (it no longer matters: put away unseen, so it can come back when it does)
			guide.intro = nil
			guide.introMark = 0
			changed = true
		end
		return changed
	end
	for _, id in Config.Guide.Intros do
		local intro = intros[id]
		if not guide.seen[id] and intro.when(farm, now) then
			guide.intro = id
			guide.introMark = if intro.mark then intro.mark(farm) else 0
			return true
		end
	end
	return changed
end

-- Whether update would change anything, without changing the farm (the server asks this every second before it writes).
function Guide.pending(farm: Farm, now: number, env: Env): boolean
	local probe: any = table.clone(farm)
	local guide = table.clone(farm.guide)
	guide.seen = table.clone(farm.guide.seen)
	probe.guide = guide
	return Guide.update(probe, now, env)
end

-- The player opened the screen a `ui` step waits for.
function Guide.seen(farm: Farm, id: string, now: number): (boolean, string?)
	local step = steps[id]
	if farm.guide.step ~= id or not step or not step.ui then
		return false, "NOT_THIS_STEP"
	end
	advance(farm, now)
	return true, nil
end

-- The player tapped Next on a `tip` step.
function Guide.next(farm: Farm, id: string, now: number): (boolean, string?)
	local step = steps[id]
	if farm.guide.step ~= id or not step or not step.tip then
		return false, "NOT_THIS_STEP"
	end
	advance(farm, now)
	return true, nil
end

-- Skip: ends the tutorial at once, or puts the intro on screen away for good.
function Guide.skip(farm: Farm, now: number): (boolean, string?)
	local guide = farm.guide
	local introId = guide.intro
	if guide.step ~= Guide.Done then
		finish(farm, now)
		return true, nil
	elseif introId then
		guide.seen[introId] = true
		guide.intro = nil
		guide.introMark = 0
		return true, nil
	end
	return false, "NOTHING_TO_SKIP"
end

-- What the client draws now, nil when nothing is shown.
function Guide.view(farm: Farm, now: number): View?
	local guide = farm.guide
	if guide.step ~= Guide.Done then
		local step = steps[guide.step]
		if not step then
			return nil
		end
		local waiting = step.blocked ~= nil and step.blocked(farm, now)
		return {
			id = guide.step,
			kind = "tutorial",
			line = if waiting and step.wait then step.wait else step.line,
			target = step.target,
			next = step.tip == true,
		}
	end
	local introId = guide.intro
	local intro = if introId then intros[introId] else nil
	if intro and introId then
		return { id = introId, kind = "intro", line = intro.line, target = intro.target, next = false }
	end
	return nil
end

return Guide
