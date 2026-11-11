# Composes monster_rig.py's review tiles into art/models/monster_slimes/<region>/review/<Name>_weights.png (each bone a
# colour, front/side/back/top, with a legend) and <Name>_poses.png (rest, squash, stretch, attack peak and each part at its
# extreme; front row and side row). Run by monster_rig.ps1 with the system python (needs PIL).
import json, os, sys, tempfile
from PIL import Image, ImageDraw

REGION = sys.argv[1] if len(sys.argv) > 1 else "meadow"
TILES = os.path.join(tempfile.gettempdir(), "monster_rig", REGION)
REVIEW = os.path.join("C:/Roblox 3rd game/art/models/monster_slimes", REGION, "review")


def load(name):
	p = os.path.join(TILES, name)
	return json.load(open(p)) if os.path.exists(p) else {}


for name, d in load("manifest_weights.json").items():
	w = d["weights"]
	tiles = [Image.open(t).convert("RGB") for t in w["tiles"]]
	s = tiles[0].size[0]
	sheet = Image.new("RGB", (s * len(tiles) + 170, s), (240, 240, 240))
	for k, t in enumerate(tiles):
		sheet.paste(t, (k * s, 0))
	dr = ImageDraw.Draw(sheet)
	for k, (nm, c) in enumerate(w["legend"]):
		y = 6 + k * 18
		dr.rectangle([s * len(tiles) + 8, y, s * len(tiles) + 22, y + 12], fill=tuple(int(x * 255) for x in c))
		dr.text((s * len(tiles) + 28, y), nm, fill=(0, 0, 0))
	sheet.save(os.path.join(REVIEW, f"{name}_weights.png"))
	print("SHEET", name, "weights")

for name, t in load("manifest_tex.json").items():
	if not t:
		continue
	s = 420
	sheet = Image.new("RGB", (s * 5, s + 20), (240, 240, 240))
	dr = ImageDraw.Draw(sheet)
	for k, (key, label) in enumerate((("before", "4096 shared, front"), ("after", "own 1024, front"), ("before_b", "4096, back"),
			("after_b", "1024, back"), ("uv", "the 1024 image"))):
		im = Image.open(t[key]).convert("RGB").resize((s, s))
		sheet.paste(im, (k * s, 20))
		dr.text((k * s + 6, 4), label, fill=(0, 0, 0))
	sheet.save(os.path.join(REVIEW, f"{name}_texture.png"))
	print("SHEET", name, "texture")

for name, d in load("manifest_poses.json").items():
	cols = d["poses"]
	first = Image.open(cols[0]["front"])
	s = first.size[0]
	sheet = Image.new("RGB", (s * len(cols), 2 * s + 20), (240, 240, 240))
	dr = ImageDraw.Draw(sheet)
	for k, c in enumerate(cols):
		dr.text((k * s + 6, 4), c["label"], fill=(0, 0, 0))
		sheet.paste(Image.open(c["front"]).convert("RGB"), (k * s, 20))
		sheet.paste(Image.open(c["side"]).convert("RGB"), (k * s, 20 + s))
	sheet.save(os.path.join(REVIEW, f"{name}_poses.png"))
	print("SHEET", name, "poses")
