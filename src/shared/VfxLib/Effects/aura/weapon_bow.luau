-- Weapon Aura Bow: what Goo Lineage's finer bows give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon bows have none). The cheapest of the weapon's layers, for four slimes on a phone: a
-- soft glow of the rung's colour along the bow and the rung's motif, drawn solid so it shows on snow. Core,
-- Windwhisper: a teal glow, sky-blue feathers drifting off the limbs. Bramble, Starfall: a violet glow, little gold
-- stars falling off the bow, a glint on the upper limb, a violet light. Legend, Moonsong: silver glints along the
-- limbs, silver notes rising, a gold crescent moon hanging over the bow like a crown, twinkles, a moon light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft glow of the rung's colour breathing along the bow, limb to limb: the bow seen lit from far)
local function gem(color, size)
	return {
		name = "gem",
		texture = "glow_soft",
		color = color,
		at = "body",
		box = { 0.15, 1.1, 0.15 },
		rate = 2.5,
		life = { 1.4, 1.8 },
		size = { { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.8 } },
		transparency = { { 0, 1 }, { 0.5, 0.3 }, { 1, 1 } },
		lightEmission = 0.3, -- (more tint than light: a glow only added is lost on snow)
		zOffset = -0.5,
	}
end

-- (small things leaving the limbs and staying where the bow passed: a carried bow draws a faint wake)
local function wake(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 0.4, 0.9, 0.3 },
		rate = rate,
		life = { 1, 1.4 },
		size = { { 0, 0 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.25 }, { 1, 1 } },
		speed = { 0.2, 0.5 },
		spread = { 180, 180 },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.4,
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
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		gem({ 40, 165, 205 }, 1.9),
		-- (sky-blue feathers of a deeper blue than the sky's: a pale one is lost on snow)
		wake("feathers", "down_feather", { { 120, 200, 245 }, { 50, 140, 220 } }, 4, 1, {
			accel = { 0, -1.2, 0 },
			drag = 1,
			rotSpeed = { -90, 90 },
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				gem({ 130, 70, 235 }, 2),
				-- (little gold stars falling off the bow as it is carried, a deep gold that holds on snow)
				wake("stars", "star_fat", { { 255, 205, 80 }, { 235, 140, 30 } }, 5, 0.8, {
					life = { 0.8, 1.1 },
					speed = { 0.2, 0.6 },
					accel = { 0, -2.5, 0 },
					rotSpeed = { -120, 120 },
					lightEmission = 0.4,
					brightness = 1.5,
				}),
				{
					name = "glint",
					texture = "star_glint_sharp",
					color = { { 255, 250, 230 }, { 220, 180, 255 } },
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
			light = { color = { 195, 160, 255 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = {
				with(gem({ 180, 200, 255 }, 1.6), {
					texture = "sparkStar",
					rate = 3,
					life = { 0.4, 0.6 },
					size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } },
					transparency = { { 0, 0 }, { 1, 0.3 } },
					rotSpeed = { -90, 90 },
					lightEmission = 0.6,
					zOffset = 1,
				}),
				-- (silver notes rising off the strings, each kept still on one of the sheet's four)
				wake("notes", "glyph_notes", { { 200, 212, 255 }, { 120, 140, 245 } }, 3, 0.9, {
					speed = { 0.3, 0.6 },
					spread = { 25, 25 },
					direction = "Top",
					rotation = { -15, 15 },
					brightness = 1.5,
					flipbook = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true },
				}),
				-- (a gold crescent moon hanging over the bow: one always there, breathing as the next takes its place)
				{
					name = "moon",
					texture = "crescent_moon",
					color = { 255, 215, 110 },
					at = "crown",
					rate = 1 / 2.2,
					steady = true,
					life = { 2.3, 2.3 },
					size = { { 0, 1.3 }, { 0.15, 1.9 }, { 0.85, 1.9 }, { 1, 1.6 } },
					transparency = { { 0, 1 }, { 0.12, 0 }, { 0.88, 0 }, { 1, 1 } },
					rotation = { -10, -10 },
					rotSpeed = { 8, 8 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 0,
					brightness = 1.6,
				},
				wake("twinkles", "star_twinkle", { { 250, 250, 255 }, { 190, 205, 255 } }, 3, 0.55, {
					life = { 0.6, 0.9 },
					speed = { 0.2, 0.5 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 175, 195, 255 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "glyph_notes (drawn in code for the library); free Creator Store pack textures (no scripts: glow_soft, star_fat, star_glint_sharp, crescent_moon, star_twinkle); down_feather (ChatGPT for the library); the owner's spark star (sparkStar, tinted)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(bowMeshPart, id, { variant = rarity }) while a core, bramble or legend bow is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
