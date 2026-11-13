-- Weapon Cast Bow: the Piercing Shot of Goo Lineage's held bows, one design per rarity (wood Common, iron Uncommon,
-- core Epic, bramble Mythic, legend Legendary). Played once at the bow's head (up along the bow, +x toward the shot:
-- the side the owner's limbs bulge to, away from the string) as the arrow is loosed; the shot's pieces sit at the
-- nock, half way down the bow, and fly along +x. Streaks and rings are drawn solid (normal, so they hold on snow), the
-- light added on top; from core up the shot marks the floor under the slime (`ground` pieces). Wood: a tan flash,
-- brown streaks, wood chips. Iron: a white glint, steel streaks, a steel ring of air punched round the arrow's line.
-- Core, Windwhisper: teal streaks, a crescent of wind spinning round the line, feathers and gusts flying with the
-- arrow, a ring of wind swirling on the floor. Bramble, Starfall: gold streaks and a gold ring, gold stars thrown out
-- and falling, violet twinkles, a violet thorned ring on the floor, a flash of violet light. Legend, Moonsong: a big
-- gold crescent moon at the string, silver streaks, silver notes flung out, a split silver ring on the floor round a
-- gold moon, a flash of moonlight.
local NOCK = { 0, -1.6, 0 } -- (studs down the bow from its head to the string's middle: the owner's 3.5-stud bows)

local function with(base, over)
	local out = table.clone(base)
	for key, value in over or {} do
		out[key] = value
	end
	return out
end

-- (the flash at the string as it is loosed, added)
local function flash(name, texture, color, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		offset = NOCK,
		count = 1,
		life = { 0.18, 0.18 },
		size = { { 0, size * 0.3 }, { 0.2, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		rotation = { 0, 359 },
		lightEmission = 1,
		zOffset = 2,
	}, over)
end

-- (streaks of air shot ahead along the arrow's line, lying along their flight, solid)
local function streaks(color, count, size)
	return {
		name = "streaks",
		texture = "streak_vertical",
		color = color,
		offset = NOCK,
		count = count,
		life = { 0.16, 0.26 },
		size = { { 0, size }, { 1, size * 0.35 } },
		transparency = { { 0, 0 }, { 0.6, 0.15 }, { 1, 1 } },
		speed = { 26, 40 },
		spread = { 7, 7 },
		direction = "Right",
		orientation = "VelocityParallel",
		-- (VelocityParallel lays a picture's width along its flight: a vertical streak turned a quarter lies along it)
		rotation = { -90, -90 },
		lightEmission = 0,
		brightness = 1.4,
	}
end

-- (a ring punched round the arrow's line, standing across it and carried a little along)
local function ring(name, texture, color, width, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		offset = NOCK,
		count = 1,
		life = { 0.32, 0.32 },
		size = { { 0, width * 0.2 }, { 0.35, width * 0.8 }, { 1, width } },
		transparency = { { 0, 0 }, { 0.4, 0.15 }, { 1, 1 } },
		speed = { 3, 3 },
		spread = { 0, 0 },
		direction = "Right",
		orientation = "VelocityPerpendicular",
		lightEmission = 0,
		brightness = 1.4,
	}, over)
end

-- (things flung out with the arrow, slowing)
local function burst(name, texture, color, count, size, over)
	return with({
		name = name,
		texture = texture,
		color = color,
		offset = NOCK,
		count = count,
		life = { 0.45, 0.7 },
		size = { { 0, size }, { 1, size * 0.5 } },
		transparency = { { 0, 0 }, { 0.6, 0.1 }, { 1, 1 } },
		speed = { 4, 8 },
		spread = { 50, 50 },
		direction = "Right",
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

return {
	id = "burst.weapon_cast_bow",
	name = "Weapon Cast Bow",
	kind = "burst",
	tier = "mid",
	host = "weapon",
	refHeight = 4,
	tags = { "weapon", "bow", "shot", "pierce", "loose", "cast", "rarity", "ladder", "goo_lineage" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	defaultVariant = "wood",
	markers = { peak = 0.1 },
	pieces = {
		flash("flash", "star_flare", { 240, 200, 140 }, 1.9),
		streaks({ { 214, 150, 80 }, { 150, 100, 55 } }, 6, 1.4),
		burst("chips", "shard_flat", { { 205, 155, 100 }, { 150, 102, 60 } }, 8, 0.5, {
			speed = { 4, 8 },
			accel = { 0, -16, 0 },
			rotSpeed = { -300, 300 },
		}),
	},
	variants = {
		wood = { tier = "cheap" },
		iron = {
			tier = "cheap",
			pieces = {
				flash("glint", "star_glint_sharp", { 255, 255, 255 }, 2),
				-- (steel blue-grey, not white: a white streak is lost on snow; the glint is the white)
				streaks({ { 205, 220, 245 }, { 120, 142, 182 } }, 8, 1.5),
				ring("ring", "ring_crisp", { 150, 175, 215 }, 2.6),
			},
		},
		core = {
			pieces = {
				flash("glint", "star_glint_sharp", { 230, 250, 255 }, 2.2),
				streaks({ { 130, 220, 240 }, { 40, 150, 210 } }, 10, 1.6),
				-- (a crescent of wind spinning round the arrow's line)
				ring("spin", "windspin_b", { 110, 215, 235 }, 3.2, {
					life = { 0.4, 0.4 },
					rotation = { 0, 359 },
					rotSpeed = { 540, 540 },
				}),
				burst("feathers", "down_feather", { { 175, 230, 255 }, { 90, 180, 240 } }, 8, 0.8, {
					life = { 0.6, 0.9 },
					accel = { 0, -3, 0 },
					rotSpeed = { -150, 150 },
					brightness = 1.3,
				}),
				burst("gusts", "gust_curl", { { 140, 225, 235 }, { 60, 175, 210 } }, 4, 1.4, {
					size = { { 0, 0.7 }, { 0.3, 1.4 }, { 1, 1.6 } },
					transparency = { { 0, 0.1 }, { 0.6, 0.3 }, { 1, 1 } },
					speed = { 5, 9 },
					spread = { 25, 25 },
					rotation = { -30, 30 },
					brightness = 1.3,
				}),
				mark("wind", "swirl_wind_ring", { 100, 205, 230 }, 3.6, {
					life = { 0.7, 0.7 },
					rotSpeed = { 160, 160 },
					brightness = 1.4,
				}),
			},
		},
		bramble = {
			pieces = {
				flash("flash", "star_flare_big", { 255, 225, 150 }, 2.6),
				streaks({ { 255, 225, 130 }, { 235, 160, 50 } }, 10, 1.7),
				ring("ring", "ring_crisp", { 255, 200, 90 }, 3),
				-- (gold stars thrown out with the arrow, falling as they slow)
				burst("stars", "star_fat", { { 255, 225, 120 }, { 255, 170, 60 } }, 12, 0.9, {
					life = { 0.6, 0.85 },
					size = { { 0, 0.5 }, { 0.2, 0.95 }, { 1, 0.5 } },
					speed = { 4, 9 },
					spread = { 70, 70 },
					accel = { 0, -10, 0 },
					rotSpeed = { -200, 200 },
					lightEmission = 0.4,
					brightness = 1.5,
				}),
				burst("twinkles", "star_twinkle", { { 240, 220, 255 }, { 175, 120, 255 } }, 8, 0.7, {
					life = { 0.35, 0.6 },
					size = { { 0, 0 }, { 0.25, 0.7 }, { 1, 0 } },
					speed = { 3, 7 },
					lightEmission = 1,
				}),
				-- (the floor under the slime: a violet thorned ring opening out)
				mark("thorns", "ring_thorned", { 140, 80, 240 }, 5, {
					rotSpeed = { 60, 60 },
					lightEmission = 0,
					brightness = 1.4,
				}),
			},
			light = { color = { 200, 160, 255 }, keys = { { 0, 0 }, { 0.05, 2.5 }, { 0.45, 0 } }, range = 10 },
		},
		legend = {
			pieces = {
				-- (a big gold crescent moon at the string as it is loosed)
				with(flash("moon", "crescent_moon", { 255, 220, 120 }, 4.5), {
					life = { 0.45, 0.45 },
					size = { { 0, 2 }, { 0.2, 4.5 }, { 1, 5 } },
					transparency = { { 0, 0 }, { 0.5, 0.1 }, { 1, 1 } },
					rotation = { -20, 20 },
					lightEmission = 0,
					brightness = 1.5,
					zOffset = 1,
				}),
				flash("flash", "flare_bright", { 220, 230, 255 }, 3),
				streaks({ { 210, 222, 255 }, { 110, 130, 230 } }, 12, 1.8),
				-- (silver notes flung out with the arrow, each popping out, bobbing to a beat and sparkling away: the clip)
				burst("notes", "notes_flip", { { 215, 225, 255 }, { 150, 170, 255 } }, 10, 1.1, {
					life = { 0.7, 0.9 },
					size = { { 0, 1.1 }, { 1, 1.05 } },
					speed = { 3, 7 },
					spread = { 60, 60 },
					accel = { 0, 3, 0 },
					rotation = { -15, 15 },
					brightness = 1.5,
					flipbook = { layout = "Grid4x4", mode = "OneShot" },
				}),
				-- (the floor under the slime: a split silver ring round a gold moon)
				-- (a deep moon blue, drawn normal: a silver ring is lost on snow)
				mark("ring", "ring_split", { 105, 125, 235 }, 6.5, {
					life = { 0.9, 0.9 },
					size = { { 0, 2 }, { 0.2, 6.5 }, { 1, 7 } },
					rotSpeed = { 50, 50 },
					lightEmission = 0,
					brightness = 1.5,
				}),
				mark("moonmark", "crescent_moon", { 255, 210, 100 }, 3, {
					life = { 0.95, 0.95 },
					size = { { 0, 1 }, { 0.15, 3 }, { 1, 3.2 } },
					rotSpeed = { -20, -20 },
					brightness = 1.5,
				}),
			},
			light = { color = { 175, 195, 255 }, keys = { { 0, 0 }, { 0.05, 4 }, { 0.6, 0 } }, range = 14 },
		},
	},
	source = {
		from = "the library, for Goo Lineage's held weapons (docs/vfx/plans/2026-11-12-weapons.md, redone 2026-11-13)",
		art = "notes_flip (a ChatGPT clip drawn for the library: tools/chatgpt/clip_frames.py); free Creator Store pack textures (no scripts: star_flare, star_flare_big, flare_bright, star_glint_sharp, streak_vertical, shard_flat, ring_crisp, windspin_b, swirl_wind_ring, star_fat, star_twinkle, ring_thorned, crescent_moon, ring_split); down_feather, gust_curl (ChatGPT for the library)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = "VfxLib.play(id, bowHeadCFrame, { variant = rarity }) as the Piercing Shot is loosed: the frame's up along the bow, its +x toward the shot (the owner's bows bulge that way, the string on -x); the shot's pieces sit 1.6 studs down the bow, at the string. Core, bramble and legend mark the floor straight under the head: pass opts.ground (the floor's height) when the game knows it, else the first floor below is found (characters left out; opts.ignore for more). Wood and iron are cheap, core to legend mid; bramble and legend flash a light.",
}
