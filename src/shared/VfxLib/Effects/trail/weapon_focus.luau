-- Weapon Focus: the ribbon Goo Lineage's Arcane Focus (a crystal staff, its gem in its head) draws as it is waved, one
-- design per rarity (wood Common, iron Uncommon, core Epic, bramble Mythic, legend Legendary). The game puts it on the
-- focus's MeshPart when a cast or an attack waves it and takes it off as the move ends. The ribbon runs from the
-- staff's upper half out past its gem, solid (ribbon_blade, drawn normal, a dark rim of its own colour) so it reads on
-- snow and on a dark floor, the magic added on top; what is thrown off comes from the gem. Wood: a short birch-brown
-- swing, sawdust puffing off, a pale spark in the gem. Iron: a steel swing, a white glint on the gem, blue needle
-- sparks. Core, the Prism: a rainbow ribbon under twisting ribbons of light, rainbow crystal shards flung off, glints.
-- Bramble, the Mythic Focus: a violet ribbon wound with green vine strands and arcane light, the game's arcane motes
-- and green leaves shaken off, a violet light. Legend, the Astral Scepter: a night-blue ribbon under a band of
-- starlight and a pink nebula, gold stars and small turning galaxies left in the air, twinkles, a starlight glow.
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
		axis = "Y", -- (the game's weapons: the length up the part's Y, the grip at the bottom)
		face = false,
		alpha = 0,
		glow = 0,
		taper = 0.5,
	}, over)
end

-- (things shaken off the gem, left in the air where it passed)
local function shed(name, texture, color, rate, life, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "head",
		box = { 0.6, 0.18, 0.6 },
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

-- (a glint riding the gem, added)
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

-- (a sheet of four pictures: each particle keeps one of them, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "trail.weapon_focus",
	name = "Weapon Focus",
	kind = "trail",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "focus", "staff", "arcane", "magic", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("ribbon_blade", { { 228, 186, 120 }, { 176, 128, 74 }, { 122, 84, 46 } }, 0.4, { 0.5, 1.2 }),
	},
	pieces = {
		shed("sawdust", "dust_ring", { { 230, 206, 160 } }, 6, { 0.45, 0.6 }, 0.9, {
			size = { { 0, 0.5 }, { 1, 1.2 } },
			transparency = { { 0, 0.3 }, { 1, 1 } },
			speed = { 0.2, 0.6 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
		}),
		-- (the wooden focus's dull gem still holds a little magic)
		shed("spark", "glow_dot_small", { { 200, 225, 255 }, { 130, 170, 255 } }, 10, { 0.3, 0.45 }, 0.5, {
			lightEmission = 1,
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				-- (blue-grey steel: the ribbon's dark rim keeps it on snow, its bright line is the edge)
				band("ribbon_blade", { { 220, 232, 250 }, { 130, 152, 190 }, { 80, 95, 125 } }, 0.45, { 0.45, 1.3 }, {
					taper = 0.45,
				}),
			},
			pieces = {
				glint("star_glint_sharp", { { 255, 255, 255 }, { 200, 220, 255 } }, 6, 1.3),
				shed("sparks", "needle_glow", { { 200, 230, 255 }, { 90, 150, 255 } }, 12, { 0.2, 0.32 }, 0.6, {
					box = { 0.3, 0.1, 0.3 },
					speed = { 4, 8 },
					drag = 2,
					orientation = "VelocityParallel",
					rotation = { -90, -90 }, -- (the vertical needle laid along its flight)
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			bands = {
				-- (the Prism: the ribbon runs through the rainbow from the gem back along the swing)
				band("ribbon_blade", "rainbow", 0.5, { 0.4, 1.4 }),
				band("beam_ribbons", { { 255, 255, 255 }, { 215, 240, 255 } }, 0.35, { 0.7, 1.45 }, {
					face = true,
					glow = 1,
					alpha = 0.25,
				}),
			},
			pieces = {
				glint("sparkStar", { { 255, 255, 255 }, { 190, 235, 255 } }, 7, 1.3),
				-- (crystal shards, each passing through the colours as it falls: the swing leaves a scatter of rainbow)
				shed("shards", "shard_flat", "rainbow", 14, { 0.5, 0.7 }, 0.75, {
					speed = { 1, 3 },
					accel = { 0, -6, 0 },
					rotSpeed = { -240, 240 },
					brightness = 1.5,
				}),
				shed("twinkles", "star_twinkle", { { 255, 250, 255 }, { 200, 230, 255 } }, 8, { 0.35, 0.5 }, 0.6, {
					size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } },
					lightEmission = 1,
					secondary = true,
				}),
			},
		},
		bramble = {
			idle = 1, -- (its light is on all through the swing)
			bands = {
				band("ribbon_blade", { { 210, 165, 255 }, { 140, 80, 235 }, { 75, 30, 150 } }, 0.55, { 0.35, 1.45 }, {
					taper = 0.55,
				}),
				-- (vines: green strands wound through the violet, drawn solid)
				band("beam_twist", { { 175, 255, 140 }, { 95, 200, 90 } }, 0.45, { 0.65, 1.5 }, {
					alpha = 0.1,
				}),
				band("arcane_band", { { 235, 200, 255 }, { 185, 120, 255 } }, 0.32, { 0.85, 1.5 }, {
					face = true,
					glow = 1,
					alpha = 0.2,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 240, 255 }, { 200, 140, 255 } }, 6, 1.8),
				-- (the game's own arcane motes, kept as drawn)
				shed("motes", "moteArcane", nil, 10, { 0.45, 0.65 }, 0.8, {
					role = "keep",
					speed = { 0.5, 1.5 },
					lightEmission = 0.5,
				}),
				shed("leaves", "leaves_solid", { { 165, 225, 90 }, { 95, 175, 60 } }, 9, { 0.8, 1.1 }, 0.9, {
					speed = { 0.5, 1.6 },
					accel = { 0, -3, 0 },
					drag = 1.5,
					rotSpeed = { -160, 160 },
					brightness = 1.3,
					flipbook = ONE_OF,
				}),
			},
			light = { color = { 200, 140, 255 }, brightness = 1.6, range = 10 },
		},
		legend = {
			idle = 1,
			bands = {
				-- (the night: deep blue, its bright line a lavender edge)
				band("ribbon_blade", { { 130, 120, 255 }, { 62, 48, 185 }, { 26, 18, 95 } }, 0.6, { 0.3, 1.5 }, {
					taper = 0.55,
				}),
				band("beam_starlight", { { 255, 240, 190 }, { 210, 190, 255 } }, 0.45, { 0.5, 1.5 }, {
					face = true,
					glow = 0.9,
					alpha = 0.1,
				}),
				-- (a pink nebula drifting over it, drawn solid)
				band("beam_smoke_soft", { { 255, 160, 225 }, { 185, 100, 235 } }, 0.5, { 0.75, 1.5 }, {
					face = true,
					alpha = 0.35,
					taper = 0.6,
				}),
			},
			pieces = {
				glint("star_flare", { { 255, 250, 230 }, { 190, 160, 255 } }, 7, 2.2),
				shed("stars", "star_fat", { { 255, 240, 170 }, { 255, 200, 90 } }, 16, { 0.55, 0.75 }, 1, {
					size = { { 0, 0.4 }, { 0.2, 1 }, { 1, 0.5 } },
					speed = { 0.5, 2 },
					rotSpeed = { -120, 120 },
					lightEmission = 0.4,
					brightness = 1.6,
				}),
				-- (small galaxies turning where the gem passed: the scepter's own burst on every swing)
				shed("galaxies", "galaxy_spiral", { { 255, 175, 230 }, { 165, 125, 255 } }, 4, { 0.6, 0.8 }, 1.5, {
					size = { { 0, 0.6 }, { 0.3, 1.5 }, { 1, 1.2 } },
					transparency = { { 0, 0.1 }, { 0.7, 0.2 }, { 1, 1 } },
					speed = { 0.2, 0.6 },
					rotSpeed = { 90, 140 },
					lightEmission = 1, -- (the pack's galaxy is drawn on dark: added, or its square shows)
					brightness = 1.8,
				}),
				shed("twinkles", "star_twinkle", { { 255, 250, 235 }, { 200, 180, 255 } }, 10, { 0.35, 0.55 }, 0.6, {
					size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 170, 140, 255 }, brightness = 2, range = 12 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "ribbon_blade (drawn in code for the library); the owner's arcane motes (moteArcane: Goo Lineage's own, kept as drawn) and spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: glow_dot_small, star_glint_sharp, needle_glow, beam_ribbons, shard_flat, star_twinkle, beam_twist, star_flare, beam_starlight, beam_smoke_soft, star_fat, galaxy_spiral); arcane_band, leaves_solid (ChatGPT for the library); dust_ring (EffectCraft)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the focus's MeshPart (its length up its Y, the gem at the top) as a cast or an attack starts, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the ribbon and what was shed fade. Wood and iron are cheap (one ribbon, two small pieces), core to legend mid; bramble and legend light the fight.",
}
