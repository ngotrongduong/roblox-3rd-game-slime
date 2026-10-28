"""Cuts the owner's nine slime faces into separate transparent parts and draws the few pieces his art does not have.

  python tools/faces/make_faces.py

Writes art/faces/parts/*.png (the owner's pixels, cut as they are: nothing recoloured, redrawn or squashed),
art/faces/drawn/*.png (pieces drawn here in the same style, to be replaced by art later) and art/faces/faces.json
(size and place of every sprite in body-height units). The owner's art is read from
reference/goo-lineage-web/assets/slime.emotion.<id>.png.

Units: the web draws each face png at 0.64 x the body width, centred 0.51 up the body (docs/reference/04 section 3).
The body is 1.0563 wide per 1.0 high (art/models/slime_body/rounds.md), so one png pixel = 0.64 * 1.0563 / png width
body heights. A sprite's cx, cy are its centre relative to the png centre (x right, y up), in body heights.
"""

import json
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(ROOT, "reference", "goo-lineage-web", "assets")
OUT = os.path.join(ROOT, "art", "faces")
BODY_W = 1.0563136
FACE_W = 0.64
IDS = ["normal", "admiring", "exciting", "loved", "sleep", "angry", "dare", "sad", "surprise"]
SS = 4  # supersampling for drawn pieces


def load(n):
    return Image.open(os.path.join(ASSETS, "slime.emotion.%s.png" % n)).convert("RGBA")


def components(im, thr=40, minpx=40):
    w, h = im.size
    a = im.getchannel("A").load()
    seen = [[False] * w for _ in range(h)]
    out = []
    for y in range(h):
        for x in range(w):
            if a[x, y] > thr and not seen[y][x]:
                st = [(x, y)]
                seen[y][x] = True
                xs, ys, n = [x], [y], 0
                while st:
                    cx, cy = st.pop()
                    n += 1
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            nx, ny = cx + dx, cy + dy
                            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and a[nx, ny] > thr:
                                seen[ny][nx] = True
                                st.append((nx, ny))
                                xs.append(nx)
                                ys.append(ny)
                if n >= minpx:
                    out.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    return out


sprites = {}


def register(name, folder, im, w_png, cx_px, cy_px, source):
    path = os.path.join(OUT, folder, name + ".png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)
    upp = FACE_W * BODY_W / w_png
    sprites[name] = {
        "file": "%s/%s.png" % (folder, name),
        "source": source,
        "px": [im.width, im.height],
        "upp": upp,
        "w": im.width * upp,
        "h": im.height * upp,
        "cx": cx_px * upp,
        "cy": cy_px * upp,
    }


# ---------------------------------------------------------------- 1. the owner's pixels
navy_samples = []
for n in IDS:
    im = load(n)
    boxes = sorted(components(im), key=lambda b: (b[0] + b[2]) / 2)
    assert len(boxes) == 3, (n, boxes)
    for part, box in zip(("eyeL", "mouth", "eyeR"), boxes):
        crop = im.crop(box)
        cx = (box[0] + box[2]) / 2 - im.width / 2
        cy = -((box[1] + box[3]) / 2 - im.height / 2)
        register("%s_%s" % (n, part), "parts", crop, im.width, cx, cy, "owner")
        if n == "normal" and part == "mouth":
            for px in crop.getdata():
                if px[3] > 250:
                    navy_samples.append(px[:3])

navy_samples.sort(key=sum)
NAVY = navy_samples[len(navy_samples) // 2] if navy_samples else (26, 47, 110)
print("navy of the owner's mouth line:", NAVY)
NORMAL_UPP = FACE_W * BODY_W / load("normal").width


def hexcol(r, g, b, a=255):
    return (r, g, b, a)


# ---------------------------------------------------------------- 2. drawn pieces (same style)
def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(im):
    return im.resize((im.width // SS, im.height // SS), Image.LANCZOS)


def mask_of(draw_fn, size):
    m = Image.new("L", (size[0] * SS, size[1] * SS), 0)
    d = ImageDraw.Draw(m)
    draw_fn(d)
    return m


def with_outline(mask, fill, line, line_px, gloss=None):
    """fill colour, a dilated outline in `line`, and optional white gloss ellipses (x0,y0,x1,y1 in 1x px)."""
    k = int(line_px * SS) * 2 + 1
    big = mask.filter(ImageFilter.MaxFilter(k))
    im = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    im.paste(Image.new("RGBA", mask.size, line), (0, 0), big)
    im.paste(Image.new("RGBA", mask.size, fill), (0, 0), mask)
    if gloss:
        d = ImageDraw.Draw(im)
        for g in gloss:
            d.ellipse([c * SS for c in g], fill=(255, 255, 255, 235))
    return im


def stroke_mask(size, pts, width, taper=None):
    """a round-capped line through pts (1x px); taper = (w0, w1) overrides width along the line."""
    def fn(d):
        n = max(2, int(sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)) * SS / 2))
        total = len(pts) - 1
        for i in range(n + 1):
            t = i / n * total
            k = min(int(t), total - 1)
            f = t - k
            x = pts[k][0] + (pts[k + 1][0] - pts[k][0]) * f
            y = pts[k][1] + (pts[k + 1][1] - pts[k][1]) * f
            wd = width if taper is None else taper[0] + (taper[1] - taper[0]) * (i / n)
            r = wd * SS / 2
            d.ellipse([x * SS - r, y * SS - r, x * SS + r, y * SS + r], fill=255)
    return mask_of(fn, size)


def union(*ms):
    out = ms[0]
    for m in ms[1:]:
        out = ImageChops.lighter(out, m)
    return out


def poly_mask(size, pts):
    return mask_of(lambda d: d.polygon([(x * SS, y * SS) for x, y in pts], fill=255), size)


def ell_mask(size, box):
    return mask_of(lambda d: d.ellipse([c * SS for c in box], fill=255), size)


drawn = {}


def put(name, im, cx=0.0, cy=0.0, upp=NORMAL_UPP):
    im = finish(im)
    path = os.path.join(OUT, "drawn", name + ".png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)
    sprites[name] = {
        "file": "drawn/%s.png" % name,
        "source": "drawn",
        "px": [im.width, im.height],
        "upp": upp,
        "w": im.width * upp,
        "h": im.height * upp,
        "cx": cx,
        "cy": cy,
    }


# brow: a thick tapered stroke, thicker at the inner end (left), drawn pointing right
def make_brow():
    size = (72, 24)
    m = stroke_mask(size, [(10, 14), (36, 9), (62, 12)], 0, taper=(9, 5))
    im = Image.new("RGBA", m.size, (0, 0, 0, 0))
    im.paste(Image.new("RGBA", m.size, NAVY + (255,)), (0, 0), m)
    # the right eye's brow is thick at its left (inner) end; the left eye's is the mirror image
    put("brow_R", im)
    put("brow_L", im.transpose(Image.FLIP_LEFT_RIGHT))


# soft blush: a pink oval with three slanted strokes
def make_blush():
    size = (70, 40)
    im = canvas(*size)
    px = im.load()
    cx, cy, rx, ry = size[0] * SS / 2, size[1] * SS / 2, size[0] * SS / 2 - 2, size[1] * SS / 2 - 2
    for y in range(im.height):
        for x in range(im.width):
            d = math.hypot((x - cx) / rx, (y - cy) / ry)
            if d < 1:
                s = 1.0 if d < 0.55 else (1 - d) / 0.45
                px[x, y] = (255, 124, 156, int(150 * s))
    d = ImageDraw.Draw(im)
    for i in (-1, 0, 1):
        x0 = cx + i * 13 * SS
        d.line([(x0 - 4 * SS, cy + 6 * SS), (x0 + 4 * SS, cy - 6 * SS)], fill=(255, 92, 132, 170), width=2 * SS)
    put("blush", im)


# a drop like the owner's tear bubble: cyan fill, deeper blue line, white gloss
def drop_mask(size, cx, top, bottom, rx):
    r = rx
    cy = bottom - r
    tri = poly_mask(size, [(cx, top), (cx - r * 0.93, cy - r * 0.36), (cx + r * 0.93, cy - r * 0.36)])
    return union(tri, ell_mask(size, (cx - r, cy - r, cx + r, cy + r)))


def make_drop(name, w, h):
    size = (w, h)
    m = drop_mask(size, w / 2, 4, h - 4, w / 2 - 5)
    im = with_outline(m, (118, 208, 250, 255), (36, 144, 228, 255), 2.2,
                      [(w / 2 - w * 0.2, h * 0.52, w / 2 - w * 0.04, h * 0.72)])
    put(name, im)


# the normal eyes with the highlight painted over, for the swirl eyes and lids
def eye_base(side):
    src = sprites["normal_eye" + side]
    im = Image.open(os.path.join(OUT, src["file"])).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a > 0 and min(r, g, b) > 150:
                px[x, y] = (0, 24, 84, a)
    return im


def make_lids():
    # lid fraction 0.28 / 0.5 / 0.72 / 0.88 of the eye shut, navy like the owner's brows; the edge bulges down a
    # little and slopes toward the outer corner (tired)
    for side in ("L", "R"):
        eye = Image.open(os.path.join(OUT, sprites["normal_eye" + side]["file"])).convert("RGBA")
        w, h = eye.size
        big = eye.resize((w * SS, h * SS), Image.LANCZOS)
        for i, frac in enumerate((0.28, 0.5, 0.72, 0.88), 1):
            lid = Image.new("L", big.size, 0)
            ld = lid.load()
            sl = -1 if side == "L" else 1  # the outer corner is at u = sl
            for x in range(big.width):
                u = (x / big.width - 0.5) * 2
                # the outer end of the lid lower than the inner end, the middle bulging down a little
                edge = (frac + 0.05 * (1 - u * u) + 0.06 * u * sl) * big.height
                for y in range(int(min(edge, big.height))):
                    ld[x, y] = 255
            a = big.getchannel("A")
            lidmask = ImageChops.multiply(lid, a)
            out = big.copy()
            out.paste(Image.new("RGBA", big.size, NAVY + (255,)), (0, 0), lidmask)
            src = sprites["normal_eye" + side]
            put("lid%d_%s" % (i, side), out, cx=src["cx"], cy=src["cy"])
    # sprites above were drawn at SS resolution then finished; `put` took the 1x size from the big image already


def make_swirls():
    for side in ("L", "R"):
        base = eye_base(side)
        w, h = base.size
        big = base.resize((w * SS, h * SS), Image.LANCZOS)
        d = ImageDraw.Draw(big)
        cx, cy = big.width * 0.5, big.height * 0.52
        rmax = min(big.width, big.height) * 0.42
        sgn = 1 if side == "L" else -1
        pts = []
        for i in range(0, 360 * 2 + 140, 5):
            a = math.radians(i)
            r = rmax * (i / (360 * 2 + 140))
            pts.append((cx + sgn * r * math.cos(a), cy + r * math.sin(a)))
        d.line(pts, fill=(255, 255, 255, 245), width=int(3.2 * SS), joint="curve")
        for p in (pts[0], pts[-1]):
            rr = 1.6 * SS
            d.ellipse([p[0] - rr, p[1] - rr, p[0] + rr, p[1] + rr], fill=(255, 255, 255, 245))
        src = sprites["normal_eye" + side]
        put("swirl_" + side, big, cx=src["cx"], cy=src["cy"])


# ---------------------------------------------------------------- emote icons (128 px)
def icon(name, mask, fill, line=NAVY + (255,), line_px=5, gloss=None):
    put(name, with_outline(mask, fill, line, line_px, gloss), upp=0.004)


def heart_mask(size, cx, cy, s):
    pts = []
    for i in range(0, 360, 2):
        t = math.radians(i)
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * s, cy - y * s))
    return poly_mask(size, pts)


def make_icons():
    S = (128, 128)
    icon("icon_heart", heart_mask(S, 64, 56, 2.45), (255, 98, 134, 255), gloss=[(34, 32, 46, 46)])
    # exclaim: tapered bar + dot
    bar = poly_mask(S, [(48, 14), (80, 14), (74, 78), (54, 78)])
    bar = union(bar, ell_mask(S, (46, 8, 82, 30)), ell_mask(S, (52, 66, 76, 90)))
    dot = ell_mask(S, (50, 94, 78, 116))
    icon("icon_exclaim", union(bar, dot), (255, 96, 70, 255), gloss=[(54, 18, 62, 40)])
    # question: hook + stem + dot
    pts = []
    for a in range(160, -75, -5):
        t = math.radians(a)
        pts.append((64 + 24 * math.cos(t), 46 - 24 * math.sin(t)))
    pts += [(64, 76), (64, 82)]
    q = stroke_mask(S, pts, 16)
    qd = ell_mask(S, (53, 95, 75, 117))
    icon("icon_question", union(q, qd), (96, 176, 255, 255), gloss=[(36, 26, 46, 36)])
    # note: head, stem, flag
    head = ell_mask(S, (26, 80, 66, 112))
    head = head.rotate(18, resample=Image.BICUBIC, center=(46 * SS, 96 * SS))
    stem = poly_mask(S, [(58, 24), (70, 24), (70, 100), (58, 100)])
    flag = poly_mask(S, [(70, 24), (104, 46), (104, 70), (70, 52)])
    icon("icon_note", union(head, stem, flag), (176, 128, 255, 255), gloss=[(32, 88, 42, 96)])
    # zzz: three Zs
    def z(x, y, s, wd):
        return stroke_mask(S, [(x, y), (x + s, y), (x, y + s), (x + s, y + s)], wd)

    icon("icon_zzz", union(z(18, 70, 34, 10), z(54, 40, 40, 11), z(88, 12, 28, 9)), (214, 236, 255, 255), line_px=4)
    # anger: four curved strokes round a cross-shaped gap
    def arc(a0, a1):
        pts = [(64 + 40 * math.cos(math.radians(a)), 64 - 40 * math.sin(math.radians(a))) for a in range(a0, a1 + 1, 4)]
        return stroke_mask(S, pts, 13)

    icon("icon_anger", union(arc(18, 72), arc(108, 162), arc(198, 252), arc(288, 342)), (255, 84, 72, 255))
    # star: four-point sparkle
    pts = []
    for i in range(8):
        r = 56 if i % 2 == 0 else 15
        a = math.radians(i * 45 - 90)
        pts.append((64 + r * math.cos(a), 64 + r * math.sin(a)))
    icon("icon_star", poly_mask(S, pts), (255, 214, 70, 255), gloss=[(60, 30, 68, 42)])
    # three small stars (dizzy)
    def star5(cx, cy, r):
        p = []
        for i in range(10):
            rr = r if i % 2 == 0 else r * 0.45
            a = math.radians(i * 36 - 90)
            p.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
        return poly_mask(S, p)

    icon("icon_stars3", union(star5(34, 82, 26), star5(94, 76, 22), star5(64, 30, 24)), (255, 214, 70, 255), line_px=4)
    # dots: a round bubble with three dots and a tail
    bub = union(ell_mask(S, (10, 22, 118, 90)), poly_mask(S, [(30, 80), (22, 108), (58, 86)]))
    im = with_outline(bub, (255, 253, 244, 255), NAVY + (255,), 5)
    d = ImageDraw.Draw(im)
    for x in (36, 64, 92):
        d.ellipse([(x - 7) * SS, 49 * SS, (x + 7) * SS, 63 * SS], fill=NAVY + (255,))
    put("icon_dots", im, upp=0.004)


make_brow()
make_blush()
make_drop("sweat", 40, 56)
make_drop("tear_drop", 28, 40)
make_lids()
make_swirls()
make_icons()

# the owner's food picture, as it is, for the hungry / eating / full emotes
food = Image.open(os.path.join(ASSETS, "mat-food.png")).convert("RGBA")
os.makedirs(os.path.join(OUT, "parts"), exist_ok=True)
food.save(os.path.join(OUT, "parts", "icon_food.png"))
sprites["icon_food"] = {
    "file": "parts/icon_food.png", "source": "owner", "px": [food.width, food.height], "upp": 0.004,
    "w": food.width * 0.004, "h": food.height * 0.004, "cx": 0.0, "cy": 0.0,
}

with open(os.path.join(OUT, "faces.json"), "w") as f:
    json.dump({"navy": list(NAVY), "faceHeightUnit": 0.51, "sprites": sprites}, f, indent=1)
print(len(sprites), "sprites")
