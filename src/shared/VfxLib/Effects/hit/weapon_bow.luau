-- Weapon Hit Bow: a plain arrow of one of Goo Lineage's bows PIERCES the foe. A flash at the puncture, needle streaks
-- of air flung along the arrow's line (out the far side of the foe), a small ring of air standing across the blow.
-- Drawn normal in a coloured body so it holds on snow. Wood: a tan flash, streaks, chips. Iron: a steel ring, a glint,
-- sparks. Core (Windwhisper): sky blue, a spinning ring of wind, feathers, gust curls. Bramble (Starfall): violet and
-- gold, falling stars, a flare, twinkles. Legend (Moonsong): navy and silver, a crescent moon stamped, the owner's
-- notes (clip) rising, a split ring on the floor.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.16, 0.16 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (a ring of air punched round the arrow's line: standing across it, carried a little along)
local function ring(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.26, 0.26 },
		size = { { 0, size * 0.3 }, { 0.5, size * 0.85 }, { 1, size } },
		transparency = { { 0, 0.05 }, { 0.5, 0.25 }, { 1, 1 } },
		direction = "Front",
		speed = { 3, 3 },
		spread = { 0, 0 },
		rotation = { 0, 359 },
		lightEmission = 0.5,
		brightness = 1.2,
		zOffset = 0.5,
	}, over)
end

-- (needle streaks of air flung along the arrow's line, forward through the foe)
local function streaks(name, color, count, over)
	return with({
		name = name,
		texture = "needle_glow",
		color = color,
		count = count,
		life = { 0.16, 0.26 },
		size = { { 0, 1.1 }, { 1, 0.6 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		direction = "Front",
		speed = { 12, 20 },
		spread = { 14, 14 },
		drag = 3,
		orientation = "VelocityParallel",
		rotation = { -90, -90 },
		lightEmission = 0.4,
		brightness = 1.3,
	}, over)
end

local function spray(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.25, 0.4 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		direction = "Back",
		speed = { 4, 9 },
		spread = { 60, 60 },
		drag = 3,
		rotation = { 0, 359 },
		lightEmission = 0,
	}, over)
end

local function mark(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		ground = true,
		flat = true,
		count = 1,
		life = { 0.4, 0.4 },
		size = { { 0, size * 0.4 }, { 0.3, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0.05 }, { 0.6, 0.25 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.3,
	}, over)
end

-- (readable on snow from the game's camera, 25 to 35 studs: a pale body is deepened to a saturated mid-tone and the
-- piece grown, its glow kept low; only the glints stay white. plan = { variant = growth })
local KEEP = { glint = true, glints = true, twinkles = true, spark = true, sparks = true, notes = true, dust = true }

local function deepen(c)
	local mean = (c[1] + c[2] + c[3]) / 3
	local out: { any } = {}
	for i = 1, 3 do
		out[i] = math.floor(math.clamp((mean + (c[i] - mean) * 1.5) * 0.8, 20, 235))
	end
	return out
end

local function deepenColor(color)
	if type(color[1]) == "number" then
		return deepen(color)
	end
	local out: { any } = {}
	for i, entry in color do
		out[i] = deepen(entry)
	end
	return out
end

local function readable(effect, plan)
	for name, grow in plan do
		local pieces = if name == "wood" then effect.pieces else effect.variants[name].pieces
		for _, piece in pieces do
			if not KEEP[piece.name] and piece.color and piece.role ~= "keep" then
				piece.color = deepenColor(piece.color)
				piece.lightEmission = math.min(piece.lightEmission or 0, 0.25)
			end
			if piece.size and not KEEP[piece.name] then
				local size = {}
				for i, key in piece.size do
					size[i] = { key[1], key[2] * grow, key[3] }
				end
				piece.size = size
			end
		end
	end
	return effect
end

return readable({
	id = "hit.weapon_bow",
	name = "Weapon Hit Bow",
	kind = "hit",
	tier = "mid",
	host = "any",
	refHeight = 2.2,
	tags = { "weapon", "bow", "arrow", "pierce", "impact", "rarity", "ladder", "goo_lineage", "snow_safe" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.06 },
	pieces = {
		flash("flash", "star_flare", { 215, 150, 80 }, 2.4, { lightEmission = 0.3, brightness = 1.5 }),
		streaks("streaks", { { 215, 170, 110 }, { 170, 115, 65 } }, 7, { lightEmission = 0.1 }),
		spray("chips", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 6, 0.4, {
			accel = { 0, -14, 0 },
			rotSpeed = { -300, 300 },
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				ring("ring", "ring_crisp", { 130, 160, 205 }, 3),
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 1.8),
				streaks("sparks", { { 255, 240, 200 }, { 255, 160, 60 } }, 12, { speed = { 14, 22 } }),
			},
		},
		core = {
			pieces = {
				ring("spin", "windspin_b", { 90, 175, 245 }, 3.6, { rotSpeed = { 200, 300 }, brightness = 1.4 }),
				streaks("streaks", { { 200, 235, 255 }, { 100, 180, 250 } }, 8, { speed = { 14, 24 } }),
				spray("feathers", "down_feather", { { 255, 255, 255 }, { 170, 215, 255 } }, 8, 0.7, {
					life = { 0.34, 0.4 },
					speed = { 3, 7 },
					accel = { 0, -2, 0 },
					rotSpeed = { -200, 200 },
					brightness = 1.3,
				}),
				spray("gusts", "gust_curl", { 175, 225, 255 }, 3, 1.1, {
					size = { { 0, 0.7 }, { 1, 1.7 } },
					transparency = { { 0, 0.15 }, { 1, 1 } },
					speed = { 2, 5 },
				}),
			},
		},
		bramble = {
			pieces = {
				flash("flare", "star_flare_big", { 215, 170, 255 }, 3.2, { lightEmission = 0.8 }),
				ring("ring", "ring_thorned", { 245, 195, 70 }, 4),
				streaks("streaks", { { 255, 235, 150 }, { 190, 130, 255 } }, 10, { speed = { 14, 24 } }),
				spray("stars", "star_fat", { { 255, 225, 110 }, { 200, 140, 255 } }, 7, 0.75, {
					life = { 0.34, 0.4 },
					direction = "Top",
					spread = { 90, 90 },
					accel = { 0, -16, 0 },
					lightEmission = 0.6,
				}),
				spray("twinkles", "star_twinkle", { 255, 245, 200 }, 8, 0.55, { lightEmission = 1, speed = { 5, 10 } }),
			},
			light = { color = { 215, 175, 255 }, keys = { { 0, 0 }, { 0.05, 1.8 }, { 0.35, 0 } }, range = 8 },
		},
		legend = {
			pieces = {
				flash("flare", "flare_bright", { 215, 225, 255 }, 3.6, { lightEmission = 0.8 }),
				-- (the crescent moon stamped on the puncture, drawn normal in silver blue)
				flash("moon", "crescent_moon", { 110, 135, 215 }, 3, {
					life = { 0.3, 0.3 },
					size = { { 0, 1.5 }, { 0.3, 3 }, { 1, 3.3 } },
					rotation = { -25, 25 },
					lightEmission = 0,
					brightness = 1.4,
					zOffset = 1,
				}),
				streaks("streaks", { { 235, 240, 255 }, { 150, 175, 255 } }, 12, { speed = { 14, 26 } }),
				-- (the owner's notes unfold and rise)
				spray("notes", "notes_flip", { 235, 240, 255 }, 5, 1.1, {
					life = { 0.4, 0.4 },
					direction = "Top",
					spread = { 40, 40 },
					speed = { 2, 5 },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					brightness = 1.4,
				}),
				mark("ring", "ring_split", { 150, 175, 255 }, 5.6, { lightEmission = 0.3 }),
			},
			light = { color = { 190, 210, 255 }, keys = { { 0, 0 }, { 0.05, 2.5 }, { 0.4, 0 } }, range = 10 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's plain weapon blows (2026-11-14, wave 2 of the game's fight effects)",
		art = "notes_flip (ChatGPT clip drawn for the library); free Creator Store pack textures (no scripts kept: star_flare, star_flare_big, flare_bright, needle_glow, shard_flat, ring_crisp, windspin_b, ring_thorned, ring_split, gust_curl, star_fat, star_twinkle, crescent_moon, star_glint_sharp); down_feather (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play('hit.weapon_bow', CFrame.lookAt(skin, skin + arrowDirection), { variant = rarity, scale = foeHeight / 2.2 }): at the foe's skin, -Z along the arrow (the streaks fly on that way). 0.2 to 0.4 s. Wood and iron are cheap, core to legend mid; bramble and legend flash a light, legend marks the floor.",
}, { wood = 1.35, core = 1.3, legend = 1.35 })
