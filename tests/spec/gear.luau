--!strict
-- Gear and the Smithy (docs/SMITHY.md): the recipes and the pieces, crafting that takes its price once or not at all,
-- equipping and unequipping that only move pieces, the stat bonus, a sold slime handing its gear back, the schema-10 save
-- and the three requests.
local Config = require("../../src/shared/Config")
local FarmKit = require("../lib/FarmKit")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local Gear = require("../../src/shared/Gear")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Shop = require("../../src/shared/Shop")
local Stats = require("../../src/shared/Stats")
local VillageRequests = require("../../src/shared/VillageRequests")
local Zombies = require("../../src/shared/Zombies")

local S = Config.Smithy
local NOW = 1_000_000

-- A farm that holds plenty of everything.
local function rich(): any
	local farm = FarmKit.farm(NOW)
	farm.coins = 10_000
	for id in Config.Dungeon.Materials do
		farm.materials[id] = 100
	end
	return farm
end

-- How many of a piece exist on the farm: in the bag and on every slime.
local function total(farm: any, gearId: string): number
	local count = farm.gear[gearId] or 0
	for _, slime in farm.slimes do
		for _, slot in S.Slots do
			if slime.gear[slot] == gearId then
				count += 1
			end
		end
	end
	return count
end

local function allTotals(farm: any): { [string]: number }
	local out = {}
	for _, id in S.GearOrder do
		out[id] = total(farm, id)
	end
	return out
end

local function request(atSmithy: boolean?): any
	return {
		isOut = function()
			return false
		end,
		atSmithy = function()
			return atSmithy ~= false
		end,
	}
end

return function(T: any)
	T.test("every piece has a slot, a tier and stats; every recipe makes a piece that exists", function()
		-- (24 weapons, 4 helms, 4 charms, 6 Legendary weapons)
		T.eq(#S.GearOrder, 38)
		local recipes = 0
		for _ in S.Recipes do
			recipes += 1
		end
		T.eq(recipes, 38)
		for _, id in S.GearOrder do
			local piece = S.Gear[id]
			T.ok(piece ~= nil, id .. " is defined")
			T.ok(table.find(S.Slots, piece.slot) ~= nil, id .. " has a real slot")
			T.ok(S.Tiers[piece.tier] ~= nil, id .. " has a real tier")
			T.ok(table.find(S.TierOrder, piece.tier) ~= nil)
			for key, points in piece.stats do
				T.ok(table.find(Stats.Keys, key) ~= nil, id .. " adds a real stat: " .. key)
				T.ok(points > 0 and points % 1 == 0, id .. " adds whole points")
			end
			local recipe = S.Recipes[id]
			T.ok(recipe ~= nil, id .. " has a recipe")
			T.eq(recipe.gear, id)
		end
		for recipeId, recipe in S.Recipes do
			T.ok(S.Gear[recipe.gear] ~= nil, recipeId .. " makes a piece that exists")
			T.ok(recipe.coins >= 0)
			for item, need in recipe.materials do
				T.ok(Config.Dungeon.Materials[item] ~= nil, recipeId .. " asks for a known drop: " .. item)
				T.ok(need >= 1 and need % 1 == 0)
				T.ok(item ~= "cloth" and item ~= "common_part", "no recipe needs what no longer drops")
			end
		end
		-- the design's numbers, spot-checked
		T.same(S.Recipes["sword-iron"].materials, { ore = 4, wood = 2 })
		T.eq(S.Recipes["sword-iron"].coins, 25)
		T.same(
			S.Recipes["helm-bramble"].materials,
			{ boar_tusk = 4, rare_part = 12, monster_core = 2, boss_essence = 1 }
		)
		T.eq(S.Recipes["charm-bramble"].coins, 400)
		T.same(S.Gear["sword-core"].stats, { attack = 4, speed = 1 })
		T.eq(S.Tiers.core.rarity, "Epic")
		T.eq(S.Tiers.bramble.colour, "#f08a24")
	end)

	T.test("a craft that fails takes nothing", function()
		local farm = FarmKit.farm(NOW)
		farm.coins = 100
		farm.materials = { wood = 5, ore = 3, monster_core = 1 }
		local before = FarmState.repair(farm, NOW)
		T.eq(select(2, Gear.canCraft(farm, "no-such-recipe")), "RECIPE_NOT_FOUND")
		T.eq(select(2, Gear.canCraft(farm, nil)), "RECIPE_NOT_FOUND")
		T.eq(select(2, Gear.canCraft(farm, "sword-iron")), "INSUFFICIENT_MATERIALS")
		farm.materials.ore = 4
		farm.coins = 24
		T.eq(select(2, Gear.canCraft(farm, "sword-iron")), "INSUFFICIENT_COINS")
		for _, id in { "no-such-recipe", "sword-iron", "sword-core" } do
			local copy = FarmState.repair(farm, NOW)
			local made, why = Gear.craft(farm, id)
			T.eq(made, nil)
			T.ok(why ~= nil)
			T.same(farm.materials, copy.materials, id .. " took no material")
			T.eq(farm.coins, copy.coins, id .. " took no coins")
			T.same(farm.gear, {}, id .. " made nothing")
		end
		T.eq(before.coins, 100)
	end)

	T.test("a craft takes its materials and coins exactly once and adds one piece to the bag", function()
		local farm = FarmKit.farm(NOW)
		farm.coins = 60
		farm.materials = { ore = 9, wood = 5 }
		T.ok(Gear.canCraft(farm, "sword-iron"))
		T.eq(Gear.craft(farm, "sword-iron"), "sword-iron")
		T.same(farm.materials, { ore = 5, wood = 3 })
		T.eq(farm.coins, 35)
		T.same(farm.gear, { ["sword-iron"] = 1 })
		T.eq(Gear.craft(farm, "sword-iron"), "sword-iron")
		T.same(farm.materials, { ore = 1, wood = 1 })
		T.eq(farm.coins, 10)
		T.eq(farm.gear["sword-iron"], 2)
		T.eq(select(2, Gear.craft(farm, "sword-iron")), "INSUFFICIENT_MATERIALS")
		T.eq(farm.gear["sword-iron"], 2, "a refused third craft adds nothing")
		-- a free recipe costs no coins; a spent material is gone from the table, not left at zero
		farm.materials = { wood = 3 }
		farm.coins = 0
		T.eq(Gear.craft(farm, "sword-wood"), "sword-wood")
		T.same(farm.materials, {})
		T.eq(farm.coins, 0)
	end)

	T.test("equip and unequip move pieces and never change how many of each there are", function()
		local farm = rich()
		-- Crafting every piece needs more drops and coins than the original twelve-piece fixture.
		for _, recipe in S.Recipes do
			for material, amount in recipe.materials do
				farm.materials[material] = (farm.materials[material] or 0) + amount
			end
			farm.coins += recipe.coins
		end
		for _, id in S.GearOrder do
			T.ok(Gear.craft(farm, id))
		end
		local before = allTotals(farm)
		local a, b = farm.slimes[1].id, farm.slimes[2].id
		T.eq(Gear.equip(farm, a, "sword-wood"), "hand")
		T.eq(farm.slimes[1].gear.hand, "sword-wood")
		T.eq(farm.gear["sword-wood"], nil, "the only one left the bag")
		T.same(allTotals(farm), before)
		-- the slot held a piece: it goes back to the bag
		T.eq(Gear.equip(farm, a, "sword-iron"), "hand")
		T.eq(farm.slimes[1].gear.hand, "sword-iron")
		T.eq(farm.gear["sword-wood"], 1)
		T.eq(farm.gear["sword-iron"], nil)
		T.same(allTotals(farm), before)
		-- the other slots and another slime
		T.eq(Gear.equip(farm, a, "helm-core"), "head")
		T.eq(Gear.equip(farm, a, "charm-bramble"), "tail")
		T.eq(Gear.equip(farm, b, "sword-wood"), "hand")
		T.same(allTotals(farm), before)
		T.eq(Gear.unequip(farm, a, "head"), "helm-core")
		T.eq(farm.slimes[1].gear.head, nil)
		T.eq(farm.gear["helm-core"], 1)
		T.same(allTotals(farm), before)
		-- refusals change nothing
		T.eq(select(2, Gear.equip(farm, "nobody", "sword-wood")), "MISSING_SLIME")
		T.eq(select(2, Gear.equip(farm, a, "no-such-gear")), "GEAR_NOT_FOUND")
		T.eq(select(2, Gear.equip(farm, a, "sword-wood")), "NOT_IN_BAG")
		T.eq(select(2, Gear.unequip(farm, a, "head")), "EMPTY_SLOT")
		T.eq(select(2, Gear.unequip(farm, a, "back")), "INVALID_SLOT")
		T.eq(select(2, Gear.unequip(farm, "nobody", "hand")), "MISSING_SLIME")
		T.eq(select(2, Gear.equip(farm, 5, "sword-wood")), "MISSING_SLIME")
		T.same(allTotals(farm), before)
	end)

	T.test("the bonus is the sum of what the slime wears, and a bare slime gets nothing", function()
		local farm = rich()
		local slime = farm.slimes[1]
		T.same(Gear.bonus(slime), { attack = 0, defence = 0, speed = 0, hp = 0 })
		slime.gear = nil
		T.same(Gear.bonus(slime), { attack = 0, defence = 0, speed = 0, hp = 0 }, "an old slime with no gear field")
		slime.gear = {}
		for _, id in { "sword-bramble", "helm-bramble", "charm-bramble" } do
			T.ok(Gear.craft(farm, id))
			T.ok(Gear.equip(farm, slime.id, id))
		end
		-- sword 5/0/1/20 + crown 2/4/0/40 + charm 0/2/3/30
		T.same(Gear.bonus(slime), { attack = 7, defence = 6, speed = 4, hp = 90 })
		T.ok(Gear.unequip(farm, slime.id, "hand"))
		T.same(Gear.bonus(slime), { attack = 2, defence = 6, speed = 3, hp = 70 })
		T.same(Gear.bonus(farm.slimes[2]), { attack = 0, defence = 0, speed = 0, hp = 0 })
	end)

	T.test("a fighter has its slime's stats plus its gear; the slime itself is unchanged", function()
		local farm = rich()
		local slime = farm.slimes[1]
		slime.stats = { attack = 10, defence = 5, speed = 3, hp = 40 }
		local bare = Zombies.fighter(slime, NOW, 1)
		T.ok(Gear.craft(farm, "sword-core"))
		T.ok(Gear.craft(farm, "helm-core"))
		T.ok(Gear.equip(farm, slime.id, "sword-core"))
		T.ok(Gear.equip(farm, slime.id, "helm-core"))
		local geared = Zombies.fighter(slime, NOW, 1)
		T.eq(geared.attack, bare.attack + 4)
		T.eq(geared.defence, bare.defence + 3)
		T.eq(geared.speed, bare.speed + 1)
		T.eq(geared.hp, bare.hp + 30)
		T.eq(geared.maxHp, bare.maxHp + 30)
		T.same(slime.stats, { attack = 10, defence = 5, speed = 3, hp = 40 }, "its own stats never change")
		local level = Stats.level(slime.stats)
		T.eq(Stats.level(slime.stats), level)
	end)

	T.test("a sold slime hands its gear back to the bag", function()
		local farm = rich()
		local a = farm.slimes[1].id
		T.ok(Gear.craft(farm, "sword-iron"))
		T.ok(Gear.craft(farm, "charm-iron"))
		T.ok(Gear.equip(farm, a, "sword-iron"))
		T.ok(Gear.equip(farm, a, "charm-iron"))
		local before = allTotals(farm)
		local paid = Shop.sell(farm, a, NOW)
		T.ok(paid ~= nil, "sold")
		T.eq(FarmState.findSlime(farm, a), nil)
		T.same(farm.gear, { ["sword-iron"] = 1, ["charm-iron"] = 1 })
		T.same(allTotals(farm), before)
		-- the same helper, by hand
		local b = farm.slimes[1]
		T.ok(Gear.equip(farm, b.id, "sword-iron"))
		Gear.returnAll(farm, b)
		T.same(b.gear, {})
		T.eq(farm.gear["sword-iron"], 1)
	end)

	T.test("a new farm has an empty bag and bare slimes", function()
		local farm = FarmState.newFarm(NOW)
		T.same(farm.gear, {})
		for _, slime in farm.slimes do
			T.same(slime.gear, {})
		end
	end)

	T.test(
		"repair keeps good gear and drops unknown ids, bad counts and a piece in the wrong slot back to the bag",
		function()
			local farm: any = FarmState.newFarm(NOW)
			farm.gear = {
				["sword-wood"] = 2,
				["helm-iron"] = 0,
				["charm-iron"] = -1,
				["sword-iron"] = 1.5,
				["not-gear"] = 3,
				["helm-wood"] = "many",
			}
			farm.slimes[1].gear = { hand = "sword-core", head = "sword-wood", tail = "mystery" }
			farm.slimes[2].gear = "junk"
			local fixed = FarmState.repair(farm, NOW)
			T.same(fixed.gear, { ["sword-wood"] = 3 }, "two in the bag and the sword that was worn in the head slot")
			T.same(fixed.slimes[1].gear, { hand = "sword-core" })
			T.same(fixed.slimes[2].gear, {})
			local again = FarmState.repair(fixed, NOW)
			T.same(again.gear, fixed.gear, "repairing a repaired farm changes nothing")
			T.same(again.slimes[1].gear, fixed.slimes[1].gear)
			local nothing: any = FarmState.newFarm(NOW)
			nothing.gear = "x"
			T.same(FarmState.repair(nothing, NOW).gear, {})
			-- a clean farm with gear keeps all of it
			local clean = FarmKit.farm(NOW)
			clean.gear = { ["helm-bramble"] = 2 }
			clean.slimes[1].gear = { tail = "charm-core" }
			local kept = FarmState.repair(clean, NOW)
			T.same(kept.gear, { ["helm-bramble"] = 2 })
			T.same(kept.slimes[1].gear, { tail = "charm-core" })
		end
	)

	T.test("a schema 9 save migrates to 10 with an empty bag and bare slimes, keeping everything else", function()
		T.ok(Config.Save.SchemaVersion >= 10)
		local old: any = FarmState.newFarm(NOW)
		old.gear = nil
		for _, slime in old.slimes do
			slime.gear = nil
		end
		old.coins = 4242
		old.materials = { ore = 7, cloth = 3 }
		local load =
			ProfileLogic.prepareLoad({ schemaVersion = 9, savedAt = NOW, data = old }, FarmSave.hooks(), NOW + 1)
		T.ok(load.ok and load.migrated)
		T.eq(load.fromVersion, 9)
		T.eq(load.data.coins, 4242)
		T.same(load.data.materials, { ore = 7, cloth = 3 }, "what players already hold stays")
		T.same(load.data.gear, {})
		for _, slime in load.data.slimes do
			T.same(slime.gear, {})
		end
		T.eq(old.gear, nil, "migration never alters the stored snapshot")
		T.eq(old.slimes[1].gear, nil)
		-- from much earlier it goes through every step
		local older: any = FarmState.newFarm(NOW)
		older.dungeon = nil
		older.gear = nil
		local far =
			ProfileLogic.prepareLoad({ schemaVersion = 8, savedAt = NOW, data = older }, FarmSave.hooks(), NOW + 1)
		T.ok(far.ok)
		T.same(far.data.gear, {})
		T.same(far.data.dungeon, { best = 0 })
	end)

	T.test("the three requests: shapes are checked, and each runs on the farm", function()
		T.ok(VillageRequests.valid({ action = "SmithyCraft", recipeId = "sword-wood" }, false))
		T.eq(VillageRequests.valid({ action = "SmithyCraft", recipeId = 5 }, false), false)
		T.eq(VillageRequests.valid({ action = "SmithyCraft" }, false), false)
		T.eq(VillageRequests.valid({ action = "SmithyCraft", recipeId = string.rep("x", 500) }, false), false)
		T.ok(VillageRequests.valid({ action = "GearEquip", slimeId = "slime-1", gearId = "sword-wood" }, false))
		T.eq(VillageRequests.valid({ action = "GearEquip", slimeId = "slime-1" }, false), false)
		T.eq(VillageRequests.valid({ action = "GearEquip", slimeId = {}, gearId = "sword-wood" }, false), false)
		T.ok(VillageRequests.valid({ action = "GearUnequip", slimeId = "slime-1", slot = "hand" }, false))
		T.eq(VillageRequests.valid({ action = "GearUnequip", slimeId = "slime-1", slot = 3 }, false), false)

		local farm = FarmKit.farm(NOW)
		farm.coins = 0
		farm.materials = { wood = 3 }
		local a = farm.slimes[1].id
		local ok, why = VillageRequests.run(farm, { action = "SmithyCraft", recipeId = "sword-iron" }, NOW, request())
		T.eq(ok, false)
		T.eq(why, "INSUFFICIENT_MATERIALS")
		-- away from the Blacksmith nothing is made or taken
		ok, why = VillageRequests.run(farm, { action = "SmithyCraft", recipeId = "sword-wood" }, NOW, request(false))
		T.eq(ok, false)
		T.eq(why, "FAR")
		T.same(farm.materials, { wood = 3 })
		T.same(farm.gear, {})
		ok = VillageRequests.run(farm, { action = "SmithyCraft", recipeId = "sword-wood" }, NOW, request())
		T.ok(ok)
		T.eq(farm.gear["sword-wood"], 1)
		ok = VillageRequests.run(farm, { action = "GearEquip", slimeId = a, gearId = "sword-wood" }, NOW, request())
		T.ok(ok)
		T.eq(farm.slimes[1].gear.hand, "sword-wood")
		ok = VillageRequests.run(farm, { action = "GearUnequip", slimeId = a, slot = "hand" }, NOW, request())
		T.ok(ok)
		T.eq(farm.gear["sword-wood"], 1)
		-- a slime that is out keeps what it set out with
		local away = {
			isOut = function()
				return true
			end,
			atSmithy = function()
				return true
			end,
		}
		ok, why = VillageRequests.run(farm, { action = "GearEquip", slimeId = a, gearId = "sword-wood" }, NOW, away)
		T.eq(ok, false)
		T.eq(why, "OUT")
		T.eq(farm.gear["sword-wood"], 1)
		ok, why = VillageRequests.run(farm, { action = "GearUnequip", slimeId = a, slot = "hand" }, NOW, request())
		T.eq(ok, false)
		T.eq(why, "EMPTY_SLOT")
	end)
end
