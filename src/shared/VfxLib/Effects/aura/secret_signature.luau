-- Secret Signatures: every Secret slime's own small effect, one variant each (Goo Lineage V2, 2026-11-10). The owner:
-- "simple, but fitting each slime, so every slime has an identity of its own"; then, on the second round: "the
-- particles need not be big or loud, but they must truly fit the slime and be beautiful". Each variant is one or two
-- pieces that say what the slime IS, matched to the art on its skin (snow falls on the Snow Rabbit, daisies tumble off
-- the Daisy Chick, a moth circles the Twilight Moth like a lamp, koi leap out of the Yin-Yang Koi); the second piece is
-- secondary (gone on Low quality). Variants are named after the slime in snake case ("Jack-o'-Slime" -> jack_o_slime).
-- No ground discs, no rings, no rarity glow (the owner's vetoes).
local WHITE = { 255, 255, 255 }
local SNOW = { 235, 245, 255 }
local ICY = { 160, 210, 255 }
local PINK = { 255, 140, 185 }
local SAKURA = { 255, 185, 210 }
local YELLOW = { 255, 225, 80 }
local GOLD = { 255, 195, 50 }
local MINT = { 140, 240, 200 }
local ORANGE = { 255, 140, 40 }
local RED = { 230, 45, 55 }
local CRIMSON = { 180, 15, 35 }
local VIOLET = { 170, 105, 255 }
local PURPLE = { 125, 60, 210 }
local LILAC = { 205, 175, 255 }
local NAVY = { 40, 50, 125 }
local GRAY = { 150, 155, 165 }
local DARK = { 45, 38, 60 }
local GREEN = { 80, 190, 80 }
local LEAF = { 120, 195, 60 }
local LIME = { 190, 240, 70 }
local AQUA = { 70, 205, 230 }
local CYAN = { 60, 230, 255 }
local SKY = { 130, 200, 255 }
local BLUE = { 70, 140, 255 }
local CORAL = { 255, 160, 150 }
local MAGENTA = { 230, 50, 160 }
local COPPER = { 215, 120, 55 }
local BROWN = { 140, 85, 45 }
local TAN = { 205, 175, 125 }
local SEED = { 35, 28, 28 }
-- Every size below times this. The first round drew everything 1.8 times bigger so nothing was lost at the village's
-- camera distance; the owner then asked for small and quiet, so the pieces are now near their real size and reach the
-- eye by their picture and motion, not by bulk.
local GROW = 1.25

local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (each preset: a motion; numbers in studs and seconds for a 3-stud slime)
-- Falling from over the head, drifting and tumbling: snow, petals, leaves, rain.
local function fall(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "above",
		box = { 1.4, 0, 1.4 },
		rate = 4,
		life = { 2.4, 3.2 },
		size = { { 0, 0 }, { 0.12, 0.32 }, { 0.85, 0.3 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.85, 0.05 }, { 1, 1 } },
		speed = { 0.1, 0.4 },
		spread = { 60, 60 },
		direction = "Bottom",
		accel = { 0, -1.6, 0 },
		drag = 1,
		rotation = { -180, 180 },
		rotSpeed = { -90, 90 },
		lightEmission = 0.1,
		locked = false,
	}, over)
end

-- Rising off the body and fading: embers, wisps, pollen, bubbles.
local function rise(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 0.9, 0.5, 0.9 },
		rate = 3,
		life = { 1.6, 2.2 },
		size = { { 0, 0 }, { 0.2, 0.32 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		speed = { 0.6, 1.2 },
		spread = { 25, 25 },
		direction = "Top",
		accel = { 0, 0.6, 0 },
		drag = 0.5,
		rotation = { -180, 180 },
		rotSpeed = { -60, 60 },
		lightEmission = 0.2,
		locked = false,
	}, over)
end

-- Rising off the skin of its upper half (a slime is a dome: anything born inside it is hidden by its body), peeling
-- away and floating up: flames, bubbles, embers, gems, wisps.
local function skin(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		radius = 1.6,
		shape = "Sphere",
		shapeStyle = "Surface",
		shapePartial = 0.5,
		direction = "Top",
		rate = 3,
		life = { 1.4, 1.8 },
		size = { { 0, 0 }, { 0.2, 0.3 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		speed = { 0.2, 0.4 },
		accel = { 0, 0.9, 0 },
		drag = 0.3,
		rotation = { -180, 180 },
		rotSpeed = { -60, 60 },
		lightEmission = 0.2,
		locked = false,
	}, over)
end

-- Popping on the skin of its upper half, grow then shrink, riding the body: spots, glints, sparkles.
local function pop(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		radius = 1.6,
		shape = "Sphere",
		shapeStyle = "Surface",
		shapePartial = 0.5,
		direction = "Top",
		rate = 2.5,
		life = { 0.7, 1 },
		size = { { 0, 0 }, { 0.35, 0.34 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.2 } },
		speed = { 0, 0 },
		rotation = { -180, 180 },
		rotSpeed = { -45, 45 },
		lightEmission = 0.3,
		locked = true,
	}, over)
end

-- Circling the body, its particles left behind as a short trail: foxfire, leaves, shards. With `steady` and `locked`
-- one particle rides the circle the whole time (a clock hand): a moth round a lamp, a planet, a cloud.
local function orbit(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		orbit = { radius = 1.7, period = 3, phase = 0, y = 1.8 },
		rate = 10,
		life = { 0.5, 0.6 },
		size = { { 0, 0.3 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.4 } },
		speed = { 0, 0 },
		rotation = { -180, 180 },
		lightEmission = 0.3,
		locked = false,
	}, over)
end

-- Dripping off the lower body: honey, poison, water.
local function drip(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "waist",
		box = { 1.3, 0.25, 1.3 },
		rate = 1.5,
		life = { 0.8, 1.1 },
		size = { { 0, 0 }, { 0.2, 0.24 }, { 1, 0.2 } },
		transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
		speed = { 0, 0.2 },
		direction = "Bottom",
		accel = { 0, -6, 0 },
		rotation = { 0, 0 },
		orientation = "FacingCameraWorldUp",
		lightEmission = 0.1,
		locked = false,
	}, over)
end

-- Sprayed up from the top of the head, falling back: seeds, juice, a whale's spout, a leaping koi.
local function spray(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "head",
		box = { 0.3, 0, 0.3 },
		rate = 3,
		life = { 0.8, 1.1 },
		size = { { 0, 0.2 }, { 1, 0.12 } },
		transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
		speed = { 3, 5 },
		spread = { 25, 25 },
		direction = "Top",
		accel = { 0, -10, 0 },
		rotation = { -180, 180 },
		rotSpeed = { -180, 180 },
		lightEmission = 0.1,
		locked = false,
	}, over)
end

-- Puffed out and growing as it rises: smoke, steam, fumes, breath.
local function puff(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "head",
		box = { 0.35, 0, 0.35 },
		rate = 1.2,
		life = { 1.6, 2.2 },
		size = { { 0, 0.25 }, { 1, 1.1 } },
		transparency = { { 0, 0.3 }, { 0.3, 0.15 }, { 1, 1 } },
		speed = { 0.6, 1 },
		spread = { 15, 15 },
		direction = "Top",
		accel = { 0, 0.3, 0 },
		drag = 0.4,
		rotation = { -180, 180 },
		rotSpeed = { -30, 30 },
		lightEmission = 0,
		locked = false,
	}, over)
end

-- Motes hanging in the air round the body, drifting slowly: pollen, spores, dust, specks, butterflies.
local function hang(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		radius = 2,
		shape = "Sphere",
		shapeStyle = "Volume",
		shapePartial = 0.5,
		direction = "Top",
		rate = 3,
		life = { 2, 3 },
		size = { { 0, 0 }, { 0.3, 0.16 }, { 0.7, 0.16 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.2 } },
		speed = { 0.15, 0.4 },
		spread = { 180, 180 },
		drag = 0.3,
		rotation = { -180, 180 },
		rotSpeed = { -40, 40 },
		lightEmission = 0.4,
		locked = false,
	}, over)
end

-- Held at the top of the head, riding it: a crown, a crest, a cloud.
local function crown(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "crown",
		box = { 0.4, 0, 0.4 },
		rate = 1,
		life = { 2.5, 3 },
		size = { { 0, 0 }, { 0.15, 0.42 }, { 0.85, 0.42 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0 } },
		speed = { 0, 0 },
		rotation = { -30, 30 },
		rotSpeed = { -10, 10 },
		lightEmission = 0.2,
		locked = true,
	}, over)
end

-- Kicked up at the feet while it moves (a share stays standing still): dust, snow, clouds, smoke.
local function kick(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "feet",
		box = { 1.3, 0, 1.3 },
		motion = "run",
		idle = 0.1,
		rate = 8,
		life = { 0.5, 0.8 },
		size = { { 0, 0.25 }, { 1, 0.7 } },
		transparency = { { 0, 0.2 }, { 1, 1 } },
		speed = { 0.5, 1.2 },
		spread = { 70, 70 },
		direction = "Top",
		drag = 2,
		rotation = { -180, 180 },
		rotSpeed = { -60, 60 },
		lightEmission = 0,
		locked = false,
	}, over)
end

local function second(piece)
	piece.secondary = true
	return piece
end

local function flip(layout, mode, fps)
	return { layout = layout, mode = mode, fps = fps, random = true }
end

local SNOWFLAKES = flip("Grid4x4", "Loop", { 1, 2 })
local FOUR = flip("Grid4x4", "OneShot")
local TWO = flip("Grid2x2", "Loop", { 0.5, 0.5 })
-- (petals_small_flip: one petal turning over, so a falling petal flutters)
local PETALS = flip("Grid4x4", "Loop", { 8, 12 })
-- (leaves_solid: four leaves; each particle keeps the one it starts on)
local LEAVES = flip("Grid2x2", "Loop", { 0, 0 })
-- (butterfly_flip, moth_flip: wings beating)
local FLAP = flip("Grid2x2", "Loop", { 8, 11 })

-- A circling companion: one particle riding the orbit all the time (steady, locked to its moving attachment).
local function companion(over)
	return with({
		rate = 0.25,
		life = { 4.05, 4.05 },
		transparency = { { 0, 0 }, { 1, 0 } },
		rotation = { 0, 0 },
		locked = true,
		steady = true,
	}, over)
end

local variants = {
	-- white + white: snowflakes drifting down on it, puffs of snow kicked up as it hops
	snow_rabbit = {
		pieces = {
			fall("snow", "snow_crystals_flip", SNOW, {
				flipbook = SNOWFLAKES,
				rate = 5,
				size = { { 0, 0 }, { 0.12, 0.22 }, { 1, 0 } },
				lightEmission = 0.3,
			}),
			second(
				kick("snowpuff", "puff_solid", SNOW, { rate = 6, idle = 0.15, size = { { 0, 0.15 }, { 1, 0.45 } } })
			),
		},
	},
	-- cherry-blossom petals fluttering down sideways in a breeze, now and then a whole blossom
	sakura_bunny = {
		pieces = {
			fall("petals", "petals_small_flip", SAKURA, {
				flipbook = PETALS,
				accel = { 0.8, -1.2, 0 },
				rate = 5,
				size = { { 0, 0 }, { 0.12, 0.36 }, { 0.85, 0.32 }, { 1, 0 } },
				rotSpeed = { -30, 30 },
			}),
			second(fall("blossoms", "blossom_five", { 255, 215, 230 }, {
				accel = { 0.6, -1, 0 },
				rate = 0.7,
				size = { { 0, 0 }, { 0.12, 0.28 }, { 0.85, 0.26 }, { 1, 0 } },
				rotSpeed = { -40, 40 },
			})),
		},
	},
	-- little daisies tumbling off its head, fluffy yellow chick down floating up
	daisy_chick = {
		pieces = {
			fall("daisies", "daisy_colour", nil, {
				role = "keep",
				at = "head",
				box = { 1, 0, 1 },
				rate = 1.6,
				life = { 2, 2.6 },
				speed = { 0.3, 0.6 },
				spread = { 70, 70 },
				size = { { 0, 0 }, { 0.12, 0.26 }, { 0.85, 0.24 }, { 1, 0 } },
				rotSpeed = { -50, 50 },
				lightEmission = 0,
			}),
			second(skin("down", "down_feather", YELLOW, {
				rate = 1,
				life = { 2, 2.6 },
				speed = { 0.2, 0.4 },
				accel = { 0, 0.3, 0 },
				size = { { 0, 0 }, { 0.2, 0.22 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotSpeed = { -40, 40 },
				lightEmission = 0.1,
			})),
		},
	},
	-- white blossoms floating up off it like spirits, turning mint as they go; mint spirit glints round it
	lily_spirit = {
		pieces = {
			skin("lilies", "blossom_five", { WHITE, MINT }, {
				rate = 2,
				life = { 2, 2.6 },
				size = { { 0, 0 }, { 0.2, 0.26 }, { 1, 0.18 } },
				transparency = { { 0, 0 }, { 0.75, 0 }, { 1, 1 } },
				speed = { 0.2, 0.35 },
				accel = { 0, 0.5, 0 },
				rotSpeed = { -30, 30 },
				lightEmission = 0.3,
			}),
			second(hang("glints", "sparkStar", MINT, { rate = 2.5, lightEmission = 0.6 })),
		},
	},
	-- two foxfire flames circling, orange fading to cream
	creamsicle_fox = {
		pieces = {
			-- (deep orange: cream fire vanishes against its cream swirls)
			orbit(
				"foxfire",
				"flame_soft",
				{ { 255, 165, 50 }, { 255, 105, 35 } },
				{ rate = 9, size = { { 0, 0.44 }, { 1, 0 } }, lightEmission = 0.2 }
			),
			second(orbit("foxfire2", "flame_soft", { { 255, 165, 50 }, { 255, 105, 35 } }, {
				rate = 9,
				orbit = { radius = 1.7, period = 3, phase = 0.5, y = 1.8 },
				size = { { 0, 0.44 }, { 1, 0 } },
				lightEmission = 0.2,
			})),
		},
	},
	-- peppermint candies floating up off it, turning; mint sparkles winking on its stripes
	peppermint_slime = {
		pieces = {
			skin("candies", "peppermint_candy", nil, {
				role = "keep",
				rate = 1.2,
				life = { 1.8, 2.2 },
				speed = { 0.2, 0.4 },
				accel = { 0, 0.5, 0 },
				size = { { 0, 0 }, { 0.15, 0.24 }, { 0.85, 0.24 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotSpeed = { -90, 90 },
				lightEmission = 0,
			}),
			second(pop("mint", "sparkStar", MINT, { rate = 2.5, lightEmission = 0.5 })),
		},
	},
	-- lilac orchid petals falling slowly, violet moon twinkles round it
	moon_orchid = {
		pieces = {
			fall("petals", "petals_small_flip", LILAC, {
				flipbook = PETALS,
				rate = 3,
				accel = { 0, -0.9, 0 },
				size = { { 0, 0 }, { 0.12, 0.36 }, { 0.85, 0.32 }, { 1, 0 } },
				rotSpeed = { -30, 30 },
			}),
			second(
				hang(
					"moonglow",
					"moteArcane",
					nil,
					{ role = "keep", rate = 2, size = { { 0, 0 }, { 0.3, 0.22 }, { 1, 0 } } }
				)
			),
		},
	},
	-- snowflakes hanging in the cold air round it, an icy wind curling round its fur
	arctic_wolf = {
		pieces = {
			hang("frost", "snow_crystals_flip", ICY, {
				flipbook = SNOWFLAKES,
				rate = 3.5,
				size = { { 0, 0 }, { 0.3, 0.2 }, { 0.7, 0.2 }, { 1, 0 } },
				speed = { 0.1, 0.3 },
				lightEmission = 0.4,
			}),
			second(orbit("wind", "gust_curl", { WHITE, ICY }, {
				rate = 2,
				life = { 1, 1.3 },
				orbit = { radius = 1.75, period = 2.2, phase = 0, y = 1.2 },
				size = { { 0, 0.36 }, { 1, 0.46 } },
				transparency = { { 0, 1 }, { 0.25, 0.25 }, { 1, 1 } },
				rotation = { -15, 15 },
				lightEmission = 0.3,
			})),
		},
	},
	-- its own little cloud floating over its head, wisps of wool drifting off it
	cloud_sheep = {
		pieces = {
			crown("cloud", "cloud_cartoon", WHITE, {
				lift = 0.5,
				box = { 0, 0, 0 },
				rate = 0.5,
				life = { 4, 4 },
				size = { { 0, 0.48 }, { 1, 0.48 } },
				transparency = { { 0, 1 }, { 0.25, 0.05 }, { 0.75, 0.05 }, { 1, 1 } },
				rotation = { -8, 8 },
				rotSpeed = { -4, 4 },
				lightEmission = 0.35,
				steady = true,
			}),
			second(hang("wool", "puff_solid", WHITE, { at = "crown", radius = 0.9, rate = 1.5, lightEmission = 0 })),
		},
	},
	-- a white koi and a black koi leaping out of it in arcs, head first
	yin_yang_koi = {
		pieces = {
			spray("light", "koi_top", WHITE, {
				rate = 0.9,
				life = { 0.9, 1.1 },
				speed = { 3, 3.8 },
				spread = { 30, 30 },
				accel = { 0, -8, 0 },
				size = { { 0, 0.32 }, { 1, 0.32 } },
				transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
				orientation = "VelocityParallel",
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			}),
			second(spray("dark", "koi_top", { 50, 48, 60 }, {
				rate = 0.9,
				life = { 0.9, 1.1 },
				speed = { 3, 3.8 },
				spread = { 30, 30 },
				accel = { 0, -8, 0 },
				size = { { 0, 0.32 }, { 1, 0.32 } },
				transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
				orientation = "VelocityParallel",
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0,
			})),
		},
	},
	-- pink pollen floating round it, rose twinkles rising
	rose_fairy = {
		pieces = {
			hang(
				"pollen",
				"dot_round",
				PINK,
				{ rate = 4, size = { { 0, 0 }, { 0.3, 0.12 }, { 0.7, 0.12 }, { 1, 0 } } }
			),
			second(
				skin(
					"twinkle",
					"sparkStar",
					PINK,
					{ rate = 2, size = { { 0, 0 }, { 0.3, 0.24 }, { 1, 0 } }, lightEmission = 0.4 }
				)
			),
		},
	},
	-- peach blossoms drifting down and turning, yellow pollen sparkles rising
	peach_blossom = {
		pieces = {
			fall("blossoms", "peach_blossom", nil, {
				role = "keep",
				rate = 1.8,
				life = { 2.6, 3.2 },
				accel = { 0.4, -1, 0 },
				size = { { 0, 0 }, { 0.12, 0.28 }, { 0.85, 0.26 }, { 1, 0 } },
				rotSpeed = { -40, 40 },
				lightEmission = 0,
			}),
			second(rise("pollen", "star_fat", YELLOW, {
				at = "head",
				box = { 0.6, 0, 0.6 },
				rate = 2,
				size = { { 0, 0 }, { 0.3, 0.14 }, { 1, 0 } },
			})),
		},
	},
	-- seeds spat up out of its top, a little pink juice with them
	watermelon_frog = {
		pieces = {
			spray("seeds", "blob_solid", SEED, { rate = 1.5, size = { { 0, 0.1 }, { 1, 0.08 } }, lightEmission = 0 }),
			second(spray("juice", "droplet_gloss", { 255, 90, 120 }, {
				rate = 2.5,
				speed = { 2, 3.5 },
				size = { { 0, 0.14 }, { 1, 0.1 } },
				orientation = "VelocityParallel",
				rotation = { 180, 180 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			})),
		},
	},
	-- coral-pink bubbles rising from its gills, little peach ones between them
	coral_axolotl = {
		pieces = {
			rise("bubbles", "bubble_gloss", CORAL, {
				at = "head",
				box = { 1, 0.2, 0.9 },
				rate = 2,
				life = { 1.6, 2 },
				speed = { 0.5, 0.9 },
				size = { { 0, 0 }, { 0.2, 0.22 }, { 1, 0.18 } },
				accel = { 0.2, 0.4, 0 },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.15,
			}),
			second(rise("fizz", "bubble_gloss", { 255, 205, 160 }, {
				at = "head",
				box = { 1, 0.2, 0.9 },
				rate = 2.5,
				size = { { 0, 0 }, { 0.2, 0.11 }, { 1, 0.09 } },
				speed = { 0.9, 1.4 },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
			})),
		},
	},
	-- chubby pink hearts floating up off it, swaying; a pink feather now and then
	lovebird_slime = {
		pieces = {
			rise("hearts", "heart_puffy", { PINK, { 235, 70, 100 } }, {
				at = "chest",
				box = { 1, 0.3, 1 },
				rate = 2,
				life = { 1.6, 2 },
				speed = { 0.5, 0.9 },
				accel = { 0, 0.3, 0 },
				size = { { 0, 0 }, { 0.2, 0.26 }, { 1, 0.16 } },
				rotation = { -15, 15 },
				rotSpeed = { -20, 20 },
				lightEmission = 0.2,
			}),
			second(fall("feather", "feather", PINK, {
				at = "chest",
				box = { 0.8, 0, 0.8 },
				rate = 0.6,
				size = { { 0, 0 }, { 0.12, 0.28 }, { 0.85, 0.26 }, { 1, 0 } },
			})),
		},
	},
	-- little pink-to-violet butterflies fluttering round it, dream dust drifting free
	dream_butterfly = {
		pieces = {
			hang("butterflies", "butterfly_flip", { PINK, VIOLET }, {
				flipbook = FLAP,
				rate = 1.2,
				life = { 2.6, 3.2 },
				size = { { 0, 0 }, { 0.15, 0.36 }, { 0.85, 0.36 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				speed = { 0.4, 0.8 },
				rotation = { -25, 25 },
				rotSpeed = { -15, 15 },
				lightEmission = 0.2,
			}),
			second(hang("dust", "star4_drift", LILAC, { rate = 4, speed = { 0.3, 0.7 } })),
		},
	},
	-- a pale moth circling it as round a lamp, a pink crescent glowing on its head
	twilight_moth = {
		pieces = {
			orbit(
				"moth",
				"moth_flip",
				{ 255, 215, 235 },
				companion({
					flipbook = FLAP,
					orbit = { radius = 1.8, period = 4, phase = 0, y = 2.3 },
					size = { { 0, 0.36 }, { 1, 0.36 } },
					lightEmission = 0.3,
				})
			),
			second(crown("moon", "crescent_smile", PINK, {
				lift = 0.3,
				box = { 0, 0, 0 },
				rate = 0.5,
				life = { 4, 4 },
				size = { { 0, 0.26 }, { 1, 0.26 } },
				transparency = { { 0, 1 }, { 0.25, 0.1 }, { 0.75, 0.1 }, { 1, 1 } },
				rotation = { -20, -20 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.6,
				steady = true,
			})),
		},
	},
	-- pink roses blooming on its back, rose petals scattering as it scurries
	rose_hedgehog = {
		pieces = {
			pop("roses", "rose_top", { PINK, { 215, 70, 120 } }, {
				at = "chest",
				radius = 1.1,
				rate = 1.4,
				life = { 1.8, 2.4 },
				size = { { 0, 0 }, { 0.2, 0.26 }, { 0.8, 0.26 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotSpeed = { -10, 10 },
				lightEmission = 0.1,
			}),
			second(kick("petals", "petals_small_flip", PINK, {
				idle = 0.3,
				rate = 5,
				life = { 0.9, 1.2 },
				flipbook = PETALS,
				size = { { 0, 0.3 }, { 1, 0.22 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				accel = { 0, -2, 0 },
				lightEmission = 0.1,
			})),
		},
	},
	-- little plum bats fluttering out of it, dark red roses drifting down
	gothic_bat = {
		pieces = {
			-- (bats_flip is 2 x 2: wings open and folded, drawn head to the left, so turned a quarter to stand upright)
			rise("bats", "bats_flip", { 70, 30, 70 }, {
				flipbook = flip("Grid2x2", "Loop", { 8, 12 }),
				rate = 1.5,
				life = { 1.2, 1.6 },
				speed = { 1.5, 2.5 },
				spread = { 70, 70 },
				size = { { 0, 0.2 }, { 0.3, 0.4 }, { 1, 0.34 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotation = { 80, 100 },
				rotSpeed = { 0, 0 },
				lightEmission = 0,
			}),
			second(fall("roses", "rose_top", { 160, 25, 60 }, {
				rate = 0.9,
				size = { { 0, 0 }, { 0.12, 0.22 }, { 0.85, 0.2 }, { 1, 0 } },
				rotSpeed = { -30, 30 },
			})),
		},
	},
	-- a mane of golden flame licks standing out round its head, sun motes rising
	sun_lion = {
		pieces = {
			pop("mane", "flame_tip", { YELLOW, GOLD, ORANGE }, {
				at = "chest",
				radius = 1.35,
				orientation = "VelocityParallel",
				speed = { 0.7, 1 },
				shapeInOut = "Outward",
				rate = 10,
				life = { 0.45, 0.6 },
				size = { { 0, 0.34 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0.4 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
				locked = true,
			}),
			second(skin("motes", "dot_round", { 255, 215, 100 }, {
				rate = 3,
				speed = { 0.5, 0.9 },
				size = { { 0, 0 }, { 0.2, 0.1 }, { 1, 0 } },
				lightEmission = 0.8,
			})),
		},
	},
	-- lemon slices popping out of its top and spinning, a spritz of juice
	lemon_gecko = {
		pieces = {
			spray("lemons", "lemon_slice", nil, {
				role = "keep",
				rate = 1.2,
				life = { 0.9, 1.2 },
				speed = { 2.5, 3.5 },
				spread = { 35, 35 },
				accel = { 0, -9, 0 },
				size = { { 0, 0.24 }, { 1, 0.24 } },
				transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
				rotSpeed = { -180, 180 },
				lightEmission = 0,
			}),
			second(spray("spritz", "droplet_gloss", { 255, 245, 140 }, {
				rate = 2,
				speed = { 2, 3 },
				size = { { 0, 0.11 }, { 1, 0.08 } },
				orientation = "VelocityParallel",
				rotation = { 180, 180 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.3,
			})),
		},
	},
	-- a flame crest on its crown, golden feathers drifting down
	sun_phoenix = {
		pieces = {
			rise("crest", "flame_tip", { GOLD, ORANGE }, {
				at = "head",
				box = { 0.35, 0, 0.2 },
				rate = 8,
				life = { 0.5, 0.7 },
				speed = { 1, 1.6 },
				spread = { 15, 15 },
				size = { { 0, 0.38 }, { 1, 0 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.5,
			}),
			second(
				fall(
					"feathers",
					"feather",
					{ GOLD, ORANGE },
					{ rate = 0.8, size = { { 0, 0 }, { 0.12, 0.28 }, { 0.85, 0.26 }, { 1, 0 } } }
				)
			),
		},
	},
	-- small flames licking up off its fiery markings, a few sparks flying off them
	fire_salamander = {
		pieces = {
			-- (full-colour curls of fire: their yellow hearts still read on its red skin)
			skin("flames", "fire_curl_flip", nil, {
				role = "keep",
				flipbook = FOUR,
				rate = 5,
				life = { 0.7, 0.9 },
				speed = { 0.3, 0.5 },
				accel = { 0, 2, 0 },
				size = { { 0, 0.36 }, { 1, 0.44 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.2,
			}),
			second(skin("sparks", "ember_streak", { YELLOW, ORANGE }, {
				rate = 1.5,
				life = { 0.4, 0.6 },
				speed = { 1.5, 2.5 },
				accel = { 0, -3, 0 },
				size = { { 0, 0.2 }, { 1, 0.06 } },
				orientation = "VelocityParallel",
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.7,
			})),
		},
	},
	-- purple feathers turning to gold as they rise round it, a gold glint on its crest
	royal_griffin = {
		pieces = {
			rise("feathers", "feather", { PURPLE, GOLD }, {
				at = "feet",
				box = { 1.4, 0, 1.4 },
				rate = 2.5,
				life = { 2, 2.6 },
				speed = { 0.8, 1.2 },
				size = { { 0, 0 }, { 0.2, 0.36 }, { 1, 0.2 } },
				rotSpeed = { -120, 120 },
				lightEmission = 0.1,
			}),
			second(crown("crest", "star_fat", GOLD, {
				at = "head",
				rate = 0.8,
				life = { 0.8, 1 },
				size = { { 0, 0 }, { 0.4, 0.4 }, { 1, 0 } },
				lightEmission = 0.6,
			})),
		},
	},
	-- small yellow stars blinking on round it, a navy feather now and then
	star_owl = {
		pieces = {
			pop("stars", "star_fat", YELLOW, {
				radius = 1.8,
				shapeStyle = "Volume",
				rate = 3,
				size = { { 0, 0 }, { 0.35, 0.26 }, { 1, 0 } },
				lightEmission = 0.5,
			}),
			second(fall("feather", "feather", NAVY, {
				rate = 0.8,
				size = { { 0, 0 }, { 0.12, 0.3 }, { 0.85, 0.28 }, { 1, 0 } },
				lightEmission = 0,
			})),
		},
	},
	-- yellow lightning snapping round its horns, static sparkles crackling in its wool
	thunder_ram = {
		pieces = {
			pop("bolts", "bolts_comic", { 255, 250, 170 }, {
				at = "head",
				radius = 1.1,
				flipbook = TWO,
				rate = 3,
				life = { 0.3, 0.4 },
				size = { { 0, 0.5 }, { 1, 0.6 } },
				lightEmission = 0.8,
			}),
			second(pop("static", "sparkStar", { 255, 240, 150 }, {
				rate = 3,
				size = { { 0, 0 }, { 0.35, 0.24 }, { 1, 0 } },
				lightEmission = 0.7,
			})),
		},
	},
	-- little honeybees buzzing round it, honey dripping off it
	honeybee_slime = {
		pieces = {
			hang("bees", "bee_flip", nil, {
				role = "keep",
				flipbook = flip("Grid2x2", "Loop", { 14, 18 }),
				rate = 1,
				life = { 2.4, 3 },
				size = { { 0, 0 }, { 0.12, 0.34 }, { 0.88, 0.34 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				speed = { 0.5, 0.9 },
				rotation = { -10, 10 },
				rotSpeed = { -10, 10 },
				lightEmission = 0,
			}),
			second(drip("honey", "honey_drop", nil, {
				role = "keep",
				rate = 1.5,
				size = { { 0, 0 }, { 0.2, 0.3 }, { 1, 0.26 } },
			})),
		},
	},
	-- leaves circling it, tiny flowers opening on its head
	forest_dryad = {
		pieces = {
			orbit("leaves", "leaves_solid", LEAF, {
				flipbook = LEAVES,
				rate = 3,
				life = { 1.2, 1.5 },
				orbit = { radius = 1.8, period = 3.5, phase = 0, y = 2 },
				size = { { 0, 0.32 }, { 1, 0.2 } },
				speed = { 0.2, 0.4 },
				spread = { 180, 180 },
				rotSpeed = { -60, 60 },
				lightEmission = 0,
			}),
			second(pop("flowers", "blossom_five", { 255, 235, 245 }, {
				at = "head",
				radius = 0.7,
				rate = 1,
				life = { 1.6, 2 },
				size = { { 0, 0 }, { 0.25, 0.22 }, { 0.8, 0.22 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotSpeed = { -10, 10 },
				lightEmission = 0.1,
			})),
		},
	},
	-- autumn leaves, orange to red to brown, tumbling down; leaves kicked up round its feet as it runs
	autumn_fox = {
		pieces = {
			fall("leaves", "leaves_solid", { ORANGE, RED, BROWN }, {
				flipbook = LEAVES,
				rate = 3,
				rotSpeed = { -200, 200 },
				accel = { 0.5, -1.6, 0 },
				size = { { 0, 0 }, { 0.12, 0.3 }, { 0.85, 0.28 }, { 1, 0 } },
			}),
			second(kick("kicked", "leaves_solid", { ORANGE, BROWN }, {
				flipbook = LEAVES,
				idle = 0.2,
				rate = 5,
				life = { 0.7, 1 },
				speed = { 1, 1.8 },
				spread = { 50, 50 },
				accel = { 0, -3, 0 },
				drag = 1,
				size = { { 0, 0.22 }, { 1, 0.18 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotSpeed = { -200, 200 },
			})),
		},
	},
	-- red holly berries round its antlers, holly leaves between them
	holly_deer = {
		pieces = {
			pop(
				"berries",
				"blob_solid",
				RED,
				{ at = "head", radius = 0.8, rate = 3, size = { { 0, 0 }, { 0.3, 0.2 }, { 1, 0 } } }
			),
			second(pop("holly", "leaves_solid", GREEN, {
				at = "head",
				radius = 1,
				flipbook = LEAVES,
				rate = 2.5,
				size = { { 0, 0 }, { 0.35, 0.36 }, { 1, 0 } },
			})),
		},
	},
	-- purple bubbles of poison welling up off it and turning lime, poison dripping
	poison_frog = {
		pieces = {
			skin("bubbles", "bubble_gloss", { { 175, 90, 235 }, LIME }, {
				rate = 2.5,
				life = { 1.2, 1.6 },
				speed = { 0.2, 0.4 },
				accel = { 0, 0.6, 0 },
				size = { { 0, 0 }, { 0.25, 0.2 }, { 0.9, 0.22 }, { 1, 0.28 } },
				transparency = { { 0, 0 }, { 0.9, 0 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			}),
			second(drip("poison", "droplet_gloss", LIME, {
				rate = 1.5,
				size = { { 0, 0 }, { 0.2, 0.2 }, { 1, 0.17 } },
				lightEmission = 0.3,
			})),
		},
	},
	-- lagoon water dripping off its shell, sunlight glinting on the water round it
	lagoon_turtle = {
		pieces = {
			drip("water", "droplet_gloss", AQUA, {
				box = { 1.1, 0.3, 1.1 },
				rate = 2,
				size = { { 0, 0 }, { 0.2, 0.2 }, { 1, 0.17 } },
				lightEmission = 0.3,
			}),
			second(hang("glints", "sparkStar", { 200, 250, 255 }, {
				radius = 2,
				rate = 3,
				life = { 0.8, 1.2 },
				size = { { 0, 0 }, { 0.4, 0.22 }, { 1, 0 } },
				lightEmission = 0.8,
			})),
		},
	},
	-- soft green moss spores hanging round it, little stones crumbling off its sides as it lumbers
	moss_golem = {
		pieces = {
			-- (pale spores: moss-green ones vanish against its own moss)
			hang(
				"spores",
				"dot_round",
				{ { 225, 250, 160 }, { 160, 220, 95 } },
				{ rate = 4.5, size = { { 0, 0 }, { 0.3, 0.16 }, { 0.7, 0.16 }, { 1, 0 } }, lightEmission = 0.35 }
			),
			second(kick("stones", "rocks", nil, {
				role = "keep",
				flipbook = TWO,
				idle = 0.25,
				rate = 4,
				life = { 0.6, 0.9 },
				speed = { 1, 1.6 },
				spread = { 40, 40 },
				accel = { 0, -8, 0 },
				drag = 0,
				size = { { 0, 0.16 }, { 1, 0.16 } },
				transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
				rotSpeed = { -180, 180 },
			})),
		},
	},
	-- murky swamp fumes creeping up from its feet, lime will-o'-wisps glowing round it
	swamp_basilisk = {
		pieces = {
			puff("fumes", "smoke_puff_flip", { 100, 130, 70 }, {
				at = "feet",
				box = { 1.5, 0, 1.5 },
				rate = 2,
				speed = { 0.2, 0.4 },
				size = { { 0, 0.4 }, { 1, 1 } },
				transparency = { { 0, 0.35 }, { 0.3, 0.25 }, { 1, 1 } },
				flipbook = FOUR,
			}),
			second(
				hang(
					"glow",
					"dot_round",
					LIME,
					{ rate = 2.5, size = { { 0, 0 }, { 0.3, 0.13 }, { 0.7, 0.13 }, { 1, 0 } }, lightEmission = 0.8 }
				)
			),
		},
	},
	-- glowing embers rising off its stripes and swirling, grey ash puffing up now and then
	ember_tiger = {
		pieces = {
			-- (its skin is painted with flames: the embers read where they rise clear of it, so they rise far)
			skin("embers", "dot_round", { { 255, 225, 100 }, { 255, 120, 30 }, { 170, 40, 20 } }, {
				rate = 8,
				life = { 1.6, 2 },
				speed = { 0.5, 0.8 },
				accel = { 0, 1.2, 0 },
				size = { { 0, 0 }, { 0.1, 0.17 }, { 1, 0 } },
				lightEmission = 0.2,
			}),
			second(
				puff("ash", "ash_puffs_flip", GRAY, { rate = 0.8, flipbook = FOUR, size = { { 0, 0.25 }, { 1, 0.6 } } })
			),
		},
	},
	-- licks of fire breathed from its mouth, smoke curling off after them
	fire_dragon = {
		pieces = {
			rise("fire", "fire_pop_small_flip", nil, {
				role = "keep",
				at = "front",
				box = { 0.3, 0.1, 0 },
				flipbook = FOUR,
				rate = 3,
				direction = "Front",
				speed = { 1.8, 2.6 },
				spread = { 12, 12 },
				accel = { 0, 1, 0 },
				life = { 0.4, 0.55 },
				size = { { 0, 0.2 }, { 1, 0.6 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				lightEmission = 0.3,
			}),
			second(puff("snort", "smoke_puff_flip", { 120, 110, 110 }, {
				at = "front",
				box = { 0.3, 0.1, 0 },
				rate = 0.8,
				direction = "Front",
				speed = { 1.2, 1.8 },
				size = { { 0, 0.25 }, { 1, 0.75 } },
				transparency = { { 0, 0.5 }, { 0.3, 0.4 }, { 1, 1 } },
				flipbook = FOUR,
			})),
		},
	},
	-- violet witch-fire flickering low round it, lilac magic sparks winking
	witch_cat = {
		pieces = {
			rise("witchfire", "flame_tongue_flip", { { 200, 120, 255 }, VIOLET, { 90, 40, 170 } }, {
				at = "feet",
				box = { 1.45, 0, 1.45 },
				flipbook = FOUR,
				rate = 7,
				life = { 0.6, 0.8 },
				speed = { 0.6, 1 },
				spread = { 10, 10 },
				size = { { 0, 0.45 }, { 1, 0.12 } },
				transparency = { { 0, 0 }, { 1, 0.3 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0,
			}),
			-- (gold stars, as on its skin)
			second(pop("magic", "star_fat", GOLD, {
				radius = 1.9,
				shapeStyle = "Volume",
				rate = 2,
				size = { { 0, 0 }, { 0.35, 0.24 }, { 1, 0 } },
				lightEmission = 0.3,
			})),
		},
	},
	-- now and then a golden koi leaping out of it in the evening light, water drops flung off with it
	sunset_koi = {
		pieces = {
			spray("koi", "koi_top", { { 255, 200, 90 }, { 255, 120, 70 } }, {
				rate = 0.6,
				life = { 1, 1.2 },
				speed = { 3.2, 4 },
				spread = { 25, 25 },
				accel = { 0, -8, 0 },
				size = { { 0, 0.34 }, { 1, 0.34 } },
				transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
				orientation = "VelocityParallel",
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			}),
			second(spray("drops", "droplet_gloss", SKY, {
				rate = 2,
				speed = { 2, 3 },
				spread = { 35, 35 },
				size = { { 0, 0.12 }, { 1, 0.09 } },
				orientation = "VelocityParallel",
				rotation = { 180, 180 },
				rotSpeed = { 0, 0 },
			})),
		},
	},
	-- copper glints sliding over its shell, copper dust lifting off
	copper_beetle = {
		pieces = {
			pop("glints", "star_fat", { 255, 235, 200 }, {
				rate = 3,
				life = { 0.7, 0.9 },
				size = { { 0, 0 }, { 0.35, 0.32 }, { 1, 0 } },
				rotation = { 0, 0 },
				rotSpeed = { -30, 30 },
				lightEmission = 0.5,
			}),
			second(
				skin(
					"dust",
					"dot_round",
					COPPER,
					{ rate = 2.5, size = { { 0, 0 }, { 0.2, 0.1 }, { 1, 0 } }, lightEmission = 0.4 }
				)
			),
		},
	},
	-- jack-o'-lantern flames flickering out of its top, dark smoke curling off
	jack_o_slime = {
		pieces = {
			rise("flames", "eye_flame_flip", ORANGE, {
				at = "head",
				box = { 0.5, 0, 0.5 },
				rate = 4,
				life = { 0.6, 0.9 },
				speed = { 0.8, 1.4 },
				size = { { 0, 0.34 }, { 1, 0.08 } },
				flipbook = FOUR,
				lightEmission = 0.6,
			}),
			second(
				puff(
					"smoke",
					"smoke_puff_flip",
					DARK,
					{ rate = 0.7, flipbook = FOUR, size = { { 0, 0.25 }, { 1, 0.65 } } }
				)
			),
		},
	},
	-- red rose petals swirling up round it, red sparkles in the swirl
	rose_dragon = {
		pieces = {
			-- (light petals: deep red ones vanish against its own red roses)
			orbit("petals", "petals_small_flip", { { 255, 185, 200 }, { 255, 105, 125 } }, {
				rate = 4,
				life = { 1.4, 1.8 },
				orbit = { radius = 1.8, period = 1.8, phase = 0, y = 1.2 },
				speed = { 0.6, 1 },
				direction = "Top",
				accel = { 0, 0.8, 0 },
				size = { { 0, 0.4 }, { 1, 0.26 } },
				flipbook = PETALS,
				rotSpeed = { -90, 90 },
				lightEmission = 0.1,
			}),
			second(
				pop(
					"sparkle",
					"sparkStar",
					{ 255, 150, 150 },
					{ radius = 1.9, shapeStyle = "Volume", rate = 2, lightEmission = 0.6 }
				)
			),
		},
	},
	-- magenta juice spraying out of its top, its leafy crest fluttering
	dragonfruit_slime = {
		pieces = {
			spray("juice", "droplet_gloss", MAGENTA, {
				rate = 3,
				size = { { 0, 0.14 }, { 1, 0.1 } },
				orientation = "VelocityParallel",
				rotation = { 180, 180 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			}),
			second(crown("crest", "feather", GREEN, {
				at = "head",
				rate = 1.2,
				life = { 1.5, 2 },
				size = { { 0, 0 }, { 0.2, 0.36 }, { 0.8, 0.36 }, { 1, 0 } },
				rotation = { -40, 40 },
				rotSpeed = { -20, 20 },
				lightEmission = 0,
			})),
		},
	},
	-- flames rising on its fiery side, snow crystals on its frozen side
	fire_ice_chimera = {
		pieces = {
			rise("fire", "flame_tip", { YELLOW, ORANGE, RED }, {
				box = { 0.15, 0.5, 0.5 },
				pose = { at = { 1.75, 0.3, 0 } },
				rate = 7,
				life = { 0.5, 0.7 },
				size = { { 0, 0.4 }, { 1, 0 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.5,
			}),
			rise("ice", "snow_crystals_flip", ICY, {
				box = { 0.15, 0.5, 0.5 },
				pose = { at = { -1.75, 0.3, 0 } },
				rate = 5,
				speed = { 0.2, 0.4 },
				accel = { 0, -0.6, 0 },
				size = { { 0, 0 }, { 0.2, 0.24 }, { 1, 0 } },
				flipbook = SNOWFLAKES,
				lightEmission = 0.3,
			}),
		},
	},
	-- forge sparks struck off its tusks, a steel glint on its armour
	iron_boar = {
		pieces = {
			spray("sparks", "ember_streak", { YELLOW, ORANGE }, {
				at = "front",
				box = { 0.5, 0.2, 0 },
				rate = 5,
				life = { 0.4, 0.6 },
				speed = { 3, 5 },
				spread = { 50, 50 },
				direction = "Front",
				accel = { 0, -12, 0 },
				orientation = "VelocityParallel",
				size = { { 0, 0.24 }, { 1, 0.08 } },
				lightEmission = 0.7,
			}),
			second(pop("glint", "sparkStar", WHITE, {
				rate = 1.5,
				life = { 0.5, 0.6 },
				size = { { 0, 0 }, { 0.35, 0.34 }, { 1, 0 } },
				lightEmission = 0.6,
			})),
		},
	},
	-- a crimson moon hanging over it, dark red mist rising
	blood_moon_bat = {
		pieces = {
			crown("moon", "crescent_moon", CRIMSON, {
				lift = 0.4,
				box = { 0, 0, 0 },
				rate = 0.5,
				life = { 4, 4 },
				size = { { 0, 0.55 }, { 1, 0.55 } },
				transparency = { { 0, 1 }, { 0.25, 0 }, { 0.75, 0 }, { 1, 1 } },
				rotation = { -20, -20 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.4,
				steady = true,
			}),
			second(skin("mist", "dark_wisp_b", { CRIMSON, DARK }, {
				rate = 1.5,
				size = { { 0, 0.4 }, { 1, 0.85 } },
				transparency = { { 0, 1 }, { 0.3, 0.5 }, { 1, 1 } },
				lightEmission = 0,
			})),
		},
	},
	-- small amethyst gems rising and turning round it, sparkles in its mane
	amethyst_unicorn = {
		pieces = {
			skin("gems", "gem_round", { VIOLET, LILAC }, {
				rate = 2.5,
				life = { 1.6, 2 },
				speed = { 0.3, 0.5 },
				accel = { 0, 0.7, 0 },
				size = { { 0, 0 }, { 0.2, 0.22 }, { 1, 0.12 } },
				rotSpeed = { -120, 120 },
				lightEmission = 0.2,
			}),
			second(pop("mane", "sparkStar", LILAC, {
				at = "head",
				radius = 0.8,
				rate = 3,
				size = { { 0, 0 }, { 0.35, 0.28 }, { 1, 0 } },
				lightEmission = 0.6,
			})),
		},
	},
	-- a spout of stars out of its blowhole, falling back like water
	galaxy_whale = {
		pieces = {
			spray("stars", "star4_drift", { LILAC, SKY }, {
				rate = 7,
				life = { 1, 1.3 },
				speed = { 4, 5.5 },
				spread = { 12, 12 },
				accel = { 0, -9, 0 },
				size = { { 0, 0.36 }, { 1, 0.18 } },
				lightEmission = 0.6,
			}),
			second(spray("spout", "droplet_gloss", SKY, {
				rate = 4,
				speed = { 4, 5.5 },
				spread = { 8, 8 },
				size = { { 0, 0.13 }, { 1, 0.08 } },
				orientation = "VelocityParallel",
				rotation = { 180, 180 },
				rotSpeed = { 0, 0 },
			})),
		},
	},
	-- violet light glinting in its cracks, pebbles crumbling off its stone
	moonstone_gargoyle = {
		pieces = {
			pop("cracks", "sparkStar", { { 240, 225, 255 }, LILAC }, {
				rate = 4,
				life = { 0.6, 0.8 },
				size = { { 0, 0 }, { 0.35, 0.32 }, { 1, 0 } },
				lightEmission = 0.7,
			}),
			second(drip("pebbles", "rocks", nil, {
				role = "keep",
				rate = 1,
				size = { { 0, 0.2 }, { 1, 0.2 } },
				flipbook = TWO,
				rotation = { -180, 180 },
				rotSpeed = { -180, 180 },
				orientation = nil,
			})),
		},
	},
	-- dark void motes pulled into it from all round, purple curls lifting off
	void_kraken = {
		pieces = {
			hang("void", "dot_round", { PURPLE, DARK }, {
				radius = 2.6,
				shapeStyle = "Surface",
				shapeInOut = "Inward",
				rate = 6,
				life = { 1.2, 1.5 },
				speed = { 1.2, 1.6 },
				spread = { 0, 0 },
				drag = 0,
				size = { { 0, 0 }, { 0.3, 0.2 }, { 0.7, 0.2 }, { 1, 0 } },
				lightEmission = 0.3,
			}),
			second(
				skin(
					"curls",
					"curls_flip",
					PURPLE,
					{ flipbook = FOUR, rate = 1.5, size = { { 0, 0.25 }, { 1, 0.55 } } }
				)
			),
		},
	},
	-- a small cyan lure glowing before its head, glowing specks drifting round it
	deep_sea_leviathan = {
		pieces = {
			crown("lure", "blob_solid", CYAN, {
				at = "head",
				box = { 0.05, 0.05, 0.05 },
				pose = { at = { 0, 0.35, -1.1 } },
				rate = 0.5,
				life = { 4, 4 },
				size = { { 0, 0.2 }, { 0.5, 0.25 }, { 1, 0.2 } },
				transparency = { { 0, 1 }, { 0.2, 0 }, { 0.8, 0 }, { 1, 1 } },
				lightEmission = 0.8,
				steady = true,
			}),
			second(
				hang(
					"specks",
					"dot_round",
					CYAN,
					{ rate = 3, size = { { 0, 0 }, { 0.3, 0.11 }, { 0.7, 0.11 }, { 1, 0 } }, lightEmission = 0.8 }
				)
			),
		},
	},
	-- storm rain lashing slantwise round it in the wind, sea spray bursting at its base
	storm_shark = {
		pieces = {
			fall("rain", "rain_streak", nil, {
				role = "keep",
				box = { 2.2, 0, 2.2 },
				rate = 10,
				life = { 0.55, 0.7 },
				size = { { 0, 0.36 }, { 1, 0.36 } },
				transparency = { { 0, 0.1 }, { 1, 0.4 } },
				speed = { 6, 7 },
				spread = { 0, 0 },
				accel = { 2, 0, 0 },
				drag = 0,
				rotation = { -14, -10 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
			}),
			second(kick("spray", "water_curls_flip", { WHITE, SKY }, {
				idle = 0.35,
				rate = 6,
				flipbook = FOUR,
				size = { { 0, 0.3 }, { 1, 0.7 } },
				lightEmission = 0.2,
			})),
		},
	},
	-- black-blue raven feathers whirling round it, starlight glinting between them
	midnight_raven = {
		pieces = {
			orbit("feathers", "feather", { NAVY, DARK }, {
				rate = 3,
				life = { 1.2, 1.5 },
				orbit = { radius = 1.8, period = 3, phase = 0, y = 1.8 },
				size = { { 0, 0.4 }, { 1, 0.24 } },
				speed = { 0.2, 0.4 },
				spread = { 180, 180 },
				rotSpeed = { -60, 60 },
				lightEmission = 0,
			}),
			second(pop("starlight", "sparkStar", SKY, {
				radius = 1.6,
				shapeStyle = "Volume",
				rate = 2,
				size = { { 0, 0 }, { 0.35, 0.28 }, { 1, 0 } },
				lightEmission = 0.7,
			})),
		},
	},
	-- a slow ring of pebbles circling its shell like an old guardian's, dust puffing from its feet as it plods
	stone_tortoise = {
		pieces = {
			orbit("pebbles", "rocks", nil, {
				role = "keep",
				rate = 3,
				life = { 1.6, 2 },
				orbit = { radius = 1.8, period = 6, phase = 0, y = 1.2 },
				size = { { 0, 0.2 }, { 0.8, 0.2 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotSpeed = { -40, 40 },
				flipbook = TWO,
				lightEmission = 0,
			}),
			second(kick("dust", "smoke_puff_flip", TAN, { flipbook = FOUR, idle = 0.2, rate = 5 })),
		},
	},
	-- shadow smoke streaming off its back as it runs, dark wisps lifting off it
	shadow_wolf = {
		pieces = {
			kick("shadow", "smoke_puff_flip", { 35, 30, 45 }, {
				at = "back",
				box = { 0.6, 0.6, 0 },
				idle = 0.3,
				rate = 5,
				life = { 0.6, 0.9 },
				speed = { 0.2, 0.5 },
				flipbook = FOUR,
				transparency = { { 0, 0.4 }, { 1, 1 } },
			}),
			second(skin("wisps", "dark_wisp_b", DARK, {
				rate = 2,
				size = { { 0, 0.4 }, { 1, 0.9 } },
				transparency = { { 0, 1 }, { 0.3, 0.5 }, { 1, 1 } },
				lightEmission = 0,
			})),
		},
	},
	-- stars twinkling in the night round it, a tiny planet going round it
	universe_slime = {
		pieces = {
			pop("stars", "star_twinkle", { 255, 245, 210 }, {
				radius = 1.9,
				shapeStyle = "Volume",
				rate = 4,
				size = { { 0, 0 }, { 0.35, 0.28 }, { 1, 0 } },
				lightEmission = 0.7,
			}),
			second(orbit(
				"planet",
				"ball_shaded",
				AQUA,
				companion({
					orbit = { radius = 1.9, period = 4, phase = 0, y = 2.2 },
					size = { { 0, 0.3 }, { 1, 0.3 } },
				})
			)),
		},
	},
	-- little down feathers drifting off it, clouds puffing under its feet as it trots
	cloud_pegasus = {
		pieces = {
			fall("feathers", "down_feather", WHITE, {
				at = "chest",
				box = { 1.4, 0.4, 1.4 },
				rate = 1.6,
				life = { 2.2, 2.8 },
				accel = { 0.3, -0.7, 0 },
				size = { { 0, 0 }, { 0.12, 0.24 }, { 0.85, 0.22 }, { 1, 0 } },
				rotSpeed = { -40, 40 },
				lightEmission = 0.2,
			}),
			second(kick("clouds", "puff_solid", WHITE, { idle = 0.4, rate = 5, size = { { 0, 0.25 }, { 1, 0.6 } } })),
		},
	},
	-- ice crystals circling it, a trail of frost behind them; white swan feathers drifting down
	frost_swan = {
		pieces = {
			orbit("ice", "shard_crystal", nil, {
				role = "keep",
				rate = 8,
				life = { 0.5, 0.6 },
				orbit = { radius = 1.8, period = 2.8, phase = 0, y = 1.7 },
				size = { { 0, 0.45 }, { 1, 0 } },
				lightEmission = 0.4,
			}),
			second(fall("feathers", "feather", { WHITE, ICY }, {
				rate = 1.2,
				size = { { 0, 0 }, { 0.12, 0.3 }, { 0.85, 0.28 }, { 1, 0 } },
				lightEmission = 0.2,
			})),
		},
	},
	-- a ring of gold-to-cyan lightning racing round it, sparks shooting off
	thunderbird = {
		pieces = {
			orbit("lightning", "bolts_comic", { GOLD, CYAN }, {
				flipbook = TWO,
				rate = 9,
				life = { 0.3, 0.4 },
				orbit = { radius = 1.8, period = 1.2, phase = 0, y = 1.8 },
				size = { { 0, 0.55 }, { 1, 0.28 } },
				transparency = { { 0, 0 }, { 1, 0.5 } },
				lightEmission = 0.8,
			}),
			second(spray("sparks", "ember_streak", GOLD, {
				at = "body",
				rate = 2,
				life = { 0.3, 0.4 },
				speed = { 3, 5 },
				spread = { 180, 180 },
				accel = { 0, -4, 0 },
				orientation = "VelocityParallel",
				size = { { 0, 0.28 }, { 1, 0.08 } },
				lightEmission = 0.8,
			})),
		},
	},
	-- two small clouds floating round its island shell, its waterfall trickling off
	sky_island_turtle = {
		pieces = {
			orbit("clouds", "cloud_cartoon", WHITE, {
				rate = 0.5,
				life = { 4.05, 4.05 },
				orbit = { radius = 1.9, period = 8, phase = 0, y = 2.3 },
				size = { { 0, 0.44 }, { 1, 0.44 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotation = { -5, 5 },
				locked = true,
				steady = true,
				lightEmission = 0.35,
			}),
			second(drip("waterfall", "droplet_gloss", AQUA, {
				at = "chest",
				box = { 0.3, 0, 0.3 },
				pose = { at = { 1.45, 0, 0 } },
				rate = 3,
				size = { { 0, 0.1 }, { 1, 0.14 } },
				lightEmission = 0.3,
			})),
		},
	},
	-- rainbow drops falling in the sunshine, warm sun twinkles
	sunshower_fox = {
		pieces = {
			fall("rainbow", "droplet_gloss", "rainbow", {
				rate = 5,
				life = { 1.2, 1.6 },
				accel = { 0, -4, 0 },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				size = { { 0, 0 }, { 0.15, 0.18 }, { 1, 0.15 } },
				lightEmission = 0.4,
			}),
			second(pop("sun", "sparkStar", GOLD, {
				radius = 1.7,
				shapeStyle = "Volume",
				rate = 2,
				size = { { 0, 0 }, { 0.35, 0.24 }, { 1, 0 } },
				lightEmission = 0.6,
			})),
		},
	},
	-- steam billowing out of its top, its red-hot core glowing through its skin
	steam_dragon = {
		pieces = {
			puff("steam", "steam_puff", WHITE, { rate = 1.5, size = { { 0, 0.3 }, { 1, 1.2 } } }),
			second(
				pop(
					"core",
					"dot_round",
					{ 255, 90, 40 },
					{ rate = 2.5, size = { { 0, 0 }, { 0.4, 0.22 }, { 1, 0 } }, lightEmission = 0.8 }
				)
			),
		},
	},
	-- pink-to-blue candy floss fluffs floating up, sugar sparkles
	cotton_candy_sheep = {
		pieces = {
			skin("floss", "puff_solid", { { 255, 150, 205 }, { 140, 185, 255 } }, {
				rate = 2.5,
				life = { 2, 2.6 },
				speed = { 0.2, 0.4 },
				accel = { 0, 0.5, 0 },
				size = { { 0, 0 }, { 0.2, 0.5 }, { 1, 0.3 } },
				lightEmission = 0,
			}),
			second(pop("sugar", "sparkStar", WHITE, {
				radius = 1.9,
				shapeStyle = "Volume",
				rate = 2.5,
				size = { { 0, 0 }, { 0.35, 0.26 }, { 1, 0 } },
			})),
		},
	},
	-- aurora ribbons, green into cyan into violet, rising off it; its tentacles dripping light
	aurora_jellyfish = {
		pieces = {
			skin("aurora", "swirl_wisp", { { 90, 240, 170 }, CYAN, VIOLET }, {
				rate = 2.5,
				life = { 1.8, 2.4 },
				speed = { 0.5, 0.9 },
				size = { { 0, 0.5 }, { 1, 1.1 } },
				transparency = { { 0, 1 }, { 0.25, 0.05 }, { 1, 1 } },
				lightEmission = 0.6,
			}),
			second(drip("tentacles", "drop_fine", VIOLET, {
				at = "feet",
				box = { 1.35, 0, 1.35 },
				rate = 2,
				accel = { 0, -2, 0 },
				lightEmission = 0.5,
			})),
		},
	},
	-- sky-blue stars in a wide flat band (its fins), like a constellation
	celestial_manta = {
		pieces = {
			rise("fins", "star_twinkle", { WHITE, SKY }, {
				at = "waist",
				box = { 2.4, 0.08, 1.1 },
				rate = 6,
				life = { 0.7, 1 },
				size = { { 0, 0 }, { 0.35, 0.36 }, { 1, 0 } },
				speed = { 0, 0 },
				accel = { 0, 0, 0 },
				lightEmission = 0.7,
				locked = true,
			}),
			second(hang("stardust", "star4_drift", { SKY, NAVY }, { rate = 2.5 })),
		},
	},
	-- blue raindrops falling on it, grey wool puffs round its storm-cloud horns
	raincloud_ram = {
		pieces = {
			fall("rain", "droplet_gloss", BLUE, {
				rate = 6,
				life = { 0.9, 1.2 },
				accel = { 0, -6, 0 },
				drag = 0,
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				size = { { 0, 0 }, { 0.1, 0.17 }, { 1, 0.15 } },
			}),
			second(hang("wool", "puff_solid", GRAY, { at = "head", radius = 1.1, rate = 1.5, lightEmission = 0 })),
		},
	},
	-- dark storm smoke swirling round it, cyan lightning bolts snapping
	tempest_dragon = {
		pieces = {
			orbit("storm", "smoke_puff_flip", { 50, 55, 80 }, {
				rate = 2.5,
				life = { 1.2, 1.5 },
				orbit = { radius = 1.6, period = 2.2, phase = 0, y = 1.5 },
				size = { { 0, 0.45 }, { 1, 0.85 } },
				transparency = { { 0, 0.3 }, { 1, 1 } },
				flipbook = FOUR,
				lightEmission = 0,
			}),
			second(pop("bolts", "bolts_comic", CYAN, {
				radius = 1.6,
				flipbook = TWO,
				rate = 2.5,
				life = { 0.25, 0.35 },
				size = { { 0, 0.5 }, { 1, 0.6 } },
				lightEmission = 0.8,
			})),
		},
	},
}

for _, variant in variants do
	for _, piece in variant.pieces do
		local grown = {}
		for index, key in piece.size do
			grown[index] = { key[1], key[2] * GROW, if key[3] then key[3] * GROW else nil }
		end
		piece.size = grown
	end
end

return {
	id = "aura.secret_signature",
	name = "Secret Signatures",
	kind = "aura",
	tier = "cheap",
	host = "slime",
	refHeight = 3,
	tags = { "slime", "secret", "signature", "per_creature", "no_ground_disc", "no_rings", "no_rarity_glow" },
	blend = "normal",
	palette = {},
	tintable = false,
	pieces = variants.snow_rabbit.pieces,
	variants = variants,
	defaultVariant = "snow_rabbit",
	source = {
		from = "Goo Lineage V2 (2026-11-10): one small signature for each of its 66 Secret slimes",
		art = "the library's pictures (ASSETS.md families) and pictures drawn for it, owner art kept as drawn",
		licence = "the owner's own, ChatGPT pictures made for the owner, and free Creator Store pictures already in the library",
	},
	notes = "Attach to a Secret slime's body with opts.variant = its name in snake case. The owner: simple, but fitting each slime, so every one has an identity of its own; small and quiet, but fitting and beautiful.",
}
