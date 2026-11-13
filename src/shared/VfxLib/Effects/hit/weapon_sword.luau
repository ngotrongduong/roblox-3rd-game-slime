-- Weapon Hit Sword: the moment a plain blow of one of Goo Lineage's swords lands, one design per rarity (wood Common,
-- iron Uncommon, core Epic, bramble Mythic, legend Legendary). Played at the foe's skin, -Z along the blow. A CUT: a
-- solid crescent flashing open across the blow and gone in a fifth of a second, sparks thrown back at the attacker.
-- Drawn normal in a coloured body (and a dark under-copy where the rung has the pieces), the white only a glint on top,
-- so it holds on the Frozen Ice snow as on the dark maps. Wood: a tan cut and chips. Iron: a steel cut with a dark edge,
-- a white glint, needle sparks. Core (Runeblade): violet cut and lilac edge, runes unfolding, glints. Bramble
-- (Dawnbreaker): gold cut, pink edge, a flash of dawn rays, feathers. Legend (Sunfire): a crimson cut and gold edge,
-- flames, embers, a gold ring of fire laid on the floor under the foe.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the cut: a crescent flashing open across the blow)
local function cut(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.2, 0.2 },
		size = { { 0, size * 0.55 }, { 0.25, size }, { 1, size * 1.12 } },
		transparency = { { 0, 0 }, { 0.5, 0.1 }, { 1, 1 } },
		rotation = { -35, 35 },
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
		life = { 0.16, 0.16 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (things thrown back at the attacker, slowing)
local function spray(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.25, 0.4 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		direction = "Back",
		speed = { 5, 10 },
		spread = { 55, 55 },
		drag = 3,
		rotation = { 0, 359 },
		lightEmission = 0,
	}, over)
end

-- (a mark on the floor under the foe)
local function mark(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		ground = true,
		flat = true,
		count = 1,
		life = { 0.4, 0.4 },
		size = { { 0, size * 0.4 }, { 0.3, size }, { 1, size * 1.1 } },
		transparency = { { 0, 0.05 }, { 0.6, 0.25 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0,
		brightness = 1.3,
	}, over)
end

return {
	id = "hit.weapon_sword",
	name = "Weapon Hit Sword",
	kind = "hit",
	tier = "mid",
	host = "any",
	refHeight = 2.2,
	tags = { "weapon", "sword", "cut", "slash", "impact", "rarity", "ladder", "goo_lineage", "snow_safe" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.08 },
	pieces = {
		cut("cut", "crescent_moon", { 205, 150, 90 }, 2.4),
		spray("chips", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 8, 0.4, {
			accel = { 0, -14, 0 },
			rotSpeed = { -300, 300 },
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				-- (steel blue, not white: a white cut is lost on snow; the glint is the white)
				cut("cut", "crescent_moon", { 120, 150, 200 }, 2.8),
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 1.7),
				spray("sparks", "needle_glow", { { 255, 240, 200 }, { 255, 150, 50 } }, 14, 0.5, {
					life = { 0.15, 0.28 },
					speed = { 9, 16 },
					drag = 4,
					orientation = "VelocityParallel",
					rotation = { -90, -90 },
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			pieces = {
				cut("cut", "crescent_moon", { 150, 85, 235 }, 3, { brightness = 1.4 }),
				cut("edge", "crescent_thin", { 245, 230, 255 }, 3.2, { life = { 0.16, 0.16 }, lightEmission = 1 }),
				spray("runes", "rune_flip", { { 235, 215, 255 }, { 170, 120, 255 } }, 5, 0.8, {
					life = { 0.38, 0.4 },
					size = { { 0, 0.8 }, { 1, 0.75 } },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					speed = { 2, 4 },
					rotation = { -20, 20 },
					brightness = 1.4,
				}),
				spray("glints", "sparkStar", { { 255, 240, 255 }, { 190, 140, 255 } }, 8, 0.55, {
					speed = { 4, 9 },
					lightEmission = 1,
				}),
			},
		},
		bramble = {
			pieces = {
				cut("cut", "crescent_moon", { 245, 190, 70 }, 3.4, { brightness = 1.4 }),
				cut("edge", "crescent_thin", { 255, 160, 185 }, 3.6, { life = { 0.17, 0.17 }, lightEmission = 1 }),
				flash("rays", "ring_rays", { 255, 215, 140 }, 4.2, {
					life = { 0.24, 0.24 },
					size = { { 0, 1.3 }, { 1, 4.2 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				spray("feathers", "down_feather", { { 255, 250, 235 }, { 255, 215, 140 } }, 9, 0.75, {
					life = { 0.35, 0.4 },
					speed = { 3, 6 },
					accel = { 0, -3, 0 },
					rotSpeed = { -200, 200 },
					brightness = 1.3,
				}),
				spray("motes", "sparkStar", { 255, 230, 150 }, 8, 0.5, { speed = { 5, 10 }, lightEmission = 1 }),
			},
			light = { color = { 255, 215, 150 }, keys = { { 0, 0 }, { 0.06, 2 }, { 0.4, 0 } }, range = 8 },
		},
		legend = {
			pieces = {
				cut("cut", "crescent_moon", { 225, 55, 40 }, 3.8, { brightness = 1.5 }),
				cut("edge", "crescent_thin", { 255, 220, 120 }, 4, { life = { 0.18, 0.18 }, lightEmission = 1 }),
				-- (full-colour fire bursting out of the cut, drawn normal: it burns on snow too)
				spray("flames", "fire_curl_flip", nil, 6, 1.5, {
					role = "keep",
					life = { 0.36, 0.4 },
					size = { { 0, 0.8 }, { 0.3, 1.7 }, { 1, 1.3 } },
					speed = { 2, 5 },
					accel = { 0, 6, 0 },
					rotation = { -20, 20 },
					brightness = 1.3,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				spray("embers", "fire_specks", { { 255, 225, 130 }, { 255, 100, 40 } }, 16, 0.5, {
					speed = { 6, 12 },
					accel = { 0, 4, 0 },
					lightEmission = 1,
				}),
				mark("sun", "ring_rays", { 255, 120, 45 }, 6.5, {
					size = { { 0, 1.5 }, { 1, 7 } },
					lightEmission = 0.3,
				}),
			},
			light = { color = { 255, 140, 60 }, keys = { { 0, 0 }, { 0.06, 3 }, { 0.4, 0 } }, range = 10 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's plain weapon blows (2026-11-14, wave 2 of the game's fight effects)",
		art = "rune_flip (ChatGPT clip drawn for the library); free Creator Store pack textures (no scripts kept: crescent_moon, crescent_thin, shard_flat, star_glint_sharp, needle_glow, ring_rays, fire_curl_flip, fire_specks); down_feather (ChatGPT for the library); the owner's spark star (sparkStar)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play('hit.weapon_sword', CFrame.lookAt(skin, skin + blowDirection), { variant = rarity, scale = foeHeight / 2.2 }): at the foe's skin, -Z along the blow. 0.2 to 0.4 s. Wood and iron are cheap (every blow of up to eight fighters), core and bramble mid, legend mid with the floor ring and a light. Drawn solid so it reads on snow.",
}
