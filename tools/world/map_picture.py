"""Draws the world map's picture from the plan (the JSON of tools/world/export_plan.luau): the regions' ground, the rim
mountains, the bay, the Heart, the volcano, the river, the roads, the pads of the places and the lines between the level
bands. Flat and readable on a phone; what stands on the map (villages, zones, packs, waystones) is drawn by client/UiMap.

    python tools/world/map_picture.py <plan.json> <out.png> [pixels, default 1024]
"""

import json
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

plan = json.load(open(sys.argv[1], encoding="utf-8"))
out_path = sys.argv[2]
PIXELS = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
SUPER = 2  # drawn twice as large, then shrunk: smooth edges
W = PIXELS * SUPER
MAP = plan["map"]
SCALE = W / MAP["Size"]  # pixels to a stud

# The terrain's own colours (tools/world/build_terrain.luau).
GRASS = (126, 196, 72)
LEAFY = (168, 214, 84)
MUD = (84, 126, 110)
GROUND = (176, 102, 66)
BASALT = (104, 80, 72)
LAVA = (240, 120, 44)
SNOW = (236, 244, 252)
GLACIER = (176, 220, 244)
ROCK = (138, 132, 122)
SAND = (232, 210, 150)
SANDSTONE = (214, 180, 120)
COBBLE = (170, 164, 156)
WATER = (84, 172, 226)
GOO = (104, 222, 178)


def px(x, z):
    return ((x - MAP["MinX"]) * SCALE, (z - MAP["MinZ"]) * SCALE)


axis = (np.arange(W, dtype=np.float32) + 0.5) / SCALE
X, Z = np.meshgrid(MAP["MinX"] + axis, MAP["MinZ"] + axis)
rng = np.random.default_rng(7)


def noise(cells):
    """Smooth noise in -1..1, `cells` bumps across the picture."""
    small = (rng.random((cells, cells)) * 255).astype(np.uint8)
    big = Image.fromarray(small).resize((W, W), Image.BICUBIC)
    return np.asarray(big, dtype=np.float32) / 127.5 - 1


def colour(rgb):
    return np.array(rgb, dtype=np.float32)


def blend(image, rgb, mask):
    """image = image * (1 - mask) + rgb * mask; mask is 0..1 for every pixel."""
    image += (colour(rgb) - image) * mask[..., None]


def smooth(a, b, v):
    t = np.clip((v - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def hexcolour(text):
    text = text.lstrip("#")
    return tuple(int(text[i : i + 2], 16) for i in (0, 2, 4))


# ----- the regions' ground: the nearest seed wins, its edge frayed -----
fray_x, fray_z = X + 70 * noise(26), Z + 70 * noise(26)
best = np.full((W, W), np.inf, dtype=np.float32)
region = np.zeros((W, W), dtype=np.int8)
for index, entry in enumerate(plan["regions"]):
    for seed in entry["at"]:
        d = (fray_x - seed[0]) ** 2 + (fray_z - seed[1]) ** 2
        closer = d < best
        best[closer] = d[closer]
        region[closer] = index
ids = [entry["id"] for entry in plan["regions"]]
patch, fine = noise(48), noise(150)
image = np.zeros((W, W, 3), dtype=np.float32)
for index, name in enumerate(ids):
    here = region == index
    if name == "vale":
        image[here] = colour(LEAFY)
    elif name == "meadow":
        image[here] = colour(GRASS)
        blend(image, LEAFY, here * smooth(0.1, 0.5, patch))
    elif name == "mushroom":
        image[here] = colour(MUD)
        blend(image, (150, 110, 190), here * smooth(0.55, 0.8, fine) * 0.8)  # caps
    elif name == "ember":
        image[here] = colour(GROUND)
        blend(image, BASALT, here * smooth(0.0, 0.5, patch))
        blend(image, LAVA, here * smooth(0.62, 0.8, fine))
    elif name == "frost":
        image[here] = colour(SNOW)
        blend(image, GLACIER, here * smooth(0.2, 0.6, patch))
# (the regions' borders, softened)
image = np.asarray(
    Image.fromarray(image.astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5 * SUPER)), dtype=np.float32
).copy()
# rolling ground: light from the north-west
height = noise(20) + 0.5 * noise(56)
shade = np.gradient(height, axis=0) + np.gradient(height, axis=1)
image *= (1 - np.clip(shade * 9, -0.1, 0.1))[..., None]

# ----- the bay and the rim mountains -----
rim = plan["rim"]
rim_d = (np.abs(X - rim["x"]) ** rim["power"] + np.abs(Z - rim["z"]) ** rim["power"]) ** (1 / rim["power"])
shore = plan["seaZ"] + 380 * (np.abs(X) / 1000) ** 3 + 40 * noise(30)
sea = smooth(-10, 10, Z - shore)
blend(image, SAND, smooth(-60, -10, Z - shore) * (1 - sea))
relief = noise(16) + 0.5 * noise(40)
light = np.clip((np.gradient(relief, axis=0) + np.gradient(relief, axis=1)) * 12, -0.16, 0.16)
mountain = smooth(-30, 40, rim_d - rim["radius"]) * (1 - sea)
rock = colour(ROCK)[None, None, :] * (0.9 - light)[..., None]
snowy = (smooth(-900, -1500, Z) * (0.55 + 0.45 * smooth(-0.2, 0.5, relief)))[..., None]
rock = rock + (colour(SNOW) * (1 - 0.6 * np.clip(light, 0, 1))[..., None] - rock) * snowy
image += (rock - image) * mountain[..., None]
for peak in plan["peaks"]:
    d = np.hypot(X - peak[0], Z - peak[1])
    blend(image, (250, 252, 255), smooth(peak[2] * 0.9, peak[2] * 0.15, d) * 0.9)
    blend(image, (120, 128, 146), smooth(peak[2], peak[2] * 0.3, np.hypot(X - peak[0] - 60, Z - peak[1] - 60)) * 0.25)
blend(image, WATER, sea)
blend(image, (60, 140, 204), sea * smooth(40, 400, Z - shore) * 0.6)
bay = image.copy()  # (the river's mouth is washed back to this once the river is drawn)

# ----- the volcano -----
volcano = plan["volcano"]
dv = np.hypot(X - volcano["x"], Z - volcano["z"])
cone = smooth(volcano["radius"], volcano["radius"] * 0.8, dv)
blend(image, (86, 66, 62), cone)
blend(image, (132, 96, 82), cone * smooth(volcano["radius"] * 0.9, volcano["crater"], dv) * 0.7)
blend(image, LAVA, cone * smooth(0.45, 0.7, noise(90)) * smooth(volcano["radius"], volcano["crater"], dv))
blend(image, (255, 196, 70), smooth(volcano["crater"], volcano["crater"] * 0.6, dv))

# ----- the Heart: cliffs, crest, lake, island -----
heart = plan["heart"]
dh = np.hypot(X - heart["x"], Z - heart["z"])
blend(image, (112, 108, 104), smooth(heart["FootRadius"] + 10, heart["FootRadius"] - 20, dh))
blend(image, (176, 170, 160), smooth(heart["FootRadius"] - 20, heart["RimRadius"], dh) * (dh < heart["FootRadius"]))
blend(image, (150, 196, 96), smooth(heart["RimRadius"] - 4, heart["RimRadius"] - 34, dh))
lake = smooth(heart["LakeOuter"] + 5, heart["LakeOuter"] - 5, dh) * smooth(heart["LakeInner"] - 5, heart["LakeInner"] + 5, dh)
blend(image, GOO, lake)

# ----- lines: the river, the roads, the pads -----
canvas = Image.fromarray(np.clip(image, 0, 255).astype(np.uint8))
draw = ImageDraw.Draw(canvas)


def line(points, width, fill, edge=None):
    path = [px(p[0], p[1]) for p in points]
    width = max(1, round(width))
    if edge:
        draw.line(path, fill=edge, width=width + 2 * SUPER, joint="curve")
        for x, y in (path[0], path[-1]):
            r = width / 2 + SUPER
            draw.ellipse((x - r, y - r, x + r, y + r), fill=edge)
    draw.line(path, fill=fill, width=width, joint="curve")
    for x, y in (path[0], path[-1]):
        r = width / 2
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def disc(x, z, radius, fill, edge=None):
    cx, cy = px(x, z)
    r = radius * SCALE
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=edge, width=SUPER)


def curve(points, steps=12):
    """A smooth line through the points (Catmull-Rom)."""
    pts = [points[0]] + list(points) + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for s in range(steps):
            t = s / steps
            out.append(
                tuple(
                    0.5
                    * (
                        2 * p1[k]
                        + (p2[k] - p0[k]) * t
                        + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t * t
                        + (3 * p1[k] - p0[k] - 3 * p2[k] + p3[k]) * t**3
                    )
                    for k in (0, 1)
                )
            )
    out.append(tuple(points[-1][:2]))
    return out


river_width = max(plan["river"]["Width"] * SCALE * 1.5, 4 * SUPER)
fall, pool = heart["Fall"], heart["Pool"]
line([(fall["x"], heart["z"] + heart["LakeOuter"] - 10), (fall["x"], fall["z"]), (pool["x"], pool["z"])], river_width, GOO)
disc(pool["x"], pool["z"], pool["radius"], WATER)
line(curve(plan["river"]["points"]), river_width, WATER, (60, 140, 204))
mouth = np.asarray(canvas, dtype=np.float32)
mouth = mouth + (bay - mouth) * smooth(0, 12, Z - shore)[..., None]
canvas = Image.fromarray(np.clip(mouth, 0, 255).astype(np.uint8))
draw = ImageDraw.Draw(canvas)

ROAD = {"main": SAND, "lane": SAND, "trail": SANDSTONE, "causeway": COBBLE}
for road in plan["roads"]:
    width = max(road["width"] * SCALE * 2, 2.5 * SUPER)
    line(road["points"], width, ROAD.get(road["kind"], SANDSTONE), (120, 96, 70))
for road in plan["roads"]:  # (again without the edge, so crossings stay open)
    line(road["points"], max(road["width"] * SCALE * 2, 2.5 * SUPER), ROAD.get(road["kind"], SANDSTONE))

for village in plan["villages"]:
    disc(village["x"], village["z"], village["radius"] * 0.8, (196, 228, 128), (120, 160, 70))
disc(plan["hub"]["x"], plan["hub"]["z"], plan["hub"]["radius"], SAND, (150, 124, 84))
for zone in plan["zones"]:
    pad = SANDSTONE if zone["kind"] == "mini" else COBBLE
    disc(zone["x"], zone["z"], zone["radius"], pad, (110, 96, 84))

image = np.asarray(canvas, dtype=np.float32).copy()

# ----- the level bands: a light wash of each band's colour and a line where two meet -----
packs = plan["packs"]
village_d = np.full((W, W), np.inf, dtype=np.float32)
for village in plan["villages"]:
    village_d = np.minimum(village_d, np.hypot(X - village["x"], Z - village["z"]))
share = np.clip((village_d - packs["nearStuds"]) / (packs["farthest"] - packs["nearStuds"]), 0, 1)
level = np.round(packs["levelMin"] + (packs["levelMax"] - packs["levelMin"]) * share ** packs["curve"])
last = math.floor(packs["levelMax"] / packs["bandLevels"])
band = np.minimum(np.floor(level / packs["bandLevels"]), last).astype(np.int8)
land = (1 - sea) * (1 - mountain) * smooth(heart["FootRadius"] - 10, heart["FootRadius"] + 10, dh)


def grown(mask, pixels):
    """The mask spread `pixels` each way."""
    spread = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(2 * pixels + 1))
    return np.asarray(spread, dtype=np.float32) / 255


for index, text in enumerate(packs["bandColours"]):
    blend(image, hexcolour(text), (band == index) * land * 0.2)
for index, text in enumerate(packs["bandColours"]):
    if index == 0:
        continue
    # a band's own line is its inner edge, in its colour, with a dark rim so it reads on any ground
    tint = hexcolour(text)
    harder, easier = band >= index, band < index
    blend(image, tuple(c * 0.4 for c in tint), grown(harder, 3 * SUPER) * grown(easier, 3 * SUPER) * land * 0.9)
    blend(image, tint, grown(harder, 2 * SUPER) * grown(easier, 2 * SUPER) * land)

result = Image.fromarray(np.clip(image, 0, 255).astype(np.uint8)).resize((PIXELS, PIXELS), Image.LANCZOS)
result.save(out_path)
print("map written to", out_path, result.size)
