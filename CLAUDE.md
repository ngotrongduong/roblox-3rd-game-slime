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
Replies to the owner are in Vietnamese. Code, comments and commits in English. **Every word inside the
game is English** (UI, signs, labels, names, even greybox labels) — the owner's rule, 2026-10-27.

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
- `.claude/agents` — the team (gameplay-dev, ui-dev, world-builder, scene-artist, model-artist, feel-dev,
  balance-tester, reviewer); `.claude/skills` — how recurring jobs are done (studio-build, art-pipeline, playtest,
  publish, robux-products, store-page); both carried over from Egg Heist, see `docs/inherited-from-game-2.md`.

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

## The owner's standing rules (carried over from earlier games)

Rules the owner set in his earlier Roblox games: Tile Smash (`C:\new roblox`), Table Titans (`C:\table-titans`) and
Egg Heist (`C:\roblox 2nd game`, "EH" below). They hold here; where this project's own docs decided otherwise
(`docs/DESIGN.md`, `docs/MAP.md`, `docs/UI.md`), the docs win. Source in brackets.

Art, models and the world
- A missing asset goes to ChatGPT AT ONCE: write the image prompt and send it in the same turn; never a coloured dot,
  text glyph or code-drawn shape as the final look; an agent names the missing picture in its report. [EH CLAUDE.md,
  said several times, written 2026-10-20]
- Every job handed to ChatGPT or Codex runs at its highest reasoning setting. [EH, 2026-10-19]
- No model, terrain piece or landmark is built before its reference picture exists, however small the request; then
  compare -> list what is not met -> fix -> check again, several rounds, and write the lessons down (skill
  `studio-build`, its `LESSONS.md`). Here the first reference is the owner's own painting. [EH, 2026-10-21]
- Maps and scenery are built live in Studio through its MCP server ("very fast and effective, build maps this way from
  now on"), in a separate work place under `assets/raw/`, by re-runnable scripts; scenery models come from
  `generate_mesh` as low poly as possible and go into the reusable kit (`assets/Kit/`, index `docs/kit/README.md`):
  look there before generating. Hero models that must match a painting go through Blender (`model-artist`) or the
  owner's image-to-3D, not `generate_mesh`. [EH, 2026-10-21/22]
- Everything as low poly and as cheap as weak phones need: few draw calls, shared meshes, no terrain grass blades,
  shadows off on small props. [EH; global]
- The owner loves games full of beautiful effects and wants the best experience the platform allows, smooth on cheap
  phones: use the global skills `roblox-vfx-craft`, `roblox-creature-rigging`, `roblox-creature-animation` (this
  project's docs win over them). [global CLAUDE.md, EH 2026-10-20]
- Visible effects come from art (the owner's VFX packs in his Studio inventory, particle textures, the original's effect
  art, ChatGPT pictures), never from code shapes; code places, scales, tints and times them. [EH, 2026-10-15]
- Every creature, element and rare slime has its OWN effects design (own sprites, motion, burst); one effect recoloured
  is not a new design. (The same as this game's veto on "one asset recoloured per element".) [EH, 2026-10-25]
- No ambient environment particle layers (falling leaves, petals, drifting dust): the owner removed them as heavier for
  little gain. The fireflies and drifting snow named in `docs/MAP.md` stay few, near the player, off under a low effects
  setting, and are shown to the owner before they stay. [EH, 2026-10-20]
- A visual change is not done until it has been seen in a Studio play test at the game's real camera distance. [EH,
  2026-10-20]
- Creature motion (monster slimes, enemies, bosses): look at every joint of the real skeleton, limbs bend at their
  joints, heads do not keep turning, no effort above the head; rig and animate in Blender, then into Roblox; natural
  deep bends beat timid limits. Slimes keep their procedural squash and hop (`docs/DESIGN.md` §4). [EH, 2026-10-09..23]
- Free Creator Store art is allowed only where the owner's art does not reach (sky, materials, particle textures):
  never paid, never with scripts kept, never from an impersonating creator or named after another game. [EH, 2026-10-19]

Screens
- A reward or a cost is its picture and a short number; never show how a number is worked out; explain little. [EH,
  2026-10-19]
- HUD: buttons hug the screen edges, the middle stays empty, related buttons grouped behind one, no names over heads,
  Roblox's own player list, world billboards sized in Offset pixels and scaled with the screen, no boards that only
  repeat numbers. [EH, 2026-10-21]

Numbers and money
- When the owner names a number or a factor, it goes straight into `Config` as one named value, no simulation round
  first; he tunes by playing. [EH, 2026-10-14/15]
- Robux: the owner approves the list and the prices; Claude never presses Buy, never accepts terms, keeps Managed
  pricing off; what Robux buys travels on its receipt and is never granted twice; nothing is sold before the save has
  loaded; odds of paid random items are shown; a discount label is computed from real prices; product names have no
  digits. Here Robux comes only at Launch and never pay-to-win (`docs/DESIGN.md` §2). Skill `robux-products`. [Tile
  Smash 2026-10-05..07, EH]
- Never lose a player's progress: Studio play tests never touch real players' saves (a separate store or slot), and a
  publish that changes the save shape shuts down all old servers. [Tile Smash 2026-10-06, EH 2026-10-18]

Working
- Work with a clear brief and a check a command can run goes to ChatGPT (browser pane) or Codex (`tools\codex.ps1`)
  first, to spare Claude's tokens; Claude writes the brief, runs the checks, looks at the pictures and commits. [EH,
  2026-10-12, 2026-10-20]
- Test switches in `Config` are off in anything committed; debug tools never reach players. [EH CLAUDE.md]
- Match the files around you (tabs, comments that say why); no new libraries, third-party code or second particle or
  animation engine without the orchestrator's review. [EH CLAUDE.md, AGENTS.md]
- When several agents work at once, a failing check in a file that is not yours: wait a minute, run it again, report it
  if it stays. [EH CLAUDE.md]
- The orchestrator does not take the owner's screen while he is using the machine (he often plays in the same Studio
  window); Studio dialogs (Asset Manager import, Publish As) are clicked by the owner. The play-test log is read with
  `tools\read_log.ps1`; subagents reach Studio through `node tools/studio_mcp.js`. [Tile Smash, EH]
- Agent files made during a session load only in the next one: until then, start a `general-purpose` agent and tell it
  to read its role file in `.claude/agents/`. [Tile Smash, 2026-10-06]
