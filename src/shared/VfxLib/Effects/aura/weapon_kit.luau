-- Weapon Aura Kit: what Goo Lineage's finer Alchemy Kits give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon ones have none). The cheapest of the weapon's layers, for four slimes on a phone: a
-- soft glow of the rung's colour breathing in the bottles and the rung's motif, drawn solid so it shows on snow. Core,
-- the Alchemist's Satchel: a violet glow, purple bubbles fizzing up. Bramble, the Philosopher's Kit: a green glow, the
-- four alchemy signs going round the bag, the game's acid dripping now and then, a gold glint, a green light. Legend,
-- the Grand Elixir Pack: a gold glow, rainbow bubbles circling over the bag, a golden flask standing over it like a
-- crown, twinkles on the glass, a violet light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft glow of the rung's colour breathing in the bottles: high on the bag and wider than it, so its mesh does not
-- hide it)
local function glow(color, size)
	return {
		name = "glow",
		texture = "glow_soft",
		color = color,
		at = "chest",
		box = { 0.6, 0.3, 0.6 },
		rate = 2,
		life = { 1.4, 1.8 },
		size = { { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.8 } },
		transparency = { { 0, 1 }, { 0.5, 0.4 }, { 1, 1 } },
		lightEmission = 0.6,
		zOffset = -0.5,
	}
end

-- (bubbles fizzing up out of the bottles, left where they rose)
local function bubbles(color, rate, size, over)
	return with({
		name = "bubbles",
		texture = "bubble_gloss",
		color = color,
		at = "chest",
		box = { 0.8, 0.3, 0.7 },
		rate = rate,
		life = { 0.9, 1.3 },
		size = { { 0, size * 0.35 }, { 0.3, size }, { 1, size * 0.7 } },
		transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
		speed = { 0.3, 0.7 },
		spread = { 30, 30 },
		direction = "Top",
		accel = { 0, 1, 0 },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.3,
		locked = false,
	}, over)
end

-- (a glint winking on the glass)
local function glint(texture, color, rate, size)
	return {
		name = "glint",
		texture = texture,
		color = color,
		at = "body",
		box = { 0.9, 0.7, 0.9 },
		rate = rate,
		life = { 0.3, 0.4 },
		size = { { 0, 0 }, { 0.35, size }, { 1, 0 } },
		rotation = { -20, 20 },
		rotSpeed = { -60, 60 },
		lightEmission = 1,
		zOffset = 1,
	}
end

-- (each particle keeps one of the four signs of the sheet, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

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
	pieces = {
		glow({ 170, 110, 255 }, 2.6),
		bubbles({ { 225, 175, 255 }, { 175, 110, 255 } }, 3.5, 0.65),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				glow({ 90, 225, 170 }, 2.8),
				-- (the four alchemy signs going round the bag, leaving a few behind as they go)
				{
					name = "signs",
					texture = "glyph_alchemy",
					color = { { 255, 230, 140 }, { 150, 245, 190 } },
					orbit = { radius = 0.9, period = 3, phase = 0, y = 1.6 },
					rate = 3,
					life = { 0.9, 1.2 },
					size = { { 0, 0 }, { 0.2, 0.7 }, { 1, 0.45 } },
					transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
					speed = { 0.1, 0.3 },
					spread = { 180, 180 },
					accel = { 0, 0.5, 0 },
					rotation = { -15, 15 },
					lightEmission = 0,
					brightness = 1.4,
					locked = false,
					flipbook = ONE_OF,
				},
				{
					-- a drop of the game's acid dripping from the bag now and then (kept as drawn)
					name = "drip",
					texture = "acidDrop",
					role = "keep",
					at = "feet",
					box = { 0.6, 0.05, 0.5 },
					rate = 0.9,
					life = { 0.5, 0.6 },
					size = { { 0, 0.5 }, { 1, 0.4 } },
					transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
					speed = { 0, 0 },
					accel = { 0, -14, 0 },
					rotation = { 0, 0 },
					lightEmission = 0,
					locked = false,
				},
				glint("star_glint_sharp", { { 255, 250, 225 }, { 255, 210, 110 } }, 1.2, 1.3),
			},
			light = { color = { 150, 255, 190 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = {
				glow({ 255, 195, 90 }, 2.8),
				-- (rainbow elixir bubbles circling over the bag, each going round the rainbow as it rises)
				{
					name = "bubbles",
					texture = "bubble_gloss",
					color = {
						{ 255, 130, 130 },
						{ 255, 220, 110 },
						{ 120, 235, 160 },
						{ 120, 175, 255 },
						{ 210, 140, 255 },
					},
					orbit = { radius = 0.85, period = 2.6, phase = 0, y = 2.4 },
					rate = 6,
					life = { 1, 1.3 },
					size = { { 0, 0.2 }, { 0.25, 0.75 }, { 1, 0.5 } },
					transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
					speed = { 0.2, 0.4 },
					spread = { 180, 180 },
					accel = { 0, 0.8, 0 },
					rotation = { 0, 359 },
					lightEmission = 0,
					brightness = 1.3,
					locked = false,
				},
				-- (a golden flask standing over the bag like a crown: one always there, breathing as the next takes its
				-- place)
				{
					name = "flask",
					texture = "glyph_flask",
					color = { 255, 210, 90 },
					at = "crown",
					rate = 1 / 2.2,
					steady = true,
					life = { 2.3, 2.3 },
					size = { { 0, 0.85 }, { 0.15, 1.2 }, { 0.85, 1.2 }, { 1, 1 } },
					transparency = { { 0, 1 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 1 } },
					rotation = { -8, 8 },
					rotSpeed = { -6, 6 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 0,
					brightness = 1.6,
				},
				with(glint("star_twinkle", { { 255, 250, 225 }, { 255, 200, 90 } }, 2.5, 0.7), {
					name = "twinkles",
					life = { 0.6, 0.9 },
					speed = { 0.1, 0.4 },
					spread = { 180, 180 },
					locked = false,
					secondary = true,
				}),
			},
			light = { color = { 215, 150, 255 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "glyph_alchemy, glyph_flask (drawn in code for the library); the owner's acid drop (acidDrop: Goo Lineage's own, kept as drawn); free Creator Store pack textures (no scripts: glow_soft, star_glint_sharp, star_twinkle); bubble_gloss (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(kitMeshPart, id, { variant = rarity }) while a core, bramble or legend kit is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
