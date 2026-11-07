# Blender headless: every .gltf in IN_DIR -> one small self-contained .glb in OUT_DIR, made for cheap phones:
# only the base colour is kept (normal and ORM maps dropped), every picture shrunk to at most 512 px.
# A megakit prop goes from about 15-25 MB (three 2048 px sheets) to 25-270 KB. Run by take_props.ps1.
import os
import sys

import bpy

MAX = 512
args = sys.argv[sys.argv.index("--") + 1 :]
in_dir, out_dir = args[0], args[1]
os.makedirs(out_dir, exist_ok=True)
for name in sorted(os.listdir(in_dir)):
	if not name.endswith(".gltf"):
		continue
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=os.path.join(in_dir, name))
	for mat in bpy.data.materials:
		if not mat.node_tree:
			continue
		nodes = mat.node_tree.nodes
		bsdf = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
		if not bsdf:
			continue
		keep = {link.from_node.name for link in bsdf.inputs["Base Color"].links}
		for n in list(nodes):
			if (n.type == "TEX_IMAGE" and n.name not in keep) or n.type in ("NORMAL_MAP", "SEPARATE_COLOR"):
				nodes.remove(n)
		# light, not painted: the game's light shades the prop (memory light-not-painted)
		bsdf.inputs["Metallic"].default_value = 0.0
		bsdf.inputs["Roughness"].default_value = 0.7
	for img in bpy.data.images:
		if img.size[0] > MAX:
			img.scale(MAX, max(1, round(img.size[1] * MAX / img.size[0])))
	out = os.path.join(out_dir, name[:-5] + ".glb")
	bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="JPEG")
	faces = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
	print("GLB", name[:-5], "faces", faces, "bytes", os.path.getsize(out))
