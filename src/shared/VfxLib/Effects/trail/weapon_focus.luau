-- Weapon Focus: the arcane ribbon round the gem of Goo Lineage's Arcane Focus (a crystal staff), one rung per rarity
-- (wood Common, iron Uncommon, core Epic, bramble Mythic, legend Legendary). The game puts it on the focus's MeshPart
-- when a cast or an attack waves it and takes it off as the move ends. Only its head draws: a short ribbon the gem
-- leaves as it is waved, motes going round the gem and left behind as a ring of light, and from core up a rune turning
-- about the gem. Wood: a pale blue wisp ribbon. Iron: a steel-blue ribbon and its motes. Core: a ribbon of violet arcane
-- energy edged with lilac wisps, violet motes, the rune. Bramble: violet energy in a green wisp, leaves shaken off.
-- Legend: a band of gold starlight round violet energy and a gold wisp, two rings of motes, a gold rune. (arcane_band
-- is drawn violet-pink: it is tinted only toward violet, the gold is the starlight's.)
local GEM = 3.05 -- studs up the 3.5-stud focus to its gem (the owner's models, the gem in its head)

local function band(texture, colors, life, blade, alpha, glow, taper)
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
	}
end

-- (motes going round the gem; left in the world, they draw the ring it waved)
local function motes(name, texture, color, rate, phase, size)
	return {
		name = name,
		texture = texture,
		color = color,
		orbit = { radius = 0.55, period = 0.5, phase = phase, y = GEM },
		rate = rate,
		life = { 0.25, 0.4 },
		size = { { 0, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } },
		rotation = { 0, 360 },
		lightEmission = 1,
		locked = false,
	}
end

-- (a rune circle turning about the gem, facing the camera)
local function rune(color, size)
	return {
		name = "rune",
		texture = "rune_circle",
		color = color,
		at = "head",
		rate = 3,
		life = { 0.4, 0.4 },
		size = { { 0, size * 0.7 }, { 0.3, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0.3 }, { 0.5, 0.45 }, { 1, 1 } },
		rotation = { 0, 360 },
		rotSpeed = { 160, 160 },
		lightEmission = 1,
		zOffset = -0.5,
	}
end

return {
	id = "trail.weapon_focus",
	name = "Weapon Focus",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "focus", "staff", "arcane", "magic", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("beam_wisp_c", { { 150, 200, 255 }, { 100, 150, 240 } }, 0.22, { 0.72, 1 }, 0.25, 0.8, 0.3),
	},
	pieces = {},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				band("beam_wisp_c", { { 130, 170, 240 }, { 90, 120, 220 } }, 0.22, { 0.72, 1 }, 0.2, 0.9, 0.3),
			},
			pieces = { motes("motes", "glow_dot_small", { { 190, 215, 255 }, { 120, 160, 255 } }, 14, 0, 0.45) },
		},
		core = {
			bands = {
				band("arcane_band", { { 200, 140, 255 }, { 170, 100, 255 } }, 0.26, { 0.7, 1 }, 0.25, 0.9, 0.3),
				band("beam_wisp_c", { { 200, 150, 255 }, { 160, 110, 255 } }, 0.2, { 0.66, 1 }, 0.3, 0.8, 0.3),
			},
			pieces = {
				motes("motes", "sparkStar", { { 225, 180, 255 }, { 170, 90, 255 } }, 14, 0, 0.55),
				rune({ { 230, 190, 255 }, { 160, 90, 255 } }, 1.3),
			},
		},
		bramble = {
			bands = {
				band("arcane_band", { { 190, 150, 255 }, { 160, 100, 255 } }, 0.26, { 0.7, 1 }, 0.2, 1, 0.3),
				band("beam_wisp_c", { { 140, 220, 110 }, { 90, 180, 80 } }, 0.2, { 0.66, 1 }, 0.3, 0.8, 0.3),
			},
			pieces = {
				motes("motes", "sparkStar", { { 190, 245, 160 }, { 120, 210, 90 } }, 14, 0, 0.55),
				rune({ { 210, 255, 190 }, { 150, 100, 255 } }, 1.3),
				{
					name = "leaves",
					texture = "leaves_solid",
					color = { { 150, 215, 80 }, { 90, 170, 60 } },
					at = "head",
					box = { 0.6, 0.15, 0.6 },
					rate = 5,
					life = { 0.5, 0.8 },
					size = { { 0, 0.45 }, { 1, 0.3 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					speed = { 0.4, 1.2 },
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
				band("beam_starlight", { { 255, 205, 100 }, { 255, 175, 60 } }, 0.3, { 0.6, 1 }, 0.3, 0.9, 0.5),
				band("arcane_band", { { 180, 130, 255 }, { 150, 90, 255 } }, 0.28, { 0.74, 1 }, 0.3, 0.9, 0.3),
				band("beam_wisp_c", { { 255, 215, 110 }, { 255, 180, 60 } }, 0.22, { 0.64, 1 }, 0.25, 0.9, 0.3),
			},
			pieces = {
				motes("motes", "sparkStar", { { 255, 230, 160 }, { 255, 200, 90 } }, 12, 0, 0.55),
				motes("violet", "sparkStar", { { 225, 180, 255 }, { 180, 90, 255 } }, 12, 0.5, 0.55),
				rune({ { 255, 235, 170 }, { 200, 120, 255 } }, 1.5),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: beam_wisp_c, beam_starlight, glow_dot_small, rune_circle); arcane_band, leaves_solid (ChatGPT for the library); the owner's spark star (sparkStar, tinted)",
		licence = "Creator Store free assets (no scripts kept); the owner's own art",
	},
	notes = "Attach to the focus's MeshPart (its length up its Y, the gem at the top) as a cast or an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the ribbon and the motes fade. Wood and iron are cheap, core to legend mid (more bands, the same small paint).",
}
