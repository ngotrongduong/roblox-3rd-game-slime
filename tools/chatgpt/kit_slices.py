# The UI kit made ready to upload (tools/chatgpt/ui_kit.json): each sliced piece keeps its edges and only a STRIP-pixel
# stretch strip taken from a clean place (small textures for phones, no ornament smeared), each whole piece is kept as it
# is, no side above MAX. Writes art/ui/kit/<name>.png and prints the Config.Ui.Kit lines (Id 0 until uploaded).
#   python tools/chatgpt/kit_slices.py
import json
from PIL import Image

ROOT = "C:/Roblox 3rd game/"
KIT = ROOT + "art/ui/kit/"
STRIP = 8
MAX = 512


def squeeze(image, low, high, at, axis):
	# keep [0, low) + STRIP pixels at `at` + [size - high, size) along one axis
	size = image.width if axis == 0 else image.height
	if low == 0 and high == 0:
		return image
	start = min(max(at - STRIP // 2, low), size - high - STRIP)
	spans = [(0, low), (start, start + STRIP), (size - high, size)]
	total = low + STRIP + high
	out = Image.new("RGBA", (total, image.height) if axis == 0 else (image.width, total), (0, 0, 0, 0))
	pos = 0
	for a, b in spans:
		box = (a, 0, b, image.height) if axis == 0 else (0, a, image.width, b)
		out.paste(image.crop(box), (pos, 0) if axis == 0 else (0, pos))
		pos += b - a
	return out


def main():
	manifest = json.load(open(ROOT + "tools/chatgpt/ui_kit.json"))
	lines = []
	for name, piece in manifest["pieces"].items():
		image = Image.open(KIT + piece["from"] + ".png").convert("RGBA")
		margins = piece.get("margins")
		if margins:
			left, top, right, bottom = margins
			cx, cy = piece.get("clean", [image.width // 2, image.height // 2])
			cx = cx or image.width // 2
			cy = cy or image.height // 2
			image = squeeze(image, left, right, cx, 0)
			image = squeeze(image, top, bottom, cy, 1)
			w, h = image.size
			lines.append(
				"\t\t%s = { Id = 0, Width = %d, Height = %d, Slice = { %d, %d, %d, %d } },"
				% (name, w, h, left, top, w - right, h - bottom)
			)
		else:
			scale = min(1, MAX / max(image.size))
			if scale < 1:
				image = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
			lines.append("\t\t%s = { Id = 0, Width = %d, Height = %d }," % (name, image.width, image.height))
		image.save(KIT + name + ".png")
	print("\n".join(lines))


if __name__ == "__main__":
	main()
