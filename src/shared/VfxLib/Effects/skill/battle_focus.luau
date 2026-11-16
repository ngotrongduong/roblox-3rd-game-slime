-- Battle Focus: the wind-up of the physical skills (2026-11-09, the owner's "skills hệ vật lý": slashes, dashes,
-- thrusts, throws). It follows its host and holds about 1.1 s: a game plays it on the cast and cancels it softly
-- (VfxLib.cancel) at the strike.
-- The owner's own design (2026-11-16, after the component system's pilot, docs/vfx/components/pilot.md): "lấy khối như
-- hình trên và đẩy hạt vào tâm ... sau khi xong thì lóe tia thép như vẫn làm, vòng xoáy gió thu hẹp lại vào chân người
-- chơi, không có đất đá hay vòng bụi gì cả". Three beats, nothing on the ground but the wind:
-- 1. the gathering: white streaks of air pulled in from every side to the middle of the body, as in the shape lab's
--    picture the owner chose (a whole sphere, Surface, Inward: every streak flies to its centre), in five pulses that
--    come closer together and fuller toward the glint;
-- 2. the steel glint at the weapon hand, as before: a sharp star with a long line of light, and the light's flash;
-- 3. the wind vortex drawn down into the feet: aura.cghow_wind_swirl's vortex run backwards (the owner: "chúng ta đã
--    có hiệu ứng wind swirl ... chỉ cần đảo ngược chiều"): its rings of wind, which climb and widen, here sink from the
--    chest and close in to the feet, over its floor disc of curling gusts closing in too, from just before the glint
--    until just after it.
-- No dust, no stones, no stomp ring.
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 225, 235, 255 } } }
-- (aura.cghow_wind_swirl's mint ramp turned to ice blue, to sit with the white streaks and the steel glint)
local ICE = { { 0, { 235, 248, 255 } }, { 0.5, { 170, 215, 255 } }, { 1, { 90, 150, 240 } } }
local STEEL = { { 0, { 255, 255, 255 } }, { 1, { 200, 220, 255 } } }

return {
	id = "skill.battle_focus",
	name = "Battle Focus",
	kind = "skill",
	tier = "mid",
	host = "character",
	refHeight = 5,
	tags = { "physical", "warrior", "charge", "power_up", "wind", "steel", "character" },
	blend = "normal",
	tintable = false,
	follow = true,
	markers = { full = 1.1, peak = 0.9 },
	pieces = {
		{
			-- the gathering: streaks of air born on a sphere round the body and pulled straight in to its middle (the
			-- owner's shape-lab picture: a whole Sphere, Surface, Inward). Each streak dies as it reaches the middle;
			-- white-hot heads lead (lesson 365), and they thicken toward the glint
			name = "pull",
			texture = "cg_air_streaks",
			color = WHITE,
			at = "chest",
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Inward",
			radius = 3.2,
			orientation = "VelocityParallel",
			rotation = { -90, -90 },
			speed = { 11, 13 },
			life = { 0.22, 0.26 },
			-- (the lab's 1.6 studs read only up close: from the gameplay camera a streak must be about 4 studs long)
			size = { { 0, 4.2 }, { 1, 2.6 } },
			transparency = { { 0, 1 }, { 0.2, 0 }, { 0.75, 0 }, { 1, 1 } },
			flipbook = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true },
			lightEmission = 1,
			brightness = 2,
			-- (pulses, as in the owner's picture: each a starburst of streaks flying in together, closer together and
			-- fuller each time; the last reaches the middle as the glint fires, 0.62 + 0.24 s)
			bursts = { { 0, 12 }, { 0.2, 14 }, { 0.38, 16 }, { 0.52, 18 }, { 0.62, 22 } },
		},
		{
			-- the wind vortex drawn down into the feet: aura.cghow_wind_swirl's climbing, widening rings run backwards
			-- (the owner: "chỉ cần đảo ngược chiều"): born wide at the chest, they sink to the feet as they close in,
			-- lying flat as they fall (VelocityPerpendicular, sent down)
			name = "rings",
			texture = "cg_swirl_ring",
			color = ICE,
			at = "chest",
			orientation = "VelocityPerpendicular",
			direction = "Bottom",
			speed = { 6, 6 },
			life = { 0.5, 0.5 },
			size = { { 0, 6.4 }, { 1, 1.2 } },
			transparency = { { 0, 1 }, { 0.15, 0.25 }, { 0.75, 0.3 }, { 1, 1 } },
			rotation = { -180, 180 },
			rotSpeed = { 300, 380 },
			lightEmission = 1,
			brightness = 2.5,
			stream = { from = 0.66, to = 0.94, rate = { 14, 18 } },
		},
		{
			-- ... and the wind swirl's floor disc of curling gusts, turning faster and closing in to the feet under them
			name = "disc",
			texture = "cg_wind_disc",
			color = ICE,
			at = "ground",
			flat = true,
			speed = { 0.01, 0.01 },
			count = 1,
			delay = 0.72,
			life = { 0.6, 0.6 },
			size = { { 0, 7.4 }, { 0.4, 6 }, { 1, 0.8 } },
			transparency = { { 0, 1 }, { 0.15, 0.25 }, { 0.8, 0.3 }, { 1, 1 } },
			rotation = { -180, 180 },
			rotSpeed = { 260, 260 },
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- the steel glint at the weapon hand raised by the shoulder, the instant before the blow (out beside the body,
			-- so the gameplay camera behind it sees it, and below the head): a sharp star with long spikes, born big ...
			name = "glint",
			texture = "star_glint_sharp",
			color = STEEL,
			at = "chest",
			offset = { 2.1, 0.5, 0 },
			count = 1,
			delay = 0.85,
			life = { 0.3, 0.3 },
			size = { { 0, 2.6 }, { 0.12, 4.2 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.2 } },
			rotation = { 15, 15 },
			rotSpeed = { 90, 90 },
			lightEmission = 1,
			brightness = 4,
			zOffset = 2,
		},
		{
			-- ... and the long thin line of light a blade throws across it (the "ting" of steel), turning with the star
			name = "glint_line",
			texture = "flare_line_e",
			color = STEEL,
			at = "chest",
			offset = { 2.1, 0.5, 0 },
			count = 1,
			delay = 0.85,
			life = { 0.3, 0.3 },
			size = { { 0, 2.5 }, { 0.12, 4 }, { 1, 0 } },
			transparency = { { 0, 0.1 }, { 1, 0.4 } },
			rotation = { 15, 15 },
			rotSpeed = { 90, 90 },
			lightEmission = 1,
			brightness = 3,
			zOffset = 1.9,
		},
	},
	light = { color = { 230, 240, 255 }, range = 8, keys = { { 0, 0 }, { 0.85, 0 }, { 0.92, 3 }, { 1.2, 0 } } },
	source = {
		from = "the library (physical skills, 2026-11-09); the owner's own design 2026-11-16",
		art = "ChatGPT pictures drawn for the library (cg_air_streaks drawn for this effect; cg_swirl_ring and cg_wind_disc, aura.cghow_wind_swirl's); free Creator Store pack textures (no scripts: star_glint_sharp, flare_line_e)",
		licence = "ChatGPT output owned by the owner; Creator Store free assets (no scripts kept)",
	},
	notes = "The wind-up of the physical skills (Cross Cut, Whirlwind Slash, Blade Dance, Great Cleave, Flash Step, Leap Slam, Spear Flurry, Wind Blade; the bow skills have skill.draw_aim): play it on the caster, cancel it at the strike or on an interruption.",
}
