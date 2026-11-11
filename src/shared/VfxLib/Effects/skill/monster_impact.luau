-- Monster Impact: the burst a dungeon boss's or mini-boss's special lands with, on top of its own release (Goo Lineage
-- V2, 2026-11-12, the owner: fights as dramatic as Genshin Impact's, still no camera), one variant per map, each with
-- its own pictures. Three beats, as a big hit in an action game is timed: a flash at the heart of the blow for a few
-- frames (the "impact frame", out of the body and in front of it), a crisp shock ring racing over the ground faster than
-- the release's own, then the ground stays marked by the map's element for about two seconds and fades (flowers
-- opening, a fuming pool, glowing cracks, frozen ground). Numbers are studs on a 5-stud box, played where the release
-- plays (twice as wide round the caster for a special that bursts there). Spreads stay narrow (radius under 2): the
-- budget shrinks a big boss's bursts to about half, never the spot they are born on, so a wider spread stood its
-- daisies far behind the boss, up by the horizon.
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
local FLAKES = { layout = "Grid4x4", mode = "Loop", fps = { 1, 2 }, random = true }

-- The impact frame: a starburst at the heart of the blow, full size in a blink, gone in a fifth of a second. Raised
-- so the floor does not cut its lower half off flat.
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		offset = { 0, 1.5, 0 },
		count = 1,
		life = { 0.18, 0.18 },
		size = { { 0, size * 0.3 }, { 0.15, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0 }, { 0.45, 0.05 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.3,
		zOffset = 3,
	}, over)
end

-- A crisp ring racing out over the ground (eased out: fast, then slowing as it fades).
local function shock(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, 0.12, 0 },
		flat = true,
		count = 1,
		life = { 0.35, 0.35 },
		size = { { 0, width * 0.15 }, { 0.25, width * 0.8 }, { 1, width } },
		transparency = { { 0, 0 }, { 0.4, 0.2 }, { 1, 1 } },
		zOffset = 0.7,
	}, over)
end

-- What the ground keeps: one flat picture lying on it, fading over `seconds`.
local function scar(name, texture, color, width, seconds, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, 0.08, 0 },
		flat = true,
		count = 1,
		life = { seconds, seconds },
		size = { { 0, width * 0.7 }, { 0.06, width }, { 1, width } },
		transparency = { { 0, 0.4 }, { 0.06, 0.05 }, { 0.6, 0.25 }, { 1, 1 } },
		rotation = { 0, 359 },
		zOffset = 0.4,
	}, over)
end

local variants = {
	-- the Meadow: a golden comic burst, bright gold shards, a gold shock ring, then a ring of pollen glowing on the
	-- ground and daisies popping up in it (brown cracks read as a shadow on the green floor; `flower_bloom_flip`'s
	-- fading frames are loose tan curls, a brown cloud at a boss's size)
	meadow = {
		pieces = {
			flash("flash", "burst_comic_b", { 255, 240, 160 }, 9),
			flash(
				"shards",
				"impact_shards",
				{ 255, 240, 170 },
				10,
				{ life = { 0.24, 0.24 }, lightEmission = 0.5, zOffset = 2.5 }
			),
			shock("shock", "ring_crisp", { 255, 205, 70 }, 14, { lightEmission = 0.3 }),
			scar("pollen", "ring_soft", { 255, 215, 80 }, 8, 1.8, { lightEmission = 0.4 }),
			{
				name = "daisies",
				texture = "daisy_colour",
				role = "keep",
				at = "ground",
				offset = { 0, 0.5, 0 },
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.8,
				orientation = "FacingCameraWorldUp",
				count = 9,
				delay = 0.12,
				life = { 1.4, 1.9 },
				size = { { 0, 0 }, { 0.12, 1.15 }, { 0.2, 0.9 }, { 0.85, 0.9 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
				rotation = { -20, 20 },
				speed = { 0, 0 },
				direction = "Top",
				zOffset = 0.5,
			},
		},
	},
	-- the Mushroom Grove: a pale violet starburst, teal rays, a violet shock ring, then a rune left on the ground,
	-- violet fumes lying low and lime bubbles popping
	grove = {
		pieces = {
			flash("flash", "impact_star", { 230, 195, 255 }, 9, { lightEmission = 0.4 }),
			flash(
				"rays",
				"impact_rays",
				{ 170, 255, 230 },
				11,
				{ life = { 0.24, 0.24 }, lightEmission = 0.5, zOffset = 2.5 }
			),
			shock("shock", "ring_crisp", { 165, 100, 240 }, 14, { lightEmission = 0.35 }),
			-- (`rune_ring_broken` has a dark square behind it: it lay on the floor as a black tile)
			scar("rune", "rune_circle", { 150, 90, 225 }, 8, 2, { rotSpeed = { 20, 20 }, lightEmission = 0.3 }),
			{
				name = "fumes",
				texture = "smoke_poison",
				color = { { 150, 95, 210 }, { 115, 70, 175 } },
				at = "ground",
				offset = { 0, 0.6, 0 },
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.6,
				count = 4,
				delay = 0.1,
				life = { 1.6, 2 },
				size = { { 0, 1.5 }, { 0.3, 3.2 }, { 1, 4 } },
				transparency = { { 0, 1 }, { 0.15, 0.35 }, { 0.6, 0.5 }, { 1, 1 } },
				speed = { 0.3, 0.8 },
				direction = "Top",
				accel = { 0, 0.3, 0 },
				rotation = { 0, 359 },
				rotSpeed = { -20, 20 },
				zOffset = 0.3,
			},
			{
				name = "bubbles",
				texture = "bubbles_flip",
				color = { 175, 240, 80 },
				at = "ground",
				offset = { 0, 0.3, 0 },
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.7,
				orientation = "FacingCameraWorldUp",
				life = { 0.5, 0.7 },
				size = { { 0, 0.8 }, { 1, 1 } },
				transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
				speed = { 0, 0 },
				flipbook = FOUR,
				lightEmission = 0.3,
				stream = { from = 0.2, to = 1.8, rate = { 8, 3 } },
			},
		},
	},
	-- Ember Lava: a white-hot starburst, orange shards, a fire shock ring, then cracks left glowing in the dark rock,
	-- smoke curling up and embers rising off them
	lava = {
		pieces = {
			flash("flash", "burst_star_b", { 255, 235, 165 }, 9, { lightEmission = 0.5 }),
			flash(
				"shards",
				"impact_shards_b",
				{ 255, 200, 110 },
				10,
				{ life = { 0.24, 0.24 }, lightEmission = 0.6, zOffset = 2.5 }
			),
			shock("shock", "ring_crisp", { 255, 120, 35 }, 14, { lightEmission = 0.5 }),
			-- (the cracks are black-backed: worn fully added, they glow on the Lava map's dark floor)
			scar("cracks", "crack_glow", { 255, 115, 35 }, 9, 2.4, { lightEmission = 1, brightness = 2 }),
			{
				name = "smoke",
				texture = "smoke_puff_solid_flip",
				color = { { 70, 58, 58 }, { 100, 85, 80 } },
				at = "ground",
				offset = { 0, 0.8, 0 },
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.5,
				count = 4,
				delay = 0.1,
				life = { 1.3, 1.8 },
				size = { { 0, 1.2 }, { 1, 3.6 } },
				transparency = { { 0, 1 }, { 0.15, 0.3 }, { 0.6, 0.45 }, { 1, 1 } },
				speed = { 1, 2 },
				direction = "Top",
				accel = { 0, 0.5, 0 },
				drag = 0.6,
				rotation = { 0, 359 },
				rotSpeed = { -25, 25 },
				flipbook = FOUR,
				zOffset = 0.3,
			},
			{
				name = "embers",
				texture = "embers_fly",
				color = { { 255, 210, 100 }, { 255, 110, 30 } },
				at = "ground",
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.8,
				direction = "Top",
				life = { 0.7, 1.1 },
				size = { { 0, 0.45 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
				speed = { 2, 5 },
				spread = { 20, 20 },
				accel = { 0, 3, 0 },
				lightEmission = 1,
				brightness = 3,
				stream = { from = 0.1, to = 1.8, rate = { 14, 3 } },
			},
		},
	},
	-- Frozen Ice: a cold four-point flash, blue shards, a blue shock ring, then the ground left frozen in a deep blue web,
	-- frost mist lying on it and glints twinkling
	ice = {
		pieces = {
			flash("flash", "star_flash", { 170, 215, 255 }, 10, { lightEmission = 0.2 }),
			flash(
				"shards",
				"impact_shards",
				{ 150, 200, 255 },
				10,
				{ life = { 0.24, 0.24 }, lightEmission = 0.3, zOffset = 2.5 }
			),
			shock("shock", "ring_crisp", { 70, 145, 245 }, 14, { lightEmission = 0.15 }),
			scar("frozen", "crack_web", { 65, 135, 235 }, 9, 2.4, { lightEmission = 0.1 }),
			{
				name = "mist",
				texture = "smoke_puff_solid_flip",
				color = { { 130, 185, 255 }, { 90, 150, 240 } },
				at = "ground",
				offset = { 0, 0.5, 0 },
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.7,
				count = 4,
				delay = 0.08,
				life = { 1.4, 1.9 },
				size = { { 0, 1.5 }, { 1, 3.8 } },
				transparency = { { 0, 1 }, { 0.15, 0.25 }, { 0.6, 0.45 }, { 1, 1 } },
				speed = { 0.4, 1 },
				spread = { 60, 60 },
				direction = "Top",
				drag = 0.8,
				rotation = { 0, 359 },
				rotSpeed = { -20, 20 },
				flipbook = FOUR,
				lightEmission = 0.1,
				zOffset = 0.3,
			},
			{
				name = "glints",
				texture = "star_glint_small",
				color = { 140, 200, 255 },
				at = "ground",
				offset = { 0, 0.6, 0 },
				shape = "Disc",
				shapeStyle = "Surface",
				radius = 1.9,
				life = { 0.4, 0.6 },
				size = { { 0, 0 }, { 0.4, 0.7 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0.2 } },
				speed = { 0, 0.3 },
				lightEmission = 0.4,
				stream = { from = 0.15, to = 1.9, rate = { 10, 4 } },
			},
			{
				name = "flakes",
				texture = "snow_crystals_flip",
				color = { 110, 180, 255 },
				count = 8,
				life = { 0.5, 0.8 },
				size = { { 0, 0.8 }, { 1, 0.3 } },
				transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
				speed = { 8, 14 },
				spread = { 180, 180 },
				accel = { 0, -6, 0 },
				drag = 1,
				flipbook = FLAKES,
				lightEmission = 0.1,
				zOffset = 1,
			},
		},
	},
}

return {
	id = "skill.monster_impact",
	name = "Monster Impact",
	kind = "skill",
	tier = "mid",
	host = "any",
	refHeight = 5,
	tags = { "dungeon", "monster", "boss", "impact", "flash", "shockwave", "ground", "green", "purple", "fire", "ice" },
	blend = "normal",
	palette = {},
	tintable = false,
	markers = { impact = 0, peak = 0.05 },
	pieces = variants.meadow.pieces,
	variants = variants,
	defaultVariant = "meadow",
	source = {
		from = "Goo Lineage V2 (2026-11-12): the dungeon bosses' bursts",
		art = "the library's pictures (ASSETS.md families)",
		licence = "free Creator Store pictures already in the library",
	},
	notes = "Play where a boss's special comes down, on top of its own release (opts.variant = the map: meadow, grove, lava, ice; opts.size = the box standing on the floor there; twice the scale round the caster for a special that bursts round itself). A flash of a fifth of a second, a crisp shock ring, then the ground marked for about two seconds.",
}
