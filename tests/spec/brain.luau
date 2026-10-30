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
	T.test("every trait hauls while a bin waits; a bored playful slime plays first", function()
		for _, trait in Config.Village.Traits do
			for seed = 1, 20 do
				local farm = FarmKit.farm(NOW)
				farm.storehouse = {}
				farm.work.fishing.box.fish = 5
				farm.slimes[1].trait = trait
				local action = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(seed))
				T.eq(action.kind, "carryBox", trait .. " seed " .. seed)
			end
		end
		local farm = FarmKit.farm(NOW)
		farm.storehouse = {}
		farm.work.fishing.box.fish = 5
		farm.slimes[1].trait = "playful"
		farm.slimes[1].needs.fun = 0
		T.ok(Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(8)).kind ~= "carryBox")
	end)
	T.test("with nothing to carry, free slimes live their lives", function()
		for _, trait in Config.Village.Traits do
			local farm = FarmKit.farm(NOW)
			farm.storehouse = {}
			farm.work.fishing.box = {}
			farm.work.garden.box = {}
			farm.slimes[1].trait = trait
			local kind = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(3)).kind
			T.ok(string.sub(kind, 1, 5) ~= "carry", trait .. " chose " .. kind)
		end
	end)
	T.test("a full bin is shared by several couriers, one load each", function()
		local farm = FarmKit.farm(NOW)
		farm.storehouse = {}
		farm.work.fishing.box = { fish = Config.Work.BoxCapacity }
		local loads = math.ceil(Config.Work.BoxCapacity / Config.Brain.CarryAmount)
		local reserved = {}
		for index = 1, loads do
			local id = "slime-" .. ((index - 1) % #farm.slimes + 1)
			local action = Brain.choose(farm, id, { nearby = {}, reserved = reserved }, NOW, Rng.new(2))
			T.eq(action.kind, "carryBox")
			local keys = Brain.reservationKeys(action)
			T.eq(keys[1], "box:fishing:fish:" .. index)
			reserved[keys[1]] = "other-" .. index
		end
		-- every load claimed: nobody else is sent to the bin
		local extra = Brain.choose(farm, "slime-1", { nearby = {}, reserved = reserved }, NOW, Rng.new(2))
		T.ok(extra.kind ~= "carryBox")
		-- releasing on arrival makes a load available again
		reserved["box:fishing:fish:1"] = nil
		T.eq(Brain.choose(farm, "slime-1", { nearby = {}, reserved = reserved }, NOW, Rng.new(2)).kind, "carryBox")
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
		local keys = Brain.reservationKeys(first)
		local second =
			Brain.choose(farm, "slime-2", { nearby = {}, reserved = { [keys[1]] = "slime-1" } }, NOW, Rng.new(2))
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
	T.test("a parent carries its new egg to a free incubator before resting; only one parent goes", function()
		local farm = FarmKit.farm(NOW)
		local made = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		T.ok(made.ok)
		local laid = made.farm
		laid.slimes[1].needs.energy = Config.Needs.Tired -- tired after laying: still carries first
		local first = Brain.choose(laid, "slime-1", CTX, NOW, Rng.new(1))
		T.eq(first.kind, "carryEgg")
		T.eq(first.eggId, laid.eggs[1].id)
		local reserved = {}
		for _, key in Brain.reservationKeys(first) do
			reserved[key] = "slime-1"
		end
		local second = Brain.choose(laid, "slime-2", { nearby = {}, reserved = reserved }, NOW, Rng.new(1))
		T.ok(second.kind ~= "carryEgg", "the other parent does something else")
	end)
	T.test("a pair resting after laying hauls, then courts again when ready", function()
		local farm = FarmKit.farm(NOW)
		farm.breeding.pairs = { { a = "slime-1", b = "slime-2" } }
		for _, s in farm.slimes do
			s.trait = "hardworking"
			s.breedReadyAt = NOW + 60
		end
		farm.storehouse = {}
		farm.work.fishing.box = { fish = Config.Work.BoxCapacity }
		local resting = Brain.choose(farm, "slime-1", CTX, NOW, Rng.new(2))
		T.eq(resting.kind, "carryBox")
		local ready = Brain.choose(farm, "slime-1", CTX, NOW + 61, Rng.new(2))
		T.eq(ready.kind, "court")
	end)

	T.test("each pair courts at its own nest, not all at one spot", function()
		local farm = FarmKit.farm(NOW)
		farm.breeding.pairs = { { a = "slime-1", b = "slime-2" }, { a = "slime-3", b = "slime-4" } }
		local ctx = table.clone(CTX)
		local spots = table.clone(CTX.spots or {})
		spots["nest:1"] = { id = "nest:1", area = "breeding", x = 0, y = 0, z = 0 }
		spots["nest:2"] = { id = "nest:2", area = "breeding", x = 18, y = 0, z = 0 }
		ctx.spots = spots
		local one = Brain.choose(farm, "slime-1", ctx, NOW, Rng.new(4))
		local two = Brain.choose(farm, "slime-3", ctx, NOW, Rng.new(4))
		T.eq(one.kind, "court")
		T.eq(two.kind, "court")
		T.eq(one.spot, "nest:1")
		T.eq(two.spot, "nest:2")
		-- a nest that is only a guess (not built) falls back to the breeding area's spot
		spots["nest:2"] = { id = "nest:2", area = "breeding", x = 0, y = 0, z = 0, guessed = true }
		T.eq(Brain.choose(farm, "slime-3", ctx, NOW, Rng.new(4)).spot, "breeding")
	end)
end
