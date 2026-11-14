-- Arcane Charge: the wind-up of skill.arcane_ray (skills wave 2, the owner's "Tia Thần Quang"). A violet rune circle
-- opens standing up before the caster's hands and slowly turns (upright, held by the host: it turns with them, never
-- with the camera), a pink glow gathers in its middle, motes of light are pulled into it from all round, and sparkles
-- twinkle round the caster. It follows its host and holds about 1.1 s: a game plays it on the cast and cancels it
-- softly (VfxLib.cancel) as the ray fires or on an interruption.
local PINK = { { 0, { 255, 215, 250 } }, { 1, { 220, 90, 255 } } }
-- (before both hands, at chest height)
local HANDS = { 0, 0.8, -1.8 }

return {
	id = "skill.arcane_charge",
	name = "Arcane Charge",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "arcane", "magic", "circle", "charge", "power_up", "pink", "violet", "character" },
	blend = "additive",
	tintable = false,
	follow = true,
	markers = { full = 1.1, peak = 1 },
	pieces = {
		{
			-- the rune circle standing before the hands, opening and slowly turning (the pack's circle is a 4 x 4 sheet
			-- of its own turning frames)
			name = "circle",
			texture = "rune_circle_violet",
			color = PINK,
			at = "body",
			offset = HANDS,
			upright = true,
			locked = true,
			count = 1,
			life = { 1.3, 1.3 },
			-- (the sheet's circles fill about two thirds of their frames: drawn big enough to show round the caster
			-- from the camera behind them)
			size = { { 0, 0 }, { 0.3, 5.4 }, { 1, 6 } },
			transparency = { { 0, 0.6 }, { 0.3, 0.05 }, { 1, 0 } },
			rotation = { 0, 0 },
			rotSpeed = { 30, 30 },
			flipbook = { layout = "Grid4x4", mode = "Loop" },
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- a pink glow gathering in its middle
			name = "core",
			texture = "glow_soft",
			color = PINK,
			at = "body",
			offset = HANDS,
			locked = true,
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0 }, { 0.8, 2.4 }, { 1, 2.8 } },
			transparency = { { 0, 0.9 }, { 0.8, 0.35 }, { 1, 0.3 } },
			lightEmission = 1,
			brightness = 1.5,
			zOffset = 1,
		},
		{
			-- motes of light pulled into the circle from all round
			name = "gather",
			texture = "glow_dot",
			color = PINK,
			at = "body",
			offset = HANDS,
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Inward",
			radius = 3,
			life = { 0.3, 0.4 },
			size = { { 0, 0.3 }, { 1, 0.1 } },
			transparency = { { 0, 0.6 }, { 0.25, 0 }, { 1, 0.2 } },
			speed = { 7, 9 },
			lightEmission = 1,
			brightness = 3,
			stream = { from = 0, to = 1.1, rate = { 12, 45 }, ease = "in" },
		},
		{
			-- sparkles twinkling round the caster
			name = "sparkles",
			texture = "sparkle_cross_flip",
			color = PINK,
			at = "body",
			box = { 1.6, 1, 1.6 },
			life = { 0.4, 0.7 },
			size = { { 0, 0.3 }, { 0.5, 0.6 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.2 } },
			speed = { 0.2, 0.6 },
			spread = { 180, 180 },
			rotation = { -180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 2.5,
			secondary = true,
			stream = { from = 0, to = 1.1, rate = { 6, 16 } },
		},
	},
	light = { color = { 235, 120, 255 }, range = 12, keys = { { 0, 0 }, { 1, 3 }, { 1.4, 0 } } },
	source = {
		from = "the library (skills wave 2, 2026-11-08)",
		art = "free Creator Store pack textures (no scripts: rune_circle_violet, glow_soft, glow_dot, sparkle_cross_flip)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "The caster's wind-up for skill.arcane_ray: play it on the cast, cancel it as the ray fires or on an interruption.",
}
