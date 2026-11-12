-- Weapon Cast Kit: the Acid Rain of Goo Lineage's Alchemy Kit, one rung per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). Played once at the kit's head (its top, up along it) as the potion is thrown
-- up: a splat of the game's own green acid bursts out of the kit and its drops are flung up high, to come down as the
-- rain, and each rung up adds a layer. Wood: the splat and a few drops. Iron: more drops, glints off the bottles. Core:
-- the acid ring, violet bubbles fizzing up. Bramble: the acid's big burst, the owner's spores puffed out, teal bubbles.
-- Legend: the burst and the splat after it, the ring, the most drops, violet bubbles and gold twinkles, a green flash
-- of light. The acid is the owner's art, kept as drawn: the rung's colour is in what comes with it.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the owner's acid pictures, kept as drawn)
local function splat(name, texture, size, over)
	return with({
		name = name,
		texture = texture,
		role = "keep",
		count = 1,
		life = { 0.35, 0.35 },
		size = { { 0, size * 0.45 }, { 0.2, size }, { 1, size * 1.15 } },
		transparency = { { 0, 0 }, { 0.55, 0.15 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.3,
		zOffset = 1,
	}, over)
end

-- (drops of acid flung up high, falling back: the rain to come)
local function drops(count)
	return {
		name = "drops",
		texture = "acidDrop",
		role = "keep",
		count = count,
		life = { 0.5, 0.75 },
		size = { { 0, 0.5 }, { 1, 0.35 } },
		transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
		speed = { 11, 16 },
		spread = { 30, 30 },
		direction = "Top",
		accel = { 0, -30, 0 },
		rotation = { 0, 0 },
		lightEmission = 0.2,
		-- (drawn over the splat: the owner's acid is opaque and hid everything thrown with it)
		zOffset = 2,
	}
end

-- (bubbles fizzing up out of the kit)
local function bubbles(color, count)
	return {
		name = "bubbles",
		texture = "bubble_gloss",
		color = color,
		count = count,
		life = { 0.45, 0.75 },
		size = { { 0, 0.15 }, { 0.3, 0.45 }, { 1, 0.3 } },
		transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
		speed = { 3, 5 },
		spread = { 60, 60 },
		direction = "Top",
		accel = { 0, 3, 0 },
		drag = 2,
		rotation = { 0, 359 },
		lightEmission = 0.3,
		zOffset = 2,
	}
end

return {
	id = "burst.weapon_cast_kit",
	name = "Weapon Cast Kit",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "alchemy", "kit", "acid", "rain", "potion", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.2 },
	pieces = {
		splat("splat", "acidSplat", 1.9),
		drops(6),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				splat("splat", "acidSplat", 2.1),
				drops(8),
				{
					name = "glints",
					texture = "star_glint_small",
					color = { { 255, 255, 255 }, { 210, 230, 255 } },
					count = 3,
					life = { 0.15, 0.25 },
					size = { { 0, 0 }, { 0.3, 0.9 }, { 1, 0 } },
					rotation = { -20, 20 },
					lightEmission = 1,
					zOffset = 2,
				},
			},
		},
		core = {
			pieces = {
				splat("splat", "acidSplat", 2.2),
				-- (the ring wide of the splat, which covered a ring as wide as itself)
				splat("ring", "ringAcid", 5.4, {
					life = { 0.4, 0.4 },
					size = { { 0, 1 }, { 0.35, 4.4 }, { 1, 5.4 } },
					zOffset = 0,
				}),
				drops(10),
				bubbles({ { 220, 170, 255 }, { 190, 130, 255 } }, 8),
			},
		},
		bramble = {
			pieces = {
				splat("burst", "burstAcid", 2.6),
				splat("ring", "ringAcid", 5.8, {
					life = { 0.4, 0.4 },
					size = { { 0, 1 }, { 0.35, 4.8 }, { 1, 5.8 } },
					zOffset = 0,
				}),
				drops(10),
				bubbles({ { 160, 245, 220 }, { 110, 220, 190 } }, 8),
				{
					-- the owner's spores puffed out (never recoloured)
					name = "spores",
					texture = "spore",
					role = "keep",
					count = 8,
					life = { 0.5, 0.8 },
					size = { { 0, 0.2 }, { 0.3, 0.45 }, { 1, 0.3 } },
					transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } },
					speed = { 2, 4 },
					spread = { 180, 180 },
					drag = 2,
					rotation = { 0, 359 },
					rotSpeed = { -90, 90 },
					lightEmission = 0.2,
					zOffset = 2,
				},
			},
		},
		legend = {
			pieces = {
				splat("burst", "burstAcid", 2.8),
				splat("splat", "acidSplat", 2.3, { delay = 0.06 }),
				splat("ring", "ringAcid", 6.2, {
					life = { 0.45, 0.45 },
					size = { { 0, 1 }, { 0.35, 5.2 }, { 1, 6.2 } },
					zOffset = 0,
				}),
				drops(12),
				bubbles({ { 225, 180, 255 }, { 190, 120, 255 } }, 8),
				{
					name = "twinkles",
					texture = "star_twinkle",
					color = { { 255, 245, 200 }, { 255, 200, 90 } },
					count = 8,
					life = { 0.4, 0.65 },
					size = { { 0, 0 }, { 0.25, 0.6 }, { 1, 0 } },
					speed = { 2, 5 },
					spread = { 180, 180 },
					drag = 2,
					rotation = { 0, 359 },
					lightEmission = 1,
					zOffset = 2,
				},
			},
			light = { color = { 150, 255, 120 }, keys = { { 0, 0 }, { 0.06, 2.5 }, { 0.5, 0 } }, range = 8 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "the owner's acid splat, burst, ring and drop and spores (acidSplat, burstAcid, ringAcid, acidDrop, spore: Goo Lineage's own, kept as drawn); free Creator Store pack textures (no scripts: star_glint_small, star_twinkle); bubble_gloss (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, kitHeadCFrame, { variant = rarity }) as the Acid Rain potion is thrown (the frame at the kit's top, up along it): the drops fly up, the game's rain falls after. Wood and iron are cheap, core to legend mid; only legend has a light.",
}
