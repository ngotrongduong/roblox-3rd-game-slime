# A shared VFX library for the owner's Roblox games: research (2026-11-06)

Read-only research. Nothing was edited, downloaded or installed. Tile Smash (`C:\new roblox`) and Table Titans
(`C:\table-titans`) could NOT be read this session: they are outside the allowed folders
(`permissions.blockReadsOutsideWorkingDirectories`), so that part relies on memory notes.

---------------------------------------------------------------------------------------------------------------------

## PART A. What already exists

### A1. Egg Heist (`C:\roblox 2nd game`): the richest effect system

**The big picture.** Egg Heist already has, in effect, a VFX library inside one game:
- **23 effect packs** as rbxm in `assets/Vfx/` (aura_pack, thunder_aura, Anime, Auras, Beams, Big, Heads, IceKit,
  vfx_pack, v_Beamy, v_Complete, v_Electro_Vfx, v_Explosion, v_Explosion2, v_FloorOn, v_Folder, v_General, v_Model,
  v_SideBlast, v_SwordInGround, v_TParticles, v_WindV2, v_the_beutiful_fire). About 335 textures. These are free
  Creator Store packs from other creators in the owner's inventory, rebuilt with no scripts by `tools/import_vfx.luau`
  + `tools/vfxlib.luau` (only ParticleEmitter/Beam/Trail/lights copied; holders remade as plain Parts/Attachments; names
  that look like another game or a brand are refused; caps of 300 holders / 600 effects).
- **Effects are DATA that points into the packs**: a piece is `{ source = "Anime/Fire-01/Main", pick = {"Fire"},
  color/role, fit, rate, life, speed, art, drift, ... }`. Shared builders read the pack emitter, clone it, refit it,
  recolour it, set the budget, and clean it up.
- **Shared engine** (all plain Luau, tested in Lune with a fake Roblox):
  - `src/shared/PetVfx.luau` (770 lines): pack reader (`emittersAt`, `find`, `pathOf`, `catalog`), the
    **area budget** (what costs is the AREA painted: rate x life x size^2, `MaxArea`), `limit` (shrinks size down to
    `MinShrink` then cuts the count), `glow` + the **BlackBacked** list (pack textures drawn on black: always additive,
    dim by Brightness, else they show dark squares), rainbow colours, `attachEffect`.
  - `src/shared/TrailBuilder.luau` (506) and `src/shared/MountFxBuilder.luau` (1272): one folder on the host, an
    invisible welded `Carrier`, `attach / detach / handleOf / update / burst / measure`.
  - `src/shared/FxQuality.luau` (47) + `Config.FxQuality` + client `FxQualityPass.luau`: Low/Medium/High multiply
    rate, count, distance, lights, "full" slots; default from the device (a touch phone on Automatic = Medium).
  - `src/client/FxUtil.luau` (32): a local folder and a look-only part (came from Tile Smash).
  - Client `DebugEffects` = the **Effects lab** (F2 > Effects): list every pack emitter with a code ("A12"), stack up
    to 6, tint, size, rate, show on me / on a trail / on a pet of 5-20-60 studs, compare with what ships, copy the
    stack as text ("Crimson = A12 + A31(tint coral) + B4"). This is the seed of the library's showroom.

**Inventory of effects (what a library could lift):**

| # | Family (module, data) | Items | Kind | Built how | Textures / assets | Lift as data + one builder? | Cost |
|---|---|---|---|---|---|---|---|
| 1 | Mutations (`PetVfx.Effects`) | 9: Shiny, Golden, Blazing, Frozen, Electric, Lunar, Shadow, Admin, Rainbow | pet aura | data -> `PetVfx.attachEffect` | pack emitters (Anime/Stars-01, Shiny-01, Fire-01..03, Auras/RNG-Aura-02 "Stars" 17087151546, v_Beamy "15" 8189517327, thunder_aura bolts, aura_pack Main Auras); Frozen uses ChatGPT `fx_snowflakes` 131500085377698 | YES, cleanest family | <=6 emitters, <=40/s, <=80 alive, <=900 st^2 per pet, 1 light |
| 2 | Egg rarity (`PetLooks.EggVfx`) | 7: Uncommon..Divine, each grander | glow/aura | same as 1, colour "catalog" = rarity | same stars, twinkles, Shiny glow/rays, aura_pack core rings | YES | 4..~30/s, light from Legendary |
| 3 | Bat by zone (`PetLooks.BatVfx`) | 8: Woods, Shore, Dunes, Jungle, Peaks, Reef, Volcano, Valley | weapon aura | same as 1 (+`free` layers) | packs | YES | `Config.BatVfx` |
| 4 | Treadmill (`PetLooks.TreadmillVfx`) | 1 set | machine | same as 1 | packs | yes | small |
| 5 | Trails (`TrailLooks` + `TrailBuilder` + `TrailFx`) | 8: Grey, Green, Blue, Purple, Golden (ribbon bands), Crimson flame, Galaxy stars, Aurora curtain | trail | data -> builder; bands = `Trail` instances with `STREAKS` textures, layers = pack emitters, `accents`, `fallback` | streaks: mist 10365550877, wisp 9541055154, slash 15412407507, crackle 12781800668; sparkle 17087151546, fire flipbook 4x4 16676455805, smoke 14595543880 | YES, complete contract (`docs/contract/trails.md`) | <=7 emitters, <=80/s, <=90 alive, <=240 st^2, <=3 bands, light 16 st |
| 6 | Mounts (`MountLooks` 3202 lines + `MountFxBuilder` + `MountFx`) | 14 signatures (Raccoon, Wolf, Boar, Lion, Wyvern, Mama Bear, Giant Crab, Manticore, Feathered Serpent, Yeti, Kraken, Magma Golem, Elder Drake, Prism Hydra) x 8 layers (eyes, shell Highlight, aura, ground sigil, orbit wisps + ribbons, stride footfalls/streaks, light, moments) + 4 moments (summon, land, roar, takeoff) | full "show-off" set: aura, sigil, orbit, trail, burst | data -> builder; palette core/accent/spark; `drift` fall/rise/back/hang; anchors body/feet/above/head/crown | packs + OWN pictures per mount: `fx_mot_<id>` 2x2 motif sheet, `fx_sig_<id>` sigil, `fx_print_<id>` footprint (in `Art.Images`, many still id 0) | YES but big; the pieces (sun halo, bee orbit, snowfall above, cooling lava print, rune rings) are great standalone items | heavy: <=30 emitters, <=260/s, <=3000 st^2, 7 ribbons; moments <=160 particles |
| 7 | Boss skills (`BossSkillFx` 1210 lines, `Shared.BossSkills`) | 8 bosses x 3 = 24: Ground Pound, Bear Charge, Roar, Pincer Crush, Bubble Barrage, Shell Guard, Tail Spikes, Pounce, Sandstorm, Venom Spit, Tail Sweep, Serpent Dash, Ice Spikes, Snowball Barrage, Frost Roar, Tentacle Slams, Ink Cloud, Whirlpool, Meteor Rain, Lava Fissure, Eruption, Fire Breath, ... | skill: telegraph + impact | code per skill, pools, uses `PetVfx` packs + flat ground sprites | packs | partly: telegraph ring + impact burst are generic; each skill's choreography is code | MAX_BURSTS 32, 6 emitters each |
| 8 | Follower hits (`FollowerFx`) | 9 elements: Physical, Fire, Ice, Water, Nature, Light, Shadow, Storm, Earth | hit / cast | table {cast source, impact source, colour} | Anime/Slash-01, Slash-Impact-01, Fire-Slash-01, Water-02, Splash-01, Smoke-01, Crack-01, Shiny-01, Big/Lighting-01, v_FloorOn | YES, tiny table already | one Emit each |
| 9 | Reward bursts (`BurstFx` 539, `Config.BurstVfx`) | 12 kinds: sell, fuse, claim, purchase, ready, setdown, drop, grab, hit, dizzy, trapset, snap | burst | invisible part + cloned pack emitters, `Emit` once, destroy | Anime/Stars-01 1851669703, Shiny-01 1053548563, RNG-Aura-02 stars, v_Beamy twinkle | YES | alive 3, 4 emitters, 40 particles |
| 10 | Other moments (code modules) | HatchShowFx (rare hatch), BossWakeFx, ChaseFx (screen: camera, speed lines, vignette), AlertFx (screen flash), ChestFx, RewardFx (UI picture flights), SlashFx, SwingFx (bat swing trail + hit sparks), DashFx (wind streak), AdminStrikeFx (green lightning), HologramFx (Highlight + scan line + falling code), AbuseFx, RagdollFx, MachineWorkFx, PortalFx, RealmFx, PlaceAtFx (ghost floor ring), TreadmillFx, RainbowFx | hatch, skill, hit, screen, world | code per moment, all on packs | packs | ideas + small pieces; screen ones are game-specific | each capped |
| 11 | Weather (`WeatherFx` 881, `NightFx` 464) | snow, rain, storm (flash + pack bolt Beam), rainbow (7 Beams curved) | world | code | packs | rainbow arch and bolt are liftable | owner removed ambient zone life: do not port as ambient layers |

`src/shared/Mod.luau` is the moderation menu, not effects. `Catalog.luau` / `Pictures.luau` / `Art.luau` are id tables
(53 `fx_*` keys in `Art.Images`).

**Docs worth carrying:** `docs/mounts/fx_design.md` (layers, palettes, and the 2026-10-25 owner rule "each one its own
form and design, no repeats, even two of one element": own pictures + own behaviour + own light), `docs/contract/trails.md`,
`docs/contract/art.md` ("Effect packs and the effects lab", "Effects quality"), `docs/visual-experience/README.md`
(earlier outside research and decisions).

**Global skills** (`C:\roblox 2nd game\tools\agent-skills\`, installed by `tools\install_skills.ps1`):
`roblox-vfx-craft` (one SKILL.md, 82 lines: direction, phases, engine facts, runtime rules, acceptance),
`roblox-creature-rigging`, `roblox-creature-animation`, `blender-image-to-3d`. No VFX references folder yet.

### A2. Goo Lineage V2 (`C:\Roblox 3rd game`)

| Effect | Where | Items | Kind | Built how | Textures | Liftable |
|---|---|---|---|---|---|---|
| Fight marks | `src/client/FightFx.luau`, `Config.Zombies.View.Fx` | 7 styles: attack (burstShock + moteShock), defence (holyHit + sparkStar), speed (slashArc, laid along the blow), hp (shockwave), rotten (biteMarks, death burst + ringShock), toxic (acidSplat, acidDrop, spat gooBlob, burstAcid, ringAcid), plague (clawMarks, spore, burstArcane, ringArcane); plus crit sparks, goo drops of the body, death ring, dodge after-images, fall/cheer stars | hit, projectile, death | data table (Styles) + one module; caps MaxMarks 14, MaxGoo 48, MaxImages 12 | 21 owner battle textures uploaded 2026-11-03 (ids in Config, e.g. burstShock 133346055977942, slashArc 95547681540742, holyHit 123273947779821, ringArcane 70489654789239, healCross 110992077814805); never recoloured | YES: owner's own art, already data |
| Hatch reveal | `src/client/HatchReveal.luau`, `Config.HatchFx` | 4: Plain, Dual (gold sunburst + 2-colour stars), Material (prism flash), Secret (arcane) | reveal | anticipation (shake, light) -> flash -> picture -> glitter -> decay, all numbers in Config | sparkle (engine `sparkles_main.dds`), star 106004463491821, sunburst 123273947779821, prism 94188471939456, arcane 75506448951291, arcaneStar 118302010408844 | YES (the engine sparkle should become a pack texture) |
| Dish buff | `src/client/SlimeBuffs.client.luau`, `Config.SlimeBuffFx` | 4: attack stars spin up, defence shields breathe, speed bolts thrown back, hp hearts float | small aura | data + one loop; rarity multipliers common..epic | owner's stat icons (`Config.Ui.Icons`) | YES |
| Area upgrade | `src/client/UpgradeReveal.client.luau`, `Config.UpgradeFx` | 1 (pieces fade in, outline, 90+40 sparkles, dust, message) | reward / construction | data + module | sparkles, dust | YES |
| Effects LOD | `src/client/EffectsLod.client.luau`, `Config.Perf` | manager | LOD | emitters off beyond EmitterStuds, lights beyond LightStuds, checked CheckHz times a second | - | YES, goes in the runtime |
| World emitters | `OwnerKit.CampFlame` (from "Realistic Fire VFX" 12136850996, scripts removed), `server/DungeonPortal` (4 emitters), `server/VillageFountain` (3), `client/WorkMoves` (water drops), `ArenaTitles`, `ZombieFight`, `Village` | ~6 | world | parts in kit / code | free store textures | CampFlame and the portal yes |

**The owner's ORIGINAL web game designs (the biggest untapped source, `docs/reference/04-vfx-animation.md`):**
- **16 fancy auras over 15 archetypes** (§5): Radiant Sun / Void, Starlight orbit, Blossom and Blizzard fall, Aurora
  Sky Veil, Night Sky, Rain Veil, Autumn Whisper, Firefly Glade, Encrypted Code Rain, Thunderstorm, Static Charge,
  Butterfly Flutter, Hellfire meteors, Blazing Ascendant. Each with its own motion rules and owner vetoes.
- **17 wings** (§6): fairy, ember, sun, void, starlight, blizzard, aurora, blossom, hellfire, nightsky, rain, autumn,
  firefly, coderain, thunder, electric, butterfly; two flight styles (Bird membrane, Butterfly clap) with exact curves,
  glow pair posed by the SAME bones, per-wing mote art and behaviour, Roblox build notes.
- Element skill FX (§8.5), world bosses (§11), phone budget (§15).
- Art present in `reference/goo-lineage-web/assets`: `fx-aura-rays/halo-{sun,void}`, `fx-aurora-curtain-a/b`,
  `fx-blaze-{glow,ring,tongue,wisp}`, `fx-bubble`, `fx-comet-star`, `fx-firefly`, `fx-hex-ring`, `fx-meteor`,
  `fx-rain-cloud/streak`, `fx-snowflake`, `fx-storm-cloud`, `fx-leaves/00-05`, `fx-petals/00-05`, 55 `battlefx-*`.
  Missing: `fx-bolts`, `fx-static`, most `fx-glyphs`, `fx-wings`, all `equip-wings-*` art.
- Vetoes that a library must be able to respect (tags, not code): no in-world rarity glow; no ground disc under auras
  (except Code Rain); no plain colour rings; the owner's art never recoloured; NORMAL blend for fire and aurora on a
  bright map (additive whites out or vanishes); electric wings no sparks; butterfly wanders, not circles.

**Project skills touching effects:** `art-pipeline` (effects come from art; port `import_vfx.luau` when the first pack
arrives), `chatgpt-art` (proven 2026-11-06: icon sheets, textures, flipbook sprites through the browser pane,
magenta keying, `prepare_icons.py`, upload through Studio), `prop-craft`, `studio-build` (LESSONS, RESEARCH),
`perf-profile`, `asset-audit`.

### A3. Tile Smash and Table Titans

Not readable this session (outside allowed folders). From memory notes: Tile Smash gave `FxUtil` (already in Egg Heist)
and `MusicController`; Table Titans holds Bone.Transform creature motion, no known effect system. Nothing to lift for
the VFX library; check once with `/add-dir` if wanted.

### A4. Counts

- Egg Heist: ~93 named effect items in data (9 mutations, 7 egg rarities, 8 bats, 8 trails, 14 mount signatures,
  24 boss skills, 9 follower elements, 12 burst kinds, ~2 treadmill/fuse) + ~20 code-only moment modules + 4 weather
  looks; 23 packs / ~335 textures; 4 shared engine modules + an effects lab + a pack importer.
- Goo Lineage: ~20 items built (7 fight styles + 6 fight extras, 4 hatch reveals, 4 buffs, 1 upgrade reveal,
  ~3 world emitters) + 1 LOD manager; 21 owner battle textures + 6 hatch textures uploaded; 33 owner designs on paper
  (16 auras, 17 wings) with art partly present.

---------------------------------------------------------------------------------------------------------------------

## PART B. Outside resources

| # | Resource | URL | Licence | What it adds | Quality signal | Safe? |
|---|---|---|---|---|---|---|
| 1 | nonlooped/roblox-suite, skill `roblox-vfx` | https://github.com/nonlooped/roblox-suite (SKILL: raw.githubusercontent.com/nonlooped/roblox-suite/main/roblox-vfx/SKILL.md) | MIT | Engine facts, flipbooks, one-shot bursts, marker-triggered effects, distance culling, the overdraw cost model (rate x size x opacity x overlap), how to measure (Stats > GPU > Fill Rate, Render > Overdraw, lowest/highest Editor Quality Level); references `particle-emitter-properties.md`, `shapes-flipbooks-and-advanced.md` | 11-28 stars, updated Aug 2026, 97 commits, eval report 2026-07 | YES: text only; already the basis of `roblox-vfx-craft`; re-read the two references for the upgrade |
| 2 | Kenney Particle Pack | https://kenney.nl/assets/particle-pack (also opengameart.org/content/particle-pack-80-sprites) | CC0 | 80 sprites at 512 px, greyscale/white for tinting: flames, smoke, magic, sparks, stars, light, traces, twirls; the base texture set for a library that does not depend on other creators' packs | Kenney is the reference CC0 source; v1.0 2018 (static, fine) | YES (owner approved Kenney 2026; download only via the site's own button, keep in `art/library/`; upload under the owner's account) |
| 3 | CC0 flipbooks: Unity free VFX image sequences + OpenGameArt CC0 effect packs | https://unity.com/blog/engine-platform/free-vfx-image-sequences-flipbooks ; https://opengameart.org/content/magic-and-smoke-effect ; https://opengameart.org/content/fire-smoke-animations | CC0 (as stated on each page; verify per file) | Real smoke, explosion, fireball, magic flipbooks to repack into Roblox grids (8x8 at <=1024 px, padded) | Unity official (2016); OGA entries vary | YES for textures (no scripts in them); check each page's licence line before download (needs owner OK to download) |
| 4 | SyphoDev-yt/roblox-ai-skills, skill `roblox-vfx` | https://github.com/SyphoDev-yt/roblox-ai-skills | custom "free licence": free use and change, no selling, must link the author's YouTube when shared | Design ideas: a HARVESTER that builds a searchable library from free packs you own, a browser simulator of Roblox VFX, local texture generation (2,000+ textures by Python), Blender VFX meshes, export as a Studio kit | 108 stars, 23 forks, only 5 commits | IDEAS ONLY: do not install (needs Python deps + Blender pipeline, a non-standard licence, many agents); the harvester idea = Egg Heist's `import_vfx` + lab, which we already own |
| 5 | Roblox Creator Hub docs | https://create.roblox.com/docs/effects/particle-emitters ; /docs/effects/beams ; /docs/effects/trails ; https://create.roblox.com/docs/projects/assets/privacy | Roblox docs | Official limits: 400/s desktop, 100/s mobile per emitter, lifetime <= 20 s, flipbook 2x2/4x4/8x8/Custom, <= 30 fps, more memory (low-memory phones may drop them), reuse textures, LightEmission 1 hides black, Brightness only with LightInfluence 0, Squash for streaks, Sphere/Cylinder shapes only on parts. **Asset privacy**: images/meshes stay Open Use unless the creator turns Asset Privacy on; then new uploads are Restricted and other experiences need a grant | official | YES |
| 6 | VFX Editor (VirtualButFake) | https://github.com/VirtualButFake/vfx-editor (devforum.roblox.com/t/vfx-editor-all-your-vfx-needs-in-one/3103467) | free on GitHub ($4.99 on the Marketplace); licence not verified | A Studio PLUGIN for authoring: number/colour sequence editors with easing and Bezier, texture storage with flipbook support | active DevForum thread | Maybe as an authoring tool for the owner/Claude in the showroom; plugin, not runtime; read its licence first; never ship its code |
| 7 | Lumina (Mqxsyy) | https://github.com/Mqxsyy/Lumina | MIT | Node-graph particle system API | 30 stars, 202 commits, "heavily WIP, not for production" | SKIP for now (second particle engine, against the rules) |
| 8 | Effect Design Suite (MiaGobble) | https://github.com/MiaGobble/Effect-Design-Suite | LICENSE file, type not shown | Plugin: emit count/delay/duration, Oklab colour editor, ~5,800 "open-source" flipbooks/textures of unnamed origin | 1 star, July 2026 | SKIP the textures (origin unknown); emit-attribute convention is an idea |
| 9 | "2 Free Realistic Flipbook Particle Explosions" | https://devforum.roblox.com/t/2-free-realistic-flipbook-particle-explosions/3035597 | author: any use, no credit | Two realistic explosion flipbooks | small | Textures only, if the owner wants realism (most of his games are cartoon) |
| 10 | Mesh Flipbook Pack by Pew | https://devforum.roblox.com/t/open-source-mesh-flipbook-pack/3635032 | none stated | Mesh flipbooks (dissolve, shockwaves, smoke balls) + a Flipbook module, uses VortexFX | May 2025 | SKIP (no licence, carries scripts) - the TECHNIQUE (a mesh whose texture is swapped frame by frame) is rewritten ourselves |
| - | Skip outright | Forge (zilibobi, paid itch), Sine VFX (paid), BuiltByBit packs (paid, some "RNG aura" packs named after a genre/other games), PartEmitter (GPLv3), VortexFX (licence unknown, a second engine), `.pages.dev` "Roblox particle texture pack" sites (SEO spam) | | | | NO |

**Techniques for high-end VFX on cheap phones (to write into `roblox-vfx-craft` and the library runtime):**
1. **Flipbooks** for fire, smoke, explosions, magic: one 1024 atlas, 4x4 (256 px frames) or 8x8 (128 px), padded
   2-4 px, `FlipbookMode` OneShot for bursts / Loop for auras, `FlipbookStartRandom`; preload with
   `ContentProvider:PreloadAsync` before the moment; reuse a few atlases across many effects; Low tier swaps to a static frame.
2. **Bursts by `:Emit(n)`** on emitters with Rate 0, pooled per effect kind (reset every property on reuse); the server
   sends one event, each client draws.
3. **Area budget, not count** (Egg Heist's PetVfx): cap rate x life x size^2 per host, shrink to a floor then cut count.
4. **Beam tricks**: `TextureSpeed` for flowing energy, `TextureMode` Wrap/Stretch, `FaceCamera`, `Segments` + `CurveSize0/1`
   for arcs (rainbows, lightning, ribbons), width curves; two Beams crossed for a volume look; a bolt = one textured Beam.
5. **Mesh VFX**: low-poly shockwave rings, slash arcs, domes, swirls (Blender, a few hundred tris) with a texture and
   tweened Size/Transparency; texture scroll through a `Texture` on an unwrapped MeshPart; very cheap per pixel vs
   stacked soft particles. Avoid runtime EditableMesh/UV edits and stacks of offset Decals (measured slow live).
6. **Additive on black vs normal with alpha**: black-backed art must be LightEmission 1; fire/aurora on a bright map
   need NORMAL blend + a low-alpha additive bloom (Goo Lineage vetoes 19-20).
7. **LOD**: one loop a few times a second for all hosts; full < ~40-60 studs, half rate to ~100-130, off beyond / off
   screen; only the nearest N hosts get particles, nearest M a light; Highlights <= ~6.
8. **Quality tiers** Low/Medium/High from the device (`FxQuality.default`), Low drops secondary layers and lights.
9. **Squash + VelocityParallel** for streaks; `LockedToPart` for auras that must follow; `ZOffset` layering;
   `Acceleration`/`Drag` for drift (fall, rise, back, hang).
10. **Bone-attached** wing/tail particles: attachments on bones move with the animation for free.

---------------------------------------------------------------------------------------------------------------------

## PART C. Recommended design of the library

### C1. Where it lives

A separate git repo **`C:\roblox-vfx-library`** (GitHub `ngotrongduong/roblox-vfx-library`, **private**: it holds
other creators' pack rbxm and asset ids; Personal Arena's "public for free Actions" reason does not apply, Lune tests
run locally). If it must be public, keep `packs/` git-ignored.

```
roblox-vfx-library/
  README.md                      how a game uses it, the rules (art not shapes, own design per item, budgets)
  CATALOG.md                     GENERATED: one row per effect (id, name, kind, tags, tier, cost, preview)
  catalog/index.html             GENERATED gallery: GIF cards, filters by kind / tag / cost / game; publishable as an Artifact
  default.project.json           rojo: builds the showroom place and the package
  src/VfxLib/                    THE RUNTIME (one copy, vendored into games)
    init.luau                    attach(host, id | def, opts) -> handle; play(id, at, opts) one-shot; stop; measure
    Builder.luau                 the one builder (from PetVfx + TrailBuilder + MountFxBuilder): emitters, beams,
                                 trails, ribbons, mesh pieces, light, highlight, moments
    Budget.luau                  area / rate / alive / size limits, `limit`, per kind (pet, trail, mount, burst)
    Quality.luau                 Low/Medium/High (FxQuality), game can plug its own setting in
    Lod.luau                     one loop: distance, nearest N, lights, off screen (EffectsLod + TrailFx guard)
    Palette.luau  Anchors.luau   roles core/accent/spark/keep, rainbow; anchors body/feet/above/head/crown/tip...
    Textures.luau                key -> rbxassetid per creator account (+ BlackBacked set, flipbook grid)
    Pool.luau                    burst pools (only if measured to help)
  effects/
    aura/<id>.luau  trail/<id>.luau  wings/<id>.luau  hit/<id>.luau  burst/<id>.luau  reveal/<id>.luau
    skill/<id>.luau  world/<id>.luau  buff/<id>.luau
  previews/<id>.png  previews/<id>.gif     shots from the showroom (real camera distance, start/peak/fade)
  textures/src/<key>.png                    the source pictures (CC0 / owner / ChatGPT), with LICENCES.md
  textures/ids.luau                         uploaded ids per account (Mue_you; others if Asset Privacy is on)
  packs/*.rbxm                              the owner's rebuilt packs (from Egg Heist assets/Vfx), script-free
  meshes/*.fbx|*.rbxm                       low-poly VFX meshes (rings, slashes, domes)
  showroom/                                 scripts that build the showroom place through Studio MCP
  tools/  check.ps1 (stylua, selene, lune, rojo)  bake.luau  catalog.luau  shoot.luau  import.ps1  import_vfx.luau
  tests/  every effect validates; budgets; no texture key shared between items; every id has a preview
  skills/ vfx-library/SKILL.md (installed globally by install_skills.ps1 like the other portable skills)
```

### C2. One effect = one data module

```lua
-- effects/aura/ember_crown.luau
return {
  id = "aura.ember_crown", name = "Ember Crown", kind = "aura",
  tags = { "fire", "rising", "legendary", "no_ground_disc" },  -- a game filters by its vetoes
  host = "pet",                       -- pet | character | mount | weapon | world | ui-free
  palette = { core = {255,106,31}, accent = {220,30,40}, spark = {255,230,170} }, tintable = true,
  blend = "normal+bloom",             -- additive | normal | normal+bloom (bright maps)
  pieces = {                          -- BAKED: real emitter properties, no pack needed at runtime
    { at = "body", role = "core", emitter = { texture = "fire_tongue_4x4", flipbook = "4x4", rate = 6,
      life = {0.6, 0.9}, size = {{0,1.2},{1,0.2}}, transparency = {{0,1},{0.15,0.2},{1,1}},
      speed = {1, 2}, drift = "rise", lightEmission = 0.6, zOffset = 0.5 } },
    { at = "crown", role = "spark", emitter = { texture = "ember_dot", rate = 4, ... } },
  },
  light = { role = "core", brightness = 1, range = 10 },
  moments = { start = { ... burst pieces ... } },
  cost = { emitters = 2, rate = 10, alive = 9, area = 120, lights = 1, tier = "cheap" },  -- checked by the tests
  textures = { "fire_tongue_4x4", "ember_dot" },
  source = { from = "Egg Heist PetVfx.Blazing", art = "pack Auras/Fire-Aura-01 16676455805", licence = "free store pack, scripts removed" },
  preview = "previews/aura.ember_crown.gif",
}
```

Key decision: **bake, don't point**. Egg Heist points into pack rbxm at runtime (`source`/`pick`), so every game must
ship the packs. The library's `tools/bake.luau` reads a chosen pack emitter (from the lab's stack code "A12 + B4") and
writes its properties as plain data with the texture id; a game then needs only the runtime and the ids. The pack
reader stays in the library for authoring.

Cost tiers (phone): **cheap** <= 2 emitters, <= 20/s, no light; **mid** <= 6, <= 60/s, 1 light, <= 900 st^2;
**heavy** (mounts, bosses) up to the MountLooks budget and only for the nearest few.

### C3. The showroom (Studio place built by script)

`showroom/build.luau`, run through Studio MCP in a work place (`showroom/Showroom.rbxl`, built, never hand-edited):
halls by kind, every effect on a pedestal with an English sign (id + name + tier): auras on a slime, a pet and an R15
dummy; trails on a dummy running a loop track; wings on a rig; hits on a dummy struck every 2 s; bursts and reveals
replayed every 3 s; skills on a ground pad. A board switches Low/Medium/High and shows live stats (particles, emitters,
area). `tools/shoot.luau` walks the camera to each pedestal at the game's real camera distance and captures start / peak
/ fade (PNG) and a frame strip stitched into a GIF; `tools/catalog.luau` rebuilds `CATALOG.md` and `catalog/index.html`.
The owner browses the gallery (or walks the showroom), says "this one", Claude imports it.

### C4. How a game takes an effect

**Vendored copy** (recommended): `& "C:\roblox-vfx-library\tools\import.ps1" -Game "C:\Roblox 3rd game" -Effects aura.ember_crown,hit.shock`
copies `src/VfxLib` (with a `VERSION` file) and the chosen effect modules into `<game>/src/shared/VfxLib/`, plus their
texture ids. The game commits them, so rojo, Lune tests, CI and Codex work with no sibling folder. Re-running updates.
- Wally: overkill (a registry to publish to, and the owner's games are not Wally projects).
- rojo `$path` to `../roblox-vfx-library`: breaks GitHub Actions / Codex / ChatGPT branches. No.
A game adapter (`VfxLib.setup{ quality = FxQuality, log = "[GooLineage]", textures = overrides }`) keeps the game's
own guide in charge. Textures: upload under Mue_you (Open Use while Asset Privacy is off; check it before relying on
ids across games; if on, grant each experience or re-upload from `textures/src`).

### C5. Skills

- **`vfx-library`** (new, global, lives in the library repo): browse (open the catalog, filter by kind/tag/tier),
  pick (show the owner 3-6 GIFs), import (run `import.ps1`, wire one call, play-test), add (moment -> reference ->
  textures -> data -> showroom shot -> cost check -> catalog -> commit), bake (lab stack -> data), retire. Carries the
  rules: art not shapes, one design per item (no recolour = new item), the owner's vetoes as tags.
- **`chatgpt-art`** (promote Goo Lineage's proven skill to global): add a VFX section: white or greyscale on black for
  additive (or on magenta for alpha), flipbook grids 2x2/4x4/8x8 <= 1024 px padded, 2x2 motif sheets, sigils, footprints;
  keep the "owner's art never redrawn" rule.
- **`roblox-vfx-craft`** (upgrade): step 0 "look in the library first"; the area budget and `limit`; black-backed rule;
  normal+bloom on bright maps; bake-don't-point; the cost tiers; the showroom shot as acceptance; techniques 1-10 above;
  a `references/` folder (engine facts, flipbook recipe, beam/mesh recipes, budgets) so SKILL.md stays short.
- `art-pipeline` / `import_vfx` stay per game; the pack importer moves into the library's tools.

### C6. The first 22 effects (ranked: value across games x ready to lift x phone cost)

| Rank | Id | From | Why first |
|---|---|---|---|
| 1 | burst.reward_glitter | EH BurstFx claim/purchase | every game pays out; cheap; already data |
| 2 | burst.coin_sell | EH BurstFx sell + GL Coin | every economy game |
| 3 | hit.shock | GL FightFx attack (burstShock + moteShock) | owner's own art, every fight |
| 4 | hit.slash_arc | GL FightFx speed | owner's art, reads at a glance |
| 5 | hit.holy | GL FightFx defence | owner's art |
| 6 | hit.acid_splat (+ spit projectile + ring) | GL FightFx toxic | a complete projectile/impact/death trio |
| 7 | hit.claw_spores (+ arcane death ring) | GL FightFx plague | owner's art |
| 8 | reveal.hatch_dual (gold sunburst) | GL HatchFx Dual | egg/gacha games all need reveals |
| 9 | reveal.hatch_secret (arcane) | GL HatchFx Secret | top-rarity moment |
| 10 | reveal.hatch_material (prism) | GL HatchFx Material | third distinct reveal |
| 11 | aura.blazing_flames | EH mutation Blazing (fire flipbooks) | flagship aura; bake from pack |
| 12 | aura.frozen_snowfall | EH mutation Frozen (own snowflake art) | already own art |
| 13 | aura.electric_bolts | EH mutation Electric | distinct motion |
| 14 | aura.lunar_halo | EH mutation Lunar (orbit halo + crescents) | distinct shape |
| 15 | aura.shadow_wisps | EH mutation Shadow | dark option |
| 16 | aura.rainbow_rings | EH mutation Rainbow | premium look |
| 17 | trail.crimson_flame | EH special trail | trails sell; complete contract |
| 18 | trail.galaxy_stars | EH special trail | |
| 19 | trail.aurora_curtain | EH special trail | |
| 20 | trail.ribbon_ladder (5 tiers grey..golden) | EH ribbon trails | one family, cheapest trail set |
| 21 | buff.stat_set (attack stars, shield breath, speed bolts, hearts) | GL SlimeBuffFx | tiny, owner's icons, any RPG |
| 22 | reveal.area_upgrade | GL UpgradeFx | any tycoon/farm upgrade |

Next wave (built new from designs on paper): **wings** from the original's 17 (start with ember = Bird style and
fairy = Butterfly style: rigged wing mesh + glow pair on the same bones + tip motes), the original's **fancy auras**
(Butterfly Flutter, Firefly Glade, Hellfire meteors, Aurora Veil, Starlight orbit), and standalone pieces of the
mount signatures (sun halo crown, bee orbit, cooling lava footprint, rune-ring sigil, fire-tornado summon) and the
boss-skill telegraph + impact pairs (ground pound shock ring, meteor rain, ice spikes).

### C7. Order of work

1. Create the repo, move in the runtime merged from PetVfx/TrailBuilder/MountFxBuilder/FxQuality/EffectsLod, with
   Lune tests (from Egg Heist's harness). 2. `bake.luau` + the first 10 items (ranks 1-10: owner art and bursts, no
   packs needed). 3. Showroom + shoot + catalog page; show the owner. 4. Ranks 11-22 baked from the packs. 5. Import
   into Goo Lineage first (it already needs auras/wings), then back-port Egg Heist when it next changes.
