-- Weapon Aura Focus: what Goo Lineage's finer Arcane Focuses give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). The cheapest of the weapon's layers, for four slimes on a
-- phone: a glow on the gem and the rung's motif going round it, drawn solid so it shows on snow. Core, the Prism: the
-- gem's glow passing through the rainbow, rainbow crystal shards circling it. Bramble, the Mythic Focus: a violet glow,
-- the game's arcane motes going round one way and green leaves the other, a glint, a violet light. Legend, the Astral
-- Scepter: a night-blue glow, a pink galaxy turning over the gem like a halo, gold stars circling, twinkles, a
-- starlight glow.
local GEM = 3.05 -- studs up the 3.5-stud focus to its gem (the owner's models, the gem in its head)

local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft glow of the rung's colour breathing round the gem)
local function gem(color, size)
	return {
		name = "gem",
		texture = "glow_soft",
		color = color,
		at = "head",
		offset = { 0, -0.4, 0 },
		rate = 2,
		life = { 1.4, 1.8 },
		size = { { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.8 } },
		transparency = { { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } },
		lightEmission = 0.6,
		zOffset = -0.5,
	}
end

-- (things going round the gem, left in the world as the focus moves: a faint ring drawn where it was carried)
local function orbit(name, texture, color, period, phase, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		orbit = { radius = 0.6, period = period, phase = phase, y = GEM },
		rate = rate,
		life = { 0.6, 0.8 },
		size = { { 0, 0 }, { 0.2, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0.05 }, { 0.7, 0.2 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.4,
		locked = false,
	}, over)
end

-- (a sheet of four pictures: each particle keeps one of them, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "aura.weapon_focus",
	name = "Weapon Aura Focus",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "focus", "held", "arcane", "orbit", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		-- (the Prism: the gem's glow passing through the colours)
		gem("rainbow", 1.9),
		orbit("shards", "shard_flat", "rainbow", 1.8, 0, 6, 0.6, { rotSpeed = { -200, 200 }, brightness = 1.5 }),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				gem({ 175, 110, 255 }, 2),
				-- (the game's own arcane motes, kept as drawn, one way round; leaves the other)
				orbit("motes", "moteArcane", nil, 1.6, 0, 6, 0.75, { role = "keep", lightEmission = 0.5 }),
				orbit("leaves", "leaves_solid", { { 170, 230, 95 }, { 95, 175, 60 } }, -2.2, 0.5, 3, 0.7, {
					life = { 0.8, 1.1 },
					accel = { 0, -0.6, 0 },
					rotSpeed = { -120, 120 },
					brightness = 1.3,
					flipbook = ONE_OF,
				}),
				{
					name = "glint",
					texture = "star_flare",
					color = { { 255, 240, 255 }, { 200, 140, 255 } },
					at = "head",
					offset = { 0, -0.4, 0 },
					rate = 1,
					life = { 0.35, 0.45 },
					size = { { 0, 0 }, { 0.35, 1.4 }, { 1, 0 } },
					rotation = { -20, 20 },
					rotSpeed = { -60, 60 },
					lightEmission = 1,
					zOffset = 1,
				},
			},
			light = { color = { 195, 140, 255 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = {
				gem({ 95, 80, 230 }, 2),
				-- (a pink galaxy turning over the gem like a halo: one always there, breathing as the next takes its place)
				{
					name = "galaxy",
					texture = "galaxy_spiral",
					color = { { 255, 180, 235 }, { 170, 130, 255 } },
					at = "crown",
					rate = 1 / 2.2,
					steady = true,
					life = { 2.3, 2.3 },
					size = { { 0, 1.1 }, { 0.15, 1.6 }, { 0.85, 1.6 }, { 1, 1.3 } },
					transparency = { { 0, 1 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 1 } },
					rotation = { 0, 0 },
					rotSpeed = { 40, 40 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 1, -- (the pack's galaxy is drawn on dark: added, or its square shows)
					brightness = 2,
				},
				orbit("stars", "star_fat", { { 255, 240, 170 }, { 255, 195, 85 } }, 2, 0, 6, 0.6, {
					rotSpeed = { -120, 120 },
					lightEmission = 0.4,
					brightness = 1.6,
				}),
				{
					name = "twinkles",
					texture = "star_twinkle",
					color = { { 255, 250, 235 }, { 200, 180, 255 } },
					at = "head",
					box = { 0.9, 0.3, 0.9 },
					rate = 3,
					life = { 0.6, 0.9 },
					size = { { 0, 0 }, { 0.3, 0.75 }, { 1, 0 } },
					speed = { 0.1, 0.4 },
					spread = { 180, 180 },
					rotation = { 0, 359 },
					lightEmission = 1,
					locked = false,
					secondary = true,
				},
			},
			light = { color = { 170, 140, 255 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "the owner's arcane motes (moteArcane: Goo Lineage's own, kept as drawn); free Creator Store pack textures (no scripts: glow_soft, shard_flat, star_flare, galaxy_spiral, star_fat, star_twinkle); leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(focusMeshPart, id, { variant = rarity }) while a core, bramble or legend focus is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
