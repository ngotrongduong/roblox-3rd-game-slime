-- Weapon Shield: the heavy bash smear of Goo Lineage's held shields, one rung per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). The game puts it on the shield's MeshPart when a bash or a block shoves
-- it and takes it off as the move ends. Where a sword cuts a thin arc, the shield shoves a wall of air: a rolling fog
-- as tall as the shield, facing the camera, slower to fade. Wood: a smear of dust-pale air. Iron: grey air and sparks
-- struck off the rim. Core: a violet smear between two bright rim lines, little ward shields left floating. Bramble:
-- gold and green, its rim lines gold, leaves and green wards. Legend: a gold and blue smear, its rim lines gold, shafts
-- of holy light through it, gold wards and star specks.
local function band(texture, colors, life, blade, alpha, glow, taper)
	return {
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y)
		face = true, -- (a shove of air turned to the camera, not a flat blade's arc)
		alpha = alpha,
		glow = glow,
		taper = taper,
	}
end

-- (sparks struck off the top of the rim, falling)
local function sparks(color, rate)
	return {
		name = "sparks",
		texture = "spark_dot",
		color = color,
		at = "head",
		box = { 0.8, 0.1, 0.4 },
		rate = rate,
		life = { 0.2, 0.35 },
		size = { { 0, 0.28 }, { 1, 0 } },
		speed = { 2, 5 },
		spread = { 180, 180 },
		accel = { 0, -18, 0 },
		lightEmission = 1,
		locked = false,
	}
end

-- (little ward shields left floating where the shield passed, growing as they fade)
local function wards(color, rate, size)
	return {
		name = "wards",
		texture = "shield_icon",
		color = color,
		at = "body",
		box = { 0.7, 0.7, 0.3 },
		rate = rate,
		life = { 0.35, 0.5 },
		size = { { 0, size * 0.6 }, { 1, size } },
		transparency = { { 0, 0.15 }, { 0.6, 0.35 }, { 1, 1 } },
		speed = { 0.2, 0.6 },
		spread = { 180, 180 },
		rotation = { -15, 15 },
		lightEmission = 1,
		locked = false,
	}
end

return {
	id = "trail.weapon_shield",
	name = "Weapon Shield",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "shield", "bash", "block", "smear", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("beam_fog", { { 236, 206, 160 }, { 190, 140, 90 } }, 0.22, { 0.08, 0.92 }, 0.35, 0.6, 0.6),
	},
	pieces = {},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				band("beam_fog", { { 185, 200, 225 }, { 140, 155, 180 } }, 0.22, { 0.08, 0.92 }, 0.3, 0.75, 0.6),
			},
			pieces = { sparks({ { 255, 250, 220 }, { 255, 180, 90 } }, 12) },
		},
		core = {
			bands = {
				band("beam_fog", { { 160, 120, 255 }, { 100, 60, 220 } }, 0.24, { 0.08, 0.92 }, 0.3, 0.8, 0.6),
				band("beam_edges", { { 215, 195, 255 }, { 160, 120, 255 } }, 0.16, { 0.05, 0.95 }, 0.1, 1, 0.4),
			},
			pieces = {
				sparks({ { 240, 230, 255 }, { 160, 120, 255 } }, 10),
				wards({ { 205, 180, 255 }, { 150, 100, 255 } }, 5, 1.2),
			},
		},
		bramble = {
			bands = {
				band("beam_fog", { { 130, 205, 80 }, { 90, 170, 60 } }, 0.25, { 0.08, 0.92 }, 0.3, 0.8, 0.6),
				band("beam_edges", { { 255, 225, 120 }, { 230, 180, 60 } }, 0.16, { 0.05, 0.95 }, 0.1, 1, 0.4),
			},
			pieces = {
				sparks({ { 255, 245, 200 }, { 255, 200, 80 } }, 10),
				wards({ { 180, 245, 140 }, { 110, 200, 80 } }, 4, 1.2),
				{
					name = "leaves",
					texture = "leaves_solid",
					color = { { 150, 215, 80 }, { 90, 170, 60 } },
					at = "body",
					box = { 0.8, 0.8, 0.3 },
					rate = 6,
					life = { 0.5, 0.8 },
					size = { { 0, 0.55 }, { 1, 0.4 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					speed = { 0.5, 1.5 },
					spread = { 180, 180 },
					accel = { 0, -5, 0 },
					rotation = { 0, 360 },
					rotSpeed = { -200, 200 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
					locked = false,
				},
			},
		},
		legend = {
			bands = {
				band("beam_fog", { { 255, 175, 50 }, { 90, 130, 255 } }, 0.26, { 0.08, 0.92 }, 0.3, 0.8, 0.6),
				band("beam_edges", { { 255, 205, 90 }, { 255, 180, 60 } }, 0.18, { 0.05, 0.95 }, 0.05, 1, 0.4),
				band("beam_light_shafts", { { 100, 140, 255 }, { 80, 110, 255 } }, 0.3, { 0, 1 }, 0.5, 0.7, 0.8),
			},
			pieces = {
				sparks({ { 255, 250, 220 }, { 255, 200, 90 } }, 10),
				wards({ { 255, 225, 130 }, { 120, 160, 255 } }, 5, 1.3),
				{
					name = "specks",
					texture = "spec_star",
					color = { { 255, 250, 230 }, { 255, 215, 110 } },
					at = "body",
					box = { 0.9, 0.9, 0.3 },
					rate = 10,
					life = { 0.35, 0.6 },
					size = { { 0, 0 }, { 0.25, 0.45 }, { 1, 0 } },
					speed = { 0.3, 1 },
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
		art = "free Creator Store pack textures (no scripts: beam_fog, beam_edges, beam_light_shafts, spark_dot, shield_icon, spec_star); leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the shield's MeshPart (its length up its Y) as a bash or a block starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the smear and what was shed fade. Wood and iron are cheap, core to legend mid (more bands, the same small paint).",
}
