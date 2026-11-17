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
	"kitchen": [
		("the village kitchen at its first era (an open-fronted cookhouse: thatch on brown posts, a cream plaster "
			"gable, plank half walls, a tall fieldstone chimney standing outside its left wall, a small thatched lean-to "
			"on posts on the right)", "the gable over the one wide open front, with no door",
			": the great chimney", ": the lean-to"),
		("the village kitchen at its second era (cream plaster on teal-painted beams, red clay tiles, a wide open front "
			"on posts, a tall red brick chimney with a cream cap and a domed bread oven at its foot outside the left wall, "
			"a small gabled wing and a striped awning on posts on the right)",
			"the gable over the one wide open front, with no door", ": the great chimney and the oven",
			": the wing and the awning"),
		("the village kitchen at its third era (a pale stone ground storey with ONE wide stone arch across the front "
			"under a jettied half-timbered gable, red clay tiles, a tall stone chimney with a small round turret outside "
			"the left wall, a small gabled wing and a raised stone terrace with a balustrade on the right)",
			"the timber gable over the one wide open stone arch, with no door", ": the great chimney and its turret",
			": the wing and the terrace"),
		("the village kitchen at its fourth era (brick piers and a black riveted steel frame, a barrel vault roof with "
			"a glazed steel fan in its front end over one wide arch, copper pipes, a tall stone chimney with brass bands "
			"outside the left wall, two glass kettles of glowing green goo beside it, a glass canopy and a small wing on "
			"the right)", "the glazed end of the vault over the one wide open arch, with no door",
			": the great chimney and the goo kettles", ": the wing and the glass canopy"),
		("the village kitchen at its fifth era (white marble and gold: columns and an entablature across the front, a "
			"pediment over one wide arched portal, blue tiled roofs and a great blue dome with gold ribs, a round marble "
			"chimney with gold bands and a crown outside the left wall, a small marble wing and a round domed colonnade "
			"on the right)", "the pediment over the one wide open arched portal, with no door",
			": the great chimney", ": the wing and the round colonnade"),
	],
	# (the picture is the whole fenced garden: only the house across its back is asked for)
	"garden": [
		("the GARDEN HOUSE that stands across the back of this fenced vegetable garden, at its first era (a small "
			"potting shed: shaggy thatch on brown posts, a cream plaster gable with brown beams and a small window, plank "
			"half walls). Draw ONLY that house: leave out the fence, the gate, the vegetable beds, the scarecrow and the "
			"well with its wind wheel", "the gable over the one wide open front, with no door", "", ""),
		("the GARDEN HOUSE that stands across the back of this fenced vegetable garden, at its second era (cream "
			"plaster on teal-painted beams, red clay tiles, a gable window with a flower box, a small dormer, a wide open "
			"front under a flat timber arch, a small glass cold frame leaning on its right wall). Draw ONLY that house: "
			"leave out the fence, the gate, the vegetable beds and the windmill on its brick foot",
			"the gable over the one wide open front, with no door", "", ": the glass cold frame"),
		("the GARDEN HOUSE that stands across the back of this fenced vegetable garden, at its third era (a stone "
			"orangery: ONE wide stone arch in the middle between two tall arched glazed windows, under a half-timbered "
			"upper storey with a gable and two dormers, red clay tiles, ivy on the stone). Draw ONLY that house: leave out "
			"the fence, the gate, the vegetable beds, the grape arbour and the round stone windmill",
			"the timber gable over the one wide open stone arch, with no door", "", ""),
		("the GARDEN HOUSE that stands across the back of this fenced vegetable garden, at its fourth era (a vaulted "
			"greenhouse of black riveted steel and teal glass: a tall barrel-vaulted nave between two lower vaulted "
			"aisles, glazed fan ends, copper pipes over the vault, one wide open arch in the front). Draw ONLY that "
			"greenhouse: leave out the fence, the gate, the vegetable beds, the sprinklers, the goo tanks and the steel "
			"wind wheel tower", "the glazed end of the nave over the one wide open arch, with no door",
			": the left aisle", ": the right aisle"),
		("the GARDEN HOUSE that stands across the back of this fenced vegetable garden, at its fifth era (a palm house "
			"of white marble and gold: columns and a pediment with a golden laurel crest over one wide open portal, a tall "
			"arched glazed window on each side of it, a great blue glass dome with gold ribs over the middle and a small "
			"blue dome over each end). Draw ONLY that palm house: leave out the balustrade, the gate, the vegetable beds, "
			"the urns, the water stairs and the marble windmill",
			"the pediment over the one wide open portal, with no door", ": the left small dome", ": the right small dome"),
	],
	# (the picture is the whole fenced breeding pen: only the hall across its back, with its warm room, is asked for)
	"breeding": [
		("the HATCHERY HALL that stands across the back of this fenced slime breeding pen, at its first era (shaggy "
			"thatch on brown posts and beams, cream plaster, a wide open front, a pink heart plaque over it, a great "
			"spotted egg in a straw nest on the ridge, and a low thatched warm room with a fieldstone chimney joined to "
			"its left wall). Draw ONLY that hall with its warm room: leave out the wattle fence, the gate, the straw "
			"nests, the glass incubators and every egg on the ground",
			"the gable over the one wide open front, with no door", ": the warm room and its chimney", ""),
		("the HATCHERY HALL that stands across the back of this fenced slime breeding pen, at its second era (cream "
			"plaster on rose-pink beams, red clay tiles, a cross gable with a pink heart plaque over the wide open front, "
			"a great spotted egg on the ridge, a lower tiled wing on its right wall, and a low tiled stove room with a red "
			"brick chimney and a glowing oven mouth joined to its left wall). Draw ONLY that hall with its stove room: "
			"leave out the picket fence, the gate, the straw nests, the glass incubators and every egg on the ground",
			"the cross gable over the one wide open front, with no door", ": the stove room and its chimney",
			": the lower wing"),
		("the HATCHERY HALL that stands across the back of this fenced slime breeding pen, at its third era (a grey "
			"stone hall with ONE wide stone arch in the middle under a pink heart plaque, a round stone drum with small "
			"round windows carrying the great spotted egg on the roof, half-timbered gables under red clay tiles on both "
			"sides, and a round stone turret with a red cone roof and a chimney at its left end). Draw ONLY that hall "
			"with its turret: leave out the stone fence, the gate, the banners, the straw nests, the copper incubators "
			"and every egg on the ground", "the one wide open stone arch, with no door", ": the round turret", ""),
		("the HATCHERY HALL that stands across the back of this fenced slime breeding pen, at its fourth era (black "
			"riveted steel and teal glass: a great glass dome with the spotted egg inside it over the middle, a lower "
			"glazed vault on each side, one wide open arch in the front under a pink heart plaque, copper pipes over "
			"the vaults, and at its left end a small brick room, a round glass boiler of glowing green goo and a dark "
			"stone chimney). Draw ONLY that hall with its boiler: leave out the iron fence, the gate, the straw nests, "
			"the glass incubators and every egg on the ground", "the one wide open arch under the dome, with no door",
			": the boiler and the chimney", ": the right vault"),
		("the HATCHERY HALL that stands across the back of this fenced slime breeding pen, at its fifth era (white "
			"marble and gold: columns and a pediment with a pink heart in gold laurels over one wide open portal, a tall "
			"arched glazed window on each side of it, a great cream dome with lavender spots, gold ribs and a gold crown "
			"over the middle, a small blue dome with gold ribs over each end, and a round marble chimney with gold bands "
			"at its left end). Draw ONLY that hall: leave out the balustrade, the gate, the banners, the urns, the straw "
			"nests, the glass incubators and every egg on the ground",
			"the pediment over the one wide open portal, with no door", ": the chimney and the left small dome",
			": the right small dome"),
	],
}

name = sys.argv[1]
os.makedirs(os.path.join(ROOT, "art", "inbox", "prompts"), exist_ok=True)
for n, (what, front, left, right) in enumerate(BUILDINGS[name], 1):
	rel = f"art/inbox/prompts/{name}_era{n}.txt"
	with open(os.path.join(ROOT, rel), "w", encoding="utf-8") as fh:
		fh.write(ASK.format(what=what, front=front, left=left, right=right))
	# (the era's panel: the cut in art/inbox, else the reference file a later landmark already has)
	panel = f"art/inbox/{name}_era{n}.jpg"
	if not os.path.exists(os.path.join(ROOT, panel)):
		panel = f"docs/areas/village-v2/{name}-ref-era{n}.jpg"
	print(f"http://127.0.0.1:18923/tools/chatgpt/carry.html?f={panel}&w=1000&p={rel}")
