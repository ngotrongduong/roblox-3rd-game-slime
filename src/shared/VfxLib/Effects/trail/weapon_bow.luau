-- Weapon Bow: the limb streaks of Goo Lineage's held bows, one design per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). The game puts it on the bow's MeshPart as a shot is drawn and loosed and
-- takes it off as the move ends. A bow does not cut: as it swings up to aim and kicks on the loose its two limb tips
-- draw two lines (beam_edges, a band bright at both edges laid along the whole bow, a little past each tip), drawn
-- solid in the rung's colour so they hold on snow, and the air between them shows the rung's motif. Wood: two brown
-- lines, wood chips and dust. Iron: steel lines, glints along the limbs, sparks. Core, Windwhisper: sky-blue lines over
-- a teal wisp of wind, feathers and curling gusts left in the air. Bramble, Starfall: gold lines over a violet band of
-- starlight, gold stars falling from where it passed, twinkles, a violet light. Legend, Moonsong: gold lines and a
-- silver core over a navy band of starlight, silver notes rising, gold crescent moons, a flare on the limb, a moon
-- light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a band laid along the bow, limb tip to limb tip: `face` false lies flat in the swing)
local function band(texture, colors, life, blade, over)
	return with({
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y, limb tip to limb tip)
		face = false,
		alpha = 0,
		glow = 0,
		taper = 0.5,
	}, over)
end

-- (things shed off the limbs, left in the air where the bow passed)
local function shed(name, texture, color, rate, life, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 0.4, 0.95, 0.3 },
		rate = rate,
		life = life,
		size = { { 0, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		speed = { 0.3, 1.2 },
		spread = { 180, 180 },
		drag = 2,
		rotation = { 0, 360 },
		lightEmission = 0,
		locked = false,
	}, over)
end

-- (a glint riding the upper limb's tip, added)
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
	id = "trail.weapon_bow",
	name = "Weapon Bow",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "bow", "shot", "draw", "streak", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("beam_edges", { { 214, 150, 80 }, { 160, 104, 52 }, { 110, 70, 36 } }, 0.4, { -0.05, 1.05 }),
	},
	pieces = {
		shed("chips", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 10, { 0.4, 0.6 }, 0.55, {
			speed = { 1.5, 3 },
			accel = { 0, -14, 0 },
			rotSpeed = { -300, 300 },
		}),
		shed("dust", "smoke_soft", { { 222, 200, 160 } }, 5, { 0.45, 0.6 }, 0.9, {
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
				-- (steel blue-grey, not white: white lines are lost on snow)
				band("beam_edges", { { 220, 232, 250 }, { 130, 152, 190 }, { 80, 95, 125 } }, 0.45, { -0.08, 1.08 }),
			},
			pieces = {
				shed("glints", "star_glint_sharp", { { 255, 255, 255 }, { 200, 220, 255 } }, 8, { 0.14, 0.22 }, 1, {
					size = { { 0, 0 }, { 0.3, 1 }, { 1, 0 } },
					transparency = { { 0, 0 }, { 1, 0.5 } },
					speed = { 0, 0 },
					rotation = { -20, 20 },
					lightEmission = 1,
					locked = true,
					zOffset = 1,
				}),
				shed("sparks", "spark_dot", { { 255, 240, 200 }, { 255, 160, 60 } }, 10, { 0.25, 0.4 }, 0.5, {
					speed = { 3, 6 },
					accel = { 0, -18, 0 },
					lightEmission = 0.7,
				}),
			},
		},
		core = {
			bands = {
				band("beam_edges", { { 160, 225, 255 }, { 60, 160, 235 }, { 30, 95, 175 } }, 0.5, { -0.1, 1.1 }),
				-- (the wind the string swept: a teal wisp between the lines, the light on it added)
				band("beam_wisp_b", { { 150, 235, 240 }, { 60, 190, 210 } }, 0.42, { 0.1, 0.9 }, {
					alpha = 0.15,
					glow = 0.5,
					taper = 0.4,
				}),
			},
			pieces = {
				glint("star_glint_sharp", { { 240, 252, 255 }, { 130, 210, 255 } }, 6, 1.2),
				shed("feathers", "down_feather", { { 175, 230, 255 }, { 90, 180, 240 } }, 10, { 0.8, 1.1 }, 0.8, {
					accel = { 0, -1.8, 0 },
					drag = 1.5,
					rotSpeed = { -120, 120 },
					brightness = 1.3,
				}),
				shed("gusts", "gust_curl", { { 140, 225, 235 }, { 60, 175, 210 } }, 6, { 0.5, 0.7 }, 1.2, {
					size = { { 0, 0.6 }, { 0.3, 1.2 }, { 1, 1.4 } },
					transparency = { { 0, 0.15 }, { 0.6, 0.3 }, { 1, 1 } },
					speed = { 0.4, 1 },
					rotation = { -30, 30 },
					rotSpeed = { -60, 60 },
					brightness = 1.3,
				}),
			},
		},
		bramble = {
			idle = 1, -- (its light is on all through the shot)
			bands = {
				band("beam_edges", { { 255, 225, 130 }, { 255, 190, 70 }, { 215, 140, 40 } }, 0.55, { -0.12, 1.12 }),
				-- (a violet band of starlight between the gold lines, solid with its stars lit)
				band("beam_starlight", { { 185, 130, 255 }, { 130, 70, 235 }, { 80, 40, 170 } }, 0.5, { 0.05, 0.95 }, {
					alpha = 0.1,
					glow = 0.3,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 250, 225 }, { 255, 205, 110 } }, 6, 1.8),
				-- (stars falling from where the bow passed, gold enough to hold on snow)
				shed("stars", "star_fat", { { 255, 225, 120 }, { 255, 170, 60 } }, 10, { 0.6, 0.85 }, 0.85, {
					size = { { 0, 0.4 }, { 0.2, 0.85 }, { 1, 0.5 } },
					speed = { 0.5, 1.5 },
					accel = { 0, -7, 0 },
					drag = 1,
					rotSpeed = { -180, 180 },
					lightEmission = 0.4,
					brightness = 1.5,
				}),
				shed("twinkles", "star_twinkle", { { 240, 220, 255 }, { 175, 120, 255 } }, 10, { 0.35, 0.55 }, 0.6, {
					size = { { 0, 0 }, { 0.25, 0.6 }, { 1, 0 } },
					speed = { 0.2, 0.8 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 200, 160, 255 }, brightness = 1.6, range = 10 },
		},
		legend = {
			idle = 1,
			bands = {
				-- (a navy night between the limbs, the stars in it lit)
				band("beam_starlight", { { 110, 130, 235 }, { 60, 75, 200 }, { 30, 35, 120 } }, 0.6, { -0.05, 1.05 }, {
					glow = 0.3,
					taper = 0.55,
				}),
				band("beam_edges", { { 255, 230, 140 }, { 255, 195, 75 }, { 220, 145, 40 } }, 0.6, { -0.15, 1.15 }, {
					taper = 0.55,
				}),
				-- (the silver core: a bright line through the middle of the bow's sweep)
				band("streak_slash", { { 245, 248, 255 }, { 190, 205, 255 } }, 0.3, { 0.3, 0.7 }, {
					glow = 1,
					taper = 0.2,
				}),
			},
			pieces = {
				glint("star_flare", { { 250, 250, 255 }, { 180, 200, 255 } }, 7, 2.2),
				-- (silver notes rising off the strings, kept still on one of the sheet's four)
				shed("notes", "glyph_notes", { { 215, 225, 255 }, { 150, 170, 255 } }, 10, { 0.7, 0.95 }, 0.9, {
					size = { { 0, 0.4 }, { 0.2, 0.95 }, { 1, 0.7 } },
					speed = { 0.3, 1 },
					accel = { 0, 1.4, 0 },
					rotation = { -15, 15 },
					rotSpeed = { -30, 30 },
					brightness = 1.5,
					flipbook = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true },
				}),
				shed("moons", "crescent_moon", { { 255, 235, 160 }, { 255, 200, 90 } }, 6, { 0.6, 0.8 }, 1.3, {
					size = { { 0, 0.5 }, { 0.25, 1.3 }, { 1, 0.9 } },
					speed = { 0.2, 0.7 },
					accel = { 0, 0.6, 0 },
					rotation = { -30, 30 },
					rotSpeed = { -45, 45 },
					lightEmission = 0.3,
					brightness = 1.5,
				}),
				shed("twinkles", "star_twinkle", { { 250, 250, 255 }, { 190, 205, 255 } }, 10, { 0.35, 0.55 }, 0.6, {
					size = { { 0, 0 }, { 0.25, 0.6 }, { 1, 0 } },
					speed = { 0.2, 0.8 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 175, 195, 255 }, brightness = 2, range = 12 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "glyph_notes (drawn in code for the library); free Creator Store pack textures (no scripts: beam_edges, beam_wisp_b, beam_starlight, streak_slash, shard_flat, smoke_soft, star_glint_sharp, spark_dot, star_flare, star_fat, star_twinkle, crescent_moon); down_feather, gust_curl (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the bow's MeshPart (its length up its Y, limb tip to limb tip) as a shot is drawn, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the lines and what was shed fade. Wood and iron are cheap (one band, two small pieces), core to legend mid; bramble and legend light the fight.",
}
