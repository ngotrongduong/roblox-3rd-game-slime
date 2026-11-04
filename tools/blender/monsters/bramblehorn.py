# Bramblehorn (BOSS, wave 10): a huge moss-covered wild BOAR: low heavy body with a hunched shoulder hump higher than the
# hips, short thick legs with dark hooves and gold tips, a long wedge head sloping down to a flat dark snout disc, small
# amber eyes under a heavy brow, short pointed ears, a clover crest with a glowing gem and two gold horn spikes on the
# forehead, short thick gold tusks rising from the lower jaw, wooden bark armour bands, a glowing amber core on the back,
# white and blue flowers, leaf clusters everywhere and a leafy tail.
# Painting: reference/goo-lineage-web/assets/enemy-green-boar.png (1254 px, a 3/4 front view from above, head low,
# charging at the viewer). Round 9 rebuild after the owner saw it read as an ox in game: the cream face mask, pink cow
# muzzle, long sideways horns and tall boxy body on stilts are gone.
# Measured from the painting (px): head wedge x 430..1000, y 640..1100; snout disc x 590..750, y 920..1010 (dark pink-brown);
# tusks from the lower jaw, curving up and out, y 750..1050; crest plate with a 4-leaf clover and an amber gem on the
# forehead; ears short and pink inside; back bands x 490..720; back core x 610..850, y 130..290; tail x 60..330, y 20..250.
# Built LEVEL, facing -Y, in STUDS (Blender metres); the painting's 3/4 charge is only approximated by the fit camera.
# Inferred: the far side of everything, the rump and the rear legs (one rear hoof shows), the belly, the third band's far end.
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
import numpy as np
from common import Piece, eye, leaf_broad, sq, two_tone
from mathutils import Vector

SPEC = dict(name="Bramblehorn", painting="enemy-green-boar.png", kind="boss", height=11.0, budget="up to 4000",
	az_range=range(-30, 11, 10), el_range=range(8, 31, 8))
TSQ = 2.2


def V(x, y, z):
	return Vector((x, y, z))


def palette(P):
	P.add(moss="#62881E", moss_light="#86B428", moss_dark="#4A6A18", cream="#E8D4A8", bark="#8C5428", bark_dark="#5A3416",
		bark_light="#A87040", amber="#F89A10", core="#FFD02A", gold="#FBB721", hoof="#2B1E14", snout="#5C3E2C",
		ear_in="#C4706E", blue="#4AA0F0", white="#FAF6E8", yellow="#F8CC24", clover="#3EAE3C", clover_light="#80D840",
		leaf="#4E9A24", leaf_light="#8CCB2C", leaf_dark="#2E6A1C", eye="#F2A820", dark="#241208", glint="#FFFFFF",
		plate="#62AA2E")


# ---- the torso: a shoulder hump (high, heavy) and a lower rump, two superellipsoids that overlap
SHO = dict(c=V(0, -1.0, 6.2), r=(3.7, 3.4, 3.5))
RUMP = dict(c=V(0, 3.1, 5.3), r=(3.2, 3.4, 2.7))


def se_point(e, d):
	"""The point and outward normal of superellipsoid `e` in the direction of unit vector d."""
	u = np.array([d[0], d[1], d[2]], float)
	u /= np.linalg.norm(u)
	k = (np.abs(u) ** TSQ).sum() ** (1 / TSQ)
	loc = u / k * np.array(e["r"])
	g = np.sign(loc) * (np.abs(loc / np.array(e["r"])) ** (TSQ - 1)) / np.array(e["r"])
	n = Vector((float(g[0]), float(g[1]), float(g[2]))).normalized()
	return e["c"] + Vector((float(loc[0]), float(loc[1]), float(loc[2]))), n


def top_z(x, y):
	"""Height of the torso's upper surface at (x, y) (the higher of the two masses), or None outside."""
	best = None
	for e in (SHO, RUMP):
		ux, uy = (x - e["c"].x) / e["r"][0], (y - e["c"].y) / e["r"][1]
		q = 1 - abs(ux) ** TSQ - abs(uy) ** TSQ
		if q > 0.02:
			z = e["c"].z + e["r"][2] * q ** (1 / TSQ)
			best = z if best is None else max(best, z)
	return best


def rotx(v, deg):
	a = math.radians(deg)
	return V(v.x, v.y * math.cos(a) - v.z * math.sin(a), v.y * math.sin(a) + v.z * math.cos(a))


HEAD_C, HEAD_R, HEAD_PITCH = V(0, -5.3, 4.3), (2.2, 2.85, 2.05), 22.0


def hp(u, push=0.0):
	"""A point on the (pitched) boar-head ellipsoid in local direction u, and its normal."""
	u = V(*u).normalized()
	loc = V(u.x * HEAD_R[0], u.y * HEAD_R[1], u.z * HEAD_R[2])
	n = V(u.x / HEAD_R[0], u.y / HEAD_R[1], u.z / HEAD_R[2]).normalized()
	n = rotx(n, HEAD_PITCH)
	return HEAD_C + rotx(loc, HEAD_PITCH) + n * push, n


def slope_axis(n):
	"""Down-slope direction along a surface with outward normal n (outward horizontal on the very top)."""
	d = V(0, 0, -1) - n * (-n.z)
	if d.length < 0.25:
		d = V(n.x, n.y, 0) if (n.x or n.y) else V(0, 1, 0)
	return d.normalized()


def build(P):
	pieces = []
	# ================================================================ Body
	body = Piece("Body", (0, 0, 0), "Root. Heavy breathing (scale Y 1.02 at 0.6 Hz), stomp dip 0.3 stud per step, rear-up lean on the charge wind-up; origin on the ground under the middle.")

	def skin(c, n):
		if n[2] < -0.65:
			return "cream"
		if n[2] > 0.78:
			return "moss_light"
		return "moss" if n[2] > 0.25 else "moss_dark"

	body.sphere(SHO["c"], SHO["r"], skin, seg=14, rings=8, fn=sq(SHO["r"], TSQ))
	body.sphere(RUMP["c"], RUMP["r"], skin, seg=12, rings=7, fn=sq(RUMP["r"], TSQ))

	# the three bark armour bands over the hump and the back
	for i, y in enumerate((-2.5, -0.3, 2.7)):
		e = SHO if (top_z(0, y) == SHO["c"].z + SHO["r"][2] * max(1 - abs((y - SHO["c"].y) / SHO["r"][1]) ** TSQ, 0.02) ** (1 / TSQ)) else RUMP
		ry = (y - e["c"].y) / e["r"][1]
		q = max(1 - abs(ry) ** TSQ, 0.02) ** (1 / TSQ)
		pts = [V(e["r"][0] * q * math.sin(a) * 1.04, y, e["c"].z + e["r"][2] * q * math.cos(a) * 1.04) for a in [math.radians(-80 + k * 20) for k in range(9)]]
		body.tube(pts, [0.42] * 9, "bark" if i != 1 else "bark_dark", seg=6, caps=(True, True))
	# the glowing core on the back in a bark ring
	cy = 1.1
	cz = top_z(0, cy)
	body.dome(V(0, cy, cz - 0.2), (0, 0, 1), 1.45, 0.6, "amber", seg=10)
	body.dome(V(0, cy, cz), (0, 0, 1), 0.9, 0.8, "core", seg=8)
	ring = [V(1.85 * math.cos(2 * math.pi * k / 9), cy + 1.85 * math.sin(2 * math.pi * k / 9), (top_z(1.85 * math.cos(2 * math.pi * k / 9), cy + 1.85 * math.sin(2 * math.pi * k / 9)) or cz) - 0.1) for k in range(10)]
	body.tube(ring, [0.3] * 10, "bark", seg=5, caps=(True, True))
	# the side core on the monster's right flank (the painting's left)
	sp, sn = se_point(RUMP, (-1, 0.1, 0.12))
	body.dome(sp, tuple(sn), 1.0, 0.5, "amber", seg=8)
	body.dome(sp + sn * 0.25, tuple(sn), 0.6, 0.6, "core", seg=6)
	# gold spikes down the spine and on the shoulders and hips
	for y in (-2.9, -1.2, 0.0, 2.6, 4.2, 5.4):
		z0 = top_z(0, y) - 0.15
		body.cone(V(0, y, z0), V(0, y + 0.3, z0 + 1.55), 0.38, "gold", seg=5)
	for sx in (1, -1):
		for e, d in ((SHO, (sx * 0.85, -0.2, 0.5)), (SHO, (sx * 0.95, 0.35, 0.25)), (RUMP, (sx * 0.85, 0.1, 0.55)), (RUMP, (sx * 0.9, 0.6, 0.2))):
			p, n = se_point(e, d)
			body.cone(p - n * 0.1, p + n * 1.0, 0.34, "gold", seg=4)
	# leaf shingles smothering the hump, the back and the flanks (a bumpy silhouette)
	cols = ("leaf_light", "leaf", "plate", "leaf_light", "moss_light")
	k = 0
	for e, rows, naz in ((SHO, (74, 52, 30, 8), 8), (RUMP, (62, 38, 14), 7)):
		for ri, el in enumerate(rows):
			for j in range(naz):
				ph = (j + (0.5 if ri % 2 else 0)) * 2 * math.pi / naz
				d = (math.cos(math.radians(el)) * math.cos(ph), math.cos(math.radians(el)) * math.sin(ph), math.sin(math.radians(el)))
				p, n = se_point(e, d)
				if p.y < -3.6 and p.z < 7.2:
					continue  # the neck: the head sits here
				if abs(p.x) < 1.9 and abs(p.y - 1.1) < 2.1 and p.z > 8.0:
					continue  # keep the glowing core clear
				k += 1
				ln = 2.1 if el > 40 else 1.8
				body.leaf(p + n * 0.1, tuple(slope_axis(n)), tuple(n), ln, 1.4, two_tone(cols[k % 5], "leaf_dark", tuple(n)), K=2, bend=-0.12, wfn=leaf_broad)
	# moss clumps: small domes for lumps
	for x, y in ((-1.6, -2.6), (1.7, -2.2), (0.4, -3.2), (-2.3, 0.2), (2.4, 0.6), (-1.4, 3.6), (1.6, 3.9), (0.2, 5.1)):
		z0 = top_z(x, y) or 6
		body.dome(V(x, y, z0 - 0.15), (x * 0.12, 0, 1), 0.85, 0.5, "moss_light" if int(x * 10) % 2 else "leaf", seg=5, smooth=False)
	# flowers: white daisies and blue forget-me-nots
	for x, y, r in ((1.0, -2.2, 0.95), (-1.9, -1.0, 0.9), (2.4, 1.6, 0.9), (-0.7, 4.4, 0.85), (1.9, 3.6, 0.8), (-2.5, 2.2, 0.85)):
		z0 = (top_z(x, y) or 6.0) - 0.1 - (abs(x) / 3.7) ** 2 * 0.6
		body.dome(V(x, y, z0), (x * 0.1, 0, 1), r, 0.3, "white", seg=6, smooth=False)
		body.dome(V(x, y, z0 + 0.1), (x * 0.1, 0, 1), r * 0.4, 0.34, "yellow", seg=5, smooth=False)
	for x, y in ((-0.6, -1.9), (1.6, -0.9), (-2.1, -2.3), (0.5, 3.2), (-1.8, 3.9), (2.6, 3.0), (-0.9, 0.3), (2.2, -1.8)):
		z0 = (top_z(x, y) or 6.0) - 0.1 - (abs(x) / 3.7) ** 2 * 0.6
		body.dome(V(x, y, z0), (x * 0.1, 0, 1), 0.46, 0.26, "blue", seg=5, smooth=False)
	pieces.append(body)

	# ================================================================ Head: long wedge sloping to a flat dark snout disc
	hj = V(0, -3.7, 5.3)
	head = Piece("Head", hj, "Look/turn about the neck (yaw +-30 deg); head-butt: dip 20 deg and thrust 1.5 studs; roar: lift 12 deg.")
	head.sphere(HEAD_C, HEAD_R, lambda c, n: "moss" if n[2] > -0.1 else "moss_dark", seg=11, rings=7, rot=(HEAD_PITCH, 0, 0))
	# the muzzle: a tapering bridge and the flat dark snout disc at its tip
	mc = V(0, -7.3, 3.55)
	head.sphere(mc, (1.15, 1.25, 0.95), "moss", seg=10, rings=6, rot=(HEAD_PITCH, 0, 0))
	axis = V(0, -0.92, -0.38)
	disc_c = V(0, -8.35, 3.1)
	head.lathe(disc_c, [(1.05, 0.0), (1.05, 0.45)], "snout", seg=10, axis=tuple(axis), cap=True)
	for sx in (1, -1):  # nostrils
		head.dome(disc_c + axis * 0.5 + V(sx * 0.4, 0, 0.05), tuple(axis), 0.26, 0.12, "dark", seg=6)
	# small eyes under a heavy brow
	for sx in (1, -1):
		p, n = hp((sx * 0.62, -0.62, 0.34), 0.06)
		eye(head, p, n, 0.36, iris="eye", up=(0, 0, 1), tall=0.9, tilt=-sx * 24, seg=10)
		a, an = hp((sx * 0.22, -0.88, 0.46), 0.1)
		b, bn = hp((sx * 0.86, -0.38, 0.52), 0.1)
		head.tube([a, b], [0.3, 0.38], "moss_dark", seg=5, caps=(True, True))
		# cheek tufts and moss leaves round the face
		for u, ang in (((sx * 0.9, -0.2, 0.1), 20), ((sx * 0.5, 0.2, 0.8), 60)):
			p2, n2 = hp(u, 0.05)
			head.leaf(p2, (sx * math.cos(math.radians(ang)), -0.3, math.sin(math.radians(ang))), tuple(n2), 1.25, 0.8, two_tone("leaf_light", "leaf_dark", tuple(n2)), K=2, bend=-0.1, wfn=leaf_broad)
		# gold horn spike on the forehead beside the crest
		hs, hn = hp((sx * 0.42, -0.3, 0.93), 0.0)
		head.cone(hs - hn * 0.1, hs + hn * 1.0 + V(sx * 0.2, 0, 0), 0.26, "gold", seg=5)
		# the tusk: short, thick, rising from the lower jaw near the snout, curving up and back
		path = [V(sx * 0.85, -7.2, 2.3), V(sx * 1.4, -7.55, 2.7), V(sx * 1.7, -7.3, 3.7), V(sx * 1.5, -6.6, 4.6)]
		head.tube(path, [0.72, 0.64, 0.44, 0.06], "gold", seg=6, caps=(False, True))
		head.lathe(path[0] + V(0, 0.15, -0.05), [(0.9, 0), (0.74, 0.55)], "leaf", seg=6, axis=tuple(path[1] - path[0]), cap=True)
		q = path[1] + (path[2] - path[1]) * 0.45
		head.cone(q, q + V(sx * 0.5, -0.3, 0.2), 0.16, "gold", seg=4)
	# the clover crest with its gem on the brow
	cp2, cn2 = hp((0, -0.3, 0.97), 0.0)
	head.dome(cp2, tuple(cn2), 1.15, 0.4, "plate", seg=6, smooth=False)
	up2 = V(0, 0, 1) - cn2 * cn2.z
	up2.normalize()
	sd2 = cn2.cross(up2)
	for i in range(4):
		a = math.pi / 4 + i * math.pi / 2
		d = up2 * math.cos(a) + sd2 * math.sin(a)
		head.dome(cp2 + cn2 * 0.2 + d * 0.42, tuple(cn2), 0.46, 0.28, "clover", seg=6, smooth=False)
	head.dome(cp2 + cn2 * 0.3, tuple(cn2), 0.28, 0.34, "core", seg=6, smooth=False)
	# a few cream whiskers under the chin (the painting's pale beard) and a leaf mane at the back of the head
	for sx in (-0.5, 0.0, 0.5):
		p, n = hp((sx, -0.5, -0.78), 0.0)
		head.leaf(p, (0, -0.4, -1.0), tuple(n), 1.3, 0.8, "cream", K=2, bend=0.05, wfn=leaf_broad)
	for sx in (1, -1):
		for u in ((sx * 0.7, 0.65, 0.5), (sx * 0.3, 0.8, 0.6)):
			p, n = hp(u, 0.05)
			head.leaf(p, (sx * 0.5, 0.3, 0.8), tuple(n), 1.4, 0.9, two_tone("leaf", "leaf_dark", tuple(n)), K=2, bend=-0.1, wfn=leaf_broad)
	pieces.append(head)

	# ================================================================ Ears: short, pointed, pink inside
	for name, sx in (("EarL", 1), ("EarR", -1)):
		j, _ = hp((sx * 0.8, 0.1, 0.62), 0.0)
		ear = Piece(name, j, "Flick: rotate about the root +-15 deg at 2.5 Hz, pin back when it charges.")
		d = V(sx * 0.55, 0.15, 1.0).normalized()
		n = V(sx * 0.4, -1.0, 0.2)
		ear.leaf(j, tuple(d), tuple(n), 1.5, 1.05, two_tone("moss_light", "leaf_dark", tuple(n)), K=2, bend=0.2, wfn=leaf_broad)
		ear.dome(j + d * 0.4 + n.normalized() * 0.1, tuple(n), 0.5, 0.16, "ear_in", seg=6, up=tuple(d), sx=1.4)
		pieces.append(ear)

	# ================================================================ Legs: short, thick, moss-furred, bark cuff, dark hoof with gold tips
	def leg(name, sx, y, hip_x, flowers):
		j = V(sx * hip_x, y, 4.3)
		lg = Piece(name, j, "Swing +-22 deg about the hip, diagonal pairs together (walk 1.0 Hz); stamp (+-30 deg) on the slam.")
		kn, an = V(sx * (hip_x + 0.2), y - 0.2, 2.5), V(sx * (hip_x + 0.25), y - 0.45, 1.25)
		lg.tube([j, kn, an], [1.4, 1.2, 1.05], lambda c, n: "moss_dark" if c[2] < 2.2 else "moss", seg=6, caps=(False, False))
		lg.lathe(an + V(0, 0, 0.1), [(1.2, 0), (1.2, 0.5)], "bark", seg=7, cap=True)
		hp_ = V(sx * (hip_x + 0.25), y - 0.5, 0.0)
		lg.lathe(hp_, [(1.15, 0), (1.05, 1.35)], "hoof", seg=7, cap=True)
		for i in (-1, 1):
			base = hp_ + V(i * 0.5, -0.95, 0.6)
			lg.cone(base, base + V(i * 0.05, -0.65, -0.45), 0.38, "gold", seg=5)
		for t, (dz, wd) in enumerate(((3.5, 1.6), (2.4, 1.5))):  # leaf plates on the front of the leg
			lg.leaf(V(sx * (hip_x + 0.1 * t), y - 0.2 - 0.12 * t - 1.0, dz), (sx * 0.1, -0.25, -1.0), (sx * 0.2, -1.0, 0.3), 1.35, wd, two_tone(("leaf_light", "leaf", "plate")[t], "leaf_dark", (0, -1, 0)), K=2, bend=-0.1, wfn=leaf_broad)
		if flowers:
			lg.dome(an + V(sx * 0.9, -0.8, 0.9), (sx * 0.5, -1, 0.2), 0.46, 0.2, "blue", seg=5, smooth=False)
			lg.dome(an + V(sx * 0.6, -1.1, 1.1), (sx * 0.4, -1, 0.3), 0.34, 0.16, "white", seg=5, smooth=False)
		return lg

	pieces.append(leg("LegFL", 1, -2.7, 2.5, True))
	pieces.append(leg("LegFR", -1, -2.7, 2.5, True))
	pieces.append(leg("LegBL", 1, 3.9, 2.4, False))
	pieces.append(leg("LegBR", -1, 3.9, 2.4, False))

	# ================================================================ Tail: a mossy stem in a bark wrap ending in a leaf bunch with two flowers
	tj = V(0, 6.2, 6.3)
	tail = Piece("Tail", tj, "Swish: rotate about the root +-25 deg at 1.4 Hz with a travelling wave (the leaves lag).")
	path = [tj, V(0.25, 7.0, 7.1), V(-0.1, 7.5, 8.2), V(-0.8, 7.7, 9.0)]
	tail.tube(path, [0.55, 0.46, 0.38, 0.32], "moss", seg=5, caps=(False, True))
	tail.lathe(path[1] + V(0, 0, -0.15), [(0.62, 0), (0.62, 0.55)], "bark", seg=6, axis=tuple(path[2] - path[1]), cap=True)
	end = path[-1]
	for tip, wd in ((V(-2.4, 8.0, 9.6), 1.3), (V(-1.2, 8.7, 9.9), 1.35), (V(-0.6, 8.3, 7.7), 1.1), (V(-2.1, 7.7, 8.0), 1.0)):
		a = tip - end
		tail.leaf(end, tuple(a), (0, -0.3, 1.0), a.length, wd, two_tone("leaf_light", "leaf_dark", (0, -0.3, 1.0)), K=2, bend=0.15, wfn=leaf_broad)
	tail.dome(end + V(-0.6, -0.3, 0.6), (0, -1, 0.3), 0.55, 0.2, "white", seg=5, smooth=False)
	tail.dome(end + V(-1.0, -0.2, 0.2), (0, -1, 0.2), 0.36, 0.18, "blue", seg=5, smooth=False)
	pieces.append(tail)
	return pieces


if __name__ == "__main__":
	C.run(__file__, "r9")
