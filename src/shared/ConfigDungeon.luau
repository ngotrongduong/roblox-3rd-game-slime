--!strict
-- Config.Dungeon, in a file of its own: Studio refuses a script of 200000 characters or more, so Config's
-- biggest blocks live apart. Config.luau requires this file; the game reads it as Config.Dungeon.

return {
	-- The maps (Sunny Meadow, Mushroom Grove; the order they turn in is MapOrder below). A monster: its budget `cost` (none for a mini-boss or boss,
	-- which come alone), its level-1 stats (the same kind of numbers a slime has), its `role`, and `kind`: the way it
	-- fights in Config.Combat (melee strikes anyone; ranged keeps its distance; hunter goes for the slime with the least
	-- health and stings it slow; healer mends its wounded team-mates; bloomshell and bramblehorn are the two bosses with a
	-- skill of their own). `drops` (docs/SMITHY.md §2): a list of lines { item, chance, min, max }, each rolled on its own
	-- when the monster falls (see "Loot" below); an item is a key of Materials.
	Maps = {
		meadow = {
			name = "Sunny Meadow",
			monsters = {
				{
					id = "green_sprout",
					name = "Twigling",
					role = "swarmer",
					cost = 1,
					attack = 1,
					defence = 0,
					speed = 3,
					hp = 13,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 4 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.35, min = 1, max = 1 },
					},
				},
				{
					id = "green_bee",
					name = "Parrot",
					role = "raider",
					cost = 2,
					attack = 3,
					defence = 0,
					speed = 5,
					hp = 18,
					kind = "hunter",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "wood", chance = 0.15, min = 1, max = 1 },
						{ item = "ore", chance = 0.10, min = 1, max = 1 },
					},
				},
				{
					id = "green_dandelion",
					name = "Bloom Sprite",
					role = "spitter",
					cost = 2,
					attack = 3,
					defence = 0,
					speed = 2,
					hp = 16,
					kind = "ranged",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.30, min = 1, max = 1 },
					},
				},
				{
					id = "green_moth",
					name = "Aurora Owl",
					role = "shaman",
					cost = 2,
					attack = 1,
					defence = 0,
					speed = 2.5,
					hp = 20,
					kind = "healer",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.15, min = 1, max = 1 },
						{ item = "rare_part", chance = 0.05, min = 1, max = 1 },
					},
				},
				{
					id = "green_snail",
					name = "Hedgehog",
					role = "armoured",
					cost = 3,
					attack = 3,
					defence = 8,
					speed = 0.7,
					hp = 38,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.30, min = 3, max = 6 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.45, min = 1, max = 2 },
						{ item = "rare_part", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "green_turtle",
					name = "Mossback Gorilla",
					role = "miniboss",
					attack = 5,
					defence = 7,
					speed = 1.5,
					hp = 140,
					kind = "bloomshell",
					drops = {
						{ item = "coins", chance = 1, min = 6, max = 11 },
						{ item = "ore", chance = 1, min = 2, max = 3 },
						{ item = "rare_part", chance = 0.60, min = 1, max = 2 },
						{ item = "monster_core", chance = 0.30, min = 1, max = 1 },
						{ item = "boar_tusk", chance = 0.20, min = 1, max = 1 },
					},
				},
				{
					id = "green_boar",
					name = "Bramblehorn",
					role = "boss",
					attack = 7,
					defence = 4,
					speed = 2,
					hp = 280,
					kind = "bramblehorn",
					drops = {
						{ item = "coins", chance = 1, min = 12, max = 20 },
						{ item = "ore", chance = 1, min = 3, max = 5 },
						{ item = "rare_part", chance = 1, min = 2, max = 3 },
						{ item = "monster_core", chance = 0.50, min = 1, max = 1 },
						{ item = "boss_essence", chance = 0.25, min = 1, max = 1 },
						-- the map's trophy: two horns, never fewer
						{ item = "boar_tusk", chance = 1, min = 2, max = 2 },
					},
				},
			} :: { any },
		},
		-- The Mushroom Grove: the Meadow's roles again with the owner's other Egg Heist creatures and the dark forest's own
		-- stats where the original has a fitting one (docs/DUNGEON_MAPS.md §2). The trophy is the Glow Spore (the original's
		-- darkforest map drop): the boss pays two, never fewer; the mini-boss, the spitter and the healer sometimes one.
		mushroom = {
			name = "Mushroom Grove",
			monsters = {
				{
					id = "dark_hare",
					name = "Jackalope",
					role = "swarmer",
					cost = 1,
					attack = 1,
					defence = 0,
					speed = 3,
					hp = 14,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 4 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.35, min = 1, max = 1 },
					},
				},
				{
					id = "dark_bat",
					name = "Cave Bat",
					role = "raider",
					cost = 2,
					attack = 3,
					defence = 0,
					speed = 4.5,
					hp = 16,
					kind = "hunter",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "wood", chance = 0.15, min = 1, max = 1 },
						{ item = "ore", chance = 0.10, min = 1, max = 1 },
					},
				},
				{
					id = "dark_fox",
					name = "Fairy Fox",
					role = "spitter",
					cost = 2,
					attack = 2,
					defence = 0,
					speed = 2.2,
					hp = 16,
					kind = "ranged",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.30, min = 1, max = 1 },
						{ item = "glow_spore", chance = 0.10, min = 1, max = 1 },
					},
				},
				{
					id = "dark_deer",
					name = "Forest Deer",
					role = "shaman",
					cost = 2,
					attack = 1,
					defence = 0,
					speed = 2.5,
					hp = 20,
					kind = "healer",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.15, min = 1, max = 1 },
						{ item = "rare_part", chance = 0.05, min = 1, max = 1 },
						{ item = "glow_spore", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "dark_totem",
					name = "Totem Golem",
					role = "armoured",
					cost = 3,
					attack = 3,
					defence = 8,
					speed = 1,
					hp = 38,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.30, min = 3, max = 6 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.45, min = 1, max = 2 },
						{ item = "rare_part", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "dark_wyrm",
					name = "Jungle Wyrm",
					role = "miniboss",
					attack = 6,
					defence = 3,
					speed = 3,
					hp = 150,
					kind = "sporeburst",
					drops = {
						{ item = "coins", chance = 1, min = 6, max = 11 },
						{ item = "ore", chance = 1, min = 2, max = 3 },
						{ item = "rare_part", chance = 0.60, min = 1, max = 2 },
						{ item = "monster_core", chance = 0.30, min = 1, max = 1 },
						{ item = "glow_spore", chance = 0.35, min = 1, max = 2 },
					},
				},
				{
					id = "dark_bear",
					name = "Mama Bear",
					role = "boss",
					attack = 7,
					defence = 5,
					speed = 1.5,
					hp = 300,
					kind = "bearslam",
					drops = {
						{ item = "coins", chance = 1, min = 12, max = 20 },
						{ item = "ore", chance = 1, min = 3, max = 5 },
						{ item = "rare_part", chance = 1, min = 2, max = 3 },
						{ item = "monster_core", chance = 0.50, min = 1, max = 1 },
						{ item = "boss_essence", chance = 0.25, min = 1, max = 1 },
						-- the map's trophy: two glow spores, never fewer
						{ item = "glow_spore", chance = 1, min = 2, max = 2 },
					},
				},
			} :: { any },
		},
	},
	-- The maps turn one step each dungeon level (shared/Dungeon.mapForLevel), from a first map each player's UserId picks
	-- (MapFirstRandom, the original's seeded first map; off, everyone starts on the first of the list). MapSeedOffset is the
	-- original's seed + 77. Lava and Ice join the list when they are built.
	MapOrder = { "meadow", "mushroom" },
	MapFirstRandom = true,
	MapSeedOffset = 77,
	-- How long the lighting takes to come back to the place's own day when a run ends (client/DungeonLight).
	LightBackSeconds = 1.5,

	-- ===== Waves (§5) =====
	-- A run is Waves waves: the mini-boss alone on MiniBossWave, the boss alone on BossWave, the others a crowd whose
	-- cost is the budget (round((Base + PerWave x (wave - 1)) x (LateFactor from LateFrom on)), at most Max).
	Waves = 10,
	MiniBossWave = 5,
	BossWave = 10,
	BudgetBase = 6,
	BudgetPerWave = 3,
	BudgetLateFrom = 6,
	BudgetLateFactor = 1.3,
	BudgetMax = 40,
	-- A wave's crowd is drawn with the run's seed + wave x WaveSeedStep.
	WaveSeedStep = 7919,
	-- The queue lets one monster in every SpawnSeconds while fewer than MaxAlive stand; between two waves the arena rests
	-- PauseSeconds, and a wave is announced CountdownSeconds before its first monster.
	SpawnSeconds = 0.8,
	MaxAlive = 8,
	PauseSeconds = 2.5,
	CountdownSeconds = 1,

	-- ===== Difficulty (the owner tunes these by playing) =====
	-- HP and ATK of a monster times WaveGrowth^(wave - 1) inside a run, and times LevelPower^(level - 1) for the dungeon
	-- level. Defence and speed are never scaled. A monster's shown level is Stats.level of its scaled stats, so it rises
	-- every wave. LuckPerLevel: loot luck = 1 + LuckPerLevel x (level - 1). StatScale: HP and ATK of every monster times
	-- this (the original's numbers beat a team of four starters in wave 1; tools/balance/dungeon_sim.luau).
	-- Measured (20 seeds, a team of four): at 0.3 starters reach wave 3, level-10 slimes the boss's door, level 40 clear
	-- level 1. LevelPower 1.6 (the original's 5 left even level-80 slimes short of clearing level 2).
	StatScale = 0.3,
	WaveGrowth = 1.12,
	LevelPower = 1.6,
	LuckPerLevel = 0.05,
	-- The first dungeon level, and the best one that must be cleared before the next opens.
	FirstLevel = 1,
	-- The Dungeon is not for new players (the owner, 2026-11-04): a farm enters only with at least EnterMinSlimes slimes
	-- (eggs not counted) and a village of level EnterMinVillageLevel or more (15: the first level whose population limit
	-- holds 20 slimes, Config.Village.PopulationProgression).
	EnterMinSlimes = 20,
	EnterMinVillageLevel = 15,

	-- ===== Loot (docs/SMITHY.md §2) =====
	-- Every line of a monster's `drops` (Maps above) is rolled on its own: a roll r in [0, 1) under the line's `chance` pays
	-- min..max of its item. The level's luck (1 + LuckPerLevel x (level - 1)) multiplies a chance below 1 and never takes
	-- one past 1; a line at 1 never fails (the boss's two horns).
	-- A "food" drop is this raw food in the storehouse (Config.Food.Raw); what does not fit the pantry is lost.
	FoodItem = "carrot",
	-- What a drop is. `kind`: coins go to the purse, food to the storehouse, a material to farm.materials. The screens
	-- (client/UiDungeon) draw coins and food with the owner's coin and food pictures (Config.Ui.Icons) and a material with its
	-- `icon`: a Roblox image id (a number) or "rbxassetid://..." once the picture exists; until then ("") a plain rounded tile
	-- carries its `short` name. DropOrder is the order drops are listed in.
	Materials = {
		coins = { name = "Coins", kind = "coins" },
		food = { name = "Slime Snacks", kind = "food" },
		-- (the pictures: ChatGPT in the game's icon style, 2026-11-04, art/icons/dg_*.png)
		wood = { name = "Hardwood", short = "Wood", kind = "material", icon = 105540459123913 },
		-- (cloth and common_part no longer drop, but saves hold them: the entries stay, and a later map may take them back)
		cloth = { name = "Linen Cloth", short = "Cloth", kind = "material", icon = 128498997412713 },
		ore = { name = "Iron Ore", short = "Ore", kind = "material", icon = 107577459785586 },
		common_part = { name = "Slime Residue", short = "Residue", kind = "material", icon = 109902889353186 },
		rare_part = { name = "Core Fragment", short = "Fragment", kind = "material", icon = 104963871301466 },
		monster_core = { name = "Monster Core", short = "Core", kind = "material", icon = 118559273498942 },
		boss_essence = { name = "Boss Essence", short = "Essence", kind = "material", icon = 135452085949250 },
		-- the id stays (saves, the picture); only the name on screen is the Meadow's trophy "Bramble Horn"
		boar_tusk = { name = "Bramble Horn", short = "Horn", kind = "material", icon = 97935793546139 },
		-- the Mushroom Grove's trophy (no picture yet: a plain tile with "Spore" until ChatGPT's icon is in)
		glow_spore = { name = "Glow Spore", short = "Spore", kind = "material", icon = 138882147682185 },
	},
	DropOrder = {
		"coins",
		"food",
		"wood",
		"ore",
		"rare_part",
		"monster_core",
		"boss_essence",
		"boar_tusk",
		"glow_spore",
	},

	-- ===== The run (server/Dungeon) =====
	-- One private arena a run, at a slot a plot far from the valley (Layout.arenaFrame): plot n's arena stands at ArenaOrigin
	-- + (n - 1) x ArenaSpacing along X, beyond the hills, so it is never seen from the valley. The frame is the floor's top
	-- middle. ServerStorage's model named ArenaTemplate, when it exists, is cloned (a model whose pivot is that middle, about ArenaRadius
	-- wide); until the art step brings it, a greybox of parts is built (round floor, low rim of ArenaRimSegments boxes).
	ArenaOrigin = { x = 2400, y = 0, z = 0 },
	ArenaSpacing = 400,
	ArenaRadius = 70,
	ArenaTemplate = "DungeonArena",
	ArenaFolder = "DungeonArenas",
	ArenaFloorThickness = 4,
	ArenaRimHeight = 6,
	ArenaRimThickness = 2,
	ArenaRimSegments = 24,
	-- A monster comes in at a random point of the arena's edge band: SpawnMinFromCentre to ArenaRadius - SpawnInset from the
	-- middle, at least SpawnMinApart from every monster that stands (the original's 140 and 60 on its 320-wide field, in
	-- studs); after SpawnTries tries the point farthest from the others is taken.
	SpawnInset = 5,
	SpawnMinFromCentre = 50,
	SpawnMinApart = 14,
	SpawnTries = 12,
	-- How fighters walk in the arena (the owner, 2026-11-08: they crossed it in a blink). The server moves them (shared/Combat,
	-- positional mode, the dungeon only) at BaseStuds + PerSpeed x SPD studs a second, never above MaxStuds. SPD 1 gives 3.9
	-- (a slime's village walking pace is about 2.7, a bit brisker for a fight), SPD 10 7.5, SPD 40 and up the cap of 16; the
	-- meadow's monsters (SPD 0.7 to 5) walk at 3.8 to 5.5, so a Twigling crosses the 50 studs between its spawn and the
	-- squad in about 10 s and a fast slime in 4. A fighter strikes from MeleeStuds (centre to centre; the lunge closes the
	-- rest) or, when it keeps its distance (Config.Combat.Ranged), from RangedStuds. Fighters keep MinApart studs from each
	-- other: a walker tries other places round its target (SlotAngles degrees off its own line, nearest first) until one
	-- is free. A walker's goal is sent again to the clients every SyncSeconds.
	Move = {
		BaseStuds = 3.5,
		PerSpeed = 0.4,
		MaxStuds = 16,
		MeleeStuds = 6,
		RangedStuds = 16,
		MinApart = 3.5,
		SlotAngles = { 0, 25, -25, 50, -50, 80, -80, 110, -110, 145, -145, 180 },
		SyncSeconds = 0.5,
		-- A blow lands only on a target within reach plus this (its target may have stepped a little during the wind-up);
		-- one further off, or a new target picked because the old one fell, is walked to first.
		BlowSlack = 2,
	},
	-- The player stands PlayerSpot (flat, from the middle) PlayerLift up, facing the middle; leaving puts them ExitOut studs
	-- in front of their portal's opening, ExitLift up. A player who strays StrayStuds past the rim (a
	-- respawn, a fall) is put back.
	PlayerSpot = { x = 0, z = 22 },
	PlayerLift = 4,
	ExitOut = 12,
	ExitLift = 4,
	StrayStuds = 30,
	-- Enter works within the portal prompt's range plus this much; the Enter, Next and Replay requests are this far apart.
	EnterSlackStuds = 6,
	RequestSeconds = 1.5,
	-- A wave that goes on this long is lost (nothing should reach it; it is a guard against a stuck fight).
	WaveMaxSeconds = 240,
	-- What a run takes from each slime that fought, once when it ends (as a zombie fight does: Config.Zombies.FightEnergy).
	RunEnergy = 8,
	RunFullness = 2,
	-- How often the arena's and the player's attributes are written, and how long a fallen monster's stand-in lingers.
	PublishSeconds = 0.25,
	FoeFadeSeconds = 1.2,
	-- How long the server waits for the client to stream the arena in before it moves the player there.
	StreamSeconds = 6,
	-- The Sunny Meadow clearing, built once from the kit (server/DungeonArena, placed by shared/DungeonArenaPlan) after the
	-- owner's painting reference/goo-lineage-web/assets/battle.map.meadow.png: a round bright clearing, four dirt paths coming
	-- in on the four axes and fading out before the middle, rocks, flower clumps and bushes round the rim, round trees packed in
	-- each corner, pines beside the left and right paths, a ring of woods behind. Studs from the arena's middle; angles in degrees from +X toward +Z.
	-- One block a map of Maps (the key is the map id): the Meadow's here, the Mushroom Grove's after it (the owner's painting
	-- battle.map.mushroom.png: the same ring plan, in a dark mossy wood with stone paths, rune circles, ruins, roots and glowing
	-- mushrooms). A key only the Grove has is absent from the Meadow's block, which then simply has none of that.
	Arenas = {
		meadow = {
			Seed = 20261104,
			-- The grass floor (a stud-look block, the village's look) reaches FloorHalf each way, past the backdrop, so the world
			-- never shows its edge; FloorColour is the village lawn's, a little brighter like the painting.
			FloorHalf = 175,
			FloorColour = "#62ae3c",
			-- The invisible wall round the fight: slimes and players cannot leave; the rim scenery stands outside it.
			WallRadius = 68,
			WallHeight = 40,
			WallThickness = 2,
			WallSegments = 24,
			-- Nothing at all stands inside FightClear (the fight's centre); tiny flowers and pebbles lie from TinyFrom to TinyTo.
			FightClear = 35,
			TinyFrom = 37,
			TinyTo = 62,
			TinyFlowers = 14,
			TinyTufts = 6,
			TinyPebbles = 7,
			TinyApart = 7,
			-- The rim band that holds the scenery (outside the wall), and the woods behind it that hide the floor's edge: BackdropRows
			-- rows of trees (r from..to, count, height), their trunks only BackdropFoot of their height wide so the crowns overlap into
			-- one wall of leaves, a row of big bushes behind (BackdropBushes), and a ring of Hills (flattened balls of grass, the
			-- horizon the eye reads past the woods).
			RimInner = 71,
			RimOuter = 108,
			BackdropInner = 112,
			BackdropOuter = 140,
			BackdropRows = {
				{ from = 112, to = 123, count = 42, tall = { 30, 40 } },
				{ from = 125, to = 140, count = 50, tall = { 38, 52 } },
			},
			BackdropFoot = 0.13,
			BackdropPine = 0.35,
			BackdropBushes = 44,
			BushRowDepth = 10,
			Hills = {
				Count = 22,
				Radius = 172,
				Jitter = 10,
				Wide = { 120, 160 },
				Tall = { 46, 66 },
				-- how much of a hill's height sinks under the floor
				Sink = 0.4,
				Colour = "#6aa35c",
			},
			-- Four dirt paths on the axes, from PathOuter in to PathInner: PathSegments overlapping flat blocks that narrow from
			-- PathWidthOuter to PathWidthInner and drift sideways by up to PathWobble; the colour fades PathFade of the way to the
			-- grass at the inner end. Each lies PathLift over the floor (so the two never flicker) and is PathThick thick.
			PathColour = "#b9894f",
			PathOuter = 124,
			PathInner = 42,
			PathSegments = 10,
			PathWidthOuter = 11,
			PathWidthInner = 4,
			PathWobble = 0.6,
			PathFade = 0.55,
			PathLift = 0.05,
			PathThick = 0.1,
			-- ...and each segment sits PathStep over the one outside it, so the places where two overlap never flicker.
			PathStep = 0.01,
			-- The scenery keeps this far from an axis (plus half its own width) so the four path mouths stay open.
			MouthHalf = 11,
			-- Space between two pieces of scenery, over their two footprints' radii.
			Gap = 1.5,
			-- Per corner (the quadrant between two paths): round trees, rock pairs, single rocks, bushes, flower clumps; tries a
			-- piece gets.
			PerCorner = { Trees = 4, RockPairs = 2, Rocks = 3, Bushes = 6, Clumps = 7, Stumps = 1, Logs = 1 },
			-- The two trees past each path's outer end: how far past it, and how far apart from the path's line.
			MouthBehind = 8,
			MouthTreeApart = 7,
			Tries = 80,
			-- Heights (trees) or widths (the rest), studs: { low, high }. Backdrop trees are taller than the rim's.
			-- (bigger than the painting's share of the clearing: the game's camera stands at the rim and the scenery is 90-130 studs
			-- off, so it must be large to read)
			Round = { 26, 34 },
			Pine = { 28, 36 },
			BackdropRound = { 32, 40 },
			RockBig = { 9, 12 },
			RockSmall = { 5, 7 },
			RockSingle = { 6, 10.5 },
			Bush = { 7, 10 },
			BackdropBush = { 12, 17 },
			-- a flower clump is sized by its height (the library's Flowers stand on stalks)
			Flower = { 5, 7 },
			Stump = { 4.8, 6.5 },
			Log = { 9, 12 },
			Tuft = { 2.8, 4 },
			TinyFlower = { 2, 2.8 },
			TinyTuft = { 1.5, 2.1 },
			TinyPebble = { 1, 1.6 },
			-- Kit models (ServerStorage.Kit.WildKit) by kind, and the tints a kind may wear (a tint only multiplies, so these are
			-- the village's: it keeps the arena in the same world).
			-- Models: what the arena is built from, by kind. The meadow's own props are library props (Quaternius' Ultimate Nature
			-- Pack, recoloured to the painting's palette by tools/library/fbx_to_glb.py; Config.LibraryKit, server/LibraryKit); a
			-- kind whose library props are not all in yet is built from Fallback (the valley's WildKit models) instead, and a kind
			-- with neither is left out. The tufts and pebbles are WildKit's (the library has none that suit).
			Models = {
				-- (BirchTree_1's white trunk read as a stray bone at the rim: the painting has no birches)
				round = { "CommonTree_1", "CommonTree_2", "CommonTree_4", "CommonTree_5" },
				pine = { "PineTree_2", "PineTree_4" },
				rock = { "Rock_2", "Rock_3", "Rock_4", "Rock_5", "Rock_Moss_3" },
				bush = { "Bush_1", "Bush_2", "BushBerries_1" },
				flower = { "Flowers", "Flowers_Pink", "Flowers_White", "Flowers_Gold" },
				stump = { "TreeStump", "TreeStump_Moss" },
				log = { "WoodLog", "WoodLog_Moss" },
				tuft = { "QtGrass_Common_Short", "QtGrass_Common_Tall" },
				pebble = { "QtPebble_Round_1", "QtPebble_Square_2" },
			},
			Fallback = {
				round = { "QtCommonTree_1", "QtCommonTree_3", "QtCommonTree_5" },
				pine = { "QtPine_1", "QtPine_5" },
				rock = { "QtRock_Medium_1", "QtRock_Medium_2", "QtRock_Medium_3" },
				bush = { "QtBush_Common_Green", "QtBush_Common_Flowers" },
				flower = { "QtFlower_3_Group", "QtFlower_4_Group" },
				stump = {},
				log = {},
			},
			Tints = {
				-- (the imported leaves are brighter than the painting's: the tints take them down, and the pines to its deep
				-- blue-green, seen 2026-11-08)
				-- and darker than the grass, so the woods stand apart from the clearing (ChatGPT's review, 2026-11-08)
				round = { "#b4bca4", "#a8b49c", "#9cac94" },
				pine = { "#8cb4a8", "#7ca89c" },
				bush = { "#ffffff", "#f0ffd2" },
				tuft = { "#f0ffc8", "#e1fabe" },
			},
		},
		-- The Mushroom Grove (battle.map.mushroom.png): the Meadow's ring plan with its own keys. A mossy olive clearing in dusk
		-- light; four cracked flagstone paths (PathStyle "stones": Stones); four faint rune circles in the quarters (Runes);
		-- the corners packed with mossy ruin stones (kind `ruin`, by height), thick twisting roots (`root`, by width) and
		-- clusters of small glowing mushrooms (`glow`, by height) with a few point lights (Glow); giant mushrooms (kind `pine`,
		-- the second tall kind) beside the left and right paths and among the dark woods behind. The props are
		-- tools/library/build_grove.ps1's (MushroomProps.glb); a kind whose props are not all imported yet is built from
		-- Fallback (the owner's own mushrooms and rocks, the valley's teal trees) and one warning names which.
		mushroom = {
			Seed = 20261124,
			FloorHalf = 175,
			FloorColour = "#6c7a40",
			WallRadius = 68,
			WallHeight = 40,
			WallThickness = 2,
			WallSegments = 24,
			FightClear = 35,
			TinyFrom = 37,
			TinyTo = 62,
			TinyFlowers = 9,
			TinyTufts = 6,
			TinyPebbles = 9,
			TinyApart = 7,
			RimInner = 71,
			RimOuter = 108,
			BackdropInner = 112,
			BackdropOuter = 140,
			BackdropRows = {
				{ from = 112, to = 123, count = 42, tall = { 30, 40 } },
				{ from = 125, to = 140, count = 50, tall = { 38, 52 } },
			},
			BackdropFoot = 0.13,
			BackdropPine = 0.4,
			BackdropBushes = 44,
			BushRowDepth = 10,
			Hills = {
				Count = 22,
				Radius = 172,
				Jitter = 10,
				Wide = { 120, 160 },
				Tall = { 46, 66 },
				Sink = 0.4,
				Colour = "#1f4a3c",
			},
			-- The paths are flagstones: one stone every Step along each path, as many across as the path is wide (stones of
			-- Size x Depth studs, Thick thick, Gap apart), skipped with a chance that grows to Skip at the inner end so the path
			-- breaks up before the middle; Moss of them are mossy; Shade is how far each stone's grey may vary.
			PathStyle = "stones",
			Stones = {
				Step = 5,
				Size = { 2.8, 4.6 },
				Depth = { 2.6, 4 },
				Thick = 0.3,
				Gap = 0.5,
				Skip = 0.55,
				Moss = 0.3,
				Shade = 0.1,
				Tilt = 0.3,
				Colour = "#a8a38a",
				MossColour = "#6f9a3a",
			},
			PathColour = "#a8a38a",
			PathOuter = 124,
			PathInner = 42,
			PathSegments = 10,
			PathWidthOuter = 12,
			PathWidthInner = 6,
			PathWobble = 0.6,
			PathFade = 0.55,
			PathLift = 0.05,
			PathThick = 0.1,
			PathStep = 0.01,
			-- The four rune circles: in the middle of each quarter, At studs out, Radius wide; a flat stone ring (RingWidth wide,
			-- Stone grey, Thick) with Marks glowing runes (Colour, Neon) set round it and a second ring of them inside.
			Runes = {
				At = 47,
				Radius = 10,
				RingWidth = 1.6,
				Marks = 16,
				Thick = 0.12,
				Stone = "#8f9a78",
				Colour = "#8fffe5",
				MarkWidth = 1.1,
				MarkLength = 2.2,
			},
			-- A glowing cluster's light: the first Lights clusters of each corner carry a point light of the colour of their
			-- first mushroom (by the model's name), Lift above the floor, Range studs, never a particle.
			Glow = {
				Lights = { 2, 2, 1, 1 },
				Lift = 2,
				Range = 18,
				Brightness = 2.2,
				Colours = { Blue = "#4fc8ff", Purple = "#b36cf0", Pink = "#ff7fbf", Teal = "#3fe0c0" },
			},
			-- The light inside this map (client/DungeonLight eases the game's lighting to it while a run is on this map):
			-- dusk, teal and cool, the glow brighter against it.
			Lighting = {
				Seconds = 1.5,
				ClockTime = 17.82,
				Brightness = 2.7,
				Ambient = "#758f9c",
				OutdoorAmbient = "#8ca7b1",
				AtmosphereColour = "#7a8fb0",
				AtmosphereDecay = "#33405e",
				AtmosphereDensity = 0.42,
				AtmosphereOffset = 0.2,
				AtmosphereHaze = 2.2,
				TintColour = "#d6e6ff",
				Saturation = 0.05,
				GradeBrightness = -0.03,
				GradeContrast = 0.08,
			},
			MouthHalf = 11,
			Gap = 1.5,
			PerCorner = {
				Trees = 4,
				RockPairs = 1,
				Rocks = 2,
				Bushes = 5,
				Clumps = 4,
				Stumps = 0,
				Logs = 0,
				Ruins = 3,
				Roots = 3,
				Glows = 2,
			},
			MouthBehind = 8,
			MouthTreeApart = 7,
			Tries = 80,
			Round = { 26, 34 },
			Pine = { 20, 28 },
			BackdropRound = { 32, 40 },
			RockBig = { 9, 12 },
			RockSmall = { 5, 7 },
			RockSingle = { 6, 10.5 },
			Bush = { 7, 10 },
			BackdropBush = { 12, 17 },
			Flower = { 5, 7 },
			Stump = { 4.8, 6.5 },
			Log = { 9, 12 },
			Tuft = { 2.8, 4 },
			TinyFlower = { 2, 2.8 },
			TinyTuft = { 1.5, 2.1 },
			TinyPebble = { 1.4, 2.2 },
			-- the ruins stand 9 to 16 studs tall, a root lies 12 to 20 studs long, a glowing mushroom is 3 to 5 tall and a
			-- cluster has GlowCount models spread over GlowSpread studs
			Ruin = { 9, 16 },
			Root = { 12, 20 },
			GlowSize = { 3.2, 5.2 },
			GlowCount = { 3, 5 },
			GlowSpread = 2.6,
			Models = {
				round = { "Willow_1_Grove", "Willow_3_Grove", "CommonTree_2_Grove" },
				pine = { "MushBig_Blue", "MushBig_Purple", "MushBig_Teal" },
				rock = {
					"Rock_6_Grove",
					"Rock_7_Grove",
					"Rock_Moss_1_Grove",
					"Rock_Moss_2_Grove",
					"Rock_Moss_4_Grove",
					"Rock_Moss_5_Grove",
					"Rock_Moss_7_Grove",
					"GroveBlock_1",
					"GroveBlock_2",
				},
				ruin = {
					"GroveSlab_1",
					"GroveSlab_2",
					"GroveSlab_3",
					"Column_Round_Grove",
					"Column_Round_Short_Grove",
					"Wall_Half_Grove",
					"Wall_Broken_Grove",
					"Wall_Double_Broken_Grove",
					"Arch_Round_Grove",
				},
				root = { "GroveRoot_1", "GroveRoot_2", "GroveRoot_3", "GroveRoot_4", "GroveRoot_5" },
				glow = {
					"MushGlow_Blue_1",
					"MushGlow_Blue_2",
					"MushGlow_Purple_1",
					"MushGlow_Purple_2",
					"MushGlow_Pink_1",
					"MushGlow_Pink_2",
				},
				bush = { "Bush_1_Grove", "Bush_2_Grove", "Plant_3_Grove", "Plant_4_Grove", "Plant_1_Grove" },
				flower = { "Flowers_GroveBlue", "Flowers_GrovePurple", "Flowers_GrovePink" },
				stump = {},
				log = {},
				tuft = { "QtGrass_Common_Short", "QtGrass_Common_Tall" },
				pebble = { "Bricks_Grove" },
			},
			Fallback = {
				round = { "QtCommonTree_1_Teal", "QtCommonTree_3_Teal", "QtCommonTree_5_Teal" },
				pine = { "OwnMushBlue", "OwnMushPurple", "OwnMushPurpleSpotted", "OwnMushPink" },
				rock = { "QtRock_Medium_1", "QtRock_Medium_2", "QtRock_Medium_3" },
				ruin = { "OwnMossyRockStack", "OwnJungleStoneShelf" },
				root = {},
				glow = { "OwnMushBlue", "OwnMushPurple", "OwnMushPurpleSpotted", "OwnMushPink" },
				bush = { "QtBush_Common_Green", "QtBush_Common_Flowers" },
				flower = { "QtFlower_3_Group", "QtFlower_4_Group" },
				pebble = { "QtPebble_Round_1", "QtPebble_Square_2" },
				stump = {},
				log = {},
			},
			Tints = {
				round = { "#ffffff", "#e8e0ff", "#d8ecff" },
				bush = { "#ffffff", "#e0f0ff" },
				tuft = { "#a8c8b0", "#98bca4" },
			},
			-- the far woods stand a step darker than the near trees, so the near willows read against them
			BackdropTints = {
				round = { "#8f9fb0", "#8494b0", "#7f9cae" },
			},
		},
	},
	-- The stand-in for a monster until its model exists (the art step): a ball whose colour follows its kind, as big as its
	-- role. Not a final look.
	StandIn = {
		Colours = {
			melee = "#7fc15a",
			hunter = "#f2c230",
			ranged = "#f0e6a0",
			healer = "#b79cf0",
			bloomshell = "#3f9a6a",
			bramblehorn = "#8a5a3a",
			sporeburst = "#9a6ae0",
			bearslam = "#6a4a3a",
		},
		Sizes = { normal = 3, armoured = 4, miniboss = 7, boss = 10 },
	},
	-- Each monster's model: one of the owner's Egg Heist creatures (the owner, 2026-11-04: "use the many monster models
	-- Egg Heist already has"), in ReplicatedStorage.MonsterKit by tools/kit/eggheist_models.luau and moved by its own
	-- Egg Heist motion module `motion` (shared/Creatures, client/CreatureRig; client/MonsterLook, SlimeActor.dress).
	-- `height` the model's height in studs, `hover` how high a flyer flies (it then flies, wings beating) with a `bob`
	-- at `bobHz`. (A look may instead name `pieces`: a model of rigid pieces turned about their joints, shared/MonsterMotion;
	-- the Blender builds of the owner's paintings in art/models/monsters/ are kept that way.)
	Looks = {
		green_sprout = { model = "Twigling", motion = "pet_Twigling", height = 4.4 },
		green_bee = { model = "Parrot", motion = "pet_Parrot", height = 3.6, hover = 3.5, bob = 0.15, bobHz = 1.5 },
		green_dandelion = { model = "BloomSprite", motion = "pet_BloomSprite", height = 4.2 },
		green_moth = { model = "AuroraOwl", motion = "pet_AuroraOwl", height = 3.8, hover = 3, bob = 0.25, bobHz = 1.2 },
		green_snail = { model = "Hedgehog", motion = "pet_Hedgehog", height = 4.6 },
		green_turtle = { model = "Gorilla", motion = "pet_Gorilla", height = 8, shadow = true },
		green_boar = { model = "Triceratops", motion = "pet_Triceratops", height = 10, shadow = true },
		-- the Mushroom Grove's (heights are first guesses, set by eye at the fight camera)
		dark_hare = { model = "Jackalope", motion = "pet_Jackalope", height = 4.4 },
		dark_bat = { model = "CaveBat", motion = "pet_CaveBat", height = 3.6, hover = 3.5, bob = 0.2, bobHz = 1.6 },
		dark_fox = { model = "FairyFox", motion = "pet_FairyFox", height = 4.2 },
		dark_deer = { model = "Deer", motion = "pet_Deer", height = 6 },
		dark_totem = { model = "TotemGolem", motion = "pet_TotemGolem", height = 5.5 },
		dark_wyrm = { model = "JungleWyrm", motion = "pet_JungleWyrm", height = 7, shadow = true },
		dark_bear = { model = "Woods", motion = "boss_Woods", height = 11, shadow = true },
	},

	-- ===== The client (client/UiDungeon, DungeonFight, MonsterLook): pixels, studs and seconds =====
	View = {
		-- The gate sheet: its height, a team row (the row's portraits), the level stepper and the Enter button.
		GateSheetHeight = 420,
		TeamRowHeight = 56,
		TeamPortrait = 40,
		DropIcon = 22,
		-- the drops list: a line's height and the width of its "1-5" at the right
		DropRow = 26,
		DropRangeWidth = 44,
		StepperButton = 48,
		StepperLabel = 70,
		EnterWidth = 110,
		-- The arena HUD: the plate at the top (wave, level, monsters left), the drops column at the left edge, the Leave button
		-- at the right edge.
		PlateWidth = 236,
		PlateHeight = 40,
		PlateWave = 88,
		PlateLevel = 48,
		PlateLeft = 34,
		DropsWidth = 300,
		DropChip = 34,
		LeaveWidth = 104,
		-- The end card at the top: Victory or Defeat, the drops of the run and the buttons.
		EndWidth = 420,
		EndHeight = 140,
		EndTitle = 30,
		-- The wave banner ("Wave 3", "Mini-boss!", "Boss!"): where (share of the screen's height), how big, how long.
		BannerTop = 0.2,
		BannerSize = 44,
		BannerSeconds = 1.8,
		BannerColours = { normal = "#ffe9a8", miniboss = "#ffb02e", boss = "#ff6a5a" },
		-- How often the HUD and the arena's published health are looked at (the HUD itself follows the player's attributes).
		PollSeconds = 0.25,
		-- The squad stands in a row across the arena's middle, SquadBack studs behind the centre line, facing the player.
		SquadBack = 2,
		-- A walking fighter (server "move" events) hops every WalkHopStuds studs of its way, WalkHop high.
		WalkHopStuds = 3,
		-- A drawn fighter that has fallen behind the server never goes faster than this many times the fastest walker.
		WalkCatchUp = 1.25,
		WalkHop = 0.35,
		-- A fighter stays this far inside the rim.
		EdgeMargin = 5,
		-- A monster's name and level over its health bar (pixels); a stray body is cleared when the player's DungeonPhase has
		-- been empty this long after a run began.
		NameWidth = 160,
		NameHeight = 22,
		ClearGrace = 3,
		NameColours = { normal = "#fffdf4", miniboss = "#ffb02e", boss = "#ff6a5a" },
		-- A drop popping out of a fallen monster: the picture's size, how long it floats, how high it rises, how many at once.
		PopIcon = 30,
		PopSeconds = 1.3,
		PopRise = 5,
		PopMax = 10,
		PopDelay = 0.22,
		-- The way each monster kind fights, as a Config.Zombies.View.Fx.Styles / Moves name (a kind left out fights as rotten).
		Ways = {
			melee = "rotten",
			hunter = "plague",
			ranged = "toxic",
			healer = "rotten",
			bloomshell = "plague",
			bramblehorn = "rotten",
			sporeburst = "plague",
			bearslam = "hp",
		},
		-- A monster's burst when it falls grows with its size, up to this many times a plain one's.
		DeathBigness = 2,
		-- A healer's mending: the picture over the one healed (studs across).
		HealBurst = 4,
		HealColour = "Green",
		-- How often the portal prompts are looked at.
		GateWatchSeconds = 1,
	},

	-- ===== The portal (server/DungeonPortal, Layout.marketPortal) =====
	-- Egg Heist's portal (the owner, 2026-11-04: "use the portal we have"), rebuilt from its kit meshes, which the owner's
	-- account published (InsertService ids). ONE portal for everyone in the Market (the owner, 2026-11-04: in the shopping
	-- area, shared; whoever steps in goes to their own arena), at Market (a Config.Market-style spot, across the square
	-- from the Blacksmith), its opening turned to the square's middle, at Scale of its full size (about 29 x 23 studs). The
	-- prompt that opens the Dungeon works from PromptRangeStuds; a lock of LockPixels hangs in the ring for a player who may
	-- not go in yet (EnterMinSlimes, EnterMinVillageLevel), seen from LockShowStuds.
	Portal = {
		Pieces = {
			bush_tall_grass = 86818606224653,
			portal_crystal = 81030539240809,
			portal_pillar = 95971264752250,
			rock_boulder_big = 76184147421470,
			rock_cliff_chunk = 120536488786893,
			rock_cracked_split = 74245328366319,
			rock_flat_slab = 120446354505612,
		},
		-- back right of the square, the Blacksmith's mirror (its middle, so a little further out than the Smithy's prompt spot)
		Market = { x = -51, z = 30 },
		Scale = 0.55,
		PromptRangeStuds = 14,
		LockPixels = 72,
		LockShowStuds = 160,
	},
}
