-- Weapon Cast Shield: the Taunt of Goo Lineage's held shields, one rung per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). Played once at the shield's head (up along it) as the slime raises it and
-- calls the foe: a ward flashes up over the shield and a ring of challenge rings out from it, and each rung up adds a
-- layer. Wood: a dust-pale ring and ward. Iron: grey, sparks struck off the rim. Core: violet, a second ring of rays.
-- Bramble: a thorned gold ring, green wards, leaves. Legend: a gold ward and ring, the owner's holy burst, a blue shock
-- ring after it, star specks, a flash of light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a ring ringing out from the shield, eased out)
local function ring(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.4, 0.4 },
		size = { { 0, width * 0.2 }, { 0.3, width * 0.75 }, { 1, width } },
		transparency = { { 0, 0 }, { 0.4, 0.15 }, { 1, 1 } },
		lightEmission = 1,
	}, over)
end

-- (the ward shield flashing up over the shield and growing as it fades)
local function ward(color, size)
	return {
		name = "ward",
		texture = "shield_icon",
		color = color,
		count = 1,
		life = { 0.45, 0.45 },
		size = { { 0, size * 0.5 }, { 0.2, size }, { 1, size * 1.2 } },
		transparency = { { 0, 0 }, { 0.5, 0.1 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = 2,
	}
end

-- (sparks struck off the rim, falling)
local function sparks(color, count)
	return {
		name = "sparks",
		texture = "spark_dot",
		color = color,
		count = count,
		life = { 0.25, 0.45 },
		size = { { 0, 0.3 }, { 1, 0 } },
		speed = { 5, 9 },
		spread = { 180, 180 },
		accel = { 0, -16, 0 },
		lightEmission = 1,
		zOffset = 1,
	}
end

return {
	id = "burst.weapon_cast_shield",
	name = "Weapon Cast Shield",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "shield", "taunt", "ward", "ring", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.14 },
	pieces = {
		ring("ring", "ring_crisp", { 236, 206, 160 }, 5),
		ward({ 236, 206, 160 }, 2),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				ring("ring", "ring_crisp", { 195, 210, 235 }, 5.2),
				ward({ 205, 220, 245 }, 2.1),
				sparks({ { 255, 250, 220 }, { 255, 180, 90 } }, 10),
			},
		},
		core = {
			pieces = {
				ring("ring", "ring_crisp", { 190, 150, 255 }, 5.5),
				ring("rays", "ring_rays", { 160, 110, 255 }, 6.2, { delay = 0.06 }),
				ward({ 200, 165, 255 }, 2.4),
				sparks({ { 240, 230, 255 }, { 160, 120, 255 } }, 10),
			},
		},
		bramble = {
			pieces = {
				ring("ring", "ring_thorned", { 255, 215, 110 }, 6),
				ring("rays", "ring_rays", { 140, 220, 90 }, 6.4, { delay = 0.06 }),
				ward({ 170, 240, 120 }, 2.5),
				sparks({ { 255, 245, 200 }, { 255, 200, 80 } }, 10),
				{
					name = "leaves",
					texture = "leaves_solid",
					color = { { 150, 215, 80 }, { 90, 170, 60 } },
					count = 8,
					life = { 0.5, 0.8 },
					size = { { 0, 0.6 }, { 1, 0.4 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					speed = { 4, 7 },
					spread = { 180, 180 },
					accel = { 0, -6, 0 },
					drag = 2,
					rotation = { 0, 359 },
					rotSpeed = { -200, 200 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				},
			},
		},
		legend = {
			pieces = {
				ring("ring", "ring_bright", { 255, 205, 90 }, 6.5),
				ring("shock", "shockwave", { 110, 150, 255 }, 7.5, { delay = 0.08, life = { 0.35, 0.35 } }),
				ward({ 255, 215, 110 }, 2.8),
				{
					-- the owner's holy burst behind the ward (never recoloured)
					name = "holy",
					texture = "holyHit",
					role = "keep",
					count = 1,
					life = { 0.35, 0.35 },
					size = { { 0, 1.5 }, { 0.2, 3.4 }, { 1, 3.8 } },
					transparency = { { 0, 0 }, { 0.5, 0.2 }, { 1, 1 } },
					rotation = { 0, 359 },
					lightEmission = 0.6,
					zOffset = 1,
				},
				sparks({ { 255, 250, 220 }, { 255, 200, 90 } }, 10),
				{
					name = "specks",
					texture = "spec_star",
					color = { { 255, 250, 230 }, { 255, 215, 110 } },
					count = 12,
					life = { 0.4, 0.7 },
					size = { { 0, 0 }, { 0.25, 0.5 }, { 1, 0 } },
					speed = { 2, 5 },
					spread = { 180, 180 },
					drag = 2,
					rotation = { 0, 359 },
					lightEmission = 1,
				},
			},
			light = { color = { 255, 215, 120 }, keys = { { 0, 0 }, { 0.06, 3 }, { 0.5, 0 } }, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: ring_crisp, ring_rays, ring_thorned, ring_bright, shield_icon, spark_dot, spec_star); the owner's holy burst (holyHit, kept as drawn) and shock ring (shockwave, tinted); leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept); the owner's own art",
	},
	notes = "VfxLib.play(id, shieldHeadCFrame, { variant = rarity }) as the Taunt is called (the frame's up along the shield). Wood and iron are cheap, core to legend mid; only legend has a light.",
}
