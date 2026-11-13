-- Acid Melt: Goo Lineage's Acid Rain eating a dungeon monster's armour, for as long as the melt lasts (4 s, on up to
-- six monsters at once). It must read as "its armour is being eaten", not as a poison mist, from the dungeon camera
-- 25-45 studs away, on the white Frozen Ice snow and on lava alike: green-yellow acid runs down the lower body, glossy
-- and solid with a dark rim (drawn normal, never added), and on the skin clusters of acid bubbles swell and pop, a thin
-- wisp of acid smoke curling up from each. Not aura.bilebloat_bubbles (loose bubbles rising round a body) nor
-- aura.sporegorge_mist (a cloud) nor hit.acid_splat (the one splash of a hit): the acid stays on the body, eating.
-- Both pictures are drawn in code (tools/status_art.py) and worn as drawn. Any monster 2 to 11 studs tall: its numbers
-- follow refHeight, its places are shares of the monster's box.

-- (each run keeps one of the sheet's four, still)
local ONE_OF = { layout = "Grid2x2", mode = "Loop", fps = { 0, 0 }, random = true }

return {
	id = "buff.acid_melt",
	name = "Acid Melt",
	kind = "buff",
	tier = "cheap",
	host = "any",
	refHeight = 5,
	tags = { "buff", "debuff", "status", "acid", "melt", "armour", "corrode", "goo_lineage", "bright_map" },
	blend = "normal",
	palette = {},
	tintable = false,
	-- (its preview: once the runs and the fizz have built up)
	markers = { peak = 1.6 },
	pieces = {
		{
			-- (acid running down the lower body: born on the skin, sliding slowly down it as it is eaten)
			name = "runs",
			texture = "acid_runs",
			role = "keep",
			at = "waist",
			-- (a box inside the monster's own: the whole box's sides lie at the tips of a bear's held-out arms, in the air;
			-- drawn a stud toward the camera, so a run born just under the skin shows on it; Studio 2026-11-13)
			box = { 0.7, 0.5, 0.7 },
			shape = "Box",
			shapeStyle = "Surface",
			rate = 5,
			life = { 1.3, 1.7 },
			size = { { 0, 0.9 }, { 0.2, 1.5 }, { 0.8, 1.5 }, { 1, 1.2 } },
			transparency = { { 0, 1 }, { 0.12, 0 }, { 0.8, 0 }, { 1, 1 } },
			speed = { 0.05, 0.1 },
			accel = { 0, -0.7, 0 },
			rotation = { -8, 8 },
			orientation = "FacingCameraWorldUp",
			flipbook = ONE_OF,
			zOffset = 1,
			locked = true,
		},
		{
			-- (acid fizzing on the armour: bubbles swell and pop, a wisp of acid smoke curls up, once over each life)
			name = "fizz",
			texture = "acid_fizz",
			role = "keep",
			at = "waist",
			box = { 0.7, 0.6, 0.7 },
			shape = "Box",
			shapeStyle = "Surface",
			rate = 6,
			life = { 0.9, 1.2 },
			size = { { 0, 1.1 }, { 1, 1.25 } },
			transparency = { { 0, 0 }, { 0.85, 0 }, { 1, 1 } },
			speed = { 0.05, 0.15 },
			orientation = "FacingCameraWorldUp",
			flipbook = { layout = "Grid4x4", mode = "OneShot" },
			zOffset = 1.1,
			locked = true,
		},
	},
	source = {
		from = "the library, for Goo Lineage's status looks (Config.Zombies.View.Status.Looks, 2026-11-13)",
		art = "acid_runs, acid_fizz (drawn in code for the library: tools/status_art.py)",
		licence = "the owner's own",
	},
	notes = 'VfxLib.attach(monsterModel, "buff.acid_melt") as Acid Rain\'s armour melt starts on it; VfxLib.detach(handle) as it ends (4 s): the runs and the fizz end their lives. Cheap: two emitters, on up to six monsters at once.',
}
