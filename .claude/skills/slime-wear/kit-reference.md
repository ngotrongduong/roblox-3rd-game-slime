# Slime wear: kit reference

## Axes

Blender (the kit table, the renders): the body is one unit tall, feet at z 0, it faces -Y, its own left is +X. Roblox
(`wear.json`, `Config.Wear`): mesh units, feet at y 0, front -Z, its own left -X; `(X, Y, Z) = (-x, z, y)`. The body's
radius every 0.05 of height is `PROFILE` (the same as `Shared/SlimeShape`): about 0.39 at the shoulders (z 0.69), 0.30
at z 0.76, the top at 1.0.

How the files have laid their parts out so far (check with `wear_inspect.ps1`): a wing's root at its +X end, spreading
toward -X with its painted side to -Y; a horn's or an ear's foot at the bottom, a horn's tip curling toward -X, an ear
opening toward -Y; a tail's base at one end along X.

## The kit table (`KITS` in `tools/blender/wear_kit.py`)

| Field | Meaning |
|---|---|
| `folder`, `glb` | `art/models/accessories/<folder>/<glb>` (wear_kit reads only the file's first mesh) |
| `out`, `texture` | the FBX name (`<out>.fbx`) and the texture PNG written next to it (1024) |
| `sort` | `lambda c:` the part a loose bit belongs to, by its middle `c` (the BIT middles from `wear_inspect.ps1`); for a sheet of many loose bits (vines, leaves) `nearest(Part=(x, z), ...)` sends each bit to the part whose mark (its middle in the file) is nearest |
| `budget` | triangles each part keeps |
| `mend` | parts torn through (a bat wing's membrane with holes): each hole is patched (below) |
| `pieces` | name -> one piece, exported in this order |
| `body` | the body colour in the review renders (RGBA, near the Secret's colours) |

Every name `sort` returns must be a part in `budget` (else a KeyError), and every part in `budget` must get at least
one bit (else an IndexError). A stray bit the kit does not want (or a piece the owner dropped) gets a part of its own
that no piece uses: it is left out of the FBX and the renders. A dropped piece also leaves `Config.Wear`; the meshes
that stay keep their ids, so nothing is uploaded again.

A piece, by `kind`:

| kind | Fields |
|---|---|
| `horn` (horns and ears) | `part`; `at` where its foot's middle starts (then it is seated along its own axis); `scale`; `tilt_out` degrees leaning out to its side; `tilt_back` degrees, positive leans back; `curl` `"back"`, `"out"`, `"in"` or none (turns a tip that curls toward -X in the file); `level` (default true: turn its flat sole level; false: keep the file's turn, for a horn the file already has upright); `foot` (`"plane"` default: the flat sole or a hollow cup's lip; `"low"`: the lowest tenth, for soft fur); `band` (default 0.3: how far up its length the draw-down onto the skin fades); `spread` (default 40: degrees from straight down the sole is looked for; 90 finds a sole facing sideways, a tusk's cuff open to the middle, Iron Boar: levelled, then `tilt_out` 80 lays it out flat to its side); `twin` the mirrored copy's name |
| `wing` (spread, a dragon's or a bat's) | `part`, `at` (the root), `scale`, `raise_` degrees tip up, `sweep` degrees back, `root` (`"+x"` default; `"-x"` for the file's right wing of a pair, spread to the slime's right), `twin` |
| `aim` (set by where it points: a bird's open wing) | `part`, `root` (which end along X is its root: `"+x"` for the file's left wing, whose root is its inner end), `at` the root just inside the skin, `scale`, `point` the direction from the root to its farthest point (the long feather's tip), `face` the way its painted side (-Y in the file) looks; both for the piece on the slime's left, mirrored for the right. With `face` to the back, each side wears the file's piece of the same side (seen from the file's front), or it comes out upside down. Its flap axis (in `wear.json`) beats the wing in its own plane, tip up for a positive turn. `twin` mirrors it to the other side (its flap axis mirrored too). A bird's wing pair: the standard below |
| `tail` | `part`, `base` `"+x"` or `"-x"` (its base end in the file), `at`, `scale`, `lift` degrees tip up (negative: down), `sink` true pushes its base end 0.03 into the body (not when its base has detail to show, a rose, a tuft) |
| `wrap` (lying ON the skin: a vine on the back, a leaf) | `part`, `at` = (degrees around the body from the front, + toward the slime's left; height of its middle), `scale`, `turn` degrees in its own plane, `flip` |
| `frame` (growing OUT past the body, as a painting draws vines round its outline) | `part`, `at` = (degrees around from the front; height of its middle; how far its middle stands from the middle line, about the skin radius there), `scale`, `yaw` degrees its plane turns to the back so it also shows from the side (30), `hug` 0-1 bends its inner edge along the outline (1 for a vine down the side, 0 for one rising off a shoulder), `turn`, `flip`; what falls inside the body is laid on the skin |
| `front` (worn where the painting draws it, as seen from the front: a wing-shaped frill up the body's sides) | `part`, `at` = (across, + toward the slime's left; up) of its middle as the painting draws it (body units: the painting's body is 1 tall and 0.527 wide each side at its widest, as the game's), `scale` (the painting's height of it over the file's), `bend` degrees the part past the outline turns back (15), `turn`, `flip`. Every point keeps its place across and up; what lies over the body is laid on its front with the back face on the skin and the whole relief outside; what reaches past the outline stands out in the middle plane. The file's left piece (seen from its front) is the slime's right (`at` across < 0). No motion |
| `tentacle` (an octopus arm growing from under the body, rigged so it bends) | `part` (drawn in the file's XZ plane, its thick root the lowest end, its suckers along one edge), `at` = (degrees around from the front, + toward the slime's left; how far out from the middle line, 0.24 is under the rim; height, 0.04), `scale` (1.4 at the front to 1.6 at the back), `bones` (default 5). How steeply it climbs and how its plane rolls are searched by the tool (below) |

At +-90 degrees a `frame` is seen from the front exactly as the file is (the painting's view): a piece from the file's
left half goes on the slime's right (`at` negative). Keep the face's zone clear (front, 35 degrees each way, heights
0.35-0.68): the body's own painted texture often already carries what the painting shows on the front.

### A bird's wing pair (the owner's standard, 2026-11-10)

Every feathered wing pair is Midnight Raven's, the pose the owner approved; change only `scale` until the `AIM` tips
stand at about x +-1.0 (Raven's file: 1.7):

```python
sort=lambda c: "WingL" if c.x < 0 else "WingR",   # the file's left wing (seen from its front) on the slime's left
WingL=dict(part="WingL", kind="aim", root="+x", at=(0.17, 0.45, 0.53), scale=1.7, point=(0.95, 0.2, 0.33),
	face=(0, 1, 0.2)),
WingR=dict(part="WingR", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=1.7, point=(0.95, 0.2, 0.33),
	face=(0, 1, 0.2)),
```

This assumes the file's wings stand as a pair seen from the front, roots at the inner bottom, tips up and out (as the
image-to-3D files do). Both `AIM` lines must say `upright` above +0.5; a negative one is upside down: swap the sort.
Config: `flap = { axis = <wear.json axis>, degrees = 10, hz = 0.6 }` on both.

A file with ONE wing (Cloud Pegasus): the wing whose root is at -X is the file's right wing, so it is the piece on the
slime's right, mirrored to the left:

```python
WingR=dict(part="Feather", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=0.8, point=(0.95, 0.2, 0.33),
	face=(0, 1, 0.2), twin="WingL"),
```

(a root at +X: `WingL`, `root="+x"`, `at` x 0.17, `twin="WingR"`). Other wings that are not a bird's take `aim` the same
way with their own `point`: Honeybee Slime's bee wings rise up and out from the upper back,
`at=(-0.24, 0.27, 0.7), scale=1.3, point=(0.65, 0.3, 0.7), face=(0, 1, 0.1)`.

### A torn piece (`mend`, Blood Moon Bat, 2026-11-10)

The owner's bat wing came with two holes torn through its membrane ("cánh dơi thì bị rách, nếu bạn sửa được thì dùng
nó"). A tear in a closed thin shell has no open edge (the bit's Euler number is below 2), so `mend` looks from the
front: it rasters the part's outline, and empty ground the outline closes round is a hole. Over each, a patch (the
hull of the hole widened by `margin`, 3.5 % of the part's size) lies `inset` (5 %) of the membrane's thickness under
its front and back. Each patch face wears a tile of its own in the texture (`TILE` pixels, put where the part shows
nothing): the membrane round the hole as the file paints it, the hole blended in smoothly. The run prints `MEND`; look
close at the wing in Play from behind (a seam or a pale fleck shows there first).

### Tentacles (Void Kraken, 2026-11-10)

The owner: an octopus slime's arms grow from under the body and curl, uncurl and wriggle like an octopus's; every arm
joins the body underneath, none sunk into it to show only a stub at its side, and the purple suckers face down or out,
never up. Eight arms round the foot at +-40, 80, 120, 160 degrees (none straight in front of the face), all low.
`wear_kit` finds each arm's suckers by the texture under its vertices (light pink-purple: red above `SUCKER_RED` and
above green by `SUCKER_PINK`), then tries every climb (-10 to 30 degrees) and roll of its plane (every 15 degrees) and
keeps the one whose suckers look most down and out, with few of them up, nothing inside the body above `PIERCE`, nothing
over the face, the arm past its root (`ROOT_PART`) not under the ground and reaching well out. It rigs each arm (a chain
of bones root to tip, each vertex weighted by its distance along the arm over the surface) and exports the bones in the
FBX; `wear.json` gives each bone's rest frame. Look at `review/low.png` (low at the front quarter) and the top.

A pair of horns or ears the file holds both of (two ears, a red horn and a blue one) is two pieces with mirrored `at`,
no `twin`; so is a pair of wings (`root` per wing). Another kind of piece needs the tool changed first (SKILL.md,
step 4).

## Reading a run

| Line | What to check |
|---|---|
| `PIECE <part> parts=n tris=n` | the loose bits joined per part; a wrong count means `sort` is wrong |
| `MEND <part> n holes, a square units, +t triangles, k tiles of TILE pixels painted` | the holes the eye sees in the part (a speck of a few cells is ignored); two tiles a hole |
| `KEPT <part> tris=n` | at or under its budget |
| `HORN <name> foot vertices=a of b, levelled by d degrees` | a foot of a few vertices on one corner missed the sole; 25-35 degrees on a horn that already stands upright: `level=False` |
| `SEAT <name> lifted x, foot gap up to g, n vertices drawn down, anchor (...)` | `lifted` how far it moved up its axis to sit on the skin; a gap above about 0.1 stretches the foot: lean it out (`tilt_out`) or move `at` along the shoulder; the anchor is where it rides the skin |
| `HORN <name> tip at height h` | the body's top is 1.0 |
| `SINK Tail x, base at (...)` | how far a tail with `sink` was pushed in |
| `FLAP CHECK tip z a -> b` | b above a, or the wing flaps down |
| `AIM <name> tip at (...), n of m vertices inside the body, upright u` | where the tip went (x out to the side, y back, z height); a few vertices inside is the root on the skin; more than about a sixth inside: move `at` out; `u` how far the file's up stays up: below 0 the piece is upside down (a turn cannot mirror: wear the file's piece of the other side) |
| `WRAP <name> at d degrees, height h, anchor (...)` | where it lies on the skin |
| `FRAME <name> at d degrees, height h, reach r, n of m vertices laid on the skin` | about half laid on the skin is a vine growing out of it; nearly none: it floats, lower `reach` |
| `FRONT <name> at (x, z), n of m vertices laid on the body's front, anchor (...)` | the rest stand out past the outline; none laid: it floats beside the body, bring `at` across in |
| `TENTACLE <name> at d degrees, rise r, roll q, root (...), reaches x from the feet, lifted l, a under the body, b through its side, suckers n of m looking (...), u of them up, k bones` | `suckers` 0: the texture test missed them (look at the colours); `looking` should point down (its last number negative) or out; `through its side` above about 15 % or `u` above 20 %: move `at` round or change `scale`; `lifted` above 0.05 lifts the root off the ground |
| `WEAR {...}` | what `wear.json` holds (a tentacle also its `bones`: per bone its point, X and Y axes, 9 numbers in Roblox space) |

Renders in `<folder>/review/` (not committed): `front back side top game backq low` whole, `head headback` close.

## Upload

1. Studio's MCP `open_cloud_invoke`, `POST /assets/v1/assets`, scopes `asset:read asset:write`, body
   `{"request":{"assetType":"Model","displayName":"<out>","description":"Goo Lineage V2: <what>","creationContext":{"creator":{"userId":"2366260872"}}}}`,
   files `[{"name":"fileContent","path":"<the FBX, absolute>"}]`. Several kits can go up at once.
2. Wait about 8 s (`execute_luau` `task.wait(8)`), then `GET /assets/v1/operations/<operationId>`: `response.assetId`.
3. `execute_luau` (Server in Play, or Edit): `InsertService:LoadAsset(<assetId>)`, print each MeshPart's `Name`,
   `MeshId` and `Size`; the Size must match `wear.json`.
4. A new texture: the project picture server (`python "C:/Roblox 3rd game/tools/chatgpt/serve.py"` in the background
   if 127.0.0.1:18923 does not answer), then `upload_image` with `imagePaths`
   `["http://127.0.0.1:18923/art/models/accessories/<folder>/<texture>.png"]`. A rebuild leaves the PNG unchanged
   (`git status`), so the kit keeps its texture id.
5. A 401: try once more. A refused file path: the owner approves the folder in Studio's MCP Permissions; never copy the
   file elsewhere.

## Config

`Config.Wear.Secrets["secret-<colours>"] = "<Kit>"`, and in `Config.Wear.Kits`:

```lua
-- the owner's <tool> model art/models/accessories/<folder>/<glb>, uploaded as model <assetId>
<Kit> = {
	texture = "rbxassetid://<texture id>",
	pieces = {
		{
			name = "WingL",
			mesh = <MeshId of WingL>,
			size = <wear.json size>,
			at = <wear.json centre>,
			anchor = <wear.json anchor>,
			-- (the owner: "đôi cánh hơi vỗ nhẹ", a soft slow beat)
			flap = { axis = <wear.json axis>, degrees = 12, hz = 0.8 },
		},
	},
},
```

`mesh` is the number in the MeshPart's `MeshId` (`rbxassetid://<number>`). The `Kits` table is cast
`:: { [string]: WearKit }` so pieces with different motion fields type-check (`tools\types.ps1`).

Motion (the owner, 2026-11-10: tails and ears move; `tests/spec/wear.luau` fails a Tail or an Ear without it):

| Piece | Fields |
|---|---|
| spread wing | `flap = { axis = <wear.json axis>, degrees = 12, hz = 0.8 }` (the owner's word on the dragons' wings: "đôi cánh hơi vỗ nhẹ") |
| bird's open wing (`aim`) | `flap = { axis = <wear.json axis>, degrees = 10, hz = 0.6 }`, a slow beat, the tip rising and falling |
| insect's wing (`aim`) | `flap = { axis = <wear.json axis>, degrees = 14, hz = 3 }`, a quick buzz, and `clear = 0.35` (lets light through: the texture has no alpha) |
| tail | a wag `flap = { axis = { 0, 1, 0 }, degrees = 8-14, hz = 0.5-0.9 }` (lazy dragon 8/0.5, brisk wolf 14/0.9) and `lag = { axis = { 1, 0, 0 }, degrees = 10-12 }` (drops as the slime climbs, lifts as it falls) |
| ear | `twitch = { axis = { 1, 0, 0 }, degrees = 16-18, every = 3-3.5 }` (a flick back now and then, each ear on its own clock) and `lag = { axis = { 1, 0, 0 }, degrees = 10-12 }` |
| ear out to the side (a sheep's) | EarL `twitch = { axis = { 0, 0, -1 }, degrees = 14, every = 3.5 }`, `lag = { axis = { 0, 0, 1 }, degrees = 12 }`; EarR the axes negated (a flick lifts it, a hop leaves it hanging) |
| tentacle | `bones = <wear.json bones>` and `wriggle = { axis = <wear.json axis>, degrees = 8, hz = 0.45-0.66, lag = 0.9, curl = 10, curlHz = 0.15 }`: a wave runs out to the tip (`lag` radians between bones) while it slowly curls and uncurls, more toward the tip; each arm a different `hz` so they never move as one |
| horn, vine, leaf, garland, cloud | none |

`Config.Wear.Twitch` (the flick's timing) and `Config.Wear.Lag` (the climb that gives a full bend, the spring's
half-life) hold the shared numbers. `client/SlimeWear` loads a kit's meshes once (`CreateMeshPartAsync`), sizes them by
the slime's scale, and each frame moves every piece with the skin at its `anchor` (`SlimeShape.deform`) and the
jelly's lean, then turns it by its flap, twitch and lag about the anchor. A piece with `bones` gets Roblox `Bone`s made
by the client under its MeshPart, named as in the FBX (`<piece>_0`, ...), at their rest frames (positions scaled with
the part): the skinned mesh binds to them by name, and `pose` turns each `Bone.Transform` for the wriggle.
