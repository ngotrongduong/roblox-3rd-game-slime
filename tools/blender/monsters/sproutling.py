# Sproutling (normal, melee): the round glossy green blob with a sprout, two big leaf ears and stubby ringed feet.
# Painting: reference/goo-lineage-web/assets/enemy-green-sprout.png (1254 px, one 3/4 view from above).
# Measured from it (px): body x 360..940 (centre 650), y 385..1000; sprout top y 84; ears x 95..1176; ground = the
# feet's soles (y ~1060 after the depth lift). Inferred: the back and the sides (a round body, ears mirrored in
# depth), the depth of every part, the ground level.
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
from common import Frame, Piece, eye, leaf_broad, on_surface, sq, two_tone

SPEC = dict(name="Sproutling", painting="enemy-green-sprout.png", kind="normal", height=4.2, budget="800-2000",
	az_range=range(-30, 31, 10), el_range=range(0, 41, 8))
fr = Frame(0.0043, 650, 1060, 0.30)
W, L = fr.W, fr.L
N_SQ = 2.7  # body superellipsoid exponent: a fat mochi blob, not a ball


def palette(P):
	P.add(green="#9AD42C", green_light="#B8E63C", green_dark="#4FA02C", ear_dark="#329A4C", ear_mid="#5CBE3C",
		yellow="#D5D824", yellow_spot="#E9EE3C", cream="#F7EBBC", amber="#E8921A", dark="#2A1706", white="#FFFFFF",
		pink="#E8708A", gold="#D9A82C", brow="#2D6B14", toe_pad="#E4CD86", stem="#7CC63A", leaf="#7CCB32")


def build(P):
	pieces = []
	# ---- Body: root, origin on the ground under the body centre
	body = Piece("Body", (0, 0, 0), "Squash and hop by code; the whole monster follows it. Origin on the ground under the centre.")
	bc = W(650, 690, 0)
	br = (L(300), L(285), L(310))
	b = body.sphere(bc, br, "green", seg=14, rings=9, fn=sq(br, N_SQ))
	p, n = on_surface(fr, bc, br, 712, 935, N_SQ)
	body.sphere(p - n * L(34), (L(178), L(55), L(88)), "cream", seg=12, rings=7,
		rot=(math.degrees(math.atan2(n[2], n[1])), 0, 0))
	for px, py, rr in ((585, 548, 20), (483, 722, 18), (526, 812, 19), (925, 770, 18), (700, 470, 15), (800, 590, 16), (640, 600, 14), (380, 790, 14)):
		p, n = on_surface(fr, bc, br, px, py, N_SQ)
		body.dome(p - n * 0.01, n, L(rr), L(rr) * 0.35, "yellow_spot", seg=6)
	for px, py, tilt in ((600, 765, -14), (865, 760, 14)):
		p, n = on_surface(fr, bc, br, px, py, N_SQ)
		eye(body, p - n * 0.02, n, L(72), up=(0, 0, 1), tall=1.4, tilt=tilt, seg=12)
	for (x0, y0), (x1, y1) in (((540, 690), (685, 782)), ((940, 700), (815, 778))):
		a, an = on_surface(fr, bc, br, x0, y0, N_SQ)
		bb, bn = on_surface(fr, bc, br, x1, y1, N_SQ)
		body.tube([a + an * L(10), bb + bn * L(10)], [L(27), L(20)], "brow", seg=4)
	p, n = on_surface(fr, bc, br, 756, 860, N_SQ)
	body.dome(p + n * L(4), n, L(34), L(16), "pink", seg=8, up=(0, 0, 1), sx=0.8)
	pieces.append(body)

	# ---- Sprout: stem and two leaves, joint at the stem foot on the body top
	sj = W(668, 405, 0) + C.Vector((0, 0, -0.03))
	sprout = Piece("Sprout", sj, "Sway side to side (rotate about the joint, +-12 deg, 0.8 Hz) and bob with the hop.")
	stem = [W(668, 420, 0), W(690, 360, 0), W(702, 310, 0), W(692, 268, 0)]
	sprout.tube(stem, [L(19), L(16), L(14), L(13)], "stem", seg=5, caps=(False, True))
	top = W(692, 268, 0)
	nrm = (0, -0.55, 0.85)
	tt = two_tone("green_light", "leaf", nrm)
	sprout.leaf(top, (-0.9, -0.1, 0.42), nrm, L(255), L(135), tt, bend=L(30), K=5, wfn=leaf_broad)
	sprout.leaf(top, (0.35, -0.05, 0.94), nrm, L(195), L(135), tt, bend=L(25), K=5, wfn=leaf_broad)
	pieces.append(sprout)

	# ---- Ears: big leaves with a yellow inner leaf; EarL is the monster's left (the viewer's right)
	def ear(name, root_px, tip_px, wd, inner_tip, inner_wd, lean, leaflets, root_d):
		root = W(root_px[0], root_px[1], root_d)
		e = Piece(name, root, "Wiggle: rotate about the root +-10 deg at 1.5 Hz, extra flick when it attacks.")
		tip = W(tip_px[0], tip_px[1], root_d)
		ax = tip - root
		nrm = C.Vector((0.0, -1.0, 0.25)) + C.Vector((lean, 0, 0))
		e.leaf(root, ax, nrm, ax.length, L(wd), two_tone("ear_dark", "ear_mid", nrm), bend=L(30), curl=L(30), K=6, fold=0.1, wfn=leaf_broad)
		ia = W(inner_tip[0], inner_tip[1], root_d + 40) - root
		e.leaf(root + C.Vector((0, -L(30), 0)), ia, nrm, ia.length, L(inner_wd), "yellow", bend=L(20), K=5, fold=0.1, wfn=leaf_broad)
		for (lx, ly, tx, ty) in leaflets:
			lb = W(lx, ly, root_d + 30)
			e.leaf(lb, W(tx, ty, root_d + 30) - lb, nrm, (W(tx, ty, 0) - W(lx, ly, 0)).length, L(42), "leaf", K=3, bend=L(8))
		return e

	pieces.append(ear("EarL", (925, 610), (1065, 170), 330, (1120, 390), 150, 0.5, [(955, 540, 985, 600)], 40))
	pieces.append(ear("EarR", (480, 660), (150, 330), 360, (150, 520), 175, -0.5, [(470, 600, 430, 640)], 60))

	# ---- Feet: ringed ankle and a round paw with three toes; FootL = the viewer's right one (farther)
	def foot(name, ankle_px, paw_px, depth, pw, toes, pads):
		ank = W(ankle_px[0], ankle_px[1], depth)
		f = Piece(name, ank, "Swing +-25 deg about the hip while walking (alternate), stamp on attack.")
		pc = W(paw_px[0], paw_px[1], depth + 30)
		d = pc - ank
		f.lathe(ank, [(L(42), 0), (L(52), L(16)), (L(42), L(32)), (L(52), L(48)), (L(42), L(64))], "gold", seg=8,
			axis=(d.x, d.y, d.z), cap=True)
		f.sphere(pc, (L(pw), L(pw * 0.85), L(pw * 0.75)), "green", seg=9, rings=6)
		for tx, ty in toes:
			f.sphere(W(tx, ty, depth + 80), L(42), "green", seg=7, rings=4)
		for tx, ty in pads:
			f.sphere(W(tx, ty, depth + 110), (L(28), L(16), L(22)), "toe_pad", seg=6, rings=4)
		return f

	pieces.append(foot("FootL", (893, 930), (908, 992), 120, 105, [(850, 1030), (915, 1052), (972, 1015)], [(930, 1030)]))
	pieces.append(foot("FootR", (443, 960), (412, 1062), 200, 112, [(362, 1108), (420, 1140), (485, 1108)], [(375, 1135), (470, 1118)]))
	return pieces


if __name__ == "__main__":
	C.run(__file__, "r1")
