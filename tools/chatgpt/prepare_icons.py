# UI icons from ChatGPT (art/inbox/<name>.webp, painted on flat magenta) made ready to upload: the magenta keyed out with a
# soft edge and no pink fringe, trimmed, padded to a square and sized 256. Writes art/icons/<name>.png.
#   python tools/chatgpt/prepare_icons.py skull energy fun close back plus
import os
import sys
from PIL import Image

ROOT = "C:/Roblox 3rd game/"
OUT = ROOT + "art/icons/"
SIZE = 256
PAD = 8

def keyness(p):
	# how magenta: red and blue both far above green
	return min(p[0], p[2]) - p[1]


# The background: each patch of magenta-ish pixels that touches the picture's edge, or that is nearly all flat pure magenta
# (the hole in a ring). A glowing violet gem inside an outline is a patch of shaded violet, so it stays.
def background(image):
	px = image.load()
	w, h = image.size
	patch = [0] * (w * h)
	back = bytearray(w * h)
	label = 0
	for sy in range(h):
		for sx in range(w):
			if patch[sy * w + sx] or keyness(px[sx, sy]) <= 40:
				continue
			label += 1
			patch[sy * w + sx] = label
			stack, cells, pure, edge = [(sx, sy)], [], 0, False
			while stack:
				x, y = stack.pop()
				cells.append(y * w + x)
				r, g, b, _ = px[x, y]
				if r > 235 and b > 235 and g < 30:
					pure += 1
				if x == 0 or y == 0 or x == w - 1 or y == h - 1:
					edge = True
				for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
					if 0 <= nx < w and 0 <= ny < h and not patch[ny * w + nx] and keyness(px[nx, ny]) > 40:
						patch[ny * w + nx] = label
						stack.append((nx, ny))
			if edge or pure > 0.6 * len(cells):
				for c in cells:
					back[c] = 1
	return back


# The magenta background made see-through in place, with a soft edge and no pink fringe (also used by prepare_ui_kit.py).
def key_out(image):
	px = image.load()
	back = background(image)
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, _ = px[x, y]
			key = keyness((r, g, b))
			if key > 40 and back[y * image.width + x]:
				amount = min(1, (key - 40) / 100)
				keep = 1 - amount
				if keep <= 0:
					px[x, y] = (0, 0, 0, 0)
				else:
					# take the magenta back out of an edge pixel
					px[x, y] = (
						max(0, min(255, int(r - (255 - g) * amount))),
						g,
						max(0, min(255, int(b - (255 - g) * amount))),
						int(255 * keep),
					)


def main():
	os.makedirs(OUT, exist_ok=True)
	for name in sys.argv[1:]:
		path = ROOT + "art/inbox/" + name
		image = Image.open(path + (".webp" if os.path.exists(path + ".webp") else ".png")).convert("RGBA")
		key_out(image)
		box = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
		image = image.crop(box)
		inner = SIZE - 2 * PAD
		scale = inner / max(image.size)
		image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.LANCZOS)
		sheet = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
		sheet.paste(image, ((SIZE - image.width) // 2, (SIZE - image.height) // 2), image)
		sheet.save(OUT + name + ".png")
		print(name, "ready, was", box)


if __name__ == "__main__":
	main()
