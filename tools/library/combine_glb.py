# Packs every GLB of a folder into ONE GLB, each prop a separate object named after its file and set apart in a row, so the
# owner brings a whole set into Studio with a single File > Import 3D (Open Cloud upload needs an approved folder, which a
# local place cannot set). Each object becomes its own MeshPart with its own mesh id.
#   blender -b --factory-startup -P tools/library/combine_glb.py -- <folder> <out.glb>
import os
import sys

import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
in_dir, out_path = args[0], args[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
x = 0.0
for name in sorted(os.listdir(in_dir)):
	if not name.endswith(".glb"):
		continue
	before = set(bpy.data.objects)
	bpy.ops.import_scene.gltf(filepath=os.path.join(in_dir, name))
	meshes = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
	for o in bpy.data.objects:
		if o not in before and o.type != "MESH":
			bpy.data.objects.remove(o)
	ob = meshes[0]
	ob.name = name[:-4]
	ob.data.name = name[:-4]
	ob.parent = None
	width = ob.dimensions.x
	ob.location = (x + width / 2, 0, 0)
	x += width + 2
	print("ADD", ob.name, "tris", sum(len(p.vertices) - 2 for p in ob.data.polygons))

bpy.ops.export_scene.gltf(
	filepath=out_path,
	export_format="GLB",
	export_active_vertex_color_when_no_material=True,
	export_vertex_color="ACTIVE",
)
print("WROTE", out_path, os.path.getsize(out_path))
