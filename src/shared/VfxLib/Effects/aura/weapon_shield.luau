-- Weapon Aura Shield: what Goo Lineage's finer shields give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon shields have none). The cheapest of the weapon's layers, for four slimes on a phone:
-- a soft glow of the rung's colour round the shield and the rung's motif. Core, the Warden: a blue glow, a gold crest
-- shimmering over the face. Bramble, the Aegis of Goo: a green glow, the owner's acid drops gathering on the face and
-- dripping off, a leaf circling the shield, a green light. Legend, the Royal Bastion: a gold glow, a golden crown
-- hanging over the shield, fleurs, banners and castles rising off it, a glint on the rim, gold specks, a gold light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft glow of the rung's colour breathing behind the shield: seen round its edges from far)
local function gem(color, size)
	return {
		name = "gem",
		texture = "glow_soft",
		color = color,
		at = "body",
		box = { 0.5, 0.6, 0.2 },
		rate = 2.5,
		life = { 1.4, 1.8 },
		size = { { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.8 } },
		transparency = { { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } },
		lightEmission = 0.6,
		zOffset = -0.5,
	}
end

-- (things leaving the shield's face and hanging where it passed)
local function wake(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		-- (wider than the shield, or most are inside it)
		box = { 1.4, 1.2, 0.6 },
		rate = rate,
		life = { 1.2, 1.6 },
		size = { { 0, 0 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
		speed = { 0.2, 0.5 },
		direction = "Top",
		spread = { 25, 25 },
		rotation = { -15, 15 },
		lightEmission = 0,
		brightness = 1.4,
		locked = false,
	}, over)
end

-- (a sheet of four small pictures: each particle keeps one of them, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "aura.weapon_shield",
	name = "Weapon Aura Shield",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "shield", "held", "ward", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		gem({ 80, 135, 255 }, 3),
		-- (the Warden's gold crest shimmering over the face, one after another, never gone)
		{
			name = "crest",
			texture = "shield_icon",
			color = { 255, 215, 100 },
			at = "body",
			-- (a little before the face and wider than the shield: inside its body the shield's own mesh hid it)
			offset = { 0, 0, -0.3 },
			rate = 1.2,
			life = { 1.5, 1.5 },
			size = { { 0, 2.8 }, { 1, 3.6 } },
			transparency = { { 0, 1 }, { 0.3, 0.45 }, { 0.7, 0.45 }, { 1, 1 } },
			rotation = { 0, 0 },
			orientation = "FacingCameraWorldUp",
			lightEmission = 0.7,
			brightness = 1.3,
			zOffset = 1,
		},
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				gem({ 110, 220, 80 }, 3.1),
				-- (the owner's acid drops gathering on the face and dripping off, as drawn)
				wake("drips", "acidDrop", nil, 2.5, 0.6, {
					role = "keep",
					box = { 0.9, 0.9, 0.4 },
					life = { 0.7, 0.9 },
					size = { { 0, 0.2 }, { 0.25, 0.6 }, { 1, 0.55 } },
					transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
					speed = { 0, 0 },
					accel = { 0, -6, 0 },
					rotation = { 0, 0 },
					brightness = 1.2,
				}),
				-- (a leaf circling the shield, leaving a few behind as it goes round)
				{
					name = "leaves",
					texture = "leaves_solid",
					color = { { 150, 215, 80 }, { 90, 170, 60 } },
					orbit = { radius = 1.4, period = 3, phase = 0, y = 1.9 },
					rate = 5,
					life = { 0.8, 1.1 },
					size = { { 0, 0 }, { 0.2, 0.75 }, { 1, 0.45 } },
					transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
					speed = { 0.1, 0.3 },
					spread = { 180, 180 },
					accel = { 0, -0.8, 0 },
					rotation = { 0, 359 },
					rotSpeed = { -90, 90 },
					lightEmission = 0,
					brightness = 1.3,
					flipbook = ONE_OF,
					locked = false,
				},
			},
			light = { color = { 150, 255, 110 }, brightness = 1.2, range = 8 },
		},
		legend = {
			pieces = {
				gem({ 255, 195, 80 }, 3.2),
				-- (a golden crown over the shield, forged again and again: it grows from a spark point by point, glints,
				-- breaks into sparkles, and the next one is already growing)
				{
					name = "crown",
					texture = "crown_flip",
					color = { 255, 205, 80 },
					at = "crown",
					rate = 1 / 2,
					steady = true,
					life = { 1.8, 1.8 },
					size = { { 0, 1.6 }, { 1, 1.6 } },
					transparency = { { 0, 0 }, { 0.9, 0 }, { 1, 1 } },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					rotation = { 0, 0 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 0,
					brightness = 1.6,
				},
				-- (the Bastion's arms rising off it: each a fleur-de-lis growing from a spark, glinting, splitting)
				wake("arms", "royal_flip", { { 255, 228, 130 }, { 255, 190, 60 } }, 1.6, 0.85, {
					size = { { 0, 0.85 }, { 1, 0.8 } },
					brightness = 1.5,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				{
					name = "glint",
					texture = "star_glint_sharp",
					color = { { 255, 255, 240 }, { 255, 215, 110 } },
					at = "head",
					box = { 0.8, 0.1, 0.3 },
					rate = 1.2,
					life = { 0.35, 0.45 },
					size = { { 0, 0 }, { 0.35, 1.5 }, { 1, 0 } },
					rotation = { -20, 20 },
					rotSpeed = { -60, 60 },
					lightEmission = 1,
					zOffset = 1.5,
				},
				wake("specks", "spec_star", { { 255, 245, 210 }, { 255, 205, 90 } }, 5, 0.55, {
					life = { 0.7, 1 },
					size = { { 0, 0 }, { 0.3, 0.55 }, { 1, 0 } },
					speed = { 0.1, 0.4 },
					spread = { 180, 180 },
					rotation = { 0, 359 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 255, 215, 120 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "royal_flip, crown_flip (ChatGPT clips drawn for the library: tools/chatgpt/clip_frames.py); free Creator Store pack textures (no scripts: glow_soft, shield_icon, star_glint_sharp, spec_star); leaves_solid (ChatGPT for the library); the owner's acid drop (acidDrop, kept as drawn)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(shieldMeshPart, id, { variant = rarity }) while a core, bramble or legend shield is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
