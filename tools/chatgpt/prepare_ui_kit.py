# A UI kit sheet from ChatGPT (art/inbox/<sheet>.png or .webp: separate pieces on flat magenta) cut into its pieces: the
# magenta keyed out (prepare_icons.key_out), each piece found as a patch of solid pixels (patches closer than GAP joined, so
# a leaf beside a ribbon stays with it), sorted in rows, top to bottom and left to right, and saved at full size as
# art/ui/kit/<sheet>-<n>.png. A numbered preview goes to art/inbox/<sheet>-pieces.png to name them by.
#   python tools/chatgpt/prepare_ui_kit.py kit-frames
import os
import sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prepare_icons import key_out  # noqa: E402

ROOT = "C:/Roblox 3rd game/"
OUT = ROOT + "art/ui/kit/"
STEP = 4  # the patch search runs on every STEP-th pixel
GAP = 24  # pixels: patches closer than this are one piece
MIN_SIDE = 24  # pixels: smaller specks are dropped
FONT = ImageFont.load_default(40)


def patches(alpha):
	w, h = alpha.width // STEP, alpha.height // STEP
	small = alpha.resize((w, h), Image.BOX).load()
	seen = bytearray(w * h)
	boxes = []
	for sy in range(h):
		for sx in range(w):
			if seen[sy * w + sx] or small[sx, sy] < 64:
				continue
			seen[sy * w + sx] = 1
			stack, box = [(sx, sy)], [sx, sy, sx, sy]
			while stack:
				x, y = stack.pop()
				box = [min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)]
				for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
					if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and small[nx, ny] >= 64:
						seen[ny * w + nx] = 1
						stack.append((nx, ny))
			boxes.append([box[0] * STEP, box[1] * STEP, (box[2] + 1) * STEP, (box[3] + 1) * STEP])
	return boxes


def near(a, b):
	return a[0] - GAP <= b[2] and b[0] - GAP <= a[2] and a[1] - GAP <= b[3] and b[1] - GAP <= a[3]


def join(boxes):
	merged = True
	while merged:
		merged = False
		for i in range(len(boxes)):
			for j in range(i + 1, len(boxes)):
				if near(boxes[i], boxes[j]):
					a, b = boxes[i], boxes.pop(j)
					boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
					merged = True
					break
			if merged:
				break
	return [b for b in boxes if b[2] - b[0] >= MIN_SIDE and b[3] - b[1] >= MIN_SIDE]


def in_rows(boxes):
	boxes.sort(key=lambda b: b[1])
	rows, row = [], []
	for b in boxes:
		# a piece whose top is below the middle of the row's first piece starts a new row
		if row and b[1] > (row[0][1] + row[0][3]) / 2:
			rows.append(row)
			row = []
		row.append(b)
	if row:
		rows.append(row)
	return [b for r in rows for b in sorted(r, key=lambda b: b[0])]


def main():
	os.makedirs(OUT, exist_ok=True)
	for sheet in sys.argv[1:]:
		path = ROOT + "art/inbox/" + sheet
		image = Image.open(path + (".webp" if os.path.exists(path + ".webp") else ".png")).convert("RGBA")
		key_out(image)
		alpha = image.getchannel("A")
		preview = Image.new("RGBA", image.size, (40, 40, 40, 255))
		preview.alpha_composite(image)
		draw = ImageDraw.Draw(preview)
		for n, box in enumerate(in_rows(join(patches(alpha))), 1):
			# tighten the coarse box to the real pixels
			tight = alpha.crop(box).point(lambda a: 255 if a > 16 else 0).getbbox()
			if tight:
				box = [box[0] + tight[0], box[1] + tight[1], box[0] + tight[2], box[1] + tight[3]]
			image.crop(box).save(OUT + sheet + "-" + str(n) + ".png")
			draw.rectangle(box, outline=(255, 0, 0, 255), width=3)
			draw.text((box[0] + 6, box[1] + 4), str(n), fill=(255, 255, 0, 255), font=FONT)
			print(sheet + "-" + str(n), "at", box, "size", box[2] - box[0], "x", box[3] - box[1])
		preview.convert("RGB").save(ROOT + "art/inbox/" + sheet + "-pieces.png")


if __name__ == "__main__":
	main()
