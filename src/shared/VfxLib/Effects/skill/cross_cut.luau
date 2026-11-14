-- Cross Cut: two sword cuts that cross in an X (physical skills, 2026-11-09: "Thập Tự Trảm"). Steel, not magic: the
-- first cut falls from upper left to lower right through the target, the second answers from upper right a beat later,
-- each a smear of swept steel with a hard white edge and a pale wake of air; orange sparks fly off where the blade
-- bites. The two cuts leave thin white scars hanging in the air in an X; a moment later the X SPLITS: a white pop with
-- speed lines, the scars flare wide and vanish, steel chips and sparks burst out and a gust blows dust off the ground
-- past the target. Played at the ATTACKER's frame (VfxLib.play(id, root.CFrame): -z ahead): the X is 4.5 studs ahead.
-- Its level is the variant: lv1 the X, lv2 a third, level cut through it, lv3 (the default) a second, wider X behind.
local STEEL = { { 175, 195, 225 }, { 230, 238, 255 }, { 255, 255, 255 } }
local WAKE = { { 200, 215, 235 }, { 240, 245, 255 } }
local SCAR = { { 255, 255, 255 }, { 255, 255, 255 } }
local HOT = { { 0, { 255, 250, 220 } }, { 0.4, { 255, 200, 90 } }, { 1, { 255, 110, 30 } } }
local DUST = { { 0, { 210, 195, 170 } }, { 1, { 160, 145, 120 } } }
local WHITE = { { 0, { 255, 255, 255 } }, { 1, { 215, 230, 255 } } }
local AHEAD = -4.5
local SPLIT = 0.42

-- one cut: the swept steel (its picture's hot edge and lens shape painted in), a pale wake of air a little wider and
-- a thin white scar that hangs on until the split, then flares and goes
local function cut(name, from, to, bulge, at, wide, scarLife)
	return {
		{
			name = name,
			texture = "slash_steel",
			colors = STEEL,
			from = from,
			to = to,
			bulge = bulge,
			face = true,
			width = { wide, wide },
			delay = at,
			life = 0.3,
			transparency = { { 0, 0 }, { 0.35, 0 }, { 1, 1 } },
			grow = { { 0, 0.5 }, { 0.25, 1 }, { 1, 1.1 } },
			edge = { 0.55, 0 },
			segments = 20,
			glow = 2.2,
			zOffset = 1,
		},
		{
			name = name .. "_wake",
			texture = "streak_mist",
			colors = WAKE,
			from = from,
			to = to,
			bulge = bulge,
			face = true,
			width = { wide * 1.6, wide * 1.6 },
			delay = at + 0.02,
			life = 0.4,
			transparency = { { 0, 0.4 }, { 0.3, 0.45 }, { 1, 1 } },
			grow = { { 0, 0.6 }, { 1, 1.3 } },
			edge = { 0.6, 0.2 },
			segments = 20,
			glow = 1.1,
		},
		{
			name = name .. "_scar",
			texture = "streak_slash",
			colors = SCAR,
			from = from,
			to = to,
			bulge = bulge,
			face = true,
			width = { 0.35, 0.35 },
			delay = at + 0.04,
			life = scarLife,
			transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
			-- (thin while it hangs, then it flares wide as the X splits)
			grow = { { 0, 1 }, { 0.78, 1 }, { 0.88, 3 }, { 1, 4 } },
			segments = 20,
			glow = 2.6,
			zOffset = 2,
		},
	}
end

local function add(list, more)
	for _, beam in more do
		table.insert(list, beam)
	end
	return list
end

-- the X: upper left to lower right, then upper right to lower left, bowed up and a little round the target
local function cross(prefix, z, size, at, wide)
	local s = size
	return add(
		cut(
			prefix .. "a",
			{ -3 * s, 3.2 * s, z },
			{ 3 * s, -2 * s, z },
			{ 1.5 * s, 1.7 * s, -0.8 },
			at,
			wide,
			SPLIT - at
		),
		cut(
			prefix .. "b",
			{ 3 * s, 3.2 * s, z },
			{ -3 * s, -2 * s, z },
			{ -1.5 * s, 1.7 * s, -0.8 },
			at + 0.12,
			wide,
			SPLIT - at - 0.12
		)
	)
end

local LV1 = cross("x", AHEAD, 1, 0, 2.3)
-- (lv2: a third cut, level, right to left through the middle of the X)
local LEVEL = cut("level", { 3.6, 0.6, AHEAD }, { -3.6, 0.6, AHEAD }, { 0, -0.6, -1.6 }, 0.22, 2, SPLIT - 0.22)
local LV2 = add(cross("x", AHEAD, 1, 0, 2.3), LEVEL)
-- (lv3: and a second, wider X behind the target; the level cut without its wake: 16 beams at most)
local LV3 = add(cross("x", AHEAD, 1, 0, 2.3), cross("wide", AHEAD - 1.2, 1.35, 0.03, 2.8))
for _, beam in cut("level", { 3.6, 0.6, AHEAD }, { -3.6, 0.6, AHEAD }, { 0, -0.6, -1.6 }, 0.22, 2, SPLIT - 0.22) do
	if not string.find(beam.name, "_wake") then
		table.insert(LV3, beam)
	end
end

local function sparksAt(name, at, direction)
	return {
		name = name,
		texture = "spark_dot",
		color = HOT,
		offset = { 0, 0.6, AHEAD },
		orientation = "VelocityParallel",
		life = { 0.2, 0.4 },
		size = { { 0, 0.45 }, { 1, 0.1 } },
		transparency = { { 0, 0 }, { 1, 0.3 } },
		speed = { 16, 28 },
		spread = { 40, 40 },
		direction = direction,
		squash = { { 0, -0.8 }, { 1, -0.6 } },
		drag = 3,
		accel = { 0, -20, 0 },
		lightEmission = 1,
		brightness = 3,
		locked = false,
		bursts = { { at, 10 } },
	}
end

return {
	id = "skill.cross_cut",
	name = "Cross Cut",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "physical", "sword", "slash", "cross", "steel", "melee", "single", "skill", "white" },
	blend = "additive",
	tintable = false,
	markers = { contact = 0.08, second = 0.2, split = SPLIT, impact = SPLIT, peak = SPLIT + 0.03 },
	beams = LV3,
	pieces = {
		-- (where the blade bites: sparks thrown along each cut)
		sparksAt("bite1", 0.08, "Right"),
		sparksAt("bite2", 0.2, "Left"),
		{
			-- the split: a white pop with speed lines flying out ...
			name = "pop",
			texture = "impact_burst",
			color = WHITE,
			offset = { 0, 0.6, AHEAD },
			count = 1,
			delay = SPLIT,
			life = { 0.35, 0.35 },
			size = { { 0, 6 }, { 1, 9 } },
			speed = { 0.01, 0.01 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 2.2,
			zOffset = 3,
		},
		{
			-- ... a star across the crossing ...
			name = "star",
			texture = "star_flare",
			color = WHITE,
			offset = { 0, 0.6, AHEAD },
			count = 1,
			delay = SPLIT,
			life = { 0.22, 0.22 },
			size = { { 0, 2 }, { 0.3, 6 }, { 1, 0 } },
			transparency = { { 0, 0 }, { 1, 0.2 } },
			speed = { 0.01, 0.01 },
			rotation = { 45, 45 },
			lightEmission = 1,
			brightness = 2,
			zOffset = 3,
		},
		{
			-- ... a burst of hot sparks every way ...
			name = "burst",
			texture = "spark_dot",
			color = HOT,
			offset = { 0, 0.6, AHEAD },
			orientation = "VelocityParallel",
			count = 30,
			delay = SPLIT,
			life = { 0.3, 0.6 },
			size = { { 0, 0.55 }, { 1, 0.1 } },
			transparency = { { 0, 0 }, { 1, 0.3 } },
			speed = { 20, 34 },
			spread = { 180, 180 },
			squash = { { 0, -1 }, { 1, -0.6 } },
			drag = 3,
			accel = { 0, -24, 0 },
			lightEmission = 1,
			brightness = 3,
			locked = false,
		},
		{
			-- ... chips of steel flung off ...
			name = "chips",
			texture = "shards_flip",
			color = { { 0, { 245, 248, 255 } }, { 1, { 170, 185, 210 } } },
			offset = { 0, 0.6, AHEAD },
			count = 14,
			delay = SPLIT,
			life = { 0.4, 0.7 },
			size = { { 0, 0.8 }, { 1, 0.3 } },
			transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
			speed = { 12, 20 },
			spread = { 70, 70 },
			direction = "Front",
			accel = { 0, -30, 0 },
			drag = 2,
			rotation = { -180, 180 },
			rotSpeed = { -400, 400 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0.4,
			brightness = 1.5,
			locked = false,
		},
		{
			-- ... and a gust that blows the dust off the ground past the target
			name = "gust",
			texture = "dust_kick_flip",
			color = DUST,
			at = "ground",
			offset = { 0, 0.2, AHEAD },
			count = 8,
			delay = SPLIT,
			life = { 0.5, 0.8 },
			size = { { 0, 1.4 }, { 1, 3.2 } },
			transparency = { { 0, 0.3 }, { 1, 1 } },
			speed = { 8, 14 },
			spread = { 35, 15 },
			direction = "Front",
			drag = 3,
			rotation = { -30, 30 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 0,
			lightInfluence = 0,
			secondary = true,
		},
		{
			-- the air slammed out of the split: thin streaks blown on ahead
			name = "wind",
			texture = "streaks_flat",
			color = { { 0, { 245, 250, 255 } }, { 1, { 200, 215, 235 } } },
			offset = { 0, 0.6, AHEAD },
			orientation = "VelocityParallel",
			count = 10,
			delay = SPLIT,
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
	variants = {
		lv1 = { beams = LV1 },
		lv2 = { beams = LV2 },
		lv3 = {},
	},
	defaultVariant = "lv3",
	light = {
		color = { 235, 240, 255 },
		range = 14,
		keys = { { 0, 0 }, { 0.08, 2 }, { 0.25, 1.5 }, { SPLIT, 5 }, { SPLIT + 0.5, 0 } },
	},
	source = {
		from = "the library (physical skills, 2026-11-09)",
		art = "EffectCraft (slash_steel, impact_burst: textures/fx); free Creator Store pack textures (no scripts: streak_mist, streak_slash, spark_dot, star_flare, shards_flip, dust_kick_flip, streaks_flat)",
		licence = "rendered for the owner's library; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the attacker's root CFrame on the swing's first contact (markers: contact 0.08, second 0.2, the X splits at 0.42: shake and hit-stop there). Levels: lv1 the X, lv2 + a level cut, lv3 (default) + a wider X behind. skill.battle_focus is its wind-up.",
}
