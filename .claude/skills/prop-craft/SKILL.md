---
name: prop-craft
description: Make a prop, decoration, lamp, planter, gate, fountain or any showpiece of Goo Lineage V2 at the owner's quality bar ("as fine as the greenhouse vegetables") - choose generated model or built-from-parts, generate in batches, check each from two sides, take it into the kit, place it with a purpose, make water or light move, and get it saved and exported into the repo. Use for any new or reworked prop, and before the owner reviews a scene.
---

# Prop craft

The owner's bar (2026-10-28, after the village): a prop must look **crafted**, never "a few boxes"; the greenhouse
vegetables are the reference. Plain part-built props were sent back every time. He also judges **where** each prop
stands: every one needs a reason to be there. Replies to the owner are in Vietnamese; every word in the game is English.
Read with: `area-review` (the review loop), `studio-build/LESSONS.md`, `roblox-vfx-craft` (effects).

## 1. Choose how to make it

| Kind | Make it by | Why |
|---|---|---|
| A solid object with a clear silhouette: planter, table, gazebo, stall, arch, statue, urn, lamp post, emblem, crest, topiary, fish | `generate_mesh` | It does these well, with textures and detail parts cannot match |
| Something flat or thin: ivy on a wall, a vine, stepping stones, a sign panel | **built in code from clones of ONE small generated piece** (e.g. `IvyLeaf`) | The generator returns a lump, a bush or a tiny tree for flat things (failed 4 times on ivy) |
| A machine that must hold something real (an egg under a glass dome), or that changes per tier | **built from parts with care**, a style table per tier | The generator made a cone, a tilted barrel, a plain bowl (8 tries on the incubator) |
| A small fixture mounted on a wall: wall lantern, torch, hanging basket | **built from parts** | Generated ones came tilted, shapeless or too thin to read; built ones can be centred exactly |
| Stonework that changes with the era (fence, gate, fountain basins) | **built from parts** in the tier's colours, with generated ornaments placed on it | Its shape must follow the plot's lines and the tier palette |

A built prop is still detailed: feet or plinth, body, bands or ribs, a rim or cap, trim in the tier's soft colour, a
small light. Count its pieces; a lantern is a plate, an arm, a hook, a cap, a roof, four posts, glass, a base, a drop.

## 2. Generating (Studio must be in **Edit**; in Play every job fails "only from the server")

1. Check the owner is not playing: watch the character 20-40 s (`execute_luau` Server); if it moves, write code first.
2. `generate_mesh`, `segmentation: "none"`, `async: true`, at most **3 jobs at once**, prompt
   `stylized low poly cartoon <thing>, <shape words>, flat matte colours, game asset`. Give the box its real proportions
   (a 20 x 5 x 5 box for a long planter). Words that fixed failures: "straight vertical", "upright", "symmetrical",
   "open on all sides, no walls", "seen from the side", "flat back".
3. While they run, write the placing code.
4. `wait_job_finished`, then take them in: a SPEC text file of `Name=Assistant-tag` lines,
   `node tools/studio_mcp.js run tools/kit/intake.luau <id> Edit SPEC=<file>` (fits, squares, sets the pivot, puts it in
   `ServerStorage.PropKit`; a name that exists is replaced).
5. **Look at every one** before using it: `tools/kit/viewer.luau` lays them out on a stand; `screen_capture` from the
   front AND the side. About a third come out wrong: thrown away and generated again with plainer words. A model that
   looks tilted from one side may be straight: check the second side before `tools/kit/upright.luau`.
6. Note each kept model in `docs/kit/README.md` (name, published asset id from the job, where it is used). Free Creator
   Store images (effect textures) are credited there too; never a model with scripts, never paid.

## 3. Placing with a purpose (the owner's notes, 2026-10-28)

- **Every prop has a reason.** A bench faces something (the fountain, a stage, a table) with its lamp beside it; no
  rows of benches along every path. One of each decoration kind in view (two sundials side by side was sent back).
- **Spread, don't pile.** Planters were all at the gate and the inside was bare: a pair at the entrance, the rest
  where each path leaves the plaza. Use the whole area, not its front.
- **A shelter is a place of its own**: the picnic table on open lawn beside the gazebo, not inside it.
- **Mounted things sit centred** on their post or tower face, the same on every one, both faces, evenly spaced; none on
  corner posts or posts against a gate tower. Square each post to its own fence run, never to the plot's centre.
- **Nothing collides**: a stall clear of an arch's posts with the way through kept open; models check free ground
  (`put`/`findSpot` in VillageStages), and what found no room is named on the layer (`Skipped` attribute) - read it
  after every build and fix each one.
- **Small plants never block and never sit on paving**: they move to free lawn (also an area's own flowers on the
  village's paving).
- **Paths are all finished the same** as the main avenue (border and checks per era).
- **No text signs the owner did not ask for** (the "Plot 5" board was removed).
- **What a level adds stays in later eras** (`has(step)`), in the new era's look.

## 4. Moving water and light (the fountain recipe, `VillageFountain.luau`)

Engine-driven, no script: `Beam` curtains from each bowl rim to the pool below (a streak texture,
`TextureSpeed` scrolling, `CurveSize0` bowing out, Axis out from the rim, SecondaryAxis along it); drop jets
(`ParticleEmitter`, `VelocityParallel`, gravity, a droplet texture) with a short Beam core; splashes where water lands;
ripple rings (`VelocityPerpendicular`, growing, fading) on each pool; pools as a still blue disc under a thin
`ForceField` film in mid blue (a pale film reads white). Rims are rings of short blocks so the water shows. Keep the
whole showpiece near 200 particles/s (a `RATE` factor) and count emitters, rates and beams after building. Lights: a few
`PointLight`s on lit lamps only (every other one).

## 5. Done means exported

1. `tools\check.ps1` CHECK OK and `tools\types.ps1` TYPES OK; sync (`tools/map/sync_server.luau`, every new module
   listed in its `sources`); shoot every era at the game's camera and close; self-review; ChatGPT if it is a scene
   (skill `chatgpt-review`); commit.
2. Generated models live only in the open Studio place until the owner presses **Ctrl+S**: ask him in the wrap-up box.
3. On his word, check `assets/raw/MapWork.rbxlx`'s time is NEW (a Ctrl+S into the wrong window does not save - ask him
   to click Studio and press again), then `lune run tools/kit/export_kit.luau`, then
   `lune run tools/kit/check_kit.luau <names>` must say KIT OK; commit `assets/Kit/*.rbxm`.
