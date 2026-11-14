--!strict
-- Rewards for coming back: the check-in runs on days in a row, quests are measured by the farm's own counts, online gifts
-- by minutes played today; a claim pays once and a refusal changes nothing; all of it is saved, repaired and migrated.
local ArenaSeason = require("../../src/shared/ArenaSeason")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Gear = require("../../src/shared/Gear")
local Guide = require("../../src/shared/Guide")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rewards = require("../../src/shared/Rewards")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local Stations = require("../../src/shared/Stations")
local VillageRequests = require("../../src/shared/VillageRequests")
local VillageSim = require("../../src/shared/VillageSim")

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
		userId = 77,
		seed = function()
			return 5
		end,
		isVip = function()
			return false
		end,
	}
end

-- A farm that has played: a team of its own so every kind of quest can be drawn.
local function bigFarm(): any
	local farm = played(FarmState.newFarm(NOW))
	for _, id in Config.Village.Areas do
		farm.areas[id].level = 20
	end
	for _, area in { "kitchen", "fishing", "garden" } do
		farm.work[area].slots[1].worker = farm.slimes[1].id
	end
	return farm
end

-- How many of a reward's items the farm holds now.
local function held(farm: any, kind: string, id: string): number
	if kind == "material" then
		return farm.materials[id] or 0
	elseif kind == "gear" then
		return farm.gear[id] or 0
	elseif kind == "food" then
		return farm.storehouse[id] or 0
	end
	return farm.fridge[id] or 0
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
		-- the counts the new kinds measure, bumped where the game does it (Dungeon.commitWave, ArenaRules.confirm, Gear.craft,
		-- VillageSim, Wheel.spin, Rewards.addPlayed)
		farm.lifetime.dungeonWaves += 1
		farm.lifetime.arenaAttacks += 1
		farm.lifetime.gearCrafted += 1
		farm.lifetime.dishesCooked += 1
		farm.lifetime.fishCaught += 1
		farm.lifetime.cropsHarvested += 1
		farm.lifetime.wheelSpins += 1
		farm.discoveries.base.red = { firstDiscoveredAt = NOW, hatchCount = 0 }
		Rewards.addPlayed(farm, NOW, 60)
		for _, kind in R.QuestKinds do
			T.eq(Rewards.count(farm, kind), before[kind] + 1, kind)
		end
	end)

	T.test("four daily quests of different kinds draw only what the farm can do", function()
		local farm: any = bigFarm()
		T.ok(Rewards.ensureQuests(farm, 42, NOW))
		T.eq(#farm.rewards.quests.list, 4)
		-- a new village has no Dungeon, Smithy or Arena, no cook, angler or gardener: those kinds are never drawn for it
		local small: any = played(FarmState.newFarm(NOW))
		for seed = 1, 40 do
			for _, quest in Rewards.makeQuests(small, seed, 5 + seed) do
				T.ok(not table.find({ "wave", "arena", "craft", "cook", "fish", "harvest" }, quest.kind), quest.kind)
			end
		end
		-- a village with all of them draws them across the days
		local drawn = {}
		for seed = 1, 60 do
			for _, quest in Rewards.makeQuests(farm, seed, 7) do
				drawn[quest.kind] = true
			end
		end
		for _, kind in R.QuestKinds do
			if kind ~= "sell" then
				T.ok(drawn[kind], kind .. " is never drawn")
			end
		end
	end)

	T.test("the counts are bumped where the game does it", function()
		-- gear made
		local farm: any = FarmKit.farm(NOW)
		farm.materials.wood = 2
		T.ok(Gear.craft(farm, "charm-wood") ~= nil)
		T.eq(farm.lifetime.gearCrafted, 1)
		T.eq(select(2, Gear.craft(farm, "charm-wood")), "INSUFFICIENT_MATERIALS")
		T.eq(farm.lifetime.gearCrafted, 1, "a refused craft is not counted")
		-- a Dungeon wave cleared (once, however often the server commits it)
		local ledger = Dungeon.newLedger()
		T.ok(Dungeon.commitWave(farm, ledger, 1) ~= nil)
		T.eq(Dungeon.commitWave(farm, ledger, 1), nil)
		T.eq(farm.lifetime.dungeonWaves, 1)
		-- fish caught and crops harvested by the simulation
		T.ok(Stations.assign(farm, "slime-1", "fishing", 1, false, NOW))
		T.ok(Stations.assign(farm, "slime-2", "garden", 1, false, NOW))
		local after, at = farm, NOW
		for step = 1, 120 do
			-- (rested and fed, so the workers keep working)
			for _, slime in after.slimes do
				slime.needs = FarmState.fullNeeds()
			end
			at += Config.Village.StepSeconds
			after = VillageSim.step(after, at, Config.Village.StepSeconds, Rng.new(step), { errands = false })
		end
		T.ok(after.lifetime.fishCaught > 0, "fish")
		T.ok(after.lifetime.cropsHarvested > 0, "crops")
		T.eq(farm.lifetime.fishCaught, 0, "the sim stays pure")
	end)

	T.test("quest texts read well for every kind", function()
		for _, kind in R.QuestKinds do
			local text = Rewards.questText({ kind = kind, need = 3, mark = 0, claimed = false })
			T.ok(#text > 6 and string.find(text, "3", 1, true) ~= nil, kind .. ": " .. text)
		end
	end)

	T.test("a reward pays items where the game keeps them", function()
		local farm: any = FarmState.newFarm(NOW)
		local grant = Rewards.grant({
			coins = 1,
			spins = 2,
			items = {
				{ kind = "material", id = "ore", count = 5 },
				{ kind = "gear", id = "charm-core", count = 1 },
				{ kind = "food", id = "carrot", count = 3 },
				{ kind = "dish", id = "grilledFish", count = 2 },
			},
		}, farm)
		T.eq(#grant.items, 4)
		local carrots = held(farm, "food", "carrot")
		T.eq(Rewards.pay(farm, grant, NOW), 0)
		T.eq(held(farm, "material", "ore"), 5)
		T.eq(held(farm, "gear", "charm-core"), 1)
		T.eq(held(farm, "food", "carrot"), carrots + 3)
		T.eq(held(farm, "dish", "grilledFish"), 2)
		T.eq(farm.rewards.wheel.bank, 2)
		T.eq(farm.coins, Config.Farm.StartingCoins + grant.coins)
		-- an item that is not in the game is not paid, a full store loses the rest and says how much
		local before = farm.materials.ore
		Rewards.pay(farm, { coins = 0, luck = 0, items = { { kind = "material", id = "nonsense", count = 4 } } }, NOW)
		T.eq(farm.materials.ore, before)
		farm.fridge = { grilledFish = FarmState.fridgeCapacity(farm.areas.kitchen.level) }
		local lost =
			Rewards.pay(farm, { coins = 0, luck = 0, items = { { kind = "dish", id = "veggieStew", count = 4 } } }, NOW)
		T.eq(lost, 4)
		-- the spec in Config is copied, never shared
		local basket = Rewards.grant(R.Daily[1], farm)
		basket.items[1].count = 99
		T.eq(R.Daily[1].items[1].count, 3)
	end)

	T.test("every reward in Config names real things", function()
		local farm: any = FarmState.newFarm(NOW)
		local specs: { any } = { R.QuestBonus, R.WeeklyChest }
		for _, list in { R.Daily, R.CheckinMilestones, R.QuestRewards, R.Online, Config.Goals.List } do
			for _, spec in list do
				table.insert(specs, spec)
			end
		end
		for _, def in R.Weekly do
			table.insert(specs, def.reward)
		end
		for _, slice in Config.Wheel.Slices do
			table.insert(specs, slice.reward)
		end
		for _, spec in specs do
			for _, item in spec.items or {} do
				local table_ = if item.kind == "material"
					then Config.Dungeon.Materials
					elseif item.kind == "gear" then Config.Smithy.Gear
					elseif item.kind == "food" then Config.Food.Raw
					else Config.Food.Dishes
				T.ok(table_[item.id] ~= nil, item.kind .. " " .. item.id)
				T.ok(item.count >= 1)
			end
		end
		for kind in R.QuestNeed do
			T.ok(table.find(R.QuestKinds, kind), kind)
		end
		for _, kind in R.QuestKinds do
			T.ok(R.QuestNeed[kind] ~= nil, kind)
		end
		T.eq(Rewards.grant(R.WeeklyChest, farm).spins, 5)
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
		T.same(fixed.rewards.quests, { day = 0, list = {}, bonus = false, rerolls = 0, freeUsed = 0 })
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
		-- every reward carries coins, luck, spins and items so the client can draw pictures and short numbers
		T.eq(#view.daily[1], 4)
		T.eq(view.daily[1][4][1].kind, "food")
		T.eq(view.daily[2][3], 1, "day 2 pays a spin")
		T.eq(#view.quests[1], 9)
		T.eq(view.quests[1][6], farm.rewards.quests.list[1].kind)
		T.eq(#view.online[9], 6)
		T.eq(view.online[9][5], 1, "the 60-minute gift pays a spin")
		T.eq(#view.milestones, #R.CheckinMilestones)
		T.eq(view.milestones[2].items[1].id, "charm-core")
		T.eq(#view.weekly.quests, #R.Weekly)
		T.eq(view.weekly.chest[1], 0)
		T.eq(#view.goals, #Config.Goals.List)
		T.eq(view.goals[1].state, 0)
		T.eq(view.rerollFree, true)
		T.eq(view.checkins, 0)
	end)

	T.test("the 60-minute online gift pays one spin, once a day", function()
		local farm: any = FarmState.newFarm(NOW)
		Rewards.addPlayed(farm, NOW, 3600)
		T.ok((Rewards.claimOnline(farm, 9, NOW)))
		T.eq(farm.rewards.wheel.bank, 1)
		T.same({ Rewards.claimOnline(farm, 9, NOW) }, { false, "TAKEN" })
		T.eq(farm.rewards.wheel.bank, 1)
		local tomorrow = NOW + DAY
		Rewards.addPlayed(farm, tomorrow, 3600)
		T.ok((Rewards.claimOnline(farm, 9, tomorrow)))
		T.eq(farm.rewards.wheel.bank, 2)
		-- the 3-minute gift is a food basket
		Rewards.addPlayed(farm, tomorrow, 180)
		T.ok((Rewards.claimOnline(farm, 2, tomorrow)))
	end)

	T.test("the check-in pays items and spins, counts every check-in and opens the milestones", function()
		local farm: any = FarmState.newFarm(NOW)
		local now = NOW
		for day = 1, 7 do
			T.ok((Rewards.claimDaily(farm, now)), "day " .. day)
			now += DAY
		end
		T.eq(farm.rewards.checkins, 7)
		T.eq(farm.rewards.wheel.bank, 1 + 2 + 3, "days 2, 5 and 7 pay spins")
		T.eq(farm.materials.ore, 5, "day 3")
		T.eq(farm.materials.rare_part, 2, "day 4")
		T.eq(farm.materials.monster_core, 3, "days 6 and 7")
		T.same({ Rewards.claimMilestone(farm, 1, now) }, { false, "NOT_DONE" })
		-- a missed day starts the run again but never takes a check-in away
		now += 2 * DAY
		T.eq((Rewards.dailyDay(farm, now)), 1)
		for _ = 1, 7 do
			Rewards.claimDaily(farm, now)
			now += DAY
		end
		T.eq(farm.rewards.checkins, 14)
		T.eq(Rewards.milestoneState(farm, 1), 1)
		T.eq(Rewards.ready(farm, now) >= 1, true)
		local bank = farm.rewards.wheel.bank
		local ok, _, coins = Rewards.claimMilestone(farm, 1, now)
		T.ok(ok and coins and coins > 0)
		T.eq(farm.rewards.wheel.bank, bank + R.CheckinMilestones[1].spins)
		T.same({ Rewards.claimMilestone(farm, 1, now) }, { false, "TAKEN" })
		T.same({ Rewards.claimMilestone(farm, 2, now) }, { false, "NOT_DONE" })
		T.same({ Rewards.claimMilestone(farm, 9, now) }, { false, "NO_MILESTONE" })
		-- the 30-check-in milestone is a piece of gear
		farm.rewards.checkins = 30
		T.ok((Rewards.claimMilestone(farm, 2, now)))
		T.eq(farm.gear["charm-core"], 1)
	end)

	T.test("the free redraw changes one unclaimed quest once a day; a paid one is for the Robux code", function()
		local farm: any = bigFarm()
		Rewards.ensureQuests(farm, 42, NOW)
		local before = table.clone(farm.rewards.quests.list)
		T.eq(Rewards.freeRerollLeft(farm, NOW), true)
		T.ok((Rewards.rerollQuest(farm, 2, 42, NOW)))
		local list = farm.rewards.quests.list
		T.ok(list[2].kind ~= before[2].kind, "a different kind")
		T.eq(list[2].mark, Rewards.count(farm, list[2].kind), "counted from now")
		T.same({ list[1], list[3], list[4] }, { before[1], before[3], before[4] }, "the others stay")
		local kinds = {}
		for _, quest in list do
			T.ok(not kinds[quest.kind], "two quests of one kind")
			kinds[quest.kind] = true
		end
		T.eq(Rewards.freeRerollLeft(farm, NOW), false)
		T.same({ Rewards.rerollQuest(farm, 1, 42, NOW) }, { false, "NO_REROLL" })
		local paid = Rewards.rerollQuest(farm, 1, 42, NOW, true)
		T.ok(paid, "paid redraws do not need the free one")
		T.eq(farm.rewards.quests.freeUsed, 1)
		T.eq(farm.rewards.quests.rerolls, 2)
		T.same({ Rewards.rerollQuest(farm, 9, 42, NOW, true) }, { false, "NO_QUEST" })
		-- a claimed quest is not redrawn, and tomorrow brings the free redraw back
		farm.rewards.quests.list[3].claimed = true
		T.same({ Rewards.rerollQuest(farm, 3, 42, NOW, true) }, { false, "TAKEN" })
		Rewards.ensureQuests(farm, 42, NOW + DAY)
		T.eq(Rewards.freeRerollLeft(farm, NOW + DAY), true)
		T.same({ Rewards.rerollQuest(farm, 1, 42, NOW) }, { false, "NO_QUEST" }, "yesterday's list is gone")
	end)

	T.test("requests redraw and claim through the remote rules", function()
		local farm: any = bigFarm()
		Rewards.ensureQuests(farm, 77, NOW)
		for _, data in
			{
				{ action = "RerollQuest", index = 1 },
				{ action = "ClaimWeekly", index = 1 },
				{ action = "ClaimWeeklyChest" },
				{ action = "ClaimGoal", id = "hatch10" },
				{ action = "ClaimMilestone", index = 1 },
				{ action = "WheelSpin" },
			}
		do
			T.ok(VillageRequests.valid(data, true), data.action)
		end
		T.ok(not VillageRequests.valid({ action = "RerollQuest", index = #R.QuestRewards + 1 }, true))
		T.ok(not VillageRequests.valid({ action = "ClaimWeekly", index = #R.Weekly + 1 }, true))
		T.ok(not VillageRequests.valid({ action = "ClaimMilestone", index = 0 }, true))
		T.ok(not VillageRequests.valid({ action = "ClaimGoal", id = 5 }, true))
		T.ok(not VillageRequests.valid({ action = "ClaimGoal", id = string.rep("x", 200) }, true))
		T.ok((VillageRequests.run(farm, { action = "RerollQuest", index = 1 }, NOW, env())))
		T.same({ VillageRequests.run(farm, { action = "RerollQuest", index = 1 }, NOW, env()) }, { false, "NO_REROLL" })
		T.same({ VillageRequests.run(farm, { action = "ClaimGoal", id = "nope" }, NOW, env()) }, { false, "NO_GOAL" })
		local ok, why, slice = VillageRequests.run(farm, { action = "WheelSpin" }, NOW, env())
		T.ok(ok and slice and slice >= 1 and slice <= #Config.Wheel.Slices, tostring(why))
		T.same({ VillageRequests.run(farm, { action = "WheelSpin" }, NOW, env()) }, { false, "NO_SPIN" })
	end)

	T.test("weekly quests come on Monday, count from the week's start and open the Weekly Chest", function()
		local farm: any = bigFarm()
		-- the week of NOW starts on a Monday at 00:00 UTC (the Arena's week); "friday" is four days in
		local monday = ArenaSeason.weekEnd(ArenaSeason.weekOf(NOW) - 1)
		T.eq((os.date("!*t", monday) :: any).wday, 2, "Monday")
		T.eq((os.date("!*t", monday - 1) :: any).wday, 1, "Sunday before it")
		local friday = monday + 4 * DAY + 12 * 3600
		T.ok(Rewards.ensureQuests(farm, 1, friday))
		T.eq(#farm.rewards.weekly.list, #R.Weekly)
		local weekList = farm.rewards.weekly.list
		Rewards.ensureQuests(farm, 1, friday + DAY)
		T.eq(farm.rewards.weekly.list, weekList, "a new day in the same week keeps the weekly quests")
		T.eq(#farm.rewards.weekly.list, #R.Weekly)
		T.eq(Rewards.chestState(farm, friday), 0)
		T.same({ Rewards.claimWeekly(farm, 1, friday) }, { false, "NOT_DONE" })
		T.same({ Rewards.claimChest(farm, friday) }, { false, "NOT_DONE" })
		for index, quest in farm.rewards.weekly.list do
			quest.mark -= quest.need
			local ok = Rewards.claimWeekly(farm, index, friday)
			T.ok(ok, "weekly " .. index)
			T.same({ Rewards.claimWeekly(farm, index, friday) }, { false, "TAKEN" })
		end
		T.eq(farm.rewards.wheel.bank, 2 + 3, "two weekly quests pay spins")
		T.eq(Rewards.chestState(farm, friday), 1)
		T.eq(Rewards.ready(farm, friday) >= 1, true)
		local ok = Rewards.claimChest(farm, friday)
		T.ok(ok)
		T.eq(farm.rewards.wheel.bank, 2 + 3 + R.WeeklyChest.spins)
		T.same({ Rewards.claimChest(farm, friday) }, { false, "TAKEN" })
		-- Sunday night is still the same week; Monday 00:00 UTC brings five new quests and a closed chest
		local sunday = monday + 6 * DAY + 23 * 3600
		T.same({ Rewards.claimWeekly(farm, 1, sunday) }, { false, "TAKEN" }, "still this week")
		T.eq(farm.rewards.weekly.week, ArenaSeason.weekOf(sunday + 3599))
		local nextMonday = monday + 7 * DAY
		T.ok(farm.rewards.weekly.week ~= ArenaSeason.weekOf(nextMonday), "the week turns at Monday 00:00 UTC")
		T.eq(Rewards.stale(farm, nextMonday), true)
		T.ok(Rewards.ensureQuests(farm, 1, nextMonday))
		T.eq(#farm.rewards.weekly.list, #R.Weekly)
		T.eq(farm.rewards.weekly.chest, false)
		for _, quest in farm.rewards.weekly.list do
			T.eq(quest.claimed, false)
		end
		T.same({ Rewards.claimWeekly(farm, 1, nextMonday - 1) }, { false, "NO_QUEST" }, "last week's are gone")
		-- weekly progress is the count since the week's start
		local view = Rewards.view(farm, nextMonday)
		T.eq(#view.weekly.quests, #R.Weekly)
		T.eq(view.weekly.reset, nextMonday + 7 * DAY)
	end)

	T.test("goals are permanent, paid by hand once and counted from the farm's own totals", function()
		local farm: any = FarmState.newFarm(NOW)
		T.same({ Rewards.claimGoal(farm, "hatch10", NOW) }, { false, "NOT_DONE" })
		T.same({ Rewards.claimGoal(farm, "hatch999", NOW) }, { false, "NO_GOAL" })
		T.eq(Rewards.goalCount(farm, "hatch"), 0, "the starters are not eggs hatched")
		farm.discoveries.base.navy.hatchCount += 12
		T.eq(Rewards.goalState(farm, Config.Goals.List[1]), 1)
		local ready = Rewards.ready(farm, NOW)
		local coins = farm.coins
		local ok, _, paid = Rewards.claimGoal(farm, "hatch10", NOW)
		T.ok(ok and paid and paid > 0)
		T.eq(farm.coins, coins + paid)
		T.eq(Rewards.ready(farm, NOW), ready - 1)
		T.same({ Rewards.claimGoal(farm, "hatch10", NOW + 30 * DAY) }, { false, "TAKEN" })
		T.eq(farm.coins, coins + paid, "paid once")
		-- the other counts
		farm.lifetime.slimesSold = 100
		farm.dungeon.best = 10
		farm.lifetime.gearCrafted = 5
		for _, id in Config.Village.Areas do
			farm.areas[id].level = 20
		end
		for _, id in { "sell10", "sell100", "dungeon3", "dungeon10", "craft1", "craft5", "village10", "village20" } do
			T.ok((Rewards.claimGoal(farm, id, NOW)), id)
		end
		T.same({ Rewards.claimGoal(farm, "village30", NOW) }, { false, "NOT_DONE" })
		T.same({ Rewards.claimGoal(farm, "sell500", NOW) }, { false, "NOT_DONE" })
		-- each goal is listed once with a distinct id and a growing need inside its kind
		local seen, last = {}, {}
		for _, goal in Config.Goals.List do
			T.ok(not seen[goal.id], "duplicate goal " .. goal.id)
			seen[goal.id] = true
			T.ok(goal.need > (last[goal.kind] or 0), goal.id)
			last[goal.kind] = goal.need
		end
	end)

	T.test("new rewards are saved and repaired part by part; a damaged one falls back alone", function()
		local farm: any = bigFarm()
		Rewards.ensureQuests(farm, 3, NOW)
		Rewards.claimDaily(farm, NOW)
		farm.rewards.wheel = { day = Rewards.dayOf(NOW), used = 1, bank = 6 }
		farm.rewards.goals.hatch10 = true
		farm.rewards.milestones = { 1 }
		Rewards.rerollQuest(farm, 1, 3, NOW)
		local copy = FarmState.repair(farm, NOW)
		T.same(copy.rewards, farm.rewards)
		T.same(copy.lifetime, farm.lifetime)
		local broken: any = FarmState.newFarm(NOW)
		broken.rewards.wheel = { day = "x", used = -3, bank = 1e12 }
		broken.rewards.goals = { hatch10 = true, nonsense = true, sell10 = "yes" }
		broken.rewards.milestones = { 2, 2, 99, 1.5, "x" }
		broken.rewards.checkins = -4
		broken.rewards.weekly = { week = 5, list = { { kind = "dance", need = 2, mark = 0 } }, chest = true }
		broken.rewards.quests = { day = 5, list = {}, bonus = true, rerolls = "x", freeUsed = -1 }
		broken.lifetime.dungeonWaves = -1
		broken.lifetime.secsPlayed = "x"
		local fixed = FarmState.repair(broken, NOW)
		T.same(fixed.rewards.wheel, { day = 0, used = 0, bank = Config.Wheel.BankCap })
		T.same(fixed.rewards.goals, { hatch10 = true })
		T.same(fixed.rewards.milestones, { 2 })
		T.eq(fixed.rewards.checkins, 0)
		T.same(fixed.rewards.weekly, { week = 0, list = {}, chest = false })
		T.same(fixed.rewards.quests, { day = 5, list = {}, bonus = true, rerolls = 0, freeUsed = 0 })
		T.eq(fixed.lifetime.dungeonWaves, 0)
		T.eq(fixed.lifetime.secsPlayed, 0)
		-- a farm whose lifetime lacks the new counts gets zeros and keeps the rest
		local legacy: any = FarmState.newFarm(NOW)
		legacy.lifetime.meals = 41
		legacy.lifetime.wheelSpins = nil
		legacy.lifetime.cropsHarvested = nil
		local mended = FarmState.repair(legacy, NOW)
		T.eq(mended.lifetime.meals, 41)
		T.eq(mended.lifetime.wheelSpins, 0)
		T.eq(mended.lifetime.cropsHarvested, 0)
	end)

	T.test("a schema 11 save migrates (through every later step) and keeps what it took", function()
		T.eq(Config.Save.SchemaVersion, 15)
		local old: any = played(FarmState.newFarm(NOW))
		Rewards.ensureQuests(old, 8, NOW)
		Rewards.claimDaily(old, NOW)
		Rewards.addPlayed(old, NOW, 120)
		Rewards.claimOnline(old, 1, NOW)
		old.rewards.quests.list[1].claimed = true
		old.rewards.indexSeen = true
		old.coins = 9876
		-- the shape of a schema 11 save: none of the new fields
		old.rewards.checkins, old.rewards.milestones, old.rewards.weekly, old.rewards.goals, old.rewards.wheel =
			nil, nil, nil, nil, nil
		old.rewards.quests.rerolls, old.rewards.quests.freeUsed = nil, nil
		for _, key in
			{
				"dungeonWaves",
				"arenaAttacks",
				"gearCrafted",
				"dishesCooked",
				"fishCaught",
				"cropsHarvested",
				"wheelSpins",
				"secsPlayed",
			}
		do
			old.lifetime[key] = nil
		end
		local daily = table.clone(old.rewards.daily)
		local quests = table.clone(old.rewards.quests.list)
		local load =
			ProfileLogic.prepareLoad({ schemaVersion = 11, savedAt = NOW, data = old }, FarmSave.hooks(), NOW + 1)
		T.ok(load.ok and load.migrated)
		local data = load.data
		T.eq(data.coins, 9876)
		T.same(data.rewards.daily, daily)
		T.same(data.rewards.online.claimed, { 1 })
		T.eq(data.rewards.indexSeen, true)
		T.eq(#data.rewards.quests.list, #quests, "today's quests stay")
		T.eq(data.rewards.quests.list[1].claimed, true)
		T.eq(data.rewards.checkins, 1, "the check-in total starts at the run it has")
		T.same(data.rewards.wheel, { day = 0, used = 0, bank = 0 })
		T.same(data.rewards.goals, {})
		T.same(data.rewards.weekly, { week = 0, list = {}, chest = false })
		T.eq(data.lifetime.wheelSpins, 0)
		T.eq(data.lifetime.secsPlayed, 0)
		T.eq(old.rewards.weekly, nil, "migration never alters the stored snapshot")
		-- the next look makes this week's quests and keeps today's
		local before = data.rewards.quests.list
		T.ok(Rewards.ensureQuests(data, 8, NOW))
		T.same(data.rewards.quests.list, before)
		T.eq(#data.rewards.weekly.list, #R.Weekly)
	end)
end
