-- Weapon Staff: the sweep of Goo Lineage's Healing Staffs, one design per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). The game puts it on the staff's MeshPart when a heal or an attack waves it
-- and takes it off as the move ends. A staff swings by its head, so its ribbon runs from the upper shaft out past the
-- head; each rung is its own staff and reads from the far side of a fight on snow or on a dark floor: the ribbon is
-- solid (ribbon_blade, drawn normal, a dark rim of its own colour), the light added on top of it. Wood: a short brown
-- sweep, green leaves shaken off, a puff of dust. Iron: a longer steel sweep, a twinkle on the head, orange sparks.
-- Core, the Enchanted staff: a violet ribbon under twisting ribbons of light and a gold edge, violet sparkles left
-- hanging in the arc, gold motes. Bramble, Lifebloom: two ribbons, teal at the shaft and blossom pink past the head,
-- a soft wisp, pink blossoms and petals drifting down, a cool light. Legend, Everbloom: a wide gold ribbon, a green
-- wisp and a bright edge, golden leaves and blooming flowers thrown off every swing, daisies, a gold light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a ribbon laid along the staff, its base and tip shares of the length: `face` false lies flat in the swing)
local function band(texture, colors, life, blade, over)
	return with({
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y, the head at the top)
		face = false,
		alpha = 0,
		glow = 0,
		taper = 0.5,
	}, over)
end

-- (things shed off the head, left in the air where it passed)
local function shed(name, texture, color, rate, life, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "head",
		box = { 0.6, 0.4, 0.6 },
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

-- (a glint riding the head, added)
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

-- (a sheet of four leaves: each particle keeps one of them, still)
local ONE_LEAF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "trail.weapon_staff",
	name = "Weapon Staff",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "staff", "heal", "nature", "leaves", "light", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("ribbon_blade", { { 210, 155, 90 }, { 158, 108, 58 }, { 108, 72, 38 } }, 0.4, { 0.45, 1.25 }, {
			taper = 0.55,
		}),
	},
	pieces = {
		shed("leaves", "leaves_solid", { { 150, 205, 80 }, { 95, 155, 55 } }, 8, { 0.6, 0.9 }, 0.55, {
			speed = { 1, 2.5 },
			accel = { 0, -6, 0 },
			drag = 1.5,
			rotSpeed = { -240, 240 },
			brightness = 1.2,
			flipbook = ONE_LEAF,
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
				-- (blue-grey steel, not white: the ribbon's dark rim keeps it on snow, its bright line is the edge)
				band("ribbon_blade", { { 220, 232, 250 }, { 130, 152, 190 }, { 80, 95, 125 } }, 0.45, { 0.35, 1.35 }, {
					taper = 0.45,
				}),
			},
			pieces = {
				glint("star_twinkle", { { 255, 255, 255 }, { 200, 220, 255 } }, 6, 1.3),
				-- (sparks struck off the iron-shod head, streaking along their flight)
				shed("sparks", "needle_glow", { { 255, 240, 200 }, { 255, 150, 50 } }, 10, { 0.25, 0.35 }, 0.55, {
					box = { 0.3, 0.2, 0.3 },
					speed = { 4, 8 },
					drag = 2,
					accel = { 0, -16, 0 },
					orientation = "VelocityParallel",
					rotation = { -90, -90 }, -- (the vertical needle laid along its flight)
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			bands = {
				band("ribbon_blade", { { 205, 160, 255 }, { 150, 90, 240 }, { 90, 40, 170 } }, 0.5, { 0.3, 1.4 }),
				-- (twisting ribbons of light over it, the Enchanted staff's own)
				band("beam_ribbons", { { 255, 205, 255 }, { 200, 130, 255 } }, 0.38, { 0.55, 1.45 }, {
					face = true,
					glow = 0.6,
					alpha = 0.15,
				}),
				band("beam_edges", { { 255, 235, 160 }, { 255, 200, 90 } }, 0.3, { 0.95, 1.45 }, {
					glow = 0.8,
					taper = 0.2,
				}),
			},
			pieces = {
				glint("sparkStar", { { 255, 240, 255 }, { 200, 150, 255 } }, 7, 1.2),
				shed("sparkles", "star_twinkle", { { 255, 225, 255 }, { 195, 135, 255 } }, 14, { 0.5, 0.8 }, 0.7, {
					size = { { 0, 0.3 }, { 0.2, 0.75 }, { 1, 0.4 } },
					speed = { 0.3, 1 },
					accel = { 0, 1, 0 },
					rotSpeed = { -60, 60 },
					lightEmission = 0.6,
					brightness = 1.5,
				}),
				shed("motes", "glow_dot_small", { { 255, 232, 150 }, { 255, 195, 90 } }, 10, { 0.3, 0.5 }, 0.5, {
					lightEmission = 1,
					secondary = true,
				}),
			},
		},
		bramble = {
			idle = 1, -- (its light is on all through the swing)
			bands = {
				band("ribbon_blade", { { 175, 250, 225 }, { 70, 200, 170 }, { 25, 130, 115 } }, 0.55, { 0.2, 0.95 }, {
					taper = 0.55,
				}),
				band(
					"ribbon_blade",
					{ { 255, 215, 230 }, { 245, 130, 175 }, { 200, 70, 125 } },
					0.55,
					{ 0.88, 1.48 },
					{
						taper = 0.55,
					}
				),
				band("beam_wisp_b", { { 230, 255, 245 }, { 140, 240, 205 } }, 0.4, { 0.4, 1.45 }, {
					face = true,
					glow = 0.6,
					alpha = 0.2,
				}),
			},
			pieces = {
				glint("star_flare", { { 240, 255, 250 }, { 150, 240, 210 } }, 6, 1.8),
				-- (Lifebloom: pink blossoms left turning in the air where the head passed, drifting down)
				shed("blossoms", "blossom_five", { { 255, 190, 215 }, { 245, 135, 178 } }, 8, { 0.9, 1.2 }, 0.95, {
					speed = { 0.4, 1.2 },
					accel = { 0, -1.5, 0 },
					drag = 1.5,
					rotSpeed = { -90, 90 },
					brightness = 1.3,
				}),
				shed("petals", "petals_small_flip", { { 255, 205, 225 }, { 255, 155, 192 } }, 12, { 0.7, 1 }, 0.6, {
					speed = { 0.6, 1.8 },
					accel = { 0, -1.2, 0 },
					drag = 1.5,
					brightness = 1.3,
					flipbook = { layout = "Grid4x4", mode = "Loop", fps = { 8, 12 } },
					secondary = true,
				}),
			},
			light = { color = { 200, 255, 225 }, brightness = 1.5, range = 10 },
		},
		legend = {
			idle = 1,
			bands = {
				band("ribbon_blade", { { 255, 240, 170 }, { 255, 195, 70 }, { 205, 140, 30 } }, 0.6, { 0.15, 1.5 }, {
					taper = 0.55,
				}),
				band("beam_wisp_b", { { 200, 255, 175 }, { 90, 215, 110 } }, 0.42, { 0.45, 1.5 }, {
					face = true,
					glow = 0.7,
					alpha = 0.1,
				}),
				band("streak_slash", { { 255, 252, 225 }, { 255, 225, 140 } }, 0.3, { 0.95, 1.5 }, {
					glow = 1,
					taper = 0.2,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 252, 225 }, { 255, 210, 100 } }, 7, 2.2),
				-- (Everbloom: golden leaves thrown off every swing, each one still, turning as it falls)
				shed("leaves", "leaves_solid", { { 255, 222, 95 }, { 228, 165, 40 } }, 16, { 0.8, 1.1 }, 1.2, {
					speed = { 0.8, 2.2 },
					accel = { 0, -3, 0 },
					drag = 1.5,
					rotSpeed = { -200, 200 },
					brightness = 1.3,
					flipbook = ONE_LEAF,
				}),
				-- (flowers opening in the arc: the staff's lily blooming as it passes)
				shed("blooms", "flower_bloom_flip", { { 255, 250, 220 }, { 255, 215, 110 } }, 6, { 0.55, 0.7 }, 1.5, {
					size = { { 0, 0.6 }, { 0.3, 1.6 }, { 1, 1.3 } },
					speed = { 0.2, 0.8 },
					rotation = { -20, 20 },
					lightEmission = 0.2,
					brightness = 1.4,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				shed("daisies", "daisy_colour", nil, 4, { 0.9, 1.2 }, 0.8, {
					role = "keep",
					speed = { 0.5, 1.5 },
					accel = { 0, -2, 0 },
					drag = 1.5,
					rotSpeed = { -120, 120 },
					secondary = true,
				}),
			},
			light = { color = { 255, 225, 140 }, brightness = 2, range = 12 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "ribbon_blade (ChatGPT for the library: tools/chatgpt/ribbon_cut.py); free Creator Store pack textures (no scripts: smoke_soft, star_twinkle, needle_glow, beam_ribbons, beam_edges, glow_dot_small, beam_wisp_b, star_flare, petals_small_flip, streak_slash, flower_bloom_flip); leaves_solid, blossom_five, daisy_colour (ChatGPT for the library); the owner's spark star (sparkStar, tinted)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the staff's MeshPart (its length up its Y, the head at the top) as a heal or an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the ribbon and what was shed fade. Wood and iron are cheap (one ribbon, two small pieces), core to legend mid; bramble and legend light the fight.",
}
