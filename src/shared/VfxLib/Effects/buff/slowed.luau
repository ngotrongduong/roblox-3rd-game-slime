-- Slowed: a slime held back by a monster's blow, for as long as the slow lasts (1.5 to 3 s, on up to four slimes at
-- once). Something clings to its foot and drags at it, one design for each thing that slows it, read from the
-- dungeon camera 25-45 studs away on the white Frozen Ice snow and on lava alike: every picture solid, full colour
-- with a dark rim of its own (drawn normal, never added), born in a ring round the slime's foot and standing on the
-- ground, turned to the camera:
--   sting  sticky honey (the meadow's Honey-Bee hunter's plain blows): strands from the slime's underside to a
--          puddle stretch thin and snap, again and again; honey drops dripping off its body
--   acid   acid sludge (the Grove's Acid Splash): heaps of green sludge stuck round its foot, bubbles swelling and
--          popping on them, wisps of acid smoke
--   roots  roots (the Grove's Root Grasp): roots break out of the ground and coil up round it, two leaves opening on
--          each; clods of earth kicked up
--   frost  rime (the Ice map's Icicle Bite, Crystal Burst, Frost Breath, Frost Gale): a crust of ice creeping up its
--          foot, shards growing out of it; a frosty mist at the ground
-- The strands, sludge, fizz, roots and rime are drawn in code (tools/status_art.py), the honey drop is the game's own:
-- all worn as drawn. At a 3-stud slime.

-- (each picture of a 2 x 2 sheet kept still, one a particle; a 4 x 4 played once over each life)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }
local ONCE = { layout = "Grid4x4", mode = "OneShot" }

-- (a picture standing in a ring round the slime's foot as wide as the slime, its own foot on the ground: `lift` is the
-- picture's middle over the ground; about as tall as the slime's lower two thirds, so it reads from the dungeon camera:
-- seen in Studio 2026-11-13, at 1.4 studs on a ring inside the slime's own width it hid in its body; at five a second
-- the side facing the camera was often bare)
local function clinging(name, texture, size, lift, rate, life, flipbook)
	return {
		name = name,
		texture = texture,
		role = "keep",
		at = "ground",
		radius = 1.5,
		shape = "Disc",
		shapeStyle = "Surface",
		lift = lift,
		rate = rate,
		life = life,
		size = { { 0, size }, { 1, size * 1.05 } },
		transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
		speed = { 0, 0 },
		orientation = "FacingCameraWorldUp",
		flipbook = flipbook,
		-- (small: the ones behind the slime stay behind it)
		zOffset = 0.15,
		locked = true,
	}
end

return {
	id = "buff.slowed",
	name = "Slowed",
	kind = "buff",
	tier = "cheap",
	host = "slime",
	refHeight = 3,
	tags = { "buff", "debuff", "status", "slow", "honey", "acid", "roots", "frost", "goo_lineage", "bright_map" },
	blend = "normal",
	palette = {},
	tintable = false,
	defaultVariant = "sting",
	-- (its preview: once what clings to the foot has built up)
	markers = { peak = 1.4 },
	pieces = {
		-- (no taller than the slime's lower two thirds: the ones behind it are drawn over a see-through slime, their tops
		-- would stand over it as a roof)
		clinging("strands", "honey_strands", 2.1, 0.9, 8, { 0.9, 1.1 }, ONCE),
		{
			-- (honey dripping off the slime's lower body)
			name = "drips",
			texture = "honey_drop",
			role = "keep",
			at = "waist",
			box = { 0.8, 0.3, 0.8 },
			shape = "Box",
			shapeStyle = "Surface",
			rate = 4,
			life = { 0.5, 0.7 },
			size = { { 0, 0.3 }, { 0.2, 0.6 }, { 1, 0.5 } },
			transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
			speed = { 0, 0.2 },
			accel = { 0, -10, 0 },
			orientation = "FacingCameraWorldUp",
			zOffset = 0.3,
			locked = false,
		},
	},
	variants = {
		sting = {},
		acid = {
			pieces = {
				-- (heaps of sludge stuck round the foot: the heap is the lower half of each picture)
				clinging("sludge", "acid_sludge", 2.2, 0.9, 6, { 1.3, 1.7 }, ONE_OF),
				-- (bubbles fizzing and popping on the sludge, wisps of acid smoke)
				clinging("fizz", "acid_fizz", 1.5, 1.2, 5, { 0.9, 1.1 }, ONCE),
			},
		},
		roots = {
			pieces = {
				-- (living long past their growing, so most stand grown)
				clinging("roots", "roots_coil", 2.4, 1.1, 7, { 1.3, 1.6 }, ONCE),
				{
					-- (clods of earth kicked up where the roots break out)
					name = "clods",
					texture = "rocks",
					role = "keep",
					at = "ground",
					radius = 1.5,
					shape = "Disc",
					shapeStyle = "Surface",
					rate = 5,
					life = { 0.45, 0.6 },
					size = { { 0, 0.42 }, { 1, 0.34 } },
					transparency = { { 0, 0 }, { 0.8, 0 }, { 1, 1 } },
					speed = { 2, 3.5 },
					direction = "Top",
					spread = { 25, 25 },
					accel = { 0, -14, 0 },
					rotation = { 0, 360 },
					rotSpeed = { -200, 200 },
					flipbook = ONE_OF,
					locked = false,
				},
			},
		},
		frost = {
			pieces = {
				clinging("rime", "rime_creep", 2.4, 1.1, 7, { 1.1, 1.4 }, ONCE),
				{
					-- (a frosty mist rising off the ground round the foot)
					name = "mist",
					texture = "smoke_frost",
					role = "keep",
					at = "ground",
					radius = 1.6,
					shape = "Disc",
					shapeStyle = "Surface",
					lift = 0.3,
					rate = 3,
					life = { 1, 1.4 },
					size = { { 0, 0.6 }, { 1, 1.3 } },
					transparency = { { 0, 0.6 }, { 0.3, 0.35 }, { 1, 1 } },
					speed = { 0.2, 0.5 },
					direction = "Top",
					rotation = { 0, 360 },
					rotSpeed = { -20, 20 },
					locked = false,
				},
			},
		},
	},
	source = {
		from = "the library, for Goo Lineage's status looks (Config.Zombies.View.Status.Looks, 2026-11-13)",
		art = "honey_strands, acid_sludge, acid_fizz, roots_coil, rime_creep (drawn in code for the library: tools/status_art.py); the owner's honey drop (honey_drop: Goo Lineage's own, kept as drawn); free Creator Store pack textures (no scripts: rocks, smoke_frost)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = 'VfxLib.attach(slimeModel, "buff.slowed", { variant = "sting" | "acid" | "roots" | "frost" }) as the slow starts; VfxLib.detach(handle) as it ends (1.5 to 3 s). Cheap: two emitters a variant, on up to four slimes at once.',
}
