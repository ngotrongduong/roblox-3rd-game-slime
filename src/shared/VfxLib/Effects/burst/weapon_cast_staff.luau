-- Weapon Cast Staff: the Mend of Goo Lineage's Healing Staff, one rung per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). Played once at the staff's head (up along it) as the heal is cast: a soft
-- bloom of light opens at the head and the owner's heal crosses rise out of it, and each rung up adds a layer. Wood: a
-- pale gold bloom and two crosses. Iron: a green bloom, leaves swirling up. Core: a violet bloom, violet motes rising.
-- Bramble: a green bloom, a soft ring, more leaves, fireflies. Legend: a gold bloom, gold rays, a ring of rays, golden
-- leaves, more crosses and gold twinkles, a warm flash of light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the soft bloom of light at the head)
local function bloom(color, size)
	return {
		name = "bloom",
		texture = "glow_soft",
		color = color,
		count = 1,
		life = { 0.5, 0.5 },
		size = { { 0, size * 0.4 }, { 0.25, size }, { 1, size * 1.2 } },
		transparency = { { 0, 0.1 }, { 0.5, 0.35 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = -0.5,
	}
end

-- (the owner's heal crosses rising out of the bloom, never recoloured)
local function crosses(count)
	return {
		name = "crosses",
		texture = "healCross",
		role = "keep",
		count = count,
		life = { 0.6, 0.85 },
		size = { { 0, 0 }, { 0.2, 0.65 }, { 1, 0.5 } },
		transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
		-- (fanned well apart: slow and narrow, they rose as one green lump over the staff's own green head)
		speed = { 3.5, 5.5 },
		spread = { 65, 65 },
		direction = "Top",
		accel = { 0, 2, 0 },
		drag = 1,
		rotation = { 0, 0 },
		lightEmission = 0.4,
		zOffset = 1,
	}
end

-- (small things swirling up off the head)
local function rising(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.5, 0.8 },
		size = { { 0, 0 }, { 0.25, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } },
		speed = { 2, 4 },
		spread = { 70, 70 },
		direction = "Top",
		accel = { 0, 2.5, 0 },
		drag = 1.5,
		rotation = { 0, 359 },
		lightEmission = 1,
	}, over)
end

local function leaves(color, count)
	return rising("leaves", "leaves_solid", color, count, 0.55, {
		size = { { 0, 0.55 }, { 1, 0.35 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		rotSpeed = { -200, 200 },
		lightEmission = 0.15,
		flipbook = { layout = "Grid2x2", mode = "Random" },
	})
end

-- (a soft ring opening round the head)
local function ring(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.45, 0.45 },
		size = { { 0, width * 0.2 }, { 0.35, width * 0.8 }, { 1, width } },
		transparency = { { 0, 0.1 }, { 0.4, 0.25 }, { 1, 1 } },
		lightEmission = 1,
	}, over)
end

return {
	id = "burst.weapon_cast_staff",
	name = "Weapon Cast Staff",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "staff", "heal", "mend", "nature", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.28 },
	pieces = {
		bloom({ 240, 230, 170 }, 2.6),
		crosses(2),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				bloom({ 190, 240, 170 }, 2.8),
				crosses(2),
				leaves({ { 160, 220, 90 }, { 100, 175, 70 } }, 5),
			},
		},
		core = {
			pieces = {
				bloom({ 200, 150, 255 }, 3),
				crosses(3),
				leaves({ { 160, 220, 90 }, { 100, 175, 70 } }, 6),
				rising("motes", "glow_dot_small", { { 215, 180, 255 }, { 170, 110, 255 } }, 10, 0.5),
			},
		},
		bramble = {
			pieces = {
				bloom({ 150, 235, 110 }, 3.1),
				crosses(3),
				leaves({ { 150, 225, 80 }, { 80, 170, 60 } }, 9),
				rising("fireflies", "glow_dot_small", { { 230, 255, 150 }, { 180, 240, 90 } }, 10, 0.45),
				ring("ring", "ring_soft", { 150, 235, 110 }, 4.4),
			},
		},
		legend = {
			pieces = {
				bloom({ 255, 215, 110 }, 3.4),
				crosses(5),
				leaves({ { 230, 215, 90 }, { 120, 200, 70 } }, 8),
				rising("twinkles", "star_twinkle", { { 255, 240, 180 }, { 255, 210, 90 } }, 8, 0.7),
				ring("rays", "ring_rays", { 255, 210, 100 }, 5.2),
				{
					name = "shine",
					texture = "nova_rays",
					color = { 255, 220, 130 },
					count = 1,
					life = { 0.4, 0.4 },
					size = { { 0, 1.2 }, { 0.25, 3.6 }, { 1, 4 } },
					transparency = { { 0, 0.1 }, { 0.5, 0.3 }, { 1, 1 } },
					rotation = { 0, 359 },
					rotSpeed = { -40, 40 },
					lightEmission = 1,
					zOffset = -1,
				},
			},
			light = { color = { 255, 225, 140 }, keys = { { 0, 0 }, { 0.08, 2.5 }, { 0.6, 0 } }, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "the owner's heal cross (healCross, never recoloured); free Creator Store pack textures (no scripts: glow_soft, glow_dot_small, star_twinkle, ring_soft, ring_rays, nova_rays); leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, staffHeadCFrame, { variant = rarity }) as the Mend is cast (the frame's up along the staff). Wood and iron are cheap, core to legend mid; only legend has a light.",
}
