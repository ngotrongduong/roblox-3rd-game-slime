--!strict
-- The community rewards: favorite the game and join the owner's group, each paid once and only when done; the group only
-- once its id is set and the server saw the player in it; saved, repaired and migrated; the tutorial's last step.
local Config = require("../../src/shared/Config")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Guide = require("../../src/shared/Guide")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Social = require("../../src/shared/Social")
local VillageRequests = require("../../src/shared/VillageRequests")

local DAY = 86400
local NOW = 20000 * DAY + 12 * 3600
local GROUP = 4242

local function env(done: boolean?): any
	return {
		isOut = function()
			return false
		end,
		atMarket = function()
			return true
		end,
		atSmithy = function()
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
			return 0
		end,
		userId = 77,
		seed = function()
			return 5
		end,
		isVip = function()
			return false
		end,
		socialDone = if done == nil
			then nil
			else function()
				return done
			end,
	}
end

-- Runs `body` with the group id set, then puts it back.
local function withGroup(id: number, body: () -> ())
	local before = Config.Social.GroupId
	Config.Social.GroupId = id
	local ok, err = pcall(body)
	Config.Social.GroupId = before
	if not ok then
		error(err, 0)
	end
end

return function(T: any)
	T.test("the favorite pays once, only when done, and a refusal changes nothing", function()
		local farm: any = FarmState.newFarm(NOW)
		local coins = farm.coins
		T.same({ Social.claim(farm, "favorite", false, NOW) }, { false, "NOT_DONE" })
		T.eq(farm.coins, coins, "not done pays nothing")
		local ok, why, paid = Social.claim(farm, "favorite", true, NOW)
		T.ok(ok, why)
		T.ok((paid or 0) > 0, "big coins")
		T.eq(farm.coins, coins + paid)
		T.ok(farm.luckPotionUntil > NOW, "and the luck potion")
		T.eq(farm.rewards.wheel.bank, Config.Social.Favorite.spins)
		T.same({ Social.claim(farm, "favorite", true, NOW + 5) }, { false, "TAKEN" })
		T.eq(farm.coins, coins + paid, "never twice")
		T.eq(farm.rewards.wheel.bank, Config.Social.Favorite.spins)
		T.same({ Social.claim(farm, "likes", true, NOW) }, { false, "NO_KIND" })
	end)

	T.test(
		"with no group id the group is not offered: no row, no claim, the tutorial asks only the favorite",
		function()
			withGroup(0, function()
				local farm: any = FarmState.newFarm(NOW)
				T.same({ Social.claim(farm, "group", true, NOW) }, { false, "NOT_OFFERED" })
				T.eq(farm.rewards.social.group, false)
				T.eq(Social.waiting(farm), 1)
				local rows = Social.view(farm, NOW)
				T.eq(#rows, 1)
				T.eq(rows[1][1], "favorite")
				Social.claim(farm, "favorite", true, NOW)
				T.eq(Social.waiting(farm), 0)
			end)
		end
	)

	T.test("the group pays only when the server saw the player in it, and only once", function()
		withGroup(GROUP, function()
			local farm: any = FarmState.newFarm(NOW)
			local coins = farm.coins
			T.eq(Social.waiting(farm), 2)
			T.same({ Social.claim(farm, "group", false, NOW) }, { false, "NOT_DONE" })
			T.eq(farm.coins, coins)
			local ok, _, paid = Social.claim(farm, "group", true, NOW)
			T.ok(ok)
			T.eq(farm.coins, coins + paid)
			T.eq(farm.materials.monster_core, 2)
			T.same({ Social.claim(farm, "group", true, NOW) }, { false, "TAKEN" })
			T.eq(farm.materials.monster_core, 2)
			local rows = Social.view(farm, NOW)
			T.eq(#rows, 2)
			T.eq(rows[2][1], "group")
			T.eq(rows[2][2], true, "shown as taken")
		end)
	end)

	T.test("the remote: a known kind only, and the server's proof decides", function()
		withGroup(GROUP, function()
			T.ok(VillageRequests.valid({ action = "ClaimSocial", kind = "group" }, true))
			T.ok(VillageRequests.valid({ action = "ClaimSocial", kind = "favorite" }, false))
			T.ok(not VillageRequests.valid({ action = "ClaimSocial", kind = "coins" }, true))
			T.ok(not VillageRequests.valid({ action = "ClaimSocial" }, true))
			local farm: any = FarmState.newFarm(NOW)
			local coins = farm.coins
			local data = { action = "ClaimSocial", kind = "group" }
			T.same({ VillageRequests.run(farm, data, NOW, env(nil)) }, { false, "NOT_DONE" })
			T.same({ VillageRequests.run(farm, data, NOW, env(false)) }, { false, "NOT_DONE" })
			T.eq(farm.coins, coins, "not in the group: nothing")
			local ok, _, paid = VillageRequests.run(farm, data, NOW, env(true))
			T.ok(ok)
			T.eq(farm.coins, coins + paid)
			T.same({ VillageRequests.run(farm, data, NOW, env(true)) }, { false, "TAKEN" })
		end)
	end)

	T.test("taken rewards are saved, repaired and kept; a schema 13 save gets none taken", function()
		local farm: any = FarmState.newFarm(NOW)
		Social.claim(farm, "favorite", true, NOW)
		local mended = FarmState.repair(farm, NOW)
		T.same(mended.rewards.social, { favorite = true, group = false })
		local broken: any = FarmState.newFarm(NOW)
		broken.rewards.social = "yes"
		T.same(FarmState.repair(broken, NOW).rewards.social, { favorite = false, group = false })
		local old: any = FarmState.repair(FarmState.newFarm(NOW), NOW)
		old.coins = 555
		old.rewards.social = nil
		local load =
			ProfileLogic.prepareLoad({ schemaVersion = 13, savedAt = NOW, data = old }, FarmSave.hooks(), NOW + 1)
		T.ok(load.ok and load.migrated)
		T.eq(load.data.coins, 555)
		T.same(load.data.rewards.social, { favorite = false, group = false })
		T.same(ProfileLogic.migrateSocial({ rewards = { social = { favorite = true } } }, NOW).rewards.social, {
			favorite = true,
		})
	end)

	T.test(
		"the tutorial ends on the community step: after the first win, Next or the rewards taken finish it",
		function()
			withGroup(0, function()
				T.eq(Config.Guide.Steps[#Config.Guide.Steps], "social")
				local farm: any = FarmState.newFarm(NOW)
				local here = { atMarket = false, atHome = true }
				farm.guide.step = "win"
				farm.guide.mark = 0
				farm.lifetime.coinsEarned = 10
				Guide.update(farm, NOW, here)
				T.eq(farm.guide.step, "social")
				T.eq(farm.tutorialDone, false)
				local view = Guide.view(farm, NOW)
				T.ok(view ~= nil and view.target == "hud:rewards" and view.next)
				T.ok(Guide.next(farm, "social", NOW))
				T.eq(farm.guide.step, Guide.Done)
				T.eq(farm.tutorialDone, true)
				-- taking the gift finishes it too
				local other: any = FarmState.newFarm(NOW)
				other.guide.step = "social"
				Guide.update(other, NOW, here)
				T.eq(other.guide.step, "social")
				Social.claim(other, "favorite", true, NOW)
				Guide.update(other, NOW, here)
				T.eq(other.guide.step, Guide.Done)
				-- a farm that took them already passes the step at once
				local done: any = FarmState.newFarm(NOW)
				done.rewards.social.favorite = true
				done.guide.step = "win"
				done.guide.mark = 0
				done.lifetime.coinsEarned = 10
				Guide.update(done, NOW, here)
				T.eq(done.guide.step, Guide.Done)
			end)
		end
	)
end
