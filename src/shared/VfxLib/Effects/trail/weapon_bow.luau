-- Weapon Bow: the limb and string streaks of Goo Lineage's held bows, one rung per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). The game puts it on the bow's MeshPart as a shot is drawn and loosed
-- and takes it off as the move ends. A bow does not cut: its two limb tips draw two thin bright lines as it swings up
-- to aim and kicks on the loose, and from core up the air the string swept between them shows as twisting wisps.
-- Wood: two pale lines. Iron: steel lines and glints running along the bow. Core: sky-blue lines over a wisp of string
-- air, and the feathers of its limbs drifting off. Bramble: green lines, a violet wisp, feathers and leaves. Legend: gold lines,
-- a violet wisp, a band of starlight, gold and violet feathers and twinkles.
local function band(texture, colors, life, blade, alpha, glow, taper)
	return {
		texture = texture,
		colors = colors,
		life = life,
		blade = blade,
		axis = "Y", -- (the game's weapons: the length up the part's Y, limb tip to limb tip)
		face = false,
		alpha = alpha,
		glow = glow,
		taper = taper,
	}
end

-- (glints running along the whole bow, limb to limb)
local function glints(texture, color, rate, size)
	return {
		name = "glints",
		texture = texture,
		color = color,
		at = "body",
		box = { 0.3, 0.95, 0.3 },
		rate = rate,
		life = { 0.12, 0.2 },
		size = { { 0, 0 }, { 0.3, size }, { 1, 0 } },
		rotation = { -20, 20 },
		lightEmission = 1,
		zOffset = 1,
	}
end

-- (the feathers of its limbs drifting off where it passed)
local function feathers(color, rate)
	return {
		name = "feathers",
		texture = "down_feather",
		color = color,
		at = "body",
		box = { 0.5, 0.9, 0.3 },
		rate = rate,
		life = { 0.6, 0.9 },
		size = { { 0, 0.5 }, { 1, 0.35 } },
		transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
		speed = { 0.3, 1 },
		spread = { 180, 180 },
		accel = { 0, -2.5, 0 },
		drag = 1,
		rotation = { 0, 360 },
		rotSpeed = { -120, 120 },
		lightEmission = 0.3,
		locked = false,
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
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	bands = {
		band("beam_edges", { { 236, 206, 160 }, { 190, 140, 90 } }, 0.16, { 0.02, 0.98 }, 0.25, 0.6, 0.2),
	},
	pieces = {},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			bands = {
				band("beam_edges", { { 205, 222, 245 }, { 150, 170, 200 } }, 0.16, { 0.02, 0.98 }, 0.15, 0.8, 0.2),
			},
			pieces = { glints("star_glint_small", { { 255, 255, 255 }, { 205, 220, 255 } }, 8, 0.8) },
		},
		core = {
			bands = {
				band("beam_edges", { { 130, 200, 255 }, { 80, 150, 255 } }, 0.18, { 0.02, 0.98 }, 0.1, 1, 0.2),
				band("beam_wisp_b", { { 175, 215, 255 }, { 110, 160, 255 } }, 0.22, { 0.2, 0.8 }, 0.35, 0.8, 0.4),
			},
			pieces = {
				glints("star_glint_small", { { 255, 255, 255 }, { 150, 210, 255 } }, 8, 0.9),
				feathers({ { 200, 230, 255 }, { 150, 200, 255 } }, 5),
			},
		},
		bramble = {
			bands = {
				band("beam_edges", { { 160, 230, 100 }, { 110, 190, 70 } }, 0.18, { 0.02, 0.98 }, 0.1, 1, 0.2),
				band("beam_wisp_b", { { 190, 120, 255 }, { 140, 80, 230 } }, 0.22, { 0.2, 0.8 }, 0.35, 0.8, 0.4),
			},
			pieces = {
				glints("star_glint_small", { { 230, 255, 190 }, { 160, 230, 100 } }, 8, 1),
				feathers({ { 200, 160, 255 }, { 170, 110, 240 } }, 5),
				{
					name = "leaves",
					texture = "leaves_solid",
					color = { { 150, 215, 80 }, { 90, 170, 60 } },
					at = "body",
					box = { 0.5, 0.9, 0.3 },
					rate = 4,
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
				band("beam_edges", { { 255, 210, 100 }, { 255, 170, 60 } }, 0.2, { 0.02, 0.98 }, 0.05, 1, 0.2),
				band("beam_wisp_b", { { 200, 130, 255 }, { 160, 80, 240 } }, 0.24, { 0.2, 0.8 }, 0.3, 0.9, 0.4),
				band("beam_starlight", { { 255, 225, 150 }, { 210, 150, 255 } }, 0.3, { 0.05, 0.95 }, 0.5, 0.8, 0.5),
			},
			pieces = {
				glints("star_flare", { { 255, 250, 225 }, { 255, 205, 90 } }, 8, 1.2),
				feathers({ { 255, 225, 150 }, { 190, 120, 255 } }, 6),
				{
					name = "twinkles",
					texture = "star_twinkle",
					color = { { 255, 250, 225 }, { 220, 170, 255 } },
					at = "body",
					box = { 0.6, 0.95, 0.3 },
					rate = 9,
					life = { 0.35, 0.55 },
					size = { { 0, 0 }, { 0.25, 0.45 }, { 1, 0 } },
					speed = { 0.2, 0.8 },
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
		art = "free Creator Store pack textures (no scripts: beam_edges, beam_wisp_b, beam_starlight, star_glint_small, star_flare, star_twinkle); down_feather, leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Attach to the bow's MeshPart (its length up its Y, limb tip to limb tip) as a shot is drawn, variant = the rarity (wood, iron, core, bramble, legend); VfxLib.detach(handle) as the move ends lets the streaks and the feathers fade. Wood and iron are cheap, core to legend mid (more bands, the same small paint).",
}
