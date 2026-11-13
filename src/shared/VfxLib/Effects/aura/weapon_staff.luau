-- Weapon Aura Staff: what Goo Lineage's finer Healing Staffs give off while they are held (core Epic, bramble Mythic,
-- legend Legendary; Common and Uncommon ones have none). The cheapest of the weapon's layers, for four slimes on a
-- phone: a soft glow of the rung's colour round the staff's head and the rung's motif, drawn solid so it shows on snow.
-- Core, the Enchanted staff: a violet glow, violet sparkles rising off the head. Bramble, Lifebloom: a teal glow, a
-- pink blossom circling the head and leaving blossoms behind, petals drifting down, a glint, a cool light. Legend,
-- Everbloom: a gold glow, a golden blossom turning over the head like a crown, golden leaves falling, the owner's heal
-- crosses rising slowly, gold twinkles, a warm light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft glow of the rung's colour breathing round the staff's head: the staff seen lit from far)
local function glow(color, size)
	return {
		name = "glow",
		texture = "glow_soft",
		color = color,
		at = "head",
		box = { 0.15, 0.4, 0.15 },
		rate = 1.5,
		life = { 1.4, 1.8 },
		size = { { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.8 } },
		transparency = { { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } },
		lightEmission = 0.6,
		zOffset = -0.5,
	}
end

-- (small things leaving the head and staying where it passed: a carried staff draws a faint wake)
local function wake(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "head",
		box = { 0.6, 0.3, 0.6 },
		rate = rate,
		life = { 1, 1.4 },
		size = { { 0, 0 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
		speed = { 0.2, 0.5 },
		direction = "Top",
		spread = { 35, 35 },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.4,
		locked = false,
	}, over)
end

-- (a sheet of four leaves: each particle keeps one of them, still)
local ONE_LEAF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "aura.weapon_staff",
	name = "Weapon Aura Staff",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "staff", "held", "heal", "nature", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		glow({ 175, 115, 255 }, 2),
		wake("sparkles", "sparkStar", { { 255, 235, 255 }, { 185, 125, 255 } }, 4, 0.65, {
			rotSpeed = { -60, 60 },
			lightEmission = 0.5,
			brightness = 1.6,
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				glow({ 110, 235, 200 }, 2.2),
				-- (a blossom circling the head, leaving a few behind as it goes round)
				{
					name = "blossoms",
					texture = "blossom_five",
					color = { { 255, 195, 220 }, { 245, 135, 178 } },
					orbit = { radius = 0.75, period = 2.6, phase = 0, y = 3.2 },
					rate = 5,
					life = { 0.9, 1.2 },
					size = { { 0, 0 }, { 0.2, 0.75 }, { 1, 0.45 } },
					transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
					speed = { 0.1, 0.3 },
					spread = { 180, 180 },
					accel = { 0, -0.6, 0 },
					rotation = { 0, 359 },
					rotSpeed = { -60, 60 },
					lightEmission = 0,
					brightness = 1.3,
					locked = false,
				},
				wake("petals", "petals_small_flip", { { 255, 205, 225 }, { 255, 155, 192 } }, 3, 0.55, {
					speed = { 0.1, 0.4 },
					spread = { 180, 180 },
					accel = { 0, -1, 0 },
					flipbook = { layout = "Grid4x4", mode = "Loop", fps = { 8, 12 } },
				}),
				{
					name = "glint",
					texture = "star_flare",
					color = { { 240, 255, 250 }, { 150, 240, 210 } },
					at = "head",
					rate = 1.2,
					life = { 0.35, 0.45 },
					size = { { 0, 0 }, { 0.35, 1.5 }, { 1, 0 } },
					rotation = { -20, 20 },
					rotSpeed = { -60, 60 },
					lightEmission = 1,
					zOffset = 1,
				},
			},
			light = { color = { 200, 255, 225 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = {
				glow({ 255, 205, 95 }, 2.4),
				-- (a golden blossom turning over the head: one always there, breathing as the next takes its place)
				{
					name = "crown",
					texture = "blossom_five",
					color = { 255, 215, 110 },
					at = "crown",
					rate = 1 / 2.2,
					steady = true,
					life = { 2.3, 2.3 },
					size = { { 0, 0.9 }, { 0.15, 1.35 }, { 0.85, 1.35 }, { 1, 1.1 } },
					transparency = { { 0, 1 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 1 } },
					rotation = { 0, 0 },
					rotSpeed = { 20, 20 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 0,
					brightness = 1.6,
				},
				wake("leaves", "leaves_solid", { { 255, 222, 95 }, { 228, 165, 40 } }, 3, 0.75, {
					life = { 1.1, 1.5 },
					size = { { 0, 0.75 }, { 1, 0.5 } },
					speed = { 0.2, 0.5 },
					spread = { 180, 180 },
					accel = { 0, -2.5, 0 },
					rotSpeed = { -150, 150 },
					brightness = 1.3,
					flipbook = ONE_LEAF,
				}),
				wake("crosses", "healCross", nil, 0.8, 0.6, {
					role = "keep",
					rotation = { 0, 0 },
					accel = { 0, 0.8, 0 },
					lightEmission = 0.4,
				}),
				wake("twinkles", "star_twinkle", { { 255, 240, 180 }, { 255, 210, 90 } }, 2.5, 0.7, {
					life = { 0.6, 0.9 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 255, 220, 130 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "the owner's heal cross (healCross, never recoloured) and spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: glow_soft, petals_small_flip, star_flare, star_twinkle); blossom_five, leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(staffMeshPart, id, { variant = rarity }) while a core, bramble or legend staff is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
