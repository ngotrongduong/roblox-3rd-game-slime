# The main colours of a four-side sheet's front view (its top-left quarter), the background left out: k-means in RGB.
# Each surface comes out twice, lit and shaded: a palette takes the lit tone or one between, never the shaded one.
# python tools/map/sheet_colours.py docs/areas/village-v2/views/granary_views_era3.webp 16
import sys

import numpy as np
from PIL import Image

path = sys.argv[1]
k = int(sys.argv[2]) if len(sys.argv) > 2 else 12
im = np.asarray(Image.open(path).convert("RGB")).astype(float)
h, w, _ = im.shape
q = im[: h // 2, : w // 2].reshape(-1, 3)
bg = np.median(im[5:40, 5:40].reshape(-1, 3), axis=0)
q = q[np.abs(q - bg).sum(1) > 30]
rng = np.random.default_rng(1)
pts = q[rng.choice(len(q), min(len(q), 40000), replace=False)]
c = pts[rng.choice(len(pts), k, replace=False)]
for _ in range(30):
	lab = np.argmin(((pts[:, None] - c[None]) ** 2).sum(-1), 1)
	c = np.array([pts[lab == i].mean(0) if (lab == i).any() else c[i] for i in range(k)])
share = np.bincount(lab, minlength=k) / len(lab)
for i in np.argsort(-share):
	print("%5.1f%%  %3d %3d %3d" % (share[i] * 100, *c[i]))
