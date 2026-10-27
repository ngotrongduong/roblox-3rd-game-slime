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

## Stylized cozy look (research 2026-10-27)

Why our scenes (`docs/areas/fishing-l1.jpg`, `fishing-l1-kit-try.jpg`, `garden-l1-first.jpg`) read "low quality" next
to the owner's paintings (`art/concept/2-fishing.png`, `art/chatgpt-refs/02-fishing-pond.png`, `03-garden.png`):
(1) the terrain grass is a photographic, noisy texture in one lime green, while the paintings use 2-3 clean greens with
lighter tufts; (2) the water is realistic (white sun glints, cyan, waves) where the painting has a saturated blue with a
lighter shallow rim; (3) props are perfect primitives (a ball tree, a plain cylinder) in shiny plastic, with no dark
edges and no contact shading; (4) every prop stands alone on a big empty lawn, where the painting is a TIGHT DIORAMA:
a ring of boulders round the water, tufts, flowers and reeds hugging every base, and nothing lonely; (5) the light is
flat and noon-like, so nothing has form. Tags as above: [V] official/primary source, [G] general practice or ours,
[?] not verified: test before leaning on it.

### 1. Light and post effects

- [V] `Lighting.Technology` is superseded (still works) by `Lighting.LightingStyle` (Realistic = "the most advanced
  realistic lighting and shadows"; Soft = "a flat, retro-Roblox look with softer lights and shadows") and
  `PrioritizeLightingQuality` (true = keep shadows and shading close up first, false = keep view distance first).
  `ShadowSoftness` only acts under Realistic. Compatibility is deprecated: Voxel + `ColorGradingEffect` with
  `TonemapperPreset = Retro` imitates it. Sources: https://create.roblox.com/docs/reference/engine/enums/Technology.md,
  https://create.roblox.com/docs/reference/engine/enums/LightingStyle.md, https://create.roblox.com/docs/environment/lighting
  - The localized reference lists `LightingStyle` with Roblox Script Security [?]: set it through `pcall` from
  execute_luau and, if refused, in the Properties panel by hand (once per place).
- [V/forum] Future/Realistic adds per-pixel shadowed local lights on top of the voxel grid; devices that cannot do it
  fall back to ShadowMap or Voxel, and Roblox scales per-pixel light distance by quality level
  (https://devforum.roblox.com/t/future-is-bright-phase-3-studio-beta/639903,
  https://devforum.roblox.com/t/future-vs-shadowmap/658587). For us: Realistic + ShadowMap-class sun shadows is fine
  because we have almost no local lights (a lantern or two a plot, `Shadows = false`); phones cut shadows at low quality
  anyway, so the scene must read without them (see "blob shadows" in section 2).
- [V] `ColorGradingEffect.TonemapperPreset`: Default = "vivid colours and high contrast" (keep it), Retro = flatter
  pre-2019 look. Only one ColorGradingEffect in Lighting counts
  (https://create.roblox.com/docs/reference/engine/classes/ColorGradingEffect.md).
- Numbers people actually use for a cartoon day:
  - DevForum "Cartoon lighting settings" (https://devforum.roblox.com/t/cartoon-lighting-settings/333686): Ambient
    163,163,163; OutdoorAmbient 128,128,128; Brightness 2.67; ShadowMap with ShadowSoftness 0.27; ColorCorrection
    Contrast 0.1, Saturation 0.3, Tint 241,241,231. Another poster: Bloom 1/25/2, Contrast 0.2, Saturation 0.6 (too
    strong for us). Two posters: no Blur above 2 (it looks foggy at low quality); one avoids Bloom in cartoon builds.
  - Roblox's own outdoor tutorial: Ambient = OutdoorAmbient = 156,136,176 (a lilac fill), EnvironmentDiffuseScale 1,
    EnvironmentSpecularScale 1, Atmosphere Density 0.272, Haze 1
    (https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments.md).
    Core curriculum: OutdoorAmbient 134,158,190, ColorShift_Top 196,222,255, ShadowSoftness 0, ClockTime 9,
    Atmosphere Density 0.375, Offset 0.17
    (https://create.roblox.com/docs/tutorials/curriculums/core/building/customize-global-lighting.md).
  - Ours (LESSONS): Atmosphere Density 0.28, Offset 0.38, Haze 0.85 for a bright valley; ColorCorrection saturation
    0.2 with flat colours.
- [G] Our preset, "sunny storybook" (a starting point; tune by the compare loop). The ideas behind the numbers: the sun
  from the side and above (about 45 degrees) so rounded shapes get a lit side and a shaded side; COLOURED fill (a warm
  sun, a cool lilac shade) instead of grey; NO environment specular (that is what makes parts look like shiny plastic);
  a light haze; small saturation and contrast lift; Bloom only for real light sources.

```lua
local L = game:GetService("Lighting")
pcall(function() L.LightingStyle = Enum.LightingStyle.Realistic end)   -- Properties panel if refused
pcall(function() L.PrioritizeLightingQuality = true end)
L.ClockTime = 14.6; L.GeographicLatitude = 35         -- sun about 45 deg up, from the side
L.Brightness = 2.6; L.ExposureCompensation = 0.1
L.Ambient = Color3.fromRGB(110, 100, 125)             -- indoor/under-roof fill, a bit lilac
L.OutdoorAmbient = Color3.fromRGB(150, 140, 175)      -- shade colour outdoors: cool lilac, never grey/black
L.ColorShift_Top = Color3.fromRGB(255, 236, 205)      -- warm sunlit faces
L.ColorShift_Bottom = Color3.fromRGB(120, 140, 190)   -- cool faces turned away
L.EnvironmentDiffuseScale = 0.5
L.EnvironmentSpecularScale = 0                        -- kills the plastic shine
L.ShadowSoftness = 0.25; L.GlobalShadows = true
local function get(cls) return L:FindFirstChildOfClass(cls) or Instance.new(cls, L) end
local a = get("Atmosphere"); a.Density = 0.26; a.Offset = 0.35; a.Haze = 0.8; a.Glare = 0
a.Color = Color3.fromRGB(205, 225, 255); a.Decay = Color3.fromRGB(120, 140, 170)
local cc = get("ColorCorrectionEffect"); cc.Saturation = 0.18; cc.Contrast = 0.08; cc.Brightness = 0.02
cc.TintColor = Color3.fromRGB(255, 250, 240)
local b = get("BloomEffect"); b.Intensity = 0.35; b.Size = 24; b.Threshold = 1.6  -- only lanterns / Neon glow
local g = get("ColorGradingEffect"); g.TonemapperPreset = Enum.TonemapperPreset.Default
local sr = get("SunRaysEffect"); sr.Intensity = 0.04; sr.Spread = 0.6   -- or none: a top-down camera rarely sees the sun
for _, e in L:GetChildren() do if e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled = false end end
```

- [G] Phones: ColorCorrection / ColorGrading are almost free; Bloom, DepthOfField, Blur and SunRays are full-screen
  passes, and "on low quality levels some post effects may be completely disabled"
  (https://developer.roblox.com/api-reference/enum/QualityLevel): never let the look DEPEND on them. DepthOfField is
  for marketing shots only (FarIntensity 0.15, FocusDistance ~60, InFocusRadius ~60), never in play with a top-down
  camera.
- [V] Sky and clouds: Atmosphere is shown against a Sky; `Clouds` (child of Terrain) Cover 0-1, Density low = light
  and fluffy, high = stormy (https://create.roblox.com/docs/reference/engine/classes/Clouds.md,
  https://devforum.roblox.com/t/dynamic-skies-are-getting-cloudy/869476). [G] Cover 0.45, Density 0.4, Color white
  for a fair day; the top-down camera mostly sees the ground, so the sky matters at the gate and in shots.

### 2. Less plastic: materials, shapes, edges

- [G] Cartoon builders on Roblox keep SmoothPlastic for low-poly work (https://devforum.roblox.com/t/how-to-make-low-poly-look/687540,
  https://devforum.roblox.com/t/low-poly-building-style-tips/293535). The "plastic" read does not come from the
  material but from: perfect primitives (a ball tree), one flat colour per object, specular shine, no dark edges, and
  no contact shading. Fix those five, not the material name.
- [V] MaterialVariant (only works under MaterialService; `StudsPerTile` = scale; `MaterialPattern` Regular/Organic
  tiling; set as Override to replace a base material everywhere, terrain included; TerrainDetail for top/side/bottom)
  https://create.roblox.com/docs/parts/materials, https://create.roblox.com/docs/reference/engine/classes/MaterialVariant.md.
  Material Generator prompt tips: "simple", "pattern", "flat", "cartoon", "hand-drawn", "top down", and "grayscale"
  to tint it later; Organic toggle randomises repeats (https://create.roblox.com/docs/studio/material-generator.md).
  Our MCP has `generate_material` (returns base material + variant name).
- [G] Recipes:
  - Grass: replace the photographic Grass with a variant: either no maps (flat colour, see LESSONS) or a
    `generate_material` "cartoon hand-drawn grass, simple flat colours, top down, soft brush strokes, grayscale",
    Organic on, StudsPerTile 24-40, terrain colour from the palette below. Paint a DARKER green ring (LeafyGrass or a
    second colour) 1-2 studs round every prop base and along fences: fake contact shadow + the painting's rim.
  - Wood: `generate_material` "cartoon hand-painted wood planks texture, simple, flat warm colours, grayscale" over
    Wood, StudsPerTile 4-6; the generated roughness should be matte (no shine).
  - Stones: rock texture kept, boulders painted 2 values (grey body, a moss-green cap part or tint).
- [G] Planks and posts like the painting (cheap, by script): every plank its own part, 0.15-stud gaps so a DARK
  under-layer (a dark-brown block under the deck, 92,56,30) shows as grooves; each plank yaw +-1.5 deg, height +-0.05,
  colour +-6% value; posts a size bigger than looks right (chunky), a slightly darker top cap, a rope ring (a flattened
  torus mesh or a thin cylinder, 214,180,120) near the top; overhang the deck past its posts.

```lua
local rng = Random.new(7)
local base = Color3.fromRGB(196, 128, 66)
for i = 0, n - 1 do
  local p = Instance.new("Part"); p.Anchored = true; p.Material = Enum.Material.Wood
  p.Size = Vector3.new(deckW, 0.6, plankW - 0.15)
  p.CFrame = deckCF * CFrame.new(0, rng:NextNumber(-0.05, 0.05), (i + 0.5) * plankW - deckL / 2)
    * CFrame.Angles(0, math.rad(rng:NextNumber(-1.5, 1.5)), 0)
  local h, s, v = base:ToHSV(); p.Color = Color3.fromHSV(h, s, math.clamp(v * rng:NextNumber(0.94, 1.06), 0, 1))
  p.CastShadow = true; p.CanTouch = false; p.Parent = deck
end
```

- [V] Rounded edges: unions take `SmoothingAngle` (30-70 deg recommended, 90+ not; no smoothing across different
  colours/materials) https://create.roblox.com/docs/reference/engine/classes/PartOperation; a Nov 2025 bug thread says
  the old smoother fails and to route through `GeometryService`
  (https://devforum.roblox.com/t/roblox-studio-smooth-angle-refusing-to-work-for-the-past-two-weeks/4074083). [G]
  For anything players look at closely, use a mesh with a real bevel (one segment, wide: the stylized bevel,
  https://devforum.roblox.com/t/realism-101-building-in-roblox-using-blender/4081400) from Blender or a CC0 pack;
  chamfer big blocks with Wedge/CornerWedge strips when no mesh exists.
- [G] Blob shadows (the scene must read at quality 1-4 where shadows are off): an opaque thin cylinder (0.05 thick,
  1.2x the prop's footprint, CastShadow off) in a darker grass colour under every prop, tree and boulder. Transparency
  stays 0, so it batches. This single trick does most of what the painting's soft shading does.
- Outlines (the painting's dark-brown edges):
  - [V] `Highlight`: up to 255 per client since 10 Nov 2025 (was 31)
    (https://devforum.roblox.com/t/lights-camera-more-highlights/4061534); the FIRST visible one costs up to ~1 ms
    GPU on mobile, more with screen coverage; each highlighted object is an extra draw; adding/removing one rebuilds
    geometry, so toggle `Enabled` instead (https://create.roblox.com/docs/effects/highlighting). One Highlight on a
    Model outlines all its parts (silhouette only). Recipe for 1-2 hero models per area: `FillTransparency = 1`,
    `OutlineColor = 60,38,22`, `OutlineTransparency = 0.2`, `DepthMode = Occluded`. Not for scatter.
  - [G/forum] Inverted hull: a copy of the mesh with flipped normals, pushed out ~0.03-0.05 studs, dark material; the
    front faces are culled so only a rim shows (https://devforum.roblox.com/t/r15-and-r6-cel-shading/869167,
    https://bnpr.gitbook.io/bnpr/outline/inverse-hull-method). Doubles triangles; gaps up close on thin parts. Best done
    in Blender by the `model-artist` (Solidify, flip normals) and baked INTO the kit mesh with dark vertex colours
    (the importer keeps vertex colours: https://create.roblox.com/docs/art/modeling/3d-importer) [?] so it costs no
    extra draw call. Test on one kit prop before a whole set.
  - [?] No real toon shader exists on Roblox; the old "huge FogStart + bright FogColor" hack is a bug-based effect that
    breaks on Vulkan/OpenGL (https://devforum.roblox.com/t/how-to-cel-shading-effect/1472627): do not use.
- [G] Palette read off `art/concept/2-fishing.png` and `art/chatgpt-refs/02,03` (eyeballed; check with a 6-colour
  palette pick): grass 98,172,58 / dark 52,118,46 / light tufts 150,205,80; wood 196,128,66 / light 226,162,92 / groove
  92,56,30; water deep 30,110,200 / shallow 80,180,230; stone 165,160,145 with moss 120,150,70; accents: lantern
  255,190,80 (Neon, the only Neon), bobber red 215,60,50, toolbox blue 40,90,170, flowers white 250,248,235 with yellow
  hearts, terracotta 200,110,70, awning green 90,140,70 / cream 240,228,190. One warm accent and one cool accent per
  area; white flowers as the "sparkle".

### 3. Foliage, grass, wind

- [V] Terrain `Decoration` (grass blades) only on the Grass material, `GrassLength` 0.1-1, moves with
  `workspace.GlobalWind` (https://create.roblox.com/docs/parts/terrain). A forum view is that it is a cheap shader
  (https://devforum.roblox.com/t/alternatives-to-grass/423304), our LESSONS say heavy on phones and not scriptable:
  [?] measure once on the owner's phone with Decoration on and GrassLength 0.4 before deciding. Its thin realistic
  blades do not match the painting either way.
- [G] The painting's grass is TUFTS: a kit of 3 tuft meshes (5-9 chunky leaf blades, 30-80 triangles, flat vertex/one
  colour, two greens), 3 flowers (5-petal white, yellow, pink, 20-40 triangles), 2 small round stones. Scatter
  150-300 per plot area, DENSE against every base, the water's edge, fences and paths, almost none in open ground. All
  clones of the same few meshes (instanced), Anchored, CanCollide/CanTouch/CanQuery off, CastShadow off, random yaw,
  scale 0.8-1.25. Flowers in clusters of 3-7, never singly in a grid.
- [V] Wind: `workspace.GlobalWind` (docs example base 5,0,2 with gusts to 25,0,10) drives terrain grass, clouds, and
  particles with `WindAffectsDrag` + Drag > 0 (https://create.roblox.com/docs/environment/global-wind). Set about
  Vector3.new(4, 0, 2).
- [V] Sway for meshes: `boatbomber/WindShake` (MIT, https://github.com/boatbomber/WindShake): tag parts, `Init()` on
  the client; settings WindDirection (0.5,0,0.5), WindSpeed 20, WindPower 0.5, `RenderDistance` 150,
  `MaxRefreshRate` 1/60, `Init({MatchWorkspaceWind = true})`. [G] For phones: RenderDistance 60-80, MaxRefreshRate
  1/30, only reeds, tall flowers and bush tops (not the tufts, not trees' trunks). Read its code before vendoring it
  (it moves CFrames on the client; anchored, no collision on tagged parts).

### 4. Water (the pond)

- [V] Terrain water: `WaterColor` (default dark teal), `WaterReflectance` 0-1, `WaterTransparency` 0-1,
  `WaterWaveSize` 0-1, `WaterWaveSpeed` 0-100 (https://create.roblox.com/docs/parts/terrain). Water transparency is
  not honoured under graphics quality 8 (seen as opaque) (https://devforum.roblox.com/t/terrain-water-transparency/1688952,
  https://roblox.fandom.com/wiki/Water). A stylized recipe from the forum: Reflectance 0.05, WaveSize 0.05, colour
  131,165,164 (https://devforum.roblox.com/t/how-can-i-make-this-water/383740).
- [G] Cartoon terrain pond: WaterColor 40,140,215, WaterReflectance 0.08 (removes the white glints in our shot),
  WaterTransparency 0.55, WaterWaveSize 0.04, WaterWaveSpeed 6; paint the bed near the shore light (Sand tinted
  110,200,220) so shallows read lighter where transparency works. These are place-wide (every terrain water body).
- [G] Better for a small plot pond, and the same on every phone: PART water. An opaque flat MeshPart/Part (SmoothPlastic,
  30,120,205) at water level, a slightly smaller part 0.02 lower in deep blue offset away from the shore, and a lighter
  shallow ring (80,180,230) round the rim, or one 256 hand-painted ColorMap (deep centre, light rim, a few white
  sparkle strokes) via SurfaceAppearance. Ripples: 1-2 slow ParticleEmitters (flat ring texture, Orientation
  VelocityPerpendicular, Rate 0.3, Lifetime 2.5, size 1->4, fade) at the bobber and lily pads.
- [G] Shoreline like the painting: a ring of 6-12 rounded boulders (2-3 shapes, 3 sizes, sunk 30%, each with a moss
  cap) covering most of the edge; reeds/cattails in 2-3 clumps of 3-5 at the back corners; tufts and white flowers
  between the stones; a foam line is optional (thin white ring at Transparency 0 just inside the stones, or skip:
  the painting has none). Lily pads: 3-5 flat discs (0.15 thick) with a wedge notch, two greens, one with a pink
  flower, 0.03 above the water plane.

### 5. Free stylized assets (all CC0 unless said; do not download without the art-pipeline's checks)

| Source | Licence | What fits us | Notes |
|---|---|---|---|
| KayKit Forest Nature Pack (Kay Lousberg) https://kaylousberg.itch.io/kaykit-forest | CC0 (free tier, pay-what-you-want) | 100+ trees, bushes, rocks, grass | FBX/glTF/OBJ; ONE 1024 gradient atlas for all models, downscalable to 128 (we use 256): every model shares one texture. Closest to the painting's chunky style. |
| Quaternius Stylized Nature MegaKit https://quaternius.com/packs/stylizednaturemegakit.html | CC0 | 40 trees, 35 plants/flowers, 27 rocks, grass, bushes | Free "Standard" ~60-70% of it; Ghibli-like; leaves may use alpha textures: prefer solid-leaf models (transparency costs). |
| Quaternius LowPoly Crops Pack https://opengameart.org/content/lowpoly-crops-pack | CC0 | 100+ crops in 5 growth stages | The garden's carrots/cabbages/growth states. FBX/OBJ/Blend. |
| Kenney Nature Kit https://kenney.nl/assets/nature-kit (licence: https://kenney.nl/support) | CC0, no attribution | 330 files: trees, rocks, plants, fences, camping props | Very low poly, flat colours; good filler. Kenney Food Kit / Furniture Kit for small props. |
| KayKit other packs https://itch.io/c/5146693/kaykit | CC0 (check each page) | furniture, restaurant, adventurer props | Same gradient-atlas style as the Forest pack: mixes cleanly. |
| Poly Pizza https://poly.pizza | per model: CC0 or CC-BY [?] | single props (lantern, bucket, boat) | Check each model's licence line; CC-BY needs a credit. |
| Roblox Creator Store | per asset | anything | Read every model for scripts before use; prefer the verified "Roblox" creator. No specific stylized pack was verified. |

- [V] Import: File > Import 3D takes .fbx, .obj, .gltf/.glb; `Scale Unit` sets the file's units; File General
  `Anchored`; turn OFF "Upload to Roblox" while trying things; "Merge Meshes" makes one MeshPart; avoid "Make Double
  Sided" (costly); glTF adds an extra Model layer per mesh; vertex colours are kept
  (https://create.roblox.com/docs/art/modeling/3d-importer). A mesh may not exceed 20,000 triangles
  (https://create.roblox.com/docs/art/modeling/specifications). [G] These packs are in metres (1 stud ~ 0.28 m):
  import in metres, then scale by the LONGEST side to our kit sizes; keep our 150-450 triangle prop budget; shrink the
  shared atlas to 256 before upload; put the pack's credit and licence in `docs/kit/README.md`.

### 6. Composition of a small cozy diorama (from the paintings)

- [G] Each area is an ISLAND: a clear rim (stones, a soft raised grass edge) that separates it from the lawn; nothing
  important outside it. Smaller and denser beats bigger and emptier: our pond area had more empty lawn than content.
- [G] Layers: one hero (the dock), 2-3 secondaries (lantern post, bucket, toolbox), then fillers (tufts, flowers,
  stones) at EVERY base; sizes about 3:2:1; odd-number clusters (3, 5, 7); triangle arrangements, not rows.
- [G] Tall things at the BACK corners (lantern post, reeds, a bush) frame the area; low things in front so the
  top-down camera sees in. 30-40% open ground left for play and readability.
- [G] Value: darkest values at the bottoms (grooves, blob shadows, dark grass rims), lightest on top faces; one warm
  light accent (the lantern, the only Neon), one red, one blue; white flowers sprinkled as sparkle.
- [G] Shape language: chunky, slightly oversized, rounded tops; no thin poles or sharp spikes unless they read as
  silhouettes (the fishing rod).
- [G] Camera: the paintings are drawn from ~35-45 deg above with a long lens; a narrower FieldOfView (45-50 instead
  of 70) gives that diorama look with less distortion. Use it for the judging shots; whether the game camera changes
  is a design decision.

### 7. Open-source tools

- `boatbomber/WindShake` (MIT) https://github.com/boatbomber/WindShake: foliage sway (section 3).
- `Chrrxs/robloxstudio-mcp` (see Tools above): scene analysis and memory tools; read before running.
- Poisson-disk scatter: `kchapelier/poisson-disk-sampling` (MIT) as reference for our own Luau version.
- [?] No maintained open-source stylized lighting module or outline module was found (searches on GitHub and the
  DevForum turned up only paid preset packs): our preset above is the module. Paid packs (BuiltByBit "Advanced Custom
  Lighting Presets") were not considered.

### Do this first (the 8 changes most likely to lift our scenes)

1. Apply the "sunny storybook" Lighting preset (section 1): side sun, lilac fill, `EnvironmentSpecularScale` 0,
   light haze, small saturation/contrast lift.
2. Replace the photographic terrain grass with a flat or hand-drawn MaterialVariant in the palette green, and paint
   a darker-green rim round every prop base, fence and the pond.
3. Turn the pond cartoon: part water (deep centre, light rim) or terrain water with Reflectance 0.08 and tiny waves,
   then ring it with 6-12 mossy boulders, reed clumps and 3-5 lily pads.
4. Shrink each area into a tight diorama island: hero + 2-3 secondaries + fillers at every base, odd clusters, 30-40%
   open ground, tall pieces at the back corners.
5. Build a small filler kit (3 grass tufts, 3 flowers, 2 pebbles, 30-80 triangles each) and scatter 150-300 per area,
   instanced, no collision or shadows.
6. Rebuild the dock and wooden props from planks with dark grooves, value jitter, chunky posts with rope rings; give
   1-2 hero models a dark-brown Highlight outline (or a baked inverted hull in kit meshes).
7. Replace primitive and failed generated props (ball trees, card-like reeds) with CC0 kit models: KayKit Forest,
   Quaternius Stylized Nature, Quaternius Crops for the garden; shared atlas at 256.
8. Opaque blob-shadow discs under every prop (reads at shadow-less quality levels), WindShake sway on reeds and tall
   flowers only, and judge with a 45-50 FOV camera at ~40 degrees.
