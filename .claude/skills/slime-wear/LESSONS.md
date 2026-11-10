# Slime wear: lessons

What went wrong while dressing Secret slimes, and the fix now in the tools. Newest last; add to it after every kit that
taught something.

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
