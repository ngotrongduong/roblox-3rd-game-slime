# Goo Lineage V2 - the 55 Dual slime skins, drawn by script on the slime body's all-round UV.
#
# Re-runnable, nothing by hand. Run inside headless Blender (numpy; PNGs written through bpy images):
#   blender -b --factory-startup -P tools/skins/make_skins.py -- [--only 1,5,9] [--test] [--render] [--pass N]
# (runner: tools/skins/make_skins.ps1)
#
# Inputs: docs/DUALS.md (the 55-pair table: #, pair, name, body colour, pattern colour), src/shared/Colours.luau
# (the swatch hex of each colour), art/models/slime_body/uv_profile.json (written by tools/blender/slime_body.py:
# the UV's profile r(v), z(v) and arc length L).
# Outputs: art/models/slime_body/skins/<NN>_<slug>.png (2048 x 1024, sRGB, only the pair's two swatch colours
# plus antialiased edges and the soft blends of the soft designs); with --render, front and back renders on the
# body and the contact sheets art/models/slime_body/duals_front.png / duals_back.png (copies of
# review/skins/pN/); with --test, a dots-and-grid test skin rendered front, side, back, top and game camera.
#
# The UV (see slime_body.py): u = angle about the vertical axis, seam at the back centre, front centre u 0.5,
# u grows toward the slime's own left; v = arc length from the centre of the base (0) to the tip (1); image top =
# tip. Every motif is drawn in SURFACE space: each texel's 3D point on the body is known, a scattered motif is a
# decal on the tangent plane at its centre (so it is round at every height and wraps across the seam), all-over
# patterns are functions of arc length, angle or the 3D point, and organic fields are 3D noise on the surface
# (seamless by construction). Edges are antialiased analytically: coverage = 0.5 - d / |grad d| per texel.

import bpy
import sys
import os
import re
import json
import math
import shutil
import numpy as np

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg(name, default):
	if name in ARGV:
		return type(default)(ARGV[ARGV.index(name) + 1])
	return default


ONLY = [int(x) for x in arg("--only", "").split(",") if x.strip()]
TEST = "--test" in ARGV
RENDER = "--render" in ARGV
PASS = arg("--pass", 1)
SKIP_SKINS = "--render-only" in ARGV

ROOT = "C:/Roblox 3rd game/"
BODY = ROOT + "art/models/slime_body/"
SKINS = BODY + "skins/"
REV = BODY + "review/skins/p%d/" % PASS
os.makedirs(SKINS, exist_ok=True)
os.makedirs(REV, exist_ok=True)

W, H = 2048, 1024  # skin size (u across, v down from the tip)
SEED = 20261028
GMAX = 0.004  # max surface distance a texel may span for decal antialiasing (texels are ~0.0016)
TILE = 256  # contact-sheet tile (px)

# ---------------------------------------------------------------- inputs
def read(path):
	with open(path, encoding="utf-8") as f:
		return f.read()


SWATCH = {m.group(1): m.group(2) for m in
	re.finditer(r'colour\("(\w+)", "[^"]+", \d+, "#([0-9a-fA-F]{6})"\)', read(ROOT + "src/shared/Colours.luau"))}
DESIGNS = []
for m in re.finditer(r"^\| (\d+) \| (\w+) \+ (\w+) \| ([^|]+?) \| ([^|]+?) \| (\w+) \| (\w+) \| ([^|]+?) \|$",
		read(ROOT + "docs/DUALS.md"), re.M):
	n = int(m.group(1))
	name = m.group(4).strip()
	DESIGNS.append({"n": n, "name": name, "body": m.group(6), "pattern": m.group(7), "source": m.group(8).strip(),
		"slug": re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")})
assert len(DESIGNS) == 55, "docs/DUALS.md table: %d rows" % len(DESIGNS)
assert len(SWATCH) == 11, SWATCH


def hex_srgb(h):
	return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float32)


UVP = json.loads(read(BODY + "uv_profile.json"))
L = float(UVP["L"])
VV = np.concatenate([[0.0], np.array(UVP["rings"]["v"])[::-1]])  # base centre, contact ring ... tip
RR = np.concatenate([[0.0], np.array(UVP["rings"]["r"])[::-1]])
ZZ = np.concatenate([[0.0], np.array(UVP["rings"]["z"])[::-1]])
V_CONTACT = float(UVP["v_contact"])
S_CONTACT = V_CONTACT * L
R_MAX = float(RR.max())


def rof(v):
	return np.interp(v, VV, RR)


def zof(v):
	return np.interp(v, VV, ZZ)


# texel grid (row 0 = top = tip)
U = ((np.arange(W) + 0.5) / W).astype(np.float64)
V = 1.0 - (np.arange(H) + 0.5) / H
RROW = rof(V)
ZROW = zof(V)
S = V * L  # arc from the base centre
ST = L - S  # arc from the tip
PH = 2 * math.pi * (U - 0.5)
X3 = (RROW[:, None] * np.sin(PH)[None, :]).astype(np.float32)
Y3 = (-RROW[:, None] * np.cos(PH)[None, :]).astype(np.float32)
Z3 = np.repeat(ZROW[:, None], W, 1).astype(np.float32)
UU = np.repeat(U[None, :], H, 0)
SS = np.repeat(S[:, None], W, 1)
STT = L - SS
ZZG = Z3.astype(np.float64)
CIRC = 2 * math.pi * RROW  # circumference per row
CC = np.repeat(CIRC[:, None], W, 1)
AREA = np.repeat(((CIRC / W) * (L / H))[:, None], W, 1)  # surface area of a texel
SIDE = (V >= V_CONTACT)[:, None] * np.ones((1, W), dtype=bool)  # not the flat underside


# ---------------------------------------------------------------- antialiasing and compositing
def aa(d, gmax=None):
	# coverage of the region d < 0, one texel wide edge; d in any unit (the texel gradient sets the width)
	if d.shape[0] < 2 or d.shape[1] < 2:
		return (d < 0).astype(np.float64)
	gy, gx = np.gradient(d)
	g = np.hypot(gx, gy)
	g = np.maximum(g, 1e-9) if gmax is None else np.clip(g, 1e-9, gmax)
	return np.clip(0.5 - d / g, 0.0, 1.0)


class Canvas:
	def __init__(self):
		self.A = np.zeros((H, W), dtype=np.float64)  # pattern-colour coverage

	def over(self, cov, rows=slice(None), cols=slice(None)):
		a = self.A[rows, cols]
		self.A[rows, cols] = a + (1 - a) * cov

	def erase(self, cov, rows=slice(None), cols=slice(None)):
		self.A[rows, cols] = self.A[rows, cols] * (1 - cov)

	def maxi(self, cov, rows=slice(None), cols=slice(None)):
		self.A[rows, cols] = np.maximum(self.A[rows, cols], cov)


def coverage(A):
	w = AREA * SIDE
	return float((A * w).sum() / w.sum())


def quantile_threshold(f, cover):
	# the value t so that f > t covers `cover` of the side surface (area weighted)
	ff = f[::2, ::2][SIDE[::2, ::2]]
	ww = AREA[::2, ::2][SIDE[::2, ::2]]
	o = np.argsort(ff)
	c = np.cumsum(ww[o])
	c /= c[-1]
	return float(ff[o][np.searchsorted(c, 1.0 - cover)])


# ---------------------------------------------------------------- 2D signed distances (motif units: fits radius 1)
def circ(x, y, cx, cy, r):
	return np.hypot(x - cx, y - cy) - r


def ell(x, y, cx, cy, rx, ry):
	return (np.hypot((x - cx) / rx, (y - cy) / ry) - 1.0) * min(rx, ry)


def seg(x, y, ax, ay, bx, by, r):
	pax, pay = x - ax, y - ay
	bax, bay = bx - ax, by - ay
	h = np.clip((pax * bax + pay * bay) / (bax * bax + bay * bay), 0, 1)
	return np.hypot(pax - bax * h, pay - bay * h) - r


def rbox(x, y, cx, cy, hx, hy, r):
	qx = np.abs(x - cx) - hx + r
	qy = np.abs(y - cy) - hy + r
	return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def poly(x, y, pts):
	pts = np.asarray(pts, dtype=np.float64)
	d = (x - pts[0, 0]) ** 2 + (y - pts[0, 1]) ** 2
	s = np.ones_like(x)
	n = len(pts)
	for i in range(n):
		j = i - 1
		ex, ey = pts[j, 0] - pts[i, 0], pts[j, 1] - pts[i, 1]
		wx, wy = x - pts[i, 0], y - pts[i, 1]
		h = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
		bx, by = wx - ex * h, wy - ey * h
		d = np.minimum(d, bx * bx + by * by)
		c1 = y >= pts[i, 1]
		c2 = y < pts[j, 1]
		c3 = ex * wy > ey * wx
		flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
		s = np.where(flip, -s, s)
	return s * np.sqrt(d)


def smin(a, b, k):
	h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
	return b * (1 - h) + a * h - k * h * (1 - h)


def rot2(x, y, a):
	c, s = math.cos(a), math.sin(a)
	return x * c + y * s, -x * s + y * c


def vesica(x, y, r, d):
	px, py = np.abs(x), np.abs(y)
	b = math.sqrt(r * r - d * d)
	return np.where((py - b) * d > px * b, np.hypot(px, py - b), np.hypot(px + d, py) - r)


def arc(x, y, ra, rb, phc, half):
	rho = np.hypot(x, y)
	dph = (np.arctan2(y, x) - phc + math.pi) % (2 * math.pi) - math.pi
	ex = [ra * math.cos(phc + s * half) for s in (-1, 1)]
	ey = [ra * math.sin(phc + s * half) for s in (-1, 1)]
	dend = np.minimum(np.hypot(x - ex[0], y - ey[0]), np.hypot(x - ex[1], y - ey[1]))
	return np.where(np.abs(dph) <= half, np.abs(rho - ra), dend) - rb


def star_pts(n, ro, ri, phase=0.0):
	return [((ro if i % 2 == 0 else ri) * math.sin(phase + math.pi * i / n),
		(ro if i % 2 == 0 else ri) * math.cos(phase + math.pi * i / n)) for i in range(2 * n)]


# ---------------------------------------------------------------- motifs (x right, y toward the tip; prm: 4 randoms)
def m_dot(x, y, prm):
	return np.hypot(x, y) - 1.0


def m_star(x, y, prm):  # owner 09: chubby five-point star, rounded points
	return poly(x, y, star_pts(5, 0.86, 0.47)) - 0.12


def m_heart(x, y, prm):  # owner 03
	a = np.minimum(circ(x, y, -0.43, 0.3, 0.5), circ(x, y, 0.43, 0.3, 0.5))
	t = poly(x, y, [(-0.88, 0.16), (0.0, -0.92), (0.88, 0.16)])
	return smin(a, t, 0.14)


def m_diamond(x, y, prm):  # owner 06: tall diamond
	return poly(x, y, [(0, 0.95), (0.52, 0), (0, -0.95), (-0.52, 0)]) - 0.04


def m_ring(x, y, prm):  # owner 07: open ring
	return np.abs(np.hypot(x, y) - 0.72) - 0.28


def m_sprinkle(x, y, prm):  # owner 10: capsule
	return seg(x, y, 0, -0.68, 0, 0.68, 0.32)


def m_moon(x, y, prm):  # owner 12: crescent
	return np.maximum(circ(x, y, 0, 0, 1.0), -circ(x, y, 0.46, 0.26, 0.8))


def m_sparkle(x, y, prm):  # owner 12: four-point sparkle with concave sides
	p = 0.6
	return (np.abs(x) ** p + np.abs(y) ** p) ** (1 / p) - 1.0


def m_star4(x, y, prm):  # fatter four-point sparkle for tiny stars
	p = 0.8
	return (np.abs(x) ** p + np.abs(y) ** p) ** (1 / p) - 1.0


def m_tri(x, y, prm):  # owner 13: rounded triangle
	return poly(x, y, [(0, 0.84), (0.727, -0.42), (-0.727, -0.42)]) - 0.15


def m_spiral(x, y, prm):  # owner 15: thick spiral, about two turns
	turns, ro, half = 2.15, 0.84, 0.13
	a = (ro - half) / turns  # radius gained per turn
	rho = np.hypot(x, y)
	ph = np.arctan2(y, x) % (2 * math.pi)
	th0, th1 = 0.9, 2 * math.pi * turns
	d = np.full_like(x, 9.0)
	for k in range(4):
		th = ph + 2 * math.pi * k
		ok = (th >= th0) & (th <= th1)
		d = np.where(ok, np.minimum(d, np.abs(rho - a * th / (2 * math.pi))), d)
	for th in (th0, th1):
		rr = a * th / (2 * math.pi)
		d = np.minimum(d, np.hypot(x - rr * math.cos(th), y - rr * math.sin(th)))
	return d - half


def m_flower(x, y, prm):  # owner 16: five round petals, a hole in the middle
	d = circ(x, y, 0, 0, 0.5)
	for i in range(5):
		a = 2 * math.pi * i / 5
		d = np.minimum(d, circ(x, y, 0.56 * math.sin(a), 0.56 * math.cos(a), 0.42))
	return np.maximum(d, -circ(x, y, 0, 0, 0.21))


def m_paw(x, y, prm):  # owner 18
	d = smin(ell(x, y, 0, -0.38, 0.5, 0.38), ell(x, y, 0, -0.2, 0.34, 0.3), 0.1)
	for cx, cy in ((-0.66, 0.12), (-0.25, 0.52), (0.25, 0.52), (0.66, 0.12)):
		d = np.minimum(d, ell(x, y, cx, cy, 0.19, 0.25))
	return d


def m_bolt(x, y, prm):  # owner 19
	return poly(x, y, [(-0.08, 0.98), (0.46, 0.98), (0.14, 0.22), (0.5, 0.22), (-0.36, -0.98), (-0.04, -0.08),
		(-0.44, -0.08)]) - 0.03


def m_leaf(x, y, prm):  # owner 20: leaf with a vein gap
	xs, ys = x / 0.95, y / 0.95
	d = vesica(xs, ys, 1.184, 0.634) * 0.95
	gap = seg(x, y, 0, -0.86, 0, 0.66, 0.05)
	for yy in (-0.42, -0.05, 0.3):
		gap = np.minimum(gap, seg(np.abs(x), y, 0, yy, 0.3, yy + 0.26, 0.035))
	return np.maximum(d, -gap)


def m_bat(x, y, prm):
	ax = np.abs(x)
	y = y + 0.12
	body = smin(ell(x, y, 0, -0.06, 0.2, 0.3), circ(x, y, 0, 0.28, 0.17), 0.06)
	ear = poly(ax, y, [(0.03, 0.36), (0.17, 0.62), (0.17, 0.32)]) - 0.02
	wing = poly(ax, y, [(0.1, 0.24), (0.5, 0.44), (1.0, 0.3), (0.9, -0.2), (0.1, -0.14)]) - 0.02
	for cx in (0.72, 0.42):
		wing = np.maximum(wing, -circ(ax, y, cx, -0.34, 0.2))
	return np.minimum(np.minimum(body, ear), wing)


def m_rosette(x, y, prm):  # leopard rosette: four arcs with gaps
	d = np.full_like(x, 9.0)
	p0 = prm[0] * 2 * math.pi
	for i in range(4):
		half = 0.48 + 0.18 * ((prm[1] * (i + 1) * 7.3) % 1.0)
		d = np.minimum(d, arc(x, y, 0.68, 0.22, p0 + i * math.pi / 2, half))
	return d


def m_drop(x, y, prm):
	return smin(circ(x, y, 0, -0.32, 0.6), poly(x, y, [(-0.5, -0.08), (0, 1.0), (0.5, -0.08)]), 0.12)


def m_crystal(x, y, prm):
	d = np.full_like(x, 9.0)
	for ox, oy, ang, sc in ((0.0, 0.0, 0.0, 1.0), (-0.48, -0.28, 0.5, 0.6), (0.5, -0.32, -0.45, 0.66)):
		xx, yy = rot2(x - ox, y - oy, ang)
		xx, yy = xx / sc, yy / sc
		shard = poly(xx, yy, [(-0.26, -0.9), (0.26, -0.9), (0.26, 0.5), (0, 0.9), (-0.26, 0.5)]) - 0.03
		shard = np.maximum(shard, -seg(xx, yy, 0, -0.62, 0, 0.55, 0.045))
		d = np.minimum(d, shard * sc)
	return d


def m_gear(x, y, prm):
	n = 8
	rho = np.hypot(x, y)
	ph = np.arctan2(y, x) + prm[0]
	rt = 0.84 + 0.14 * np.clip(2.4 * np.cos(n * ph), -1, 1)
	return np.maximum(rho - rt, 0.3 - rho)


def m_cloud(x, y, prm):
	d = smin(circ(x, y, -0.5, -0.12, 0.38), circ(x, y, 0.02, 0.14, 0.5), 0.1)
	d = smin(d, circ(x, y, 0.52, -0.1, 0.38), 0.1)
	return smin(d, rbox(x, y, 0, -0.3, 0.85, 0.22, 0.2), 0.08)


def m_blossom(x, y, prm):
	d = np.full_like(x, 9.0)
	for i in range(5):
		xx, yy = rot2(x, y, 2 * math.pi * i / 5)
		p = np.maximum(circ(xx, yy, 0, 0.5, 0.42), -circ(xx, yy, 0, 1.0, 0.17))
		d = np.minimum(d, p)
	return np.maximum(d, -circ(x, y, 0, 0, 0.14))


def m_snowflake(x, y, prm):
	d = circ(x, y, 0, 0, 0.22)
	for i in range(6):
		a = math.pi / 2 + i * math.pi / 3
		cx, cy = math.cos(a), math.sin(a)
		d = np.minimum(d, seg(x, y, 0, 0, 0.9 * cx, 0.9 * cy, 0.095))
		px, py = 0.52 * cx, 0.52 * cy
		for s in (-1, 1):
			b = a + s * math.radians(50)
			d = np.minimum(d, seg(x, y, px, py, px + 0.32 * math.cos(b), py + 0.32 * math.sin(b), 0.075))
	return d


def m_berry(x, y, prm):
	d = np.full_like(x, 9.0)
	for cx, cy in ((-0.36, -0.36), (0.36, -0.36), (0.0, 0.26)):
		d = np.minimum(d, circ(x, y, cx, cy, 0.335))
	xx, yy = rot2(x - 0.3, y - 0.72, -0.9)
	return np.minimum(d, vesica(xx / 0.26, yy / 0.26, 1.184, 0.634) * 0.26)


def m_pumpkin(x, y, prm):
	c = ell(x, y, 0, -0.16, 0.4, 0.6)
	u = smin(c, np.minimum(ell(x, y, -0.4, -0.2, 0.44, 0.52), ell(x, y, 0.4, -0.2, 0.44, 0.52)), 0.04)
	u = np.where(np.abs(x) > 0.18, np.maximum(u, 0.04 - np.abs(c)), u)
	xx, yy = rot2(x - 0.04, y - 0.52, -0.25)
	return np.minimum(u, rbox(xx, yy, 0, 0, 0.08, 0.18, 0.05))


def m_crown(x, y, prm):
	d = poly(x, y, [(-0.8, -0.62), (0.8, -0.62), (0.86, 0.34), (0.42, -0.02), (0, 0.5), (-0.42, -0.02),
		(-0.86, 0.34)]) - 0.03
	for cx, cy, r in ((-0.86, 0.42, 0.14), (0.86, 0.42, 0.14), (0, 0.62, 0.15)):
		d = np.minimum(d, circ(x, y, cx, cy, r))
	for cx, r in ((0.0, 0.12), (-0.46, 0.09), (0.46, 0.09)):
		d = np.maximum(d, -circ(x, y, cx, -0.36, r))
	return d


def m_fish(x, y, prm):
	d = smin(ell(x, y, -0.16, 0, 0.58, 0.42), poly(x, y, [(0.3, 0), (0.96, 0.48), (0.78, 0), (0.96, -0.48)]) - 0.03,
		0.08)
	d = np.minimum(d, poly(x, y, [(-0.38, 0.3), (0.1, 0.34), (-0.12, 0.58)]) - 0.03)
	return np.maximum(d, -circ(x, y, -0.48, 0.1, 0.085))


def m_daisy(x, y, prm):
	d = np.full_like(x, 9.0)
	for i in range(10):
		a = 2 * math.pi * i / 10
		d = np.minimum(d, seg(x, y, 0.4 * math.sin(a), 0.4 * math.cos(a), 0.8 * math.sin(a), 0.8 * math.cos(a), 0.17))
	return np.maximum(d, -circ(x, y, 0, 0, 0.28))


def m_clover(x, y, prm):
	d = seg(x, y, 0, 0, 0.22, -0.95, 0.065)
	for i in range(4):
		a = math.pi / 4 + i * math.pi / 2
		cx, cy = 0.42 * math.cos(a), 0.42 * math.sin(a)
		xx, yy = rot2(x - cx, y - cy, a - math.pi / 2)
		d = np.minimum(d, m_heart(xx / 0.5, yy / 0.5, prm) * 0.5)
	return d


def m_seed(x, y, prm):
	return m_drop(x, y, prm)


# ---------------------------------------------------------------- surface frames and decals
def frame(uc, vc):
	r, z = float(rof(vc)), float(zof(vc))
	e = 0.004
	tr = float(rof(min(vc + e, 1.0)) - rof(max(vc - e, 0.0)))
	tz = float(zof(min(vc + e, 1.0)) - zof(max(vc - e, 0.0)))
	n = math.hypot(tr, tz)
	tr, tz = tr / n, tz / n
	ph = 2 * math.pi * (uc - 0.5)
	s, c = math.sin(ph), math.cos(ph)
	C = np.array([r * s, -r * c, z])
	eu = np.array([c, s, 0.0])
	ev = np.array([tr * s, -tr * c, tz])
	nn = np.array([tz * s, -tz * c, -tr])
	return C, eu, ev, nn


def box(uc, vc, ext):
	s_c = vc * L
	v0, v1 = (s_c - ext) / L, (s_c + ext) / L
	i0 = max(0, int(math.floor((1 - v1) * H - 0.5)))
	i1 = min(H, int(math.ceil((1 - v0) * H - 0.5)) + 1)
	rmin = float(RROW[i0:i1].min())
	hw = ext / (2 * math.pi * max(rmin, 1e-4)) * 1.15
	if hw >= 0.49:
		cols = slice(None)
	else:
		cols = np.arange(int(math.floor((uc - hw) * W)), int(math.ceil((uc + hw) * W)) + 1) % W
	return slice(i0, i1), cols


def local(uc, vc, R, rot, flip, ext_k=1.4):
	rows, cols = box(uc, vc, R * ext_k)
	C, eu, ev, nn = frame(uc, vc)
	dx = X3[rows][:, cols] - C[0]
	dy = Y3[rows][:, cols] - C[1]
	dz = Z3[rows][:, cols] - C[2]
	X = dx * eu[0] + dy * eu[1] + dz * eu[2]
	Y = dx * ev[0] + dy * ev[1] + dz * ev[2]
	D = dx * nn[0] + dy * nn[1] + dz * nn[2]
	x, y = rot2(X / R, Y / R, rot)
	if flip:
		x = -x
	far = (D < -0.6 * R) | (np.hypot(x, y) > ext_k)
	return rows, cols, x.astype(np.float64), y.astype(np.float64), far


def decal(cv, uc, vc, R, fn, rot=0.0, flip=False, prm=None, op="over"):
	rows, cols, x, y, far = local(uc, vc, R, rot, flip)
	if prm is None:
		prm = np.zeros(4)
	d = np.where(far, 1.5, fn(x, y, prm)) * R
	cov = aa(d, GMAX)
	getattr(cv, op)(cov, rows, cols)


def soft_decal(cv, uc, vc, R, fn, prm=None):
	rows, cols, x, y, far = local(uc, vc, R, 0.0, False)
	cov = np.where(far, 0.0, fn(x, y, prm))
	cv.maxi(cov, rows, cols)


# ---------------------------------------------------------------- Poisson-disc scatter by surface area
def area_sampler(rng, v_lo, v_hi, n):
	vg = np.linspace(v_lo, v_hi, 2000)
	c = np.cumsum(rof(vg))
	c = (c - c[0]) / (c[-1] - c[0])
	return np.interp(rng.random(n), c, vg), rng.random(n)


def point3(u, v):
	r, z = rof(v), zof(v)
	ph = 2 * math.pi * (u - 0.5)
	return np.stack([r * np.sin(ph), -r * np.cos(ph), z], -1)


def scatter(rng, classes, sep=1.18, base_k=0.7, tip_k=1.3, zmin=None, zmax=None, st_min=0.0, placed=None):
	# classes: [(R, tries, fn, rot_deg, flip)], largest first; returns [(u, v, R, fn, rot, flip, prm)]
	out = list(placed or [])
	P = [point3(np.array([p[0]]), np.array([p[1]]))[0] for p in out]
	Rs = [p[2] for p in out]
	for R, tries, fn, rot_deg, can_flip in classes:
		s_lo = S_CONTACT + base_k * R
		s_hi = L - max(tip_k * R, st_min + R)
		vs, us = area_sampler(rng, s_lo / L, s_hi / L, tries)
		zs = zof(vs)
		pts = point3(us, vs)
		for k in range(tries):
			if zmin is not None and zs[k] < zmin:
				continue
			if zmax is not None and zs[k] > zmax:
				continue
			if P:
				d = np.linalg.norm(np.asarray(P) - pts[k], axis=1)
				if np.any(d < (np.asarray(Rs) + R) * sep):
					continue
			P.append(pts[k])
			Rs.append(R)
			rot = math.radians(rng.uniform(-rot_deg, rot_deg))
			flip = bool(can_flip and rng.random() < 0.5)
			out.append((float(us[k]), float(vs[k]), R, fn, rot, flip, rng.random(4)))
	return out


def draw_all(cv, items):
	for u, v, R, fn, rot, flip, prm in items:
		decal(cv, u, v, R, fn, rot, flip, prm)


def scattered(rng, classes, **kw):
	cv = Canvas()
	draw_all(cv, scatter(rng, classes, **kw))
	return cv.A


# ---------------------------------------------------------------- 3D value noise on the surface (seamless)
def hash3(ix, iy, iz, seed):
	h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (seed * 2654435761)
	h &= 0xFFFFFFFF
	h = ((h ^ (h >> 15)) * 2246822519) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 3266489917) & 0xFFFFFFFF
	h ^= h >> 16
	return (h & 0xFFFFFF).astype(np.float64) / 16777216.0


def vnoise(x, y, z, seed):
	ix, iy, iz = np.floor(x), np.floor(y), np.floor(z)
	fx, fy, fz = x - ix, y - iy, z - iz
	ix, iy, iz = ix.astype(np.int64), iy.astype(np.int64), iz.astype(np.int64)
	q = lambda f: f * f * f * (f * (f * 6 - 15) + 10)
	ux, uy, uz = q(fx), q(fy), q(fz)
	out = 0.0
	for dx in (0, 1):
		wx = ux if dx else 1 - ux
		for dy in (0, 1):
			wy = uy if dy else 1 - uy
			for dz in (0, 1):
				wz = uz if dz else 1 - uz
				out = out + wx * wy * wz * hash3(ix + dx, iy + dy, iz + dz, seed)
	return out


def fbm(x, y, z, freq, octaves, seed, gain=0.5):
	tot, amp, norm = 0.0, 1.0, 0.0
	for o in range(octaves):
		f = freq * (2 ** o)
		tot = tot + amp * vnoise(x * f + 17.1 * o, y * f + 5.3 * o, z * f + 11.7 * o, seed + o)
		norm += amp
		amp *= gain
	return tot / norm


def warped(freq, octaves, seed, warp, wfreq=None):
	x, y, z = X3.astype(np.float64), Y3.astype(np.float64), Z3.astype(np.float64)
	wf = wfreq or freq
	qx = fbm(x, y, z, wf, 2, seed + 101) - 0.5
	qy = fbm(x, y, z, wf, 2, seed + 202) - 0.5
	qz = fbm(x, y, z, wf, 2, seed + 303) - 0.5
	return fbm(x + warp * qx, y + warp * qy, z + warp * qz, freq, octaves, seed)


def field_cover(f, cover):
	t = quantile_threshold(f, cover)
	return aa(t - f)


# ---------------------------------------------------------------- Voronoi on the surface
def voronoi_f12(pts):
	pts = np.asarray(pts, dtype=np.float32)
	F1 = np.empty((H, W), dtype=np.float32)
	F2 = np.empty((H, W), dtype=np.float32)
	ch = 16
	for i0 in range(0, H, ch):
		P = np.stack([X3[i0:i0 + ch], Y3[i0:i0 + ch], Z3[i0:i0 + ch]], -1).reshape(-1, 3)
		d2 = ((P[:, None, :] - pts[None, :, :]) ** 2).sum(-1)
		two = np.partition(d2, 1, axis=1)[:, :2]
		F1[i0:i0 + ch] = np.sqrt(two[:, 0]).reshape(-1, W)
		F2[i0:i0 + ch] = np.sqrt(two[:, 1]).reshape(-1, W)
	return F1.astype(np.float64), F2.astype(np.float64)


def row_lattice(a, dy, stagger=True, start=None, top_point=True):
	# points in rows of constant arc length spaced dy, each row with round(circumference / a) points
	pts = []
	s = S_CONTACT + 0.3 * dy if start is None else start
	k = 0
	while s < L - 0.5 * dy:
		v = s / L
		n = max(1, int(round(2 * math.pi * float(rof(v)) / a)))
		off = 0.5 if (stagger and k % 2) else 0.0
		u = (np.arange(n) + off) / n
		pts.extend(point3(u, np.full(n, v)).tolist())
		s += dy
		k += 1
	if top_point:
		pts.append([0.0, 0.0, float(zof(1.0))])
	# underside: a ring and the centre so the base gets cells too
	pts.extend(point3(np.arange(6) / 6, np.full(6, 0.5 * V_CONTACT)).tolist())
	return pts


# ---------------------------------------------------------------- pattern helpers
def band(t, duty, c=0.0):
	# negative inside bands of width `duty` (in periods) centred at t = c + 0.5 + k
	q = (t - c) % 1.0 - 0.5
	return np.abs(q) - duty / 2


def wrapdu(du):
	return (du + 0.5) % 1.0 - 0.5


def smoothstep(a, b, x):
	t = np.clip((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)


RFRAC = (RROW / R_MAX)[:, None]  # radius / widest radius, per row


# ---------------------------------------------------------------- the 55 designs
def d_pinstripe(rng):
	n = 28
	dist = np.abs(wrapdu(UU * n - np.round(UU * n)) / n) * CC  # surface distance to the nearest stripe centre
	return aa(dist - 0.016)


def d_midnight_fade(rng):
	return smoothstep(0.22, 0.72, ZZG)


def d_batwing(rng):
	return scattered(rng, [(0.15, 3000, m_bat, 20, False), (0.115, 3000, m_bat, 25, False)], sep=1.0)


def d_ladybug(rng):
	cap = 0.2
	cv = Canvas()
	cv.over(aa(STT - cap))
	draw_all(cv, scatter(rng, [(0.085, 3000, m_dot, 0, False), (0.06, 3000, m_dot, 0, False)], sep=1.55,
		st_min=cap + 0.04))
	return cv.A


def d_tiger(rng):
	# tapered, wavy strokes: long ones hang from the tip, short ones rise from the base, between them
	d = np.full((H, W), 9.0)
	n = 12
	for i in range(n):
		u0 = (i + rng.uniform(-0.15, 0.15)) / n
		down = i % 2 == 0
		t = STT - 0.04 if down else SS - S_CONTACT  # arc from the stroke's root
		ln = rng.uniform(0.8, 1.05) if down else rng.uniform(0.42, 0.6)
		w0 = rng.uniform(0.17, 0.21) if down else rng.uniform(0.13, 0.16)
		sway = 0.06 * np.sin(2 * math.pi * (t / 0.55) + rng.uniform(0, 6.3)) + 0.04 * t
		x = wrapdu(UU - u0) * CC - sway
		half = 0.5 * w0 * np.clip(1 - t / ln, 0, 1) ** 0.65
		dd = np.where((t >= 0) & (t <= ln), np.abs(x) - half, 9.0)
		d = np.minimum(d, dd)
	return aa(d)


def d_honeycomb(rng):
	a = 0.17
	F1, F2 = voronoi_f12(row_lattice(a, a * math.sqrt(3) / 2))
	return aa((F2 - F1) / 2 - 0.0125)


def d_dragonscale(rng):
	cv = Canvas()
	Rs, t = 0.088, 0.017
	rows = []
	s = S_CONTACT + 0.2 * Rs
	k = 0
	while s < L - 0.6 * Rs:
		rows.append((s, k))
		s += Rs * 0.95
		k += 1
	ring = lambda x, y, p: np.abs(np.hypot(x, y) - (1 - t / (2 * Rs))) - t / (2 * Rs)
	for s, k in rows:  # from the base up: higher rows lie over lower ones (scale edges point down)
		v = s / L
		n = max(1, int(round(2 * math.pi * float(rof(v)) / (2 * Rs))))
		for j in range(n):
			u = (j + (0.5 if k % 2 else 0.0)) / n
			decal(cv, u, v, Rs, m_dot, op="erase")
			decal(cv, u, v, Rs, ring, op="over")
	decal(cv, 0.5, 1.0 - 0.3 * Rs / L, Rs * 0.8, m_dot, op="erase")
	return cv.A


def d_wild_rosette(rng):
	return scattered(rng, [(0.1, 3000, m_rosette, 180, False), (0.08, 3000, m_rosette, 180, False),
		(0.035, 3000, m_dot, 0, False)], sep=1.2)


def d_neon_swirl(rng):
	return scattered(rng, [(0.125, 3000, m_spiral, 180, True), (0.09, 3000, m_spiral, 180, True)], sep=1.12)


def d_moo(rng):
	return field_cover(warped(3.0, 2, 1010, 0.6), 0.33)


def d_drizzle(rng):
	return scattered(rng, [(0.105, 3000, m_drop, 10, False), (0.08, 3000, m_drop, 10, False)], sep=1.15)


def d_geode(rng):
	return scattered(rng, [(0.13, 3000, m_crystal, 20, True), (0.1, 3000, m_crystal, 20, True)], sep=1.05)


def d_brickwork(rng):
	bh, bl, m = 0.085, 0.2, 0.018
	k = np.floor((SS - S_CONTACT) / bh)
	smid = S_CONTACT + (k + 0.5) * bh
	n = np.maximum(1, np.round(2 * math.pi * rof(smid / L) / bl))
	off = 0.5 * (k % 2)
	xb = UU * n + off
	dv = np.abs(xb - np.round(xb)) * CC / n
	dv = np.where(n < 3, 9.0, dv)
	sb = (SS - S_CONTACT) / bh
	dh = np.abs(sb - np.round(sb)) * bh
	return aa(np.minimum(dv, dh) - m / 2)


def d_lava_crack(rng):
	pts = [point3(np.array([p[0]]), np.array([p[1]]))[0] for p in
		scatter(rng, [(0.11, 4000, m_dot, 0, False)], sep=1.0, base_k=0.0, tip_k=0.0)]
	pts += [[0, 0, float(zof(1.0))]]
	x, y, z = X3.astype(np.float64), Y3.astype(np.float64), Z3.astype(np.float64)
	F1, F2 = voronoi_f12(pts)
	e = (F2 - F1) / 2
	wob = fbm(x, y, z, 6.0, 2, 1414)
	half = 0.007 + 0.012 * wob
	core = aa(e - half)
	glow = np.exp(-np.maximum(e - half, 0) / 0.022) * 0.85
	return np.maximum(core, glow * (e > half))


def d_clockwork(rng):
	return scattered(rng, [(0.105, 3000, m_gear, 180, False), (0.075, 3000, m_gear, 180, False),
		(0.05, 3000, m_gear, 180, False)], sep=1.1)


def d_camo(rng):
	return field_cover(warped(4.2, 3, 1616, 0.45), 0.4)


def d_sprinkle(rng):
	return scattered(rng, [(0.078, 6000, m_sprinkle, 180, False)], sep=1.0)


def d_overcast(rng):
	return scattered(rng, [(0.12, 3000, m_cloud, 8, True), (0.09, 3000, m_cloud, 8, True)], sep=1.05)


def d_marble(rng):
	x, y, z = X3.astype(np.float64), Y3.astype(np.float64), Z3.astype(np.float64)
	t = fbm(x, y, z, 1.6, 4, 1919)
	b = 2.4 * (0.8 * z + 0.45 * x - 0.3 * y) + 3.2 * t
	thick = np.abs(np.sin(math.pi * b)) - 0.2
	b2 = 4.1 * (0.5 * z - 0.6 * x + 0.4 * y) + 4.0 * fbm(x, y, z, 2.3, 3, 2020)
	thin = np.abs(np.sin(math.pi * b2)) - 0.08
	return np.maximum(aa(thick), aa(thin))


def d_nebula(rng):
	f = warped(3.0, 4, 2002, 0.9, 2.2)
	t = quantile_threshold(f, 0.36)
	a = smoothstep(t - 0.08, t + 0.08, f)
	cv = Canvas()
	cv.A = a
	items = scatter(rng, [(0.08, 3000, m_star4, 30, False), (0.06, 3000, m_star4, 30, False)], sep=2.0)
	for u, v, R, fn, rot, flip, prm in items:
		p = point3(np.array([u]), np.array([v]))[0]
		i = int(min(H - 1, max(0, (1 - v) * H)))
		j = int(u * W) % W
		if a[i, j] < 0.12:
			decal(cv, u, v, R, fn, rot, flip, prm)
	return cv.A


def d_tartan(rng):
	n = 10
	P = 2 * math.pi * R_MAX / n  # square at the widest
	tv = UU * n
	ts = STT / P
	broad = np.minimum(band(tv, 0.17), band(ts, 0.17))
	thin = np.minimum(np.minimum(band(tv, 0.06, 0.5), band(ts, 0.06, 0.5)),
		np.minimum(band(tv, 0.03, 0.34), band(ts, 0.03, 0.34)))
	return np.maximum(aa(broad), aa(thin))


def d_peach_drip(rng):
	# owner 14: the cap reaches the shoulders (z ~ 0.65), the drips run down toward mid-body
	top = 0.58
	edge = top + 0.03 * np.sin(2 * math.pi * 3 * UU + 0.7)
	d = STT - edge
	n = 10
	us = (np.arange(n) + rng.uniform(-0.2, 0.2, n)) / n + 0.5 / n
	lens = rng.uniform(0.1, 0.36, n)
	lens[::3] += 0.1
	ws = rng.uniform(0.08, 0.115, n)
	for i in range(n):
		x = wrapdu(UU - us[i]) * CC
		dd = seg(x, STT, 0, top, 0, top + lens[i], ws[i] / 2)
		dd = np.minimum(dd, circ(x, STT, 0, top + lens[i], ws[i] * 0.62))
		d = smin(d, dd, 0.05)
	return aa(d)


def d_firefly(rng):
	cv = Canvas()
	items = scatter(rng, [(0.105, 3000, None, 0, False), (0.08, 3000, None, 0, False),
		(0.06, 3000, None, 0, False)], sep=1.1)

	def glow(x, y, prm):
		rho = np.hypot(x, y)
		return np.where(rho < 0.34, 1.0, 0.8 * np.exp(-((rho - 0.34) / 0.3) ** 2))

	for u, v, R, fn, rot, flip, prm in items:
		soft_decal(cv, u, v, R, glow)
		decal(cv, u, v, R * 0.36, m_dot)
	return cv.A


def d_forestpeak(rng):
	return scattered(rng, [(0.085, 3000, m_tri, 180, False), (0.065, 3000, m_tri, 180, False)], sep=1.3)


def d_sakura(rng):
	return scattered(rng, [(0.1, 3000, m_blossom, 180, False), (0.075, 3000, m_blossom, 180, False)], sep=1.12)


def d_deepsea(rng):
	return aa(band(STT / 0.17, 0.5))


def d_snowflake(rng):
	return scattered(rng, [(0.105, 3000, m_snowflake, 30, False), (0.078, 3000, m_snowflake, 30, False)],
		sep=1.05)


def d_berrypatch(rng):
	return scattered(rng, [(0.13, 3000, m_berry, 25, True), (0.1, 3000, m_berry, 25, True)], sep=1.05)


def d_pumpkin_patch(rng):
	return scattered(rng, [(0.13, 3000, m_pumpkin, 15, True), (0.1, 3000, m_pumpkin, 15, True)], sep=1.05)


def d_crowned(rng):
	return scattered(rng, [(0.125, 3000, m_crown, 15, False), (0.095, 3000, m_crown, 15, False)], sep=1.05)


def d_duskmoon(rng):
	return scattered(rng, [(0.1, 3000, m_moon, 35, True), (0.075, 3000, m_moon, 35, True),
		(0.05, 3000, m_sparkle, 15, False), (0.035, 3000, m_sparkle, 15, False)], sep=1.15)


def d_royal_diamond(rng):
	return scattered(rng, [(0.115, 3000, m_diamond, 6, False), (0.085, 3000, m_diamond, 6, False),
		(0.06, 3000, m_diamond, 6, False)], sep=0.95)


def d_periwinkle(rng):
	return scattered(rng, [(0.1, 3000, m_flower, 180, False), (0.075, 3000, m_flower, 180, False)], sep=1.15)


def d_lavender_stripe(rng):
	m, P = 13, 0.2  # helix: 13 turns round, slope ~40 deg at the widest
	return aa(band(STT / P + m * UU, 0.42))


def d_wildfire(rng):
	n = 10
	H_i = np.array([0.5, 0.36, 0.6, 0.4, 0.55, 0.34, 0.62, 0.42, 0.52, 0.38])
	z = ZZG
	sway = 0.13 * np.sin(2 * math.pi * (z * 1.7)) * np.clip(z / 0.5, 0, 1)
	t = UU * n + sway
	idx = np.floor(t).astype(np.int64) % n
	x = t - np.floor(t) - 0.5
	Hh = H_i[idx]
	base = 0.1
	h = base + (Hh - base) * np.clip(1 - np.abs(2 * x), 0, 1) ** 1.25
	return aa(z - h)


def d_starburst(rng):
	return scattered(rng, [(0.1, 3000, m_star, 25, False), (0.072, 3000, m_star, 25, False),
		(0.032, 3000, m_dot, 0, False), (0.022, 3000, m_dot, 0, False)], sep=1.15)


def d_watermelon(rng):
	cv = Canvas()
	cv.over(aa(ZZG - 0.17))
	draw_all(cv, scatter(rng, [(0.075, 4000, m_seed, 12, False)], sep=2.0, zmin=0.3))
	return cv.A


def d_sweetheart(rng):
	return scattered(rng, [(0.11, 3000, m_heart, 20, False), (0.08, 3000, m_heart, 20, False),
		(0.05, 3000, m_heart, 20, False)], sep=1.1)


def d_racer(rng):
	g, w = 0.07, 0.115
	return aa(np.abs(np.abs(X3.astype(np.float64)) - (g / 2 + w / 2)) - w / 2)


def d_pawprint(rng):
	return scattered(rng, [(0.1, 3000, m_paw, 30, False), (0.078, 3000, m_paw, 30, False)], sep=1.1)


def d_ember_chevron(rng):
	n, P = 12, 0.2
	A = (2 * math.pi * RROW[:, None] / (2 * n))  # 45 deg teeth at every height
	tri = np.abs((UU * n) % 1.0 - 0.5) * 2
	return aa(band((STT + A * tri) / P, 0.5))


def d_tangerine(rng):
	cv = Canvas()
	cap = 0.2
	cv.over(aa(STT - cap))
	n = 6
	for i in range(n):
		u = 0.5 + i / n
		R = 0.3 if i % 2 == 0 else 0.25
		v = (L - (cap + R * 0.85)) / L
		decal(cv, u % 1.0, v, R, m_leaf, rot=math.pi + (0.15 if i % 2 else -0.15))
	return cv.A


def d_sunrise_fade(rng):
	return 1.0 - smoothstep(0.14, 0.72, ZZG)


def d_goldfish(rng):
	return scattered(rng, [(0.13, 3000, m_fish, 15, True), (0.1, 3000, m_fish, 15, True)], sep=1.03)


def d_creamsicle_check(rng):
	n = 14
	P = 2 * math.pi * R_MAX / n
	f = np.sin(math.pi * UU * n) * np.sin(math.pi * STT / P)
	return aa(-f)


def d_citrusleaf(rng):
	return scattered(rng, [(0.125, 3000, m_leaf, 180, True), (0.095, 3000, m_leaf, 180, True)], sep=1.02)


def d_lollipop(rng):
	P = 0.6
	return aa(band(STT / P + UU, 0.45))


def d_sunwave(rng):
	P, k = 0.2, 3
	A = 0.07 * RFRAC
	return aa(band((STT + A * np.sin(2 * math.pi * k * UU)) / P, 0.3))


def d_daisy(rng):
	return scattered(rng, [(0.1, 3000, m_daisy, 180, False), (0.075, 3000, m_daisy, 180, False)], sep=1.1)


def d_clover(rng):
	return scattered(rng, [(0.105, 3000, m_clover, 30, True), (0.08, 3000, m_clover, 30, True)], sep=1.08)


def d_seafoam(rng):
	return scattered(rng, [(0.095, 3000, m_ring, 0, False), (0.068, 3000, m_ring, 0, False),
		(0.03, 3000, m_dot, 0, False)], sep=1.2)


def d_mint_chip(rng):
	return scattered(rng, [(0.1, 3000, m_dot, 0, False), (0.065, 3000, m_dot, 0, False),
		(0.036, 3000, m_dot, 0, False)], sep=1.3)


def d_cotton_candy(rng):
	f = warped(2.4, 3, 5353, 1.1, 1.8)
	t = quantile_threshold(f, 0.42)
	return smoothstep(t - 0.05, t + 0.05, f)


def d_lace(rng):
	cv = Canvas()
	bw, rs, hole = 0.08, 0.062, 0.02
	for top in (0.24, 0.66, 1.06):
		bot = top + bw
		n = max(3, int(round(2 * math.pi * float(rof((L - bot) / L)) / (2 * rs))))
		x = (np.mod(UU * n, 1.0) - 0.5) * CC / n
		y = STT - bot
		d = np.maximum(STT - bot, top - STT)
		d = np.minimum(d, np.hypot(x, y) - rs)
		d = np.maximum(d, -(np.hypot(x, STT - (bot + 0.006)) - hole))
		x2 = (np.mod(UU * n + 0.5, 1.0) - 0.5) * CC / n
		d = np.maximum(d, -(np.hypot(x2, STT - (top + bw * 0.45)) - hole * 0.8))
		cv.over(aa(d))
	return cv.A


def d_frostbolt(rng):
	return scattered(rng, [(0.135, 3000, m_bolt, 18, True), (0.105, 3000, m_bolt, 18, True)], sep=0.98)


DRAW = {1: d_pinstripe, 2: d_midnight_fade, 3: d_batwing, 4: d_ladybug, 5: d_tiger, 6: d_honeycomb,
	7: d_dragonscale, 8: d_wild_rosette, 9: d_neon_swirl, 10: d_moo, 11: d_drizzle, 12: d_geode, 13: d_brickwork,
	14: d_lava_crack, 15: d_clockwork, 16: d_camo, 17: d_sprinkle, 18: d_overcast, 19: d_marble, 20: d_nebula,
	21: d_tartan, 22: d_peach_drip, 23: d_firefly, 24: d_forestpeak, 25: d_sakura, 26: d_deepsea, 27: d_snowflake,
	28: d_berrypatch, 29: d_pumpkin_patch, 30: d_crowned, 31: d_duskmoon, 32: d_royal_diamond, 33: d_periwinkle,
	34: d_lavender_stripe, 35: d_wildfire, 36: d_starburst, 37: d_watermelon, 38: d_sweetheart, 39: d_racer,
	40: d_pawprint, 41: d_ember_chevron, 42: d_tangerine, 43: d_sunrise_fade, 44: d_goldfish,
	45: d_creamsicle_check, 46: d_citrusleaf, 47: d_lollipop, 48: d_sunwave, 49: d_daisy, 50: d_clover,
	51: d_seafoam, 52: d_mint_chip, 53: d_cotton_candy, 54: d_lace, 55: d_frostbolt}


# ---------------------------------------------------------------- images
def save_png(path, rgb):
	h, w = rgb.shape[:2]
	px = np.ones((h, w, 4), dtype=np.float32)
	px[..., :3] = rgb
	im = bpy.data.images.new("skin_save", w, h, alpha=True)
	im.pixels.foreach_set(np.ascontiguousarray(px[::-1]).ravel())
	im.filepath_raw = path
	im.file_format = "PNG"
	im.save()
	bpy.data.images.remove(im)


def load_png(path):
	img = bpy.data.images.load(path, check_existing=False)
	w, h = img.size
	arr = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1].copy()
	bpy.data.images.remove(img)
	return arr


def skin_path(d):
	return SKINS + "%02d_%s.png" % (d["n"], d["slug"])


def make_skin(d):
	rng = np.random.default_rng(SEED + d["n"])
	A = np.clip(DRAW[d["n"]](rng), 0, 1)
	b, p = hex_srgb(SWATCH[d["body"]]), hex_srgb(SWATCH[d["pattern"]])
	rgb = b[None, None, :] * (1 - A[..., None]) + p[None, None, :] * A[..., None]
	save_png(skin_path(d), rgb.astype(np.float32))
	return coverage(A)


def make_test():
	# white body; grey grid (16 meridians, rings every 0.1 of arc); black equal discs (radius 0.06) everywhere,
	# one across the seam, one beside the tip: the discs must look round on the body, the grid even, no seam
	rng = np.random.default_rng(7)
	grid = np.minimum(np.abs(wrapdu(UU * 16 - np.round(UU * 16)) / 16) * CC, np.abs(SS / 0.1 - np.round(SS / 0.1)) * 0.1)
	G = aa(grid - 0.003)
	cv = Canvas()
	items = [(0.0, 0.5, 0.06, m_dot, 0, False, np.zeros(4)), (0.5, 1 - 0.13 / L, 0.06, m_ring, 0, False, np.zeros(4))]
	items = scatter(rng, [(0.06, 4000, m_dot, 0, False)], sep=1.9, placed=items, tip_k=1.0, base_k=0.3)
	draw_all(cv, items)
	rgb = np.ones((H, W, 3), dtype=np.float32)
	rgb = rgb * (1 - 0.45 * G[..., None])
	rgb = rgb * (1 - cv.A[..., None])
	save_png(SKINS + "test_uv.png", rgb.astype(np.float32))
	return SKINS + "test_uv.png"


# ---------------------------------------------------------------- renders on the body
def setup_scene():
	bpy.ops.wm.open_mainfile(filepath=BODY + "SlimeBody.blend")
	sc = bpy.context.scene
	try:
		sc.eevee.taa_render_samples = 32
	except AttributeError:
		pass
	body = bpy.data.objects["SlimeBody"]
	hull = bpy.data.objects["SlimeBodyOutline"]
	for name in ("WireView",):
		if name in bpy.data.objects:
			bpy.data.objects[name].hide_render = True
	mat = bpy.data.materials.new("SkinPreview")
	nt = mat.node_tree
	for n in list(nt.nodes):
		if n.type != "OUTPUT_MATERIAL":
			nt.nodes.remove(n)
	bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
	bsdf.inputs["Roughness"].default_value = 0.10  # the game's SurfaceAppearance roughness
	tex = nt.nodes.new("ShaderNodeTexImage")
	tex.extension = "REPEAT"
	nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
	out = [n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"][0]
	nt.links.new(bsdf.outputs[0], out.inputs["Surface"])
	body.data.materials[0] = mat
	hmat = hull.data.materials[0]
	em = [n for n in hmat.node_tree.nodes if n.type == "EMISSION"][0]
	return sc, body, hull, tex, em


def lin(c):
	return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


def cam(name, loc, rot, scale):
	cd = bpy.data.cameras.new(name)
	ob = bpy.data.objects.new(name, cd)
	bpy.context.scene.collection.objects.link(ob)
	ob.location = loc
	ob.rotation_euler = [math.radians(a) for a in rot]
	cd.type = "ORTHO"
	cd.ortho_scale = scale
	cd.clip_end = 100
	return ob


def label_obj():
	cu = bpy.data.curves.new("Label", "FONT")
	cu.align_x = "CENTER"
	cu.align_y = "CENTER"
	cu.size = 0.105
	ob = bpy.data.objects.new("Label", cu)
	bpy.context.scene.collection.objects.link(ob)
	m = bpy.data.materials.new("LabelMat")
	nt = m.node_tree
	for n in list(nt.nodes):
		if n.type != "OUTPUT_MATERIAL":
			nt.nodes.remove(n)
	e = nt.nodes.new("ShaderNodeEmission")
	e.inputs["Color"].default_value = (0.02, 0.02, 0.03, 1)
	nt.links.new(e.outputs[0], [n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"][0].inputs["Surface"])
	cu.materials.append(m)
	ob.visible_shadow = False
	return ob, cu


def render(camob, path, w, h):
	sc = bpy.context.scene
	sc.camera = camob
	sc.render.resolution_x = w
	sc.render.resolution_y = h
	sc.render.resolution_percentage = 100
	sc.render.filepath = path
	bpy.ops.render.render(write_still=True)
	return path


def over_bg(rgba, bg=0.92):
	a = rgba[..., 3:4]
	return np.dstack([rgba[..., :3] * a + bg * (1 - a), np.ones(rgba.shape[:2] + (1,), dtype=np.float32)])


def grid_sheet(tiles, per_row, gap=6):
	th, tw = tiles[0].shape[:2]
	rows = []
	for r in range(0, len(tiles), per_row):
		row = tiles[r:r + per_row]
		while len(row) < per_row:
			row.append(np.full((th, tw, 4), 0.92, dtype=np.float32))
		parts = []
		for i, t in enumerate(row):
			parts.append(t)
			if i < per_row - 1:
				parts.append(np.ones((th, gap, 4), dtype=np.float32))
		rows.append(np.hstack(parts))
		rows.append(np.ones((gap, rows[-1].shape[1], 4), dtype=np.float32))
	return np.vstack(rows[:-1])


def render_designs(designs):
	sc, body, hull, tex, em = setup_scene()
	cf = cam("SkinFront", (0, -10, 0.5), (90, 0, 0), 1.42)
	cb = cam("SkinBack", (0, 10, 0.5), (90, 0, 180), 1.42)
	lab, cu = label_obj()
	front, back = [], []
	for d in designs:
		img = bpy.data.images.load(skin_path(d), check_existing=False)
		tex.image = img
		# the outline hull is the body colour x 0.6, as in the game (tools/slime/showcase.luau)
		rc = hex_srgb(SWATCH[d["body"]]) * 0.6
		em.inputs["Color"].default_value = lin(list(rc)) + [1.0]
		cu.body = "%d %s" % (d["n"], d["name"])
		for camob, side, lst, loc, rot in ((cf, "front", front, (0, -3, -0.13), (90, 0, 0)),
				(cb, "back", back, (0, 3, -0.13), (90, 0, 180))):
			lab.location = loc
			lab.rotation_euler = [math.radians(a) for a in rot]
			p = render(camob, REV + "%02d_%s.png" % (d["n"], side), TILE, TILE)
			lst.append(over_bg(load_png(p)))
		bpy.data.images.remove(img)
	sf = grid_sheet(front, 11)
	sb_ = grid_sheet(back, 11)
	save_png(REV + "duals_front.png", sf[..., :3])
	save_png(REV + "duals_back.png", sb_[..., :3])
	if len(designs) == 55:
		shutil.copyfile(REV + "duals_front.png", BODY + "duals_front.png")
		shutil.copyfile(REV + "duals_back.png", BODY + "duals_back.png")


def render_test(path):
	sc, body, hull, tex, em = setup_scene()
	img = bpy.data.images.load(path, check_existing=False)
	tex.image = img
	em.inputs["Color"].default_value = (0.25, 0.25, 0.28, 1)
	hull.hide_render = True
	tiles = []
	for name in ("CamFront", "CamSide", "CamBack", "CamTop", "CamGame", "CamGameBack"):
		p = render(bpy.data.objects[name], REV + "test_%s.png" % name, 400, 400)
		tiles.append(over_bg(load_png(p)))
	sheet = grid_sheet(tiles, 6)
	save_png(REV + "test_uv_sheet.png", sheet[..., :3])


# ---------------------------------------------------------------- main
def main():
	todo = [d for d in DESIGNS if not ONLY or d["n"] in ONLY]
	if TEST:
		p = make_test()
		render_test(p)
		print("[make_skins] test sheet", REV + "test_uv_sheet.png")
		if not ONLY and not RENDER:
			return
	stats = {}
	if not SKIP_SKINS:
		for d in todo:
			c = make_skin(d)
			stats[d["n"]] = round(c, 3)
			print("[make_skins] %02d %-18s body %-6s pattern %-6s cover %.3f" % (d["n"], d["name"], d["body"],
				d["pattern"], c))
		with open(REV + "coverage.json", "w") as f:
			json.dump({"%02d_%s" % (d["n"], d["slug"]): stats[d["n"]] for d in todo}, f, indent=1)
	if RENDER:
		render_designs(todo)
		print("[make_skins] sheets", REV + "duals_front.png", REV + "duals_back.png")


main()
