-- Frost Howl: the Yeti's wind-up for skill.blizzard, "the howl that calls the blizzard" (the owner's idea, 2026-11-16,
-- docs/vfx/plans/2026-11-16-boss-windups.md). It howls: three white-blue rings roll out from its head one after
-- another, bright snow is drawn in round its body, and a pale ice-blue circle on the floor, as wide as the blizzard,
-- brightens until the release: the player reads "get out of this circle". Play it on its host when the skill is
-- called; it lasts until the release (MonsterLib: 2.05 s), which cancels it (VfxLib.cancel).
-- Its numbers are for the Yeti itself (12.65 studs tall): MonsterLib plays a wind-up at scale 1, and a one-shot's
-- sizes, speeds and radii do not grow with its host. The circle stays 19: a skill's particle is never drawn over 20
-- studs (Budget), so the blizzard's ring is 20 on the Yeti too, not 20 times its scale.
local ICE = { { 0, { 245, 252, 255 } }, { 1, { 160, 220, 255 } } }

return {
	id = "skill.frost_howl",
	name = "Frost Howl",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 12.65,
	tags = { "dungeon", "ice", "frost", "snow", "charge", "power_up", "boss", "white", "blue", "bright_map" },
	blend = "normal",
	palette = {},
	tintable = false,
	follow = true,
	markers = {
		full = 2.05,
		peak = 1.3,
	},
	pieces = {
		{
			-- three howl rings rolling out from its head, one after another
			name = "howl",
			texture = "ring_fat_flip",
			role = "keep",
			color = ICE,
			at = "head",
			-- (its mouth: the head anchor is the top of its head)
			offset = { 0, -1.8, 0 },
			direction = "Front",
			orientation = "VelocityPerpendicular",
			bursts = { { 0.15, 1 }, { 0.7, 1 }, { 1.25, 1 } },
			life = { 0.6, 0.6 },
			size = { { 0, 2.5 }, { 1, 16 } },
			transparency = { { 0, 0.1 }, { 0.6, 0.3 }, { 1, 1 } },
			speed = { 12, 12 },
			flipbook = {
				layout = "Grid4x4",
				mode = "OneShot",
			},
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- bright snow drawn in round its body from all round
			name = "snow",
			texture = "snow_crystals_flip",
			role = "keep",
			color = { { 0, { 255, 255, 255 } }, { 1, { 210, 240, 255 } } },
			at = "body",
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Inward",
			height = 2.5,
			radius = 10,
			orientation = "VelocityParallel",
			stream = {
				from = 0,
				ease = "in",
				rate = { 12, 36 },
				to = 1.9,
			},
			life = { 0.45, 0.55 },
			size = { { 0, 2.4 }, { 1, 0.9 } },
			transparency = { { 0, 0.6 }, { 0.3, 0 }, { 1, 0.3 } },
			speed = { 18, 22 },
			flipbook = {
				layout = "Grid4x4",
				mode = "OneShot",
			},
			lightEmission = 0.5,
		},
		{
			-- the danger circle: as wide as the blizzard, brighter until the release
			name = "circle",
			texture = "ring_halo",
			role = "keep",
			color = ICE,
			at = "ground",
			flat = true,
			count = 1,
			life = { 2.4, 2.4 },
			size = { { 0, 12 }, { 0.1, 19 }, { 1, 19 } },
			transparency = { { 0, 0.95 }, { 0.1, 0.75 }, { 0.8, 0.05 }, { 1, 1 } },
			lightEmission = 1,
			brightness = 2,
			-- (on the floor: a flat piece pushed under it is never drawn, lesson 372)
			zOffset = 0.2,
		},
	},
	source = {
		from = "the library (Slime Dungeon fight set, 2026-11-09), redrawn from the owner's idea 2026-11-16",
		art = "free Creator Store pack pictures already in the library (ring_fat_flip, snow_crystals_flip, ring_halo)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "The Yeti's wind-up for skill.blizzard, 'the howl that calls the blizzard' (the owner's idea, 2026-11-16): three howl rings roll out from its head, bright snow is drawn in, a pale ice-blue circle as wide as the blizzard brightens until the release. Play it on its host when the skill is called; the release (2.05 s in MonsterLib) cancels it (VfxLib.cancel).",
}
