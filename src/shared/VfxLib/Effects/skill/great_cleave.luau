-- Great Cleave: one huge sweep that hits everything in front (physical skills, 2026-11-09: "Đại Phá Trảm"). A heavy
-- blade swung low and wide, right to left: a crescent of swept steel 200 degrees round and 8 studs out, a pale wake of
-- air behind it; where it passes the ground is gashed (dark cracks along the arc), a wall of dust is thrown up along
-- it, rocks fly, sparks and white pops where it meets the foes, and a gust blows on ahead. At lv3 the force of it runs
-- on: a thinner echo of the arc flies out further. Played at the ATTACKER's frame (VfxLib.play(id, root.CFrame)).
-- Its level is the variant: lv1 a 160 degree arc 6 studs out, lv2 the full arc, lv3 (the default) and its echo.
local STEEL = { { 175, 195, 225 }, { 230, 238, 255 }, { 255, 255, 255 } }
local WAKE = { { 200, 215, 235 }, { 240, 245, 255 } }
local HOT = { { 0, { 255, 250, 220 } }, { 0.4, { 255, 200, 90 } }, { 1, { 255, 110, 30 } } }
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local HEIGHT = -1.1 -- (the blade's height: low, at the knees of a foe)
local GROUND = -2.45
local HIT = 0.08

local function on(angle, radius, y)
	local a = math.rad(angle)
	return { radius * math.sin(a), y, -radius * math.cos(a) }
end

-- an arc from `a1` to `a2` degrees (from ahead toward the right) round the attacker, lying flat, bowed out to the circle
local function arc(name, texture, colors, a1, a2, radius, y, delay, life, wide, alpha, glow)
	local half = math.rad(math.abs(a1 - a2) / 2)
	local mid = math.rad((a1 + a2) / 2)
	local push = radius * (1 - math.cos(half)) / 0.75
	return {
		name = name,
		texture = texture,
		colors = colors,
		from = on(a1, radius, y),
		to = on(a2, radius, y),
		bulge = { push * math.sin(mid), 0, -push * math.cos(mid) },
		width = { wide * 0.8, wide },
		delay = delay,
		life = life,
		transparency = { { 0, alpha }, { 0.35, alpha }, { 1, 1 } },
		grow = { { 0, 0.6 }, { 0.25, 1 }, { 1, 1.15 } },
		edge = { 0.5, 0 },
		segments = 20,
		glow = glow,
		zOffset = if texture == "slash_steel" then 1 else 0,
	}
end

-- the sweep, right to left in two halves (a Beam bends no more than about 180 degrees)
local function sweep(prefix, span, radius, y, delay, wide, steel)
	local out: { any } = {}
	local half = span / 2
	for index, range in { { half, 0 }, { 0, -half } } do
		local at = delay + (index - 1) * 0.05
		if steel then
			table.insert(
				out,
				arc(`{prefix}{index}`, "slash_steel", STEEL, range[1], range[2], radius, y, at, 0.32, wide, 0, 2.3)
			)
		end
		table.insert(
			out,
			arc(
				`{prefix}{index}_wake`,
				"streak_mist",
				WAKE,
				range[1],
				range[2],
				radius + 0.6,
				y,
				at + 0.02,
				0.42,
				wide * 1.5,
				0.4,
				1.1
			)
		)
	end
	return out
end

-- the gash: straight dark cracks lying on the ground along the arc
local function gash(span, radius, count)
	local out: { any } = {}
	for i = 1, count do
		local a1 = span / 2 - (i - 1) * span / count
		local a2 = a1 - span / count
		table.insert(out, {
			name = "gash" .. i,
			texture = "crack_slit",
			colors = { { 255, 255, 255 }, { 255, 255, 255 } },
			from = on(a1 + 2, radius, GROUND),
			to = on(a2 - 2, radius, GROUND),
			flat = true,
			width = { 1.3, 1.3 },
			delay = HIT + (i - 1) * 0.025,
			life = 1.3,
			transparency = { { 0, 0 }, { 0.75, 0.1 }, { 1, 1 } },
			grow = { { 0, 0.3 }, { 0.1, 1 }, { 1, 1 } },
			glow = 0,
		})
	end
	return out
end

local function add(list, more)
	for _, beam in more do
		table.insert(list, beam)
	end
	return list
end

-- the pieces, along the arc's band in front (a box `deep` shares of the 5-stud box ahead, `wide` across)
local function pieces(radius, wide)
	local band = { 0, GROUND + 0.1, -radius * 0.75 }
	local box = { wide, 0, radius * 0.18 }
	return {
		{
			-- white pops where the blade meets the foes along the arc
			name = "pops",
			texture = "impact_burst",
			color = WHITE,
			at = "body",
			offset = { 0, HEIGHT + 0.6, -radius * 0.8 },
			box = { wide * 0.9, 0.1, radius * 0.12 },
			count = 4,
			delay = HIT,
			life = { 0.25, 0.3 },
			size = { { 0, 3 }, { 1, 5 } },
			speed = { 0.01, 0.01 },
			rotation = { -180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 1.7,
			zOffset = 3,
		},
		{
			-- hot sparks along it
			name = "sparks",
			texture = "spark_dot",
			color = HOT,
			at = "body",
			offset = { 0, HEIGHT, -radius * 0.8 },
			box = { wide, 0.1, radius * 0.15 },
			orientation = "VelocityParallel",
			count = 28,
			delay = HIT,
			life = { 0.25, 0.5 },
			size = { { 0, 0.45 }, { 1, 0.1 } },
			transparency = { { 0, 0 }, { 1, 0.3 } },
			speed = { 14, 24 },
			spread = { 60, 60 },
			direction = "Left",
			squash = { { 0, -0.8 }, { 1, -0.6 } },
			drag = 3,
			accel = { 0, -24, 0 },
			lightEmission = 1,
			brightness = 3,
			locked = false,
		},
		{
			-- a wall of dust thrown up along the arc
			name = "wall",
			texture = "dust_kick_flip",
			color = DUST,
			at = "body",
			offset = band,
			box = box,
			count = 16,
			delay = HIT + 0.02,
			life = { 0.7, 1.1 },
			size = { { 0, 1.8 }, { 1, 4.2 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			speed = { 5, 9 },
			spread = { 25, 25 },
			direction = "Top",
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
		},
		{
			-- rocks flying out of the gash
			name = "rocks",
			texture = "rocks",
			color = { { 255, 255, 255 } },
			at = "body",
			offset = band,
			box = box,
			count = 14,
			delay = HIT,
			life = { 0.6, 0.9 },
			size = { { 0, 0.45 }, { 1, 0.3 } },
			speed = { 10, 18 },
			spread = { 40, 40 },
			direction = "Top",
			accel = { 0, -45, 0 },
			rotation = { -180, 180 },
			rotSpeed = { -400, 400 },
			lightEmission = 0,
			locked = false,
		},
		{
			-- a gust blown on ahead: thin streaks of air
			name = "gust",
			texture = "streaks_flat",
			color = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } },
			at = "body",
			offset = { 0, HEIGHT + 0.5, -radius * 0.7 },
			box = { wide, 0.2, 0.2 },
			orientation = "VelocityParallel",
			count = 12,
			delay = HIT + 0.05,
			life = { 0.2, 0.35 },
			size = { { 0, 2.4 }, { 1, 1 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			speed = { 30, 45 },
			spread = { 20, 20 },
			direction = "Front",
			drag = 4,
			lightEmission = 0.7,
			brightness = 1.4,
			locked = false,
			secondary = true,
		},
	}
end

local function level(n)
	local span = if n == 1 then 160 else 200
	local radius = if n == 1 then 6 else 8
	local beams = sweep("arc", span, radius, HEIGHT, 0, if n == 1 then 2.6 else 3.2, true)
	add(beams, gash(span, radius - 0.6, if n == 1 then 4 else 5))
	if n == 3 then
		-- (the echo: a thinner arc of air flying out further, after the blade)
		add(beams, sweep("echo", 180, 11.5, HEIGHT + 0.3, 0.14, 2.6, false))
	end
	return {
		beams = beams,
		pieces = pieces(radius, if n == 1 then 2.2 else 3),
		markers = { contact = HIT, impact = HIT, peak = if n == 3 then 0.2 else 0.14 },
	}
end

local LV3 = level(3)

return {
	id = "skill.great_cleave",
	name = "Great Cleave",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "sword", "axe", "slash", "cleave", "sweep", "steel", "dust", "melee", "aoe", "skill" },
	blend = "additive",
	tintable = false,
	markers = LV3.markers,
	beams = LV3.beams,
	pieces = LV3.pieces,
	variants = { lv1 = level(1), lv2 = level(2), lv3 = {} },
	defaultVariant = "lv3",
	light = { color = { 235, 240, 255 }, range = 16, keys = { { 0, 0 }, { HIT, 4 }, { 0.7, 0 } } },
	source = {
		from = "the library (physical skills, 2026-11-09)",
		art = "EffectCraft (slash_steel, impact_burst: textures/fx); free Creator Store pack textures (no scripts: streak_mist, crack_slit, spark_dot, dust_kick_flip, rocks, streaks_flat)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the attacker's root CFrame as the heavy swing starts; it hits everything in the arc in front (200 degrees, 8 studs; lv1 160 degrees, 6 studs) at 0.08 s (markers.impact: shake there). Levels: lv1, lv2, lv3 (default, with an echo arc flying further). skill.battle_focus is its wind-up.",
}
