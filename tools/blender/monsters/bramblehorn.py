# Bramblehorn (BOSS, wave 10): a big mossy boar with gold spiked tusks, a clover crest with a glowing gem, wooden bark
# bands, white and blue flowers, a glowing amber core on its back, dark hooves with gold tips and a leafy tail.
# Painting: reference/goo-lineage-web/assets/enemy-green-boar.png (1254 px, a 3/4 front view from above, head low).
# Measured from it (px): whole x 64..1191, y 17..1226; head x 430..1000, y 640..1100; tusks to y 1050; back bands
# x 490..720; back core x 610..850, y 130..290; tail x 60..330, y 20..250; hooves down to y 1226. Built LEVEL, facing -Y,
# head forward and slightly low, in px units (B frame). Inferred: the right/back sides of the torso, the rear legs and
# their bark cuffs (one rear hoof shows), the underside, the third band's far end, which side the side core is on.
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
from common import Frame, Piece, eye, leaf_broad, on_surface, sq, two_tone
from mathutils import Vector

SPEC = dict(name="Bramblehorn", painting="enemy-green-boar.png", kind="boss", height=11.0, budget="up to 4000",
	cam=(-10, 16))
S = 0.0096
fr0 = Frame(S, 0, 0, 0.0)


def B(x, y, z):
	return Vector((x * S, y * S, z * S))


def L(v):
	return v * S


def palette(P):
	P.add(moss="#5E8E1E", moss_light="#88BA28", moss_dark="#3E6A16", cream="#F0E2B8", bark="#90522A", bark_dark="#5E381A",
		bark_light="#AE7442", amber="#F29A12", core="#FFD22E", gold="#FFC428", hoof="#2B2010", snout="#D07C88",
		ear_in="#D07C88", blue="#4AA0F0", white="#FAF6E8", yellow="#F8CC24", clover="#3EAE3C", clover_light="#80D840",
		leaf="#54A220", leaf_light="#94D22C", leaf_dark="#2E7A22", eye="#F2A820", dark="#241208", glint="#FFFFFF",
		plate="#62AA2E")


def build(P):
	pieces = []
	# ---- Body: mossy torso, cream chest fur, bark bands, glowing cores, spikes, flowers and leaves
	body = Piece("Body", (0, 0, 0), "Root. Heavy breathing (scale Y 1.02 at 0.6 Hz), stomp dip 0.3 stud per step, rear-up lean on the charge wind-up; origin on the ground under the middle.")
	tc, tr = B(0, 250, 570), (L(400), L(580), L(330))
	TSQ = 2.4

	def mottle(c, n):  # mossy fur: patches of light moss, dark moss and leaf green (a hash of the face position), cream underneath
		if n[2] < -0.5:
			return "cream"
		return "moss_light" if n[2] > 0.7 else ("moss_dark" if n[2] < -0.1 else "moss")

	body.sphere(tc, tr, mottle, seg=14, rings=8, fn=sq(tr, TSQ))

	def top(y):  # z of the torso's top line at y (px)
		d = (y - 250) / 580
		return 570 + 330 * max(1 - abs(d) ** TSQ, 0.01) ** (1 / TSQ)

	def width(y):
		d = (y - 250) / 580
		return 400 * max(1 - abs(d) ** TSQ, 0.01) ** (1 / TSQ)

	for i, y in enumerate((40, 265, 500)):  # the three bark bands over the back
		pts = []
		for k in range(9):
			a = math.radians(-78 + k * 19.5)
			pts.append(B(width(y) * math.sin(a) * 1.05, y, 570 + (top(y) - 570) * math.cos(a) * 1.06))
		body.tube(pts, [L(44)] * 9, "bark" if i != 1 else "bark_dark", seg=6, caps=(True, True))
	cp = B(0, 385, top(385) + 10)  # the glowing core on the back, in a bark ring
	body.dome(cp - B(0, 0, 25), (0, 0, 1), L(150), L(60), "amber", seg=10)
	body.dome(cp, (0, 0, 1), L(92), L(80), "core", seg=8)
	ring = [cp + B(175 * math.cos(2 * math.pi * k / 9), 175 * math.sin(2 * math.pi * k / 9), -20) for k in range(10)]
	body.tube(ring, [L(30)] * 10, "bark", seg=5, caps=(True, True))
	sp, sn = Vector((-tr[0] * 0.93, tc[1] + L(40), tc[2] + L(70))), Vector((-1, 0, 0))  # the side core (the painting's left flank)
	body.dome(sp, tuple(sn), L(105), L(55), "amber", seg=8)
	body.dome(sp + sn * L(25), tuple(sn), L(60), L(60), "core", seg=6)
	for y in (-30, 140, 330, 520, 680):  # gold spikes along the spine
		z0 = top(y) - 12
		body.cone(B(0, y, z0), B(0, y + 30, z0 + 165), L(40), "gold", seg=5)
	for sx in (1, -1):  # shoulder and hip spikes
		for y, z in ((-60, 780), (620, 700)):
			p = B(sx * width(y) * 0.85, y, z)
			body.cone(p, p + B(sx * 95, 10, 90), L(38), "gold", seg=5)
	for x, y, r in ((130, 60, 90), (-150, 180, 80), (230, 380, 85), (-110, 560, 80), (60, 450, 95), (-250, 330, 85)):  # flowers: white daisies, blue forget-me-nots
		z0 = top(y) * 0.98 - (abs(x) / 400) ** 2 * 120
		body.dome(B(x, y, z0), (x * 0.002, 0, 1), L(r), L(26), "white", seg=6, smooth=False)
		body.dome(B(x, y, z0 + 10), (x * 0.002, 0, 1), L(r * 0.38), L(30), "yellow", seg=5, smooth=False)
	for x, y in ((-60, 250), (160, 220), (-210, 80), (80, 640), (-250, 420), (300, 600), (-80, 130), (200, 520), (-190, 600), (30, 330)):
		z0 = top(y) * 0.98 - (abs(x) / 400) ** 2 * 120
		body.dome(B(x, y, z0), (x * 0.002, 0, 1), L(42), L(22), "blue", seg=5, smooth=False)
	for x, y, ang in ((60, 150, 30), (-120, 300, 150), (200, 450, 80), (-60, 520, 200), (140, 20, 330), (-230, 160, 110), (260, 280, 20), (-150, 640, 250),
		(-20, 80, 100), (110, 330, 200), (-200, 450, 20), (20, 600, 310), (-250, 300, 60), (230, 150, 140), (-100, 400, 270), (180, 560, 220)):  # leaf clusters over the back
		z0 = top(y) - (abs(x) / 400) ** 2 * 140
		a = math.radians(ang)
		body.leaf(B(x, y, z0), (math.cos(a), math.sin(a), -0.05), (0, 0, 1), L(260), L(140), two_tone("leaf_light" if ang % 20 else "leaf", "leaf_dark", (0, 0, 1)), K=2, bend=L(-12), wfn=leaf_broad)
	for row, z in enumerate((480, 600, 720)):  # the leaf ruff over the shoulders and chest (seen head-on, like the painting)
		for k, x in enumerate((-300, -180, -60, 60, 180, 300) if row != 1 else (-240, -120, 0, 120, 240)):
			dx, dz = x / 400.0, (z - 570) / 330.0
			q = max(1 - dx * dx - dz * dz, 0.02) ** 0.5
			p = B(x * 0.97, 250 - 580 * q * 0.98, z)
			n = Vector((dx / 400, -q / 580, dz / 330)).normalized()
			down = Vector((0, 0, -1)) - n * (-n[2])
			body.leaf(p + n * L(8), tuple(down.normalized()), tuple(n), L(250), L(170), two_tone(("leaf_light", "leaf", "plate")[(k + row) % 3], "leaf_dark", tuple(n)), K=2, bend=L(-10), wfn=leaf_broad)
	for sx in (1, -1):  # the leafy fur shingles down both flanks (the painting's flanks are covered in leaves)
		for k, (y, z) in enumerate(((20, 520), (200, 470), (380, 520), (560, 480), (110, 360), (300, 340), (480, 360))):
			dy, dz = (y - 250) / 580, (z - 570) / 330
			q = max(1 - dy * dy - dz * dz, 0.02) ** 0.5
			p = B(sx * 400 * q * 0.98, y, z)
			n = Vector((sx * q / 400, dy / 580, dz / 330)).normalized()
			down = Vector((0, 0, -1)) - n * (-n[2])
			body.leaf(p + n * L(6), tuple(down.normalized()), tuple(n), L(230), L(150), two_tone("leaf_light" if k % 2 else "leaf", "leaf_dark", tuple(n)), K=3, bend=L(-10), wfn=leaf_broad)
	pieces.append(body)

	# ---- Head: low, wide, cream-and-moss with the clover crest, amber eyes, pink snout and gold tusks
	hj = B(0, -330, 400)
	head = Piece("Head", hj, "Look/turn about the neck (yaw +-30 deg); head-butt: dip 20 deg and thrust 1.5 studs; roar: lift 12 deg.")
	hc, hr = B(0, -620, 360), (L(275), L(300), L(235))
	head.sphere(hc, hr, lambda c, n: "moss" if n[2] > 0.35 else "cream", seg=12, rings=8, fn=sq(hr, 2.3))
	snc, snr = B(0, -915, 275), (L(135), L(110), L(95))
	head.sphere(snc, snr, "snout", seg=10, rings=6)
	for sx in (1, -1):
		p, n = on_surface(fr0, snc, snr, sx * 52, -300, 2.0)
		head.dome(p, n, L(20), L(8), "dark", seg=5)
		p, n = on_surface(fr0, hc, hr, sx * 150, -440, 2.3)
		eye(head, p + n * L(5), n, L(58), iris="eye", up=(0, 0, 1), tall=0.9, tilt=-sx * 22, seg=10)
		# tusk: a gold tapering horn curling up and out, with two spikes and a leaf cuff at the base
		path = [B(sx * 190, -750, 210), B(sx * 300, -855, 235), B(sx * 365, -920, 370), B(sx * 345, -945, 540), B(sx * 290, -930, 700)]
		head.tube(path, [L(88), L(76), L(60), L(38), L(8)], "gold", seg=6, caps=(False, True))
		for t, ci in ((0.5, 1), (0.6, 2)):
			q = path[ci] + (path[ci + 1] - path[ci]) * t
			head.cone(q, q + B(sx * 80, -45, 30), L(24), "gold", seg=4)
		head.lathe(path[0] + B(0, 20, -5), [(L(88), 0), (L(70), L(70))], "leaf", seg=6, axis=tuple(path[1] - path[0]), cap=True)
	cp2, cn2 = on_surface(fr0, hc, hr, 0, -520, 2.3)  # the clover crest on the brow
	head.dome(cp2, cn2, L(175), L(60), "plate", seg=6, smooth=False)
	up2 = Vector((0, 0, 1)) - cn2 * cn2.z
	up2.normalize()
	sd2 = cn2.cross(up2)
	for i in range(4):
		a = math.pi / 4 + i * math.pi / 2
		d = up2 * math.cos(a) + sd2 * math.sin(a)
		head.dome(cp2 + cn2 * L(26) + d * L(58), tuple(cn2), L(60), L(34), "clover", seg=6, smooth=False)
	head.dome(cp2 + cn2 * L(34), tuple(cn2), L(36), L(46), "core", seg=6, smooth=False)
	for sx in (1, -1):  # leaf mane round the cheeks and brow
		for k, (x, z, ang) in enumerate(((235, 470, 30), (255, 360, -20), (205, 560, 70))):
			p, n = on_surface(fr0, hc, hr, sx * x, -z, 2.3)
			head.leaf(p, (sx * math.cos(math.radians(ang)), -0.2, math.sin(math.radians(ang))), tuple(n), L(210), L(110), two_tone("leaf_light" if k % 2 else "leaf", "leaf_dark", tuple(n)), K=3, bend=L(-8), wfn=leaf_broad)
	pieces.append(head)

	# ---- Ears: a moss leaf with a pink inside; EarL is the monster's left
	for name, sx in (("EarL", 1), ("EarR", -1)):
		j = B(sx * 215, -500, 550)
		ear = Piece(name, j, "Flick: rotate about the root +-15 deg at 2.5 Hz, pin back when it charges.")
		d = Vector((sx * 0.45, 0.1, 1.0)).normalized()
		n = Vector((sx * 0.5, -1.0, 0.1))
		ear.leaf(j, tuple(d), tuple(n), L(270), L(190), two_tone("moss_light", "leaf_dark", tuple(n)), K=3, bend=L(15), wfn=leaf_broad)
		ear.dome(j + d * L(60) + n.normalized() * L(16), tuple(n), L(75), L(24), "ear_in", seg=6, up=tuple(d), sx=1.5)
		pieces.append(ear)

	# ---- Legs: a thick cream-furred leg, a bark cuff, a dark hoof with two gold tips and a leaf; flowers on the front ones
	def leg(name, sx, y, hip_x, reach, flowers):
		j = B(sx * hip_x, y, 540)
		lg = Piece(name, j, "Swing +-22 deg about the hip, diagonal pairs together (walk 1.0 Hz); stamp (+-30 deg) on the slam.")
		kn, an = B(sx * (hip_x + 25), y - reach * 0.3, 300), B(sx * (hip_x + 30), y - reach * 0.5, 150)
		lg.tube([j, kn, an], [L(135), L(115), L(100)], lambda c, n: "moss_light" if c[2] > 400 * S else "moss", seg=7, caps=(False, False))
		lg.lathe(an + B(0, 0, 25), [(L(132), 0), (L(132), L(60))], "bark", seg=7, cap=True)
		hp = B(sx * (hip_x + 30), y - reach * 0.5, 0)
		lg.lathe(hp, [(L(128), 0), (L(118), L(150))], "hoof", seg=7, cap=True)
		for i in (-1, 1):
			base = hp + B(i * 52, -105, 60)
			lg.cone(base, base + B(i * 6, -70, -45), L(40), "gold", seg=5)
		lg.leaf(an + B(0, -60, 70), (0.1 * sx, -0.4, -1.0), (sx * 0.4, -1.0, 0.0), L(210), L(130), two_tone("leaf_light", "leaf_dark", (0, -1, 0)), K=3, bend=L(-8), wfn=leaf_broad)
		if flowers:
			lg.dome(an + B(sx * 90, -80, 90), (sx * 0.5, -1, 0.2), L(48), L(18), "blue", seg=5, smooth=False)
			lg.dome(an + B(sx * 60, -110, 110), (sx * 0.4, -1, 0.3), L(34), L(16), "white", seg=5, smooth=False)
		return lg

	pieces.append(leg("LegFL", 1, -200, 270, 100, True))
	pieces.append(leg("LegFR", -1, -200, 270, 100, True))
	pieces.append(leg("LegBL", 1, 560, 280, 0, False))
	pieces.append(leg("LegBR", -1, 560, 280, 0, False))

	# ---- Tail: a mossy stem in a bark wrap ending in a leaf bunch with two flowers
	tj = B(0, 800, 650)
	tail = Piece("Tail", tj, "Swish: rotate about the root +-25 deg at 1.4 Hz with a travelling wave (the leaves lag).")
	path = [tj, B(25, 900, 760), B(-10, 985, 900), B(-90, 1030, 990)]
	tail.tube(path, [L(52), L(44), L(36), L(30)], "moss", seg=5, caps=(False, True))
	tail.lathe(path[1] + B(0, 0, -20), [(L(60), 0), (L(60), L(70))], "bark", seg=6, axis=tuple(path[2] - path[1]), cap=True)
	end = path[-1]
	for tip, wd in ((B(-250, 1040, 1100), 150), (B(-120, 1120, 1130), 160), (B(-60, 1080, 850), 130), (B(-230, 1000, 900), 120)):
		a = tip - end
		tail.leaf(end, tuple(a), (0, -0.3, 1.0), a.length, L(wd), two_tone("leaf_light", "leaf_dark", (0, -0.3, 1.0)), K=3, bend=L(15), wfn=leaf_broad)
	tail.dome(end + B(-60, -30, 70), (0, -1, 0.3), L(60), L(22), "white", seg=5, smooth=False)
	tail.dome(end + B(-110, -20, 20), (0, -1, 0.2), L(40), L(20), "blue", seg=5, smooth=False)
	pieces.append(tail)
	return pieces


if __name__ == "__main__":
	C.run(__file__, sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "r1")
