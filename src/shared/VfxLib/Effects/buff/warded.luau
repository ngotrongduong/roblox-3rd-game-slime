-- Warded: the look a slime wears while a Healer's Ward barrier is on it (Goo Lineage: Ward 5 s, Overflow 4 s). The
-- same family as `skill.healer_ward` (which closes the bubble and pops it), but held: a soft see-through bubble round
-- the body that breathes slowly (its own thin rim, tinted a deeper green so the edge holds on white snow), and the
-- owner's petals drifting on its skin. The bubble stays pale so the body and its face stay in sight; no shields (those
-- are `buff.stat_set` defence). Calm: nothing flashes. Two emitters, at a 3-stud slime.
local GREEN = { { 0, { 90, 200, 120 } }, { 1, { 40, 150, 90 } } }

return {
	id = "buff.warded",
	name = "Warded",
	kind = "buff",
	tier = "cheap",
	host = "slime",
	refHeight = 3,
	tags = { "buff", "healer", "ward", "bubble", "petals", "green", "status", "goo_lineage", "bright_map" },
	blend = "normal+bloom",
	palette = {},
	tintable = false,
	-- (its preview: once the bubble has faded in)
	markers = { peak = 1.2 },
	pieces = {
		{
			-- the bubble: one big see-through skin, breathing, each born as the last fades (a slow cross-fade)
			name = "bubble",
			texture = "bubble_gloss",
			color = GREEN,
			at = "body",
			locked = true,
			rate = 1,
			life = { 3, 3 },
			size = { { 0, 3.5 }, { 0.5, 3.9 }, { 1, 3.5 } },
			transparency = { { 0, 1 }, { 0.25, 0.65 }, { 0.75, 0.65 }, { 1, 1 } },
			lightEmission = 0.1,
			brightness = 1,
		},
		{
			-- the owner's petals drifting on the skin of the bubble, held to it
			name = "petals",
			texture = "petals_small_flip",
			color = { { 255, 255, 255 } },
			role = "keep",
			at = "body",
			radius = 1.7,
			shape = "Sphere",
			shapeStyle = "Surface",
			shapeInOut = "Outward",
			rate = 1.6,
			life = { 1.6, 2.2 },
			size = { { 0, 0.5 }, { 0.5, 0.65 }, { 1, 0.5 } },
			transparency = { { 0, 1 }, { 0.25, 0.1 }, { 0.75, 0.1 }, { 1, 1 } },
			speed = { 0.2, 0.5 },
			rotation = { -180, 180 },
			rotSpeed = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "Loop", fps = { 0, 0 }, random = true },
			lightEmission = 0,
			locked = true,
		},
	},
	source = {
		from = "the library, for Goo Lineage's Healer Ward and Overflow (2026-11-14)",
		art = "the owner's art (petals_small_flip, kept); a free Creator Store pack texture (no scripts: bubble_gloss)",
		licence = "owner's art; Creator Store free assets (no scripts kept)",
	},
	notes = 'VfxLib.attach(slimeBody, "buff.warded", { weld = true }) right after play("skill.healer_ward", ...) (that one-shot closes its bubble at 0.25 s and pops at 1.1 s: attach this at the pop so it takes over, or at once and let it fade in); VfxLib.detach(handle) when the barrier ends or is used up (a 0.3 s fade). Cheap: two emitters, safe on several slimes at once.',
}
