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

os.makedirs(OUT, exist_ok=True)
for name in sys.argv[1:]:
	image = Image.open(ROOT + "art/inbox/" + name + ".webp").convert("RGBA")
	px = image.load()
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, _ = px[x, y]
			# how magenta: red and blue both far above green
			key = min(r, b) - g
			if key > 40:
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
	box = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
	image = image.crop(box)
	inner = SIZE - 2 * PAD
	scale = inner / max(image.size)
	image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.LANCZOS)
	sheet = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	sheet.paste(image, ((SIZE - image.width) // 2, (SIZE - image.height) // 2), image)
	sheet.save(OUT + name + ".png")
	print(name, "ready, was", box)
