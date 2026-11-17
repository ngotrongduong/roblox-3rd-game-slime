---
name: landmark-build
description: Use when a village building of Goo Lineage V2 that upgrades through its 50 levels is built or rebuilt as a landmark (the Granary, the Kitchen, the Garden, the Breeding House and the Training Hall are done; dock and the village's own pieces follow), when the owner sends a note on a finished landmark, when its upgrade ladder is planned or judged, when a shape is too hard for Roblox parts and must go to Blender or the owner's Meshy, or before changing src/server/Architecture.luau or a landmark module such as Granary.luau.
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
   The owner's rule (2026-11-17, the Garden: "cho nó thêm cả các hình của những tòa nhà khác nữa"): the request
   always carries the village's concept paintings (`concept-era1-hamlet`, `era3-town`, `era5-capital`: the district
   is in them) AND the earlier landmarks' sheets, five pictures a message; one sheet alone as the style lock gave a
   garden lower and plainer than its village, and a second request.
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
   then the shot), read the console. When the owner's cloud place is already open (`list_roblox_studios` shows
   "Slime"), do step 11's upload of the new Blender pieces FIRST, so this one play test shows the real meshes;
   otherwise it shows the stand-ins (`mesh = 0`). Play follows the server's clock and is often night: the shots
   are taken in daylight through a client `BindToRenderStep` that writes the day's Lighting values (LESSONS, "The
   Garden"), unbound again before the owner gets Studio back. One camera for all five eras, set once.
   *Gate: no error, the look holds in the game's light.*
8. **ONE ChatGPT review, at the end** (the owner's requirement; my own way first): the five era shots, sent in the
   chat that drew the reference sheet, with scores per era and the 5-8 best fixes asked for. Once the meshes are
   uploaded, step 7's play-test shots ARE the review shots (daylight, the real floor and stations: the Training
   Hall); otherwise the Edit preview's (the pieces on; closer than the self-review shots, the building filling half
   the frame), with one paragraph saying what must not be judged (the preview's empty hall and lawn). Check
   every point against the code and the reference, then ONE last edit. No second round. When that edit changes
   colours or glass, shoot the five levels once more in Play (the camera and `_G.AreaShow` are already known:
   about ten calls) so the pictures the owner gets are the final state.
9. **Close.** `tools\check.ps1` (CHECK OK), `tools\types.ps1 src/server` (TYPES OK), the final shots in
   `docs/areas/village-v2/review/`, `docs/STATUS.md`, new lessons into `LESSONS.md` and INTO THIS SKILL in the same
   commit, commit only the job's own paths.
10. **The owner's part**, asked in the closing box and never waited for: his Meshy pieces (Smart topology), any
    ChatGPT sign-in, and opening his cloud place ("Slime") in Studio for the mesh upload.
11. **Upload and wear the real meshes** (once that place is open; done for the Granary and the Kitchen, 2026-11-17):
    `node tools/kit/upload_village_pieces.js <the cloud place's studio id>` uploads every new file under
    `art/models` and writes the ids into both configs. An uploaded file comes in half a turn round and
    `server/LibraryKit` turns it back: look at ONE piece with a front, alone, from both sides, first. Then
    `tools/map/real_kit_preview.luau` + the preview tool, one shot an era (ONE `screen_capture` a message), one
    play test, the checks. Never save the cloud place.
12. **The owner's notes after the lock** (he plays it and sends a picture with one line): do exactly what the note
    says, at every level it touches, the same turn. A piece he takes out leaves its ladder row empty: give that row
    its next-best step at once (the Garden's rose arch became two clipped bushes in pots, a piece of his own
    sheets) and say so; fix the ladder file, `hard-pieces.md` and STATUS in the same commit. Show it in the game:
    if Studio is in Play (he is in it), stop it, `sync_all.ps1`, start it, `_G.AreaShow` at the levels the note
    touches, one shot each, then give the camera back (`CameraType = Custom`, the RenderStep unbound) and leave
    Play running. Types and check before the commit, as always. No ChatGPT round for a note of his.

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
- Colour in the game's daylight (the Garden's review): lit Neon panes wash out to white, so window gold is deep
  (about 250, 200, 105); copper under Metal darkens to brown wood, so it starts bright (226, 132, 78); at the marble
  era every metal ornament is gold, copper beside marble reads rustic.
- Width before the play test (the Training Hall): measure the building against its yard as the sheet draws it; a
  hall half the yard wide read as a shed. Size by parameters (`hw`, `rise`) so a wider hall moves nothing else.
- Glass (the Training Hall): `Architecture.new`'s see-through at 0.4 vanishes in the game's daylight, 0.08 reads
  as coloured glass, in a colour darker than the sky; a glass front needs bars at least 0.25 thick to read as
  panes. Lit panes are a deep amber (238, 158, 60) so the window's bars still show.
- Masts, lamp standards and pipes never stand in front of a banner or an emblem; an ornament that does not suit a
  later era's material is swapped there (pipes on steel, hanging lanterns on marble), the ladder row written as built.
- A gate's roof never outweighs the house behind it (3 deep was enough); thatch gets a darker course half way up
  each slope or it reads as a lid; a vine canopy is a few light clumps with the rafters showing, not a hedge.
- The roof's big ornament (the Breeding House's egg): measure its width against its height on the sheet before
  modelling, it is drawn broader than one thinks; a wrong proportion is mended by a non-uniform scale, with no new
  upload. On a drum it sits sunk to its widest; on a low house it stands in a collar cone of the roof's own cover.
- A cone on a gabled roof is never wider than the hall is deep (its rim comes out through the gable), and the cone
  mesh is 1.19 times its nominal height: read a hidden tip's top from the preview.
- Nothing stands in front of the emblem (a flower box hid the heart); an emblem is wider than tall.
- Stand-in previews of the new Blender pieces settle size and place BEFORE the upload; then one upload.
- Pink and violet in the game's light: a warm light rose under Wood (a cool pink turns purple); lit spots a
  blue-violet Neon (violet glows magenta); marble a shade off white (242, 239, 232).
- The carry holds five pictures: say the hidden flank in one clause of the brief when a sixth does not fit.

## 5a. Size and roofs (the owner, 2026-11-17, after the Dock)

- **Size first, from above.** Before a module is written, stand the planned house beside the fishing pier (6 x
  24.7, the standard, never resized) and a 5-stud player in `tools/map/lineup_preview.luau` (all landmarks in one
  row, a `<Module> <level> <K> <splitZ> <pivotX> <pivotZ>` line each) and shoot it straight down (camera field of
  view 14 from 1800 up) and from the front. A house BODY, without silos, chimneys or towers, is at least 1.5 pier
  lengths wide (37) and one pier length deep (25); the lakeside house is the reference, the Granary is the central
  building and larger. The Dock was built 16 wide into its old cell and had to be redone: "tôi đã nói từ trước là
  phải tăng kích thước lên nhưng mà bạn vẫn cứ cố nhét nó vào không gian chật hẹp cũ".
- **The plot grows with the house**, never the house squeezed into the plot (`docs/VILLAGE_SCALE.md` §6 has the
  numbers and the K of every house).
- **One roof an era, the Granary's**, on every landmark: 1 thatch (232, 190, 84) Sand; 2 clay tiles (198, 70, 58);
  3 clay tiles (190, 62, 50); 4 roof shingles (62, 96, 160); 5 clay tiles (44, 84, 170). A dome or a vault that
  roofs a hall or a tower wears `L.roof` with no material of its own; glass is for windows, end fans and goo
  lanterns. A new roof colour must not equal another field's colour of that era (skins are keyed by colour).
- The lighthouse has ONE window.

## 6. Do not

- No model, however small, before its reference picture. No whole building from Meshy or Tripo.
- No bigger footprint, taller tower or extra volume to chase a review score; size comes from the owner's rule in
  section 5a, and the plot grows with it.
- No second ChatGPT round on a finished building, and no fix built from its answer without checking the code:
  nine of its 25 last points asked for what the Granary already had.
- No upload worked round: the test place refuses mesh uploads ("asset:read"); they go through the owner's cloud
  place, which he opens (step 11).
- No Meshy straw laid over a slab roof (the owner, 2026-11-17: "xấu lắm", it shows in patches): slab roofs keep the
  part-built thatch with rolls; a whole Meshy cap on a round tower or silo is fine.
- No ornament across a building's best face, and no big cartoon piece in front of a finished entrance (the owner
  took the Meshy rose arch out of the Garden, 2026-11-17: "trông nó không hợp với khu vườn này"; it also hid the
  arch stones and pilasters the reviewer then asked for). A sheet piece is worn only where it suits the building's
  own style; ornaments stand beside a door, never over it.
- No review point taken against a standing rule of his (a new floor an era against the stud look): drop it and
  name it in the report.
- No text, numbers or signs on a building unasked; no baked highlights; nothing copied from another game.

## 7. Ledger

| Building | Module | Reference | Ladder | State |
|----------|--------|-----------|--------|-------|
| Pantry -> Granary | `Granary.luau` | `granary-ref-era*.jpg` | in the module's `build` (25 features + 4 store props an era; not yet walked against section 2's step test) | locked 2026-11-16; every piece uploaded and worn 2026-11-17 |
| Kitchen (cookhouse to grand restaurant) | `Kitchen.luau` | `kitchen-ref-sheet.jpg`, `kitchen-ref-era*.jpg` | `kitchen-ladder.md` (walked on paper; seen at each era's last level, not pair by pair) | locked 2026-11-17 (ChatGPT: likeness 78-88, finish 74-83, before the last edit); every piece uploaded and worn 2026-11-17 |
| Garden (potting shed to royal palm house, with its windmill) | `Garden.luau` | `garden-ref-sheet.jpg`, `garden-ref-era*.jpg` | `garden-ladder.md` (walked on paper; seen at each era's last level, not pair by pair) | locked 2026-11-17 (ChatGPT: 78-84 an era, 81 overall, before the last edit; the last edit seen in the Edit preview only); B10 and B11 uploaded and worn; the rose arch taken out at the owner's word, step 19 is two bush pots (seen in Play at 30 and 50) |
| Breeding pen -> Breeding House (nest hall to royal hatchery, the spotted egg on its roof) | `BreedingHouse.luau` | `breeding-ref-sheet.jpg`, `breeding-ref-era*.jpg` | `breeding-ladder.md` (walked on paper; seen at each era's last level, not pair by pair) | locked 2026-11-17 (ChatGPT: likeness 83-87, finish 77-85 an era, before the last edit; the last edit seen in the Edit preview only); B12 and B13 uploaded and worn |
| Training ground -> Training Hall (drill shed to marble arena, the banner tower at its right end) | `TrainingHall.luau` | `training-ref-sheet.jpg`, `training-ref-era*.jpg` | `training-ladder.md` (walked on paper; seen at each era's last level, not pair by pair) | locked 2026-11-17 (ChatGPT: likeness 73-86, finish 72-80 an era, before the last edit; the last edit seen in Play at all five eras, the capital's flank in the Edit preview only); B14 uploaded and worn |
| Fishing pond -> Dock (fishing shack to marble boathouse, the lighthouse at its left end; the pond stays big: the owner's note) | `Boathouse.luau` | `dock-ref-sheet.jpg`, `dock-ref-era*.jpg` | `dock-ladder.md` (walked on paper) | built, reviewed once, checkpoint `4d99066` 2026-11-17, NOT locked: too small against the pier (section 5a); deeper hall and the era roofs in the code, the K 2.45 house only in the line-up; waits for the plots to grow |
| Village pieces and layout | - | - | - | not started |
