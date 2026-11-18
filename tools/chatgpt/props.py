# One reference picture an object, for a props sheet the owner sends (2026-11-18: "với mỗi một hình hãy yêu cầu
# chatgpt dựng 1 hình cho 1 vật phẩm. rồi sau đó liên kết với meshy dựng hình smart topology. nhớ chọn số lượng mesh
# cho phù hợp với từng vật phẩm"). One chat a sheet, the sheet attached once; ChatGPT draws one image an object, a
# batch a message; each picture then goes to Meshy Smart Topology at the triangle count named here (skill
# meshy-multiview, "Smart Topology"). The sheets are in docs/areas/village-v2/props/.
#   python tools/chatgpt/props.py lamppost
# writes art/inbox/prompts/props_<sheet>_<batch>.txt (the first carries the sheet, the later ones are typed into the
# same chat) and prints the address that opens the first one in the browser pane.
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

FIRST = (
	"This sheet is approved concept art from my cozy low-poly Roblox farm game: {what}. I will turn each object into "
	"its own 3D model with an image-to-3D tool (Meshy), so I need one clean reference picture per object. With the "
	"image generator (not code), please make {n} separate images, one object in each, in this order: {items}. Keep "
	"each object exactly as it is in my sheet: the same design, proportions, colours, materials and details, nothing "
	"added and nothing left out. Rules for every image: square; the one complete object alone, seen from the same "
	"three-quarter front view, slightly from above, as in my sheet; centred and filling about 80 percent of the image, "
	"nothing cropped; a solid matte look under soft even overcast light with gentle form shading only (nothing glows: "
	"lantern and window glass a plain pale warm yellow; no light rays, no shine spots, no cast shadow on the ground, no "
	"reflections); a plain flat light grey background #D9D9D9; no text, labels or numbers, no people."
)
NEXT = (
	"Thank you. Now the next {n} objects of the same sheet, again {n} separate images, one object in each, with exactly "
	"the same rules (square, the one complete object alone in the sheet's three-quarter view, centred, nothing cropped, "
	"matte under soft even light, nothing glowing, no cast shadow, plain flat light grey background #D9D9D9, no text), "
	"in this order: {items}."
)

# sheet -> (what the sheet shows, batches of (file name, what the object is, Meshy Smart Topology triangle count))
SHEETS = {
	"lamppost": ("five lamp posts, one per era of the village, from left to right", [[
		("lamp_wood", "the first, a plain wooden gallows lamp post: a square brown timber post with a bolted wooden arm "
			"and a diagonal brace, a bronze six-sided lantern hanging from a ring, on a two-step pale stone base", 2000),
		("lamp_painted", "the second, a teal-green painted timber post with a cream inset panel and a gold band, a green "
			"arm and brace, a small red clay-tiled pyramid roof with a gold finial on top, a bronze lantern hanging, on a "
			"two-step pale stone base", 2500),
		("lamp_stone", "the third, a square pale stone-brick pillar with green ivy climbing it, a gold band and a gold "
			"diamond plaque, a carved wooden bracket arm, a small red tiled roof with a gold finial on top, a bronze "
			"lantern hanging, on a stone base", 3000),
		("lamp_tech", "the fourth, a slime-tech pillar of dark riveted iron with teal glass panels, a brass gear and a "
			"copper pipe, a teal glass dome cap with brass ribs and a finial, an iron lattice arm, a round bronze lantern "
			"hanging, on a riveted iron base", 3500),
		("lamp_royal", "the fifth, a royal white marble column with gold bands, a blue banner with a gold crown, pink "
			"flowers and ivy climbing it, a gold crown cap over a blue ribbed dome with a gold finial, a gold scroll arm, "
			"a blue-and-gold crowned lantern hanging, on a marble base with a gold fleur-de-lis", 4000),
	]]),
	"flowerpot": ("five flower pots, one per era of the village, from left to right", [[
		("pot_clay", "the first, a plain terracotta pot full of white daisies with yellow middles and green leaves", 1500),
		("pot_barrel", "the second, a wooden barrel tub with two riveted iron bands, full of pink flowers and green "
			"leaves", 2000),
		("pot_stone", "the third, a pale stone-brick cube planter with a gold diamond on its front, full of purple "
			"flower clusters and green leaves", 2000),
		("pot_crown", "the fourth, a cream stone planter with gold trim and blue panels bearing gold crowns, full of "
			"yellow and white flowers with leaves trailing over its rim", 2500),
		("pot_urn", "the fifth, a white marble urn on a round pedestal with gold rims and a gold fleur-de-lis, full of "
			"pink roses and small white flowers with trailing vines", 3000),
	]]),
	"planter": ("five long flower troughs, one per era of the village, from left to right", [[
		("planter_wood", "the first, a plain wooden plank trough with yellow flowers and green leaves", 1500),
		("planter_riveted", "the second, a wooden plank trough with thick corner posts and metal rivets, full of pink "
			"flowers and green leaves", 2000),
		("planter_stone", "the third, a pale stone-brick trough with a gold diamond on its front, full of blue flower "
			"clusters and green leaves", 2000),
		("planter_crown", "the fourth, a cream stone trough with gold trim and a blue front panel bearing a gold crown, "
			"full of white flowers with leaves trailing over its rim", 3000),
		("planter_royal", "the fifth, a white marble balustrade trough with gold finial posts at its corners and a blue "
			"banner with a gold crown hanging in front, full of pink roses and small white flowers with trailing vines",
			4000),
	]]),
	"cart": ("five vegetable carts, one per era of the village, from left to right", [[
		("cart_barrow", "the first, a small wooden two-wheeled hand cart with two long handles, loaded with cabbages "
			"and carrots", 3000),
		("cart_awning", "the second, a wooden market cart with a red-and-cream striped awning on four posts, a teal side "
			"panel with a blank cream plaque, two spoked wheels and handles, loaded with a pumpkin, a cabbage and "
			"tomatoes", 4000),
		("cart_roofed", "the third, a wooden cart with a red clay-tiled gable roof on timber arches, two lanterns "
			"hanging at its front corners, a flower box, a leaf emblem, iron-banded spoked wheels and handles, loaded "
			"with vegetables", 5000),
	], [
		("cart_glass", "the fourth, a slime-tech cart: a glass barrel-vault canopy on dark riveted iron arches with a "
			"brass gear on top, ivy over it, two lanterns, a purple flower box, teal glass side panels, iron wheels and "
			"handles, loaded with vegetables", 6000),
		("cart_royal", "the fifth, a royal cart of cream marble and gold: a blue-and-gold striped dome canopy with a "
			"gold crown and four gold finials, blue banners with gold crowns, a flower box, blue-and-gold wheels and gold "
			"handles, loaded with vegetables", 6000),
	]]),
	"kitchen": ("the kitchen's signs, emblems, a finial and windows, read row by row from the top left", [[
		("sign_hat", "the top row's first, a wooden hanging sign: a short brown post with an arm, a brown wooden "
			"shield-shaped board with a white chef's hat on it hanging on two chains", 1500),
		("sign_spoon", "the top row's second, the same kind of post with a round brown wooden board bearing a crossed "
			"fork and spoon, hanging on two chains", 1500),
		("banner_red_hat", "the top row's third, a red pennant banner with a gold border hanging from a gold rod with a "
			"gold finial, a white chef's hat on it", 1000),
		("banner_blue_spoon", "the top row's fourth, a blue pennant banner with a gold border hanging from a gold rod "
			"with a gold finial, a gold crossed fork and spoon on it", 1000),
	], [
		("emblem_chef_slime", "the middle row's first, a round gold emblem: a smiling yellow slime wearing a white "
			"chef's hat inside a gold laurel wreath", 2500),
		("emblem_spoon_ribbon", "the middle row's second, a red emblem with a gold rim bearing a crossed fork and spoon, "
			"a white chef's hat on top and red ribbons at its sides", 2000),
		("finial_bell", "the middle row's third, a gold bell-shaped finial with a pointed top on a small pale "
			"stone-brick base", 1000),
	], [
		("window_roofed", "the bottom row's first, a square window with four panes in a cream timber frame, a small red "
			"clay-tiled roof over it and a wooden flower box of pink flowers under it", 2500),
		("window_arch", "the bottom row's second, an arched window with small panes in a pale stone surround and a "
			"flower box of pink flowers under it", 2000),
		("window_shutters", "the bottom row's third, a window with four panes, open green wooden shutters, a pale stone "
			"frame and a flower box of pink flowers under it", 2000),
		("window_plain", "the bottom row's fourth, a plain brown wooden window frame with four panes", 1000),
	]]),
}

if __name__ == "__main__":
	name = sys.argv[1]
	what, batches = SHEETS[name]
	os.makedirs(os.path.join(ROOT, "art", "inbox", "prompts"), exist_ok=True)
	for b, batch in enumerate(batches, 1):
		items = ", ".join(f"({i}) {desc}" for i, (_, desc, _) in enumerate(batch, 1))
		text = (FIRST if b == 1 else NEXT).format(what=what, n=len(batch), items=items)
		with open(os.path.join(ROOT, "art", "inbox", "prompts", f"props_{name}_{b}.txt"), "w", encoding="utf-8") as fh:
			fh.write(text)
		print(f"batch {b}: " + " ".join(file for file, _, _ in batch))
	print(f"http://127.0.0.1:18923/tools/chatgpt/carry.html?f=docs/areas/village-v2/props/{name}-sheet.jpg"
		f"&w=1400&p=art/inbox/prompts/props_{name}_1.txt")
