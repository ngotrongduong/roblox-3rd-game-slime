-- Whirlwind Slash: the warrior spins with the blade held out (physical skills, 2026-11-09: "Toàn Phong Trảm"), an
-- area attack all round. Each turn is drawn as four quarter arcs of swept steel lying flat at the blade's reach, one
-- after another round the body (right, ahead, left, behind), so the eye follows the spin; each turn a little higher.
-- Dust is torn off the ground in a ring that blows outward with every turn, curls of wind whip round the body, grit
-- and sparks fly off the rim. At lv3 the last turn ends in a wide ring cut and a shockwave of dust. Played at the
-- ATTACKER's frame (VfxLib.play(id, root.CFrame)). Its level is the variant: lv1 one turn, lv2 two, lv3 (the
-- default) three and the ring cut.
local STEEL = { { 175, 195, 225 }, { 230, 238, 255 }, { 255, 255, 255 } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local AIR = { { 0, { 240, 248, 255 } }, { 1, { 195, 210, 235 } } }
local HOT = { { 0, { 255, 250, 220 } }, { 0.4, { 255, 200, 90 } }, { 1, { 255, 110, 30 } } }
local REACH = 4.6
local TURN = 0.24 -- (seconds a turn)
local QUARTER = TURN / 4
local FINALE = 3 * TURN

-- a point on the blade's circle: `angle` degrees from ahead toward the right
local function on(angle, radius, y)
	local a = math.rad(angle)
	return { radius * math.sin(a), y, -radius * math.cos(a) }
end

-- one quarter of a turn, from `angle` round to `angle` - 90 (right to ahead to left to behind), lying flat, bowed
-- outward so its peak sits on the circle
local function quarter(name, angle, radius, y, delay, wide)
	local mid = math.rad(angle - 45)
	local push = radius * (1 - math.cos(math.rad(45))) / 0.75
	return {
		name = name,
		texture = "slash_steel",
		colors = STEEL,
		from = on(angle, radius, y),
		to = on(angle - 90, radius, y),
		bulge = { push * math.sin(mid), 0, -push * math.cos(mid) },
		width = { wide * 0.7, wide },
		delay = delay,
		life = 0.26,
		transparency = { { 0, 0 }, { 0.3, 0 }, { 1, 1 } },
		grow = { { 0, 0.6 }, { 0.3, 1 }, { 1, 1.15 } },
		edge = { 0.6, 0 },
		segments = 12,
		glow = 2.2,
	}
end

local function turns(count)
	local out: { any } = {}
	for t = 1, count do
		for q = 1, 4 do
			-- (each turn a little higher, and starting a little further round)
			table.insert(
				out,
				quarter(
					`t{t}q{q}`,
					90 - (q - 1) * 90 + (t - 1) * 20,
					REACH,
					-0.7 + (t - 1) * 0.55,
					(t - 1) * TURN + (q - 1) * QUARTER,
					2.2
				)
			)
		end
	end
	return out
end

-- the ring cut that ends lv3: two halves at once, wider and lower
local function ring()
	local push = 6.4 * 4 / 3
	local out: { any } = {}
	for index, side in { 1, -1 } do
		table.insert(out, {
			name = "ring" .. index,
			texture = "slash_steel",
			colors = STEEL,
			from = { 6.4 * side, -0.9, 0 },
			to = { -6.4 * side, -0.9, 0 },
			bulge = { 0, 0, -push * side },
			width = { 2.6, 2.6 },
			delay = FINALE,
			life = 0.35,
			transparency = { { 0, 0 }, { 0.4, 0 }, { 1, 1 } },
			grow = { { 0, 0.5 }, { 0.2, 1 }, { 1, 1.2 } },
			edge = { 0.2, 0.2 },
			segments = 20,
			glow = 2.6,
			zOffset = 1,
		})
	end
	return out
end

local function each(count, n, extra)
	local out: { any } = {}
	for t = 1, count do
		table.insert(out, { (t - 1) * TURN + 0.02, n })
	end
	if extra then
		table.insert(out, extra)
	end
	return out
end

local function pieces(count, finale)
	return {
		{
			-- dust torn off the ground in a ring blown outward, every turn
			name = "dust_ring",
			texture = "dust_ring",
			color = DUST,
			at = "ground",
			flat = true,
			life = { 0.6, 0.6 },
			size = { { 0, 4 }, { 1, 10 } },
			transparency = { { 0, 0.2 }, { 1, 1 } },
			rotation = { -180, 180 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
			bursts = each(count, 1, if finale then { FINALE, 1 } else nil),
		},
		{
			-- clouds of dust kicked out from under the feet
			name = "kick",
			texture = "dust_kick_flip",
			color = DUST,
			at = "feet",
			shape = "Disc",
			shapeInOut = "Outward",
			radius = 2.5,
			life = { 0.5, 0.8 },
			size = { { 0, 1.2 }, { 1, 3 } },
			transparency = { { 0, 0.3 }, { 1, 1 } },
			speed = { 6, 10 },
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
			bursts = each(count, 5, if finale then { FINALE, 10 } else nil),
		},
		{
			-- curls of wind whipping round the body with the spin
			name = "curls",
			texture = "windspin_b",
			color = AIR,
			at = "waist",
			shape = "Disc",
			radius = 3.4,
			spin = -3,
			life = { 0.3, 0.45 },
			size = { { 0, 2.5 }, { 1, 4 } },
			transparency = { { 0, 0.35 }, { 1, 1 } },
			speed = { 0.5, 1 },
			rotation = { -180, 180 },
			rotSpeed = { -500, -300 },
			lightEmission = 0.7,
			brightness = 1.4,
			stream = { from = 0, to = count * TURN, rate = { 24, 24 } },
		},
		{
			-- hot sparks and grit flung off the rim, along the spin
			name = "sparks",
			texture = "spark_dot",
			color = HOT,
			at = "waist",
			shape = "Disc",
			shapeInOut = "Outward",
			radius = REACH,
			orientation = "VelocityParallel",
			life = { 0.2, 0.4 },
			size = { { 0, 0.4 }, { 1, 0.1 } },
			transparency = { { 0, 0 }, { 1, 0.3 } },
			speed = { 14, 22 },
			squash = { { 0, -0.8 }, { 1, -0.6 } },
			drag = 3,
			accel = { 0, -20, 0 },
			lightEmission = 1,
			brightness = 3,
			locked = false,
			stream = { from = 0.03, to = count * TURN, rate = { 40, 40 } },
		},
		{
			-- pebbles thrown off the ground round the feet
			name = "grit",
			texture = "rocks",
			color = { { 255, 255, 255 } },
			at = "feet",
			shape = "Disc",
			shapeInOut = "Outward",
			radius = 2,
			life = { 0.5, 0.8 },
			size = { { 0, 0.3 }, { 1, 0.2 } },
			speed = { 8, 14 },
			accel = { 0, -30, 0 },
			rotation = { -180, 180 },
			rotSpeed = { -300, 300 },
			lightEmission = 0,
			locked = false,
			secondary = true,
			bursts = each(count, 4, if finale then { FINALE, 10 } else nil),
		},
	}
end

local FINISH = {
	{
		-- lv3's end: a shockwave of dust racing out along the ground ...
		name = "shock",
		texture = "ring_rough",
		color = DUST,
		at = "ground",
		flat = true,
		count = 1,
		delay = FINALE,
		life = { 0.5, 0.5 },
		size = { { 0, 5 }, { 1, 17 } },
		transparency = { { 0, 0.1 }, { 0.6, 0.4 }, { 1, 1 } },
		rotation = { -180, 180 },
		lightEmission = 0,
		lightInfluence = 0,
	},
	{
		-- ... and the air cracked by the ring cut: speed lines flying out from the body
		name = "pop",
		texture = "impact_burst",
		color = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } },
		at = "waist",
		flat = true,
		count = 1,
		delay = FINALE,
		life = { 0.35, 0.35 },
		size = { { 0, 9 }, { 1, 15 } },
		flipbook = { layout = "Grid4x4", mode = "OneShot" },
		lightEmission = 1,
		brightness = 1.6,
	},
}

local LV3 = turns(3)
for _, beam in ring() do
	table.insert(LV3, beam)
end
local LV3_PIECES = pieces(3, true)
for _, piece in FINISH do
	table.insert(LV3_PIECES, piece)
end

return {
	id = "skill.whirlwind_slash",
	name = "Whirlwind Slash",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "sword", "slash", "spin", "whirlwind", "steel", "dust", "melee", "aoe", "skill" },
	blend = "additive",
	tintable = false,
	markers = { contact = 0.03, finish = FINALE, impact = FINALE, peak = FINALE + 0.05 },
	beams = LV3,
	pieces = LV3_PIECES,
	variants = {
		lv1 = { beams = turns(1), pieces = pieces(1, false), markers = { contact = 0.03, peak = 0.2 } },
		lv2 = { beams = turns(2), pieces = pieces(2, false), markers = { contact = 0.03, peak = TURN + 0.2 } },
		lv3 = {},
	},
	defaultVariant = "lv3",
	light = {
		color = { 235, 240, 255 },
		range = 14,
		keys = { { 0, 0 }, { 0.05, 2 }, { FINALE, 2 }, { FINALE + 0.05, 4 }, { FINALE + 0.6, 0 } },
	},
	source = {
		from = "the library (physical skills, 2026-11-09)",
		art = "EffectCraft (slash_steel, dust_ring, impact_burst: textures/fx); free Creator Store pack textures (no scripts: dust_kick_flip, windspin_b, spark_dot, rocks, ring_rough)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the attacker's root CFrame as the spin starts; a turn takes 0.24 s (hits at each turn). Levels: lv1 one turn, lv2 two, lv3 (default) three and a ring cut with a dust shockwave at 0.72 s (markers.impact). skill.battle_focus is its wind-up.",
}
