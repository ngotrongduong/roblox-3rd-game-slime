--!strict
-- Rewards for coming back: the check-in runs on days in a row, quests are measured by the farm's own counts, online gifts
-- by minutes played today; a claim pays once and a refusal changes nothing; all of it is saved, repaired and migrated.
local Config = require("../../src/shared/Config")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Guide = require("../../src/shared/Guide")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rewards = require("../../src/shared/Rewards")
local Shop = require("../../src/shared/Shop")
local VillageRequests = require("../../src/shared/VillageRequests")

local DAY = 86400
-- noon of a UTC day
local NOW = 20000 * DAY + 12 * 3600
local R = Config.Rewards

local function played(farm: any): any
	farm.tutorialDone = true
	farm.guide.step = Guide.Done
	return farm
end

local function env(unsaved: number?): any
	local left = unsaved or 0
	return {
		isOut = function()
			return false
		end,
		atMarket = function()
			return true
		end,
		nearGate = function()
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
		unsavedPlay = function()
			local out = left
			left = 0
			return out
		end,
	}
end

return function(T: any)
	T.test("coins are a share of the cheapest upgrade, rounded to two figures, never under the floor", function()
		local farm: any = FarmState.newFarm(NOW)
		T.eq(Rewards.coinBase(farm), 150)
		T.eq(Rewards.grant({ coins = 2 }, farm).coins, 300)
		T.eq(Rewards.grant({ coins = 0.1 }, farm).coins, R.CoinFloor)
		T.eq(Rewards.grant({ luck = 15 }, farm).coins, 0)
		T.eq(Rewards.grant({ luck = 15 }, farm).luck, 15)
		for _, id in Config.Village.Areas do
			farm.areas[id].level = Config.Village.MaxLevel
		end
		T.ok(Rewards.coinBase(farm) > 0, "a finished village still pays")
	end)

	T.test("the check-in pays once a day, runs on days in a row and starts over after a missed day", function()
		local farm: any = FarmState.newFarm(NOW)
		T.same({ Rewards.dailyDay(farm, NOW) }, { 1, false })
		local ok, _, coins = Rewards.claimDaily(farm, NOW)
		T.ok(ok)
		T.eq(farm.coins, coins)
		T.same({ Rewards.claimDaily(farm, NOW + 3600) }, { false, "TAKEN" })
		T.eq(farm.coins, coins, "a refusal pays nothing")
		local now = NOW
		for day = 2, #R.Daily do
			now += DAY
			T.eq((Rewards.dailyDay(farm, now)), day)
			T.ok((Rewards.claimDaily(farm, now)))
		end
		-- day 7 gave luck; after day 7 comes day 1
		T.ok(farm.luckPotionUntil > now)
		T.eq((Rewards.dailyDay(farm, now + DAY)), 1)
		T.ok((Rewards.claimDaily(farm, now + DAY)))
		T.eq((Rewards.dailyDay(farm, now + 2 * DAY)), 2)
		-- a whole day missed: back to day 1
		T.eq((Rewards.dailyDay(farm, now + 3 * DAY)), 1)
	end)

	T.test("luck adds to the time left and never passes the cap", function()
		local farm: any = FarmState.newFarm(NOW)
		Rewards.pay(farm, { coins = 0, luck = 30 }, NOW)
		T.eq(farm.luckPotionUntil, NOW + 1800)
		Rewards.pay(farm, { coins = 0, luck = 30 }, NOW + 600)
		T.eq(farm.luckPotionUntil, NOW + 3600)
		Rewards.pay(farm, { coins = 0, luck = 999 }, NOW)
		T.eq(farm.luckPotionUntil, NOW + R.LuckMaxMinutes * 60)
	end)

	T.test("quests wait for the tutorial, are the same for a player all day and differ in kind", function()
		local farm: any = FarmState.newFarm(NOW)
		while #farm.slimes > 4 do
			table.remove(farm.slimes)
		end
		T.ok(not Rewards.ensureQuests(farm, 42, NOW), "no quests during the tutorial")
		played(farm)
		T.ok(Rewards.ensureQuests(farm, 42, NOW))
		T.ok(not Rewards.ensureQuests(farm, 42, NOW + 60), "made once a day")
		local list = farm.rewards.quests.list
		T.eq(#list, R.QuestCount)
		local kinds = {}
		for _, quest in list do
			T.ok(not kinds[quest.kind], "two quests of one kind")
			kinds[quest.kind] = true
			T.ok(quest.kind ~= "sell", "a village of 4 cannot sell")
		end
		T.same(Rewards.makeQuests(farm, 42, Rewards.dayOf(NOW)), Rewards.makeQuests(farm, 42, Rewards.dayOf(NOW)))
		T.ok(Rewards.ensureQuests(farm, 42, NOW + DAY), "a new day, a new list")
	end)

	T.test("a quest counts from when it was made and pays once when done", function()
		local farm: any = played(FarmState.newFarm(NOW))
		farm.lifetime.meals = 50
		farm.rewards.quests = {
			day = Rewards.dayOf(NOW),
			list = { { kind = "feed", need = 10, mark = 50, claimed = false } },
			bonus = false,
		}
		local quest = farm.rewards.quests.list[1]
		T.eq(Rewards.progress(farm, quest), 0)
		T.same({ Rewards.claimQuest(farm, 1, NOW) }, { false, "NOT_DONE" })
		farm.lifetime.meals = 57
		T.eq(Rewards.progress(farm, quest), 7)
		farm.lifetime.meals = 99
		T.eq(Rewards.progress(farm, quest), 10, "never past the need")
		T.eq(Rewards.ready(farm, NOW), 2, "the quest and today's check-in")
		local ok, _, coins = Rewards.claimQuest(farm, 1, NOW)
		T.ok(ok and coins and coins > 0)
		T.same({ Rewards.claimQuest(farm, 1, NOW) }, { false, "TAKEN" })
		T.same({ Rewards.claimQuest(farm, 1, NOW + DAY) }, { false, "NO_QUEST" }, "yesterday's quests are gone")
	end)

	T.test("every kind of quest moves with what the player does", function()
		local farm: any = played(FarmState.newFarm(NOW))
		local before = {}
		for _, kind in R.QuestKinds do
			before[kind] = Rewards.count(farm, kind)
		end
		-- a sale, a meal, a zombie, an egg laid and hatched, an upgrade
		local extra = FarmState.newStarters(NOW)
		for i, slime in extra do
			slime.id = "extra-" .. i
			table.insert(farm.slimes, slime)
		end
		T.ok(Shop.sell(farm, "extra-1", NOW) ~= nil)
		farm.lifetime.meals += 1
		farm.lifetime.mobsKilled += 1
		farm.lifetime.breeds += 1
		farm.discoveries.base.navy.hatchCount += 1
		farm.areas.garden.level += 1
		for _, kind in R.QuestKinds do
			T.eq(Rewards.count(farm, kind), before[kind] + 1, kind)
		end
	end)

	T.test("the bonus comes once every quest is claimed", function()
		local farm: any = played(FarmState.newFarm(NOW))
		Rewards.ensureQuests(farm, 7, NOW)
		T.eq(Rewards.bonusState(farm, NOW), 0)
		T.same({ Rewards.claimBonus(farm, NOW) }, { false, "NOT_DONE" })
		for _, quest in farm.rewards.quests.list do
			quest.mark -= quest.need
		end
		for index in farm.rewards.quests.list do
			T.ok((Rewards.claimQuest(farm, index, NOW)))
		end
		T.eq(Rewards.bonusState(farm, NOW), 1)
		T.ok((Rewards.claimBonus(farm, NOW)))
		T.ok(farm.luckPotionUntil > NOW)
		T.same({ Rewards.claimBonus(farm, NOW) }, { false, "TAKEN" })
	end)

	T.test("online gifts open with minutes played today and start again the next day", function()
		local farm: any = FarmState.newFarm(NOW)
		T.same({ Rewards.claimOnline(farm, 1, NOW) }, { false, "NOT_YET" })
		Rewards.addPlayed(farm, NOW, 59)
		T.same({ Rewards.claimOnline(farm, 1, NOW) }, { false, "NOT_YET" })
		Rewards.addPlayed(farm, NOW + 1, 1)
		T.ok((Rewards.claimOnline(farm, 1, NOW + 1)))
		T.same({ Rewards.claimOnline(farm, 1, NOW + 2) }, { false, "TAKEN" })
		T.same({ Rewards.claimOnline(farm, 2, NOW + 2) }, { false, "NOT_YET" })
		T.same({ Rewards.claimOnline(farm, 99, NOW + 2) }, { false, "NO_GIFT" })
		-- across midnight only the part after it counts, and every gift is there again
		local midnight = (Rewards.dayOf(NOW) + 1) * DAY
		Rewards.addPlayed(farm, midnight + 30, 300)
		T.eq(Rewards.played(farm, midnight + 30), 30)
		T.eq(#farm.rewards.online.claimed, 0)
		Rewards.addPlayed(farm, midnight + 60, 30)
		T.ok((Rewards.claimOnline(farm, 1, midnight + 60)))
	end)

	T.test("requests claim through the remote rules; the online claim counts unsaved play first", function()
		local farm: any = played(FarmState.newFarm(NOW))
		for _, data in
			{
				{ action = "ClaimDaily" },
				{ action = "ClaimQuest", index = 1 },
				{ action = "ClaimQuestBonus" },
				{ action = "ClaimOnline", step = 1 },
				{ action = "IndexSeen" },
			}
		do
			T.ok(VillageRequests.valid(data, true), data.action)
		end
		T.ok(not VillageRequests.valid({ action = "ClaimQuest", index = 0 }, true))
		T.ok(not VillageRequests.valid({ action = "ClaimQuest", index = 1.5 }, true))
		T.ok(not VillageRequests.valid({ action = "ClaimOnline", step = #R.Online + 1 }, true))
		local ok, _, coins = VillageRequests.run(farm, { action = "ClaimOnline", step = 1 }, NOW, env(61))
		T.ok(ok and coins and coins > 0)
		T.ok((VillageRequests.run(farm, { action = "ClaimDaily" }, NOW, env())))
		T.ok((VillageRequests.run(farm, { action = "IndexSeen" }, NOW, env())))
		T.ok(farm.rewards.indexSeen)
		T.ok(not (VillageRequests.run(farm, { action = "IndexSeen" }, NOW, env())))
	end)

	T.test("the rewards and index intros open when they matter and close when used", function()
		local farm: any = played(FarmState.newFarm(NOW))
		for _, id in Config.Guide.Intros do
			if id ~= "rewards" and id ~= "index" then
				farm.guide.seen[id] = true
			end
		end
		local home = { atMarket = false, atHome = true }
		Guide.update(farm, NOW, home)
		T.eq(farm.guide.intro, "rewards", "today's check-in waits")
		Rewards.claimDaily(farm, NOW)
		Guide.update(farm, NOW, home)
		T.eq(farm.guide.intro, nil)
		T.ok(farm.guide.seen.rewards)
		farm.discoveries.base.red = { firstDiscoveredAt = NOW, hatchCount = 1 }
		Guide.update(farm, NOW, home)
		T.eq(farm.guide.intro, "index")
		farm.rewards.indexSeen = true
		Guide.update(farm, NOW, home)
		T.ok(farm.guide.seen.index)
	end)

	T.test("rewards are saved and repaired part by part, and schema 7 saves migrate", function()
		local farm: any = played(FarmState.newFarm(NOW))
		Rewards.ensureQuests(farm, 3, NOW)
		Rewards.claimDaily(farm, NOW)
		Rewards.addPlayed(farm, NOW, 120)
		Rewards.claimOnline(farm, 1, NOW)
		local copy = FarmState.repair(farm, NOW)
		T.same(copy.rewards, farm.rewards)
		local broken: any = FarmState.newFarm(NOW)
		broken.rewards = {
			daily = { streak = 99, day = -4 },
			quests = { day = 5, list = { { kind = "dance", need = 2, mark = 0 } }, bonus = true },
			online = { day = 7, secs = "x", claimed = { 1, 1, 99, 2.5, 3 } },
		}
		local fixed = FarmState.repair(broken, NOW)
		T.same(fixed.rewards.daily, { streak = #R.Daily, day = 0 })
		T.same(fixed.rewards.quests, { day = 0, list = {}, bonus = false })
		T.same(fixed.rewards.online, { day = 7, secs = 0, claimed = { 1, 3 } })
		local old: any = FarmState.newFarm(NOW)
		old.rewards = nil
		old.lifetime.slimesSold = nil
		old.lifetime.meals = nil
		old.coins = 555
		local load =
			ProfileLogic.prepareLoad({ schemaVersion = 7, savedAt = NOW, data = old }, FarmSave.hooks(), NOW + 1)
		T.ok(load.ok and load.migrated)
		T.eq(load.data.coins, 555)
		T.same(load.data.rewards, FarmState.newRewards())
		T.eq(load.data.lifetime.meals, 0)
		T.eq(old.rewards, nil, "migration never alters the stored snapshot")
	end)

	T.test("the view lists what the client draws", function()
		local farm: any = played(FarmState.newFarm(NOW))
		Rewards.ensureQuests(farm, 9, NOW)
		local view = Rewards.view(farm, NOW)
		T.eq(view.day, 1)
		T.eq(view.taken, false)
		T.eq(#view.daily, #R.Daily)
		T.eq(#view.quests, R.QuestCount)
		T.eq(#view.online, #R.Online)
		T.eq(view.bonus[1], 0)
		T.eq(view.reset, NOW + 12 * 3600)
	end)
end
