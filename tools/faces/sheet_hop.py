"""The hop strip: art/faces/hop_strip.png from art/faces/shots/hop_<n>.png (tools/slime/hop_strip.ps1). Usage: sheet_hop.py N"""

import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SHOTS = os.path.join(ROOT, "art", "faces", "shots")
n = int(sys.argv[1])
W, H = 360, 360
sheet = Image.new("RGB", (W * min(n, 4), H * ((n + 3) // 4)), (255, 255, 255))
for i in range(1, n + 1):
    im = Image.open(os.path.join(SHOTS, "hop_%d.png" % i)).convert("RGB")
    cx, cy = im.width // 2, im.height // 2
    tile = im.crop((cx - 380, cy - 330, cx + 380, cy + 430)).resize((W, H), Image.LANCZOS)
    sheet.paste(tile, (((i - 1) % 4) * W, ((i - 1) // 4) * H))
sheet.save(os.path.join(ROOT, "art", "faces", "hop_strip.png"))
