-- Weapon Hit Staff: a plain blow of one of Goo Lineage's healing staffs, a soft THUMP of living light: a bloom opening
-- on the foe, leaves and petals knocked off, rising motes. Drawn normal in a coloured body so it holds on snow. Wood:
-- a pale green bloom, leaves, dust. Iron: a green ring, a glint, needle sparks. Core (Enchanted): violet flare, sparkles,
-- motes, a soft ring. Bramble (Lifebloom): rays, teal-and-pink blossoms, the owner's petals clip, a ring. Legend
-- (Everbloom): golden leaves, daisies, a lily blooming on the floor, a ring of rays.
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
		life = { 0.28, 0.4 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		direction = "Back",
		speed = { 3, 8 },
		spread = { 80, 80 },
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

local function leaves(color, count, over)
	return spray(
		"leaves",
		"leaves_solid",
		color,
		count,
		0.65,
		with({ rotSpeed = { -220, 220 }, accel = { 0, -4, 0 }, flipbook = ONE_OF }, over)
	)
end

return {
	id = "hit.weapon_staff",
	name = "Weapon Hit Staff",
	kind = "hit",
	tier = "mid",
	host = "any",
	refHeight = 2.2,
	tags = { "weapon", "staff", "bloom", "leaves", "impact", "rarity", "ladder", "goo_lineage", "snow_safe" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.06 },
	pieces = {
		flash("bloom", "star_flare", { 150, 215, 120 }, 2.1, { lightEmission = 0.5, brightness = 1.3 }),
		leaves({ { 140, 200, 90 }, { 95, 150, 60 } }, 7),
		spray("dust", "dust_ring", { 228, 215, 175 }, 2, 1.1, {
			size = { { 0, 0.9 }, { 1, 2.2 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			speed = { 0.5, 1 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				ring("ring", "ring_crisp", { 110, 200, 130 }, 3),
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 1.8),
				spray("sparks", "needle_glow", { { 220, 255, 210 }, { 130, 230, 140 } }, 12, 0.5, {
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
				flash("flare", "star_flare", { 175, 110, 245 }, 3, { lightEmission = 0.7 }),
				ring("ring", "ring_soft", { 190, 130, 255 }, 4, { brightness = 1.3 }),
				spray("sparkles", "sparkStar", { { 255, 235, 255 }, { 200, 150, 255 } }, 9, 0.55, {
					speed = { 4, 9 },
					lightEmission = 1,
				}),
				spray("motes", "glow_dot_small", { 215, 170, 255 }, 8, 0.45, {
					direction = "Top",
					spread = { 60, 60 },
					speed = { 2, 5 },
					accel = { 0, 3, 0 },
					lightEmission = 0.8,
				}),
			},
		},
		bramble = {
			pieces = {
				flash("rays", "nova_rays", { 130, 235, 200 }, 4.2, {
					life = { 0.24, 0.24 },
					size = { { 0, 1.3 }, { 1, 4.2 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				spray("blossoms", "blossom_five", { { 255, 160, 200 }, { 110, 225, 195 } }, 6, 0.85, {
					life = { 0.34, 0.4 },
					rotSpeed = { -180, 180 },
					accel = { 0, -3, 0 },
					brightness = 1.2,
				}),
				-- (the owner's petals drift down as a clip)
				spray("petals", "petals_small_flip", nil, 6, 0.8, {
					role = "keep",
					life = { 0.38, 0.4 },
					flipbook = { layout = "Grid4x4", mode = "Loop", fps = { 8, 12 } },
				}),
				ring("ring", "ring_crisp", { 120, 225, 190 }, 4.6),
			},
			light = { color = { 170, 255, 215 }, keys = { { 0, 0 }, { 0.05, 1.8 }, { 0.35, 0 } }, range = 8 },
		},
		legend = {
			pieces = {
				leaves({ { 255, 215, 90 }, { 215, 160, 40 } }, 8, { brightness = 1.3 }),
				spray(
					"daisies",
					"daisy_colour",
					nil,
					6,
					0.8,
					{ role = "keep", life = { 0.34, 0.4 }, accel = { 0, -3, 0 } }
				),
				flash("rays", "ring_rays", { 255, 225, 120 }, 5, {
					life = { 0.26, 0.26 },
					size = { { 0, 1.5 }, { 1, 5 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				spray("sparkles", "sparkStar", { 255, 240, 170 }, 10, 0.55, { speed = { 4, 10 }, lightEmission = 1 }),
				-- (a lily blooming on the floor under the foe)
				mark("blossom", "blossom_five", { 255, 245, 200 }, 4.6, {
					size = { { 0, 1.5 }, { 0.4, 4.6 }, { 1, 4.8 } },
					rotSpeed = { 30, 30 },
				}),
			},
			light = { color = { 255, 230, 140 }, keys = { { 0, 0 }, { 0.05, 3 }, { 0.4, 0 } }, range = 10 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's plain weapon blows (2026-11-14, wave 2 of the game's fight effects)",
		art = "the owner's battle art (petals_small_flip, daisy_colour) as drawn; free Creator Store pack textures (no scripts kept: star_flare, leaves_solid, star_glint_sharp, needle_glow, ring_crisp, ring_soft, glow_dot_small, nova_rays, blossom_five, ring_rays); the owner's spark star (sparkStar); dust_ring (EffectCraft)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play('hit.weapon_staff', CFrame.lookAt(skin, skin + blowDirection), { variant = rarity, scale = foeHeight / 2.2 }): at the foe's skin. 0.25 to 0.4 s. Wood and iron are cheap, core to legend mid; bramble and legend flash a light, legend blooms on the floor.",
}
