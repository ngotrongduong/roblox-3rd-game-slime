# A Secret slime's worn pieces (Config.Wear) from the owner's Meshy model of one wing, one horn and one tail.
# Splits the three, mirrors the wing and the horn into pairs, lowers the triangles for phones, sets each piece on a
# slime body one unit tall (the game's mesh units), renders it from six sides into <folder>/review/, and exports:
#   <out>.fbx       HornL HornR WingL WingR Tail, placed around the body (feet at the origin)
#   <texture>.png   the texture at 1024
#   wear.json       each piece's centre, size and anchor (and a wing's flap axis) in Roblox mesh space: Config.Wear
# Blender axes are the slime body's own (tools/blender/slime_body.py): Z up, the slime faces -Y, its own left is +X.
# Exported like the body (FBX, forward -Z, up Y), so Roblox reads (X, Y, Z) = (-x, z, y).
# Every Meshy model so far lays the pieces out alike: the wing's root at its +X end, spreading toward -X with its
# painted side to -Y; the horn's base at the bottom, its tip curling toward -X; the tail's base at its +X end.
# Run: tools/blender/wear_kit.ps1 <kit>
import bpy, bmesh, json, math, os, sys
from mathutils import Matrix, Vector

ART = r"C:\Roblox 3rd game\art\models\accessories"

# where each piece sits on the body (Blender axes, body height 1): anchor point, size factor, turns (degrees);
# `sort` says which piece a loose part of the file belongs to, by its middle; `budget` the triangles a piece keeps
KITS = {
	# Tempest Dragon (secret-black-blue), 2026-11-10
	"TempestDragon": dict(
		folder="tempest_dragon",
		glb="neon_dragon_relics.glb",
		out="TempestDragonWear",
		texture="tempest_dragon_wear.png",
		sort=lambda c: "Tail" if c.x < -0.185 else ("Horn" if c.x > 0.25 else "Wing"),
		horn=dict(at=(0.223, 0.002, 0.764), scale=0.92, tilt_out=16, tilt_back=18, curl="back"),
		wing=dict(at=(0.3, 0.34, 0.47), scale=1.5, raise_=24, sweep=38),
		tail=dict(at=(0.0, 0.44, 0.16), scale=1.25, lift=12),
		budget=dict(Horn=520, Wing=760, Tail=640),
		body=(0.05, 0.12, 0.45, 1),
	),
	# Steam Dragon (secret-blue-red), 2026-11-10
	"SteamDragon": dict(
		folder="steam_dragon",
		glb="patriotic_dragon_cost.glb",
		out="SteamDragonWear",
		texture="steam_dragon_wear.png",
		sort=lambda c: "Tail" if c.z < -0.02 else ("Horn" if c.x > 0.2 else "Wing"),
		# (the owner's painting: the horns stand at the shoulders, their tips curling out to the sides)
		horn=dict(at=(0.27, 0.04, 0.74), scale=0.8, tilt_out=14, tilt_back=0, curl="out"),
		wing=dict(at=(0.3, 0.34, 0.47), scale=1.1, raise_=24, sweep=38),
		tail=dict(at=(0.0, 0.45, 0.21), scale=0.62, lift=14),
		budget=dict(Horn=900, Wing=900, Tail=900),
		body=(0.55, 0.12, 0.1, 1),
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
HORN, WING, TAIL, BUDGET = KIT["horn"], KIT["wing"], KIT["tail"], KIT["budget"]


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

# weld the seams, split into loose parts, and sort them into the three pieces
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
groups = {"Tail": [], "Wing": [], "Horn": []}
for o in [o for o in bpy.data.objects if o.type == "MESH"]:
	c = sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
	groups[KIT["sort"](c)].append(o)
pieces = {}
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
	pieces[key] = ob


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


for key, ob in pieces.items():
	print(f"KEPT {key} tris={decimate(ob, BUDGET[key])}")

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


# the owner, 2026-11-10: "vị trí gốc của 2 cặp sừng còn bị lộ" (the horns' bases showed): a horn is pushed down its own
# axis until all of it below its collar (the lowest height where it is nearly as wide as its base gets) lies this far
# inside the body, so no rim and no overhang shows above the skin
BURY = 0.03


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


# horn: its base is flat but cut at a slant in the file: turn the base level so the horn grows straight out of it; its
# tip then curls toward -X: turn it to curl back (+Y) or out (+X), lean it out (+X) and back
horn = pieces["Horn"]
down, ring = base_plane(horn.data)
rebase(horn, sum((horn.data.vertices[i].co for i in ring), Vector()) / len(ring))
horn.data.transform(down.rotation_difference(Vector((0, 0, -1))).to_matrix().to_4x4())
print(f"HORN base vertices={len(ring)} of {len(horn.data.vertices)}, levelled by {math.degrees(down.angle(Vector((0, 0, -1)))):.1f} degrees")
horn.data.transform(Matrix.Scale(HORN["scale"], 4))
vs = horn.data.vertices
tall = max(v.co.z for v in vs)
widths = [0.0] * 18
for v in vs:
	k = max(0, int(v.co.z / tall / 0.02))
	if k < len(widths):
		widths[k] = max(widths[k], v.co.xy.length)
collar = (next(k for k, w in enumerate(widths) if w >= max(widths) * 0.92) + 1) * 0.02
base = [v.index for v in vs if v.co.z <= collar * tall]
print(f"HORN collar at {collar:.0%} of its height, {len(base)} vertices below it")
horn.data.transform(Matrix.Rotation(rad(-90 if HORN["curl"] == "back" else 180), 4, "Z"))
turn = Matrix.Rotation(rad(HORN["tilt_out"]), 3, "Y") @ Matrix.Rotation(rad(-HORN["tilt_back"]), 3, "X")
horn.data.transform(turn.to_4x4())
horn.location = HORN["at"]
up = turn @ Vector((0, 0, 1))
sunk = 0.0
while max(outside(horn.location + vs[i].co) for i in base) > -BURY and sunk < 0.2:
	horn.location -= up * 0.005
	sunk += 0.005
top = max((horn.location + v.co).z for v in horn.data.vertices)
print(f"HORN sunk {sunk:.3f}, base at {tuple(round(c, 3) for c in horn.location)}, tip at height {top:.3f}")

# wing: root = the end at +X in the file, spreading toward -X: turn it to spread toward the slime's left (+X) with its
# painted side to the back, raise the tip, sweep it back
wing = pieces["Wing"]
rebase(wing, anchor_of(wing, "x", True))
wing.data.transform(Matrix.Scale(WING["scale"], 4))
wing.data.transform(Matrix.Rotation(rad(180), 4, "Z"))
wing.data.transform(Matrix.Rotation(rad(-WING["raise_"]), 4, "Y"))
wing.data.transform(Matrix.Rotation(rad(WING["sweep"]), 4, "Z"))
wing.location = WING["at"]
sw = rad(WING["sweep"])
# the hinge runs along the root, front to back after the sweep; a positive turn about it lifts the tip
wing_axis = Vector((math.sin(sw), -math.cos(sw), 0))

# tail: base = the thick end at +X in the file, the tip toward -X: turn it to stretch back (+Y), tip up
tail = pieces["Tail"]
rebase(tail, anchor_of(tail, "x", True))
tail.data.transform(Matrix.Scale(TAIL["scale"], 4))
tail.data.transform(Matrix.Rotation(rad(-90), 4, "Z"))
tail.data.transform(Matrix.Rotation(rad(-TAIL["lift"]), 4, "X"))
tail.location = TAIL["at"]


def mirrored(ob, name):
	twin = ob.copy()
	twin.data = ob.data.copy()
	twin.name = name
	bpy.context.scene.collection.objects.link(twin)
	twin.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
	twin.data.flip_normals()
	twin.location = (-ob.location.x, ob.location.y, ob.location.z)
	return twin


horn.name, wing.name = "HornL", "WingL"
hornR = mirrored(horn, "HornR")
wingR = mirrored(wing, "WingR")
wear = [horn, hornR, wing, wingR, tail]

# a check that the flap axis lifts the tip: turn WingL's farthest point by +10 degrees about it
far = max(wing.data.vertices, key=lambda v: v.co.length).co
lifted = Matrix.Rotation(rad(10), 3, wing_axis) @ far
print("FLAP CHECK tip z", round(far.z, 3), "->", round(lifted.z, 3))

# texture at 1024
img = bpy.data.images["Image_0"]
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
}
for name, d in views.items():
	cam.location = centre + d.normalized() * 6
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
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
	if ob.name == "WingL":
		entry["axis"] = rb(wing_axis)
	elif ob.name == "WingR":
		entry["axis"] = rb(Vector((math.sin(sw), math.cos(sw), 0)))
	out[ob.name] = entry
out["triangles"] = total
with open(os.path.join(ROOT, "wear.json"), "w") as f:
	json.dump(out, f, indent=1)
print("WEAR", json.dumps(out))

# export the five pieces like the body
bpy.ops.object.select_all(action="DESELECT")
for ob in wear:
	ob.select_set(True)
bpy.context.view_layer.objects.active = wear[0]
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, KIT["out"] + ".fbx"), use_selection=True,
	object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True,
	use_space_transform=True, bake_space_transform=False, mesh_smooth_type="FACE", use_mesh_modifiers=True,
	use_tspace=False, path_mode="AUTO", embed_textures=False)
print("DONE")
