# Saves the pictures a .glb file carries (its JSON chunk names the bufferViews they sit in) and lists its materials. Used once to take the
# leaf picture of art/models/quaternius/Bush_Common.glb (Leaves_TwistedTree_C) for tools/map/recolour_leaves.py (2026-11-02).
#   python tools/map/extract_glb_image.py <file.glb> <output folder>
import json
import os
import struct
import sys

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
data = open(src, "rb").read()
magic, version, length = struct.unpack("<4sII", data[:12])
pos = 12
document = None
binary = None
while pos < length:
    size, kind = struct.unpack("<II", data[pos : pos + 8])
    chunk = data[pos + 8 : pos + 8 + size]
    if kind == 0x4E4F534A:
        document = json.loads(chunk)
    elif kind == 0x004E4942:
        binary = chunk
    pos += 8 + size
base = os.path.splitext(os.path.basename(src))[0]
for i, image in enumerate(document.get("images", [])):
    view = document["bufferViews"][image["bufferView"]]
    start = view.get("byteOffset", 0)
    blob = binary[start : start + view["byteLength"]]
    ext = "png" if image.get("mimeType", "").endswith("png") else "jpg"
    path = os.path.join(out, "%s_%d_%s.%s" % (base, i, image.get("name", "x"), ext))
    open(path, "wb").write(blob)
    print(path, len(blob))
for material in document.get("materials", []):
    print(material.get("name"), json.dumps(material.get("pbrMetallicRoughness", {}))[:200], material.get("alphaMode"))
