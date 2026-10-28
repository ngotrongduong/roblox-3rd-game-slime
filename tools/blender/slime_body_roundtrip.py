# Round-trip check of the slime body exports: imports each FBX into an empty scene and reports what arrived
# (meshes, triangles, bones and their heads, influences per vertex, weight sums, custom normals, height).
#   blender -b --factory-startup -P tools/blender/slime_body_roundtrip.py
import bpy
import json

OUT = "C:/Roblox 3rd game/art/models/slime_body/"
report = {}
for fn in ("SlimeBody.fbx", "SlimeBodyOutline.fbx"):
	for ob in list(bpy.data.objects):
		bpy.data.objects.remove(ob, do_unlink=True)
	bpy.ops.import_scene.fbx(filepath=OUT + fn)
	r = {"objects": [(o.name, o.type) for o in bpy.data.objects]}
	for o in bpy.data.objects:
		if o.type == "ARMATURE":
			r["bones"] = {b.name: [round(c, 4) for c in (o.matrix_world @ b.head_local)] for b in o.data.bones}
			r["bone_parents"] = {b.name: (b.parent.name if b.parent else None) for b in o.data.bones}
		if o.type == "MESH":
			me = o.data
			r["mesh"] = o.name
			r["tris"] = sum(len(p.vertices) - 2 for p in me.polygons)
			r["verts"] = len(me.vertices)
			infl = [len([g for g in v.groups if g.weight > 1e-5]) for v in me.vertices]
			sums = [sum(g.weight for g in v.groups) for v in me.vertices]
			r["max_influences"] = max(infl)
			r["weight_sum_range"] = [round(min(sums), 4), round(max(sums), 4)]
			r["groups"] = [g.name for g in o.vertex_groups]
			r["has_custom_normals"] = me.has_custom_normals
			zs = [(o.matrix_world @ v.co).z for v in me.vertices]
			r["height"] = round(max(zs) - min(zs), 4)
			r["min_z"] = round(min(zs), 4)
			r["uv_layers"] = [u.name for u in me.uv_layers]
	report[fn] = r
print("[roundtrip]", json.dumps(report, indent=1))
with open(OUT + "review/roundtrip.json", "w") as f:
	json.dump(report, f, indent=1)
