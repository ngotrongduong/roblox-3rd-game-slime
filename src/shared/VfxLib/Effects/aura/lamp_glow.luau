-- Lamp Glow: the light of a lamp's head at night, for a world lamp whose glass is part of its mesh and cannot be lit
-- (Goo Lineage V2's village lamps and crystal lanterns, 2026-11-15: the owner, "where there is a lamp, make it glow").
-- A soft halo round the lantern and a brighter core in it, both breathing a little like a flame behind glass. Put it on
-- an anchor at the lamp's head (host any: a part about as tall as the lantern). Tintable: the game hands the lamp's own
-- colour as `core` (warm for an oil lamp, cyan for a crystal). No light of its own: a lamp keeps its own PointLight.
return {
	id = "aura.lamp_glow",
	name = "Lamp Glow",
	kind = "aura",
	tier = "cheap",
	host = "any",
	refHeight = 1,
	tags = { "lamp", "lantern", "light", "glow", "night", "world", "warm", "tintable" },
	blend = "additive",
	palette = { core = { 255, 200, 120 } },
	tintable = true,
	pieces = {
		{
			-- the halo round the lantern, slow and steady
			name = "halo",
			texture = "glow_soft",
			role = "core",
			at = "body",
			speed = { 0.01, 0.01 },
			locked = true,
			rate = 1.6,
			life = { 1.6, 1.6 },
			size = { { 0, 3.4 }, { 0.5, 3.8 }, { 1, 3.4 } },
			transparency = { { 0, 1 }, { 0.3, 0.55 }, { 0.7, 0.55 }, { 1, 1 } },
			lightEmission = 1,
			lightInfluence = 0,
			brightness = 1,
			zOffset = 0.5,
			steady = true,
		},
		{
			-- the bright core inside the glass, flickering a touch
			name = "core",
			texture = "glow_core",
			role = "core",
			at = "body",
			speed = { 0.01, 0.01 },
			locked = true,
			rate = 3,
			life = { 0.7, 0.9 },
			size = { { 0, 1.1 }, { 0.5, 1.3 }, { 1, 1.1 } },
			transparency = { { 0, 1 }, { 0.25, 0.2 }, { 0.75, 0.25 }, { 1, 1 } },
			lightEmission = 1,
			lightInfluence = 0,
			brightness = 1.5,
			zOffset = 0.6,
		},
	},
	source = {
		from = "the library, for Goo Lineage V2's lamps at night (2026-11-15)",
		art = "free Creator Store pack textures (glow_soft, glow_core)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "A world lamp's glow: attach it to an anchor at the lantern's head (1 stud tall at refHeight), detach it by day. Hand the lamp's colour as palette.core.",
}
