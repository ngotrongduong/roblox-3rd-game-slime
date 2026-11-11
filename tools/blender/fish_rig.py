# Rigs the owner's decorative fish (art/models/fish/decorative_fish.glb: eight fancy goldfish, four dark and four light,
# each a body and two belly fins) so they swim in the Secret slimes' effects: each fish is turned to look along -Y
# (Roblox's front, -Z), put on its own middle, given a chain of bones from the snout to the tail tip (the head held
# rigid, the body and the tail blended between the bones' middles) and written to one FBX with its bones, the texture
# at 1024 and fish.json (each fish's size, length and bone rest frames in Roblox space, read by VfxLib's Models).
# Review renders, straight and bent, go to <folder>/review/.
# Run: tools/blender/fish_rig.ps1
import bpy, json, math, os, sys
from mathutils import Matrix, Vector

GLB = sys.argv[sys.argv.index("--") + 1]
ROOT = os.path.dirname(GLB)
REVIEW = os.path.join(ROOT, "review")
os.makedirs(REVIEW, exist_ok=True)

# the file's two rows (dark above, light below), each left to right as the inspect renders show them
NAMES = {
	"dark": ["moon_ink", "gold_ink", "sakura_ink", "silver_ink"],
	"light": ["frost_white", "cream_gold", "blossom_pink", "lilac_white"],
}
# where the joints lie along the fish, snout 0 to tail tip 1: the head rigid to the first, the tail fins past the last
JOINTS = [0, 0.35, 0.55, 0.75, 1]
TEXTURE = 1024
SPACING = 0.4

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
scene = bpy.context.scene
meshes = [o for o in scene.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
	o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
	bpy.ops.object.join()
whole = bpy.context.view_layer.objects.active
whole.parent = None
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
bits = [o for o in scene.objects if o.type == "MESH"]


def middle(o):
	pts = [o.matrix_world @ v.co for v in o.data.vertices]
	return sum(pts, Vector()) / len(pts)


bodies = [o for o in bits if len(o.data.polygons) > 100]
fins = [o for o in bits if len(o.data.polygons) <= 100]
print(f"BITS bodies={len(bodies)} fins={len(fins)}")
groups = {id(b): [b] for b in bodies}
for f in fins:
	m = middle(f)
	near = min(bodies, key=lambda b: (middle(b) - m).length)
	groups[id(near)].append(f)
top = max(middle(b).z for b in bodies)
low = min(middle(b).z for b in bodies)
fish = []
for row, test in (("dark", lambda z: z > (top + low) / 2), ("light", lambda z: z <= (top + low) / 2)):
	row_bodies = sorted([b for b in bodies if test(middle(b).z)], key=lambda b: middle(b).x)
	for name, body in zip(NAMES[row], row_bodies):
		bpy.ops.object.select_all(action="DESELECT")
		for o in groups[id(body)]:
			o.select_set(True)
		bpy.context.view_layer.objects.active = body
		bpy.ops.object.join()
		body.name = name
		body.data.name = name
		fish.append(body)

# the texture, smaller for phones
image = None
for img in bpy.data.images:
	if img.size[0] > 0:
		image = img
image.scale(TEXTURE, TEXTURE)
image.filepath_raw = os.path.join(ROOT, "fish_texture.png")
image.file_format = "PNG"
image.save()
print(f"TEXTURE {image.filepath_raw} {TEXTURE}")


# numbers for the game, in Roblox mesh space: (X, Y, Z) = (-x, z, y)
def rb(v):
	return [round(-v.x, 4), round(v.z, 4), round(v.y, 4)]


out = {}
rigs = []
for i, ob in enumerate(fish):
	# (its snout looked -X: a quarter turn about Z makes it look -Y)
	ob.data.transform(Matrix.Rotation(math.radians(90), 4, "Z"))
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	c = (lo + hi) / 2
	ob.data.transform(Matrix.Translation(-c))
	ob.location = Vector((i * SPACING, 0, 0))
	size = hi - lo
	length = size.y
	snout = -length / 2
	# the bones along the spine, at the body's own height where each joint lies
	joints = []
	for f in JOINTS:
		y = snout + f * length
		band = [v.co for v in vs if abs(v.co.y - y) < length * 0.08]
		z = sum((p.z for p in band), 0.0) / len(band) if band else 0.0
		joints.append(Vector((0, y, z)))
	arm = bpy.data.armatures.new(ob.name + "Rig")
	rig = bpy.data.objects.new(ob.name + "Rig", arm)
	scene.collection.objects.link(rig)
	rig.location = ob.location
	bpy.ops.object.select_all(action="DESELECT")
	rig.select_set(True)
	bpy.context.view_layer.objects.active = rig
	bpy.ops.object.mode_set(mode="EDIT")
	prev = None
	n = len(JOINTS) - 1
	for k in range(n):
		b = arm.edit_bones.new(f"{ob.name}_{k}")
		b.head, b.tail = joints[k], joints[k + 1]
		b.roll = 0
		if prev:
			b.parent = prev
			b.use_connect = True
		prev = b
	bpy.ops.object.mode_set(mode="OBJECT")
	groups_ = [ob.vertex_groups.new(name=f"{ob.name}_{k}") for k in range(n)]
	mids = [(JOINTS[k] + JOINTS[k + 1]) / 2 for k in range(n)]
	for v in vs:
		t = (v.co.y - snout) / length
		if t <= mids[0]:
			groups_[0].add([v.index], 1.0, "REPLACE")
			continue
		if t >= mids[-1]:
			groups_[-1].add([v.index], 1.0, "REPLACE")
			continue
		k = max(j for j in range(n - 1) if mids[j] <= t)
		w = (t - mids[k]) / (mids[k + 1] - mids[k])
		groups_[k].add([v.index], 1.0 - w, "REPLACE")
		groups_[k + 1].add([v.index], w, "REPLACE")
	ob.parent = rig
	ob.matrix_parent_inverse = rig.matrix_world.inverted()
	mod = ob.modifiers.new("Rig", "ARMATURE")
	mod.object = rig
	rigs.append(rig)
	ob.data.calc_loop_triangles()
	# each bone's rest frame from the fish's middle (its point, X axis, Y axis as Roblox's import makes them: the FBX
	# turns a bone half round its own Y, so its X is Blender's turned backwards; wear_kit.py, checked in Studio)
	frames = [Matrix.Translation(-rig.location) @ rig.matrix_world @ b.matrix_local for b in arm.bones]
	out[ob.name] = dict(
		size=[round(size.x, 4), round(size.z, 4), round(size.y, 4)],
		length=round(length, 4),
		tris=len(ob.data.loop_triangles),
		bones=[rb(m.translation) + rb(-m.col[0].xyz) + rb(m.col[1].xyz) for m in frames],
	)
	print(f"FISH {ob.name} length {length:.3f} tris {len(ob.data.loop_triangles)} joints "
		f"{[tuple(round(x, 3) for x in j) for j in joints]}")
with open(os.path.join(ROOT, "fish.json"), "w") as f:
	json.dump(out, f, indent=1)

# review: the school from above and the side, straight, then every tail bent as it swims
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1280
scene.render.resolution_y = 480
world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.82, 0.86, 0.9, 1)
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3
sun.rotation_euler = (math.radians(40), 0, math.radians(30))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = SPACING * len(fish) * 1.05
scene.collection.objects.link(cam)
scene.camera = cam
centre = Vector((SPACING * (len(fish) - 1) / 2, 0, 0))


def shoot(name, d):
	cam.location = centre + d.normalized() * 3
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(REVIEW, f"{name}.png")
	bpy.ops.render.render(write_still=True)


shoot("fish_top", Vector((0, 0.001, 1)))
shoot("fish_side", Vector((1, -1, 0.3)))
for rig in rigs:
	for k, pb in enumerate(rig.pose.bones):
		pb.rotation_mode = "XYZ"
		pb.rotation_euler = (0, 0, math.radians(14 * min(k, 2)))
bpy.context.view_layer.update()
shoot("fish_bent_top", Vector((0, 0.001, 1)))
for rig in rigs:
	for pb in rig.pose.bones:
		pb.rotation_euler = (0, 0, 0)
bpy.context.view_layer.update()

bpy.ops.object.select_all(action="DESELECT")
for o in fish + rigs:
	o.select_set(True)
bpy.context.view_layer.objects.active = fish[0]
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, "fish.fbx"), use_selection=True,
	object_types={"MESH", "ARMATURE"}, axis_forward="-Z", axis_up="Y",
	apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True, bake_space_transform=False,
	mesh_smooth_type="FACE", use_mesh_modifiers=False, use_tspace=False, path_mode="AUTO", embed_textures=False,
	add_leaf_bones=False, use_armature_deform_only=True, bake_anim=False)
print("DONE")
