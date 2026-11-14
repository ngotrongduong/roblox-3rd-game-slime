"""Side profile of a GLB cut by its middle plane (x = offset), drawn in text, to find where a mouth, a door or a seat
really is before aiming water, light or a character at it:
    python tools/world/glb_section.py <file.glb> <height in studs> [x offset in studs]
Axes printed: across = z (studs from the box's middle), up = y (studs above the box's bottom), two columns a stud."""
import json
import struct
import sys

path, tall = sys.argv[1], float(sys.argv[2])
cut = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0
data = open(path, "rb").read()
jlen = struct.unpack("<I", data[12:16])[0]
doc = json.loads(data[20:20 + jlen])
binary = data[20 + jlen + 8:]
# (a node that turns or scales its mesh would make the section wrong: Meshy's files have none)
print("nodes", [(n.get("name"), n.get("rotation"), n.get("scale"), n.get("translation"), "matrix" in n) for n in doc["nodes"]])


def read(acc_index, fmt, width):
    acc = doc["accessors"][acc_index]
    view = doc["bufferViews"][acc["bufferView"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    size = struct.calcsize(fmt) * width
    stride = view.get("byteStride", size)
    return [struct.unpack_from("<" + fmt * width, binary, start + i * stride) for i in range(acc["count"])]


FORMATS = {5121: "B", 5123: "H", 5125: "I"}
tris = []
for mesh in doc["meshes"]:
    for prim in mesh["primitives"]:
        pos = read(prim["attributes"]["POSITION"], "f", 3)
        kind = FORMATS[doc["accessors"][prim["indices"]]["componentType"]]
        idx = [i[0] for i in read(prim["indices"], kind, 1)]
        for i in range(0, len(idx), 3):
            tris.append((pos[idx[i]], pos[idx[i + 1]], pos[idx[i + 2]]))

lo = [min(p[i] for t in tris for p in t) for i in range(3)]
hi = [max(p[i] for t in tris for p in t) for i in range(3)]
scale = tall / (hi[1] - lo[1])
mid = [(lo[i] + hi[i]) / 2 for i in range(3)]
print("size studs", [round((hi[i] - lo[i]) * scale, 2) for i in range(3)])


def studs(p):
    return ((p[0] - mid[0]) * scale, (p[1] - lo[1]) * scale, (p[2] - mid[2]) * scale)


segments = []
for t in tris:
    pts = [studs(p) for p in t]
    hits = []
    for a, b in ((0, 1), (1, 2), (2, 0)):
        xa, xb = pts[a][0] - cut, pts[b][0] - cut
        if (xa < 0) != (xb < 0):
            k = xa / (xa - xb)
            hits.append((pts[a][2] + (pts[b][2] - pts[a][2]) * k, pts[a][1] + (pts[b][1] - pts[a][1]) * k))
    if len(hits) == 2:
        segments.append(hits)

half = (hi[2] - lo[2]) * scale / 2
cols = int(half * 2 * 2) + 3
rows = int(tall) + 2
grid = [[" "] * cols for _ in range(rows)]
for (z0, y0), (z1, y1) in segments:
    for s in range(21):
        z = z0 + (z1 - z0) * s / 20
        y = y0 + (y1 - y0) * s / 20
        grid[int(y)][int((z + half) * 2) + 1] = "#"
for r in range(rows - 1, -1, -1):
    print("%3d %s" % (r, "".join(grid[r])))
print("z from %.1f (left) to %.1f (right), two columns a stud" % (-half, half))
