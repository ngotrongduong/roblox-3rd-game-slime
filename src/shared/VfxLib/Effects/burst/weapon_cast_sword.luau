-- Weapon Cast Sword: the Dash Strike of Goo Lineage's held swords, one rung per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). Played once at the sword's head (up along the blade) as the dash cuts: a
-- crescent of the cut flashes at the blade and needle sparks are thrown off it, and each rung up adds a layer. Wood: a
-- pale crescent and sparks. Iron: a steel crescent, a glint on the point. Core: a violet crescent with a white edge, a
-- violet star of impact, violet motes. Bramble: green and gold, leaves torn off. Legend: a crimson crescent with a gold
-- edge, a gold flare and shock ring, embers and twinkles, a flash of light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the cut: a crescent flashing open at the blade and gone in a fifth of a second)
local function crescent(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.22, 0.22 },
		size = { { 0, size * 0.5 }, { 0.25, size }, { 1, size * 1.15 } },
		transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
		rotation = { -40, 40 },
		lightEmission = 1,
		zOffset = 1,
	}, over)
end

-- (a star of the blow on the point)
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.18, 0.18 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (needle sparks thrown off the cut, lying along their flight)
local function sparks(color, count)
	return {
		name = "sparks",
		texture = "needle_glow",
		color = color,
		count = count,
		life = { 0.18, 0.3 },
		size = { { 0, 0.55 }, { 1, 0 } },
		speed = { 9, 15 },
		spread = { 180, 180 },
		drag = 4,
		orientation = "VelocityParallel",
		-- (VelocityParallel lays a picture's width along its flight: the vertical needle turned a quarter lies along it)
		rotation = { -90, -90 },
		lightEmission = 1,
	}
end

-- (small things flung out of the cut, slowing and drifting)
local function shed(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.4, 0.65 },
		size = { { 0, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.6, 0.15 }, { 1, 1 } },
		speed = { 3, 6 },
		spread = { 180, 180 },
		drag = 3,
		rotation = { 0, 359 },
		lightEmission = 1,
	}, over)
end

return {
	id = "burst.weapon_cast_sword",
	name = "Weapon Cast Sword",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "sword", "dash", "strike", "slash", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.1 },
	pieces = {
		crescent("cut", "crescent_moon", { 236, 206, 160 }, 2.6),
		sparks({ { 255, 235, 200 }, { 220, 180, 120 } }, 8),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				crescent("cut", "crescent_moon", { 200, 220, 245 }, 2.8),
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 1.6),
				sparks({ { 255, 255, 255 }, { 180, 200, 235 } }, 10),
			},
		},
		core = {
			pieces = {
				crescent("cut", "crescent_moon", { 175, 115, 255 }, 3.2),
				crescent("edge", "crescent_thin", { 245, 235, 255 }, 3.4, { life = { 0.18, 0.18 } }),
				flash("star", "impact_star", { 190, 140, 255 }, 2),
				sparks({ { 225, 190, 255 }, { 160, 100, 255 } }, 12),
			},
		},
		bramble = {
			pieces = {
				crescent("cut", "crescent_moon", { 150, 215, 80 }, 3.3),
				crescent("edge", "crescent_thin", { 255, 225, 130 }, 3.5, { life = { 0.18, 0.18 } }),
				flash("star", "impact_star", { 255, 215, 110 }, 2.2),
				sparks({ { 255, 235, 160 }, { 255, 200, 80 } }, 12),
				shed("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 8, 0.6, {
					accel = { 0, -6, 0 },
					rotSpeed = { -200, 200 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				}),
			},
		},
		legend = {
			pieces = {
				-- (bright: a deep crimson adds little to a dark map and read smaller than bramble's green)
				crescent("cut", "crescent_moon", { 255, 150, 60 }, 4.2),
				crescent("edge", "crescent_thin", { 255, 225, 140 }, 4.4, { life = { 0.2, 0.2 } }),
				flash("flare", "flare_bright", { 255, 200, 100 }, 3),
				flash("ring", "shockwave", { 255, 190, 90 }, 5, {
					life = { 0.3, 0.3 },
					size = { { 0, 1 }, { 1, 5 } },
					transparency = { { 0, 0.1 }, { 1, 1 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				shed("embers", "fire_specks", { { 255, 210, 110 }, { 255, 90, 40 } }, 16, 0.5, { accel = { 0, 3, 0 } }),
				shed("twinkles", "star_twinkle", { { 255, 240, 190 }, { 255, 190, 80 } }, 8, 0.7, {
					size = { { 0, 0 }, { 0.25, 0.7 }, { 1, 0 } },
				}),
			},
			light = { color = { 255, 170, 80 }, keys = { { 0, 0 }, { 0.05, 3 }, { 0.4, 0 } }, range = 8 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "free Creator Store pack textures (no scripts: crescent_moon, crescent_thin, star_glint_sharp, impact_star, needle_glow, flare_bright, fire_specks, star_twinkle); the owner's shock ring (shockwave, tinted); leaves_solid (ChatGPT for the library)",
		licence = "Creator Store free assets (no scripts kept); the owner's own art",
	},
	notes = "VfxLib.play(id, swordHeadCFrame, { variant = rarity }) as the Dash Strike cuts (the frame's up along the blade). Wood and iron are cheap, core to legend mid; only legend has a light.",
}
