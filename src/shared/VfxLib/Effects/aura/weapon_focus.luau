-- Weapon Aura Focus: what Goo Lineage's finer Arcane Focuses give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). Quiet, for four slimes on a phone: the game's own arcane motes
-- go round the gem, left behind in a faint ring as the focus moves, and a rune turns faintly about it. Core: the arcane
-- motes and a violet rune. Bramble: the motes, a green rune, the gem glowing green, a leaf now and then. Legend: the
-- arcane motes and gold stars going round the other way, a gold rune, the gem glowing gold, gold twinkles.
local GEM = 3.05 -- studs up the 3.5-stud focus to its gem (the owner's models)

local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (motes going round the gem; left in the world, they draw a faint ring)
local function orbit(name, texture, phase, period, over)
	return with({
		name = name,
		texture = texture,
		orbit = { radius = 0.5, period = period, phase = phase, y = GEM },
		rate = 8,
		life = { 0.4, 0.55 },
		size = { { 0, 0.7 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.6,
		locked = false,
	}, over)
end

local function arcane(phase)
	return orbit("motes", "moteArcane", phase, 1.6, { role = "keep" })
end

-- (a rune turning faintly about the gem)
local function rune(color, size)
	return {
		name = "rune",
		-- (a broken ring of white strokes: floor art is one aura's own, and rune_circle is the ember sovereign's)
		texture = "rune_ring_broken",
		color = color,
		at = "head",
		offset = { 0, -0.35, 0 },
		rate = 0.6,
		life = { 2, 2 },
		size = { { 0, size }, { 1, size } },
		-- (at 0.7 the broken strokes were lost on a dark wall)
		transparency = { { 0, 1 }, { 0.3, 0.35 }, { 0.7, 0.35 }, { 1, 1 } },
		rotation = { 0, 359 },
		rotSpeed = { 60, 60 },
		lightEmission = 1,
		zOffset = -0.5,
	}
end

-- (the gem glowing softly, breathing)
local function gem(color)
	return {
		name = "gem",
		texture = "glow_soft",
		color = color,
		at = "head",
		offset = { 0, -0.45, 0 },
		rate = 1,
		life = { 1.6, 1.6 },
		size = { { 0, 1.3 }, { 0.5, 1.5 }, { 1, 1.3 } },
		transparency = { { 0, 1 }, { 0.5, 0.5 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = -1,
	}
end

return {
	id = "aura.weapon_focus",
	name = "Weapon Aura Focus",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "focus", "held", "arcane", "rune", "orbit", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		arcane(0),
		rune({ 200, 150, 255 }, 1.4),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				arcane(0),
				rune({ 170, 235, 130 }, 1.45),
				gem({ 140, 220, 100 }),
				{
					name = "leaves",
					texture = "leaves_solid",
					color = { { 150, 215, 80 }, { 90, 170, 60 } },
					at = "head",
					box = { 0.6, 0.15, 0.6 },
					rate = 0.8,
					life = { 0.9, 1.2 },
					size = { { 0, 0.6 }, { 1, 0.42 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					speed = { 0.2, 0.5 },
					spread = { 180, 180 },
					accel = { 0, -2.5, 0 },
					rotation = { 0, 359 },
					rotSpeed = { -150, 150 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
					locked = false,
				},
			},
		},
		legend = {
			pieces = {
				arcane(0),
				orbit("stars", "sparkStar", 0.5, -1.6, {
					color = { { 255, 235, 170 }, { 255, 200, 90 } },
					lightEmission = 1,
				}),
				rune({ 255, 215, 120 }, 1.55),
				gem({ 255, 190, 80 }),
				{
					name = "twinkles",
					texture = "star_twinkle",
					color = { { 255, 245, 210 }, { 255, 200, 90 } },
					at = "head",
					box = { 0.9, 0.3, 0.9 },
					rate = 2.5,
					life = { 0.6, 0.9 },
					size = { { 0, 0 }, { 0.3, 0.75 }, { 1, 0 } },
					speed = { 0.1, 0.4 },
					spread = { 180, 180 },
					rotation = { 0, 359 },
					lightEmission = 1,
					locked = false,
				},
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "the owner's arcane motes (moteArcane: Goo Lineage's own, kept as drawn) and spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: rune_ring_broken, glow_soft, star_twinkle); leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(focusMeshPart, id, { variant = rarity }) while a core, bramble or legend focus is held; VfxLib.detach(handle) when it is put away. Core is cheap, bramble and legend mid; no light.",
}
