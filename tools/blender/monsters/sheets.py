# The two overview pictures: art/models/monsters/sheet.png (each painting over its render) and
# art/models/monsters/lineup.png (all 7 at real relative size beside a 4-stud slime).
# Run after the 7 builds: blender -b --factory-startup -P sheets.py
import math
import os
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import bpy
import common as C
import numpy as np
from mathutils import Vector

NAMES = [("sproutling", "Sproutling"), ("honey_bee", "HoneyBee"), ("puffdandy", "Puffdandy"), ("glowmoth", "Glowmoth"),
	("clover_snail", "CloverSnail"), ("bloomshell", "Bloomshell"), ("bramblehorn", "Bramblehorn")]
LIFT = {"HoneyBee": 0.0, "Puffdandy": 0.0, "Glowmoth": 0.0}  # all shown standing on the same ground line


def resize(a, size):
	"""Nearest-neighbour fit of an RGBA tile into size x size, centred."""
	h, w = a.shape[:2]
	s = size / max(h, w)
	nh, nw = max(1, int(h * s)), max(1, int(w * s))
	ys = (np.arange(nh) / s).astype(int).clip(0, h - 1)
	xs = (np.arange(nw) / s).astype(int).clip(0, w - 1)
	r = a[ys][:, xs]
	out = np.ones((size, size, 4), dtype=np.float32)
	out[..., :3] = 0.92
	y0, x0 = (size - nh) // 2, (size - nw) // 2
	out[y0 : y0 + nh, x0 : x0 + nw] = C.over(r)
	return out


def sheet():
	cols = []
	for _, n in NAMES:
		d = C.OUT + n + "/review/"
		p = resize(C.load_rgba(d + "aligned_paint.png"), 320)
		r = resize(C.load_rgba(d + "aligned_render.png"), 320)
		cols.append(C.vstack([p, r]))
	C.save_rgba(C.OUT + "sheet.png", C.hstack(cols))
	print("[monster] sheet.png written")


def lineup():
	C.reset_scene()
	scratch = "C:/Users/ngotr/AppData/Local/Temp/claude/C--Roblox-3rd-game/359377ff-a015-4261-bc9c-325011e9fce2/scratchpad/lineup_tmp/"
	os.makedirs(scratch, exist_ok=True)
	x = 0.0
	groups = []
	# a 4-stud slime stand-in (the real body is the slime_body FBX; an ellipsoid of its size is enough for the comparison)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, radius=1.0, location=(0, 0, 0))
	sl = bpy.context.active_object
	sl.scale = (2.0, 2.0, 1.7)
	sl.location = (2.0, 0, 1.7)
	bpy.ops.object.shade_smooth()
	m = bpy.data.materials.new("slime")
	m.use_nodes = False
	m.diffuse_color = (0.30, 0.78, 0.95, 1)
	sl.data.materials.append(m)
	x = 4.0 + 1.2
	for script, n in NAMES:
		mod = C.load_spec("C:/Roblox 3rd game/tools/blender/monsters/%s.py" % script)
		objs, pieces, pal = C.instantiate(mod, n + "_", scratch + n + "/")
		lo, hi = C.world_bounds(objs)
		w = float(hi[0] - lo[0])
		dx = x - float(lo[0]) + 0.0
		for ob in objs:
			ob.location.x += dx
		x += w + 1.2
		groups.append(n)
	total = x
	tall = total * 0.27  # the picture is 2400 x 650
	C.setup_render(1800, flat=False)
	sc = bpy.context.scene
	sc.render.resolution_x, sc.render.resolution_y = 2400, 650
	# front view, orthographic: real relative size
	cam = C.make_cam((total / 2, 0, tall / 2 - 0.8), 0, 6, 60, ortho=total * 1.04)
	sc.render.filepath = scratch + "lineup_raw.png"
	sh = sc.display.shading
	sh.color_type = "TEXTURE"
	bpy.ops.render.render(write_still=True)
	a = C.load_rgba(scratch + "lineup_raw.png")
	C.setup_render(1800, flat=True)  # the same "lit" blend as the comparison sheets: mostly true palette, a little studio shading
	sc.render.resolution_x, sc.render.resolution_y = 2400, 650
	sc.render.filepath = scratch + "lineup_flat.png"
	bpy.ops.render.render(write_still=True)
	f = C.load_rgba(scratch + "lineup_flat.png")
	a[..., :3] = 0.2 * a[..., :3] + 0.8 * f[..., :3]
	C.save_rgba(C.OUT + "lineup.png", C.over(a))
	print("[monster] lineup.png written, total width %.1f studs" % total)


sheet()
lineup()
