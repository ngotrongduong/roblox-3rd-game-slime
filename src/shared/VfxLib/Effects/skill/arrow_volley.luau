-- Arrow Volley: a rain of arrows on an area (physical skills, 2026-11-09: "Vạn Tiễn"), the ranged end of the family.
-- The archer looses arrow after arrow high into the air, a snap of air at the bow each time; each arrow (EffectCraft:
-- white vanes with a red band, a wooden shaft, a steel head) climbs, turns over and drops point first on its own
-- curved path into the area round the target, a thin pale streak behind it, and strikes the ground in a puff of dust
-- and splinters. When the last has struck, a haze of dust hangs over the area. Played at the target with opts.from =
-- the archer (their bow hand). Its level is the variant: lv1 6 arrows, lv2 10, lv3 (the default) 15.
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local AIR = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } }
local LOOSE = 0.035 -- (seconds between arrows)
local RADIUS = 5
local LEVELS = { lv1 = 6, lv2 = 10, lv3 = 15 }
-- (each arrow's flight a little its own)
local FLIGHTS = { 0.6, 0.55, 0.65, 0.58, 0.62, 0.56, 0.64, 0.6, 0.57, 0.63, 0.59, 0.61, 0.55, 0.66, 0.6 }
local LIFTS = { 9, 10.5, 8, 9.5, 11, 8.5, 10, 9, 10.5, 8, 9.5, 11, 8.5, 10, 9 }

local function arrows(count)
	local out: { any } = {}
	for i = 1, count do
		-- (spread over the area: a golden-angle turn each, out to the rim by the last)
		local angle = math.rad(i * 137.508)
		local r = RADIUS * math.sqrt((i - 0.5) / count)
		local delay = (i - 1) * LOOSE
		local side = (i % 3) - 1
		table.insert(out, {
			name = "arrow" .. i,
			texture = "arrow_steel",
			colors = { { 255, 255, 255 }, { 255, 255, 255 } },
			caster = true,
			-- (from the nock to the point, as the picture is stored: drawn on the bow, pointing up and ahead)
			-- (big as arrows go, 3.2 studs: smaller is lost from the player's camera behind the archer)
			from = { 0.5 + side * 0.15, 0.2, -0.2 },
			to = { 0.5 + side * 0.15, 2, -2.8 },
			width = { 0.8, 0.8 },
			delay = delay,
			life = 0.03 + FLIGHTS[i],
			transparency = { { 0, 0 }, { 1, 0 } },
			face = true,
			glow = 0,
			strike = {
				at = 0.03,
				seconds = FLIGHTS[i],
				bend = { side * 1.5, LIFTS[i], 0 },
				aim = { r * math.cos(angle), -2.3, r * math.sin(angle) },
				wander = 1,
				trail = {
					texture = "streak_mist",
					colors = { { 240, 245, 255 }, { 200, 215, 235 } },
					width = 0.7,
					life = 0.25,
					glow = 1,
				},
			},
			land = "thud",
		})
	end
	return out
end

local function last(count)
	local out = 0
	for i = 1, count do
		out = math.max(out, (i - 1) * LOOSE + 0.03 + FLIGHTS[i])
	end
	return out
end

local function releases(count)
	local out: { any } = {}
	for i = 1, count do
		table.insert(out, { (i - 1) * LOOSE + 0.03, 1 })
	end
	return out
end

local function pieces(count)
	local done = last(count)
	return {
		{
			-- a snap of air at the bow as each arrow is loosed
			name = "snap",
			texture = "streak_lens",
			color = AIR,
			caster = { 0.5, 1, -1.4 },
			orientation = "VelocityParallel",
			life = { 0.12, 0.18 },
			size = { { 0, 1.6 }, { 1, 0.6 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			speed = { 6, 10 },
			spread = { 25, 25 },
			direction = "Front",
			lightEmission = 0.8,
			brightness = 1.5,
			bursts = releases(count),
		},
		{
			-- where each arrow strikes: a puff of dust ...
			name = "thud",
			texture = "dust_kick_flip",
			color = DUST,
			onLand = true,
			count = 2,
			life = { 0.4, 0.6 },
			size = { { 0, 0.8 }, { 1, 2.2 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			speed = { 2, 4 },
			spread = { 60, 60 },
			direction = "Top",
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
		},
		{
			-- ... and grit kicked up over the area as they land
			name = "grit",
			texture = "rocks",
			color = { { 255, 255, 255 } },
			at = "feet",
			shape = "Disc",
			radius = RADIUS,
			direction = "Top",
			life = { 0.4, 0.6 },
			size = { { 0, 0.25 }, { 1, 0.15 } },
			speed = { 6, 10 },
			spread = { 30, 30 },
			accel = { 0, -40, 0 },
			rotation = { -180, 180 },
			rotSpeed = { -300, 300 },
			lightEmission = 0,
			locked = false,
			secondary = true,
			stream = { from = 0.5, to = done, rate = { 30, 30 } },
		},
		{
			-- a haze of dust hanging over the area when the last has struck
			name = "haze",
			texture = "dust_ring",
			color = DUST,
			at = "ground",
			flat = true,
			count = 1,
			delay = done - 0.15,
			life = { 1, 1 },
			size = { { 0, RADIUS * 1.6 }, { 1, RADIUS * 2.8 } },
			transparency = { { 0, 0.35 }, { 1, 1 } },
			rotation = { -180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
		},
	}
end

local function level(count)
	local first = 0.03 + FLIGHTS[1]
	return {
		beams = arrows(count),
		pieces = pieces(count),
		-- (peak: the most arrows in the air at once, for the preview)
		markers = { loose = 0.03, impact = first, last = last(count), peak = first - 0.12 },
	}
end

local variants = {}
for name, count in LEVELS do
	variants[name] = level(count)
end
local LV3 = variants.lv3

return {
	id = "skill.arrow_volley",
	name = "Arrow Volley",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "bow", "arrows", "volley", "rain", "ranged", "aoe", "dust", "skill" },
	blend = "additive",
	tintable = false,
	markers = LV3.markers,
	beams = LV3.beams,
	pieces = LV3.pieces,
	variants = { lv1 = variants.lv1, lv2 = variants.lv2, lv3 = {} },
	defaultVariant = "lv3",
	source = {
		from = "the library (physical skills, 2026-11-09)",
		art = "EffectCraft (arrow_steel, dust_ring: textures/fx); free Creator Store pack textures (no scripts: streak_mist, streak_lens, dust_kick_flip, rocks)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the target with opts.from = the archer's bow hand: an arrow loosed every 0.035 s, the first strikes at markers.impact (0.63 s), the last at markers.last (about 1.1 s at lv3); hit what stands in the 5-stud circle between them. Levels: lv1 6 arrows, lv2 10, lv3 (default) 15. skill.draw_aim is its wind-up.",
}
