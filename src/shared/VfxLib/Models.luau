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

-- A model an effect brings with it (a packaged effect: `assets.models`): kept only when the key is new.
function Models.add(key, entry)
	if Models.list[key] == nil and type(entry) == "table" and entry.mesh ~= nil then
		Models.list[key] = entry
	end
end

function Models.boneName(index)
	return string.format("S%02d", index)
end

return Models
