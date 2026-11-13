-- Weapon Cast Focus: the Arcane Barrage of Goo Lineage's Arcane Focus, one design per rarity (wood Common, iron
-- Uncommon, core Epic, bramble Mythic, legend Legendary). Played once at the focus's head (its gem, up along the staff)
-- as the barrage is cast. What flies is solid (drawn normal, so it holds on snow), the light added on top; from core up
-- the cast marks the floor under the slime (`ground` pieces). Wood: a warm flare, wood chips and a puff of dust. Iron:
-- a white glint, a steel ring snapping open, blue needle sparks. Core, the Prism: a rainbow arc flashing round the gem,
-- rainbow crystal shards flung out, glints, a cut gem stamped on the floor. Bramble, the Mythic Focus: the game's own
-- arcane burst and motes, its arcane ring opening on the floor, green leaves thrown up, a violet flash of rays and
-- light. Legend, the Astral Scepter: a starlight flare, a pink nebula blooming at the gem, gold stars flung out, a
-- galaxy turning on the floor inside a gold ring racing out, twinkles, a starlight flash.
local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (a flash on the gem, added)
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		count = 1,
		life = { 0.22, 0.22 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.6 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (things flung out of the gem, slowing)
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

-- (a sheet of four pictures: each particle keeps one of them, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "burst.weapon_cast_focus",
	name = "Weapon Cast Focus",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "focus", "arcane", "barrage", "rune", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.14 },
	pieces = {
		flash("flash", "flare_star", { 255, 215, 150 }, 2.2),
		burst("chips", "shard_flat", { { 220, 172, 110 }, { 160, 112, 64 } }, 10, 0.5, {
			accel = { 0, -16, 0 },
			rotSpeed = { -300, 300 },
		}),
		burst("dust", "dust_ring", { { 230, 210, 172 } }, 2, 1.2, {
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
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 2.2),
				-- (a steel ring snapping open round the gem, blue-grey: white is lost on snow)
				flash("ring", "ring_crisp", { 150, 172, 212 }, 3.4, {
					life = { 0.3, 0.3 },
					size = { { 0, 1 }, { 1, 3.4 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
					lightEmission = 0,
					brightness = 1.3,
					zOffset = 0,
				}),
				burst("sparks", "needle_glow", { { 210, 235, 255 }, { 90, 150, 255 } }, 14, 0.6, {
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
				-- (the Prism: a rainbow arc flashing round the gem, its own colours)
				flash("arc", "arc_rainbow", nil, 3.6, {
					role = "keep",
					life = { 0.3, 0.3 },
					size = { { 0, 1.2 }, { 0.3, 3.6 }, { 1, 4 } },
					zOffset = 0,
				}),
				burst("shards", "shard_flat", "rainbow", 14, 0.85, {
					life = { 0.5, 0.75 },
					speed = { 6, 11 },
					accel = { 0, -6, 0 },
					rotSpeed = { -300, 300 },
					brightness = 1.5,
				}),
				burst("glints", "sparkStar", { { 255, 255, 255 }, { 180, 230, 255 } }, 8, 0.7, {
					speed = { 2, 5 },
					lightEmission = 1,
				}),
				-- (a cut gem stamped on the floor under the slime, turning)
				mark("gem", "gem_round", { 200, 235, 255 }, 2.8, {
					rotSpeed = { 45, 45 },
					brightness = 1.5,
				}),
			},
		},
		bramble = {
			pieces = {
				-- (the game's own arcane burst, motes and ring, kept as drawn)
				flash("burst", "burstArcane", nil, 3.4, {
					role = "keep",
					life = { 0.32, 0.32 },
					size = { { 0, 1.4 }, { 0.2, 3.4 }, { 1, 3.8 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
					lightEmission = 0.5,
					zOffset = 1,
				}),
				burst("motes", "moteArcane", nil, 14, 0.75, {
					role = "keep",
					life = { 0.35, 0.6 },
					speed = { 4, 8 },
					drag = 4,
					lightEmission = 0.5,
				}),
				burst("leaves", "leaves_solid", { { 170, 230, 95 }, { 95, 175, 60 } }, 12, 0.9, {
					life = { 0.8, 1 },
					speed = { 3, 6 },
					accel = { 0, -3, 0 },
					rotSpeed = { -180, 180 },
					brightness = 1.3,
					flipbook = ONE_OF,
				}),
				flash("rays", "ring_rays", { 205, 150, 255 }, 4.6, {
					life = { 0.32, 0.32 },
					size = { { 0, 1.5 }, { 1, 4.6 } },
					rotation = { 0, 0 },
					zOffset = 0,
				}),
				mark("ring", "ringArcane", nil, 5.5, {
					role = "keep",
					life = { 0.7, 0.7 },
					size = { { 0, 1.2 }, { 0.3, 5 }, { 1, 6 } },
					rotSpeed = { 60, 60 },
					lightEmission = 0.4,
				}),
			},
			light = { color = { 200, 140, 255 }, keys = { { 0, 0 }, { 0.05, 2.5 }, { 0.45, 0 } }, range = 10 },
		},
		legend = {
			pieces = {
				flash("flare", "star_flare", { 255, 245, 215 }, 3.6),
				-- (a pink nebula blooming at the gem, drawn solid)
				burst("nebula", "smoke_soft", { { 255, 165, 228 }, { 175, 105, 240 } }, 4, 2.4, {
					life = { 0.6, 0.8 },
					size = { { 0, 1.2 }, { 0.4, 3 }, { 1, 3.6 } },
					transparency = { { 0, 0.3 }, { 0.6, 0.45 }, { 1, 1 } },
					speed = { 0.5, 1.5 },
					rotSpeed = { -40, 40 },
					brightness = 1.3,
				}),
				burst("stars", "star_fat", { { 255, 240, 170 }, { 255, 195, 85 } }, 18, 1, {
					life = { 0.55, 0.8 },
					size = { { 0, 0.5 }, { 0.2, 1 }, { 1, 0.4 } },
					speed = { 6, 12 },
					rotSpeed = { -200, 200 },
					lightEmission = 0.4,
					brightness = 1.6,
				}),
				burst("twinkles", "star_twinkle", { { 255, 250, 235 }, { 200, 180, 255 } }, 10, 0.7, {
					size = { { 0, 0 }, { 0.3, 0.7 }, { 1, 0 } },
					speed = { 2, 6 },
					lightEmission = 1,
					secondary = true,
				}),
				-- (the floor under the slime: a galaxy turning inside a gold ring racing out)
				mark("galaxy", "galaxy_spiral", { { 255, 180, 235 }, { 160, 125, 255 } }, 5, {
					life = { 1, 1 },
					size = { { 0, 1.5 }, { 0.15, 5 }, { 1, 5.6 } },
					rotSpeed = { 80, 80 },
					lightEmission = 1, -- (the pack's galaxy is drawn on dark: added, or its square shows)
					brightness = 2,
				}),
				mark("ring", "ring_line_b", { 255, 205, 95 }, 7.5, {
					life = { 0.65, 0.65 },
					size = { { 0, 2 }, { 1, 8 } },
					transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
				}),
			},
			light = { color = { 175, 145, 255 }, keys = { { 0, 0 }, { 0.05, 3.5 }, { 0.6, 0 } }, range = 14 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "the owner's arcane burst, ring and motes (burstArcane, ringArcane, moteArcane: Goo Lineage's own, kept as drawn) and spark star (sparkStar, tinted); free Creator Store pack textures (no scripts: flare_star, shard_flat, star_glint_sharp, ring_crisp, needle_glow, arc_rainbow, ring_rays, star_flare, smoke_soft, star_fat, star_twinkle, galaxy_spiral, ring_line_b); dust_ring (EffectCraft); gem_round, leaves_solid (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, focusHeadCFrame, { variant = rarity }) as the Arcane Barrage is cast (the frame at the gem, up along the staff). Core, bramble and legend mark the floor straight under the head: pass opts.ground (the floor's height) when the game knows it, else the first floor below is found (characters left out; opts.ignore for more). Wood and iron are cheap, core to legend mid; bramble and legend flash a light.",
}
