---
name: landmark-build
description: Use when a village building of Goo Lineage V2 that upgrades through its 50 levels is built or rebuilt as a landmark (the Granary is done; kitchen, garden, breeding pen, training ground, dock and the village's own pieces follow), when its upgrade ladder is planned or judged, when a shape is too hard for Roblox parts and must go to Blender or the owner's Meshy, or before changing src/server/Architecture.luau or a landmark module such as Granary.luau.
---

# Landmark build: one village building, from reference to locked

The owner's goal (2026-11-16): the village's buildings taller, with more fine detail, better finished and sensibly
built, about 90% like their reference, in real materials, hollow where a player can walk in. The Granary
(`src/server/Granary.luau`) went this road first, from 60-74 to 80-86 of 100 in ChatGPT's eyes; every later building
follows it so nothing is found out twice. Replies to the owner are in Vietnamese; every word in the game is English.

Read first, and only these: the two Granary sections of `.claude/skills/studio-build/LESSONS.md` ("Landmark buildings
from parts", "The Granary, a landmark built from parts against a reference sheet" with the notes under it),
`docs/areas/village-v2/hard-pieces.md`, and the header of `Granary.luau` as the worked example. Props that stand
round the building are skill `area-review` and `prop-craft`; sending pictures is skill `chatgpt-review`.

## 1. The road, in order

Each step has its gate. Do not start a step before the gate of the one before it.

1. **Reference.** One ChatGPT concept sheet of the ONE building at its five eras (skill `chatgpt-art`, the village's
   earlier sheets as the style lock), saved as `docs/areas/village-v2/<name>-ref-era<N>.jpg`. *Gate: the owner says
   the sheet is the model.* This is the only thing he must approve before building; nothing is built without it.
   What gave a usable sheet at the first try (the Kitchen): a new chat, the Granary's sheet and the village concept
   attached, "ONE new sheet in exactly the same style, layout and camera as picture 1" (three on top, two below, the
   same farmer figure for scale, grey studded ground, no text), then each era in one clause, then the rules that
   make it ONE building (what stays on which side at every era, what is always open, each era taller and richer).
   With the pane hidden, carry the pictures by script (skill `meshy-multiview`, "With the pane hidden"). Cut the
   sheet into the five era files with a small PIL script; send the whole sheet to the owner.
2. **Ladder.** Write the building's 50 steps as a table in `docs/areas/village-v2/<name>-ladder.md` BEFORE any code
   (section 2). *Gate: every row passes the step test.*
3. **Sort the shapes** (section 3) into parts, Blender and Meshy, and fill `hard-pieces.md`; look first at what the
   earlier landmarks' pieces already give (domes, cone roofs, columns, balustrades, pipes, gears are shared) and at
   the owner's sheet kit (`src/shared/ConfigMeshyKit.luau`: ovens, parasol tables, banners, flower boxes, lanterns,
   finials, stalls; a piece is worn with `painted(name, cf, scale)` over its part stand-in). Steps 2
   and 3 are paper and are done while the owner looks at the sheet. Once he has approved it, send ONE request to
   ChatGPT for the Meshy pieces' reference pictures (two 2 x 2 sheets hold eight pieces; the request text of the
   Granary is in `hard-pieces.md`), cut them into `art/models/<name>/refs/` and send them to the owner, so he builds
   while the rest goes on.
4. **Build from parts.** One module a landmark on `Architecture.new(...)`: a palette and sizes per era,
   `features(level)`, a part stand-in for every hard piece. Hollow hall, tower on tie beams, roofs as two thin slabs.
5. **Blender pieces.** Added to the village's one script (`tools/blender/granary_pieces.py`), every object its own
   `Config.LibraryKit.Props` entry `<Piece>_<Slot>` with `mesh = 0`; the module asks by name and keeps the stand-in
   when it gets nil. So the code ships before any upload and the ladder never changes.
6. **Look, in Edit, without a play test.** The preview tool (`tools/map/landmark_preview.luau`, the module passed as
   `Landmark=src/server/<Name>.luau`; its header has the command) builds the levels in its `LEVELS` list side by
   side with the Blender AND Meshy pieces on; `screen_capture` with a camera position shoots them. Self-review
   against the reference (section 5) and fix. Destroy the preview folders at the close.
7. **One play test** (StudioTest only): `tools\map\sync_all.ps1 -StudioId <id>` (the whole game, so Config and every
   module of the chain are fresh), `_G.AreaShow` at the last level of each era (`task.wait(1.5)` in the same call,
   then the shot), read the console. It shows the STAND-INS (every `mesh` is 0 until the owner's import).
   *Gate: no error, the look holds in the game's light.*
8. **ONE ChatGPT review, at the end** (the owner's requirement; my own way first): the five era shots from the Edit
   preview (the pieces on; closer than the self-review shots, the building filling half the frame), sent in the chat
   that drew the reference sheet, one paragraph saying what must not be judged (the preview's empty hall and lawn:
   the stations and floor are the area module's), scores per era and the 5-8 best fixes. Check
   every point against the code and the reference, then ONE last edit. No second round.
9. **Close.** `tools\check.ps1` (CHECK OK), `tools\types.ps1 src/server` (TYPES OK), the final shots in
   `docs/areas/village-v2/review/`, `docs/STATUS.md`, new lessons into `LESSONS.md` and INTO THIS SKILL in the same
   commit, commit only the job's own paths.
10. **The owner's part**, asked in the closing box and never waited for: the mesh upload (a Studio place saved to
    Roblox, or his File > Import 3D of the FBX files), his Meshy pieces (Smart topology), any ChatGPT sign-in.

## 2. The upgrade ladder (the owner's rules, 2026-11-16)

"Sau mỗi nâng cấp nhỏ sẽ có một chút thay đổi cho công trình ... Những thay đổi này tuy nhỏ nhưng phải nhìn thấy
được dễ dàng và thực sự là thấy có sự nâng cấp hơn cấp trước chứ không phải kiểu trước có 2 bông hoa bây giờ thì có
3 bông. Nói chung là phải có sự thay đổi về hình thái, màu sắc, chất liệu rõ ràng." And earlier the same day: one
small part a level, the biggest change at the last level.

A step is ONE of these four kinds, his own list:

| Kind | What changes | Granary examples |
|------|--------------|------------------|
| A new ornament | something that was not there | a bell, banners, a weathervane, a second silo |
| An ornament upgraded | the same thing in its next form | a plain lamp to a lantern, a cone cap to a dome |
| A material moved on | a surface takes the next material | thatch to clay tiles, wooden silo to stone |
| A part swapped | one part becomes the next era's part | the tower cap, the door, the lean-to roof |

The step test, every row of the ladder:
- **Seen at once**: from the plot's play camera, with level N and N+1 side by side, a person told nothing points at
  the change. It is a change of SHAPE, COLOUR or MATERIAL on something at least about 2 studs big or a whole surface.
- **Never a count alone**: a third flower, a fourth crate, one more window box is not a step. More of the same only
  counts when it changes the outline (a second silo does; a third sack does not).
- **Never hidden**: not inside the hall, not behind the building, not under a roof.
- **Better, not just different**: richer material, finer form, more light. Nothing is taken away at a later level.
- **The grandest step is level 50**, and each era's last level carries that era's biggest step (my reading).
- A step is its own piece: a Blender or Meshy model is never one fused building, so each piece can arrive, change
  material or colour on its own level.

To judge a ladder cheaply: put an era's ten levels in the preview tool's `LEVELS`, shoot the row once, walk the pairs.

## 3. Which shapes go where

Hard shapes are never faked from parts (the owner's rule). Decide at step 3, not after three rounds of trying.

| Goes to | Shapes | How |
|---------|--------|-----|
| Parts (`Architecture`) | walls, slab roofs, beams, posts, round drums, flat discs, windows, awnings, steps | the builder `b`; materials carry the texture |
| Blender, by me | regular curved or repeated shapes with exact sizes: cone roofs with tile rows, ribbed domes, capitals and bases, balustrades, pipe elbows, gears, arches with mouldings | one script, lowest triangle count, a kit prop with a stand-in |
| Meshy, by the owner | organic or sculpted: statues, crests and cartouches, shaggy thatch, ivy, sacks, lanterns with fine iron, animals | a row in `hard-pieces.md` and a ChatGPT reference picture of the piece alone; Smart topology |

A slime statue is neither: it is the game's own slime (`ClientKit.SlimeBody` in a Model, `ScaleTo`).
`hard-pieces.md` is the ledger: piece, era, what it replaces, reference file, model. A piece nobody has built yet
keeps its stand-in and is named in the review brief as "not to be judged".

## 4. Least time, least tokens

- Look in Edit (step 6) as often as needed; enter Play once (step 7). A play session costs ten times a preview.
- Shoot the last level of each era and nothing between, plus ONE close-up of every ornament.
- `tools\types.ps1 src/server` BEFORE syncing to Studio; it catches what a sync would only show as a runtime error.
- ChatGPT twice a building at most: the reference pictures (step 3) and the final review (step 8). While it thinks,
  write the docs; poll with javascript loops of 35 s at most (the tool stops at 45 s); read the answer as text.
- Grep for a section of `Granary.luau` or `LESSONS.md`; never read those files whole.
- I build it myself with no subagent unless a piece is truly separate work (then one agent, Sonnet medium).
- The owner's numbers and notes go in as he says them, with no extra round first.

## 5. Self-review before anyone else sees it

- Every sloped slab: both ends measured in the area frame, high at the wall and low at the posts.
- Every ornament once from close: nothing stands in front of it, it reads against what is behind it (a dark plate
  behind brass on glass).
- Structure shows on the player's side: a brace hidden under a roof does nothing.
- A big glowing volume is plain material with a thin Neon slice; big gold is Metal, Foil only for thin trims.
- A dark era has one warm wall colour; compare colours with the reference picture, not from memory.
- Nothing timber stands out of a roof slope; pipes run beside dormers, not through them.
- Count the mesh pieces a level (the preview prints it): a wrong count names the missing piece at once.
- Depth before decoration (the Kitchen's review): an arch with a real rise and proud, two-tone voussoirs; glass set
  0.9 behind its steel; a portal with a lining deeper than the wall; covers at least 0.3 thick with a valance or a
  roll. Cloth is SmoothPlastic, never Fabric. A plate behind an emblem is dark on glass, the era's cloth on marble.
- Shoot the flank the review camera hides once, and send it with the five: the reviewer asks for what stands there.

## 6. Do not

- No model, however small, before its reference picture. No whole building from Meshy or Tripo.
- No bigger footprint, taller tower or extra volume to chase a review score; the plot may grow only when the owner
  says so for the village's layout.
- No second ChatGPT round on a finished building, and no fix built from its answer without checking the code:
  nine of its 25 last points asked for what the Granary already had.
- No upload worked round: the test place refuses mesh uploads ("asset:read"); that is the owner's click.
- No text, numbers or signs on a building unasked; no baked highlights; nothing copied from another game.

## 7. Ledger

| Building | Module | Reference | Ladder | State |
|----------|--------|-----------|--------|-------|
| Pantry -> Granary | `Granary.luau` | `granary-ref-era*.jpg` | in the module's `build` (25 features + 4 store props an era; not yet walked against section 2's step test) | locked 2026-11-16; 7 Blender pieces wait for upload, 8 Meshy pieces for the owner |
| Kitchen (cookhouse to grand restaurant) | `Kitchen.luau` | `kitchen-ref-sheet.jpg`, `kitchen-ref-era*.jpg` | `kitchen-ladder.md` (walked on paper; seen at each era's last level, not pair by pair) | locked 2026-11-17 (ChatGPT: likeness 78-88, finish 74-83, before the last edit); 2 new Blender pieces and the owner's sheet pieces wait for his import |
| Garden, breeding pen, training ground, dock, village pieces | - | - | - | not started |
