--!strict
-- The fights of the big world (docs/WORLD.md §7, M5): every zone of WorldPlan.Zones is a short fight in the open, on the
-- zone's own pad, by the Slime Dungeon's rules (shared/Dungeon; the run is server/Dungeon's). A zone sends a few waves; a
-- wave is the Dungeon's crowd of that wave number on the zone's map, or one named monster alone. The last wave is always
-- one monster: the zone's guard. The rules are shared/ZoneFights. Read as Config.World.
return {
	-- How fast a player walks, studs a second (the owner, 2026-11-14: twice Roblox's own 16; the world is big).
	WalkSpeed = 32,
	-- Day and night (the owner, 2026-11-15; client/DayNight). The clock runs from the server's time, so every player and
	-- server sees the same hour: 06:00 to 18:00 takes DayMinutes, 18:00 to 06:00 NightMinutes. Night falls between
	-- DuskFrom and DuskTo and lifts between DawnFrom and DawnTo (hours); at full night the place's own light eases to Night
	-- (hex colours; Brightness and the Atmosphere's Color and Decay). Back from a Dungeon map with a light of its own, the
	-- clock eases in over BlendSeconds.
	DayNight = {
		DayMinutes = 10,
		NightMinutes = 4,
		DuskFrom = 17.6,
		DuskTo = 19.2,
		DawnFrom = 4.8,
		DawnTo = 6.6,
		BlendSeconds = 3,
		Night = {
			Brightness = 1.2,
			Ambient = "3c4878",
			OutdoorAmbient = "4a5a96",
			AtmosphereColour = "28304e",
			AtmosphereDecay = "1c2440",
		},
	},
	-- The world's fires and lamps (client/WorldLights). Torches burn by day and night with the VFX library's Fire, on an
	-- unseen anchor FireHeight studs tall whose foot stands FireAt of the torch's height up (the flame sets its size by the
	-- anchor). Lamps light up when the night is at least LampsOnAt (0 day, 1 full night): their lights switch on and their
	-- head glows (Glow, on an unseen anchor `size` studs wide `at` of the lamp's height up from its foot, in the lamp's
	-- `colour`: their glass is part of the mesh and cannot light up itself); a lamp with no light of its own gets one
	-- there, LampLight. By day their lights are off and the glow goes.
	Lights = {
		Torches = { "TorchSconce" },
		Fire = "aura.cghow_toon_campfire",
		FireAt = 0.74,
		FireHeight = 1.8,
		LampsOnAt = 0.35,
		Glow = "aura.lamp_glow",
		Lamps = {
			VillageLamp = { at = 0.85, size = 1, colour = "ffc878" },
			CrystalLantern = { at = 0.72, size = 1.6, colour = "6ef0e1" },
			WoodLantern = { at = 0.5, size = 0.9, colour = "ffc878" },
		},
		LampLight = { Brightness = 1.2, Range = 10 },
	},
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
	-- The Heart's rim is closed to climbers (the owner, 2026-11-14: he walked in over the mountain): an unseen wall along
	-- the crest (WorldPlan.Heart.RimRadius), Height studs tall from Sink below the gates' ground, in pieces no longer than
	-- SegmentStuds, open only where the three seals stand (and closed again above each seal).
	RimWall = { Folder = "HeartRim", Height = 600, Sink = 30, Depth = 8, SegmentStuds = 40 },
	-- ===== The packs: the monsters of the open world (docs/WORLD.md §8; rules in shared/WorldPacks) =====
	-- Packs of SizeMin..SizeMax monsters stand all over the world, each at a level of its own that never changes: LevelMin
	-- within NearStuds of a village's middle, LevelMax from FarStuds on, rising between by (share of the way) ^ Curve.
	-- FarStuds is how far the farthest pack that really stands is from every village (the server's line "zombies: N packs
	-- out ... the farthest F studs" says it; farther spots are the rim's slopes, where none stands): set it again after
	-- the plan or the ground changes, then run tools/world/map_picture.ps1. A pack's monsters are the common ones of its
	-- region's Dungeon map (Maps, by WorldPlan region). The world is read in bands of BandLevels levels ("Lv 1-20",
	-- "Lv 20-40" ...), each with its colour on the map.
	Packs = {
		LevelMin = 4,
		LevelMax = 150,
		NearStuds = 300,
		FarStuds = 2420,
		Curve = 1.6,
		BandLevels = 20,
		BandColours = { "#7ee06a", "#c9e04c", "#ffd23c", "#ffa63c", "#ff7a4a", "#f2507a", "#c05cf0", "#7a6cff" },
		-- Where: one pack to a cell of GridStuds, moved up to JitterStuds off the cell's middle (the same every time); a
		-- spot is tried again up to Tries times when it lands in water, on a slope (the ground's normal under MinNormalY),
		-- on something built, or too near a place. Clear studs kept from: the world's rim, a village's edge, the hub's
		-- edge, a zone's edge, the foot of the Heart, any other site's edge (a place's edge is its WorldPlan radius).
		GridStuds = 280,
		JitterStuds = 90,
		Tries = 4,
		MinNormalY = 0.92,
		RimClear = 150,
		VillageClear = 50,
		HubClear = 60,
		ZoneClear = 40,
		HeartClear = 40,
		SiteClear = 30,
		SizeMin = 3,
		SizeMax = 5,
		-- A monster's stats against an even slime of the pack's level (every stat the same share, as a slime's level is
		-- counted), and the coins it pays at level 0 by its role (raised by its level as a slime's sale is). At 0.85 four
		-- even slimes of a pack's level beat four monsters about 87 times in 100 (tools/balance/fight_sim.luau).
		StatFactor = 0.85,
		CoinBase = { swarmer = 100, raider = 150, spitter = 150, shaman = 200, armoured = 300 },
		Maps = { vale = "meadow", meadow = "meadow", mushroom = "mushroom", ember = "lava", frost = "ice" },
		-- A team sets out at most this far from its pack, on the pack's side towards the player's village (a march from
		-- the gate itself would take minutes across the world), and comes back to the same spot.
		MarchMostStuds = 60,
	},
	-- ===== The waystones: teleport points (docs/WORLD.md §8) =====
	-- One stands beside every zone's pad (OutStuds from the fight's middle, towards the hub) and one inside every
	-- village's gate (across the path from the team banner, HomeAcross and HomeIn from the gate: a spot clear of the
	-- village's bushes and lamps at every village level looked at, 1 and 16). A zone's waystone opens for a
	-- player who has won that zone. A player travels from anywhere to an open waystone by quick travel's rules
	-- (server/QuickTravel: Home and the Market are always open) and lands ArriveStuds from it, towards the pad. The stone's
	-- anchor hangs Lift over the ground; its prompt answers from PromptRangeStuds.
	Waystones = {
		Folder = "Waystones",
		LookFolder = "WaystoneLooks",
		-- (at 54 every stone stands 5 studs or more clear of its pad's rim rocks; at 58 three touched one)
		OutStuds = 54,
		ArriveStuds = 7,
		HomeAcross = -11,
		HomeIn = 14,
		Lift = 3,
		PromptRangeStuds = 14,
		-- Its look (server/Waystone): the Dungeon Portal's side pillar at Scale of the portal's full size (the pillar and
		-- its crystal stand about 15 studs at 1), one glyph of the portal's rune sheet (Runes, RuneStuds wide) RuneHeight
		-- over the foot and RuneOut in front of the pillar's middle, the crystal's light and its motes a second.
		Look = {
			Scale = 0.7,
			Runes = 81706490345447,
			RuneStuds = 3,
			RuneHeight = 5.6,
			RuneOut = 2.4,
			LightRange = 10,
			LightBrightness = 0.8,
			MotesRate = 3,
		},
	},
	-- ===== The map (client/UiMap) =====
	-- Its picture is drawn from WorldPlan by tools/world/map_picture.ps1 (art/map/world_map.png): a square of Size studs
	-- whose north-west corner is (MinX, MinZ) in the plan's coordinates. Run the tool again after the plan changes.
	Map = { Image = 110309697818054, MinX = -2300, MinZ = -2500, Size = 4600 },
	-- What a zone's guard pays when it falls, by the zone's kind, in place of its own drops (the Dungeon's bosses pay
	-- trophies that a short fight may not hand out every few minutes). Lines as a monster's drops (item, chance, min..max).
	-- "trophy" is the region's own (Trophy below; a region without one pays none). Coins are what the guard pays at
	-- level 0, raised by the zone's level as a pack monster's are (x 1 + level x Config.Economy.SellLevelStep): a mini
	-- guard pays about what two or three packs round it do, a boss three times that (the owner, 2026-11-14: the guards'
	-- coins match their new levels; they were 10-120 before). Every other monster of a zone drops what its def says,
	-- at luck 1.
	Reward = {
		mini = {
			{ item = "coins", chance = 1, min = 1000, max = 1600 },
			{ item = "ore", chance = 1, min = 1, max = 2 },
			{ item = "rare_part", chance = 0.5, min = 1, max = 1 },
			{ item = "monster_core", chance = 0.15, min = 1, max = 1 },
		},
		boss = {
			{ item = "coins", chance = 1, min = 3000, max = 4500 },
			{ item = "rare_part", chance = 1, min = 2, max = 3 },
			{ item = "monster_core", chance = 1, min = 1, max = 1 },
			{ item = "boss_essence", chance = 0.5, min = 1, max = 1 },
			{ item = "trophy", chance = 1, min = 2, max = 2 },
		},
		mega = {
			{ item = "coins", chance = 1, min = 8000, max = 12000 },
			{ item = "monster_core", chance = 1, min = 2, max = 3 },
			{ item = "boss_essence", chance = 1, min = 2, max = 2 },
		},
	},
	Trophy = { meadow = "boar_tusk", mushroom = "glow_spore", ember = "ember_core", frost = "frost_fang" },
	-- The zones, by their WorldPlan id.
	--   map     the Config.Dungeon.Maps id its crowds are drawn from
	--   level   the dungeon level its monsters are scaled to (HP and attack x LevelPower ^ (level - 1); it need not be whole).
	--           Set with tools/balance/zone_sim.luau (`fit`) so that four even slimes of the level in the comment win about
	--           three fights in four. That level is the level of the packs standing round the zone (the owner, 2026-11-14:
	--           a guard matches the monsters about it), the Heart's the packs' highest: fit again after Packs or the plan
	--           changes.
	--   waves   in order. { wave = n }: the Dungeon's crowd of wave n (never the Dungeon's own boss waves, 5 and 10).
	--           { wave = n, guard = id }: that monster alone, as strong as in wave n; `power` multiplies its HP and attack
	--           once more (a common monster standing guard). Wave numbers rise within a zone (monster ids are made of them).
	--   needs   zones that must be won first
	--   offset  the middle of the fight, studs from the zone's middle (x east, z south), where the pad's middle is not flat
	Zones = {
		-- the Meadow
		m1 = { map = "meadow", level = 0.55, waves = { { wave = 2 }, { wave = 3, guard = "green_boar" } } }, -- team 6
		m2 = { map = "meadow", level = 1, waves = { { wave = 2 }, { wave = 3, guard = "green_turtle" } } }, -- team 5
		-- the Mushroom Grove
		m3 = { map = "mushroom", level = 4.5, waves = { { wave = 2 }, { wave = 3, guard = "dark_wyrm" } } }, -- team 24
		m4 = { map = "mushroom", level = 7.75, waves = { { wave = 2 }, { wave = 3, guard = "dark_deer", power = 4 } } }, -- team 63
		b1 = {
			map = "mushroom",
			level = 4.6,
			waves = { { wave = 4 }, { wave = 6, guard = "dark_wyrm" }, { wave = 7, guard = "dark_bear" } },
		}, -- team 55
		-- the Ember Wastes
		m5 = { map = "lava", level = 3.8, waves = { { wave = 3 }, { wave = 4, guard = "lava_bull" } } }, -- team 26
		m6 = { map = "lava", level = 6.9, waves = { { wave = 3 }, { wave = 4, guard = "lava_tortoise", power = 4 } } }, -- team 89
		b2 = {
			map = "lava",
			level = 4.65,
			waves = { { wave = 4 }, { wave = 6, guard = "lava_bull" }, { wave = 7, guard = "lava_golem" } },
		}, -- team 63
		-- the far corners
		m7 = { map = "mushroom", level = 7.05, waves = { { wave = 4 }, { wave = 6, guard = "dark_totem", power = 4 } } }, -- team 103
		m8 = { map = "lava", level = 7.6, waves = { { wave = 4 }, { wave = 6, guard = "lava_phoenix", power = 4 } } }, -- team 114
		-- the Frost Peaks
		m9 = { map = "ice", level = 7.4, waves = { { wave = 4 }, { wave = 6, guard = "ice_golem", power = 4 } } }, -- team 148
		m10 = { map = "ice", level = 7.2, waves = { { wave = 4 }, { wave = 6, guard = "ice_mammoth" } } }, -- team 127
		b3 = {
			map = "ice",
			level = 6,
			waves = { { wave = 4 }, { wave = 6, guard = "ice_mammoth" }, { wave = 7, guard = "ice_yeti" } },
			-- (a mound fills the pad's south-west)
			offset = { x = 0, z = -30 },
		}, -- team 117
		-- The Heart. King Goo has no model yet (docs/WORLD.md §5): until he does, the four region bosses hold it in turn.
		heart = {
			map = "ice",
			level = 6.65,
			waves = {
				{ wave = 3, guard = "green_boar" },
				{ wave = 4, guard = "dark_bear" },
				{ wave = 6, guard = "lava_golem" },
				{ wave = 7, guard = "ice_yeti" },
			},
			needs = { "b1", "b2", "b3" },
		}, -- team 150
	},
}
