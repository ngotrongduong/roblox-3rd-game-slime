--!strict
local Breeding = require("../../src/shared/Breeding")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")
local Zombies = require("../../src/shared/Zombies")
local FarmKit = require("../lib/FarmKit")

local NOW = 1000000

local function squadOf(level: number): { any }
	local share = level / 4
	local out = {}
	for index = 1, Config.Zombies.TeamSize do
		table.insert(
			out,
			{ id = "s" .. index, attack = share, defence = share, speed = share, hp = share * Config.Stats.HpPerLevel }
		)
	end
	return out
end

local function winRate(playerLevel: number, camp: number): number
	local wins = 0
	for seed = 1, 200 do
		local rng = Rng.new(seed)
		local fight = Combat.new(squadOf(playerLevel), Zombies.group("z", playerLevel, camp, rng), rng)
		while not fight.winner do
			Combat.step(fight, 0.1)
		end
		if fight.winner == "squad" then
			wins += 1
		end
	end
	return wins / 200
end

return function(T: any)
	T.test("the original's damage and cooldown formulas", function()
		T.eq(Combat.damage(10, 50), 10 * Config.Combat.DamageScale * 0.5)
		T.eq(Combat.damage(0, 50), Config.Combat.MinDamage, "at least the minimum")
		T.eq(Combat.cooldown(0), 1)
		T.eq(Combat.cooldown(9999), Config.Combat.MinCooldown)
	end)
	T.test("a fight is seeded and ends with one side standing", function()
		local function play(): (string?, number)
			local rng = Rng.new(5)
			local fight = Combat.new(squadOf(8), Zombies.group("z", 8, 1, rng), rng)
			while not fight.winner do
				Combat.step(fight, 0.1)
			end
			return fight.winner, fight.seconds
		end
		local a, b = play()
		local c, d = play()
		T.eq(a, c)
		T.eq(b, d)
		T.ok(a ~= nil)
	end)
	T.test("a group of the player's own level is usually beaten, harder groups less often", function()
		for _, level in { 4, 12, 30 } do
			local same, three, five = winRate(level, 1), winRate(level, 2), winRate(level, 3)
			T.ok(same > 0.7, "same level at " .. level .. ": " .. same)
			T.ok(same >= three and three >= five, "harder is harder at " .. level)
		end
	end)
	T.test("the player's level is the average of the strongest slimes a trip can send", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(20))
		T.eq(Zombies.playerLevel(farm, NOW), 4)
		for index = 1, Config.Zombies.Teams * Config.Zombies.TeamSize do
			farm.slimes[index].stats = { attack = 5, defence = 5, speed = 5, hp = 50 }
		end
		T.eq(Zombies.playerLevel(farm, NOW), 20, "weak slimes kept at home change nothing")
		farm.slimes[1].ghostUntil = NOW + 100
		T.eq(Zombies.playerLevel(farm, NOW), 19, "a ghost does not count")
		T.same(Zombies.campLevels(20), { 20, 23, 25 })
	end)
	T.test("rarer zombies and higher levels pay more; kinds roll by weight", function()
		T.ok(Zombies.killReward("toxic", 10) > Zombies.killReward("rotten", 10))
		T.ok(Zombies.killReward("plague", 10) > Zombies.killReward("toxic", 10))
		T.ok(Zombies.killReward("rotten", 20) > Zombies.killReward("rotten", 10))
		local rng = Rng.new(3)
		local plagues = {}
		for camp = 1, #Config.Zombies.LevelOffsets do
			local seen = { rotten = 0, toxic = 0, plague = 0 }
			for _ = 1, 2000 do
				local kind = Zombies.rollKind(camp, rng)
				seen[kind] += 1
			end
			T.ok(seen.rotten > seen.toxic and seen.toxic > seen.plague and seen.plague > 0)
			plagues[camp] = seen.plague
		end
		T.ok(plagues[3] > plagues[2] and plagues[2] > plagues[1], "harder camps hold more rare zombies")
	end)
	T.test("a dead slime has 15 minutes: food brings it back, else it is lost for good", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		farm.work.fishing.slots[1].worker = "s1"
		local paid = Zombies.fall(farm, "s1", NOW)
		T.ok(paid > 0)
		T.eq(farm.coins, paid)
		T.eq(Zombies.fall(farm, "s1", NOW), 0, "dies once")
		T.eq(farm.slimes[1].ghostUntil, NOW + Config.Village.GhostSeconds)
		farm.storehouse = {}
		T.eq(select(2, Zombies.revive(farm, "s1", NOW + 60)), "NO_FOOD")
		T.eq(farm.slimes[1].ghostUntil, NOW + Config.Village.GhostSeconds, "a refusal changes nothing")
		farm.storehouse = { fish = 1, carrot = 2 }
		T.eq(Zombies.reviveCost(4), 2)
		T.ok(Zombies.revive(farm, "s1", NOW + 60))
		T.eq(farm.slimes[1].ghostUntil, nil)
		T.same(farm.storehouse, { carrot = 1 }, "paid from the biggest stock each time")
		T.eq(select(2, Zombies.revive(farm, "s1", NOW + 60)), "NOT_DEAD")

		Zombies.fall(farm, "s1", NOW)
		local after = VillageSim.step(farm, NOW + Config.Village.GhostSeconds, 1, Rng.new(1), { errands = false })
		T.eq(#after.slimes, 5, "lost for good")
		T.eq(after.work.fishing.slots[1].worker, nil, "and off its job")
	end)
	T.test("the last two slimes come back by themselves, and time away never costs a slime", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(2))
		Zombies.fall(farm, "s1", NOW)
		local after = VillageSim.step(farm, NOW + Config.Village.GhostSeconds, 1, Rng.new(1), { errands = false })
		T.eq(#after.slimes, 2)
		T.eq(after.slimes[1].ghostUntil, nil)

		local away = FarmKit.farm(NOW, FarmKit.many(6))
		Zombies.fall(away, "s1", NOW)
		away.lastSimulatedAt = NOW + 60
		local back = NOW + 60 + 8 * 3600
		local caught = VillageSim.catchUp(away, NOW + 60, back, Rng.new(1))
		T.eq(#caught.slimes, 6)
		T.eq(caught.slimes[1].ghostUntil - back, Config.Village.GhostSeconds - 60, "14 minutes are still left")
	end)
	T.test("who can go: grown up, free and alive; the shop has its own refusals", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		T.ok(Zombies.canSend(farm, farm.slimes[1], NOW))
		farm.work.fishing.slots[1].worker = "s1"
		T.ok(not Zombies.canSend(farm, farm.slimes[1], NOW), "at work")
		T.eq(select(2, Shop.sell(farm, "s1", NOW)), "AT_WORK")
		farm.slimes[2].isFavourite = true
		T.eq(select(2, Shop.sell(farm, "s2", NOW)), "FAVOURITE")
		Zombies.fall(farm, "s3", NOW)
		T.eq(select(2, Shop.sell(farm, "s3", NOW)), "DEAD")
		local coins = farm.coins
		T.eq(Shop.sell(farm, "s4", NOW), 120)
		T.eq(farm.coins, coins + 120)
		T.eq(#farm.slimes, 5)
		local two = FarmKit.farm(NOW, FarmKit.many(2))
		T.eq(select(2, Shop.sell(two, "s1", NOW)), "LAST_SLIMES")
	end)
	T.test("a team is 0 to 4 different slimes that are free; a slime in another team moves", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(8))
		local function refusal(index: number, ids: { string }, isOut: ((string) -> boolean)?): string?
			local ok, why = Zombies.setTeam(farm, index, ids, NOW, isOut)
			T.ok(not ok, "refused")
			return why
		end
		T.ok(Zombies.setTeam(farm, 1, { "s1" }, NOW))
		T.same(farm.teams[1].members, { "s1" })
		T.ok(Zombies.setTeam(farm, 2, { "s1", "s2", "s3", "s4" }, NOW))
		T.same(farm.teams[1].members, {}, "s1 moved to team 2")
		T.same(farm.teams[2].members, { "s1", "s2", "s3", "s4" })
		T.ok(Zombies.setTeam(farm, 2, {}, NOW), "a team can be emptied")
		T.eq(refusal(0, { "s1" }), "BAD_TEAM")
		T.eq(refusal(Config.Zombies.Teams + 1, { "s1" }), "BAD_TEAM")
		T.eq(refusal(1.5, { "s1" }), "BAD_TEAM")
		T.eq(refusal(1, { "s1", "s2", "s3", "s4", "s5" }), "BAD_SIZE")
		T.eq(refusal(1, { "s1", "s1" }), "DUPLICATE")
		T.eq(refusal(1, { "nope" }), "NO_SLIME")
		T.eq(
			refusal(1, { "s1", "s2" }, function(id: string): boolean
				return id == "s2"
			end),
			"OUT"
		)
		table.insert(farm.slimes, FarmKit.slime("baby", { createdAt = NOW }))
		T.eq(refusal(1, { "baby" }), "BABY")
		Zombies.fall(farm, "s4", NOW)
		T.eq(refusal(1, { "s4" }), "DEAD")
		farm.work.fishing.slots[1].worker = "s3"
		T.eq(refusal(1, { "s3" }), "BUSY")
		farm.breeding.pairs[1] = { a = "s5", b = "s6" }
		T.eq(refusal(1, { "s5" }), "BUSY")
		T.same(farm.teams[1].members, {}, "a refusal changes nothing")
	end)
	T.test("one job at a time: a team slime cannot work or breed, a worker or parent cannot join a team", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		T.ok(Zombies.setTeam(farm, 1, { "s1", "s2" }, NOW))
		T.eq(select(2, Stations.canAssign(farm, "s1", "fishing", 1, false, NOW)), "IN_TEAM")
		T.eq(select(2, Stations.assign(farm, "s2", "garden", 1, true, NOW)), "IN_TEAM")
		T.eq(select(2, Breeding.setPair(farm, 1, "s1", "s3", NOW)), "IN_TEAM")
		T.eq(select(2, Breeding.setPair(farm, 1, "s3", "s2", NOW)), "IN_TEAM")
		T.same(farm.breeding.pairs[1], {}, "nothing was paired")
		T.ok(Stations.assign(farm, "s3", "fishing", 1, false, NOW))
		T.ok(Breeding.setPair(farm, 1, "s4", "s5", NOW))
		T.eq(select(2, Zombies.setTeam(farm, 2, { "s3" }, NOW)), "BUSY")
		T.eq(select(2, Zombies.setTeam(farm, 2, { "s4" }, NOW)), "BUSY")
		T.ok(Zombies.setTeam(farm, 1, { "s2" }, NOW), "s1 left the team")
		T.ok(Stations.assign(farm, "s1", "garden", 1, false, NOW), "and is free for a job")
		T.ok(Zombies.canSend(farm, farm.slimes[2], NOW), "a team member can march")
	end)
	T.test("a team survives a slime lost for good: removeSlime takes it out of its team", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		T.ok(Zombies.setTeam(farm, 1, { "s1", "s2" }, NOW))
		T.ok(Zombies.setTeam(farm, 3, { "s3" }, NOW))
		T.ok(FarmState.removeSlime(farm, "s1"))
		T.same(farm.teams[1].members, { "s2" })
		T.same(farm.teams[3].members, { "s3" })
		T.ok(not FarmState.removeSlime(farm, "s1"), "gone already")
		T.eq(#farm.teams, Config.Zombies.Teams)
	end)
	T.test("ready again: full health, fed, awake and rested; a wound heals with time", function()
		local slime = FarmKit.slime("a")
		T.ok(Zombies.readyAgain(slime, NOW, 0))
		T.eq(select(2, Zombies.readyAgain(slime, NOW, 0.01)), "health")
		slime.needs.fullness = Config.Needs.WantsFood
		T.eq(select(2, Zombies.readyAgain(slime, NOW, 0)), "hungry")
		slime.needs.fullness = Config.Needs.WantsFood + 1
		T.ok(Zombies.readyAgain(slime, NOW, 0))
		slime.needs.energy = Config.Needs.Tired
		T.eq(select(2, Zombies.readyAgain(slime, NOW, 0)), "tired")
		slime.needs.energy = Config.Needs.Tired + 1
		slime.sleeping = true
		T.eq(select(2, Zombies.readyAgain(slime, NOW, 0)), "tired", "asleep")
		slime.sleeping = nil
		slime.ghostUntil = NOW + 5
		T.eq(select(2, Zombies.readyAgain(slime, NOW, 0)), "dead")
		T.ok(Zombies.readyAgain(slime, NOW + 5, 0), "its time is over")

		T.eq(Zombies.heal(0.5, 60), 0.5 - Config.Zombies.HealPerMinute)
		T.eq(Zombies.heal(0.2, 600), 0, "never below healthy")
		T.ok(Zombies.heal(1, 120) <= 0, "a full heal takes about two minutes")
	end)
	T.test("a team walks at the pace of its slowest member", function()
		local near = Zombies.marchSeconds(100, { 1 })
		T.ok(near > 20 and near < 60, "about 100 studs at the starter walk: " .. near)
		T.eq(Zombies.marchSeconds(100, { 1, 10 }), near, "the slowest sets the pace")
		T.ok(Zombies.marchSeconds(100, { 30 }) < near, "a faster team arrives sooner")
		T.ok(Zombies.marchSeconds(200, { 1 }) > near)
		T.eq(Zombies.marchSeconds(100, {}), 0)
	end)
	T.test("camps lie further out each, groups spread across the way and centred", function()
		local n = Config.Zombies.GroupsPerCamp
		local first, sum = nil, 0
		for index = 1, n do
			local across, forward = Zombies.campOffset(1, index)
			sum += across
			T.eq(forward, Config.Zombies.CampFirstDistance)
			if first then
				T.ok(across > first)
			end
			first = across
		end
		T.eq(sum, 0, "centred on the way out")
		-- every camp stays inside its plot's slice of the valley (40 degrees: 9 places on the rim)
		for camp = 1, #Config.Zombies.LevelOffsets do
			local across, forward = Zombies.campOffset(camp, Config.Zombies.GroupsPerCamp)
			local radius = Config.Map.RimRadius - Config.Map.PlotSize / 2 - forward
			T.ok(across / radius < math.tan(math.rad(20)), "camp " .. camp .. " inside its slice")
		end
		local _, near = Zombies.campOffset(1, 1)
		local _, far = Zombies.campOffset(#Config.Zombies.LevelOffsets, 1)
		T.ok(far > near)
	end)
	T.test("a hungry slime fights at half strength, a dish buff adds on", function()
		local slime = FarmKit.slime("a", { stats = { attack = 10, defence = 1, speed = 1, hp = 10 } })
		T.eq(Zombies.fighter(slime, NOW, 1).attack, 10)
		slime.buff = { stat = "attack", percent = 10, untilTime = NOW + 1 }
		T.eq(Zombies.fighter(slime, NOW, 1).attack, 11)
		slime.buff = nil
		slime.needs.fullness = 0
		T.eq(Zombies.fighter(slime, NOW, 1).attack, 5)
	end)
	T.test("a wounded slime starts a fight with what it has left, out of its full health", function()
		local slime = FarmKit.slime("a", { stats = { attack = 1, defence = 1, speed = 1, hp = 40 } })
		local hurt = Zombies.fighter(slime, NOW, 0.25)
		T.eq(hurt.hp, 10)
		T.eq(hurt.maxHp, 40)
		local rng = Rng.new(1)
		local fight = Combat.new({ hurt }, Zombies.group("z", 4, 1, rng), rng)
		T.eq(fight.units[1].hp, 10)
		T.eq(fight.units[1].maxHp, 40)
		T.eq(Zombies.fighter(slime, NOW, 1).hp, 40)
	end)
	T.test("a slime's death pays by its level and rarity", function()
		local plain = FarmKit.slime("a")
		T.ok(Zombies.deathReward(plain) > 0)
		local strong = FarmKit.slime("b", { stats = { attack = 9, defence = 9, speed = 9, hp = 90 } })
		T.ok(Zombies.deathReward(strong) > Zombies.deathReward(plain))
	end)
end
