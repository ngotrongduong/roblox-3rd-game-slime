# Goo Lineage V2 - the base slime body (every slime and the player's avatar use it).
#
# Re-runnable: builds everything from the owner's painting and the constants below, nothing by hand.
#   blender -b --factory-startup -P tools/blender/slime_body.py -- --round N
# (runner: tools/blender/slime_body.ps1 -Round N)
#
# Reference: reference/goo-lineage-web/assets/slime.base.navy.png (front view only, the owner's painting).
# Inferred (no other view exists): the body is a solid of revolution of the front silhouette (round seen
# from above, side silhouette = front silhouette); the painting's slight lean (tip about 4 px left of the
# upper body's centre) is straightened onto one vertical axis.
#
# Blender axes: Z up, the slime faces -Y, its own left is +X. Origin = centre of the base on the ground.
# Height 1.0 (the game scales it). Exported FBX uses Roblox's documented Blender settings (-Z forward, Y up).
#
# Outputs (art/models/slime_body/): SlimeBody.fbx, SlimeBodyOutline.fbx, SlimeBody_roughness.png,
# SlimeBody_normal.png, uv_profile.json (r(v), z(v) of the all-round UV for tools/skins/make_skins.py),
# SlimeBody.blend, review/rN/ (renders, comparison sheets, metrics.json). From round 5 the UV is cylindrical
# (seam at the back centre) and the painted-highlight overlay is retired.

import bpy
import sys
import os
import json
import math
import numpy as np
from mathutils import Vector, Matrix

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg(name, default):
	if name in ARGV:
		return type(default)(ARGV[ARGV.index(name) + 1])
	return default


ROUND = arg("--round", 1)

ROOT = "C:/Roblox 3rd game/"
REF = ROOT + "reference/goo-lineage-web/assets/slime.base.navy.png"
OUT = ROOT + "art/models/slime_body/"
REV = OUT + "review/r%d/" % ROUND
os.makedirs(REV, exist_ok=True)

# ---------------------------------------------------------------- constants
ALPHA_THR = 0.5  # silhouette = painting alpha >= 0.5 (measured: body alpha 0.97-0.99, edge anti-aliased)
CENTRE_SMOOTH_ROWS = 6.0  # smoothing of the per-row centre line before straightening the lean (px rows)
SMOOTH_PX = 1.2  # smoothing of the measured contour along its length, painting px (removes pixel noise only)
FLAT_EPS = 0.003  # profile points lower than this (x height) are the flat contact disc
SEGMENTS = 40  # around the axis (9 deg; top-view outline error 0.3 % of the radius)
RINGS = 30  # profile rings from the tip down to the base contact ring; tris = 2 * SEGMENTS * RINGS
KAPPA0 = 1.5  # ring spacing ~ 1/sqrt(|curvature| + KAPPA0): equal chord sag, more rings at tip, shoulders, lip
OUTLINE_T = 0.011  # outline hull inflation (x height); the painting's dark rim is about 4 px of 372 (~1.1 %)
BONE_K = 1.5  # weight normaliser (x height): w_top = z/K, w_side = |x|/K; the game moves a bone by (s-1)*K*H
BODY_HEX = "1b4fd8"  # navy in src/shared/Colours.luau (the game's MeshPart.Color for this preview)
OUTLINE_DARK = 0.6 # outline colour = body colour (sRGB) x this; painting rim (2,22,119) vs body (0,70,212)
ROUGHNESS = 0.15  # SurfaceAppearance RoughnessMap value (glossy slime)
HL_FLOOR = 0.02  # painting red channel below this is body (navy has R ~ 0); above it, highlight whiteness
LIP = (0.2, 0.048, 0.012)  # lip ring: white alpha, centre height, sigma (x height); rows 359-371 of the painting
EDGE_FADE =(0.92, 0.985)  # overlay fades out between these fractions of the radius (painted streaks end by 0.88)
OV_RES = 1024  # overlay ColorMap size (brief: 1024 max)
UV_S = 1.16  # old front-projection frame, used only for the retired overlay map (see make_textures)
UV_ZC = 0.5
UV_ROWS = 256  # rows of uv_profile.json (the skin generator's r(v), z(v) table)
LIGHT = {"sky": [0.60, 0.74, 1.0], "ground": [0.50, 0.50, 0.55], "ambient": 0.9, "sun": 2.1, "sun_angle": 6}
FACE_Z = 0.51 # face centre height (x body height) in the original (docs/reference/04 and the brief)


# ---------------------------------------------------------------- image helpers
def load_rgba(path):
	img = bpy.data.images.load(path, check_existing=False)
	w, h = img.size
	arr = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1].copy()
	bpy.data.images.remove(img)
	return arr  # row 0 = top, raw sRGB values 0..1


def save_rgba(path, arr):
	h, w = arr.shape[:2]
	if arr.shape[2] == 3:
		arr = np.dstack([arr, np.ones((h, w), dtype=np.float32)])
	im = bpy.data.images.new("tmp_save", w, h, alpha=True)
	im.pixels.foreach_set(np.ascontiguousarray(arr[::-1], dtype=np.float32).ravel())
	im.filepath_raw = path
	im.file_format = "PNG"
	im.save()
	bpy.data.images.remove(im)


def sample(img2d, x, y):
	# bilinear; pixel i covers [i, i+1], its centre is i + 0.5; outside the image = 0
	h, w = img2d.shape
	fx = np.clip(x - 0.5, 0, w - 1.0001)
	fy = np.clip(y - 0.5, 0, h - 1.0001)
	x0 = np.floor(fx).astype(np.int64)
	y0 = np.floor(fy).astype(np.int64)
	tx = fx - x0
	ty = fy - y0
	v = (img2d[y0, x0] * (1 - tx) * (1 - ty) + img2d[y0, x0 + 1] * tx * (1 - ty)
		+ img2d[y0 + 1, x0] * (1 - tx) * ty + img2d[y0 + 1, x0 + 1] * tx * ty)
	v[(x < 0) | (x > w) | (y < 0) | (y > h)] = 0.0
	return v


def resize(arr, w, h):
	H0, W0 = arr.shape[:2]
	xs = (np.arange(w) + 0.5) * W0 / w
	ys = (np.arange(h) + 0.5) * H0 / h
	XX, YY = np.meshgrid(xs, ys)
	out = np.zeros((h, w, arr.shape[2]), dtype=np.float32)
	for c in range(arr.shape[2]):
		out[..., c] = sample(arr[..., c], XX.ravel(), YY.ravel()).reshape(h, w)
	return out


def gsmooth(a, sigma):
	if sigma < 0.3:
		return a.copy()
	k = int(4 * sigma) + 1
	t = np.arange(-k, k + 1)
	g = np.exp(-0.5 * (t / sigma) ** 2)
	g /= g.sum()
	return np.convolve(np.pad(a, k, mode="edge"), g, mode="valid")


def hex_srgb(h):
	return [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]


def srgb_lin(c):
	return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


# ---------------------------------------------------------------- 1. measure the painting
def measure():
	P = load_rgba(REF)
	Hh, W = P.shape[:2]
	A = P[..., 3]
	L = np.full(Hh, np.nan)
	R = np.full(Hh, np.nan)
	for r in range(Hh):
		row = A[r]
		idx = np.where(row >= ALPHA_THR)[0]
		if len(idx) == 0:
			continue
		i, j = idx[0], idx[-1]
		L[r] = (i - 0.5) + (ALPHA_THR - row[i - 1]) / (row[i] - row[i - 1]) if i > 0 else 0.0
		R[r] = (j + 0.5) + (row[j] - ALPHA_THR) / (row[j] - row[j + 1]) if j < W - 1 else float(W)
	rows = np.where(~np.isnan(L))[0]
	cr = np.interp(np.arange(Hh), rows, ((L + R) / 2)[rows])
	cs = gsmooth(cr, CENTRE_SMOOTH_ROWS)
	# one vertical axis: the x that best overlaps the painting's rows with symmetric rows of the same width
	best = (0, 0)
	for x0 in np.arange(W * 0.4, W * 0.6, 0.05):
		hw = (R[rows] - L[rows]) / 2
		inter = np.clip(np.minimum(R[rows], x0 + hw) - np.maximum(L[rows], x0 - hw), 0, None).sum()
		iou = inter / (2 * (R[rows] - L[rows]).sum() - inter)
		if iou > best[0]:
			best = (iou, x0)
	row_iou_ceiling, x0 = best
	# straighten the lean (shift every row so its centre sits on x0), then mirror-average
	xs = np.arange(W) + 0.5
	S = np.zeros_like(A)
	for r in range(Hh):
		S[r] = np.interp(xs - (x0 - cs[r]), xs, A[r], left=0, right=0)
	M = np.zeros_like(S)
	for r in range(Hh):
		M[r] = np.interp(2 * x0 - xs, xs, S[r], left=0, right=0)
	S = 0.5 * (S + M)
	# sub-pixel contour of the right half by rays from a centre inside the body (last crossing per ray)
	yc = float(rows[0] + 0.6 * (rows[-1] - rows[0]))
	th = np.linspace(np.pi / 2, -np.pi / 2, 2401)
	step = 0.05
	t = np.arange(0, max(W, Hh), step)
	X = x0 + np.outer(np.cos(th), t)
	Y = yc - np.outer(np.sin(th), t)
	V = sample(S, X.ravel(), Y.ravel()).reshape(X.shape)
	inside = V >= ALPHA_THR
	crossings = int((np.diff(inside.astype(np.int8), axis=1) == -1).sum(1).max())
	last = inside.shape[1] - 1 - np.argmax(inside[:, ::-1], axis=1)
	ii = np.arange(len(th))
	v0 = V[ii, last]
	v1 = V[ii, last + 1]
	tc = t[last] + step * (v0 - ALPHA_THR) / (v0 - v1)
	px = x0 + np.cos(th) * tc
	py = yc - np.sin(th) * tc
	px[0] = px[-1] = x0
	return dict(P=P, A=A, W=W, Hh=Hh, L=L, R=R, rows=rows, cs=cs, x0=float(x0), px=px, py=py,
		row_iou_ceiling=float(row_iou_ceiling), ray_crossings=crossings)


# ---------------------------------------------------------------- 2. the profile curve
def build_profile(m):
	px, py, x0 = m["px"], m["py"], m["x0"]
	ytop, ybot = float(py[0]), float(py[-1])
	Hpx = ybot - ytop
	r = (px - x0) / Hpx
	z = (ybot - py) / Hpx
	seg = np.hypot(np.diff(r), np.diff(z))
	s = np.concatenate([[0], np.cumsum(seg)])
	n = 4000
	su = np.linspace(0, s[-1], n)
	r = np.interp(su, s, r)
	z = np.interp(su, s, z)
	ds = su[1]
	e = 300  # mirror the curve through the axis at both ends so smoothing keeps the tip and base on the axis
	rE = np.concatenate([-r[1:e + 1][::-1], r, -r[-e - 1:-1][::-1]])
	zE = np.concatenate([z[1:e + 1][::-1], z, z[-e - 1:-1][::-1]])
	sig = (SMOOTH_PX / Hpx) / ds
	r = gsmooth(rE, sig)[e:e + n]
	z = gsmooth(zE, sig)[e:e + n]
	r[0] = 0.0
	z = z - z[-1]
	# flat contact disc: cut where the curve first comes within FLAT_EPS of the ground
	ic = int(np.argmax(z < FLAT_EPS))
	r = np.concatenate([r[:ic], [r[ic]]])
	z = np.concatenate([z[:ic], [0.0]])
	n = len(r)
	dr = np.gradient(r, ds)
	dz = np.gradient(z, ds)
	ddr = np.gradient(dr, ds)
	ddz = np.gradient(dz, ds)
	kap = np.abs(dr * ddz - dz * ddr) / np.power(dr * dr + dz * dz, 1.5)
	kap = gsmooth(kap, sig * 2)
	rho = np.sqrt(kap + KAPPA0)
	F = np.concatenate([[0], np.cumsum(0.5 * (rho[1:] + rho[:-1]))])
	F /= F[-1]
	idx = np.interp(np.linspace(0, 1, RINGS + 1), F, np.arange(n))
	ar = np.arange(n)
	pr = np.interp(idx, ar, r)
	pz = np.interp(idx, ar, z)
	tr = np.interp(idx, ar, dr)
	tz = np.interp(idx, ar, dz)
	tl = np.hypot(tr, tz)
	nr, nz = -tz / tl, tr / tl  # outward normal of a curve running from the tip down the right side
	nr[0], nz[0] = 0.0, 1.0
	nr[-1], nz[-1] = 0.0, -1.0
	# chord sag between rings, in painting px (how faceted the front silhouette can look)
	sag = 0.0
	for k in range(RINGS):
		a, b = int(math.floor(idx[k])), int(math.ceil(idx[k + 1]))
		P0 = np.array([pr[k], pz[k]])
		P1 = np.array([pr[k + 1], pz[k + 1]])
		d = P1 - P0
		dl = np.hypot(*d)
		if dl < 1e-9:
			continue
		q = np.stack([r[a:b + 1], z[a:b + 1]], 1) - P0
		sag = max(sag, float(np.abs(q[:, 0] * d[1] - q[:, 1] * d[0]).max() / dl))
	iw = int(np.argmax(r))
	return dict(r=r, z=z, pr=pr, pz=pz, nr=nr, nz=nz, Hpx=Hpx, ybot=ybot, ytop=ytop,
		height=float(z[0]), r_max=float(r[iw]), z_widest=float(z[iw]), r_contact=float(r[-1]),
		sag_px=sag * Hpx)


def radius_at(prof, zq):
	# radius of the dense profile at height zq on the upper/side branch (z decreasing along the curve)
	r, z = prof["r"], prof["z"]
	return float(np.interp(zq, z[::-1], r[::-1]))


def uv_rings(prof):
	# arc length along the mesh's own ring polyline (what the GPU interpolates the texture over): ring 0 = tip,
	# ring RINGS = the base contact ring, then the flat underside to the centre of the base
	pr, pz = np.asarray(prof["pr"]), np.asarray(prof["pz"])
	s = np.concatenate([[0.0], np.cumsum(np.hypot(np.diff(pr), np.diff(pz)))])  # from the tip
	L = float(s[-1] + math.hypot(pr[-1], pz[-1]))
	return {"s": s, "L": L, "v": 1.0 - s / L}


def write_uv_profile(prof, path, rows=UV_ROWS):
	# r(v), z(v) for the skin generator: row i is v = (i + 0.5) / rows from the base centre (v 0) to the tip (v 1);
	# image row = rows - 1 - i (image top = tip). Linear between rings, like the mesh.
	ru = uv_rings(prof)
	pr, pz, rv = np.asarray(prof["pr"]), np.asarray(prof["pz"]), ru["v"]
	vv = np.concatenate([[0.0], rv[::-1]])  # base centre, then the rings from the contact ring up to the tip
	rr = np.concatenate([[0.0], pr[::-1]])
	zz = np.concatenate([[0.0], pz[::-1]])
	v = (np.arange(rows) + 0.5) / rows
	data = {
		"about": "Goo Lineage V2 slime body UV (tools/blender/slime_body.py). u = angle about the vertical axis, "
		"seam at the back centre (u 0 = 1), front centre u 0.5, u grows toward the slime's own left (screen right "
		"in the front view). v = arc length from the centre of the base (0) up the underside and side to the tip "
		"(1); image top = tip. Body height 1. Surface distance: dv * L along the profile, du * 2 pi r(v) round it.",
		"L": ru["L"], "height": float(pz[0]), "v_contact": float(rv[-1]), "rows": rows,
		"v": [round(float(x), 6) for x in v],
		"r": [round(float(x), 6) for x in np.interp(v, vv, rr)],
		"z": [round(float(x), 6) for x in np.interp(v, vv, zz)],
		"rings": {"v": [round(float(x), 6) for x in rv], "r": [round(float(x), 6) for x in pr],
			"z": [round(float(x), 6) for x in pz]},
	}
	with open(path, "w") as f:
		json.dump(data, f, indent=1)
	return data


# ---------------------------------------------------------------- 3. the mesh
def reset_scene():
	for ob in list(bpy.data.objects):
		bpy.data.objects.remove(ob, do_unlink=True)
	for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.armatures):
		for d in list(coll):
			coll.remove(d)


def build_mesh(prof, name, inflate=0.0, flip=False):
	pr, pz, nr, nz = prof["pr"], prof["pz"], prof["nr"], prof["nz"]
	N = SEGMENTS
	verts, norms = [], []
	verts.append((0.0, 0.0, pz[0] + inflate))
	norms.append((0.0, 0.0, 1.0))
	ring_start = []
	for k in range(1, RINGS + 1):
		ring_start.append(len(verts))
		for j in range(N):
			ph = 2 * math.pi * j / N
			sx, sy = math.sin(ph), -math.cos(ph)
			rr = pr[k] + inflate * nr[k]
			zz = pz[k] + inflate * nz[k]
			verts.append((rr * sx, rr * sy, zz))
			norms.append((nr[k] * sx, nr[k] * sy, nz[k]))
	base = len(verts)
	verts.append((0.0, 0.0, -inflate))
	norms.append((0.0, 0.0, -1.0))
	faces = []
	r1 = ring_start[0]
	for j in range(N):
		faces.append((0, r1 + j, r1 + (j + 1) % N))
	for k in range(RINGS - 1):
		a, b = ring_start[k], ring_start[k + 1]
		for j in range(N):
			j1 = (j + 1) % N
			faces.append((a + j, b + j, b + j1, a + j1))
	rl = ring_start[-1]
	for j in range(N):
		faces.append((base, rl + (j + 1) % N, rl + j))
	if flip:
		faces = [tuple(reversed(f)) for f in faces]
		norms = [(-a, -b, -c) for (a, b, c) in norms]
	me = bpy.data.meshes.new(name)
	me.from_pydata(verts, [], faces)
	me.update()
	for p in me.polygons:
		p.use_smooth = True
	me.normals_split_custom_set_from_vertices(norms)
	# UV: cylindrical, all the way round. u = angle about the vertical axis, seam at the back centre (u 0 = 1),
	# front centre u 0.5, increasing toward the slime's own left (+X; screen right in the front view, so the
	# image is not mirrored from any side). v = arc length of the un-inflated ring polyline from the centre of
	# the base (v 0) up the underside and the side to the tip (v 1 = image top). The hull uses the same rows.
	ring_v = uv_rings(prof)["v"]
	vert_u, vert_v = [None], [1.0]  # tip pole: u from its face
	for k in range(1, RINGS + 1):
		for j in range(N):
			vert_u.append((j / N + 0.5) % 1.0)
			vert_v.append(float(ring_v[k]))
	vert_u.append(None)  # base centre pole
	vert_v.append(0.0)
	uv = me.uv_layers.new(name="UVMap")
	for p in me.polygons:
		cx = sum(verts[i][0] for i in p.vertices) / len(p.vertices)
		cy = sum(verts[i][1] for i in p.vertices) / len(p.vertices)
		uc = (math.atan2(cx, -cy) / (2 * math.pi) + 0.5) % 1.0
		for li in p.loop_indices:
			vi = me.loops[li].vertex_index
			u = vert_u[vi]
			if u is None:
				u = uc
			elif u - uc > 0.5:
				u -= 1.0
			elif u - uc < -0.5:
				u += 1.0
			uv.data[li].uv = (u, vert_v[vi])
	ob = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(ob)
	return ob


# ---------------------------------------------------------------- 4. rig
BONES = ["Root", "Base", "Top", "Left", "Right", "Front", "Back"]


def build_rig(prof):
	ad = bpy.data.armatures.new("SlimeRig")
	arm = bpy.data.objects.new("SlimeRig", ad)
	bpy.context.scene.collection.objects.link(arm)
	bpy.context.view_layer.objects.active = arm
	arm.select_set(True)
	bpy.ops.object.mode_set(mode="EDIT")
	H, rw, zw = prof["height"], prof["r_max"], prof["z_widest"]
	heads = {
		"Root": (0, 0, 0), "Base": (0, 0, 0), "Top": (0, 0, H),
		"Left": (rw, 0, zw), "Right": (-rw, 0, zw), "Front": (0, -rw, zw), "Back": (0, rw, zw),
	}
	lens = {"Root": 0.2, "Base": 0.1}
	root = None
	for n in BONES:
		eb = ad.edit_bones.new(n)
		h = Vector(heads[n])
		eb.head = h
		eb.tail = h + Vector((0, 0, lens.get(n, 0.08)))
		eb.roll = 0.0
		if n == "Root":
			root = eb
		else:
			eb.parent = root
			eb.use_connect = False
	bpy.ops.object.mode_set(mode="OBJECT")
	return arm, heads


def skin(ob, arm):
	# Exact affine squash/stretch from pure bone translations: w_top = z/K, w_left = max(x,0)/K, ...,
	# Base takes the rest. Moving Top by (sy-1)*K scales every height by sy about the ground; moving
	# Left/Right by +/-(sx-1)*K (and Front/Back the same) scales the width by sx about the axis.
	groups = {n: ob.vertex_groups.new(name=n) for n in BONES if n != "Root"}
	maxinf, minbase = 0, 1.0
	for v in ob.data.vertices:
		x, y, z = v.co
		w = {
			"Top": max(z, 0.0) / BONE_K,
			"Left": max(x, 0.0) / BONE_K, "Right": max(-x, 0.0) / BONE_K,
			"Front": max(-y, 0.0) / BONE_K, "Back": max(y, 0.0) / BONE_K,
		}
		w = {k: val for k, val in w.items() if val > 1e-6}
		w["Base"] = 1.0 - sum(w.values())
		minbase = min(minbase, w["Base"])
		maxinf = max(maxinf, len(w))
		for k, val in w.items():
			groups[k].add([v.index], val, "REPLACE")
	ob.parent = arm
	mod = ob.modifiers.new("Armature", "ARMATURE")
	mod.object = arm
	return maxinf, minbase


def set_pose(arm, sy=1.0, sx=1.0):
	for pb in arm.pose.bones:
		pb.matrix_basis = Matrix.Identity(4)
	d = (sx - 1.0) * BONE_K
	off = {"Top": (0, 0, (sy - 1.0) * BONE_K), "Left": (d, 0, 0), "Right": (-d, 0, 0),
		"Front": (0, -d, 0), "Back": (0, d, 0)}
	for n, o in off.items():
		pb = arm.pose.bones[n]
		pb.matrix = Matrix.Translation(Vector(o)) @ pb.bone.matrix_local
	bpy.context.view_layer.update()


def eval_bbox(ob):
	dg = bpy.context.evaluated_depsgraph_get()
	e = ob.evaluated_get(dg)
	me = e.to_mesh()
	co = np.array([v.co[:] for v in me.vertices])
	e.to_mesh_clear()
	return co.min(0), co.max(0)


# ---------------------------------------------------------------- 5. textures
def make_textures(m, prof, overlay=False):
	# The overlay (painted highlights) is retired: the owner wants all light from the game's light, and it was
	# drawn for the old front-projection UV. Kept behind a flag only to reproduce the round 1-4 renders.
	if overlay:
		make_overlay(m, prof)
	rough = np.full((256, 256, 4), ROUGHNESS, dtype=np.float32)
	rough[..., 3] = 1
	save_rgba(OUT + "SlimeBody_roughness.png", rough)
	nm = np.zeros((256, 256, 4), dtype=np.float32)
	nm[..., 0] = nm[..., 1] = 128 / 255
	nm[..., 2] = 1
	nm[..., 3] = 1
	save_rgba(OUT + "SlimeBody_normal.png", nm)


def make_overlay(m, prof):
	P, cs = m["P"], m["cs"]
	Hpx, ybot = prof["Hpx"], prof["ybot"]
	n = OV_RES
	u = (np.arange(n) + 0.5) / n
	X = u * UV_S - UV_S / 2
	Z = UV_ZC + UV_S / 2 - u * UV_S  # image row 0 (top) = highest Z
	XX, ZZ = np.meshgrid(X, Z)
	py = ybot - ZZ * Hpx
	cc = np.interp(py - 0.5, np.arange(len(cs)), cs)  # follow the painting's own centre line per row
	pxx = cc + XX * Hpx
	red = sample(P[..., 0], pxx.ravel(), py.ravel()).reshape(n, n)
	a = np.clip((red - HL_FLOOR) / (1.0 - HL_FLOOR), 0, 1)
	# the front projection degenerates where the surface turns sideways (|x| -> radius at that height):
	# fade the overlay out there so the painting's edge pixels do not smear across the sides and the back
	hw = np.array([radius_at(prof, zq) for zq in Z])[:, None]
	q = np.abs(XX) / np.maximum(hw, 1e-4)
	fade = np.clip((EDGE_FADE[1] - q) / (EDGE_FADE[1] - EDGE_FADE[0]), 0, 1)
	fade = fade * fade * (3 - 2 * fade)
	# the painting's bright lip ring near the base (central columns: B 150 at z 0.15 -> 222 at z 0.048 ->
	# 136 at the base outline); a ring of fixed height, so it reads the same from every side
	lip = LIP[0] * np.exp(-0.5 * ((ZZ - LIP[1]) / LIP[2]) ** 2)
	a = 1.0 - (1.0 - a) * (1.0 - lip)
	a = a * fade
	ov = np.ones((n, n, 4), dtype=np.float32)
	ov[..., 3] = a
	save_rgba(OUT + "SlimeBody_overlay.png", ov)


# ---------------------------------------------------------------- 6. materials (preview of the Roblox look)
def node(nt, t, loc=(0, 0)):
	n = nt.nodes.new(t)
	n.location = loc
	return n


def out_node(nt):
	return [n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"][0]


def mat_preview():
	mat = bpy.data.materials.new("SlimeBodyPreview")
	nt = mat.node_tree
	for n in list(nt.nodes):
		if n.type != "OUTPUT_MATERIAL":
			nt.nodes.remove(n)
	bsdf = node(nt, "ShaderNodeBsdfPrincipled", (200, 0))
	ro = node(nt, "ShaderNodeTexImage", (-500, -200))
	ro.image = bpy.data.images.load(OUT + "SlimeBody_roughness.png", check_existing=True)
	ro.image.colorspace_settings.name = "Non-Color"
	bsdf.inputs["Base Color"].default_value = srgb_lin(hex_srgb(BODY_HEX)) + [1.0]
	nt.links.new(ro.outputs["Color"], bsdf.inputs["Roughness"])
	nt.links.new(bsdf.outputs[0], out_node(nt).inputs["Surface"])
	return mat


def mat_flat(name, srgb, alpha_backface=False):
	mat = bpy.data.materials.new(name)
	nt = mat.node_tree
	for n in list(nt.nodes):
		if n.type != "OUTPUT_MATERIAL":
			nt.nodes.remove(n)
	em = node(nt, "ShaderNodeEmission")
	em.inputs["Color"].default_value = srgb_lin(srgb) + [1.0]
	if alpha_backface:
		geo = node(nt, "ShaderNodeNewGeometry")
		tr = node(nt, "ShaderNodeBsdfTransparent")
		mx = node(nt, "ShaderNodeMixShader")
		nt.links.new(geo.outputs["Backfacing"], mx.inputs[0])
		nt.links.new(em.outputs[0], mx.inputs[1])
		nt.links.new(tr.outputs[0], mx.inputs[2])
		nt.links.new(mx.outputs[0], out_node(nt).inputs["Surface"])
	else:
		nt.links.new(em.outputs[0], out_node(nt).inputs["Surface"])
	return mat


def mat_clay():
	mat = bpy.data.materials.new("Clay")
	bsdf = [n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"]
	if not bsdf:
		bsdf = [node(mat.node_tree, "ShaderNodeBsdfPrincipled")]
		mat.node_tree.links.new(bsdf[0].outputs[0], out_node(mat.node_tree).inputs["Surface"])
	bsdf[0].inputs["Base Color"].default_value = (0.6, 0.6, 0.62, 1)
	bsdf[0].inputs["Roughness"].default_value = 0.55
	return mat


def mat_export(name):
	mat = bpy.data.materials.new(name)  # plain, no textures: the look is set in Studio (SurfaceAppearance)
	return mat


# ---------------------------------------------------------------- 7. scene, cameras, renders
def sun_from_streak(m, prof):
	# point the preview sun so its real glint lands in the painting's big upper-left streak
	P, x0, Hpx, ybot = m["P"], m["x0"], prof["Hpx"], prof["ybot"]
	ys, xs = np.mgrid[0:P.shape[0], 0:P.shape[1]]
	box = (P[..., 0] > 0.6) & (xs < x0 - 30) & (ys > ybot - 0.8 * Hpx) & (ys < ybot - 0.5 * Hpx)
	cx, cy = xs[box].mean() + 0.5, ys[box].mean() + 0.5
	X = (cx - x0) / Hpx
	Z = (ybot - cy) / Hpx
	r = radius_at(prof, Z)
	Y = -math.sqrt(max(r * r - X * X, 0.0))
	drdz = (radius_at(prof, Z + 0.005) - radius_at(prof, Z - 0.005)) / 0.01
	n = Vector((X / r, Y / r, -drdz)).normalized()  # gradient of rho - r(z)
	V = Vector((0, -1, 0))
	L = (2 * n.dot(V) * n - V).normalized()
	return L, (float(cx), float(cy))


def setup_render(sun_dir):
	sc = bpy.context.scene
	for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
		try:
			sc.render.engine = eng
			break
		except TypeError:
			pass
	sc.render.film_transparent = True
	sc.view_settings.view_transform = "Standard"
	sc.view_settings.look = "None"
	sc.render.image_settings.file_format = "PNG"
	sc.render.image_settings.color_mode = "RGBA"
	sc.render.resolution_percentage = 100
	try:
		sc.eevee.taa_render_samples = 64
	except AttributeError:
		pass
	w = bpy.data.worlds.new("World")
	sc.world = w
	if bpy.app.version < (5, 0, 0):
		w.use_nodes = True
	nt = w.node_tree
	bg = [n for n in nt.nodes if n.type == "BACKGROUND"][0]
	# outdoor ambient like a Roblox day: bright sky above, darker ground bounce below
	tc = node(nt, "ShaderNodeTexCoord")
	sep = node(nt, "ShaderNodeSeparateXYZ")
	mr = node(nt, "ShaderNodeMapRange")
	mr.inputs["From Min"].default_value = -0.3
	mr.inputs["From Max"].default_value = 0.6
	mx = node(nt, "ShaderNodeMix")
	mx.data_type = "RGBA"
	cin = [s for s in mx.inputs if s.type == "RGBA"]
	cin[0].default_value = srgb_lin(LIGHT["ground"]) + [1]
	cin[1].default_value = srgb_lin(LIGHT["sky"]) + [1]
	nt.links.new(tc.outputs["Generated"], sep.inputs[0])
	nt.links.new(sep.outputs["Z"], mr.inputs["Value"])
	nt.links.new(mr.outputs["Result"], mx.inputs[0])
	nt.links.new([s for s in mx.outputs if s.type == "RGBA"][0], bg.inputs["Color"])
	bg.inputs["Strength"].default_value = LIGHT["ambient"]
	sd = bpy.data.lights.new("Sun", "SUN")
	sd.energy = LIGHT["sun"]
	sd.angle = math.radians(LIGHT["sun_angle"])
	sun = bpy.data.objects.new("Sun", sd)
	sc.collection.objects.link(sun)
	sun.rotation_euler = (-Vector(sun_dir)).to_track_quat("-Z", "Y").to_euler()


def camera(name, loc, rot=None, target=None, ortho=None, fit="AUTO", lens=50):
	cd = bpy.data.cameras.new(name)
	cam = bpy.data.objects.new(name, cd)
	bpy.context.scene.collection.objects.link(cam)
	cam.location = loc
	if target is not None:
		cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
	else:
		cam.rotation_euler = [math.radians(a) for a in rot]
	if ortho:
		cd.type = "ORTHO"
		cd.ortho_scale = ortho
	else:
		cd.lens = lens
	cd.sensor_fit = fit
	cd.clip_end = 100
	return cam


def render(cam, path, w, h):
	sc = bpy.context.scene
	sc.camera = cam
	sc.render.resolution_x = w
	sc.render.resolution_y = h
	sc.render.filepath = path
	bpy.ops.render.render(write_still=True)
	return path


def over_bg(rgba, bg=0.93):
	a = rgba[..., 3:4]
	return np.dstack([rgba[..., :3] * a + bg * (1 - a), np.ones(rgba.shape[:2] + (1,), dtype=np.float32)])


def hstack(tiles, gap=8):
	h = max(t.shape[0] for t in tiles)
	out = []
	for i, t in enumerate(tiles):
		if t.shape[0] < h:
			t = np.vstack([t, np.ones((h - t.shape[0],) + t.shape[1:], dtype=np.float32)])
		out.append(t)
		if i < len(tiles) - 1:
			out.append(np.ones((h, gap, 4), dtype=np.float32))
	return np.hstack(out)


# ---------------------------------------------------------------- main
def main():
	reset_scene()
	m = measure()
	prof = build_profile(m)
	W, Hh, Hpx, ybot, x0 = m["W"], m["Hh"], prof["Hpx"], prof["ybot"], m["x0"]
	print("[slime_body] axis x0 %.2f px, Hpx %.2f, ytop %.2f, ybot %.2f, row-IoU ceiling %.4f, ray crossings %d"
		% (x0, Hpx, prof["ytop"], ybot, m["row_iou_ceiling"], m["ray_crossings"]))

	make_textures(m, prof)

	body = build_mesh(prof, "SlimeBody")
	hull = build_mesh(prof, "SlimeBodyOutline", inflate=OUTLINE_T * prof["height"], flip=True)
	arm, heads = build_rig(prof)
	maxinf_b, minbase_b = skin(body, arm)
	maxinf_h, minbase_h = skin(hull, arm)
	uvp = write_uv_profile(prof, OUT + "uv_profile.json")
	uv_check = {}
	for ob in (body, hull):
		uvd = ob.data.uv_layers[0].data
		areas = []
		for p in ob.data.polygons:
			q = [uvd[li].uv for li in p.loop_indices]
			areas.append(sum(q[i].x * q[(i + 1) % len(q)].y - q[(i + 1) % len(q)].x * q[i].y for i in range(len(q))))
		areas = np.array(areas)
		uv_check[ob.name] = {"faces_ccw": int((areas > 0).sum()), "faces_cw": int((areas < 0).sum()),
			"faces_zero": int((areas == 0).sum()), "uv_area": float(np.abs(areas).sum() / 2)}
	print("[slime_body] UV L %.4f, v_contact %.4f, check %s" % (uvp["L"], uvp["v_contact"], uv_check))

	m_prev = mat_preview()
	m_hull = mat_flat("OutlinePreview", [c * OUTLINE_DARK for c in hex_srgb(BODY_HEX)], alpha_backface=True)
	m_wire = mat_flat("Wire", [0.05, 0.05, 0.08])
	m_clay = mat_clay()
	body.data.materials.append(m_prev)
	hull.data.materials.append(m_hull)
	hull.visible_shadow = False

	# wire overlay object (renders only)
	wire = bpy.data.objects.new("WireView", body.data.copy())
	bpy.context.scene.collection.objects.link(wire)
	wire.parent = arm
	am = wire.modifiers.new("Armature", "ARMATURE")
	am.object = arm
	wm = wire.modifiers.new("Wire", "WIREFRAME")
	wm.thickness = 0.0035
	wm.use_replace = True
	wire.data.materials.clear()
	wire.data.materials.append(m_wire)
	wire.hide_render = True
	wire.visible_shadow = False

	# ---- exports (rest pose, plain materials)
	set_pose(arm)
	bpy.ops.object.select_all(action="DESELECT")
	body.data.materials[0] = mat_export("SlimeBody")
	hull.data.materials[0] = mat_export("SlimeBodyOutline")
	fbx = dict(use_selection=True, object_types={"ARMATURE", "MESH"}, axis_forward="-Z", axis_up="Y",
		apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True,
		bake_space_transform=False, add_leaf_bones=False, primary_bone_axis="Y", secondary_bone_axis="X",
		use_armature_deform_only=False, bake_anim=False, mesh_smooth_type="OFF", use_mesh_modifiers=False,
		use_tspace=False, path_mode="AUTO", embed_textures=False)
	for ob, fn in ((body, "SlimeBody.fbx"), (hull, "SlimeBodyOutline.fbx")):
		bpy.ops.object.select_all(action="DESELECT")
		arm.select_set(True)
		ob.select_set(True)
		bpy.context.view_layer.objects.active = arm
		bpy.ops.export_scene.fbx(filepath=OUT + fn, **fbx)
	body.data.materials[0] = m_prev
	hull.data.materials[0] = m_hull

	# ---- deformation check: the evaluated box must scale exactly
	deform = {}
	for name, sy, sx in (("rest", 1, 1), ("squash", 0.52, 1.5), ("stretch", 1.32, 0.82)):
		set_pose(arm, sy, sx)
		lo, hi = eval_bbox(body)
		deform[name] = {"sy": sy, "sx": sx, "height": float(hi[2] - lo[2]), "width_x": float(hi[0] - lo[0]),
			"depth_y": float(hi[1] - lo[1]), "min_z": float(lo[2])}
	set_pose(arm)

	# ---- renders
	sun_dir, streak_px = sun_from_streak(m, prof)
	setup_render(sun_dir)
	fit = "VERTICAL" if Hh >= W else "HORIZONTAL"
	osc = max(Hh, W) / Hpx
	cxm = (W / 2 - x0) / Hpx
	czm = (ybot - Hh / 2) / Hpx
	cam_front = camera("CamFront", (cxm, -10, czm), rot=(90, 0, 0), ortho=osc, fit=fit)
	cam_side = camera("CamSide", (10, 0, czm), rot=(90, 0, 90), ortho=osc, fit=fit)
	cam_back = camera("CamBack", (0, 10, czm), rot=(90, 0, 180), ortho=osc, fit=fit)
	cam_top = camera("CamTop", (0, 0, 10), rot=(0, 0, 0), ortho=osc, fit=fit)
	el, az, dist = math.radians(38), math.radians(28), 2.3
	cam_game = camera("CamGame", (-math.sin(az) * math.cos(el) * dist, -math.cos(az) * math.cos(el) * dist,
		0.45 + math.sin(el) * dist), target=(0, 0, 0.42), lens=50)
	cam_gback = camera("CamGameBack", (math.sin(az) * math.cos(el) * dist, math.cos(az) * math.cos(el) * dist,
		0.45 + math.sin(el) * dist), target=(0, 0, 0.42), lens=50)
	cam_dfront = camera("CamDeformFront", (0, -10, 0.62), rot=(90, 0, 0), ortho=1.9)
	cam_dgame = camera("CamDeformGame", (-math.sin(az) * math.cos(el) * 4.2, -math.cos(az) * math.cos(el) * 4.2,
		0.5 + math.sin(el) * 4.2), target=(0, 0, 0.5), lens=50)

	rw, rh = 2 * W, 2 * Hh
	R = {}
	R["front_hull"] = render(cam_front, REV + "front_hull.png", rw, rh)
	hull.hide_render = True
	R["front"] = render(cam_front, REV + "front.png", rw, rh)
	R["side"] = render(cam_side, REV + "side.png", rw, rh)
	R["back"] = render(cam_back, REV + "back.png", rw, rh)
	R["top"] = render(cam_top, REV + "top.png", rw, rh)
	R["game"] = render(cam_game, REV + "game.png", 800, 800)
	R["game_back"] = render(cam_gback, REV + "game_back.png", 800, 800)
	hull.hide_render = False
	R["game_hull"] = render(cam_game, REV + "game_hull.png", 800, 800)
	R["side_hull"] = render(cam_side, REV + "side_hull.png", rw, rh)
	for name, sy, sx in (("squash", 0.52, 1.5), ("stretch", 1.32, 0.82)):
		set_pose(arm, sy, sx)
		R[name + "_front"] = render(cam_dfront, REV + name + "_front.png", 640, 640)
		R[name + "_game"] = render(cam_dgame, REV + name + "_game.png", 640, 640)
	set_pose(arm)
	R["rest_front"] = render(cam_dfront, REV + "rest_front.png", 640, 640)
	R["rest_game"] = render(cam_dgame, REV + "rest_game.png", 640, 640)
	# wire views: clay body + wire
	hull.hide_render = True
	body.data.materials[0] = m_clay
	R["clay_top"] = render(cam_top, REV + "clay_top.png", rw, rh)
	R["clay_game"] = render(cam_game, REV + "clay_game.png", 800, 800)
	wire.hide_render = False
	R["wire_front"] = render(cam_front, REV + "wire_front.png", rw, rh)
	R["wire_game"] = render(cam_game, REV + "wire_game.png", 800, 800)
	R["wire_top"] = render(cam_top, REV + "wire_top.png", rw, rh)
	wire.hide_render = True
	body.data.materials[0] = m_prev
	hull.hide_render = False

	# ---- measure the front render against the painting
	A = m["A"]
	ref_mask = A >= ALPHA_THR
	fr = load_rgba(R["front"])
	fa = fr[..., 3].reshape(Hh, 2, W, 2).mean((1, 3))
	ren_mask = fa >= ALPHA_THR
	inter = (ref_mask & ren_mask).sum()
	iou = float(inter / (ref_mask | ren_mask).sum())
	fh = load_rgba(R["front_hull"])
	fha = fh[..., 3].reshape(Hh, 2, W, 2).mean((1, 3)) >= ALPHA_THR
	iou_hull = float((ref_mask & fha).sum() / (ref_mask | fha).sum())
	# width per height band (render vs painting), px of the painting
	bands = []
	for zf in (0.02, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.85, 0.9, 0.95, 0.98):
		row = int(round(ybot - zf * Hpx - 0.5))
		rp = np.where(ref_mask[row])[0]
		rr = np.where(ren_mask[row])[0]
		wp = int(rp[-1] - rp[0] + 1) if len(rp) else 0
		wr = int(rr[-1] - rr[0] + 1) if len(rr) else 0
		cp = (rp[-1] + rp[0]) / 2 if len(rp) else 0
		crr = (rr[-1] + rr[0]) / 2 if len(rr) else 0
		bands.append({"z": zf, "row": row, "w_paint": wp, "w_model": wr, "dw_px": wr - wp,
			"centre_paint": float(cp), "centre_model": float(crr)})
	rows_ref = np.where(ref_mask.any(1))[0]
	rows_ren = np.where(ren_mask.any(1))[0]
	cols_ref = np.where(ref_mask.any(0))[0]
	cols_ren = np.where(ren_mask.any(0))[0]
	aspect_ref = (cols_ref[-1] - cols_ref[0] + 1) / (rows_ref[-1] - rows_ref[0] + 1)
	aspect_ren = (cols_ren[-1] - cols_ren[0] + 1) / (rows_ren[-1] - rows_ren[0] + 1)
	# colour per height band, median sRGB 0-255 over the middle of the body, highlights left out
	colour = {}
	frr = resize(fr, W, Hh)
	for name, z0, z1 in (("upper", 0.62, 0.75), ("middle", 0.40, 0.55), ("lower", 0.12, 0.25)):
		ys, xs = np.mgrid[0:Hh, 0:W]
		box = ((ys > ybot - z1 * Hpx) & (ys < ybot - z0 * Hpx) & (np.abs(xs + 0.5 - x0) < 0.2 * Hpx)
			& (m["P"][..., 0] < 0.08) & ref_mask & (frr[..., 3] > 0.9))
		colour[name] = {"painting": [int(v) for v in np.median(m["P"][box][:, :3], 0) * 255],
			"render": [int(v) for v in np.median(frr[box][:, :3], 0) * 255]}
	print("[slime_body] colour", colour)

	# ---- comparison sheets
	P = m["P"]
	paint2 = over_bg(resize(P, rw, rh))
	tile = lambda p: over_bg(load_rgba(p))
	ov = np.ones((Hh, W, 4), dtype=np.float32)
	both = ref_mask & ren_mask
	ov[both, :3] = 0.72
	ov[ref_mask & ~ren_mask, :3] = (1.0, 0.15, 0.15)
	ov[~ref_mask & ren_mask, :3] = (0.1, 0.55, 1.0)
	ov2 = np.repeat(np.repeat(ov, 2, 0), 2, 1)
	sheet1 = hstack([paint2, tile(R["front_hull"]), tile(R["front"]), ov2])
	save_rgba(REV + "sheet_front.png", sheet1)
	g = lambda p: resize(over_bg(load_rgba(p)), 600, 600)
	sq = lambda p: resize(over_bg(load_rgba(p)), 600, int(600 * rh / rw))
	sheet2 = hstack([sq(R["side"]), sq(R["back"]), sq(R["top"]), g(R["game"]), g(R["game_back"]), g(R["game_hull"])])
	save_rgba(REV + "sheet_views.png", sheet2)
	d = lambda p: over_bg(load_rgba(p))
	sheet3 = hstack([d(R["rest_front"]), d(R["squash_front"]), d(R["stretch_front"]),
		d(R["rest_game"]), d(R["squash_game"]), d(R["stretch_game"])])
	save_rgba(REV + "sheet_deform.png", sheet3)
	sheet4 = hstack([sq(R["wire_front"]), g(R["wire_game"]), sq(R["wire_top"]), sq(R["clay_top"]), g(R["clay_game"])])
	save_rgba(REV + "sheet_wire.png", sheet4)

	# ---- numbers
	tris_b = sum(len(p.vertices) - 2 for p in body.data.polygons)
	tris_h = sum(len(p.vertices) - 2 for p in hull.data.polygons)
	face_r = radius_at(prof, FACE_Z * prof["height"])
	metrics = {
		"round": ROUND, "reference": REF, "image_px": [W, Hh],
		"axis_x0_px": x0, "body_height_px": Hpx, "ground_row_px": ybot, "top_row_px": prof["ytop"],
		"row_iou_ceiling_symmetric": m["row_iou_ceiling"], "ray_crossings_max": m["ray_crossings"],
		"iou_front_body": iou, "iou_front_body_plus_outline": iou_hull,
		"aspect_w_over_h": {"painting": float(aspect_ref), "model": float(aspect_ren)},
		"bands": bands, "colour_median_srgb": colour, "streak_centre_px": streak_px,
		"sun_dir_to_light": list(sun_dir),
		"model": {"height": prof["height"], "r_max": prof["r_max"], "z_widest": prof["z_widest"],
			"r_contact": prof["r_contact"], "ring_sag_px": prof["sag_px"],
			"rings": [[round(float(a), 4), round(float(b), 4)] for a, b in zip(prof["pr"], prof["pz"])]},
		"tris_body": tris_b, "tris_outline": tris_h, "verts_body": len(body.data.vertices),
		"max_influences": max(maxinf_b, maxinf_h), "min_base_weight": min(minbase_b, minbase_h),
		"bones_blender": {k: list(v) for k, v in heads.items()}, "bone_k": BONE_K,
		"deform": deform, "uv": {"L": uvp["L"], "v_contact": uvp["v_contact"], "check": uv_check},
		"face_centre": {"z": FACE_Z * prof["height"], "front_surface_y": -face_r},
	}
	with open(REV + "metrics.json", "w") as f:
		json.dump(metrics, f, indent=1)
	print("[slime_body] IoU body %.4f, body+outline %.4f, tris %d / %d, sag %.2f px"
		% (iou, iou_hull, tris_b, tris_h, prof["sag_px"]))

	bpy.ops.wm.save_as_mainfile(filepath=OUT + "SlimeBody.blend")


if __name__ == "__main__":
	main()
