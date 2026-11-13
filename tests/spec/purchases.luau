-- What Robux sells (docs/MONETIZATION.md §2): the catalog, what each good does to a farm, boosts on coins EARNED only, hatching
-- speed, teams and slots, the Streak Saver and redraw banks, receipts granted once (through the real save path on two simulated
-- servers) and the schema-13 save. The Roblox side (server/Purchases) is thin and calls these same functions.
local Boosts = require("../../src/shared/Boosts")
local Breeding = require("../../src/shared/Breeding")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local Fake = require("../lib/FakeDataStore")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Hatching = require("../../src/shared/Hatching")
local Products = require("../../src/shared/Products")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local ProfileStore = require("../../src/server/ProfileStore")
local Rewards = require("../../src/shared/Rewards")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local VillageRequests = require("../../src/shared/VillageRequests")
local VillageRules = require("../../src/shared/Village")
local VillageSim = require("../../src/shared/VillageSim")
local Wheel = require("../../src/shared/Wheel")
local Zombies = require("../../src/shared/Zombies")

local DAY = 86400
-- noon of a UTC day
local NOW = 20000 * DAY + 12 * 3600
local R = Config.Robux

-- A farm that owns the given passes (the way server/Purchases mirrors them).
local function farmWith(passes: { string }?): any
	local farm = FarmKit.farm(NOW)
	for _, key in passes or {} do
		farm.robux.passes[key] = true
	end
	return farm
end

local function product(key: string): any
	return assert(Products.get(key), key)
end

return function(T)
	-- ===== the catalog =====

	T.test(
		"the catalog holds every pass and product of the plan, each with a name without digits and no Roblox id yet",
		function()
			local passes, goods = 0, 0
			local seen: { [string]: boolean } = {}
			for _, p in R.Products do
				T.ok(not seen[p.key], "key twice: " .. p.key)
				seen[p.key] = true
				T.ok(p.name ~= "" and not string.find(p.name, "%d"), "name of " .. p.key)
				T.ok(p.icon ~= "" and p.price > 0, "icon and price of " .. p.key)
				T.eq(p.id, 0, "no Creator Hub id for " .. p.key)
				T.ok(p.kind == "pass" or p.kind == "product", "kind of " .. p.key)
				if p.kind == "pass" then
					passes += 1
				else
					goods += 1
				end
			end
			T.eq(passes, 7)
			T.eq(goods, 15)
			T.eq(R.TestGrant, false, "the test switch is off in anything committed")
			T.eq(Products.byProductId(0), nil, "id 0 is a good that is not on Roblox yet")
			T.eq(Products.byPassId(0), nil)
		end
	)

	T.test(
		"gold packs are 2, 7, 18 and 50 coin bases; spins 1, 5 and 12; potions 30 minutes; one Starter Pack",
		function()
			T.eq(product("goldPouch").gold, 2)
			T.eq(product("goldSack").gold, 7)
			T.eq(product("goldChest").gold, 18)
			T.eq(product("goldVault").gold, 50)
			T.eq(product("spin1").spins, 1)
			T.eq(product("spin5").spins, 5)
			T.eq(product("spin12").spins, 12)
			for _, key in { "luckPotion", "goldPotion", "hatchPotion" } do
				T.eq(product(key).minutes, 30, key)
			end
			T.eq(product("luck2").luck, 2)
			T.eq(product("luck4").luck, 4)
			T.eq(product("luck8").luck, 8)
			T.eq(product("team6").requires, "team5")
			T.eq(product("ranch").slots, 50)
			T.eq(product("starterPack").starter.gold, 7)
		end
	)

	-- ===== coins earned =====

	T.test("VIP pays 1.5 x on coins earned, a Gold Potion 2 x, both 3 x; an ended potion nothing", function()
		local farm = farmWith()
		T.eq(Boosts.coinFactor(farm, NOW), 1)
		T.eq(Boosts.earn(farm, 100, NOW), 100)
		farm.robux.passes.vip = true
		T.eq(Boosts.earn(farm, 100, NOW), 150)
		farm.boosts.gold = NOW + 60
		T.eq(Boosts.earn(farm, 100, NOW), 300)
		T.eq(Boosts.earn(farm, 100, NOW + 61), 150, "the potion ran out")
		farm.robux.passes.vip = nil
		T.eq(Boosts.earn(farm, 100, NOW), 200)
	end)

	T.test("fights, slime sales, dish sales and rewards are boosted; Robux gold and the Index are not", function()
		local plain, vip = farmWith(), farmWith({ "vip" })
		-- a fight (up to the vault) and a dungeon wave
		T.eq(Zombies.pay(plain, 100, NOW), 100)
		T.eq(Zombies.pay(vip, 100, NOW), 150)
		T.eq(vip.lifetime.coinsEarned, 150)
		T.eq(Zombies.pay(farmWith({ "vip" }), 100), 100, "a caller with no clock pays unboosted")
		-- a reward
		local before = vip.coins
		Rewards.pay(vip, { coins = 100, luck = 0 }, NOW)
		T.eq(vip.coins - before, 150)
		-- a slime sale
		local a, b = farmWith(), farmWith({ "vip" })
		a.slimes, b.slimes = FarmKit.many(8), FarmKit.many(8)
		local paidPlain = Shop.sell(a, "s5", NOW) :: number
		local paidVip = Shop.sell(b, "s5", NOW) :: number
		T.ok(paidPlain > 0)
		T.eq(paidVip, math.floor(paidPlain * 1.5 + 0.5))
		T.eq(b.coins, paidVip)
		-- a dish sale
		a.fridge.grilledFish, b.fridge.grilledFish = 4, 4
		local dishPlain = Shop.sellDish(a, "grilledFish", 4, NOW) :: number
		local dishVip = Shop.sellDish(b, "grilledFish", 4, NOW) :: number
		T.eq(dishVip, math.floor(dishPlain * 1.5 + 0.5))
		-- a dungeon wave pays through Zombies.pay
		local ledger = Dungeon.newLedger()
		T.ok(Dungeon.addDrop(ledger, 1, { item = "coins", amount = 100 }), "a drop is written")
		local waveFarm = farmWith({ "vip" })
		local paid = Dungeon.commitWave(waveFarm, ledger, 1, NOW) :: any
		T.eq(paid.coins, 150)
		-- Robux gold is plain coins: nothing multiplies it
		local rich = farmWith({ "vip" })
		rich.boosts.gold = NOW + 1000
		T.eq(rich.coins, 0)
		Products.redeem(rich, "goldPouch", "g1", NOW)
		T.eq(rich.coins, 2 * Rewards.coinBase(rich), "2 coin bases, never 3 x of them")
		T.eq(rich.lifetime.coinsEarned, 0, "bought gold is not coins earned")
	end)

	-- ===== hatching =====

	T.test("VIP hatches 1.5 x faster, a Hatch Potion 2 x, both 3 x; the floor stays", function()
		local farm = farmWith()
		T.eq(Boosts.hatchFactor(farm, NOW), 1)
		farm.robux.passes.vip = true
		T.eq(Boosts.hatchFactor(farm, NOW), 1.5)
		farm.boosts.hatch = NOW + 10
		T.eq(Boosts.hatchFactor(farm, NOW), 3)
		T.eq(Boosts.hatchFactor(farm, NOW + 11), 1.5)
		local slow = Breeding.incubationSeconds(20, 1, false)
		T.eq(Breeding.incubationSeconds(20, 1, false, 2), math.round(slow / 2))
		T.eq(
			Breeding.incubationSeconds(20, 1, false, 1000),
			Config.Breeding.IncubationFloorSeconds,
			"never under the floor"
		)
		T.eq(
			Breeding.incubationSeconds(20, 1, true, 2),
			Config.Breeding.TutorialHatchSeconds,
			"the tutorial's clock is its own"
		)
		-- a laid egg is timed with the boost
		local plain, vip = farmWith(), farmWith({ "vip" })
		local a = Breeding.createEgg(plain, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		local b = Breeding.createEgg(vip, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		assert(a.ok and a.egg and b.ok and b.egg)
		T.ok(b.egg.hatchAt - NOW < a.egg.hatchAt - NOW)
		T.eq(b.egg.hatchAt - NOW, Breeding.nestSeconds(b.egg, 1, false, 1.5))
	end)

	T.test("a Hatch Potion or the VIP pass that starts while an egg grows speeds the rest of its time up", function()
		local farm = farmWith()
		local res = Breeding.createEgg(farm, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		assert(res.ok and res.egg)
		local egg = assert(FarmState.findEgg(res.farm, res.egg.id))
		local left = egg.hatchAt - NOW
		Products.grant(res.farm, "hatchPotion", NOW)
		T.near(egg.hatchAt - NOW, left / 2, 1e-9)
		-- a second potion adds time and does not speed the egg up twice
		local after = egg.hatchAt
		Products.grant(res.farm, "hatchPotion", NOW)
		T.eq(egg.hatchAt, after)
		T.eq(res.farm.boosts.hatch, NOW + 3600, "two potions are an hour")
		-- the VIP pass starting
		local other = farmWith()
		local laid = Breeding.createEgg(other, "slime-1", "slime-2", NOW, Rng.new(1), FarmKit.ids())
		assert(laid.ok and laid.egg)
		local growing = assert(FarmState.findEgg(laid.farm, laid.egg.id))
		local remaining = growing.hatchAt - NOW
		T.ok(Products.setPass(laid.farm, "vip", true, NOW))
		T.near(growing.hatchAt - NOW, remaining / 1.5, 1e-9)
		T.ok(not Products.setPass(laid.farm, "vip", true, NOW), "asked again, nothing changes")
		T.near(growing.hatchAt - NOW, remaining / 1.5, 1e-9)
	end)

	T.test("Hatch All Now hatches every egg through the village step, and again changes nothing", function()
		local farm = farmWith()
		farm.slimes = FarmKit.many(6)
		local one = Breeding.createEgg(farm, "s1", "s2", NOW, Rng.new(1), FarmKit.ids())
		assert(one.ok, tostring(one.reason))
		local two = Breeding.createEgg(one.farm, "s3", "s4", NOW, Rng.new(2), FarmKit.ids())
		assert(two.ok, tostring(two.reason))
		local eggs: any = two.farm
		T.eq(#eggs.eggs, 2)
		T.ok(Products.canBuy(eggs, "hatchAll", NOW))
		local ok, status = Products.redeem(eggs, "hatchAll", "h1", NOW)
		T.ok(ok)
		T.eq(status, "GRANTED")
		for _, egg in eggs.eggs do
			T.ok(egg.hatchAt <= NOW, "ready now")
		end
		T.ok(Hatching.nextReadyEgg(eggs, NOW) ~= nil, "the sim's auto-hatch sees it")
		T.same({ Products.redeem(eggs, "hatchAll", "h1", NOW) }, { true, "DUPLICATE" }, "the same receipt")
		local snapshot = {}
		for _, egg in eggs.eggs do
			table.insert(snapshot, egg.hatchAt)
		end
		Products.grant(eggs, "hatchAll", NOW)
		for index, egg in eggs.eggs do
			T.eq(egg.hatchAt, snapshot[index], "a second one moves nothing")
		end
		local hatched = VillageSim.step(eggs, NOW, 1, Rng.new(1), { errands = false })
		T.eq(#hatched.eggs, 0, "both hatched")
		T.eq(#hatched.slimes, 8)
		T.eq(select(2, Products.canBuy(hatched, "hatchAll", NOW)), "NO_EGGS", "nothing to hatch, nothing sold")
	end)

	-- ===== room =====

	T.test("Bigger Ranch adds 50 slime slots to what the village allows, and Breeding respects it", function()
		local farm = farmWith()
		local limit = FarmState.populationLimit(farm.areas)
		T.eq(FarmState.capacity(farm), limit)
		T.eq(VillageRules.populationLimit(farm), limit)
		farm.slimes = FarmKit.many(limit)
		T.eq(Breeding.check(farm, "s1", "s2", NOW).reason, "SLIME_CAP_REACHED")
		farm.robux.passes.ranch = true
		T.eq(Boosts.extraSlots(farm), 50)
		T.eq(FarmState.capacity(farm), limit + 50)
		T.eq(VillageRules.populationLimit(farm), limit + 50)
		T.ok(Breeding.check(farm, "s1", "s2", NOW).ok)
	end)

	T.test("each Extra Team pass adds one team: six at most, a farm always holds six", function()
		local farm = farmWith()
		T.eq(Config.Zombies.Teams, 6)
		T.eq(#farm.teams, 6)
		T.eq(Boosts.extraTeams(farm), 0)
		farm.robux.passes.team5 = true
		T.eq(Boosts.extraTeams(farm), 1)
		farm.robux.passes.team6 = true
		T.eq(Boosts.extraTeams(farm), 2)
		farm.robux.passes.team5 = nil
		T.eq(
			Products.canBuy(farm, "team5", NOW),
			true,
			"team 6 owned, team 5 not (a damaged mirror) can still be bought"
		)
		local repaired = FarmState.repair(FarmState.repair(farm, NOW), NOW)
		T.eq(#repaired.teams, 6)
	end)

	-- ===== what is bought =====

	T.test("potion time adds up: a second potion starts when the first ends", function()
		local farm = farmWith()
		T.eq(select(2, Products.grant(farm, "goldPotion", NOW)), "gold potion until " .. (NOW + 1800))
		T.eq(farm.boosts.gold, NOW + 1800)
		Products.grant(farm, "goldPotion", NOW + 600)
		T.eq(farm.boosts.gold, NOW + 3600, "10 minutes into the first: 50 minutes left")
		Products.grant(farm, "goldPotion", NOW + 7200)
		T.eq(farm.boosts.gold, NOW + 7200 + 1800, "a potion bought after the last one ended starts then")
		-- the Luck Potion is the farm's luckPotionUntil, which the rewards also pay
		Products.grant(farm, "luckPotion", NOW)
		T.eq(farm.luckPotionUntil, NOW + 1800)
		Rewards.pay(farm, { coins = 0, luck = 15 }, NOW)
		T.eq(farm.luckPotionUntil, NOW + 1800 + 900)
		Products.grant(farm, "luckPotion", NOW)
		T.eq(farm.luckPotionUntil, NOW + 1800 + 900 + 1800, "bought time is never cut by a reward's cap")
		Rewards.pay(farm, { coins = 0, luck = 15 }, NOW)
		T.ok(farm.luckPotionUntil >= NOW + 1800 + 900 + 1800, "a reward never shortens a bought potion")
	end)

	T.test("gold packs pay coin bases; spins go into the bank", function()
		local farm = farmWith()
		local base = Rewards.coinBase(farm)
		Products.grant(farm, "goldSack", NOW)
		T.eq(farm.coins, 7 * base)
		Products.grant(farm, "goldVault", NOW)
		T.eq(farm.coins, 57 * base)
		T.eq(farm.rewards.wheel.bank, 0)
		Products.grant(farm, "spin5", NOW)
		Products.grant(farm, "spin12", NOW)
		T.eq(farm.rewards.wheel.bank, 17)
	end)

	T.test("the Starter Pack is once an account: gold, spins, an hour of luck and five ore", function()
		local farm = farmWith()
		T.ok(Products.canBuy(farm, "starterPack", NOW))
		local ore = farm.materials.ore or 0
		local base = Rewards.coinBase(farm)
		T.same(
			{ Products.redeem(farm, "starterPack", "sp1", NOW) },
			{ true, "GRANTED", "starter pack, gold " .. 7 * base }
		)
		T.eq(farm.coins, 7 * base)
		T.eq(farm.rewards.wheel.bank, 5)
		T.eq(farm.luckPotionUntil, NOW + 3600)
		T.eq((farm.materials.ore or 0) - ore, 5)
		T.eq(farm.robux.starterBought, true)
		T.same({ Products.canBuy(farm, "starterPack", NOW) }, { false, "STARTER_BOUGHT" })
		T.same({ Products.canBuy(farmWith(), "starterPack", NOW, true) }, { false, "RESTRICTED" })
	end)

	T.test(
		"what may be bought: a pass once, the next tier needs the one before, a lower luck tier is refused, random items are region-gated",
		function()
			local farm = farmWith()
			T.same({ Products.canBuy(farm, "nope", NOW) }, { false, "UNKNOWN" })
			T.eq(Products.canBuy(farm, "vip", NOW), true)
			farm.robux.passes.vip = true
			T.same({ Products.canBuy(farm, "vip", NOW) }, { false, "OWNED" })
			T.same({ Products.canBuy(farm, "team6", NOW) }, { false, "NEEDS_PASS" })
			farm.robux.passes.team5 = true
			T.eq(Products.canBuy(farm, "team6", NOW), true)
			farm.robux.passes.luck4 = true
			T.same({ Products.canBuy(farm, "luck2", NOW) }, { false, "BETTER_OWNED" })
			T.same({ Products.canBuy(farm, "luck4", NOW) }, { false, "OWNED" })
			T.eq(Products.canBuy(farm, "luck8", NOW), true)
			T.same({ Products.canBuy(farm, "spin1", NOW, true) }, { false, "RESTRICTED" })
			T.eq(Products.canBuy(farm, "spin1", NOW, false), true)
			T.eq(Products.canBuy(farm, "goldPouch", NOW, true), true, "gold is not a random item")
			T.eq(Products.paidRandom(product("spin12")), true)
			T.eq(Products.paidRandom(product("starterPack")), true, "it holds spins")
			T.eq(Products.paidRandom(product("hatchPotion")), false)
		end
	)

	T.test("the Energy Drink fills every living slime's energy and wakes it; a fallen one is not revived", function()
		local farm = farmWith()
		farm.slimes = FarmKit.many(4)
		T.same({ Products.canBuy(farm, "energyDrink", NOW) }, { false, "NOT_TIRED" })
		for index, slime in farm.slimes do
			slime.needs.energy = index * 10
		end
		farm.slimes[2].sleeping = true
		farm.slimes[4].ghostUntil = NOW + 500
		T.eq(Products.canBuy(farm, "energyDrink", NOW), true)
		Products.grant(farm, "energyDrink", NOW)
		T.eq(farm.slimes[1].needs.energy, Config.Needs.Start)
		T.eq(farm.slimes[2].needs.energy, Config.Needs.Start)
		T.eq(farm.slimes[2].sleeping, nil)
		T.eq(farm.slimes[3].needs.energy, Config.Needs.Start)
		T.eq(farm.slimes[4].needs.energy, 40, "a ghost stays as it is")
		T.eq(farm.slimes[4].ghostUntil, NOW + 500)
	end)

	T.test("the Starter Pack's luck is a paid potion: all of it is added, even on a full reward potion", function()
		local farm = farmWith()
		local full = NOW + Config.Rewards.LuckMaxMinutes * 60
		farm.luckPotionUntil = full
		Products.grant(farm, "starterPack", NOW)
		T.eq(farm.luckPotionUntil, full + 3600)
	end)

	T.test("an Energy Drink paid when nobody is tired is banked, and spent when someone is", function()
		local farm = farmWith()
		farm.slimes = FarmKit.many(2)
		T.same({ Products.redeem(farm, "energyDrink", "d1", NOW) }, { true, "GRANTED", "energy drink banked 1" })
		T.eq(farm.robux.drinks, 1)
		T.same({ Products.useBanked(farm, "energyDrink", NOW) }, { false, "NOT_TIRED" })
		T.eq(farm.robux.drinks, 1, "nothing spent while nobody is tired")
		farm.slimes[1].needs.energy = 10
		T.eq((Products.useBanked(farm, "energyDrink", NOW)), true)
		T.eq(farm.slimes[1].needs.energy, Config.Needs.Start)
		T.eq(farm.robux.drinks, 0)
		T.same({ Products.useBanked(farm, "energyDrink", NOW) }, { false, "NONE" })
		T.same({ Products.useBanked(farm, "starterPack", NOW) }, { false, "UNKNOWN" })
	end)

	T.test("a Hatch All Now paid with no egg growing is banked, and spent when one is", function()
		local farm = farmWith()
		farm.slimes = FarmKit.many(2)
		T.same({ Products.redeem(farm, "hatchAll", "h9", NOW) }, { true, "GRANTED", "hatch all banked 1" })
		T.eq(farm.robux.hatchAlls, 1)
		T.same({ Products.useBanked(farm, "hatchAll", NOW) }, { false, "NO_EGGS" })
		local laid = Breeding.createEgg(farm, "s1", "s2", NOW, Rng.new(1), FarmKit.ids())
		assert(laid.ok, tostring(laid.reason))
		local eggs: any = laid.farm
		T.eq((Products.useBanked(eggs, "hatchAll", NOW)), true)
		T.ok(eggs.eggs[1].hatchAt <= NOW, "ready now")
		T.eq(eggs.robux.hatchAlls, 0)
		T.same({ Products.useBanked(eggs, "hatchAll", NOW) }, { false, "NONE" })
		T.eq(VillageRequests.valid({ action = "UseBanked", key = "hatchAll" }, true), true)
		T.eq(VillageRequests.valid({ action = "UseBanked", key = 5 }, true), false)
	end)

	T.test("an egg's hatch bar keeps its fraction when a potion changes the time left", function()
		local farm = farmWith()
		farm.slimes = FarmKit.many(2)
		local laid = Breeding.createEgg(farm, "s1", "s2", NOW, Rng.new(1), FarmKit.ids())
		assert(laid.ok, tostring(laid.reason))
		local eggs: any = laid.farm
		local egg = eggs.eggs[1]
		T.eq(egg.hatchStart, NOW, "the start is stored when the egg is laid")
		local function fraction(now: number): number
			return (now - egg.hatchStart) / (egg.hatchAt - egg.hatchStart)
		end
		local middle = NOW + (egg.hatchAt - NOW) / 2
		T.near(fraction(middle), 0.5, 1e-9)
		Products.grant(eggs, "hatchPotion", middle)
		T.near(fraction(middle), 0.5, 1e-9, "a potion starting does not move the bar")
		local repaired: any = FarmState.repair(eggs, middle)
		T.eq(repaired.eggs[1].hatchStart, egg.hatchStart, "the start survives a save")
	end)

	T.test("what a reward pays is what is credited and shown: VIP and a Gold Potion count in", function()
		local farm = farmWith({ "vip" })
		farm.boosts.gold = NOW + 600
		local plain = Rewards.grant(Config.Rewards.Daily[1], farm).coins
		local expected = math.floor(plain * 3 + 0.5)
		local shown = Rewards.view(farm, NOW).daily[1][1]
		T.eq(shown, expected, "the view carries the boosted amount")
		local before = farm.coins
		local ok, _, coins = Rewards.claimDaily(farm, NOW)
		T.ok(ok)
		T.eq(coins, expected, "the claim answers the credited coins")
		T.eq(farm.coins - before, coins)
		local _, credited = Rewards.pay(farm, { coins = 100, luck = 0 }, NOW)
		T.eq(credited, 300)
		local spinFarm = farmWith({ "vip" })
		local view = Wheel.view(spinFarm, NOW)
		local ok2, _, index, grant = Wheel.spin(spinFarm, Rng.sequence({ 0.1 }), NOW, false)
		T.ok(ok2 and grant)
		T.eq(spinFarm.coins, grant.coins, "the spin's grant says what was credited")
		T.eq(view.slices[index].coins, grant.coins, "the wheel showed the same amount")
	end)

	-- ===== quests and the check-in =====

	T.test("the Quest Reroll is banked and spent after the free redraw; a refused redraw spends nothing", function()
		local farm = farmWith()
		farm.rewards.quests = { day = Rewards.dayOf(NOW), list = {}, bonus = false, rerolls = 0, freeUsed = 0 }
		T.same({ Products.canBuy(farm, "questReroll", NOW) }, { false, "NO_QUEST" })
		local made = FarmState.newFarm(NOW)
		made.tutorialDone = true
		made.areas.fishing.level, made.areas.garden.level = 12, 12
		for _, id in Config.Village.Areas do
			made.areas[id].level = 20
		end
		for _, area in { "kitchen", "fishing", "garden" } do
			made.work[area].slots[1].worker = made.slimes[1].id
		end
		Rewards.ensureQuests(made, 7, NOW)
		T.eq(Products.canBuy(made, "questReroll", NOW), true)
		Products.grant(made, "questReroll", NOW)
		Products.grant(made, "questReroll", NOW)
		T.eq(made.robux.rerolls, 2)
		T.ok(Rewards.reroll(made, 1, 5, NOW), "the free one first")
		T.eq(made.robux.rerolls, 2, "the bank is untouched while a free redraw is left")
		T.ok(Rewards.reroll(made, 2, 5, NOW), "then a bought one")
		T.eq(made.robux.rerolls, 1)
		made.rewards.quests.list[3].claimed = true
		T.same({ Rewards.reroll(made, 3, 5, NOW) }, { false, "TAKEN" })
		T.eq(made.robux.rerolls, 1, "a refusal costs no bought redraw")
		T.ok(Rewards.reroll(made, 4, 5, NOW))
		T.eq(made.robux.rerolls, 0)
		T.same({ Rewards.reroll(made, 1, 5, NOW) }, { false, "NO_REROLL" })
		T.eq(Rewards.view(made, NOW).rerollBank, 0)
	end)

	T.test(
		"the Streak Saver mends a check-in run broken by exactly one missed day, and is offered only then",
		function()
			local farm = farmWith()
			-- no run at all
			T.eq(Rewards.mendable(farm, NOW), false)
			T.same({ Products.canBuy(farm, "streakSaver", NOW) }, { false, "NOT_BROKEN" })
			for day = 0, 2 do
				T.ok((Rewards.claimDaily(farm, NOW + day * DAY)))
			end
			local last = NOW + 2 * DAY
			T.eq(farm.rewards.daily.streak, 3)
			T.eq(Rewards.mendable(farm, last), false, "taken today")
			T.eq(Rewards.mendable(farm, last + DAY), false, "not yet missed: it simply continues")
			T.eq(Rewards.mendable(farm, last + 2 * DAY), true, "exactly one missed day")
			T.eq(Rewards.mendable(farm, last + 3 * DAY), false, "two missed days cannot be mended")
			T.eq(Rewards.view(farm, last + 2 * DAY).mendable, true)
			T.same({ Rewards.mendStreak(farm, last + 3 * DAY) }, { false, "NOT_BROKEN" })
			-- bought while mendable: mended at once, nothing banked
			local day = last + 2 * DAY
			T.eq(Products.canBuy(farm, "streakSaver", day), true)
			T.eq((Rewards.dailyDay(farm, day)), 1, "without it the run starts over")
			Products.grant(farm, "streakSaver", day)
			T.eq(farm.robux.savers, 0)
			T.eq((Rewards.dailyDay(farm, day)), 4, "with it the run goes on to day 4")
			T.ok((Rewards.claimDaily(farm, day)))
			T.eq(farm.rewards.daily.streak, 4)
			-- bought just before midnight and granted after it: banked, used by the next check-in
			local other = farmWith()
			for d = 0, 1 do
				Rewards.claimDaily(other, NOW + d * DAY)
			end
			Products.grant(other, "streakSaver", NOW + DAY)
			T.eq(other.robux.savers, 1, "not mendable now: banked")
			local missed = NOW + 3 * DAY
			T.ok((Rewards.claimDaily(other, missed)))
			T.eq(other.rewards.daily.streak, 3, "the banked saver mended the run")
			T.eq(other.robux.savers, 0)
		end
	)

	-- ===== receipts and the save =====

	T.test("a receipt is granted once, however often Roblox asks", function()
		local farm = farmWith()
		local base = Rewards.coinBase(farm)
		T.same({ Products.redeem(farm, "goldPouch", "r-1", NOW) }, { true, "GRANTED", "gold " .. 2 * base })
		T.eq(farm.coins, 2 * base)
		T.same({ Products.redeem(farm, "goldPouch", "r-1", NOW) }, { true, "DUPLICATE" })
		T.same({ Products.redeem(farm, "goldPouch", "r-1", NOW + 99) }, { true, "DUPLICATE" })
		T.eq(farm.coins, 2 * base, "paid once")
		T.ok(Products.redeem(farm, "goldPouch", "r-2", NOW))
		T.eq(farm.coins, 4 * base, "a different purchase is a different receipt")
		T.same(farm.robux.receipts, { "r-1", "r-2" })
		T.same({ Products.redeem(farm, "vip", "r-3", NOW) }, { false, "UNKNOWN" }, "a pass is not a developer product")
		T.same({ Products.redeem(farm, "nope", "r-4", NOW) }, { false, "UNKNOWN" })
		T.eq(#farm.robux.receipts, 2, "a refused one is not recorded")
	end)

	T.test("receipts are bounded: the newest are kept", function()
		local farm = farmWith()
		for index = 1, R.ReceiptsKept + 50 do
			Products.takeReceipt(farm, "r" .. index)
		end
		T.eq(#farm.robux.receipts, R.ReceiptsKept)
		T.eq(farm.robux.receipts[#farm.robux.receipts], "r" .. (R.ReceiptsKept + 50))
		T.ok(not Products.hasReceipt(farm, "r1"))
		T.ok(Products.hasReceipt(farm, "r" .. (R.ReceiptsKept + 50)))
		T.eq(#FarmState.repair(farm, NOW).robux.receipts, R.ReceiptsKept)
	end)

	T.test("through the real save path: a receipt granted on one server is not granted again by another", function()
		local clock = { t = NOW }
		local function now()
			return clock.t
		end
		local function wait(seconds: number)
			clock.t += seconds
		end
		local backing = Fake.newBacking()
		local function server(jobId: string)
			return ProfileStore.new({
				store = Fake.new(backing),
				hooks = FarmSave.hooks(),
				jobId = jobId,
				placeId = 1,
				now = now,
				wait = wait,
				log = function() end,
			})
		end
		local a, b = server("A"), server("B")
		local key = "Player_9"
		local profile = a.load(key, { 9 })
		assert(profile, "loaded")
		local base = Rewards.coinBase(profile.data)
		local before = profile.data.coins
		-- what Purchases.deliver does: redeem inside the update, then write now
		T.same(
			{ Products.redeem(profile.data, "goldSack", "receipt-1", now()) },
			{ true, "GRANTED", "gold " .. 7 * base }
		)
		a.markDirty(profile)
		T.eq(a.save(profile), true)
		T.eq(a.release(profile), true)
		local again = b.load(key, { 9 })
		assert(again, "loaded on the other server")
		T.eq(again.data.coins, before + 7 * base)
		T.ok(Products.hasReceipt(again.data, "receipt-1"), "the receipt came through the save and its repair")
		T.same({ Products.redeem(again.data, "goldSack", "receipt-1", now()) }, { true, "DUPLICATE" })
		T.eq(again.data.coins, before + 7 * base, "Roblox asking again on the second server grants nothing")
		T.ok(Products.redeem(again.data, "goldSack", "receipt-2", now()))
		T.eq(again.data.coins, before + 14 * base)
	end)

	-- ===== the schema-13 save =====

	T.test("a schema 12 save migrates: no boosts, no receipts, six teams, nothing else touched", function()
		T.eq(Config.Save.SchemaVersion, 14)
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		farm.coins = 777
		farm.teams[1].members = { "s1", "s2" }
		farm.teams[1].repeatOn = true
		local stored: any = FarmState.repair(farm, NOW)
		stored.boosts, stored.robux = nil, nil
		while #stored.teams > 4 do
			table.remove(stored.teams)
		end
		local result =
			ProfileLogic.prepareLoad({ schemaVersion = 12, savedAt = NOW, data = stored }, FarmSave.hooks(), NOW + 1)
		T.ok(result.ok and result.migrated)
		T.eq(result.data.coins, 777)
		T.same(result.data.boosts, { gold = 0, hatch = 0 })
		T.same(
			result.data.robux,
			{ receipts = {}, passes = {}, starterBought = false, rerolls = 0, savers = 0, drinks = 0, hatchAlls = 0 }
		)
		T.eq(#result.data.teams, 6)
		T.same(result.data.teams[1].members, { "s1", "s2" })
		T.eq(result.data.teams[1].repeatOn, true)
		T.eq(#result.data.teams[6].members, 0)
		T.eq(stored.boosts, nil, "the stored snapshot is not changed")
		-- the same through the migration alone
		local direct = ProfileLogic.migrateRobux(stored, NOW)
		T.same(direct.boosts, { gold = 0, hatch = 0 })
		T.eq(#direct.teams, 6)
	end)

	T.test("repair mends each Robux field alone and never invents a pass", function()
		local farm: any = FarmState.repair(FarmKit.farm(NOW), NOW)
		farm.boosts = { gold = -5, hatch = "soon" }
		farm.robux = {
			receipts = { "ok-1", 42, "ok-2", {} },
			passes = { vip = true, luck8 = true, goldPouch = true, nonsense = true, team5 = "yes" },
			starterBought = "maybe",
			rerolls = -3,
			savers = 2.5,
			drinks = -1,
			hatchAlls = 3.7,
		}
		local mended: any = FarmState.repair(farm, NOW)
		T.same(mended.boosts, { gold = 0, hatch = 0 })
		T.same(mended.robux.receipts, { "ok-1", "ok-2" })
		T.same(mended.robux.passes, { vip = true, luck8 = true }, "only pass keys, only true")
		T.eq(mended.robux.starterBought, false)
		T.eq(mended.robux.rerolls, 0)
		T.eq(mended.robux.savers, 2, "a fraction is cut to a whole number")
		T.eq(mended.robux.drinks, 0)
		T.eq(mended.robux.hatchAlls, 3)
		farm.boosts, farm.robux = "x", 7
		local blank: any = FarmState.repair(farm, NOW)
		T.same(blank.boosts, { gold = 0, hatch = 0 })
		T.same(
			blank.robux,
			{ receipts = {}, passes = {}, starterBought = false, rerolls = 0, savers = 0, drinks = 0, hatchAlls = 0 }
		)
		T.eq(#FarmState.repair(farm, NOW).teams, 6)
	end)
end
