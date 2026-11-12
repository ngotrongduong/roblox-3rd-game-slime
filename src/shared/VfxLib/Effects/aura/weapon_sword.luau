-- Weapon Aura Sword: what Goo Lineage's finer swords give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon swords have none). Quiet, for four slimes on a phone: a soft sheen of the rung's colour
-- breathes on the blade, a glint wakes on the point now and then and a few small things leave the blade and stay where
-- it passed, so a sword carried about draws a faint wake. Core: a violet sheen, violet sparks drifting up. Bramble: a
-- green sheen, a gold glint, a leaf now and then, gold pollen. Legend: an orange-gold sheen, a gold flare on the point,
-- embers rising off the blade, gold twinkles.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft sheen of the rung's colour breathing on the blade: without it, what little is shed reads as nothing)
local function sheen(color, size)
	return {
		name = "sheen",
		texture = "glow_soft",
		color = color,
		at = "chest",
		rate = 1,
		life = { 1.6, 1.6 },
		size = { { 0, size * 0.85 }, { 0.5, size }, { 1, size * 0.85 } },
		transparency = { { 0, 1 }, { 0.5, 0.55 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = -0.5,
	}
end

-- (a glint waking on the point now and then)
local function glint(texture, color, size, rate)
	return {
		name = "glint",
		texture = texture,
		color = color,
		at = "head",
		rate = rate,
		life = { 0.3, 0.4 },
		size = { { 0, 0 }, { 0.35, size }, { 1, 0 } },
		rotation = { -20, 20 },
		rotSpeed = { -60, 60 },
		lightEmission = 1,
		zOffset = 1,
	}
end

-- (small things leaving the upper blade and staying where it passed)
local function wake(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "chest",
		box = { 0.25, 0.5, 0.4 },
		rate = rate,
		life = { 0.6, 0.9 },
		size = { { 0, 0 }, { 0.25, size }, { 1, 0 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } },
		speed = { 0.2, 0.6 },
		spread = { 180, 180 },
		accel = { 0, 1, 0 },
		rotation = { 0, 359 },
		lightEmission = 1,
		locked = false,
	}, over)
end

return {
	id = "aura.weapon_sword",
	name = "Weapon Aura Sword",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "sword", "held", "glint", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		sheen({ 160, 110, 255 }, 2),
		wake("sparks", "sparkStar", { { 225, 190, 255 }, { 170, 100, 255 } }, 6, 0.65),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				sheen({ 160, 215, 80 }, 2.1),
				glint("star_glint_sharp", { { 255, 245, 200 }, { 255, 210, 90 } }, 1.3, 1),
				wake("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 1.2, 0.6, {
					size = { { 0, 0.6 }, { 1, 0.42 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					accel = { 0, -2.5, 0 },
					rotSpeed = { -150, 150 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				}),
				wake("pollen", "glow_dot_small", { { 255, 235, 140 }, { 255, 205, 80 } }, 4, 0.5),
			},
		},
		legend = {
			pieces = {
				sheen({ 255, 140, 50 }, 2.3),
				glint("star_flare", { { 255, 245, 210 }, { 255, 150, 70 } }, 1.6, 1),
				wake(
					"embers",
					"fire_specks",
					{ { 255, 210, 110 }, { 255, 90, 40 } },
					6,
					0.6,
					{ accel = { 0, 2.5, 0 } }
				),
				wake("twinkles", "star_twinkle", { { 255, 240, 190 }, { 255, 190, 80 } }, 2.5, 0.75),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: glow_soft, star_glint_sharp, star_flare, glow_dot_small, fire_specks, star_twinkle); the owner's spark star (sparkStar, tinted); leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept); the owner's own art",
	},
	notes = "VfxLib.attach(swordMeshPart, id, { variant = rarity }) while a core, bramble or legend sword is held; VfxLib.detach(handle) when it is put away. Core is cheap, bramble and legend mid; no light.",
}
