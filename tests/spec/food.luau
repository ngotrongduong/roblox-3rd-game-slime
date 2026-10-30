local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Food = require("../../src/shared/Food")
local Rng = require("../../src/shared/Rng")
return function(T)
	T.test("bounded add and take never go below zero or over capacity", function()
		local bag = {}
		T.eq(Food.add(bag, "fish", 1000, 10), 10)
		T.eq(Food.add(bag, "carrot", 10, 10), 0)
		T.eq(Food.take(bag, "fish", 1000), 10)
		T.eq(Food.take(bag, "fish", 1), 0)
		T.eq(Food.add(bag, "fake", 4, 10), 0)
		T.eq(Food.total(bag), 0)
		T.eq(Food.storehouseCapacity(1), 100)
		T.eq(Food.storehouseCapacity(50), 1080)
		T.eq(Food.fridgeCapacity(1), 20)
		T.eq(Food.fridgeCapacity(50), 216)
	end)
	T.test("best recipe chooses fullness and ingredient shopping never invents stock", function()
		local farm = FarmKit.farm(1000)
		T.eq(Food.bestDish({ fish = 2 }), "grilledFish")
		T.eq(Food.bestDish({ fish = 1, carrot = 1, cabbage = 1 }), "fishVegSoup")
		T.eq(Food.bestDish({}), nil)
		farm.counter = { fish = 1 }
		farm.storehouse = { carrot = 2, cabbage = 1 }
		T.same(Food.ingredientsWanted(farm), {}, "no cook or opted-in eater means no ingredient delivery")
		farm.work.kitchen.slots[1].worker = "slime-1"
		T.same(Food.ingredientsWanted(farm), {}, "a staffed kitchen still needs real eaters")
		table.insert(farm.cookedAllowed, "slime-2")
		T.same(Food.ingredientsWanted(farm), { carrot = 1, cabbage = 1 })
	end)
	T.test("prepared food is bounded by opted-in eaters and work-box stock", function()
		local farm = FarmKit.farm(1000)
		farm.work.kitchen.slots[1].worker = "slime-1"
		table.insert(farm.cookedAllowed, "slime-2")
		T.ok(Food.canPrepare(farm))
		farm.fridge.grilledFish = Config.Food.PreparedMealsPerAllowedSlime
		T.ok(not Food.canPrepare(farm), "one eater needs only two ready meals")
		T.same(Food.ingredientsWanted(farm), {})
		farm.fridge.grilledFish = 1
		farm.work.kitchen.box.veggieStew = 1
		T.ok(not Food.canPrepare(farm), "dish stock waiting for delivery also counts")
		table.insert(farm.cookedAllowed, "slime-3")
		T.ok(Food.canPrepare(farm), "a new eater increases demand")
	end)
	T.test("dish permission, fallback, fullness and timed battle buff", function()
		local farm = FarmKit.farm(1000)
		farm.fridge = { fishVegSoup = 1 }
		farm.storehouse = { fish = 2, carrot = 5 }
		T.eq(Food.chooseMeal(farm, "slime-1"), "carrot")
		table.insert(farm.cookedAllowed, "slime-1")
		T.eq(Food.chooseMeal(farm, "slime-1"), "fishVegSoup")
		farm.slimes[1].needs.fullness = 20
		T.eq(Food.eat(farm, "slime-1", 1000), "fishVegSoup")
		T.eq(farm.slimes[1].needs.fullness, 100)
		T.same(farm.slimes[1].buff, { stat = "hp", percent = 10, untilTime = 2200 })
		T.eq(Food.eat(farm, "slime-1", 1001), "carrot")
		T.eq(farm.fridge.fishVegSoup, nil)
	end)
	T.test("every kind is complete and a group's weights add up to 100", function()
		local sums = { fish = 0, veg = 0 }
		for id, kind in Config.Food.Kinds do
			T.ok(Config.Food.Rarities[kind.rarity] ~= nil, id .. " has a known rarity")
			T.ok(kind.fullness > 0 and kind.weight > 0 and kind.name ~= "", id .. " has fullness, weight and name")
			T.eq(Config.Food.Raw[id], kind.fullness, id .. " raw fullness is the kind's")
			T.ok(table.find(Config.Food.RawOrder, id) ~= nil, id .. " is in RawOrder")
			sums[kind.group] += kind.weight
		end
		T.eq(sums.fish, 100)
		T.eq(sums.veg, 100)
		T.eq(#Config.Food.RawOrder, #Config.Food.FishOrder + #Config.Food.VegOrder)
	end)
	T.test("kind rolls follow the weights (100k seeded rolls within half a percentage point)", function()
		for group, order in { fish = Config.Food.FishOrder, veg = Config.Food.VegOrder } do
			local rng = Rng.new(20261030)
			local seen = {}
			local rolls = 100000
			for _ = 1, rolls do
				local id = Food.roll(group, rng)
				seen[id] = (seen[id] or 0) + 1
			end
			for _, id in order do
				local percent = (seen[id] or 0) / rolls * 100
				T.ok(
					math.abs(percent - Config.Food.Kinds[id].weight) <= 0.5,
					group .. " " .. id .. " rolled " .. string.format("%.2f", percent) .. "%"
				)
			end
		end
	end)
	T.test("a roll at the very top of the range still returns a kind of the group", function()
		local top = Rng.sequence({ 0.9999999 })
		T.eq(Food.roll("fish", top), "goldenCarp")
		T.eq(Food.roll("veg", Rng.sequence({ 0 })), "carrot")
	end)
	T.test("a slime eats a new kind for the kind's fullness; stores keep every kind", function()
		for id, kind in Config.Food.Kinds do
			local farm = FarmKit.farm(1000)
			farm.storehouse = { [id] = 1 }
			farm.slimes[1].needs.fullness = 10
			T.eq(Food.eat(farm, "slime-1", 1000), id)
			T.eq(farm.slimes[1].needs.fullness, 10 + kind.fullness, id)
			T.eq(farm.storehouse[id], nil)
		end
		local bag = {}
		for _, id in Config.Food.RawOrder do
			T.eq(Food.add(bag, id, 1, 50), 1, id)
		end
		T.eq(Food.total(bag), #Config.Food.RawOrder)
	end)
	T.test("the saved stores and bins repair every kind and drop only unknown ids", function()
		local farm = FarmState.newFarm(1000)
		farm.storehouse = { trout = 3, pumpkin = 2, starfruit = 1, junk = 4 }
		farm.work.fishing.box = { salmon = 4, goldenCarp = 1 }
		farm.work.garden.box = { tomato = 5, corn = 2 }
		farm.work.garden.slots[1].pending = "pumpkin"
		farm.work.fishing.slots[1].pending = "pufferfish"
		local out = FarmState.repair(farm, 1000)
		T.same(out.storehouse, { trout = 3, pumpkin = 2, starfruit = 1 })
		T.same(out.work.fishing.box, { salmon = 4, goldenCarp = 1 })
		T.same(out.work.garden.box, { tomato = 5, corn = 2 })
		T.eq(out.work.garden.slots[1].pending, "pumpkin")
		T.eq(out.work.fishing.slots[1].pending, "pufferfish")
		farm.work.garden.slots[1].pending = "salmon"
		T.eq(FarmState.repair(farm, 1000).work.garden.slots[1].pending, nil, "a fish is never a garden catch")
	end)
end
