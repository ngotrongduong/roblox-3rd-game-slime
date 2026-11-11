# The Frozen Ice seven for tools/blender/monster_rig.py (exec'd into its namespace). Parts move by generic_move's rule
# (drives "<Part>.p/.r/.y", ".x/.f/.z", ".o", ".spin").
import bmesh

DISC = {}


def _disc_frame(co):
	"""A disc's middle (the middle of its extent in its own plane), its normal (facing -y) and the in-plane radius."""
	c, ax, sp = pca(co)
	nrm = ax[2] if ax[2][1] < 0 else -ax[2]
	u = ax[0]
	v = np.cross(nrm, u)
	rel = co - c
	pu, pv = rel @ u, rel @ v
	c = c + u * (np.percentile(pu, 2) + np.percentile(pu, 98)) / 2 + v * (np.percentile(pv, 2) + np.percentile(pv, 98)) / 2
	rel = co - c
	rad = rel - np.outer(rel @ nrm, nrm)
	return c, nrm, u, v, np.linalg.norm(rad, axis=1), np.arctan2(rad @ v, rad @ u)


def pre_rimesaw(ob):
	"""The blade ring is cut free of the disc along its inner rim (an edge split, no vertex moved), so it can spin
	without dragging the disc: each face goes to the ring when its middle lies beyond the cut radius, set just inside
	the notches between the blades."""
	me = ob.data
	bm = bmesh.new()
	bm.from_mesh(me)
	co = np.array([v.co[:] for v in bm.verts])
	c, nrm, u, v, r, ang = _disc_frame(co)
	B = 72
	bi = ((ang % TAU) / TAU * B).astype(int) % B
	outline = np.array([np.percentile(r[bi == b], 97) if (bi == b).sum() > 1 else 0 for b in range(B)])
	rmax = float(np.percentile(r, 98))
	rn = float(np.percentile(outline[outline > 0], 8))
	r_cut = 0.9 * rn
	ring = set()
	for f in bm.faces:
		fc = np.mean([co[vv.index] for vv in f.verts], axis=0) - c
		fr = np.linalg.norm(fc - (fc @ nrm) * nrm)
		if fr > r_cut:
			ring.add(f.index)
	edges = [e for e in bm.edges if len(e.link_faces) == 2 and ((e.link_faces[0].index in ring) != (e.link_faces[1].index in ring))]
	bmesh.ops.split_edges(bm, edges=edges)
	bm.to_mesh(me)
	bm.free()
	me.update()
	DISC.update(c=c, nrm=nrm, r_cut=r_cut)
	print(f"CUT Rimesaw disc middle {np.round(c, 2).tolist()} facing {np.round(nrm, 2).tolist()} outer radius {rmax:.2f}, notches at {rn:.2f}, ring cut at {r_cut:.2f}: {len(ring)} faces, {len(edges)} edges split")


def mirror_sel(m, sel, cx, tol):
	"""The vertices whose mirror image across x = cx lies within tol of the selection (the other side's twin part)."""
	from mathutils import kdtree
	pts = m.co[sel]
	kd = kdtree.KDTree(len(pts))
	for i, p in enumerate(pts):
		kd.insert(Vector(p), i)
	kd.balance()
	out = np.zeros(m.n, bool)
	for i, p in enumerate(m.co):
		if kd.find(Vector((2 * cx - p[0], p[1], p[2])))[2] < tol:
			out[i] = True
	return out


def mx(p, cx):
	return (2 * cx - p[0], p[1], p[2])


# ---------------------------------------------------------------- rigs
@monster("Frostnip", 3000, role="swarmer")
def rig_frostnip(m):
	z = m.co[:, 2]
	H = float(z.max())
	white = (m.sat < 0.3) & (z > 0.35 * H)
	lab = m.components(white)
	cap = np.zeros(m.n, bool)
	for k in range(lab.max() + 1):
		if (lab == k).sum() >= 10:
			cap |= lab == k
	lo, hi, c = _lohi(m, cap)
	print(f"JOINT Frostnip snow cap {int(cap.sum())} vertices from z {lo[2]:.2f}")
	return [part("Cap", "Top", (c[0], c[1], lo[2]), soften(m, cap.astype(float), 2), tail=(c[0], c[1], hi[2]))]


@monster("Rimesaw", 3000, role="hunter", pre=pre_rimesaw)
def rig_rimesaw(m):
	c, nrm, r_cut = DISC["c"], DISC["nrm"], DISC["r_cut"]
	rel = m.co - c
	r = np.linalg.norm(rel - np.outer(rel @ nrm, nrm), axis=1)
	blades = np.zeros(m.n, bool)
	for k in set(m.island.tolist()):
		s = m.island == k
		if r[s].mean() > r_cut:
			blades |= s
	m.info["cage_sel"] = ~blades
	print(f"JOINT Rimesaw blade ring {int(blades.sum())} vertices, spin axis {np.round(nrm, 2).tolist()}")
	bp = part("Blades", "Body", c, blades.astype(float), tail=Vector(c) + Vector(nrm))
	bp["spin_axis"] = Vector(nrm)
	return [bp]


@monster("Shardspire", 3000, role="spitter", mid=True)
def rig_shardspire(m):
	z = m.co[:, 2]
	main = m.island == m.main
	loose = ~main
	zc = float(np.percentile(z[loose], 5)) + 0.1
	crown = loose | (main & (z > zc))
	lo, hi, c = _lohi(m, main & (z < zc))
	print(f"JOINT Shardspire crown from z {zc:.2f} (the loose crystals' foot), {int(crown.sum())} vertices")
	return [part("Crown", "Top", (c[0], c[1], zc), soften(m, crown.astype(float), 2), tail=(c[0], c[1], float(z.max())))]


@monster("Snowshroud", 3000, role="healer")
def rig_snowshroud(m):
	z = m.co[:, 2]
	H = float(z.max())
	main = m.island == m.main
	zh = 0.55 * H  # inferred: the hood's shoulder in the side view
	zt = 0.8 * H
	hood = main & (z > zh - 0.25)
	base_pt = m.co[main & (np.abs(z - zt) < 0.08)].mean(0)
	tparts, tot = geo_chain(m, main & (z > zt - 0.05), base_pt, ["HoodTip1", "HoodTip2"], "Hood", fade=0.2, label="Snowshroud hood tip")
	w = np.where(main, np.array([sstep(zh - 0.25, zh + 0.15, x) for x in z]), 0.0)
	w = np.clip(w - tot, 0, 1)
	lo, hi, c = _lohi(m, main)
	print(f"JOINT Snowshroud hood from z {zh:.2f}, tip from z {zt:.2f}")
	return [part("Hood", "Top", (c[0], c[1], zh), w, tail=base_pt)] + tparts


@monster("Icebound", 3000, role="armoured")
def rig_icebound(m):
	z = m.co[:, 2]
	y = m.co[:, 1]
	main = m.island == m.main
	zp = 0.35  # inferred: the puddle's top in the side view (the block stands on it)
	puddle = main & ((z < zp) | ((y < -2.1) & (z < 0.9)))
	block = ~puddle
	for k in set(m.island.tolist()) - {m.main}:
		s = m.island == k
		if m.co[s, 2].mean() < 0.45:
			block &= ~s
			puddle |= s
	w = soften(m, block.astype(float), 2)
	lo, hi, c = _lohi(m, block)
	m.info["cage_sel"] = puddle
	m.info["cage_thin"] = True
	bp = part("Block", "Body", (c[0], c[1], lo[2]), w, tail=(c[0], c[1], hi[2]))
	bp["half_depth"] = float((hi[1] - lo[1]) / 2)
	bp["half_width"] = float((hi[0] - lo[0]) / 2)
	print(f"JOINT Icebound block {int(block.sum())} vertices box {np.round(lo, 2).tolist()}..{np.round(hi, 2).tolist()}, puddle {int(puddle.sum())}")
	return [bp]


@monster("Rimetusk", 6000, role="miniboss")
def rig_rimetusk(m):
	x, y, z = m.co.T
	H = float(z.max())
	main = m.island == m.main
	lo, hi, c = _lohi(m, main)
	parts = []
	tusks = np.zeros(m.n, bool)
	cx = float(c[0])
	tusks = np.zeros(m.n, bool)
	for name, sg in (("TuskL", 1), ("TuskR", -1)):
		# what stands out in front of the face, low down, on its own side (the tusk's walk found y -5.75..-4.66 with the
		# body front at about -4.6; colour does not help, the whole front is saturated): the largest connected piece there
		zone = (y < lo[1] + 1.0) & (z < 0.6 * H) & ((x - cx) * sg > 0.3)
		lab = m.components(zone)
		k = int(np.argmax([(lab == j).sum() for j in range(lab.max() + 1)]))
		sel = lab == k
		tip = int(np.nonzero(sel)[0][np.argmin(z[sel])])
		top = m.co[sel][m.co[sel][:, 2] > np.percentile(z[sel], 80)].mean(0)
		parts.append(part(name, "Front", top, soften(m, sel.astype(float), 2), tail=m.co[tip]))
		tusks |= sel
		print(f"JOINT Rimetusk {name} {int(sel.sum())} vertices root {np.round(top, 2).tolist()} tip {np.round(m.co[tip], 2).tolist()}")
	zm = 0.55 * H
	w = np.where(main & ~tusks, np.array([sstep(zm - 0.5, zm + 0.5, a) * sstep(-1.5, 0.0, b) for a, b in zip(z, y)]), 0.0)
	for k in set(m.island.tolist()) - {m.main}:
		s = m.island == k
		if m.co[s, 2].mean() > 0.5 * H:
			w[s] = 1.0
	print(f"JOINT Rimetusk mane from z {zm:.2f} behind y -1.5, {int((w > 0.5).sum())} vertices")
	parts.insert(0, part("Mane", "Top", (c[0], 0.0, zm), w, tail=(c[0], 1.0, H)))
	return parts


@monster("Frostmaw", 8000, role="boss")
def rig_frostmaw(m):
	x, z = m.co[:, 0], m.co[:, 2]
	H = float(z.max())
	parts = []
	cx = float((x.max() + x.min()) / 2)
	zl = 0.58 * H  # measured: the left horn's protrusion walk found its foot at z 5.76 of 10
	for name, sg in (("HornL", 1), ("HornR", -1)):
		zone = (z > zl) & ((x - cx) * sg > 2.8)  # 2.8: where the horn leaves the head (the walk's inner edge, x 2.81)
		lab = m.components(zone)
		k = int(np.argmax([(lab == j).sum() for j in range(lab.max() + 1)]))
		sel = lab == k
		inner = sel & ((x - cx) * sg < 3.3)
		base = m.co[inner].mean(0) if inner.any() else m.co[sel].mean(0)
		tip = int(np.nonzero(sel)[0][np.argmax((x[sel] - cx) * sg)])
		parts.append(part(name, "Top", base, soften(m, sel.astype(float), 2), tail=m.co[tip]))
		print(f"JOINT Frostmaw {name} {int(sel.sum())} vertices root {np.round(base, 2).tolist()} tip {np.round(m.co[tip], 2).tolist()}")
	print("JOINT Frostmaw jaw: no clean cut (the lower jaw is the body's own front, one surface with the gaping mouth), the roar opens through the cage")
	return parts


# ---------------------------------------------------------------- motions
def mo_frostnip(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.2)

	def p_idle(t, c):
		return {"Cap.z": 0.2 * H * (c["squash"] - ch(idle, t, "squash", 0.15, Ti)), "Cap.p": -0.5 * (ch(idle, t, "pitch", 0.2, Ti) - 0.05)}

	def p_move(t, c):
		return {"Cap.z": 0.35 * (ch(move, t, "lift", 0.07, Tm) - c["lift"]), "Cap.p": -0.7 * ch(move, t, "pitch", 0.1, Tm)}

	def attack(t):  # a twisting nip: it winds to one side and snaps across
		return C(fwd=keys(t, [(0, 0), (0.25, 0.25), (0.38, -1.1), (0.55, -1.0), (0.9, 0)]), yaw=keys(t, [(0, 0), (0.25, -0.25), (0.4, 0.2), (0.6, 0), (0.9, 0)]),
			squash=keys(t, [(0, 0), (0.25, 0.2), (0.36, -0.2), (0.44, 0.12), (0.55, 0)]), pitch=keys(t, [(0, 0), (0.25, -0.15), (0.4, 0.3), (0.9, 0)]),
			lift=0.25 * hump(t, 0.26, 0.42)), {}

	def p_attack(t, c):
		return {"Cap.p": -0.6 * ch(attack, t, "pitch", 0.1), "Cap.r": 0.5 * ch(attack, t, "yaw", 0.08), "Cap.z": 0.1 * hump(t, 0.38, 0.5)}

	def p_hit(t, c):
		return {"Cap.r": ring(t, 0, 0.08, 7, 0.25) * _end(t), "Cap.z": 0.06 * hump(t, 0, 0.2)}

	def p_die(t, c):
		return {"Cap.r": keys(t, [(0, 0), (1.0, 0.3)]), "Cap.x": keys(t, [(0, 0), (1.1, 0.3)]), "Cap.z": keys(t, [(0, 0), (0.15, 0.08), (1.1, -0.05)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 0.9, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.4


def mo_rimesaw(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.06)

	def idle(t):
		return C(squash=0.03 * math.sin(math.pi * t), roll=0.03 * math.sin(math.pi * t + 0.6), pitch=0.04), {}

	def p_idle(t, c):
		return {"Blades.spin": TAU * t / Ti}

	Tm = 1.0

	def move(t):  # it glides, tilting into the run
		return C(pitch=0.12 + 0.03 * math.sin(TAU * t), lift=0.03 * H * (1 - math.cos(TAU * 2 * t)) / 2, roll=0.04 * math.sin(TAU * t)), {}

	def p_move(t, c):
		return {"Blades.spin": 2 * TAU * t / Tm}

	def attack(t):
		return C(fwd=keys(t, [(0, 0), (0.35, 0.3), (0.55, -1.8), (0.65, -1.7), (1.0, 0)]), pitch=keys(t, [(0, 0), (0.35, -0.15), (0.55, 0.25), (1.0, 0)]),
			squash=keys(t, [(0, 0), (0.35, 0.1), (0.5, -0.12), (0.6, 0.1), (0.8, 0)]), roll=0.05 * math.sin(TAU * 8 * t) * hump(t, 0.1, 0.55)), {}

	def p_attack(t, c):
		return {"Blades.spin": 4 * TAU * sstep(0.0, 1.0, t), "Blades.p": ring(t, 0.55, 0.06, 6, 0.3)}

	def p_hit(t, c):
		return {"Blades.spin": 0.4 * hump(t, 0, 0.4), "Blades.r": ring(t, 0, 0.06, 7, 0.25) * _end(t)}

	def p_die(t, c):
		return {"Blades.spin": 1.2 * sstep(0, 1.0, t), "Blades.p": keys(t, [(0, 0), (1.1, 0.25)]), "Blades.z": keys(t, [(0, 0), (1.1, -0.4)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.0, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.55


def mo_shardspire(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.12, 1.1, 0.04)

	def p_idle(t, c):
		return {"Crown.p": -0.5 * (ch(idle, t, "pitch", 0.2, Ti) - 0.05) + 0.02 * math.sin(math.pi * t - 1), "Crown.r": -0.5 * ch(idle, t, "roll", 0.2, Ti)}

	def p_move(t, c):
		return {"Crown.p": -0.8 * ch(move, t, "pitch", 0.1, Tm), "Crown.z": 0.3 * (ch(move, t, "lift", 0.07, Tm) - c["lift"])}

	def attack(t):  # leans back, whips forward (the shard flies), the column springs back
		return C(pitch=keys(t, [(0, 0), (0.4, -0.3), (0.55, 0.35), (0.62, 0.3)]) * (1 - sstep(0.62, 0.66, t)) + settle(t, 0.64, 0.3, 1.6, 0.3) * sstep(0.62, 0.66, t),
			squash=keys(t, [(0, 0), (0.4, -0.12), (0.55, 0.1), (0.8, 0)])), {}

	def p_attack(t, c):
		return {"Crown.p": -0.6 * (ch(attack, t, "pitch", 0.08) - c["pitch"]) + ring(t, 0.55, 0.12, 4, 0.3)}

	def p_hit(t, c):
		return {"Crown.p": ring(t, 0.03, -0.1, 5, 0.3) * _end(t), "Crown.r": ring(t, 0.04, 0.06, 6, 0.3) * _end(t)}

	def p_die(t, c):
		return {"Crown.p": keys(t, [(0, 0), (1.1, 0.35)]), "Crown.z": keys(t, [(0, 0), (1.1, -0.3)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.1, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.55


def mo_snowshroud(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.12, 1.1, 0.04)
	pulses = lambda t: hump(t, 0.4, 0.55) + hump(t, 0.6, 0.75) + hump(t, 0.8, 0.95)

	def tip(p1, p2, r1=0.0, r2=0.0):
		return {"HoodTip1.p": p1, "HoodTip2.p": p2, "HoodTip1.r": r1, "HoodTip2.r": r2}

	def p_idle(t, c):
		d = tip(0.05 * math.sin(math.pi * t - 1.0), 0.08 * math.sin(math.pi * t - 1.7), 0.03 * math.sin(math.pi * t + 0.2), 0.05 * math.sin(math.pi * t - 0.5))
		d["Hood.p"] = -0.4 * (ch(idle, t, "pitch", 0.2, Ti) - 0.05)
		return d

	def p_move(t, c):
		d = tip(-0.6 * ch(move, t, "pitch", 0.14, Tm), -0.8 * ch(move, t, "pitch", 0.22, Tm))
		d["Hood.z"] = 0.3 * (ch(move, t, "lift", 0.07, Tm) - c["lift"])
		d["Hood.p"] = -0.5 * ch(move, t, "pitch", 0.1, Tm)
		return d

	def attack(t):
		return C(lift=keys(t, [(0, 0), (0.35, 0.3), (1.0, 0.3), (1.2, 0)]), squash=keys(t, [(0, 0), (0.35, -0.12), (1.0, -0.12), (1.2, 0)]),
			swell=0.08 * pulses(t), pitch=keys(t, [(0, 0), (0.35, -0.1), (1.2, 0)])), {}

	def p_attack(t, c):
		d = tip(ring(t, 0.3, 0.15, 2.5, 0.3), ring(t, 0.36, 0.2, 2.5, 0.3))
		d["Hood.z"] = keys(t, [(0, 0), (0.35, 0.25), (1.0, 0.2), (1.2, 0)])
		d["Hood.p"] = keys(t, [(0, 0), (0.35, -0.15), (1.0, -0.12), (1.2, 0)])
		return d

	def p_hit(t, c):
		d = tip(ring(t, 0.04, 0.1, 4, 0.3) * _end(t), ring(t, 0.08, 0.13, 4, 0.3) * _end(t))
		d["Hood.r"] = ring(t, 0, 0.06, 7, 0.25) * _end(t)
		return d

	def p_die(t, c):
		d = tip(keys(t, [(0, 0), (1.1, 0.15)]), keys(t, [(0, 0), (1.1, 0.2)]))
		d["Hood.p"] = keys(t, [(0, 0), (1.1, 0.25)])
		d["Hood.z"] = keys(t, [(0, 0), (1.1, -0.3)])
		return d

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.2, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.47


def mo_icebound(r):
	H = float(r["m"].co[:, 2].max())
	bp = next(p for p in r["parts"] if p["name"] == "Block")
	hd, hw = bp["half_depth"], bp["half_width"]

	def block(p=0.0, rr=0.0, z=0.0, f=0.0):
		"""The block turns about its base middle; it is lifted so the edge it rocks on stays on the ground."""
		return {"Block.p": p, "Block.r": rr, "Block.z": z + hd * abs(math.sin(p)) + hw * abs(math.sin(rr)), "Block.f": f}

	Ti = 2.0

	def idle(t):
		return C(squash=0.05 * math.sin(math.pi * t)), {}

	def p_idle(t, c):
		return block(0.008 * math.sin(math.pi * t - 0.5), 0.01 * math.sin(math.pi * t + 1.0))

	Tm = 1.2
	w = TAU / Tm

	def move(t):  # it rocks from corner to corner; each thump splashes the puddle
		return C(squash=0.15 * abs(math.cos(w * t)) - 0.05), {}

	def p_move(t, c):
		return block(0.02, 0.07 * math.sin(w * t))

	def attack(t):
		return C(squash=keys(t, [(0, 0), (0.6, -0.05), (0.7, 0.3), (0.85, 0)]) + ring(t, 0.7, 0.2, 3, 0.35), fwd=keys(t, [(0, 0), (0.35, 0.1), (0.7, -0.4), (1.2, 0)])), {}

	def p_attack(t, c):
		p = keys(t, [(0, 0), (0.35, -0.08), (0.6, 0.2), (0.7, 0.0)]) + ring(t, 0.7, -0.04, 6, 0.3)
		return block(p, 0.0, 0.08 * hump(t, 0.3, 0.6))

	def hit(t):
		return C(squash=ring(t, 0, 0.2, 4, 0.3) * _end(t), fwd=0.05 * H * keys(t, [(0, 0), (0.08, 1), (0.4, 0)])), {}

	def p_hit(t, c):
		return block(ring(t, 0, -0.05, 6, 0.3) * _end(t), ring(t, 0.02, 0.04, 7, 0.3) * _end(t))

	def die(t):
		return C(squash=keys(t, [(0, 0), (0.15, 0.2), (1.0, 0.85), (1.2, 0.85)])), {}

	def p_die(t, c):
		return block(keys(t, [(0, 0), (1.0, 0.06)]), keys(t, [(0, 0), (0.2, -0.05), (1.0, 0.15)]), keys(t, [(0, 0), (1.1, -0.25)]))

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.2, attack, p_attack, 0.4, hit, p_hit, 1.2, die, p_die), 0.7


def mo_rimetusk(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.07, 1.4, 0.035)

	def tusks(p):
		return {"TuskL.p": p, "TuskR.p": p}

	def p_idle(t, c):
		d = tusks(0.015 * math.sin(math.pi * t - 0.3))
		d["Mane.p"] = -0.5 * (ch(idle, t, "pitch", 0.25, Ti) - 0.05)
		d["Mane.z"] = 0.15 * H * (c["squash"] - ch(idle, t, "squash", 0.2, Ti))
		return d

	def p_move(t, c):
		return {"Mane.p": -0.7 * ch(move, t, "pitch", 0.12, Tm), "Mane.z": 0.4 * (ch(move, t, "lift", 0.08, Tm) - c["lift"])}

	def attack(t):  # head down, two rams
		return C(fwd=keys(t, [(0, 0), (0.3, 0.4), (0.45, -1.5), (0.6, -1.3), (0.72, -0.6), (0.95, -2.2), (1.1, -2.0), (1.6, 0)]),
			pitch=keys(t, [(0, 0), (0.3, 0.2), (1.1, 0.2), (1.6, 0)]) + 0.1 * hump(t, 0.42, 0.52) + 0.12 * hump(t, 0.92, 1.02),
			squash=keys(t, [(0, 0), (0.3, 0.15), (0.42, -0.1), (0.48, 0.15), (0.6, 0), (0.92, -0.12), (0.98, 0.2), (1.15, 0)])), {}

	def p_attack(t, c):
		d = tusks(keys(t, [(0, 0), (0.3, 0.15), (1.1, 0.15), (1.6, 0)]) + ring(t, 0.45, -0.05, 5, 0.3) + ring(t, 0.95, -0.06, 5, 0.3))
		d["Mane.p"] = -0.6 * (ch(attack, t, "pitch", 0.12) - c["pitch"]) + ring(t, 0.47, 0.06, 3, 0.3) + ring(t, 0.97, 0.08, 3, 0.3)
		return d

	def p_hit(t, c):
		return {"Mane.p": -0.8 * ch(hit, t, "pitch", 0.08), "Mane.r": ring(t, 0.03, 0.04, 5, 0.3) * _end(t)}

	def p_die(t, c):
		d = tusks(keys(t, [(0, 0), (1.1, 0.12)]))
		d["Mane.p"] = keys(t, [(0, 0), (1.1, 0.15)])
		d["Mane.z"] = keys(t, [(0, 0), (1.1, -0.3)])
		return d

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.6, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.45


def mo_frostmaw(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.06, 1.5, 0.03)

	def horns(p, out=0.0):
		return {"HornL.p": p, "HornR.p": p, "HornL.r": out, "HornR.r": -out}

	def p_idle(t, c):
		return horns(0.015 * math.sin(math.pi * t - 0.6) - 0.3 * (ch(idle, t, "pitch", 0.2, Ti) - 0.05))

	def p_move(t, c):
		return horns(-0.4 * ch(move, t, "pitch", 0.1, Tm))

	def attack(t):  # rears up stretched, head back, roars (trembling), settles
		trem = 0.02 * math.sin(TAU * 9 * t) * hump(t, 0.55, 1.3)
		return C(squash=keys(t, [(0, 0), (0.25, 0.15), (0.55, -0.3), (1.25, -0.25), (1.5, 0)]) + ring(t, 1.5, 0.15, 2, 0.4),
			lift=keys(t, [(0, 0), (0.55, 0.08 * H), (1.25, 0.06 * H), (1.5, 0)]), pitch=keys(t, [(0, 0), (0.25, 0.1), (0.55, -0.25), (1.25, -0.2), (1.6, 0)]) + trem,
			swell=keys(t, [(0, 0), (0.55, 0.12), (1.25, 0.1), (1.5, 0)]), roll=trem), {}

	def p_attack(t, c):
		return horns(keys(t, [(0, 0), (0.25, 0.05), (0.55, -0.15), (1.25, -0.12), (1.6, 0)]), keys(t, [(0, 0), (0.55, 0.06), (1.3, 0)]))

	def p_hit(t, c):
		return horns(-0.5 * ch(hit, t, "pitch", 0.06))

	def p_die(t, c):
		return horns(keys(t, [(0, 0), (0.2, -0.05), (1.1, 0.12)]), keys(t, [(0, 0), (1.1, -0.05)]))

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.8, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.6


MOTION_FNS.update(Frostnip=mo_frostnip, Rimesaw=mo_rimesaw, Shardspire=mo_shardspire, Snowshroud=mo_snowshroud, Icebound=mo_icebound,
	Rimetusk=mo_rimetusk, Frostmaw=mo_frostmaw)

EXTREMES.update(
	Frostnip=[("cap lags up", C(), {"Cap.z": 0.15, "Cap.p": 0.15}), ("cap slid", C(squash=0.85), {"Cap.r": 0.3, "Cap.x": 0.3, "Cap.z": -0.05})],
	Rimesaw=[("blades 1/8 turn", C(), {"Blades.spin": TAU / 8}), ("blades 1/4 turn", C(), {"Blades.spin": TAU / 4}), ("ram", C(pitch=0.25, squash=-0.12), {"Blades.p": 0.06})],
	Shardspire=[("lean back", C(pitch=-0.3, squash=-0.12), {"Crown.p": 0.15}), ("whip fwd", C(pitch=0.35, squash=0.1), {"Crown.p": -0.15}),
		("crown fallen", C(squash=0.85), {"Crown.p": 0.35, "Crown.z": -0.3})],
	Snowshroud=[("hood lifted", C(lift=0.3, squash=-0.12), {"Hood.z": 0.25, "Hood.p": -0.15}), ("tip whip", C(), {"HoodTip1.p": 0.15, "HoodTip2.p": 0.2}),
		("hood slumped", C(squash=0.85), {"Hood.p": 0.25, "Hood.z": -0.3, "HoodTip1.p": 0.15, "HoodTip2.p": 0.2})],
	Rimetusk=[("tusks lowered", C(pitch=0.2), {"TuskL.p": 0.15, "TuskR.p": 0.15}), ("mane lags", C(), {"Mane.p": 0.12, "Mane.z": 0.2}),
		("dead", C(squash=0.85), {"Mane.p": 0.15, "Mane.z": -0.3, "TuskL.p": 0.12, "TuskR.p": 0.12})],
	Frostmaw=[("roar: rear, horns back", C(squash=-0.3, pitch=-0.25, swell=0.12), {"HornL.p": -0.15, "HornR.p": -0.15, "HornL.r": 0.06, "HornR.r": -0.06}),
		("horns fwd", C(), {"HornL.p": 0.15, "HornR.p": 0.15})],
)


def _ex_ice():
	return [("tips fwd", C(), {"Block.p": 0.2, "Block.z": 0.0}), ("rock side", C(), {"Block.r": 0.07}), ("toppled", C(squash=0.85), {"Block.r": 0.15, "Block.z": -0.25})]


EXTREMES["Icebound"] = _ex_ice()
