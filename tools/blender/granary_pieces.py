# The Granary's regular hard pieces (docs/areas/village-v2/hard-pieces.md, B1-B7), the Kitchen's two (B8, B9) and the
# Garden's two (B10, B11), the Breeding House's two (B12, B13) and the Training Hall's one (B14), built by script, no
# textures.
# Owner 2026-11-16: "những khối và hình mà khó dựng thì hoặc là bạn tự dựng trên blender rồi ghép vào, hoặc để tôi tự dựng".
# 1 Blender unit = 1 stud, Z up (Roblox +Y after export). Every object of a piece is one colour slot (the game paints it);
# the preview paints the slots flat. Run: tools/blender/granary_pieces.ps1. Out: art/models/granary/blender/.
import json
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

ROOT = "C:/Roblox 3rd game/"
OUT = ROOT + "art/models/granary/blender/"
TAU = 2 * math.pi

COL = {
	"Tiles": (0.75, 0.25, 0.2), "Finial": (0.9, 0.68, 0.2), "Glass": (0.45, 0.8, 0.85), "Frame": (0.25, 0.3, 0.33),
	"Shell": (0.2, 0.35, 0.8), "Gold": (0.9, 0.68, 0.2), "Shaft": (0.93, 0.9, 0.82), "Base": (0.9, 0.68, 0.2),
	"Capital": (0.9, 0.68, 0.2), "Run": (0.93, 0.9, 0.82), "Post": (0.93, 0.9, 0.82), "Urn": (0.9, 0.68, 0.2),
	"Elbow": (0.78, 0.45, 0.25), "Flange": (0.9, 0.68, 0.2), "Wheel": (0.9, 0.68, 0.2), "Blades": (0.6, 0.42, 0.26),
	"Egg": (0.98, 0.94, 0.84), "Spots": (0.69, 0.57, 0.89), "Ribs": (0.2, 0.2, 0.23), "Rim": (0.84, 0.28, 0.47),
	"Heart": (1.0, 0.48, 0.64), "Disc": (0.69, 0.5, 0.31), "Steel": (0.82, 0.83, 0.86),
}


class M:
	def __init__(s):
		s.v, s.f = [], []

	def add(s, pts):
		i = len(s.v)
		s.v.extend(pts)
		return i


def bridge(m, a, b, n):
	if len(a) == 1 and len(b) == 1:
		return
	for i in range(n):
		j = (i + 1) % n
		if len(a) == 1:
			m.f.append((a[0], b[j], b[i]))
		elif len(b) == 1:
			m.f.append((a[i], a[j], b[0]))
		else:
			m.f.append((a[i], a[j], b[j], b[i]))


def lathe(m, prof, sides, cap_bottom=False, cap_top=False, loop=False, phase=0.0):
	# prof: (r, z[, zig]) from bottom to top; r = 0 makes a single pole vertex; zig lifts every odd vertex of the ring
	i_start = len(m.v)
	rings = []
	for p in prof:
		r, z = p[0], p[1]
		zig = p[2] if len(p) > 2 else 0.0
		if r < 1e-6:
			rings.append([m.add([(0.0, 0.0, z)])])
			continue
		pts = []
		for i in range(sides):
			a = TAU * i / sides + phase
			pts.append((r * math.cos(a), r * math.sin(a), z + (zig if i % 2 else 0.0)))
		i0 = m.add(pts)
		rings.append(list(range(i0, i0 + sides)))
	pairs = list(zip(rings, rings[1:]))
	if loop:
		pairs.append((rings[-1], rings[0]))
	for a, b in pairs:
		bridge(m, a, b, sides)
	if cap_bottom and len(rings[0]) > 1:
		c = m.add([(0.0, 0.0, prof[0][1])])
		for i in range(sides):
			m.f.append((c, rings[0][(i + 1) % sides], rings[0][i]))
	if cap_top and len(rings[-1]) > 1:
		c = m.add([(0.0, 0.0, prof[-1][1])])
		for i in range(sides):
			m.f.append((c, rings[-1][i], rings[-1][(i + 1) % sides]))
	return i_start, len(m.v)


def xform(m, rng, fn):
	for i in range(*rng):
		m.v[i] = fn(m.v[i])


def box(m, c, s, rot=0.0):
	cx, cy, cz = c
	hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
	cs, sn = math.cos(rot), math.sin(rot)
	pts = []
	for z in (-hz, hz):
		for x, y in ((-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy)):
			pts.append((cx + x * cs - y * sn, cy + x * sn + y * cs, cz + z))
	i = m.add(pts)
	for q in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
		m.f.append(tuple(i + k for k in q))


def sweep(m, sections, cap_end=True):
	# sections: list of 4-vertex cross sections in the same cyclic order
	rings = []
	for sec in sections:
		i0 = m.add(sec)
		rings.append(list(range(i0, i0 + len(sec))))
	for a, b in zip(rings, rings[1:]):
		bridge(m, a, b, len(a))
	m.f.append(tuple(reversed(rings[0])))
	if cap_end:
		m.f.append(tuple(rings[-1]))


def rib(m, pts, normals, phi, hw, ht):
	# a square-section rib along a meridian: ht = half thickness along the normal, hw = half width sideways
	e = Vector((-math.sin(phi), math.cos(phi), 0))
	secs = []
	for p, n in zip(pts, normals):
		p, n = Vector(p), Vector(n)
		secs.append([tuple(p - n * ht - e * hw), tuple(p + n * ht - e * hw), tuple(p + n * ht + e * hw), tuple(p - n * ht + e * hw)])
	sweep(m, secs, cap_end=False)


def merid(r, a, phi):
	return (r * math.cos(a) * math.cos(phi), r * math.cos(a) * math.sin(phi), r * math.sin(a))


# ---------------------------------------------------------------- the pieces: each returns [(name, M, loc, slot, smooth_angle)]


def cone_roof():
	# 5 stacked lampshades on a straight cone (eave radius 1, ~54 degrees): each course's lower edge stands 0.06 proud of the
	# course below (a flat ledge) and is a 0.07 high vertical lip; the lowest course kicks out 0.04 at the eave.
	H, pitch = 1.3, 0.26
	R = lambda z: 0.96 * (1 - z / H)
	prof = []
	for c in range(5):
		b = c * pitch
		prof.append((R(0) + 0.04, 0.0) if c == 0 else (R(b), b))  # lower edge of the lip
		prof.append((R(b) + (0.005 if c == 0 else 0.0), b + 0.07))  # lip top
		prof.append((R(b + pitch) - 0.06, b + pitch) if c < 4 else (0.0, H))  # meets the next course's ledge
	t = M()
	lathe(t, prof, 16)
	f = M()
	lathe(f, [(0.03, 1.26), (0.03, 1.3), (0.078, 1.312), (0.11, 1.39), (0.078, 1.468), (0.0, 1.5)], 8, cap_bottom=True)
	return [("ConeRoof_Tiles", t, (0, 0, 0), "Tiles", 40), ("ConeRoof_Finial", f, (0, 0, 0), "Finial", 60)]


def glass_dome():
	lat = [0, 22.5, 45, 67.5]
	outer = [(math.cos(math.radians(a)), math.sin(math.radians(a))) for a in lat] + [(0.0, 1.0)]
	ri = 0.965
	inner = [(r * ri, z * ri) for r, z in reversed(outer)]
	g = M()
	lathe(g, outer + inner, 16, loop=True)
	fr = M()
	lathe(fr, [(0.94, 0.0), (1.06, 0.0), (1.06, 0.08), (0.94, 0.08)], 16, loop=True)  # base ring
	lathe(fr, [(0.84, 0.47), (0.9, 0.47), (0.9, 0.53), (0.84, 0.53)], 16, loop=True)  # ring at half height
	angs = [math.radians(a) for a in lat + [90]]
	for k in range(8):
		phi = TAU * k / 8
		pts = [merid(1.02, a, phi) for a in angs]
		rib(fr, pts, [merid(1.0, a, phi) for a in angs], phi, 0.03, 0.025)
	fi = M()
	lathe(fi, [(0.06, 0.99), (0.06, 1.03), (0.1, 1.07), (0.1, 1.11), (0.05, 1.15), (0.02, 1.17), (0.0, 1.36)], 8, cap_bottom=True)
	return [("GlassDome_Glass", g, (0, 0, 0), "Glass", 60), ("GlassDome_Frame", fr, (0, 0, 0), "Frame", 40),
		("GlassDome_Finial", fi, (0, 0, 0), "Finial", 60)]


def royal_dome():
	sp = [(1.0, 0.05), (1.0, 0.25), (0.93, 0.5), (0.78, 0.76), (0.55, 0.99), (0.3, 1.15), (0.2, 1.22)]
	sh = M()
	lathe(sh, [(0.0, 0.05)] + sp, 16, cap_top=True)
	gd = M()
	lathe(gd, [(0.94, 0.0), (1.07, 0.0), (1.07, 0.07), (0.94, 0.12)], 16, loop=True)  # moulded base ring
	pts, nrm = [], []
	for i, (r, z) in enumerate(sp):
		a, b = sp[max(i - 1, 0)], sp[min(i + 1, len(sp) - 1)]
		n2 = Vector((b[1] - a[1], -(b[0] - a[0]))).normalized()  # outward profile normal
		pts.append((r, z))
		nrm.append((n2.x, n2.y))
	for k in range(8):
		phi = TAU * k / 8
		c, s = math.cos(phi), math.sin(phi)
		rib(gd, [((r + 0.015 * n[0]) * c, (r + 0.015 * n[0]) * s, z + 0.015 * n[1]) for (r, z), n in zip(pts, nrm)],
			[(n[0] * c, n[0] * s, n[1]) for n in nrm], phi, 0.03, 0.025)
	lathe(gd, [(0.22, 1.2), (0.22, 1.27), (0.15, 1.27), (0.15, 1.48), (0.22, 1.48), (0.22, 1.53), (0.0, 1.68)], 8)  # lantern
	lathe(gd, [(0.0, 1.66), (0.06, 1.7), (0.07, 1.74), (0.06, 1.78), (0.02, 1.81), (0.02, 1.86), (0.035, 1.88), (0.035, 1.92),
		(0.0, 1.95)], 8)  # finial: ball, spike, ball
	return [("RoyalDome_Shell", sh, (0, 0, 0), "Shell", 60), ("RoyalDome_Gold", gd, (0, 0, 0), "Gold", 40)]


def column():
	sh = M()
	lathe(sh, [(0.5, 0.0), (0.46, 1.0)], 12, cap_bottom=True, cap_top=True)
	ba = M()
	box(ba, (0, 0, 0.075), (1.3, 1.3, 0.15))
	lathe(ba, [(0.58, 0.15), (0.65, 0.19), (0.65, 0.25), (0.54, 0.3), (0.58, 0.34), (0.58, 0.41), (0.5, 0.45)], 12, cap_top=True)
	ca = M()
	lathe(ca, [(0.46, 0.0), (0.5, 0.12), (0.58, 0.3), (0.66, 0.52)], 12, cap_bottom=True, cap_top=True)
	box(ca, (0, 0, 0.61), (1.4, 1.4, 0.18))
	for k in range(8):  # chunky leaf scallops round the bell: a tapered block, small at the foot, wide and proud at the lip
		phi = TAU * k / 8
		u, v = Vector((math.cos(phi), math.sin(phi), 0)), Vector((-math.sin(phi), math.cos(phi), 0))
		def P(rad, tan, z):
			return tuple(u * rad + v * tan + Vector((0, 0, z)))
		pts = [P(0.47, -0.06, 0.06), P(0.47, 0.06, 0.06), P(0.54, 0.06, 0.06), P(0.54, -0.06, 0.06),
			P(0.55, -0.14, 0.44), P(0.55, 0.14, 0.44), P(0.71, 0.14, 0.44), P(0.71, -0.14, 0.44)]
		i = ca.add(pts)
		for q in ((0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
			ca.f.append(tuple(i + t for t in q))
	return [("Column_Shaft", sh, (0, 0, 0.45), "Shaft", 40), ("Column_Base", ba, (0, 0, 0), "Base", 40),
		("Column_Capital", ca, (0, 0, 1.45), "Capital", 40)]


def balustrade():
	run = M()
	box(run, (0, 0, 0.07), (4.0, 0.3, 0.14))
	box(run, (0, 0, 1.03), (4.0, 0.35, 0.14))
	for k in range(5):
		x = -1.6 + 0.8 * k
		i = lathe(run, [(0.07, 0.14), (0.1, 0.3), (0.06, 0.55), (0.085, 0.78), (0.06, 0.96)], 8)
		xform(run, i, lambda p, x=x: (p[0] + x, p[1], p[2]))
	po = M()
	box(po, (0, 0, 0.6), (0.5, 0.5, 1.2))
	box(po, (0, 0, 1.25), (0.6, 0.6, 0.1))
	ur = M()
	lathe(ur, [(0.0, 0.0), (0.12, 0.0), (0.14, 0.06), (0.2, 0.18), (0.12, 0.3), (0.08, 0.38), (0.12, 0.43), (0.0, 0.5)], 8)
	return [("Balustrade_Run", run, (0, 0, 0), "Run", 50), ("Balustrade_Post", po, (2.5, 0, 0), "Post", 40),
		("Balustrade_Urn", ur, (2.5, 0, 1.3), "Urn", 60)]


def pipe():
	pr, bend = 0.25, 0.7
	el = M()
	rings = []
	for k in range(6):
		th = math.radians(-90 - 18 * k)
		cen = Vector((bend + bend * math.cos(th), 0, bend + bend * math.sin(th)))
		nn = Vector((math.cos(th), 0, math.sin(th)))
		rings.append([tuple(cen + pr * (math.cos(TAU * i / 10) * nn + math.sin(TAU * i / 10) * Vector((0, 1, 0)))) for i in range(10)])
	idx = []
	for r in rings:
		i0 = el.add(r)
		idx.append(list(range(i0, i0 + 10)))
	for a, b in zip(idx, idx[1:]):
		bridge(el, a, b, 10)
	fl = [(0.36, -0.06), (0.36, 0.06)]
	rng = lathe(el, fl, 10, cap_bottom=True, cap_top=True)  # end A, axis X, flush with the bend end at x = 0.7
	xform(el, rng, lambda p: (p[2] + 0.64, p[1], p[0]))
	rng = lathe(el, fl, 10, cap_bottom=True, cap_top=True)  # end B, axis Z, flush at z = 0.7
	xform(el, rng, lambda p: (p[0], p[1], p[2] + 0.64))
	f = M()
	lathe(f, fl, 10, cap_bottom=True, cap_top=True)
	return [("Pipe_Elbow", el, (0, 0, 0), "Elbow", 50), ("Pipe_Flange", f, (1.8, 0, 0), "Flange", 50)]


def gear():
	teeth, rt, ro, ri = 12, 0.82, 1.0, 0.7
	half = 0.15
	outl = []
	for k in range(teeth):
		a = TAU * k / teeth
		for da, r in ((-6.5, rt), (-4.5, ro), (4.5, ro), (6.5, rt)):
			outl.append((r * math.cos(a + math.radians(da)), r * math.sin(a + math.radians(da))))
	inl = [(ri * math.cos(TAU * (j + 0.5) / teeth), ri * math.sin(TAU * (j + 0.5) / teeth)) for j in range(teeth)]
	m = M()
	for z in (half, -half):
		m.add([(x, y, z) for x, y in outl])
		m.add([(x, y, z) for x, y in inl])
	no, ni = len(outl), len(inl)
	of, if_, ob, ib = 0, no, no + ni, no + ni + no
	for j in range(teeth):
		S = [of + (4 * j + 3 + t) % no for t in range(6)]
		a, b = if_ + j, if_ + (j + 1) % ni
		tris = [(a, S[0], S[1]), (a, S[1], S[2]), (a, S[2], b), (b, S[2], S[3]), (b, S[3], S[4]), (b, S[4], S[5])]
		for t in tris:
			m.f.append(t)
			m.f.append(tuple((q - of + ob) if q < no else (q - if_ + ib) for q in reversed(t)))
	for i in range(no):
		j = (i + 1) % no
		m.f.append((of + i, ob + i, ob + j, of + j))
	for i in range(ni):
		j = (i + 1) % ni
		m.f.append((if_ + i, if_ + j, ib + j, ib + i))
	for j in range(6):  # six spokes
		a = TAU * j / 6
		box(m, (0.46 * math.cos(a), 0.46 * math.sin(a), 0), (0.62, 0.13, 0.2), a)
	lathe(m, [(0.24, -half), (0.24, half)], 12, cap_bottom=True, cap_top=True)  # hub
	lathe(m, [(0.14, -half - 0.08), (0.14, half + 0.08)], 8, cap_bottom=True, cap_top=True)  # boss through both faces
	xform(m, (0, len(m.v)), lambda p: (p[0], p[2], p[1]))  # stand it up: face towards the front, thickness along Y
	return [("Gear_Wheel", m, (0, 0, 0), "Wheel", 40)]


def chimney_crown():
	# the Kitchen's (ladder step 22): a hollow band of radius 1 with a rolled foot, twelve points and a ball on each
	sides, ro, ri, band, tip = 24, 1.0, 0.9, 0.5, 0.5
	m = M()
	prof = [(ro, 0.0), (ro + 0.07, 0.06), (ro, 0.12), (ro, band - 0.1), (ro + 0.05, band - 0.05), (ro, band, tip),
		(ri, band, tip), (ri, 0.0)]
	lathe(m, prof, sides, loop=True)
	r, mid = 0.085, (ro + ri) / 2
	for k in range(1, sides, 2):
		a = TAU * k / sides
		rng = lathe(m, [(0.0, -r), (r * 0.7, -r * 0.7), (r, 0.0), (r * 0.7, r * 0.7), (0.0, r)], 6)
		xform(m, rng, lambda p: (p[0] + mid * math.cos(a), p[1] + mid * math.sin(a), p[2] + band + tip + r * 0.6))
	return [("ChimneyCrown_Gold", m, (0, 0, 0), "Gold", 40)]


def vent_hood():
	# the Kitchen's cooking line: a hollow copper hood of radius 1, a rolled rim, a cone and a collar for its stem
	m = M()
	prof = [(0.98, 0.0), (1.04, 0.05), (0.98, 0.1), (0.94, 0.13), (0.36, 0.62), (0.36, 0.66), (0.31, 0.68), (0.31, 0.75),
		(0.26, 0.75), (0.26, 0.6), (0.9, 0.08), (0.9, 0.0)]
	lathe(m, prof, 16, loop=True)
	return [("VentHood_Copper", m, (0, 0, 0), "Elbow", 40)]


def wind_wheel():
	# the Garden's (ladder step 10): a many-bladed farm wind wheel of radius 1, held at its hub, its face to the front.
	# Twelve pitched blades that widen outward, two hoops through them, six spokes behind, a short hub.
	m = M()
	blades, r0, r1, pitch, ht = 12, 0.24, 0.98, math.radians(24), 0.012
	for k in range(blades):
		a = TAU * k / blades
		rad, tan = Vector((math.cos(a), math.sin(a), 0)), Vector((-math.sin(a), math.cos(a), 0))
		secs = []
		for r, hw in ((r0, 0.045), (r1, 0.2)):
			sec = []
			for w, t in ((-hw, -ht), (hw, -ht), (hw, ht), (-hw, ht)):
				w2, t2 = w * math.cos(pitch) - t * math.sin(pitch), w * math.sin(pitch) + t * math.cos(pitch)
				sec.append(tuple(rad * r + tan * w2 + Vector((0, 0, t2))))
			secs.append(sec)
		sweep(m, secs)
	for r in (0.36, 0.8):
		lathe(m, [(r - 0.022, -0.025), (r + 0.022, -0.025), (r + 0.022, 0.025), (r - 0.022, 0.025)], 24, loop=True)
	for j in range(6):
		a = TAU * (j + 0.5) / 6
		box(m, (0.44 * math.cos(a), 0.44 * math.sin(a), -0.07), (0.74, 0.05, 0.04), a)
	lathe(m, [(0.13, -0.1), (0.13, 0.06)], 12, cap_bottom=True, cap_top=True)
	xform(m, (0, len(m.v)), lambda p: (p[0], p[2], p[1]))  # stand it up: face towards the front, thickness along Y
	return [("WindWheel_Blades", m, (0, 0, 0), "Blades", 40)]


def irrigation_arch():
	# the Garden's (ladder step 36): a copper hoop over a bed, half a span of 1 and 1 high (the game stretches it), held
	# at the middle of its foot: a tube, a collar at each foot, three sprinkler heads that point at the bed
	m = M()
	pr, seg, sides = 0.042, 14, 6
	idx = []
	for k in range(seg + 1):
		th = math.pi * k / seg
		nn = Vector((math.cos(th), 0, math.sin(th)))
		i0 = m.add([tuple(nn + pr * (math.cos(TAU * i / sides) * nn + math.sin(TAU * i / sides) * Vector((0, 1, 0))))
			for i in range(sides)])
		idx.append(list(range(i0, i0 + sides)))
	for a, b in zip(idx, idx[1:]):
		bridge(m, a, b, sides)
	for s in (-1, 1):
		rng = lathe(m, [(0.085, 0.0), (0.085, 0.07), (0.05, 0.1)], 8, cap_bottom=True, cap_top=True)
		xform(m, rng, lambda p: (p[0] + s, p[1], p[2]))
	for deg in (48, 90, 132):
		th = math.radians(deg)
		base = Vector((math.cos(th), 0, math.sin(th))) * (1 - pr * 0.5)
		d, e = Vector((-math.cos(th), 0, -math.sin(th))), Vector((-math.sin(th), 0, math.cos(th)))
		rng = lathe(m, [(0.03, 0.0), (0.03, 0.07), (0.095, 0.13), (0.095, 0.16)], 8, cap_bottom=True, cap_top=True)
		xform(m, rng, lambda p: tuple(base + d * p[2] + e * p[0] + Vector((0, p[1], 0))))
	return [("IrrigationArch_Copper", m, (0, 0, 0), "Elbow", 50)]


def egg_r(z):
	# the egg's outline: widest (radius 1) at 0.3 above its foot, a short round belly below, a tall ovoid above (top at 1.9)
	a = 1.0 if z < 0.3 else 1.6
	return math.sqrt(max(0.0, 1 - ((z - 0.3) / a) ** 2))


def egg_pt(z, phi, out=0.0):
	# a point of the egg's skin pushed `out` along its normal, and that normal
	a = 1.0 if z < 0.3 else 1.6
	r = egg_r(z)
	n = Vector((r, (z - 0.3) / (a * a))).normalized()
	rr = r + out * n.x
	return (rr * math.cos(phi), rr * math.sin(phi), z + out * n.y), (n.x * math.cos(phi), n.x * math.sin(phi), n.y)


def egg_dome():
	# the Breeding House's (ladder steps 10, 20, 30, 40, 50): the giant egg of radius 1 and 1.9 high, held at the middle of
	# its foot. Its spots stand proud as their own object (the game lights them), the eight meridian ribs and the three
	# bands are the last two eras' cage.
	sides = 20
	ups = [math.radians(a) for a in (12, 24, 36, 48, 60, 72, 82)]
	sh = M()
	lathe(sh, [(egg_r(z), z) for z in (0.0, 0.12, 0.3)] + [(math.cos(a), 0.3 + 1.6 * math.sin(a)) for a in ups] + [(0.0, 1.9)],
		sides, cap_bottom=True)
	sp = M()
	# (height, degrees round, radius, stretch along the meridian): between the ribs and clear of the bands
	for z0, deg, rs, st in ((0.64, 67.5, 0.2, 1.1), (0.58, 202.5, 0.18, 1.0), (0.66, 337.5, 0.19, 1.2), (1.06, 22.5, 0.16, 1.0),
		(1.04, 157.5, 0.17, 1.15), (1.0, 292.5, 0.16, 1.0), (0.98, 112.5, 0.15, 1.2), (0.62, 247.5, 0.14, 1.0),
		(1.56, 247.5, 0.11, 1.0), (1.58, 67.5, 0.1, 1.1), (1.55, 337.5, 0.1, 1.0), (1.02, 337.5, 0.1, 1.0)):
		phi = math.radians(deg)
		nz = egg_pt(z0, phi)[1][2]
		along = math.sqrt(1 - nz * nz)  # how much of a step along the meridian is height
		top = [sp.add([egg_pt(z0, phi, 0.045)[0]])]
		rings = []
		for f, out in ((0.6, 0.038), (1.0, 0.006)):
			pts = []
			for k in range(8):
				t = TAU * k / 8
				z = z0 + rs * st * f * math.sin(t) * along
				pts.append(egg_pt(z, phi + rs * f * math.cos(t) / max(egg_r(z), 0.2), out)[0])
			i0 = sp.add(pts)
			rings.append(list(range(i0, i0 + 8)))
		under = [sp.add([egg_pt(z0, phi, -0.06)[0]])]
		for a, b in zip([top] + rings, rings + [under]):
			bridge(sp, a, b, 8)
	rb = M()
	zs = [0.0, 0.15, 0.3] + [0.3 + 1.6 * math.sin(math.radians(a)) for a in (12, 24, 36, 48, 60, 70)]
	for k in range(8):
		phi = TAU * k / 8
		both = [egg_pt(z, phi, 0.02) for z in zs]
		rib(rb, [p for p, _ in both], [n for _, n in both], phi, 0.035, 0.03)
	bd = M()
	lathe(bd, [(0.97, 0.25), (1.06, 0.25), (1.06, 0.35), (0.97, 0.35)], sides, loop=True)  # the belt
	lathe(bd, [(0.75, 1.3), (0.84, 1.3), (0.8, 1.38), (0.7, 1.38)], sides, loop=True)  # the upper band
	lathe(bd, [(0.25, 1.78), (0.4, 1.78), (0.37, 1.86), (0.2, 1.9)], sides, loop=True)  # the ring the ribs end in
	return [("EggDome_Shell", sh, (0, 0, 0), "Egg", 60), ("EggDome_Spots", sp, (0, 0, 0), "Spots", 50),
		("EggDome_Ribs", rb, (0, 0, 0), "Ribs", 40), ("EggDome_Bands", bd, (0, 0, 0), "Gold", 40)]


def stack(m, ring, centre, layers):
	# a closed puffy body from one flat outline: `layers` are (scale about the centre, z) from the back pole to the front one
	cx, cy = centre
	n = len(ring)
	rows = []
	for s, z in layers:
		if s < 1e-6:
			rows.append([m.add([(cx, cy, z)])])
		else:
			i0 = m.add([(cx + (x - cx) * s, cy + (y - cy) * s, z) for x, y in ring])
			rows.append(list(range(i0, i0 + n)))
	for a, b in zip(rows, rows[1:]):
		bridge(m, a, b, n)


def heart_emblem():
	# the Breeding House's emblem (ladder steps 6 and 7): a puffy heart about 2 wide in a raised rim with an egg on it,
	# held at its middle, its face to the front, the same on its back
	n, k = 40, 0.9 / 16
	line = []
	for i in range(n):
		t = TAU * i / n
		line.append((16 * math.sin(t) ** 3 * k,
			(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t) + 2.5) * k))
	puff = lambda s: 0.05 + 0.17 * math.sqrt(1 - s * s)
	half = [(s, puff(s)) for s in (0.25, 0.55, 0.82, 1.0)]
	h = M()
	stack(h, line, (0.0, 0.05), [(0.0, -0.22)] + [(s, -z) for s, z in half] + [(s, z) for s, z in reversed(half)] + [(0.0, 0.22)])
	r = M()
	rows = []
	for i in range(n):
		a, b, p = line[i - 1], line[(i + 1) % n], line[i]
		nx, ny = -(b[1] - a[1]), b[0] - a[0]  # the outline runs clockwise: its left is outside
		d = math.hypot(nx, ny)
		nx, ny = nx / d, ny / d
		i0 = r.add([(p[0] + nx * o, p[1] + ny * o, z) for o, z in ((-0.03, -0.11), (0.07, -0.15), (0.11, -0.07), (0.11, 0.07),
			(0.07, 0.15), (-0.03, 0.11))])
		rows.append(list(range(i0, i0 + 6)))
	for i in range(n):
		bridge(r, rows[i], rows[(i + 1) % n], 6)
	e = M()
	egg = []
	for i in range(20):
		t = TAU * i / 20
		egg.append((0.4 * math.sin(t) * (1 - 0.2 * math.cos(t)), 0.06 + 0.5 * math.cos(t)))
	stack(e, egg, (0.0, 0.03), [(0.0, -0.27), (0.5, -0.265), (0.85, -0.235), (1.0, -0.14), (1.0, 0.14), (0.85, 0.235),
		(0.5, 0.265), (0.0, 0.27)])
	for m in (h, r, e):
		xform(m, (0, len(m.v)), lambda p: (p[0], p[2], p[1]))  # stand it up: face towards the front, thickness along Y
	return [("HeartEmblem_Rim", r, (0, 0, 0), "Rim", 50), ("HeartEmblem_Heart", h, (0, 0, 0), "Heart", 60),
		("HeartEmblem_Egg", e, (0, 0, 0), "Egg", 60)]


def shield_emblem():
	# the Training Hall's emblem (ladder step 2): a round shield 2 wide with a raised rim and two crossed swords on its
	# face, points up; held at its middle, its face to the front, its back plain (it hangs on a wall)
	sides = 24
	d = M()
	lathe(d, [(0.0, -0.2), (0.5, -0.17), (0.86, -0.1), (0.86, 0.1), (0.5, 0.17), (0.0, 0.2)], sides)
	r = M()
	lathe(r, [(0.82, -0.12), (0.9, -0.18), (1.0, -0.13), (1.0, 0.13), (0.9, 0.18), (0.82, 0.12)], sides, loop=True)
	bl, hl = M(), M()
	for s, z in ((1, 0.25), (-1, 0.31)):
		a = s * math.pi / 4  # the sword leans this far from upright
		ux, uy = math.sin(a), math.cos(a)  # along the sword
		vx, vy = math.cos(a), -math.sin(a)  # across it
		secs = []
		for u, half, thick in ((-0.5, 0.11, 0.045), (0.92, 0.09, 0.04), (1.2, 0.005, 0.005)):
			cx, cy = ux * u, uy * u
			secs.append([(cx - vx * half, cy - vy * half, z), (cx, cy, z + thick), (cx + vx * half, cy + vy * half, z),
				(cx, cy, z - thick)])
		sweep(bl, secs)
		for u, su, sv in ((-0.55, 0.11, 0.6), (-0.8, 0.4, 0.1), (-1.06, 0.17, 0.17)):  # the guard, the grip, the pommel
			box(hl, (ux * u, uy * u, z), (sv, su, 0.1), -a)
	for m in (d, r, bl, hl):
		xform(m, (0, len(m.v)), lambda p: (p[0], p[2], p[1]))  # stand it up: face towards the front, thickness along Y
	return [("ShieldEmblem_Disc", d, (0, 0, 0), "Disc", 40), ("ShieldEmblem_Rim", r, (0, 0, 0), "Gold", 50),
		("ShieldEmblem_Blades", bl, (0, 0, 0), "Steel", 30), ("ShieldEmblem_Hilts", hl, (0, 0, 0), "Gold", 30)]


PIECES = [("ConeRoof", cone_roof), ("GlassDome", glass_dome), ("RoyalDome", royal_dome), ("Column", column),
	("Balustrade", balustrade), ("Pipe", pipe), ("Gear", gear), ("ChimneyCrown", chimney_crown), ("VentHood", vent_hood),
	("WindWheel", wind_wheel), ("IrrigationArch", irrigation_arch), ("EggDome", egg_dome), ("HeartEmblem", heart_emblem),
	("ShieldEmblem", shield_emblem)]


# ---------------------------------------------------------------- Blender side


def clear():
	for ob in list(bpy.data.objects):
		bpy.data.objects.remove(ob, do_unlink=True)
	for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
		for d in list(coll):
			coll.remove(d)


def to_object(name, m, loc, slot, angle):
	me = bpy.data.meshes.new(name)
	me.from_pydata(m.v, [], m.f)
	me.update()
	bm = bmesh.new()
	bm.from_mesh(me)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	lim = math.radians(angle)
	for f in bm.faces:
		f.smooth = True
	for e in bm.edges:
		if len(e.link_faces) == 2:
			e.smooth = e.calc_face_angle(0.0) <= lim
	bm.to_mesh(me)
	bm.free()
	ob = bpy.data.objects.new(name, me)
	ob.location = loc
	bpy.context.scene.collection.objects.link(ob)
	mat = bpy.data.materials.new(slot)
	mat.diffuse_color = COL[slot] + (1.0,)
	me.materials.append(mat)
	return ob


def volume(ob):
	return sum(p.center.dot(p.normal) * p.area for p in ob.data.polygons) / 3.0


def render(objs, path):
	sc = bpy.context.scene
	bpy.context.view_layer.update()
	lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
	for ob in objs:
		for v in ob.data.vertices:
			w = ob.matrix_world @ v.co
			lo = Vector(map(min, lo, w))
			hi = Vector(map(max, hi, w))
	ctr, size = (lo + hi) / 2, (hi - lo)
	d = Vector((1.0, -1.25, 0.85)).normalized()
	cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
	sc.collection.objects.link(cam)
	cam.data.type = "ORTHO"
	cam.data.ortho_scale = size.length * 0.95 + 0.2
	cam.location = ctr + d * 30
	cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
	sc.camera = cam
	w = bpy.data.worlds.new("W")
	w.color = (0.62, 0.62, 0.62)
	sc.world = w
	sc.render.engine = "BLENDER_WORKBENCH"
	sc.display.shading.color_type = "MATERIAL"
	sc.display.shading.light = "STUDIO"
	sc.view_settings.view_transform = "Standard"
	sc.render.resolution_x = sc.render.resolution_y = 800
	sc.render.filepath = path
	bpy.ops.render.render(write_still=True)


def export(objs, path):
	bpy.ops.object.select_all(action="DESELECT")
	for ob in objs:
		ob.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	kw = dict(filepath=path, use_selection=True, object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
		apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True, bake_space_transform=False,
		mesh_smooth_type="EDGE", use_mesh_modifiers=False, use_tspace=False, path_mode="AUTO", add_leaf_bones=False)
	bpy.ops.export_scene.fbx(**kw)


PREVIEW_HEAD = """local AssetService = game:GetService('AssetService')
local SS = game:GetService('ServerStorage')
local folder = SS:FindFirstChild('GranaryPreview') or Instance.new('Folder')
folder.Name = 'GranaryPreview'
folder.Parent = SS
local made = {}
local function make(name, size, at, v, t)
	local old = folder:FindFirstChild(name) if old then old:Destroy() end
	local em = AssetService:CreateEditableMesh()
	local ids = {}
	for k = 0, #v / 3 - 1 do ids[k + 1] = em:AddVertex(Vector3.new(v[k * 3 + 1], v[k * 3 + 2], v[k * 3 + 3])) end
	for k = 0, #t / 3 - 1 do em:AddTriangle(ids[t[k * 3 + 1]], ids[t[k * 3 + 2]], ids[t[k * 3 + 3]]) end
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	part.Name = name .. 'Part' part.Anchored = true part.Material = Enum.Material.SmoothPlastic
	part.Size = Vector3.new(size[1], size[2], size[3]) part.CFrame = CFrame.new(at[1], at[2], at[3])
	local model = Instance.new('Model') model.Name = name part.Parent = model model.Parent = folder
	table.insert(made, name)
end
"""


def bounds(ob):
	# size and centre from the piece's foot, in Roblox axes (x, y up, z = -Blender y)
	w = [ob.matrix_world @ v.co for v in ob.data.vertices]
	pts = [(p.x, p.z, -p.y) for p in w]
	lo = [min(p[i] for p in pts) for i in range(3)]
	hi = [max(p[i] for p in pts) for i in range(3)]
	return pts, [hi[i] - lo[i] for i in range(3)], [(hi[i] + lo[i]) / 2 for i in range(3)]


def preview(objs, path):
	# A Luau script that builds the same objects in an open Studio place with EditableMesh (ServerStorage.GranaryPreview),
	# so a piece is judged on the building before it is uploaded (tools/map/landmark_preview.luau). A vertex is split where
	# its corners' normals differ, so Studio's own normals keep the sharp edges.
	lines = [PREVIEW_HEAD]
	for ob in objs:
		me = ob.data
		me.calc_loop_triangles()
		pts, size, ctr = bounds(ob)
		index, v, t = {}, [], []
		for lt in me.loop_triangles:
			for li, vi in zip(lt.loops, lt.vertices):
				n = me.corner_normals[li].vector
				key = (vi, round(n.x, 2), round(n.y, 2), round(n.z, 2))
				if key not in index:
					index[key] = len(index) + 1
					v.append("%.3f,%.3f,%.3f" % tuple(pts[vi][i] - ctr[i] for i in range(3)))
				t.append(str(index[key]))
		lines.append("make('%s', {%.3f,%.3f,%.3f}, {%.3f,%.3f,%.3f}, {%s}, {%s})" % (ob.name, *size, *ctr, ",".join(v), ",".join(t)))
		lines.append("task.wait()")
	lines.append("return table.concat(made, ', ')")
	with open(path, "w") as fh:
		fh.write("\n".join(lines))


# `-- <folder>` after Blender's own arguments also writes the Studio preview scripts there
PREVIEW = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else None
os.makedirs(OUT, exist_ok=True)
report = {}
for pname, fn in PIECES:
	clear()
	objs = [to_object(n, m, loc, slot, ang) for n, m, loc, slot, ang in fn()]
	info = {}
	for ob in objs:
		mm = [ob.matrix_world @ v.co for v in ob.data.vertices]
		mn = [min(c[i] for c in mm) for i in range(3)]
		mx = [max(c[i] for c in mm) for i in range(3)]
		sz = [mx[i] - mn[i] for i in range(3)]
		info[ob.name] = {"size_studs_xyz": [round(sz[0], 3), round(sz[2], 3), round(sz[1], 3)],  # Roblox axes: X, Y (up), Z
			"centre_studs_xyz": [round(c, 3) for c in bounds(ob)[2]],  # from the piece's foot: Config.LibraryKit's `at`
			"triangles": sum(len(p.vertices) - 2 for p in ob.data.polygons), "origin_location_blender": list(ob.location),
			"signed_volume": round(volume(ob), 3)}
	report[pname] = {"objects": info, "triangles": sum(o["triangles"] for o in info.values())}
	render(objs, OUT + pname + ".png")
	export(objs, OUT + pname + ".fbx")
	if PREVIEW:
		os.makedirs(PREVIEW, exist_ok=True)
		preview(objs, os.path.join(PREVIEW, pname + ".luau"))
with open(OUT + "pieces.json", "w") as fh:
	json.dump(report, fh, indent=1)
for k, v in report.items():
	print("[granary_pieces]", k, v["triangles"], {n: (o["triangles"], o["size_studs_xyz"], o["signed_volume"]) for n, o in v["objects"].items()})
