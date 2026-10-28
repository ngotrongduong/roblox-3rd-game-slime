# Builds one contact sheet of review pictures: python sheet.py out.jpg a.jpg b.jpg ...
# Each picture is cropped to its middle (the building) and labelled by its file name.
import sys
from PIL import Image, ImageDraw

out, files = sys.argv[1], sys.argv[2:]
TILE_W, TILE_H = 760, 470
cols = 2 if len(files) <= 4 else 3
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * TILE_W, rows * TILE_H), "white")
draw = ImageDraw.Draw(sheet)
for k, f in enumerate(files):
    im = Image.open(f).convert("RGB")
    w, h = im.size
    # keep the middle 60% of the width, full height, then fit the tile
    box = (int(w * 0.2), 0, int(w * 0.8), h)
    im = im.crop(box)
    im.thumbnail((TILE_W, TILE_H))
    x, y = (k % cols) * TILE_W, (k // cols) * TILE_H
    sheet.paste(im, (x + (TILE_W - im.width) // 2, y + (TILE_H - im.height) // 2))
    label = f.replace("\\", "/").split("/")[-1].rsplit(".", 1)[0]
    draw.rectangle((x, y, x + 170, y + 26), fill="black")
    draw.text((x + 6, y + 6), label, fill="white")
sheet.save(out, quality=78)
print(out, sheet.size)
