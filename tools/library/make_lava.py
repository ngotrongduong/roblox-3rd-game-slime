# Blender headless: Ember Lava's own low-poly props, made by script (no pack has them). Round 4 (the ChatGPT art-director
# review): the painting is a volcanic crater, so the rock is heavy, LOW, chunky basalt (clusters of big boulders with short thick
# hexagonal columns, terraced ledges, flat fracture plates on the floor) with only a few sharp peaks, and the lava is connected
# cracks (fissure systems with Y junctions) and pools with a burnt-rock bank. Each prop is ONE mesh whose colours are VERTEX
# colours (Roblox keeps those), origin at the middle of its foot, written as a small .glb into OUT_DIR with a preview picture,
# like make_grove.py does.
#
# The glowing pieces (names starting LavaFissure / LavaPool) carry their whole palette in vertex colour: hot core, orange body,
# a dark burnt bank. server/DungeonArena turns those two kinds Neon in WHITE (Config.Dungeon.Arenas.lava.Neon), so Roblox's
# vertex-colour multiply leaves the colours as painted and the Neon material makes them glow. Fissures lie along +X, thick end
# at -X. Rock colours are plain (no baked light or shine: the game's light does that) except that an upward-facing face is
# painted toward the stone highlight, which is what a shape reads by under a flat ambient light.
#   blender -b --factory-startup -P tools/library/make_lava.py -- <out_dir>
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


# Roblox shows a vertex colour as it is stored (it does not brighten linear values): a colour stored through a linear
# conversion renders near black (round 1 of the Lava play test), so every colour here is stored raw, as the colour wanted.
def raw(h):
	return tuple(int(h[i : i + 2], 16) / 255 for i in (1, 3, 5)) + (1.0,)


# the round-4 palette (the art director's): basalt clearly darker than the floor (#3F3A42), stone highlights on top faces,
# darker fracture plates, a burnt bank round the lava, lava body and core
BASALT = raw("#28262d")
BASALT_DARK = raw("#1f1d24")
BASALT_LIGHT = raw("#34313a")
STONE = raw("#48434b")
PLATE = raw("#302e35")
BANK = raw("#211a1d")
BODY = raw("#f15a20")
CORE = raw("#ffad3d")


def vary(base, rnd, amount=0.3):
	"""a base colour pushed a little toward the dark or the light, per piece"""
	t = rnd.uniform(-amount, amount)
	return mix(base, BASALT_LIGHT if t > 0 else BASALT_DARK, abs(t))


def finish(name, verts, faces, colour_of=None, vcol=None, check=True, shade=True):
	"""verts: list of (x, y, z) in Blender's Z-up; faces: lists of vertex indices (wound outward); colour_of(face_index) -> RGBA,
	or vcol[vertex_index] -> RGBA (the glowing pieces). `shade`: a face that looks up is painted toward the stone highlight."""
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
			c = colour_of(poly.index)
			if shade:
				up = max(0.0, poly.normal.z - 0.2) / 0.8
				c = mix(c, STONE, min(1.0, up) * 0.8)
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
	scene.world.color = (0.25, 0.2, 0.3)
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


# ---- chunky basalt: columns, boulder masses, ledges, plates ----------------------------------------------------------
def block_column(verts, faces, cols, cx, cy, r, h, rnd, base, jag=0.12):
	"""One short thick hexagonal column with a blunt, broken top: foot ring, shoulder ring, a top ring whose corners sit at
	different heights, and a top fan (30 triangles)."""
	n = 6
	spin = rnd.uniform(0, TAU / 6)
	starts = []
	for z, rm in ((0.0, 1.0), (h * 0.55, 1.05), (h, 0.97)):
		starts.append(len(verts))
		for k in range(n):
			a = k / n * TAU + spin
			dz = rnd.uniform(-jag, jag) * h if z == h else 0.0
			verts.append((cx + math.cos(a) * r * rm, cy + math.sin(a) * r * rm, z + dz))
	top = len(verts)
	verts.append((cx, cy, h + rnd.uniform(-jag, jag) * h * 0.5))
	for i in range(2):
		bridge(faces, starts[i], starts[i + 1], n)
		for _ in range(n):
			cols.append(vary(base, rnd, 0.22))
	for k in range(n):
		faces.append([starts[2] + k, starts[2] + (k + 1) % n, top])
		cols.append(vary(base, rnd, 0.3))


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


def rock_into(verts, faces, cols, cx, cy, sx, sy, sz, rough, rnd, base, levels=0, flat=0.35):
	"""A faceted rock: an icosphere stretched to (sx, sy, sz), roughened, its foot flattened and set on the ground at (cx, cy).
	Its top stands 2 - flat times sz high (levels 0 is 20 faces, 1 is 80)."""
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
		cols.append(vary(base, rnd, 0.3))


def mass(name, seed, boulders, columns, spread, hmax):
	"""A heavy low basalt cluster: `boulders` big rocks (6 to 12 wide, 4 to `hmax` high, the biggest in the middle) heaped
	together, and `columns` short thick hexagonal columns (2 to 4 wide, 3 to 7 tall) round their foot."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	base = vary(BASALT, rnd, 0.08)
	turn0 = rnd.uniform(0, TAU)
	for k in range(boulders):
		if k == 0:
			cx = cy = 0.0
			w = rnd.uniform(10.5, 12.0)
			h = hmax
		else:
			a = turn0 + k / (boulders - 1) * TAU + rnd.uniform(-0.35, 0.35)
			d = spread * rnd.uniform(0.55, 1.0)
			cx, cy = math.cos(a) * d, math.sin(a) * d
			w = rnd.uniform(6.0, 10.0)
			h = hmax * rnd.uniform(0.5, 0.85)
		rock_into(
			verts, faces, cols, cx, cy, w / 2 * rnd.uniform(0.95, 1.15), w / 2 * rnd.uniform(0.8, 1.0), h / 1.65, 0.2, rnd, base,
			levels=1 if k < 2 else 0, flat=0.35,
		)  # fmt: skip
	for k in range(columns):
		a = turn0 + (k + 0.5) / columns * TAU + rnd.uniform(-0.3, 0.3) + 0.5
		d = spread * rnd.uniform(1.05, 1.3)
		block_column(verts, faces, cols, math.cos(a) * d, math.sin(a) * d, rnd.uniform(1.0, 2.0), rnd.uniform(3.0, 7.0), rnd, base)
	finish(name, verts, faces, lambda i: cols[i])


def column_group(name, seed, count):
	"""A few short thick hexagonal columns standing together, blunt broken tops, and a chunk fallen at the foot."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	base = vary(BASALT, rnd, 0.08)
	for k in range(count):
		if k == 0:
			cx = cy = 0.0
			r, h = rnd.uniform(1.3, 1.6), rnd.uniform(5.5, 7.0)
		else:
			a = k / (count - 1) * TAU + rnd.uniform(-0.3, 0.3)
			d = rnd.uniform(2.6, 3.3)
			cx, cy = math.cos(a) * d, math.sin(a) * d
			r, h = rnd.uniform(1.0, 1.45), rnd.uniform(3.0, 5.5)
		block_column(verts, faces, cols, cx, cy, r, h, rnd, base, 0.14)
	rock_into(verts, faces, cols, 2.4, -2.9, 1.3, 1.1, 0.7, 0.25, rnd, base)
	finish(name, verts, faces, lambda i: cols[i])


def prism(verts, faces, cols, cx, cy, rad, squash, z0, h, rnd, base, sides=7):
	"""A flat slab with an irregular outline: foot ring at z0, top ring at z0 + h (a little smaller), a top fan."""
	spin = rnd.uniform(0, TAU)
	rs = [rad * rnd.uniform(0.78, 1.08) for _ in range(sides)]
	starts = []
	for z, shrink in ((z0, 1.0), (z0 + h, 0.93)):
		starts.append(len(verts))
		for k in range(sides):
			a = spin + k / sides * TAU
			verts.append((cx + math.cos(a) * rs[k] * shrink, cy + math.sin(a) * rs[k] * shrink * squash, z))
	top = len(verts)
	verts.append((cx, cy, z0 + h * 1.02))
	bridge(faces, starts[0], starts[1], sides)
	for _ in range(sides):
		cols.append(vary(base, rnd, 0.18))
	for k in range(sides):
		faces.append([starts[1] + k, starts[1] + (k + 1) % sides, top])
		cols.append(vary(base, rnd, 0.18))


def ledge(name, seed, tiers):
	"""A terraced basalt ledge, irregular, low: 2 to 5 studs high at 12 to 18 across."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	base = vary(BASALT, rnd, 0.08)
	z = 0.0
	for k in range(tiers):
		rad = 7.0 * (1 - 0.22 * k)
		h = (1.7, 1.3, 1.1)[k]
		prism(verts, faces, cols, rnd.uniform(-1, 1) * k, rnd.uniform(-1, 1) * k, rad, rnd.uniform(0.65, 0.85), z, h, rnd, base)
		z += h * 0.98
	finish(name, verts, faces, lambda i: cols[i])


def plate(name, seed):
	"""A broad low fracture plate lying on the floor, darker than the floor: 0.25 thick, irregular outline."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	prism(verts, faces, cols, 0, 0, 6.0, rnd.uniform(0.6, 0.85), 0.0, 0.25, rnd, PLATE, sides=8)
	finish(name, verts, faces, lambda i: cols[i], shade=False)


# ---- sharp peaks (a few landmarks) -------------------------------------------------------------------------------------
def spike(verts, faces, cols, cx, cy, r, h, lean, rnd, base, sides=5):
	"""One faceted shard: three rings narrowing to a point, the rings drifting along `lean` (25 triangles)."""
	shares = [(0.0, 1.0), (0.4, 0.7), (0.74, 0.38)]
	starts = []
	twist = rnd.uniform(0, TAU)
	for z, rm in shares:
		starts.append(len(verts))
		t = z
		for k in range(sides):
			a = twist + k / sides * TAU + rnd.uniform(-0.18, 0.18)
			rr = r * rm * rnd.uniform(0.88, 1.12)
			verts.append((cx + math.cos(a) * rr + lean[0] * t**1.4 * h, cy + math.sin(a) * rr + lean[1] * t**1.4 * h, z * h))
	apex = len(verts)
	verts.append((cx + lean[0] * h, cy + lean[1] * h, h))
	for i in range(2):
		bridge(faces, starts[i], starts[i + 1], sides)
		for _ in range(sides):
			cols.append(vary(base, rnd, 0.25))
	for k in range(sides):
		faces.append([starts[2] + k, starts[2] + (k + 1) % sides, apex])
		cols.append(vary(base, rnd, 0.3))


def peak(name, seed, shards, rubble):
	"""A landmark: a couple of tall sharp shards (x, y, radius, height, lean x, lean y) on a skirt of chunky rocks."""
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	base = vary(BASALT, rnd, 0.08)
	for x, y, r, h, lx, ly in shards:
		spike(verts, faces, cols, x, y, r, h, (lx, ly), rnd, base)
	for x, y, w, h in rubble:
		rock_into(verts, faces, cols, x, y, w / 2, w / 2 * rnd.uniform(0.8, 1.0), h / 1.65, 0.2, rnd, base)
	finish(name, verts, faces, lambda i: cols[i])


# ---- lava: fissures and pools ------------------------------------------------------------------------------------------
THICK = 0.3
BANK_W = 0.6


def ribbon(verts, faces, vcol, points, widths, top):
	"""A flat ribbon along a polyline of HALF widths: three vertices across the top (orange edge, hot middle, orange edge) and
	a dark burnt-rock bank sloping down to the ground on both sides."""
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
		for side, z, c, out in ((1, top, BODY, 0), (0, top, CORE, 0), (-1, top, BODY, 0), (1, 0.0, BANK, BANK_W), (-1, 0.0, BANK, BANK_W)):
			verts.append((px + nx * (w + out) * side, py + ny * (w + out) * side, z))
			vcol.append(c)
		rows.append(base)
	for i in range(n - 1):
		a, b = rows[i], rows[i + 1]
		# a: 0 left, 1 middle, 2 right (top), 3 left foot, 4 right foot; the travel direction is the ribbon's own
		faces.append([a + 2, b + 2, b + 1, a + 1])
		faces.append([a + 1, b + 1, b + 0, a + 0])
		faces.append([a + 4, b + 4, b + 2, a + 2])
		faces.append([b + 3, a + 3, a + 0, b + 0])
	a = rows[0]
	faces.append([a + 3, a + 4, a + 2, a + 0])


def crack(rnd, x, y, heading, seg, count, w_from, w_to, swing):
	"""A polyline of `count` angular segments of length `seg` from (x, y), the heading kinking at every joint; its half widths
	taper from w_from to w_to."""
	pts, wid = [(x, y)], [w_from]
	for i in range(1, count + 1):
		heading += rnd.uniform(-swing, swing)
		x += math.cos(heading) * seg
		y += math.sin(heading) * seg
		pts.append((x, y))
		wid.append(w_from + (w_to - w_from) * i / count)
	return pts, wid


def fissure(name, length, w0, seed, branches):
	"""One connected fissure system: a main channel along +X (thick at x = 0, tapering to a thin tip at x = length) in angular
	segments, with Y-junction branches 0.5 to 1.5 wide leaving it forward at 25 to 55 degrees and tapering to nothing."""
	rnd = random.Random(seed)
	verts, faces, vcol = [], [], []
	n = 6
	seg = length / n
	pts, wid = crack(rnd, 0.0, 0.0, 0.0, seg, n, w0, 0.18, 0.2)
	# keep the channel's end on the axis: the kinks only wobble it
	ribbon(verts, faces, vcol, pts, wid, THICK)
	slots = list(range(1, n - 1))
	rnd.shuffle(slots)
	for k in range(branches):
		i = slots[k % len(slots)]
		ox, oy = pts[i]
		side = 1 if k % 2 == 0 else -1
		base_heading = math.atan2(pts[i + 1][1] - oy, pts[i + 1][0] - ox)
		heading = base_heading + side * rnd.uniform(0.45, 0.95)
		count = rnd.choice((2, 3, 3))
		bpts, bwid = crack(rnd, ox, oy, heading, seg * rnd.uniform(0.7, 1.0), count, min(wid[i] * 0.55, 0.75), 0.22, 0.25)
		# a hair lower than the main crack so the two never fight where they cross
		ribbon(verts, faces, vcol, bpts, bwid, THICK * 0.8)
		if k == 0 and count >= 3:
			# a fork on the first branch: a Y of its own
			fx, fy = bpts[2]
			fh = math.atan2(bpts[3][1] - bpts[2][1], bpts[3][0] - bpts[2][0]) - side * rnd.uniform(0.7, 1.0)
			fpts, fwid = crack(rnd, fx, fy, fh, seg * 0.6, 2, 0.4, 0.2, 0.2)
			ribbon(verts, faces, vcol, fpts, fwid, THICK * 0.7)
	finish(name, verts, faces, vcol=vcol, check=False)


def pool(name, length, width, seed, pieces):
	"""A lava pool of 3 to 5 overlapping irregular pieces (a union of ellipses seen from their common middle), a hot core, an
	orange body, and a raised dark burnt-rock bank all round."""
	rnd = random.Random(seed)
	ells = []
	for _ in range(pieces):
		a = length / 2 * rnd.uniform(0.45, 0.7)
		b = width / 2 * rnd.uniform(0.5, 0.9)
		cx = rnd.uniform(-0.38, 0.38) * length / 2
		cy = rnd.uniform(-0.4, 0.4) * width / 2
		ells.append((cx, cy, a, b, rnd.uniform(-0.9, 0.9)))
	# the middle of the first piece sits at the origin so the union is star-shaped round it
	ells[0] = (0.0, 0.0, ells[0][2], ells[0][3], ells[0][4])
	n = 22

	def reach(theta):
		best = 0.0
		for cx, cy, a, b, rot in ells:
			dx, dy = math.cos(theta - rot), math.sin(theta - rot)
			ox = (-cx * math.cos(rot) - cy * math.sin(rot))
			oy = (cx * math.sin(rot) - cy * math.cos(rot))
			# solve |(t*d - c') / (a, b)| = 1 for t, d in the ellipse's frame
			A = (dx / a) ** 2 + (dy / b) ** 2
			B = 2 * (dx * ox / a**2 + dy * oy / b**2)
			C = (ox / a) ** 2 + (oy / b) ** 2 - 1
			disc = B * B - 4 * A * C
			if disc > 0 and C < 0:
				best = max(best, (-B + math.sqrt(disc)) / (2 * A))
		return best

	rs = [max(reach(k / n * TAU), 0.6) * rnd.uniform(0.96, 1.04) for k in range(n)]
	verts, faces, vcol = [(0.0, 0.0, THICK)], [], [CORE]
	rings = ((0.42, THICK, mix(CORE, BODY, 0.55), 0.0), (1.0, THICK, BODY, 0.0), (1.0, 0.55, BANK, 0.35), (1.0, 0.0, BANK, BANK_W + 0.4))
	starts = []
	for scale, z, c, out in rings:
		starts.append(len(verts))
		for k in range(n):
			a = k / n * TAU
			r = rs[k] * scale + out
			verts.append((math.cos(a) * r, math.sin(a) * r, z))
			vcol.append(c)
	for k in range(n):
		k2 = (k + 1) % n
		faces.append([0, starts[0] + k, starts[0] + k2])
		for i in range(3):
			faces.append([starts[i] + k, starts[i + 1] + k, starts[i + 1] + k2, starts[i] + k2])
	finish(name, verts, faces, vcol=vcol, check=False)


# ---- make them --------------------------------------------------------------------------------------------------------
# heavy low masses: the tallest piece is 8 to 9 studs, the cluster about twice that across
mass("LavaMass_1", 101, 6, 4, 8.0, 8.5)
mass("LavaMass_2", 111, 5, 5, 8.5, 7.5)
mass("LavaMass_3", 121, 7, 3, 7.5, 9.0)
mass("LavaMass_4", 131, 5, 6, 9.0, 8.0)
# short thick column groups
column_group("LavaStump_1", 401, 4)
column_group("LavaStump_2", 411, 5)
column_group("LavaStump_3", 421, 3)
# terraced ledges
ledge("LavaLedge_1", 501, 3)
ledge("LavaLedge_2", 511, 2)
ledge("LavaLedge_3", 521, 3)
# fracture plates for the floor
plate("LavaPlate_1", 601)
plate("LavaPlate_2", 611)
plate("LavaPlate_3", 621)
# round faceted boulders: radii (x, y, z) in a mass's own style, so one reads like the others
for k, (radii, rough, seed) in enumerate((((1.0, 0.9, 0.7), 0.16, 301), ((1.25, 0.85, 0.6), 0.22, 311), ((0.95, 1.0, 0.9), 0.18, 321))):
	rnd = random.Random(seed)
	verts, faces, cols = [], [], []
	rock_into(verts, faces, cols, 0, 0, radii[0], radii[1], radii[2], rough, rnd, vary(BASALT, rnd, 0.1), levels=1, flat=0.3)
	finish("LavaBoulder_%d" % (k + 1), verts, faces, lambda i: cols[i])
# sharp peaks (x, y, radius, height, lean x, lean y); the foot skirt (x, y, width, height)
peak("LavaPeak_1", 701, [(0, 0, 2.2, 10.0, 0.2, 0.08), (3.4, 1.2, 1.5, 6.4, -0.12, 0.15)], [(-2.5, -1.8, 4.0, 2.2), (2.2, -2.6, 3.4, 1.8), (4.5, 2.6, 3.0, 1.5)])
peak("LavaPeak_2", 711, [(0, 0, 2.0, 10.0, -0.22, 0.1), (-3.2, 1.4, 1.4, 5.6, 0.2, 0.0), (2.9, -1.6, 1.3, 4.2, 0.1, -0.1)], [(2.4, 2.2, 3.8, 2.0), (-2.4, -2.4, 3.2, 1.6)])
peak("LavaPeak_3", 721, [(0, 0, 2.3, 10.0, 0.08, -0.2), (3.0, -0.6, 1.6, 7.0, -0.2, 0.1)], [(-2.8, 1.6, 4.2, 2.4), (0.8, 3.2, 3.2, 1.6), (4.6, 1.8, 3.0, 1.4)])
# lava: fissure systems (thick end at -X; main channel length, half width at the thick end, seed, branches) and pools
fissure("LavaFissure_1", 24.0, 1.7, 801, 4)
fissure("LavaFissure_2", 26.0, 2.2, 811, 5)
fissure("LavaFissure_3", 22.0, 1.5, 821, 3)
fissure("LavaFissure_4", 28.0, 2.3, 831, 6)
pool("LavaPool_1", 14.0, 7.0, 901, 4)
pool("LavaPool_2", 11.0, 6.0, 911, 3)
pool("LavaPool_3", 13.0, 8.0, 921, 5)
pool("LavaPool_4", 9.5, 5.0, 931, 3)
