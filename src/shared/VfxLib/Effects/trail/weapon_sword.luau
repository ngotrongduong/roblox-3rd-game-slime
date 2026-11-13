-- Weapon Sword: the blade arc of Goo Lineage's held swords, one design per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). The game puts it on the sword's MeshPart when an attack swings it and takes
-- it off as the move ends. Each rung is its own sword, and each reads from the far side of a fight on snow or on a
-- dark floor: the ribbon is solid (ribbon_blade, drawn normal, a dark rim of its own colour), the light added on top
-- of it. Wood: a short brown swing, wood chips falling. Iron: a longer steel swing with a bright edge, sparks off the
-- point. Core, the Runeblade: a violet ribbon under a lilac edge, diamond runes left hanging in the arc. Bramble, the
-- Dawnbreaker: two ribbons, gold at the guard and dawn pink at the point, shafts of light, white-gold feathers
-- drifting down, a warm light. Legend, Sunfire: a wide crimson ribbon, a flame band and a white-gold edge, flames
-- thrown off every swing, embers, a sun flare on the point, a fire light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a ribbon laid along the blade, its base and tip shares of the length: `face` false lies flat in the swing)
local function band(texture, colors, life, blade, over)
	return with({
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y, the grip at the bottom)
		face = false,
		alpha = 0,
		glow = 0,
		taper = 0.3,
	}, over)
end

-- (things shed off the upper blade, left in the air where it passed)
local function shed(name, texture, color, rate, life, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "chest",
		box = { 0.3, 0.6, 0.5 },
		rate = rate,
		life = life,
		size = { { 0, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		speed = { 0.4, 1.5 },
		spread = { 180, 180 },
		drag = 3,
		rotation = { 0, 360 },
		lightEmission = 0,
		locked = false,
	}, over)
end

-- (a glint riding the point, added)
local function glint(texture, color, rate, size)
	return {
		name = "glint",
		texture = texture,
		color = color,
		at = "head",
		rate = rate,
		life = { 0.12, 0.18 },
		size = { { 0, 0 }, { 0.3, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.5 } },
		rotation = { -20, 20 },
		rotSpeed = { -90, 90 },
		lightEmission = 1,
		zOffset = 1,
	}
end

return {
	id = "trail.weapon_sword",
	name = "Weapon Sword",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "sword", "slash", "swing", "blade", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("ribbon_blade", { { 214, 150, 80 }, { 160, 104, 52 }, { 110, 70, 36 } }, 0.4, { 0.15, 1.2 }, {
			taper = 0.55,
		}),
	},
	pieces = {
		shed("chips", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 12, { 0.4, 0.6 }, 0.55, {
			speed = { 1.5, 3 },
			accel = { 0, -14, 0 },
			rotSpeed = { -300, 300 },
		}),
		shed("dust", "smoke_soft", { { 222, 200, 160 } }, 6, { 0.45, 0.6 }, 0.9, {
			size = { { 0, 0.5 }, { 1, 1.2 } },
			transparency = { { 0, 0.45 }, { 1, 1 } },
			speed = { 0.2, 0.6 },
			secondary = true,
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				-- (white steel: the ribbon's dark rim keeps it on snow, its bright line is the edge)
				band("ribbon_blade", { { 220, 232, 250 }, { 130, 152, 190 }, { 80, 95, 125 } }, 0.45, { 0.05, 1.3 }, {
					taper = 0.45,
				}),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 255, 255 }, { 210, 225, 255 } }, 6, 1.2),
				shed("sparks", "spark_dot", { { 255, 240, 200 }, { 255, 160, 60 } }, 12, { 0.25, 0.4 }, 0.5, {
					at = "head",
					box = { 0.3, 0.15, 0.3 },
					speed = { 3, 7 },
					drag = 2,
					accel = { 0, -18, 0 },
					lightEmission = 0.7,
				}),
			},
		},
		core = {
			bands = {
				band("ribbon_blade", { { 196, 150, 255 }, { 140, 80, 235 }, { 80, 35, 160 } }, 0.5, { 0, 1.4 }, {
					taper = 0.5,
				}),
				band("streak_slash", { { 255, 245, 255 }, { 215, 180, 255 } }, 0.3, { 0.95, 1.42 }, {
					glow = 1,
					taper = 0.2,
				}),
			},
			pieces = {
				glint("sparkStar", { { 255, 240, 255 }, { 200, 150, 255 } }, 7, 1.1),
				shed("runes", "glyph_rune", { { 235, 215, 255 }, { 175, 125, 255 } }, 10, { 0.6, 0.85 }, 0.7, {
					size = { { 0, 0.3 }, { 0.2, 0.75 }, { 1, 0.5 } },
					speed = { 0.3, 1 },
					accel = { 0, 1.2, 0 },
					rotation = { -15, 15 },
					rotSpeed = { -40, 40 },
					brightness = 1.4,
				}),
				shed("motes", "glow_dot_small", { { 220, 180, 255 }, { 150, 90, 255 } }, 12, { 0.3, 0.5 }, 0.5, {
					lightEmission = 1,
					secondary = true,
				}),
			},
		},
		bramble = {
			idle = 1, -- (its light is on all through the swing)
			bands = {
				band("ribbon_blade", { { 255, 240, 190 }, { 255, 200, 90 }, { 225, 150, 45 } }, 0.55, { 0, 0.78 }, {
					taper = 0.55,
				}),
				band("ribbon_blade", { { 255, 214, 222 }, { 245, 125, 145 }, { 200, 60, 95 } }, 0.55, { 0.72, 1.48 }, {
					taper = 0.55,
				}),
				band("beam_light_shafts", { { 255, 250, 225 }, { 255, 220, 140 } }, 0.4, { 0.2, 1.4 }, {
					face = true,
					glow = 0.8,
					alpha = 0.3,
					taper = 0.5,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 252, 230 }, { 255, 205, 110 } }, 6, 1.8),
				-- (gold enough to hold on snow, where white feathers are lost)
				shed("feathers", "down_feather", { { 255, 235, 175 }, { 255, 205, 110 } }, 9, { 0.9, 1.2 }, 0.95, {
					speed = { 0.5, 1.6 },
					accel = { 0, -1.8, 0 },
					drag = 1.5,
					rotSpeed = { -120, 120 },
					brightness = 1.3,
				}),
				shed("dawn", "sparkStar", { { 255, 245, 215 }, { 255, 170, 170 } }, 8, { 0.5, 0.7 }, 0.6, {
					lightEmission = 0.6,
					brightness = 1.5,
					secondary = true,
				}),
			},
			light = { color = { 255, 215, 150 }, brightness = 1.6, range = 10 },
		},
		legend = {
			idle = 1,
			bands = {
				band("ribbon_blade", { { 255, 120, 70 }, { 230, 45, 40 }, { 150, 15, 35 } }, 0.6, { -0.05, 1.5 }, {
					taper = 0.55,
				}),
				band("beam_flame_soft", { { 255, 215, 110 }, { 255, 120, 40 } }, 0.42, { 0.4, 1.5 }, {
					face = true,
					glow = 0.8,
					alpha = 0.1,
					taper = 0.5,
				}),
				band("streak_slash", { { 255, 252, 225 }, { 255, 215, 120 } }, 0.3, { 0.95, 1.5 }, {
					glow = 1,
					taper = 0.2,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 250, 225 }, { 255, 140, 70 } }, 7, 2.2),
				-- (flames thrown off every swing: full-colour fire, drawn normal so it burns on snow too)
				shed("flames", "fire_curl_flip", nil, 20, { 0.45, 0.6 }, 1.5, {
					role = "keep",
					size = { { 0, 0.8 }, { 0.3, 1.6 }, { 1, 1.2 } },
					speed = { 0.3, 1.2 },
					accel = { 0, 4, 0 },
					rotation = { -20, 20 },
					brightness = 1.3,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				shed("embers", "fire_specks", { { 255, 225, 130 }, { 255, 110, 40 } }, 18, { 0.35, 0.6 }, 0.5, {
					speed = { 1, 3 },
					accel = { 0, 3, 0 },
					lightEmission = 1,
				}),
			},
			light = { color = { 255, 150, 70 }, brightness = 2, range = 12 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "ribbon_blade, glyph_rune (drawn in code for the library); free Creator Store pack textures (no scripts: shard_flat, smoke_soft, star_glint_sharp, spark_dot, streak_slash, glow_dot_small, beam_light_shafts, star_flare, beam_flame_soft, fire_specks, fire_curl_flip); down_feather (ChatGPT for the library); the owner's spark star (sparkStar, tinted)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the sword's MeshPart (its length up its Y, the grip at the bottom) as an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the ribbon and what was shed fade. Wood and iron are cheap (one ribbon, two small pieces), core to legend mid; bramble and legend light the fight.",
}
