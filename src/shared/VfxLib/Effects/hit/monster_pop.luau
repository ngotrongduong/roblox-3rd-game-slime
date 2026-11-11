-- Monster Pop: the small burst a regular dungeon monster's special lands with, on top of its own blow (Goo Lineage V2,
-- 2026-11-12, the owner: fights as dramatic as Genshin Impact's, still no camera), one variant per map, each with its own
-- pictures. The bosses' skill.monster_impact cut down for a moment that comes often: a hit pop for a few frames, a quick
-- ring over the ground and a spray of the map's element, all gone in under a second; nothing stays on the ground (the
-- bosses keep that). Numbers are studs on a 5-stud box, played at the middle of the body it strikes, standing on the
-- floor (opts.size).
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
local FLUTTER = { layout = "Grid4x4", mode = "Loop", fps = { 10, 12 }, random = true }

-- The hit pop: one picture at the heart of the blow, raised so the floor does not cut it, played through its frames.
local function pop(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		offset = { 0, 0.8, 0 },
		count = 1,
		life = { 0.3, 0.3 },
		size = { { 0, size * 0.6 }, { 0.2, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		rotation = { 0, 359 },
		flipbook = FOUR,
		lightEmission = 0.3,
		zOffset = 2,
	}, over)
end

-- A quick ring over the ground, eased out.
local function ring(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, 0.12, 0 },
		flat = true,
		count = 1,
		life = { 0.3, 0.3 },
		size = { { 0, width * 0.2 }, { 0.3, width * 0.8 }, { 1, width } },
		transparency = { { 0, 0 }, { 0.4, 0.2 }, { 1, 1 } },
		zOffset = 0.7,
	}, over)
end

-- Bits of the element flung out of the blow and falling.
local function spray(name, texture, color, count, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.5, 0.8 },
		size = { { 0, 0.6 }, { 1, 0.3 } },
		transparency = { { 0, 0 }, { 0.75, 0.1 }, { 1, 1 } },
		speed = { 6, 10 },
		spread = { 70, 70 },
		accel = { 0, -8, 0 },
		drag = 1.5,
		rotation = { 0, 359 },
		rotSpeed = { -200, 200 },
		zOffset = 1,
	}, over)
end

local variants = {
	-- the Meadow: a warm gold hit pop, a fringed gold ring, pink and white petals fluttering out
	meadow = {
		pieces = {
			pop("pop", "hit_pop_flip", { 255, 230, 120 }, 5, { lightEmission = 0.4 }),
			ring("ring", "ring_fringed_b", { 255, 205, 60 }, 7, { lightEmission = 0.3 }),
			spray("petals", "petals_small_flip", { { 255, 160, 200 }, { 255, 240, 245 } }, 7, {
				speed = { 5, 8 },
				accel = { 0, -4, 0 },
				flipbook = FLUTTER,
			}),
		},
	},
	-- the Mushroom Grove: a violet toxic splat, a lime bubble ring, the owner's spores puffed out
	grove = {
		pieces = {
			pop("splat", "impact_splat", { 200, 140, 255 }, 5, { flipbook = false, life = { 0.22, 0.22 } }),
			ring("ring", "ring_bubble", { 150, 240, 110 }, 7, { lightEmission = 0.3 }),
			spray(
				"spores",
				"spore",
				nil,
				6,
				{ role = "keep", speed = { 4, 7 }, accel = { 0, -2, 0 }, rotSpeed = false }
			),
		},
	},
	-- Ember Lava: an orange hit pop, a ring bursting into flecks of fire, embers thrown up and out
	lava = {
		pieces = {
			pop("pop", "hit_pop_b_flip", { 255, 170, 70 }, 5, { lightEmission = 0.6 }),
			ring("ring", "ring_burst_b_flip", { 255, 120, 40 }, 7, { flipbook = FOUR, lightEmission = 0.6 }),
			spray("embers", "embers_fly", { { 255, 210, 100 }, { 255, 110, 30 } }, 9, {
				size = { { 0, 0.45 }, { 1, 0 } },
				accel = { 0, 2, 0 },
				lightEmission = 1,
				brightness = 3,
				rotSpeed = false,
			}),
		},
	},
	-- Frozen Ice: a deep blue splat, a thin cracked ring, small crystal shards flung out (pale ice vanishes on the
	-- near-white floor)
	ice = {
		pieces = {
			-- (a bigger, deeper splat and ring than the other maps': at 5 and 7 they vanished into the white floor)
			pop(
				"splat",
				"impact_pale",
				{ 55, 115, 235 },
				6.5,
				{ flipbook = false, life = { 0.26, 0.26 }, lightEmission = 0 }
			),
			ring("ring", "ring_cracked", { 35, 100, 225 }, 8.5, { lightEmission = 0 }),
			spray("shards", "shard_crystal", { 80, 150, 250 }, 8, {
				size = { { 0, 1.1 }, { 1, 0.6 } },
				speed = { 4, 7 },
				lightEmission = 0,
			}),
		},
	},
}

return {
	id = "hit.monster_pop",
	name = "Monster Pop",
	kind = "hit",
	tier = "cheap",
	host = "any",
	refHeight = 5,
	tags = { "dungeon", "monster", "impact", "pop", "ground", "green", "purple", "fire", "ice" },
	blend = "normal",
	palette = {},
	tintable = false,
	markers = { impact = 0 },
	pieces = variants.meadow.pieces,
	variants = variants,
	defaultVariant = "meadow",
	source = {
		from = "Goo Lineage V2 (2026-11-12): the dungeon's regular monsters' specials",
		art = "the library's pictures (ASSETS.md families), owner art kept as drawn (spore)",
		licence = "the owner's own and free Creator Store pictures already in the library",
	},
	notes = "Play at the middle of the body a regular monster's special strikes, on top of its blow (opts.variant = the map: meadow, grove, lava, ice; opts.size = the box standing on the floor there). Under a second, nothing left on the ground.",
}
