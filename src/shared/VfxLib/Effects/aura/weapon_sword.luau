-- Weapon Aura Sword: what Goo Lineage's finer swords give off while they are held (core Epic, bramble Mythic, legend
-- Legendary; Common and Uncommon swords have none). Each rung's whole aura is one ChatGPT clip (the owner's way, lesson
-- 284: a GIF of this very sword wearing it, rebuilt as the effect alone round its empty shape) FIXED through the
-- sword's middle, so it turns and tilts with the sword, never with the camera, and the sword hides it where it stands
-- (lessons 291, 292); a few small things of the clip's kind drifting round it, before and behind, give it depth from
-- every side (the owner, 2026-11-13). Core, the Runeblade: a violet glow tracing the edges, lilac diamond runes lighting up the blade,
-- a ribbon circling, runes and sparkles round it. Bramble, the Dawnbreaker: gold and pink light ribbons up the blade,
-- the gem pulsing, a star on the tip, feathers spiralling and drifting off, a warm light. Legend, Sunfire, is built in
-- 3D instead (the owner, 2026-11-13: "I like the colour bands moving round the item, but I want it to feel 3D"): its
-- gems glow, two flame strands wind round the blade from the guard to the tip, glowing sparks fly off it and a soft
-- rainbow light breathes out of it from behind.

-- (the whole aura in one picture drawn round the sword's empty shape, through its middle, the clip once every 1.5 s.
-- `size`: the picture's side in studs, the sword's height over its share of the picture, as clip_frames.py --fit
-- prints it, times two)
local function card(texture, size)
	return { name = "aura", texture = texture, size = size }
end

-- (a few small things of the clip's own kind round the blade, before it, behind it and beside it, held to it as it
-- swings: from the side, where the card is only a line, they still stand round the sword in depth)
local function motes(name, texture, color, over)
	local piece = {
		name = name,
		texture = texture,
		color = color,
		at = "body",
		box = { 1.6, 1, 3.5 },
		rate = 8,
		life = { 1.6, 2.2 },
		size = { { 0, 0 }, { 0.25, 0.16 }, { 0.75, 0.16 }, { 1, 0 } },
		transparency = { { 0, 0.15 }, { 1, 0.35 } },
		speed = { 0.05, 0.2 },
		spread = { 180, 180 },
		rotation = { 0, 359 },
		rotSpeed = { -45, 45 },
		lightEmission = 0.4,
		brightness = 1.4,
	}
	for key, value in over or {} do
		piece[key] = value
	end
	return piece
end

-- (a gem's own light: a soft glow breathing on the gem, a few at once so it never blinks, drawn a little toward the
-- camera so the gem's raised face never hides it. `at`: the gem's middle, studs from the sword's middle)
local function gem(name, at, across, color)
	return {
		name = name,
		texture = "glow_point_b",
		color = color,
		at = "body",
		radius = 0.01,
		pose = { at = at },
		rate = 3,
		life = { 1.2, 1.2 },
		size = { { 0, across * 0.75 }, { 0.5, across }, { 1, across * 0.75 } },
		transparency = { { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } },
		speed = { 0, 0 },
		rotation = { 0, 359 },
		lightEmission = 1,
		brightness = 1.5,
		zOffset = 0.45,
		steady = true,
	}
end

-- (a flame strand wound round the blade from just over the guard to past the tip, its picture running up it; two of
-- them half a turn apart make the fire wrap the blade: the blade hides each where it passes behind. Its body is drawn
-- normal, so the orange holds on a bright sky (added, it burnt white, 2026-11-13 lab); a thin added core of white-gold
-- runs inside it, the fire's hot heart)
local FLAME = {
	texture = "beam_flame_white",
	low = -0.15,
	high = 1.9,
	turns = 2.5,
	flow = 2,
	fade = 0.15,
}

local function flame(name, phase, core)
	local strand = table.clone(FLAME)
	strand.name = name
	strand.phase = phase
	if core then
		strand.color = { { 255, 240, 190 }, { 255, 200, 110 }, { 255, 150, 70 } }
		strand.radius = { 0.6, 0.26 }
		strand.width = { 0.18, 0.08 }
		strand.glow = 0.7
		strand.alpha = 0.2
		strand.zOffset = 0.03
		strand.secondary = true
	else
		strand.color = { { 255, 200, 90 }, { 255, 110, 30 }, { 200, 35, 25 } }
		strand.radius = { 0.6, 0.26 }
		strand.width = { 0.75, 0.3 }
		strand.glow = 1.5
		strand.additive = false
	end
	return strand
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
	cards = { card("runeblade_aura_flip", 3.5) },
	pieces = {
		motes("runes", "rune_flakes", { { 235, 215, 255 }, { 170, 120, 255 } }, {
			flipbook = { layout = "Grid2x2", mode = "Random" },
			rate = 5,
			size = { { 0, 0 }, { 0.25, 0.2 }, { 0.75, 0.2 }, { 1, 0 } },
			rotation = { -15, 15 },
			rotSpeed = { -20, 20 },
			lightEmission = 1,
		}),
		motes("sparks", "star_twinkle", { { 240, 225, 255 }, { 180, 140, 255 } }, {
			size = { { 0, 0 }, { 0.25, 0.12 }, { 0.75, 0.12 }, { 1, 0 } },
			lightEmission = 1,
			secondary = true,
		}),
	},
	variants = {
		core = { tier = "cheap" },
		bramble = {
			cards = { card("dawn_aura_flip", 4.48) },
			pieces = {
				motes("feathers", "down_feather", { { 255, 245, 215 }, { 255, 205, 160 } }, {
					rate = 5,
					size = { { 0, 0 }, { 0.2, 0.2 }, { 0.8, 0.2 }, { 1, 0 } },
					accel = { 0, -0.15, 0 },
					rotSpeed = { -60, 60 },
					lightEmission = 0,
				}),
				motes("sparks", "star_twinkle", { { 255, 245, 220 }, { 255, 170, 195 } }, {
					size = { { 0, 0 }, { 0.25, 0.12 }, { 0.75, 0.12 }, { 1, 0 } },
					lightEmission = 1,
					secondary = true,
				}),
			},
			light = { color = { 255, 210, 150 }, brightness = 1.3, range = 8 },
		},
		-- Sunfire, built in 3D in four steps (the owner, 2026-11-13; the steps and rules:
		-- skills/roblox-vfx-craft/workflows/held-weapon-aura-3d.md): its gems glow, a flame winds round the blade from the
		-- guard to the tip, glowing sparks fly off it, a soft rainbow light breathes out of it. No card.
		legend = {
			cards = {},
			pieces = {
				-- 1. the gems: the big red one in the guard, the red pommel, the small gold diamond on the blade
				gem("gem_guard", { 0, -0.41, 0 }, 0.7, { 255, 95, 70 }),
				gem("gem_pommel", { 0, -1.47, 0 }, 0.5, { 255, 80, 65 }),
				gem("gem_blade", { 0, 0.37, 0 }, 0.22, { 255, 190, 90 }),
				-- 3. glowing sparks thrown off the blade, left in the air as it swings, rising as they cool
				{
					name = "sparks",
					texture = "glow_core",
					color = { { 255, 185, 85 }, { 255, 115, 40 }, { 220, 50, 25 } },
					at = "body",
					box = { 0.35, 0.55, 0.25 },
					pose = { at = { 0, 0.85, 0 } },
					locked = false,
					rate = 12,
					life = { 0.8, 1.4 },
					size = { { 0, 0.08 }, { 0.6, 0.06 }, { 1, 0 } },
					transparency = { { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } },
					speed = { 0.6, 1.4 },
					spread = { 180, 180 },
					drag = 2,
					accel = { 0, 1.2, 0 },
					lightEmission = 1,
					brightness = 1.2,
				},
				-- 4. a soft rainbow light breaking out of the blade's middle: rainbow rays behind the sword, turning
				-- slowly, two at once fading in and out so it breathes; faint, so it never glares
				{
					name = "rainbow",
					texture = "rays_rainbow",
					role = "keep",
					at = "body",
					radius = 0.01,
					pose = { at = { 0, 0.55, 0 } },
					rate = 0.8,
					life = { 2.5, 2.5 },
					size = { { 0, 2 }, { 1, 2.4 } },
					transparency = { { 0, 1 }, { 0.5, 0.82 }, { 1, 1 } },
					speed = { 0, 0 },
					rotation = { 0, 359 },
					rotSpeed = { -12, 12 },
					lightEmission = 1,
					brightness = 1,
					zOffset = -0.5,
					secondary = true,
				},
			},
			-- 2. the flame round the blade: two strands, each with its hot core
			spirals = {
				flame("flame_a", 0),
				flame("flame_b", 0.5),
				flame("core_a", 0, true),
				flame("core_b", 0.5, true),
			},
			light = { color = { 255, 150, 80 }, brightness = 1, range = 8 },
		},
	},
	-- (the preview caught mid-clip, not on its dim first frame)
	markers = { peak = 3.6 },
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "runeblade_aura_flip, dawn_aura_flip (ChatGPT's GIF of each sword wearing it, rebuilt by ChatGPT as the effect alone: tools/chatgpt/clip_frames.py --black --fit); rune_flakes, down_feather (ChatGPT for the library); free Creator Store pack textures (no scripts: star_twinkle, beam_flame_white, glow_point_b, glow_core, rays_rainbow)",
		licence = "the owner's own art (drawn for the library by ChatGPT); Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.attach(swordMeshPart, id, { variant = rarity }) while a core, bramble or legend sword is held; VfxLib.detach(handle) when it is put away. The card lies through the sword's middle (its thin side is the mesh's z). Core is cheap (no light), bramble and legend mid with a small light. Legend has no card: its flame is two spirals of beams round the blade (y is the blade's length), its gem glows sit on Goo Lineage's legend sword mesh (measured from its front shot), its sparks are left in the air as it swings.",
}
