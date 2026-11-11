-- Monster Windup: what the dungeon's bosses and mini-bosses do for about 1.2 s before a special goes off (Goo Lineage V2,
-- 2026-11-12), one variant each. The game plays it on the monster with `follow` and cancels it softly as the release
-- (skill.monster_special, the same variant) comes down. Every one is built the way the other charges are: streams that
-- speed up (ease "in"), things drawn in, a ring closing on the ground, a light swelling; but each has its own pictures,
-- motion and colour. Numbers are studs on a 5-stud host (the game scales them). Solid pictures first (smoke, leaves,
-- droplets, shards); the added glows are small accents so they still read on the bright maps. (`embers_fly` is
-- dark-backed: worn fully added, lightEmission 1, or its grey square shows on a bright map.)
-- (a field given as `false` is taken out of the base)
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
local EIGHT = { layout = "Grid8x8", mode = "OneShot" }
local LEAVES = { layout = "Grid2x2", mode = "Random" }
local FLAKES = { layout = "Grid4x4", mode = "Loop", fps = { 1, 2 }, random = true }

-- Things drawn in to the middle of the host from a ball round it, faster and faster.
local function pulled(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		shape = "Sphere",
		shapeStyle = "Surface",
		shapeInOut = "Inward",
		radius = 3,
		life = { 0.4, 0.5 },
		size = { { 0, 0.9 }, { 0.5, 0.6 }, { 1, 0.15 } },
		transparency = { { 0, 0.3 }, { 0.3, 0 }, { 1, 0.1 } },
		speed = { 6, 7 },
		stream = { from = 0.1, to = 1.15, rate = { 10, 30 }, ease = "in" },
	}, over)
end

-- Things lifting off the ground round the host.
local function rising(name, texture, color, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		shape = "Disc",
		shapeStyle = "Surface",
		radius = 2.8,
		direction = "Top",
		life = { 0.5, 0.7 },
		size = { { 0, 0.6 }, { 0.4, 1.3 }, { 1, 0.5 } },
		transparency = { { 0, 0.4 }, { 0.2, 0 }, { 0.8, 0.1 }, { 1, 1 } },
		speed = { 2, 4 },
		stream = { from = 0.05, to = 1.15, rate = { 8, 26 }, ease = "in" },
	}, over)
end

-- A ring on the ground closing in on the host, three times (a hair over the floor and drawn toward the camera: on the
-- floor itself the floor hid it).
local function closing(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, 0.1, 0 },
		flat = true,
		life = { 0.55, 0.55 },
		size = { { 0, width }, { 0.7, width * 0.35 }, { 1, width * 0.2 } },
		transparency = { { 0, 0.5 }, { 0.2, 0 }, { 0.8, 0.15 }, { 1, 1 } },
		zOffset = 0.5,
		bursts = { { 0.1, 1 }, { 0.5, 1 }, { 0.9, 1 } },
	}, over)
end

-- A soft light swelling on the host (a small accent, held by the host).
local function swell(name, color, size, over)
	return with({
		name = name,
		texture = "glow_soft",
		color = color,
		at = "body",
		locked = true,
		count = 1,
		life = { 1.3, 1.3 },
		size = { { 0, size * 0.25 }, { 0.8, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0.95 }, { 0.8, 0.45 }, { 1, 0.4 } },
		lightEmission = 0.6,
		zOffset = 0.5,
	}, over)
end

local function light(color, range)
	return { color = color, range = range, keys = { { 0, 0 }, { 1, 2 }, { 1.4, 0 } } }
end

local variants = {
	-- ROTBLOOM (meadow mini-boss)
	-- root_snare: roots and leaves curling up off the ground round it, earth specks pulled in, a green ring closing
	root_snare = {
		pieces = {
			rising("roots", "spikes_up", { { 135, 95, 50 }, { 105, 75, 45 } }, {
				radius = 3,
				orientation = "FacingCameraWorldUp",
				speed = { 1.5, 3 },
				size = { { 0, 0.6 }, { 0.4, 2.8 }, { 1, 2 } },
				transparency = { { 0, 0.5 }, { 0.2, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				rotation = { -15, 15 },
				rotSpeed = { -30, 30 },
				stream = { from = 0.05, to = 1.15, rate = { 8, 20 }, ease = "in" },
			}),
			rising("leaves", "leaves_solid", { { 185, 215, 70 }, { 235, 205, 80 } }, {
				radius = 2.8,
				speed = { 2, 3.5 },
				accel = { 0, 1, 0 },
				size = { { 0, 0.6 }, { 0.4, 1.2 }, { 1, 0.5 } },
				rotation = { 0, 359 },
				rotSpeed = { -120, 120 },
				flipbook = LEAVES,
				stream = { from = 0.1, to = 1.15, rate = { 6, 16 }, ease = "in" },
			}),
			pulled("specks", "dust_specks_flip", { 90, 62, 38 }, {
				at = "ground",
				radius = 3.4,
				speed = { 4, 5 },
				size = { { 0, 0.8 }, { 1, 0.2 } },
				flipbook = FOUR,
				stream = { from = 0.1, to = 1.15, rate = { 8, 22 }, ease = "in" },
			}),
			closing("ring", "ring_wave", { 125, 88, 45 }, 9),
		},
	},
	-- BRAMBLEHORN (meadow boss)
	-- bramble_burst: bramble thorns pushing up round it, autumn leaves and red berries sucked in, a thorned ring closing,
	-- a warm light swelling
	bramble_burst = {
		light = light({ 255, 190, 90 }, 10),
		pieces = {
			rising("thorns", "spikes_cluster", { { 125, 150, 55 }, { 150, 110, 55 } }, {
				radius = 3.2,
				orientation = "FacingCameraWorldUp",
				speed = { 1, 2 },
				size = { { 0, 0.5 }, { 0.4, 2.4 }, { 1, 1.8 } },
				transparency = { { 0, 0.5 }, { 0.2, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				rotation = { -12, 12 },
				stream = { from = 0.05, to = 1.15, rate = { 6, 18 }, ease = "in" },
			}),
			pulled("leaves", "leaves_solid", { { 150, 200, 60 }, { 225, 130, 50 } }, {
				size = { { 0, 1.2 }, { 0.5, 0.9 }, { 1, 0.3 } },
				rotation = { 0, 359 },
				rotSpeed = { -200, 200 },
				flipbook = LEAVES,
				stream = { from = 0.1, to = 1.15, rate = { 6, 18 }, ease = "in" },
			}),
			pulled("berries", "dot_solid", { 210, 40, 45 }, {
				size = { { 0, 0.6 }, { 1, 0.3 } },
				stream = { from = 0.15, to = 1.15, rate = { 4, 12 }, ease = "in" },
			}),
			closing("ring", "ring_thorned", { 175, 130, 55 }, 9.5),
			swell("warm", { 255, 200, 100 }, 3.4),
		},
	},
	-- horn_toss: hooves pawing: dust puffing up round its feet, clods of earth kicked up, a ring of dust closing
	horn_toss = {
		pieces = {
			rising("dust", "dust_kick_flip", { 205, 180, 140 }, {
				radius = 3,
				speed = { 2, 4 },
				spread = { 40, 40 },
				size = { { 0, 1.2 }, { 1, 3 } },
				transparency = { { 0, 0.5 }, { 0.15, 0.2 }, { 1, 1 } },
				rotation = { 0, 359 },
				flipbook = FOUR,
				stream = { from = 0.05, to = 1.15, rate = { 6, 20 }, ease = "in" },
			}),
			rising("clods", "rocks", nil, {
				role = "keep",
				radius = 3,
				speed = { 5, 9 },
				spread = { 35, 35 },
				accel = { 0, -18, 0 },
				size = { { 0, 0.7 }, { 1, 0.45 } },
				rotation = { 0, 359 },
				rotSpeed = { -150, 150 },
				flipbook = { layout = "Grid2x2", mode = "PingPong", fps = { 0, 0 }, random = true },
				stream = { from = 0.1, to = 1.15, rate = { 6, 18 }, ease = "in" },
			}),
			closing("ring", "ring_rough", { 215, 190, 150 }, 9, {
				transparency = { { 0, 0.6 }, { 0.2, 0.25 }, { 0.8, 0.35 }, { 1, 1 } },
			}),
		},
	},
	-- SPOREGORGE (mushroom mini-boss)
	-- gorge_bite: lime drool falling, lime fumes pulled into its maw, its glow pulsing lime
	gorge_bite = {
		pieces = {
			rising("drool", "acidDrop", nil, {
				role = "keep",
				at = "front",
				shape = "Box",
				radius = false,
				box = { 0.5, 0.2, 0.1 },
				direction = "Bottom",
				orientation = "FacingCameraWorldUp",
				speed = { 0, 0.3 },
				accel = { 0, -9, 0 },
				life = { 0.5, 0.7 },
				size = { { 0, 0.2 }, { 0.2, 1 }, { 1, 0.8 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				stream = { from = 0.05, to = 1.15, rate = { 6, 18 }, ease = "in" },
			}),
			pulled("fumes", "smoke_wisp_flip", { { 200, 255, 60 }, { 150, 230, 40 } }, {
				radius = 3.4,
				size = { { 0, 2.4 }, { 1, 0.9 } },
				transparency = { { 0, 0.8 }, { 0.2, 0 }, { 1, 0.5 } },
				flipbook = FOUR,
				lightEmission = 0.3,
				stream = { from = 0.1, to = 1.15, rate = { 8, 20 }, ease = "in" },
			}),
			swell("pulse", { 200, 255, 60 }, 3.4, {
				life = { 0.4, 0.4 },
				size = { { 0, 1.5 }, { 0.4, 3.4 }, { 1, 2.4 } },
				transparency = { { 0, 0.8 }, { 0.3, 0.4 }, { 1, 1 } },
				count = false,
				bursts = { { 0.05, 1 }, { 0.45, 1 }, { 0.8, 1 }, { 1.05, 1 } },
			}),
		},
	},
	-- HOLLOWHEART (mushroom boss)
	-- root_grasp: dark purple smoke and teal motes drawn in low along the ground, a teal ring closing
	root_grasp = {
		pieces = {
			pulled("smoke", "smoke_floor_flip", { { 70, 35, 110 }, { 110, 60, 150 } }, {
				at = "ground",
				radius = 3.2,
				speed = { 3, 4 },
				life = { 0.6, 0.8 },
				size = { { 0, 2.4 }, { 1, 0.9 } },
				transparency = { { 0, 1 }, { 0.2, 0.1 }, { 0.8, 0.3 }, { 1, 1 } },
				flipbook = FOUR,
				rotation = { 0, 359 },
				stream = { from = 0.05, to = 1.15, rate = { 8, 22 }, ease = "in" },
			}),
			-- (dot_round, not mote_glow: mote_glow's dark square shows on a bright map)
			pulled("motes", "dot_round", { 70, 240, 215 }, {
				at = "ground",
				radius = 3,
				speed = { 4, 5 },
				size = { { 0, 0.5 }, { 0.5, 0.4 }, { 1, 0.1 } },
				lightEmission = 0.4,
				stream = { from = 0.1, to = 1.15, rate = { 6, 20 }, ease = "in" },
			}),
			closing("ring", "ring_double", { 60, 230, 200 }, 10),
		},
	},
	-- heart_pulse: its heart beating faster and faster: a teal glow and a thump ring at the chest on a quickening beat,
	-- a beat ring racing out on the ground with each thump, teal motes drawn in
	heart_pulse = {
		light = light({ 80, 240, 215 }, 10),
		pieces = {
			-- (the glow alone was lost in its own teal chest on a bright map: the ground ring carries the beat; born as
			-- wide as the boss and fading only at the end: born smaller, it was under its body until it had faded)
			closing("beat", "ring_wave", { 60, 225, 200 }, 16, {
				life = { 0.45, 0.45 },
				size = { { 0, 8.5 }, { 1, 16 } },
				transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } },
				lightEmission = 0.5,
				bursts = { { 0.05, 1 }, { 0.5, 1 }, { 0.8, 1 }, { 0.97, 1 }, { 1.1, 1 } },
			}),
			swell("heart", { 80, 240, 215 }, 3.4, {
				at = "chest",
				life = { 0.35, 0.35 },
				size = { { 0, 1.2 }, { 0.3, 3.4 }, { 1, 1.6 } },
				transparency = { { 0, 0.7 }, { 0.25, 0.25 }, { 1, 1 } },
				lightEmission = 0.7,
				count = false,
				bursts = { { 0.05, 1 }, { 0.5, 1 }, { 0.8, 1 }, { 0.97, 1 }, { 1.1, 1 } },
			}),
			swell("thump", { 150, 255, 235 }, 4.5, {
				texture = "ring_wave",
				at = "chest",
				life = { 0.4, 0.4 },
				size = { { 0, 1 }, { 1, 4.5 } },
				transparency = { { 0, 0.3 }, { 1, 1 } },
				lightEmission = 0.3,
				secondary = true,
				count = false,
				bursts = { { 0.05, 1 }, { 0.5, 1 }, { 0.8, 1 }, { 0.97, 1 }, { 1.1, 1 } },
			}),
			pulled("motes", "dot_round", { 110, 245, 225 }, {
				at = "chest",
				radius = 2.6,
				size = { { 0, 0.5 }, { 0.5, 0.4 }, { 1, 0.1 } },
				lightEmission = 0.4,
				stream = { from = 0.1, to = 1.15, rate = { 6, 20 }, ease = "in" },
			}),
		},
	},
	-- MAGMAW (lava mini-boss)
	-- molten_chomp: lava bubbling in its maw: embers rising fast, molten drops, small fire pops, orange light swelling
	molten_chomp = {
		light = light({ 255, 140, 50 }, 10),
		pieces = {
			rising("embers", "embers_fly", { { 255, 170, 50 }, { 255, 90, 20 } }, {
				at = "head",
				shape = "Box",
				radius = false,
				box = { 0.5, 0, 0.3 },
				speed = { 5, 9 },
				accel = { 0, 2, 0 },
				life = { 0.4, 0.6 },
				size = { { 0, 0 }, { 0.2, 0.5 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0.3 } },
				lightEmission = 1,
				brightness = 3,
				stream = { from = 0.05, to = 1.15, rate = { 10, 34 }, ease = "in" },
			}),
			rising("drops", "droplet_gloss", { { 255, 225, 110 }, { 255, 140, 35 }, { 230, 70, 20 } }, {
				at = "head",
				shape = "Box",
				radius = false,
				box = { 0.5, 0, 0.3 },
				orientation = "FacingCameraWorldUp",
				speed = { 2, 4 },
				accel = { 0, -14, 0 },
				size = { { 0, 0.3 }, { 0.2, 0.6 }, { 1, 0.45 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				lightEmission = 0.4,
				stream = { from = 0.1, to = 1.15, rate = { 6, 18 }, ease = "in" },
			}),
			{
				name = "bubbles",
				texture = "fire_pop_small_flip",
				role = "keep",
				at = "head",
				orientation = "FacingCameraWorldUp",
				life = { 0.35, 0.35 },
				size = { { 0, 1.6 }, { 1, 2.4 } },
				transparency = { { 0, 0.2 }, { 0.7, 0.3 }, { 1, 1 } },
				flipbook = FOUR,
				lightEmission = 0.3,
				bursts = { { 0.2, 1 }, { 0.5, 1 }, { 0.75, 1 }, { 0.95, 1 }, { 1.1, 1 } },
			},
			swell("glow", { 255, 140, 50 }, 3.4, { at = "head" }),
		},
	},
	-- CALDEROS (lava boss)
	-- mane_lash: its mane flaring: tall flames round it, embers pulled up, orange light swelling
	mane_lash = {
		light = light({ 255, 140, 50 }, 12),
		pieces = {
			rising("mane", "flame_beautiful_flip", nil, {
				role = "keep",
				radius = 1.8,
				orientation = "FacingCameraWorldUp",
				speed = { 2, 4 },
				accel = { 0, 4, 0 },
				size = { { 0, 2 }, { 0.4, 3.8 }, { 1, 2 } },
				transparency = { { 0, 0.5 }, { 0.12, 0 }, { 0.7, 0.2 }, { 1, 1 } },
				rotation = { -10, 10 },
				flipbook = EIGHT,
				lightEmission = 0.3,
				brightness = 1.2,
				stream = { from = 0.05, to = 1.15, rate = { 8, 26 }, ease = "in" },
			}),
			rising("embers", "embers_fly", { { 255, 210, 100 }, { 255, 110, 30 } }, {
				radius = 2.5,
				speed = { 5, 8 },
				accel = { 0, 6, 0 },
				life = { 0.5, 0.8 },
				size = { { 0, 0 }, { 0.2, 0.45 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0.3 } },
				rotation = { -180, 180 },
				lightEmission = 1,
				brightness = 3,
				stream = { from = 0.1, to = 1.15, rate = { 6, 18 }, ease = "in" },
			}),
			swell("glow", { 255, 140, 50 }, 4),
		},
	},
	-- meteor_rain: embers and fire streaming UP from it to a point high over its head, a red glow growing there
	meteor_rain = {
		light = light({ 255, 90, 50 }, 12),
		pieces = {
			rising("fire", "fire_curl_flip", nil, {
				role = "keep",
				at = "body",
				shape = "Sphere",
				radius = 0.8,
				orientation = "FacingCameraWorldUp",
				speed = { 13, 17 },
				spread = { 6, 6 },
				life = { 0.5, 0.6 },
				size = { { 0, 1.4 }, { 0.4, 1.8 }, { 1, 0.5 } },
				transparency = { { 0, 0.3 }, { 0.2, 0 }, { 1, 1 } },
				flipbook = FOUR,
				lightEmission = 0.3,
				stream = { from = 0.05, to = 1.15, rate = { 8, 26 }, ease = "in" },
			}),
			rising("embers", "embers_fly", { { 255, 220, 120 }, { 255, 120, 30 } }, {
				at = "body",
				shape = "Sphere",
				radius = 1,
				speed = { 12, 16 },
				spread = { 10, 10 },
				life = { 0.45, 0.6 },
				size = { { 0, 0 }, { 0.2, 0.4 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0.3 } },
				lightEmission = 1,
				brightness = 3,
				stream = { from = 0.1, to = 1.15, rate = { 10, 30 }, ease = "in" },
			}),
			swell("sky", { 255, 70, 40 }, 5, { offset = { 0, 7.5, 0 }, lightEmission = 0.7 }),
		},
	},
	-- RIMETUSK (ice mini-boss)
	-- frost_breath: icy mist sucked into its mouth, frost crystals pulled in, a cold blue light
	-- (no light: on the Ice map's near-white floor it only burnt the floor round it to white and hid the mist)
	frost_breath = {
		pieces = {
			-- (a deep ice blue with little light of its own, never near-white: the pack's grey frost cloud and pale shards
			-- were lost on a bright floor, and the Ice map's floor is near-white; drawn into its MOUTH from in front of it:
			-- round its head they lay over its own ice-blue body and could not be seen)
			pulled("mist", "smoke_puff_solid_flip", { { 150, 200, 255 }, { 95, 160, 245 } }, {
				at = "front",
				radius = 4,
				size = { { 0, 2.2 }, { 1, 0.6 } },
				transparency = { { 0, 0.6 }, { 0.2, 0.1 }, { 1, 0.4 } },
				rotation = { 0, 359 },
				flipbook = FOUR,
				lightEmission = 0.1,
				stream = { from = 0.05, to = 1.15, rate = { 10, 26 }, ease = "in" },
			}),
			pulled("crystals", "ice_shards_flip", { { 95, 170, 245 }, { 55, 125, 230 } }, {
				at = "front",
				radius = 3.8,
				size = { { 0, 1.4 }, { 1, 0.3 } },
				flipbook = FOUR,
				lightEmission = 0.15,
				stream = { from = 0.1, to = 1.15, rate = { 8, 20 }, ease = "in" },
			}),
			closing("frost", "ring_wave", { 60, 140, 240 }, 9),
			swell("glow", { 90, 160, 250 }, 4, { at = "front", lightEmission = 0.3 }),
		},
	},
	-- FROSTMAW (ice boss)
	-- glacier_gore: ice shards forming round it, a frost ring spreading over the ground, blue light
	glacier_gore = {
		light = light({ 120, 180, 255 }, 12),
		pieces = {
			-- (shards tinted ice blue, standing up out of the floor round the boss's feet: pale and close in they were lost,
			-- at its middle they rose over its head, at 1.6 the tall shard read as paper blades and spun at 0.9 they were
			-- specks. Frostmaw plays at scale 2.2 and is about 17 studs wide, so 8 of these units: at 7.5 they stood 16
			-- studs out, behind the camera and far behind the boss)
			rising("shards", "shard_crystal", { { 110, 185, 255 }, { 60, 135, 240 } }, {
				radius = 4.4,
				speed = { 0.4, 1.2 },
				spread = { 10, 10 },
				life = { 0.6, 0.9 },
				size = { { 0, 0 }, { 0.3, 1.8 }, { 0.8, 1.8 }, { 1, 0 } },
				transparency = { { 0, 0.2 }, { 0.2, 0 }, { 0.8, 0 }, { 1, 1 } },
				rotation = { -20, 20 },
				lightEmission = 0.1,
				stream = { from = 0.05, to = 1.15, rate = { 10, 24 }, ease = "in" },
			}),
			-- (born wider than the boss: at 9 to 15 it lay under its body all its life. A ring is a burst, and the bursts'
			-- area cap halves them on a boss this big: these sizes play at about 1.05, not 2.2)
			closing("frost", "ring_cracked", { 70, 150, 245 }, 19, {
				size = { { 0, 14 }, { 0.6, 18 }, { 1, 19 } },
				transparency = { { 0, 0.3 }, { 0.3, 0.1 }, { 1, 1 } },
				lightEmission = 0.1,
			}),
			swell("glow", { 120, 180, 255 }, 4),
		},
	},
	-- frost_gale: a snow whirl round it speeding up: flakes pouring up faster and faster, a spinning ring, curls of wind
	frost_gale = {
		pieces = {
			-- (all of it outside the boss's body and ice blue: close in and near-white, the body and the floor hid it.
			-- Frostmaw is about 17 studs wide; the flakes play at scale 2.2 and the whirl, a burst halved by the bursts'
			-- area cap, at about 1.43: the flakes rise at 6.5 and the whirl starts at 13)
			rising("flakes", "snow_crystals_flip", { 150, 205, 255 }, {
				radius = 6.5,
				spread = { 20, 20 },
				life = { 0.6, 0.9 },
				size = { { 0, 0.7 }, { 1, 0.4 } },
				rotation = { 0, 359 },
				rotSpeed = { -200, 200 },
				flipbook = FLAKES,
				lightEmission = 0.1,
				stream = { from = 0.05, to = 1.15, rate = { 4, 36 }, ease = "in" },
			}),
			closing("whirl", "swirl_wind_ring", { 100, 170, 250 }, 18, {
				life = { 0.5, 0.5 },
				size = { { 0, 13 }, { 1, 18 } },
				transparency = { { 0, 0.3 }, { 0.3, 0.1 }, { 1, 1 } },
				rotSpeed = { 160, 220 },
				bursts = { { 0.05, 1 }, { 0.45, 1 }, { 0.8, 1 } },
			}),
			rising("gusts", "gust_curl", { 150, 205, 255 }, {
				at = "body",
				radius = 3.4,
				shape = "Sphere",
				speed = { 1, 2 },
				life = { 0.5, 0.7 },
				size = { { 0, 1.2 }, { 1, 2.2 } },
				transparency = { { 0, 0.8 }, { 0.3, 0.4 }, { 1, 1 } },
				rotation = { 0, 359 },
				rotSpeed = { 120, 240 },
				secondary = true,
				stream = { from = 0.1, to = 1.15, rate = { 3, 14 }, ease = "in" },
			}),
		},
	},
}

return {
	id = "skill.monster_windup",
	name = "Monster Windup",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = {
		"dungeon",
		"monster",
		"boss",
		"charge",
		"windup",
		"skill",
		"per_creature",
		"green",
		"purple",
		"fire",
		"ice",
	},
	blend = "normal",
	palette = {},
	tintable = false,
	follow = true,
	markers = { full = 1.2, peak = 1 },
	pieces = variants.root_snare.pieces,
	variants = variants,
	defaultVariant = "root_snare",
	source = {
		from = "Goo Lineage V2 (2026-11-12): the dungeon monsters' specials",
		art = "the library's pictures (ASSETS.md families), owner art kept as drawn (acidDrop)",
		licence = "the owner's own and free Creator Store pictures already in the library",
	},
	notes = "The wind-up of a boss's or mini-boss's special, played on the monster with follow = true, opts.variant = the special's key (Config.Dungeon.Fx.Monsters[id].skills[key].variant); cancelled softly as skill.monster_special of the same variant comes down. Holds about 1.2 s.",
}
