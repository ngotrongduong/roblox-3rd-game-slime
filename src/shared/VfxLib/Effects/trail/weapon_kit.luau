-- Weapon Kit: the swing of Goo Lineage's Alchemy Kit, one design per rarity (wood Common, iron Uncommon, core Epic,
-- bramble Mythic, legend Legendary). The game puts it on the kit's MeshPart when a throw or an attack swings it and
-- takes it off as the move ends. A satchel of potions does not cut: held by its handle (the top), its bag sweeps
-- widest, so its smear faces the camera and is flung out past the bag, from its bottom edge to a bag's height beyond
-- (shares 0.1 down to -1): the wide bag swung about its handle covers the arc it sweeps, so a smear across the bag, or
-- one only half a bag past it, is hidden in it from the game's camera (seen in Studio 2026-11-13). Each rung reads
-- from the far side of a fight on snow or on a dark floor: the smear is solid (drawn normal in the rung's colour), the
-- light added on top of it. Wood: a red and blue potion slosh, drops of both flung and falling, a puff of dust. Iron: a
-- steel swing with a hard edge along the bag's bottom, a glint and sparks off its rivets. Core, the Alchemist's
-- Satchel: a violet slosh under a lilac edge, purple bubbles fizzing up, a fizz of motes, a spark on the glass.
-- Bramble, the Philosopher's Kit: a teal slosh inside gold edges, the four alchemy signs left hanging in the arc, the
-- game's acid dripping, a gold flare, a green light. Legend, the Grand Elixir Pack: a wide violet slosh, a rainbow of
-- elixir ribbons and a bright core, big rainbow bubbles, golden flasks tumbling up, twinkles, a violet light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a smear of potion flung off the bag: its shares from the bag's bottom (0) out past it (below 0) and up to the handle (1))
local function band(texture, colors, life, blade, over)
	return with({
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		-- (the kit is wider than it is tall: its length still up its Y, the handle at the top)
		axis = "Y",
		face = true, -- (a lump swung, not a blade: its smear turned to the camera)
		alpha = 0,
		glow = 0,
		taper = 0.5,
	}, over)
end

-- (things shed off the bag where it passed, left in the air)
local function shed(name, texture, color, rate, life, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 0.8, 0.6, 0.8 },
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

-- (a glint winking on the bag's bottom, where it sweeps fastest, added)
local function glint(texture, color, rate, size)
	return {
		name = "glint",
		texture = texture,
		color = color,
		at = "feet",
		box = { 0.8, 0.1, 0.8 },
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

-- (bubbles fizzing up out of the bottles, left behind as it swings on)
local function bubbles(color, rate, size, over)
	return shed(
		"bubbles",
		"bubble_gloss",
		color,
		rate,
		{ 0.5, 0.8 },
		size,
		with({
			at = "chest",
			box = { 0.7, 0.4, 0.7 },
			size = { { 0, size * 0.4 }, { 0.3, size }, { 1, size * 0.75 } },
			speed = { 0.5, 1.2 },
			spread = { 50, 50 },
			direction = "Top",
			accel = { 0, 3, 0 },
			drag = 1,
			brightness = 1.3,
		}, over)
	)
end

-- (the signs and the flasks are ChatGPT clips: each particle plays its clip once over its life)
local ONCE = { layout = "Grid4x4", mode = "OneShot" }

return {
	id = "trail.weapon_kit",
	name = "Weapon Kit",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 2.5,
	tags = { "weapon", "alchemy", "kit", "potion", "fizz", "bubbles", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		-- (the red potion at the head of the slosh, the blue one trailing)
		band("ribbon_blade", { { 235, 85, 70 }, { 175, 90, 160 }, { 60, 105, 220 } }, 0.4, { 0.05, -0.95 }),
	},
	pieces = {
		-- (drops of both potions flung off the bag, falling)
		shed("drops", "droplet_gloss", { { 240, 90, 75 }, { 70, 120, 235 } }, 12, { 0.4, 0.6 }, 0.55, {
			speed = { 1.5, 3 },
			accel = { 0, -18, 0 },
			rotation = { 0, 0 },
			brightness = 1.2,
		}),
		shed("dust", "smoke_soft", { { 214, 190, 150 } }, 6, { 0.45, 0.6 }, 0.9, {
			at = "feet",
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
				-- (a steel bag swung flat: the ribbon's hard bright edge laid along the bag's bottom, its tip end, and
				-- its dark rim keeps it on snow)
				band("ribbon_blade", { { 220, 232, 250 }, { 130, 152, 190 }, { 80, 95, 125 } }, 0.45, { 0.05, -1 }, {
					face = false,
					taper = 0.45,
				}),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 255, 255 }, { 210, 225, 255 } }, 6, 1.1),
				shed("sparks", "spark_dot", { { 255, 240, 200 }, { 255, 160, 60 } }, 12, { 0.25, 0.4 }, 0.5, {
					at = "feet",
					box = { 0.8, 0.1, 0.8 },
					speed = { 3, 7 },
					drag = 2,
					accel = { 0, -18, 0 },
					lightEmission = 0.7,
				}),
			},
		},
		core = {
			bands = {
				band("ribbon_blade", { { 215, 130, 255 }, { 150, 70, 225 }, { 90, 35, 160 } }, 0.5, { 0.1, -0.95 }),
				-- (a lilac edge along the slosh's far rim, swung flat)
				band("ribbon_blade", { { 245, 225, 255 }, { 200, 160, 255 }, { 140, 90, 220 } }, 0.3, { -0.55, -1 }, {
					face = false,
					taper = 0.3,
				}),
			},
			pieces = {
				bubbles({ { 225, 175, 255 }, { 175, 110, 255 } }, 12, 0.65),
				-- (the fizz: tiny lilac motes racing up out of the bottles)
				shed("fizz", "glow_dot_small", { { 240, 215, 255 }, { 180, 120, 255 } }, 16, { 0.3, 0.5 }, 0.5, {
					at = "chest",
					speed = { 2, 4 },
					spread = { 30, 30 },
					direction = "Top",
					drag = 2,
					lightEmission = 1,
					secondary = true,
				}),
				glint("sparkStar", { { 255, 240, 255 }, { 200, 150, 255 } }, 6, 1),
			},
		},
		bramble = {
			idle = 1, -- (its light is on all through the swing)
			bands = {
				band("ribbon_blade", { { 120, 245, 205 }, { 40, 190, 150 }, { 20, 120, 100 } }, 0.55, { 0.1, -0.95 }),
				-- (gold edges either side of the slosh: the Philosopher's gilt)
				band("beam_edges", { { 255, 230, 140 }, { 255, 195, 70 }, { 215, 145, 40 } }, 0.4, { 0.05, -1 }, {
					taper = 0.55,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 252, 230 }, { 255, 205, 110 } }, 6, 1.6),
				-- (alchemy sigils left hanging in the arc, rising a little, gold on the green: each draws itself, glints,
				-- bursts into bubbles)
				shed("signs", "alchemy_flip", { { 255, 230, 140 }, { 150, 245, 190 } }, 6, { 0.75, 0.95 }, 0.85, {
					size = { { 0, 0.85 }, { 1, 0.8 } },
					speed = { 0.3, 1 },
					accel = { 0, 1.2, 0 },
					rotation = { -15, 15 },
					rotSpeed = { -25, 25 },
					brightness = 1.4,
					flipbook = ONCE,
				}),
				-- (the game's own acid dripping off the bag, kept as drawn)
				shed("acid", "acidDrop", nil, 8, { 0.4, 0.6 }, 0.55, {
					role = "keep",
					at = "feet",
					box = { 0.8, 0.1, 0.8 },
					speed = { 0.5, 1.5 },
					accel = { 0, -20, 0 },
					rotation = { 0, 0 },
				}),
				shed("motes", "glow_dot_small", { { 190, 255, 215 }, { 80, 230, 160 } }, 12, { 0.4, 0.6 }, 0.5, {
					lightEmission = 1,
					accel = { 0, 1.5, 0 },
					secondary = true,
				}),
			},
			light = { color = { 150, 255, 190 }, brightness = 1.6, range = 10 },
		},
		legend = {
			idle = 1,
			bands = {
				band("ribbon_blade", { { 205, 125, 255 }, { 150, 70, 235 }, { 100, 40, 180 } }, 0.6, { 0.15, -1 }, {
					taper = 0.55,
				}),
				-- (the elixir's rainbow, red at the head of the swing through to violet at its tail)
				band(
					"beam_ribbons",
					{ { 255, 110, 110 }, { 255, 215, 95 }, { 110, 230, 150 }, { 110, 170, 255 }, { 205, 125, 255 } },
					0.45,
					{ 0.05, -0.95 },
					{ glow = 0.4, alpha = 0.1 }
				),
				-- (a bright core along the slosh's far rim, added)
				band("streak_slash", { { 255, 252, 230 }, { 255, 225, 150 } }, 0.3, { -0.6, -1 }, {
					glow = 1,
					taper = 0.2,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 250, 225 }, { 255, 190, 230 } }, 7, 2),
				-- (big elixir bubbles, each going round the rainbow as it rises)
				bubbles(
					{ { 255, 130, 130 }, { 255, 220, 110 }, { 120, 235, 160 }, { 120, 175, 255 }, { 210, 140, 255 } },
					14,
					1.3,
					{ life = { 0.6, 0.9 } }
				),
				-- (golden flasks bobbing up out of the pack: each pops up, sloshes, pops its cork, bursts into bubbles)
				shed("flasks", "flask_flip", { { 255, 225, 130 }, { 255, 185, 70 } }, 4, { 0.8, 1 }, 1.15, {
					at = "chest",
					size = { { 0, 1.15 }, { 1, 1.1 } },
					speed = { 1, 2 },
					accel = { 0, 2, 0 },
					rotation = { -15, 15 },
					rotSpeed = { -25, 25 },
					brightness = 1.5,
					flipbook = ONCE,
				}),
				shed("twinkles", "star_twinkle", { { 255, 250, 225 }, { 255, 205, 100 } }, 10, { 0.35, 0.55 }, 0.6, {
					box = { 1, 0.8, 1 },
					size = { { 0, 0 }, { 0.25, 0.6 }, { 1, 0 } },
					speed = { 0.2, 0.8 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 215, 150, 255 }, brightness = 2, range = 12 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "ribbon_blade (ChatGPT for the library: tools/chatgpt/ribbon_cut.py), alchemy_flip, flask_flip (ChatGPT clips: tools/chatgpt/clip_frames.py); the owner's acid drop (acidDrop: Goo Lineage's own, kept as drawn); the owner's spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: beam_edges, beam_ribbons, streak_slash, smoke_soft, star_glint_sharp, spark_dot, glow_dot_small, star_flare, star_twinkle); bubble_gloss, droplet_gloss (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the kit's MeshPart (its length up its Y, the handle at the top, though it is wider than tall; held by the handle, the bag swung below) as a throw or an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the smear and what was shed fade. Wood and iron are cheap (one smear, two small pieces), core to legend mid; bramble and legend light the fight.",
}
