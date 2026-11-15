--!strict
-- Cooking spices (the owner, 2026-11-15): the store, the Lasting and Legendary dishes, batches, no selling, the rebuff rule
-- of auto-feed, the "all" buff in a fight and the schema 16 -> 17 migration.
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Food = require("../../src/shared/Food")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local Stations = require("../../src/shared/Stations")
local VillageRequests = require("../../src/shared/VillageRequests")
local VillageSim = require("../../src/shared/VillageSim")
local Zombies = require("../../src/shared/Zombies")

local NOW = 1000000

local function env(atMarket: boolean): any
	return {
		atMarket = function()
			return atMarket
		end,
	}
end

return function(T: any)
	T.test(
		"BuySpice takes the coins and adds the spices in one step; short coins, the cap and a bad count change nothing",
		function()
			local farm = FarmKit.farm(NOW)
			T.same(farm.spices, { honey = 0, truffle = 0, saffron = 0 })
			farm.coins = 1000
			T.eq(Shop.buySpice(farm, "honey", 2), 1000)
			T.eq(farm.coins, 0)
			T.eq(farm.spices.honey, 2)
			T.eq(select(2, Shop.buySpice(farm, "honey", 1)), "NO_COINS")
			T.eq(select(2, Shop.buySpice(farm, "pepper", 1)), "UNKNOWN_SPICE")
			for _, bad in { 0, 11, 1.5, -1, 0 / 0 } do
				T.eq(select(2, Shop.buySpice(farm, "honey", bad)), "INVALID_COUNT")
			end
			farm.coins = 1e9
			farm.spices.honey = Config.Food.SpiceCap - 2
			T.eq(select(2, Shop.buySpice(farm, "honey", 3)), "FULL")
			T.eq(farm.spices.honey, Config.Food.SpiceCap - 2)
			T.eq(farm.coins, 1e9)
			T.eq(Shop.buySpice(farm, "honey", 2), 1000)
			T.eq(farm.spices.honey, Config.Food.SpiceCap)
		end
	)

	T.test("the BuySpice request has its shape, needs the Market and pays through Shop", function()
		T.ok(VillageRequests.valid({ action = "BuySpice", spice = "saffron", count = 10 }, false))
		for _, bad in
			{
				{ spice = 1, count = 1 },
				{ spice = "honey", count = 0 },
				{ spice = "honey", count = 11 },
				{ spice = "honey", count = 1.5 },
				{ spice = "honey" },
			}
		do
			bad.action = "BuySpice"
			T.ok(not VillageRequests.valid(bad, false))
		end
		local farm = FarmKit.farm(NOW)
		farm.coins = 80000
		local data = { action = "BuySpice", spice = "saffron", count = 2 }
		local ok, why = VillageRequests.run(farm, data, NOW, env(false))
		T.ok(not ok and why == "TOO_FAR")
		T.eq(farm.coins, 80000)
		local ok2, _, paid = VillageRequests.run(farm, data, NOW, env(true))
		T.ok(ok2)
		T.eq(paid, 80000)
		T.eq(farm.spices.saffron, 2)
		T.eq(farm.coins, 0)
	end)

	T.test("spices are not raw food: not eaten, not a revive meal, not in the storehouse", function()
		local farm = FarmKit.farm(NOW)
		farm.spices.saffron = 5
		farm.storehouse = {}
		T.eq(Food.add(farm.storehouse, "saffron", 3, 100), 0)
		T.eq(Food.total(farm.storehouse), 0)
		T.eq(Food.cheapestRaw({ saffron = 5, honey = 5 }), nil)
		T.eq(Food.eat(farm, "slime-1", NOW), nil)
		T.eq(select(2, Food.feed(farm, "slime-1", "saffron", NOW)), "UNKNOWN_DISH")
		farm.slimes[1].ghostUntil = NOW + Config.Village.GhostSeconds
		T.ok(not Zombies.revive(farm, "slime-1", NOW))
		T.eq(farm.spices.saffron, 5)
	end)

	T.test("a spice dish needs its kitchen level and cooks a batch of four from the spice shelf", function()
		T.ok(not Food.recipeUnlocked("lastingStew", 9))
		T.ok(Food.recipeUnlocked("lastingStew", 10))
		T.ok(not Food.recipeUnlocked("lastingStewII", 24))
		T.ok(Food.recipeUnlocked("lastingStewII", 25))
		T.ok(not Food.recipeUnlocked("saffronBanquet", 44))
		T.ok(Food.recipeUnlocked("saffronBanquet", 45))
		T.eq(Food.cookSeconds("lastingStew", 1), 240)
		local farm = FarmKit.farm(NOW)
		farm.areas.kitchen.level = 9
		T.ok(not Stations.setCookRecipe(farm, 1, "lastingStew"))
		farm.areas.kitchen.level = 45
		T.ok(Stations.setCookRecipe(farm, 1, "goldenCarpRoyale"))
		farm.work.kitchen.slots[1].worker = "slime-1"
		farm.counter = { goldenCarp = 1, salmon = 1 }
		local idle = VillageSim.step(farm, NOW + 1000, 1000, Rng.new(1), { errands = false })
		T.same(idle.work.kitchen.box, {}, "no saffron, no cook")
		T.same(idle.counter, { goldenCarp = 1, salmon = 1 })
		farm.spices.saffron = 1
		local cooked = VillageSim.step(farm, NOW + 1000, 1000, Rng.new(1), { errands = false })
		T.eq(cooked.work.kitchen.box.goldenCarpRoyale, 4)
		T.eq(cooked.spices.saffron, 0)
		T.same(cooked.counter, {})
		T.eq(cooked.lifetime.dishesCooked, 4)
		-- the fridge's room still holds: only what fits is cooked
		local tight = FarmKit.farm(NOW)
		tight.areas.kitchen.level = 45
		tight.fridge = { grilledFish = Food.fridgeCapacity(45) - 2 }
		T.eq(Food.cookYield(tight, "saffronBanquet"), 2)
		T.eq(Food.cookYield(tight, "grilledFish"), 1)
	end)

	T.test("a cook is asked for the raw part of a spice dish only, and only while a spice is held", function()
		local farm = FarmKit.farm(NOW)
		farm.areas.kitchen.level = 10
		farm.work.kitchen.slots[1] = { worker = "slime-1", progress = 0, recipe = "lastingStew" }
		farm.storehouse = { trout = 5, carrot = 5, fish = 5 }
		T.same(Food.ingredientsWanted(farm), {})
		farm.spices.honey = 1
		T.same(Food.ingredientsWanted(farm), { trout = 1, carrot = 1 })
	end)

	T.test("spice dishes cannot be sold: buying, cooking and selling never makes coins", function()
		T.ok(Food.sellable("grilledFish"))
		T.ok(Food.sellable("goldenBanquet"))
		T.ok(not Food.sellable("lastingStew"))
		T.ok(not Food.sellable("lastingStewII"))
		T.ok(not Food.sellable("saffronStarTart"))
		T.ok(not Food.sellable("nothing"))
		local farm = FarmKit.farm(NOW)
		farm.coins = 0
		farm.fridge = { goldenCarpRoyale = 4, lastingStew = 4 }
		local ok, why =
			VillageRequests.run(farm, { action = "SellDish", dish = "goldenCarpRoyale", count = 4 }, NOW, env(true))
		T.ok(not ok and why == "NOT_SELLABLE")
		T.eq(select(2, Shop.sellDish(farm, "lastingStew", 1)), "NOT_SELLABLE")
		T.eq(farm.coins, 0)
		T.same(farm.fridge, { goldenCarpRoyale = 4, lastingStew = 4 })
	end)

	T.test("a dish buff stays one per slime and the new dish brings its own numbers", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { lastingStew = 1, saffronStarTart = 1 }
		T.ok(Food.feed(farm, "slime-1", "lastingStew", NOW))
		T.same(farm.slimes[1].buff, { stat = "all", percent = 3, untilTime = NOW + 3600, dish = "lastingStew" })
		T.ok(Food.feed(farm, "slime-1", "saffronStarTart", NOW + 10))
		T.same(
			farm.slimes[1].buff,
			{ stat = "speed", percent = 20, untilTime = NOW + 10 + 1500, dish = "saffronStarTart" }
		)
		-- an "all" buff survives a save and a load
		farm.slimes[1].buff = { stat = "all", percent = 5, untilTime = NOW + 100, dish = "lastingStewII" }
		T.same(FarmState.repair(farm, NOW).slimes[1].buff, farm.slimes[1].buff)
	end)

	T.test("auto-feed takes a buff dish only when the buff has 10% or less left, else raw food, else waits", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { grilledFish = 3 }
		farm.storehouse = { fish = 2 }
		T.ok(Food.setAutoDish(farm, "slime-1", "grilledFish"))
		local slime = farm.slimes[1]
		T.eq(Food.chooseMeal(farm, "slime-1", NOW), "grilledFish", "no buff: the dish")
		slime.buff = { stat = "attack", percent = 4, untilTime = NOW + 500, dish = "grilledFish" }
		local item, from = Food.chooseMeal(farm, "slime-1", NOW)
		T.eq(item, "fish")
		T.eq(from, "storehouse")
		slime.buff.untilTime = NOW + 60
		T.eq(Food.chooseMeal(farm, "slime-1", NOW), "grilledFish", "exactly 10% left: rebuff")
		slime.buff.untilTime = NOW + 61
		farm.storehouse = {}
		T.eq(Food.chooseMeal(farm, "slime-1", NOW), nil, "fresh buff and no raw food: it waits")
		slime.buff.untilTime = NOW - 1
		T.eq(Food.chooseMeal(farm, "slime-1", NOW), "grilledFish", "an ended buff")
	end)

	T.test("an all buff raises attack, defence, speed and HP in a fight; one stat raises one", function()
		local farm = FarmKit.farm(NOW)
		local slime = farm.slimes[1]
		slime.stats = { attack = 10, defence = 10, speed = 10, hp = 100 }
		slime.buff = { stat = "all", percent = 50, untilTime = NOW + 100, dish = "lastingStew" }
		local fighter = Zombies.fighter(slime, NOW, 1)
		T.eq(fighter.attack, 15)
		T.eq(fighter.defence, 15)
		T.eq(fighter.speed, 15)
		T.eq(fighter.hp, 150)
		T.eq(fighter.maxHp, 150)
		slime.buff = { stat = "defence", percent = 50, untilTime = NOW + 100 }
		local one = Zombies.fighter(slime, NOW, 1)
		T.eq(one.attack, 10)
		T.eq(one.defence, 15)
	end)

	T.test("schema 16 to 17 keeps everything and adds the spice shelf at zero; repair caps what is held", function()
		T.eq(Config.Save.SchemaVersion, 17)
		local farm = FarmKit.farm(NOW)
		farm.coins = 4321
		farm.fridge = { grilledFish = 2 }
		local old: any = farm
		old.spices = nil
		local loaded = ProfileLogic.prepareLoad({ schemaVersion = 16, data = farm }, FarmSave.hooks(), NOW + 1)
		T.ok(loaded.ok and loaded.migrated)
		T.eq(loaded.data.coins, 4321)
		T.same(loaded.data.fridge, { grilledFish = 2 })
		T.same(loaded.data.spices, { honey = 0, truffle = 0, saffron = 0 })
		local rich: any = FarmKit.farm(NOW)
		rich.spices = { honey = 500, truffle = -3, saffron = 2.7, pepper = 9 }
		T.same(FarmState.repair(rich, NOW).spices, { honey = Config.Food.SpiceCap, truffle = 0, saffron = 2 })
	end)
end
