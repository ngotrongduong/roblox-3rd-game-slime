# Recolours the Quaternius leaf textures (CC0, but the author asks that the assets are not passed on as files, so the results stay in the
# gitignored art/models/quaternius/recolour/): the picture's alpha is kept, the colour is replaced by a target hue with the original's
# light and dark and a soft blotch noise so a crown is not one flat sheet. Run: python tools/map/recolour_leaves.py <the pack's Textures folder>
import os
import random
import sys

from PIL import Image, ImageFilter

source = sys.argv[1]
output = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art", "models", "quaternius", "recolour")
os.makedirs(output, exist_ok=True)

# name: (source picture, target colour at mid brightness)
JOBS = {
	"Twisted_Purple": ("Leaves_TwistedTree_C", (138, 70, 188)),
	"Twisted_Orange": ("Leaves_TwistedTree_C", (240, 122, 30)),
	"Twisted_Gold": ("Leaves_TwistedTree_C", (246, 186, 40)),
	"Common_Teal": ("Leaves_NormalTree_C", (40, 176, 150)),
	"Common_Purple": ("Leaves_NormalTree_C", (150, 80, 196)),
	# the village's bushes (2026-11-02): Bush_Common wears the twisted tree's red picture, a sunny village wants green ones
	# (the picture can also be taken from art/models/quaternius/Bush_Common.glb: its one image, saved as Leaves_TwistedTree_C.png)
	"Twisted_Green": ("Leaves_TwistedTree_C", (100, 160, 44)),
}
SIZE = 512

for name, (picture, target) in JOBS.items():
	if not os.path.exists(os.path.join(source, picture + ".png")):
		print("skipped", name, "(no", picture + ".png", "in", source + ")")
		continue
	im = Image.open(os.path.join(source, picture + ".png")).convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)
	r, g, b, a = im.split()
	grey = Image.merge("RGB", (r, g, b)).convert("L")
	pixels = [p for p, al in zip(grey.getdata(), a.getdata()) if al > 128]
	mean = max(sum(pixels) / max(len(pixels), 1), 1)
	rng = random.Random(name)
	blotch = Image.effect_noise((SIZE // 16, SIZE // 16), 40).resize((SIZE, SIZE), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
	out = Image.new("RGBA", (SIZE, SIZE))
	gd, bd, ad = grey.load(), blotch.load(), a.load()
	op = out.load()
	for y in range(SIZE):
		for x in range(SIZE):
			k = (gd[x, y] / mean) * (0.82 + 0.36 * bd[x, y] / 255)
			k = max(0.55, min(1.35, k))
			op[x, y] = (
				min(255, int(target[0] * k)),
				min(255, int(target[1] * k)),
				min(255, int(target[2] * k)),
				ad[x, y],
			)
	out.save(os.path.join(output, "Leaves_" + name + ".png"))
	print("wrote", name)
