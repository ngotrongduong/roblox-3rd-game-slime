# What the professional workflow is, and the numbers (research of 2026-10-21)

Carried over from the owner's previous game (Egg Heist). The sources behind `SKILL.md`. [V] read in an official or
primary source, [G] general game-art practice, [?] not verified. Re-check a [?] before leaning on it.

## The pipeline [V]

Roblox's Environmental Art curriculum: greybox -> polished assets -> a central asset library -> construct the world ->
optimise (https://create.roblox.com/docs/tutorials/curriculums/environmental-art). The greybox tests layout and play
"before investing time into polishing assets". Global light comes last.

## Composition [G]

A landmark a zone, seen from the spawn or the gate; the first view framed by two masses; paths that lead the eye with
light or contrast at their end; one hero object a screen; open ground between clusters; dense near paths and points of
interest, sparse toward the edges, big cheap shapes far away; foreground / midground / background separated by value
and haze; variety by scale, rotation and tint of few meshes rather than more meshes (Roblox says the same for draw
calls: https://create.roblox.com/docs/performance-optimization/design).

## Judging against a reference [G]

Score 0-2 each, the same 3-5 cameras every round, the lowest first: (1) silhouette and landmark placement, (2) palette
(5-7 dominant colours), (3) value structure (both pictures in greyscale: the light and dark masses), (4) horizon
height and camera angle, (5) density gradient, (6) path readability, (7) haze and depth layers, (8) scale of props
against a player, (9) shape language (chunky or thin). Pixel metrics (SSIM, PSNR) do not judge style; an image-model
judge (us) scoring item by item with a one-line reason does. Cheap pre-checks: greyscale histogram, a 6-colour palette,
horizon height, an 8x8 luminance map.

## Performance [V unless marked]

- 60 FPS = 16.67 ms. Roblox's only example numbers: under 1,000 draw calls and 1M triangles on a baseline device; draw
  calls matter more than triangles; identical meshes with matching textures share a draw call
  (https://create.roblox.com/docs/performance-optimization/improve).
- Textures: memory goes with pixels (1024 = 4x 512); props 256 or less, at most 512. One texture tinted
  (`SurfaceAppearance.Color`) instead of colour variants.
- Transparency only 0 or 1. `CastShadow` off on small props. Few lights, their shadows off. Particles and decals batch
  poorly.
- Collision: Box for small anchored parts; `CanCollide`, `CanTouch`, `CanQuery` off where not needed; anchor all
  static parts. Cost: Box < Hull < Default < PreciseConvexDecomposition.
- `MeshPart.RenderFidelity` Automatic: full under 250 studs, medium to 500, lowest beyond
  (https://create.roblox.com/docs/parts/meshes). Changing TextureId / Transparency / Material per copy may break
  instancing [?].
- Shadows are off at graphics quality 4 and below: the scene must read without them (value, colour, haze).
- Streaming (https://create.roblox.com/docs/workspace/streaming): `StreamOutBehavior` Opportunistic,
  `ModelStreamingBehavior` Improved, `StreamingIntegrityMode` PauseOutsideLoadedArea, kit props
  `ModelStreamingMode` Atomic, `LevelOfDetail` SLIM far away. This game is planned with StreamingEnabled on
  (`docs/MAP.md` §3): code must never expect a far part to exist on the client.
- Measure on a real phone: F9 Memory, Shift+F1..F5 stats, the MicroProfiler (from the phone's settings, read in a PC
  browser).

## Tools

- The built-in Studio MCP server is the one to use (Roblox archived its Rust server). The maintained community fork
  `Chrrxs/robloxstudio-mcp` adds profiler and memory tools (`capture_micro_profiler`, `get_memory_breakdown`,
  `get_scene_analysis`): read its code before ever running it.
- Scattering: Bridson's Poisson-disk (about 60 lines; JS reference `kchapelier/poisson-disk-sampling`), radius from a
  noise field for a density gradient, seeded `Random`.
- Terrain as data: the build script plus its seed is the source of truth (deterministic, diffable); `ReadVoxels` /
  `WriteVoxels` 4,194,304 voxels a call at most; a TerrainRegion (`CopyRegion`/`PasteRegion`) is the runtime way.
- generate_mesh [G/blog]: short prompts, one object, "low poly" said; 3-4 candidates for an important prop, the best
  by silhouette from afar; normalise pivot and scale; one palette; MaterialVariants via `generate_material`.

## Numbers we adopt (our targets, tune on a real low-end phone)

- In view: at most 300k triangles and 500 draw calls. A stable 30+ FPS on the baseline phone.
- Props 150-450 triangles, hero props 250-600. A kit of 30-60 unique meshes reused many times.
- Textures 256 for props, 512 at most. Lights: about 4 local lights a zone, shadows off. Transparency 0 or 1.
- Streaming: MinRadius 64, TargetRadius 300-500 to start.
