-- Weapon Aura Sword: what Goo Lineage's finer swords give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon swords have none). The cheapest of the weapon's layers, for four slimes on a phone:
-- a soft glow on the guard's gem and the rung's motif, drawn solid so it shows on snow. Core, the Runeblade: a violet
-- glow, lilac diamond runes rising off the blade. Bramble, the Dawnbreaker: its whole aura in one ChatGPT clip (gold
-- and pink light ribbons up the blade, the gem pulsing, a star on the tip, feathers spiralling), a warm light.
-- Legend, Sunfire: glints on the gem, small flames
-- licking up the blade, a golden sun turning over the point like a crown, embers, a fire light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a soft glow of the rung's colour breathing along the blade, from the guard's gem up: the sword seen lit from far)
local function gem(color, size)
	return {
		name = "gem",
		texture = "glow_soft",
		color = color,
		at = "chest",
		box = { 0.15, 1.1, 0.15 },
		rate = 2.5,
		life = { 1.4, 1.8 },
		size = { { 0, size * 0.7 }, { 0.5, size }, { 1, size * 0.8 } },
		transparency = { { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } },
		lightEmission = 0.6,
		zOffset = -0.5,
	}
end

-- (small things leaving the blade and staying where it passed: a carried sword draws a faint wake)
local function wake(name, texture, color, rate, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		at = "chest",
		box = { 0.3, 0.6, 0.3 },
		rate = rate,
		life = { 1, 1.4 },
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

return {
	id = "aura.weapon_sword",
	name = "Weapon Aura Sword",
	kind = "aura",
	tier = "mid",
	host = "weapon",
	refHeight = 3.5,
	tags = { "weapon", "sword", "held", "glint", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "core",
	pieces = {
		gem({ 165, 105, 255 }, 1.8),
		-- (runes rising off the blade, each unfolding, turning and shattering as it goes: the clip)
		wake("runes", "rune_flip", { { 235, 215, 255 }, { 170, 120, 255 } }, 2.5, 0.85, {
			size = { { 0, 0.85 }, { 1, 0.8 } },
			brightness = 1.6,
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			pieces = {
				{
					-- (the whole aura in one picture drawn round the sword's empty shape, from ChatGPT's GIF of this very
					-- sword: gold light ribbons rise up its left edge and pink ones up its right, the gem pulses, a star
					-- flares on the tip at the peak, feathers spiral round; the clip once a life, 1.5 s, one always there,
					-- the next taking over on the clip's dim first frame)
					name = "aura",
					texture = "dawn_aura_flip",
					role = "keep",
					at = "body",
					rate = 1 / 1.5,
					steady = true,
					life = { 1.52, 1.52 },
					-- (the sword's shape is 87% of the picture's height and a particle covers twice its Size: 3.5 / 0.87 / 2)
					size = { { 0, 2 }, { 1, 2 } },
					transparency = { { 0, 0 }, { 1, 0 } },
					-- (stood along the blade by a crawl up it, so the picture leans as the sword leans; VelocityParallel lays
					-- a picture's WIDTH along the flight, so the upright drawing is turned a quarter: lesson 255)
					speed = { 0.05, 0.05 },
					direction = "Top",
					orientation = "VelocityParallel",
					rotation = { -90, -90 },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					lightEmission = 0,
					-- (over the sword's faces: the gem's glow lies on the gem)
					zOffset = 0.3,
					locked = true,
				},
			},
			light = { color = { 255, 210, 150 }, brightness = 1.3, range = 8 },
		},
		legend = {
			pieces = {
				with(gem({ 255, 120, 70 }, 1.6), {
					texture = "sparkStar",
					rate = 3,
					life = { 0.4, 0.6 },
					size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } },
					transparency = { { 0, 0 }, { 1, 0.3 } },
					rotSpeed = { -90, 90 },
					lightEmission = 0.6,
					zOffset = 1,
				}),
				wake("flames", "fire_curl_flip", nil, 5, 1, {
					role = "keep",
					life = { 0.55, 0.7 },
					size = { { 0, 0.5 }, { 0.3, 1 }, { 1, 0.7 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					speed = { 0.3, 0.6 },
					brightness = 1.3,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				-- (a golden sun turning over the point: one always there, breathing as the next takes its place)
				{
					name = "sun",
					texture = "sun_flip",
					color = { 255, 205, 80 },
					at = "crown",
					rate = 1 / 2.2,
					steady = true,
					life = { 2.3, 2.3 },
					-- (each sun shoots out its rays, swells, cracks and sparkles away: the clip, slowed to its life)
					size = { { 0, 1.4 }, { 1, 1.4 } },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					transparency = { { 0, 1 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 1 } },
					rotation = { 0, 0 },
					rotSpeed = { 25, 25 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 0,
					brightness = 1.6,
				},
				wake("embers", "fire_specks", { { 255, 225, 130 }, { 255, 100, 40 } }, 5, 0.45, {
					life = { 0.6, 0.9 },
					speed = { 0.5, 1 },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 255, 140, 70 }, brightness = 1.3, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "rune_flip, sun_flip (ChatGPT clips drawn for the library: tools/chatgpt/clip_frames.py); dawn_aura_flip (ChatGPT's GIF of the Dawnbreaker wearing it, rebuilt by ChatGPT as the effect alone: clip_frames.py --black); free Creator Store pack textures (no scripts: glow_soft, fire_curl_flip, fire_specks); the owner's spark star (sparkStar, tinted)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(swordMeshPart, id, { variant = rarity }) while a core, bramble or legend sword is held; VfxLib.detach(handle) when it is put away. Core is cheap (no light), bramble and legend mid with a small light.",
}
