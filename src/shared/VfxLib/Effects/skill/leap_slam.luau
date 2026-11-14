-- Leap Slam: a leap high into the air and down onto the foe with the full weight of the blow (physical skills,
-- 2026-11-09: "Thiên Giáng Kích"), an area attack where it lands. The warrior kicks off in a ring of dust and flies
-- in an arc, a pale wake of air behind; landing, the ground gives: a white pop, a crater of cracks with straight
-- fissures running out of it, a ring of dust blown out flat, a rough shockwave racing along the ground, clouds of
-- dust thrown up all round and rocks flying out and falling back. At lv3 the ground answers a breath later with a
-- second, wider shockwave. Played at the landing spot with opts.from = the attacker (the projectile is the leap's
-- wake; the game moves the body). Its level is the variant: lv1 a small crater, lv2 the full one, lv3 (the default)
-- and the aftershock.
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local AIR = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } }
local LEAP = 0.5
local GROUND = -2.45

-- straight fissures running out of the crater along the ground
local function fissures(count, reach)
	local out: { any } = {}
	for i = 1, count do
		local a = math.rad(i * 360 / count + 17 * (i % 2))
		local r = reach * (if i % 2 == 0 then 1 else 0.75)
		table.insert(out, {
			name = "fissure" .. i,
			texture = "crack_slit",
			colors = { { 255, 255, 255 }, { 255, 255, 255 } },
			from = { 0.8 * math.sin(a), GROUND, -0.8 * math.cos(a) },
			to = { r * math.sin(a), GROUND, -r * math.cos(a) },
			flat = true,
			width = { 1.4, 0.6 },
			delay = 0.02 * i,
			life = 1.4,
			transparency = { { 0, 0 }, { 0.75, 0.1 }, { 1, 1 } },
			grow = { { 0, 0.3 }, { 0.1, 1 }, { 1, 1 } },
			glow = 0,
		})
	end
	return out
end

local function pieces(n)
	local big = if n == 1 then 0.75 else 1
	local out = {
		{
			-- the kick-off: a ring of dust where the attacker leapt from (timed from the cast)
			name = "kickoff",
			texture = "dust_ring",
			color = DUST,
			along = 0,
			cast = true,
			flat = true,
			count = 1,
			life = { 0.6, 0.6 },
			size = { { 0, 2.5 }, { 1, 7 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			rotation = { -180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
		},
		{
			-- the landing: a white pop with speed lines ...
			name = "pop",
			texture = "impact_burst",
			color = WHITE,
			at = "ground",
			offset = { 0, 1.5, 0 },
			count = 1,
			life = { 0.35, 0.35 },
			size = { { 0, 6 * big }, { 1, 11 * big } },
			speed = { 0.01, 0.01 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 1.8,
			zOffset = 3,
		},
		{
			-- ... the crater cracked into the ground ...
			name = "crater",
			texture = "crack_ground",
			color = { { 255, 255, 255 } },
			at = "ground",
			offset = { 0, 0.05, 0 },
			flat = true,
			count = 1,
			life = { 1.6, 1.6 },
			size = { { 0, 4 * big }, { 0.06, 9 * big }, { 1, 9.4 * big } },
			transparency = { { 0, 0 }, { 0.75, 0.1 }, { 1, 1 } },
			rotation = { -180, 180 },
			lightEmission = 0,
			lightInfluence = 0,
		},
		{
			-- ... a ring of dust blown out flat ...
			name = "dust_ring",
			texture = "dust_ring",
			color = DUST,
			at = "ground",
			flat = true,
			count = 1,
			life = { 0.9, 0.9 },
			size = { { 0, 5 * big }, { 1, 16 * big } },
			transparency = { { 0, 0.1 }, { 1, 1 } },
			rotation = { -180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
		},
		{
			-- ... a rough shockwave racing along the ground ...
			name = "shock",
			texture = "ring_rough",
			color = DUST,
			at = "ground",
			offset = { 0, 0.15, 0 },
			flat = true,
			count = 1,
			life = { 0.5, 0.5 },
			size = { { 0, 4 * big }, { 1, 18 * big } },
			transparency = { { 0, 0.05 }, { 0.6, 0.4 }, { 1, 1 } },
			rotation = { -180, 180 },
			lightEmission = 0,
			lightInfluence = 0,
		},
		{
			-- ... clouds of dust thrown up all round ...
			name = "kick",
			texture = "dust_kick_flip",
			color = DUST,
			at = "feet",
			shape = "Disc",
			shapeInOut = "Outward",
			radius = 2.5 * big,
			count = 14,
			life = { 0.7, 1.1 },
			size = { { 0, 2 }, { 1, 4.5 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			speed = { 7, 12 },
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
			locked = false,
		},
		{
			-- ... and rocks flying out, falling back
			name = "rocks",
			texture = "rocks",
			color = { { 255, 255, 255 } },
			at = "feet",
			box = { 0.5, 0, 0.5 },
			count = if n == 1 then 10 else 16,
			life = { 0.8, 1.1 },
			size = { { 0, 0.55 }, { 1, 0.4 } },
			speed = { 14, 22 },
			spread = { 40, 40 },
			direction = "Top",
			accel = { 0, -50, 0 },
			rotation = { -180, 180 },
			rotSpeed = { -400, 400 },
			lightEmission = 0,
			locked = false,
			secondary = true,
		},
	}
	if n == 3 then
		table.insert(out, {
			-- the aftershock: the ground answers with a second, wider wave
			name = "aftershock",
			texture = "ring_rough",
			color = DUST,
			at = "ground",
			offset = { 0, 0.2, 0 },
			flat = true,
			count = 1,
			delay = 0.24,
			life = { 0.6, 0.6 },
			size = { { 0, 6 }, { 1, 26 } },
			transparency = { { 0, 0.15 }, { 0.6, 0.5 }, { 1, 1 } },
			rotation = { -180, 180 },
			lightEmission = 0,
			lightInfluence = 0,
		})
	end
	return out
end

local function level(n)
	return {
		beams = fissures(if n == 1 then 4 else 6, if n == 1 then 5 else 7),
		pieces = pieces(n),
		markers = { land = LEAP, impact = LEAP, peak = LEAP + (if n == 3 then 0.26 else 0.04) },
	}
end

local LV3 = level(3)

return {
	id = "skill.leap_slam",
	name = "Leap Slam",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "hammer", "sword", "leap", "slam", "ground", "dust", "shockwave", "melee", "aoe", "skill" },
	blend = "additive",
	tintable = false,
	markers = LV3.markers,
	projectile = {
		-- the leap's wake: a pale smear of air flying the arc with the body
		texture = "streak_lens",
		color = AIR,
		size = { { 0, 3 }, { 1, 4 } },
		transparency = { { 0, 0.5 }, { 1, 0.4 } },
		lightEmission = 0.7,
		brightness = 1.2,
		seconds = LEAP,
		arc = 6,
		riders = {
			{
				-- a vapour wake of air left hanging along the arc (streaks shed every way read as broken glass)
				name = "wisps",
				texture = "smoke_cloud_soft",
				color = AIR,
				life = { 0.3, 0.45 },
				size = { { 0, 1.2 }, { 1, 2.4 } },
				transparency = { { 0, 0.5 }, { 1, 1 } },
				speed = { 0.2, 0.6 },
				spread = { 180, 180 },
				rotation = { -180, 180 },
				lightEmission = 0.6,
				brightness = 1,
				stream = { from = 0, to = LEAP, rate = { 40, 40 } },
			},
		},
		trail = {
			texture = "streak_mist",
			colors = { { 240, 245, 255 }, { 200, 215, 235 } },
			width = 2.2,
			life = 0.4,
			glow = 1.4,
		},
	},
	beams = LV3.beams,
	pieces = LV3.pieces,
	variants = { lv1 = level(1), lv2 = level(2), lv3 = {} },
	defaultVariant = "lv3",
	light = { color = { 255, 240, 220 }, range = 18, keys = { { 0, 4 }, { 0.6, 0 } } },
	source = {
		from = "the library (physical skills, 2026-11-09)",
		art = "EffectCraft (impact_burst, dust_ring: textures/fx); free Creator Store pack textures (no scripts: streak_lens, smoke_cloud_soft, streak_mist, crack_slit, crack_ground, ring_rough, dust_kick_flip, rocks)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the landing spot with opts.from = the attacker as they leap; move the body along a 6-stud arc and land at 0.5 s (markers.impact: damage in a ~8-stud circle, a strong short shake there). Levels: lv1 a smaller crater, lv2 the full one, lv3 (default) and an aftershock wave at 0.74 s. skill.battle_focus is its wind-up.",
}
