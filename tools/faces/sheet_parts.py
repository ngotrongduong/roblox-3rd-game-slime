"""Contact sheet of every cut and drawn face part: art/faces/review_parts.png (python tools/faces/sheet_parts.py)."""

import json
import os

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "art", "faces")
data = json.load(open(os.path.join(OUT, "faces.json")))["sprites"]
names = sorted(data, key=lambda n: (data[n]["source"] != "owner", n))
CW, CH, COLS = 150, 120, 8
rows = (len(names) + COLS - 1) // COLS
sheet = Image.new("RGB", (CW * COLS, CH * rows), (150, 190, 140))
d = ImageDraw.Draw(sheet)
for i, n in enumerate(names):
    im = Image.open(os.path.join(OUT, data[n]["file"])).convert("RGBA")
    k = min(1.0, (CW - 10) / im.width, (CH - 26) / im.height)
    if k < 1:
        im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    x, y = (i % COLS) * CW, (i // COLS) * CH
    sheet.paste(im, (x + (CW - im.width) // 2, y + 4), im)
    d.text((x + 4, y + CH - 16), n, fill=(0, 0, 0))
sheet.save(os.path.join(OUT, "review_parts.png"))
