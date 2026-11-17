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
	"Stone": (0.84, 0.82, 0.77), "Brick": (0.78, 0.44, 0.29), "TechGlass": (0.35, 0.85, 0.72), "Iron": (0.22, 0.24, 0.28),
	"Slate": (0.24, 0.38, 0.63), "Copper": (0.89, 0.52, 0.31), "DoorIron": (0.15, 0.16, 0.19), "Glow": (1.0, 0.8, 0.3),
	"Marble": (0.98, 0.97, 0.95), "Royal": (0.17, 0.33, 0.67), "Sky": (0.5, 0.68, 0.88),
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


def fish_emblem():
	# the Dock's emblem (ladder step 6): a round sign 2 wide with a raised rim and a fish in relief on its face, its head
	# to the viewer's left; held at its middle, its face to the front, its back plain (it hangs on a gable). The eye is
	# its own object so every era can colour it.
	sides = 24
	d = M()
	lathe(d, [(0.0, -0.2), (0.5, -0.17), (0.86, -0.1), (0.86, 0.1), (0.5, 0.17), (0.0, 0.2)], sides)
	r = M()
	lathe(r, [(0.82, -0.12), (0.9, -0.18), (1.0, -0.13), (1.0, 0.13), (0.9, 0.18), (0.82, 0.12)], sides, loop=True)
	f = M()
	# (outlines run clockwise seen from the front; each is star-shaped round its own centre, so `stack` can puff it)
	# (drawn with the head at -x, then mirrored: on a wall in the game the model's +x is the viewer's left)
	flip = lambda ring: [(-x, y) for x, y in reversed(ring)]
	top = [(-0.62, 0.0), (-0.56, 0.13), (-0.43, 0.23), (-0.22, 0.3), (0.0, 0.27), (0.18, 0.17), (0.32, 0.08)]
	body = top + [(x, -y * 0.92) for x, y in reversed(top[1:])]
	stack(f, flip(body), (0.15, 0.0), [(0.0, 0.1), (1.0, 0.12), (1.0, 0.25), (0.85, 0.32), (0.5, 0.365), (0.0, 0.38)])
	tail = [(0.2, 0.08), (0.62, 0.3), (0.7, 0.27), (0.56, 0.0), (0.7, -0.27), (0.62, -0.3), (0.2, -0.08)]
	stack(f, flip(tail), (-0.45, 0.0), [(0.0, 0.1), (1.0, 0.12), (1.0, 0.22), (0.8, 0.28), (0.0, 0.3)])
	dorsal = [(-0.3, 0.26), (-0.12, 0.44), (0.1, 0.36), (0.12, 0.2)]
	stack(f, flip(dorsal), (0.05, 0.3), [(0.0, 0.12), (1.0, 0.14), (1.0, 0.21), (0.7, 0.25), (0.0, 0.26)])
	belly = [(-0.22, -0.22), (0.02, -0.2), (0.0, -0.4), (-0.12, -0.36)]
	stack(f, flip(belly), (0.08, -0.29), [(0.0, 0.12), (1.0, 0.14), (1.0, 0.21), (0.7, 0.25), (0.0, 0.26)])
	e = M()
	eye = [(0.42 + 0.06 * math.sin(TAU * i / 10), 0.07 + 0.06 * math.cos(TAU * i / 10)) for i in range(10)]
	stack(e, eye, (0.42, 0.07), [(0.0, 0.3), (1.0, 0.31), (1.0, 0.39), (0.6, 0.41), (0.0, 0.415)])
	for m in (d, r, f, e):
		xform(m, (0, len(m.v)), lambda p: (p[0], p[2], p[1]))  # stand it up: face towards the front, thickness along Y
	return [("FishEmblem_Disc", d, (0, 0, 0), "Disc", 40), ("FishEmblem_Rim", r, (0, 0, 0), "Gold", 50),
		("FishEmblem_Fish", f, (0, 0, 0), "Steel", 60), ("FishEmblem_Eye", e, (0, 0, 0), "Ribs", 60)]


# ---------------------------------------------------------------- whole small buildings: the garden's tool stores
# (the owner, 2026-11-17: "blender dựng hình tốt hơn là dùng roblox tại sao bạn không dùng cách đó?"). One object a
# material, all held at the middle of the building's foot, the door on +Y; every block chamfered so the game's light
# draws its edges. Reference: docs/areas/village-v2/garden-toolstore-ref.jpg.


def cbox(m, c, s, ch=0.08, rot=0.0):
	# a box with every edge chamfered `ch`
	h = [s[0] / 2, s[1] / 2, s[2] / 2]
	ch = min(ch, min(h) * 0.8)
	cs, sn = math.cos(rot), math.sin(rot)
	idx, pts = {}, []
	for sx in (-1, 1):
		for sy in (-1, 1):
			for sz in (-1, 1):
				sg = (sx, sy, sz)
				for a in range(3):  # the corner's vertex on the face across axis a
					p = [sg[i] * (h[i] - (0 if i == a else ch)) for i in range(3)]
					idx[(sg, a)] = len(pts)
					pts.append((c[0] + p[0] * cs - p[1] * sn, c[1] + p[0] * sn + p[1] * cs, c[2] + p[2]))
	i0 = m.add(pts)

	def V(sg, a):
		return i0 + idx[(tuple(sg), a)]

	for a in range(3):
		b, c2 = (a + 1) % 3, (a + 2) % 3
		for s1 in (-1, 1):
			q = []
			for sb, sc in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
				sg = [0, 0, 0]
				sg[a], sg[b], sg[c2] = s1, sb, sc
				q.append(V(sg, a))
			m.f.append(tuple(q))
		for sb in (-1, 1):
			for sc in (-1, 1):
				lo = [0, 0, 0]
				lo[a], lo[b], lo[c2] = -1, sb, sc
				hi = list(lo)
				hi[a] = 1
				m.f.append((V(lo, b), V(hi, b), V(hi, c2), V(lo, c2)))
	for sx in (-1, 1):
		for sy in (-1, 1):
			for sz in (-1, 1):
				m.f.append((V((sx, sy, sz), 0), V((sx, sy, sz), 1), V((sx, sy, sz), 2)))


def bar(m, p1, p2, w, t):
	# a square bar from p1 to p2, `w` wide sideways and `t` thick
	a, b = Vector(p1), Vector(p2)
	d = (b - a).normalized()
	side = d.cross(Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))).normalized()
	nrm = side.cross(d).normalized()
	sweep(m, [[tuple(p - side * w / 2 - nrm * t / 2), tuple(p + side * w / 2 - nrm * t / 2),
		tuple(p + side * w / 2 + nrm * t / 2), tuple(p - side * w / 2 + nrm * t / 2)] for p in (a, b)])


def arch_band(m, cx, cz, r0, r1, y0, y1, a0=0.0, a1=math.pi, n=12, kz=1.0):
	# a band r0..r1 round (cx, cz) in the XZ plane from angle a0 to a1, y0..y1 deep; kz < 1 flattens it into an ellipse
	secs = []
	for k in range(n + 1):
		a = a0 + (a1 - a0) * k / n
		c, s = math.cos(a), math.sin(a) * kz
		secs.append([(cx + r0 * c, y0, cz + r0 * s), (cx + r1 * c, y0, cz + r1 * s), (cx + r1 * c, y1, cz + r1 * s),
			(cx + r0 * c, y1, cz + r0 * s)])
	sweep(m, secs)


def prism(m, outline, y0, y1):
	# an outline of (x, z) points in the XZ plane, y0..y1 thick
	k = len(outline)
	i = m.add([(x, y0, z) for x, z in outline] + [(x, y1, z) for x, z in outline])
	m.f.append(tuple(range(i, i + k)))
	m.f.append(tuple(range(i + 2 * k - 1, i + k - 1, -1)))
	for j in range(k):
		j2 = (j + 1) % k
		m.f.append((i + j, i + j2, i + k + j2, i + k + j))


def arc(cx, cz, r, a0=0.0, a1=math.pi, n=12, kz=1.0):
	return [(cx + r * math.cos(a0 + (a1 - a0) * k / n), cz + kz * r * math.sin(a0 + (a1 - a0) * k / n)) for k in range(n + 1)]


def arch_slab(m, cx, z0, zs, r, y0, y1, n=12):
	# a door leaf or a pane: a rectangle from z0 to the spring zs with a half circle on it
	prism(m, [(cx - r, z0), (cx + r, z0)] + arc(cx, zs, r, n=n), y0, y1)


def stud(m, p, d, r=0.18):
	# a rivet head at p, bulging along the unit axis d
	rng = lathe(m, [(r, 0.0), (r * 0.75, r * 0.55), (0.0, r * 0.8)], 5, cap_bottom=True)
	p, d = Vector(p), Vector(d)
	u = Vector((0, 0, 1)).cross(d)
	u = u.normalized() if u.length > 1e-6 else Vector((1, 0, 0))
	v = d.cross(u)
	xform(m, rng, lambda q: tuple(p + u * q[0] + v * q[1] + d * q[2]))


def lat(m, prof, sides, x, y, **kw):
	rng = lathe(m, prof, sides, **kw)
	xform(m, rng, lambda q: (q[0] + x, q[1] + y, q[2]))


def ball(m, c, r, sides=10, rings=6):
	prof = [(0.0, c[2] - r)] + [(r * math.cos(-math.pi / 2 + math.pi * k / rings), c[2] + r * math.sin(-math.pi / 2 + math.pi * k / rings))
		for k in range(1, rings)] + [(0.0, c[2] + r)]
	lat(m, prof, sides, c[0], c[1])


def pillow(m, poly, n, proud=0.07, inset=0.07):
	# a block or a tile standing `proud` off its plane (normal n), its edges bevelled back to the plane, so every joint
	# between neighbours is a real groove the game's light draws
	poly, n, k = [Vector(p) for p in poly], Vector(n), len(poly)
	top = []
	for i, p in enumerate(poly):
		a, b = (poly[i - 1] - p).normalized(), (poly[(i + 1) % k] - p).normalized()
		top.append(p + (a + b) * (inset / max(a.cross(b).length, 0.35)) + n * proud)
	i0 = m.add([tuple(p) for p in poly] + [tuple(p) for p in top])
	m.f.append(tuple(range(i0, i0 + k)))
	m.f.append(tuple(range(i0 + k, i0 + 2 * k)))
	for i in range(k):
		j = (i + 1) % k
		m.f.append((i0 + i, i0 + j, i0 + k + j, i0 + k + i))


def tiles(m, o, du, dv, cols, rows, proud=0.07, inset=0.07):
	# a wall of blocks on the rectangle from o spanned by du and dv (du x dv points out), every other row half a block on
	o, du, dv = Vector(o), Vector(du), Vector(dv)
	n = du.cross(dv).normalized()
	for r in range(rows):
		cuts = [c / cols for c in range(cols + 1)]
		if r % 2:
			cuts = [0.0] + [(c + 0.5) / cols for c in range(cols)] + [1.0]
		for a, b in zip(cuts, cuts[1:]):
			p, q = o + dv * (r / rows), o + dv * ((r + 1) / rows)
			pillow(m, [p + du * a, p + du * b, q + du * b, q + du * a], n, proud, inset)


def block_run(m, a, b, z0, h, d, n, ch=0.1):
	# n chamfered blocks in a row from a to b (x, y), each `d` deep and `h` high: a plinth course
	(ax, ay), (bx, by) = a, b
	run = math.hypot(bx - ax, by - ay) / n
	for k in range(n):
		t = (k + 0.5) / n
		cbox(m, (ax + (bx - ax) * t, ay + (by - ay) * t, z0 + h / 2), (run, d, h) if abs(bx - ax) > abs(by - ay) else (d, run, h), ch)


def clip(poly, f):
	# the part of a 2D polygon where the linear f is not negative
	out = []
	for i, p in enumerate(poly):
		q = poly[(i + 1) % len(poly)]
		fp, fq = f(p), f(q)
		if fp >= 0:
			out.append(p)
		if (fp >= 0) != (fq >= 0):
			t = fp / (fp - fq)
			out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
	return [p for i, p in enumerate(out) if math.dist(p, out[i - 1]) > 1e-4]


def tile_roof(m, hx0, hy0, z0, hx1, hy1, z1, rows, w, cy=0.0, lip=0.26, drop=0.2):
	# a hipped roof in `rows` courses: each course's foot stands `lip` proud of the course below and hangs over it, and
	# each slope of a course is cut into tiles `w` wide (every other course half a tile on), trimmed at the hips
	for k in range(rows):
		t0, t1 = k / rows, (k + 1) / rows
		ax, ay, az = hx0 + (hx1 - hx0) * t0, hy0 + (hy1 - hy0) * t0, z0 + (z1 - z0) * t0
		bx, by, bz = hx0 + (hx1 - hx0) * t1, hy0 + (hy1 - hy0) * t1, z0 + (z1 - z0) * t1
		if k:
			ax, ay, az = ax + lip, ay + lip, az - drop
		i = m.add([(-ax, cy - ay, az), (ax, cy - ay, az), (ax, cy + ay, az), (-ax, cy + ay, az), (-bx, cy - by, bz),
			(bx, cy - by, bz), (bx, cy + by, bz), (-bx, cy + by, bz)])
		for q in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
			m.f.append(tuple(i + j for j in q))
		for sgn in (-1, 1):
			for along_x in (True, False):
				la, lb = (ax, bx) if along_x else (ay, by)  # half the eave's length at the course's foot and top
				da, db = (ay, by) if along_x else (ax, bx)  # how far out the slope is there
				rise = (0, sgn * (bz - az), da - db) if along_x else (sgn * (bz - az), 0, da - db)
				j0 = int(la / w) + 2
				for j in range(-j0, j0):
					u0 = j * w + (w / 2 if k % 2 else 0.0)
					poly = clip([(u0, 0.0), (u0 + w, 0.0), (u0 + w, 1.0), (u0, 1.0)], lambda p: la + (lb - la) * p[1] - p[0])
					poly = clip(poly, lambda p: la + (lb - la) * p[1] + p[0])
					if len(poly) < 3 or max(p[0] for p in poly) - min(p[0] for p in poly) < 0.35:
						continue
					pts = []
					for u, s in poly:
						d, z = sgn * (da + (db - da) * s), az + (bz - az) * s
						pts.append((u, cy + d, z) if along_x else (d, cy + u, z))
					pillow(m, pts, Vector(rise).normalized(), 0.06, 0.06)


def tube(m, pts, y, r, sides=8):
	# a round pipe along a path of (x, z) points in the plane y
	rings = []
	for k, (x, z) in enumerate(pts):
		a, b = pts[max(k - 1, 0)], pts[min(k + 1, len(pts) - 1)]
		d = Vector((b[0] - a[0], 0, b[1] - a[1])).normalized()
		nn = Vector((-d.z, 0, d.x))
		i0 = m.add([tuple(Vector((x, y, z)) + r * (math.cos(TAU * i / sides) * nn + math.sin(TAU * i / sides) * Vector((0, 1, 0))))
			for i in range(sides)])
		rings.append(list(range(i0, i0 + sides)))
	for a, b in zip(rings, rings[1:]):
		bridge(m, a, b, sides)
	m.f.append(tuple(reversed(rings[0])))
	m.f.append(tuple(rings[-1]))


def cog(m, cx, cz, r, y0, y1, teeth=8):
	# a gear wheel on a wall that faces +Y, with a proud hub
	out = []
	for k in range(teeth):
		a = TAU * k / teeth
		w = TAU / teeth
		for da, rr in ((-0.3 * w, r * 0.78), (-0.17 * w, r), (0.17 * w, r), (0.3 * w, r * 0.78)):
			out.append((cx + rr * math.cos(a + da), cz + rr * math.sin(a + da)))
	prism(m, out, y0, y1)
	prism(m, arc(cx, cz, r * 0.5, 0.0, TAU * 11 / 12, 11), y1 - 0.02, y1 + 0.1)
	prism(m, arc(cx, cz, r * 0.22, 0.0, TAU * 7 / 8, 7), y1 + 0.08, y1 + 0.2)


def leaf(m, p, ang, length, w, t=0.09):
	# a pointed leaf lying on a wall that faces +Y, from p along `ang` in the XZ plane
	d, s, p = Vector((math.cos(ang), 0, math.sin(ang))), Vector((-math.sin(ang), 0, math.cos(ang))), Vector(p)
	mid = p + d * length * 0.45
	i = m.add([tuple(p), tuple(p + d * length), tuple(mid + s * w), tuple(mid - s * w), tuple(mid + Vector((0, t, 0)))])
	for q in ((0, 2, 4), (2, 1, 4), (1, 3, 4), (3, 0, 4), (0, 3, 1, 2)):
		m.f.append(tuple(i + j for j in q))


def tool_store_tech():
	# era 4: a steel frame on a brick foot, glass above, a slate hip roof, a glazed lunette over the arched double door
	# The picture's proportions on the yard's footprint: the eave at 6.5, the roof's cap near 10, the door down to the
	# ground through the plinth.
	pl, br, gl, fr, ro, go, co, do = M(), M(), M(), M(), M(), M(), M(), M()
	# a plinth of stone blocks round a core, open where the door stands
	box(pl, (0, 0, 0.39), (9.8, 7.8, 0.78))
	block_run(pl, (-5.3, -3.9), (5.3, -3.9), 0, 0.8, 0.8, 6)
	# the brick foot, and brick up to the beam round the door
	box(br, (0, 0, 1.85), (9.2, 7.2, 2.1))
	box(br, (0, 3.25, 4.35), (5.5, 0.7, 2.9))
	box(gl, (0, 0, 4.35), (9.0, 7.0, 2.9))
	for sx in (-1, 1):
		block_run(pl, (sx * 4.9, -3.5), (sx * 4.9, 3.5), 0, 0.8, 0.8, 4)
		block_run(pl, (sx * 2.15, 3.9), (sx * 5.3, 3.9), 0, 0.8, 0.8, 2)
		for sy in (-1, 1):
			cbox(fr, (sx * 4.6, sy * 3.6, 3.3), (0.9, 0.9, 5.0), 0.09)
			bar(fr, (sx * 5.5, sy * 4.5, 6.6), (sx * 1.3, sy * 1.0, 10.0), 0.45, 0.3)  # the hips
			cbox(fr, (sx * 5.15, sy * 4.15, 6.78), (0.6, 0.6, 0.45), 0.06)
			ball(go, (sx * 5.15, sy * 4.15, 7.3), 0.36, 8, 5)
			stud(go, (sx * 1.25, sy * 0.95, 10.3), (0, 0, 1))
			for z in (1.4, 3.7, 5.0):
				stud(go, (sx * 4.6, sy * 4.05, z), (0, sy, 0))
				stud(go, (sx * 5.05, sy * 3.6, z), (sx, 0, 0))
		# a long side: its sill, its eave beam, its glazing bars
		cbox(fr, (sx * 4.7, 0, 2.9), (0.6, 6.3, 0.5), 0.07)
		cbox(fr, (sx * 4.65, 0, 6.15), (0.9, 8.2, 0.7), 0.09)
		for y in (-1.15, 1.15):
			box(fr, (sx * 4.52, y, 4.35), (0.2, 0.24, 2.9))
		for z in (3.85, 4.8):
			box(fr, (sx * 4.52, 0, z), (0.2, 6.3, 0.2))
		for y in (-3.0, -1.5, 0, 1.5, 3.0):
			stud(go, (sx * 5.1, y, 6.15), (sx, 0, 0))
		for y in (-2.0, 0, 2.0):
			stud(go, (sx * 5.0, y, 2.9), (sx, 0, 0))
		# the front: a window between the corner and the door's brick, its sill and post
		cbox(fr, (sx * 3.15, 3.75, 2.9), (2.0, 0.6, 0.5), 0.07)
		cbox(fr, (sx * 2.75, 3.7, 4.35), (0.3, 0.4, 2.9), 0.05)
		box(fr, (sx * 3.525, 3.52, 4.35), (0.2, 0.2, 2.9))
		for z in (3.85, 4.8):
			box(fr, (sx * 3.525, 3.52, z), (1.25, 0.2, 0.2))
		for x in (2.6, 3.6):
			stud(go, (sx * x, 4.05, 2.9), (0, 1, 0))
		for x in (0.7, 1.9, 3.7, 4.6):
			stud(go, (sx * x, 4.1, 6.15), (0, 1, 0))
		# the door's heavy frame, riveted, down to the ground
		cbox(fr, (sx * 1.875, 3.98, 1.8), (0.55, 0.76, 3.6), 0.06)
		for z in (0.7, 1.7, 2.7):
			stud(go, (sx * 1.875, 4.36, z), (0, 1, 0))
		box(do, (sx * 1.525, 4.04, 1.8), (0.15, 0.28, 3.6))
		# a leaf: a raised panel below, glazing bars above, a copper pull
		cbox(do, (sx * 0.82, 4.08, 1.12), (1.0, 0.12, 1.5), 0.05)
		box(do, (sx * 0.68, 4.09, 3.45), (0.12, 0.1, 2.2))
		cbox(co, (sx * 0.34, 4.32, 2.6), (0.18, 0.18, 1.0), 0.05)
		for z in (2.25, 2.95):
			box(co, (sx * 0.34, 4.2, z), (0.12, 0.26, 0.12))
		# a gold plate where the lunette's arch lands on the beam
		cbox(go, (sx * 2.75, 4.3, 6.15), (1.0, 0.4, 0.9), 0.06)
		stud(go, (sx * 2.75, 4.5, 6.15), (0, 1, 0), 0.22)
	for sy in (-1, 1):
		cbox(fr, (0, sy * 3.65, 6.15), (10.3, 0.9, 0.7), 0.09)
	cbox(fr, (0, -3.7, 2.9), (8.3, 0.6, 0.5), 0.07)
	for x in (-2.8, -1.4, 0, 1.4, 2.8):
		box(fr, (x, -3.52, 4.35), (0.24, 0.2, 2.9))
	for z in (3.85, 4.8):
		box(fr, (0, -3.52, z), (8.3, 0.2, 0.2))
	for x in (-4.2, -2.8, -1.4, 0, 1.4, 2.8, 4.2):
		stud(go, (x, -4.1, 6.15), (0, -1, 0))
	# the door in its arch: dark leaves, glass above the rail
	arch_band(fr, 0, 3.6, 1.6, 2.15, 3.6, 4.36)
	arch_band(do, 0, 3.6, 1.45, 1.6, 3.9, 4.18)
	arch_slab(do, 0, 0.0, 3.6, 1.5, 3.9, 4.04)
	arch_slab(gl, 0, 2.35, 3.6, 1.2, 4.0, 4.07)
	cbox(do, (0, 4.1, 2.52), (0.3, 0.2, 5.04), 0.05)
	cbox(do, (0, 4.08, 2.2), (3.0, 0.16, 0.3), 0.05)
	for z in (3.1, 3.9):
		box(do, (0, 4.09, z), (2.3, 0.1, 0.12))
	for k in range(7):
		a = math.pi * (k + 0.5) / 7
		stud(go, (1.875 * math.cos(a), 4.36, 3.6 + 1.875 * math.sin(a)), (0, 1, 0))
	# the lunette on the beam, a low arch as wide as the door's brick, its barrel roof running back into the hip roof,
	# a gear on its crown
	kz = 0.75
	# (band and glass stand at the eave's edge: anything further back has its foot hidden by the roof's slope)
	arch_band(fr, 0, 6.5, 2.5, 3.0, 3.8, 4.5, n=14, kz=kz)
	prism(gl, arc(0, 6.5, 2.52, n=14, kz=kz), 4.25, 4.38)
	box(fr, (0, 4.42, 7.42), (0.24, 0.2, 1.85))
	box(fr, (0, 4.42, 7.35), (4.4, 0.2, 0.2))
	for sx in (-1, 1):
		box(fr, (sx * 1.25, 4.42, 7.3), (0.2, 0.2, 1.6))
	for k in range(8):
		a = math.pi * (k + 0.5) / 8
		stud(go, (2.75 * math.cos(a), 4.5, 6.5 + kz * 2.75 * math.sin(a)), (0, 1, 0))
	prism(ro, arc(0, 6.5, 2.95, n=14, kz=kz), 1.9, 4.25)
	cog(go, 0, 8.8, 1.0, 4.5, 4.8)
	tile_roof(ro, 5.45, 4.45, 6.5, 1.3, 1.0, 9.9, 4, 1.8)
	# the roof's steel cap, a gold foot and ball on it
	cbox(fr, (0, 0, 10.1), (3.2, 2.6, 0.4), 0.1)
	cbox(fr, (0, 0, 10.45), (1.5, 1.5, 0.3), 0.08)
	lat(go, [(0.78, 10.6), (0.78, 10.74), (0.52, 10.86), (0.44, 11.0)], 10, 0, 0, cap_bottom=True)
	ball(go, (0, 0, 11.55), 0.64)
	# (no lantern here: the game hangs the kit's wall lantern left of the door, on the post at x 2.75, front face
	# y 3.9. The owner, 2026-11-17: the lamps we have are used, not modelled again.)
	# a thick copper pipe out of the roof's right end (-X), over and back in, a flange at every joint
	py = -1.6
	path = [(-4.95, 6.6), (-4.95, 9.3)] + arc(-4.25, 9.3, 0.7, math.pi, math.pi / 2, 5)[1:] + arc(-3.55, 9.3, 0.7, math.pi / 2, 0.0, 5) + [(-2.85, 8.2)]
	tube(co, path, py, 0.45, 10)
	for a, b in (((-4.95, 7.3), (-4.95, 7.55)), ((-4.95, 9.05), (-4.95, 9.3)), ((-4.0, 10.0), (-3.8, 10.0)),
		((-2.85, 9.05), (-2.85, 9.3)), ((-2.85, 8.7), (-2.85, 8.9))):
		tube(co, [a, b], py, 0.6, 10)
	o = (0, 0, 0)
	return [("ToolStoreTech_Plinth", pl, o, "Stone", 40), ("ToolStoreTech_Brick", br, o, "Brick", 40),
		("ToolStoreTech_Glass", gl, o, "TechGlass", 30), ("ToolStoreTech_Frame", fr, o, "Iron", 40),
		("ToolStoreTech_Roof", ro, o, "Slate", 30), ("ToolStoreTech_Gold", go, o, "Gold", 40),
		("ToolStoreTech_Copper", co, o, "Copper", 50), ("ToolStoreTech_Door", do, o, "DoorIron", 30)]


def tool_store_royal():
	# era 5: jointed marble blocks on a block plinth, columns on pedestals at the front corners, a pediment with a laurel
	# over the gold-framed arched door, one round window, a royal blue tiled hip roof with gold hips and a finial
	# As in the picture the front is not symmetric: the door and its pediment stand left of the middle (+X), the one
	# round window right of them; the columns carry the entablature a stud in front of the wall.
	ma, go, ro, gl = M(), M(), M(), M()
	dx, wx, fy = 1.3, -2.75, 0.375  # the door's middle, the window's, the middle of the entablature (it oversails the front)
	# a plinth of big blocks round a core, open where the door stands
	box(ma, (0, 0, 0.49), (9.8, 7.8, 0.98))
	block_run(ma, (-5.3, -3.9), (5.3, -3.9), 0, 1.0, 0.8, 6)
	block_run(ma, (-5.3, 3.9), (dx - 2.25, 3.9), 0, 1.0, 0.8, 3)
	block_run(ma, (dx + 2.25, 3.9), (5.3, 3.9), 0, 1.0, 0.8, 1)
	# the walls in five courses of jointed blocks, the door's bay half a stud proud
	box(ma, (0, 0, 3.5), (8.86, 6.86, 5.0))
	box(ma, (dx, 3.66, 3.5), (4.8, 0.52, 5.0))
	up = (0, 0, 5.0)
	tiles(ma, (-4.43, -3.43, 1.0), (8.86, 0, 0), up, 6, 5)
	tiles(ma, (4.43, -3.43, 1.0), (0, 6.86, 0), up, 5, 5)
	tiles(ma, (-4.43, 3.43, 1.0), (0, -6.86, 0), up, 5, 5)
	tiles(ma, (dx - 2.4, 3.43, 1.0), (-4.43 - dx + 2.4, 0, 0), up, 2, 5)
	tiles(ma, (dx + 2.4, 3.92, 1.0), (-4.8, 0, 0), up, 3, 5)
	# the entablature: an architrave with dentils, a thick gold cornice
	cbox(ma, (0, fy, 6.25), (9.6, 8.25, 0.6), 0.07)
	cbox(go, (0, fy, 6.75), (10.7, 9.35, 0.4), 0.08)
	for k in range(13):
		box(ma, (-4.5 + 0.75 * k, fy + 4.24, 6.42), (0.3, 0.24, 0.26))
	for sx in (-1, 1):
		block_run(ma, (sx * 4.9, -3.5), (sx * 4.9, 3.5), 0, 1.0, 0.8, 4)
		for k in range(11):
			box(ma, (sx * 4.92, fy - 3.75 + 0.75 * k, 6.42), (0.24, 0.3, 0.26))
		# a stout column on a square pedestal, gold foot and capital
		x, y = sx * 4.35, 3.75
		cbox(ma, (x, y, 0.85), (1.5, 1.5, 1.7), 0.1)
		lat(ma, [(0.55, 2.0), (0.5, 5.3)], 12, x, y)
		lat(go, [(0.8, 1.7), (0.8, 1.86), (0.66, 1.96), (0.72, 2.08), (0.58, 2.2)], 12, x, y, cap_bottom=True, cap_top=True)
		lat(go, [(0.5, 5.2), (0.56, 5.34), (0.7, 5.5), (0.82, 5.7)], 12, x, y, cap_bottom=True, cap_top=True)
		cbox(go, (x, y, 5.825), (1.7, 1.7, 0.25), 0.06)
		cbox(ma, (sx * 4.2, -3.2, 3.48), (1.0, 1.0, 4.95), 0.08)  # a square pilaster on each back corner
		# the door: marble posts, a gold jamb, a pull
		cbox(ma, (dx + sx * 2.025, 4.1, 1.8), (0.45, 0.5, 3.6), 0.05)
		cbox(go, (dx + sx * 1.65, 4.165, 1.8), (0.3, 0.43, 3.6), 0.04)
		cbox(go, (dx + sx * 0.3, 4.36, 2.4), (0.13, 0.13, 0.8), 0.03)
		for z in (2.15, 2.65):
			box(go, (dx + sx * 0.3, 4.26, z), (0.09, 0.22, 0.09))
		# the pediment's raking cornice in gold, a laurel branch on the tympanum (its leaves shorter toward the corner)
		# (the pediment stands at the cornice's edge, in front of the roof's eave: further back the slope hides its foot)
		bar(go, (dx + sx * 3.5, 5.1, 7.05), (dx, 5.1, 9.35), 0.8, 0.4)
		for k in range(3):
			p = (dx + sx * (0.55 + 0.45 * k), 5.1, 7.34)
			for a in (40 - 10 * k, -15 + 5 * k):
				a = math.radians(a)
				leaf(go, p, a if sx > 0 else math.pi - a, 0.85 - 0.1 * k, 0.3, 0.16)
		# the roof's gold hips
		for sy in (-1, 1):
			bar(go, (sx * 5.05, fy + sy * 4.35, 7.05), (sx * 1.1, fy + sy * 0.9, 10.45), 0.5, 0.3)
	# the pilaster that closes the door's bay, on its own pedestal, a gold plate for a capital
	cbox(ma, (dx - 2.4, 3.9, 0.5), (0.9, 0.9, 1.0), 0.08)
	cbox(ma, (dx - 2.4, 3.8, 3.4), (0.7, 0.7, 4.8), 0.07)
	cbox(go, (dx - 2.4, 3.84, 5.7), (0.86, 0.8, 0.5), 0.06)
	# the door in its arch: a marble surround, a gold frame and keystone, blue glass
	arch_band(ma, dx, 3.6, 1.8, 2.25, 3.9, 4.3)
	arch_band(go, dx, 3.6, 1.5, 1.8, 3.95, 4.38)
	cbox(go, (dx, 4.25, 5.75), (0.6, 0.5, 0.9), 0.07)
	arch_slab(gl, dx, 0.0, 3.6, 1.5, 4.0, 4.1)
	cbox(go, (dx, 4.16, 2.55), (0.26, 0.2, 5.1), 0.04)
	box(go, (dx, 4.14, 0.12), (3.0, 0.16, 0.24))
	for z in (1.6, 3.2):
		box(go, (dx, 4.14, z), (3.0, 0.14, 0.14))
	# the round window
	arch_band(go, wx, 4.0, 0.7, 0.95, 3.45, 3.8, 0.0, TAU, 16)
	prism(gl, arc(wx, 4.0, 0.72, 0.0, TAU * 15 / 16, 15), 3.5, 3.6)
	box(go, (wx, 3.66, 4.0), (0.12, 0.14, 1.42))
	box(go, (wx, 3.66, 4.0), (1.42, 0.14, 0.12))
	# the pediment over the door's bay, a gable roof behind it with a gold ridge
	# (the hip roof stops inside the gold cornice, which is its edge as in the picture)
	prism(ma, [(dx - 3.0, 6.95), (dx + 3.0, 6.95), (dx, 8.95)], 4.8, 5.05)
	prism(ro, [(dx - 3.4, 6.95), (dx + 3.4, 6.95), (dx, 9.2)], 2.3, 4.8)
	bar(go, (dx, 2.2, 9.25), (dx, 4.9, 9.25), 0.3, 0.2)
	cbox(go, (dx, 5.1, 9.42), (0.55, 1.0, 0.4), 0.05)
	ball(go, (dx, 5.08, 7.42), 0.4, 10, 4)
	tile_roof(ro, 5.0, 4.3, 6.95, 1.1, 0.9, 10.35, 4, 1.8, fy)
	# a stepped gold foot and a tall finial
	cbox(go, (0, fy, 10.5), (2.6, 2.2, 0.36), 0.08)
	lat(go, [(0.95, 10.68), (0.8, 10.98)], 6, 0, fy, cap_top=True)
	lat(go, [(0.32, 10.98), (0.5, 11.15), (0.6, 11.4), (0.5, 11.65), (0.24, 11.8), (0.3, 11.9), (0.0, 12.5)], 10, 0, fy)
	o = (0, 0, 0)
	return [("ToolStoreRoyal_Marble", ma, o, "Marble", 40), ("ToolStoreRoyal_Gold", go, o, "Gold", 40),
		("ToolStoreRoyal_Roof", ro, o, "Royal", 30), ("ToolStoreRoyal_Glass", gl, o, "Sky", 30)]


PIECES = [("ConeRoof", cone_roof), ("GlassDome", glass_dome), ("RoyalDome", royal_dome), ("Column", column),
	("Balustrade", balustrade), ("Pipe", pipe), ("Gear", gear), ("ChimneyCrown", chimney_crown), ("VentHood", vent_hood),
	("WindWheel", wind_wheel), ("IrrigationArch", irrigation_arch), ("EggDome", egg_dome), ("HeartEmblem", heart_emblem),
	("ShieldEmblem", shield_emblem), ("FishEmblem", fish_emblem), ("ToolStoreTech", tool_store_tech),
	("ToolStoreRoyal", tool_store_royal)]
# PIECES_ONLY=Name,Name builds only those (the others' files and their rows in pieces.json stay)
ONLY = os.environ.get("PIECES_ONLY")
if ONLY:
	PIECES = [p for p in PIECES if p[0] in ONLY.split(",")]
# the buildings are judged from their door's side
FRONT = {"ToolStoreTech": (-0.4, 1.25, 0.4), "ToolStoreRoyal": (-0.4, 1.25, 0.4)}


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


def render(objs, path, view=None):
	sc = bpy.context.scene
	bpy.context.view_layer.update()
	lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
	for ob in objs:
		for v in ob.data.vertices:
			w = ob.matrix_world @ v.co
			lo = Vector(map(min, lo, w))
			hi = Vector(map(max, hi, w))
	ctr, size = (lo + hi) / 2, (hi - lo)
	d = Vector(view or (1.0, -1.25, 0.85)).normalized()
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
if ONLY and os.path.exists(OUT + "pieces.json"):
	with open(OUT + "pieces.json") as fh:
		report = json.load(fh)
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
	render(objs, OUT + pname + ".png", FRONT.get(pname))
	export(objs, OUT + pname + ".fbx")
	if PREVIEW:
		os.makedirs(PREVIEW, exist_ok=True)
		preview(objs, os.path.join(PREVIEW, pname + ".luau"))
with open(OUT + "pieces.json", "w") as fh:
	json.dump(report, fh, indent=1)
for k, v in report.items():
	if ONLY and k not in ONLY.split(","):
		continue
	print("[granary_pieces]", k, v["triangles"], {n: (o["triangles"], o["size_studs_xyz"], o["signed_volume"]) for n, o in v["objects"].items()})
