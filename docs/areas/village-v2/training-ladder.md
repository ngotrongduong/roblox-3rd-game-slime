# The Training Hall as a landmark: plan and upgrade ladder

Skill `landmark-build`, steps 2 and 3. Reference: `training-ref-sheet.jpg` and `training-ref-era1.jpg` ... `era5.jpg`
in this folder (ChatGPT chat `/c/6afb80dc-3ab0-83ec-841b-48264f101756`, 2026-11-17, its first sheet, drawn with the
Breeding House's and the Kitchen's sheets and the village's three concept paintings as references). **Built and
locked 2026-11-17** (the owner: "Duyệt, dựng đi"): `src/server/TrainingHall.luau`, called from
`TrainingStages.build`; the final shots are `review/training-l10.jpg` ... `training-l50.jpg` (the game's daylight,
after the last edit) and `training-l50-flank.jpg` (the Edit preview). ChatGPT's one review, before the last edit:
likeness 86 / 82 / 79 / 73 / 86, finish 78 / 73 / 72 / 74 / 80 for eras 1-5. As built, two rows differ from the
first plan and are written as built below: 36 (the capital hangs lanterns where the steel hall has pipes) and 37
(the masts stand at the yard's back corners, clear of the tower's banner). The hall spans most of the yard's back
(20 to 23 wide in the 37.6 yard): at half that width it read as a shed against the sheet.

## The place

The training ground, grown into the village's arena. The same five things at every era, in the same places, so it
reads as one place:
- **The hall** across the back, its front always wide open so the weapon racks and the tiered benches with their
  blue runner are seen from outside. A player walks in.
- **The tower** at the hall's right end as one comes in through the gate: a log lookout, a painted watchtower, a
  round stone keep, a steel tower with a goo core, a marble tower under a dome. From level 10 on always the tallest
  thing, one form taller and grander at the last level of every era.
- **The banner**: the squad's big royal-blue banner with one gold stripe, flying from the tower's top (the yard's
  own banner pole with `SquadPoint` stays where it is).
- **The shield**: a big round shield with two crossed swords over the hall's open front, the ground's emblem
  (wood, painted blue with a gold rim, iron, steel with a green glow, gold).
- **The yard**, open to the sky: packed sand, the dummy on its post in the middle, the training spots, the four
  stations against the fences, the gate in the middle of the front fence.

| Era | Levels | Look |
|-----|--------|------|
| 1 hamlet | 1-10 | a palisade of pointed logs bound with rope, brown timber under shaggy thatch, a braced log lookout with a thatch cap, a straw dummy |
<!-- The second scale-up, 2026-11-17 (the owner: "khu vực sân tập cũng có thể mở rộng ra cả 2 bên của nhà thi đấu để có khoảng trống rộng hơn"): the hall grew 1.9 times; the fence stands at its own size round the grown lot, x -35.72..35.72, z -16.4..38.3 (`TrainingHall.fence()`); the floor and kerbs run to it, also beside the hall; the four stations moved out with the side fences (16.92), the middle stays open. The ground numbers in the paragraph below are the drawn ones. -->
| 2 painted | 11-20 | cream pickets on royal-blue posts with gold caps, cream plaster on royal-blue beams, red clay tiles, the tower boarded in cream and blue under a red cone cap, a wooden dummy with a painted chest plate |
| 3 town | 21-30 | a low stone wall with timber rails, a stone hall with a great arch under a half-timbered gable and a blue slate roof, battlements, a round stone tower with a blue slate cone, a dummy in an iron helmet |
| 4 slime tech | 31-40 | black riveted steel and teal glass vaults, copper pipes, floodlight masts, a glowing green goo core in the steel tower, a steel fence with green glass, a sparring machine as the dummy |
| 5 capital | 41-50 | white marble and gold, columns, side arcades and a pediment, a blue glass vault with gold ribs, the tower in marble under a blue and gold dome, a marble balustrade, a golden dummy |

What stays where the rules have it: the three training spots (`SPOTS`: levels 1, 21, 31, with the punching bag at
the second), the four station slots against the fences (`SLOT_AT`), the area's own dummy, archery target, weapon
rack and banner pole. The ground is x -18.8..18.8, z -16.4..16.4, the gate x -4..4 at the front, and today it grows
6 studs at the back from level 11 for the stands. The hall does not fit in front of the two back stations, so the
ground grows once at the back for every level (as the Garden and the Breeding House did; an area may grow, never
shrink): the hall and the tower stand in that strip. Today's open stands, their canopy and the scoreboard go: the
hall with its benches takes their job (the sheet has no scoreboard, and a board that only repeats numbers is against
the owner's HUD rule). No trophy anywhere (the owner, 2026-10-28).

## The ladder

As the other landmarks': an era's first level changes the architecture (and brings the training spot the rules add
there); levels 2-5 bring the four stations, each slot taking its next, different model (the kit's own, already in
`TrainingStages.PROPS`); levels 6-10 add one feature each (`f`), and a feature once added stays in every later era
in that era's materials. Kind: N a new ornament or part, U an ornament upgraded, M a material moved on, S a part
swapped for the next one.

| Level | f | Kind | What changes, as a player sees it |
|-------|---|------|-----------------------------------|
| 1 | | | The ground: a timber rail fence, a gate of two posts, the straw dummy, the archery target, the weapon rack, the banner pole, and across the back a timber drill shed under thatch, its front open on weapon racks and two rows of benches, an open timber truss in its gable |
| 2 | | N | Stone weights |
| 3 | | N | Tyre run |
| 4 | | N | Rest bench |
| 5 | | N | Sword barrel |
| 6 | 1 | N | A curved timber arch over the gate, a lantern on each of its posts |
| 7 | 2 | S | The hall's open truss is closed with boards and carries the big round wooden shield with two crossed swords; lanterns on its two front posts |
| 8 | 3 | S | The rail fence becomes a palisade of pointed logs bound with rope |
| 9 | 4 | N | A lookout stand at the hall's right end: four braced log legs, a railed platform as high as the eaves, a ladder |
| 10 | 5 | U | **The lookout becomes a tower: a cabin with a lit window under a thatch cap, well above the hall's roof, the squad's big blue banner with its gold stripe flying from its mast** |
| 11 | | M S | Era 2: cream pickets on royal-blue posts, a blue gate arch, cream plaster and royal-blue beams on the hall, red clay tiles, the shield painted blue in a gold rim, the tower boarded in cream with blue beams under a low red tiled cap, the dummy in wood with a painted chest plate |
| 12 | | U | Log barbell |
| 13 | | U | Jump hurdles |
| 14 | | U | Water cooler |
| 15 | | U | Shield rack |
| 16 | 6 | N | A long blue banner with the gold stripe hangs down the tower's front |
| 17 | 7 | N | Flower boxes along the front fence, one each side of the gate |
| 18 | 8 | N | Gold ball caps on the fence's corner and gate posts, a lit lantern under each |
| 19 | 9 | N | A railed blue gallery round the tower under its cap, with lit windows |
| 20 | 10 | U | **The tower a storey taller under a tall red cone roof of tile rows with a gold finial** |
| 21 | | M S | Era 3: a low stone wall with timber rails and stone pillars, a stone gate arch, the hall's ground floor in stone with one great arch under a blue slate roof, the shield in iron, the tower round and in stone under a blue slate cone, the dummy in an iron helmet; the punching bag and the second training spot |
| 22 | | U | Dumbbell rack |
| 23 | | U | Balance beam |
| 24 | | U | Massage table |
| 25 | | U | Armour stand |
| 26 | 11 | N | Battlements on the hall's stone shoulders, either side of the roof |
| 27 | 12 | N | Blue banners with a gold sword on the gate's two pillars |
| 28 | 13 | N | A raised iron portcullis in the gate arch, its spikes showing under the stone |
| 29 | 14 | N | A half-timbered gable storey on the hall under a higher blue slate roof: the hall stands a floor taller |
| 30 | 15 | U | **The tower a floor taller, with a crown of battlements on corbels under a tall blue slate cone and lit windows all the way up** |
| 31 | | M S | Era 4: a black steel fence with brass caps, a steel gate arch, the hall a steel and teal glass vault, the shield in steel, the tower in riveted black steel under a small glass cap, the dummy a sparring machine; the third training spot |
| 32 | | U | Weight bench |
| 33 | | U | Climbing wall |
| 34 | | U | Ice bath |
| 35 | | U | Sparring bot |
| 36 | 16 | N | Copper pipes from the tower up over the hall's vault, one down to a valve at its foot (at the capital: a lit gold lantern hangs in each bay of the portico; pipes do not belong on marble) |
| 37 | 17 | N | Two floodlight masts of steel lattice at the yard's back corners, each head a lit grid of six lamps (era 5: gold lamp standards) |
| 38 | 18 | N | Glowing green glass in the fence's panels and the gate's piers, green globe lamps on the piers |
| 39 | 19 | U | The shield in a great riveted steel ring with a glowing green rim, in front of a round fan window of teal glass |
| 40 | 20 | U | **The tower's goo core: a tall glowing green tank between steel ribs in its upper half, under a glass-and-iron dome** |
| 41 | | M S | Era 5: a white marble balustrade with gold ball caps, a marble and gold gate, the hall in marble with columns and a pediment, an arcade wing each side, the shield in gold, the tower in marble with gold bands under a small blue cap, a golden dummy |
| 42 | | U | Gravity press |
| 43 | | U | Holo hoops |
| 44 | | U | Heal pod |
| 45 | | U | Holo trainer |
| 46 | 21 | N | Gold urns of pink flowers on the fence's front corner pillars and beside the hall |
| 47 | 22 | N | Gold laurels round the shield on the pediment |
| 48 | 23 | S | The hall's roof becomes a blue glass vault with gold ribs behind a marble balustrade with gold finials |
| 49 | 24 | N | A gallery of marble columns with a gold rail round the tower's top |
| 50 | 25 | U | **The tower's great blue and gold dome on that gallery, with gold ribs, a gold lantern and finial, the banner over all** |

Walked against the step test (section 2 of the skill): no row is a count alone (lanterns, flower boxes, gold caps,
banners, masts, urns each arrive together as one set; the battlements and the masts change the outline); every row
is outside or in the open front; nothing is taken away (lookout stand, lookout tower, watchtower, keep, goo tower,
domed tower: the same part in its next form, only taller; the rail fence only becomes richer). The tower's five
forms carry the last level of every era, the dome the last of all. The weakest rows, to be made big enough at the
build: 2-5 (the kit's smallest stations, as today), 18 (caps at least 0.9 across, each lantern a real light), 28
(spikes at least 0.4 thick, dark iron against the lit yard), 47 (laurels as wide as the shield). The five era
pictures show each era's LAST level.

Against today's `TrainingStages`: its levels 6-10 moved the floor, the border, the fence and stands, the lamps and
masts and the gate arch up one material tier, one a level; those now change together at an era's first level, and
levels 6-10 are the features above. The floodlight masts move from level 21 to the sheet's place, level 37.

The owner's fences and gates (2026-11-18, `YardKit`, `hard-pieces.md` "Fences and gates"): levels 1-7 keep the
part-built rail fence, row 8 is his log rail section (it stands in for the palisade), and every later era's fence is
his section of that era; his thatched gate is row 6, his tiled, vine and royal gates come with rows 11, 21 and 41, and
his slime-tech gate is row 38 (the steel arch before it). The blue banners of row 27 hang on the gate's piers above
its flower boxes.

## Which shapes go where

Looked in the owner's sheet kit first (`src/shared/ConfigMeshyKit.luau`): the Training Hall needs no new Meshy piece.

| Goes to | Pieces |
|---------|--------|
| Parts (`Architecture`) | fences (rails, palisade logs with four-sided points (`b.pyramid`; two wedges read as blocks), pickets, stone wall and rails, steel bars with glass), the hall's walls, posts, slab roofs and thatch with rolls, benches and their runner, weapon racks, the lookout's legs, braces and ladder, the tower's square and round drums, battlements and corbels as blocks round a drum, arches with proud voussoirs, the glass vaults as flat panes between ribs, lattice masts and lamp heads, the goo tank (plain glass with a thin Neon slice), column shafts, the pediment, the hanging banners with their stripe, the portcullis |
| Blender, reused | cone roof with tile rows (the tower's caps at eras 2 and 3), glass-and-iron dome (the goo tower's cap), royal dome (the tower's dome at 50), column capital and base, balustrade run with urn (the era-5 fence and roof), copper pipe elbow |
| Blender, new (in `tools/blender/granary_pieces.py`) | B14 `ShieldEmblem`: a round domed shield with a boss (`ShieldEmblem_Disc`), its raised rim (`ShieldEmblem_Rim`) and two crossed swords, blades and hilts apart (`ShieldEmblem_Blades`, `ShieldEmblem_Hilts`), so each takes the era's material; modelled broad and shallow from the start (the Breeding House's lesson) |
| Meshy, from the owner's sheets | `ThatchCap_Tower` (the lookout's cap), `WallLantern_Iron` (gate, hall posts), `FlowerBox_Trough`, `FlowerBox_Pink` (7), `Pillar_GoldCap`, `Pillar_Lantern` (8, era 3's wall, if they fit), `Banner_Blue` or `Banner_SlimeBlue` (6, 12, if their badge suits; else parts), `Window_Arched` (the tower), `GooTank_Glass`, `PipeValve_Copper` (16, 20), `Urn_PinkFlowers`, `FlowerUrn_Gold` (21), `Laurel_Gold` (22), `Finial_GoldStone` (23), `ConePot_Topiary` (era 5) |

The flying banner on the tower is the game's own `WavingFlag`. The dummy's five forms stay the area's own build
(`TrainingStages`). Every sheet piece was already uploaded; the one new Blender piece (B14) was uploaded through
the owner's cloud place on 2026-11-17 and is worn.
