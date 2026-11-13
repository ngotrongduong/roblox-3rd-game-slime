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
-- The strands, sludge, fizz, roots and rime are ChatGPT clips (16 frames each, tools/chatgpt/clip_frames.py), each
-- played once over a particle's life; the honey drop is the game's own: all worn as drawn. At a 3-stud slime.

-- (a clip played once over each life)
local ONCE = { layout = "Grid4x4", mode = "OneShot" }
-- (the clods: each picture of a 2 x 2 sheet kept still, one a particle)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

-- (a picture standing in a ring round the slime's foot as wide as the slime, its own foot on the ground and `height`
-- studs tall: a particle covers about twice its Size (lesson 117), so Size and the lift of its middle are both half the
-- height. The clips fill their cell at their peak, so `height` is how high the look climbs. The game's slime body is
-- SOLID and the ones in front cover it: honey and frost stay low round the foot and the slime stays clear (in the game
-- 2026-11-13 strands 1.6 times its height caged it and a frost card hid it). The ring is a FLAT box a little wider
-- than the body (3.6 studs on the game's 3.17): a Disc is born on its part's top face (lesson 212), so the old
-- `radius = 1.5` (a cube 3 studs tall) put the ring round the slime's head, and on the solid body only what stood
-- over the head or past its sides was seen; at five a second the near side was bare)
local RING = { 1.14, 0.01, 1.14 }
local function clinging(name, texture, height, rate, life, flipbook)
	local size = height / 2
	return {
		name = name,
		texture = texture,
		role = "keep",
		at = "ground",
		box = RING,
		shape = "Disc",
		shapeStyle = "Surface",
		lift = size,
		rate = rate,
		life = life,
		size = { { 0, size }, { 1, size * 1.05 } },
		transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
		speed = { 0, 0 },
		orientation = "FacingCameraWorldUp",
		flipbook = flipbook,
		-- (a pull toward the camera that keeps the near ones over the body's curve; the ones behind stay behind it)
		zOffset = 0.35,
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
		-- (strands from the slime's underside to a puddle, under half its height: the slime itself stays in sight)
		clinging("strands", "honey_flip", 1.4, 8, { 1.3, 1.6 }, ONCE),
		{
			-- (honey dripping off the slime's lower body: born on its skin, a box a share wider than the body, since the
			-- body is solid and a drop inside it is never seen)
			name = "drips",
			texture = "honey_drop",
			role = "keep",
			at = "waist",
			box = { 1.05, 0.15, 1.05 },
			shape = "Box",
			shapeStyle = "Surface",
			rate = 4,
			life = { 0.5, 0.7 },
			-- (drops about half a stud across: a particle covers twice its Size)
			size = { { 0, 0.15 }, { 0.2, 0.28 }, { 1, 0.24 } },
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
				-- (sludge round the foot: a splat heaves up into a clinging heap, pops, slumps back; half the slime)
				clinging("sludge", "sludge_flip", 1.5, 7, { 1.3, 1.6 }, ONCE),
				-- (bubbles fizzing and popping on the sludge, wisps of acid smoke)
				clinging("fizz", "acid_fizz_flip", 1.3, 4, { 1, 1.2 }, ONCE),
			},
		},
		roots = {
			pieces = {
				-- (the clip once over each life: break out, coil, leaf, sink back)
				clinging("roots", "roots_flip", 2.2, 6, { 1.4, 1.7 }, ONCE),
				{
					-- (clods of earth kicked up where the roots break out)
					name = "clods",
					texture = "rocks",
					role = "keep",
					at = "ground",
					box = RING,
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
				-- (a crust of small crystal mounds all round the foot, a third of the slime's height: many small ones hug
				-- the round body, one big one is a card)
				clinging("rime", "rime_flip", 1.1, 12, { 1.2, 1.5 }, ONCE),
				{
					-- (a frosty mist rising off the ground round the foot)
					name = "mist",
					texture = "smoke_frost",
					role = "keep",
					at = "ground",
					box = { 1.2, 0.01, 1.2 },
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
		art = "honey_flip, sludge_flip, acid_fizz_flip, roots_flip, rime_flip (ChatGPT clips drawn for the library: tools/chatgpt/clip_frames.py); the owner's honey drop (honey_drop: Goo Lineage's own, kept as drawn); free Creator Store pack textures (no scripts: rocks, smoke_frost)",
		licence = "the owner's own art; Creator Store free assets (no scripts kept)",
	},
	notes = 'VfxLib.attach(slimeModel, "buff.slowed", { variant = "sting" | "acid" | "roots" | "frost" }) as the slow starts; VfxLib.detach(handle) as it ends (1.5 to 3 s). Cheap: two emitters a variant, on up to four slimes at once.',
}
