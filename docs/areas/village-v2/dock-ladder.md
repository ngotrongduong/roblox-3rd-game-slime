# The Dock as a landmark: plan and upgrade ladder

Skill `landmark-build`, steps 2 and 3. Reference: `dock-ref-sheet.jpg` and `dock-ref-era1.jpg` ... `era5.jpg` in this
folder (ChatGPT chat `/c/6afb9646-8c94-83ec-883d-ece4941c74f5`, 2026-11-17, its first sheet, drawn with the Training
Hall's and the Garden's sheets and the village's three concept paintings as references). **Built and locked
2026-11-17** after the owner's "Duyệt, dựng đi": `src/server/Boathouse.luau` (the boathouse, the lighthouse, the
fence, the boat, the landing), `src/server/DockStages.luau` (where the pond's stage and the landmark meet; the area's
entry in `AreaUpgrade.OWN_STAGES`), the pier's five eras in `PondStages.luau` (`DOCK`, `dockParts`). As built, see
"As built" at the end.

## The owner's note on the sheet (2026-11-17)

"khu hồ nước ở đây vẽ hơi nhỏ nhưng ở trong khu làng tôi muốn nó lớn hơn một chút chứ không phải chỉ là cái hồ bé
tí": the sheet is the model for the boathouse, the lighthouse, the pier and the fence, NOT for the pond's size. The
pond keeps the game's size (three lobes, about 52 studs across: nearly twice the sheet's pond against the farmer),
still grows its left lobe at 21 and its right lobe at 41, and nothing of the landmark takes water away: the boathouse
stands on the back bank with only its landing on stilts over the water's edge, and the fence follows the real, big
bank. If he wants it bigger still, the lobes in `PondStages` (`LOBES`, `GROW`) are the numbers to raise.

## The place

The fishing pond (`src/server/PondStages.luau`, area `FishingPondL1`), grown into the village's harbour. The same
things at every era, in the same places, so it reads as one place:
- **The pond**, big and open in front, with its lilies.
- **The pier**, the same size at every level, from the near bank straight out over the water (fishing places 1
  and 2 are on it), with the boat tied to it.
- **The boathouse** across the back bank, its whole water side always wide open so the hanging nets, the fish rack,
  the barrels and the boat slip are seen across the pond. A player walks in round the bank.
- **The lighthouse** at the boathouse's left end as one looks from the pier's foot: a fire beacon, then a
  whitewashed tower with red bands, a round stone tower, a steel tower with a goo lamp, a marble tower under a dome.
  From level 10 on always the tallest thing, one form taller and grander at the last level of every era, its lamp
  always lit.
- **The fish**: a big round emblem with a fish in relief on the boathouse's gable over the open front (wood, painted
  blue in a gold rim, iron, steel with a green glow, gold).
- **The fence** along the near bank either side of the pier's foot, in short runs that leave the pier, the paths, the
  fish bin and the fishing places open (the slimes walk there): it never closes the pond in.

| Era | Levels | Look |
|-----|--------|------|
| 1 hamlet | 1-10 | a brown timber fishing shack on log stilts under shaggy golden thatch, a log rail fence, a small whitewashed lighthouse with one red band, a timber gallery and a thatch cap |
| 2 painted | 11-20 | cream plaster on royal-blue beams under red clay tiles, a blue and white striped awning, white pickets on blue posts with gold caps, the lighthouse white with two red bands, a blue gallery and a red cone roof |
| 3 town | 21-30 | a stone boathouse with one great boat arch under a half-timbered gable and a blue slate roof, battlements on its shoulders, a stone quay wall with iron rails and lanterns, a round stone lighthouse with an iron gallery and a blue slate cone |
| 4 slime tech | 31-40 | black riveted steel and teal glass vaults, copper pipes, a quay crane, a steel fence with glowing green glass, the lighthouse in riveted steel with a glowing green goo lamp under a glass and iron dome |
| 5 capital | 41-50 | white marble and gold, columns and a pediment, a blue glass vault with gold ribs, a marble balustrade with gold lanterns, banners with a gold crown, the lighthouse in marble with gold bands under a blue and gold dome |

What stays where the rules have it: the four fishing places (`WorkSpot1..4`: the pier's far end, the pier's middle
from 11, the side jetty from 21, the blue rock from 31) with their rod stands, the fish bin, the blue rock, the
plank path along the bank, the bench, the pond's two new lobes (21, 41) and the jetty in the left one. What the
landmark takes over: the pier's look (its deck, rails, lamps), the lighthouse (today a level-41 tower in the back
corner: it becomes the landmark's, from level 10), the back bank (today's reeds, stones and sunk log from 31 move to
the bank's free ends), the small bait shed (it stays as the bait stall of level 15). The back bank cannot grow: it
is a corner wedge between the village's two walls (measured before building: its lawn is about `50 - z` wide each
side), so the boathouse was sized to it (16 wide, 8 deep, its landing on stilts over the water's edge) and the
lighthouse stands in the corner behind its left end; the water is not made smaller for it.

## The ladder

An era's first level changes the architecture (and brings the fishing place or the pond lobe the rules add there).
Levels 2-5 are the pier and the bank: the pier's rails, its lamps, the boat and one new piece on the bank, each in
its next form an era. Levels 6-10 add one feature each (`f`), and a feature once added stays in every later era in
that era's materials. Kind: N a new ornament or part, U an ornament upgraded, M a material moved on, S a part swapped
for the next one.

| Level | f | Kind | What changes, as a player sees it |
|-------|---|------|-----------------------------------|
| 1 | | | The pond, the bare plank pier on its posts, the bench on the bank, and across the back bank a timber fishing shack on log stilts under thatch, its water side open on hanging nets, a fish rack and barrels, an open timber truss in its gable |
| 2 | | N | Log rails along both sides of the pier, bollards with rope at its head |
| 3 | | N | A lit lantern on a post at each end of the pier, both sides |
| 4 | | N | A rowboat tied to the pier, its oars in it |
| 5 | | N | A fish-drying rack with the day's catch on the bank by the path |
| 6 | 1 | S | The shack's open truss is closed with boards and carries the big round wooden fish sign; lanterns on its two front posts |
| 7 | 2 | N | A plank landing on stilts in front of the shack, out over the water's edge, with barrels and a net hung to dry between its posts |
| 8 | 3 | N | A log rail fence bound with rope along the near bank, either side of the pier's foot |
| 9 | 4 | N | A beacon at the shack's left end: a whitewashed stone stump a storey high with a fire basket burning on it |
| 10 | 5 | U | **The beacon becomes a lighthouse: the whitewashed tower well above the shack's roof with one red band, a timber gallery, a lit lantern room and a thatch cap** |
| 11 | | M S | Era 2: the pier's deck painted, white pickets on royal-blue posts, the house in cream plaster and royal-blue beams under red clay tiles, the fish painted blue in a gold rim, the lighthouse under a low red tiled cap, the net rack by the path; the second fishing place |
| 12 | | M | The pier's rails: white with royal-blue posts |
| 13 | | U | The pier's lamps: blue lanterns with gold caps |
| 14 | | S | The boat: painted blue and white, with a small mast and a red pennant |
| 15 | | N | The bait stall on the near bank: a counter of fish on ice under a red roof |
| 16 | 6 | N | A blue and white striped awning over the landing at the house's right |
| 17 | 7 | N | Flower boxes on the fence, one each side of the pier's foot |
| 18 | 8 | N | Gold ball caps on the fence's posts, a lit lantern on the two by the pier |
| 19 | 9 | N | A railed blue gallery round the lighthouse under its cap, with lit windows |
| 20 | 10 | U | **The lighthouse a storey taller with a second red band, under a tall red cone roof of tile rows with a gold finial** |
| 21 | | M S | Era 3: a stone quay wall with iron rails along the near bank, the house's ground floor in stone with one great boat arch under a blue slate roof, the fish in iron, the lighthouse round and in stone under a blue slate cone; the pond's left lobe with its jetty and the third fishing place |
| 22 | | M | The pier's rails: iron bars between stone-grey posts |
| 23 | | U | The pier's lamps: iron lanterns on stone piers |
| 24 | | S | The boat: a sailing dinghy, its mast up and a cream sail furled on the boom |
| 25 | | N | The fish cooler by the jetty |
| 26 | 11 | N | Battlements on the house's stone shoulders, either side of the roof |
| 27 | 12 | S | The plank landing becomes a stone quay apron with steps down to the water and iron mooring rings |
| 28 | 13 | U | The fish in a great riveted iron ring |
| 29 | 14 | N | A half-timbered gable storey on the house under a higher blue slate roof: the house stands a floor taller |
| 30 | 15 | U | **The lighthouse a floor taller, an iron gallery on corbels under a tall blue slate cone, lit windows all the way up** |
| 31 | | M S | Era 4: a black steel fence with brass caps, the house a steel and teal glass vault, the fish in steel, the lighthouse in riveted black steel under a small glass cap; the fourth fishing place |
| 32 | | M | The pier's rails: black steel with brass caps |
| 33 | | U | The pier's lamps: green globe lamps, and light strips along the deck's edges |
| 34 | | S | The boat: a steel launch with a brass funnel and a green lamp |
| 35 | | N | A steel crane on the quay at the house's right, a crate hanging from its hook |
| 36 | 16 | N | Copper pipes from the lighthouse up over the house's vault, one down to a valve at its foot (at the capital: a lit gold lantern hangs in each bay of the portico; pipes do not belong on marble) |
| 37 | 17 | N | A round tank of glowing green goo at the lighthouse's foot, feeding the pipes (at the capital: blue glass in gold bands) |
| 38 | 18 | N | Glowing green glass in the fence's panels, green globe caps on its piers |
| 39 | 19 | U | The fish in a great riveted steel ring with a glowing green rim, in front of a round fan window of teal glass |
| 40 | 20 | U | **The lighthouse's goo lamp: a tall glowing green tank between steel ribs in its upper half, under a glass-and-iron dome** |
| 41 | | M S | Era 5: a white marble balustrade with gold ball caps, the house in marble with columns and a pediment, the fish in gold, the lighthouse in marble with gold bands under a small blue cap; the pond's right lobe |
| 42 | | M | The pier's rails: a marble balustrade with a gold rail |
| 43 | | U | The pier's lamps: gold lanterns on marble piers |
| 44 | | S | The boat: a white and gold barge under a blue canopy |
| 45 | | N | Gold urns of pink flowers on the quay's corner piers and beside the house |
| 46 | 21 | N | Blue banners with a gold crown on the lighthouse's front and on the portico's outer columns |
| 47 | 22 | N | Gold laurels round the fish on the pediment |
| 48 | 23 | S | The house's roof becomes a blue glass vault with gold ribs |
| 49 | 24 | N | A gallery of marble columns with a gold rail round the lighthouse's top |
| 50 | 25 | U | **The lighthouse's great blue and gold dome on that gallery, with gold ribs, a great gold lantern and finial** |

Walked against the step test (section 2 of the skill): no row is a count alone (rails, lamps, flower boxes, gold
caps, banners and urns each arrive together as one set; the landing, the beacon, the battlements, the crane and the
gable storey change the outline); every row is outside, on the water or in the open front; nothing is taken away
(beacon, lighthouse and its four later forms are the same part, only taller; the landing becomes the stone apron,
the boat its next boat). The lighthouse's five forms carry the last level of every era, the dome the last of all.
The weakest rows, to be made big enough at the build: 3 (each lantern a real light, its post at least 4 high), 5
(the rack at least 4 wide, on the bank and not behind the bench), 17 (boxes at least 3 long, flowers in two
colours), 18 (caps at least 0.9 across), 28 (the ring at least 0.5 thick, dark iron on the pale gable), 47 (laurels
as wide as the fish). The pier's rails and lamps stay one era behind the house for one or two levels after an era's
first level, as the pond's parts always did. The five era pictures show each era's LAST level.

Against today's `PondStages`: its ten material tiers of five levels (deck, rails, lamps, bait box, bollards, one a
level) become the five eras above; the bait box and the bollards come with the rails (row 2) and take the era's
material with them; the bait shed moves from 11 to 15, the fish cooler from 21 to 25, the lighthouse from 41 to 10.
The net rack (11), the bank path (11, longer at 21), the bench, the fishing stool on the right bank, the crystal
buoy and the beacon of 41 stay as they are.

## Which shapes go where

Looked in the owner's sheet kit first (`src/shared/ConfigMeshyKit.luau`): the Dock needs no new Meshy piece.

| Goes to | Pieces |
|---------|--------|
| Parts (`Architecture`) | the pier (planks, beams, posts, rails, bollards), fences (log rails, pickets, stone wall with iron rails, steel bars with glass), the boathouse's stilts, walls, posts, slab roofs and thatch with rolls, the landing and the stone apron with its steps, hanging nets (thin crossed rods in a frame), the boat arch with proud voussoirs, battlements, the glass vaults as panes between ribs (0.08 see-through, darker than the sky), the crane (a lattice jib, a hook, a crate), the lighthouse's round drums and bands, galleries, corbels, the lantern room (panes in a frame, a deep amber lamp), the goo tank (plain glass with a thin Neon slice), column shafts, the pediment, banners, the boats (the pond's own hull from parts, with mast, sail, funnel or canopy added) |
| Blender, reused | cone roof with tile rows (the lighthouse's caps at eras 2 and 3), glass-and-iron dome (the goo lamp's cap), royal dome (the dome at 50), column capital and base, balustrade run with urn (the era-5 fence and pier), copper pipe elbow |
| Blender, new (in `tools/blender/granary_pieces.py`) | B15 `FishEmblem`: a round disc (`FishEmblem_Disc`), its raised rim (`FishEmblem_Rim`) and a plump fish in relief with its tail, fin and eye (`FishEmblem_Fish`), each apart so it takes the era's material; modelled broad and shallow, the fish standing proud of the disc |
| Meshy, from the owner's sheets | `ThatchCap_Tower` (the lighthouse's cap at era 1), `FishRack_Wood` (5, and inside the open front), `Barrel_Oak`, `BarrelStack_Three`, `CrateStack_Wood`, `RopeHook_Coil` (the landing and the boathouse), `WallLantern_Iron` (6), `FlowerBox_Trough` or `FlowerBox_Pink` (17), `Pillar_GoldCap`, `Pillar_Lantern` (the era-3 quay, if they fit), `Window_Arched` (the lighthouse), `GooTank_Glass`, `PipeValve_Copper` (36, 37), `Banner_Blue` (46, if its badge suits; else parts), `Urn_PinkFlowers` (45), `Laurel_Gold` (47), `Finial_GoldStone` |

The kit's own pond models (`LogBench`, `NetRack`, `FishCooler`, `CrystalBuoy`, `FishBucket`) stay where `PondStages`
places them.
