# Brief "village-movement": pathfinding, collisions, a natural hop, carrying (slimes and the player)

Claude (the orchestrator) has full decision authority; never ask the user anything; work until the task is done.
Repository `ngotrongduong/roblox-3rd-game-slime`, base `main`. Work on a NEW branch `chatgpt/village-movement` from the
latest `main`; never commit to `main`, no pull request.

Read first: `CLAUDE.md`, `docs/GAMEPLAY.md` (§10 = the owner's notes this job answers: Carrying, Movement, The player
helps), and the village code: `src/server/Village.luau` (actors, routes, legs, replication), `src/server/Spots.luau`,
`src/server/VillageRemotes.luau`, `src/shared/Brain.luau` (actions, reservations, `arrive`), `src/shared/Food.luau`,
`src/shared/Breeding.luau` (`placeInIncubator`), `src/client/Village.client.luau` (draws slimes along legs, carried
items), `src/client/SlimeActor.luau` (the render loop, hops, `setCFrame`), `src/shared/SlimeMotion.luau`,
`src/shared/Config.luau`.

Another worker is rebuilding the UI at the same time: do NOT edit `src/client/VillageUI.luau`, any `src/client/Ui*.luau`
or the `Ui` block of `Config.luau`.

## The owner's words (2026-10-29)
"When a slime carries something on its head and moves, the thing must move up and down with the slime. Slimes have a
collision box and follow physics like everything else, they do not walk through objects. Program a sensible way for
them to find their path. The movement animation must be redone: now they go far too fast, not like a slime's normal
movement. If no slime is working, the player can help by moving eggs, vegetables, fish, food... to the allowed place."

## Build
1. **Pathfinding (server)**: routes come from `PathfindingService` (agent radius and height from the slime's size,
   no jumping, `Config.Village.Path*` numbers) between the slime's position and its target, over the plot's real
   geometry (fences, buildings, props, water, beds). Each waypoint is a leg (merge nearly straight runs). Cache paths
   between fixed spots; for moving targets (player, partner) recompute at most every `PathRefreshSeconds`. When a path
   fails, fall back to today's route through the plaza and log one line naming the two spots (rate-limited).
2. **Collisions**: slimes never pass through objects (the path), the player or each other: the client's slime bodies
   are collidable for characters (anchored parts moved by SlimeActor, so the player bumps into them); slimes keep a
   small personal space — the server avoids sending two slimes onto the same point at the same time (extend the spot
   spread to the path's end), and the client nudges overlapping slimes apart smoothly (presentation only, no drift).
3. **A natural slime hop-walk**: much slower (`Config.Village.WalkSpeed` about a third of today's, SPD adds a little),
   one hop every `HopSeconds` (about 0.55 s) covering about `HopStuds`: the body moves forward only while airborne,
   crouches before and squashes after each landing (SlimeActor's `hop`), with a tiny pause between hops; it turns
   smoothly toward where it goes before hopping. Leg times on the server match this pace exactly, so client and server
   agree where a slime is.
4. **Carried things ride on the head**: the carried model follows the body's top every frame, rising and falling and
   tilting with each hop and squash (attach it inside SlimeActor's single render loop: add `Actor.attach(self, model,
   offset)` / `Actor.detach(self)`; no second loop). Same for eggs carried to the incubator.
5. **The player helps carry** (server-authoritative): ProximityPrompts (key E, `Config.Village.CarryPrompt*`) at the
   fish bin, the vegetable bin, the storehouse, the kitchen counter, the fridge, the nests and the incubators. "Pick
   up" takes one item (a fish, a vegetable, a dish or an egg) into the player's hands; "Put down" at a place that
   accepts it (raw food → storehouse or kitchen counter; dishes → fridge; an egg → a free incubator, which starts its
   incubation) moves it with the shared rules (`Food.take/add`, `Breeding.placeInIncubator`). Only the plot's owner;
   distance checked on the server (`CarryReachStuds`); one item at a time; the carried model is welded on the player's
   head (server side, so everyone sees it); leaving or dying puts it back where it came from (never lost, never
   doubled). The brain treats an item the player holds as reserved. A new remote request is not needed if prompts are
   server-side; if you add requests, check them like the others in `VillageRemotes.luau`.

## Tests and gates
Lune tests for any pure helper you add (path leg merging, player carry rules in a shared module if you make one).
`tools/check.ps1` → `CHECK OK`, `tools/types.ps1` → `TYPES OK` (strict). You cannot run them: be careful (no unused
variables, imports or parameters; attribute reads are `any`; typed fields added later go in the type).

## Report (your last chat message)
Branch, commits, what changed per file, what you decided yourself, what the orchestrator must check in Studio.
