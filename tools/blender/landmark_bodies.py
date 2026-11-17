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
		for k, src in t.items():
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


def window(t, uc, vc, w, h, rise=0.32, fw=0.24):
	# An arched window of four panes in a timber frame that goes through the wall, a pane on each face. The wall is
	# not cut: the game's own wall (the collision) stands inside the model's and would show in the hole.
	v0, top = vc - h / 2, vc + h / 2
	spring = top - rise
	arcp = [(uc + x, z) for x, z in seg(w, spring, rise)]
	fr = t["Timber"]
	for n0, n1 in ((0.0, 0.06), (-T - 0.06, -T)):
		G.prism(t["Pane"], [(uc - w / 2, v0), (uc + w / 2, v0)] + arcp, n0, n1)
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


ELEVATIONS = {"front": (0, 1, 0.02), "left": (1, 0, 0.02), "back": (0, -1, 0.02), "right": (-1, 0, 0.02)}
BODIES = [("GranaryBody1", granary1)]
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
