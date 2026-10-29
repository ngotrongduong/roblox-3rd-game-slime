# Brief "village-client": drawing the living village and the player's controls

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
If something is unclear, pick the simplest thing that fits the code around it and write it in your report.

Repository `ngotrongduong/roblox-3rd-game-slime`, base `main`. Work on a NEW branch `chatgpt/village-client` from
the latest `main`; never commit to `main`, no pull request.

## Read first
- `CLAUDE.md` (every word in the game is English; HUD buttons hug the screen edges, the middle stays empty, no names
  over heads, billboards in Offset pixels; a reward or a cost is its picture and a short number; smooth on cheap
  phones; client draws and asks, never decides). `docs/UI.md` (simplest possible screen; every interaction is done on
  the objects in the world). `docs/GAMEPLAY.md` (the spec).
- The server side on main (commit fa5e20a "Village server ..."): `src/server/Village.luau` (what it replicates under
  `workspace.Villages.<UserId>`: HUD attributes on the folder, `Slimes/<id>` and `Eggs/<id>` Configurations and their
  attributes, legs as From/To + LegStart/LegEnd in `workspace:GetServerTimeNow()` time), `src/server/VillageRemotes.luau`
  (the `ReplicatedStorage.Remotes.Village` RemoteFunction and its requests), `src/server/Spots.luau`,
  `src/shared/Config.luau` (Village, Brain, Work, Food blocks), `src/shared/Expressions.luau`.
- The slime drawing that exists: `src/client/SlimeActor.luau` (`Actor.new(model, emotion)`, `:setEmotion`,
  `:lookAt`, `:playMotion`, `:hop`, distance budget), `src/client/SlimeFace.luau`, `src/shared/SlimeMotion.luau`;
  how a slime model is dressed: `tools/slime/showcase.luau` (single colours: white map tinted with the `Colours`
  swatch, glossy SurfaceAppearance, outline hull at x0.6; Duals: skin image untinted) and
  `tools/slime/materials.luau` (the 18 materials, `docs/MATERIALS.md`); `tools/slime/emotions_client.luau` (a client
  that drives SlimeActor). Dual skin image ids: `art/models/slime_body/skins/asset_ids.json`.

## Assets the client finds (the orchestrator puts them in the place)
`ReplicatedStorage.ClientKit`: `SlimeBody` and `SlimeBodyOutline` (the rigged MeshParts, pivot at the feet after
resetting `PivotOffset` as showcase does), `Items/<item>` models for fish, carrot, cabbage, grilledFish, veggieStew,
fishVegSoup and `Egg`. When a model is missing, draw a small neutral stand-in and log ONE line naming it (the
orchestrator makes the art); never ship a stand-in silently.

## What to build (all in `src/client`, plus pure helpers in `src/shared` with Lune tests)

1. `src/shared/SkinIds.luau`: the 55 Dual skin ids from the JSON, keyed by the Dual definition id in
   `DualDesigns.luau` (match by number `NN`), with a Lune test that all 55 designs have an id.
2. `src/client/SlimeLook.luau`: `build(attrs) -> Model` from a slime's Look attributes: plain colour (swatch tint),
   Dual (its skin), Material (its look by `docs/MATERIALS.md`), Secret (no 3D art yet: its first colour, plus one
   log line "missing Secret art <id>"), scale (baby growth). Shared SurfaceAppearances are cached per look, so 200
   slimes do not make 200 copies.
3. `src/client/Village.client.luau`: for every `workspace.Villages.*` folder (the player's own and neighbours'),
   one SlimeActor per slime:
   - Moves along the current leg by small hops (position from `LegStart/LegEnd`, one hop about every
     `Config.Brain.HopSeconds`, faces where it goes, lands softly), stands still at the end.
   - Emotion from the `Emotion` attribute; looks at its chat partner or the player when the action says so.
   - Action motions: work at each area (fishing: still with small bobs facing the water; garden: hop between crop
     spots; kitchen: busy wobble at the counter; training: punches = quick lunges), carry (the item model rides on the
     head), sleep (sleep face, slow breathing, a small "Zz" billboard icon), eat (a few chews), chat (icon bubble:
     heart, note, star, angry; no text), court (hearts), tag (quick hops), walk a baby (baby follows behind).
   - Ghosts: see-through and pale, float softly at the gate.
   - Eggs at their nest or incubator marker, the plain egg look; a wobble just before `HatchAt`.
   - Created and removed as Configurations come and go; nothing animates far away (SlimeActor's budget).
4. `src/client/VillageUI.luau` (+ started from `Main.client.luau`): only on the player's OWN plot.
   - A ProximityPrompt "Manage" (key F, so the upgrade prompt keeps E) at each area's entrance opens a bottom sheet
     anchored to that area: work slots (worker and reserve faces, tap a slot → a slime picker that lists free adults
     with their portrait, level and a fullness and energy icon; Remove), training: the stat per slot (4 icons),
     kitchen: "Cooked food" toggles per slime, breeding: the 2 pair places (tap → pick two slimes; Clear), with
     the reason from the server shown as a short toast when a request fails.
   - A small HUD strip at the top edge: coins, fish, carrot, cabbage, dishes, slimes n / limit (icon + number).
   - Mobile first: touch targets ≥ 48 px, one sheet at a time, closes on walking away. Style: the owner's
     cream / brown parchment colours (`docs/reference/03-shell-ui-world.md`), rounded, icons over words. Icons: use
     emoji-free image ids from `Config.Ui.Icons` (add the table with 0 placeholders and log the missing ones once; the
     orchestrator orders the art).
5. Remove nothing the existing client scripts do.

## Gates
`tools/check.ps1` → `CHECK OK` and `tools/types.ps1` → `TYPES OK` (you cannot run them; be careful with strict types:
attribute reads are `any`, cast them). The orchestrator play-tests in Studio.

## Lessons from earlier jobs
- No unused variables, imports or parameters (selene); `_` prefix for intentionally unused ones.
- Do not call `RunService` heavy work per slime per frame outside SlimeActor's loop; batch.
- `Instance:GetAttribute` returns `any`: check the type before use.
- Forgetting to start a new module from `Main.client.luau` is a common slip.
- Do not touch `src/server`, `tools/`, `assets/`, `art/`, `docs/`.

## Report (your last chat message)
Branch, commits, what each file does, every stand-in or missing icon, what you decided yourself.
