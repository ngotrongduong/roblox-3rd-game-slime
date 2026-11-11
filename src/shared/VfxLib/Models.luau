-- The library's skinned 3D models: a serpent's whole body as one MeshPart, bent along its loop by its bones.
--
-- A MODEL (rigged in Blender, uploaded by Studio's Import 3D; its source GLB in models/<key>.glb):
--   mesh      the MeshPart's mesh asset id (no texture: drawn in the effect's colour, as `look`)
--   look      the Material it is drawn in ("ForceField": a see-through hologram, lit at its edges)
--   fill      (optional) the transparency of a Neon copy of the body under it, bent by the same bones: a faint solid
--             body, so the hologram still reads over a bright sky
--   length    studs from snout to tail tip at scale 1; snout: where the snout is on the part's Z (its head looks +Z)
--   root      the Root bone's place in the part; bones: spine bones S01.. under Root, the first at Z `first`, each
--             `step` studs behind the one before, all turned by `turn` (the import's rest rotation, row by row)
--   legs      { name, bone (the spine bone it hangs from), at (its place in that bone's frame), phase (share of a
--             stroke), swing (degrees forward and back), spread (degrees out from the body and in), period (seconds of
--             one stroke) }: a leg's bone, holding the leg rigidly from its shoulder, clawing as the serpent flies
--   wave      (optional) the body swimming up and down along its own path: { height (studs each way), length (studs
--             of one wave), period (seconds) }; the wave runs from the head back to the tail, small at the head
--   head      (optional) the head looking about on its own: { bones (how many spine bones from the snout turn with
--             it, about the next one), yaw, pitch (degrees each way), period (seconds of one look) }
--   tail      (optional) the tail swishing side to side: { bones (spine bones at the end), sway (studs each way at
--             the tip), length (studs of one swish), period (seconds) }
--   (lengths in the model's studs at scale 1)
--   area      square studs it covers (Budget)
local Models = {}

Models.list = {
	-- The owner's Crimson Sky Serpent (Meshy, 2026-11-08): a long eastern dragon made straight, four legs folded back
	-- for flight (docs/vfx/models.md)
	crimson_serpent = {
		mesh = 121014246534797,
		look = "ForceField",
		fill = 0.85,
		length = 14,
		snout = 7,
		root = { 0.0068, 0.5566, 0.0027 },
		bones = 24,
		first = 5.5935,
		step = 0.535317,
		turn = { -1, 0, 0, 0, 0, -1, 0, -1, 0 },
		-- (the arms claw quick and wide, the hind legs kick slower and close to the body)
		legs = {
			{
				name = "FrontL",
				bone = 5,
				at = { -0.7614, -0.0119, 0.2665 },
				phase = 0,
				swing = 28,
				spread = 16,
				period = 1.3,
			},
			{
				name = "FrontR",
				bone = 5,
				at = { 0.7614, -0.0119, 0.2665 },
				phase = 0.5,
				swing = 28,
				spread = 16,
				period = 1.3,
			},
			{
				name = "HindL",
				bone = 13,
				at = { -0.7614, -0.0309, 0.2665 },
				phase = 0.25,
				swing = 16,
				spread = 7,
				period = 1.9,
			},
			{
				name = "HindR",
				bone = 13,
				at = { 0.7614, -0.0309, 0.2665 },
				phase = 0.75,
				swing = 16,
				spread = 7,
				period = 1.9,
			},
		},
		-- (gentle slopes: a bone pushed off its path parts from the next, about 8% at the steepest)
		wave = { height = 0.5, length = 8, period = 1.7 },
		head = { bones = 3, yaw = 18, pitch = 10, period = 3.6 },
		tail = { bones = 9, sway = 0.4, length = 8, period = 1.4 },
		area = 20,
	},
}

-- The library's swimming fish: small skinned MeshParts in their own painted texture, worn by an aura's `swimmers`
-- (Builder: each rides its orbit head first, its tail sweeping side to side).
--
-- A FISH (rigged by tools/blender/fish_rig.py, first in Goo Lineage, uploaded as one Model; its source in models/fish/):
--   mesh      the MeshPart's mesh asset id
--   texture?  its picture's id (a packaged effect's fish carry it); else Models.FishTexture (one file shares one picture)
--   size      the MeshPart's size at scale 1, its snout toward -Z (the front), its back up
--   bones     its spine, snout to tail: each bone's rest frame in the part (point, X axis, Y axis, 9 numbers), as
--             Roblox's import binds the skin to them; the client makes them, named `<key>_0`, `<key>_1`, ...
Models.FishTexture = 95909658020180
Models.fish = {
	-- The owner's decorative fish (2026-11-11): eight fancy goldfish with long fan tails, four on dark bodies (a moon, gold
	-- swirls, cherry blossoms, silver curls) and four on pale ones (ice blue, cream and gold, blossom pink, lilac)
	moon_ink = {
		mesh = 82627304127796,
		size = { 0.2251, 0.1021, 0.2319 },
		bones = {
			{ 0, -0.0199, -0.116, 1, 0, 0, 0, 0.0715, 0.9974 },
			{ 0, -0.014, -0.0348, 1, 0, 0, 0, 0.0648, 0.9979 },
			{ 0, -0.011, 0.0116, 1, 0, 0, 0, 0.2795, 0.9601 },
			{ 0, 0.0025, 0.058, 1, 0, 0, 0, -0.1721, 0.9851 },
		},
	},
	gold_ink = {
		mesh = 93052271190071,
		size = { 0.2148, 0.1045, 0.2275 },
		bones = {
			{ 0, -0.0195, -0.1138, 1, 0, 0, 0, 0.0153, 0.9999 },
			{ 0, -0.0182, -0.0341, 1, 0, 0, 0, 0.2627, 0.9649 },
			{ 0, -0.0058, 0.0114, 1, 0, 0, 0, -0.0742, 0.9972 },
			{ 0, -0.0092, 0.0569, 1, 0, 0, 0, 0.4758, 0.8796 },
		},
	},
	sakura_ink = {
		mesh = 121342531636735,
		size = { 0.229, 0.1021, 0.2319 },
		bones = {
			{ 0, -0.014, -0.116, 1, 0, 0, 0, -0.0019, 1 },
			{ 0, -0.0142, -0.0348, 1, 0, 0, 0, 0.0805, 0.9968 },
			{ 0, -0.0104, 0.0116, 1, 0, 0, 0, 0.121, 0.9927 },
			{ 0, -0.0048, 0.058, 1, 0, 0, 0, 0.2701, 0.9628 },
		},
	},
	silver_ink = {
		mesh = 101041736082859,
		size = { 0.2148, 0.1045, 0.2275 },
		bones = {
			{ 0, -0.0197, -0.1138, 1, 0, 0, 0, 0.0228, 0.9997 },
			{ 0, -0.0179, -0.0341, 1, 0, 0, 0, 0.2763, 0.9611 },
			{ 0, -0.0048, 0.0114, 1, 0, 0, 0, 0.0057, 1 },
			{ 0, -0.0045, 0.0569, 1, 0, 0, 0, 0.2657, 0.9641 },
		},
	},
	frost_white = {
		mesh = 86616017924613,
		size = { 0.2266, 0.1099, 0.2314 },
		bones = {
			{ 0, -0.0133, -0.1157, 1, 0, 0, 0, -0.0752, 0.9972 },
			{ 0, -0.0194, -0.0347, 1, 0, 0, 0, 0.1875, 0.9823 },
			{ 0, -0.0106, 0.0116, 1, 0, 0, 0, 0.2394, 0.9709 },
			{ 0, 0.0008, 0.0579, 1, 0, 0, 0, 0.2144, 0.9767 },
		},
	},
	cream_gold = {
		mesh = 115026543022654,
		size = { 0.2271, 0.1089, 0.2344 },
		bones = {
			{ 0, -0.014, -0.1172, 1, 0, 0, 0, -0.0009, 1 },
			{ 0, -0.014, -0.0352, 1, 0, 0, 0, 0.1279, 0.9918 },
			{ 0, -0.008, 0.0117, 1, 0, 0, 0, 0.1176, 0.9931 },
			{ 0, -0.0024, 0.0586, 1, 0, 0, 0, -0.124, 0.9923 },
		},
	},
	blossom_pink = {
		mesh = 140482603841354,
		size = { 0.2344, 0.104, 0.229 },
		bones = {
			{ 0, -0.0134, -0.1145, 1, 0, 0, 0, -0.0254, 0.9997 },
			{ 0, -0.0154, -0.0344, 1, 0, 0, 0, 0.1885, 0.9821 },
			{ 0, -0.0067, 0.0115, 1, 0, 0, 0, 0.1242, 0.9923 },
			{ 0, -0.0009, 0.0573, 1, 0, 0, 0, -0.0594, 0.9982 },
		},
	},
	lilac_white = {
		mesh = 71380294033098,
		size = { 0.2275, 0.1128, 0.2222 },
		bones = {
			{ 0, -0.0114, -0.1111, 1, 0, 0, 0, -0.0437, 0.999 },
			{ 0, -0.0148, -0.0333, 1, 0, 0, 0, 0.2953, 0.9554 },
			{ 0, -0.001, 0.0111, 1, 0, 0, 0, -0.0343, 0.9994 },
			{ 0, -0.0026, 0.0555, 1, 0, 0, 0, -0.073, 0.9973 },
		},
	},
}

-- A model an effect brings with it (a packaged effect: `assets.models`): kept only when the key is new.
function Models.add(key, entry)
	if Models.list[key] == nil and type(entry) == "table" and entry.mesh ~= nil then
		Models.list[key] = entry
	end
end

-- A fish an effect brings with it (a packaged effect: `assets.fish`, each with its `texture`): kept only when new.
function Models.addFish(key, entry)
	if Models.fish[key] == nil and type(entry) == "table" and entry.mesh ~= nil then
		Models.fish[key] = entry
	end
end

function Models.boneName(index)
	return string.format("S%02d", index)
end

return Models
