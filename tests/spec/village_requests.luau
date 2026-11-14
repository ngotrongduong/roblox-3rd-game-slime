--!strict
-- What a player's request may do: the shape it must have and the rules that guard coins and slimes.
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local Food = require("../../src/shared/Food")
local Village = require("../../src/shared/Village")
local VillageRequests = require("../../src/shared/VillageRequests")

local NOW = 1000000

-- A player standing everywhere, with nobody out; a test changes what it needs.
local function env(changes: { [string]: any }?): any
	local out: any = {
		isOut = function()
			return false
		end,
		atMarket = function()
			return true
		end,
		teamOut = function()
			return false
		end,
		atHome = function()
			return true
		end,
		recall = function() end,
		attack = function()
			return true, nil
		end,
		clearWounds = function() end,
		freeUpgrades = false,
	}
	for key, value in changes or {} do
		out[key] = value
	end
	return out
end

local function isOut()
	return true
end

local function refuse()
	return false
end

return function(T: any)
	T.test("a request of the wrong shape is refused", function()
		local maxDishes = Food.fridgeCapacity(Config.Village.MaxLevel)
		local bad: { any } = {
			{ action = "Nothing" },
			{ action = "SetPair", index = 1.5 },
			{ action = "SetPair", index = 1, a = 7 },
			{ action = "Assign", area = "fishing", slot = 1, slimeId = "slime-1" },
			{ action = "Sell", slimeId = 1 },
			{ action = "SellDish", dish = "grilledFish", count = 0 },
			{ action = "SellDish", dish = "grilledFish", count = 1.5 },
			{ action = "SellDish", dish = "grilledFish", count = 0 / 0 },
			{ action = "SellDish", dish = "grilledFish", count = math.huge },
			{ action = "SellDish", dish = "grilledFish", count = maxDishes + 1 },
			{ action = "FeedDish", slimeId = "slime-1" },
			{ action = "UpgradeArea", areaId = "not-an-area" },
			{ action = "SetTeam", team = 0, slimeIds = {} },
			{ action = "SetTeam", team = Config.Zombies.Teams + 1, slimeIds = {} },
			{ action = "SetTeam", team = 1, slimeIds = { 1 } },
			{ action = "SetTeam", team = 1, slimeIds = { a = "slime-1" } },
			{ action = "SetTeamRepeat", team = 1, on = "yes" },
			{ action = "AttackGroup", team = 1, groupId = string.rep("x", Config.Zombies.TargetIdMaxLength + 1) },
		}
		for index, data in bad do
			T.ok(not VillageRequests.valid(data, true), "bad request " .. index)
		end
		local tooMany = table.create(Config.Zombies.TeamSize + 1, "slime-1")
		T.ok(not VillageRequests.valid({ action = "SetTeam", team = 1, slimeIds = tooMany }, true))
	end)

	T.test("well-formed requests pass; no-plot requests need a plot", function()
		T.ok(VillageRequests.valid({ action = "SetPair", index = 1 }, false))
		T.ok(VillageRequests.valid({ action = "SellDish", dish = "grilledFish", count = 1 }, false))
		T.ok(VillageRequests.valid({ action = "SetAutoDish", slimeId = "slime-1" }, false))
		local upgrade = { action = "UpgradeArea", areaId = Config.Village.Areas[1] }
		T.ok(VillageRequests.valid(upgrade, true))
		T.ok(not VillageRequests.valid(upgrade, false))
		T.ok(not VillageRequests.valid({ action = "SetTeamRepeat", team = 1, on = true }, false))
	end)

	T.test("selling a slime needs the Market and a slime at home", function()
		local farm = FarmKit.farm(NOW)
		local coins, count = farm.coins, #farm.slimes
		local sell = { action = "Sell", slimeId = "slime-2" }
		T.eq(select(2, VillageRequests.run(farm, sell, NOW, env({ atMarket = refuse }))), "TOO_FAR")
		T.eq(select(2, VillageRequests.run(farm, sell, NOW, env({ isOut = isOut }))), "OUT")
		T.eq(farm.coins, coins)
		T.eq(#farm.slimes, count)
		local ok, _, paid = VillageRequests.run(farm, sell, NOW, env())
		T.ok(ok)
		T.eq(farm.coins, coins + (paid :: number))
		T.eq(#farm.slimes, count - 1)
	end)

	T.test("selling dishes needs the Market, respects the fridge and pays only what was held", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { grilledFish = 1 }
		local coins = farm.coins
		local sell = { action = "SellDish", dish = "grilledFish", count = 3 }
		T.eq(select(2, VillageRequests.run(farm, sell, NOW, env({ atMarket = refuse }))), "TOO_FAR")
		local over =
			{ action = "SellDish", dish = "grilledFish", count = Food.fridgeCapacity(farm.areas.kitchen.level) + 1 }
		T.eq(select(2, VillageRequests.run(farm, over, NOW, env())), "INVALID_ARGUMENT")
		T.eq(farm.fridge.grilledFish, 1)
		T.eq(farm.coins, coins)
		local ok, _, paid = VillageRequests.run(farm, sell, NOW, env())
		T.ok(ok)
		local rarity = (Config.Food.Dishes :: any).grilledFish.rarity
		T.eq(paid, (Config.Food.DishRarities :: any)[rarity].price, "one dish held, one dish paid")
		T.eq(farm.coins, coins + (paid :: number))
	end)

	T.test("a slime out on a march takes no orders", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { grilledFish = 1 }
		local out = env({ isOut = isOut })
		local requests: { any } = {
			{ action = "Assign", area = "fishing", slot = 1, slimeId = "slime-1", asReserve = false },
			{ action = "SetPair", index = 1, a = "slime-1", b = "slime-2" },
			{ action = "Revive", slimeId = "slime-1" },
		}
		for _, data in requests do
			T.eq(select(2, VillageRequests.run(farm, data, NOW, out)), "OUT", data.action)
		end
		T.eq(farm.work.fishing.slots[1].worker, nil)
		T.eq(farm.fridge.grilledFish, 1)
		-- but it is fed its dish out there (a team's sheet feeds each member)
		T.ok(VillageRequests.run(farm, { action = "FeedDish", slimeId = "slime-1", dish = "grilledFish" }, NOW, out))
		T.eq(farm.fridge.grilledFish or 0, 0)
	end)

	T.test("unassign knows the slime and frees its place", function()
		local farm = FarmKit.farm(NOW)
		T.eq(
			select(2, VillageRequests.run(farm, { action = "Unassign", slimeId = "nobody" }, NOW, env())),
			"MISSING_SLIME"
		)
		T.eq(
			select(2, VillageRequests.run(farm, { action = "Unassign", slimeId = "slime-1" }, NOW, env())),
			"NOT_ASSIGNED"
		)
		farm.work.fishing.slots[1].worker = "slime-1"
		T.ok(VillageRequests.run(farm, { action = "Unassign", slimeId = "slime-1" }, NOW, env()))
		T.eq(farm.work.fishing.slots[1].worker, nil)
	end)

	T.test("an upgrade costs its price unless free, and takes nothing when refused", function()
		local farm = FarmKit.farm(NOW)
		local area = Config.Village.Areas[1]
		local level = (farm.areas :: any)[area].level
		local price = Village.upgradeCost(level)
		local upgrade = { action = "UpgradeArea", areaId = area }
		farm.coins = price - 1
		T.eq(select(2, VillageRequests.run(farm, upgrade, NOW, env())), "NO_COINS")
		T.eq(farm.coins, price - 1)
		T.eq((farm.areas :: any)[area].level, level)
		farm.coins = price
		T.ok(VillageRequests.run(farm, upgrade, NOW, env()))
		T.eq(farm.coins, 0)
		T.eq((farm.areas :: any)[area].level, level + 1)
		T.ok(VillageRequests.run(farm, upgrade, NOW, env({ freeUpgrades = true })))
		T.eq(farm.coins, 0)
	end)

	T.test("a team explores from home until it is called back", function()
		local farm = FarmKit.farm(NOW)
		local go = { action = "SetTeamExplore", team = 1, band = 2 }
		T.ok(VillageRequests.valid(go, true))
		T.ok(not VillageRequests.valid(go, false))
		T.ok(not VillageRequests.valid({ action = "SetTeamExplore", team = 1, band = -1 }, true))
		T.ok(not VillageRequests.valid({ action = "SetTeamExplore", team = 1, band = 1.5 }, true))
		T.ok(not VillageRequests.valid({ action = "SetTeamExplore", team = 1, band = 99 }, true))
		T.eq(select(2, VillageRequests.run(farm, go, NOW, env())), "NO_MEMBERS")
		farm.teams[1].members = { "slime-1" }
		farm.teams[1].repeatOn = true
		T.eq(select(2, VillageRequests.run(farm, go, NOW, env({ atHome = refuse }))), "TOO_FAR")
		T.eq(select(2, VillageRequests.run(farm, go, NOW, env({ teamOut = isOut }))), "TEAM_OUT")
		farm.teams[2].members = { "slime-2" }
		T.eq(
			select(2, VillageRequests.run(farm, { action = "SetTeamExplore", team = 2, band = 1 }, NOW, env())),
			"LOCKED"
		)
		T.eq(farm.teams[1].explore, nil)
		T.ok(VillageRequests.run(farm, go, NOW, env()))
		T.eq(farm.teams[1].explore, 2)
		T.eq(farm.teams[1].repeatOn, false, "exploring replaces the repeat")
		-- called back from anywhere, even out: the server brings it home
		local called = 0
		local away = env({
			atHome = refuse,
			teamOut = isOut,
			recall = function(team: number)
				called = team
			end,
		})
		T.ok(VillageRequests.run(farm, { action = "SetTeamExplore", team = 1, band = 0 }, NOW, away))
		T.eq(farm.teams[1].explore, nil)
		T.eq(called, 1)
	end)

	T.test("a line-up is set at the team banner, only while the team is home", function()
		local farm = FarmKit.farm(NOW)
		local set = { action = "SetTeam", team = 1, slimeIds = {} }
		T.eq(select(1, VillageRequests.run(farm, set, NOW, env())), true)
		T.eq(select(2, VillageRequests.run(farm, set, NOW, env({ atHome = refuse }))), "TOO_FAR")
		T.eq(select(2, VillageRequests.run(farm, set, NOW, env({ teamOut = isOut }))), "TEAM_OUT")
		local again = { action = "SetTeamRepeat", team = 1, on = true }
		T.eq(select(2, VillageRequests.run(farm, again, NOW, env())), "NO_MEMBERS")
		T.eq(farm.teams[1].repeatOn, false)
	end)

	T.test("a revive clears the wounds only when it works", function()
		local farm = FarmKit.farm(NOW)
		local cleared = 0
		local watch = env({
			clearWounds = function()
				cleared += 1
			end,
		})
		local revive = { action = "Revive", slimeId = "slime-1" }
		T.eq(select(2, VillageRequests.run(farm, revive, NOW, watch)), "NOT_DEAD")
		T.eq(cleared, 0)
		farm.slimes[1].ghostUntil = NOW + 100
		farm.storehouse = { fish = 100 }
		T.ok(VillageRequests.run(farm, revive, NOW, watch))
		T.eq(cleared, 1)
	end)

	T.test("team sheet request shapes need a plot, a team number and their fields", function()
		local row = { action = "SetTeamRow", team = 1, slimeId = "s1", row = "back" }
		local tactic = { action = "SetTeamTactic", team = 1, tactic = "focus" }
		T.ok(VillageRequests.valid(row, true))
		T.ok(VillageRequests.valid(tactic, true))
		T.ok(not VillageRequests.valid(row, false))
		T.ok(not VillageRequests.valid(tactic, false))
		for _, bad in
			{
				{ action = "SetTeamRow", team = 0, slimeId = "s1", row = "front" },
				{ action = "SetTeamRow", team = 1.5, slimeId = "s1", row = "front" },
				{ action = "SetTeamRow", team = 1, slimeId = 55, row = "front" },
				{ action = "SetTeamRow", team = 1, slimeId = "s1", row = false },
				{ action = "SetTeamTactic", team = Config.Zombies.Teams + 1, tactic = "focus" },
				{ action = "SetTeamTactic", team = 1, tactic = 42 },
			}
		do
			T.ok(not VillageRequests.valid(bad, true), bad.action)
		end
	end)

	T.test("SetTeamRow validates membership and availability, and default rows clear overrides", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(4))
		farm.teams[1].members = { "s1", "s2" }
		farm.slimes[1].gear.hand = "bow-wood"
		local row = { action = "SetTeamRow", team = 1, slimeId = "s1", row = "back" }
		T.eq(select(2, VillageRequests.run(farm, { action = "SetTeamRow", team = 0 }, NOW, env())), "BAD_TEAM")
		local locked = { action = "SetTeamRow", team = 2, slimeId = "s1", row = "back" }
		T.eq(select(2, VillageRequests.run(farm, locked, NOW, env())), "LOCKED")
		T.eq(select(2, VillageRequests.run(farm, row, NOW, env({ teamOut = isOut }))), "TEAM_OUT")
		T.eq(
			select(
				2,
				VillageRequests.run(farm, { action = "SetTeamRow", team = 1, slimeId = "s3", row = "back" }, NOW, env())
			),
			"NO_SLIME"
		)
		T.eq(
			select(
				2,
				VillageRequests.run(farm, { action = "SetTeamRow", team = 1, slimeId = "s1", row = "side" }, NOW, env())
			),
			"BAD_ROW"
		)
		T.eq(farm.teams[1].formation, nil, "refusals did not write a choice")
		T.ok(VillageRequests.run(farm, row, NOW, env()))
		T.same(farm.teams[1].formation, { s1 = "back" })
		T.ok(VillageRequests.run(farm, { action = "SetTeamRow", team = 1, slimeId = "s1", row = "middle" }, NOW, env()))
		T.eq(farm.teams[1].formation, nil, "the bow's middle default is represented by absence")
	end)

	T.test("SetTeamTactic refuses invalid or away teams, and Balanced drops the field", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(4))
		farm.teams[1].members = { "s1" }
		local focus = { action = "SetTeamTactic", team = 1, tactic = "focus" }
		T.eq(select(2, VillageRequests.run(farm, { action = "SetTeamTactic", team = 0 }, NOW, env())), "BAD_TEAM")
		T.eq(
			select(2, VillageRequests.run(farm, { action = "SetTeamTactic", team = 2, tactic = "focus" }, NOW, env())),
			"LOCKED"
		)
		T.eq(select(2, VillageRequests.run(farm, focus, NOW, env({ teamOut = isOut }))), "TEAM_OUT")
		T.eq(
			select(2, VillageRequests.run(farm, { action = "SetTeamTactic", team = 1, tactic = "rush" }, NOW, env())),
			"BAD_TACTIC"
		)
		T.eq(farm.teams[1].tactic, nil)
		T.ok(VillageRequests.run(farm, focus, NOW, env()))
		T.eq(farm.teams[1].tactic, "focus")
		T.ok(VillageRequests.run(farm, { action = "SetTeamTactic", team = 1, tactic = "protect" }, NOW, env()))
		T.eq(farm.teams[1].tactic, "protect")
		T.ok(VillageRequests.run(farm, { action = "SetTeamTactic", team = 1, tactic = "balanced" }, NOW, env()))
		T.eq(farm.teams[1].tactic, nil)
	end)
end
