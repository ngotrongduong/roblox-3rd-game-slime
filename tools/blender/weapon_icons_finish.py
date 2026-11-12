# Turns the Legendary weapon renders (art/models/weapons/review/icon_<id>.png, tools/blender/weapon_icons.py) into Smithy
# pictures like the other weapons': trimmed, a dark outline round the shape, centred on a 256 px transparent square.
import os
from PIL import Image, ImageFilter

REVIEW = "C:/Roblox 3rd game/art/models/weapons/review"
OUT = "C:/Roblox 3rd game/art/icons/weapons"
IDS = ["sword-legend", "shield-legend", "bow-legend", "focus-legend", "staff-legend", "kit-legend"]
OUTLINE = 9  # px at 512, about the width of the painted pictures' line
INK = (45, 28, 22, 255)
SIZE = 256
PAD = 10

for gear in IDS:
	image = Image.open(os.path.join(REVIEW, f"icon_{gear}.png")).convert("RGBA")
	box = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
	image = image.crop(box)
	# room for the line all round
	canvas = Image.new("RGBA", (image.width + OUTLINE * 2 + 4, image.height + OUTLINE * 2 + 4), (0, 0, 0, 0))
	canvas.paste(image, (OUTLINE + 2, OUTLINE + 2))
	alpha = canvas.getchannel("A").point(lambda a: 255 if a > 40 else 0)
	grown = alpha.filter(ImageFilter.MaxFilter(OUTLINE * 2 + 1)).filter(ImageFilter.GaussianBlur(1.2))
	ink = Image.new("RGBA", canvas.size, INK)
	ink.putalpha(grown)
	ink.alpha_composite(canvas)
	side = max(ink.width, ink.height)
	square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	square.paste(ink, ((side - ink.width) // 2, (side - ink.height) // 2))
	inner = SIZE - PAD * 2
	square = square.resize((inner, inner), Image.LANCZOS)
	final = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	final.paste(square, (PAD, PAD))
	final.save(os.path.join(OUT, f"{gear}.png"))
	print(f"ICONFILE {gear} {final.size}")
