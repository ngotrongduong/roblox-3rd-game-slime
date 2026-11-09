# Blender headless: Frozen Ice's own low-poly props, made by script (no pack has them). The painting (battle.map.ice.png) is a
# pale frozen lake with a snowy shore, big snow-capped dark slate rocks with blue crystals growing through them in the corners,
# frosted pale blue-green pines, bare twig "corals" with white frost, and small frost shrubs. So: heavy LOW slate masses with
# a snow cap, a few crystal clusters, pine groves (3 or 4 pines on a snow mound, so the rim reads as groups and not a ring of
# spikes), snow mounds for the shore, little snow fences, frost sprigs and shrubs, and flat crack lines for the lake.
# Each prop is ONE mesh whose colours are VERTEX colours (Roblox keeps those), origin at the middle of its foot, written as a
# small .glb into OUT_DIR with a preview picture, like make_lava.py does. Every colour is stored RAW (sRGB as wanted: Roblox
# shows vertex colours as stored). The light and shine come from the game's light, not from the paint, except that an up-facing
# face of a rock is painted snow (that is a cap, not a highlight).
#
# Names the plan and the Config use (docs/DUNGEON_MAPS.md, Frozen Ice): IceMound_n (shore, wide), IceGrove_n (pine kind, by
# height), IceRock_n (ruin kind, by height), IceBoulder_n (rock), IceCrystal_n (glow kind: clusters, by height) and IceShard_n
# (root kind: low crystal sprouts at a rock's foot, wide).
# Round 4 (the art director's review of the ice-r3 shots) adds: IceRidge_n (faceted snow ridges, the hills' ring, stretched to
# the plan's width and height), IceFar_n (the far land that closes the horizon), IceCliff_n (cliff kind: the heavy rock
# landmarks, wide), IceCrystalHero_n (hero kind, by height), IceCrystalMid_n (glow kind), IceCrystalSmall_n (root kind, wide),
# IceBank_n (bank kind, wide), IceFrostBush_n (frost kind, wide) and IcePatch_n (patch kind: faint floor frost, wide);
# IceCrack_n is thinner and shorter. The palette is the review's: slate-blue rock, snow a touch under white, cyan crystals.
#   blender -b --factory-startup -P tools/library/make_ice.py -- <out_dir>
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

TAU = math.tau


def mix(a, b, t):
	return tuple(a[i] + (b[i] - a[i]) * t for i in range(4))


def raw(h):
	return tuple(int(h[i : i + 2], 16) / 255 for i in (1, 3, 5)) + (1.0,)


# the palette (round 4, from the art director's review of the shots): the slate is the contrast (clearly darker than the floor
# #DDEBF5 and the snow), blue rather than grey; the snow a touch below white; the crystals cyan cores with pale tips (never white)
SNOW = raw("#f0f6fa")
SNOW_SHADE = raw("#b4c8da")
SLATE = raw("#4e6a85")
SLATE_DARK = raw("#405a75")
SLATE_LIGHT = raw("#617d96")
PINE = raw("#86c3c0")
PINE_DARK = raw("#5f9ea6")
TRUNK = raw("#4a4658")
ICE_DEEP = raw("#318ebc")
ICE_MID = raw("#65c8e9")
ICE_LIGHT = raw("#c5f7ff")
TWIG = raw("#55607c")
FROST = raw("#dcf0ff")
WOOD = raw("#6a6070")
CRACK = raw("#c4d9ea")
CRACK_EDGE = raw("#8aaac6")
# the ridges and the far land: slate-blue faces under pale snow shoulders; the far land two pale blue-greys
RIDGE_ROCK = raw("#6f879f")
RIDGE_SNOW1 = raw("#afc6d8")
RIDGE_SNOW2 = raw("#e6f1f8")
FAR_LOW = raw("#b7c9d9")
FAR_HIGH = raw("#d6e3ed")
BUSH_A = raw("#8ba5bd")
BUSH_B = raw("#bfe4f2")
PATCH = raw("#c9deeb")
FLOOR = raw("#ddebf5")


def vary(base, rnd, amount=0.3):
	"""a base colour pushed a little toward the dark or the light, per piece"""
	t = rnd.uniform(-amount, amount)
	return mix(base, SLATE_LIGHT if t > 0 else SLATE_DARK, abs(t))


def finish(name, verts, faces, cols=None, vcol=None, check=True):
	"""verts: (x, y, z) in Blender's Z-up; faces: lists of vertex indices (wound outward). Colour: `cols[face]` = (RGBA, cap)
	(a capped face turns snow the more it looks up), or `vcol[vertex]` = RGBA."""
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
	me.update()
	attr = me.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="CORNER")
	for poly in me.polygons:
		if vcol is None:
			c, cap = cols[poly.index]
			if cap:
				t = min(1.0, max(0.0, (poly.normal.z - 0.25) / 0.4))
				c = mix(c, SNOW, t * 0.95)
		for li in poly.loop_indices:
			attr.data[li].color = vcol[me.loops[li].vertex_index] if vcol is not None else c
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
	inward = 0
	if check:
		# winding: every face of each separate solid must face away from that solid's own middle
		parent = list(range(len(me.vertices)))

		def find(i):
			while parent[i] != i:
				parent[i] = parent[parent[i]]
				i = parent[i]
			return i

		for p in me.polygons:
			for a in p.vertices[1:]:
				parent[find(a)] = find(p.vertices[0])
		members = {}
		for p in me.polygons:
			members.setdefault(find(p.vertices[0]), []).append(p)
		for polys in members.values():
			used = {v for p in polys for v in p.vertices}
			middle = sum((me.vertices[v].co for v in used), Vector()) / len(used)
			inward += sum(1 for p in polys if (p.center - middle).dot(p.normal) < -0.02)
	out = os.path.join(out_dir, name + ".glb")
	bpy.ops.export_scene.gltf(
		filepath=out, export_format="GLB", export_active_vertex_color_when_no_material=True, export_vertex_color="ACTIVE"
	)
	print(
		"GLB",
		name,
		"tris",
		tris,
		"dims %.2f %.2f %.2f" % (dims.x, dims.y, dims.z),
		"bytes",
		os.path.getsize(out),
		"inward",
		inward,
	)
	scene = bpy.context.scene
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "VERTEX"
	scene.render.resolution_x = 256
	scene.render.resolution_y = 256
	scene.world = bpy.data.worlds.new("W")
	scene.world.color = (0.62, 0.74, 0.9)
	size = max(dims.x, dims.y, dims.z)
	cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
	scene.collection.objects.link(cam)
	scene.camera = cam
	mid = Vector((0, 0, dims.z / 2))
	cam.location = mid + Vector((1.5, -2.0, 1.1)).normalized() * size * 2.4
	cam.rotation_euler = (mid - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(prev_dir, name + ".png")
	bpy.ops.render.render(write_still=True)


def bridge(faces, a0, b0, n):
	"""Quads between two rings of n vertices starting at indices a0 (lower) and b0 (upper)."""
	for k in range(n):
		k2 = (k + 1) % n
		faces.append([a0 + k, a0 + k2, b0 + k2, b0 + k])


T = (1 + math.sqrt(5)) / 2
ICO_V = [(-1, T, 0), (1, T, 0), (-1, -T, 0), (1, -T, 0), (0, -1, T), (0, 1, T), (0, -1, -T), (0, 1, -T), (T, 0, -1), (T, 0, 1), (-T, 0, -1), (-T, 0, 1)]
ICO_F = [
	(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
	(3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1),
]  # fmt: skip


def unit(v):
	m = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2)
	return (v[0] / m, v[1] / m, v[2] / m)


def ico(levels):
	verts = [unit(v) for v in ICO_V]
	faces = [list(f) for f in ICO_F]
	for _ in range(levels):
		cache = {}

		def mid(a, b):
			key = (min(a, b), max(a, b))
			if key not in cache:
				m = unit(tuple((verts[a][i] + verts[b][i]) / 2 for i in range(3)))
				verts.append(m)
				cache[key] = len(verts) - 1
			return cache[key]

		out = []
		for a, b, c in faces:
			ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
			out += [[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]]
		faces = out
	return verts, faces


def rock_into(verts, faces, cols, cx, cy, sx, sy, sz, rough, rnd, base, levels=0, flat=0.35, cap=True):
	"""A faceted rock: an icosphere stretched to (sx, sy, sz), roughened, its foot flattened and set on the ground at (cx, cy).
	Its top stands 2 - flat times sz high (levels 0 is 20 faces, 1 is 80). `cap`: its up-facing faces turn snow."""
	iv, ifc = ico(levels)
	yaw = rnd.uniform(0, TAU)
	cy_, sy_ = math.cos(yaw), math.sin(yaw)
	start = len(verts)
	for x, y, z in iv:
		k = rnd.uniform(1 - rough, 1 + rough)
		px, py, pz = x * sx * k, y * sy * k, z * sz * k
		zz = max(pz + sz * (1 - flat), 0.0)
		verts.append((cx + px * cy_ - py * sy_, cy + px * sy_ + py * cy_, zz))
	for f in ifc:
		faces.append([start + i for i in f])
		cols.append((vary(base, rnd, 0.3), cap))


# ---- crystals ---------------------------------------------------------------------------------------------------------
def crystal_into(verts, faces, cols, cx, cy, r, h, lean, rnd, sides=6, z0=0.0):
	"""One hexagonal crystal with a pointed tip: a foot ring, a shoulder ring at 0.62 h (a little narrower, the tip drifting
	along `lean`), and an apex (18 triangles); its foot at height z0. Deep cyan below, pale toward the tip (two tones a face)."""
	spin = rnd.uniform(0, TAU)
	starts = []
	for z, rm, lt in ((0.0, 1.0, 0.0), (0.62, 0.85, 0.35)):
		starts.append(len(verts))
		for k in range(sides):
			a = spin + k / sides * TAU
			verts.append((cx + math.cos(a) * r * rm + lean[0] * lt * h, cy + math.sin(a) * r * rm + lean[1] * lt * h, z0 + z * h))
	apex = len(verts)
	verts.append((cx + lean[0] * h, cy + lean[1] * h, z0 + h))
	bridge(faces, starts[0], starts[1], sides)
	for _ in range(sides):
		cols.append((mix(ICE_DEEP, ICE_MID, rnd.uniform(0.15, 0.55)), False))
	for k in range(sides):
		faces.append([starts[1] + k, starts[1] + (k + 1) % sides, apex])
		cols.append((mix(ICE_MID, ICE_LIGHT, rnd.uniform(0.35, 0.95)), False))


def clump_into(verts, faces, cols, cx, cy, tall, rnd, count, spread=None):
	"""A cluster of `count` crystals: the tallest in the middle, the others round it leaning outward (heights 0.5 to 0.8)."""
	spread = tall * 0.2 if spread is None else spread
	crystal_into(verts, faces, cols, cx, cy, tall * 0.17, tall, (rnd.uniform(-0.1, 0.1), rnd.uniform(-0.1, 0.1)), rnd)
	turn = rnd.uniform(0, TAU)
	for k in range(1, count):
		a = turn + k / (count - 1) * TAU + rnd.uniform(-0.3, 0.3)
		h = tall * rnd.uniform(0.5, 0.8)
		crystal_into(
			verts, faces, cols, cx + math.cos(a) * spread, cy + math.sin(a) * spread, h * 0.17, h,
			(math.cos(a) * 0.28, math.sin(a) * 0.28), rnd,
		)  # fmt: skip


def crystal(name, seed, tall, count):
	"""A cluster for the corners (kind `glow`, by height)."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	clump_into(verts, faces, cols, 0, 0, tall, rnd, count)
	finish(name, verts, faces, cols)


def shard(name, seed, count):
	"""Low crystals sprouting from the ground, 6 across (kind `root`, wide): they lean out like a hand opened on the snow."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	turn = rnd.uniform(0, TAU)
	for k in range(count):
		a = turn + k / count * TAU + rnd.uniform(-0.3, 0.3)
		d = rnd.uniform(1.2, 2.0) if k else 0.0
		h = rnd.uniform(2.6, 4.6) if k else 5.2
		crystal_into(verts, faces, cols, math.cos(a) * d, math.sin(a) * d, h * 0.2, h, (math.cos(a) * 0.4, math.sin(a) * 0.4), rnd)
	finish(name, verts, faces, cols)


# ---- slate masses, boulders, mounds ------------------------------------------------------------------------------------
def ice_rock(name, seed, boulders, hmax, clumps):
	"""A heavy low snow-capped slate cluster: `boulders` big rocks (6 to 12 wide, 4 to `hmax` high, the biggest in the middle)
	heaped together, a few crystal clumps pushing out between them."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	base = vary(SLATE, rnd, 0.06)
	turn0 = rnd.uniform(0, TAU)
	spread = 7.5
	for k in range(boulders):
		if k == 0:
			cx = cy = 0.0
			w = rnd.uniform(10.5, 12.0)
			h = hmax
		else:
			a = turn0 + k / (boulders - 1) * TAU + rnd.uniform(-0.35, 0.35)
			d = spread * rnd.uniform(0.55, 1.0)
			cx, cy = math.cos(a) * d, math.sin(a) * d
			w = rnd.uniform(6.0, 9.5)
			h = hmax * rnd.uniform(0.5, 0.85)
		rock_into(
			verts, faces, cols, cx, cy, w / 2 * rnd.uniform(0.95, 1.15), w / 2 * rnd.uniform(0.8, 1.0), h / 1.65, 0.2, rnd, base,
			levels=1 if k < 2 else 0, flat=0.35,
		)  # fmt: skip
	for k in range(clumps):
		a = turn0 + (k + 0.5) / max(clumps, 1) * TAU + 0.9
		d = spread * 1.05
		clump_into(verts, faces, cols, math.cos(a) * d, math.sin(a) * d, rnd.uniform(4.5, 6.0), rnd, 3, spread=1.0)
	finish(name, verts, faces, cols)


def boulder(name, seed, radii, rough):
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	rock_into(verts, faces, cols, 0, 0, radii[0], radii[1], radii[2], rough, rnd, vary(SLATE, rnd, 0.1), levels=1, flat=0.3)
	finish(name, verts, faces, cols)


def mound(name, seed, lumps):
	"""A soft snow drift for the shore: `lumps` overlapping flat domes (80 triangles each), white on top and blue-shadowed at
	the foot (painted by height, a face at a time)."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	for k in range(lumps):
		w = rnd.uniform(9.0, 13.0)
		h = rnd.uniform(2.0, 3.2)
		cx = 0.0 if k == 0 else rnd.uniform(-1, 1) * 5.0
		cy = 0.0 if k == 0 else rnd.uniform(-1, 1) * 3.0
		start = len(faces)
		rock_into(verts, faces, cols, cx, cy, w / 2, w / 2 * rnd.uniform(0.7, 0.95), h / 1.65, 0.07, rnd, SNOW, levels=1, flat=0.35, cap=False)
		top = max(v[2] for v in verts[-42:])
		for i in range(start, len(faces)):
			z = sum(verts[v][2] for v in faces[i]) / 3
			cols[i] = (mix(SNOW_SHADE, SNOW, min(1.0, max(0.0, z / (top * 0.8)) ** 0.7)), False)
	finish(name, verts, faces, cols)


# ---- frosted pines ----------------------------------------------------------------------------------------------------
def pine_into(verts, faces, cols, cx, cy, r, h, rnd, tiers=3):
	"""One frosted pine: a short trunk and `tiers` cones (24 triangles each), each with a pale blue-green skirt and a white
	snow top; the cones overlap upward and narrow."""
	n = 6
	spin = rnd.uniform(0, TAU)
	trunk0 = len(verts)
	for z, rr in ((0.0, 0.1), (0.25 * h, 0.07)):
		for k in range(4):
			a = k / 4 * TAU + spin
			verts.append((cx + math.cos(a) * r * rr * 3, cy + math.sin(a) * r * rr * 3, z))
	bridge(faces, trunk0, trunk0 + 4, 4)
	for _ in range(4):
		cols.append((TRUNK, False))
	for t in range(tiers):
		z0 = h * (0.1 + 0.27 * t)
		th = h * (0.46 if t < tiers - 1 else 0.5)
		rr = r * (1 - 0.27 * t)
		rings = []
		for z, scale in ((z0, 1.0), (z0 + th * 0.45, 0.55)):
			rings.append(len(verts))
			for k in range(n):
				a = spin + t * 0.5 + k / n * TAU
				jitter = 1 + 0.06 * math.sin(k * 2.7 + t)
				verts.append((cx + math.cos(a) * rr * scale * jitter, cy + math.sin(a) * rr * scale * jitter, z))
		apex = len(verts)
		verts.append((cx, cy, z0 + th))
		bridge(faces, rings[0], rings[1], n)
		for _ in range(n):
			cols.append((mix(PINE, SNOW, 0.3 + rnd.uniform(0, 0.15)), False))
		for k in range(n):
			faces.append([rings[1] + k, rings[1] + (k + 1) % n, apex])
			cols.append((SNOW, False))
		# the underside, so no hollow shows from a low camera
		centre = len(verts)
		verts.append((cx, cy, z0 + 0.02))
		for k in range(n):
			faces.append([rings[0] + (k + 1) % n, rings[0] + k, centre])
			cols.append((PINE_DARK, False))


def grove(name, seed, pines):
	"""A pine grove for the kind `pine` (by height 9 to 16): a snow mound and `pines` frosted pines, the tallest in the middle,
	the others round it at 0.55 to 0.8 of its height."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	tall = 12.0
	start = len(faces)
	rock_into(verts, faces, cols, 0, 0, tall * 0.5, tall * 0.42, 1.5, 0.06, rnd, SNOW, levels=1, flat=0.4, cap=False)
	top = max(v[2] for v in verts)
	for i in range(start, len(faces)):
		z = sum(verts[v][2] for v in faces[i]) / 3
		cols[i] = (mix(SNOW_SHADE, SNOW, min(1.0, max(0.0, z / (top * 0.9)))), False)
	pine_into(verts, faces, cols, 0, 0, tall * 0.2, tall, rnd, 3)
	turn = rnd.uniform(0, TAU)
	for k in range(1, pines):
		a = turn + k / (pines - 1) * TAU + rnd.uniform(-0.3, 0.3)
		d = tall * rnd.uniform(0.28, 0.38)
		h = tall * rnd.uniform(0.55, 0.8)
		pine_into(verts, faces, cols, math.cos(a) * d, math.sin(a) * d, h * 0.2, h, rnd, 3 if h > tall * 0.62 else 2)
	finish(name, verts, faces, cols)


# ---- frost sprigs and shrubs (the bare twig corals) --------------------------------------------------------------------
def limb(verts, faces, cols, p, d, length, r0, level, top, rnd, spread):
	"""One four-sided cone from p along d (unit), then, below `top` levels, three children leaning off its upper end."""
	# a frame u, v with u x v = d
	ref = (1.0, 0.0, 0.0) if abs(d[0]) < 0.9 else (0.0, 1.0, 0.0)
	u = (d[1] * ref[2] - d[2] * ref[1], d[2] * ref[0] - d[0] * ref[2], d[0] * ref[1] - d[1] * ref[0])
	m = math.sqrt(sum(c * c for c in u))
	u = tuple(c / m for c in u)
	v = (d[1] * u[2] - d[2] * u[1], d[2] * u[0] - d[0] * u[2], d[0] * u[1] - d[1] * u[0])
	# (u x v = d needs v = d x u)
	start = len(verts)
	for k in range(4):
		a = k / 4 * TAU
		verts.append(tuple(p[i] + (u[i] * math.cos(a) + v[i] * math.sin(a)) * r0 for i in range(3)))
	end = tuple(p[i] + d[i] * length for i in range(3))
	apex = len(verts)
	verts.append(end)
	frost = mix(TWIG, FROST, min(1.0, level / max(top, 1)))
	for k in range(4):
		faces.append([start + k, start + (k + 1) % 4, apex])
		cols.append((frost, False))
	if level < top:
		for k in range(3):
			a = rnd.uniform(0, TAU) if level else k / 3 * TAU + rnd.uniform(-0.3, 0.3)
			tilt = rnd.uniform(0.55, 0.9)
			# a unit vector tilted `tilt` radians off d, turned about it by a
			nd = tuple(d[i] * math.cos(tilt) + (u[i] * math.cos(a) + v[i] * math.sin(a)) * math.sin(tilt) for i in range(3))
			at = tuple(p[i] + d[i] * length * rnd.uniform(0.55, 0.85) for i in range(3))
			limb(verts, faces, cols, at, nd, length * rnd.uniform(0.55, 0.75), r0 * 0.6, level + 1, top, rnd, spread)


def sprig_into(verts, faces, cols, cx, cy, h, rnd, top):
	d = (rnd.uniform(-0.12, 0.12), rnd.uniform(-0.12, 0.12), 1.0)
	m = math.sqrt(sum(c * c for c in d))
	d = tuple(c / m for c in d)
	limb(verts, faces, cols, (cx, cy, 0.0), d, h * 0.45, h * 0.06, 0, top, rnd, 0.0)


def sprig(name, seed, h):
	"""A bare twig coral with white frost on its tips (kind `flower`, by height)."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	sprig_into(verts, faces, cols, 0, 0, h, rnd, 3)
	finish(name, verts, faces, cols, check=False)


def shrub(name, seed, sprigs):
	"""A snow heap with `sprigs` twig corals growing out of it (kind `bush`, wide, about 7 across)."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	rock_into(verts, faces, cols, 0, 0, 3.4, 3.0, 0.9, 0.08, rnd, SNOW, levels=1, flat=0.4, cap=False)
	for i in range(len(faces)):
		z = sum(verts[v][2] for v in faces[i]) / 3
		cols[i] = (mix(SNOW_SHADE, SNOW, min(1.0, z / 1.1)), False)
	turn = rnd.uniform(0, TAU)
	for k in range(sprigs):
		a = turn + k / sprigs * TAU
		d = 0.0 if k == 0 else rnd.uniform(1.3, 2.2)
		sprig_into(verts, faces, cols, math.cos(a) * d, math.sin(a) * d, rnd.uniform(3.6, 5.2) if k else 5.6, rnd, 2)
	finish(name, verts, faces, cols, check=False)


# ---- snow fences -------------------------------------------------------------------------------------------------------
def box_into(verts, faces, cols, cx, cy, z0, sx, sy, h, yaw, side, top):
	"""A box of sx x sy x h turned `yaw` about its own middle: four sides and a snow top (10 triangles)."""
	c, s = math.cos(yaw), math.sin(yaw)
	start = len(verts)
	for z in (z0, z0 + h):
		for x, y in ((-sx / 2, -sy / 2), (sx / 2, -sy / 2), (sx / 2, sy / 2), (-sx / 2, sy / 2)):
			verts.append((cx + x * c - y * s, cy + x * s + y * c, z))
	for a, b, c2, d in ((0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
		faces.append([start + a, start + b, start + c2, start + d])
		cols.append((side, False))
	faces.append([start + 4, start + 5, start + 6, start + 7])
	cols.append((top, False))


def fence(name, seed, posts, broken):
	"""A short snow fence along +X: `posts` posts 2.4 apart and two rails (one missing when `broken`), snow on every top."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	span = (posts - 1) * 2.4
	for k in range(posts):
		x = -span / 2 + k * 2.4
		box_into(verts, faces, cols, x, rnd.uniform(-0.1, 0.1), 0, 0.4, 0.4, rnd.uniform(1.5, 1.9), rnd.uniform(-0.25, 0.25), mix(WOOD, SLATE, 0.2), SNOW)
	for r, z in enumerate((0.55, 1.05)):
		if broken and r == 1:
			continue
		box_into(verts, faces, cols, 0, 0.26, z, span + 0.5, 0.18, 0.2, 0.0, WOOD, SNOW)
	finish(name, verts, faces, cols, check=False)


# ---- the lake's crack lines --------------------------------------------------------------------------------------------
THICK = 0.08
EDGE = 0.12


def crack_ribbon(verts, faces, vcol, points, widths):
	"""A flat ribbon on a polyline of HALF widths: white in the middle, a blue edge, a foot that slopes down to the floor so
	the crack lies 0.12 over it and never fights it (the foot is the lowest point, so the mesh stands at z 0)."""
	n = len(points)
	rows = []
	for i, (px, py) in enumerate(points):
		a = points[max(i - 1, 0)]
		b = points[min(i + 1, n - 1)]
		dx, dy = b[0] - a[0], b[1] - a[1]
		m = math.hypot(dx, dy) or 1.0
		nx, ny = -dy / m, dx / m
		w = widths[i]
		base = len(verts)
		for side, z, c, out in ((1, THICK, CRACK_EDGE, 0), (0, THICK, CRACK, 0), (-1, THICK, CRACK_EDGE, 0), (1, 0.0, CRACK_EDGE, EDGE), (-1, 0.0, CRACK_EDGE, EDGE)):
			verts.append((px + nx * (w + out) * side, py + ny * (w + out) * side, z))
			vcol.append(c)
		rows.append(base)
	for i in range(n - 1):
		a, b = rows[i], rows[i + 1]
		faces.append([a + 2, b + 2, b + 1, a + 1])
		faces.append([a + 1, b + 1, b + 0, a + 0])
		faces.append([a + 4, b + 4, b + 2, a + 2])
		faces.append([b + 3, a + 3, a + 0, b + 0])


def crack_line(rnd, x, y, heading, seg, count, w_from, w_to, swing):
	pts, wid = [(x, y)], [w_from]
	for i in range(1, count + 1):
		heading += rnd.uniform(-swing, swing)
		x += math.cos(heading) * seg
		y += math.sin(heading) * seg
		pts.append((x, y))
		wid.append(w_from + (w_to - w_from) * i / count)
	return pts, wid


def crack(name, seed, length, branches):
	"""A frozen-lake crack: a kinked main line along X about `length` long, thin forks off it (flat, flush, kind `pebble`)."""
	rnd = random.Random(seed)
	verts, faces, vcol = [], [], []
	n = 6
	seg = length / n
	pts, wid = crack_line(rnd, -length / 2, 0.0, 0.0, seg, n, 0.15, 0.05, 0.38)
	crack_ribbon(verts, faces, vcol, pts, wid)
	slots = list(range(1, n - 1))
	rnd.shuffle(slots)
	for k in range(branches):
		i = slots[k % len(slots)]
		ox, oy = pts[i]
		side = 1 if k % 2 == 0 else -1
		heading = math.atan2(pts[i + 1][1] - oy, pts[i + 1][0] - ox) + side * rnd.uniform(0.5, 1.0)
		bpts, bwid = crack_line(rnd, ox, oy, heading, seg * rnd.uniform(0.6, 0.9), rnd.choice((2, 3)), 0.09, 0.03, 0.45)
		crack_ribbon(verts, faces, vcol, bpts, bwid)
	finish(name, verts, faces, vcol=vcol, check=False)


# ---- round 4: faceted ridges and the far land --------------------------------------------------------------------------
def clamp01(t):
	return min(1.0, max(0.0, t))


def face_normal(verts, f):
	a, b, c = verts[f[0]], verts[f[1]], verts[f[2]]
	ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
	vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
	n = (uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx)
	m = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2) or 1.0
	return (n[0] / m, n[1] / m, n[2] / m)


def peaks(rnd, count, lo, wlo, whi):
	"""Triangular summits along the ridge: (where -0.5 to 0.5, how high 0 to 1, how wide); the tallest is exactly 1."""
	out = []
	for k in range(count):
		u = (k + 0.5) / count - 0.5 + rnd.uniform(-0.1, 0.1)
		out.append([u, rnd.uniform(lo, 1.0), rnd.uniform(wlo, whi)])
	out[rnd.randrange(count)][1] = 1.0
	return out


def envelope(u, ps):
	return max((a * max(0.0, 1 - abs(u - up) / w) for up, a, w in ps), default=0.0)


def cross_profile(v, crest):
	"""0 at both edges (v -0.5 and 0.5), 1 along the crest line, straight slopes between (steeper on the near side)."""
	if v < crest:
		return clamp01(1 - (crest - v) / (crest + 0.5))
	return clamp01(1 - (v - crest) / (0.5 - crest))


def heightfield(verts, faces, nx, ny, W, D, height, rnd, jit=0.3, top=None):
	"""A coarse irregular grid, z from height(u, v) (u, v in -0.5..0.5), 0 along the whole outline: nx x ny vertices, two
	triangles a cell, the diagonal turned at random, every face wound to look up. Returns the faces made."""
	base = len(verts)
	for j in range(ny):
		for i in range(nx):
			u, v = i / (nx - 1) - 0.5, j / (ny - 1) - 0.5
			edge = i in (0, nx - 1) or j in (0, ny - 1)
			x = u * W + (rnd.uniform(-jit, jit) * W / (nx - 1) if 0 < i < nx - 1 else 0.0)
			y = v * D + (rnd.uniform(-jit, jit) * D / (ny - 1) if 0 < j < ny - 1 else 0.0)
			verts.append((x, y, 0.0 if edge else height(u, v)))
	# the grid may miss the crest: scale so the tallest vertex is exactly `top`
	if top:
		peak = max(v[2] for v in verts[base:]) or 1.0
		for n in range(base, len(verts)):
			verts[n] = (verts[n][0], verts[n][1], verts[n][2] * top / peak)
	made = []
	for j in range(ny - 1):
		for i in range(nx - 1):
			a = base + j * nx + i
			b, c, d = a + 1, a + nx + 1, a + nx
			if rnd.random() < 0.5:
				made += [[a, b, c], [a, c, d]]
			else:
				made += [[a, b, d], [b, c, d]]
	faces += made
	return made


def ridge(name, seed, W, D, H, nx, ny, summits):
	"""A faceted snow ridge for the hills' ring: a few big planes with asymmetric crests, slate-blue rock faces and pale snow
	shoulders (steep faces rock, flatter ones snow, the snow whiter higher up). Open below: it stands in the ground."""
	rnd = random.Random(seed)
	ps = peaks(rnd, summits, 0.5, 0.26, 0.42)
	crest = rnd.uniform(-0.13, 0.13)
	verts, faces, cols = [], [], []
	made = heightfield(verts, faces, nx, ny, W, D, lambda u, v: H * envelope(u, ps) * cross_profile(v, crest) * rnd.uniform(0.86, 1.08), rnd, 0.3, H)
	for f in made:
		n = face_normal(verts, f)
		zc = sum(verts[i][2] for i in f) / 3 / H
		rock = 1 - clamp01((n[2] - 0.35) / 0.4 + (zc - 0.45) * 1.2)
		stone = mix(RIDGE_ROCK, SLATE_DARK, rnd.uniform(0.0, 0.2))
		snow = mix(RIDGE_SNOW1, RIDGE_SNOW2, clamp01(zc * 1.3 - 0.1 + rnd.uniform(-0.1, 0.1)))
		cols.append((mix(snow, stone, rock), False))
	finish(name, verts, faces, cols, check=False)


def far_land(name, seed, W, D, H):
	"""One piece of the far land that closes the horizon: an irregular opaque skyline of many narrow summits with a lower layer
	of foothills in front of them, pale blue-grey (paler higher). Open below; the plan sinks its foot under the floor line."""
	rnd = random.Random(seed)
	back = peaks(rnd, 8, 0.4, 0.07, 0.12)
	front = peaks(rnd, 6, 0.2, 0.08, 0.14)
	verts, faces, cols = [], [], []
	made = heightfield(
		verts, faces, 17, 6, W, D,
		lambda u, v: H * max(envelope(u, back) * cross_profile(v, 0.2), 0.55 * envelope(u, front) * cross_profile(v, -0.14)) * rnd.uniform(0.9, 1.05),
		rnd, 0.35, H,
	)  # fmt: skip
	for f in made:
		zc = sum(verts[i][2] for i in f) / 3 / H
		cols.append((mix(FAR_LOW, FAR_HIGH, clamp01(zc * 1.15 + rnd.uniform(-0.12, 0.12))), False))
	finish(name, verts, faces, cols, check=False)


# ---- round 4: the heavy rock landmarks ---------------------------------------------------------------------------------
def tower_into(verts, faces, cols, cx, cy, r, h, rnd, sides=6, lean=(0.0, 0.0)):
	"""One angular rock tower under a thick snow cap that overhangs it: rings at 0, 0.5, 0.8 h (the rock, narrowing and leaning),
	the cap's lip at 0.84 h (wider than the rock below), its shoulder at 0.95 h and a flat top. Dark blue faces, light ones
	on some; about 54 triangles for 6 sides."""
	spin = rnd.uniform(0, TAU)
	rings = []
	for zf, rm in ((0.0, 1.0), (0.45, 0.84), (0.78, 0.66), (0.82, 0.76), (0.94, 0.5)):
		rings.append(len(verts))
		for k in range(sides):
			a = spin + k / sides * TAU + rnd.uniform(-0.15, 0.15)
			rr = r * rm * rnd.uniform(0.82, 1.18)
			dz = rnd.uniform(-0.05, 0.05) * h if 0 < zf < 0.9 else 0.0
			verts.append((cx + math.cos(a) * rr + lean[0] * zf * h, cy + math.sin(a) * rr + lean[1] * zf * h, zf * h + dz))
	top = len(verts)
	verts.append((cx + lean[0] * h, cy + lean[1] * h, h))
	for band in range(4):
		bridge(faces, rings[band], rings[band + 1], sides)
		for _ in range(sides):
			if band < 2:
				stone = mix(SLATE_DARK, SLATE_LIGHT, rnd.uniform(0.0, 1.0))
				cols.append((mix(stone, SLATE_DARK, 0.3 * (1 - band)), False))
			elif band == 2:
				cols.append((mix(SNOW_SHADE, RIDGE_SNOW1, rnd.uniform(0.0, 1.0)), False))
			else:
				cols.append((mix(SNOW, RIDGE_SNOW2, rnd.uniform(0.0, 0.6)), False))
	for k in range(sides):
		faces.append([rings[4] + k, rings[4] + (k + 1) % sides, top])
		cols.append((SNOW, False))


def cliff(name, seed, masses, W, H):
	"""A heavy rock landmark (16 to 25 wide, 10 to 16 tall): `masses` angular towers that interlock (they overlap), the tallest in
	the middle, dark slate faces under thick snow caps."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	turn = rnd.uniform(0, TAU)
	for k in range(masses):
		if k == 0:
			cx = cy = 0.0
			r, h = W * 0.3, H
		else:
			a = turn + k / (masses - 1) * TAU + rnd.uniform(-0.3, 0.3)
			d = W * rnd.uniform(0.26, 0.34)
			cx, cy = math.cos(a) * d, math.sin(a) * d
			r, h = W * rnd.uniform(0.2, 0.27), H * rnd.uniform(0.5, 0.88)
		lean = (rnd.uniform(-0.05, 0.05), rnd.uniform(-0.05, 0.05))
		tower_into(verts, faces, cols, cx, cy, r, h, rnd, sides=6 if k % 2 == 0 else 5, lean=lean)
	finish(name, verts, faces, cols, check=False)


# ---- round 4: the crystal hierarchy, banks, frosted bushes, frost patches ------------------------------------------------
def spires(verts, faces, cols, rnd, tall, count, z0, spread):
	"""`count` crystals from height z0: the tallest in the middle (its tip at z0 + tall), the others round it leaning outward."""
	crystal_into(verts, faces, cols, 0.0, 0.0, tall * 0.12, tall, (rnd.uniform(-0.06, 0.06), rnd.uniform(-0.06, 0.06)), rnd, z0=z0)
	turn = rnd.uniform(0, TAU)
	for k in range(1, count):
		a = turn + k / (count - 1) * TAU + rnd.uniform(-0.3, 0.3)
		h = tall * rnd.uniform(0.45, 0.8)
		crystal_into(
			verts, faces, cols, math.cos(a) * spread, math.sin(a) * spread, h * 0.13, h, (math.cos(a) * 0.3, math.sin(a) * 0.3), rnd, z0=z0
		)  # fmt: skip


def hero(name, seed, tall, count):
	"""A hero or medium crystal cluster (kind `hero` or `glow`, by height): `count` spires rising out of a dark rock foot with a
	snow cap, cyan cores and pale tips."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	foot = tall * 0.2
	tower_into(verts, faces, cols, 0.0, 0.0, tall * 0.34, foot, rnd, sides=7)
	spires(verts, faces, cols, rnd, tall - foot * 0.6, count, foot * 0.6, tall * 0.13)
	finish(name, verts, faces, cols, check=False)


def tiny_crystals(name, seed, tall, count):
	"""Small crystals, 1 to 3 tall, three or four in a pinch (kind `root`, wide)."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	spires(verts, faces, cols, rnd, tall, count, 0.0, tall * 0.4)
	finish(name, verts, faces, cols, check=False)


def bank(name, seed, length, lumps):
	"""A long low snow bank (kind `bank`, by length; about a quarter as high): `lumps` flat domes in a row, pale on top and
	blue-shadowed at the foot."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	for k in range(lumps):
		t = (k + 0.5) / lumps - 0.5
		w = length / lumps * rnd.uniform(1.3, 1.6)
		h = length * rnd.uniform(0.2, 0.27) * (1 - abs(t) * 0.7)
		first, start = len(verts), len(faces)
		rock_into(verts, faces, cols, t * length * 0.8, rnd.uniform(-0.3, 0.3), w / 2, w / 2 * rnd.uniform(0.38, 0.5), h / 1.65, 0.07, rnd, SNOW, levels=1, flat=0.35, cap=False)
		top = max(v[2] for v in verts[first:])
		for i in range(start, len(faces)):
			z = sum(verts[v][2] for v in faces[i]) / 3
			cols[i] = (mix(SNOW_SHADE, SNOW, clamp01(z / (top * 0.85)) ** 0.7), False)
	finish(name, verts, faces, cols)


def frost_bush(name, seed, lumps):
	"""A frosted bush (kind `frost`, wide; about 3/4 as high as wide): `lumps` overlapping blue-grey and pale cyan domes with a
	dusting of snow on top."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	turn = rnd.uniform(0, TAU)
	for k in range(lumps):
		a = turn + k / lumps * TAU
		d = 0.0 if k == 0 else rnd.uniform(0.9, 1.3)
		w = rnd.uniform(2.6, 3.4) if k else 3.8
		h = rnd.uniform(2.0, 2.6) if k else 3.2
		start = len(faces)
		rock_into(verts, faces, cols, math.cos(a) * d, math.sin(a) * d, w / 2, w / 2 * rnd.uniform(0.85, 1.0), h / 1.65, 0.14, rnd, BUSH_A, levels=1 if k == 0 else 0, flat=0.3)
		for i in range(start, len(faces)):
			cols[i] = (mix(BUSH_A, BUSH_B, rnd.random()), True)
	finish(name, verts, faces, cols)


def patch(name, seed, size):
	"""A faint frost patch on the floor (kind `patch`, wide): an irregular polygon a hair above the floor, #C9DEEB in the middle
	fading to the floor colour at its edge."""
	rnd = random.Random(seed)
	verts, vcol, faces = [(0.0, 0.0, 0.07)], [PATCH], []
	n = 9
	spin = rnd.uniform(0, TAU)
	stretch = rnd.uniform(1.0, 1.35)
	inner, outer = [], []
	for k in range(n):
		a = spin + k / n * TAU
		r = size / 2 * rnd.uniform(0.72, 1.0)
		inner.append(len(verts))
		verts.append((math.cos(a) * r * 0.62 * stretch, math.sin(a) * r * 0.62, 0.07))
		vcol.append(PATCH)
	for k in range(n):
		a = spin + k / n * TAU
		r = size / 2 * rnd.uniform(0.72, 1.0)
		outer.append(len(verts))
		verts.append((math.cos(a) * r * stretch, math.sin(a) * r, 0.0))
		vcol.append(mix(PATCH, FLOOR, 0.85))
	for k in range(n):
		k2 = (k + 1) % n
		faces.append([0, inner[k], inner[k2]])
		faces.append([inner[k], outer[k], outer[k2], inner[k2]])
	finish(name, verts, faces, vcol=vcol, check=False)


# ---- make them --------------------------------------------------------------------------------------------------------
# round 4: faceted ridges (width, depth, height, grid, summits) for the hills' ring, the far land (width, depth, height)
ridge("IceRidge_1", 1101, 34.0, 22.0, 20.0, 8, 5, 3)
ridge("IceRidge_2", 1111, 36.0, 24.0, 22.0, 8, 5, 4)
ridge("IceRidge_3", 1121, 32.0, 20.0, 18.0, 7, 5, 3)
ridge("IceRidge_4", 1131, 38.0, 24.0, 21.0, 9, 5, 4)
ridge("IceRidge_5", 1141, 30.0, 20.0, 17.0, 7, 5, 3)
far_land("IceFar_1", 1201, 200.0, 70.0, 40.0)
far_land("IceFar_2", 1211, 210.0, 70.0, 38.0)
far_land("IceFar_3", 1221, 190.0, 66.0, 42.0)
# the rock landmarks (seed, masses, width, tallest)
cliff("IceCliff_1", 1301, 5, 24.0, 14.0)
cliff("IceCliff_2", 1311, 4, 21.0, 12.0)
cliff("IceCliff_3", 1321, 5, 23.0, 15.0)
cliff("IceCliff_4", 1331, 4, 19.0, 11.5)
# crystal clusters: hero (tall, spires), medium, small
hero("IceCrystalHero_1", 1401, 13.0, 5)
hero("IceCrystalHero_2", 1411, 14.0, 4)
hero("IceCrystalHero_3", 1421, 12.0, 4)
hero("IceCrystalHero_4", 1431, 13.0, 3)
hero("IceCrystalMid_1", 1441, 5.6, 4)
hero("IceCrystalMid_2", 1451, 6.2, 3)
hero("IceCrystalMid_3", 1461, 5.0, 4)
tiny_crystals("IceCrystalSmall_1", 1471, 2.6, 3)
tiny_crystals("IceCrystalSmall_2", 1481, 2.2, 4)
tiny_crystals("IceCrystalSmall_3", 1491, 2.8, 3)
# low snow banks (length, lumps) and frosted bushes
bank("IceBank_1", 1501, 9.0, 3)
bank("IceBank_2", 1511, 8.0, 3)
bank("IceBank_3", 1521, 10.0, 4)
bank("IceBank_4", 1531, 7.0, 2)
frost_bush("IceFrostBush_1", 1601, 3)
frost_bush("IceFrostBush_2", 1611, 3)
frost_bush("IceFrostBush_3", 1621, 4)
# faint frost patches on the floor (width)
patch("IcePatch_1", 1701, 11.0)
patch("IcePatch_2", 1711, 12.0)
patch("IcePatch_3", 1721, 10.0)
# the shore: snow drifts (2 or 3 lumps)
mound("IceMound_1", 101, 2)
mound("IceMound_2", 111, 3)
mound("IceMound_3", 121, 2)
mound("IceMound_4", 131, 3)
# pine groves (a snow mound and 3 or 4 frosted pines)
grove("IceGrove_1", 201, 4)
grove("IceGrove_2", 211, 3)
grove("IceGrove_3", 221, 4)
grove("IceGrove_4", 231, 3)
# heavy low slate masses (seed, boulders, tallest, crystal clumps pushing through)
ice_rock("IceRock_1", 301, 6, 9.0, 2)
ice_rock("IceRock_2", 311, 5, 8.0, 1)
ice_rock("IceRock_3", 321, 6, 9.5, 2)
ice_rock("IceRock_4", 331, 5, 8.5, 0)
# snow-capped boulders for the rim
boulder("IceBoulder_1", 401, (1.0, 0.9, 0.7), 0.16)
boulder("IceBoulder_2", 411, (1.25, 0.85, 0.6), 0.22)
boulder("IceBoulder_3", 421, (0.95, 1.0, 0.9), 0.18)
# crystal clusters (tall, count) and low sprouts (count)
crystal("IceCrystal_1", 501, 7.0, 5)
crystal("IceCrystal_2", 511, 8.5, 4)
crystal("IceCrystal_3", 521, 6.0, 5)
crystal("IceCrystal_4", 531, 9.0, 3)
shard("IceShard_1", 601, 4)
shard("IceShard_2", 611, 5)
shard("IceShard_3", 621, 3)
# twig corals and the shrubs
sprig("IceSprig_1", 701, 5.0)
sprig("IceSprig_2", 711, 5.6)
sprig("IceSprig_3", 721, 4.6)
shrub("IceShrub_1", 801, 4)
shrub("IceShrub_2", 811, 5)
# snow fences
fence("IceFence_1", 901, 3, False)
fence("IceFence_2", 911, 4, True)
fence("IceFence_3", 921, 2, False)
# the lake's cracks (length, forks)
crack("IceCrack_1", 1001, 11.0, 3)
crack("IceCrack_2", 1011, 12.0, 4)
crack("IceCrack_3", 1021, 8.0, 2)
crack("IceCrack_4", 1031, 10.0, 3)
