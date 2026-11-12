-- Weapon Aura Staff: what Goo Lineage's finer Healing Staffs give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). Quiet, for four slimes on a phone: a soft glow of the rung's
-- colour breathes at the head, small lights rise off it and a leaf falls from it now and then. Core: violet, violet
-- motes rising. Bramble: green, fireflies wandering up, leaves. Legend: gold, the owner's heal crosses rising slowly,
-- gold twinkles, golden leaves.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (small lights rising off the head, left where they rose)
local function rising(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "head",
		box = { 0.6, 0.2, 0.6 },
		rate = rate,
		life = { 0.8, 1.2 },
		size = { { 0, 0 }, { 0.3, size }, { 1, 0 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } },
		speed = { 0.3, 0.7 },
		spread = { 40, 40 },
		direction = "Top",
		accel = { 0, 0.8, 0 },
		rotation = { 0, 359 },
		lightEmission = 1,
		locked = false,
	}, over)
end

-- (a soft glow of the rung's colour breathing at the head: without it, what little is shed reads as nothing)
local function glow(color, size)
	return {
		name = "glow",
		texture = "glow_soft",
		color = color,
		at = "head",
		rate = 1,
		life = { 1.6, 1.6 },
		size = { { 0, size * 0.85 }, { 0.5, size }, { 1, size * 0.85 } },
		transparency = { { 0, 1 }, { 0.5, 0.5 }, { 1, 1 } },
		lightEmission = 1,
		zOffset = -0.5,
	}
end

-- (a leaf falling from the head now and then)
local function leaves(color, rate)
	return {
		name = "leaves",
		texture = "leaves_solid",
		color = color,
		at = "head",
		box = { 0.6, 0.15, 0.6 },
		rate = rate,
		life = { 0.9, 1.3 },
		size = { { 0, 0.6 }, { 1, 0.42 } },
		transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
		speed = { 0.2, 0.5 },
		spread = { 180, 180 },
		accel = { 0, -2.5, 0 },
		drag = 1,
		rotation = { 0, 359 },
		rotSpeed = { -150, 150 },
		lightEmission = 0.15,
		flipbook = { layout = "Grid2x2", mode = "Random" },
		locked = false,
	}
end

return {
	id = "aura.weapon_staff",
	name = "Weapon Aura Staff",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "staff", "held", "heal", "nature", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		glow({ 170, 120, 255 }, 1.8),
		rising("motes", "glow_dot_small", { { 225, 195, 255 }, { 170, 110, 255 } }, 5, 0.55),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				glow({ 150, 235, 110 }, 1.9),
				rising("fireflies", "glow_dot_small", { { 230, 255, 150 }, { 180, 240, 90 } }, 5, 0.55, {
					speed = { 0.2, 0.6 },
					spread = { 90, 90 },
				}),
				leaves({ { 150, 225, 80 }, { 80, 170, 60 } }, 1),
			},
		},
		legend = {
			pieces = {
				glow({ 255, 210, 100 }, 2.1),
				rising("crosses", "healCross", nil, 0.8, 0.55, {
					role = "keep",
					rotation = { 0, 0 },
					lightEmission = 0.4,
					transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } },
				}),
				rising("twinkles", "star_twinkle", { { 255, 240, 180 }, { 255, 210, 90 } }, 2.5, 0.7),
				leaves({ { 230, 215, 90 }, { 120, 200, 70 } }, 0.8),
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "the owner's heal cross (healCross, never recoloured); free Creator Store pack textures (no scripts: glow_dot_small, glow_soft, star_twinkle); leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(staffMeshPart, id, { variant = rarity }) while a core, bramble or legend staff is held; VfxLib.detach(handle) when it is put away. Core is cheap, bramble and legend mid; no light.",
}
