-- Mage Meteor wind-up: before skill.meteor_fall, a violet swirl of stars turns over the Mage's head and is pulled
-- tighter, a small violet rune circle opens above them, and a low note of light gathers. Played on the Mage (follows),
-- about 1.2 s, then played the meteor. Coloured violet bodies with white-gold star glints.
local VIOLET = { { 0, { 235, 210, 255 } }, { 1, { 135, 65, 230 } } }
local STAR = { { 0, { 255, 245, 200 } }, { 1, { 255, 200, 90 } } }

return {
	id = "skill.mage_meteor_windup",
	name = "Mage Meteor Wind-up",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "mage", "meteor", "windup", "stars", "violet", "swirl", "character", "skill" },
	blend = "normal+bloom",
	tintable = false,
	follow = true,
	markers = { gathered = 1, peak = 0.8, full = 1.3 },
	pieces = {
		{
			-- the violet circle opening over their head
			name = "circle",
			texture = "rune_circle_violet",
			color = VIOLET,
			at = "body",
			offset = { 0, 3.4, 0 },
			locked = true,
			flat = true,
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0 }, { 0.3, 4 }, { 1, 4.4 } },
			transparency = { { 0, 0.7 }, { 0.3, 0.05 }, { 0.9, 0.1 }, { 1, 1 } },
			rotSpeed = { 60, 60 },
			flipbook = { layout = "Grid4x4", mode = "Loop" },
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- stars swirling in over it, pulled tighter
			name = "stars",
			texture = "star_twinkle",
			color = STAR,
			at = "body",
			offset = { 0, 3.4, 0 },
			shape = "Disc",
			shapeInOut = "Inward",
			radius = 3.2,
			life = { 0.5, 0.8 },
			size = { { 0, 0.6 }, { 0.5, 0.4 }, { 1, 0 } },
			transparency = { { 0, 0.2 }, { 1, 0.3 } },
			speed = { 3, 5 },
			lightEmission = 1,
			brightness = 3,
			stream = { from = 0, to = 1.2, rate = { 10, 40 }, ease = "in" },
		},
		{
			-- the gathered light
			name = "core",
			texture = "glow_soft",
			color = VIOLET,
			at = "body",
			offset = { 0, 3.4, 0 },
			locked = true,
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0 }, { 0.85, 2.2 }, { 1, 2.6 } },
			transparency = { { 0, 0.9 }, { 0.8, 0.3 }, { 1, 0.3 } },
			lightEmission = 1,
			brightness = 1.8,
		},
	},
	light = { color = { 170, 100, 255 }, range = 12, keys = { { 0, 0 }, { 1, 3 }, { 1.4, 0 } } },
	source = {
		from = "the library (fight effects wave 2, 2026-11-14)",
		art = "free Creator Store pack textures (no scripts: rune_circle_violet, star_twinkle, glow_soft)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Play on the Mage (follow) 1.2 s before skill.meteor_fall; stars are all in by markers.gathered (1 s). Cancel softly (VfxLib.cancel) on an interruption.",
}
