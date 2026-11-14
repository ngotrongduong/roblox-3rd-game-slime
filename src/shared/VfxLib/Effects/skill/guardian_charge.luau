-- Guardian Charge: the short aim of every Guardian skill (0.3 s, played on the caster, follows them). The shield emblem lifts
-- before their chest in blue-white light while a gold ring closes on it, motes are pulled in.
-- Coloured bodies (gold, royal blue) so it reads on snow; white only as a glint. Cancel it softly as the skill fires.
local GOLD = { { 0, { 255, 232, 150 } }, { 1, { 235, 170, 40 } } }
local BLUE = { { 0, { 190, 225, 255 } }, { 1, { 70, 130, 235 } } }

return {
	id = "skill.guardian_charge",
	name = "Guardian Charge",
	kind = "skill",
	tier = "cheap",
	host = "character",
	refHeight = 5,
	tags = { "guardian", "shield", "charge", "gold", "blue", "character" },
	blend = "normal+bloom",
	tintable = false,
	follow = true,
	markers = { full = 0.3, peak = 0.25 },
	pieces = {
		{
			-- a gold ring closing in on the emblem (not the floor seal: that is the Bulwark wind-up)
			name = "ring",
			texture = "ring_crisp",
			color = GOLD,
			at = "body",
			offset = { 0, 0.6, -1.4 },
			locked = true,
			count = 1,
			life = { 0.3, 0.3 },
			size = { { 0, 5 }, { 1, 1.6 } },
			transparency = { { 0, 0.6 }, { 0.5, 0.1 }, { 1, 0.3 } },
			lightEmission = 0.5,
			brightness = 1.5,
		},
		{
			-- the shield emblem lifting before the chest
			name = "emblem",
			texture = "shield_icon",
			color = BLUE,
			at = "body",
			offset = { 0, 0.6, -1.4 },
			locked = true,
			count = 1,
			life = { 0.4, 0.4 },
			size = { { 0, 0.6 }, { 0.6, 2.2 }, { 1, 2.4 } },
			transparency = { { 0, 0.8 }, { 0.4, 0.05 }, { 1, 0.4 } },
			lightEmission = 0.4,
			brightness = 1.5,
		},
		{
			-- motes pulled in
			name = "gather",
			texture = "glow_dot",
			color = GOLD,
			at = "body",
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Inward",
			radius = 2.6,
			life = { 0.2, 0.3 },
			size = { { 0, 0.3 }, { 1, 0.1 } },
			transparency = { { 0, 0.5 }, { 1, 0.2 } },
			speed = { 7, 9 },
			lightEmission = 1,
			brightness = 3,
			stream = { from = 0, to = 0.3, rate = { 30, 60 } },
		},
	},
	source = {
		from = "the library (fight effects wave 2, 2026-11-14)",
		art = "free Creator Store pack textures (no scripts: rune_circle, shield_icon, glow_dot)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Play on the Guardian (follow) for the 0.3 s aim of Taunt / Shield Bash / Shield Wall / Bulwark; cancel it as the skill fires.",
}
