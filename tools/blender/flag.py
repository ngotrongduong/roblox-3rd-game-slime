# The waving flag (the owner, 2026-11-03: "thin, flying softly like a real flag"): a wooden pole with a gold finial and
# a thin two-sided cloth on a chain of bones along its length, which the client bends (client/FlagWave). The cloth's
# picture is made here from the owner's own sword art (reference/goo-lineage-web/assets/equip-sword.png, untouched,
# only scaled and mirrored into a crossed pair). Run: tools/blender/flag.ps1. Out: art/models/flag/.
import os

import bpy
import numpy as np
from mathutils import Vector

ROOT = "C:/Roblox 3rd game/"
OUT = ROOT + "art/models/flag/"
SWORD = ROOT + "reference/goo-lineage-web/assets/equip-sword.png"

POLE_H = 10.0  # pole height (Blender units = studs after import, scaled again when placed)
POLE_R = 0.13
CLOTH_W = 4.8  # along the wind
CLOTH_H = 3.0
COLS, ROWS = 24, 10
BONES = 8  # Bone0 at the pole edge ... Bone7 near the free end
TEX_W, TEX_H = 1024, 640


def reset_scene():
	for ob in list(bpy.data.objects):
		bpy.data.objects.remove(ob, do_unlink=True)
	for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.images, bpy.data.cameras, bpy.data.lights):
		for d in list(coll):
			coll.remove(d)


def rgb(h):
	return np.array([int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)] + [1.0])


def make_texture():
	img = np.zeros((TEX_H, TEX_W, 4))  # row 0 = the top of the picture (flipped when written)
	img[:, :] = rgb("C23B30")  # the red field
	cream, gold, gold_dark = rgb("F4E4C4"), rgb("E6B43C"), rgb("A87A22")
	band, line = 34, 8
	img[:band] = cream
	img[-band:] = cream
	img[band : band + line] = gold
	img[-band - line : -band] = gold
	hoist = 80
	img[:, :hoist] = gold
	img[:, hoist - 10 : hoist] = gold_dark
	# the crossed swords: the owner's sword and its mirror, alpha over the field
	s = bpy.data.images.load(SWORD)
	size = 430
	s.scale(size, size)
	px = np.array(s.pixels[:]).reshape(size, size, 4)[::-1]  # Blender rows are bottom-up
	cx = hoist + (TEX_W - hoist) // 2
	# (each sword moved out by apart so the blades cross at their middle, not at the guards)
	apart = 78
	cy = TEX_H // 2 + apart // 2
	for art, dx in ((px, -apart), (px[:, ::-1], apart)):
		y0, x0 = cy - size // 2, cx - size // 2 + dx
		dst = img[y0 : y0 + size, x0 : x0 + size]
		a = art[:, :, 3:4]
		dst[:, :, :3] = art[:, :, :3] * a + dst[:, :, :3] * (1 - a)
	bpy.data.images.remove(s)
	out = bpy.data.images.new("FlagCloth", TEX_W, TEX_H, alpha=False)
	out.pixels[:] = img[::-1].ravel()
	out.filepath_raw = OUT + "FlagCloth.png"
	out.file_format = "PNG"
	out.save()
	return out


def material(name, colour, image=None):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	bsdf = m.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = colour
	bsdf.inputs["Roughness"].default_value = 0.8
	if image:
		tex = m.node_tree.nodes.new("ShaderNodeTexImage")
		tex.image = image
		m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
	return m


def mesh_object(name, verts, faces, uvs=None, mat=None):
	me = bpy.data.meshes.new(name)
	me.from_pydata(verts, [], faces)
	if uvs:
		layer = me.uv_layers.new(name="UVMap")
		for poly in me.polygons:
			for li in poly.loop_indices:
				layer.data[li].uv = uvs[me.loops[li].vertex_index]
	me.update()
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	if mat:
		me.materials.append(mat)
	return ob


def lathe(name, profile, sides, mat):
	# profile: (radius, z) from bottom to top; a closed solid of revolution
	verts, faces = [], []
	for r, z in profile:
		for i in range(sides):
			a = 2 * np.pi * i / sides
			verts.append((r * np.cos(a), r * np.sin(a), z))
	for j in range(len(profile) - 1):
		for i in range(sides):
			a, b = j * sides + i, j * sides + (i + 1) % sides
			faces.append((a, b, b + sides, a + sides))
	verts.append((0, 0, profile[0][1]))
	verts.append((0, 0, profile[-1][1]))
	bot, top, last = len(verts) - 2, len(verts) - 1, (len(profile) - 1) * sides
	for i in range(sides):
		faces.append((bot, (i + 1) % sides, i))
		faces.append((top, last + i, last + (i + 1) % sides))
	ob = mesh_object(name, verts, faces, mat=mat)
	for p in ob.data.polygons:
		p.use_smooth = True
	return ob


def build_pole():
	wood = material("Wood", (0.32, 0.19, 0.09, 1))
	gold = material("Gold", (0.9, 0.68, 0.2, 1))
	r = POLE_R
	pole = lathe("Pole", [(r * 2.6, 0), (r * 2.6, 0.25), (r * 1.6, 0.45), (r * 1.15, 0.6), (r, 1.0), (r * 0.9, POLE_H)], 10, wood)
	ball = [(0.001, POLE_H)]
	for k in range(1, 8):
		t = np.pi * k / 8
		ball.append((0.26 * np.sin(t), POLE_H + 0.06 + 0.26 * (1 - np.cos(t))))
	ball.append((0.001, POLE_H + 0.58))
	finial = lathe("Finial", [(r * 1.4, POLE_H - 0.12)] + ball[1:], 10, gold)
	return pole, finial


def build_cloth(image):
	z_top = POLE_H - 0.25
	x0 = POLE_R * 0.9
	verts, uvs, faces = [], [], []
	for side, dy in ((0, 0.004), (1, -0.004)):  # two faces back to back: thin, seen from both sides
		base = len(verts)
		for j in range(ROWS + 1):
			for i in range(COLS + 1):
				u, v = i / COLS, j / ROWS
				verts.append((x0 + u * CLOTH_W, dy, z_top - CLOTH_H + v * CLOTH_H))
				uvs.append((u, v))
		for j in range(ROWS):
			for i in range(COLS):
				a = base + j * (COLS + 1) + i
				q = (a, a + 1, a + COLS + 2, a + COLS + 1)
				faces.append(q if side == 0 else tuple(reversed(q)))
	cloth = mesh_object("FlagCloth", verts, faces, uvs, material("Cloth", (1, 1, 1, 1), image))
	for p in cloth.data.polygons:
		p.use_smooth = True

	# the bone chain along the middle of the cloth, each bone the parent of the next
	zm = z_top - CLOTH_H / 2
	seg = CLOTH_W / BONES
	ad = bpy.data.armatures.new("FlagRig")
	arm = bpy.data.objects.new("FlagRig", ad)
	bpy.context.scene.collection.objects.link(arm)
	bpy.context.view_layer.objects.active = arm
	bpy.ops.object.mode_set(mode="EDIT")
	prev = None
	for k in range(BONES):
		eb = ad.edit_bones.new("Flag%d" % k)
		eb.head = Vector((x0 + k * seg, 0, zm))
		eb.tail = Vector((x0 + (k + 1) * seg, 0, zm))
		eb.roll = 0
		if prev:
			eb.parent = prev
			eb.use_connect = True
		prev = eb
	bpy.ops.object.mode_set(mode="OBJECT")

	# weights: a point between bone k's head and the next head blends k into k+1, so the bends stay soft
	groups = [cloth.vertex_groups.new(name="Flag%d" % k) for k in range(BONES)]
	for v in cloth.data.vertices:
		t = (v.co.x - x0) / seg
		k = min(int(t), BONES - 1)
		f = min(max(t - k, 0.0), 1.0)
		if k + 1 < BONES:
			groups[k].add([v.index], 1 - f, "REPLACE")
			groups[k + 1].add([v.index], f, "REPLACE")
		else:
			groups[k].add([v.index], 1.0, "REPLACE")
	cloth.parent = arm
	mod = cloth.modifiers.new("Armature", "ARMATURE")
	mod.object = arm
	return cloth, arm


def preview(arm):
	# a still of a wave, to look at before importing
	bpy.context.view_layer.objects.active = arm
	bpy.ops.object.mode_set(mode="POSE")
	for k, pb in enumerate(arm.pose.bones):
		pb.rotation_mode = "XYZ"
		pb.rotation_euler = (0, 0, 0.32 * np.sin(k * 0.9) if k else 0.25)
	bpy.ops.object.mode_set(mode="OBJECT")
	scene = bpy.context.scene
	cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
	scene.collection.objects.link(cam)
	cam.location = (4.5, -12, 7.5)
	cam.rotation_euler = (np.radians(84), 0, np.radians(14))
	scene.camera = cam
	sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
	scene.collection.objects.link(sun)
	sun.rotation_euler = (np.radians(40), np.radians(20), np.radians(30))
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.color_type = "TEXTURE"
	scene.display.shading.light = "STUDIO"
	scene.render.resolution_x, scene.render.resolution_y = 900, 900
	scene.render.filepath = OUT + "preview.png"
	bpy.ops.render.render(write_still=True)
	bpy.data.objects.remove(cam)
	bpy.data.objects.remove(sun)
	bpy.context.view_layer.objects.active = arm
	bpy.ops.object.mode_set(mode="POSE")
	for pb in arm.pose.bones:
		pb.rotation_euler = (0, 0, 0)
	bpy.ops.object.mode_set(mode="OBJECT")


def export(cloth, arm, pole, finial):
	fbx = dict(use_selection=True, object_types={"ARMATURE", "MESH"}, axis_forward="-Z", axis_up="Y",
		apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True,
		bake_space_transform=False, add_leaf_bones=False, primary_bone_axis="Y", secondary_bone_axis="X",
		use_armature_deform_only=False, bake_anim=False, mesh_smooth_type="FACE", use_mesh_modifiers=False,
		use_tspace=False, path_mode="COPY", embed_textures=True)
	bpy.ops.object.select_all(action="DESELECT")
	for ob in (arm, cloth, pole, finial):
		ob.select_set(True)
	bpy.context.view_layer.objects.active = arm
	bpy.ops.export_scene.fbx(filepath=OUT + "WavingFlag.fbx", **fbx)


os.makedirs(OUT, exist_ok=True)
reset_scene()
image = make_texture()
pole, finial = build_pole()
cloth, arm = build_cloth(image)
preview(arm)
export(cloth, arm, pole, finial)
tris = sum(len(p.vertices) - 2 for ob in (cloth, pole, finial) for p in ob.data.polygons)
print("[flag] done: %d triangles, out %s" % (tris, OUT))
