---
name: studio-build
description: Build Goo Lineage V2's world LIVE in Roblox Studio through its MCP server - the Goo Valley's terrain, the Wild Garden's quarters, the Market, the home plots' scenery, light, low-poly kit models from Roblox's generate_mesh - always from a reference picture and checked against it with screenshots until it matches. Use for a new area, dressing, a set of props for the kit, or when something built looks poor.
---

# Building in Studio, from a reference, until it matches

Carried over from the owner's previous game (Egg Heist, `C:\roblox 2nd game\.claude\skills\studio-build`), where the
owner set these rules (2026-10-21): maps are built this way ("very fast and effective, build maps this way from now
on"); **as low poly as possible** so weak phones play smoothly; every model made is **kept in the kit** for reuse; and
nothing is built without a **reference picture** first, nor called done until the result has been compared with it and
fixed, several rounds, with the lessons written down.

In this game the reference is first of all **the owner's own paintings** (`art/chatgpt-refs/`,
`reference/goo-lineage-web/assets`) and the ChatGPT concept art made from them (`docs/art/*.md` holds the prompts,
`art/inbox/` the pictures). The look is decided (`docs/DESIGN.md` §3): full 3D cartoon in the style of the owner's art,
simple and clean, low poly.

The stages, as professional Roblox environment artists work (the research and its numbers: `RESEARCH.md` beside this
file):

1. **Reference**: the pictures, the checklist, the fixed cameras.
2. **Greybox**: terrain shape, paths, landmarks, plain blocks where big things will stand. Judge ONLY layout, scale
   against a player, paths and sightlines; screenshot it as the baseline. (This game's greybox exists:
   `tools/map/build_terrain.luau`, `tools/map/build_greybox.luau`, positions from `src/shared/Layout.luau`, pictures in
   `docs/map-greybox/`.)
3. **Assets**: what the kit lacks, generated and judged (2-3 candidates for a hero prop, the best by silhouette). Hero
   pieces that must match a painting closely (the plot's buildings, the slime) go to the `model-artist` agent (Blender)
   or the owner's image-to-3D route instead (see `art-pipeline`).
4. **Dressing**: scattering by rules (dense near paths and points of interest, sparse toward the edges, open grass
   between clusters), variety by scale, rotation and tint of few meshes.
5. **Light and mood**: Lighting, Atmosphere, a ColorCorrection (saturation) to bring the palette to the reference; it
   must read WITHOUT shadows too (they are off at graphics quality 4 and below).
6. **Performance gate** (section 4c), then the **compare rounds** (section 4) and the **lessons** (4b).

**HARD RULE (the owner, 2026-10-21, after it was skipped once): no model, piece of terrain or landmark is generated or
built before its reference picture exists, however small the request. A request like "add a big tree" starts with the
ChatGPT prompt, in the same turn.**

## 0. Before anything

- Look in the kit: `docs/kit/README.md` (the index) and its pictures `docs/kit/gallery_*.png` (both are made with the
  first kit model). Reuse before generating. The owner's previous game has a kit of low-poly nature models
  (`C:\roblox 2nd game\assets\Kit`, index `C:\roblox 2nd game\docs\kit\README.md`): its models were made for that game
  and are ours to reuse only where they fit this game's softer painted look; read, never edit, that folder.
- Look for the job's reference pictures. If there is none, the orchestrator asks ChatGPT for one at once (below); an
  agent says in its report which picture it needs and works on what it can.

## 1. The reference

- ChatGPT (the browser pane, its highest reasoning setting, the style lock of `docs/art/chatgpt-home-plot.md`, one image
  per message, the subject written out in full each time; "next" alone makes it redraw the last one). For an area: a
  wide view of the whole and a closer view of its heart. For a kit category: one sheet of all its models side by side.
- The internet is fine for the look of real things (how a willow droops, how a pond's shore runs); for shape and colour
  only: nothing of another game is copied.
- Keep the pictures in `docs/references/<job>/` (or `art/inbox/` when the owner downloads them himself).
- The checklist: the 9 standard points, each scored 0 (not met), 1 (close), 2 (met): (1) silhouette and landmark
  placement, (2) palette, its 5-7 dominant colours, (3) value structure (both pictures in greyscale), (4) horizon height
  and camera angle, (5) density gradient, (6) path readability, (7) haze and depth layers, (8) scale against a player,
  (9) shape language (chunky, rounded). Then the job's own points read off the reference. A kit model: silhouette,
  proportions, colour, parts that must show, size.
- The cameras: 3-5 fixed positions (a wide view like the reference's, the game's own top-down follow view, eye level at
  the gate, one detail) written in the job's script folder (`cameras.json`), the same every round.

## 2. The connection

- Studio: Assistant (Ctrl+J) > ... > Settings > MCP Servers > **Enable Studio as MCP server** (the owner turned it on in
  October 2026).
- In a session that has the `Roblox_Studio` MCP tools, use them. Otherwise (and in every subagent):
  `node tools/studio_mcp.js list` · `call <tool> <args.json>` · `run <file.luau> <studio_id> [Edit] [NAME=file]` ·
  `shot <studio_id> <out.png> cx cy cz lx ly lz`. `call list_roblox_studios` gives the ids (names show the place); ids
  change when a place is reopened.
- Work in a SEPARATE place saved under `assets/raw/` (the valley's is `assets/raw/MapWork.rbxlx`); never in the published
  place. "Save Experience" (Ctrl+S on a new place) would create a new experience on Roblox: cancel it; use File > Save to
  File As.
- If a call says Studio is in Play mode, the owner is testing: wait, then call `get_studio_state` again. When the owner
  is using the screen, do not take it: saves and shots wait.
- `execute_luau` freezes Studio until it yields: work in chunks with `task.wait()` (terrain a region at a time, models
  40 at a time). A minimised Studio gives white `screen_capture`s.

## 3. Building

- Every build step is a Luau file in the job's folder (`tools/map/` for the valley), re-runnable from nothing, positions
  read from `Layout`: terrain, landmarks, dressing, light. Fix the script and run it again; do not hand-fix in Studio.
  The plan is that the game builds the valley from `Layout` itself (a server `World` module), so what works in the work
  place moves into the game as code or as exported data (TerrainRegions, placements), never as a hand-saved place.
- Terrain: Grass / LeafyGrass / Sand / Mud / Rock / Slate / Snow with `SetMaterialColor` to the palette; water by
  `Terrain.Water*`; a light `Atmosphere` (density about 0.2), `Clouds`. Turn the grass blades off (Terrain property
  Decoration, Properties panel: not scriptable). For a painted look, grass, paths and sand are FLAT colour: a
  MaterialVariant with no texture over the material (`MaterialService:SetBaseMaterialOverride`); rock keeps its texture.
  A game script may not create a MaterialVariant at run time: they are built into the place.
- Models: `generate_mesh`, `segmentation: "none"`, `maxTriangles` per kind (trees 450, bushes 220, rocks 140, flowers
  160; never above 600 for scenery). Prompts: `stylized low poly cartoon <thing>, <what it looks like>, flat matte
  colours, game asset` and nothing else, under ~200 characters. Give it a box whose longest side is about 20 and scale
  afterwards by the LONGEST side. At most 3 jobs at a time ("Too Many Requests").
- Every placed copy is a clone of one kit model (the mesh is shared), anchored, `CanTouch` and `CanQuery` off, no
  collision on foliage, rocks by their hull (Box for small ones), `RenderFidelity` Automatic, `CastShadow` off on small
  props, transparency only 0 or 1. Never change TextureId or Material per copy: vary by scale, rotation and colour (tint
  the generated part's OWN SurfaceAppearance `Color`; to change a colour a tint cannot reach, paint it: remove the
  SurfaceAppearance, TextureID "", SmoothPlastic + Color). Place bare MeshParts, not Model copies; lay landmarks on the
  PROBED ground (a raycast), never at the plan's height.
- **A model with a PrimaryPart pivots by `PrimaryPart.PivotOffset`, not by `WorldPivot`.** Set the pivot at the middle
  of the foot that way, or everything stands half sunk into the ground.
- Scattering: Poisson-disk (Bridson) with a radius from a noise field gives an even, natural spread with a density
  gradient; a seeded `Random` so a re-run gives the same map.

## 4. Compare and fix (the loop, several rounds)

- Each round: shots from the fixed cameras (close shots for single models), Read the pictures, and score the checklist
  point by point: 2 MET / 1 CLOSE / 0 NOT MET, with one line on what differs. Write the round's table into the job's
  notes (`docs/references/<job>/rounds.md`). Every hero piece is also shot from ABOVE at about 60 degrees (the game's
  camera is top-down) and from close beside it: a piece that only reads from the front is not done. Judge every model
  from 4 sides and above, never one.
- Fix the NOT MET points first, the biggest first (shape, then proportion, then colour, then density), re-run, and start
  the next round. A model that came out wrong is thrown away and generated again, with a better prompt if the same fault
  came twice. Before blaming a model, probe where it stands.
- At least 2 rounds after the first draft, at most 5 for one job; stop when every point is MET or CLOSE.
- Done means: the list is met, nothing floats or sinks, nothing obviously repeats, and the triangle budget is kept.
  Send the owner the reference and the result side by side.

## 4c. The performance gate (before every round is shown)

- Count with `execute_luau`: instances, MeshParts, unique MeshIds, triangles, parts that collide, parts that cast
  shadows. Check the REAL triangles of a generated model before using it (some broke their ceiling ten times over).
  Targets (`RESEARCH.md`): at most 300k triangles and 500 draw calls in view, a kit of 30-60 unique meshes reused, props
  150-450 triangles, textures 256.
- What can only be measured in the game (FPS, draw calls, memory) is measured on a real low-end phone by the owner (F9,
  Shift+F1..F5, the MicroProfiler) before a map is published; the report says so.

## 4b. The lessons

- READ `LESSONS.md` beside this file before starting a job.
- At the END of every job, add what this job taught (a mistake made, a prompt that worked, a number that worked) to
  `LESSONS.md`, one dated line each, under its heading. If a lesson changes how this skill says to work, change the skill
  too.

## 5. Keeping it

- Kit models go to `assets/Kit/<Category>/<key>.rbxm` with a line in `docs/kit/README.md` and a gallery picture
  `docs/kit/gallery_<category>.png`. The tools that did this in the owner's previous game (`tools/realm/kit_spec.json`,
  `kit_generate.js`, `kit_collect.luau`, `kit_gallery.luau`, `kit_tris.luau`, `stats.luau`, `shoot_around.js`, and
  `tools/kit_export.luau` in `C:\roblox 2nd game`) are ported here with the first kit job (see
  `docs/inherited-from-game-2.md`).
- An area: its scripts in its folder, the work place in `assets/raw/` (not committed), and what the game needs of it
  (terrain as TerrainRegions, placements as data) brought into the project when it goes into the game.
