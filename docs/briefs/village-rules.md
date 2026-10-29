# Brief "village-rules": the rules of the living village (shared logic + tests)

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
If something is unclear, pick the simplest thing that fits the code around it and write it in your report.

Repository: `ngotrongduong/roblox-3rd-game-slime`, base branch `main`. Work on a NEW branch `chatgpt/village-rules`
created from the latest `main`; never commit to `main`, no pull request. Commit in small steps with clear messages.

## Read first (all on main)
- `CLAUDE.md` — project rules. Luau, tabs, `--!strict`, comments that say WHY, every tunable number only in
  `src/shared/Config.luau` (one block an area), every print starts with `[GooLineage]`. Shared modules load with
  `if script then require(script.Parent.X) else require("./X")`; exported types cannot be read through that require,
  so a module uses `typeof(...)` for a sibling's type (see `Mutations.luau`).
- `docs/GAMEPLAY.md` §3-§8 — THE SPEC (needs, food chain, work areas, training, breeding with nests and pairs,
  ghosts). §1-§2 (colours, luck) are already built: commit "Inheritance: colour sets and pools ..." is the pattern to
  follow for style and tests.
- Code you change or reuse: `src/shared/FarmState.luau` (types, `newFarm`, field-by-field `repair`),
  `ProfileLogic.luau` (migrations; follow the v2→v3 one), `Breeding.luau` (`check`, `createEgg`, `inheritStats`,
  `cooldownSeconds`), `Hatching.luau`, `Growth.luau`, `Stats.luau`, `Luck.luau`, `Mutations.luau` (`sellValue`),
  `FarmSave.luau`, `Config.luau`.
- Tests: `tests/run.luau`, `tests/lib/T.luau`, `tests/lib/FarmKit.luau`, `tests/spec/*.luau` (follow their style; a
  spec file returns `function(T)`).

## What to build (all pure logic in `src/shared`, no Roblox services)

### Save shape (schema 4)
`Config.Save.SchemaVersion` = 4, migration v3→v4 in `ProfileLogic`, `FarmState` types + `newFarm` + `repair`:
- Slime: `needs = { fullness, energy, fun }` (0-100, replaces hunger / hungerState), `trait` (one of
  `Config.Village.Traits`: "hardworking", "lazy", "playful", "shy", "chatty", "glutton", picked from the slime's seed),
  `friends = { [slimeId]: number }` (0-100, at most `Config.Village.MaxFriends` = 8 kept, lowest dropped),
  `buff = { stat: string, percent: number, untilTime: number }?`, `ghostUntil: number?`. Remove `fallen` and
  `previousLoadout` (battle leftovers; the ghost replaces fallen).
- Farm: `areas = { fishing, garden, kitchen, pantry, training, breeding }`, each `{ level: number }` (1..50).
  `work = { fishing, garden, kitchen, training }`, each `{ slots: { WorkSlot }, box: { [item]: number } }` with
  `WorkSlot = { worker: string?, reserve: string?, progress: number, stat: string? }` (stat only for training).
  `storehouse = { [rawItem]: number }`, `counter = { [rawItem]: number }` (kitchen ingredients),
  `fridge = { [dishId]: number }`, `cookedAllowed = { string }` (slime ids allowed to eat dishes),
  `breeding = { pairs: { { a: string?, b: string?, courtingUntil: number? } } }`.
  Egg: `place` ("nest" or "incubator"), `slot` (nest or incubator number), `hatchAt: number?` (nil while in a nest).
- Remove: `food`, `workstations`, `unlockedStations`, `upgrades`, `nest` (the original's auto-nest; set pairs replace
  it). Grow-up and rest use the breeding area's level instead of the old upgrade levels.
- `newFarm`: 4 navy starters (adult, full needs), storehouse 10 fish + 10 carrot (`Config.Food.Start`), every area
  level 1, slots sized by level (1 each), 2 empty pair places, no eggs.
- Migration v3→v4: hunger → fullness (energy 100, fun 100), trait from seed, drop the removed fields (old
  `food.basicFood` becomes fish in the storehouse, capped), every area level 1, eggs → incubators 1..n keeping their
  `hatchAt` (extra eggs go to nests unincubated), `fallen` dropped.
- `repair` keeps every new field valid (unknown items dropped, counts clamped to capacity, slots resized to the
  area's level, a worker or reserve that no longer exists or is a baby or a ghost removed, a slime in two places kept
  in the first, pairs with missing slimes cleared).

### `Needs.luau`
Rates per minute in `Config.Needs` (§4 table): fullness falls 2 idle / 3 working or training; energy falls 2 working
or training / 0.5 idle, rises 5 sleeping; fun falls `FunFall`. `tick(needs, activity, seconds)` with activity "idle",
"work", "sleep"; `eatValue`; states: `wantsFood` (≤50), `canPair` (≥60 fullness and not tired), `isHungry` (≤25),
`workFactor` (0.5 hungry, else 1), `isTired` (≤20), `rested` (≥90). Babies' fullness falls at `BabyFactor` (0.5).

### `Food.luau`
Items and dishes from `Config.Food`: raw fish +20, carrot +15, cabbage +15; dishes grilledFish (2 fish, +60, attack
+10% for 1200 s), veggieStew (2 carrot + 1 cabbage, +65, defence +10%), fishVegSoup (1 fish + 1 carrot + 1 cabbage,
+90, hp +10%), cook time 120 s. Capacities by level: storehouse `100 + 20 × (pantryLevel − 1)`, fridge
`20 + 4 × (kitchenLevel − 1)`, counter 10, each box `Config.Work.BoxCapacity` (10). Functions: add / take with
capacity (never negative, never above capacity, return how many moved), `chooseMeal(farm, slimeId)` (allowed slimes:
the fridge dish with most fullness, else the storehouse; others: the storehouse item there is most of),
`eat(farm, slimeId, now)` (applies fullness, clamp 100, sets the dish's buff), `bestDish(counter)` (most fullness the
counter can make), `ingredientsWanted(farm)` (what the cook needs from the storehouse for the best dish possible from
counter + storehouse).

### `Stations.luau` (work areas)
Slots by level: 1, +1 at levels 11, 21, 31 (max 4), `Config.Work.SlotLevels`. `canAssign(farm, slimeId, areaId,
slotIndex, asReserve, now)` with reason codes: missing slime, baby, ghost, already working or reserve anywhere, in a
breeding pair, slot taken, no such slot. `assign`, `unassign`, `setTrainingStat`. Cycle seconds by area at level 1
(`Config.Work`: fishing 60 s → 1 fish; garden 240 s → 3 vegetables, carrot or cabbage 50/50; kitchen 120 s → 1
dish; training 90 s → 1 session), times `0.99 ^ (level − 1)`. `activeWorker(farm, slot, now)`: the worker, or the
reserve when the worker is tired, hungry or a ghost (and the reserve is not), else nil. Progress: seconds × the
active worker's `workFactor`; a full box pauses fishing and garden; the kitchen needs the dish's ingredients on the
counter (it takes them when a dish starts).

### `Training.luau`
`gainChance(statKey, value, trainingLevel, luck)` = `Base × Soft / (Soft + v − 1) × (1 + (level − 1) × ChancePerLevel)
× luck`, capped by `Config.Mutation.ChanceCap`; v = value, or hp / 10 for hp; Base 0.60, Soft 10, ChancePerLevel
1/49. `finishSession(stats, statKey, rng, chance)`: +1 (hp +10), clamped by `Stats.clamp`.

### `Village.luau`
Area ids `Village.Areas = { "fishing", "garden", "kitchen", "pantry", "training", "breeding" }`; village level =
floor(average of the six levels); population limit = `20 + 4 × (villageLevel − 1)` (eggs hold a place); upgrade cost
of the next level = `round10(100 × 200 ^ ((level − 1) / 48))` coins (100 at level 1 → 20,000 for level 49→50);
`upgrade(farm, areaId)` checks max 50 and coins, takes the coins, raises the level, resizes slots.

### Breeding flow (in `Breeding.luau`, keep `createEgg`'s genetics)
Counts by breeding level: nests, incubators and pair places each `2`, +1 at 11, 21, 31, 41 (`Config.Breeding`).
`setPair(farm, index, idA, idB)` (adults, different, not ghosts, not working or reserve, not in another pair; nil
ids clear the place). `pairReady(farm, index, now)`: both rested (`breedReadyAt`), `canPair`, not ghosts, a free nest,
room in the village. `startCourtship` sets `courtingUntil = now + CourtshipSeconds` (60). `layEgg(farm, index, now,
rng, newId)` after courtship: `createEgg` (stats, colours, pity, luck as now), the egg goes to the first free nest
with `place = "nest"`, no `hatchAt`; parents rest (existing cooldown, using the breeding level) and lose
`Config.Breeding.LayEnergy` (30) energy. `placeInIncubator(farm, eggId, now)`: a free incubator, sets
`hatchAt = now + incubationSeconds(babyLevel, breedingLevel)` = `round((60 + max(0, level − 4) × 1) × 0.98 ^
(breedingLevel − 1))`. `Hatching` hatches only incubator eggs whose `hatchAt` has passed (oldest first), as now
(idempotent), and frees the incubator.

### `VillageSim.luau`
One simulation for online and offline: `step(farm, now, seconds, rng, opts) -> (farm, events)`, pure (returns a new
farm), where `opts.errands` = true means "do every carry at once" (offline catch-up and tests), false means the server
brain carries things (then the sim only does needs, work progress into boxes, cooking from the counter, courtship
timers, incubation, hatching, growth, ghosts). `catchUp(farm, lastSimulatedAt, now, rng)` runs whole 60 s steps with
errands on, capped at 8 h (`Config.Village.OfflineCapSeconds`), then sets `lastSimulatedAt = now`. In errand mode,
per step: needs tick (working slimes "work", tired ones "sleep" until rested, others "idle"); slimes at ≤50 fullness
eat (`Food.eat`, one meal a step); work progress; boxes → storehouse; storehouse → counter for the best dish; dishes
→ fridge; nest eggs → free incubators; ready pairs court and lay; hatch ready eggs; ghosts with `ghostUntil ≤ now`
come back (fullness and energy 100). Events list what happened (food made, eaten, eggs laid, hatched) for the
"while you were away" summary.

## Tests (new specs; update old ones only when the old rule is gone; never loosen a test to make it pass)
- `needs.luau`: rates, thresholds, babies slower.
- `food.luau`: capacities, add/take never negative or above capacity, chooseMeal with and without permission, best
  dish, buff set on eating.
- `stations.luau`: slot counts at levels 1/10/11/21/31/50, assign rules and reasons, reserve takes over a tired or
  hungry worker, hungry worker at half speed, a full box pauses, kitchen waits for ingredients.
- `training.luau`: chance 0.60 at 1, ≈0.316 at 10, ≈0.207 at 20, ≈0.102 at 50, ≈0.0556 at 99 (level 1, luck 1);
  ×2 at level 50; hp uses hp/10; 100,000 seeded sessions match the chance ±0.5 pp.
- `village.luau`: village level, population limit, upgrade cost table (levels 1, 2, 25, 49), upgrade checks.
- `breeding_flow.luau`: pairs, readiness (each failing condition), courtship 60 s, egg in a nest without hatchAt,
  incubation only after placeInIncubator, incubation time by baby level and breeding level, nests full → wait.
- `village_sim.luau`: 4 starters with 1 fisher for 8 h offline never stay hungry long; a full storehouse stops the
  box emptying but never loses food; a whole pair → egg → incubator → hatch → grown-up cycle; ghosts revive;
  migration v3→v4 on a saved v3 farm.
- Tests use the seeded `Rng` and fixed times, never `os.time()`.

## Do not touch
`src/server`, `src/client`, `tools/`, `assets/`, `art/`, `docs/` (except nothing). Server code that still uses the
removed fields is fixed by the orchestrator afterwards; if `src/server/PlayerData.luau` or `FarmSave.luau` must change
to keep the build compiling, keep it minimal and say so.

## Gates (the orchestrator runs them on your branch; you cannot run commands, so be careful)
`tools/check.ps1` (stylua, selene, lune tests, rojo build) must end `CHECK OK`; `tools/types.ps1` (luau-lsp strict)
must end `TYPES OK`.

## Lessons from earlier jobs (avoid these slips)
- No unused variables, imports or parameters (selene fails); prefix an intentionally unused parameter with `_`.
- A typed table field added later must be in the type, in `newFarm` and in `repair`, or types fail.
- No require cycles between shared modules (Food must not require Breeding etc.; pass values in).
- Tests never use `os.time()`; fake clocks are plain numbers.
- Do not delete or rewrite code you were not asked to change; your branch must start from the latest `main`.

## Report (your last chat message)
Branch name and commits, what each new module does, what you decided yourself, anything not done.
