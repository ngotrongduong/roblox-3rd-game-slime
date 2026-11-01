# The three zombie skins from ChatGPT (art/inbox/zskin1..3.webp) brought to the slime skin format: 2048 x 1024 PNG, with
# the left and right edges cross-faded so the seam at the slime's back does not show. Prints how far the edges were apart.
#   python tools/skins/prepare_zombie_skins.py
import os
from PIL import Image

ROOT = "C:/Roblox 3rd game/"
SKINS = ROOT + "art/models/slime_body/skins/"
UPLOAD = ROOT + "art/upload_now/"
BLEND = 24  # pixels each side of the seam
NAMES = {"zskin1.webp": "z_rotten.png", "zskin2.webp": "z_toxic.png", "zskin3.webp": "z_plague.png"}

os.makedirs(UPLOAD, exist_ok=True)
for source, target in NAMES.items():
	image = Image.open(ROOT + "art/inbox/" + source).convert("RGB").resize((2048, 1024), Image.LANCZOS)
	px = image.load()
	width, height = image.size
	apart = 0
	for y in range(height):
		left, right = px[0, y], px[width - 1, y]
		apart += sum(abs(a - b) for a, b in zip(left, right)) / 3
		middle = tuple((a + b) // 2 for a, b in zip(left, right))
		for x in range(BLEND):
			keep = x / BLEND
			px[x, y] = tuple(int(m + (c - m) * keep) for m, c in zip(middle, px[x, y]))
			mirror = width - 1 - x
			px[mirror, y] = tuple(int(m + (c - m) * keep) for m, c in zip(middle, px[mirror, y]))
	image.save(SKINS + target)
	image.save(UPLOAD + target)
	print(target, "edges apart by", round(apart / height, 1), "of 255 on average")
