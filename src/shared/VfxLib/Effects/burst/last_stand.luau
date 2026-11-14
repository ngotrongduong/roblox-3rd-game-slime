-- Last Stand: the Guardian's blow that should have felled them leaves them at 1 HP. "It should have fallen and it
-- refused": a gold shield plate flashes in front of the body with a web of dark cracks through it, the cracks seal in a
-- white-gold flash (markers.hold), a thin defiant ring snaps out along the floor and a few embers rise. One warm
-- colour, one plate, one ring: not stat_set's shields (small, pale, breathing) and not guardian_taunt's crimson rings.
-- Played once on the slime's body (refHeight 3). Coloured normal bodies, so it reads on snow.
local GOLD = { { 0, { 255, 235, 150 } }, { 1, { 235, 170, 40 } } }
local WHITE_GOLD = { { 0, { 255, 252, 225 } }, { 1, { 255, 215, 110 } } }
local HOLD = 0.4

return {
	id = "burst.last_stand",
	name = "Last Stand",
	kind = "burst",
	tier = "mid",
	host = "any",
	refHeight = 3,
	tags = { "guardian", "shield", "last_stand", "trait", "gold", "cracks", "refuse", "goo_lineage", "bright_map" },
	blend = "normal+bloom",
	tintable = false,
	markers = { hold = HOLD, peak = 0.2, full = 0.9 },
	pieces = {
		{
			-- the gold plate flashing in front of the body
			name = "plate",
			texture = "shield_icon",
			color = GOLD,
			at = "body",
			offset = { 0, 0.2, -1.6 },
			count = 1,
			life = { 0.55, 0.55 },
			size = { { 0, 5.4 }, { 0.15, 3.8 }, { 0.8, 4 }, { 1, 4.6 } },
			transparency = { { 0, 0.5 }, { 0.1, 0 }, { 0.7, 0.1 }, { 1, 1 } },
			lightEmission = 0.3,
			brightness = 1.3,
		},
		{
			-- the cracks through it: dark, until they seal
			name = "cracks",
			texture = "crack_web",
			color = { { 70, 30, 10 } },
			at = "body",
			offset = { 0, 0.2, -1.7 },
			count = 1,
			delay = 0.05,
			life = { 0.35, 0.35 },
			size = { { 0, 2.4 }, { 1, 2.8 } },
			transparency = { { 0, 1 }, { 0.15, 0.1 }, { 0.75, 0.1 }, { 1, 1 } },
			rotation = { 20, 20 },
			lightEmission = 0,
		},
		{
			-- the seal: the cracks fill with white-gold light
			name = "seal",
			texture = "star_glint_sharp",
			color = WHITE_GOLD,
			at = "body",
			offset = { 0, 0.2, -1.8 },
			count = 1,
			delay = HOLD,
			life = { 0.3, 0.3 },
			size = { { 0, 1 }, { 0.3, 6 }, { 1, 5 } },
			transparency = { { 0, 0 }, { 0.4, 0.1 }, { 1, 1 } },
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- the defiant ring snapping out along the floor
			name = "ring",
			texture = "ring_crisp",
			color = WHITE_GOLD,
			at = "ground",
			flat = true,
			count = 1,
			delay = HOLD,
			life = { 0.35, 0.35 },
			size = { { 0, 3 }, { 0.4, 9 }, { 1, 10.5 } },
			transparency = { { 0, 0.05 }, { 0.5, 0.2 }, { 1, 1 } },
			lightEmission = 0.5,
			brightness = 1.5,
		},
		{
			-- a few embers rising off it
			name = "embers",
			texture = "embers_fly",
			color = GOLD,
			at = "body",
			count = 9,
			delay = HOLD,
			life = { 0.5, 0.8 },
			size = { { 0, 0.5 }, { 1, 0.1 } },
			transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } },
			speed = { 3, 7 },
			spread = { 40, 40 },
			direction = "Top",
			accel = { 0, 2, 0 },
			lightEmission = 1,
			brightness = 2,
			locked = false,
		},
	},
	light = { color = { 255, 215, 120 }, range = 9, keys = { { 0, 0 }, { 0.1, 2 }, { HOLD, 3 }, { 0.8, 0 } } },
	source = {
		from = "the library, for Goo Lineage's Guardian trait Last Stand (2026-11-14)",
		art = "free Creator Store pack textures (no scripts: shield_icon, crack_web, star_glint_sharp, ring_crisp, embers_fly)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = 'VfxLib.play("burst.last_stand", slimeBodyCFrameOrPart) the moment the blow is cut to 1 HP; the cracks seal at markers.hold (0.4 s), done by 0.9 s. guardian_taunt plays right after.',
}
