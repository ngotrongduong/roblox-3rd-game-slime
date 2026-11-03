# A UI icon from the owner's own art (reference/goo-lineage-web/assets/<file>.png, already transparent): trimmed to its
# bounds, padded to a square and sized 256, nothing else changed. Writes art/icons/<name>.png.
#   python tools/art/owner_icon.py equip-sword attack-sword
import os
import sys
from PIL import Image

ROOT = "C:/Roblox 3rd game/"
OUT = ROOT + "art/icons/"
SIZE = 256
PAD = 8

source, name = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
image = Image.open(ROOT + "reference/goo-lineage-web/assets/" + source + ".png").convert("RGBA")
box = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
image = image.crop(box)
inner = SIZE - 2 * PAD
scale = inner / max(image.size)
image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.LANCZOS)
sheet = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
sheet.paste(image, ((SIZE - image.width) // 2, (SIZE - image.height) // 2), image)
sheet.save(OUT + name + ".png")
print(name, "ready, was", box)
