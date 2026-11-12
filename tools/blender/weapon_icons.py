# Renders the owner's Legendary weapon set (art/models/weapons/source/legendary.glb: six weapons in a 3 x 2 grid, top row
# sword, shield, bow; bottom row focus, staff, kit) one weapon at a time, on a transparent background, the long ones
# turned to lie corner to corner like the Smithy's other weapon pictures. Writes art/models/weapons/review/icon_<id>.png
# (512 px); tools/blender/weapon_icons_finish.py trims them, draws the dark outline and writes art/icons/weapons/.
# Run: tools/blender/weapon_icons.ps1
import bpy, bmesh, math, os
from mathutils import Vector

GLB = "C:/Roblox 3rd game/art/models/weapons/source/legendary.glb"
OUT = "C:/Roblox 3rd game/art/models/weapons/review"
# (column by x, row by z in the file's own units; the turn about the view axis in degrees)
CELLS = [
	("sword-legend", 0, 1, 45),
	("shield-legend", 1, 1, 0),
	("bow-legend", 2, 1, 0),
	("focus-legend", 0, 0, 45),
	("staff-legend", 1, 0, 45),
	("kit-legend", 2, 0, 0),
]
COLUMNS = [-0.2, 0.17]  # x borders between the three columns
ROW_Z = 0.5  # z border between the two rows

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


def cell_of(p):
	column = 0 if p.x < COLUMNS[0] else (1 if p.x < COLUMNS[1] else 2)
	row = 1 if p.z > ROW_Z else 0
	return column, row


# each welded island goes to the cell its centre stands in
bm = bmesh.new()
bm.from_mesh(whole.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.00001)
bm.verts.ensure_lookup_table()
island = [-1] * len(bm.verts)
centres = []
for v in bm.verts:
	if island[v.index] >= 0:
		continue
	index = len(centres)
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
	centres.append((lo + hi) / 2)
bm.to_mesh(whole.data)
bm.free()

scene.render.engine = "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 512
scene.view_settings.view_transform = "Standard"
world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.55
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 2.4
sun.rotation_euler = (math.radians(40), math.radians(-20), math.radians(-25))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
scene.collection.objects.link(cam)
scene.camera = cam

for name, column, row, turn in CELLS:
	piece = whole.copy()
	piece.data = whole.data.copy()
	scene.collection.objects.link(piece)
	bm = bmesh.new()
	bm.from_mesh(piece.data)
	bm.verts.ensure_lookup_table()
	drop = [v for v in bm.verts if cell_of(centres[island[v.index]]) != (column, row)]
	bmesh.ops.delete(bm, geom=drop, context="VERTS")
	bm.to_mesh(piece.data)
	bm.free()
	whole.hide_render = True
	# (a copy made after the first carries the hidden flag of the whole)
	piece.hide_render = False
	# turn it about the view axis (Y, the camera looks along +Y) so a long weapon lies corner to corner
	# (the glTF import leaves objects on quaternions, where rotation_euler does nothing)
	piece.rotation_mode = "XYZ"
	piece.rotation_euler = (0, math.radians(turn), 0)
	bpy.context.view_layer.update()
	vs = [piece.matrix_world @ v.co for v in piece.data.vertices]
	lo, hi = Vector(map(min, *vs)), Vector(map(max, *vs))
	centre, size = (lo + hi) / 2, hi - lo
	cam.data.ortho_scale = max(size.x, size.z) * 1.08
	cam.location = centre + Vector((0, -2, 0))
	cam.rotation_euler = (math.radians(90), 0, 0)
	cam.data.clip_end = 5
	scene.render.filepath = os.path.join(OUT, f"icon_{name}.png")
	bpy.ops.render.render(write_still=True)
	print(f"ICON {name} verts={len(piece.data.vertices)} size={tuple(round(x, 3) for x in size)}")
	bpy.data.objects.remove(piece)
print("DONE")
