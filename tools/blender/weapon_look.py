# A first look at one of the owner's weapon files (a Meshy image-to-3D of a weapon family's tiers, or the Legendary set):
# prints its meshes, triangles, size and big loose parts, and renders it from the front and from above into
# art/models/weapons/review/<name>_front.png and <name>_top.png.
# Run: tools/blender/weapon_look.ps1
import bpy, bmesh, math, os, sys
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1 :]
GLB = ARGS[0]
NAME = os.path.splitext(os.path.basename(GLB))[0]
REVIEW = "C:/Roblox 3rd game/art/models/weapons/review"
os.makedirs(REVIEW, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
scene = bpy.context.scene
meshes = [o for o in scene.objects if o.type == "MESH"]
tris = 0
lo, hi = Vector((1e9, 1e9, 1e9)), Vector((-1e9, -1e9, -1e9))
for o in meshes:
	o.data.calc_loop_triangles()
	tris += len(o.data.loop_triangles)
	for v in o.data.vertices:
		w = o.matrix_world @ v.co
		lo = Vector(map(min, lo, w))
		hi = Vector(map(max, hi, w))
print(f"LOOK {NAME} meshes={len(meshes)} tris={tris} size={tuple(round(x, 3) for x in (hi - lo))}")

# big loose parts (welded), to count the weapons in the file
for o in meshes:
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.00001)
	bm.verts.ensure_lookup_table()
	seen = [False] * len(bm.verts)
	parts = []
	for v in bm.verts:
		if seen[v.index]:
			continue
		stack, group = [v], []
		seen[v.index] = True
		while stack:
			cur = stack.pop()
			group.append(cur)
			for e in cur.link_edges:
				other = e.other_vert(cur)
				if not seen[other.index]:
					seen[other.index] = True
					stack.append(other)
		ws = [o.matrix_world @ g.co for g in group]
		glo, ghi = Vector(map(min, *ws)), Vector(map(max, *ws))
		parts.append((len(group), (glo + ghi) / 2, ghi - glo))
	parts.sort(key=lambda p: -p[0])
	for count, centre, size in parts[:12]:
		print(f"PART {o.name} verts={count} centre={tuple(round(x, 3) for x in centre)} size={tuple(round(x, 3) for x in size)}")
	print(f"PARTS {o.name} {len(parts)} islands")
	bm.free()

scene.render.engine = "BLENDER_EEVEE"
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
centre, span = (lo + hi) / 2, (hi - lo).length
for vname, d, w, h in [("front", Vector((0, -1, 0)), 1600, 900), ("top", Vector((0, -0.001, 1)), 1600, 900)]:
	cam.data.ortho_scale = span * 1.02
	cam.location = centre + d.normalized() * span * 2
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
	cam.data.clip_end = span * 5
	scene.render.resolution_x, scene.render.resolution_y = w, h
	scene.render.filepath = os.path.join(REVIEW, f"{NAME}_{vname}.png")
	bpy.ops.render.render(write_still=True)
print("DONE")
