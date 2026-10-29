# Brief "village-polish-1": fixes from the first play test of the living village

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
Repository `ngotrongduong/roblox-3rd-game-slime`, base `main` (latest commit af7a7aa). Work on a NEW branch
`chatgpt/village-polish-1` from the latest `main`; never commit to `main`, no pull request. Read `CLAUDE.md`,
`docs/GAMEPLAY.md`, and the village code: `src/shared/Brain.luau`, `src/server/Village.luau`, `src/server/Spots.luau`,
`src/server/VillageRemotes.luau`, `src/client/Village.client.luau`, `src/client/VillageUI.luau`, `src/shared/Config.luau`.

## What the play test showed (Studio, one player, 4 starters)
The village runs: slimes choose actions and walk their legs. Problems to fix:

1. **The Manage sheets do not know the village's state**: the server does not replicate work slots, reserves,
   training stats, breeding pairs, needs, levels or cooked-food permission, so the UI keeps a session-only memory
   and shows "?". Fix: the server publishes them (per slime Configuration: `Fullness`, `Energy`, `Fun`, `Level`,
   `Attack`, `Defence`, `Speed`, `Hp`, `Baby` (bool), `WorkArea`, `WorkSlot`, `Reserve` (bool), `PairIndex`,
   `CookedAllowed` (bool); on the village folder: `Work` (JSON of every area's slots: worker, reserve, stat,
   progress fraction), `Pairs` (JSON: a, b, courtingUntil), `Areas` (JSON of levels), `Box` (JSON of each box)),
   updated only when they change. `VillageUI` reads these and drops its session memory; the sheets refresh live.
2. **Two slimes run the same errand** (both carried fish to the kitchen for one dish). Fix: the brain reserves an
   errand target (a box batch, the counter's missing ingredients, an egg) for one slime until it arrives or gives up;
   others score it 0 meanwhile. Keep the reservation in the server session (runtime), passed to `Brain.choose` in
   `ctx`. Test in `tests/spec/brain.luau`.
3. **Slimes stand inside each other and inside the player**: the "player" action ends exactly on the player's
   position, and slimes at one spot overlap. Fix: actions toward a moving target (player, partner, baby) stop
   `Config.Brain.StopStuds` (4) short on the line toward it; slimes sharing a spot get a small ring offset by order
   (`Config.Brain.SpotSpread`), so they stand side by side; partners chatting face each other.
4. **Many spots fall back** to area centres: storehouse, fridge, box:garden, box:kitchen, nap, fountain, campfire,
   plaza, gate. Fix in `Spots.luau`: also find them from the existing models when no marker exists: the pantry
   building's door side (the `PantryL1` model's front, toward the plaza), the kitchen's counter and a fridge spot
   beside it, the garden's gate side for its box, the campfire (the model or part named like "Campfire" / "Fire" in
   the front-right cell) and its seats (`Bench`, `Stump`, `Log` models near it) as nap spots, the plaza's well
   (`Well`, `StoneWell`, `Fountain`) as the fountain, the gate (`Gate` in the plot's front). Log which ones were found.
   The orchestrator adds real markers later; keep the names in `Config.Village.SpotNames`.

## Gates
`tools/check.ps1` → `CHECK OK`, `tools/types.ps1` → `TYPES OK` (strict). You cannot run them: be careful (no unused
variables or imports; attribute reads are `any`, check them; typed table fields added later go in the type).
Do not touch `tools/`, `assets/`, `art/`, `docs/`.

## Report (your last chat message)
Branch, commits, what changed per file, what you decided yourself.
