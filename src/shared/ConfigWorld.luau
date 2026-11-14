--!strict
-- The fights of the big world (docs/WORLD.md §7, M5): every zone of WorldPlan.Zones is a short fight in the open, on the
-- zone's own pad, by the Slime Dungeon's rules (shared/Dungeon; the run is server/Dungeon's). A zone sends a few waves; a
-- wave is the Dungeon's crowd of that wave number on the zone's map, or one named monster alone. The last wave is always
-- one monster: the zone's guard. The rules are shared/ZoneFights. Read as Config.World.
return {
	-- The workspace folders the server makes: the prompt anchor of every zone, the seal of every gate of the Heart.
	Folder = "ZoneGuards",
	GateFolder = "ZoneGates",
	-- A player's attribute of a zone, "Zone_<id>": the server time (os.time) of their last win there, 0 for never.
	Attribute = "Zone_",
	-- The prompt of a zone hangs AnchorLift above the middle of its fight and answers from PromptRangeStuds.
	PromptRangeStuds = 18,
	AnchorLift = 4,
	-- The fight keeps to the flat middle of the pad (the rocks of a pad's rim begin near 60 studs): monsters come in
	-- SpawnInner..SpawnOuter from the middle and nobody fights farther out than FightRadius.
	FightRadius = 48,
	SpawnInner = 30,
	SpawnOuter = 44,
	-- Seconds a zone rests, for the player who won it, before they may fight it again; by the zone's kind.
	Rest = { mini = 300, boss = 900, mega = 1800 },
	-- The gate of the Heart (WorldPlan.Sites id) each boss zone opens for the player who won it.
	Gates = { gate_w = "b1", gate_e = "b2", gate_n = "b3" },
	-- A gate's seal: an unseen wall across the arch until its boss is won. Studs; Lift = its foot above the gate's ground.
	-- The lock picture hangs LockHeight above the ground, LockPixels wide, seen from LockShowStuds.
	Seal = { Width = 52, Height = 60, Depth = 8, Lift = -4, LockHeight = 14, LockPixels = 96, LockShowStuds = 260 },
	-- What a zone's guard pays when it falls, by the zone's kind, in place of its own drops (the Dungeon's bosses pay
	-- trophies that a short fight may not hand out every few minutes). Lines as a monster's drops (item, chance, min..max).
	-- "trophy" is the region's own (Trophy below; a region without one pays none). Coins are multiplied by
	-- 1 + CoinsPerTier x (tier - 1). Every other monster of a zone drops what its def says, at luck 1.
	Reward = {
		mini = {
			{ item = "coins", chance = 1, min = 10, max = 16 },
			{ item = "ore", chance = 1, min = 1, max = 2 },
			{ item = "rare_part", chance = 0.5, min = 1, max = 1 },
			{ item = "monster_core", chance = 0.15, min = 1, max = 1 },
		},
		boss = {
			{ item = "coins", chance = 1, min = 30, max = 45 },
			{ item = "rare_part", chance = 1, min = 2, max = 3 },
			{ item = "monster_core", chance = 1, min = 1, max = 1 },
			{ item = "boss_essence", chance = 0.5, min = 1, max = 1 },
			{ item = "trophy", chance = 1, min = 2, max = 2 },
		},
		mega = {
			{ item = "coins", chance = 1, min = 80, max = 120 },
			{ item = "monster_core", chance = 1, min = 2, max = 3 },
			{ item = "boss_essence", chance = 1, min = 2, max = 2 },
		},
	},
	CoinsPerTier = 0.25,
	Trophy = { meadow = "boar_tusk", mushroom = "glow_spore", ember = "ember_core", frost = "frost_fang" },
	-- The zones, by their WorldPlan id.
	--   map     the Config.Dungeon.Maps id its crowds are drawn from
	--   level   the dungeon level its monsters are scaled to (HP and attack x LevelPower ^ (level - 1); it need not be whole).
	--           Set with tools/balance/zone_sim.luau so that four even slimes of the level in the comment win about three
	--           fights in four.
	--   waves   in order. { wave = n }: the Dungeon's crowd of wave n (never the Dungeon's own boss waves, 5 and 10).
	--           { wave = n, guard = id }: that monster alone, as strong as in wave n; `power` multiplies its HP and attack
	--           once more (a common monster standing guard). Wave numbers rise within a zone (monster ids are made of them).
	--   needs   zones that must be won first
	--   offset  the middle of the fight, studs from the zone's middle (x east, z south), where the pad's middle is not flat
	Zones = {
		-- the Meadow
		m1 = { map = "meadow", level = 0.55, waves = { { wave = 2 }, { wave = 3, guard = "green_boar" } } }, -- team 6
		m2 = { map = "meadow", level = 2.55, waves = { { wave = 2 }, { wave = 3, guard = "green_turtle" } } }, -- team 10
		-- the Mushroom Grove
		m3 = { map = "mushroom", level = 3.2, waves = { { wave = 2 }, { wave = 3, guard = "dark_wyrm" } } }, -- team 14
		m4 = { map = "mushroom", level = 4.45, waves = { { wave = 2 }, { wave = 3, guard = "dark_deer", power = 4 } } }, -- team 18
		b1 = {
			map = "mushroom",
			level = 2.2,
			waves = { { wave = 4 }, { wave = 6, guard = "dark_wyrm" }, { wave = 7, guard = "dark_bear" } },
		}, -- team 22
		-- the Ember Wastes
		m5 = { map = "lava", level = 3.75, waves = { { wave = 3 }, { wave = 4, guard = "lava_bull" } } }, -- team 26
		m6 = { map = "lava", level = 3.85, waves = { { wave = 3 }, { wave = 4, guard = "lava_tortoise", power = 4 } } }, -- team 30
		b2 = {
			map = "lava",
			level = 2.95,
			waves = { { wave = 4 }, { wave = 6, guard = "lava_bull" }, { wave = 7, guard = "lava_golem" } },
		}, -- team 34
		-- the far corners
		m7 = { map = "mushroom", level = 4.2, waves = { { wave = 4 }, { wave = 6, guard = "dark_totem", power = 4 } } }, -- team 38
		m8 = { map = "lava", level = 4.6, waves = { { wave = 4 }, { wave = 6, guard = "lava_phoenix", power = 4 } } }, -- team 42
		-- the Frost Peaks
		m9 = { map = "ice", level = 3.85, waves = { { wave = 4 }, { wave = 6, guard = "ice_golem", power = 4 } } }, -- team 46
		m10 = { map = "ice", level = 4.35, waves = { { wave = 4 }, { wave = 6, guard = "ice_mammoth" } } }, -- team 50
		b3 = {
			map = "ice",
			level = 3.7,
			waves = { { wave = 4 }, { wave = 6, guard = "ice_mammoth" }, { wave = 7, guard = "ice_yeti" } },
			-- (a mound fills the pad's south-west)
			offset = { x = 0, z = -30 },
		}, -- team 54
		-- The Heart. King Goo has no model yet (docs/WORLD.md §5): until he does, the four region bosses hold it in turn.
		heart = {
			map = "ice",
			level = 3.8,
			waves = {
				{ wave = 3, guard = "green_boar" },
				{ wave = 4, guard = "dark_bear" },
				{ wave = 6, guard = "lava_golem" },
				{ wave = 7, guard = "ice_yeti" },
			},
			needs = { "b1", "b2", "b3" },
		}, -- team 60
	},
}
