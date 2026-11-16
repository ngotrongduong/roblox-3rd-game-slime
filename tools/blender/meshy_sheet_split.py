# Splits a Meshy model that was made from a SHEET of several objects (one mesh, the objects lying side by side) into
# its objects, shows them, and writes the named ones out. The sheets and their pieces are listed in meshy_sheets.json.
#   blender -b --factory-startup -P meshy_sheet_split.py -- <sheet key> [export]
# Looking (no `export`): prints the objects (triangles, size, centre in the sheet) and renders into the sheet's `out`
# folder sheet_front.png and views_<n>.png (four objects a picture, one a row: from the front, from its right side, from
# above with its front down). With `export`, every piece of the sheet's `pieces` (found by its centre `at` in the sheet,
# laid square to the sheet when `square`, then turned by `turn` degrees about Blender's x, y, z, made `height` studs high
# or `width` studs wide) is written, and pieces_<n>.png shows them as written (the same three views):
#   <out>/<key>_pieces.glb   all pieces side by side, each its own named mesh, one shared 1024 px picture: the file the
#                            owner imports into Studio (File > Import 3D)
#   <out>/pieces.json        triangles and the Config.LibraryKit.Props line of every piece
#   <out>/preview/<Piece>.luau  the piece as an EditableMesh with a colour a face, for ServerStorage.GranaryPreview
#                            (tools/map/landmark_preview.luau), so it is judged on the building before any upload
# A piece's front faces Roblox -Z (out of a wall, as Architecture's `face`). `hold` says where the building holds it:
# "foot" the middle of its foot, "back" the middle of its back, "top" the middle of its top, "centre".
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Euler, Vector

GAP = 0.012  # loose parts closer than this share of the sheet's width belong to one object (a sheet's own `gap` wins)
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

args = sys.argv[sys.argv.index("--") + 1 :]
KEY, EXPORT = args[0], len(args) > 1 and args[1] == "export"
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "meshy_sheets.json")) as fh:
	SHEET = json.load(fh)[KEY]
GLB, OUT = os.path.join(ROOT, SHEET["source"]), os.path.join(ROOT, SHEET["out"])
os.makedirs(OUT, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=GLB, merge_vertices=True)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]


def pick(objs):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]


pick(meshes)
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if len(meshes) > 1:
	bpy.ops.object.join()
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
parts = [o for o in bpy.context.scene.objects if o.type == "MESH"]


def box(objs):
	lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
	for ob in objs:
		for v in ob.data.vertices:
			w = ob.matrix_world @ v.co
			lo = Vector(map(min, lo, w))
			hi = Vector(map(max, hi, w))
	return lo, hi


boxes = [box([o]) for o in parts]
lo, hi = box(parts)
gap = (hi.x - lo.x) * SHEET.get("gap", GAP)
parent = list(range(len(parts)))


def find(a):
	while parent[a] != a:
		parent[a] = parent[parent[a]]
		a = parent[a]
	return a


for i in range(len(parts)):
	for j in range(i + 1, len(parts)):
		(a0, a1), (b0, b1) = boxes[i], boxes[j]
		# (in depth too: a sheet of things standing on a floor has a row behind the front one)
		if all(a0[k] - gap < b1[k] and b0[k] - gap < a1[k] for k in range(3)):
			parent[find(j)] = find(i)
groups = {}
for i, o in enumerate(parts):
	groups.setdefault(find(i), []).append(o)
# (a crumb, a bead that floats free beside its lantern, is thrown away)
SMALL = (hi.x - lo.x) * 0.03
for r in [r for r, m in groups.items() if max(box(m)[1] - box(m)[0]) < SMALL]:
	for o in groups.pop(r):
		bpy.data.objects.remove(o)
objects = []
for members in groups.values():
	pick(members)
	if len(members) > 1:
		bpy.ops.object.join()
	ob = bpy.context.view_layer.objects.active
	bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
	ob.rotation_mode = "XYZ"  # (the glTF importer leaves quaternions, which ignore rotation_euler)
	objects.append(ob)
# (reading order: the top row first, left to right)
objects.sort(key=lambda o: (-round(o.location.z / (hi.z - lo.z) * 3), o.location.x))
print("SHEET", KEY, "objects", len(objects), "loose parts", len(parts))
for i, o in enumerate(objects):
	a, c = box([o])
	size = c - a
	# (open: edges with a face on one side only, the rim of a hole; depth: where it stands behind the sheet's front)
	edges = {}
	for p in o.data.polygons:
		for key in p.edge_keys:
			edges[key] = edges.get(key, 0) + 1
	rim = sum(1 for n in edges.values() if n == 1)
	print("  %2d  tris %5d  wide %.3f high %.3f deep %.3f  at %.3f %.3f  depth %.3f  open %d" % (i, len(o.data.polygons), size.x, size.z, size.y, o.location.x, o.location.z, o.location.y, rim))


def render(objs, path, res):
	sc = bpy.context.scene
	a, c = box(objs)
	ctr, size = (a + c) / 2, c - a
	cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
	sc.collection.objects.link(cam)
	cam.data.type = "ORTHO"
	cam.data.ortho_scale = max(size.x, size.z) * 1.06
	cam.location = ctr + Vector((0, -30, 0))
	cam.rotation_euler = Vector((0, 1, 0)).to_track_quat("-Z", "Y").to_euler()
	sc.camera = cam
	w = bpy.data.worlds.new("W")
	w.color = (0.5, 0.5, 0.52)
	sc.world = w
	sc.render.engine = "BLENDER_WORKBENCH"
	sc.display.shading.color_type = "TEXTURE"
	sc.display.shading.light = "STUDIO"
	sc.view_settings.view_transform = "Standard"
	sc.render.resolution_x = res if size.x >= size.z else int(res * size.x / size.z)
	sc.render.resolution_y = res if size.z >= size.x else int(res * size.z / size.x)
	sc.render.filepath = path
	bpy.ops.render.render(write_still=True)
	bpy.data.objects.remove(cam)


def views(objs, prefix, half=0.0, blocks=1, turns=((0, 0, 0), (0, 0, -90), (90, 0, 0))):
	# four objects a picture, one a row: from the front, from its right side, from above with its front down
	# (`half`: a half turn first, for pieces whose front already faces away; `blocks`: that many objects side by side
	# in a row, each with its views, to look through a big sheet in few pictures)
	cell = max(max(o.dimensions) for o in objs) * 1.12
	for o in bpy.context.scene.objects:
		o.hide_render = True
	per = 4 * blocks
	for first in range(0, len(objs), per):
		shown = []
		for n, o in enumerate(objs[first : first + per]):
			for col, turn in enumerate(turns):
				c = o.copy()
				bpy.context.scene.collection.objects.link(c)
				c.hide_render = False
				c.rotation_euler = (Euler([math.radians(t) for t in turn]).to_matrix() @ Euler((0, 0, half)).to_matrix()).to_euler()
				c.location = ((n % blocks * (len(turns) + 0.2) + col) * cell, 0, -(n // blocks) * cell)
				shown.append(c)
		bpy.context.view_layer.update()
		render(shown, os.path.join(OUT, "%s_%d.png" % (prefix, first // per + 1)), 1500)
		for c in shown:
			bpy.data.objects.remove(c)


def squared(ob):
	# the turn about the upright axis (degrees, -45..45) that lays the piece's footprint square to the sheet
	pts = np.array([(v.co.x, v.co.y) for v in ob.data.vertices])

	def area(deg):
		a = math.radians(deg)
		x = pts[:, 0] * math.cos(a) - pts[:, 1] * math.sin(a)
		y = pts[:, 0] * math.sin(a) + pts[:, 1] * math.cos(a)
		return np.ptp(x) * np.ptp(y)

	return min(np.arange(-45, 45.01, 0.5), key=area)


if not EXPORT:
	render(objects, os.path.join(OUT, "sheet_front.png"), 1400)
	views(objects, "views", 0.0, 2)
	print("LOOK OK")
	sys.exit(0)

# --- export -----------------------------------------------------------------------------------------------------------
image = next(n.image for n in objects[0].data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE")
iw, ih = image.size
pixels = np.empty(iw * ih * 4, dtype=np.float32)
image.pixels.foreach_get(pixels)
pixels = pixels.reshape(ih, iw, 4)

PREVIEW_HEAD = """local AssetService = game:GetService('AssetService')
local SS = game:GetService('ServerStorage')
local folder = SS:FindFirstChild('GranaryPreview') or Instance.new('Folder')
folder.Name = 'GranaryPreview'
folder.Parent = SS
local function make(name, size, v, t, pal, fc)
	local old = folder:FindFirstChild(name) if old then old:Destroy() end
	local em = AssetService:CreateEditableMesh()
	local ids, cols = {}, {}
	for k = 0, #v / 3 - 1 do ids[k + 1] = em:AddVertex(Vector3.new(v[k * 3 + 1], v[k * 3 + 2], v[k * 3 + 3])) end
	for k = 0, #pal / 3 - 1 do cols[k + 1] = em:AddColor(Color3.fromRGB(pal[k * 3 + 1], pal[k * 3 + 2], pal[k * 3 + 3]), 1) end
	for k = 0, #t / 3 - 1 do
		local f = em:AddTriangle(ids[t[k * 3 + 1]], ids[t[k * 3 + 2]], ids[t[k * 3 + 3]])
		local c = cols[fc[k + 1]]
		em:SetFaceColors(f, { c, c, c })
	end
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	part.Name = name .. 'Part' part.Anchored = true part.Material = Enum.Material.SmoothPlastic
	part.Size = Vector3.new(size[1], size[2], size[3])
	local model = Instance.new('Model') model.Name = name part.Parent = model model.Parent = folder
	return name
end
"""

os.makedirs(os.path.join(OUT, "preview"), exist_ok=True)
ledger, chosen, x = {}, [], 0.0
for name, spec in SHEET["pieces"].items():
	# (`at`: the object's centre in the sheet, across and up, and its depth too where the sheet has rows; `with`: the
	# centres of more objects that belong to the piece, as the stools of a table)
	def found(at):
		deep = len(at) > 2
		return min(objects, key=lambda o: (Vector((o.location.x, o.location.y if deep else 0, o.location.z)) - Vector((at[0], at[2] if deep else 0, at[1]))).length)

	ob = found(spec["at"])
	more = [m for m in (found(at) for at in spec.get("with", [])) if m is not ob]
	if more:
		pick([ob] + more)
		bpy.ops.object.join()
		objects = [o for o in objects if o not in more]
		bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
	ob.name = ob.data.name = name
	pick([ob])
	if "hue" in spec:
		# (colour that ran over from a neighbour on the sheet: in this piece's own part of the picture every texel whose
		# hue lies between the first two numbers takes the third; hues 0..1)
		h0, h1, to = spec["hue"]
		me = ob.data
		me.calc_loop_triangles()
		uv = me.uv_layers.active.data
		for lt in me.loop_triangles:
			p = np.array([(uv[li].uv.x % 1 * iw, uv[li].uv.y % 1 * ih) for li in lt.loops])
			d = (p[1, 1] - p[2, 1]) * (p[0, 0] - p[2, 0]) + (p[2, 0] - p[1, 0]) * (p[0, 1] - p[2, 1])
			if abs(d) < 1e-9:
				continue
			x0, y0 = np.maximum(np.floor(p.min(0)).astype(int) - 1, 0)
			x1, y1 = np.minimum(np.ceil(p.max(0)).astype(int) + 1, (iw, ih))
			ys, xs = np.mgrid[y0:y1, x0:x1] + 0.5
			w0 = ((p[1, 1] - p[2, 1]) * (xs - p[2, 0]) + (p[2, 0] - p[1, 0]) * (ys - p[2, 1])) / d
			w1 = ((p[2, 1] - p[0, 1]) * (xs - p[2, 0]) + (p[0, 0] - p[2, 0]) * (ys - p[2, 1])) / d
			cell = pixels[y0:y1, x0:x1, :3]
			mx, mn = cell.max(-1), cell.min(-1)
			span = np.where(mx - mn < 1e-6, 1, mx - mn)
			r, g, b = cell[..., 0], cell[..., 1], cell[..., 2]
			hue = np.where(mx == r, ((g - b) / span) % 6, np.where(mx == g, (b - r) / span + 2, (r - g) / span + 4)) / 6
			hit = (w0 > -0.1) & (w1 > -0.1) & (w0 + w1 < 1.1) & (hue > h0) & (hue < h1) & (mx - mn > 0.08)
			sat = (mx - mn) / np.where(mx < 1e-6, 1, mx)
			for ch, n in enumerate((5, 3, 1)):
				k = (n + to * 6) % 6
				cell[..., ch] = np.where(hit, mx - mx * sat * np.clip(np.minimum(k, 4 - k), 0, 1), cell[..., ch])
	# (the piece's own turn, then half a turn: its front, towards the sheet's viewer at -Y, faces +Y = Roblox -Z)
	turn = spec.get("turn", [0, 0, 0])
	yaw = float(squared(ob)) if spec.get("square") else 0.0
	own = Euler([math.radians(t) for t in turn]).to_matrix() @ Euler((0, 0, math.radians(yaw))).to_matrix()
	ob.rotation_euler = (Euler((0, 0, math.pi)).to_matrix() @ own).to_euler()
	bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
	a, c = box([ob])
	if "upright" in spec:
		# (a parasol's pole drawn leaning: the piece is sheared until its pole stands straight; the two numbers are
		# shares of its height where a level cut meets only the pole, which has no points of its own between its ends)
		foot = a.z - ob.matrix_world.translation.z  # (the points are counted from the piece's own middle)

		def cut(share):
			z = foot + (c.z - a.z) * share
			ends = [[ob.data.vertices[i].co for i in e.vertices] for e in ob.data.edges]
			met = np.array([p.lerp(q, (z - p.z) / (q.z - p.z))[:] for p, q in ends if (p.z - z) * (q.z - z) < 0])
			return (met.min(0) + met.max(0)) / 2

		low, high = (cut(s) for s in spec["upright"])
		lean = (high - low) / (high[2] - low[2])
		for v in ob.data.vertices:
			v.co.x -= lean[0] * (v.co.z - foot)
			v.co.y -= lean[1] * (v.co.z - foot)
		a, c = box([ob])
	k = spec["height"] / (c.z - a.z) if "height" in spec else spec["width"] / (c.x - a.x)
	ob.scale = (k, k, k)
	bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
	bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
	a, c = box([ob])
	size = [c.x - a.x, c.z - a.z, c.y - a.y]  # (Roblox: x across, y up, z the depth)
	hold = spec.get("hold", "foot")
	off = {"foot": (0, size[1] / 2, 0), "back": (0, 0, -size[2] / 2), "top": (0, -size[1] / 2, 0), "centre": (0, 0, 0)}[hold]
	me = ob.data
	me.calc_loop_triangles()
	uv = me.uv_layers.active.data
	palette, v, t, fc = {}, [], [], []
	for p in me.vertices:
		v.append("%.3f,%.3f,%.3f" % (p.co.x, p.co.z, -p.co.y))
	for lt in me.loop_triangles:
		t.extend(str(i + 1) for i in lt.vertices)
		u = sum((uv[li].uv for li in lt.loops), Vector((0, 0))) / 3
		r, g, b = pixels[int(u.y % 1 * ih) % ih, int(u.x % 1 * iw) % iw, :3]
		colour = tuple(min(255, int(ch * 255) // 8 * 8 + 4) for ch in (r, g, b))
		fc.append(str(palette.setdefault(colour, len(palette) + 1)))
	pal = ",".join("%d,%d,%d" % c3 for c3 in palette)
	with open(os.path.join(OUT, "preview", name + ".luau"), "w") as fh:
		fh.write(PREVIEW_HEAD)
		fh.write("return make('%s', {%.3f,%.3f,%.3f}, {%s}, {%s}, {%s}, {%s})\n" % (name, *size, ",".join(v), ",".join(t), pal, ",".join(fc)))
	line = "%s = { { mesh = 0, tex = \"%s\", size = { %.3f, %.3f, %.3f }, at = { %.3f, %.3f, %.3f } } }," % (name, SHEET["tex"], *size, *off)
	ledger[name] = {"tris": len(me.loop_triangles), "config": line}
	print(" ", line, " tris", len(me.loop_triangles))
	ob.location = (x + size[0] / 2, 0, 0)
	x += size[0] + 1
	chosen.append(ob)

with open(os.path.join(OUT, "pieces.json"), "w") as fh:
	json.dump(ledger, fh, indent=1)
image.pixels.foreach_set(pixels.ravel())
image.scale(1024, 1024)
pick(chosen)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, KEY + "_pieces.glb"), use_selection=True, export_format="GLB", export_image_format="JPEG")
# (the check: every piece as the building will hold it, seen from its front, its right side, above and behind)
for o in chosen:
	o.location = (0, 0, 0)
views(chosen, "pieces", math.pi, 2 if len(chosen) > 4 else 1, ((0, 0, 0), (0, 0, -90), (90, 0, 0), (0, 0, 180)))
print("SPLIT OK", len(chosen), "pieces")
