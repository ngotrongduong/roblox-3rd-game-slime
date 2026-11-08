# One picture of every preview in a folder, in name order, no labels (the order is printed). Blender has numpy, not PIL:
#   blender -b --factory-startup -P contact_sheet.py -- <preview dir> <out.png> [columns]
import os
import sys

import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1 :]
folder, out = args[0], args[1]
cols = int(args[2]) if len(args) > 2 else 6
files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
size = 256
rows = (len(files) + cols - 1) // cols
sheet = np.ones((rows * size, cols * size, 4), dtype=np.float32)
for i, f in enumerate(files):
	img = bpy.data.images.load(os.path.join(folder, f))
	px = np.array(img.pixels[:], dtype=np.float32).reshape(img.size[1], img.size[0], 4)
	h, w = px.shape[0], px.shape[1]
	px = px[:size, :size]
	# image rows start at the bottom: the first file goes top-left
	r, c = i // cols, i % cols
	y0 = (rows - 1 - r) * size
	sheet[y0 : y0 + px.shape[0], c * size : c * size + px.shape[1]] = px
res = bpy.data.images.new("sheet", cols * size, rows * size)
res.pixels = sheet.flatten().tolist()
res.filepath_raw = out
res.file_format = "PNG"
res.save()
for i, f in enumerate(files):
	print(i // cols + 1, i % cols + 1, f[:-4])
