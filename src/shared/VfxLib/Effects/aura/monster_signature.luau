-- Monster Signatures: the flames, smoke, poison, spores and frost the owner painted on his dungeon monster slimes and
-- the 3D models left out, one variant each (Goo Lineage V2, 2026-11-12). The owner: "the fire ones above all: put the
-- flames back where they were; poison slimes get poison, bubbles or toxic smoke; the others alike, only those that need
-- it". The game wears each on a small invisible anchor riding one bone of the monster (the painted spot), its front the
-- monster's front: every variant's refHeight is that anchor's size, so its numbers are studs on the built model.
-- Flames and smoke are not locked: they rise in the world and trail behind a monster that moves.
local SNOW = { 235, 245, 255 }
local HOT = { { 255, 250, 220 }, { 255, 190, 70 } }
local EMBER = { { 255, 220, 120 }, { 255, 120, 30 } }

local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

local function second(piece)
	piece.secondary = true
	return piece
end

local FOUR = { layout = "Grid4x4", mode = "OneShot" }
local EIGHT = { layout = "Grid8x8", mode = "OneShot" }
local FLAKES = { layout = "Grid4x4", mode = "Loop", fps = { 1, 2 }, random = true }
local SMALL_FLAKES = { layout = "Grid2x2", mode = "Random" }

-- Upright tongues of fire licking up off the spot.
local function flames(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		shape = "Box",
		orientation = "FacingCameraWorldUp",
		direction = "Top",
		spread = { 10, 10 },
		-- (solid as soon as it is born: its frames fade it themselves; a see-through flame reads pale on a bright map)
		transparency = { { 0, 0.5 }, { 0.08, 0 }, { 0.8, 0 }, { 1, 1 } },
		rotation = { -8, 8 },
		flipbook = FOUR,
		-- (a little light only: fully added, fire on a bright sky or floor washes out to white)
		lightEmission = 0.25,
		brightness = 1.2,
		locked = false,
	}, over)
end

-- Glowing embers drifting up off the spot.
local function embers(color, over)
	return with({
		name = "embers",
		texture = "embers_fly",
		color = color,
		at = "body",
		direction = "Top",
		spread = { 25, 25 },
		transparency = { { 0, 0 }, { 1, 0.3 } },
		rotation = { -180, 180 },
		lightEmission = 1,
		brightness = 3,
		locked = false,
	}, over)
end

-- Hot sparks shot up, stretched along their flight.
local function sparks(texture, color, over)
	return with({
		name = "sparks",
		texture = texture,
		color = color,
		at = "body",
		direction = "Top",
		spread = { 30, 30 },
		drag = 2.5,
		transparency = { { 0, 0 }, { 1, 0 } },
		squash = { { 0, -0.6 }, { 1, 0 } },
		orientation = "VelocityParallel",
		lightEmission = 1,
		brightness = 4,
		locked = false,
	}, over)
end

-- A soft glow held on the spot, breathing in and out.
local function glow(color, over)
	return with({
		name = "glow",
		texture = "glow_soft",
		color = color,
		at = "body",
		speed = { 0, 0 },
		transparency = { { 0, 1 }, { 0.35, 0.7 }, { 0.65, 0.7 }, { 1, 1 } },
		rotation = { -180, 180 },
		lightEmission = 1,
		zOffset = -0.5,
		locked = true,
	}, over)
end

-- Puffs of smoke, mist or fumes rising and swelling as they go.
local function fumes(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		direction = "Top",
		spread = { 20, 20 },
		drag = 0.5,
		rotation = { -180, 180 },
		rotSpeed = { -20, 20 },
		lightEmission = 0,
		locked = false,
	}, over)
end

-- Motes hanging in the air round the spot, drifting slowly: spores, pollen, glints.
local function motes(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		shape = "Sphere",
		shapeStyle = "Volume",
		shapePartial = 0.6,
		direction = "Top",
		speed = { 0.1, 0.3 },
		spread = { 180, 180 },
		drag = 0.3,
		transparency = { { 0, 0 }, { 1, 0.2 } },
		rotation = { -180, 180 },
		rotSpeed = { -40, 40 },
		lightEmission = 0.6,
		locked = false,
	}, over)
end

-- One glossy spore bubble riding a wandering circle the whole time.
local function orb(name, color, path, size)
	return {
		name = name,
		-- (a solid glossy bubble, as painted: a glow dot melted into the sky)
		texture = "bubble_gloss",
		color = color,
		orbit = path,
		rate = 0.25,
		life = { 4.05, 4.05 },
		size = { { 0, size }, { 1, size } },
		transparency = { { 0, 0 }, { 1, 0 } },
		speed = { 0, 0 },
		rotation = { 0, 0 },
		lightEmission = 0.4,
		locked = true,
		steady = true,
	}
end

-- Snow going round on a circle, its flakes left behind as a whirl (a deep ice blue with little light of its own: in
-- near-white the Ice map's white floor swallowed it).
local function whirl(name, path)
	return {
		name = name,
		texture = "snow_crystals_flip",
		color = { 110, 180, 255 },
		orbit = path,
		flipbook = FLAKES,
		rate = 12,
		life = { 0.8, 1.1 },
		size = { { 0, 0.9 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.3 } },
		speed = { 0, 0.3 },
		spread = { 180, 180 },
		accel = { 0, 1.2, 0 },
		rotation = { -180, 180 },
		rotSpeed = { -90, 90 },
		lightEmission = 0.1,
		locked = false,
	}
end

local variants = {
	-- EMBER LAVA
	-- Wickling: a small candle flame flickering on its wick's tip, a warm halo, now and then an ember
	wickling = {
		refHeight = 1.2,
		pieces = {
			flames("flame", "fire_curl_flip", nil, {
				role = "keep",
				box = { 0.12, 0, 0.12 },
				lift = 0.35,
				speed = { 0.4, 0.8 },
				spread = { 6, 6 },
				accel = { 0, 2, 0 },
				rate = 12,
				life = { 0.35, 0.5 },
				size = { { 0, 1.4 }, { 0.35, 2.2 }, { 1, 1 } },
			}),
			second(glow({ 255, 170, 60 }, {
				rate = 1.5,
				life = { 0.8, 1 },
				size = { { 0, 1.8 }, { 0.5, 2.1 }, { 1, 1.8 } },
			})),
			second(embers(EMBER, {
				box = { 0.2, 0.2, 0.2 },
				speed = { 0.8, 1.5 },
				accel = { 0, 1, 0 },
				rate = 2,
				life = { 0.7, 1.1 },
				size = { { 0, 0 }, { 0.2, 0.18 }, { 1, 0 } },
			})),
		},
	},
	-- Scorchdart: a mane of wild flame streaming off its back, thicker and sparking while it darts
	scorchdart = {
		refHeight = 2.5,
		pieces = {
			flames("mane", "fire_curl_d_flip", nil, {
				role = "keep",
				box = { 0.3, 0.1, 0.9 },
				lift = 1.2,
				speed = { 1, 1.8 },
				spread = { 12, 12 },
				accel = { 0, 3, 0 },
				motion = "run",
				idle = 0.6,
				rate = 18,
				life = { 0.4, 0.65 },
				size = { { 0, 2 }, { 0.4, 3 }, { 1, 1.3 } },
				rotation = { -10, 10 },
			}),
			second(sparks("ember_streak", HOT, {
				box = { 0.3, 0.1, 0.8 },
				speed = { 2.5, 4.5 },
				spread = { 35, 35 },
				motion = "run",
				idle = 0.3,
				rate = 5,
				life = { 0.25, 0.45 },
				size = { { 0, 0 }, { 0.15, 0.35 }, { 1, 0 } },
			})),
		},
	},
	-- Blazegullet: two curls of smoke rising from its nostrils, a glow inside them, now and then an ember
	blazegullet = {
		refHeight = 2,
		pieces = {
			-- (dusty rose, as painted: a grey smoke vanishes against the sky)
			fumes("smoke", "smoke_wisp_flip", { { 190, 120, 130 }, { 120, 85, 95 } }, {
				box = { 0.5, 0, 0.08 },
				lift = 0.4,
				speed = { 0.6, 1 },
				spread = { 10, 10 },
				accel = { 0, 0.5, 0 },
				drag = 0.4,
				rate = 4.5,
				life = { 1.5, 2 },
				size = { { 0, 1.2 }, { 1, 3.2 } },
				transparency = { { 0, 1 }, { 0.1, 0 }, { 0.65, 0.3 }, { 1, 1 } },
				rotation = { -20, 20 },
				rotSpeed = { -25, 25 },
				flipbook = FOUR,
			}),
			second(glow({ 255, 120, 40 }, {
				texture = "glow_dot",
				box = { 0.5, 0, 0 },
				rate = 1.2,
				life = { 1, 1.4 },
				size = { { 0, 0.5 }, { 1, 0.5 } },
				transparency = { { 0, 1 }, { 0.3, 0.5 }, { 0.7, 0.5 }, { 1, 1 } },
				zOffset = 0.2,
			})),
			embers(EMBER, {
				box = { 0.4, 0, 0.1 },
				speed = { 0.8, 1.5 },
				spread = { 30, 30 },
				accel = { 0, 1, 0 },
				rate = 0.8,
				life = { 0.8, 1.2 },
				size = { { 0, 0 }, { 0.2, 0.14 }, { 1, 0 } },
			}),
		},
	},
	-- Pyrekeeper: a pale golden fire of spiky flames burning in its brazier, sparks rising off it
	pyrekeeper = {
		refHeight = 2,
		pieces = {
			flames("flame", "fire_curl_c_flip", nil, {
				role = "keep",
				box = { 0.45, 0, 0.45 },
				lift = 0.6,
				speed = { 0.6, 1.2 },
				spread = { 8, 8 },
				accel = { 0, 2.5, 0 },
				rate = 16,
				life = { 0.4, 0.6 },
				size = { { 0, 1.7 }, { 0.4, 2.7 }, { 1, 1.2 } },
				rotation = { -6, 6 },
			}),
			sparks("spark_dot", { { 255, 250, 215 }, { 255, 215, 110 } }, {
				box = { 0.4, 0, 0.4 },
				speed = { 2, 3.5 },
				spread = { 20, 20 },
				drag = 1.2,
				accel = { 0, 0.5, 0 },
				rate = 4,
				life = { 0.6, 1 },
				size = { { 0, 0.12 }, { 1, 0.04 } },
				squash = { { 0, -0.5 }, { 1, -0.5 } },
				brightness = 3,
			}),
			second(glow({ 255, 215, 120 }, {
				rate = 1.2,
				life = { 1, 1.3 },
				size = { { 0, 1.8 }, { 1, 2.1 } },
				transparency = { { 0, 1 }, { 0.4, 0.75 }, { 1, 1 } },
			})),
		},
	},
	-- Magmaw (mini-boss): molten drops falling from its teeth, glowing strands hanging off them, embers rising out of
	-- its maw
	magmaw = {
		refHeight = 4,
		pieces = {
			-- (glossy solid drops, half added: a drop drawn on black melted into a bright floor)
			{
				name = "drips",
				texture = "droplet_gloss",
				color = { { 255, 225, 110 }, { 255, 140, 35 }, { 230, 70, 20 } },
				at = "body",
				box = { 0.7, 0, 0.2 },
				shape = "Box",
				direction = "Bottom",
				speed = { 0, 0.3 },
				accel = { 0, -12, 0 },
				rate = 5,
				life = { 0.45, 0.65 },
				size = { { 0, 0.4 }, { 0.15, 0.6 }, { 1, 0.45 } },
				transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
				rotation = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.5,
				brightness = 1.5,
				locked = false,
			},
			{
				name = "strands",
				texture = "streak_drip",
				color = { { 255, 180, 60 }, { 240, 90, 20 } },
				at = "body",
				box = { 0.7, 0, 0.2 },
				shape = "Box",
				speed = { 0, 0 },
				rate = 3,
				life = { 0.5, 0.8 },
				size = { { 0, 0.9 }, { 1, 1.4 } },
				transparency = { { 0, 1 }, { 0.2, 0.2 }, { 0.8, 0.3 }, { 1, 1 } },
				rotation = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 1,
				brightness = 2,
				locked = true,
			},
			second(embers(nil, {
				texture = "embers_flip",
				role = "keep",
				box = { 0.5, 0.3, 0.3 },
				speed = { 1, 2 },
				accel = { 0, 1.5, 0 },
				rate = 5,
				life = { 0.8, 1.2 },
				size = { { 0, 0.3 }, { 0.3, 0.55 }, { 1, 0.15 } },
				flipbook = EIGHT,
				transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				brightness = 1,
			})),
		},
	},
	-- Calderos (boss): a roaring mane of fire up off its head, tongues licking round it, embers and sparks, its glow
	-- lighting the ground
	calderos = {
		refHeight = 8,
		light = { color = { 255, 140, 50 }, brightness = 2, range = 16 },
		pieces = {
			flames("mane", "fire_beautiful_flip", nil, {
				role = "keep",
				box = { 0.9, 0.15, 0.6 },
				lift = 1.5,
				speed = { 2, 3.5 },
				spread = { 15, 15 },
				accel = { 0, 5, 0 },
				rate = 18,
				life = { 0.6, 0.9 },
				size = { { 0, 2.6 }, { 0.35, 4.2 }, { 1, 2.2 } },
				transparency = { { 0, 1 }, { 0.1, 0.05 }, { 0.75, 0.25 }, { 1, 1 } },
				rotation = { -10, 10 },
				flipbook = EIGHT,
				lightEmission = 0.3,
			}),
			flames("licks", "fire_curl_b_flip", nil, {
				role = "keep",
				box = { 0.8, 0.15, 0.7 },
				lift = 1,
				speed = { 1.5, 2.5 },
				accel = { 0, 4, 0 },
				rate = 9,
				life = { 0.5, 0.75 },
				size = { { 0, 2 }, { 0.4, 3.2 }, { 1, 1.4 } },
				transparency = { { 0, 1 }, { 0.15, 0.1 }, { 0.7, 0.3 }, { 1, 1 } },
			}),
			embers(EMBER, {
				box = { 1, 0.6, 1 },
				speed = { 1.5, 3 },
				spread = { 30, 30 },
				accel = { 0, 2.5, 0 },
				rate = 6,
				life = { 1, 1.5 },
				size = { { 0, 0 }, { 0.2, 0.35 }, { 1, 0 } },
			}),
			second(sparks("ember_streak", HOT, {
				box = { 0.8, 0.3, 0.8 },
				speed = { 5, 9 },
				rate = 4,
				life = { 0.3, 0.55 },
				size = { { 0, 0 }, { 0.15, 0.6 }, { 1, 0 } },
			})),
		},
	},

	-- MUSHROOM GROVE
	-- Bilebloat: toxic bubbles swelling and popping all over its skin, acid dripping off it, poison fumes rising
	bilebloat = {
		refHeight = 4,
		pieces = {
			-- (glossy bubbles swelling on the skin and popping: a solid picture, so they read on a bright map too)
			{
				name = "bubbles",
				texture = "bubble_gloss",
				color = { { 215, 255, 60 }, { 160, 240, 40 } },
				at = "body",
				radius = 1.7,
				shape = "Sphere",
				shapeStyle = "Surface",
				shapePartial = 0.7,
				direction = "Top",
				speed = { 0, 0.05 },
				rate = 6,
				life = { 1, 1.4 },
				size = { { 0, 0 }, { 0.7, 1.3 }, { 0.88, 1.5 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotation = { -180, 180 },
				lightEmission = 0.3,
				locked = true,
			},
			{
				name = "drip",
				texture = "acidDrop",
				role = "keep",
				at = "waist",
				box = { 0.7, 0.2, 0.7 },
				direction = "Bottom",
				speed = { 0, 0.2 },
				accel = { 0, -8, 0 },
				rate = 1.5,
				life = { 0.6, 0.9 },
				size = { { 0, 0 }, { 0.2, 0.5 }, { 1, 0.4 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotation = { 0, 0 },
				orientation = "FacingCameraWorldUp",
				lightEmission = 0.2,
				locked = false,
			},
			second(fumes("fumes", "smoke_blobs_flip", { { 205, 255, 60 }, { 140, 215, 40 } }, {
				at = "head",
				box = { 0.6, 0, 0.6 },
				speed = { 0.4, 0.7 },
				accel = { 0, 0.3, 0 },
				rate = 2,
				life = { 1.8, 2.4 },
				size = { { 0, 1.2 }, { 1, 3 } },
				transparency = { { 0, 1 }, { 0.12, 0.1 }, { 0.6, 0.35 }, { 1, 1 } },
				flipbook = FOUR,
				lightEmission = 0.15,
			})),
		},
	},
	-- Sporegorge (mini-boss): green toxic mist curling up out of its split sacs, the owner's spores drifting round it
	sporegorge = {
		refHeight = 6,
		pieces = {
			-- (neon lime curls, as painted, solid at their thickest: a pale or faint smoke vanished on a bright map)
			fumes("mist", "smoke_wisp_flip", { { 210, 255, 50 }, { 160, 235, 40 } }, {
				box = { 0.7, 0.3, 0.7 },
				speed = { 0.5, 0.9 },
				spread = { 25, 25 },
				accel = { 0, 0.35, 0 },
				drag = 0.4,
				rate = 5,
				life = { 2, 2.6 },
				size = { { 0, 2 }, { 1, 4.4 } },
				transparency = { { 0, 1 }, { 0.12, 0 }, { 0.6, 0.3 }, { 1, 1 } },
				rotation = { -25, 25 },
				rotSpeed = { -15, 15 },
				flipbook = FOUR,
				lightEmission = 0.35,
			}),
			motes("spores", "spore", nil, {
				role = "keep",
				radius = 3,
				speed = { 0.2, 0.5 },
				drag = 0.4,
				rate = 3,
				life = { 2, 3 },
				size = { { 0, 0 }, { 0.3, 0.7 }, { 0.7, 0.7 }, { 1, 0 } },
				lightEmission = 0.3,
			}),
		},
	},
	-- Hexcap: two glowing spore orbs circling its cap, smaller ones floating free round it
	hexcap = {
		refHeight = 3.5,
		pieces = {
			orb("orb", { 60, 240, 200 }, { radius = 1.5, period = 5, phase = 0, y = 1.9, bob = { 0.25, 2 } }, 0.7),
			second(
				orb(
					"orb2",
					{ 120, 250, 160 },
					{ radius = 1.7, period = 6.5, phase = 0.5, y = 2.3, bob = { 0.3, 2.6 } },
					0.55
				)
			),
			-- (dot_round, not mote_glow: mote_glow's dark square shows on a bright map, seen 2026-11-12)
			motes("motes", "dot_round", { { 90, 245, 190 }, { 40, 210, 170 } }, {
				radius = 1.6,
				rate = 3,
				life = { 2, 3 },
				size = { { 0, 0 }, { 0.25, 0.35 }, { 0.75, 0.35 }, { 1, 0 } },
				lightEmission = 0.4,
			}),
		},
	},
	-- Hollowheart (boss): faint teal spores drifting down from its glowing mushrooms, glints winking on them
	hollowheart = {
		refHeight = 9,
		pieces = {
			{
				name = "spores",
				texture = "glow_dot_small",
				color = { { 60, 230, 210 }, { 40, 180, 190 } },
				at = "body",
				box = { 1, 0.2, 1 },
				shape = "Box",
				direction = "Bottom",
				speed = { 0.2, 0.5 },
				spread = { 30, 30 },
				accel = { 0, -0.5, 0 },
				drag = 0.8,
				rate = 10,
				life = { 2.6, 3.6 },
				size = { { 0, 0 }, { 0.15, 0.7 }, { 0.85, 0.7 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
				rotation = { -180, 180 },
				rotSpeed = { -30, 30 },
				lightEmission = 0.5,
				locked = false,
			},
			second(motes("glints", "sparkStar", { 150, 255, 230 }, {
				radius = 3.5,
				shapeStyle = "Surface",
				speed = { 0, 0 },
				rate = 2,
				life = { 0.7, 1 },
				size = { { 0, 0 }, { 0.35, 0.4 }, { 1, 0 } },
				rotSpeed = { -45, 45 },
				lightEmission = 0.8,
				locked = true,
			})),
		},
	},
	-- Glimlure: its anglerfish lure glowing teal, lighting what is near, a few motes floating off it
	glimlure = {
		refHeight = 1,
		light = { color = { 110, 255, 230 }, brightness = 1.5, range = 6 },
		pieces = {
			-- (half added: fully added it burnt to a white blob)
			glow({ 60, 235, 210 }, {
				rate = 2,
				life = { 0.9, 1.2 },
				size = { { 0, 0.8 }, { 0.5, 1.05 }, { 1, 0.8 } },
				lightEmission = 0.6,
				transparency = { { 0, 1 }, { 0.3, 0.3 }, { 0.7, 0.3 }, { 1, 1 } },
				brightness = 2,
				zOffset = 0.2,
			}),
			second(motes("motes", "glow_dot", { 170, 255, 240 }, {
				radius = 0.6,
				speed = { 0.1, 0.25 },
				rate = 2,
				life = { 1, 1.6 },
				size = { { 0, 0 }, { 0.3, 0.12 }, { 1, 0 } },
				lightEmission = 1,
			})),
		},
	},

	-- SUNNY MEADOW
	-- Sapcaller: dandelion fluff drifting off its seed puff on the breeze, golden pollen hanging round it
	sapcaller = {
		refHeight = 2.6,
		pieces = {
			{
				name = "seeds",
				texture = "down_feather",
				color = { 250, 250, 240 },
				at = "body",
				box = { 0.4, 0.3, 0.4 },
				direction = "Top",
				speed = { 0.4, 0.8 },
				spread = { 60, 60 },
				accel = { 0.4, 0.15, 0 },
				drag = 0.8,
				rate = 2,
				life = { 2.2, 3 },
				size = { { 0, 0 }, { 0.15, 0.32 }, { 0.85, 0.3 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.05 }, { 1, 1 } },
				rotation = { -30, 30 },
				rotSpeed = { -40, 40 },
				lightEmission = 0.15,
				locked = false,
			},
			second(motes("pollen", "dot_round", { 255, 215, 90 }, {
				radius = 1.4,
				rate = 2,
				life = { 2, 2.8 },
				size = { { 0, 0 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 0 } },
			})),
		},
	},
	-- Rotbloom (mini-boss): pollen puffing up out of its flower's middle, sparkling dust floating off it
	rotbloom = {
		refHeight = 5,
		pieces = {
			-- (golden turning rose, as painted: a pale yellow puff melted into the sky)
			fumes("puffs", "smoke_puff_solid_flip", { { 255, 200, 60 }, { 245, 150, 90 }, { 240, 140, 160 } }, {
				box = { 0.25, 0, 0.25 },
				lift = 0.4,
				speed = { 1.5, 2.6 },
				spread = { 22, 22 },
				drag = 1.6,
				accel = { 0, 0.3, 0 },
				rate = 3.5,
				life = { 1.3, 1.7 },
				size = { { 0, 1.5 }, { 1, 4 } },
				transparency = { { 0, 1 }, { 0.08, 0 }, { 0.6, 0.25 }, { 1, 1 } },
				rotSpeed = { -25, 25 },
				flipbook = FOUR,
				lightEmission = 0.2,
			}),
			second(motes("dust", "dot_round", { { 255, 190, 50 }, { 255, 140, 40 } }, {
				radius = 1.5,
				speed = { 0.6, 1.2 },
				spread = { 40, 40 },
				drag = 0.8,
				accel = { 0, 0.3, 0 },
				rate = 4,
				life = { 1.2, 1.8 },
				size = { { 0, 0 }, { 0.3, 0.22 }, { 1, 0 } },
			})),
		},
	},

	-- FROZEN ICE
	-- Snowshroud: frost mist curling round its hem, a few snowflakes falling round it
	snowshroud = {
		refHeight = 4,
		pieces = {
			-- (curling wisps tinted ice blue: smoke_frost, a blue-grey picture, read as grey dirt on the Ice map's white floor)
			fumes("mist", "smoke_wisp_flip", { { 140, 195, 255 }, { 90, 155, 240 } }, {
				flipbook = FOUR,
				at = "feet",
				radius = 1.7,
				shape = "Cylinder",
				shapeStyle = "Surface",
				speed = { 0.15, 0.35 },
				spread = { 40, 40 },
				accel = { 0, 0.12, 0 },
				rate = 4,
				life = { 2, 2.6 },
				size = { { 0, 0.8 }, { 1, 2 } },
				transparency = { { 0, 1 }, { 0.2, 0.15 }, { 0.7, 0.45 }, { 1, 1 } },
				rotSpeed = { -12, 12 },
				lightEmission = 0.1,
			}),
			second({
				name = "flakes",
				texture = "snow_crystals_flip",
				color = SNOW,
				at = "head",
				box = { 0.8, 0, 0.8 },
				direction = "Bottom",
				speed = { 0.1, 0.3 },
				spread = { 40, 40 },
				accel = { 0, -1, 0 },
				drag = 1,
				rate = 2.5,
				life = { 2, 2.6 },
				size = { { 0, 0 }, { 0.12, 0.22 }, { 0.85, 0.2 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.85, 0.05 }, { 1, 1 } },
				rotation = { -180, 180 },
				rotSpeed = { -60, 60 },
				flipbook = FLAKES,
				lightEmission = 0.4,
				locked = false,
			}),
		},
	},
	-- Rimetusk (mini-boss): frost breath puffing out of its mouth, forward and down, ice glitter in it
	rimetusk = {
		refHeight = 3.5,
		pieces = {
			-- (frost breath tinted ice blue: near-white, the Ice map's white floor behind it swallowed it)
			fumes("breath", "smoke_cloud_soft", { { 185, 222, 255 }, { 130, 185, 250 } }, {
				box = { 0.15, 0.1, 0 },
				direction = "Front",
				speed = { 1.8, 2.8 },
				spread = { 12, 12 },
				drag = 2,
				accel = { 0, -0.6, 0 },
				rate = 4,
				life = { 0.9, 1.3 },
				size = { { 0, 0.5 }, { 1, 2 } },
				transparency = { { 0, 1 }, { 0.1, 0.1 }, { 0.6, 0.45 }, { 1, 1 } },
				rotSpeed = { -30, 30 },
				lightEmission = 0.1,
			}),
			second({
				name = "glitter",
				texture = "fx_snowflakes",
				color = SNOW,
				at = "body",
				box = { 0.15, 0.1, 0 },
				direction = "Front",
				speed = { 1.2, 2.2 },
				spread = { 20, 20 },
				drag = 1.5,
				accel = { 0, -0.8, 0 },
				rate = 2,
				life = { 0.8, 1.2 },
				size = { { 0, 0.12 }, { 1, 0.2 } },
				transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				rotation = { -180, 180 },
				flipbook = SMALL_FLAKES,
				lightEmission = 1,
				locked = false,
			}),
		},
	},
	-- Frostmaw (boss): a whirl of snow going round its base, drifts of snow smoke billowing up round its feet, flakes
	-- falling on it
	frostmaw = {
		refHeight = 11,
		pieces = {
			-- (the whirls and the drift go round outside its body: Frostmaw is about 13 studs wide on an 11-stud anchor
			-- played at 1.15, so 6 of these units from its middle; at 5 and 4.6 its body hid them all)
			whirl("whirl", { radius = 7.6, period = 2.6, phase = 0, y = 1.2, bob = { 0.6, 1.9 } }),
			whirl("whirl2", { radius = 8.3, period = 2.6, phase = 0.5, y = 2.2, bob = { 0.5, 2.3 } }),
			-- (snow smoke in solid puffs tinted ice blue, nearly solid: the thin smoke_tufts_flip, near-white or blue, and
			-- these puffs at 0.35 see-through vanished on the Ice map's white floor. A low ring round its feet: `radius`
			-- makes a cube, as tall as it is wide, which put them up to its shoulders)
			fumes("drift", "smoke_puff_solid_flip", { { 120, 180, 255 }, { 80, 145, 240 } }, {
				at = "feet",
				box = { 1.31, 0.15, 1.31 },
				shape = "Cylinder",
				shapeStyle = "Surface",
				speed = { 0.6, 1.2 },
				spread = { 50, 50 },
				accel = { 0, 0.4, 0 },
				drag = 0.8,
				rate = 4,
				life = { 1.4, 1.9 },
				size = { { 0, 2 }, { 1, 4.5 } },
				transparency = { { 0, 1 }, { 0.15, 0.1 }, { 0.7, 0.35 }, { 1, 1 } },
				rotSpeed = { -25, 25 },
				flipbook = FOUR,
				lightEmission = 0.1,
			}),
			second({
				name = "flakes",
				texture = "fx_snowflakes",
				color = SNOW,
				at = "above",
				box = { 0.7, 0, 0.7 },
				direction = "Bottom",
				speed = { 1.2, 2 },
				spread = { 12, 12 },
				rate = 6,
				life = { 2, 2.6 },
				size = { { 0, 0.3 }, { 0.15, 0.45 }, { 1, 0.4 } },
				transparency = { { 0, 1 }, { 0.12, 0.05 }, { 0.8, 0.15 }, { 1, 1 } },
				rotation = { -180, 180 },
				flipbook = SMALL_FLAKES,
				lightEmission = 1,
				locked = false,
			}),
		},
	},
}

return {
	id = "aura.monster_signature",
	name = "Monster Signatures",
	kind = "aura",
	tier = "mid",
	host = "any",
	refHeight = 4,
	tags = { "dungeon", "monster", "signature", "per_creature", "fire", "smoke", "poison", "spores", "frost" },
	blend = "normal",
	palette = {},
	tintable = false,
	pieces = variants.wickling.pieces,
	variants = variants,
	defaultVariant = "wickling",
	source = {
		from = "Goo Lineage V2 (2026-11-12): the effects painted on its 28 Slime Dungeon monsters, for the 16 that wear one",
		art = "the library's pictures (ASSETS.md families), owner art kept as drawn (spore, acidDrop)",
		licence = "the owner's own and free Creator Store pictures already in the library",
	},
	notes = "Attach to a small anchor part riding the monster's bone at the painted spot (its front the monster's front), the anchor's size the variant's refHeight, opts.variant = the monster's name in lower case.",
}
