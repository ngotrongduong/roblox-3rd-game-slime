-- Renewal Charge: the wind-up of skill.renewal_rain (the heal for many). The caster lifts both hands to the sky and
-- calls the rain: drops of light rise from the ground round them, faster and faster, into a cloud of mint light that
-- gathers over their head and turns; motes are drawn up into it and stars twinkle in it, while ripples run out over
-- the ground at their feet as if rain were already falling. Its look is a rain run backwards (drops going UP into a
-- cloud), not the sanctuary's floor flower. It follows its host and holds about 1.1 s: a game plays it on the cast
-- and cancels it softly (VfxLib.cancel) as the rain begins.
local RAIN = { { 0, { 235, 255, 250 } }, { 0.5, { 150, 245, 210 } }, { 1, { 90, 220, 170 } } }
local MINT = { { 0, { 230, 255, 235 } }, { 1, { 130, 235, 180 } } }
local GOLD = { { 0, { 255, 250, 225 } }, { 1, { 255, 220, 140 } } }
-- (the cloud gathering over the raised hands)
local CLOUD = { 0, 4.6, 0 }

return {
	id = "skill.renewal_charge",
	name = "Renewal Charge",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "heal", "rain", "water", "nature", "charge", "power_up", "green", "aqua", "support", "character" },
	blend = "additive",
	tintable = false,
	follow = true,
	markers = { full = 1.1, peak = 1 },
	pieces = {
		{
			-- drops of light rising from the ground round the caster, faster and faster
			name = "drops",
			texture = "drop_glow",
			color = RAIN,
			at = "ground",
			radius = 2.4,
			shape = "Disc",
			direction = "Top",
			orientation = "VelocityParallel",
			-- (its height along the flight, lesson 112; turned this way its round end leads, its tail below it: a drop
			-- going UP)
			rotation = { -90, -90 },
			life = { 0.45, 0.6 },
			size = { { 0, 0.6 }, { 0.6, 0.75 }, { 1, 0.3 } },
			transparency = { { 0, 0.6 }, { 0.2, 0.1 }, { 1, 0.5 } },
			speed = { 9, 13 },
			lightEmission = 1,
			brightness = 2.5,
			stream = { from = 0.05, to = 1.1, rate = { 14, 40 }, ease = "in" },
		},
		{
			-- the cloud of mint light gathering over the head
			name = "cloud",
			texture = "glow_soft_big",
			color = MINT,
			at = "body",
			offset = CLOUD,
			locked = true,
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0.8 }, { 0.8, 3.2 }, { 1, 3.5 } },
			transparency = { { 0, 0.95 }, { 0.7, 0.45 }, { 1, 0.4 } },
			lightEmission = 1,
			brightness = 1.4,
		},
		{
			-- ... turning, a swirl of light in it
			name = "swirl",
			texture = "halo_swirl",
			color = RAIN,
			at = "body",
			offset = CLOUD,
			locked = true,
			count = 1,
			delay = 0.15,
			life = { 1.15, 1.15 },
			size = { { 0, 0.6 }, { 0.75, 2.6 }, { 1, 2.9 } },
			transparency = { { 0, 0.9 }, { 0.6, 0.25 }, { 1, 0.2 } },
			rotation = { 0, 0 },
			rotSpeed = { 120, 120 },
			lightEmission = 1,
			brightness = 1.8,
			zOffset = 0.5,
		},
		{
			-- motes drawn up into the cloud
			name = "motes",
			texture = "glow_dot",
			color = GOLD,
			at = "body",
			offset = CLOUD,
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Inward",
			radius = 2.4,
			life = { 0.4, 0.5 },
			size = { { 0, 0.1 }, { 0.5, 0.3 }, { 1, 0.1 } },
			transparency = { { 0, 0.4 }, { 0.3, 0 }, { 1, 0.1 } },
			speed = { 6, 7 },
			lightEmission = 1,
			brightness = 3,
			stream = { from = 0.2, to = 1.1, rate = { 10, 26 }, ease = "in" },
		},
		{
			-- ripples running out over the ground at the feet, as if the rain were already falling
			name = "ripples",
			texture = "ring_wave",
			color = RAIN,
			at = "ground",
			flat = true,
			life = { 0.6, 0.6 },
			size = { { 0, 1 }, { 1, 6.5 } },
			transparency = { { 0, 0.15 }, { 0.6, 0.5 }, { 1, 1 } },
			lightEmission = 1,
			brightness = 1.8,
			zOffset = 0.2,
			bursts = { { 0.15, 1 }, { 0.55, 1 }, { 0.9, 1 } },
		},
		{
			-- stars twinkling in the cloud
			name = "twinkles",
			texture = "star_twinkle",
			color = GOLD,
			at = "body",
			offset = CLOUD,
			shape = "Sphere",
			radius = 1.8,
			life = { 0.25, 0.4 },
			size = { { 0, 0 }, { 0.4, 0.8 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.2 } },
			speed = { 0.05, 0.05 },
			rotation = { -45, 45 },
			lightEmission = 1,
			brightness = 3,
			secondary = true,
			stream = { from = 0.3, to = 1.1, rate = { 6, 16 } },
		},
	},
	light = { color = { 160, 255, 210 }, range = 12, keys = { { 0, 0 }, { 1, 2.2 }, { 1.4, 0 } } },
	source = {
		from = "the library (healing set, 2026-11-09)",
		art = "free Creator Store pack textures (no scripts: drop_glow, glow_soft_big, halo_swirl, glow_dot, ring_wave, star_twinkle)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "The caster's wind-up for skill.renewal_rain: play it on the cast, cancel it as the rain begins or on an interruption.",
}
