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
| B16 | `ToolStoreTech`: a whole tool store, one mesh a material (`_Plinth`, `_Brick`, `_Glass`, `_Frame`, `_Roof`, `_Gold`, `_Copper`, `_Door`; its lantern is the kit's `WallLantern_Iron`); 6970 triangles | 4 | nothing (the timber shed stood only at eras 2-3) | the work yard, door to the beds |
| B17 | `ToolStoreRoyal`: the marble tool store (`_Marble`, `_Gold`, `_Roof`, `_Glass`); 5844 triangles | 5 | nothing | the work yard, door to the beds |

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

## The Training Hall (built 2026-11-17; B14 built in Blender, uploaded and worn)

The sorting and the 50 steps are in `training-ladder.md`. No new Meshy piece: the lookout's thatch cap, lanterns,
flower boxes, pillars, banners, the goo tank and its valve, urns, the laurel and the finials all come from the
sheets he already sent.

| # | Piece (Blender, new) | Era | Replaces | Shown from |
|---|----------------------|-----|----------|------------|
| B14 | `ShieldEmblem`: a round domed shield with a boss (`_Disc`), its raised rim (`_Rim`), two crossed swords with blades and hilts apart (`_Blades`, `_Hilts`) | 1-5 (wood; blue in a gold rim; iron; steel with a green rim; gold) | a flat disc with two crossed bars | the hall's emblem (2), the gate's small one |

Reused: B1 (the tower's cone caps at eras 2 and 3), B2 (the goo tower's cap), B3 (the tower's dome at 50), B4 and
B5 (columns, the balustrade fence and roof), B6 (pipes).

## The Dock (built 2026-11-17; B15 built in Blender, uploaded and worn)

The sorting and the 50 steps are in `dock-ladder.md`. No new Meshy piece: the lighthouse's thatch cap, the fish
rack, barrels, crates, the rope coil, lanterns, flower boxes, pillars, the goo tank and its valve, banners, urns,
the laurel and the finials all come from the sheets he already sent.

| # | Piece (Blender, new) | Era | Replaces | Shown from |
|---|----------------------|-----|----------|------------|
| B15 | `FishEmblem`: a round disc (`_Disc`), its raised rim (`_Rim`), a plump fish in relief with tail and fins (`_Fish`), its eye apart (`_Eye`); 734 triangles; the head to the viewer's left, as the sheet | 1-5 (wood; blue in a gold rim; iron; steel with a green rim; gold) | a flat disc with a ball and a wedge | the boathouse's emblem (1) |

Reused: B1 (the lighthouse's cone caps at eras 2 and 3), B2 (the goo lamp's cap), B3 (the dome at 50), B4 and B5
(columns, the balustrade fence and pier rails), B6 (pipes).

## Era props from the owner's five sheets (2026-11-18, Meshy Smart Topology by Claude)

The owner sent five sheets of props, each a ladder through the eras (`props/<sheet>-sheet.jpg`): "với mỗi một hình
hãy yêu cầu chatgpt dựng 1 hình cho 1 vật phẩm. rồi sau đó liên kết với meshy dựng hình smart topology. nhớ chọn số
lượng mesh cho phù hợp với từng vật phẩm". One ChatGPT chat a sheet drew one picture an object
(`tools/chatgpt/props.py` holds the requests, names and triangle counts); the pictures are
`art/models/village_props/<sheet>/refs/<piece>.png`; each went to Meshy Smart Topology (Meshy T2.5, Texture on with
Meshy N1 at 2K, Private, 15 credits) at the triangle count below: more for pieces seen big or full of leaves and
flowers, less for flat signs and banners that hang many times. Credits: 628 before, 31 x 15 spent.

| Sheet | Piece | Era | Triangles asked | Got | GLB MB |
|-------|-------|-----|-----------------|-----|--------|
| lamppost | `lamp_wood` gallows post, hanging lantern | 1 | 2000 | 1902 | 2.3 |
| lamppost | `lamp_painted` teal post, tiled cap | 2 | 2500 | 2482 | 2.9 |
| lamppost | `lamp_stone` brick pillar, ivy | 3 | 3000 | 3080 | 3.1 |
| lamppost | `lamp_tech` riveted iron, glass dome, gear | 4 | 3500 | 3548 | 3.2 |
| lamppost | `lamp_royal` marble column, crown dome, banner | 5 | 4000 | 3957 | 3.5 |
| flowerpot | `pot_clay` terracotta, daisies | 1 | 1500 | 1516 | 2.1 |
| flowerpot | `pot_barrel` barrel tub, pink flowers | 2 | 2000 | 2002 | 2.6 |
| flowerpot | `pot_stone` brick cube, purple flowers | 3 | 2000 | 2007 | 2.6 |
| flowerpot | `pot_crown` cream stone, blue crown panels | 4 | 2500 | 2490 | 2.3 |
| flowerpot | `pot_urn` marble urn, roses | 5 | 3000 | 2839 | 3.4 |
| planter | `planter_wood` plank trough, yellow | 1 | 1500 | 1438 | 2.9 |
| planter | `planter_riveted` riveted trough, pink | 2 | 2000 | 1885 | 2.9 |
| planter | `planter_stone` brick trough, blue | 3 | 2000 | 2017 | 3.5 |
| planter | `planter_crown` cream stone, crown panel | 4 | 3000 | 2800 | 3.0 |
| planter | `planter_royal` marble balustrade, banner, roses | 5 | 4000 | 3828 | 3.2 |
| cart | `cart_barrow` hand cart | 1 | 3000 | 3100 | 2.8 |
| cart | `cart_awning` striped awning stall cart | 2 | 4000 | 3920 | 3.2 |
| cart | `cart_roofed` tiled roof, lanterns | 3 | 5000 | 4871 | 3.9 |
| cart | `cart_glass` glass vault, iron arches, gear | 4 | 6000 | 5579 | 3.6 |
| cart | `cart_royal` marble and gold, blue dome | 5 | 6000 | 5932 | 4.3 |
| kitchen | `sign_hat` hanging sign, chef's hat | - | 1500 | 1515 | 2.8 |
| kitchen | `sign_spoon` hanging sign, fork and spoon (the owner's second build) | - | 1500 | 1502 | 2.5 |
| kitchen | `banner_red_hat` red pennant, chef's hat | - | 1000 | 1003 | 1.6 |
| kitchen | `banner_blue_spoon` blue pennant, fork and spoon | - | 1000 | 1029 | 2.2 |
| kitchen | `emblem_chef_slime` gold laurel, slime in a chef's hat | - | 2500 | 2484 | 2.1 |
| kitchen | `emblem_spoon_ribbon` red, fork and spoon, ribbons | - | 2000 | 1991 | 2.6 |
| kitchen | `finial_bell` gold bell finial on bricks | - | 1000 | 973 | 2.9 |
| kitchen | `window_roofed` window, tiled hood, flower box | - | 2500 | 2398 | 2.7 |
| kitchen | `window_arch` arched stone window, flower box | - | 2000 | 2039 | 2.6 |
| kitchen | `window_shutters` green shutters, flower box | - | 2000 | 1920 | 2.6 |
| kitchen | `window_plain` plain wooden window (second build) | - | 1000 | 1048 | 2.4 |

ChatGPT chats: lamppost `/c/6afd2678-b94c-83ec-9204-a2136078aa06`, flowerpot `/c/6afd26ac-3ec4-83ec-a4b2-7adf6dac3ccb`,
planter `/c/6afd26e4-a4a0-83ec-a138-3d1d76ad1bee`, cart `/c/6afd2703-9a4c-83ec-8eaf-7195c09d260a`, kitchen
`/c/6afd272f-90c8-83ec-9474-186a75056b89`. `cart_glass` is cut from a picture that also showed the royal cart's dome
at its foot; `cart_royal` was asked for again on its own.

Downloaded the same day: `art/models/village_props/<sheet>/<piece>.glb`, beside `refs/`. Every file is one mesh, one
material and one 2048 px texture; its triangles equal the Faces Meshy showed; it is about 0.95 units on its longest
side (rescale on placing). Each was rendered from the front-left and the back-right (`review/`, not committed) and
put beside its picture. Two builds were redone: `sign_spoon` by the owner, who regenerated it in Meshy, and
`window_plain`, whose first build had dark blue glass in front (yellow only at the back): regenerated once (15
credits, 153 -> 138), after which the owner said not to fix in Meshy any more ("không sửa ở meshy nữa tốn token")
and that a simple fault like that is fixed in Blender, free. The rest showed no fault. Facing: most fronts look
along glTF +Z; the five lamp posts show their decorated side along -Z, so check each one when it is placed.

Next: upload with `upload_village_pieces.js`, and the ladders of the buildings and the village layout point at them.

### Fences and gates (same day, same way)

The owner added two more sheets, "thêm bộ hàng rào và cổng này nữa": five fence sections and five entrance gates, one
an era (`props/fence-sheet.jpg`, `props/gate-sheet.jpg`; ChatGPT chats fence `/c/6afd382d-0aa8-83ec-9602-74d45008a3e7`,
gate `/c/6afd385c-39fc-83ec-8d39-1eb1f364c7ec`). Credits were 138, and ten builds cost 150, so the four lighter fences
went two to a picture (`fence/refs/pair_*.png`: each fence cut to its outline, the two stacked as rows on the same grey
with a 12 percent gap) and were split again in Blender by loose parts above and below the empty band; the pair files
are kept in `fence/pairs/`. Midway the owner asked for the gates one at a time ("dựng cổng chính từng cái một vì cổng
nhiều chi tiết, làm nhiều cái cùng 1 lúc chất lượng không cao"): thatch, tiled and vine had already been queued
together, tech and royal waited each for the one before. All five gates were then looked at closely (straight front
and back, 720 px): none of the three queued together shows a fault. 8 x 15 credits, 138 -> 18.

| Sheet | Piece | Era | Triangles asked | Got | GLB MB |
|-------|-------|-----|-----------------|-----|--------|
| fence | `fence_rail` log posts on stones, branch rails, rope | 1 | 1200 (pair 2400) | 1996 | 2.7 |
| fence | `fence_picket` cream pickets, teal posts, gold caps | 2 | 1200 (pair) | 466 | 2.6 |
| fence | `fence_stone` brick pillars, wooden X brace | 3 | 1500 (pair 3500) | 1200 | 2.2 |
| fence | `fence_iron` riveted iron pillars, arched railing | 4 | 2000 (pair) | 2310 | 2.2 |
| fence | `fence_royal` marble balustrade, crown banners | 5 | 2500 | 2418 | 2.7 |
| gate | `gate_thatch` timber frame, straw roof, log fences | 1 | 3000 | 3002 | 3.1 |
| gate | `gate_tiled` teal arch, tiled gable, lanterns | 2 | 3500 | 3238 | 3.1 |
| gate | `gate_vine` brick arch, vine pergola, grapes | 3 | 4500 | 4256 | 3.2 |
| gate | `gate_tech` riveted iron arch, glass dome, gear | 4 | 4500 | 4467 | 3.5 |
| gate | `gate_royal` marble arch, blue dome, crown banners | 5 | 5000 | 4945 | 3.1 |

The pair builds came out at 2462 and 3510 triangles; their halves keep the pair's shared texture and are centred on
their own box. A split fence is about 0.65 units long and every other piece about 0.95: rescale on placing. The gates'
backs are plainer than their fronts (one picture each): face the front to the road. Meshy gave every front along glTF
+Z, which shows backwards in the game, so all ten carry the kitchen pieces' half turn (node rotation [0, 1, 0, 0]):
their fronts now look along -Z like the lamps' (rendered again from both sides). The pairs in `fence/pairs/` are left
as Meshy gave them and are not uploaded.

**Worn (2026-11-18, the owner: "nhập chúng vào kho asset và dùng chúng cho các khu đất").** `src/server/YardKit.luau`
puts them round the yards of the Breeding House, the Garden and the Training Hall at every era, and the Kitchen's
`GateArch` wears the gate of its tier. In the game a section's +x end stands at its start, so each fence is cut in
Blender (`tools/blender/fence_open.py`) into `<key>_open.glb` (start post cut off) and `<key>_bare.glb` (both cut
off): a run is open sections, a post at each section's end and none at its start, each corner takes its post from
the run that ends there, and the run that ends at a gate ends with the bare one, because the gate model's own short
wings carry its end posts. Config rows `PropFence<Era>Open` and `PropFence<Era>Bare` (the bare one's size and `at`
from its own GLB bounds, scaled like the full section: a bare box is shorter and lower than the full one). The era-1
thatched gate is the ladders' first gate step (plain posts before it); the slime-tech gate swaps in at the step that
put the steel arch on: Breeding 16, Garden 17, Training 18. Training's era 1 has no fence until its step 3 (the rail
fence; the owner's rail section stands in for the palisade). Banners on the gate piers stand above the gates' flower
boxes. Not worn yet: the Dock's bank fence and the village's outer wall keep their own, and the kitchen's signs,
emblems and windows are uploaded but not placed.

### Windows, one an era (2026-11-18, drawn by ChatGPT at the owner's request)

The owner: "yêu cầu chat gpt vẽ cho tôi lại bộ cửa sổ cho 5 thời kỳ". The kitchen sheet's four windows were not an era
ladder, so ChatGPT redrew them as five, one an era, with the gate, kitchen and lamp-post sheets attached as the style
lock (chat `/c/6afd6537-2600-83ec-9f45-e5a5aa60c4b2`). The owner wants the frames alone ("tôi chỉ muốn khung cửa sổ
thôi, không có hoa, không có mái che gì cả"): no flower box, plant, roof, hood or banner; each era told by its frame:
1 log and plank lashed with rope; 2 teal painted timber with cream panels and gold caps; 3 an arched pale stone-brick
surround with a gold diamond keystone; 4 a round-topped riveted iron frame with teal glass and a brass gear; 5 an
arched cream marble frame with gold trim and a gold crown keystone. The sheet is `props/window-sheet.jpg`. Next, once the owner approves it: one picture a window (`tools/chatgpt/props.py`), then
Meshy Smart Topology (about 2000 triangles each).

## Other districts

Listed when each district is rebuilt.
