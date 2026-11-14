-- Guardian Bulwark wind-up: the gold circle with the shield emblem drawn on the floor under the Guardian before Spirit
-- Guardian (skill.spirit_guardian) rises. The ring draws itself and turns, the emblem glows in its middle, blue-white
-- light lifts off it. Play it on the Guardian, ~1 s, then play the summon. Coloured normal bodies (gold, royal blue).
local GOLD = { { 0, { 255, 215, 90 } }, { 1, { 215, 130, 10 } } }
local BLUE = { { 0, { 200, 230, 255 } }, { 1, { 60, 120, 235 } } }

return {
	id = "skill.guardian_bulwark",
	name = "Guardian Bulwark Wind-up",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "guardian", "shield", "bulwark", "windup", "circle", "summon", "gold", "blue", "skill" },
	blend = "normal+bloom",
	tintable = false,
	follow = true,
	markers = { drawn = 0.5, peak = 0.7, full = 1.1 },
	pieces = {
		{
			-- the gold circle drawing itself and turning
			name = "circle",
			texture = "rune_circle",
			color = GOLD,
			at = "ground",
			flat = true,
			count = 1,
			life = { 1.2, 1.2 },
			size = { { 0, 2 }, { 0.4, 6.5 }, { 1, 7 } },
			transparency = { { 0, 0.8 }, { 0.3, 0.05 }, { 0.85, 0.1 }, { 1, 1 } },
			rotation = { 0, 0 },
			rotSpeed = { 40, 40 },
			lightEmission = 0.5,
			brightness = 1.5,
		},
		{
			-- the emblem lit in its middle
			name = "emblem",
			texture = "shield_icon",
			color = BLUE,
			at = "ground",
			flat = true,
			count = 1,
			delay = 0.2,
			life = { 1, 1 },
			size = { { 0, 1 }, { 0.4, 5 }, { 1, 5.4 } },
			transparency = { { 0, 0.8 }, { 0.4, 0.05 }, { 0.85, 0.15 }, { 1, 1 } },
			lightEmission = 0.4,
			brightness = 1.5,
		},
		{
			-- blue-white light lifting off it
			name = "rise",
			texture = "glow_dot",
			color = BLUE,
			at = "ground",
			shape = "Disc",
			radius = 3,
			direction = "Top",
			life = { 0.5, 0.8 },
			size = { { 0, 0.4 }, { 1, 0.1 } },
			transparency = { { 0, 0.4 }, { 1, 1 } },
			speed = { 2.5, 4.5 },
			lightEmission = 1,
			brightness = 3,
			stream = { from = 0.2, to = 1, rate = { 16, 36 } },
		},
	},
	light = { color = { 255, 215, 120 }, range = 12, keys = { { 0, 0 }, { 0.6, 2.5 }, { 1.2, 0 } } },
	source = {
		from = "the library (fight effects wave 2, 2026-11-14)",
		art = "free Creator Store pack textures (no scripts: rune_circle, shield_icon, glow_dot)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Play on the Guardian ~1.1 s before skill.spirit_guardian rises (it follows them). The circle is drawn by markers.drawn (0.5 s). skill.summon_call was not reused: it is a portal, this is a floor seal.",
}
