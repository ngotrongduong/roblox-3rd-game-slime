# Bloomshell (MINI-BOSS, wave 5): a leaf-shingled turtle with gold spikes, a big pink lotus bud on its shell, a green
# head with a leaf crest and four gold-clawed legs. Painting: reference/goo-lineage-web/assets/enemy-green-turtle.png.
# Measured from it (px, 1254 square): shell x 135..1140, y 230..1000 (dome 1005 wide); lotus bud x 480..820, y 25..400;
# head x 380..750, y 690..1000; front legs x 140..390 / 800..1050, claws down to y 1235. Built level, facing -Y, in px
# units (B frame). Inferred: the back and the sides of the shell (the shingle rows go all round), the rear legs (only
# one rear claw set shows), the tail (none shows: a short stub is NOT added), the plastron (hidden).
import math
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C
from common import Frame, Piece, eye, leaf_broad, on_surface, sq, two_tone
from mathutils import Vector

SPEC = dict(name="Bloomshell", painting="enemy-green-turtle.png", kind="mini-boss", height=8.0, budget="up to 4000",
	az_range=range(-20, 21, 10), el_range=range(10, 46, 7))
S = 0.0072
fr0 = Frame(S, 0, 0, 0.0)


def B(x, y, z):
	return Vector((x * S, y * S, z * S))


def L(v):
	return v * S


def palette(P):
	P.add(shell="#238040", shell_deep="#1A5A30", rim="#6A3C24", leaf_a="#C2E23A", leaf_b="#62BC4A", leaf_c="#92D23E",
		leaf_dark="#2E923E", skin="#6AAA32", skin_light="#96CC3A", skin_dark="#4A7E26", tan="#B8935A", gold="#F5AE2E",
		pink="#F26A8E", pink_light="#F8A2B8", pink_deep="#D94A78", amber="#E8A020", dark="#241208", cream="#F3E8B8",
		white="#FFFFFF", glint="#FFFFFF")


def build(P):
	pieces = []
	# ---- Body: the shell, shingles, spikes, rim and the soft skin under it
	body = Piece("Body", (0, 0, 0), "Root. Slow lumbering sway (+-2 deg roll, 0.9 Hz) and a heavy 0.25 stud dip per step; origin on the ground under the middle.")
	sc, sr = B(0, 120, 330), (L(520), L(520), L(345))
	body.sphere(B(0, 110, 150), (L(430), L(470), L(130)), "skin", seg=12, rings=6)
	body.sphere(sc, sr, lambda c, n: "shell" if c[2] > sc[2] - L(20) else "rim", seg=16, rings=9)

	def shell_pt(theta, phi, push=0.0):
		t, f = math.radians(theta), math.radians(phi)
		p = Vector((sr[0] * math.sin(t) * math.sin(f), sc[1] - sr[1] * math.sin(t) * math.cos(f), sc[2] + sr[2] * math.cos(t)))
		n = Vector(((p.x - sc[0]) / sr[0] ** 2, (p.y - sc[1]) / sr[1] ** 2, (p.z - sc[2]) / sr[2] ** 2)).normalized()
		up = Vector((-sr[0] * math.cos(t) * math.sin(f), sr[1] * math.cos(t) * math.cos(f), sr[2] * math.sin(t)))
		up = (up - n * up.dot(n)).normalized()
		return p + n * L(push), n, up

	cols = ["leaf_a", "leaf_b", "leaf_c"]
	rows = ((80, 12, 300, 250), (60, 10, 270, 230), (40, 7, 240, 210), (20, 5, 190, 170))
	for ri, (th, n_, ln, wd) in enumerate(rows):
		for k in range(n_):
			phi = (k + (0.5 if ri % 2 else 0)) * 360.0 / n_
			p, n, up = shell_pt(th, phi, 4 + ri * 5)
			sag = -ln * ln / (2 * 450)
			body.leaf(p, tuple(up), tuple(n), L(ln), L(wd), two_tone(cols[(k + ri) % 3], "leaf_dark", tuple(n)), K=3, bend=L(sag), wfn=leaf_broad, fold=0.05)
	for phi, th in ((0, 52), (90, 62), (-90, 62), (50, 70), (-50, 70), (135, 70), (-135, 70)):  # gold spikes on green plates
		p, n, up = shell_pt(th, phi, 22)
		body.dome(p - n * L(6), tuple(n), L(62), L(20), "leaf_dark", seg=6, smooth=False)
		body.cone(p, p + n * L(105), L(34), "gold", seg=5)
	pieces.append(body)

	# ---- Bud: the lotus on top, six pink petals inside green sepals; joint at the shell top
	tp, tn, _ = shell_pt(0, 0, 0)
	bud = Piece("Bud", tp, "Sway about the joint (+-6 deg, 0.7 Hz), swell (scale 1.08) and glow before a big attack; opens (petals out 25 deg) when it enrages.")
	bud.lathe(tp, [(L(95), L(-20)), (L(120), L(80)), (L(125), L(170)), (L(85), L(260)), (0, L(320))], "pink_deep", seg=8)
	for i in range(6):
		a = 2 * math.pi * i / 6 + 0.3
		rad = Vector((math.cos(a), math.sin(a), 0))
		d = Vector((rad.x * 0.22, rad.y * 0.22, 1.0)).normalized()
		bud.leaf(tp + rad * L(100) + Vector((0, 0, L(30))), tuple(d), tuple(rad), L(310), L(200), two_tone("pink", "pink_light", tuple(rad)), K=4, bend=L(-26), wfn=leaf_broad, fold=0.1)
	for i in range(7):  # green sepals round the base
		a = 2 * math.pi * i / 7
		rad = Vector((math.cos(a), math.sin(a), 0))
		d = Vector((rad.x * 0.55, rad.y * 0.55, 0.85)).normalized()
		bud.leaf(tp + rad * L(120), tuple(d), tuple(rad), L(210), L(130), two_tone("leaf_b", "leaf_dark", tuple(rad)), K=3, bend=L(-6), wfn=leaf_broad)
	pieces.append(bud)

	# ---- Head: green, leaf crest with a gold spike, amber angry eyes, snout and cheek spikes
	hj = B(0, -380, 185)
	head = Piece("Head", hj, "Look/turn about the neck (yaw +-30 deg), lunge forward 0.6 stud on a bite, bob down at each step.")
	hc, hr = B(0, -540, 195), (L(235), L(215), L(175))
	head.sphere(hc, hr, "skin", seg=12, rings=8, fn=sq(hr, 2.3))
	sn, snr = B(0, -710, 150), (L(120), L(110), L(75))
	head.sphere(sn, snr, "skin_light", seg=10, rings=6)
	for sx in (1, -1):
		p, n = on_surface(fr0, hc, hr, sx * 100, -265, 2.3)
		eye(head, p + n * L(4), n, L(50), up=(0, 0, 1), tall=1.0, tilt=-sx * 18, seg=10)
		head.cone(on_surface(fr0, hc, hr, sx * 190, -230, 2.3)[0], on_surface(fr0, hc, hr, sx * 190, -230, 2.3)[0] + Vector((sx * L(60), -L(30), L(30))), L(24), "gold", seg=5)
		pn, nn = on_surface(fr0, sn, snr, sx * 40, -205, 2.0)
		head.dome(pn, nn, L(14), L(6), "dark", seg=5)
	for sx in (1, -1):  # leaf crest
		head.leaf(B(sx * 50, -480, 300), (sx * 0.9, -0.25, 0.55), (0, -0.5, 1.0), L(200), L(120), two_tone("leaf_a", "leaf_b", (0, -0.5, 1.0)), K=3, bend=L(10), wfn=leaf_broad)
	head.leaf(B(0, -490, 330), (0, -0.2, 1.0), (0, -1.0, 0.2), L(210), L(150), two_tone("leaf_c", "leaf_b", (0, -1.0, 0.2)), K=3, bend=L(10), wfn=leaf_broad)
	head.cone(B(0, -490, 380), B(0, -500, 520), L(34), "gold", seg=5)
	pieces.append(head)

	# ---- Legs: a thick green leg with a leaf, three gold claws and a foot pad
	def leg(name, sx, y, depth_out, hip_z, reach):
		jx = sx * depth_out
		j = B(jx, y, hip_z)
		lg = Piece(name, j, "Swing +-20 deg about the hip, diagonal pairs together (walk cycle 1.1 Hz); stamp (+-35 deg) on the slam attack.")
		foot = B(jx + sx * 40, y - reach, 70)
		lg.tube([j, (j + foot) * 0.5 + B(sx * 20, -reach * 0.3, 0), foot], [L(125), L(120), L(115)], "skin", seg=8, caps=(False, True))
		lg.sphere(foot + B(0, -50, 0), (L(135), L(165), L(75)), "skin_light", seg=8, rings=5)
		for i in (-1, 0, 1):
			b0 = foot + B(i * 75, -180, 10)
			lg.cone(b0, b0 + B(i * 12, -90, -18), L(32), "gold", seg=5)
		lg.leaf((j + foot) * 0.5 + B(0, -90, 40), (sx * 0.1, 0.1, -1.0), (sx * 0.3, -1.0, 0.1), L(250), L(160), two_tone("leaf_b", "leaf_dark", (0, -1, 0)), K=3, bend=L(-10), wfn=leaf_broad)
		for k, (dz, wd) in enumerate(((-10, 230), (-90, 220), (-170, 200))):  # the leaf armour on the leg: shingles standing proud of the tube
			t = -dz / (hip_z - 70)  # how far down the leg the plate starts: it follows the leg's slope and stands on its front
			lg.leaf(B(jx + sx * 40 + (k - 1) * sx * 45, y - reach * t - 160, hip_z + dz), (sx * 0.1, -reach / (hip_z - 70), -1.0), (sx * 0.2, -1.0, 0.45), L(185), L(wd), two_tone(("leaf_c", "leaf_a", "leaf_b")[k], "leaf_dark", (sx, 0, 0)), K=3, bend=L(-18), wfn=leaf_broad)
		return lg

	pieces.append(leg("LegFL", 1, -280, 390, 270, 180))
	pieces.append(leg("LegFR", -1, -280, 390, 270, 180))
	pieces.append(leg("LegBL", 1, 400, 400, 260, 60))
	pieces.append(leg("LegBR", -1, 400, 400, 260, 60))
	return pieces


if __name__ == "__main__":
	C.run(__file__, "r2")
