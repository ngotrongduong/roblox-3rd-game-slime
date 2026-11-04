--!strict
-- The Slime Dungeon's rules: what each wave sends and how strong it is, the drops and the ledger that pays them once, the
-- level ladder, the fight's new ways (a fight that stays open, a fighter that joins, healers, stings, the bosses) and the
-- schema-9 save.
local Combat = require("../../src/shared/Combat")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Food = require("../../src/shared/Food")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rng = require("../../src/shared/Rng")

local D = Config.Dungeon
local NOW = 1_000_000

local function def(id: string): any
	for _, each in (D.Maps :: any).meadow.monsters do
		if each.id == id then
			return each
		end
	end
	error("no def " .. id)
end

return function(T: any)
	T.test("a normal wave's budget is the original's table; the mini-boss and the boss come alone", function()
		T.eq(Dungeon.budget(1), 6)
		T.eq(Dungeon.budget(2), 9)
		T.eq(Dungeon.budget(3), 12)
		T.eq(Dungeon.budget(4), 15)
		T.eq(Dungeon.budget(5), nil)
		T.eq(Dungeon.budget(6), 27)
		T.eq(Dungeon.budget(7), 31)
		T.eq(Dungeon.budget(8), 35)
		T.eq(Dungeon.budget(9), 39)
		T.eq(Dungeon.budget(10), nil)
		T.eq(Dungeon.waveKind(5), "miniboss")
		T.eq(Dungeon.waveKind(10), "boss")
		T.eq(Dungeon.waveKind(1), "normal")
	end)

	T.test("wave 5 is the mini-boss alone, wave 10 the boss alone, the rest a crowd that fits the budget", function()
		local mini = Dungeon.plan("meadow", 1, 5, 99)
		T.eq(#mini, 1)
		T.eq(mini[1].defId, "green_turtle")
		T.eq(mini[1].defRole, "miniboss")
		local boss = Dungeon.plan("meadow", 1, 10, 99)
		T.eq(#boss, 1)
		T.eq(boss[1].defId, "green_boar")
		T.eq(boss[1].kind, "bramblehorn")
		local stoppedShort = false
		for wave = 1, D.Waves do
			if Dungeon.budget(wave) then
				for seed = 1, 20 do
					local crowd = Dungeon.plan("meadow", 1, wave, seed)
					local cost, ids = 0, {}
					for _, each in crowd do
						cost += def(each.defId).cost
						T.ok(each.defRole ~= "miniboss" and each.defRole ~= "boss", "no big monster in a crowd")
						T.ok(not ids[each.id], "ids are unique in a run")
						ids[each.id] = true
					end
					local budget = Dungeon.budget(wave) :: number
					T.ok(cost <= budget, "wave " .. wave .. " fits its budget")
					-- (it stopped at a def that did not fit: at most the dearest def's cost, less one, is left over)
					T.ok(budget - cost <= 2, "wave " .. wave .. " spends the budget but for what no def fits")
					stoppedShort = stoppedShort or cost < budget
				end
			end
		end
		T.ok(stoppedShort, "a wave stops at the first def that overflows, it does not hunt for a cheaper one")
	end)

	T.test("the same seed gives the same wave, another seed another", function()
		local function names(seed: number): string
			local out = {}
			for _, each in Dungeon.plan("meadow", 3, 7, seed) do
				table.insert(out, each.defId)
			end
			return table.concat(out, ",")
		end
		T.eq(names(5), names(5))
		local differs = false
		for seed = 6, 20 do
			differs = differs or names(seed) ~= names(5)
		end
		T.ok(differs)
		T.eq(Dungeon.plan("meadow", 1, 3, 5)[1].id, "m3-1")
	end)

	T.test(
		"HP and attack rise with the wave and the level, defence and speed never do, and the shown level climbs",
		function()
			local snail = def("green_snail")
			local last = 0
			for wave = 1, 9 do
				local stats = Dungeon.scale(snail, 1, wave)
				T.near(stats.hp, snail.hp * D.StatScale * D.WaveGrowth ^ (wave - 1), 1e-9)
				T.near(stats.attack, snail.attack * D.StatScale * D.WaveGrowth ^ (wave - 1), 1e-9)
				T.eq(stats.defence, snail.defence)
				T.eq(stats.speed, snail.speed)
				local level = Dungeon.monsterLevel(snail, 1, wave)
				T.ok(level >= last, "the level never falls from wave to wave")
				last = level
			end
			T.ok(Dungeon.monsterLevel(snail, 1, 9) > Dungeon.monsterLevel(snail, 1, 1))
			local one, two = Dungeon.scale(snail, 1, 1), Dungeon.scale(snail, 2, 1)
			T.near(two.hp, one.hp * D.LevelPower, 1e-9)
			T.near(two.attack, one.attack * D.LevelPower, 1e-9)
			T.eq(two.defence, one.defence)
			T.eq(two.speed, one.speed)
			T.ok(Dungeon.monsterLevel(snail, 2, 1) > Dungeon.monsterLevel(snail, 1, 1))
			local planned = Dungeon.plan("meadow", 3, 9, 4)[1]
			T.ok(planned.level >= 1 and planned.hp > 0)
			T.eq(planned.level, Dungeon.monsterLevel(def(planned.defId), 3, 9))
		end
	)

	T.test("every drop line of every monster can hit, with amounts in range, at about its chance", function()
		for _, each in (D.Maps :: any).meadow.monsters do
			local hits: { [string]: number } = {}
			local tries = 4000
			for n = 1, tries do
				for _, drop in Dungeon.rollDrops(each, 1, "m1-" .. n, 77) do
					hits[drop.item] = (hits[drop.item] or 0) + 1
					local line
					for _, candidate in each.drops do
						if candidate.item == drop.item then
							line = candidate
						end
					end
					T.ok(line ~= nil, each.id .. " drops only what its list says: " .. drop.item)
					T.ok(drop.amount >= line.min and drop.amount <= line.max, each.id .. " " .. drop.item)
				end
			end
			for _, line in each.drops do
				T.ok((hits[line.item] or 0) > 0, each.id .. " drops " .. line.item)
				T.near((hits[line.item] or 0) / tries, line.chance, 0.03, each.id .. " " .. line.item)
				T.ok(D.Materials[line.item] ~= nil, line.item .. " is a known drop")
			end
		end
		T.same(
			Dungeon.rollDrops(def("green_boar"), 1, "m10-1", 3),
			Dungeon.rollDrops(def("green_boar"), 1, "m10-1", 3),
			"the same monster and seed give the same drops"
		)
	end)

	T.test("the boss always pays 2 Bramble Horns; no monster drops cloth or common_part", function()
		for n = 1, 200 do
			local horns = 0
			for _, drop in Dungeon.rollDrops(def("green_boar"), 1, "m10-" .. n, n) do
				if drop.item == "boar_tusk" then
					horns += drop.amount
				end
			end
			T.eq(horns, 2)
		end
		for _, each in (D.Maps :: any).meadow.monsters do
			for _, line in each.drops do
				T.ok(line.item ~= "cloth" and line.item ~= "common_part", each.id .. " drops neither")
			end
		end
		T.eq(table.find(D.DropOrder, "cloth"), nil)
		T.eq(table.find(D.DropOrder, "common_part"), nil)
		T.ok(D.Materials.cloth ~= nil and D.Materials.common_part ~= nil, "saves still hold them")
		T.eq(D.Materials.boar_tusk.name, "Bramble Horn")
		T.eq(D.Materials.boar_tusk.short, "Horn")
		T.eq(D.Materials.rare_part.name, "Core Fragment")
		T.eq(D.Materials.rare_part.short, "Fragment")
	end)

	T.test("luck raises a chance below 1 but never past 1, and leaves a sure line alone", function()
		T.near(Dungeon.luck(1), 1, 1e-9)
		T.near(Dungeon.luck(21), 2, 1e-9)
		T.near(Dungeon.chance({ chance = 0.25 }, 1), 0.25, 1e-9)
		T.near(Dungeon.chance({ chance = 0.25 }, 21), 0.5, 1e-9)
		T.eq(Dungeon.chance({ chance = 0.5 }, 41), 1)
		T.eq(Dungeon.chance({ chance = 0.9 }, 1000), 1)
		T.eq(Dungeon.chance({ chance = 1 }, 1000), 1)
		local function essence(level: number): number
			local count = 0
			for n = 1, 6000 do
				for _, drop in Dungeon.rollDrops(def("green_boar"), level, "m10-" .. n, 5) do
					if drop.item == "boss_essence" then
						count += 1
					end
				end
			end
			return count
		end
		local low, high = essence(1), essence(21)
		T.ok(high > low * 1.5, "level 21 has twice the luck: " .. low .. " -> " .. high)
		-- and a Twigling pays wood more often
		local function wood(level: number): number
			local count = 0
			for n = 1, 4000 do
				for _, drop in Dungeon.rollDrops(def("green_sprout"), level, "m1-" .. n, 5) do
					if drop.item == "wood" then
						count += 1
					end
				end
			end
			return count
		end
		T.ok(wood(21) > wood(1) * 1.5, "luck makes a plain drop likelier")
		-- a line that is sure keeps paying at any level
		for n = 1, 100 do
			local got = {}
			for _, drop in Dungeon.rollDrops(def("green_boar"), 200, "m10-" .. n, n) do
				got[drop.item] = true
			end
			T.ok(got.coins and got.ore and got.rare_part and got.monster_core and got.boar_tusk, "sure lines pay")
		end
	end)

	T.test("a wave pays once when it clears; a second commit pays nothing", function()
		local farm = FarmKit.farm(NOW)
		farm.coins = 0
		local ledger = Dungeon.newLedger()
		T.ok(Dungeon.addDrop(ledger, 1, { item = "coins", amount = 7 }))
		T.ok(Dungeon.addDrop(ledger, 1, { item = "coins", amount = 3 }))
		T.ok(Dungeon.addDrop(ledger, 1, { item = "ore", amount = 2 }))
		T.ok(Dungeon.addDrop(ledger, 1, { item = "boar_tusk", amount = 2 }))
		T.eq(Dungeon.addDrop(ledger, 1, { item = "gold_bar", amount = 1 }), false, "an unknown item is refused")
		T.eq(Dungeon.addDrop(ledger, 1, { item = "ore", amount = 0 }), false)
		T.eq(farm.coins, 0, "nothing is paid while the wave runs")
		local paid = Dungeon.commitWave(farm, ledger, 1) :: any
		T.eq(paid.coins, 10)
		T.eq(farm.coins, 10)
		T.eq(farm.lifetime.coinsEarned, 10)
		T.eq(farm.materials.ore, 2)
		T.eq(farm.materials.boar_tusk, 2)
		T.eq(Dungeon.commitWave(farm, ledger, 1), nil, "the same wave never pays twice")
		T.eq(farm.coins, 10)
		T.eq(farm.materials.ore, 2)
		T.eq(Dungeon.addDrop(ledger, 1, { item = "ore", amount = 1 }), false, "a paid wave takes no more drops")
		T.ok(Dungeon.addDrop(ledger, 2, { item = "ore", amount = 1 }))
		Dungeon.commitWave(farm, ledger, 2)
		T.eq(farm.materials.ore, 3, "another wave pays on its own")
	end)

	T.test("a lost wave gives nothing, earlier waves stay paid", function()
		local farm = FarmKit.farm(NOW)
		farm.coins = 0
		local ledger = Dungeon.newLedger()
		Dungeon.addDrop(ledger, 1, { item = "coins", amount = 5 })
		Dungeon.commitWave(farm, ledger, 1)
		Dungeon.addDrop(ledger, 2, { item = "coins", amount = 50 })
		Dungeon.addDrop(ledger, 2, { item = "wood", amount = 4 })
		T.ok(Dungeon.discardWave(ledger, 2))
		T.eq(Dungeon.commitWave(farm, ledger, 2), nil, "a discarded wave cannot be paid afterwards")
		T.eq(Dungeon.discardWave(ledger, 1), false, "a paid wave cannot be taken back")
		T.eq(farm.coins, 5)
		T.eq(farm.materials.wood, nil)
	end)

	T.test("food goes into the storehouse; what does not fit the pantry is lost", function()
		local farm = FarmKit.farm(NOW)
		local capacity = Food.storehouseCapacity(farm.areas.pantry.level)
		farm.storehouse = { fish = capacity - 2 }
		local ledger = Dungeon.newLedger()
		Dungeon.addDrop(ledger, 1, { item = "food", amount = 5 })
		local paid = Dungeon.commitWave(farm, ledger, 1) :: any
		T.eq(paid.food, 2)
		T.eq(paid.lost, 3)
		T.eq(Food.total(farm.storehouse), capacity)
		T.eq(farm.storehouse[D.FoodItem], 2)
		T.eq(farm.materials.food, nil, "food is no material")
	end)

	T.test("the ladder opens one level at a time", function()
		local farm = FarmKit.farm(NOW)
		T.ok(Dungeon.canEnter(farm, 1))
		T.eq(Dungeon.canEnter(farm, 2), false)
		T.eq(Dungeon.canEnter(farm, 0), false)
		T.eq(Dungeon.canEnter(farm, 1.5), false)
		T.eq(Dungeon.recordClear(farm, 2), false, "a level that was not open cannot be cleared")
		T.ok(Dungeon.recordClear(farm, 1))
		T.eq(farm.dungeon.best, 1)
		T.ok(Dungeon.canEnter(farm, 2))
		T.eq(Dungeon.canEnter(farm, 3), false)
		T.ok(Dungeon.recordClear(farm, 2))
		T.eq(Dungeon.recordClear(farm, 1), false, "an old level does not lower the best")
		T.eq(farm.dungeon.best, 2)
		T.ok(Dungeon.canEnter(farm, 1), "any cleared level can be played again")
	end)

	T.test("only a grown farm enters: enough slimes and a village of the set level", function()
		local farm = FarmKit.farm(NOW, FarmKit.many(D.EnterMinSlimes - 1))
		for _, area in farm.areas do
			area.level = D.EnterMinVillageLevel
		end
		T.eq(Dungeon.entryBlock(farm), "FEW_SLIMES")
		table.insert(farm.slimes, FarmKit.slime("extra"))
		T.eq(Dungeon.entryBlock(farm), nil)
		farm.areas[Config.Village.Areas[1]].level = D.EnterMinVillageLevel - #Config.Village.Areas
		T.eq(Dungeon.entryBlock(farm), "VILLAGE_LEVEL")
		T.eq(Dungeon.entryBlock(FarmKit.farm(NOW)), "FEW_SLIMES", "a new player's farm stays out")
		farm.areas[Config.Village.Areas[1]].level = D.EnterMinVillageLevel
		T.ok(
			FarmState.populationLimit(farm.areas) >= D.EnterMinSlimes,
			"a village of that level has room for the slimes"
		)
	end)

	T.test("an open fight does not end when the foes are down; a foe that joins carries it on", function()
		local rng = Rng.new(1)
		local striker = { id = "s", attack = 50, defence = 0, speed = 0, hp = 1000 }
		local function foe(id: string): any
			return { id = id, attack = 0, defence = 0, speed = 0, hp = 1 }
		end
		local fight = Combat.new({ striker }, { foe("a") }, rng)
		fight.open = true
		local fell: { [string]: boolean } = {}
		local function run(steps: number)
			for _ = 1, steps do
				for _, event in Combat.step(fight, 0.1) do
					if event.kind == "fallen" then
						fell[event.to] = true
					end
				end
			end
		end
		run(100)
		T.ok(fell.a, "the first foe fell")
		T.eq(fight.winner, nil, "the fight stays open")
		Combat.add(fight, foe("b"), "foe")
		run(100)
		T.ok(fell.b, "the foe that joined was fought")
		T.eq(fight.winner, nil)
		fight.open = false
		run(1)
		T.eq(fight.winner, "squad", "closed again, the fight is won")
		T.eq(Combat.add(fight, foe("c"), "foe"), nil, "nobody joins a finished fight")
		-- a squad wiped out ends an open fight all the same
		local doomed = Combat.new(
			{ { id = "d", attack = 0, defence = 0, speed = 0, hp = 1 } },
			{ { id = "f", attack = 50, defence = 0, speed = 0, hp = 1000 } },
			Rng.new(2)
		)
		doomed.open = true
		for _ = 1, 100 do
			Combat.step(doomed, 0.1)
		end
		T.eq(doomed.winner, "foe")
	end)

	T.test("a squad that waited for the next foe does not strike all its missed blows at once", function()
		local fight = Combat.new({ { id = "s", attack = 1, defence = 0, speed = 5, hp = 1e6 } }, {}, Rng.new(3))
		fight.open = true
		for _ = 1, 600 do
			Combat.step(fight, 0.1)
		end
		Combat.add(fight, { id = "z", attack = 0, defence = 0, speed = 0, hp = 1e6 }, "foe")
		local blows = 0
		for _ = 1, 10 do
			for _, event in Combat.step(fight, 0.1) do
				if event.from == "s" and (event.kind == "hit" or event.kind == "dodge") then
					blows += 1
				end
			end
		end
		T.ok(blows <= 1, "a second after the foe came, at most one blow: " .. blows)
	end)

	T.test("a healer mends the most wounded team-mate instead of striking; with nobody hurt it strikes", function()
		local function squad(): { any }
			return { { id = "s", attack = 0, defence = 0, speed = 0, hp = 1e6 } }
		end
		local healer = { id = "h", attack = 10, defence = 0, speed = 1, hp = 1e6, kind = "healer" }
		local hurt = { id = "w", attack = 0, defence = 0, speed = 0, hp = 30, maxHp = 100, kind = "melee" }
		local worse = { id = "x", attack = 0, defence = 0, speed = 0, hp = 10, maxHp = 100, kind = "melee" }
		local fight = Combat.new(squad(), { healer, hurt, worse }, Rng.new(4))
		local heals = {}
		for _ = 1, 150 do
			for _, event in Combat.step(fight, 0.1) do
				if event.kind == "heal" then
					table.insert(heals, event)
				end
			end
		end
		T.ok(#heals >= 2)
		T.eq(heals[1].from, "h")
		T.eq(heals[1].to, "x", "the most wounded first")
		T.near(heals[1].amount, 10 * Config.Combat.Heals.healer.share, 1e-9)
		for _, unit in fight.units do
			if unit.id == "x" then
				T.ok(unit.hp > 10, "the health is back")
			end
			if unit.id == "x" or unit.id == "w" then
				T.ok(unit.hp <= 100, "never past the full health")
			end
			if unit.id == "h" then
				T.eq(unit.hp, 1e6, "a healer does not heal itself")
			end
		end
		local well = Combat.new(
			squad(),
			{ { id = "h", attack = 10, defence = 0, speed = 1, hp = 1e6, kind = "healer" } },
			Rng.new(4)
		)
		local strikesWhenWell, healed = 0, 0
		for _ = 1, 150 do
			for _, event in Combat.step(well, 0.1) do
				if event.kind == "heal" then
					healed += 1
				elseif event.from == "h" and event.kind == "hit" then
					strikesWhenWell += 1
				end
			end
		end
		T.eq(healed, 0)
		T.ok(strikesWhenWell > 0)
	end)

	T.test("a hunter goes for the weakest, a ranged fighter says so, a sting slows the target", function()
		local fresh = { id = "a", attack = 1, defence = 0, speed = 1, hp = 100 }
		local weak = { id = "b", attack = 1, defence = 0, speed = 1, hp = 10 }
		local bee = { id = "bee", attack = 3, defence = 0, speed = 5, hp = 1e6, kind = "hunter" }
		local fight = Combat.new({ fresh, weak }, { bee }, Rng.new(1))
		local first: string? = nil
		while not first do
			for _, event in Combat.step(fight, 0.1) do
				if event.kind == "aim" and event.from == "bee" then
					first = event.to
				end
			end
		end
		T.eq(first, "b")
		-- ranged
		local puff = { id = "p", attack = 3, defence = 0, speed = 2, hp = 1e6, kind = "ranged" }
		local melee = { id = "m", attack = 3, defence = 0, speed = 2, hp = 1e6, kind = "melee" }
		local function marks(foe: any): (boolean, boolean)
			local f = Combat.new({ { id = "t", attack = 0, defence = 0, speed = 0, hp = 1e6 } }, { foe }, Rng.new(1))
			local ranged, plain = false, false
			for _ = 1, 100 do
				for _, event in Combat.step(f, 0.1) do
					if event.from == foe.id and event.kind == "hit" then
						if event.ranged then
							ranged = true
						else
							plain = true
						end
					end
				end
			end
			return ranged, plain
		end
		T.same({ marks(puff) }, { true, false })
		T.same({ marks(melee) }, { false, true })
		-- the sting: the stung slime strikes far less often than when stung by a plain fighter
		local function blowsOfTarget(foe: any): (number, boolean)
			local f = Combat.new({ { id = "t", attack = 1, defence = 0, speed = 5, hp = 1e6 } }, { foe }, Rng.new(9))
			local blows, slowed = 0, false
			for _ = 1, 300 do
				for _, event in Combat.step(f, 0.1) do
					if event.from == "t" and (event.kind == "hit" or event.kind == "dodge") then
						blows += 1
					elseif event.slow then
						slowed = true
					end
				end
			end
			return blows, slowed
		end
		local stungBlows, stung =
			blowsOfTarget({ id = "e", attack = 3, defence = 0, speed = 5, hp = 1e6, kind = "hunter" })
		local plainBlows, wasSlowed =
			blowsOfTarget({ id = "e", attack = 3, defence = 0, speed = 5, hp = 1e6, kind = "melee" })
		T.ok(stung and not wasSlowed)
		T.ok(stungBlows < plainBlows * 0.6, "stung " .. stungBlows .. " against " .. plainBlows)
	end)

	T.test("the two bosses strike their skills: Pollen Shockwave on all, Thorn Charge heavy with a splash", function()
		local function squad(): { any }
			local out = {}
			for _, id in { "a", "b", "c" } do
				table.insert(out, { id = id, attack = 0, defence = 0, speed = 0, hp = 1e6 })
			end
			return out
		end
		local function skillEvents(kind: string): { any }
			local boss = { id = "boss", attack = 5, defence = 0, speed = 2, hp = 1e9, kind = kind }
			local fight = Combat.new(squad(), { boss }, Rng.new(6))
			local out = {}
			for _ = 1, 600 do
				for _, event in Combat.step(fight, 0.1) do
					if event.skill == kind then
						table.insert(out, event)
					end
				end
			end
			return out
		end
		T.eq(Config.Combat.Skills.bloomshell.name, "Pollen Shockwave")
		T.eq(Config.Combat.Skills.bramblehorn.name, "Thorn Charge")
		local shock = skillEvents("bloomshell")
		local struck: { [string]: boolean } = {}
		for _, event in shock do
			if event.kind == "hit" then
				struck[event.to] = true
			end
		end
		T.ok(struck.a and struck.b and struck.c, "the shockwave reaches all three")
		local charge = skillEvents("bramblehorn")
		local heavy, splash = false, false
		for _, event in charge do
			if event.kind == "hit" and event.splash then
				splash = true
			elseif event.kind == "hit" then
				heavy = true
			end
		end
		T.ok(heavy and splash, "a heavy blow and thorns beside it")
	end)

	T.test("the best dungeon level is saved, repaired and migrated from schema 8", function()
		local farm: any = FarmState.newFarm(NOW)
		T.same(farm.dungeon, { best = 0 })
		farm.dungeon.best = 4
		T.same(FarmState.repair(farm, NOW).dungeon, { best = 4 })
		for _, bad in { -3, "x", 2.5, 0 / 0 } do
			local broken: any = FarmState.newFarm(NOW)
			broken.dungeon = { best = bad }
			local fixed = FarmState.repair(broken, NOW)
			T.ok(fixed.dungeon.best >= 0 and fixed.dungeon.best % 1 == 0, "best repaired from " .. tostring(bad))
		end
		local half: any = FarmState.newFarm(NOW)
		half.dungeon = { best = 2.5 }
		T.eq(FarmState.repair(half, NOW).dungeon.best, 2)
		local nothing: any = FarmState.newFarm(NOW)
		nothing.dungeon = "x"
		T.same(FarmState.repair(nothing, NOW).dungeon, { best = 0 })
		local old: any = FarmState.newFarm(NOW)
		old.dungeon = nil
		old.coins = 777
		local load =
			ProfileLogic.prepareLoad({ schemaVersion = 8, savedAt = NOW, data = old }, FarmSave.hooks(), NOW + 1)
		T.ok(load.ok and load.migrated)
		T.eq(load.data.coins, 777)
		T.same(load.data.dungeon, { best = 0 })
		T.eq(old.dungeon, nil, "migration never alters the stored snapshot")
	end)
end
