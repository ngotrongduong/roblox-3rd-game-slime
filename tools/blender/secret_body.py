# A Secret slime's own body from the owner's 3D model (2026-11-11: Moss Golem, Stone Tortoise, Dragonfruit Slime).
# The game keeps the shared slime body's rig: client/SlimeLook clones ClientKit.SlimeBody (bones and all) and gives it
# this mesh (MeshPart:ApplyMesh), so the jelly squash, hop and lean and the face work unchanged. So the model is set in
# exactly the base body's box (feet at the origin, height MeshHeight, width the body's), bound to the same bones at the
# same rest places, weighted by the same rule (tools/blender/slime_body.py `skin`), and exported the same way.
#   & "C:\Roblox 3rd game\tools\blender\secret_body.ps1" <folder>
# reads art/models/secret_bodies/<folder>/<folder>.glb and writes there: <Name>Body.fbx, <folder>_color.png,
# <folder>_normal.png and <folder>_rough.png (1024, for the SurfaceAppearance in ClientKit.Looks), review/*.png.
# Blender axes are the body's: Z up, the slime faces -Y (the file's front), its own left is +X.
import bpy, math, os, sys
import numpy as np
from mathutils import Vector

ART = r"C:\Roblox 3rd game\art\models\secret_bodies"
# the base body's box and bones (ClientKit.SlimeBody in Studio: Size 1.0563 x 0.99993, bones Left/Right/Front/Back at
# radius 0.52826, height 0.33473 over the feet)
HEIGHT = 0.999933
RADIUS = 1.0563136 / 2
BONE_R, BONE_Z = 0.5282583, 0.3347313
BONE_K = 1.5
BONES = ["Root", "Base", "Top", "Left", "Right", "Front", "Back"]
MAX_TRIS = 4000
TEXTURE = 1024

FOLDER = sys.argv[sys.argv.index("--") + 1]
ROOT = os.path.join(ART, FOLDER)
REVIEW = os.path.join(ROOT, "review")
os.makedirs(REVIEW, exist_ok=True)
NAME = "".join(w.capitalize() for w in FOLDER.split("_")) + "Body"

for ob in list(bpy.data.objects):
	bpy.data.objects.remove(ob, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT, FOLDER + ".glb"))
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
for o in meshes:
	world = o.matrix_world.copy()
	o.parent = None
	o.matrix_world = world
	o.data.transform(world)
	o.matrix_world.identity()
for o in list(bpy.data.objects):
	if o.type != "MESH":
		bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
	o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
	bpy.ops.object.join()
body = bpy.context.view_layer.objects.active
body.name = NAME
body.data.name = NAME

# into the base body's box: the middle on the axis, feet on the ground, the same height and width
co = np.array([v.co[:] for v in body.data.vertices])
lo, hi = co.min(0), co.max(0)
mid = (lo + hi) / 2
sx = 2 * RADIUS / (hi[0] - lo[0])
sy = 2 * RADIUS / (hi[1] - lo[1])
sz = HEIGHT / (hi[2] - lo[2])
co = (co - np.array((mid[0], mid[1], lo[2]))) * np.array((sx, sy, sz))
# (both ways the body's width exactly: the MeshPart it is applied to keeps the base body's size and bones)
for v, p in zip(body.data.vertices, co):
	v.co = Vector(p)
body.data.update()
print(f"BOX {FOLDER} file {tuple(round(float(x), 3) for x in hi - lo)}, scaled x {sx:.3f}, y {sy:.3f}, up {sz:.3f}")

tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
if tris > MAX_TRIS:
	mod = body.modifiers.new("Decimate", "DECIMATE")
	mod.ratio = MAX_TRIS / tris
	bpy.ops.object.modifier_apply(modifier=mod.name)
	tris = sum(len(p.vertices) - 2 for p in body.data.polygons)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.quads_convert_to_tris()
bpy.ops.object.mode_set(mode="OBJECT")
print(f"TRIS {FOLDER} {len(body.data.polygons)}")

# the maps, 1024: colour, normal, roughness (the file's packed roughness-metal map's green)
images = [i for i in bpy.data.images if i.type == "IMAGE" and i.size[0] > 0]
def kind(img):
	n = img.name.lower()
	return "normal" if "normal" in n else ("rm" if n.endswith("_rm.jpg") or "_rm" in n or "metal" in n else "color")
for img in images:
	k = kind(img)
	img.scale(TEXTURE, TEXTURE)
	px = np.array(img.pixels[:]).reshape(TEXTURE, TEXTURE, 4)
	if k == "rm":
		g = px[:, :, 1:2]
		px = np.concatenate([g, g, g, np.ones_like(g)], axis=2)
		k = "rough"
	out = bpy.data.images.new(f"{FOLDER}_{k}", TEXTURE, TEXTURE, alpha=False)
	out.colorspace_settings.name = "sRGB" if k == "color" else "Non-Color"
	out.pixels[:] = px.ravel()
	out.filepath_raw = os.path.join(ROOT, f"{FOLDER}_{k}.png")
	out.file_format = "PNG"
	out.save()
	print(f"MAP {FOLDER}_{k}.png from {img.name}")

# the base body's rig and weights (slime_body.py build_rig / skin)
ad = bpy.data.armatures.new("SlimeRig")
arm = bpy.data.objects.new("SlimeRig", ad)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
heads = {"Root": (0, 0, 0), "Base": (0, 0, 0), "Top": (0, 0, HEIGHT), "Left": (BONE_R, 0, BONE_Z),
	"Right": (-BONE_R, 0, BONE_Z), "Front": (0, -BONE_R, BONE_Z), "Back": (0, BONE_R, BONE_Z)}
lens = {"Root": 0.2, "Base": 0.1}
root = None
for n in BONES:
	eb = ad.edit_bones.new(n)
	eb.head = Vector(heads[n])
	eb.tail = Vector(heads[n]) + Vector((0, 0, lens.get(n, 0.08)))
	eb.roll = 0.0
	if n == "Root":
		root = eb
	else:
		eb.parent = root
		eb.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")
groups = {n: body.vertex_groups.new(name=n) for n in BONES if n != "Root"}
for v in body.data.vertices:
	x, y, z = v.co
	w = {"Top": max(z, 0.0) / BONE_K, "Left": max(x, 0.0) / BONE_K, "Right": max(-x, 0.0) / BONE_K,
		"Front": max(-y, 0.0) / BONE_K, "Back": max(y, 0.0) / BONE_K}
	w = {k: val for k, val in w.items() if val > 1e-6}
	w["Base"] = 1.0 - sum(w.values())
	for k, val in w.items():
		groups[k].add([v.index], val, "REPLACE")
body.parent = arm
body.modifiers.new("Armature", "ARMATURE").object = arm

bpy.ops.object.select_all(action="DESELECT")
arm.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, NAME + ".fbx"), use_selection=True,
	object_types={"ARMATURE", "MESH"}, axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL",
	apply_unit_scale=True, use_space_transform=True, bake_space_transform=False, add_leaf_bones=False,
	primary_bone_axis="Y", secondary_bone_axis="X", use_armature_deform_only=False, bake_anim=False,
	mesh_smooth_type="OFF", use_mesh_modifiers=False, use_tspace=False, path_mode="AUTO", embed_textures=False)
print(f"FBX {NAME}.fbx")

# review: front, side, back, three-quarter
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = scene.render.resolution_y = 480
scene.world = bpy.data.worlds.new("W")
scene.world.color = (0.75, 0.77, 0.8)
sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
sun.data.energy = 3
sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = 1.4
scene.collection.objects.link(cam)
scene.camera = cam
for view, yaw in (("front", 0), ("side", 90), ("back", 180), ("quarter", 35)):
	a = math.radians(yaw)
	cam.location = (3 * math.sin(a), -3 * math.cos(a), 0.6)
	cam.rotation_euler = (math.radians(88), 0, a)
	scene.render.filepath = os.path.join(REVIEW, view + ".png")
	bpy.ops.render.render(write_still=True)
print(f"DONE {FOLDER}")
