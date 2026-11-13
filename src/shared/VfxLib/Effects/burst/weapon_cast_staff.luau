-- Weapon Cast Staff: the Mend of Goo Lineage's Healing Staffs, one design per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). Played once at the staff's head (up along the staff) as the heal is
-- cast: the owner's heal crosses rise out of the head on every rung, and each rung is its own spell, drawn solid so it
-- holds on snow, the light added on top; from core up the Mend marks the floor under the slime (`ground` pieces).
-- Wood: two crosses, green leaves tossed up, a puff of dust. Iron: two crosses, a steel ring opening round the head,
-- sparks. Core, the Enchanted staff: a violet flare, violet sparkles flung out, gold motes rising, three crosses, a
-- violet ring opening on the floor. Bramble, Lifebloom: a burst of teal rays, pink blossoms and petals flung out,
-- four crosses, a teal ring racing out on the floor, a cool flash. Legend, Everbloom: a lily blooming open at the
-- head, golden leaves and daisies thrown up, five crosses, a great golden blossom stamped on the floor inside a ring
-- of gold rays, a warm flash.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a flash on the head, added)
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.25, 0.25 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (things flung out of the head, slowing)
local function burst(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.55, 0.8 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		speed = { 3, 6 },
		spread = { 180, 180 },
		drag = 3,
		rotation = { 0, 359 },
		lightEmission = 0,
	}, over)
end

-- (the owner's heal crosses rising out of the head, never recoloured, fanned well apart so they never rise as one lump)
local function crosses(count, size)
	return {
		name = "crosses",
		texture = "healCross",
		role = "keep",
		count = count,
		life = { 0.65, 0.9 },
		size = { { 0, 0 }, { 0.2, size }, { 1, size * 0.75 } },
		transparency = { { 0, 0 }, { 0.7, 0.15 }, { 1, 1 } },
		speed = { 3.5, 5.5 },
		spread = { 65, 65 },
		direction = "Top",
		accel = { 0, 2, 0 },
		drag = 1,
		rotation = { 0, 0 },
		lightEmission = 0.4,
		zOffset = 1,
	}
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

-- (a sheet of four leaves: each particle keeps one of them, still)
local ONE_LEAF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "burst.weapon_cast_staff",
	name = "Weapon Cast Staff",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "staff", "heal", "mend", "nature", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.15 },
	pieces = {
		crosses(2, 0.7),
		burst("leaves", "leaves_solid", { { 150, 205, 80 }, { 95, 155, 55 } }, 8, 0.6, {
			speed = { 3, 5 },
			direction = "Top",
			spread = { 70, 70 },
			accel = { 0, -6, 0 },
			rotSpeed = { -240, 240 },
			brightness = 1.2,
			flipbook = ONE_LEAF,
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
				crosses(2, 0.75),
				-- (steel blue, not white: a white ring is lost on snow)
				flash("ring", "ring_crisp", { 150, 175, 215 }, 3.4, {
					life = { 0.35, 0.35 },
					size = { { 0, 0.8 }, { 1, 3.4 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
					rotation = { 0, 0 },
					lightEmission = 0.4,
					brightness = 1.3,
					zOffset = 0,
				}),
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
				flash("flare", "star_flare", { 230, 190, 255 }, 3),
				burst("sparkles", "sparkStar", { { 255, 235, 255 }, { 185, 125, 255 } }, 12, 0.75, {
					speed = { 3, 6 },
					rotSpeed = { -120, 120 },
					lightEmission = 1,
				}),
				burst("motes", "glow_dot_small", { { 255, 232, 150 }, { 255, 195, 90 } }, 10, 0.5, {
					size = { { 0, 0 }, { 0.25, 0.5 }, { 1, 0 } },
					speed = { 2, 4 },
					direction = "Top",
					spread = { 70, 70 },
					accel = { 0, 2.5, 0 },
					lightEmission = 1,
				}),
				crosses(3, 0.8),
				mark("ring", "ring_soft", { 190, 135, 255 }, 4.5, {
					rotSpeed = { 30, 30 },
					lightEmission = 0.4,
				}),
			},
		},
		bramble = {
			pieces = {
				flash("rays", "nova_rays", { 200, 255, 230 }, 4.5, {
					life = { 0.32, 0.32 },
					size = { { 0, 1.5 }, { 1, 4.5 } },
					rotSpeed = { -40, 40 },
					zOffset = 0,
				}),
				burst("blossoms", "blossom_five", { { 255, 190, 215 }, { 245, 135, 178 } }, 10, 1, {
					life = { 0.8, 1 },
					accel = { 0, -2, 0 },
					rotSpeed = { -120, 120 },
					brightness = 1.3,
				}),
				burst("petals", "petals_small_flip", { { 255, 205, 225 }, { 255, 155, 192 } }, 14, 0.6, {
					life = { 0.8, 1 },
					speed = { 4, 7 },
					accel = { 0, -1.5, 0 },
					brightness = 1.3,
					flipbook = { layout = "Grid4x4", mode = "Loop", fps = { 8, 12 } },
				}),
				crosses(4, 0.85),
				mark("ring", "ring_crisp", { 90, 225, 190 }, 6, {
					life = { 0.6, 0.6 },
					size = { { 0, 1 }, { 1, 6.5 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
					lightEmission = 0.3,
				}),
			},
			light = { color = { 190, 255, 220 }, keys = { { 0, 0 }, { 0.06, 2.5 }, { 0.5, 0 } }, range = 10 },
		},
		legend = {
			pieces = {
				-- (the Everbloom's lily opening at the head and fading)
				{
					name = "bloom",
					texture = "flower_bloom_flip",
					color = { { 255, 250, 225 }, { 255, 215, 110 } },
					count = 1,
					life = { 0.8, 0.8 },
					size = { { 0, 1 }, { 0.3, 3.4 }, { 1, 3.8 } },
					transparency = { { 0, 0.05 }, { 0.7, 0.15 }, { 1, 1 } },
					rotation = { -15, 15 },
					lightEmission = 0.2,
					brightness = 1.5,
					zOffset = 1,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				},
				burst("leaves", "leaves_solid", { { 255, 222, 95 }, { 228, 165, 40 } }, 16, 0.9, {
					life = { 0.8, 1.1 },
					speed = { 4, 8 },
					accel = { 0, -3, 0 },
					rotSpeed = { -200, 200 },
					brightness = 1.3,
					flipbook = ONE_LEAF,
				}),
				burst("daisies", "daisy_colour", nil, 6, 0.8, {
					role = "keep",
					life = { 0.8, 1.1 },
					speed = { 3, 6 },
					direction = "Top",
					spread = { 70, 70 },
					accel = { 0, -4, 0 },
					rotSpeed = { -120, 120 },
				}),
				crosses(5, 0.9),
				-- (the floor under the slime: a great golden blossom stamped inside a ring of gold rays)
				mark("blossom", "blossom_five", { 255, 215, 110 }, 5.5, {
					life = { 1, 1 },
					size = { { 0, 1.5 }, { 0.15, 5.5 }, { 1, 6 } },
					rotSpeed = { 20, 20 },
					brightness = 1.5,
				}),
				mark("rays", "ring_rays", { 255, 205, 90 }, 7.5, {
					life = { 0.7, 0.7 },
					size = { { 0, 2 }, { 1, 8 } },
					transparency = { { 0, 0 }, { 0.5, 0.2 }, { 1, 1 } },
					lightEmission = 0.3,
				}),
			},
			light = { color = { 255, 225, 140 }, keys = { { 0, 0 }, { 0.06, 4 }, { 0.6, 0 } }, range = 14 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "the owner's heal cross (healCross, never recoloured) and spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: ring_crisp, needle_glow, star_flare, glow_dot_small, ring_soft, nova_rays, petals_small_flip, flower_bloom_flip, ring_rays); dust_ring (EffectCraft); leaves_solid, blossom_five, daisy_colour (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, staffHeadCFrame, { variant = rarity }) as the Mend is cast (the frame's up along the staff). Core, bramble and legend mark the floor straight under the head: pass opts.ground (the floor's height) when the game knows it, else the first floor below is found (characters left out; opts.ignore for more). Wood and iron are cheap, core to legend mid; bramble and legend flash a light.",
}
