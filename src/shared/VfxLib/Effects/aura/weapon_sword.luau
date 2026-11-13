-- Weapon Aura Sword: what Goo Lineage's finer swords give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon swords have none). The cheapest of the weapon's layers, for four slimes on a phone:
-- a soft glow on the guard's gem and the rung's motif, drawn solid so it shows on snow. Core, the Runeblade: a violet
-- glow, lilac diamond runes rising off the blade. Bramble, the Dawnbreaker: a pink glow on the gem, a white-gold
-- feather circling the blade, a glint on the point, a warm light. Legend, Sunfire: glints on the gem, small flames
-- licking up the blade, a golden sun turning over the point like a crown, embers, a fire light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft glow of the rung's colour breathing along the blade, from the guard's gem up: the sword seen lit from far)
local function gem(color, size)
	return {
		name = "gem",
		texture = "glow_soft",
		color = color,
		at = "chest",
		box = { 0.15, 1.1, 0.15 },
		rate = 2.5,
		life = { 1.4, 1.8 },
		size = { { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.8 } },
		transparency = { { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } },
		lightEmission = 0.6,
		zOffset = -0.5,
	}
end

-- (small things leaving the blade and staying where it passed: a carried sword draws a faint wake)
local function wake(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "chest",
		box = { 0.3, 0.6, 0.3 },
		rate = rate,
		life = { 1, 1.4 },
		size = { { 0, 0 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
		speed = { 0.2, 0.5 },
		direction = "Top",
		spread = { 25, 25 },
		rotation = { -15, 15 },
		lightEmission = 0,
		brightness = 1.4,
		locked = false,
	}, over)
end

return {
	id = "aura.weapon_sword",
	name = "Weapon Aura Sword",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "sword", "held", "glint", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		gem({ 165, 105, 255 }, 1.8),
		wake("runes", "glyph_rune", { { 235, 215, 255 }, { 170, 120, 255 } }, 3.5, 0.75, { brightness = 1.6 }),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				gem({ 255, 150, 175 }, 2),
				-- (a feather circling the blade, leaving a few behind as it goes round)
				{
					name = "feathers",
					texture = "down_feather",
					color = { { 255, 235, 175 }, { 255, 200, 110 } },
					orbit = { radius = 0.75, period = 2.4, phase = 0, y = 2.4 },
					rate = 7,
					life = { 0.8, 1.1 },
					size = { { 0, 0 }, { 0.2, 0.75 }, { 1, 0.45 } },
					transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
					speed = { 0.1, 0.3 },
					spread = { 180, 180 },
					accel = { 0, -0.6, 0 },
					rotation = { 0, 359 },
					rotSpeed = { -90, 90 },
					lightEmission = 0,
					brightness = 1.3,
					locked = false,
				},
				{
					name = "glint",
					texture = "star_glint_sharp",
					color = { { 255, 250, 230 }, { 255, 210, 110 } },
					at = "head",
					rate = 1.2,
					life = { 0.35, 0.45 },
					size = { { 0, 0 }, { 0.35, 1.5 }, { 1, 0 } },
					rotation = { -20, 20 },
					rotSpeed = { -60, 60 },
					lightEmission = 1,
					zOffset = 1,
				},
			},
			light = { color = { 255, 210, 150 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = {
				with(gem({ 255, 120, 70 }, 1.6), {
					texture = "sparkStar",
					rate = 3,
					life = { 0.4, 0.6 },
					size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } },
					transparency = { { 0, 0 }, { 1, 0.3 } },
					rotSpeed = { -90, 90 },
					lightEmission = 0.6,
					zOffset = 1,
				}),
				wake("flames", "fire_curl_flip", nil, 5, 1, {
					role = "keep",
					life = { 0.55, 0.7 },
					size = { { 0, 0.5 }, { 0.3, 1 }, { 1, 0.7 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					speed = { 0.3, 0.6 },
					brightness = 1.3,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				-- (a golden sun turning over the point: one always there, breathing as the next takes its place)
				{
					name = "sun",
					texture = "glyph_sun",
					color = { 255, 205, 80 },
					at = "crown",
					rate = 1 / 2.2,
					steady = true,
					life = { 2.3, 2.3 },
					size = { { 0, 0.9 }, { 0.15, 1.3 }, { 0.85, 1.3 }, { 1, 1.1 } },
					transparency = { { 0, 1 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 1 } },
					rotation = { 0, 0 },
					rotSpeed = { 25, 25 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 0,
					brightness = 1.6,
				},
				wake("embers", "fire_specks", { { 255, 225, 130 }, { 255, 100, 40 } }, 5, 0.45, {
					life = { 0.6, 0.9 },
					speed = { 0.5, 1 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 255, 140, 70 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "glyph_rune, glyph_sun (drawn in code for the library); free Creator Store pack textures (no scripts: glow_soft, star_glint_sharp, fire_curl_flip, fire_specks); down_feather (ChatGPT for the library); the owner's spark star (sparkStar, tinted)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(swordMeshPart, id, { variant = rarity }) while a core, bramble or legend sword is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
