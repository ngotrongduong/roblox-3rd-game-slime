-- Guardian Taunt: the shout that pulls every foe's eyes. Three rings of crimson-gold roll out from the Guardian's chest
-- one after the other, the shield emblem is stamped over them in gold, and a floor ring pulses under their feet. Played
-- on the Guardian at their position. Coloured normal bodies (crimson, gold), so it reads on snow.
local RED = { { 255, 190, 150 }, { 225, 50, 40 } }
local GOLD = { { 0, { 255, 235, 160 } }, { 1, { 235, 165, 35 } } }

local function ring(name, delay, to)
	return {
		name = name,
		texture = "ring_crisp",
		color = { { 0, RED[1] }, { 1, RED[2] } },
		at = "body",
		count = 1,
		delay = delay,
		life = { 0.45, 0.45 },
		size = { { 0, 3 }, { 0.5, to * 0.8 }, { 1, to * 1.2 } },
		transparency = { { 0, 0.05 }, { 0.6, 0.2 }, { 1, 1 } },
		lightEmission = 0.3,
		brightness = 1.5,
	}
end

return {
	id = "skill.guardian_taunt",
	name = "Guardian Taunt",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "guardian", "shield", "taunt", "shout", "red", "gold", "skill" },
	blend = "normal+bloom",
	tintable = false,
	markers = { shout = 0, peak = 0.25, full = 0.7 },
	pieces = {
		ring("ring1", 0, 9),
		ring("ring2", 0.12, 12),
		ring("ring3", 0.24, 15),
		{
			-- the emblem stamped over the shout
			name = "emblem",
			texture = "shield_icon",
			color = GOLD,
			at = "body",
			offset = { 0, 0.4, -1.2 },
			count = 1,
			life = { 0.6, 0.6 },
			size = { { 0, 7 }, { 0.2, 4.6 }, { 1, 5 } },
			transparency = { { 0, 0.6 }, { 0.15, 0 }, { 0.7, 0.2 }, { 1, 1 } },
			lightEmission = 0.4,
			brightness = 1.5,
		},
		{
			-- the floor pulsing under their feet
			name = "floor",
			texture = "ring_fat_sharp",
			color = GOLD,
			at = "ground",
			flat = true,
			count = 1,
			life = { 0.6, 0.6 },
			size = { { 0, 4 }, { 1, 14 } },
			transparency = { { 0, 0.1 }, { 1, 1 } },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0.5,
			brightness = 1.5,
		},
		{
			-- gold sparks flung out with it
			name = "sparks",
			texture = "star_twinkle",
			color = GOLD,
			at = "body",
			count = 14,
			life = { 0.3, 0.5 },
			size = { { 0, 0.5 }, { 1, 0.1 } },
			transparency = { { 0, 0 }, { 1, 1 } },
			speed = { 10, 18 },
			spread = { 180, 180 },
			drag = 3,
			lightEmission = 1,
			brightness = 2.5,
		},
	},
	light = { color = { 255, 190, 90 }, range = 10, keys = { { 0, 0 }, { 0.1, 3 }, { 0.6, 0 } } },
	source = {
		from = "the library (fight effects wave 2, 2026-11-14)",
		art = "free Creator Store pack textures (no scripts: ring_crisp, shield_icon, ring_fat_sharp, star_twinkle)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Play on the Guardian (position, facing). Foes' eyes turn at markers.shout (0 s); done at 0.7 s. skill.guardian_charge is the aim.",
}
