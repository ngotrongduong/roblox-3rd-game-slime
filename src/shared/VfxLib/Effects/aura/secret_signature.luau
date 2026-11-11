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
local CORAL = { 255, 160, 150 }
local MAGENTA = { 230, 50, 160 }
local COPPER = { 215, 120, 55 }
local BROWN = { 140, 85, 45 }
local TAN = { 205, 175, 125 }
-- Every size below times this. The first round drew everything 1.8 times bigger so nothing was lost at the village's
-- camera distance; the owner then asked for small and quiet, so the pieces are now near their real size and reach the
-- eye by their picture and motion, not by bulk. Third round (2026-11-11), the owner looking at all 66 side by side:
-- "fair, but a little bigger and a little more, so they are easier to see": every size and every rate (but a
-- companion's, one picture always there) go up again.
local GROW = 1.7
local MORE = 1.5

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

-- A companion with beating wings (butterfly_flip, moth_flip) wandering round its path, facing the camera.
local function flutter(path, size)
	return companion({
		flipbook = FLAP,
		orbit = path,
		size = { { 0, size }, { 1, size } },
		lightEmission = 0.3,
	})
end

-- One of the owner's 3D fish (Models.fish) swimming round it head first on a wandering path, its tail sweeping.
local function fish(name, model, length, path)
	return { name = name, model = model, length = length, orbit = path }
end

-- A place in a school going round together: its reach, how far behind the lead, its height; one beat of wandering.
local function school(radius, phase, y)
	return { radius = radius, period = 8.5, phase = phase, y = y, bob = { 0.3, 3.2 }, sway = { 0.25, 4.4 } }
end

-- A grey cloud hanging over its head and riding it, built of soft smoke puffs.
local function stormCloud(color)
	return crown("cloud", "smoke_cloud_soft", color, {
		lift = 1.3,
		box = { 0.7, 0.08, 0.5 },
		rate = 4,
		life = { 2.4, 3 },
		size = { { 0, 0.55 }, { 0.5, 0.8 }, { 1, 0.85 } },
		transparency = { { 0, 1 }, { 0.3, 0.05 }, { 0.7, 0.1 }, { 1, 1 } },
		rotation = { -180, 180 },
		rotSpeed = { -8, 8 },
		lightEmission = 0,
	})
end

-- Now and then a bolt of lightning striking from that cloud down onto its head.
local function strike(color)
	return crown("strike", "bolts_comic", color, {
		lift = 0.55,
		box = { 0.25, 0, 0.2 },
		flipbook = TWO,
		rate = 0.35,
		life = { 0.18, 0.24 },
		size = { { 0, 1.1 }, { 1, 1.2 } },
		transparency = { { 0, 0 }, { 0.6, 0 }, { 1, 1 } },
		rotation = { 0, 0 },
		rotSpeed = { 0, 0 },
		orientation = "FacingCameraWorldUp",
		lightEmission = 1,
	})
end

-- A planet going round it (radius, seconds a turn, where it starts, height, size).
local function planet(radius, period, phase, y, size)
	return companion({
		orbit = { radius = radius, period = period, phase = phase, y = y },
		size = { { 0, size }, { 1, size } },
		lightEmission = 0.15,
	})
end

-- A drift of cloud going slowly round it, its puffs swelling and thinning behind it.
local function mist(phase)
	return {
		orbit = { radius = 2.1, period = 9, phase = phase, y = 2, bob = { 0.25, 4.3 } },
		rate = 3,
		life = { 2.4, 3 },
		size = { { 0, 0.45 }, { 0.5, 0.75 }, { 1, 0.85 } },
		transparency = { { 0, 1 }, { 0.25, 0.2 }, { 0.7, 0.35 }, { 1, 1 } },
		speed = { 0.05, 0.15 },
		spread = { 180, 180 },
		rotation = { -180, 180 },
		rotSpeed = { -8, 8 },
		lightEmission = 0.3,
		locked = false,
	}
end

-- A Christmas-tree light on the skin, blinking on and off twice before it goes out.
local function fairyLight(name, color)
	return pop(name, "glow_dot", color, {
		radius = 1.65,
		shapePartial = 0.7,
		rate = 2.5,
		life = { 2, 2.4 },
		size = { { 0, 0.2 }, { 1, 0.2 } },
		transparency = {
			{ 0, 1 },
			{ 0.05, 0 },
			{ 0.3, 0 },
			{ 0.35, 1 },
			{ 0.5, 1 },
			{ 0.55, 0 },
			{ 0.8, 0 },
			{ 0.85, 1 },
			{ 1, 1 },
		},
		rotSpeed = { 0, 0 },
		lightEmission = 1,
	})
end

-- Pieces of the library's own Level 1 pet auras (effects/aura/blazing_flames, electric_bolts, shadow_wisps), worn at a
-- slime's size: their studs and speeds are for a 5-stud pet, so three fifths of them (2026-11-11, the owner: "we have
-- an effect library: take from it the effects that can be used").
local LIB = 0.6
local function libSize(keys)
	local out = {}
	for index, key in keys do
		out[index] = { key[1], key[2] * LIB / GROW }
	end
	return out
end

-- blazing_flames' Licks: upright tongues of fire licking up round the body.
local function licks(color, over)
	return with({
		name = "licks",
		texture = "flame_tongue_flip",
		color = color,
		at = "waist",
		box = { 0.9, 0.3, 0.9 },
		shape = "Box",
		orientation = "FacingCameraWorldUp",
		direction = "Top",
		speed = { 1 * LIB, 2.2 * LIB },
		spread = { 10, 10 },
		accel = { 0, 3 * LIB, 0 },
		rate = 7,
		life = { 0.55, 0.8 },
		size = libSize({ { 0, 1.6 }, { 0.4, 2.4 }, { 1, 2 } }),
		transparency = { { 0, 1 }, { 0.15, 0.1 }, { 0.7, 0.3 }, { 1, 1 } },
		rotation = { -10, 10 },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 1,
		brightness = 2.5,
		locked = false,
	}, over)
end

-- blazing_flames' Embers: glowing embers drifting up off the body.
local function embers(color, over)
	return with({
		name = "embers",
		texture = "embers_fly",
		color = color,
		at = "body",
		box = { 1, 0.6, 1 },
		shape = "Box",
		direction = "Top",
		speed = { 1 * LIB, 2.5 * LIB },
		spread = { 25, 25 },
		accel = { 0, 2.5 * LIB, 0 },
		rate = 4,
		life = { 0.8, 1.3 },
		size = libSize({ { 0, 0 }, { 0.2, 0.4 }, { 1, 0 } }),
		transparency = { { 0, 0 }, { 1, 0.3 } },
		rotation = { -180, 180 },
		lightEmission = 1,
		brightness = 3,
		locked = false,
	}, over)
end

-- blazing_flames' Sparks: hot sparks shot up, stretched along their flight.
local function sparks(color, over)
	return with({
		name = "sparks",
		texture = "ember_streak",
		color = color,
		at = "waist",
		box = { 0.8, 0.2, 0.8 },
		shape = "Box",
		direction = "Top",
		speed = { 4 * LIB, 8 * LIB },
		spread = { 30, 30 },
		drag = 2.5,
		rate = 3,
		life = { 0.3, 0.6 },
		size = libSize({ { 0, 0 }, { 0.15, 0.5 }, { 1, 0 } }),
		transparency = { { 0, 0 }, { 1, 0 } },
		squash = { { 0, -0.6 }, { 1, 0 } },
		orientation = "VelocityParallel",
		lightEmission = 1,
		brightness = 4,
		locked = false,
	}, over)
end

-- electric_bolts' Bolts: short zigzag bolts snapping round the body.
local function bolts(color, over)
	return with({
		name = "bolts",
		texture = "bolt_flip_a",
		color = color,
		at = "body",
		box = { 0.9, 0.8, 0.9 },
		shape = "Box",
		rate = 5,
		life = { 0.15, 0.22 },
		size = libSize({ { 0, 2.6 }, { 1, 3 } }),
		transparency = { { 0, 0 }, { 0.6, 0 }, { 1, 1 } },
		speed = { 0, 0 },
		rotation = { -180, 180 },
		flipbook = { layout = "Grid2x2", mode = "OneShot" },
		lightEmission = 1,
		brightness = 4,
		zOffset = 0.5,
		locked = true,
	}, over)
end

-- electric_bolts' Sparks: white-hot sparks flying off the skin, stretched along their flight.
local function zaps(color, over)
	return with({
		name = "zaps",
		texture = "spark_dot",
		color = color,
		at = "body",
		radius = 1.5,
		shape = "Sphere",
		shapeStyle = "Surface",
		shapeInOut = "Outward",
		shapePartial = 0.6,
		direction = "Top",
		speed = { 6 * LIB, 12 * LIB },
		drag = 4,
		rate = 6,
		life = { 0.25, 0.45 },
		size = libSize({ { 0, 0.35 }, { 1, 0.08 } }),
		transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
		squash = { { 0, -0.6 }, { 1, -0.6 } },
		orientation = "VelocityParallel",
		lightEmission = 1,
		brightness = 3,
		locked = false,
	}, over)
end

-- electric_bolts' Charge: a faint glow of charge behind the body.
local function charge(color)
	return {
		name = "charge",
		texture = "glow_soft",
		color = color,
		at = "body",
		rate = 1,
		life = { 1, 1.4 },
		size = libSize({ { 0, 4 }, { 1, 4.6 } }),
		transparency = { { 0, 1 }, { 0.4, 0.75 }, { 1, 1 } },
		speed = { 0, 0 },
		rotation = { -180, 180 },
		lightEmission = 1,
		brightness = 3,
		zOffset = -1,
		locked = true,
		secondary = true,
	}
end

local FIRE = { { 255, 240, 170 }, { 255, 150, 40 }, { 225, 55, 20 } }
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
	-- candies of every colour but its own red and white raining down on it, tumbling; mint sparkles winking on its
	-- stripes (2026-11-11, the owner: "let candies fall like rain, not red and white")
	peppermint_slime = {
		pieces = {
			fall("candies", "candy_rain_flip", nil, {
				role = "keep",
				-- (each candy keeps the frame it starts on)
				flipbook = LEAVES,
				box = { 1.3, 0, 1.3 },
				rate = 4,
				life = { 1.3, 1.6 },
				speed = { 0.5, 1 },
				spread = { 10, 10 },
				accel = { 0, -3, 0 },
				drag = 0.3,
				size = { { 0, 0 }, { 0.08, 0.26 }, { 0.9, 0.26 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotSpeed = { -120, 120 },
				lightEmission = 0,
			}),
			second(pop("mint", "sparkStar", MINT, { rate = 2.5, lightEmission = 0.5 })),
		},
	},
	-- lilac orchid petals falling slowly, violet moon twinkles round it
	moon_orchid = {
		pieces = {
			-- (twice the petals since 2026-11-11: the owner found them too few)
			fall("petals", "petals_small_flip", LILAC, {
				flipbook = PETALS,
				rate = 6,
				box = { 1.4, 0, 1.4 },
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
	-- bright snowflakes hanging in the cold air round it, frosty steam breathing up off it (2026-11-11: the owner found
	-- the curling wind a poor white smoke and the flakes faint and few)
	arctic_wolf = {
		pieces = {
			hang("frost", "snow_crystals_flip", SNOW, {
				flipbook = SNOWFLAKES,
				radius = 2.3,
				rate = 6,
				size = { { 0, 0 }, { 0.3, 0.26 }, { 0.7, 0.26 }, { 1, 0 } },
				speed = { 0.1, 0.3 },
				lightEmission = 0.7,
			}),
			-- (the library's frozen_snowfall: the owner's own small flakes falling round it, drawn on black so added)
			fall("snowfall", "fx_snowflakes", SNOW, {
				box = { 1.25, 0, 1.25 },
				flipbook = { layout = "Grid2x2", mode = "Random" },
				rate = 8,
				life = { 1.8, 2.2 },
				speed = { 1.9 * LIB, 2.6 * LIB },
				spread = { 12, 12 },
				accel = { 0, 0, 0 },
				size = libSize({ { 0, 0.25 }, { 0.15, 0.36 }, { 1, 0.3 } }),
				transparency = { { 0, 1 }, { 0.12, 0.05 }, { 0.8, 0.15 }, { 1, 1 } },
				lightEmission = 1,
			}),
			second(rise("steam", "steam_puff", { { 240, 248, 255 }, { 205, 230, 255 } }, {
				at = "feet",
				-- (born on a ring round its feet: under it the body hides them)
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 2.2,
				life = { 2.2, 2.8 },
				speed = { 0.3, 0.6 },
				spread = { 20, 20 },
				accel = { 0, 0.25, 0 },
				drag = 0.6,
				size = { { 0, 0.35 }, { 1, 1 } },
				transparency = { { 0, 1 }, { 0.25, 0.45 }, { 0.6, 0.6 }, { 1, 1 } },
				rotSpeed = { -20, 20 },
				lightEmission = 0.15,
			})),
		},
	},
	-- standing on its own soft bank of cloud, puffs of it billowing round its body (2026-11-11: the owner found the
	-- cartoon cloud over its head poor and asked for cotton, cloud or steam floating under and round it)
	cloud_sheep = {
		pieces = {
			rise("bank", "smoke_cloud_soft", WHITE, {
				at = "feet",
				radius = 1.7,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 3,
				life = { 3, 4 },
				speed = { 0.05, 0.2 },
				spread = { 60, 60 },
				accel = { 0, 0, 0 },
				drag = 0.5,
				size = { { 0, 0.5 }, { 0.5, 1 }, { 1, 1.1 } },
				transparency = { { 0, 1 }, { 0.3, 0.15 }, { 0.7, 0.3 }, { 1, 1 } },
				rotSpeed = { -10, 10 },
				lightEmission = 0.25,
			}),
			second(hang("puffs", "smoke_cloud_soft_b", WHITE, {
				radius = 2.2,
				rate = 1.5,
				life = { 2.6, 3.4 },
				speed = { 0.05, 0.2 },
				size = { { 0, 0.3 }, { 0.5, 0.6 }, { 1, 0.7 } },
				transparency = { { 0, 1 }, { 0.3, 0.3 }, { 0.7, 0.4 }, { 1, 1 } },
				rotSpeed = { -10, 10 },
				lightEmission = 0.25,
			})),
		},
	},
	-- a white koi and a black koi swimming round it head first, always on opposite sides so they never touch, their
	-- paths rising, falling, nearing and drawing off on beats of their own (2026-11-11, the owner)
	-- (the owner's own 3D fish since 2026-11-11, rigged so their fan tails sweep as they swim: the pale ice one and the
	-- dark silver one)
	yin_yang_koi = {
		swimmers = {
			fish("light", "frost_white", 1.3, {
				radius = 2.5,
				period = 7,
				phase = 0,
				y = 1.8,
				bob = { 0.35, 3.1 },
				sway = { 0.3, 4.3 },
			}),
			fish("dark", "silver_ink", 1.3, {
				radius = 2.5,
				period = 7,
				phase = 0.5,
				y = 1.8,
				bob = { 0.35, 3.7 },
				sway = { 0.3, 5.1 },
			}),
		},
		pieces = {
			-- (a few bubbles rising off it, as if under water)
			rise("bubbles", "bubble_gloss", { { 245, 250, 255 }, { 200, 215, 235 } }, {
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				at = "feet",
				rate = 1.2,
				life = { 2, 2.6 },
				size = { { 0, 0 }, { 0.2, 0.16 }, { 1, 0.12 } },
				lightEmission = 0.3,
			}),
		},
	},
	-- pink pollen floating round it, rose twinkles rising
	rose_fairy = {
		pieces = {
			-- (rose petals falling, the pollen and twinkles bigger and more: 2026-11-11, the owner saw almost nothing)
			fall("petals", "petals_small_flip", { PINK, { 235, 80, 130 } }, {
				flipbook = PETALS,
				box = { 1.4, 0, 1.4 },
				rate = 5,
				accel = { 0.5, -1.1, 0 },
				size = { { 0, 0 }, { 0.12, 0.36 }, { 0.85, 0.32 }, { 1, 0 } },
				rotSpeed = { -30, 30 },
			}),
			hang(
				"pollen",
				"dot_round",
				PINK,
				{ rate = 5, size = { { 0, 0 }, { 0.3, 0.18 }, { 0.7, 0.18 }, { 1, 0 } }, lightEmission = 0.5 }
			),
			second(
				skin(
					"twinkle",
					"sparkStar",
					{ 255, 190, 220 },
					{ rate = 3.5, size = { { 0, 0 }, { 0.3, 0.32 }, { 1, 0 } }, lightEmission = 0.6 }
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
	-- watermelon-pink and rind-green bubbles rising round it from its feet to over its head (2026-11-11, the owner)
	watermelon_frog = {
		pieces = {
			rise("pink", "bubble_gloss", { 255, 110, 140 }, {
				at = "feet",
				-- (born on a ring round its feet: under it the body hides them)
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 2.5,
				life = { 2.2, 2.8 },
				speed = { 0.8, 1.2 },
				spread = { 10, 10 },
				accel = { 0, 0.3, 0 },
				size = { { 0, 0 }, { 0.15, 0.24 }, { 0.9, 0.26 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.05 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			}),
			second(rise("green", "bubble_gloss", { 110, 215, 90 }, {
				at = "feet",
				-- (born on a ring round its feet: under it the body hides them)
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 2.5,
				life = { 2.2, 2.8 },
				speed = { 0.8, 1.2 },
				spread = { 10, 10 },
				accel = { 0, 0.3, 0 },
				size = { { 0, 0 }, { 0.15, 0.2 }, { 0.9, 0.22 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.05 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			})),
		},
	},
	-- coral-pink bubbles rising from its gills, little peach ones between them
	coral_axolotl = {
		pieces = {
			-- (more bubbles since 2026-11-11, the owner)
			rise("bubbles", "bubble_gloss", CORAL, {
				at = "head",
				box = { 1.4, 0.2, 1.2 },
				rate = 4,
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
				box = { 1.4, 0.2, 1.2 },
				rate = 4,
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
			-- (more hearts since 2026-11-11, the owner)
			rise("hearts", "heart_puffy", { PINK, { 235, 70, 100 } }, {
				at = "chest",
				box = { 1.6, 0.3, 1.6 },
				rate = 4.5,
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
	-- three pink-to-violet butterflies always fluttering round it on paths of their own, dream dust drifting free
	-- (2026-11-11, the owner: "2 or 3 butterflies always flying round")
	dream_butterfly = {
		pieces = {
			orbit(
				"butterfly1",
				"butterfly_flip",
				PINK,
				flutter({ radius = 2, period = 5, phase = 0, y = 2, bob = { 0.4, 1.7 }, sway = { 0.35, 3.3 } }, 0.36)
			),
			orbit(
				"butterfly2",
				"butterfly_flip",
				VIOLET,
				flutter(
					{ radius = 2.3, period = 6.5, phase = 0.4, y = 1.3, bob = { 0.35, 2.1 }, sway = { 0.4, 2.9 } },
					0.32
				)
			),
			second(
				orbit(
					"butterfly3",
					"butterfly_flip",
					{ 235, 150, 255 },
					flutter(
						{ radius = 1.8, period = -7, phase = 0.7, y = 2.7, bob = { 0.3, 1.9 }, sway = { 0.3, 4.1 } },
						0.28
					)
				)
			),
			second(hang("dust", "star4_drift", LILAC, { rate = 4, speed = { 0.3, 0.7 } })),
		},
	},
	-- pale moths circling it as round a lamp, a pink crescent glowing on its head (three since 2026-11-11, the owner)
	twilight_moth = {
		pieces = {
			orbit(
				"moth",
				"moth_flip",
				{ 255, 215, 235 },
				flutter(
					{ radius = 1.8, period = 4, phase = 0, y = 2.3, bob = { 0.35, 1.6 }, sway = { 0.3, 2.7 } },
					0.36
				)
			),
			orbit(
				"moth2",
				"moth_flip",
				{ 240, 200, 255 },
				flutter(
					{ radius = 2.2, period = 5.5, phase = 0.35, y = 1.6, bob = { 0.3, 2.2 }, sway = { 0.35, 3.4 } },
					0.32
				)
			),
			second(
				orbit(
					"moth3",
					"moth_flip",
					{ 255, 230, 210 },
					flutter(
						{ radius = 1.6, period = -6, phase = 0.7, y = 2.9, bob = { 0.25, 1.9 }, sway = { 0.3, 3.9 } },
						0.28
					)
				)
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
			-- (bats_flip is 2 x 2: wings open and folded, drawn head to the left, so turned a quarter to stand upright:
			-- -90; the first turn, +90, stood them on their heads, 2026-11-11)
			rise("bats", "bats_flip", { 70, 30, 70 }, {
				flipbook = flip("Grid2x2", "Loop", { 8, 12 }),
				rate = 1.5,
				life = { 1.2, 1.6 },
				speed = { 1.5, 2.5 },
				spread = { 70, 70 },
				size = { { 0, 0.2 }, { 0.3, 0.4 }, { 1, 0.34 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotation = { -100, -80 },
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
			-- (real licking fire on its crest and real embers flying off it since 2026-11-11: the owner found the plain
			-- flame tips not true to life)
			rise("crest", "flame_beautiful_flip", nil, {
				role = "keep",
				flipbook = { layout = "Grid8x8", mode = "OneShot" },
				at = "head",
				box = { 0.5, 0, 0.3 },
				rate = 7,
				life = { 0.6, 0.8 },
				speed = { 0.6, 1 },
				spread = { 10, 10 },
				accel = { 0, 1.5, 0 },
				size = { { 0, 0.5 }, { 1, 0.7 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.4,
			}),
			-- (the library's blazing_flames embers and hot sparks since its second look: the owner still found the
			-- sparks flying off it untrue)
			licks({ { 255, 245, 190 }, { 255, 185, 50 }, { 240, 90, 20 } }, { rate = 5 }),
			embers({ { 255, 230, 140 }, { 255, 140, 30 } }, { at = "head", box = { 0.8, 0.3, 0.6 }, rate = 5 }),
			sparks({ { 255, 250, 210 }, { 255, 190, 60 } }, { at = "head", box = { 0.6, 0, 0.4 }, rate = 3 }),
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
			-- (more fire since 2026-11-11, the owner: twice the curls, bigger, and licking flames on its crown)
			skin("flames", "fire_curl_flip", nil, {
				role = "keep",
				flipbook = FOUR,
				rate = 10,
				life = { 0.7, 0.9 },
				speed = { 0.3, 0.5 },
				accel = { 0, 2, 0 },
				size = { { 0, 0.44 }, { 1, 0.54 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.2,
			}),
			rise("blaze", "flame_beautiful_flip", nil, {
				role = "keep",
				flipbook = { layout = "Grid8x8", mode = "OneShot" },
				at = "head",
				box = { 0.9, 0, 0.7 },
				rate = 6,
				life = { 0.6, 0.8 },
				speed = { 0.6, 1 },
				spread = { 10, 10 },
				accel = { 0, 1.5, 0 },
				size = { { 0, 0.45 }, { 1, 0.6 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.4,
			}),
			-- (the library's blazing_flames: tongues of fire licking up all round it, and its hot sparks)
			licks(FIRE, { rate = 6 }),
			second(sparks({ { 255, 250, 210 }, { 255, 170, 40 } }, { rate = 2.5 })),
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
			-- (more stars of more sizes and shapes since 2026-11-11, the owner: fat stars, long twinkles, sharp glints)
			pop("stars", "star_fat", YELLOW, {
				radius = 2.2,
				shapeStyle = "Volume",
				rate = 4,
				size = { { 0, 0 }, { 0.35, 0.3 }, { 1, 0 } },
				lightEmission = 0.5,
			}),
			hang("twinkles", "star_twinkle_long", { 255, 245, 190 }, {
				radius = 2.4,
				rate = 3,
				life = { 1, 1.6 },
				speed = { 0.05, 0.2 },
				size = { { 0, 0 }, { 0.4, 0.5 }, { 1, 0 } },
				rotation = { 0, 0 },
				rotSpeed = { -20, 20 },
				lightEmission = 0.8,
			}),
			second(pop("glints", "star_glint_sharp", { 200, 225, 255 }, {
				radius = 2,
				shapeStyle = "Volume",
				rate = 3,
				size = { { 0, 0 }, { 0.35, 0.18 }, { 1, 0 } },
				lightEmission = 0.8,
			})),
			second(fall("feather", "feather", NAVY, {
				rate = 0.8,
				size = { { 0, 0 }, { 0.12, 0.3 }, { 0.85, 0.28 }, { 1, 0 } },
				lightEmission = 0,
			})),
		},
	},
	-- yellow electric sparks flashing all over its body, static sparkles crackling in its wool
	thunder_ram = {
		pieces = {
			-- (the library's electric_bolts in its own yellow since 2026-11-11: the owner found the comic bolts at its
			-- horns poor and asked for electric sparks flashing all round its body)
			-- (born just outside its skin, where the body cannot hide them; dimmer, so its yellow reads)
			bolts({ { 255, 250, 200 }, { 255, 225, 70 }, { 255, 180, 20 } }, {
				radius = 1.75,
				shape = "Sphere",
				shapeStyle = "Surface",
				shapePartial = 0.75,
				direction = "Top",
				rate = 6,
				brightness = 1.6,
			}),
			zaps({ { 255, 255, 235 }, { 255, 230, 120 } }),
			second(pop("static", "sparkStar", { 255, 240, 150 }, {
				rate = 3,
				size = { { 0, 0 }, { 0.35, 0.24 }, { 1, 0 } },
				lightEmission = 0.7,
			})),
			charge({ 255, 210, 60 }),
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
	-- Christmas-tree lights of four colours twinkling on and off all round its body, holly leaves round its antlers
	-- (2026-11-11, the owner: "like the coloured blinking lights on a Christmas tree")
	holly_deer = {
		pieces = {
			fairyLight("red", { 255, 60, 60 }),
			fairyLight("green", { 90, 255, 110 }),
			fairyLight("gold", { 255, 215, 70 }),
			second(fairyLight("blue", { 80, 160, 255 })),
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
	-- lagoon water dripping off its shell, aqua bubbles rising round it, sunlight glinting on the water (more and bigger
	-- since 2026-11-11, the owner)
	lagoon_turtle = {
		pieces = {
			drip("water", "droplet_gloss", AQUA, {
				box = { 1.4, 0.3, 1.4 },
				rate = 4,
				size = { { 0, 0 }, { 0.2, 0.26 }, { 1, 0.22 } },
				lightEmission = 0.3,
			}),
			rise("bubbles", "bubble_gloss", AQUA, {
				at = "feet",
				-- (born on a ring round its feet: under it the body hides them)
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 3,
				life = { 2, 2.6 },
				speed = { 0.8, 1.2 },
				spread = { 10, 10 },
				accel = { 0, 0.3, 0 },
				size = { { 0, 0 }, { 0.15, 0.22 }, { 0.9, 0.26 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.05 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
			}),
			second(hang("glints", "sparkStar", { 200, 250, 255 }, {
				radius = 2.2,
				rate = 5,
				life = { 0.8, 1.2 },
				size = { { 0, 0 }, { 0.4, 0.3 }, { 1, 0 } },
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
	-- a school of koi in sunset colours swimming round it together, head first, each a little above, below, in or out
	-- of the next as they wander (2026-11-11, the owner: "a school of many-coloured koi swimming round its body")
	-- (the owner's own 3D fish since 2026-11-11, in warm sunset colours, their fan tails sweeping as they swim)
	sunset_koi = {
		swimmers = {
			-- (out past its bulge, so its body never hides them)
			fish("lead", "gold_ink", 1.25, school(2.6, 0, 1.8)),
			fish("gold", "cream_gold", 1.15, school(2.95, -0.07, 1.35)),
			fish("pink", "blossom_pink", 1.1, school(2.4, -0.1, 2.3)),
			fish("blossom", "sakura_ink", 1.1, school(2.75, -0.16, 1.9)),
			second(fish("moon", "moon_ink", 1.05, school(3.1, -0.2, 1.55))),
		},
		pieces = {
			-- (a few bubbles rising off it, as if under water)
			rise("bubbles", "bubble_gloss", { { 255, 240, 220 }, { 255, 200, 150 } }, {
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				at = "feet",
				rate = 1.2,
				life = { 2, 2.6 },
				size = { { 0, 0 }, { 0.2, 0.16 }, { 1, 0.12 } },
				lightEmission = 0.3,
			}),
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
	-- its fiery side ablaze with real licking fire and embers, snow falling on its frozen side (2026-11-11, the owner:
	-- "snow falling on one side, fire blazing on the other")
	fire_ice_chimera = {
		pieces = {
			rise("fire", "flame_beautiful_flip", nil, {
				role = "keep",
				flipbook = { layout = "Grid8x8", mode = "OneShot" },
				box = { 0.15, 0.5, 0.7 },
				pose = { at = { 1.6, 0.4, 0 } },
				rate = 7,
				life = { 0.6, 0.8 },
				speed = { 0.6, 1 },
				spread = { 10, 10 },
				accel = { 0, 1.5, 0 },
				size = { { 0, 0.5 }, { 1, 0.65 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.4,
			}),
			-- (the library's blazing_flames tongues and embers on that side only)
			licks(FIRE, { box = { 0.2, 0.3, 0.7 }, pose = { at = { 1.3, 0, 0 } }, rate = 6 }),
			second(embers({ { 255, 230, 140 }, { 255, 140, 30 } }, {
				box = { 0.15, 0.5, 0.7 },
				pose = { at = { 1.7, 0.6, 0 } },
			})),
			fall("snow", "snow_crystals_flip", SNOW, {
				flipbook = SNOWFLAKES,
				box = { 0.45, 0, 0.9 },
				pose = { at = { -1.1, 0.2, 0 } },
				rate = 7,
				life = { 2, 2.6 },
				spread = { 20, 20 },
				accel = { 0, -1.2, 0 },
				size = { { 0, 0 }, { 0.12, 0.26 }, { 0.85, 0.24 }, { 1, 0 } },
				lightEmission = 0.6,
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
			-- (stars circling it, leaving short trails, since 2026-11-11, the owner)
			orbit("ring1", "star_fat", { 255, 240, 180 }, {
				orbit = { radius = 2.1, period = 3.5, phase = 0, y = 2, bob = { 0.3, 2.6 } },
				rate = 6,
				life = { 0.7, 0.8 },
				size = { { 0, 0.3 }, { 1, 0 } },
				lightEmission = 0.7,
			}),
			second(orbit("ring2", "star_fat", { 200, 190, 255 }, {
				orbit = { radius = 2.4, period = -4.5, phase = 0.5, y = 1.2, bob = { 0.3, 3.1 } },
				rate = 6,
				life = { 0.7, 0.8 },
				size = { { 0, 0.26 }, { 1, 0 } },
				lightEmission = 0.7,
			})),
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
			-- (deep-sea bubbles rising round it since 2026-11-11, the owner)
			rise("bubbles", "bubble_gloss", { 185, 140, 255 }, {
				at = "feet",
				-- (born on a ring round its feet: under it the body hides them)
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 3,
				life = { 2, 2.6 },
				speed = { 0.8, 1.2 },
				spread = { 10, 10 },
				accel = { 0, 0.3, 0 },
				size = { { 0, 0 }, { 0.15, 0.22 }, { 0.9, 0.26 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.05 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
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
				-- (a soft glow that flashes bright now and then, 2026-11-11, the owner)
				size = { { 0, 0.2 }, { 0.45, 0.22 }, { 0.5, 0.55 }, { 0.6, 0.22 }, { 1, 0.2 } },
				transparency = { { 0, 1 }, { 0.15, 0.1 }, { 0.5, 0 }, { 0.85, 0.1 }, { 1, 1 } },
				lightEmission = 1,
				steady = true,
			}),
			rise("bubbles", "bubble_gloss", { 150, 235, 255 }, {
				at = "feet",
				-- (born on a ring round its feet: under it the body hides them)
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 3,
				life = { 2, 2.6 },
				speed = { 0.8, 1.2 },
				spread = { 10, 10 },
				accel = { 0, 0.3, 0 },
				size = { { 0, 0 }, { 0.15, 0.22 }, { 0.9, 0.26 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.05 }, { 1, 1 } },
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				lightEmission = 0.2,
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
	-- a grey storm cloud over its head, now and then a bolt of lightning striking down onto it, sea spray at its base
	-- (2026-11-11, the owner)
	storm_shark = {
		pieces = {
			stormCloud({ 105, 110, 125 }),
			strike({ 225, 240, 255 }),
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
	-- black-grey shadow smoke pooling round its feet, veiling its lower body but seen through, dark wisps lifting off
	-- it (2026-11-11, the owner)
	shadow_wolf = {
		pieces = {
			-- (the library's shadow_wisps smoke since its second look)
			rise("shadow", "smoke_dark", { { 90, 86, 100 }, { 45, 42, 55 } }, {
				at = "feet",
				-- (born on a ring round its feet: under it the body hides them)
				radius = 1.85,
				shape = "Cylinder",
				shapeStyle = "Surface",
				rate = 4,
				life = { 2.4, 3 },
				speed = { 0.1, 0.3 },
				spread = { 60, 60 },
				accel = { 0, 0, 0 },
				drag = 0.6,
				size = { { 0, 0.5 }, { 0.5, 0.95 }, { 1, 1.05 } },
				transparency = { { 0, 1 }, { 0.3, 0.4 }, { 0.7, 0.5 }, { 1, 1 } },
				rotSpeed = { -12, 12 },
				lightEmission = 0,
			}),
			-- (shadow_wisps' own jagged wisps licking up round it like black flames)
			second(rise("wisps", "dark_wisp_a", { { 70, 60, 90 }, DARK }, {
				box = { 0.9, 0.6, 0.9 },
				shape = "Box",
				speed = { 2 * LIB, 4 * LIB },
				spread = { 20, 20 },
				accel = { 0, 6 * LIB, 0 },
				drag = 1,
				rate = 4,
				life = { 0.45, 0.65 },
				size = libSize({ { 0, 2.8 }, { 0.4, 4 }, { 1, 0 } }),
				transparency = { { 0, 1 }, { 0.25, 0.25 }, { 0.7, 0.35 }, { 1, 1 } },
				rotation = { -30, 30 },
				rotSpeed = { -100, 100 },
				orientation = "VelocityParallel",
				lightEmission = 0,
				zOffset = -0.5,
			})),
		},
	},
	-- a little solar system: planets of their own colours and sizes going round it, the near ones faster, stars
	-- twinkling in the night round them (2026-11-11, the owner: "a few planets turning round it, like the solar system")
	universe_slime = {
		pieces = {
			-- (twice the size since their first look: as specks they read as nothing)
			orbit("mercury", "ball_shaded", { 255, 150, 80 }, planet(1.9, 3.5, 0, 1.9, 0.4)),
			orbit("earth", "ball_shaded", AQUA, planet(2.4, 5, 0.35, 1.7, 0.55)),
			orbit("giant", "ball_shaded", { 255, 205, 120 }, planet(2.9, 7.5, 0.7, 1.5, 0.75)),
			second(orbit("ice", "ball_shaded", { 175, 140, 255 }, planet(3.3, 10, 0.15, 1.35, 0.5))),
			pop("stars", "star_twinkle", { 255, 245, 210 }, {
				radius = 2.4,
				shapeStyle = "Volume",
				rate = 4,
				size = { { 0, 0 }, { 0.35, 0.28 }, { 1, 0 } },
				lightEmission = 0.7,
			}),
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
	-- two soft drifts of cloud floating round its island shell, leaving wisps of mist behind, its waterfall trickling
	-- off (2026-11-11: the owner found the cartoon cloud poor and asked for cloud, smoke or steam)
	sky_island_turtle = {
		pieces = {
			orbit("clouds", "smoke_cloud_soft", WHITE, mist(0)),
			second(orbit("clouds2", "smoke_cloud_soft_b", WHITE, mist(0.5))),
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
	-- a grey rain cloud over its head, rain pouring from it onto the ram, grey wool puffs round its storm-cloud horns
	-- (the cloud since 2026-11-11, the owner)
	raincloud_ram = {
		pieces = {
			stormCloud({ 140, 148, 160 }),
			fall("rain", "rain_streak", nil, {
				role = "keep",
				at = "crown",
				lift = 1.1,
				box = { 0.65, 0, 0.45 },
				rate = 14,
				life = { 0.35, 0.45 },
				size = { { 0, 0.3 }, { 1, 0.3 } },
				transparency = { { 0, 0.1 }, { 1, 0.3 } },
				speed = { 6, 7 },
				spread = { 0, 0 },
				accel = { 0, -4, 0 },
				drag = 0,
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				orientation = "FacingCameraWorldUp",
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
			-- (bigger bolts and more of them since 2026-11-11: the owner found them too small to read; the library's
			-- electric_bolts, a third bigger than a pet's, its white sparks and its charge)
			bolts({ { 235, 255, 255 }, { 110, 230, 255 }, { 30, 160, 255 } }, {
				rate = 6,
				size = libSize({ { 0, 3.4 }, { 1, 4 } }),
			}),
			pop("arcs", "bolts_comic", CYAN, {
				radius = 1.8,
				shapePartial = 0.75,
				flipbook = TWO,
				rate = 3,
				life = { 0.25, 0.35 },
				size = { { 0, 0.85 }, { 1, 1 } },
				lightEmission = 1,
			}),
			zaps({ { 235, 255, 255 }, { 120, 230, 255 } }, { rate = 5 }),
			charge({ 60, 180, 255 }),
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
		if not piece.steady then
			piece.rate *= MORE
		end
	end
end

return {
	id = "aura.secret_signature",
	name = "Secret Signatures",
	kind = "aura",
	-- (mid since 2026-11-11: some Secrets wear a few companions, planets, lights or fish each one emitter)
	tier = "mid",
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
		art = "the library's pictures (ASSETS.md families) and pictures drawn for it, owner art kept as drawn; the owner's own 3D fish (models/fish/), rigged in Blender",
		licence = "the owner's own, ChatGPT pictures made for the owner, and free Creator Store pictures already in the library",
	},
	notes = "Attach to a Secret slime's body with opts.variant = its name in snake case. The owner: simple, but fitting each slime, so every one has an identity of its own; small and quiet, but fitting and beautiful.",
}
