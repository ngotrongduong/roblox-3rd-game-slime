# The Garden as a landmark: plan and upgrade ladder

Skill `landmark-build`, steps 2 and 3. Reference: `garden-ref-sheet.jpg` and `garden-ref-era1.jpg` ... `era5.jpg` in
this folder (ChatGPT chat `/c/6afb4b95-2914-83ec-b096-95f99182ce68`, 2026-11-17; its second sheet, drawn with the
village's three concept paintings, the Granary at eras 2 and 4 and the Kitchen's sheet as references, at the owner's
word; the first, from the Kitchen's sheet alone, is `art/inbox/garden_ref_sheet.webp`). The owner approved the
sheet on 2026-11-17 ("Duyệt, dựng đi"); it is built as `src/server/Garden.luau`, called from `GardenStages.build`,
and was seen in a play test at levels 10, 20, 30, 40 and 50 (`review/garden-play-l*.jpg`); after ChatGPT's one
review and the last edit it was seen in the Edit preview (`review/garden-final-l*.jpg`).

## The place

A fenced vegetable garden that grows into a royal palm-house garden. The same four things at every era, in the same
places, so it reads as one garden:
- **The beds**: the two long raised beds with the work path between them, always open to the sky. The crops, the
  work spots and the markers stay where `GardenStages.luau` has them.
- **The gate** in the middle of the front fence: posts, then a roofed gate, a vine pergola, a steel-and-glass arch,
  a marble arch.
- **The garden house** across the back, its front always wide open so the tools, pots and seed sacks are seen from
  outside: a potting shed that becomes an orangery, a greenhouse, a palm house. A player walks in.
- **The water tower** in the back left corner as one walks in (+x): a well that becomes a windmill. Always the
  tallest thing, its wheel always turning, a blue pennant on top.

| Era | Levels | Look |
|-----|--------|------|
| 1 hamlet | 1-10 | woven wattle fence, thatch on brown timber posts, a cream plaster gable, a fieldstone well under a timber trestle |
| 2 painted | 11-20 | cream pickets on teal posts, cream plaster on teal beams, red clay tiles, a red brick tower foot |
| 3 town | 21-30 | a low stone wall with timber rails, a stone orangery with arched windows under a half-timbered storey, a round stone mill |
| 4 slime tech | 31-40 | black steel and teal glass, a vaulted greenhouse, copper pipes, green goo, a steel wind wheel |
| 5 capital | 41-50 | white marble and gold, columns and a pediment, blue glass domes, blue and gold sails |

The fence was x -18..18, z -12..21, the beds x -13..13, z -3..14.5. The house and the tower stand behind the
beds, so the area grew once at the back, for every level (an area may grow, never shrink): the fence is now
x -18..18, z -12..28.5. The compost corner (back left) gave way to the tower and moved along the fence. The map's
own garden sign stands outside the front fence at x -9, so the row of flower boxes there leaves its place free.

**The second scale-up (2026-11-17).** The house grew 2.6 times, so the fence now stands at its own size round the
grown lot: x -46.8..46.8, z -12..44.5 (`Garden.fence()`). Two notes of the owner on it:
- "khoảng đất màu nâu ở khu làm vườn hơi nhỏ ... có thể tăng số lượng garden bed và diện tích sau những lần
  upgrade", then "chỉ cần lên khoảng 4 garden bed thôi": the beds are 2 at era 1 and 4 from era 2, the new pair
  12 studs outside the first two (`Config.Village.GardenYard`; `GardenStages` clones the map's beds and makes
  20 / 40 crop plots).
- "tại sao nửa đằng sau của khu làm vườn lại để màu xanh? hãy cho cả khu này thành màu đất": the soil is the WHOLE
  fenced garden at every level, beside and behind the house too (no lawn inside the fence, ever).
The props that stood round the old fence follow the wide one.

**The two wings of soil (the owner, 2026-11-17).** "còn những chỗ đất trống còn lại để bố trí các công trình phụ
trợ, trang trí", and at once after: "chú ý về việc đặt vật phẩm tại vị trí nào và kích thước ra sao. mọi thứ cần
phải hợp lý và đúng với chức năng chứ không phải cứ đặt cho đầy khu đất. nếu không có hoặc chưa có hãy đề xuất chứ
không bắt buộc phải cố đặt chúng vào". So each wing holds ONE place with a job, against the side fence at the beds'
depth, from era 2 (when the beds double); the rest of the soil stays open (`WINGS` in `GardenStages`, real
positions; sizes as the village's own benches, lamps and flower beds):

| Wing | What | Where (x, z) | Size | Eras |
|------|------|--------------|------|------|
| +x, the tower's side: the work yard | the kit's tool shed, door to the beds | 40.5, 3 | 10 x 8, 9 tall | 2-3 only: timber under red tiles sits right by the red-tiled houses, wrong by steel-and-glass and marble |
| | the era's own tool store, door to the beds: `ToolStoreTech` (riveted steel frame, teal glass, brick foot, shingle roof, gear, copper pipe, lantern), `ToolStoreRoyal` (marble courses, gold-capped columns, pediment, arched gold door, the era's blue roof with gold hips) | 40.5, 3 | 10.4 x 8.4; 9 and 10.5 tall | 4, 5 (built in Blender 2026-11-17, `Garden.toolStore`; reference `garden-toolstore-ref.jpg`) |
| | the machines' bay (the tools slot of eras 2-5) before the shed, beside its door | 33, -4 | as before | 2-5 |
| -x: the seat | a bench looking over the beds (park, iron, modern, marble) | -44.4, 6 | 4.4 wide | 2-5 |
| | its lamp beside it (lantern, iron, modern, golden) | -45, 9.25 | 4 to 9.6 tall | 2-5 |
| | a flower bed at each end (wood, brick, steel, marble) | -45, -1 and 13 | 5.4 long | 2-5 |

The two log benches outside the front fence went: the garden has its own seat now. Compost, hay, the scarecrow,
the water pieces and the harvest crates keep their places among the beds, where they work.

Proposed for the open soil, NOT built (each needs its reference picture first, then Blender or the owner's Meshy):
1. BUILT 2026-11-17 (the owner chose it): a tool store for era 4 and one for era 5, in the table above.
2. A potting bench with seedling trays, against the shed's side (about 5 wide, 3.5 tall).
3. A cold frame or small seedling glasshouse behind the shed, by the tower's basin (about 8 x 5, 3 tall).
4. Two or three beehives in the far back corner of the seat's wing, away from the bench (each about 2 x 2, 3 tall).
5. Two or three small fruit trees along the back fence beside the house (each about 9 tall).
6. A vine arbour over the bench (about 8 x 5, 8 tall).

## The ladder

As the Kitchen's: an era's first level changes the architecture; levels 2-5 bring the four garden props, each slot
taking its next, different model (the kit's own, already in `GardenStages.PROPS`); levels 6-10 add one feature each
(`f`), and a feature once added stays in every later era in that era's materials. Kind: N a new ornament or part,
U an ornament upgraded, M a material moved on, S a part swapped for the next one.

| Level | f | Kind | What changes, as a player sees it |
|-------|---|------|-----------------------------------|
| 1 | | | The garden: a wattle fence, the two plank beds, a gate of two posts, a small thatched potting shed on posts at the back, a fieldstone well with a winch |
| 2 | | N | Watering can, on a plank stand with a bucket |
| 3 | | N | Tool rack |
| 4 | | N | Compost bin |
| 5 | | N | Straw scarecrow |
| 6 | 1 | N | A little thatched roof over the gate, a lantern on each post |
| 7 | 2 | S | The shed's open gable truss is closed with cream plaster and a shuttered window, big lanterns on its two front posts |
| 8 | 3 | N | A straw lean-to on the shed's side over a potting bench, herbs hung to dry: the first side wing |
| 9 | 4 | U | A tall timber trestle rises over the well and carries a water barrel: the tower is now the tallest thing |
| 10 | 5 | N | **The wooden wind wheel on the tower, turning, with the blue pennant** |
| 11 | | M S | Era 2: cream pickets on teal posts, red clay tiles on the gate and the house, cream plaster on teal beams, the tower on a red brick foot, the lean-to a glass cold frame |
| 12 | | U | Rain barrel |
| 13 | | U | Soil cart |
| 14 | | U | Compost tumbler |
| 15 | | U | Hatted scarecrow |
| 16 | 6 | N | Flower boxes along the front fence on both sides of the gate and under the gable window |
| 17 | 7 | N | A dormer with a lit window on the house roof |
| 18 | 8 | N | A brick basin at the tower's foot, filled with water from a spout |
| 19 | 9 | N | Two round clipped bushes in pots where the path reaches the house (the rose arch first built here was taken out at the owner's word, 2026-11-17: it did not fit the garden) |
| 20 | 10 | S | **The wheel becomes a windmill: four big cream cloth sails** |
| 21 | | M S | Era 3: a low stone wall with timber rails, stone gate pillars, the house a stone orangery with tall arched windows, the tower a round stone drum under a red cone cap with lattice sails |
| 22 | | U | Hand pump |
| 23 | | U | Seed spreader |
| 24 | | U | Fertiliser sacks |
| 25 | | U | Pinwheel post |
| 26 | 11 | N | A timber pergola behind the gate, heavy with vines and grapes, over the path to the beds |
| 27 | 12 | N | Water pours from a spout high in the tower down a stone chute into the basin |
| 28 | 13 | N | Ivy climbs the orangery's two front piers and over its arch |
| 29 | 14 | N | A timber gallery round the mill, under its cap |
| 30 | 15 | N | **A jettied half-timbered storey on the orangery under a higher red roof with a front gable: the house stands a floor taller** |
| 31 | | M S | Era 4: a black steel fence with brass caps, a steel-and-glass gate arch, the house a steel and teal glass greenhouse under a glass vault, the tower a steel trestle on its brick foot with a many-bladed steel wheel |
| 32 | | U | Sprinkler |
| 33 | | U | Tiller |
| 34 | | U | Fertiliser tank |
| 35 | | U | Bird repeller |
| 36 | 16 | N | Copper irrigation arches with sprinkler heads over both beds |
| 37 | 17 | N | A brass gear wheel on the gate arch |
| 38 | 18 | N | Copper pipes from the tower over to the greenhouse roof |
| 39 | 19 | N | Blue banners on the gate piers |
| 40 | 20 | N | **A glowing green goo tank in the tower under the wheel, and two smaller tanks at its foot, piped to the beds** |
| 41 | | M S | Era 5: a white marble balustrade, a marble and gold gate arch, the house a marble palm house with columns and a pediment, a marble tower with blue and gold sails, marble bed frames with gold trim |
| 42 | | U | Watering drone |
| 43 | | U | Garden robot |
| 44 | | U | Goo composter |
| 45 | | U | Robot scarecrow |
| 46 | 21 | N | Cone topiaries in gold urns at the corners and beside the house |
| 47 | 22 | N | A gold crown on the tower's top |
| 48 | 23 | N | A golden slime between gold laurels on the pediment |
| 49 | 24 | N | Small blue glass domes with gold ribs on the two side wings |
| 50 | 25 | N | **The great blue glass dome with gold ribs and a gold lantern over the palm house** |

Walked against the step test (section 2 of the skill): no row is a count alone (the lanterns, the flower boxes, the
topiaries and the side domes each arrive together as one set; the great dome is a different part from the side
domes); every row is outside or in the open front; nothing is taken away (wheel, then sails; lean-to, then cold
frame, side bay, glass aisle, side pavilion: the same part in its next form). The weakest rows, to be made big
enough at the build: 2 (a watering can is 1.2 studs: it stands on a 2-stud stand with a bucket), 17 (a dormer 3
studs wide with real light), 28 (ivy over a whole pier, top to bottom). The five era pictures show each era's LAST
level. Not yet seen in the game: this is the plan.

## Which shapes go where

Looked in the owner's sheet kit first (`src/shared/ConfigMeshyKit.luau`): the Garden needs no new Meshy piece.

| Goes to | Pieces |
|---------|--------|
| Parts (`Architecture`) | fences (wattle as posts and woven rails, pickets, stone wall and rails, steel bars), bed frames, house walls, posts and piers, slab roofs, thatch with rolls, the trestle's beams, the brick foot, the round stone drum, the gallery, sails as thin frames and cloths on a hub, basin, chute and water, the pergola's beams, the glass vault as flat panes between ribs, column shafts, the pediment, grapes as small balls |
| Blender, reused | cone roof with tile rows (the mill's cap), glass-and-iron dome (the goo tank's cap), royal dome (the three domes), column capital and base, balustrade run with urn (the era-5 fence), copper pipe elbow, brass gear wheel, gold crown (the tower's top) |
| Blender, new (in `tools/blender/granary_pieces.py`) | `WindWheel_Blades`: a many-bladed wind wheel, timber at era 1 and steel at era 4; `IrrigationArch_Copper`: a copper hoop with a sprinkler head |
| Meshy, from the owner's sheets | `WallLantern_Iron` (shed posts, gate), `FlowerBox_Trough`, `FlowerBox_Pink`, `FlowerBox_Yellow` (fence, gable), `BushPot_Round` (19), `Trellis_Ivy`, `Ivy_Corner`, `PlanterBox_Vines` (pergola, piers), `Window_Shutters`, `Window_Arched`, `Dormer_RedRoof` (house), `GooTank_Glass`, `PipeValve_Copper` (40), `Banner_SlimeBlue` (39), `ConePot_Topiary`, `FlowerUrn_Gold` (46), `SlimeCrest_Laurel` or the game's gold slime with `Laurel_Gold` (48), `Finial_GoldStone` |

Every one of the sheet pieces is already uploaded (2026-11-17); only the two new Blender pieces will need an upload
through the owner's cloud place.
