-- Times, outside Roblox, the work the server does for every player every second: the village tick
-- (VillageSim.step, which copies the whole farm) on a fresh farm and on the debug Late farm (village 40,
-- 40 slimes of level 80), plus the farm's copy and its JSON size (what a save writes). Lune's VM is not
-- Roblox's (no native code generation), so the numbers are an upper bound to compare runs with, not a
-- server's real cost. Re-run after a change to the tick and compare (docs/audit/OPTIMIZATION_RESULTS.md).
--   lune run tools/perf/server_bench.luau
local serde = require("@lune/serde")
local DebugPresets = require("../../src/shared/DebugPresets")
local FarmKit = require("../../tests/lib/FarmKit")
local ProfileLogic = require("../../src/shared/ProfileLogic")
local Rng = require("../../src/shared/Rng")
local VillageSim = require("../../src/shared/VillageSim")

local NOW = 1_700_000_000
local ROUNDS = 200

local function time(what: string, rounds: number, fn: (number) -> ())
	fn(0) -- (warm up)
	local start = os.clock()
	for i = 1, rounds do
		fn(i)
	end
	local each = (os.clock() - start) / rounds
	print(string.format("%-44s %8.3f ms", what, each * 1000))
end

local function bench(name: string, farm: any)
	print(string.format("== %s: %d slimes, %d eggs", name, #farm.slimes, #(farm.eggs or {})))
	local rng = Rng.new(1)
	local state = farm
	time("village tick (VillageSim.step, 1 s)", ROUNDS, function(i: number)
		local nextFarm = VillageSim.step(state, NOW + i, 1, rng, { errands = false, workReady = {}, courtReady = {} })
		state = nextFarm
	end)
	time("copy of the farm (ProfileLogic.deepCopy)", ROUNDS, function()
		ProfileLogic.deepCopy(state)
	end)
	local text = serde.encode("json", state)
	time(string.format("JSON of the farm (%d bytes)", #text), ROUNDS, function()
		serde.encode("json", state)
	end)
end

bench("fresh farm", FarmKit.farm(NOW))
local late = FarmKit.farm(NOW)
DebugPresets.preset(late, "late", NOW)
bench("debug Late farm", late)
