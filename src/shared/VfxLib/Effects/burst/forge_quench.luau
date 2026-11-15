-- Forge Quench: a tempered piece quenched on Goo Lineage V2's anvil, one rung per gear tier. Played at the face centre
-- (Y up) with burst.forge_reveal, only when a piece is tempered. White steam billows up off the face for about 1.2 s
-- (solid smoke, drawn normal: it reads in bright day and at night), water droplets spit out and fall. Iron up: a
-- ring of steam rolls out over the face; core up: sizzle sparks in the tier's colour; legend: gold glints in the steam.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

local STEAM = {
	name = "steam",
	texture = "cg_smoke_plume_flip",
	color = { { 0, { 255, 255, 255 } }, { 1, { 225, 230, 235 } } },
	at = "origin",
	direction = "Top",
	shape = "Disc",
	radius = 0.6,
	life = { 0.9, 1.2 },
	size = { { 0, 0.8 }, { 0.4, 2.2 }, { 1, 3 } },
	transparency = { { 0, 0.05 }, { 0.6, 0.3 }, { 1, 1 } },
	speed = { 2.5, 4 },
	spread = { 12, 12 },
	drag = 1.2,
	accel = { 0, 1.5, 0 },
	rotation = { 0, 359 },
	rotSpeed = { -30, 30 },
	lightEmission = 0,
	lightInfluence = 0.7,
	flipbook = { layout = "Grid4x4", mode = "OneShot" },
	stream = { from = 0, to = 0.7, rate = { 16, 6 }, burst = 4 },
}

local DROPS = {
	name = "drops",
	texture = "droplet_gloss",
	color = { 230, 245, 255 },
	at = "origin",
	direction = "Top",
	count = 8,
	life = { 0.45, 0.7 },
	size = { { 0, 0.18 }, { 1, 0.12 } },
	transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
	speed = { 5, 8 },
	spread = { 55, 55 },
	accel = { 0, -30, 0 },
	orientation = "VelocityParallel",
	rotation = { 180, 180 },
	lightEmission = 0.2,
}

local RING = {
	name = "roll",
	texture = "dust_ring",
	color = { 245, 248, 252 },
	at = "origin",
	flat = true,
	count = 1,
	life = { 0.7, 0.7 },
	size = { { 0, 1 }, { 1, 4 } },
	transparency = { { 0, 0.2 }, { 1, 1 } },
	lightEmission = 0,
	flipbook = { layout = "Grid4x4", mode = "OneShot" },
}

local function sizzle(colors)
	return {
		name = "sizzle",
		texture = "needle_glow",
		color = colors,
		at = "origin",
		direction = "Top",
		shape = "Disc",
		radius = 0.7,
		life = { 0.15, 0.3 },
		size = { { 0, 0.22 }, { 1, 0.05 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		speed = { 4, 8 },
		spread = { 50, 50 },
		accel = { 0, -16, 0 },
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		lightEmission = 1,
		brightness = 2,
		stream = { from = 0, to = 0.6, rate = { 20, 8 } },
	}
end

return {
	id = "burst.forge_quench",
	name = "Forge Quench",
	kind = "burst",
	tier = "mid",
	host = "any",
	refHeight = 4,
	tags = { "forge", "anvil", "quench", "steam", "water", "craft", "rarity", "ladder", "goo_lineage" },
	blend = "normal",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.4 },
	pieces = { STEAM, DROPS },
	variants = {
		wood = {},
		iron = { extra = { RING } },
		core = { extra = { RING, sizzle({ { 0, { 245, 230, 255 } }, { 1, { 138, 79, 208 } } }) } },
		bramble = { extra = { RING, sizzle({ { 0, { 255, 230, 170 } }, { 1, { 240, 138, 36 } } }) } },
		legend = {
			extra = {
				RING,
				sizzle({ { 0, { 255, 250, 215 } }, { 1, { 247, 198, 0 } } }),
				with(sizzle({ { 0, { 255, 250, 215 } }, { 1, { 247, 198, 0 } } }), {
					name = "glints",
					texture = "star_twinkle",
					orientation = "FacingCamera",
					rotation = { -45, 45 },
					radius = 1,
					life = { 0.4, 0.6 },
					size = { { 0, 0 }, { 0.4, 0.4 }, { 1, 0 } },
					speed = { 2, 4 },
					accel = { 0, 1, 0 },
					stream = { from = 0.1, to = 1, rate = { 10, 6 } },
				}),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage V2's forge scene (2026-11-15)",
		art = "cg_smoke_plume_flip, droplet_gloss (ChatGPT for the library); dust_ring (EffectCraft); free Creator Store pack textures (no scripts: needle_glow, star_twinkle)",
		licence = "the library's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, faceCentreCFrame, { variant = tierKey }) with burst.forge_reveal, only when a piece is tempered. About 1.2 s of steam (drawn normal, solid: day and night). Every rung mid (a rare moment; the steam needs its area).",
}
