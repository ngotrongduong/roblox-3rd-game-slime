-- Weapon Cast Focus: the Arcane Barrage of Goo Lineage's Arcane Focus, one rung per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). Played once at the focus's head (its gem, up along the staff) as the
-- barrage is cast: the gem flares, a rune circle turns open round it and motes of arcane light are sprayed out, and each
-- rung up adds a layer. Wood: a pale blue flare and rune. Iron: steel-blue, its motes. Core: the game's own arcane burst,
-- ring and motes (the owner's art) round a violet rune. Bramble: the same round a green rune, leaves shaken off. Legend:
-- a gold rune and flare over the arcane burst, ring and motes, gold twinkles, a violet flash of light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the gem flaring)
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

-- (a rune circle turning open round the gem)
local function rune(color, size)
	return {
		name = "rune",
		texture = "rune_circle",
		color = color,
		count = 1,
		life = { 0.45, 0.45 },
		size = { { 0, size * 0.4 }, { 0.3, size }, { 1, size * 1.15 } },
		transparency = { { 0, 0 }, { 0.5, 0.2 }, { 1, 1 } },
		rotation = { 0, 359 },
		rotSpeed = { 220, 220 },
		lightEmission = 1,
		zOffset = -0.5,
	}
end

-- (motes of light sprayed out of the gem, slowing)
local function motes(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.3, 0.55 },
		size = { { 0, size }, { 1, 0 } },
		transparency = { { 0, 0 }, { 0.6, 0.15 }, { 1, 1 } },
		speed = { 4, 8 },
		spread = { 180, 180 },
		drag = 4,
		rotation = { 0, 359 },
		lightEmission = 1,
	}, over)
end

-- (the owner's arcane pictures, kept as drawn: the burst, the ring, the motes)
local ARCANE = {
	burst = {
		name = "burst",
		texture = "burstArcane",
		role = "keep",
		count = 1,
		life = { 0.3, 0.3 },
		size = { { 0, 1.4 }, { 0.2, 2.8 }, { 1, 3.4 } },
		transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.5,
		zOffset = 1,
	},
	ring = {
		name = "ring",
		texture = "ringArcane",
		role = "keep",
		count = 1,
		life = { 0.4, 0.4 },
		size = { { 0, 1 }, { 0.35, 3.6 }, { 1, 4.6 } },
		transparency = { { 0, 0 }, { 0.4, 0.15 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.5,
	},
}
local function arcaneMotes(count)
	return motes("motes", "moteArcane", nil, count, 0.6, { role = "keep", lightEmission = 0.5 })
end

return {
	id = "burst.weapon_cast_focus",
	name = "Weapon Cast Focus",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "focus", "arcane", "barrage", "rune", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "additive",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.14 },
	pieces = {
		flash("flash", "flare_star", { 150, 200, 255 }, 1.8),
		rune({ 150, 200, 255 }, 2.4),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				flash("flash", "flare_star", { 130, 170, 240 }, 2),
				rune({ 140, 180, 245 }, 2.6),
				motes("motes", "glow_dot_small", { { 190, 215, 255 }, { 120, 160, 255 } }, 12, 0.45),
			},
		},
		core = {
			pieces = {
				ARCANE.burst,
				ARCANE.ring,
				arcaneMotes(14),
				-- (the rune wider than the owner's burst, or the burst hides it and the three top rungs look alike)
				rune({ 200, 150, 255 }, 3.4),
			},
		},
		bramble = {
			pieces = {
				ARCANE.burst,
				ARCANE.ring,
				arcaneMotes(14),
				rune({ 170, 235, 130 }, 3.8),
				motes("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 7, 0.55, {
					life = { 0.5, 0.8 },
					size = { { 0, 0.55 }, { 1, 0.35 } },
					speed = { 3, 6 },
					accel = { 0, -6, 0 },
					drag = 2,
					rotSpeed = { -200, 200 },
					lightEmission = 0.15,
					flipbook = { layout = "Grid2x2", mode = "Random" },
				}),
			},
		},
		legend = {
			pieces = {
				ARCANE.burst,
				ARCANE.ring,
				arcaneMotes(16),
				rune({ 255, 215, 120 }, 4.2),
				flash("flare", "flare_bright", { 255, 210, 120 }, 2.8),
				motes("twinkles", "star_twinkle", { { 255, 245, 200 }, { 255, 200, 90 } }, 8, 0.7, {
					life = { 0.4, 0.65 },
					size = { { 0, 0 }, { 0.25, 0.7 }, { 1, 0 } },
					speed = { 2, 5 },
				}),
			},
			light = { color = { 190, 120, 255 }, keys = { { 0, 0 }, { 0.05, 3 }, { 0.45, 0 } }, range = 9 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/WEAPONS.md step 3, 2026-11-12)",
		art = "the owner's arcane burst, ring and motes (burstArcane, ringArcane, moteArcane: Goo Lineage's own, kept as drawn); free Creator Store pack textures (no scripts: flare_star, flare_bright, rune_circle, glow_dot_small, star_twinkle); leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, focusHeadCFrame, { variant = rarity }) as the Arcane Barrage is cast (the frame at the gem, up along the staff). Wood and iron are cheap, core to legend mid; only legend has a light.",
}
