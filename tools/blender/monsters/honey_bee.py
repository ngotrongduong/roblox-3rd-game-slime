# Honey Bee (normal, hunter, flies): cream fuzzy collar, yellow head with a leaf and angry amber eyes, striped
# abdomen ending in a leafy orange honey bud, translucent wings, antennae with honey drops, brown legs with leaf cuffs
# and gold claws, a honeycomb ball. Painting: reference/goo-lineage-web/assets/enemy-green-bee.png.
# Measured from it (px, 1254 square): collar diameter ~470 (x 350..800), yellow face disc ~330, abdomen ~560 long and
# ~290 wide, bud ~300 long, wing span ~1050 (x 105..1150), whole height ~1135 (bud tip y 55 to claw tip y 1190).
# Built LEVEL (facing -Y, tail along +Y) in painting-px units, then pitched 28 deg (tail up) as in the painting.
# Inferred: everything behind and under the body, the depth of every part, the wing outlines' backs, 3 legs a side.
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
from common import Frame, Piece, eye, leaf_broad, on_surface, two_tone, wing_pts
from mathutils import Vector

SPEC = dict(name="HoneyBee", painting="enemy-green-bee.png", kind="normal", height=4.3, budget="800-2000",
	az_range=range(10, 91, 6), el_range=range(6, 41, 6))
S = 0.0038
PITCH = 32.0
fr0 = Frame(S, 0, 0, 0.0)  # a frame where px = x (left +), py = -z, d = -y (for on_surface in the level frame)


def B(x, y, z):  # bee-frame px -> metres: x = monster's left, y = backward, z = up
	return Vector((x * S, y * S, z * S))


def L(v):
	return v * S


def palette(P):
	P.add(cream="#F8EEC8", yellow="#FFCB14", yellow_light="#FFE24A", abd_green="#5E9E1E", leaf="#4C9C26", leaf_dark="#2F7A1E",
		brown="#64300F", brown_light="#8E4A16", orange="#F58A0C", orange_gold="#FFB41A", amber="#EE921A", dark="#2A1206",
		white="#FFFFFF", cream_eye="#F7EBC8", gold="#FFB81C", wing="#FFFCEA", wing_edge="#FFE68A", honey="#FFBE1C",
		honey_dark="#E0900E", drop="#FFD21A", pink="#E8708A")


def sheet_wing(p, root, axis, wd, Lw, Ww, col, edge=None):
	if edge:
		p.sheet(wing_pts(root - Vector((0, 0, 0.004)), axis, wd, Lw * 1.07, Ww * 1.1, leaf_broad), edge)
	p.sheet(wing_pts(root, axis, wd, Lw, Ww, leaf_broad), col)


def build(P):
	pieces = []
	# ---- Body: head, fuzzy collar, face
	body = Piece("Body", (0, 0, 0), "Root. Hover bob +-0.15 stud at 3 Hz; lean forward when it dives. Origin under the head.")
	body.sphere(B(0, 30, 0), (L(255), L(130), L(250)), "cream", seg=12, rings=7)
	hc, hr = B(0, -110, -5), (L(185), L(150), L(180))
	body.sphere(hc, hr, "yellow", seg=12, rings=7)
	for sx in (1, -1):
		p, n = on_surface(fr0, hc, hr, sx * 82, -22)
		eye(body, p - n * L(6), n, L(56), up=(0, 0, 1), tall=1.25, tilt=-sx * 16, seg=8)
		a, an = on_surface(fr0, hc, hr, sx * 160, -85)
		b, bn = on_surface(fr0, hc, hr, sx * 30, -52)
		body.tube([a + an * L(5), b + bn * L(5)], [L(17), L(13)], "dark", seg=4)
		m0 = B(sx * 55, -215, 60 * -1)
		mp = [B(sx * 60, -235, -75), B(sx * 80, -292, -112), B(sx * 42, -326, -170)]
		body.tube(mp, [L(24), L(19), L(13)], "brown", seg=5)
		body.cone(mp[-1] + (mp[-1] - mp[-2]).normalized() * L(-8), mp[-1] + (mp[-1] - mp[-2]).normalized() * L(60), L(14), "gold", seg=5)
	body.cone(B(0, -245, -60), B(0, -292, -165), L(26), "gold", seg=5)
	fl = B(0, -235, 95)
	body.leaf(fl, (0, 0.35, 1.0), (0, -1, 0.35), L(210), L(105), two_tone("leaf", "leaf_dark", (0, -1, 0.35)), K=4, bend=L(20), wfn=leaf_broad)
	body.leaf(B(-30, 110, 150), (-0.5, 0.4, 1.0), (0.3, -1, 0.3), L(140), L(70), two_tone("leaf", "leaf_dark", (0, -1, 0.3)), K=3)
	pieces.append(body)

	# ---- Abdomen: striped ovoid (yellow / green bands), joint where it meets the collar
	aj = B(0, 170, 10)
	abd = Piece("Abdomen", aj, "Wobble about the joint (pitch +-8 deg, 1.2 Hz) and curl down when it stings.")
	prof = [(0, 0), (110, 30), (155, 70), (172, 110), (175, 170), (170, 220), (160, 290), (135, 340), (110, 390), (80, 430), (52, 470), (30, 500)]
	bands = [(0, 110, "yellow"), (110, 220, "abd_green"), (220, 340, "yellow"), (340, 430, "abd_green"), (430, 600, "yellow")]

	def stripe(c, n):
		h = (c[1] - aj.y) / S
		for lo, hi, col in bands:
			if lo <= h < hi:
				return col
		return "yellow"

	abd.lathe(aj, [(L(r * 1.12), L(h)) for r, h in prof], stripe, seg=10, axis=(0, 1, 0), up=(0, 0, 1))
	abd.tube([aj + B(0, 496, 0), aj + B(0, 540, 4)], [L(30), L(24)], "brown", seg=6)
	pieces.append(abd)

	# ---- Bud: the leafy orange honey bud on the end of the abdomen
	bj = aj + B(0, 536, 4)
	bud = Piece("Bud", bj, "Sway about the joint (+-10 deg, 2 Hz, lags the abdomen); drips glow on a hit.")
	ax = Vector((0, math.cos(math.radians(24)), math.sin(math.radians(24))))
	prof = [(L(32), 0), (L(78), L(50)), (L(98), L(120)), (L(86), L(200)), (L(50), L(262)), (0, L(320))]
	bud.lathe(bj, prof, lambda c, n: "orange" if (c - bj).dot(ax) < L(150) else "orange_gold", seg=8, axis=tuple(ax), up=(0, 0, 1))
	side = Vector((1, 0, 0))
	up = ax.cross(side).normalized()
	for i in range(5):
		a = 2 * math.pi * i / 5
		rad = side * math.cos(a) + up * math.sin(a)
		d = ax * 0.75 + rad * 0.65
		bud.leaf(bj + rad * L(40), tuple(d), tuple(rad), L(210), L(95), two_tone("leaf", "leaf_dark", tuple(rad)), K=3, bend=L(20))
	pieces.append(bud)

	# ---- Wings: a big forewing and a smaller hindwing each side (translucent in game: Transparency ~0.35)
	wl = Piece("WingL", B(150, 95, 140), "Flap about the root axis (the line along the body): +-38 deg at 14-18 Hz while flying; slow +-10 deg at idle.")
	# (the wing plane faces forward-up, so the broad face shows from the front like the painting)
	a1, n1 = Vector((0.93, 0.3, 0.28)), Vector((0.3, -1, 0.25))
	sheet_wing(wl, B(150, 95, 140), a1, n1.cross(a1), L(450), L(215), "wing", "wing_edge")
	a2, n2 = Vector((0.95, 0.5, -0.12)), Vector((0.2, -1, 0.5))
	sheet_wing(wl, B(140, 150, 100), a2, n2.cross(a2), L(320), L(165), "wing", "wing_edge")
	pieces.append(wl)
	pieces.append(wl.mirror("WingR"))

	# ---- Antennae: brown curved stalk and a glossy honey drop
	def antenna(name, sx):
		root = B(sx * 70, -190, 150)
		a = Piece(name, root, "Bob and sway about the root (+-12 deg, 1.6 Hz, out of phase with the other).")
		path = [root, B(sx * 110, -180, 280), B(sx * 200, -130, 335), B(sx * 255, -95, 280)]
		a.tube(path, [L(20), L(17), L(15), L(14)], "brown", seg=5, caps=(False, True))
		a.sphere(B(sx * 252, -78, 195), (L(52), L(52), L(95)), "drop", seg=8, rings=5)
		return a

	pieces.append(antenna("AntennaL", 1))
	pieces.append(antenna("AntennaR", -1))

	# ---- Legs: three a side, brown with a leaf cuff and a gold claw; the honeycomb ball hangs from the left set
	def legs(name, sx, ball):
		root = B(sx * 105, 70, -150)
		lg = Piece(name, root, "Swing the three legs a few degrees about the joint (+-14 deg) as it flies; tuck up when it dives.")
		for y in (-30, 70, 165):
			s_, k_, f_ = B(sx * 100, y, -150), B(sx * 195, y - 15, -255), B(sx * 215, y - 40, -385)
			lg.tube([s_, k_, f_], [L(40), L(36), L(20)], "brown", seg=4, caps=(False, True))
			d = (f_ - k_).normalized()
			lg.lathe(k_ + d * L(24), [(L(66), 0), (L(36), L(64))], "leaf", seg=5, axis=tuple(d), cap=True)
			lg.cone(f_ - d * L(10), f_ + d * L(75), L(20), "gold", seg=5)
		if ball:
			lg.tube([B(sx * 150, 30, -170), B(sx * 215, -5, -280)], [L(10), L(9)], "leaf", seg=4)
			bc = B(sx * 225, -15, -380)
			lg.sphere(bc, L(88), "honey", seg=10, rings=7)
			lg.lathe(bc + B(0, 0, 70), [(L(50), 0), (L(26), L(46))], "leaf", seg=6, cap=True)
		return lg

	pieces.append(legs("LegsL", 1, True))
	pieces.append(legs("LegsR", -1, False))

	# ---- pitch the whole bee (tail up), then stand its lowest point on the ground
	for p in pieces:
		p.rotate_x(PITCH, (0, 0, 0))
	zmin = min(p.zmin() for p in pieces)
	for p in pieces:
		p.shift((0, 0, -zmin))
	body.joint = Vector((0, 0, 0))
	return pieces


if __name__ == "__main__":
	C.run(__file__, "r1")
