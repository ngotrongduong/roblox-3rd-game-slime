# A Secret slime's worn pieces (Config.Wear) from the owner's model (Meshy, Tripo) of its horns, ears, wings and tail.
# Splits the file into its parts, lowers the triangles for phones, sets each piece on a slime body one unit tall (the
# game's mesh units), mirrors a piece into its twin where the file holds one of a pair, renders it from six sides into
# <folder>/review/, and exports:
#   <out>.fbx       the pieces (HornL HornR WingL WingR Tail, EarL EarR ...), placed around the body (feet at the origin)
#   <texture>.png   the texture at 1024
#   wear.json       each piece's centre, size and anchor (and a wing's flap axis) in Roblox mesh space: Config.Wear
# Blender axes are the slime body's own (tools/blender/slime_body.py): Z up, the slime faces -Y, its own left is +X.
# Exported like the body (FBX, forward -Z, up Y), so Roblox reads (X, Y, Z) = (-x, z, y).
# How the files lay their parts out so far: a wing's root at its +X end, spreading toward -X with its painted side to
# -Y; a horn's or an ear's base at the bottom (a horn's tip curling toward -X, an ear facing -Y); a tail's base at one
# end along X (`base`).
# Run: tools/blender/wear_kit.ps1 <kit>. The whole job, the kit fields and the lessons: skill slime-wear
# (.claude/skills/slime-wear), kept current with this file.
import bpy, bmesh, heapq, json, math, os, sys
from mathutils import Matrix, Vector

ART = r"C:\Roblox 3rd game\art\models\accessories"

def nearest(**marks):
	# a `sort` for a file of many loose bits: each goes to the part whose mark (x, z of its middle in the file, from
	# wear_inspect.ps1) is nearest
	return lambda c: min(marks, key=lambda k: (marks[k][0] - c.x) ** 2 + (marks[k][1] - c.z) ** 2)


# `sort` says which part of the file a loose bit belongs to, by its middle; `budget` the triangles a part keeps;
# `pieces` what is made of each part, in the order they are exported: kind (horn: horns and ears, wing, tail), where it
# sits on the body (Blender axes, body height 1; +X is the slime's own left), size factor, turns in degrees, and `twin`,
# the mirrored piece on the other side
KITS = {
	# Tempest Dragon (secret-black-blue), 2026-11-10
	"TempestDragon": dict(
		folder="tempest_dragon",
		glb="neon_dragon_relics.glb",
		out="TempestDragonWear",
		texture="tempest_dragon_wear.png",
		sort=lambda c: "Tail" if c.x < -0.185 else ("Horn" if c.x > 0.25 else "Wing"),
		budget=dict(Horn=520, Wing=760, Tail=640),
		pieces=dict(
			HornL=dict(part="Horn", kind="horn", at=(0.223, 0.002, 0.764), scale=0.92, tilt_out=16, tilt_back=18,
				curl="back", twin="HornR"),
			WingL=dict(part="Wing", kind="wing", at=(0.3, 0.34, 0.47), scale=1.5, raise_=24, sweep=38, twin="WingR"),
			Tail=dict(part="Tail", kind="tail", base="+x", at=(0.0, 0.44, 0.16), scale=1.25, lift=-12),
		),
		body=(0.05, 0.12, 0.45, 1),
	),
	# Steam Dragon (secret-blue-red), 2026-11-10
	"SteamDragon": dict(
		folder="steam_dragon",
		glb="patriotic_dragon_cost.glb",
		out="SteamDragonWear",
		texture="steam_dragon_wear.png",
		sort=lambda c: "Tail" if c.z < -0.02 else ("Horn" if c.x > 0.2 else "Wing"),
		budget=dict(Horn=900, Wing=900, Tail=900),
		pieces=dict(
			# (the owner's painting: the horns stand at the shoulders, their tips curling out to the sides)
			HornL=dict(part="Horn", kind="horn", at=(0.27, 0.04, 0.74), scale=0.8, tilt_out=14, tilt_back=0, curl="out",
				twin="HornR"),
			WingL=dict(part="Wing", kind="wing", at=(0.3, 0.34, 0.47), scale=1.1, raise_=24, sweep=38, twin="WingR"),
			Tail=dict(part="Tail", kind="tail", base="+x", at=(0.0, 0.45, 0.21), scale=0.62, lift=-14),
		),
		body=(0.55, 0.12, 0.1, 1),
	),
	# Fire-Ice Chimera (secret-navy-red), 2026-11-10: a red horn on the red side (its right), a blue one on the left, a
	# tail red at the base and blue at the arrow tip
	"FireIceChimera": dict(
		folder="fire_ice_chimera",
		glb="navy_red.glb",
		out="FireIceChimeraWear",
		texture="fire_ice_chimera_wear.png",
		sort=lambda c: "Tail" if c.z < 0 else ("HornR" if c.x < 0 else "HornL"),
		budget=dict(HornL=600, HornR=600, Tail=800),
		pieces=dict(
			# (the owner's painting: both stand at the shoulders, bulging out, their tips turning in; the file has them so
			# already, upright, so they keep its turn)
			HornL=dict(part="HornL", kind="horn", at=(0.26, 0.04, 0.74), scale=0.8, tilt_out=8, tilt_back=0, level=False),
			HornR=dict(part="HornR", kind="horn", at=(-0.26, 0.04, 0.74), scale=0.8, tilt_out=8, tilt_back=0, level=False),
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=0.55, lift=10, sink=True),
		),
		body=(0.45, 0.1, 0.25, 1),
	),
	# Shadow Wolf (secret-black-gray), 2026-11-10: two wolf ears and a bushy tail (Tripo, already a pair of ears)
	"ShadowWolf": dict(
		folder="shadow_wolf",
		glb="black_gray.glb",
		out="ShadowWolfWear",
		texture="shadow_wolf_wear.png",
		sort=lambda c: "Tail" if c.z < 0.5 else ("EarL" if c.x > 0 else "EarR"),
		budget=dict(EarL=700, EarR=700, Tail=900),
		pieces=dict(
			# (the owner's painting: upright at the shoulders, leaning out a little, open to the front, the fur at their
			# foot hanging down the shoulder)
			EarL=dict(part="EarL", kind="horn", at=(0.35, 0.0, 0.66), scale=0.85, tilt_out=8, tilt_back=0, level=False,
				foot="low"),
			EarR=dict(part="EarR", kind="horn", at=(-0.35, 0.0, 0.66), scale=0.85, tilt_out=8, tilt_back=0, level=False,
				foot="low"),
			Tail=dict(part="Tail", kind="tail", base="+x", at=(0.0, 0.45, 0.2), scale=0.55, lift=10, sink=True),
		),
		body=(0.1, 0.1, 0.12, 1),
	),
	# Void Kraken (secret-black-purple), 2026-11-10: eight cosmic tentacles with glowing suckers. The owner: they grow
	# from under the body and curl and wriggle like an octopus's arms. Around the foot, none straight in front. Raised
	# up the sides and back (the first try), several sank into the body and showed as stubs at its side, and some turned
	# their suckers up: every arm now joins under the body and goes out low, its suckers down or out (searched by the
	# tool)
	"VoidKraken": dict(
		folder="void_kraken",
		glb="black_purple.glb",
		out="VoidKrakenWear",
		texture="void_kraken_wear.png",
		sort=nearest(Arm1=(-0.374, 0.677), Arm2=(-0.124, 0.651), Arm3=(0.15, 0.67), Arm4=(0.379, 0.604),
			Arm5=(-0.357, 0.2), Arm6=(-0.129, 0.218), Arm7=(0.121, 0.12), Arm8=(0.378, 0.216)),
		budget=dict(Arm1=450, Arm2=450, Arm3=450, Arm4=450, Arm5=450, Arm6=450, Arm7=450, Arm8=450),
		pieces=dict(
			# (the front pair at 40 degrees, not 22.5: straight at the camera they read as stubs)
			Arm4=dict(part="Arm4", kind="tentacle", at=(40, 0.24, 0.04), scale=1.4),
			Arm5=dict(part="Arm5", kind="tentacle", at=(80, 0.24, 0.04), scale=1.5),
			Arm1=dict(part="Arm1", kind="tentacle", at=(120, 0.24, 0.04), scale=1.5),
			Arm2=dict(part="Arm2", kind="tentacle", at=(160, 0.24, 0.04), scale=1.6),
			Arm3=dict(part="Arm3", kind="tentacle", at=(-160, 0.24, 0.04), scale=1.6),
			Arm6=dict(part="Arm6", kind="tentacle", at=(-120, 0.24, 0.04), scale=1.5),
			Arm8=dict(part="Arm8", kind="tentacle", at=(-80, 0.24, 0.04), scale=1.5),
			Arm7=dict(part="Arm7", kind="tentacle", at=(-40, 0.24, 0.04), scale=1.4),
		),
		body=(0.12, 0.05, 0.3, 1),
	),
	# Midnight Raven (secret-black-navy), 2026-11-10: a pair of starry feathered wings, both in the file. The owner: the
	# painting's wings are not right, set them where they sit well on its back; raised, they stood up too high; folded,
	# at the sides or on the back, they were not what he wants: so they grow from the upper back and spread out
	# sideways, level, as a bird's open wings ("xoay ngang như đang xòe cánh"); the file's right wing on the slime's left
	# came out upside down ("vẫn bị lộn ngược"): seen from behind, each side wears the file's wing of the same side
	"MidnightRaven": dict(
		folder="midnight_raven",
		glb="black_navy.glb",
		out="MidnightRavenWear",
		texture="midnight_raven_wear.png",
		sort=lambda c: "WingL" if c.x < 0 else "WingR",
		budget=dict(WingL=900, WingR=900),
		pieces=dict(
			# (his sketch over the back view: the roots near the spine at mid-back, the wings wide, past the body by most
			# of their length, the long feathers' tips rising and curling up at the outer end, the rest fanning below)
			WingL=dict(part="WingL", kind="aim", root="+x", at=(0.17, 0.45, 0.53), scale=1.7, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
			WingR=dict(part="WingR", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=1.7, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
		),
		body=(0.05, 0.06, 0.2, 1),
	),
	# Gothic Bat (secret-black-pink), 2026-11-10: bat ears, bat wings with rose vines, a thorny tail with a rose at its
	# base and a pink tip
	"GothicBat": dict(
		folder="gothic_bat",
		glb="black_pink.glb",
		out="GothicBatWear",
		texture="gothic_bat_wear.png",
		sort=lambda c: "Tail" if c.z < 0.27 else (("EarL" if c.x > 0 else "EarR") if c.z > 0.59 else ("WingR" if c.x > 0 else "WingL")),
		budget=dict(EarL=500, EarR=500, WingL=700, WingR=700, Tail=900),
		pieces=dict(
			# (the owner's painting: big ears upright at the shoulders, leaning out, open to the front; the wings spread
			# out to the sides behind the shoulders)
			EarL=dict(part="EarL", kind="horn", at=(0.33, 0.0, 0.7), scale=1.5, tilt_out=12, tilt_back=0, level=False,
				foot="low"),
			EarR=dict(part="EarR", kind="horn", at=(-0.33, 0.0, 0.7), scale=1.5, tilt_out=12, tilt_back=0, level=False,
				foot="low"),
			WingL=dict(part="WingL", kind="wing", at=(0.32, 0.3, 0.5), scale=1.6, raise_=12, sweep=16),
			WingR=dict(part="WingR", kind="wing", root="-x", at=(-0.32, 0.3, 0.5), scale=1.6, raise_=12, sweep=16),
			# (the owner: the rose end grows from the body and shows, the pink tip is the end)
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.485, 0.2), scale=0.85, lift=5),
		),
		body=(0.6, 0.1, 0.3, 1),
	),
	# Jack-o'-Slime (secret-black-orange), 2026-11-10: a sheet of curling vines and leaves, laid around the pumpkin body
	# as the owner's painting has them: a leafy vine on each shoulder, a vine down each side, vines along the foot in
	# front; the big curly vine on the back (the face takes the front)
	"JackOSlime": dict(
		folder="jack_o_slime",
		glb="black_orange.glb",
		out="JackOSlimeWear",
		texture="jack_o_slime_wear.png",
		sort=nearest(
			VineTopR=(-0.336, 0.845),
			VineFootR=(-0.265, 0.082),
			VineBack=(-0.234, 0.478),
			LeafA=(-0.126, 0.246),
			LeafB=(-0.015, 0.481),
			LeafTop=(0.001, 0.917),
			LeafC=(0.019, 0.289),
			VineSideR=(0.187, 0.451),
			VineFootL=(0.282, 0.068),
			VineTopL=(0.304, 0.874),
			VineSideL=(0.373, 0.441),
		),
		budget=dict(VineTopR=260, VineFootR=260, VineBack=500, LeafA=60, LeafB=40, LeafTop=60, LeafC=40, VineSideR=280,
			VineFootL=300, VineTopL=280, VineSideL=280),
		pieces=dict(
			# (the owner: the vines grow out past the body, as his painting draws them round its outline) a leafy vine
			# rising off each shoulder, a curling vine down each side; `at` for a frame: (degrees around the body from the
			# front, + toward the slime's left; height; distance out from the middle line)
			VineTopL=dict(part="VineTopL", kind="frame", at=(90, 0.8, 0.44), scale=1.45, yaw=30),
			VineTopR=dict(part="VineTopR", kind="frame", at=(-90, 0.8, 0.44), scale=1.45, yaw=30),
			VineSideL=dict(part="VineSideL", kind="frame", at=(90, 0.34, 0.56), scale=1.3, hug=1, yaw=30),
			VineSideR=dict(part="VineSideR", kind="frame", at=(-90, 0.34, 0.56), scale=1.3, hug=1, yaw=30),
			# `at` for a wrap: (degrees around the body from the front, + toward the slime's left; height)
			VineFootL=dict(part="VineFootL", kind="wrap", at=(42, 0.12), scale=1.3),
			VineFootR=dict(part="VineFootR", kind="wrap", at=(-42, 0.12), scale=1.3),
			VineBack=dict(part="VineBack", kind="wrap", at=(180, 0.42), scale=1.3),
			LeafTop=dict(part="LeafTop", kind="wrap", at=(150, 0.68), scale=1.5),
			LeafA=dict(part="LeafA", kind="wrap", at=(-125, 0.2), scale=1.5),
			LeafB=dict(part="LeafB", kind="wrap", at=(125, 0.22), scale=1.5),
			LeafC=dict(part="LeafC", kind="wrap", at=(-150, 0.66), scale=1.5),
		),
		body=(0.8, 0.3, 0.05, 1),
	),
	# Cotton Candy Sheep (secret-blue-pink), 2026-11-10: two spiral ram horns on the shoulders and a tuft of
	# cotton-candy puffs across the top. The file also holds two sheep ears, puff clouds for the sides and a cloud for
	# the foot: the owner kept only the horns and the tuft ("chỉ cần để lại cặp sừng và chỏm lông trên đầu"), so the
	# rest are parts no piece uses
	"CottonCandySheep": dict(
		folder="cotton_candy_sheep",
		glb="blue_pink.glb",
		out="CottonCandySheepWear",
		texture="cotton_candy_sheep_wear.png",
		sort=lambda c: (("HornL" if c.x > 0 else "HornR") if c.z > 0.5 else
			(("EarL" if c.x > 0 else "EarR") if abs(c.x) > 0.25 else "Garland") if c.z > 0.2 else
			("CloudFront" if abs(c.x) < 0.2 else ("CloudL" if c.x > 0 else "CloudR"))),
		budget=dict(HornL=500, HornR=500, EarL=400, EarR=400, Garland=400, CloudL=220, CloudR=220, CloudFront=380),
		pieces=dict(
			HornL=dict(part="HornL", kind="horn", at=(0.27, 0.0, 0.72), scale=0.55, tilt_out=10, tilt_back=0, level=False),
			HornR=dict(part="HornR", kind="horn", at=(-0.27, 0.0, 0.72), scale=0.55, tilt_out=10, tilt_back=0, level=False),
			Garland=dict(part="Garland", kind="aim", root="+x", at=(-0.23, -0.05, 0.8), scale=1.1, point=(-1, 0, 0),
				face=(0, -1, 0.3)),
		),
		body=(0.45, 0.6, 0.95, 1),
	),
	# Sunshower Fox (secret-blue-orange), 2026-11-10: two small pointed fox ears at the top corners, leaning out, and a
	# bushy tail (blue-white at the base, an orange curling tip)
	"SunshowerFox": dict(
		folder="sunshower_fox",
		glb="blue_orange.glb",
		out="SunshowerFoxWear",
		texture="sunshower_fox_wear.png",
		sort=lambda c: "Tail" if c.z < 0.45 else ("EarL" if c.x > 0 else "EarR"),
		budget=dict(EarL=620, EarR=620, Tail=900),
		pieces=dict(
			EarL=dict(part="EarL", kind="horn", at=(0.34, 0.0, 0.7), scale=0.75, tilt_out=32, tilt_back=0, level=False,
				foot="low"),
			EarR=dict(part="EarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=0.75, tilt_out=32, tilt_back=0, level=False,
				foot="low"),
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=0.95, lift=0, sink=True),
		),
		body=(0.3, 0.55, 0.9, 1),
	),
}
TEXTURE = 1024

# the body's radius every 0.05 of its height (Shared/SlimeShape PROFILE)
PROFILE = [0.1164, 0.3466, 0.4251, 0.4704, 0.4995, 0.5171, 0.5258, 0.5269, 0.5221, 0.5131, 0.4997, 0.4811, 0.4568,
	0.4248, 0.3822, 0.3253, 0.2417, 0.1508, 0.0997, 0.0671, 0.0]

KIT = KITS[sys.argv[sys.argv.index("--") + 1]]
ROOT = os.path.join(ART, KIT["folder"])
REVIEW = os.path.join(ROOT, "review")
os.makedirs(REVIEW, exist_ok=True)


def rad(d):
	return math.radians(d)


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT, KIT["glb"]))
src = [o for o in bpy.data.objects if o.type == "MESH"][0]
for o in bpy.data.objects:
	if o is not src and o.type != "MESH":
		bpy.data.objects.remove(o)
bpy.context.view_layer.objects.active = src
src.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# weld the seams, split into loose bits, and sort them into the file's parts
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
groups = {key: [] for key in KIT["budget"]}
for o in [o for o in bpy.data.objects if o.type == "MESH"]:
	c = sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
	groups[KIT["sort"](c)].append(o)
parts = {}
for key, objs in groups.items():
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	if len(objs) > 1:
		bpy.ops.object.join()
	ob = bpy.context.view_layer.objects.active
	ob.name = key
	ob.data.calc_loop_triangles()
	print(f"PIECE {key} parts={len(objs)} tris={len(ob.data.loop_triangles)}")
	parts[key] = ob


def anchor_of(ob, axis, high):
	# the middle of the 6 % of vertices at one end along an axis (where the piece meets the body)
	vs = [v.co.copy() for v in ob.data.vertices]
	vals = sorted(getattr(v, axis) for v in vs)
	lo, hi = vals[0], vals[-1]
	cut = hi - (hi - lo) * 0.06 if high else lo + (hi - lo) * 0.06
	end = [v for v in vs if (getattr(v, axis) >= cut if high else getattr(v, axis) <= cut)]
	return sum(end, Vector()) / len(end)


def decimate(ob, target):
	ob.data.calc_loop_triangles()
	n = len(ob.data.loop_triangles)
	if n > target:
		mod = ob.modifiers.new("Decimate", "DECIMATE")
		mod.ratio = target / n
		mod.use_collapse_triangulate = True
		bpy.context.view_layer.objects.active = ob
		bpy.ops.object.modifier_apply(modifier=mod.name)
	ob.data.calc_loop_triangles()
	return len(ob.data.loop_triangles)


def rebase(ob, anchor):
	# move the geometry so the anchor is at the object's origin
	ob.data.transform(Matrix.Translation(-anchor))
	ob.location = (0, 0, 0)


for key, ob in parts.items():
	print(f"KEPT {key} tris={decimate(ob, KIT['budget'][key])}")


def skin_radius(z):
	# the body's radius at a height (0 above its tip)
	if z <= 0:
		return PROFILE[0]
	if z >= 1:
		return 0.0
	f = z / 0.05
	i = min(int(f), len(PROFILE) - 2)
	return PROFILE[i] + (PROFILE[i + 1] - PROFILE[i]) * (f - i)


def outside(p):
	# how far a point stands out of the body, across (negative: inside)
	return math.sqrt(p.x * p.x + p.y * p.y) - skin_radius(p.z)


# the owner, 2026-11-10, twice: a horn's or an ear's foot must not show ("vị trí gốc của 2 cặp sừng còn bị lộ"), yet it
# stands as far out of the body as it can, keeping the detail near its foot ("nằm sát phần ngoài của slime nhiều nhất có
# thể để giữ được các chi tiết gần gốc"): only its foot's rim goes SEAT under the skin, and where the skin falls away
# under the foot (a shoulder's slope) the lowest part of the piece is drawn down onto the skin, never the whole piece
# pushed in
SEAT = 0.02
# a tail's base end is pushed this far under the skin
BURY = 0.03


def sink(ob, base, axis, name):
	# push a placed piece along -axis until every vertex in `base` lies BURY inside the body
	sunk = 0.0
	while max(outside(ob.location + ob.data.vertices[i].co) for i in base) > -BURY and sunk < 0.2:
		ob.location -= axis * 0.005
		sunk += 0.005
	print(f"SINK {name} {sunk:.3f}, base at {tuple(round(c, 3) for c in ob.location)}")


def to_skin(p, axis):
	# how far a point must move down `axis` to lie SEAT under the skin (negative: up); None where no skin lies below
	t = -0.6
	while outside(p - axis * t) > -SEAT:
		t += 0.01
		if t > 0.6:
			return None
	while outside(p - axis * (t - 0.001)) <= -SEAT:
		t -= 0.001
	return t


def seat(ob, foot, axis, band, name):
	# set a placed horn or ear on the skin: move it along `axis` until the vertex of its foot nearest the skin lies SEAT
	# under it, then draw the rest of the foot down onto the skin, and with it what stands above the foot, less the
	# higher it stands, to nothing at `band` (a share of the piece's length)
	vs = ob.data.vertices
	gap = {i: to_skin(ob.location + vs[i].co, axis) for i in foot}
	foot = [i for i in foot if gap[i] is not None]
	lift = min(gap[i] for i in foot)
	ob.location -= axis * lift
	for i in foot:
		gap[i] -= lift
	high = max(v.co.dot(axis) for v in vs) - min(v.co.dot(axis) for v in vs)
	band *= high
	flat = {i: vs[i].co - axis * vs[i].co.dot(axis) for i in foot}
	moved = []
	for v in vs:
		t = to_skin(ob.location + v.co, axis)
		if t is None:
			continue
		# the foot's gap under this point: its nearest foot vertices across the axis, weighted by nearness
		p = v.co - axis * v.co.dot(axis)
		w = {i: math.exp(-((p - flat[i]).length / 0.012) ** 2) for i in foot}
		if sum(w.values()) < 1e-9:
			w = {min(foot, key=lambda i: (p - flat[i]).length): 1.0}
		g = sum(w[i] * gap[i] for i in w) / sum(w.values())
		over = max(0.0, t - g)
		if over < band and g > 0:
			moved.append((v, axis * g * (1 - over / band)))
	for v, d in moved:
		v.co -= d
	# the piece rides the skin from the middle of its foot
	c = sum((vs[i].co for i in foot), Vector()) / len(foot)
	ob.data.transform(Matrix.Translation(-c))
	ob.location += c
	print(f"SEAT {name} lifted {-lift:.3f}, foot gap up to {max(gap[i] for i in foot):.3f}, {len(moved)} vertices drawn down, anchor {tuple(round(x, 3) for x in ob.location)}")


def base_plane(me, spread=40, step=2, tol=0.02):
	# the plane a piece's flat bottom (a sole, or the lip of a hollow cup) rests on: of the directions within `spread`
	# degrees of straight down, the one whose lowest plane touches the most vertices (within `tol` of the piece's
	# height); returns that direction and those vertices
	vs = [v.co for v in me.vertices]
	tol *= max(v.z for v in vs) - min(v.z for v in vs)
	best = None
	for a in range(0, spread + 1, step):
		for b in range(0, 360, step * 4 if a else 360):
			n = Vector((math.sin(rad(a)) * math.cos(rad(b)), math.sin(rad(a)) * math.sin(rad(b)), -math.cos(rad(a))))
			d = [v.dot(n) for v in vs]
			low = max(d)
			near = [i for i, x in enumerate(d) if x > low - tol]
			if not best or len(near) > len(best[1]):
				best = (n, near)
	return best


def place_horn(ob, spec, name):
	# a horn or an ear. Its foot: the flat sole (or a hollow cup's lip) of a horn, the lowest tenth of an ear's soft fur
	# (`foot="low"`). A horn's sole is cut at a slant in the file: turn it level (`level`) so the horn grows straight out
	# of it, or keep the horn as the file stands it (upright already). A horn's tip curls toward -X in the file: turn it
	# to curl back (+Y), out or in (`curl`); then lean it out to its side and back, and seat it on the body
	side = 1 if spec["at"][0] >= 0 else -1
	vs = ob.data.vertices
	if spec.get("foot", "plane") == "plane":
		down, foot = base_plane(ob.data)
	else:
		zs = sorted(v.co.z for v in vs)
		down, foot = Vector((0, 0, -1)), [v.index for v in vs if v.co.z <= zs[0] + (zs[-1] - zs[0]) * 0.1]
	if not spec.get("level", True):
		down = Vector((0, 0, -1))
	rebase(ob, sum((vs[i].co for i in foot), Vector()) / len(foot))
	ob.data.transform(down.rotation_difference(Vector((0, 0, -1))).to_matrix().to_4x4())
	print(f"HORN {name} foot vertices={len(foot)} of {len(vs)}, levelled by {math.degrees(down.angle(Vector((0, 0, -1)))):.1f} degrees")
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	curl = spec.get("curl")
	spin = {"back": -90, "out": 180 if side > 0 else 0, "in": 0 if side > 0 else 180}.get(curl, 0)
	ob.data.transform(Matrix.Rotation(rad(spin), 4, "Z"))
	turn = Matrix.Rotation(rad(side * spec["tilt_out"]), 3, "Y") @ Matrix.Rotation(rad(-spec["tilt_back"]), 3, "X")
	ob.data.transform(turn.to_4x4())
	ob.location = spec["at"]
	seat(ob, foot, turn @ Vector((0, 0, 1)), spec.get("band", 0.3), name)
	top = max((ob.location + v.co).z for v in vs)
	print(f"HORN {name} tip at height {top:.3f}")


def place_wing(ob, spec):
	# root = the end at +X in the file, spreading toward -X (the file's left wing, as the file is seen from its front):
	# turn it to spread toward the slime's left (+X) with its painted side to the back. With `root="-x"` (the file's
	# right wing of a pair) it spreads to the slime's right the same way. Then raise the tip, sweep it back; returns the
	# flap axis
	side = -1 if spec.get("root") == "-x" else 1
	rebase(ob, anchor_of(ob, "x", side > 0))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	ob.data.transform(Matrix.Rotation(rad(180), 4, "Z"))
	ob.data.transform(Matrix.Rotation(rad(-side * spec["raise_"]), 4, "Y"))
	ob.data.transform(Matrix.Rotation(rad(side * spec["sweep"]), 4, "Z"))
	ob.location = spec["at"]
	sw = rad(spec["sweep"])
	# the hinge runs along the root, front to back after the sweep; a positive turn about it lifts the tip
	axis = Vector((math.sin(sw), -side * math.cos(sw), 0))
	# a check that the flap axis lifts the tip: turn the farthest point by +10 degrees about it
	far = max(ob.data.vertices, key=lambda v: v.co.length).co
	print("FLAP CHECK tip z", round(far.z, 3), "->", round((Matrix.Rotation(rad(10), 3, axis) @ far).z, 3))
	return axis


def place_tail(ob, spec, name):
	# base = the end along X that `base` names, the tip toward the other: turn it to stretch back (+Y), lift the tip
	# (`lift`, degrees up), set it on the body; with `sink`, push it into the body until its base end lies inside
	high = spec["base"] == "+x"
	xs = sorted(v.co.x for v in ob.data.vertices)
	cut = xs[-1] - (xs[-1] - xs[0]) * 0.06 if high else xs[0] + (xs[-1] - xs[0]) * 0.06
	end = [v.index for v in ob.data.vertices if (v.co.x >= cut if high else v.co.x <= cut)]
	rebase(ob, anchor_of(ob, "x", high))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	ob.data.transform(Matrix.Rotation(rad(-90 if high else 90), 4, "Z"))
	ob.data.transform(Matrix.Rotation(rad(spec["lift"]), 4, "X"))
	ob.location = spec["at"]
	if spec.get("sink"):
		sink(ob, end, Matrix.Rotation(rad(spec["lift"]), 3, "X") @ Vector((0, 1, 0)), name)


def meridian():
	# the body's outline from its feet to its top: (height, radius, length along the skin from the feet) every 0.005
	rows, run = [], 0.0
	for k in range(201):
		z = k * 0.005
		r = skin_radius(z)
		if rows:
			run += math.hypot(z - rows[-1][0], r - rows[-1][1])
		rows.append((z, r, run))
	return rows


MERIDIAN = meridian()


def along(run):
	# the height and radius that lie `run` along the skin from the feet
	run = min(max(run, 0.0), MERIDIAN[-1][2])
	for a, b in zip(MERIDIAN, MERIDIAN[1:]):
		if b[2] >= run:
			f = (run - a[2]) / max(b[2] - a[2], 1e-9)
			return a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
	return MERIDIAN[-1][0], MERIDIAN[-1][1]


def place_wrap(ob, spec, name):
	# a flat piece the file lays in its XZ plane with its face to -Y (a vine, a leaf), bent around the body onto its
	# skin: its height runs up the skin, its width around the body, its back face on the skin. `at` = (degrees around
	# the body from the front, positive toward the slime's left; the height of its middle); `turn` degrees in its own
	# plane, positive counter-clockwise as seen from outside; `flip` mirrors it left to right
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	rebase(ob, (lo + hi) / 2)
	ob.data.transform(Matrix.Scale(spec["scale"], 4) @ Matrix.Rotation(rad(-spec.get("turn", 0)), 4, "Y"))
	if spec.get("flip"):
		ob.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
		ob.data.flip_normals()
	back = max(v.co.y for v in vs)
	phi, height = rad(spec["at"][0]), spec["at"][1]
	start = next(row[2] for row in MERIDIAN if row[0] >= height)
	r0 = skin_radius(height)
	anchor = Vector((r0 * math.sin(phi), -r0 * math.cos(phi), height))
	for v in vs:
		z, r = along(start + v.co.z)
		a = phi + v.co.x / max(r, 0.08)
		# (its back face a hair under the skin, so no gap shows)
		out = r + (back - v.co.y) - 0.005
		v.co = Vector((out * math.sin(a), -out * math.cos(a), z)) - anchor
	ob.location = anchor
	print(f"WRAP {name} at {spec['at'][0]} degrees, height {height}, anchor {tuple(round(x, 3) for x in anchor)}")


def onto_skin(p):
	# a point inside the body (or under the ground) moved straight out onto the skin
	p.z = max(p.z, 0.005)
	r, least = math.hypot(p.x, p.y), skin_radius(p.z) + 0.004
	if r < least:
		k = least / max(r, 1e-6)
		p.x, p.y = p.x * k, p.y * k
	return p


def place_frame(ob, spec, name):
	# a flat piece the file lays in its XZ plane with its face to -Y (a vine, a leaf) that grows OUT of the body, as the
	# owner's painting draws vines curling round the outline: stood upright in the plane through the body's middle line
	# at `at` = (degrees around from the front, positive toward the slime's left; the height of its middle; how far its
	# middle stands from the middle line), seen from there as the file is seen from its front (at +-90 degrees, the
	# painting's own view). `yaw` turns its plane about the upright line, its outer end toward the back (degrees), so it
	# also shows from the side. `hug` (0 to 1) bends it so its inner edge follows the body's outline up and down;
	# whatever then lies inside the body is laid on the skin. `turn` and `flip` as for a wrap
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	rebase(ob, (lo + hi) / 2)
	ob.data.transform(Matrix.Scale(spec["scale"], 4) @ Matrix.Rotation(rad(-spec.get("turn", 0)), 4, "Y"))
	if spec.get("flip"):
		ob.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
		ob.data.flip_normals()
	deg, height, reach = spec["at"]
	phi, s, hug = rad(deg), (1 if deg >= 0 else -1), spec.get("hug", 0)
	plane = phi + s * rad(spec.get("yaw", 0))
	out = Vector((math.sin(plane), -math.cos(plane), 0))
	depth = Vector((math.cos(plane), math.sin(plane), 0)) * s
	centre = Vector((reach * math.sin(phi), -reach * math.cos(phi), height))
	r0 = skin_radius(height)
	anchor = Vector((r0 * math.sin(phi), -r0 * math.cos(phi), height))
	laid = 0
	for v in vs:
		p = centre + out * (v.co.x * s) + depth * v.co.y + Vector((0, 0, v.co.z))
		p += out * (hug * (skin_radius(p.z) - r0))
		q = onto_skin(p.copy())
		laid += (q - p).length > 1e-6
		v.co = q - anchor
	ob.location = anchor
	print(f"FRAME {name} at {deg} degrees, height {height}, reach {reach}, {laid} of {len(vs)} vertices laid on the skin")


def place_aim(ob, spec, name):
	# a piece set by where it points (a bird's wing at rest on the back: the owner, 2026-11-10, "tư thế tự nhiên của cánh
	# chim", "phải ở đằng sau lưng của slime", "xoay ngang như đang xòe cánh"): its root (the end along X that `root`
	# names) at `at`, turned so its long line (from the root to its farthest point) runs along `point` and its painted
	# side (-Y in the file) looks along `face` (made square to `point`). The directions are for a piece on the slime's
	# left (+X); one on its right (`at` x < 0) takes them mirrored. A turn cannot mirror: a piece whose painted side
	# turns from the file's front to the slime's back must be the file's piece of the same side, or it comes out upside
	# down (the run prints how upright the file's top stays). Returns the beat axis: the painted side's normal, signed
	# so a positive turn lifts the tip, the wing beating in its own plane
	vs = ob.data.vertices
	rebase(ob, anchor_of(ob, "x", spec["root"] == "+x"))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))

	def frame(along, look):
		along = along.normalized()
		look = (look - along * look.dot(along)).normalized()
		return Matrix((along, look, along.cross(look))).transposed()

	m = 1 if spec["at"][0] >= 0 else -1
	point, face = Vector(spec["point"]), Vector(spec["face"])
	point.x *= m
	face.x *= m
	far = max(vs, key=lambda v: v.co.length).co.copy()
	turn = frame(point, face) @ frame(far, Vector((0, -1, 0))).transposed()
	ob.data.transform(turn.to_4x4())
	ob.location = spec["at"]
	tip = max(vs, key=lambda v: v.co.length).co + ob.location
	inside = sum(outside(ob.location + v.co) < 0 for v in vs)
	upright = (turn @ Vector((0, 0, 1))).z
	print(f"AIM {name} tip at {tuple(round(x, 3) for x in tip)}, {inside} of {len(vs)} vertices inside the body, "
		f"upright {upright:+.2f}")
	along = point.normalized()
	normal = (face - along * face.dot(along)).normalized()
	return normal if normal.cross(along).z > 0 else -normal


SUCKER_PIXELS = []


def suckers_of(ob):
	# the vertices painted as suckers (light pink-purple; the arm itself is dark blue with blue-violet streaks), by the
	# texture under them
	import numpy as np
	img = [i for i in bpy.data.images if i.size[0] > 0][0]
	w, h = img.size
	if not SUCKER_PIXELS:
		px = np.empty(w * h * 4, np.float32)
		img.pixels.foreach_get(px)
		SUCKER_PIXELS.append(px.reshape(h, w, 4))
	px = SUCKER_PIXELS[0]
	uv = ob.data.uv_layers.active.data
	sums = [[0.0, 0.0, 0] for _ in ob.data.vertices]
	for loop in ob.data.loops:
		u, v = uv[loop.index].uv
		c = px[min(int(v % 1 * h), h - 1), min(int(u % 1 * w), w - 1)]
		s = sums[loop.vertex_index]
		s[0] += c[0]
		s[1] += c[1]
		s[2] += 1
	return [i for i, s in enumerate(sums) if s[2] and s[0] / s[2] > SUCKER_RED and (s[0] - s[1]) / s[2] > SUCKER_PINK]


# a sucker's red, and how far its red stands above its green (the arm's streaks are blue-violet: low red)
SUCKER_RED = 0.5
SUCKER_PINK = 0.15
# how much of an arm's length (from its root) is its root, under the body
ROOT_PART = 0.2
# above this height a part of an arm inside the body pierces its side (below, the jelly's low bulge hides it)
PIERCE = 0.12


def place_tentacle(ob, spec, name):
	# an octopus arm growing from under the body (the owner, 2026-11-10: "gắn ở dưới thân của slime", "co duỗi, ngọ nguậy
	# như tay bạch tuộc"; then: every arm joins the body underneath, none sunk into it to show only a stub at its side,
	# and the purple suckers face down or out, never up: "phần màu tím phải quay xuống bên dưới hoặc ra ngoài"). The file
	# draws it in its XZ plane, its thick root the lowest end. The root goes under the body at `at` = (degrees around from
	# the front, + toward the slime's left; how far out from the middle line; height), its long line (root to farthest
	# point) out over the ground. How steeply it climbs and how its plane rolls about that line are searched: the turn
	# whose suckers look most down and out, with nothing past its root inside the body, nothing over the face, the root
	# not lifted off the ground's level and the arm reaching well out of the body. Then rigged: a chain of `bones` bones
	# root to tip (named <name>_0, _1, ...), each vertex weighted by how far along the arm it lies, measured over its
	# surface. Returns the curl axis (its plane's normal; a positive turn lifts the tip) and the joints
	vs = ob.data.vertices
	zs = sorted(v.co.z for v in vs)
	cut = zs[0] + (zs[-1] - zs[0]) * 0.06
	root = [v.index for v in vs if v.co.z <= cut]
	rebase(ob, sum((vs[i].co for i in root), Vector()) / len(root))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	# how far along the arm each vertex lies: the shortest way over its edges from the root (Dijkstra)
	links = [[] for _ in vs]
	for e in ob.data.edges:
		a, b = e.vertices
		d = (vs[a].co - vs[b].co).length
		links[a].append((b, d))
		links[b].append((a, d))
	dist = [math.inf] * len(vs)
	heap = []
	for i in root:
		dist[i] = 0.0
		heap.append((0.0, i))
	heapq.heapify(heap)
	while heap:
		d, i = heapq.heappop(heap)
		if d > dist[i]:
			continue
		for j, w in links[i]:
			if d + w < dist[j]:
				dist[j] = d + w
				heapq.heappush(heap, (d + w, j))
	top = max(x for x in dist if x < math.inf)
	t = [min(x, top) / top for x in dist]

	def frame(along, look):
		along = along.normalized()
		look = (look - along * look.dot(along)).normalized()
		return Matrix((along, look, along.cross(look))).transposed()

	deg, reach, height = spec["at"]
	out = Vector((math.sin(rad(deg)), -math.cos(rad(deg)), 0))
	side = Vector((0, 0, 1)).cross(out)
	far = max(vs, key=lambda v: v.co.length).co.copy()
	sucker = suckers_of(ob)
	cos = [v.co.copy() for v in vs]
	nos = [v.normal.copy() for v in vs]
	flat = frame(far, Vector((0, 1, 0))).transposed()
	best = None
	for rise in range(-10, 35, 5):
		point = out * math.cos(rad(rise)) + Vector((0, 0, math.sin(rad(rise))))
		for roll in range(0, 360, 15):
			turn = frame(point, Matrix.Rotation(rad(roll), 3, point) @ side) @ flat
			ps = [turn @ c for c in cos]
			# (the root may go under the ground, hidden by the body; the arm past it lies on the ground at most)
			lift = max(-(height + min(p.z for p, f in zip(ps, t) if f > ROOT_PART)), 0.0)
			origin = Vector((out.x * reach, out.y * reach, height + lift))
			ws = [origin + p for p in ps]
			# past its root inside the body: hidden under the jelly's low bulge, or (above PIERCE) out through its side
			inside = sum(1 for w, f in zip(ws, t) if f > ROOT_PART and outside(w) < 0) / len(ws)
			pierce = sum(1 for w in ws if w.z > PIERCE and outside(w) < 0) / len(ws)
			face = sum(1 for w in ws if 0.3 < w.z < 0.7 and w.y < 0 and abs(math.atan2(w.x, -w.y)) < rad(35)) / len(ws)
			looks = [turn @ nos[i] for i in sucker]
			look = sum(looks, Vector()).normalized()
			up = sum(1 for d in looks if d.z > 0.3) / max(len(looks), 1)
			score = (-look.z + 0.6 * look.dot(out) - 2 * up - 10 * pierce - 2 * inside - 4 * face - 10 * lift
				+ 1.5 * max(outside(w) for w in ws))
			if best is None or score > best[0]:
				best = (score, rise, roll, point, turn, lift, inside, pierce, up, look)
	_, rise, roll, point, turn, lift, inside, pierce, up, look = best
	ob.data.transform(turn.to_4x4())
	ob.location = Vector((out.x * reach, out.y * reach, height + lift))
	n = spec.get("bones", 5)
	joints = []
	for k in range(n + 1):
		band = [vs[i].co for i in range(len(vs)) if (k - 0.5) / n <= t[i] < (k + 0.5) / n]
		if not band:
			band = [vs[min(range(len(vs)), key=lambda i: abs(t[i] - k / n))].co]
		joints.append(sum(band, Vector()) / len(band))
	arm = bpy.data.armatures.new(name + "Rig")
	rig = bpy.data.objects.new(name + "Rig", arm)
	bpy.context.scene.collection.objects.link(rig)
	rig.location = ob.location
	bpy.ops.object.select_all(action="DESELECT")
	rig.select_set(True)
	bpy.context.view_layer.objects.active = rig
	bpy.ops.object.mode_set(mode="EDIT")
	prev = None
	for k in range(n):
		b = arm.edit_bones.new(f"{name}_{k}")
		b.head, b.tail = joints[k], joints[k + 1]
		if prev:
			b.parent = prev
			b.use_connect = True
		prev = b
	bpy.ops.object.mode_set(mode="OBJECT")
	groups = [ob.vertex_groups.new(name=f"{name}_{k}") for k in range(n)]
	for i in range(len(vs)):
		# (between the middles of the two nearest bones)
		f = min(max(t[i] * n - 0.5, 0.0), n - 1.0)
		k = min(int(f), n - 2)
		w = f - k
		groups[k].add([i], 1.0 - w, "REPLACE")
		groups[k + 1].add([i], w, "REPLACE")
	ob.parent = rig
	ob.matrix_parent_inverse = rig.matrix_world.inverted()
	mod = ob.modifiers.new("Rig", "ARMATURE")
	mod.object = rig
	normal = turn @ Vector((0, 1, 0))
	along = point.normalized()
	axis = normal if normal.cross(along).z > 0 else -normal
	tip = max((ob.location + v.co).length for v in vs)
	print(f"TENTACLE {name} at {deg} degrees, rise {rise}, roll {roll}, root {tuple(round(x, 3) for x in ob.location)}, "
		f"reaches {tip:.3f} from the feet, lifted {lift:.3f}, {inside:.0%} under the body, {pierce:.0%} through its side, "
		f"suckers {len(sucker)} of {len(vs)} looking {tuple(round(x, 2) for x in look)}, {up:.0%} of them up, {n} bones")
	# each bone's rest frame (its point and its X and Y axes, Y along the bone), as Roblox's import puts it: the game
	# builds the bones from these, by name, and the skin bends with them
	frames = [rig.matrix_world @ b.matrix_local for b in arm.bones]
	return axis, frames, rig


def mirrored(ob, name):
	twin = ob.copy()
	twin.data = ob.data.copy()
	twin.name = name
	bpy.context.scene.collection.objects.link(twin)
	twin.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
	twin.data.flip_normals()
	twin.location = (-ob.location.x, ob.location.y, ob.location.z)
	return twin


wear, axes, joints, rigs = [], {}, {}, []
for name, spec in KIT["pieces"].items():
	ob = parts[spec["part"]]
	if spec["kind"] == "horn":
		place_horn(ob, spec, name)
	elif spec["kind"] == "wing":
		axis = place_wing(ob, spec)
		axes[name] = axis
		if spec.get("twin"):
			axes[spec["twin"]] = Vector((axis.x, -axis.y, axis.z))
	elif spec["kind"] == "wrap":
		place_wrap(ob, spec, name)
	elif spec["kind"] == "frame":
		place_frame(ob, spec, name)
	elif spec["kind"] == "aim":
		axes[name] = place_aim(ob, spec, name)
	elif spec["kind"] == "tentacle":
		axes[name], joints[name], rig = place_tentacle(ob, spec, name)
		rigs.append(rig)
	else:
		place_tail(ob, spec, name)
	ob.name = name
	wear.append(ob)
	if spec.get("twin"):
		wear.append(mirrored(ob, spec["twin"]))

# a part no piece uses (a bit the owner did not want) leaves the pictures too
used = {spec["part"] for spec in KIT["pieces"].values()}
for key, ob in parts.items():
	if key not in used:
		bpy.data.objects.remove(ob)

# texture at 1024
img = [i for i in bpy.data.images if i.size[0] > 0][0]
img.scale(TEXTURE, TEXTURE)
img.filepath_raw = os.path.join(ROOT, KIT["texture"])
img.file_format = "PNG"
img.save()


# the reference body (a lathe of the profile) and two eyes on its front, for the pictures only
def lathe():
	bm = bmesh.new()
	seg = 40
	rings = []
	for i, r in enumerate(PROFILE):
		z = i * 0.05
		ring = [bm.verts.new((max(r, 0.0001) * math.cos(2 * math.pi * k / seg), max(r, 0.0001) * math.sin(2 * math.pi * k / seg), z)) for k in range(seg)]
		rings.append(ring)
	for a, b in zip(rings, rings[1:]):
		for k in range(seg):
			bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
	bm.faces.new(list(reversed(rings[0])))
	me = bpy.data.meshes.new("Body")
	bm.to_mesh(me)
	ob = bpy.data.objects.new("Body", me)
	bpy.context.scene.collection.objects.link(ob)
	for p in me.polygons:
		p.use_smooth = True
	m = bpy.data.materials.new("BodyMat")
	m.use_nodes = True
	m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = KIT["body"]
	me.materials.append(m)
	for sx in (-0.16, 0.16):
		bpy.ops.mesh.primitive_uv_sphere_add(radius=0.06, location=(sx, -0.47, 0.55))
		eye = bpy.context.active_object
		eye.name = "Eye"
		em = bpy.data.materials.new("EyeMat")
		em.use_nodes = True
		em.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (1, 1, 1, 1)
		eye.data.materials.append(em)
	return ob


body = lathe()

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 560
scene.render.resolution_y = 560
world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.82, 0.86, 0.9, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 1.2
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.5
sun.rotation_euler = (rad(45), 0, rad(-35))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = 2.0
scene.collection.objects.link(cam)
scene.camera = cam
centre = Vector((0, 0.15, 0.55))
views = {
	"front": Vector((0, -1, 0)),
	"back": Vector((0, 1, 0)),
	"side": Vector((1, 0, 0)),
	"top": Vector((0, 0.001, 1)),
	"game": Vector((0.6, -1, 0.75)),
	"backq": Vector((-0.8, 1, 0.5)),
	# (low at the front quarter: what grows from under the body)
	"low": Vector((0.7, -1, 0.12)),
}
for name, d in views.items():
	cam.location = centre + d.normalized() * 6
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(REVIEW, f"{name}.png")
	bpy.ops.render.render(write_still=True)
# the head close, from the front and from above the back, where horns and ears sit
cam.data.ortho_scale = 0.9
head = Vector((0, 0, 0.8))
for name, d in {"head": Vector((0, -1, 0.15)), "headback": Vector((0.3, 1, 0.6))}.items():
	cam.location = head + d.normalized() * 6
	cam.rotation_euler = (head - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(REVIEW, f"{name}.png")
	bpy.ops.render.render(write_still=True)


# numbers for the game, in Roblox mesh space: (X, Y, Z) = (-x, z, y)
def rb(v):
	return [round(-v.x, 4), round(v.z, 4), round(v.y, 4)]


out = {}
total = 0
for ob in wear:
	pts = [ob.matrix_world @ v.co for v in ob.data.vertices]
	lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
	hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
	c = (lo + hi) / 2
	size = hi - lo
	ob.data.calc_loop_triangles()
	total += len(ob.data.loop_triangles)
	entry = dict(centre=rb(c), size=[round(size.x, 4), round(size.z, 4), round(size.y, 4)], anchor=rb(ob.location),
		tris=len(ob.data.loop_triangles))
	if ob.name in axes:
		entry["axis"] = rb(axes[ob.name])
	if ob.name in joints:
		# (a rigged piece: its bones root to tip, each its point, X axis and Y axis as Roblox's import makes them: the
		# FBX turns a bone half round its own Y, so its X is Blender's turned backwards; checked in Studio, 2026-11-10)
		entry["bones"] = [rb(m.translation) + rb(-m.col[0].xyz) + rb(m.col[1].xyz) for m in joints[ob.name]]
	out[ob.name] = entry
out["triangles"] = total
with open(os.path.join(ROOT, "wear.json"), "w") as f:
	json.dump(out, f, indent=1)
print("WEAR", json.dumps(out))

# export the pieces like the body
bpy.ops.object.select_all(action="DESELECT")
for ob in wear + rigs:
	ob.select_set(True)
bpy.context.view_layer.objects.active = wear[0]
# (a rigged kit carries its bones; the modifier stays live so the skin goes out unposed)
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, KIT["out"] + ".fbx"), use_selection=True,
	object_types={"MESH", "ARMATURE"} if rigs else {"MESH"}, axis_forward="-Z", axis_up="Y",
	apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True, bake_space_transform=False,
	mesh_smooth_type="FACE", use_mesh_modifiers=not rigs, use_tspace=False, path_mode="AUTO", embed_textures=False,
	add_leaf_bones=False, use_armature_deform_only=True, bake_anim=False)
print("DONE")
