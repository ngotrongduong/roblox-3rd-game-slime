# Shared helpers of the seven Sunny Meadow monsters (tools/blender/monsters/<name>.py).
#
# One monster = a few rigid mesh PIECES (Body, Wing, Leg ...), each with its origin at its joint, all painted from ONE
# small palette (a 256 px texture of flat swatches, every face points at its swatch; no baked light: the game's light
# shades them). The geometry is written in the painting's own pixel frame (see Frame) so every constant is measured
# from the owner's painting or marked "inferred".
#
# Frame: Blender metres = Roblox studs, Z up, the monster faces -Y (the same FBX export as the slime body, so it
# faces Roblox's front -Z). Blender +X is the monster's OWN LEFT (the viewer's right when it faces the viewer); in
# Roblox mesh space that is -X. A piece named L is on the monster's left.
import importlib.util
import json
import math
import os

import bmesh
import bpy
import numpy as np
from mathutils import Vector

ROOT = "C:/Roblox 3rd game/"
ART = ROOT + "reference/goo-lineage-web/assets/"
OUT = ROOT + "art/models/monsters/"


# ---------------------------------------------------------------- files and images
def reset_scene():
	for ob in list(bpy.data.objects):
		bpy.data.objects.remove(ob, do_unlink=True)
	for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.images, bpy.data.cameras, bpy.data.lights):
		for d in list(coll):
			coll.remove(d)


def load_rgba(path):
	img = bpy.data.images.load(path, check_existing=False)
	w, h = img.size
	arr = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1].copy()
	bpy.data.images.remove(img)
	return arr  # row 0 = top, sRGB 0..1


def save_rgba(path, arr):
	h, w = arr.shape[:2]
	if arr.shape[2] == 3:
		arr = np.dstack([arr, np.ones((h, w), dtype=np.float32)])
	im = bpy.data.images.new("tmp_save", w, h, alpha=True)
	im.pixels.foreach_set(np.ascontiguousarray(arr[::-1], dtype=np.float32).ravel())
	im.filepath_raw = path
	im.file_format = "PNG"
	im.save()
	bpy.data.images.remove(im)


def hex_rgb(h):
	h = h.lstrip("#")
	return [int(h[i : i + 2], 16) / 255 for i in (0, 2, 4)]


# ---------------------------------------------------------------- the painting's frame
class Frame:
	"""Painting pixels -> Blender metres. W(px, py, d): x right, z up from the ground row gy, d = depth toward the
	viewer in px (the painting is a 3/4 view from above: a part nearer to the viewer is drawn lower, so its true
	height is raised by d * tan(el); el is an inferred 25 degrees unless the monster says otherwise)."""

	def __init__(self, scale, cx, gy, tan_el=0.46):
		self.s, self.cx, self.gy, self.t = scale, cx, gy, tan_el

	def W(self, px, py, d=0.0):
		s = self.s
		return Vector(((self.cx - px) * -s, -d * s, (self.gy - py) * s + d * s * self.t))

	def L(self, v):  # a length in px -> metres
		return v * self.s

	def P(self, v):  # a world point -> the painting pixel it is drawn at
		d = -v[1] / self.s
		return (self.cx + v[0] / self.s, self.gy - (v[2] - d * self.s * self.t) / self.s)


# ---------------------------------------------------------------- palette
def boost(rgb, sat=1.0, val=1.0):
	"""The paintings are bright and saturated and the game light only darkens: lift every mid colour a little (near
	black, near white and greys stay as they are)."""
	import colorsys

	h, s, v = colorsys.rgb_to_hsv(*rgb)
	if v < 0.22 or s < 0.08:
		return rgb
	return list(colorsys.hsv_to_rgb(h, min(1.0, s * sat), min(1.0, v * val + 0.02)))


class Palette:
	def __init__(self):
		self.names, self.rgb = [], {}

	def add(self, **cols):
		for k, v in cols.items():
			if k not in self.rgb:
				self.names.append(k)
			self.rgb[k] = boost(hex_rgb(v))

	def idx(self, name):
		return self.names.index(name)

	def uv(self, name):
		i = self.idx(name)
		return ((i % 8 + 0.5) / 8, 1 - (i // 8 + 0.5) / 8)

	def image_array(self):
		a = np.zeros((256, 256, 4), dtype=np.float32)
		a[..., 3] = 1
		a[:, :, :3] = 0.5
		for i, n in enumerate(self.names):
			r, c = divmod(i, 8)
			a[r * 32 : (r + 1) * 32, c * 32 : (c + 1) * 32, :3] = self.rgb[n]
		return a


# ---------------------------------------------------------------- geometry primitives (numpy in, numpy out)
def frame_matrix(axis, up=None):
	z = np.array(axis, float)
	z /= np.linalg.norm(z)
	u = np.array(up if up is not None else (0, 0, 1), float)
	if abs(np.dot(u / np.linalg.norm(u), z)) > 0.95:
		u = np.array((1.0, 0, 0)) if abs(z[0]) < 0.9 else np.array((0, 1.0, 0))
	x = u - np.dot(u, z) * z
	x /= np.linalg.norm(x)
	y = np.cross(z, x)
	return np.stack([x, y, z], axis=1)  # columns: local x, y, z in world


def euler_matrix(rot):
	rx, ry, rz = [math.radians(a) for a in rot]
	cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	mx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
	my = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
	mz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
	return mz @ my @ mx


def _v(p):
	return np.array([p[0], p[1], p[2]], float)


def prim_sphere(c, r, seg=12, rings=8, rot=None, fn=None):
	rx, ry, rz = r if isinstance(r, (tuple, list)) else (r, r, r)
	V = [(0, 0, rz)]
	for j in range(1, rings):
		ph = math.pi * j / rings
		rr, z = math.sin(ph), math.cos(ph) * rz
		for i in range(seg):
			th = 2 * math.pi * i / seg
			V.append((rx * rr * math.cos(th), ry * rr * math.sin(th), z))
	V.append((0, 0, -rz))
	V = np.array(V)
	if fn is not None:
		V = fn(V)
	if rot is not None:
		V = V @ euler_matrix(rot).T
	V = V + _v(c)
	F = [(0, 1 + i, 1 + (i + 1) % seg) for i in range(seg)]
	for j in range(rings - 2):
		a, b = 1 + j * seg, 1 + (j + 1) * seg
		for i in range(seg):
			i2 = (i + 1) % seg
			F.append((a + i, b + i, b + i2, a + i2))
	last, pole = 1 + (rings - 2) * seg, len(V) - 1
	F += [(pole, last + (i + 1) % seg, last + i) for i in range(seg)]
	return V, F


def prim_lathe(c, profile, seg=8, axis=(0, 0, 1), up=None, cap=True, fn=None):
	"""profile: [(radius, height)] from the base up; radius 0 at an end makes a pole, otherwise the end is capped."""
	M = frame_matrix(axis, up)
	V, F, rows = [], [], []
	for r, h in profile:
		if r <= 1e-9:
			rows.append(("pole", len(V)))
			V.append((0, 0, h))
		else:
			rows.append(("ring", len(V)))
			for i in range(seg):
				th = 2 * math.pi * i / seg
				V.append((r * math.cos(th), r * math.sin(th), h))
	for k in range(len(rows) - 1):
		(t0, a), (t1, b) = rows[k], rows[k + 1]
		for i in range(seg):
			i2 = (i + 1) % seg
			if t0 == "pole" and t1 == "ring":
				F.append((a, b + i, b + i2))
			elif t0 == "ring" and t1 == "pole":
				F.append((a + i, b, a + i2))
			elif t0 == "ring" and t1 == "ring":
				F.append((a + i, b + i, b + i2, a + i2))
	if cap:
		for end in (0, -1):
			t, a = rows[end]
			if t == "ring":
				z = profile[end][1]
				V.append((0, 0, z))
				pc = len(V) - 1
				F += [(pc, a + (i + 1) % seg, a + i) for i in range(seg)]
	V = np.array(V, float)
	if fn is not None:
		V = fn(V)
	return V @ M.T + _v(c), F


def prim_cone(base, tip, r, seg=5, r2=0.0):
	axis = _v(tip) - _v(base)
	h = float(np.linalg.norm(axis))
	prof = [(r, 0.0), (r2, h)] if r2 > 1e-9 else [(r, 0.0), (0.0, h)]
	return prim_lathe(base, prof, seg=seg, axis=axis, cap=True)


def prim_tube(path, radii, seg=6, caps=(True, True)):
	P = [_v(p) for p in path]
	n = len(P)
	T = []
	for k in range(n):
		a = P[min(k + 1, n - 1)] - P[max(k - 1, 0)]
		T.append(a / np.linalg.norm(a))
	ref = np.array((0, 0, 1.0))
	if abs(np.dot(ref, T[0])) > 0.95:
		ref = np.array((1.0, 0, 0))
	N = ref - np.dot(ref, T[0]) * T[0]
	N /= np.linalg.norm(N)
	V, F = [], []
	for k in range(n):
		if k > 0:  # parallel transport
			N = N - np.dot(N, T[k]) * T[k]
			N /= np.linalg.norm(N)
		B = np.cross(T[k], N)
		for i in range(seg):
			th = 2 * math.pi * i / seg
			V.append(P[k] + radii[k] * (math.cos(th) * N + math.sin(th) * B))
	for k in range(n - 1):
		for i in range(seg):
			i2 = (i + 1) % seg
			F.append((k * seg + i, (k + 1) * seg + i, (k + 1) * seg + i2, k * seg + i2))
	if caps[0]:
		V.append(P[0])
		F += [(len(V) - 1, (i + 1) % seg, i) for i in range(seg)]
	if caps[1]:
		V.append(P[-1])
		F += [(len(V) - 1, (n - 1) * seg + i, (n - 1) * seg + (i + 1) % seg) for i in range(seg)]
	return np.array(V), F


def leaf_width(t):
	return math.sin(math.pi * t ** 0.75) ** 0.85  # widest at t 0.4, round base, pointed tip


def leaf_broad(t):
	return math.sin(math.pi * t ** 0.62) ** 0.55  # a plump leaf: widest at t 0.4, still rounded at 0.7


def prim_leaf(base, axis, normal, L, Wd, bend=0.0, thick=None, K=4, fold=0.12, curl=0.0, wfn=None):
	"""A thin closed leaf: along `axis` for L, Wd wide, bent toward `normal` by `bend` (tip rise), a centre-rib fold.
	curl > 0 turns the tip over toward the normal even more (quadratic on top of bend)."""
	a = _v(axis)
	a /= np.linalg.norm(a)
	n = _v(normal)
	n = n - np.dot(n, a) * a
	n /= np.linalg.norm(n)
	s = np.cross(n, a)  # lateral
	thick = thick if thick is not None else 0.07 * Wd
	b = _v(base)
	wf = wfn or leaf_width
	rows = []
	for k in range(K + 1):
		t = k / K
		cen = b + a * (L * t) + n * (bend * t * t + curl * t ** 3)
		w = 0.5 * Wd * wf(t)
		rows.append((cen, w))
	V, idx = [], {}

	def add(key, p):
		idx[key] = len(V)
		V.append(p)

	for layer, off in ((0, thick / 2), (1, -thick / 2)):
		add((layer, 0, "c"), rows[0][0] + n * off)
		for k in range(1, K):
			cen, w = rows[k]
			for u, nm in ((-1, "l"), (0, "c"), (1, "r")):
				add((layer, k, nm), cen + s * (w * u) + n * (off + fold * w * (1 - abs(u))))
		add((layer, K, "c"), rows[K][0] + n * off)

	def ring(layer, k):
		return [(layer, 0, "c")] if k == 0 else [(layer, K, "c")] if k == K else [(layer, k, "l"), (layer, k, "c"), (layer, k, "r")]

	F = []
	for layer in (0, 1):
		for k in range(K):
			ra, rb = ring(layer, k), ring(layer, k + 1)
			if len(ra) == 1:
				F += [(idx[ra[0]], idx[rb[0]], idx[rb[1]]), (idx[ra[0]], idx[rb[1]], idx[rb[2]])]
			elif len(rb) == 1:
				F += [(idx[ra[0]], idx[ra[1]], idx[rb[0]]), (idx[ra[1]], idx[ra[2]], idx[rb[0]])]
			else:
				for j in range(2):
					F.append((idx[ra[j]], idx[rb[j]], idx[rb[j + 1]], idx[ra[j + 1]]))
	# the rim: left edge and right edge strips between the two layers
	edge_l = [(0, 0, "c")] + [(0, k, "l") for k in range(1, K)] + [(0, K, "c")]
	edge_r = [(0, 0, "c")] + [(0, k, "r") for k in range(1, K)] + [(0, K, "c")]
	for edge in (edge_l, edge_r):
		for k in range(len(edge) - 1):
			u0, u1 = edge[k], edge[k + 1]
			d0, d1 = (1,) + u0[1:], (1,) + u1[1:]
			F.append((idx[u0], idx[u1], idx[d1], idx[d0]))
	return np.array(V), F


def prim_disc_sheet(pts):
	"""A flat convex polygon as a fan (one side); the caller doubles it for two sides."""
	P = [_v(p) for p in pts]
	return np.array(P), [(0, i, i + 1) for i in range(1, len(P) - 1)]


# ---------------------------------------------------------------- closed-mesh orientation
def recalc(V, F):
	bm = bmesh.new()
	vs = [bm.verts.new(v) for v in V]
	bm.verts.index_update()
	for f in F:
		try:
			bm.faces.new([vs[i] for i in f])
		except ValueError:
			pass
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
	out = [tuple(lp.vert.index for lp in f.loops) for f in bm.faces]
	bm.free()
	return out


def face_data(V, F):
	cen, nor = [], []
	for f in F:
		p = V[list(f)]
		c = p.mean(0)
		nn = np.cross(p[1] - p[0], p[2] - p[0]) if len(f) >= 3 else np.zeros(3)
		if len(f) == 4:
			nn = np.cross(p[2] - p[0], p[3] - p[1])
		ln = np.linalg.norm(nn)
		cen.append(c)
		nor.append(nn / ln if ln > 1e-12 else np.array((0, 0, 1.0)))
	return np.array(cen), np.array(nor)


# ---------------------------------------------------------------- a piece = one mesh object with its joint origin
class Piece:
	def __init__(self, name, joint, motion=""):
		self.name, self.joint, self.motion = name, Vector(joint), motion
		self.V, self.F, self.C, self.S = [], [], [], []  # verts, faces, face colour names, face smooth flags

	def _push(self, V, F, col, smooth=True, closed=True, outward=None):
		V = np.asarray(V, float)
		if closed:
			F = recalc(V, F)
		cen, nor = face_data(V, F)
		if outward is not None and not closed:
			o = _v(outward)
			if float(np.mean(nor @ o)) < 0:
				F = [tuple(reversed(f)) for f in F]
				nor = -nor
		base = len(self.V)
		f0 = len(self.F)
		self.V += [tuple(v) for v in V]
		for k, f in enumerate(F):
			self.F.append(tuple(i + base for i in f))
			self.C.append(col(cen[k], nor[k]) if callable(col) else col)
			self.S.append(smooth)
		return (f0, len(self.F))

	# --- primitives
	def sphere(self, c, r, col, seg=12, rings=8, rot=None, fn=None, smooth=True):
		V, F = prim_sphere(c, r, seg, rings, rot, fn)
		return self._push(V, F, col, smooth)

	def lathe(self, c, profile, col, seg=8, axis=(0, 0, 1), up=None, cap=True, smooth=True, fn=None):
		V, F = prim_lathe(c, profile, seg, axis, up, cap, fn)
		return self._push(V, F, col, smooth)

	def cone(self, base, tip, r, col, seg=5, r2=0.0, smooth=False):
		V, F = prim_cone(base, tip, r, seg, r2)
		return self._push(V, F, col, smooth)

	def tube(self, path, radii, col, seg=6, caps=(True, True), smooth=True):
		V, F = prim_tube(path, radii, seg, caps)
		return self._push(V, F, col, smooth)

	def leaf(self, base, axis, normal, L, Wd, col, smooth=False, **kw):
		V, F = prim_leaf(base, axis, normal, L, Wd, **kw)
		return self._push(V, F, col, smooth=smooth)

	def dome(self, c, normal, r, h, col, seg=8, smooth=True, up=None, sx=1.0, sy=1.0):
		"""An open shallow dome (3 rings) facing `normal`: eyes, plates, spots stuck on a surface. sx stretches it
		along `up` (its local x), sy across."""
		n = _v(normal)
		n /= np.linalg.norm(n)
		sc = np.array((sx, sy, 1.0))
		V, F = prim_lathe(c, [(r, 0.0), (0.7 * r, 0.6 * h), (0.0, h)], seg, n, up, cap=False, fn=lambda V: V * sc)
		return self._push(V, F, col, smooth, closed=False, outward=n)

	def sheet(self, pts, col, double=True, smooth=False):
		V, F = prim_disc_sheet(pts)
		n = np.cross(V[1] - V[0], V[2] - V[0])
		r1 = self._push(V, F, col, smooth, closed=False, outward=n)
		if double:
			self._push(V, [tuple(reversed(f)) for f in F], col, smooth, closed=False, outward=-n)
		return r1

	def paint(self, rng, pred, col):
		"""Recolour the faces f0..f1 whose centre (world) and normal satisfy pred(c, n)."""
		V = np.array(self.V)
		for k in range(rng[0], rng[1]):
			f = self.F[k]
			cen, nor = face_data(V, [f])
			if pred(cen[0], nor[0]):
				self.C[k] = col

	def mirror(self, name, joint=None):
		q = Piece(name, joint if joint is not None else (-self.joint.x, self.joint.y, self.joint.z), self.motion)
		q.V = [(-x, y, z) for x, y, z in self.V]
		q.F = [tuple(reversed(f)) for f in self.F]
		q.C, q.S = list(self.C), list(self.S)
		return q

	def rotate_x(self, deg, pivot=(0, 0, 0)):
		"""Turns the whole piece (and its joint) about the X axis through pivot; + tips the +Y end up."""
		a = math.radians(deg)
		c, s = math.cos(a), math.sin(a)
		pv = _v(pivot)

		def f(p):
			q = _v(p) - pv
			return (q[0] + pv[0], q[1] * c - q[2] * s + pv[1], q[1] * s + q[2] * c + pv[2])

		self.V = [f(p) for p in self.V]
		self.joint = Vector(f(self.joint))

	def shift(self, d):
		d = _v(d)
		self.V = [(x + d[0], y + d[1], z + d[2]) for x, y, z in self.V]
		self.joint = self.joint + Vector(d)

	def zmin(self):
		return min(v[2] for v in self.V)

	def tris(self):
		return sum(len(f) - 2 for f in self.F)

	def to_object(self, pal, mat, prefix=""):
		o = self.joint
		me = bpy.data.meshes.new(prefix + self.name)
		me.from_pydata([(x - o.x, y - o.y, z - o.z) for x, y, z in self.V], [], self.F)
		uv = me.uv_layers.new(name="UVMap")
		for pi, poly in enumerate(me.polygons):
			u = pal.uv(self.C[pi])
			for li in poly.loop_indices:
				uv.data[li].uv = u
		me.polygons.foreach_set("use_smooth", self.S)
		me.update()
		ob = bpy.data.objects.new(prefix + self.name, me)
		bpy.context.scene.collection.objects.link(ob)
		ob.location = o
		me.materials.append(mat)
		return ob


# ---------------------------------------------------------------- shared shapes
def eye(p, c, n, r, sclera="cream", iris="amber", pupil="dark", glint="white", up=(0, 0, 1), seg=10, tall=1.35, tilt=0.0, h=None):
	"""A painted eye stuck on a surface: sclera rim, iris, pupil and a highlight, layered domes (about 110 triangles).
	tall stretches it along `up`; tilt turns it about the normal (degrees)."""
	n = _v(n)
	n /= np.linalg.norm(n)
	c = _v(c)
	u = _v(up) - np.dot(_v(up), n) * n
	u /= np.linalg.norm(u)
	if tilt:
		t = math.radians(tilt)
		u = u * math.cos(t) + np.cross(n, u) * math.sin(t)
	side = np.cross(n, u)
	h = h or 0.42 * r
	k = dict(up=u, sx=tall)
	p.dome(c, n, r, h, sclera, seg, **k)
	p.dome(c + n * 0.30 * h, n, 0.86 * r, h, iris, seg, **k)
	p.dome(c + n * 0.55 * h, n, 0.52 * r, h, pupil, seg, **k)
	p.dome(c + n * 1.0 * h + u * 0.30 * r - side * 0.14 * r, n, 0.19 * r, 0.3 * h, glint, 6)


def sq(r, n=2.5):
	"""A sphere-vertex function: pushes the unit sphere toward a superellipsoid of exponent n (n 2 = sphere, larger =
	fatter, more mochi-like) with radii r."""

	def f(V):
		u = V / np.array(r)
		k = (np.abs(u) ** n).sum(1, keepdims=True) ** (1 / n)
		k[k < 1e-9] = 1
		return (u / k) * np.array(r)

	return f


def on_surface(fr, c, r, px, py, n=2.0):
	"""The point of the front (-Y) surface of an axis-aligned superellipsoid (centre c, radii r, metres, exponent n)
	that the painting draws at pixel (px, py); the normal there. The depth of the point lifts it by tan(el)."""
	rx, ry, rz = r
	d = 0.0
	for _ in range(4):
		w = fr.W(px, py, d)
		dx, dz = (w.x - c[0]) / rx, (w.z - c[2]) / rz
		q = max(1 - abs(dx) ** n - abs(dz) ** n, 1e-4)
		dy = -(q ** (1 / n))
		d = -(c[1] + dy * ry) / fr.s
	p = np.array((c[0] + dx * rx, c[1] + dy * ry, c[2] + dz * rz))
	nn = np.array((math.copysign(abs(dx) ** (n - 1), dx) / rx, -(abs(dy) ** (n - 1)) / ry, math.copysign(abs(dz) ** (n - 1), dz) / rz))
	return Vector(p), Vector(nn / np.linalg.norm(nn))


def wing_pts(root, axis, width_dir, L, Wd, shape=None, n=7):
	"""Outline of a flat wing/leaf-shaped sheet from `root` along `axis` (length L, width Wd along width_dir)."""
	shape = shape or leaf_broad
	a = _v(axis)
	a /= np.linalg.norm(a)
	w = _v(width_dir) - np.dot(_v(width_dir), a) * a
	w /= np.linalg.norm(w)
	r = _v(root)
	side = [r + a * (L * k / n) + w * (0.5 * Wd * shape(k / n)) for k in range(1, n)]
	other = [r + a * (L * k / n) - w * (0.5 * Wd * shape(k / n)) for k in range(n - 1, 0, -1)]
	return [r] + side + [r + a * L] + other


def two_tone(top, bottom, normal):
	"""Face colour by side: `top` where the face looks along `normal`, else `bottom` (leaves: lit face and underside)."""
	n = _v(normal)
	n /= np.linalg.norm(n)
	return lambda c, nn: top if float(np.dot(nn, n)) >= 0 else bottom


# ---------------------------------------------------------------- building a monster from its script
def load_spec(path):
	spec = importlib.util.spec_from_file_location("monster_" + os.path.basename(path)[:-3], path)
	mod = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(mod)
	return mod


def make_material(pal, name, image):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	bsdf = m.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Roughness"].default_value = 0.55
	tex = m.node_tree.nodes.new("ShaderNodeTexImage")
	tex.image = image
	tex.interpolation = "Closest"
	m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
	m.use_backface_culling = True
	return m


def instantiate(mod, prefix="", out_dir=None):
	"""Builds the monster's pieces into the open scene; returns (objects, pieces, palette)."""
	pal = Palette()
	mod.palette(pal)
	pieces = mod.build(pal)
	arr = pal.image_array()
	out_dir = out_dir or (OUT + mod.SPEC["name"] + "/")
	os.makedirs(out_dir, exist_ok=True)
	png = out_dir + mod.SPEC["name"] + ".png"
	save_rgba(png, arr)
	img = bpy.data.images.load(png, check_existing=False)
	img.colorspace_settings.name = "sRGB"
	img.pack()
	mat = make_material(pal, mod.SPEC["name"], img)
	objs = [p.to_object(pal, mat, prefix) for p in pieces]
	return objs, pieces, pal


def world_bounds(objs):
	bpy.context.view_layer.update()
	pts = []
	for ob in objs:
		for v in ob.data.vertices:
			pts.append(ob.matrix_world @ v.co)
	a = np.array([(p.x, p.y, p.z) for p in pts])
	return a.min(0), a.max(0)


# ---------------------------------------------------------------- rendering
def setup_render(size, flat=False, bg=None):
	sc = bpy.context.scene
	sc.render.engine = "BLENDER_WORKBENCH"
	sc.render.film_transparent = True
	sc.render.resolution_x = sc.render.resolution_y = size
	sc.render.image_settings.file_format = "PNG"
	sc.render.image_settings.color_mode = "RGBA"
	sc.view_settings.view_transform = "Standard"
	sh = sc.display.shading
	sh.color_type = "TEXTURE"
	sh.light = "FLAT" if flat else "STUDIO"
	sh.show_object_outline = False
	try:  # a brighter studio light so the renders read like the game's daylight, not a dim room
		sh.studiolight_intensity = 1.5
	except AttributeError:
		pass
	sh.show_cavity = False
	sh.show_specular_highlight = not flat
	sc.display.render_aa = "8"


def make_cam(target, az, el, dist, lens=50, ortho=None):
	for ob in [o for o in bpy.data.objects if o.type == "CAMERA"]:
		bpy.data.objects.remove(ob, do_unlink=True)
	cd = bpy.data.cameras.new("Cam")
	cam = bpy.data.objects.new("Cam", cd)
	bpy.context.scene.collection.objects.link(cam)
	a, e = math.radians(az), math.radians(el)
	t = Vector(target)
	cam.location = t + Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))) * dist
	cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
	cd.lens = lens
	cd.clip_end = 500
	if ortho:
		cd.type = "ORTHO"
		cd.ortho_scale = ortho
	bpy.context.scene.camera = cam
	return cam


def render_arr(path, size, flat=False):
	setup_render(size, flat)
	bpy.context.scene.render.filepath = path
	bpy.ops.render.render(write_still=True)
	return load_rgba(path)


# ---------------------------------------------------------------- silhouette comparison (area and centroid normalised)
def mask_stats(m):
	ys, xs = np.nonzero(m)
	return dict(area=len(ys), cx=xs.mean(), cy=ys.mean(), x0=xs.min(), x1=xs.max(), y0=ys.min(), y1=ys.max())


def warp(img, st, size, fill=0.0, frac=0.22):
	"""Maps `img` (H x W x C) so its mask centroid is the canvas centre and its mask area is frac * size^2."""
	s = math.sqrt(frac * size * size / st["area"])
	yy, xx = np.mgrid[0:size, 0:size]
	sx = (xx - size / 2) / s + st["cx"]
	sy = (yy - size / 2) / s + st["cy"]
	h, w = img.shape[:2]
	ok = (sx >= 0) & (sx < w - 1) & (sy >= 0) & (sy < h - 1)
	out = np.full((size, size) + img.shape[2:], fill, dtype=img.dtype)
	out[ok] = img[sy[ok].astype(int), sx[ok].astype(int)]
	return out


def iou(a, b):
	u = (a | b).sum()
	return float((a & b).sum() / u) if u else 0.0


def over(rgba, bg=0.92):
	a = rgba[..., 3:4]
	return np.dstack([rgba[..., :3] * a + bg * (1 - a), np.ones(rgba.shape[:2] + (1,), dtype=np.float32)])


def overlap_img(ref_m, mod_m):
	h, w = ref_m.shape
	o = np.ones((h, w, 4), dtype=np.float32)
	o[..., :3] = 0.96
	o[ref_m & mod_m, :3] = 0.55
	o[ref_m & ~mod_m, :3] = (0.9, 0.15, 0.15)
	o[~ref_m & mod_m, :3] = (0.15, 0.3, 0.9)
	return o


def hstack(tiles, gap=6):
	h = max(t.shape[0] for t in tiles)
	out = []
	for i, t in enumerate(tiles):
		if t.shape[0] < h:
			t = np.vstack([t, np.ones((h - t.shape[0],) + t.shape[1:], dtype=np.float32)])
		out.append(t)
		if i < len(tiles) - 1:
			out.append(np.ones((h, gap, 4), dtype=np.float32))
	return np.hstack(out)


def vstack(tiles, gap=6):
	w = max(t.shape[1] for t in tiles)
	out = []
	for i, t in enumerate(tiles):
		if t.shape[1] < w:
			t = np.hstack([t, np.ones((t.shape[0], w - t.shape[1]) + t.shape[2:], dtype=np.float32)])
		out.append(t)
		if i < len(tiles) - 1:
			out.append(np.ones((gap, w, 4), dtype=np.float32))
	return np.vstack(out)


def shrink(img, size):
	"""Box-ish downscale of a square float image by an integer-ish factor (mean over blocks)."""
	h, w = img.shape[:2]
	f = max(1, h // size)
	hh, ww = (h // f) * f, (w // f) * f
	return img[:hh, :ww].reshape(hh // f, f, ww // f, f, img.shape[2]).mean((1, 3))


def fit_and_compare(mod, objs, tag, work, tile=400):
	"""Finds the camera (az, el) that best matches the painting's silhouette, then writes the comparison sheet.
	Returns the metrics dict."""
	spec = mod.SPEC
	paint = load_rgba(ART + spec["painting"])
	pm = paint[..., 3] > 0.5
	pst = mask_stats(pm)
	ref_c = warp(pm, pst, 256)
	lo, hi = world_bounds(objs)
	centre = (lo + hi) / 2
	R = float(np.linalg.norm(hi - lo)) / 2
	dist = R / math.sin(math.atan(18 / spec.get("lens", 50))) * 1.05
	azs = spec.get("az_range", range(-40, 41, 10))
	els = spec.get("el_range", range(0, 46, 7))
	best = (-1, 0, 0)
	if "cam" in spec:  # the painting's view is known (the monster's pose is built to it): no search
		azs, els = [spec["cam"][0]], [spec["cam"][1]]
	for az in azs:
		for el in els:
			make_cam(centre, az, el, dist, spec.get("lens", 50))
			a = render_arr(work + "fit.png", 192)
			mm = a[..., 3] > 0.5
			if mm.sum() < 50:
				continue
			sc = iou(ref_c, warp(mm, mask_stats(mm), 256))
			if sc > best[0]:
				best = (sc, az, el)
	sc, az, el = best
	make_cam(centre, az, el, dist, spec.get("lens", 50))
	studio = render_arr(work + "studio.png", 768)
	flat = render_arr(work + "flat.png", 768, flat=True)
	# the "lit" look: half the studio shading over the true palette (Workbench's studio light alone is a dim room;
	# the game's daylight keeps the painting's saturated colours)
	studio = studio.copy()
	studio[..., :3] = np.clip(0.2 * studio[..., :3] + 0.8 * flat[..., :3], 0, 1)
	mm = studio[..., 3] > 0.5
	mst = mask_stats(mm)
	# world proportions: the painting's bbox aspect vs the render's
	asp_p = (pst["x1"] - pst["x0"]) / (pst["y1"] - pst["y0"])
	asp_m = (mst["x1"] - mst["x0"]) / (mst["y1"] - mst["y0"])
	S = 2 * tile
	paint_w = warp(paint, pst, S)
	studio_w, flat_w = warp(studio, mst, S), warp(flat, mst, S)
	ref_s, mod_s = warp(pm, pst, S), warp(mm, mst, S)
	pr = shrink(over(paint_w), tile)
	tiles = [pr, shrink(over(studio_w), tile), shrink(over(flat_w), tile), shrink(overlap_img(ref_s, mod_s), tile)]
	save_rgba(work + "sheet_%s.png" % tag, hstack(tiles))
	return dict(iou=round(iou(ref_s, mod_s), 4), az=az, el=el, aspect_painting=round(asp_p, 3), aspect_render=round(asp_m, 3),
		aspect_err_pct=round(100 * (asp_m / asp_p - 1), 1), sheet=work + "sheet_%s.png" % tag, aligned_render=studio_w,
		aligned_flat=flat_w, aligned_paint=paint_w)


def turn_sheet(objs, path, views=((0, 12), (-45, 22), (-90, 12), (180, 12), (45, 22), (0, 80)), size=300, lens=50, flat=True):
	"""Front, 3/4, side, back and top of the model in one row (the sides and back are INFERRED, this is for checking)."""
	lo, hi = world_bounds(objs)
	centre = (lo + hi) / 2
	R = float(np.linalg.norm(hi - lo)) / 2
	dist = R / math.sin(math.atan(18 / lens)) * 1.05
	tiles = []
	for az, el in views:
		make_cam(centre, az, el, dist, lens)
		a = render_arr(path[:-4] + "_tmp.png", size, flat=flat)
		tiles.append(over(a))
	save_rgba(path, hstack(tiles))


# ---------------------------------------------------------------- export
def export_fbx(objs, path):
	fbx = dict(use_selection=True, object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
		apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True,
		bake_space_transform=False, add_leaf_bones=False, primary_bone_axis="Y", secondary_bone_axis="X",
		bake_anim=False, mesh_smooth_type="FACE", use_mesh_modifiers=False, use_tspace=False, path_mode="COPY",
		embed_textures=True)
	bpy.ops.object.select_all(action="DESELECT")
	for ob in objs:
		ob.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.export_scene.fbx(filepath=path, **fbx)


def run(modpath, tag="r1"):
	"""The per-monster entry point: build, compare with the painting, export, write the numbers."""
	import sys

	if "--" in sys.argv and len(sys.argv) > sys.argv.index("--") + 1:
		tag = sys.argv[sys.argv.index("--") + 1]
	mod = load_spec(modpath)
	name = mod.SPEC["name"]
	reset_scene()
	out_dir = OUT + name + "/"
	os.makedirs(out_dir + "review/", exist_ok=True)
	objs, pieces, pal = instantiate(mod, "", out_dir)
	work = out_dir + "review/"
	m = fit_and_compare(mod, objs, tag, work)
	turn_sheet(objs, work + "views_%s.png" % tag)
	tris = sum(p.tris() for p in pieces)
	lo, hi = world_bounds(objs)
	info = dict(name=name, painting=mod.SPEC["painting"], kind=mod.SPEC["kind"], tris=tris,
		size_xyz=[round(float(hi[i] - lo[i]), 3) for i in range(3)], bbox_min=[round(float(x), 3) for x in lo],
		bbox_max=[round(float(x), 3) for x in hi], target_height=mod.SPEC["height"], colours=len(pal.names),
		pieces=[dict(name=p.name, joint=[round(p.joint.x, 3), round(p.joint.y, 3), round(p.joint.z, 3)], tris=p.tris(),
			motion=p.motion) for p in pieces])
	for k in ("iou", "az", "el", "aspect_painting", "aspect_render", "aspect_err_pct", "sheet"):
		info[k] = m[k]
	export_fbx(objs, out_dir + name + ".fbx")
	with open(out_dir + name + ".json", "w") as f:
		json.dump(info, f, indent=1)
	save_rgba(out_dir + "review/aligned_render.png", m["aligned_render"])
	save_rgba(out_dir + "review/aligned_paint.png", m["aligned_paint"])
	print("[monster] %s: tris %d (budget %s), height %.2f (target %.1f), pieces %d, IoU %.3f at az %d el %d, aspect err %.1f%%"
		% (name, tris, mod.SPEC["budget"], hi[2] - lo[2], mod.SPEC["height"], len(pieces), m["iou"], m["az"], m["el"], m["aspect_err_pct"]))
	return info
