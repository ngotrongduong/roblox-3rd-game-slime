# Brief "village-work": fishing and gardening as real work, the breeding program, SPD work speed, two fixes

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
Repository `ngotrongduong/roblox-3rd-game-slime`, base `main`. Work on a NEW branch `chatgpt/village-work` from the latest
`main`; never commit to `main`, no pull request.

Read first: `CLAUDE.md`, `docs/GAMEPLAY.md` (§10, the owner's notes: Fishing, Garden, Breeding program, SPD), and the
code: `src/server/Village.luau` (actors, routes, pathfinding, carrying), `src/server/Spots.luau`,
`src/server/PondStages.luau` (fishing places `WorkSpot1..4` open with the slots; the rod stands), `src/server/GardenStages.luau`
(garden places `WorkSpot1..4`; `CropPlot1..20` markers with a `Bed` attribute; the stage layer's `CropPlots` count),
`src/server/WorkProps.luau` (the `FishBin` / `VegBin` bins, `ItemBin` tag), `src/client/Bins.client.luau`,
`src/client/Village.client.luau`, `src/client/SlimeActor.luau` (`attach` / `detach`, hops), `src/shared/VillageSim.luau`,
`src/shared/Stations.luau`, `src/shared/Brain.luau`, `src/shared/Breeding.luau`, `src/shared/FarmState.luau`,
`src/shared/Config.luau`, `src/client/VillageUI.luau` (the Manage sheets: only the breeding sheet changes here).
Tools and models in `ReplicatedStorage.ClientKit.Items`: `FishingRod`, `Hoe`, `WateringCan`, `fish`, `carrot`,
`cabbage`, the crop stage models `Carrot1..4` / `Cabbage1..4` (kit `CropKit`, in the work place's `ServerStorage.CropKit`;
add them to `ClientKit.Items` through `tools/kit/export_client_kit.luau` if the client needs them).

## The owner's words (2026-10-29)
"Make animations for the jobs. On the fishing dock put a rod at each fishing place. Next to the pond, outside, a bin:
when a fisher catches a fish it drops it into that bin, which holds 10. Gardening needs a set of animations: watering,
caring, harvesting. When watering it holds the watering can over its head and waters the vegetables. When the soil has
no vegetables it takes the hoe and hoes the soil; we have the growth stages of the vegetables, use them. When a
vegetable is big enough it pulls it out and carries it to the bin outside the garden, which holds 10 vegetables of any
kind. The garden has 4 places round the 2 garden beds. At breeding, F shows the slime list to put slimes into the
breeding program: 4 slimes at the start, 8 at the top level with 4 nests. Slimes rest after breeding. SPD affects the
work speed." (The places, rods, bins and markers are already built.)

## Build
1. **Fishing cycle** (server decides, client shows): the fisher walks to its place, faces the water, casts (rod swing),
   waits (bobber, a small bob now and then), reels in on a bite, a fish model appears, then it carries the fish on its
   head to the `FishBin` and drops it in (the box count +1, the bin shows it), then walks back. A full bin (10) → it waits
   at the bin, worried, until a hauler or the player empties it. Publish the phase on the slime (`WorkPhase`: walk,
   cast, wait, reel, carry, drop) with its start/end times so the client plays the right motion; the rod is the place's
   own rod stand (the slime takes the rod: `FishingRod` attached in front while fishing, back on the stand when it leaves).
2. **Garden cycle** with real plots: save each `CropPlot` (`farm.work.garden.plots = { { crop, stage, progress, watered } }`,
   schema 5 + migration; plots count from the stage layer, 20 at level 1). A plot goes empty → hoed → planted (carrot or
   cabbage) → growing through the 4 stage models → ripe. The gardener chooses the most useful nearby plot: hoe an empty
   one (`Hoe` held, chopping motion), plant a hoed one (a quick dab), water a dry growing one (`WateringCan` held OVER ITS
   HEAD, tilted, a few drops; watering moves the plot's growth on, dry plots grow slowly), pull a ripe one (tug-tug-pop,
   the vegetable comes up) and carry it on its head to the `VegBin`, drop it in. The server swaps the plot's crop model to
   its stage (grow it smoothly from the last stage's size, as the owner asked earlier) — models replicate from the server
   so every player sees the same garden. Tune times in `Config.Work.Garden*` so one gardener at level 1 gives about the
   same vegetables per hour as today's `GardenYield / cycle`. Offline catch-up advances plots in the abstract sim.
3. **SPD sets work speed**: every work time (fishing wait, garden actions, kitchen, training) × `1 / (1 + min((SPD − 1) ×
   Config.Work.SpeedBonusPerSpd, Config.Work.SpeedBonusMax))` (0.05 and 3, the original's numbers), with a Lune test.
4. **Breeding program**: pair places = nests: 2 at the start, +1 at level 21, +1 at level 41 → 4 (and the same for
   incubators), so the program holds 4 slimes at the start and 8 at the top. The breeding Manage sheet (F) lists the
   program's places and opens the slime list to fill them (keep the UI kit look and the Suggested slime of
   `VillageUI.luau`). Slimes rest after laying (already so) and do not work while in the program.
5. **Fixes from the last play test**: (a) the storehouse and counter spots taken from building models end inside the
   building, so every path to them fails ("village path failed: plaza > storehouse"); snap every model-derived spot to
   the nearest walkable point outside its model, in front of its door, and keep pathfinding on; (b) a slime whose "player"
   action starts already close still stands inside the player: always stop `StopStuds` short of the player, even with an
   empty route, and keep re-checking while the player moves.

## Tests and gates
Lune tests: the garden plot cycle (each step and its conditions, growth with and without water, offline), SPD work speed,
breeding places by level, the save migration v4→v5. `tools/check.ps1` → `CHECK OK`, `tools/types.ps1` → `TYPES OK`
(strict). You cannot run them: be careful (no unused variables, imports or parameters; attribute reads are `any`;
typed fields added later go in the type, `newFarm` and `repair`).

## Report (your last chat message)
Branch, commits, what changed per file, numbers you chose, what the orchestrator must check in Studio.
