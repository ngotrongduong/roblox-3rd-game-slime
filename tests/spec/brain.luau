-- Village brain choices and arrival invariants (Lune: no Roblox services or wall clock).
local Brain = require("../../src/shared/Brain")
local Breeding = require("../../src/shared/Breeding")
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local Rng = require("../../src/shared/Rng")

local NOW = 1000000
local CTX = { nearby = {} }

return function(T)
	T.test("hungry slime goes to food and eats on arrival", function()
		local farm = FarmKit.farm(NOW)
		farm.slimes[1].needs.fullness = Config.Needs.WantsFood
		local action = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(1))
		T.eq(action.kind, "eat")
		T.eq(action.spot, "storehouse")
		local before = farm.storehouse[action.carry.item]
		local _, ok = Brain.arrive(farm, "slime-1", action, NOW)
		T.ok(ok)
		T.eq(farm.storehouse[action.carry.item], before - 1)
		T.ok(farm.slimes[1].needs.fullness > Config.Needs.WantsFood)
	end)
	T.test("tired slime walks to a bed and begins sleeping only there", function()
		local farm = FarmKit.farm(NOW)
		farm.slimes[1].needs.energy = Config.Needs.Tired
		local action = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(1))
		T.eq(action.kind, "sleep")
		T.eq(farm.slimes[1].sleeping, nil)
		local _, ok = Brain.arrive(farm, "slime-1", action, NOW)
		T.ok(ok)
		T.eq(farm.slimes[1].sleeping, true)
	end)
	T.test("idle hardworking slime carries from a box", function()
		local farm = FarmKit.farm(NOW)
		farm.slimes[1].trait = "hardworking"
		farm.storehouse = {}
		farm.work.fishing.box = { fish = Config.Work.BoxCapacity }
		local action = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(2))
		T.eq(action.kind, "carryBox")
		T.eq(action.source, "fishing")
	end)
	T.test("carrying preserves total stock and honours capacity", function()
		local farm = FarmKit.farm(NOW)
		farm.work.garden.box = { carrot = 6 }
		local total = farm.storehouse.carrot + farm.work.garden.box.carrot
		local action = {
			kind = "carryBox",
			spot = "storehouse",
			source = "garden",
			seconds = 3,
			emotion = "proud",
			carry = { item = "carrot", count = Config.Brain.CarryAmount },
		}
		local _, ok = Brain.arrive(farm, "slime-1", action, NOW)
		T.ok(ok)
		T.eq(farm.storehouse.carrot + farm.work.garden.box.carrot, total)
		T.eq(farm.work.garden.box.carrot, 6 - Config.Brain.CarryAmount)
		farm.storehouse = { fish = 100 }
		local before = farm.work.garden.box.carrot
		_, ok = Brain.arrive(farm, "slime-1", action, NOW)
		T.ok(not ok)
		T.eq(farm.work.garden.box.carrot, before)
	end)
	T.test("a waiting nest egg is delivered and starts an incubation clock", function()
		local farm = FarmKit.farm(NOW)
		local egg = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(4), FarmKit.ids())
		T.ok(egg.ok)
		farm = egg.farm
		farm.slimes[3].trait = "hardworking"
		local action = Brain.choose(farm, "slime-3", CTX, NOW, Rng.new(1))
		T.eq(action.kind, "carryEgg")
		local _, ok = Brain.arrive(farm, "slime-3", action, NOW)
		T.ok(ok)
		T.eq(farm.eggs[1].place, "incubator")
		T.ok(farm.eggs[1].hatchAt > NOW)
	end)
	T.test("cooked-allowed slime eats fridge dish; another must eat raw", function()
		local farm = FarmKit.farm(NOW)
		farm.fridge = { grilledFish = 2 }
		farm.cookedAllowed = { "slime-1" }
		farm.slimes[1].needs.fullness = 40
		farm.slimes[2].needs.fullness = 40
		local allowed = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(1))
		T.eq(allowed.kind, "eat")
		T.eq(allowed.spot, "fridge")
		local _, applied = Brain.arrive(farm, "slime-1", allowed, NOW)
		T.ok(applied)
		T.eq(farm.fridge.grilledFish, 1)
		local denied = Brain.choose(farm, "slime-2", CTX, NOW, Rng.new(1))
		T.eq(denied.spot, "storehouse")
		_, applied = Brain.arrive(farm, "slime-2", denied, NOW)
		T.ok(applied)
		T.eq(farm.fridge.grilledFish, 1)
	end)
	T.test("stale action refuses to create items or spend unrelated food", function()
		local farm = FarmKit.farm(NOW)
		farm.work.fishing.box.fish = 2
		local action = {
			kind = "carryBox",
			spot = "storehouse",
			source = "fishing",
			seconds = 3,
			emotion = "proud",
			carry = { item = "fish", count = 2 },
		}
		farm.work.fishing.box.fish = nil
		local start = farm.storehouse.fish
		local _, ok = Brain.arrive(farm, "slime-1", action, NOW)
		T.ok(not ok)
		T.eq(farm.storehouse.fish, start)
	end)
	T.test("hungry and tired babies stay in nursery", function()
		local baby = FarmKit.slime("baby", { createdAt = NOW })
		baby.needs.fullness = 0
		baby.needs.energy = 0
		local farm = FarmKit.farm(NOW, { baby })
		local action = Brain.choose(farm, "baby", CTX, NOW, Rng.new(3))
		T.eq(action.kind, "nursery")
		T.eq(action.spot, "nursery")
	end)
	T.test("trait scores alter a choice with identical seed", function()
		local farm = FarmKit.farm(NOW)
		farm.storehouse = {}
		farm.work.fishing.box.fish = 5
		farm.slimes[1].trait = "hardworking"
		local hard = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(8))
		farm.slimes[1].trait = "playful"
		local play = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(8))
		T.eq(hard.kind, "carryBox")
		T.ok(play.kind ~= hard.kind)
	end)
	T.test("a claimed box batch is offered to only one slime", function()
		local farm = FarmKit.farm(NOW)
		farm.storehouse = {}
		farm.work.fishing.box = { fish = Config.Work.BoxCapacity }
		farm.slimes[1].trait = "hardworking"
		farm.slimes[2].trait = "hardworking"
		local first = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(2))
		T.eq(first.kind, "carryBox")
		local keys = Brain.reservationKeys(first)
		T.eq(keys[1], "box:fishing:fish")
		local second = Brain.choose(farm, "slime-2", { nearby = {}, reserved = { [keys[1]] = "slime-1" } }, NOW, Rng.new(2))
		T.ok(second.kind ~= "carryBox")
		-- Releasing on arrival makes the remaining batch available again.
		local again = Brain.choose(farm, "slime-2", CTX, NOW, Rng.new(2))
		T.eq(again.kind, "carryBox")
	end)
	T.test("a claimed counter delivery cannot be chosen twice", function()
		local farm = FarmKit.farm(NOW)
		farm.work.fishing.box = {}
		farm.work.garden.box = {}
		farm.counter = {}
		farm.storehouse = { fish = 2 }
		farm.slimes[1].trait = "hardworking"
		farm.slimes[2].trait = "hardworking"
		local first = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(2))
		T.eq(first.kind, "carryKitchen")
		local second = Brain.choose(farm, "slime-2", { nearby = {}, reserved = { counter = "slime-1" } }, NOW, Rng.new(2))
		T.ok(second.kind ~= "carryKitchen")
	end)
	T.test("egg and incubator are both claimed during a carry", function()
		local farm = FarmKit.farm(NOW)
		local created = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(4), FarmKit.ids())
		T.ok(created.ok)
		farm = created.farm
		farm.slimes[3].trait = "hardworking"
		farm.slimes[4].trait = "hardworking"
		local first = Brain.choose(farm, "slime-3", CTX, NOW, Rng.new(1))
		T.eq(first.kind, "carryEgg")
		local keys = Brain.reservationKeys(first)
		T.eq(keys[1], "egg:" .. farm.eggs[1].id)
		T.eq(keys[2], first.spot)
		local locked = { [keys[1]] = "slime-3", [keys[2]] = "slime-3" }
		local second = Brain.choose(farm, "slime-4", { nearby = {}, reserved = locked }, NOW, Rng.new(1))
		T.ok(second.kind ~= "carryEgg")
	end)

end
