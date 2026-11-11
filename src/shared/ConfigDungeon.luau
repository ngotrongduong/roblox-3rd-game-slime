--!strict
-- Config.Dungeon, in a file of its own: Studio refuses a script of 200000 characters or more, so Config's
-- biggest blocks live apart. Config.luau requires this file; the game reads it as Config.Dungeon.

return {
	-- The maps (Sunny Meadow, Mushroom Grove, Ember Lava; the order they turn in is MapOrder below). A monster: its budget `cost` (none for a mini-boss or boss,
	-- which come alone), its level-1 stats (the same kind of numbers a slime has), its `role`, and `kind`: the way it
	-- fights in Config.Combat (melee strikes anyone; ranged keeps its distance; hunter goes for the slime with the least
	-- health and stings it slow; healer mends its wounded team-mates; bloomshell and bramblehorn are the two bosses with a
	-- skill of their own). `drops` (docs/SMITHY.md §2): a list of lines { item, chance, min, max }, each rolled on its own
	-- when the monster falls (see "Loot" below); an item is a key of Materials.
	-- The monsters' specials (docs/MONSTER-SLIMES.md, "Attacks"), copied by Config into Config.Combat.Skills, which says what
	-- each `kind` does. A monster's `skills` list (Maps) takes them in turn; each comes every `every` blows of the FIRST in
	-- the list (every mending, for a mend). Numbers are a first guess the owner tunes by playing. A boss's and a mini-boss's
	-- specials carry `windup` (Config.Combat.Skills): they are called that early, so their charge plays whole; a regular
	-- monster's attacking special a shorter one, for a readable tell before it pops (Fx.Pop).
	Skills = {
		-- the Meadow
		burr_roll = { kind = "multi", name = "Burr Roll", every = 4, factor = 0.7, hits = 2, windup = 0.6 },
		honey_lance = { kind = "single", name = "Honey Lance", every = 4, factor = 1.8, windup = 0.6 },
		seed_volley = { kind = "multi", name = "Seed Volley", every = 4, factor = 0.5, hits = 3, windup = 0.6 },
		bloom_mend = { kind = "mend", name = "Bloom Mend", every = 3, share = 0.6 },
		bark_wall = { kind = "guard", name = "Bark Wall", every = 5, factor = 1, seconds = 3, defence = 1.3 },
		root_snare = { kind = "single", name = "Root Snare", every = 5, factor = 1.6, stun = 1, windup = 1.2 },
		bramble_burst = { kind = "all", name = "Bramble Burst", every = 4, factor = 0.6, stun = 0.4, windup = 1.2 },
		horn_toss = { kind = "single", name = "Horn Toss", every = 4, factor = 2.6, windup = 1.2 },
		-- the Mushroom Grove
		mandible_frenzy = { kind = "multi", name = "Mandible Frenzy", every = 4, factor = 0.45, hits = 3, windup = 0.6 },
		lure_flash = { kind = "single", name = "Lure Flash", every = 4, factor = 1.5, stun = 0.6, windup = 0.6 },
		acid_splash = {
			kind = "splash",
			name = "Acid Splash",
			every = 4,
			factor = 1.2,
			splash = 0.5,
			spread = 2,
			slow = 0.3,
			slowSeconds = 2,
			windup = 0.6,
		},
		hex_mend = { kind = "mend", name = "Hex Mend", every = 3, share = 0.6 },
		rune_ward = { kind = "guard", name = "Rune Ward", every = 5, factor = 1, seconds = 3, defence = 1.3 },
		gorge_bite = { kind = "single", name = "Gorge Bite", every = 4, factor = 2, windup = 1.2 },
		root_grasp = {
			kind = "all",
			name = "Root Grasp",
			every = 4,
			factor = 0.45,
			slow = 0.5,
			slowSeconds = 3,
			windup = 1.2,
		},
		heart_pulse = { kind = "all", name = "Heart Pulse", every = 4, factor = 0.7, stun = 0.5, windup = 1.2 },
		-- Ember Lava
		flare_pop = {
			kind = "splash",
			name = "Flare Pop",
			every = 4,
			factor = 1,
			splash = 0.5,
			spread = 2,
			windup = 0.6,
		},
		comet_dash = { kind = "multi", name = "Comet Dash", every = 4, factor = 0.9, hits = 2, windup = 0.6 },
		fireball = {
			kind = "splash",
			name = "Fireball",
			every = 4,
			factor = 1.6,
			splash = 0.6,
			spread = 2,
			windup = 0.6,
		},
		pyre_mend = { kind = "mend", name = "Pyre Mend", every = 3, share = 0.6 },
		basalt_wall = { kind = "guard", name = "Basalt Wall", every = 5, factor = 1, seconds = 3, defence = 1.3 },
		molten_chomp = { kind = "multi", name = "Molten Chomp", every = 4, factor = 1.2, hits = 2, windup = 1.2 },
		mane_lash = {
			kind = "splash",
			name = "Mane Lash",
			every = 5,
			factor = 2,
			splash = 0.7,
			spread = 3,
			windup = 1.2,
		},
		meteor_rain = { kind = "multi", name = "Meteor Rain", every = 5, factor = 0.9, hits = 3, windup = 1.2 },
		-- Frozen Ice
		icicle_bite = {
			kind = "single",
			name = "Icicle Bite",
			every = 4,
			factor = 1.4,
			slow = 0.4,
			slowSeconds = 1.5,
			windup = 0.6,
		},
		saw_spin = { kind = "multi", name = "Saw Spin", every = 4, factor = 0.5, hits = 3, windup = 0.6 },
		crystal_burst = {
			kind = "splash",
			name = "Crystal Burst",
			every = 4,
			factor = 1.3,
			splash = 0.6,
			spread = 2,
			slow = 0.3,
			slowSeconds = 2,
			windup = 0.6,
		},
		frost_mend = { kind = "mend", name = "Frost Mend", every = 3, share = 0.6 },
		ice_wall = { kind = "guard", name = "Ice Wall", every = 5, factor = 1, seconds = 3, defence = 1.3 },
		frost_breath = {
			kind = "splash",
			name = "Frost Breath",
			every = 4,
			factor = 1,
			splash = 0.6,
			spread = 3,
			slow = 0.4,
			slowSeconds = 2,
			windup = 1.2,
		},
		glacier_gore = { kind = "single", name = "Glacier Gore", every = 5, factor = 2.8, windup = 1.2 },
		frost_gale = {
			kind = "splash",
			name = "Frost Gale",
			every = 5,
			factor = 1.2,
			splash = 0.7,
			spread = 3,
			slow = 0.5,
			slowSeconds = 2.5,
			windup = 1.2,
		},
	},
	Maps = {
		meadow = {
			name = "Sunny Meadow",
			monsters = {
				{
					id = "green_sprout",
					skills = { "burr_roll" },
					name = "Burrling",
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
					skills = { "honey_lance" },
					name = "Stinglob",
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
					skills = { "seed_volley" },
					name = "Gapebloom",
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
					skills = { "bloom_mend" },
					name = "Sapcaller",
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
					skills = { "bark_wall" },
					name = "Barkhide",
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
					skills = { "bloomshell", "root_snare" },
					name = "Rotbloom",
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
					skills = { "bramblehorn", "bramble_burst", "horn_toss" },
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
					skills = { "mandible_frenzy" },
					name = "Gloomtick",
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
					skills = { "lure_flash" },
					name = "Glimlure",
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
					skills = { "acid_splash" },
					name = "Bilebloat",
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
					skills = { "hex_mend" },
					name = "Hexcap",
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
					skills = { "rune_ward" },
					name = "Ruingut",
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
					skills = { "sporeburst", "gorge_bite" },
					name = "Sporegorge",
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
					skills = { "bearslam", "root_grasp", "heart_pulse" },
					name = "Hollowheart",
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
		-- Ember Lava: the Grove's roles again, each a step stronger (docs/DUNGEON_MAPS.md §3; the monsters are
		-- docs/MONSTER-SLIMES.md's). The healer is the Pyrekeeper. The trophy is the Ember Core: the boss pays two, never
		-- fewer; the mini-boss, the spitter and the healer sometimes one.
		lava = {
			name = "Ember Lava",
			monsters = {
				{
					id = "lava_newt",
					skills = { "flare_pop" },
					name = "Wickling",
					role = "swarmer",
					cost = 1,
					attack = 2,
					defence = 0,
					speed = 3.2,
					hp = 16,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 4 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.35, min = 1, max = 1 },
					},
				},
				{
					id = "lava_wolf",
					skills = { "comet_dash" },
					name = "Scorchdart",
					role = "raider",
					cost = 2,
					attack = 4,
					defence = 0,
					speed = 5,
					hp = 19,
					kind = "hunter",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "wood", chance = 0.15, min = 1, max = 1 },
						{ item = "ore", chance = 0.10, min = 1, max = 1 },
					},
				},
				{
					id = "lava_phoenix",
					skills = { "fireball" },
					name = "Blazegullet",
					role = "spitter",
					cost = 2,
					attack = 3,
					defence = 0,
					speed = 2.4,
					hp = 18,
					kind = "ranged",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.30, min = 1, max = 1 },
						{ item = "ember_core", chance = 0.10, min = 1, max = 1 },
					},
				},
				{
					id = "lava_drake",
					skills = { "pyre_mend" },
					name = "Pyrekeeper",
					role = "shaman",
					cost = 2,
					attack = 1,
					defence = 0,
					speed = 2.5,
					hp = 22,
					kind = "healer",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.15, min = 1, max = 1 },
						{ item = "rare_part", chance = 0.05, min = 1, max = 1 },
						{ item = "ember_core", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "lava_tortoise",
					skills = { "basalt_wall" },
					name = "Basaltback",
					role = "armoured",
					cost = 3,
					attack = 3,
					defence = 10,
					speed = 0.8,
					hp = 44,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.30, min = 3, max = 6 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.45, min = 1, max = 2 },
						{ item = "rare_part", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "lava_bull",
					skills = { "lavastomp", "molten_chomp" },
					name = "Magmaw",
					role = "miniboss",
					attack = 7,
					defence = 4,
					speed = 3,
					hp = 170,
					kind = "lavastomp",
					drops = {
						{ item = "coins", chance = 1, min = 6, max = 11 },
						{ item = "ore", chance = 1, min = 2, max = 3 },
						{ item = "rare_part", chance = 0.60, min = 1, max = 2 },
						{ item = "monster_core", chance = 0.30, min = 1, max = 1 },
						{ item = "ember_core", chance = 0.35, min = 1, max = 2 },
					},
				},
				{
					id = "lava_golem",
					skills = { "eruption", "mane_lash", "meteor_rain" },
					name = "Calderos",
					role = "boss",
					attack = 8,
					defence = 6,
					speed = 1.5,
					hp = 340,
					kind = "eruption",
					drops = {
						{ item = "coins", chance = 1, min = 12, max = 20 },
						{ item = "ore", chance = 1, min = 3, max = 5 },
						{ item = "rare_part", chance = 1, min = 2, max = 3 },
						{ item = "monster_core", chance = 0.50, min = 1, max = 1 },
						{ item = "boss_essence", chance = 0.25, min = 1, max = 1 },
						-- the map's trophy: two ember cores, never fewer
						{ item = "ember_core", chance = 1, min = 2, max = 2 },
					},
				},
			} :: { any },
		},
		-- Frozen Ice, the fourth and last map: the same roles again, each a step stronger than Ember Lava's, with the owner's ice
		-- creatures from Egg Heist (docs/DUNGEON_MAPS.md §3). The healer is the Penguin, not the Aurora Owl: the Owl already
		-- heals in the Meadow, the Penguin is one of Egg Heist's rigged pets and a walker (a motion the healers do not have yet,
		-- and a bird that fits the snow). The mini-boss is the Mammoth (Tusk Charge, two rams) and the boss the Yeti of the Peaks
		-- (Blizzard on every slime). The trophy is the Frost Fang: the boss pays two, never fewer; the mini-boss, the Frost Wisp
		-- and the Penguin sometimes one.
		ice = {
			name = "Frozen Ice",
			monsters = {
				{
					id = "ice_fox",
					skills = { "icicle_bite" },
					name = "Frostnip",
					role = "swarmer",
					cost = 1,
					attack = 3,
					defence = 0,
					speed = 3.4,
					hp = 20,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.25, min = 2, max = 5 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.35, min = 1, max = 1 },
					},
				},
				{
					id = "ice_leopard",
					skills = { "saw_spin" },
					name = "Rimesaw",
					role = "raider",
					cost = 2,
					attack = 5,
					defence = 0,
					speed = 5.2,
					hp = 24,
					kind = "hunter",
					drops = {
						{ item = "coins", chance = 0.25, min = 3, max = 6 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "wood", chance = 0.15, min = 1, max = 1 },
						{ item = "ore", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "ice_wisp",
					skills = { "crystal_burst" },
					name = "Shardspire",
					role = "spitter",
					cost = 2,
					attack = 4,
					defence = 0,
					speed = 2.4,
					hp = 22,
					kind = "ranged",
					drops = {
						{ item = "coins", chance = 0.25, min = 3, max = 6 },
						{ item = "food", chance = 0.15, min = 3, max = 5 },
						{ item = "wood", chance = 0.30, min = 1, max = 1 },
						{ item = "frost_fang", chance = 0.10, min = 1, max = 1 },
					},
				},
				{
					id = "ice_penguin",
					skills = { "frost_mend" },
					name = "Snowshroud",
					role = "shaman",
					cost = 2,
					attack = 1,
					defence = 0,
					speed = 2.5,
					hp = 27,
					kind = "healer",
					drops = {
						{ item = "coins", chance = 0.25, min = 3, max = 6 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.15, min = 1, max = 1 },
						{ item = "rare_part", chance = 0.05, min = 1, max = 1 },
						{ item = "frost_fang", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "ice_golem",
					skills = { "ice_wall" },
					name = "Icebound",
					role = "armoured",
					cost = 3,
					attack = 4,
					defence = 12,
					speed = 0.8,
					hp = 56,
					kind = "melee",
					drops = {
						{ item = "coins", chance = 0.30, min = 4, max = 7 },
						{ item = "food", chance = 0.10, min = 3, max = 5 },
						{ item = "ore", chance = 0.45, min = 1, max = 2 },
						{ item = "rare_part", chance = 0.12, min = 1, max = 1 },
					},
				},
				{
					id = "ice_mammoth",
					skills = { "tuskcharge", "frost_breath" },
					name = "Rimetusk",
					role = "miniboss",
					attack = 9,
					defence = 5,
					speed = 2.8,
					hp = 215,
					kind = "tuskcharge",
					drops = {
						{ item = "coins", chance = 1, min = 8, max = 13 },
						{ item = "ore", chance = 1, min = 2, max = 3 },
						{ item = "rare_part", chance = 0.60, min = 1, max = 2 },
						{ item = "monster_core", chance = 0.30, min = 1, max = 1 },
						{ item = "frost_fang", chance = 0.35, min = 1, max = 2 },
					},
				},
				{
					id = "ice_yeti",
					skills = { "blizzard", "glacier_gore", "frost_gale" },
					name = "Frostmaw",
					role = "boss",
					attack = 10,
					defence = 7,
					speed = 1.4,
					hp = 420,
					kind = "blizzard",
					drops = {
						{ item = "coins", chance = 1, min = 14, max = 23 },
						{ item = "ore", chance = 1, min = 3, max = 5 },
						{ item = "rare_part", chance = 1, min = 2, max = 3 },
						{ item = "monster_core", chance = 0.50, min = 1, max = 1 },
						{ item = "boss_essence", chance = 0.25, min = 1, max = 1 },
						-- the map's trophy: two frost fangs, never fewer
						{ item = "frost_fang", chance = 1, min = 2, max = 2 },
					},
				},
			} :: { any },
		},
	},
	-- The maps turn one step each dungeon level (shared/Dungeon.mapForLevel), from a first map each player's UserId picks
	-- (MapFirstRandom, the original's seeded first map; off, everyone starts on the first of the list). MapSeedOffset is the
	-- original's seed + 77. Frozen Ice is the last of the four.
	MapOrder = { "meadow", "mushroom", "lava", "ice" },
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
		-- Ember Lava's trophy (icon from ChatGPT, art/icons/dg_ember_core.png)
		ember_core = { name = "Ember Core", short = "Ember", kind = "material", icon = 78182808861046 },
		-- Frozen Ice's trophy (icon from ChatGPT, art/icons/dg_frost_fang.png)
		frost_fang = { name = "Frost Fang", short = "Fang", kind = "material", icon = 116041071019115 },
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
		"ember_core",
		"frost_fang",
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
		-- Monsters walk FoeGain times a slime of the same SPD (the owner, 2026-11-10: they were too slow, twice as fast).
		FoeGain = 2,
		-- Blows that reach past the target (the owner, 2026-11-10: fighters far away were being hit): a splash lands only on
		-- foes within SplashStuds of its target, an "all" skill only on foes within AreaStuds of the one using it (a ranged
		-- fighter's reach plus the slack, so everyone fighting it is in), and a guard takes a team-mate's blow only within
		-- GuardStuds of it.
		SplashStuds = 8,
		AreaStuds = 18,
		GuardStuds = 8,
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
	-- How many teams one run takes in (the owner, 2026-11-10: one team only).
	RunTeams = 1,
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
		-- Ember Lava (battle.map.lava.png), round 4 (the art director: a volcanic CRATER, not a crystal wasteland): the Meadow's
		-- ring plan with its own keys. A neutral charcoal stud floor (#3F3A42) ringed by darker, hotter ground; no path is drawn
		-- (PathStyle "none": the four lanes only stay free). The rock is heavy, LOW basalt: boulder masses on a first shelf
		-- (kind `ruin`, by height; `pine` for the framing masses and the backdrop rows, lower straight behind: BackdropLow),
		-- terraced ledges (`log`, by width), short thick column groups (`stump`), boulders (`rock`), and only four landmark
		-- groups of sharp peaks (`round`). Flat fracture plates lie on the floor (`pebble`, by width). The lava is four connected
		-- fissure systems, one a quarter (`vein`, claiming nothing, thin tip at VeinTip from the middle) each ending in a pool
		-- (`pool`, claiming its ground; the first Glow.Lights of a quarter are lit), turned Neon in white by `Neon` (the mesh
		-- carries its own colours). No plants, no glowing domes. The props are tools/library/build_lava.ps1's (LavaProps.glb,
		-- all in Config.LibraryKit); Fallback (the owner's basalt and the valley's rocks) only guards a kind whose props are
		-- missing, and the lava (no fallback) is then simply absent, with one warning naming which kinds. The light is LATE
		-- DUSK (ClockTime 18.2, no stars: a dark sky with a thin warm band on the horizon; the glow carries the scene).
		lava = {
			Seed = 20261207,
			FloorHalf = 175,
			FloorColour = "#3f3a42",
			WallRadius = 68,
			WallHeight = 40,
			WallThickness = 2,
			WallSegments = 24,
			FightClear = 35,
			TinyFrom = 42,
			TinyTo = 66,
			TinyFlowers = 0,
			TinyTufts = 0,
			TinyPebbles = 10,
			TinyApart = 14,
			RimInner = 70,
			RimOuter = 104,
			BackdropInner = 108,
			BackdropOuter = 138,
			BackdropRows = {
				{ from = 108, to = 118, count = 14, tall = { 6, 10 } },
				{ from = 120, to = 138, count = 18, tall = { 9, 14 } },
			},
			BackdropFoot = 0.5,
			BackdropPine = 1,
			BackdropLow = { Lateral = 40, Factor = 0.55 },
			BackdropBushes = 0,
			BushRowDepth = 10,
			-- Two overlapping layers of dark hills beyond the shelf: the near ring, and Far, taller and darker behind it.
			Hills = {
				Count = 24,
				Radius = 160,
				Jitter = 8,
				Wide = { 70, 96 },
				Tall = { 14, 24 },
				Sink = 0.4,
				Colour = "#2f2a37",
				Far = {
					Count = 30,
					Radius = 196,
					Jitter = 10,
					Wide = { 140, 190 },
					Tall = { 50, 70 },
					-- (the foot barely sunk: with the ring's 0.4 the valleys between the hills fell to the floor line and the farm
					-- hill's grass showed through them)
					Sink = 0.12,
					Colour = "#221e2a",
				},
			},
			-- No path is drawn; these only keep the four lanes along the axes free (the plan reads them for the tiny pieces).
			PathStyle = "none",
			PathColour = "#4d4360",
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
			-- The lava, turned Neon in white: the mesh's own vertex colours (core #FFAD3D, body #F15A20, bank #211A1D) show as painted.
			Neon = { vein = "#ffffff", pool = "#ffffff" },
			-- A pool's light: the first Lights pools of each quarter (list: quarters 1 to 4, the two far ones the player's camera
			-- looks into last) carry a point light, Lift above the floor, Range studs, never a particle. Six in all; the colour is
			-- found by the model's name.
			Glow = {
				Lights = { 1, 1, 2, 2 },
				Lift = 3,
				Range = 22,
				Brightness = 1.3,
				Colours = { Lava = "#ff7132" },
			},
			-- The light inside this map (client/DungeonLight eases the game's lighting to it while a run is on this map): late dusk
			-- (the place's own dusk sky is teal, wrong over lava; at 18.2 the sky is almost black with a faint warm band; later
			-- it is plain navy, earlier olive), Stars 0, the rock lit by a bright neutral ambient and Exposure (the sun is under
			-- the horizon) so the floor shows its stud colour and the black and dark slimes stay seen, the lava brighter.
			Lighting = {
				Seconds = 1.5,
				ClockTime = 18.2,
				Stars = 0,
				Brightness = 3,
				Exposure = 0.35,
				Ambient = "#e0dade",
				OutdoorAmbient = "#f0e8ec",
				AtmosphereColour = "#5a3050",
				AtmosphereDecay = "#8a3a30",
				AtmosphereDensity = 0.7,
				AtmosphereOffset = 0,
				AtmosphereHaze = 3,
				TintColour = "#ffe4d4",
				Saturation = 0.05,
				GradeBrightness = 0,
				GradeContrast = 0.1,
			},
			MouthHalf = 11,
			Gap = 1.5,
			PerCorner = {
				Trees = 1,
				RockPairs = 1,
				Rocks = 2,
				Bushes = 0,
				Clumps = 0,
				Stumps = 3,
				Logs = 2,
				Ruins = 2,
				Roots = 0,
				Glows = 0,
				-- (the lava: a list, one number for each quarter; each quarter has one fissure system)
				Pools = { 1, 1, 2, 2 },
				Veins = 1,
			},
			MouthBehind = 8,
			MouthTreeApart = 7,
			-- (the four path mouths are closed by low basalt masses, not by tall trees)
			MouthKind = "pine",
			Tries = 160,
			-- the landmark peaks (kind `round`, by height): one group in each corner, 20 to 28 studs
			Round = { 20, 28 },
			-- the masses that frame the near-path sides (kind `pine`, by height) and the shelf's (`ruin`): 8 to 11 studs tall,
			-- about twice that across, so their footprint is most of their height
			Pine = { 8, 11 },
			PineFoot = 0.7,
			Ruin = { 8, 10.5 },
			RuinFoot = 0.7,
			RockPairFoot = 6.5,
			StumpFoot = 0.4,
			BackdropRound = { 8, 12 },
			RockBig = { 7, 10 },
			RockSmall = { 4.5, 6.5 },
			RockSingle = { 6, 10 },
			Bush = { 7, 10 },
			BackdropBush = { 12, 17 },
			Flower = { 5, 7 },
			-- short thick column groups, 7 to 10 across; terraced ledges 12 to 18 across (2 to 5 high)
			Stump = { 7, 10 },
			Log = { 12, 18 },
			Tuft = { 2.8, 4 },
			TinyFlower = { 2, 2.8 },
			TinyTuft = { 1.5, 2.1 },
			-- the floor's broad low fracture plates, 6 to 12 across (R42 to 66)
			TinyPebble = { 6, 12 },
			Root = { 6, 9 },
			GlowSize = { 3.2, 5.2 },
			GlowCount = { 3, 5 },
			GlowSpread = 2.6,
			-- The lava: a pool is 8 to 14 studs long; a fissure system's main channel is 22 to 30 long with its thin tip 46 to 54
			-- studs from the middle (nothing inside 35), so its thick end, 70 to 84 out, runs into a pool at the rim.
			Pool = { 8, 14 },
			Vein = { 22, 30 },
			VeinTip = { 46, 54 },
			Models = {
				round = { "LavaPeak_1", "LavaPeak_2", "LavaPeak_3" },
				pine = { "LavaMass_1", "LavaMass_2", "LavaMass_3", "LavaMass_4" },
				rock = {
					"LavaBoulder_1",
					"LavaBoulder_2",
					"LavaBoulder_3",
					"Rock_1_Lava",
					"Rock_2_Lava",
					"Rock_3_Lava",
					"Rock_4_Lava",
					"Rock_5_Lava",
				},
				ruin = { "LavaMass_1", "LavaMass_2", "LavaMass_3", "LavaMass_4" },
				root = {},
				stump = { "LavaStump_1", "LavaStump_2", "LavaStump_3" },
				log = { "LavaLedge_1", "LavaLedge_2", "LavaLedge_3" },
				pebble = { "LavaPlate_1", "LavaPlate_2", "LavaPlate_3" },
				vein = { "LavaFissure_1", "LavaFissure_2", "LavaFissure_3", "LavaFissure_4" },
				pool = { "LavaPool_1", "LavaPool_2", "LavaPool_3", "LavaPool_4" },
				glow = {},
				bush = {},
				flower = {},
				tuft = {},
			},
			Fallback = {
				round = { "QtDeadTree_1", "QtDeadTree_3", "QtDeadTree_5" },
				pine = { "OwnStackedBasalt", "OwnMoltenPlateau" },
				rock = { "QtRock_Medium_1", "QtRock_Medium_2", "QtRock_Medium_3" },
				ruin = { "OwnStackedBasalt", "OwnMoltenPlateau" },
				root = {},
				stump = {},
				log = {},
				pebble = { "QtPebble_Round_1", "QtPebble_Square_2" },
				vein = {},
				pool = {},
				glow = {},
				bush = {},
				flower = {},
				tuft = {},
			},
			-- (the library props carry their own colours in vertex colour, so nothing is tinted)
			Tints = {},
			BackdropTints = {},
		},
		-- Frozen Ice (battle.map.ice.png), round 4, the fourth and last map: the Meadow's ring plan with its own keys, the biggest
		-- calm clearing of the four. An ice-white stud floor (#dbe9f7, the brightest value of the picture) with a shore of low
		-- snow drifts round it (kind `mound`, Mounds: broken only at the four lanes), no path drawn (PathStyle "none"). The
		-- masses are groves of frosted pines on a snow base (kind `pine`, with two single frosted pines; `round` for the corners'
		-- lone pines and bare twig trees), heavy slate rock as the contrast (`ruin` masses by height, `rock` boulders by width),
		-- snow-capped bushes and shrubs, stumps, and logs with short snow fences (`log`, by width); the corners hold blue
		-- crystal clusters (`glow`, a few lit) and shards (`root`), turned Neon and a little see-through by `Neon` and
		-- `NeonAlpha` (the mesh carries its own blues); the floor has flat crack lines (`pebble`, by width) in the open band.
		-- The props are tools/library/build_ice.ps1's (IceProps.glb, all named in Models and in Config.LibraryKit since the
		-- owner's import; Fallback, the valley's dead trees and rocks, only guards a kind whose models fail to load). The light is
		-- an OVERCAST WINTER DAY: a pale full-cover cloud layer (Lighting.Clouds), a bluish ambient, desaturated (the place's own
		-- grade adds colour) and a little negative exposure, so the near-white floor does not burn out.
		ice = {
			Seed = 20261221,
			FloorHalf = 175,
			FloorColour = "#ddebf5",
			WallRadius = 68,
			WallHeight = 40,
			WallThickness = 2,
			WallSegments = 24,
			FightClear = 35,
			TinyFrom = 40,
			TinyTo = 66,
			TinyFlowers = 0,
			TinyTufts = 0,
			-- (round 4) a few thin cracks, 6 to 12 long, and 8 faint frost patches, 7 to 15 wide, on the outer fight ring
			TinyPebbles = 7,
			TinyPatches = 8,
			TinyApart = 16,
			RimInner = 71,
			RimOuter = 106,
			BackdropInner = 110,
			BackdropOuter = 142,
			-- (round 4: a thinner wood, 9 to 17 tall, in dense groups with short gaps between: the ridges and the far land do the
			-- backdrop's work now)
			BackdropRows = {
				{ from = 110, to = 122, count = 14, tall = { 9, 13 } },
				{ from = 124, to = 142, count = 16, tall = { 11, 17 } },
			},
			BackdropClump = { Groups = 9, Pull = 0.7 },
			BackdropFoot = 0.42,
			BackdropPine = 1,
			-- (the groves straight behind the monsters, along the four axes, stand lower so the boss reads against the sky)
			BackdropLow = { Lateral = 40, Factor = 0.6 },
			BackdropBushes = 0,
			BushRowDepth = 10,
			-- Two layers beyond the woods (round 4, from the art director's review: the smooth domes and the teal strip at the
			-- horizon are gone). The near ring is faceted snow ridges (the `ridge` models, stretched to Wide x Tall: 7 to 9 in
			-- view, some lower so the skyline undulates); Far is the far land (the `far` models) in one continuous, overlapping
			-- opaque skyline whose foot is sunk under the floor line, so no sea or ground shows past it. Without the models the
			-- rings are the old smooth balls (Colour).
			Hills = {
				Count = 40,
				Radius = 156,
				Jitter = 8,
				Wide = { 30, 46 },
				Tall = { 14, 28 },
				Sink = 0.08,
				Colour = "#cfe0f2",
				Far = {
					Count = 40,
					Radius = 206,
					Jitter = 6,
					Wide = { 170, 230 },
					Tall = { 60, 76 },
					Sink = 0.12,
					Colour = "#b7c9d9",
				},
			},
			-- The heavy rock landmarks (kind `cliff`, by width; `model` an index into Models.cliff), two in the left third and
			-- two in the right third of the player's view and a smaller one near the far middle, each with Banks.PerLandmark
			-- low snow banks joining it to its neighbours and Pines snowy groves behind it. Fixed spots, x and z from the
			-- arena's middle (the camera stands at z +27 and looks toward -z, +x is right).
			Landmarks = {
				{ x = -46, z = -72, size = 24, model = 1, pines = 2 },
				{ x = -82, z = -50, size = 20, model = 2, pines = 2 },
				{ x = 46, z = -72, size = 24, model = 3, pines = 2 },
				{ x = 82, z = -50, size = 19, model = 4, pines = 2 },
				{ x = 24, z = -98, size = 16, model = 4, pines = 2 },
			},
			-- The hero crystal clusters (kind `hero`, by height; `model` an index into Models.hero), each lit (Glow): the strongest
			-- pair against the left and right landmarks, two shorter ones at the back, off the boss's line. A spot that is
			-- taken moves to the nearest free one.
			Heroes = {
				{ x = -62, z = -48, size = 15, model = 2 },
				{ x = 62, z = -50, size = 15, model = 1 },
				{ x = -26, z = -94, size = 11, model = 3 },
				{ x = 50, z = -90, size = 10, model = 4 },
			},
			-- Low snow banks (kind `bank`, by length; they stand 1 to 3 high) joining the rock groups: PerLandmark round each.
			Banks = { PerLandmark = 3, Long = { 5, 11 } },
			-- A group of 3 or 4 frosted bushes (kind `frost`, by width: they stand 2 to 4 high) in each corner, Spread studs across
			Frost = { Wide = { 3.2, 5 }, Spread = 2.4 },
			-- the snowy pines behind each landmark (kind `pine`, by height)
			PineBehind = { 11, 17 },
			-- No path is drawn; these only keep the four lanes along the axes free (the plan reads them for the tiny pieces).
			PathStyle = "none",
			PathColour = "#e8f1fa",
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
			-- The shore: Count snow drifts of Wide studs across, From to To studs out from the middle (outside the fight, under the
			-- rim's scenery).
			Mounds = { Count = 16, From = 72, To = 84, Wide = { 10, 16 } },
			-- (round 4: the crystals are no longer Neon: their cyan cores and pale tips show as painted, never blown out to white)
			Neon = {},
			NeonAlpha = {},
			-- A crystal cluster's light: the first Lights clusters of each corner (kind `glow`) carry a point light, and every hero
			-- cluster does (the colour is found by the model's name), Lift above the floor, Range studs, never a particle. Four
			-- in all (the heroes), none on the medium or the tiny ones.
			Glow = {
				Lights = { 0, 0, 0, 0 },
				Lift = 5,
				Range = 14,
				Brightness = 0.6,
				Colours = { Crystal = "#80deff" },
			},
			-- The light inside this map (client/DungeonLight eases the game's lighting to it while a run is on this map): a cool
			-- overcast day (ClockTime 8.6 under a pale cloud layer), a bluish ambient, a pale blue haze, Saturation -0.3 to cancel
			-- the place's own grade; Exposure a little under 0 so the ice-white floor keeps its stud colour instead of burning out.
			Lighting = {
				Seconds = 1.5,
				ClockTime = 8.6,
				Stars = 0,
				Brightness = 2.2,
				Exposure = -0.2,
				Ambient = "#9fb1cc",
				OutdoorAmbient = "#b0c2dc",
				AtmosphereColour = "#dfe8f0",
				AtmosphereDecay = "#bcccdd",
				AtmosphereDensity = 0.5,
				AtmosphereOffset = 0.25,
				AtmosphereHaze = 4,
				TintColour = "#e6efff",
				Saturation = -0.3,
				GradeBrightness = 0,
				GradeContrast = 0.08,
				-- an overcast winter sky: the engine's blue day sky and its clouds would read as summer (client/DungeonLight)
				Clouds = { Cover = 0.95, Density = 0.55, Colour = "#f4f8ff" },
			},
			MouthHalf = 11,
			Gap = 1.5,
			-- (round 4: the landmarks, heroes and banks are placed by hand above; a corner keeps a few small things: one bare
			-- tree (4 in all), two medium crystal clusters (8), three tiny ones (12), one group of frosted bushes (12 to 16))
			PerCorner = {
				Trees = 1,
				RockPairs = 0,
				Rocks = 2,
				Bushes = 1,
				Clumps = 0,
				Stumps = 0,
				Logs = 1,
				Ruins = 0,
				Roots = 3,
				Glows = 2,
				Frosts = 1,
			},
			MouthBehind = 8,
			MouthTreeApart = 7,
			-- (the four path mouths are closed by groves, as the lava's are by low masses)
			MouthKind = "pine",
			Tries = 160,
			-- the corners' lone trees (kind `round`, by height), 14 to 20 studs
			Round = { 14, 20 },
			-- the groves and single pines that frame the near-path sides (kind `pine`, by height): 9 to 13, about as wide as tall
			Pine = { 9, 13 },
			PineFoot = 0.55,
			-- the slate masses (kind `ruin`, by height; about twice that across)
			Ruin = { 9, 13 },
			RuinFoot = 0.9,
			RockPairFoot = 6.5,
			StumpFoot = 0.5,
			BackdropRound = { 9, 13 },
			RockBig = { 6, 9 },
			RockSmall = { 3.5, 5.5 },
			RockSingle = { 5, 9 },
			Bush = { 5, 8 },
			BackdropBush = { 12, 17 },
			Flower = { 5, 7 },
			-- stumps 4 to 6 across; logs and snow fences 7 to 11 long
			Stump = { 4, 6 },
			Log = { 7, 11 },
			Tuft = { 2.8, 4 },
			TinyFlower = { 2, 2.8 },
			TinyTuft = { 1.5, 2.1 },
			-- the floor's thin crack lines, 6 to 12 across, and its frost patches, 7 to 15 (R40 to 66)
			TinyPebble = { 6, 12 },
			TinyPatch = { 7, 15 },
			-- a tiny crystal cluster (kind `root`) is 2.2 to 3 across, 1 to 3 tall; a medium one (kind `glow`) 4 to 7 tall
			Root = { 2.2, 3 },
			GlowSize = { 4, 7 },
			GlowCount = { 1, 1 },
			GlowSpread = 2.2,
			Models = {
				-- (the bare dark trees, a few accents only)
				round = {
					"CommonTree_Dead_Snow_3_Ice",
					"CommonTree_Dead_Snow_4_Ice",
					"Willow_Dead_Snow_1_Ice",
					"Willow_Dead_Snow_3_Ice",
					"Willow_Dead_Snow_4_Ice",
				},
				-- the hills' rings (Hills, Hills.Far): faceted snow ridges and the far land; the heavy rock landmarks (Landmarks),
				-- the hero crystal clusters (Heroes), the low snow banks (Banks), the frosted bushes (Frost), the floor's frost
				-- patches (TinyPatches)
				ridge = { "IceRidge_1", "IceRidge_2", "IceRidge_3", "IceRidge_4", "IceRidge_5" },
				far = { "IceFar_1", "IceFar_2", "IceFar_3" },
				cliff = { "IceCliff_1", "IceCliff_2", "IceCliff_3", "IceCliff_4" },
				hero = { "IceCrystalHero_1", "IceCrystalHero_2", "IceCrystalHero_3", "IceCrystalHero_4" },
				bank = { "IceBank_1", "IceBank_2", "IceBank_3", "IceBank_4" },
				frost = { "IceFrostBush_1", "IceFrostBush_2", "IceFrostBush_3" },
				patch = { "IcePatch_1", "IcePatch_2", "IcePatch_3" },
				pine = {
					"IceGrove_1",
					"IceGrove_2",
					"IceGrove_3",
					"IceGrove_4",
					"PineTree_Snow_2_Ice",
					"PineTree_Snow_5_Ice",
				},
				rock = {
					"IceBoulder_1",
					"IceBoulder_2",
					"IceBoulder_3",
					"Rock_Snow_1_Ice",
					"Rock_Snow_3_Ice",
					"Rock_Snow_4_Ice",
					"Rock_Snow_5_Ice",
					"Rock_Snow_6_Ice",
				},
				ruin = { "IceRock_1", "IceRock_2", "IceRock_3", "IceRock_4" },
				root = { "IceCrystalSmall_1", "IceCrystalSmall_2", "IceCrystalSmall_3" },
				glow = { "IceCrystalMid_1", "IceCrystalMid_2", "IceCrystalMid_3" },
				bush = { "Bush_Snow_1_Ice", "Bush_Snow_2_Ice", "IceShrub_1", "IceShrub_2" },
				stump = { "TreeStump_Snow_Ice" },
				log = { "WoodLog_Snow_Ice", "IceFence_1", "IceFence_2", "IceFence_3" },
				tuft = { "IceSprig_1", "IceSprig_2", "IceSprig_3" },
				pebble = { "IceCrack_1", "IceCrack_2", "IceCrack_3", "IceCrack_4" },
				mound = { "IceMound_1", "IceMound_2", "IceMound_3", "IceMound_4" },
				flower = {},
			},
			Fallback = {
				round = { "QtDeadTree_1", "QtDeadTree_3", "QtDeadTree_5" },
				pine = { "QtPine_1", "QtPine_5" },
				rock = { "QtRock_Medium_1", "QtRock_Medium_2", "QtRock_Medium_3" },
				ruin = {},
				root = {},
				glow = {},
				bush = {},
				stump = {},
				log = {},
				tuft = {},
				pebble = { "QtPebble_Round_1", "QtPebble_Square_2" },
				mound = {},
				flower = {},
				-- (round 4: a kind whose models are not in the library yet is simply left out, and the hills are the smooth balls)
				ridge = {},
				far = {},
				cliff = {},
				hero = {},
				bank = {},
				frost = {},
				patch = {},
			},
			-- (the library props carry their own colours in vertex colour, so nothing is tinted)
			Tints = {},
			BackdropTints = {},
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
			lavastomp = "#c8501e",
			eruption = "#8a2a1a",
			tuskcharge = "#d8e4f0",
			blizzard = "#9fcff0",
		},
		Sizes = { normal = 3, armoured = 4, miniboss = 7, boss = 10 },
	},
	-- Each monster's look: its monster slime (docs/MONSTER-SLIMES.md), the owner's 3D model split, rigged and given its
	-- moves in Blender (tools/blender/monster_rig*.py, art/models/monster_slimes/<region>/), uploaded
	-- (tools/kit/upload_monsters.js, ids.json): `clips` names its moves (shared/MonsterClips/<Name>, played by
	-- client/ClipRig), `mesh` and `texture` its asset ids, `height` how tall it stands in studs (as it was built; a floater's
	-- hover is in its moves), `shadow` for the mini-bosses and bosses, `turn` the degrees it is turned about its height so
	-- its face looks where it goes (a few models came turned, as the concept pictures were three-quarter views; + brings a
	-- face that looks to its left to the front). A look may instead name an Egg Heist creature
	-- (`model` in ReplicatedStorage.MonsterKit moved by its `motion` module, shared/Creatures and client/CreatureRig, with
	-- `hover`, `bob` and `bobHz` for a flyer) or `pieces` (rigid pieces turned about their joints, shared/MonsterMotion).
	-- Every look's `height` (and its hover) is drawn this many times bigger: the monsters read small beside the 3-stud
	-- slimes in a fight at the player's camera (2026-11-09). `Big` is for the looks with `shadow` (minibosses and
	-- bosses), which are already tall.
	-- `fx`: the effects on its body where the owner's painting had them (the owner, 2026-11-11: fire on the Lava ones,
	-- poison bubbles or smoke on the toxic ones, only where it is needed; docs/MONSTER-SLIMES.md): each a VFX library
	-- `effect` (and `variant`) on an invisible box of `size` studs as built that rides the `bone`, `at` studs as built from
	-- the bone's rest point (in the model's axes as built), client/ClipRig.anchor.
	LookScale = { Normal = 1.35, Big = 1.15 },
	Looks = {
		-- Sunny Meadow's
		green_sprout = { clips = "Burrling", mesh = 137807217575397, texture = 138681763611567, height = 4.4 },
		green_bee = { clips = "Stinglob", mesh = 113014346736172, texture = 75158359280374, height = 3.6 },
		green_dandelion = { clips = "Gapebloom", mesh = 93569552469358, texture = 135413526793030, height = 4.2 },
		green_moth = {
			clips = "Sapcaller",
			mesh = 120737224081437,
			texture = 71772462336332,
			height = 3.8,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "sapcaller",
					bone = "Stalk3",
					at = { -0.2, 0.6, 0.2 },
					size = 2.6,
				},
			},
		},
		green_snail = { clips = "Barkhide", mesh = 140178248884285, texture = 102872532900531, height = 4.6 },
		green_turtle = {
			clips = "Rotbloom",
			mesh = 93464689205170,
			texture = 138165822750225,
			height = 8,
			shadow = true,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "rotbloom",
					bone = "Flower",
					at = { 0, 0.6, 0 },
					size = 5,
				},
			},
		},
		green_boar = {
			clips = "Bramblehorn",
			mesh = 123517482780418,
			texture = 113411905560648,
			height = 10,
			shadow = true,
		},
		-- the Mushroom Grove's
		dark_hare = { clips = "Gloomtick", mesh = 81502541674019, texture = 112116342243841, height = 4.4 },
		dark_bat = {
			clips = "Glimlure",
			mesh = 74320947597347,
			texture = 75204701729024,
			height = 3.6,
			turn = 57,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "glimlure",
					bone = "Lure2",
					at = { 0.5, 0.35, -0.12 },
					size = 1,
				},
			},
		},
		dark_fox = {
			clips = "Bilebloat",
			mesh = 101371378759876,
			texture = 108421618690524,
			height = 4.2,
			turn = -20,
			fx = {
				{ effect = "aura.monster_signature", variant = "bilebloat", bone = "Body", at = { 0, 1, 0 }, size = 4 },
			},
		},
		dark_deer = {
			clips = "Hexcap",
			mesh = 123670007933216,
			texture = 137125937387984,
			height = 3.8,
			fx = {
				{ effect = "aura.monster_signature", variant = "hexcap", bone = "Cap", at = { 0, 0.4, 0 }, size = 3.5 },
			},
		},
		dark_totem = { clips = "Ruingut", mesh = 106841847934251, texture = 105872266930309, height = 4.6 },
		dark_wyrm = {
			clips = "Sporegorge",
			mesh = 92941475092637,
			texture = 131395010003057,
			height = 8,
			shadow = true,
			fx = {
				{ effect = "aura.monster_signature", variant = "sporegorge", bone = "Top", at = { 0, 1, 0 }, size = 6 },
			},
		},
		dark_bear = {
			clips = "Hollowheart",
			mesh = 80922916527388,
			texture = 102830187428765,
			height = 10,
			shadow = true,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "hollowheart",
					bone = "Crown",
					at = { 0, 2.5, 0 },
					size = 9,
				},
			},
		},
		-- Ember Lava's
		lava_newt = {
			clips = "Wickling",
			mesh = 107835269091363,
			texture = 79020227671379,
			height = 4.4,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "wickling",
					bone = "Wick2",
					at = { -0.46, 0.42, 0.15 },
					size = 1.2,
				},
			},
		},
		lava_wolf = {
			clips = "Scorchdart",
			mesh = 79283961500273,
			texture = 139885960871598,
			height = 3.6,
			turn = 30,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "scorchdart",
					bone = "Spine3",
					at = { 0, 0.25, 0 },
					size = 2.5,
				},
			},
		},
		lava_phoenix = {
			clips = "Blazegullet",
			mesh = 119982999618894,
			texture = 79027366845168,
			height = 4.2,
			turn = -15,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "blazegullet",
					bone = "Top",
					at = { 0, -0.3, -0.9 },
					size = 2,
				},
			},
		},
		lava_drake = {
			clips = "Pyrekeeper",
			mesh = 99465572241029,
			texture = 133586105790685,
			height = 3.8,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "pyrekeeper",
					bone = "Brazier",
					at = { 0, 0.7, -0.3 },
					size = 2,
				},
			},
		},
		lava_tortoise = { clips = "Basaltback", mesh = 124537289602580, texture = 102905861327564, height = 4.6 },
		lava_bull = {
			clips = "Magmaw",
			mesh = 84598397307019,
			texture = 101694948132599,
			height = 8,
			shadow = true,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "magmaw",
					bone = "Jaw",
					at = { 0, 0.6, -2.3 },
					size = 4,
				},
			},
		},
		lava_golem = {
			clips = "Calderos",
			mesh = 119811024837186,
			texture = 115472744044897,
			height = 10,
			shadow = true,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "calderos",
					bone = "Mane2",
					at = { -1.2, 0.3, 1.7 },
					size = 8,
				},
			},
		},
		-- Frozen Ice's (the Frostmaw is dark so that it reads on the white floor)
		ice_fox = { clips = "Frostnip", mesh = 87406578571606, texture = 137195367943596, height = 4.4 },
		ice_leopard = { clips = "Rimesaw", mesh = 113370508274803, texture = 134755381308207, height = 3.6 },
		ice_wisp = { clips = "Shardspire", mesh = 93910658403605, texture = 113839119156842, height = 4.2 },
		ice_penguin = {
			clips = "Snowshroud",
			mesh = 134787401494105,
			texture = 113926521902131,
			height = 3.8,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "snowshroud",
					bone = "Body",
					-- (the anchor's bottom on the ground: its mist curls round the hem)
					at = { 0, 1.5, 0 },
					size = 4,
				},
			},
		},
		ice_golem = { clips = "Icebound", mesh = 129447292939570, texture = 91773709005563, height = 4.6 },
		ice_mammoth = {
			clips = "Rimetusk",
			mesh = 135170060162540,
			texture = 99482423322194,
			height = 8,
			shadow = true,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "rimetusk",
					bone = "Front",
					at = { 0.3, 1.1, -0.4 },
					size = 3.5,
				},
			},
		},
		ice_yeti = {
			clips = "Frostmaw",
			mesh = 70916405343821,
			texture = 114276870471488,
			height = 10,
			shadow = true,
			fx = {
				{
					effect = "aura.monster_signature",
					variant = "frostmaw",
					bone = "Body",
					-- (the anchor's bottom on the ground: its snow whirls round the base)
					at = { 0, 3.2, 0 },
					size = 11,
				},
			},
		},
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
		-- The arena HUD: the plate at the top (wave, level, monsters left), the drops row along the bottom edge, the Leave
		-- button at the right edge.
		PlateWidth = 236,
		PlateHeight = 40,
		PlateWave = 88,
		PlateLevel = 48,
		PlateLeft = 34,
		DropsWidth = 360,
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
			-- Ember Lava's two bosses have a way of their own (their blows, steps and skill art in Config.Zombies.View)
			lavastomp = "lavastomp",
			eruption = "eruption",
			-- Frozen Ice's two bosses have a way of their own too
			tuskcharge = "tuskcharge",
			blizzard = "blizzard",
		},
		-- A monster's burst when it falls grows with its size, up to this many times a plain one's.
		DeathBigness = 2,
		-- A healer's mending: the picture over the one healed (studs across).
		HealBurst = 4,
		HealColour = "Green",
		-- A monster slime healer's own healing move peaks this many seconds after the mending shows.
		ClipHealLead = 0.15,
		-- How often the portal prompts are looked at.
		GateWatchSeconds = 1,
	},

	-- ===== Fight effects by monster (client/ZombieFight with src/shared/VfxLib; design: docs/DUNGEON_MAPS.md) =====
	-- Each monster's own looks from the owner's VFX library, themed to its map (the owner, 2026-11-09): `blow` plays on
	-- the one it hits (and, for a ranged one, `shot` flies there first: the same effect with its projectile), `fall` is
	-- its burst when it falls (that effect's FallVariant), a healer's `heal` plays over the one it mends, and each of its
	-- specials (`skills`, by the key in Skills above) has its wind-up on the caster when the special is called, its release
	-- (`at`: on the caster's feet, on the target with the caster as `from`, or rising straight up from the caster) when it
	-- comes down (a wall's and a mend's on the caster), and its blows land as the blow's SkillVariant. A special's `variant`
	-- names its own look in both its wind-up and its release (skill.monster_windup and skill.monster_special have one
	-- variant per special; a regular's special has no wind-up). A monster left out keeps the battle art of its kind
	-- (Ways). The slimes' own blows and the village zombies never use these.
	Fx = {
		FallVariant = "death",
		SkillVariant = "skill",
		-- a blow, shot and fall are drawn this many times bigger per step of the monster's size, up to MaxScale
		Scale = 1,
		MaxScale = 2.2,
		-- how long a shot flies before its blow lands (the library's projectiles fly about this long)
		ShotSeconds = 0.3,
		-- the height of the box the monsters' hit effects were made for (their refHeight): a fall stands it on the ground
		FallBox = 4,
		-- a wind-up fades out this softly when its skill goes off
		WindupFade = 0.15,
		-- A boss's and a mini-boss's special (one with a `windup` and wind-up art) hits like a burst (the owner, 2026-11-12: drama like
		-- Genshin Impact's, still no camera): all through its wind-up a mark on the ground shows where it comes down
		-- (skill.monster_mark, the monster's `element` as its variant; MarkWide times wider round the caster for a special
		-- that comes down there) and its body glows its element's Glow colour, up to GlowMost (1 = none) as the wind-up
		-- ends; as it goes off the body flashes (FlashFill) and skill.monster_impact (the same variant) flares and marks the
		-- ground under the release; each body it strikes freezes HitStopSeconds (a plain blow: View.HitStopSeconds) and
		-- flashes white (HitFlash), both fading over FlashSeconds.
		Burst = {
			MarkWide = 2,
			Glow = { meadow = "#9fe05a", grove = "#b48cff", lava = "#ff8c32", ice = "#6ab4ff" },
			GlowMost = 0.6,
			FlashFill = 0.3,
			HitStopSeconds = 0.18,
			HitFlash = 0.35,
			FlashSeconds = 0.22,
		},
		-- A regular monster's attacking special (one with a `windup` but no wind-up art of its own) pops, a step below a
		-- burst so the bosses still stand out: its body glows its element's Burst.Glow colour up to GlowMost through the
		-- shorter wind-up and flashes as it lets go; its first blow on the one it aims at plays hit.monster_pop (the
		-- element as its variant) over the blow and freezes that body HitStopSeconds with a white flash (HitFlash).
		Pop = {
			GlowMost = 0.65,
			HitStopSeconds = 0.12,
			HitFlash = 0.55,
		},
		Monsters = {
			-- Meadow: leaves, wind, pollen, earth
			green_sprout = { blow = "hit.green_sprout", fall = "hit.green_sprout", element = "meadow" },
			green_bee = { blow = "hit.green_bee", fall = "hit.green_bee", element = "meadow" },
			green_dandelion = {
				blow = "hit.green_dandelion",
				shot = true,
				fall = "hit.green_dandelion",
				element = "meadow",
			},
			green_moth = {
				blow = "hit.green_moth",
				heal = "burst.moth_mend",
				fall = "hit.green_moth",
				skills = {
					bloom_mend = { release = "skill.monster_special", at = "caster", variant = "bloom_mend" },
				},
			},
			green_snail = {
				blow = "hit.green_snail",
				fall = "hit.green_snail",
				skills = {
					bark_wall = { release = "skill.monster_special", at = "caster", variant = "bark_wall" },
				},
			},
			green_turtle = {
				blow = "hit.green_turtle",
				fall = "hit.green_turtle",
				element = "meadow",
				skills = {
					bloomshell = { windup = "skill.renewal_charge", release = "skill.pollen_shockwave", at = "caster" },
					root_snare = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "root_snare",
					},
				},
			},
			green_boar = {
				blow = "hit.green_boar",
				fall = "hit.green_boar",
				element = "meadow",
				skills = {
					bramblehorn = { windup = "skill.bramble_rage", release = "burst.rock_smash", at = "target" },
					bramble_burst = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "caster",
						variant = "bramble_burst",
					},
					horn_toss = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "horn_toss",
					},
				},
			},
			-- Mushroom: spores, toxic, violet arcane
			dark_hare = { blow = "hit.dark_hare", fall = "hit.dark_hare", element = "grove" },
			dark_bat = { blow = "hit.dark_bat", fall = "hit.dark_bat", element = "grove" },
			dark_fox = {
				blow = "hit.dark_fox",
				shot = true,
				fall = "hit.dark_fox",
				element = "grove",
				skills = {
					acid_splash = { release = "skill.monster_special", at = "target", variant = "acid_splash" },
				},
			},
			dark_deer = {
				blow = "hit.dark_deer",
				heal = "burst.deer_mend",
				fall = "hit.dark_deer",
				skills = {
					hex_mend = { release = "skill.monster_special", at = "caster", variant = "hex_mend" },
				},
			},
			dark_totem = {
				blow = "hit.dark_totem",
				fall = "hit.dark_totem",
				skills = {
					rune_ward = { release = "skill.monster_special", at = "caster", variant = "rune_ward" },
				},
			},
			dark_wyrm = {
				blow = "hit.dark_wyrm",
				fall = "hit.dark_wyrm",
				element = "grove",
				skills = {
					sporeburst = { windup = "skill.void_charge", release = "skill.spore_burst", at = "caster" },
					gorge_bite = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "gorge_bite",
					},
				},
			},
			dark_bear = {
				blow = "hit.dark_bear",
				fall = "hit.dark_bear",
				element = "grove",
				skills = {
					bearslam = {
						windup = "skill.umbral_growl",
						release = "skill.leap_slam",
						variant = "lv2",
						at = "caster",
					},
					root_grasp = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "caster",
						variant = "root_grasp",
					},
					heart_pulse = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "caster",
						variant = "heart_pulse",
					},
				},
			},
			-- Lava: fire, magma, explosions
			lava_newt = {
				blow = "hit.lava_newt",
				fall = "hit.lava_newt",
				element = "lava",
				skills = {
					flare_pop = { release = "skill.monster_special", at = "target", variant = "flare_pop" },
				},
			},
			lava_wolf = { blow = "hit.lava_wolf", fall = "hit.lava_wolf", element = "lava" },
			lava_phoenix = {
				blow = "hit.lava_phoenix",
				shot = true,
				fall = "hit.lava_phoenix",
				element = "lava",
				skills = {
					fireball = { release = "skill.monster_special", at = "target", variant = "fireball" },
				},
			},
			lava_drake = {
				blow = "hit.lava_drake",
				heal = "burst.drake_mend",
				fall = "hit.lava_drake",
				skills = {
					pyre_mend = { release = "skill.monster_special", at = "caster", variant = "pyre_mend" },
				},
			},
			lava_tortoise = {
				blow = "hit.lava_tortoise",
				fall = "hit.lava_tortoise",
				skills = {
					basalt_wall = { release = "skill.monster_special", at = "caster", variant = "basalt_wall" },
				},
			},
			lava_bull = {
				blow = "hit.lava_bull",
				fall = "hit.lava_bull",
				element = "lava",
				skills = {
					lavastomp = { windup = "skill.meteor_charge", release = "skill.meteor_crash", at = "caster" },
					molten_chomp = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "molten_chomp",
					},
				},
			},
			lava_golem = {
				blow = "hit.lava_golem",
				fall = "hit.lava_golem",
				element = "lava",
				skills = {
					eruption = { windup = "skill.phoenix_charge", release = "skill.flame_jet", at = "up" },
					mane_lash = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "mane_lash",
					},
					meteor_rain = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "meteor_rain",
					},
				},
			},
			-- Ice: frost, snow, crystal shards
			ice_fox = { blow = "hit.ice_fox", fall = "hit.ice_fox", element = "ice" },
			ice_leopard = { blow = "hit.ice_leopard", fall = "hit.ice_leopard", element = "ice" },
			ice_wisp = {
				blow = "hit.ice_wisp",
				shot = true,
				fall = "hit.ice_wisp",
				element = "ice",
				skills = {
					crystal_burst = { release = "skill.monster_special", at = "target", variant = "crystal_burst" },
				},
			},
			ice_penguin = {
				blow = "hit.ice_penguin",
				heal = "burst.penguin_mend",
				fall = "hit.ice_penguin",
				skills = {
					frost_mend = { release = "skill.monster_special", at = "caster", variant = "frost_mend" },
				},
			},
			ice_golem = {
				blow = "hit.ice_golem",
				fall = "hit.ice_golem",
				skills = {
					ice_wall = { release = "skill.monster_special", at = "caster", variant = "ice_wall" },
				},
			},
			ice_mammoth = {
				blow = "hit.ice_mammoth",
				fall = "hit.ice_mammoth",
				element = "ice",
				skills = {
					tuskcharge = { windup = "skill.frost_charge", release = "skill.ice_spear", at = "target" },
					frost_breath = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "frost_breath",
					},
				},
			},
			ice_yeti = {
				blow = "hit.ice_yeti",
				fall = "hit.ice_yeti",
				element = "ice",
				skills = {
					blizzard = { windup = "skill.frost_howl", release = "skill.blizzard", at = "caster" },
					glacier_gore = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "glacier_gore",
					},
					frost_gale = {
						windup = "skill.monster_windup",
						release = "skill.monster_special",
						at = "target",
						variant = "frost_gale",
					},
				},
			},
		},
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
