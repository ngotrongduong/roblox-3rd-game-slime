# Splits the owner's 3D file of one region's monster slimes (an image-to-3D model of the region's group picture,
# art/concepts/monster_slimes/<region>/group.png: five small monsters in a row above the mini-boss and the boss) into one
# object a monster: the welded mesh's loose islands are joined into clusters wherever they touch (a gap wider than GAP
# keeps two monsters apart), the big clusters are given to the monsters by their place in the picture (top row left to
# right, then the bottom row; a monster may be several), small leftovers go with the nearest big cluster, and each
# monster is set on its own ground centre facing -Y (Roblox's front,
# -Z) and scaled to its height in studs (1 Blender metre = 1 stud). Writes <out>/<region>.blend (the seven, the texture
# beside it) and review/<name>_views.png (front, three-quarter, side, back, top) for every monster.
# Run: tools/blender/monster_split.ps1 <glb> <region>
import bpy, bmesh, math, os, sys
from mathutils import Matrix, Vector, kdtree

ARGS = sys.argv[sys.argv.index("--") + 1 :]
GLB, REGION = ARGS[0], ARGS[1]
OUT = os.path.join("C:/Roblox 3rd game/art/models/monster_slimes", REGION)
REVIEW = os.path.join(OUT, "review")
os.makedirs(REVIEW, exist_ok=True)

# the picture's order (top row left to right, then the bottom row) and each monster's height in studs, the same for a
# slot in every region (the Meadow's looks' heights in Config.Dungeon.Looks): swarmer, hunter, spitter, healer,
# armoured, mini-boss, boss
HEIGHTS = [4.4, 3.6, 4.2, 3.8, 4.6, 8, 10]
NAMES = {
	"meadow": ["Burrling", "Stinglob", "Gapebloom", "Sapcaller", "Barkhide", "Rotbloom", "Bramblehorn"],
	"mushroom": ["Gloomtick", "Glimlure", "Bilebloat", "Hexcap", "Ruingut", "Sporegorge", "Hollowheart"],
	"lava": ["Wickling", "Scorchdart", "Blazegullet", "Pyrekeeper", "Basaltback", "Magmaw", "Calderos"],
	"ice": ["Frostnip", "Rimesaw", "Shardspire", "Snowshroud", "Icebound", "Rimetusk", "Frostmaw"],
}
ROSTER = {region: list(zip(names, HEIGHTS)) for region, names in NAMES.items()}
GAP = 0.002  # in the file's own units (it is about 1 wide)

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
for o in list(scene.objects):
	if o != whole:
		bpy.data.objects.remove(o)

# weld the seams, then find the islands
bm = bmesh.new()
bm.from_mesh(whole.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.00001)
bm.verts.ensure_lookup_table()
bm.faces.ensure_lookup_table()
island = [-1] * len(bm.verts)
count = 0
for v in bm.verts:
	if island[v.index] >= 0:
		continue
	stack = [v]
	island[v.index] = count
	while stack:
		x = stack.pop()
		for e in x.link_edges:
			y = e.other_vert(x)
			if island[y.index] < 0:
				island[y.index] = count
				stack.append(y)
	count += 1

# islands that touch (closer than GAP) are one cluster
parent = list(range(count))


def find(a):
	while parent[a] != a:
		parent[a] = parent[parent[a]]
		a = parent[a]
	return a


tree = kdtree.KDTree(len(bm.verts))
for v in bm.verts:
	tree.insert(v.co, v.index)
tree.balance()
for v in bm.verts:
	for _, j, _ in tree.find_range(v.co, GAP):
		a, b = find(island[v.index]), find(island[j])
		if a != b:
			parent[a] = b
cluster_verts = {}
for v in bm.verts:
	cluster_verts.setdefault(find(island[v.index]), []).append(v.index)
clusters = sorted(cluster_verts.values(), key=len, reverse=True)
names = ROSTER[REGION]
print(f"ISLANDS {count} CLUSTERS {len(clusters)} sizes {[len(c) for c in clusters[:12]]}")


def box(idx):
	pts = [bm.verts[i].co for i in idx]
	return Vector(map(min, *pts)), Vector(map(max, *pts))


# A monster may be several big clusters (a crown of branches that does not touch its body), so the big clusters are
# put in the picture's rows by height and in their monster by place along the row: the two rows are two groups of the
# clusters' middles by height, then the top row five and the bottom row two groups by x (weighted 1-D k-means).
MAJOR = 300  # vertices: a cluster at least this big is placed by its middle, a smaller one goes with its nearest
major = [c for c in clusters if len(c) >= MAJOR]
minor = [c for c in clusters if len(c) < MAJOR]
mids = [sum((bm.verts[i].co for i in c), Vector()) / len(c) for c in major]


def kmeans(values, weights, k):
	ordered = sorted(values)
	centres = [ordered[round((j + 0.5) * len(ordered) / k - 0.5)] for j in range(k)]
	for _ in range(50):
		groups = [min(range(k), key=lambda j: abs(v - centres[j])) for v in values]
		for j in range(k):
			w = sum(weights[n] for n in range(len(values)) if groups[n] == j)
			if w:
				centres[j] = sum(values[n] * weights[n] for n in range(len(values)) if groups[n] == j) / w
	return groups, centres


sizes_ = [len(c) for c in major]
rows, row_z = kmeans([m.z for m in mids], sizes_, 2)
upper = max(range(2), key=lambda j: row_z[j])
slot_of = [None] * len(major)
for row, k, base in ((upper, 5, 0), (1 - upper, 2, 5)):
	members = [n for n in range(len(major)) if rows[n] == row]
	groups, centres = kmeans([mids[n].x for n in members], [sizes_[n] for n in members], k)
	rank = sorted(range(k), key=lambda j: centres[j])
	for n, g in zip(members, groups):
		slot_of[n] = base + rank.index(g)
for n, c in enumerate(major):
	lo, hi = box(c)
	print(f"MAJOR verts {len(c)} -> {names[slot_of[n]][0]} lo {tuple(round(x, 3) for x in lo)} hi {tuple(round(x, 3) for x in hi)}")
vert_owner = {}
for n, c in enumerate(major):
	for i in c:
		vert_owner[i] = slot_of[n]
# the small ones with the major cluster nearest to their middle
major_tree = kdtree.KDTree(sum(len(c) for c in major))
for c in major:
	for i in c:
		major_tree.insert(bm.verts[i].co, i)
major_tree.balance()
for c in minor:
	mid = sum((bm.verts[i].co for i in c), Vector()) / len(c)
	_, i, d = major_tree.find(mid)
	for j in c:
		vert_owner[j] = vert_owner[i]
	if d > 0.03:
		print(f"FAR verts {len(c)} at {tuple(round(x, 3) for x in mid)} -> {names[vert_owner[i]][0]}, {d:.4f} away")
bm.to_mesh(whole.data)
bm.free()

# one object a monster
objs = []
for slot, (name, height) in enumerate(names):
	ob = whole.copy()
	ob.data = whole.data.copy()
	ob.name = ob.data.name = name
	scene.collection.objects.link(ob)
	b = bmesh.new()
	b.from_mesh(ob.data)
	b.verts.ensure_lookup_table()
	bmesh.ops.delete(b, geom=[v for v in b.verts if vert_owner.get(v.index) != slot], context="VERTS")
	b.to_mesh(ob.data)
	b.free()
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	s = height / (hi.z - lo.z)
	ob.data.transform(Matrix.Diagonal((s, s, s, 1)) @ Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))))
	ob.data.calc_loop_triangles()
	size = (hi - lo) * s
	print(f"MONSTER {name} tris {len(ob.data.loop_triangles)} size {size.x:.2f} x {size.y:.2f} x {size.z:.2f} (w, d, h)")
	objs.append(ob)
bpy.data.objects.remove(whole)
for k, ob in enumerate(objs):
	ob.location = Vector((k * 12.0, 0, 0))

# the texture beside the .blend
for img in bpy.data.images:
	if img.size[0] > 0:
		img.filepath_raw = os.path.join(OUT, REGION + "_texture.jpg")
		img.file_format = "JPEG"
		img.save()
		print(f"TEXTURE {img.filepath_raw} {img.size[0]}")

# review: five views of each monster, side by side
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 2000
scene.render.resolution_y = 420
world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.9, 0.92, 0.95, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 2.5
sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
scene.collection.objects.link(cam)
scene.camera = cam
VIEWS = [("front", Vector((0, -1, 0.15))), ("34", Vector((0.8, -1, 0.35))), ("side", Vector((1, 0, 0.1))),
	("back", Vector((0, 1, 0.15))), ("top", Vector((0, -0.05, 1)))]
for k, ob in enumerate(objs):
	for o in objs:
		o.hide_render = o != ob
	vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
	lo, hi = Vector(map(min, *vs)), Vector(map(max, *vs))
	centre, span = (lo + hi) / 2, (hi - lo).length
	tiles = []
	for vname, d in VIEWS:
		cam.data.ortho_scale = span * 1.05
		cam.location = centre + d.normalized() * span * 2
		cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
		cam.data.clip_end = span * 5
		scene.render.resolution_x = scene.render.resolution_y = 400
		path = os.path.join(REVIEW, f"_{ob.name}_{vname}.png")
		scene.render.filepath = path
		bpy.ops.render.render(write_still=True)
		tiles.append(path)
	sheet = bpy.data.images.new(ob.name + "_views", 400 * len(tiles), 400)
	px = [0.0] * (400 * len(tiles) * 400 * 4)
	for t, path in enumerate(tiles):
		im = bpy.data.images.load(path)
		src = list(im.pixels)
		for y in range(400):
			row = src[y * 400 * 4 : (y + 1) * 400 * 4]
			start = (y * 400 * len(tiles) + t * 400) * 4
			px[start : start + 400 * 4] = row
		bpy.data.images.remove(im)
		os.remove(path)
	sheet.pixels = px
	sheet.filepath_raw = os.path.join(REVIEW, f"{ob.name}_views.png")
	sheet.file_format = "PNG"
	sheet.save()
for o in objs:
	o.hide_render = False
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, REGION + ".blend"), relative_remap=True)
print("DONE")
