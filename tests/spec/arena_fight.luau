--!strict
local ArenaFight = require("../../src/shared/ArenaFight")
local Bots = require("../../src/shared/ArenaBots")
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Gear = require("../../src/shared/Gear")
local Rng = require("../../src/shared/Rng")
local FarmKit = require("../lib/FarmKit")

return function(T)
	T.test("Arena fighters use base plus gear, full health, and the same role on both sides", function()
		local slime = FarmKit.slime("s", { stats = { attack = 4, defence = 3, speed = 2, hp = 50 } })
		slime.needs.fullness = 0
		slime.buff = { stat = "attack", percent = 100, untilTime = 1e10 }
		slime.ghostUntil = 1e10
		for id, piece in Config.Smithy.Gear do
			if piece.slot == "hand" then
				slime.gear.hand = id
				break
			end
		end
		T.ok(slime.gear.hand)
		local bonus = Gear.bonus(slime)
		local a = ArenaFight.fighter(slime, "a:")
		local d = ArenaFight.fighter(slime, "d:")
		T.eq(a.id, "a:s")
		T.eq(d.id, "d:s")
		T.eq(a.attack, 4 + bonus.attack)
		T.eq(a.defence, 3 + bonus.defence)
		T.eq(a.speed, 2 + bonus.speed)
		T.eq(a.hp, 50 + bonus.hp)
		T.eq(a.maxHp, a.hp)
		T.eq(a.role, Combat.role(a, slime.seed))
		d.id = a.id
		T.same(a, d)
		T.eq(ArenaFight.power({ a }), math.round(a.attack + a.defence + a.speed + a.hp / Config.Stats.HpPerLevel))
	end)
	T.test("power rounds the final sum and includes all gear stats", function()
		local fighter = { id = "s", attack = 1.2, defence = 1.1, speed = 1.1, hp = 10 }
		T.eq(ArenaFight.power({ fighter, fighter }), 9)
		T.eq(ArenaFight.power({}), 0)
	end)
	T.test("snapshots preserve requested order and the builder's appearance fields", function()
		local farm = FarmKit.farm(0, {
			FarmKit.slime("plain"),
			FarmKit.slime("dual", { appearance = { type = "dual", definitionId = "dual-look" } }),
			FarmKit.slime("secret", { appearance = { type = "secret", definitionId = "secret-look" } }),
			FarmKit.slime("material", { appearance = { type = "material", definitionId = "gold" } }),
		})
		local snap = ArenaFight.snapshot(farm, { "material", "secret", "dual", "plain" })
		T.ok(snap)
		T.eq(snap.fighters[1].id, "material")
		T.eq(snap.looks[1].Material, "gold")
		T.eq(snap.looks[2].SecretId, "secret-look")
		T.eq(snap.looks[3].DualId, "dual-look")
		T.same(snap.looks[4], { Colour = "navy" })
		T.eq(snap.power, ArenaFight.power(snap.fighters))
		snap.fighters[1].attack = 1000
		snap.looks[4].Colour = "red"
		T.eq(farm.slimes[4].stats.attack, 1)
		T.eq(farm.slimes[1].visibleColour, "navy")
	end)
	T.test("invalid snapshot ids, repeated slimes and empty or oversized teams are refused", function()
		local farm = FarmKit.farm(0, FarmKit.many(Config.Arena.TeamSize + 1))
		T.eq(ArenaFight.snapshot(farm, {}), nil)
		T.eq(ArenaFight.snapshot(farm, { "s1", "unknown" }), nil)
		T.eq(ArenaFight.snapshot(farm, { "s1", "s1" }), nil)
		local ids = {}
		for _, slime in farm.slimes do
			table.insert(ids, slime.id)
		end
		T.eq(ArenaFight.snapshot(farm, ids), nil)
	end)
	T.test("same seed gives the same replay and simulation never mutates its inputs", function()
		local team = Bots.team(202611, "b500")
		local first = ArenaFight.simulate(team.fighters, team.fighters, 123)
		T.same(first, ArenaFight.simulate(team.fighters, team.fighters, 123))
		T.same(team, Bots.team(202611, "b500"))
		T.ok(first.seconds > 0 and first.seconds <= Config.Arena.MaxFightSeconds)
		T.ok(#first.steps > 0)
		local ids = {}
		for _, fighter in team.fighters do
			ids["a:" .. fighter.id], ids["d:" .. fighter.id] = true, true
		end
		local previous = 0
		for _, step in first.steps do
			T.ok(step.t > previous)
			T.ok(#step.events > 0)
			previous = step.t
			for _, event in step.events do
				T.ok(ids[event.to])
				if event.from then
					T.ok(ids[event.from])
				end
			end
		end
	end)
	T.test("timeout is a defender win at exactly the configured deadline", function()
		local tank = { id = "same", attack = 0, defence = 0, speed = 0, hp = 1e9 }
		local replay = ArenaFight.simulate({ tank }, { tank }, 123)
		T.eq(replay.won, false)
		T.eq(replay.seconds, Config.Arena.MaxFightSeconds)
		T.eq(tank.id, "same")
		T.eq(tank.hp, 1e9)
	end)
	T.test("won means the attack side won and decisive fights end before timeout", function()
		local strong = { id = "s", attack = 1000, defence = 1000, speed = 100, hp = 10000 }
		local weak = { id = "w", attack = 0, defence = 0, speed = 0, hp = 1 }
		local victory = ArenaFight.simulate({ strong }, { weak }, 17)
		T.eq(victory.won, true)
		T.ok(victory.seconds < Config.Arena.MaxFightSeconds)
		T.eq(ArenaFight.simulate({ weak }, { strong }, 17).won, false)
	end)
	T.test("nil, omitted and false fair options preserve event and RNG sequences", function()
		local a = { id = "a", attack = 1, defence = 0, speed = 0, hp = 1000 }
		local d = { id = "d", attack = 1, defence = 0, speed = 0, hp = 1000 }
		local rngA, rngB, rngC = Rng.new(77), Rng.new(77), Rng.new(77)
		local omitted = Combat.new({ a }, { d }, rngA)
		local explicit = Combat.new({ a }, { d }, rngB, nil)
		local disabled = Combat.new({ a }, { d }, rngC, { fair = false })
		for _ = 1, 200 do
			local events = Combat.step(omitted, Config.Zombies.FightStepSeconds)
			T.same(events, Combat.step(explicit, Config.Zombies.FightStepSeconds))
			T.same(events, Combat.step(disabled, Config.Zombies.FightStepSeconds))
			for _, event in events do
				if event.from == "d" and event.kind == "hit" then
					T.eq(event.crit, false)
				end
			end
		end
		local nextA, nextB, nextC = rngA:next(), rngB:next(), rngC:next()
		T.eq(nextA, nextB)
		T.eq(nextB, nextC)
	end)
	T.test("legacy foes skip the crit draw, while fair foes can crit", function()
		local a = { id = "a", attack = 1, defence = 0, speed = 0, hp = 1000 }
		local d = { id = "d", attack = 1, defence = 0, speed = 0, hp = 1000 }
		for _, fair in { false, true } do
			local draws = 0
			local rng = Rng.fromSource(function()
				draws += 1
				return 0
			end)
			local fight = Combat.new({ a }, { d }, rng, { fair = fair })
			T.eq(fight.fair, fair)
			local foeHit = false
			for _, event in Combat.step(fight, 2) do
				if event.from == "d" and event.kind == "hit" then
					foeHit = true
					T.eq(event.crit, fair)
				end
			end
			T.ok(foeHit)
			T.eq(draws, if fair then 10 else 9)
		end
	end)
end
