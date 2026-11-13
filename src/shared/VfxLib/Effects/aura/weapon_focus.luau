-- Weapon Aura Focus: what Goo Lineage's finer Arcane Focuses give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). Each rung's whole aura is one ChatGPT clip (the owner's way,
-- lesson 284: a GIF of this very focus wearing it, rebuilt as the effect alone round its empty shape) FIXED through
-- the focus's middle, so it turns and tilts with the focus, never with the camera, and the focus hides it where it
-- stands (lessons 291, 292); a few small things of the clip's kind drifting round it, before and behind, give it depth
-- from every side (the owner, 2026-11-13). Core, the Prism: a rainbow glow breaking out of the gem ring, a rainbow ribbon
-- swirling up round the focus, rainbow shards and white glints round it. Bramble, the Mythic Focus: violet rings
-- orbiting the head, the gem pulsing violet, green leaves and violet sparkles drifting round it, a violet light.
-- Legend, the Astral Scepter: a violet and blue nebula swirling round it, a little golden galaxy turning over its tip
-- like a crown, gold stars and blue sparkles round it, a starlight glow.

-- (the whole aura in one picture drawn round the focus's empty shape, through its middle, the clip once every 1.5 s.
-- `size`: the picture's side in studs, the focus's height over its share of the picture, as clip_frames.py --fit
-- prints it, times two)
local function card(texture, size)
	return { name = "aura", texture = texture, size = size }
end

-- (a few small things of the clip's own kind round the focus, before it, behind it and beside it, held to it: from the
-- side, where the card is only a line, they still stand round the focus in depth)
local function motes(name, texture, color, over)
	local piece = {
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 1.5, 1, 2.4 },
		rate = 8,
		life = { 1.6, 2.2 },
		size = { { 0, 0 }, { 0.25, 0.16 }, { 0.75, 0.16 }, { 1, 0 } },
		transparency = { { 0, 0.15 }, { 1, 0.35 } },
		speed = { 0.05, 0.2 },
		spread = { 180, 180 },
		rotation = { 0, 359 },
		rotSpeed = { -45, 45 },
		lightEmission = 0.4,
		brightness = 1.4,
	}
	for key, value in over or {} do
		piece[key] = value
	end
	return piece
end

local SPARKS = { { 0, 0 }, { 0.25, 0.12 }, { 0.75, 0.12 }, { 1, 0 } }

return {
	id = "aura.weapon_focus",
	name = "Weapon Aura Focus",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "focus", "held", "arcane", "orbit", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	cards = { card("prism_aura_flip", 4.24) },
	pieces = {
		motes("shards", "star_twinkle", "rainbow", { rate = 8, size = SPARKS, lightEmission = 1 }),
		motes("glints", "sparkStar", { { 255, 255, 255 }, { 200, 230, 255 } }, {
			rate = 3,
			life = { 0.6, 0.9 },
			size = { { 0, 0 }, { 0.35, 0.18 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.3 } },
			rotSpeed = { -90, 90 },
			lightEmission = 0.6,
			secondary = true,
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			cards = { card("mythic_aura_flip", 3.78) },
			pieces = {
				motes("leaves", "leaves_solid", { { 155, 235, 115 }, { 90, 190, 80 } }, {
					flipbook = { layout = "Grid2x2", mode = "Random" },
					rate = 4,
					size = { { 0, 0 }, { 0.2, 0.18 }, { 0.8, 0.18 }, { 1, 0 } },
					accel = { 0, -0.12, 0 },
					lightEmission = 0,
				}),
				motes("sparks", "star_twinkle", { { 230, 200, 255 }, { 170, 110, 255 } }, {
					size = SPARKS,
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 195, 140, 255 }, brightness = 1.3, range = 8 },
		},
		legend = {
			cards = { card("astral_aura_flip", 4.42) },
			pieces = {
				motes("stars", "star4_drift", { { 255, 240, 170 }, { 255, 205, 90 } }, {
					size = { { 0, 0 }, { 0.25, 0.16 }, { 0.75, 0.16 }, { 1, 0 } },
					lightEmission = 0.8,
				}),
				motes("sparks", "star_twinkle", { { 205, 215, 255 }, { 150, 120, 255 } }, {
					size = SPARKS,
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 170, 140, 255 }, brightness = 1.3, range = 9 },
		},
	},
	-- (the preview caught mid-clip, not on its dim first frame)
	markers = { peak = 3.6 },
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "prism_aura_flip, mythic_aura_flip, astral_aura_flip (ChatGPT's GIF of each focus wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit); leaves_solid (ChatGPT for the library); the owner's spark star (sparkStar, tinted); star4_drift (Egg Heist's pack); free Creator Store pack textures (no scripts: star_twinkle)",
		licence = "the owner's own art (drawn for the library by ChatGPT); Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(focusMeshPart, id, { variant = rarity }) while a core, bramble or legend focus is held; VfxLib.detach(handle) when it is put away. The card lies through the focus's middle (its thin side is the mesh's z). Core is cheap (no light), bramble and legend mid with a small light.",
}
