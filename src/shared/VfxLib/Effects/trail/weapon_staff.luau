-- Weapon Staff: the leaf-and-light ribbon from the head of Goo Lineage's Healing Staff, one rung per rarity (wood
-- Common, iron Uncommon, core Epic, bramble Mythic, legend Legendary). The game puts it on the staff's MeshPart when a
-- heal or an attack waves it and takes it off as the move ends. Its head leaves a soft ribbon of light with stars in it
-- and sheds leaves that tumble down where it passed. Wood: a pale ribbon of light. Iron: green-white light and a few
-- leaves. Core: a violet light under a green wisp, leaves and violet motes rising. Bramble: green and gold light, more
-- leaves, fireflies. Legend: a gold-green light, a green wisp and shafts of light, golden leaves, the owner's heal
-- crosses rising and gold twinkles.
local function band(texture, colors, life, blade, alpha, glow, taper, length)
	return {
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y, the grip at the bottom)
		face = false,
		alpha = alpha,
		glow = glow,
		taper = taper,
		length = length,
	}
end

-- (leaves shaken off the head, tumbling down where it passed)
local function leaves(color, rate)
	return {
		name = "leaves",
		texture = "leaves_solid",
		color = color,
		at = "head",
		box = { 0.7, 0.2, 0.7 },
		rate = rate,
		life = { 0.6, 0.9 },
		size = { { 0, 0.5 }, { 1, 0.35 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		speed = { 0.4, 1.2 },
		spread = { 180, 180 },
		accel = { 0, -4, 0 },
		drag = 1,
		rotation = { 0, 360 },
		rotSpeed = { -180, 180 },
		lightEmission = 0.15,
		flipbook = { layout = "Grid2x2", mode = "Random" },
		locked = false,
	}
end

-- (soft lights rising off the head)
local function rising(name, texture, color, rate, size)
	return {
		name = name,
		texture = texture,
		color = color,
		at = "head",
		box = { 0.6, 0.25, 0.6 },
		rate = rate,
		life = { 0.4, 0.7 },
		size = { { 0, 0 }, { 0.25, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } },
		speed = { 0.5, 1.2 },
		spread = { 60, 60 },
		accel = { 0, 2.5, 0 },
		rotation = { 0, 360 },
		lightEmission = 1,
		locked = false,
	}
end

return {
	id = "trail.weapon_staff",
	name = "Weapon Staff",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "staff", "heal", "nature", "leaves", "light", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("beam_starlight", { { 240, 230, 170 }, { 200, 210, 130 } }, 0.24, { 0.68, 1 }, 0.35, 0.7, 0.3, 2.5),
	},
	pieces = {},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				band("beam_starlight", { { 190, 240, 170 }, { 130, 205, 130 } }, 0.24, { 0.68, 1 }, 0.3, 0.8, 0.3, 2.5),
			},
			pieces = { leaves({ { 160, 220, 90 }, { 100, 175, 70 } }, 5) },
		},
		core = {
			bands = {
				band(
					"beam_starlight",
					{ { 200, 150, 255 }, { 160, 100, 255 } },
					0.26,
					{ 0.66, 1 },
					0.25,
					0.9,
					0.3,
					2.5
				),
				band("beam_wisp_b", { { 150, 230, 140 }, { 100, 200, 110 } }, 0.22, { 0.72, 1 }, 0.35, 0.8, 0.4),
			},
			pieces = {
				leaves({ { 160, 220, 90 }, { 100, 175, 70 } }, 6),
				rising("motes", "glow_dot_small", { { 215, 180, 255 }, { 170, 110, 255 } }, 10, 0.5),
			},
		},
		bramble = {
			bands = {
				band("beam_starlight", { { 150, 235, 110 }, { 100, 200, 90 } }, 0.26, { 0.66, 1 }, 0.25, 0.9, 0.3, 2.5),
				band("beam_wisp_b", { { 255, 225, 120 }, { 230, 190, 80 } }, 0.22, { 0.72, 1 }, 0.35, 0.8, 0.4),
			},
			pieces = {
				leaves({ { 150, 225, 80 }, { 80, 170, 60 } }, 9),
				rising("fireflies", "glow_dot_small", { { 230, 255, 150 }, { 180, 240, 90 } }, 10, 0.45),
				rising("glints", "star_glint_small", { { 255, 240, 180 }, { 255, 215, 100 } }, 6, 0.7),
			},
		},
		legend = {
			bands = {
				band("beam_starlight", { { 255, 215, 110 }, { 255, 185, 70 } }, 0.28, { 0.64, 1 }, 0.2, 1, 0.3, 2.5),
				band("beam_wisp_b", { { 130, 235, 140 }, { 80, 200, 110 } }, 0.24, { 0.7, 1 }, 0.3, 0.9, 0.4),
				band("beam_light_shafts", { { 230, 245, 170 }, { 160, 230, 140 } }, 0.3, { 0.55, 1 }, 0.5, 0.8, 0.6),
			},
			pieces = {
				leaves({ { 230, 215, 90 }, { 120, 200, 70 } }, 8),
				{
					-- the owner's heal crosses rising off the head (never recoloured)
					name = "crosses",
					texture = "healCross",
					at = "head",
					box = { 0.6, 0.25, 0.6 },
					rate = 5,
					life = { 0.45, 0.7 },
					size = { { 0, 0 }, { 0.2, 0.55 }, { 1, 0.4 } },
					transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
					speed = { 0.6, 1.2 },
					spread = { 50, 50 },
					accel = { 0, 2, 0 },
					rotation = { 0, 0 },
					lightEmission = 0.4,
					locked = false,
				},
				rising("twinkles", "star_twinkle", { { 255, 240, 180 }, { 255, 210, 90 } }, 8, 0.7),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "the owner's heal cross (healCross, never recoloured); free Creator Store pack textures (no scripts: beam_starlight, beam_wisp_b, beam_light_shafts, glow_dot_small, star_glint_small, star_twinkle); leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the staff's MeshPart (its length up its Y, the head at the top) as a heal or an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the light and the leaves fade. Wood and iron are cheap, core to legend mid (more bands, the same small paint).",
}
