"""Writes the ear editor's read-back (ear_read.luau's JSON) into src/shared/ConfigWear.luau (skill slime-wear).

    python ear_write.py <read.json> <ConfigWear.luau>

Each piece named in the JSON gets its `size`, `at` and `anchor` lines replaced and a `turn` line after its anchor;
its mesh, texture and motion stay. A piece with `copy` (one he copied in the editor) is added after the piece it came
from, with that piece's mesh and motion. Prints every piece it changed.
"""
import json
import re
import sys


def nums(v):
	return "{ " + ", ".join(f"{(x if x != 0 else 0):g}" for x in v) + " }"


def even(pieces):
	"""A pair set as mirrors (ear_mirror.luau) gets mirrored anchors too: each is put back on the skin on its own."""
	for name, p in pieces.items():
		other = pieces.get(name[:-1] + "R") if name.endswith("L") else None
		if other and abs(p["at"][0] + other["at"][0]) < 0.001 and abs(p["at"][2] - other["at"][2]) < 0.001:
			a, b = p["anchor"], other["anchor"]
			mid = [round((a[0] - b[0]) / 2, 4), round((a[1] + b[1]) / 2, 4), round((a[2] + b[2]) / 2, 4)]
			p["anchor"] = mid
			other["anchor"] = [-mid[0], mid[1], mid[2]]


def main():
	data = json.load(open(sys.argv[1], encoding="utf-8-sig"))
	if not data:
		print("nothing moved")
		return
	path = sys.argv[2]
	text = open(path, encoding="utf-8").read()
	for kit, pieces in data.items():
		even(pieces)
		start = text.index(f"\n\t\t{kit} = {{\n")
		end = text.index("\n\t\t},\n", start)
		block = text[start:end]
		# copies last, after the pieces they came from
		for name, p in sorted(pieces.items(), key=lambda kv: bool(kv[1].get("copy"))):
			if p.get("copy"):
				# a piece he copied: the one it came from, written again under its own name just after it, without comments
				head = block.index(f'name = "{p["copy"]}",')
				tail = block.find("\n\t\t\t\t},", head)
				body = re.sub(r"\n\t+-- [^\n]*", "", block[head:tail]).replace(f'"{p["copy"]}"', f'"{name}"', 1)
				after = tail + len("\n\t\t\t\t},")
				block = block[:after] + "\n\t\t\t\t{\n\t\t\t\t\t" + body + "\n\t\t\t\t}," + block[after:]
			head = block.index(f'name = "{name}",')
			tail = block.find("\n\t\t\t\t},", head)
			piece = block[head:tail]
			for key in ("size", "at", "anchor"):
				piece, n = re.subn(rf"(\n\t+){key} = \{{[^}}]*\}},", rf"\g<1>{key} = {nums(p[key])},", piece, count=1)
				assert n == 1, (kit, name, key)
			piece = re.sub(r"\n\t+turn = \{[^}]*\},", "", piece)
			piece = re.sub(r"(\n(\t+)anchor = \{[^}]*\},)", rf"\g<1>\n\g<2>turn = {nums(p['turn'])},", piece, count=1)
			block = block[:head] + piece + block[tail:]
			print(kit, name, "at", p["at"], "turn", p["turn"])
		text = text[:start] + block + text[end:]
	open(path, "w", encoding="utf-8", newline="\n").write(text)


main()
