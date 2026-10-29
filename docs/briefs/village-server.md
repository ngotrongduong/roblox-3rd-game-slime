# Brief "village-server": the village on the server and the slime brain

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
If something is unclear, pick the simplest thing that fits the code around it and write it in your report.

Repository `ngotrongduong/roblox-3rd-game-slime`, base `main`. Work on a NEW branch `chatgpt/village-server` from
the latest `main`; never commit to `main`, no pull request.

## Read first
- `CLAUDE.md` (rules: the server decides everything, clients draw and ask; every remote handler checks who asks,
  what they own and how often; numbers only in `Config.luau`; every print starts with `[GooLineage]`; smooth on cheap
  phones).
- `docs/GAMEPLAY.md` (the whole spec; §5, §7, §9 matter most here).
- The rules already on main (commit "Village rules (ChatGPT job, checked) ..."): `src/shared/VillageSim.luau`,
  `Needs`, `Food`, `Stations`, `Training`, `Village`, `Breeding` (pairs, nests, incubators), `Hatching`, `FarmState`
  (the schema-4 farm), `Config` (blocks Needs, Food, Work, Village, Breeding).
- Server: `src/server/Main.server.luau`, `PlayerData.luau` (`onReady`, `onLeaving`, `get`, `update`,
  `markKeyMoment` — the only way to change a player's data), `AreaUpgrade.server.luau` (today free, unsaved upgrades
  of Plot 5 with the E key), `Layout.luau` (`plotFrame`, `plotAreaFacing(plot, col, row)`, `plotGate`).
- Client API the brain feeds later: `src/client/SlimeActor.luau` and `src/shared/Expressions.luau` (the 24 emotion
  names you may send).

## The world today
The plots are built only in the work place: `workspace.Map.Plot5` (areas `FishingPondL1` (col -1,row 1),
`PantryL1` (0,1), `GardenL1` (1,1), `KitchenL1` (-1,0), `BreedingL1` (1,0), `TrainingL1` (-1,-1), the plaza in the
middle (0,0), the gate at the front (0,-1), a campfire in the front-right cell (1,-1)). Markers: `WorkSpot1..4`
(BaseParts or Attachments) in the pond, kitchen, training and garden models; `Nest1..n` and `Incubator1..n` in the
breeding area. So: one player owns Plot 5 for now (`Config.Village.DevPlot = 5`; a later job hands out plots 1-8).
When `workspace.Map` or the plot is missing, the village still runs (rules, saves, remotes) and logs one line.

## What to build

### 1. `src/shared/Brain.luau` (pure, tested in Lune)
The slime brain's choice, Sims style: `Brain.choose(farm, slimeId, ctx, now, rng) -> Action`. `ctx` holds plain data
only (spot ids and positions as `{ x, y, z }`, which slimes are near, the player's position or nil).
`Action = { kind, spot (id), seconds, emotion, carry = { item, count }?, partner (slime id)? }`.
- A slime that is working (worker or active reserve) goes to its area's work spot and works there ("work").
- A courting pair goes into the breeding house ("court", emotion "loved").
- Otherwise each candidate action gets a score: need urgency (fullness ≤ 50 → eat at the storehouse, or the fridge
  if allowed; energy ≤ 20 → sleep at a nap spot, until rested), village needs (a box with items → carry up to
  `Config.Brain.CarryAmount` to the storehouse; the counter wants ingredients → storehouse to kitchen; a nest egg and
  a free incubator → carry the egg; a hungry baby → bring food; babies → play with or walk a baby round the plaza),
  fun and social (chat with a friend nearby, play tag, greet, argue and make up — friendship +`Config.Brain`
  amounts), daily life (watch the fish, smell flowers, splash at the fountain, warm up at the campfire, wander), and
  the player nearby (look, hop closer, cheer). Weights per trait in `Config.Brain.TraitWeights`; a little random
  noise so slimes differ. Every action names an emotion from `Expressions`.
- `Brain.arrive(farm, slimeId, action, now) -> (farm, ok)`: the effect when the slime gets there, using the shared
  rules (`Food.take/add/eat`, `Breeding.placeInIncubator`, friendship, sleeping on/off). It re-checks everything at
  arrival (the box may be empty by then): a stale action does nothing.
- Babies stay in the nursery spot area unless an adult is walking them.
- Tests `tests/spec/brain.luau`: a hungry slime chooses to eat; a tired one sleeps; an idle slime with a full box
  carries; carrying moves items and never creates or loses any; an egg errand starts incubation; an allowed slime eats
  a dish, a not-allowed one never does; a stale arrival is a no-op; trait weights change the choice (seeded).

### 2. `VillageSim` change
With `opts.errands = false` the sim must NOT eat and must NOT start sleeping (the brain walks slimes to food and beds
and calls `Brain.arrive`); it still ticks needs (a `sleeping` slime recovers), work, cooking, courtship timers,
laying, incubation, hatching, growth and ghosts. Update its tests.

### 3. `src/server/Village.luau` (+ started from `Main.server.luau`)
- On `PlayerData.onReady`: catch up offline (`VillageSim.catchUp`, 8 h cap), give the player the dev plot, make the
  replicated folder, start the slimes.
- A loop (`Config.Village.TickSeconds`, 1 s) per player: `VillageSim.step(..., { errands = false })` through
  `PlayerData.update`; `markKeyMoment` for laid, hatched, upgraded. Brain decisions run when a slime's action ends,
  spread so at most `Config.Brain.ThinksPerTick` slimes a player think each tick.
- Movement: route = current position → its area's entrance → the plaza → the target area's entrance → the target
  spot (skip what is not needed); time = length / walk speed from SPD (`GAMEPLAY.md` §3). The server never moves
  parts: it publishes each leg (from, to, start time, end time) and the client hops along it. Positions are runtime
  only, never saved.
- `src/server/Spots.luau`: finds the spots in the plot (markers above; storehouse door, kitchen counter and fridge,
  nursery, nap spots: campfire seats and plaza benches, fountain, flower beds, pond edge) by names listed in
  `Config.Village.SpotNames`, with a fallback position from `Layout.plotAreaFacing` for each area so nothing breaks
  when a marker is missing; logs which spots were found and which fell back.
- Replication (what the client draws; never the embryo of an egg): `workspace.Villages.<UserId>` Folder with
  attributes for the HUD (coins, storehouse, fridge, population, limit, village level); `Slimes` with one
  `Configuration` per slime, attributes: Look (assetId), Colour, Material, DualId, SecretId, Scale (baby growth),
  Name, Trait, Action, Emotion, Carry, FromX/Y/Z, ToX/Y/Z, LegStart, LegEnd (server time), Ghost, Sleeping, Working
  area. `Eggs` with one `Configuration` per egg: Place, Slot, HatchAt. Update attributes only when they change.
- Leaving: stop the loop, destroy the folder (the profile is saved by `PlayerData`).

### 4. Remotes `src/server/VillageRemotes.luau`
One `RemoteFunction` `ReplicatedStorage.Remotes.Village` (create the folder if missing). Requests `{ action, ... }`:
`SetPair(index, a, b)`, `Assign(area, slot, slimeId, asReserve)`, `Unassign(slimeId)`, `SetTrainingStat(slot,
stat)`, `SetCookedAllowed(slimeId, allowed)`, `UpgradeArea(areaId)`. Each: the player's profile is ready, argument
types and ranges checked, the slime is theirs, at most `Config.Village.RequestsPerSecond` a player; the change goes
through the shared rules inside `PlayerData.update`; reply `{ ok, reason? }`. `UpgradeArea` pays coins
(`Village.upgrade`) and fires a `BindableEvent` `ServerStorage.VillageEvents.AreaLevelChanged(player, areaId,
level)`.

### 5. `AreaUpgrade.server.luau`
Its E prompts now call the same upgrade path (coins, saved levels, only the plot's owner); on join and on
`AreaLevelChanged` it builds the saved level's stage. Keep its visuals as they are. Debug: when
`Config.Village.DevFreeUpgrades` is true (default false) the cost is 0 — studio only.

## Tests and gates
New Lune specs for `Brain` and the `VillageSim` change; server code has no Lune tests but must pass strict types
(`tools/types.ps1` → `TYPES OK`) and `tools/check.ps1` → `CHECK OK` (stylua, selene, lune, rojo). You cannot run
them: be careful.

## Lessons from earlier jobs
- No unused variables, imports or parameters (selene); `_` prefix for intentionally unused ones.
- Typed table fields added later go in the type, `newFarm` and `repair`.
- No require cycles (Brain may require Food, Breeding, Needs, Stations, Config; not VillageSim).
- Tests never use `os.time()`; server code uses `workspace:GetServerTimeNow()` for times sent to clients and
  `os.time()` for saved times.
- Forgetting to start a new service from `Main.server.luau` is a common slip.
- Do not touch `src/client`, `tools/`, `assets/`, `art/`, `docs/`.

## Report (your last chat message)
Branch, commits, what each file does, what you decided yourself, anything not done.
