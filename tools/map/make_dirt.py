# Two calm painted earths for the valley's middle, made from art/textures/watercolor/DirtPath.png (Voxel Core Lab, CC0, Jonas Voland):
# DirtRoad (the roads and trails: a soft tan) and DirtWorn (worn earth under trees and in the quarters: a darker rust brown). The picture's
# light and dark are kept but flattened (lower contrast), its colour is mapped onto two tones and only a little of the original is left, so
# no orange and pink mottling. Run: python tools/map/make_dirt.py
import os

from PIL import Image, ImageChops, ImageEnhance

here = os.path.dirname(os.path.abspath(__file__))
folder = os.path.join(here, "..", "..", "art", "textures", "watercolor")
source = Image.open(os.path.join(folder, "DirtPath.png")).convert("RGB").resize((512, 512), Image.LANCZOS)
grey = ImageEnhance.Contrast(source.convert("L")).enhance(1.5)

TONES = {
	"DirtRoad": ((132, 94, 58), (204, 164, 112), 0.15),
	"DirtWorn": ((62, 42, 30), (146, 108, 74), 0.15),
}
for name, (dark, light, keep) in TONES.items():
	ramp = Image.merge(
		"RGB",
		tuple(grey.point(lambda v, a=dark[i], b=light[i]: int(a + (b - a) * min(255, max(0, (v - 70) * 255 / 130)) / 255)) for i in range(3)),
	)
	calm = ImageEnhance.Color(source).enhance(0.35)
	result = Image.blend(ramp, calm, keep)
	result.save(os.path.join(folder, name + ".png"))
	print("wrote", name)
