# What was carried over from Egg Heist (2026-10-27)

The owner asked: "study the second game, transfer its agents, skills and notes over here so I don't have to repeat the
old rules." Source: `C:\roblox 2nd game` (Egg Heist), read only, and the session memories of the owner's Roblox games
(Egg Heist, Tile Smash, Table Titans). Nothing in the second game was changed.

## Transferred

Agents (`.claude/agents/`), each rewritten for this game (paths, `tools\check.ps1` / `types.ps1`, `[GooLineage]`, the
owner's vetoes and the decided look):

| Agent | Model | What it does here |
|---|---|---|
| `gameplay-dev` | sonnet | farm rules, saves through `PlayerData`, remotes |
| `ui-dev` | sonnet | the minimal HUD and the world-as-menu cards (`docs/UI.md`) |
| `world-builder` | sonnet | the CODE that builds the valley from `Layout`, level pieces, placing models |
| `scene-artist` | opus | live building in Studio from a reference (skill `studio-build`) |
| `model-artist` | opus | Blender models from the owner's paintings (skill `blender-image-to-3d`) |
| `feel-dev` | opus | big moments: the egg reveal, remodels, fights, the World Boss |
| `balance-tester` | sonnet | pacing and economy simulations in `tests/sim/` |
| `reviewer` | opus | read-only review: saves, money, trades, remotes |

Skills (`.claude/skills/`): `studio-build` (with `LESSONS.md` and `RESEARCH.md`), `art-pipeline`, `playtest`,
`publish`, `robux-products`, `store-page`.

Tools (`tools/`), small and generic, adapted: `read_log.ps1` (the play test's `[GooLineage]` lines and errors),
`studio_mcp.js` + `studio_mcp_client.js` (Studio's MCP server from a script, for subagents), `serve_dir.js` (a local
server for `upload_image`), `codex.ps1` (a job to Codex through the owner's bridge, reasoning high, reports in
`%TEMP%\goolineage_codex`).

Rules: `CLAUDE.md`, section "The owner's standing rules (carried over from earlier games)", plus one Layout line.
Memory (`C:\Users\ngotr\.claude\projects\C--Roblox-3rd-game\memory\`): token frugality, small jobs fast, the
ChatGPT/Codex how-to, Roblox accounts and access, no Windows paths in heredoc Python, the earlier games to learn from.

The portable skills `roblox-vfx-craft`, `roblox-creature-rigging`, `roblox-creature-animation` and
`blender-image-to-3d` were NOT copied: they are installed for every project in `C:\Users\ngotr\.claude\skills` (and
Codex's folder) by `C:\roblox 2nd game\tools\install_skills.ps1` from `C:\roblox 2nd game\tools\agent-skills`; they are
edited there and installed again.

## Skipped, and why

- Skill `add-zone` (a ring zone with pets, a boss and nests): Egg Heist's map and content model only. If this game needs
  a recipe for "a new Dual / Secret slime" or "a new plot area level", it is written fresh from `docs/MAP.md`.
- Egg-Heist-only notes: the chase relay, traps vs bosses, treadmills, bots as scenery, mounts and the Mount Realm, the
  hunt, followers, winged pets always fly, the rewards rework, its live store page and analytics numbers (the lessons
  kept: new players left after 1.6 minutes; the 16+ audience gate), its GitHub remote, the TV launcher (not a game).
- Egg Heist's contract (`docs/contract/*`), motion write-ups (`docs/motion/*`) and `docs/visual-experience/README.md`:
  about its own systems; read them there when a similar system is built here.
- `.claude/launch.json` (its art-kit preview servers) and settings: there is no `settings.json` in the second game.
- The ui-dev rule "no images are uploaded, icons drawn in code": the owner overturned it later (missing asset ->
  ChatGPT), and this game has the owner's own UI art.
- The world-builder rule "everything is parts made by code": replaced here by models matching the owner's paintings.

## Tools to port later (when this game first needs them)

| Tool in `C:\roblox 2nd game\tools` | What it does | Port when |
|---|---|---|
| `codemap.ps1`, `codemap.luau`, `codemaplib.luau`, `tests/codemap.luau` | the code map: callers, impact of a change, generated overview | the code grows past a few dozen modules (Phase 2-3) |
| `pictures.ps1` | keys out the background of ChatGPT icons, trims, pads, sizes, draws a sheet | the first batch of new icons |
| `split_views.ps1` | cuts a ChatGPT turnaround into views of one scale and ground line | the first Blender model (the slime body) |
| `models.ps1`, `glb_rest.js`, `glb_facing.js`, `inspect_model.ps1`, `paint.ps1`, `glow.ps1` | prepares image-to-3D `.glb` files for Roblox (fewer triangles, texture size, rest pose, facing, paint, glow masks) | the first `.glb` from the owner |
| `import_models.luau`, `modellib.luau`, `split_models.luau` | turns models the owner imported in Studio into `assets/*.rbxm` | the first imported model |
| `import_vfx.luau`, `vfxlib.luau` | rebuilds effect packs from the owner's inventory into `assets/Vfx` | the first effect pack |
| `tools/realm/kit_*`, `stats.luau`, `shoot_around.js`, `kit_export.luau` | the reusable kit: generate, collect, gallery, triangles, export | the first kit model |
| `rig_model.ps1`, `rig_round.ps1`, `joint_check.ps1`, `flex_sheet.ps1`, `weight_sheet.ps1`, `centre_line.ps1`, `probe.ps1`, `rig_sheet.ps1`, `motion_preview.ps1`, `anim_blender.ps1` | rigging and motion of creatures, judged by pictures and numbers | the first monster slime with a skeleton (Phase 5) |
| `studio.ps1` | builds and opens the place in Studio (orchestrator only) | when play tests become frequent |
| `make_grounds.luau` | MaterialVariants built into the place | the art pass of the terrain |
| debug panel (`Shared.Debug`, `DebugService`, `DebugUi`, `DebugCheats`) | Studio-only cheats, error list, effects lab | Phase 2, first playable |
| `cmp_tests.js` | compares a test copied for a Codex job with its original | the first Codex job that copies a test |
| `install_skills.ps1` | installs the portable skills | never: it stays in the second game |
