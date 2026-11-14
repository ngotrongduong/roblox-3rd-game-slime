--!strict
-- The fights of the big world's zones: every zone of the plan has its numbers, its waves are sound, its guard pays the
-- zone's reward (never a boss's own trophies), a win rests the zone and opens the gate behind a boss, and the schema-15
-- save keeps the wins.
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local FarmSave = require("../../src/shared/FarmSave")
local FarmState = require("../../src/shared/FarmState")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local VillageRequests = require("../../src/shared/VillageRequests")
local WorldPlan = require("../../src/shared/WorldPlan")
local ZoneFights = require("../../src/shared/ZoneFights")

local W = Config.World
local NOW = 1_000_000

return function(T: any)
	T.test("every zone of the plan has numbers, and every numbered zone is in the plan", function()
		local count = 0
		for _, place in WorldPlan.Zones do
			count += 1
			T.ok((W.Zones :: any)[place.id], "numbers for " .. place.id)
			T.ok((W.Rest :: any)[place.kind], "a rest for kind " .. place.kind)
			T.ok((W.Reward :: any)[place.kind], "a reward for kind " .. place.kind)
		end
		for id in W.Zones :: { [string]: any } do
			count -= 1
			T.ok(ZoneFights.zone(id), id .. " is a zone of the plan")
		end
		T.eq(count, 0)
		T.eq(ZoneFights.zone("nowhere"), nil)
		T.eq(ZoneFights.zone(7), nil)
	end)

	T.test("a zone's waves rise, its crowds are no Dungeon boss wave, and its last wave is one guard", function()
		for id, numbers in W.Zones :: { [string]: any } do
			T.ok((Config.Dungeon.Maps :: any)[numbers.map], id .. " has a map")
			local last = 0
			for index, entry in numbers.waves do
				T.ok(entry.wave > last, id .. " wave numbers rise")
				last = entry.wave
				local plan = ZoneFights.plan(id, index, 77)
				if entry.guard then
					T.eq(#plan, 1, id .. " guard stands alone")
					T.eq(plan[1].defId, entry.guard)
				else
					T.eq(Dungeon.waveKind(entry.wave), "normal", id .. " crowd wave")
					T.ok(#plan >= 1, id .. " crowd is not empty")
				end
				for _, monster in plan do
					T.ok(Dungeon.defOf(numbers.map, monster.defId), "def of " .. monster.defId)
				end
			end
			T.ok(numbers.waves[#numbers.waves].guard, id .. " ends with its guard")
			T.eq(ZoneFights.waveKind(id, #numbers.waves), "boss")
			-- (a zone shows the level of the packs round it, and so does every monster of its fight)
			local level = ZoneFights.level(id)
			T.ok(level >= W.Packs.LevelMin and level <= W.Packs.LevelMax, id .. " shows a pack's level")
			for index in numbers.waves do
				for _, monster in ZoneFights.plan(id, index, 77) do
					T.eq(monster.level, level, id .. " monsters show the zone's level")
				end
			end
			for _, need in numbers.needs or {} do
				T.ok((W.Zones :: any)[need], id .. " needs a real zone")
			end
		end
		T.eq(ZoneFights.level("heart"), W.Packs.LevelMax)
		T.eq(ZoneFights.waveKind("m1", 1), "normal")
		T.eq(ZoneFights.waveKind("b1", 2), "miniboss")
	end)

	T.test("the same seed makes the same wave; a guard's power multiplies its health and attack", function()
		T.same(ZoneFights.plan("b1", 1, 5), ZoneFights.plan("b1", 1, 5))
		local def = Dungeon.defOf("meadow", "green_snail")
		local plain = Dungeon.monster(def, 2, 3, "x")
		local strong = Dungeon.monster(def, 2, 3, "x", 4)
		T.near(strong.hp, plain.hp * 4, 1e-6)
		T.near(strong.attack, plain.attack * 4, 1e-6)
		T.eq(strong.defence, plain.defence)
		T.ok(strong.level > plain.level)
	end)

	T.test("the guard pays the zone's reward, never its own drops; the crowd pays its own", function()
		local boar = Dungeon.defOf("meadow", "green_boar")
		-- (the Meadow's boss always drops its trophy in the Dungeon; a mini zone never does)
		for _, line in ZoneFights.dropDef("m1", 2, boar).drops do
			T.ok(line.item ~= "boar_tusk", "no trophy from a mini zone")
			T.ok((Config.Dungeon.Materials :: any)[line.item], line.item .. " is a material")
		end
		T.eq(ZoneFights.dropDef("m1", 1, boar), boar)
		-- a boss zone pays its region's trophy; the Heart's region has none
		local trophy = false
		for _, line in ZoneFights.reward("b2") do
			trophy = trophy or line.item == "ember_core"
			T.ok(line.item ~= "trophy")
		end
		T.ok(trophy, "the Molten Throne pays Ember Cores")
		for _, line in ZoneFights.reward("heart") do
			T.ok((Config.Dungeon.Materials :: any)[line.item], line.item .. " is a material")
		end
		-- coins grow with the tier
		local function coins(id: string): number
			for _, line in ZoneFights.reward(id) do
				if line.item == "coins" then
					return line.min
				end
			end
			return 0
		end
		T.eq(coins("m1"), W.Reward.mini[1].min)
		T.ok(coins("m10") > coins("m1"))
		-- the list a screen shows: every def has drop lines, the last is the guard's reward, and no boss's own trophy in a
		-- mini zone
		for id in W.Zones :: { [string]: any } do
			local defs = ZoneFights.dropDefs(id)
			T.same(defs[#defs].drops, ZoneFights.reward(id))
			for _, def in defs do
				T.ok(type(def.drops) == "table", id .. " drop lines")
			end
		end
		for _, def in ZoneFights.dropDefs("m1") do
			for _, line in def.drops do
				T.ok(line.item ~= "boar_tusk", "no trophy listed for a mini zone")
			end
		end
	end)

	T.test("a won zone rests, then may be fought again; the Heart needs the three bosses", function()
		local farm = FarmState.newFarm(NOW)
		T.eq(ZoneFights.block(farm.world.beaten, "m1", NOW), nil)
		T.eq(ZoneFights.block(farm.world.beaten, "nowhere", NOW), "ZONE_UNKNOWN")
		ZoneFights.recordClear(farm, "m1", NOW)
		T.eq(ZoneFights.block(farm.world.beaten, "m1", NOW + 1), "ZONE_RESTING")
		T.eq(ZoneFights.restLeft("m1", farm.world.beaten.m1, NOW + 100), W.Rest.mini - 100)
		T.eq(ZoneFights.block(farm.world.beaten, "m1", NOW + W.Rest.mini), nil)
		T.eq(ZoneFights.restLeft("m1", nil, NOW), 0)

		T.eq(ZoneFights.block(farm.world.beaten, "heart", NOW), "ZONE_LOCKED")
		ZoneFights.recordClear(farm, "b1", NOW)
		ZoneFights.recordClear(farm, "b2", NOW)
		T.eq(ZoneFights.block(farm.world.beaten, "heart", NOW), "ZONE_LOCKED")
		T.eq(ZoneFights.gateOpen(farm.world.beaten, "gate_w"), true)
		T.eq(ZoneFights.gateOpen(farm.world.beaten, "gate_n"), false)
		T.eq(ZoneFights.gateOpen(farm.world.beaten, "no_gate"), false)
		ZoneFights.recordClear(farm, "b3", NOW)
		T.eq(ZoneFights.block(farm.world.beaten, "heart", NOW), nil)
	end)

	T.test("every gate of the Heart has its boss zone", function()
		for gate, zone in W.Gates :: { [string]: string } do
			local site = WorldPlan.find(gate)
			T.ok(site and site.kind == "gate", gate .. " is a gate of the plan")
			local _, place = ZoneFights.zone(zone)
			T.eq(place.kind, "boss")
		end
	end)

	T.test("a zone is entered by its id; an unknown zone is refused", function()
		T.eq(VillageRequests.valid({ action = "DungeonEnter", zone = "m1", teams = { 1 } }, true), true)
		T.eq(VillageRequests.valid({ action = "DungeonEnter", zone = "m1", teams = { 1 } }, false), false)
		T.eq(VillageRequests.valid({ action = "DungeonEnter", zone = "nowhere", teams = { 1 } }, true), false)
		T.eq(VillageRequests.valid({ action = "DungeonEnter", zone = 3, level = 1, teams = { 1 } }, true), false)
		T.eq(VillageRequests.valid({ action = "DungeonEnter", level = 1, teams = { 1 } }, true), true)
	end)

	T.test("a schema-14 save gains an empty list of wins; repair keeps real wins and drops the rest", function()
		local farm = FarmState.newFarm(NOW)
		local stored: any = FarmState.repair(farm, NOW)
		stored.world = nil
		local result =
			ProfileLogic.prepareLoad({ schemaVersion = 14, savedAt = 0, data = stored }, FarmSave.hooks(), NOW)
		T.ok(result.ok)
		T.ok(result.migrated)
		T.same(result.data.world, { beaten = {} })

		local dirty: any = FarmState.newFarm(NOW)
		dirty.world = { beaten = { m1 = NOW, nowhere = NOW, b1 = -4, m2 = "yesterday", b2 = 1.5 } }
		T.same(FarmState.repair(dirty, NOW).world, { beaten = { m1 = NOW } })
		dirty.world = "gone"
		T.same(FarmState.repair(dirty, NOW).world, { beaten = {} })
	end)
end
