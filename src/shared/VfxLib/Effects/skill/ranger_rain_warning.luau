-- Ranger Arrow Rain warning: before skill.arrow_volley, a wide ring of red-orange arrow marks fills in on the floor
-- over 1.2 s (seven marks lying point-in, one after the other, then a red ring joins them): "stay out of the circle".
-- Played on the spot (the middle of the area), radius 5 studs, the same circle skill.arrow_volley falls on. Coloured red
-- bodies with a dark edge, so it reads on snow.
local RED = { { 0, { 255, 190, 120 } }, { 1, { 225, 55, 30 } } }
local MARKS = 7
local RADIUS = 4.6

local function marks()
	local out: { any } = {}
	for i = 1, MARKS do
		local a = (i - 1) / MARKS * math.pi * 2
		table.insert(out, {
			name = "mark" .. i,
			texture = "arrow_steel",
			color = RED,
			at = "ground",
			flat = true,
			offset = { math.cos(a) * RADIUS, 0, math.sin(a) * RADIUS },
			count = 1,
			delay = (i - 1) * 0.12,
			life = { 1.2, 1.2 },
			size = { { 0, 0.8 }, { 0.1, 2.6 }, { 1, 2.6 } },
			transparency = { { 0, 0.8 }, { 0.1, 0.1 }, { 0.85, 0.15 }, { 1, 1 } },
			-- (the point toward the middle)
			rotation = { -math.deg(a) - 90, -math.deg(a) - 90 },
			lightEmission = 0.3,
			brightness = 1.4,
		})
	end
	return out
end

local pieces = marks()
table.insert(pieces, {
	name = "ring",
	texture = "ring_thorned",
	color = RED,
	at = "ground",
	flat = true,
	count = 1,
	delay = 0.5,
	life = { 0.7, 0.7 },
	size = { { 0, 6 }, { 0.4, 10.6 }, { 1, 11 } },
	transparency = { { 0, 0.8 }, { 0.3, 0.1 }, { 0.85, 0.15 }, { 1, 1 } },
	lightEmission = 0.3,
	brightness = 1.4,
})

return {
	id = "skill.ranger_rain_warning",
	name = "Ranger Arrow Rain Warning",
	kind = "skill",
	tier = "mid",
	host = "any",
	refHeight = 5,
	tags = { "ranger", "arrows", "warning", "telegraph", "ring", "red", "aoe", "skill" },
	blend = "normal+bloom",
	tintable = false,
	markers = { filled = 1.0, peak = 1, full = 1.2 },
	pieces = pieces,
	source = {
		from = "the library (fight effects wave 2, 2026-11-14)",
		art = "EffectCraft (arrow_steel); free Creator Store pack textures (no scripts: ring_thorned)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play on the spot (flat, radius 5 like skill.arrow_volley) 1.2 s before it: marks fill in one by one, all there by markers.filled (1 s). Sheds nothing, never hides the foes.",
}
