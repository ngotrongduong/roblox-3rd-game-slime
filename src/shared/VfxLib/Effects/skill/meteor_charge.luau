-- Meteor Charge: the wind-up of skill.meteor_fall (skills wave 3, the owner's "Thiên Thạch Giáng"). The caster's hand
-- is raised and burns orange; high over their head and a little ahead a circle of the night sky opens, standing up
-- like a window in the sky (constellations and shooting stars, violet and orange), and slowly turns, stars twinkle round its rim, and sparks of starlight rain down from it into the
-- raised hand. It follows its host and holds about 1.1 s: a game plays it on the cast and cancels it softly
-- (VfxLib.cancel) as the meteor is called down.
local COSMIC = { { 0, { 255, 220, 170 } }, { 0.5, { 255, 140, 70 } }, { 1, { 170, 80, 255 } } }
local STAR = { { 0, { 255, 245, 220 } }, { 1, { 255, 170, 90 } } }
local VIOLET = { { 0, { 230, 190, 255 } }, { 1, { 150, 70, 255 } } }
-- (the raised right hand, over the head)
local HAND = { 1, 2.9, -0.2 }
-- (the sky circle, high above and a little ahead, standing up: lying flat it was seen edge on from a camera behind
-- and over the caster)
local SKY = { 0, 7, -3.5 }

return {
	id = "skill.meteor_charge",
	name = "Meteor Charge",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "meteor", "cosmic", "star", "sky", "charge", "power_up", "orange", "violet", "character" },
	blend = "additive",
	tintable = false,
	follow = true,
	markers = { full = 1.1, peak = 1 },
	pieces = {
		{
			-- the circle of night sky opening high over the head, slowly turning
			name = "sky",
			texture = "floor_starfall",
			color = { { 0, { 255, 200, 150 } }, { 1, { 200, 130, 255 } } },
			at = "body",
			offset = SKY,
			upright = true,
			locked = true,
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0 }, { 0.35, 5.6 }, { 1, 6 } },
			transparency = { { 0, 0.7 }, { 0.35, 0.1 }, { 1, 0 } },
			rotation = { 0, 0 },
			rotSpeed = { 40, 40 },
			lightEmission = 1,
			brightness = 1.6,
		},
		{
			-- a violet haze behind it
			name = "haze",
			texture = "glow_soft",
			color = VIOLET,
			at = "body",
			offset = SKY,
			upright = true,
			locked = true,
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 2 }, { 0.5, 7 }, { 1, 7.5 } },
			transparency = { { 0, 1 }, { 0.5, 0.55 }, { 1, 0.5 } },
			lightEmission = 1,
			brightness = 1,
			zOffset = -1,
		},
		{
			-- stars twinkling round its rim
			name = "twinkles",
			texture = "star_twinkle",
			color = STAR,
			at = "body",
			offset = SKY,
			shape = "Sphere",
			shapeStyle = "Surface",
			radius = 2.7,
			life = { 0.3, 0.5 },
			size = { { 0, 0 }, { 0.4, 1 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.2 } },
			speed = { 0.05, 0.05 },
			rotation = { -45, 45 },
			lightEmission = 1,
			brightness = 3,
			stream = { from = 0.2, to = 1.1, rate = { 10, 26 } },
		},
		{
			-- sparks of starlight raining down from it into the hand
			name = "starfall",
			texture = "fire_specks",
			color = STAR,
			at = "body",
			offset = { 0.5, 6.2, -2.8 },
			box = { 0.8, 0.05, 0.5 },
			shape = "Box",
			direction = "Bottom",
			orientation = "VelocityParallel",
			life = { 0.25, 0.35 },
			size = { { 0, 0.35 }, { 1, 0.1 } },
			transparency = { { 0, 0.1 }, { 1, 0.3 } },
			speed = { 6, 9 },
			spread = { 8, 8 },
			squash = { { 0, -1 }, { 1, -1 } },
			lightEmission = 1,
			brightness = 3,
			secondary = true,
			stream = { from = 0.3, to = 1.1, rate = { 10, 30 }, ease = "in" },
		},
		{
			-- the raised hand burning orange
			name = "hand",
			texture = "glow_soft",
			color = COSMIC,
			at = "body",
			offset = HAND,
			locked = true,
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0.5 }, { 0.8, 2.6 }, { 1, 3 } },
			transparency = { { 0, 0.9 }, { 0.8, 0.2 }, { 1, 0.15 } },
			lightEmission = 1,
			brightness = 2,
			zOffset = 1,
		},
		{
			-- flames licking up off the hand
			name = "flames",
			texture = "flame_beautiful_flip",
			color = { { 255, 255, 255 } },
			at = "body",
			offset = HAND,
			orientation = "FacingCameraWorldUp",
			direction = "Top",
			life = { 0.35, 0.5 },
			size = { { 0, 0.8 }, { 0.4, 1.4 }, { 1, 0.4 } },
			transparency = { { 0, 0.2 }, { 0.7, 0.4 }, { 1, 1 } },
			speed = { 1, 2 },
			spread = { 15, 15 },
			flipbook = { layout = "Grid8x8", mode = "OneShot" },
			lightEmission = 0.5,
			brightness = 1.6,
			stream = { from = 0.1, to = 1.1, rate = { 8, 20 } },
		},
	},
	light = { color = { 255, 150, 90 }, range = 12, keys = { { 0, 0 }, { 1, 2.6 }, { 1.4, 0 } } },
	source = {
		from = "the library (skills wave 3, 2026-11-08)",
		art = "ChatGPT floor art (floor_starfall); free Creator Store pack textures (no scripts: glow_soft, star_twinkle, fire_specks, flame_beautiful_flip)",
		licence = "ChatGPT output owned by the owner; Creator Store free assets (no scripts kept)",
	},
	notes = "The caster's wind-up for skill.meteor_fall: play it on the cast, cancel it as the meteor is called down or on an interruption.",
}
