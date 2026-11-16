"""Draws each Dungeon map's own sky box (the owner, 2026-11-16: "each dungeon its own skybox"): three pictures a map in
art/sky/<map>/ - `side` (worn by all four sides: it tiles left to right, so the box has no seam however Roblox turns its
faces), `up` and `down`. The colour is a gradient by the height of the view over the horizon (the same at every face's
edge, so the faces meet), with soft clouds in a band over the horizon and, on a dusk map, a few stars.

    python tools/world/dungeon_sky.py            (all maps)
    python tools/world/dungeon_sky.py meadow     (one)
"""

import math
import os
import sys

import numpy as np
from PIL import Image

SIZE = 512
ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "art", "sky")


def hexrgb(text):
    text = text.lstrip("#")
    return np.array([int(text[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


# Each map: the gradient's stops (degrees over the horizon -> colour), its clouds (colour lit and in shade, how much of
# the band they cover, how high the band reaches in degrees) and its stars (how many on the top face).
MAPS = {
    # Sunny Meadow: a bright cozy day, deep blue overhead, pale near the land, white fluffy clouds
    "meadow": {
        "stops": [(-90, "#bfe0f2"), (0, "#e8f6ff"), (8, "#bfe3fb"), (30, "#7cc0f2"), (90, "#3f8fe0")],
        "cloud": ("#ffffff", "#c9dcef"),
        "cover": 0.42,
        "band": 34,
        "stars": 0,
    },
    # Mushroom Grove: teal-violet dusk, a warm peach band low down, violet clouds lit pink from below, a few stars
    "mushroom": {
        "stops": [(-90, "#2b3150"), (0, "#f0a890"), (6, "#b98aa8"), (22, "#5a4f8a"), (55, "#2a2c5c"), (90, "#161a3a")],
        "cloud": ("#e7a3b8", "#4b3f72"),
        "cover": 0.36,
        "band": 26,
        "stars": 220,
    },
    # Ember Lava: almost black overhead, a red-orange glow on the horizon, dark smoke lit red from below
    "lava": {
        "stops": [(-90, "#2a0e0c"), (0, "#e0561e"), (5, "#a8301a"), (18, "#4a1416"), (45, "#1e0c10"), (90, "#0e080a")],
        "cloud": ("#9a3a20", "#1c1012"),
        "cover": 0.5,
        "band": 30,
        "stars": 0,
    },
    # Frozen Ice: a pale overcast winter sky, thick soft clouds
    "ice": {
        "stops": [(-90, "#c9d6e4"), (0, "#f1f5fa"), (10, "#dfe7f1"), (40, "#c4d2e3"), (90, "#aebfd6")],
        "cloud": ("#fbfdff", "#b9c7d8"),
        "cover": 0.62,
        "band": 40,
        "stars": 0,
    },
}


def gradient(stops, elevation):
    out = np.zeros(elevation.shape + (3,), dtype=np.float32)
    degrees = [s[0] for s in stops]
    colours = [hexrgb(s[1]) for s in stops]
    for k in range(3):
        out[..., k] = np.interp(elevation, degrees, [c[k] for c in colours])
    return out


rng = np.random.default_rng(11)
LATTICE = rng.random((64, 64, 64)).astype(np.float32)


def noise3(x, y, z):
    """Smooth value noise in 0..1 on a 64-cell lattice that wraps."""
    xi, yi, zi = np.floor(x).astype(int), np.floor(y).astype(int), np.floor(z).astype(int)
    xf, yf, zf = x - xi, y - yi, z - zi
    u, v, w = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf), zf * zf * (3 - 2 * zf)
    out = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                corner = LATTICE[(xi + dx) % 64, (yi + dy) % 64, (zi + dz) % 64]
                weight = (u if dx else 1 - u) * (v if dy else 1 - v) * (w if dz else 1 - w)
                out = out + corner * weight
    return out


def fbm(x, y, z, octaves=5):
    total, amp, norm = 0, 1.0, 0
    for _ in range(octaves):
        total = total + noise3(x, y, z) * amp
        norm += amp
        x, y, z, amp = x * 2.03 + 17, y * 2.03 + 5, z * 2.03 + 11, amp * 0.5
    return total / norm


def smooth(a, b, v):
    t = np.clip((v - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def stars(image, count, allowed):
    if count <= 0:
        return
    star_rng = np.random.default_rng(count + 3)
    for _ in range(count):
        x, y = int(star_rng.integers(0, SIZE)), int(star_rng.integers(0, SIZE))
        if not allowed[y, x]:
            continue
        glow = 120 + 135 * star_rng.random()
        r = 1 if star_rng.random() < 0.85 else 2
        patch = image[max(0, y - r + 1) : y + r, max(0, x - r + 1) : x + r]
        patch[...] = np.maximum(patch, glow)


def side(spec):
    u = (np.arange(SIZE, dtype=np.float32) + 0.5) / SIZE
    U, V = np.meshgrid(u, u)
    x, y = 2 * U - 1, 1 - 2 * V  # y up
    elevation = np.degrees(np.arctan2(y, np.sqrt(1 + x * x)))
    image = gradient(spec["stops"], elevation)
    # clouds: noise round a circle in u (so the picture tiles left to right), flattened towards the horizon
    # (wide across, thin up and down, thinner still near the horizon: a layer of clouds seen at a slant)
    angle = 2 * math.pi * U
    height = np.clip(elevation, 0, 90)
    lift = 2.2 * np.log1p(height / 1.5)
    n = fbm(np.cos(angle) * 0.9 + 32, np.sin(angle) * 0.9 + 32, lift + 7)
    shade = fbm(np.cos(angle) * 0.9 + 32, np.sin(angle) * 0.9 + 32, lift + 7.35)
    band = smooth(-1, 3, elevation) * (1 - smooth(spec["band"] * 0.6, spec["band"], elevation))
    edge = 1 - spec["cover"]
    cloud = smooth(edge, edge + 0.16, n) * band
    lit, dark = hexrgb(spec["cloud"][0]), hexrgb(spec["cloud"][1])
    mix = np.clip(0.5 + (n - shade) * 6, 0, 1)[..., None]
    colour = dark + (lit - dark) * mix
    image = image + (colour - image) * cloud[..., None] * 0.92
    stars(image, spec["stars"] // 3, elevation > 20)
    return image


def top(spec):
    u = (np.arange(SIZE, dtype=np.float32) + 0.5) / SIZE
    U, V = np.meshgrid(u, u)
    x, z = 2 * U - 1, 2 * V - 1
    elevation = np.degrees(np.arctan2(1, np.sqrt(x * x + z * z)))
    image = gradient(spec["stops"], elevation)
    stars(image, spec["stars"], elevation > 0)
    return image


def down(spec):
    return gradient(spec["stops"], np.full((SIZE, SIZE), -90, dtype=np.float32))


def save(image, path):
    Image.fromarray(np.clip(image, 0, 255).astype(np.uint8)).save(path)


names = sys.argv[1:] or list(MAPS)
for name in names:
    spec = MAPS[name]
    folder = os.path.join(ROOT, name)
    os.makedirs(folder, exist_ok=True)
    s, t, d = side(spec), top(spec), down(spec)
    save(s, os.path.join(folder, "side.png"))
    save(t, os.path.join(folder, "up.png"))
    save(d, os.path.join(folder, "down.png"))
    # a look at it: the top over one side, and two sides next to each other (the seam)
    sheet = np.zeros((SIZE * 2, SIZE * 2, 3), dtype=np.float32)
    sheet[:SIZE, :SIZE] = t
    sheet[SIZE:, :SIZE] = s
    sheet[SIZE:, SIZE:] = s
    save(sheet, os.path.join(folder, "preview.png"))
    print("sky written:", folder)
