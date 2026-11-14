# A round floor picture from ChatGPT (art/inbox/<name>.webp, painted on flat magenta) made ready to upload as a Decal:
# the magenta keyed out, trimmed to the disc, 1024 px edge to edge. Writes art/world/<name>.png.
#   python tools/chatgpt/prepare_floor.py heart_medallion
import os
import sys
from PIL import Image

from prepare_icons import key_out

ROOT = "C:/Roblox 3rd game/"
OUT = ROOT + "art/world/"
SIZE = 1024


def main():
	os.makedirs(OUT, exist_ok=True)
	for name in sys.argv[1:]:
		image = Image.open(ROOT + "art/inbox/" + name + ".webp").convert("RGBA")
		key_out(image)
		box = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
		image = image.crop(box)
		side = max(image.size)
		sheet = Image.new("RGBA", (side, side), (0, 0, 0, 0))
		sheet.paste(image, ((side - image.width) // 2, (side - image.height) // 2), image)
		sheet.resize((SIZE, SIZE), Image.LANCZOS).save(OUT + name + ".png")
		print(name, "ready, was", box)


if __name__ == "__main__":
	main()
