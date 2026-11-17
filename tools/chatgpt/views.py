# The request for a landmark's FOUR-SIDE reference sheet (the owner, 2026-11-17: "với mỗi tòa nhà bạn hãy yêu cầu
# chatgpt cho xem hình tham chiếu ở các mặt khác nhau"): one message an era, carried with that era's panel of the
# building's concept sheet. ChatGPT answers with ONE image, a 2 x 2 grid of straight-on elevations (front, left, back,
# right), which the Blender build is measured from (skill landmark-build).
#   python tools/chatgpt/views.py granary
# writes art/inbox/prompts/<building>_era<N>.txt and prints the address to open in the browser pane for each era
# (the era's panel must already be cut to art/inbox/<building>_era<N>.jpg).
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

ASK = (
	"This is one building from a cozy low-poly Roblox farm game: {what}. I will model it in Blender and need to see "
	"every side of it. With the image generator (not code), draw ONE image: a 2 x 2 grid of four straight-on elevation "
	"views of exactly this same building, like an architect's turnaround sheet: top-left the FRONT ({front}), top-right "
	"the LEFT side (the side at the left of my picture{left}), bottom-left the BACK, bottom-right the RIGHT side (the "
	"side at the right of my picture{right}). Flat orthographic camera at mid height, no perspective, the same scale in "
	"all four views, each standing on the same ground line; the back's outline is the mirror of the front's and the "
	"right side's the mirror of the left's. Draw every wall, window, beam, roof course, tower and attached part fully "
	"and clearly, and invent sensible back and side walls in the same style (windows, a small back door). Keep my "
	"picture's exact style, colours and materials. Only the building itself: no farmer, no crates, sacks, plants or "
	"loose props, no cast shadows. Plain light grey background, wide gaps between the four views, no text, labels or "
	"numbers."
)

# building -> its eras: what it is, what the front is, what stands on the left and on the right
BUILDINGS = {
	"granary": [
		("the village granary at its first era (thatch and cream plaster on brown beams, a small clock tower on the ridge, "
			"an open lean-to shed along its right wall, two wooden silos behind the shed)", "the gable with the great door",
			"", ": the lean-to shed and the silos"),
		("the village granary at its second era (cream plaster on teal-painted beams, red clay tiles, an arched great "
			"door, a clock tower on the ridge, a lower wing with its own gabled roof on the left wall, an open lean-to shed "
			"along the right wall, two silos behind the shed)", "the gable with the great arched door",
			": the wing", ": the lean-to shed and the silos"),
		("the village granary at its third era (a grey stone ground storey under a jettied half-timbered upper storey, red "
			"clay tiles, a stone clock tower on the ridge, a round stone turret, a wing on the left wall, an open lean-to "
			"shed along the right wall, three stone silos with red cone roofs behind the shed)",
			"the gable with the great stone arch", ": the wing and the turret", ": the lean-to shed and the silos"),
		("the village granary at its fourth era (a dark steel-framed glasshouse on a brick foot, blue slate roofs, a "
			"glass-domed clock tower, copper pipes, a glazed wing on the left wall, an open lean-to shed along the right "
			"wall, two glass silos of glowing green goo behind the shed)", "the glazed gable with the great arched door",
			": the glazed wing", ": the lean-to shed and the goo silos"),
		("the village granary at its fifth era (white marble and gold, blue tiled roofs and domes, a pediment with a "
			"golden crowned slime over the great arched door, a domed clock tower, a marble wing on the left wall, an open "
			"lean-to shed along the right wall, golden silos under blue domes behind the shed)",
			"the pediment with the great arched door", ": the marble wing", ": the lean-to shed and the golden silos"),
	],
}

name = sys.argv[1]
os.makedirs(os.path.join(ROOT, "art", "inbox", "prompts"), exist_ok=True)
for n, (what, front, left, right) in enumerate(BUILDINGS[name], 1):
	rel = f"art/inbox/prompts/{name}_era{n}.txt"
	with open(os.path.join(ROOT, rel), "w", encoding="utf-8") as fh:
		fh.write(ASK.format(what=what, front=front, left=left, right=right))
	print(f"http://127.0.0.1:18923/tools/chatgpt/carry.html?f=art/inbox/{name}_era{n}.jpg&w=1000&p={rel}")
