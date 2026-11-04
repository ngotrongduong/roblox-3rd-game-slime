--!strict
-- The owner's debug presets (Studio only): every stage and every single action leaves a farm FarmState.repair passes
-- unchanged, the Mid and Late stages meet the Dungeon's entry rule, a timer jump finishes every timer, and nothing throws.
local Config = require("../../src/shared/Config")
local DebugPresets = require("../../src/shared/DebugPresets")
local Dungeon = require("../../src/shared/Dungeon")
local FarmKit = require("../lib/FarmKit")
local FarmState = require("../../src/shared/FarmState")
local Genetics = require("../../src/shared/Genetics")
local Growth = require("../../src/shared/Growth")
local Guide = require("../../src/shared/Guide")
local Mutations = require("../../src/shared/Mutations")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Stations = require("../../src/shared/Stations")
local Stats = require("../../src/shared/Stats")

local NOW = 1_700_000_000

-- The farm FarmState.repair makes of this one: it must be this one, with nothing to repair.
local function assertValid(farm: any, what: string)
	-- a nap is session state the save does not keep (repair drops it), so it is not compared
	local want = ProfileLogic.deepCopy(farm)
	for _, slime in want.slimes do
		slime.sleeping = nil
	end
	local copy = ProfileLogic.deepCopy(want)
	local repaired, warnings, replaced = FarmState.repair(copy, NOW)
	assert(not replaced, what .. ": the farm was thrown away")
	assert(#warnings == 0, what .. ": repair warned: " .. table.concat(warnings, "; "))
	local T = require("../lib/T")
	local ok, err = pcall(function()
		T.same(repaired, want)
	end)
	assert(ok, what .. ": repair changed the farm: " .. tostring(err))
end

local function isBaby(farm: any, slime: any): boolean
	return Growth.isBaby(
		slime.createdAt,
		NOW,
		Stats.level(slime.stats),
		farm.areas.breeding.level - Config.Village.StartLevel
	)
end

-- A farm that has a bit of everything the timers touch.
local function busyFarm(): any
	local farm = FarmKit.farm(NOW, FarmKit.many(8))
	for _, slime in farm.slimes do
		slime.createdAt = NOW - 100_000
	end
	-- s1 and s2 court, s3 fishes, s4 trains, s5 is a ghost, s6 sleeps and is tired, s7 is a baby
	farm.breeding.pairs[1] = { a = "s1", b = "s2", courtingUntil = NOW + 100 }
	assert(Stations.assign(farm, "s3", "fishing", 1, false, NOW))
	farm.work.fishing.slots[1].progress = 5
	assert(Stations.assign(farm, "s4", "training", 1, false, NOW))
	farm.slimes[5].ghostUntil = NOW + 500
	farm.slimes[6].needs = { fullness = 70, energy = 5, fun = 70 }
	farm.slimes[7].createdAt = NOW - 1
	farm.slimes[7].breedReadyAt = NOW
	farm.slimes[1].breedReadyAt = NOW + 400
	table.insert(farm.eggs, {
		id = "egg-1",
		parentIds = { "s1", "s2" },
		createdAt = NOW - 10,
		hatchAt = NOW + 500,
		place = "incubator",
		slot = 1,
		offspringId = "slime-baby-1",
		embryo = {
			stats = Stats.starter(),
			colourGenotype = Genetics.homozygous("navy"),
			appearanceMutation = Mutations.none(),
		},
		status = "incubating",
	})
	table.insert(farm.eggs, {
		id = "egg-2",
		parentIds = { "s1", "s2" },
		createdAt = NOW - 10,
		hatchAt = NOW + 900,
		place = "nest",
		slot = 1,
		offspringId = "slime-baby-2",
		embryo = {
			stats = Stats.starter(),
			colourGenotype = Genetics.homozygous("red"),
			appearanceMutation = Mutations.none(),
		},
		status = "nest",
	})
	assertValid(farm, "the busy farm itself")
	farm.slimes[6].sleeping = true
	return farm
end

-- Every "farm" item of the menu, as (id, args) pairs.
local function farmItems(): { { id: string, args: any } }
	local out = {}
	for _, group in DebugPresets.Menu do
		for _, item in group.items do
			if item.kind == "farm" then
				table.insert(out, { id = item.id, args = item.args })
			end
		end
	end
	return out
end

return function(T: any)
	T.test("a slime's stats make exactly the level asked, inside the stat limits", function()
		for level = 4, DebugPresets.Numbers.MaxLevel do
			local stats = DebugPresets.statsFor(level)
			T.eq(Stats.level(stats), level, "level " .. level)
			for _, key in Stats.Keys do
				local limit = (Config.Stats.Limits :: any)[key]
				T.ok(
					stats[key] >= limit.min and stats[key] <= limit.max,
					key .. " out of its limits at level " .. level
				)
			end
		end
		T.eq(Stats.level(DebugPresets.statsFor(1)), 4, "below the starter it is the starter")
		T.eq(Stats.level(DebugPresets.statsFor(100000)), DebugPresets.Numbers.MaxLevel, "above the top it is the top")
	end)

	T.test("each preset on a new farm gives a valid farm in the stage's numbers", function()
		local expect: { [string]: { level: number, slimes: number } } = {
			early = { level = 5, slimes = 8 },
			mid = { level = 16, slimes = 20 },
			late = { level = 40, slimes = 40 },
		}
		for name, want in expect do
			local farm = FarmState.newFarm(NOW)
			local ok, text = DebugPresets.preset(farm, name, NOW)
			T.ok(ok, name .. ": " .. text)
			assertValid(farm, name)
			T.eq(FarmState.villageLevel(farm.areas), want.level, name .. " village level")
			T.eq(#farm.slimes, want.slimes, name .. " slimes")
			for _, slime in farm.slimes do
				T.ok(not isBaby(farm, slime), name .. ": " .. slime.id .. " is a baby")
				T.ok(slime.needs.fullness == Config.Needs.Start and slime.needs.energy == Config.Needs.Start)
			end
			T.eq(farm.tutorialDone, true, name .. " tutorial")
			T.eq(farm.guide.step, "done", name .. " guide step")
			T.eq(Guide.view(farm, NOW), nil, name .. ": no tutorial or intro on screen")
			T.eq(#farm.eggs, 0)
			T.ok(#farm.slimes <= FarmState.populationLimit(farm.areas), name .. ": more slimes than the village holds")
		end
	end)

	T.test("a preset's new-player luck is over (the tutorial ended long ago)", function()
		local farm = FarmState.newFarm(NOW)
		DebugPresets.preset(farm, "mid", NOW)
		local Luck = require("../../src/shared/Luck")
		T.eq(Luck.multiplier(farm, NOW), 1)
	end)

	T.test("Mid and Late meet the Dungeon's entry rule, Early does not", function()
		for _, name in { "mid", "late" } do
			local farm = FarmState.newFarm(NOW)
			DebugPresets.preset(farm, name, NOW)
			T.eq(Dungeon.entryBlock(farm), nil, name)
			-- and a team is set for the squad
			T.ok(#farm.teams[1].members == Config.Zombies.TeamSize, name .. ": team 1 is not full")
		end
		local early = FarmState.newFarm(NOW)
		DebugPresets.preset(early, "early", NOW)
		T.ok(Dungeon.entryBlock(early) ~= nil)
	end)

	T.test("Mid has gear on its teams, enough coins and every material; Late has all of it, more", function()
		local mid = FarmState.newFarm(NOW)
		DebugPresets.preset(mid, "mid", NOW)
		T.eq(mid.coins, 50_000)
		for _, id in Config.Dungeon.DropOrder do
			local entry: any = (Config.Dungeon.Materials :: any)[id]
			if entry.kind == "material" then
				T.eq(mid.materials[id], 30, id)
			end
		end
		for _, id in mid.teams[1].members do
			local slime = FarmState.findSlime(mid, id) :: any
			for _, slot in Config.Smithy.Slots do
				local gear = Config.Smithy.Gear[slime.gear[slot]]
				T.ok(gear ~= nil and gear.tier == "iron", "a team member's " .. slot .. " is not iron")
			end
		end
		for _, id in Config.Smithy.GearOrder do
			T.eq(mid.gear[id], 1, "bag " .. id)
		end
		local late = FarmState.newFarm(NOW)
		DebugPresets.preset(late, "late", NOW)
		T.eq(late.dungeon.best, 5)
		T.eq(#late.teams[4].members, Config.Zombies.TeamSize, "all four teams open and full")
		T.ok(late.coins > mid.coins and late.materials.wood > mid.materials.wood)
	end)

	T.test("every action of the menu on a new farm gives a valid farm", function()
		for _, item in farmItems() do
			local farm = FarmState.newFarm(NOW)
			local ok, text = DebugPresets.run(farm, item.id, NOW, item.args)
			T.ok(ok, item.id .. ": " .. text)
			T.ok(text ~= "")
			assertValid(farm, item.id)
		end
	end)

	T.test("every action of the menu on a busy farm and on a late farm gives a valid farm", function()
		for _, item in farmItems() do
			local busy = busyFarm()
			local ok, text = DebugPresets.run(busy, item.id, NOW, item.args)
			T.ok(ok, "busy " .. item.id .. ": " .. text)
			assertValid(busy, "busy " .. item.id)
			local late = FarmState.newFarm(NOW)
			DebugPresets.preset(late, "late", NOW)
			local ok2, text2 = DebugPresets.run(late, item.id, NOW, item.args)
			T.ok(ok2, "late " .. item.id .. ": " .. text2)
			assertValid(late, "late " .. item.id)
		end
	end)

	T.test("a lower stage over a higher one cuts the slots, pairs and stocks to fit", function()
		local farm = FarmState.newFarm(NOW)
		DebugPresets.preset(farm, "late", NOW)
		assertValid(farm, "late")
		DebugPresets.preset(farm, "early", NOW)
		assertValid(farm, "early after late")
		T.eq(#farm.slimes, 8)
		T.eq(#farm.work.fishing.slots, FarmState.slotCount(5))
		T.eq(#farm.breeding.pairs, FarmState.breedingCount(5))
		DebugPresets.preset(farm, "late", NOW)
		T.eq(#farm.work.fishing.slots, FarmState.slotCount(40))
		T.eq(#farm.breeding.pairs, FarmState.breedingCount(40))
	end)

	T.test("a preset takes the worn gear back and leaves no piece lost", function()
		local farm = FarmState.newFarm(NOW)
		DebugPresets.preset(farm, "mid", NOW)
		DebugPresets.preset(farm, "early", NOW)
		assertValid(farm, "early after mid")
		T.eq(next(farm.gear), nil, "early has no gear and the old slimes' gear is not left anywhere")
		for _, slime in farm.slimes do
			T.eq(next(slime.gear :: any), nil)
		end
	end)

	T.test("coins are added without a ceiling, materials and the gear set add to what is held", function()
		local farm = FarmState.newFarm(NOW)
		farm.coins = 5
		DebugPresets.run(farm, "coins_small", NOW, nil)
		T.eq(farm.coins, 5 + DebugPresets.Numbers.CoinsSmall)
		DebugPresets.run(farm, "coins_big", NOW, nil)
		T.eq(farm.coins, 5 + DebugPresets.Numbers.CoinsSmall + DebugPresets.Numbers.CoinsBig)
		farm.materials.wood = 7
		DebugPresets.run(farm, "materials", NOW, nil)
		T.eq(farm.materials.wood, 7 + DebugPresets.Numbers.MaterialsEach)
		T.eq(farm.materials.boar_tusk, DebugPresets.Numbers.MaterialsEach)
		DebugPresets.run(farm, "gear", NOW, nil)
		DebugPresets.run(farm, "gear", NOW, nil)
		for _, id in Config.Smithy.GearOrder do
			T.eq(farm.gear[id], 2)
		end
	end)

	T.test("finishing the timers finishes them all", function()
		local farm = busyFarm()
		local ok, text = DebugPresets.finishTimers(farm, NOW)
		T.ok(ok and text ~= "")
		assertValid(farm, "after the timers")
		for _, egg in farm.eggs do
			T.eq(egg.status, "ready", egg.id)
			T.ok(egg.hatchAt <= NOW)
		end
		for _, slime in farm.slimes do
			T.ok(not isBaby(farm, slime), slime.id .. " is still a baby")
			T.ok(slime.breedReadyAt <= NOW, slime.id .. " still rests")
			T.eq(slime.ghostUntil, nil, slime.id)
			T.eq(slime.sleeping, nil, slime.id)
		end
		T.eq(farm.breeding.pairs[1].courtingUntil, NOW)
		T.ok(farm.work.fishing.slots[1].progress >= Stations.cycleSeconds("fishing", farm.areas.fishing.level))
		T.ok(farm.work.training.slots[1].progress >= Stations.cycleSeconds("training", farm.areas.training.level))
		T.ok(farm.slimes[6].needs.energy >= Config.Needs.Rested, "the napper is rested")
		-- the revived ghost is whole again
		T.eq(farm.slimes[5].needs.fullness, Config.Needs.Start)
	end)

	T.test("finishing the timers of a new farm only grows the starter slimes up", function()
		local farm = FarmState.newFarm(NOW)
		local before = ProfileLogic.deepCopy(farm)
		DebugPresets.finishTimers(farm, NOW)
		assertValid(farm, "new farm after the timers")
		for index, slime in farm.slimes do
			T.ok(slime.createdAt <= before.slimes[index].createdAt)
			slime.createdAt = before.slimes[index].createdAt
		end
		T.same(farm, before)
	end)

	T.test("fill needs wakes and feeds everybody", function()
		local farm = busyFarm()
		DebugPresets.run(farm, "needs", NOW, nil)
		for _, slime in farm.slimes do
			T.eq(slime.needs.fullness, Config.Needs.Start)
			T.eq(slime.needs.energy, Config.Needs.Start)
			T.eq(slime.sleeping, nil)
		end
		assertValid(farm, "needs")
	end)

	T.test("slimes are added grown, of the level asked, in plain colours, and bad numbers add nothing", function()
		local farm = FarmState.newFarm(NOW)
		local before = #farm.slimes
		local ok = DebugPresets.run(farm, "slimes", NOW, { count = 12, level = 25 })
		T.ok(ok)
		T.eq(#farm.slimes, before + 12)
		local colours: { [string]: boolean } = {}
		for index = before + 1, #farm.slimes do
			local slime = farm.slimes[index]
			T.eq(Stats.level(slime.stats), 25)
			T.ok(not isBaby(farm, slime))
			T.eq(slime.appearanceMutation.type, "none")
			colours[slime.visibleColour] = true
		end
		T.ok(next(colours) ~= nil and (function(): number
			local n = 0
			for _ in colours do
				n += 1
			end
			return n
		end)() >= 11, "twelve slimes go through all eleven colours")
		assertValid(farm, "twelve slimes")
		local snapshot = ProfileLogic.deepCopy(farm)
		for _, bad in
			{ { count = 0, level = 5 }, { count = 61, level = 5 }, { count = "5", level = 5 }, { count = 5 }, {} }
		do
			local done = DebugPresets.run(farm, "slimes", NOW, bad)
			T.eq(done, false)
		end
		T.eq((DebugPresets.run(farm, "slimes", NOW, nil)), false)
		T.same(farm, snapshot)
		-- the slime ids are all different, though two taps come in the same second
		DebugPresets.run(farm, "slimes", NOW, { count = 3, level = 9 })
		local seen: { [string]: boolean } = {}
		for _, slime in farm.slimes do
			T.ok(not seen[slime.id], "duplicate id " .. slime.id)
			seen[slime.id] = true
		end
	end)

	T.test(
		"a Dual and a Secret slime are made by the game's own recipes, each tap a design that is not shown yet",
		function()
			local farm = FarmState.newFarm(NOW)
			for _, kind in { "dual", "secret" } do
				local seen: { [string]: boolean } = {}
				for _ = 1, 4 do
					local ok, text = DebugPresets.run(farm, kind, NOW, nil)
					T.ok(ok, text)
					local slime = farm.slimes[#farm.slimes]
					local design = slime.appearanceMutation
					T.eq(design.type, kind)
					T.ok(Mutations.isKnown(design), "an unknown design")
					T.ok(not seen[design.definitionId :: string], "the same design twice")
					seen[design.definitionId :: string] = true
					-- the pair of colours it comes from can really make it (the breeding pools)
					local colours = Genetics.baseColours(slime)
					local pool = if kind == "dual" then Genetics.dualPool(colours) else Genetics.secretPool(colours)
					local found = false
					for _, row in pool do
						found = found or row.id == design.definitionId
					end
					T.ok(found, design.definitionId :: string .. " is not in its pair's pool")
					T.eq(slime.assetId, Mutations.assetId(design, slime.visibleColour))
					T.ok(farm.discoveries[kind][design.definitionId :: string] ~= nil, "in the Index")
				end
			end
			assertValid(farm, "rare slimes")
			T.eq(DebugPresets.run(farm, "bogus", NOW, nil), false)
			T.eq(DebugPresets.addRare(farm, NOW, "material"), false)
		end
	)

	T.test("skipping the tutorial ends it and starts the luck; resetting starts it over", function()
		local farm = FarmState.newFarm(NOW)
		T.eq(farm.guide.step, Config.Guide.Steps[1])
		DebugPresets.run(farm, "guide_skip", NOW, nil)
		T.eq(farm.tutorialDone, true)
		T.eq(farm.guide.step, "done")
		T.eq(farm.tutorialDoneAt, NOW)
		assertValid(farm, "skipped")
		DebugPresets.run(farm, "guide_reset", NOW, nil)
		T.eq(farm.tutorialDone, false)
		T.eq(farm.tutorialDoneAt, nil)
		T.eq(farm.guide.step, Config.Guide.Steps[1])
		assertValid(farm, "reset")
		-- a preset ends it again, with no luck window
		DebugPresets.run(farm, "early", NOW, nil)
		T.eq(farm.guide.step, "done")
		assertValid(farm, "early after a reset")
	end)

	T.test("every item of the menu has an id and a text, and a farm item has a handler", function()
		local kinds = { farm = true, undo = true, fresh = true, travel = true }
		local count = 0
		for _, group in DebugPresets.Menu do
			T.ok(group.group ~= "")
			for _, item in group.items do
				count += 1
				T.ok(item.id ~= "" and item.text ~= "" and kinds[item.kind], item.id)
			end
		end
		T.ok(count >= 18)
	end)
end
