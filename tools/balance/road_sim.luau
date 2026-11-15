--!nocheck
-- The road from village level 1 to 50 against the owner's times (2026-11-15: the first 20 levels within about an hour,
-- the next ten in 2-4 hours, every level after that slower than the one before). It solves the upgrade price of every
-- area level from what a typical village earns at that point, then walks the real prices (Village.upgradeCost) with
-- three kinds of player and prints when each reaches level 10, 20, 30, 40 and 50, the coin vault against every price,
-- the Smithy's prices and the Dungeon's coins beside them.
--   lune run tools/balance/road_sim.luau [solve]
-- ("solve" also prints the solved price of every level, to choose Config.Village.UpgradePrices' anchors from)
--
-- What is measured: coins a fight (WorldPacks.killReward over the Sunny Meadow's roster, the same as pack_sim's won
-- fights), fights an hour of a team on Repeat (early_game_sim: an 80 s cycle with its marches, heals and naps = 45),
-- training (Training.gainChance, Stations.cycleSeconds and speedTimeFactor), slimes and dishes sold (income_sim and
-- kitchen_sim, docs/ECONOMY.md).
-- What is assumed (a play test moves these, and every price with them):
--   * a team fights packs of its own level, FIGHTS_PER_TEAM_HOUR times an hour (between Repeat's 45 and an exploring
--     team's 37, which walks a minute and more between packs);
--   * a new team is at full use five village levels after it opens (it needs four grown slimes first);
--   * the fighters' level follows the training ground: TRAIN_SHARE of the levels its slots can give reach the teams
--     (training, then breeding the trained, then swapping the babies in). 0 never trains, 0.5 does little else;
--   * half the babies and dishes a village could sell are sold.
local process = require("@lune/process")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Stations = require("../../src/shared/Stations")
local Training = require("../../src/shared/Training")
local Village = require("../../src/shared/Village")
local WorldPacks = require("../../src/shared/WorldPacks")

local AREAS = #Config.Village.Areas
local MAX = Config.Village.MaxLevel

-- ===== the owner's road =====
-- Minutes a village level takes: the first FIRST_MINUTES, each next one EARLY_GROWTH times longer up to level 20, then
-- LATE_GROWTH times longer. 0.6 x 1.155 ^ n sums to 56 min over levels 1-19 (the tutorial's first minutes make the
-- hour); from 20 on, 12 % a level makes the ten levels 20-29 take 2.7 h, 30-39 8.5 h and 40-49 26 h.
local FIRST_MINUTES = 0.6
local EARLY_GROWTH = 1.155
local LATE_GROWTH = 1.12
local LATE_FROM = 20

local function targetMinutes(level: number): number
	if level < LATE_FROM then
		return FIRST_MINUTES * EARLY_GROWTH ^ (level - 1)
	end
	return FIRST_MINUTES * EARLY_GROWTH ^ (LATE_FROM - 1) * LATE_GROWTH ^ (level - LATE_FROM)
end

-- ===== the player =====
local FIGHTS_PER_TEAM_HOUR = 40
local TEAM_RAMP_LEVELS = 5
local PRODUCTIVE = 0.55
local SOLD_SHARE = 0.5
local PLAYERS = { { "never trains", 0 }, { "typical", 0.25 }, { "trains hard", 0.5 } }
local TYPICAL = 0.25
-- coins an hour by village level: every baby sold (income_sim) and every dish sold with the fighters fed (kitchen_sim B)
local SLIME_SALES = { { 1, 3500 }, { 10, 9400 }, { 20, 9900 }, { 30, 11400 }, { 40, 10000 }, { 50, 14000 } }
local DISH_SALES = { { 1, 1500 }, { 10, 4000 }, { 20, 6000 }, { 30, 20600 }, { 40, 44000 }, { 50, 42800 } }

local function lerp(points: { { number } }, at: number): number
	for index = 2, #points do
		local low, high = points[index - 1], points[index]
		if at <= high[1] then
			return low[2] + (high[2] - low[2]) * (at - low[1]) / (high[1] - low[1])
		end
	end
	return points[#points][2]
end

-- Coins of a won fight against a pack of this level: the average pack of the Sunny Meadow.
local function packCoins(level: number): number
	local roster = WorldPacks.roster("meadow")
	local sum = 0
	for _, def in roster do
		sum += WorldPacks.killReward(def.role, level)
	end
	local P = Config.World.Packs
	return sum / #roster * (P.SizeMin + P.SizeMax) / 2
end

-- Teams in use: the first, and each later one growing to full use over TEAM_RAMP_LEVELS village levels.
local function teams(level: number): number
	local sum = 1
	for index = 2, #Config.Zombies.TeamOpensAt do
		sum += math.clamp((level - Config.Zombies.TeamOpensAt[index] + 1) / TEAM_RAMP_LEVELS, 0, 1)
	end
	return sum
end

-- Levels an hour the training ground's slots give slimes of this level (even stats), at this area level.
local function trainRate(slimeLevel: number, level: number): number
	local value = slimeLevel / 4
	local chance = Training.gainChance("attack", value, level, 1)
	local seconds = Stations.cycleSeconds("training", level) * Stations.speedTimeFactor(value) / PRODUCTIVE
	return FarmState.slotCount(level) * chance * 3600 / seconds
end

local function packLevel(slimeLevel: number): number
	local P = Config.World.Packs
	return math.clamp(math.floor(slimeLevel), P.LevelMin, P.LevelMax)
end

local function fightIncome(level: number, slimeLevel: number): number
	return teams(level) * FIGHTS_PER_TEAM_HOUR * packCoins(packLevel(slimeLevel))
end

local function income(level: number, slimeLevel: number): number
	return fightIncome(level, slimeLevel) + SOLD_SHARE * (lerp(SLIME_SALES, level) + lerp(DISH_SALES, level))
end

local START_LEVEL = Config.Stats.Starter.attack
	+ Config.Stats.Starter.defence
	+ Config.Stats.Starter.speed
	+ Config.Stats.Starter.hp / Config.Stats.HpPerLevel

-- ===== the solve: a typical player on the target road =====
if process.args[1] == "solve" then
	print("SOLVED from the target road, a typical player (anchors for Config.Village.UpgradePrices are chosen from these)")
	print("area level | minutes this level | slimes' level | teams | income/h | price | village reached at (h)")
	local slimeLevel, clock = START_LEVEL, 0
	for level = 1, MAX - 1 do
		local minutes = targetMinutes(level)
		local earning = income(level, slimeLevel)
		local price = earning * minutes / 60 / AREAS
		clock += minutes
		print(
			string.format(
				"%4d | %7.1f | %5.0f | %4.1f | %8.0f | %8.0f | %2d at %6.2f",
				level,
				minutes,
				slimeLevel,
				teams(level),
				earning,
				price,
				level + 1,
				clock / 60
			)
		)
		slimeLevel += trainRate(slimeLevel, level) * TYPICAL * minutes / 60
	end
	print("")
end

-- ===== the real prices, walked =====
local STEP_MINUTES = 0.5
local MARKS = { 5, 10, 20, 30, 40, 50 }

local function walk(share: number)
	local slimeLevel, clock = START_LEVEL, 0
	local reached: { [number]: number } = {}
	local rows = {}
	for level = 1, MAX - 1 do
		local price = Village.upgradeCost(level)
		local need = price * AREAS
		local started = clock
		local earningAtStart = income(level, slimeLevel)
		local levelAtStart = slimeLevel
		while need > 0 do
			need -= income(level, slimeLevel) * STEP_MINUTES / 60
			slimeLevel += trainRate(slimeLevel, level) * share * STEP_MINUTES / 60
			clock += STEP_MINUTES
		end
		reached[level + 1] = clock / 60
		rows[level] = { price = price, minutes = clock - started, earning = earningAtStart, slimeLevel = levelAtStart }
	end
	return reached, rows
end

print(string.format("THE REAL PRICES (Config.Village.UpgradePrices), %d fights an hour a team, packs of the team's own level", FIGHTS_PER_TEAM_HOUR))
local typicalRows
print("village level reached at (hours) |     5     10     20     30     40     50")
for _, player in PLAYERS do
	local reached, rows = walk(player[2])
	if player[2] == TYPICAL then
		typicalRows = rows
	end
	local line = string.format("%-32s |", string.format("%s (share %.2f)", player[1], player[2]))
	for _, mark in MARKS do
		line ..= string.format(" %6.2f", reached[mark])
	end
	print(line)
end
print(
	string.format(
		"target                           | %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f",
		(function()
			local out = {}
			for _, mark in MARKS do
				local sum = 0
				for level = 1, mark - 1 do
					sum += targetMinutes(level)
				end
				table.insert(out, sum / 60)
			end
			return table.unpack(out)
		end)()
	)
)

print("\nThe typical player, level by level")
print("area level | price | income/h | slimes' level | teams | this village level takes | one upgrade | vault / price | vault fills in")
local total = 0
for level = 1, MAX - 1 do
	local row = typicalRows[level]
	total += row.price
	if level <= 2 or level % 5 == 0 or level == 19 or level == 29 or level == 39 or level == 49 then
		local cap = Village.coinCap(level)
		print(
			string.format(
				"%4d | %7d | %8.0f | %4.0f | %3.1f | %7.1f min | %6.1f min | %4.1f | %5.1f min",
				level,
				row.price,
				row.earning,
				row.slimeLevel,
				teams(level),
				row.minutes,
				row.minutes / AREAS,
				cap / row.price,
				cap / (fightIncome(level, row.slimeLevel) / 60)
			)
		)
	end
end
print(string.format("one area, 1 to %d: %d coins; the whole village: %d coins", MAX, total, total * AREAS))

-- ===== the Smithy beside the road =====
-- A piece's price against the upgrade price and the typical income at the village level its tier is made at
-- (CRAFT_AT: wood with the Dungeon's door, the others where their materials are first within reach).
local CRAFT_AT = { wood = 15, iron = 20, core = 27, bramble = 34, legend = 42 }
print("\nThe Smithy: a piece's coins beside the road (sword of each tier)")
print("tier | coins | made at village level | upgrades it equals there | minutes of typical income | fits the vault there")
for _, tier in Config.Smithy.TierOrder do
	local recipe = Config.Smithy.Recipes["sword-" .. tier]
	local at = CRAFT_AT[tier]
	local row = typicalRows[at]
	print(
		string.format(
			"%-8s | %7d | %2d | %5.2f | %5.1f | %s",
			tier,
			recipe.coins,
			at,
			recipe.coins / row.price,
			recipe.coins / (row.earning / 60),
			if recipe.coins <= Village.coinCap(at) then "yes" else "NO"
		)
	)
end
