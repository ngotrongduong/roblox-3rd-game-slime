---
name: slime-wear
description: Use when the owner sends a 3D file (GLB or FBX, from Meshy, Tripo or his image-to-3D) of horns, ears, wings, a tail, a crown or any other piece for a Secret slime of Goo Lineage V2 to wear; when he says a worn piece sits wrong (sunk into the body, floating, its base showing, the wrong angle, side, size or place); or before changing Config.Wear, client/SlimeWear or tools/blender/wear_kit.py.
---

# Slime wear: a Secret slime's own pieces

Each Secret slime may wear its own pieces, made from the owner's 3D file and set on the slime's jelly body so they ride
it as it squashes, hops and leans. One kit per Secret: `tools/blender/wear_kit.py` (a table in `KITS`) turns the file
into placed, low-poly pieces; `Config.Wear` names them; `client/SlimeWear` draws them. Replies to the owner are in
Vietnamese; everything in the game is English.

Read with: `kit-reference.md` (every kit field, the run's output, the Config mapping), `LESSONS.md` (what went wrong
and the fix; read it before the first run), the owner's painting of the Secret (the reference for every piece).

Who does what: an agent may do steps 1-6, 8 and 9 and report; Studio (steps 7 and 10) and the commit are the
orchestrator's (CLAUDE.md).

## The owner's rules for worn pieces

- **His painting decides.** Where a piece stands, its angle, its size and which side it is on come from
  `reference/goo-lineage-web/assets/slime.secret.<colours>.png`. His art is never recoloured or redrawn.
- **Sat on the skin, never sunk in** (2026-11-10): a horn or an ear stands as far out of the body as it can; only the
  rim of its foot goes under the skin, and where the shoulder slopes away the lowest part is drawn down onto it
  (`seat`). The detail at its foot (fur, a spiked collar, a band) must show.
- **No base showing** (2026-11-10): no rim, hollow or gap under a piece from any side.
- **Every pair of ears is worn as Sunshower Fox wears its own** (2026-11-10, after four rounds on the fox-file ears
  that each made them worse: "càng sửa càng hỏng, hãy nghiên cứu con này ... copy chính xác như vậy. cả về góc độ và vị
  trí đặt tai"): `horn` at (+-0.34, 0, 0.7), `tilt_out` 32, `tilt_back` 0, `level=False`, `foot="low"`, the default
  `band` and no `deep`; `scale` only brings the ear to Sunshower's height (about 0.28 in `WEAR`). Its foot then sits
  at height 0.71 on the top corner. Never sink ears deeper, lean them out further, drag their lower half down or give
  each its own angle to hide a gap: those were tried and he rejected them. An ear twitches by a swivel about the
  upright (it never tips its foot off the skin). Judge ears from 3x close-ups of every root in Play, including the two
  shots from low at the front (`-lowright`, `-lowleft`), and next to Sunshower Fox.
- **Claude places ears roughly, the owner fine-tunes them by hand** (2026-11-10, after placing four pairs himself: "lần
  sau cũng làm như vậy, bạn sắp xếp chung chung như vậy rồi để tôi tinh chỉnh lại là được"): put the ears on in one
  plain round (the Sunshower Fox standard above), check them in Play, then open the ear editor for him instead of more
  rounds of your own. Stop Play, sync, run `ear_editor.luau` (Edit; set its EDIT and REFERENCE lists), tell him in
  Vietnamese: click an ear, Move (Ctrl+2), Rotate (Ctrl+3), and turn Studio's snapping down first (Model tab, Rotate
  45 -> off or 1, Move -> off or 0.05; he met the 45-degree steps). Wait for his word, then `ear_read.luau` (Edit) to
  a JSON file, `python ear_write.py <json> src/shared/ConfigWear.luau`, check, sync, run `ear_editor.luau` and
  `ear_read.luau` again (it must return `[]`: the game draws exactly what he set), remove the stage
  (`workspace.EarEditor`), see it in Play. His `turn`, `at`, `size` and `anchor` are kept as they are: no rebuild, no
  mirroring, no "fixing" them afterwards. The editor takes any piece whose name holds "Ear"; widen `isEar` for other
  pieces he wants to place.
- **Vines grow out, not stuck on** (2026-11-10: "dây leo mọc vươn ra cả bên ngoài của slime"): what the painting draws
  round the outline stands out past the body (`frame`), only what lies on the back is laid on the skin (`wrap`).
- **A bird's wings spread from the back** (2026-11-10: "tư thế tự nhiên của cánh chim thay vì chổng lên trên cao", then
  "phải ở đằng sau lưng của slime, không phải ở bên cạnh", then "xoay ngang như đang xòe cánh chứ không phải tư thế
  cánh cụp lại", with his sketch): the roots near the spine at mid-back, the wings wide and level out to the sides,
  past the body by most of their length, the long feathers curling up at the outer ends, the rest fanning below
  (`aim`). Never folded, never at the sides, never raised high, never upside down.
- **Every bird's wing pair is worn the same way** (2026-11-10, approving Midnight Raven: "từ bây giờ, các cặp cánh dạng
  cánh chim lắp cho slime đều giữ đúng theo tư thế và vị trí này. chuyển động cánh cũng giống như nhau"): copy
  Midnight Raven's `aim` numbers (`kit-reference.md`, "A bird's wing pair") and its motion (`flap` 10 degrees, 0.6 Hz,
  about the `wear.json` axis); only `scale` changes, to bring the span to Raven's (tips at about +-1.0).
- **Tails and ears move** (2026-11-10: "gắn thêm chuyển động cho phần đuôi và tai"): a tail wags and trails the hop,
  an ear twitches now and then and trails the hop (`kit-reference.md`, "Config").
- **Tentacles grow from under the body and wriggle** (2026-11-10, Void Kraken: "gắn ở dưới thân của slime, nó sẽ có
  chuyển động co duỗi, ngọ nguậy như tay bạch tuộc"): rooted under the rim, out over the ground, rigged with bones so
  each arm bends along its length, curling and uncurling slowly while a wave runs to its tip, every arm on its own
  beat (`tentacle`, `kit-reference.md`, "Tentacles"). Then: "tất cả đều phải kết nối ở phần dưới của con slime", none
  sunk into the body to show only a stub at its side, and "phần màu tím phải quay xuống bên dưới hoặc ra ngoài chứ
  không lật mặt lên trên": all low, the suckers down or out.
- **Worn proud, never sunk** (2026-11-10, Frost Swan: "chúng là phụ kiện gắn nổi trên thân slime, không phải chìm vào
  trong thân"): a flat piece laid on the body keeps its whole relief outside the skin, only its back face touching it.
  A file may hold more than fits ("không cần dùng hết, chỉ dùng những cái phù hợp"): leave out a piece that would sit on
  the face or meet the ground, and say which in the report.
- **Not every wing shape is a bird's wing** (2026-11-10, Frost Swan: "trông giống như cánh nhưng không phải cánh chim,
  hãy gắn nó vào vị trí giống như trong hình ảnh tham chiếu"): a wing-shaped ornament the painting draws on the body's
  sides (crystal frills) goes where the painting draws it (`front`); the bird's wing standard is for real wings only.
- **Butterfly wings are worn on their straight edge, low on the back, and beat back** (2026-11-10, fairy, butterfly
  and moth wings: "không cần khớp với tranh, cứ đặt ở vị trí sau lưng", then "quá cao, cho xuống thấp tầm ngang thân
  dưới một chút, tăng kích thước cánh lên lớn hơn và đặt chuyển động kiểu cánh bướm vỗ từ trước ra sau chứ không phải
  từ trên xuống dưới", then "phần tiếp xúc với thân thể không phải là phần nhỏ nhọn ... mà là phần thẳng của cạnh cánh
  bướm"): `aim` with `edge=True`, the straight inner edge laid down the back either side of the spine from about
  0.35 up, the wing out to the side, about 0.93 tall; the beat turns it on that edge back toward its twin and open
  again (`flap` with `bias`, `kit-reference.md`). Paintings with huge wings do not override this.
- **Flowers and leaves keep their 3D shape** (2026-11-10, Forest Dryad and Peach Blossom: "các lưới của hoa và lá ...
  biến dạng ... hãy cố gắng giữ nguyên mesh để khối hình hoa lá đúng với nguyên dạng 3d nhất có thể, không cần phải
  kéo để nó ôm sát thân con slime"): a crown, a wreath of hair, a cluster, a festoon is worn `rigid` (turned, moved,
  scaled, never bent), touching the body and standing off its curve; `wrap`, `frame` and `front` bend the mesh and are
  only for flat plaques and vines that may bend. Keep nearly all their triangles: decimated hard, leaves break up.
- **Tusks stand out of the face** (2026-11-10, Iron Boar: "nanh răng của con lợn rừng nằm ở phía trước mặt, không phải
  ở 2 bên"): low on the front either side of the mouth, pointing forward, tips curling up.
- **Rigid pieces are pressed onto the body, some of them into the jelly** (2026-11-10, Amethyst Unicorn: "có thể đẩy
  sát cái mái tóc về phía con slime như vậy, sẽ chấp nhận một phần tóc bị chìm vào trong thân", with his sketch): a
  big rigid piece (a mane, an armour plate) lies as close as it can, its stray locks or edges let in (`tuck`), rather
  than touching at one point and standing off. Still never bent; a mane too wide may be flattened (`squash`).
- **A mane runs like a horse's** (2026-11-10, Amethyst Unicorn: "chạy dọc từ đỉnh đầu phía trước ra đằng sau lưng rồi
  tới dưới chân ... Không tạo hình giống như trong hình mẫu là tóc ở 2 bên mặt"): from just behind the horn over the
  head and down the back to the feet (`lay="side"`), never down the sides of the face.
- **Armour goes round the body, front too** (2026-11-10, Copper Beetle: "nhớ ghép cả giáp ở phần trước thân nữa"):
  the plates on the back and again on the front, either side of the face (a part may be worn twice); a plate that
  would cover the face stays on the back.
- Each Secret has its own design; one piece recoloured for another Secret is not a new design.
- Low poly for cheap phones: each part keeps the triangles in its kit's `budget` (about 500 to 900).

## The steps

1. **Know the Secret.** The owner names it by its two colours ("Navy+red"). The id is `secret-<a>-<b>` with the two
   colour names in alphabetical order (`Colours.pairKey`): `secret-navy-red`. His word may not be a palette name
   ("gold"): match it to the names in `src/shared/Colours.luau` and to a Secret in `src/shared/SecretRecipes.luau` (its
   name and painting); if two Secrets could fit, pick the one whose painting shows the pieces and say so in the report.
   Look at the painting whole (`reference/goo-lineage-web/assets/slime.secret.<a>-<b>.png`) and its top enlarged:
   `python "C:\Roblox 3rd game\.claude\skills\slime-wear\paint_top.py" navy-red <scratchpad>\paint_top.png`.
   Note each piece's place (shoulder edge, top, back), lean, how it turns, how big against the body. A piece the
   painting does not show is still worn (the file is what the owner wants): place it as the nearest existing kit does
   and name it in the report.
2. **Take the file in.** A scratch `.ps1` copies it from Downloads to `art/models/accessories/<folder>/<file>`: the
   folder is the Secret's name in snake case (`fire_ice_chimera`), the file name without spaces (`navy_red.glb`).
   `art/models` is the folder the owner approved for uploads: never copy a file elsewhere to get round an approval.
3. **Look into it:** `& "C:\Roblox 3rd game\tools\blender\wear_inspect.ps1" "<file>"` prints the loose bits with
   their middles (what `sort` reads) and renders six sides into `<folder>\review\inspect\`. Look at the renders: which
   bit is what, where each one's base is, which way a horn curls, which way an ear opens.
4. **Write the kit** in `KITS` of `tools/blender/wear_kit.py` (fields in `kit-reference.md`): `sort` by the middles
   from step 3, `budget`, and a piece for each part with its place from step 1. Start from the nearest existing kit.
   The tool knows `horn` (horns and ears), `wing` (spread), `aim` (a piece set by where it points: a bird's open
   wing), `tail`, `wrap` (a flat piece lying on the skin), `frame` (a flat piece growing out past the outline),
   `front` (a flat piece worn exactly where the painting draws it seen from the front, its relief standing proud),
   `rigid` (a flower crown, leafy hair, a cluster: kept exactly as the file shapes it, never bent) and
   `tentacle` (an arm under the body, rigged with bones); `twin` mirrors one piece into a pair, and a part torn through
   (a bat wing with holes) is mended by the kit's `mend`. A piece of another kind (a crown,
   a halo, four wings) first gets its kind in `wear_kit.py`, its row in `kit-reference.md` and, if its anchor cannot
   sit on the skin, a change to `tests/spec/wear.luau`; then step 6 is due.
5. **Build:** `& "C:\Roblox 3rd game\tools\blender\wear_kit.ps1" <Kit>`. Read the lines (`kit-reference.md`), then
   look at `review/head.png`, `headback.png`, `front.png`, `side.png`, `game.png` and `backq.png` next to the painting.
   List what differs (place, lean, size, foot showing, detail lost, a gap), change the table, build again. Several
   rounds are normal.
6. **If `wear_kit.py` itself changed:** rebuild every other kit, then `git -C "C:/Roblox 3rd game" status --short --
   art/models/accessories`. A kit whose `wear.json` is not listed did not move: its FBX differs only in its timestamp,
   restore it with `git checkout -- <fbx>`. A kit whose numbers moved without a reason is a regression: fix the tool.
   A kit that moved on purpose goes through steps 7 and 8 too.
7. **Upload** the FBX (and the texture, for a new kit): `kit-reference.md`, "Upload". Unchanged meshes keep their ids.
   The Studio id comes from the MCP's `list_roblox_studios`.
8. **Config.Wear** (in `src/shared/ConfigWear.luau`): the Secret in `Secrets`, the kit in `Kits` with the model id in
   its comment, each piece's numbers from `wear.json` and its motion (`kit-reference.md`, "Config").
9. **Check:** `& "C:\Roblox 3rd game\tools\check.ps1"` ends `CHECK OK` (`tests/spec/wear.luau` holds every piece on
   the skin and every pair mirrored).
10. **See it in Play:** stop Play (MCP `start_stop_play`),
    `& "C:\Roblox 3rd game\tools\map\sync_all.ps1" -StudioId <id>`, start Play, then one command:
    `& "C:\Roblox 3rd game\.claude\skills\slime-wear\shoot_close.ps1" <id> secret-<a>-<b> <scratchpad>\close`.
    It puts the character on the open lawn (`play_stage.luau`), lines every Secret that wears pieces up in front of it,
    alive (`play_check.luau`; each must say `n/n pieces`), brings the one named out onto open ground
    (`play_close.luau`) and shoots it from the front, back, side and three-quarter as the game sees it, and level as the
    painting does. Look at all five next to the painting: pieces on the skin, no gap, the detail at their foot showing,
    the place and size the painting gives. A piece that only moves keeps its mesh ids; change `at` and `anchor` alone.
    End by running `play_stage.luau` again so the owner's character stands in front of it, then send him the shots.
11. **Finish:** a paragraph in `docs/STATUS.md` under today's section at the top (a new `## <date> — ...` section if
    there is none); commit only your own files: the kit folder's `.glb`, `.fbx`, `.png` and `wear.json`, `wear_kit.py`,
    `ConfigWear.luau`, `docs/STATUS.md`, this skill if it changed (`git add` new ones first, then `commit --only`); tell the
    owner in Vietnamese what he will see and what was not seen (a phone).

## Keeping this skill current

This skill is the standard way to dress a Secret slime. When a run finds a better method, a new kind of piece, a tool
or a new rule from the owner, change this skill in the same commit as the work: the steps or `kit-reference.md` for
the method, `LESSONS.md` for what went wrong and its fix, "The owner's rules" for his words (with the date). Never leave
a method only in a scratch file or a chat.
