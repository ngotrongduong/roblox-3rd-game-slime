# Looks into the owner's accessory file before a kit is written for it (skill slime-wear): renders it from six sides
# into <out>, then splits it into loose bits the way wear_kit.py does (seams welded) and prints each bit's size and
# middle, which is what a kit's `sort` reads. Blender axes as the file comes in (Z up).
# Run: tools/blender/wear_inspect.ps1 <file.glb> [out folder]
import bpy, math, os, sys
from mathutils import Vector

GLB, OUT = sys.argv[sys.argv.index("--") + 1 :][:2]
os.makedirs(OUT, exist_ok=True)


def r3(v):
	return tuple(round(c, 3) for c in v)


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
for img in bpy.data.images:
	print(f"IMG {img.name} size={tuple(img.size)}")
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
# (wear_kit.py reads only the first mesh of a file)
print(f"FILE meshes={len(meshes)}" + ("  <- wear_kit.py reads only the first: join them first" if len(meshes) > 1 else ""))
pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
print(f"ALL lo={r3(lo)} hi={r3(hi)}")

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 640
scene.render.resolution_y = 640
world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.82, 0.86, 0.9, 1)
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3
sun.rotation_euler = (math.radians(50), 0, math.radians(30))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
size = max(hi - lo)
cam.data.ortho_scale = size * 1.15
scene.collection.objects.link(cam)
scene.camera = cam
centre = (lo + hi) / 2
views = {
	"front": Vector((0, -1, 0)),
	"back": Vector((0, 1, 0)),
	"left": Vector((-1, 0, 0)),
	"right": Vector((1, 0, 0)),
	"top": Vector((0, 0.001, 1)),
	"persp": Vector((0.7, -0.7, 0.5)),
}
for name, d in views.items():
	cam.location = centre + d.normalized() * size * 3
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(OUT, f"{name}.png")
	bpy.ops.render.render(write_still=True)

# the loose bits, as wear_kit.py splits them
bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
	o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
	bpy.ops.object.join()
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
bits = []
for o in [o for o in bpy.data.objects if o.type == "MESH"]:
	vs = [o.matrix_world @ v.co for v in o.data.vertices]
	o.data.calc_loop_triangles()
	b_lo = Vector((min(p.x for p in vs), min(p.y for p in vs), min(p.z for p in vs)))
	b_hi = Vector((max(p.x for p in vs), max(p.y for p in vs), max(p.z for p in vs)))
	bits.append((sum(vs, Vector()) / len(vs), len(o.data.loop_triangles), b_lo, b_hi))
bits.sort(key=lambda b: (round(b[0].x, 2), b[0].z))
print(f"BITS {len(bits)} loose bits, by their middle's x")
for c, tris, b_lo, b_hi in bits:
	print(f"BIT middle={r3(c)} tris={tris} lo={r3(b_lo)} hi={r3(b_hi)}")
print(f"DONE renders in {OUT}")
