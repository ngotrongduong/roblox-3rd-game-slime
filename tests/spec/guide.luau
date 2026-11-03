--!strict
-- The tutorial and the intros: every step is finished by the real farm (or by the screen, Next or Skip the player sends),
-- never by time; its progress is saved and repaired like the rest of the farm.
local Breeding = require("../../src/shared/Breeding")
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Guide = require("../../src/shared/Guide")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Stations = require("../../src/shared/Stations")
local VillageRequests = require("../../src/shared/VillageRequests")

local NOW = 1000000
local HOME = { atMarket = false, atHome = true }
local MARKET = { atMarket = true, atHome = false }

local function requestEnv(): any
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
	}
end

local function stepOf(farm: any): string
	return farm.guide.step
end

return function(T: any)
	T.test("every step and intro of Config.Guide has its words and checks", function()
		local ok, missing = Guide.known()
		T.ok(ok, "missing " .. tostring(missing))
	end)

	T.test("a new farm starts the tutorial at its first step and shows it", function()
		local farm = FarmState.newFarm(NOW)
		T.eq(stepOf(farm), Config.Guide.Steps[1])
		local view = Guide.view(farm, NOW)
		assert(view)
		T.eq(view.id, "book")
		T.eq(view.kind, "tutorial")
		T.eq(view.target, "hud:slimes")
	end)

	T.test("a new player's starters leave free adults for a team, so the team step does not wait", function()
		local farm: any = FarmState.newFarm(NOW)
		T.ok(
			#farm.slimes >= Config.Zombies.TeamSize + 4,
			"a full team and four more for fishing, the garden and a pair"
		)
		T.ok((Stations.assign(farm, "slime-1", "fishing", 1, false, NOW)))
		T.ok((Stations.assign(farm, "slime-2", "garden", 1, false, NOW)))
		T.ok((Breeding.setPair(farm, 1, "slime-3", "slime-4", NOW)))
		farm.guide.step = "team"
		local view = Guide.view(farm, NOW)
		assert(view)
		T.eq(view.id, "team")
		T.ok(string.find(view.line, "grows up", 1, true) == nil)
	end)

	T.test("a fresh player walks the whole tutorial by playing, and finishing it starts the new-player luck", function()
		local farm: any = FarmState.newFarm(NOW)
		-- (a farm of four, so every adult is busy by the team step and the wait line shows)
		while #farm.slimes > 4 do
			table.remove(farm.slimes)
		end
		local now = NOW
		-- nothing moves on by itself, and a screen step only goes with the screen the player opened
		T.ok(not Guide.update(farm, now, HOME))
		T.ok(not (Guide.seen(farm, "food", now)), "not this step")
		T.ok((Guide.seen(farm, "book", now)))
		T.eq(stepOf(farm), "fish")
		T.ok(not Guide.update(farm, now, HOME), "waits for a fisher")
		T.ok((Stations.assign(farm, "slime-1", "fishing", 1, false, now)))
		T.ok(Guide.update(farm, now, HOME))
		T.eq(stepOf(farm), "garden")
		T.ok((Stations.assign(farm, "slime-2", "garden", 1, false, now)))
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), "food")
		T.ok((Guide.seen(farm, "food", now)))
		T.eq(stepOf(farm), "pair")
		T.ok((Breeding.setPair(farm, 1, "slime-3", "slime-4", now)))
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), "egg")
		T.ok(not Guide.update(farm, now, HOME), "waits for the egg")
		farm.lifetime.breeds += 1
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), "hatch")
		now += 30
		table.insert(farm.slimes, FarmKit.slime("baby", { createdAt = now }))
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), "market", "a baby is born")
		T.ok(not Guide.update(farm, now, HOME), "waits for the trip")
		Guide.update(farm, now, MARKET)
		T.eq(stepOf(farm), "sell")
		local view = Guide.view(farm, now)
		assert(view)
		T.ok(view.next, "a tip step shows Next")
		T.ok(not Guide.update(farm, now, MARKET), "a tip waits for Next")
		T.ok((Guide.next(farm, "sell", now)))
		T.eq(stepOf(farm), "home")
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), "pads")
		T.ok((Guide.next(farm, "pads", now)))
		T.eq(stepOf(farm), "team")
		-- every adult is busy and the baby is small: the line says to wait
		local waiting = Guide.view(farm, now)
		assert(waiting)
		T.ok(string.find(waiting.line, "grows up", 1, true) ~= nil)
		now += 10 * 60
		local grown = Guide.view(farm, now)
		assert(grown)
		T.ok(string.find(grown.line, "grows up", 1, true) == nil, "the baby is grown")
		farm.teams[1].members = { "baby" }
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), "attack")
		local mark = farm.guide.mark
		farm.teams[1].target = "s1c1g1"
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), "win")
		T.eq(farm.guide.mark, mark, "coins are counted from the order")
		T.eq(farm.tutorialDone, false, "the first-egg boost and the luck wait for the end")
		T.ok(not Guide.update(farm, now, HOME), "waits for coins")
		farm.lifetime.coinsEarned += 40
		now += 60
		Guide.update(farm, now, HOME)
		T.eq(stepOf(farm), Guide.Done)
		T.eq(farm.tutorialDone, true)
		T.eq(farm.tutorialDoneAt, now)
	end)

	T.test("a rejoin passes every step the farm has already done in one look", function()
		local farm: any = FarmState.newFarm(NOW)
		farm.guide.step = "fish"
		Stations.assign(farm, "slime-1", "fishing", 1, false, NOW)
		Stations.assign(farm, "slime-2", "garden", 1, false, NOW)
		T.ok(Guide.update(farm, NOW, HOME))
		T.eq(stepOf(farm), "food", "stops at the screen step")
	end)

	T.test("Skip ends the tutorial with the luck, then closes intros for good", function()
		local farm: any = FarmState.newFarm(NOW)
		T.ok((Guide.skip(farm, NOW)))
		T.eq(stepOf(farm), Guide.Done)
		T.eq(farm.tutorialDone, true)
		T.eq(farm.tutorialDoneAt, NOW)
		T.eq(Guide.view(farm, NOW), nil)
		T.ok(not (Guide.skip(farm, NOW)), "nothing to skip")
		farm.slimes[1].ghostUntil = NOW + 100
		T.ok(Guide.update(farm, NOW, HOME))
		T.eq(farm.guide.intro, "ghost")
		T.ok((Guide.skip(farm, NOW)))
		T.eq(farm.guide.intro, nil)
		T.ok(farm.guide.seen.ghost)
		Guide.update(farm, NOW, HOME)
		T.ok(farm.guide.intro ~= "ghost", "a closed intro never comes back")
	end)

	T.test("intros open when their feature matters, most urgent first, and close when done", function()
		local farm: any = FarmKit.farm(NOW)
		Guide.update(farm, NOW, HOME)
		T.eq(farm.guide.intro, "kitchen", "free slimes and no cook")
		-- a slime falls: the kitchen stays until it is done or no longer matters, then the ghost comes first
		farm.slimes[1].ghostUntil = NOW + 100
		Stations.assign(farm, "slime-2", "kitchen", 1, false, NOW)
		Guide.update(farm, NOW, HOME)
		T.ok(farm.guide.seen.kitchen, "a cook was given")
		Guide.update(farm, NOW, HOME)
		T.eq(farm.guide.intro, "ghost")
		farm.slimes[1].ghostUntil = nil
		Guide.update(farm, NOW, HOME)
		T.ok(farm.guide.seen.ghost)
		-- team 2 opens with the village
		for _, id in Config.Village.Areas do
			farm.areas[id].level = Config.Zombies.TeamOpensAt[2]
		end
		farm.guide.seen.training = true
		Guide.update(farm, NOW, HOME)
		T.eq(farm.guide.intro, "team2")
		farm.teams[2].members = { "slime-3" }
		Guide.update(farm, NOW, HOME)
		T.ok(farm.guide.seen.team2)
	end)

	T.test("an intro that stops mattering is put away unseen and can come back", function()
		local farm: any = FarmKit.farm(NOW)
		farm.coins = 1000
		Guide.update(farm, NOW, HOME)
		T.eq(farm.guide.intro, "upgrade")
		farm.coins = 0
		Guide.update(farm, NOW, HOME)
		T.ok(farm.guide.intro ~= "upgrade")
		T.ok(not farm.guide.seen.upgrade)
	end)

	T.test("pending tells without changing the farm", function()
		local farm: any = FarmState.newFarm(NOW)
		farm.guide.step = "fish"
		Stations.assign(farm, "slime-1", "fishing", 1, false, NOW)
		T.ok(Guide.pending(farm, NOW, HOME))
		T.eq(stepOf(farm), "fish")
		T.ok(Guide.update(farm, NOW, HOME))
		T.ok(not Guide.pending(farm, NOW, HOME))
	end)

	T.test("the requests check their shape and only finish the step on screen", function()
		T.ok(VillageRequests.valid({ action = "GuideSeen", step = "book" }, false))
		T.ok(VillageRequests.valid({ action = "GuideSkip" }, false))
		T.ok(not VillageRequests.valid({ action = "GuideNext", step = 5 }, true))
		T.ok(not VillageRequests.valid({ action = "GuideNext", step = string.rep("x", 40) }, true))
		local farm: any = FarmState.newFarm(NOW)
		local ok, why = VillageRequests.run(farm, { action = "GuideNext", step = "book" }, NOW, requestEnv())
		T.ok(not ok)
		T.eq(why, "NOT_THIS_STEP")
		T.ok((VillageRequests.run(farm, { action = "GuideSeen", step = "book" }, NOW, requestEnv())))
		T.eq(stepOf(farm), "fish")
		T.ok((VillageRequests.run(farm, { action = "GuideSkip" }, NOW, requestEnv())))
		T.eq(stepOf(farm), Guide.Done)
	end)

	T.test("repair keeps a good guide and resets a broken one", function()
		local farm: any = FarmState.newFarm(NOW)
		farm.guide.step = "egg"
		farm.guide.mark = 3
		local kept = FarmState.repair(farm, NOW)
		T.eq(kept.guide.step, "egg")
		T.eq(kept.guide.mark, 3)
		local broken: any = FarmState.newFarm(NOW)
		broken.guide = { step = "nonsense", seen = { ghost = true, bogus = true }, intro = "bogus" }
		local fixed, warnings = FarmState.repair(broken, NOW)
		T.eq(fixed.guide.step, Config.Guide.Steps[1])
		T.eq(fixed.guide.intro, nil)
		T.same(fixed.guide.seen, { ghost = true })
		T.ok(#warnings > 0)
		-- the step always agrees with tutorialDone
		local done: any = FarmState.newFarm(NOW)
		done.tutorialDone = true
		local agreed = FarmState.repair(done, NOW)
		T.eq(agreed.guide.step, Guide.Done)
		-- a legacy farm without the field: the tour is done
		local legacy: any = FarmState.newFarm(NOW)
		legacy.guide = nil
		legacy.tutorialDone = nil
		T.eq(FarmState.repair(legacy, NOW).guide.step, Guide.Done)
	end)

	T.test("schema 6 to 7: an old farm has played, so its tutorial is over without new luck", function()
		local old: any = FarmState.newFarm(NOW)
		old.guide = nil
		old.coins = 777
		local load =
			ProfileLogic.prepareLoad({ schemaVersion = 6, savedAt = NOW, data = old }, FarmSave.hooks(), NOW + 1)
		T.ok(load.ok and load.migrated)
		T.eq(load.data.coins, 777)
		T.eq(load.data.guide.step, Guide.Done)
		T.eq(load.data.tutorialDone, true)
		T.eq(load.data.tutorialDoneAt, nil, "no new-player luck for an old farm")
		T.same(load.data.guide.seen, {})
		T.eq(old.guide, nil, "migration never alters the stored snapshot")
		-- a new farm saves and loads its tutorial as it was
		local fresh: any = FarmState.newFarm(NOW)
		fresh.guide.step = "pair"
		local again = ProfileLogic.prepareLoad(
			{ schemaVersion = Config.Save.SchemaVersion, savedAt = NOW, data = fresh },
			FarmSave.hooks(),
			NOW + 1
		)
		T.ok(again.ok)
		T.eq(again.data.guide.step, "pair")
	end)
end
