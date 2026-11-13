-- Weapon Aura Kit: what Goo Lineage's finer Alchemy Kits give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon ones have none). Each rung's whole aura is one ChatGPT clip (the owner's way, lesson
-- 284: a GIF of this very kit wearing it, rebuilt as the effect alone round its empty shape) FIXED through the kit's
-- middle, so it turns and tilts with the kit, never with the camera, and the kit hides it where it stands (lessons
-- 291, 292); a few small things of the clip's kind drifting round it, before and behind, give it depth from every side
-- (the owner, 2026-11-13). Core, the Alchemist's Satchel: violet light swirling round the bag, red and blue potion drops glowing at
-- its sides, bubbles rising and drops falling round it. Bramble, the Philosopher's Kit: a golden alchemy circle turning
-- round it, a teal star pulsing in the bag, a little flask and a sprout glowing, teal sparkles and gold stars round it,
-- a green light. Legend, the Grand Elixir Pack: a golden halo over the handle, the gem pulsing violet, violet wisps
-- curling up its sides, rainbow bubbles drifting round it, a violet light.

-- (the whole aura in one picture drawn round the kit's empty shape, through its middle, the clip once every 1.5 s.
-- `size`: the picture's side in studs, the kit's height over its share of the picture, as clip_frames.py --fit
-- --height 2.5 prints it, times two)
local function card(texture, size)
	return { name = "aura", texture = texture, size = size }
end

-- (a few small things of the clip's own kind round the kit, before it, behind it and beside it, held to it: from the
-- side, where the card is only a line, they still stand round the kit in depth)
local function motes(name, texture, color, over)
	local piece = {
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 1.2, 1.1, 0.9 },
		rate = 8,
		life = { 1.6, 2.2 },
		size = { { 0, 0 }, { 0.25, 0.15 }, { 0.75, 0.15 }, { 1, 0 } },
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

local SPARKS = { { 0, 0 }, { 0.25, 0.11 }, { 0.75, 0.11 }, { 1, 0 } }
-- (bubbles rising off the bag, swelling a little before they go)
local function bubbles(color)
	return motes("bubbles", "bubble_gloss", color, {
		size = { { 0, 0 }, { 0.2, 0.12 }, { 0.85, 0.15 }, { 1, 0 } },
		speed = { 0.2, 0.4 },
		direction = "Top",
		spread = { 25, 25 },
		lightEmission = 0.2,
	})
end

return {
	id = "aura.weapon_kit",
	name = "Weapon Aura Kit",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 2.5,
	tags = { "weapon", "alchemy", "kit", "held", "bubbles", "potion", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	cards = { card("satchel_aura_flip", 4.08) },
	pieces = {
		bubbles({ { 235, 210, 255 }, { 180, 130, 255 } }),
		-- (a potion drop falling off the bag: the picture's point is up, so it falls as drawn, unturned)
		motes("drops", "droplet_gloss", { { 255, 150, 200 }, { 190, 140, 255 } }, {
			rate = 3,
			life = { 1, 1.4 },
			size = { { 0, 0 }, { 0.2, 0.12 }, { 1, 0.1 } },
			transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
			accel = { 0, -0.6, 0 },
			rotation = { 0, 0 },
			rotSpeed = { 0, 0 },
			lightEmission = 0.2,
			secondary = true,
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			cards = { card("philosopher_aura_flip", 4.7) },
			pieces = {
				motes("sparks", "star_twinkle", { { 215, 255, 245 }, { 110, 230, 210 } }, {
					size = SPARKS,
					lightEmission = 1,
				}),
				motes("stars", "star4_drift", { { 255, 240, 170 }, { 255, 205, 90 } }, {
					rate = 5,
					size = { { 0, 0 }, { 0.25, 0.15 }, { 0.75, 0.15 }, { 1, 0 } },
					lightEmission = 0.8,
					secondary = true,
				}),
			},
			light = { color = { 150, 255, 190 }, brightness = 1.3, range = 8 },
		},
		legend = {
			cards = { card("elixir_aura_flip", 3.8) },
			pieces = {
				bubbles("rainbow"),
				motes("sparks", "star_twinkle", { { 245, 220, 255 }, { 190, 130, 255 } }, {
					size = SPARKS,
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 215, 150, 255 }, brightness = 1.3, range = 9 },
		},
	},
	-- (the preview caught mid-clip, not on its dim first frame)
	markers = { peak = 3.6 },
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "satchel_aura_flip, philosopher_aura_flip, elixir_aura_flip (ChatGPT's GIF of each kit wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit --height 2.5); bubble_gloss, droplet_gloss (ChatGPT for the library); star4_drift (Egg Heist's pack); free Creator Store pack textures (no scripts: star_twinkle)",
		licence = "the owner's own art (drawn for the library by ChatGPT); Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(kitMeshPart, id, { variant = rarity }) while a core, bramble or legend kit is held; VfxLib.detach(handle) when it is put away. The card lies through the kit's middle (its thin side is the mesh's z). Core is cheap (no light), bramble and legend mid with a small light.",
}
