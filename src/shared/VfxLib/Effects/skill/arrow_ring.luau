-- Arrow Ring: a trap of arrows round the foe (bow skills, 2026-11-09: "Tiễn Trận"), a hold on one spot. The archer
-- looses arrow after arrow high over the foe; each (EffectCraft's `arrow_steel`) drops point first into the ground
-- round them in a ring and STAYS there, standing in the earth leaning out, a puff of dust where it bit, until the ring
-- is whole: a fence of arrows. Then the trap closes: a rough ring of dust rushes inward from the arrows onto the foe,
-- a white pop on them, and the arrows fade. Played at the foe with opts.from = the bow hand. Its level is the
-- variant: lv1 four arrows 3.5 studs round, lv2 six 4 studs round, lv3 (the default) eight 4.5 studs round.
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local LOOSE = 0.06 -- (seconds between arrows)
local GROUND = -2.5
local FLIGHTS = { 0.55, 0.5, 0.58, 0.52, 0.56, 0.5, 0.57, 0.53 }

local function landing(i)
	return (i - 1) * LOOSE + 0.03 + FLIGHTS[i]
end

local function snapAt(count)
	return landing(count) + 0.25
end

local function arrows(count, radius)
	local out: { any } = {}
	local snap = snapAt(count)
	for i = 1, count do
		-- (round the ring every other arrow across, so it closes from both sides)
		local k = if i % 2 == 1 then (i - 1) / 2 else count / 2 + (i - 2) / 2
		local a = math.rad(k * 360 / count + 20)
		local cx, cz = math.cos(a), math.sin(a)
		local x, z = radius * cx, radius * cz
		local at = landing(i)
		table.insert(out, {
			name = "arrow" .. i,
			texture = "arrow_steel",
			colors = { { 255, 255, 255 }, { 255, 255, 255 } },
			caster = true,
			from = { 0.5, 0.2, -0.2 },
			to = { 0.5, 2, -2.8 },
			width = { 0.8, 0.8 },
			delay = (i - 1) * LOOSE,
			life = 0.03 + FLIGHTS[i],
			transparency = { { 0, 0 }, { 1, 0 } },
			face = true,
			glow = 0,
			strike = {
				at = 0.03,
				seconds = FLIGHTS[i],
				bend = { 0, 7, 0 },
				aim = { x, GROUND + 0.2, z },
				trail = {
					texture = "streak_mist",
					colors = { { 240, 245, 255 }, { 200, 215, 235 } },
					width = 0.7,
					life = 0.25,
					glow = 1,
				},
			},
			land = "bite",
		})
		-- the arrow left standing in the ground, leaning out (nock up and out, point buried)
		table.insert(out, {
			name = "stuck" .. i,
			texture = "arrow_steel",
			colors = { { 255, 255, 255 }, { 255, 255, 255 } },
			from = { x + cx * 1.2, GROUND + 2.6, z + cz * 1.2 },
			to = { x - cx * 0.1, GROUND - 0.3, z - cz * 0.1 },
			width = { 0.8, 0.8 },
			delay = at,
			life = snap + 0.35 - at,
			transparency = { { 0, 0 }, { 1 - 0.3 / (snap + 0.35 - at), 0 }, { 1, 1 } },
			face = true,
			glow = 0,
		})
	end
	return out
end

local function level(count, radius)
	local snap = snapAt(count)
	return {
		beams = arrows(count, radius),
		pieces = {
			{
				-- a puff of dust where each arrow bites into the ground
				name = "bite",
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
				-- the trap closes: a rough ring of dust rushing in from the arrows onto the foe ...
				name = "close",
				texture = "ring_rough",
				color = DUST,
				at = "ground",
				offset = { 0, 0.15, 0 },
				flat = true,
				count = 1,
				delay = snap,
				life = { 0.35, 0.35 },
				size = { { 0, radius * 2.6 }, { 1, 2 } },
				transparency = { { 0, 0.4 }, { 0.3, 0.05 }, { 1, 0.6 } },
				rotation = { -180, 180 },
				lightEmission = 0,
				lightInfluence = 0,
			},
			{
				-- ... a white pop on the foe as it closes ...
				name = "pop",
				texture = "impact_burst",
				color = WHITE,
				at = "body",
				count = 1,
				delay = snap + 0.3,
				life = { 0.3, 0.3 },
				size = { { 0, 4 }, { 1, 7 } },
				speed = { 0.01, 0.01 },
				flipbook = { layout = "Grid4x4", mode = "OneShot" },
				lightEmission = 1,
				brightness = 1.7,
				zOffset = 3,
			},
			{
				-- ... and dust thrown up round the foe's feet
				name = "dust",
				texture = "dust_ring",
				color = DUST,
				at = "ground",
				flat = true,
				count = 1,
				delay = snap + 0.3,
				life = { 0.7, 0.7 },
				size = { { 0, 3 }, { 1, 9 } },
				transparency = { { 0, 0.15 }, { 1, 1 } },
				rotation = { -180, 180 },
				flipbook = { layout = "Grid4x4", mode = "OneShot" },
				lightEmission = 0,
				lightInfluence = 0,
			},
		},
		markers = { impact = landing(1), ring = landing(count), snap = snap + 0.3, peak = snap - 0.05 },
	}
end

local LV3 = level(8, 4.5)

return {
	id = "skill.arrow_ring",
	name = "Arrow Ring",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "bow", "arrows", "trap", "ring", "root", "ranged", "control", "dust", "skill" },
	blend = "additive",
	tintable = false,
	markers = LV3.markers,
	beams = LV3.beams,
	pieces = LV3.pieces,
	variants = { lv1 = level(4, 3.5), lv2 = level(6, 4), lv3 = {} },
	defaultVariant = "lv3",
	source = {
		from = "the library (bow skills, 2026-11-09)",
		art = "EffectCraft (arrow_steel, impact_burst, dust_ring: textures/fx); free Creator Store pack textures (no scripts: streak_mist, dust_kick_flip, ring_rough)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the foe with opts.from = the bow hand: the arrows fall round the foe from markers.impact (0.58 s), the ring is whole at markers.ring, and it closes at markers.snap (about 1.5 s at lv3): root or stun the foe there. Levels: lv1 four arrows, lv2 six, lv3 (default) eight. skill.draw_aim is its wind-up.",
}
