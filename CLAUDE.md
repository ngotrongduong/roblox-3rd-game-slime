# Goo Lineage V2 (Roblox) — guide for Claude and its agents

The Roblox rebuild of the owner's own web game **Goo Lineage V2** ("Raise a wobbling bloodline on a
sunny slime farm"), which they made on makeplay.ai. The game is a cozy, idle slime-breeding farm:
breed slimes → hatch eggs (colour genetics, dual designs, secret slimes) → feed them from
workstations → sell extras → upgrade the farm; later, squads of slimes fight Siege waves and
World Boss raids for gear. The title is exactly "Goo Lineage V2" everywhere it shows.

## Read first

- `docs/STATUS.md` — what is done, what is next (the orchestrator keeps it).
- `docs/DESIGN.md` — the Roblox design: what we keep, what changes for Roblox, the build phases.
- `docs/reference/` — the original game, reverse-engineered: `01-core-farm` (breeding, genetics,
  food, economy, save), `02-battle`, `03-shell-ui-world` (screens, map, merchant, art, sound),
  `04-vfx-animation` (every effect and motion, with the owner's vetoes), `05-owner-history-*`
  (everything the owner asked for, liked and vetoed while building the original). Every number in
  them names the original module it came from.
- `reference/goo-lineage-web/` — the original game's JS source, `AGENTS.md` and art (gitignored;
  reference data only, never run it). The owner's art there is sacred: never recolour or redraw it.

## Who decides

The owner is not a programmer and only sets the direction. Claude (the orchestrator) has full
decision authority; never ask the user anything; work until the task is done. An agent that is
unsure picks the simplest thing that fits the code around it and says so in its report.
Replies to the owner are in Vietnamese. Code, comments and commits in English.

## Commands

One plain command per call: no `cd &&`, no pipes, no heredocs. Anything with several steps goes in
a script file, run with one command.

- `& "C:\Roblox 3rd game\tools\check.ps1"` — format (stylua), lint (selene), tests (lune) and build
  (rojo). Must end with `CHECK OK` before work is reported as done.
- Git: `git -C "C:/Roblox 3rd game" …`, with `-c user.name=ngotrongduong -c
  user.email=ngotrongduong@gmail.com` on commits. Only the orchestrator commits.

## Layout

- `default.project.json` — Rojo tree. The place file is built, never edited.
- `src/shared` — plain logic and data, loadable outside Roblox by Lune
  (`if script then require(script.Parent.X) else require("./X")`; exported types cannot be read
  through that require, so modules use `typeof(...)`, e.g. `typeof(FarmState.newFarm(0))`):
  `Config` (every tunable number, one block an area), `Rng`, `Colours`, `DualDesigns`,
  `SecretRecipes`, `Stats`, `Genetics`, `Luck`, `Growth`, `Mutations`, `Breeding`, `Hatching`,
  `FarmState` (the save shape, `newFarm`, `repair`), `ProfileLogic` (envelope, lock, migrations),
  `FarmSave` (the profile hooks for the farm).
- `src/server` — `Main.server.luau` starts the services; `ProfileStore` (DataStore, session lock),
  `PlayerData` (get / update / markKeyMoment: the only way to change a player's data).
  `src/client` — drawing and input.
- `tests/run.luau` runs every `tests/spec/*.luau` (`lune run tests/run.luau genetics` runs one);
  the kit is `tests/lib/T.luau`, with `FarmKit` and `FakeDataStore`.
- `& "C:\Roblox 3rd game\tools\types.ps1" [path]` — the Luau type checker Studio uses; must end
  with `TYPES OK`.

## Rules of the code

- The server decides everything; clients draw and ask. Every remote handler checks who asks, what
  they own and how often. Times are server time (`os.time()` / `workspace:GetServerTimeNow()`).
- Numbers live in `Config.luau`; nothing tunable is written into the logic.
- Logic that can be pure goes in `src/shared` with a check in `tests/run.luau`.
- Every line the game prints starts with `[GooLineage]`.
- Smooth on cheap phones: budget particles, stream the world, animate only what is on screen.
- Carry every owner veto from `docs/reference/04-vfx-animation.md` §14 and `05-owner-history-*`.

## Hard limits

- Never enter credentials, sign in, buy anything, accept terms, or delete the owner's data. Never
  commit secrets.
- Never take over the screen from an agent: no Roblox Studio, browser or desktop control. Report
  what needs a look; the orchestrator does it.
- Nothing is copied from another developer's game. The owner's own web game is ours to port.
