# Reads each exported FBX back WITHOUT axis conversion, so the numbers are the file's own axes (Y up, as Roblox reads them).
import bpy

OUT = "C:/Roblox 3rd game/art/models/granary/blender/"
for name in ("ConeRoof", "Balustrade", "Pipe", "Gear", "Column"):
	for ob in list(bpy.data.objects):
		bpy.data.objects.remove(ob, do_unlink=True)
	bpy.ops.import_scene.fbx(filepath=OUT + name + ".fbx", use_manual_orientation=True, axis_forward="Y", axis_up="Z",
		global_scale=1.0)
	for ob in bpy.data.objects:
		if ob.type == "MESH":
			bpy.context.view_layer.update()
			w = [ob.matrix_world @ v.co for v in ob.data.vertices]
			size = [round(max(p[i] for p in w) - min(p[i] for p in w), 3) for i in range(3)]
			print("[axes]", name, ob.name, size, "bbox of vertices with node transforms, file axes x,y(up),z; rot",
				[round(a, 2) for a in ob.rotation_euler])
