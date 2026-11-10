# Slime wear: lessons

What went wrong while dressing Secret slimes, and the fix now in the tools. Newest last; add to it after every kit that
taught something.

## What worked (keep doing it)

Fifteen Secrets dressed on 2026-11-10; these got a piece right in one or two rounds:

- **Read the painting in body units.** The painting's body and the game's share their shape: 1 tall, 0.527 wide each
  side at its widest. Measure a piece's middle, height and reach on the painting in pixels, divide by the body's height
  in pixels, and `at` and `scale` come out nearly right at the first build (Frost Swan's frills).
- **Ask what a winged part is before placing it:** a real wing (spread from the back: the bird's standard, a bat's
  `wing`) or an ornament the painting draws on the body (`front`). The renders cannot tell; the painting can.
- **One kit, many rounds of renders, one upload.** Build, look at `front`, `head`, `game`, `side`, `backq` next to the
  painting, change the table, build again; upload only when the renders match. A Play look then usually needs one
  more step of scale (the jelly sits wider than the render's body).
- **A piece that only moves keeps its mesh ids** (Roblox centres an uploaded mesh): change `at` and `anchor` in Config
  and skip the upload. A change of scale or of its foot's draw-down is new geometry: upload again.
- **Rebuild the other kits in the background** while uploading (step 6), then restore the FBX files that differ only in
  their timestamp; a `wear.json` that did not move proves the kit did not.
- **Close shots on open ground, five sides** (`shoot_close.ps1`): above as the game sees it, and level as the painting
  does. Judge horns beside wings and plaques the colour of the skin from the level shot too.
- **When the owner corrects, his words go into "The owner's rules" the same hour**, with the date, and the fix into
  the tool, so the next Secret starts right.

## 2026-11-10 (Tempest Dragon, Steam Dragon, Fire-Ice Chimera, Shadow Wolf)

| What went wrong | The fix |
|---|---|
| A horn's base found as its lowest 6 % of vertices caught one corner of a slanted cut; the horn sank by nothing and its base showed | `base_plane`: the plane, within 40 degrees of straight down, that touches the most vertices (a sole, or a hollow cup's lip) |
| Finding the base cap by flood fill took only part of it | the plane fit above |
| Scoring `base_plane` by face area instead of vertex count moved Steam Dragon's horns | kept the vertex count; rerun every kit after a change to `wear_kit.py` |
| `tilt_back` leaned the wrong way | positive leans back now; Tempest's numbers were changed to keep its look |
| The Chimera's horns, levelled, leaned 30-36 degrees and sideways: the file already had them upright | `level=False` keeps the file's turn |
| An ear's anchor was its single lowest vertex | `foot="low"`: the middle of its lowest tenth |
| Ears looked small and hidden in the game though fine in the renders | judge size in Play at the game's camera, not only in renders (scale 0.65 -> 0.85) |
| Horns and ears were sunk until their collar (an ear: its lowest 12 %) lay 0.03 inside: the wolf's lower fur, the Chimera's spiked collars and the dragons' horn bands were lost. The owner: "nằm sát phần ngoài của slime nhiều nhất có thể để giữ được các chi tiết gần gốc" | `seat`: moved along its axis until its foot touches the skin, only the foot's rim 0.02 under it; on a slope the lowest part is drawn down onto the skin |
| The two ears of a pair are different meshes, so their seated anchors differ by 0.0001 and the pair test failed | the test allows 0.005 for anchors of a pair |
| `upload_image` failed without its `imagePaths` | pass picture-server URLs |
| The owner's character stood in the shots | `play_check.luau` steps it aside |
| New files could not go into `git commit --only` | `git add` them first |

## 2026-11-10 (Midnight Raven, Jack-o'-Slime, Gothic Bat)

| What went wrong | The fix |
|---|---|
| A file holding both wings of a pair: the tool knew only one wing mirrored by `twin` | `root="-x"` for the file's right wing |
| Raven's feathered wings, raised and swept like a dragon's, stood up like an angel's. The owner: "giống với tư thế tự nhiên của cánh chim thay vì chổng lên trên cao" | (a fold along the sides, below, was wrong too) |
| Folded along the sides: "cặp cánh phải ở đằng sau lưng của slime, không phải ở bên cạnh"; folded on the back, tips down: "xoay ngang như đang xòe cánh chứ không phải tư thế cánh cụp lại", and he drew it over the back render | kind `aim` (replaces `fold`): roots at mid-back near the spine, the wings spread level and wide, tips drooping; his sketch is the check. A short Vietnamese word for a pose can mean several: when the owner sends a sketch, match it |
| The fold's angles (`droop`, `splay`, `roll`) took rounds of guessing | `aim` names where the long feather points and where the painted side looks; one round got close |
| The spread wings came out upside down ("vẫn bị lộn ngược"): the file's right wing was worn on the slime's left, and a turn cannot mirror it once its painted side faces back. The renders looked plausible, so it went to Play unnoticed | each side wears the file's wing of the same side; the `AIM` line prints `upright`, which must be positive. Compare the worn piece with the file's own front view (`review/inspect/front.png`): the same feathers up |
| The owner approved the Raven's pose and asked for it on every bird's wing pair, with the same motion | `kit-reference.md`, "A bird's wing pair": copy it, change only `scale` |
| Vines from a sticker sheet bent flat onto the skin looked like stickers (and at scale 0.8 like scattered bits). The owner: "dây leo mọc vươn ra cả bên ngoài của slime, hãy xem bản thiết kế gốc" | kind `frame` for what the painting draws round the outline (shoulders, sides): upright, out past the body, `hug` along the outline, `yaw` 30 so it shows from the side; `wrap` only for what lies on the back |
| A vine stood exactly in the front plane was a straight stick from the side | `yaw` |
| Vines judged in the renders looked small in Play, where the jelly is wider | scale them up a step after the first Play look |
| Gothic Bat's tail with `sink` buried the rose at its base | no `sink` on a tail whose base has detail; set `at` on the skin instead |
| Two different vines of one sheet at mirrored spots failed the pair test's `at` check | the test allows 0.07 for a pair's middles (anchors stay at 0.005) |
| Pieces with different motion fields broke the type check of `Config.Wear.Kits` | the table is cast to `{ [string]: WearKit }` |
| The stage for `play_check` stood by the well among village slimes | move the character to an open lawn first (a free 46-stud box) |

## 2026-11-10 (Void Kraken, Sunshower Fox, Cotton Candy Sheep)

| What went wrong | The fix |
|---|---|
| Tentacles that must bend along their length cannot be rigid pieces turned about one point | kind `tentacle`: an armature in the FBX, the mesh `HasSkinnedMesh`; the game makes `Bone`s by name under the MeshPart from `CreateMeshPartAsync` at the rest frames in `wear.json`, and the skin binds to them (checked in Studio: it bends) |
| The bones' frames from Blender came out mirrored in Roblox | the FBX turns a bone half round its Y: Roblox's bone X is minus Blender's; `wear_kit` writes `-X` |
| Weights by straight distance from the root bled across a curled arm's coils | distance measured over the surface (Dijkstra on the edges), weights blended between bone middles |
| The front pair straight at the camera (22.5 degrees) read as stubs | +-40 degrees, low (`rise` 4-8) and short |
| The skin test failed tentacles: their anchors are under the body, not on its skin | `tests/spec/wear.luau`: a piece with `bones` must sit under the rim (height 0-0.25) and carry a `wriggle` |
| The sheep's garland, seated as a horn, stood as an arch | `aim` with its file's top down: a crown round the head's top; its `upright` reads negative on purpose |
| Sheep ears stick out sideways: a twitch about X only spun them | twitch and lag about Z, the axes negated on the right |
| The owner kept only the sheep's horns and tuft ("chỉ cần để lại cặp sừng và chỏm lông trên đầu, còn lại có thể bỏ đi hết"): a file is what he offers, not all of it must be worn | the dropped parts stay in `sort` and `budget` with no piece (out of the FBX and the renders) and leave `Config.Wear`; the kept meshes keep their ids |
| Tentacles raised up the sides and back (`rise` up to 55) sank into the body's bulge and showed as stubs at its side; some turned their suckers up. The renders from the front looked fine, the owner's close look in Play did not | the tool now finds the suckers by colour and searches each arm's climb and roll (suckers down or out, nothing through the side above `PIERCE`, root on the ground); judge from `review/low.png`, the top, and close in Play from every side |

## 2026-11-10 (Cloud Pegasus, Honeybee Slime, Blood Moon Bat: one file, three Secrets)

| What went wrong | The fix |
|---|---|
| The owner's file held ONE white wing, ONE bee wing and ONE bat wing for three Secrets | three kits read the same file (`WING_TRIO` sort), each keeps its own wing (the others are parts no piece uses) and mirrors it with `twin` |
| A single wing aimed as the slime's left wing came out upside down (its root is at -X: the file's right wing) | it goes on the slime's RIGHT (`WingR`, `root="-x"`, `at` x < 0) with `twin="WingL"`; `upright` +0.99. The `aim` twin's flap axis is the mirror of a turn axis, (x, -y, -z): the same numbers as the Raven's own pair |
| The torn bat wing had no open edges: each tear is a tunnel through a closed, thin shell (Euler number -2), so "fill holes" tools see nothing | `mend`: the wing's outline seen from the front, rastered; empty ground it closes round is a hole; a thin patch a little wider than the hole lies just under the membrane's two faces |
| The patch's UVs taken from the membrane round the hole showed pale; one flat colour showed as a sticker; repainting the texture under the patch smeared 770 000 pixels, because the file's atlas cuts the membrane into many islands | each patch face gets a tile of its own in the texture (`TILE`, where the bat shows nothing; this kit's PNG serves the bat only): the membrane round the hole sampled through its faces, the hole blended in smoothly |
| Patches set 20 % of the thickness inside left a dark seam round each hole | 5 % (`inset=0.05`); the tile carries the membrane's own texture where patch and membrane overlap, so nothing fights |
| Bee wings came out solid cream in Roblox (the texture has no alpha) | a piece's `clear` (0.35) lets light through, on top of a ghost's fade (`client/SlimeWear`) |

## 2026-11-10 (Moonstone Gargoyle)

| What went wrong | The fix |
|---|---|
| Spread bat wings matching the painting best had their root at r 0.424 at height 0.72, off the skin (0.359): the skin test failed | slide the root down and in along the shoulder (0.67, r 0.403) and check the render again; a piece that only moves keeps its mesh ids (Roblox centres an uploaded mesh), only `at` and `anchor` change |
| Horns at the head's top corners, level with the wing roots (`at` y 0.02), looked right in the level front render but merged with the wing roots from the game's camera above: same colour, one behind the other | horns on the FRONT of the top corners (y -0.1), so the body is behind them; judge horns beside wings in Play from the front |
| The line-up row ran into a fence for the last Secrets (x 217): the close shots showed planks | move the one Secret onto open ground in front of the row: set its actor's `root` (the actor puts the model back on it) as well as `PivotTo` |

## 2026-11-10 (Frost Swan)

| What went wrong | The fix |
|---|---|
| Crystal frills shaped like wings were worn in the bird's wing pose; the owner: "trông giống như cánh nhưng không phải cánh chim, hãy gắn nó vào vị trí giống như trong hình ảnh tham chiếu" | a wing-shaped ornament the painting draws on the body is not a wing: kind `front`, where the painting draws it. Ask of each winged part: does the painting show it spread off the back (a wing) or lying on the body (an ornament)? |
| A `frame` lays each point inside the body onto the skin one by one: a flat plaque's front and back faces land on the same skin, its relief flattened, the "sunk" look the owner forbids | `front` lays the plaque's back face on the skin and keeps its thickness outside |
| The frills matched the painting in the renders but looked small in Play, where the jelly sits wider | measure the painting's middle and height in body units and add a step of scale after the first Play look (1.18 -> 1.25, `at` out 0.36 -> 0.39) |
| A plaque the same colours as the painted skin is hard to see where it lies flat on the front | judge it from a level camera too (the crystal reads at the outline and in its relief) |
