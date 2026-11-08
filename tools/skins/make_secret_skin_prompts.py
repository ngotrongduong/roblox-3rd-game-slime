# Goo Lineage V2 - ChatGPT prompts for the Secret slimes' body skins, three slimes per chat (the owner's call,
# 2026-11-08: every special slime gets a ChatGPT skin on the base body; ears, tails, horns and wings come later as
# separate parts).
#   python tools/skins/make_secret_skin_prompts.py <batch.json> [first group number] [folder prefix, default skins]
# batch.json: [{"subject": "secret-black-gray", "name": "Shadow Wolf", "desc": "..."}], each subject folder in
# art/turnaround/ holding source.png. Writes art/turnaround/<prefix>-g<N>/prompt.txt and subjects.txt (the subjects
# in order) and prints the carry address of each group: the chat gets the slimes' own pictures.
import json
import os
import sys

ROOT = "C:/Roblox 3rd game/"
WORK = ROOT + "art/turnaround/"
PER_CHAT = 3

# No layout example is attached any more: the first round had a finished flat-vector skin as the format example and
# came back as simple as it ("too simple", the owner, 2026-11-08); a top band ChatGPT still leaves is cut by
# prepare_secret_skins.py. Without "brushwork, never flat vector" about one chat in three still came back as flat
# vector fills.
TEMPLATE = (
	"These are {count} slimes from our own game (pictures 1 to {count}, our own art): {list}. With the image generator "
	"(not code), make {count} SEPARATE images, one skin for each slime in the same order. Each is a wide 2:1 unwrapped "
	"all-round skin texture for its round slime body, as rich and detailed as the slime's own picture: the same art "
	"style, the same painted detail, texture and colour richness (fine painterly detail, colour variation, many small "
	"motifs), high quality and crisp at full size, not simplified: hand-painted with visible brushwork and softly blended "
	"colour inside every shape, like a painted game texture, never flat vector art, clip-art or plain single-colour "
	"fills. Layout: the top edge of the image is the tip at the "
	"top of the slime, the bottom edge is its base, the middle of the image is the slime's front (what we see in its "
	"picture), the left half continues the left side of the front round to the back and the right half the right side, "
	"and the left and right edges meet at the back, so they must join seamlessly. The top fifth of the image is squeezed "
	"into the small tip, so keep the main motifs in the middle band. Copy each slime's own design, colours and surface "
	"details (patterns, markings, scales, clouds, stars and so on) faithfully and spread them all round the body. Only "
	"the body's surface: no ears, horns, wings, fins, tails, tentacles, crests, antlers or feet (those are separate 3D "
	"parts), no face (no eyes, no mouth: added in the game), nothing floating around it. Fill the whole image edge to "
	"edge, the top edge too: no white or empty area, no background, no outline or bump of the slime's top, no border. "
	"The game lights the body itself, so paint no lighting: no highlights or shine spots, no gloss or reflections, no "
	"rim light, no cast shadows, no dark-to-light shading across the body; all the detail of the design stays. No text "
	"or labels."
)


def main():
	batch = json.load(open(sys.argv[1], encoding="utf-8"))
	first = int(sys.argv[2]) if len(sys.argv) > 2 else 1
	prefix = sys.argv[3] if len(sys.argv) > 3 else "skins"
	for g, start in enumerate(range(0, len(batch), PER_CHAT)):
		group = batch[start:start + PER_CHAT]
		folder = "%s-g%d" % (prefix, first + g)
		os.makedirs(WORK + folder, exist_ok=True)
		names = "; ".join("%d) the %s (%s)" % (i + 1, s["name"], s["desc"]) for i, s in enumerate(group))
		with open(WORK + folder + "/prompt.txt", "w", encoding="utf-8") as f:
			f.write(TEMPLATE.format(count=len(group), list=names))
		with open(WORK + folder + "/subjects.txt", "w", encoding="utf-8") as f:
			f.write("\n".join(s["subject"] for s in group) + "\n")
		files = ",".join(s["subject"] + "/source.png" for s in group)
		print(folder, "http://localhost:5333/_tools/carry.html?site=chatgpt&w=1024&to=/&p=%s/prompt.txt&f=%s" % (folder, files))


main()
