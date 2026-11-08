# Blender headless: the Mushroom Grove's own low-poly props, made by script (no pack has them): glowing cap mushrooms in the
# painting's blue / purple / pink (small and giant), thick twisting roots, chunky mossy ruin stones. Each is ONE mesh whose
# colours are VERTEX colours (Roblox keeps those), origin at the middle of its foot, written as a small .glb into OUT_DIR with a
# preview picture, like tools/library/fbx_to_glb.py does for the packs' props. Prints each prop's triangle count.
#   blender -b --factory-startup -P tools/library/make_grove.py -- <out_dir>
import math
import os
import random
import sys

import bpy
from mathutils import Vector

out_dir = sys.argv[sys.argv.index("--") + 1]
os.makedirs(out_dir, exist_ok=True)
prev_dir = os.path.join(out_dir, "preview")
os.makedirs(prev_dir, exist_ok=True)


def lin(c):
	return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hexc(h, mul=1.0):
	return tuple(min(1.0, lin(int(h[i : i + 2], 16) / 255) * mul) for i in (1, 3, 5)) + (1.0,)


def mix(a, b, t):
	return tuple(a[i] + (b[i] - a[i]) * t for i in range(4))


def finish(name, verts, faces, colour_of):
	"""verts: list of (x, y, z) in Blender's Z-up; faces: lists of vertex indices (convex, wound outward); colour_of(face_index,
	centre, normal) -> RGBA linear."""
	bpy.ops.wm.read_factory_settings(use_empty=True)
	me = bpy.data.meshes.new(name)
	me.from_pydata([tuple(v) for v in verts], [], faces)
	me.update()
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	bpy.context.view_layer.objects.active = ob
	# foot at the origin: the lowest point at z 0, the middle of the footprint at x, y 0
	lo = Vector((min(v.co.x for v in me.vertices), min(v.co.y for v in me.vertices), min(v.co.z for v in me.vertices)))
	hi = Vector((max(v.co.x for v in me.vertices), max(v.co.y for v in me.vertices), max(v.co.z for v in me.vertices)))
	for v in me.vertices:
		v.co -= Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
	attr = me.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="CORNER")
	for poly in me.polygons:
		c = colour_of(poly.index, poly.center, poly.normal)
		for li in poly.loop_indices:
			attr.data[li].color = c
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
	dims = ob.dimensions
	out = os.path.join(out_dir, name + ".glb")
	bpy.ops.export_scene.gltf(
		filepath=out, export_format="GLB", export_active_vertex_color_when_no_material=True, export_vertex_color="ACTIVE"
	)
	print("GLB", name, "tris", tris, "dims %.2f %.2f %.2f" % (dims.x, dims.y, dims.z), "bytes", os.path.getsize(out))
	scene = bpy.context.scene
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "VERTEX"
	scene.render.resolution_x = 256
	scene.render.resolution_y = 256
	scene.world = bpy.data.worlds.new("W")
	scene.world.color = (0.18, 0.28, 0.26)
	size = max(dims.x, dims.y, dims.z)
	cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
	scene.collection.objects.link(cam)
	scene.camera = cam
	mid = Vector((0, 0, dims.z / 2))
	cam.location = mid + Vector((1.5, -2.0, 1.1)).normalized() * size * 2.4
	cam.rotation_euler = (mid - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(prev_dir, name + ".png")
	bpy.ops.render.render(write_still=True)


def ring(n, radius, z, wobble=0.0, rnd=None, phase=0.0):
	out = []
	for k in range(n):
		a = phase + k / n * math.tau
		r = radius * (1 + (rnd.uniform(-wobble, wobble) if rnd else 0))
		out.append((math.cos(a) * r, math.sin(a) * r, z))
	return out


def bridge(faces, a0, b0, n):
	"""Quads between two rings of n vertices starting at indices a0 (lower) and b0 (upper)."""
	for k in range(n):
		k2 = (k + 1) % n
		faces.append([a0 + k, a0 + k2, b0 + k2, b0 + k])


# ---- glowing cap mushrooms --------------------------------------------------------------------------------------------
STEM = hexc("#f4ead2")
STEM_DARK = hexc("#d6c9a6")
CAPS = {
	# name: (cap, rim, underside)
	"Blue": ("#2fa6ff", "#8fe0ff", "#d6f4ff"),
	"Purple": ("#9a50e8", "#d09aff", "#f0dcff"),
	"Pink": ("#f0589f", "#ffa6d4", "#ffe0f0"),
	"Teal": ("#25c4a8", "#8ff0d8", "#d8fff2"),
}


def mushroom(name, kind, stem_h, stem_r, cap_r, cap_h, bend, seed, sides=8, glow=1.0):
	rnd = random.Random(seed)
	cap, rim, under = (hexc(h, glow) for h in CAPS[kind])
	verts, faces, cols = [], [], []
	# the stem: four rings from the foot up, leaning by `bend`, thinner at the waist
	radii = [stem_r * 1.35, stem_r * 0.95, stem_r * 0.9, stem_r * 1.05]
	zs = [0.0, stem_h * 0.35, stem_h * 0.7, stem_h]
	starts = []
	for r, z in zip(radii, zs):
		starts.append(len(verts))
		off = bend * (z / stem_h) ** 2
		for x, y, zz in ring(sides, r, z, 0.06, rnd):
			verts.append((x + off, y, zz))
	for i in range(3):
		bridge(faces, starts[i], starts[i + 1], sides)
		cols += [mix(STEM_DARK, STEM, i / 2)] * sides
	top = bend
	# the cap: underside rim, widest ring, a shoulder, and the crown
	cap_sides = sides + 2
	base = len(verts)
	rings = [
		(cap_r * 0.98, stem_h - cap_h * 0.12),
		(cap_r * 1.0, stem_h + cap_h * 0.12),
		(cap_r * 0.82, stem_h + cap_h * 0.55),
		(cap_r * 0.45, stem_h + cap_h * 0.9),
	]
	cs = []
	for r, z in rings:
		cs.append(len(verts))
		for x, y, zz in ring(cap_sides, r, z, 0.05, rnd):
			verts.append((x + top, y, zz))
	apex = len(verts)
	verts.append((top, 0, stem_h + cap_h))
	for i in range(3):
		bridge(faces, cs[i], cs[i + 1], cap_sides)
		colour = rim if i == 0 else cap
		cols += [mix(colour, cap, rnd.random() * 0.25)] * cap_sides
	for k in range(cap_sides):
		k2 = (k + 1) % cap_sides
		faces.append([cs[3] + k, cs[3] + k2, apex])
		cols.append(mix(cap, rim, 0.25 + 0.5 * rnd.random()))
	# the gills: a disc from the cap's underside rim in to the stem's top ring
	gill = len(verts)
	for x, y, z in ring(cap_sides, cap_r * 0.35, stem_h - cap_h * 0.06, 0.0, None):
		verts.append((x + top, y, z))
	for k in range(cap_sides):
		k2 = (k + 1) % cap_sides
		faces.append([gill + k2, gill + k, cs[0] + k, cs[0] + k2])
		cols.append(under)
	finish(name, verts, faces, lambda i, c, n: cols[i])


# ---- thick twisting roots ---------------------------------------------------------------------------------------------
BARK = hexc("#6a4426")
BARK_LIGHT = hexc("#9a6a3c")
MOSS = hexc("#6fa534")


def root(name, length, thick, arch, wander, twist, seed, segs=14, sides=6):
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	ph1, ph2 = rnd.uniform(0, 6.28), rnd.uniform(0, 6.28)
	prev = None
	rings_at = []
	for s in range(segs + 1):
		t = s / segs
		x = t * length
		# an arch over the ground and a sideways wander that settles toward the tip; thick at the foot, thin at the tip
		y = wander * math.sin(t * math.tau * 0.9 + ph1) * (0.4 + 0.6 * t)
		z = arch * math.sin(min(1.0, t * 1.15) * math.pi) ** 0.8 + thick * 0.5 * (1 - t)
		r = thick * (1.0 - 0.55 * t) * (1 + 0.14 * math.sin(t * 9 + ph2))
		rings_at.append((Vector((x, y, z)), r))
	for s, (p, r) in enumerate(rings_at):
		tangent = (rings_at[min(s + 1, segs)][0] - rings_at[max(s - 1, 0)][0]).normalized()
		side = tangent.cross(Vector((0, 0, 1)))
		if side.length < 1e-4:
			side = Vector((0, 1, 0))
		side.normalize()
		up = side.cross(tangent).normalized()
		start = len(verts)
		for k in range(sides):
			a = k / sides * math.tau + twist * s / segs
			d = side * math.cos(a) * r + up * math.sin(a) * r * 0.8
			verts.append((p.x + d.x, p.y + d.y, p.z + d.z))
		if prev is not None:
			for k in range(sides):
				k2 = (k + 1) % sides
				faces.append([prev + k, prev + k2, start + k2, start + k])
		prev = start
	# a cap at the foot, so no hole shows
	faces.append([k for k in reversed(range(sides))])
	n_face_rows = segs

	def colour(i, c, n):
		if i >= segs * sides:
			return BARK
		row = i // sides
		t = row / segs
		base = mix(BARK_LIGHT, BARK, 0.35 + 0.5 * ((i % sides) / sides))
		if n.z > 0.5 and rnd.random() < 0.35:
			base = mix(base, MOSS, 0.6)
		return mix(base, BARK, 0.35 * t)

	finish("Grove" + name, verts, faces, colour)


# ---- chunky mossy ruin stones -----------------------------------------------------------------------------------------
STONE = hexc("#b4ad98")
STONE_LIGHT = hexc("#d9d3bc")
STONE_DARK = hexc("#948c76")


def stone(name, w, d, h, taper, jitter, seed, rows=3):
	"""A chunky block: a base ring, rows of four corners drifting inward, a flat top; green on top and in patches."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	starts = []
	for r in range(rows + 1):
		t = r / rows
		sx = w * (1 - taper * t * t) / 2
		sy = d * (1 - taper * t * t) / 2
		z = h * t
		starts.append(len(verts))
		for cx, cy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
			j = lambda: rnd.uniform(-jitter, jitter) * w
			verts.append((cx * sx + j(), cy * sy + j(), z + (rnd.uniform(-jitter, jitter) * h * 0.4 if r > 0 else 0)))
	for r in range(rows):
		bridge(faces, starts[r], starts[r + 1], 4)
	faces.append([starts[rows] + 3, starts[rows] + 2, starts[rows] + 1, starts[rows]])
	faces.append([starts[0], starts[0] + 1, starts[0] + 2, starts[0] + 3])

	def colour(i, c, n):
		if n.z > 0.45:
			return mix(MOSS, hexc("#7aa83a"), rnd.random())
		row = i // 4
		base = mix(STONE_DARK, STONE_LIGHT, row / max(rows - 1, 1) * 0.6 + rnd.random() * 0.3)
		if row == rows - 1 and rnd.random() < 0.35:
			base = mix(base, MOSS, 0.7)
		elif rnd.random() < 0.08:
			base = mix(base, MOSS, 0.5)
		return base

	finish("Grove" + name, verts, faces, colour)


# ---- make them --------------------------------------------------------------------------------------------------------
# small glowing mushrooms (the painting's clusters): three colours, two shapes each
for kind in ("Blue", "Purple", "Pink"):
	mushroom("MushGlow_%s_1" % kind, kind, 0.95, 0.11, 0.5, 0.42, 0.10, 11, glow=1.0)
	mushroom("MushGlow_%s_2" % kind, kind, 0.6, 0.1, 0.42, 0.34, -0.06, 23, glow=1.0)
# the giant ones for the corners' foot and the far woods
mushroom("MushBig_Blue", "Blue", 3.2, 0.34, 1.7, 1.15, 0.6, 31, sides=9, glow=0.9)
mushroom("MushBig_Purple", "Purple", 3.6, 0.36, 1.9, 1.2, -0.7, 41, sides=9, glow=0.85)
mushroom("MushBig_Teal", "Teal", 3.0, 0.32, 1.6, 1.05, 0.4, 53, sides=9, glow=0.85)
# roots: long low arches, thick twisting ones, a short knotted one
root("Root_1", 5.0, 0.55, 0.9, 0.8, 1.2, 7)
root("Root_2", 6.5, 0.65, 1.3, 1.1, 2.0, 17)
root("Root_3", 4.0, 0.5, 0.5, 0.7, 0.8, 27)
root("Root_4", 7.5, 0.6, 1.6, 1.4, 1.5, 37)
root("Root_5", 3.2, 0.6, 1.0, 0.5, 2.6, 47)
# ruin stones: a tall slab, a thick pillar-block, a low block, a leaning slab
stone("Slab_1", 1.0, 0.55, 3.2, 0.12, 0.035, 5)
stone("Slab_2", 1.3, 0.7, 2.4, 0.2, 0.04, 15)
stone("Slab_3", 0.9, 0.9, 2.0, 0.1, 0.045, 25)
stone("Block_1", 1.6, 1.4, 1.1, 0.15, 0.05, 35)
stone("Block_2", 1.2, 1.2, 0.8, 0.25, 0.05, 45)
