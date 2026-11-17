# The village scale (owner, 2026-10-30)

"Double the total area of the player's village, double each activity area, rearrange the buildings so
they have airier space that fits the slimes' size." Slimes got stuck between nests, a trough and a fence
(`docs/play/owner-2026-10-29/stuck-breeding-*`). This file is the standard; the numbers live in
`Config.Map`, the geometry in `src/shared/Layout.luau`, the checks in `tests/spec/layout.luau`.

## 1. The standard slime

| | studs | source |
|---|---|---|
| height at scale 1 | 3 (`Map.SlimeHeight`) | `Config.VillageClient.BodyHeight` |
| width at scale 1 | 3.5 (`Map.SlimeWidth`) | measured body bulge (orchestrator's figure; re-measure in MapWork in phase E) |
| baby | x0.62 (`Farm.BabyScale`) | |
| path agent radius | 1 + 0.8 x scale | `Village.PathMinRadius`, `PathRadiusPerScale` |

Design for an adult at scale 1.3 (about 4.5 wide) so big slimes still fit.

## 2. Clearances (all from the slime width S = 3.5)

(The village props are spread over the bigger plot: path lamps and flowers at fixed fractions of each path,
the tree ring every half cell along the fence, the campfire corner's seats and trees on a wider ring.)

| rule | studs | why |
|---|---|---|
| `PathWidth` (inner plot paths) | 6 | the owner's own width (2026-10-30: 14 and 8 were too wide); slimes pass on the lawn beside it (design note, not a rule) |
| `MainPathWidth` (gate road) | 6 | the same |
| `PlazaRadius` | 16 | the round plaza paving (was 15) |
| `RingRoadWidth` | 24 (was 18) | valley traffic |
| `WorkFront` | 7 | free ground (2 S) in front of every work place, nest, incubator, trough, bin, seat, door, upgrade pad |
| `PropGap` | 7 | least gap between two props, or a prop and the fence: two slimes pass |
| `TurnRadius` | 7 | open corner where a path turns / meets a fence |
| `PlotLane` | 40 | least open lane between neighbouring rim footprints |
| nest / incubator ring | 5 all round | a parent walks round it to lay / carry |

## 3. The new numbers

| | old | new | factor |
|---|---|---|---|
| `PlotSize` | 160 | 228 | x1.425 side, x2.03 area |
| cell (one area) | 53.3 | 76 | x2.03 area |
| `RimRadius` | 360 | 500 | neighbour centres 342 apart, open lane >= 50 (test) |
| gate radius | 280 | 386 | |
| `RingRoadRadius` / width | 258 / 18 | 356 / 24 | 18 to the gates, 10 to the Wild Garden |
| `WildRadius` | 240 | 334 | x1.39, same proportion as the rim |
| `HeartRadius` | 46 | 64 | |
| `DuelRingDistance` / radius | 78 / 14 | 108 / 14 | ring size is an arena, kept |
| `FloorRadius` | 490 | 690 | plot corners at 661 |
| `HillOuterRadius` / height | 600 / 70 | 830 / 80 | hill band 140 wide |
| Market | 200 x 160 | unchanged | it is not the player's village; lane to plots 1 and 8 checked |

The whole valley grows by about x1.39, so its look and proportions stay; walking gate to Heart grows from
234 to 322 studs (quick travel covers it).

### The plot's 3x3 grid (cell 76)

Same arrangement as now (`Layout.PlotAreas`): back row fishing, pantry, garden; middle kitchen, meadow
(plaza), breeding; front training, gate, hatchery; all areas face the plaza. Inside every cell the usable
square is about 62 x 62 (was ~40 x 40). Paths run from the plaza to each area's entrance (6 wide), the
gate road too. The plaza (meadow cell) is a round paving of radius 16 with the fountain in the middle.

## 4. Inventory of what changes

Rule: **models keep their present size**; only their positions spread. Each stage module places props in
its area's own frame with hand-typed offsets; those offsets are re-laid for a 62-stud usable square,
following §2 (every interactive object gets `WorkFront` free, `PropGap` between props). A plain x1.425
multiply is the starting point, then hand fixes where props must stay grouped (a bench at its table, a rod
rack at the dock).

Runtime (`src/server`):
- `VillageStages.luau`: `HALF = 80` typed by hand -> `Config.Map.PlotSize / 2`; plaza, paths, fence posts.
- `VillageWalls.luau`, `VillageFountain.luau`, `GateArch.luau`: fence line and gate at the new half size;
  the fence gets more post/segment clones (shared meshes), not longer meshes.
- `AreaStages`, `PondStages`, `GardenStages` (shared with the food agent's `GardenPlots`: coordinate),
  `PantryStages`, `KitchenStages`, `TrainingStages`, `BreedingStages`: every hand-placed offset per level
  1..10, the remodels at 4, 7, 10.
- `WorkProps.luau`, `UpgradePads.luau`, `Spots.luau`: work spots, pads, seat spots re-placed with the props.
- `src/client/Village.client.luau` reads only `Layout`; no change.

Saved place (MapWork, `tools/map/*.luau`), re-run in this order after the code change:
1. `build_terrain` (valley floor, hills, ring road, Wild Garden at the new radii; all terrain is lost and rebuilt).
2. `build_greybox` (plot ground, Market, Duel Rings), `build_village`.
3. `stud_floor` (stud texture floor per plot), `pond_water_l1`.
4. `build_*_l1` per area (fishing, pantry, garden, kitchen, breeding, training).
5. `replace_fences`, `replace_props`, `replace_greybox_trees`, `dress_plot_kit`, `dress_plot_nature`,
   `polish_plot`, `tidy_plot` (dressing and the owner kit trees are re-placed: positions lost, models kept).
6. `fix_rocks`, `fix_zfight`, `lighting_storybook` (unchanged), then the scans.
7. Kit export of any re-spaced prop group; owner Ctrl+S.

Risks: the owner must Ctrl+S MapWork after each phase; StreamingEnabled with a 1660-stud valley (check
the stream radius covers a whole plot: plot diagonal 322); terrain rebuild time; the food agent edits the
garden at the same time. The play-test save is in memory, so no player data is at stake.

**Between phase A and B the code and the saved place disagree** (plots, gates and Spots move to the new
radii while the saved terrain and plot sit at the old ones): do not publish phase A alone.

## 5. Build plan

- **A** (done): `Config.Map` numbers, `Layout.cellSize`, layout tests (rim lanes by separating axis,
  doubled area, paths sized to the slime).
- **B** MapWork ground: terrain, stud floor, paths at `PathWidth`/`MainPathWidth`, fence, gate, pond water,
  dressing; screenshots from the plaza and from above; Ctrl+S.
- **C** one area at a time (breeding first: the owner's complaint, then garden, hatchery, kitchen, pantry,
  fishing, training): re-space stages and props, screenshots at levels 1/21/41, `probe_pads`,
  `probe_seats`, `scan_zfight`, `scan_rocks` green.
- **D** valley: Market on the new rim, ring road, Wild Garden quarters, Heart, Duel Rings, hills.
- **E** `probe_paths` all green, play test with 20 slimes per plot: nobody stuck for 2 minutes in
  breeding and garden; re-measure the slime width.

## 6. The second scale-up: houses sized from the fishing pier (owner, 2026-11-17)

His rules, in his order: the fishing pier (6 x 24.7) is the standard and keeps its size; a house BODY (not its
silos, chimneys, towers) is at least 1.5 pier lengths wide (37) and one pier length deep (25); the lakeside house
is the reference, the other houses about its size, the Granary is the central building and larger; the pond's
water grows to 3 times its AREA (x1.73 across); every plot grows with its house ("do not cram it into the old
space"); judge sizes from above with all six side by side. Rule 4's "models keep their present size" no longer
holds for the six landmark houses.

How the houses grow (seen only in the Edit line-up, `tools/map/lineup_preview.luau` with
`tools/map/lineup_spec.txt`; NOT in the game yet):

1. Deeper halls in the modules' own `LOOKS.depth` (done, in the code): Boathouse 10.4, Training Hall 13.2,
   Breeding House 11, Garden 10.
2. The house group scaled K times round its front-centre foot (`Model:ScaleTo`); yards, fences, gates and the
   pier are not scaled:

| Landmark | K | split z / pivot (x, z) | house group at L50, K applied (wide x deep) | body (wide x deep) |
|---|---|---|---|---|
| Granary | 2.2 | all / (0, 0) | 115 x 66 with wing and silos | about 53 x 40 |
| Kitchen | 1.45 | all / (0, -5) | 83 x 29 | about 41 x 25 |
| Garden | 2.6 | 17 / (0, 18.5) | 99 x 35 | about 37 x 26 |
| Breeding House | 2.3 | 19 / (4, 20) | 111 x 33 | about 44 x 25 |
| Training Hall | 1.9 | 16.5 / (0, 17.4) | 74 x 30 | about 43 x 25 |
| Boathouse | 2.45 | 21 / (-2, 24.4) | 81 x 44 with the lighthouse | about 41 x 25 |

What this asks of the plot (my estimate, nothing changed yet): a cell of about 130 (now 76), so `PlotSize`
about 390 (now 228), the plot's corner at about 276 from its middle, `WorldPlan.Village.PadRadius` (176) at
least 290, village centres at least 620 apart (now about 400): the villages move, MapWork's ground is rebuilt
by phases B-E above, each `*Stages` module re-spaces its yard and stations, and the Granary goes to the middle
cell. 288 is the most `PlotSize` can be without moving villages (40-stud lanes kept), which is too small.

To build it in the game: K as named numbers in `Config`, each module builds its house sections into a child
Model and scales it (check stud `Texture` tiles and lights after `ScaleTo`; people-scale props inside are
re-placed by the `*Stages` module at their own size), each `footprint` grows, then the plots.
