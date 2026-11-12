# Cuts the owner's weapon models (art/models/weapons/source/) into the 30 weapons the slimes hold: each family file has its
# four tiers in a row from wood to Mythic, the Legendary file all six in a 3 x 2 grid. Each weapon becomes one mesh named
# by its gear id, centred on its box (Roblox centres an uploaded mesh anyway), the owner's triangles and texture kept as
# they are (about 1300 triangles a weapon, 2800 a Legendary one: light enough for four on a phone). Writes one FBX a file
# (art/models/weapons/<file>.fbx, uploaded as a Model) and its texture (<file>.png, 1024, uploaded as an image), a review
# picture of the cut pieces (review/kit_<file>.png) and prints one KIT line a weapon with its size in Roblox axes.
# Run: tools/blender/weapon_kit.ps1
import bpy, bmesh, math, os
from mathutils import Vector

ROOT = "C:/Roblox 3rd game/art/models/weapons"
SOURCE = ROOT + "/source"
REVIEW = ROOT + "/review"
os.makedirs(REVIEW, exist_ok=True)
TIERS = ["wood", "iron", "core", "bramble"]
FILES = [
	("sword", "sword"),
	("shield", "shield"),
	("bow", "bow"),
	("crystal_staves", "focus"),
	("druid_stave", "staff"),
	("kit", "kit"),
]
# the Legendary grid (as tools/blender/weapon_icons.py): column by x, row by z in the file's own units
LEGEND = [
	("sword-legend", 0, 1),
	("shield-legend", 1, 1),
	("bow-legend", 2, 1),
	("focus-legend", 0, 0),
	("staff-legend", 1, 0),
	("kit-legend", 2, 0),
]
COLUMNS = [-0.2, 0.17]
ROW_Z = 0.5


def load(name):
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=f"{SOURCE}/{name}.glb")
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
	return whole


def save_texture(whole, name):
	for mat in whole.data.materials:
		if not (mat and mat.use_nodes):
			continue
		for node in mat.node_tree.nodes:
			if node.type == "TEX_IMAGE" and node.image:
				image = node.image
				if image.size[0] > 1024:
					image.scale(1024, 1024)
				image.filepath_raw = f"{ROOT}/{name}.png"
				image.file_format = "PNG"
				image.save()
				return image
	raise RuntimeError(f"{name}: no texture")


def islands(whole):
	# each welded island: its vertex list's centre and x extent
	bm = bmesh.new()
	bm.from_mesh(whole.data)
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.00001)
	bm.verts.ensure_lookup_table()
	island = [-1] * len(bm.verts)
	boxes = []
	for v in bm.verts:
		if island[v.index] >= 0:
			continue
		index = len(boxes)
		stack, members = [v], []
		island[v.index] = index
		while stack:
			cur = stack.pop()
			members.append(cur)
			for e in cur.link_edges:
				other = e.other_vert(cur)
				if island[other.index] < 0:
					island[other.index] = index
					stack.append(other)
		lo = Vector(map(min, *[m.co for m in members])) if len(members) > 1 else members[0].co.copy()
		hi = Vector(map(max, *[m.co for m in members])) if len(members) > 1 else members[0].co.copy()
		boxes.append((lo, hi, len(members)))
	bm.to_mesh(whole.data)
	bm.free()
	return island, boxes


def row_groups(boxes, count):
	# islands whose x extents overlap belong to one weapon; the groups, left to right, merged down to `count`
	order = sorted(range(len(boxes)), key=lambda i: boxes[i][0].x)
	groups = []
	for i in order:
		lo, hi = boxes[i][0].x, boxes[i][1].x
		if groups and lo <= groups[-1]["hi"]:
			groups[-1]["hi"] = max(groups[-1]["hi"], hi)
			groups[-1]["members"].append(i)
		else:
			groups.append({"lo": lo, "hi": hi, "members": [i]})
	while len(groups) > count:
		# the narrowest gap closes first
		gaps = [groups[k + 1]["lo"] - groups[k]["hi"] for k in range(len(groups) - 1)]
		k = gaps.index(min(gaps))
		groups[k]["hi"] = groups[k + 1]["hi"]
		groups[k]["members"] += groups[k + 1]["members"]
		del groups[k + 1]
	if len(groups) != count:
		raise RuntimeError(f"found {len(groups)} weapons, wanted {count}")
	which = {}
	for g, group in enumerate(groups):
		for i in group["members"]:
			which[i] = g
	return which


def cut(whole, keep, name):
	piece = whole.copy()
	piece.data = whole.data.copy()
	piece.name = piece.data.name = name
	bpy.context.scene.collection.objects.link(piece)
	bm = bmesh.new()
	bm.from_mesh(piece.data)
	bm.verts.ensure_lookup_table()
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep(v.index)], context="VERTS")
	lo = Vector(map(min, *[v.co for v in bm.verts]))
	hi = Vector(map(max, *[v.co for v in bm.verts]))
	centre = (lo + hi) / 2
	for v in bm.verts:
		v.co -= centre
	tris = sum(len(f.verts) - 2 for f in bm.faces)
	bm.to_mesh(piece.data)
	bm.free()
	piece.location = (0, 0, 0)
	size = hi - lo
	# (the FBX export turns Blender (x, y, z) into Roblox (-x, z, y))
	print(f"KIT {name} tris={tris} size={round(size.x, 4)} {round(size.z, 4)} {round(size.y, 4)}")
	return piece, size


def review(pieces, name):
	scene = bpy.context.scene
	widest = max(size.x for _, size in pieces) * 1.25
	tallest = max(size.z for _, size in pieces)
	for i, (piece, _) in enumerate(pieces):
		piece.location = (i * widest, 0, 0)
	scene.render.engine = "BLENDER_EEVEE"
	scene.render.resolution_x, scene.render.resolution_y = 1600, 600
	world = bpy.data.worlds.new("w")
	scene.world = world
	world.use_nodes = True
	world.node_tree.nodes["Background"].inputs[0].default_value = (0.9, 0.92, 0.95, 1)
	world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
	sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
	sun.data.energy = 2.5
	sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
	scene.collection.objects.link(sun)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	cam.data.type = "ORTHO"
	scene.collection.objects.link(cam)
	scene.camera = cam
	span = widest * len(pieces)
	cam.data.ortho_scale = max(span, tallest * 1600 / 600) * 1.02
	cam.location = Vector(((len(pieces) - 1) * widest / 2, -10, 0))
	cam.rotation_euler = (math.radians(90), 0, 0)
	cam.data.clip_end = 30
	scene.render.filepath = f"{REVIEW}/kit_{name}.png"
	bpy.ops.render.render(write_still=True)
	for piece, _ in pieces:
		piece.location = (0, 0, 0)
	bpy.data.objects.remove(sun)
	bpy.data.objects.remove(cam)


def export(pieces, name):
	bpy.ops.object.select_all(action="DESELECT")
	for piece, _ in pieces:
		piece.select_set(True)
	bpy.context.view_layer.objects.active = pieces[0][0]
	bpy.ops.export_scene.fbx(filepath=f"{ROOT}/{name}.fbx", use_selection=True, object_types={"MESH"},
		axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True,
		use_space_transform=True, bake_space_transform=False, mesh_smooth_type="FACE", use_mesh_modifiers=False,
		use_tspace=False, path_mode="AUTO", embed_textures=False)
	print(f"FBX {name}.fbx")


for file, family in FILES:
	whole = load(file)
	save_texture(whole, file)
	island, boxes = islands(whole)
	which = row_groups(boxes, 4)
	pieces = []
	for g, tier in enumerate(TIERS):
		pieces.append(cut(whole, lambda i, g=g: which[island[i]] == g, f"{family}-{tier}"))
	bpy.data.objects.remove(whole)
	review(pieces, file)
	export(pieces, file)

whole = load("legendary")
save_texture(whole, "legendary")
island, boxes = islands(whole)


def cell_of(i):
	lo, hi, _ = boxes[island[i]]
	c = (lo + hi) / 2
	column = 0 if c.x < COLUMNS[0] else (1 if c.x < COLUMNS[1] else 2)
	return column, 1 if c.z > ROW_Z else 0


pieces = [cut(whole, lambda i, col=col, row=row: cell_of(i) == (col, row), name) for name, col, row in LEGEND]
bpy.data.objects.remove(whole)
review(pieces, "legendary")
export(pieces, "legendary")
print("DONE")
