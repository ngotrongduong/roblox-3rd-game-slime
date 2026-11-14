-- Weapon Hit Kit: a plain blow of one of Goo Lineage's alchemy kits, a flask SMASHED on the foe: a splash of liquid, glass
-- and drops flung back, fizz. Drawn normal in a coloured body so it holds on snow. Wood: a red-and-blue splash, drops,
-- dust. Iron: a steel splash, a glint, sparks. Core (Alchemist's Satchel): violet splash, fizzing bubbles, glints.
-- Bramble (Philosopher's Kit): the owner's acid splash and drops, teal bubbles, alchemy signs (clip), a gold circle
-- on the floor. Legend (Grand Elixir): a violet and gold burst, flasks flying (clip), rainbow bubbles, twinkles, a ring.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.18, 0.18 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (the splash: a blot flung open on the foe)
local function splash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.4, 0.4 },
		-- (the ink splat is only a thin dark rim under the potion's own coloured body, see `body`)
		size = { { 0, size * 0.5 }, { 0.2, size * 0.65 }, { 1, size * 0.7 } },
		transparency = { { 0, 0.15 }, { 0.8, 0.3 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.8,
		zOffset = 1,
	}, over)
end

-- (the splash in the potion's colours: a solid fat star drawn normal, over the rim)
local function body(color, size)
	return flash("body", "star_fat", color, size, {
		life = { 0.3, 0.3 },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		lightEmission = 0.15,
		brightness = 1.6,
		zOffset = 1.5,
	})
end

local function spray(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.28, 0.4 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		direction = "Back",
		speed = { 5, 11 },
		spread = { 80, 80 },
		accel = { 0, -12, 0 },
		drag = 2,
		rotation = { 0, 359 },
		lightEmission = 0,
	}, over)
end

local function mark(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		ground = true,
		flat = true,
		count = 1,
		life = { 0.4, 0.4 },
		size = { { 0, size * 0.4 }, { 0.3, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0.05 }, { 0.6, 0.25 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.3,
	}, over)
end

local ONCE = { layout = "Grid4x4", mode = "OneShot" }

local function bubbles(color, count, over)
	return spray(
		"bubbles",
		"glow_dot_small",
		color,
		count,
		0.5,
		with(
			{ direction = "Top", spread = { 70, 70 }, speed = { 2, 6 }, accel = { 0, 4, 0 }, lightEmission = 0.7 },
			over
		)
	)
end

return {
	id = "hit.weapon_kit",
	name = "Weapon Hit Kit",
	kind = "hit",
	tier = "mid",
	host = "any",
	refHeight = 2.2,
	tags = { "weapon", "kit", "alchemy", "flask", "splash", "impact", "rarity", "ladder", "goo_lineage", "snow_safe" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.08 },
	pieces = {
		splash("splash", "splash_dark_flip", { 235, 80, 80 }, 2.2, { flipbook = ONCE }),
		body({ { 235, 70, 70 }, { 90, 120, 235 } }, 3.4),
		spray("drops", "droplet_gloss", { { 220, 80, 80 }, { 90, 130, 235 } }, 8, 0.45, {}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				splash("splash", "splash_dark_flip", { 150, 185, 235 }, 2.5, { flipbook = ONCE }),
				body({ { 90, 150, 235 }, { 50, 110, 220 } }, 3.6),
				spray("sparks", "needle_glow", { { 255, 240, 200 }, { 255, 160, 60 } }, 12, 0.5, {
					life = { 0.15, 0.28 },
					speed = { 8, 15 },
					accel = { 0, 0, 0 },
					drag = 4,
					orientation = "VelocityParallel",
					rotation = { -90, -90 },
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			pieces = {
				splash("splash", "splash_dark_flip", { 185, 110, 255 }, 3, { flipbook = ONCE }),
				body({ { 190, 110, 255 }, { 130, 60, 220 } }, 4.2),
				bubbles({ { 205, 160, 255 }, { 150, 90, 235 } }, 12),
				spray("glints", "sparkStar", { 255, 240, 255 }, 6, 0.5, { lightEmission = 1, accel = { 0, 0, 0 } }),
			},
		},
		bramble = {
			pieces = {
				-- (the owner's acid splash, as drawn)
				splash("acid", "acidSplat", nil, 3.2, { role = "keep" }),
				spray("drops", "acidDrop", nil, 8, 0.55, { role = "keep" }),
				bubbles({ { 120, 235, 205 }, { 60, 180, 160 } }, 10),
				-- (alchemy signs unfold and rise: the clip)
				spray("signs", "alchemy_flip", { 255, 225, 120 }, 3, 1.1, {
					life = { 0.4, 0.4 },
					direction = "Top",
					spread = { 40, 40 },
					speed = { 2, 4 },
					accel = { 0, 0, 0 },
					flipbook = ONCE,
					brightness = 1.4,
				}),
				mark("circle", "rune_circle", { 255, 210, 90 }, 5, { lightEmission = 0.3 }),
			},
			light = { color = { 150, 255, 220 }, keys = { { 0, 0 }, { 0.05, 1.8 }, { 0.35, 0 } }, range = 8 },
		},
		legend = {
			pieces = {
				flash("flare", "star_flare", { 255, 225, 140 }, 3.6, { lightEmission = 0.8 }),
				body({ { 200, 90, 255 }, { 255, 170, 40 } }, 5.2),
				-- (flasks fly out whole and burst: the clip)
				spray("flasks", "flask_flip", { 255, 235, 190 }, 4, 1.1, {
					life = { 0.4, 0.4 },
					speed = { 4, 8 },
					flipbook = ONCE,
					brightness = 1.4,
				}),
				bubbles({ { 255, 140, 200 }, { 140, 220, 255 }, { 255, 235, 120 }, { 170, 255, 170 } }, 14, {
					direction = "Back",
				}),
				spray("twinkles", "star_twinkle", { 255, 245, 200 }, 8, 0.55, {
					lightEmission = 1,
					accel = { 0, 0, 0 },
					speed = { 5, 10 },
				}),
			},
			light = { color = { 215, 170, 255 }, keys = { { 0, 0 }, { 0.05, 3 }, { 0.4, 0 } }, range = 10 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's plain weapon blows (2026-11-14, wave 2 of the game's fight effects)",
		art = "alchemy_flip, flask_flip (ChatGPT clips drawn for the library); the owner's battle art (acidSplat, acidDrop) as drawn; free Creator Store pack textures (no scripts kept: droplet_gloss, star_glint_sharp, needle_glow, glow_dot_small, rune_circle, star_flare, star_twinkle); the owner's spark star (sparkStar); dust_ring (EffectCraft)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play('hit.weapon_kit', CFrame.lookAt(skin, skin + blowDirection), { variant = rarity, scale = foeHeight / 2.2 }): at the foe's skin. 0.3 to 0.4 s. Wood and iron are cheap, core to legend mid; bramble and legend flash a light, bramble marks the floor.",
}
