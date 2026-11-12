-- Weapon Sword: the blade arc of Goo Lineage's held swords, one rung per rarity (wood Common, iron Uncommon, core Epic,
-- bramble Mythic, legend Legendary). The game puts it on the sword's MeshPart when an attack swings it and takes it off
-- as the move ends: the ribbon is laid along the upper blade only while it moves, and each rung up adds layers. Wood: a
-- pale streak of air. Iron: a steel streak and a glint riding the point. Core: a violet body under a white edge, violet
-- motes left hanging in the arc. Bramble: gold and green, leaves torn off the blade and gold pollen. Legend: a crimson
-- and gold arc, a white-hot edge, a band of starlight round it, embers and twinkles thrown off.
local function band(texture, colors, life, blade, alpha, glow, taper, length)
	return {
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y, the grip at the bottom)
		face = false, -- (a flat ribbon in the swing: the blade's own arc)
		alpha = alpha,
		glow = glow,
		taper = taper,
		length = length,
	}
end

-- (a glint riding the point of the blade)
local function glint(texture, color, rate, size)
	return {
		name = "glint",
		texture = texture,
		color = color,
		at = "head",
		rate = rate,
		life = { 0.12, 0.18 },
		size = { { 0, 0 }, { 0.3, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.6 } },
		rotation = { -20, 20 },
		rotSpeed = { -90, 90 },
		lightEmission = 1,
		zOffset = 1,
	}
end

-- (small things shed off the upper blade: left hanging where it passed, they draw the arc a moment longer)
local function shed(name, texture, color, rate, life, size, more)
	local piece = {
		name = name,
		texture = texture,
		color = color,
		at = "chest",
		box = { 0.25, 0.55, 0.5 },
		rate = rate,
		life = life,
		size = { { 0, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } },
		speed = { 0.3, 1.2 },
		spread = { 180, 180 },
		drag = 3,
		rotation = { 0, 360 },
		lightEmission = 1,
		locked = false,
	}
	for key, value in more or {} do
		piece[key] = value
	end
	return piece
end

return {
	id = "trail.weapon_sword",
	name = "Weapon Sword",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "sword", "slash", "swing", "blade", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("streak_mist", { { 236, 206, 160 }, { 190, 140, 90 } }, 0.14, { 0.3, 1 }, 0.35, 0.5, 0.15),
	},
	pieces = {},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				band("streak_mist", { { 205, 222, 245 }, { 140, 160, 190 } }, 0.16, { 0.28, 1 }, 0.18, 0.8, 0.15),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 255, 255 }, { 200, 220, 255 } }, 7, 1.1),
			},
		},
		core = {
			bands = {
				band(
					"streak_mist",
					{ { 175, 115, 255 }, { 120, 60, 220 }, { 70, 30, 150 } },
					0.2,
					{ 0.25, 1 },
					0.12,
					1,
					0.2
				),
				band("streak_slash", { { 255, 255, 255 }, { 230, 200, 255 } }, 0.12, { 0.5, 1 }, 0, 1, 0.1),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 245, 255 }, { 200, 150, 255 } }, 7, 1.2),
				shed("motes", "sparkStar", { { 225, 180, 255 }, { 160, 90, 255 } }, 16, { 0.3, 0.5 }, 0.65),
			},
		},
		bramble = {
			bands = {
				band(
					"streak_mist",
					{ { 170, 230, 90 }, { 110, 190, 60 }, { 60, 140, 50 } },
					0.22,
					{ 0.25, 1 },
					0.1,
					1,
					0.2
				),
				band("streak_slash", { { 255, 245, 190 }, { 255, 215, 110 } }, 0.13, { 0.5, 1 }, 0, 1, 0.1),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 250, 220 }, { 255, 210, 90 } }, 8, 1.3),
				shed("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 5, { 0.5, 0.8 }, 0.55, {
					size = { { 0, 0.55 }, { 1, 0.4 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					accel = { 0, -5, 0 },
					rotSpeed = { -200, 200 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				}),
				shed("pollen", "glow_dot_small", { { 255, 235, 140 }, { 255, 205, 80 } }, 12, { 0.3, 0.5 }, 0.45),
			},
		},
		legend = {
			bands = {
				band(
					"streak_mist",
					{ { 255, 120, 45 }, { 235, 65, 40 }, { 170, 20, 40 } },
					0.24,
					{ 0.22, 1 },
					0.08,
					1,
					0.2
				),
				band("streak_slash", { { 255, 210, 110 }, { 255, 190, 90 } }, 0.14, { 0.45, 1 }, 0, 1, 0.1),
				band("beam_starlight", { { 255, 150, 60 }, { 255, 100, 50 } }, 0.3, { 0.15, 1 }, 0.6, 0.7, 0.5, 3),
			},
			pieces = {
				glint("star_flare", { { 255, 250, 225 }, { 255, 120, 80 } }, 8, 1.5),
				shed("embers", "fire_specks", { { 255, 210, 110 }, { 255, 90, 40 } }, 18, { 0.3, 0.55 }, 0.55, {
					accel = { 0, 3, 0 },
				}),
				shed("twinkles", "star_twinkle", { { 255, 245, 200 }, { 255, 190, 80 } }, 8, { 0.4, 0.6 }, 0.75, {
					size = { { 0, 0 }, { 0.25, 0.75 }, { 1, 0 } },
				}),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: streak_mist, streak_slash, beam_starlight, star_glint_sharp, star_flare, fire_specks, star_twinkle, glow_dot_small); the owner's spark star (sparkStar, tinted); leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept); the owner's own art",
	},
	notes = "Attach to the sword's MeshPart (its length up its Y, the grip at the bottom) as an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the ribbon and what was shed fade. Wood and iron are cheap, core to legend mid (more bands, the same small paint).",
}
