-- Weapon Shield: the heavy bash smear of Goo Lineage's held shields, one design per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). The game puts it on the shield's MeshPart when a bash or a block shoves
-- it and takes it off as the move ends. Where a sword cuts a thin flat arc, the shield shoves a wall: a ribbon as tall
-- as the shield and past it, turned to the camera, solid (drawn normal, a dark rim of its own colour) so it holds on
-- snow and on a dark floor, the light added on top. Wood: a brown wall, splinters off the rim, dust off the bottom
-- edge. Iron: a steel wall, a glint on the rim, sparks flying off it. Core, the Warden: a royal blue wall between gold
-- rim lines, little blue-gold crests left hanging, gold specks. Bramble, the Aegis of Goo: a wall of green goo with
-- vines through it and gold rim lines, goo drops falling off, leaves, a green light. Legend, the Royal Bastion: a
-- wide royal blue wall between solid gold lines, shafts of light through it, gold fleurs, banners, castles and crowns
-- rising where it passed, gold specks, a sun-gold light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a wall laid along the shield, its base and top shares of the height: `face` true turns it to the camera)
local function band(texture, colors, life, blade, over)
	return with({
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y)
		face = true, -- (a shove of air as tall as the shield, not a flat blade's arc)
		alpha = 0,
		glow = 0,
		taper = 0.5,
	}, over)
end

-- (things knocked off the shield's face, left in the air where it passed)
local function shed(name, texture, color, rate, life, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 0.8, 0.8, 0.3 },
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

-- (a glint riding the top of the rim, added)
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

-- (a sheet of four small pictures: each particle keeps one of them, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "trail.weapon_shield",
	name = "Weapon Shield",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "shield", "bash", "block", "smear", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("ribbon_blade", { { 214, 160, 96 }, { 160, 110, 58 }, { 112, 74, 38 } }, 0.4, { -0.05, 1.1 }, {
			taper = 0.6,
		}),
	},
	pieces = {
		shed("splinters", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 10, { 0.4, 0.6 }, 0.55, {
			at = "head",
			box = { 0.8, 0.15, 0.4 },
			speed = { 1.5, 3 },
			accel = { 0, -14, 0 },
			rotSpeed = { -300, 300 },
		}),
		-- (dust shoved off the shield's bottom edge, rolling)
		shed("dust", "smoke_soft", { { 222, 200, 160 } }, 6, { 0.45, 0.6 }, 1, {
			at = "feet",
			box = { 0.8, 0.1, 0.4 },
			size = { { 0, 0.6 }, { 1, 1.4 } },
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
				-- (steel blue, not white: the wall's dark rim keeps it on snow, its bright line is the shield's rim)
				band(
					"ribbon_blade",
					{ { 220, 232, 250 }, { 130, 152, 190 }, { 80, 95, 125 } },
					0.45,
					{ -0.05, 1.15 },
					{
						taper = 0.55,
					}
				),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 255, 255 }, { 210, 225, 255 } }, 5, 1.3),
				-- (sparks struck off the rim, flying as streaks)
				shed("sparks", "needle_glow", { { 255, 240, 200 }, { 255, 150, 50 } }, 14, { 0.2, 0.32 }, 0.55, {
					at = "head",
					box = { 0.8, 0.12, 0.4 },
					speed = { 5, 9 },
					drag = 3,
					accel = { 0, -14, 0 },
					orientation = "VelocityParallel",
					rotation = { -90, -90 }, -- (the vertical needle laid along its flight)
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			bands = {
				band("ribbon_blade", { { 130, 180, 255 }, { 55, 105, 235 }, { 25, 50, 145 } }, 0.5, { -0.05, 1.25 }),
				-- (the gold rim lines, top and bottom of the wall, added)
				band("beam_edges", { { 255, 228, 130 }, { 240, 180, 60 } }, 0.32, { -0.05, 1.25 }, {
					glow = 1,
					taper = 0.4,
				}),
			},
			pieces = {
				glint("sparkStar", { { 255, 250, 225 }, { 255, 210, 100 } }, 6, 1.2),
				-- (the Warden's crests left hanging where the shield passed: gold turning to blue as they fade)
				shed("crests", "shield_icon", { { 255, 215, 100 }, { 90, 140, 255 } }, 6, { 0.6, 0.8 }, 1, {
					size = { { 0, 0.5 }, { 0.2, 1 }, { 1, 1.2 } },
					transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
					speed = { 0.2, 0.6 },
					rotation = { -12, 12 },
					brightness = 1.4,
				}),
				shed("specks", "spec_star", { { 255, 240, 190 }, { 255, 200, 80 } }, 12, { 0.4, 0.6 }, 0.5, {
					lightEmission = 1,
					secondary = true,
				}),
			},
		},
		bramble = {
			idle = 1, -- (its light is on all through the shove)
			bands = {
				-- (a wall of green goo: the lava's blobs drawn solid)
				band("beam_lava", { { 170, 245, 100 }, { 80, 200, 60 }, { 35, 130, 40 } }, 0.55, { -0.05, 1.3 }),
				-- (vines twisting through it, dark green)
				band("beam_twist", { { 110, 190, 60 }, { 60, 140, 40 }, { 40, 95, 30 } }, 0.45, { 0, 1.4 }, {
					alpha = 0.05,
				}),
				band("beam_edges", { { 255, 230, 130 }, { 240, 185, 60 } }, 0.3, { -0.05, 1.3 }, {
					glow = 1,
					taper = 0.4,
				}),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 250, 220 }, { 255, 210, 100 } }, 5, 1.4),
				-- (the owner's acid drops falling off the goo, as drawn)
				shed("drops", "acidDrop", nil, 9, { 0.5, 0.7 }, 0.7, {
					role = "keep",
					speed = { 0.5, 1.5 },
					drag = 1,
					accel = { 0, -16, 0 },
					rotation = { 0, 0 },
				}),
				shed("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 7, { 0.7, 0.9 }, 0.75, {
					speed = { 0.5, 1.5 },
					accel = { 0, -3, 0 },
					drag = 1.5,
					rotSpeed = { -150, 150 },
					brightness = 1.2,
					flipbook = ONE_OF,
				}),
			},
			light = { color = { 150, 255, 110 }, brightness = 1.5, range = 10 },
		},
		legend = {
			idle = 1,
			bands = {
				band("ribbon_blade", { { 100, 140, 255 }, { 45, 75, 215 }, { 25, 30, 125 } }, 0.6, { -0.1, 1.45 }, {
					taper = 0.55,
				}),
				-- (solid gold rim lines: gold added on snow is lost, gold drawn holds)
				band("beam_edges", { { 255, 232, 140 }, { 255, 195, 70 }, { 220, 145, 40 } }, 0.45, { -0.1, 1.45 }),
				-- (shafts of light through the wall, added)
				band("beam_light_shafts", { { 255, 245, 210 }, { 255, 210, 110 } }, 0.4, { 0.15, 1.45 }, {
					glow = 0.8,
					alpha = 0.25,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 250, 225 }, { 255, 200, 90 } }, 7, 2.2),
				-- (the Bastion's arms rising where it passed: a fleur-de-lis, a banner, a castle, a crown, each its own)
				shed("arms", "glyph_royal", { { 255, 228, 130 }, { 255, 190, 60 } }, 9, { 0.7, 0.95 }, 1, {
					size = { { 0, 0.4 }, { 0.2, 1.05 }, { 1, 0.85 } },
					speed = { 0.3, 1 },
					accel = { 0, 1.2, 0 },
					rotation = { -10, 10 },
					rotSpeed = { -30, 30 },
					brightness = 1.5,
					flipbook = ONE_OF,
				}),
				shed("specks", "spec_star", { { 255, 245, 200 }, { 255, 205, 80 } }, 14, { 0.4, 0.6 }, 0.55, {
					lightEmission = 1,
				}),
			},
			light = { color = { 255, 215, 120 }, brightness = 2, range = 12 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "ribbon_blade, glyph_royal (drawn in code for the library); free Creator Store pack textures (no scripts: shard_flat, smoke_soft, star_glint_sharp, needle_glow, beam_edges, shield_icon, spec_star, beam_lava, beam_twist, beam_light_shafts, star_flare); leaves_solid (ChatGPT for the library); the owner's acid drop (acidDrop, kept as drawn) and spark star (sparkStar, tinted)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the shield's MeshPart (its length up its Y) as a bash or a block starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the wall and what was shed fade. Wood and iron are cheap (one ribbon, two small pieces), core to legend mid; bramble and legend light the fight.",
}
