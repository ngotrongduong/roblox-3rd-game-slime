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

## 2026-11-10 (Forest Dryad, Iron Boar, Peach Blossom)

| What went wrong | The fix |
|---|---|
| Iron Boar's tusks, worn as horns with the file's turn (`level=False`), were lifted 0.34 up to the shoulders as horns, their foot stretched 0.2: their cuff opens sideways, which `base_plane` (40 degrees from down) cannot find. The owner: "là 2 cái nanh, không phải sừng" | `spread=90` finds the sideways sole |
| Then laid out flat from the lower sides, as the painting's side view seemed to show. The owner: "nằm ở phía trước mặt, không phải ở 2 bên" | low on the front either side of the mouth, leaning forward (`tilt_back` -70, `spin` turns the curl so the tips rise); a boar's tusks come out of its face |
| Flowers, leaves and a wreath of leafy hair worn `front` and `wrap` were bent onto the skin, their petals and leaves stretched; cut to 900 triangles the leaves broke into shards. The owner: "lưới của hoa và lá ... biến dạng ... giữ nguyên mesh" | kind `rigid`: only turned, moved and scaled, touching the body at its deepest point; keep nearly all the triangles (Hair 2200, Crown 1800) |
| Curved armour plates (shoulder guards) as `front` or `wrap` stood off the body like fins from the game's camera: their own curve is kept as relief | left out (the skin already paints the armour); a strongly curved piece is not a plaque |
| A leafy arch of hair or a flower crown drawn round the head in the painting: `front` at the painting's place matched it at the first build | `front`, `at` (0, 0.72-0.74), scale to the painting's width in body units |
| Antlers behind the `front` hair hid in Play from the front | a step of scale (1.1 -> 1.4) so they rise above it |

## 2026-11-10 (Amethyst Unicorn, Copper Beetle)

| What went wrong | The fix |
|---|---|
| The unicorn's mane, worn `rigid` facing out of the back, touched the body at one lock and hung off it like a ponytail; turned, stretched or sheared it still stood off, and a `fit` search counting vertices near the skin chose odd poses (sideways, high) | the file draws the mane from the side, front to back: `lay="side"`; then the owner's sketch: pressed in with 30 % of it in the jelly (`tuck` 0.3), scale 1.55, a little pitch (turn -10), moved in steeply (tilt 65), width flattened (`squash` y 0.55). Set a mane by hand from `review/side.png`, not by `fit` |
| `turn` on a side-laid piece: a positive turn swung the falling hair out backward like a tail | negative pitches its lower end in |
| The beetle's curved plates as set stood off like fins again | `rigid` with `tuck` 0.1 and `fit` over turn and tilt: each lay on the body (shoulders and side plates turned about 60 degrees) |
| The owner: "nhớ ghép cả giáp ở phần trước thân nữa" | the shoulder and side plates worn twice (front and back); at 50 degrees round the front shoulders touched the eyes, 68 clears them; the shield stays on the back |
| `tests/spec/wear.luau` allowed no side of 1 or more; a mane to the feet is 1.12 long | the limit is 1.25 |
| Config.luau neared Studio's 200000-character script limit with every kit | `Config.Wear` lives in `src/shared/ConfigWear.luau` |
| The unicorn's horn stood straight up on the top of the head as the painting has it. The owner: lower, on the forehead, the tip leaning out forward, and a little deeper in the body | `horn` at (0, -0.3, 0.76), `tilt_back` -40; then 0.04 further in along the horn in Config (`at` and `anchor` moved together) |

## 2026-11-10 (Rose Fairy, Dream Butterfly, Twilight Moth, Sun Phoenix, Royal Griffin: one file, five Secrets)

| What went wrong | The fix |
|---|---|
| The fairy, butterfly and moth wings were scaled up to their paintings' huge wings (root at mid back, tips past the top of the head); in Play they stood at the sides of the body. The owner: "không cần khớp với tranh, cứ đặt ở vị trí sau lưng như những cánh bướm khác" | the bee's `aim` numbers, scale to tips at about x +-0.73 (fairy 1.8, butterfly 1.65, moth 2.0); now an owner's rule in `SKILL.md` |
| The two feathered wings at the first scale reached x +-0.9 | scale up (phoenix 2.05, griffin 1.78) to Raven's +-1.0 |
| In the bee's pose they stood too high and small, beat up and down, and met the body at their narrow point. The owner: lower, level with the body, bigger, a butterfly's beat front to back, and "phần tiếp xúc với thân thể ... là phần thẳng của cạnh cánh bướm" | `aim` gained `edge` (the straight inner edge along `point`, the axis that edge) and `flap` gained `bias`; edges down the back from 0.35, 0.93 tall, beating 0 to 60 degrees back |
| The first edge pose (root y 0.48, height 0.3, edge leaning forward 0.35) sank the wings' lower halves into the body: from behind the body hid their inner edges | root at y 0.52 (on the skin), height 0.35, lean 0.25 |
| A file holding four Secrets' sets (fox tail file: 12 bits in one model 1 tall) gave ears 0.18 and tails 0.22 at the usual scales: the tool sizes by the whole file | ears scale 1.6 (about 0.31 wide, 0.33 tall), tails 2.6 (about 0.64): read the sizes in `WEAR` against the painting before looking at pictures |
| The four fox-file ears stood nearly upright (tilt_out 15-25) on the steep top corners: their outer foot hung over the slope and light showed under them. The owner: "chưa được dính sát vào thân slime. vẫn còn khoảng hở nhỏ", and the angles to fit | lean them out with the shoulder (wolf and cat 28, fox 34, tiger 38), a hair forward (`tilt_back` -6), the foot drawn down over half the ear (`band` 0.5) and pushed 0.025 in (`deep`); the run now prints how many of the lowest vertices are still outside the skin: aim for 0 or 1 |
| After that fix I called the roots tight from the whole-body shots; the owner still saw light under them: "vẫn còn khoảng hở từ gốc của cặp tai với thân ... vậy mà bạn cũng đồng ý được?" Two causes: only the lowest tenth was checked (the cup's back rim higher up stayed out), and the 18-20 degree flick back about X plus a 12 degree lag tipped the foot's rim about 0.05 off the skin in Play | `deep` 0.08, `band` 0.6, `scale` 1.75; the `HORN` count now covers the lowest fifth (aim for 0); the twitch is a swivel about Y and the lag 5 degrees; judge every root from 3x close-ups of the Play shots before saying it is joined |
| The owner then shot Ember Tiger and Creamsicle Fox from close and low: the foot of an ear still off the body. Each pair had one angle, mirrored, but the file's left and right ears are different meshes (Wolf 390 and 462 triangles): the same lean fits one better than the other. Tried and dropped: dragging the ear's lower half straight down onto the shoulder (`hug`): the outer wall stretched into a flap that hung lower still | `fit` on every ear: its own lean out, lean back and spin, searched for the most even foot rim on the skin (fox 33 and 39, wolf 40 and 34, tiger 30 and 30, cat 37 and 34); the review renders gained `headlow` and the Play shots `-lowright` / `-lowleft` |
| The owner: "càng sửa càng hỏng", and pointed at Sunshower Fox (blue-orange), whose ears he likes: copy its place and angles exactly. Each round had moved the fox-file ears further from it: bigger (1.75 against Sunshower's 0.28 tall), lower (foot at 0.63 against 0.71, from `deep` and lower `at`), leaning out more (34-40) and each ear on its own angle | the four kits take Sunshower's numbers (`at` +-0.34, 0, 0.7, `tilt_out` 32, `tilt_back` 0, default seat) and a scale for its height (1.5); `fit` and `hug` taken back out of the tool. When a piece of one kind already pleases the owner, copy its numbers before inventing new ones |
| `reference/goo-lineage-web/assets/slime.secret.orange-white.png` is the Yellow+White daisy slime, not the Creamsicle Fox (the owner, 2026-11-10) | for Orange+White go by the owner's picture (fox ears at the top corners, cream and orange swirls) and the game's own skin |
| The beat's direction: wear.json's axis goes through `rb`, a mirror, so a turn's sense could flip | checked in Play from the wing's RightVector over a second: WingR's swings 0 to +0.77 in z (back), WingL's 0 to -0.77, as meant |
