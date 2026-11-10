# Tempest Dragon's worn pieces (Secret slime secret-black-blue), from the owner's Meshy model
# art/models/accessories/tempest_dragon/neon_dragon_relics.glb (one tail, one bat wing, one horn).
# Splits the three, mirrors the wing and the horn into pairs, lowers the triangles for phones, sets each piece on a
# slime body one unit tall (the game's mesh units), renders it from five sides, and exports:
#   TempestDragonWear.fbx   HornL HornR WingL WingR Tail, placed around the body (feet at the origin)
#   tempest_dragon_wear.png the texture at 1024
#   wear.json               each piece's centre, size and anchor (and a wing's flap axis) in Roblox mesh space
# Blender axes are the slime body's own (tools/blender/slime_body.py): Z up, the slime faces -Y, its own left is +X.
# Exported like the body (FBX, forward -Z, up Y), so Roblox reads (X, Y, Z) = (-x, z, y).
# Run: tools/blender/wear_tempest_dragon.ps1
import bpy, bmesh, json, math, os
from mathutils import Matrix, Vector

ROOT = r"C:\Roblox 3rd game\art\models\accessories\tempest_dragon"
GLB = os.path.join(ROOT, "neon_dragon_relics.glb")
REVIEW = os.path.join(ROOT, "review")
os.makedirs(REVIEW, exist_ok=True)

# where each piece sits on the body (Blender axes, body height 1): anchor point, size factor, turns (degrees)
HORN = dict(at=(0.22, 0.06, 0.75), scale=0.92, tilt_out=16, tilt_back=8)
WING = dict(at=(0.3, 0.34, 0.47), scale=1.5, raise_=24, sweep=38)
TAIL = dict(at=(0.0, 0.44, 0.16), scale=1.25, lift=12)
# triangles a piece may keep (one of each pair)
BUDGET = dict(Horn=520, Wing=760, Tail=640)
TEXTURE = 1024

# the body's radius every 0.05 of its height (Shared/SlimeShape PROFILE)
PROFILE = [0.1164, 0.3466, 0.4251, 0.4704, 0.4995, 0.5171, 0.5258, 0.5269, 0.5221, 0.5131, 0.4997, 0.4811, 0.4568,
	0.4248, 0.3822, 0.3253, 0.2417, 0.1508, 0.0997, 0.0671, 0.0]


def rad(d):
	return math.radians(d)


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
src = [o for o in bpy.data.objects if o.type == "MESH"][0]
for o in bpy.data.objects:
	if o is not src and o.type != "MESH":
		bpy.data.objects.remove(o)
bpy.context.view_layer.objects.active = src
src.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mat = src.data.materials[0]
for node in mat.node_tree.nodes:
	print("NODE", node.type, node.name, getattr(getattr(node, "image", None), "name", ""))

# weld the seams, split into loose parts, and sort them by where they stand (tail left, wing middle, horn right)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
groups = {"Tail": [], "Wing": [], "Horn": []}
for o in [o for o in bpy.data.objects if o.type == "MESH"]:
	c = sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
	key = "Tail" if c.x < -0.185 else ("Horn" if c.x > 0.25 else "Wing")
	groups[key].append(o)
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

# horn: base = lowest end; its tip curls toward -X in the file: turn it to curl back (+Y), lean out (+X) and back
horn = pieces["Horn"]
rebase(horn, anchor_of(horn, "z", False))
horn.data.transform(Matrix.Scale(HORN["scale"], 4))
horn.data.transform(Matrix.Rotation(rad(-90), 4, "Z"))
horn.data.transform(Matrix.Rotation(rad(HORN["tilt_back"]), 4, "X"))
horn.data.transform(Matrix.Rotation(rad(HORN["tilt_out"]), 4, "Y"))
horn.location = HORN["at"]

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

# tail: base = the thick end at +X in the file, the spade tip up toward -X: turn it to stretch back (+Y), tip up
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
img.filepath_raw = os.path.join(ROOT, "tempest_dragon_wear.png")
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
	m.diffuse_color = (0.05, 0.12, 0.45, 1)
	m.use_nodes = True
	m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.12, 0.45, 1)
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
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, "TempestDragonWear.fbx"), use_selection=True,
	object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True,
	use_space_transform=True, bake_space_transform=False, mesh_smooth_type="FACE", use_mesh_modifiers=True,
	use_tspace=False, path_mode="AUTO", embed_textures=False)
print("DONE")
