"""Contact sheet of the emotion stage's faces: art/faces/review_emotions.png from art/faces/shots/<emotion>.png
(tools/slime/shoot_emotions.ps1 takes the shots). Each shot is cropped round the middle of the picture, where the slime is."""

import os

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SHOTS = os.path.join(ROOT, "art", "faces", "shots")
ORDER = ["normal", "happy", "laughing", "exciting", "wink", "admiring", "loved", "shy", "proud", "dare", "curious",
         "surprise", "scared", "angry", "sulking", "sad", "crying", "dizzy", "sleepy", "sleep", "bored", "hungry",
         "eating", "full"]
COLS, TILE, CROP = 6, 300, 560
sheet = Image.new("RGB", (COLS * TILE, (len(ORDER) + COLS - 1) // COLS * TILE), (255, 255, 255))
d = ImageDraw.Draw(sheet)
for i, name in enumerate(ORDER):
    path = os.path.join(SHOTS, name + ".png")
    if not os.path.exists(path):
        continue
    im = Image.open(path).convert("RGB")
    cx, cy = im.width // 2, int(im.height * 0.5)
    tile = im.crop((cx - CROP // 2, cy - CROP // 2 - 40, cx + CROP // 2, cy + CROP // 2 - 40)).resize((TILE, TILE), Image.LANCZOS)
    x, y = (i % COLS) * TILE, (i // COLS) * TILE
    sheet.paste(tile, (x, y))
    d.text((x + 6, y + 4), name, fill=(255, 255, 255))
sheet.save(os.path.join(ROOT, "art", "faces", "review_emotions.png"))
print("sheet", sheet.size)
