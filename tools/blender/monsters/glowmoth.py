# Glowmoth (normal, healer, flies): a round yellow-and-cream fluffy owl-like body, big magenta eyes, pink feathery
# antennae ending in glowing yellow drops, four wings (pink rim, yellow, green leaf vein, pink spots), small dark feet.
# Painting: reference/goo-lineage-web/assets/enemy-green-moth.png (1254 px, one front 3/4 view).
# Measured from it (px): fluffy body x 320..900, y 430..960; wings x 60..470 and 810..1220, y 165..850; antennae up to
# y 120; claws down to y 1090. Inferred: the back and sides, the wings' sides in depth (the painting shows them
# face-on), left/right made symmetrical (the painting's two antennae differ in curl).
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
from common import Frame, Piece, eye, leaf_broad, on_surface, sq, two_tone, wing_pts
from mathutils import Vector

SPEC = dict(name="Glowmoth", painting="enemy-green-moth.png", kind="normal", height=4.0, budget="800-2000",
	cam=(0, 12))
fr = Frame(0.0041, 620, 1092, 0.30)
W, L = fr.W, fr.L


def palette(P):
	P.add(fur="#FFD535", fur_light="#FFE86E", cream="#FFF1CC", pink="#F5607E", pink_light="#FF9AA8", magenta="#D01E6A",
		dark="#2A0E10", sclera="#FFF3DA", wing_yellow="#FFEC88", leaf="#92B22E", leaf_dark="#6F8A1C", brown="#7A4A1C",
		drop="#FFCE14", white="#FFFFFF", wing_pink="#F5648A", beak="#8A5A28")


def build(P):
	pieces = []
	body = Piece("Body", (0, 0, 0), "Float: bob +-0.3 stud at 1.5 Hz, tilt a few degrees with the flap. Origin on the ground under the body.")
	bc = W(620, 665, 0)
	br = (L(300), L(265), L(270))
	body.sphere(bc, br, "fur", seg=14, rings=8, fn=sq(br, 2.4))
	cp, cn = on_surface(fr, bc, br, 630, 735, 2.4)
	body.sphere(cp - cn * L(30), (L(170), L(50), L(118)), "cream", seg=10, rings=6,
		rot=(math.degrees(math.atan2(cn[2], cn[1])), 0, 0))
	chp, chn = on_surface(fr, bc, br, 665, 905, 2.4)
	body.sphere(chp - chn * L(35), (L(235), L(60), L(105)), "cream", seg=10, rings=6,
		rot=(math.degrees(math.atan2(chn[2], chn[1])), 0, 0))
	fp, fn = on_surface(fr, bc, br, 650, 735, 2.4)  # the cream face mask round the eyes (the painting's owl-like face)
	body.dome(fp, fn, L(175), L(14), "fur_light", seg=12, up=(0, 0, 1), sx=1.0, sy=0.6)
	for px, tilt in ((555, -8), (750, 8)):
		p, n = on_surface(fr, bc, br, px, 728, 2.4)
		eye(body, p + n * L(18), n, L(58), sclera="sclera", iris="magenta", pupil="dark", up=(0, 0, 1), tall=1.2, tilt=tilt, seg=10)
	bk, bn = on_surface(fr, bc, br, 675, 790, 2.4)
	body.cone(Vector(bk) - Vector(bn) * L(10) + Vector((0, -L(28), 0)), Vector(bk) + Vector((0, -L(60), -L(30))), L(24), "beak", seg=5)
	for px, py, ln, wd in ((555, 872, 120, 70), (650, 890, 130, 80), (730, 870, 115, 70)):  # pink chest feathers
		p, n = on_surface(fr, bc, br, px, py - 20, 2.4)
		body.leaf(Vector(p) + Vector(n) * L(8), (0.0, -0.5, -1.0), tuple(n), L(ln), L(wd), two_tone("pink", "pink_light", tuple(n)), K=3, bend=L(10), wfn=leaf_broad)
	hp, hn = on_surface(fr, bc, br, 610, 490, 2.4)  # the pink head tuft and the white feather under it
	body.leaf(Vector(hp) + Vector(hn) * L(6), (0, -0.3, 1.0), tuple(hn), L(130), L(95), two_tone("pink", "pink_light", tuple(hn)), K=3, bend=L(15), wfn=leaf_broad)
	wp, wn = on_surface(fr, bc, br, 610, 590, 2.4)
	body.leaf(Vector(wp) + Vector(wn) * L(6), (0, -0.2, -1.0), tuple(wn), L(120), L(70), "white", K=3, bend=L(8), wfn=leaf_broad)
	for px in (520, 735):  # the yellow crest tufts
		p, n = on_surface(fr, bc, br, px, 440, 2.4)
		body.leaf(Vector(p), (0.25 * (px - 620) / 120, -0.2, 1.0), tuple(n), L(150), L(80), "fur_light", K=3, bend=L(10), wfn=leaf_broad)
	for px in (535, 780):
		p, n = on_surface(fr, bc, br, px, 670, 2.4)
		body.dome(p, n, L(20), L(6), "pink", seg=6)
	pieces.append(body)

	# ---- Wings: pink fluffy rim, yellow field, a green leaf, pink spots; a forewing and a hindwing a side
	wj = W(880, 650, -60)
	wl = Piece("WingL", wj, "Slow soft flap about the root: +-30 deg at 3-4 Hz (a moth, not a bee); the healing pulse spreads them wide.")

	def wing(piece, root, tip_px, Lw, Ww, nrm):
		a = W(tip_px[0], tip_px[1], -60) - root
		a.normalize()
		n = Vector(nrm).normalized()
		w = n.cross(a)
		# n points at the viewer: the rim goes behind, the yellow field in the middle, the green leaf in front
		piece.sheet(wing_pts(root - n * L(10), a, w, L(Lw) * 1.08, L(Ww) * 1.1, leaf_broad), "wing_pink")
		piece.sheet(wing_pts(root, a, w, L(Lw), L(Ww), leaf_broad), "wing_yellow")
		piece.sheet(wing_pts(root + n * L(8) + a * L(Lw * 0.12), a, w, L(Lw) * 0.74, L(Ww) * 0.55, leaf_broad), "leaf")
		return a, w, n

	a1, w1, n1 = wing(wl, wj, (1190, 400), 430, 330, (0.15, -1, 0.15))
	r2 = W(870, 700, -60)
	a2, w2, n2 = wing(wl, r2, (1130, 790), 340, 260, (0.15, -1, 0.0))
	for t, off_w in ((0.62, 0.05), (0.7, -0.3)):  # pink spots on the hindwing
		c = r2 + a2 * L(340 * t) + w2 * L(260 * off_w)
		wl.dome(c - n2 * L(10), tuple(-n2), L(36), L(8), "pink", seg=8)
	pieces.append(wl)
	pieces.append(wl.mirror("WingR"))

	# ---- Antennae: a pink feather blade, hooked over, ending in a glowing honey drop
	def antenna(sx):
		root = W(620 + sx * 80, 520, 0)
		a = Piece("AntennaL" if sx > 0 else "AntennaR", root, "Bob and curl about the root (+-10 deg, 1.2 Hz, the drop swings after); the drop glows when it heals.")
		path = [W(620 + sx * 80, 520, 0), W(620 + sx * 120, 360, 0), W(620 + sx * 160, 200, 0), W(620 + sx * 235, 160, 0), W(620 + sx * 285, 220, 0)]
		a.tube(path, [L(34), L(30), L(26), L(22), L(20)], "pink", seg=5, caps=(False, True))
		nrm = (0, -1, 0)
		a.leaf(path[0], tuple(path[2] - path[0]), nrm, (path[2] - path[0]).length * 1.05, L(150), two_tone("pink", "pink_light", nrm), K=4, bend=L(10), wfn=leaf_broad)
		a.sphere(W(620 + sx * 285, 330, 0), (L(80), L(75), L(110)), "drop", seg=8, rings=5)
		a.leaf(W(620 + sx * 285, 232, 0), (0, 0, 1), nrm, L(80), L(80), "pink", K=3, bend=L(6), wfn=leaf_broad)
		return a

	pieces.append(antenna(1))
	pieces.append(antenna(-1))

	# ---- Feet: a feather tuft and two dark claws
	def foot(name, tuft_px, claws, depth):
		t = W(tuft_px[0], tuft_px[1], depth)
		f = Piece(name, t, "Tuck up while flying; swing a few degrees (+-10) with the bob.")
		f.sphere(t, (L(70), L(55), L(75)), "fur", seg=7, rings=5)
		f.sphere(t + Vector((0, -L(25), -L(35))), (L(45), L(35), L(35)), "pink", seg=6, rings=4)
		for cx, cy in claws:
			c = W(cx, cy, depth)
			f.cone(c + Vector((0, 0, L(45))), c + Vector((L(14), -L(10), -L(55))), L(24), "brown", seg=5)
		return f

	pieces.append(foot("FootL", (715, 985), [(735, 1060), (660, 1065)], 40))
	pieces.append(foot("FootR", (500, 945), [(440, 935), (575, 1005)], 30))
	return pieces


if __name__ == "__main__":
	C.run(__file__, "r1")
