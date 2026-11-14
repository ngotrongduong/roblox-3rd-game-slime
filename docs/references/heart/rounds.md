# The Heart, rebuilt (2026-11-14): compare rounds

The owner: "the central area is designed too poorly, redesign it to be beautiful". References (ChatGPT, style-locked on the
world sheets): `heart_ref_wide.webp` (the whole crater), `heart_ref_island.webp` (the island up close),
`heart_ref_assets.webp` and `heart_ref_assets2.webp` (the six new models, cut into Meshy sources). Builder:
`tools/world/build_heart.luau` (the Heart's only builder; `build_sites.luau` keeps its folder).

## Cameras (work place, Edit, set by `execute_luau`, wait 7-8 s, capture with no camera arguments)

| Name | From | Looks at | FOV |
|---|---|---|---|
| wide | (0, 640, -6040) | (0, 132, -6660) | 60 |
| island | (0, 250, -6400) | (0, 140, -6660) | 60 |
| crown | (-60, 172, -6500) | (0, 182, -6710) | 70 |
| gate | the middle + dir(186.1 deg) x 340, 16 over the ground | the middle + (0, 30, 0) | 70 |
| spout | the spout (224, 150, -6396) + across x 22 + inward x 66 + (0, 6, 0) | the spout + inward x 10 - (0, 5, 0) | 50 |
| play | the game's own camera behind the character, standing 40 south of the middle | - | - |

## Scores (0 not met, 1 close, 2 met)

| Point | r0 (before) | r1 | r2 | r3 | r4 (final) | What differs at the end |
|---|---|---|---|---|---|---|
| 1 Silhouette and landmarks | 0 | 1 | 2 | 2 | 2 | shrine at the north of the island, arena in the middle, four spouts, six ruins, as the reference |
| 2 Palette | 1 | 1 | 2 | 2 | 2 | turquoise crystals (painted, not tinted), sandstone and gold floor, purple and teal trees |
| 3 Value structure | 1 | 1 | 2 | 2 | 2 | the pale floor and the dark shrine read against the grass |
| 4 Horizon and camera | 2 | 2 | 2 | 2 | 2 | same cameras |
| 5 Density gradient | 0 | 1 | 1 | 2 | 2 | flower beds round the arena, open grass between, two rows of trees on the far shore |
| 6 Path readability | 1 | 2 | 2 | 2 | 2 | cobble causeways edged with kerbs and lanterns, guardians where they reach the island |
| 7 Haze and depth | 2 | 2 | 2 | 2 | 2 | unchanged (the world's light) |
| 8 Scale against a player | 1 | 1 | 1 | 2 | 2 | lanterns 11, rune stones 22, guardians 28-40, shrine 104 (seen in play: `shots/play_arena.jpg`) |
| 9 Shape language | 0 | 2 | 2 | 2 | 2 | the six Meshy models are chunky and rounded like the gates |
| Job: the middle is a paved arena with a crest | 0 | 1 | 2 | 2 | 2 | the reference's crest is carved stone; ours is a picture on the floor (cheaper, flat for the fight) |
| Job: water pours from the spouts into the lake | 0 | 0 | 1 | 1 | 2 | r4: from inside the mouth, over the lip (the owner's note) |
| Job: the shrine wears a crown of crystals | 0 | 1 | 1 | 0 | 2 | r3 stacked a giant kit crystal on the roof; the owner vetoed it; the model's own crystals stay |

## What each round fixed

- **r1** first build: the six models placed, causeways edged, floor of stud slabs. Not met: the floor read as a white
  disc, crystals stayed blue under a tint, the island was bare, the spouts stood on grass with no water to be seen.
- **r2** crystals painted turquoise, warm sandstone floor with the ChatGPT medallion picture, spouts moved to the water's
  edge with beam water (attachments parented before their World* values), flower beds, taller trees.
- **r3** bigger rune stones, guardians and lanterns; lily pads smaller; a spire of kit crystals on the shrine's roof.
- **r4** the roof spire taken off (the owner: the roof already has its crystals); the spouts' water starts at the back
  of the throat and runs over the lower lip (the owner); the arena floor lowered to a tenth of a stud over the land.

## The count (performance gate)

512 kit pieces, 961 parts, 25 lights (no shadows), 31 beams, 50 unique meshes; about 91,000 triangles of new Meshy
models over the whole crater (24 lanterns x 986, 10 rune stones x 1,176, 8 guardians x 2,564, 4 spouts x 3,097,
6 colonnades x 3,028, the shrine 4,738). Measured in the work place before the last round: 294 parts collide, 425 cast
shadows. FPS on a phone: not measured.

## In the game (MapWork play test, 2026-11-14)

The world loaded with no new error ("zones of the big world ready: 14 fights, 3 gates sealed, the rim walled in 60
pieces, 22 waystones"); the Heart's fight anchor stands at y 136 (terrain 132 + its lift) over a floor whose top is
132.1; the character walked the west causeway and the arena (`shots/play_causeway.jpg`, `shots/play_arena.jpg`); a spout's
water was seen running in play.

The Heart's fight on the new floor (a second play test): waves 1 to 3 of 4 ran (Bramblehorn, Hollowheart, Calderos, all
Lv 150) against the debug menu's "late" farm; the squad's slimes stood with their bodies' bottoms at y 132.0 and
Calderos at 131.9, the floor's top being 132.1 (`shots/play_fight_wave1.jpg`, `shots/play_fight_wave3.jpg`). A monster
the camera did not face (Hollowheart) read with its mesh at its pivot, half in the ground by the numbers: most likely
the client not posing what is off screen (not proved, it was not looked at); its height comes from the terrain either
way, not from the floor.

**Not run:** the fight's last wave and win; the skill marks drawn flat on the ground, one by one; the phone view.
