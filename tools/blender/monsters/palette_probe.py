# Prints the main colours of the owner's seven monster paintings (k-means over the opaque pixels, sRGB), with the share
# and the mean position of each colour (painting px), so the palettes in the monster scripts are MEASURED, not guessed.
# Run: tools/blender/monsters/probe.ps1   (reads reference/goo-lineage-web/assets/enemy-green-*.png, writes nothing)
import bpy
import numpy as np

ART = "C:/Roblox 3rd game/reference/goo-lineage-web/assets/"
NAMES = ["sprout", "bee", "dandelion", "moth", "snail", "turtle", "boar"]
K = 16


def load(path):
	img = bpy.data.images.load(path, check_existing=False)
	w, h = img.size
	a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1].copy()
	bpy.data.images.remove(img)
	return a


for nm in NAMES:
	a = load(ART + "enemy-green-%s.png" % nm)
	h, w = a.shape[:2]
	ys, xs = np.nonzero(a[:, :, 3] > 0.9)
	sel = np.random.RandomState(1).choice(len(ys), 20000, replace=False)
	ys, xs = ys[sel], xs[sel]
	px = a[ys, xs, :3]
	rng = np.random.RandomState(2)
	cen = px[rng.choice(len(px), K, replace=False)]
	for _ in range(25):
		d = ((px[:, None, :] - cen[None]) ** 2).sum(2)
		lab = d.argmin(1)
		for k in range(K):
			m = lab == k
			if m.any():
				cen[k] = px[m].mean(0)
	print("== %s (%d x %d), opaque bbox x %d..%d y %d..%d" % (nm, w, h, xs.min(), xs.max(), ys.min(), ys.max()))
	order = np.argsort(-np.bincount(lab, minlength=K))
	for k in order:
		m = lab == k
		c = (np.clip(cen[k], 0, 1) * 255).round().astype(int)
		print("  #%02X%02X%02X  %4.1f%%  at x %4d y %4d" % (c[0], c[1], c[2], 100 * m.mean(), xs[m].mean(), ys[m].mean()))
