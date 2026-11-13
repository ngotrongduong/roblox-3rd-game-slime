-- Weapon Cast Kit: the Acid Rain of Goo Lineage's Alchemy Kit, one design per rarity (wood Common, iron Uncommon, core
-- Epic, bramble Mythic, legend Legendary). Played once at the kit's head (its handle end, up along it) as the potion is
-- thrown up: the game's own acid drops fly up high, to come down as the rain, and each rung throws its own potion with
-- them. The splash is solid (drawn normal, so it holds on snow), the light added on top; from core up the throw marks
-- the floor under the slime (`ground` pieces). Wood: a red and blue potion splashing out, its drops flung up, a puff of
-- dust. Iron: a cork popped off a steel flask: a white glint, needle sparks, the acid flung up. Core, the Alchemist's
-- Satchel: a violet splash, purple bubbles and a fizz of motes rising, a small violet ring on the floor. Bramble, the
-- Philosopher's Kit: a green flash of rays, the four alchemy signs flung out, the acid, a gold transmutation circle
-- turning on the floor, a green light. Legend, the Grand Elixir Pack: big rainbow bubbles and golden flasks bursting
-- out, a gold flare, the acid, a rainbow ring of rays racing over the floor, twinkles, a violet light.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a flash on the throw, added)
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

-- (things thrown up out of the kit, slowing, falling back)
local function burst(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = count,
		life = { 0.5, 0.75 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		speed = { 4, 8 },
		spread = { 60, 60 },
		direction = "Top",
		drag = 2,
		rotation = { 0, 359 },
		lightEmission = 0,
		zOffset = 1,
	}, over)
end

-- (drops of the game's acid flung up high, falling back: the rain to come; kept as drawn)
local function acid(count)
	return burst("acid", "acidDrop", nil, count, 0.55, {
		role = "keep",
		size = { { 0, 0.55 }, { 1, 0.4 } },
		transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
		speed = { 11, 16 },
		spread = { 30, 30 },
		drag = 0,
		accel = { 0, -30, 0 },
		rotation = { 0, 0 },
		zOffset = 2,
	})
end

-- (bubbles fizzing up out of the kit)
local function bubbles(color, count, size, over)
	return burst(
		"bubbles",
		"bubble_gloss",
		color,
		count,
		size,
		with({
			life = { 0.55, 0.85 },
			size = { { 0, size * 0.4 }, { 0.3, size }, { 1, size * 0.75 } },
			speed = { 3, 6 },
			accel = { 0, 3, 0 },
			brightness = 1.3,
		}, over)
	)
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

-- (the signs and the flasks are ChatGPT clips: each particle plays its clip once over its life)
local ONCE = { layout = "Grid4x4", mode = "OneShot" }

return {
	id = "burst.weapon_cast_kit",
	name = "Weapon Cast Kit",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "alchemy", "kit", "acid", "rain", "potion", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.15 },
	pieces = {
		-- (the red and blue potions splashed out of the bag, drawn normal so they hold on snow)
		burst("splash", "droplet_gloss", { { 240, 90, 75 }, { 70, 120, 235 } }, 14, 0.6, {
			speed = { 6, 11 },
			spread = { 45, 45 },
			drag = 0,
			accel = { 0, -24, 0 },
			orientation = "VelocityParallel",
			rotation = { 180, 180 }, -- (the point trailing its flight)
			brightness = 1.2,
		}),
		acid(6),
		burst("dust", "dust_ring", { { 220, 196, 160 } }, 2, 1.2, {
			size = { { 0, 1 }, { 1, 2.4 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			speed = { 0.5, 1 },
			spread = { 180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				-- (the cork popped off a steel flask: the white glint, sparks racing off the rim)
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 2),
				burst("sparks", "needle_glow", { { 255, 240, 200 }, { 255, 150, 50 } }, 14, 0.55, {
					life = { 0.2, 0.32 },
					speed = { 9, 15 },
					spread = { 70, 70 },
					drag = 4,
					orientation = "VelocityParallel",
					rotation = { -90, -90 }, -- (the vertical needle laid along its flight)
					lightEmission = 0.8,
				}),
				acid(9),
			},
		},
		core = {
			pieces = {
				flash("spark", "sparkStar", { 215, 160, 255 }, 2.2, { lightEmission = 0.8 }),
				bubbles({ { 225, 175, 255 }, { 175, 110, 255 } }, 12, 0.75),
				-- (the fizz: lilac motes racing up)
				burst("fizz", "glow_dot_small", { { 240, 215, 255 }, { 180, 120, 255 } }, 18, 0.5, {
					life = { 0.35, 0.55 },
					speed = { 6, 10 },
					spread = { 35, 35 },
					drag = 3,
					lightEmission = 1,
				}),
				acid(10),
				mark("ring", "ring_line_b", { 190, 130, 255 }, 3.2, {
					life = { 0.6, 0.6 },
					size = { { 0, 0.8 }, { 1, 3.6 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
					lightEmission = 0.3,
				}),
			},
		},
		bramble = {
			pieces = {
				flash("rays", "ring_rays", { 150, 255, 180 }, 4.5, {
					life = { 0.32, 0.32 },
					size = { { 0, 1.5 }, { 1, 4.5 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				-- (alchemy sigils flung out of the kit, gold on the green: each draws itself, glints, bursts into bubbles)
				burst("signs", "alchemy_flip", { { 255, 230, 140 }, { 150, 245, 190 } }, 6, 0.95, {
					life = { 0.7, 0.9 },
					size = { { 0, 0.95 }, { 1, 0.9 } },
					speed = { 3, 6 },
					spread = { 90, 90 },
					rotation = { -20, 20 },
					brightness = 1.4,
					flipbook = ONCE,
				}),
				acid(12),
				burst("motes", "glow_dot_small", { { 190, 255, 215 }, { 80, 230, 160 } }, 14, 0.55, {
					speed = { 3, 7 },
					spread = { 180, 180 },
					lightEmission = 1,
				}),
				-- (the floor under the slime: a gold transmutation circle turning as it opens)
				mark("circle", "rune_circle", { 255, 205, 90 }, 5.5, {
					life = { 0.95, 0.95 },
					size = { { 0, 1.5 }, { 0.2, 5.5 }, { 1, 6 } },
					rotSpeed = { 40, 40 },
					lightEmission = 0.4,
					brightness = 1.5,
				}),
			},
			light = { color = { 150, 255, 190 }, keys = { { 0, 0 }, { 0.05, 2.5 }, { 0.45, 0 } }, range = 10 },
		},
		legend = {
			pieces = {
				flash("flare", "star_flare", { 255, 235, 200 }, 3.6, { life = { 0.25, 0.25 } }),
				-- (big elixir bubbles, each going round the rainbow as it rises)
				bubbles(
					{ { 255, 130, 130 }, { 255, 220, 110 }, { 120, 235, 160 }, { 120, 175, 255 }, { 210, 140, 255 } },
					14,
					1.4,
					{ life = { 0.7, 1 }, speed = { 4, 8 }, spread = { 80, 80 } }
				),
				-- (golden flasks thrown up out of the pack: each pops up, sloshes, pops its cork, bursts into bubbles)
				burst("flasks", "flask_flip", { { 255, 225, 130 }, { 255, 185, 70 } }, 5, 1.3, {
					life = { 0.8, 1 },
					size = { { 0, 1.3 }, { 1, 1.25 } },
					speed = { 5, 9 },
					accel = { 0, -6, 0 },
					rotation = { -20, 20 },
					rotSpeed = { -40, 40 },
					brightness = 1.5,
					flipbook = ONCE,
				}),
				acid(12),
				-- (the floor under the slime: a ring of rays racing out, going round the rainbow)
				mark(
					"rays",
					"ring_rays",
					{ { 255, 120, 120 }, { 255, 215, 100 }, { 120, 235, 160 }, { 120, 170, 255 }, { 210, 130, 255 } },
					7.5,
					{
						life = { 0.8, 0.8 },
						size = { { 0, 2 }, { 1, 8 } },
						transparency = { { 0, 0 }, { 0.5, 0.2 }, { 1, 1 } },
						lightEmission = 0.3,
					}
				),
				burst("twinkles", "star_twinkle", { { 255, 250, 225 }, { 255, 200, 90 } }, 12, 0.65, {
					size = { { 0, 0 }, { 0.25, 0.65 }, { 1, 0 } },
					speed = { 2, 6 },
					spread = { 180, 180 },
					lightEmission = 1,
				}),
			},
			light = { color = { 215, 150, 255 }, keys = { { 0, 0 }, { 0.05, 3.5 }, { 0.6, 0 } }, range = 13 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "alchemy_flip, flask_flip (ChatGPT clips drawn for the library: tools/chatgpt/clip_frames.py); the owner's acid drop (acidDrop: Goo Lineage's own, kept as drawn); the owner's spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: star_glint_sharp, needle_glow, glow_dot_small, ring_line_b, ring_rays, rune_circle, star_flare, star_twinkle); dust_ring (EffectCraft); bubble_gloss, droplet_gloss (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, kitHeadCFrame, { variant = rarity }) as the Acid Rain potion is thrown (the frame at the kit's handle end, up along it): the drops fly up, the game's rain falls after. Core, bramble and legend mark the floor straight under the head: pass opts.ground (the floor's height) when the game knows it, else the first floor below is found (characters left out; opts.ignore for more). Wood and iron are cheap, core to legend mid; bramble and legend flash a light.",
}
