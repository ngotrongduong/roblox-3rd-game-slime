-- Monster Mark: the warning on the ground where a dungeon boss's or mini-boss's special will come down (Goo Lineage V2,
-- 2026-11-12, the owner: fights as dramatic as Genshin Impact's), one variant per map, each with its own pictures and
-- motion. It shows all through the wind-up (about 1.2 s): a seal opening and turning, rings closing in on the spot,
-- bits of the map's element lifting off it; the game cancels it softly as the release comes down. Numbers are studs on
-- a 5-stud box: the game plays it on the target's spot, or twice as wide round the caster for a special that bursts
-- there. Each in a colour its own floor does not swallow (the Meadow's floor is green, the Ice map's near-white).
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
local FLAKES = { layout = "Grid4x4", mode = "Loop", fps = { 1, 2 }, random = true }

-- The seal: one flat picture on the spot opening to `width` studs and turning, held until the release.
local function seal(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, 0.12, 0 },
		flat = true,
		count = 1,
		life = { 1.5, 1.5 },
		size = { { 0, width * 0.55 }, { 0.12, width }, { 1, width } },
		transparency = { { 0, 1 }, { 0.1, 0.3 }, { 0.75, 0.1 }, { 1, 0.1 } },
		rotSpeed = { 30, 30 },
		zOffset = 0.5,
	}, over)
end

-- Rings closing in on the spot, one after the other, the last as the wind-up ends.
local function closing(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		offset = { 0, 0.15, 0 },
		flat = true,
		bursts = { { 0.05, 1 }, { 0.45, 1 }, { 0.8, 1 } },
		life = { 0.42, 0.42 },
		size = { { 0, width * 1.15 }, { 1, width * 0.25 } },
		transparency = { { 0, 0.7 }, { 0.3, 0.1 }, { 0.85, 0.2 }, { 1, 1 } },
		zOffset = 0.6,
	}, over)
end

-- Bits lifting off the spot's ground, more and more. Kept within about 2 studs of it: the budget shrinks a big boss's
-- bursts to about half but never the spot they are born on, so a wider spread stood them far behind the boss.
local function lifting(name, texture, color, radius, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "ground",
		shape = "Disc",
		shapeStyle = "Surface",
		radius = radius,
		direction = "Top",
		life = { 0.6, 0.9 },
		size = { { 0, 0.3 }, { 0.3, 0.8 }, { 1, 0.3 } },
		transparency = { { 0, 0.5 }, { 0.2, 0 }, { 0.8, 0.15 }, { 1, 1 } },
		speed = { 2, 4 },
		spread = { 15, 15 },
		stream = { from = 0.05, to = 1.2, rate = { 4, 14 }, ease = "in" },
	}, over)
end

local variants = {
	-- the Meadow (Rotbloom, Bramblehorn): a thorned seal of amber and gold, gold spiky rings closing, leaves and pollen
	-- lifting (green would vanish on the green floor, and brown read as its shadow)
	meadow = {
		pieces = {
			seal("seal", "ring_thorned", { 230, 165, 50 }, 9, { lightEmission = 0.25 }),
			closing("rings", "ring_spiky", { 255, 215, 70 }, 9, { lightEmission = 0.35 }),
			lifting("leaves", "leaves_solid", { { 200, 150, 60 }, { 230, 200, 80 } }, 2, {
				speed = { 1, 2 },
				accel = { 0, 0.5, 0 },
				rotation = { 0, 359 },
				rotSpeed = { -160, 160 },
				size = { { 0, 0.3 }, { 0.3, 0.6 }, { 1, 0.3 } },
				flipbook = LEAVES,
			}),
			lifting("pollen", "dot_round", { 255, 215, 60 }, 1.8, {
				accel = { 0, 2, 0 },
				size = { { 0, 0 }, { 0.3, 0.35 }, { 1, 0 } },
				lightEmission = 0.4,
				stream = { from = 0.2, to = 1.2, rate = { 4, 16 }, ease = "in" },
			}),
		},
	},
	-- the Mushroom Grove (Sporegorge, Hollowheart): a violet rune seal, a teal split ring turning the other way inside
	-- it, the owner's spores lifting
	grove = {
		pieces = {
			seal("seal", "rune_circle_violet", { 160, 95, 235 }, 9, { lightEmission = 0.3 }),
			seal("inner", "ring_split", { 60, 225, 195 }, 5.5, {
				offset = { 0, 0.18, 0 },
				rotSpeed = { -90, -90 },
				lightEmission = 0.35,
				zOffset = 0.7,
			}),
			closing("rings", "ring_crisp", { 175, 110, 245 }, 9, { lightEmission = 0.3 }),
			lifting("spores", "spore", nil, 1.9, { role = "keep", size = { { 0, 0.3 }, { 0.3, 0.9 }, { 1, 0.3 } } }),
		},
	},
	-- Ember Lava (Magmaw, Calderos): a web of cracks splitting open and glowing, fat fire rings closing, embers lifting
	lava = {
		pieces = {
			seal("cracks", "crack_web", { 255, 105, 30 }, 9, {
				size = { { 0, 2 }, { 0.6, 8 }, { 1, 9.5 } },
				rotSpeed = { 0, 0 },
				rotation = { 0, 359 },
				lightEmission = 0.5,
			}),
			closing("rings", "ring_fat_flip", { 255, 150, 50 }, 9, { flipbook = FOUR, lightEmission = 0.5 }),
			lifting("embers", "embers_fly", { { 255, 210, 100 }, { 255, 110, 30 } }, 2, {
				accel = { 0, 3, 0 },
				size = { { 0, 0.5 }, { 1, 0 } },
				lightEmission = 1,
				brightness = 3,
				stream = { from = 0.05, to = 1.2, rate = { 6, 22 }, ease = "in" },
			}),
		},
	},
	-- Frozen Ice (Rimetusk, Frostmaw): frost cracking out from the spot in a deep ice blue, crisp blue rings closing,
	-- snow crystals lifting (pale blue vanished on the near-white floor)
	ice = {
		pieces = {
			seal("frost", "crack_star", { 60, 130, 235 }, 9, {
				size = { { 0, 2.5 }, { 0.7, 8.5 }, { 1, 9.5 } },
				rotSpeed = { 0, 0 },
				rotation = { 0, 359 },
				lightEmission = 0.1,
			}),
			closing("rings", "ring_neon", { 80, 155, 250 }, 9, { lightEmission = 0.15 }),
			lifting("flakes", "snow_crystals_flip", { 100, 170, 255 }, 1.9, {
				accel = { 0, 1, 0 },
				size = { { 0, 0.3 }, { 0.3, 0.8 }, { 1, 0.4 } },
				flipbook = FLAKES,
				lightEmission = 0.1,
			}),
		},
	},
}

return {
	id = "skill.monster_mark",
	name = "Monster Mark",
	kind = "skill",
	tier = "mid",
	host = "any",
	refHeight = 5,
	tags = { "dungeon", "monster", "boss", "telegraph", "warning", "ground", "green", "purple", "fire", "ice" },
	blend = "normal",
	palette = {},
	tintable = false,
	markers = { full = 1.2 },
	pieces = variants.meadow.pieces,
	variants = variants,
	defaultVariant = "meadow",
	source = {
		from = "Goo Lineage V2 (2026-11-12): the dungeon bosses' warnings",
		art = "the library's pictures (ASSETS.md families), owner art kept as drawn (spore)",
		licence = "the owner's own and free Creator Store pictures already in the library",
	},
	notes = "Play at the spot a boss's special will come down as its wind-up starts (opts.variant = the map: meadow, grove, lava, ice; opts.size = the box standing on the floor there), twice as wide round the caster for a special that bursts round itself; cancel it softly (VfxLib.cancel) as the release comes down. Holds about 1.2 s.",
}
