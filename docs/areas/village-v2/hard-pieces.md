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

| # | Piece | Era | Replaces |
|---|-------|-----|----------|
| B1 | Cone roof with tile rows and a finial (turrets, silos) | 2-3 | stacked discs |
| B2 | Glass-and-iron dome with a brass finial (tower, goo tanks) | 4 | `ball` halves |
| B3 | Royal dome: blue shell, gold ribs, lantern and finial (tower, silos, turrets) | 5 | `ball` halves |
| B4 | Column with gold capital and base | 5 | cylinders |
| B5 | Balustrade run with a corner urn | 5 | none yet |
| B6 | Copper pipe elbows with flanges | 4 | `RoofPipe` rods |
| B7 | Brass gear-wheel emblem | 4 | `Gear*` parts |

### The request to ChatGPT (not sent yet: the browser pane's ChatGPT was signed out on 2026-11-16)

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
