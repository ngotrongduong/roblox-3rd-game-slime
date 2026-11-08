# Blender headless: every .fbx in IN_DIR -> one small .glb in OUT_DIR whose colours are VERTEX colours (the flat-colour
# Quaternius packs paint with one material per colour: Roblox keeps vertex colours, not material colours), and a small
# preview picture in OUT_DIR/preview. Prints the triangle count. Run by take_fbx.ps1.
import json
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
in_dir, out_dir = args[0], args[1]
os.makedirs(out_dir, exist_ok=True)
prev_dir = os.path.join(out_dir, "preview")
os.makedirs(prev_dir, exist_ok=True)


def srgb_to_linear(c):
	return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


# The Ultimate Nature Pack's material names -> the painting's colours (sRGB hex)
PALETTE = {
	"DarkGreen": "#3f9a2a",
	"Green": "#74c63a",
	"Wood": "#7b4c2c",
	"LightWood": "#c08f5c",
	"Rock": "#aaa8a4",
	"Berry": "#e8425e",
	"Cyan": "#4f8fe8",
	"Yellow": "#f6d03c",
	"White": "#ece8da",
	"Black": "#4a3d36",
	"Mushroom_Top": "#d9503f",
	"Mushroom_Bottom": "#f2e8d2",
}
# a colour variant of the same props (the flower clumps): OVERRIDE='{"Cyan":"#ee7fb0"}' SUFFIX=_Pink
PALETTE.update(json.loads(os.environ.get("OVERRIDE", "{}")))
SUFFIX = os.environ.get("SUFFIX", "")
# a prop heavier than this many triangles is collapsed down to it (tools/library/fbx_to_glb.py: trees)
MAX_TRIS = int(os.environ.get("MAX_TRIS", "600"))


for name in sorted(os.listdir(in_dir)):
	if not name.endswith(".fbx"):
		continue
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.fbx(filepath=os.path.join(in_dir, name))
	meshes = [o for o in bpy.data.objects if o.type == "MESH"]
	# one object, transforms applied, triangulated
	for o in bpy.data.objects:
		o.select_set(False)
	for o in meshes:
		o.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	if len(meshes) > 1:
		bpy.ops.object.join()
	ob = bpy.context.view_layer.objects.active
	me = ob.data
	# a vertex colour per face corner from the face's material (by its name: the pack's muted palette becomes the game's
	# bright cozy one; a name not listed keeps its own colour)
	attr = me.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="CORNER")
	cols = []
	for slot in ob.material_slots:
		m = slot.material
		c = (0.8, 0.8, 0.8, 1.0)
		if m:
			c = tuple(m.diffuse_color)
			if m.node_tree:
				for n in m.node_tree.nodes:
					if n.type == "BSDF_PRINCIPLED":
						c = tuple(n.inputs["Base Color"].default_value)
						break
			if m.name.split(".")[0] in PALETTE:
				h = PALETTE[m.name.split(".")[0]]
				c = tuple(srgb_to_linear(int(h[i : i + 2], 16) / 255) for i in (1, 3, 5)) + (1.0,)
		cols.append(c)
	for poly in me.polygons:
		c = cols[poly.material_index] if poly.material_index < len(cols) else (0.8, 0.8, 0.8, 1)
		for li in poly.loop_indices:
			attr.data[li].color = c
	# drop the materials but one plain material that shows the colour attribute
	me.materials.clear()
	mat = bpy.data.materials.new("Flat")
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
	vc = nodes.new("ShaderNodeVertexColor")
	vc.layer_name = "Col"
	mat.node_tree.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
	bsdf.inputs["Metallic"].default_value = 0.0
	bsdf.inputs["Roughness"].default_value = 0.8
	me.materials.append(mat)
	tris = sum(len(p.vertices) - 2 for p in me.polygons)
	if tris > MAX_TRIS:
		mod = ob.modifiers.new("Decimate", "DECIMATE")
		mod.ratio = MAX_TRIS / tris
		mod.use_collapse_triangulate = True
		bpy.ops.object.modifier_apply(modifier="Decimate")
		me = ob.data
		tris = sum(len(p.vertices) - 2 for p in me.polygons)
	# the origin at the middle of the foot, so a model's pivot is where it stands
	lo = Vector((min(v.co.x for v in me.vertices), min(v.co.y for v in me.vertices), min(v.co.z for v in me.vertices)))
	hi = Vector((max(v.co.x for v in me.vertices), max(v.co.y for v in me.vertices), max(v.co.z for v in me.vertices)))
	for v in me.vertices:
		v.co -= Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
	dims = ob.dimensions
	name = name[:-4] + SUFFIX + ".fbx"
	out = os.path.join(out_dir, name[:-4] + ".glb")
	bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_active_vertex_color_when_no_material=True, export_vertex_color="ACTIVE")
	print("GLB", name[:-4], "tris", tris, "dims %.2f %.2f %.2f" % (dims.x, dims.y, dims.z), "bytes", os.path.getsize(out))
	# preview: a camera three-quarter above, vertex colours shown flat-lit
	scene = bpy.context.scene
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "VERTEX"
	scene.render.resolution_x = 256
	scene.render.resolution_y = 256
	scene.render.film_transparent = False
	scene.world = bpy.data.worlds.new("W")
	scene.world.color = (0.62, 0.8, 0.95)
	size = max(dims.x, dims.y, dims.z)
	cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
	scene.collection.objects.link(cam)
	scene.camera = cam
	mid = Vector((0, 0, dims.z / 2))
	cam.location = mid + Vector((1.5, -2.0, 1.1)).normalized() * size * 2.4
	direction = mid - cam.location
	cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(prev_dir, name[:-4] + ".png")
	bpy.ops.render.render(write_still=True)
