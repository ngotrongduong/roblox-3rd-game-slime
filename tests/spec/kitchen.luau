--!strict
-- Regression checks for the kitchen, save schema, economy and combat payouts.
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Food = require("../../src/shared/Food")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local Stations = require("../../src/shared/Stations")
local Village = require("../../src/shared/Village")
local VillageSim = require("../../src/shared/VillageSim")
local Zombies = require("../../src/shared/Zombies")

local NOW = 1000000

return function(T: any)
	T.test("area-level rarity weights total 100; epic rolls rise by level 50", function()
		for _, group in { "fish", "veg" } do
			local order = if group == "fish" then Config.Food.FishOrder else Config.Food.VegOrder
			local bottom, top = 0, 0
			for _, id in order do
				bottom += (Config.Food.Kinds :: any)[id].weight
				top += (Config.Food.Kinds :: any)[id].topWeight
			end
			T.eq(bottom, 100)
			T.eq(top, 100)
			local commonEpics, highEpics = 0, 0
			local first, last = Rng.new(27), Rng.new(27)
			for _ = 1, 10000 do
				local low = Food.roll(group, first, 1)
				local high = Food.roll(group, last, 50)
				if (Config.Food.Kinds :: any)[low].rarity == "epic" then
					commonEpics += 1
				end
				if (Config.Food.Kinds :: any)[high].rarity == "epic" then
					highEpics += 1
				end
			end
			T.ok(highEpics > commonEpics, group .. " top level produces more epics")
		end
	end)

	T.test("sixteen recipes in rarity/stat order, locked recipes cannot be assigned", function()
		T.eq(#Config.Food.DishOrder, 16)
		local farm = FarmKit.farm(NOW)
		T.eq(Food.slotRecipe(farm.work.kitchen.slots[1], 1), "grilledFish")
		T.ok(not Stations.setCookRecipe(farm, 1, "bakedTrout"))
		T.ok(not Stations.setCookRecipe(farm, 1, "unknown"))
		T.eq(farm.work.kitchen.slots[1].recipe, nil, "invalid assignment leaves no explicit recipe")
		farm.areas.kitchen.level = 8
		T.ok(Stations.setCookRecipe(farm, 1, "bakedTrout"))
		T.eq(farm.work.kitchen.slots[1].recipe, "bakedTrout")
		T.ok(Food.recipeUnlocked("bakedTrout", 8))
		T.ok(not Food.recipeUnlocked("salmonSteak", 8))
		T.ok(Food.cookSeconds("grilledFish", 50) < Food.cookSeconds("grilledFish", 1))
		T.ok(Food.cookSeconds("bakedTrout", 8) > Food.cookSeconds("grilledFish", 8))
	end)

	T.test("a cook with missing ingredients waits without consuming a partial recipe", function()
		local farm = FarmKit.farm(NOW)
		farm.work.kitchen.slots[1].worker = "slime-1"
		farm.counter = { fish = 1 }
		local after = VillageSim.step(farm, NOW + 240, 240, Rng.new(1), { errands = false })
		T.same(after.counter, { fish = 1 })
		T.eq(after.work.kitchen.slots[1].progress, 0)
		T.same(after.work.kitchen.box, {})
		farm.counter = { fish = 2 }
		local cooked = VillageSim.step(farm, NOW + 120, 120, Rng.new(1), { errands = false })
		T.eq(cooked.work.kitchen.box.grilledFish, 1)
		T.eq(cooked.counter.fish, nil)
	end)

	T.test("two staffed recipes request the sum without stealing the food reserve", function()
		local farm = FarmKit.farm(NOW)
		farm.areas.kitchen.level = 11
		farm.work.kitchen.slots[1].worker = "slime-1"
		farm.work.kitchen.slots[2] = { worker = "slime-2", progress = 0, recipe = "veggieStew" }
		farm.storehouse = { fish = 5, carrot = 4, cabbage = 3 }
		T.same(Food.ingredientsWanted(farm), { fish = 2, carrot = 2, cabbage = 1 })
		farm.storehouse = { fish = 4 }
		T.same(Food.ingredientsWanted(farm), {}, "reserve holds back the last four raw items")
		farm.counter = { fish = 2, carrot = 3 }
		farm.storehouse = { fish = 8 }
		T.ok(Stations.setCookRecipe(farm, 1, "blueFishSkewer"))
		T.eq(farm.counter.fish, nil, "obsolete fish returns to the pantry")
		T.eq(farm.storehouse.fish, 10)
		T.eq(farm.counter.carrot, 3, "the second cook still needs carrots")
	end)

	T.test("ingredients left by a cook who is gone return to the storehouse and cannot jam the counter", function()
		local farm = FarmKit.farm(NOW)
		farm.counter = { fish = 6, carrot = 4 }
		farm.storehouse = { fish = 1 }
		local after = VillageSim.step(farm, NOW + 1, 1, Rng.new(1), { errands = false })
		T.same(after.counter, {})
		T.eq(after.storehouse.fish, 7)
		T.eq(after.storehouse.carrot, 4)
	end)

	T.test("manual feeding replaces a timed buff and never spends stock on refusal", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { grilledFish = 1, bakedTrout = 1 }
		farm.slimes[1].buff = { stat = "defence", percent = 5, untilTime = NOW + 900 }
		T.eq(select(2, Food.feed(farm, "slime-1", "not-a-dish", NOW)), "UNKNOWN_DISH")
		T.eq(select(2, Food.feed(farm, "slime-1", "goldenBanquet", NOW)), "NO_DISH")
		T.same(farm.fridge, { grilledFish = 1, bakedTrout = 1 }, "refusals do not spend a dish")
		T.same(
			farm.slimes[1].buff,
			{ stat = "defence", percent = 5, untilTime = NOW + 900 },
			"refusals do not replace the buff"
		)
		T.ok(Food.feed(farm, "slime-1", "grilledFish", NOW))
		T.same(farm.slimes[1].buff, { stat = "attack", percent = 4, untilTime = NOW + 600, dish = "grilledFish" })
		T.eq(farm.fridge.grilledFish, nil)
		T.ok(Food.feed(farm, "slime-1", "bakedTrout", NOW + 1))
		T.same(farm.slimes[1].buff, { stat = "attack", percent = 6, untilTime = NOW + 661, dish = "bakedTrout" })
		farm.slimes[1].ghostUntil = NOW + 100
		T.eq(select(2, Food.feed(farm, "slime-1", "bakedTrout", NOW)), "DEAD")
	end)

	T.test("auto dish only on selection, falling back to cheapest raw kind", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { grilledFish = 1 }
		farm.storehouse = { salmon = 10, carrot = 1, fish = 2 }
		T.ok(Food.setAutoDish(farm, "slime-1", "grilledFish"))
		farm.slimes[1].needs.fullness = 20
		T.eq(Food.eat(farm, "slime-1", NOW), "grilledFish")
		T.eq(Food.eat(farm, "slime-1", NOW + 1), "fish", "rare food stays for cooking")
		T.eq(Food.cheapestRaw({ salmon = 10, carrot = 2, fish = 1 }), "carrot", "common abundance wins")
		T.eq(select(2, Food.setAutoDish(farm, "slime-1", "bad")), "UNKNOWN_DISH")
		T.ok(Food.setAutoDish(farm, "slime-1", nil))
		T.eq(farm.slimes[1].autoDish, nil)
	end)

	T.test("speed buffs affect fighters while raw food revives from least rarity", function()
		local farm = FarmKit.farm(NOW)
		local slime = farm.slimes[1]
		slime.stats.speed = 4
		slime.buff = { stat = "speed", percent = 25, untilTime = NOW + 600, dish = "starfruitTart" }
		T.eq(Zombies.fighter(slime, NOW, 1).speed, 5)
		T.eq(Zombies.fighter(slime, NOW + 601, 1).speed, 4)
		farm.storehouse = { salmon = 8, fish = 1, carrot = 3 }
		slime.ghostUntil = NOW + Config.Village.GhostSeconds
		T.ok(Zombies.revive(farm, slime.id, NOW))
		T.eq(farm.storehouse.salmon, 8)
	end)

	T.test("dish sales pay rarity price and may exceed the battle vault", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { grilledFish = 2, goldenBanquet = 1 }
		T.eq(select(2, Shop.sellDish(farm, "grilledFish", 0)), "INVALID_COUNT")
		T.eq(Shop.sellDish(farm, "grilledFish", 4), 2000)
		T.eq(farm.fridge.grilledFish, nil)
		T.eq(Shop.sellDish(farm, "goldenBanquet", 1), 2000)
		T.eq(farm.lifetime.coinsEarned, 4000)
		local cap = Village.coinCap(farm.areas.pantry.level)
		farm.coins = cap - 10
		T.eq(Zombies.pay(farm, 100), 10)
		T.eq(farm.coins, cap)
		T.eq(Zombies.pay(farm, 100), 0)
		T.eq(farm.coins, cap)
		farm.fridge = { grilledFish = 1 }
		T.eq(Shop.sellDish(farm, "grilledFish", 1), 1000)
		T.eq(farm.coins, cap + 1000)
		T.eq(Zombies.pay(farm, 100), 0)
		T.eq(farm.coins, cap + 1000)
		T.eq(Shop.sell(farm, "slime-2", NOW), 120, "slime sale also ignores the cap")
		T.eq(farm.coins, cap + 1120)
	end)

	T.test("upgrade anchors hold and intermediate prices never fall", function()
		for _, row in Config.Village.UpgradePrices do
			T.eq(Village.upgradeCost(row.level), row.price)
		end
		for level = 2, 50 do
			T.ok(Village.upgradeCost(level) >= Village.upgradeCost(level - 1), "price dropped at " .. level)
		end
		T.eq(Village.coinCap(50), 3 * 99000)
		T.eq(Config.Pads.FreeUpgrades, false)
	end)

	T.test("bad saved recipe and dish ids are dropped while valid old buffs remain", function()
		local farm = FarmKit.farm(NOW)
		farm.work.kitchen.slots[1].recipe = "invalid"
		farm.slimes[1].autoDish = "invalid"
		farm.slimes[1].buff = { stat = "speed", percent = 12, untilTime = NOW + 100, dish = "invalid" }
		local repaired = FarmState.repair(farm, NOW)
		T.eq(repaired.work.kitchen.slots[1].recipe, nil)
		T.eq(Food.slotRecipe(repaired.work.kitchen.slots[1], 1), "grilledFish")
		T.eq(repaired.slimes[1].autoDish, nil)
		T.same(repaired.slimes[1].buff, { stat = "speed", percent = 12, untilTime = NOW + 100 })
	end)

	T.test("schema five migration keeps progress and strips old cooked permissions", function()
		local farm = FarmKit.farm(NOW)
		farm.coins = 1234
		farm.work.kitchen.slots[1].recipe = "grilledFish"
		farm.slimes[1].autoDish = "veggieStew"
		farm.slimes[1].buff = { stat = "hp", percent = 8, untilTime = NOW + 500, dish = "fishVegSoup" }
		local old: any = farm
		old.cookedAllowed = { "slime-1" }
		local loaded = ProfileLogic.prepareLoad({ schemaVersion = 5, data = farm }, FarmSave.hooks(), NOW + 1)
		T.ok(loaded.ok and loaded.migrated)
		T.eq(loaded.data.coins, 1234)
		T.eq(loaded.data.cookedAllowed, nil)
		T.eq(loaded.data.work.kitchen.slots[1].recipe, "grilledFish")
		T.eq(loaded.data.slimes[1].autoDish, "veggieStew")
		T.eq(loaded.data.slimes[1].buff.dish, "fishVegSoup")
		T.eq((FarmState.newFarm(NOW) :: any).cookedAllowed, nil)
	end)
end
