# Clover Snail (elite, armoured): a teal-green slime foot and head with gold spikes and two eye stalks with glossy
# balls, carrying a big green leaf-and-clover spiral shell with gold spikes and white flowers.
# Painting: reference/goo-lineage-web/assets/enemy-green-snail.png (1254 px, one 3/4 view from above-front-right).
# Measured from it (px): shell x 140..1015, y 36..830 (about 870 x 790); head/foot x 300..1000, y 700..1190; eye-ball
# diameter ~110; gold trim along the shell lip. Built level, facing -Y, in px units (B frame like the bee), spiral
# on the monster's RIGHT side (-X: the painting shows its right flank). Inferred: the shell's far side, the foot's
# underside and tail, the shell's depth (a 600 px thick ovoid), how the spiral leaves overlap on the hidden side.
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
from common import Frame, Piece, eye, leaf_broad, on_surface, sq, two_tone
from mathutils import Vector

SPEC = dict(name="CloverSnail", painting="enemy-green-snail.png", kind="elite", height=5.0, budget="up to 2500",
	cam=(-46, 28))
S = 0.0050
fr0 = Frame(S, 0, 0, 0.0)


def B(x, y, z):
	return Vector((x * S, y * S, z * S))


def L(v):
	return v * S


def palette(P):
	P.add(teal="#25CC8E", teal_light="#80F0B8", teal_dark="#12A070", ball="#74F0AC", eye_y="#F5DC5A", iris="#8A3A10",
		dark="#241006", cream="#F8F0CA", gold="#F0B42C", gold_trim="#D4B870", shell_deep="#0F6C46", shell_dark="#1E8E3E",
		leaf_mid="#3CB02A", leaf_light="#8CDC2A", leaf_lime="#BCEE3C", clover="#38CC3C", clover_light="#94F04C",
		white="#FFFFFF", flower_c="#F2B81C", dew="#B8F0D0")


def build(P):
	pieces = []
	# ---- Body: the slime foot and head
	body = Piece("Body", (0, 0, 0), "Slither: squash-stretch along Y at 1 Hz (length x1.08 / height x0.94) and ripple the foot lobes; origin on the ground under the foot.")
	foot_c, foot_r = B(0, 130, 75), (L(250), L(440), L(75))
	body.sphere(foot_c, foot_r, "teal", seg=14, rings=8, fn=sq(foot_r, 2.6))
	for x, y, r in ((-190, 480, 90), (170, 520, 80), (-60, 600, 70), (230, 300, 70)):  # the puddle lobes at the tail end
		body.sphere(B(x, y, 55), (L(r), L(r), L(55)), "teal_light", seg=7, rings=4)
	hc, hr = B(0, -300, 215), (L(215), L(205), L(190))
	body.sphere(hc, hr, "teal", seg=12, rings=8, fn=sq(hr, 2.4))
	for sx in (1, -1):
		p, n = on_surface(fr0, hc, hr, sx * 115, -245, 2.4)
		eye(body, p + n * L(4), n, L(66), sclera="eye_y", iris="iris", pupil="dark", up=(0, 0, 1), tall=1.0, tilt=-sx * 14, seg=10)
		lid = Vector(p) + n * L(14) + Vector((0, 0, L(40)))  # the heavy lid over the upper half
		body.dome(lid, tuple(n), L(78), L(26), "teal_dark", seg=8, up=(0, 0, 1), sx=0.75)
	mp, mn = on_surface(fr0, hc, hr, 0, -118, 2.4)
	body.dome(Vector(mp) + Vector(mn) * L(4), tuple(mn), L(115), L(18), "cream", seg=10, up=(0, 0, 1), sx=0.5)
	for x, z in ((-130, -330), (130, -330), (0, -395), (-175, -200), (175, -200)):  # gold spikes on the head
		p, n = on_surface(fr0, hc, hr, x, z, 2.4)
		body.cone(Vector(p) - Vector(n) * L(12), Vector(p) + Vector(n) * L(95), L(26), "gold", seg=5)
	pieces.append(body)

	# ---- Eye stalks: two jointed stalks with glossy balls
	def stalk(name, sx, r_ball):
		root = B(sx * 110, -255, 360)
		a = Piece(name, root, "Sway about the root (+-14 deg, 1.1 Hz, out of phase); lean toward the target when it spots one.")
		path = [root, B(sx * 140, -258, 450), B(sx * 185, -255, 545)]
		a.tube(path, [L(32), L(27), L(24)], "teal", seg=6, caps=(False, False))
		a.sphere(B(sx * 192, -255, 545 + r_ball * 0.7), L(r_ball), "ball", seg=9, rings=6)
		return a

	pieces.append(stalk("StalkL", 1, 68))
	pieces.append(stalk("StalkR", -1, 62))

	# ---- Shell: a dark ovoid wrapped in a spiral of big leaves, clovers, white flowers and gold spikes
	cj = B(0, 150, 110)
	shell = Piece("Shell", cj, "Wobble about the joint (+-5 deg roll, 1 Hz) with the slither; rattle on a hit. Origin where it rests on the foot.")
	sc, sr = B(0, 150, 460), (L(300), L(415), L(410))

	def spiral_band(c, n):
		"""The painting's whorl: coloured bands wound round the swirl centre (y 190, z 440 px) on the right (-X) flank,
		with a dark groove between the turns; the left flank and the hidden side are plain dark shell."""
		if n[0] > -0.15:
			return "shell_deep"
		dy, dz = c[1] / S - 190, c[2] / S - 440
		r = math.hypot(dy, dz)
		if r < 75:
			return "shell_deep"
		u = r / 135.0 - math.atan2(-dz, -dy) / (2 * math.pi)  # one turn per 135 px, the front of the snail is -y
		f, k = u % 1.0, int(math.floor(u))
		if f > 0.82:
			return "shell_deep"  # the groove
		return ("leaf_light", "leaf_mid", "shell_dark")[k % 3]

	shell.sphere(sc, sr, lambda c, n: "shell_dark" if n[0] < -0.15 else "shell_deep", seg=16, rings=10)

	def side(y, z, push=0.0):
		"""A point on the monster's right (-X) flank of the shell ovoid at (y, z) px, and its outward normal."""
		dy, dz = (y * S - sc[1]) / sr[1], (z * S - sc[2]) / sr[2]
		q = max(1 - dy * dy - dz * dz, 1e-3)
		dx = -math.sqrt(q)
		p = Vector((sc[0] + dx * sr[0], sc[1] + dy * sr[1], sc[2] + dz * sr[2]))
		n = Vector((dx / sr[0], dy / sr[1], dz / sr[2])).normalized()
		return p + n * L(push), n

	cols = ["leaf_light", "leaf_mid", "leaf_lime", "leaf_mid", "leaf_light", "leaf_mid", "leaf_lime", "leaf_light", "leaf_mid", "leaf_lime", "leaf_mid", "leaf_light"]
	for k in range(4):  # the big leaves of the outer whorl (upper right and top of the painting's shell)
		ph = math.radians(-35 + k * 38)
		rho = 300
		ln = 330 + k * 12
		tang0 = Vector((0, -math.sin(ph), math.cos(ph)))
		p, n = side(190 + rho * math.cos(ph) - tang0.y * ln * 0.5, 440 + rho * math.sin(ph) - tang0.z * ln * 0.5, 45)  # leaf start (pushed out: the 14-segment ovoid's facets sag 0.05 m below its true surface)
		tang = (tang0 - n * tang0.dot(n)).normalized()
		sag = -ln * ln / (2 * 415) * 0.6  # the leaf hugs the ovoid: it falls away from the tangent line like the shell does
		shell.leaf(p, tuple(tang), tuple(n), L(ln), L(230), two_tone(cols[k % 12], "shell_dark", tuple(n)), K=3, bend=L(sag), wfn=leaf_broad, fold=0.04)
	# the whorl itself: two ribbons winding out from the swirl centre (y 190, z 440 px), the painting's pale spiral bands
	for arm, (col, rad) in enumerate((("leaf_lime", 34), ("leaf_light", 30))):
		pts = []
		for i in range(23):
			th = 0.25 + i * 0.27  # radians; ~2 turns
			rr = 55 + 52 * th
			a = th + arm * math.pi
			yy, zz = 105 + rr * math.cos(a) * 0.9, 440 + rr * math.sin(a)
			pts.append(side(yy, zz, 26 - arm * 4)[0])
		shell.tube(pts, [L(rad)] * len(pts), col, seg=4, caps=(True, True))
	for y, z, nl, r in ((-120, 720, 4, 105), (105, 440, 3, 55), (-200, 480, 3, 70), (80, 190, 3, 50), (330, 740, 3, 70)):  # clovers: the big one up-right of the whorl, a small one in its eye
		p, n = side(y, z, 45 + r * 0.2)
		up = Vector((0, 0, 1)) - n * n.z
		up.normalize()
		sd = n.cross(up)
		for i in range(nl):
			a = 2 * math.pi * i / nl + (math.pi / 4 if nl == 4 else math.pi / 2)
			d = up * math.cos(a) + sd * math.sin(a)
			shell.dome(p + d * L(r * 0.78), tuple(n), L(r * 0.8), L(r * 0.3), "clover", seg=6, smooth=False)
		shell.dome(p + n * L(r * 0.1), tuple(n), L(r * 0.38), L(r * 0.3), "clover_light", seg=6, smooth=False)
	for y, z in ((60, 800), (-30, 440), (180, 330)):  # white flowers
		p, n = side(y, z, 55)
		shell.dome(p, tuple(n), L(62), L(24), "white", seg=5, smooth=False)
		shell.dome(p + n * L(12), tuple(n), L(24), L(18), "flower_c", seg=5, smooth=False)
	for k in range(8):  # gold spikes round the rim
		t = math.radians(-10 + k * 29)
		y, z = sc[1] + sr[1] * math.cos(t) * 0.97, sc[2] + sr[2] * math.sin(t) * 0.97
		n = Vector((0, math.cos(t) / sr[1], math.sin(t) / sr[2])).normalized()
		p = Vector((-L(40) * (1 if k % 2 else -1), y, z))
		shell.cone(p - n * L(15), p + n * L(105), L(30), "gold", seg=5)
	lip = [side(-120 + i * 95, 175 + 25 * math.sin(i * 0.9), 20)[0] for i in range(7)]  # the gold trim on the lip
	shell.tube(lip, [L(20)] * 7, "gold_trim", seg=4)
	pieces.append(shell)
	return pieces


if __name__ == "__main__":
	C.run(__file__, "r2")
