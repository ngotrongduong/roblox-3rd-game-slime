--!nocheck
-- How many full Dungeon runs a team needs to forge four weapons of one tier (the plan's gates, 2026-11-15: Uncommon in 4
-- runs or fewer, Epic 5, Mythic 7, Legendary 8). The four are a sword, a shield, a bow and a staff, which ask for all four
-- basics; each run the player picks the dungeon whose basic is shortest. Every run is won to wave 10, on the real
-- Dungeon.plan, rollDrops and commitWave (clear bonus included). Coins, packs and the guide's gift are left out.
--   lune run tools/balance/loot_sim.luau [trials]
local process = require("@lune/process")
local Config = require("../../src/shared/Config")
local Dungeon = require("../../src/shared/Dungeon")
local FarmKit = require("../../tests/lib/FarmKit")

local D = Config.Dungeon
local S = Config.Smithy
local NOW = 1_000_000
local TRIALS = tonumber(process.args[1]) or 200
local FAMILIES = { "sword", "shield", "bow", "staff" }
-- tier, the dungeon level a player farms it at (docs/SMITHY.md's stages), the plan's gate in runs
local TIERS = {
	{ "iron", 10, 4 },
	{ "core", 35, 5 },
	{ "bramble", 70, 7 },
	{ "legend", 110, 8 },
}

local basicOf = {}
for _, mapId in { "meadow", "mushroom", "lava", "ice" } do
	basicOf[mapId] = (D.Maps :: any)[mapId].basic
end

-- One won run: every wave's drops paid into `farm`.
local function run(farm: any, mapId: string, level: number, seed: number)
	local ledger = Dungeon.newLedger()
	for wave = 1, D.Waves do
		for _, monster in Dungeon.plan(mapId, level, wave, seed) do
			local def = Dungeon.defOf(mapId, monster.defId)
			for _, drop in Dungeon.rollDrops(def, level, monster.id .. ":" .. seed, seed, mapId) do
				Dungeon.addDrop(ledger, wave, drop)
			end
		end
		Dungeon.commitWave(farm, ledger, wave, NOW)
	end
end

local function needOf(tier: string): { [string]: number }
	local need = {}
	for _, family in FAMILIES do
		for item, amount in (S.Recipes :: any)[family .. "-" .. tier].materials do
			need[item] = (need[item] or 0) + amount
		end
	end
	return need
end

print("[GooLineage] runs to forge a sword, shield, bow and staff of one tier, " .. TRIALS .. " players each")
local ok = true
for _, row in TIERS do
	local tier, level, gate = row[1], row[2], row[3]
	local need = needOf(tier)
	local counts = {}
	for trial = 1, TRIALS do
		local farm: any = FarmKit.farm(NOW)
		farm.materials = {}
		local runs = 0
		while true do
			local short, best = nil, 0
			local done = true
			for item, amount in need do
				local gap = amount - (farm.materials[item] or 0)
				if gap > 0 then
					done = false
				end
			end
			if done or runs >= 50 then
				break
			end
			for mapId, basic in basicOf do
				local gap = (need[basic] or 0) - (farm.materials[basic] or 0)
				if gap > best or short == nil then
					short, best = mapId, gap
				end
			end
			runs += 1
			run(farm, short, level, trial * 1000 + runs)
		end
		table.insert(counts, runs)
	end
	table.sort(counts)
	local median, p90 = counts[math.ceil(TRIALS / 2)], counts[math.ceil(TRIALS * 0.9)]
	local pass = median <= gate
	ok = ok and pass
	print(
		string.format(
			"[GooLineage] %-8s level %3d: median %d runs, 9 in 10 within %d, gate %d %s",
			tier,
			level,
			median,
			p90,
			gate,
			if pass then "ok" else "OVER"
		)
	)
end
print(if ok then "[GooLineage] LOOT GATES OK" else "[GooLineage] LOOT GATES OVER")
