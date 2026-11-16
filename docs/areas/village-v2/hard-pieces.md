# Village v2: pieces that plain parts cannot reach

The owner's rule (2026-11-16): a block or shape that is hard to build from parts is not forced out of parts. Either
Claude builds it in Blender and fits it on the building, or the owner builds it in Meshy from a ChatGPT reference
picture. Until a piece arrives, the part-built stand-in stays in `src/server/Granary.luau`.

Reference for all of them: `granary-ref-era1.jpg` … `granary-ref-era5.jpg` in this folder.

## The Granary

### For the owner, in Meshy (organic or sculpted; Smart topology, one picture each)

Reference pictures: `art/models/granary/refs/` (cut from the ChatGPT sheets; the ledger below says which exist).

| # | Piece | Era | Replaces | Reference | Model |
|---|-------|-----|----------|-----------|-------|
| 1 | Crowned gold slime statue on a small plinth | 5 (crest, tower top, door pedestals) | `SlimeStatue` (the game's slime body, gold) | `slime_statue.png` | - |
| 2 | Gold crest cartouche: round frame, scrolls and laurel, empty middle | 5 (pediment) | `Crest*` parts | `crest.png` | - |
| 3 | Thatched gable roof: shaggy straw, thick rounded eaves, bound ridge | 1 (main roof) | `Roof` slabs | `thatch_gable_roof.png` | - |
| 4 | Thatched four-sided tower cap with a straw knot | 1 (clock tower) | tower cap slabs | `thatch_tower_cap.png` (drawn rounder than four-sided: it overhangs the square tower) | - |
| 5 | Thatched cone cap for a round silo | 1 (silos) | the tiled cone (B1) in straw colour | `thatch_silo_cap.png` | - |
| 6 | Wall lantern: iron bracket, glass lamp | all (door, lean-to) | `LeanLamp` boxes | `wall_lantern.png` | - |
| 7 | Grain sack hanging from a pulley hook on a short beam | 1-3 (lean-to) | none yet | `hanging_sack.png` | - |
| 8 | Ivy climbing a wall corner | 1-3 (front wall) | none yet | `ivy_corner.png` | - |

The eight pictures were drawn on 2026-11-16 (two 2 x 2 sheets, kept as `art/inbox/granary_refs_1.webp` and `_2.webp`) and
sent to the owner; each Meshy generation uses Smart topology (his rule).

### For Claude, in Blender (regular shapes, exact sizes, lowest triangle count)

All seven are built (`tools/blender/granary_pieces.py` -> `art/models/granary/blender/<Piece>.fbx`, sizes in
`pieces.json`) and fitted in `Granary.luau` through `Config.LibraryKit.Props` (`<Piece>_<Slot>`). Seen on the building
at levels 20/30/40/50 in a Studio preview (`review/granary-pieces-*.jpg`, made with `tools/map/landmark_preview.luau`).
**Uploaded 2026-11-17** through the owner's cloud place "Slime" (`node tools/kit/upload_village_pieces.js <studio id>`;
the test place answers "Scope 'asset:read' has not been granted"): the ids are in Config and
`art/models/village_ids.json`, and the game shows the meshes (`review/granary-real-l*.jpg`). An uploaded file comes in
half a turn round; `server/LibraryKit` turns it back.

| # | Piece | Era | Replaces | Shown from (feature step, unchanged) |
|---|-------|-----|----------|--------------------------------------|
| B1 | Cone roof with tile rows and a finial | 2-3 | stacked discs | silo caps (features 1, 2, 11), turret roofs at era 3 (12, 13) |
| B2 | Glass-and-iron dome with a brass finial | 4 | `ball` halves | tower roof, goo-tank caps, turret caps at era 4 |
| B3 | Royal dome: blue shell, gold ribs, lantern and finial | 5 | `ball` halves | tower, silos, turrets at era 5; silo crowns (22) round its lantern, the crowned slime (25) on it |
| B4 | Column: gold capital and base (the shaft stays a cylinder part) | 5 | cylinders | portico (21) |
| B5 | Balustrade run, post and urn | 5 | the gold rail and balusters | portico (21) |
| B6 | Copper pipe elbow with flanges | 4 | the diagonal `RoofPipe` rod | roof pipes of era 4 |
| B7 | Brass gear-wheel emblem | 4 | `Gear*` parts | gear over the door (16) |

### The request to ChatGPT (sent 2026-11-16 once the owner signed in: chat `/c/6afac2fc-bd18-83ec-9c57-b1e78298967f`)

Attach `granary-ref-era5.jpg` and `granary-ref-era1.jpg`, thinking effort High, a new chat, one paragraph:

> These two sheets are the approved concept art of ONE building of my cozy low-poly Roblox farm game, the slime
> farm's Granary, at five eras (thatched hamlet, painted village, stone town, slime-tech glasshouse, royal capital).
> I will build some of its hard pieces as separate 3D models with an image-to-3D tool (Meshy), so I need clean
> reference pictures of those pieces alone. With the image generator (not code), please make TWO images, each one a
> 2 x 2 grid of four separate objects, in the exact chunky, slightly toy-like low-poly style and colours of my
> sheets. Rules for every cell: one single complete object, seen from a three-quarter front view slightly from above,
> centred, filling about 80 percent of its cell, nothing cropped, nothing else in the cell; solid matte look under
> soft even overcast light with gentle form shading only (no glow, no light rays, no cast shadow on the ground, no
> reflections); plain flat light grey background #D9D9D9, wide empty gaps between the four objects, no grid lines, no
> text, no labels, no numbers, no people. IMAGE 1, reading order: (1) a gold statue of the crowned slime exactly like
> the gold slime on the pediment of my royal era (round droplet body with a small tip, two simple dark eyes and a
> small smile, a little gold crown), sitting on a low round white marble plinth with a gold rim; (2) a gold crest
> cartouche for a pediment: a thick round gold frame with scrolls and laurel leaves on both sides and a small crown
> on top, the middle left as an empty flat blue disc; (3) a wall lantern: a black wrought-iron bracket holding a
> small warm glass lamp with a little pointed cap, as on my hamlet and village eras; (4) a plump burlap grain sack
> tied with rope, hanging from an iron hook and wooden pulley under a short wooden beam. IMAGE 2, reading order: (1)
> the thatched gable roof of my first era alone, without the house: thick shaggy golden straw, deep rounded eaves, a
> bound straw ridge, open underneath; (2) the small four-sided thatched cap of the clock tower alone, shaggy straw
> with a little straw knot on top; (3) a round thatched cone cap for a wooden silo alone, layered shaggy straw with a
> small knob; (4) a clump of climbing green ivy with chunky leaves shaped to hug an outside wall corner, shown
> without the wall.

Then: bring the two sheets back (skill `chatgpt-art`, section 2), cut each cell square with the grey as padding into
`art/models/granary/refs/<piece>.png`, fill the table above.

## The Kitchen (sheet approved and built 2026-11-16, `src/server/Kitchen.luau`)

The sorting and the 50 steps are in `kitchen-ladder.md`. Seen with every piece on in a Studio preview
(`review/kitchen-final-l*.jpg` after ChatGPT's review and the last edit, `kitchen-pieces-l*.jpg` before it; made with
`tools/map/landmark_preview.luau`) and with its stand-ins in a play test (`review/kitchen-play-l*.jpg`). As for the
Granary, every piece was uploaded on 2026-11-17 and the game shows the meshes (`review/kitchen-real-l*.jpg`,
`review/kitchen-realplay-l*.jpg`).

### The owner's Meshy pieces it wears (kit names in `src/shared/ConfigMeshyKit.luau`)

| Piece (kit name) | Era | Replaces | Sheet |
|------------------|-----|----------|-------|
| `ChefEmblem_Plaque` | 3-4 (gable, feature 14) | hat and plate of parts | kitchen |
| `ChefHat_White` | 5 (on the game's gold slime, 23) | a hat of parts | kitchen |
| `Laurel_Gold` | 5 (pediment, 23) | gold trims | kitchen |
| `PotRack_Iron` | 4-5 (over the cooking line) | nothing (new) | kitchen |
| `ThatchRoof_Gable` | not worn | - (the owner's veto, 2026-11-17: straw laid over the slabs showed in patches; the part-built thatch stays) | granary |
| `WallLantern_Iron` | 1-5 (front posts, piers, columns) | box lanterns | granary |
| `FlowerBox_Pink`, `FlowerBox_Yellow` | 2-5 (16) | box planters | flowerpots |
| `Oven_Brick`, `Oven_Stone` | 2, 3-5 (10) | the oven of parts | kitchenkit |
| `CauldronFrame_Fire` | 1-3 | tripod and ball cauldron | kitchenkit |
| `ParasolTable_Red`, `ParasolTable_Blue` | 3-5 (12) | cone parasols | stall |
| `Banner_SlimeBlue` | 4-5 (16) | flat banners | village |
| `Finial_GoldStone` | 1-4 (ridge, 4) | a gold ball | restaurant |

The Granary took two from the same sheets: `GooTank_Glass` (its era-4 vats) and `Banner_SlimeBlue` (door and wing).

### Claude's Blender pieces (the village's one script, `tools/blender/granary_pieces.py`)

| # | Piece | Era | Replaces | Shown from |
|---|-------|-----|----------|------------|
| B8 | `ChimneyCrown_Gold`: a gold band, twelve points with balls | 5 | a ring of wedges | the chimney's crown (22) |
| B9 | `VentHood_Copper`: a hollow copper hood with a rolled rim | 4-5 | cones | the three hoods over the cooking line |

Reused from the Granary: B1 (the smokehouse turret, 15), B2 (the kettles' caps, 20), B3 (both domes, 24 and 25), B4
and B5 (columns, balustrades), B7 (gear, 18). The vault's ribs stay straight beams, pane by pane: a curved model
would stand off the flat glass. Oven, parasols and cauldron came from the owner's sheets instead of Blender.

## The owner's sheet models (Meshy, many props in one file)

He sends whole sheets; `tools/blender/meshy_sheet_split.py` cuts each into its pieces (names in
`tools/blender/meshy_sheets.json`), repairs open faces and smeared colour, and writes `<key>_pieces.glb`, the file he
imports, beside `pieces.json`. 80 pieces so far: granary 8 and kitchen 4 (first delivery), then village 13, stall 9,
stallitems 9, kitchenkit 7, flowerpots 10, environment 9, restaurant 11 (second delivery, 68 kept; where a piece came
twice the better one won: the village sheet's wall lantern, hoist sack and ivy corner lost to the granary's). Most
wait for the districts they belong to (stalls and shelves for the Market, lamp posts, fences and the fountain for the
village layout).

## The Garden (built 2026-11-17; B10 and B11 built in Blender, uploaded and worn)

The sorting and the 50 steps are in `garden-ladder.md`. No new Meshy piece: everything organic comes from the sheets
he already sent (`BushPot_Round`, `Trellis_Ivy`, `Ivy_Corner`, `PlanterBox_Vines`, the flower boxes, topiaries and
urns, `SlimeCrest_Laurel`, `GooTank_Glass`, `Banner_SlimeBlue`, `WallLantern_Iron`, windows and the dormer).

| # | Piece (Blender, new) | Era | Replaces | Shown from |
|---|----------------------|-----|----------|------------|
| B10 | `WindWheel_Blades`: a many-bladed wind wheel on a hub | 1 (timber), 4 (steel) | flat blade parts | the tower's wheel (5) |
| B11 | `IrrigationArch_Copper`: a copper hoop with a sprinkler head | 4-5 | straight rods | the arches over the beds (16) |

Reused: B1 (the mill's cap), B2 (the goo tank's cap), B3 (the three domes), B4 and B5 (columns, the balustrade
fence), B6 (pipes), B7 (the gate's gear), B8 (the tower's crown).

## The Breeding House (built 2026-11-17; B12 and B13 built in Blender, uploaded and worn)

The sorting and the 50 steps are in `breeding-ladder.md`. No new Meshy piece: lanterns, flower boxes, the dormer,
windows, ivy, the goo tank and its valve, banners, urns and the laurel all come from the sheets he already sent.
The egg is worn 1.1 times as wide and 0.85 times as tall as it was modelled, the heart 1.12 times as wide
(`BreedingHouse.luau`, after the final review): a next egg or emblem is modelled broad from the start.

| # | Piece (Blender, new) | Era | Replaces | Shown from |
|---|----------------------|-----|----------|------------|
| B12 | `EggDome`: a tall ovoid half shell (`_Shell`), its spots standing proud (`_Spots`), meridian ribs with two bands (`_Ribs`) | 1-5 (ribs: black steel at 4, gold at 5) | a stretched `ball` with flat discs | the egg on the hall's roof (5, 10, 15, 20, 25) |
| B13 | `HeartEmblem`: a puffy heart (`_Heart`) in a raised rim (`_Rim`) with an egg on it (`_Egg`) | 1-5 | a heart of two balls and a wedge | the gate's heart (1), the hall's emblem (2) |

Reused: B1 (the turret's cap, the egg's thatch and tile collars), B2 (the boiler's cap), B3 (the two wing domes),
B4 and B5 (columns, the balustrade fence), B6 (pipes), B7 (the gate's gear), B8 (the egg's crown).

## Other districts

Listed when each district is rebuilt.
