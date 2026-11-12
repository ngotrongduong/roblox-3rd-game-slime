-- Ether Burst: a burst of raw magic, the library's first picture rendered by EffectCraft (2026-11-09: recipe
-- tools/effectcraft/recipes/ether_bloom.json). A white-hot flash opens into a ball of crackling energy strings that
-- hollows into a ring and fades; a second, violet bloom turned the other way under it gives depth; a thin shock ring
-- runs out, sparks fly and a few motes drift up after. Ice blue to violet. For a spell landing, a level up, a pickup.
local ETHER = { { 0, { 235, 250, 255 } }, { 0.3, { 120, 200, 255 } }, { 1, { 90, 110, 255 } } }
local DEEP = { { 0, { 200, 170, 255 } }, { 1, { 120, 70, 255 } } }
local SPARK = { { 0, { 255, 255, 255 } }, { 1, { 140, 210, 255 } } }

return {
	id = "burst.ether_burst",
	name = "Ether Burst",
	kind = "burst",
	tier = "mid",
	host = "any",
	refHeight = 5,
	tags = { "magic", "arcane", "energy", "burst", "spell", "blue", "violet", "level up", "explosion" },
	blend = "additive",
	markers = { peak = 0.3 },
	pieces = {
		{
			-- the energy: flash, strings opening, a ring, gone (16 frames over its life)
			name = "Bloom",
			texture = "ether_bloom",
			color = ETHER,
			count = 1,
			life = { 0.85, 0.85 },
			size = { { 0, 7.5 }, { 1, 9 } },
			transparency = { { 0, 0 }, { 1, 0 } },
			speed = { 0, 0 },
			rotation = { -180, 180 },
			rotSpeed = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 3,
			zOffset = 1,
		},
		{
			-- a violet bloom under it, turned the other way and a little behind in time
			name = "Depth",
			texture = "ether_bloom",
			color = DEEP,
			count = 1,
			delay = 0.06,
			life = { 0.9, 0.9 },
			size = { { 0, 6 }, { 1, 7.5 } },
			transparency = { { 0, 0.3 }, { 1, 0.3 } },
			speed = { 0, 0 },
			rotation = { -180, 180 },
			rotSpeed = { 40, 60 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- a thin shock ring running out
			name = "Shock",
			texture = "ring_fat_sharp",
			color = ETHER,
			count = 1,
			life = { 0.4, 0.4 },
			size = { { 0, 2 }, { 1, 10 } },
			transparency = { { 0, 0.1 }, { 1, 1 } },
			speed = { 0, 0 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- sparks flung out every way, stretched along their flight
			name = "Sparks",
			texture = "spark_dot",
			color = SPARK,
			count = 22,
			life = { 0.25, 0.5 },
			size = { { 0, 0.45 }, { 1, 0.05 } },
			transparency = { { 0, 0 }, { 1, 0.3 } },
			speed = { 16, 28 },
			spread = { 180, 180 },
			drag = 5,
			orientation = "VelocityParallel",
			squash = { { 0, -0.6 }, { 1, -0.3 } },
			lightEmission = 1,
			brightness = 3,
		},
		{
			-- motes left behind, drifting up
			name = "Motes",
			texture = "spark_dot",
			color = DEEP,
			count = 12,
			delay = 0.15,
			life = { 0.8, 1.2 },
			box = { 2.5, 2, 2.5 },
			shape = "Box",
			size = { { 0, 0.3 }, { 0.5, 0.25 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.5 } },
			speed = { 0.5, 1.5 },
			accel = { 0, 2, 0 },
			spread = { 180, 180 },
			lightEmission = 1,
			brightness = 2,
			secondary = true,
		},
	},
	light = { color = { 140, 190, 255 }, range = 14, keys = { { 0, 0 }, { 0.04, 3 }, { 0.5, 0 } } },
	source = {
		art = "ether_bloom rendered for the library by EffectCraft from a recipe; ring_fat_sharp and spark_dot the library's",
		from = "the library (2026-11-09, the first EffectCraft flipbook: docs/vfx/effectcraft.md)",
		licence = "the owner's (rendered for the library); Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the point of the burst. Low quality drops the motes.",
}
