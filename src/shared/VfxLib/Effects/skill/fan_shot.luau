-- Fan Shot: a handful of arrows loosed at once, fanned out (bow skills, 2026-11-09: "Tán Tiễn"), a cone attack in
-- front. A white pop and a gust of air at the bow; the arrows (EffectCraft's `arrow_steel`) fly out low and flat, each
-- on its own line of the fan, a pale streak behind each; where each one strikes, a small white pop. Played at the
-- ARCHER's frame (VfxLib.play(id, root.CFrame)): the arrows fly 16 studs ahead. Its level is the variant: lv1 three
-- arrows in a 30 degree fan, lv2 five in 50, lv3 (the default) seven in 70.
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } }
local AIR = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 155, 140, 115 } } }
local RANGE = 16
local FLIGHT = 0.3
local BOW = { 0.5, 0.8, -1 }

local function arrows(count, span)
	local out: { any } = {}
	for i = 1, count do
		local share = (i - 1) / (count - 1) - 0.5
		local a = math.rad(share * span)
		local x, z = math.sin(a), -math.cos(a)
		-- (the middle arrow first, the outer ones a hair later)
		local delay = math.abs(share) * 0.04
		table.insert(out, {
			name = "arrow" .. i,
			texture = "arrow_steel",
			colors = { { 255, 255, 255 }, { 255, 255, 255 } },
			-- (from the nock to the point, laid along its own line of the fan)
			from = { BOW[1] - x * 1.6, BOW[2], BOW[3] - z * 1.6 },
			to = { BOW[1] + x * 1.6, BOW[2], BOW[3] + z * 1.6 },
			width = { 0.8, 0.8 },
			delay = delay,
			life = 0.02 + FLIGHT,
			transparency = { { 0, 0 }, { 1, 0 } },
			face = true,
			glow = 0,
			zOffset = 1,
			strike = {
				at = 0.02,
				seconds = FLIGHT,
				bend = { 0, 0.6, 0 },
				aim = { x * RANGE, 0.2, z * RANGE },
				wander = 0.3,
				trail = {
					texture = "streak_mist",
					colors = { { 240, 245, 255 }, { 200, 215, 235 } },
					width = 0.8,
					life = 0.25,
					glow = 1.2,
				},
			},
			land = "hit",
		})
	end
	return out
end

local function level(count, span)
	return {
		beams = arrows(count, span),
		markers = { loose = 0.02, impact = 0.02 + FLIGHT, peak = 0.02 + FLIGHT * 0.6 },
	}
end

local LV3 = level(7, 70)

return {
	id = "skill.fan_shot",
	name = "Fan Shot",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "bow", "arrows", "fan", "multishot", "projectile", "ranged", "cone", "skill" },
	blend = "additive",
	tintable = false,
	markers = LV3.markers,
	beams = LV3.beams,
	pieces = {
		{
			-- the loose: a white pop at the bow ...
			name = "loose",
			texture = "impact_burst",
			color = WHITE,
			offset = BOW,
			count = 1,
			life = { 0.2, 0.2 },
			size = { { 0, 2 }, { 1, 4 } },
			speed = { 0.01, 0.01 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 1.5,
			zOffset = 2,
		},
		{
			-- ... and a gust of air thrown out over the fan
			name = "gust",
			texture = "streaks_flat",
			color = AIR,
			offset = BOW,
			orientation = "VelocityParallel",
			count = 14,
			life = { 0.2, 0.32 },
			size = { { 0, 2.2 }, { 1, 0.8 } },
			transparency = { { 0, 0.25 }, { 1, 1 } },
			speed = { 30, 45 },
			spread = { 35, 8 },
			direction = "Front",
			drag = 4,
			lightEmission = 0.7,
			brightness = 1.4,
			locked = false,
		},
		{
			-- dust blown off the ground in front of the archer
			name = "dust",
			texture = "dust_kick_flip",
			color = DUST,
			at = "ground",
			offset = { 0, 0.3, -1.5 },
			count = 5,
			life = { 0.4, 0.7 },
			size = { { 0, 1 }, { 1, 2.6 } },
			transparency = { { 0, 0.35 }, { 1, 1 } },
			speed = { 5, 9 },
			spread = { 35, 15 },
			direction = "Front",
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
			locked = false,
			secondary = true,
		},
		{
			-- where each arrow strikes: a small white pop
			name = "hit",
			texture = "impact_burst",
			color = WHITE,
			onLand = true,
			count = 1,
			life = { 0.2, 0.2 },
			size = { { 0, 1.8 }, { 1, 3.2 } },
			speed = { 0.01, 0.01 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 1.6,
			zOffset = 2,
		},
	},
	variants = { lv1 = level(3, 30), lv2 = level(5, 50), lv3 = {} },
	defaultVariant = "lv3",
	light = { color = { 235, 240, 255 }, range = 10, keys = { { 0, 2.5 }, { 0.3, 0 } } },
	source = {
		from = "the library (bow skills, 2026-11-09)",
		art = "EffectCraft (arrow_steel, impact_burst: textures/fx); free Creator Store pack textures (no scripts: streak_mist, streaks_flat, dust_kick_flip)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the archer's root CFrame as the string is let go: the arrows fly 16 studs ahead in a fan and strike at markers.impact (0.32 s); hit what stands in the cone. Levels: lv1 three arrows (30 degrees), lv2 five (50), lv3 (default) seven (70). skill.draw_aim is its wind-up.",
}
