-- Guardian Shield Wall: a row of gold-rimmed blue shields rises from the floor in front of the Guardian and links into
-- one barrier, glinting along its rim, with a ring of force on the floor. Played at the Guardian, facing the foe; the
-- wall stands 3 studs ahead, 6 studs wide, about 1.4 s. Coloured normal bodies; white only as a glint.
local GOLD = { { 0, { 255, 235, 160 } }, { 1, { 235, 165, 35 } } }
local BLUE = { { 0, { 200, 230, 255 } }, { 1, { 60, 120, 235 } } }

local function shield(i, x, delay)
	return {
		name = "shield" .. i,
		texture = "shield_icon",
		color = BLUE,
		at = "body",
		offset = { x, -0.4, -3 },
		count = 1,
		delay = delay,
		life = { 1.2, 1.2 },
		size = { { 0, 1 }, { 0.12, 3.8 }, { 0.8, 3.8 }, { 1, 3 } },
		transparency = { { 0, 0.7 }, { 0.12, 0 }, { 0.8, 0.05 }, { 1, 1 } },
		lightEmission = 0.3,
		brightness = 1.5,
	}
end

return {
	id = "skill.guardian_wall",
	name = "Guardian Shield Wall",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "guardian", "shield", "wall", "barrier", "gold", "blue", "skill" },
	blend = "normal+bloom",
	tintable = false,
	markers = { up = 0.3, peak = 0.5, full = 1.4 },
	pieces = {
		shield(1, -2.4, 0),
		shield(2, -0.8, 0.05),
		shield(3, 0.8, 0.1),
		shield(4, 2.4, 0.15),
		{
			-- the gold glint running along the rim once they link
			name = "glint",
			texture = "star_flare",
			color = GOLD,
			at = "body",
			offset = { 0, -0.4, -3 },
			box = { 6, 0.6, 0.4 },
			life = { 0.3, 0.5 },
			size = { { 0, 0.6 }, { 0.5, 1 }, { 1, 0 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			lightEmission = 1,
			brightness = 2.5,
			stream = { from = 0.25, to = 0.9, rate = { 14, 14 } },
		},
		{
			name = "floor",
			texture = "ring_fat_sharp",
			color = GOLD,
			at = "ground",
			flat = true,
			offset = { 0, 0, -3 },
			count = 1,
			life = { 0.9, 0.9 },
			size = { { 0, 3 }, { 1, 9 } },
			transparency = { { 0, 0.1 }, { 1, 1 } },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0.5,
			brightness = 1.5,
		},
		{
			-- dust shaken off the floor as they rise
			name = "dust",
			texture = "dust_kick_flip",
			color = { { 225, 230, 240 } },
			at = "ground",
			offset = { 0, 0, -3 },
			box = { 6, 0.2, 0.6 },
			count = 6,
			life = { 0.4, 0.6 },
			size = { { 0, 0.8 }, { 1, 2 } },
			transparency = { { 0, 0.3 }, { 1, 1 } },
			speed = { 1, 3 },
			direction = "Top",
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
		},
	},
	light = { color = { 190, 220, 255 }, range = 10, keys = { { 0, 0 }, { 0.3, 2.5 }, { 1.3, 0 } } },
	source = {
		from = "the library (fight effects wave 2, 2026-11-14)",
		art = "free Creator Store pack textures (no scripts: shield_icon, star_flare, ring_fat_sharp, dust_kick_flip)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the Guardian facing the foe: four shields rise at 0 to 0.15 s, 3 studs ahead, linked into a 6-stud wall (markers.up 0.3 s); gone by 1.4 s.",
}
