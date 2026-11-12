--!strict
-- The Index pays coins once per kind found (Config.Index.DiscoverCoins), and several slimes sell in one go (Shop.sellMany).
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Genetics = require("../../src/shared/Genetics")
local Hatching = require("../../src/shared/Hatching")
local Mutations = require("../../src/shared/Mutations")
local Shop = require("../../src/shared/Shop")
local Stats = require("../../src/shared/Stats")
local Village = require("../../src/shared/Village")
local VillageRequests = require("../../src/shared/VillageRequests")

local NOW = 3000000

-- Adds a ready egg with a chosen embryo to the farm.
local function addEgg(farm: any, id: string, appearance: any, colour: string)
	table.insert(farm.eggs, {
		id = id,
		parentIds = { "slime-1", "slime-2" },
		createdAt = NOW - 60,
		hatchAt = NOW,
		place = "incubator",
		slot = 1,
		offspringId = "baby-" .. id,
		embryo = {
			stats = { attack = 4, defence = 2, speed = 1, hp = 30 },
			colourGenotype = Genetics.fromAppearance(appearance, { alleles = { colour, colour } }),
			appearanceMutation = appearance,
		},
		status = "ready",
	})
end

-- Hatches one egg of the given kind and returns the new farm and what the hatch paid.
local function hatchOne(farm: any, id: string, appearance: any, colour: string): (any, number)
	addEgg(farm, id, appearance, colour)
	local res = Hatching.hatch(farm, id, NOW)
	assert(res.ok, "hatched")
	return res.farm, res.discoveryCoins or 0
end

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

local function ids(from: number, to: number): { string }
	local out = {}
	for i = from, to do
		table.insert(out, "s" .. i)
	end
	return out
end

return function(T: any)
	T.test("a new plain colour pays once, a repeat pays nothing, also after a save round trip", function()
		local pays = Config.Index.DiscoverCoins.plain
		T.ok(pays > 0)
		local farm = FarmKit.farm(NOW)
		local coins, earned = farm.coins, farm.lifetime.coinsEarned
		local gained
		farm, gained = hatchOne(farm, "e1", { type = "none" }, "red")
		T.eq(gained, pays)
		T.eq(farm.coins, coins + pays)
		T.eq(farm.lifetime.coinsEarned, earned + pays)
		-- the same colour again, on the live farm and on a farm that went through the save repair
		farm, gained = hatchOne(farm, "e2", { type = "none" }, "red")
		T.eq(gained, 0)
		T.eq(farm.coins, coins + pays)
		local repaired = (FarmState.repair(farm, NOW))
		repaired, gained = hatchOne(repaired, "e3", { type = "none" }, "red")
		T.eq(gained, 0)
		T.eq(repaired.coins, coins + pays)
	end)

	T.test("the starter colour pays nothing", function()
		local farm = FarmKit.farm(NOW)
		local coins = farm.coins
		local gained
		farm, gained = hatchOne(farm, "e1", { type = "none" }, Config.Farm.StarterColour)
		T.eq(gained, 0)
		T.eq(farm.coins, coins)
	end)

	T.test("a Dual, a material and a Secret each pay their own amount, once", function()
		local kinds = {
			{ kind = "dual", appearance = { type = "dual", definitionId = "dual-red-pink-38" } },
			{ kind = "material", appearance = { type = "material", definitionId = "gold" } },
			{ kind = "secret", appearance = { type = "secret", definitionId = "secret-navy-red" } },
		}
		for _, item in kinds do
			local pays = (Config.Index.DiscoverCoins :: any)[item.kind]
			T.ok(pays > 0, item.kind .. " pays")
			local farm = FarmKit.farm(NOW)
			local coins = farm.coins
			local gained
			farm, gained = hatchOne(farm, "e1", item.appearance, "red")
			T.eq(gained, pays, item.kind)
			T.eq(farm.coins, coins + pays, item.kind)
			farm, gained = hatchOne(farm, "e2", item.appearance, "red")
			T.eq(gained, 0, item.kind)
			T.eq(farm.coins, coins + pays, item.kind)
		end
	end)

	T.test("the reward is not held back by the coin vault", function()
		local farm = FarmKit.farm(NOW)
		local cap = Village.coinCap(farm.areas.pantry.level)
		farm.coins = cap
		local gained
		farm, gained = hatchOne(farm, "e1", { type = "none" }, "red")
		T.ok(gained > 0)
		T.eq(farm.coins, cap + gained)
	end)

	T.test("selling several slimes pays the sum of their prices and takes them all", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		local expected = 0
		for _, slime in farm.slimes do
			if slime.id == "s1" or slime.id == "s2" or slime.id == "s3" then
				expected += Mutations.sellValue(slime.appearanceMutation, Stats.level(slime.stats))
			end
		end
		local coins, sold = farm.coins, farm.lifetime.slimesSold
		local total, why = Shop.sellMany(farm, ids(1, 3), NOW)
		T.eq(why, nil)
		T.eq(total, expected)
		T.eq(farm.coins, coins + expected)
		T.eq(#farm.slimes, 3)
		T.eq(farm.lifetime.slimesSold, sold + 3)
	end)

	T.test("a refused multi-sale changes nothing", function()
		local function refused(farm: any, list: { string }, reason: string)
			local coins, count = farm.coins, #farm.slimes
			local total, why = Shop.sellMany(farm, list, NOW)
			T.eq(total, nil, reason)
			T.eq(why, reason)
			T.eq(farm.coins, coins, reason)
			T.eq(#farm.slimes, count, reason)
		end
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		refused(farm, {}, "INVALID_COUNT")
		refused(farm, { "s1", "s1" }, "DUPLICATE")
		refused(farm, { "s1", "nobody" }, "NO_SLIME")
		-- leaving fewer than the last two
		refused(farm, ids(1, 5), "LAST_SLIMES")
		-- one favourite in the list spoils the whole sale
		farm.slimes[2].isFavourite = true
		refused(farm, { "s1", "s2", "s3" }, "FAVOURITE")
		-- a dead one too
		farm.slimes[2].isFavourite = false
		farm.slimes[3].ghostUntil = NOW + 100
		refused(farm, { "s1", "s3" }, "DEAD")
	end)

	T.test("a multi-sale is capped in length", function()
		local max = Config.Zombies.SellManyMax
		local farm = FarmKit.farm(NOW, FarmKit.many(max + 4))
		local total = Shop.sellMany(farm, ids(1, max + 1), NOW)
		T.eq(total, nil)
		T.eq(#farm.slimes, max + 4)
		local paid = Shop.sellMany(farm, ids(1, max), NOW)
		T.ok(paid ~= nil)
		T.eq(#farm.slimes, 4)
	end)

	T.test("the SellMany request has a shape, needs the Market and a slime at home", function()
		local max = Config.Zombies.SellManyMax
		local long: { any } = {}
		for i = 1, max + 1 do
			table.insert(long, "s" .. i)
		end
		local bad: { any } = {
			{ action = "SellMany" },
			{ action = "SellMany", slimeIds = "s1" },
			{ action = "SellMany", slimeIds = {} },
			{ action = "SellMany", slimeIds = long },
			{ action = "SellMany", slimeIds = { 1, 2 } },
			{ action = "SellMany", slimeIds = { a = "s1" } },
			{ action = "SellMany", slimeIds = { string.rep("x", Config.Smithy.IdMaxLength + 1) } },
		}
		for i, request in bad do
			T.ok(not VillageRequests.valid(request), "request " .. i .. " is refused")
		end
		T.ok(VillageRequests.valid({ action = "SellMany", slimeIds = { "s1", "s2" } }))

		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		local request = { action = "SellMany", slimeIds = { "s1", "s2" } }
		local coins = farm.coins
		local function notThere()
			return false
		end
		local function isOut()
			return true
		end
		T.eq(select(2, VillageRequests.run(farm, request, NOW, env({ atMarket = notThere }))), "TOO_FAR")
		T.eq(select(2, VillageRequests.run(farm, request, NOW, env({ isOut = isOut }))), "OUT")
		T.eq(farm.coins, coins)
		T.eq(#farm.slimes, 6)
		local ok, _, paid = VillageRequests.run(farm, request, NOW, env())
		T.ok(ok)
		T.eq(farm.coins, coins + (paid :: number))
		T.eq(#farm.slimes, 4)
	end)
end
