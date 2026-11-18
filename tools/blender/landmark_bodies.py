# The village landmarks' BODIES, whole, from Blender (the owner, 2026-11-17: "dựng lại tất cả các công trình bằng
# blender", "cánh cửa chính mở nhé, và có thể đi vào bên trong nhà"): each era of a building is one set of meshes, one
# object a MATERIAL (the game paints the era's colour and a real material), hollow, its great door standing open. The
# sizes are the landmark module's own (LOOKS in src/server/Granary.luau ...), so the module's part shell, kept unseen
# as the collision, and everything a level switches on still fit. Measured from ChatGPT's four-side sheets
# (docs/areas/village-v2/views/). Run headless:
#   & "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P "C:\Roblox 3rd game\tools\blender\landmark_bodies.py"
# It writes art/models/granary/blender/<Body>.fbx (the folder tools/kit/upload_village_pieces.js uploads), <Body>.png and
# four elevations <Body>_front / _left / _back / _right.png to hold beside the sheet.
#
# Axes: the module's (x, y up, z from the front wall to the back; +x is the left as one walks in) become Blender's
# (x, -z, y): the front faces +Y, the origin is the middle of the front wall's foot.
import json
import math
import os
import random
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender")
import granary_pieces as G  # noqa: E402
from granary_pieces import M  # noqa: E402

G.COL.update({"Plaster": (0.93, 0.86, 0.71), "Timber": (0.43, 0.28, 0.16), "Thatch": (0.91, 0.75, 0.33),
	"Planks": (0.59, 0.38, 0.21), "Pane": (1.0, 0.84, 0.47)})

BASE, FLOOR, T = 1.2, 0.4, 0.6  # the stone foot, the yard's paving, a wall's thickness: as in the modules
SLOTS = ("Stone", "Plaster", "Timber", "Thatch", "Planks", "Iron", "Pane")


def new():
	return {k: M() for k in SLOTS}


class Face:
	# A wall seen from outside, in the axes the helpers of granary_pieces draw in: local x along the wall (to the
	# viewer's LEFT), y out of the wall, z up. `ang` turns it round the up axis, (ox, oy) is where its origin stands.
	def __init__(s, ang, ox, oy):
		s.c, s.s, s.ox, s.oy = math.cos(ang), math.sin(ang), ox, oy

	def put(s, out, t):
		done = set()  # (two slots of one colour share a mesh: see `granary`)
		for k, src in t.items():
			if id(src) in done:
				continue
			done.add(id(src))
			m = out[k]
			i = len(m.v)
			m.v.extend((s.ox + x * s.c - y * s.s, s.oy + x * s.s + y * s.c, z) for x, y, z in src.v)
			m.f.extend(tuple(i + j for j in f) for f in src.f)


def lbox(m, u0, u1, v0, v1, n0, n1, ch=0.0):
	# a box in a face's axes: u along the wall, v up, n out of it
	c, s = ((u0 + u1) / 2, (n0 + n1) / 2, (v0 + v1) / 2), (abs(u1 - u0), abs(n1 - n0), abs(v1 - v0))
	if ch:
		G.cbox(m, c, s, ch)
	else:
		G.box(m, c, s)


def mbox(m, x0, x1, y0, y1, z0, z1, ch=0.0):
	# a box in the module's axes
	lbox(m, x0, x1, y0, y1, -z1, -z0, ch)


def mbar(m, p, q, w, t):
	G.bar(m, (p[0], -p[2], p[1]), (q[0], -q[2], q[1]), w, t)


def seg(w, spring, rise, n=8):
	# the points of a low arch over an opening `w` wide, from its +u end to its -u end
	r = (w * w / 4 + rise * rise) / (2 * rise)
	a = math.asin(w / 2 / r)
	return [(r * math.sin(a - 2 * a * k / n), spring + rise - r + r * math.cos(a - 2 * a * k / n)) for k in range(n + 1)]


def wall(m, u0, u1, v0, v1, holes=(), n0=-T, n1=0.0):
	# a wall from corner to corner, less its holes (u0, u1, v0, v1), as boxes
	us = sorted({u0, u1} | {x for h in holes for x in h[:2] if u0 < x < u1})
	for a, b in zip(us, us[1:]):
		mid, v = (a + b) / 2, v0
		for h in sorted((h for h in holes if h[0] < mid < h[1]), key=lambda h: h[2]):
			if h[2] > v + 1e-3:
				lbox(m, a, b, v, h[2], n0, n1)
			v = max(v, h[3])
		if v < v1 - 1e-3:
			lbox(m, a, b, v, v1, n0, n1)


def courses(m, u0, u1, v0, v1, n0, n1, rows, length=2.0, ch=0.09):
	# courses of chamfered blocks, every other one half a block on: the joints are real grooves
	h = (v1 - v0) / rows
	n = max(1, round((u1 - u0) / length))
	step = (u1 - u0) / n
	for r in range(rows):
		cuts = [u0 + step * k for k in range(n + 1)]
		if r % 2:
			cuts = [u0] + [u0 + step * (k + 0.5) for k in range(n)] + [u1]
		for a, b in zip(cuts, cuts[1:]):
			lbox(m, a, b, v0 + r * h, v0 + (r + 1) * h, n0, n1, ch)


def window(t, uc, vc, w, h, rise=0.32, fw=0.24, frame="Timber", pane="Pane"):
	# An arched window of four panes in a timber frame that goes through the wall, a pane on each face. The wall is
	# not cut: the game's own wall (the collision) stands inside the model's and would show in the hole.
	v0, top = vc - h / 2, vc + h / 2
	spring = top - rise
	arcp = [(uc + x, z) for x, z in seg(w, spring, rise)]
	fr = t[frame]
	for n0, n1 in ((0.0, 0.06), (-T - 0.06, -T)):
		G.prism(t[pane], [(uc - w / 2, v0), (uc + w / 2, v0)] + arcp, n0, n1)
		lbox(fr, uc - 0.07, uc + 0.07, v0, top - 0.02, n0 - 0.04, n1 + 0.04)
		lbox(fr, uc - w / 2, uc + w / 2, vc - 0.07, vc + 0.07, n0 - 0.04, n1 + 0.04)
	for s in (-1, 1):
		lbox(fr, uc + s * w / 2, uc + s * (w / 2 + fw), v0, spring, -T - 0.14, 0.2, 0.04)
	lbox(fr, uc - w / 2 - 0.42, uc + w / 2 + 0.42, v0 - 0.26, v0, -T - 0.2, 0.42, 0.05)
	G.prism(fr, [(uc - w / 2 - fw, top + fw), (uc - w / 2 - fw, spring)] + arcp[::-1] + [(uc + w / 2 + fw, spring),
		(uc + w / 2 + fw, top + fw)], -T - 0.14, 0.2)


def hatch(t, uc, vc, w, h):
	# a loft hatch: louvres in a timber frame, proud of the wall
	fr, pl = t["Timber"], t["Planks"]
	for s in (-1, 1):
		lbox(fr, uc + s * w / 2, uc + s * (w / 2 + 0.26), vc - h / 2, vc + h / 2, 0, 0.3, 0.05)
	lbox(fr, uc - w / 2 - 0.36, uc + w / 2 + 0.36, vc + h / 2, vc + h / 2 + 0.28, 0, 0.34, 0.05)
	lbox(fr, uc - w / 2 - 0.36, uc + w / 2 + 0.36, vc - h / 2 - 0.28, vc - h / 2, 0, 0.38, 0.05)
	lbox(pl, uc - w / 2, uc + w / 2, vc - h / 2, vc + h / 2, 0, 0.08)
	n = round(h / 0.34)
	for k in range(n):
		v = vc - h / 2 + (k + 0.5) * h / n
		sec = ((0.08, v + 0.13), (0.26, v - 0.02), (0.26, v - 0.09), (0.08, v + 0.06))
		G.sweep(pl, [[(u, nn, vv) for nn, vv in sec] for u in (uc - w / 2, uc + w / 2)])


def ring(m, c, r0=0.26, r=0.055):
	# a ring handle lying on a face, its middle at c
	rng = G.lathe(m, [(r0 + r * math.cos(G.TAU * k / 6), r * math.sin(G.TAU * k / 6)) for k in range(6)], 10, loop=True)
	G.xform(m, rng, lambda q: (c[0] + q[0], c[1] + q[2], c[2] + q[1]))


def roll(m, p, q, r, sides=8):
	# a round roll from p to q (Blender points)
	p, q = G.Vector(p), G.Vector(q)
	d = (q - p).normalized()
	u = d.cross(G.Vector((0, 0, 1)) if abs(d.z) < 0.95 else G.Vector((1, 0, 0))).normalized()
	v = u.cross(d)
	G.sweep(m, [[tuple(c + r * (math.cos(G.TAU * i / sides) * u + math.sin(G.TAU * i / sides) * v)) for i in range(sides)]
		for c in (p, q)])


def thatch(m, eave, top, z0, z1, rows, thick=0.8, lip=0.42):
	# One slope of thatch from `eave` up to `top` ((x, y) in the module's axes), z0..z1 along the ridge: a slab under
	# `rows` courses, each standing `lip` proud over the one below, its foot ragged (every other point hangs lower).
	(ex, ey), (tx, ty) = eave, top
	run = math.hypot(tx - ex, ty - ey)
	dx, dy = (tx - ex) / run, (ty - ey) / run
	nx, ny = (-dy, dx) if dx > 0 else (dy, -dx)  # the slope's normal, the one that points up

	def at(a, nn, z):
		return (ex + dx * a + nx * nn, -z, ey + dy * a + ny * nn)

	G.sweep(m, [[at(0, -thick, z), at(0, 0, z), at(run, 0, z), at(run, -thick, z)] for z in (z0, z1)])
	nz = max(2, round((z1 - z0 + 0.3) / 0.5))
	rnd = random.Random(7)
	for k in range(rows):
		a0 = run * k / rows - (0.28 if k == 0 else 0.55)
		a1 = run * (k + 1) / rows + 0.05
		foot = -thick if k == 0 else -0.05  # (the eave's course is as thick as the roof)
		secs = []
		for j in range(nz + 1):
			z = z0 - 0.15 + (z1 - z0 + 0.3) * j / nz
			# the foot is one unbroken fringe that leans out over the course below: tufts of uneven length
			jag = (0.5 if j % 2 else 0.12) + 0.14 * rnd.random()
			hi = lip * (0.85 + 0.3 * rnd.random())
			secs.append([at(a0 + 0.1, foot, z), at(a0 - jag, hi, z), at(a1, 0.03, z), at(a1, -0.05, z)])
		G.sweep(m, secs)


def gable_frame(t, half, wall_h, rise, hatch_y):
	# what the front and the back gable share: the tie beam, king post, struts, rafters under the thatch, a collar and
	# the loft hatch on it
	fr, ridge = t["Timber"], wall_h + rise
	lbox(fr, -half - 0.18, half + 0.18, wall_h - 0.25, wall_h + 0.25, -0.1, 0.26, 0.07)
	lbox(fr, -0.21, 0.21, wall_h + 0.25, ridge - 1.3, -0.1, 0.18, 0.05)
	for s in (-1, 1):
		G.bar(fr, (s * half * 0.62, 0.04, wall_h + 0.2), (0, 0.04, wall_h + rise * 0.55), 0.3, 0.36)
		G.bar(fr, (s * (half - 1.3), 0.06, wall_h + 0.15), (0, 0.06, ridge - 1.15), 0.34, 0.4)
	lbox(fr, -half * 0.39, half * 0.39, hatch_y - 1.25, hatch_y - 0.9, -0.1, 0.2, 0.05)
	hatch(t, 0, hatch_y, 1.6, 1.8)


# ---------------------------------------------------------------- the Granary


def granary1():
	# era 1 (LOOKS[1] of Granary.luau): thatch and cream plaster on brown beams, a clock tower on tie beams over the
	# hall, an open lean-to along the right wall. The tower's straw cap, the silos, lanterns and the clock stay the
	# game's own pieces.
	hw, d, wall_h, rise, over = 8.5, 12.0, 9.0, 7.5, 1.5
	dw, door_top = 7.6, BASE + 6.6
	pitch, ridge = rise / hw, wall_h + rise
	out = new()
	front, back = Face(0, 0, 0), Face(math.pi, 0, -d)
	left, right = Face(-math.pi / 2, hw, -d / 2), Face(math.pi / 2, -hw, -d / 2)
	stone, timber, planks, iron = out["Stone"], out["Timber"], out["Planks"], out["Iron"]

	# the stone foot: two courses of blocks round a core whose top is the hall's floor
	mbox(stone, -hw - 0.2, hw + 0.2, 0, BASE - 0.02, -0.2, d + 0.2)
	for face in (front, back):
		t = new()
		courses(t["Stone"], -hw - 0.3, hw + 0.3, 0, BASE, -0.35, 0.3, 2)
		face.put(out, t)
	for face in (left, right):
		t = new()
		courses(t["Stone"], -d / 2 + 0.35, d / 2 - 0.35, 0, BASE, -0.35, 0.3, 2)
		face.put(out, t)

	# the dock before the door (the leaves swing out over it) and its step
	leaf_w = dw / 2 - 0.06
	dock_d, dock_hw = leaf_w + 0.6, dw / 2 + 1.5
	mbox(stone, -dock_hw + 0.12, dock_hw - 0.12, 0, BASE - 0.1, -dock_d + 0.12, 0)
	t = new()
	courses(t["Stone"], -dock_hw, dock_hw, 0, BASE - 0.14, -0.4, 0, 2, 2.2)
	Face(0, 0, dock_d).put(out, t)
	for ang, x in ((-math.pi / 2, dock_hw), (math.pi / 2, -dock_hw)):
		t = new()
		courses(t["Stone"], -dock_d / 2 + 0.4, dock_d / 2 - 0.4, 0, BASE - 0.14, -0.4, 0, 2, 1.8)
		Face(ang, x, dock_d / 2).put(out, t)
	for i in range(4):
		for j in range(2):
			mbox(stone, -dock_hw + i * dock_hw / 2, -dock_hw + (i + 1) * dock_hw / 2, BASE - 0.14, BASE,
				-dock_d + j * dock_d / 2, -dock_d + (j + 1) * dock_d / 2, 0.05)
	for i in range(3):
		mbox(stone, -4.8 + i * 3.2, -1.6 + i * 3.2, 0, 0.8, -dock_d - 1.2, -dock_d, 0.08)

	# THE FRONT: plaster round the great door, two small windows, the door's frame with a low arched head
	t = new()
	fr = t["Timber"]
	for s in (-1, 1):
		window(t, s * 6.85, 4.6, 1.5, 1.9)
	wall(t["Plaster"], -hw, hw, BASE, wall_h, [(-dw / 2, dw / 2, BASE, door_top)])
	G.prism(t["Plaster"], [(-hw + 1.05, wall_h), (hw - 1.05, wall_h), (0, ridge - 0.9)], -T, 0)
	for s in (-1, 1):
		lbox(fr, s * (dw / 2 + 0.55), s * (hw - 0.3), BASE, BASE + 0.42, -0.1, 0.18, 0.05)
		lbox(fr, s * 4.65, s * (hw - 0.3), door_top, door_top + 0.45, -0.1, 0.18, 0.05)
		lbox(fr, s * 6.64, s * 7.06, door_top + 0.45, wall_h - 0.25, -0.1, 0.18, 0.05)
		lbox(fr, s * dw / 2, s * (dw / 2 + 0.55), BASE, door_top, -T - 0.1, 0.4, 0.06)
	lbox(fr, -4.65, 4.65, door_top, door_top + 0.6, -T - 0.1, 0.42, 0.07)
	arch_rise, arch_spring = 0.75, door_top - 1.2
	G.prism(fr, [(-dw / 2, door_top)] + seg(dw, arch_spring, arch_rise, 10)[::-1] + [(dw / 2, door_top)], -0.28, 0.3)
	gable_frame(t, hw, wall_h, rise, wall_h + rise * 0.36)
	front.put(out, t)

	# the leaves, swung open past square onto the dock: planks under the arch's line, iron straps, a cross brace
	r = (dw * dw / 4 + arch_rise * arch_rise) / (2 * arch_rise)
	cy = arch_spring + arch_rise - r
	leaf_h = arch_spring - BASE
	for s in (-1, 1):
		t = new()
		for k in range(5):
			x0, x1 = leaf_w * k / 5 + 0.015, leaf_w * (k + 1) / 5 - 0.015
			tops = [cy + math.sqrt(r * r - (dw / 2 - x) ** 2) - 0.06 for x in (x0, x1)]
			G.prism(t["Planks"], [(x0, BASE + 0.04), (x1, BASE + 0.04), (x1, tops[1]), (x0, tops[0])], -0.13, 0.13)
		lo, hi = BASE + leaf_h * 0.22, BASE + leaf_h * 0.78
		for v in (lo, hi):
			lbox(t["Iron"], 0.05, leaf_w - 0.2, v - 0.12, v + 0.12, -0.2, 0.2, 0.03)
		G.bar(t["Timber"], (0.25, 0, lo + 0.2), (leaf_w - 0.3, 0, hi - 0.2), 0.4, 0.3)
		G.bar(t["Timber"], (0.25, 0, hi - 0.2), (leaf_w - 0.3, 0, lo + 0.2), 0.4, 0.3)
		for n in (-0.2, 0.2):
			ring(t["Iron"], (leaf_w - 0.55, n, BASE + 2.9))
		Face(math.radians(90 - s * 10), s * dw / 2, 0.2).put(out, t)

	# THE LEFT WALL: three arched windows between the posts
	for face, windows in ((left, True), (right, False)):
		t = new()
		fr = t["Timber"]
		for u in (-4, 0, 4) if windows else ():
			window(t, u, 4.6, 1.6, 2.0)
		wall(t["Plaster"], -d / 2 + T, d / 2 - T, BASE, wall_h)
		lbox(fr, -d / 2 + 0.3, d / 2 - 0.3, BASE, BASE + 0.42, -0.1, 0.18, 0.05)
		lbox(fr, -d / 2 + 0.3, d / 2 - 0.3, 7.3, 7.75, -0.1, 0.18, 0.05)
		for u in (-2, 2):
			lbox(fr, u - 0.21, u + 0.21, BASE + 0.42, 7.3, -0.1, 0.18, 0.05)
		face.put(out, t)

	# THE BACK: a small plank door on two stone steps, a window either side, the gable as the front's
	t = new()
	fr = t["Timber"]
	door_h = 3.7
	for s in (-1, 1):
		window(t, s * 5.5, 4.6, 1.5, 1.9)
	wall(t["Plaster"], -hw, hw, BASE, wall_h)
	G.prism(t["Plaster"], [(-hw + 1.05, wall_h), (hw - 1.05, wall_h), (0, ridge - 0.9)], -T, 0)
	for s in (-1, 1):
		lbox(fr, s * 1.25, s * (hw - 0.3), BASE, BASE + 0.42, -0.1, 0.18, 0.05)
		lbox(fr, s * 2.69, s * 3.11, BASE + 0.42, wall_h - 0.25, -0.1, 0.18, 0.05)
		lbox(fr, s * 0.95, s * 1.25, BASE, BASE + door_h, 0, 0.26, 0.05)
	lbox(fr, -1.45, 1.45, BASE + door_h, BASE + door_h + 0.35, 0, 0.3, 0.05)
	# (the back door is shut and lies on the wall, which is not cut: see `window`)
	for k in range(4):
		lbox(t["Planks"], -0.95 + k * 0.475 + 0.012, -0.475 + k * 0.475 - 0.012, BASE + 0.03, BASE + door_h, 0, 0.1)
	for v in (BASE + 0.7, BASE + door_h - 0.7):
		lbox(t["Iron"], -0.9, 0.55, v - 0.1, v + 0.1, 0.08, 0.15, 0.02)
	G.bar(fr, (-0.8, 0.14, BASE + 0.95), (0.8, 0.14, BASE + door_h - 0.95), 0.1, 0.22)
	ring(t["Iron"], (0.62, 0.17, BASE + door_h / 2), 0.2, 0.045)
	lbox(t["Stone"], -1.7, 1.7, 0, 0.8, 0.3, 1.5, 0.08)
	lbox(t["Stone"], -1.4, 1.4, 0.8, BASE - 0.06, 0.3, 0.95, 0.07)
	gable_frame(t, hw, wall_h, rise, wall_h + rise * 0.36)
	back.put(out, t)

	# the corner posts
	for sx in (-1, 1):
		mbox(timber, sx * (hw - 0.3), sx * (hw + 0.18), BASE, wall_h - 0.3, -0.18, 0.3, 0.06)
		mbox(timber, sx * (hw - 0.3), sx * (hw + 0.18), BASE, wall_h - 0.3, d - 0.3, d + 0.18, 0.06)

	# THE ROOF: five courses of thatch a slope, a roll along the ridge and down each verge, barge boards under them
	th = out["Thatch"]
	eave_x = hw + over
	eave_y = ridge - pitch * eave_x
	for s in (-1, 1):
		thatch(th, (s * eave_x, eave_y), (0, ridge), -over, d + over, 5)
		for z in (-over, d + over):
			roll(th, (s * (eave_x + 0.15), -z, eave_y - 0.1), (0, -z, ridge - 0.1), 0.5)
		for z in (-over + 0.4, d + over - 0.4):
			mbar(timber, (s * (eave_x - 0.4), ridge - 1.32 - pitch * (eave_x - 0.4), z), (0, ridge - 1.32, z), 0.24, 0.5)
	roll(th, (0, over + 0.25, ridge + 0.12), (0, -d - over - 0.25, ridge + 0.12), 0.55)
	G.ball(th, (0, over + 0.3, ridge + 0.25), 0.66, 8, 5)

	# THE CLOCK TOWER: on tie beams across the hall, its legs through the roof; the cap, the clock and the flag are
	# the game's
	tw, zt = 5.5, d * 0.55
	dial = tw * 0.34
	clock_y = ridge + 0.6 + dial
	shaft_top, foot = clock_y + dial + 1, ridge - pitch * tw / 2 - 0.8
	mbox(out["Plaster"], -tw / 2, tw / 2, foot, shaft_top, zt - tw / 2, zt + tw / 2)
	for sx in (-1, 1):
		for sz in (-1, 1):
			mbox(timber, sx * (tw / 2 - 0.42), sx * (tw / 2 + 0.08), foot, shaft_top, zt + sz * (tw / 2 - 0.42),
				zt + sz * (tw / 2 + 0.08), 0.06)
			mbox(timber, sx * (tw / 2 - 0.6), sx * tw / 2, wall_h - 0.6, foot + 0.3, zt + sz * (tw / 2 - 0.6), zt + sz * tw / 2,
				0.05)
	for sz in (-1, 1):
		z = zt + sz * (tw / 2 - 0.3)
		mbox(timber, -hw + T - 0.05, hw - T + 0.05, wall_h - 1.2, wall_h - 0.6, z - 0.3, z + 0.3, 0.06)
	string_y = clock_y - dial - 0.65
	mbox(timber, -tw / 2 - 0.25, tw / 2 + 0.25, string_y - 0.18, string_y + 0.18, zt - tw / 2 - 0.25, zt + tw / 2 + 0.25, 0.06)
	mbox(timber, -tw / 2 - 0.5, tw / 2 + 0.5, shaft_top, shaft_top + 0.5, zt - tw / 2 - 0.5, zt + tw / 2 + 0.5, 0.1)
	mbox(timber, -tw / 2 - 0.85, tw / 2 + 0.85, shaft_top + 0.5, shaft_top + 0.8, zt - tw / 2 - 0.85, zt + tw / 2 + 0.85, 0.08)

	# THE LEAN-TO along the right wall: thatch carried on from the eave at a flatter pitch, on three posts
	z0, z1, lean_out = 1.6, 10.2, 6.2
	slope = 1.6 / lean_out
	tuck = over - 0.4
	lean_hi = ridge - pitch * (hw + tuck) - 0.1 + slope * tuck
	run = lean_out + 0.6
	thatch(th, (-hw - run, lean_hi - slope * run + 0.3), (-hw - 0.9, lean_hi - slope * 0.9 + 0.3), z0 - 0.5, z1 + 0.5, 2, 0.6,
		0.36)
	px, beam_y = -(hw + lean_out - 0.3), lean_hi - slope * (lean_out - 0.3) - 0.4
	mbox(timber, -hw - 0.3, -hw, lean_hi - 0.5, lean_hi - 0.1, z0 - 0.3, z1 + 0.3, 0.05)
	mbox(timber, px - 0.2, px + 0.2, beam_y - 0.2, beam_y + 0.2, z0 - 0.3, z1 + 0.3, 0.05)
	zc = (z0 + z1) / 2
	for y in (FLOOR + 1.3, FLOOR + 2.3):  # the low rails along its open side (the ends stay open)
		mbox(timber, px - 0.1, px + 0.1, y - 0.16, y + 0.16, z0 + 0.3, z1 - 0.3, 0.04)
	for z in (z0 + 0.3, zc, z1 - 0.3):
		mbox(stone, px - 0.5, px + 0.5, FLOOR - 0.4, FLOOR + 0.3, z - 0.5, z + 0.5, 0.08)
		mbox(timber, px - 0.25, px + 0.25, FLOOR + 0.3, beam_y - 0.2, z - 0.25, z + 0.25, 0.07)
		mbar(timber, (px, beam_y - 1.5, z), (px + 1.3, beam_y + 0.1, z), 0.3, 0.3)
		for dz in ((-1.3, 1.3) if z == zc else (1.3,) if z < zc else (-1.3,)):
			mbar(timber, (px, beam_y - 1.5, z), (px, beam_y - 0.1, z + dz), 0.3, 0.3)
		mbar(timber, (px - 0.5, beam_y + 0.2 + slope * 0.5, z), (-hw, lean_hi - 0.45, z), 0.3, 0.3)

	return [("GranaryBody1_" + k, out[k], (0, 0, 0), k, 35) for k in SLOTS if out[k].v]


# ---------------------------------------------------------------- the Granary's eras 2 to 5, one builder
#
# Eras 2-5 share one plan (a hall with a great arched door, a wing on the left, a lean-to on the right, a clock tower
# over the ridge), so one function builds them from a copy of the module's LOOKS. A slot is a colour FIELD of the
# module's Look (wall, lower, beam ...): the game paints `GranaryBody<era>_<Slot>` with that field's colour, which
# also gives it the era's material. Two fields of one colour at an era share one mesh, under the first one's name.

FIELDS = ("Stone", "Wall", "Lower", "Beam", "Board", "Surround", "Frame", "Roof", "Door", "Band", "Glass", "TowerWall",
	"TowerCap", "Gold")
SQ2 = math.sqrt(2)


def rgb(r, g, b):
	return (round(r / 255, 4), round(g / 255, 4), round(b / 255, 4))


IRON = rgb(58, 60, 68)
LOOK = {
	2: dict(hw=10, d=14, wall_h=9.4, rise=9.5, over=1.2, dw=8.6, dh=7.2, lower_h=None, jet=0.0, glass=False,
		floors=(BASE, 5.3, 9.4), rows=((4, 1.5, 1.9, 0), (7.6, 1.3, 1.5, 0)), timber=True, wing=(8, 9, 6, 3.6), tower=6.5,
		spire=6.5, cap="pyramid"),
	3: dict(hw=11, d=16, wall_h=11.8, rise=10, over=1.2, dw=9.6, dh=8.2, lower_h=9.6, jet=0.3, glass=False,
		floors=(9.6, 11.8), rows=((4.4, 1.5, 2, 1), (10.75, 1.3, 1.4, 0)), timber=True, wing=(8.5, 9.6, 7, 4), tower=7.5,
		spire=7.5, cap="pyramid"),
	4: dict(hw=11.5, d=17, wall_h=12, rise=9, over=1, dw=10, dh=8.4, lower_h=5.8, jet=0.0, glass=True,
		floors=(5.8, 8.9, 12), rows=((3.6, 1.6, 2, 0),), timber=True, wing=(8.5, 10, 7, 3.4), tower=8, spire=0, cap="glass"),
	5: dict(hw=12, d=18, wall_h=12.8, rise=6.5, over=1, dw=10, dh=8.6, lower_h=None, jet=0.0, glass=False, floors=(),
		rows=((4.6, 1.6, 2.4, 1), (11.15, 1.5, 1.5, 0)), timber=False, wing=(9, 10, 7.6, 2.6), tower=8.5, spire=0, cap="dome"),
}
PAINT = {
	2: dict(Stone=rgb(156, 152, 146), Wall=rgb(244, 238, 224), Lower=rgb(244, 238, 224), Beam=rgb(40, 128, 130),
		Board=rgb(32, 104, 108), Surround=rgb(40, 128, 130), Frame=rgb(255, 255, 255), Roof=rgb(198, 70, 58),
		Door=rgb(146, 96, 56), Band=IRON, Glass=rgb(255, 222, 140), TowerWall=rgb(244, 238, 224), TowerCap=rgb(52, 150, 150),
		Gold=rgb(236, 190, 70)),
	3: dict(Stone=rgb(128, 124, 118), Wall=rgb(240, 230, 206), Lower=rgb(170, 166, 158), Beam=rgb(112, 72, 44),
		Board=rgb(112, 72, 44), Surround=rgb(206, 200, 188), Frame=rgb(112, 72, 44), Roof=rgb(190, 62, 50),
		Door=rgb(104, 66, 44), Band=IRON, Glass=rgb(255, 222, 140), TowerWall=rgb(176, 172, 166), TowerCap=rgb(190, 62, 50),
		Gold=rgb(236, 190, 70)),
	4: dict(Stone=rgb(74, 80, 92), Wall=rgb(150, 225, 235), Lower=rgb(198, 112, 74), Beam=rgb(58, 72, 96),
		Board=rgb(58, 72, 96), Surround=rgb(58, 72, 96), Frame=rgb(58, 72, 96), Roof=rgb(62, 96, 160), Door=rgb(150, 94, 54),
		Band=rgb(58, 72, 96), Glass=rgb(120, 230, 235), TowerWall=rgb(90, 200, 220), TowerCap=rgb(90, 200, 220),
		Gold=rgb(224, 170, 70)),
	5: dict(Stone=rgb(214, 208, 196), Wall=rgb(250, 249, 245), Lower=rgb(250, 249, 245), Beam=rgb(228, 222, 210),
		Board=rgb(236, 192, 76), Surround=rgb(236, 192, 76), Frame=rgb(236, 192, 76), Roof=rgb(44, 84, 170),
		Door=rgb(52, 90, 166), Band=rgb(236, 192, 76), Glass=rgb(130, 220, 240), TowerWall=rgb(250, 249, 245),
		TowerCap=rgb(44, 84, 170), Gold=rgb(236, 192, 76)),
}


def rnd(x):
	# Luau's math.round (Python's rounds a half to the even number)
	return math.floor(x + 0.5)


def bay_centres(length):
	# the module's bayCentres: the middles of a wall's bays, between the posts of `timbers`
	n = max(1, rnd(length / 3.2))
	step = (length - 0.4) / n
	return [-length / 2 + 0.2 + (i + 0.5) * step for i in range(n)]


def faces(hw, d, off):
	# a hall's four walls, front, back, left and right, standing `off` out
	return (Face(0, 0, off), Face(math.pi, 0, -d - off), Face(-math.pi / 2, hw + off, -d / 2),
		Face(math.pi / 2, -hw - off, -d / 2))


def timbers(m, u0, u1, v0, v1, braces=True, ends=False, gap=None, rivets=False):
	# The module's b.timber on a face: a rail at the foot and the top, a post about every 3.2 (`ends`: only the two
	# end ones), a brace in each end bay. `gap` (u0, u1) leaves a door's place free of the foot rail and of posts.
	length, n0, n1 = u1 - u0, -0.06, 0.24
	if gap:
		lbox(m, u0, gap[0], v0, v0 + 0.4, n0, n1, 0.05)
		lbox(m, gap[1], u1, v0, v0 + 0.4, n0, n1, 0.05)
	else:
		lbox(m, u0, u1, v0, v0 + 0.4, n0, n1, 0.05)
	lbox(m, u0, u1, v1 - 0.4, v1, n0, n1, 0.05)
	bays = max(1, rnd(length / 3.2))
	step = (length - 0.4) / bays
	for i in (0, bays) if ends else range(bays + 1):
		u = u0 + 0.2 + i * step
		if gap and gap[0] - 0.2 < u < gap[1] + 0.2:
			continue
		lbox(m, u - 0.2, u + 0.2, v0 + 0.4, v1 - 0.4, n0, n1 - 0.02, 0.05)
		if rivets:
			for v in (v0 + 0.2, v1 - 0.2):
				G.stud(m, (u, n1, v), (0, 1, 0), 0.1)
	if braces and not ends and bays >= 2 and v1 - v0 >= 3:
		G.bar(m, (u0 + 0.4, 0.06, v0 + 0.4), (u0 + step, 0.06, v1 - 0.4), 0.2, 0.32)
		G.bar(m, (u1 - 0.4, 0.06, v0 + 0.4), (u1 - step, 0.06, v1 - 0.4), 0.2, 0.32)


def tiled(m, axis, eave, top, e0, e1, rows, thick, lip=0.13, a_from=0.0, cut=None):
	# One slope of tiles from `eave` up to `top`: (x, y) of the module with the ridge along z (`axis` "z"), or (z, y)
	# with the ridge along x ("x"); e0..e1 along the ridge. A slab `thick` deep, its top on the roof's line as the
	# module's is, under `rows` courses that each stand `lip` proud at their foot. `a_from` starts it that far up the
	# slope (the courses stay where a whole slope's are); `cut` (the slope's own x or z -> e1) ends it on a slanting
	# line, a valley against another roof.
	(ep, ey), (tp, ty) = eave, top
	run = math.hypot(tp - ep, ty - ey)
	dp, dy = (tp - ep) / run, (ty - ey) / run
	np, ny = (-dy, dp) if dp > 0 else (dy, -dp)  # the slope's normal, the one that points up

	def at(a, nn, e):
		p, y = ep + dp * a + np * nn, ey + dy * a + ny * nn
		return (p, -e, y) if axis == "z" else (e, -p, y)

	def far(a, d=0.0):
		return (max(e0 + 0.01, cut(ep + dp * a)) if cut else e1) + d

	G.sweep(m, [[at(a_from, -thick, e0), at(a_from, 0, e0), at(run, 0, e0), at(run, -thick, e0)],
		[at(a_from, -thick, far(a_from)), at(a_from, 0, far(a_from)), at(run, 0, far(run)), at(run, -thick, far(run))]])
	for k in range(rows):
		a0, a1 = run * k / rows - (0.15 if k == 0 else 0.0), run * (k + 1) / rows + 0.03
		if a1 <= a_from:
			continue
		a0 = max(a0, a_from)
		foot = -thick if k == 0 else 0.0  # (the eave's course is as thick as the roof)
		G.sweep(m, [[at(a0, foot, e0 - 0.05), at(a0, lip, e0 - 0.05), at(a1, 0.015, e0 - 0.05), at(a1, -0.02, e0 - 0.05)],
			[at(a0, foot, far(a0, 0.05)), at(a0, lip, far(a0, 0.05)), at(a1, 0.015, far(a1, 0.05)),
				at(a1, -0.02, far(a1, 0.05))]])


def girdle(out, mk, F, slot, x, z, v0, v1, proud, ch=0.04):
	# a band round the four walls `F` of a hall (`x`, `z`: half its width and half its depth, to the walls' faces)
	for i, face in enumerate(F):
		e = x + proud if i < 2 else z
		t = mk()
		lbox(t[slot], -e, e, v0, v1, 0, proud, ch)
		face.put(out, t)


def granary(era):
	L = LOOK[era]
	hw, d, wall_h, rise, over, dw, jet = L["hw"], L["d"], L["wall_h"], L["rise"], L["over"], L["dw"], L["jet"]
	glass, timber = L["glass"], L["timber"]
	lower_top = L["lower_h"] or wall_h
	half = hw + jet
	pitch, ridge = rise / half, wall_h + rise
	door_top = BASE + L["dh"]
	R = dw * 0.36  # the arch's rise: a low half ellipse, cut straight three times a side in the module's wall
	spring = door_top - R
	inner = dw / 2 + 0.9
	w_out, w_len, w_h, w_rise = L["wing"]
	wz0, wz1 = 1.6, 1.6 + w_len
	wzc, x1 = (wz0 + wz1) / 2, hw + w_out
	hole_top = w_h - 0.8  # the way through the left wall into the wing
	lean_hi = min(wall_h - 0.6, 8.2)

	paint = PAINT[era]
	alias, first = {}, {}
	for k in FIELDS:
		if paint[k] in first:
			alias[k] = first[paint[k]]
		else:
			first[paint[k]] = k

	def mk():
		own = {k: M() for k in FIELDS if k not in alias}
		return {k: own[alias.get(k, k)] for k in FIELDS}

	def win(t, u, y, w, h, rd):
		if rd:
			window(t, u, y + w / 4, w, h + w / 2, w / 2, 0.24, "Frame", "Glass")
		else:
			window(t, u, y, w, h, 0.3, 0.24, "Frame", "Glass")

	def arch(k):
		return (dw / 2 * math.cos(math.radians(k * 30)), spring + R * math.sin(math.radians(k * 30)))

	out = mk()
	F0, F1 = faces(hw, d, 0.0), faces(hw, d, jet)
	stone, board, beam, roof = out["Stone"], out["Board"], out["Beam"], out["Roof"]
	wf, wb, wo = Face(0, 0, -wz0), Face(math.pi, 0, -wz1), Face(-math.pi / 2, x1, -wzc)  # the wing's three walls

	# the stone foot of the hall and of the wing: two courses of blocks round a core
	mbox(stone, -hw - 0.2, hw + 0.2, 0, BASE - 0.02, -0.2, d + 0.2)
	mbox(stone, hw, x1 + 0.2, 0, BASE - 0.02, wz0 - 0.2, wz1 + 0.2)
	for face, u0, u1 in ((F0[0], -hw - 0.3, hw + 0.3), (F0[1], -hw - 0.3, hw + 0.3), (F0[2], -d / 2 + 0.35, d / 2 - 0.35),
		(F0[3], -d / 2 + 0.35, d / 2 - 0.35), (wf, hw + 0.3, x1 + 0.3), (wb, -x1 - 0.3, -hw - 0.3),
		(wo, -w_len / 2 + 0.35, w_len / 2 - 0.35)):
		t = mk()
		courses(t["Stone"], u0, u1, 0, BASE, -0.35, 0.3, 2)
		face.put(out, t)

	# the dock before the door and its step (the capital's leaves open into the hall: a shallower dock)
	leaf_w = dw / 2 - 0.06
	dock_d, dock_hw = (3.6 if era == 5 else leaf_w + 0.6), dw / 2 + 1.5
	mbox(stone, -dock_hw + 0.12, dock_hw - 0.12, 0, BASE - 0.1, -dock_d + 0.12, 0)
	t = mk()
	courses(t["Stone"], -dock_hw, dock_hw, 0, BASE - 0.14, -0.4, 0, 2, 2.2)
	Face(0, 0, dock_d).put(out, t)
	for ang, x in ((-math.pi / 2, dock_hw), (math.pi / 2, -dock_hw)):
		t = mk()
		courses(t["Stone"], -dock_d / 2 + 0.4, dock_d / 2 - 0.4, 0, BASE - 0.14, -0.4, 0, 2, 1.8)
		Face(ang, x, dock_d / 2).put(out, t)
	for i in range(4):
		for j in range(2):
			mbox(stone, -dock_hw + i * dock_hw / 2, -dock_hw + (i + 1) * dock_hw / 2, BASE - 0.14, BASE,
				-dock_d + j * dock_d / 2, -dock_d + (j + 1) * dock_d / 2, 0.05)
	sw = dock_hw - 0.5
	for i in range(3):
		mbox(stone, -sw + i * sw * 2 / 3, -sw + (i + 1) * sw * 2 / 3, 0, 0.8, -dock_d - 1.2, -dock_d, 0.08)

	# THE WALLS, a storey at a time (the glasshouse's stay the game's own glass and brick: only its frame is modelled)
	storeys = [(BASE, lower_top, "Lower", 0.0, F0)]
	if L["lower_h"]:
		storeys.append((lower_top, wall_h, "Wall", jet, F1))
	if not glass:
		for y0, y1, slot, off, F in storeys:
			X, e = hw + off, d / 2 + off - T
			t = mk()
			wall(t[slot], -X, X, y0, y1, [(-dw / 2, dw / 2, BASE, door_top)])
			if y0 <= spring and y1 >= door_top:
				# (the corners over the arch, cut as the module's wall is: the ring below hides the cuts)
				for s in (-1, 1):
					G.prism(t[slot], [(s * x, y) for x, y in (arch(0), (dw / 2, door_top), arch(3), arch(2), arch(1))], -T, 0)
			F[0].put(out, t)
			t = mk()
			wall(t[slot], -X, X, y0, y1)
			F[1].put(out, t)
			t = mk()
			wall(t[slot], -e, e, y0, y1, [(wz0 + T - d / 2, wz1 - T - d / 2, BASE, hole_top)] if y0 < hole_top else [])
			F[2].put(out, t)
			t = mk()
			wall(t[slot], -e, e, y0, y1)
			F[3].put(out, t)
			# the wing's walls
			if y0 < w_h:
				for face, u0, u1 in ((wf, hw, x1), (wb, -x1, -hw), (wo, -w_len / 2 + T, w_len / 2 - T)):
					t = mk()
					wall(t[slot], u0, u1, y0, min(y1, w_h))
					face.put(out, t)

	# THE ROOF: courses of tiles, a roll along the ridge, barge boards at the gables
	t_roof = min(0.6, max(0.25, half * 2 * 0.035))  # (the module's slab)
	drop = t_roof * math.sqrt(1 + pitch * pitch)
	eave_x = half + over
	eave_y = ridge - pitch * eave_x
	rz0, rz1 = -jet - over, d + jet + over
	for s in (-1, 1):
		tiled(roof, "z", (s * eave_x, eave_y), (0, ridge), rz0, rz1, max(4, rnd(math.hypot(eave_x, ridge - eave_y) / 1.15)),
			t_roof)
		for z in (rz0 - 0.12, rz1 + 0.12):
			mbar(board, (s * (eave_x + 0.1), eave_y - pitch * 0.1 - drop / 2, z), (0, ridge - drop / 2, z), 0.3, t_roof + 0.35)
	roll(roof, (0, -rz0 + 0.25, ridge + 0.1), (0, -rz1 - 0.25, ridge + 0.1), 0.4)

	# THE GABLES, front and back: the wall's triangle under the roof, a tie beam, king post and struts, a round window
	for face in F1[:2]:
		t = mk()
		if not glass:
			G.prism(t["Wall"], [(-half + drop / pitch, wall_h), (half - drop / pitch, wall_h), (0, ridge - drop)], -T, 0)
		lbox(t["Board"], -half + 0.4, half - 0.4, wall_h - 0.25, wall_h + 0.25, -0.05, 0.3, 0.06)
		if timber:
			lbox(t["Beam"], -0.2, 0.2, wall_h + 0.25, ridge - drop - 0.2, -0.05, 0.25, 0.05)
			for s in (-1, 1):
				G.bar(t["Beam"], (s * half * 0.62, 0.1, wall_h + 0.2), (0, 0.1, wall_h + rise * 0.55), 0.3, 0.36)
		if era in (2, 3):
			r, gy = 1 + 0.15 * era, wall_h + rise * 0.36
			G.arch_band(t["Frame"], 0, gy, r, r + 0.3, 0.0, 0.42, 0, G.TAU, 20)
			G.prism(t["Glass"], G.arc(0, gy, r, 0, G.TAU, 20)[:-1], 0.0, 0.34)
			lbox(t["Frame"], -0.07, 0.07, gy - r, gy + r, 0.3, 0.44)
			lbox(t["Frame"], -r, r, gy - 0.07, gy + 0.07, 0.3, 0.44)
		face.put(out, t)

	# THE FRAME: bands of timber (steel on the glasshouse) at the module's floors, their posts where b.timber's stand
	if timber:
		fl = L["floors"]
		for i in range(len(fl) - 1):
			y0, y1 = fl[i], fl[i + 1]
			off = jet if y0 >= lower_top else 0.0
			F = F1 if off else F0
			X, e = hw + off, d / 2 + off
			cut = 0.45 if i == len(fl) - 2 else 0.0  # (under the eaves the side walls' top rail stops short)
			t = mk()
			timbers(t["Beam"], wz1 - d / 2 if y0 < hole_top else -e, e, y0, y1 - cut, rivets=glass)
			F[2].put(out, t)
			t = mk()
			timbers(t["Beam"], -e, e, y0, y1 - cut, rivets=glass)
			F[3].put(out, t)
			t = mk()
			timbers(t["Beam"], -X, X, y0, y1, gap=(-1.5, 1.5) if y0 < BASE + 4 else None, rivets=glass)
			F[1].put(out, t)
			t = mk()
			if y0 >= door_top:
				timbers(t["Beam"], -X, X, y0, y1, rivets=glass)
			else:
				timbers(t["Beam"], -X, -inner, y0, y1, ends=True, rivets=glass)
				timbers(t["Beam"], inner, X, y0, y1, ends=True, rivets=glass)
			F[0].put(out, t)
	else:
		# marble: pilasters with golden heads between the bays, a band under the roof
		def pilaster(t, u):
			lbox(t["Beam"], u - 0.45, u + 0.45, BASE, wall_h, -0.05, 0.3, 0.06)
			lbox(t["Beam"], u - 0.6, u + 0.6, BASE, BASE + 0.5, -0.05, 0.4, 0.07)
			lbox(t["Gold"], u - 0.65, u + 0.65, wall_h - 0.5, wall_h, -0.05, 0.46, 0.07)

		n = rnd(d / 3.2)
		tl, tr = mk(), mk()
		for i in range(n + 1):
			z = 0.45 + i * (d - 0.9) / n
			if not wz0 < z < wz1:
				pilaster(tl, z - d / 2)
			pilaster(tr, d / 2 - z)
		F0[2].put(out, tl)
		F0[3].put(out, tr)
		t = mk()
		for x in (-hw + 0.45, -inner, inner, hw - 0.45):
			pilaster(t, x)
		F0[0].put(out, t)
		t = mk()
		for x in (-hw + 0.45, hw - 0.45):
			pilaster(t, x)
		F0[1].put(out, t)
		girdle(out, mk, F0, "Beam", hw, d / 2, wall_h - 0.7, wall_h, 0.25, 0.05)
		girdle(out, mk, F0, "Gold", hw, d / 2, wall_h - 0.85, wall_h - 0.65, 0.35, 0.03)

	if L["lower_h"] and jet > 0:
		# the town's hall: its plaster storey stands out on a beam over corbels, quoins up the stone corners
		girdle(out, mk, F1, "Beam", hw + jet, d / 2 + jet, lower_top - 0.25, lower_top + 0.25, 0.18, 0.05)
		for i, face in enumerate(F0):
			e = hw if i < 2 else d / 2
			n = rnd(2 * e / 1.7)
			t = mk()
			for k in range(n + 1):
				u = -e + 0.5 + k * (2 * e - 1) / n
				if (i == 0 and abs(u) < dw / 2 + 1.5) or (i == 2 and wz0 - 0.6 < u + d / 2 < wz1 + 0.6):
					continue
				G.sweep(t["Beam"], [[(uu, 0.0, lower_top - 0.95), (uu, 0.5, lower_top - 0.3), (uu, 0.5, lower_top - 0.24),
					(uu, 0.0, lower_top - 0.24)] for uu in (u - 0.17, u + 0.17)])
			face.put(out, t)
		for s in (-1, 1):
			for back in (False, True):
				for i in range(5):
					wide, y = (1.3 if i % 2 == 0 else 0.9), BASE + 0.7 + i * 1.5
					z0, z1 = (d + 0.12 - wide, d + 0.12) if back else (-0.12, wide - 0.12)
					mbox(out["Surround"], s * (hw + 0.12 - wide), s * (hw + 0.12), y - 0.45, y + 0.45, z0, z1, 0.07)
	if glass:
		# the glasshouse: a stone cap along the brick foot and on the corner piers (the piers stay the game's brick)
		girdle(out, mk, F0, "Stone", hw, d / 2, lower_top - 0.15, lower_top + 0.15, 0.2)
		for s in (-1, 1):
			mbox(stone, s * (hw - 0.5) - 0.85, s * (hw - 0.5) + 0.85, spring, spring + 0.35, -0.35, 1.35, 0.06)

	# THE GREAT DOOR: jambs, imposts, the arch's ring, the two leaves swung open past square
	jw = 1.3 if glass else 1.1 if era == 3 else 0.55
	t = mk()
	jamb = t["Lower" if glass else "Surround"]
	for s in (-1, 1):
		a, b = sorted((s * (dw / 2 - 0.08), s * (dw / 2 + jw)))
		if era in (3, 4):
			courses(jamb, a, b, BASE, spring - 0.18, -0.7, 0.4, rnd((spring - BASE) / 0.85), jw + 1, 0.06)
		else:
			lbox(jamb, a, b, BASE, spring - 0.18, -0.7, 0.4, 0.06)
		a, b = sorted((s * (dw / 2 - 0.22), s * (dw / 2 + jw + 0.2)))
		lbox(t["Surround"], a, b, spring - 0.18, spring + 0.18, -0.8, 0.5, 0.05)

	def ring_at(k, n):
		a = math.pi * k / n
		c, sn = math.cos(a), math.sin(a)
		xi, zi, xo, zo = (dw / 2 - 0.24) * c, spring + (R - 0.24) * sn, (dw / 2 + 0.55) * c, spring + (R + 0.55) * sn
		return [(xi, -0.7, zi), (xo, -0.7, zo), (xo, 0.4, zo), (xi, 0.4, zi)]

	if era == 3:
		for k in range(13):  # stone voussoirs, a joint between each
			G.sweep(t["Surround"], [ring_at(k + 0.035, 13), ring_at(k + 0.965, 13)])
	else:
		G.sweep(t["Surround"], [ring_at(k, 18) for k in range(19)])
	F0[0].put(out, t)

	leaf_h = spring - BASE
	planks = max(4, rnd(leaf_w / 0.8))

	def leaf_top(x):
		# a leaf's top follows the arch: low at its hinge, high where the two meet
		q = (dw / 2 - x) / (dw / 2 - 0.32)
		return spring + (R - 0.32) * math.sqrt(max(0.0, 1 - q * q))

	for s in (-1, 1):
		t = mk()
		for k in range(planks):
			xa, xb = leaf_w * k / planks + 0.015, leaf_w * (k + 1) / planks - 0.015
			G.prism(t["Door"], [(xa, BASE + 0.04), (xb, BASE + 0.04), (xb, leaf_top(xb)), (xa, leaf_top(xa))], -0.13, 0.13)
		lo, hi = BASE + leaf_h * 0.22, BASE + leaf_h * 0.78
		for v in (lo, hi):
			lbox(t["Band"], 0.05, leaf_w - 0.2, v - 0.12, v + 0.12, -0.2, 0.2, 0.03)
		G.bar(t["Band"], (0.3, 0, lo + 0.2), (leaf_w - 0.35, 0, hi - 0.2), 0.36, 0.3)
		for n in (-0.2, 0.2):
			ring(t["Band"], (leaf_w - 0.55, n, BASE + leaf_h * 0.5))
		if era == 5:
			Face(-math.radians(90 - s * 10), s * dw / 2, -T - 0.2).put(out, t)
		else:
			Face(math.radians(90 - s * 10), s * dw / 2, 0.2).put(out, t)

	# THE WINDOWS, where the module's stand (between the posts); the back has its own, clear of its small door
	for y, w, h, rd in L["rows"]:
		up = L["lower_h"] is not None and y > lower_top
		off, F = (jet, F1) if up else (0.0, F0)
		X = hw + off
		t = mk()
		if y - h / 2 > door_top + 0.3:
			for c in bay_centres(X * 2)[1:-1]:
				if abs(c) > 2.3:
					win(t, c, y, w, h, rd)
		else:
			for s in (-1, 1):
				win(t, s * (inner + (X - inner) / 2 + 0.25), y, w, h, rd)
		F[0].put(out, t)
		t = mk()
		for c in bay_centres(X * 2)[1:-1]:
			if abs(c) > 2.3 or y - h / 2 > BASE + 4.6:
				win(t, c, y, w, h, rd)
		F[1].put(out, t)
		if not glass:
			cs = bay_centres(d + off * 2)
			tl, tr = mk(), mk()
			for c in cs[1:-1] if timber else cs:
				z = d / 2 + c
				if not (wz0 - 1 < z < wz1 + 1 and y - h / 2 < w_h + w_rise + 0.3):
					win(tl, c, y, w, h, rd)
				if y - h / 2 > lean_hi + 0.4 or z > 10.2 + 1.4:
					win(tr, -c, y, w, h, rd)
			F[2].put(out, tl)
			F[3].put(out, tr)

	# THE BACK: a small plank door on two stone steps (shut; it lies on the wall, which is not cut)
	t = mk()
	door_h = 3.7
	for s in (-1, 1):
		lbox(t["Beam"], s * 0.95, s * 1.25, BASE, BASE + door_h, 0, 0.26, 0.05)
	lbox(t["Beam"], -1.45, 1.45, BASE + door_h, BASE + door_h + 0.35, 0, 0.3, 0.05)
	for k in range(4):
		lbox(t["Door"], -0.95 + k * 0.475 + 0.012, -0.475 + k * 0.475 - 0.012, BASE + 0.03, BASE + door_h, 0, 0.1)
	for v in (BASE + 0.7, BASE + door_h - 0.7):
		lbox(t["Band"], -0.9, 0.55, v - 0.1, v + 0.1, 0.08, 0.15, 0.02)
	G.bar(t["Beam"], (-0.8, 0.14, BASE + 0.95), (0.8, 0.14, BASE + door_h - 0.95), 0.1, 0.22)
	ring(t["Band"], (0.62, 0.17, BASE + door_h / 2), 0.2, 0.045)
	lbox(t["Stone"], -1.7, 1.7, 0, 0.8, 0.3, 1.5, 0.08)
	lbox(t["Stone"], -1.4, 1.4, 0.8, BASE - 0.06, 0.3, 0.95, 0.07)
	F0[1].put(out, t)

	# THE CLOCK TOWER on tie beams across the hall; the clock, the gallery, the domes and the flag stay the game's
	tw, zt = L["tower"], d * 0.55
	dial = tw * 0.34
	clock_y = ridge + 0.6 + dial
	shaft_top, foot, tie_y = clock_y + dial + 1, ridge - pitch * tw / 2 - 0.8, wall_h - 0.9
	if not glass:
		mbox(out["TowerWall"], -tw / 2, tw / 2, foot, shaft_top, zt - tw / 2, zt + tw / 2)
	for sx in (-1, 1):
		for sz in (-1, 1):
			mbox(board, sx * (tw / 2 - 0.35), sx * (tw / 2 + 0.15), foot, shaft_top, zt + sz * (tw / 2 - 0.35),
				zt + sz * (tw / 2 + 0.15), 0.06)
			mbox(board, sx * (tw / 2 - 0.6), sx * tw / 2, tie_y, foot + 0.3, zt + sz * (tw / 2 - 0.6), zt + sz * tw / 2, 0.05)
	for sz in (-1, 1):
		z = zt + sz * (tw / 2 - 0.3)
		mbox(board, -hw + T - 0.05, hw - T + 0.05, tie_y - 0.3, tie_y + 0.3, z - 0.3, z + 0.3, 0.06)
	string_y, top = clock_y - dial - 0.65, shaft_top + 0.5
	for grow, y0, y1, ch in ((0.25, string_y - 0.18, string_y + 0.18, 0.06), (0.5, shaft_top, top, 0.1)):
		mbox(board, -tw / 2 - grow, tw / 2 + grow, y0, y1, zt - tw / 2 - grow, zt + tw / 2 + grow, ch)
	if L["cap"] == "pyramid":
		mbox(board, -tw / 2 - 0.85, tw / 2 + 0.85, top, top + 0.3, zt - tw / 2 - 0.85, zt + tw / 2 + 0.85, 0.08)
		# its cap: a pyramid of tile courses, each over the one below
		hb, y0, n, prof = (tw + 1.5) / 2, top + 0.3, 7, []
		for k in range(n):
			prof += [((hb * (1 - k / n) + 0.2) * SQ2, y0 + L["spire"] * k / n),
				((hb * (1 - (k + 1) / n) + 0.04) * SQ2, y0 + L["spire"] * (k + 1) / n)]
		prof.append((0.0, y0 + L["spire"] + 0.12))
		G.lat(out["TowerCap"], prof, 4, 0, -zt, cap_bottom=True, phase=math.pi / 4)

	# THE WING on the left, under a roof of its own that runs into the hall's
	if glass:
		# the glasshouse wing: steel ribs, a ridge, a sill and a fan over the game's glass barrel vault
		a = w_out / 2
		xm = hw + a
		for z in (wz0 - 0.25, wzc, wz1 + 0.25):
			t = mk()
			G.arch_band(t["Beam"], xm, w_h, a + 0.05, a + 0.6, -0.18, 0.18, 0, math.pi, 12, w_rise / (a + 0.3))
			Face(0, 0, -z).put(out, t)
		for k in range(1, 6):
			mbar(beam, (xm, w_h + 0.1, wz0 - 0.1), (xm + (a + 0.3) * math.cos(math.pi * k / 6),
				w_h + w_rise * math.sin(math.pi * k / 6), wz0 - 0.1), 0.2, 0.2)
		mbox(beam, xm - 0.2, xm + 0.2, w_h + w_rise - 0.05, w_h + w_rise + 0.25, wz0 - 0.4, wz1 + 0.4, 0.04)
		mbox(beam, xm - a - 0.3, xm + a + 0.3, w_h - 0.18, w_h + 0.18, wz0 - 0.35, wz0 + 0.15, 0.04)
		for z0, z1 in ((wz0 - 0.2, wz0 + T + 0.2), (wz1 - T - 0.2, wz1 + 0.2)):
			mbox(stone, hw - 0.1, x1 + 0.1, lower_top - 0.15, lower_top + 0.15, z0, z1, 0.04)
	else:
		wt = min(0.6, max(0.25, w_len * 0.035))
		wp = w_rise / (w_len / 2)
		wdrop = wt * math.sqrt(1 + wp * wp)
		for s in (-1, 1):
			ez, ey = wzc + s * (w_len / 2 + 0.8), w_h - wp * 0.8
			tiled(roof, "x", (ez, ey), (wzc, w_h + w_rise), hw - 0.1, x1 + 0.8,
				max(3, rnd(math.hypot(w_len / 2 + 0.8, w_rise + wp * 0.8) / 1.15)), wt)
			mbar(board, (x1 + 0.92, ey - wdrop / 2, ez), (x1 + 0.92, w_h + w_rise - wdrop / 2, wzc), 0.3, wt + 0.35)
		roll(roof, (hw + 0.2, -wzc, w_h + w_rise + 0.08), (x1 + 1.0, -wzc, w_h + w_rise + 0.08), 0.32)
		# its gable on the outer wall, a round eye in it; a window to the front, two on the outer wall
		y, w, h, rd = L["rows"][0]
		wy, eye = BASE + (w_h - BASE) * 0.55, w_h + w_rise * 0.36
		t = mk()
		G.prism(t["Wall"], [(-w_len / 2 + wdrop / wp, w_h), (w_len / 2 - wdrop / wp, w_h), (0, w_h + w_rise - wdrop)], -T, 0)
		G.arch_band(t["Frame"], 0, eye, 0.55, 0.8, 0.0, 0.3, 0, G.TAU, 16)
		G.prism(t["Glass"], G.arc(0, eye, 0.55, 0, G.TAU, 16)[:-1], 0.0, 0.2)
		framed = timber and era != 3
		# (in a frame the outer wall's windows stand in its end bays: the module's stood on the posts)
		for u in (bay_centres(w_len)[0], bay_centres(w_len)[-1]) if framed else (-0.22 * w_len, 0.22 * w_len):
			win(t, u, wy, w, h, rd)
		if framed:
			timbers(t["Beam"], -w_len / 2, w_len / 2, BASE, w_h, braces=False)
		wo.put(out, t)
		t = mk()
		win(t, hw + w_out / 2, wy, w, h, rd)
		if framed:
			timbers(t["Beam"], hw, x1, BASE, w_h)
		wf.put(out, t)
		if framed:
			t = mk()
			timbers(t["Beam"], -x1, -hw, BASE, w_h)
			wb.put(out, t)
	if glass:
		# (its steel band over the brick foot)
		for face, u0, u1 in ((wf, hw, x1), (wo, -w_len / 2, w_len / 2)):
			t = mk()
			timbers(t["Beam"], u0, u1, lower_top, w_h, braces=False, rivets=True)
			face.put(out, t)
	if era == 5:
		# a golden line round the hall at the wing's eaves (not across the doorway), a golden band round the wing's top
		for i, face in enumerate(F0):
			e = hw + 0.1 if i < 2 else d / 2
			t = mk()
			if i == 0:
				lbox(t["Gold"], -e, -dw / 2 - jw, w_h - 0.45, w_h - 0.15, 0, 0.1)
				lbox(t["Gold"], dw / 2 + jw, e, w_h - 0.45, w_h - 0.15, 0, 0.1)
			else:
				lbox(t["Gold"], -e, e, w_h - 0.45, w_h - 0.15, 0, 0.1)
			face.put(out, t)
		for face, u0, u1 in ((wf, hw, x1 + 0.15), (wb, -x1 - 0.15, -hw), (wo, -w_len / 2 - 0.15, w_len / 2 + 0.15)):
			t = mk()
			lbox(t["Gold"], u0, u1, w_h - 0.5, w_h, 0, 0.15, 0.04)
			face.put(out, t)

	# THE LEAN-TO along the right wall: tiles on a plate and a beam, three posts (round ones on the capital's)
	z0, z1, lean_out = 1.6, 10.2, 6.2
	slope, run = 1.6 / lean_out, lean_out + 0.6
	tiled(roof, "z", (-hw - run, lean_hi - slope * run + 0.18), (-hw, lean_hi + 0.18), z0 - 0.5, z1 + 0.5, 6, 0.35)
	px, beam_y = -(hw + lean_out - 0.3), lean_hi - slope * (lean_out - 0.3) - 0.4
	mbox(board, -hw - 0.3, -hw, lean_hi - 0.5, lean_hi - 0.1, z0 - 0.3, z1 + 0.3, 0.05)
	mbox(board, px - 0.2, px + 0.2, beam_y - 0.2, beam_y + 0.2, z0 - 0.3, z1 + 0.3, 0.05)
	zc = (z0 + z1) / 2
	for z in (z0 + 0.3, zc, z1 - 0.3):
		mbox(stone, px - 0.5, px + 0.5, FLOOR - 0.4, FLOOR + 0.3, z - 0.5, z + 0.5, 0.08)
		if era == 5:
			G.lat(beam, [(0.5, FLOOR + 0.3), (0.5, FLOOR + 0.6), (0.36, FLOOR + 0.78), (0.33, beam_y - 0.68),
				(0.5, beam_y - 0.5), (0.5, beam_y - 0.2)], 10, px, -z)
		else:
			mbox(board, px - 0.25, px + 0.25, FLOOR + 0.3, beam_y - 0.2, z - 0.25, z + 0.25, 0.07)
			mbar(board, (px, beam_y - 1.5, z), (px + 1.3, beam_y + 0.1, z), 0.3, 0.3)
			for dz in ((-1.3, 1.3) if z == zc else (1.3,) if z < zc else (-1.3,)):
				mbar(board, (px, beam_y - 1.5, z), (px, beam_y - 0.1, z + dz), 0.3, 0.3)
		mbar(board, (px - 0.5, beam_y + 0.2 + slope * 0.5, z), (-hw, lean_hi - 0.45, z), 0.3, 0.3)

	G.COL.update(paint)
	return [(f"GranaryBody{era}_{k}", out[k], (0, 0, 0), k, 35) for k in FIELDS if k not in alias and out[k].v]


# ---------------------------------------------------------------- the Kitchen
# src/server/Kitchen.luau: an open-fronted cookhouse 28.6 wide and 17.3 deep. The model's origin is the module's own
# (the front wall's outer face stands at z -5), the great chimney outside the left wall. The slots are the Look's
# colour fields, as the Granary's. What a level switches on stays the game's: lanterns, flower boxes, the side bays'
# and the gable's windows, the oven, wing, terrace, dormers, pipes, the vault's glass ends, columns, the emblem.
# The first era changes with its levels, so three of its parts are models of their own: the open truss (levels 1-6),
# the closed plaster gable (from 7) and the chimney's upper stack (from 8).

K_FIELDS = ("Stone", "Wall", "Lower", "Beam", "Board", "Roof", "Frame", "Glass", "Shutters", "Chimney", "Cap", "Gold")
K_HW, K_Z0, K_Z1, K_BAY, K_AISLE, K_CX, K_CZ = 14.3, -5.0, 12.3, 9.5, 10.7, 16.5, 6.2
K_LOOK = {
	1: dict(wall_h=8.2, rise=9.6, over=1.8, thick=0.9, stack=6.5, win=(5, 2.0)),
	2: dict(wall_h=8.6, rise=9.6, over=1.5, thick=0.6, stack=6.5, win=(5, 2.0)),
	3: dict(wall_h=9.6, rise=10.4, over=1.4, thick=0.6, stack=6.5, spring=4.4, arch_r=3.8, win=(7, 1.4)),
	4: dict(wall_h=9.6, rise=9.4, over=0.8, thick=0.2, stack=6.0, spring=5.0, arch_r=3.4),
	5: dict(wall_h=12.0, rise=6.5, over=0.5, thick=0.5, stack=11.0, spring=6.2, arch_r=4.0),
}
K_PAINT = {
	1: dict(Stone=rgb(150, 146, 138), Wall=rgb(236, 220, 180), Lower=rgb(170, 120, 72), Beam=rgb(110, 72, 42),
		Board=rgb(92, 60, 36), Roof=rgb(232, 190, 84), Frame=rgb(126, 84, 50), Glass=rgb(255, 214, 120),
		Shutters=rgb(120, 150, 96), Chimney=rgb(140, 138, 134), Cap=rgb(112, 110, 108), Gold=rgb(236, 190, 70)),
	2: dict(Stone=rgb(156, 152, 146), Wall=rgb(244, 238, 224), Lower=rgb(244, 238, 224), Beam=rgb(40, 128, 130),
		Board=rgb(32, 104, 108), Roof=rgb(198, 70, 58), Frame=rgb(250, 246, 236), Glass=rgb(255, 222, 140),
		Shutters=rgb(56, 146, 146), Chimney=rgb(190, 92, 66), Cap=rgb(232, 222, 200), Gold=rgb(236, 190, 70)),
	3: dict(Stone=rgb(128, 124, 118), Wall=rgb(240, 230, 206), Lower=rgb(198, 190, 174), Beam=rgb(112, 72, 44),
		Board=rgb(92, 60, 38), Roof=rgb(190, 62, 50), Frame=rgb(222, 216, 202), Glass=rgb(255, 222, 140),
		Shutters=rgb(222, 216, 202), Chimney=rgb(150, 146, 140), Cap=rgb(120, 116, 112), Gold=rgb(236, 190, 70)),
	4: dict(Stone=rgb(74, 80, 92), Wall=rgb(150, 225, 215), Lower=rgb(198, 112, 74), Beam=rgb(52, 56, 64),
		Board=rgb(40, 44, 50), Roof=rgb(62, 96, 160), Frame=rgb(214, 208, 196), Glass=rgb(255, 226, 150),
		Shutters=rgb(214, 208, 196), Chimney=rgb(124, 122, 120), Cap=rgb(84, 86, 92), Gold=rgb(224, 170, 70)),
	5: dict(Stone=rgb(214, 208, 196), Wall=rgb(250, 249, 245), Lower=rgb(250, 249, 245), Beam=rgb(228, 222, 210),
		Board=rgb(236, 192, 76), Roof=rgb(44, 84, 170), Frame=rgb(236, 192, 76), Glass=rgb(255, 230, 160),
		Shutters=rgb(236, 192, 76), Chimney=rgb(244, 242, 236), Cap=rgb(206, 200, 188), Gold=rgb(236, 192, 76)),
}
KITCHEN = {}


def kitchen_set(era):
	# every model of one era: {"body": rows, "truss": rows, "gable": rows, "stack": rows}
	if era in KITCHEN:
		return KITCHEN[era]
	L = K_LOOK[era]
	HW, Z0, Z1, BAY, CX, CZ = K_HW, K_Z0, K_Z1, K_BAY, K_CX, K_CZ
	ZC, LEN = (Z0 + Z1) / 2, Z1 - Z0
	wall_h, rise, over, thick = L["wall_h"], L["rise"], L["over"], L["thick"]
	half = K_AISLE if era == 5 else HW  # half the main roof's span
	pitch, ridge = rise / half, wall_h + rise
	under = thick + 0.5
	e = LEN / 2 - T  # half a side wall, between the front and the back wall

	paint = K_PAINT[era]
	alias, first = {}, {}
	for k in K_FIELDS:
		if paint[k] in first:
			alias[k] = first[paint[k]]
		else:
			first[paint[k]] = k

	def mk():
		own = {k: M() for k in K_FIELDS if k not in alias}
		return {k: own[alias.get(k, k)] for k in K_FIELDS}

	def win(t, u, y, w, h):
		if era >= 3:
			window(t, u, y + w / 4, w, h + w / 2, w / 2, 0.24, "Frame", "Glass")
		else:
			window(t, u, y, w, h, 0.3, 0.24, "Frame", "Glass")

	body, truss, gable, stack = mk(), mk(), mk(), mk()
	front, back = Face(0, 0, -Z0), Face(math.pi, 0, -Z1)
	sides = ((1, Face(-math.pi / 2, HW, -ZC)), (-1, Face(math.pi / 2, -HW, -ZC)))  # (a side's u is s * (z - ZC))
	beam = body["Beam"]

	# THE FRONT ----------------------------------------------------------------------------------------------------
	t = mk()
	if era <= 2:
		# posts on stone pads under a tie beam, knee braces; the side bays a plank panel, then a low plaster wall
		tie = wall_h - 0.9
		for x in (-(HW - 0.45), -BAY, BAY, HW - 0.45):
			lbox(t["Stone"], x - 0.8, x + 0.8, 0.25, FLOOR + 0.62, -1.25, 0.35, 0.1)
			lbox(t["Beam"], x - 0.48, x + 0.48, FLOOR + 0.6, tie, -0.93, 0.03, 0.07)
			lbox(t["Beam"], x - 0.62, x + 0.62, tie - 0.4, tie, -1.07, 0.17, 0.06)
		# (it ends at the posts' outer faces and a hair under the eaves: a longer or higher one stands out of the roof)
		lbox(t["Beam"], -HW + 0.1, HW - 0.1, tie, tie + 0.88, -0.93, 0.03, 0.08)
		for s in (-1, 1):
			for a, dd in ((BAY - 0.45, -2.6), (BAY + 0.45, 1.6), (HW - 0.9, -1.6)):
				G.bar(t["Beam"], (s * a, -0.45, tie - abs(dd)), (s * (a + dd), -0.45, tie + 0.1), 0.45, 0.5)
			x0, x1 = BAY + 0.45, HW - 0.9
			if era == 1:
				w = (x1 - x0) / 5
				lbox(t["Lower"], s * x0, s * x1, 0.3, 2.85, -0.5, -0.4)
				for k in range(5):
					lbox(t["Lower"], s * (x0 + k * w + 0.03), s * (x0 + (k + 1) * w - 0.03), 0.3, 2.9, -0.6, -0.3)
				lbox(t["Beam"], s * x0, s * x1, 2.9, 3.22, -0.7, -0.2, 0.05)
				lbox(t["Beam"], s * x0, s * x1, FLOOR, FLOOR + 0.3, -0.66, -0.24, 0.04)
			else:
				lbox(t["Wall"], s * x0, s * x1, 0.3, FLOOR + 3.22, -0.72, -0.18)
				lbox(t["Beam"], s * (x0 - 0.1), s * (x1 + 0.1), FLOOR + 3.2, FLOOR + 3.56, -0.92, 0.02, 0.06)
				lbox(t["Beam"], s * x0, s * x1, FLOOR, FLOOR + 0.36, -0.78, -0.12, 0.04)
	else:
		# piers either side of ONE wide arch (the wall over it cut straight four times a side, as the module's is:
		# the ring hides the cuts), a ring of stones, steel or gold round it, a keystone
		spring, R = L["spring"], L["arch_r"]
		top = wall_h - 1.2 if era == 5 else wall_h  # (the capital's entablature takes the rest)
		ring = {3: "Frame", 4: "Beam", 5: "Gold"}[era]
		crown = spring + R

		def arch(a, g):
			return ((BAY + g) * math.cos(a), spring + (R + g) * math.sin(a))

		def band(m, g0, g1, n0, n1, a0=0.0, a1=math.pi, n=24):
			secs = []
			for k in range(n + 1):
				(ui, vi), (uo, vo) = (arch(a0 + (a1 - a0) * k / n, g) for g in (g0, g1))
				secs.append([(ui, n0, vi), (uo, n0, vo), (uo, n1, vo), (ui, n1, vi)])
			G.sweep(m, secs)

		for s in (-1, 1):
			lbox(t["Lower"], s * BAY, s * HW, 0, top, -T, 0)
			for k in range(4):
				(px, py), (qx, qy) = (arch(math.radians(j * 22.5), 0) for j in (k, k + 1))
				G.prism(t["Lower"], [(s * px, py), (s * px, top), (s * qx, top), (s * qx, qy)], -T, 0)
			u0, u1 = sorted((s * (BAY - 0.2), s * (HW + 0.2)))
			courses(t["Stone"], u0, u1, 0, 1.0, -T - 0.2, 0.2, 1, 1.7)
			if era <= 4:
				for i in range(4):
					long = 0.9 if i % 2 else 1.3
					lbox(t["Frame"], s * BAY, s * (BAY + long), 1.04 + i * 0.9, 1.66 + i * 0.9, -T - 0.12, 0.12, 0.06)
			lbox(t["Frame"], s * (BAY - 0.2), s * (BAY + 1.3), spring - 0.33, spring + 0.13, -T - 0.22, 0.22, 0.06)
			if era == 5:
				# the portal: a marble lining inside the gold ring, deeper than the wall
				lbox(t["Wall"], s * (BAY - 0.6), s * BAY, 0, spring, -T - 0.5, 0.5)
				lbox(t["Gold"], s * (BAY - 0.82), s * (BAY + 0.12), spring - 0.02, spring + 0.32, -T - 0.67, 0.67, 0.05)
		if era == 3:
			# cut stone: proud voussoirs, every other one darker and a little lower
			span = math.radians(85.2)
			for s in (0, 1):
				for k in range(6):
					a0, a1 = span * k / 6 + 0.006, span * (k + 1) / 6 - 0.006
					if s:
						a0, a1 = math.pi - a0, math.pi - a1
					dark = k % 2 == 1
					band(t["Stone" if dark else "Frame"], -0.25, 0.82 if dark else 0.92, -T - (0.27 if dark else 0.35),
						0.27 if dark else 0.35, a0, a1, 2)
		elif era == 4:
			band(t["Beam"], -0.25, 0.7, -T - 0.15, 0.15)
			for k in range(1, 24):
				u, v = arch(math.pi * k / 24, 0.35)
				G.stud(t["Beam"], (u, 0.15, v), (0, 1, 0), 0.11)
		else:
			band(t["Gold"], 0.0, 0.7, -T - 0.15, 0.15)
			band(t["Wall"], -0.6, 0.02, -T - 0.5, 0.5)
		key = 1.5 if era == 3 else 1.2
		ky0, ky1 = crown + 0.55 - (key + 0.1) / 2, crown + 0.55 + (key + 0.1) / 2
		kd = (key - 0.7) / 2 + 0.06
		G.prism(t[ring], [(-0.53 * key, ky0), (0.53 * key, ky0), (0.67 * key, ky1), (-0.67 * key, ky1)], -T - kd, kd)
		if era == 3:
			# the jetty: a beam on corbels under the half-timbered gable
			lbox(t["Beam"], -HW + 0.1, HW - 0.1, wall_h - 0.82, wall_h - 0.02, -0.82, 0.52, 0.07)
			for x in (-HW + 0.5, -11.9, -BAY, BAY, 11.9, HW - 0.5):
				lbox(t["Beam"], x - 0.3, x + 0.3, wall_h - 1.5, wall_h - 0.8, -0.25, 0.65, 0.06)
				lbox(t["Beam"], x - 0.24, x + 0.24, wall_h - 1.9, wall_h - 1.5, -0.25, 0.36, 0.05)
		elif era == 4:
			# the vault's tie beam, riveted, a brass gear at the fan's hub; the fan's spokes and ring
			hub = wall_h + 0.2
			lbox(t["Beam"], -HW - 0.32, HW + 0.32, wall_h - 0.27, wall_h + 0.27, -1.27, 0.27, 0.06)
			for i in range(-6, 7):
				if abs(i) > 0:
					G.stud(t["Beam"], (i * 2.2, 0.27, wall_h), (0, 1, 0), 0.12)
			G.cog(t["Gold"], 0, hub, 1.15, 0.27, 0.5, 10)
			for k in range(1, 12):
				a = math.radians(k * 15)
				G.bar(t["Beam"], (0, -0.2, hub), ((HW - 0.4) * math.cos(a), -0.2, wall_h + (rise - 0.4) * math.sin(a)), 0.25, 0.25)
			secs = []
			for k in range(21):
				a = math.pi * k / 20
				c, sn = math.cos(a), math.sin(a)
				secs.append([((0.55 * HW + g) * c, n, hub + (0.55 * rise + g) * sn) for g, n in
					((-0.13, -0.34), (0.13, -0.34), (0.13, -0.06), (-0.13, -0.06))])
			G.sweep(t["Beam"], secs)
	front.put(body, t)

	# THE WALLS ----------------------------------------------------------------------------------------------------
	# the back wall: two lit windows either side of the stove, a plank door drawn on it (the stove stands inside)
	t = mk()
	wall(t["Lower" if era in (3, 4) else "Wall"], -HW, HW, 0.3, wall_h)
	if era <= 2:
		timbers(t["Beam"], -HW + 0.15, HW - 0.15, FLOOR, wall_h - 0.1)
	else:
		courses(t["Stone"], -HW - 0.2, HW + 0.2, 0, 1.0, -0.1, 0.2, 1, 2.0)
	for x in (-6, 6):
		win(t, x, 5.6, 2.0, 2.2)
	door = {1: "Lower", 2: "Shutters", 3: "Beam", 4: "Board", 5: "Cap"}[era]
	for k in range(4):
		lbox(t[door], -1.3 + k * 0.65 + 0.02, -1.3 + (k + 1) * 0.65 - 0.02, FLOOR, FLOOR + 4.6, -0.02, 0.14)
	for s in (-1, 1):
		lbox(t["Frame"], s * 1.3, s * 1.62, FLOOR, FLOOR + 4.6, -0.02, 0.27, 0.05)
	lbox(t["Frame"], -1.75, 1.75, FLOOR + 4.6, FLOOR + 4.96, -0.02, 0.31, 0.05)
	back.put(body, t)
	if era <= 2:
		t = mk()
		timbers(t["Beam"], -HW + T, HW - T, FLOOR, wall_h)
		Face(0, 0, -(Z1 - T)).put(body, t)

	# the side walls
	bays = bay_centres(LEN - 2 * T)
	for s, face in sides:
		t = mk()
		if era >= 3:
			u0, u1 = sorted((s * (Z0 + T + 0.2 - ZC), s * (Z1 - 0.1 - ZC)))
			courses(t["Stone"], u0, u1, 0, 1.0, -0.1, 0.2, 1, 2.0)
		if era == 1:
			# a plank half wall between posts: a shed, open under the eaves
			u0, u1 = sorted((s * (Z0 + 0.9 - ZC), s * (Z1 - T - ZC)))
			n = rnd((u1 - u0) / 0.95)
			w = (u1 - u0) / n
			for k in range(n):
				lbox(t["Lower"], u0 + k * w + 0.03, u0 + (k + 1) * w - 0.03, 0.3, 3.6, -T, 0.02 if k % 2 else -0.02)
			lbox(t["Beam"], u0, u1, 3.6, 3.92, -T - 0.17, 0.17, 0.05)
			for i in (1, 2, 3):
				u = s * (Z0 + 0.45 + i * (LEN - 0.75) / 4 - ZC)
				lbox(t["Beam"], u - 0.38, u + 0.38, 0.3, wall_h - 0.55, -0.78, 0.1, 0.06)
				for d in (-1, 1):
					G.bar(t["Beam"], (u + d * 0.3, -0.34, wall_h - 2.3), (u + d * 1.9, -0.34, wall_h - 0.55), 0.4, 0.4)
			lbox(t["Beam"], -LEN / 2 - 0.05, LEN / 2 + 0.05, wall_h - 0.62, wall_h - 0.03, -0.82, 0.0, 0.06)
		elif era == 4:
			# a brick foot under glass (the game's) in a riveted steel frame
			wall(t["Lower"], -e, e, 0.3, 4.4)
			lbox(t["Beam"], -e, e, 4.38, 4.72, -0.72, 0.14, 0.04)
			lbox(t["Beam"], -LEN / 2 - 0.05, LEN / 2 + 0.05, wall_h - 0.52, wall_h + 0.02, -0.72, 0.16, 0.05)
			step, mid = (LEN - 0.4) / 4, (4.7 + wall_h - 0.5) / 2
			for i in range(5):
				u = -LEN / 2 + 0.2 + i * step
				lbox(t["Beam"], u - 0.24, u + 0.24, 4.7, wall_h - 0.5, -0.58, 0.14, 0.04)
				for v in (5.1, mid, wall_h - 0.9):
					G.stud(t["Beam"], (u, 0.14, v), (0, 1, 0), 0.1)
				if i < 4:
					lbox(t["Beam"], u + step / 2 - 0.06, u + step / 2 + 0.06, 4.7, wall_h - 0.5, -0.1, 0.06)
			lbox(t["Beam"], -e, e, mid - 0.07, mid + 0.07, -0.1, 0.06)
		else:
			wall(t["Lower" if era == 3 else "Wall"], -e, e, 0.3, wall_h)
			if era == 2:
				# (0.3 under the eaves: the roof's line passes the wall's top, a timber proud of it stood out of the tiles)
				timbers(t["Beam"], -e, e, FLOOR, wall_h - 0.3, braces=False)
				lbox(t["Beam"], -e, e, 6.0, 6.4, -0.06, 0.22, 0.05)
			elif era == 3:
				lbox(t["Frame"], -e, e, 6.6, 6.9, -0.02, 0.16, 0.04)
				lbox(t["Beam"], -LEN / 2, LEN / 2, wall_h - 0.95, wall_h - 0.4, -0.02, 0.3, 0.06)
			else:
				# the capital: pilasters under a cornice, gold at their heads and along it
				n = len(bays)
				step = (LEN - 2 * T - 0.4) / n
				for i in range(n + 1):
					u = -e + 0.2 + i * step
					lbox(t["Stone"], u - 0.5, u + 0.5, 0.9, wall_h - 1.7, -0.02, 0.32, 0.05)
					lbox(t["Stone"], u - 0.62, u + 0.62, 0, 1.0, -0.02, 0.46, 0.06)
					lbox(t["Gold"], u - 0.62, u + 0.62, wall_h - 1.75, wall_h - 1.3, -0.02, 0.44, 0.05)
				lbox(t["Wall"], -LEN / 2 - 0.05, LEN / 2 + 0.05, wall_h - 1.2, wall_h + 0.02, -0.05, 0.52, 0.05)
				lbox(t["Wall"], -LEN / 2 - 0.05, LEN / 2 + 0.05, wall_h - 0.28, wall_h + 0.04, 0.4, 0.72, 0.04)
				lbox(t["Gold"], -LEN / 2 - 0.05, LEN / 2 + 0.05, wall_h - 1.34, wall_h - 1.16, -0.02, 0.6, 0.04)
			# (on the left the chimney and the oven take the middle; on the right the terrace is the front half)
			for i in ((1, 5) if s > 0 else (1, 3)):
				uc = -bays[i - 1]
				win(t, uc, 4, 1.8, 2.2)
				if era == 2:
					for d in (-1, 1):
						lbox(t["Shutters"], uc + d * 1.2, uc + d * 2.05, 2.9, 5.1, 0.2, 0.34, 0.03)
						for v in (3.3, 4.0, 4.7):
							lbox(t["Shutters"], uc + d * 1.27, uc + d * 1.98, v - 0.12, v + 0.12, 0.3, 0.4, 0.03)
		face.put(body, t)

	# THE ROOF -----------------------------------------------------------------------------------------------------
	if era != 4:
		# a great gable to the front (the capital's: a pediment over the nave): courses of thatch or tiles, a roll
		# along the ridge, barge boards
		eave_x = half + over
		eave_y = ridge - pitch * eave_x
		rz0, rz1 = Z0 - over, Z1 + over
		drop = thick * math.sqrt(1 + pitch * pitch)
		run = math.hypot(eave_x, ridge - eave_y)
		for s in (-1, 1):
			if era == 1:
				thatch(body["Roof"], (s * eave_x, eave_y), (0, ridge), rz0, rz1, 5, thick)
			else:
				tiled(body["Roof"], "z", (s * eave_x, eave_y), (0, ridge), rz0, rz1, max(4, rnd(run / 1.15)), thick)
			for z in (rz0 - 0.12, rz1 + 0.12):
				mbar(body["Board"], (s * (eave_x + 0.1), eave_y - pitch * 0.1 - drop / 2, z), (0, ridge - drop / 2, z), 0.3,
					thick + 0.35)
		roll(body["Roof"], (0, -rz0 + 0.25, ridge + 0.1), (0, -rz1 - 0.25, ridge + 0.1), 0.7 if era == 1 else 0.4)

		def gable_end(t, tie):
			# the wall's triangle under the roof; the timber eras frame it: rafters, struts, a post, a collar
			G.prism(t["Wall"], [(-half + drop / pitch, wall_h), (half - drop / pitch, wall_h), (0, ridge - drop)], -T, 0)
			if era > 3:
				return
			bm = t["Beam"]
			# (every timber's eave end keeps half a stud under the roof's line: the module's own stood out of the roof)
			xs = HW - 0.8 / pitch - 0.2
			for s in (-1, 1):
				G.bar(bm, (s * xs, 0.1, wall_h + 0.3), (0, 0.1, ridge - under - 0.25), 0.3, 0.5)
				G.bar(bm, (s * 3.4, 0.08, wall_h + 0.2), (s * 6.8, 0.08, ridge - pitch * 6.8 - under - 0.5), 0.26, 0.45)
			# (the post stops at the gable's window, which is the game's)
			wy, wh = L["win"]
			lbox(bm, -0.25, 0.25, wall_h, wall_h + wy - wh / 2 - 0.45, -0.02, 0.26, 0.04)
			if wall_h + wy + wh / 2 + 0.45 < ridge - under - 0.6:
				lbox(bm, -0.25, 0.25, wall_h + wy + wh / 2 + 0.45, ridge - under - 0.5, -0.02, 0.26, 0.04)
			cw = half * (1 - 3.3 / rise) - 1
			lbox(bm, -cw, cw, wall_h + 3.08, wall_h + 3.52, -0.02, 0.26, 0.04)
			if tie:
				lbox(bm, -HW + 0.9, HW - 0.9, wall_h - 0.25, wall_h + 0.25, -0.02, 0.28, 0.05)

		t = mk()
		gable_end(t, True)
		back.put(body, t)
		t = mk()
		gable_end(t, False)
		front.put(gable if era == 1 else body, t)
		if era == 1:
			# the open truss the first levels show in place of the gable
			t = mk()
			bm, n = t["Beam"], -0.45
			for s in (-1, 1):
				G.bar(bm, (s * (HW - 1.2), n, wall_h + 0.1), (0, n, ridge - under), 0.6, 0.6)
				G.bar(bm, (s * 3.4, n, wall_h), (s * 6.8, n, ridge - pitch * 6.8 - under - 0.4), 0.45, 0.45)
			lbox(bm, -0.3, 0.3, wall_h, ridge - under, n - 0.3, n + 0.3, 0.05)
			cw = half * 0.45 - 0.5
			lbox(bm, -cw, cw, wall_h + rise * 0.55 - 0.25, wall_h + rise * 0.55 + 0.25, n - 0.25, n + 0.25, 0.05)
			front.put(truss, t)
		if era <= 3:
			# two trusses over the hall
			for z in (Z0 + 4.3, Z1 - 1.8):
				mbox(beam, -HW + T - 0.05, HW - T + 0.05, wall_h - 0.62, wall_h + 0.02, z - 0.32, z + 0.32, 0.05)
				mbox(beam, -0.27, 0.27, wall_h, ridge - under, z - 0.27, z + 0.27)
				for s in (-1, 1):
					mbar(beam, (s * (HW - 1.1), wall_h + 0.1, z), (0, ridge - under, z), 0.5, 0.5)
		else:
			# the capital: flat aisle roofs either side of the nave, an entablature across the front, gold lines
			for s in (-1, 1):
				mbox(body["Stone"], s * (K_AISLE - 0.05), s * (HW + 0.05), wall_h - 0.22, wall_h + 0.22, Z0 - 0.05, Z1 + 0.05)
			mbox(body["Wall"], -HW - 0.57, HW + 0.57, wall_h - 1.22, wall_h + 0.02, Z0 - 1.72, Z0 + 0.62, 0.06)
			for y in (wall_h - 0.2, wall_h - 1.22):
				mbox(body["Gold"], -HW - 0.66, HW + 0.66, y, y + 0.17, Z0 - 1.81, Z0 + 0.4, 0.03)
	else:
		# a barrel vault in the era's roof: courses of shingles under steel ribs and purlins, an arch at each end
		za, zb = Z0 - over, Z1 + over

		def P(a, g):
			return ((HW + g) * math.cos(a), wall_h + (rise + g) * math.sin(a))

		def rib(z0, z1, g0, g1, n=16):
			secs = []
			for k in range(n + 1):
				(x0, y0), (x1, y1) = (P(math.pi * k / n, g) for g in (g0, g1))
				secs.append([(x0, -z0, y0), (x1, -z0, y1), (x1, -z1, y1), (x0, -z1, y0)])
			G.sweep(beam, secs)

		for k in range(16):
			a0, a1 = math.pi * k / 16, math.pi * (k + 1) / 16
			lo, hi = (a0, a1) if k < 8 else (a1, a0)
			sec = [P(lo, -0.15), P(lo, 0.3), P(hi, 0.17), P(hi, -0.15)]
			G.sweep(body["Roof"], [[(x, -z, y) for x, y in sec] for z in (za, zb)])
		for i in range(5):
			z = Z0 + 0.2 + i * (LEN - 0.4) / 4
			rib(z - 0.2, z + 0.2, 0.1, 0.5)
		rib(za - 0.1, za + 0.4, -0.45, 0.55)
		rib(zb - 0.4, zb + 0.1, -0.45, 0.55)
		for k in range(1, 12):
			x, y = P(math.radians(k * 15), 0.4)
			roll(beam, (x, -za + 0.05, y), (x, -zb - 0.05, y), 0.2 if k == 6 else 0.14, 6)

	# THE GREAT CHIMNEY, outside the left wall: a foot, a shoulder, two shafts, a cap -----------------------------------
	tall_top = ridge + L["stack"]
	low_top = ridge + 1.5  # (the first era's, before its upper stack is built)
	mid_top = min(wall_h + 6, (low_top if era == 1 else tall_top) - 3)

	def tier(dst, slot, w, y0, y1):
		h = w / 2
		if era == 5:
			# the capital's is round
			r = w * 0.55 + 0.1
			G.lat(dst[slot], [(r, y0), (r, y1)], 16, CX, -CZ, cap_bottom=True, cap_top=True)
		elif slot == "Chimney" and era != 2:
			# stone: courses of blocks round a core
			mbox(dst[slot], CX - h + 0.25, CX + h - 0.25, y0, y1, CZ - h + 0.25, CZ + h - 0.25)
			rows = max(1, rnd((y1 - y0) / 1.5))
			for ang, ox, oy, wide in ((-math.pi / 2, CX + h, -CZ, True), (math.pi / 2, CX - h, -CZ, True),
				(0, CX, -CZ + h, False), (math.pi, CX, -CZ - h, False)):
				tt = mk()
				half_u = h + 0.05 if wide else h - 0.3
				courses(tt[slot], -half_u, half_u, y0, y1, -0.3, 0.05, rows, 1.9 if wide else 1.6)
				Face(ang, ox, oy).put(dst, tt)
		else:
			mbox(dst[slot], CX - h - 0.05, CX + h + 0.05, y0, y1, CZ - h - 0.05, CZ + h + 0.05, 0.08)

	tier(body, "Chimney", 4.4, 0, 5)
	tier(body, "Cap", 4.0, 5, 5.6)
	tier(body, "Chimney", 3.4, 5.6, mid_top)
	tier(body, "Cap", 3.2, mid_top, mid_top + 0.5)
	tier(body, "Chimney", 2.8, mid_top + 0.5, low_top if era == 1 else tall_top)
	if era == 1:
		tier(stack, "Chimney", 2.8, low_top, tall_top)
	tier(stack if era == 1 else body, "Cap", 3.6, tall_top, tall_top + 0.7)
	if era == 3:
		tier(body, "Frame", 3.05, mid_top + 4, mid_top + 4.4)
	elif era >= 4:
		for fr in (0.2, 0.55, 0.9):
			y = mid_top + (tall_top - mid_top) * fr
			tier(body, "Gold", 3.1, y - 0.22, y + 0.22)
		tier(body, "Gold", 3.7, 8.2, 8.7)

	def rows(name, d):
		return [(f"{name}_{k}", d[k], (0, 0, 0), k, 35) for k in K_FIELDS if k not in alias and d[k].v]

	KITCHEN[era] = dict(body=rows(f"KitchenBody{era}", body), truss=rows("KitchenTruss1", truss),
		gable=rows("KitchenGable1", gable), stack=rows("KitchenStack1", stack))
	return KITCHEN[era]


def kitchen(era, part="body"):
	G.COL.update(K_PAINT[era])
	return kitchen_set(era)[part]


# ---------------------------------------------------------------- moulds every later landmark shares
# (the owner, 2026-11-18: the parts that come back house after house are made once and called with other numbers)


def arch_at(half, spring, R, a, g=0.0):
	# a point of the modules' arch (half its width, its spring line, its rise) at angle `a`, `g` outside it
	return ((half + g) * math.cos(a), spring + (R + g) * math.sin(a))


def ring_band(m, half, spring, R, g0, g1, n0, n1, a0=0.0, a1=math.pi, n=24):
	# a band round that arch on a face: from g0 to g1 outside it, n0..n1 out of the wall
	secs = []
	for k in range(n + 1):
		(ui, vi), (uo, vo) = (arch_at(half, spring, R, a0 + (a1 - a0) * k / n, g) for g in (g0, g1))
		secs.append([(ui, n0, vi), (uo, n0, vo), (uo, n1, vo), (ui, n1, vi)])
	G.sweep(m, secs)


def arch_wall(m, half, hw, spring, R, v0, top, n0=-T, n1=0.0):
	# a front wall with ONE wide arch: a pier each side, the wall over the arch cut straight four times a side as the
	# modules' archWall is (a ring hides the cuts)
	for s in (-1, 1):
		lbox(m, s * half, s * hw, v0, top, n0, n1)
		for k in range(4):
			(px, py), (qx, qy) = (arch_at(half, spring, R, math.radians(j * 22.5)) for j in (k, k + 1))
			G.prism(m, [(s * px, py), (s * px, top), (s * qx, top), (s * qx, qy)], n0, n1)


def rafter_pair(m, pitch, y, ridge, drop, n=0.08, w=0.26, t=0.4, gap=0.3):
	# two rafters on a gable's face, parallel to the roof and `gap` under its slab: no timber stands out of a roof
	d = drop + gap
	x0 = (ridge - d - (y + 0.5)) / pitch
	for s in (-1, 1):
		G.bar(m, (s * x0, n, y + 0.5), (0, n, ridge - d), w, t)


def cross_roof(out, mk, y, half, z0, z1, up, cross, cu, over=0.9, over2=0.6, tie=False):
	# The modules' tiledRoof: a gabled roof whose ridge runs along x over walls `half` wide from z0 to z1, `up` high
	# from the wall top `y`, and a cross gable `cross` wide and `cu` high over the middle of the front. Tiles (the
	# cross slopes end in the valleys), ridge rolls, barge boards, the three gables' plaster and their timber.
	zc, span = (z0 + z1) / 2, z1 - z0
	pm, p2 = up / (span / 2), cu / (cross / 2)
	th, th2 = min(0.6, max(0.25, span * 0.035)), min(0.6, max(0.25, cross * 0.035))
	drop, drop2 = th * math.sqrt(1 + pm * pm), th2 * math.sqrt(1 + p2 * p2)
	ridge, xe = y + up, half + over
	# (the cross eave stops where it would sink under the main slope)
	cx = min(cross / 2 + over2, (cu + pm * over2) / p2 - 0.02)
	roof, board = out["Roof"], out["Board"]
	rows = max(4, rnd(math.hypot(span / 2 + over, up + pm * over) / 1.15))
	rows2 = max(3, rnd(math.hypot(cx, p2 * cx) / 1.15))
	fe, be = (z0 - over, y - pm * over), (z1 + over, y - pm * over)
	tiled(roof, "x", be, (zc, ridge), -xe, xe, rows, th)
	for a, b in ((-xe, -cross / 2), (cross / 2, xe)):
		tiled(roof, "x", fe, (zc, ridge), a, b, rows, th)
	# (behind the cross gable's wall the main slope starts inside it: no eave strip stands before that wall)
	tiled(roof, "x", fe, (zc, ridge), -cross / 2, cross / 2, rows, th, a_from=(over + 0.5) * math.sqrt(1 + pm * pm))
	roll(roof, (-xe - 0.15, -zc, ridge + 0.08), (xe + 0.15, -zc, ridge + 0.08), 0.3)
	roll(roof, (0, -(z0 - over2 - 0.15), y + cu + 0.06), (0, -(z0 + cu / pm + 0.2), y + cu + 0.06), 0.26)
	zv = z0 - over2 - 0.1
	for s in (-1, 1):
		tiled(roof, "z", (s * cx, y + cu - p2 * cx), (0, y + cu), z0 - over2, None, rows2, th2,
			cut=lambda x: z0 + (cu - p2 * abs(x)) / pm)
		x = s * (xe + 0.1)
		for (ez, ey), d in ((fe, -1), (be, 1)):
			mbar(board, (x, ey - pm * 0.1 - drop / 2, ez + d * 0.1), (x, ridge - drop / 2, zc), 0.3, th + 0.35)
		mbar(board, (s * (cx + 0.1), y + cu - p2 * (cx + 0.1) - drop2 / 2, zv), (0, y + cu - drop2 / 2, zv), 0.3, th2 + 0.35)
		# a side's gable: plaster under the slab, a post, a rail, rafters
		t = mk()
		bm = t["Beam"]
		G.prism(t["Wall"], [(-span / 2 + drop / pm, y), (span / 2 - drop / pm, y), (0, ridge - drop)], -T, 0)
		lbox(bm, -0.2, 0.2, y, ridge - drop - 0.3, -0.02, 0.24, 0.04)
		hl = min(span * 0.25, (up * 0.58 - drop - 0.17) / pm - 0.05)
		lbox(bm, -hl, hl, y + up * 0.42 - 0.17, y + up * 0.42 + 0.17, -0.02, 0.22, 0.04)
		rafter_pair(bm, pm, y, ridge, drop)
		if tie:
			lbox(bm, -span / 2 + 0.6, span / 2 - 0.6, y - 0.02, y + 0.38, -0.02, 0.26, 0.05)
		Face(-s * math.pi / 2, s * half, -zc).put(out, t)
	# the front gable (the game's own window stands before it)
	t = mk()
	G.prism(t["Wall"], [(-cross / 2 + drop2 / p2, y), (cross / 2 - drop2 / p2, y), (0, y + cu - drop2)], -T, 0)
	hl = cross / 2 - (0.3 + drop2) / p2 - 0.1
	lbox(t["Beam"], -hl, hl, y - 0.17, y + 0.3, -0.02, 0.24, 0.05)
	rafter_pair(t["Beam"], p2, y, y + cu, drop2)
	Face(0, 0, -z0).put(out, t)


def barrel(roof, beam, hw, spring, R, za, zb, ribs, lip=0.3, rib=(0.1, 0.5), purlins=11, n=16):
	# a barrel vault over walls `hw` apart from za to zb: courses in the era's roof, ribs ((z, half its width)) and
	# purlins in its steel
	def P(a, g):
		return arch_at(hw, spring, R, a, g)

	for k in range(n):
		a0, a1 = math.pi * k / n, math.pi * (k + 1) / n
		lo, hi = (a0, a1) if k < n // 2 else (a1, a0)
		sec = [P(lo, -0.15), P(lo, lip), P(hi, lip * 0.55), P(hi, -0.15)]
		G.sweep(roof, [[(x, -z, y) for x, y in sec] for z in (za, zb)])
	for z, w in ribs:
		secs = []
		for k in range(n + 1):
			(x0, y0), (x1, y1) = (P(math.pi * k / n, g) for g in rib)
			secs.append([(x0, -(z - w), y0), (x1, -(z - w), y1), (x1, -(z + w), y1), (x0, -(z + w), y0)])
		G.sweep(beam, secs)
	for k in range(1, purlins + 1):
		x, y = P(math.pi * k / (purlins + 1), rib[1] - 0.1)
		roll(beam, (x, -za + 0.05, y), (x, -zb - 0.05, y), 0.12, 6)


def planks(m, u0, u1, v0, v1, w=0.7):
	# a wall of boards on a face: every other one a little proud, grooves between
	k = max(1, round((u1 - u0) / w))
	step = (u1 - u0) / k
	lbox(m, u0, u1, v0, v1, -T, -0.04)
	for i in range(k):
		lbox(m, u0 + i * step + 0.03, u0 + (i + 1) * step - 0.03, v0, v1 + 0.02, -T, 0.05 if i % 2 else 0.0)


def plank_door(t, w, h, floor, frame="Beam", uc=0.0):
	# a plank door on a wall's face, `w` half its width: boards, two ledges, jambs and a head
	pl = t["Shutters"]
	lbox(pl, uc - w, uc + w, floor, floor + h, -0.02, 0.05)
	for i in range(4):
		lbox(pl, uc - w + i * w / 2 + 0.03, uc - w + (i + 1) * w / 2 - 0.03, floor + 0.04, floor + h - 0.04, 0.0, 0.1)
	for v in (floor + 0.55, floor + h - 0.8):
		lbox(pl, uc - w + 0.08, uc + w - 0.08, v, v + 0.26, 0.05, 0.16, 0.03)
	for s in (-1, 1):
		lbox(t[frame], uc + s * w, uc + s * (w + 0.3), floor, floor + h, -0.06, 0.26, 0.05)
	lbox(t[frame], uc - w - 0.4, uc + w + 0.4, floor + h, floor + h + 0.35, -0.06, 0.3, 0.05)


def gable_roof(out, mk, cx, half, y, za, zb, up, over, thatched=False, barge="Board"):
	# The modules' frontGable: a roof whose ridge runs front to back over walls `half` each side of x = cx, from za to
	# zb, `up` high from the wall top `y`: thatch or tiles, barge boards at both ends, a ridge roll. Returns its pitch,
	# the slab's drop and the ridge's height, for the gables under it.
	pitch = up / half
	th = 0.6 if thatched else min(0.6, max(0.25, half * 2 * 0.035))
	drop, ridge = th * math.sqrt(1 + pitch * pitch), y + up
	run = math.hypot(half + over, up + pitch * over)
	t = mk()
	for s in (-1, 1):
		eave = (s * (half + over), y - pitch * over)
		if thatched:
			thatch(t["Roof"], eave, (0, ridge), za - over, zb + over, max(2, rnd(run / 2.2)), th, 0.34)
		else:
			tiled(t["Roof"], "z", eave, (0, ridge), za - over, zb + over, max(3, rnd(run / 1.15)), th)
		for z in (za - over - 0.12, zb + over + 0.12):
			mbar(t[barge], (s * (half + over + 0.1), y - pitch * (over + 0.1) - drop / 2, z), (0, ridge - drop / 2, z), 0.3,
				th + 0.35)
	r = 0.55 * min(1, half / 5) if thatched else 0.3
	roll(t["Roof"], (0, -(za - over - 0.25), ridge + 0.1), (0, -(zb + over + 0.25), ridge + 0.1), r)
	Face(0, cx, 0).put(out, t)
	return pitch, drop, ridge


def gable_wall(t, half, y, pitch, drop, ridge, slot="Wall", rail=True, struts=True, n0=-T):
	# a gable's face under such a roof (the face's u = 0 under the ridge): plaster under the slab, a rail on the wall
	# top, two struts, rafters; no post in the middle (an emblem hangs there)
	G.prism(t[slot], [(-half + drop / pitch, y), (half - drop / pitch, y), (0, ridge - drop)], n0, 0)
	bm = t["Beam"]
	if rail:
		lbox(bm, -half + 0.9, half - 0.9, y - 0.02, y + 0.42, -0.02, 0.26, 0.05)
	if struts:
		for s in (-1, 1):
			G.bar(bm, (s * half * 0.62, 0.08, y + 0.3), (s * half * 0.3, 0.08, ridge - drop - pitch * half * 0.3 - 0.55), 0.24, 0.3)
	if rail or struts:
		rafter_pair(bm, pitch, y, ridge, drop)


def stone_stack(out, mk, slot, cx, cz, w, y0, y1, row=0.9):
	# a square chimney shaft of fieldstone: courses of blocks round a core (the Kitchen's)
	h = w / 2
	mbox(out[slot], cx - h + 0.25, cx + h - 0.25, y0, y1, cz - h + 0.25, cz + h - 0.25)
	rows = max(1, rnd((y1 - y0) / row))
	for ang, ox, oy, wide in ((-math.pi / 2, cx + h, -cz, True), (math.pi / 2, cx - h, -cz, True),
		(0, cx, -cz + h, False), (math.pi, cx, -cz - h, False)):
		tt = mk()
		half_u = h + 0.05 if wide else h - 0.3
		courses(tt[slot], -half_u, half_u, y0, y1, -0.3, 0.05, rows, w)
		Face(ang, ox, oy).put(out, tt)


def box_room(out, mk, xa, xb, za, zb, v0, v1, slot, faces="fob", n0=-T):
	# the walls of a room that stands against a hall: its front, its outer side (xb) and its back, corner to corner
	t = mk()
	u0, u1 = sorted((xa, xb))
	if "f" in faces:
		lbox(t[slot], u0, u1, v0, v1, n0, 0)
		Face(0, 0, -za).put(out, t)
	if "b" in faces:
		t = mk()
		lbox(t[slot], -u1, -u0, v0, v1, n0, 0)
		Face(math.pi, 0, -zb).put(out, t)
	if "o" in faces:
		s = 1 if xb > xa else -1
		t = mk()
		lbox(t[slot], -(zb - za) / 2, (zb - za) / 2, v0, v1, n0, 0)
		Face(-s * math.pi / 2, xb, -(za + zb) / 2).put(out, t)


# ---------------------------------------------------------------- the Garden's house
# (only the house across the back of the garden: fence, gate, beds, water tower, the glass and the kit's pieces stay
# the module's)

G_FIELDS = ("Stone", "Wall", "Lower", "Beam", "Gold", "Board", "Roof", "Frame", "Glass", "Shutters")
GF, G_Z0, G_Z1 = 0.2, 18.5, 28.5  # the module's FLOOR, HZ and zb: its floor, its front wall and its back wall
G_LOOK = {1: (5.4, 6.2, 4.2), 2: (6.5, 6.8, 4.8), 3: (7.2, 6.8, 4.6), 4: (5.4, 9.4, 5.4), 5: (5.5, 9.0, 3.2)}  # hw, wallH, rise
G_PAINT = {
	1: dict(Stone=rgb(150, 146, 138), Wall=rgb(236, 220, 180), Lower=rgb(170, 120, 72), Beam=rgb(110, 72, 42),
		Gold=rgb(236, 190, 70), Board=rgb(92, 60, 36), Roof=rgb(232, 190, 84), Frame=rgb(126, 84, 50),
		Glass=rgb(255, 214, 120), Shutters=rgb(120, 150, 96)),
	2: dict(Stone=rgb(232, 222, 200), Wall=rgb(244, 238, 224), Lower=rgb(190, 92, 66), Beam=rgb(40, 128, 130),
		Gold=rgb(236, 190, 70), Board=rgb(32, 104, 108), Roof=rgb(198, 70, 58), Frame=rgb(250, 246, 236),
		Glass=rgb(250, 198, 100), Shutters=rgb(56, 146, 146)),
	3: dict(Stone=rgb(128, 124, 118), Wall=rgb(240, 230, 206), Lower=rgb(198, 190, 174), Beam=rgb(112, 72, 44),
		Gold=rgb(236, 190, 70), Board=rgb(92, 60, 38), Roof=rgb(190, 62, 50), Frame=rgb(222, 216, 202),
		Glass=rgb(250, 198, 100), Shutters=rgb(120, 150, 96)),
	4: dict(Stone=rgb(74, 80, 92), Wall=rgb(150, 225, 215), Lower=rgb(198, 112, 74), Beam=rgb(52, 56, 64),
		Gold=rgb(224, 170, 70), Board=rgb(40, 44, 50), Roof=rgb(62, 96, 160), Frame=rgb(214, 208, 196),
		Glass=rgb(250, 202, 108), Shutters=rgb(40, 44, 50)),
	5: dict(Stone=rgb(214, 208, 196), Wall=rgb(250, 249, 245), Lower=rgb(214, 208, 196), Beam=rgb(228, 222, 210),
		Gold=rgb(236, 192, 76), Board=rgb(236, 192, 76), Roof=rgb(44, 84, 170), Frame=rgb(236, 192, 76),
		Glass=rgb(250, 204, 112), Shutters=rgb(236, 192, 76)),
}
G_NAMES = dict(body="GardenBody{}", truss="GardenTruss1", gable="GardenGable1", lean="GardenLean1", roof="GardenRoof3",
	storey="GardenStorey3")
GARDEN = {}


def garden_set(era):
	# every model of one era: the body, and the pieces a level switches (era 1's open truss, closed gable and
	# lean-to; era 3's roof on the ground storey, or its jettied upper storey under that roof)
	if era in GARDEN:
		return GARDEN[era]
	hw, wall_h, rise = G_LOOK[era]
	Z0, Z1 = G_Z0, G_Z1
	ZC, top, e = (Z0 + Z1) / 2, GF + wall_h, (Z1 - Z0) / 2

	paint = G_PAINT[era]
	alias, first = {}, {}
	for k in G_FIELDS:
		if paint[k] in first:
			alias[k] = first[paint[k]]
		else:
			first[paint[k]] = k

	def mk():
		own = {k: M() for k in G_FIELDS if k not in alias}
		return {k: own[alias.get(k, k)] for k in G_FIELDS}

	parts = {k: mk() for k in G_NAMES}
	body = parts["body"]
	beam, board = body["Beam"], body["Board"]
	front, back = Face(0, 0, -Z0), Face(math.pi, 0, -Z1)
	sides = ((1, Face(-math.pi / 2, hw, -ZC)), (-1, Face(math.pi / 2, -hw, -ZC)))  # (a side's u is s * (z - ZC))

	def door(t, w, h, frame="Beam"):
		plank_door(t, w, h, GF, frame)

	if era == 1:
		# A POTTING SHED: two posts on stone pads under a tie beam, plank half walls under plaster, thatch
		sill, pitch, th = GF + 2.4, rise / hw, 0.6
		drop, ridge = th * math.sqrt(1 + pitch * pitch), top + rise
		for s in (-1, 1):
			x = s * (hw - 0.4)
			mbox(body["Stone"], x - 0.68, x + 0.68, GF, GF + 0.52, Z0 - 0.28, Z0 + 1.08, 0.1)
			mbox(beam, x - 0.45, x + 0.45, GF + 0.5, top - 0.76, Z0 - 0.05, Z0 + 0.85, 0.06)
			mbar(board, (s * (hw - 0.75), top - 2.6, Z0 + 0.4), (s * (hw - 2.4), top - 0.7, Z0 + 0.4), 0.45, 0.45)
		# (it ends inside the posts' outer faces and a hair under the eaves: a longer one stands out of the thatch)
		mbox(beam, -hw + 0.05, hw - 0.05, top - 0.78, top - 0.02, Z0 - 0.03, Z0 + 0.83, 0.07)

		def low_braces(t, ua, ub):
			for d, u in ((1, ua), (-1, ub)):
				G.bar(t["Board"], (u + d * 0.4, 0.06, sill + 0.25), (u + d * 1.9, 0.06, top - 0.75), 0.2, 0.3)

		for s, F in sides:
			t = mk()
			ua, ub = sorted((s * (Z0 + 0.8 - ZC), s * (Z1 - ZC)))
			planks(t["Lower"], ua, ub, GF, sill)
			wall(t["Wall"], ua, ub, sill, top)
			lbox(t["Beam"], ua, ub, sill - 0.18, sill + 0.18, -0.06, 0.26, 0.05)
			timbers(t["Beam"], ua, ub, GF, top - 0.3, braces=False)
			low_braces(t, ua, ub)
			if s == 1:
				window(t, (ua + ub) / 2, 4.6, 1.3, 1.5, 0.3, 0.2, "Frame", "Glass")
			F.put(body, t)
		t = mk()
		for u0, u1 in ((-hw, -1.5), (1.5, hw)):
			planks(t["Lower"], u0, u1, GF, sill)
			lbox(t["Beam"], u0, u1, sill - 0.18, sill + 0.18, -0.06, 0.26, 0.05)
		lbox(t["Wall"], -1.5, 1.5, GF, sill, -T, 0)
		wall(t["Wall"], -hw, hw, sill, top)
		timbers(t["Beam"], -hw + 0.15, hw - 0.15, GF, top - 0.1, braces=False, gap=(-1.5, 1.5))
		low_braces(t, -hw + 0.15, hw - 0.15)
		door(t, 1.2, 3.4)
		G.prism(t["Wall"], [(-hw + drop / pitch, top), (hw - drop / pitch, top), (0, ridge - drop)], -T, 0)
		rafter_pair(t["Beam"], pitch, top, ridge, drop)
		lbox(t["Beam"], -0.2, 0.2, top - 0.1, ridge - drop - 0.2, -0.02, 0.22, 0.04)
		back.put(body, t)
		for s in (-1, 1):
			thatch(body["Roof"], (s * (hw + 1), top - pitch), (0, ridge), Z0 - 1, Z1 + 1, 4, th, 0.34)
			for z in (Z0 - 1.12, Z1 + 1.12):
				mbar(board, (s * (hw + 1.1), top - pitch * 1.1 - drop / 2, z), (0, ridge - drop / 2, z), 0.3, th + 0.35)
		roll(body["Roof"], (0, -Z0 + 1.25, ridge + 0.1), (0, -Z1 - 1.25, ridge + 0.1), 0.55)
		# the open truss of the first levels
		t = mk()
		rafter_pair(t["Beam"], pitch, top - 0.45, ridge, drop, -0.3, 0.5, 0.5, 0.36)
		lbox(t["Beam"], -0.3, 0.3, top - 0.02, ridge - 0.67, -0.6, 0.0, 0.05)
		lbox(t["Beam"], -1.95, 1.95, top + rise * 0.5 - 0.23, top + rise * 0.5 + 0.23, -0.55, -0.05, 0.05)
		front.put(parts["truss"], t)
		# the plaster gable that closes it (its window is the game's)
		t = mk()
		G.prism(t["Wall"], [(-hw + drop / pitch, top), (hw - drop / pitch, top), (0, ridge - drop)], -T, 0)
		lbox(t["Beam"], -hw + 0.9, hw - 0.9, top - 0.02, top + 0.42, -0.02, 0.26, 0.05)
		rafter_pair(t["Beam"], pitch, top, ridge, drop)
		lbox(t["Beam"], -0.2, 0.2, top + 2.55, ridge - drop - 0.2, -0.02, 0.22, 0.04)
		front.put(parts["gable"], t)
		# the lean-to along the left wall
		ln = parts["lean"]
		thatch(ln["Roof"], (-hw - 4.25, GF + 3.68), (-hw + 0.05, GF + 5.13), Z0 + 0.6, Z1, 2, 0.5, 0.3)
		roll(ln["Roof"], (-hw - 4.2, -Z0 - 0.5, GF + 3.4), (-hw - 4.2, -Z1 - 0.1, GF + 3.4), 0.24)
		for z in (Z0 + 1, Z1 - 0.4):
			mbox(ln["Beam"], -hw - 3.89, -hw - 3.31, GF, GF + 3.3, z - 0.29, z + 0.29, 0.05)
		mbox(ln["Beam"], -hw - 3.86, -hw - 3.34, GF + 3.25, GF + 3.75, Z0 + 0.7, Z1 - 0.1, 0.05)
	elif era == 2:
		# A COTTAGE: cream plaster on teal beams, a flat timber arch over the open front, a cross-gabled tile roof
		aw, spring, R = 3.4, GF + 3.9, 1.9
		t = mk()
		bm = t["Beam"]
		arch_wall(t["Wall"], aw, hw, spring, R, GF, top)
		ring_band(bm, aw, spring, R, -0.05, 0.45, -T - 0.08, 0.22)
		for s in (-1, 1):
			lbox(bm, s * (aw - 0.05), s * (aw + 0.45), GF, spring, -T - 0.08, 0.22, 0.05)
			lbox(bm, s * (aw - 0.15), s * (aw + 0.6), spring - 0.2, spring + 0.14, -T - 0.14, 0.3, 0.05)
			lbox(bm, s * (aw + 0.45), s * (hw - 0.4), GF, GF + 0.4, -0.06, 0.22, 0.05)
		# (the rail keeps under the eaves' line: the roof comes down over the front)
		lbox(bm, -hw + 0.3, hw - 0.3, top - 0.8, top - 0.3, -0.06, 0.24, 0.05)
		front.put(body, t)
		for s in (-1, 1):
			for za, zb in ((Z0 - 0.1, Z0 + 0.5), (Z1 - 0.5, Z1 + 0.1)):
				mbox(beam, s * (hw - 0.5), s * (hw + 0.1), GF, top - 0.3, za, zb, 0.05)
		for s, F in sides:
			t = mk()
			bm = t["Beam"]
			wall(t["Wall"], -e, e, GF, top)
			lbox(bm, -e + 0.5, e - 0.5, GF, GF + 0.4, -0.06, 0.22, 0.05)
			lbox(bm, -e + 0.5, e - 0.5, top - 0.42, top - 0.02, -0.06, 0.24, 0.05)
			lbox(bm, -e + 0.5, e - 0.5, GF + 2.2, GF + 2.55, -0.06, 0.2, 0.05)
			for u in (-1.6, 1.6):
				# (the game's shuttered window takes the left wall's back half)
				if not (s == 1 and u > 0):
					lbox(bm, u - 0.2, u + 0.2, GF + 0.4, top - 0.42, -0.06, 0.22, 0.05)
			for d in (-1, 1):
				G.bar(bm, (d * (e - 0.6), 0.06, top - 2.5), (d * (e - 2.0), 0.06, top - 0.5), 0.2, 0.3)
			F.put(body, t)
		t = mk()
		bm = t["Beam"]
		wall(t["Wall"], -hw, hw, GF, top)
		for s in (-1, 1):
			lbox(bm, s * 1.2, s * (hw - 0.4), GF, GF + 0.4, -0.06, 0.22, 0.05)
			lbox(bm, s * 2.0 - 0.2, s * 2.0 + 0.2, GF + 0.4, top - 0.8, -0.06, 0.22, 0.05)
			window(t, s * 4.1, 3.9, 1.5, 1.9, 0.3, 0.22, "Frame", "Glass")
		lbox(bm, -hw + 0.3, hw - 0.3, top - 0.8, top - 0.3, -0.06, 0.24, 0.05)
		door(t, 0.9, 3.4)
		back.put(body, t)
		cross_roof(body, mk, top, hw, Z0, Z1, rise, 5.6, 3.3)
	elif era == 3:
		# AN ORANGERY: pale stone, ONE wide arch of two-tone voussoirs, quoins, a cornice; a bay on the left wall.
		# Its roof is a model of its own: at the era's last level a jettied timber storey lifts it.
		aw, spring, R = 2.8, GF + 3.8, 2.4
		cy0, cy1 = top - 0.8, top - 0.35  # the cornice, under the eaves' line
		t = mk()
		arch_wall(t["Lower"], aw, hw, spring, R, GF, top)
		for i in range(11):
			big = i % 2 == 0
			ring_band(t["Frame" if big else "Stone"], aw, spring, R, -0.05, 0.55 if big else 0.48, -T - 0.1,
				0.25 if big else 0.18, math.pi * i / 11 + 0.012, math.pi * (i + 1) / 11 - 0.012, 3)
		G.prism(t["Frame"], [(-0.32, spring + R - 0.3), (0.32, spring + R - 0.3), (0.48, top - 0.25), (-0.48, top - 0.25)],
			-T - 0.1, 0.42)
		for s in (-1, 1):
			lbox(t["Frame"], s * (aw - 0.1), s * (aw + 0.65), spring - 0.22, spring + 0.12, -T - 0.14, 0.3, 0.05)
			u0, u1 = sorted((s * (aw + 0.02), s * (hw + 0.18)))
			courses(t["Stone"], u0, u1, GF, GF + 0.8, -T - 0.05, 0.18, 1, 1.5)
			# (the cornice stops at the arch's ring; under the cross gable nothing stands over it)
			lbox(t["Frame"], s * 2.35, s * (hw + 0.3), cy0, cy1, 0, 0.3, 0.05)
		front.put(body, t)
		for s in (-1, 1):
			for zf, d in ((Z0, 1), (Z1, -1)):
				for i in range(7):
					long, y = i % 2 == 0, GF + 0.86 + i * 0.75
					mbox(body["Frame"], s * (hw - (1.0 if long else 0.65)), s * (hw + 0.12), y, y + 0.62, zf - d * 0.12,
						zf + d * (0.65 if long else 1.0), 0.06)
		for s, F in sides:
			t = mk()
			wall(t["Lower"], -e, e, GF, top)
			courses(t["Stone"], -e - 0.18, e + 0.18, GF, GF + 0.8, -0.05, 0.18, 1, 1.7)
			lbox(t["Frame"], -e - 0.3, e + 0.3, cy0, cy1, 0, 0.3, 0.05)
			F.put(body, t)
		t = mk()
		wall(t["Lower"], -hw, hw, GF, top)
		for s in (-1, 1):
			u0, u1 = sorted((s * 1.3, s * (hw + 0.18)))
			courses(t["Stone"], u0, u1, GF, GF + 0.8, -0.05, 0.18, 1, 1.6)
			window(t, s * 4.3, 4.0, 1.5, 2.9, 0.75, 0.24, "Frame", "Glass")
		lbox(t["Frame"], -hw - 0.3, hw + 0.3, cy0, cy1, 0, 0.3, 0.05)
		door(t, 1.0, 3.6, "Frame")
		back.put(body, t)
		# the bay on the left wall: stone walls on a plinth course, a tiled lean roof
		x1, x2, bz0, bz1, by = -hw, -hw - 3.4, Z0 + 1.6, Z1 - 0.8, GF + 3.9
		low, stone = body["Lower"], body["Stone"]
		mbox(low, x2, x1, GF, by, bz0, bz0 + T)
		mbox(low, x2, x2 + T, GF, by, bz0, bz1)
		mbox(low, x2, x1, GF, by, bz1 - T, bz1)
		mbox(stone, x2 - 0.16, x1, GF, GF + 0.8, bz0 - 0.16, bz0 + 0.3, 0.07)
		mbox(stone, x2 - 0.16, x2 + 0.3, GF, GF + 0.8, bz0 - 0.16, bz1 + 0.16, 0.07)
		mbox(stone, x2 - 0.16, x1, GF, GF + 0.8, bz1 - 0.3, bz1 + 0.16, 0.07)
		for zf in (bz0, bz1 - T):
			t = mk()
			G.prism(t["Lower"], [(x2, by), (x1, by), (x1, by + 1.5)], -T, 0)
			Face(0, 0, -zf).put(body, t)
		tiled(body["Roof"], "z", (x2 - 0.7, GF + 4.02), (x1, GF + 5.92), bz0 - 0.5, bz1 + 0.5, 3, 0.4)
		# the roof on the ground storey (levels 21 to 29)
		cross_roof(parts["roof"], mk, top, hw, Z0, Z1, rise, 6, 3.6, tie=True)
		# the jettied upper storey of level 30, under the same roof
		st = parts["storey"]
		sh, half, z0, z1 = 3.8, hw + 0.3, Z0 - 0.6, Z1 + 0.2
		ry, zc2, e2 = top + sh, (z0 + z1) / 2, (z1 - z0) / 2
		mbox(st["Beam"], -half - 0.15, half + 0.15, top - 0.03, top + 0.53, z0 - 0.05, z0 + 0.65, 0.06)
		for x in (-half + 0.3, -aw - 0.5, aw + 0.5, half - 0.3):
			mbar(st["Board"], (x, top - 1.1, Z0 - 0.05), (x, top + 0.05, z0 + 0.2), 0.4, 0.4)
		t = mk()
		bm = t["Beam"]
		wall(t["Wall"], -half, half, top + 0.5, ry)
		lbox(bm, -half + 0.3, half - 0.3, top + 0.5, top + 0.9, -0.06, 0.22, 0.05)
		lbox(bm, -half + 0.3, half - 0.3, ry - 0.7, ry - 0.3, -0.06, 0.24, 0.05)
		for u in (-2.3, 2.3):  # (between the game's three windows)
			lbox(bm, u - 0.2, u + 0.2, top + 0.9, ry - 0.7, -0.06, 0.22, 0.05)
		Face(0, 0, -z0).put(st, t)
		t = mk()
		wall(t["Wall"], -half, half, top + 0.5, ry)
		timbers(t["Beam"], -half + 0.3, half - 0.3, top + 0.5, ry - 0.3)
		Face(math.pi, 0, -z1).put(st, t)
		for s in (-1, 1):
			t = mk()
			wall(t["Wall"], -e2, e2, top + 0.5, ry)
			timbers(t["Beam"], -e2 + 0.3, e2 - 0.3, top + 0.5, ry - 0.02)
			Face(-s * math.pi / 2, s * half, -zc2).put(st, t)
			for zf, d in ((z0, 1), (z1, -1)):
				mbox(st["Beam"], s * (half - 0.5), s * (half + 0.1), top + 0.5, ry - 0.3, zf - d * 0.1, zf + d * 0.5, 0.05)
		cross_roof(st, mk, ry, half, z0, z1, 5, 6, 3.6)
	elif era == 4:
		# A GREENHOUSE: riveted black steel on brick plinths (the glass is the game's), a shingled barrel vault over
		# the nave with a raised lantern vault, a lower roof over each aisle
		ax, spring, R, eave, az = 9.0, top, rise, GF + 4.6, Z0 + 0.9
		low, cap, roof = body["Lower"], body["Frame"], body["Roof"]

		def plinth(xa, xb, za, zb):
			mbox(low, xa, xb, GF, GF + 1.3, za, zb)
			mbox(cap, xa - 0.1, xb + 0.1, GF + 1.3, GF + 1.5, za - 0.1, zb + 0.1, 0.04)
			mbox(beam, xa - 0.07, xb + 0.07, GF, GF + 0.24, za - 0.07, zb + 0.07, 0.03)

		plinth(-ax, ax, Z1 - T, Z1)
		zg = Z1 - T / 2  # the back wall's glass
		for k in range(1, 8):
			x = -ax + k * ax / 4
			mbox(beam, x - 0.13, x + 0.13, GF + 1.5, eave - 0.2, zg - 0.18, zg + 0.18)
		mbox(beam, -ax, ax, GF + 2.92, GF + 3.18, zg - 0.16, zg + 0.16)
		mbox(beam, -hw, hw, eave - 0.18, eave + 0.18, zg - 0.2, zg + 0.2)
		for x in (-2.7, 0, 2.7):
			mbox(beam, x - 0.13, x + 0.13, eave + 0.18, spring, zg - 0.18, zg + 0.18)
		mbox(beam, -hw, hw, GF + 6.9, GF + 7.16, zg - 0.16, zg + 0.16)
		for s in (-1, 1):
			x = s * hw
			# the nave's posts to the vault, a riveted web from the front one back to the aisle, the plate on them
			for z in (Z0, Z1):
				mbox(beam, x - 0.33, x + 0.33, GF, top, z - 0.33, z + 0.33, 0.04)
			for k in range(8):
				G.stud(beam, (x, -Z0 + 0.33, GF + 0.7 + k * 1.2), (0, 1, 0), 0.1)
			mbox(beam, x - 0.12, x + 0.12, GF, top - 0.5, Z0, az + 0.1)
			mbox(beam, x - 0.28, x + 0.28, spring - 0.53, spring + 0.03, Z0, Z1, 0.04)
			mbox(beam, x - 0.23, x + 0.23, GF + 6.9, spring - 0.5, ZC - 0.23, ZC + 0.23)
			mbar(beam, (x, spring - 2.2, Z0), (s * (hw - 2), spring - 0.3, Z0), 0.4, 0.4)
			# the aisle: plinths, corner posts, plates at its eaves, its roof under five ribs
			plinth(min(x, s * ax), max(x, s * ax), az, az + T)
			plinth(min(s * (ax - T), s * ax), max(s * (ax - T), s * ax), az + T, Z1 - T)
			for z in (az, Z1):
				mbox(beam, s * ax - 0.26, s * ax + 0.26, GF, eave + 0.2, z - 0.26, z + 0.26, 0.04)
				mbox(beam, x, s * ax, eave - 0.23, eave + 0.23, z - 0.23, z + 0.23, 0.04)
			mbox(beam, s * ax - 0.23, s * ax + 0.23, eave - 0.23, eave + 0.23, az, Z1, 0.04)
			tiled(roof, "z", (s * (ax + 0.3), eave + 0.15), (x, GF + 6.8), az, Z1, 3, 0.18, 0.08)
			for i in range(5):
				z = az + i * (Z1 - az) / 4
				mbar(beam, (x, GF + 6.88, z), (s * (ax + 0.3), eave + 0.23, z), 0.25, 0.28)
			# glazing bars: the aisle's outer wall, the clerestory over the aisle's roof
			zf, xm = az + T / 2, s * (hw + ax) / 2  # (the aisle's front)
			mbox(beam, xm - 0.13, xm + 0.13, GF + 1.5, eave - 0.2, zf - 0.18, zf + 0.18)
			mbox(beam, x, s * ax, GF + 2.92, GF + 3.18, zf - 0.16, zf + 0.16)
			xg = s * (ax - T / 2)
			for k in (1, 2, 3):
				z = az + T + k * (Z1 - az - T * 2) / 4
				mbox(beam, xg - 0.18, xg + 0.18, GF + 1.5, eave - 0.2, z - 0.13, z + 0.13)
			mbox(beam, xg - 0.16, xg + 0.16, GF + 2.92, GF + 3.18, az + T, Z1 - T)
			mbox(beam, x - 0.2, x + 0.2, GF + 6.65, GF + 6.95, az, Z1)
			for k in (1, 2, 4, 5):
				z = az + k * (Z1 - az) / 6
				mbox(beam, x - 0.18, x + 0.18, GF + 6.95, spring - 0.5, z - 0.13, z + 0.13)
		# the tie beam across the front, riveted; the vault; the fans' bars and a gold hub
		mbox(beam, -hw - 0.35, hw + 0.35, spring - 0.28, spring + 0.28, Z0 - 0.28, Z0 + 0.28, 0.05)
		for k in range(-5, 6):
			G.stud(beam, (k * 1.0, -Z0 + 0.28, spring), (0, 1, 0), 0.1)
		barrel(roof, beam, hw, spring, R, Z0, Z1, [(Z0 + i * (Z1 - Z0) / 4, 0.18) for i in range(5)], 0.2, (-0.25, 0.45), 7)
		for z in (Z0 - 0.08, Z1 + 0.08):
			for k in range(1, 8):
				x, y = arch_at(hw - 0.15, spring, R - 0.15, math.radians(k * 22.5))
				mbar(beam, (0, spring + 0.3, z), (x, y, z), 0.14, 0.14)
		t = mk()
		G.cog(t["Gold"], 0, spring + 0.3, 0.45, 0.28, 0.5, 8)
		front.put(body, t)
		r2 = 2.0
		s2 = spring + math.sqrt(R * R - r2 * r2) - 0.15
		lz0, lz1 = Z0 + 1.6, Z1 - 1.6
		barrel(roof, beam, r2, s2, r2, lz0, lz1, [(lz0, 0.15), (ZC, 0.12), (lz1, 0.15)], 0.14, (-0.12, 0.26), 3)
		roll(body["Gold"], (0, -lz0 + 0.2, s2 + r2 + 0.3), (0, -lz1 - 0.2, s2 + r2 + 0.3), 0.14)
	else:
		# A PALM HOUSE: a marble hall behind a pediment, a gold-ringed portal, an entablature all round, a wing each side
		aw, spring, R = 2.6, GF + 5, 2.4
		wx, wz0, wz1, wh, pz, et = 10.0, Z0 + 0.9, Z1 - 0.4, GF + 6.4, Z0 - 1.9, top + 0.6
		half = hw + 0.6
		pitch, th = rise / half, min(0.6, max(0.25, half * 2 * 0.035))
		drop, ridge = th * math.sqrt(1 + pitch * pitch), et + rise
		white, stone, gold, marble = body["Wall"], body["Stone"], body["Gold"], body["Beam"]
		mbox(stone, -hw - 1.2, hw + 1.2, GF, GF + 0.25, pz - 1, Z0, 0.04)
		mbox(white, -hw - 0.7, hw + 0.7, GF + 0.25, GF + 0.5, pz - 0.5, Z0, 0.04)
		t = mk()
		arch_wall(t["Wall"], aw, hw, spring, R, GF, top)
		# (a lining deeper than the wall, a gold ring round it)
		ring_band(t["Beam"], aw, spring, R, 0.0, 0.35, -T - 0.3, 0.3)
		ring_band(t["Gold"], aw, spring, R, 0.35, 0.6, -0.02, 0.2)
		G.prism(t["Gold"], [(-0.3, spring + R - 0.1), (0.3, spring + R - 0.1), (0.45, spring + R + 0.8),
			(-0.45, spring + R + 0.8)], -0.05, 0.42)
		for s in (-1, 1):
			lbox(t["Beam"], s * aw, s * (aw + 0.35), GF, spring, -T - 0.3, 0.3, 0.04)
			lbox(t["Gold"], s * (aw - 0.1), s * (aw + 0.75), spring - 0.2, spring + 0.1, -T - 0.36, 0.38, 0.04)
		front.put(body, t)
		for s, F in sides:
			t = mk()
			wall(t["Wall"], -e, e, GF, top)
			F.put(body, t)
		t = mk()
		wall(t["Wall"], -hw, hw, GF, top)
		door(t, 1.0, 3.8)
		back.put(body, t)
		# the entablature: across the porch as the module's, and on round the hall (it closes the slit under the eaves)
		mbox(white, -half, half, top - 0.4, et, pz + 0.1, Z0, 0.05)
		mbox(white, -half, half, top - 0.4, et, Z1 - T, Z1 + 0.15, 0.05)
		for s in (-1, 1):
			mbox(white, s * (hw - T), s * half, top - 0.4, et, Z0, Z1, 0.05)
		for y0, y1 in ((top - 0.4, top - 0.2), (et - 0.27, et - 0.07)):
			mbox(gold, -half - 0.08, half + 0.08, y0, y1, pz + 0.02, pz + 0.3, 0.03)
			mbox(gold, -half - 0.08, half + 0.08, y0, y1, Z1 - 0.1, Z1 + 0.23, 0.03)
			for s in (-1, 1):
				mbox(gold, s * (half - 0.2), s * (half + 0.08), y0, y1, pz + 0.02, Z1 + 0.23, 0.03)
		# a wing each side: marble walls on a stone plinth, pilasters, a flat roof with a gold cornice, arched windows
		for s in (-1, 1):
			mbox(white, s * hw, s * wx, GF, wh, wz0, wz0 + T)
			mbox(white, s * (wx - T), s * wx, GF, wh, wz0, wz1)
			mbox(white, s * hw, s * wx, GF, wh, wz1 - T, wz1)
			mbox(stone, s * hw, s * (wx + 0.3), wh, wh + 0.4, wz0 - 0.3, wz1 + 0.3, 0.05)
			mbox(gold, s * hw, s * (wx + 0.38), wh + 0.08, wh + 0.32, wz0 - 0.38, wz0 - 0.2, 0.03)
			mbox(gold, s * hw, s * (wx + 0.38), wh + 0.08, wh + 0.32, wz1 + 0.2, wz1 + 0.38, 0.03)
			mbox(gold, s * (wx + 0.2), s * (wx + 0.38), wh + 0.08, wh + 0.32, wz0 - 0.38, wz1 + 0.38, 0.03)
			mbox(stone, s * hw, s * (wx + 0.15), GF, GF + 0.8, wz0 - 0.15, wz0 + 0.2, 0.05)
			mbox(stone, s * hw, s * (wx + 0.15), GF, GF + 0.8, wz1 - 0.2, wz1 + 0.15, 0.05)
			mbox(stone, s * (wx - 0.2), s * (wx + 0.15), GF, GF + 0.8, wz0 - 0.15, wz1 + 0.15, 0.05)
			for zf, d in ((wz0, 1), (wz1, -1)):
				mbox(marble, s * (wx - 0.75), s * (wx + 0.1), GF + 0.8, wh, zf - d * 0.1, zf + d * 0.75, 0.04)
			t = mk()
			window(t, -s * (hw + wx) / 2, 3.9, 1.6, 3.2, 0.8, 0.22, "Frame", "Glass")
			Face(math.pi, 0, -wz1).put(body, t)
			t = mk()
			window(t, 0, 3.9, 1.6, 3.2, 0.8, 0.22, "Frame", "Glass")
			Face(-s * math.pi / 2, s * wx, -(wz0 + wz1) / 2).put(body, t)
		# the pediment at each end, gold raking boards, the tiled roof
		for zf, ang in ((pz, 0.0), (Z1, math.pi)):
			t = mk()
			G.prism(t["Wall"], [(-half + drop / pitch, et), (half - drop / pitch, et), (0, ridge - drop)], -T, 0)
			Face(ang, 0, -zf).put(body, t)
		for s in (-1, 1):
			tiled(body["Roof"], "z", (s * (half + 0.5), et - pitch * 0.5), (0, ridge), pz - 0.5, Z1 + 0.5, 6, th)
			for z in (pz - 0.62, Z1 + 0.62):
				mbar(gold, (s * (half + 0.6), et - pitch * 0.6 - drop / 2, z), (0, ridge - drop / 2, z), 0.3, th + 0.3)

	def rows(name, d):
		return [(f"{name}_{k}", d[k], (0, 0, 0), k, 35) for k in G_FIELDS if k not in alias and d[k].v]

	GARDEN[era] = {k: rows(G_NAMES[k].format(era), d) for k, d in parts.items()}
	return GARDEN[era]


def garden(era, part="body"):
	G.COL.update(G_PAINT[era])
	return garden_set(era)[part]


# ---------------------------------------------------------------- the Breeding House's hall
# (only the hall across the back of the pen with what is joined to it: the warm room, the wings, the turret, the
# boiler's foot and stack, the tower. The fence, the heart, the egg and its drum, the glass, the columns and the kit's
# pieces stay the module's)
B_FIELDS = ("Stone", "Wall", "Lower", "Beam", "Gold", "Board", "Roof", "Frame", "Glass", "Shutters")
BF, B_Z0, B_Z1 = 0.4, 20.0, 31.0  # the module's FLOOR, HZ and zb
B_LOOK = {1: (7.2, 6.6, 5.0), 2: (8.2, 7.2, 5.4), 3: (8.6, 8.0, 4.8), 4: (8.0, 10.0, 6.6), 5: (9.6, 10.5, 3.6)}  # hw, wallH, rise
B_PAINT = {
	1: dict(Stone=rgb(150, 146, 138), Wall=rgb(236, 220, 180), Lower=rgb(170, 120, 72), Beam=rgb(110, 72, 42),
		Gold=rgb(236, 190, 70), Board=rgb(92, 60, 36), Roof=rgb(232, 190, 84), Frame=rgb(126, 84, 50),
		Glass=rgb(250, 204, 110), Shutters=rgb(150, 110, 150)),
	2: dict(Stone=rgb(232, 222, 200), Wall=rgb(244, 238, 224), Lower=rgb(190, 92, 66), Beam=rgb(246, 160, 158),
		Gold=rgb(236, 190, 70), Board=rgb(224, 122, 126), Roof=rgb(198, 70, 58), Frame=rgb(250, 246, 236),
		Glass=rgb(250, 198, 100), Shutters=rgb(214, 104, 136)),
	3: dict(Stone=rgb(128, 124, 118), Wall=rgb(240, 230, 206), Lower=rgb(198, 190, 174), Beam=rgb(112, 72, 44),
		Gold=rgb(236, 190, 70), Board=rgb(92, 60, 38), Roof=rgb(190, 62, 50), Frame=rgb(222, 216, 202),
		Glass=rgb(250, 198, 100), Shutters=rgb(150, 110, 150)),
	4: dict(Stone=rgb(74, 80, 92), Wall=rgb(150, 225, 215), Lower=rgb(198, 112, 74), Beam=rgb(52, 56, 64),
		Gold=rgb(224, 170, 70), Board=rgb(40, 44, 50), Roof=rgb(62, 96, 160), Frame=rgb(214, 208, 196),
		Glass=rgb(250, 202, 108), Shutters=rgb(40, 44, 50)),
	5: dict(Stone=rgb(214, 208, 196), Wall=rgb(242, 239, 232), Lower=rgb(214, 208, 196), Beam=rgb(228, 222, 210),
		Gold=rgb(236, 192, 76), Board=rgb(236, 192, 76), Roof=rgb(44, 84, 170), Frame=rgb(236, 192, 76),
		Glass=rgb(250, 204, 112), Shutters=rgb(236, 192, 76)),
}
B_NAMES = dict(body="BreedingBody{}", truss="BreedingTruss1", gable="BreedingGable1", lean="BreedingLean1",
	chimney="BreedingChimney1", wing="BreedingWing2", roof="BreedingRoof3", storey="BreedingStorey3")
BREEDING = {}


def breeding_set(era):
	# every model of one era: the body, and the pieces a level switches (era 1's open truss, closed gable, lean-to and
	# chimney; era 2's right wing; era 3's roof on the stone hall, or its jettied storey under that roof)
	if era in BREEDING:
		return BREEDING[era]
	hw, wall_h, rise = B_LOOK[era]
	Z0, Z1 = B_Z0, B_Z1
	ZC, top, e = (Z0 + Z1) / 2, BF + wall_h, (Z1 - Z0) / 2
	rz0, rz1 = Z0 + 1.2, Z1 - 0.5  # the side rooms' front and back
	rzm, re = (rz0 + rz1) / 2, (rz1 - rz0) / 2

	paint = B_PAINT[era]
	alias, first = {}, {}
	for k in B_FIELDS:
		if paint[k] in first:
			alias[k] = first[paint[k]]
		else:
			first[paint[k]] = k

	def mk():
		own = {k: M() for k in B_FIELDS if k not in alias}
		return {k: own[alias.get(k, k)] for k in B_FIELDS}

	parts = {k: mk() for k in B_NAMES}
	body = parts["body"]
	beam, board = body["Beam"], body["Board"]
	front, back = Face(0, 0, -Z0), Face(math.pi, 0, -Z1)
	sides = ((1, Face(-math.pi / 2, hw, -ZC)), (-1, Face(math.pi / 2, -hw, -ZC)))  # (a side's u is s * (z - ZC))

	def room_faces(xa, xb):
		# a side room's front (u = x), outer side (u = s * (z - rzm)) and back (u = -x): it stands from the hall's
		# wall xa out to xb
		s = 1 if xb > xa else -1
		return Face(0, 0, -rz0), Face(-s * math.pi / 2, xb, -rzm), Face(math.pi, 0, -rz1)

	def room_roof(dst, cx, half, y, slot="Wall"):
		# a side room's own front-gabled roof, with its two gables
		p, d, r = gable_roof(dst, mk, cx, half, y, rz0, rz1, half * 0.85, 0.5)
		for F in (Face(0, cx, -rz0), Face(math.pi, cx, -rz1)):
			t = mk()
			gable_wall(t, half, y, p, d, r, slot, rail=False, struts=False)
			if slot == "Wall":
				rafter_pair(t["Beam"], p, y, r, d)
			F.put(dst, t)

	if era <= 2:
		# A TIMBER HALL: two posts on stone pads under a tie beam, its whole front open, its gable to the front; plank
		# half walls under plaster and thatch at the hamlet, plaster on rose beams under tiles at the village
		sill = BF + 2.6
		for s in (-1, 1):
			x = s * (hw - 0.45)
			mbox(body["Stone"], x - 0.73, x + 0.73, BF, BF + 0.52, Z0 - 0.28, Z0 + 1.18, 0.1)
			mbox(beam, x - 0.47, x + 0.47, BF + 0.5, top - 0.76, Z0 - 0.02, Z0 + 0.92, 0.06)
			mbar(board, (s * (hw - 0.7), top - 2.7, Z0 + 0.45), (s * (hw - 2.5), top - 0.8, Z0 + 0.45), 0.45, 0.45)
		# (it ends inside the posts' outer faces and a hair under the eaves: a longer one stands out of the roof)
		mbox(beam, -hw + 0.05, hw - 0.05, top - 0.78, top - 0.02, Z0 - 0.03, Z0 + 0.93, 0.07)
		pitch, drop, ridge = gable_roof(body, mk, 0, hw, top, Z0, Z1, rise, 1, thatched=era == 1)
		for s, F in sides:
			t = mk()
			ua, ub = sorted((s * (Z0 + 0.8 - ZC), s * (Z1 - ZC)))
			if era == 1:
				planks(t["Lower"], ua, ub, BF, sill)
				wall(t["Wall"], ua, ub, sill, top)
			else:
				wall(t["Wall"], ua, ub, BF, top)
			lbox(t["Beam"], ua, ub, sill - 0.18, sill + 0.18, -0.06, 0.26, 0.05)
			timbers(t["Beam"], ua, ub, BF, top - 0.3, braces=era == 2)
			if era == 1 and s == -1:
				# (the right wall's two windows, in its end bays; the left wall is the lean-to's)
				for d in (-1, 1):
					window(t, (ua + ub) / 2 + d * 3.27, BF + 4.5, 1.3, 1.6, 0.35, 0.2, "Frame", "Glass")
			F.put(body, t)
		t = mk()
		if era == 1:
			for u0, u1 in ((-hw, -1.5), (1.5, hw)):
				planks(t["Lower"], u0, u1, BF, sill)
			lbox(t["Wall"], -1.5, 1.5, BF, sill, -T, 0)
			wall(t["Wall"], -hw, hw, sill, top)
		else:
			wall(t["Wall"], -hw, hw, BF, top)
		for u0, u1 in ((-hw, -1.5), (1.5, hw)):
			lbox(t["Beam"], u0, u1, sill - 0.18, sill + 0.18, -0.06, 0.26, 0.05)
		timbers(t["Beam"], -hw + 0.15, hw - 0.15, BF, top - 0.1, braces=False, gap=(-1.5, 1.5))
		plank_door(t, 1.2, 3.6, BF, "Beam" if era == 1 else "Board")
		# (a window in the middle of each end bay of that frame)
		length = hw * 2 - 0.3
		wu = length / 2 - 0.2 - (length - 0.4) / max(1, rnd(length / 3.2)) / 2
		for d in (-1, 1):
			window(t, d * wu, BF + 4.6, 1.4, 1.7, 0.35, 0.22, "Frame", "Glass")
		gable_wall(t, hw, top, pitch, drop, ridge)
		back.put(body, t)
		if era == 1:
			# the open truss of the first levels
			t = mk()
			rafter_pair(t["Beam"], pitch, top - 0.45, ridge, drop, -0.3, 0.5, 0.5, 0.36)
			lbox(t["Beam"], -0.3, 0.3, top - 0.02, ridge - 0.67, -0.6, 0.0, 0.05)
			hc = hw - (rise * 0.5 + drop) / pitch
			lbox(t["Beam"], -hc, hc, top + rise * 0.5 - 0.23, top + rise * 0.5 + 0.23, -0.55, -0.05, 0.05)
			front.put(parts["truss"], t)
			# the plaster gable that closes it (the heart hangs on it)
			t = mk()
			gable_wall(t, hw, top, pitch, drop, ridge)
			front.put(parts["gable"], t)
			# the thatched warm room on the left wall: plank walls, plaster up to its lean roof (high at the hall)
			ln = parts["lean"]
			x1, x2 = hw, hw + 4.6
			F0, F1, F2 = room_faces(x1, x2)
			t = mk()
			planks(t["Lower"], x1, x2, BF, BF + 3.3)
			G.prism(t["Wall"], [(x1, BF + 3.3), (x2, BF + 3.3), (x2, BF + 3.4), (x1, BF + 5.15)], -T, 0)
			F0.put(ln, t)
			t = mk()
			planks(t["Lower"], -re, re, BF, BF + 3.3)
			F1.put(ln, t)
			t = mk()
			planks(t["Lower"], -x2, -x1, BF, BF + 3.3)
			G.prism(t["Wall"], [(-x2, BF + 3.3), (-x1, BF + 3.3), (-x1, BF + 5.15), (-x2, BF + 3.4)], -T, 0)
			F2.put(ln, t)
			thatch(ln["Roof"], (x2 + 0.7, BF + 3.72), (x1 + 0.05, BF + 5.8), rz0 - 0.6, rz1 + 0.6, 2, 0.55, 0.3)
			roll(ln["Roof"], (x2 + 0.62, -(rz0 - 0.7), BF + 3.45), (x2 + 0.62, -(rz1 + 0.7), BF + 3.45), 0.22)
			for x, z in ((x1 + 0.3, rz0 - 0.05), (x2 - 0.3, rz0 - 0.05), (x2 - 0.3, rz1 + 0.05)):
				mbox(ln["Beam"], x - 0.27, x + 0.27, BF, BF + 3.3, z - 0.27, z + 0.27, 0.05)
			mbox(ln["Beam"], x1, x2, BF + 3.2, BF + 3.52, rz0 - 0.3, rz0 - 0.02, 0.04)
			mbox(ln["Beam"], x2 + 0.02, x2 + 0.3, BF + 3.2, BF + 3.52, rz0 - 0.3, rz1 + 0.3, 0.04)
			# the fieldstone chimney that stands up through that roof
			ch = parts["chimney"]
			cx, cz, y1 = x2 - 1.4, rz1 - 1.5, BF + 10
			stone_stack(ch, mk, "Stone", cx, cz, 1.8, BF + 3.4, y1)
			mbox(ch["Frame"], cx - 1.17, cx + 1.17, y1 - 0.02, y1 + 0.42, cz - 1.17, cz + 1.17, 0.08)
		else:
			t = mk()
			gable_wall(t, hw, top, pitch, drop, ridge)
			front.put(body, t)
			# the brick stove room on the left wall under its own tiled gable, its brick chimney with a cream cap
			x1, x2, h = hw, hw + 5.6, BF + 5.2
			low = body["Lower"]
			box_room(body, mk, x1, x2, rz0, rz1, BF, h, "Lower")
			F0, F1, F2 = room_faces(x1, x2)
			for F, u0, u1 in ((F0, x1, x2 + 0.2), (F1, -re - 0.2, re + 0.2), (F2, -x2 - 0.2, -x1)):
				t = mk()
				lbox(t["Stone"], u0, u1, BF, BF + 0.62, 0, 0.3 if F is F0 else 0.2, 0.05)
				F.put(body, t)
			room_roof(body, (x1 + x2) / 2, 2.8, h, "Lower")
			cx, cz, y1 = x2 - 1.3, rz1 - 1.4, BF + 12.5
			mbox(low, cx - 0.88, cx + 0.88, BF + 5, y1, cz - 0.88, cz + 0.88, 0.07)
			mbox(low, cx - 1.0, cx + 1.0, y1 - 0.95, y1 - 0.6, cz - 1.0, cz + 1.0, 0.05)
			mbox(body["Frame"], cx - 1.12, cx + 1.12, y1 - 0.02, y1 + 0.42, cz - 1.12, cz + 1.12, 0.08)
			# the right wing of level 18: plaster on rose posts under its own tiled gable, a window in its side
			wg = parts["wing"]
			xa, xb, h = -hw, -hw - 5.2, BF + 5
			box_room(wg, mk, xa, xb, rz0, rz1, BF, h, "Wall")
			F0, F1, F2 = room_faces(xa, xb)
			t = mk()
			for x in (xb + 0.3, xa - 0.3):
				lbox(t["Beam"], x - 0.27, x + 0.27, BF, h, -0.02, 0.26, 0.05)
			lbox(t["Beam"], xb, xa, h - 0.42, h - 0.02, -0.04, 0.28, 0.05)
			lbox(t["Beam"], xb + 0.5, xa - 0.5, BF, BF + 0.4, -0.04, 0.24, 0.05)
			F0.put(wg, t)
			t = mk()
			timbers(t["Beam"], -re + 0.1, re - 0.1, BF, h - 0.3)
			window(t, 0, BF + 3.0, 1.4, 1.7, 0.35, 0.22, "Frame", "Glass")
			F1.put(wg, t)
			t = mk()
			timbers(t["Beam"], -xa + 0.1, -xb - 0.1, BF, h - 0.02, ends=True)
			F2.put(wg, t)
			room_roof(wg, (xa + xb) / 2, 2.6, h)
	elif era == 3:
		# A STONE HALL: ONE great arch of two-tone voussoirs under a keystone, quoins, a string course; a round turret
		# with its chimney on the left, a half-timbered wing on the right. Its roof is a model of its own: at the
		# era's last levels a jettied timber storey lifts it.
		ow, spring, R = hw - 2.8, BF + 3.6, 3.3
		low, stone, frame = body["Lower"], body["Stone"], body["Frame"]
		cy0, cy1 = top - 0.85, top - 0.4  # the side walls' cornice, under the eaves' line
		t = mk()
		arch_wall(t["Lower"], ow, hw, spring, R, BF, top, -0.8, 0.0)
		for i in range(13):
			big = i % 2 == 0
			ring_band(t["Frame" if big else "Stone"], ow, spring, R, -0.05, 0.9 if big else 0.8, -0.85,
				0.5 if big else 0.4, math.pi * i / 13 + 0.01, math.pi * (i + 1) / 13 - 0.01, 3)
		G.prism(t["Frame"], [(-0.42, spring + R - 0.35), (0.42, spring + R - 0.35), (0.62, top - 0.4), (-0.62, top - 0.4)],
			-0.85, 0.72)
		for s in (-1, 1):
			lbox(t["Frame"], s * (ow - 0.12), s * (ow + 1.05), spring - 0.3, spring + 0.1, -0.86, 0.56, 0.05)
			u0, u1 = sorted((s * (ow + 0.02), s * (hw + 0.18)))
			courses(t["Stone"], u0, u1, BF, BF + 0.8, -0.82, 0.18, 1, 1.4)
		lbox(t["Frame"], -hw, hw, top - 0.42, top - 0.02, 0, 0.35, 0.05)
		front.put(body, t)
		for s in (-1, 1):
			for zf, d in ((Z0, 1), (Z1, -1)):
				for i in range(8):
					long, y = i % 2 == 0, BF + 0.86 + i * 0.78
					mbox(frame, s * (hw - (1.0 if long else 0.65)), s * (hw + 0.12), y, y + 0.64, zf - d * 0.12,
						zf + d * (0.65 if long else 1.0), 0.06)
		for s, F in sides:
			t = mk()
			wall(t["Lower"], -e, e, BF, top)
			courses(t["Stone"], -e - 0.18, e + 0.18, BF, BF + 0.8, -0.05, 0.18, 1, 1.7)
			lbox(t["Frame"], -e - 0.3, e + 0.3, cy0, cy1, 0, 0.3, 0.05)
			F.put(body, t)
		t = mk()
		wall(t["Lower"], -hw, hw, BF, top)
		for s in (-1, 1):
			u0, u1 = sorted((s * 1.3, s * (hw + 0.18)))
			courses(t["Stone"], u0, u1, BF, BF + 0.8, -0.05, 0.18, 1, 1.6)
			window(t, s * 4.6, BF + 4.4, 1.5, 2.9, 0.75, 0.24, "Frame", "Glass")
		lbox(t["Frame"], -hw - 0.3, hw + 0.3, cy0, cy1, 0, 0.3, 0.05)
		plank_door(t, 1.0, 3.6, BF, "Frame")
		back.put(body, t)
		# the round turret (its cone roof is the kit's), a plinth ring, a band under its windows, a cornice
		tx, tz, th = hw + 3.4, Z0 + 3.8, BF + 12
		G.lat(low, [(3.04, BF), (3.04, th)], 16, tx, -tz, cap_top=True)
		G.lat(stone, [(3.32, BF), (3.32, BF + 0.7), (3.06, BF + 0.84)], 16, tx, -tz)
		G.lat(frame, [(3.06, BF + 4.25), (3.2, BF + 4.33), (3.2, BF + 4.62), (3.06, BF + 4.7)], 16, tx, -tz)
		G.lat(frame, [(3.06, th - 0.5), (3.42, th - 0.36), (3.42, th + 0.02), (3.0, th + 0.02)], 16, tx, -tz)
		cx, cz, y1 = tx + 1.9, tz + 2.6, BF + 15.5
		mbox(stone, cx - 0.73, cx + 0.73, BF, y1, cz - 0.73, cz + 0.73, 0.07)
		mbox(frame, cx - 0.82, cx + 0.82, y1 - 2.2, y1 - 1.88, cz - 0.82, cz + 0.82, 0.05)
		mbox(frame, cx - 0.97, cx + 0.97, y1 - 0.02, y1 + 0.42, cz - 0.97, cz + 0.97, 0.07)
		# the right wing: stone to its sill, plaster in timber above, its own tiled gable, a window in its side
		xa, xb, h, ws = -hw, -hw - 5.6, BF + 6.4, BF + 3.2
		box_room(body, mk, xa, xb, rz0, rz1, BF, ws, "Lower")
		box_room(body, mk, xa, xb, rz0, rz1, ws, h, "Wall")
		F0, F1, F2 = room_faces(xa, xb)
		t = mk()
		timbers(t["Beam"], xb + 0.1, xa - 0.1, ws, h - 0.02, ends=True)
		courses(t["Stone"], xb - 0.18, xa, BF, BF + 0.8, -0.05, 0.18, 1, 1.4)
		F0.put(body, t)
		t = mk()
		timbers(t["Beam"], -re + 0.1, re - 0.1, ws, h - 0.3)
		courses(t["Stone"], -re - 0.18, re + 0.18, BF, BF + 0.8, -0.05, 0.18, 1, 1.6)
		window(t, 0, BF + 4.65, 1.3, 1.6, 0.35, 0.22, "Frame", "Glass")
		F1.put(body, t)
		t = mk()
		timbers(t["Beam"], -xa + 0.1, -xb - 0.1, ws, h - 0.02, ends=True)
		courses(t["Stone"], -xa, -xb + 0.18, BF, BF + 0.8, -0.05, 0.18, 1, 1.4)
		F2.put(body, t)
		room_roof(body, (xa + xb) / 2, 2.8, h)
		# the roof on the stone hall (levels 21 to 28)
		rf = parts["roof"]
		p, d, r = gable_roof(rf, mk, 0, hw, top, Z0, Z1, rise, 0.9)
		for F in (front, back):
			t = mk()
			gable_wall(t, hw, top, p, d, r)
			F.put(rf, t)
		# the jettied upper storey of levels 29 and 30, under the same roof
		st = parts["storey"]
		half, z2, zb2 = hw + 0.3, Z0 - 0.6, Z1 + 0.2
		y2, zc2, e2 = top + 3.8, (z2 + zb2) / 2, (zb2 - z2) / 2
		mbox(st["Beam"], -half - 0.15, half + 0.15, top - 0.03, top + 0.45, z2 - 0.15, zb2 + 0.05, 0.06)
		for k in (-3, -2, -1, 1, 2, 3):
			x = k * (hw - 0.6) / 3
			mbar(st["Board"], (x, top - 1.15, Z0 - 0.05), (x, top, z2 + 0.15), 0.4, 0.4)
		t = mk()
		bm = t["Beam"]
		wall(t["Wall"], -half, half, top + 0.4, y2, n0=-0.5)
		lbox(bm, -half + 0.3, half - 0.3, top + 0.4, top + 0.8, -0.06, 0.22, 0.05)
		lbox(bm, -half + 0.3, half - 0.3, y2 - 0.42, y2 - 0.02, -0.06, 0.24, 0.05)
		for u in (-half + 0.5, -1.9, 1.9, half - 0.5):  # (between the game's two windows and the corners)
			lbox(bm, u - 0.2, u + 0.2, top + 0.8, y2 - 0.42, -0.06, 0.22, 0.05)
		Face(0, 0, -z2).put(st, t)
		t = mk()
		wall(t["Wall"], -half, half, top + 0.4, y2, n0=-0.5)
		timbers(t["Beam"], -half + 0.3, half - 0.3, top + 0.4, y2 - 0.02)
		Face(math.pi, 0, -zb2).put(st, t)
		for s in (-1, 1):
			t = mk()
			wall(t["Wall"], -e2, e2, top + 0.4, y2, n0=-0.5)
			timbers(t["Beam"], -e2 + 0.3, e2 - 0.3, top + 0.4, y2 - 0.3)
			Face(-s * math.pi / 2, s * half, -zc2).put(st, t)
			for zf, d in ((z2, 1), (zb2, -1)):
				mbox(st["Beam"], s * (half - 0.5), s * (half + 0.1), top + 0.4, y2 - 0.3, zf - d * 0.1, zf + d * 0.5, 0.05)
		p, d, r = gable_roof(st, mk, 0, half, y2, z2, Z1, rise, 0.9)
		for F in (Face(0, 0, -z2), Face(math.pi, 0, -zb2)):
			t = mk()
			gable_wall(t, half, y2, p, d, r)
			F.put(st, t)
	elif era == 4:
		# A STEEL AND GLASS VAULT on brick (the glass is the game's): riveted posts and rails, a shingled barrel vault
		# under ribs, a heavy two-tone ring on brick piers round the open front, a lower vault each side, the boiler's
		# brick foot and its steel stack
		low, cap, stone, roof, gold = body["Lower"], body["Frame"], body["Stone"], body["Roof"], body["Gold"]
		wy = BF + 2.8  # the brick walls' top
		mid = (wy + top) / 2
		for s in (-1, 1):
			x = s * (hw - 0.3)
			mbox(low, s * (hw - T), s * hw, BF, wy, Z0, Z1)
			mbox(cap, x - 0.47, x + 0.47, wy, wy + 0.3, Z0, Z1 + 0.1, 0.04)
			for k in range(4):
				z = Z0 + 0.3 + k * (Z1 - Z0 - 0.6) / 3
				mbox(beam, x - 0.26, x + 0.26, wy + 0.3, top - 0.5, z - 0.26, z + 0.26, 0.04)
				for j in range(4):
					G.stud(beam, (s * (hw - 0.04), -z, wy + 1.2 + j * 1.9), (s, 0, 0), 0.1)
			for k in range(3):
				z = Z0 + 0.3 + (k + 0.5) * (Z1 - Z0 - 0.6) / 3
				mbox(beam, x - 0.1, x + 0.1, wy + 0.3, top - 0.5, z - 0.09, z + 0.09)
			mbox(beam, x - 0.28, x + 0.28, top - 0.52, top + 0.02, Z0, Z1, 0.04)
			mbox(beam, x - 0.1, x + 0.1, mid - 0.13, mid + 0.13, Z0, Z1)
			# the front pier: brick on a slate foot under a stone cap, a stone band
			mbox(low, s * (hw - 1.7), s * (hw + 0.2), BF, top, Z0 - 0.4, Z0 + 0.8, 0.05)
			mbox(cap, s * (hw - 1.9), s * (hw + 0.4), top, top + 0.4, Z0 - 0.6, Z0 + 1.0, 0.06)
			mbox(cap, s * (hw - 1.82), s * (hw + 0.32), BF + 7.0, BF + 7.35, Z0 - 0.52, Z0 + 0.92, 0.04)
			mbox(stone, s * (hw - 1.9), s * (hw + 0.4), BF, BF + 0.7, Z0 - 0.6, Z0 + 1.0, 0.06)
		# the back wall: brick under a cap, glazing bars and the lunette's fan
		mbox(low, -hw, hw, BF, wy, Z1 - T, Z1)
		mbox(cap, -hw - 0.1, hw + 0.1, wy, wy + 0.3, Z1 - 0.75, Z1 + 0.15, 0.04)
		zg = Z1 - 0.2
		for k in range(1, 6):
			x = -hw + k * hw / 3
			mbox(beam, x - 0.13, x + 0.13, wy + 0.3, top - 0.25, zg - 0.18, zg + 0.18)
		mbox(beam, -hw, hw, mid - 0.13, mid + 0.13, zg - 0.16, zg + 0.16)
		mbox(beam, -hw, hw, top - 0.3, top + 0.2, zg - 0.22, zg + 0.22, 0.04)
		for k in range(1, 8):
			x, y = arch_at(hw - 0.3, top, rise - 0.3, math.radians(k * 22.5))
			mbar(beam, (0, top + 0.2, zg), (x, y, zg), 0.14, 0.14)
		barrel(roof, beam, hw, top, rise, Z0, Z1, [(Z0 + 0.2 + k * (Z1 - Z0 - 0.4) / 3, 0.22) for k in range(4)], 0.2,
			(-0.25, 0.45), 7)
		# the front: the ring (brick and stone, a brass stud on every stone), the riveted transom, the lunette's bars
		t = mk()
		for i in range(15):
			big = i % 2 == 0
			ring_band(t["Frame" if big else "Lower"], hw, top, rise, -0.25, 0.72 if big else 0.62, -0.45,
				0.72 if big else 0.62, math.pi * i / 15 + 0.008, math.pi * (i + 1) / 15 - 0.008, 3)
			if big:
				u, v = arch_at(hw, top, rise, math.pi * (i + 0.5) / 15, 0.25)
				G.stud(t["Gold"], (u, 0.72, v), (0, 1, 0), 0.17)
		lbox(t["Beam"], -(hw - 1.7), hw - 1.7, top - 0.15, top + 0.35, -0.4, 0.2, 0.04)
		for k in range(-6, 7):
			G.stud(t["Beam"], (k * 0.95, 0.2, top + 0.1), (0, 1, 0), 0.1)
		for k in range(1, 8):
			u, v = arch_at(hw - 0.5, top + 0.3, rise - 0.5, math.radians(k * 22.5))
			G.bar(t["Beam"], (0, 0, top + 0.3), (u, 0, v), 0.14, 0.14)
		front.put(body, t)
		# a wing each side: brick foot walls under a stone sill, steel posts and plates, a small vault with fan bars
		ww = 5.4
		for s in (-1, 1):
			cx, half, spring, R = s * (hw + ww / 2), ww / 2 - 0.2, BF + 4.4, 2.5
			mbox(low, s * (hw + ww - 0.5), s * (hw + ww), BF, BF + 1.8, rz0, rz1)
			for z in (rz0, rz1 - 0.5):
				mbox(low, s * hw, s * (hw + ww), BF, BF + 1.8, z, z + 0.5)
			mbox(cap, s * hw, s * (hw + ww + 0.15), BF + 1.8, BF + 2.1, rz0 - 0.2, rz0 + 0.6, 0.04)
			mbox(cap, s * hw, s * (hw + ww + 0.15), BF + 1.8, BF + 2.1, rz1 - 0.6, rz1 + 0.15, 0.04)
			mbox(cap, s * (hw + ww - 0.6), s * (hw + ww + 0.15), BF + 1.8, BF + 2.1, rz0 + 0.6, rz1 - 0.6, 0.04)
			for z in (rz0 + 0.25, rz1 - 0.25):
				for k in (-1, 0, 1):
					x = cx + k * half
					mbox(beam, x - 0.21, x + 0.21, BF + 2.1, spring, z - 0.21, z + 0.21, 0.03)
				mbox(beam, cx - ww / 2, cx + ww / 2, spring - 0.2, spring + 0.2, z - 0.25, z + 0.25, 0.03)
				for k in (1, 2, 3):
					x, y = arch_at(half - 0.2, spring, R - 0.2, math.radians(k * 45))
					mbar(beam, (cx, spring + 0.2, z), (cx + x, y, z), 0.12, 0.12)
			xg = s * (hw + ww - 0.25)
			mbox(beam, xg - 0.21, xg + 0.21, spring - 0.2, spring + 0.2, rz0, rz1, 0.03)
			for k in (1, 2, 3):
				z = rz0 + k * (rz1 - rz0) / 4
				mbox(beam, xg - 0.12, xg + 0.12, BF + 2.1, spring - 0.2, z - 0.1, z + 0.1)
			t = mk()
			barrel(t["Roof"], t["Beam"], half, spring, R, rz0, rz1, [(rz0 + 0.25, 0.2), (rzm, 0.2), (rz1 - 0.25, 0.2)], 0.14,
				(-0.1, 0.3), 3)
			Face(0, cx, 0).put(body, t)
		bx, bz = hw + ww + 2.6, Z0 + 4
		mbox(low, bx - 2.2, bx + 2.2, BF, BF + 3.2, bz - 2.2, bz + 2.2, 0.05)
		mbox(cap, bx - 2.4, bx + 2.4, BF + 3.2, BF + 3.6, bz - 2.4, bz + 2.4, 0.06)
		mbox(stone, bx - 2.32, bx + 2.32, BF, BF + 0.5, bz - 2.32, bz + 2.32, 0.05)
		sx, sz, sy = bx + 1.35, bz + 1.35, BF + 16.5
		G.lat(board, [(0.84, BF + 3.6), (0.84, sy - 0.4), (1.08, sy - 0.4), (1.08, sy + 0.2), (0.78, sy + 0.2),
			(0.78, sy - 0.3), (0.0, sy - 0.3)], 12, sx, -sz)
		y = BF + 5
		while y <= sy - 1:
			G.lat(gold, [(0.86, y - 0.15), (0.96, y - 0.15), (0.96, y + 0.15), (0.86, y + 0.15)], 12, sx, -sz)
			y += 2.8
	else:
		# A MARBLE HALL: piers with pilasters, an entablature with a gold frieze and cornice over the portico, a
		# pediment under blue tiles and gold raking boards, a flat-roofed wing each side, the round tower with gold
		# bands (the columns, the windows of the wings' fronts and the cone and domes are the game's)
		ez = Z0 - 2
		half = hw + 0.2
		white, stone, gold = body["Wall"], body["Stone"], body["Gold"]
		cy0, cy1 = top - 0.5, top - 0.15  # the side walls' cornice, under the eaves' line
		for s, F in sides:
			t = mk()
			wall(t["Wall"], -e, e, BF, top)
			lbox(t["Stone"], -e - 0.1, e + 0.1, BF, BF + 0.95, 0, 0.3, 0.05)
			lbox(t["Gold"], -e - 0.2, e + 0.2, cy0, cy1, 0, 0.35, 0.04)
			F.put(body, t)
		t = mk()
		for s in (-1, 1):
			lbox(t["Wall"], s * (hw - 1.7), s * hw, BF, top - 1.3, -T, 0)
			lbox(t["Stone"], s * (hw - 1.8), s * (hw + 0.3), BF, BF + 0.95, -T - 0.1, 0.3, 0.05)
			lbox(t["Beam"], s * (hw - 1.5), s * (hw - 0.2), BF + 0.95, top - 1.75, 0, 0.12, 0.04)
			lbox(t["Gold"], s * (hw - 1.6), s * (hw - 0.1), top - 1.75, top - 1.3, 0, 0.22, 0.04)
			lbox(t["Gold"], s * (hw - 1.6), s * (hw - 0.1), BF + 0.95, BF + 1.25, 0, 0.22, 0.04)
		front.put(body, t)
		t = mk()
		wall(t["Wall"], -hw, hw, BF, top)
		for s in (-1, 1):
			lbox(t["Stone"], s * 1.5, s * (hw + 0.3), BF, BF + 0.95, 0, 0.3, 0.05)
			window(t, s * 5.2, BF + 5.2, 1.7, 3.6, 0.85, 0.24, "Frame", "Glass")
		lbox(t["Gold"], -hw - 0.35, hw + 0.35, cy0, cy1, 0, 0.35, 0.04)
		plank_door(t, 1.1, 4.2, BF, "Frame")
		back.put(body, t)
		# the entablature over the portico: a gold frieze and a gold cornice round its three open sides
		mbox(white, -half, half, top - 1.3, top, ez, Z0 + T, 0.05)
		for y0, y1, g in ((top - 1.28, top - 0.93, 0.12), (top - 0.5, top - 0.2, 0.35)):
			mbox(gold, -half - g, half + g, y0, y1, ez - g, ez + 0.1, 0.03)
			for s in (-1, 1):
				mbox(gold, s * (half - 0.1), s * (half + g), y0, y1, ez + 0.1, Z0 + 0.1, 0.03)
		p, d, r = gable_roof(body, mk, 0, half, top, ez, Z1, rise, 0.6, barge="Gold")
		for F in (Face(0, 0, -ez), back):
			t = mk()
			gable_wall(t, half, top, p, d, r, rail=False, struts=False)
			F.put(body, t)
		# a wing each side: marble walls on a stone plinth, corner pilasters, a flat roof inside a gold cornice, an
		# arched window in its side and in its back
		ww, wh = 5.4, BF + 7
		for s in (-1, 1):
			xa, xb = s * hw, s * (hw + ww)
			lo, hi = sorted((xa, xb))
			ua, ub = (lo - 0.3, hi) if s < 0 else (lo, hi + 0.3)  # (the front's trims, on round the outer corner)
			box_room(body, mk, xa, xb, rz0, rz1, BF, wh, "Wall")
			mbox(stone, lo, hi, wh - 0.02, wh + 0.4, rz0, rz1)
			F0, F1, F2 = room_faces(xa, xb)
			for F, u0, u1, uw in ((F0, ua, ub, None), (F1, -re - 0.3, re + 0.3, 0.0), (F2, -ub, -ua, -(lo + hi) / 2)):
				t = mk()
				lbox(t["Stone"], u0, u1, BF, BF + 0.72, 0, 0.3, 0.05)
				lbox(t["Gold"], u0, u1, wh + 0.04, wh + 0.42, 0, 0.3, 0.04)
				if uw is not None:
					window(t, uw, BF + 3.7, 1.6, 3.2, 0.8, 0.22, "Frame", "Glass")
				if F is F1:
					for d2 in (-1, 1):
						lbox(t["Beam"], d2 * (re - 0.7), d2 * re, BF + 0.72, wh, 0, 0.14, 0.04)
				F.put(body, t)
		# the round tower (its cone roof is the kit's): a plinth ring, three gold bands
		bx, bz, th = hw + ww + 2.6, Z0 + 4, BF + 15.5
		G.lat(white, [(2.44, BF), (2.44, th)], 16, bx, -bz, cap_top=True)
		G.lat(stone, [(2.74, BF), (2.74, BF + 0.8), (2.46, BF + 0.94)], 16, bx, -bz)
		for y in (BF + 4.6, BF + 11.2):
			G.lat(gold, [(2.46, y - 0.3), (2.64, y - 0.22), (2.64, y + 0.22), (2.46, y + 0.3)], 16, bx, -bz)
		G.lat(gold, [(2.46, th - 0.55), (2.64, th - 0.47), (2.64, th + 0.02), (2.4, th + 0.02)], 16, bx, -bz)

	def rows(name, d):
		return [(f"{name}_{k}", d[k], (0, 0, 0), k, 35) for k in B_FIELDS if k not in alias and d[k].v]

	BREEDING[era] = {k: rows(B_NAMES[k].format(era), d) for k, d in parts.items()}
	return BREEDING[era]


def breeding(era, part="body"):
	G.COL.update(B_PAINT[era])
	return breeding_set(era)[part]


# ---------------------------------------------------------------- the Training Hall
# (the hall across the back of the yard and the tower at its right end. The yard, the shield, the glass, the columns,
# the galleries, the caps and the kit's pieces stay the module's)
T_FIELDS = ("Stone", "Wall", "Lower", "Beam", "Gold", "Board", "Roof", "Frame", "Glass", "Shutters")
TF, T_Z0, T_Z1 = 0.4, 17.4, 30.6  # the module's FLOOR, HZ and zb
T_LOOK = {1: (10.0, 6.2, 6.0), 2: (10.6, 6.8, 6.4), 3: (11.0, 7.4, 5.6), 4: (11.4, 6.0, 8.4), 5: (9.2, 9.5, 3.9)}  # hw, wallH, rise
T_TOWER = {1: (1.9, 1.4), 2: (2.3, 1.2), 3: (2.7, 0.6), 4: (2.7, 0.5), 5: (2.8, 0.3)}  # half its width, its gap to the hall
T_PAINT = {
	1: dict(Stone=rgb(150, 146, 138), Wall=rgb(196, 150, 98), Lower=rgb(164, 114, 68), Beam=rgb(110, 72, 42),
		Gold=rgb(236, 190, 70), Board=rgb(92, 60, 36), Roof=rgb(232, 190, 84), Frame=rgb(126, 84, 50),
		Glass=rgb(238, 158, 60), Shutters=rgb(176, 128, 78)),
	2: dict(Stone=rgb(214, 206, 188), Wall=rgb(244, 238, 224), Lower=rgb(226, 214, 190), Beam=rgb(70, 118, 224),
		Gold=rgb(236, 190, 70), Board=rgb(48, 86, 184), Roof=rgb(198, 70, 58), Frame=rgb(250, 246, 236),
		Glass=rgb(238, 158, 60), Shutters=rgb(176, 128, 78)),
	3: dict(Stone=rgb(132, 128, 122), Wall=rgb(240, 230, 206), Lower=rgb(192, 188, 178), Beam=rgb(112, 72, 44),
		Gold=rgb(236, 190, 70), Board=rgb(92, 60, 38), Roof=rgb(190, 62, 50), Frame=rgb(224, 218, 204),
		Glass=rgb(238, 158, 60), Shutters=rgb(176, 128, 78)),
	4: dict(Stone=rgb(86, 90, 100), Wall=rgb(84, 190, 180), Lower=rgb(72, 76, 88), Beam=rgb(52, 56, 64),
		Gold=rgb(224, 170, 70), Board=rgb(40, 44, 50), Roof=rgb(62, 96, 160), Frame=rgb(104, 110, 122),
		Glass=rgb(238, 158, 60), Shutters=rgb(176, 128, 78)),
	5: dict(Stone=rgb(214, 208, 196), Wall=rgb(242, 239, 232), Lower=rgb(214, 208, 196), Beam=rgb(228, 222, 210),
		Gold=rgb(236, 192, 76), Board=rgb(236, 192, 76), Roof=rgb(44, 84, 170), Frame=rgb(236, 192, 76),
		Glass=rgb(238, 158, 60), Shutters=rgb(176, 128, 78)),
}
T_NAMES = dict(body="TrainingBody{}", truss="TrainingTruss1", gable="TrainingGable1", lookout="TrainingLookout1",
	cabin="TrainingCabin1", tower="TrainingTower{}", tall="TrainingTall{}", roof="TrainingRoof{}",
	storey="TrainingStorey3", vault="TrainingVault5")
TRAINING = {}


def training_set(era):
	# every model of one era: the body, and the pieces a level switches (era 1's open truss, closed gable, lookout stand
	# and cabin; the tower of eras 2 to 4 at its two heights; era 3's roof on the stone hall, or its timber storey under
	# that roof; era 5's tiled roof, or its vault behind the pediment)
	if era in TRAINING:
		return TRAINING[era]
	hw, wall_h, rise = T_LOOK[era]
	Z0, Z1 = T_Z0, T_Z1
	ZC, top, e = (Z0 + Z1) / 2, TF + wall_h, (Z1 - Z0) / 2
	tr, gap = T_TOWER[era]
	tx, tz = -((hw + 3.2 if era == 5 else hw) + tr + gap), Z0 + 3.3

	paint = T_PAINT[era]
	alias, first = {}, {}
	for k in T_FIELDS:
		if paint[k] in first:
			alias[k] = first[paint[k]]
		else:
			first[paint[k]] = k

	def mk():
		own = {k: M() for k in T_FIELDS if k not in alias}
		return {k: own[alias.get(k, k)] for k in T_FIELDS}

	parts = {k: mk() for k in T_NAMES}
	body = parts["body"]
	beam, board = body["Beam"], body["Board"]
	front, back = Face(0, 0, -Z0), Face(math.pi, 0, -Z1)
	sides = ((1, Face(-math.pi / 2, hw, -ZC)), (-1, Face(math.pi / 2, -hw, -ZC)))  # (a side's u is s * (z - ZC))
	corners = ((-1, -1), (1, -1), (1, 1), (-1, 1))

	def round_tower(dst, slot, y1):
		# the round tower's shaft on its stone foot (inside the game's windows, which stand 0.03 off its wall)
		G.lat(dst[slot], [(tr + 0.02, TF + 0.9), (tr + 0.02, y1)], 16, tx, -tz, cap_top=True)
		G.lat(dst["Stone"], [(tr + 0.34, TF), (tr + 0.34, TF + 0.96), (tr + 0.04, TF + 1.12)], 16, tx, -tz)

	def hoop(m, y, h, r0, r1):
		G.lat(m, [(r0, y - h), (r1, y - h + 0.06), (r1, y + h - 0.06), (r0, y + h)], 16, tx, -tz)

	def spoke(dst, slot, a, w, v0, v1, r0, r1, ch=0.05):
		# a block on the round tower's wall, `a` round it
		t = mk()
		lbox(t[slot], -w, w, v0, v1, r0, r1, ch)
		Face(a, tx, -tz).put(dst, t)

	if era <= 2:
		# A TIMBER HALL: two posts on stone pads under a tie beam, its whole front open, its gable to the front; plank
		# walls under thatch at the hamlet, plaster on blue beams under tiles at the village
		sill = TF + 2.6
		rail = sill if era == 1 else TF + 5.75  # (the village's rail runs over its arched windows)
		for s in (-1, 1):
			x = s * (hw - 0.45)
			mbox(body["Stone"], x - 0.73, x + 0.73, TF, TF + 0.52, Z0 - 0.28, Z0 + 1.18, 0.1)
			mbox(beam, x - 0.47, x + 0.47, TF + 0.5, top - 0.76, Z0 - 0.02, Z0 + 0.92, 0.06)
			mbar(board, (s * (hw - 0.7), top - 3.0, Z0 + 0.45), (s * (hw - 3.1), top - 0.8, Z0 + 0.45), 0.45, 0.45)
		# (it ends inside the posts' outer faces and a hair under the eaves: a longer one stands out of the roof)
		mbox(beam, -hw + 0.05, hw - 0.05, top - 0.78, top - 0.02, Z0 - 0.03, Z0 + 0.93, 0.07)
		pitch, drop, ridge = gable_roof(body, mk, 0, hw, top, Z0, Z1, rise, 1, thatched=era == 1)
		for s, F in sides:
			t = mk()
			ua, ub = sorted((s * (Z0 + 0.8 - ZC), s * (Z1 - ZC)))
			if era == 1:
				planks(t["Lower"], ua, ub, TF, sill)
				planks(t["Wall"], ua, ub, sill, top)
			else:
				wall(t["Wall"], ua, ub, TF, top)
			lbox(t["Beam"], ua, ub, rail - 0.18, rail + 0.18, -0.06, 0.26, 0.05)
			timbers(t["Beam"], ua, ub, TF, top - 0.3, braces=era == 1)
			for u in bay_centres(ub - ua):
				u += (ua + ub) / 2
				if s == -1 and ZC - u < tz + tr + 1:
					continue  # (the tower stands in front of that bay)
				if era == 1 and abs(u - (ua + ub) / 2) < 3:
					window(t, u, TF + 4.5, 1.3, 1.6, 0.12, 0.2, "Frame", "Glass")
				elif era == 2:
					window(t, u, TF + 3.9, 1.3, 2.0, 0.6, 0.22, "Frame", "Glass")
			F.put(body, t)
		t = mk()
		if era == 1:
			for u0, u1 in ((-hw, -1.5), (1.5, hw)):
				planks(t["Lower"], u0, u1, TF, sill)
			lbox(t["Wall"], -1.5, 1.5, TF, sill, -T, 0)
			planks(t["Wall"], -hw, hw, sill, top)
		else:
			wall(t["Wall"], -hw, hw, TF, top)
		for u0, u1 in ((-hw, -1.5), (1.5, hw)):
			lbox(t["Beam"], u0, u1, rail - 0.18, rail + 0.18, -0.06, 0.26, 0.05)
		timbers(t["Beam"], -hw + 0.15, hw - 0.15, TF, top - 0.1, braces=False, gap=(-1.5, 1.5))
		plank_door(t, 1.2, 3.6, TF, "Beam" if era == 1 else "Board")
		for u in bay_centres(hw * 2 - 0.3):
			if 3 < abs(u) < 6.6:
				if era == 1:
					window(t, u, TF + 4.5, 1.4, 1.6, 0.12, 0.2, "Frame", "Glass")
				else:
					window(t, u, TF + 3.9, 1.4, 2.0, 0.6, 0.22, "Frame", "Glass")
		gable_wall(t, hw, top, pitch, drop, ridge)
		back.put(body, t)
		if era == 1:
			# the open truss of the first level
			t = mk()
			rafter_pair(t["Beam"], pitch, top - 0.45, ridge, drop, -0.3, 0.5, 0.5, 0.36)
			lbox(t["Beam"], -0.3, 0.3, top - 0.02, ridge - 0.67, -0.6, 0.0, 0.05)
			hc = hw - (rise * 0.5 + drop) / pitch
			lbox(t["Beam"], -hc, hc, top + rise * 0.5 - 0.23, top + rise * 0.5 + 0.23, -0.55, -0.05, 0.05)
			front.put(parts["truss"], t)
			# the plank gable that closes it (the shield hangs on it)
			t = mk()
			gable_wall(t, hw, top, pitch, drop, ridge)
			front.put(parts["gable"], t)
			# the lookout stand: four braced legs, a railed platform as high as the eaves, a ladder
			lk, P = parts["lookout"], top
			lk_plank = lk["Shutters"]
			for i, a in enumerate(corners):
				c = corners[(i + 1) % 4]
				ax, az, cx, cz = tx + a[0] * tr, tz + a[1] * tr, tx + c[0] * tr, tz + c[1] * tr
				mbox(lk["Beam"], ax - 0.24, ax + 0.24, TF, P - 0.18, az - 0.24, az + 0.24, 0.05)
				mbar(lk["Board"], (ax, TF + 0.5, az), (cx, P - 0.6, cz), 0.26, 0.26)
				mbar(lk["Board"], (cx, TF + 0.5, cz), (ax, P - 0.6, az), 0.26, 0.26)
				g = tr + 0.45
				p, q = (tx + a[0] * g, tz + a[1] * g), (tx + c[0] * g, tz + c[1] * g)
				mbox(lk["Beam"], p[0] - 0.16, p[0] + 0.16, P + 0.2, P + 1.72, p[1] - 0.16, p[1] + 0.16, 0.04)
				mbar(lk["Beam"], (p[0], P + 1.6, p[1]), (q[0], P + 1.6, q[1]), 0.25, 0.25)
				mbar(lk["Board"], (p[0], P + 0.9, p[1]), (q[0], P + 0.9, q[1]), 0.2, 0.2)
			mbox(lk_plank, tx - tr - 0.68, tx + tr + 0.68, P - 0.22, P + 0.22, tz - tr - 0.68, tz + tr + 0.68, 0.06)
			for k in (-0.45, 0.45):
				mbar(lk["Board"], (tx + k, TF, tz - tr - 2), (tx + k, P + 0.2, tz - tr - 0.7), 0.16, 0.16)
			for i in range(1, 7):
				f = i / 7
				y, z = TF + f * (P + 0.2 - TF), tz - tr - 2 + f * 1.3
				mbox(lk["Board"], tx - 0.45, tx + 0.45, y - 0.06, y + 0.06, z - 0.06, z + 0.06)
			# the cabin that makes it a tower: the legs carried on, a plank cabin on its own floor (its cap is the kit's)
			cb, P2 = parts["cabin"], P + 3.4
			for i, a in enumerate(corners):
				c = corners[(i + 1) % 4]
				ax, az, cx, cz = tx + a[0] * tr, tz + a[1] * tr, tx + c[0] * tr, tz + c[1] * tr
				mbox(cb["Beam"], ax - 0.24, ax + 0.24, P + 0.2, P2 - 0.18, az - 0.24, az + 0.24, 0.05)
				mbar(cb["Board"], (ax, P + 1.9, az), (cx, P2 - 0.3, cz), 0.26, 0.26)
				mbox(cb["Beam"], ax - 0.22, ax + 0.22, P2 + 0.2, P2 + 3.22, az - 0.22, az + 0.22, 0.04)
				for y in (P2 + 0.42, P2 + 3.0):
					mbar(cb["Beam"], (ax, y, az), (cx, y, cz), 0.24, 0.3)
			mbox(cb["Shutters"], tx - tr - 0.53, tx + tr + 0.53, P2 - 0.22, P2 + 0.22, tz - tr - 0.53, tz + tr + 0.53, 0.06)
			mbox(cb["Wall"], tx - tr + 0.1, tx + tr - 0.1, P2 + 0.2, P2 + 3.22, tz - tr + 0.1, tz + tr - 0.1)
		else:
			t = mk()
			gable_wall(t, hw, top, pitch, drop, ridge)
			front.put(body, t)
			# the watchtower at its two heights: cream boards between blue posts on a stone foot, bands, a board eave,
			# a cross brace in the foot bay of the two faces the yard sees
			for key, H in (("tower", TF + 11.2), ("tall", TF + 14.2)):
				tw, yG = parts[key], H - 3.2
				mbox(tw["Stone"], tx - tr - 0.28, tx + tr + 0.28, TF, TF + 0.93, tz - tr - 0.28, tz + tr + 0.28, 0.08)
				mbox(tw["Wall"], tx - tr - 0.02, tx + tr + 0.02, TF + 0.85, H, tz - tr - 0.02, tz + tr + 0.02)
				for a in corners:
					x, z = tx + a[0] * tr, tz + a[1] * tr
					mbox(tw["Beam"], x - 0.27, x + 0.27, TF + 0.9, H - 0.3, z - 0.27, z + 0.27, 0.05)
				y = TF + 3.6
				while y <= yG - 1 + 1e-6:
					mbox(tw["Beam"], tx - tr - 0.27, tx + tr + 0.27, y - 0.2, y + 0.2, tz - tr - 0.27, tz + tr + 0.27, 0.05)
					y += 3.3
				mbox(tw["Board"], tx - tr - 0.47, tx + tr + 0.47, H - 0.42, H + 0.02, tz - tr - 0.47, tz + tr + 0.47, 0.06)
				g, ya, yb = tr - 0.3, TF + 1.1, TF + 3.3
				for s in (-1, 1):
					zf, xs = tz - tr - 0.05, tx + tr + 0.05
					mbar(tw["Beam"], (tx - s * g, ya, zf), (tx + s * g, yb, zf), 0.3, 0.3)
					mbar(tw["Beam"], (xs, ya, tz - s * g), (xs, yb, tz + s * g), 0.3, 0.3)
	elif era == 3:
		# A STONE HALL: ONE great arch of two-tone voussoirs under a keystone between two square shoulders, a string
		# course; the round keep at its right end. Its roof is a model of its own (with the shoulders, which stand as
		# high as it does): at the era's last levels a half-timbered storey lifts it.
		ow, spring, R = hw - 2.9, TF + 3.4, 3.2
		stone, frame = body["Stone"], body["Frame"]
		cy0, cy1 = top - 0.85, top - 0.4  # the side walls' cornice, under the eaves' line
		zf = Z0 + 0.2  # the gable's face, and the storey's
		t = mk()
		arch_wall(t["Lower"], ow, hw, spring, R, TF, top, -0.8, 0.0)
		for i in range(13):
			big = i % 2 == 0
			ring_band(t["Frame" if big else "Stone"], ow, spring, R, -0.05, 0.9 if big else 0.8, -0.85,
				0.5 if big else 0.4, math.pi * i / 13 + 0.01, math.pi * (i + 1) / 13 - 0.01, 3)
		G.prism(t["Frame"], [(-0.45, spring + R - 0.35), (0.45, spring + R - 0.35), (0.65, top - 0.4), (-0.65, top - 0.4)],
			-0.85, 0.72)
		for s in (-1, 1):
			lbox(t["Frame"], s * (ow - 0.12), s * (ow + 1.05), spring - 0.3, spring + 0.1, -0.86, 0.56, 0.05)
			u0, u1 = sorted((s * (ow + 0.02), s * (hw - 1.4)))
			courses(t["Stone"], u0, u1, TF, TF + 0.8, -0.82, 0.18, 1, 1.4)
		lbox(t["Frame"], -hw + 1.4, hw - 1.4, top - 0.42, top - 0.02, 0, 0.35, 0.05)
		front.put(body, t)
		for s in (-1, 1):
			for i in range(7):
				long, y = i % 2 == 0, TF + 0.86 + i * 0.78
				mbox(frame, s * (hw - (1.0 if long else 0.65)), s * (hw + 0.12), y, y + 0.64, Z1 - (0.65 if long else 1.0),
					Z1 + 0.12, 0.06)
		for s, F in sides:
			t = mk()
			wall(t["Lower"], -e, e, TF, top)
			courses(t["Stone"], -e - 0.18, e + 0.18, TF, TF + 0.8, -0.05, 0.18, 1, 1.7)
			lbox(t["Frame"], -e - 0.3, e + 0.3, cy0, cy1, 0, 0.3, 0.05)
			for d in (-1, 1):
				if not (s == -1 and d == 1):  # (the keep stands in front of that one)
					window(t, d * 3.3, TF + 3.7, 1.4, 2.4, 0.7, 0.24, "Frame", "Glass")
			F.put(body, t)
		t = mk()
		wall(t["Lower"], -hw, hw, TF, top)
		for s in (-1, 1):
			u0, u1 = sorted((s * 1.3, s * (hw + 0.18)))
			courses(t["Stone"], u0, u1, TF, TF + 0.8, -0.05, 0.18, 1, 1.6)
			for u in (4.2, 7.8):
				window(t, s * u, TF + 3.7, 1.4, 2.4, 0.7, 0.24, "Frame", "Glass")
		lbox(t["Frame"], -hw - 0.3, hw + 0.3, cy0, cy1, 0, 0.3, 0.05)
		plank_door(t, 1.0, 3.6, TF, "Frame")
		back.put(body, t)

		def shoulders(dst, ph):
			# the two square shoulders of the arch: stone on a foot under a cap, the string course carried round
			for s in (-1, 1):
				x = s * (hw - 0.5)
				mbox(dst["Lower"], x - 1.03, x + 1.03, TF, ph, Z0 - 1.52, Z0 + 0.02, 0.06)
				mbox(dst["Stone"], x - 1.22, x + 1.22, TF, TF + 0.82, Z0 - 1.72, Z0 - 0.08, 0.08)
				mbox(dst["Frame"], x - 1.22, x + 1.22, ph - 0.02, ph + 0.32, Z0 - 1.72, Z0 - 0.08, 0.06)
				mbox(dst["Frame"], x - 1.12, x + 1.12, top - 0.42, top - 0.02, Z0 - 1.62, Z0 - 0.1, 0.05)

		# the roof on the stone hall (levels 21 to 28)
		rf = parts["roof"]
		p, d, r = gable_roof(rf, mk, 0, hw, top, zf, Z1, rise, 0.5)
		for F in (Face(0, 0, -zf), back):
			t = mk()
			gable_wall(t, hw, top, p, d, r)
			F.put(rf, t)
		shoulders(rf, top + 0.5)
		# the half-timbered upper storey of levels 29 and 30, under the same roof
		st = parts["storey"]
		y2, zc2, e2 = top + 3.4, (zf + Z1) / 2, (Z1 - zf) / 2
		mbox(st["Beam"], -hw - 0.14, hw + 0.14, top - 0.03, top + 0.44, zf - 0.14, Z1 + 0.14, 0.06)
		t = mk()
		bm = t["Beam"]
		wall(t["Wall"], -hw, hw, top + 0.4, y2, n0=-0.5)
		lbox(bm, -hw + 1.4, hw - 1.4, top + 0.4, top + 0.8, -0.06, 0.22, 0.05)
		lbox(bm, -hw + 1.4, hw - 1.4, y2 - 0.42, y2 - 0.02, -0.06, 0.24, 0.05)
		for u in (-hw + 1.7, -5.4, -1.9, 1.9, 5.4, hw - 1.7):  # (between the game's two windows and the shoulders)
			lbox(bm, u - 0.2, u + 0.2, top + 0.8, y2 - 0.42, -0.06, 0.22, 0.05)
		for s in (-1, 1):
			G.bar(bm, (s * 5.7, 0.06, top + 0.8), (s * (hw - 2.0), 0.06, y2 - 0.42), 0.2, 0.32)
		Face(0, 0, -zf).put(st, t)
		t = mk()
		wall(t["Wall"], -hw, hw, top + 0.4, y2, n0=-0.5)
		timbers(t["Beam"], -hw + 0.3, hw - 0.3, top + 0.4, y2 - 0.02)
		back.put(st, t)
		for s in (-1, 1):
			t = mk()
			wall(t["Wall"], -e2, e2, top + 0.4, y2, n0=-0.5)
			timbers(t["Beam"], -e2 + 0.3, e2 - 0.3, top + 0.4, y2 - 0.3)
			Face(-s * math.pi / 2, s * hw, -zc2).put(st, t)
			mbox(st["Beam"], s * (hw - 0.5), s * (hw + 0.1), top + 0.4, y2 - 0.3, Z1 - 0.5, Z1 + 0.1, 0.05)
		p, d, r = gable_roof(st, mk, 0, hw, y2, zf, Z1, rise, 0.5)
		for F in (Face(0, 0, -zf), back):
			t = mk()
			gable_wall(t, hw, y2, p, d, r)
			F.put(st, t)
		shoulders(st, y2 + 0.5)
		# the round keep at its two heights: courses of pale stone, a neck under its cone (the kit's); the taller one
		# wears a crown of battlements on corbels
		for key, H in (("tower", TF + 12.6), ("tall", TF + 16.2)):
			tw = parts[key]
			round_tower(tw, "Lower", H)
			y = TF + 5
			while y <= H - 2 + 1e-6:
				hoop(tw["Frame"], y, 0.18, tr, tr + 0.14)
				y += 4
			G.lat(tw["Lower"], [(tr - 0.46, H - 0.1), (tr - 0.46, H + 1.72)], 16, tx, -tz, cap_top=True)
			if key == "tall":
				G.lat(tw["Lower"], [(tr - 0.2, H - 0.78), (tr + 0.84, H - 0.78), (tr + 0.84, H + 0.38), (tr - 0.6, H + 0.38)],
					16, tx, -tz)
				for k in range(12):
					spoke(tw, "Frame", k * math.pi / 6, 0.25, H - 1.45, H - 0.75, tr - 0.05, tr + 0.65)
				for k in range(10):
					spoke(tw, "Lower", k * math.pi / 5, 0.48, H + 0.34, H + 1.25, tr + 0.18, tr + 0.8, 0.06)
	elif era == 4:
		# A STEEL AND GLASS VAULT (the glass is the game's): steel foot walls under a cap, riveted posts and rails, a
		# shingled barrel vault under ribs, a heavy two-tone ring between two riveted piers round the open front; the
		# riveted steel tower at its right end, whole or with its goo core open between ribs
		low, cap, stone, roof, gold = body["Lower"], body["Frame"], body["Stone"], body["Roof"], body["Gold"]
		wy = TF + 2.4  # the foot walls' top
		mid = (wy + top) / 2
		for s in (-1, 1):
			x = s * (hw - 0.3)
			mbox(low, s * (hw - T), s * hw, TF, wy, Z0, Z1)
			mbox(cap, x - 0.47, x + 0.47, wy, wy + 0.3, Z0, Z1 + 0.1, 0.04)
			for k in range(4):
				z = Z0 + 0.3 + k * (Z1 - Z0 - 0.6) / 3
				mbox(beam, x - 0.26, x + 0.26, wy + 0.3, top - 0.5, z - 0.26, z + 0.26, 0.04)
				for j in range(2):
					G.stud(beam, (s * (hw - 0.04), -z, wy + 1.1 + j * 1.5), (s, 0, 0), 0.1)
				G.stud(gold, (s * (hw + 0.01), -z, TF + 1.2), (s, 0, 0), 0.13)
			for k in range(3):
				z = Z0 + 0.3 + (k + 0.5) * (Z1 - Z0 - 0.6) / 3
				mbox(beam, x - 0.14, x + 0.14, wy + 0.3, top - 0.5, z - 0.09, z + 0.09)
			mbox(beam, x - 0.28, x + 0.28, top - 0.52, top + 0.02, Z0, Z1, 0.04)
			mbox(beam, x - 0.14, x + 0.14, mid - 0.13, mid + 0.13, Z0, Z1)
			# the front pier: riveted steel on a slate foot under a cap, a steel band
			px = s * (hw - 0.8)
			mbox(low, px - 1.13, px + 1.13, TF, top + 0.62, Z0 - 0.53, Z0 + 0.83, 0.05)
			mbox(cap, px - 1.32, px + 1.32, top + 0.58, top + 1.0, Z0 - 0.72, Z0 + 1.02, 0.06)
			mbox(stone, px - 1.32, px + 1.32, TF, TF + 0.72, Z0 - 0.72, Z0 + 1.02, 0.06)
			mbox(beam, px - 1.2, px + 1.2, TF + 2.75, TF + 3.05, Z0 - 0.6, Z0 + 0.9, 0.04)
			for dx in (-0.8, 0.8):
				for k in range(3):
					G.stud(gold, (px + dx, -(Z0 - 0.53), TF + 1.6 + k * 2.2), (0, 1, 0), 0.16)
		# the back wall: steel under a cap, glazing bars and the lunette's fan
		mbox(low, -hw, hw, TF, wy, Z1 - T, Z1)
		mbox(cap, -hw - 0.1, hw + 0.1, wy, wy + 0.3, Z1 - 0.75, Z1 + 0.15, 0.04)
		zg = Z1 - 0.2
		for k in range(1, 8):
			x = -hw + k * hw / 4
			mbox(beam, x - 0.13, x + 0.13, wy + 0.3, top - 0.25, zg - 0.18, zg + 0.18)
			G.stud(gold, (x, -(Z1 + 0.01), TF + 1.2), (0, -1, 0), 0.13)
		mbox(beam, -hw, hw, mid - 0.13, mid + 0.13, zg - 0.16, zg + 0.16)
		mbox(beam, -hw, hw, top - 0.3, top + 0.2, zg - 0.22, zg + 0.22, 0.04)
		for k in range(1, 8):
			x, y = arch_at(hw - 0.3, top, rise - 0.3, math.radians(k * 22.5))
			mbar(beam, (0, top + 0.2, zg), (x, y, zg), 0.14, 0.14)
		barrel(roof, beam, hw, top, rise, Z0, Z1, [(Z0 + 0.2 + k * (Z1 - Z0 - 0.4) / 3, 0.22) for k in range(4)], 0.2,
			(-0.25, 0.45), 7)
		# the front: the ring (steel and pale steel, a brass stud on every pale one), the riveted transom, the
		# lunette's bars and its inner ring
		t = mk()
		for i in range(15):
			big = i % 2 == 0
			ring_band(t["Frame" if big else "Lower"], hw, top, rise, -0.25, 0.72 if big else 0.62, -0.45,
				0.72 if big else 0.62, math.pi * i / 15 + 0.008, math.pi * (i + 1) / 15 - 0.008, 3)
			if big:
				u, v = arch_at(hw, top, rise, math.pi * (i + 0.5) / 15, 0.25)
				G.stud(t["Gold"], (u, 0.72, v), (0, 1, 0), 0.17)
		lbox(t["Beam"], -(hw - 1.9), hw - 1.9, top - 0.15, top + 0.35, -0.4, 0.2, 0.04)
		for k in range(-9, 10):
			G.stud(t["Beam"], (k * 0.95, 0.2, top + 0.1), (0, 1, 0), 0.1)
		for k in range(1, 8):
			u, v = arch_at(hw - 0.5, top + 0.3, rise - 0.5, math.radians(k * 22.5))
			G.bar(t["Beam"], (0, 0, top + 0.3), (u, 0, v), 0.14, 0.14)
		ring_band(t["Beam"], (hw - 0.5) * 0.64, top + 0.3, (rise - 0.5) * 0.64, -0.09, 0.09, -0.09, 0.09)
		front.put(body, t)
		H, y0 = TF + 16.2, TF + 9.6
		for key, solid in (("tower", H), ("tall", y0)):
			tw = parts[key]
			round_tower(tw, "Lower", solid)
			y = TF + 3.2
			while y <= solid + 1e-6:
				hoop(tw["Beam"], y, 0.2, tr, tr + 0.16)
				for k in range(8):
					a = k * math.pi / 4 + 0.3
					G.stud(tw["Gold"], (tx - (tr + 0.14) * math.sin(a), -tz + (tr + 0.14) * math.cos(a), y),
						(-math.sin(a), math.cos(a), 0), 0.13)
				y += 3.2
			if key == "tall":
				ym = (y0 + H - 1) / 2
				for k in range(6):
					spoke(tw, "Beam", k * math.pi / 3 + 0.5, 0.25, y0 - 0.1, H - 0.98, tr - 0.4, tr + 0.1, 0.04)
				hoop(tw["Beam"], ym, 0.23, tr - 0.5, tr - 0.2)
				G.lat(tw["Lower"], [(tr + 0.16, H - 1.03), (tr + 0.16, H + 0.03)], 16, tx, -tz, cap_bottom=True, cap_top=True)
	else:
		# A MARBLE HALL: piers with pilasters, an entablature with a gold frieze and cornice over the portico, a
		# pediment with gold raking boards, an arcade wing each side under a flat roof inside a gold cornice, the round
		# tower with gold bands. Its roof is a model of its own: blue tiles, or at the last levels a blue vault with
		# gold ribs behind the pediment (the columns, the balustrades, the glass and the domes are the game's)
		ez = Z0 - 2
		half = hw + 0.2
		white, stone, gold = body["Wall"], body["Stone"], body["Gold"]
		cy0, cy1 = top - 0.4, top - 0.03  # the side walls' cornice, under the eaves' line
		for s, F in sides:
			t = mk()
			wall(t["Wall"], -e, e, TF, top)
			lbox(t["Stone"], -e - 0.1, e + 0.1, TF, TF + 0.95, 0, 0.3, 0.05)
			lbox(t["Gold"], -e - 0.2, e + 0.2, cy0, cy1, 0, 0.36, 0.04)
			F.put(body, t)
		t = mk()
		for s in (-1, 1):
			lbox(t["Wall"], s * (hw - 1.7), s * hw, TF, top - 1.3, -T, 0)
			lbox(t["Stone"], s * (hw - 1.8), s * hw, TF, TF + 0.95, -T - 0.1, 0.3, 0.05)
			lbox(t["Beam"], s * (hw - 1.5), s * (hw - 0.2), TF + 0.95, top - 1.75, 0, 0.12, 0.04)
			lbox(t["Gold"], s * (hw - 1.6), s * (hw - 0.1), top - 1.75, top - 1.3, 0, 0.22, 0.04)
			lbox(t["Gold"], s * (hw - 1.6), s * (hw - 0.1), TF + 0.95, TF + 1.25, 0, 0.22, 0.04)
		front.put(body, t)
		t = mk()
		wall(t["Wall"], -hw, hw, TF, top)
		for s in (-1, 1):
			lbox(t["Stone"], s * 1.5, s * (hw + 0.3), TF, TF + 0.95, 0, 0.3, 0.05)
			for u in (3.4, 6.7):
				window(t, s * u, TF + 4.9, 1.5, 3.2, 0.75, 0.24, "Frame", "Glass")
		lbox(t["Gold"], -hw - 0.35, hw + 0.35, cy0, cy1, 0, 0.36, 0.04)
		plank_door(t, 1.1, 4.2, TF, "Frame")
		back.put(body, t)
		# the entablature over the portico: a gold frieze and a gold cornice round its three open sides
		mbox(white, -half, half, top - 1.3, top, ez, Z0 + T, 0.05)
		for y0, y1, g in ((top - 1.28, top - 0.93, 0.12), (top - 0.5, top - 0.2, 0.35)):
			mbox(gold, -half - g, half + g, y0, y1, ez - g, ez + 0.1, 0.03)
			for s in (-1, 1):
				mbox(gold, s * (half - 0.1), s * (half + g), y0, y1, ez + 0.1, Z0 + 0.1, 0.03)
		# an arcade wing each side: an arch in a gold ring on its front, pilasters and panels on its end wall
		ww, wt = 3.2, TF + 6.4
		wzb = Z1 - 1.5  # the wing's back
		zm, hs = (Z0 + wzb - 0.6) / 2, (wzb - 0.6 - Z0) / 2  # its end wall, from the front to its back wall
		bay = (hs * 2 - 0.6) / 3
		for s in (-1, 1):
			cx, xe = s * (hw + ww / 2), s * (hw + ww)
			t = mk()
			arch_wall(t["Wall"], 1.0, ww / 2, TF + 3.3, 1.2, TF, wt)
			ring_band(t["Gold"], 1.0, TF + 3.3, 1.2, 0.0, 0.3, -0.16, 0.26)
			for d in (-1, 1):
				lbox(t["Stone"], d * 1.0, d * (ww / 2 + 0.1), TF, TF + 0.85, -T, 0.22, 0.04)
				lbox(t["Gold"], d * 0.94, d * (ww / 2), TF + 3.0, TF + 3.3, -T - 0.02, 0.2, 0.03)
			Face(0, cx, -Z0).put(body, t)
			t = mk()
			wall(t["Wall"], -hs, hs, TF, wt)
			lbox(t["Stone"], -hs - 0.1, hs + 0.1, TF, TF + 0.85, 0, 0.26, 0.04)
			lbox(t["Gold"], -hs - 0.2, hs + 0.2, wt - 0.38, wt - 0.02, 0, 0.3, 0.04)
			for k in range(4):
				u = -hs + 0.3 + k * bay
				lbox(t["Beam"], u - 0.3, u + 0.3, TF + 0.85, wt - 0.38, 0, 0.16, 0.04)
			for k in range(3):
				u = -hs + 0.3 + (k + 0.5) * bay
				lbox(t["Stone"], u - bay / 2 + 0.6, u + bay / 2 - 0.6, TF + 1.5, wt - 1.5, 0, 0.07)
				lbox(t["Gold"], u - bay / 2 + 0.5, u + bay / 2 - 0.5, wt - 1.5, wt - 1.3, 0, 0.14, 0.03)
			Face(-s * math.pi / 2, xe, -zm).put(body, t)
			t = mk()
			wall(t["Wall"], -ww / 2, ww / 2, TF, wt)
			lbox(t["Stone"], -ww / 2, ww / 2, TF, TF + 0.85, 0, 0.26, 0.04)
			Face(math.pi, cx, -wzb).put(body, t)
			lo, hi = sorted((s * hw, s * (hw + ww + 0.22)))
			mbox(stone, lo, hi, wt - 0.02, wt + 0.32, Z0 - 0.33, wzb + 0.13, 0.04)
			mbox(gold, cx - ww / 2 - 0.25, cx + ww / 2 + 0.25, wt, wt + 0.3, Z0 - 0.57, Z0 - 0.13, 0.03)
		# the round tower (its gallery, columns and dome are the game's): a stone foot, four gold bands
		H = TF + 17
		round_tower(body, "Wall", H)
		for y in (TF + 1.3, TF + 6.4, TF + 12, H - 0.5):
			hoop(gold, y, 0.2, tr, tr + 0.15)
		# the tiled roof behind the pediment (levels 41 to 47)
		rf = parts["roof"]
		p, d, r = gable_roof(rf, mk, 0, half, top, ez, Z1, rise, 0.6, barge="Gold")
		for F in (Face(0, 0, -ez), back):
			t = mk()
			gable_wall(t, half, top, p, d, r, rail=False, struts=False)
			F.put(rf, t)
		# the vault of levels 48 to 50: the pediment keeps a short tiled roof, a stone deck carries a blue vault with
		# gold ribs behind it (its glass ends are the game's)
		vt = parts["vault"]
		hv, R, za = hw - 1.5, rise + 1.7, Z0 + 1.4
		p, d, r = gable_roof(vt, mk, 0, half, top, ez, za, rise, 0.6, barge="Gold")
		for F in (Face(0, 0, -ez), Face(math.pi, 0, -za)):
			t = mk()
			gable_wall(t, half, top, p, d, r, rail=False, struts=False)
			F.put(vt, t)
		mbox(vt["Stone"], -hw - 0.03, hw + 0.03, top - 0.03, top + 0.28, za - 0.03, Z1 + 0.03, 0.04)
		barrel(vt["Roof"], vt["Gold"], hv, top + 0.25, R, za + 0.5, Z1 - 0.1,
			[(za + 0.7 + k * (Z1 - za - 1.0) / 3, 0.2) for k in range(4)], 0.2, (-0.1, 0.4), 5)

	def rows(name, d):
		return [(f"{name}_{k}", d[k], (0, 0, 0), k, 35) for k in T_FIELDS if k not in alias and d[k].v]

	TRAINING[era] = {k: rows(T_NAMES[k].format(era), d) for k, d in parts.items()}
	return TRAINING[era]


def training(era, part="body"):
	G.COL.update(T_PAINT[era])
	return training_set(era)[part]


ELEVATIONS = {"front": (0, 1, 0.02), "left": (1, 0, 0.02), "back": (0, -1, 0.02), "right": (-1, 0, 0.02)}
BODIES = [("GranaryBody1", granary1)] + [(f"GranaryBody{e}", lambda e=e: granary(e)) for e in (2, 3, 4, 5)]
BODIES += [(f"KitchenBody{e}", lambda e=e: kitchen(e)) for e in (1, 2, 3, 4, 5)]
BODIES += [(f"Kitchen{p.capitalize()}1", lambda p=p: kitchen(1, p)) for p in ("truss", "gable", "stack")]
BODIES += [(f"GardenBody{e}", lambda e=e: garden(e)) for e in (1, 2, 3, 4, 5)]
BODIES += [(f"Garden{p.capitalize()}1", lambda p=p: garden(1, p)) for p in ("truss", "gable", "lean")]
BODIES += [(f"Garden{p.capitalize()}3", lambda p=p: garden(3, p)) for p in ("roof", "storey")]
BODIES += [(f"BreedingBody{e}", lambda e=e: breeding(e)) for e in (1, 2, 3, 4, 5)]
BODIES += [(f"Breeding{p.capitalize()}1", lambda p=p: breeding(1, p)) for p in ("truss", "gable", "lean", "chimney")]
BODIES += [("BreedingWing2", lambda: breeding(2, "wing"))]
BODIES += [(f"Breeding{p.capitalize()}3", lambda p=p: breeding(3, p)) for p in ("roof", "storey")]
BODIES += [(f"TrainingBody{e}", lambda e=e: training(e)) for e in (1, 2, 3, 4, 5)]
BODIES += [(f"Training{p.capitalize()}1", lambda p=p: training(1, p)) for p in ("truss", "gable", "lookout", "cabin")]
BODIES += [(f"Training{p.capitalize()}{e}", lambda p=p, e=e: training(e, p)) for e in (2, 3, 4) for p in ("tower", "tall")]
BODIES += [(f"Training{p.capitalize()}3", lambda p=p: training(3, p)) for p in ("roof", "storey")]
BODIES += [(f"Training{p.capitalize()}5", lambda p=p: training(5, p)) for p in ("roof", "vault")]
# (LANDMARK_BODIES=GranaryBody2,GranaryBody3 in the environment builds only those)
if os.environ.get("LANDMARK_BODIES"):
	BODIES = [b for b in BODIES if b[0] in os.environ["LANDMARK_BODIES"].split(",")]
# the body's own picture from the front right, as the concept sheet shows it
for name, _ in BODIES:
	G.FRONT[name] = (-0.75, 1.0, 0.45)

G.build(BODIES, views={name: ELEVATIONS for name, _ in BODIES}, merge=True)

# the kit rows of what was built, for src/shared/ConfigMeshyKit.luau (a new piece gets `mesh = 0`; the upload fills it)
with open(G.OUT + "pieces.json", encoding="utf-8") as fh:
	built = json.load(fh)
for name, _ in BODIES:
	for obj, info in built[name]["objects"].items():
		size, at = (", ".join(f"{v:g}" for v in info[k]) for k in ("size_studs_xyz", "centre_studs_xyz"))
		print(f'ROW\t\t{obj} = {{ {{ mesh = 0, tex = "", size = {{ {size} }}, at = {{ {at} }} }} }},')
