# The big world (rebuild of the main map, 2026-11-14)

The owner's brief: keep the player village as it is; rebuild everything else as one world about ten times larger,
natural and scenic, made to explore, not a grid of arenas: **8 villages, 1 shopping hub, 10 mini-boss zones, 3 boss
zones, 1 mega-boss zone**. Kit assets first; smooth on cheap phones. His rule while it was built: "laid out in a
natural state, not divided into cells like a chessboard".

Where it lives: the plan is data (`src/shared/WorldPlan.luau`, checked by `tests/spec/world_plan.luau`); three
re-runnable builders turn it into the world in the work place `assets/raw/MapWork.rbxlx` (`tools/world/`). It stands
at an offset (`WorldPlan.Origin`, 6,000 studs north of the old valley), so the old valley keeps running until the
game is switched over (section 7, milestone M4). References: `docs/references/world/world_ref_1..3.webp`; shots of
the result: `docs/references/world/shots/`.

## 1. Audit (what there was)

**The map.** One round valley at the origin (`Config.Map`): a flat floor of radius 690 with hills to 830, eight home
plots (228 square) and the Market on a ring road of radius 356, the Wild Garden (radius 334) with its Heart clearing
in the middle. Fights (zombie camps, the Dungeon's nine slices, the arena) are reached through gates and boards, not
by walking: the world itself has nowhere to go. Built by `tools/map/*.luau` with `terrain:Fill*` shapes.
Good and kept: the home plot (the game builds it), the Market (1,789 instances, moved whole), the owner-approved
ground look (StorybookGrass, the orange WildDirt path, stud floors), the kit and its proven recipes
(`tools/map/build_wild_slices.luau`). Weak: small, symmetric (a clock face), no landmarks seen from afar, no route.

**The library** (ServerStorage of the work place; index `docs/kit/README.md`): WildKit 109 (20 Yasu trees, Quaternius
trees / bushes / rocks / grass with purple, teal, orange and gold variants, the owner's mushrooms, crystals, basalt,
ice), PropKit 254 (buildings, fences, lamps, signs, arches, statues, boats, mills, giant mushrooms), OwnerKit 20,
NatureKit 35, KitCache, CropKit, FishKit, FoodKit. Enough for five regions' plants, rocks and arena rings and for
every landmark but these: **no bridge, no gate with a region's character, no centrepiece for the mega-boss, no
arena altar, no waystone** (section 5).

## 2. World layout

4,600 x 4,400 studs (the old floor was 1,380 across: about ten times the ground). North is up; local x east, z south.

```
                 snow peaks  .  Frost Reach  .  snow peaks
        Sunken Ruins   Crystal Hollow   GLACIER THRONE   Frostfang   Ashen Pass
              \              \________ Frost Gate ________/             /
   Webwood     \                    |  THE HEART  |                    /   Emberglass
     Hollow -- Grove Fork   Root Gate (crater lake, Gate Ember   Ember Fork -- Field      VOLCANO
   Mushroom     |   GLOOMROOT ===== island, King Goo) ===== MOLTEN     |      Ember Terraces
    Grove   Sporelight Glade        Crownfall  |            THRONE   Cinder Terraces
                 \                   Lookout   | river                 /
            Bramble Hollow ---- WAYFARERS' CROSS (great oak) ---- Old Stone Bridge -- Turtle Pond
                                       |  King's Road                    Rolling Meadows
                 Hillfoot        North Gate      Millbrook (mill)
          Westmeadow       GOO MARKET (hub) = Market Bridge      Eastfield        Home Vale
                 Orchard End     South Gate      Sunny Rise
                        Reedbank   |  Reed Bridge   Baywatch
                              South Quay (lighthouse) ~ South Bay ~ open sea
```

- **Home Vale** (south, safe): the Goo Market in the middle on the river; the eight villages in a loose ring round it,
  each in its own fold of land, 590-770 studs from the hub, joined by the Village Lane; the river runs through to the
  round South Bay and the quay.
- **Rolling Meadows** (the first wilds): the King's Road leaves the vale north to **Wayfarers' Cross** under the great
  oak, the world's one crossroads: west to the Mushroom Grove, east to the Ember Terraces, on along the river to the
  lookout under Crownfall.
- **Mushroom Grove** (west, teal and violet), **Ember Terraces** (east, black basalt, lava veins, terraces under the
  volcano), **Frost Reach** (north, snow, pines, three peaks). Region borders wander with the land (a warped nearest
  seed, never a line).
- **The Heart** (middle of the world, mega-boss): a rock mesa 130 studs over the plain holding a crater lake with an
  island, King Goo's arena. Its lake spills south as **Crownfall**, the source of the river that runs past the Cross,
  through the vale and the Market to the sea: the whole world hangs on one line of water. It is seen from every
  region; it is entered only by three causeways, each behind one boss.
- **Edges**: rim mountains all round (a superellipse, not a wall), the volcano east, three snow peaks north, the sea
  south.

Path network (`WorldPlan.Roads`, 17 roads; the test proves every place is joined): King's Road (14 wide, lamps), the
Village Lane loop with West Row and East Row to the hub, Quay Road, Bramble Way and Pond Way from the Cross, Grove
Road / Cinder Road to the bosses with side tracks to the far minis (Webwood, Emberglass), the two Frost Roads over
the passes to Glacier Throne, and the three causeways (cobble, 12 wide) up into the Heart. Roads follow curves and
the land's height; four bridges cross the river.

Transitions: meadow grass thins into mud and teal trees going west, into terraces, dead trees and autumn colours
going east; the two far minis (Sunken Ruins, Ashen Pass) sit on the passes where grove and ember meet the snow.

## 3. Zones (`WorldPlan.Zones`): purpose and why there

Tier is the order a player meets them by road (test "progression by road legs").

| Tier | Zone | Kind | Region | Monster | Why it is there |
|---|---|---|---|---|---|
| 1 | Bramble Hollow | mini | Meadows | boar | first fight, one road leg west of the Cross, in sight of it |
| 2 | Turtle Pond | mini | Meadows | turtle | the east choice from the Cross, over the Old Stone Bridge |
| 3 | Sporelight Glade | mini | Mushroom | wyrm | the grove's doorstep: glow seen from Bramble Hollow |
| 4 | Webwood Hollow | mini | Mushroom | golem | side track off Grove Fork: the first detour that pays |
| 5 | Gloomroot Throne | boss | Mushroom | bear | end of Grove Road at the mesa's west foot; opens the Root Gate |
| 6 | Cinder Terraces | mini | Ember | bull | first terrace above the meadows |
| 7 | Emberglass Field | mini | Ember | tortoise | far side track under the volcano |
| 8 | Molten Throne | boss | Ember | magma golem | east foot of the mesa; opens the Ember Gate |
| 9 | Sunken Ruins | mini | grove/snow pass | totem golem | the west pass north: ruins half in the mud |
| 10 | Ashen Pass | mini | ember/snow pass | phoenix | the east pass north: ash meets snow |
| 11 | Crystal Hollow | mini | Frost | ice golem | frozen hollow on Frost Road West |
| 12 | Frostfang Ridge | mini | Frost | mammoth | ridge on Frost Road East |
| 13 | Glacier Throne | boss | Frost | yeti | under the peaks, north foot of the mesa; opens the Frost Gate |
| 14 | The Heart | mega | middle | King Goo | the island in the crater: every road ends here |

Other named places (`WorldPlan.Sites`): Wayfarers' Cross, North Gate and South Gate (lane junctions), South Quay,
Crownfall Lookout, Grove Fork, Ember Fork, the three gates, the four bridges (Market, Mill, Reed, Old Stone).

## 4. What was built (in `assets/raw/MapWork.rbxlx`, saved 2026-11-14 10:40)

| Builder | Makes | Run | Result |
|---|---|---|---|
| `tools/world/build_terrain.luau` | the heightfield, 4-stud voxels: regions, river, bay and sea, rim, volcano, peaks, the Heart (rim, lake, island, gate cuts, causeway ramps), pads, roads | `ARGS`: `rows 0 34`, `sea`, `probe X Z` | 1,260 chunks in 10.9 s |
| `tools/world/build_scatter.luau` | trees, plants and rocks by region (read off the ground material), groves by noise, bare roads and pads, flowers along roads | `ARGS`: `rows 0 8`, `count` | about 8,700 placements, 10,994 parts, 88 meshes |
| `tools/world/build_sites.luau` | the Market at the hub, 4 bridges, 13 arena rings with torches, signs and boss thrones, 3 gates, the Heart's crown, Crownfall, the Cross, quay, lookout, mill, village gates, lamps | no args | 468 kit pieces, 2,141 parts |

```
node tools/studio_mcp.js run tools/world/build_terrain.luau <studio_id> Edit PLAN=src/shared/WorldPlan.luau ARGS=<file>
```

Tree in the place: `workspace.World.Scenery.C<x>_<z>` (one folder a 512-stud cell, bare parts) and
`workspace.World.Sites` (`Market`, `Bridges`, `Zones/<name>`, `Heart`, `Landmarks`, `Villages`, `Wayside`). The old
valley is untouched in `workspace.Map`; no builder calls `terrain:Clear()`.

## 5. Missing assets, by priority

All: low poly, chunky rounded cartoon shapes like the owner's kit, flat matte colours, no baked light or shadow
(light comes from the game), one mesh, base colour only, ground contact flat. Meshy: Image to 3D from ONE picture on
the **Smart Topology** tab (the owner's rule), the triangle count below typed into Poly Count, Texture on (15
credits, no Remesh needed); import into Roblox as one MeshPart.

| # | Asset | Use | Size in game | Triangles | Now (interim) |
|---|---|---|---|---|---|
| 1 | Root Gate, Ember Gate, Frost Gate | the three ways into the Heart | 42 tall, opening 16+ wide | 3,000 each | **done 2026-11-14**: own models (`art/models/world/gates/*.glb`, 3,930 / 3,110 / 3,167 triangles) in `ServerStorage.WorldKit`, region pieces kept as dressing |
| 2 | The Crown of the Heart | the mega-boss island's spire, seen across the world | 240 tall | 4,000 | CrystalCluster, stretched |
| 3 | Stone arch bridge | 4 river crossings (and more later) | 68 long, 14-18 wide | 1,500 | built of parts (plank arch) |
| 4 | Arena altar, 4 kinds | the mark of a fight: meadow, grove, ember, frost | 12-16 tall | 800 each | torches only |
| 5 | Waystone | junction and zone-entrance marker | 6 tall | 300 | PropKit Signpost |
| 6 | Boss thrones, 3 | Elder Cap, Molten Seat, Glacier Seat behind each boss ring | 60-80 tall | 2,000 each | scaled-up kit pieces |
| 7 | Ruin set (broken column, fallen arch, wall end) | Sunken Ruins | 8-20 | 600 each | RuinArch, DryStoneWall |
| 8 | Hub town houses | a small town round the Market | - | - | Quaternius / Kenney packs first (`art/library/`), no generation |
| 9 | Crownfall's moving water and mist | the waterfall | - | - | parts; the effect comes from the VFX library, not a model |

### ChatGPT image prompts (one message each, image generator, highest thinking; attach `world_ref_2.webp` as the style lock)

Shared ending for every prompt: *"Stylized low-poly cartoon game asset in the exact style of the attached picture:
chunky rounded shapes, flat matte colours, soft even light, no cast shadow, no glow effects, no text. Front view,
the whole object in frame, centred, on a flat pure white background."*

1. **Root Gate**: "A tall fantasy gateway made of two huge twisted tree roots that arch and knot together at the top,
   teal glowing mushrooms growing in steps up both sides, two hanging lanterns under the arch, mossy stone footing,
   a wide open passage through the middle."
   **Ember Gate**: "A tall gateway of stacked black basalt blocks with glowing orange lava cracks, clusters of orange
   crystals on its shoulders, two iron braziers at its feet, a wide open passage through the middle."
   **Frost Gate**: "A tall gateway of snow-capped grey stone blocks with big pale-blue ice crystals growing from its
   top and sides, icicles under the arch, snow piled at its feet, a wide open passage through the middle."
   (The first picture of all three exists: `world_ref_3.webp`.)
2. **Crown of the Heart**: "A towering spire shaped like a crown: a ring of tall turquoise goo-crystal points rising
   from a round stone base, the middle point twice as tall as the others, small round slime-like drips frozen on the
   crystals, a carved slime face on the base."
3. **Stone arch bridge**: "A low single-arch footbridge of rounded grey and cream stones with a gentle hump, low stone
   side walls with a rounded cap, a little moss, seen from the side, the arch open underneath."
4. **Arena altars** (four pictures): "A standing-stone altar marking a monster's lair: <meadow: a mossy grey monolith
   with a carved boar tusk sign and wild flowers at its foot | grove: a root-wrapped stump altar with a ring of teal
   mushrooms and a violet rune | ember: a black obsidian brazier pillar with a bowl of lava and orange crystal teeth |
   frost: a pale-blue ice obelisk with a snow cap and a frozen claw mark>."
5. **Waystone**: "A knee-high rounded milestone of cream stone with a carved arrow and a small slime emblem, a tuft of
   grass at its foot."
6. **Thrones** (three pictures): "A giant <elder mushroom with a split cap and a root seat | seat of cooled lava with
   glowing cracks and basalt columns behind | seat of blue ice with tall crystal fins behind>, a boss's throne."
7. **Ruin set**: "Three separate pieces of an old sunken temple in a row with wide gaps: a broken round column, a
   fallen arch half buried, a crumbled wall end; cream stone, moss and small teal mushrooms."

### Meshy prompts (Image to 3D, Smart topology; add as the text hint)

1. "Low-poly stylized fantasy gate, one solid mesh, open passage, flat matte colours, no glow, game asset, 3,000 tris."
2. "Low-poly stylized crystal crown spire on a round stone base, one solid mesh, flat colours, game asset, 4,000 tris."
3. "Low-poly stylized stone arch footbridge, symmetric, walkable flat deck, open arch, game asset, 1,500 tris."
4. "Low-poly stylized standing-stone altar, one solid mesh, flat colours, game asset, 800 tris."
5. "Low-poly stylized milestone, one solid mesh, flat colours, game asset, 300 tris."
6. "Low-poly stylized giant throne, one solid mesh, flat colours, game asset, 2,000 tris."
7. "Low-poly stylized ruin piece, one solid mesh, flat colours, game asset, 600 tris." (one generation a piece)

The way through the tools (proved on the three gates, 2026-11-14): cut the subject out of its reference picture into
a square `source.png`, carry it into Meshy with skill `meshy-multiview`'s `carry.html`, Smart Topology tab, poly
count, Texture on, Generate; open the TEXTURED entry in the model list (each generation lists a grey mesh and a
textured model), Download as glb into `art/models/world/`, upload through Studio's Open Cloud, load into
`ServerStorage.WorldKit` (`tools/world/take_gates.luau` is the pattern; lessons in
`.claude/skills/studio-build/LESSONS.md`). The text prompts above are only a hint: Smart Topology takes no text.
A finished model replaces its interim by one line in `tools/world/build_sites.luau` (the kit and name it clones).

## 6. Performance (measured in Studio, 2026-11-14)

- Scenery: 10,994 MeshParts from **88 unique meshes**, 814 collide (big rocks only), 3,766 cast shadows (18 studs
  and taller); the densest 512-stud cell holds 530 parts. Sites: 2,141 parts, 1,370 of them the Market as it was.
- The far view is terrain (mesa, volcano, peaks, bay): it draws at any distance with terrain's own level of detail,
  so the landmarks stay when instances stream out.
- For the game: `StreamingEnabled`, target radius about 700, minimum 250; the Crown and the great oak persistent;
  plants under 6 studs can drop at a low graphics level (they are separate entries in the scatter recipes).
- **Not measured:** triangles in view, draw calls, memory and FPS on a real phone (the owner's F9 / MicroProfiler
  pass before any publish).

## 7. Implementation plan and milestones

- **M1 Plan as data** (done): `WorldPlan` + 9 tests (counts, spacing, pads clear of the river, roads join everything,
  each gate behind one boss, progression).
- **M2 Terrain** (done): one heightfield pass; everything is a function of the plan, so moving a place and running
  `rows 0 34` again moves the land.
- **M3 Dressing and places** (done): scatter, Market, bridges, arenas, gates, landmarks, wayfinding.
- **M4 Switch the game over** (next; code, not done): `Layout` takes plot frames from `WorldPlan.Villages`
  (`villageFacing`), the Market's anchors from the hub, spawn at the hub; the server `World` module loads this
  terrain and `World.Scenery / Sites` instead of the old valley; streaming on; then the old `workspace.Map` terrain
  and the old builders retire. Saves do not change shape (plots are slots, not positions).
- **M5 Fights in the world**: each zone gets its encounter (camp spawn ring = the arena pad; tier from
  `WorldPlan.Zones`), boss kills open the three gates, King Goo on the island. Design with `game-designer` first.
- **M6 Own models** for section 5, swapped in; region light and sound (client-side Atmosphere by region, no ambient
  particle layers).
- **M7 Phone pass** and the owner's walk through every road.

Build order inside a region when it is deepened later: reference picture -> terrain detail (ponds, ledges) -> hero
pieces -> scatter recipe -> shots from the fixed cameras -> rounds (skill `studio-build`).

## 8. Validation (round 1, against `world_ref_1` and `world_ref_2`; 2 met, 1 close, 0 not met)

| Point | Score | Seen |
|---|---|---|
| Silhouette and landmarks | 2 | `shots/cross.jpg`: great tree, mesa with Crownfall and the Crown's tip, lookout, bridge, as reference 2; `shots/heart.jpg`: crater lake, island, three causeways as reference 1 |
| Palette | 1 | greens are yellower than the reference; grove ground pale teal, lava reads red not orange |
| Horizon and camera | 2 | the Cross view matches reference 2's framing |
| Density gradient | 1 | groves and open ground alternate; the vale is thin, the references' region edges are denser |
| Path readability | 2 | orange dirt and cobble causeways read from far on grass, mud, basalt and snow |
| Haze and depth | 1 | one Atmosphere for all; no region mood yet |
| Shape language | 1 | kit pieces fit; the gates are their own models (2026-11-14); bridges, crown and fall are interim |
| Value structure, scale against a player | - | not checked: no play test stands in the new world yet (M4) |

Fixed during the build: straight region borders and a rectangular bay (warp raised to 460 / 130 / 24 studs, cubic
shore); the Heart read as a low hill (top 84 -> 130, rim rise 34 -> 46, rock by a lower steepness inside the Heart);
village pads showed as stamped circles (pads keep the natural grass); the quay sat on the river mouth (moved); the
Market's back wall on Quay Road (the road now starts at South Gate); too many ember dirt blotches (threshold 0.25
-> 0.4); the Crown hidden behind the rim from the Cross (stretched to 240 studs).

Known and left: the old valley shows as a floating slab on the south horizon until M4 removes it; the river lies
only 2 studs under its banks; Turtle Pond has no pond yet; village pads are empty (the game builds the plots).

## 9. Needs the owner

- A walk through the world in Studio (MapWork, `workspace.World`): is the layout the world he wants, before M4 moves
  the game onto it.
- Model uploads need asset read and write granted to the Assistant (Settings > MCP Permissions; granted 2026-11-14)
  AND a Studio open on a place saved to Roblox: the token comes through that Studio, not through MapWork.
- Meshy credits for section 5 (each generation spends 15; 673 left on 2026-11-14).
- Publishing stays his.
