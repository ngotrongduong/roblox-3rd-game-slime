-- Draw and Aim: the wind-up of the bow and crossbow skills (2026-11-09: "Giương Cung"). No magic in it: an archer
-- plants their feet, draws and takes aim. A ring of dust is pushed out under the feet; streaks of air are pulled in
-- toward the arrowhead held out in front; a small curl of wind gathers at the point and thin rings close in on it
-- one after another (the eye narrowing on the mark); at the end a hard glint flashes on the arrowhead: the moment
-- before the loose. It follows its host and holds about 1.1 s: a game plays it on the draw and cancels it softly
-- (VfxLib.cancel) at the loose.
local DUST = { { 0, { 205, 190, 165 } }, { 1, { 150, 135, 110 } } }
local AIR = { { 0, { 235, 245, 255 } }, { 1, { 190, 210, 235 } } }
local STEEL = { { 0, { 255, 255, 255 } }, { 1, { 200, 220, 255 } } }
local TIP = { 0.3, 0.2, -1.8 } -- (the arrowhead, held out in front of the chest)

return {
	id = "skill.draw_aim",
	name = "Draw and Aim",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "physical", "bow", "crossbow", "archer", "charge", "aim", "wind", "steel", "character" },
	blend = "normal",
	tintable = false,
	follow = true,
	markers = { full = 1.1, peak = 0.9 },
	pieces = {
		{
			-- streaks of air pulled in toward the arrowhead
			name = "air",
			texture = "streak_lens",
			color = AIR,
			at = "chest",
			offset = TIP,
			shape = "Sphere",
			shapeInOut = "Inward",
			radius = 3,
			orientation = "VelocityParallel",
			life = { 0.22, 0.3 },
			size = { { 0, 1 }, { 1, 0.35 } },
			transparency = { { 0, 1 }, { 0.3, 0.15 }, { 1, 1 } },
			speed = { 10, 13 },
			squash = { { 0, -1.4 }, { 1, -1 } },
			lightEmission = 0.8,
			brightness = 2,
			stream = { from = 0.1, to = 1.05, rate = { 10, 40 }, ease = "in" },
		},
		{
			-- a small curl of wind gathering at the point
			name = "curl",
			texture = "windspin_b",
			color = AIR,
			at = "chest",
			offset = TIP,
			life = { 0.3, 0.4 },
			size = { { 0, 2.4 }, { 1, 1.2 } },
			transparency = { { 0, 1 }, { 0.3, 0.45 }, { 1, 1 } },
			speed = { 0.01, 0.01 },
			rotation = { -180, 180 },
			rotSpeed = { -500, -350 },
			lightEmission = 0.7,
			brightness = 1.4,
			stream = { from = 0.25, to = 1.05, rate = { 4, 12 }, ease = "in" },
		},
		{
			-- thin rings closing in on the point, one after another, standing across the aim
			name = "focus",
			texture = "ring_rays_thin",
			color = AIR,
			at = "chest",
			offset = { TIP[1], TIP[2], TIP[3] - 0.3 },
			upright = true,
			locked = true,
			life = { 0.35, 0.35 },
			size = { { 0, 4 }, { 1, 0.6 } },
			transparency = { { 0, 1 }, { 0.3, 0.45 }, { 1, 0.9 } },
			speed = { 0.01, 0.01 },
			rotation = { -180, 180 },
			lightEmission = 0.8,
			brightness = 1.5,
			stream = { from = 0.35, to = 0.95, rate = { 3, 5 } },
		},
		{
			-- a ring of dust pushed out once as the feet are planted
			name = "plant",
			texture = "dust_ring",
			color = DUST,
			at = "ground",
			flat = true,
			count = 1,
			life = { 0.6, 0.6 },
			size = { { 0, 2.5 }, { 1, 6 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			rotation = { -180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
		},
		{
			-- the glint on the arrowhead, the instant before the loose
			name = "glint",
			texture = "star_flare",
			color = STEEL,
			at = "chest",
			offset = TIP,
			count = 1,
			delay = 0.85,
			life = { 0.25, 0.25 },
			size = { { 0, 0.5 }, { 0.3, 3 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.2 } },
			rotation = { 15, 15 },
			rotSpeed = { 90, 90 },
			lightEmission = 1,
			brightness = 3,
			zOffset = 2,
		},
	},
	light = { color = { 230, 240, 255 }, range = 8, keys = { { 0, 0 }, { 0.85, 0 }, { 0.92, 3 }, { 1.2, 0 } } },
	source = {
		from = "the library (bow skills, 2026-11-09)",
		art = "EffectCraft (dust_ring, textures/fx); free Creator Store pack textures (no scripts: streak_lens, windspin_b, ring_rays_thin, star_flare)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "The wind-up of the bow and crossbow skills (Piercing Arrow, Fan Shot, Arrow Ring, Arrow Volley, Repeater Bolts, Heavy Bolt, Explosive Bolt): play it on the archer, cancel it at the loose or on an interruption.",
}
