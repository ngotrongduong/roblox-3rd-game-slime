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
| 1 | Crowned gold slime statue on a small plinth | 5 (crest, tower top, door pedestals) | `SlimeStatue` (the game's slime body, gold) | - | - |
| 2 | Gold crest cartouche: round frame, scrolls and laurel, empty middle | 5 (pediment) | `Crest*` parts | - | - |
| 3 | Thatched gable roof: shaggy straw, thick rounded eaves, bound ridge | 1 (main roof) | `Roof` slabs | - | - |
| 4 | Thatched four-sided tower cap with a straw knot | 1 (clock tower) | tower cap slabs | - | - |
| 5 | Thatched cone cap for a round silo | 1 (silos) | stacked discs | - | - |
| 6 | Wall lantern: iron bracket, glass lamp | all (door, lean-to) | `LeanLamp` boxes | - | - |
| 7 | Grain sack hanging from a pulley hook on a short beam | 1-3 (lean-to) | none yet | - | - |
| 8 | Ivy climbing a wall corner | 1-3 (front wall) | none yet | - | - |

### For Claude, in Blender (regular shapes, exact sizes, lowest triangle count)

All seven are built (`tools/blender/granary_pieces.py` -> `art/models/granary/blender/<Piece>.fbx`, sizes in
`pieces.json`) and fitted in `Granary.luau` through `Config.LibraryKit.Props` (`<Piece>_<Slot>`). Seen on the building
at levels 20/30/40/50 in a Studio preview (`review/granary-pieces-*.jpg`, made with `tools/map/granary_preview.luau`).
**Not uploaded yet**: every `mesh` id is 0, so the game still shows the part stand-ins. The upload needs a Studio whose
place is saved to Roblox (the test place answers "Scope 'asset:read' has not been granted"), or the owner's one
File > Import 3D; then the ids go into Config and each step below shows the mesh instead.

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

## Other districts

Listed when each district is rebuilt.
