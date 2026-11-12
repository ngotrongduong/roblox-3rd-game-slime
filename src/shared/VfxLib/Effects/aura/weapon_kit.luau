-- Weapon Aura Kit: what Goo Lineage's finer Alchemy Kits give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon ones have none). Quiet, for four slimes on a phone: a soft glow of the rung's colour
-- breathes in the bottles, bubbles fizz up out of them and a glint winks on the glass now and then. Core: violet, violet
-- bubbles. Bramble: teal, teal bubbles, the owner's spores drifting out, a glint. Legend: gold, violet bubbles, a drop
-- of the game's acid dripping now and then, gold twinkles and a gold flare on the glass.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (bubbles fizzing up out of the bottles, left where they rose)
local function bubbles(color, rate)
	return {
		name = "bubbles",
		texture = "bubble_gloss",
		color = color,
		at = "chest",
		box = { 0.8, 0.3, 0.7 },
		rate = rate,
		life = { 0.8, 1.2 },
		size = { { 0, 0.15 }, { 0.3, 0.42 }, { 1, 0.3 } },
		transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
		speed = { 0.3, 0.7 },
		spread = { 30, 30 },
		direction = "Top",
		accel = { 0, 1, 0 },
		rotation = { 0, 359 },
		lightEmission = 0.3,
		locked = false,
	}
end

-- (a soft glow of the rung's colour breathing in the bottles: without it, what little is shed reads as nothing)
local function glow(color, size)
	return {
		name = "glow",
		texture = "glow_soft",
		color = color,
		-- (high on the bag and wider than it: inside the bag its own mesh hid the glow)
		at = "chest",
		rate = 1,
		life = { 1.6, 1.6 },
		size = { { 0, size * 0.85 }, { 0.5, size }, { 1, size * 0.85 } },
		transparency = { { 0, 1 }, { 0.5, 0.55 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = -0.5,
	}
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
		life = { 0.25, 0.35 },
		size = { { 0, 0 }, { 0.35, size }, { 1, 0 } },
		rotation = { -20, 20 },
		lightEmission = 1,
		zOffset = 1,
	}
end

return {
	id = "aura.weapon_kit",
	name = "Weapon Aura Kit",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 2.5,
	tags = { "weapon", "alchemy", "kit", "held", "bubbles", "potion", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		glow({ 170, 110, 255 }, 2.8),
		bubbles({ { 220, 170, 255 }, { 190, 130, 255 } }, 3),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				glow({ 90, 220, 190 }, 2.9),
				bubbles({ { 160, 245, 220 }, { 110, 220, 190 } }, 3),
				glint("star_glint_small", { { 255, 250, 225 }, { 255, 215, 110 } }, 1.5, 1.1),
				with(bubbles(nil, 1.2), {
					-- the owner's spores drifting out (never recoloured)
					name = "spores",
					texture = "spore",
					role = "keep",
					size = { { 0, 0.15 }, { 0.3, 0.35 }, { 1, 0.25 } },
					spread = { 180, 180 },
					accel = { 0, 0.3, 0 },
					rotSpeed = { -60, 60 },
					lightEmission = 0.2,
				}),
			},
		},
		legend = {
			pieces = {
				glow({ 255, 190, 80 }, 3),
				bubbles({ { 225, 180, 255 }, { 190, 120, 255 } }, 3),
				glint("star_flare", { { 255, 250, 225 }, { 255, 205, 100 } }, 1.2, 1.3),
				{
					-- a drop of the game's acid dripping from the bag now and then (never recoloured)
					name = "drip",
					texture = "acidDrop",
					role = "keep",
					at = "feet",
					box = { 0.6, 0.05, 0.5 },
					rate = 0.7,
					life = { 0.5, 0.6 },
					size = { { 0, 0.3 }, { 1, 0.22 } },
					transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
					speed = { 0, 0 },
					accel = { 0, -14, 0 },
					rotation = { 0, 0 },
					lightEmission = 0.2,
					locked = false,
				},
				{
					name = "twinkles",
					texture = "star_twinkle",
					color = { { 255, 245, 210 }, { 255, 200, 90 } },
					at = "body",
					box = { 1.1, 0.9, 1.1 },
					rate = 2.5,
					life = { 0.6, 0.9 },
					size = { { 0, 0 }, { 0.3, 0.65 }, { 1, 0 } },
					speed = { 0.1, 0.4 },
					spread = { 180, 180 },
					rotation = { 0, 359 },
					lightEmission = 1,
					locked = false,
				},
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "the owner's acid drop and spores (acidDrop, spore: Goo Lineage's own, kept as drawn); free Creator Store pack textures (no scripts: glow_soft, star_glint_small, star_flare, star_twinkle); bubble_gloss (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(kitMeshPart, id, { variant = rarity }) while a core, bramble or legend kit is held; VfxLib.detach(handle) when it is put away. Core is cheap, bramble and legend mid; no light.",
}
