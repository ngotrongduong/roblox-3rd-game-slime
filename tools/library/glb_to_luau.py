# Turns small GLBs (art/library/converted/<Set>) into Luau scripts that build the same meshes in an open Studio place with
# EditableMesh, so a map can be judged before the owner has imported the meshes. Each script puts one Model a prop (a MeshPart
# with the vertex colours) under ServerStorage.<Folder>. Not for the game itself (the game loads the imported meshes).
#   python -I glb_to_luau.py <Set dir> <out dir> <Folder> [batch size]
import json
import os
import struct
import sys

COMPONENT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
COUNT = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
	data = open(path, "rb").read()
	_, _, _ = struct.unpack("<III", data[:12])
	pos = 12
	gltf, binary = None, b""
	while pos < len(data):
		length, kind = struct.unpack("<II", data[pos : pos + 8])
		chunk = data[pos + 8 : pos + 8 + length]
		if kind == 0x4E4F534A:
			gltf = json.loads(chunk)
		elif kind == 0x004E4942:
			binary = chunk
		pos += 8 + length
	return gltf, binary


def accessor(gltf, binary, index):
	acc = gltf["accessors"][index]
	view = gltf["bufferViews"][acc["bufferView"]]
	fmt, size = COMPONENT[acc["componentType"]]
	n = COUNT[acc["type"]]
	start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
	stride = view.get("byteStride", size * n)
	out = []
	for i in range(acc["count"]):
		raw = struct.unpack_from("<" + fmt * n, binary, start + i * stride)
		if acc.get("normalized"):
			raw = tuple(x / (2 ** (8 * size) - 1) for x in raw)
		out.append(raw)
	return out, acc


def main():
	src, dest, folder = sys.argv[1], sys.argv[2], sys.argv[3]
	batch = int(sys.argv[4]) if len(sys.argv) > 4 else 6
	os.makedirs(dest, exist_ok=True)
	names = sorted(f for f in os.listdir(src) if f.endswith(".glb"))
	for start in range(0, len(names), batch):
		lines = [
			"local AssetService = game:GetService('AssetService')",
			"local SS = game:GetService('ServerStorage')",
			f"local folder = SS:FindFirstChild('{folder}') or Instance.new('Folder')",
			f"folder.Name = '{folder}'",
			"folder.Parent = SS",
			"local function lin(c) return if c <= 0.0031308 then c * 12.92 else 1.055 * c ^ (1 / 2.4) - 0.055 end",
			"local made = {}",
			"local function make(name, v, c, ix, colour)",
			"\tlocal old = folder:FindFirstChild(name) if old then old:Destroy() end",
			"\tlocal em = AssetService:CreateEditableMesh()",
			"\tlocal ids, cols = {}, {}",
			"\tfor k = 0, #v / 3 - 1 do ids[k + 1] = em:AddVertex(Vector3.new(v[k * 3 + 1], v[k * 3 + 2], v[k * 3 + 3])) end",
			"\tfor k = 0, #ix / 3 - 1 do",
			"\t\tlocal a, b, d = ix[k * 3 + 1] + 1, ix[k * 3 + 2] + 1, ix[k * 3 + 3] + 1",
			"\t\tlocal f = em:AddTriangle(ids[a], ids[b], ids[d])",
			"\t\tif c then",
			"\t\t\tlocal function col(i) return Color3.new(lin(c[(i - 1) * 3 + 1]), lin(c[(i - 1) * 3 + 2]), lin(c[(i - 1) * 3 + 3])) end",
			"\t\t\tlocal id = em:AddColor(col(a), 1)",
			"\t\t\tem:SetFaceColors(f, { id, id, id })",
			"\t\tend",
			"\tend",
			"\tlocal part = AssetService:CreateMeshPartAsync(Content.fromObject(em))",
			"\tpart.Name = name .. 'Part' part.Anchored = true part.Material = Enum.Material.SmoothPlastic part.Color = colour",
			"\tlocal model = Instance.new('Model') model.Name = name part.Parent = model model.Parent = folder",
			"\ttable.insert(made, name)",
			"end",
		]
		for name in names[start : start + batch]:
			gltf, binary = read_glb(os.path.join(src, name))
			prim = gltf["meshes"][0]["primitives"][0]
			pos, _ = accessor(gltf, binary, prim["attributes"]["POSITION"])
			cols = None
			if "COLOR_0" in prim["attributes"]:
				cols, _ = accessor(gltf, binary, prim["attributes"]["COLOR_0"])
			idx, _ = accessor(gltf, binary, prim["indices"])
			v = ",".join("%.3f,%.3f,%.3f" % p for p in pos)
			c = "nil"
			if cols:
				c = "{" + ",".join("%.3f,%.3f,%.3f" % (p[0], p[1], p[2]) for p in cols) + "}"
			ix = ",".join(str(i[0]) for i in idx)
			# the colour most of the triangles wear: EditableMesh in Studio does not draw vertex colours, so the part wears it
			dominant = "Color3.new(1,1,1)"
			if cols:
				count = {}
				for k in range(0, len(idx), 3):
					p = cols[idx[k][0]]
					key = (round(p[0], 2), round(p[1], 2), round(p[2], 2))
					count[key] = count.get(key, 0) + 1
				best = max(count, key=count.get)
				if "Tree" in name or "Bush" in name:
					best = max(count, key=lambda p: p[1] - p[0])  # the leaves, not the trunk
				srgb = [x * 12.92 if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055 for x in best]
				dominant = "Color3.new(%.3f,%.3f,%.3f)" % tuple(srgb)
			lines.append(f"make('{name[:-4]}', {{{v}}}, {c}, {{{ix}}}, {dominant})")
			lines.append("task.wait()")
		lines.append("return table.concat(made, ', ')")
		out = os.path.join(dest, "batch_%02d.luau" % (start // batch))
		open(out, "w").write("\n".join(lines))
		print("wrote", out, os.path.getsize(out))


main()
