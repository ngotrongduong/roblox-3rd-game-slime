-- Spirit Guardian: a summoning skill (2026-11-09, the owner's "summoning ... hỗ trợ tấn công hoặc bảo vệ": "Thần Hộ
-- Vệ"), a holy guardian called to protect. A holy circle opens under the caster and a column of light wells up behind
-- them; out of it rises a giant knight of gold-white light (ChatGPT, seen from behind: a tower shield, a long sword
-- held point down, a cape of light), standing at the caster's left shoulder, see-through. He raises his
-- shield: a glint, and at lv2 a wall of holy runes stands before the caster, catching what comes; feathers of light
-- drift down. At lv3 he drives his sword into the ground ahead: a holy blast and a shockwave push the foes back. Then
-- he fades up into motes of light. Played at the caster's own CFrame. Its level is the variant: lv1 the guardian, lv2
-- the wall, lv3 (the default) the sword.
-- (coloured normal bodies: added light on him was a yellow-white blaze on bright grass, 2026-11-14)
local GOLD = { { 0, { 245, 205, 80 } }, { 1, { 205, 145, 25 } } }
local GROUND = -2.5 -- (the ground under the caster's root)
-- (where the guardian stands: behind the caster's left shoulder, off the line from the player's camera to the caster;
-- straight behind them he stood between the camera and the caster, a blaze filling the picture)
local SIDE = -3.6
local BEHIND = 1.2
local RISE = 0.1
local OUT = 0.7
local RAISE = 0.9 -- (the shield is raised)
local SMITE = 1.3 -- (lv3: the sword in the ground)
local END = 4

local GUARDIAN = {
	name = "guardian",
	texture = "summon_guardian",
	colors = { { 190, 135, 40 }, { 150, 95, 20 } },
	-- (from his feet under the ground to the top of his crest: the picture is stored that way)
	from = { SIDE, GROUND - 0.3, BEHIND },
	to = { SIDE, GROUND + 9, BEHIND },
	width = { 9, 9 },
	delay = RISE,
	life = END - RISE,
	-- (see-through: the caster shows through him from the player's camera)
	transparency = { { 0, 0.2 }, { 0.85, 0.25 }, { 1, 1 } },
	face = true,
	-- (his own colours as drawn, barely lit: his shield, sword and cape must read on grass and snow)
	glow = 0,
	zOffset = -1,
	emerge = OUT,
}

local function pieces(n)
	local out = {
		{
			-- the holy circle opening under the caster
			name = "circle",
			texture = "floor_holy",
			color = GOLD,
			at = "ground",
			offset = { 0, 0.1, 0.8 },
			flat = true,
			count = 1,
			life = { END, END },
			size = { { 0, 2 }, { 0.06, 9 }, { 1, 9.5 } },
			transparency = { { 0, 1 }, { 0.06, 0.3 }, { 0.85, 0.5 }, { 1, 1 } },
			rotation = { 0, 0 },
			rotSpeed = { 20, 20 },
			lightEmission = 0.2,
			brightness = 1,
		},
		{
			-- a column of light welling up behind the caster as he rises
			name = "column",
			texture = "glow_soft",
			color = GOLD,
			at = "ground",
			offset = { SIDE, 4, BEHIND },
			count = 1,
			life = { 1.2, 1.2 },
			size = { { 0, 3 }, { 0.3, 11 }, { 1, 12 } },
			transparency = { { 0, 1 }, { 0.3, 0.88 }, { 1, 1 } },
			lightEmission = 0.1,
			brightness = 1,
			zOffset = -2,
		},
		{
			-- motes of light rising round him the whole time
			name = "motes",
			texture = "spark_dot",
			color = GOLD,
			at = "ground",
			offset = { SIDE, 0.5, BEHIND - 0.5 },
			shape = "Disc",
			radius = 4,
			life = { 0.8, 1.4 },
			size = { { 0, 0.3 }, { 1, 0.05 } },
			speed = { 2, 4 },
			spread = { 10, 10 },
			direction = "Top",
			lightEmission = 1,
			brightness = 3,
			stream = { from = RISE, to = END - 0.3, rate = { 12, 12 } },
		},
		{
			-- the glint as he raises his shield
			name = "glint",
			texture = "star_flare_big",
			color = GOLD,
			at = "ground",
			offset = { SIDE - 2.7, 5.8, BEHIND - 0.5 },
			count = 1,
			delay = RAISE,
			life = { 0.45, 0.45 },
			size = { { 0, 2 }, { 0.3, 9 }, { 1, 5 } },
			transparency = { { 0, 0 }, { 0.6, 0.3 }, { 1, 1 } },
			rotation = { 0, 0 },
			lightEmission = 1,
			brightness = 1.8,
			zOffset = 2,
		},
		{
			-- feathers of light drifting down
			name = "feathers",
			texture = "feather",
			color = GOLD,
			at = "ground",
			offset = { SIDE, 8, BEHIND - 1 },
			box = { 1.6, 0.1, 0.6 },
			life = { 1.6, 2.2 },
			size = { { 0, 0 }, { 0.1, 0.6 }, { 1, 0.45 } },
			transparency = { { 0, 0 }, { 0.75, 0.1 }, { 1, 1 } },
			speed = { 0.5, 1.5 },
			spread = { 180, 180 },
			drift = "fall",
			rotation = { -180, 180 },
			rotSpeed = { -90, 90 },
			lightEmission = 0.6,
			brightness = 2,
			secondary = true,
			stream = { from = RAISE, to = END - 1, rate = { 5, 5 } },
		},
		{
			-- he fades up into motes of light
			name = "fade",
			texture = "spark_dot",
			color = GOLD,
			at = "ground",
			offset = { SIDE, 4.5, BEHIND },
			box = { 1.6, 1.8, 0.4 },
			count = 40,
			delay = END - 0.6,
			life = { 0.7, 1.1 },
			size = { { 0, 0.35 }, { 1, 0.05 } },
			speed = { 3, 6 },
			spread = { 25, 25 },
			direction = "Top",
			drag = 1,
			lightEmission = 1,
			brightness = 3,
			locked = false,
		},
	}
	if n >= 2 then
		table.insert(out, {
			-- a wall of holy runes standing before the caster, catching what comes
			name = "wall",
			texture = "floor_holy",
			color = GOLD,
			at = "waist",
			offset = { 0, 0.5, -2.5 },
			upright = true,
			locked = true,
			count = 1,
			delay = RAISE,
			life = { END - RAISE, END - RAISE },
			size = { { 0, 1 }, { 0.06, 7 }, { 1, 7 } },
			transparency = { { 0, 1 }, { 0.06, 0.45 }, { 0.85, 0.55 }, { 1, 1 } },
			rotation = { 0, 0 },
			rotSpeed = { 30, 30 },
			lightEmission = 1,
			brightness = 1.2,
		})
	end
	if n == 3 then
		table.insert(out, {
			-- the sword driven into the ground ahead: a holy blast (the owner's holy hit, as drawn) ...
			name = "smite",
			texture = "holyHit",
			role = "keep",
			at = "ground",
			offset = { 1.5, 1.5, -5 },
			count = 1,
			delay = SMITE,
			life = { 0.35, 0.35 },
			size = { { 0, 5 }, { 1, 9 } },
			transparency = { { 0, 0 }, { 0.5, 0.35 }, { 1, 1 } },
			rotation = { -10, 10 },
			lightEmission = 0.3,
			brightness = 1,
			zOffset = 2,
		})
		table.insert(out, {
			-- ... and a shockwave over the ground pushing the foes back
			name = "shock",
			texture = "ring_rays",
			color = GOLD,
			at = "ground",
			offset = { 1.5, 0.15, -5 },
			flat = true,
			count = 1,
			delay = SMITE,
			life = { 0.5, 0.5 },
			size = { { 0, 2 }, { 1, 16 } },
			transparency = { { 0, 0.1 }, { 0.6, 0.5 }, { 1, 1 } },
			lightEmission = 0.2,
			brightness = 1,
		})
	end
	return out
end

local function level(n)
	return {
		pieces = pieces(n),
		markers = {
			risen = RISE + OUT,
			guard = RAISE,
			smite = if n == 3 then SMITE else nil,
			fade = END,
			peak = RAISE + 0.15,
		},
	}
end

local LV3 = level(3)

return {
	id = "skill.spirit_guardian",
	name = "Spirit Guardian",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = {
		"summon",
		"summoning",
		"guardian",
		"knight",
		"spirit",
		"holy",
		"light",
		"gold",
		"protect",
		"shield",
		"skill",
	},
	blend = "normal+bloom",
	tintable = false,
	markers = LV3.markers,
	beams = { GUARDIAN },
	pieces = LV3.pieces,
	variants = { lv1 = level(1), lv2 = level(2), lv3 = {} },
	defaultVariant = "lv3",
	light = {
		color = { 255, 220, 140 },
		range = 16,
		keys = {
			{ 0, 0 },
			{ RAISE, 2 },
			{ SMITE - 0.05, 1.2 },
			{ SMITE, 2.5 },
			{ SMITE + 0.4, 1 },
			{ END, 0.8 },
			{ END + 0.3, 0 },
		},
	},
	source = {
		from = "the library (summoning skills, 2026-11-09)",
		art = "ChatGPT pictures drawn for the library (summon_guardian, floor_holy); the owner's holy hit; free Creator Store pack textures (no scripts: glow_soft, spark_dot, star_flare_big, feather, ring_rays)",
		licence = "ChatGPT output and the owner's art; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the caster's CFrame: the guardian stands over the caster from markers.risen (0.8 s); from markers.guard (0.9 s) to markers.fade (4 s) shield the caster (lv2 and lv3: block what comes from the front, the wall); lv3 knocks the foes ahead back at markers.smite (1.3 s). skill.summon_call is its wind-up.",
}
