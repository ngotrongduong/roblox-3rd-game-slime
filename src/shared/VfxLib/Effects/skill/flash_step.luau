-- Flash Step: a dash that cuts on the way through (physical skills, 2026-11-09: "Thiểm Bộ Trảm"). The warrior kicks
-- off in a burst of dust and crosses to the foe in 0.14 s: a white streak of speed, thin lines of air left hanging
-- along the path, wisps shed behind. Arriving, they are already past: thin white cut lines hang across the foe for a
-- breath, then the cuts OPEN (the delayed cut of a sword drawn too fast to see): crescents of steel flare along the
-- lines, a white pop with speed lines, hot sparks, dust blown on past the foe. Played at the foe with opts.from = the
-- attacker (the projectile is the dash itself; the game moves the body). Its level is the variant: lv1 one level cut,
-- lv2 an X, lv3 (the default) an X and a level cut through it.
local STEEL = { { 175, 195, 225 }, { 230, 238, 255 }, { 255, 255, 255 } }
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } }
local HOT = { { 0, { 255, 250, 220 } }, { 0.4, { 255, 200, 90 } }, { 1, { 255, 110, 30 } } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local DASH = 0.14
local OPEN = 0.42 -- (after the arrival: the cuts open)
local CHEST = 3 -- (studs over the ground of the path's frame)

-- the lines of speed left hanging along the path, from the kick-off to the foe
local function speedLines()
	local out: { any } = {}
	for index, spot in { { -0.6, CHEST + 0.4 }, { 0.5, CHEST - 0.3 }, { 0, CHEST + 1.1 } } do
		table.insert(out, {
			name = "speed" .. index,
			-- (a ribbon of streaks: the thin streak_slash needle was lost from 12 studs)
			texture = "streak_mist",
			colors = { { 220, 232, 255 }, { 255, 255, 255 } },
			along = { 0, 1 },
			from = { spot[1], spot[2], 0 },
			to = { spot[1] * 0.4, spot[2], 1.5 },
			face = true,
			width = { 0.4, 1.3 },
			delay = 0,
			life = 0.45,
			transparency = { { 0, 0.2 }, { 1, 1 } },
			edge = { 0.8, 0 },
			glow = 2,
		})
	end
	return out
end

-- a cut across the foe: a thin white line that hangs, then the cut opens along it (a crescent of steel flaring)
local function cut(name, from, to, bulge, at)
	return {
		{
			name = name,
			texture = "streak_slash",
			colors = { { 255, 255, 255 }, { 255, 255, 255 } },
			along = 1,
			from = from,
			to = to,
			face = true,
			width = { 0.5, 0.5 },
			delay = at,
			life = OPEN - at + 0.08,
			transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
			grow = { { 0, 0.4 }, { 0.15, 1 }, { 0.8, 1 }, { 1, 3 } },
			glow = 3,
			zOffset = 2,
		},
		{
			name = name .. "_open",
			texture = "slash_steel",
			colors = STEEL,
			along = 1,
			from = from,
			to = to,
			bulge = bulge,
			face = true,
			width = { 2.6, 2.6 },
			delay = OPEN,
			life = 0.3,
			transparency = { { 0, 0 }, { 0.3, 0 }, { 1, 1 } },
			grow = { { 0, 0.3 }, { 0.2, 1 }, { 1, 1.2 } },
			edge = { 0.5, 0 },
			segments = 16,
			glow = 2.4,
			zOffset = 1,
		},
	}
end

local LEVEL = { { -3.4, CHEST + 0.2, 0 }, { 3.4, CHEST + 0.4, 0 }, { 0, -0.8, -0.6 } }
local DOWN = { { -2.8, CHEST + 2.6, 0 }, { 2.8, CHEST - 2, 0 }, { 1.2, 1.4, -0.4 } }
local UP = { { 2.8, CHEST + 2.6, 0 }, { -2.8, CHEST - 2, 0 }, { -1.2, 1.4, -0.4 } }

local function level(n)
	local beams = speedLines()
	local cuts = if n == 1 then { LEVEL } elseif n == 2 then { DOWN, UP } else { DOWN, UP, LEVEL }
	for index, line in cuts do
		for _, beam in cut("cut" .. index, line[1], line[2], line[3], 0.03 + (index - 1) * 0.03) do
			table.insert(beams, beam)
		end
	end
	return beams
end

return {
	id = "skill.flash_step",
	name = "Flash Step",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "sword", "dash", "iaido", "slash", "speed", "steel", "melee", "single", "skill" },
	blend = "additive",
	tintable = false,
	markers = { arrive = DASH, split = DASH + OPEN, impact = DASH + OPEN, peak = DASH + OPEN + 0.04 },
	projectile = {
		-- the dash: a white streak flying from the attacker to the foe (drawn level, laid along the flight)
		texture = "streaks_flat",
		color = { { 255, 255, 255 } },
		size = { { 0, 4.5 }, { 1, 5.5 } },
		transparency = { { 0, 0.2 }, { 1, 0.2 } },
		lightEmission = 1,
		brightness = 2,
		zOffset = 2,
		seconds = DASH,
		arc = 0,
		riders = {
			{
				-- the kick-off: dust burst where the attacker stood
				name = "kickoff",
				texture = "dust_kick_flip",
				color = DUST,
				count = 8,
				delay = 0,
				life = { 0.5, 0.8 },
				size = { { 0, 1.5 }, { 1, 3.5 } },
				transparency = { { 0, 0.25 }, { 1, 1 } },
				speed = { 4, 8 },
				spread = { 180, 60 },
				drag = 3,
				rotation = { -30, 30 },
				flipbook = { layout = "Grid4x4", mode = "OneShot" },
				lightEmission = 0,
				lightInfluence = 0,
			},
			{
				-- wisps of air shed behind on the way
				name = "wisps",
				texture = "streak_lens",
				color = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } },
				orientation = "VelocityParallel",
				life = { 0.25, 0.4 },
				size = { { 0, 1.4 }, { 1, 0.5 } },
				transparency = { { 0, 0.2 }, { 1, 1 } },
				speed = { 1, 3 },
				spread = { 180, 180 },
				squash = { { 0, -1.5 }, { 1, -1 } },
				lightEmission = 0.8,
				brightness = 1.5,
				stream = { from = 0, to = DASH, rate = { 160, 160 } },
			},
		},
		trail = {
			texture = "streak_mist",
			colors = { { 255, 255, 255 }, { 200, 215, 240 } },
			width = 2.4,
			life = 0.35,
			glow = 2.2,
		},
	},
	beams = level(3),
	pieces = {
		{
			-- a ring of dust where the attacker kicked off
			name = "kick_ring",
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
			-- dust skidding on past the foe where the attacker stops
			name = "skid",
			texture = "dust_kick_flip",
			color = DUST,
			along = 1,
			offset = { 0, 0.3, -2.5 },
			count = 8,
			life = { 0.5, 0.8 },
			size = { { 0, 1.4 }, { 1, 3.2 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			speed = { 6, 10 },
			spread = { 30, 20 },
			direction = "Front",
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
		},
		{
			-- the cuts open: a white pop with speed lines ...
			name = "pop",
			texture = "impact_burst",
			color = WHITE,
			along = 1,
			offset = { 0, CHEST, 0 },
			count = 1,
			delay = OPEN,
			life = { 0.35, 0.35 },
			size = { { 0, 6 }, { 1, 9.5 } },
			speed = { 0.01, 0.01 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 2,
			zOffset = 3,
		},
		{
			-- ... hot sparks every way ...
			name = "sparks",
			texture = "spark_dot",
			color = HOT,
			along = 1,
			offset = { 0, CHEST, 0 },
			orientation = "VelocityParallel",
			count = 28,
			delay = OPEN,
			life = { 0.3, 0.55 },
			size = { { 0, 0.5 }, { 1, 0.1 } },
			transparency = { { 0, 0 }, { 1, 0.3 } },
			speed = { 18, 30 },
			spread = { 180, 180 },
			squash = { { 0, -1 }, { 1, -0.6 } },
			drag = 3,
			accel = { 0, -24, 0 },
			lightEmission = 1,
			brightness = 3,
			locked = false,
		},
		{
			-- ... and the air of the cut blown on past the foe
			name = "gust",
			texture = "streaks_flat",
			color = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } },
			along = 1,
			offset = { 0, CHEST, 0 },
			orientation = "VelocityParallel",
			count = 10,
			delay = OPEN,
			life = { 0.2, 0.3 },
			size = { { 0, 2.2 }, { 1, 1 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			speed = { 30, 45 },
			spread = { 25, 25 },
			direction = "Front",
			drag = 4,
			lightEmission = 0.7,
			brightness = 1.4,
			locked = false,
			secondary = true,
		},
	},
	variants = { lv1 = { beams = level(1) }, lv2 = { beams = level(2) }, lv3 = {} },
	defaultVariant = "lv3",
	light = {
		color = { 235, 240, 255 },
		range = 14,
		keys = { { 0, 1.5 }, { 0.2, 0.5 }, { OPEN, 5 }, { OPEN + 0.5, 0 } },
	},
	source = {
		from = "the library (physical skills, 2026-11-09)",
		art = "EffectCraft (slash_steel, impact_burst, dust_ring: textures/fx); free Creator Store pack textures (no scripts: streaks_flat, streak_lens, streak_mist, streak_slash, dust_kick_flip, spark_dot)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the foe with opts.from = the attacker's chest as the dash starts; move the body there in 0.14 s (markers.arrive) and on a few studs past. The damage lands when the cuts open, markers.impact (0.56 s): shake and hit-stop there. Levels: lv1 one cut, lv2 an X, lv3 (default) an X and a level cut. skill.battle_focus is its wind-up.",
}
