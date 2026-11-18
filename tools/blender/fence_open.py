# The owner's fence sections with an end post cut off, so a run of them never shows two posts side by side.
#   blender -b --factory-startup -P tools/blender/fence_open.py -- art/models/village_props/fence
# Writes beside each <name>.glb: <name>_open.glb without its +x post, <name>_bare.glb without either post. The cut is
# the plane at KEEP of the length from the mesh's -x end (glTF mesh space): the inner face of its +x post, found on each
# model's height profile (the post is the tall part at the end; KEEP is where the low infill starts); the -x post's
# inner face is the same share from the other end. In the game the mesh's +x end stands at the section's start (the
# file's half turn, the import's and LibraryKit's), so an open section keeps the post at its end and every run is open
# sections; a run that ends at a gate ends with the bare one, the gate's own end post standing where its post would be.
import bmesh
import bpy
import os
import sys

KEEP = {
    "fence_rail": 0.80,
    "fence_picket": 0.82,
    "fence_stone": 0.76,
    "fence_iron": 0.80,
    "fence_royal": 0.78,
}

folder = sys.argv[sys.argv.index("--") + 1]
for key, keep in KEEP.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(folder, key + ".glb"))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for o in meshes:
        xs = [v.co.x for v in o.data.vertices]
        x0, x1 = min(xs), max(xs)
        cut = x0 + (x1 - x0) * keep
        bm = bmesh.new()
        bm.from_mesh(o.data)
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(cut, 0, 0), plane_no=(1, 0, 0), clear_outer=True)
        bm.to_mesh(o.data)
        bm.free()
        o.data.update()
        print("OPEN", key, o.name, "x", round(x0, 4), round(x1, 4), "cut", round(cut, 4), "faces", len(o.data.polygons))
    out = os.path.join(folder, key + "_open.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print("WROTE", out, os.path.getsize(out))
    for o in meshes:
        xs = [v.co.x for v in o.data.vertices]
        x0, x1 = min(xs), max(xs)
        # (x1 is the +x cut now: the -x post's inner face is the same share of the whole length from x0)
        cut = x0 + (x1 - x0) * (1 - keep) / keep
        bm = bmesh.new()
        bm.from_mesh(o.data)
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(cut, 0, 0), plane_no=(-1, 0, 0), clear_outer=True)
        bm.to_mesh(o.data)
        bm.free()
        o.data.update()
        print("BARE", key, o.name, "x", round(x0, 4), round(x1, 4), "cut", round(cut, 4), "faces", len(o.data.polygons))
    out = os.path.join(folder, key + "_bare.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print("WROTE", out, os.path.getsize(out))
