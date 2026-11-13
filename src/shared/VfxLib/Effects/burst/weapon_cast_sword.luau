-- Weapon Cast Sword: the Dash Strike of Goo Lineage's held swords, one design per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). Played once at the sword's head (up along the blade) as the dash cuts.
-- The cut is solid (drawn normal, so it holds on snow), the light added on top; from core up the strike marks the
-- floor under the slime (`ground` pieces). Wood: a brown crescent, chips and a puff of dust. Iron: a steel crescent, a
-- white glint, needle sparks. Core, the Runeblade: a violet crescent and a lilac edge, diamond runes flung out, a rune
-- circle on the floor. Bramble, the Dawnbreaker: a gold crescent and a pink edge, a ring of dawn rays, feathers
-- thrown up, a gold ring racing out on the floor, a warm flash. Legend, Sunfire: a crimson crescent and a gold edge,
-- flames bursting, embers, a golden sun stamped on the floor inside a ring of fire rays, a fire flash.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the cut: a crescent flashing open at the blade and gone in a quarter second)
local function crescent(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.26, 0.26 },
		size = { { 0, size * 0.5 }, { 0.25, size }, { 1, size * 1.15 } },
		transparency = { { 0, 0 }, { 0.5, 0.1 }, { 1, 1 } },
		rotation = { -40, 40 },
		lightEmission = 0,
		brightness = 1.3,
		zOffset = 1,
	}, over)
end

-- (a flash on the point, added)
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.2, 0.2 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (things flung out of the cut, slowing)
local function burst(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.45, 0.7 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		speed = { 4, 8 },
		spread = { 180, 180 },
		drag = 3,
		rotation = { 0, 359 },
		lightEmission = 0,
	}, over)
end

-- (a mark on the floor under the slime: lying flat, opening out and fading)
local function mark(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		ground = true,
		flat = true,
		count = 1,
		life = { 0.85, 0.85 },
		size = { { 0, size * 0.4 }, { 0.2, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0.05 }, { 0.6, 0.2 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.3,
	}, over)
end

-- (a sheet of sixteen small circles: each particle keeps one of them, still)
local ONE_OF = { layout = "Grid4x4", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "burst.weapon_cast_sword",
	name = "Weapon Cast Sword",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "sword", "dash", "strike", "slash", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.12 },
	pieces = {
		crescent("cut", "crescent_moon", { 205, 160, 105 }, 2.6),
		burst("chips", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 10, 0.5, {
			speed = { 4, 8 },
			accel = { 0, -16, 0 },
			rotSpeed = { -300, 300 },
		}),
		burst("dust", "dust_ring", { { 228, 208, 170 } }, 2, 1.2, {
			size = { { 0, 1 }, { 1, 2.4 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			speed = { 0.5, 1 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				-- (steel blue, not white: a white cut is lost on snow; the glint is the white)
				crescent("cut", "crescent_moon", { 170, 192, 225 }, 2.9),
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 1.9),
				burst("sparks", "needle_glow", { { 255, 240, 200 }, { 255, 150, 50 } }, 14, 0.55, {
					life = { 0.2, 0.32 },
					speed = { 9, 15 },
					drag = 4,
					orientation = "VelocityParallel",
					rotation = { -90, -90 }, -- (the vertical needle laid along its flight)
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			pieces = {
				crescent("cut", "crescent_moon", { 170, 105, 255 }, 3.2, { brightness = 1.4 }),
				crescent("edge", "crescent_thin", { 245, 230, 255 }, 3.4, { life = { 0.2, 0.2 }, lightEmission = 1 }),
				-- (each rune unfolds, turns and shatters as it flies: the clip)
				burst("runes", "rune_flip", { { 235, 215, 255 }, { 170, 120, 255 } }, 8, 0.95, {
					life = { 0.65, 0.8 },
					size = { { 0, 0.95 }, { 1, 0.9 } },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					speed = { 3, 6 },
					rotation = { -20, 20 },
					brightness = 1.4,
				}),
				burst("glints", "sparkStar", { { 255, 240, 255 }, { 190, 140, 255 } }, 6, 0.7, {
					speed = { 2, 5 },
					lightEmission = 1,
				}),
				mark("circle", "rune_circle_violet", { 205, 160, 255 }, 4.5, {
					rotSpeed = { 40, 40 },
					lightEmission = 0.4,
					flipbook = ONE_OF,
				}),
			},
		},
		bramble = {
			pieces = {
				crescent("cut", "crescent_moon", { 255, 205, 95 }, 3.4, { brightness = 1.4 }),
				crescent("edge", "crescent_thin", { 255, 175, 190 }, 3.6, { life = { 0.2, 0.2 }, lightEmission = 1 }),
				flash("rays", "ring_rays", { 255, 225, 150 }, 4.5, {
					life = { 0.32, 0.32 },
					size = { { 0, 1.5 }, { 1, 4.5 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				burst("feathers", "down_feather", { { 255, 252, 240 }, { 255, 220, 150 } }, 12, 0.8, {
					life = { 0.8, 1 },
					speed = { 3, 6 },
					accel = { 0, -2, 0 },
					rotSpeed = { -150, 150 },
					brightness = 1.3,
				}),
				mark("ring", "ring_line_b", { 255, 200, 90 }, 6, {
					life = { 0.6, 0.6 },
					size = { { 0, 1 }, { 1, 6.5 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
				}),
			},
			light = { color = { 255, 215, 150 }, keys = { { 0, 0 }, { 0.05, 2.5 }, { 0.45, 0 } }, range = 10 },
		},
		legend = {
			pieces = {
				crescent("cut", "crescent_moon", { 240, 70, 50 }, 4, { brightness = 1.5 }),
				crescent("edge", "crescent_thin", { 255, 225, 130 }, 4.2, { life = { 0.22, 0.22 }, lightEmission = 1 }),
				-- (full-colour fire bursting out of the cut, drawn normal: it burns on snow too)
				burst("flames", "fire_curl_flip", nil, 10, 1.6, {
					role = "keep",
					life = { 0.5, 0.65 },
					size = { { 0, 0.8 }, { 0.3, 1.8 }, { 1, 1.4 } },
					speed = { 3, 6 },
					accel = { 0, 5, 0 },
					rotation = { -20, 20 },
					brightness = 1.3,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				burst("embers", "fire_specks", { { 255, 225, 130 }, { 255, 100, 40 } }, 18, 0.55, {
					speed = { 5, 10 },
					accel = { 0, 3, 0 },
					lightEmission = 1,
				}),
				-- (the floor under the slime: a golden sun stamped inside a ring of crimson fire rays)
				-- (the sun shoots out its rays, swells, cracks and sparkles away: the clip)
				mark("sun", "sun_flip", { 255, 200, 70 }, 4.4, {
					life = { 0.95, 0.95 },
					size = { { 0, 4.4 }, { 1, 4.6 } },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					rotSpeed = { 30, 30 },
					brightness = 1.5,
				}),
				mark("rays", "ring_rays", { 255, 95, 50 }, 7.5, {
					life = { 0.7, 0.7 },
					size = { { 0, 2 }, { 1, 8 } },
					transparency = { { 0, 0 }, { 0.5, 0.2 }, { 1, 1 } },
					lightEmission = 0.3,
				}),
			},
			light = { color = { 255, 140, 60 }, keys = { { 0, 0 }, { 0.05, 4 }, { 0.6, 0 } }, range = 14 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "rune_flip, sun_flip (ChatGPT clips drawn for the library: tools/chatgpt/clip_frames.py); free Creator Store pack textures (no scripts: crescent_moon, crescent_thin, shard_flat, star_glint_sharp, needle_glow, rune_circle_violet, ring_rays, ring_line_b, fire_curl_flip, fire_specks); dust_ring (EffectCraft); down_feather (ChatGPT for the library); the owner's spark star (sparkStar, tinted)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, swordHeadCFrame, { variant = rarity }) as the Dash Strike cuts (the frame's up along the blade). Core, bramble and legend mark the floor straight under the head: pass opts.ground (the floor's height) when the game knows it, else the first floor below is found (characters left out; opts.ignore for more). Wood and iron are cheap, core to legend mid; bramble and legend flash a light.",
}
