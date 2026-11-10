# A Secret slime drawn by the owner's 3D model whose body is the shared slime's but lumpy, with hair (a mane, spines)
# grown on it (2026-11-11, Sun Lion and Rose Hedgehog: "bề mặt phía trước của thân con slime không được phẳng mịn ...
# chỉnh sửa lại cho đúng với dáng của con slime gốc (chỉ phần thân thôi nhé phần tóc giữ nguyên)").
# The body becomes the shared body itself: the model is fitted onto it and its colours are baked onto the shared body's
# UV, a skin like every Secret's (SkinIds). The hair is cut off the model where it stands out of the shared body, and
# goes out as one worn piece (Config.Wear), its map the model's own.
#   & "C:\Roblox 3rd game\tools\blender\secret_mane.ps1" <folder>
# reads art/models/secret_bodies/<folder>/<folder>.glb; writes there <folder>_skin.png (the body's skin), Mane.fbx and
# mane.png (the worn piece and its map), mane.json (its numbers, as wear_kit.py's wear.json) and review/*.png.
# Blender axes are the body's: Z up, the slime faces -Y, its own left is +X.
import bpy, bmesh, json, math, os, sys
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

ART = r"C:\Roblox 3rd game\art\models\secret_bodies"
BODY_BLEND = r"C:\Roblox 3rd game\art\models\slime_body\SlimeBody.blend"
HEIGHT = 0.999933
RADIUS = 1.0563136 / 2
# the shared body's radius every 0.05 of its height (wear_kit.py PROFILE, for a body one unit tall)
PROFILE = [0.1164, 0.3466, 0.4251, 0.4704, 0.4995, 0.5171, 0.5258, 0.5269, 0.5221, 0.5131, 0.4997, 0.4811, 0.4568,
	0.4248, 0.3822, 0.3253, 0.2417, 0.1508, 0.0997, 0.0671, 0.0]
PMAX = max(PROFILE)
SKIN = 1024

# per model: `out` how far out of the shared body a face's middle must stand to be hair, `front` the half angle (degrees
# from straight ahead) of the face's front where nothing is hair (the lumps of the old body), `budget` the mane's
# triangles, `back` how far round from the front (in turns) the skin is the mane's, grown over from the sides
MODELS = {
	"sun_lion": dict(out=0.03, front=50, budget=2400, back=0.3),
	"rose_hedgehog": dict(out=0.03, front=50, budget=2600, back=0.3),
}

FOLDER = sys.argv[sys.argv.index("--") + 1]
SPEC = MODELS[FOLDER]
ROOT = os.path.join(ART, FOLDER)
REVIEW = os.path.join(ROOT, "review")
os.makedirs(REVIEW, exist_ok=True)

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
model = bpy.context.view_layer.objects.active
model.name = "Model"


# fit the shared body's shape to the model's front (where no hair grows): its axis (x middle, y found), its feet (the
# lowest point), its radius and height found by a search that keeps the most front points on the surface
def radius_at(zn):
	f = np.clip(zn, 0, 1) / 0.05
	i = np.minimum(f.astype(int), len(PROFILE) - 2)
	p = np.array(PROFILE)
	return p[i] + (p[i + 1] - p[i]) * (f - i)


co = np.array([v.co[:] for v in model.data.vertices])
lo, hi = co.min(0), co.max(0)
cx, z0 = (lo[0] + hi[0]) / 2, lo[2]
# (the surface seen from the front: the frontmost point of each cell of a grid across x and z)
span = hi - lo
cell = np.floor((co[:, [0, 2]] - lo[[0, 2]]) / (span[[0, 2]] / 48)).astype(int)
first = {}
for i, (k, y) in enumerate(zip(map(tuple, cell), co[:, 1])):
	if k not in first or y < co[first[k], 1]:
		first[k] = i
front = co[list(first.values())]


def cost(cy, rm, hm):
	zn = (front[:, 2] - z0) / hm
	r = np.hypot(front[:, 0] - cx, front[:, 1] - cy)
	ok = (zn > 0.04) & (zn < 0.85) & (front[:, 1] < cy)
	q = r / (rm * radius_at(zn) / PMAX)
	return np.where(ok, np.minimum(np.abs(q - 1), 0.12), 0.12).mean()


best = None
cys = np.linspace(lo[1], lo[1] + 0.8 * span[1], 36)
rms = np.linspace(0.2 * span[0], 0.6 * span[0], 36)
hms = np.linspace(0.4 * span[2], 1.05 * span[2], 36)
for _ in range(3):
	for cy in cys:
		for rm in rms:
			for hm in hms:
				c = cost(cy, rm, hm)
				if best is None or c < best[0]:
					best = (c, cy, rm, hm)
	_, cy, rm, hm = best
	cys = np.linspace(cy - (cys[1] - cys[0]) * 2, cy + (cys[1] - cys[0]) * 2, 15)
	rms = np.linspace(rm - (rms[1] - rms[0]) * 2, rm + (rms[1] - rms[0]) * 2, 15)
	hms = np.linspace(hm - (hms[1] - hms[0]) * 2, hm + (hms[1] - hms[0]) * 2, 15)
c, cy, rm, hm = best
sxy, sz = RADIUS / rm, HEIGHT / hm
co = (co - np.array((cx, cy, z0))) * np.array((sxy, sxy, sz))
for v, p in zip(model.data.vertices, co):
	v.co = Vector(p)
model.data.update()
print(f"FIT {FOLDER} cost {c:.4f}, axis y {cy:.3f}, radius {rm:.3f}, height {hm:.3f} (file {tuple(round(float(x), 3) for x in span)})")

# the shared body, as it rests
with bpy.data.libraries.load(BODY_BLEND) as (src, dst):
	print("BODY meshes", list(src.meshes))
	dst.meshes = [n for n in src.meshes if n == "SlimeBody"]
body = bpy.data.objects.new("Body", dst.meshes[0])
bpy.context.scene.collection.objects.link(body)
bco = np.array([v.co[:] for v in body.data.vertices])
print(f"BODY box {tuple(round(float(x), 4) for x in bco.min(0))} {tuple(round(float(x), 4) for x in bco.max(0))}, "
	f"{len(body.data.polygons)} faces")
bm = bmesh.new()
bm.from_mesh(body.data)
tree = BVHTree.FromBMesh(bm)


def outside(p):
	# how far a point stands out of the shared body (negative inside)
	loc, nrm, _, dist = tree.find_nearest(Vector(p))
	return dist if (Vector(p) - loc).dot(nrm) >= 0 else -dist


# how well the front fits now
fv = [v.co for v in model.data.vertices if v.co.y < 0 and 0.05 < v.co.z < 0.85 and abs(math.atan2(v.co.x, -v.co.y)) < math.radians(SPEC["front"])]
d = np.array([outside(p) for p in fv])
print(f"FRONT {len(d)} points: out of the body {np.percentile(d, 5):.3f} .. {np.percentile(d, 95):.3f}, "
	f"within 0.02 {np.mean(np.abs(d) < 0.02) * 100:.0f}%")

# the hair: faces standing out of the body, not on the old body's front, grown a few rings back into the body so its
# roots stay under the skin
me = model.data
cent = [p.center.copy() for p in me.polygons]
dist = np.array([outside(c) for c in cent])
az = np.array([abs(math.degrees(math.atan2(c.x, -c.y))) for c in cent])
zz = np.array([c.z for c in cent])
behind = np.array([c.y > 0.02 for c in cent])
# (over the tip, where the angle means little, only what stands behind it)
hair = (dist > SPEC["out"]) & ((az > SPEC["front"]) | ((zz > 0.95) & behind))
for lo_az in range(0, 180, 20):
	sel = (az >= lo_az) & (az < lo_az + 20)
	print(f"  azimuth {lo_az:3d}-{lo_az + 20:3d}: {sel.sum():5d} faces, out > {SPEC['out']}: {(sel & (dist > SPEC['out'])).sum():5d}, hair {(sel & hair).sum():5d}")
vert_faces = [[] for _ in me.vertices]
for p in me.polygons:
	for vi in p.vertices:
		vert_faces[vi].append(p.index)
for _ in range(3):
	grow = hair.copy()
	for p in me.polygons:
		if hair[p.index]:
			for vi in p.vertices:
				for f in vert_faces[vi]:
					if dist[f] > -0.06 and (az[f] > SPEC["front"] - 10 or (zz[f] > 0.9 and behind[f])):
						grow[f] = True
	hair = grow
print(f"HAIR {int(hair.sum())} of {len(me.polygons)} faces")

def part(name, keep):
	ob = model.copy()
	ob.data = model.data.copy()
	ob.name = name
	bpy.context.scene.collection.objects.link(ob)
	b = bmesh.new()
	b.from_mesh(ob.data)
	b.faces.ensure_lookup_table()
	bmesh.ops.delete(b, geom=[f for f in b.faces if not keep[f.index]], context="FACES")
	b.to_mesh(ob.data)
	b.free()
	return ob


mane = part("Mane", hair)
# (the old body without its hair: what the skin is baked from, so no hair is painted on the body's back)
rest = part("Rest", ~hair)
bpy.ops.object.select_all(action="DESELECT")
bpy.context.view_layer.objects.active = mane
mane.select_set(True)
tris = sum(len(p.vertices) - 2 for p in mane.data.polygons)
if tris > SPEC["budget"]:
	mod = mane.modifiers.new("Decimate", "DECIMATE")
	mod.ratio = SPEC["budget"] / tris
	bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.quads_convert_to_tris()
bpy.ops.object.mode_set(mode="OBJECT")

# its anchor: the middle of its roots (its points nearest the skin), on the skin
mco = [v.co.copy() for v in mane.data.vertices]
md = np.array([outside(p) for p in mco])
roots = [mco[i] for i in np.argsort(np.abs(md))[: max(20, len(mco) // 10)]]
mid = sum(roots, Vector()) / len(roots)
anchor = tree.find_nearest(mid)[0]
mane.data.transform(Matrix.Translation(-anchor))
mane.location = anchor


def rb(v):
	# Roblox mesh space: (X, Y, Z) = (-x, z, y)
	return [round(-v.x, 4), round(v.z, 4), round(v.y, 4)]


pts = [anchor + v.co for v in mane.data.vertices]
mlo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
mhi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
size = mhi - mlo
mane.data.calc_loop_triangles()
info = {"Mane": dict(centre=rb((mlo + mhi) / 2), size=[round(size.x, 4), round(size.z, 4), round(size.y, 4)],
	anchor=rb(anchor), tris=len(mane.data.loop_triangles))}
with open(os.path.join(ROOT, "mane.json"), "w") as f:
	json.dump(info, f, indent=1)
print("MANE", json.dumps(info))

# the mane's map: the model's colour map (what feeds its material's Base Color)
color = None
for m in model.data.materials:
	for n in m.node_tree.nodes if m and m.use_nodes else []:
		if n.type == "BSDF_PRINCIPLED" and n.inputs["Base Color"].is_linked:
			src = n.inputs["Base Color"].links[0].from_node
			if src.type == "TEX_IMAGE" and src.image:
				color = src.image
print("MAPS colour", color.name if color else None)
if color:
	color.scale(SKIN, SKIN)
	color.filepath_raw = os.path.join(ROOT, "mane.png")
	color.file_format = "PNG"
	color.save()

bpy.ops.object.select_all(action="DESELECT")
mane.select_set(True)
bpy.context.view_layer.objects.active = mane
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, "Mane.fbx"), use_selection=True, object_types={"MESH"},
	axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True,
	use_space_transform=True, bake_space_transform=False, mesh_smooth_type="FACE", use_tspace=False,
	path_mode="AUTO", embed_textures=False)
print("FBX Mane.fbx")

# the body's skin: the model's colours baked onto the shared body's UV, from just outside it
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 4
# (clear, so what no ray met stays clear: no margin, which would smear the dark rim of a hole across it)
skin = bpy.data.images.new(f"{FOLDER}_skin", SKIN, SKIN, alpha=True)
skin.generated_color = (0, 0, 0, 0)
mat = bpy.data.materials.new("Skin")
mat.use_nodes = True
node = mat.node_tree.nodes.new("ShaderNodeTexImage")
node.image = skin
mat.node_tree.nodes.active = node
body.data.materials.clear()
body.data.materials.append(mat)
for ob in (mane, model):
	ob.hide_render = True
	ob.hide_set(True)
bpy.ops.object.select_all(action="DESELECT")
rest.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_selected_to_active=True, cage_extrusion=0.08,
	max_ray_distance=0.2, margin=0)
# where the rays met nothing (under the mane, where the old body had no skin) or met the dark inside of a cut, the
# nearest colours grow in
px = np.array(skin.pixels[:]).reshape(SKIN, SKIN, 4)
known = (px[:, :, 3] > 0.5) & (px[:, :, :3].sum(2) > 0.6)
# (and the back above the feet, all under the mane: what was baked there is the hair's roots, so it is grown over from
# the sides; u is the angle round the body, its front at 0.5; row 0 the image's bottom, the feet)
u = (np.arange(SKIN) + 0.5) / SKIN
rows = np.arange(SKIN)[:, None]
known &= ~((np.abs(u - 0.5)[None, :] > SPEC["back"]) & (rows > 0.32 * SKIN))
grown = ~known
px[:, :, 3] = 1
print(f"SKIN holes {100 - known.mean() * 100:.1f}%")
rgb = np.where(known[:, :, None], px[:, :, :3], 0)
for _ in range(1200):
	if known.all():
		break
	acc = np.zeros_like(rgb)
	cnt = np.zeros(known.shape)
	for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		acc += np.roll(np.roll(np.where(known[:, :, None], rgb, 0), dy, 0), dx, 1)
		cnt += np.roll(np.roll(known, dy, 0), dx, 1)
	new = ~known & (cnt > 0)
	rgb[new] = acc[new] / cnt[new][:, None]
	known = known | new
# (the grown colours softened, so no streaks run along the rows)
for _ in range(40):
	soft = (rgb + np.roll(rgb, 2, 0) + np.roll(rgb, -2, 0) + np.roll(rgb, 2, 1) + np.roll(rgb, -2, 1)) / 5
	rgb[grown] = soft[grown]
px[:, :, :3] = rgb
skin.pixels[:] = px.ravel()
skin.filepath_raw = os.path.join(ROOT, f"{FOLDER}_skin.png")
skin.file_format = "PNG"
skin.save()
print(f"SKIN {FOLDER}_skin.png")

# review: the shared body in its new skin wearing the mane; and the old model beside it
bsdf = mat.node_tree.nodes.get("Principled BSDF")
if bsdf:
	mat.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
	bsdf.inputs["Roughness"].default_value = 0.25
for ob in (mane, model):
	ob.hide_render = False
	ob.hide_set(False)
rest.hide_render = True
model.location.x = 1.4
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x, scene.render.resolution_y = 960, 480
scene.world = bpy.data.worlds.new("W")
scene.world.color = (0.75, 0.77, 0.8)
sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
sun.data.energy = 3
sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = 3.0
scene.collection.objects.link(cam)
scene.camera = cam
centre = Vector((0.7, 0, 0.55))
for view, yaw in (("front", 0), ("side", 90), ("back", 180), ("quarter", 35)):
	a = math.radians(yaw)
	d = Vector((math.sin(a), -math.cos(a), 0.12)).normalized()
	cam.location = centre + d * 6
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(REVIEW, f"mane_{view}.png")
	bpy.ops.render.render(write_still=True)
print(f"DONE {FOLDER}")
