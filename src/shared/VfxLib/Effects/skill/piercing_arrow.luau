-- Piercing Arrow: one arrow drawn to the full and loosed straight through (bow skills, 2026-11-09: "Xuyên Tâm
-- Tiễn"), a line attack. A snap of air and a white pop at the bow; the arrow (EffectCraft's `arrow_steel`) flies dead
-- straight and fast, a pale ribbon of air and a thin line of vapour behind it. It hits: a white pop with
-- speed lines, and it does not stop: the arrow flies on out of the far side, a gust and grit thrown on; at lv3 lines
-- of speed hang along the whole path and a cone of air is blown open behind the foe. Played at the foe with
-- opts.from = the bow hand. Its level is the variant: lv1 the arrow and the hit, lv2 the arrow flying on, lv3 (the
-- default) the speed lines and the cone.
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } }
local AIR = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local FLIGHT = 0.22
local CHEST = 2.8 -- (studs over the ground of the path's frame)

-- the arrow flying on out of the far side (the same arrow, rolled on past the foe)
local EXIT = {
	name = "exit",
	texture = "arrow_steel",
	colors = { { 255, 255, 255 }, { 255, 255, 255 } },
	along = 1,
	from = { 0, CHEST, 1.6 },
	to = { 0, CHEST, -1.6 },
	face = true,
	width = { 0.9, 0.9 },
	life = 0.16,
	roll = { to = 1.5, seconds = 0.16 },
	transparency = { { 0, 0 }, { 0.6, 0 }, { 1, 1 } },
	glow = 0,
	zOffset = 1,
}

local function speedLines()
	local out = {}
	for index, spot in { { -0.5, CHEST + 0.5 }, { 0.6, CHEST - 0.4 } } do
		table.insert(out, {
			name = "speed" .. index,
			texture = "streak_mist",
			colors = { { 220, 232, 255 }, { 255, 255, 255 } },
			along = { 0.1, 1 },
			from = { spot[1], spot[2], 0 },
			to = { spot[1] * 0.3, spot[2], 0 },
			face = true,
			width = { 0.3, 1.1 },
			life = 0.45,
			transparency = { { 0, 0.25 }, { 1, 1 } },
			edge = { 0.8, 0 },
			glow = 1.8,
		})
	end
	return out
end

local function pieces(n)
	local out = {
		{
			-- the loose: a snap of air and a small white pop at the bow (timed from the cast)
			name = "loose",
			texture = "impact_burst",
			color = WHITE,
			caster = { 0, 0, -1.2 },
			cast = true,
			count = 1,
			life = { 0.2, 0.2 },
			size = { { 0, 1.5 }, { 1, 3 } },
			speed = { 0.01, 0.01 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 1.5,
			zOffset = 2,
		},
		{
			-- the hit: a white pop with speed lines ...
			name = "pop",
			texture = "impact_burst",
			color = WHITE,
			at = "body",
			count = 1,
			life = { 0.3, 0.3 },
			size = { { 0, 4 }, { 1, if n == 3 then 8 else 6.5 } },
			speed = { 0.01, 0.01 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 1.8,
			zOffset = 3,
		},
		{
			-- ... and splinters and grit blown out of the far side
			name = "grit",
			texture = "rocks",
			color = { { 255, 255, 255 } },
			along = 1,
			offset = { 0, CHEST, -0.8 },
			count = 8,
			life = { 0.4, 0.7 },
			size = { { 0, 0.3 }, { 1, 0.2 } },
			speed = { 12, 20 },
			spread = { 25, 25 },
			direction = "Front",
			accel = { 0, -35, 0 },
			rotation = { -180, 180 },
			rotSpeed = { -400, 400 },
			lightEmission = 0,
			locked = false,
			secondary = true,
		},
	}
	if n >= 2 then
		table.insert(out, {
			-- a gust blown on out of the far side
			name = "gust",
			texture = "streaks_flat",
			color = AIR,
			along = 1,
			offset = { 0, CHEST, -0.8 },
			orientation = "VelocityParallel",
			count = if n == 3 then 14 else 8,
			life = { 0.2, 0.3 },
			size = { { 0, 2.4 }, { 1, 1 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			speed = { 30, 45 },
			spread = { 15, 15 },
			direction = "Front",
			drag = 4,
			lightEmission = 0.7,
			brightness = 1.4,
			locked = false,
		})
	end
	if n == 3 then
		table.insert(out, {
			-- a cone of air blown open behind the foe, standing across the line
			name = "cone",
			texture = "ring_rays",
			color = WHITE,
			along = 1,
			offset = { 0, CHEST, -2.5 },
			upright = true,
			count = 1,
			life = { 0.3, 0.3 },
			size = { { 0, 2 }, { 1, 7.5 } },
			transparency = { { 0, 0.1 }, { 1, 1 } },
			rotation = { -180, 180 },
			lightEmission = 1,
			brightness = 1.5,
		})
		table.insert(out, {
			-- dust kicked off the ground under the exit
			name = "dust",
			texture = "dust_kick_flip",
			color = DUST,
			along = 1,
			offset = { 0, 0.3, -2 },
			count = 6,
			life = { 0.5, 0.8 },
			size = { { 0, 1.2 }, { 1, 3 } },
			transparency = { { 0, 0.3 }, { 1, 1 } },
			speed = { 5, 9 },
			spread = { 35, 25 },
			direction = "Front",
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
			locked = false,
		})
	end
	return out
end

local function level(n)
	local beams = {}
	if n >= 2 then
		table.insert(beams, EXIT)
	end
	if n == 3 then
		for _, beam in speedLines() do
			table.insert(beams, beam)
		end
	end
	return { beams = beams, pieces = pieces(n) }
end

local LV3 = level(3)

return {
	id = "skill.piercing_arrow",
	name = "Piercing Arrow",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "bow", "arrow", "pierce", "projectile", "ranged", "line", "single", "skill" },
	blend = "additive",
	tintable = false,
	markers = { impact = FLIGHT, peak = FLIGHT + 0.05 },
	projectile = {
		seconds = FLIGHT,
		arc = 0,
		head = {
			texture = "arrow_steel",
			length = 3.4,
			width = 0.9,
			color = { { 255, 255, 255 } },
			glow = 0,
			zOffset = 1,
		},
		riders = {
			{
				-- a thin line of vapour torn off behind the arrow (curls of wind spun round it read as soap bubbles)
				name = "vapour",
				texture = "smoke_cloud_soft",
				color = AIR,
				life = { 0.25, 0.4 },
				size = { { 0, 0.7 }, { 1, 1.6 } },
				transparency = { { 0, 0.45 }, { 1, 1 } },
				speed = { 0.2, 0.5 },
				spread = { 180, 180 },
				rotation = { -180, 180 },
				lightEmission = 0.6,
				brightness = 1,
				stream = { from = 0, to = FLIGHT, rate = { 70, 70 } },
			},
		},
		trail = {
			texture = "streak_mist",
			colors = { { 240, 245, 255 }, { 200, 215, 235 } },
			width = 1.2,
			life = 0.35,
			glow = 1.5,
		},
	},
	beams = LV3.beams,
	pieces = LV3.pieces,
	variants = { lv1 = level(1), lv2 = level(2), lv3 = {} },
	defaultVariant = "lv3",
	-- (low: at 3 it washed the foe pale blue before the arrow had reached them)
	light = { color = { 235, 240, 255 }, range = 12, keys = { { 0, 0 }, { 0.02, 2 }, { 0.3, 0 } } },
	source = {
		from = "the library (bow skills, 2026-11-09)",
		art = "EffectCraft (arrow_steel, impact_burst: textures/fx); free Creator Store pack textures (no scripts: smoke_cloud_soft, streak_mist, streaks_flat, ring_rays, rocks, dust_kick_flip)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the foe with opts.from = the bow hand as the string is let go: the arrow strikes at markers.impact (0.22 s) and flies on through (hit everything on the line). Levels: lv1, lv2 (spiral, the arrow flying on), lv3 (default, speed lines and a bigger exit). skill.draw_aim is its wind-up.",
}
