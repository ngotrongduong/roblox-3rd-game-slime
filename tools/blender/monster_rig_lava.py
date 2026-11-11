# The Ember Lava seven for tools/blender/monster_rig.py (exec'd into its namespace). Parts move by generic_move's rule
# (drives "<Part>.p/.r/.y", ".x/.f/.z", ".o", ".spin"); Scorchdart has no cage: its body is a spine chain.


# ---------------------------------------------------------------- rigs
@monster("Wickling", 3000, role="swarmer")
def rig_wickling(m):
	z = m.co[:, 2]
	sizes = np.bincount(m.island)
	big = [k for k in range(len(sizes)) if sizes[k] > 0.15 * m.n]
	capk = max(big, key=lambda k: m.co[m.island == k, 2].mean())
	cap = m.island == capk
	lo, hi, c = _lohi(m, cap)
	zs = np.arange(lo[2], hi[2] + 0.2, 0.05)
	prof = zprof(m, cap, c[0], c[1], zs, half=0.05)
	kmax = int(np.argmax(prof))
	kw = next((k for k in range(kmax, len(zs)) if 0 < prof[k] < 0.3 * prof[kmax]), len(zs) - 4)
	zw = float(zs[kw])
	print("PROFILE Wickling crust radius by height:", [(round(a, 2), round(b, 2)) for a, b in zip(zs, prof)])
	base_pt = m.co[cap & (np.abs(z - zw) < 0.08)].mean(0)
	tparts, tot = geo_chain(m, cap & (z > zw - 0.1), base_pt, ["Wick1", "Wick2"], "Crust", fade=0.15, label="Wickling wick")
	wc = np.clip(cap.astype(float) - tot, 0, 1)
	print(f"JOINT Wickling crust island {int(cap.sum())} vertices, wick from z {zw:.2f}")
	return [part("Crust", "Top", (c[0], c[1], float(np.percentile(z[cap], 5))), wc, tail=base_pt)] + tparts


@monster("Scorchdart", 3000, role="hunter", nocage=True)
def rig_scorchdart(m):
	main = m.island == m.main
	y = m.co[:, 1]
	y0, y1 = float(np.percentile(y[main], 1)), float(np.percentile(y[main], 99))
	L = y1 - y0
	sj = [y0 + f * L for f in (0.15, 0.38, 0.6, 0.8, 0.99)]
	names = ["Spine1", "Spine2", "Spine3", "Spine4"]
	parts, tot = axis_chain(m, main, (0, 1, 0), sj, names, "Body", fade=0.0, label="Scorchdart spine")
	for k in sorted(set(m.island.tolist()) - {m.main}):
		s = m.island == k
		cy = float(m.co[s, 1].mean())
		u = float(np.interp(cy, sj, np.arange(len(sj))))
		b = names[min(int(u), 3)]
		parts.append(onto(b, s.astype(float)))
		print(f"JOINT Scorchdart piece {int(s.sum())} vertices at y {cy:.2f} rigid on {b}")
	return parts


@monster("Blazegullet", 3000, role="spitter")
def rig_blazegullet(m):
	main = m.island == m.main
	bright = (m.val > 0.82) & ((m.hue < 60) | (m.hue > 350))
	lab = m.components(bright & main)
	k = int(np.argmax(np.bincount(lab[lab >= 0])))
	seed = lab == k
	c = m.co[seed].mean(0)
	nrm = m.nor[seed].mean(0)
	nrm /= np.linalg.norm(nrm)
	R = float(np.percentile(np.linalg.norm(m.co[seed] - c, axis=1), 90))
	d = np.linalg.norm(m.co - c, axis=1)
	front = ((m.co - c) @ nrm) > -0.4 * R
	w = np.where(front, np.array([sstep(1.05 * R, 0.5 * R, x) for x in d]), 0.0)
	print(f"JOINT Blazegullet sac middle {np.round(c, 2).tolist()} facing {np.round(nrm, 2).tolist()} radius {R:.2f}, {int((w > 0.5).sum())} vertices; lips: no clean cut (they are the same jelly as the face), they ride the cage")
	pp = part("Sac", "Front", c - nrm * 0.4 * R, w, tail=c)
	pp["out"] = Vector(nrm)
	return [pp]


@monster("Pyrekeeper", 3000, hover=0.5, role="healer")
def rig_pyrekeeper(m):
	main = m.island == m.main
	z = m.co[:, 2]
	H = float(z.max())
	others = sorted(set(m.island.tolist()) - {m.main}, key=lambda k: -(m.island == k).sum())
	ringk = next(k for k in others if 25 < np.median(m.hue[m.island == k]) < 65)
	ring = m.island == ringk
	rl, rh, rc = _lohi(m, ring)
	ax = pca(m.co[ring])[1][2]
	ax = ax if ax[2] > 0 else -ax
	allring = ring | ((m.island != m.main) & ~ring)
	lo, hi, c = _lohi(m, main & (z < 0.4 * H))
	zs = np.arange(0.45 * H, 0.9 * H, 0.05)
	prof = zprof(m, main, c[0], c[1], zs, half=0.05)
	zb = float(zs[int(np.argmin(np.where(prof > 0, prof, 99)))])
	print("PROFILE Pyrekeeper radius by height:", [(round(a, 2), round(b, 2)) for a, b in zip(zs, prof)])
	braz = main & (z > zb)
	print(f"JOINT Pyrekeeper ring centre {np.round(rc, 2).tolist()} axis {np.round(ax, 2).tolist()} ({int(allring.sum())} vertices with its shards), brazier from the neck z {zb:.2f}")
	rp = part("Ring", "Body", rc, allring.astype(float), tail=Vector(rc) + Vector(ax))
	rp["spin_axis"] = Vector(ax)
	return [part("Brazier", "Top", (c[0], c[1], zb), soften(m, braz.astype(float), 2, keep=main.astype(float)), tail=(c[0], c[1], H)), rp]


@monster("Basaltback", 3000, role="armoured")
def rig_basaltback(m):
	main = m.island == m.main
	z = m.co[:, 2]
	dark = main & (m.val < 0.75)
	zc = float(np.percentile(z[dark], 8))
	cols = main & (z > zc)
	lo, hi, c = _lohi(m, cols)
	print(f"JOINT Basaltback columns from z {zc:.2f}, {int(cols.sum())} vertices")
	return [part("Columns", "Top", (c[0], c[1], zc), soften(m, cols.astype(float), 2), tail=(c[0], c[1], hi[2]))]


@monster("Magmaw", 6000, role="miniboss")
def rig_magmaw(m):
	main = m.island == m.main
	x, y, z = m.co.T
	lo, hi, c = _lohi(m, main)
	small, spikes = [], []
	for k in sorted(set(m.island.tolist()) - {m.main}):
		s = m.island == k
		cc = m.co[s].mean(0)
		if abs(cc[0] - c[0]) > 2.0 and cc[1] > -1.6:
			spikes.append(s)
		elif cc[1] < -1.2:
			small.append((float(cc[2]), s))
	zsort = sorted(zz for zz, s in small)
	gaps = [(zsort[i + 1] - zsort[i], (zsort[i + 1] + zsort[i]) / 2) for i in range(len(zsort) - 1)]
	zm = max(gaps)[1]
	lower = [s for zz, s in small if zz < zm]
	yj = max(float(m.co[s, 1].mean()) for s in lower) + 0.6
	w = np.where(main, np.array([sstep(yj, yj - 0.8, a) * sstep(zm, zm - 0.5, b) for a, b in zip(y, z)]), 0.0)
	for s in lower:
		w[s] = 1.0
	print(f"JOINT Magmaw mouth line z {zm:.2f} (gap between the teeth rows), jaw from y {yj:.2f} forward, lower teeth pieces {len(lower)}, jaw vertices {int((w > 0.5).sum())}")
	parts = [part("Jaw", "Front", (c[0], yj, zm - 0.2), w, tail=(c[0], yj - 1.0, zm - 0.2))]
	for s in spikes:
		side = "Left" if m.co[s, 0].mean() > c[0] else "Right"
		parts.append(onto(side, s.astype(float)))
	print(f"JOINT Magmaw shoulder spikes {len(spikes)} rigid on Left/Right")
	return parts


@monster("Calderos", 8000, role="boss")
def rig_calderos(m):
	main = m.island == m.main
	x, y, z = m.co.T
	H = float(z.max())
	lo, hi, c = _lohi(m, main)
	dark = (m.val < 0.72) & (m.sat > 0.5)
	yfr = float(np.percentile(y[main], 3))
	seed = dark & main & (y < yfr + 2.5) & (z > 1.8)
	bx = np.percentile(x[seed], [5, 95])
	bz = np.percentile(z[seed], [5, 95])
	ym = float(np.percentile(y[seed], 90))
	inbox = (x > bx[0]) & (x < bx[1]) & (z > bz[0]) & (z < bz[1])
	mask = main & inbox & (y < ym)
	plates, fins = {}, []
	for k in sorted(set(m.island.tolist()) - {m.main}):
		s = m.island == k
		cc = m.co[s].mean(0)
		if np.median(m.val[s]) > 0.85:
			continue  # magma pouring down: rides the cage
		if inbox[s].mean() > 0.5 and cc[1] < ym + 0.5:
			mask |= s
		elif abs(cc[0] - c[0]) > 3 and cc[2] < 6.5:
			side = "PlateL" if cc[0] > c[0] else "PlateR"
			if side not in plates or s.sum() > plates[side].sum():
				if side in plates:
					fins.append(plates[side])
				plates[side] = s
			else:
				fins.append(s)
		else:
			fins.append(s)
	print(f"JOINT Calderos mask box x {np.round(bx, 2).tolist()} z {np.round(bz, 2).tolist()} in front of y {ym:.2f}, {int(mask.sum())} vertices")
	parts = [part("Mask", "Top", (c[0], ym, float(np.mean(bz))), soften(m, mask.astype(float), 2), tail=(c[0], yfr, float(np.mean(bz))))]
	for side, s in plates.items():
		root, tip = _root_tip(m, s, main)
		parts.append(part(side, "Left" if side == "PlateL" else "Right", root, s.astype(float), tail=tip))
		print(f"JOINT Calderos {side} root {np.round(root, 2).tolist()}")
	# the mane: the molten mass above 0.6 H behind the mask, a chain sweeping back (and a little up)
	zm = 0.6 * H
	mane = main & (z > zm - 0.6) & (y > ym + 0.3)
	a = np.array([0.0, 1.0, 0.15])
	a /= np.linalg.norm(a)
	s = m.co @ a
	sj = list(np.percentile(s[mane & (z > zm)], [3, 35, 68, 98]))
	mparts, tot = axis_chain(m, mane, a, sj, ["Mane1", "Mane2", "Mane3"], "Top", fade=0.8, label="Calderos mane")
	zf = np.array([sstep(zm - 0.6, zm + 0.4, v) for v in z])
	for p in mparts:
		p["w"] = p["w"] * zf
	parts += mparts
	for f in fins:
		cc = m.co[f].mean(0)
		if cc[2] > zm - 1.0 and cc[1] > ym:
			u = float(np.interp(cc @ a, sj, np.arange(4)))
			parts.append(onto(f"Mane{min(int(u), 2) + 1}", f.astype(float)))
	return parts


# ---------------------------------------------------------------- motions
def mo_wickling(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.2)

	def wick(p1, r1=0.0, p2=None, r2=None):
		return {"Wick1.p": p1, "Wick1.r": r1, "Wick2.p": p1 * 1.3 if p2 is None else p2, "Wick2.r": r1 * 1.3 if r2 is None else r2}

	def p_idle(t, c):
		d = wick(0.06 * math.sin(math.pi * t - 1.0) - 0.6 * (ch(idle, t, "pitch", 0.2, Ti) - 0.05), 0.05 * math.sin(math.pi * t + 0.4),
			0.1 * math.sin(math.pi * t - 1.8), 0.08 * math.sin(math.pi * t - 0.5))
		d["Crust.z"] = 0.2 * H * (c["squash"] - ch(idle, t, "squash", 0.12, Ti))
		return d

	def p_move(t, c):
		u = t % Tm
		d = wick(-0.9 * ch(move, t, "pitch", 0.12, Tm) + 0.5 * ch(move, t, "squash", 0.15, Tm), 0.0,
			-1.2 * ch(move, t, "pitch", 0.2, Tm) + 0.7 * ch(move, t, "squash", 0.22, Tm), 0.0)
		d["Crust.z"] = 0.3 * (ch(move, t, "lift", 0.05, Tm) - c["lift"])
		d["Crust.r"] = ring(u, 0.68, 0.06, 7, 0.25) + ring(u + Tm, 0.68, 0.06, 7, 0.25)
		return d

	def attack(t):
		return C(fwd=keys(t, [(0, 0), (0.22, 0.3), (0.35, -1.0), (0.55, -0.9), (0.85, 0)]),
			squash=keys(t, [(0, 0), (0.22, 0.2), (0.33, -0.22), (0.4, 0.12), (0.5, 0), (0.85, 0)]),
			pitch=keys(t, [(0, 0), (0.22, -0.2), (0.35, 0.28), (0.85, 0)]) + 0.15 * hump(t, 0.37, 0.44) + 0.15 * hump(t, 0.46, 0.53),
			lift=0.3 * hump(t, 0.24, 0.4)), {}

	def p_attack(t, c):
		d = wick(keys(t, [(0, 0), (0.22, 0.25), (0.35, -0.3)]) * (1 - sstep(0.35, 0.4, t)) + ring(t, 0.37, -0.35, 3, 0.3), 0.0,
			keys(t, [(0, 0), (0.25, 0.35), (0.38, -0.4)]) * (1 - sstep(0.38, 0.43, t)) + ring(t, 0.4, -0.45, 3, 0.3), 0.0)
		d["Crust.p"] = ring(t, 0.36, 0.06, 7, 0.25)
		return d

	def p_hit(t, c):
		d = wick(ring(t, 0.03, -0.3, 4, 0.3) * _end(t), ring(t, 0.03, 0.15, 5, 0.3) * _end(t))
		d["Crust.r"] = ring(t, 0, 0.08, 9, 0.2) * _end(t)
		d["Crust.z"] = 0.06 * hump(t, 0, 0.2)
		return d

	def p_die(t, c):
		d = wick(keys(t, [(0, 0), (0.15, -0.2), (1.1, 0.5)]), keys(t, [(0, 0), (1.1, 0.3)]), keys(t, [(0, 0), (0.2, -0.2), (1.1, 0.7)]), keys(t, [(0, 0), (1.1, 0.4)]))
		d["Crust.r"] = keys(t, [(0, 0), (1.0, 0.2)])
		d["Crust.z"] = keys(t, [(0, 0), (0.15, 0.08), (1.1, -0.2)])
		return d

	return _A(Ti, idle, p_idle, Tm, move, p_move, 0.85, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.37


def mo_scorchdart(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.1)

	def wave(t, A, f, lag=0.9, ph=0.0, grow=0.35):
		return {f"Spine{k + 1}.y": A * (1 + grow * k) * math.sin(TAU * f * t - lag * k + ph) for k in range(4)}

	def idle(t):
		return C(squash=0.04 * math.sin(math.pi * t), pitch=0.02 * math.sin(math.pi * t - 0.5)), {}

	def p_idle(t, c):
		return wave(t, 0.04, 0.5)

	Tm = 0.6
	w = TAU / Tm

	def move(t):  # a fast darting slither: a surge each beat, stretched as it shoots, gathered as it lands
		return C(fwd=-0.25 * math.sin(w * t), squash=-0.12 * math.sin(w * t) + 0.04, yaw=0.08 * math.sin(w * t + 0.8), lift=0.03 * H * (1 - math.cos(w * t)) / 2), {}

	def p_move(t, c):
		return wave(t, 0.14, 1 / Tm, 1.0)

	def attack(t):
		return C(fwd=keys(t, [(0, 0), (0.3, 0.5), (0.4, -2.0), (0.55, -1.9), (0.9, 0)]),
			squash=keys(t, [(0, 0), (0.3, 0.25), (0.38, -0.35), (0.5, -0.2), (0.62, 0.1), (0.9, 0)]),
			pitch=keys(t, [(0, 0), (0.3, -0.12), (0.4, 0.12), (0.9, 0)]), lift=0.15 * hump(t, 0.32, 0.5)), {}

	def p_attack(t, c):
		coil = keys(t, [(0, 0), (0.3, 1), (0.38, 0)])
		d = {f"Spine{k + 1}.y": coil * (0.0, 0.3, -0.4, 0.45)[k] + ring(t, 0.4 + 0.04 * k, (0.0, 0.12, -0.2, 0.3)[k], 3, 0.3) for k in range(4)}
		return d

	def p_hit(t, c):
		return {f"Spine{k + 1}.y": ring(t, 0.03 * k, 0.12 * (1 + 0.3 * k), 4, 0.3) * _end(t) for k in range(4)}

	def p_die(t, c):
		d = {f"Spine{k + 1}.y": keys(t, [(0, 0), (0.15, -0.1), (1.1, 0.25)]) for k in range(4)}
		d.update({f"Spine{k + 1}.p": keys(t, [(0, 0), (1.1, -0.05 * k)]) for k in range(1, 4)})
		return d

	return _A(2.0, idle, p_idle, Tm, move, p_move, 0.9, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.42


def mo_blazegullet(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.15, 1.15, 0.045)

	def p_idle(t, c):
		return {"Sac.o": 0.06 * math.sin(math.pi * t - 0.5) + 0.03 * math.sin(TAU * t)}

	def p_move(t, c):
		return {"Sac.o": 0.5 * ch(move, t, "squash", 0.1, Tm), "Sac.z": 0.3 * (ch(move, t, "lift", 0.07, Tm) - c["lift"])}

	def attack(t):
		return C(pitch=keys(t, [(0, 0), (0.42, -0.25), (0.62, 0.25), (1.2, 0)]) + ring(t, 0.62, 0.06, 3, 0.4),
			lift=keys(t, [(0, 0), (0.42, 0.25), (0.62, 0), (1.2, 0)]), squash=keys(t, [(0, 0), (0.42, -0.15), (0.62, 0.2), (0.8, 0)]),
			swell=keys(t, [(0, 0), (0.42, 0.12), (0.62, -0.05), (0.8, 0)])), {}

	def p_attack(t, c):
		return {"Sac.o": keys(t, [(0, 0), (0.42, 0.35), (0.6, 0.35), (0.66, -0.1), (0.85, 0)]) + ring(t, 0.85, 0.05, 4, 0.3),
			"Sac.z": keys(t, [(0, 0), (0.42, -0.1), (0.66, 0.05), (1.0, 0)])}

	def p_hit(t, c):
		return {"Sac.o": ring(t, 0.02, -0.15, 5, 0.3) * _end(t)}

	def p_die(t, c):
		return {"Sac.o": keys(t, [(0, 0), (0.15, 0.1), (1.1, -0.1)]), "Sac.z": keys(t, [(0, 0), (1.1, -0.2)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.2, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.64


def mo_pyrekeeper(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r)
	# the ring turns all the time: one turn per Idle loop (8 s, four bobs) and per Move loop (4 s, four darts) so
	# the loops join; two fast turns in the heal
	Ti, Tm = 8.0, 4.0

	def p_idle(t, c):
		return {"Ring.spin": TAU * t / Ti, "Ring.p": 0.03 * math.sin(math.pi * t / 2), "Brazier.p": -0.5 * (ch(idle, t, "pitch", 0.2, 2.0) - 0.08),
			"Brazier.r": -0.5 * ch(idle, t, "roll", 0.2, 2.0)}

	def p_move(t, c):
		return {"Ring.spin": TAU * t / Tm, "Ring.p": -0.3 * ch(move, t, "pitch", 0.1, 1.0), "Brazier.p": -0.7 * ch(move, t, "pitch", 0.12, 1.0)}

	def attack(t):
		return C(lift=keys(t, [(0, 0), (0.3, 0.3), (0.95, 0.3), (1.2, 0)]), squash=keys(t, [(0, 0), (0.3, -0.1), (0.95, -0.1), (1.2, 0)]),
			swell=0.08 * (hump(t, 0.35, 0.5) + hump(t, 0.55, 0.7) + hump(t, 0.75, 0.9)), pitch=keys(t, [(0, 0), (0.3, -0.08), (1.2, 0)])), {}

	def p_attack(t, c):
		return {"Ring.spin": 2 * TAU * sstep(0.05, 1.15, t), "Brazier.z": keys(t, [(0, 0), (0.3, 0.3), (0.95, 0.25), (1.2, 0)]),
			"Brazier.p": ring(t, 0.3, -0.1, 2, 0.3), "Brazier.r": ring(t, 0.35, 0.06, 2.5, 0.3)}

	def p_hit(t, c):
		e = _end(t)
		return {"Ring.p": ring(t, 0, 0.12, 4, 0.3) * e, "Ring.r": ring(t, 0.03, 0.08, 5, 0.3) * e, "Brazier.r": ring(t, 0, 0.08, 8, 0.25) * e,
			"Brazier.z": 0.06 * hump(t, 0, 0.2)}

	def p_die(t, c):
		return {"Ring.p": keys(t, [(0, 0), (0.6, 0.15), (1.0, 0.3)]), "Ring.spin": 0.6 * sstep(0, 0.9, t), "Ring.z": keys(t, [(0, 0), (1.0, -0.3)]),
			"Brazier.r": keys(t, [(0, 0), (1.1, 0.35)]), "Brazier.z": keys(t, [(0, 0), (1.1, -0.2)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.2, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.42


def mo_basaltback(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.06, 1.4, 0.03)

	def p_idle(t, c):
		return {"Columns.z": 0.2 * H * (c["squash"] - ch(idle, t, "squash", 0.2, Ti)), "Columns.p": 0.015 * math.sin(math.pi * t - 1.3)}

	def p_move(t, c):
		u = t % Tm
		return {"Columns.z": 0.4 * (ch(move, t, "lift", 0.06, Tm) - c["lift"]) + ring(u, 0.68, -0.06, 6, 0.3) + ring(u + Tm, 0.68, -0.06, 6, 0.3),
			"Columns.p": ring(u, 0.7, 0.05, 7, 0.3) + ring(u + Tm, 0.7, 0.05, 7, 0.3)}

	def attack(t):
		return C(fwd=keys(t, [(0, 0), (0.35, 0.3), (0.45, 0.3), (0.58, -1.2), (0.7, -1.1), (1.1, 0)]),
			squash=keys(t, [(0, 0), (0.35, 0.2), (0.5, -0.1), (0.6, 0.12), (0.8, 0)]) + ring(t, 0.6, 0.05, 3, 0.4),
			pitch=keys(t, [(0, 0), (0.35, -0.12), (0.58, 0.2), (1.1, 0)])), {}

	def p_attack(t, c):
		return {"Columns.f": 0.5 * (ch(attack, t, "fwd", 0.06) - c["fwd"]), "Columns.p": ring(t, 0.58, 0.1, 5, 0.3), "Columns.z": ring(t, 0.58, -0.08, 6, 0.3)}

	def p_hit(t, c):
		e = _end(t)
		return {"Columns.r": ring(t, 0, 0.05, 10, 0.2) * e, "Columns.p": ring(t, 0.02, 0.04, 9, 0.2) * e, "Columns.z": 0.05 * hump(t, 0, 0.2)}

	def p_die(t, c):
		return {"Columns.p": keys(t, [(0, 0), (1.1, 0.15)]), "Columns.r": keys(t, [(0, 0), (1.1, -0.1)]), "Columns.z": keys(t, [(0, 0), (0.15, 0.08), (1.1, -0.3)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.1, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.58


def mo_magmaw(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.08, 1.3, 0.035)

	def p_idle(t, c):
		return {"Jaw.p": 0.05 + 0.04 * math.sin(math.pi * t - 0.8)}

	def p_move(t, c):
		return {"Jaw.p": 0.05 + 0.6 * (ch(move, t, "lift", 0.06, Tm) - c["lift"]) / H * 4 + 0.3 * ch(move, t, "squash", 0.1, Tm)}

	def attack(t):
		return C(lift=keys(t, [(0, 0), (0.45, 1.2), (0.6, 1.2), (0.72, 0)]),
			squash=keys(t, [(0, 0), (0.2, 0.15), (0.45, -0.25), (0.62, -0.2), (0.72, 0)]) + ring(t, 0.72, 0.6, 1.8, 0.35),
			pitch=keys(t, [(0, 0), (0.45, -0.3), (0.65, 0.1), (1.3, 0)])), {}

	def p_attack(t, c):
		return {"Jaw.p": keys(t, [(0, 0.05), (0.45, 0.45), (0.65, 0.4), (0.74, -0.05), (1.3, 0.05)]) + ring(t, 0.74, 0.08, 4, 0.3)}

	def p_hit(t, c):
		return {"Jaw.p": 0.05 + 0.2 * hump(t, 0, 0.3) + ring(t, 0.1, 0.05, 5, 0.3) * _end(t)}

	def p_die(t, c):
		return {"Jaw.p": keys(t, [(0, 0.05), (0.2, 0.3), (1.1, 0.4)])}

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.3, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.72


def mo_calderos(r):
	H, Ti, idle, Tm, move, Th, hit, Td, die = std(r, 0.06, 1.5, 0.03)

	def mane(fn):
		return {f"Mane{k + 1}.p": fn(k) for k in range(3)}

	def plates(z=0.0, rr=0.0):
		return {"PlateL.z": z, "PlateR.z": z, "PlateL.r": rr, "PlateR.r": -rr}

	def p_idle(t, c):
		d = mane(lambda k: 0.04 * (1 + 0.5 * k) * math.sin(math.pi * t - 0.8 * k) - 0.4 * (ch(idle, t, "pitch", 0.2 + 0.1 * k, Ti) - 0.05))
		d["Mask.p"] = 0.01 * math.sin(math.pi * t - 0.3)
		return d

	def p_move(t, c):
		d = mane(lambda k: -0.6 * ch(move, t, "pitch", 0.1 + 0.07 * k, Tm) - 0.25 * ch(move, t, "squash", 0.12 + 0.07 * k, Tm))
		d.update(plates(0.3 * (ch(move, t, "lift", 0.05, Tm) - c["lift"])))
		return d

	def attack(t):
		return C(squash=keys(t, [(0, 0), (0.45, 0.3), (0.75, -0.35), (0.95, -0.25), (1.05, 0)]) + ring(t, 1.05, 0.6, 1.6, 0.35),
			lift=keys(t, [(0, 0), (0.45, 0), (0.75, 0.12 * H), (0.95, 0.12 * H), (1.05, 0)]),
			pitch=keys(t, [(0, 0), (0.45, 0.12), (0.75, -0.2), (1.05, 0.08), (1.6, 0)])), {}

	def p_attack(t, c):
		# chain turns add up bone to bone: about 0.4 rad of flare at the mane's end in all
		d = mane(lambda k: keys(t - 0.04 * k, [(0, 0), (0.45, -0.04), (0.75, 0.12 + 0.02 * k), (0.95, 0.1)]) * (1 - sstep(0.95, 1.3, t)) + ring(t, 1.05 + 0.05 * k, -0.1, 1.4, 0.3))
		d["Mask.p"] = keys(t, [(0, 0), (0.45, 0.08), (0.75, -0.35), (0.95, -0.3), (1.2, 0)]) + ring(t, 1.05, 0.15, 2.5, 0.3)
		d.update(plates(ring(t, 1.05, -0.12, 5, 0.3), keys(t, [(0, 0), (0.75, 0.12), (1.0, 0)])))
		return d

	def p_hit(t, c):
		d = mane(lambda k: -0.8 * ch(hit, t, "pitch", 0.06 + 0.04 * k))
		d["Mask.p"] = ring(t, 0, -0.05, 6, 0.3) * _end(t)
		return d

	def p_die(t, c):
		d = mane(lambda k: keys(t, [(0, 0), (0.2, 0.05), (1.1, -0.12)]))
		d["Mask.p"] = keys(t, [(0, 0), (0.15, -0.1), (1.1, 0.2)])
		d.update(plates(keys(t, [(0, 0), (1.1, -0.2)])))
		return d

	return _A(Ti, idle, p_idle, Tm, move, p_move, 1.6, attack, p_attack, Th, hit, p_hit, Td, die, p_die), 0.8


MOTION_FNS.update(Wickling=mo_wickling, Scorchdart=mo_scorchdart, Blazegullet=mo_blazegullet, Pyrekeeper=mo_pyrekeeper, Basaltback=mo_basaltback,
	Magmaw=mo_magmaw, Calderos=mo_calderos)

EXTREMES.update(
	Wickling=[("wick whips fwd", C(), {"Wick1.p": 0.3, "Wick2.p": 0.45}), ("wick back", C(), {"Wick1.p": -0.3, "Wick2.p": -0.4, "Wick1.r": 0.2}),
		("crust rattle", C(), {"Crust.r": 0.08, "Crust.z": 0.08}), ("dead", C(squash=0.85), {"Wick1.p": 0.5, "Wick2.p": 0.7, "Crust.r": 0.2, "Crust.z": -0.2})],
	Scorchdart=[("wave", C(), {"Spine1.y": 0.12, "Spine2.y": -0.16, "Spine3.y": 0.2, "Spine4.y": -0.24}), ("coiled", C(squash=0.25), {"Spine2.y": 0.3, "Spine3.y": -0.4, "Spine4.y": 0.45}),
		("darting", C(squash=-0.35), {}), ("dead", C(squash=0.85), {"Spine1.y": 0.25, "Spine2.y": 0.25, "Spine3.y": 0.25, "Spine4.y": 0.25})],
	Blazegullet=[("gulp", C(pitch=-0.25, swell=0.12), {"Sac.o": 0.35}), ("spit", C(pitch=0.25, squash=0.2), {"Sac.o": -0.1}), ("sagged", C(squash=0.85), {"Sac.o": -0.1, "Sac.z": -0.2})],
	Pyrekeeper=[("ring quarter turn", C(), {"Ring.spin": TAU / 4}), ("brazier lifted", C(swell=0.08), {"Brazier.z": 0.3, "Brazier.p": -0.1}),
		("ring tilted", C(), {"Ring.p": 0.3, "Ring.z": -0.3}), ("brazier tipped", C(squash=0.85), {"Brazier.r": 0.35, "Brazier.z": -0.2})],
	Basaltback=[("columns jolt", C(squash=0.2), {"Columns.z": -0.08, "Columns.p": 0.1}), ("columns lean", C(), {"Columns.p": 0.15, "Columns.r": -0.1}),
		("columns rattle", C(), {"Columns.r": 0.05, "Columns.p": 0.04, "Columns.z": 0.05})],
	Magmaw=[("jaw wide", C(pitch=-0.3, squash=-0.25), {"Jaw.p": 0.45}), ("jaw shut", C(squash=0.4), {"Jaw.p": -0.05}), ("dead", C(squash=0.85), {"Jaw.p": 0.4})],
	Calderos=[("mask back, mane flares", C(squash=-0.35, pitch=-0.2), {"Mask.p": -0.35, "Mane1.p": 0.12, "Mane2.p": 0.14, "Mane3.p": 0.16}),
		("mane whips down", C(squash=0.5), {"Mane1.p": -0.1, "Mane2.p": -0.1, "Mane3.p": -0.1, "Mask.p": 0.15}),
		("plates flare", C(), {"PlateL.r": 0.12, "PlateR.r": -0.12, "PlateL.z": -0.12, "PlateR.z": -0.12})],
)
