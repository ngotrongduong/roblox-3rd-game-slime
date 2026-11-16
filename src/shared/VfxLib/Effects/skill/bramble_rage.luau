-- Bramble Rage: the Bramblehorn's wind-up, "the ground answers its anger" (the owner's idea, 2026-11-16,
-- docs/vfx/plans/2026-11-16-boss-windups.md). It paws the ground: bright leaf-green thorns burst up round its feet in
-- three waves, pale earth is kicked back behind it like a bull's before the charge, and a glowing green crack opens
-- under it, at full size as the smash goes off. Play it on its host when the skill is called; it lasts until the
-- release (MonsterLib: 2.05 s), which cancels it.
-- Its numbers are for the Bramblehorn itself (11.5 studs tall, 20 long): MonsterLib plays a wind-up at scale 1, and a
-- one-shot's sizes, speeds and radii do not grow with its host (only its `box` shares do).
local LEAF = { { 0, { 200, 255, 130 } }, { 1, { 90, 215, 60 } } }

return {
	id = "skill.bramble_rage",
	name = "Bramble Rage",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 11.5,
	tags = { "dungeon", "meadow", "thorn", "earth", "charge", "power_up", "boss", "green" },
	blend = "normal",
	palette = {},
	tintable = false,
	follow = true,
	markers = {
		full = 2.05,
		peak = 1.5,
	},
	pieces = {
		{
			-- thorns bursting up round its feet in three waves, each pushing out from the hooves, each a little stronger
			name = "thorns",
			texture = "spikes_up",
			role = "keep",
			color = LEAF,
			at = "feet",
			shape = "Sphere",
			shapeStyle = "Surface",
			height = 0.2,
			-- (out past its sides, 8.5 studs wide: closer in, its legs hid them from the player's camera)
			radius = 6,
			bursts = { { 0.1, 8 }, { 0.7, 10 }, { 1.3, 12 } },
			life = { 0.5, 0.6 },
			size = { { 0, 1 }, { 0.25, 5.5 }, { 1, 3.6 } },
			transparency = { { 0, 0.2 }, { 0.15, 0 }, { 0.7, 0.1 }, { 1, 1 } },
			speed = { 5, 7 },
			drag = 2,
			lightEmission = 0.4,
		},
		{
			-- pale earth pawed up at its front hooves, three kicks, puffing up and out where the player sees it (kicked
			-- back, from under the belly or the hind legs, it stayed hidden by the long body and the tail from every side)
			-- (a round cloud: the kick picture, `dust_kick_flip`, read as a thin pale streak from the front)
			name = "paw",
			texture = "dust_cloud",
			color = { { 0, { 245, 228, 185 } }, { 1, { 210, 185, 140 } } },
			at = "feet",
			-- (the front legs, 5.5 studs ahead of the box's middle: its tail makes the box longer behind)
			offset = { 0, 0, -5.5 },
			box = { 0.7, 0, 0.05 },
			direction = "Top",
			bursts = { { 0.35, 5 }, { 0.95, 5 }, { 1.55, 6 } },
			life = { 0.55, 0.75 },
			size = { { 0, 3 }, { 1, 7 } },
			transparency = { { 0, 0.3 }, { 0.3, 0.15 }, { 1, 1 } },
			speed = { 6, 10 },
			spread = { 45, 45 },
			accel = { 0, 3, 0 },
			lightEmission = 0.3,
			drag = 2,
			rotation = { 0, 359 },
			rotSpeed = { -40, 40 },
		},
		{
			-- a glowing green crack opening under it, brighter and wider until the smash (2 s of its 2.4), then fading
			name = "crack",
			texture = "crack_glow",
			color = LEAF,
			at = "ground",
			flat = true,
			count = 1,
			life = { 2.4, 2.4 },
			size = { { 0, 3 }, { 0.83, 17 }, { 1, 18 } },
			transparency = { { 0, 0.75 }, { 0.8, 0.05 }, { 1, 1 } },
			rotation = { -180, 180 },
			lightEmission = 1,
			brightness = 2,
			-- (on the floor: a flat piece pushed under it is never drawn, lesson 372)
			zOffset = 0.2,
		},
	},
	source = {
		from = "the library (Slime Dungeon fight set, 2026-11-09), redrawn from the owner's idea 2026-11-16",
		art = "free Creator Store pack pictures already in the library (spikes_up, dust_cloud, crack_glow)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "The Bramblehorn's wind-up, 'the ground answers its anger' (the owner's idea, 2026-11-16): thorns in three waves, pale earth pawed back, a glowing green crack under it at full size as the smash goes off. Play it on its host when the skill is called; the release (2.05 s in MonsterLib) cancels it.",
}
