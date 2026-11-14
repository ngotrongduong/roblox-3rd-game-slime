--!strict
local Breeding = require("../../src/shared/Breeding")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local FarmState = require("../../src/shared/FarmState")
local Rng = require("../../src/shared/Rng")
local Shop = require("../../src/shared/Shop")
local Stations = require("../../src/shared/Stations")
local VillageSim = require("../../src/shared/VillageSim")
local WorldPacks = require("../../src/shared/WorldPacks")
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

-- Opens every team: the village grown big enough (all areas but the breeding pen, whose level changes how fast babies grow).
local function openTeams(farm: any)
	for _, id in Config.Village.Areas do
		if id ~= "breeding" then
			farm.areas[id].level = Config.Village.MaxLevel
		end
	end
	assert(Zombies.teamsOpen(FarmState.villageLevel(farm.areas)) == #Config.Zombies.TeamOpensAt, "every team open")
end

local function winRate(playerLevel: number, packLevel: number): number
	local wins = 0
	for seed = 1, 200 do
		local rng = Rng.new(seed)
		local fight = Combat.new(squadOf(playerLevel), WorldPacks.pack("z", "meadow", packLevel, rng), rng)
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
			local fight = Combat.new(squadOf(8), WorldPacks.pack("z", "meadow", 8, rng), rng)
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
	T.test("fighters open apart, and every blow is announced before it lands", function()
		local rng = Rng.new(9)
		-- (plain blows only: a monster's skill lands its own hits)
		local pack = WorldPacks.pack("z", "meadow", 8, rng)
		for _, monster in pack do
			monster.skills = {}
		end
		local fight = Combat.new(squadOf(8), pack, rng)
		local firstBlow: { [string]: number } = {}
		local aimed: { [string]: boolean } = {}
		while not fight.winner and fight.seconds < 60 do
			for _, event in Combat.step(fight, 0.1) do
				local from = event.from :: string
				if event.kind == "aim" then
					T.ok(not aimed[from], "one aim per blow")
					aimed[from] = true
				elseif event.kind == "hit" or event.kind == "dodge" then
					T.ok(aimed[from], "a blow lands only after its aim")
					aimed[from] = nil
					firstBlow[from] = firstBlow[from] or fight.seconds
				end
			end
		end
		local times: { number } = {}
		for _, seconds in firstBlow do
			table.insert(times, seconds)
		end
		table.sort(times)
		T.ok(#times >= 4)
		T.ok(times[#times] - times[1] >= 0.5, "the first blows are spread out")
	end)
	T.test("a slime fights by its strongest stat; a tie goes by its seed", function()
		local hpPer = Config.Stats.HpPerLevel
		local function role(attack: number, defence: number, speed: number, hp: number, seed: number): string
			return Combat.role({ id = "s", attack = attack, defence = defence, speed = speed, hp = hp }, seed)
		end
		T.eq(role(9, 2, 2, 2 * hpPer, 0), "attack")
		T.eq(role(2, 2, 9, 2 * hpPer, 0), "speed")
		T.eq(role(2, 2, 2, 9 * hpPer, 0), "hp")
		local seen: { [string]: boolean } = {}
		for seed = 0, 3 do
			seen[role(1, 1, 1, hpPer, seed)] = true
		end
		T.ok(seen.attack and seen.defence and seen.speed and seen.hp, "equal stats spread over every role")
	end)
	T.test("a guard draws the blows; a fast slime goes for the foe with the least health", function()
		local function slime(id: string, role: string): any
			return { id = id, attack = 5, defence = 5, speed = 5, hp = 50, role = role }
		end
		local hits: { [string]: number } = {}
		local rng = Rng.new(3)
		for _ = 1, 40 do
			local squad = { slime("guard", "defence"), slime("a", "hp"), slime("b", "hp"), slime("c", "hp") }
			local fight = Combat.new(squad, { { id = "z", attack = 5, defence = 5, speed = 5, hp = 9999 } }, rng)
			for _ = 1, 30 do
				for _, event in Combat.step(fight, 0.1) do
					if event.kind == "aim" and event.from == "z" then
						hits[event.to] = (hits[event.to] or 0) + 1
					end
				end
			end
		end
		T.ok((hits.guard or 0) > (hits.a or 0) * 2, "the guard is picked far more than any other")
		local foes = {
			{ id = "full", attack = 1, defence = 1, speed = 1, hp = 50 },
			{ id = "hurt", attack = 1, defence = 1, speed = 1, hp = 10, maxHp = 50 },
		}
		local fight = Combat.new({ slime("fast", "speed") }, foes, Rng.new(1))
		local first: string? = nil
		while not first do
			for _, event in Combat.step(fight, 0.1) do
				if event.kind == "aim" and event.from == "fast" then
					first = event.to
				end
			end
		end
		T.eq(first, "hurt")
	end)
	T.test(
		"skills: every few blows a skill is announced and struck; a guard takes the blows meant for its team",
		function()
			local function run(squad: { any }, foes: { any }, seconds: number): { any }
				local fight = Combat.new(squad, foes, Rng.new(5))
				local events = {}
				for _ = 1, seconds * 10 do
					for _, event in Combat.step(fight, 0.1) do
						table.insert(events, event)
					end
				end
				return events
			end
			local function foe(id: string): any
				return { id = id, attack = 0, defence = 0, speed = 0, hp = 1e6 }
			end
			local skills = Config.Combat.Skills
			-- Belly Bounce strikes every foe at once, and is announced first
			local events = run({ { id = "h", attack = 5, defence = 0, speed = 0, hp = 50, role = "hp" } }, {
				foe("x"),
				foe("y"),
				foe("z"),
			}, 30)
			local announced, struck, plain = false, {}, 0
			for _, event in events do
				if event.kind == "aim" and event.skill == "hp" then
					announced = true
				elseif (event.kind == "hit" or event.kind == "dodge") and event.from == "h" then
					if event.skill == "hp" then
						struck[event.to] = true
					else
						plain += 1
					end
				end
			end
			T.ok(announced and struck.x and struck.y and struck.z, "Belly Bounce announced, then hits all three")
			T.ok(plain >= skills.hp.every - 1, "plain blows between skills")
			-- Dash Strike: its blows numbered 1..hits
			local most = 0
			for _, event in
				run({ { id = "s", attack = 5, defence = 0, speed = 0, hp = 50, role = "speed" } }, { foe("x") }, 30)
			do
				if event.skill == "speed" and event.n then
					most = math.max(most, event.n)
				end
			end
			T.eq(most, skills.speed.hits)
			-- Jelly Guard: after the guard event, blows at the team-mate land on the guard
			events = run({
				{ id = "g", attack = 1, defence = 5, speed = 0, hp = 1e6, role = "defence" },
				{ id = "m", attack = 0, defence = 0, speed = 0, hp = 1e5, role = "hp" },
			}, { { id = "z", attack = 5, defence = 0, speed = 0, hp = 1e6, kind = "toxic" } }, 60)
			-- (a toxic zombie goes for the weaker team-mate, never the guard itself)
			local guarded = false
			for _, event in events do
				if event.kind == "hit" and event.guard == "g" then
					T.eq(event.to, "g")
					guarded = true
				end
			end
			T.ok(guarded, "a blow was taken by the guard")
			-- a skill that strikes everyone never strikes a fighter that has fallen (a guard felled covering a team-mate)
			for seed = 1, 30 do
				local fight = Combat.new({
					{ id = "g", attack = 0, defence = 0, speed = 0, hp = 3, role = "defence" },
					{ id = "m", attack = 0, defence = 0, speed = 0, hp = 1e5, role = "hp" },
				}, { { id = "z", attack = 50, defence = 0, speed = 0, hp = 1e6, kind = "toxic" } }, Rng.new(seed))
				local falls = 0
				for _ = 1, 300 do
					for _, event in Combat.step(fight, 0.1) do
						if event.kind == "fallen" and event.to == "g" then
							falls += 1
						end
					end
				end
				T.ok(falls <= 1, "the guard falls once, seed " .. seed)
			end
		end
	)
	T.test("a pack of the squad's own level is beaten more often than not, a stronger one less often", function()
		for _, level in { 4, 12, 30 } do
			local same, stronger = winRate(level, level), winRate(level, level * 2)
			T.ok(same > 0.5, "same level at " .. level .. ": " .. same)
			T.ok(same > stronger, "stronger is harder at " .. level)
		end
	end)
	T.test("the player's level is the average of the strongest slimes a trip can send", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(20))
		T.eq(Zombies.playerLevel(farm, NOW), 4)
		for index = 1, Config.Zombies.LevelTeams * Config.Zombies.TeamSize do
			farm.slimes[index].stats = { attack = 5, defence = 5, speed = 5, hp = 50 }
		end
		T.eq(Zombies.playerLevel(farm, NOW), 20, "weak slimes kept at home change nothing")
		farm.slimes[1].ghostUntil = NOW + 100
		T.eq(Zombies.playerLevel(farm, NOW), 19, "a ghost does not count")
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
		openTeams(farm)
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
	T.test("teams open as the village grows, 4 at most; a closed team cannot be filled, only emptied", function()
		local opens = Config.Zombies.TeamOpensAt
		T.eq(Zombies.teamsOpen(1), 1)
		T.eq(Zombies.teamsOpen(opens[2] - 1), 1)
		T.eq(Zombies.teamsOpen(opens[2]), 2)
		T.eq(Zombies.teamsOpen(opens[#opens]), #opens)
		T.eq(Zombies.teamsOpen(Config.Village.MaxLevel), #opens)
		local farm = FarmKit.farm(NOW, FarmKit.many(8))
		T.eq(FarmState.villageLevel(farm.areas) < opens[2], true, "a new village")
		T.ok(Zombies.setTeam(farm, 1, { "s1" }, NOW))
		T.eq(select(2, Zombies.setTeam(farm, 2, { "s2" }, NOW)), "LOCKED")
		-- (an old save may hold a line-up in a team the village has not opened: it can still be emptied)
		farm.teams[2].members = { "s3" }
		T.ok(Zombies.setTeam(farm, 2, {}, NOW))
		T.ok(not Zombies.teamOpen(farm, 2))
		openTeams(farm)
		T.ok(Zombies.teamOpen(farm, 4))
		T.ok(Zombies.setTeam(farm, 2, { "s2" }, NOW))
	end)
	T.test("the Extra Team passes add teams on top of the village's, six at most", function()
		local opens = Config.Zombies.TeamOpensAt
		T.eq(Config.Zombies.Teams, 6)
		T.eq(Zombies.teamsOpen(1, 1), 2, "one extra on a new village")
		T.eq(Zombies.teamsOpen(Config.Village.MaxLevel, 1), #opens + 1)
		T.eq(Zombies.teamsOpen(Config.Village.MaxLevel, 2), Config.Zombies.Teams)
		T.eq(Zombies.teamsOpen(Config.Village.MaxLevel, 9), Config.Zombies.Teams, "never above six")
		local farm = FarmKit.farm(NOW, FarmKit.many(30))
		openTeams(farm)
		T.eq(#farm.teams, Config.Zombies.Teams, "a farm holds six teams")
		T.ok(not Zombies.teamOpen(farm, #opens + 1), "the fifth team waits for its pass")
		T.eq(select(2, Zombies.setTeam(farm, #opens + 1, { "s20" }, NOW)), "LOCKED")
		farm.robux.passes.team5 = true
		T.ok(Zombies.teamOpen(farm, #opens + 1))
		T.ok(not Zombies.teamOpen(farm, #opens + 2))
		T.ok(Zombies.setTeam(farm, #opens + 1, { "s20" }, NOW))
		farm.robux.passes.team6 = true
		T.ok(Zombies.teamOpen(farm, Config.Zombies.Teams))
		T.ok(Zombies.setTeam(farm, Config.Zombies.Teams, { "s21", "s22" }, NOW))
		T.eq(#farm.teams[Config.Zombies.Teams].members, 2)
	end)
	T.test("one job at a time: a team slime cannot work or breed, a worker or parent cannot join a team", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		openTeams(farm)
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
		openTeams(farm)
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

		T.eq(Zombies.heal(0.5, 6), 0.5 - Config.Zombies.HealPerMinute / 10)
		T.eq(Zombies.heal(0.2, 600), 0, "never below healthy")
		T.ok(Zombies.heal(1, 30) <= 0, "a full heal takes about half a minute")
	end)
	T.test("a team walks at the pace of its slowest member", function()
		local near = Zombies.marchSeconds(100, { 1 })
		T.ok(near > 20 and near < 60, "about 100 studs at the starter walk: " .. near)
		T.eq(Zombies.marchSeconds(100, { 1, 10 }), near, "the slowest sets the pace")
		T.ok(Zombies.marchSeconds(100, { 30 }) < near, "a faster team arrives sooner")
		T.ok(Zombies.marchSeconds(200, { 1 }) > near)
		T.eq(Zombies.marchSeconds(100, {}), 0)
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
		local fight = Combat.new({ hurt }, WorldPacks.pack("z", "meadow", 4, rng), rng)
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

	T.test("changing a team keeps the remaining rows and drops transferred members' rows", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(6))
		openTeams(farm)
		T.ok(Zombies.setTeam(farm, 1, { "s1", "s2", "s3" }, NOW))
		farm.teams[1].formation = { s1 = "back", s2 = "middle", s3 = "back" }
		T.ok(Zombies.setTeam(farm, 1, { "s1", "s3", "s4" }, NOW))
		T.same(farm.teams[1].formation, { s1 = "back", s3 = "back" })
		T.ok(Zombies.setTeam(farm, 2, { "s1", "s5" }, NOW))
		T.same(farm.teams[1].members, { "s3", "s4" })
		T.same(farm.teams[1].formation, { s3 = "back" })
		T.eq(farm.teams[2].formation, nil, "the previous team's choice does not follow a transferred slime")
		T.ok(Zombies.setTeam(farm, 1, {}, NOW))
		T.eq(farm.teams[1].formation, nil)
	end)

	T.test("rowOf uses saved choice, weapon family or Brawler front; missing tactic is Balanced", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(4))
		farm.slimes[1].gear.hand = "bow-wood"
		farm.slimes[2].gear.hand = "staff-wood"
		farm.slimes[3].gear.hand = "shield-wood"
		farm.teams[1].members = { "s1", "s2", "s3", "s4" }
		T.eq(Zombies.rowOf(farm, "s1"), "middle")
		T.eq(Zombies.rowOf(farm, "s2"), "back")
		T.eq(Zombies.rowOf(farm, "s3"), "front")
		T.eq(Zombies.rowOf(farm, "s4"), "front")
		T.eq(Zombies.rowOf(farm, "unknown"), Config.Classes.Rows.Brawler)
		farm.teams[1].formation = { s1 = "back", s3 = "middle" }
		T.eq(Zombies.rowOf(farm, "s1"), "back")
		T.eq(Zombies.rowOf(farm, "s3"), "middle")
		T.eq(Zombies.tacticOf(farm.teams[1]), "balanced")
		farm.teams[1].tactic = "protect"
		T.eq(Zombies.tacticOf(farm.teams[1]), "protect")
	end)

	T.test("rowSpots centers four in one row, or each row separately in original member order", function()
		local spacing = Config.Zombies.View.FormationSpacing
		local depth = Config.Classes.Rows.Depth
		local one = Zombies.rowSpots({ "front", "front", "front", "front" })
		T.eq(#one, 4)
		for index, spot in one do
			T.near(spot.across, (index - 2.5) * spacing, 1e-9)
			T.eq(spot.back, 0)
		end
		local groups = Zombies.rowSpots({ "back", "front", "middle", "front" })
		T.eq(#groups, 4)
		T.near(groups[1].across, 0, 1e-9)
		T.eq(groups[1].back, 2 * depth)
		T.near(groups[2].across, -spacing / 2, 1e-9)
		T.eq(groups[2].back, 0)
		T.near(groups[3].across, 0, 1e-9)
		T.eq(groups[3].back, depth)
		T.near(groups[4].across, spacing / 2, 1e-9)
		T.eq(groups[4].back, 0)
	end)
end
