-- Weapon Kit: the bottle glints and fizz of Goo Lineage's Alchemy Kit, one rung per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). The game puts it on the kit's MeshPart when a throw or an attack swings
-- it and takes it off as the move ends. A satchel of potions does not cut: its swing leaves a smear of potion goo in
-- blobs, glints wink on its bottles, and it fizzes, bubbles rising and drops flung off where it passed. Wood: a red and
-- blue smear. Iron: a steel-blue smear, glints on the bottles. Core: a violet smear and a misty edge, bubbles fizzing up. Bramble: teal and
-- green, bubbles and drops flung. Legend: violet goo under a gold mist, a band of starlight, glints, bubbles, drops and
-- twinkles.
local function band(texture, colors, life, blade, alpha, glow, taper)
	return {
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		-- (the kit is wider than it is tall: its length still up its Y, the handle at the top; it hangs from the hand, so
		-- the bag's bottom sweeps widest and the goo is flung a little past it: shares below 0)
		axis = "Y",
		face = true, -- (a lump swung, not a blade: its smear turned to the camera)
		alpha = alpha,
		glow = glow,
		taper = taper,
	}
end

-- (glints winking on the bottles, riding the kit)
local function glints(texture, color, rate, size)
	return {
		name = "glints",
		texture = texture,
		color = color,
		at = "body",
		box = { 0.9, 0.6, 0.9 },
		rate = rate,
		life = { 0.12, 0.2 },
		size = { { 0, 0 }, { 0.3, size }, { 1, 0 } },
		rotation = { -20, 20 },
		lightEmission = 1,
		zOffset = 1,
	}
end

-- (bubbles fizzing up out of the kit, left behind as it swings on)
local function bubbles(color, rate)
	return {
		name = "bubbles",
		texture = "bubble_gloss",
		color = color,
		at = "chest",
		box = { 0.7, 0.4, 0.7 },
		rate = rate,
		life = { 0.4, 0.7 },
		size = { { 0, 0.15 }, { 0.3, 0.4 }, { 1, 0.3 } },
		transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
		speed = { 0.5, 1.2 },
		spread = { 50, 50 },
		accel = { 0, 3, 0 },
		rotation = { 0, 360 },
		lightEmission = 0.3,
		locked = false,
	}
end

-- (drops flung off as it swings, falling)
local function drops(color, rate)
	return {
		name = "drops",
		texture = "droplet_gloss",
		color = color,
		at = "body",
		box = { 0.8, 0.5, 0.8 },
		rate = rate,
		life = { 0.3, 0.5 },
		size = { { 0, 0.3 }, { 1, 0.2 } },
		transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
		speed = { 1.5, 3 },
		spread = { 180, 180 },
		accel = { 0, -20, 0 },
		rotation = { 0, 0 },
		lightEmission = 0.3,
		locked = false,
	}
end

return {
	id = "trail.weapon_kit",
	name = "Weapon Kit",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 2.5,
	tags = { "weapon", "alchemy", "kit", "potion", "fizz", "bubbles", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("beam_lava", { { 255, 120, 100 }, { 100, 150, 255 } }, 0.22, { -0.3, 0.7 }, 0.35, 0.6, 0.5),
	},
	pieces = {},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				band("beam_lava", { { 130, 170, 255 }, { 255, 130, 110 } }, 0.22, { -0.3, 0.7 }, 0.3, 0.7, 0.5),
			},
			pieces = { glints("star_glint_small", { { 255, 255, 255 }, { 210, 230, 255 } }, 8, 0.8) },
		},
		core = {
			bands = {
				band("beam_lava", { { 210, 120, 255 }, { 140, 70, 220 } }, 0.24, { -0.3, 0.7 }, 0.3, 0.8, 0.5),
				band("streak_mist", { { 220, 170, 255 }, { 160, 100, 255 } }, 0.18, { -0.2, 0.55 }, 0.3, 0.8, 0.3),
			},
			pieces = {
				glints("star_glint_small", { { 255, 250, 255 }, { 220, 170, 255 } }, 8, 0.9),
				bubbles({ { 220, 170, 255 }, { 190, 130, 255 } }, 9),
			},
		},
		bramble = {
			bands = {
				band("beam_lava", { { 100, 230, 200 }, { 60, 180, 120 } }, 0.24, { -0.3, 0.7 }, 0.3, 0.8, 0.5),
				band("streak_mist", { { 160, 245, 220 }, { 80, 200, 170 } }, 0.18, { -0.2, 0.55 }, 0.3, 0.8, 0.3),
			},
			pieces = {
				glints("star_glint_small", { { 255, 250, 225 }, { 255, 215, 110 } }, 8, 1),
				bubbles({ { 160, 245, 220 }, { 110, 220, 190 } }, 9),
				drops({ { 130, 235, 190 }, { 80, 200, 140 } }, 7),
			},
		},
		legend = {
			bands = {
				band("beam_lava", { { 190, 110, 255 }, { 150, 70, 230 } }, 0.26, { -0.3, 0.7 }, 0.3, 0.85, 0.5),
				band("streak_mist", { { 255, 200, 90 }, { 255, 175, 60 } }, 0.2, { -0.2, 0.55 }, 0.3, 0.9, 0.3),
				band("beam_starlight", { { 255, 205, 110 }, { 200, 140, 255 } }, 0.3, { -0.35, 0.8 }, 0.55, 0.7, 0.6),
			},
			pieces = {
				glints("star_flare", { { 255, 250, 225 }, { 255, 205, 100 } }, 8, 1.1),
				bubbles({ { 225, 180, 255 }, { 190, 120, 255 } }, 9),
				drops({ { 255, 230, 160 }, { 200, 120, 255 } }, 6),
				{
					name = "twinkles",
					texture = "star_twinkle",
					color = { { 255, 250, 225 }, { 255, 205, 100 } },
					at = "body",
					box = { 1, 0.8, 1 },
					rate = 7,
					life = { 0.35, 0.55 },
					size = { { 0, 0 }, { 0.25, 0.4 }, { 1, 0 } },
					speed = { 0.2, 0.8 },
					spread = { 180, 180 },
					rotation = { 0, 360 },
					lightEmission = 1,
					locked = false,
				},
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: beam_lava, streak_mist, beam_starlight, star_glint_small, star_flare, star_twinkle); bubble_gloss, droplet_gloss (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the kit's MeshPart (its length up its Y, the handle at the top, though it is wider than tall; held by the handle, the bag swung below) as a throw or an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the smear, the bubbles and the drops fade. Wood and iron are cheap, core to legend mid (more bands, the same small paint).",
}
