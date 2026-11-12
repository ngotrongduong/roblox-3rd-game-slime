-- Weapon Aura Bow: what Goo Lineage's finer bows give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon bows have none). Quiet, for four slimes on a phone: a soft sheen of the rung's colour
-- breathes on the bow, glints run along the limbs and a feather drifts off now and again. Core: a sky-blue sheen and
-- glints. Bramble: green, green-gold glints, a violet feather, a leaf. Legend: gold, gold flares along the limbs, violet
-- and gold twinkles, a gold feather.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft sheen of the rung's colour breathing on the bow: without it, what little is shed reads as nothing)
local function sheen(color, size)
	return {
		name = "sheen",
		texture = "glow_soft",
		color = color,
		at = "body",
		rate = 1,
		life = { 1.6, 1.6 },
		size = { { 0, size * 0.85 }, { 0.5, size }, { 1, size * 0.85 } },
		transparency = { { 0, 1 }, { 0.5, 0.55 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = -0.5,
	}
end

-- (glints running along the limbs, limb tip to limb tip)
local function glints(texture, color, rate, size)
	return {
		name = "glints",
		texture = texture,
		color = color,
		at = "body",
		box = { 0.3, 0.95, 0.3 },
		rate = rate,
		life = { 0.25, 0.35 },
		size = { { 0, 0 }, { 0.35, size }, { 1, 0 } },
		rotation = { -20, 20 },
		lightEmission = 1,
		zOffset = 1,
	}
end

-- (a feather drifting off the limbs, left where it fell)
local function drifting(name, texture, color, rate, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 0.4, 0.9, 0.3 },
		rate = rate,
		life = { 0.9, 1.3 },
		size = { { 0, 0.6 }, { 1, 0.42 } },
		transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
		speed = { 0.2, 0.5 },
		spread = { 180, 180 },
		accel = { 0, -1.5, 0 },
		drag = 1,
		rotation = { 0, 359 },
		rotSpeed = { -90, 90 },
		lightEmission = 0.3,
		locked = false,
	}, over)
end

return {
	id = "aura.weapon_bow",
	name = "Weapon Aura Bow",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "bow", "held", "glint", "feather", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		sheen({ 110, 170, 255 }, 2.2),
		glints("star_glint_small", { { 230, 245, 255 }, { 120, 180, 255 } }, 2.5, 1.1),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				sheen({ 150, 215, 90 }, 2.3),
				glints("star_glint_small", { { 230, 255, 190 }, { 160, 230, 100 } }, 2.5, 1.1),
				drifting("feathers", "down_feather", { { 200, 160, 255 }, { 170, 110, 240 } }, 0.6),
				drifting("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 0.7, {
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					accel = { 0, -2.5, 0 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				}),
			},
		},
		legend = {
			pieces = {
				sheen({ 255, 190, 70 }, 2.4),
				glints("star_flare", { { 255, 250, 225 }, { 255, 205, 90 } }, 2, 1.3),
				drifting("feathers", "down_feather", { { 255, 225, 150 }, { 190, 120, 255 } }, 0.6),
				drifting("twinkles", "star_twinkle", { { 255, 245, 210 }, { 210, 160, 255 } }, 2.5, {
					life = { 0.6, 0.9 },
					size = { { 0, 0 }, { 0.3, 0.75 }, { 1, 0 } },
					accel = { 0, 0.5, 0 },
					rotSpeed = { 0, 0 },
					lightEmission = 1,
				}),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: glow_soft, star_glint_small, star_flare, star_twinkle); down_feather, leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(bowMeshPart, id, { variant = rarity }) while a core, bramble or legend bow is held; VfxLib.detach(handle) when it is put away. Core is cheap, bramble and legend mid; no light.",
}
