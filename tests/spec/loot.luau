--!strict
-- The four dungeons' loot (the owner, 2026-11-15): a group of materials a dungeon, drop tables by role and level with no luck,
-- the clear bonus, the open world's packs paying their region's basic, and Tempering.
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local FarmKit = require("../lib/FarmKit")
local Gear = require("../../src/shared/Gear")
local VillageRequests = require("../../src/shared/VillageRequests")
local WorldPacks = require("../../src/shared/WorldPacks")
local WorldPlan = require("../../src/shared/WorldPlan")

local D = Config.Dungeon
local S = Config.Smithy
local P = Config.World.Packs
local NOW = 1_000_000

local BASICS = { wood = true, silk = true, ore = true, crystal = true }

-- The chance of the Loot line of this role and item at a level (the map's own basic and trophy named "basic" / "trophy").
local function chance(mapId: string, role: string, item: string, level: number): number
	for _, line in Dungeon.lootLines(mapId, role, level) do
		if line.item == item then
			return line.chance
		end
	end
	return 0
end

-- One whole run of a dungeon: every wave planned, its monsters' drops rolled and paid. Returns the basics paid.
local function fullClear(mapId: string, level: number, seed: number): number
	local farm: any = FarmKit.farm(NOW)
	farm.materials = {}
	local ledger = Dungeon.newLedger()
	for wave = 1, D.Waves do
		for _, monster in Dungeon.plan(mapId, level, wave, seed) do
			local each = Dungeon.defOf(mapId, monster.defId)
			for _, drop in Dungeon.rollDrops(each, level, monster.id .. ":" .. seed, seed, mapId) do
				Dungeon.addDrop(ledger, wave, drop)
			end
		end
		Dungeon.commitWave(farm, ledger, wave, NOW)
	end
	local basics = 0
	for item, amount in farm.materials do
		if BASICS[item] then
			basics += amount
		end
	end
	return basics
end

-- A piece's points as a rough power: HP counts a tenth.
local function power(id: string): number
	local piece = (S.Gear :: any)[id]
	local total = 0
	for key, points in piece.stats do
		total += if key == "hp" then points / 10 else points
	end
	return total
end

local function rich(): any
	local farm: any = FarmKit.farm(NOW)
	farm.materials = {}
	return farm
end

return function(T: any)
	T.test(
		"each dungeon has its own basic and trophy, the four basics are four materials, and nothing is lucky",
		function()
			local seen: { [string]: boolean } = {}
			for _, id in D.MapOrder do
				local each = (D.Maps :: any)[id]
				T.ok(BASICS[each.basic] and not seen[each.basic], id .. " has a basic of its own")
				seen[each.basic] = true
				T.ok(D.Materials[each.trophy] ~= nil)
			end
			T.eq((D.Maps :: any).meadow.basic, "wood")
			T.eq((D.Maps :: any).mushroom.basic, "silk")
			T.eq((D.Maps :: any).lava.basic, "ore")
			T.eq((D.Maps :: any).ice.basic, "crystal")
			T.eq((D.Maps :: any).ice.trophy, "frost_fang")
			T.eq(D.Materials.silk.name, "Mushroom Silk")
			T.eq(D.Materials.crystal.short, "Crystal")
			T.eq((D :: any).LuckPerLevel, nil)
			T.eq((Dungeon :: any).luck, nil)
			T.eq((Dungeon :: any).chance, nil)
			-- the monsters' own lines are coins and food only
			for _, id in D.MapOrder do
				for _, each in (D.Maps :: any)[id].monsters do
					for _, line in each.drops do
						T.ok(line.item == "coins" or line.item == "food", each.id .. " drops " .. line.item)
					end
				end
			end
		end
	)

	T.test("the loot lines follow the owner's bands by role and level", function()
		for _, level in { 1, 20 } do
			T.near(chance("meadow", "swarmer", "wood", level), 0.20, 1e-9)
		end
		T.near(chance("meadow", "armoured", "wood", 21), 0.24, 1e-9)
		T.near(chance("meadow", "raider", "wood", 50), 0.24, 1e-9)
		T.near(chance("meadow", "raider", "wood", 51), 0.30, 1e-9)
		T.near(chance("meadow", "raider", "wood", 90), 0.30, 1e-9)
		T.near(chance("meadow", "raider", "wood", 91), 0.40, 1e-9)
		T.near(chance("mushroom", "shaman", "silk", 150), 0.40, 1e-9)
		-- regulars: Core Fragment, Monster Core
		T.eq(chance("lava", "swarmer", "rare_part", 20), 0)
		T.near(chance("lava", "swarmer", "rare_part", 21), 0.02, 1e-9)
		T.near(chance("lava", "swarmer", "rare_part", 51), 0.01, 1e-9)
		T.eq(chance("lava", "swarmer", "rare_part", 91), 0)
		T.eq(chance("lava", "swarmer", "monster_core", 50), 0)
		T.near(chance("lava", "swarmer", "monster_core", 51), 0.02, 1e-9)
		T.near(chance("lava", "swarmer", "monster_core", 91), 0.03, 1e-9)
		T.eq(chance("lava", "swarmer", "boss_essence", 200), 0)
		T.eq(chance("lava", "swarmer", "ore", 200) > 0, true)
		-- the mini-boss
		T.near(chance("ice", "miniboss", "rare_part", 20), 0.03, 1e-9)
		T.near(chance("ice", "miniboss", "rare_part", 21), 0.35, 1e-9)
		T.eq(chance("ice", "miniboss", "monster_core", 30), 0)
		T.near(chance("ice", "miniboss", "monster_core", 31), 0.03, 1e-9)
		T.near(chance("ice", "miniboss", "monster_core", 51), 0.50, 1e-9)
		T.eq(chance("ice", "miniboss", "boss_essence", 99), 0)
		T.near(chance("ice", "miniboss", "boss_essence", 100), 0.20, 1e-9)
		T.near(chance("ice", "miniboss", "frost_fang", 1), 0.30, 1e-9)
		T.near(chance("ice", "miniboss", "crystal", 1), 1, 1e-9)
		-- the boss
		T.near(chance("meadow", "boss", "rare_part", 20), 0.03, 1e-9)
		T.near(chance("meadow", "boss", "rare_part", 21), 0.70, 1e-9)
		T.near(chance("meadow", "boss", "monster_core", 40), 0.03, 1e-9)
		T.near(chance("meadow", "boss", "monster_core", 51), 1, 1e-9)
		T.eq(chance("meadow", "boss", "boss_essence", 80), 0)
		T.near(chance("meadow", "boss", "boss_essence", 81), 0.10, 1e-9)
		T.near(chance("meadow", "boss", "boss_essence", 90), 0.10 + 0.15 * 9 / 18, 1e-9)
		T.near(chance("meadow", "boss", "boss_essence", 99), 0.25, 1e-9)
		T.near(chance("meadow", "boss", "boss_essence", 100), 1, 1e-9)
		T.near(chance("meadow", "boss", "boar_tusk", 1), 1, 1e-9)
		-- a mini-boss pays 2-3 basics, a boss 3-5, a regular 1
		for _, line in Dungeon.lootLines("meadow", "miniboss", 1) do
			if line.item == "wood" then
				T.eq(line.min, 2)
				T.eq(line.max, 3)
			end
		end
		for _, line in Dungeon.lootLines("meadow", "boss", 1) do
			if line.item == "wood" then
				T.eq(line.min, 3)
				T.eq(line.max, 5)
			end
		end
		-- the same lines at every level, so a stream's rolls never shift
		T.eq(#Dungeon.lootLines("meadow", "boss", 1), #Dungeon.lootLines("meadow", "boss", 150))
	end)

	T.test(
		"a seeded drop is the same twice, a boss always pays its basic and trophy, and the gate lists what can drop",
		function()
			local boss = Dungeon.defOf("lava", "lava_golem")
			T.same(Dungeon.rollDrops(boss, 60, "m10-1", 5, "lava"), Dungeon.rollDrops(boss, 60, "m10-1", 5, "lava"))
			for n = 1, 100 do
				local got: { [string]: number } = {}
				for _, drop in Dungeon.rollDrops(boss, 1, "m10-" .. n, n, "lava") do
					got[drop.item] = (got[drop.item] or 0) + drop.amount
				end
				T.ok((got.ore or 0) >= 3 and (got.ore or 0) <= 5, "a boss pays 3-5 Iron Ore")
				T.eq(got.ember_core, 1)
				T.eq(got.monster_core, nil, "no Monster Core under level 31")
			end
			-- no mapId: the def's own lines only (a zone's fight)
			for n = 1, 200 do
				for _, drop in Dungeon.rollDrops(boss, 200, "m10-" .. n, n) do
					T.ok(drop.item == "coins" or drop.item == "food")
				end
			end
			local low, high = Dungeon.dropTable("meadow", 1), Dungeon.dropTable("meadow", 120)
			T.ok(low.wood ~= nil and low.coins ~= nil and low.boar_tusk ~= nil)
			T.eq(low.boss_essence, nil)
			T.eq(low.monster_core, nil)
			T.ok(high.boss_essence ~= nil and high.monster_core ~= nil and high.rare_part ~= nil)
			T.same(low.wood, { 1, 5 })
		end
	)

	T.test("a full clear pays more basics the deeper it goes", function()
		local function average(mapId: string, level: number): number
			local total = 0
			for seed = 1, 40 do
				total += fullClear(mapId, level, seed)
			end
			return total / 40
		end
		local a, b, c, d = average("meadow", 10), average("meadow", 30), average("meadow", 70), average("meadow", 100)
		T.ok(a > 10 and a < b and b < c and c < d, `{a} {b} {c} {d}`)
	end)

	T.test(
		"a run's coins rise with its monsters' level, the same by role in every dungeon; a zone's fight pays the line as it stands",
		function()
			local function coinLine(each: any): any
				for _, line in each.drops do
					if line.item == "coins" then
						return line
					end
				end
				return nil
			end
			local function coins(each: any, level: number, key: string, seed: number, mapId: string?): number
				local sum = 0
				for _, drop in Dungeon.rollDrops(each, level, key, seed, mapId) do
					sum += if drop.item == "coins" then drop.amount else 0
				end
				return sum
			end
			local boss = Dungeon.defOf("meadow", "green_boar")
			local line = coinLine(boss)
			for n = 1, 100 do
				local zone = coins(boss, 200, "m10-" .. n, n)
				T.ok(zone >= line.min and zone <= line.max, "a zone's fight pays the line as it stands")
				for _, level in { 1, 100 } do
					local grow = 1 + Dungeon.mainLevel(level) * Config.Economy.SellLevelStep
					local got = coins(boss, level, "m10-" .. n, n, "meadow")
					T.ok(
						got >= math.floor(line.min * grow + 0.5) and got <= math.floor(line.max * grow + 0.5),
						`level {level} pays {got}`
					)
				end
			end
			T.same(Dungeon.dropTable("meadow", 1).coins, { 60, 600 })
			T.same(Dungeon.dropTable("meadow", 100).coins, { 300, 3000 })
			-- no dungeon is the one to farm coins in
			local byRole: { [string]: any } = {}
			for _, id in D.MapOrder do
				for _, each in (D.Maps :: any)[id].monsters do
					local own = coinLine(each)
					local seen = byRole[each.role] or own
					byRole[each.role] = seen
					T.same({ own.chance, own.min, own.max }, { seen.chance, seen.min, seen.max }, each.id)
				end
			end
			-- a won run is worth three to five fights with a pack of its monsters' level (what one team earns from the
			-- world in the five minutes a run lasts: tools/balance/road_sim.luau)
			local roster = WorldPacks.roster("meadow")
			for _, level in { 1, 40, 150 } do
				local fight = 0
				for _, def in roster do
					fight += WorldPacks.killReward(def.role, Dungeon.mainLevel(level)) / #roster * (P.SizeMin + P.SizeMax) / 2
				end
				local sum, runs = 0, 0
				for _, id in D.MapOrder do
					for seed = 1, 5 do
						for wave = 1, D.Waves do
							for _, monster in Dungeon.plan(id, level, wave, seed) do
								local each = Dungeon.defOf(id, monster.defId)
								sum += coins(each, level, monster.id .. ":" .. seed, seed, id)
							end
						end
						runs += 1
					end
				end
				local worth = sum / runs / fight
				T.ok(worth >= 3 and worth <= 5, `a level {level} run is worth {worth} pack fights`)
			end
		end
	)

	T.test("the clear bonus is paid once with wave 10, never on a lost wave 10 or an earlier wave", function()
		local farm = rich()
		local ledger = Dungeon.newLedger()
		Dungeon.addDrop(ledger, 1, { item = "wood", amount = 10 })
		Dungeon.addDrop(ledger, 1, { item = "ore", amount = 7 })
		Dungeon.addDrop(ledger, 1, { item = "boar_tusk", amount = 3 })
		Dungeon.commitWave(farm, ledger, 1)
		T.eq(farm.materials.wood, 10, "no bonus on wave 1")
		Dungeon.addDrop(ledger, 10, { item = "wood", amount = 5 })
		local paid: any = Dungeon.commitWave(farm, ledger, 10, NOW)
		-- 15 wood collected: +35% rounded is 5; 7 ore: +2
		T.eq(paid.materials.wood, 10)
		T.eq(paid.materials.ore, 2)
		T.eq(farm.materials.wood, 20)
		T.eq(farm.materials.ore, 9)
		T.eq(farm.materials.boar_tusk, 3, "trophies get no bonus")
		T.eq(Dungeon.commitWave(farm, ledger, 10, NOW), nil)
		T.eq(farm.materials.wood, 20, "never twice")
		-- a lost wave 10 pays nothing, bonus included
		local lost = rich()
		local run = Dungeon.newLedger()
		Dungeon.addDrop(run, 1, { item = "silk", amount = 20 })
		Dungeon.commitWave(lost, run, 1)
		Dungeon.addDrop(run, 10, { item = "silk", amount = 5 })
		Dungeon.discardWave(run, 10)
		T.eq(Dungeon.commitWave(lost, run, 10), nil)
		T.eq(lost.materials.silk, 20)
	end)

	T.test(
		"a pack pays its region's basic, the Vale rotates the four, and the loot is fixed by the pack's roll",
		function()
			for _, region in WorldPlan.Regions do
				local at = region.at[1]
				local basic = WorldPacks.material("p5x5", at[1], at[2])
				if region.id == "vale" then
					T.ok(BASICS[basic])
				else
					T.eq(basic, (D.Maps :: any)[(P.Maps :: any)[region.id]].basic, region.id)
				end
			end
			local vale = WorldPlan.Regions[1].at[1]
			T.eq(WorldPlan.Regions[1].id, "vale")
			local seen: { [string]: boolean } = {}
			for col = 1, 4 do
				seen[WorldPacks.material("p" .. col .. "x1", vale[1], vale[2])] = true
			end
			for basic in BASICS do
				T.ok(seen[basic], "the Vale pays " .. basic)
			end
			T.eq(
				WorldPacks.material("p2x3", vale[1], vale[2]),
				WorldPacks.material("p2x3", vale[1], vale[2]),
				"the same cell always pays the same"
			)
			T.same(WorldPacks.loot("p1x1-7", "wood", 30), WorldPacks.loot("p1x1-7", "wood", 30))
			local rare, core, second = 0, 0, 0
			local tries = 6000
			for n = 1, tries do
				for _, drop in WorldPacks.loot("p1x1-" .. n, "ore", 70) do
					T.ok(drop.item ~= "boss_essence" and drop.item ~= "frost_fang" and drop.item ~= "ember_core")
					if drop.item == "rare_part" then
						rare += 1
					elseif drop.item == "monster_core" then
						core += 1
					elseif drop.amount == 2 then
						second += 1
					end
				end
				local early = WorldPacks.loot("p1x1-" .. n, "ore", 20)
				T.eq(#early, 1, "no catalyst under level 25")
				T.eq(early[1].amount, 1, "one unit under level 60")
				T.eq(#WorldPacks.loot("p1x1-" .. n, "ore", 40) <= 2, true)
			end
			T.near(rare / tries, P.RarePartChance, 0.02)
			T.near(core / tries, P.MonsterCoreChance, 0.02)
			T.near(second / tries, P.SecondBasicChance, 0.03)
			for n = 1, 500 do
				for _, drop in WorldPacks.loot("p1x1-" .. n, "ore", 40) do
					T.ok(drop.item ~= "monster_core", "no Monster Core under level 65")
				end
			end
		end
	)

	T.test("every recipe is two basics and its catalysts, by family", function()
		T.same(S.Recipes["sword-core"].materials, { ore = 12, wood = 8, rare_part = 2 })
		T.same(S.Recipes["shield-bramble"].materials, { ore = 20, crystal = 12, monster_core = 3 })
		T.same(S.Recipes["kit-legend"].materials, { silk = 30, ore = 20, monster_core = 5, boss_essence = 2 })
		T.same(S.Recipes["focus-iron"].materials, { crystal = 6, silk = 4 })
		T.eq(S.Recipes["helm-core"].coins, 1500)
		T.same(S.Recipes["helm-core"].materials, { ore = 6, silk = 4, rare_part = 1 })
		T.eq(S.Recipes["helm-legend"], nil)
		T.eq(S.Recipes["sword-wood"].coins, 0)
	end)

	T.test(
		"a tempered twin is +1 to the main stat, HP +10, and stays below the plain piece of the next tier",
		function()
			T.same((S.Gear :: any)["sword-iron-t"].stats, { attack = 3 })
			T.same((S.Gear :: any)["shield-iron-t"].stats, { defence = 2, hp = 20 })
			T.eq((S.Gear :: any)["sword-iron-t"].base, "sword-iron")
			T.eq((S.Gear :: any)["sword-iron-t"].tempered, true)
			T.eq((S.Gear :: any)["sword-iron-t"].icon, (S.Gear :: any)["sword-iron"].icon)
			T.eq((S.Gear :: any)["sword-wood-t"], nil, "Common has no twin")
			for family in S.Pairs do
				for index, tier in S.TierOrder do
					local plain = family .. "-" .. tier
					local nextPlain = family .. "-" .. (S.TierOrder[index + 1] or "none")
					if (S.Gear :: any)[plain .. "-t"] then
						T.ok(power(plain .. "-t") > power(plain))
						if (S.Gear :: any)[nextPlain] then
							-- (never above; the Alchemy Kit's iron twin only reaches its core piece's level, 4 = 4: +1 on a gap of 1)
							T.ok(power(plain .. "-t") <= power(nextPlain), plain .. "-t is below " .. nextPlain)
						end
					end
				end
			end
		end
	)

	T.test("Tempering takes the piece and the trophies, all or nothing", function()
		local farm = rich()
		farm.gear = { ["sword-iron"] = 1 }
		-- iron: one trophy of either of Ember Lava's and Sunny Meadow's (the sword is ore + wood); the bag's larger heap goes
		T.eq(select(2, Gear.temper(farm, "sword-iron")), "INSUFFICIENT_MATERIALS")
		farm.materials = { boar_tusk = 1, ember_core = 3 }
		T.eq(Gear.temper(farm, "sword-iron"), "sword-iron-t")
		T.same(farm.materials, { boar_tusk = 1, ember_core = 2 })
		T.same(farm.gear, { ["sword-iron-t"] = 1 })
		T.eq(farm.lifetime.gearCrafted, 1)
		-- nothing left to temper: the bag is untouched
		T.eq(select(2, Gear.temper(farm, "sword-iron")), "NOT_IN_BAG")
		-- core: one of each; a missing trophy leaves everything as it was
		farm.gear = { ["bow-core"] = 1 }
		farm.materials = { boar_tusk = 5 }
		local before = { gear = table.clone(farm.gear), materials = table.clone(farm.materials) }
		T.eq(select(2, Gear.temper(farm, "bow-core")), "INSUFFICIENT_MATERIALS")
		T.same(farm.gear, before.gear)
		T.same(farm.materials, before.materials)
		farm.materials = { boar_tusk = 1, glow_spore = 1, silk = 9 }
		T.eq(Gear.temper(farm, "bow-core"), "bow-core-t")
		T.same(farm.materials, { silk = 9 })
		-- bramble: one of each and 2 Monster Cores; legend: 2 of each and 2 Boss Essence
		farm.gear = { ["shield-bramble"] = 1, ["staff-legend"] = 1 }
		farm.materials = { ember_core = 1, frost_fang = 1, monster_core = 1 }
		T.eq(select(2, Gear.temper(farm, "shield-bramble")), "INSUFFICIENT_MATERIALS")
		farm.materials.monster_core = 2
		T.eq(Gear.temper(farm, "shield-bramble"), "shield-bramble-t")
		T.same(farm.materials, {})
		farm.materials = { boar_tusk = 2, frost_fang = 2, boss_essence = 2 }
		T.eq(Gear.temper(farm, "staff-legend"), "staff-legend-t")
		T.same(farm.materials, {})
		T.eq(farm.gear["staff-legend-t"], 1)
		-- refusals: Common, a tempered piece, an unknown id
		farm.gear = { ["sword-wood"] = 1, ["sword-iron-t"] = 1 }
		farm.materials = { boar_tusk = 9, ember_core = 9 }
		T.eq(select(2, Gear.temper(farm, "sword-wood")), "CANNOT_TEMPER")
		T.eq(select(2, Gear.temper(farm, "sword-iron-t")), "CANNOT_TEMPER")
		T.eq(select(2, Gear.temper(farm, "nonsense")), "GEAR_NOT_FOUND")
		T.eq(select(2, Gear.temper(farm, 5)), "GEAR_NOT_FOUND")
		T.same(farm.materials, { boar_tusk = 9, ember_core = 9 })
	end)

	T.test("a worn piece cannot be tempered; a tempered one is worn, unworn and sold like any other", function()
		local farm = rich()
		farm.gear = { ["sword-iron"] = 1 }
		farm.materials = { boar_tusk = 1 }
		local a = farm.slimes[1].id
		T.ok(Gear.equip(farm, a, "sword-iron"))
		T.eq(select(2, Gear.temper(farm, "sword-iron")), "NOT_IN_BAG", "it must be taken off first")
		T.ok(Gear.unequip(farm, a, "hand"))
		T.eq(Gear.temper(farm, "sword-iron"), "sword-iron-t")
		T.eq(Gear.equip(farm, a, "sword-iron-t"), "hand")
		T.same(Gear.bonus(farm.slimes[1]), { attack = 3, defence = 0, speed = 0, hp = 0 })
		T.eq(Gear.unequip(farm, a, "hand"), "sword-iron-t")
		T.eq(farm.gear["sword-iron-t"], 1)
	end)

	T.test("SmithyTemper is checked like SmithyCraft: its shape, and the Blacksmith's range", function()
		T.ok(VillageRequests.valid({ action = "SmithyTemper", gearId = "sword-iron" }, false))
		T.eq(VillageRequests.valid({ action = "SmithyTemper", gearId = 5 }, false), false)
		T.eq(VillageRequests.valid({ action = "SmithyTemper" }, false), false)
		T.eq(VillageRequests.valid({ action = "SmithyTemper", gearId = string.rep("x", 500) }, false), false)
		local farm = rich()
		farm.gear = { ["sword-iron"] = 1 }
		farm.materials = { boar_tusk = 1 }
		local function env(atSmithy: boolean): any
			return {
				isOut = function()
					return false
				end,
				atSmithy = function()
					return atSmithy
				end,
			}
		end
		local ok, why = VillageRequests.run(farm, { action = "SmithyTemper", gearId = "sword-iron" }, NOW, env(false))
		T.eq(ok, false)
		T.eq(why, "FAR")
		T.same(farm.gear, { ["sword-iron"] = 1 })
		ok = VillageRequests.run(farm, { action = "SmithyTemper", gearId = "sword-iron" }, NOW, env(true))
		T.ok(ok)
		T.same(farm.gear, { ["sword-iron-t"] = 1 })
	end)
end
