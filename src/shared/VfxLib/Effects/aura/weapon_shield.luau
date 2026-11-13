-- Weapon Aura Shield: what Goo Lineage's finer shields give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon shields have none). Each rung's whole aura is one ChatGPT clip (the owner's way,
-- lesson 284: a GIF of this very shield wearing it, rebuilt as the effect alone round its empty shape) FIXED through
-- the shield's middle, so it turns and tilts with the shield, never with the camera, and the shield hides it where it
-- stands (lessons 291, 292); a few small things of the clip's kind drifting round it, before and behind, give it depth
-- from every side (the owner, 2026-11-13). Core, the Warden: a royal-blue light running round the rim, a gold glint sweeping
-- the crest, blue stars twinkling round it. Bramble, the Aegis of Goo: lime goo oozing round the rim and dripping off
-- the point, bubbles rising and popping, leaves glowing and drifting off, a green light. Legend, the Royal Bastion:
-- golden rays fanning out behind it, gold light round the rim and towers, a crown of light over the top, golden
-- fleurs-de-lis rising round it, a gold light.

-- (the whole aura in one picture drawn round the shield's empty shape, through its middle, the clip once every 1.5 s.
-- `size`: the picture's side in studs, the shield's height over its share of the picture, as clip_frames.py --fit
-- prints it, times two)
local function card(texture, size)
	return { name = "aura", texture = texture, size = size }
end

-- (a few small things of the clip's own kind round the shield, before it, behind it and beside it, held to it: from
-- the side, where the card is only a line, they still stand round the shield in depth)
local function motes(name, texture, color, over)
	local piece = {
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 1.2, 1, 2 },
		rate = 8,
		life = { 1.6, 2.2 },
		size = { { 0, 0 }, { 0.25, 0.18 }, { 0.75, 0.18 }, { 1, 0 } },
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

-- (a glint that flares and goes: born small, wide in a moment, gone)
local POP = { { 0, 0 }, { 0.35, 0.2 }, { 1, 0 } }

return {
	id = "aura.weapon_shield",
	name = "Weapon Aura Shield",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "shield", "held", "ward", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	cards = { card("warden_aura_flip", 3.8) },
	pieces = {
		motes("stars", "star4_drift", { { 210, 225, 255 }, { 90, 140, 255 } }, { lightEmission = 0.6 }),
		motes("glints", "star_glint_sharp", { { 255, 245, 200 }, { 255, 205, 100 } }, {
			rate = 2,
			life = { 0.5, 0.7 },
			size = { { 0, 0 }, { 0.4, 0.35 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.2 } },
			rotation = { -15, 15 },
			rotSpeed = { -30, 30 },
			lightEmission = 1,
			secondary = true,
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			cards = { card("goo_aegis_aura_flip", 4.88) },
			pieces = {
				motes("bubbles", "bubble_gloss", { { 215, 255, 160 }, { 150, 240, 80 } }, {
					size = { { 0, 0 }, { 0.2, 0.14 }, { 0.85, 0.16 }, { 1, 0 } },
					speed = { 0.2, 0.4 },
					direction = "Top",
					spread = { 20, 20 },
					lightEmission = 0.2,
				}),
				motes("leaves", "leaves_solid", { { 175, 240, 95 }, { 110, 200, 60 } }, {
					flipbook = { layout = "Grid2x2", mode = "Random" },
					rate = 3,
					size = { { 0, 0 }, { 0.2, 0.2 }, { 0.8, 0.2 }, { 1, 0 } },
					accel = { 0, -0.15, 0 },
					lightEmission = 0,
					secondary = true,
				}),
			},
			light = { color = { 150, 255, 110 }, brightness = 1.2, range = 8 },
		},
		legend = {
			cards = { card("bastion_aura_flip", 4.5) },
			pieces = {
				-- (a fleur-de-lis grows from a spark, glints, splits and drifts up: the clip once a life)
				motes("fleurs", "royal_flip", { { 255, 228, 130 }, { 255, 190, 60 } }, {
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					rate = 2,
					life = { 1.5, 1.5 },
					size = { { 0, 0.3 }, { 1, 0.3 } },
					transparency = { { 0, 0 }, { 1, 0 } },
					speed = { 0.2, 0.35 },
					direction = "Top",
					spread = { 25, 25 },
					rotation = { 0, 0 },
					rotSpeed = { 0, 0 },
					lightEmission = 0,
				}),
				motes("glints", "sparkStar", { { 255, 245, 190 }, { 255, 200, 90 } }, {
					rate = 3,
					life = { 0.6, 0.9 },
					size = POP,
					transparency = { { 0, 0 }, { 1, 0.3 } },
					rotSpeed = { -90, 90 },
					lightEmission = 0.6,
					secondary = true,
				}),
			},
			light = { color = { 255, 215, 120 }, brightness = 1.3, range = 9 },
		},
	},
	-- (the preview caught mid-clip, not on its dim first frame)
	markers = { peak = 3.6 },
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "warden_aura_flip, goo_aegis_aura_flip, bastion_aura_flip (ChatGPT's GIF of each shield wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit); royal_flip, bubble_gloss, leaves_solid (ChatGPT for the library); the owner's spark star (sparkStar, tinted); star4_drift (Egg Heist's pack); free Creator Store pack textures (no scripts: star_glint_sharp)",
		licence = "the owner's own art (drawn for the library by ChatGPT); Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(shieldMeshPart, id, { variant = rarity }) while a core, bramble or legend shield is held; VfxLib.detach(handle) when it is put away. The card lies through the shield's middle (its thin side is the mesh's z). Core is cheap (no light), bramble and legend mid with a small light.",
}
