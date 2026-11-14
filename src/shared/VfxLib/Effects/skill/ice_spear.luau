-- Ice Spear: a ranged ice skill (skills wave 2, the owner's "Băng Thương"). The spear of ice (ChatGPT, a glowing
-- spear drawn tip up) is thrown from the caster's hand STRAIGHT and very fast at the target (0.35 s), frost mist and
-- glittering crystals streaming off it and a pale ribbon behind. On the hit: a white flash, the frost circle (ChatGPT)
-- spreading on the ground, a ring of rays, ice shattering out; a RING OF ICE SPIKES (ChatGPT, on Beams) breaks out of
-- the ground round the target, leaning out, chips of ice thrown up where each breaks the ground, a smaller ring
-- further out after it; frost rolls over the ground and glittering snow dust falls a while. One tone: ice blue with
-- white. Its wind-up is skill.frost_charge on the caster.
local ICE = { { 0, { 240, 252, 255 } }, { 1, { 120, 200, 255 } } }
local FLIGHT = 0.35
-- (the ground in the play's frame: refHeight 5, the box's middle at 0)
local GROUND = -2.5

-- the ring of ice spikes: `count` spikes `radius` studs round the target, each from under the ground out and up to
-- `height`, leaning out; one after another round the ring
local function spikes(prefix, count, radius, height, width, delay, turn)
	local out: { any } = {}
	for i = 1, count do
		local angle = math.rad(turn + (i - 1) * 360 / count)
		local x, z = math.cos(angle), math.sin(angle)
		-- (every other spike a little taller: a ragged crown, not a fence)
		local h = height * (if i % 2 == 0 then 0.8 else 1)
		table.insert(out, {
			name = prefix .. i,
			texture = "ice_spike",
			-- (added pictures stacked round a ring wash out to white: kept a little blue and dim so each jag reads)
			colors = { { 190, 230, 255 }, { 225, 245, 255 } },
			-- (from its base under the ground to its tip: the picture is stored that way)
			from = { x * radius, GROUND - 0.4, z * radius },
			to = { x * (radius + h * 0.35), GROUND + h, z * (radius + h * 0.35) },
			width = { width, width },
			delay = delay + (i - 1) * 0.02,
			life = 1.5,
			transparency = { { 0, 0 }, { 0.7, 0 }, { 1, 1 } },
			grow = { { 0, 1 }, { 0.7, 1 }, { 1, 0.6 } },
			face = true,
			glow = 1.6,
			zOffset = 1,
			emerge = 0.12,
			rise = "chips",
		})
	end
	return out
end

local beams = spikes("spike", 8, 2.2, 6.5, 3.2, 0, 0)
for _, beam in spikes("outer", 6, 3.8, 3.8, 2.3, 0.12, 30) do
	table.insert(beams, beam)
end

return {
	id = "skill.ice_spear",
	name = "Ice Spear",
	kind = "skill",
	tier = "heavy",
	host = "character",
	refHeight = 5,
	tags = { "ice", "frost", "spear", "projectile", "ranged", "spikes", "skill", "blue", "white" },
	blend = "additive",
	tintable = false,
	markers = { impact = FLIGHT, peak = FLIGHT + 0.3 },
	projectile = {
		-- (VelocityParallel lays the picture's WIDTH along the flight: a spear drawn tip up is turned a quarter so the
		-- tip leads, as the firebird, lesson 112)
		texture = "ice_spear",
		rotation = { -90, -90 },
		color = { { 255, 255, 255 } },
		size = { { 0, 4 }, { 1, 4.6 } },
		transparency = { { 0, 0 }, { 1, 0 } },
		lightEmission = 1,
		brightness = 1.6,
		zOffset = 2,
		seconds = FLIGHT,
		arc = 0,
		riders = {
			{
				-- frost mist left hanging along the throw
				name = "frost",
				texture = "smoke_frost",
				color = { { 255, 255, 255 } },
				life = { 0.4, 0.7 },
				size = { { 0, 0.8 }, { 1, 2.2 } },
				transparency = { { 0, 0.45 }, { 1, 1 } },
				speed = { 0.5, 1.5 },
				spread = { 180, 180 },
				drag = 2,
				rotation = { -180, 180 },
				rotSpeed = { -60, 60 },
				lightEmission = 0.3,
				brightness = 1.5,
				stream = { from = 0, to = FLIGHT, rate = { 70, 70 } },
			},
			{
				-- glittering crystals shed behind it
				name = "glitter",
				texture = "snow_crystals_flip",
				color = { { 255, 255, 255 } },
				life = { 0.5, 0.9 },
				size = { { 0, 0.4 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0.3 } },
				speed = { 1, 3 },
				spread = { 180, 180 },
				drag = 2,
				accel = { 0, -2, 0 },
				rotation = { -180, 180 },
				flipbook = { layout = "Grid4x4", mode = "OneShot", fps = { 1, 1 } },
				lightEmission = 1,
				brightness = 2.5,
				secondary = true,
				stream = { from = 0, to = FLIGHT, rate = { 60, 60 } },
			},
		},
		-- (a pale ribbon behind it: the frost trail)
		trail = {
			texture = "streak_mist",
			colors = { { 225, 248, 255 }, { 110, 190, 255 } },
			width = 1.6,
			life = 0.3,
			glow = 2,
		},
	},
	pieces = {
		{
			-- the hit: a white flash ...
			name = "flash",
			texture = "burst_star_c",
			color = ICE,
			at = "body",
			count = 1,
			life = { 0.2, 0.2 },
			size = { { 0, 3 }, { 1, 7 } },
			transparency = { { 0, 0 }, { 0.5, 0.3 }, { 1, 1 } },
			rotation = { -180, 180 },
			lightEmission = 1,
			brightness = 1.5,
			zOffset = 2,
		},
		{
			-- ... the frost circle spreading on the ground round the target
			name = "floor",
			texture = "floor_icelance",
			color = { { 255, 255, 255 } },
			at = "ground",
			flat = true,
			count = 1,
			life = { 1.7, 1.7 },
			size = { { 0, 2 }, { 0.1, 10 }, { 1, 11 } },
			-- (under the spikes, never brighter than them)
			transparency = { { 0, 0.45 }, { 0.7, 0.6 }, { 1, 1 } },
			rotation = { -180, 180 },
			rotSpeed = { 15, 15 },
			lightEmission = 1,
			brightness = 1,
		},
		{
			-- ... a ring of rays racing out over it
			name = "ring",
			texture = "ring_rays",
			color = ICE,
			at = "ground",
			flat = true,
			count = 1,
			life = { 0.45, 0.45 },
			size = { { 0, 3 }, { 1, 16 } },
			transparency = { { 0, 0.05 }, { 0.6, 0.5 }, { 1, 1 } },
			lightEmission = 1,
			brightness = 2,
		},
		{
			-- the spear shatters: shards of ice thrown out
			name = "shatter",
			texture = "ice_shards_flip",
			color = ICE,
			at = "body",
			orientation = "VelocityParallel",
			count = 24,
			life = { 0.4, 0.7 },
			size = { { 0, 0.9 }, { 1, 0.3 } },
			transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
			speed = { 14, 24 },
			spread = { 180, 180 },
			drag = 3,
			accel = { 0, -12, 0 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 2.5,
		},
		{
			-- where each spike breaks the ground: chips of ice thrown up
			name = "chips",
			texture = "ice_shards_flip",
			color = ICE,
			onLand = true,
			count = 4,
			orientation = "VelocityParallel",
			life = { 0.35, 0.55 },
			size = { { 0, 0.6 }, { 1, 0.2 } },
			transparency = { { 0, 0 }, { 1, 0.3 } },
			speed = { 6, 12 },
			spread = { 40, 40 },
			direction = "Top",
			drag = 2,
			accel = { 0, -24, 0 },
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			lightEmission = 1,
			brightness = 2.5,
		},
		{
			-- frost rolling out over the ground
			name = "mist",
			texture = "smoke_frost",
			color = { { 255, 255, 255 } },
			at = "feet",
			box = { 1.2, 0, 1.2 },
			count = 10,
			delay = 0.05,
			life = { 0.9, 1.4 },
			size = { { 0, 2 }, { 1, 4.5 } },
			-- (thin and low: thick, it hid the spikes in a white haze)
			transparency = { { 0, 0.7 }, { 1, 1 } },
			speed = { 5, 9 },
			spread = { 10, 360 },
			direction = "Front",
			drag = 3,
			rotation = { -180, 180 },
			rotSpeed = { -30, 30 },
			lightEmission = 0.1,
			brightness = 1,
		},
		{
			-- glittering snow dust falling a while over it all
			name = "snow",
			texture = "snow_crystals_flip",
			color = { { 255, 255, 255 } },
			at = "above",
			box = { 2.6, 0, 2.6 },
			count = 40,
			delay = 0.1,
			life = { 1.4, 2.2 },
			size = { { 0, 0 }, { 0.15, 0.4 }, { 1, 0.15 } },
			transparency = { { 0, 0 }, { 0.8, 0.1 }, { 1, 1 } },
			speed = { 0.2, 0.8 },
			spread = { 60, 60 },
			direction = "Top",
			drift = "fall",
			drag = 1.5,
			rotation = { -180, 180 },
			rotSpeed = { -90, 90 },
			flipbook = { layout = "Grid4x4", mode = "OneShot", fps = { 1, 1 } },
			lightEmission = 1,
			brightness = 2.5,
			secondary = true,
		},
	},
	beams = beams,
	light = { color = { 170, 220, 255 }, range = 20, keys = { { 0, 0 }, { 0.03, 6 }, { 0.6, 2 }, { 1.6, 0 } } },
	source = {
		from = "the library (skills wave 2, 2026-11-08)",
		art = "ChatGPT pictures drawn for the library (ice_spear, ice_spike, floor_icelance); free Creator Store pack textures (no scripts: smoke_frost, snow_crystals_flip, ice_shards_flip, burst_star_c, ring_rays, streak_mist)",
		licence = "ChatGPT output owned by the owner; Creator Store free assets (no scripts kept)",
	},
	notes = "Play at the target with opts.from = the caster's hand: the spear flies straight there (0.35 s, markers.impact) and the ring of ice spikes breaks out round the target (a game may root the target in place while they stand, about 1.3 s). skill.frost_charge on the caster is its wind-up.",
}
