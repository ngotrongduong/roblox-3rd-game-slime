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
| `sort` | `lambda c:` the part a loose bit belongs to, by its middle `c` (the BIT middles from `wear_inspect.ps1`) |
| `budget` | triangles each part keeps |
| `pieces` | name -> one piece, exported in this order |
| `body` | the body colour in the review renders (RGBA, near the Secret's colours) |

Every name `sort` returns must be a part in `budget` (else a KeyError), and every part in `budget` must get at least
one bit (else an IndexError). A stray bit the kit does not want gets a part of its own that no piece uses: it is left
out of the FBX but still shows in the renders where the file has it.

A piece, by `kind`:

| kind | Fields |
|---|---|
| `horn` (horns and ears) | `part`; `at` where its foot's middle starts (then it is seated along its own axis); `scale`; `tilt_out` degrees leaning out to its side; `tilt_back` degrees, positive leans back; `curl` `"back"`, `"out"`, `"in"` or none (turns a tip that curls toward -X in the file); `level` (default true: turn its flat sole level; false: keep the file's turn, for a horn the file already has upright); `foot` (`"plane"` default: the flat sole or a hollow cup's lip; `"low"`: the lowest tenth, for soft fur); `band` (default 0.3: how far up its length the draw-down onto the skin fades); `twin` the mirrored copy's name |
| `wing` | `part`, `at` (the root), `scale`, `raise_` degrees tip up, `sweep` degrees back, `twin` |
| `tail` | `part`, `base` `"+x"` or `"-x"` (its base end in the file), `at`, `scale`, `lift` degrees tip up (negative: down), `sink` true pushes its base end 0.03 into the body |

A pair of horns or ears the file holds both of (two ears, a red horn and a blue one) is two pieces with mirrored `at`,
no `twin`. A wing is always one wing whose root is its +X end, mirrored by `twin`: a file holding both wings, or
another kind of piece, needs the tool changed first (SKILL.md, step 4).

## Reading a run

| Line | What to check |
|---|---|
| `PIECE <part> parts=n tris=n` | the loose bits joined per part; a wrong count means `sort` is wrong |
| `KEPT <part> tris=n` | at or under its budget |
| `HORN <name> foot vertices=a of b, levelled by d degrees` | a foot of a few vertices on one corner missed the sole; 25-35 degrees on a horn that already stands upright: `level=False` |
| `SEAT <name> lifted x, foot gap up to g, n vertices drawn down, anchor (...)` | `lifted` how far it moved up its axis to sit on the skin; a gap above about 0.1 stretches the foot: lean it out (`tilt_out`) or move `at` along the shoulder; the anchor is where it rides the skin |
| `HORN <name> tip at height h` | the body's top is 1.0 |
| `SINK Tail x, base at (...)` | how far a tail with `sink` was pushed in |
| `FLAP CHECK tip z a -> b` | b above a, or the wing flaps down |
| `WEAR {...}` | what `wear.json` holds |

Renders in `<folder>/review/` (not committed): `front back side top game backq` whole, `head headback` close.

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

`mesh` is the number in the MeshPart's `MeshId` (`rbxassetid://<number>`). Only wings take `flap`; 12 degrees at 0.8 Hz
is the owner's word on the dragons' wings, the start for any other wing, shown to him before it stays. `client/SlimeWear` loads a kit's meshes once (`CreateMeshPartAsync`), sizes them by the
slime's scale, and each frame moves every piece with the skin at its `anchor` (`SlimeShape.deform`) and the jelly's
lean.
