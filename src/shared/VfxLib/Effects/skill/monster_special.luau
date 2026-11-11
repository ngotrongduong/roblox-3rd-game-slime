-- Monster Special: what comes down when a dungeon monster's special goes off (Goo Lineage V2, 2026-11-12), one variant
-- per special, each with its own pictures, motion and burst (never one effect recoloured). The game plays it at the
-- caster's centre (a wall, a mend, a burst round itself) or at the target's spot (a bite, a blow, a breath, a fall); the
-- special's blows still land as the monster's own hit effect on top. The bosses' and mini-bosses' variants have a
-- wind-up of the same name (skill.monster_windup). Numbers are studs on a 5-stud box (the game scales them by the
-- monster's size). Solid pictures first (smoke, leaves, rocks, shards, glossy drops), lightEmission 0 to 0.4, so they read
-- on the bright maps; the added glows are small accents. A regular's release is about 60 particles at most, a boss's
-- about 120. (`embers_fly` is dark-backed: worn fully added, lightEmission 1, or its grey square shows on a bright map;
-- the packs' 4 x 4 explosion is pixelated at this size, the library's sharp redraw `explosion_sharp_1..3` is not.)
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		if value == false then
			out[key] = nil
		else
			out[key] = value
		end
	end
	return out
end

local FOUR = { layout = "Grid4x4", mode = "OneShot" }
local LEAVES = { layout = "Grid2x2", mode = "Random" }
local ROCKS = { layout = "Grid2x2", mode = "PingPong", fps = { 0, 0 }, random = true }
local FLAKES = { layout = "Grid4x4", mode = "Loop", fps = { 1, 2 }, random = true }
local SHARP = { layout = "Grid2x2", mode = "OneShot" }

-- A ring (or any flat picture) lying on the ground, racing out to `width` studs. (A hair over the floor and drawn a
-- little toward the camera: on the floor itself, or pushed away from the camera, the floor hid it.)
local function wave(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, 0.1, 0 },
		flat = true,
		count = 1,
		life = { 0.7, 0.7 },
		size = { { 0, width * 0.25 }, { 0.3, width * 0.8 }, { 1, width } },
		transparency = { { 0, 0 }, { 0.5, 0.2 }, { 1, 1 } },
		zOffset = 0.5,
	}, over)
end

-- A throw: `count` bits flung up and out from the centre, falling back.
local function fling(name, texture, color, count, speed, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.5, 1 },
		size = { { 0, 1.2 }, { 1, 0.4 } },
		transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
		speed = speed,
		spread = { 70, 70 },
		direction = "Top",
		accel = { 0, -14, 0 },
		drag = 1.2,
		rotation = { 0, 359 },
		rotSpeed = { -180, 180 },
		zOffset = 2,
	}, over)
end

-- One picture flaring at the centre and fading.
local function pop(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.45, 0.45 },
		size = { { 0, size * 0.5 }, { 0.2, size }, { 1, size * 1.15 } },
		transparency = { { 0, 0.2 }, { 0.15, 0 }, { 0.6, 0.2 }, { 1, 1 } },
		rotation = { 0, 359 },
		zOffset = 2,
	}, over)
end

-- Things standing up out of the ground in a ring, `height` studs tall.
local function rise(name, texture, color, count, height, radius, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, height * 0.4, 0 },
		shape = "Disc",
		shapeStyle = "Surface",
		radius = radius,
		orientation = "FacingCameraWorldUp",
		direction = "Top",
		count = count,
		speed = { 1, 2 },
		life = { 0.7, 1 },
		size = { { 0, height * 0.2 }, { 0.25, height }, { 0.8, height }, { 1, height * 0.8 } },
		transparency = { { 0, 0.3 }, { 0.15, 0 }, { 0.75, 0.1 }, { 1, 1 } },
		zOffset = 1,
	}, over)
end

local ORANGE = { { 255, 225, 110 }, { 255, 140, 35 } }
local GREENS = { { 110, 190, 60 }, { 70, 150, 50 } }
-- (ice and frost in a deep ice blue with little light of their own, never near-white: the Ice map's floor is near-white
-- (#ddebf5) and swallowed the pale blues too, on its own colour in the showroom)
local ICE = { { 110, 185, 255 }, { 60, 140, 240 } }
local SNOW = { 165, 212, 255 }
local FROST = { 70, 150, 245 }
local FROST_CLOUD = { { 150, 200, 255 }, { 95, 160, 245 } }
local LIME = { { 215, 255, 60 }, { 160, 240, 40 } }

local variants = {
	-- ROTBLOOM (meadow mini-boss)
	-- root_snare: roots and vines bursting up under the target and wrapping, clods and leaves thrown, a brown-green ring
	root_snare = {
		pieces = {
			rise("roots", "spikes_up", { { 145, 105, 60 }, { 105, 78, 45 } }, 7, 3.4, 1.8),
			rise("wrap", "spikes_cluster", { 85, 140, 55 }, 4, 3, 1.2, { delay = 0.08, rotation = { -20, 20 } }),
			fling(
				"leaves",
				"leaves_solid",
				GREENS,
				10,
				{ 6, 12 },
				{ flipbook = LEAVES, size = { { 0, 1 }, { 1, 0.4 } } }
			),
			fling(
				"clods",
				"blots_flip",
				{ 95, 70, 45 },
				8,
				{ 5, 10 },
				{ flipbook = FOUR, size = { { 0, 0.9 }, { 1, 0.3 } } }
			),
			wave("ring", "ring_rough", { 125, 88, 45 }, 13),
		},
	},
	-- BRAMBLEHORN (meadow boss)
	-- bramble_burst: a ring of thorns erupting outward along the ground, red berries and leaves flying, dust
	bramble_burst = {
		pieces = {
			rise("thorns", "spikes_up", { { 125, 150, 55 }, { 150, 110, 55 } }, 12, 3, 4),
			wave("ring", "ring_spiky", { 175, 130, 55 }, 18),
			fling(
				"leaves",
				"leaves_solid",
				{ { 120, 190, 60 }, { 210, 90, 50 } },
				10,
				{ 7, 13 },
				{ flipbook = LEAVES }
			),
			fling(
				"berries",
				"dot_solid",
				{ 205, 40, 45 },
				8,
				{ 7, 13 },
				{ size = { { 0, 0.5 }, { 1, 0.4 } }, accel = { 0, -18, 0 } }
			),
			fling("dust", "dust_kick_flip", { 200, 175, 135 }, 4, { 5, 9 }, {
				spread = { 180, 25 },
				accel = { 0, 0, 0 },
				drag = 2,
				size = { { 0, 1.6 }, { 1, 4.2 } },
				transparency = { { 0, 0.4 }, { 0.2, 0.15 }, { 1, 1 } },
				flipbook = FOUR,
			}),
		},
	},
	-- horn_toss: an upward toss: dust and wood chips rising, a slam star at the target, leaves spinning up, a dust ring
	horn_toss = {
		pieces = {
			fling("dust", "dust_kick_flip", { 200, 175, 135 }, 5, { 10, 16 }, {
				spread = { 25, 25 },
				accel = { 0, -6, 0 },
				size = { { 0, 1.2 }, { 1, 3 } },
				transparency = { { 0, 0.45 }, { 0.2, 0.3 }, { 1, 1 } },
				flipbook = FOUR,
			}),
			fling(
				"chips",
				"shard_flat",
				{ 165, 120, 70 },
				10,
				{ 14, 22 },
				{ spread = { 22, 22 }, size = { { 0, 0.7 }, { 1, 0.25 } } }
			),
			pop("star", "burst_comic", { 255, 230, 160 }, 6, { life = { 0.25, 0.25 } }),
			fling("leaves", "leaves_solid", { { 120, 190, 60 }, { 200, 170, 60 } }, 8, { 12, 18 }, {
				spread = { 20, 20 },
				accel = { 0, -8, 0 },
				rotSpeed = { -400, 400 },
				flipbook = LEAVES,
			}),
			wave("ring", "ring_wave", { 200, 170, 120 }, 11),
		},
	},
	-- SPOREGORGE (mushroom mini-boss)
	-- gorge_bite: a giant bite: the owner's acid splat on the ground, acid drops and purple spores spraying, a lime ring
	gorge_bite = {
		pieces = {
			wave("splat", "acidSplat", nil, 7, {
				role = "keep",
				life = { 0.9, 0.9 },
				size = { { 0, 3 }, { 0.15, 7 }, { 1, 7.5 } },
				transparency = { { 0, 0.05 }, { 0.6, 0.1 }, { 1, 1 } },
			}),
			fling("drops", "acidDrop", nil, 12, { 9, 16 }, {
				role = "keep",
				orientation = "FacingCameraWorldUp",
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				size = { { 0, 0.8 }, { 1, 0.5 } },
				accel = { 0, -16, 0 },
			}),
			fling("spores", "spore", nil, 8, { 6, 12 }, { role = "keep", size = { { 0, 1 }, { 1, 0.3 } } }),
			wave("ring", "ringAcid", nil, 12, { role = "keep", delay = 0.05 }),
			pop("flash", "burstAcid", nil, 6, { role = "keep", life = { 0.3, 0.3 } }),
		},
	},
	-- HOLLOWHEART (mushroom boss)
	-- root_grasp: a wave of dark roots rippling outward over the ground, teal glints, purple dust
	root_grasp = {
		pieces = {
			wave("roots", "crack_ground", { 60, 35, 80 }, 12, { life = { 0.9, 0.9 } }),
			wave("ring", "ring_torn", { 80, 40, 120 }, 16, { delay = 0.05 }),
			wave("rip", "ring_shreds", { 40, 200, 180 }, 20, { delay = 0.12, lightEmission = 0.3 }),
			fling("glints", "star_glint_small", { 150, 255, 235 }, 10, { 3, 8 }, {
				spread = { 90, 90 },
				accel = { 0, 2, 0 },
				size = { { 0, 0 }, { 0.3, 0.7 }, { 1, 0 } },
				lightEmission = 0.6,
			}),
			fling("dust", "dust_kick_flip", { 110, 70, 150 }, 6, { 4, 8 }, {
				spread = { 180, 20 },
				accel = { 0, 0, 0 },
				drag = 2,
				size = { { 0, 1.6 }, { 1, 4.4 } },
				transparency = { { 0, 0.4 }, { 0.2, 0.15 }, { 1, 1 } },
				flipbook = FOUR,
			}),
		},
	},
	-- heart_pulse: three teal shockwave rings racing out, a spiral rune flash at the centre, spores flung out
	heart_pulse = {
		pieces = {
			wave("rings", "ring_wave", { 70, 235, 210 }, 18, {
				count = false,
				bursts = { { 0, 1 }, { 0.14, 1 }, { 0.28, 1 } },
				lightEmission = 0.3,
			}),
			wave("rune", "rune_circle", { 110, 245, 225 }, 9, {
				life = { 0.5, 0.5 },
				size = { { 0, 3 }, { 0.3, 8 }, { 1, 9 } },
				rotSpeed = { 150, 150 },
				lightEmission = 0.4,
			}),
			pop(
				"flash",
				"halo_swirl",
				{ 110, 245, 225 },
				5,
				{ life = { 0.4, 0.4 }, rotSpeed = { 120, 120 }, lightEmission = 0.6 }
			),
			fling(
				"spores",
				"spore",
				nil,
				10,
				{ 8, 14 },
				{ role = "keep", spread = { 180, 180 }, size = { { 0, 1 }, { 1, 0.3 } } }
			),
		},
	},
	-- MAGMAW (lava mini-boss)
	-- molten_chomp: two bites of lava: splash chunks and molten droplets spraying round the target, embers, a scorch ring
	molten_chomp = {
		pieces = {
			fling("chunks", "splat_burst_flip", { 255, 165, 50 }, 0, { 9, 15 }, {
				count = false,
				bursts = { { 0, 8 }, { 0.25, 8 } },
				size = { { 0, 1.3 }, { 1, 0.5 } },
				accel = { 0, -16, 0 },
				flipbook = FOUR,
				-- (a little light: tinted orange, its grey shading read as brown mud)
				lightEmission = 0.35,
			}),
			fling("drops", "droplet_gloss", ORANGE, 12, { 8, 15 }, {
				orientation = "FacingCameraWorldUp",
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				size = { { 0, 0.6 }, { 1, 0.3 } },
				accel = { 0, -22, 0 },
				lightEmission = 0.4,
			}),
			fling("embers", "embers_fly", { { 255, 200, 90 }, { 255, 100, 25 } }, 10, { 5, 11 }, {
				size = { { 0, 0.5 }, { 1, 0 } },
				accel = { 0, 3, 0 },
				lightEmission = 1,
				brightness = 3,
			}),
			wave(
				"scorch",
				"ring_smoky",
				{ 70, 35, 25 },
				11,
				{ transparency = { { 0, 0.2 }, { 0.5, 0.35 }, { 1, 1 } } }
			),
			wave("glow", "ring_crisp", { 255, 150, 50 }, 8, { life = { 0.45, 0.45 }, lightEmission = 0.4 }),
		},
	},
	-- CALDEROS (lava boss)
	-- mane_lash: a sweeping crescent of flame at the target, a fire burst, flames licking up, embers, a scorched ring
	mane_lash = {
		pieces = {
			-- (raised and kept small: the pack's slash is soft at size, and the floor cut a big one in half)
			pop("slash", "fire_slash_flip", nil, 6, {
				role = "keep",
				offset = { 0, 2.5, 0 },
				life = { 0.5, 0.5 },
				rotation = { -25, 25 },
				flipbook = FOUR,
				zOffset = 3,
			}),
			pop("burst", "fire_burst_flip", nil, 4.5, {
				role = "keep",
				offset = { 0, 2, 0 },
				delay = 0.05,
				flipbook = FOUR,
			}),
			rise(
				"flames",
				"fire_curl_d_flip",
				nil,
				4,
				4.5,
				2.2,
				{ role = "keep", flipbook = FOUR, rotation = { -8, 8 } }
			),
			fling("embers", "embers_fly", { { 255, 210, 100 }, { 255, 110, 30 } }, 12, { 6, 13 }, {
				size = { { 0, 0.5 }, { 1, 0 } },
				accel = { 0, 3, 0 },
				lightEmission = 1,
				brightness = 3,
			}),
			wave(
				"scorch",
				"ring_smoky",
				{ 60, 35, 25 },
				13,
				{ transparency = { { 0, 0.2 }, { 0.5, 0.35 }, { 1, 1 } } }
			),
		},
	},
	-- meteor_rain: three fireballs falling from above onto the target, one after the other, each with an explosion,
	-- rock bits and a fire ring
	meteor_rain = {
		pieces = {
			{
				-- (born 16 studs up, stretched along their fall; gone as they reach the ground)
				name = "fireballs",
				texture = "fireball",
				role = "keep",
				at = "ground",
				offset = { 0, 16, 0 },
				shape = "Box",
				box = { 0.5, 0, 0.5 },
				orientation = "VelocityParallel",
				direction = "Bottom",
				bursts = { { 0, 1 }, { 0.25, 1 }, { 0.5, 1 } },
				life = { 0.34, 0.34 },
				size = { { 0, 2.6 }, { 1, 2.2 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				speed = { 26, 30 },
				spread = { 3, 3 },
				accel = { 0, -80, 0 },
				squash = { { 0, -0.5 }, { 1, -0.5 } },
				lightEmission = 0.3,
				zOffset = 2,
			},
			-- (each blast is two sheets of the sharp explosion, one after the other, high enough that the floor does not cut
			-- it)
			{
				name = "blasts",
				texture = "explosion_sharp_1",
				role = "keep",
				at = "ground",
				offset = { 0, 3, 0 },
				orientation = "FacingCameraWorldUp",
				bursts = { { 0.34, 1 }, { 0.59, 1 }, { 0.84, 1 } },
				life = { 0.16, 0.16 },
				size = { { 0, 1.5 }, { 1, 5 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				flipbook = SHARP,
				zOffset = 2,
			},
			{
				name = "blasts2",
				texture = "explosion_sharp_2",
				role = "keep",
				at = "ground",
				offset = { 0, 3, 0 },
				orientation = "FacingCameraWorldUp",
				bursts = { { 0.5, 1 }, { 0.75, 1 }, { 1, 1 } },
				life = { 0.22, 0.22 },
				size = { { 0, 5 }, { 1, 6 } },
				transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
				flipbook = SHARP,
				zOffset = 2,
			},
			fling("rocks", "rocks", nil, 0, { 9, 16 }, {
				role = "keep",
				at = "ground",
				count = false,
				bursts = { { 0.34, 4 }, { 0.59, 4 }, { 0.84, 4 } },
				spread = { 60, 60 },
				life = { 0.4, 0.7 },
				size = { { 0, 0.9 }, { 1, 0.27 } },
				accel = { 0, -30, 0 },
				flipbook = ROCKS,
			}),
			wave("ring", "ring_wave", { 255, 140, 50 }, 9, {
				count = false,
				bursts = { { 0.34, 1 }, { 0.59, 1 }, { 0.84, 1 } },
				life = { 0.4, 0.4 },
				size = { { 0, 2 }, { 1, 9 } },
				lightEmission = 0.3,
			}),
		},
	},
	-- RIMETUSK (ice mini-boss)
	-- frost_breath: a cloud of frost breath bursting over the target, ice crystals spraying, glitter, a frost ring
	frost_breath = {
		pieces = {
			-- (a solid puff tinted ice blue: the pack's frost cloud read as grey dust on a bright floor)
			fling("breath", "smoke_puff_solid_flip", FROST_CLOUD, 5, { 3, 7 }, {
				accel = { 0, 0, 0 },
				drag = 2,
				life = { 0.8, 1.1 },
				size = { { 0, 2 }, { 1, 6.5 } },
				transparency = { { 0, 0.4 }, { 0.15, 0.1 }, { 0.6, 0.4 }, { 1, 1 } },
				rotSpeed = { -30, 30 },
				flipbook = FOUR,
				lightEmission = 0.1,
			}),
			fling("crystals", "ice_shards_flip", ICE, 12, { 9, 16 }, {
				accel = { 0, -10, 0 },
				flipbook = FOUR,
				lightEmission = 0.1,
			}),
			fling("glitter", "snow_crystals_flip", SNOW, 8, { 3, 8 }, {
				accel = { 0, -3, 0 },
				flipbook = FLAKES,
				size = { { 0, 0.6 }, { 1, 0.3 } },
				lightEmission = 0.15,
			}),
			wave("ring", "ring_wave", FROST, 12),
		},
	},
	-- FROSTMAW (ice boss)
	-- glacier_gore: ice spikes erupting out of the ground under the target, crystal shards shattering, a snow burst
	glacier_gore = {
		pieces = {
			-- (ground spikes tinted ice: the pack's long pale shard, this tall, read as flat paper blades)
			rise(
				"spikes",
				"spikes_up",
				{ { 120, 195, 255 }, { 60, 135, 235 } },
				8,
				4.5,
				1.6,
				{ rotation = { -8, 8 }, lightEmission = 0.1 }
			),
			fling("shatter", "ice_shards_flip", ICE, 14, { 10, 18 }, {
				delay = 0.12,
				flipbook = FOUR,
				accel = { 0, -16, 0 },
				lightEmission = 0.1,
			}),
			fling("snow", "snow_crystals_flip", SNOW, 8, { 5, 10 }, {
				delay = 0.12,
				flipbook = FLAKES,
				accel = { 0, -4, 0 },
				lightEmission = 0.15,
			}),
			fling("puff", "smoke_puff_solid_flip", FROST_CLOUD, 3, { 2, 5 }, {
				delay = 0.1,
				accel = { 0, 0, 0 },
				size = { { 0, 2 }, { 1, 5.5 } },
				transparency = { { 0, 0.4 }, { 0.2, 0.15 }, { 1, 1 } },
				flipbook = FOUR,
				lightEmission = 0.1,
			}),
			wave("ring", "ring_cracked", FROST, 14),
		},
	},
	-- frost_gale: a gale: snow streaks sweeping sideways over the target area, flakes flying, curls of wind, a wide
	-- white swirl ring
	frost_gale = {
		pieces = {
			fling("streaks", "streak_horizontal", { 140, 200, 255 }, 14, { 26, 36 }, {
				at = "body",
				shape = "Box",
				box = { 1.5, 0.8, 0.5 },
				direction = "Front",
				orientation = "VelocityParallel",
				spread = { 5, 5 },
				accel = { 0, 0, 0 },
				drag = 0.5,
				life = { 0.3, 0.5 },
				size = { { 0, 1.4 }, { 1, 0.6 } },
				lightEmission = 0.15,
			}),
			fling("flakes", "snow_crystals_flip", SNOW, 12, { 14, 24 }, {
				direction = "Front",
				spread = { 25, 25 },
				accel = { 0, -2, 0 },
				flipbook = FLAKES,
				size = { { 0, 0.7 }, { 1, 0.4 } },
				lightEmission = 0.15,
			}),
			wave("swirl", "swirl_wind_ring", { 100, 170, 250 }, 15, { rotSpeed = { 150, 200 } }),
			fling("gust", "gust_curl", SNOW, 4, { 12, 18 }, {
				direction = "Front",
				spread = { 15, 15 },
				accel = { 0, 0, 0 },
				life = { 0.4, 0.6 },
				size = { { 0, 2 }, { 1, 5 } },
				transparency = { { 0, 0.5 }, { 0.3, 0.3 }, { 1, 1 } },
				rotSpeed = { 60, 120 },
			}),
		},
	},

	-- REGULARS (meadow)
	-- bloom_mend: Sapcaller's dandelion seeds puffing up, a soft gold-green ring, pollen
	bloom_mend = {
		pieces = {
			fling("seeds", "down_feather", { 250, 250, 240 }, 16, { 4, 9 }, {
				spread = { 60, 60 },
				accel = { 0, 2, 0 },
				drag = 1.4,
				life = { 0.8, 1.4 },
				size = { { 0, 0.4 }, { 0.2, 1.1 }, { 1, 0.7 } },
				rotSpeed = { -60, 60 },
				lightEmission = 0.15,
			}),
			wave("ring", "ring_soft", { 255, 215, 80 }, 9),
			pop("bloom", "glow_soft", { 255, 240, 170 }, 5, {
				life = { 0.5, 0.5 },
				transparency = { { 0, 0.5 }, { 0.2, 0.25 }, { 1, 1 } },
				lightEmission = 0.5,
			}),
			fling("pollen", "dot_round", { 255, 205, 60 }, 12, { 2, 6 }, {
				accel = { 0, 3, 0 },
				drag = 1.5,
				size = { { 0, 0.5 }, { 1, 0.15 } },
				lightEmission = 0.3,
			}),
		},
	},
	-- bark_wall: Barkhide's bark chips and leaves bursting round it, a brown ring, a short shield flash
	bark_wall = {
		pieces = {
			fling(
				"chips",
				"shard_flat",
				{ { 150, 100, 55 }, { 110, 75, 45 } },
				14,
				{ 8, 14 },
				{ spread = { 80, 80 }, accel = { 0, -18, 0 }, size = { { 0, 1.4 }, { 1, 0.5 } } }
			),
			fling("leaves", "leaves_solid", GREENS, 8, { 6, 10 }, { flipbook = LEAVES }),
			wave("ring", "ring_rough", { 125, 85, 45 }, 9),
			pop("flash", "glow_soft", { 225, 190, 120 }, 6, {
				life = { 0.3, 0.3 },
				transparency = { { 0, 0.5 }, { 0.2, 0.35 }, { 1, 1 } },
				lightEmission = 0.5,
			}),
		},
	},
	-- REGULARS (mushroom)
	-- acid_splash: Bilebloat's acid: the owner's splat and drops, lime bubbles popping, a lime ring
	acid_splash = {
		pieces = {
			wave("splat", "acidSplat", nil, 5, {
				role = "keep",
				life = { 0.9, 0.9 },
				size = { { 0, 2 }, { 0.15, 5 }, { 1, 5.4 } },
				transparency = { { 0, 0.05 }, { 0.6, 0.1 }, { 1, 1 } },
			}),
			fling("drops", "acidDrop", nil, 8, { 7, 13 }, {
				role = "keep",
				orientation = "FacingCameraWorldUp",
				rotation = { 0, 0 },
				rotSpeed = { 0, 0 },
				size = { { 0, 0.7 }, { 1, 0.45 } },
				accel = { 0, -16, 0 },
			}),
			fling("bubbles", "bubble_gloss", LIME, 6, { 2, 6 }, {
				accel = { 0, 3, 0 },
				life = { 0.5, 0.9 },
				size = { { 0, 0.2 }, { 0.5, 1 }, { 0.85, 1.2 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				lightEmission = 0.3,
			}),
			wave("ring", "ringAcid", nil, 9, { role = "keep", delay = 0.05 }),
		},
	},
	-- hex_mend: Hexcap's teal rune circle turning on the ground, glossy teal bubbles rising, motes
	hex_mend = {
		pieces = {
			wave(
				"rune",
				"rune_circle",
				{ 60, 235, 205 },
				10,
				{ life = { 1, 1 }, rotSpeed = { 90, 90 }, lightEmission = 0.4 }
			),
			fling("bubbles", "bubble_gloss", { 90, 240, 210 }, 10, { 2, 5 }, {
				at = "ground",
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.6,
				spread = { 25, 25 },
				accel = { 0, 2, 0 },
				drag = 0.5,
				life = { 0.8, 1.3 },
				size = { { 0, 0.2 }, { 0.4, 0.9 }, { 0.85, 1 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				lightEmission = 0.3,
			}),
			-- (dot_round, not mote_glow: mote_glow's dark square shows on a bright map)
			fling("motes", "dot_round", { 150, 255, 235 }, 8, { 1, 3 }, {
				spread = { 180, 180 },
				accel = { 0, 2, 0 },
				size = { { 0, 0 }, { 0.3, 0.45 }, { 1, 0 } },
				lightEmission = 0.4,
			}),
		},
	},
	-- rune_ward: Ruingut's green-teal rune ring flashing, stone chips, moss bits
	rune_ward = {
		pieces = {
			wave("ring", "rune_ring_outer", { 90, 230, 160 }, 9, { life = { 0.5, 0.5 }, lightEmission = 0.4 }),
			wave("ring2", "ring_double", { 70, 190, 150 }, 6, { delay = 0.06 }),
			fling("chips", "rocks", nil, 8, { 6, 11 }, {
				role = "keep",
				size = { { 0, 0.7 }, { 1, 0.25 } },
				flipbook = ROCKS,
			}),
			fling("moss", "leaves_solid", { 70, 130, 60 }, 6, { 4, 8 }, { flipbook = LEAVES }),
		},
	},
	-- REGULARS (lava)
	-- flare_pop: Wickling's small pop of fire, bits of fire, a few embers
	flare_pop = {
		pieces = {
			pop("pop", "fire_pop_flip", nil, 5, { role = "keep", flipbook = FOUR }),
			fling("bits", "fire_pop_small_flip", nil, 3, { 4, 8 }, {
				role = "keep",
				accel = { 0, 2, 0 },
				size = { { 0, 1.2 }, { 1, 0.5 } },
				flipbook = FOUR,
			}),
			fling("embers", "embers_fly", { { 255, 200, 90 }, { 255, 100, 25 } }, 8, { 4, 9 }, {
				size = { { 0, 0.4 }, { 1, 0 } },
				accel = { 0, 3, 0 },
				lightEmission = 1,
				brightness = 3,
			}),
		},
	},
	-- fireball: Blazegullet's explosion of fire, smoke puffs, a scorch ring, embers
	fireball = {
		pieces = {
			-- (the explosion's frames in three sheets played one after another, unturned so they line up; raised so the
			-- floor does not cut it)
			pop("ball", "explosion_sharp_1", nil, 6, {
				role = "keep",
				offset = { 0, 2, 0 },
				life = { 0.16, 0.16 },
				size = { { 0, 2 }, { 1, 6 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotation = { 0, 0 },
				flipbook = SHARP,
			}),
			pop("blast", "explosion_sharp_2", nil, 7, {
				role = "keep",
				offset = { 0, 2, 0 },
				delay = 0.16,
				life = { 0.2, 0.2 },
				size = { { 0, 6 }, { 1, 7 } },
				transparency = { { 0, 0 }, { 1, 0 } },
				rotation = { 0, 0 },
				flipbook = SHARP,
			}),
			pop("cool", "explosion_sharp_3", nil, 7, {
				role = "keep",
				offset = { 0, 2, 0 },
				delay = 0.36,
				life = { 0.3, 0.3 },
				size = { { 0, 7 }, { 1, 7.5 } },
				transparency = { { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } },
				rotation = { 0, 0 },
				flipbook = SHARP,
			}),
			pop("burst", "fire_burst_flip", nil, 4.5, {
				role = "keep",
				offset = { 0, 1.5, 0 },
				delay = 0.03,
				flipbook = FOUR,
			}),
			fling("smoke", "smoke_puff_solid_flip", { { 70, 60, 60 }, { 110, 95, 90 } }, 5, { 3, 7 }, {
				accel = { 0, 2, 0 },
				drag = 2,
				life = { 0.8, 1.2 },
				size = { { 0, 1.6 }, { 1, 4.5 } },
				transparency = { { 0, 0.3 }, { 0.2, 0.1 }, { 1, 1 } },
				flipbook = FOUR,
			}),
			wave(
				"scorch",
				"ring_smoky",
				{ 60, 40, 35 },
				11,
				{ transparency = { { 0, 0.2 }, { 0.5, 0.35 }, { 1, 1 } } }
			),
			fling("embers", "embers_fly", { { 255, 210, 100 }, { 255, 110, 30 } }, 10, { 6, 13 }, {
				size = { { 0, 0.5 }, { 1, 0 } },
				accel = { 0, 3, 0 },
				lightEmission = 1,
				brightness = 3,
			}),
		},
	},
	-- pyre_mend: Pyrekeeper's pale golden flame rising, sparks lifting, a warm ring
	pyre_mend = {
		pieces = {
			rise("flame", "fire_curl_c_flip", { 255, 235, 170 }, 3, 4, 0.8, { flipbook = FOUR }),
			fling("sparks", "spark_dot", { 255, 235, 170 }, 10, { 4, 9 }, {
				spread = { 40, 40 },
				accel = { 0, 5, 0 },
				drag = 1.5,
				size = { { 0, 0.3 }, { 1, 0.05 } },
				lightEmission = 0.8,
			}),
			wave("ring", "ring_soft", { 255, 215, 120 }, 8),
		},
	},
	-- basalt_wall: Basaltback's dark basalt chunks bursting up, a glowing crack ring, dust
	basalt_wall = {
		pieces = {
			fling("rocks", "rocks", { 110, 98, 98 }, 10, { 9, 16 }, {
				spread = { 55, 55 },
				accel = { 0, -22, 0 },
				size = { { 0, 1 }, { 1, 0.4 } },
				flipbook = ROCKS,
			}),
			wave("crack", "crack_glow", { 255, 120, 40 }, 9, { lightEmission = 0.5 }),
			wave("ring", "ring_cracked", { 255, 150, 60 }, 7, { delay = 0.05 }),
			fling("dust", "dust_kick_flip", { 90, 80, 75 }, 4, { 4, 8 }, {
				spread = { 180, 20 },
				accel = { 0, 0, 0 },
				drag = 2,
				size = { { 0, 1.4 }, { 1, 3.6 } },
				transparency = { { 0, 0.4 }, { 0.2, 0.15 }, { 1, 1 } },
				flipbook = FOUR,
			}),
		},
	},
	-- REGULARS (ice)
	-- crystal_burst: an ice wisp's crystal shards bursting, glitter, a frost ring
	crystal_burst = {
		pieces = {
			-- (a deeper blue and a little bigger than the other ice: pale and thin, the flung shards read as glass slivers)
			fling("shards", "shard_crystal", { { 100, 175, 255 }, { 55, 125, 235 } }, 12, { 10, 17 }, {
				size = { { 0, 1.6 }, { 1, 0.5 } },
				accel = { 0, -14, 0 },
				lightEmission = 0.1,
			}),
			fling("glitter", "star_glint_small", { 150, 205, 255 }, 10, { 4, 10 }, {
				spread = { 180, 180 },
				accel = { 0, -2, 0 },
				size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } },
				lightEmission = 0.4,
			}),
			fling("chips", "ice_shards_flip", ICE, 8, { 8, 14 }, {
				flipbook = FOUR,
				accel = { 0, -16, 0 },
				size = { { 0, 1.5 }, { 1, 0.5 } },
				lightEmission = 0.1,
			}),
			wave("ring", "ring_wave", FROST, 9),
		},
	},
	-- frost_mend: Penguin's ring of ice crescents turning on the ground, sparkles and snow crystals rising
	frost_mend = {
		pieces = {
			-- (a solid ring of ice crescents: the snowflake floor circle is black-backed, added, and vanished on the Ice
			-- map's white floor, and the soft spiky ring was too faint to see there)
			wave(
				"frost",
				"ring_crescents",
				{ 80, 160, 250 },
				11,
				{ life = { 1, 1 }, rotSpeed = { 40, 40 }, lightEmission = 0.15 }
			),
			fling("sparkles", "star_twinkle", { 100, 175, 255 }, 12, { 2, 5 }, {
				accel = { 0, 4, 0 },
				drag = 1,
				size = { { 0, 0 }, { 0.3, 0.9 }, { 1, 0 } },
				lightEmission = 0.3,
			}),
			fling("flakes", "snow_crystals_flip", { 110, 180, 255 }, 10, { 2, 4 }, {
				at = "ground",
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.8,
				spread = { 25, 25 },
				accel = { 0, 2, 0 },
				drag = 0.6,
				life = { 0.8, 1.3 },
				flipbook = FLAKES,
				size = { { 0, 0.3 }, { 0.3, 0.9 }, { 1, 0.5 } },
				lightEmission = 0.1,
			}),
		},
	},
	-- ice_wall: the golem's ice crystal shards rising round it, a frost ring, mist
	ice_wall = {
		pieces = {
			rise(
				"shards",
				"spikes_cluster",
				{ { 130, 200, 255 }, { 70, 145, 240 } },
				8,
				3.2,
				2.2,
				{ lightEmission = 0.1 }
			),
			wave("ring", "ring_wave", FROST, 9),
			fling("mist", "smoke_puff_solid_flip", FROST_CLOUD, 3, { 1, 3 }, {
				at = "ground",
				accel = { 0, 0, 0 },
				size = { { 0, 1.5 }, { 1, 4 } },
				transparency = { { 0, 0.4 }, { 0.2, 0.2 }, { 1, 1 } },
				flipbook = FOUR,
				lightEmission = 0.1,
			}),
		},
	},
}

return {
	id = "skill.monster_special",
	name = "Monster Special",
	kind = "skill",
	tier = "mid",
	host = "any",
	refHeight = 5,
	tags = {
		"dungeon",
		"monster",
		"skill",
		"special",
		"per_creature",
		"green",
		"purple",
		"fire",
		"ice",
		"heal",
		"guard",
	},
	blend = "normal",
	palette = {},
	tintable = false,
	markers = { impact = 0.1, peak = 0.3 },
	pieces = variants.root_snare.pieces,
	variants = variants,
	defaultVariant = "root_snare",
	source = {
		from = "Goo Lineage V2 (2026-11-12): the dungeon monsters' specials",
		art = "the library's pictures (ASSETS.md families), owner art kept as drawn (acidSplat, acidDrop, ringAcid, burstAcid, spore)",
		licence = "the owner's own and free Creator Store pictures already in the library",
	},
	notes = "Play at the caster's centre (guards, mends, bursts) or at the target's spot (opts.from = the caster), opts.variant = the special's key (Config.Dungeon.Fx.Monsters[id].skills[key].variant); scale by the monster's size. A boss's special has skill.monster_windup of the same variant as its wind-up. The special's blows land as the monster's own hit effect on top.",
}
