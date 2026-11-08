# Goo Lineage V2 - the Secret slimes' skins from ChatGPT brought to the slime skin format: 2048 x 1024 PNG with the
# left and right edges cross-faded so the seam at the slime's back does not show (as prepare_zombie_skins.py).
#   python tools/skins/prepare_secret_skins.py <group number> [<group number> ...]
#   python tools/skins/prepare_secret_skins.py <group> --pick 1 4 5   (which gen_N is each subject's skin, 0 skips one;
#   plain numbers with spaces: commas or a "-" there made PowerShell ask the owner "Allow once")
# Reads art/turnaround/skins-g<N>/gen_1.. (brought back in page order) and subjects.txt (the subjects in the order
# asked); writes art/models/slime_body/skins/s_<colours>.png, a copy in art/upload_now/, and skins-g<N>/sheet.jpg.
import os
import sys
from PIL import Image, ImageChops, ImageDraw

ROOT = "C:/Roblox 3rd game/"
WORK = ROOT + "art/turnaround/"
SKINS = ROOT + "art/models/slime_body/skins/"
UPLOAD = ROOT + "art/upload_now/"
BLEND = 24  # pixels each side of the seam
BAND_DIST = 40  # max channel difference to a top corner's colour for a pixel to belong to an empty top band
BAND_MAX = 0.3  # a band reaching lower than this share of the height is part of the design, not empty


def find(folder, name):
	for ext in (".webp", ".png", ".jpg"):
		if os.path.exists(folder + name + ext):
			return folder + name + ext
	return None


def seamless(image):
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
	return apart / height


# ChatGPT often draws the slime's rounded top as an empty band (white or one flat colour) with a bump in the middle,
# though asked not to. The top of the skin is squeezed into the tip anyway, so the band is cut off and the rest
# stretched back to 2:1: a flood from each top corner over pixels of the corner's colour, kept only if it spans
# most of the width and stays in the top BAND_MAX.
def trim_top(image):
	w, h = image.size
	cut = 0
	for corner in ((0, 0), (w - 1, 0)):
		key = image.getpixel(corner)
		r, g, b = ImageChops.difference(image, Image.new("RGB", image.size, key)).split()
		near = ImageChops.lighter(ImageChops.lighter(r, g), b).point(lambda d: 255 if d < BAND_DIST else 0)
		ImageDraw.floodfill(near, corner, 128)
		box = near.point(lambda v: 255 if v == 128 else 0).getbbox()
		if box and box[3] < h * BAND_MAX and box[2] - box[0] > w * 0.4:
			cut = max(cut, box[3] + 2)
	return (image.crop((0, cut, w, h)).resize((w, h), Image.LANCZOS), cut) if cut else (image, 0)


os.makedirs(UPLOAD, exist_ok=True)
pick = sys.argv[sys.argv.index("--pick") + 1 :] if "--pick" in sys.argv else None
for group in (sys.argv[1:2] if pick else sys.argv[1:]):
	folder = WORK + ("skins-g" + group if group.isdigit() else group) + "/"  # a number, or a folder like rich-g3
	subjects = open(folder + "subjects.txt", encoding="utf-8").read().split()
	# the chat's own attachments come back too (512 px pictures, the 1024 px format example): skins are the big ones
	gens = []
	k = 1
	while find(folder, "gen_%d" % k):
		if Image.open(find(folder, "gen_%d" % k)).width >= 1200:
			gens.append(find(folder, "gen_%d" % k))
		k += 1
	gens = [find(folder, "gen_" + n) if n != "0" else None for n in pick] if pick else gens[-len(subjects):]
	sheet = Image.new("RGB", (1024, 512 * len(subjects)), (128, 128, 128))
	for i, subject in enumerate(subjects):
		if i >= len(gens) or not gens[i]:
			print("[GooLineage] %s: no skin for %s" % (group, subject))
			continue
		raw = Image.open(gens[i]).convert("RGB")
		trimmed, cut = trim_top(raw)
		image = trimmed.resize((2048, 1024), Image.LANCZOS)
		apart = seamless(image)
		if cut:
			print("[GooLineage] %s: cut an empty top band of %d px" % (subject, cut))
		target = "s_" + subject.replace("secret-", "") + ".png"
		image.save(SKINS + target)
		image.save(UPLOAD + target)
		sheet.paste(image.resize((1024, 512), Image.LANCZOS), (0, 512 * i))
		print("[GooLineage]", target, "from", raw.size, "edges apart by", round(apart, 1), "of 255")
	sheet.save(folder + "sheet.jpg", quality=85)
