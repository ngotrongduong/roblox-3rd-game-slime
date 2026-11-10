"""Writes the ear editor's read-back (ear_read.luau's JSON) into src/shared/ConfigWear.luau (skill slime-wear).

    python ear_write.py <read.json> <ConfigWear.luau>

Each piece named in the JSON gets its `size`, `at` and `anchor` lines replaced and a `turn` line after its anchor;
its mesh, texture and motion stay. Prints every piece it changed.
"""
import json
import re
import sys


def nums(v):
	return "{ " + ", ".join(f"{x:g}" for x in v) + " }"


def main():
	data = json.load(open(sys.argv[1], encoding="utf-8-sig"))
	if not data:
		print("nothing moved")
		return
	path = sys.argv[2]
	text = open(path, encoding="utf-8").read()
	for kit, pieces in data.items():
		start = text.index(f"\n\t\t{kit} = {{\n")
		end = text.index("\n\t\t},\n", start)
		block = text[start:end]
		for name, p in pieces.items():
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
