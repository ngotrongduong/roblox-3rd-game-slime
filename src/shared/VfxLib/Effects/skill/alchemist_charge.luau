-- Alchemist Charge: the short aim of every Alchemist skill (0.3 s, played on the caster, follows them). A gold alchemy
-- circle draws on the floor, bubbles rise off the flask in their hand and a teal glint runs round it. Coloured bodies.
local GOLD = { { 0, { 255, 240, 170 } }, { 1, { 235, 175, 50 } } }
local TEAL = { { 0, { 190, 255, 235 } }, { 1, { 40, 190, 170 } } }

return {
	id = "skill.alchemist_charge",
	name = "Alchemist Charge",
	kind = "skill",
	tier = "cheap",
	host = "character",
	refHeight = 5,
	tags = { "alchemist", "charge", "circle", "bubbles", "gold", "teal", "character" },
	blend = "normal+bloom",
	tintable = false,
	follow = true,
	markers = { full = 0.3, peak = 0.25 },
	pieces = {
		{
			name = "circle",
			texture = "alchemy_flip",
			color = GOLD,
			at = "ground",
			flat = true,
			count = 1,
			life = { 0.4, 0.4 },
			size = { { 0, 5 }, { 1, 5.6 } },
			transparency = { { 0, 0.3 }, { 0.7, 0.1 }, { 1, 0.7 } },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0.5,
			brightness = 1.5,
		},
		{
			name = "bubbles",
			texture = "bubble_gloss",
			color = TEAL,
			at = "body",
			offset = { 0.5, 0.4, -0.8 },
			direction = "Top",
			life = { 0.3, 0.5 },
			size = { { 0, 0.3 }, { 1, 0.5 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			speed = { 1.5, 3 },
			spread = { 25, 25 },
			lightEmission = 0.2,
			stream = { from = 0, to = 0.3, rate = { 30, 40 } },
		},
	},
	source = {
		from = "the library (fight effects wave 2, 2026-11-14)",
		art = "free Creator Store pack textures (no scripts: alchemy_flip, bubble_gloss)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Play on the Alchemist (follow) for the 0.3 s aim of Acid Rain / Squad Tonic / Cursed Flask / Catalyst Cloud; cancel it as the skill fires.",
}
