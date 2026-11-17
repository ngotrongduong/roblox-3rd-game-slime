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
		-- Far off, a lamp's glow (the library's, gone past about 200 studs) gives way to a Bulb: a Neon ball at its head,
		-- shown only past From studs from the camera, PerStud of that distance wide (at least the glow's size, at most
		-- Max), so a lit village reads from afar at night for next to nothing; a moving effect only near (the owner,
		-- 2026-11-16). The lamps themselves stay on every device (tools/build_publish.luau makes them Persistent).
		Bulb = { From = 170, PerStud = 0.006, Max = 6, Transparency = 0.15 },
		-- An effect worn day and night by every unseen part of this name the world puts down (Crownfall's foot).
		Worn = { FallFoot = "aura.waterfall_foam" },
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
		-- (2420 before the villages moved, 2026-11-17; 2310 is the same farthest pack, at -1078, -1747, from Hillfoot's
		-- new place, worked out from the plan: read the server's line in the next play test and set it again.)
		FarStuds = 2310,
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
		-- counted), and the coins it pays at level 0 by its role (raised by its level as a slime's sale is). At 0.55 a
		-- team beats a pack of its own level every time and loses a slime about once in 12 fights at level 4, less
		-- above; a pack a fifth above its level is a fair fight (96-98 wins in 100, a slime lost every other fight) and
		-- one 1.7 times its level about even (tools/balance/pack_sim.luau). It was 0.85 until 2026-11-15: the four
		-- starters then lost two slimes a fight to the packs beside their village (62 wins in 100), so a new village
		-- could not earn.
		StatFactor = 0.55,
		CoinBase = { swarmer = 100, raider = 150, spitter = 150, shaman = 200, armoured = 300 },
		Maps = { vale = "meadow", meadow = "meadow", mushroom = "mushroom", ember = "lava", frost = "ice" },
		-- What a won pack pays (the owner, 2026-11-15; shared/WorldPacks.loot, rolled with the pack): one unit of its region's
		-- basic (the Dungeon map's own, Config.Dungeon.Maps; a Home Vale pack takes ValeBasics in turn by its cell, so a new
		-- player meets all four near home), a second unit with SecondBasicChance from pack level SecondBasicFrom, a Core
		-- Fragment with RarePartChance from RarePartFrom and a Monster Core with MonsterCoreChance from MonsterCoreFrom.
		-- Never a trophy, never Boss Essence.
		ValeBasics = { "wood", "silk", "ore", "crystal" },
		SecondBasicFrom = 60,
		SecondBasicChance = 0.5,
		RarePartFrom = 25,
		RarePartChance = 1 / 6,
		MonsterCoreFrom = 65,
		MonsterCoreChance = 0.1,
		-- A team sets out at most this far from its pack, on the pack's side towards the player's village (a march from
		-- the gate itself would take minutes across the world), and comes back to the same spot.
		MarchMostStuds = 60,
	},
	-- ===== Treasure chests (the owner, 2026-11-16; rules shared/Treasure, server/Treasure) =====
	-- Count chests lie on the open land at a time, each on a spot picked at random where a pack could stand (a random
	-- cell of the packs' grid, Tries tries), at least Apart studs from every other chest. The first player to open one
	-- (its prompt, held HoldSeconds from PromptRangeStuds) gets Coins raised by the spot's level as a pack monster's
	-- coins are (x 1 + level x Config.Economy.SellLevelStep), past the vault's cap; RespawnSeconds later another lies
	-- somewhere else. The chest is Quaternius' Pirate Kit chest (CC0) recoloured gold and honey wood, uploaded as model
	-- Model (art/models/props/treasure_chest), Scale times its file size. Over it stands a pillar of light seen across the
	-- world: a Beam of the library's light shafts (PillarTexture), PillarHeight studs, PillarWidth wide at the foot and
	-- the top, in PillarColour, its picture flowing up at PillarSpeed. The chests are kept on every device (Persistent).
	Chests = {
		Folder = "TreasureChests",
		Remote = "Treasure",
		Count = 12,
		Apart = 500,
		Tries = 40,
		Coins = 1500,
		RespawnSeconds = 180,
		PromptRangeStuds = 10,
		HoldSeconds = 0.5,
		Model = 88485660368211,
		Scale = 3.4,
		PillarTexture = 18837316844,
		PillarHeight = 160,
		PillarWidth = { 12, 5 },
		PillarColour = "ffd25a",
		PillarSpeed = 0.4,
		-- the moment it opens, for the player who opened it (client)
		Burst = "burst.reward_glitter",
		BurstColour = "ffd25a",
	},
	-- ===== The crowds at the zones (the owner, 2026-11-16; client/ZoneCrowds) =====
	-- Every zone of these Kinds shows its guard standing on the middle of its pad with Count of its map's common monsters
	-- on a ring Ring studs round it, all facing the zone's waystone: drawn while the camera is within DrawStuds (looked at
	-- every CheckSeconds), put away while the viewer's own fight runs and while the zone rests for them after a win.
	Crowds = { Kinds = { "mini", "boss" }, Count = 3, Ring = 18, DrawStuds = 320, CheckSeconds = 0.5 },
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
	-- (no lines between the level bands since 2026-11-16, the owner)
	Map = { Image = 130854496202058, MinX = -2300, MinZ = -2500, Size = 4600 },
	-- What a zone's guard pays when it falls, by the zone's kind, in place of its own drops. Lines as a monster's drops (item,
	-- chance, min..max). No trophy: those are the Dungeon's own (the owner, 2026-11-15). Coins are what the guard pays at
	-- level 0, raised by the zone's level as a pack monster's are (x 1 + level x Config.Economy.SellLevelStep): a mini
	-- guard pays about what two or three packs round it do, a boss three times that (the owner, 2026-11-14: the guards'
	-- coins match their new levels; they were 10-120 before). Every other monster of a zone drops what its def says
	-- (coins and food only).
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
		},
		mega = {
			{ item = "coins", chance = 1, min = 8000, max = 12000 },
			{ item = "monster_core", chance = 1, min = 2, max = 3 },
			{ item = "boss_essence", chance = 1, min = 2, max = 2 },
		},
	},
	-- The zones, by their WorldPlan id.
	--   map     the Config.Dungeon.Maps id its crowds are drawn from
	--           Every monster of a zone stands at the zone's level (shared/ZoneFights.level: the level of the packs round
	--           it, the owner 2026-11-14; the Heart's the packs' highest) and is made as the Dungeon's monsters are.
	--   waves   in order. { wave = n }: the Dungeon's crowd of wave n (never the Dungeon's own boss waves, 5 and 10).
	--           { wave = n, guard = id }: that monster alone, as strong as in wave n; a wave's `power` multiplies its HP and
	--           attack once more (a common monster standing guard). Wave numbers rise within a zone (monster ids are made
	--           of them).
	--   power   HP and attack of every monster of the zone times this, set with tools/balance/zone_sim.luau (`fit`) so
	--           that a team of the zone's level wins about three fights in four: fit again after Packs, the plan or the
	--           Dungeon's monsters change.
	--   needs   zones that must be won first
	--   offset  the middle of the fight, studs from the zone's middle (x east, z south), where the pad's middle is not flat
	Zones = {
		-- the Meadow
		-- (power fitted 2026-11-15, 10 seeds a team: the zone's team wins 77-90 fights in 100)
		m1 = { map = "meadow", power = 4.75, waves = { { wave = 2 }, { wave = 3, guard = "green_boar" } } }, -- team 6
		m2 = { map = "meadow", power = 5.05, waves = { { wave = 2 }, { wave = 3, guard = "green_turtle" } } }, -- team 5
		-- the Mushroom Grove
		m3 = { map = "mushroom", power = 4.9, waves = { { wave = 2 }, { wave = 3, guard = "dark_wyrm" } } }, -- team 24
		m4 = {
			map = "mushroom",
			power = 4.15,
			waves = { { wave = 2 }, { wave = 3, guard = "dark_deer", power = 4 } },
		}, -- team 63
		b1 = {
			map = "mushroom",
			power = 2.7,
			waves = { { wave = 4 }, { wave = 6, guard = "dark_wyrm" }, { wave = 7, guard = "dark_bear" } },
		}, -- team 55
		-- the Ember Wastes
		m5 = { map = "lava", power = 3.55, waves = { { wave = 3 }, { wave = 4, guard = "lava_bull" } } }, -- team 26
		m6 = {
			map = "lava",
			power = 3.2,
			waves = { { wave = 3 }, { wave = 4, guard = "lava_tortoise", power = 4 } },
		}, -- team 89
		b2 = {
			map = "lava",
			power = 2.9,
			waves = { { wave = 4 }, { wave = 6, guard = "lava_bull" }, { wave = 7, guard = "lava_golem" } },
		}, -- team 63
		-- the far corners
		m7 = {
			map = "mushroom",
			power = 2.8,
			waves = { { wave = 4 }, { wave = 6, guard = "dark_totem", power = 4 } },
		}, -- team 103
		m8 = {
			map = "lava",
			power = 2.8,
			waves = { { wave = 4 }, { wave = 6, guard = "lava_phoenix", power = 4 } },
		}, -- team 114
		-- the Frost Peaks
		m9 = {
			map = "ice",
			power = 2.85,
			waves = { { wave = 4 }, { wave = 6, guard = "ice_golem", power = 4 } },
		}, -- team 148
		m10 = { map = "ice", power = 3.05, waves = { { wave = 4 }, { wave = 6, guard = "ice_mammoth" } } }, -- team 127
		b3 = {
			map = "ice",
			power = 2.8,
			waves = { { wave = 4 }, { wave = 6, guard = "ice_mammoth" }, { wave = 7, guard = "ice_yeti" } },
			-- (a mound fills the pad's south-west)
			offset = { x = 0, z = -30 },
		}, -- team 117
		-- The Heart. King Goo has no model yet (docs/WORLD.md §5): until he does, the four region bosses hold it in turn.
		heart = {
			map = "ice",
			power = 2.8,
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
