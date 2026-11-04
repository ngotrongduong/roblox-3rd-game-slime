# Prints the painting colour (mean of a 9x9 patch, hex) at given points: blender -b --factory-startup -P sample.py -- name:x,y name:x,y ...
# The first argument is the painting file name, e.g. enemy-green-sprout.png
import sys

sys.path.insert(0, "C:/Roblox 3rd game/tools/blender/monsters")
import common as C

args = sys.argv[sys.argv.index("--") + 1 :]
img = C.load_rgba(C.ART + args[0])
for a in args[1:]:
	name, xy = a.split(":")
	x, y = [int(v) for v in xy.split(",")]
	p = img[y - 4 : y + 5, x - 4 : x + 5, :3].reshape(-1, 3).mean(0)
	print("[sample] %s (%d,%d) #%02X%02X%02X" % (name, x, y, *[int(round(c * 255)) for c in p]))
