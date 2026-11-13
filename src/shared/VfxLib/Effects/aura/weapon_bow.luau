-- Weapon Aura Bow: what Goo Lineage's finer bows give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon bows have none). Each rung's whole aura is one ChatGPT clip (the owner's way, lesson
-- 284: a GIF of this very bow wearing it, rebuilt as the effect alone round its empty shape) FIXED through the bow's
-- middle, so it turns and tilts with the bow, never with the camera, and the bow hides it where it stands (lessons
-- 291, 292); a few small things of the clip's kind drifting round it, before and behind, give it depth from every side
-- (the owner, 2026-11-13). Core, Windwhisper: teal wind arcs sweeping round the bow's back, the string shimmering, white feathers
-- and small gusts drifting round it. Bramble, Starfall: violet starlight along the limbs, the star gems flaring, the
-- string shimmering, gold stars falling round it, a violet light. Legend, Moonsong: silver moonlight swirling round
-- the bow, crescent moons orbiting, notes drifting off, a moon halo over the tip like a crown, a moon light.

-- (the whole aura in one picture drawn round the bow's empty shape, through its middle, the clip once every 1.5 s.
-- `size`: the picture's side in studs, the bow's height over its share of the picture, as clip_frames.py --fit
-- prints it, times two)
local function card(texture, size)
	return { name = "aura", texture = texture, size = size }
end

-- (a few small things of the clip's own kind round the bow, before it, behind it and beside it, held to it: from the
-- side, where the card is only a line, they still stand round the bow in depth)
local function motes(name, texture, color, over)
	local piece = {
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 1.3, 1, 3.8 },
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
	id = "aura.weapon_bow",
	name = "Weapon Aura Bow",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "bow", "held", "glint", "feather", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	cards = { card("windwhisper_aura_flip", 4.48) },
	pieces = {
		motes("feathers", "down_feather", { { 255, 255, 255 }, { 215, 245, 240 } }, {
			rate = 5,
			size = { { 0, 0 }, { 0.2, 0.2 }, { 0.8, 0.2 }, { 1, 0 } },
			accel = { 0, -0.1, 0 },
			rotSpeed = { -60, 60 },
			lightEmission = 0,
		}),
		-- (a small gust curling past the bow, across it)
		motes("gusts", "gust_curl", { { 200, 255, 245 }, { 110, 225, 210 } }, {
			rate = 2,
			life = { 1.2, 1.6 },
			size = { { 0, 0 }, { 0.3, 0.35 }, { 1, 0.3 } },
			transparency = { { 0, 1 }, { 0.3, 0.3 }, { 1, 1 } },
			speed = { 0.3, 0.5 },
			direction = "Right",
			spread = { 20, 20 },
			rotation = { -10, 10 },
			rotSpeed = { 0, 0 },
			lightEmission = 0.3,
			secondary = true,
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			cards = { card("starfall_aura_flip", 3.86) },
			pieces = {
				motes("stars", "star4_drift", { { 255, 240, 170 }, { 255, 200, 90 } }, {
					size = { { 0, 0 }, { 0.25, 0.16 }, { 0.75, 0.16 }, { 1, 0 } },
					accel = { 0, -0.3, 0 },
					lightEmission = 0.8,
				}),
				motes("sparks", "star_twinkle", { { 230, 210, 255 }, { 170, 130, 255 } }, {
					size = SPARKS,
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 195, 160, 255 }, brightness = 1.3, range = 8 },
		},
		legend = {
			cards = { card("moonsong_aura_flip", 4.86) },
			pieces = {
				-- (music notes pop out, bob to a beat and sparkle away: the clip once a life)
				motes("notes", "notes_flip", { { 215, 225, 255 }, { 150, 170, 255 } }, {
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					rate = 2,
					life = { 1.5, 1.5 },
					size = { { 0, 0.28 }, { 1, 0.28 } },
					transparency = { { 0, 0 }, { 1, 0 } },
					speed = { 0.15, 0.3 },
					direction = "Top",
					spread = { 30, 30 },
					rotation = { -10, 10 },
					rotSpeed = { 0, 0 },
					lightEmission = 0,
				}),
				motes("sparks", "star_twinkle", { { 245, 250, 255 }, { 180, 200, 255 } }, {
					size = SPARKS,
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 175, 195, 255 }, brightness = 1.3, range = 9 },
		},
	},
	-- (the preview caught mid-clip, not on its dim first frame)
	markers = { peak = 3.6 },
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "windwhisper_aura_flip, starfall_aura_flip, moonsong_aura_flip (ChatGPT's GIF of each bow wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit); down_feather, gust_curl, notes_flip (ChatGPT for the library); star4_drift (Egg Heist's pack); free Creator Store pack textures (no scripts: star_twinkle)",
		licence = "the owner's own art (drawn for the library by ChatGPT); Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(bowMeshPart, id, { variant = rarity }) while a core, bramble or legend bow is held; VfxLib.detach(handle) when it is put away. The card lies through the bow's middle (its thin side is the mesh's z). Core is cheap (no light), bramble and legend mid with a small light.",
}
