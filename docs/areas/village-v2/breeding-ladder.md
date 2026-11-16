# The Breeding House as a landmark: plan and upgrade ladder

Skill `landmark-build`, steps 2 and 3. Reference: `breeding-ref-sheet.jpg` and `breeding-ref-era1.jpg` ... `era5.jpg`
in this folder (ChatGPT chat `/c/6afb68c2-6688-83ec-a111-70354f61ff0b`, 2026-11-17, its first sheet, drawn with the
Garden's and the Kitchen's sheets and the village's three concept paintings as references). **The owner approved the
sheet on 2026-11-17 ("Duyệt, dựng đi") and it is built**: `src/server/BreedingHouse.luau` (the village already has a
cell called "hatchery", and `shared/Breeding` is the rules), called from `BreedingStages.build`. Seen in the Edit
preview and in one play test at levels 10, 20, 30, 40 and 50 (`review/breeding-play-l*.jpg`,
`review/breeding-final-l*.jpg`); the 50 steps were not walked pair by pair in the game. Where the build left the
plan, the rows below say what stands.

## The place

The breeding pen, grown into a royal hatchery. The same five things at every era, in the same places, so it reads as
one place:
- **The hall** across the back, its front always wide open so the straw beds, the nesting cubbies and the egg
  shelves are seen from outside. A player walks in.
- **The egg**: the giant cream egg with lavender spots on the middle of the hall's roof, from level 10 on always
  the tallest thing, one form bigger and grander at the last level of every era.
- **The heart**: a big pink heart with a white egg in it over the hall's open front, the house's emblem.
- **The warm room** on the left as one walks in (+x), joined to the hall, with the chimney that heats the eggs: a
  hay lean-to, a brick stove room, a stone turret, a goo boiler, a marble tower.
- **The yard**, open to the sky: the nests in two rows either side of the lane from the gate to the hall, the
  incubators in their line outside the right fence, the gate in the middle of the front fence.

| Era | Levels | Look |
|-----|--------|------|
| 1 hamlet | 1-10 | woven wattle fence, brown timber and cream plaster under shaggy thatch, a fieldstone chimney, wooden incubators with brass bands |
| 2 painted | 11-20 | cream pickets on rose-pink posts, cream plaster on rose-pink beams, red clay tiles, a red brick stove room and chimney, cream enamel incubators |
| 3 town | 21-30 | a low stone wall with timber rails, a stone hall with a great arch under a half-timbered storey, a round stone turret with a red cone roof, copper incubators |
| 4 slime tech | 31-40 | black riveted steel and teal glass vaults, copper pipes, a glowing green goo boiler on a brick foot, steel incubators with screens |
| 5 capital | 41-50 | white marble and gold, columns and a pediment, blue glass domes on the wings, a marble balustrade, marble and gold incubators |

What stays where the rules have it: the four nests (`NESTS`), the four incubators in their line outside the right
fence with the side gate to them (`INCUBATORS`; the sheet draws them in a row at the hall's right, the game keeps its
line, which a slime's work spots and the map's markers stand on), the four care props in their corners. The pen is
x -17..25, z -19..19, the gate x 0..8 at the front. The hall does not fit beside the two working corners at the back,
so the area grows once at the back, for every level (as the Garden did; an area may grow, never shrink): the back
fence moves from z 19 to z 30, and the hall, the warm room and the right wing stand in that strip, the lane carried
on to the hall's door. The old open nesting shelter in front of them goes: the hall takes its job.

## The ladder

As the Garden's and the Kitchen's: an era's first level changes the architecture (and brings the nest or the
incubator the rules add there); levels 2-5 bring the four care props, each slot taking its next, different model
(the kit's own, already in `BreedingStages.PROPS`); levels 6-10 add one feature each (`f`), and a feature once added
stays in every later era in that era's materials. Kind: N a new ornament or part, U an ornament upgraded, M a
material moved on, S a part swapped for the next one.

| Level | f | Kind | What changes, as a player sees it |
|-------|---|------|-----------------------------------|
| 1 | | | The pen: a wattle fence, a gate of two posts, two straw nests, two wooden incubators, and across the back a small timber hall under thatch, its front open on straw beds and egg shelves, an open timber truss in its gable |
| 2 | | N | Feed bucket |
| 3 | | N | Egg basket |
| 4 | | N | Straw pile |
| 5 | | N | Oil lamp |
| 6 | 1 | N | A timber arch over the gate with a pink heart on it, a lantern on each post |
| 7 | 2 | S | The hall's open truss is closed with cream plaster and carries the big pink heart with the white egg; lanterns on its two front posts |
| 8 | 3 | N | A thatched hay lean-to on the hall's left side with a lit window: the warm room |
| 9 | 4 | N | A fieldstone chimney stands up through the lean-to's roof |
| 10 | 5 | N | **The spotted egg on the hall's roof, sitting in a thick ring of thatch like an egg in a nest** |
| 11 | | M S | Era 2: cream pickets on rose-pink posts, a red tiled roof over the gate, red clay tiles and rose-pink beams on the hall, the lean-to a red brick stove room with a brick chimney, the egg in a tile collar, cream enamel incubators; a third nest |
| 12 | | U | Hay feeder |
| 13 | | U | Egg crate |
| 14 | | U | Cushion pile |
| 15 | | U | Heat lamp |
| 16 | 6 | N | Two flower boxes on the hall's gable beam, one each side of the heart (as built: a box under the gable hid the emblem) |
| 17 | 7 | N | A bread-oven mouth with a glowing fire in the stove room's front, under its own little tiled roof |
| 18 | 8 | N | A tiled bay on the hall's right side with a round lit window: the right wing |
| 19 | 9 | N | Two dormers with lit windows on the hall's roof, one each side of the egg |
| 20 | 10 | U | **The egg grows half again as big, in a taller tile collar with a painted rim** (as built: on a drum this egg read tall and thin; the drums start at era 3) |
| 21 | | M S | Era 3: a low stone wall with timber rails, a stone gate arch, the hall in stone with one great arch, the stove room a round stone turret under a red cone roof, the right wing half-timbered, copper incubators; a third incubator |
| 22 | | U | Grain feeder |
| 23 | | U | Egg cart |
| 24 | | U | Trampoline |
| 25 | | U | Warming stove |
| 26 | 11 | N | Lavender banners with a gold egg on the gate's two pillars and on the turret |
| 27 | 12 | N | Ivy with white flowers climbs over the hall's great arch |
| 28 | 13 | N | Glowing globe lamps on the wall's corner pillars |
| 29 | 14 | N | A jettied half-timbered storey on the hall under a higher red roof with a front gable: the hall stands a floor taller |
| 30 | 15 | U | **The egg rises on a tall round stone drum with lit windows, bigger again** |
| 31 | | M S | Era 4: a black steel fence with brass caps, a steel-and-glass gate arch, the hall a steel and teal glass vault with glass side vaults, the turret a goo boiler (a glowing green tank on a brick foot) with a riveted steel stack, steel incubators with screens; a fourth nest |
| 32 | | U | Auto feeder |
| 33 | | U | Egg scanner |
| 34 | | U | Slime bed |
| 35 | | U | Monitor station |
| 36 | 16 | N | A brass gear wheel on the gate arch |
| 37 | 17 | N | Copper pipes from the boiler up over the hall's roof and down to the incubators |
| 38 | 18 | N | Glowing green goo tubes in the gate's piers and the fence's corner posts |
| 39 | 19 | N | A second, smaller goo tank on the right wing, piped to the incubators |
| 40 | 20 | U | **The egg under a great dome of black steel ribs and brass bands with a brass finial, its spots glowing** |
| 41 | | M S | Era 5: a white marble balustrade, a marble and gold gate arch with blue banners, the hall in marble with columns and a pediment, marble wings with arcades, the boiler a marble tower with gold bands, marble and gold incubators; a fourth incubator |
| 42 | | U | Goo feeder |
| 43 | | U | Egg pod |
| 44 | | U | Cloud bed |
| 45 | | U | Holo beacon |
| 46 | 21 | N | Gold urns of pink flowers at the fence's corners and beside the hall's door |
| 47 | 22 | N | Gold laurels round the heart on the pediment |
| 48 | 23 | N | A golden slime statue on a pedestal each side of the door |
| 49 | 24 | N | Small blue glass domes with gold ribs on the two wings |
| 50 | 25 | U | **The great egg dome on a marble drum with gold ribs and a gold crown on its top** |

Walked against the step test (section 2 of the skill): no row is a count alone (lanterns, flower boxes, banners,
globes, goo tubes, urns, statues and the wing domes each arrive together as one set; the two dormers change the roof's
outline); every row is outside or in the open front; nothing is taken away (lean-to, stove room, turret, boiler,
tower: the same part in its next form; the egg only grows). The egg's five forms carry the last level of every
era, the crown the last of all. The weakest rows, to be made big enough at the build: 2-5 (the kit's smallest care
props: on their mats, as today), 13 (globes at least 1.4 studs with a real light), 22 (laurels as wide as the
heart). The five era pictures show each era's LAST level.

Against today's `BreedingStages`: its levels 6-10 moved the fence, the floor, the nest platforms, the incubator pad
and the gate arch up one material tier, one a level; those five now change together at an era's first level, and
levels 6-10 are the features above.

## Which shapes go where

Looked in the owner's sheet kit first (`src/shared/ConfigMeshyKit.luau`): the Breeding House needs no new Meshy piece.

| Goes to | Pieces |
|---------|--------|
| Parts (`Architecture`) | fences (wattle, pickets, stone wall and rails, steel bars), the hall's walls, posts, slab roofs and thatch with rolls, the lean-to, the square chimneys, the brick foot, the turret's and the egg's round drums, the thatch ring as rolls, arches with proud voussoirs, the glass vaults as flat panes between ribs, column shafts, the pediment, lavender banners with an egg badge, globe lamps, goo tubes, the incubators (today's part-built ones, kept) |
| Blender, reused | cone roof with tile rows (the turret's cap, the egg's tile collar), glass-and-iron dome (the boiler's cap), royal dome (the two wing domes), column capital and base, balustrade run with urn (the era-5 fence), copper pipe elbow, brass gear wheel, gold crown (the egg's crown) |
| Blender, new (in `tools/blender/granary_pieces.py`) | B12 `EggDome`: the egg as a tall ovoid half shell with its spots standing proud (`EggDome_Shell`, `EggDome_Spots`) and its meridian ribs with two bands (`EggDome_Ribs`: black steel at era 4, gold at era 5); B13 `HeartEmblem`: a puffy heart in a raised rim with an egg on it (`HeartEmblem_Rim`, `HeartEmblem_Heart`, `HeartEmblem_Egg`) |
| Meshy, from the owner's sheets | `WallLantern_Iron` (gate, hall posts), `FlowerBox_Pink`, `FlowerBox_Yellow`, `FlowerBox_Trough` (6), `Dormer_RedRoof` (9), `Window_Arched`, `Window_Shutters` (lean-to, wings), `Ivy_Corner`, `Trellis_Ivy` (12), `Pillar_Lantern` (13, if it fits the wall), `GooTank_Glass`, `PipeValve_Copper` (boiler, 19), `Banner_Blue` or `Banner_SlimeBlue` (era 5), `Urn_PinkFlowers`, `FlowerUrn_Gold` (21), `Laurel_Gold` (22), `HayBales_Stack` (inside the hall), `Finial_GoldStone` |

The golden slime statues (23) are the game's own slime (`b.slime`). Every sheet piece is already uploaded; only the
two new Blender pieces will need an upload through the owner's cloud place.
