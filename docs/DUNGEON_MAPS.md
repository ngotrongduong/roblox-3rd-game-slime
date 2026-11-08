# Slime Dungeon: the other three maps (plan only, nothing here is built yet)

Written 2026-11-08. The Sunny Meadow (`battle.map.meadow.png`) is built: `shared/DungeonArenaPlan`, `server/DungeonArena`,
`Config.Dungeon.Arena`, props from `Config.LibraryKit`. This file plans Mushroom, Lava and Ice the same way, and the code
that rotates the maps each level. The paintings are in `reference/goo-lineage-web/assets/` and are the owner's: shape and
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
| shaman / healer | Aurora Owl | `AuroraOwl` (in the kit already) | a retint of its glow is not a new design: use its own motion, keep it; or Penguin `Pets/Penguin` |
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
