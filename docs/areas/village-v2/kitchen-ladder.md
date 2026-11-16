# The Kitchen as a landmark: plan and upgrade ladder

Skill `landmark-build`, steps 2 and 3. Reference: `kitchen-ref-sheet.jpg` and `kitchen-ref-era1.jpg` ... `era5.jpg` in
this folder (ChatGPT chat `/c/6afae216-2974-83ec-a85c-e5b5281ae5b3`, 2026-11-16). **The owner has not yet said the
sheet is the model: nothing is built before he does.**

## The building

A cookhouse that grows into a grand restaurant. The same three things at every era, so it reads as one building:
- **The hall**, front always wide open (posts, then arches, then columns) so the cooking line is seen from outside:
  the kit stove, counter and firewood, and the three cooking spots (`CookingSpot1..3`, levels 1 / 21 / 31) stay
  where `KitchenStages.luau` has them.
- **The great chimney** on the left as one walks in (+x), always the tallest thing, always smoking.
- **The terrace** on the right (-x): where the slimes' food is eaten; its cover is the part that changes most.

| Era | Levels | Look |
|-----|--------|------|
| 1 hamlet | 1-10 | thatch on brown timber posts, cream plaster gable, fieldstone chimney, a cauldron over the fire |
| 2 painted | 11-20 | cream plaster on teal beams, red clay tiles, red brick chimney with a cream cap |
| 3 town | 21-30 | stone ground storey with open arches under a jettied half-timbered storey, stone chimney |
| 4 slime tech | 31-40 | red brick foot, black steel frame, glass vault roof, copper hoods over the stoves |
| 5 capital | 41-50 | white marble and gold, columns and a pediment, blue slate and domes |

The pad today is x -14.3..14.3, z -11.7..11.7. The terrace needs room on the right: the area grows once to -x when the
lean-to arrives (an area may grow, never shrink); the size is measured at the build.

## The ladder

As the Granary's: an era's first level changes the architecture; levels 2-5 bring the four kitchen props, each slot
taking its next, different model (the kit's own, already in `KitchenStages.PROPS`); levels 6-10 add one feature each
(`f`), and a feature once added stays in every later era in that era's materials. Kind: N a new ornament or part,
U an ornament upgraded, M a material moved on, S a part swapped for the next one.

| Level | f | Kind | What changes, as a player sees it |
|-------|---|------|-----------------------------------|
| 1 | | | The cook shed: thatch on posts, the fieldstone chimney, a fire with a hanging cauldron |
| 2 | | N | Veggie crates |
| 3 | | N | Camp grill in the front yard |
| 4 | | N | Rain barrel |
| 5 | | N | Dish rack |
| 6 | 1 | N | Big lanterns hung on the two front posts: warm light on the front |
| 7 | 2 | S | The open gable truss is closed with cream plaster and a shuttered window |
| 8 | 3 | U | The chimney grows a third taller, gets a capstone and starts to smoke |
| 9 | 4 | N | A gold finial with the blue pennant on the ridge |
| 10 | 5 | N | **A straw lean-to on the right over a plank table and benches: the first terrace** |
| 11 | | M S | Era 2: teal beams, red clay tiles for thatch (the lean-to too), the chimney in red brick |
| 12 | | U | Pickle barrels |
| 13 | | U | Stone grill |
| 14 | | U | Hand pump |
| 15 | | U | Plate shelf |
| 16 | 6 | N | Flower boxes under the gable window and at the front corners |
| 17 | 7 | N | A small gabled wing at the right back with its own lit window |
| 18 | 8 | S | The lean-to's roof becomes a red-and-white striped awning |
| 19 | 9 | N | A dormer on the main roof |
| 20 | 10 | N | **A domed brick bread oven at the chimney's foot, its mouth glowing** |
| 21 | | M S | Era 3: a stone storey with three open arches, a jettied half-timbered storey over it, a stone chimney |
| 22 | | U | Spice cabinet |
| 23 | | U | Brick barbecue |
| 24 | | U | Stone sink |
| 25 | | U | Serving cart |
| 26 | 11 | S | The terrace is raised on stone with a balustrade wall |
| 27 | 12 | N | Two striped parasols over new tables: the terrace reaches further out |
| 28 | 13 | S | The blank side bays of the stone storey become lit arched windows |
| 29 | 14 | N | The chef-hat emblem with wheat ears on the gable |
| 30 | 15 | N | **A smokehouse turret on the chimney: a timber lantern room under a red cone roof** |
| 31 | | M S | Era 4: brick foot, black steel frame, a glass vault roof, copper hoods; the chimney banded in iron and brass |
| 32 | | U | Ice box |
| 33 | | U | Steel grill |
| 34 | | U | Steel sink |
| 35 | | U | Buffet warmer |
| 36 | 16 | N | Blue banners on the front piers |
| 37 | 17 | N | Copper pipes from the chimney over the glass roof |
| 38 | 18 | U | A brass gear wheel round the emblem on the gable |
| 39 | 19 | S | A glass canopy with hanging lamps over the terrace, in the awning's place |
| 40 | 20 | N | **Two kettles of glowing green goo beside the chimney, piped into it** |
| 41 | | M S | Era 5: white marble and gold, columns across the front, a pediment, blue slate; a marble chimney |
| 42 | | U | Goo fridge |
| 43 | | U | Plasma grill |
| 44 | | U | Goo tap |
| 45 | | U | Food dispenser |
| 46 | 21 | N | A balustrade with gold urns along the roof's edge |
| 47 | 22 | U | A gold crown on the chimney's top |
| 48 | 23 | U | The emblem's hat becomes a golden chef slime between gold laurels |
| 49 | 24 | S | The terrace becomes a round colonnade under its own small blue dome |
| 50 | 25 | N | **The great blue dome with gold ribs and a gold lantern over the hall** |

Walked against the step test (section 2 of the skill): no row is a count alone (one dormer, one wing, two parasols
that arrive together, two kettles together); every row is outside or in the open front; nothing is taken away (the
awning becomes the canopy, then the colonnade: the same part in its next form). The weakest rows, to be made big
enough at the build: 6 (lanterns of 1.6 studs with real light), 9 (finial and a 2.6-stud flag), 16 (boxes 3 studs
wide, bright flowers). Not yet seen side by side in a preview: that is step 6.

## Which shapes go where

| Goes to | Pieces |
|---------|--------|
| Parts (`Architecture`) | hall walls, posts, arches' piers, slab roofs, the chimney's shafts and bands, the oven's base, the wing, the dormer, awning slabs in stripes, tables and benches, banners, flower boxes, the terrace floor, the glass vault as flat panes between the ribs |
| Blender, reused from the Granary | cone roof with tile rows (the smokehouse turret), royal dome (both domes), column capital and base, balustrade run with urn (terrace wall, roof edge), copper pipe elbow, brass gear wheel, glass-and-iron dome (the kettles' caps) |
| Blender, new (`tools/blender/kitchen_pieces.py`) | oven dome with its arched mouth; parasol (eight gores, two colour slots); steel vault rib; copper vent hood; cauldron; chimney crown |
| Meshy, the owner | chef-hat emblem with wheat ears (carved plaque, eras 3-4); a chef's hat alone (worn by the game's own slime, gold, at era 5); a pair of gold laurel branches (era 5 pediment) |
| Meshy, already asked for the Granary | the thatched gable roof (era 1 roof), the wall lantern, the ivy corner: the same models fit here |

The golden chef slime is the game's own slime body in gold with the owner's chef hat on it, as the Granary's statue.
The request for the three new Meshy reference pictures goes to ChatGPT once the owner has approved the sheet, so no
Meshy credits are spent on a design he might change.
