# Writes art/models/monsters/MOTION.md from each monster's <Name>.json (pieces, joints, motions). Run in Blender's
# python (no extra packages): blender -b --factory-startup -P motion_md.py
import json
import os

ROOT = "C:/Roblox 3rd game/art/models/monsters"
ORDER = [
	("Sproutling", "normal, melee", "walks and hops on the ground"),
	("HoneyBee", "normal, hunter", "flies: the game lifts the whole model 3-5 studs and bobs it"),
	("Puffdandy", "normal, ranged", "floats: the game lifts the whole model about 2 studs and drifts it"),
	("Glowmoth", "normal, healer", "flies: the game lifts the whole model 3-4 studs and bobs it"),
	("CloverSnail", "elite", "slides on the ground"),
	("Bloomshell", "mini-boss, wave 5", "walks on four legs"),
	("Bramblehorn", "boss, wave 10", "walks on four legs, charges"),
]
NOTES = {
	"HoneyBee": "Wings: each WingL/WingR holds a fore- and a hind-wing as flat sheets; set Transparency about 0.35 on both in game "
		"(the painting's wings are glassy). Flap 12-20 Hz about the root joint (rotate about the line along the body, the model's Y axis in Blender, Z in Roblox).",
	"Glowmoth": "Wings: set Transparency about 0.2 if wanted; the flap is slow (3-4 Hz, +-30 deg), a moth not a bee. "
		"The two antennae end in glowing drops (give them a PointLight / Neon material in game).",
	"Puffdandy": "The three loose dandelion seeds around the painting are NOT in the model (effect: drift them by code).",
	"CloverSnail": "The shell's spiral is on the monster's RIGHT side only (the painting shows that flank); the left side is plain leaves and dark shell.",
	"Bloomshell": "The Bud swells and glows before a big attack; Head lunges forward on a bite.",
	"Bramblehorn": "Glowing amber cores (back and one flank) are in the palette as bright colours: a Neon part or an emission pulse in game makes them glow.",
}


def main():
	out = []
	out.append("# Sunny Meadow monsters: pieces, joints and motions\n")
	out.append("Built by `tools/blender/monsters/*.py` (shared helper `common.py`; `build_all.ps1` rebuilds everything). One FBX and one 256 px palette png per monster in `art/models/monsters/<Name>/`.\n")
	out.append("## Conventions (read first)\n")
	out.append("- Scale: 1 Blender metre = 1 stud. The monster faces Blender -Y, which is Roblox -Z (the front of a Roblox model).")
	out.append("- Every monster is SEPARATE rigid mesh pieces, no armature (the game animates them procedurally, like the slimes). `Body` is the root; its origin is on the ground under the middle (feet at z 0, a hovering monster is lifted by the game).")
	out.append("- Each other piece has its ORIGIN AT ITS JOINT (the pivot to rotate about). Pieces keep their positions relative to Body, so the model is whole when every piece sits at its Body-relative joint.")
	out.append("- Names ending L are the monster's own LEFT. Seen from the front (the monster facing you) its left is on your right. In Blender that is +X; in Roblox mesh space it is -X.")
	out.append("- Axis mapping Blender (bx, by, bz) to Roblox mesh space: (-bx, bz, by); the FBX export (axis_forward -Z, axis_up Y) already does this, so in Studio the front is -Z and up is +Y. The joint tables below list Blender metres and the Roblox offset from Body.")
	out.append("- Material: one palette texture (nearest sampling), no baked light; the game light shades it. Faces are single-sided: Studio's backface culling is fine, leaves are thin double-sided sheets where it matters.")
	out.append("- Triangle budgets: normal 800-2000, elite up to 2500, mini-boss and boss up to 4000.\n")
	for name, kind, move in ORDER:
		p = os.path.join(ROOT, name, name + ".json")
		with open(p) as f:
			d = json.load(f)
		out.append("## %s (%s)\n" % (name, kind))
		out.append("Painting `%s`; %d tris, %d pieces, %.2f studs tall (target %.1f); %s." % (d["painting"], d["tris"], len(d["pieces"]), d["size_xyz"][2], d["target_height"], move))
		out.append("Bounding box (Blender metres): x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f.\n" % (d["bbox_min"][0], d["bbox_max"][0], d["bbox_min"][1], d["bbox_max"][1], d["bbox_min"][2], d["bbox_max"][2]))
		if name in NOTES:
			out.append(NOTES[name] + "\n")
		out.append("| Piece | Tris | Joint, Blender (x, y, z) | Joint, Roblox (x, y, z) | Motion |")
		out.append("|---|---|---|---|---|")
		for pc in d["pieces"]:
			j = pc["joint"]
			out.append("| %s | %d | %.2f, %.2f, %.2f | %.2f, %.2f, %.2f | %s |" % (pc["name"], pc["tris"], j[0], j[1], j[2], -j[0], j[2], j[1], pc["motion"]))
		out.append("")
	with open(ROOT + "/MOTION.md", "w") as f:
		f.write("\n".join(out))
	print("[monster] MOTION.md written")


main()
