-- Weapon Hit Shield: a plain blow of one of Goo Lineage's shields, a blunt SLAM. A crest of the shield stamped on the
-- foe's skin (solid, growing as it fades), a ring of force punched out across the blow, what the shield is made of
-- thrown back. Drawn normal in a coloured body so it holds on snow. Wood: a plank crest, splinters, a puff of dust. Iron:
-- a grey crest and a ring, rim sparks. Core (Warden): a royal blue crest with a gold rim, a gold ring, gold specks.
-- Bramble (Aegis of Goo): a green crest, the owner's acid splash and goo drops, leaves, the owner's acid ring on the
-- floor. Legend (Royal Bastion): a gold crest, royal arms unfolding, a ring of gold, specks, a seal on the floor.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the crest stamped on the skin: it lands big and settles, growing as it fades)
local function crest(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.3, 0.3 },
		size = { { 0, size * 1.25 }, { 0.2, size * 0.95 }, { 1, size * 1.15 } },
		transparency = { { 0, 0 }, { 0.55, 0.1 }, { 1, 1 } },
		rotation = { 0, 0 },
		lightEmission = 0,
		brightness = 1.25,
		zOffset = 1,
	}, over)
end

-- (a ring of force, flying out across the blow)
local function ring(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.26, 0.26 },
		size = { { 0, size * 0.25 }, { 0.5, size * 0.85, 0 }, { 1, size } },
		transparency = { { 0, 0.05 }, { 0.5, 0.2 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.4,
		brightness = 1.2,
		zOffset = 0.5,
	}, over)
end

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
		speed = { 4, 9 },
		spread = { 70, 70 },
		drag = 3,
		rotation = { 0, 359 },
		lightEmission = 0,
	}, over)
end

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

local ONE_OF = { layout = "Grid4x4", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "hit.weapon_shield",
	name = "Weapon Hit Shield",
	kind = "hit",
	tier = "mid",
	host = "any",
	refHeight = 2.2,
	tags = { "weapon", "shield", "slam", "bash", "impact", "rarity", "ladder", "goo_lineage", "snow_safe" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.06 },
	pieces = {
		crest("crest", "icon_defence", nil, 2.1, { role = "keep" }),
		spray("splinters", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 8, 0.45, {
			accel = { 0, -14, 0 },
			rotSpeed = { -300, 300 },
		}),
		spray("dust", "dust_ring", { 228, 208, 170 }, 2, 1.1, {
			size = { { 0, 0.9 }, { 1, 2.2 } },
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
				crest("crest", "shield_icon", { 130, 150, 175 }, 2.3),
				ring("ring", "ring_crisp", { 160, 185, 215 }, 3.6),
				spray("sparks", "needle_glow", { { 255, 240, 200 }, { 255, 160, 60 } }, 12, 0.5, {
					life = { 0.15, 0.28 },
					speed = { 8, 15 },
					spread = { 80, 80 },
					drag = 4,
					orientation = "VelocityParallel",
					rotation = { -90, -90 },
					lightEmission = 0.8,
				}),
			},
		},
		core = {
			pieces = {
				crest("crest", "shield_icon", { 60, 110, 230 }, 2.6, { brightness = 1.35 }),
				crest("rim", "shield_icon", { 255, 205, 80 }, 3, {
					life = { 0.22, 0.22 },
					transparency = { { 0, 0.2 }, { 1, 1 } },
					lightEmission = 1,
					zOffset = 2,
				}),
				ring("ring", "ring_crisp", { 255, 200, 80 }, 4.4),
				spray("specks", "spec_star", { { 255, 235, 150 }, { 255, 200, 80 } }, 10, 0.5, {
					speed = { 5, 10 },
					lightEmission = 1,
				}),
			},
		},
		bramble = {
			pieces = {
				-- (the owner's acid splash, as drawn, behind a green crest)
				crest("splash", "acidSplat", nil, 3.3, { role = "keep", life = { 0.34, 0.34 }, zOffset = 0 }),
				crest("crest", "shield_icon", { 70, 170, 80 }, 2.5, { brightness = 1.3 }),
				spray("goo", "gooBlob", nil, 6, 0.8, { role = "keep", life = { 0.34, 0.4 }, accel = { 0, -12, 0 } }),
				spray("leaves", "leaves_solid", { { 120, 215, 100 }, { 70, 150, 60 } }, 8, 0.6, {
					rotSpeed = { -200, 200 },
					flipbook = ONE_OF,
				}),
				mark("ring", "ringAcid", nil, 5, { role = "keep" }),
			},
			light = { color = { 140, 255, 130 }, keys = { { 0, 0 }, { 0.05, 1.8 }, { 0.35, 0 } }, range = 8 },
		},
		legend = {
			pieces = {
				crest("crest", "shield_icon", { 255, 195, 60 }, 2.9, { brightness = 1.5 }),
				-- (the royal arms unfold, flare and scatter: the clip)
				crest("arms", "royal_flip", { 255, 235, 170 }, 3.4, {
					life = { 0.4, 0.4 },
					size = { { 0, 3.4 }, { 1, 3.6 } },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					transparency = { { 0, 0 }, { 0.9, 0 }, { 1, 1 } },
					zOffset = 2,
					brightness = 1.5,
				}),
				ring("ring", "ring_crisp", { 255, 215, 90 }, 5.4, { lightEmission = 0.7 }),
				spray("specks", "spec_star", { { 255, 245, 190 }, { 255, 205, 80 } }, 16, 0.55, {
					speed = { 6, 12 },
					lightEmission = 1,
				}),
				mark("seal", "rune_ring_ornate", { 255, 205, 80 }, 6, { lightEmission = 0.3 }),
			},
			light = { color = { 255, 215, 130 }, keys = { { 0, 0 }, { 0.05, 3 }, { 0.4, 0 } }, range = 10 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's plain weapon blows (2026-11-14, wave 2 of the game's fight effects)",
		art = "royal_flip (ChatGPT clip drawn for the library); the owner's battle art (icon_defence, acidSplat, gooBlob, ringAcid) as drawn; free Creator Store pack textures (no scripts kept: shield_icon, ring_crisp, shard_flat, needle_glow, spec_star, leaves_solid, rune_ring_ornate); dust_ring (EffectCraft)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play('hit.weapon_shield', CFrame.lookAt(skin, skin + blowDirection), { variant = rarity, scale = foeHeight / 2.2 }): at the foe's skin, -Z along the blow. 0.3 to 0.4 s. Wood and iron are cheap, core to legend mid; bramble and legend flash a light and mark the floor.",
}
