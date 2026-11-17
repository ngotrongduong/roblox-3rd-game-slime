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


def tiled(m, axis, eave, top, e0, e1, rows, thick, lip=0.13):
	# One slope of tiles from `eave` up to `top`: (x, y) of the module with the ridge along z (`axis` "z"), or (z, y)
	# with the ridge along x ("x"); e0..e1 along the ridge. A slab `thick` deep, its top on the roof's line as the
	# module's is, under `rows` courses that each stand `lip` proud at their foot.
	(ep, ey), (tp, ty) = eave, top
	run = math.hypot(tp - ep, ty - ey)
	dp, dy = (tp - ep) / run, (ty - ey) / run
	np, ny = (-dy, dp) if dp > 0 else (dy, -dp)  # the slope's normal, the one that points up

	def at(a, nn, e):
		p, y = ep + dp * a + np * nn, ey + dy * a + ny * nn
		return (p, -e, y) if axis == "z" else (e, -p, y)

	G.sweep(m, [[at(0, -thick, e), at(0, 0, e), at(run, 0, e), at(run, -thick, e)] for e in (e0, e1)])
	for k in range(rows):
		a0, a1 = run * k / rows - (0.15 if k == 0 else 0.0), run * (k + 1) / rows + 0.03
		foot = -thick if k == 0 else 0.0  # (the eave's course is as thick as the roof)
		G.sweep(m, [[at(a0, foot, e), at(a0, lip, e), at(a1, 0.015, e), at(a1, -0.02, e)] for e in (e0 - 0.05, e1 + 0.05)])


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


ELEVATIONS = {"front": (0, 1, 0.02), "left": (1, 0, 0.02), "back": (0, -1, 0.02), "right": (-1, 0, 0.02)}
BODIES = [("GranaryBody1", granary1)] + [(f"GranaryBody{e}", lambda e=e: granary(e)) for e in (2, 3, 4, 5)]
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
