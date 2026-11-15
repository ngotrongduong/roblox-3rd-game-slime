-- Forge Reveal: the new weapon rising out of Goo Lineage V2's anvil face, one rung per gear tier. Played at the face
-- centre (Y up) as the weapon starts to rise (it climbs about 4 studs over 0.8 s; its name shows about 1 s later). A
-- column of light in the tier's colour climbs from the face at every rung, and each rung adds its own crafted piece on
-- top of the one below: wood (Common) a few sparks and a small flash; iron (Uncommon) a green ring sweeping out over
-- the face; core (Epic) violet crystal shards flying up and fading; bramble (Mythic) an orange flame pillar; legend
-- (Legendary) gold light rays round a white-gold core and a glitter rain, about 3 s. Low rungs are cheap.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

local function column(color, life, over)
	return with({
		name = "column",
		texture = "beam_light_shafts",
		colors = { { 255, 255, 245 }, color },
		from = { 0, 0, 0 },
		to = { 0, 7, 0 },
		width = { 1.6, 1.1 },
		face = true,
		life = life,
		emerge = 0.25,
		transparency = { { 0, 0.15 }, { 0.25, 0.1 }, { 0.7, 0.45 }, { 1, 1 } },
		grow = { { 0, 0.6 }, { 0.2, 1.1 }, { 1, 0.7 } },
		edge = { 0.85, 0 },
		speed = 2,
		glow = 1.6,
	}, over)
end

local function sparks(colors, count)
	return {
		name = "sparks",
		texture = "needle_glow",
		color = colors,
		at = "origin",
		direction = "Top",
		count = count,
		life = { 0.4, 0.7 },
		size = { { 0, 0.4 }, { 1, 0.12 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		speed = { 8, 14 },
		spread = { 45, 45 },
		accel = { 0, -20, 0 },
		drag = 1.5,
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		lightEmission = 1,
		brightness = 2,
	}
end

local function flash(color, size)
	return {
		name = "flash",
		texture = "star_flare_big",
		color = color,
		at = "origin",
		count = 1,
		life = { 0.3, 0.3 },
		size = { { 0, size * 0.3 }, { 0.25, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.35 }, { 1, 1 } },
		rotation = { 0, 0 },
		lightEmission = 1,
		brightness = 1.8,
		zOffset = 1,
	}
end

-- (a ring sweeping out over the anvil face)
local function ring(color)
	return {
		name = "ring",
		texture = "ring_halo",
		color = color,
		at = "origin",
		flat = true,
		count = 1,
		life = { 0.55, 0.55 },
		size = { { 0, 0.6 }, { 1, 4.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } },
		lightEmission = 1,
		brightness = 2,
		zOffset = 0.2,
	}
end

-- (crystal shards flung up, turning, fading)
local function shards(colors, count)
	return {
		name = "shards",
		texture = "shard_crystal",
		color = colors,
		at = "origin",
		direction = "Top",
		count = count,
		delay = 0.1,
		life = { 0.8, 1.1 },
		size = { { 0, 0.3 }, { 0.15, 0.7 }, { 1, 0.4 } },
		transparency = { { 0, 0 }, { 0.6, 0.15 }, { 1, 1 } },
		speed = { 6, 10 },
		spread = { 35, 35 },
		accel = { 0, -4, 0 },
		drag = 1.8,
		rotation = { 0, 359 },
		rotSpeed = { -160, 160 },
		lightEmission = 0.6,
		brightness = 1.6,
	}
end

-- (a pillar of flame licking up from the face round the rising weapon)
local function flames(colors, count)
	return {
		name = "flames",
		texture = "fire_column_flip",
		color = colors,
		at = "origin",
		direction = "Top",
		radius = 0.4,
		shape = "Disc",
		life = { 0.55, 0.75 },
		size = { { 0, 0.8 }, { 0.3, 2 }, { 1, 1.4 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } },
		speed = { 4, 6 },
		accel = { 0, 4, 0 },
		rotation = { -10, 10 },
		lightEmission = 0.8,
		brightness = 1.4,
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		stream = { from = 0.05, to = 0.85, rate = { 9, 4 }, burst = count },
	}
end

local GOLD = { 247, 198, 0 }

return {
	id = "burst.forge_reveal",
	name = "Forge Reveal",
	kind = "burst",
	tier = "heavy",
	host = "any",
	refHeight = 4,
	tags = { "forge", "anvil", "reveal", "craft", "weapon", "light", "column", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { rise = 0, peak = 0.35 },
	beams = { column({ 143, 151, 160 }, 1.2) },
	pieces = {
		sparks({ { 0, { 255, 250, 225 } }, { 1, { 255, 140, 50 } } }, 10),
		flash({ 235, 240, 245 }, 2.2),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			beams = { column({ 58, 155, 58 }, 1.3) },
			extra = { ring({ { 0, { 210, 255, 200 } }, { 1, { 58, 155, 58 } } }) },
		},
		core = {
			tier = "mid",
			beams = { column({ 138, 79, 208 }, 1.5) },
			pieces = {
				sparks({ { 0, { 255, 250, 225 } }, { 1, { 255, 140, 50 } } }, 10),
				flash({ 240, 225, 255 }, 2.6),
				ring({ { 0, { 240, 225, 255 } }, { 1, { 138, 79, 208 } } }),
				shards({ { 0, { 235, 215, 255 } }, { 1, { 138, 79, 208 } } }, 8),
			},
		},
		bramble = {
			tier = "mid",
			beams = { column({ 240, 138, 36 }, 1.7) },
			pieces = {
				sparks({ { 0, { 255, 250, 225 } }, { 1, { 255, 140, 50 } } }, 12),
				flash({ 255, 225, 170 }, 2.8),
				ring({ { 0, { 255, 225, 170 } }, { 1, { 240, 138, 36 } } }),
				shards({ { 0, { 255, 230, 190 } }, { 1, { 240, 138, 36 } } }, 6),
				flames({ { 0, { 255, 220, 140 } }, { 1, { 240, 110, 30 } } }, 3),
			},
			light = { color = { 255, 170, 90 }, keys = { { 0, 0 }, { 0.1, 3 }, { 1.4, 0 } }, range = 12 },
		},
		legend = {
			tier = "heavy",
			beams = {
				column(GOLD, 2.6, { width = { 1.8, 1.2 }, to = { 0, 8, 0 } }),
				-- (gold rays fanning round the column)
				column(GOLD, 2.4, {
					name = "rays",
					width = { 3.6, 4.4 },
					to = { 0, 6.5, 0 },
					emerge = 0.35,
					transparency = { { 0, 0.4 }, { 0.3, 0.3 }, { 0.75, 0.55 }, { 1, 1 } },
					speed = -1.2,
					glow = 1.3,
				}),
				-- (a white-gold core up the middle)
				column({ 255, 235, 150 }, 1.6, {
					name = "core",
					texture = "beam_starlight",
					width = { 0.5, 0.3 },
					glow = 2.4,
					speed = 3,
					zOffset = 0.5,
				}),
			},
			pieces = {
				sparks({ { 0, { 255, 252, 230 } }, { 1, GOLD } }, 12),
				flash({ 255, 235, 150 }, 3.4),
				ring({ { 0, { 255, 245, 200 } }, { 1, GOLD } }),
				shards({ { 0, { 255, 245, 210 } }, { 1, GOLD } }, 6),
				flames({ { 0, { 255, 235, 160 } }, { 1, { 247, 160, 20 } } }, 3),
				{
					-- glitter raining down round the risen weapon
					name = "glitter",
					texture = "star_twinkle",
					color = { { 0, { 255, 252, 230 } }, { 1, GOLD } },
					at = "origin",
					offset = { 0, 5, 0 },
					shape = "Disc",
					radius = 1.6,
					direction = "Bottom",
					life = { 0.9, 1.2 },
					size = { { 0, 0 }, { 0.2, 0.35 }, { 1, 0.1 } },
					transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
					speed = { 1, 2 },
					accel = { 0, -3, 0 },
					rotation = { -45, 45 },
					lightEmission = 1,
					brightness = 2.5,
					secondary = true,
					stream = { from = 0.5, to = 2.2, rate = { 22, 12 } },
				},
			},
			light = { color = { 255, 215, 110 }, keys = { { 0, 0 }, { 0.2, 4 }, { 1.5, 2.5 }, { 3, 0 } }, range = 16 },
		},
	},
	source = {
		from = "the library, for Goo Lineage V2's forge scene (2026-11-15)",
		art = "free Creator Store pack textures (no scripts: beam_light_shafts, beam_starlight, needle_glow, star_flare_big, ring_halo, shard_crystal, fire_column_flip, star_twinkle)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, faceCentreCFrame, { variant = tierKey }) as the weapon starts to rise out of the anvil face (Y up). Wood about 1.2 s, iron 1.3, core 1.5, bramble 1.7, legend about 3 s. markers.rise = 0, peak 0.35. Wood and iron cheap, core and bramble mid, legend heavy.",
}
