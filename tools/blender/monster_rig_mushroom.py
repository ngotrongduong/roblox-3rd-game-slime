# The Mushroom Grove's seven for tools/blender/monster_rig.py (run by it with exec into its namespace, so every helper
# there is in scope): their rigs (parts measured on the mesh) and their motions. Parts move by generic_move's rule:
# drives "<Part>.p/.r/.y" (turns about X/Y/Z, model axes), ".x/.f/.z" (offset), ".o" (along the part's out vector),
# ".spin" (about its spin_axis).


def _lohi(m, sel):
	p = m.co[sel]
	lo, hi = np.percentile(p, 3, axis=0), np.percentile(p, 97, axis=0)
	return lo, hi, (lo + hi) / 2


def _root_tip(m, sel, body):
	"""A loose piece's root (its points nearest the body) and tip (its point farthest from the root)."""
	p = m.co[sel]
	bp = m.co[body]
	d = np.array([np.min(np.linalg.norm(bp - q, axis=1)) for q in p])
	root = p[d <= np.percentile(d, 15)].mean(0)
	tip = p[np.argmax(np.linalg.norm(p - root, axis=1))]
	return root, tip


# ---------------------------------------------------------------- rigs
@monster("Gloomtick", 3000, role="swarmer")
def rig_gloomtick(m):
	body = m.island == m.main
	H = float(m.co[:, 2].max())
	z = m.co[:, 2]
	parts = []
	mands = []
	for k in sorted(set(m.island.tolist()) - {m.main}):
		sel = m.island == k
		if sel.sum() >= 6 and m.co[sel, 2].mean() < 0.45 * H and m.sat[sel].mean() < 0.7:
			mands.append(sel)
	mands.sort(key=lambda s: -m.co[s, 0].mean())
	mand_all = np.zeros(m.n, bool)
	for name, sel in zip(("MandibleL", "MandibleR"), mands[:2]):
		root, tip = _root_tip(m, sel, body)
		parts.append(part(name, "Front", root, sel.astype(float), tail=tip))
		mand_all |= sel
		print(f"JOINT Gloomtick {name} root {np.round(root, 2).tolist()} tip {np.round(tip, 2).tolist()}")
	lo, hi, c = _lohi(m, body)
	zs = np.arange(0.3, 0.8 * H, 0.08)
	prof = zprof(m, body, c[0], c[1], zs)
	zr = float(zs[int(np.argmax(prof))])
	print("PROFILE Gloomtick radius by height:", [(round(a, 2), round(b, 2)) for a, b in zip(zs, prof)])
	th = m.thickness()
	w = np.array([sstep(zr - 0.1, zr + 0.2, x) for x in z])
	spikes = (th < 0.35) & (z > zr - 0.9)
	w = np.where(body, np.maximum(w, spikes.astype(float)), 0.0)
	w[(~body) & (~mand_all)] = 1.0
	print(f"JOINT Gloomtick carapace rim z {zr:.2f} (widest slice), {int((w > 0.5).sum())} vertices")
	parts.insert(0, part("Carapace", "Top", (c[0], c[1], zr), w, tail=(c[0], c[1], H)))
	return parts


@monster("Glimlure", 3000, role="hunter")
def rig_glimlure(m):
	H = float(m.co[:, 2].max())
	z = m.co[:, 2]
	teal = (m.hue > 160) & (m.hue < 215) & (m.sat > 0.3) & (m.val > 0.7)
	lab = m.components(teal & (z > 0.62 * H))
	k = int(np.argmax(np.bincount(lab[lab >= 0])))
	bulb = lab == k
	bidx = np.nonzero(bulb)[0]
	tip_i = int(bidx[np.argmin(z[bidx])])
	# the lure: everything above the head's crown that hangs together with the bulb (the stalk stands clear of the
	# head; the back crest is above that height too but joins it only through the body)
	zb = 0.58 * H  # inferred: the head's crown in the side view, just under where the stalk leaves it
	lab2 = m.components(z > zb)
	sel = lab2 == lab2[tip_i]
	g = m.geodesic(tip_i, 8.0)
	G = float(g[sel].max())
	# the bulb: the round end, out to where the cross-section narrows to the stalk
	counts = [int((sel & (g >= k * 0.08) & (g < (k + 1) * 0.08)).sum()) for k in range(int(G / 0.08) + 1)]
	kpk = int(np.argmax(counts[: max(3, len(counts) // 2)]))
	kneck = kpk + int(np.argmin(counts[kpk: kpk + 12]))
	blen = kneck * 0.08
	# the stalk climbs from the bulb, arcs over and comes down into the head: its base is the first low point of the
	# rings' heights after the arc's top (beyond it the back crest climbs again)
	bz = [float(z[sel & (g >= k * 0.08) & (g < (k + 1) * 0.08)].mean()) if counts[k] else 9.0 for k in range(len(counts))]
	ktop = kneck + int(np.argmax(bz[kneck:]))
	kb, lo_z = ktop, bz[ktop]
	for k in range(ktop + 1, len(bz)):
		if bz[k] < lo_z:
			kb, lo_z = k, bz[k]
		elif bz[k] > lo_z + 0.2:
			break
	sel = sel & (g < (kb + 1) * 0.08)
	G = float(g[sel].max())
	print(f"PROFILE Glimlure lure ring sizes from the bulb's end every 0.08: {counts}, neck at {blen:.2f}, ring heights {np.round(bz, 2).tolist()}, base ring {kb}")
	base = m.co[sel & (g > G - 0.15)].mean(0)
	mid = m.co[sel & (np.abs(g - (G + blen) / 2) < 0.12)].mean(0)
	broot = m.co[sel & (np.abs(g - blen) < 0.1)].mean(0)
	print(f"JOINT Glimlure lure above z {zb:.2f}: {int(sel.sum())} vertices, length {G:.2f} bulb {blen:.2f} base {np.round(base, 2).tolist()} mid {np.round(mid, 2).tolist()} bulb root {np.round(broot, 2).tolist()}")
	gm = (G + blen) / 2
	w2 = np.where(sel, np.array([1 - sstep(gm - 0.15 * G, gm + 0.15 * G, x) for x in g]), 0.0)
	# the stalk's foot fades into the head along the stalk itself (a ring-based fade spread over the head's crown)
	tot = np.where(sel, np.array([1 - sstep(G - 0.6, G, x) for x in g]), 0.0)
	w1 = np.clip(tot - w2, 0, 1)
	lure = sel
	# the tail: along the body's long horizontal axis, away from the lure
	body = ~lure
	P = m.co[body]
	cxy = P[:, :2].mean(0)
	w_, v_ = np.linalg.eigh(np.cov((P[:, :2] - cxy).T))
	a2 = v_[:, -1]
	if (m.co[bulb, :2].mean(0) - cxy) @ a2 > 0:
		a2 = -a2
	a = np.array([a2[0], a2[1], 0.0])
	s = (m.co[:, :2] - cxy) @ a2
	smax = float(np.percentile(s[body], 99.5))
	o = float(np.array([cxy[0], cxy[1], 0]) @ a)
	sj = [o + 0.0 * smax, o + 0.36 * smax, o + 0.68 * smax, o + 0.95 * smax]
	tparts, tot = axis_chain(m, body, a, sj, ["Tail1", "Tail2", "Tail3"], "Body", fade=0.6, label="Glimlure tail")
	m.info["tail_axis"] = Vector(a)
	m.info["cage_sel"] = body & (s < 0.15 * smax)
	return [part("Lure1", "Top", base, w1, tail=mid), part("Lure2", "Lure1", mid, w2, tail=broot)] + tparts


@monster("Bilebloat", 3000, role="spitter")
def rig_bilebloat(m):
	H = float(m.co[:, 2].max())
	x, y, z = m.co.T
	lo, hi, c = _lohi(m, np.ones(m.n, bool))
	cand = (np.abs(x - c[0]) < 1.0) & (z > 0.2 * H) & (z < 0.7 * H)
	idx = np.nonzero(cand)[0]
	tip_i = int(idx[np.argmin(y[idx])])
	sel, g, G = m.protrusion(tip_i, 0.08, "Bilebloat lips", start=3)
	base = m.co[sel & (g > G - 0.12)].mean(0)
	print(f"JOINT Bilebloat lips tip {np.round(m.co[tip_i], 2).tolist()} depth {G:.2f} base {np.round(base, 2).tolist()} {int(sel.sum())} vertices")
	return [part("Lips", "Front", base, soften(m, sel.astype(float), 2), tail=m.co[tip_i])]


@monster("Hexcap", 3000, role="healer")
def rig_hexcap(m):
	body = m.island == m.main
	H = float(m.co[:, 2].max())
	x, y, z = m.co.T
	lo, hi, c = _lohi(m, body & (z < 0.3 * H))
	# the stem is teal-green, the cap violet: along the axis (r < 0.9, where the brim and its runes are not) the cap
	# starts at the lowest slice that is mostly violet
	r = np.hypot(x - c[0], y - c[1])
	violet = (m.hue > 240) & (m.hue < 335)
	stemc = (m.hue > 140) & (m.hue < 215) & (m.sat > 0.3)
	# the stem's top: the highest stem-coloured vertex close to the axis (the cap's teal runes are out on the brim or
	# high on the cone, so the search stops at 0.65 H)
	core = body & stemc & (r < 1.0) & (z < 0.65 * H)
	zj = float(np.percentile(z[core], 97))
	sb = body & stemc & (z > zj - 0.45) & (z < zj - 0.1)
	rs = float(np.percentile(r[sb], 90)) if sb.sum() > 5 else 0.9
	cap = body & ((z > zj) | ((~stemc | (r > rs + 0.15)) & (z > 0.9)))
	cap |= ~body
	ct = float(np.percentile(z[cap], 99.5))
	zt0 = zj + 0.6 * (ct - zj)
	print(f"JOINT Hexcap stem top z {zj:.2f} (stem radius under it {rs:.2f}), cap top {ct:.2f}, tip from z {zt0:.2f}, cap vertices {int(cap.sum())}")
	tipsel = cap & body & (z > zt0 - 0.05)
	base_pt = m.co[cap & body & (np.abs(z - zt0) < 0.08)].mean(0)
	tparts, tot = geo_chain(m, tipsel, base_pt, ["CapTip1", "CapTip2"], "Cap", fade=0.2, label="Hexcap tip")
	wcap = np.clip(soften(m, cap.astype(float), 2) - tot, 0, 1)
	return [part("Cap", "Top", (c[0], c[1], zj), wcap, tail=base_pt)] + tparts


@monster("Ruingut", 3000, role="armoured")
def rig_ruingut(m):
	H = float(m.co[:, 2].max())
	x, y, z = m.co.T
	grey = m.sat < 0.3
	lab = m.components(grey)
	comps = []
	for k in range(lab.max() + 1):
		s = lab == k
		if s.sum() >= 12:
			comps.append((float(z[s].mean()), k, int(s.sum())))
	comps.sort(reverse=True)
	# the column: the highest stone piece; its upper half gives its middle and radius (the base is wrapped in roots)
	seed = lab == comps[0][1]
	print(f"JOINT Ruingut highest stone piece {int(seed.sum())} vertices box {m.box(seed)}")
	core = seed & (z > np.percentile(z[seed], 75))
	pcx, pcy = np.median(x[core]), np.median(y[core])
	pr = float(np.percentile(np.hypot(x[core] - pcx, y[core] - pcy), 85))
	# the same stone piece runs down into the brow slab over the mouth: only what stands within the column's radius
	# is the column, the rest is a slab on the face
	pillar = seed & (np.hypot(x - pcx, y - pcy) < pr * 1.25)
	brow = seed & ~pillar
	z0 = float(np.percentile(z[pillar], 5))
	if brow.sum() >= 6:
		lab[brow] = lab.max() + 1
		comps.append((float(z[brow].mean()), int(lab.max()), int(brow.sum())))
	for k in set(m.island.tolist()) - {m.main}:
		s = m.island == k
		cc = m.co[s].mean(0)
		if math.hypot(cc[0] - pcx, cc[1] - pcy) < pr * 1.2 and cc[2] > z0 + 0.3:
			pillar |= s
	print(f"JOINT Ruingut pillar centre ({pcx:.2f}, {pcy:.2f}) radius {pr:.2f} from z {z0:.2f}, {int(pillar.sum())} vertices")
	parts = [part("Pillar", "Top", (pcx, pcy, z0), soften(m, pillar.astype(float), 2), tail=(pcx, pcy, H))]
	for zz, k, n in comps[1:]:
		s = (lab == k) & ~pillar
		if s.sum() < 12:
			continue
		cc = m.co[s].mean(0)
		side = side_of(m, cc)
		parts.append(onto(side, soften(m, s.astype(float), 1) * (~pillar)))
		print(f"JOINT Ruingut slab {n} vertices at {np.round(cc, 2).tolist()} rigid on {side}")
	return parts


@monster("Sporegorge", 6000, role="miniboss")
def rig_sporegorge(m):
	body = m.island == m.main
	H = float(m.co[:, 2].max())
	lo, hi, c = _lohi(m, body)
	cen = np.array([c[0], c[1], 0.45 * H])
	sacs = []
	for k in sorted(set(m.island.tolist()) - {m.main}):
		s = m.island == k
		p = m.co[s]
		diam = float(np.ptp(p, axis=0).max())
		hue = float(np.median(m.hue[s]))
		if diam > 0.65 and 240 < hue < 345:
			sacs.append(s)
	sacs.sort(key=lambda s: -m.co[s, 2].mean())
	parts = []
	for k, s in enumerate(sacs):
		root, tip = _root_tip(m, s, body)
		cc = m.co[s].mean(0)
		pp = part(f"Sac{k + 1}", "Top", root, s.astype(float), tail=cc)
		pp["out"] = Vector(cc - cen).normalized()
		parts.append(pp)
		print(f"JOINT Sporegorge Sac{k + 1} {int(s.sum())} vertices middle {np.round(cc, 2).tolist()} out {np.round(np.array(pp['out']), 2).tolist()}")
	return parts


@monster("Hollowheart", 8000, role="boss")
def rig_hollowheart(m):
	H = float(m.co[:, 2].max())
	body = m.island == m.main
	lo, hi, c = _lohi(m, body)
	crown = np.zeros(m.n, bool)
	for k in set(m.island.tolist()) - {m.main}:
		s = m.island == k
		hue = float(np.median(m.hue[s]))
		if m.co[s, 2].mean() > 0.52 * H and not (150 < hue < 200):
			crown |= s
	lab = m.components(crown)
	sizes = sorted([(int((lab == k).sum()), k) for k in range(lab.max() + 1)], reverse=True)
	halves = False
	if len(sizes) >= 2 and sizes[1][0] > 0.3 * sizes[0][0]:
		xa, xb = m.co[lab == sizes[0][1], 0].mean(), m.co[lab == sizes[1][1], 0].mean()
		halves = (xa - c[0]) * (xb - c[0]) < 0
	print(f"JOINT Hollowheart crown pieces {sizes[:4]} -> {'two halves' if halves else 'one crown'}")
	zc = float(np.percentile(m.co[crown, 2], 5))
	if not halves:
		return [part("Crown", "Top", (c[0], c[1], zc), crown.astype(float), tail=(c[0], c[1], H))]
	out = []
	for name, sgn in (("CrownL", 1), ("CrownR", -1)):
		s = crown & ((m.co[:, 0] - c[0]) * sgn > 0)
		p = m.co[s]
		root = p[p[:, 2] <= np.percentile(p[:, 2], 8)].mean(0)
		out.append(part(name, "Top", root, s.astype(float), tail=p.mean(0)))
		print(f"JOINT Hollowheart {name} root {np.round(root, 2).tolist()}")
	return out


# ---------------------------------------------------------------- motions
def _A(Ti, idle, p_idle, Tm, move, p_move, Ta, attack, p_attack, Th, hit, p_hit, Td, die, p_die):
	return dict(Idle=wrap(Ti, True, idle, p_idle), Move=wrap(Tm, True, move, p_move), Attack=wrap(Ta, False, attack, p_attack),
		Hit=wrap(Th, False, hit, p_hit), Die=wrap(Td, False, die, p_die))


def _end(t):
	return 1 - sstep(0.28, 0.4, t)


def _with(fn, **extra):
	"""A body action with extra channels added: extra[name] = fn(t)."""
	def f(t):
		c, d = fn(t)
		c = dict(c)
		for k, e in extra.items():
			c[k] = c.get(k, 0.0) + e(t)
		return c, d
	return f


def mo_gloomtick(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.12)
	Tm = 0.6
	w = TAU / Tm

	def move(t):  # a scuttle: two quick hops a loop, a waddle side to side
		return C(lift=0.05 * H * abs(math.sin(w * t)), squash=0.1 * math.cos(2 * w * t), pitch=0.1 + 0.04 * math.sin(2 * w * t),
			roll=0.07 * math.sin(w * t), yaw=0.05 * math.sin(w * t + 0.5)), {}

	def mand(a, droop=0.0):
		return {"MandibleL.y": a, "MandibleR.y": -a, "MandibleL.p": droop, "MandibleR.p": droop}

	def p_idle(t, c):
		d = mand(0.08 + 0.07 * math.sin(TAU * 1.5 * t) * math.sin(math.pi * t) ** 2)
		d["Carapace.z"] = 0.25 * H * (c["squash"] - ch(idle, t, "squash", 0.15, Ti))
		d["Carapace.p"] = 0.02 * math.sin(math.pi * t - 1.0)
		return d

	def p_move(t, c):
		d = mand(0.15 + 0.15 * math.sin(2 * w * t))
		d["Carapace.z"] = 0.3 * (ch(move, t, "lift", 0.05, Tm) - c["lift"])
		d["Carapace.r"] = 0.04 * math.sin(2 * w * t + 1.0)
		d["Carapace.p"] = 0.03 * math.sin(2 * w * t)
		return d

	def attack(t):
		return C(fwd=keys(t, [(0, 0), (0.3, 0.25), (0.42, -1.2), (0.55, -1.1), (0.9, 0)]),
			squash=keys(t, [(0, 0), (0.3, 0.25), (0.4, -0.2), (0.48, 0.12), (0.6, 0), (0.9, 0)]),
			pitch=keys(t, [(0, 0), (0.3, -0.15), (0.42, 0.3), (0.9, 0)]) + 0.15 * hump(t, 0.44, 0.52),
			lift=0.25 * hump(t, 0.3, 0.46)), {}

	def p_attack(t, c):
		d = mand(keys(t, [(0, 0.08), (0.3, 0.65), (0.4, 0.65), (0.46, -0.12), (0.6, -0.1), (0.9, 0.08)]) + ring(t, 0.46, 0.06, 6, 0.3))
		d["Carapace.p"] = keys(t, [(0, 0), (0.3, -0.15), (0.45, 0.15), (0.9, 0)]) + ring(t, 0.45, 0.06, 7, 0.25)
		d["Carapace.z"] = 0.12 * hump(t, 0.3, 0.5)
		return d

	def p_hit(t, c):
		d = mand(0.08 + 0.4 * hump(t, 0, 0.3))
		d["Carapace.r"] = ring(t, 0, 0.08, 9, 0.2) * _end(t)
		d["Carapace.z"] = 0.08 * hump(t, 0, 0.2)
		return d

	def p_die(t, c):
		d = mand(keys(t, [(0, 0.08), (0.2, 0.6), (1.0, 0.45)]), keys(t, [(0, 0), (1.0, 0.35)]))
		d["Carapace.r"] = keys(t, [(0, 0), (1.0, 0.22)])
		d["Carapace.z"] = keys(t, [(0, 0), (0.15, 0.1), (1.1, -0.2)])
		d["Carapace.x"] = keys(t, [(0, 0), (1.1, 0.2)])
		return d

	return _A(Ti, idle, p_idle, Tm, move, p_move, 0.9, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.46


def mo_glimlure(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.1)

	def tail(t, A, f, lagk=0.9, ph=0.0):
		return {f"Tail{k + 1}.y": A * (0.6 + 0.4 * k) * math.sin(TAU * f * t - lagk * k + ph) for k in range(3)}

	def p_idle(t, c):
		d = tail(t, 0.08, 0.5)
		d["Lure1.p"] = 0.06 * math.sin(math.pi * t - 0.5) - 0.5 * (ch(idle, t, "pitch", 0.15, Ti) - 0.05)
		d["Lure2.p"] = 0.1 * math.sin(math.pi * t - 1.3)
		d["Lure2.r"] = 0.05 * math.sin(math.pi * t + 0.4)
		return d

	Tm = 1.0
	w = TAU / Tm

	def move(t):  # a slither: the body sways and the wave runs down the tail, no hop
		return C(yaw=0.1 * math.sin(w * t), side=0.03 * H * math.sin(w * t - 0.4), squash=0.04 * math.sin(2 * w * t), pitch=0.06,
			lift=0.02 * H * (1 - math.cos(2 * w * t)) / 2), {}

	def p_move(t, c):
		d = tail(t, 0.28, 1.0, 1.0, -1.2)
		d["Lure1.p"] = -0.15 + 0.08 * math.sin(2 * w * t - 1.0)
		d["Lure2.p"] = -0.2 + 0.1 * math.sin(2 * w * t - 1.6)
		d["Lure1.y"] = -0.6 * ch(move, t, "yaw", 0.15, Tm)
		return d

	def attack(t):
		return C(fwd=keys(t, [(0, 0), (0.3, 0.5), (0.45, -1.8), (0.6, -1.7), (1.0, 0)]),
			pitch=keys(t, [(0, 0), (0.3, -0.25), (0.45, 0.25), (1.0, 0)]) + 0.15 * hump(t, 0.47, 0.55) + 0.12 * hump(t, 0.56, 0.64),
			squash=keys(t, [(0, 0), (0.3, 0.15), (0.42, -0.2), (0.5, 0.1), (0.7, 0)]), lift=0.2 * hump(t, 0.3, 0.5)), {}

	def p_attack(t, c):
		d = {f"Tail{k + 1}.y": 0.25 * (k + 1) / 3 * hump(t, 0.05, 0.45) + ring(t, 0.42 + 0.05 * k, -0.2 * (k + 1), 2.5, 0.3) for k in range(3)}
		# the stalk already arcs forward over the face: forward is kept small so the bulb never folds into the head
		d["Lure1.p"] = keys(t, [(0, 0), (0.3, -0.4), (0.44, 0.25), (0.55, 0.2), (1.0, 0)]) + ring(t, 0.55, -0.15, 3, 0.35)
		d["Lure2.p"] = keys(t, [(0, 0), (0.33, -0.3), (0.46, 0.3), (0.58, 0.25), (1.0, 0)]) + ring(t, 0.58, -0.2, 3.5, 0.3)
		return d

	def p_hit(t, c):
		d = {f"Tail{k + 1}.y": ring(t, 0.03 * k, 0.2, 4, 0.3) * _end(t) for k in range(3)}
		d["Lure1.p"] = ring(t, 0.02, -0.3, 3.5, 0.3) * _end(t)
		d["Lure2.p"] = ring(t, 0.06, -0.35, 3.5, 0.3) * _end(t)
		return d

	def p_die(t, c):
		d = {f"Tail{k + 1}.y": keys(t, [(0, 0), (0.15, -0.1), (1.1, 0.3)]) for k in range(3)}
		d["Lure1.p"] = keys(t, [(0, 0), (0.15, -0.2), (1.0, 0.25)])
		d["Lure2.p"] = keys(t, [(0, 0), (0.2, -0.2), (1.1, 0.35)])
		return d

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.0, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.47


def mo_bilebloat(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.15, 1.1, 0.05)
	idle = _with(idle, swell=lambda t: 0.06 * math.sin(math.pi * t - 0.3))
	hit = _with(hit, swell=lambda t: ring(t, 0.02, -0.15, 3.5, 0.3) * _end(t))
	die = _with(die, swell=lambda t: keys(t, [(0, 0), (0.15, 0.15), (1.0, -0.25)]))

	def p_idle(t, c):
		return {"Lips.f": 0.04 * math.sin(TAU * t), "Lips.p": 0.05 * math.sin(math.pi * t - 0.7)}

	def p_move(t, c):
		return {"Lips.f": 0.3 * (ch(move, t, "lift", 0.06, Tm) - c["lift"]), "Lips.p": -0.5 * ch(move, t, "squash", 0.1, Tm)}

	def attack(t):
		return C(swell=keys(t, [(0, 0), (0.45, 0.38), (0.52, 0.4), (0.6, -0.12), (0.75, 0)]) + ring(t, 0.75, 0.06, 3, 0.4),
			pitch=keys(t, [(0, 0), (0.45, -0.18), (0.58, 0.22), (1.1, 0)]), squash=keys(t, [(0, 0), (0.45, -0.05), (0.58, 0.08), (0.8, 0)]),
			fwd=keys(t, [(0, 0), (0.45, 0.2), (0.6, -0.3), (1.1, 0)])), {}

	def p_attack(t, c):
		return {"Lips.f": keys(t, [(0, 0), (0.45, 0.12), (0.58, -0.45), (0.7, -0.4), (1.1, 0)]),
			"Lips.p": keys(t, [(0, 0), (0.45, -0.15), (0.58, 0.25), (1.1, 0)]) + ring(t, 0.7, 0.08, 5, 0.3)}

	def p_hit(t, c):
		return {"Lips.f": ring(t, 0, 0.12, 6, 0.3) * _end(t), "Lips.p": ring(t, 0.03, -0.15, 5, 0.3) * _end(t)}

	def p_die(t, c):
		return {"Lips.p": keys(t, [(0, 0), (0.2, -0.15), (1.1, 0.5)]), "Lips.z": keys(t, [(0, 0), (1.1, -0.1)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.1, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.58


def mo_hexcap(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.15, 1.0, 0.04)
	pulses = lambda t: hump(t, 0.35, 0.5) + hump(t, 0.55, 0.7) + hump(t, 0.75, 0.9)

	def p_idle(t, c):
		return {"Cap.p": -0.5 * (ch(idle, t, "pitch", 0.2, Ti) - 0.05) + 0.02 * math.sin(math.pi * t - 1),
			"Cap.r": -0.5 * ch(idle, t, "roll", 0.2, Ti), "CapTip1.p": 0.06 * math.sin(math.pi * t - 1.2),
			"CapTip1.r": 0.05 * math.sin(math.pi * t + 0.3), "CapTip2.p": 0.1 * math.sin(math.pi * t - 1.9),
			"CapTip2.r": 0.08 * math.sin(math.pi * t - 0.4)}

	def p_move(t, c):
		return {"Cap.p": -0.7 * ch(move, t, "pitch", 0.1, Tm), "Cap.z": 0.35 * (ch(move, t, "lift", 0.07, Tm) - c["lift"]),
			"CapTip1.p": -0.8 * ch(move, t, "pitch", 0.15, Tm), "CapTip2.p": -1.0 * ch(move, t, "pitch", 0.22, Tm),
			"CapTip2.r": 0.3 * ch(move, t, "squash", 0.2, Tm)}

	def attack(t):
		return C(lift=keys(t, [(0, 0), (0.3, 0.25), (0.95, 0.25), (1.2, 0)]), squash=keys(t, [(0, 0), (0.3, -0.12), (0.95, -0.12), (1.2, 0)]),
			swell=0.08 * pulses(t), pitch=keys(t, [(0, 0), (0.3, -0.1), (1.2, 0)])), {}

	def p_attack(t, c):
		return {"Cap.p": keys(t, [(0, 0), (0.3, -0.3), (0.95, -0.25), (1.2, 0)]), "Cap.z": keys(t, [(0, 0), (0.3, 0.25), (0.95, 0.2), (1.2, 0)]),
			"CapTip1.p": ring(t, 0.25, 0.25, 2.5, 0.3) + 0.06 * pulses(t), "CapTip2.p": ring(t, 0.32, 0.35, 2.5, 0.3),
			"CapTip1.r": ring(t, 0.4, 0.15, 3, 0.3)}

	def p_hit(t, c):
		e = _end(t)
		return {"Cap.r": ring(t, 0, 0.08, 7, 0.25) * e, "Cap.p": ring(t, 0.02, 0.06, 6, 0.25) * e,
			"CapTip1.p": ring(t, 0.05, 0.3, 4, 0.3) * e, "CapTip2.p": ring(t, 0.08, 0.4, 4, 0.3) * e}

	def p_die(t, c):
		return {"Cap.r": keys(t, [(0, 0), (1.0, 0.35)]), "Cap.z": keys(t, [(0, 0), (0.2, 0.1), (1.1, -0.35)]), "Cap.x": keys(t, [(0, 0), (1.1, 0.2)]),
			"CapTip1.r": keys(t, [(0, 0), (1.1, 0.4)]), "CapTip2.r": keys(t, [(0, 0), (1.1, 0.5)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.2, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.42


def mo_ruingut(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.07, 1.3, 0.035)

	def p_idle(t, c):
		return {"Pillar.p": 0.025 * math.sin(math.pi * t - 1.2) - 0.5 * (ch(idle, t, "pitch", 0.25, Ti) - 0.05),
			"Pillar.r": 0.02 * math.sin(math.pi * t + 0.6) - 0.5 * ch(idle, t, "roll", 0.25, Ti)}

	def p_move(t, c):
		u = t % Tm
		return {"Pillar.p": -0.8 * ch(move, t, "pitch", 0.12, Tm) + ring(u, 0.7, 0.06, 4, 0.3) + ring(u + Tm, 0.7, 0.06, 4, 0.3),
			"Pillar.r": ring(u, 0.72, 0.04, 5, 0.3) + ring(u + Tm, 0.72, 0.04, 5, 0.3)}

	def attack(t):
		return C(fwd=keys(t, [(0, 0), (0.35, 0.35), (0.45, 0.35), (0.62, -1.2), (0.75, -1.1), (1.2, 0)]),
			squash=keys(t, [(0, 0), (0.35, 0.18), (0.5, -0.12), (0.62, 0.12), (0.8, 0)]) + ring(t, 0.62, 0.06, 3, 0.4),
			pitch=keys(t, [(0, 0), (0.35, -0.1), (0.62, 0.25), (1.2, 0)])), {}

	def p_attack(t, c):
		p = keys(t, [(0, 0), (0.4, -0.12), (0.6, 0.0), (0.72, 0.32)]) if t < 0.72 else settle(t, 0.72, 0.32, 1.3, 0.3)
		return {"Pillar.p": p, "Pillar.r": ring(t, 0.72, 0.06, 2, 0.3)}

	def p_hit(t, c):
		e = _end(t)
		return {"Pillar.p": ring(t, 0.03, -0.1, 4, 0.3) * e, "Pillar.r": ring(t, 0.05, 0.06, 5, 0.3) * e}

	def p_die(t, c):
		return {"Pillar.p": keys(t, [(0, 0), (0.2, -0.1), (1.1, 0.45)]), "Pillar.z": keys(t, [(0, 0), (1.1, -0.3)]), "Pillar.r": keys(t, [(0, 0), (1.1, 0.12)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.2, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.62


def mo_sporegorge(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.08, 1.3, 0.04)
	n = sum(1 for p in r["parts"] if p["name"].startswith("Sac"))

	def sacs(fn):
		return {f"Sac{k + 1}.o": fn(k) for k in range(n)}

	def p_idle(t, c):
		return sacs(lambda k: 0.12 * math.sin(math.pi * t - 1.3 * k))

	def p_move(t, c):
		return sacs(lambda k: 0.5 * (ch(move, t, "lift", 0.05 + 0.02 * k, Tm) - c["lift"]) + 0.6 * ch(move, t, "squash", 0.08 + 0.015 * k, Tm))

	def attack(t):
		return C(squash=keys(t, [(0, 0), (0.45, 0.3), (0.6, -0.35), (0.75, -0.25), (1.0, 0)]) + ring(t, 1.0, 0.1, 2, 0.4),
			lift=0.1 * H * hump(t, 0.55, 0.95), swell=keys(t, [(0, 0), (0.45, 0.12), (0.6, 0.2), (1.0, 0)]),
			pitch=keys(t, [(0, 0), (0.45, 0.1), (0.6, -0.15), (1.4, 0)])), {}

	def p_attack(t, c):
		return sacs(lambda k: keys(t - 0.015 * k, [(0, 0), (0.45, 0.2 + 0.05 * math.sin(k)), (0.6, 0.5), (0.72, 0.45), (1.1, 0)])
			+ ring(t, 1.1 + 0.02 * k, 0.12, 2.5, 0.35))

	def p_hit(t, c):
		return sacs(lambda k: ring(t, 0.02 * k, 0.15, 5, 0.3) * _end(t))

	def p_die(t, c):
		return sacs(lambda k: keys(t, [(0, 0), (0.2, 0.1), (1.1, -0.2)]))

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.4, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.6


def mo_hollowheart(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.07, 1.5, 0.03)
	crowns = [p["name"] for p in r["parts"] if p["name"].startswith("Crown")]

	def cr(p, rr=0.0, z=0.0):
		d = {}
		for nm in crowns:
			s = -1 if nm == "CrownR" else 1
			d[nm + ".p"] = p
			d[nm + ".r"] = rr if nm == "Crown" else s * rr
			d[nm + ".z"] = z
		return d

	def p_idle(t, c):
		return cr(-0.6 * (ch(idle, t, "pitch", 0.35, Ti) - 0.05) + 0.02 * math.sin(math.pi * t - 2), -0.6 * ch(idle, t, "roll", 0.35, Ti) + 0.015 * math.sin(math.pi * t + 0.5))

	def p_move(t, c):
		return cr(-0.9 * ch(move, t, "pitch", 0.18, Tm) + 0.08 * ch(move, t, "squash", 0.22, Tm))

	def attack(t):
		return C(lift=keys(t, [(0, 0), (0.3, 0), (0.62, 1.6), (0.72, 1.6), (0.82, 0)]),
			squash=keys(t, [(0, 0), (0.3, 0.25), (0.5, -0.3), (0.72, -0.25), (0.82, 0)]) + ring(t, 0.82, 0.7, 1.6, 0.35),
			pitch=keys(t, [(0, 0), (0.3, 0.05), (0.62, -0.18), (0.8, 0.12), (1.6, 0)])), {}

	def p_attack(t, c):
		return cr(keys(t, [(0, 0), (0.3, 0.08), (0.62, -0.4), (0.8, -0.3), (1.0, 0)]) + ring(t, 0.82, 0.45, 1.2, 0.3))

	def p_hit(t, c):
		return cr(-0.8 * ch(hit, t, "pitch", 0.1), -0.8 * ch(hit, t, "roll", 0.1))

	def p_die(t, c):
		return cr(keys(t, [(0, 0), (0.2, -0.1), (1.1, 0.35)]), 0.0, keys(t, [(0, 0), (1.1, -0.3)]))

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.6, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.82


MOTION_FNS.update(Gloomtick=mo_gloomtick, Glimlure=mo_glimlure, Bilebloat=mo_bilebloat, Hexcap=mo_hexcap, Ruingut=mo_ruingut,
	Sporegorge=mo_sporegorge, Hollowheart=mo_hollowheart)


def _ex_hollow():
	return [("crown back", C(), {"Crown.p": -0.4, "CrownL.p": -0.4, "CrownR.p": -0.4}), ("crown whips fwd", C(squash=0.5), {"Crown.p": 0.4, "CrownL.p": 0.4, "CrownR.p": 0.4})]


EXTREMES.update(
	Gloomtick=[("carapace lifted", C(), {"Carapace.z": 0.2, "Carapace.p": -0.15}), ("mandibles open", C(), {"MandibleL.y": 0.65, "MandibleR.y": -0.65}),
		("mandibles shut", C(), {"MandibleL.y": -0.12, "MandibleR.y": 0.12}), ("dead", C(squash=0.85), {"Carapace.r": 0.22, "Carapace.z": -0.2, "MandibleL.p": 0.35, "MandibleR.p": 0.35})],
	Glimlure=[("lure fwd", C(), {"Lure1.p": 0.25, "Lure2.p": 0.3}), ("lure back", C(), {"Lure1.p": -0.4, "Lure2.p": -0.3}),
		("tail wave", C(), {"Tail1.y": 0.17, "Tail2.y": -0.22, "Tail3.y": 0.28}), ("tail curl", C(), {"Tail1.y": 0.3, "Tail2.y": 0.3, "Tail3.y": 0.3})],
	Bilebloat=[("inflated", C(swell=0.4, pitch=-0.18), {"Lips.f": 0.12}), ("spit", C(swell=-0.12, pitch=0.22), {"Lips.f": -0.45, "Lips.p": 0.25}),
		("deflated", C(squash=0.85, swell=-0.25), {"Lips.p": 0.5})],
	Hexcap=[("cap back, lifted", C(), {"Cap.p": -0.3, "Cap.z": 0.25}), ("tip whip", C(), {"CapTip1.p": 0.2, "CapTip2.p": 0.3, "CapTip1.r": 0.15}),
		("cap fallen", C(squash=0.85), {"Cap.r": 0.35, "Cap.z": -0.35, "Cap.x": 0.2})],
	Ruingut=[("pillar tips fwd", C(pitch=0.25), {"Pillar.p": 0.32}), ("pillar back", C(), {"Pillar.p": -0.15, "Pillar.r": 0.08}),
		("pillar toppled", C(squash=0.85), {"Pillar.p": 0.45, "Pillar.z": -0.3})],
	Hollowheart=_ex_hollow(),
)


def _ex_spore():
	return [("sacs swell", C(squash=0.3), {f"Sac{k}.o": 0.3 for k in range(1, 20)}), ("sacs thrown", C(squash=-0.35), {f"Sac{k}.o": 0.5 for k in range(1, 20)}),
		("sacs sag", C(squash=0.85), {f"Sac{k}.o": -0.2 for k in range(1, 20)})]


EXTREMES["Sporegorge"] = _ex_spore()
