-- Void Charge: the wind-up of skill.void_singularity (docs/vfx/plans/2026-11-08-skills-wave-1.md). Dark wisps and
-- violet needles are pulled in to the hand from a sphere round the body, more as the charge fills (eased-in streams);
-- at the chest a small black hole grows: an eclipse for its core (a pack picture), the library's violet rim of light
-- curling into it (ChatGPT) and the packs' portal rings spiralling in behind; on the ground a soft ring CLOSES in on a
-- quickening beat; the light swells, dim violet. It follows its host and holds 1.2 s: a game plays it on the charge and
-- cancels it softly (VfxLib.cancel) at the throw or an interruption.
local VIOLET = { { 0, { 235, 210, 255 } }, { 0.5, { 170, 90, 255 } }, { 1, { 110, 40, 210 } } }
local DEEP = { { 0, { 150, 70, 240 } }, { 1, { 90, 30, 180 } } }
local DARK = { { 0, { 35, 10, 55 } }, { 1, { 15, 5, 25 } } }

return {
	id = "skill.void_charge",
	name = "Void Charge",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "void", "dark", "charge", "power_up", "pull", "violet", "black", "character" },
	blend = "additive",
	tintable = false,
	follow = true,
	markers = { full = 1.2, peak = 1 },
	pieces = {
		{
			-- dark wisps pulled in to the body from all round
			name = "wisps",
			texture = "smoke_dark",
			color = DARK,
			at = "chest",
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Inward",
			radius = 3.4,
			life = { 0.4, 0.5 },
			size = { { 0, 1.4 }, { 1, 0.3 } },
			transparency = { { 0, 1 }, { 0.3, 0.35 }, { 1, 0.6 } },
			speed = { 6, 8 },
			rotation = { -180, 180 },
			rotSpeed = { -90, 90 },
			lightEmission = 0,
			stream = { from = 0, to = 1.2, rate = { 8, 26 }, ease = "in" },
		},
		{
			-- violet needles drawn in with them, stretched along their flight
			name = "needles",
			texture = "needle_soft",
			color = VIOLET,
			at = "chest",
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Inward",
			radius = 3.2,
			orientation = "VelocityParallel",
			life = { 0.35, 0.45 },
			size = { { 0, 0.4 }, { 1, 0.12 } },
			transparency = { { 0, 0.6 }, { 0.25, 0 }, { 1, 0.2 } },
			speed = { 7, 9 },
			squash = { { 0, -1 }, { 1, -0.5 } },
			lightEmission = 1,
			brightness = 4,
			stream = { from = 0, to = 1.2, rate = { 12, 44 }, ease = "in" },
		},
		{
			-- the small black hole at the chest: an eclipse growing (drawn dark, over the scene)
			name = "core",
			texture = "glow_astral",
			color = { { 190, 140, 255 } },
			at = "chest",
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0 }, { 0.85, 1.6 }, { 1, 1.8 } },
			transparency = { { 0, 0.3 }, { 0.3, 0 }, { 1, 0 } },
			lightEmission = 0,
			zOffset = 1.5,
		},
		{
			-- its bright rim, light curling in, turning
			name = "rim",
			texture = "void_rim",
			color = VIOLET,
			at = "chest",
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0 }, { 0.85, 2.6 }, { 1, 2.9 } },
			transparency = { { 0, 0.4 }, { 0.3, 0 }, { 1, 0 } },
			rotation = { -180, 180 },
			rotSpeed = { -180, -180 },
			lightEmission = 1,
			brightness = 2.5,
			zOffset = 2,
		},
		{
			-- behind it, the portal's rings spiralling in
			name = "suck",
			texture = "portal_suck",
			color = DEEP,
			at = "chest",
			count = 1,
			life = { 1.3, 1.3 },
			size = { { 0, 0 }, { 0.85, 4 }, { 1, 4.4 } },
			transparency = { { 0, 0.6 }, { 0.4, 0.25 }, { 1, 0.2 } },
			rotation = { -180, 180 },
			rotSpeed = { -120, -120 },
			lightEmission = 1,
			brightness = 1.5,
			zOffset = 1,
		},
		{
			-- a soft ring on the ground closing IN on the caster, faster and faster
			name = "close",
			texture = "ring_soft",
			color = DEEP,
			at = "ground",
			flat = true,
			life = { 0.4, 0.4 },
			size = { { 0, 7 }, { 1, 1 } },
			transparency = { { 0, 1 }, { 0.3, 0.25 }, { 1, 0.6 } },
			lightEmission = 1,
			brightness = 1.5,
			bursts = { { 0, 1 }, { 0.45, 1 }, { 0.78, 1 }, { 1, 1 }, { 1.14, 1 } },
		},
	},
	light = { color = { 150, 70, 240 }, range = 12, keys = { { 0, 0.3 }, { 1.2, 2.2 }, { 1.4, 0 } } },
	source = {
		from = "the library (skills wave 1, 2026-11-08)",
		art = "ChatGPT picture drawn for the library (void_rim); free Creator Store pack textures (no scripts: glow_astral, portal_suck, ring_soft, needle_soft)",
		licence = "ChatGPT output owned by the owner; Creator Store free assets (no scripts kept)",
	},
	notes = "The caster's wind-up for skill.void_singularity: play it on the charge, cancel it (VfxLib.cancel) at the throw or an interruption.",
}
