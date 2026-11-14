-- Momentum: the Warrior has just finished a foe and its Dash Strike is ready again at once: "a kill made it faster".
-- Steel-red speed lines sweep back past the body, one blade glint crosses it, a small kick of sparks goes up. Short
-- (0.5 s) and light: not battle_focus (a long charge, drawing in) and not flash_step (the white dash and cuts that follow).
-- Played once on the Warrior (follow, refHeight 3). Coloured normal bodies (steel-red), so it reads on snow.
local RED = { { 0, { 255, 150, 130 } }, { 1, { 215, 45, 40 } } }
local STEEL = { { 0, { 235, 242, 255 } }, { 1, { 160, 185, 225 } } }
local HOT = { { 0, { 255, 240, 200 } }, { 0.5, { 255, 150, 70 } }, { 1, { 230, 60, 35 } } }

return {
	id = "burst.momentum",
	name = "Momentum",
	kind = "burst",
	tier = "cheap",
	host = "any",
	refHeight = 3,
	tags = { "warrior", "momentum", "trait", "speed", "steel", "red", "sparks", "goo_lineage", "bright_map" },
	blend = "normal+bloom",
	tintable = false,
	follow = true,
	markers = { glint = 0.1, peak = 0.15, full = 0.55 },
	pieces = {
		{
			-- speed lines thrown back along the body
			name = "lines",
			texture = "streaks_flat",
			color = RED,
			at = "body",
			box = { 1.1, 0.8, 0.3 },
			shape = "Box",
			shapeStyle = "Volume",
			count = 8,
			life = { 0.25, 0.4 },
			size = { { 0, 2.4 }, { 1, 1.2 } },
			transparency = { { 0, 0.1 }, { 0.5, 0.2 }, { 1, 1 } },
			speed = { 14, 22 },
			direction = "Back",
			orientation = "VelocityParallel",
			spread = { 8, 8 },
			lightEmission = 0.3,
			brightness = 1.4,
			locked = false,
		},
		{
			-- one blade glint crossing the body, rising as it goes
			name = "glint",
			texture = "star_glint_sharp",
			color = STEEL,
			at = "body",
			offset = { 0, 0.4, -1.2 },
			count = 1,
			delay = 0.05,
			life = { 0.22, 0.22 },
			size = { { 0, 1.6 }, { 0.3, 3 }, { 1, 1.4 } },
			transparency = { { 0, 0.3 }, { 0.3, 0 }, { 1, 1 } },
			rotation = { -30, -30 },
			speed = { 8, 8 },
			direction = "Right",
			lightEmission = 1,
			brightness = 1.8,
			locked = false,
		},
		{
			-- a small upward kick of sparks
			name = "sparks",
			texture = "spark_dot",
			color = HOT,
			at = "body",
			count = 12,
			delay = 0.08,
			life = { 0.3, 0.5 },
			size = { { 0, 0.4 }, { 1, 0.08 } },
			transparency = { { 0, 0 }, { 1, 1 } },
			speed = { 8, 14 },
			direction = "Top",
			spread = { 35, 35 },
			orientation = "VelocityParallel",
			drag = 2,
			accel = { 0, -18, 0 },
			lightEmission = 1,
			brightness = 2.5,
			locked = false,
		},
	},
	source = {
		from = "the library, for Goo Lineage's Warrior trait Momentum (2026-11-14)",
		art = "free Creator Store pack textures (no scripts: streaks_flat, star_glint_sharp, spark_dot)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = 'VfxLib.play("burst.momentum", warriorBodyPart) as the kill lands (it follows the body); done by 0.55 s. skill.flash_step is the dash that follows.',
}
