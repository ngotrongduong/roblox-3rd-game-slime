-- Forge Strike: one hammer blow on Goo Lineage V2's anvil while a weapon is forged, one rung per gear tier (wood
-- Common, iron Uncommon, core Epic, bramble Mythic, legend Legendary). Played at the hammer's contact point on the
-- anvil face (Y up), once a blow, 2 or 3 blows 0.33 s apart, so it is short and cheap. Hot-metal sparks spray out and up
-- and fall back under gravity (bright orange-white needles laid along their flight), a tiny white contact flash, a
-- little puff of soot. From iron up the spray carries the tier's own flecks: iron green embers, core violet star
-- glints, bramble big orange fire flecks, legend gold stars with a gold glint on the flash.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

local SPARKS = {
	name = "sparks",
	texture = "needle_glow",
	color = { { 0, { 255, 250, 225 } }, { 0.4, { 255, 190, 90 } }, { 1, { 255, 110, 30 } } },
	at = "origin",
	direction = "Top",
	count = 14,
	life = { 0.3, 0.5 },
	size = { { 0, 0.32 }, { 1, 0.12 } },
	transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
	speed = { 9, 15 },
	spread = { 60, 60 },
	accel = { 0, -38, 0 },
	drag = 1.5,
	orientation = "VelocityParallel",
	rotation = { -90, -90 },
	lightEmission = 1,
	brightness = 2,
}

local FLASH = {
	name = "flash",
	texture = "star_glint_sharp",
	color = { 255, 245, 220 },
	at = "origin",
	count = 1,
	life = { 0.12, 0.12 },
	size = { { 0, 0.6 }, { 0.3, 1.6 }, { 1, 0.4 } },
	transparency = { { 0, 0 }, { 1, 1 } },
	rotation = { 0, 359 },
	lightEmission = 1,
	brightness = 2,
	zOffset = 1,
}

-- (a little soot off the struck metal, drawn normal: it reads in day and at night)
local SOOT = {
	name = "soot",
	texture = "smoke_puffs_flip",
	color = { { 0, { 95, 88, 82 } }, { 1, { 150, 145, 140 } } },
	at = "origin",
	direction = "Top",
	count = 2,
	life = { 0.45, 0.6 },
	size = { { 0, 0.4 }, { 1, 1.2 } },
	transparency = { { 0, 0.3 }, { 1, 1 } },
	speed = { 1, 2 },
	spread = { 40, 40 },
	rotation = { 0, 359 },
	lightEmission = 0,
	flipbook = { layout = "Grid4x4", mode = "OneShot" },
}

-- (the tier's own flecks thrown with the spray)
local function flecks(texture, colors, count, size, over)
	return with({
		name = "flecks",
		texture = texture,
		color = colors,
		at = "origin",
		direction = "Top",
		count = count,
		life = { 0.4, 0.65 },
		size = { { 0, size }, { 1, size * 0.3 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		speed = { 5, 10 },
		spread = { 70, 70 },
		accel = { 0, -22, 0 },
		drag = 2,
		rotation = { 0, 359 },
		rotSpeed = { -200, 200 },
		lightEmission = 1,
		brightness = 1.8,
	}, over)
end

return {
	id = "hit.forge_strike",
	name = "Forge Strike",
	kind = "hit",
	tier = "mid",
	host = "any",
	refHeight = 2,
	tags = { "forge", "anvil", "hammer", "sparks", "metal", "craft", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.06 },
	pieces = { SPARKS, FLASH, SOOT },
	variants = {
		wood = { tier = "cheap" },
		iron = {
			extra = { flecks("fire_specks", { { 0, { 200, 255, 190 } }, { 1, { 58, 155, 58 } } }, 8, 0.35) },
		},
		core = {
			extra = { flecks("sparkStar", { { 0, { 245, 230, 255 } }, { 1, { 138, 79, 208 } } }, 7, 0.45) },
		},
		bramble = {
			extra = {
				flecks("fire_specks", { { 0, { 255, 220, 140 } }, { 1, { 240, 138, 36 } } }, 10, 0.55, {
					accel = { 0, -12, 0 },
				}),
			},
		},
		legend = {
			pieces = {
				SPARKS,
				with(FLASH, { color = { 255, 230, 140 }, size = { { 0, 0.8 }, { 0.3, 2.2 }, { 1, 0.5 } } }),
				SOOT,
				flecks("sparkStar", { { 0, { 255, 250, 210 } }, { 1, { 247, 198, 0 } } }, 10, 0.5),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage V2's forge scene (2026-11-15)",
		art = "the owner's spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: needle_glow, star_glint_sharp, smoke_puffs_flip, fire_specks)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, contactCFrame, { variant = tierKey }) once per hammer blow, the frame on the anvil face with Y up. About 0.6 s. Wood is cheap; iron to legend add their own flecks (mid). The sparks fall in arcs; they do not bounce (particles do not collide).",
}
