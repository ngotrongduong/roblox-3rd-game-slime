# A Secret slime's worn pieces (Config.Wear) from the owner's model (Meshy, Tripo) of its horns, ears, wings and tail.
# Splits the file into its parts, lowers the triangles for phones, sets each piece on a slime body one unit tall (the
# game's mesh units), mirrors a piece into its twin where the file holds one of a pair, renders it from six sides into
# <folder>/review/, and exports:
#   <out>.fbx       the pieces (HornL HornR WingL WingR Tail, EarL EarR ...), placed around the body (feet at the origin)
#   <texture>.png   the texture at 1024
#   wear.json       each piece's centre, size and anchor (and a wing's flap axis) in Roblox mesh space: Config.Wear
# Blender axes are the slime body's own (tools/blender/slime_body.py): Z up, the slime faces -Y, its own left is +X.
# Exported like the body (FBX, forward -Z, up Y), so Roblox reads (X, Y, Z) = (-x, z, y).
# How the files lay their parts out so far: a wing's root at its +X end, spreading toward -X with its painted side to
# -Y; a horn's or an ear's base at the bottom (a horn's tip curling toward -X, an ear facing -Y); a tail's base at one
# end along X (`base`).
# Run: tools/blender/wear_kit.ps1 <kit>. The whole job, the kit fields and the lessons: skill slime-wear
# (.claude/skills/slime-wear), kept current with this file.
import bpy, bmesh, heapq, json, math, os, sys
from mathutils import Matrix, Vector

ART = r"C:\Roblox 3rd game\art\models\accessories"

def nearest(**marks):
	# a `sort` for a file of many loose bits: each goes to the part whose mark (x, z of its middle in the file, from
	# wear_inspect.ps1) is nearest
	return lambda c: min(marks, key=lambda k: (marks[k][0] - c.x) ** 2 + (marks[k][1] - c.z) ** 2)


# the owner's "feathered wing 3d model.glb" (2026-11-10): one torn bat wing, one big white feathered wing, one bee wing
WING_TRIO = nearest(Bat=(-0.295, 0.615), Feather=(-0.073, 0.212), Bee=(0.253, 0.577))

# the owner's "fantasy wings 3d model.glb" (2026-11-10): five single wings, one for each of five Secrets, every one with
# its root at its -X end (the narrow end where it meets the body), its tip up and toward +X: the file's right wing
FANTASY_WINGS = nearest(Moth=(-0.336, 0.598), Butterfly=(-0.21, 0.216), Phoenix=(-0.026, 0.568),
	Griffin=(0.207, 0.174), Fairy=(0.337, 0.575))
FANTASY_BUDGET = dict(Moth=344, Butterfly=656, Phoenix=546, Griffin=688, Fairy=506)

# the owner's "stylized fox tail 3d model.glb" (2026-11-10): four rows of two ears and a tail, top to bottom the Arctic
# Wolf's (navy and white), the Ember Tiger's (striped), the Witch Cat's (purple) and the Creamsicle Fox's. In each row the
# ear at x -0.02 opens toward +X: the slime's left ear
FOX_TAIL = nearest(WolfEarR=(-0.284, 0.855), WolfEarL=(-0.019, 0.853), WolfTail=(0.224, 0.856),
	TigerEarR=(-0.282, 0.615), TigerEarL=(-0.021, 0.62), TigerTail=(0.239, 0.617),
	CatEarR=(-0.28, 0.388), CatEarL=(-0.017, 0.386), CatTail=(0.24, 0.383),
	FoxEarR=(-0.282, 0.13), FoxEarL=(-0.021, 0.128), FoxTail=(0.231, 0.119))
FOX_BUDGET = dict(WolfEarR=462, WolfEarL=390, WolfTail=682, TigerEarR=424, TigerEarL=336, TigerTail=538, CatEarR=368,
	CatEarL=366, CatTail=701, FoxEarR=380, FoxEarL=320, FoxTail=812)

# the owner's "demon wings 3d model.glb" (2026-11-11): five pairs, top to bottom axolotl gills (two feathery fronds from
# one root, the root at the inner end), small leaves, big ribbed horns (a hollow cup at the foot, curling out and up),
# small horns, bat wings (the wrist knob and the root at the inner end, three fingers; the membrane bitten through
# between two fingers on each). The file's left one of each pair (x < 0) is the slime's right, except the wings: the
# file's left wing has its root at +X, so it spreads to the slime's left once turned (`wing`)
DEMON_WINGS = lambda c: (("GillL" if c.x > 0 else "GillR") if c.z > 0.7 else
	(("LeafL" if c.x > 0 else "LeafR") if c.z > 0.55 else
	((("HornL" if c.x > 0 else "HornR") if abs(c.x) > 0.18 else ("SpikeL" if c.x > 0 else "SpikeR")) if c.z > 0.3 else
	("BatR" if c.x > 0 else "BatL"))))
DEMON_BUDGET = dict(GillL=860, GillR=860, LeafL=134, LeafR=134, HornL=640, HornR=640, SpikeL=150, SpikeR=150, BatL=700,
	BatR=700)

# the owner's "fantasy icons 3d model.glb" (2026-11-11): two fox ears of autumn leaves (tilted toward each other, open
# toward each other), two reindeer antlers with holly and berries at their foot, two fish fins (the round root at the
# inner end, the fan out) and an angler fish's lure (the knob at its foot, arching over to the bulb)
FANTASY_ICONS = nearest(FoxEarA=(-0.412, 0.504), FoxEarB=(-0.17, 0.504), AntlerR=(0.198, 0.501),
	AntlerL=(0.401, 0.496), FinR=(-0.4, 0.111), FinL=(-0.161, 0.106), Lure=(0.267, 0.115))
FANTASY_ICONS_BUDGET = dict(FoxEarA=700, FoxEarB=700, AntlerR=510, AntlerL=600, FinR=700, FinL=700, Lure=442)

# the owner's "fluffy bunny ears 3d model.glb" (2026-11-11): white ears lying on their backs, tips back and out; pink
# ears that rise from a cup and flop over, hanging out to their side; a white and a pink round cotton tail (x > 0)
BUNNY_EARS = lambda c: (("TailW" if c.y > 0 else "TailP") if c.x > 0.15 else
	(("WEarR" if c.x < -0.18 else "WEarL") if c.y > 0 else ("PEarR" if c.x < -0.18 else "PEarL")))
BUNNY_BUDGET = dict(WEarR=284, WEarL=234, PEarR=258, PEarL=278, TailW=404, TailP=472)

# the owner's "fantasy wings 3d model (1).glb" (2026-11-11), not the 2026-11-10 file of that name: two ribbed ram horns
# (their spirals opening outward), a golden swirl of cloud, two starry navy feathered wings (each root at its inner
# end), two red dragon horns with a spiked gold collar at the foot, two whole red bat wings (the wrist knob at the inner
# end). Facing the file's front, the left one of each pair is the slime's right, except the wings (`aim`, `wing`)
FANTASY_WINGS_B = nearest(RedHornR=(-0.436, 0.156), RamHornR=(-0.312, 0.716), RedHornL=(-0.246, 0.155),
	StarWingL=(-0.175, 0.437), RamHornL=(-0.039, 0.712), BatL=(0.042, 0.188), StarWingR=(0.166, 0.439),
	Cloud=(0.245, 0.699), BatR=(0.344, 0.185))
FANTASY_WINGS_B_BUDGET = dict(RedHornR=434, RamHornR=460, RedHornL=348, StarWingL=528, RamHornL=502, BatL=598,
	StarWingR=700, Cloud=500, BatR=594)

# the owner's "golden wing 3d model.glb" (2026-11-11): two golden feathered wings with blue inner feathers (each root at
# its inner end), two striped green watermelon frog feet with pink toes, two green poison frog feet with purple spots;
# the feet lie flat, toes to the front (-Y)
GOLDEN_WING = nearest(FootWR=(-0.389, 0.071), GoldWingL=(-0.186, 0.448), FootWL=(-0.16, 0.077),
	FootPR=(0.155, 0.078), GoldWingR=(0.198, 0.456), FootPL=(0.392, 0.082))
GOLDEN_WING_BUDGET = dict(FootWR=164, GoldWingL=700, FootWL=124, FootPR=278, GoldWingR=499, FootPL=166)

# the owner's "fiery phoenix tail 3d model.glb" (2026-11-11): two red flame ears (fur inside) at the top, a golden lion's
# tail (a tuft at its tip) at bottom left, a red flame tail at bottom right; each tail's root is its thin curled end at -X
PHOENIX_TAIL = nearest(FlameEarR=(-0.257, 0.688), FlameEarL=(0.158, 0.698), LionTail=(-0.224, 0.326),
	FlameTail=(0.262, 0.315))
PHOENIX_TAIL_BUDGET = dict(FlameEarR=348, FlameEarL=422, LionTail=706, FlameTail=500)

# `sort` says which part of the file a loose bit belongs to, by its middle; `budget` the triangles a part keeps;
# `pieces` what is made of each part, in the order they are exported: kind (horn: horns and ears, wing, tail), where it
# sits on the body (Blender axes, body height 1; +X is the slime's own left), size factor, turns in degrees, and `twin`,
# the mirrored piece on the other side
KITS = {
	# Tempest Dragon (secret-black-blue), 2026-11-10
	"TempestDragon": dict(
		folder="tempest_dragon",
		glb="neon_dragon_relics.glb",
		out="TempestDragonWear",
		texture="tempest_dragon_wear.png",
		sort=lambda c: "Tail" if c.x < -0.185 else ("Horn" if c.x > 0.25 else "Wing"),
		budget=dict(Horn=520, Wing=760, Tail=640),
		pieces=dict(
			HornL=dict(part="Horn", kind="horn", at=(0.223, 0.002, 0.764), scale=0.92, tilt_out=16, tilt_back=18,
				curl="back", twin="HornR"),
			WingL=dict(part="Wing", kind="wing", at=(0.3, 0.34, 0.47), scale=1.5, raise_=24, sweep=38, twin="WingR"),
			Tail=dict(part="Tail", kind="tail", base="+x", at=(0.0, 0.44, 0.16), scale=1.25, lift=-12),
		),
		body=(0.05, 0.12, 0.45, 1),
	),
	# Steam Dragon (secret-blue-red), 2026-11-10
	"SteamDragon": dict(
		folder="steam_dragon",
		glb="patriotic_dragon_cost.glb",
		out="SteamDragonWear",
		texture="steam_dragon_wear.png",
		sort=lambda c: "Tail" if c.z < -0.02 else ("Horn" if c.x > 0.2 else "Wing"),
		budget=dict(Horn=900, Wing=900, Tail=900),
		pieces=dict(
			# (the owner's painting: the horns stand at the shoulders, their tips curling out to the sides)
			HornL=dict(part="Horn", kind="horn", at=(0.27, 0.04, 0.74), scale=0.8, tilt_out=14, tilt_back=0, curl="out",
				twin="HornR"),
			WingL=dict(part="Wing", kind="wing", at=(0.3, 0.34, 0.47), scale=1.1, raise_=24, sweep=38, twin="WingR"),
			Tail=dict(part="Tail", kind="tail", base="+x", at=(0.0, 0.45, 0.21), scale=0.62, lift=-14),
		),
		body=(0.55, 0.12, 0.1, 1),
	),
	# Fire-Ice Chimera (secret-navy-red), 2026-11-10: a red horn on the red side (its right), a blue one on the left, a
	# tail red at the base and blue at the arrow tip
	"FireIceChimera": dict(
		folder="fire_ice_chimera",
		glb="navy_red.glb",
		out="FireIceChimeraWear",
		texture="fire_ice_chimera_wear.png",
		sort=lambda c: "Tail" if c.z < 0 else ("HornR" if c.x < 0 else "HornL"),
		budget=dict(HornL=600, HornR=600, Tail=800),
		pieces=dict(
			# (the owner's painting: both stand at the shoulders, bulging out, their tips turning in; the file has them so
			# already, upright, so they keep its turn)
			HornL=dict(part="HornL", kind="horn", at=(0.26, 0.04, 0.74), scale=0.8, tilt_out=8, tilt_back=0, level=False),
			HornR=dict(part="HornR", kind="horn", at=(-0.26, 0.04, 0.74), scale=0.8, tilt_out=8, tilt_back=0, level=False),
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=0.55, lift=10, sink=True),
		),
		body=(0.45, 0.1, 0.25, 1),
	),
	# Shadow Wolf (secret-black-gray), 2026-11-10: two wolf ears and a bushy tail (Tripo, already a pair of ears)
	"ShadowWolf": dict(
		folder="shadow_wolf",
		glb="black_gray.glb",
		out="ShadowWolfWear",
		texture="shadow_wolf_wear.png",
		sort=lambda c: "Tail" if c.z < 0.5 else ("EarL" if c.x > 0 else "EarR"),
		budget=dict(EarL=700, EarR=700, Tail=900),
		pieces=dict(
			# (the owner's painting: upright at the shoulders, leaning out a little, open to the front, the fur at their
			# foot hanging down the shoulder)
			EarL=dict(part="EarL", kind="horn", at=(0.35, 0.0, 0.66), scale=0.85, tilt_out=8, tilt_back=0, level=False,
				foot="low"),
			EarR=dict(part="EarR", kind="horn", at=(-0.35, 0.0, 0.66), scale=0.85, tilt_out=8, tilt_back=0, level=False,
				foot="low"),
			Tail=dict(part="Tail", kind="tail", base="+x", at=(0.0, 0.45, 0.2), scale=0.55, lift=10, sink=True),
		),
		body=(0.1, 0.1, 0.12, 1),
	),
	# Void Kraken (secret-black-purple), 2026-11-10: eight cosmic tentacles with glowing suckers. The owner: they grow
	# from under the body and curl and wriggle like an octopus's arms. Around the foot, none straight in front. Raised
	# up the sides and back (the first try), several sank into the body and showed as stubs at its side, and some turned
	# their suckers up: every arm now joins under the body and goes out low, its suckers down or out (searched by the
	# tool)
	"VoidKraken": dict(
		folder="void_kraken",
		glb="black_purple.glb",
		out="VoidKrakenWear",
		texture="void_kraken_wear.png",
		sort=nearest(Arm1=(-0.374, 0.677), Arm2=(-0.124, 0.651), Arm3=(0.15, 0.67), Arm4=(0.379, 0.604),
			Arm5=(-0.357, 0.2), Arm6=(-0.129, 0.218), Arm7=(0.121, 0.12), Arm8=(0.378, 0.216)),
		budget=dict(Arm1=450, Arm2=450, Arm3=450, Arm4=450, Arm5=450, Arm6=450, Arm7=450, Arm8=450),
		pieces=dict(
			# (the front pair at 40 degrees, not 22.5: straight at the camera they read as stubs)
			Arm4=dict(part="Arm4", kind="tentacle", at=(40, 0.24, 0.04), scale=1.4),
			Arm5=dict(part="Arm5", kind="tentacle", at=(80, 0.24, 0.04), scale=1.5),
			Arm1=dict(part="Arm1", kind="tentacle", at=(120, 0.24, 0.04), scale=1.5),
			Arm2=dict(part="Arm2", kind="tentacle", at=(160, 0.24, 0.04), scale=1.6),
			Arm3=dict(part="Arm3", kind="tentacle", at=(-160, 0.24, 0.04), scale=1.6),
			Arm6=dict(part="Arm6", kind="tentacle", at=(-120, 0.24, 0.04), scale=1.5),
			Arm8=dict(part="Arm8", kind="tentacle", at=(-80, 0.24, 0.04), scale=1.5),
			Arm7=dict(part="Arm7", kind="tentacle", at=(-40, 0.24, 0.04), scale=1.4),
		),
		body=(0.12, 0.05, 0.3, 1),
	),
	# Midnight Raven (secret-black-navy), 2026-11-10: a pair of starry feathered wings, both in the file. The owner: the
	# painting's wings are not right, set them where they sit well on its back; raised, they stood up too high; folded,
	# at the sides or on the back, they were not what he wants: so they grow from the upper back and spread out
	# sideways, level, as a bird's open wings ("xoay ngang như đang xòe cánh"); the file's right wing on the slime's left
	# came out upside down ("vẫn bị lộn ngược"): seen from behind, each side wears the file's wing of the same side
	"MidnightRaven": dict(
		folder="midnight_raven",
		glb="black_navy.glb",
		out="MidnightRavenWear",
		texture="midnight_raven_wear.png",
		sort=lambda c: "WingL" if c.x < 0 else "WingR",
		budget=dict(WingL=900, WingR=900),
		pieces=dict(
			# (his sketch over the back view: the roots near the spine at mid-back, the wings wide, past the body by most
			# of their length, the long feathers' tips rising and curling up at the outer end, the rest fanning below)
			WingL=dict(part="WingL", kind="aim", root="+x", at=(0.17, 0.45, 0.53), scale=1.7, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
			WingR=dict(part="WingR", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=1.7, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
		),
		body=(0.05, 0.06, 0.2, 1),
	),
	# Gothic Bat (secret-black-pink), 2026-11-10: bat ears, bat wings with rose vines, a thorny tail with a rose at its
	# base and a pink tip
	"GothicBat": dict(
		folder="gothic_bat",
		glb="black_pink.glb",
		out="GothicBatWear",
		texture="gothic_bat_wear.png",
		sort=lambda c: "Tail" if c.z < 0.27 else (("EarL" if c.x > 0 else "EarR") if c.z > 0.59 else ("WingR" if c.x > 0 else "WingL")),
		budget=dict(EarL=500, EarR=500, WingL=700, WingR=700, Tail=900),
		pieces=dict(
			# (the owner's painting: big ears upright at the shoulders, leaning out, open to the front; the wings spread
			# out to the sides behind the shoulders)
			EarL=dict(part="EarL", kind="horn", at=(0.33, 0.0, 0.7), scale=1.5, tilt_out=12, tilt_back=0, level=False,
				foot="low"),
			EarR=dict(part="EarR", kind="horn", at=(-0.33, 0.0, 0.7), scale=1.5, tilt_out=12, tilt_back=0, level=False,
				foot="low"),
			WingL=dict(part="WingL", kind="wing", at=(0.32, 0.3, 0.5), scale=1.6, raise_=12, sweep=16),
			WingR=dict(part="WingR", kind="wing", root="-x", at=(-0.32, 0.3, 0.5), scale=1.6, raise_=12, sweep=16),
			# (the owner: the rose end grows from the body and shows, the pink tip is the end)
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.485, 0.2), scale=0.85, lift=5),
		),
		body=(0.6, 0.1, 0.3, 1),
	),
	# Jack-o'-Slime (secret-black-orange), 2026-11-10: a sheet of curling vines and leaves, laid around the pumpkin body
	# as the owner's painting has them: a leafy vine on each shoulder, a vine down each side, vines along the foot in
	# front; the big curly vine on the back (the face takes the front)
	"JackOSlime": dict(
		folder="jack_o_slime",
		glb="black_orange.glb",
		out="JackOSlimeWear",
		texture="jack_o_slime_wear.png",
		sort=nearest(
			VineTopR=(-0.336, 0.845),
			VineFootR=(-0.265, 0.082),
			VineBack=(-0.234, 0.478),
			LeafA=(-0.126, 0.246),
			LeafB=(-0.015, 0.481),
			LeafTop=(0.001, 0.917),
			LeafC=(0.019, 0.289),
			VineSideR=(0.187, 0.451),
			VineFootL=(0.282, 0.068),
			VineTopL=(0.304, 0.874),
			VineSideL=(0.373, 0.441),
		),
		budget=dict(VineTopR=260, VineFootR=260, VineBack=500, LeafA=60, LeafB=40, LeafTop=60, LeafC=40, VineSideR=280,
			VineFootL=300, VineTopL=280, VineSideL=280),
		pieces=dict(
			# (the owner: the vines grow out past the body, as his painting draws them round its outline) a leafy vine
			# rising off each shoulder, a curling vine down each side; `at` for a frame: (degrees around the body from the
			# front, + toward the slime's left; height; distance out from the middle line)
			VineTopL=dict(part="VineTopL", kind="frame", at=(90, 0.8, 0.44), scale=1.45, yaw=30),
			VineTopR=dict(part="VineTopR", kind="frame", at=(-90, 0.8, 0.44), scale=1.45, yaw=30),
			VineSideL=dict(part="VineSideL", kind="frame", at=(90, 0.34, 0.56), scale=1.3, hug=1, yaw=30),
			VineSideR=dict(part="VineSideR", kind="frame", at=(-90, 0.34, 0.56), scale=1.3, hug=1, yaw=30),
			# `at` for a wrap: (degrees around the body from the front, + toward the slime's left; height)
			VineFootL=dict(part="VineFootL", kind="wrap", at=(42, 0.12), scale=1.3),
			VineFootR=dict(part="VineFootR", kind="wrap", at=(-42, 0.12), scale=1.3),
			VineBack=dict(part="VineBack", kind="wrap", at=(180, 0.42), scale=1.3),
			LeafTop=dict(part="LeafTop", kind="wrap", at=(150, 0.68), scale=1.5),
			LeafA=dict(part="LeafA", kind="wrap", at=(-125, 0.2), scale=1.5),
			LeafB=dict(part="LeafB", kind="wrap", at=(125, 0.22), scale=1.5),
			LeafC=dict(part="LeafC", kind="wrap", at=(-150, 0.66), scale=1.5),
		),
		body=(0.8, 0.3, 0.05, 1),
	),
	# Cotton Candy Sheep (secret-blue-pink), 2026-11-10: two spiral ram horns on the shoulders and a tuft of
	# cotton-candy puffs across the top. The file also holds two sheep ears, puff clouds for the sides and a cloud for
	# the foot: the owner kept only the horns and the tuft ("chỉ cần để lại cặp sừng và chỏm lông trên đầu"), so the
	# rest are parts no piece uses
	"CottonCandySheep": dict(
		folder="cotton_candy_sheep",
		glb="blue_pink.glb",
		out="CottonCandySheepWear",
		texture="cotton_candy_sheep_wear.png",
		sort=lambda c: (("HornL" if c.x > 0 else "HornR") if c.z > 0.5 else
			(("EarL" if c.x > 0 else "EarR") if abs(c.x) > 0.25 else "Garland") if c.z > 0.2 else
			("CloudFront" if abs(c.x) < 0.2 else ("CloudL" if c.x > 0 else "CloudR"))),
		budget=dict(HornL=500, HornR=500, EarL=400, EarR=400, Garland=400, CloudL=220, CloudR=220, CloudFront=380),
		pieces=dict(
			HornL=dict(part="HornL", kind="horn", at=(0.27, 0.0, 0.72), scale=0.55, tilt_out=10, tilt_back=0, level=False),
			HornR=dict(part="HornR", kind="horn", at=(-0.27, 0.0, 0.72), scale=0.55, tilt_out=10, tilt_back=0, level=False),
			Garland=dict(part="Garland", kind="aim", root="+x", at=(-0.23, -0.05, 0.8), scale=1.1, point=(-1, 0, 0),
				face=(0, -1, 0.3)),
		),
		body=(0.45, 0.6, 0.95, 1),
	),
	# Sunshower Fox (secret-blue-orange), 2026-11-10: two small pointed fox ears at the top corners, leaning out, and a
	# bushy tail (blue-white at the base, an orange curling tip)
	"SunshowerFox": dict(
		folder="sunshower_fox",
		glb="blue_orange.glb",
		out="SunshowerFoxWear",
		texture="sunshower_fox_wear.png",
		sort=lambda c: "Tail" if c.z < 0.45 else ("EarL" if c.x > 0 else "EarR"),
		budget=dict(EarL=620, EarR=620, Tail=900),
		pieces=dict(
			EarL=dict(part="EarL", kind="horn", at=(0.34, 0.0, 0.7), scale=0.75, tilt_out=32, tilt_back=0, level=False,
				foot="low"),
			EarR=dict(part="EarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=0.75, tilt_out=32, tilt_back=0, level=False,
				foot="low"),
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=0.95, lift=0, sink=True),
		),
		body=(0.3, 0.55, 0.9, 1),
	),
	# Cloud Pegasus (secret-blue-blue), 2026-11-10: a pair of small white feathered wings. The owner's file holds ONE
	# white feathered wing, one bee wing and one bat wing (WING_TRIO); each Secret takes its own and mirrors it into a
	# pair. Its root is at -X, spreading toward +X: the file's right wing, so it goes on the slime's right and its twin on
	# the left. A bird's wings take the Raven's pose, the owner's standard for every bird wing pair, only smaller
	"CloudPegasus": dict(
		folder="cloud_pegasus",
		glb="wing_trio.glb",
		out="CloudPegasusWear",
		texture="cloud_pegasus_wear.png",
		sort=WING_TRIO,
		budget=dict(Bat=300, Feather=900, Bee=300),
		pieces=dict(
			WingR=dict(part="Feather", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=0.8, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2), twin="WingL"),
		),
		body=(0.3, 0.6, 1, 1),
	),
	# Honeybee Slime (secret-black-yellow), 2026-11-10: a bee's two clear wings from the upper back, rising up and out
	# behind the shoulders as the painting has them (WING_TRIO's bee wing, root at -X: the file's right wing)
	"HoneybeeSlime": dict(
		folder="honeybee_slime",
		glb="wing_trio.glb",
		out="HoneybeeSlimeWear",
		texture="honeybee_slime_wear.png",
		sort=WING_TRIO,
		budget=dict(Bat=300, Feather=900, Bee=300),
		pieces=dict(
			WingR=dict(part="Bee", kind="aim", root="-x", at=(-0.24, 0.27, 0.7), scale=1.3, point=(0.65, 0.3, 0.7),
				face=(0, 1, 0.1), twin="WingL"),
		),
		body=(0.95, 0.8, 0.1, 1),
	),
	# Blood Moon Bat (secret-black-red), 2026-11-10: bat wings from the upper shoulders, up and out, the tips above the
	# top. WING_TRIO's bat wing came torn, two holes through its membrane: mended (`mend`). Root at -X: the file's right
	# wing
	"BloodMoonBat": dict(
		folder="blood_moon_bat",
		glb="wing_trio.glb",
		out="BloodMoonBatWear",
		texture="blood_moon_bat_wear.png",
		sort=WING_TRIO,
		budget=dict(Bat=600, Feather=900, Bee=300),
		mend=["Bat"],
		pieces=dict(
			WingR=dict(part="Bat", kind="wing", root="-x", at=(-0.28, 0.25, 0.66), scale=1.5, raise_=50, sweep=16,
				twin="WingL"),
		),
		body=(0.6, 0.05, 0.08, 1),
	),
	# Moonstone Gargoyle (secret-gray-purple), 2026-11-10: stone bat wings standing up and out behind the shoulders, two
	# small horns on the FRONT of the head's top corners (the file has them upright, tips curling out; further back they
	# merge with the wing roots seen from the game's camera), a scaly tail with an arrow tip (the painting shows none:
	# worn as the other tails are)
	"MoonstoneGargoyle": dict(
		folder="moonstone_gargoyle",
		glb="gray_purple.glb",
		out="MoonstoneGargoyleWear",
		texture="moonstone_gargoyle_wear.png",
		sort=lambda c: "Tail" if c.z < 0.2 else ((("HornR" if c.x < 0 else "HornL") if abs(c.x) < 0.2 else
			("WingL" if c.x < 0 else "WingR"))),
		budget=dict(HornL=400, HornR=400, WingL=600, WingR=600, Tail=700),
		pieces=dict(
			HornL=dict(part="HornL", kind="horn", at=(0.23, -0.1, 0.75), scale=1.0, tilt_out=6, tilt_back=0, level=False),
			HornR=dict(part="HornR", kind="horn", at=(-0.23, -0.1, 0.75), scale=1.0, tilt_out=6, tilt_back=0, level=False),
			WingL=dict(part="WingL", kind="wing", at=(0.29, 0.28, 0.67), scale=1.65, raise_=-5, sweep=30),
			WingR=dict(part="WingR", kind="wing", root="-x", at=(-0.29, 0.28, 0.67), scale=1.65, raise_=-5, sweep=30),
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.485, 0.2), scale=0.85, lift=5),
		),
		body=(0.45, 0.42, 0.5, 1),
	),
	# Frost Swan (secret-blue-white), 2026-11-10: the owner's file holds the painting's ice pieces as raised plaques: two
	# crystal frills shaped like wings, the crest under the top, a crest for the foot and a snowflake. The owner: use only
	# what fits, worn standing proud of the body, never sunk in ("gắn nổi trên thân slime, không phải chìm vào trong
	# thân"); the frills are not a bird's wings, they go where the painting has them ("không phải cánh chim, hãy gắn nó
	# vào vị trí giống như trong hình ảnh tham chiếu"): up the lower front sides, the feathers past the outline. The crest
	# lies on the front under the top. The foot's crest would meet the ground as the jelly squashes and the snowflake would
	# sit on the face: parts no piece uses
	"FrostSwan": dict(
		folder="frost_swan",
		glb="blue_white.glb",
		out="FrostSwanWear",
		texture="frost_swan_wear.png",
		sort=nearest(
			FrillR=(-0.335, 0.407),
			Foot=(-0.005, 0.122),
			Crest=(-0.009, 0.625),
			Flake=(-0.004, 0.399),
			FrillL=(0.307, 0.4),
		),
		budget=dict(FrillL=700, FrillR=700, Crest=300, Foot=320, Flake=180),
		pieces=dict(
			# `at` for a front piece: (across, + toward the slime's left; up) of its middle as the painting draws it
			FrillL=dict(part="FrillL", kind="front", at=(0.39, 0.41), scale=1.25, bend=15),
			FrillR=dict(part="FrillR", kind="front", at=(-0.39, 0.41), scale=1.25, bend=15),
			Crest=dict(part="Crest", kind="wrap", at=(0, 0.76), scale=1.25),
		),
		body=(0.55, 0.8, 1, 1),
	),
	# Forest Dryad (secret-green-green), 2026-11-10: the painting's leafy hair round the top with flowers, and small
	# antlers at the top corners. The file: two antlers with leaves and blossoms, the leafy arch of hair, a cluster of
	# blossoms, a big leaf, a small vine and a yellow pollen speck (no piece). The owner: "không cần phải chính xác như
	# trong hình, chỉ cần gắn lên cho đẹp": the hair worn where the painting has it, the blossoms, leaf and vine dress the
	# back
	"ForestDryad": dict(
		folder="forest_dryad",
		glb="green_green.glb",
		out="ForestDryadWear",
		texture="forest_dryad_wear.png",
		sort=lambda c: (("AntlerR" if c.x < -0.1 else ("AntlerL" if c.x < 0.2 else "Blossoms")) if c.z > 0.4 else
			("Hair" if c.x < 0 else ("Pollen" if c.z < 0.1 else ("Leaf" if c.x < 0.32 else "Vine")))),
		# (the leaves and blossoms keep nearly all their triangles: cut to 900, the hair's leaves broke into shards)
		budget=dict(AntlerL=470, AntlerR=390, Blossoms=420, Hair=2200, Leaf=160, Vine=180, Pollen=6),
		pieces=dict(
			# (1.1 hid behind the hair seen from the front in Play)
			AntlerL=dict(part="AntlerL", kind="horn", at=(0.25, 0.02, 0.76), scale=1.4, tilt_out=12, tilt_back=0),
			AntlerR=dict(part="AntlerR", kind="horn", at=(-0.25, 0.02, 0.76), scale=1.4, tilt_out=12, tilt_back=0),
			# (the owner: bent onto the skin by `front` and `wrap`, the leaves and blossoms came out deformed; worn rigid,
			# as the file shapes them, touching the body and standing off its curve)
			Hair=dict(part="Hair", kind="rigid", at=(0, 0.8), scale=1.4, tilt=55),
			Blossoms=dict(part="Blossoms", kind="rigid", at=(170, 0.62), scale=1.2, tilt=35),
			Leaf=dict(part="Leaf", kind="rigid", at=(-145, 0.34), scale=1.2, turn=-20),
			Vine=dict(part="Vine", kind="rigid", at=(140, 0.32), scale=1.3, turn=15),
		),
		body=(0.25, 0.6, 0.15, 1),
	),
	# Iron Boar (secret-gray-red), 2026-11-10: the painting's metal tusks out of red armour cuffs at the lower sides,
	# red armour plates on the sides. The file: two tusks in red cuffs (the owner: "là 2 cái nanh, không phải sừng"),
	# two armour plates, an armoured tail with an arrow tip, a spiked circlet, a chained collar and a loose red gem. No
	# piece for the plates (curved shoulder guards: laid on the front or wrapped round the sides, their outer half stood
	# off the body like fins; the skin already paints the red armour), the collar (no neck) or the gem (it would float)
	"IronBoar": dict(
		folder="iron_boar",
		glb="gray_red.glb",
		out="IronBoarWear",
		texture="iron_boar_wear.png",
		sort=lambda c: ("Tail" if c.z < 0.24 else
			(("TuskR" if c.x < -0.27 else ("TuskL" if c.x < 0 else "Circlet")) if c.z > 0.45 else
			("PlateR" if c.x < -0.3 else ("PlateL" if c.x < -0.05 else ("Collar" if c.x < 0.3 else "Gem"))))),
		budget=dict(TuskL=345, TuskR=345, PlateL=400, PlateR=400, Tail=900, Circlet=700, Collar=600, Gem=26),
		pieces=dict(
			# (worn as horns are: the cuff's open end faces the middle in the file, `spread` 90 finds it as the sole;
			# levelled, the tusk stands up out of it; `spin` turns its curl to the back, then it leans forward out of the
			# lower front either side of the mouth, its tip curling up. The owner: "nằm ở phía trước mặt, không phải ở 2
			# bên")
			TuskL=dict(part="TuskL", kind="horn", at=(0.22, -0.44, 0.26), scale=1.6, tilt_out=15, tilt_back=-70, spread=90,
				spin=-90),
			TuskR=dict(part="TuskR", kind="horn", at=(-0.22, -0.44, 0.26), scale=1.6, tilt_out=15, tilt_back=-70, spread=90,
				spin=90),
			# (round the front of the head, the spikes up: a rigid piece set by where it runs, as the sheep's garland)
			Circlet=dict(part="Circlet", kind="aim", root="+x", at=(0.32, -0.2, 0.7), scale=1.2, point=(-1, 0, 0),
				face=(0, -1, 0.1)),
			Tail=dict(part="Tail", kind="tail", base="-x", at=(0.0, 0.485, 0.2), scale=0.7, lift=5),
		),
		body=(0.55, 0.12, 0.1, 1),
	),
	# Peach Blossom (secret-pink-yellow), 2026-11-10: the painting's crown of peach blossoms across the top. The file:
	# the crown, two small blossom clusters, a blossom with a bead, a blossom branch with beads, a festoon with ribbons
	# and three loose petals. The crown where the painting has it, the clusters behind it on the head, the festoon across
	# the back; the bead blossom would sit on the face and the branch and petals add nothing (no piece)
	"PeachBlossom": dict(
		folder="peach_blossom",
		glb="pink_yellow.glb",
		out="PeachBlossomWear",
		texture="peach_blossom_wear.png",
		sort=lambda c: ("Crown" if c.z > 0.38 else
			(("ClusterR" if c.x < -0.15 else ("Bloom" if c.x < 0.15 else "ClusterL")) if c.z > 0.2 else
			("Branch" if c.x < -0.25 else ("Festoon" if c.x < 0.25 else "Petals")))),
		budget=dict(Crown=1800, ClusterL=420, ClusterR=390, Bloom=480, Branch=460, Festoon=800, Petals=32),
		pieces=dict(
			# (worn rigid, as the file shapes them: bent onto the skin the blossoms came out deformed)
			Crown=dict(part="Crown", kind="rigid", at=(0, 0.74), scale=1.3, tilt=40),
			ClusterL=dict(part="ClusterL", kind="rigid", at=(125, 0.62), scale=1.2, tilt=25),
			ClusterR=dict(part="ClusterR", kind="rigid", at=(-125, 0.62), scale=1.2, tilt=25),
			Festoon=dict(part="Festoon", kind="rigid", at=(180, 0.4), scale=1.05, tilt=5),
		),
		body=(0.95, 0.5, 0.65, 1),
	),
	# Amethyst Unicorn (secret-purple-purple), 2026-11-10: the painting's crystal horn at the top front, a flowing mane
	# and crystals low on the front. The file: the horn, the mane with small crystals in it, and a row of five crystals
	# (small, middle, big, middle, small). The owner: the mane runs like a horse's from the top front of the head down
	# the back to the feet, not at the sides of the face as the painting has it; flattened if too wide; nothing bent
	"AmethystUnicorn": dict(
		folder="amethyst_unicorn",
		glb="purple_purple.glb",
		out="AmethystUnicornWear",
		texture="amethyst_unicorn_wear.png",
		sort=lambda c: ("Horn" if c.z > 0.3 and c.x < 0 else ("Mane" if c.x > 0.15 else ("TipR" if c.x < -0.42 else
			("GemR" if c.x < -0.32 else ("Big" if c.x < -0.2 else ("GemL" if c.x < -0.08 else "TipL")))))),
		budget=dict(Horn=484, Mane=2600, TipR=26, GemR=64, Big=172, GemL=96, TipL=30),
		pieces=dict(
			# (the owner: on the forehead, under the top of the head, the tip leaning out forward, not straight up)
			Horn=dict(part="Horn", kind="horn", at=(0, -0.3, 0.76), scale=0.9, tilt_out=0, tilt_back=-40),
			# (laid along the spine seen from the side: the file's hair arcs from its top front over and down, as a mane
			# runs over a horse's neck; pitched steeper to fall down the back)
			Mane=dict(part="Mane", kind="rigid", lay="side", at=(180, 0.7), scale=1.55, squash=(1, 0.55, 1), turn=-10,
				tilt=65, tuck=0.3),
			# (the file's row, worn across the lower front)
			Big=dict(part="Big", kind="rigid", at=(0, 0.14), scale=0.8, tilt=-25),
			GemL=dict(part="GemL", kind="rigid", at=(25, 0.15), scale=0.8, tilt=-25),
			GemR=dict(part="GemR", kind="rigid", at=(-25, 0.15), scale=0.8, tilt=-25),
			TipL=dict(part="TipL", kind="rigid", at=(43, 0.13), scale=0.8, tilt=-25),
			TipR=dict(part="TipR", kind="rigid", at=(-43, 0.13), scale=0.8, tilt=-25),
		),
		body=(0.45, 0.2, 0.8, 1),
	),
	# Copper Beetle (secret-gray-orange), 2026-11-10: the painting is a beetle's shell over the whole body: a grey cap
	# with a point, an orange shield down the middle, orange shoulder plates, grey plates below them and four claws at
	# the feet. The file holds those pieces laid out as the painting draws them, with three small bands and two rivets.
	# Worn on the back (the shell of a beetle; the front keeps the face), each plate as the file shapes it
	"CopperBeetle": dict(
		folder="copper_beetle",
		glb="gray_orange.glb",
		out="CopperBeetleWear",
		texture="copper_beetle_wear.png",
		# (the file's left, x < 0, is the slime's left once the plates face backward)
		sort=lambda c: ("Cap" if c.z > 0.8 else (("ShoulderL" if c.x < 0 else "ShoulderR") if c.z > 0.6 and abs(c.x) > 0.15
			else ("Shield" if c.z > 0.5 else (("PlateL" if c.x < 0 else "PlateR") if c.z > 0.35 else
			(("ClawL1" if c.x < -0.2 else ("ClawL2" if c.x < 0 else ("ClawR2" if c.x < 0.2 else "ClawR1"))) if c.z < 0.15
			else ("KnobL" if c.x < -0.35 else ("BandL" if c.x < -0.1 else ("BandC" if c.x < 0.1 else
			("BandR" if c.x < 0.35 else "KnobR"))))))))),
		# (the plates are worn twice, front and back: a little lower than the file for phones)
		budget=dict(Cap=420, Shield=560, ShoulderL=400, ShoulderR=400, PlateL=350, PlateR=350, ClawL1=158, ClawL2=182,
			ClawR2=178, ClawR1=148, KnobL=22, KnobR=20, BandL=124, BandC=130, BandR=142),
		pieces=dict(
			# (each plate turned and leaned to lie on the body the closest it can, its edges let a little into the jelly:
			# set as they come, the curved plates stood off it like fins)
			Cap=dict(part="Cap", kind="rigid", at=(180, 0.86), scale=1.1, tuck=0.1, fit=((-30, 30, 5), (20, 85, 5))),
			# (the owner: "nhớ ghép cả giáp ở phần trước thân nữa": the shoulder and side plates on the front too, as the
			# painting draws them, either side of the face; the shield stays on the back, off the face. Facing the front,
			# the file's right-hand plates go on the slime's left)
			# (at 50 degrees the shoulders touched the eyes)
			FrontShoulderL=dict(part="ShoulderR", kind="rigid", at=(68, 0.66), scale=1.1, tuck=0.1,
				fit=((-60, 60, 5), (-10, 70, 5))),
			FrontShoulderR=dict(part="ShoulderL", kind="rigid", at=(-68, 0.66), scale=1.1, tuck=0.1,
				fit=((-60, 60, 5), (-10, 70, 5))),
			FrontPlateL=dict(part="PlateR", kind="rigid", at=(58, 0.34), scale=1.1, tuck=0.1,
				fit=((-60, 60, 5), (-40, 40, 5))),
			FrontPlateR=dict(part="PlateL", kind="rigid", at=(-58, 0.34), scale=1.1, tuck=0.1,
				fit=((-60, 60, 5), (-40, 40, 5))),
			Shield=dict(part="Shield", kind="rigid", at=(180, 0.55), scale=1.3, tuck=0.1, fit=((0, 0, 5), (-10, 50, 5))),
			ShoulderL=dict(part="ShoulderL", kind="rigid", at=(135, 0.66), scale=1.1, tuck=0.1,
				fit=((-60, 60, 5), (-10, 70, 5))),
			ShoulderR=dict(part="ShoulderR", kind="rigid", at=(-135, 0.66), scale=1.1, tuck=0.1,
				fit=((-60, 60, 5), (-10, 70, 5))),
			PlateL=dict(part="PlateL", kind="rigid", at=(130, 0.36), scale=1.1, tuck=0.1, fit=((-60, 60, 5), (-40, 40, 5))),
			PlateR=dict(part="PlateR", kind="rigid", at=(-130, 0.36), scale=1.1, tuck=0.1, fit=((-60, 60, 5), (-40, 40, 5))),
			# (little legs at the feet, two a side)
			ClawL1=dict(part="ClawL1", kind="rigid", at=(70, 0.11), scale=1.1, tilt=-20),
			ClawL2=dict(part="ClawL2", kind="rigid", at=(120, 0.11), scale=1.1, tilt=-20),
			ClawR2=dict(part="ClawR2", kind="rigid", at=(-120, 0.11), scale=1.1, tilt=-20),
			ClawR1=dict(part="ClawR1", kind="rigid", at=(-70, 0.11), scale=1.1, tilt=-20),
		),
		body=(0.5, 0.5, 0.52, 1),
	),
	# Five Secrets' wings from FANTASY_WINGS, 2026-11-10, each the file's right wing mirrored into a pair. The feathered
	# ones (Sun Phoenix, Royal Griffin) take Midnight Raven's pose, the owner's standard for a bird's wings; the fairy,
	# butterfly and moth wings sit on the back, not as their paintings have them (the owner, 2026-11-10: "không cần khớp
	# với tranh, cứ đặt ở vị trí sau lưng"), then lower, level with the body, and bigger ("quá cao, cho xuống thấp tầm
	# ngang thân dưới một chút, tăng kích thước cánh lên lớn hơn")
	"RoseFairy": dict(
		folder="rose_fairy",
		glb="fantasy_wings.glb",
		out="RoseFairyWear",
		texture="rose_fairy_wear.png",
		sort=FANTASY_WINGS,
		budget=FANTASY_BUDGET,
		pieces=dict(
			WingR=dict(part="Fairy", kind="aim", edge=True, root="-x", at=(-0.12, 0.52, 0.35), scale=2.45,
				point=(0.3, -0.25, 1), face=(0, 1, 0.1), twin="WingL"),
		),
		body=(0.95, 0.5, 0.7, 1),
	),
	"DreamButterfly": dict(
		folder="dream_butterfly",
		glb="fantasy_wings.glb",
		out="DreamButterflyWear",
		texture="dream_butterfly_wear.png",
		sort=FANTASY_WINGS,
		budget=FANTASY_BUDGET,
		pieces=dict(
			WingR=dict(part="Butterfly", kind="aim", edge=True, root="-x", at=(-0.12, 0.52, 0.35), scale=2.25,
				point=(0.3, -0.25, 1), face=(0, 1, 0.1), twin="WingL"),
		),
		body=(0.8, 0.45, 0.95, 1),
	),
	"TwilightMoth": dict(
		folder="twilight_moth",
		glb="fantasy_wings.glb",
		out="TwilightMothWear",
		texture="twilight_moth_wear.png",
		sort=FANTASY_WINGS,
		budget=FANTASY_BUDGET,
		pieces=dict(
			WingR=dict(part="Moth", kind="aim", edge=True, root="-x", at=(-0.12, 0.52, 0.35), scale=2.7,
				point=(0.3, -0.25, 1), face=(0, 1, 0.1), twin="WingL"),
		),
		body=(0.3, 0.2, 0.6, 1),
	),
	"SunPhoenix": dict(
		folder="sun_phoenix",
		glb="fantasy_wings.glb",
		out="SunPhoenixWear",
		texture="sun_phoenix_wear.png",
		sort=FANTASY_WINGS,
		budget=FANTASY_BUDGET,
		pieces=dict(
			WingR=dict(part="Phoenix", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=2.05, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2), twin="WingL"),
		),
		body=(1, 0.75, 0.15, 1),
	),
	"RoyalGriffin": dict(
		folder="royal_griffin",
		glb="fantasy_wings.glb",
		out="RoyalGriffinWear",
		texture="royal_griffin_wear.png",
		sort=FANTASY_WINGS,
		budget=FANTASY_BUDGET,
		pieces=dict(
			WingR=dict(part="Griffin", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=1.78, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2), twin="WingL"),
		),
		body=(1, 0.8, 0.2, 1),
	),
	# Four Secrets' ears and tails from FOX_TAIL, 2026-11-10: the ears upright at the top corners as the paintings have
	# them, leaning out a little, open to the front; the tail low on the back, as Shadow Wolf's
	"ArcticWolf": dict(
		folder="arctic_wolf",
		glb="fox_tail.glb",
		out="ArcticWolfWear",
		texture="arctic_wolf_wear.png",
		sort=FOX_TAIL,
		budget=FOX_BUDGET,
		pieces=dict(
			EarL=dict(part="WolfEarL", kind="horn", at=(0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			EarR=dict(part="WolfEarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			Tail=dict(part="WolfTail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=2.6, lift=0, sink=True),
		),
		body=(0.75, 0.82, 0.97, 1),
	),
	# Sun Lion (secret-yellow-yellow), 2026-11-11: the golden lion's tail of PHOENIX_TAIL (its mane is its own model's,
	# tools/blender/secret_mane.py)
	"SunLion": dict(
		folder="sun_lion",
		glb="phoenix_tail.glb",
		out="SunLionWear",
		texture="sun_lion_wear.png",
		sort=PHOENIX_TAIL,
		budget=PHOENIX_TAIL_BUDGET,
		pieces=dict(
			Tail=dict(part="LionTail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=1.2, lift=0, sink=True),
		),
		body=(1, 0.8, 0.2, 1),
	),
	# Fire Salamander (secret-red-yellow), 2026-11-11: the red flame ears and flame tail of PHOENIX_TAIL ("bộ tai đỏ và
	# đuôi đỏ là cho con Yellow+red"), worn as every fox's
	"FireSalamander": dict(
		folder="fire_salamander",
		glb="phoenix_tail.glb",
		out="FireSalamanderWear",
		texture="fire_salamander_wear.png",
		sort=PHOENIX_TAIL,
		budget=PHOENIX_TAIL_BUDGET,
		pieces=dict(
			EarL=dict(part="FlameEarL", kind="horn", at=(0.34, 0.0, 0.7), scale=0.9, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			EarR=dict(part="FlameEarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=0.9, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			Tail=dict(part="FlameTail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=1.2, lift=0, sink=True),
		),
		body=(0.9, 0.2, 0.1, 1),
	),
	"EmberTiger": dict(
		folder="ember_tiger",
		glb="fox_tail.glb",
		out="EmberTigerWear",
		texture="ember_tiger_wear.png",
		sort=FOX_TAIL,
		budget=FOX_BUDGET,
		pieces=dict(
			EarL=dict(part="TigerEarL", kind="horn", at=(0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			EarR=dict(part="TigerEarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			Tail=dict(part="TigerTail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=2.6, lift=0, sink=True),
		),
		body=(1, 0.55, 0.15, 1),
	),
	"WitchCat": dict(
		folder="witch_cat",
		glb="fox_tail.glb",
		out="WitchCatWear",
		texture="witch_cat_wear.png",
		sort=FOX_TAIL,
		budget=FOX_BUDGET,
		pieces=dict(
			EarL=dict(part="CatEarL", kind="horn", at=(0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			EarR=dict(part="CatEarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			Tail=dict(part="CatTail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=2.6, lift=0, sink=True),
		),
		body=(0.6, 0.35, 0.8, 1),
	),
	"CreamsicleFox": dict(
		folder="creamsicle_fox",
		glb="fox_tail.glb",
		out="CreamsicleFoxWear",
		texture="creamsicle_fox_wear.png",
		sort=FOX_TAIL,
		budget=FOX_BUDGET,
		pieces=dict(
			EarL=dict(part="FoxEarL", kind="horn", at=(0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			EarR=dict(part="FoxEarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=1.5, tilt_out=32, tilt_back=0,
				level=False, foot="low"),
			Tail=dict(part="FoxTail", kind="tail", base="-x", at=(0.0, 0.45, 0.2), scale=2.6, lift=0, sink=True),
		),
		body=(1, 0.75, 0.4, 1),
	),
	# Coral Axolotl (secret-orange-pink), 2026-11-11: the painting's feathery gill fronds fanning out from the upper
	# sides past the outline, small leaves low at their foot. From DEMON_WINGS: each gill pair kept as the file shapes it
	# (seen from the front as the painting draws them), the file's piece of the same side
	"CoralAxolotl": dict(
		folder="coral_axolotl",
		glb="demon_wings.glb",
		out="CoralAxolotlWear",
		texture="coral_axolotl_wear.png",
		sort=DEMON_WINGS,
		budget=DEMON_BUDGET,
		pieces=dict(
			# (the root just inside the skin at the upper side, the lower frond reaching out and a little up, the upper
			# one rising out of it; turned a little back so they show from the side too)
			GillL=dict(part="GillL", kind="aim", root="-x", at=(0.37, 0.08, 0.68), scale=1.4, point=(1, 0.3, 0.3),
				face=(0.3, -1, 0)),
			GillR=dict(part="GillR", kind="aim", root="+x", at=(-0.37, 0.08, 0.68), scale=1.4, point=(1, 0.3, 0.3),
				face=(0.3, -1, 0)),
			# (a leaf tucked under each gill's root, reaching out and down)
			LeafL=dict(part="LeafL", kind="aim", root="-x", at=(0.42, 0.04, 0.6), scale=1.4, point=(0.9, 0.0, -0.45),
				face=(0.2, -1, 0.2)),
			LeafR=dict(part="LeafR", kind="aim", root="+x", at=(-0.42, 0.04, 0.6), scale=1.4, point=(0.9, 0.0, -0.45),
				face=(0.2, -1, 0.2)),
		),
		body=(1, 0.5, 0.4, 1),
	),
	# Fire Dragon (secret-orange-red), 2026-11-11: the painting's big ribbed horns on the top corners curving out and up,
	# small horns on the shoulders below and outside them, small bat wings spread level at the sides. From DEMON_WINGS;
	# the bat wings came bitten through between two fingers: mended to a whole scalloped membrane (`scallop`)
	"FireDragon": dict(
		folder="fire_dragon",
		glb="demon_wings.glb",
		out="FireDragonWear",
		texture="fire_dragon_wear.png",
		sort=DEMON_WINGS,
		budget=DEMON_BUDGET,
		# (the wing's finger tips along its trailing edge in the file's front view: the leading edge's tip, the second and
		# third fingers' tips, the inner corner by the body, the wrist. The file's WingR is bitten between the second and
		# third fingers: filled out to an arc as deep as its whole neighbours'. The file's WingL is bitten twice, once
		# under the wrist where it meets the body; mended it kept a straight wall there and a loose strip of its inner
		# edge, so WingR is worn on both sides)
		scallop=dict(
			BatR=dict(tips=[(0.45, 0.229), (0.385, 0.085), (0.268, 0.027), (0.132, 0.004), (0.178, 0.226)],
				sag=[None, 0.15, None, None]),
		),
		pieces=dict(
			# (the file has them upright, bulging out with the tip up: they keep its turn)
			HornL=dict(part="HornL", kind="horn", at=(0.27, 0.04, 0.74), scale=1.05, tilt_out=0, tilt_back=0, level=False,
				spread=60),
			HornR=dict(part="HornR", kind="horn", at=(-0.27, 0.04, 0.74), scale=1.05, tilt_out=0, tilt_back=0, level=False,
				spread=60),
			# (the painting's small horns on the shoulders, in front of the wing roots, pointing up and out)
			SpikeL=dict(part="SpikeL", kind="horn", at=(0.36, -0.08, 0.63), scale=0.95, tilt_out=35, tilt_back=0, spin=180),
			SpikeR=dict(part="SpikeR", kind="horn", at=(-0.36, -0.08, 0.63), scale=0.95, tilt_out=35, tilt_back=0,
				spin=180),
			WingR=dict(part="BatR", kind="wing", root="-x", at=(-0.41, 0.14, 0.58), scale=1.05, raise_=5, sweep=15,
				twin="WingL"),
		),
		body=(0.9, 0.25, 0.08, 1),
	),
	# Autumn Fox (secret-green-orange), 2026-11-11: fox ears of autumn leaves at the top corners (FANTASY_ICONS). The
	# file tilts them toward each other, open toward each other: stood up (`pre`) and turned open to the front (`spin`),
	# then worn as Sunshower Fox wears its ears (the owner's standard); he fine-tunes them by hand
	"AutumnFox": dict(
		folder="autumn_fox",
		glb="fantasy_icons.glb",
		out="AutumnFoxWear",
		texture="autumn_fox_wear.png",
		sort=FANTASY_ICONS,
		budget=FANTASY_ICONS_BUDGET,
		pieces=dict(
			EarL=dict(part="FoxEarB", kind="horn", at=(0.34, 0.0, 0.7), scale=1.45, tilt_out=32, tilt_back=0, level=False,
				foot="low", pre=(("Y", 32),)),
			EarR=dict(part="FoxEarA", kind="horn", at=(-0.34, 0.0, 0.7), scale=1.45, tilt_out=32, tilt_back=0, level=False,
				foot="low", pre=(("Y", -32),)),
		),
		body=(0.55, 0.6, 0.15, 1),
	),
	# Holly Deer (secret-green-red), 2026-11-11: the painting's antlers standing up from the top corners, holly leaves and
	# red berries at their foot (FANTASY_ICONS; the antler whose big holly leaf reaches +X on the slime's left)
	"HollyDeer": dict(
		folder="holly_deer",
		glb="fantasy_icons.glb",
		out="HollyDeerWear",
		texture="holly_deer_wear.png",
		sort=FANTASY_ICONS,
		budget=FANTASY_ICONS_BUDGET,
		pieces=dict(
			AntlerL=dict(part="AntlerL", kind="horn", at=(0.26, 0.02, 0.76), scale=1.8, tilt_out=12, tilt_back=0,
				level=False, foot="low"),
			AntlerR=dict(part="AntlerR", kind="horn", at=(-0.26, 0.02, 0.76), scale=1.8, tilt_out=12, tilt_back=0,
				level=False, foot="low"),
		),
		body=(0.35, 0.6, 0.12, 1),
	),
	# Deep-Sea Leviathan (secret-navy-navy), 2026-11-11: the painting's fins on both sides standing out past the outline,
	# and an angler fish's lure rising from the top of the head on the slime's left, arching out with its glowing bulb
	# hanging (FANTASY_ICONS; the file's fins and lure seen from the front as the painting draws them)
	"DeepSeaLeviathan": dict(
		folder="deep_sea_leviathan",
		glb="fantasy_icons.glb",
		out="DeepSeaLeviathanWear",
		texture="deep_sea_leviathan_wear.png",
		sort=FANTASY_ICONS,
		budget=FANTASY_ICONS_BUDGET,
		pieces=dict(
			FinL=dict(part="FinL", kind="aim", root="-x", at=(0.49, 0.08, 0.33), scale=1.4, point=(0.6, 0.6, 0.53),
				face=(0.71, -0.71, 0)),
			FinR=dict(part="FinR", kind="aim", root="+x", at=(-0.49, 0.08, 0.33), scale=1.4, point=(0.6, 0.6, 0.53),
				face=(0.71, -0.71, 0)),
			Lure=dict(part="Lure", kind="horn", at=(0.08, -0.22, 0.8), scale=1.3, tilt_out=0, tilt_back=0, level=False,
				foot="low", spin=-20),
		),
		body=(0.05, 0.1, 0.35, 1),
	),
	# Snow Rabbit (secret-white-white), 2026-11-11: the painting's tall white ears at the top corners leaning out a
	# little, and a white cotton tail low on the back (BUNNY_EARS; the file lays the ears on their backs: stood up by
	# `pre`)
	"SnowRabbit": dict(
		folder="snow_rabbit",
		glb="bunny_ears.glb",
		out="SnowRabbitWear",
		texture="snow_rabbit_wear.png",
		sort=BUNNY_EARS,
		budget=BUNNY_BUDGET,
		pieces=dict(
			EarL=dict(part="WEarL", kind="horn", at=(0.34, 0.0, 0.7), scale=1.3, tilt_out=20, tilt_back=0, level=False,
				foot="low", pre=(("X", 64), ("Y", -32))),
			EarR=dict(part="WEarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=1.3, tilt_out=20, tilt_back=0, level=False,
				foot="low", pre=(("X", 64), ("Y", 33))),
			Tail=dict(part="TailW", kind="rigid", at=(180, 0.22), scale=0.7),
		),
		body=(0.88, 0.9, 1, 1),
	),
	# Sakura Bunny (secret-pink-white), 2026-11-11: no painting; worn as Snow Rabbit: the pink ears rise from the top
	# corners and flop over to hang at the sides, a pink cotton tail low on the back (BUNNY_EARS)
	"SakuraBunny": dict(
		folder="sakura_bunny",
		glb="bunny_ears.glb",
		out="SakuraBunnyWear",
		texture="sakura_bunny_wear.png",
		sort=BUNNY_EARS,
		budget=BUNNY_BUDGET,
		pieces=dict(
			EarL=dict(part="PEarL", kind="horn", at=(0.34, 0.0, 0.7), scale=1.35, tilt_out=10, tilt_back=0, level=False,
				foot="low"),
			EarR=dict(part="PEarR", kind="horn", at=(-0.34, 0.0, 0.7), scale=1.35, tilt_out=10, tilt_back=0, level=False,
				foot="low"),
			Tail=dict(part="TailP", kind="rigid", at=(180, 0.22), scale=0.7),
		),
		body=(1, 0.8, 0.88, 1),
	),
	# Rose Dragon (secret-red-red), 2026-11-11: the painting's red horns on the top corners curling up, roses at their
	# foot, red bat wings spread from the upper sides behind them (FANTASY_WINGS_B). Placed roughly: the owner fine-tunes
	"RoseDragon": dict(
		folder="rose_dragon",
		glb="fantasy_wings_b.glb",
		out="RoseDragonWear",
		texture="rose_dragon_wear.png",
		sort=FANTASY_WINGS_B,
		budget=FANTASY_WINGS_B_BUDGET,
		pieces=dict(
			HornL=dict(part="RedHornL", kind="horn", at=(0.26, 0.04, 0.74), scale=1.4, tilt_out=8, tilt_back=0, level=False),
			HornR=dict(part="RedHornR", kind="horn", at=(-0.26, 0.04, 0.74), scale=1.4, tilt_out=8, tilt_back=0, level=False),
			WingL=dict(part="BatL", kind="wing", at=(0.33, 0.28, 0.58), scale=1.75, raise_=20, sweep=20),
			WingR=dict(part="BatR", kind="wing", root="-x", at=(-0.33, 0.28, 0.58), scale=1.75, raise_=20, sweep=20),
		),
		body=(0.75, 0.05, 0.1, 1),
	),
	# Star Owl (secret-navy-yellow), 2026-11-11: starry navy feathered wings, worn as every bird's wing pair (Midnight
	# Raven's pose). The painting's crest on the top is not in the file
	"StarOwl": dict(
		folder="star_owl",
		glb="fantasy_wings_b.glb",
		out="StarOwlWear",
		texture="star_owl_wear.png",
		sort=FANTASY_WINGS_B,
		budget=FANTASY_WINGS_B_BUDGET,
		pieces=dict(
			WingL=dict(part="StarWingL", kind="aim", root="+x", at=(0.17, 0.45, 0.53), scale=2.6, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
			WingR=dict(part="StarWingR", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=2.6, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
		),
		body=(0.08, 0.12, 0.4, 1),
	),
	# Thunder Ram (secret-gray-yellow), 2026-11-11: the painting's big ribbed ram horns on the top corners, curling out
	# and down; the file's golden swirl of cloud (the painting's cloud markings) worn as a fluffy tail low on the back
	"ThunderRam": dict(
		folder="thunder_ram",
		glb="fantasy_wings_b.glb",
		out="ThunderRamWear",
		texture="thunder_ram_wear.png",
		sort=FANTASY_WINGS_B,
		budget=FANTASY_WINGS_B_BUDGET,
		pieces=dict(
			# (the file's two horns differ, the right one curled tighter and set further out: the left worn on both sides)
			HornL=dict(part="RamHornL", kind="horn", at=(0.31, 0.02, 0.7), scale=1.85, tilt_out=10, tilt_back=0, level=False,
				twin="HornR"),
			Tail=dict(part="Cloud", kind="rigid", at=(180, 0.26), scale=1.0),
		),
		body=(1, 0.8, 0.1, 1),
	),
	# Thunderbird (secret-blue-yellow), 2026-11-11: golden feathered wings with blue inner feathers, worn as every bird's
	# wing pair (Midnight Raven's pose). The painting's crest on the top is not in the file
	"Thunderbird": dict(
		folder="thunderbird",
		glb="golden_wing.glb",
		out="ThunderbirdWear",
		texture="thunderbird_wear.png",
		sort=GOLDEN_WING,
		budget=GOLDEN_WING_BUDGET,
		pieces=dict(
			WingL=dict(part="GoldWingL", kind="aim", root="+x", at=(0.17, 0.45, 0.53), scale=1.85, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
			WingR=dict(part="GoldWingR", kind="aim", root="-x", at=(-0.17, 0.45, 0.53), scale=1.85, point=(0.95, 0.2, 0.33),
				face=(0, 1, 0.2)),
		),
		body=(0.2, 0.55, 1, 1),
	),
	# Watermelon Frog (secret-green-pink), 2026-11-11: the painting's frog feet at the foot on both sides, toes out
	"WatermelonFrog": dict(
		folder="watermelon_frog",
		glb="golden_wing.glb",
		out="WatermelonFrogWear",
		texture="watermelon_frog_wear.png",
		sort=GOLDEN_WING,
		budget=GOLDEN_WING_BUDGET,
		pieces=dict(
			FootL=dict(part="FootWL", kind="rigid", at=(60, 0.08), scale=1.0),
			FootR=dict(part="FootWR", kind="rigid", at=(-60, 0.08), scale=1.0),
		),
		body=(0.35, 0.65, 0.2, 1),
	),
	# Poison Frog (secret-green-purple), 2026-11-11: the painting's frog feet at the foot on both sides, toes out. Its eyes
	# on the top are not in the file
	"PoisonFrog": dict(
		folder="poison_frog",
		glb="golden_wing.glb",
		out="PoisonFrogWear",
		texture="poison_frog_wear.png",
		sort=GOLDEN_WING,
		budget=GOLDEN_WING_BUDGET,
		pieces=dict(
			FootL=dict(part="FootPL", kind="rigid", at=(60, 0.08), scale=1.0),
			FootR=dict(part="FootPR", kind="rigid", at=(-60, 0.08), scale=1.0),
		),
		body=(0.5, 0.75, 0.1, 1),
	),
}
TEXTURE = 1024

# the body's radius every 0.05 of its height (Shared/SlimeShape PROFILE)
PROFILE = [0.1164, 0.3466, 0.4251, 0.4704, 0.4995, 0.5171, 0.5258, 0.5269, 0.5221, 0.5131, 0.4997, 0.4811, 0.4568,
	0.4248, 0.3822, 0.3253, 0.2417, 0.1508, 0.0997, 0.0671, 0.0]

KIT = KITS[sys.argv[sys.argv.index("--") + 1]]
ROOT = os.path.join(ART, KIT["folder"])
REVIEW = os.path.join(ROOT, "review")
os.makedirs(REVIEW, exist_ok=True)


def rad(d):
	return math.radians(d)


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT, KIT["glb"]))
src = [o for o in bpy.data.objects if o.type == "MESH"][0]
for o in bpy.data.objects:
	if o is not src and o.type != "MESH":
		bpy.data.objects.remove(o)
bpy.context.view_layer.objects.active = src
src.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# weld the seams, split into loose bits, and sort them into the file's parts
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
groups = {key: [] for key in KIT["budget"]}
for o in [o for o in bpy.data.objects if o.type == "MESH"]:
	c = sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
	groups[KIT["sort"](c)].append(o)
parts = {}
for key, objs in groups.items():
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	if len(objs) > 1:
		bpy.ops.object.join()
	ob = bpy.context.view_layer.objects.active
	ob.name = key
	ob.data.calc_loop_triangles()
	print(f"PIECE {key} parts={len(objs)} tris={len(ob.data.loop_triangles)}")
	parts[key] = ob


def anchor_of(ob, axis, high):
	# the middle of the 6 % of vertices at one end along an axis (where the piece meets the body)
	vs = [v.co.copy() for v in ob.data.vertices]
	vals = sorted(getattr(v, axis) for v in vs)
	lo, hi = vals[0], vals[-1]
	cut = hi - (hi - lo) * 0.06 if high else lo + (hi - lo) * 0.06
	end = [v for v in vs if (getattr(v, axis) >= cut if high else getattr(v, axis) <= cut)]
	return sum(end, Vector()) / len(end)


def decimate(ob, target):
	ob.data.calc_loop_triangles()
	n = len(ob.data.loop_triangles)
	if n > target:
		mod = ob.modifiers.new("Decimate", "DECIMATE")
		mod.ratio = target / n
		mod.use_collapse_triangulate = True
		bpy.context.view_layer.objects.active = ob
		bpy.ops.object.modifier_apply(modifier=mod.name)
	ob.data.calc_loop_triangles()
	return len(ob.data.loop_triangles)


def rebase(ob, anchor):
	# move the geometry so the anchor is at the object's origin
	ob.data.transform(Matrix.Translation(-anchor))
	ob.location = (0, 0, 0)


# the side of a mended hole's tile in the texture, in pixels at the file's size
TILE = 96


def hull2(pts):
	# the convex hull of (x, z) points, counter-clockwise seen from the front
	pts = sorted(set(pts))

	def half(seq):
		out = []
		for p in seq:
			while len(out) >= 2 and ((out[-1][0] - out[-2][0]) * (p[1] - out[-2][1]) - (out[-1][1] - out[-2][1]) * (p[0] - out[-2][0])) <= 0:
				out.pop()
			out.append(p)
		return out[:-1]

	return half(pts) + half(reversed(pts))


def simplify(loop, eps):
	# a closed outline with the points that stray less than `eps` from the line through their neighbours left out
	# (Douglas-Peucker on each half, split at the point farthest from the first)
	import numpy as np
	p = np.array(loop)

	def rdp(a):
		if len(a) < 3:
			return list(range(len(a)))
		d = a[-1] - a[0]
		n = np.hypot(*d)
		dist = np.abs(d[0] * (a[:, 1] - a[0, 1]) - d[1] * (a[:, 0] - a[0, 0])) / n if n > 1e-12 else np.hypot(*(a - a[0]).T)
		k = int(np.argmax(dist))
		if dist[k] <= eps:
			return [0, len(a) - 1]
		left, right = rdp(a[:k + 1]), rdp(a[k:])
		return left[:-1] + [k + i for i in right]

	far = int(np.argmax(np.hypot(*(p - p[0]).T)))
	first = rdp(p[:far + 1])
	second = rdp(np.concatenate([p[far:], p[:1]]))
	keep = first[:-1] + [far + i for i in second[:-1]]
	return [tuple(p[i]) for i in keep]


def mend(ob, name, margin=0.035, inset=0.05, used=None, scallop=None):
	# fill the holes torn through a thin piece the file lays flat in its XZ plane (a bat wing's membrane): where its
	# outline seen from the front closes round empty ground, a thin patch is laid over the hole, wider than it by
	# `margin` of the piece's size, its two faces `inset` of the membrane's thickness under the membrane's front and
	# back, so its edge hides inside the membrane. Each face of the patch wears a tile of its own in the texture: the
	# membrane round the hole as the file paints it, the hole blended smoothly in from it (one flat colour showed as a
	# sticker; the file's own texture over a hole is pale). The tiles go where none of the kit's `used` parts shows the
	# texture.
	# `scallop` = dict(tips=[(x, z), ...], sag=[...]): a membrane bitten out of its EDGE (Fire Dragon's bat wings: the
	# owner wants a whole membrane, each scallop between two finger tips a smooth inward curve). `tips` are the finger
	# tips (and the wrist) along the trailing edge in the file's front view, each snapped to the nearest corner of the
	# outline's hull; between tips k and k+1 the edge is a circular arc bowed in by `sag[k]` of the chord (None: that
	# scallop is whole, left as the file draws it). Empty ground inside the hull that a bitten scallop's chord opens onto
	# is filled out to its arc, and every hole as above; the patch keeps the shape of what it fills (not its hull), and
	# off the membrane its depth follows the plane of the membrane round it
	import numpy as np
	from collections import deque
	from mathutils.geometry import barycentric_transform

	me = ob.data
	me.calc_loop_triangles()
	uv = me.uv_layers.active.data
	tris = [(t, [me.vertices[i].co.copy() for i in t.vertices]) for t in me.loop_triangles]
	xs = [v.co.x for v in me.vertices]
	zs = [v.co.z for v in me.vertices]
	size = max(max(xs) - min(xs), max(zs) - min(zs))
	cell = size / 240
	x0, z0 = min(xs) - 3 * cell, min(zs) - 3 * cell
	w, h = int((max(xs) - x0) / cell) + 4, int((max(zs) - z0) / cell) + 4
	gx, gz = np.meshgrid(x0 + (np.arange(w) + 0.5) * cell, z0 + (np.arange(h) + 0.5) * cell)
	cover = np.zeros((h, w), bool)
	for _, (a, b, c) in tris:
		# (the cells whose middles lie in the triangle, seen from the front)
		d = (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
		if abs(d) < 1e-12:
			continue
		l1 = ((b.z - c.z) * (gx - c.x) + (c.x - b.x) * (gz - c.z)) / d
		l2 = ((c.z - a.z) * (gx - c.x) + (a.x - c.x) * (gz - c.z)) / d
		cover |= (l1 >= -0.01) & (l2 >= -0.01) & (1 - l1 - l2 >= -0.01)
	# the open ground reached from the edge of the grid is outside; open ground left over is a hole
	seen = np.zeros((h, w), bool)

	def flood(start, keep):
		region, todo = [], deque([start])
		seen[start] = True
		while todo:
			j, i = todo.popleft()
			region.append((j, i))
			for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				q = (j + dj, i + di)
				if 0 <= q[0] < h and 0 <= q[1] < w and not seen[q] and keep(q):
					seen[q] = True
					todo.append(q)
		return region

	flood((0, 0), lambda q: not cover[q])
	holes = [flood((j, i), lambda q: not cover[q]) for j in range(h) for i in range(w) if not cover[j, i] and not seen[j, i]]
	holes = [r for r in holes if len(r) >= 20]
	outside_ground = seen.copy()

	def near_(m):
		# (the cells next to a mask, without wrapping round the grid's edges)
		p = np.pad(m, 1)
		return p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]

	if scallop:
		# the hull of the membrane seen from the front, and the bites that a bitten scallop's chord opens onto
		hull = hull2([(float(x), float(z)) for x, z in zip(gx[cover], gz[cover])])
		hx = np.array([p[0] for p in hull])
		hz = np.array([p[1] for p in hull])
		inhull = np.ones((h, w), bool)
		for k in range(len(hull)):
			a, b = hull[k], hull[(k + 1) % len(hull)]
			inhull &= (b[0] - a[0]) * (gz - a[1]) - (b[1] - a[1]) * (gx - a[0]) >= -1e-9
		tips = []
		for x, z in scallop["tips"]:
			k = int(np.argmin(np.hypot(hx - x, hz - z)))
			tips.append(Vector((hx[k], 0, hz[k])))
		mid = Vector((float(gx[cover].mean()), 0, float(gz[cover].mean())))
		slabs, cuts = [], np.zeros((h, w), bool)
		for k, r in enumerate(scallop["sag"]):
			a, b = tips[k], tips[k + 1]
			chord = (b - a).length
			u = (b - a) / chord
			n = Vector((-u.z, 0, u.x))
			if n.dot(mid - a) < 0:
				n = -n
			t = (gx - a.x) * u.x + (gz - a.z) * u.z
			s = (gx - a.x) * n.x + (gz - a.z) * n.z
			slab = (t >= 0) & (t <= chord) & (s >= -2 * cell)
			slabs.append((slab, s, chord))
			if r:
				sag = r * chord
				big = (chord * chord / 4 + sag * sag) / (2 * sag)
				c = a + u * (chord / 2) + n * (sag - big)
				cuts |= slab & (np.hypot(gx - c.x, gz - c.z) < big)
		# the bites: open ground inside the hull, reached from outside, each bit apart (the hull's own rim left out, so
		# two scallops either side of a finger tip stay apart)
		ground = inhull & ~near_(~inhull) & ~cover & outside_ground
		rim = near_(near_(near_(near_(~inhull))))
		labelled = np.zeros((h, w), bool)
		bites = []
		for j, i in zip(*np.nonzero(ground)):
			if labelled[j, i]:
				continue
			region, todo = [], deque([(j, i)])
			labelled[j, i] = True
			while todo:
				q = todo.popleft()
				region.append(q)
				for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
					p = (q[0] + dj, q[1] + di)
					if 0 <= p[0] < h and 0 <= p[1] < w and ground[p] and not labelled[p]:
						labelled[p] = True
						todo.append(p)
			if len(region) < 20:
				continue
			rj, ri = np.array(region).T
			# (which scallop it opens onto: where its mouth meets the hull's rim; deep inside, the slabs overlap)
			mouth = rim[rj, ri]
			mj, mi = (rj[mouth], ri[mouth]) if mouth.any() else (rj, ri)
			hits = [int(slab[mj, mi].sum()) for slab, _, _ in slabs]
			k = int(np.argmax(hits))
			if not hits[k]:
				continue
			deep = float(slabs[k][1][rj, ri].max()) / slabs[k][2]
			mask = np.zeros((h, w), bool)
			mask[rj, ri] = True
			if scallop["sag"][k]:
				mask &= ~cuts
			# (a sliver a cell or two wide along an arc is left out)
			core = mask & ~near_(~mask)
			core = core & ~near_(~core)
			mask &= near_(near_(core)) | core
			print(f"SCALLOP {name} bite of {len(region)} cells between tips {k} and {k + 1}, {deep:.2f} of the chord deep, "
				f"{'filled ' + str(int(mask.sum())) + ' cells' if scallop['sag'][k] else 'whole, kept'}")
			if scallop["sag"][k]:
				# (each piece of it apart: the arc may cut it in two)
				left = mask.copy()
				for j0, i0 in zip(*np.nonzero(mask)):
					if not left[j0, i0]:
						continue
					piece, todo = [], deque([(j0, i0)])
					left[j0, i0] = False
					while todo:
						q = todo.popleft()
						piece.append(q)
						for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
							p = (q[0] + dj, q[1] + di)
							if 0 <= p[0] < h and 0 <= p[1] < w and left[p]:
								left[p] = False
								todo.append(p)
					if len(piece) >= 20:
						bites.append([(int(a), int(b)) for a, b in piece])
		print(f"SCALLOP {name} tips {[tuple(round(c, 3) for c in (p.x, p.z)) for p in tips]}")

	def under(x, z, facing):
		# the membrane's front (facing -1) or back (+1) at a point: its depth
		best = None
		for t, (a, b, c) in tris:
			if t.normal.y * facing <= 0.2:
				continue
			p = barycentric_transform(Vector((x, 0, z)), Vector((a.x, 0, a.z)), Vector((b.x, 0, b.z)), Vector((c.x, 0, c.z)),
				Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))
			miss = max(-p.x, -p.y, -p.z, 0.0)
			if best is None or miss < best[0]:
				best = (miss, p, t)
		_, p, t = best
		return p.x * me.vertices[t.vertices[0]].co.y + p.y * me.vertices[t.vertices[1]].co.y + p.z * me.vertices[t.vertices[2]].co.y

	img = [i for i in bpy.data.images if i.size[0] > 0][0]
	iw, ih = img.size
	px = np.empty(iw * ih * 4, np.float32)
	img.pixels.foreach_get(px)
	px = px.reshape(ih, iw, 4)

	def raster(mask, uvs):
		# mark the texture's pixels whose middles lie in a triangle of UVs
		(ax, ay), (bx, by), (cx, cy) = [(u.x * iw - 0.5, u.y * ih - 0.5) for u in uvs]
		d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
		i0, i1 = max(int(min(ax, bx, cx)), 0), min(int(max(ax, bx, cx)) + 2, iw)
		j0, j1 = max(int(min(ay, by, cy)), 0), min(int(max(ay, by, cy)) + 2, ih)
		if abs(d) < 1e-9 or i0 >= i1 or j0 >= j1:
			return
		gi, gj = np.meshgrid(np.arange(i0, i1), np.arange(j0, j1))
		l1 = ((by - cy) * (gi - cx) + (cx - bx) * (gj - cy)) / d
		l2 = ((cy - ay) * (gi - cx) + (ax - cx) * (gj - cy)) / d
		mask[j0:j1, i0:i1] |= (l1 >= 0) & (l2 >= 0) & (1 - l1 - l2 >= 0)

	def near(m):
		return np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)

	# the pixels the kit's pieces show: a patch's tile goes where none of them shows anything (the file's atlas cuts the
	# membrane into many islands, so the hole has no place of its own in the texture; this kit's texture serves its own
	# pieces only, so the other parts' pixels are free)
	shown = np.zeros((ih, iw), bool)
	for part in used or [ob]:
		part.data.calc_loop_triangles()
		puv = part.data.uv_layers.active.data
		for t in part.data.loop_triangles:
			raster(shown, [puv[i].uv for i in t.loops])

	def tile(hull, facing):
		# a TILE-pixel square of the texture painted as the membrane round the hole (sampled through the faces on that
		# side) with the hole blended smoothly in from it; returns the UV of a point (x, z) in it
		for j0 in range(4, ih - TILE - 4, 16):
			free = [i0 for i0 in range(4, iw - TILE - 4, 16) if not shown[j0 - 4:j0 + TILE + 4, i0 - 4:i0 + TILE + 4].any()]
			if free:
				break
		i0 = free[0]
		shown[j0 - 4:j0 + TILE + 4, i0 - 4:i0 + TILE + 4] = True
		lo_x, lo_z = min(p[0] for p in hull), min(p[1] for p in hull)
		k = (TILE - 8) / max(max(p[0] for p in hull) - lo_x, max(p[1] for p in hull) - lo_z)
		ii, jj = np.meshgrid(np.arange(TILE), np.arange(TILE))
		gx_, gz_ = lo_x + (ii + 0.5 - 4) / k, lo_z + (jj + 0.5 - 4) / k
		col = np.zeros((TILE, TILE, 3), np.float32)
		known = np.zeros((TILE, TILE), bool)
		for t, (a, b, c) in tris:
			d = (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
			if t.normal.y * facing <= 0.2 or abs(d) < 1e-12:
				continue
			l1 = ((b.z - c.z) * (gx_ - c.x) + (c.x - b.x) * (gz_ - c.z)) / d
			l2 = ((c.z - a.z) * (gx_ - c.x) + (a.x - c.x) * (gz_ - c.z)) / d
			l3 = 1 - l1 - l2
			inside = (l1 >= 0) & (l2 >= 0) & (l3 >= 0) & ~known
			if inside.any():
				ua, ub, uc = [uv[i].uv for i in t.loops]
				pu = np.clip(((l1 * ua.x + l2 * ub.x + l3 * uc.x)[inside] * iw).astype(int), 0, iw - 1)
				pv = np.clip(((l1 * ua.y + l2 * ub.y + l3 * uc.y)[inside] * ih).astype(int), 0, ih - 1)
				col[inside] = px[pv, pu, :3]
				known |= inside
		# (the membrane's last pixels at the hole's edge are pale: left out)
		for _ in range(3):
			known &= ~near(~known)
		gap = ~known
		col[gap] = col[known].mean(axis=0)
		for _ in range(1500):
			col[gap] = ((np.roll(col, 1, 0) + np.roll(col, -1, 0) + np.roll(col, 1, 1) + np.roll(col, -1, 1)) / 4)[gap]
		px[j0:j0 + TILE, i0:i0 + TILE, :3] = col
		return lambda x, z: Vector(((i0 + 4 + (x - lo_x) * k) / iw, (j0 + 4 + (z - lo_z) * k) / ih))

	bm = bmesh.new()
	bm.from_mesh(me)
	layer = bm.loops.layers.uv.active
	added, filled, painted = 0, 0, 0
	for region in holes:
		cells = set(region)
		grow = int(round(margin * size / cell))
		# the hole widened by the margin, as far as the membrane reaches (never out past its outline)
		ring = set(cells)
		for _ in range(grow):
			ring |= {(j + dj, i + di) for j, i in ring for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1))
				if 0 <= j + dj < h and 0 <= i + di < w and (cover[j + dj, i + di] or (j + dj, i + di) in cells)}
		pts = sorted({(float(gx[j, i]), float(gz[j, i])) for j, i in ring})

		def half(seq):
			out = []
			for p in seq:
				while len(out) >= 2 and ((out[-1][0] - out[-2][0]) * (p[1] - out[-2][1]) - (out[-1][1] - out[-2][1]) * (p[0] - out[-2][0])) <= 0:
					out.pop()
				out.append(p)
			return out[:-1]

		# its outline: the hull of the widened hole (counter-clockwise seen from the front), points closer than a few
		# cells merged
		hull = half(pts) + half(reversed(pts))
		hull = [p for k, p in enumerate(hull) if k == 0 or math.dist(p, hull[k - 1]) > 4 * cell]
		for facing in (-1, 1):
			at = tile(hull, facing)
			corners = []
			for x, z in hull:
				yf, yb = under(x, z, -1), under(x, z, 1)
				y = yf + inset * (yb - yf) if facing < 0 else yb - inset * (yb - yf)
				corners.append((bm.verts.new((x, y, z)), at(x, z)))
			if facing > 0:
				corners.reverse()
			face = bm.faces.new([v for v, _ in corners])
			for loop, (_, u) in zip(face.loops, corners):
				loop[layer].uv = u
			painted += 1
			face.normal_update()
			if face.normal.y * facing < 0:
				face.normal_flip()
			added += len(corners) - 2
		filled += len(region)

	def outline(mask):
		# the outer edge of a mask of cells, as a loop of cell corners (j, i) with the mask on its left: counter-clockwise
		# seen from the front (x along i, z along j)
		m = np.pad(mask, 1)
		nxt = {}
		for j, i in zip(*np.nonzero(mask)):
			if not m[j, i + 1]:
				nxt.setdefault((j, i), []).append((j, i + 1))
			if not m[j + 1, i + 2]:
				nxt.setdefault((j, i + 1), []).append((j + 1, i + 1))
			if not m[j + 2, i + 1]:
				nxt.setdefault((j + 1, i + 1), []).append((j + 1, i))
			if not m[j + 1, i]:
				nxt.setdefault((j + 1, i), []).append((j, i))
		loops = []
		while nxt:
			start = min(nxt)
			loop, p = [start], start
			while True:
				q = nxt[p].pop()
				if not nxt[p]:
					del nxt[p]
				if q == start:
					break
				loop.append(q)
				p = q
			loops.append(loop)
		return max(loops, key=len)

	for region in bites if scallop else []:
		cells = set(region)
		grow = int(round(margin * size / cell))
		# the bite widened by the margin into the membrane round it, its own shape kept (an arc's bow is not convex)
		ring = set(cells)
		for _ in range(grow):
			ring |= {(j + dj, i + di) for j, i in ring for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1))
				if 0 <= j + dj < h and 0 <= i + di < w and (cover[j + dj, i + di] or (j + dj, i + di) in cells)}
		mask = np.zeros((h, w), bool)
		mask[tuple(np.array(sorted(ring)).T)] = True
		# (closed by a cell, and any island of membrane inside it taken in, so its edge is one loop)
		mask = mask | near_(mask)
		mask = mask & ~near_(~mask)
		out = np.zeros((h, w), bool)
		todo = deque([(0, 0)])
		out[0, 0] = True
		while todo:
			j, i = todo.popleft()
			for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				q = (j + dj, i + di)
				if 0 <= q[0] < h and 0 <= q[1] < w and not mask[q] and not out[q]:
					out[q] = True
					todo.append(q)
		mask = ~out
		poly = simplify([(x0 + i * cell, z0 + j * cell) for j, i in outline(mask)], 1.5 * cell)

		def on_membrane(x, z):
			# how many of the four cells round a corner the membrane covers
			i, j = int(round((x - x0) / cell)), int(round((z - z0) / cell))
			return sum(bool(cover[jj, ii]) for jj in (j - 1, j) for ii in (i - 1, i) if 0 <= jj < h and 0 <= ii < w)

		# off the membrane, the depth of its two faces follows the plane of the membrane's front and back round the bite
		# (the middles of the faces looking that way within a fifth of the piece's size of the bite's middle; a fit to the
		# outline's own points caught the finger bones and tilted the patch out of the membrane)
		cx = sum(p[0] for p in poly) / len(poly)
		cz = sum(p[1] for p in poly) / len(poly)
		plane = []
		for facing in (-1, 1):
			rows = []
			for t, (a, b, c) in tris:
				m = (a + b + c) / 3
				if t.normal.y * facing > 0.5 and math.hypot(m.x - cx, m.z - cz) < 0.2 * size:
					rows.append((m.x, m.z, 1.0, m.y))
			if len(rows) < 3:
				plane = None
				break
			rows = np.array(rows)
			plane.append(np.linalg.lstsq(rows[:, :3], rows[:, 3], rcond=None)[0])
		for facing in (-1, 1):
			at = tile(poly, facing)
			corners = []
			for x, z in poly:
				if on_membrane(x, z) or plane is None:
					yf, yb = under(x, z, -1), under(x, z, 1)
				else:
					yf, yb = [float(c[0] * x + c[1] * z + c[2]) for c in plane]
				y = yf + inset * (yb - yf) if facing < 0 else yb - inset * (yb - yf)
				corners.append((bm.verts.new((x, y, z)), at(x, z)))
			if facing > 0:
				corners.reverse()
			face = bm.faces.new([v for v, _ in corners])
			for loop, (_, u) in zip(face.loops, corners):
				loop[layer].uv = u
			painted += 1
			face.normal_update()
			if face.normal.y * facing < 0:
				face.normal_flip()
			added += len(corners) - 2
		filled += len(region)
		holes.append(region)
	bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 3])
	bm.to_mesh(me)
	bm.free()
	me.update()
	img.pixels.foreach_set(px.ravel())
	img.update()
	print(f"MEND {name} {len(holes)} holes, {filled * cell * cell:.4f} square units, +{added} triangles, "
		f"{painted} tiles of {TILE} pixels painted")


# (the parts the kit's pieces wear: a mended patch's texture tile goes where none of them shows the texture)
worn = [parts[p] for p in dict.fromkeys(spec["part"] for spec in KIT["pieces"].values())]
for key in KIT.get("mend", ()):
	mend(parts[key], key, used=worn)
for key, spec in KIT.get("scallop", {}).items():
	mend(parts[key], key, used=worn, scallop=spec)
for key, ob in parts.items():
	print(f"KEPT {key} tris={decimate(ob, KIT['budget'][key])}")


def skin_radius(z):
	# the body's radius at a height (0 above its tip)
	if z <= 0:
		return PROFILE[0]
	if z >= 1:
		return 0.0
	f = z / 0.05
	i = min(int(f), len(PROFILE) - 2)
	return PROFILE[i] + (PROFILE[i + 1] - PROFILE[i]) * (f - i)


def outside(p):
	# how far a point stands out of the body, across (negative: inside)
	return math.sqrt(p.x * p.x + p.y * p.y) - skin_radius(p.z)


# the owner, 2026-11-10, twice: a horn's or an ear's foot must not show ("vị trí gốc của 2 cặp sừng còn bị lộ"), yet it
# stands as far out of the body as it can, keeping the detail near its foot ("nằm sát phần ngoài của slime nhiều nhất có
# thể để giữ được các chi tiết gần gốc"): only its foot's rim goes SEAT under the skin, and where the skin falls away
# under the foot (a shoulder's slope) the lowest part of the piece is drawn down onto the skin, never the whole piece
# pushed in
SEAT = 0.02
# a tail's base end is pushed this far under the skin
BURY = 0.03


def sink(ob, base, axis, name):
	# push a placed piece along -axis until every vertex in `base` lies BURY inside the body
	sunk = 0.0
	while max(outside(ob.location + ob.data.vertices[i].co) for i in base) > -BURY and sunk < 0.2:
		ob.location -= axis * 0.005
		sunk += 0.005
	print(f"SINK {name} {sunk:.3f}, base at {tuple(round(c, 3) for c in ob.location)}")


def to_skin(p, axis):
	# how far a point must move down `axis` to lie SEAT under the skin (negative: up); None where no skin lies below
	t = -0.6
	while outside(p - axis * t) > -SEAT:
		t += 0.01
		if t > 0.6:
			return None
	while outside(p - axis * (t - 0.001)) <= -SEAT:
		t -= 0.001
	return t


def seat(ob, foot, axis, band, name):
	# set a placed horn or ear on the skin: move it along `axis` until the vertex of its foot nearest the skin lies SEAT
	# under it, then draw the rest of the foot down onto the skin, and with it what stands above the foot, less the
	# higher it stands, to nothing at `band` (a share of the piece's length)
	vs = ob.data.vertices
	gap = {i: to_skin(ob.location + vs[i].co, axis) for i in foot}
	foot = [i for i in foot if gap[i] is not None]
	lift = min(gap[i] for i in foot)
	ob.location -= axis * lift
	for i in foot:
		gap[i] -= lift
	high = max(v.co.dot(axis) for v in vs) - min(v.co.dot(axis) for v in vs)
	band *= high
	flat = {i: vs[i].co - axis * vs[i].co.dot(axis) for i in foot}
	moved = []
	for v in vs:
		t = to_skin(ob.location + v.co, axis)
		if t is None:
			continue
		# the foot's gap under this point: its nearest foot vertices across the axis, weighted by nearness
		p = v.co - axis * v.co.dot(axis)
		w = {i: math.exp(-((p - flat[i]).length / 0.012) ** 2) for i in foot}
		if sum(w.values()) < 1e-9:
			w = {min(foot, key=lambda i: (p - flat[i]).length): 1.0}
		g = sum(w[i] * gap[i] for i in w) / sum(w.values())
		over = max(0.0, t - g)
		if over < band and g > 0:
			moved.append((v, axis * g * (1 - over / band)))
	for v, d in moved:
		v.co -= d
	# the piece rides the skin from the middle of its foot
	c = sum((vs[i].co for i in foot), Vector()) / len(foot)
	ob.data.transform(Matrix.Translation(-c))
	ob.location += c
	print(f"SEAT {name} lifted {-lift:.3f}, foot gap up to {max(gap[i] for i in foot):.3f}, {len(moved)} vertices drawn down, anchor {tuple(round(x, 3) for x in ob.location)}")


def base_plane(me, spread=40, step=2, tol=0.02):
	# the plane a piece's flat bottom (a sole, or the lip of a hollow cup) rests on: of the directions within `spread`
	# degrees of straight down, the one whose lowest plane touches the most vertices (within `tol` of the piece's
	# height); returns that direction and those vertices
	vs = [v.co for v in me.vertices]
	tol *= max(v.z for v in vs) - min(v.z for v in vs)
	best = None
	for a in range(0, spread + 1, step):
		for b in range(0, 360, step * 4 if a else 360):
			n = Vector((math.sin(rad(a)) * math.cos(rad(b)), math.sin(rad(a)) * math.sin(rad(b)), -math.cos(rad(a))))
			d = [v.dot(n) for v in vs]
			low = max(d)
			near = [i for i, x in enumerate(d) if x > low - tol]
			if not best or len(near) > len(best[1]):
				best = (n, near)
	return best


def place_horn(ob, spec, name):
	# a horn or an ear. Its foot: the flat sole (or a hollow cup's lip) of a horn, the lowest tenth of an ear's soft fur
	# (`foot="low"`). A horn's sole is cut at a slant in the file: turn it level (`level`) so the horn grows straight out
	# of it, or keep the horn as the file stands it (upright already). A horn's tip curls toward -X in the file: turn it
	# to curl back (+Y), out or in (`curl`); then lean it out to its side and back, and seat it on the body
	side = 1 if spec["at"][0] >= 0 else -1
	vs = ob.data.vertices
	# `pre` = ((axis, degrees), ...): turns applied to the file's piece first, for a piece the file lays down or tilts
	# (the bunny file's ears lie on their backs): stood up, its foot is found as usual
	for ax, deg in spec.get("pre", ()):
		ob.data.transform(Matrix.Rotation(rad(deg), 4, ax))
	if spec.get("foot", "plane") == "plane":
		down, foot = base_plane(ob.data, spec.get("spread", 40))
	else:
		zs = sorted(v.co.z for v in vs)
		down, foot = Vector((0, 0, -1)), [v.index for v in vs if v.co.z <= zs[0] + (zs[-1] - zs[0]) * 0.1]
	if not spec.get("level", True):
		down = Vector((0, 0, -1))
	rebase(ob, sum((vs[i].co for i in foot), Vector()) / len(foot))
	ob.data.transform(down.rotation_difference(Vector((0, 0, -1))).to_matrix().to_4x4())
	print(f"HORN {name} foot vertices={len(foot)} of {len(vs)}, levelled by {math.degrees(down.angle(Vector((0, 0, -1)))):.1f} degrees")
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	curl = spec.get("curl")
	spin = spec.get("spin", {"back": -90, "out": 180 if side > 0 else 0, "in": 0 if side > 0 else 180}.get(curl, 0))
	ob.data.transform(Matrix.Rotation(rad(spin), 4, "Z"))
	turn = Matrix.Rotation(rad(side * spec["tilt_out"]), 3, "Y") @ Matrix.Rotation(rad(-spec["tilt_back"]), 3, "X")
	ob.data.transform(turn.to_4x4())
	ob.location = spec["at"]
	axis = turn @ Vector((0, 0, 1))
	seat(ob, foot, axis, spec.get("band", 0.3), name)
	# `deep`: pushed this much further in along the piece, so no sliver of light shows under its foot from any side
	# (the owner, 2026-11-10, of the fox-file ears: "chưa được dính sát vào thân slime. vẫn còn khoảng hở nhỏ")
	ob.location -= axis * spec.get("deep", 0)
	top = max((ob.location + v.co).z for v in vs)
	# the lowest fifth of the piece along its axis: the share of it standing outside the skin (a gap under the foot,
	# which a twitch or a lag opens further as it turns the piece about its anchor)
	low = sorted(vs, key=lambda v: v.co.dot(axis))[: max(1, len(vs) // 5)]
	out = sum(outside(ob.location + v.co) > 0 for v in low)
	print(f"HORN {name} tip at height {top:.3f}, {out} of the lowest {len(low)} vertices outside the skin")


def place_wing(ob, spec):
	# root = the end at +X in the file, spreading toward -X (the file's left wing, as the file is seen from its front):
	# turn it to spread toward the slime's left (+X) with its painted side to the back. With `root="-x"` (the file's
	# right wing of a pair) it spreads to the slime's right the same way. Then raise the tip, sweep it back; returns the
	# flap axis
	side = -1 if spec.get("root") == "-x" else 1
	rebase(ob, anchor_of(ob, "x", side > 0))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	ob.data.transform(Matrix.Rotation(rad(180), 4, "Z"))
	ob.data.transform(Matrix.Rotation(rad(-side * spec["raise_"]), 4, "Y"))
	ob.data.transform(Matrix.Rotation(rad(side * spec["sweep"]), 4, "Z"))
	ob.location = spec["at"]
	sw = rad(spec["sweep"])
	# the hinge runs along the root, front to back after the sweep; a positive turn about it lifts the tip
	axis = Vector((math.sin(sw), -side * math.cos(sw), 0))
	# a check that the flap axis lifts the tip: turn the farthest point by +10 degrees about it
	far = max(ob.data.vertices, key=lambda v: v.co.length).co
	print("FLAP CHECK tip z", round(far.z, 3), "->", round((Matrix.Rotation(rad(10), 3, axis) @ far).z, 3))
	return axis


def place_tail(ob, spec, name):
	# base = the end along X that `base` names, the tip toward the other: turn it to stretch back (+Y), lift the tip
	# (`lift`, degrees up), set it on the body; with `sink`, push it into the body until its base end lies inside
	high = spec["base"] == "+x"
	xs = sorted(v.co.x for v in ob.data.vertices)
	cut = xs[-1] - (xs[-1] - xs[0]) * 0.06 if high else xs[0] + (xs[-1] - xs[0]) * 0.06
	end = [v.index for v in ob.data.vertices if (v.co.x >= cut if high else v.co.x <= cut)]
	rebase(ob, anchor_of(ob, "x", high))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	ob.data.transform(Matrix.Rotation(rad(-90 if high else 90), 4, "Z"))
	ob.data.transform(Matrix.Rotation(rad(spec["lift"]), 4, "X"))
	ob.location = spec["at"]
	if spec.get("sink"):
		sink(ob, end, Matrix.Rotation(rad(spec["lift"]), 3, "X") @ Vector((0, 1, 0)), name)


def meridian():
	# the body's outline from its feet to its top: (height, radius, length along the skin from the feet) every 0.005
	rows, run = [], 0.0
	for k in range(201):
		z = k * 0.005
		r = skin_radius(z)
		if rows:
			run += math.hypot(z - rows[-1][0], r - rows[-1][1])
		rows.append((z, r, run))
	return rows


MERIDIAN = meridian()


def along(run):
	# the height and radius that lie `run` along the skin from the feet
	run = min(max(run, 0.0), MERIDIAN[-1][2])
	for a, b in zip(MERIDIAN, MERIDIAN[1:]):
		if b[2] >= run:
			f = (run - a[2]) / max(b[2] - a[2], 1e-9)
			return a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
	return MERIDIAN[-1][0], MERIDIAN[-1][1]


def rigid_frame(spec, turn, tilt):
	# the turn of a rigid piece (file axes to body axes) and the way it moves in or out, for its `turn` and `tilt`
	phi, t = rad(spec["at"][0]), rad(tilt)
	out = Vector((math.sin(phi), -math.cos(phi), 0))
	z = Vector((0, 0, 1))
	look = out * math.cos(t) + z * math.sin(t)
	up = -out * math.sin(t) + z * math.cos(t)
	if spec.get("lay") == "side":
		frame = Matrix((out, z.cross(out), z)).transposed()
	else:
		frame = Matrix(((-look).cross(up), -look, up)).transposed()
	return frame @ Matrix.Rotation(rad(-turn), 3, "Y"), look


def fit_rigid(ob, spec, name):
	# `fit` = (turns, tilts), each (from, to, step): try every pair and keep the one that lays the most of the piece
	# within 0.03 of the skin once it moves onto it (a long piece that should lie along the body, a mane)
	import numpy as np
	zs = np.arange(len(PROFILE)) * 0.05
	prof = np.array(PROFILE)
	co = np.array([v.co[:] for v in ob.data.vertices]) * spec["scale"]
	phi, height = rad(spec["at"][0]), spec["at"][1]
	r0 = skin_radius(height)
	base = np.array((r0 * math.sin(phi), -r0 * math.cos(phi), height))

	def out_of(p):
		return np.hypot(p[:, 0], p[:, 1]) - np.interp(p[:, 2], zs, prof)

	best = None
	(t0, t1, ts), (l0, l1, ls) = spec["fit"]
	for turn in range(t0, t1 + 1, ts):
		for tilt in range(l0, l1 + 1, ls):
			m, look = rigid_frame(spec, turn, tilt)
			p = co @ np.array(m).T
			lk = np.array(look[:])
			near, far = -0.6, 1.0
			for _ in range(30):
				mid = (near + far) / 2
				if -np.quantile(out_of(p + base + lk * mid), spec.get("tuck", 0)) > SEAT:
					near = mid
				else:
					far = mid
			q = p + base + lk * far
			# `reach` = (lowest, highest): its lowest point must come down to `lowest`, its top stay under `highest`
			low, top = spec.get("reach", (9, 9))
			if q[:, 2].min() > low or q[:, 2].max() > top:
				continue
			touch = int((out_of(q) < 0.03).sum())
			if not best or touch > best[0]:
				best = (touch, turn, tilt)
	print(f"FIT {name} turn {best[1]}, tilt {best[2]}: {best[0]} of {len(co)} vertices within 0.03 of the skin")
	return dict(spec, turn=best[1], tilt=best[2])


def place_rigid(ob, spec, name):
	# a piece worn exactly as the file shapes it (the owner, 2026-11-10, of flowers and leaves bent onto the skin by
	# `wrap` and `front`: "lưới của hoa và lá ... biến dạng", "hãy cố gắng giữ nguyên mesh ... không cần phải kéo để nó ôm
	# sát thân"): only scaled, turned and moved, never bent. Its front (-Y in the file) looks out from the body at `at` =
	# (degrees around from the front, + toward the slime's left; height), leaned back by `tilt` degrees (its front
	# looking up, its top lying back over the head); `turn` degrees in its own plane, `flip` mirrors it. Then it moves in
	# or out along that look until its deepest point lies SEAT under the skin: it touches the body there and keeps its
	# shape, standing off the curve elsewhere
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	rebase(ob, (lo + hi) / 2)
	# `squash` scales the file's own axes (the owner, of a mane too wide: "có thể bóp hơi dẹp lại")
	ob.data.transform(Matrix.Diagonal((*spec.get("squash", (1, 1, 1)), 1)))
	# `shear` slides the file's X by its height (a mane whose locks fall back stood upright), still straight lines
	ob.data.transform(Matrix.Shear("XY", 4, (spec.get("shear", 0), 0)))
	if spec.get("fit"):
		spec = fit_rigid(ob, spec, name)
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	if spec.get("flip"):
		ob.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
		ob.data.flip_normals()
	# `lay="side"`: a piece that runs over the body seen from its side (a mane): the file's X runs along `out`, its Z
	# stays up, its front looks to the side; `turn` pitches it, and it moves along `look` all the same
	frame, look = rigid_frame(spec, spec.get("turn", 0), spec.get("tilt", 0))
	ob.data.transform(frame.to_4x4())
	phi, height = rad(spec["at"][0]), spec["at"][1]
	r0 = skin_radius(height)
	base = Vector((r0 * math.sin(phi), -r0 * math.cos(phi), height))

	# `tuck`: the share of the piece let in deeper than SEAT (a mane's stray locks, hidden in the jelly)
	rank = int(spec.get("tuck", 0) * len(vs))

	def depth(d):
		return sorted((-outside(base + look * d + v.co) for v in vs), reverse=True)[rank]

	near, far = -0.6, 1.0
	for _ in range(40):
		mid = (near + far) / 2
		if depth(mid) > SEAT:
			near = mid
		else:
			far = mid
	at = base + look * far
	deep = sorted(vs, key=lambda v: outside(at + v.co))[rank].co + at
	across = math.hypot(deep.x, deep.y)
	r = skin_radius(deep.z)
	anchor = Vector((deep.x * r / across, deep.y * r / across, deep.z)) if across > 1e-6 else Vector((0, 0, deep.z))
	ob.data.transform(Matrix.Translation(at - anchor))
	ob.location = anchor
	touch = sum(outside(anchor + v.co) < 0.03 for v in vs)
	print(f"RIGID {name} at {spec['at']}, moved {far:+.3f} along its look, {touch} of {len(vs)} vertices within 0.03 of "
		f"the skin, anchor {tuple(round(x, 3) for x in anchor)}")


def place_wrap(ob, spec, name):
	# a flat piece the file lays in its XZ plane with its face to -Y (a vine, a leaf), bent around the body onto its
	# skin: its height runs up the skin, its width around the body, its back face on the skin. `at` = (degrees around
	# the body from the front, positive toward the slime's left; the height of its middle); `turn` degrees in its own
	# plane, positive counter-clockwise as seen from outside; `flip` mirrors it left to right
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	rebase(ob, (lo + hi) / 2)
	ob.data.transform(Matrix.Scale(spec["scale"], 4) @ Matrix.Rotation(rad(-spec.get("turn", 0)), 4, "Y"))
	if spec.get("flip"):
		ob.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
		ob.data.flip_normals()
	back = max(v.co.y for v in vs)
	phi, height = rad(spec["at"][0]), spec["at"][1]
	start = next(row[2] for row in MERIDIAN if row[0] >= height)
	r0 = skin_radius(height)
	anchor = Vector((r0 * math.sin(phi), -r0 * math.cos(phi), height))
	for v in vs:
		z, r = along(start + v.co.z)
		a = phi + v.co.x / max(r, 0.08)
		# (its back face a hair under the skin, so no gap shows)
		out = r + (back - v.co.y) - 0.005
		v.co = Vector((out * math.sin(a), -out * math.cos(a), z)) - anchor
	ob.location = anchor
	print(f"WRAP {name} at {spec['at'][0]} degrees, height {height}, anchor {tuple(round(x, 3) for x in anchor)}")


def onto_skin(p):
	# a point inside the body (or under the ground) moved straight out onto the skin
	p.z = max(p.z, 0.005)
	r, least = math.hypot(p.x, p.y), skin_radius(p.z) + 0.004
	if r < least:
		k = least / max(r, 1e-6)
		p.x, p.y = p.x * k, p.y * k
	return p


def place_frame(ob, spec, name):
	# a flat piece the file lays in its XZ plane with its face to -Y (a vine, a leaf) that grows OUT of the body, as the
	# owner's painting draws vines curling round the outline: stood upright in the plane through the body's middle line
	# at `at` = (degrees around from the front, positive toward the slime's left; the height of its middle; how far its
	# middle stands from the middle line), seen from there as the file is seen from its front (at +-90 degrees, the
	# painting's own view). `yaw` turns its plane about the upright line, its outer end toward the back (degrees), so it
	# also shows from the side. `hug` (0 to 1) bends it so its inner edge follows the body's outline up and down;
	# whatever then lies inside the body is laid on the skin. `turn` and `flip` as for a wrap
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	rebase(ob, (lo + hi) / 2)
	ob.data.transform(Matrix.Scale(spec["scale"], 4) @ Matrix.Rotation(rad(-spec.get("turn", 0)), 4, "Y"))
	if spec.get("flip"):
		ob.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
		ob.data.flip_normals()
	deg, height, reach = spec["at"]
	phi, s, hug = rad(deg), (1 if deg >= 0 else -1), spec.get("hug", 0)
	plane = phi + s * rad(spec.get("yaw", 0))
	out = Vector((math.sin(plane), -math.cos(plane), 0))
	depth = Vector((math.cos(plane), math.sin(plane), 0)) * s
	centre = Vector((reach * math.sin(phi), -reach * math.cos(phi), height))
	r0 = skin_radius(height)
	anchor = Vector((r0 * math.sin(phi), -r0 * math.cos(phi), height))
	laid = 0
	for v in vs:
		p = centre + out * (v.co.x * s) + depth * v.co.y + Vector((0, 0, v.co.z))
		p += out * (hug * (skin_radius(p.z) - r0))
		q = onto_skin(p.copy())
		laid += (q - p).length > 1e-6
		v.co = q - anchor
	ob.location = anchor
	print(f"FRAME {name} at {deg} degrees, height {height}, reach {reach}, {laid} of {len(vs)} vertices laid on the skin")


def place_front(ob, spec, name):
	# a flat piece worn where the owner's painting draws it, as the painting is seen: from the front (the Frost Swan's
	# crystal frills, the owner 2026-11-10: "gắn nó vào vị trí giống như trong hình ảnh tham chiếu", worn standing proud,
	# "không phải chìm vào trong thân"). The file's front view is the painting's: every point keeps its place across and
	# up; what lies over the body is laid on its front with the back face on the skin and the whole relief outside (a
	# frame lays such points one by one and flattens the relief); what reaches past the outline stands out in the body's
	# middle plane, turned back by `bend` degrees. `at` = (across, + toward the slime's left; up) of its middle in the
	# front view, `scale`; `turn` and `flip` as for a wrap
	vs = ob.data.vertices
	lo = Vector((min(v.co.x for v in vs), min(v.co.y for v in vs), min(v.co.z for v in vs)))
	hi = Vector((max(v.co.x for v in vs), max(v.co.y for v in vs), max(v.co.z for v in vs)))
	rebase(ob, (lo + hi) / 2)
	ob.data.transform(Matrix.Scale(spec["scale"], 4) @ Matrix.Rotation(rad(-spec.get("turn", 0)), 4, "Y"))
	if spec.get("flip"):
		ob.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
		ob.data.flip_normals()
	back = max(v.co.y for v in vs)
	ax, az = spec["at"]
	bend = math.tan(rad(spec.get("bend", 0)))
	laid = 0
	for v in vs:
		x, z = ax + v.co.x, max(az + v.co.z, 0.005)
		r = skin_radius(z)
		if abs(x) < r:
			y = -math.sqrt(r * r - x * x)
			laid += 1
		else:
			y = (abs(x) - r) * bend
		# (its back face a hair under the skin, so no gap shows)
		v.co = Vector((x, y + 0.005 - (back - v.co.y), z))
	r = skin_radius(az)
	anchor = Vector((ax, -math.sqrt(max(r * r - ax * ax, 0.0)), az))
	ob.data.transform(Matrix.Translation(-anchor))
	ob.location = anchor
	print(f"FRONT {name} at {spec['at']}, {laid} of {len(vs)} vertices laid on the body's front, anchor {tuple(round(x, 3) for x in anchor)}")


def place_aim(ob, spec, name):
	# a piece set by where it points (a bird's wing at rest on the back: the owner, 2026-11-10, "tư thế tự nhiên của cánh
	# chim", "phải ở đằng sau lưng của slime", "xoay ngang như đang xòe cánh"): its root (the end along X that `root`
	# names) at `at`, turned so its long line (from the root to its farthest point) runs along `point` and its painted
	# side (-Y in the file) looks along `face` (made square to `point`). The directions are for a piece on the slime's
	# left (+X); one on its right (`at` x < 0) takes them mirrored. A turn cannot mirror: a piece whose painted side
	# turns from the file's front to the slime's back must be the file's piece of the same side, or it comes out upside
	# down (the run prints how upright the file's top stays). Returns the beat axis: the painted side's normal, signed
	# so a positive turn lifts the tip, the wing beating in its own plane
	vs = ob.data.vertices
	rebase(ob, anchor_of(ob, "x", spec["root"] == "+x"))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))

	def frame(along, look):
		along = along.normalized()
		look = (look - along * look.dot(along)).normalized()
		return Matrix((along, look, along.cross(look))).transposed()

	m = 1 if spec["at"][0] >= 0 else -1
	point, face = Vector(spec["point"]), Vector(spec["face"])
	point.x *= m
	face.x *= m
	far = max(vs, key=lambda v: v.co.length).co.copy()
	if spec.get("edge"):
		# a butterfly's wing meets the body along its straight inner edge, not at its narrow point (the owner,
		# 2026-11-10: "phần tiếp xúc với thân thể ... là phần thẳng của cạnh cánh bướm"): the edge runs from the root to
		# the highest vertex of the inner 35 % of the wing (the file draws the wing upright), and that edge, not the
		# farthest point, is what runs along `point`
		out = 1 if spec["root"] == "-x" else -1
		width = max(v.co.x * out for v in vs)
		far = max((v for v in vs if v.co.x * out < width * 0.35), key=lambda v: v.co.z).co.copy()
		print(f"EDGE {name} {far.length:.3f} long")
	turn = frame(point, face) @ frame(far, Vector((0, -1, 0))).transposed()
	ob.data.transform(turn.to_4x4())
	ob.location = spec["at"]
	tip = max(vs, key=lambda v: v.co.length).co + ob.location
	inside = sum(outside(ob.location + v.co) < 0 for v in vs)
	upright = (turn @ Vector((0, 0, 1))).z
	print(f"AIM {name} tip at {tuple(round(x, 3) for x in tip)}, {inside} of {len(vs)} vertices inside the body, "
		f"upright {upright:+.2f}")
	along = point.normalized()
	if spec.get("edge"):
		# (a butterfly's beat: the wing turns on its edge as on a hinge, signed so a positive turn sweeps it back)
		return along * m
	normal = (face - along * face.dot(along)).normalized()
	return normal if normal.cross(along).z > 0 else -normal


SUCKER_PIXELS = []


def suckers_of(ob):
	# the vertices painted as suckers (light pink-purple; the arm itself is dark blue with blue-violet streaks), by the
	# texture under them
	import numpy as np
	img = [i for i in bpy.data.images if i.size[0] > 0][0]
	w, h = img.size
	if not SUCKER_PIXELS:
		px = np.empty(w * h * 4, np.float32)
		img.pixels.foreach_get(px)
		SUCKER_PIXELS.append(px.reshape(h, w, 4))
	px = SUCKER_PIXELS[0]
	uv = ob.data.uv_layers.active.data
	sums = [[0.0, 0.0, 0] for _ in ob.data.vertices]
	for loop in ob.data.loops:
		u, v = uv[loop.index].uv
		c = px[min(int(v % 1 * h), h - 1), min(int(u % 1 * w), w - 1)]
		s = sums[loop.vertex_index]
		s[0] += c[0]
		s[1] += c[1]
		s[2] += 1
	return [i for i, s in enumerate(sums) if s[2] and s[0] / s[2] > SUCKER_RED and (s[0] - s[1]) / s[2] > SUCKER_PINK]


# a sucker's red, and how far its red stands above its green (the arm's streaks are blue-violet: low red)
SUCKER_RED = 0.5
SUCKER_PINK = 0.15
# how much of an arm's length (from its root) is its root, under the body
ROOT_PART = 0.2
# above this height a part of an arm inside the body pierces its side (below, the jelly's low bulge hides it)
PIERCE = 0.12


def place_tentacle(ob, spec, name):
	# an octopus arm growing from under the body (the owner, 2026-11-10: "gắn ở dưới thân của slime", "co duỗi, ngọ nguậy
	# như tay bạch tuộc"; then: every arm joins the body underneath, none sunk into it to show only a stub at its side,
	# and the purple suckers face down or out, never up: "phần màu tím phải quay xuống bên dưới hoặc ra ngoài"). The file
	# draws it in its XZ plane, its thick root the lowest end. The root goes under the body at `at` = (degrees around from
	# the front, + toward the slime's left; how far out from the middle line; height), its long line (root to farthest
	# point) out over the ground. How steeply it climbs and how its plane rolls about that line are searched: the turn
	# whose suckers look most down and out, with nothing past its root inside the body, nothing over the face, the root
	# not lifted off the ground's level and the arm reaching well out of the body. Then rigged: a chain of `bones` bones
	# root to tip (named <name>_0, _1, ...), each vertex weighted by how far along the arm it lies, measured over its
	# surface. Returns the curl axis (its plane's normal; a positive turn lifts the tip) and the joints
	vs = ob.data.vertices
	zs = sorted(v.co.z for v in vs)
	cut = zs[0] + (zs[-1] - zs[0]) * 0.06
	root = [v.index for v in vs if v.co.z <= cut]
	rebase(ob, sum((vs[i].co for i in root), Vector()) / len(root))
	ob.data.transform(Matrix.Scale(spec["scale"], 4))
	# how far along the arm each vertex lies: the shortest way over its edges from the root (Dijkstra)
	links = [[] for _ in vs]
	for e in ob.data.edges:
		a, b = e.vertices
		d = (vs[a].co - vs[b].co).length
		links[a].append((b, d))
		links[b].append((a, d))
	dist = [math.inf] * len(vs)
	heap = []
	for i in root:
		dist[i] = 0.0
		heap.append((0.0, i))
	heapq.heapify(heap)
	while heap:
		d, i = heapq.heappop(heap)
		if d > dist[i]:
			continue
		for j, w in links[i]:
			if d + w < dist[j]:
				dist[j] = d + w
				heapq.heappush(heap, (d + w, j))
	top = max(x for x in dist if x < math.inf)
	t = [min(x, top) / top for x in dist]

	def frame(along, look):
		along = along.normalized()
		look = (look - along * look.dot(along)).normalized()
		return Matrix((along, look, along.cross(look))).transposed()

	deg, reach, height = spec["at"]
	out = Vector((math.sin(rad(deg)), -math.cos(rad(deg)), 0))
	side = Vector((0, 0, 1)).cross(out)
	far = max(vs, key=lambda v: v.co.length).co.copy()
	sucker = suckers_of(ob)
	cos = [v.co.copy() for v in vs]
	nos = [v.normal.copy() for v in vs]
	flat = frame(far, Vector((0, 1, 0))).transposed()
	best = None
	for rise in range(-10, 35, 5):
		point = out * math.cos(rad(rise)) + Vector((0, 0, math.sin(rad(rise))))
		for roll in range(0, 360, 15):
			turn = frame(point, Matrix.Rotation(rad(roll), 3, point) @ side) @ flat
			ps = [turn @ c for c in cos]
			# (the root may go under the ground, hidden by the body; the arm past it lies on the ground at most)
			lift = max(-(height + min(p.z for p, f in zip(ps, t) if f > ROOT_PART)), 0.0)
			origin = Vector((out.x * reach, out.y * reach, height + lift))
			ws = [origin + p for p in ps]
			# past its root inside the body: hidden under the jelly's low bulge, or (above PIERCE) out through its side
			inside = sum(1 for w, f in zip(ws, t) if f > ROOT_PART and outside(w) < 0) / len(ws)
			pierce = sum(1 for w in ws if w.z > PIERCE and outside(w) < 0) / len(ws)
			face = sum(1 for w in ws if 0.3 < w.z < 0.7 and w.y < 0 and abs(math.atan2(w.x, -w.y)) < rad(35)) / len(ws)
			looks = [turn @ nos[i] for i in sucker]
			look = sum(looks, Vector()).normalized()
			up = sum(1 for d in looks if d.z > 0.3) / max(len(looks), 1)
			score = (-look.z + 0.6 * look.dot(out) - 2 * up - 10 * pierce - 2 * inside - 4 * face - 10 * lift
				+ 1.5 * max(outside(w) for w in ws))
			if best is None or score > best[0]:
				best = (score, rise, roll, point, turn, lift, inside, pierce, up, look)
	_, rise, roll, point, turn, lift, inside, pierce, up, look = best
	ob.data.transform(turn.to_4x4())
	ob.location = Vector((out.x * reach, out.y * reach, height + lift))
	n = spec.get("bones", 5)
	joints = []
	for k in range(n + 1):
		band = [vs[i].co for i in range(len(vs)) if (k - 0.5) / n <= t[i] < (k + 0.5) / n]
		if not band:
			band = [vs[min(range(len(vs)), key=lambda i: abs(t[i] - k / n))].co]
		joints.append(sum(band, Vector()) / len(band))
	arm = bpy.data.armatures.new(name + "Rig")
	rig = bpy.data.objects.new(name + "Rig", arm)
	bpy.context.scene.collection.objects.link(rig)
	rig.location = ob.location
	bpy.ops.object.select_all(action="DESELECT")
	rig.select_set(True)
	bpy.context.view_layer.objects.active = rig
	bpy.ops.object.mode_set(mode="EDIT")
	prev = None
	for k in range(n):
		b = arm.edit_bones.new(f"{name}_{k}")
		b.head, b.tail = joints[k], joints[k + 1]
		if prev:
			b.parent = prev
			b.use_connect = True
		prev = b
	bpy.ops.object.mode_set(mode="OBJECT")
	groups = [ob.vertex_groups.new(name=f"{name}_{k}") for k in range(n)]
	for i in range(len(vs)):
		# (between the middles of the two nearest bones)
		f = min(max(t[i] * n - 0.5, 0.0), n - 1.0)
		k = min(int(f), n - 2)
		w = f - k
		groups[k].add([i], 1.0 - w, "REPLACE")
		groups[k + 1].add([i], w, "REPLACE")
	ob.parent = rig
	ob.matrix_parent_inverse = rig.matrix_world.inverted()
	mod = ob.modifiers.new("Rig", "ARMATURE")
	mod.object = rig
	normal = turn @ Vector((0, 1, 0))
	along = point.normalized()
	axis = normal if normal.cross(along).z > 0 else -normal
	tip = max((ob.location + v.co).length for v in vs)
	print(f"TENTACLE {name} at {deg} degrees, rise {rise}, roll {roll}, root {tuple(round(x, 3) for x in ob.location)}, "
		f"reaches {tip:.3f} from the feet, lifted {lift:.3f}, {inside:.0%} under the body, {pierce:.0%} through its side, "
		f"suckers {len(sucker)} of {len(vs)} looking {tuple(round(x, 2) for x in look)}, {up:.0%} of them up, {n} bones")
	# each bone's rest frame (its point and its X and Y axes, Y along the bone), as Roblox's import puts it: the game
	# builds the bones from these, by name, and the skin bends with them
	frames = [rig.matrix_world @ b.matrix_local for b in arm.bones]
	return axis, frames, rig


def mirrored(ob, name):
	twin = ob.copy()
	twin.data = ob.data.copy()
	twin.name = name
	bpy.context.scene.collection.objects.link(twin)
	twin.data.transform(Matrix.Scale(-1, 4, (1, 0, 0)))
	twin.data.flip_normals()
	twin.location = (-ob.location.x, ob.location.y, ob.location.z)
	return twin


wear, axes, joints, rigs = [], {}, {}, []
# a part worn twice (an armour plate on the front and again on the back) is copied before the first one moves
pristine = {key: ob.data.copy() for key, ob in parts.items()}
taken = set()
for name, spec in KIT["pieces"].items():
	ob = parts[spec["part"]]
	if spec["part"] in taken:
		ob = bpy.data.objects.new(name, pristine[spec["part"]].copy())
		bpy.context.scene.collection.objects.link(ob)
	taken.add(spec["part"])
	if spec["kind"] == "horn":
		place_horn(ob, spec, name)
	elif spec["kind"] == "wing":
		axis = place_wing(ob, spec)
		axes[name] = axis
		if spec.get("twin"):
			axes[spec["twin"]] = Vector((axis.x, -axis.y, axis.z))
	elif spec["kind"] == "wrap":
		place_wrap(ob, spec, name)
	elif spec["kind"] == "frame":
		place_frame(ob, spec, name)
	elif spec["kind"] == "front":
		place_front(ob, spec, name)
	elif spec["kind"] == "rigid":
		place_rigid(ob, spec, name)
	elif spec["kind"] == "aim":
		axes[name] = place_aim(ob, spec, name)
		if spec.get("twin"):
			# (the mirror of a turn's axis keeps its x and turns its y and z: the twin's tip lifts too)
			axes[spec["twin"]] = Vector((axes[name].x, -axes[name].y, -axes[name].z))
	elif spec["kind"] == "tentacle":
		axes[name], joints[name], rig = place_tentacle(ob, spec, name)
		rigs.append(rig)
	else:
		place_tail(ob, spec, name)
	ob.name = name
	wear.append(ob)
	if spec.get("twin"):
		wear.append(mirrored(ob, spec["twin"]))

# a part no piece uses (a bit the owner did not want) leaves the pictures too
used = {spec["part"] for spec in KIT["pieces"].values()}
for key, ob in parts.items():
	if key not in used:
		bpy.data.objects.remove(ob)

# texture at 1024
img = [i for i in bpy.data.images if i.size[0] > 0][0]
img.scale(TEXTURE, TEXTURE)
img.filepath_raw = os.path.join(ROOT, KIT["texture"])
img.file_format = "PNG"
img.save()


# the reference body (a lathe of the profile) and two eyes on its front, for the pictures only
def lathe():
	bm = bmesh.new()
	seg = 40
	rings = []
	for i, r in enumerate(PROFILE):
		z = i * 0.05
		ring = [bm.verts.new((max(r, 0.0001) * math.cos(2 * math.pi * k / seg), max(r, 0.0001) * math.sin(2 * math.pi * k / seg), z)) for k in range(seg)]
		rings.append(ring)
	for a, b in zip(rings, rings[1:]):
		for k in range(seg):
			bm.faces.new((a[k], a[(k + 1) % seg], b[(k + 1) % seg], b[k]))
	bm.faces.new(list(reversed(rings[0])))
	me = bpy.data.meshes.new("Body")
	bm.to_mesh(me)
	ob = bpy.data.objects.new("Body", me)
	bpy.context.scene.collection.objects.link(ob)
	for p in me.polygons:
		p.use_smooth = True
	m = bpy.data.materials.new("BodyMat")
	m.use_nodes = True
	m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = KIT["body"]
	me.materials.append(m)
	for sx in (-0.16, 0.16):
		bpy.ops.mesh.primitive_uv_sphere_add(radius=0.06, location=(sx, -0.47, 0.55))
		eye = bpy.context.active_object
		eye.name = "Eye"
		em = bpy.data.materials.new("EyeMat")
		em.use_nodes = True
		em.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (1, 1, 1, 1)
		eye.data.materials.append(em)
	return ob


body = lathe()

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 560
scene.render.resolution_y = 560
world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.82, 0.86, 0.9, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 1.2
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.5
sun.rotation_euler = (rad(45), 0, rad(-35))
scene.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = 2.0
scene.collection.objects.link(cam)
scene.camera = cam
centre = Vector((0, 0.15, 0.55))
views = {
	"front": Vector((0, -1, 0)),
	"back": Vector((0, 1, 0)),
	"side": Vector((1, 0, 0)),
	"top": Vector((0, 0.001, 1)),
	"game": Vector((0.6, -1, 0.75)),
	"backq": Vector((-0.8, 1, 0.5)),
	# (low at the front quarter: what grows from under the body)
	"low": Vector((0.7, -1, 0.12)),
}
for name, d in views.items():
	cam.location = centre + d.normalized() * 6
	cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(REVIEW, f"{name}.png")
	bpy.ops.render.render(write_still=True)
# the head close, from the front, from above the back, and from low at the front (where a player close to the slime
# looks up under its ears: the owner's view of an ear hanging over the shoulder, 2026-11-10)
cam.data.ortho_scale = 0.9
head = Vector((0, 0, 0.8))
for name, d in {"head": Vector((0, -1, 0.15)), "headback": Vector((0.3, 1, 0.6)), "headlow": Vector((0.35, -1, -0.35))}.items():
	cam.location = head + d.normalized() * 6
	cam.rotation_euler = (head - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = os.path.join(REVIEW, f"{name}.png")
	bpy.ops.render.render(write_still=True)


# numbers for the game, in Roblox mesh space: (X, Y, Z) = (-x, z, y)
def rb(v):
	return [round(-v.x, 4), round(v.z, 4), round(v.y, 4)]


out = {}
total = 0
for ob in wear:
	pts = [ob.matrix_world @ v.co for v in ob.data.vertices]
	lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
	hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
	c = (lo + hi) / 2
	size = hi - lo
	ob.data.calc_loop_triangles()
	total += len(ob.data.loop_triangles)
	entry = dict(centre=rb(c), size=[round(size.x, 4), round(size.z, 4), round(size.y, 4)], anchor=rb(ob.location),
		tris=len(ob.data.loop_triangles))
	if ob.name in axes:
		entry["axis"] = rb(axes[ob.name])
	if ob.name in joints:
		# (a rigged piece: its bones root to tip, each its point, X axis and Y axis as Roblox's import makes them: the
		# FBX turns a bone half round its own Y, so its X is Blender's turned backwards; checked in Studio, 2026-11-10)
		entry["bones"] = [rb(m.translation) + rb(-m.col[0].xyz) + rb(m.col[1].xyz) for m in joints[ob.name]]
	out[ob.name] = entry
out["triangles"] = total
with open(os.path.join(ROOT, "wear.json"), "w") as f:
	json.dump(out, f, indent=1)
print("WEAR", json.dumps(out))

# export the pieces like the body
bpy.ops.object.select_all(action="DESELECT")
for ob in wear + rigs:
	ob.select_set(True)
bpy.context.view_layer.objects.active = wear[0]
# (a rigged kit carries its bones; the modifier stays live so the skin goes out unposed)
bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT, KIT["out"] + ".fbx"), use_selection=True,
	object_types={"MESH", "ARMATURE"} if rigs else {"MESH"}, axis_forward="-Z", axis_up="Y",
	apply_scale_options="FBX_SCALE_ALL", apply_unit_scale=True, use_space_transform=True, bake_space_transform=False,
	mesh_smooth_type="FACE", use_mesh_modifiers=not rigs, use_tspace=False, path_mode="AUTO", embed_textures=False,
	add_leaf_bones=False, use_armature_deform_only=True, bake_anim=False)
print("DONE")
