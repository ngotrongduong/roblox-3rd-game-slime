-- Weapon Aura Staff: what Goo Lineage's finer Healing Staffs give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). Each rung's whole aura is one ChatGPT clip (the owner's way,
-- lesson 284: a GIF of this very staff wearing it, rebuilt as the effect alone round its empty shape) FIXED through
-- the staff's middle, so it turns and tilts with the staff, never with the camera, and the staff hides it where it
-- stands (lessons 291, 292); a few small things of the clip's kind drifting round it, before and behind, give it depth
-- from every side (the owner, 2026-11-13). Core, the Enchanted staff: a violet ribbon of light spiralling up round the
-- shaft, the crystal pulsing violet, white sparkles and violet glints round it. Bramble, Lifebloom: the crystal pulsing
-- teal, teal and pink ribbons spiralling up, blossoms drifting away round it, teal sparkles, a cool light. Legend,
-- Everbloom: a crown of golden lily petals opening over the top, the emerald pulsing green, golden leaves rising round
-- it, green and gold glints, a warm light.

-- (the whole aura in one picture drawn round the staff's empty shape, through its middle, the clip once every 1.5 s.
-- `size`: the picture's side in studs, the staff's height over its share of the picture, as clip_frames.py --fit
-- prints it, times two)
local function card(texture, size)
	return { name = "aura", texture = texture, size = size }
end

-- (a few small things of the clip's own kind round the staff, before it, behind it and beside it, held to it: from the
-- side, where the card is only a line, they still stand round the staff in depth)
local function motes(name, texture, color, over)
	local piece = {
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 2, 1, 3.3 },
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
-- (a glint that flares and goes: born small, wide in a moment, gone)
local POP = { { 0, 0 }, { 0.35, 0.18 }, { 1, 0 } }

return {
	id = "aura.weapon_staff",
	name = "Weapon Aura Staff",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "staff", "held", "heal", "nature", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	cards = { card("enchanted_aura_flip", 3.64) },
	pieces = {
		motes("sparks", "star_twinkle", { { 255, 255, 255 }, { 220, 190, 255 } }, {
			rate = 8,
			size = SPARKS,
			lightEmission = 1,
		}),
		motes("glints", "sparkStar", { { 235, 210, 255 }, { 170, 110, 255 } }, {
			rate = 3,
			life = { 0.6, 0.9 },
			size = POP,
			transparency = { { 0, 0 }, { 1, 0.3 } },
			rotSpeed = { -90, 90 },
			lightEmission = 0.6,
			secondary = true,
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			cards = { card("lifebloom_aura_flip", 3.38) },
			pieces = {
				motes("petals", "peach_blossom", nil, {
					role = "keep",
					rate = 4,
					size = { { 0, 0 }, { 0.2, 0.16 }, { 0.8, 0.16 }, { 1, 0 } },
					accel = { 0, -0.12, 0 },
					rotSpeed = { -60, 60 },
					lightEmission = 0,
				}),
				motes("sparks", "star_twinkle", { { 215, 255, 240 }, { 110, 240, 210 } }, {
					size = SPARKS,
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 200, 255, 225 }, brightness = 1.3, range = 8 },
		},
		legend = {
			cards = { card("everbloom_aura_flip", 4.54) },
			pieces = {
				motes("leaves", "leaves_solid", { { 255, 232, 135 }, { 230, 180, 60 } }, {
					flipbook = { layout = "Grid2x2", mode = "Random" },
					rate = 4,
					size = { { 0, 0 }, { 0.2, 0.18 }, { 0.8, 0.18 }, { 1, 0 } },
					speed = { 0.15, 0.3 },
					direction = "Top",
					spread = { 40, 40 },
					lightEmission = 0.2,
				}),
				motes("glints", "sparkStar", { { 220, 255, 180 }, { 255, 215, 110 } }, {
					rate = 3,
					life = { 0.6, 0.9 },
					size = POP,
					transparency = { { 0, 0 }, { 1, 0.3 } },
					rotSpeed = { -90, 90 },
					lightEmission = 0.6,
					secondary = true,
				}),
			},
			light = { color = { 255, 220, 130 }, brightness = 1.3, range = 9 },
		},
	},
	-- (the preview caught mid-clip, not on its dim first frame)
	markers = { peak = 3.6 },
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "enchanted_aura_flip, lifebloom_aura_flip, everbloom_aura_flip (ChatGPT's GIF of each staff wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit); peach_blossom, leaves_solid (ChatGPT for the library); the owner's spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: star_twinkle)",
		licence = "the owner's own art (drawn for the library by ChatGPT); Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(staffMeshPart, id, { variant = rarity }) while a core, bramble or legend staff is held; VfxLib.detach(handle) when it is put away. The card lies through the staff's middle (its thin side is the mesh's z). Core is cheap (no light), bramble and legend mid with a small light.",
}
