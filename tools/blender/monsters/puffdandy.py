# Puffdandy (normal, ranged, floats): a light-green round blob under a huge white dandelion puff with a yellow centre,
# two leaf arms and a curly stem tail. Painting: reference/goo-lineage-web/assets/enemy-green-dandelion.png.
# Measured from it (px, 1254 square): body x 370..865 (centre 617), y ~503..905; puff x 235..975, y 45..640; tail
# down to y 1150. The three loose seeds floating around the painting are NOT built (effects, they drift by code).
# Inferred: the back and sides of everything, the puff's depth, the fluff (a plain oblate ball with petal fans).
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
from common import Frame, Piece, eye, leaf_broad, on_surface, sq, two_tone, wing_pts
from mathutils import Vector

SPEC = dict(name="Puffdandy", painting="enemy-green-dandelion.png", kind="normal", height=4.4, budget="800-2000",
	cam=(0, 8))
fr = Frame(0.0037, 617, 1150, 0.30)
W, L = fr.W, fr.L


def palette(P):
	P.add(body="#BEE45C", body_dark="#9CC23A", leaf="#B4DA2C", leaf_dark="#86BC22", white="#F8F8F2", puff_under="#EDEBDC",
		yellow="#F5D95A", brown="#9A6A1C", amber="#E7A52A", dark="#3A2008", cream="#FFF4D8", pink="#E86F82",
		cheek="#F4D2A8", glint="#FFFFFF", stem="#A8CC2A")


def build(P):
	pieces = []
	body = Piece("Body", (0, 0, 0), "Float: bob +-0.25 stud at 1.2 Hz and drift; origin on the ground under the blob (the game lifts it).")
	bc = W(617, 750, 0)
	br = (L(248), L(235), L(240))
	body.sphere(bc, br, "body", seg=12, rings=8, fn=sq(br, 2.3))
	for px, tilt in ((505, -10), (705, 10)):
		p, n = on_surface(fr, bc, br, px, 758, 2.3)
		eye(body, p - n * L(6), n, L(64), iris="amber", up=(0, 0, 1), tall=1.1, tilt=tilt, seg=10)
	for (x0, y0), (x1, y1) in (((455, 705), (545, 730)), ((755, 700), (665, 722))):
		a, an = on_surface(fr, bc, br, x0, y0, 2.3)
		b, bn = on_surface(fr, bc, br, x1, y1, 2.3)
		body.tube([a + an * L(5), b + bn * L(5)], [L(10), L(8)], "dark", seg=4)
	p, n = on_surface(fr, bc, br, 590, 815, 2.3)
	body.dome(p + n * L(3), n, L(26), L(12), "pink", seg=8, sx=0.8)
	for px in (470, 745):  # the pale blush
		p, n = on_surface(fr, bc, br, px, 830, 2.3)
		body.dome(p, n, L(34), L(8), "cheek", seg=8, sx=0.7)
	p, n = on_surface(fr, bc, br, 583, 692, 2.3)  # the white sprout mark on the forehead
	for ang, ln in ((-35, 26), (0, 32), (35, 26)):
		d = Vector((math.sin(math.radians(ang)), 0, math.cos(math.radians(ang))))
		q = Vector(p) + d * L(6)
		body.leaf(q, (d.x, d.y, d.z), tuple(n), L(ln * 1.3), L(18), "glint", K=3, thick=L(4))
	pieces.append(body)

	# ---- Puff: a white oblate ball with a flower centre, petal fans round the lower rim and leaf sepals
	pj = W(605, 640, -20) + Vector((0, 0, 0))
	puff = Piece("Puff", pj, "Sway on the neck (+-6 deg, 1 Hz), puff up (scale 1.1) when it shoots, shake loose on a hit. Origin where it sits on the body.")
	pc = W(605, 345, -30)
	pr = (L(372), L(330), L(298))
	puff.sphere(pc, pr, "white", seg=12, rings=7, fn=sq(pr, 2.0))
	pu, un = on_surface(fr, pc, pr, 578, 380, 2.2)
	un = Vector(un)
	puff.dome(Vector(pu) + un * L(8), tuple(un), L(170), L(34), "puff_under", seg=12)
	ax = Vector((1, 0, 0)) - un * Vector((1, 0, 0)).dot(un)
	ax.normalize()
	ay = un.cross(ax)
	for i in range(12):  # the brown petal ring round the yellow centre
		a = 2 * math.pi * i / 12
		d = ax * math.cos(a) + ay * math.sin(a)
		lift = un * L(36)
		puff.cone(Vector(pu) + lift + d * L(66), Vector(pu) + lift + d * L(150) - un * L(10), L(15), "brown", seg=4)
	puff.dome(Vector(pu) + un * L(26), tuple(un), L(62), L(40), "yellow", seg=8)
	# petal fans: broad white petals along the lower front rim
	for i in range(9):
		a = math.radians(-100 + i * 25)  # around the front-bottom of the puff
		base = Vector((math.sin(a) * pr[0] * 0.93, -math.cos(a) * pr[1] * 0.55, -pr[2] * 0.70)) + pc
		d = Vector((math.sin(a) * 0.55, -0.55, -0.62)).normalized()
		nrm = Vector((0, -0.2, 1.0))
		puff.leaf(base, tuple(d), tuple(nrm), L(190), L(125), two_tone("white", "puff_under", tuple(nrm)), K=4, bend=L(25), wfn=leaf_broad)
	# the scalloped rim: a ring of broad white seed-tuft fans round the edge of the puff, so the outline is fluffy
	for ring, (rs, ln, wd) in enumerate(((0.93, 150, 120), (0.80, 120, 100))):
		n_ = 15 - ring * 5
		for i in range(n_):
			t = math.radians(-135 + (270.0 * i / (n_ - 1)) + (7 if ring else 0))  # from the top, round both sides, skipping the bottom
			d = Vector((math.sin(t), 0.0, math.cos(t)))
			base = pc + Vector((d.x * pr[0] * rs, -pr[1] * (0.25 + 0.2 * ring), d.z * pr[2] * rs))
			puff.leaf(base, tuple(d), (0, -1, 0.1), L(ln), L(wd), two_tone("white" if (i + ring) % 2 else "puff_under", "puff_under", (0, -1, 0)), K=2, bend=L(8), wfn=leaf_broad)
	for sx in (1, -1):  # green sepals poking out at the neck
		puff.leaf(W(617 + sx * 260, 640, -20), (sx * 0.9, 0, 0.35), (0, -1, 0.3), L(150), L(80), "leaf", K=3, bend=L(10))
	pieces.append(puff)

	# ---- Arms: two leaves each side (leaf arms), the near one bigger
	def arm(name, root_px, leaves, depth):
		root = W(root_px[0], root_px[1], depth)
		a = Piece(name, root, "Wave: rotate about the root +-25 deg at 1.8 Hz; swing wide when it shoots.")
		for tip_px, wd in leaves:
			tip = W(tip_px[0], tip_px[1], depth + 15)
			ax_ = tip - root
			nrm = Vector((0, -1, 0.35))
			a.leaf(root, tuple(ax_), tuple(nrm), ax_.length, L(wd), two_tone("leaf", "leaf_dark", tuple(nrm)), K=4, bend=L(18), wfn=leaf_broad)
		return a

	pieces.append(arm("ArmR", (395, 800), [((190, 745), 110), ((280, 835), 140)], 20))
	pieces.append(arm("ArmL", (850, 760), [((1040, 640), 130), ((1000, 770), 100)], 10))

	# ---- Tail: the curly stem ending in a leaf cluster
	tj = W(690, 890, -10)
	tail = Piece("Tail", tj, "Swish: rotate about the root +-18 deg at 1.5 Hz with a travelling wave (tip lags).")
	path = [W(690, 885, -10), W(745, 925, -10), W(785, 985, -10), W(765, 1045, -10), W(705, 1050, -10), W(650, 1025, -10)]
	tail.tube(path, [L(20), L(18), L(16), L(15), L(14), L(12)], "stem", seg=5, caps=(False, True))
	end = path[-1]
	for tip_px, wd, ln in (((600, 1010), 85, 120), ((690, 1115), 100, 160), ((610, 1090), 80, 130)):
		tip = W(tip_px[0], tip_px[1], -10)
		ax_ = tip - end
		tail.leaf(end, tuple(ax_), (0, -1, 0.3), ax_.length, L(wd), two_tone("leaf", "leaf_dark", (0, -1, 0.3)), K=3, bend=L(12), wfn=leaf_broad)
	pieces.append(tail)
	return pieces


if __name__ == "__main__":
	C.run(__file__, "r1")
