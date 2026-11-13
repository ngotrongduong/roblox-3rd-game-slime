-- Weapon Cast Shield: the Taunt of Goo Lineage's held shields, one design per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). Played once at the shield's head (up along it) as the slime raises it and
-- calls the foe: a crest flashes up over the shield, solid (drawn normal, so it holds on snow), the light added on top;
-- from core up the call marks the floor under the slime (`ground` pieces). Wood: the wooden shield itself flashing up,
-- splinters, a puff of dust. Iron: a steel crest, a steel ring ringing out, sparks flying. Core, the Warden: a royal
-- blue crest under a gold one, a ring of gold rays, gold specks, a blue-gold ring racing out on the floor. Bramble, the
-- Aegis of Goo: a green crest over a splash of acid, goo flung out, leaves, a ring of acid on the floor, gold rays, a
-- green flash. Legend, the Royal Bastion: a royal blue crest, a golden crown rising over it, fleurs, banners, castles
-- and crowns flung out, gold specks, an ornate gold ring stamped on the floor inside a ring of rays, a gold flash.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the crest standing up over the shield and growing as it fades)
local function ward(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.45, 0.45 },
		size = { { 0, size * 0.5 }, { 0.2, size }, { 1, size * 1.15 } },
		transparency = { { 0, 0 }, { 0.5, 0.1 }, { 1, 1 } },
		rotation = { 0, 0 },
		orientation = "FacingCameraWorldUp",
		lightEmission = 0,
		brightness = 1.4,
		zOffset = 1,
	}, over)
end

-- (a ring ringing out from the shield, eased out)
local function ring(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.4, 0.4 },
		size = { { 0, width * 0.2 }, { 0.3, width * 0.75 }, { 1, width } },
		transparency = { { 0, 0 }, { 0.4, 0.15 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 0.3,
		brightness = 1.4,
	}, over)
end

-- (a flash behind the crest, added)
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.3, 0.3 },
		size = { { 0, size * 0.3 }, { 1, size } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 0,
	}, over)
end

-- (things flung out of the call, slowing)
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

-- (a sheet of four small pictures: each particle keeps one of them, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "burst.weapon_cast_shield",
	name = "Weapon Cast Shield",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "shield", "taunt", "ward", "ring", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.14 },
	pieces = {
		-- (the owner's wooden shield, as drawn: the Common shield itself raised over the slime)
		ward("ward", "icon_defence", nil, 2.2, { role = "keep", brightness = 1.2 }),
		burst("splinters", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 10, 0.5, {
			accel = { 0, -16, 0 },
			rotSpeed = { -300, 300 },
		}),
		burst("dust", "dust_ring", { { 228, 208, 170 } }, 2, 1.2, {
			size = { { 0, 1 }, { 1, 2.6 } },
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
				-- (steel blue, not white: a white crest is lost on snow)
				ward("ward", "shield_icon", { 150, 175, 215 }, 2.4, { brightness = 1.3 }),
				ring("ring", "ring_crisp", { 150, 180, 230 }, 4.8),
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
				ward("ward", "shield_icon", { 70, 125, 250 }, 3, { brightness = 1.5 }),
				-- (a gold crest flaring over the blue one, a little wider: the Warden's gold rim)
				ward("rim", "shield_icon", { 255, 215, 90 }, 3.3, {
					life = { 0.3, 0.3 },
					transparency = { { 0, 0.2 }, { 0.4, 0.3 }, { 1, 1 } },
					lightEmission = 1,
					zOffset = 0.5,
				}),
				flash("rays", "ring_rays", { 255, 220, 120 }, 5, { delay = 0.04 }),
				burst("specks", "spec_star", { { 255, 245, 200 }, { 255, 205, 80 } }, 12, 0.55, {
					speed = { 3, 7 },
					lightEmission = 1,
				}),
				mark("ring", "ring_crisp", { 120, 170, 255 }, 5, {
					life = { 0.55, 0.55 },
					size = { { 0, 1 }, { 1, 5.5 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
					lightEmission = 0.3,
					brightness = 1.4,
				}),
			},
		},
		bramble = {
			pieces = {
				ward("ward", "shield_icon", { 90, 200, 70 }, 3.2, { brightness = 1.5 }),
				-- (the owner's acid splash behind the crest, as drawn)
				ward("splash", "acidSplat", nil, 3.2, {
					role = "keep",
					size = { { 0, 1.2 }, { 0.2, 3 }, { 1, 3.4 } },
					rotation = { 0, 359 },
					orientation = "FacingCamera",
					brightness = 1.2,
					zOffset = 0,
				}),
				burst("goo", "gooBlob", nil, 6, 0.95, {
					role = "keep",
					speed = { 5, 9 },
					accel = { 0, -14, 0 },
					rotSpeed = { -120, 120 },
					brightness = 1.2,
				}),
				burst("leaves", "leaves_solid", { { 150, 215, 80 }, { 90, 170, 60 } }, 10, 0.75, {
					life = { 0.7, 0.95 },
					speed = { 4, 7 },
					accel = { 0, -4, 0 },
					rotSpeed = { -200, 200 },
					brightness = 1.2,
					flipbook = ONE_OF,
				}),
				flash("rays", "ring_rays", { 255, 225, 120 }, 5.2, { delay = 0.04 }),
				-- (the owner's ring of acid racing out on the floor, as drawn)
				mark("ring", "ringAcid", nil, 5, {
					role = "keep",
					life = { 0.7, 0.7 },
					size = { { 0, 1.5 }, { 0.2, 4.5 }, { 1, 5.5 } },
					brightness = 1.2,
				}),
			},
			light = { color = { 150, 255, 110 }, keys = { { 0, 0 }, { 0.05, 2.5 }, { 0.45, 0 } }, range = 10 },
		},
		legend = {
			pieces = {
				ward("ward", "shield_icon", { 60, 100, 240 }, 3.6, { brightness = 1.6 }),
				-- (a golden crown rising over the crest: it grows from a spark point by point, glints, breaks into sparkles)
				{
					name = "crown",
					texture = "crown_flip",
					color = { 255, 205, 80 },
					count = 1,
					life = { 0.95, 0.95 },
					size = { { 0, 2.4 }, { 1, 2.6 } },
					transparency = { { 0, 0 }, { 0.9, 0 }, { 1, 1 } },
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
					speed = { 3, 3 },
					direction = "Top",
					spread = { 0, 0 },
					drag = 3,
					rotation = { 0, 0 },
					orientation = "FacingCameraWorldUp",
					lightEmission = 0,
					brightness = 1.6,
					zOffset = 2,
				},
				-- (the Bastion's arms flung out: each a fleur-de-lis growing from a spark, glinting, splitting)
				burst("arms", "royal_flip", { { 255, 228, 130 }, { 255, 190, 60 } }, 7, 1.1, {
					life = { 0.7, 0.9 },
					size = { { 0, 1.1 }, { 1, 1.05 } },
					speed = { 4, 8 },
					rotation = { -15, 15 },
					brightness = 1.5,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				burst("specks", "spec_star", { { 255, 245, 200 }, { 255, 205, 80 } }, 16, 0.55, {
					speed = { 5, 10 },
					lightEmission = 1,
				}),
				-- (the floor under the slime: an ornate gold ring stamped inside a ring of gold rays)
				mark("seal", "rune_ring_ornate", { 255, 210, 90 }, 6.5, {
					life = { 0.95, 0.95 },
					size = { { 0, 2 }, { 0.15, 6.5 }, { 1, 7 } },
					rotSpeed = { 30, 30 },
					brightness = 1.5,
				}),
				mark("rays", "ring_rays", { 255, 200, 80 }, 8, {
					life = { 0.7, 0.7 },
					size = { { 0, 2 }, { 1, 8 } },
					transparency = { { 0, 0 }, { 0.5, 0.2 }, { 1, 1 } },
					lightEmission = 0.3,
				}),
			},
			light = { color = { 255, 215, 120 }, keys = { { 0, 0 }, { 0.05, 4 }, { 0.6, 0 } }, range = 14 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "royal_flip, crown_flip (ChatGPT clips drawn for the library: tools/chatgpt/clip_frames.py); free Creator Store pack textures (no scripts: shield_icon, shard_flat, ring_crisp, needle_glow, ring_rays, spec_star, rune_ring_ornate); dust_ring (EffectCraft); leaves_solid (ChatGPT for the library); the owner's shield icon (icon_defence), acid splash (acidSplat), goo blob (gooBlob) and acid ring (ringAcid), all kept as drawn",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, shieldHeadCFrame, { variant = rarity }) as the Taunt is called (the frame's up along the shield). Core, bramble and legend mark the floor straight under the head: pass opts.ground (the floor's height) when the game knows it, else the first floor below is found (characters left out; opts.ignore for more). Wood and iron are cheap, core to legend mid; bramble and legend flash a light.",
}
