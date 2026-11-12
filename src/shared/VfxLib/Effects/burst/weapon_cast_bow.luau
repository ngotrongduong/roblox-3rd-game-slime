-- Weapon Cast Bow: the Piercing Shot of Goo Lineage's held bows, one rung per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). Played once at the bow's head (up along the bow, +x toward the shot: the side
-- the owner's limbs bulge to, away from the string) as the arrow is loosed; its pieces sit at the nock, half way down the
-- bow: a flash at the string, streaks of
-- air shot ahead along the arrow's line and a ring of air punched round it, and each rung up adds a layer. Wood: a pale
-- flash and streaks. Iron: steel, the ring of air. Core: sky blue, the bow's feathers flying. Bramble: green streaks, a
-- violet thorned ring, feathers and leaves. Legend: a gold flare, gold streaks and ring, a violet shock ring after it,
-- gold feathers and twinkles, a flash of light.
local NOCK = { 0, -1.6, 0 } -- (studs down the bow from its head to the string's middle: the owner's 3.5-stud bows)

local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the flash at the string as it is loosed)
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		offset = NOCK,
		count = 1,
		life = { 0.16, 0.16 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (streaks of air shot ahead along the arrow's line, lying along their flight)
local function streaks(color, count)
	return {
		name = "streaks",
		texture = "streak_vertical",
		color = color,
		offset = NOCK,
		count = count,
		life = { 0.12, 0.2 },
		size = { { 0, 1.1 }, { 1, 0.35 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		speed = { 28, 42 },
		spread = { 7, 7 },
		direction = "Right",
		orientation = "VelocityParallel",
		-- (VelocityParallel lays a picture's width along its flight: a vertical streak turned a quarter lies along it)
		rotation = { -90, -90 },
		lightEmission = 1,
	}
end

-- (a ring of air punched round the arrow's line, standing across it)
local function ring(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		offset = NOCK,
		count = 1,
		life = { 0.28, 0.28 },
		size = { { 0, width * 0.2 }, { 0.35, width * 0.8 }, { 1, width } },
		transparency = { { 0, 0 }, { 0.4, 0.2 }, { 1, 1 } },
		speed = { 3, 3 },
		spread = { 0, 0 },
		direction = "Right",
		orientation = "VelocityPerpendicular",
		lightEmission = 1,
	}, over)
end

-- (feathers shaken off the limbs, drifting)
local function feathers(color, count)
	return {
		name = "feathers",
		texture = "down_feather",
		color = color,
		offset = NOCK,
		count = count,
		life = { 0.5, 0.8 },
		size = { { 0, 0.55 }, { 1, 0.35 } },
		transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
		speed = { 2, 4 },
		spread = { 180, 180 },
		accel = { 0, -3, 0 },
		drag = 2,
		rotation = { 0, 359 },
		rotSpeed = { -150, 150 },
		lightEmission = 0.3,
	}
end

return {
	id = "burst.weapon_cast_bow",
	name = "Weapon Cast Bow",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "bow", "shot", "pierce", "loose", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.1 },
	pieces = {
		flash("flash", "star_flare", { 236, 206, 160 }, 1.8),
		streaks({ { 255, 235, 200 }, { 220, 180, 120 } }, 6),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				flash("flash", "star_flare", { 205, 222, 245 }, 1.9),
				streaks({ { 255, 255, 255 }, { 180, 200, 235 } }, 8),
				ring("ring", "ring_crisp", { 205, 222, 245 }, 2.4),
			},
		},
		core = {
			pieces = {
				flash("flash", "star_flare_big", { 140, 200, 255 }, 2.2),
				streaks({ { 200, 230, 255 }, { 100, 160, 255 } }, 10),
				ring("ring", "ring_crisp", { 130, 195, 255 }, 2.8),
				feathers({ { 200, 230, 255 }, { 150, 200, 255 } }, 6),
			},
		},
		bramble = {
			pieces = {
				flash("flash", "star_flare_big", { 170, 235, 110 }, 2.3),
				streaks({ { 210, 255, 170 }, { 120, 210, 80 } }, 10),
				ring("ring", "ring_thorned", { 190, 120, 255 }, 3),
				feathers({ { 200, 160, 255 }, { 170, 110, 240 } }, 5),
				with(feathers({ { 150, 215, 80 }, { 90, 170, 60 } }, 5), {
					name = "leaves",
					texture = "leaves_solid",
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				}),
			},
		},
		legend = {
			pieces = {
				flash("flash", "flare_bright", { 255, 205, 100 }, 2.8),
				streaks({ { 255, 235, 170 }, { 255, 190, 80 } }, 12),
				ring("ring", "ring_bright", { 255, 205, 90 }, 3.2),
				ring("shock", "shockwave", { 190, 120, 255 }, 4.2, { delay = 0.05, speed = { 6, 6 } }),
				feathers({ { 255, 225, 150 }, { 190, 120, 255 } }, 6),
				{
					name = "twinkles",
					texture = "star_twinkle",
					color = { { 255, 250, 225 }, { 220, 170, 255 } },
					offset = NOCK,
					count = 8,
					life = { 0.35, 0.6 },
					size = { { 0, 0 }, { 0.25, 0.6 }, { 1, 0 } },
					speed = { 3, 7 },
					spread = { 40, 40 },
					direction = "Right",
					drag = 3,
					rotation = { 0, 359 },
					lightEmission = 1,
				},
			},
			light = { color = { 255, 210, 120 }, keys = { { 0, 0 }, { 0.04, 3 }, { 0.35, 0 } }, range = 8 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: star_flare, star_flare_big, flare_bright, streak_vertical, ring_crisp, ring_thorned, ring_bright, star_twinkle); the owner's shock ring (shockwave, tinted); down_feather, leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept); the owner's own art",
	},
	notes = "VfxLib.play(id, bowHeadCFrame, { variant = rarity }) as the Piercing Shot is loosed: the frame's up along the bow, its +x toward the shot (the owner's bows bulge that way, the string on -x); the pieces sit 1.6 studs down the bow, at the string. Wood and iron are cheap, core to legend mid; only legend has a light.",
}
