# Rigs, skins and animates one region's monster slimes (the seven objects of art/models/monster_slimes/<region>/<region>.blend,
# cut out by monster_split.py): each gets a triangle budget (collapse decimation, UVs kept), an armature whose jelly body is
# a CAGE of bones (Body low, Top high, Front/Back/Left/Right on the equator: Roblox's Bone.Transform has no scale, so squash
# and stretch are made by MOVING these bones), the monster's own bones at joints measured on the mesh (texture colour under
# each vertex, islands, slices along an axis, angle clusters round a flower's axis), weights (jelly smooth across the cage,
# hard parts rigid on their bone, at most 4 influences) and five actions written as functions of time (Idle, Move, Attack,
# Hit, Die). Writes <Name>/<Name>.fbx per monster, <region>_rigged.blend, and review tiles that tools/blender/monster_rig_sheets.py
# turns into review/<Name>_poses.png, <Name>_weights.png, <Name>_motion.gif and <region>_idle.gif.
# Never edits <region>.blend. Every motion is in model axes (Blender: x the monster's left, -y its front, z up), each bone's
# move relative to its parent, so it ports to the game's Bone.Transform (see the region's MOTION.md).
# Run: tools/blender/monster_rig.ps1 [region] [Name+Name|all] [full|weights|norender]
import bpy, math, os, sys, json, tempfile
import numpy as np
from mathutils import Matrix, Vector, Quaternion
from mathutils.bvhtree import BVHTree

ARGS = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
REGION = ARGS[0] if len(ARGS) > 0 and ARGS[0] else "meadow"
ONLY = None if len(ARGS) < 2 or ARGS[1] in ("", "all") else ARGS[1].split("+")
MODE = ARGS[2] if len(ARGS) > 2 and ARGS[2] else "full"
DIR = "C:/Roblox 3rd game/art/models/monster_slimes/" + REGION
TILES = os.path.join(tempfile.gettempdir(), "monster_rig", REGION).replace(chr(92), "/")
FPS = 30
TAU = 2 * math.pi
os.makedirs(TILES, exist_ok=True)


# ---------------------------------------------------------------- small maths
def clamp(x, a=0.0, b=1.0):
	return a if x < a else b if x > b else x


def sstep(a, b, x):
	t = clamp((x - a) / (b - a))
	return t * t * (3 - 2 * t)


def keys(t, ks):
	"""Smooth (zero slope at each key) interpolation through [(time, value), ...]."""
	if t <= ks[0][0]:
		return ks[0][1]
	for (t0, v0), (t1, v1) in zip(ks, ks[1:]):
		if t <= t1:
			return v0 + (v1 - v0) * sstep(t0, t1, t)
	return ks[-1][1]


def ring(t, t0, amp, f, z):
	"""A damped spring set ringing at t0 (starts at 0 with speed, decays): overshoot and settle."""
	if t <= t0:
		return 0.0
	u = t - t0
	w = TAU * f
	return amp * math.exp(-z * w * u) * math.sin(w * math.sqrt(1 - z * z) * u)


def settle(t, t0, amp, f, z):
	"""A damped spring let go at t0 from amp (starts at amp with no speed, swings through 0, settles)."""
	if t <= t0:
		return amp
	u = t - t0
	w = TAU * f
	wd = w * math.sqrt(1 - z * z)
	return amp * math.exp(-z * w * u) * (math.cos(wd * u) + z / math.sqrt(1 - z * z) * math.sin(wd * u))


def hump(t, a, b):
	"""0 -> 1 -> 0 between a and b, smooth at both ends."""
	if t <= a or t >= b:
		return 0.0
	return math.sin(math.pi * (t - a) / (b - a)) ** 2


def periodic(fn, T, n=4):
	"""A one-shot channel fn (rest before 0, settles by itself) made into a loop of period T that joins with no jump:
	the tails of the earlier cycles are added in."""
	return lambda t: sum(fn((t % T) + k * T) for k in range(n))


def qaxis(axis, ang):
	return Quaternion(Vector(axis).normalized(), ang)


def qeul(x=0.0, y=0.0, z=0.0):
	return (qaxis((0, 0, 1), z) @ qaxis((0, 1, 0), y) @ qaxis((1, 0, 0), x))


# ---------------------------------------------------------------- the monster table
# per monster: triangle budget, hover height (flyers float above their ground centre), the rig function and the motion
# function (below). Other regions add rows here.
MONSTERS = {}
MEADOW = ("Burrling", "Stinglob", "Gapebloom", "Sapcaller", "Barkhide", "Rotbloom", "Bramblehorn")
MOTION_FNS = {}  # name -> fn(r) -> (actions, peak): the regions after the Meadow
EXTREMES = {}  # name -> [(label, c, d), ...]


def monster(name, budget, hover=0.0, role="melee", nocage=False, mid=False, pre=None):
	"""nocage: the body is a spine chain (no Top/Front/Back/Left/Right); mid: a Mid cage bone so a column bends;
	pre: fn(ob) that edits the decimated mesh before it is measured (a clean cut)."""

	def deco(fn):
		MONSTERS[name] = dict(budget=budget, hover=hover, role=role, rig=fn, nocage=nocage, mid=mid, pre=pre)
		return fn

	return deco


# ---------------------------------------------------------------- the mesh, measured
class Mesh:
	def __init__(self, ob, px):
		me = ob.data
		self.ob = ob
		n = len(me.vertices)
		self.n = n
		co = np.empty(n * 3)
		me.vertices.foreach_get("co", co)
		self.co = co.reshape(n, 3)
		nor = np.empty(n * 3)
		me.vertices.foreach_get("normal", nor)
		self.nor = nor.reshape(n, 3)
		e = np.empty(len(me.edges) * 2, dtype=np.int64)
		me.edges.foreach_get("vertices", e)
		self.edges = e.reshape(-1, 2)
		self.adj = [[] for _ in range(n)]
		for a, b in self.edges:
			self.adj[a].append(b)
			self.adj[b].append(a)
		# the texture colour under each vertex (mean over its corners)
		H, W = px.shape[:2]
		uv = np.empty(len(me.loops) * 2)
		me.uv_layers.active.data.foreach_get("uv", uv)
		uv = uv.reshape(-1, 2)
		lv = np.empty(len(me.loops), dtype=np.int64)
		me.loops.foreach_get("vertex_index", lv)
		xs = np.clip((uv[:, 0] % 1.0 * W).astype(int), 0, W - 1)
		ys = np.clip((uv[:, 1] % 1.0 * H).astype(int), 0, H - 1)
		rgb = px[ys, xs, :3]
		col = np.zeros((n, 3))
		np.add.at(col, lv, rgb)
		cnt = np.bincount(lv, minlength=n)
		self.rgb = col / np.maximum(cnt, 1)[:, None]
		r, g, b = self.rgb.T
		mx, mn = self.rgb.max(1), self.rgb.min(1)
		d = np.maximum(mx - mn, 1e-5)
		self.hue = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
		self.sat = (mx - mn) / np.maximum(mx, 1e-4)
		self.val = mx
		self.island = self.components(np.ones(n, bool))
		sizes = np.bincount(self.island)
		self.main = int(np.argmax(sizes))
		self._thick = None

	def components(self, mask):
		"""Connected pieces of the mesh inside mask (label per vertex, -1 outside)."""
		lab = np.full(self.n, -1)
		c = 0
		for s in np.nonzero(mask)[0]:
			if lab[s] >= 0:
				continue
			lab[s] = c
			st = [s]
			while st:
				x = st.pop()
				for y in self.adj[x]:
					if mask[y] and lab[y] < 0:
						lab[y] = c
						st.append(y)
			c += 1
		return lab

	def thickness(self):
		"""How far a ray goes inward from each vertex before it leaves the body (thin vines and thorns are small)."""
		if self._thick is None:
			bvh = BVHTree.FromObject(self.ob, bpy.context.evaluated_depsgraph_get())
			t = np.full(self.n, 9.0)
			for i in range(self.n):
				p, nv = Vector(self.co[i]), Vector(self.nor[i])
				hit = bvh.ray_cast(p - nv * 0.002, -nv, 9.0)
				if hit[0] is not None:
					t[i] = hit[3]
			self._thick = t
		return self._thick

	def rings(self, seed, k):
		"""Graph distance (in edges, up to k) from the seed vertices; k+1 beyond."""
		dist = np.full(self.n, k + 1)
		front = list(np.nonzero(seed)[0])
		dist[front] = 0
		for r in range(1, k + 1):
			nxt = []
			for x in front:
				for y in self.adj[x]:
					if dist[y] > r:
						dist[y] = r
						nxt.append(y)
			front = nxt
		return dist

	def geodesic(self, src, limit=99.0):
		"""Distance along the surface (edge lengths) from vertex src, up to limit."""
		import heapq
		d = np.full(self.n, np.inf)
		d[src] = 0
		h = [(0.0, src)]
		while h:
			dd, x = heapq.heappop(h)
			if dd > d[x] or dd > limit:
				continue
			for y in self.adj[x]:
				nd = dd + float(np.linalg.norm(self.co[x] - self.co[y]))
				if nd < d[y]:
					d[y] = nd
					heapq.heappush(h, (nd, y))
		return d

	def protrusion(self, tip, step, label, grow=2.6, start=4):
		"""A horn-like part grown from its tip along the surface: each step adds a ring of vertices; the base is where a
		ring suddenly gets much bigger than the shaft's rings (the part meets the body). Returns (mask, geodesic, base)."""
		g = self.geodesic(tip, 12.0)
		counts = []
		for k in range(1, 200):
			c = int(((g >= (k - 1) * step) & (g < k * step)).sum())
			counts.append(c)
			if k > start and c > grow * np.median(counts[1:-1]) and c > 6:
				break
		G = (len(counts) - 1) * step
		print(f"PROFILE {label} ring sizes from the tip every {step}: {counts} -> base at {G:.2f}")
		return g < G, g, G

	def box(self, mask):
		p = self.co[mask]
		return p.min(0).round(2).tolist(), p.max(0).round(2).tolist()


def pca(p):
	c = p.mean(0)
	w, v = np.linalg.eigh(np.cov((p - c).T))
	return c, v[:, ::-1].T, w[::-1]  # centre, axes (largest first), spread


def ang_clusters(ang, k_min=3, bins=72, smooth=2):
	"""Peaks of a circular histogram of angles: one per petal."""
	h = np.histogram(ang % TAU, bins=bins, range=(0, TAU))[0].astype(float)
	ker = np.exp(-0.5 * (np.arange(-3 * smooth, 3 * smooth + 1) / smooth) ** 2)
	hs = np.array([sum(h[(i + j) % bins] * ker[j + 3 * smooth] for j in range(-3 * smooth, 3 * smooth + 1)) for i in range(bins)])
	peaks = [i for i in range(bins) if hs[i] > hs[i - 1] and hs[i] >= hs[(i + 1) % bins] and hs[i] > 0.25 * hs.max()]
	return [(i + 0.5) * TAU / bins for i in peaks], hs


def angdiff(a, b):
	return (a - b + math.pi) % TAU - math.pi


# ---------------------------------------------------------------- parts: each returns bones and weights
# A part: dict(name, parent, head, tail, w (per vertex 0..1)). The cage takes whatever the parts leave.
def part(name, parent, head, w, tail=None, length=0.4):
	head = Vector(head)
	return dict(name=name, parent=parent, head=head, tail=Vector(tail) if tail is not None else head + Vector((0, 0, length)), w=w)


def soften(m, w, k=2, keep=None):
	"""Lets a rigid part's weight fade over k rings into the jelly next to it, so the seam stretches and never tears."""
	d = m.rings(w >= 0.999, k)
	fade = np.clip(1 - d / (k + 1), 0, 1)
	if keep is not None:
		fade = fade * keep
	return np.maximum(w, fade)


def hats(u, n):
	"""Weights of n chain bones from a chain parameter u (bone k spans u in [k, k+1]): full on a bone at its middle,
	linear blend to the next, the ends held."""
	W = np.zeros((len(u), n))
	for k in range(n):
		c = k + 0.5
		w = np.clip(1 - np.abs(u - c), 0, 1)
		if k == 0:
			w = np.where(u < c, 1.0, w)
		if k == n - 1:
			w = np.where(u > c, 1.0, w)
		W[:, k] = w
	return W / np.maximum(W.sum(1), 1e-9)[:, None]


def geo_chain(m, sel, base_pt, names, parent, fade=0.15, label=""):
	"""A bending part (a wick, a curled tip, a stalk) as a chain of bones laid along the surface from its base: each
	vertex's chain parameter is its distance along the surface from the base point; joints are the middles of the
	vertices at each step; the base fades into the parent over the first `fade` of the length.
	Returns (parts, total weight)."""
	idx = np.nonzero(sel)[0]
	base_i = int(idx[np.argmin(np.linalg.norm(m.co[idx] - np.array(base_pt), axis=1))])
	g = m.geodesic(base_i, 40.0)
	G = float(np.percentile(g[sel], 99))
	n = len(names)
	u = np.clip(g / G * n, 0, n)
	J = [np.array(base_pt, float)]
	for k in range(1, n + 1):
		band = sel & (np.abs(g - k * G / n) < 0.1 * G) if k < n else sel & (g > 0.88 * G)
		J.append(m.co[band].mean(0) if band.any() else J[-1])
	Wh = hats(u, n)
	tot = np.where(sel, np.array([sstep(0, fade * n, x) for x in u]), 0.0)
	parts = []
	for k, nm in enumerate(names):
		pp = part(nm, parent if k == 0 else names[k - 1], J[k], Wh[:, k] * tot, tail=J[k + 1])
		pp["seg"] = Vector(J[k + 1] - J[k])
		parts.append(pp)
	print(f"CHAIN {label} length {G:.2f} joints {[np.round(j, 2).tolist() for j in J]}")
	return parts, tot


def axis_chain(m, sel, a, s_joints, names, parent, fade=0.4, label=""):
	"""A chain along a straight axis a (a tail, a mane, a spine): joints at the parameters s_joints (s = (co - o).a,
	o the origin of the axis), each joint the middle of the vertices of its slice; weights blend between joints; the
	first joint fades in over `fade` studs before it (fade 0: everything in sel before the first joint is on bone 1)."""
	a = np.array(a, float)
	a /= np.linalg.norm(a)
	s = m.co @ a
	n = len(names)
	J = []
	for sj in s_joints:
		band = sel & (np.abs(s - sj) < 0.25)
		if band.sum() < 3:
			band = sel & (np.abs(s - sj) < 0.6)
		J.append(m.co[band].mean(0))
	# chain parameter: piecewise linear in s through the joints
	u = np.interp(s, s_joints, np.arange(len(s_joints)), left=-1.0, right=float(n))
	Wh = hats(np.clip(u, 0, n), n)
	if fade > 0:
		tot = np.where(sel, np.array([sstep(s_joints[0] - fade, s_joints[0], x) for x in s]), 0.0)
	else:
		tot = sel.astype(float)
	parts = []
	for k, nm in enumerate(names):
		pp = part(nm, parent if k == 0 else names[k - 1], J[k], Wh[:, k] * tot, tail=J[k + 1] if k + 1 < len(J) else None)
		pp["seg"] = Vector(J[k] - J[k - 1]) if k > 0 else Vector((0, 0, 0))
		parts.append(pp)
	print(f"CHAIN {label} along {np.round(a, 2).tolist()} joints {[np.round(j, 2).tolist() for j in J]}")
	return parts, tot


def zprof(m, sel, cx, cy, zs, half=0.06, q=90):
	r = np.hypot(m.co[:, 0] - cx, m.co[:, 1] - cy)
	out = []
	for z in zs:
		b = sel & (np.abs(m.co[:, 2] - z) < half)
		out.append(float(np.percentile(r[b], q)) if b.sum() > 3 else 0.0)
	return np.array(out)


def side_of(m, c):
	"""The cage bone a hard piece at c rides: Top above the body's middle height, else the equator bone it lies toward."""
	lo, hi = m.co.min(0), m.co.max(0)
	mid = (lo + hi) / 2
	d = np.array(c) - mid
	ext = (hi - lo) / 2
	if d[2] > 0.25 * ext[2] * 2 and abs(d[0]) / ext[0] < 0.55 and abs(d[1]) / ext[1] < 0.55:
		return "Top"
	if abs(d[0]) / ext[0] > abs(d[1]) / ext[1]:
		return "Left" if d[0] > 0 else "Right"
	return "Front" if d[1] < 0 else "Back"


def _lohi(m, sel):
	p = m.co[sel]
	lo, hi = np.percentile(p, 3, axis=0), np.percentile(p, 97, axis=0)
	return lo, hi, (lo + hi) / 2


def _root_tip(m, sel, body):
	"""A loose piece's root (its points nearest the body) and tip (its point farthest from the root)."""
	p = m.co[sel]
	bp = m.co[body]
	d = np.array([np.min(np.linalg.norm(bp - q, axis=1)) for q in p])
	root = p[d <= np.percentile(d, 15)].mean(0)
	tip = p[np.argmax(np.linalg.norm(p - root, axis=1))]
	return root, tip


def _A(Ti, idle, p_idle, Tm, move, p_move, Ta, attack, p_attack, Th, hit, p_hit, Td, die, p_die):
	return dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(Ta, False, attack, p_attack),
		Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))


def _end(t):
	return 1 - sstep(0.28, 0.4, t)


def _with(fn, **extra):
	"""A body action with extra channels added: extra[name] = fn(t)."""
	def f(t):
		c, d = fn(t)
		c = dict(c)
		for k, e in extra.items():
			c[k] = c.get(k, 0.0) + e(t)
		return c, d
	return f


def onto(name, w):
	"""Weights onto an EXISTING bone (a cage bone or another part's bone): a rigid piece riding it."""
	return dict(name=name, existing=True, w=w)


def flower(m, sel, n_petals, parent, stem_name, inner, label):
	"""A flower head (sel): its axis is the normal of the petal disc, a stem bone at its base, one bone per petal at the
	petal's hinge (petals found as peaks of the angle histogram round the axis); petal weight ramps from 0 at the hinge
	radius to 1 a little further out, the rest of the head rigid on the stem."""
	p = m.co[sel]
	c, ax, sp = pca(p)
	nrm = ax[2] if ax[2][2] > 0 else -ax[2]
	u = ax[0] - nrm * np.dot(ax[0], nrm)
	u /= np.linalg.norm(u)
	v = np.cross(nrm, u)
	# the centre: the middle of the head's extent in its own plane (a mean leans toward wherever the mesh is dense)
	pu, pv = (p - c) @ u, (p - c) @ v
	c = c + u * (np.percentile(pu, 2) + np.percentile(pu, 98)) / 2 + v * (np.percentile(pv, 2) + np.percentile(pv, 98)) / 2
	rel = m.co - c
	hgt = rel @ nrm
	rad_v = rel - np.outer(hgt, nrm)
	r = np.linalg.norm(rad_v, axis=1)
	ang = np.arctan2(rad_v @ v, rad_v @ u)
	rmax = np.percentile(r[sel], 98)
	r_in = inner * rmax
	# the petals: the head's outline radius round the axis dips at each notch between two petals; the n deepest dips
	# (or every dip below 85% of the outline) cut the head into petal sectors
	B = 90
	bi = ((ang % TAU) / TAU * B).astype(int) % B
	outline = np.zeros(B)
	for b in range(B):
		s = sel & (bi == b)
		outline[b] = np.percentile(r[s], 97) if s.sum() > 1 else 0
	outline = np.array([np.mean([outline[(b + j) % B] for j in (-1, 0, 1)]) for b in range(B)])
	dips = [b for b in range(B) if outline[b] < outline[b - 1] and outline[b] <= outline[(b + 1) % B]]
	# a dip's depth: how far it sits below the lower of the highest points on either side within 40 degrees
	def depth(b):
		left = max(outline[(b - j) % B] for j in range(1, 11))
		right = max(outline[(b + j) % B] for j in range(1, 11))
		return min(left, right) - outline[b]
	dips.sort(key=depth, reverse=True)
	if n_petals:
		dips = dips[:n_petals]
	else:
		dips = [b for b in dips if depth(b) > 0.12 * rmax]
	cuts = sorted((b + 0.5) * TAU / B for b in dips)
	print(f"PETALS {label} notches at {[round(math.degrees(c)) for c in cuts]} depths {[round(depth(b), 2) for b in sorted(dips)]}")
	# better when it works: beyond some radius the petals are separate sheets of the mesh; the smallest radius where
	# the head falls apart into petal-sized pieces gives them directly, each petal's angle range cut between neighbours
	def sheets(f):
		lab = m.components(sel & (r > f * rmax))
		ids = [k for k in range(lab.max() + 1) if (lab == k).sum() >= 10]
		return lab, [k for k in ids if np.ptp(r[lab == k]) > 0.15 * rmax]  # a petal reaches outward

	fs = list(np.arange(0.3, 0.86, 0.05))
	if not n_petals:  # unknown count: the radius where the head falls into the most petals
		fs = [max(fs, key=lambda f: (len(sheets(f)[1]), -f))]
	for f in fs:
		lab, ids = sheets(f)
		if (n_petals and len(ids) == n_petals) or (not n_petals and len(ids) >= 4):
			mids = []
			for k in ids:
				aa = ang[lab == k]
				ref = math.atan2(np.sin(aa).mean(), np.cos(aa).mean())
				mids.append(ref % TAU)
			mids.sort()
			cuts = [(mids[k] + (angdiff(mids[(k + 1) % len(mids)], mids[k]) % TAU) / 2) % TAU for k in range(len(mids))]
			cuts = sorted([cuts[-1]] + cuts[:-1])
			print(f"PETALS {label} {len(ids)} separate sheets beyond r {f:.2f} x rmax, middles {[round(math.degrees(a)) for a in mids]}")
			break
	peaks = [(cuts[k] + (angdiff(cuts[(k + 1) % len(cuts)], cuts[k]) % TAU) / 2) % TAU for k in range(len(cuts))]
	print(f"FLOWER {label} centre {np.round(c, 2).tolist()} axis {np.round(nrm, 2).tolist()} rmax {rmax:.2f} r_in {r_in:.2f} "
		f"peaks {len(peaks)} at {[round(math.degrees(a)) for a in peaks]}")
	base = Vector(c - nrm * 0.5 * np.percentile(np.abs(hgt[sel]), 60))
	parts = []
	head_w = sel.astype(float)
	total = np.zeros(m.n)
	ramp = np.array([sstep(r_in, r_in + 0.3 * rmax, x) for x in r])
	# each vertex to the sector between two notches it lies in
	near = np.zeros(m.n, int)
	if cuts:
		after = np.array([[(a - c) % TAU for c in cuts] for a in ang])
		near = np.argmin(after, axis=1)
	for k, a in enumerate(peaks):
		w = np.where(sel & (near == k), ramp, 0.0)
		dirv = u * math.cos(a) + v * math.sin(a)
		hinge = c + dirv * r_in + nrm * np.median(hgt[sel & (near == k) & (np.abs(r - r_in) < 0.15 * rmax)]) if (sel & (near == k) & (np.abs(r - r_in) < 0.15 * rmax)).any() else c + dirv * r_in
		tipp = c + dirv * rmax
		parts.append(part(f"Petal{k + 1}", stem_name, hinge, w, tail=tipp))
		parts[-1]["hinge_axis"] = Vector(np.cross(nrm, dirv))
		parts[-1]["dir"] = Vector(dirv)
		total += w
	stem = part(stem_name, parent, base, head_w - total, tail=Vector(c))
	stem["axis"] = Vector(nrm)
	return [stem] + parts, dict(centre=c, axis=nrm, rmax=rmax, r_in=r_in)


# ---------------------------------------------------------------- the seven of the Sunny Meadow
@monster("Burrling", 3000, role="swarmer")
def rig_burrling(m):
	return []  # its thorns ride the jelly


@monster("Stinglob", 3000, hover=0.9, role="hunter")
def rig_stinglob(m):
	parts = []
	body = m.island == m.main
	# the wings: the two loose islands; the root is where each comes closest to the body
	bodyp = m.co[body]
	for k in set(m.island.tolist()) - {m.main}:
		sel = m.island == k
		p = m.co[sel]
		d = np.array([np.min(np.linalg.norm(bodyp - q, axis=1)) for q in p])
		root = p[d <= np.percentile(d, 12)].mean(0)
		tipp = p[np.argmax(np.linalg.norm(p - root, axis=1))]
		name = "WingL" if p[:, 0].mean() > 0 else "WingR"
		parts.append(part(name, "Top", root, sel.astype(float), tail=tipp))
		# the flap hinge: in the wing's plane, across its span (root to tip), signed so a positive angle takes the tip down
		nrm = pca(p)[1][2]
		span = (tipp - root) / np.linalg.norm(tipp - root)
		ax = np.cross(nrm, span)
		ax /= np.linalg.norm(ax)
		if np.cross(ax, tipp - root)[2] > 0:
			ax = -ax
		parts[-1]["flap_axis"] = Vector(ax)
		print(f"JOINT Stinglob {name} root {np.round(root, 2).tolist()} tip {np.round(tipp, 2).tolist()} flap axis {np.round(ax, 2).tolist()}")
	# the stinger: grown along the surface from its tip (the body's extreme up and back) until the rings widen into the body
	tip_i = int(np.argmax(np.where(body, m.co @ np.array([0, 0.55, 0.83]), -1e9)))
	tip = m.co[tip_i]
	sel, g, G = m.protrusion(tip_i, 0.12, "Stinglob stinger")
	base = m.co[sel & (g > G - 0.2)].mean(0)
	mid = m.co[sel & (np.abs(g - G / 2) < 0.12)].mean(0)
	print(f"JOINT Stinglob stinger length {G:.2f} base {np.round(base, 2).tolist()} middle {np.round(mid, 2).tolist()}")
	# the shaft's outer half on Stinger2, its base half on Stinger1, the base ring fades into the body
	w2 = np.where(sel, np.array([1 - sstep(G * 0.35, G * 0.65, x) for x in g]), 0.0)
	w1 = soften(m, sel.astype(float), 2, keep=body.astype(float)) - w2
	parts.append(part("Stinger1", "Top", base, w1, tail=mid))
	parts.append(part("Stinger2", "Stinger1", mid, w2, tail=tip))
	core = body & ~sel
	m.info["long_axis"] = Vector(pca(m.co[core])[1][0])
	print(f"JOINT Stinglob body long axis {tuple(round(x, 2) for x in m.info['long_axis'])}")
	return parts


@monster("Gapebloom", 3000, role="spitter")
def rig_gapebloom(m):
	green = (m.hue > 55) & (m.hue < 170) & (m.sat > 0.3)
	body = m.island == m.main
	head_col = ~green & body
	zc = np.percentile(m.co[head_col, 2], 5)
	# the flower head: everything not green above the head's base, plus the loose bits inside the maw (teeth, seeds)
	loose_in = (m.island != m.main) & ~green
	sel = (head_col | loose_in) & (m.co[:, 2] > zc)
	parts, f = flower(m, sel, 0, "Top", "Stem", 0.42, "Gapebloom")
	m.info["flower"] = f
	return parts


@monster("Sapcaller", 3000, hover=0.5, role="healer")
def rig_sapcaller(m):
	body = m.island == m.main
	p = m.co[body]
	lowp = p[p[:, 2] < 1.2]
	cx = (np.percentile(lowp[:, 0], 3) + np.percentile(lowp[:, 0], 97)) / 2
	cy = (np.percentile(lowp[:, 1], 3) + np.percentile(lowp[:, 1], 97)) / 2
	r = np.hypot(m.co[:, 0] - cx, m.co[:, 1] - cy)
	zs = np.arange(0.2, 3.0, 0.1)
	prof = [float(np.percentile(r[body & (np.abs(m.co[:, 2] - z) < 0.05)], 90)) if (body & (np.abs(m.co[:, 2] - z) < 0.05)).sum() > 3 else 9 for z in zs]
	print("PROFILE Sapcaller body radius by height:", [(round(z, 1), round(x, 2)) for z, x in zip(zs, prof)])
	kmax = int(np.argmax([x if x < 9 else 0 for x in prof]))
	kneck = kmax + int(np.argmin(prof[kmax:kmax + 16]))
	zneck = float(zs[kneck])
	# the puffs: every loose island that is not a leaf low on the body
	puffs = []
	for k in sorted(set(m.island.tolist()) - {m.main}):
		sel = m.island == k
		if m.co[sel, 2].mean() > zneck + 0.3 or m.sat[sel].mean() < 0.4:
			puffs.append(sel)
	allp = np.any(puffs, axis=0)
	pc = m.co[allp].mean(0)
	zbase = float(np.percentile(m.co[allp, 2], 3))
	neck = np.array([cx, cy, zneck])
	top = pc.copy()  # the puffs hang round their cluster's middle: the chain ends there
	print(f"JOINT Sapcaller neck z {zneck:.2f} (widest at {zs[kmax]:.1f}), puff base z {zbase:.2f}, cluster centre {np.round(pc, 2).tolist()}")
	stalk = body & (m.co[:, 2] > zneck - 0.05)
	a = top - neck
	L = np.linalg.norm(a)
	t = ((m.co - neck) @ a) / (L * L)
	joints = [neck, neck + a / 3, neck + 2 * a / 3, top]
	ws = []
	mids = [1 / 6, 1 / 2, 5 / 6]
	for k in range(3):
		ws.append(np.zeros(m.n))
	for i in np.nonzero(stalk)[0]:
		tt = t[i]
		if tt <= mids[0]:
			ws[0][i] = 1
		elif tt >= mids[2]:
			ws[2][i] = 1
		else:
			k = 0 if tt < mids[1] else 1
			f = (tt - mids[k]) / (mids[k + 1] - mids[k])
			ws[k][i] = 1 - f
			ws[k + 1][i] = f
	# the neck ring blends into the jelly
	low = stalk & (m.co[:, 2] < zneck + 0.15)
	ws[0][low] *= np.clip((m.co[low, 2] - (zneck - 0.05)) / 0.2, 0, 1)
	parts = [part("Stalk1", "Top", joints[0], ws[0], tail=joints[1]), part("Stalk2", "Stalk1", joints[1], ws[1], tail=joints[2]),
		part("Stalk3", "Stalk2", joints[2], ws[2], tail=joints[3])]
	m.info["puff_centre"] = Vector(pc)
	for k, sel in enumerate(puffs):
		q = m.co[sel]
		root = q[np.argmin(np.linalg.norm(q - pc, axis=1))]
		pp = part(f"Puff{k + 1}", "Stalk3", root, sel.astype(float), tail=q.mean(0))
		pp["out"] = Vector(q.mean(0) - pc).normalized()
		parts.append(pp)
	return parts


@monster("Barkhide", 3000, role="armoured")
def rig_barkhide(m):
	body = m.island == m.main
	bark = body & (m.hue < 45) & (m.sat > 0.45)
	leaves = (m.island != m.main) & (m.hue > 55)
	sel = bark | leaves
	# a stray bark-coloured speck far below the plates (the eyes glow orange) stays on the jelly
	zr = np.percentile(m.co[bark, 2], 8)
	eyes = bark & (m.co[:, 1] < -1.2) & (m.co[:, 2] < 2.2)
	sel &= ~eyes
	w = soften(m, sel.astype(float), 2, keep=body.astype(float))
	c = m.co[sel].mean(0)
	head = Vector((c[0], c[1] + 0.3, zr))
	print(f"JOINT Barkhide shell rim z {zr:.2f}, plates centre {np.round(c, 2).tolist()}, eye specks {int(eyes.sum())}")
	return [part("Shell", "Top", head, w, tail=Vector(c))]


@monster("Rotbloom", 6000, role="miniboss")
def rig_rotbloom(m):
	red = (m.sat > 0.35) & ((m.hue < 22) | (m.hue > 320))
	pale = (m.sat < 0.45) & (m.val > 0.6)  # the cream spots on the petals
	body = m.island == m.main
	core = red & body
	zc = np.percentile(m.co[core, 2], 10)
	sel = body & (red | pale) & (m.co[:, 2] > zc - 0.1)
	parts, f = flower(m, sel, 5, "Top", "Flower", 0.36, "Rotbloom")
	m.info["flower"] = f
	return parts


@monster("Bramblehorn", 8000, role="boss")
def rig_bramblehorn(m):
	orange = (m.hue > 14) & (m.hue < 45) & (m.sat > 0.6) & (m.val > 0.4)
	lab = m.components(orange)
	big = []
	for k in range(lab.max() + 1):
		sel = lab == k
		if sel.sum() > 40:
			big.append((int(sel.sum()), k, m.box(sel)))
	big.sort(reverse=True)
	for s, k, bx in big[:12]:
		print(f"ORANGE comp {k} n {s} box {bx}")
	th = m.thickness()
	print("THICK pct", np.percentile(th, [5, 25, 50, 75, 95]).round(2).tolist())
	from mathutils import kdtree
	# the horns: wood-orange pieces (more than 40 vertices) out at each side of the head, cut apart by the green vines
	# wrapped round them; each horn is its pieces plus everything thin within reach of them (the wraps)
	parts = []
	horns = {}
	for side, test in (("HornL", lambda c: c[0] > 1.2 and c[2] > 2.0), ("HornR", lambda c: c[0] < -1.2 and c[2] > 2.0)):
		seeds = np.zeros(m.n, bool)
		for s, k, bx in big:
			sel = lab == k
			c = m.co[sel].mean(0)
			# the back pieces (behind the head's middle) are thicket branches, not horn
			if test(c) and c[1] < 0.4 and abs(c[0]) > 2.3:
				seeds |= sel
		kd = kdtree.KDTree(int(seeds.sum()))
		for i in np.nonzero(seeds)[0]:
			kd.insert(m.co[i], int(i))
		kd.balance()
		near = np.array([kd.find(m.co[i])[2] for i in range(m.n)])
		horn = seeds | ((near < 0.3) & (th < 1.2))
		horns[side] = horn
		print(f"JOINT Bramblehorn {side} pieces {int(seeds.sum())} grown {int(horn.sum())} box {m.box(horn)}")
	# a horn's root: its vertices nearest the head's middle line
	for side, horn in horns.items():
		p = m.co[horn]
		d = np.abs(p[:, 0])
		root = p[d <= np.percentile(d, 8)].mean(0)
		tipp = p[np.argmax(np.linalg.norm(p - root, axis=1))]
		w = soften(m, horn.astype(float), 2)
		parts.append(part(side, "Top", root, w, tail=tipp))
	anyhorn = horns["HornL"] | horns["HornR"]
	# the thicket: berries and leaves (loose islands) up on the back, and every thin vine and thorn above the dome
	thick_top = np.percentile(m.co[th > 2.0, 2], 98)
	loose = (m.island != m.main) & (m.co[:, 2] > 0.55 * thick_top)
	thin = (th < 0.9) & (m.co[:, 2] > 0.62 * thick_top)
	sel = (loose | thin) & ~anyhorn
	w = soften(m, sel.astype(float), 2, keep=(~anyhorn).astype(float))
	c = m.co[sel].mean(0)
	base = Vector((c[0], c[1], float(np.percentile(m.co[sel, 2], 10))))
	print(f"JOINT Bramblehorn thicket dome top {thick_top:.2f}, from z {0.62 * thick_top:.2f}, {int(sel.sum())} vertices, base {tuple(round(x, 2) for x in base)}")
	parts.append(part("Thicket", "Top", base, w, tail=Vector(c)))
	return parts


# ---------------------------------------------------------------- motion
# An action is a function of time t (seconds) returning (c, d):
#   c, the jelly's channels: lift (studs up, on top of the hover), fwd (studs along y: negative = forward), side (studs
#     along x), squash (1 = flattened by 90% of the cage's height, negative = stretched), pitch (radians, positive leans
#     forward: the top goes toward -y), roll (radians, positive tips the top toward +x), yaw (radians about z).
#   d, the parts' drives (radians unless named otherwise), see apply_pose.
# The cage turns c into bone moves (cage_pose); apply_pose turns d into the parts' bone moves. Both are what the game
# ports. Loops are built so that t = 0 and t = T are the same pose with the same speed.
CH = ("lift", "fwd", "side", "squash", "pitch", "roll", "yaw", "swell")
# swell (added after the Meadow, 0 there): the body inflates, top up 0.5 swell Ht and equator out 0.45 swell R together


def C(**k):
	return {n: k.get(n, 0.0) for n in CH}


def cage_pose(r, c, hover):
	g = r["g"]
	heads = {b.name: b.head_local for b in r["rig"].data.bones}
	p = {}
	p["Body"] = (Vector((c["side"], c["fwd"], c["lift"] + hover)), qeul(0.35 * c["pitch"], 0.35 * c["roll"], c["yaw"]))
	if "Top" not in heads:  # a spine body: the parts carry the squash (apply_pose)
		return p
	Ht = heads["Top"].z - heads["Body"].z
	Hb = g["zeq"] - heads["Body"].z
	sw = c.get("swell", 0.0)
	p["Top"] = (Vector((0.4 * c["roll"] * Ht, -0.4 * c["pitch"] * Ht, (-0.9 * c["squash"] + 0.5 * sw) * Ht)), qeul(0.65 * c["pitch"], 0.65 * c["roll"], 0))
	if "Mid" in heads:  # a column: the middle takes half the lean and half the squash, so it bends
		p["Mid"] = (Vector((0.2 * c["roll"] * Ht, -0.2 * c["pitch"] * Ht, (-0.45 * c["squash"] + 0.25 * sw) * Ht)), qeul(0.3 * c["pitch"], 0.3 * c["roll"], 0))
	for k, dv in g["dirs"].items():
		p[k] = (Vector(dv) * 0.45 * (c["squash"] + sw) * g["ext"][k] + Vector((0, 0, -0.4 * c["squash"] * Hb)), Quaternion())
	return p


def generic_move(r, pt, c, d):
	"""Every part of the regions after the Meadow moves by one rule, read from the drives d by the part's name n:
	turn = Z(n.y) * Y(n.r) * X(n.p) * about(spin_axis, n.spin); offset = (n.x, n.f, n.z) + out * n.o.
	A spine body's chain also carries the squash: its first bone sinks 0.3 squash Hj, every later bone moves along
	its own segment by -0.3 squash (stretch lengthens the body)."""
	n = pt["name"]
	q = qeul(d.get(n + ".p", 0.0), d.get(n + ".r", 0.0), d.get(n + ".y", 0.0))
	if "spin_axis" in pt:
		q = q @ qaxis(pt["spin_axis"], d.get(n + ".spin", 0.0))
	loc = Vector((d.get(n + ".x", 0.0), d.get(n + ".f", 0.0), d.get(n + ".z", 0.0)))
	if "out" in pt:
		loc += pt["out"] * d.get(n + ".o", 0.0)
	if r["spec"].get("nocage") and n.startswith("Spine"):
		if n == "Spine1":
			loc += Vector((0, 0, -0.3 * c["squash"] * r["g"]["Hj"]))
		else:
			loc += pt["seg"] * (-0.3 * c["squash"])
	return loc, q


def apply_pose(r, c, d, hover=None):
	"""Every bone's move (relative to its parent, model axes) from the channels and drives."""
	if hover is None:
		hover = r["spec"]["hover"]
	p = cage_pose(r, c, hover)
	info = r["m"].info
	for pt in r["parts"]:
		n = pt["name"]
		if pt.get("existing"):
			continue
		q, loc = Quaternion(), Vector()
		if r["name"] not in MEADOW:
			p[n] = generic_move(r, pt, c, d)
			continue
		if n in ("WingL", "WingR"):
			q = qaxis(pt["flap_axis"], d.get("flap", 0.0))
		elif n.startswith("Stinger"):
			q = qeul(d.get("sting" + n[-1], 0.0))
		elif n in ("Stem", "Flower"):
			q = qeul(d.get("stem_p", 0.0), d.get("stem_r", 0.0))
			loc = Vector((0, 0, d.get("stem_z", 0.0)))
		elif n.startswith("Petal"):
			k = int(n[5:]) - 1
			th = d["petal"](k) if "petal" in d else 0.0
			if th > 0:  # opening folds a petal down: one that already points down opens less, so it never enters the body
				th *= clamp((pt["dir"].z + 0.45) / 0.7)
			q = qaxis(pt["hinge_axis"], th)
		elif n.startswith("Stalk"):
			k = int(n[5:]) - 1
			q = qeul(d.get("stalk_p", (0, 0, 0))[k], d.get("stalk_r", (0, 0, 0))[k])
		elif n.startswith("Puff"):
			k = int(n[4:]) - 1
			loc = pt["out"] * (d["puff"](k) if "puff" in d else 0.0)
		elif n == "Shell":
			q = qeul(d.get("shell_p", 0.0), d.get("shell_r", 0.0), d.get("shell_y", 0.0))
			loc = Vector((0, d.get("shell_f", 0.0), d.get("shell_z", 0.0)))
		elif n in ("HornL", "HornR"):
			s = 1 if n == "HornL" else -1
			q = qeul(d.get("horn", 0.0), s * d.get("horn_out", 0.0))
		elif n == "Thicket":
			q = qeul(d.get("thk_p", 0.0), d.get("thk_r", 0.0))
		p[n] = (loc, q)
	return p


def lagd(fn, t, d, key, T=None):
	"""Channel key of action fn at t - d (looping when T is given): the follow-through every part uses."""
	tt = t - d
	if T:
		tt %= T
	elif tt < 0:
		tt = 0.0
	return fn(tt)[0][key]


# shared bodies -------------------------------------------------------------
def idle_ground(H, depth=0.05):
	T = 2.0
	w = TAU / T

	def f(t):
		return C(squash=depth * math.sin(w * t) + 0.3 * depth * math.sin(2 * w * t + 0.7), pitch=0.05 + 0.025 * math.sin(w * t - 0.5),
			roll=0.02 * math.sin(w * t + 1.3), yaw=0.03 * math.sin(w * t + 2.0)), {}

	return T, f


def idle_fly(H):
	T = 2.0

	def f(t):
		return C(lift=0.035 * H * math.sin(TAU * t), squash=-0.04 * math.sin(TAU * t - 0.9), pitch=0.08 + 0.04 * math.sin(TAU * t - 0.4),
			roll=0.03 * math.sin(math.pi * t)), {}

	return T, f


def hop_once(h, heavy=1.0):
	"""One hop from rest (0..0.68 s) and its landing spring; the loop adds the tail of the hop before."""

	def f(t):
		s = keys(t, [(0, 0), (0.2, 0.22 * heavy), (0.3, -0.2), (0.62, -0.06), (0.68, 0)]) if t < 0.68 else 0.0
		s += ring(t, 0.68, 0.55 * heavy, 2.2 / math.sqrt(heavy), 0.35)
		u = (t - 0.3) / 0.38
		lift = h * 4 * u * (1 - u) if 0 < u < 1 else 0.0
		pitch = (keys(t, [(0, 0), (0.2, 0.12), (0.3, -0.05), (0.6, -0.08), (0.68, 0)]) if t < 0.68 else 0.0) + ring(t, 0.68, 0.35, 1.8, 0.4)
		return C(lift=lift, squash=s, pitch=pitch)

	return f


def move_ground(H, h, heavy=1.0):
	T = 1.0
	one = hop_once(h, heavy)
	return T, lambda t: (f_sum(one, t, T), {})


def f_sum(one, t, T, n=4):
	cs = [one((t % T) + k * T) for k in range(n)]
	return {k: sum(c[k] for c in cs) for k in CH}


def move_fly(H, surge=0.6):
	T = 1.0

	def one(t):
		return C(fwd=-surge * (sstep(0.05, 0.3, t) - sstep(0.35, 0.95, t)) if t < 1 else 0.0,
			pitch=0.3 * hump(t, 0.02, 0.45) + ring(t, 0.3, -0.12, 2.0, 0.4),
			squash=-0.08 * hump(t, 0.05, 0.3) + ring(t, 0.3, 0.08, 3.0, 0.4))

	def f(t):
		c = f_sum(one, t, T)
		c["lift"] = 0.04 * H * math.sin(TAU * 2 * t)
		return c, {}

	return T, f


def hit_body(H):
	T = 0.4

	def f(t):
		end = 1 - sstep(0.28, 0.4, t)
		return C(fwd=0.08 * H * keys(t, [(0, 0), (0.08, 1), (0.4, 0)]), squash=ring(t, 0, 0.25, 4.0, 0.3) * end,
			pitch=-0.2 * keys(t, [(0, 0), (0.07, 1), (0.4, 0)]) + ring(t, 0.07, 0.1, 3.5, 0.4) * end,
			roll=ring(t, 0, 0.08, 5.0, 0.3) * end), {}

	return T, f


def die_body(H, hover):
	T = 1.2

	def f(t):
		c = C(squash=keys(t, [(0, 0), (0.12, 0.2), (0.25, -0.1), (1.0, 0.85), (1.2, 0.85)]) + ring(t, 0.95, 0.05, 3.0, 0.4),
			pitch=keys(t, [(0, 0), (0.12, -0.2), (0.5, 0.1), (1.2, 0.05)]), fwd=0.05 * H * keys(t, [(0, 0), (0.12, 1), (0.6, 0.6)]))
		if hover:
			c["lift"] = hover * keys(t, [(0, 0), (0.2, 0.15), (0.6, -1.0), (1.2, -1.0)])
		return c, {}

	return T, f


# per monster ---------------------------------------------------------------
def wrap(T, loop, body, parts):
	"""body: fn(t)->(c, {}); parts: fn(t, c)->d (may read body at other times for lag)."""
	return (T, loop, lambda t: (body(t)[0], parts(t, body(t)[0])))


def ch(fn, t, key, d=0.0, T=None):
	return lagd(fn, t, d, key, T)


def std(r, hop=0.2, heavy=1.0, depth=0.05):
	"""The shared bodies for one monster: (H, Ti, idle, Tm, move, Th, hit, Td, die)."""
	H, hover = float(r["m"].co[:, 2].max()), r["spec"]["hover"]
	Ti, idle = idle_fly(H) if hover else idle_ground(H, depth)
	Tm, move = move_fly(H) if hover else move_ground(H, hop * H, heavy)
	Th, hit = hit_body(H)
	Td, die = die_body(H, hover)
	return H, Ti, idle, Tm, move, Th, hit, Td, die


def motions(r):
	"""Name -> (length s, loops, fn(t) -> (c, d)) for this monster."""
	name, H, hover = r["name"], float(r["m"].co[:, 2].max()), r["spec"]["hover"]
	if name in MOTION_FNS:
		return MOTION_FNS[name](r)
	A = {}
	nP = sum(1 for p in r["parts"] if p["name"].startswith("Petal"))
	nPuff = sum(1 for p in r["parts"] if p["name"].startswith("Puff"))

	def wrap(T, loop, body, parts):
		"""body: fn(t)->(c, {}); parts: fn(t, c)->d (may read body at other times for lag)."""
		return (T, loop, lambda t: (body(t)[0], parts(t, body(t)[0])))

	Ti, idle = (idle_fly if hover else idle_ground)(H)
	Th, hit = hit_body(H)
	Td, die = die_body(H, hover)
	if hover:
		Tm, move = move_fly(H)
	else:
		Tm, move = move_ground(H, {"Barkhide": 0.07, "Rotbloom": 0.1, "Bramblehorn": 0.07}.get(name, 0.2) * H,
			{"Barkhide": 1.2, "Rotbloom": 1.3, "Bramblehorn": 1.4}.get(name, 1.0))

	def ch(fn, t, key, d=0.0, T=None):
		return lagd(fn, t, d, key, T)

	if name == "Burrling":
		def attack(t):
			return C(fwd=keys(t, [(0, 0), (0.25, 0.35), (0.4, -1.3), (0.62, -1.2), (1.0, 0)]),
				squash=keys(t, [(0, 0), (0.25, 0.22), (0.38, -0.25), (0.45, 0.1), (0.55, 0), (1.0, 0)]) + ring(t, 0.6, 0.15, 3.0, 0.35),
				pitch=keys(t, [(0, 0), (0.25, -0.18), (0.4, 0.3), (1.0, 0)]) + 0.18 * hump(t, 0.42, 0.5) + 0.18 * hump(t, 0.52, 0.6),
				lift=0.35 * hump(t, 0.28, 0.44)), {}
		none = lambda t, c: {}
		A = dict(Idle=wrap(Ti, True, idle, none), Move=wrap(Tm, True, move, none), Attack=wrap(1.0, False, attack, none),
			Hit=wrap(Th, False, hit, none), Die=wrap(Td, False, die, none))
		peak = 0.45

	elif name == "Stinglob":
		def flap(t, amp, hz):
			ph = TAU * hz * t
			return -0.3 + amp * math.cos(ph + 0.35 * math.sin(ph))  # the down stroke a little longer and stronger
		def p_idle(t, c):
			return dict(flap=flap(t, 0.55, 6), sting1=0.08 * math.sin(math.pi * t - 1.0) - 0.5 * (ch(idle, t, "pitch", 0.1, Ti) - 0.08),
				sting2=0.12 * math.sin(math.pi * t - 1.7))
		def p_move(t, c):
			return dict(flap=flap(t, 0.65, 6), sting1=-0.7 * ch(move, t, "pitch", 0.08, Tm), sting2=-0.5 * ch(move, t, "pitch", 0.16, Tm))
		def attack(t):
			return C(lift=keys(t, [(0, 0), (0.35, 0.6), (0.52, -0.7), (0.6, -0.7), (1.0, 0)]),
				fwd=keys(t, [(0, 0), (0.35, 0.5), (0.52, -1.6), (0.62, -1.6), (1.0, 0)]),
				pitch=keys(t, [(0, 0), (0.35, -0.35), (0.5, 0.55), (0.62, 0.5), (1.0, 0)]) + ring(t, 0.62, 0.1, 2.5, 0.4),
				squash=keys(t, [(0, 0), (0.35, 0.12), (0.48, -0.15), (0.55, 0.18), (0.7, 0)])), {}
		def p_attack(t, c):
			return dict(flap=flap(t, 0.7, 6), sting1=keys(t, [(0, 0), (0.35, -0.3), (0.5, 1.0), (0.62, 1.0), (1.0, 0)]) + ring(t, 0.62, -0.15, 3, 0.4),
				sting2=keys(t, [(0, 0), (0.38, -0.2), (0.53, 0.5), (0.62, 0.5), (1.0, 0)]))
		def p_hit(t, c):
			return dict(flap=flap(t, 0.3, 6) + ring(t, 0, 0.4, 3, 0.3), sting1=-1.0 * ch(hit, t, "pitch", 0.05), sting2=-0.8 * ch(hit, t, "pitch", 0.1))
		def p_die(t, c):
			return dict(flap=keys(t, [(0, 0.1), (0.2, -0.4), (0.7, 0.45), (1.2, 0.5)]) + 0.3 * math.cos(TAU * 6 * t) * (1 - sstep(0, 0.6, t)),
				sting1=keys(t, [(0, 0), (0.6, 0.2), (1.0, 0.9)]), sting2=keys(t, [(0, 0), (0.7, 0.3), (1.2, 0.6)]))
		A = dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(1.0, False, attack, p_attack),
			Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))
		peak = 0.55

	elif name == "Gapebloom":
		def p_idle(t, c):
			w = math.pi
			return dict(stem_p=-0.6 * (ch(idle, t, "pitch", 0.15, Ti) - 0.05), stem_r=-0.6 * ch(idle, t, "roll", 0.15, Ti),
				petal=lambda k: 0.06 * math.sin(w * t - 1.2 - k * TAU / nP) + 1.2 * ch(idle, t, "squash", 0.2, Ti))
		def p_move(t, c):
			return dict(stem_p=0.6 * ch(move, t, "pitch", 0.08, Tm) + 0.5 * ch(move, t, "squash", 0.08, Tm),
				petal=lambda k: 0.9 * ch(move, t, "squash", 0.1 + 0.01 * k, Tm))
		def attack(t):
			return C(pitch=keys(t, [(0, 0), (0.35, -0.3), (0.45, 0.12), (1.0, 0)]) + ring(t, 0.45, 0.06, 2.5, 0.35),
				squash=keys(t, [(0, 0), (0.35, -0.15), (0.45, 0.25), (0.6, 0)]) + ring(t, 0.6, 0.06, 3, 0.4)), {}
		def p_attack(t, c):
			return dict(stem_p=keys(t, [(0, 0), (0.35, -0.3), (0.45, 0.2), (1.0, 0)]) + ring(t, 0.45, 0.08, 3.0, 0.3),
				petal=lambda k: keys(t - 0.012 * k, [(0, 0), (0.35, -0.35), (0.47, 0.65), (0.6, 0.65)]) * (1 - sstep(0.6, 1.0, t))
					+ ring(t, 0.6 + 0.012 * k, -0.15, 3, 0.35))
		def p_hit(t, c):
			return dict(stem_p=-1.2 * ch(hit, t, "pitch", 0.05), petal=lambda k: -0.3 * hump(t, 0, 0.3) + ring(t, 0.05, 0.12, 5, 0.3) * (1 - sstep(0.3, 0.4, t)))
		def p_die(t, c):
			return dict(stem_p=keys(t, [(0, 0), (0.15, -0.3), (1.0, 0.6), (1.2, 0.6)]), stem_z=-0.4 * sstep(0.3, 1.0, t),
				petal=lambda k: keys(t, [(0, 0), (0.15, -0.3), (1.0, 0.75)]))
		A = dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(1.0, False, attack, p_attack),
			Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))
		peak = 0.47

	elif name == "Sapcaller":
		def puffs(t, swell):
			return lambda k: swell + 0.04 * math.sin(TAU * t - k * 0.9)
		def chain(fn, t, T, key, gain):
			return tuple(gain[k] * ch(fn, t, key, 0.1 * (k + 1), T) for k in range(3))
		def p_idle(t, c):
			w = math.pi
			return dict(stalk_p=tuple(a * math.sin(w * t - 0.6 * k) for k, a in enumerate((0.04, 0.06, 0.08))),
				stalk_r=tuple(a * math.sin(w * t + 1.0 - 0.6 * k) for k, a in enumerate((0.03, 0.05, 0.07))), puff=puffs(t, 0.0))
		def p_move(t, c):
			return dict(stalk_p=chain(move, t, Tm, "pitch", (-0.4, -0.5, -0.6)), puff=puffs(t, 0.0))
		def attack(t):
			return C(lift=keys(t, [(0, 0), (0.3, 0.3), (0.9, 0.3), (1.0, 0)]), squash=keys(t, [(0, 0), (0.3, -0.15), (0.9, -0.15), (1.0, 0)])
				+ 0.05 * (hump(t, 0.35, 0.5) + hump(t, 0.55, 0.7) + hump(t, 0.75, 0.9)), pitch=keys(t, [(0, 0), (0.3, -0.08), (1.0, 0)])), {}
		def p_attack(t, c):
			pulse = 0.1 * (hump(t, 0.35, 0.5) + hump(t, 0.55, 0.7) + hump(t, 0.75, 0.9))
			swell = 0.3 * keys(t, [(0, 0), (0.3, 1), (0.85, 1), (1.0, 0)]) + pulse
			return dict(stalk_p=(-0.05 * hump(t, 0.1, 0.9), -0.05 * hump(t, 0.1, 0.9), 0.0), puff=lambda k: swell * (1 + 0.15 * math.sin(k * 1.7)))
		def p_hit(t, c):
			return dict(stalk_p=chain(hit, t, None, "pitch", (-0.8, -1.0, -1.2)), puff=lambda k: ring(t, 0.02 * k, 0.08, 6, 0.3) * (1 - sstep(0.3, 0.4, t)))
		def p_die(t, c):
			return dict(stalk_p=tuple(keys(t, [(0, 0), (0.15, -0.15), (1.1, 0.35 + 0.1 * k)]) for k in range(3)),
				puff=lambda k: -0.1 * sstep(0.5, 1.1, t))
		A = dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(1.0, False, attack, p_attack),
			Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))
		peak = 0.62

	elif name == "Barkhide":
		def p_idle(t, c):
			return dict(shell_p=0.03 * math.sin(math.pi * t - 1.4), shell_z=-0.3 * (ch(idle, t, "squash", 0.2, Ti) - c["squash"]))
		def p_move(t, c):
			return dict(shell_z=0.4 * (ch(move, t, "lift", 0.06, Tm) - c["lift"]), shell_p=ring((t % Tm), 0.7, 0.07, 6, 0.3) + ring((t % Tm) + Tm, 0.7, 0.07, 6, 0.3))
		def attack(t):
			return C(fwd=keys(t, [(0, 0), (0.3, 0.3), (0.4, 0.3), (0.58, -1.0), (1.0, 0)]),
				squash=keys(t, [(0, 0), (0.3, -0.08), (0.42, 0.22), (0.6, 0.05), (1.0, 0)]) + ring(t, 0.6, 0.06, 3, 0.4),
				pitch=keys(t, [(0, 0), (0.3, -0.12), (0.45, 0.15), (0.6, 0.18), (1.0, 0)])), {}
		def p_attack(t, c):
			return dict(shell_z=keys(t, [(0, 0), (0.3, 0.25), (0.42, -0.12), (0.7, -0.08), (1.0, 0)]),
				shell_p=keys(t, [(0, 0), (0.3, -0.2), (0.42, 0.15), (0.75, 0.1), (1.0, 0)]) + ring(t, 0.42, 0.05, 7, 0.25))
		def p_hit(t, c):
			end = 1 - sstep(0.3, 0.4, t)
			return dict(shell_y=ring(t, 0, 0.06, 9, 0.2) * end, shell_p=ring(t, 0.02, 0.05, 8, 0.25) * end, shell_z=0.06 * hump(t, 0, 0.2))
		def p_die(t, c):
			return dict(shell_z=keys(t, [(0, 0), (0.15, 0.12), (1.0, -0.25)]), shell_p=keys(t, [(0, 0), (1.0, 0.12)]), shell_r=keys(t, [(0, 0), (1.1, 0.08)]))
		A = dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(1.0, False, attack, p_attack),
			Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))
		peak = 0.42

	elif name == "Rotbloom":
		Ti, idle = idle_ground(H, 0.035)
		def p_idle(t, c):
			return dict(stem_p=-0.5 * (ch(idle, t, "pitch", 0.2, Ti) - 0.05), stem_r=-0.5 * ch(idle, t, "roll", 0.2, Ti),
				petal=lambda k: 0.05 * math.sin(math.pi * t - 1.0 - k * TAU / nP) + 1.0 * ch(idle, t, "squash", 0.25, Ti))
		def p_move(t, c):
			return dict(stem_p=0.5 * ch(move, t, "pitch", 0.1, Tm), stem_z=0.3 * (ch(move, t, "lift", 0.06, Tm) - c["lift"]),
				petal=lambda k: 0.8 * ch(move, t, "squash", 0.1 + 0.015 * k, Tm))
		def attack(t):
			return C(lift=0.9 * hump(t, 0.3, 0.56) if t < 0.43 else 0.9 * keys(t, [(0.43, 1), (0.56, 0)]),
				squash=keys(t, [(0, 0), (0.3, -0.2), (0.5, -0.1), (0.56, 0)]) + ring(t, 0.56, 0.6, 2.0, 0.35),
				pitch=keys(t, [(0, 0), (0.35, -0.2), (0.56, 0.12), (1.2, 0)])), {}
		def p_attack(t, c):
			return dict(stem_z=ring(t, 0.56, -0.5, 2.2, 0.35), stem_p=-0.4 * c["pitch"],
				petal=lambda k: keys(t, [(0, 0), (0.35, -0.3), (0.56, -0.1)]) * (1 - sstep(0.54, 0.6, t)) + settle(t, 0.6 + 0.015 * k, -0.6, 1.6, 0.35) * sstep(0.54, 0.6, t))
		def p_hit(t, c):
			return dict(stem_p=-1.0 * ch(hit, t, "pitch", 0.06), petal=lambda k: ring(t, 0.02 * k, 0.25, 4, 0.3) * (1 - sstep(0.3, 0.4, t)))
		def p_die(t, c):
			return dict(stem_z=-0.8 * sstep(0.2, 1.0, t), stem_p=keys(t, [(0, 0), (1.0, 0.25)]), petal=lambda k: keys(t, [(0, 0), (0.2, -0.2), (1.1, 0.4)]))
		A = dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(1.2, False, attack, p_attack),
			Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))
		peak = 0.62

	elif name == "Bramblehorn":
		Ti, idle = idle_ground(H, 0.035)
		def p_idle(t, c):
			return dict(thk_p=-0.6 * (ch(idle, t, "pitch", 0.3, Ti) - 0.05) + 0.02 * math.sin(math.pi * t - 2.0),
				thk_r=-0.6 * ch(idle, t, "roll", 0.3, Ti), horn=0.015 * math.sin(math.pi * t - 0.4))
		def p_move(t, c):
			return dict(thk_p=-0.8 * (ch(move, t, "pitch", 0.15, Tm)) + 0.06 * (ch(move, t, "lift", 0.12, Tm) - c["lift"]))
		def attack(t):
			return C(fwd=keys(t, [(0, 0), (0.4, 0.6), (0.65, -2.2), (0.75, -2.2), (1.2, 0)]),
				squash=keys(t, [(0, 0), (0.4, 0.2), (0.5, -0.15), (0.65, 0)]) + ring(t, 0.65, 0.3, 2.0, 0.35),
				pitch=keys(t, [(0, 0), (0.4, 0.25), (0.65, 0.3), (1.2, 0)]), lift=0.25 * hump(t, 0.45, 0.65)), {}
		def p_attack(t, c):
			return dict(horn=keys(t, [(0, 0), (0.4, 0.2), (0.75, 0.2), (1.2, 0)]) + ring(t, 0.65, 0.04, 4, 0.3),
				thk_p=-0.6 * ch(attack, t, "pitch", 0.15) + ring(t, 0.7, 0.2, 1.5, 0.3))
		def p_hit(t, c):
			return dict(thk_p=-0.9 * ch(hit, t, "pitch", 0.08), thk_r=-0.9 * ch(hit, t, "roll", 0.08))
		def p_die(t, c):
			return dict(thk_p=keys(t, [(0, 0), (0.2, 0.1), (1.1, -0.2)]), thk_r=keys(t, [(0, 0), (1.1, 0.12)]), horn=keys(t, [(0, 0), (1.0, 0.15)]),
				horn_out=keys(t, [(0, 0), (1.0, 0.08)]))
		A = dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(1.2, False, attack, p_attack),
			Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))
		peak = 0.66
	return A, peak


def extremes(r):
	"""The pose sheet: rest, squash, stretch, then each part at its extremes (label, c, d)."""
	n = r["name"]
	H = float(r["m"].co[:, 2].max())
	out = [("rest", C(), {}), ("squash", C(squash=0.45), {}), ("stretch", C(squash=-0.35, lift=0.1 * H), {})]
	if n in EXTREMES:
		return out + EXTREMES[n]
	ex = {
		"Burrling": [("lean fwd", C(pitch=0.35, squash=0.1), {}), ("lean side", C(roll=0.3), {})],
		"Stinglob": [("wings down", C(), dict(flap=0.3)), ("wings up", C(), dict(flap=-1.0)), ("stinger stab", C(), dict(sting1=1.0, sting2=0.5)),
			("stinger back", C(), dict(sting1=-0.4, sting2=-0.3))],
		"Gapebloom": [("petals open", C(), dict(petal=lambda k: 0.75)), ("petals shut", C(), dict(petal=lambda k: -0.4)),
			("stem fwd", C(), dict(stem_p=0.3))],
		"Sapcaller": [("puffs swell", C(), dict(puff=lambda k: 0.45)), ("stalk bend", C(), dict(stalk_p=(0.15, 0.2, 0.25), stalk_r=(0.1, 0.15, 0.2)))],
		"Barkhide": [("shell open", C(), dict(shell_z=0.25, shell_p=-0.2)), ("shell clamp", C(squash=0.22), dict(shell_z=-0.12, shell_p=0.15)),
			("shell rattle", C(), dict(shell_y=0.08, shell_r=0.06))],
		"Rotbloom": [("petals whip up", C(), dict(petal=lambda k: -0.6)), ("petals droop", C(), dict(petal=lambda k: 0.3)), ("flower down", C(squash=0.3), dict(stem_z=-0.5))],
		"Bramblehorn": [("horns lowered", C(pitch=0.3), dict(horn=0.25)), ("horns spread", C(), dict(horn_out=0.1)), ("thicket sway", C(), dict(thk_p=0.2, thk_r=0.12))],
	}[n]
	return out + ex


def set_pose(r, pose):
	rig = r["rig"]
	for pb in rig.pose.bones:
		pb.rotation_mode = "QUATERNION"
		if pb.name in pose:
			loc, q = pose[pb.name]
			Q = rig.data.bones[pb.name].matrix_local.to_3x3()
			Qi = Q.inverted()
			pb.location = Qi @ loc
			pb.rotation_quaternion = (Qi @ q.to_matrix() @ Q).to_quaternion()
		else:
			pb.location = (0, 0, 0)
			pb.rotation_quaternion = Quaternion()
	bpy.context.view_layer.update()


def bake_actions(r, A):
	rig = r["rig"]
	if rig.animation_data is None:
		rig.animation_data_create()
	acts = {}
	for an, (T, loop, fn) in A.items():
		act = bpy.data.actions.new(f"{r['name']}_{an}")
		act.use_fake_user = True
		rig.animation_data.action = act
		N = int(round(T * FPS))
		for f in range(N + 1):
			t = f / FPS
			c, d = fn(t)
			set_pose(r, apply_pose(r, c, d))
			for pb in rig.pose.bones:
				if pb.name == "Root":
					continue
				pb.keyframe_insert("location", frame=f)
				pb.keyframe_insert("rotation_quaternion", frame=f)
		if loop:
			# the loop joins: first and last frames equal
			c0, d0 = fn(0.0)
			c1, d1 = fn(T - 1e-9)
			gap = max(abs(c0[k] - c1[k]) for k in CH)
			print(f"ACTION {r['name']}_{an} {T:.2f} s {N + 1} frames loop gap {gap:.4f}")
		else:
			print(f"ACTION {r['name']}_{an} {T:.2f} s {N + 1} frames")
		acts[an] = (act, N)
	rig.animation_data.action = None
	return acts


# ---------------------------------------------------------------- build
def sample_texture():
	img = [i for i in bpy.data.images if i.size[0] > 0][0]
	W, H = img.size
	px = np.empty(W * H * 4, dtype=np.float32)
	img.pixels.foreach_get(px)
	return px.reshape(H, W, 4)


def decimate(ob, budget):
	ob.data.calc_loop_triangles()
	tris = len(ob.data.loop_triangles)
	if tris > budget:
		mod = ob.modifiers.new("Budget", "DECIMATE")
		mod.decimate_type = "COLLAPSE"
		mod.ratio = budget / tris * 0.985
		bpy.context.view_layer.objects.active = ob
		bpy.ops.object.modifier_apply(modifier=mod.name)
	ob.data.calc_loop_triangles()
	return tris, len(ob.data.loop_triangles)


def cage(m, taken, spec=None):
	"""The jelly's cage bones from the jelly's own shape (vertices no part took). m.info may narrow it: cage_sel (only
	these vertices are measured: a head end, a puddle), cage_thin (measure them even if thin)."""
	spec = spec or {}
	jel = taken < 0.5
	P = m.co[jel]
	# the jelly's height: the top of its thick part (vines, tendrils and thorns on top are thin)
	H = float(m.co[:, 2].max())
	sel = m.info.get("cage_sel")
	okv = np.ones(m.n, bool) if m.info.get("cage_thin") else (m.thickness() > 0.2 * H)
	if sel is not None:
		okv = okv & sel
		jel = jel | sel
	if spec.get("nocage"):  # a spine body: every vertex is on the chain; its height is the whole mesh's
		jel = np.ones(m.n, bool)
	thick = jel & okv
	Hj = float(np.percentile(m.co[thick, 2], 98))
	if spec.get("nocage"):
		lo, hi = m.co.min(0), m.co.max(0)
		cx, cy = float(lo[0] + hi[0]) / 2, float(lo[1] + hi[1]) / 2
		g = dict(Hj=Hj, zeq=0.5 * Hj, cx=cx, cy=cy, ext={}, dirs={})
		return ["Body"], dict(Body=Vector((cx, cy, 0.25 * Hj))), np.ones((m.n, 1)), g
	# the shape is measured on every thick vertex (a shell or a flower covering the jelly still has jelly under it)
	P = m.co[okv & (m.co[:, 2] < Hj)]
	low = P[P[:, 2] < Hj * 0.5]
	mid = lambda a: float(np.percentile(a, 3) + np.percentile(a, 97)) / 2  # a median leans toward dense mesh
	cx, cy = mid(low[:, 0]), mid(low[:, 1])
	best = (0, 0.4 * Hj)
	for z in np.linspace(0.12 * Hj, 0.45 * Hj, 14):
		band = P[np.abs(P[:, 2] - z) < 0.04 * Hj]
		if len(band) < 8:
			continue
		rr = np.percentile(np.hypot(band[:, 0] - cx, band[:, 1] - cy), 90)
		if rr > best[0]:
			best = (rr, z)
	zeq = float(best[1])
	band = P[np.abs(P[:, 2] - zeq) < 0.08 * Hj]
	cx, cy = mid(band[:, 0]), mid(band[:, 1])
	ext = dict(Front=cy - np.percentile(band[:, 1], 4), Back=np.percentile(band[:, 1], 96) - cy,
		Left=np.percentile(band[:, 0], 96) - cx, Right=cx - np.percentile(band[:, 0], 4))
	dirs = dict(Front=(0, -1, 0), Back=(0, 1, 0), Left=(1, 0, 0), Right=(-1, 0, 0))
	heads = dict(Body=Vector((cx, cy, 0.25 * Hj)), Top=Vector((cx, cy, 0.75 * Hj)))
	for k, d in dirs.items():
		heads[k] = Vector((cx, cy, zeq)) + Vector(d) * 0.75 * float(ext[k])
	g = dict(Hj=Hj, zeq=zeq, cx=cx, cy=cy, ext={k: float(v) for k, v in ext.items()}, dirs=dirs)
	# smooth weights: a gaussian of the distance to each cage bone, measured in the body's own proportions
	sx = (g["ext"]["Left"] + g["ext"]["Right"]) / 2
	sy = (g["ext"]["Front"] + g["ext"]["Back"]) / 2
	sc = np.array([sx, sy, Hj / 2])
	names = ["Body", "Top", "Front", "Back", "Left", "Right"]
	if spec.get("mid"):
		names.append("Mid")
		heads["Mid"] = Vector((cx, cy, 0.5 * Hj))
	W = np.zeros((m.n, len(names)))
	for k, nm in enumerate(names):
		d = np.linalg.norm((m.co - np.array(heads[nm])) / sc, axis=1)
		W[:, k] = np.exp(-(d / 0.6) ** 2)
	W /= np.maximum(W.sum(1), 1e-9)[:, None]
	return names, heads, W, g


def build(name, spec, src, px, index):
	src.name = src.data.name = name + "_src"
	ob = src.copy()
	ob.data = src.data.copy()
	ob.name = ob.data.name = name
	bpy.context.scene.collection.objects.link(ob)
	ob.location = src.location.copy()
	src.hide_render = True
	src.hide_set(True)
	before, after = decimate(ob, spec["budget"])
	if spec.get("pre"):
		spec["pre"](ob)
		ob.data.calc_loop_triangles()
		after = len(ob.data.loop_triangles)
	m = Mesh(ob, px)
	m.info = {}
	parts = spec["rig"](m)
	taken = np.zeros(m.n)
	for p in parts:
		taken += p["w"]
	names, heads, CW, g = cage(m, taken, spec)
	# the armature: every bone points up (+z) with no roll, so every bone's rest axes are the model's axes and each
	# motion below is written once in model axes
	arm = bpy.data.armatures.new(name + "Rig")
	rig = bpy.data.objects.new(name + "Rig", arm)
	bpy.context.scene.collection.objects.link(rig)
	rig.location = ob.location.copy()
	bpy.context.view_layer.objects.active = rig
	bpy.ops.object.mode_set(mode="EDIT")
	eb = arm.edit_bones
	L = 0.18 * g["Hj"]
	root = eb.new("Root")
	root.head, root.tail = Vector((0, 0, 0)), Vector((0, 0, L))
	bones = {"Root": root}
	for nm in names:
		b = eb.new(nm)
		b.head = heads[nm]
		b.tail = heads[nm] + Vector((0, 0, L))
		b.parent = bones["Root"] if nm == "Body" else bones["Body"]
		bones[nm] = b
	for p in parts:
		if p.get("existing"):
			continue
		b = eb.new(p["name"])
		b.head = p["head"]
		b.tail = p["head"] + Vector((0, 0, max(0.15, min(L, (p["tail"] - p["head"]).length))))
		b.parent = bones[p["parent"]]
		bones[p["name"]] = b
	for b in eb:
		b.roll = 0
		b.use_deform = b.name != "Root"
	bpy.ops.object.mode_set(mode="OBJECT")
	# weights: parts first, the cage takes the rest; at most 4, normalised
	allnames = names + [p["name"] for p in parts if not p.get("existing")]
	Wt = np.zeros((m.n, len(allnames)))
	Wt[:, : len(names)] = CW * np.clip(1 - taken, 0, 1)[:, None]
	for p in parts:
		Wt[:, allnames.index(p["name"])] += p["w"]
	Wt = np.clip(Wt, 0, None)
	order = np.argsort(-Wt, axis=1)
	for i in range(m.n):
		Wt[i, order[i, 4:]] = 0
	Wt[Wt < 0.01] = 0
	Wt /= np.maximum(Wt.sum(1), 1e-9)[:, None]
	for k, nm in enumerate(allnames):
		vg = ob.vertex_groups.new(name=nm)
		for i in np.nonzero(Wt[:, k])[0]:
			vg.add([int(i)], float(Wt[i, k]), "REPLACE")
	ob.parent = rig
	ob.location = (0, 0, 0)
	ob.matrix_parent_inverse = Matrix.Identity(4)
	mod = ob.modifiers.new("Rig", "ARMATURE")
	mod.object = rig
	# checks
	inf = (Wt > 0).sum(1)
	print(f"CHECK {name} tris {before}->{after} verts {m.n} bones {len(allnames) + 1} max influences {inf.max()} "
		f"unweighted {(inf == 0).sum()} sum range {Wt.sum(1).min():.3f}..{Wt.sum(1).max():.3f} root weight 0")
	print(f"CAGE {name} Hj {g['Hj']:.2f} equator z {g['zeq']:.2f} centre ({g['cx']:.2f}, {g['cy']:.2f}) reach "
		+ " ".join(f"{k} {v:.2f}" for k, v in g["ext"].items()))
	for k, nm in enumerate(allnames):
		sel = Wt[:, k] > 0.5
		if sel.any():
			print(f"BONE {name}.{nm} head {tuple(round(x, 2) for x in bones_head(arm, nm))} verts>0.5 {int(sel.sum())} box {m.box(sel)}")
	return dict(name=name, ob=ob, rig=rig, m=m, parts=parts, g=g, W=Wt, names=allnames, spec=spec, tris=after, index=index)


def bones_head(arm, nm):
	return arm.bones[nm].head_local


# ---------------------------------------------------------------- review renders
PALETTE = [(0.9, 0.9, 0.9), (0.95, 0.75, 0.2), (0.2, 0.45, 0.95), (0.95, 0.3, 0.3), (0.3, 0.85, 0.35), (0.7, 0.3, 0.9),
	(0.1, 0.85, 0.85), (1.0, 0.5, 0.0), (0.55, 0.35, 0.15), (1.0, 0.4, 0.75), (0.5, 0.95, 0.1), (0.2, 0.2, 0.6),
	(0.95, 0.95, 0.2), (0.0, 0.5, 0.3), (0.6, 0.0, 0.2), (0.4, 0.6, 1.0), (0.9, 0.6, 0.5), (0.3, 0.3, 0.3)]


def setup_render():
	scene = bpy.context.scene
	scene.render.engine = "BLENDER_EEVEE"
	scene.render.film_transparent = False
	world = bpy.data.worlds.new("w")
	scene.world = world
	world.use_nodes = True
	world.node_tree.nodes["Background"].inputs[0].default_value = (0.9, 0.92, 0.95, 1)
	world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
	sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
	sun.data.energy = 2.5
	sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
	scene.collection.objects.link(sun)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	cam.data.type = "ORTHO"
	scene.collection.objects.link(cam)
	scene.camera = cam
	# the bone-colour view
	mat = bpy.data.materials.new("BoneView")
	mat.use_nodes = True
	nt = mat.node_tree
	for nd in list(nt.nodes):
		nt.nodes.remove(nd)
	at = nt.nodes.new("ShaderNodeAttribute")
	at.attribute_name = "BoneCol"
	em = nt.nodes.new("ShaderNodeBsdfDiffuse")
	out = nt.nodes.new("ShaderNodeOutputMaterial")
	nt.links.new(at.outputs["Color"], em.inputs["Color"])
	nt.links.new(em.outputs[0], out.inputs["Surface"])
	return cam, mat


def shoot(cam, centre, span, d, path, res):
	scene = bpy.context.scene
	scene.render.resolution_x = scene.render.resolution_y = res
	cam.data.ortho_scale = span
	cam.location = centre + Vector(d).normalized() * span * 2
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
	cam.data.clip_end = span * 6
	scene.render.filepath = path
	bpy.ops.render.render(write_still=True)


def view_frame(r, grow=1.3):
	ob = r["ob"]
	co = r["m"].co
	lo, hi = co.min(0), co.max(0)
	centre = Vector(((lo + hi) / 2).tolist()) + r["rig"].location + Vector((0, 0, r["spec"]["hover"] * 0.5))
	return centre, float(np.linalg.norm(hi - lo)) * 0.8 * grow


def weights_view(r, cam, mat):
	ob = r["ob"]
	me = ob.data
	attr = me.color_attributes.new("BoneCol", "FLOAT_COLOR", "POINT")
	cols = np.zeros((r["m"].n, 4))
	cols[:, 3] = 1
	for k in range(len(r["names"])):
		cols[:, :3] += r["W"][:, k : k + 1] * np.array(PALETTE[k % len(PALETTE)])
	attr.data.foreach_set("color", cols.ravel())
	old = me.materials[0]
	me.materials[0] = mat
	centre, span = view_frame(r, 1.0)
	centre.z -= r["spec"]["hover"] * 0.5
	tiles = []
	for vname, d in (("front", (0, -1, 0.15)), ("side", (1, 0, 0.1)), ("back", (0, 1, 0.15)), ("top", (0, -0.05, 1))):
		path = f"{TILES}/{r['name']}/w_{vname}.png"
		shoot(cam, centre, span, d, path, 360)
		tiles.append(path)
	me.materials[0] = old
	me.color_attributes.remove(me.color_attributes["BoneCol"])
	legend = [(nm, PALETTE[k % len(PALETTE)]) for k, nm in enumerate(r["names"])]
	return dict(tiles=tiles, legend=legend)


# ---------------------------------------------------------------- its own texture (Roblox shows images at most 1024)
TEX = 1024


def own_texture(r, cam, check):
	"""A second UV map that packs only this monster's islands into 0-1 (relative scale kept, 6 px margins), the region's
	4096 texture baked through the old UVs onto a 1024 image (Cycles emission bake), saved as <Name>/<Name>.png; the
	mesh keeps only the new UVs and a material reading that image. check: front renders before and after."""
	ob, me, name = r["ob"], r["ob"].data, r["name"]
	set_pose(r, {})
	old_uv = me.uv_layers.active.name
	old_mat = me.materials[0]
	src_img = [i for i in bpy.data.images if i.size[0] >= 2048][0]
	tiles = {}
	centre, span = view_frame(r, 1.1)
	if check:
		tiles["before"] = f"{TILES}/{name}/t_before.png"
		shoot(cam, centre, span, (0, -1, 0.25), tiles["before"], 420)
		tiles["before_b"] = f"{TILES}/{name}/t_before_b.png"
		shoot(cam, centre, span, (0.3, 1, 0.35), tiles["before_b"], 420)
	new = me.uv_layers.new(name="Own")
	me.uv_layers.active = new
	bpy.ops.object.select_all(action="DESELECT")
	ob.select_set(True)
	bpy.context.view_layer.objects.active = ob
	ts = bpy.context.scene.tool_settings
	ts.use_uv_select_sync = True
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.uv.select_all(action="SELECT")
	bpy.ops.uv.pack_islands(rotate=True, scale=True, margin_method="FRACTION", margin=6 / TEX)
	bpy.ops.object.mode_set(mode="OBJECT")
	uv = np.empty(len(me.loops) * 2)
	me.uv_layers["Own"].data.foreach_get("uv", uv)
	uv = uv.reshape(-1, 2)
	# the fill: how much of 0-1 the packed islands' boxes reach
	print(f"TEX {name} packed UVs span {uv.min(0).round(3).tolist()}..{uv.max(0).round(3).tolist()}")
	img = bpy.data.images.new(name + "_tex", TEX, TEX, alpha=False)
	mat = bpy.data.materials.new(name + "_bake")
	mat.use_nodes = True
	nt = mat.node_tree
	for nd in list(nt.nodes):
		nt.nodes.remove(nd)
	uvn = nt.nodes.new("ShaderNodeUVMap")
	uvn.uv_map = old_uv
	tex = nt.nodes.new("ShaderNodeTexImage")
	tex.image = src_img
	em = nt.nodes.new("ShaderNodeEmission")
	out = nt.nodes.new("ShaderNodeOutputMaterial")
	nt.links.new(uvn.outputs["UV"], tex.inputs["Vector"])
	nt.links.new(tex.outputs["Color"], em.inputs["Color"])
	nt.links.new(em.outputs[0], out.inputs["Surface"])
	target = nt.nodes.new("ShaderNodeTexImage")
	target.image = img
	nt.nodes.active = target
	for k in range(len(me.materials)):
		me.materials[k] = mat
	scene = bpy.context.scene
	eng = scene.render.engine
	scene.render.engine = "CYCLES"
	scene.cycles.samples = 4
	scene.cycles.device = "CPU"
	scene.render.bake.margin = 8
	scene.render.bake.use_clear = True
	bpy.ops.object.bake(type="EMIT", margin=8, use_clear=True)
	scene.render.engine = eng
	path = f"{DIR}/{name}/{name}.png"
	os.makedirs(f"{DIR}/{name}", exist_ok=True)
	img.filepath_raw = path
	img.file_format = "PNG"
	img.save()
	img.filepath = path
	# the final material: the 1024 image on the new (only) UVs
	fm = bpy.data.materials.new(name + "_Mat")
	fm.use_nodes = True
	bsdf = fm.node_tree.nodes.get("Principled BSDF")
	ti = fm.node_tree.nodes.new("ShaderNodeTexImage")
	ti.image = img
	fm.node_tree.links.new(ti.outputs["Color"], bsdf.inputs["Base Color"])
	if old_mat is not None and old_mat.node_tree and old_mat.node_tree.nodes.get("Principled BSDF"):
		ob_b = old_mat.node_tree.nodes["Principled BSDF"]
		for k in ("Roughness", "Metallic"):
			if not ob_b.inputs[k].is_linked:
				bsdf.inputs[k].default_value = ob_b.inputs[k].default_value
	me.materials.clear()
	me.materials.append(fm)
	me.uv_layers.remove(me.uv_layers[old_uv])
	me.uv_layers.active = me.uv_layers["Own"]
	bpy.data.materials.remove(mat)
	if check:
		tiles["after"] = f"{TILES}/{name}/t_after.png"
		shoot(cam, centre, span, (0, -1, 0.25), tiles["after"], 420)
		tiles["after_b"] = f"{TILES}/{name}/t_after_b.png"
		shoot(cam, centre, span, (0.3, 1, 0.35), tiles["after_b"], 420)
		tiles["uv"] = path
	print(f"TEX {name} {path} {os.path.getsize(path) // 1024} KB")
	return tiles


def rq(q):
	"""A Blender model-axes quaternion (w, x, y, z) in Roblox axes: the axis maps like a vector (det +1)."""
	return [round(q.w, 5), round(-q.x, 5), round(q.z, 5), round(q.y, 5)]


def golden(r, A):
	"""Every bone's move (apply_pose) at 8 evenly spaced times of every action: loops at k T / 8, one-shots at k T / 7
	(k = 0..7, so the last is the held end)."""
	out = {}
	for an, (T, loop, fn) in A.items():
		rows = []
		for k in range(8):
			t = k * T / 8 if loop else k * T / 7
			c, d = fn(t)
			pose = apply_pose(r, c, d)
			bones = {}
			for bn, (loc, q) in pose.items():
				q = q.normalized()
				bones[bn] = dict(loc=[round(x, 5) for x in loc], rot=[round(q.w, 5), round(q.x, 5), round(q.y, 5), round(q.z, 5)],
					loc_rb=[round(-loc.x, 5), round(loc.z, 5), round(loc.y, 5)], rot_rb=rq(q))
			rows.append(dict(t=round(t, 5), channels={kk: round(v, 5) for kk, v in c.items()}, bones=bones))
		out[an] = rows
	return out


def part_data(r):
	"""Every per-part vector or number the motions read, Blender and Roblox axes."""
	out = {}
	for p in r["parts"]:
		if p.get("existing"):
			continue
		dd = {}
		for k, v in p.items():
			if k in ("name", "parent", "w", "head", "tail"):
				continue
			if isinstance(v, Vector):
				dd[k] = [round(x, 4) for x in v]
				dd[k + "_rb"] = rb(v)
			elif isinstance(v, (int, float)):
				dd[k] = round(float(v), 4)
		if dd:
			out[p["name"]] = dd
	info = {}
	for k, v in r["m"].info.items():
		if isinstance(v, Vector):
			info[k] = [round(x, 4) for x in v]
			info[k + "_rb"] = rb(v)
		elif isinstance(v, (int, float)):
			info[k] = round(float(v), 4)
		elif isinstance(v, dict):
			info[k] = {kk: (rb(vv) if hasattr(vv, "__len__") and len(vv) == 3 else round(float(vv), 4)) for kk, vv in v.items()}
	return out, info


# ---------------------------------------------------------------- the regions after the Meadow add their rows here
_REGION_FILE = f"C:/Roblox 3rd game/tools/blender/monster_rig_{REGION}.py"
if os.path.exists(_REGION_FILE):
	exec(compile(open(_REGION_FILE).read(), _REGION_FILE, "exec"), globals())

# ---------------------------------------------------------------- main
bpy.ops.wm.open_mainfile(filepath=DIR + "/" + REGION + ".blend")
px = sample_texture()
srcs = {o.name: o for o in bpy.data.objects if o.type == "MESH"}
cam, boneview = setup_render()
results = []
for index, (name, spec) in enumerate(MONSTERS.items()):
	if name not in srcs or (ONLY and name not in ONLY):
		continue
	os.makedirs(f"{TILES}/{name}", exist_ok=True)
	r = build(name, spec, srcs[name], px, index)
	results.append(r)
def solo(r):
	for o in bpy.context.scene.objects:
		if o.type == "MESH":
			o.hide_render = o != r["ob"]


def rb(v):
	"""Blender model axes to Roblox mesh axes: (X, Y, Z) = (-x, z, y)."""
	return [round(-v[0], 3), round(v[2], 3), round(v[1], 3)]


mw, mp, mt, joints = {}, {}, {}, {}
for r in results:
	solo(r)
	if MODE in ("full", "weights"):
		mw[r["name"]] = dict(weights=weights_view(r, cam, boneview))
	if MODE == "weights":
		continue
	A, peak = motions(r)
	# the pose sheet: every extreme, front and side
	if MODE == "full":
		poses = extremes(r)
		at = A["Attack"][2](peak)
		poses.insert(3, ("attack peak", at[0], at[1]))
		centre, span = view_frame(r, 1.45)
		cols = []
		for k, (label, c, d) in enumerate(poses):
			set_pose(r, apply_pose(r, c, d))
			col = dict(label=label)
			for vname, dv in (("front", (0, -1, 0.12)), ("side", (1, 0, 0.08))):
				path = f"{TILES}/{r['name']}/p{k}_{vname}.png"
				shoot(cam, centre, span, dv, path, 300)
				col[vname] = path
			cols.append(col)
		mp[r["name"]] = dict(poses=cols)
		set_pose(r, {})
	r["acts"] = bake_actions(r, A)
	mt[r["name"]] = own_texture(r, cam, MODE == "full")
	arm = r["rig"].data
	heads = {b.name: b.head_local for b in arm.bones}
	g = dict(r["g"])
	if "Top" in heads:
		g["Ht"] = round(heads["Top"].z - heads["Body"].z, 4)
		g["Hb"] = round(g["zeq"] - heads["Body"].z, 4)
	g["dirs_rb"] = {k: rb(v) for k, v in g["dirs"].items()}
	pdata, info = part_data(r)
	joints[r["name"]] = dict(tris=r["tris"], height=round(float(r["m"].co[:, 2].max()), 3), hover=r["spec"]["hover"], peak=peak,
		texture=f"{r['name']}/{r['name']}.png", cage=g,
		bones=[dict(name=b.name, parent=b.parent.name if b.parent else "", blender=[round(x, 3) for x in b.head_local],
			roblox=rb(b.head_local), rest_rotation=[1, 0, 0, 0],
			verts=int((r["W"][:, r["names"].index(b.name)] > 0.5).sum()) if b.name in r["names"] else 0)
			for b in arm.bones],
		parts=pdata, info=info,
		actions={an: [round(T, 3), loop] for an, (T, loop, fn) in A.items()},
		golden=golden(r, A))
with open(f"{TILES}/manifest_weights.json", "w") as f:
	json.dump(mw, f, indent=1)
with open(f"{TILES}/manifest_poses.json", "w") as f:
	json.dump(mp, f, indent=1)
with open(f"{TILES}/manifest_tex.json", "w") as f:
	json.dump(mt, f, indent=1)

if MODE != "weights":
	# every action a take: one NLA strip each, then the FBX with the monster at the origin
	for r in results:
		rig, ob = r["rig"], r["ob"]
		ad = rig.animation_data
		for an, (act, N) in r["acts"].items():
			tr = ad.nla_tracks.new()
			tr.name = an
			st = tr.strips.new(an, 0, act)
			if hasattr(st, "action_slot") and len(act.slots):
				st.action_slot = act.slots[0]
		ad.action = None
		os.makedirs(f"{DIR}/{r['name']}", exist_ok=True)
		keep = rig.location.copy()
		rig.location = (0, 0, 0)
		bpy.context.view_layer.update()
		bpy.ops.object.select_all(action="DESELECT")
		ob.select_set(True)
		rig.select_set(True)
		bpy.context.view_layer.objects.active = rig
		path = f"{DIR}/{r['name']}/{r['name']}.fbx"
		bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH", "ARMATURE"}, axis_forward="-Z", axis_up="Y",
			apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True, bake_space_transform=False,
			mesh_smooth_type="FACE", use_mesh_modifiers=False, use_tspace=False, path_mode="AUTO", embed_textures=False,
			add_leaf_bones=False, use_armature_deform_only=True, bake_anim=True, bake_anim_use_all_bones=True,
			bake_anim_use_nla_strips=True, bake_anim_use_all_actions=False, bake_anim_force_startend_keying=True,
			bake_anim_step=1.0, bake_anim_simplify_factor=0.0)
		rig.location = keep
		# the saved file shows the idle; the takes stay as muted tracks
		for tr in ad.nla_tracks:
			tr.mute = True
		ad.action = r["acts"]["Idle"][0]
		print(f"EXPORT {path} {os.path.getsize(path) // 1024} KB")
	with open(f"{DIR}/rig_{REGION}.json", "w") as f:
		json.dump(joints, f, indent=1)
	if ONLY is None:
		for o in srcs.values():  # the unrigged cut-outs stay in <region>.blend only
			bpy.data.objects.remove(o)
		for o in bpy.context.scene.objects:
			o.hide_render = False
		bpy.ops.wm.save_as_mainfile(filepath=f"{DIR}/{REGION}_rigged.blend", relative_remap=True)
		print(f"EXPORT {DIR}/{REGION}_rigged.blend")
print("DONE")
