-- Weapon Hit Focus: a plain blow of one of Goo Lineage's arcane focuses, a small ARCANE BURST: a flare of the gem
-- bursting open on the foe, a ring of the element, shards and motes of it flung out. Drawn normal in a coloured body so
-- it holds on snow. Wood: a pale blue flare and chips. Iron: a steel ring, a glint, needle sparks. Core (Prism): a
-- rainbow arc, rainbow shards, glints, a gem. Bramble (Mythic Focus): the owner's arcane burst and motes, green leaves,
-- rays, the owner's arcane ring on the floor. Legend (Astral): a gold-white flare, night-blue nebula, gold stars,
-- twinkles, a galaxy turning on the floor.
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

-- (a ring opening out on the foe)
local function ring(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.28, 0.28 },
		size = { { 0, size * 0.25 }, { 0.5, size * 0.85 }, { 1, size } },
		transparency = { { 0, 0.05 }, { 0.5, 0.25 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.5,
		brightness = 1.2,
		zOffset = 0.5,
	}, over)
end

local function spray(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.25, 0.4 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		direction = "Back",
		speed = { 4, 9 },
		spread = { 90, 90 },
		drag = 3,
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

local ONE_OF = { layout = "Grid4x4", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "hit.weapon_focus",
	name = "Weapon Hit Focus",
	kind = "hit",
	tier = "mid",
	host = "any",
	refHeight = 2.2,
	tags = { "weapon", "focus", "arcane", "magic", "impact", "rarity", "ladder", "goo_lineage", "snow_safe" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.06 },
	pieces = {
		flash("flare", "flare_star", { 120, 175, 245 }, 2.2, { lightEmission = 0.6, brightness = 1.3 }),
		spray("chips", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 6, 0.4, {
			accel = { 0, -14, 0 },
			rotSpeed = { -300, 300 },
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				ring("ring", "ring_crisp", { 110, 150, 215 }, 3),
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 1.8),
				spray("sparks", "needle_glow", { { 200, 225, 255 }, { 120, 170, 255 } }, 12, 0.5, {
					life = { 0.15, 0.28 },
					speed = { 8, 15 },
					drag = 4,
					orientation = "VelocityParallel",
					rotation = { -90, -90 },
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			pieces = {
				flash("arc", "arc_rainbow", nil, 3.4, { role = "keep", lightEmission = 0.4, brightness = 1.3 }),
				-- (the prism's glass: shards of every colour of the spectrum)
				spray("shards", "shard_flat", {
					{ 255, 120, 140 },
					{ 255, 210, 90 },
					{ 120, 235, 150 },
					{ 100, 190, 255 },
					{ 200, 140, 255 },
				}, 12, 0.5, { speed = { 6, 12 }, rotSpeed = { -300, 300 }, brightness = 1.3 }),
				spray("glints", "sparkStar", { { 255, 245, 255 }, { 190, 220, 255 } }, 7, 0.55, {
					speed = { 3, 8 },
					lightEmission = 1,
				}),
				-- (a small gem popping off the point, clear of the foe's body)
				ring("gem", "gem_round", { 255, 150, 220 }, 1.4, {
					size = { { 0, 0.5 }, { 0.3, 1.4 }, { 1, 1.1 } },
					transparency = { { 0, 0.1 }, { 0.6, 0.3 }, { 1, 1 } },
				}),
			},
		},
		bramble = {
			pieces = {
				flash("burst", "burstArcane", nil, 3.4, { role = "keep", brightness = 1.2 }),
				spray("motes", "moteArcane", nil, 10, 0.7, { role = "keep", speed = { 3, 8 } }),
				spray("leaves", "leaves_solid", { { 130, 220, 100 }, { 80, 160, 70 } }, 6, 0.6, {
					rotSpeed = { -200, 200 },
					flipbook = ONE_OF,
				}),
				flash("rays", "ring_rays", { 190, 150, 255 }, 4, {
					life = { 0.24, 0.24 },
					size = { { 0, 1.3 }, { 1, 4 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				mark("ring", "ringArcane", nil, 5, { role = "keep" }),
			},
			light = { color = { 180, 140, 255 }, keys = { { 0, 0 }, { 0.05, 2 }, { 0.4, 0 } }, range = 8 },
		},
		legend = {
			pieces = {
				flash("flare", "star_flare", { 255, 235, 150 }, 4, { lightEmission = 0.8 }),
				-- (night-blue nebula, drawn normal: it shows on snow)
				spray("nebula", "smoke_soft", { 60, 70, 160 }, 4, 1.8, {
					size = { { 0, 1.2 }, { 1, 2.8 } },
					transparency = { { 0, 0.15 }, { 1, 1 } },
					speed = { 1, 3 },
					spread = { 180, 180 },
				}),
				spray("stars", "star_fat", { { 255, 225, 110 }, { 230, 235, 255 } }, 8, 0.8, {
					life = { 0.34, 0.4 },
					speed = { 5, 11 },
					spread = { 180, 180 },
					lightEmission = 0.6,
				}),
				spray("twinkles", "star_twinkle", { 255, 250, 210 }, 8, 0.6, {
					lightEmission = 1,
					speed = { 3, 8 },
					spread = { 180, 180 },
				}),
				-- (the pack's galaxy is drawn on dark: added, or its square shows)
				mark("galaxy", "galaxy_spiral", { { 255, 180, 235 }, { 160, 125, 255 } }, 5, {
					rotSpeed = { 120, 120 },
					lightEmission = 1,
					brightness = 2,
				}),
			},
			light = { color = { 190, 180, 255 }, keys = { { 0, 0 }, { 0.05, 3 }, { 0.4, 0 } }, range = 10 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's plain weapon blows (2026-11-14, wave 2 of the game's fight effects)",
		art = "the owner's battle art (burstArcane, moteArcane, ringArcane) as drawn; free Creator Store pack textures (no scripts kept: flare_star, shard_flat, star_glint_sharp, needle_glow, ring_crisp, arc_rainbow, gem_round, leaves_solid, ring_rays, star_flare, smoke_soft, star_fat, star_twinkle, galaxy_spiral); the owner's spark star (sparkStar)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play('hit.weapon_focus', CFrame.lookAt(skin, skin + blowDirection), { variant = rarity, scale = foeHeight / 2.2 }): at the foe's skin. 0.25 to 0.4 s. Wood and iron are cheap, core to legend mid; bramble and legend flash a light and mark the floor.",
}
