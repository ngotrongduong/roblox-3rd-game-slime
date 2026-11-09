# Slime Dungeon: the other three maps (Mushroom: built; Lava: built; Ice: built)

Written 2026-11-08. The Sunny Meadow (`battle.map.meadow.png`) is built: `shared/DungeonArenaPlan`, `server/DungeonArena`,
`Config.Dungeon.Arenas.meadow`, props from `Config.LibraryKit`. This file plans Mushroom, Lava and Ice the same way, and the
code that rotates the maps each level.

**Lava, phase A done (2026-11-09).** Code: `Config.Dungeon.Arenas.lava`, `Maps.lava` (seven monsters), `MapOrder = { meadow, mushroom,
lava }`, plan kinds `pool` (claims ground, rim only, the map's six lights on the first pools of each quarter) and `vein`
(zone `floor`, claims nothing, longer and so thicker toward the rim, its thick end turned at the corner; the plan test checks
all of it), `PathStyle = "none"`, `Arenas.lava.Neon` (the kinds turned Neon `#ff6a1a` by `server/DungeonArena`) and
`Hills.Glow` (every fourth hill wears a Neon dome). Props: `art/library/converted/LavaProps.glb` (31 props, one import;
`tools/library/build_lava.ps1`, procedural ones in `make_lava.py`; 139 models placed, about 15 thousand triangles, none over
400). Slots: `round` spires `LavaSpire_1..3`; `pine` and `ruin` column clusters `LavaColumns_1..3`; `rock` `LavaBoulder_1..3`
and `Rock_1..5_Lava`; `stump` `LavaStump_1..3`; `log` rubble heaps `LavaRubble_1..2`; `pebble` `LavaPebble_1..2`; `root` black
dead snags `CommonTree_Dead_3/4_Lava`, `Willow_Dead_3_Lava`; `vein` `LavaVein_1..4` and `pool` `LavaPool_1..3` (both flat,
painted white in the middle and dark at the edge, so Neon `#ff6a1a` reads hot in the middle and cools to a crust; the vein's
long axis is +X with the thick end at -X). Monsters: Fire Newt, Ember Wolf, Phoenix (flies), Inferno Dragon (the healer: the
Bestiary Imp is not rigged, the Dragon is a flier of the Aurora Owl's motion family), Rock Tortoise, Magma Bull (mini-boss,
skill `lavastomp`), Magma Golem (boss `Guardians/Volcano`, skill `eruption`, drops 2 `ember_core`). Differences from the plan
below: the snags use the `root` slot (sized by width) instead of a new kind, rubble heaps use `log`, and the volcano hills
are a glowing dome on the existing ring of hills (no separate volcano meshes). Missing pictures: the `ember_core` icon
(`Materials.ember_core.icon = 0`, a plain tile until ChatGPT draws it) and a fire set for the skills and the Phoenix's shot
(the skills reuse the owner's battle art, `Config.Zombies.View.Skill.Looks.lavastomp/eruption`). Phase B (after the owner
imports `LavaProps.glb`): copy MeshIds and sizes into `Config.LibraryKit.Props` (names as above), then look from the player's
camera: veins and pools are already Neon by Config and the pools already carry the lights, so only judge the floor colour
`#4d4360`, the light (`Lighting`, same dusk window as the Grove) and the spire/column scale.

**Lava, phase B done (2026-11-09), three rounds in StudioTest.** The 31 props are in `Config.LibraryKit.Props` (tex "P", `at = {0,
h/2, 0}`). The Grove -> Lava swap at Next level, all seven monsters fighting, the Magma Bull's Stomp, the Golem's Eruption and
the victory panel (`ember_core` icon) were all seen; the console stayed clean. Shots: `docs/ui/dungeon/lava-r1-*` (first look,
rocks near-black), `lava-r2-*` (night light, bigger lava, smaller spires), `lava-r3-{player,corner,live}.png` (final).
- Round 1: floor `#4d4360` read black under the dusk light, the sky was teal, the lava pools too small. The rocks were pitch black:
  Roblox shows a mesh's vertex colours as stored, and `fbx_to_glb.py` had stored them as linear values (the Grove palette was
  pre-brightened to hide this). Fix: `RAW=1` stores raw sRGB (`make_lava.py raw()`, new `$lava` palette in `build_lava.ps1`),
  `LavaProps.glb` rebuilt (313520 bytes).
- Round 2: lighting is NIGHT (`ClockTime 19.5`, bright Ambient: a black starry sky, the lava and the glow domes carry the scene),
  floor `#554e66`, hills `#4a4058`, lava `Pool 11..16` (13..20 crowded the rocks below the plan test's count), `Vein 18..36`, `Tries` 80 -> 160, spires `Round 17..23` and column clusters `Pine 14..19` (fewer, so the rim stops reading as a wall).
- Round 3: hills 22 -> 26 (the green terrain gap at the horizon is nearly closed), `Veins` 5 -> 7 per corner. Reads: violet
  rock clusters in the corners, glowing veins and rim pools, a calm dark centre, the bull and golem lit by their own lava.
- (Done in round 4: the owner re-imported the rebuilt `LavaProps.glb`; its ids are in `Config.LibraryKit.Props`. Until then the
  rocks read near-black and the play test emulated the colours on the client, see studio-build LESSONS.)
- Still weak: a thin yellow-green terrain strip at the far-left horizon from the corner view, many spires on the rim, the floor
  shows the stud pattern (the owner's choice), no phone view seen.

**Ice, phase A done (2026-11-09).** Code: `Config.Dungeon.Arenas.ice`, `Maps.ice` (seven monsters), `MapOrder = { meadow, mushroom,
lava, ice }` (the four maps are all in), `Materials.frost_fang` (icon 116041071019115, in `DropOrder`), plan kind `mound` (zone
`floor`, claims nothing, drawn last and only for a map with `Arenas.<map>.Mounds`, so no other map's plan changed; broken at the
four lanes), `Arenas.ice.NeonAlpha` (a Transparency for the kinds in `Neon`; `server/DungeonArena.glowing`), folder `Snow`.
Props: `art/library/converted/IceProps.glb` (52 props, one import; `tools/library/build_ice.ps1`, procedural ones in
`make_ice.py`, the Ultimate Nature snow variants recoloured with `fbx_to_glb.py` `RAW=1 SUFFIX=_Ice` and the Ice palette; every prop at
most 420 triangles, 166 models in 131 groups placed, about 38 thousand triangles). Models slots and their props (triangles in brackets):
`mound` `IceMound_1..4` (160-240, snow drifts, 11-15 across); `pine` `IceGrove_1..4` (296-400, three frosted pines on a snow
base, 13.7 tall) and `PineTree_Snow_2/5_Ice` (420); `round` `PineTree_Snow_1/2/4/5_Ice`, `CommonTree_Dead_Snow_3/4_Ice`,
`Willow_Dead_Snow_1/3/4_Ice` (420, the bare twig look); `ruin` `IceRock_1..4` (220-348, slate masses with a snow cap, 16-20
across); `rock` `IceBoulder_1..3` (80), `Rock_Snow_1/3/4/5/6_Ice` (96-160); `root` `IceShard_1..3` (54-90, crystal shards); `glow`
`IceCrystal_1..4` (54-90, crystal clusters 6-9 tall); `bush` `Bush_Snow_1/2_Ice` (220), `IceShrub_1..2` (288-340); `stump`
`TreeStump_Snow_Ice` (220); `log` `WoodLog_Snow_Ice` (220) and `IceFence_1..3` (40-50, short snow fences); `tuft` `IceSprig_1..3`
(160, twig corals); `pebble` `IceCrack_1..4` (80-136, flat crack lines, 0.12 thick). Not used: `Rock_Snow_2` and
`CommonTree_Dead_Snow_5` (their material names are numbers, so the palette cannot reach them). Monsters: Arctic Fox, Snow
Leopard, Frost Wisp (floats), Penguin (the healer: the Aurora Owl already heals in the Meadow; the Penguin is a rigged Egg Heist
pet and a walker, a new motion family for the healers), Ice Golem, Mammoth (mini-boss, skill `tuskcharge`, a `multi` skill of
two rams), Yeti (boss `Guardians/Peaks`, skill `blizzard`, an `all` skill with a 0.7 s stun, drops 2 `frost_fang`). All seven
models are in `assets/MonsterKit.rbxm` (28 models now) and their motion modules in `src/shared/Creatures`. The two skills each
have a skill art entry, a blow style, steps (`Moves.Stand/Spread`) and a way; every one differs from every other skill's (a test
checks it). The light is a cool low-sun day (`ClockTime 8.6`, bluish ambient, `Exposure -0.3` so the near-white floor does not
burn out). Differences from the plan below: no `OwnIce*` models (the library props replace them), the crystals are the `glow`
kind and the shards the `root` kind (both Neon, Transparency 0.25, four lights), the snow mounds are meshes and not Plastic balls,
the floor cracks are flat meshes in the open band (`pebble`), the shore is one ring (`Mounds`). Missing pictures: a frost set
for the skills and the Wisp's shard (the skills reuse the owner's battle art, `Config.Zombies.View.Skill.Looks.tuskcharge/blizzard`);
the `frost_fang` icon exists. Phase B (after the owner imports `IceProps.glb`): copy the MeshIds and sizes into
`Config.LibraryKit.Props` (names as above, tex "P", `at = {0, h/2, 0}`), then look from the player's camera: crystals and shards
are already Neon and see-through by Config and four crystal clusters already carry the lights, so judge the floor colour
`#dbe9f7` and the exposure (`Lighting`), the size of the mounds against the lanes, the grove scale and whether the crack lines
read. Until the import the arena stands on `Fallback` (the valley's dead trees, pines and rocks and plain pebbles for the
cracks) and one warning names the kinds that are missing.

**Ice, phase B done (2026-11-09), three rounds in StudioTest.** The 52 props are in `Config.LibraryKit.Props` (tex "P", `at = {0,
h/2, 0}`; ids and sizes read from the owner's import), so `Fallback` is no longer used for Ice and the console shows no
missing-kinds warning. A run seen live: Lava (level 1) -> Ice (Next level) swap, all seven monsters fought (the Wisp hovers),
the Mammoth's Tusk Charge (`aim/tuskcharge`, two `hit/tuskcharge`) and the Yeti's Blizzard (`aim/blizzard`, hits on the squad)
fired, and the victory panel shows the `frost_fang` icon (`116041071019115`). The console stayed clean (only the village's two
asset-still-generating notices and Studio's own camera note). Shots: `docs/ui/dungeon/ice-r1-{player,corner}.png` (first look),
`ice-r2-{player,corner,victory}.png`, `ice-r3-{player,corner,live,boss}.png` (final; live = Mammoth, boss = Yeti, 34 studs away).
- Round 1 (as built in phase A): the engine's blue day sky with white clouds read as summer, the near hills (Tall 18-30) were
  smooth white domes that hid the rim's groves and masses, the slate rocks were few and small, the floor was fine (pale, not
  blown out at `Exposure -0.3`).
- Round 2: overcast sky. `Lighting.Clouds = { Cover, Density, Colour }` is new (`client/DungeonLight` eases the terrain's
  `Clouds`, or makes an empty one, and eases back to the place's own on any other map): Atmosphere `Density`/`Offset`/`Haze`
  barely change the engine sky, a full-cover pale `Clouds` layer does (`0.95`, `0.55`, `#f4f8ff`). The place's own
  ColorCorrection adds `+0.18` saturation under ours, so the grade is `Saturation -0.3` (was `-0.04`), `Exposure -0.2`, Ambient
  `#9fb1cc`. Near hills `Tall 9..15` (was 18..30), Far `Tall 24..38`; backdrop rows `11..16` and `15..22` tall; `Ruin 9..13`
  (was 7..9), `Rocks` and `Ruins` 3 a corner (was 2), `TinyPebbles 18` (cracks read as pale blue lines on the floor).
- Round 3: Far hills `Tall 40..56` again: at 24..38 the ridge no longer hid the teal band of the place's far sea at the horizon
  (see below). Reads: a pale ice floor with the stud pattern, white snow shore drifts, dark slate masses with a snow cap, bright
  cyan crystal clusters in the corners (four lit), frosted groves behind, a flat cool grey-white sky. The Mammoth reads brown
  against the snow, the Yeti by its blue face and feet, horns and its blue shadow; the Penguin and Frost Wisp read small at the
  player's distance (their health bars carry them).
- Still weak: a teal band (the place's far water, outside the arena) shows in gaps between the far hills from low cameras; the
  Yeti is white on white (value contrast comes from the rocks behind it, not from the floor); the overcast cloud layer shows a
  faint wave pattern at some angles; the domes still read as smooth hills, not as the painting's rock ridges; no phone view seen.
  The test copy keeps `Workspace.Scene` (the owner's import) and the new `MonsterKit` (28 models, loaded from
  `assets/MonsterKit.rbxm` by `SerializationService`), and its Config patch (`MapOrder {lava, ice}`, `MapFirstRandom false`,
  4 waves, `StatScale 0.2`) is not in the repo.

**Ice, round 4 (2026-11-09), from a ChatGPT art-director review of the round-3 shots.** The verdict: smooth domes and a thin
rim read as a field, not as a frozen arena enclosed by icy cliffs with two crystal-and-rock landmarks flanking an open fight
space. Built in two stages: new meshes in `tools/library/make_ice.py` -> `IceProps.glb` (re-imported by the owner once), then
the numbers by eye. The meshes are new names in `Config.LibraryKit.Props` (84 entries now; the whole Ice block was rewritten
from the new import, every MeshId is new, the `IceCrack_*` sizes changed):
- `IceRidge_1..5` (faceted snow ridges, 30-38 wide, 17-22 tall; slate-blue faces, snow shoulders) replace the dome balls: the near
  ring is 40 ridges (`Hills`, `Wide 30..46`, `Tall 14..28`, `Sink 0.08`), stretched from the prototype's size by `DungeonArena`
  and turned to face the arena; `IceFar_1..3` (190-210 wide, opaque pale `#b7c9d9`/`#d6e3ed` silhouettes, `Hills.Far`, 16 at
  radius 206, `Tall 54..70`, `Sink 0.12`) close the horizon over the place's own far sea and terrain.
- `IceCliff_1..4` (4-5 interlocking angular masses with snow caps, 17-26 wide, 11-15 tall) are the five `Landmarks` (two left and
  two right of the player's view, one smaller far middle), each with two snowy pines behind it and three `IceBank_1..4` snowbanks
  at its foot. `IceCrystalHero_1..4` (3-5 spires, 12-14 tall, cyan cores, light tips, not Neon) are the four `Heroes`, lit with
  the point lights (`Glow.Lights`); `IceCrystalMid_1..3` and `IceCrystalSmall_1..3` are the glow and root kinds.
- `IceFrostBush_1..3` trios in each corner (`Frosts`), `IcePatch_1..3` faint frost patches (8) and `IceCrack_1..4` thin cracks
  (7) on the floor; the `Neon` kinds are off. The bare dark trees are down to 4; the backdrop pines clump in groups
  (`BackdropClump`). The sky stays the cool grey-white cloud layer; floor `#ddebf5`.
- Yeti: its own `contact` shadow (a flat dark-blue disc 6 studs across, `Looks.ice_yeti.contact`, made by `MonsterLook`, kept
  under the monster's ground spot by `SlimeActor`); Penguin `height 3.5`, Frost Wisp `3`.
- Result (shots `docs/ui/dungeon/ice-r4-{player,corner,live,boss}.png`): the player's view is enclosed by pale and slate
  ridges, a rock landmark with a crystal hero in each third, open floor in the middle; the Mammoth and the Yeti stand out of
  the rocks behind them, the Yeti on its dark contact disc. The console stayed clean. Still weak: from the corner camera
  (outside the player's normal view) the place's green terrain still peeks over the far silhouette at one side, and a thin teal
  sea line shows at the very edge of the player's view; no phone view seen.

**Lava, round 4 (2026-11-09), from a ChatGPT art-director review of the round-3 shots.** The verdict: a purple crystal
wasteland with lava puddles, where the painting is a volcanic crater (heavy low basalt, lava as connected cracks, a brighter
neutral fight floor ringed by a darker, hotter perimeter). Rebuilt, re-imported by the owner (`LavaProps.glb`, 381464 bytes,
32 props, ids in `Config.LibraryKit.Props`, the old import and the dead-snag props gone). Shots:
`docs/ui/dungeon/lava-r4-{player,corner,live,boss}.png` (live = Magma Bull, boss = Magma Golem, 26 studs away, both read
through their own glow against the dark basalt).
- Props (`tools/library/make_lava.py`, procedural, all `inward 0`): `LavaMass_1..4` chunky basalt clusters (350-400 triangles,
  18-25 wide, 8-9 high) for the `pine` and `ruin` slots; `LavaPeak_1..3` thin 10-high peaks (`round`, scaled to 20-28, one group
  a corner); `LavaStump_1..3` short thick hex columns (`stump`); `LavaLedge_1..3` terraced ledges (`log`); `LavaPlate_1..3`
  flat fracture plates (`pebble`, 6-12 across); `LavaBoulder_1..3` and `Rock_1..5_Lava` (`rock`); `LavaFissure_1..4` (`vein`:
  a 22-28 long main channel with branches and a Y fork, thick end at -X) and `LavaPool_1..4` (`pool`: 3-5 irregular pieces,
  dark burnt bank `#211A1D`, orange `#F15A20` body, `#FFAD3D` core).
- Plan (`DungeonArenaPlan`): the lava is placed FIRST (`step 0b`): one fissure system a corner, its tip `VeinTip` 46-54 from
  the middle (nothing inside 35), the pool at its thick end, then the other pools (`Pools = { 1, 1, 2, 2 }`, six lights);
  only then the peaks, masses, rocks and ledges. Hills have two layers (`Hills` and `Hills.Far`, taller and darker behind).
  The shelf is `RimInner 70` .. `RimOuter 104`, the woods start at 108. New numbers: `PineFoot`, `RuinFoot` 0.7 (masses are
  wide), `RockPairFoot`, `StumpFoot`. Result: 4 fissures, 6 pools, 4 peaks, 8 masses, 12 rocks, 12 stumps, 7 ledges, 42 hills,
  636 parts and 274 meshes in the arena.
- Light (`Arenas.lava.Lighting`, `client/DungeonLight`): LATE DUSK `ClockTime 18.2` with a bright neutral `Ambient #e0dade`,
  `Exposure 0.35` (new, `ExposureCompensation`), no sun, so the studs show the floor colour. 18.2 gives a dark sky with a thin
  warm band at the horizon; later it is plain navy, earlier olive. A `Sky` instance made in code turned the whole sky navy
  (the place has no Sky of its own and its engine sky keeps a few faint stars), so none is made. `Stars = 0` only works in a
  place that has a `Sky`.
- Still weak: a few stars remain (no Sky in the place), the fissures read small from the player's camera because the near
  corners are behind it, the white glow behind the left peak is the sun just under the horizon, no phone view seen.

**Mushroom, phase B done (2026-11-09).** Real props in `Config.LibraryKit.Props`, dusk light tuned (ClockTime 17.82, see
`Lighting` in the Config), olive floor `#7d8742`, a live Meadow -> Grove run and all six monsters seen; shots in
`docs/ui/dungeon/mushroom-r2-*.png`. Open: thin dark roots, dark willow blobs, a phone view.

**Mushroom, phase A done (2026-11-08).** Code: `Dungeon.mapForLevel`, `Config.Dungeon.Arenas.{meadow,mushroom}`, plan
functions `stones`/`runes` and the kinds `ruin`, `root`, `glow` (`light` flag on a few), `DungeonArena.template(mapId)`,
the arena swap in `server/Dungeon.again`, `client/DungeonLight`. Props: `art/library/converted/MushroomProps.glb` (52 props,
`tools/library/build_grove.ps1`, procedural ones in `make_grove.py`); the owner imports it, then phase B copies MeshIds and
sizes into `Config.LibraryKit.Props` and judges the arena from the player's camera. The Mushroom King became the Jungle
Wyrm (the Quaternius one is unrigged); the healer is the Forest Deer. Differences from the plan below: runes and stones are
script-built parts (no texture), the giant mushrooms use the `pine` slot. The paintings are in `reference/goo-lineage-web/assets/` and are the owner's: shape and
colour only, never redrawn.

## 1. How the Meadow was done (the recipe each map repeats)

- A round bright clearing 68 studs from the middle to the invisible wall (`WallRadius`), the stud-look floor 350 studs a side,
  nothing inside `FightClear` (35) except the paths' fade and tiny ground bits.
- Four layers outside the wall: the rim (painting's corner clusters, 71-108 studs), a double ring of tall woods
  (`BackdropRows`, 112-140), a ring of matte hills behind (`Hills`), the sky. The camera sits at the rim looking in, so
  scenery 90-130 studs away is drawn about 1.4 times the painting's scale and no floor edge or sky gap may show.
- Props come from `art/library` (Quaternius / Kenney, CC0), made 500 triangles at most with `tools/library/take_fbx.ps1`
  (FBX packs, flat material colours remapped by name to the painting's palette) or `take_props.ps1` (glTF packs), uploaded
  as meshes and listed in `Config.LibraryKit.Props`. The plan is pure and tested (`tests/spec/arena_plan.luau`).
- Measured for the Meadow: 273 scenery models, 348 parts, about 70-75 thousand triangles (see "Budget" below).

## 2. Mushroom Grove (`battle.map.mushroom.png`)

What makes it read (check every shot against these):
1. A mossy olive-green clearing, darker and bluer than the Meadow; dusk light, not noon.
2. Cracked flagstone paths on the left and right axes and the top and bottom (wider than the Meadow's dirt, stones cracked
   and mossy), ending before the middle.
3. Four faint rune circles, one in each quarter, flat on the ground (a decal-like flat ring, glowing teal).
4. Corners packed with mossy ruin stones (standing slabs, a broken arch) wrapped in thick twisting roots.
5. Glowing mushrooms in blue, purple, pink in small clusters at the foot of the ruins and the roots.
6. Dark leafy bushes at the rim; very dark teal woods at the edge (vignette).
7. Centre empty and calm.

Layout: same ring plan as the Meadow (`RimInner 71`, backdrop rows) with these changes: backdrop trees are the giant
mushrooms and twisted trees, the hills are dark teal (`#1f4a3c`), the fog and sky go dusk-teal (Lighting preset per map).
Rune circles: four flat rings at radius about 45-50 in the quarters, built from the existing `Own*` rune art if it fits or one
ChatGPT texture (flat pattern, script-drawn is allowed: "Script simple art").

Props (pack / file):
- Mushrooms: `OwnMushBlue`, `OwnMushPurple`, `OwnMushPurpleSpotted`, `OwnMushPink` (WildKit, the owner's); Quaternius
  Stylized Nature MegaKit `Mushroom_Common`, `Mushroom_Laetiporus` (big shelf mushrooms for the backdrop), Ultimate Nature
  Pack mushroom-coloured material (`Mushroom_Top`, `Mushroom_Bottom` are already in `fbx_to_glb.py`'s PALETTE).
- Ruins: `OwnMossyRockStack`, `OwnJungleStoneShelf`, Ultimate Nature `Rock_Moss_2..7`, `Rock_6`, `Rock_7`;
  Ultimate Modular Ruins Pack (pillars, arch pieces) for the standing slabs and the arch.
- Roots and trees: `OwnAncientJungleTree`; Ultimate Nature `CommonTree_Dead_*` and `Willow_*` (the twisted look),
  `TreeStump_Moss`, `WoodLog_Moss`.
- Ground: `Fern_1`, `Plant_1/_7` and `_Big` (Stylized Nature MegaKit), `Bush_1/_2` tinted dark, `Pebble_Round_*`.
- Light: a few PointLights (teal / purple, range 14, brightness 1) under the glowing clusters; never a particle layer.

Monsters (roles as `Config.Dungeon.Maps.meadow`; stats copy the Meadow's role row, then the balance pass):

| Role | Monster | Source | Note |
| --- | --- | --- | --- |
| swarmer | Twigling | Egg Heist `Pets/Twigling` (already in MonsterKit) | reuse; or Cute Animated Monsters `Mushroom` (small) |
| raider / hunter | Cave Bat | `Pets/CaveBat` | flies; needs `hover` and `bob` in its Look |
| spitter / ranged | Fairy Fox | `Pets/FairyFox` | glowing spores as the shot |
| shaman / healer | Jungle Wyrm (small) or Aurora Owl | `Pets/JungleWyrm`, or `AuroraOwl` in the kit | Wyrm is a long body: scale to 4 studs |
| armoured | Totem Golem | `Pets/TotemGolem` | stone body, fits the ruins; slow |
| miniboss | Mushroom King | Quaternius Ultimate Monsters `MushroomKing` (glb) | NEEDS WORK: not rigged for our motion, so a procedural wobble like the slimes; or Egg Heist `Pets/JungleWyrm` full size |
| boss | Mama Bear | Egg Heist `Guardians/Woods` (`boss_Woods`, 48 bones) | NEEDS WORK: boss size, `height = 10` like Triceratops, `shadow = true`, check the rig scale |

## 3. Ember Lava (`battle.map.lava.png`)

What makes it read:
1. Dark purple-grey cracked basalt floor, almost flat and calm in the middle; the floor itself is the darkest thing.
2. Bright orange lava veins in cracks that grow thicker toward the corners, ending in glowing pools at the rim.
3. Chunky dark rock clusters in each corner: stacked basalt columns, tall sharp spires, round boulders.
4. Small broken basalt stumps and rubble dotted on the floor near the corners (and a few on the left and right axes).
5. No plants. Colours: near-black violet, charcoal, hot orange, a little yellow where the lava is brightest.
6. Centre empty, no paths (the paintings show open ground on the axes).

Layout: the rim ring is basalt and lava instead of woods; the backdrop is tall dark spires and a ring of low volcano
hills (dark `#2a2230`, a few with a glowing top ring). Lava: flat Neon-material slabs (orange `#ff6a1a`, thin), a few
pools at the corners only, never in the fight zone; each pool a PointLight (orange, range 18) and no particles by default
(an optional few embers "near the player, off at low effects", shown to the owner first, per the owner's rule). The floor is
the stud-look in near-black violet.

Props:
- Owner's models in WildKit: `OwnStackedBasalt`, `OwnMoltenPlateau`, `OwnEmberCrystalPatch`, `OwnMagmaCrystalCluster`,
  `OwnFiregrass`, `OwnCrystalRed`.
- Rocks: Ultimate Nature `Rock_1..7` recoloured charcoal (PALETTE override `Rock` -> `#4a4250`), tall ones `Rock_1`, `Rock_Moss_1` as spires;
  Stylized Nature MegaKit `Rock_Medium_1..3`, `Pebble_Square_*` for rubble.
- Dead trees as black snags: Ultimate Nature `CommonTree_Dead_*`, `Willow_Dead_*` recoloured near-black, few.
- Torches / braziers for mood only if wanted: Fantasy Props MegaKit `Torch_Metal`, `Cauldron`.

Monsters:

| Role | Monster | Source | Note |
| --- | --- | --- | --- |
| swarmer | Fire Newt | `Pets/FireNewt` | small, quick |
| raider / hunter | Ember Wolf | `Pets/EmberWolf` | fast, bites the weakest slime |
| spitter / ranged | Phoenix (small) | `Pets/Phoenix` | flies, fireball; needs `hover`; scale down to 3.6 |
| shaman / healer | Imp | Quaternius Bestiary `Imp` | NEEDS WORK: a Bestiary glb is not rigged for our motion; or Egg Heist `Pets/Phoenix` as healer and the Imp as the spitter |
| armoured | Rock Tortoise | `Pets/RockTortoise` | slow, high defence |
| miniboss | Magma Bull | `Pets/MagmaBull` | full size, `height = 8`, `shadow = true` |
| boss | Magma Golem | `Guardians/Volcano` (`boss_Volcano`, 48 bones) | NEEDS WORK: boss size and its lava glow (Neon parts fine); alternative `Pets/InfernoDragon` |

## 4. Frozen Ice (`battle.map.ice.png`)

What makes it read:
1. A pale blue-white frozen lake, softly cracked, the biggest and calmest clearing of the four (an oval).
2. A snowy shore all round the oval, soft white mounds with a blue shadow, rimmed by little snow fences.
3. Big snow-capped dark rocks (some with ice crystals growing through them) in each corner.
4. Blue crystal clusters (pointed, translucent, light cyan to deeper blue) beside the rocks.
5. Frosted trees: pale blue-green pines and bare dark twigs/corals with white frost; small frost shrubs by the hundred.
6. Everything is white, ice blue and slate; no warm colour except the sky tint.

Layout: the floor is an ice-white stud look (`#dbe9f7`) with the snow shore ring at the rim: snow mounds as
white matte Plastic balls (like the Meadow hills), the frosted pines as the backdrop rows, the hills white-blue.
A few translucent crystal clusters at the corners (Glass/ForceField is expensive on phones: use `Neon` light-blue,
`Transparency 0.25`, a few parts only). Light: cool, low sun, the daylight preset with a bluish ambient.

Props:
- Owner's models: `OwnIceCrystalCluster`, `OwnIceCrystalSpire`, `OwnFrozenRockSpire`, `OwnSnowberryBush`,
  `OwnCrystalPaleBlue`, `OwnCrystalBlue`.
- Ultimate Nature snow variants (all in the same pack): `PineTree_Snow_1..5`, `CommonTree_Snow_*`, `CommonTree_Dead_Snow_*`,
  `BirchTree_Snow_*`, `BirchTree_Dead_Snow_*`, `Willow_Dead_Snow_*` (the bare twig coral look), `Bush_Snow_1/2`,
  `Rock_Snow_1..7`, `TreeStump_Snow`, `WoodLog_Snow`. These are FBX with flat colours: the same `take_fbx.ps1`
  route, with a snow PALETTE (the snow material to `#f4f8ff`).
- Snow fence: Fantasy Props MegaKit or Ultimate Nature `WoodLog_Snow` cut short (a few only).

Monsters:

| Role | Monster | Source | Note |
| --- | --- | --- | --- |
| swarmer | Arctic Fox | `Pets/ArcticFox` | small and many |
| raider / hunter | Snow Leopard | `Pets/SnowLeopard` | fast, hunts the weakest |
| spitter / ranged | Frost Wisp | `Pets/FrostWisp` | floats, ice shard; `hover` in its Look |
| shaman / healer | Penguin | `Pets/Penguin` | BUILT (phase A): the Aurora Owl already heals in the Meadow; the Penguin walks (a new motion for a healer) |
| armoured | Ice Golem | `Pets/IceGolem` | slow, high defence |
| miniboss | Mammoth | `Pets/Mammoth` | NEEDS WORK: size, `height = 9`, `shadow = true` |
| boss | Yeti | `Guardians/Peaks` (`boss_Peaks`, 62 bones) | NEEDS WORK: boss size; alternative `Pets/FrostDragon` or Ultimate Monsters `Yeti` (not rigged) |

## 5. Monster work common to all three

- Egg Heist models come in through `tools/kit/eggheist_models.luau kit <Pets/Name> ...` (writes `assets/MonsterKit.rbxm`)
  and `studio <out.luau> <Folder> ...` for a test place; bosses are `Guardians/<Name>`. The kit file today holds Twigling,
  Parrot, BloomSprite, AuroraOwl, Hedgehog, Gorilla, Triceratops (checked 2026-11-08).
- Each monster needs a `Config.Dungeon.Looks` entry (`model`, `motion` = the creature's `src/shared/Creatures/<file>` name,
  `height`, `hover`/`bob`/`bobHz` for fliers, `shadow` for the two big ones). The motion modules are already in this
  repo's `src/shared/Creatures` (carried over); check each name exists before wiring.
- Own effects per monster: no recoloured copy of another's burst (project rule); the mini-boss and the boss use the existing
  `bloomshell` / `bramblehorn` skills until each gets its own `kind` in `Config.Combat`.
- Egg Heist's pets are rigged for a walk and idle; check the attack and hit motions exist (`pet_<Name>.luau` rows)
  before promising a map. Quaternius monsters (Ultimate Monsters, Cute Animated Monsters, Bestiary) are animated
  glb, a different rig: only worth it where Egg Heist has no fit (Mushroom King, Imp), and each needs the
  `roblox-creature-rigging` route first.
- Stats: copy the Meadow's role rows (cost, attack, defence, speed, hp, drops), then the balance-tester agent tunes them per map;
  drops per map use `Materials` that exist (`SMITHY.md`). A map's trophy (the Meadow's two horns) needs a new material per map:
  Mushroom `moss_heart`, Lava `ember_core`, Ice `frost_fang` (names to confirm with the owner's smithy list).

## 6. Maps rotate each level

Rule from `docs/reference/02-battle.md` ("Choose the map"): the first map is chosen from a seed, then each level moves to the
next map in the cycle.

- Config: `Maps` gets `mushroom`, `lava`, `ice` entries; `MapOrder = { "meadow", "mushroom", "lava", "ice" }` (the order of the
  original's `BATTLE_MAPS`; check it in `reference/goo-lineage-web/` before fixing the order).
- Pure logic in `shared/Dungeon.luau` (it already has the map lookup, line 40): `Dungeon.mapForLevel(seed: number, level: number): string`
  = `MapOrder[(first - 1 + level - 1) % #MapOrder + 1]` where `first = floor(Rng.new(seed + 77):next() * #MapOrder) + 1`
  (matching the original's `mulberry32(seed + 77)`). Test: same seed gives the same list; four levels in a row visit all four;
  level 1 differs between seeds.
- Server: `Dungeon.luau` line 908 sets `mapId = D.MapOrder[1]` at the start of a run: use `mapForLevel(seed, 1)`; when a level
  changes (`continueRun` past the last wave, if the Roblox design keeps levels), set the new `mapId` and swap the arena Model
  (destroy and clone the next template; players and slimes are moved to its spawns). The monsters' `Maps[mapId].monsters` already
  drive the wave director.
- Arena: `DungeonArena.template(mapId)` builds and caches one Model per map (a table `cached[mapId]`). `Config.Dungeon.Arena`
  becomes `Config.Dungeon.Arenas[mapId]` (the Meadow's block moved under `meadow`, the plan reading `A` as a parameter); each
  has its own `Models`, `Tints`, sizes, floor colour, path style, hill colour and a `Lighting` block (ambient, outdoor ambient,
  colour shift, fog colour and distance, an optional atmosphere) that the client applies when the arena shows.
  `DungeonArenaPlan.build(names, A)` and `hills(A)` take the block; the test loops over every map.
- Client: `UiDungeon.luau` lines 204 and 291 read `D.MapOrder[1]`; they must read the run's `mapId` (state sent by the server)
  for the gate title ("Sunny Meadow") and `MonsterLook` for the monsters on that map.
- Save and replay: the seed lives in the run, so the same run replays the same map order.

## 7. Budget and build order

- Budget per arena as the Meadow: models 600 triangles at most (trees 500, bushes 220-380, rocks 140), about 300 models;
  the Meadow measures 70-75 thousand triangles in all, which is already the top of what a weak phone should see, so the
  other maps use bigger and fewer pieces (Lava and Ice about 150 models).
- Order: Ice first (fewest new tools: one PALETTE and the snow variants of the same pack), then Lava (recoloured rocks,
  owner's models), then Mushroom (the rune circles and the ruins need the most new work).
- Each map is built as the Meadow was: reference list, greybox, props, light, three rounds of shots against the painting
  (`docs/ui/dungeon/<map>-r<n>-*.png`), lessons into `studio-build/LESSONS.md`.
