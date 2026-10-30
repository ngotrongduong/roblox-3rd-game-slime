# Lessons from building the living village (2026-10-29..30)

What the owner's play rounds taught us. Read before working on the village, its code or its map.

## Checking
- Lune tests and strict types passing proves little here: most bugs the owner found only exist in the running game.
  Nothing is "done" until it ran in a MapWork play test, and for looks until someone saw it at the game's camera.
- **When the screen looks wrong, read the console first** (`get_console_output`, or the Output panel). The "pairs stuck at
  the nest" report was really one error repeating every frame: `SlimeMotion:434` (a nil Gravity in the glide gait) stopped
  the shared render loop, so every slime froze on the client while the server played on. An hour went to theories first.
- **Compare client and server.** Read `Workspace.VillageClientActors.<id>.SlimeBody.Position` (a Model's `GetPivot` is stale:
  SlimeActor moves parts with BulkMoveTo) against the slime's Configuration `ToX/ToZ`, `Action`, `LegEnd`. A body far from
  its leg near the camera means the client is broken, not the path.
- Slimes far from the camera do not animate by design: stand the character near what you measure.
- `execute_luau` runs in a separate module context: `require(PlayerData)` gives a copy that is never ready, so needs or saves
  cannot be changed by script in a play test (a dev hook would be needed). Read only published attributes.
- `screen_capture` comes back white when the Studio window is covered. Say so and rely on numbers.
- Client play-test saves are in memory: stopping a play test loses that village.
- If the owner asks to look on his machine, computer use with Roblox Studio works; `zoom` reads the LAST screenshot, so take a
  fresh one first.

## Robustness
- One shared loop (SlimeActor's render step) must never die from one slime's error: wrap per-slime work in `pcall`, warn once.
- A table of per-mode numbers with missing fields (the glide gait has no hop numbers) must fall back field-safely. State can
  change mid-animation: a slime can turn tired in mid-air.
- A condition that silently does nothing is a bug report waiting: training with no stat chosen stood idle forever. Give a
  sensible default, and publish WHY something waits (`Pairs[n].waiting`, shown on the breeding sheet).
- Reservations and shared targets: two pairs sent to one "breeding" spot jam it. Anything several slimes use needs a spot per user
  (pair k at nest k) or spreading.
- Scores by trait can silently exclude jobs (lazy and playful never hauled): urgent errands get a flat bonus.

## World and space
- Slime standard: about 3.5 studs wide, 3 tall (`Config.Map.SlimeWidth/Height`). Design every clearance from it
  (`docs/VILLAGE_SCALE.md`). Tight areas caused the "stuck" reports.
- The owner keeps paths at **6 studs**; models keep their size when an area grows; only spacing changes.
- Spots from models end inside the model unless settled: every spot goes on free ground outside (`Spots.settle`), faces what it
  belongs to; pathfinding fails from inside a model, and the old fallback then flew straight over water.
- Pathfinding waypoints float 0.7-2 studs above the floor: snap to the ground on server and client (a ball cast, a thin ray falls
  through dock planks).
- Measure before placing: props land on benches, in signs and on paths. Probes: `tools/map/probe_paths`, `probe_pads`,
  `probe_seats`, `scan_zfight`, `scan_rocks`, `fix_rocks`, `fix_zfight`. Run them at levels 1, 21, 41.
- Bounding-box tops are not surfaces: seat things by raycast (the rock's rod stand floated; crops floated on the soil).
- Raycasts from far above hit fences and tree crowns: filter to Terrain or start just above the object. A repair script that
  measured wrongly buried rocks by 10 studs, and the next one lifted them: re-scan after every fix.
- Coplanar parts flicker: `ZFight` raises the smaller one by 0.03 at every stage build.
- A BillboardGui sized in Offset stays one screen size (looks bigger when zoomed out); use Scale (studs) for world things.
- A game script cannot set a SurfaceAppearance's maps: looks come ready made in `ClientKit.Looks`.
- `ClientKit` and the kit reach the repo only through a saved place: owner Ctrl+S on the MapWork window, check the file's time
  (`assets/raw/MapWork.rbxlx`) because a save once went to the wrong window, then `lune run tools/kit/export_kit.luau` and
  `export_client_kit.luau`. Back up the place before a rebuild.
- `tools/map/sync_all.ps1` refuses during Play: stop the test first. Two agents cannot share play tests: tell each one, and never
  stop a test you did not start.

## The owner's taste (rules he set in these rounds)
- Emotes: a short pop-up at the event, never a sign that stays; lasting effects only for sleep (z's), loved (one heart at a time,
  slow, from the top of the head) and dizzy (stars circling).
- Work: one tap on the slime, it pops up at its place and starts. One square per slot, no frame when filled, no outer Manage.
- Gaits: walk = Big leaps everywhere; the slow stroll ONLY inside the breeding area.
- Rest on seats (on the seat, not the backrest). Pairs face each other. Carried things ride on the head and bob; the player holds
  things in the right hand. Bins: stand off, toss in an arc.
- Food and objects: free 3D or `generate_mesh`, never drawn; icons are model renders.
- Do not over-ask: he reads Vietnamese summaries, picks direction, and gives corrections with screenshots.

## Working with agents and ChatGPT
- ChatGPT writes large features well from a brief in `docs/briefs/`, on a `chatgpt/<name>` branch, in 20-30 min, but never ran them:
  expect lint, type and logic slips. Send back the exact gate output rather than fixing it all by hand.
- ChatGPT cannot see the world: anything about positions, looks or feel goes to a Studio agent or the orchestrator.
- A resumed agent's long context costs more each turn: start a fresh one with a good brief once it passes about 300k tokens.
- Commit message and report must separate what was proved in play from what only passed tests.
