--!strict
-- Every tunable number of the game lives here. Values come from the original web game
-- (docs/reference/*.md, each with its source module); change them here, never in the logic.
-- Each area owns its own block below.

local Config = {}

Config.GameName = "Goo Lineage V2"
Config.LogPrefix = "[GooLineage]"

-- ===== Farm rules: stats, breeding, genetics, mutations, eggs, growth, luck =====
-- (owned by the farm-rules modules: FarmState, Stats, Genetics, Mutations, Breeding, Hatching)
-- Source: docs/reference/01-core-farm.md. Every time is in SECONDS (the original used ms).

Config.Stats = {
	-- New slimes and the four starters: level 4.
	Starter = { attack = 1, defence = 1, speed = 1, hp = 10 },
	-- Inclusive integer limits; speed starts at 1 so a job can never take zero time.
	Limits = {
		attack = { min = 1, max = 99 },
		defence = { min = 1, max = 99 },
		speed = { min = 1, max = 99 },
		hp = { min = 10, max = 9990 },
	},
	-- level = floor(attack + defence + speed + hp / HpPerLevel)
	HpPerLevel = 10,
}

Config.Breeding = {
	-- Incubation: (Base + a second a baby level above IncubationLevelBase) * IncubationAreaFactor per area level.
	IncubationSeconds = 60,
	-- An egg left in its nest hatches too, this many times slower than in an incubator (the owner, 2026-10-29).
	NestSlowFactor = 2,
	-- Parent rest: round((Base + max(0, bestParentLevel - 1) * PerLevel) * Factor ^ min(MaxLevel, upgradeLevel)).
	CooldownSeconds = 60,
	CooldownPerLevelSeconds = 1,
	CooldownUpgradeFactor = 0.95,
	CooldownMaxLevel = 20,
	-- One stat may beat the stronger parent (chance × luck, capped by Config.Mutation.ChanceCap).
	ImproveChance = 0.10,
	StatBonusMin = 1,
	StatBonusMax = 3,
	HpBonusMin = 10,
	HpBonusMax = 30,
	MaxActiveEggs = 4,
	-- Slots: Base + min(MaxLevel, slimeStorage) * PerLevel → 20 .. 220. Eggs reserve a slot.
	PopulationBase = 20,
	PopulationPerLevel = 5,
	PopulationMaxLevel = 40,
	-- The tutorial's first egg: a new homozygous colour, this many stats beat the parents.
	TutorialBoostedStats = 2,
	-- While the tutorial runs, breeding is quick so a new player does not wait (the owner, 2026-11-03): every egg
	-- hatches in this long in an incubator (NestSlowFactor times longer in a nest) and a courtship takes this long.
	TutorialHatchSeconds = 10,
	TutorialCourtshipSeconds = 10,
	-- How many fresh ids to ask for before giving up (a counter or GUID never collides).
	IdAttempts = 32,
	-- Two places at level 1, one extra at each milestone.
	SlotLevels = { 21, 41 },
	BasePlaces = 2,
	-- Each level of the breeding area above the first speeds a courtship and an incubation by these factors, down to
	-- their floors, and lifts the chance of a rare baby (secret, dual, material) by RareChancePerLevel of its base (the
	-- owner, 2026-11-04: an upgrade should breed faster, hatch faster and give more rare mutations, not only more
	-- nests). Level 10: courtship 42 s, hatch 42 s, rare x1.18; level 20: 28 s, 28 s, x1.38; level 50: x1.98.
	CourtshipSeconds = 60,
	CourtshipAreaFactor = 0.96,
	CourtshipMinSeconds = 15,
	-- A courtship takes this much longer for each level of the stronger parent above LevelBase: a little, while an
	-- incubation grows by IncubationPerBabyLevel a level (the owner, 2026-11-04: the higher the slime, the longer the
	-- hatch; courting is not slowed much).
	CourtshipPerLevelSeconds = 0.5,
	CourtshipLevelBase = 4,
	LayEnergy = 30,
	IncubationPerBabyLevel = 2,
	IncubationLevelBase = 4,
	IncubationAreaFactor = 0.96,
	IncubationFloorSeconds = 10,
	RareChancePerLevel = 0.02,
}

Config.Mutation = {
	-- A material roll only follows the Plain category (docs/GAMEPLAY.md).
	MaterialChance = 0.02,
	-- Luck-multiplied chances (secret, material, dual, stat improvement) never go above this.
	ChanceCap = 0.95,
	-- The PityThreshold-th plain egg in a row is forced rare: PitySecretShare secret, else dual.
	-- Pity never gives a material.
	PityThreshold = 25,
	PitySecretShare = 0.10,
}

-- Categorical inheritance (docs/GAMEPLAY.md §1.2); Plain is the remaining share.
Config.Inheritance = {
	plainSame = { secret = 0.01, dual = 0, random = 0.10 },
	plainOther = { secret = 0.01, dual = 0.04, random = 0.10 },
	dualPlain = { secret = 0.02, dual = 0.25, random = 0.10 },
	dualSame = { secret = 0.03, dual = 0.50, random = 0.10 },
	dualOther = { secret = 0.04, dual = 0.40, random = 0.10 },
	secretPlain = { secret = 0.03, dual = 0.20, random = 0.10 },
	secretDual = { secret = 0.05, dual = 0.40, random = 0.10 },
	secretSame = { secret = 0.10, dual = 0.60, random = 0.10 },
	secretOther = { secret = 0.07, dual = 0.45, random = 0.10 },
}

-- Material slimes (docs/MATERIALS.md): a rare appearance next to Dual and Secret. Which material is a
-- weighted pick; TierWeight is each material's weight by tier, SellBase its sell value by tier.
Config.Material = {
	TierWeight = { common = 6, rare = 3, precious = 1 },
	SellBase = { common = 1500, rare = 3000, precious = 8000 },
	-- The outline hull of a material slime is its drawn colour times this.
	HullShade = 0.6,
}

-- Selling a slime (docs/reference/01-core-farm.md §8.1): floor(base × (1 + level × SellLevelStep)).
-- Base by appearance; a material slime uses Config.Material.SellBase by its tier.
Config.Economy = {
	SellBase = { none = 100, dual = 1000, secret = 10000 },
	SellLevelStep = 0.05,
}

-- Fights (docs/reference/02-battle.md §8): the original's damage, cooldown and crit numbers; dodge is new.
Config.Combat = {
	DefenceK = 50,
	DefenceCap = 0.75,
	-- a fight lasts about 25 s to watch at any level
	DamageScale = 0.3,
	MinDamage = 0.05,
	MinCooldown = 0.25,
	CooldownPerSpeed = 0.04,
	OpeningCooldown = 0.5,
	CritBase = 0.10,
	CritPerSpeed = 0.002,
	CritCap = 0.30,
	CritFactor = 1.6,
	DodgePerSpeed = 0.005,
	DodgeCap = 0.25,
	-- Each fighter opens somewhere in OpeningCooldown .. + OpeningSpread seconds and every blow is up to CooldownJitter
	-- off its beat, so a team never strikes as one (the owner, 2026-11-03: "4 independent slimes"). An "aim" event goes
	-- out WindupSeconds before each blow for the wind-up.
	OpeningSpread = 1.5,
	CooldownJitter = 0.15,
	WindupSeconds = 0.3,
	-- A slime's way of fighting is its strongest stat (Combat.role), in this order on a tie broken by its seed.
	Roles = { "attack", "defence", "speed", "hp" },
	-- Whom each way of fighting goes for (a slime's role or a zombie's kind; the rest pick anyone): a fast slime finishes
	-- the one with the least health left, a strong one goes for the hardest hitter, a toxic zombie for the weakest slime.
	-- (a dungeon hunter, like the toxic zombie, finishes the one with the least health)
	Aims = { speed = "weakest", attack = "strongest", toxic = "weakest", hunter = "weakest" },
	-- A healer (dungeon monsters, docs/reference/02-battle.md §10) does not strike while a team-mate is wounded: the most
	-- wounded one gets back `share` times the healer's attack (the original's attack x 3 at its damage weight), and the
	-- healer waits `extraCooldown` seconds more before its next turn.
	Heals = { healer = { share = 0.9, extraCooldown = 1 } },
	-- A ranged fighter strikes as any other; its events say `ranged` so the client keeps it at a distance.
	Ranged = { ranged = true },
	-- A plain blow of this way of fighting slows the one it hits: its beat runs at (1 - slow) speed for `seconds`
	-- (Honey Bee: 70% for 2 s, docs/reference/02-battle.md §7). A new sting only renews the time; it never stacks.
	Stings = { hunter = { slow = 0.7, seconds = 2 } },
	-- How much more often a fighter that picks anyone picks one of these: the guard draws the blows to itself.
	Pull = { defence = 3 },
	-- Every way of fighting has its own skill, struck instead of every `every`-th blow (the owner, 2026-11-03), its name
	-- shouted by the one who strikes it. `factor` is the weight of each of its blows against a plain one.
	--   splash: the target, and up to `spread` others beside it at `splash`;   multi: `hits` quick blows at the target;
	--   guard: for `seconds` the guard takes every blow aimed at a team-mate, its defence times `defence`;
	--   all: every foe at once, each knocked `stun` seconds off its beat;   single: one heavy blow.
	Skills = {
		attack = { kind = "splash", name = "Goo Slam", every = 4, factor = 1.4, splash = 0.4, spread = 2 },
		speed = { kind = "multi", name = "Dash Strike", every = 4, factor = 0.5, hits = 3 },
		defence = { kind = "guard", name = "Jelly Guard", every = 5, factor = 1, seconds = 3, defence = 1.3 },
		hp = { kind = "all", name = "Belly Bounce", every = 5, factor = 0.5, stun = 0.4 },
		rotten = { kind = "single", name = "Chomp", every = 5, factor = 1.6 },
		toxic = { kind = "all", name = "Acid Rain", every = 5, factor = 0.45 },
		plague = { kind = "all", name = "Plague Burst", every = 4, factor = 0.6, stun = 0.4 },
		-- The two bosses of the Slime Dungeon's Sunny Meadow (Config.Dungeon): Bloomshell shakes every slime at once,
		-- Bramblehorn charges the target with a heavy blow that throws the thorns about it (the original's charge: x2.0 on
		-- the target, x0.6 beside it).
		bloomshell = { kind = "all", name = "Pollen Shockwave", every = 5, factor = 0.5, stun = 0.6 },
		bramblehorn = { kind = "splash", name = "Thorn Charge", every = 4, factor = 2, splash = 0.6, spread = 2 },
		-- The two of the Mushroom Grove: the Jungle Wyrm bursts a cloud of spores over every slime, Mama Bear slams the ground
		-- under her target and the slimes beside it.
		sporeburst = { kind = "all", name = "Spore Burst", every = 4, factor = 0.5, stun = 0.5 },
		bearslam = { kind = "splash", name = "Den Slam", every = 4, factor = 2.4, splash = 0.7, spread = 3 },
		-- The two of Ember Lava: the Magma Bull stamps its target and the slimes beside it, the Magma Golem makes the ground
		-- erupt under every slime at once (a step heavier than the Grove's, as the map's monsters are).
		lavastomp = { kind = "splash", name = "Magma Stomp", every = 4, factor = 2.6, splash = 0.75, spread = 3 },
		eruption = { kind = "all", name = "Eruption", every = 5, factor = 0.6, stun = 0.6 },
		-- The two of Frozen Ice, each a skill kind of its own: the Mammoth lowers its tusks and rams its target twice
		-- (two blows that each weigh a step more than the Bull's share of a stomp), the Yeti howls a blizzard over every
		-- slime at once, and the cold holds each one a moment longer than the eruption's heat.
		tuskcharge = { kind = "multi", name = "Tusk Charge", every = 4, factor = 1.4, hits = 2 },
		blizzard = { kind = "all", name = "Blizzard", every = 5, factor = 0.65, stun = 0.7 },
	},
}

-- Props from the free library (art/library, CC0): Quaternius' Fantasy Props MegaKit, made small by tools/library/take_props.ps1,
-- imported by the owner (2026-11-08); the server puts each together from its meshes (server/LibraryKit) and the stages place
-- them by name like the kit's own models. Each part: its mesh, its picture (a trim sheet, Textures), its size and its centre
-- from the prop's foot, in studs of the imported model (any size: `place` scales a prop to its slot).
Config.LibraryKit = {
	Textures = {
		F = "rbxassetid://88131378238308", -- wood (T_Trim_Furniture, art/models/props/quaternius)
		M = "rbxassetid://71855764790861", -- iron
		-- the produce (apples, carrots) is painted in the mesh's own vertex colours: the trim sheet over them read black
		P = "",
		C = "rbxassetid://71397049359621", -- cloth
	},
	Props = {
		Barrel = {
			{ mesh = 136375007718158, tex = "F", size = { 2.784, 3.592, 2.784 }, at = { 0, 1.796, 0 } },
			{ mesh = 127037148208044, tex = "M", size = { 2.792, 2.334, 2.792 }, at = { 0, 1.751, 0 } },
		},
		Barrel_Apples = {
			{ mesh = 132533726279302, tex = "F", size = { 2.784, 3.592, 2.784 }, at = { 0, 1.796, 0 } },
			{ mesh = 131374859428781, tex = "M", size = { 2.792, 2.334, 2.792 }, at = { 0, 1.751, 0 } },
			{ mesh = 78986540689423, tex = "P", size = { 1.733, 0.95, 1.773 }, at = { 0.002, 3.032, -0.014 } },
		},
		Bench = {
			{ mesh = 82983925864215, tex = "F", size = { 11.107, 2.133, 2.137 }, at = { 0, 1.066, 0 } },
			{ mesh = 140163533106589, tex = "M", size = { 7.356, 0.115, 1.409 }, at = { 0, 1.998, 0.025 } },
		},
		Bucket_Wooden_1 = {
			{ mesh = 132508416890620, tex = "F", size = { 1.502, 1.171, 1.462 }, at = { 0.005, 0.586, -0.036 } },
			{ mesh = 81812337491409, tex = "M", size = { 1.736, 0.135, 0.846 }, at = { 0, 1.041, 0.344 } },
		},
		Cauldron = {
			{ mesh = 137876148545744, tex = "M", size = { 3.956, 3.262, 3.776 }, at = { 0, 1.631, 0 } },
		},
		Crate_Wooden = {
			{ mesh = 131790322916575, tex = "F", size = { 3.369, 3.52, 3.425 }, at = { 0, 1.862, -0.008 } },
			{ mesh = 105661159718332, tex = "M", size = { 3.253, 3.724, 3.633 }, at = { -0.019, 1.862, 0 } },
		},
		FarmCrate_Apple = {
			{ mesh = 94764161420810, tex = "F", size = { 2.855, 0.975, 1.588 }, at = { 0, 0.488, 0 } },
			{ mesh = 75018336870446, tex = "M", size = { 2.32, 0.755, 1.657 }, at = { 0.005, 0.51, 0 } },
			{ mesh = 109037019181785, tex = "P", size = { 2.25, 0.784, 1.426 }, at = { -0.013, 0.411, -0.011 } },
		},
		FarmCrate_Carrot = {
			{ mesh = 131712433745343, tex = "P", size = { 2.662, 0.942, 2.206 }, at = { 0.05, 1.175, 0.031 } },
			{ mesh = 126065041271513, tex = "F", size = { 2.855, 0.975, 1.588 }, at = { 0, 0.488, -0.306 } },
			{ mesh = 123714214047372, tex = "M", size = { 2.32, 0.755, 1.657 }, at = { 0.005, 0.51, -0.306 } },
		},
		FarmCrate_Empty = {
			{ mesh = 100028304019085, tex = "F", size = { 2.855, 0.975, 1.588 }, at = { 0, 0.488, 0 } },
			{ mesh = 109150201003884, tex = "M", size = { 2.32, 0.755, 1.657 }, at = { 0.005, 0.51, 0 } },
		},
		Lantern_Wall = {
			{ mesh = 85249417263972, tex = "M", size = { 1.429, 5.348, 5.209 }, at = { 0, 2.674, 0 } },
		},
		Stall_Cart_Empty = {
			{ mesh = 133346702422863, tex = "M", size = { 7.31, 7.868, 4.239 }, at = { -2.386, 3.934, 0 } },
			{ mesh = 114639508008462, tex = "F", size = { 12.063, 10.297, 4.076 }, at = { 0.01, 5.156, 0 } },
			{ mesh = 73567020016753, tex = "C", size = { 7.267, 3.324, 3.756 }, at = { -2.386, 8.865, -0.035 } },
		},
		Stall_Empty = {
			{ mesh = 70775102318080, tex = "M", size = { 7.379, 2.449, 3.277 }, at = { 0, 2.219, 0.036 } },
			{ mesh = 127707752377149, tex = "F", size = { 7.311, 10.308, 3.491 }, at = { 0, 5.154, 0.02 } },
			{ mesh = 140105739714888, tex = "C", size = { 7.297, 6.588, 3.729 }, at = { 0, 7.215, 0 } },
		},
		Stool = {
			{ mesh = 97282599980451, tex = "F", size = { 1.898, 2.355, 1.898 }, at = { 0, 1.177, 0 } },
		},
		Table_Large = {
			{ mesh = 72020217389011, tex = "F", size = { 11.394, 3.246, 4.353 }, at = { 0, 1.623, 0.017 } },
			{ mesh = 72743792577672, tex = "M", size = { 8.707, 0.318, 4.376 }, at = { 0, 3.095, -0.005 } },
		},
		-- The dungeon meadow's scenery (Quaternius' Ultimate Nature Pack, recoloured in its vertex colours by
		-- tools/library/fbx_to_glb.py, packed into one file by combine_glb.py and imported by the owner, 2026-11-08).
		BirchTree_1 = {
			{ mesh = 139444343818531, tex = "P", size = { 1.702, 3.568, 2.428 }, at = { 0, 1.784, 0 } },
		},
		BushBerries_1 = {
			{ mesh = 98755479798740, tex = "P", size = { 1.392, 1.266, 1.716 }, at = { 0, 0.633, 0 } },
		},
		Bush_1 = {
			{ mesh = 115781284840420, tex = "P", size = { 1.328, 1.242, 1.69 }, at = { 0, 0.621, 0 } },
		},
		Bush_2 = {
			{ mesh = 106685108364171, tex = "P", size = { 1.346, 1.111, 1.328 }, at = { 0, 0.555, 0 } },
		},
		CommonTree_1 = {
			{ mesh = 103359265744370, tex = "P", size = { 1.886, 2.477, 2.741 }, at = { 0, 1.238, 0 } },
		},
		CommonTree_2 = {
			{ mesh = 119490308149469, tex = "P", size = { 1.659, 3.092, 2.508 }, at = { 0, 1.546, 0 } },
		},
		CommonTree_3 = {
			{ mesh = 126889590117941, tex = "P", size = { 1.277, 3.438, 1.521 }, at = { 0, 1.719, 0 } },
		},
		CommonTree_4 = {
			{ mesh = 136184488317389, tex = "P", size = { 1.567, 2.781, 1.801 }, at = { 0, 1.39, 0 } },
		},
		CommonTree_5 = {
			{ mesh = 137764274843200, tex = "P", size = { 1.28, 2.535, 2.246 }, at = { 0, 1.267, 0 } },
		},
		Flowers = {
			{ mesh = 134067909108589, tex = "P", size = { 0.479, 0.828, 0.604 }, at = { 0, 0.414, 0 } },
		},
		Flowers_Gold = {
			{ mesh = 127315168636363, tex = "P", size = { 0.479, 0.828, 0.604 }, at = { 0, 0.414, 0 } },
		},
		Flowers_Pink = {
			{ mesh = 90565517534449, tex = "P", size = { 0.479, 0.828, 0.604 }, at = { 0, 0.414, 0 } },
		},
		Flowers_White = {
			{ mesh = 83992252834730, tex = "P", size = { 0.479, 0.828, 0.604 }, at = { 0, 0.414, 0 } },
		},
		PineTree_2 = {
			{ mesh = 70532459082860, tex = "P", size = { 1.784, 3.568, 1.955 }, at = { 0, 1.784, 0 } },
		},
		PineTree_4 = {
			{ mesh = 114815845598921, tex = "P", size = { 1.248, 3.345, 1.38 }, at = { 0, 1.672, 0 } },
		},
		Rock_1 = {
			{ mesh = 119572610685766, tex = "P", size = { 0.485, 0.878, 0.467 }, at = { 0, 0.439, 0 } },
		},
		Rock_2 = {
			{ mesh = 115963105141504, tex = "P", size = { 0.561, 0.646, 0.565 }, at = { 0, 0.323, 0 } },
		},
		Rock_3 = {
			{ mesh = 95882723669756, tex = "P", size = { 0.738, 0.676, 0.803 }, at = { 0, 0.338, 0 } },
		},
		Rock_4 = {
			{ mesh = 116688203820067, tex = "P", size = { 0.744, 0.784, 1.251 }, at = { 0, 0.392, 0 } },
		},
		Rock_5 = {
			{ mesh = 92356299110908, tex = "P", size = { 0.663, 0.653, 0.915 }, at = { 0, 0.326, 0 } },
		},
		Rock_Moss_1 = {
			{ mesh = 120420035752313, tex = "P", size = { 0.485, 0.95, 0.467 }, at = { 0, 0.475, 0 } },
		},
		Rock_Moss_3 = {
			{ mesh = 114892369901374, tex = "P", size = { 0.738, 0.557, 0.803 }, at = { 0, 0.278, 0 } },
		},
		TreeStump = {
			{ mesh = 77391363848171, tex = "P", size = { 1.36, 0.622, 1.031 }, at = { 0, 0.311, 0 } },
		},
		TreeStump_Moss = {
			{ mesh = 73489273110803, tex = "P", size = { 1.36, 0.622, 1.031 }, at = { 0, 0.311, 0 } },
		},
		WoodLog = {
			{ mesh = 120837366948236, tex = "P", size = { 0.633, 0.748, 2.67 }, at = { 0, 0.374, 0 } },
		},
		WoodLog_Moss = {
			{ mesh = 111123259457669, tex = "P", size = { 0.894, 0.688, 2.67 }, at = { 0, 0.344, 0 } },
		},
		-- The Mushroom Grove's scenery (tools/library/build_grove.ps1: the recoloured Quaternius pieces and the procedural
		-- mushrooms, roots and stones, one file MushroomProps.glb, imported by the owner, 2026-11-08).
		Arch_Round_Grove = {
			{ mesh = 88178210630935, tex = "P", size = { 3.092, 3.533, 0.491 }, at = { 0, 1.766, 0 } },
		},
		Bricks_Grove = {
			{ mesh = 107984017723307, tex = "P", size = { 1.824, 0.546, 1.610 }, at = { 0, 0.273, 0 } },
		},
		Bush_1_Grove = {
			{ mesh = 93520277136821, tex = "P", size = { 1.332, 1.228, 1.690 }, at = { 0, 0.614, 0 } },
		},
		Bush_2_Grove = {
			{ mesh = 130082336287283, tex = "P", size = { 1.346, 1.111, 1.328 }, at = { 0, 0.555, 0 } },
		},
		Column_Round_Grove = {
			{ mesh = 100390927091504, tex = "P", size = { 0.659, 3.990, 0.659 }, at = { 0, 1.995, 0 } },
		},
		Column_Round_Short_Grove = {
			{ mesh = 102096065413340, tex = "P", size = { 0.489, 1.830, 0.489 }, at = { 0, 0.915, 0 } },
		},
		CommonTree_2_Grove = {
			{ mesh = 124286681619024, tex = "P", size = { 1.659, 3.092, 2.508 }, at = { 0, 1.546, 0 } },
		},
		CommonTree_Dead_3_Grove = {
			{ mesh = 136066234974098, tex = "P", size = { 0.638, 3.002, 0.813 }, at = { 0, 1.501, 0 } },
		},
		CommonTree_Dead_4_Grove = {
			{ mesh = 71567418145919, tex = "P", size = { 0.819, 2.369, 1.084 }, at = { 0, 1.185, 0 } },
		},
		Flowers_GroveBlue = {
			{ mesh = 114126707411773, tex = "P", size = { 0.479, 0.828, 0.604 }, at = { 0, 0.414, 0 } },
		},
		Flowers_GrovePink = {
			{ mesh = 114446490885346, tex = "P", size = { 0.479, 0.828, 0.604 }, at = { 0, 0.414, 0 } },
		},
		Flowers_GrovePurple = {
			{ mesh = 136034666784827, tex = "P", size = { 0.479, 0.828, 0.604 }, at = { 0, 0.414, 0 } },
		},
		GroveBlock_1 = {
			{ mesh = 136498865034717, tex = "P", size = { 1.704, 1.114, 1.456 }, at = { 0, 0.557, 0 } },
		},
		GroveBlock_2 = {
			{ mesh = 107270301683421, tex = "P", size = { 1.239, 0.813, 1.181 }, at = { 0, 0.407, 0 } },
		},
		GroveRoot_1 = {
			{ mesh = 130947608834036, tex = "P", size = { 5.393, 1.532, 1.876 }, at = { 0, 0.766, 0 } },
		},
		GroveRoot_2 = {
			{ mesh = 82174900626929, tex = "P", size = { 7.019, 2.172, 2.459 }, at = { 0, 1.086, 0 } },
		},
		GroveRoot_3 = {
			{ mesh = 129653513206045, tex = "P", size = { 4.356, 1.191, 1.554 }, at = { 0, 0.595, 0 } },
		},
		GroveRoot_4 = {
			{ mesh = 72693051242033, tex = "P", size = { 8.033, 2.317, 2.749 }, at = { 0, 1.158, 0 } },
		},
		GroveRoot_5 = {
			{ mesh = 124430086850497, tex = "P", size = { 3.672, 1.704, 1.581 }, at = { 0, 0.852, 0 } },
		},
		GroveSlab_1 = {
			{ mesh = 105908454229057, tex = "P", size = { 1.054, 3.240, 0.589 }, at = { 0, 1.620, 0 } },
		},
		GroveSlab_2 = {
			{ mesh = 100988617531247, tex = "P", size = { 1.311, 2.415, 0.774 }, at = { 0, 1.207, 0 } },
		},
		GroveSlab_3 = {
			{ mesh = 71093832379376, tex = "P", size = { 0.967, 2.000, 0.962 }, at = { 0, 1.000, 0 } },
		},
		MushBig_Blue = {
			{ mesh = 105249084598537, tex = "P", size = { 3.439, 4.350, 3.389 }, at = { 0, 2.175, 0 } },
		},
		MushBig_Purple = {
			{ mesh = 84378256361786, tex = "P", size = { 3.752, 4.800, 3.867 }, at = { 0, 2.400, 0 } },
		},
		MushBig_Teal = {
			{ mesh = 113976765253227, tex = "P", size = { 3.113, 4.050, 3.136 }, at = { 0, 2.025, 0 } },
		},
		MushGlow_Blue_1 = {
			{ mesh = 113399732892887, tex = "P", size = { 1.004, 1.370, 0.980 }, at = { 0, 0.685, 0 } },
		},
		MushGlow_Blue_2 = {
			{ mesh = 101534783014598, tex = "P", size = { 0.844, 0.940, 0.799 }, at = { 0, 0.470, 0 } },
		},
		MushGlow_Pink_1 = {
			{ mesh = 107114224793779, tex = "P", size = { 1.004, 1.370, 0.980 }, at = { 0, 0.685, 0 } },
		},
		MushGlow_Pink_2 = {
			{ mesh = 84776363110484, tex = "P", size = { 0.844, 0.940, 0.799 }, at = { 0, 0.470, 0 } },
		},
		MushGlow_Purple_1 = {
			{ mesh = 103669983144973, tex = "P", size = { 1.004, 1.370, 0.980 }, at = { 0, 0.685, 0 } },
		},
		MushGlow_Purple_2 = {
			{ mesh = 120063581041886, tex = "P", size = { 0.844, 0.940, 0.799 }, at = { 0, 0.470, 0 } },
		},
		Plant_1_Grove = {
			{ mesh = 128405745871615, tex = "P", size = { 1.188, 0.505, 0.940 }, at = { 0, 0.252, 0 } },
		},
		Plant_3_Grove = {
			{ mesh = 122612462968813, tex = "P", size = { 1.072, 0.941, 0.973 }, at = { 0, 0.470, 0 } },
		},
		Plant_4_Grove = {
			{ mesh = 124134557917628, tex = "P", size = { 1.903, 0.800, 2.112 }, at = { 0, 0.400, 0 } },
		},
		Rock_6_Grove = {
			{ mesh = 119017456110249, tex = "P", size = { 0.912, 0.708, 1.142 }, at = { 0, 0.354, 0 } },
		},
		Rock_7_Grove = {
			{ mesh = 126785006935665, tex = "P", size = { 0.876, 0.849, 1.098 }, at = { 0, 0.425, 0 } },
		},
		Rock_Moss_1_Grove = {
			{ mesh = 123370299800741, tex = "P", size = { 0.485, 0.950, 0.467 }, at = { 0, 0.475, 0 } },
		},
		Rock_Moss_2_Grove = {
			{ mesh = 95410338686555, tex = "P", size = { 0.613, 0.692, 0.650 }, at = { 0, 0.346, 0 } },
		},
		Rock_Moss_4_Grove = {
			{ mesh = 121138786250161, tex = "P", size = { 0.744, 0.784, 1.251 }, at = { 0, 0.392, 0 } },
		},
		Rock_Moss_5_Grove = {
			{ mesh = 109806645878392, tex = "P", size = { 0.663, 0.577, 0.915 }, at = { 0, 0.288, 0 } },
		},
		Rock_Moss_7_Grove = {
			{ mesh = 139912600194223, tex = "P", size = { 0.876, 0.774, 1.098 }, at = { 0, 0.387, 0 } },
		},
		Wall_Broken_Grove = {
			{ mesh = 82561138554681, tex = "P", size = { 1.988, 1.947, 0.286 }, at = { 0, 0.974, 0 } },
		},
		Wall_Double_Broken_Grove = {
			{ mesh = 103302874853166, tex = "P", size = { 1.989, 0.986, 0.566 }, at = { 0, 0.493, 0 } },
		},
		Wall_Half_Grove = {
			{ mesh = 130165192026734, tex = "P", size = { 0.996, 2.001, 0.286 }, at = { 0, 1.000, 0 } },
		},
		Willow_1_Grove = {
			{ mesh = 76034894423338, tex = "P", size = { 1.433, 2.830, 2.555 }, at = { 0, 1.415, 0 } },
		},
		Willow_3_Grove = {
			{ mesh = 135483415854515, tex = "P", size = { 1.306, 2.347, 1.986 }, at = { 0, 1.173, 0 } },
		},
		Willow_Dead_1_Grove = {
			{ mesh = 118235263036754, tex = "P", size = { 0.498, 2.692, 1.812 }, at = { 0, 1.346, 0 } },
		},
		Willow_Dead_3_Grove = {
			{ mesh = 117932356743380, tex = "P", size = { 0.311, 1.906, 1.578 }, at = { 0, 0.953, 0 } },
		},
		-- Ember Lava's (art/library/converted/LavaProps.glb, re-imported 2026-11-09 for round 4)
		LavaBoulder_1 = {
			{ mesh = 136262590650396, tex = "P", size = { 1.692, 1.175, 2.104 }, at = { 0, 0.588, 0 } },
		},
		LavaBoulder_2 = {
			{ mesh = 133160707813778, tex = "P", size = { 1.797, 1.150, 2.711 }, at = { 0, 0.575, 0 } },
		},
		LavaBoulder_3 = {
			{ mesh = 110064537160234, tex = "P", size = { 2.168, 1.515, 2.170 }, at = { 0, 0.757, 0 } },
		},
		LavaFissure_1 = {
			{ mesh = 105394039797071, tex = "P", size = { 24.179, 0.300, 16.161 }, at = { 0, 0.150, 0 } },
		},
		LavaFissure_2 = {
			{ mesh = 125002752972030, tex = "P", size = { 26.336, 0.300, 13.860 }, at = { 0, 0.150, 0 } },
		},
		LavaFissure_3 = {
			{ mesh = 76556525121560, tex = "P", size = { 21.973, 0.300, 9.718 }, at = { 0, 0.150, 0 } },
		},
		LavaFissure_4 = {
			{ mesh = 134812736660128, tex = "P", size = { 28.332, 0.300, 20.371 }, at = { 0, 0.150, 0 } },
		},
		LavaLedge_1 = {
			{ mesh = 96780386446623, tex = "P", size = { 12.838, 4.062, 10.340 }, at = { 0, 2.031, 0 } },
		},
		LavaLedge_2 = {
			{ mesh = 86199735009200, tex = "P", size = { 11.596, 2.992, 10.281 }, at = { 0, 1.496, 0 } },
		},
		LavaLedge_3 = {
			{ mesh = 88768925313860, tex = "P", size = { 12.890, 4.062, 11.813 }, at = { 0, 2.031, 0 } },
		},
		LavaMass_1 = {
			{ mesh = 126158809574000, tex = "P", size = { 18.216, 8.556, 17.550 }, at = { 0, 4.278, 0 } },
		},
		LavaMass_2 = {
			{ mesh = 130222315037742, tex = "P", size = { 23.436, 8.320, 23.218 }, at = { 0, 4.160, 0 } },
		},
		LavaMass_3 = {
			{ mesh = 103337344761113, tex = "P", size = { 20.244, 9.055, 20.720 }, at = { 0, 4.527, 0 } },
		},
		LavaMass_4 = {
			{ mesh = 106613319552706, tex = "P", size = { 25.374, 7.604, 23.051 }, at = { 0, 3.802, 0 } },
		},
		LavaPeak_1 = {
			{ mesh = 74436766905220, tex = "P", size = { 10.152, 10.000, 8.059 }, at = { 0, 5.000, 0 } },
		},
		LavaPeak_2 = {
			{ mesh = 122599360401308, tex = "P", size = { 8.824, 10.000, 7.597 }, at = { 0, 5.000, 0 } },
		},
		LavaPeak_3 = {
			{ mesh = 133363040217282, tex = "P", size = { 10.911, 10.000, 7.136 }, at = { 0, 5.000, 0 } },
		},
		LavaPlate_1 = {
			{ mesh = 96189998264266, tex = "P", size = { 11.186, 0.255, 7.283 }, at = { 0, 0.128, 0 } },
		},
		LavaPlate_2 = {
			{ mesh = 122436832985513, tex = "P", size = { 11.081, 0.255, 7.896 }, at = { 0, 0.128, 0 } },
		},
		LavaPlate_3 = {
			{ mesh = 78772015733558, tex = "P", size = { 11.934, 0.255, 8.526 }, at = { 0, 0.128, 0 } },
		},
		LavaPool_1 = {
			{ mesh = 140207913557398, tex = "P", size = { 12.228, 0.550, 7.915 }, at = { 0, 0.275, 0 } },
		},
		LavaPool_2 = {
			{ mesh = 116477501453488, tex = "P", size = { 9.730, 0.550, 8.216 }, at = { 0, 0.275, 0 } },
		},
		LavaPool_3 = {
			{ mesh = 131177167201142, tex = "P", size = { 10.849, 0.550, 10.614 }, at = { 0, 0.275, 0 } },
		},
		LavaPool_4 = {
			{ mesh = 104916821881907, tex = "P", size = { 9.630, 0.550, 6.481 }, at = { 0, 0.275, 0 } },
		},
		LavaStump_1 = {
			{ mesh = 115679444372201, tex = "P", size = { 7.241, 7.591, 8.145 }, at = { 0, 3.796, 0 } },
		},
		LavaStump_2 = {
			{ mesh = 79703866409281, tex = "P", size = { 8.047, 7.169, 7.848 }, at = { 0, 3.584, 0 } },
		},
		LavaStump_3 = {
			{ mesh = 72455173056730, tex = "P", size = { 8.179, 7.469, 5.544 }, at = { 0, 3.735, 0 } },
		},
		Rock_1_Lava = {
			{ mesh = 98962634157089, tex = "P", size = { 0.485, 0.878, 0.467 }, at = { 0, 0.439, 0 } },
		},
		Rock_2_Lava = {
			{ mesh = 134260206375231, tex = "P", size = { 0.561, 0.646, 0.565 }, at = { 0, 0.323, 0 } },
		},
		Rock_3_Lava = {
			{ mesh = 84716651710154, tex = "P", size = { 0.738, 0.676, 0.803 }, at = { 0, 0.338, 0 } },
		},
		Rock_4_Lava = {
			{ mesh = 93042374472366, tex = "P", size = { 0.744, 0.784, 1.251 }, at = { 0, 0.392, 0 } },
		},
		Rock_5_Lava = {
			{ mesh = 101777159754433, tex = "P", size = { 0.663, 0.653, 0.915 }, at = { 0, 0.327, 0 } },
		},
		-- Frozen Ice's (art/library/converted/IceProps.glb, re-imported 2026-11-09 with the round-4 meshes)
		Bush_Snow_1_Ice = {
			{ mesh = 109629374321597, tex = "P", size = { 1.384, 1.271, 1.776 }, at = { 0, 0.635, 0 } },
		},
		Bush_Snow_2_Ice = {
			{ mesh = 86315062307433, tex = "P", size = { 1.362, 1.158, 1.359 }, at = { 0, 0.579, 0 } },
		},
		CommonTree_Dead_Snow_3_Ice = {
			{ mesh = 82596345673035, tex = "P", size = { 0.638, 3.002, 0.813 }, at = { 0, 1.501, 0 } },
		},
		CommonTree_Dead_Snow_4_Ice = {
			{ mesh = 84757499741988, tex = "P", size = { 0.819, 2.370, 1.082 }, at = { 0, 1.185, 0 } },
		},
		IceBank_1 = {
			{ mesh = 126232137183409, tex = "P", size = { 7.808, 2.073, 3.836 }, at = { 0, 1.036, 0 } },
		},
		IceBank_2 = {
			{ mesh = 117918765199226, tex = "P", size = { 6.870, 1.945, 3.918 }, at = { 0, 0.973, 0 } },
		},
		IceBank_3 = {
			{ mesh = 76169625155685, tex = "P", size = { 8.528, 2.175, 3.460 }, at = { 0, 1.087, 0 } },
		},
		IceBank_4 = {
			{ mesh = 90667313993296, tex = "P", size = { 5.530, 1.415, 5.321 }, at = { 0, 0.708, 0 } },
		},
		IceBoulder_1 = {
			{ mesh = 88854164745033, tex = "P", size = { 1.966, 1.172, 1.901 }, at = { 0, 0.586, 0 } },
		},
		IceBoulder_2 = {
			{ mesh = 74384128659852, tex = "P", size = { 1.969, 1.068, 2.438 }, at = { 0, 0.534, 0 } },
		},
		IceBoulder_3 = {
			{ mesh = 88280603186113, tex = "P", size = { 2.013, 1.493, 1.967 }, at = { 0, 0.747, 0 } },
		},
		IceCliff_1 = {
			{ mesh = 136765315852170, tex = "P", size = { 23.285, 14.000, 23.165 }, at = { 0, 7.000, 0 } },
		},
		IceCliff_2 = {
			{ mesh = 86644216872883, tex = "P", size = { 20.214, 12.000, 18.188 }, at = { 0, 6.000, 0 } },
		},
		IceCliff_3 = {
			{ mesh = 101552065135755, tex = "P", size = { 25.765, 15.000, 24.138 }, at = { 0, 7.500, 0 } },
		},
		IceCliff_4 = {
			{ mesh = 121018561671771, tex = "P", size = { 18.702, 11.500, 17.510 }, at = { 0, 5.750, 0 } },
		},
		IceCrack_1 = {
			{ mesh = 80188698455799, tex = "P", size = { 10.816, 0.080, 2.675 }, at = { 0, 0.040, 0 } },
		},
		IceCrack_2 = {
			{ mesh = 125015794177127, tex = "P", size = { 10.300, 0.080, 10.097 }, at = { 0, 0.040, 0 } },
		},
		IceCrack_3 = {
			{ mesh = 118693035256664, tex = "P", size = { 7.113, 0.080, 3.679 }, at = { 0, 0.040, 0 } },
		},
		IceCrack_4 = {
			{ mesh = 75168936759383, tex = "P", size = { 8.833, 0.080, 5.498 }, at = { 0, 0.040, 0 } },
		},
		IceCrystalHero_1 = {
			{ mesh = 125946448278090, tex = "P", size = { 8.410, 13.000, 7.882 }, at = { 0, 6.500, 0 } },
		},
		IceCrystalHero_2 = {
			{ mesh = 116420020984836, tex = "P", size = { 10.542, 14.000, 9.284 }, at = { 0, 7.000, 0 } },
		},
		IceCrystalHero_3 = {
			{ mesh = 126132487068728, tex = "P", size = { 7.520, 12.000, 7.977 }, at = { 0, 6.000, 0 } },
		},
		IceCrystalHero_4 = {
			{ mesh = 83385289318042, tex = "P", size = { 9.172, 13.000, 9.254 }, at = { 0, 6.500, 0 } },
		},
		IceCrystalMid_1 = {
			{ mesh = 124279069887716, tex = "P", size = { 3.495, 5.600, 3.897 }, at = { 0, 2.800, 0 } },
		},
		IceCrystalMid_2 = {
			{ mesh = 71623198352085, tex = "P", size = { 4.290, 6.200, 4.206 }, at = { 0, 3.100, 0 } },
		},
		IceCrystalMid_3 = {
			{ mesh = 82677496730144, tex = "P", size = { 3.779, 5.000, 3.841 }, at = { 0, 2.500, 0 } },
		},
		IceCrystalSmall_1 = {
			{ mesh = 138906445335210, tex = "P", size = { 2.736, 2.600, 0.946 }, at = { 0, 1.300, 0 } },
		},
		IceCrystalSmall_2 = {
			{ mesh = 73730997728307, tex = "P", size = { 1.715, 2.200, 2.374 }, at = { 0, 1.100, 0 } },
		},
		IceCrystalSmall_3 = {
			{ mesh = 77409621367242, tex = "P", size = { 1.249, 2.800, 3.282 }, at = { 0, 1.400, 0 } },
		},
		IceCrystal_1 = {
			{ mesh = 102454138987518, tex = "P", size = { 5.001, 7.000, 5.169 }, at = { 0, 3.500, 0 } },
		},
		IceCrystal_2 = {
			{ mesh = 130730608318344, tex = "P", size = { 4.797, 8.500, 5.955 }, at = { 0, 4.250, 0 } },
		},
		IceCrystal_3 = {
			{ mesh = 85632430791895, tex = "P", size = { 3.698, 6.000, 4.221 }, at = { 0, 3.000, 0 } },
		},
		IceCrystal_4 = {
			{ mesh = 133922013551164, tex = "P", size = { 6.415, 9.000, 2.708 }, at = { 0, 4.500, 0 } },
		},
		IceFar_1 = {
			{ mesh = 133913939139370, tex = "P", size = { 200.000, 40.000, 70.000 }, at = { 0, 20.000, 0 } },
		},
		IceFar_2 = {
			{ mesh = 73970256829534, tex = "P", size = { 210.000, 38.000, 70.000 }, at = { 0, 19.000, 0 } },
		},
		IceFar_3 = {
			{ mesh = 90655589383930, tex = "P", size = { 190.000, 42.000, 66.000 }, at = { 0, 21.000, 0 } },
		},
		IceFence_1 = {
			{ mesh = 102744608904169, tex = "P", size = { 5.300, 1.888, 0.595 }, at = { 0, 0.944, 0 } },
		},
		IceFence_2 = {
			{ mesh = 81600390306724, tex = "P", size = { 7.700, 1.865, 0.625 }, at = { 0, 0.932, 0 } },
		},
		IceFence_3 = {
			{ mesh = 124359585247892, tex = "P", size = { 2.900, 1.639, 0.544 }, at = { 0, 0.820, 0 } },
		},
		IceFrostBush_1 = {
			{ mesh = 125630450988296, tex = "P", size = { 4.151, 3.169, 4.480 }, at = { 0, 1.585, 0 } },
		},
		IceFrostBush_2 = {
			{ mesh = 73281625371297, tex = "P", size = { 4.079, 3.231, 4.332 }, at = { 0, 1.615, 0 } },
		},
		IceFrostBush_3 = {
			{ mesh = 91423953440207, tex = "P", size = { 4.838, 3.426, 4.356 }, at = { 0, 1.713, 0 } },
		},
		IceGrove_1 = {
			{ mesh = 107641632480211, tex = "P", size = { 11.239, 13.680, 10.221 }, at = { 0, 6.840, 0 } },
		},
		IceGrove_2 = {
			{ mesh = 123912489338479, tex = "P", size = { 11.276, 13.680, 10.314 }, at = { 0, 6.840, 0 } },
		},
		IceGrove_3 = {
			{ mesh = 114047785465322, tex = "P", size = { 9.548, 13.680, 11.849 }, at = { 0, 6.840, 0 } },
		},
		IceGrove_4 = {
			{ mesh = 88043783625549, tex = "P", size = { 11.079, 13.680, 11.093 }, at = { 0, 6.840, 0 } },
		},
		IceMound_1 = {
			{ mesh = 105548164034361, tex = "P", size = { 12.448, 2.363, 10.555 }, at = { 0, 1.181, 0 } },
		},
		IceMound_2 = {
			{ mesh = 134531357117045, tex = "P", size = { 15.390, 2.524, 13.671 }, at = { 0, 1.262, 0 } },
		},
		IceMound_3 = {
			{ mesh = 115093632959818, tex = "P", size = { 10.837, 2.807, 10.751 }, at = { 0, 1.403, 0 } },
		},
		IceMound_4 = {
			{ mesh = 71420473578672, tex = "P", size = { 13.411, 2.822, 12.015 }, at = { 0, 1.411, 0 } },
		},
		IcePatch_1 = {
			{ mesh = 101416279151980, tex = "P", size = { 10.391, 0.070, 10.050 }, at = { 0, 0.035, 0 } },
		},
		IcePatch_2 = {
			{ mesh = 114447597202875, tex = "P", size = { 12.363, 0.070, 11.291 }, at = { 0, 0.035, 0 } },
		},
		IcePatch_3 = {
			{ mesh = 112796256787864, tex = "P", size = { 10.415, 0.070, 8.727 }, at = { 0, 0.035, 0 } },
		},
		IceRidge_1 = {
			{ mesh = 98333394082224, tex = "P", size = { 34.000, 20.000, 22.000 }, at = { 0, 10.000, 0 } },
		},
		IceRidge_2 = {
			{ mesh = 107335280544453, tex = "P", size = { 36.000, 22.000, 24.000 }, at = { 0, 11.000, 0 } },
		},
		IceRidge_3 = {
			{ mesh = 138555956000103, tex = "P", size = { 32.000, 18.000, 20.000 }, at = { 0, 9.000, 0 } },
		},
		IceRidge_4 = {
			{ mesh = 131746644540245, tex = "P", size = { 38.000, 21.000, 24.000 }, at = { 0, 10.500, 0 } },
		},
		IceRidge_5 = {
			{ mesh = 113068332518628, tex = "P", size = { 30.000, 17.000, 20.000 }, at = { 0, 8.500, 0 } },
		},
		IceRock_1 = {
			{ mesh = 79678896022977, tex = "P", size = { 17.430, 10.014, 17.806 }, at = { 0, 5.007, 0 } },
		},
		IceRock_2 = {
			{ mesh = 93787167744071, tex = "P", size = { 20.489, 7.676, 19.506 }, at = { 0, 3.838, 0 } },
		},
		IceRock_3 = {
			{ mesh = 86329577672340, tex = "P", size = { 19.554, 10.282, 21.045 }, at = { 0, 5.141, 0 } },
		},
		IceRock_4 = {
			{ mesh = 87033316848003, tex = "P", size = { 15.966, 9.448, 18.858 }, at = { 0, 4.724, 0 } },
		},
		IceShard_1 = {
			{ mesh = 118215808168269, tex = "P", size = { 5.380, 5.200, 4.631 }, at = { 0, 2.600, 0 } },
		},
		IceShard_2 = {
			{ mesh = 124019687786895, tex = "P", size = { 5.393, 5.200, 5.072 }, at = { 0, 2.600, 0 } },
		},
		IceShard_3 = {
			{ mesh = 107126844783500, tex = "P", size = { 4.208, 5.200, 5.031 }, at = { 0, 2.600, 0 } },
		},
		IceShrub_1 = {
			{ mesh = 77679941456915, tex = "P", size = { 6.531, 3.946, 6.370 }, at = { 0, 1.973, 0 } },
		},
		IceShrub_2 = {
			{ mesh = 115000926197297, tex = "P", size = { 6.417, 4.078, 6.204 }, at = { 0, 2.039, 0 } },
		},
		IceSprig_1 = {
			{ mesh = 83224760780086, tex = "P", size = { 3.126, 4.022, 3.455 }, at = { 0, 2.011, 0 } },
		},
		IceSprig_2 = {
			{ mesh = 94911508092213, tex = "P", size = { 3.696, 3.945, 3.495 }, at = { 0, 1.972, 0 } },
		},
		IceSprig_3 = {
			{ mesh = 102700511981081, tex = "P", size = { 2.961, 3.572, 2.818 }, at = { 0, 1.786, 0 } },
		},
		PineTree_Snow_1_Ice = {
			{ mesh = 125182804674344, tex = "P", size = { 1.951, 2.700, 1.802 }, at = { 0, 1.350, 0 } },
		},
		PineTree_Snow_2_Ice = {
			{ mesh = 110668183415234, tex = "P", size = { 1.784, 3.568, 1.951 }, at = { 0, 1.784, 0 } },
		},
		PineTree_Snow_4_Ice = {
			{ mesh = 82081149381174, tex = "P", size = { 1.242, 3.345, 1.379 }, at = { 0, 1.673, 0 } },
		},
		PineTree_Snow_5_Ice = {
			{ mesh = 109342342407495, tex = "P", size = { 1.460, 2.695, 1.326 }, at = { 0, 1.347, 0 } },
		},
		Rock_Snow_1_Ice = {
			{ mesh = 95597779943119, tex = "P", size = { 0.485, 0.984, 0.467 }, at = { 0, 0.492, 0 } },
		},
		Rock_Snow_3_Ice = {
			{ mesh = 138690893762289, tex = "P", size = { 0.738, 0.579, 0.803 }, at = { 0, 0.289, 0 } },
		},
		Rock_Snow_4_Ice = {
			{ mesh = 136361339169131, tex = "P", size = { 0.744, 0.798, 1.251 }, at = { 0, 0.399, 0 } },
		},
		Rock_Snow_5_Ice = {
			{ mesh = 95003282720416, tex = "P", size = { 0.663, 0.606, 0.915 }, at = { 0, 0.303, 0 } },
		},
		Rock_Snow_6_Ice = {
			{ mesh = 87595149976287, tex = "P", size = { 0.909, 0.737, 1.142 }, at = { 0, 0.368, 0 } },
		},
		TreeStump_Snow_Ice = {
			{ mesh = 106845180938282, tex = "P", size = { 1.360, 0.622, 1.031 }, at = { 0, 0.311, 0 } },
		},
		Willow_Dead_Snow_1_Ice = {
			{ mesh = 94801897905922, tex = "P", size = { 0.498, 2.692, 1.808 }, at = { 0, 1.346, 0 } },
		},
		Willow_Dead_Snow_3_Ice = {
			{ mesh = 133980749855049, tex = "P", size = { 0.301, 1.906, 1.578 }, at = { 0, 0.953, 0 } },
		},
		Willow_Dead_Snow_4_Ice = {
			{ mesh = 81598078693718, tex = "P", size = { 1.010, 2.719, 2.588 }, at = { 0, 1.359, 0 } },
		},
		WoodLog_Snow_Ice = {
			{ mesh = 118142207603457, tex = "P", size = { 0.627, 0.586, 2.494 }, at = { 0, 0.293, 0 } },
		},
	},
	-- how long a stage waits for the meshes before it leaves a library prop out (seconds)
	WaitSeconds = 15,
}

-- The waving flag (the owner, 2026-11-03: "thin, flying softly like a real flag"): tools/blender/flag.py, imported by the
-- owner; the server puts it together from these meshes (server/WavingFlag) and the client waves it (client/FlagWave).
-- Offsets are from the pole's foot, in studs of the imported model (ModelHeight tall, cloth flying along -X).
Config.Flag = {
	PoleMesh = "rbxassetid://112369592171464",
	FinialMesh = "rbxassetid://86258054180806",
	ClothMesh = "rbxassetid://99599710505900",
	ClothTexture = "rbxassetid://71768414532152",
	ModelHeight = 10.58,
	PoleAt = { 0, 5, 0 },
	FinialAt = { 0, 10.23, 0 },
	ClothAt = { -2.517, 8.25, 0 },
	-- the first bone at the cloth's pole edge, then Bones in a chain BoneStep apart (as in the import)
	BoneAt = { -0.117, 8.25, 0 },
	Bones = 8,
	BoneStep = 0.6,
	PoleColour = { 110, 70, 38 },
	FinialColour = { 232, 182, 64 },
	-- the flag of the training ground stands on its FlagBase this tall
	TrainingHeight = 9.5,
}

-- The zombie slimes outside the village (the owner, 2026-11-02, docs/ECONOMY.md).
Config.Zombies = if script then require(script.Parent.ConfigZombies) else require("./ConfigZombies")

-- The Slime Dungeon (the owner, 2026-11-04): a private arena where the team fights monsters that come in waves; each wave
-- a set number of them, stronger from wave to wave and from dungeon level to dungeon level. The numbers are the original's
-- (docs/reference/02-battle.md §5 waves, §6 level ladder, §7 roster, §13 loot); the rules are shared/Dungeon.
Config.Dungeon = if script then require(script.Parent.ConfigDungeon) else require("./ConfigDungeon")

-- Gear and the Smithy (the owner, 2026-11-04; docs/SMITHY.md): three slots on every slime, four tiers, a piece each crafted
-- from dungeon drops at the Blacksmith. Gear adds flat points to a slime's stats in every fight (shared/Gear.bonus); it
-- never changes the slime's own stats, level or price. Rules: shared/Gear; requests: shared/VillageRequests.
Config.Smithy = {
	-- A gear, recipe or slot id sent by a client is at most this many characters (a request longer than that is refused).
	IdMaxLength = 40,
	-- The slots in the order the sheet shows them, and what each piece of a slot is called on screen.
	Slots = { "hand", "head", "tail" },
	-- (the owner, 2026-11-04: the hand slot shows as Weapon, the tail slot as Charm; the saved ids stay)
	SlotNames = { hand = "Weapon", head = "Head", tail = "Charm" },
	-- Tiers from the weakest. The rarity colour is only for screens (the original's veto: no glow in the world).
	TierOrder = { "wood", "iron", "core", "bramble" },
	Tiers = {
		wood = { rarity = "Common", colour = "#8f97a0" },
		iron = { rarity = "Uncommon", colour = "#3a9b3a" },
		core = { rarity = "Epic", colour = "#8a4fd0" },
		bramble = { rarity = "Mythic", colour = "#f08a24" },
	},
	-- Every piece of gear: its name, slot, tier and the flat points it adds (stat keys of shared/Stats; a stat left out adds
	-- nothing). A hand piece is a weapon, a head piece a helm, a tail piece a charm.
	GearOrder = {
		"sword-wood",
		"helm-wood",
		"charm-wood",
		"sword-iron",
		"helm-iron",
		"charm-iron",
		"sword-core",
		"helm-core",
		"charm-core",
		"sword-bramble",
		"helm-bramble",
		"charm-bramble",
	},
	Gear = {
		-- (`icon`: ChatGPT, 2026-11-04, in the style of the drop icons; art/icons/gear_*.png)
		["sword-wood"] = {
			name = "Wooden Sword",
			slot = "hand",
			tier = "wood",
			stats = { attack = 1 },
			icon = "rbxassetid://80279447540538",
		},
		["helm-wood"] = {
			name = "Wooden Helm",
			slot = "head",
			tier = "wood",
			stats = { defence = 1 },
			icon = "rbxassetid://109171481258060",
		},
		["charm-wood"] = {
			name = "Twig Charm",
			slot = "tail",
			tier = "wood",
			stats = { speed = 1 },
			icon = "rbxassetid://85641589605360",
		},
		["sword-iron"] = {
			name = "Iron Sword",
			slot = "hand",
			tier = "iron",
			stats = { attack = 2 },
			icon = "rbxassetid://73489897072784",
		},
		["helm-iron"] = {
			name = "Iron Helm",
			slot = "head",
			tier = "iron",
			stats = { defence = 2, hp = 10 },
			icon = "rbxassetid://115651104665931",
		},
		["charm-iron"] = {
			name = "Iron Charm",
			slot = "tail",
			tier = "iron",
			stats = { speed = 1, hp = 10 },
			icon = "rbxassetid://99177471454710",
		},
		["sword-core"] = {
			name = "Core Blade",
			slot = "hand",
			tier = "core",
			stats = { attack = 4, speed = 1 },
			icon = "rbxassetid://96392644637640",
		},
		["helm-core"] = {
			name = "Core Helm",
			slot = "head",
			tier = "core",
			stats = { defence = 3, hp = 30 },
			icon = "rbxassetid://76647945648082",
		},
		["charm-core"] = {
			name = "Core Charm",
			slot = "tail",
			tier = "core",
			stats = { attack = 1, speed = 3 },
			icon = "rbxassetid://105675835742715",
		},
		["sword-bramble"] = {
			name = "Bramble Sword",
			slot = "hand",
			tier = "bramble",
			stats = { attack = 5, speed = 1, hp = 20 },
			icon = "rbxassetid://133843312835996",
		},
		["helm-bramble"] = {
			name = "Bramble Crown",
			slot = "head",
			tier = "bramble",
			stats = { attack = 2, defence = 4, hp = 40 },
			icon = "rbxassetid://93917438503786",
		},
		["charm-bramble"] = {
			name = "Bramble Charm",
			slot = "tail",
			tier = "bramble",
			stats = { defence = 2, speed = 3, hp = 30 },
			icon = "rbxassetid://131165304696818",
		},
	},
	-- One recipe a piece (the recipe's id is the piece's id): `materials` are keys of Config.Dungeon.Materials with how many,
	-- `coins` the price. A craft takes them once and adds one piece to the bag (an all-or-nothing step).
	Recipes = {
		["sword-wood"] = { gear = "sword-wood", materials = { wood = 3 }, coins = 0 },
		["helm-wood"] = { gear = "helm-wood", materials = { wood = 4 }, coins = 0 },
		["charm-wood"] = { gear = "charm-wood", materials = { wood = 2 }, coins = 0 },
		["sword-iron"] = { gear = "sword-iron", materials = { ore = 4, wood = 2 }, coins = 25 },
		["helm-iron"] = { gear = "helm-iron", materials = { ore = 5 }, coins = 25 },
		["charm-iron"] = { gear = "charm-iron", materials = { ore = 3, wood = 2 }, coins = 25 },
		["sword-core"] = { gear = "sword-core", materials = { ore = 8, rare_part = 6, monster_core = 1 }, coins = 150 },
		["helm-core"] = { gear = "helm-core", materials = { ore = 8, rare_part = 6, monster_core = 1 }, coins = 150 },
		["charm-core"] = { gear = "charm-core", materials = { wood = 6, rare_part = 6, monster_core = 1 }, coins = 150 },
		["sword-bramble"] = {
			gear = "sword-bramble",
			materials = { boar_tusk = 4, rare_part = 12, monster_core = 2, boss_essence = 1 },
			coins = 400,
		},
		["helm-bramble"] = {
			gear = "helm-bramble",
			materials = { boar_tusk = 4, rare_part = 12, monster_core = 2, boss_essence = 1 },
			coins = 400,
		},
		["charm-bramble"] = {
			gear = "charm-bramble",
			materials = { boar_tusk = 4, rare_part = 12, monster_core = 2, boss_essence = 1 },
			coins = 400,
		},
	},
}

Config.Growth = {
	-- Grow-up: round((Base + max(0, level - 1) * PerLevel) * Factor ^ min(MaxLevel, upgradeLevel)) → 303 s at level 4.
	GrowUpSeconds = 300,
	GrowUpPerLevelSeconds = 1,
	UpgradeFactor = 0.95,
	UpgradeMaxLevel = 20,
	-- A hatchling is drawn at BabyScale and eases to 1 while it grows.
	BabyScale = 0.62,
	-- A slime hatched while the tutorial runs grows up in this long (its birth time is set back; the owner, 2026-11-03).
	TutorialGrowUpSeconds = 30,
}

Config.Luck = {
	-- New-player luck after the tutorial ends: ×First for one window, ×Second for the next, then ×1. It is a REAL factor on
	-- the chances, outside the curve below.
	WindowSeconds = 30 * 60,
	First = 5,
	Second = 3,
	ServerBonus = 1,
	-- Luck LABELS (docs/MONETIZATION.md §1), each multiplying the others: a Luck Potion (30 minutes, sold), VIP, the highest
	-- Perm Luck pass (Config.Robux.Products, field `luck`) and the server's bonus. The label becomes the real factor on the
	-- chances by a falling curve, real = 1 + PerDoubling * log2(label): each doubling adds this share of the base chance.
	Potion = 2,
	Vip = 1.5,
	PerDoubling = 0.4,
}

Config.Farm = {
	-- (the owner, 2026-11-04: eight, so a new player fills a team of TeamSize and still has slimes to work and breed)
	StarterCount = 8,
	StarterColour = "navy",
	StartingFood = 20,
	StartingCoins = 0,
	-- Pantry: Base + foodStorage level * PerLevel.
	FoodCapacityBase = 100,
	FoodCapacityPerLevel = 100,
	MaxHunger = 100,
	StartingHunger = 100,
	-- hunger <= this is "hungry" (and eats); <= 0 is "starving".
	HungryThreshold = 35,
	-- Workstation definition ids in buy order; the farm keeps one station entry for each.
	Stations = { "ws.berry-bush", "ws.farm-plot", "ws.fishing-pond", "ws.cooking-kitchen" },
	StartUnlockedStations = { "ws.berry-bush" },
	StationMaxWorkers = 3,
	-- Starter gear, all in the inventory: { item id, definition id }.
	StarterItems = {
		{ "item-sword-1", "sword" },
		{ "item-bow-1", "bow" },
		{ "item-staff-1", "healing_staff" },
		{ "item-staff-2", "healing_staff-2" },
		{ "item-shield-1", "shield" },
		{ "item-focus-1", "arcane_focus" },
		{ "item-focus-2", "arcane_focus-2" },
		{ "item-kit-1", "alchemy_kit" },
		{ "item-kit-2", "alchemy_kit-2" },
	},
	-- Gear retired from the original; stripped from loaded farms.
	RemovedItemDefinitions = { "sword-2", "bow-2", "shield-2" },
	-- The player's own avatar slime (not a farm slime).
	AvatarName = "You",
	AvatarNameMaxLength = 16,
	AvatarStats = { attack = 1, defence = 1, speed = 1, hp = 10 },
	AvatarFrame = "wood",
	AvatarBackground = "meadow",
	AvatarHatchesPerRank = 50,
	-- Secret art with wide features ("big" in SecretRecipes) draws its body this much larger.
	SecretBodyBoost = 1.2,
	-- A loaded farm keeps at most max(population limit, this) slimes: only absurd arrays are cut.
	RepairSlimeHardCap = 500,
}

-- ===== Living village (docs/GAMEPLAY.md §§3-8) =====
Config.Village = {
	Areas = { "fishing", "garden", "kitchen", "pantry", "training", "breeding" },
	Traits = { "hardworking", "lazy", "playful", "shy", "chatty", "glutton" },
	MaxFriends = 8,
	StartLevel = 1,
	-- A published progress clock keeps its times while a new estimate lies within this many seconds (the
	-- simulation steps once a second; this stops a running clock from rewriting its attributes every tick).
	ClockKeepSeconds = 0.6,
	MaxLevel = 50,
	-- Smooth capacity progression: interpolate between these checkpoints. Every village level adds 1 or 2 slimes,
	-- never a sudden 15-slime jump (the owner, 2026-11-04: "my village is level 6 and the slime limit did not grow";
	-- levels 1-6 used to stay at 12). Keep all old-save slimes.
	PopulationProgression = {
		{ level = 1, cap = 12 },
		{ level = 20, cap = 31 },
		{ level = 30, cap = 43 },
		{ level = 40, cap = 57 },
		{ level = 50, cap = 72 },
	},
	-- The owner, 2026-11-04: the first 20 levels were too slow for what a new player earns (a camp-1 fight pays about
	-- 800 all game). Halved there: 1-2 is a fifth of a fight, 19-20 about two fights. Level 25 eases into the old curve.
	UpgradePrices = {
		{ level = 1, price = 150 },
		{ level = 5, price = 260 },
		{ level = 10, price = 550 },
		{ level = 15, price = 1100 },
		{ level = 19, price = 1700 },
		{ level = 25, price = 6000 },
		{ level = 30, price = 14000 },
		{ level = 35, price = 24000 },
		{ level = 39, price = 37000 },
		{ level = 45, price = 67000 },
		{ level = 49, price = 99000 },
	},
	CoinCapMin = 2000,
	-- (was 3 before the early prices were halved on 2026-11-04; 6 keeps the vault where it was)
	CoinCapPriceFactor = 6,
	OfflineCapSeconds = 8 * 60 * 60,
	StepSeconds = 60,
	-- How long a dead slime waits to be revived with food before it is lost for good (the owner, 2026-11-02).
	GhostSeconds = 15 * 60,
	WalkSpeed = 1.5 / 0.55,
	WalkPerSpeed = 0.02,
	HopSeconds = 0.55,
	HopStuds = 1.5,
	-- (1: the railed dock from level 21 is too narrow for a wider agent; the jelly body squeezes past rails)
	PathMinRadius = 1,
	PathRadiusPerScale = 0.8,
	PathHeightPerScale = 3,
	PathWaypointStuds = 3,
	PathWaterCost = 1000000,
	PathStraightTolerance = 0.07,
	PathPointEpsilon = 0.08,
	PathCacheSeconds = 30,
	PathRefreshSeconds = 3,
	PathRefreshStuds = 3,
	PathWarningSeconds = 30,
	PathAvoidStuds = 2.5,
	PathWaitSeconds = 0.55,
	PathConflictPasses = 3,
	CarryPromptDistance = 10,
	CarryPromptHeight = 1.5,
	CarryPromptAboveObject = 1,
	CarryPromptRefreshSeconds = 0.5,
	CarryPromptHoldSeconds = 0,
	CarryReachStuds = 12,
	CarryModelScale = 0.42,
	CarryHeadOffset = 0.7,
	-- held in the player's hand: the item's middle sits this share of its half-height below the hand's end, and
	-- this many studs in front of it
	CarryHandSink = 0.6,
	CarryHandForward = 0.3,
	DevFreeUpgrades = false,
	TickSeconds = 1,
	RequestsPerSecond = 4,
	SpotNames = {
		Work = { "WorkSpot1", "WorkSpot2", "WorkSpot3", "WorkSpot4" },
		Nest = { "Nest1", "Nest2", "Nest3", "Nest4", "Nest5", "Nest6" },
		Incubator = { "Incubator1", "Incubator2", "Incubator3", "Incubator4", "Incubator5", "Incubator6" },
		Storehouse = { "StorehouseDoor", "PantryDoor", "Entrance" },
		StorehouseModels = { "PantryDoor", "Door" },
		-- the Deposit store prompt: the pantry's sign board, else its door
		StorehouseSign = { "SignPantry", "PantryDoor", "Door" },
		Box = { "FishBin", "VegBin", "CollectionBox", "FishBucket", "HarvestBox", "DishBox" },
		CounterModels = { "KitchenCounter", "Counter", "PrepCounter" },
		FridgeModels = { "Fridge", "Refrigerator" },
		-- the real fridges among the kitchen's props: the Fridge prompt exists only with one of them
		FridgeProps = { "IceBox", "GooFridge", "Fridge", "Refrigerator" },
		NapModels = { "Bench", "Stump", "Log" },
		FountainModels = { "Well", "StoneWell", "Fountain" },
		CampfireModels = { "Campfire", "FirePit", "Fire" },
		Plaza = { "Plaza", "PlazaCentre" },
		Gate = { "Gate", "FrontGate" },
		Counter = { "KitchenCounter", "Counter", "WorkSpot1" },
		Fridge = { "Fridge", "Refrigerator" },
		Nursery = { "Nursery", "NurserySpot", "Nest1" },
		Nap = { "CampfireSeat", "Bench", "Seat" },
		Fountain = { "Fountain", "VillageFountain", "Well" },
		Flowers = { "FlowerBed", "Planter", "Flowers" },
		-- (not a fishing place: a watcher must not stand where the fisher casts)
		Pond = { "PondEdge", "Dock" },
		Campfire = { "Campfire", "FirePit" },
	},
	SpotSearchStuds = 30,
	SpotDoorOffset = 2,
	-- Near-door candidates before wider/forward detours if the obvious point is blocked.
	SpotOutsideOffsets = { { 0, 0 }, { 0, 2 }, { -3, 2 }, { 3, 2 }, { -6, 4 }, { 6, 4 } },
	SpotCounterOffsetX = -2,
	SpotFridgeOffsetX = 4,
	SpotBoxOffsetX = -4,
	SpotNapOffset = 5,
	-- Standing on the ground (the owner, 2026-10-29: "slimes have collision and do not go through objects").
	-- A ray looks for the ground from GroundProbeUp above a point down to GroundProbeDown below it.
	GroundProbeUp = 3,
	GroundProbeDown = 8,
	-- How far below a point in the air (beside a player on a roof) the floor is looked for.
	FloorProbeDown = 60,
	-- (a ball, not a thin ray: a ray falls through the gaps between dock planks into the water)
	GroundProbeRadius = 0.6,
	-- A path waypoint looks for the floor from this little above itself (never from above a roof).
	PathGroundProbe = 0.5,
	-- The box a standing slime needs (a grown slime is about 3 studs high and wide); it starts SpotClearLift
	-- above the feet so a kerb or a plank edge does not count as a wall.
	SpotClearWidth = 2.6,
	SpotClearHeight = 2.2,
	SpotClearLift = 0.5,
	-- A standing place may be at most this much higher than the spot it came from (no slime on a log or a lid).
	SpotMaxRise = 0.6,
	-- A spread or a step short of a partner may be at most this much lower than the spot it spreads from.
	SpotMaxDrop = 1,
	-- A spread standing place keeps at least this far from where another slime stands or is going.
	SpotApartStuds = 4,
	-- A spot inside a model moves out in rings this far apart, up to this many rings.
	SpotSettleStep = 1,
	SpotSettleRings = 14,
	SpotSettleMinAngles = 8,
	SpotSettleAnglesPerRing = 6,
	-- A spot moved further than this faces the thing it was moved out of.
	SpotFacePull = 0.5,
	-- From the middle of a bin to the slime that tosses fish or vegetables into it (a bin is about 3 studs
	-- wide, a slime too: this leaves a step of about one and a half studs between them).
	BinStandStuds = 4.5,
	-- A gardener stands this far from the middle of the plant it tends.
	CropStandStuds = 2.2,
	-- Taking from a bin or a stand, and tossing into a bin (seconds; the item flies in an arc).
	TakeSeconds = 0.9,
	TossSeconds = 0.8,
	-- A slime assigned to a work place pops into it (the owner, 2026-10-29: no walk there).
	PopSeconds = 0.5,
	-- How often the breeding area's footprint is measured again (a courting slime strolls only inside it).
	BreedingBoxSeconds = 5,
	-- An item tossed flies this high above the straight line between the slime and the bin.
	TossArcStuds = 2.5,
	-- Seats (the owner, 2026-10-30: resting and sleeping slimes sit on the benches' seats, never on a backrest).
	-- Models with these exact names anywhere in the plot are seats (every era's bench, logs and stumps), and so are
	-- the parts named SeatParts (the area stages' plank benches, with their BenchBack beside them).
	SeatModels = { "LogBench", "ParkBench", "IronBench", "ModernBench", "MarbleBench", "Stump", "Bench" },
	SeatParts = { "BenchSeat" },
	-- A part bench's back and legs are the plank's siblings within this many studs.
	SeatPartReach = 1.6,
	-- Rays from above on a SeatProbeGrid x SeatProbeGrid grid across the footprint; a seat surface lies between
	-- SeatMinRise and SeatMaxRise above the ground and faces up (normal Y at least SeatFlatNormal).
	SeatProbeGrid = 9,
	SeatMinRise = 0.6,
	SeatMaxRise = 3.2,
	SeatFlatNormal = 0.5,
	-- Hits within SeatBand of each other are one flat surface; hits more than SeatBackRise above the seat are the
	-- backrest (the slime faces away from it).
	SeatBand = 0.35,
	SeatBackRise = 0.6,
	-- The fewest hits that make a seat, the width one sitting slime needs, and the most slimes on one seat.
	SeatMinHits = 3,
	SeatPlaceStuds = 2.4,
	SeatMaxPlaces = 3,
	-- A seat without a back faces the campfire within this many studs, else the plaza.
	SeatCampfireStuds = 16,
	-- The slime walks to the ground this far in front of its place, then hops up.
	SeatApproachStuds = 2.2,
	-- A slime warming itself takes a seat within this distance of the fire; else it stands by the fire.
	SeatWarmStuds = 14,
}

-- Slimes choose a destination rather than receiving instantaneous food/energy effects.
Config.Brain = {
	CarryAmount = 3,
	ThinksPerTick = 4,
	MaxFriends = 3,
	NearbyStuds = 25,
	PlayerStuds = 30,
	StopStuds = 4,
	SpotSpread = 4,
	SpotSpreadPlaces = 6,
	IdleSeconds = 6,
	Noise = 2,
	ErrandScore = 35,
	-- Added to every carrying errand whatever the trait (a full bin, a dish to put away, an egg to move): above the
	-- calm pastimes of any trait, so free slimes haul while things wait; only a bored playful or chatty slime may
	-- play or chat first (the owner, 2026-10-30: "many idle slimes but they do not take hauling jobs").
	ErrandUrgency = 70,
	EggScore = 45,
	BabyFoodScore = 52,
	PlayScore = 12,
	SocialScore = 10,
	DailyScore = 8,
	PlayerScore = 14,
	FunGain = 10,
	FunScore = 20,
	FriendGain = 2,
	FriendLoss = 1,
	Duration = {
		ghost = 20,
		sleep = 12,
		eat = 4,
		nursery = 8,
		court = 8,
		work = 10,
		carryBox = 3,
		carryKitchen = 3,
		carryDish = 3,
		carryEgg = 3,
		feedBaby = 4,
		playBaby = 8,
		walkBaby = 10,
		chat = 6,
		tag = 8,
		greet = 4,
		argue = 6,
		makeup = 6,
		watchFish = 8,
		flowers = 8,
		splash = 6,
		warm = 10,
		wander = 8,
		player = 5,
	},
	TraitWeights = {
		hardworking = { errands = 4, care = 1, play = 0.4, social = 0.7, daily = 0.7 },
		lazy = { errands = 0.3, care = 0.6, play = 0.6, social = 0.8, daily = 4 },
		playful = { errands = 0.2, care = 2, play = 5, social = 1.5, daily = 1 },
		shy = { errands = 1.2, care = 1.5, play = 0.8, social = 0.3, daily = 2 },
		chatty = { errands = 0.5, care = 1, play = 1.3, social = 6, daily = 0.7 },
		glutton = { errands = 2, care = 1.2, play = 0.5, social = 0.8, daily = 2 },
	},
}

Config.Needs = {
	Max = 100,
	Start = 100,
	-- Balanced for starter SPD, not the fastest possible worker.
	IdleFullnessPerMinute = 1.5,
	WorkFullnessPerMinute = 2.25,
	IdleEnergyPerMinute = 0.5,
	WorkEnergyPerMinute = 2,
	-- (was 5: a nap from Tired to Rested took 14 minutes, the longest wait of a fighting team; the owner, 2026-11-04)
	SleepEnergyPerMinute = 10,
	FunFallPerMinute = 0.5,
	BabyFactor = 0.5,
	WantsFood = 50,
	PairFullness = 60,
	Hungry = 25,
	HungryWorkFactor = 0.5,
	Tired = 20,
	Rested = 90,
}

-- Raw food kinds (the owner, 2026-10-30: several kinds of fish and vegetables with rarities, for recipes later).
-- `group` says where it comes from (fishing or the garden), `weight` is its share of one roll within its group
-- (a group's weights add up to 100, so a weight is a percent), `fullness` what a slime gains eating it raw, `crop` the
-- CropKit model prefix of a vegetable (Carrot4 is the ripe carrot). Ids `fish`, `carrot` and `cabbage` are the first
-- kinds and keep their saves; every other id is new. The model of a kind is ClientKit.Items.<id>.
local FoodKinds = {
	fish = { name = "Koi", group = "fish", rarity = "common", fullness = 25, weight = 40, topWeight = 25 },
	blueFish = { name = "Blue Fish", group = "fish", rarity = "common", fullness = 22, weight = 30, topWeight = 20 },
	trout = { name = "Trout", group = "fish", rarity = "uncommon", fullness = 28, weight = 18, topWeight = 30 },
	salmon = { name = "Salmon", group = "fish", rarity = "rare", fullness = 40, weight = 8, topWeight = 13 },
	pufferfish = { name = "Pufferfish", group = "fish", rarity = "rare", fullness = 40, weight = 3, topWeight = 7 },
	goldenCarp = { name = "Golden Carp", group = "fish", rarity = "epic", fullness = 60, weight = 1, topWeight = 5 },
	carrot = {
		name = "Carrot",
		group = "veg",
		rarity = "common",
		fullness = 20,
		weight = 30,
		topWeight = 23,
		crop = "Carrot",
	},
	cabbage = {
		name = "Cabbage",
		group = "veg",
		rarity = "common",
		fullness = 20,
		weight = 30,
		topWeight = 22,
		crop = "Cabbage",
	},
	tomato = {
		name = "Tomato",
		group = "veg",
		rarity = "uncommon",
		fullness = 24,
		weight = 18,
		topWeight = 17,
		crop = "Tomato",
	},
	corn = {
		name = "Corn",
		group = "veg",
		rarity = "uncommon",
		fullness = 28,
		weight = 12,
		topWeight = 13,
		crop = "Corn",
	},
	pumpkin = {
		name = "Pumpkin",
		group = "veg",
		rarity = "rare",
		fullness = 40,
		weight = 8,
		topWeight = 20,
		crop = "Pumpkin",
	},
	starfruit = {
		name = "Starfruit",
		group = "veg",
		rarity = "epic",
		fullness = 60,
		weight = 2,
		topWeight = 5,
		crop = "Starfruit",
	},
}
local FishOrder = { "fish", "blueFish", "trout", "salmon", "pufferfish", "goldenCarp" }
local VegOrder = { "carrot", "cabbage", "tomato", "corn", "pumpkin", "starfruit" }
local FoodRaw: { [string]: number } = {}
local FoodRawOrder: { string } = {}
for _, list in { FishOrder, VegOrder } do
	for _, id in list do
		FoodRaw[id] = (FoodKinds :: any)[id].fullness
		table.insert(FoodRawOrder, id)
	end
end

Config.Food = {
	Kinds = FoodKinds,
	FishOrder = FishOrder,
	VegOrder = VegOrder,
	Rarities = {
		common = { name = "Common", colour = "#7d6a55", order = 1 },
		uncommon = { name = "Uncommon", colour = "#3f9a38", order = 2 },
		rare = { name = "Rare", colour = "#2f7fd0", order = 3 },
		epic = { name = "Epic", colour = "#9a45c8", order = 4 },
	},
	-- Raw fullness by id and the order every store, bin and picker walks (derived from Kinds above).
	Raw = FoodRaw,
	RawOrder = FoodRawOrder,
	-- A vegetable's seedling, young and growing stages use these CropKit models (<prefix>1..3) when it has none of
	-- its own; only the ripe stage (<crop>4) is its own model.
	SproutCrop = "Cabbage",
	DishRarities = {
		common = { kitchenLevel = 1, percent = 4, buffSeconds = 600, cookSeconds = 120, price = 1000 },
		uncommon = { kitchenLevel = 8, percent = 6, buffSeconds = 660, cookSeconds = 150, price = 1100 },
		rare = { kitchenLevel = 20, percent = 9, buffSeconds = 780, cookSeconds = 200, price = 1300 },
		epic = { kitchenLevel = 35, percent = 12, buffSeconds = 900, cookSeconds = 300, price = 2000 },
	},
	DefaultRecipe = "grilledFish",
	CookReservePerSlime = 1,
	Dishes = {
		grilledFish = {
			name = "Grilled Fish",
			ingredients = { fish = 2 },
			stat = "attack",
			fullness = 60,
			rarity = "common",
		},
		veggieStew = {
			name = "Veggie Stew",
			ingredients = { carrot = 2, cabbage = 1 },
			stat = "defence",
			fullness = 65,
			rarity = "common",
		},
		blueFishSkewer = {
			name = "Blue Fish Skewer",
			ingredients = { blueFish = 2 },
			stat = "speed",
			fullness = 60,
			rarity = "common",
		},
		fishVegSoup = {
			name = "Fish and Veggie Soup",
			ingredients = { fish = 1, carrot = 1, cabbage = 1 },
			stat = "hp",
			fullness = 90,
			rarity = "common",
		},
		bakedTrout = {
			name = "Baked Trout",
			ingredients = { trout = 1, fish = 1 },
			stat = "attack",
			fullness = 70,
			rarity = "uncommon",
		},
		cornChowder = {
			name = "Corn Chowder",
			ingredients = { corn = 1, cabbage = 1, carrot = 1 },
			stat = "defence",
			fullness = 85,
			rarity = "uncommon",
		},
		sweetCornSalad = {
			name = "Sweet Corn Salad",
			ingredients = { corn = 1, tomato = 1 },
			stat = "speed",
			fullness = 70,
			rarity = "uncommon",
		},
		tomatoFishStew = {
			name = "Tomato Fish Stew",
			ingredients = { tomato = 1, blueFish = 1 },
			stat = "hp",
			fullness = 75,
			rarity = "uncommon",
		},
		salmonSteak = {
			name = "Salmon Steak",
			ingredients = { salmon = 1, tomato = 1 },
			stat = "attack",
			fullness = 80,
			rarity = "rare",
		},
		pumpkinStew = {
			name = "Pumpkin Stew",
			ingredients = { pumpkin = 1, corn = 1 },
			stat = "defence",
			fullness = 85,
			rarity = "rare",
		},
		pufferfishRolls = {
			name = "Pufferfish Rolls",
			ingredients = { pufferfish = 1, cabbage = 1 },
			stat = "speed",
			fullness = 80,
			rarity = "rare",
		},
		salmonPumpkinBisque = {
			name = "Salmon Pumpkin Bisque",
			ingredients = { salmon = 1, pumpkin = 1 },
			stat = "hp",
			fullness = 100,
			rarity = "rare",
		},
		goldenCarpFeast = {
			name = "Golden Carp Feast",
			ingredients = { goldenCarp = 1, salmon = 1 },
			stat = "attack",
			fullness = 100,
			rarity = "epic",
		},
		starfruitGlazedPuffer = {
			name = "Starfruit Glazed Puffer",
			ingredients = { starfruit = 1, pufferfish = 1 },
			stat = "defence",
			fullness = 100,
			rarity = "epic",
		},
		starfruitTart = {
			name = "Starfruit Tart",
			ingredients = { starfruit = 1, pumpkin = 1 },
			stat = "speed",
			fullness = 100,
			rarity = "epic",
		},
		goldenBanquet = {
			name = "Golden Banquet",
			ingredients = { goldenCarp = 1, starfruit = 1 },
			stat = "hp",
			fullness = 100,
			rarity = "epic",
		},
	},
	DishOrder = {
		"grilledFish",
		"veggieStew",
		"blueFishSkewer",
		"fishVegSoup",
		"bakedTrout",
		"cornChowder",
		"sweetCornSalad",
		"tomatoFishStew",
		"salmonSteak",
		"pumpkinStew",
		"pufferfishRolls",
		"salmonPumpkinBisque",
		"goldenCarpFeast",
		"starfruitGlazedPuffer",
		"starfruitTart",
		"goldenBanquet",
	},
	Start = { fish = 10, carrot = 10 },
	StorehouseBase = 100,
	StorehousePerLevel = 20,
	FridgeBase = 20,
	FridgePerLevel = 4,
	CounterCapacity = 10,
}

Config.Work = {
	Areas = { "fishing", "garden", "kitchen", "training" },
	SlotLevels = { 11, 21, 31 },
	BaseSlots = 1,
	BoxCapacity = 10,
	CycleSeconds = { fishing = 60, garden = 240, kitchen = 120, training = 90 },
	CycleLevelFactor = 0.99,
	FishingYield = 1,
	SpeedBonusPerSpd = 0.05,
	SpeedBonusMax = 3,
	GardenPlotCount = 20,
	GardenMaxPlotCount = 60,
	GardenStageSeconds = 75,
	GardenDryGrowthFactor = 0.15,
	GardenWaterBoostSeconds = 12,
	-- Six tending actions per harvest: 3600 / (6 * 13.5) ~= 44 vegetables/hour, near the old 45.
	GardenActionSeconds = 13.5,
	FishCastSeconds = 3,
	FishReelSeconds = 3,
	WorkDropSeconds = 2,
	GardenCropScaleStart = 0.78,
	GardenCropGrowSteps = 5,
	GardenCropGrowStepSeconds = 0.06,
	GardenCropLift = 0.2,
	-- A crop stands on its bed: the soil is found by a ray from GardenSoilProbeUp above the marker down
	-- GardenSoilProbeDown below it, and the crop's lowest point goes GardenCropSink into it.
	GardenSoilProbeUp = 1.5,
	GardenSoilProbeDown = 4,
	GardenCropSink = 0.05,
	WorkToolOffset = 0.55,
	WorkRodTiltDegrees = 26,
	WorkHoeTiltDegrees = 40,
	WorkWaterTiltDegrees = 70,
	WorkBobHz = 1.2,
	WorkBobStuds = 0.12,
	WorkShakeHz = 2.6,
	WorkShakeDegrees = 14,
	WorkDropsPerWater = 3,
	WorkWaterDropTexture = "rbxasset://textures/particles/sparkles_main.dds",
	WorkWaterDropColour = { 130, 205, 255 },
	WorkWaterDropSize = 0.14,
	WorkWaterDropLifetime = 0.4,
	WorkWaterDropSpeed = 1.6,
	WorkWaterDropGravity = 5,
	WorkDropDistance = 0.65,
	WorkToolScale = 0.55,
	KitchenYield = 1,
}

-- Short, client-only construction reveal. The server changes gameplay immediately;
-- clients fade changed stage pieces into view, with a focused celebration on the upgraded area.
Config.UpgradeFx = {
	Tag = "AreaUpgradeReveal",
	PartAttribute = "UpgradeFxPart",
	-- the biggest changed pieces fade in; anything past this just appears (too small to notice)
	MaxChangedParts = 150,
	OutlinedParts = 6,
	BurstMaxStuds = 24, -- wider and the sparkles thin out to specks at the play camera (seen in play)
	ClientSettleSeconds = 0.25,
	ViewDistanceStuds = 175,
	MaxEventAgeSeconds = 8,
	JoinGraceSeconds = 0.5,
	RevealSeconds = 1.35,
	RevealStaggerSeconds = 0.95,
	OutlineSeconds = 2.2,
	-- (long enough to read the line of what the level gives, Config.Pads.Gives)
	MessageSeconds = 3.6,
	MessageHeightStuds = 5,
	MessageRiseStuds = 3,
	MessageWidthPixels = 340,
	MessageHeightPixels = 130,
	ScreenBaseY = 900,
	ScreenMin = 0.7,
	ScreenMax = 1.3,
	SparkleCount = 90,
	SparkleSecondCount = 40,
	EraStepLevels = 10,
	FirstEraUpgradeLevel = 11,
	EraSparkleMultiplier = 1.8,
	SparkleSecondDelay = 0.55,
	SparkleLifetimeMin = 0.75,
	SparkleLifetimeMax = 1.35,
	SparkleSpeedMin = 8,
	SparkleSpeedMax = 16,
	SparkleAccelerationY = -12,
	SparkleSize = 1.1,
	DustCount = 24,
	DustSizeStart = 3,
	DustSizeEnd = 8,
	DustTransparency = 0.3,
	DustLifetimeMin = 1,
	DustLifetimeMax = 1.6,
	DustSpeedMin = 4,
	DustSpeedMax = 8,
	FxLifetimeSeconds = 4,
	Dust = { 240, 232, 214 },
	Gold = { 255, 211, 105 },
	Cream = { 255, 247, 220 },
	Shadow = { 55, 34, 24 },
}

Config.Training = {
	Base = 0.60,
	Soft = 10,
	ChancePerLevel = 1 / 49,
	Gain = 1,
	HpGain = 10,
}

-- ===== Upgrade pads and work places (the owner, 2026-10-29, docs/GAMEPLAY.md §10) =====
Config.Pads = {
	-- Area upgrades now spend actual coins, following the anchored village price progression.
	FreeUpgrades = false,
	Radius = 2.4, -- studs; the pad's disc
	StandHeight = 6, -- a player this far above the ground still stands on it
	CheckSeconds = 0.1,
	-- where each pad stands: x, z in the area's own frame, beside the path near the entrance
	Spots = {
		-- (moved clear of props and off the paths, the owner 2026-10-29: the garden pad overlapped a bench;
		-- checked at levels 1, 21 and 41 with tools/map/probe_pads.luau)
		-- (2026-10-30, the village scale: beside the 14-stud paths; checked at level 1 only, 21 and 41 in phase C)
		fishing = { -14, -26 },
		garden = { 8, -23 },
		pantry = { 9.5, -18 },
		kitchen = { 10.5, -20 }, -- (the kitchen and training ground spread inside too, 2026-10-30)
		training = { 8.5, -24.5 },
		breeding = { 15, -24 },
	},
	-- What an upgrade of each area does, shown under the pad's price and with the level-up title (the owner,
	-- 2026-11-04: players should know why they upgrade). Workers come at Config.Work.SlotLevels, nests at
	-- Config.Breeding.SlotLevels; work is CycleLevelFactor faster a level; rarer fish and vegetables from Food.roll.
	Gives = {
		-- (short enough for one line over a pad at the play camera, seen 2026-11-04)
		fishing = "Faster fishing, rarer fish",
		garden = "Faster crops, rarer veggies",
		kitchen = "Faster cooking, new recipes",
		training = "Faster training, bigger gains",
		pantry = "More storage, bigger vault",
		breeding = "Faster eggs, rarer babies",
	},
}

Config.WorkPlaces = {
	BinCapacity = 10, -- fish, or vegetables of any kind, a bin shows
	-- the bins outside the pond and the garden, beside the path: x, z in the area's frame, turn in degrees
	FishBin = { 12.4, -26.7, 0 }, -- (the pond of the village scale, spread by 1.3)
	VegBin = { -7.5, -17.5, 0 },
	-- the fourth fishing place: a blue-grey boulder on the pond's bank (x, z in the pond's frame, its real
	-- height, the widest it may be); the kit model and its tint
	FishRock = { x = -25.4, z = 7.8, height = 3.4, width = 7, model = "WideBoulder", tint = { 112, 148, 200 } },
	-- the dock's first place stands this many studs in from its far end (the second is mid-dock); the pier's
	-- place, at its end (pond frame)
	DockEndInset = 1.0,
	-- the garden: how far the four places stand off the beds' edges, and the side ones shifted along the beds
	GardenGap = 2.2,
	GardenSideShift = 4,
	PierPlace = { x = 19.8, z = -0.5 },
}

-- ===== The Goo Valley map (docs/MAP.md) =====
-- (owned by Layout and the map builder). Studs; the valley centre is the origin.

Config.Map = {
	-- The height of the terrain's surface on flat ground. Terrain voxels are 4 studs with centres on
	-- multiples of 4, so a floor filled up to y = 0 shows its surface at y = 2 (measured by raycast,
	-- 2026-10-27). Everything that stands on the ground is placed from this height.
	GroundY = 2,
	-- Home plots on the rim; the Market takes one more rim slot (north).
	PlotCount = 8,
	-- The village scale (docs/VILLAGE_SCALE.md, the owner 2026-10-30: "double the area, sized to the slime"). The
	-- standard slime at scale 1, and the clearances every builder keeps from it.
	SlimeWidth = 3.5,
	SlimeHeight = 3,
	-- The village paths keep the owner's 6 studs (2026-10-30: "narrow the paths back to the size they had
	-- before"); slimes pass each other on the lawn beside them. The plaza's round paving has this radius.
	PathWidth = 6,
	MainPathWidth = 6,
	PlazaRadius = 16,
	-- Free ground in front of a work place, nest, incubator, bin, seat or door; between two props; corner turns.
	WorkFront = 7,
	PropGap = 7,
	TurnRadius = 7,
	-- The least open lane between two neighbouring plots on the rim.
	PlotLane = 40,
	-- Distance from the centre to the middle of each rim slot.
	RimRadius = 500,
	-- A home plot is a square this wide (a 3x3 grid of areas): 2.03x the area of the old 160.
	PlotSize = 228,
	-- The Market's footprint (across the rim, along the radius).
	MarketWidth = 200,
	MarketDepth = 160,
	-- The flat valley floor; hills rise beyond it.
	FloorRadius = 690,
	HillOuterRadius = 830,
	HillHeight = 80,
	-- The ring road joining every plot and the Market.
	RingRoadRadius = 356,
	RingRoadWidth = 24,
	-- The Wild Garden and its Heart (World Boss clearing) with two Duel Rings at its edge.
	WildRadius = 334,
	HeartRadius = 64,
	DuelRingRadius = 14,
	DuelRingDistance = 108,
	-- No z-fighting (src/server/ZFight.luau): top faces closer than ZFightTolerance that overlap by more than
	-- ZFightEdge in plan flicker; the smaller part rises by ZFightStep (up to ZFightPasses times). ZFightCell is
	-- the plan grid of the search.
	ZFightTolerance = 0.02,
	ZFightEdge = 0.01,
	ZFightStep = 0.03,
	ZFightPasses = 12,
	ZFightCell = 8,
	-- Rocks rest on the ground (src/server/RockSeat.luau): under the edge of a rock the ground is looked for from
	-- RockProbeUp above its base to RockProbeDown below; it sinks RockBury into it, at most RockMaxSink, and
	-- moves toward higher ground in rings RockShiftStep apart (RockShiftSteps rings) when that is not enough.
	RockProbeUp = 1,
	RockProbeDown = 8,
	RockBury = 0.25,
	RockMaxSink = 1.2,
	RockMaxBuried = 0.6,
	RockShiftStep = 0.5,
	RockShiftSteps = 8,
	RockSeatTolerance = 0.05,
}

-- ===== Frame cost on phones (src/client/EffectsLod.client.luau, tools/build_publish.luau) =====
Config.Perf = {
	-- The world's particle emitters and lights (fires, fountain, lamps; under Workspace.Map) draw only this near the
	-- camera. Measured 2026-11-04: scripts take under 1 ms a frame, but every plot's fires and lamps stayed on at any
	-- distance, and big soft smoke particles are what phones pay for most.
	EmitterStuds = 170,
	LightStuds = 150,
	-- How often a second the distances are looked at again.
	CheckHz = 4,
	-- In the place that goes to players, parts smaller than this (the length of their size) cast no shadow.
	SmallShadowStuds = 6,
}

-- ===== The Market (docs/MAP.md 1.3; the owner, 2026-11-02: one slime buyer, one VIP counter, one leaderboard) =====
-- Spots are local to Layout.marketFrame() (turn them into world positions with Layout.marketPoint): x across the square,
-- z along the radius. The frame looks at the valley centre, so -z is the front (the open side towards the valley) and +z the
-- back (towards the valley's edge); +x is the left of someone walking in from the valley. The prompts and the landing
-- stand at these spots whether or not the scene artist's models are there yet. The square is Map.MarketWidth x MarketDepth.
Config.Market = {
	-- The square (the owner, 2026-11-05: tidy): a round plaza on the fountain, five places on one circle of about 56 round it, each
	-- facing the fountain: the buyer front left, the VIP counter front right, the Blacksmith back left, the Dungeon portal back right
	-- (Config.Dungeon.Portal.Market), the board at the back in the middle; the way in at the front. tools/map/build_market.luau
	-- keeps a copy of these numbers: change both.
	-- Where quick travel lands: on the way in, in front of the plaza, facing the back.
	Landing = { x = 0, z = -56 },
	-- The slime buyer's counter (left) and the VIP counter (right), 60 degrees either side of the way in.
	Buyer = { x = 48, z = -28 },
	Vip = { x = -48, z = -28 },
	-- The leaderboard, at the back in the middle.
	Board = { x = 0, z = 62 },
	-- The Blacksmith (docs/SMITHY.md §6), back left, 120 degrees from the way in, facing the fountain (tools/map/build_smithy.luau).
	Smithy = { x = 48, z = 28 },
	-- What the scene artist names things in workspace.Map.Market (the board's picture goes on its part ScreenName).
	Model = "Market",
	BuyerModel = "SlimeBuyer",
	VipModel = "VipStall",
	BoardModel = "Leaderboard",
	SmithyModel = "Blacksmith",
	ScreenName = "Screen",
	-- How close the VIP counter's prompt shows and its sheet stays open (the buyer's are Zombies.ShopRangeStuds).
	VipRangeStuds = 40,
	-- How close the Blacksmith's prompt shows and its sheet stays open; the server takes a craft within this plus Slack.
	SmithyRangeStuds = 30,
	SmithyRangeSlackStuds = 12,
}

-- Quick travel (src/server/QuickTravel.luau): the HUD's Home and Market buttons.
Config.Travel = {
	-- One move per player this often.
	CooldownSeconds = 3,
	-- A character lands this high above the ground and drops.
	LiftStuds = 4,
	-- Home lands this far inside the plot's front edge, in the gate's opening, facing in.
	HomeInsideStuds = 12,
}

-- Robux goods of the VIP counter (docs/MONETIZATION.md §2: the owner approved this list and these prices on 2026-11-06; a
-- new product or a changed price is asked again, skill robux-products). ONE table holds everything sold: `kind` is "pass"
-- (a game pass, owned for ever, asked of Roblox) or "product" (a developer product, bought again and again, delivered on its
-- receipt). `id` is the Creator Hub id; 0 means it does not exist there yet: the shop shows SOON and the server refuses to
-- prompt for it. `name` is the Hub name (no digits: they are filtered); `label` is the card's title when it may hold digits.
-- What a good does is read from its own fields (shared/Products.grant, shared/Boosts):
--   luck = n        Perm Luck label x n (only the highest owned counts)         teams = n   Extra Team passes: +n team
--   vip = true      the VIP pass                                                slots = n   Bigger Ranch: +n slime slots
--   requires = key  can be bought only with that pass owned
--   gold = n        coins = n x Rewards.coinBase (the village's cheapest next upgrade); never multiplied by a boost
--   spins = n       n wheel spins into the bank (a paid random item: hidden where PolicyService restricts them)
--   potion = kind, minutes   "luck" | "gold" | "hatch" potion for that long, added to the time left
--   effect = "energy" | "hatchAll" | "reroll" | "saver"   an act on the farm
--   starter = { gold, spins, luckMinutes, items }        the Starter Pack, once an account
export type Product = {
	key: string,
	name: string,
	label: string?,
	icon: string,
	price: number,
	kind: string,
	id: number,
	luck: number?,
	vip: boolean?,
	teams: number?,
	slots: number?,
	requires: string?,
	gold: number?,
	spins: number?,
	potion: string?,
	minutes: number?,
	effect: string?,
	starter: { gold: number, spins: number, luckMinutes: number, items: { { kind: string, id: string, count: number } } }?,
}

Config.Robux = {
	-- A test switch, OFF in anything committed. Studio only: a "buy" request hands the good out through the same function as
	-- a real receipt (shared/Products.redeem, server/Purchases.deliver), without Roblox and for any id, and logs the grant.
	TestGrant = false,
	-- A client may ask for a purchase prompt this often (seconds).
	PromptGapSeconds = 1.5,
	-- A receipt that arrives while the save is still loading waits this long for it before Roblox is told to ask again.
	ReceiptWaitSeconds = 20,
	-- A save keeps the last this many receipt ids (Roblox repeats a receipt only until it is granted, so old ones go).
	ReceiptsKept = 200,
	-- Game passes are asked of Roblox at joining: PassTries times, PassRetrySeconds apart (UserOwnsGamePassAsync can fail); a
	-- bought pass is confirmed the same way before it is granted.
	PassTries = 3,
	PassRetrySeconds = 4,
	-- What the server publishes on each player (attributes) is looked at this often.
	RefreshSeconds = 2,
	-- The boosts (docs/MONETIZATION.md §2). VIP pays 1.5 x on coins EARNED (fights, slime and dish sales, rewards; never
	-- Robux gold), the Gold Potion 2 x; they multiply. Eggs hatch VIP x faster and Hatch Potion x faster (incubation time,
	-- its floor kept). The luck labels are Config.Luck.
	CoinFactorVip = 1.5,
	CoinFactorPotion = 2,
	HatchFactorVip = 1.5,
	HatchFactorPotion = 2,
	-- The gold [VIP] chat tag and the small VIP badge (the Player attribute Vip, client/VipTag).
	VipTag = { Text = "[VIP]", Colour = "FFC83D" },
	Products = {
		-- ===== game passes =====
		{ key = "vip", name = "VIP", icon = "vip", price = 249, kind = "pass", id = 0, vip = true },
		{
			key = "luck2",
			name = "Lucky Clover",
			label = "Luck x2",
			icon = "potion_luck",
			price = 19,
			kind = "pass",
			id = 0,
			luck = 2,
		},
		{
			key = "luck4",
			name = "Lucky Horseshoe",
			label = "Luck x4",
			icon = "potion_luck",
			price = 59,
			kind = "pass",
			id = 0,
			luck = 4,
		},
		{
			key = "luck8",
			name = "Lucky Star",
			label = "Luck x8",
			icon = "potion_luck",
			price = 159,
			kind = "pass",
			id = 0,
			luck = 8,
		},
		{ key = "team5", name = "Extra Team", icon = "team_slot", price = 99, kind = "pass", id = 0, teams = 1 },
		{
			key = "team6",
			name = "Extra Team Plus",
			icon = "team_slot",
			price = 149,
			kind = "pass",
			id = 0,
			teams = 1,
			requires = "team5",
		},
		{ key = "ranch", name = "Bigger Ranch", icon = "ranch_slot", price = 79, kind = "pass", id = 0, slots = 50 },
		-- ===== developer products =====
		{
			key = "goldPouch",
			name = "Pouch of Gold",
			icon = "gold_pouch",
			price = 29,
			kind = "product",
			id = 0,
			gold = 2,
		},
		{ key = "goldSack", name = "Sack of Gold", icon = "gold_sack", price = 89, kind = "product", id = 0, gold = 7 },
		{
			key = "goldChest",
			name = "Chest of Gold",
			icon = "gold_chest",
			price = 199,
			kind = "product",
			id = 0,
			gold = 18,
		},
		{
			key = "goldVault",
			name = "Vault of Gold",
			icon = "gold_vault",
			price = 499,
			kind = "product",
			id = 0,
			gold = 50,
		},
		{ key = "spin1", name = "Lucky Spin", icon = "spin", price = 25, kind = "product", id = 0, spins = 1 },
		{ key = "spin5", name = "Spin Bundle", icon = "spin", price = 99, kind = "product", id = 0, spins = 5 },
		{ key = "spin12", name = "Spin Crate", icon = "spin", price = 199, kind = "product", id = 0, spins = 12 },
		{
			key = "luckPotion",
			name = "Luck Potion",
			icon = "potion_luck",
			price = 29,
			kind = "product",
			id = 0,
			potion = "luck",
			minutes = 30,
		},
		{
			key = "goldPotion",
			name = "Gold Potion",
			icon = "potion_gold",
			price = 29,
			kind = "product",
			id = 0,
			potion = "gold",
			minutes = 30,
		},
		{
			key = "hatchPotion",
			name = "Hatch Potion",
			icon = "potion_hatch",
			price = 19,
			kind = "product",
			id = 0,
			potion = "hatch",
			minutes = 30,
		},
		{
			key = "energyDrink",
			name = "Energy Drink",
			icon = "energy_drink",
			price = 19,
			kind = "product",
			id = 0,
			effect = "energy",
		},
		{
			key = "hatchAll",
			name = "Hatch All Now",
			icon = "hatch_now",
			price = 19,
			kind = "product",
			id = 0,
			effect = "hatchAll",
		},
		{
			key = "questReroll",
			name = "Quest Reroll",
			icon = "quest_reroll",
			price = 9,
			kind = "product",
			id = 0,
			effect = "reroll",
		},
		{
			key = "streakSaver",
			name = "Streak Saver",
			icon = "streak_saver",
			price = 19,
			kind = "product",
			id = 0,
			effect = "saver",
		},
		{
			key = "starterPack",
			name = "Starter Pack",
			icon = "starter_pack",
			price = 49,
			kind = "product",
			id = 0,
			starter = {
				gold = 7,
				spins = 5,
				luckMinutes = 60,
				items = { { kind = "material", id = "ore", count = 5 } },
			},
		},
	} :: { Product },
}

-- The leaderboard of the Market (src/server/Leaderboard.luau, LeaderboardStore, shared/Leaderboard, and the client's
-- LeaderboardScreen): the top Rows slimes of the whole game by level, one per player.
Config.Leaderboard = {
	-- Few rows, so the letters read from across the square on a phone.
	Rows = 6,
	-- The OrderedDataStore holds each player's best score, the second store the names that go with it (a score is one number).
	ScoreStore = "GooLineage_Board_v1",
	NameStore = "GooLineage_BoardNames_v1",
	-- score = level * TimeScale + (TimeScale - 1 - the second that level was first seen): higher level first, earlier first.
	TimeScale = 10_000_000_000,
	-- A player's best is sent when it improved, at most this often, and when they leave.
	WriteGapSeconds = 60,
	-- The server looks for bests to send this often, reads the top this often, and re-reads the players here this often.
	WriteCheckSeconds = 10,
	ReadSeconds = 60,
	LiveSeconds = 5,
	-- Leaving writes may use this long at shutdown.
	ShutdownSeconds = 15,
	-- Names longer than this are cut; empty ones become the fallbacks.
	MaxNameLength = 24,
	FallbackPlayer = "Player",
	FallbackSlime = "Slime",
	-- A Studio play test keeps the board in memory. Switch on only to try the real store from Studio (never commit it on).
	StudioUsesRealStore = false,
	-- Published for the clients: ReplicatedStorage.<Folder> with attributes Row1..RowN ("player<TAB>slime<TAB>level").
	Folder = "Leaderboard",
	-- The screen: the face of the Screen part it is drawn on, canvas pixels per stud of that face, and its words.
	Face = "Front",
	PixelsPerStud = 40,
	Title = "Top Slimes",
	Empty = "No slimes yet",
	-- The title takes this share of the canvas height; the letters grow to fill their row between these sizes; a missing
	-- screen is looked for this often (seconds).
	TitleShare = 0.14,
	TextMin = 8,
	TextMax = 96,
	ScreenLookSeconds = 3,
}

-- ===== The plots of a server (src/server/Plots.luau; the owner, 2026-11-02: up to 8 players, a plot each) =====
Config.Plots = {
	-- The hand-built village the others are copies of: workspace.Map.Plot5 in the work place. At server start it moves to
	-- ServerStorage under TemplateName and every plot, this one too, is left empty until a player joins.
	TemplatePlot = 5,
	TemplateName = "PlotTemplate",
	-- A village is copied (and a plot a player left is cleared) in steps: after this many seconds of work the server
	-- gives the frame back. A container holding more parts than ChunkParts is copied child by child.
	StepSeconds = 0.006,
	ChunkParts = 400,
	-- A player appears this many studs from the plaza towards the gate, this high above the ground.
	SpawnAhead = 16,
	SpawnLift = 0.1,
	-- A plot nobody holds is one stud-lawn part over the sunken ground (its top this far under the village floor's top).
	EmptyColour = "#68b23e",
	EmptyDrop = 0.05,
	EmptyThickness = 2,
	-- Vector3 attributes in world space that turn with a copied village: tag -> attribute names (the fish loops of the pond).
	Turned = { PondFish = { "Centre" } },
	-- How often a player waiting for a plot's copy to be built looks again.
	WaitSeconds = 0.1,
	-- Shown to a ninth player (the place should allow 8).
	FullMessage = "This server is full. Please join another one - your farm is safe.",
}

-- ===== The slime body, face and motion =====
-- (owned by SlimeShape, SlimeMotion, Expressions and the client's SlimeFace / SlimeActor). Lengths are in
-- body heights (one slime is 1.0 high at scale 1); the farm scales the model, the code multiplies by it.

Config.Slime = {
	-- The skinned body (art/models/slime_body/rounds.md): mesh height, and the bone weight divisor
	-- (a vertex is pulled by its height / BoneK toward the Top bone, by its width / BoneK toward a side bone).
	MeshHeight = 0.999933,
	-- (the body MeshPart's centre is this far above the feet)
	MeshCentre = 0.4999665,
	BoneK = 1.5,
	-- The face's centre sits this far up the body (the original game: 0.51), and a face picture is
	-- drawn 0.64 body widths wide.
	FaceHeight = 0.51,
	-- Where the eye and mouth plates sit on the face (x from the middle, y from the face centre).
	EyeX = 0.215,
	EyeY = 0,
	MouthY = -0.1,
	-- A face plate stands this far off the skin so it never fights the body's own pixels.
	PlateOffset = 0.006,
	-- Pixels of face picture per body height (the owner's face pictures are about this sharp).
	CanvasPerUnit = 365,

	-- The jelly: damped springs. Hz = how fast it rings, Damping = 0 rings forever, 1 never rings.
	SquashHz = 3.2,
	SquashDamping = 0.28,
	LeanHz = 2.2,
	LeanDamping = 0.4,
	YawHz = 3,
	YawDamping = 0.6,
	PuffHz = 4,
	PuffDamping = 0.35,
	-- Width follows the squash by this much (1 would keep the volume); jelly bulges a little less.
	VolumeBulge = 0.55,
	-- Hops: gravity in body heights per second squared, the crouch before the jump, the stretch
	-- while airborne and the landing's push into the squash spring (the owner, 2026-10-29: a soft body
	-- with weight, crouch before a hop, a landing squash and a wobble that dies down).
	Gravity = 10,
	CrouchSeconds = 0.13,
	CrouchSquash = -0.26,
	AirStretch = 0.12,
	LandKick = 3,
	-- The physics never takes a step longer than this, and integrates in pieces of SubStep.
	MaxStep = 1 / 15,
	SubStep = 1 / 120,

	-- Blinks: the face only, with a hardly visible dip of the body.
	BlinkMinSeconds = 3.5,
	BlinkMaxSeconds = 6,
	BlinkSeconds = 0.12,
	BlinkShut = 0.88,
	DoubleBlinkChance = 0.18,
	DoubleBlinkGapSeconds = 0.22,
	BlinkBodyKick = -0.7,
	-- Eyes: how fast they turn toward a target, and how far they may move inside the face.
	GazeRate = 9,
	GazeX = 0.022,
	GazeY = 0.015,
	-- An emotion swap swells the face by PopSize for PopSeconds.
	PopSeconds = 0.15,
	PopSize = 0.08,
	-- Emotes pop once; sleep, love and dizzy effects keep their own short lifetimes.
	EmoteShowSeconds = 1.8,
	EmoteFadeSeconds = 0.45,
	ZzzEverySeconds = 0.9,
	ZzzLifeSeconds = 2.6,
	-- hearts rise one at a time, slowly (the owner, 2026-10-29)
	HeartsLifeSeconds = 2.6,
	-- an emote is this many body heights across, in the world (it scales with the camera's distance like the slime)
	EmoteSize = 0.55,
	OrbitStars = 3,
	OrbitHz = 0.7,

	-- Cost: every slime closer than FullStuds is drawn every frame, up to FarStuds at 10 Hz,
	-- beyond that only its physics runs (and not even that beyond SleepStuds).
	FullStuds = 70,
	FarStuds = 160,
	SleepStuds = 400,
	FarHz = 10,
}

-- ===== Worn pieces of a Secret slime (the owner, 2026-11-10: "phụ kiện cho từng con slime") =====
-- Drawn by the client (client/SlimeWear): each piece is a mesh made for a body one unit tall (tools/blender/wear_kit.py,
-- which writes these numbers to art/models/accessories/<kit>/wear.json), in mesh units: feet at y 0, front -Z, the slime's
-- own left -X. `at` is the piece's middle where it rests, `size` its box; it rides the skin at `anchor` as the jelly
-- squashes, hops and leans. A `flap` swings it about its anchor along `axis` (a positive turn lifts it), `degrees` each
-- way, `hz` times a second (a tail wags with one about the up axis). A `twitch` flicks it now and then (Twitch), a `lag`
-- makes it trail the hop (Lag). A kit whose meshes are not uploaded yet (mesh 0) is left off.
-- (the owner, 2026-11-10: "gắn thêm chuyển động cho phần đuôi và tai")
-- A tentacle bends: its `bones` (root to tip, each its rest point and X and Y axes in mesh units) are built on it by name
-- so its skin follows them, and its `wriggle` turns each about `axis` (a positive turn lifts the tip): a wave of
-- `degrees` running out to the tip `hz` times a second, each bone `lag` radians behind the one before, and a slow curl
-- of `curl` degrees and back `curlHz` times a second; both grow toward the tip. (the owner, 2026-11-10: "co duỗi, ngọ
-- nguậy như tay bạch tuộc")
type WearMotion = { axis: { number }, degrees: number, hz: number?, every: number? }
type WearWriggle = { axis: { number }, degrees: number, hz: number, lag: number, curl: number, curlHz: number }
type WearPiece = {
	name: string,
	mesh: number,
	size: { number },
	at: { number },
	anchor: { number },
	flap: WearMotion?,
	twitch: WearMotion?,
	lag: WearMotion?,
	bones: { { number } }?,
	wriggle: WearWriggle?,
}
type WearKit = { texture: string, pieces: { WearPiece } }
Config.Wear = {
	-- An ear's `twitch`: once in each `every` seconds, at a moment of its own, it flicks `degrees` about `axis` ({1, 0, 0}
	-- tips it back) and comes home: Out the flick's seconds, Length the whole move's.
	Twitch = { Out = 0.07, Length = 0.4 },
	-- A `lag` bends a piece about `axis` ({1, 0, 0}: ears tip back, a tail drops) as the slime climbs, the other way as it
	-- falls: `degrees` at a climb of Rise bodies a second, eased by a spring that goes half way in HalfLife seconds; a
	-- pause longer than Gap (a far slime) starts it over.
	Lag = { Rise = 4, HalfLife = 0.07, Gap = 0.5 },
	-- Secret id -> its kit
	Secrets = {
		["secret-black-blue"] = "TempestDragon",
		["secret-blue-red"] = "SteamDragon",
		["secret-navy-red"] = "FireIceChimera",
		["secret-black-gray"] = "ShadowWolf",
		["secret-black-navy"] = "MidnightRaven",
		["secret-black-orange"] = "JackOSlime",
		["secret-black-pink"] = "GothicBat",
		["secret-blue-pink"] = "CottonCandySheep",
		["secret-blue-orange"] = "SunshowerFox",
		["secret-black-purple"] = "VoidKraken",
		["secret-blue-blue"] = "CloudPegasus",
		["secret-black-yellow"] = "HoneybeeSlime",
		["secret-black-red"] = "BloodMoonBat",
		["secret-gray-purple"] = "MoonstoneGargoyle",
		["secret-blue-white"] = "FrostSwan",
	},
	Kits = {
		-- the owner's Meshy model art/models/accessories/tempest_dragon/neon_dragon_relics.glb, uploaded as model
		-- 137031942711781 (its five MeshParts give the mesh ids)
		TempestDragon = {
			texture = "rbxassetid://83202714233801",
			pieces = {
				{
					name = "HornL",
					mesh = 96314571205165,
					size = { 0.1553, 0.2796, 0.182 },
					at = { -0.239, 0.8957, 0.0251 },
					anchor = { -0.2306, 0.7906, 0.011 },
				},
				{
					name = "HornR",
					mesh = 127323584430638,
					size = { 0.1553, 0.2796, 0.182 },
					at = { 0.239, 0.8957, 0.0251 },
					anchor = { 0.2306, 0.7906, 0.011 },
				},
				{
					name = "WingL",
					mesh = 114769919864432,
					size = { 0.4211, 0.4311, 0.3377 },
					at = { -0.4875, 0.6246, 0.484 },
					anchor = { -0.3, 0.47, 0.34 },
					-- (the owner: "đôi cánh hơi vỗ nhẹ", a soft slow beat)
					flap = { axis = { -0.6157, 0, -0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 78544047008425,
					size = { 0.4211, 0.4311, 0.3377 },
					at = { 0.4875, 0.6246, 0.484 },
					anchor = { 0.3, 0.47, 0.34 },
					flap = { axis = { -0.6157, 0, 0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 137066152781922,
					size = { 0.1352, 0.2177, 0.3827 },
					at = { 0.0017, 0.1752, 0.6211 },
					anchor = { 0, 0.16, 0.44 },
					-- (a slow lazy wag)
					flap = { axis = { 0, 1, 0 }, degrees = 8, hz = 0.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's Meshy model art/models/accessories/steam_dragon/patriotic_dragon_cost.glb, uploaded as model
		-- 88958587355820
		SteamDragon = {
			texture = "rbxassetid://79626976517509",
			pieces = {
				{
					name = "HornL",
					mesh = 72943524244004,
					size = { 0.2944, 0.3225, 0.203 },
					at = { -0.3388, 0.8715, 0.0507 },
					anchor = { -0.2746, 0.7584, 0.04 },
				},
				{
					name = "HornR",
					mesh = 105459137410678,
					size = { 0.2944, 0.3225, 0.203 },
					at = { 0.3388, 0.8715, 0.0507 },
					anchor = { 0.2746, 0.7584, 0.04 },
				},
				{
					name = "WingL",
					mesh = 102255726396265,
					size = { 0.5098, 0.4678, 0.4121 },
					at = { -0.5241, 0.6013, 0.5068 },
					anchor = { -0.3, 0.47, 0.34 },
					flap = { axis = { -0.6157, 0, -0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 98472723970976,
					size = { 0.5098, 0.4678, 0.4121 },
					at = { 0.5241, 0.6013, 0.5068 },
					anchor = { 0.3, 0.47, 0.34 },
					flap = { axis = { -0.6157, 0, 0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 106763278921249,
					size = { 0.1093, 0.2103, 0.365 },
					at = { 0.0024, 0.1512, 0.6229 },
					anchor = { 0, 0.21, 0.45 },
					flap = { axis = { 0, 1, 0 }, degrees = 8, hz = 0.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/fire_ice_chimera/navy_red.glb (a red horn on the red side, a blue one
		-- on the blue side, a red-to-blue tail), uploaded as model 119200639103906
		FireIceChimera = {
			texture = "rbxassetid://131498492296218",
			pieces = {
				{
					name = "HornL",
					mesh = 108500283271458,
					size = { 0.1807, 0.3802, 0.1652 },
					at = { -0.29, 0.9051, 0.035 },
					anchor = { -0.264, 0.7683, 0.04 },
				},
				{
					name = "HornR",
					mesh = 101066443649361,
					size = { 0.1838, 0.3785, 0.1652 },
					at = { 0.2869, 0.9094, 0.0324 },
					anchor = { 0.264, 0.7682, 0.04 },
				},
				{
					name = "Tail",
					mesh = 138892483345830,
					size = { 0.1082, 0.2751, 0.4989 },
					at = { 0.0073, 0.2827, 0.6657 },
					anchor = { 0, 0.1965, 0.4303 },
					flap = { axis = { 0, 1, 0 }, degrees = 10, hz = 0.6 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/shadow_wolf/black_gray.glb (two wolf ears, a bushy smoky tail), uploaded
		-- as model 117979860637781
		ShadowWolf = {
			texture = "rbxassetid://120486318461151",
			pieces = {
				{
					name = "EarL",
					mesh = 70636085288680,
					size = { 0.3834, 0.4831, 0.1856 },
					at = { -0.2704, 0.9018, 0.0312 },
					anchor = { -0.356, 0.7026, 0 },
					-- (a dog's ear: a quick flick back now and then, each ear on its own)
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "EarR",
					mesh = 96839745024511,
					size = { 0.3808, 0.4934, 0.185 },
					at = { 0.2738, 0.901, 0.0358 },
					anchor = { 0.3559, 0.7021, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "Tail",
					mesh = 87072655348517,
					size = { 0.1708, 0.2537, 0.459 },
					at = { 0.0119, 0.1979, 0.6566 },
					anchor = { 0, 0.1983, 0.4402 },
					-- (a wolf's brisk wag)
					flap = { axis = { 0, 1, 0 }, degrees = 14, hz = 0.9 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
		-- the owner's model art/models/accessories/cotton_candy_sheep/blue_pink.glb (pink ram horns and a cotton-candy
		-- tuft worn as a crown; the owner kept only these, 2026-11-10), uploaded as model 109726191050235
		CottonCandySheep = {
			texture = "rbxassetid://132670767775971",
			pieces = {
				{
					name = "HornL",
					mesh = 90284009845471,
					size = { 0.2499, 0.2246, 0.0884 },
					at = { -0.3141, 0.8037, 0.0113 },
					anchor = { -0.2774, 0.7619, 0 },
				},
				{
					name = "HornR",
					mesh = 73095859444618,
					size = { 0.2531, 0.2205, 0.0887 },
					at = { 0.3053, 0.8096, 0.0184 },
					anchor = { 0.2774, 0.7618, 0 },
				},
				{
					name = "Garland",
					mesh = 74304308066268,
					size = { 0.438, 0.2276, 0.2008 },
					at = { 0.0243, 0.8499, -0.1075 },
					anchor = { 0.23, 0.8, -0.05 },
				},
			},
		},
		-- the owner's model art/models/accessories/sunshower_fox/blue_orange.glb (fox ears, blue fur, orange rim, white fluff
		-- inside; a bushy tail from a blue base to an orange curl), uploaded as model 111111432845594
		SunshowerFox = {
			texture = "rbxassetid://91317140780540",
			pieces = {
				{
					name = "EarL",
					mesh = 133352440958331,
					size = { 0.2333, 0.2844, 0.0912 },
					at = { -0.3269, 0.8388, 0.0151 },
					anchor = { -0.3479, 0.7127, 0 },
					-- (small perky ears flick often)
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "EarR",
					mesh = 81193564832508,
					size = { 0.2341, 0.2801, 0.0898 },
					at = { 0.3415, 0.8285, 0.0162 },
					anchor = { 0.3475, 0.712, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "Tail",
					mesh = 70476181876410,
					size = { 0.23, 0.3657, 0.6189 },
					at = { 0.0154, 0.1952, 0.6984 },
					anchor = { 0, 0.2, 0.41 },
					-- (a brisk bushy wag, between the wolf's and the dragon's)
					flap = { axis = { 0, 1, 0 }, degrees = 12, hz = 0.8 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
		-- the owner's model art/models/accessories/void_kraken/black_purple.glb (eight cosmic tentacles with glowing
		-- suckers; the owner: they grow from under the body and curl and wriggle like an octopus's arms, none sunk into
		-- it, the suckers facing down or out), rigged by tools/blender/wear_kit.py (kind `tentacle`), uploaded as model
		-- 91899436585494
		VoidKraken = {
			texture = "rbxassetid://113029184257138",
			pieces = {
				{
					name = "Arm4",
					mesh = 128179148715784,
					size = { 0.3703, 0.2037, 0.3549 },
					at = { -0.2681, 0.0606, -0.3135 },
					anchor = { -0.1543, 0.0446, -0.1839 },
					bones = {
						{ -0.1471, 0.0309, -0.2027, -0.387, 0.3748, 0.8425, -0.8425, 0.2276, -0.4883 },
						{ -0.2075, 0.0472, -0.2377, -0.2187, 0.3154, 0.9234, -0.9234, 0.239, -0.3004 },
						{ -0.3088, 0.0734, -0.2706, -0.8276, 0.1219, 0.5479, -0.5479, 0.0365, -0.8357 },
						{ -0.3596, 0.0768, -0.3482, -0.8175, 0.3614, -0.4484, 0.4484, -0.0892, -0.8894 },
						{ -0.3236, 0.0696, -0.4195, 0.3522, 0.1943, -0.9155, 0.9155, -0.2746, 0.294 },
					},
					-- (each arm on its own beat)
					wriggle = {
						axis = { 0.2589, 0.9613, -0.0941 },
						degrees = 8,
						hz = 0.45,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm5",
					mesh = 100349152536520,
					size = { 0.5428, 0.3832, 0.2794 },
					at = { -0.4878, 0.1433, -0.0815 },
					anchor = { -0.2364, 0.0429, -0.0417 },
					bones = {
						{ -0.2509, 0.0333, -0.0732, 0.0747, 0.3075, 0.9486, -0.9486, 0.3153, -0.0275 },
						{ -0.3413, 0.0633, -0.0758, 0.3549, 0.5715, 0.7399, -0.7399, 0.6555, -0.1515 },
						{ -0.4374, 0.1485, -0.0955, 0.0444, 0.4665, 0.8834, -0.8834, 0.4313, -0.1833 },
						{ -0.5499, 0.2034, -0.1188, 0.0376, -0.2932, 0.9553, -0.9553, -0.291, -0.0517 },
						{ -0.6678, 0.1675, -0.1252, 0.972, -0.1411, 0.1878, -0.1878, -0.9472, 0.2601 },
					},
					wriggle = {
						axis = { 0.1232, -0.2548, -0.9591 },
						degrees = 8,
						hz = 0.48,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm1",
					mesh = 111664306738205,
					size = { 0.5876, 0.4751, 0.4069 },
					at = { -0.4228, 0.2234, 0.2321 },
					anchor = { -0.2078, 0.0417, 0.12 },
					bones = {
						{ -0.2198, 0.0591, 0.1316, 0.3774, 0.0616, 0.924, -0.924, 0.0914, 0.3713 },
						{ -0.3454, 0.0715, 0.1821, 0.7272, 0.2784, 0.6275, -0.6275, 0.6402, 0.4431 },
						{ -0.4418, 0.1698, 0.2502, 0.9293, 0.2081, 0.3051, -0.3051, 0.8981, 0.3166 },
						{ -0.4939, 0.3232, 0.3042, 0.4386, 0.1501, 0.886, -0.886, 0.237, 0.3985 },
						{ -0.6241, 0.358, 0.3628, 0.9775, -0.16, 0.1371, -0.1371, -0.9771, -0.163 },
					},
					wriggle = {
						axis = { -0.3719, 0.2248, -0.9006 },
						degrees = 8,
						hz = 0.51,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm2",
					mesh = 128303848666777,
					size = { 0.3572, 0.4146, 0.6529 },
					at = { -0.1377, 0.1781, 0.4965 },
					anchor = { -0.0821, 0.045, 0.2255 },
					bones = {
						{ -0.0934, 0.0589, 0.243, 0.9379, 0.0515, 0.3429, -0.3429, 0.2844, 0.8953 },
						{ -0.1332, 0.0919, 0.3469, 0.8432, -0.0063, 0.5376, -0.5376, -0.0215, 0.8429 },
						{ -0.2195, 0.0884, 0.4822, 0.9967, -0.034, -0.0741, 0.0741, 0.7573, 0.6489 },
						{ -0.2074, 0.212, 0.5881, 0.9992, 0.017, 0.0369, -0.0369, 0.7602, 0.6486 },
						{ -0.2134, 0.3353, 0.6933, 0.7443, -0.0788, 0.6631, -0.6631, -0.2043, 0.7201 },
					},
					wriggle = {
						axis = { -0.7385, 0.4491, -0.503 },
						degrees = 8,
						hz = 0.54,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm3",
					mesh = 129663097083190,
					size = { 0.3919, 0.3394, 0.6255 },
					at = { 0.1931, 0.1456, 0.5007 },
					anchor = { 0.0821, 0.0959, 0.2255 },
					bones = {
						{ 0.0815, 0.0924, 0.2408, 0.8159, 0.0326, -0.5773, 0.5773, -0.1023, 0.8101 },
						{ 0.1612, 0.0783, 0.3526, 0.9999, -0.0025, -0.0116, 0.0116, 0.4164, 0.9091 },
						{ 0.1628, 0.136, 0.4787, 0.9934, -0.0157, -0.1134, 0.1134, 0.2708, 0.9559 },
						{ 0.1806, 0.1784, 0.6285, 0.7589, 0.1208, -0.6399, 0.6399, -0.3206, 0.6984 },
						{ 0.2759, 0.1307, 0.7325, 0.4837, 0.7191, -0.4989, 0.4989, -0.6949, -0.5179 },
					},
					wriggle = {
						axis = { -0.6482, -0.7056, 0.2863 },
						degrees = 8,
						hz = 0.57,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm6",
					mesh = 137475068722289,
					size = { 0.5879, 0.2692, 0.4013 },
					at = { 0.458, 0.0916, 0.2549 },
					anchor = { 0.2078, 0.04, 0.12 },
					bones = {
						{ 0.2213, 0.0315, 0.1416, 0.5818, -0.2132, -0.7849, 0.7849, 0.4001, 0.4731 },
						{ 0.3205, 0.0821, 0.2014, 0.4113, 0.0838, -0.9076, 0.9076, -0.1291, 0.3994 },
						{ 0.4443, 0.0645, 0.2559, 0.5396, -0.128, -0.8321, 0.8321, 0.2314, 0.504 },
						{ 0.5573, 0.0959, 0.3243, 0.6781, -0.2165, -0.7024, 0.7024, 0.4723, 0.5325 },
						{ 0.6664, 0.1692, 0.407, 0.8437, 0.3782, -0.3809, 0.3809, -0.9218, -0.0715 },
					},
					wriggle = {
						axis = { -0.4516, -0.2564, 0.8546 },
						degrees = 8,
						hz = 0.6,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm8",
					mesh = 95919529910338,
					size = { 0.6429, 0.3186, 0.3197 },
					at = { 0.528, 0.1445, -0.104 },
					anchor = { 0.2364, 0.0747, -0.0417 },
					bones = {
						{ 0.2576, 0.0822, -0.0436, 0.0797, 0.0815, -0.9935, 0.9935, -0.0879, 0.0725 },
						{ 0.3821, 0.0711, -0.0345, -0.0935, -0.3782, -0.921, 0.921, 0.3185, -0.2243 },
						{ 0.5187, 0.1184, -0.0678, 0.111, -0.7771, -0.6195, 0.6195, 0.5416, -0.5683 },
						{ 0.6248, 0.2111, -0.1651, -0.0729, -0.0071, -0.9973, 0.9973, 0.0066, -0.073 },
						{ 0.7704, 0.212, -0.1757, 0.9957, 0.0361, -0.085, 0.085, -0.7177, 0.6912 },
					},
					wriggle = {
						axis = { 0.0184, 0.6992, 0.7147 },
						degrees = 8,
						hz = 0.63,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm7",
					mesh = 78307173896949,
					size = { 0.4751, 0.2183, 0.402 },
					at = { 0.2745, 0.0734, -0.357 },
					anchor = { 0.1543, 0.043, -0.1839 },
					bones = {
						{ 0.1538, 0.0444, -0.2123, -0.3155, -0.856, -0.4097, 0.4097, 0.2666, -0.8724 },
						{ 0.1868, 0.0659, -0.2825, -0.4732, -0.2487, -0.8451, 0.8451, 0.1427, -0.5152 },
						{ 0.2772, 0.0811, -0.3376, -0.2876, 0.0307, -0.9573, 0.9573, -0.0228, -0.2883 },
						{ 0.4332, 0.0774, -0.3846, 0.3172, -0.926, -0.2048, 0.2048, 0.2777, -0.9386 },
						{ 0.4574, 0.1102, -0.4954, -0.1818, 0.2189, 0.9587, -0.9587, 0.1775, -0.2224 },
					},
					wriggle = {
						axis = { 0.0925, 0.9518, 0.2925 },
						degrees = 8,
						hz = 0.66,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
			},
		},
		-- the owner's model art/models/accessories/midnight_raven/black_navy.glb (a pair of feathered wings; the owner: the
		-- painting's wings are wrong; raised they stood too high, folded they were not what he wants: so they grow from the
		-- middle of the back and spread wide, level, the long feathers curling up at the ends, as his sketch draws a
		-- bird's open wings), uploaded as model 105971591012484
		MidnightRaven = {
			texture = "rbxassetid://95556414402224",
			pieces = {
				{
					name = "WingL",
					mesh = 82359241334531,
					size = { 0.87, 0.5971, 0.2359 },
					at = { -0.5811, 0.5339, 0.5575 },
					anchor = { -0.17, 0.53, 0.45 },
					-- (the open wing beats slowly in its own plane, the tip rising and falling)
					flap = { axis = { -0.2437, -0.1181, -0.9626 }, degrees = 10, hz = 0.6 },
				},
				{
					name = "WingR",
					mesh = 71396339618517,
					size = { 0.8679, 0.6101, 0.2312 },
					at = { 0.5819, 0.5534, 0.558 },
					anchor = { 0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, 0.1181, 0.9626 }, degrees = 10, hz = 0.6 },
				},
			},
		},
		-- the owner's model art/models/accessories/cloud_pegasus/wing_trio.glb (one white feathered wing, mirrored into a
		-- pair; the Raven's pose and beat, the owner's standard for every bird wing pair, only smaller), uploaded as model
		-- 87390925158467
		CloudPegasus = {
			texture = "rbxassetid://89482836839649",
			pieces = {
				{
					name = "WingL",
					mesh = 106819395859519,
					size = { 0.7862, 0.3704, 0.1954 },
					at = { -0.5389, 0.6181, 0.5257 },
					anchor = { -0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, -0.1181, -0.9626 }, degrees = 10, hz = 0.6 },
				},
				{
					name = "WingR",
					mesh = 127232322331656,
					size = { 0.7862, 0.3704, 0.1954 },
					at = { 0.5389, 0.6181, 0.5257 },
					anchor = { 0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, 0.1181, 0.9626 }, degrees = 10, hz = 0.6 },
				},
			},
		},
		-- the owner's model art/models/accessories/honeybee_slime/wing_trio.glb (one bee wing, mirrored into a pair, rising
		-- up and out from the upper back), uploaded as model 71604348945099
		HoneybeeSlime = {
			texture = "rbxassetid://85451487466506",
			pieces = {
				{
					name = "WingL",
					mesh = 89838154835644,
					size = { 0.3991, 0.4405, 0.1866 },
					at = { -0.4292, 0.8807, 0.351 },
					anchor = { -0.24, 0.7, 0.27 },
					-- (a bee's wings buzz: small and quick; clear, as the painting's)
					flap = { axis = { -0.2567, 0.1694, -0.9515 }, degrees = 14, hz = 3 },
					clear = 0.35,
				},
				{
					name = "WingR",
					mesh = 86802540053816,
					size = { 0.3991, 0.4405, 0.1866 },
					at = { 0.4292, 0.8807, 0.351 },
					anchor = { 0.24, 0.7, 0.27 },
					flap = { axis = { -0.2567, -0.1694, 0.9515 }, degrees = 14, hz = 3 },
					clear = 0.35,
				},
			},
		},
		-- the owner's model art/models/accessories/blood_moon_bat/wing_trio.glb (one bat wing, its two torn holes mended,
		-- mirrored into a pair, up and out from the upper shoulders), uploaded as model 113673886578474
		BloodMoonBat = {
			texture = "rbxassetid://121139310661251",
			pieces = {
				{
					name = "WingL",
					mesh = 105030148439945,
					size = { 0.5243, 0.5736, 0.1981 },
					at = { -0.4365, 0.7854, 0.2705 },
					anchor = { -0.28, 0.66, 0.25 },
					flap = { axis = { -0.2756, 0, -0.9613 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 101786129418069,
					size = { 0.5243, 0.5736, 0.1981 },
					at = { 0.4365, 0.7854, 0.2705 },
					anchor = { 0.28, 0.66, 0.25 },
					flap = { axis = { -0.2756, 0, 0.9613 }, degrees = 12, hz = 0.8 },
				},
			},
		},
		-- the owner's model art/models/accessories/moonstone_gargoyle/gray_purple.glb (stone bat wings out behind the
		-- shoulders, two small horns on the front of the head's top corners, a scaly arrow-tipped tail), uploaded as model
		-- 128659610713284
		MoonstoneGargoyle = {
			texture = "rbxassetid://84499624132900",
			pieces = {
				{
					name = "HornL",
					mesh = 133666424166771,
					size = { 0.171, 0.2183, 0.1067 },
					at = { -0.2748, 0.8717, -0.0862 },
					anchor = { -0.2331, 0.7792, -0.1 },
				},
				{
					name = "HornR",
					mesh = 81409518149910,
					size = { 0.1678, 0.2227, 0.1064 },
					at = { 0.2832, 0.8667, -0.1022 },
					anchor = { 0.2331, 0.7792, -0.1 },
				},
				{
					name = "WingL",
					mesh = 82014703898286,
					size = { 0.65, 0.4992, 0.3888 },
					at = { -0.5931, 0.7108, 0.4556 },
					anchor = { -0.29, 0.67, 0.28 },
					flap = { axis = { -0.5, 0, -0.866 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 119158942649300,
					size = { 0.6594, 0.4984, 0.3867 },
					at = { 0.5982, 0.7152, 0.4537 },
					anchor = { 0.29, 0.67, 0.28 },
					flap = { axis = { -0.5, 0, 0.866 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 72949607917756,
					size = { 0.1329, 0.2124, 0.6239 },
					at = { -0.0066, 0.1987, 0.7766 },
					anchor = { 0, 0.2, 0.485 },
					-- (a stone creature's tail: a slow, heavy wag)
					flap = { axis = { 0, 1, 0 }, degrees = 8, hz = 0.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/jack_o_slime/black_orange.glb (pumpkin vines and leaves; the owner: as
		-- his painting has them, growing out past the body round its outline), uploaded as model 104420315090131
		JackOSlime = {
			texture = "rbxassetid://112513356176270",
			pieces = {
				{
					name = "VineTopL",
					mesh = 137899791141278,
					size = { 0.44, 0.382, 0.3043 },
					at = { -0.4402, 0.8, -0.0151 },
					anchor = { -0.2417, 0.8, 0 },
				},
				{
					name = "VineTopR",
					mesh = 101060743461314,
					size = { 0.4299, 0.466, 0.2477 },
					at = { 0.4386, 0.8, 0 },
					anchor = { 0.2417, 0.8, 0 },
				},
				{
					name = "VineSideL",
					mesh = 102760336778778,
					size = { 0.4963, 0.6921, 0.3002 },
					at = { -0.3924, 0.351, -0.0964 },
					anchor = { -0.5267, 0.34, 0 },
				},
				{
					name = "VineSideR",
					mesh = 109032431194606,
					size = { 0.4333, 0.6883, 0.2666 },
					at = { 0.402, 0.3491, -0.0955 },
					anchor = { 0.5267, 0.34, 0 },
				},
				{
					name = "VineFootL",
					mesh = 135231371777731,
					size = { 0.4182, 0.1209, 0.3688 },
					at = { -0.2769, 0.1288, -0.3114 },
					anchor = { -0.2966, 0.12, -0.3294 },
				},
				{
					name = "VineFootR",
					mesh = 131548259721098,
					size = { 0.5516, 0.1558, 0.439 },
					at = { 0.228, 0.1332, -0.2479 },
					anchor = { 0.2966, 0.12, -0.3294 },
				},
				{
					name = "VineBack",
					mesh = 95837274024134,
					size = { 0.6241, 0.6992, 0.3456 },
					at = { -0.0032, 0.4133, 0.3959 },
					anchor = { 0, 0.42, 0.5185 },
				},
				{
					name = "LeafTop",
					mesh = 78142670396585,
					size = { 0.2187, 0.1368, 0.1232 },
					at = { -0.2072, 0.6746, 0.3623 },
					anchor = { -0.1996, 0.68, 0.3458 },
				},
				{
					name = "LeafA",
					mesh = 139024666239614,
					size = { 0.128, 0.1487, 0.1502 },
					at = { 0.4166, 0.2055, 0.2926 },
					anchor = { 0.4092, 0.2, 0.2865 },
				},
				{
					name = "LeafB",
					mesh = 87898225951103,
					size = { 0.1076, 0.1549, 0.1119 },
					at = { -0.4234, 0.2239, 0.292 },
					anchor = { -0.4149, 0.22, 0.2905 },
				},
				{
					name = "LeafC",
					mesh = 83191436666121,
					size = { 0.1932, 0.1667, 0.1266 },
					at = { 0.1878, 0.6525, 0.3711 },
					anchor = { 0.2081, 0.66, 0.3605 },
				},
			},
		},
		-- the owner's model art/models/accessories/gothic_bat/black_pink.glb (bat ears and wings, a tail from a rose to a
		-- pink tip), uploaded as model 96930448698996
		GothicBat = {
			texture = "rbxassetid://111197209449835",
			pieces = {
				{
					name = "EarL",
					mesh = 111731956855345,
					size = { 0.3638, 0.3755, 0.1382 },
					at = { -0.3519, 0.8528, -0.0011 },
					anchor = { -0.3343, 0.7204, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 16, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
				{
					name = "EarR",
					mesh = 88489406212673,
					size = { 0.3664, 0.3795, 0.14 },
					at = { 0.3517, 0.8513, -0.002 },
					anchor = { 0.3344, 0.7208, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 16, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
				{
					name = "WingL",
					mesh = 137310084417243,
					size = { 0.7067, 0.4821, 0.2204 },
					at = { -0.6589, 0.6412, 0.3938 },
					anchor = { -0.32, 0.5, 0.3 },
					flap = { axis = { -0.2756, 0, -0.9613 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 88069061520671,
					size = { 0.7083, 0.4746, 0.2227 },
					at = { 0.6615, 0.6546, 0.3946 },
					anchor = { 0.32, 0.5, 0.3 },
					flap = { axis = { -0.2756, 0, 0.9613 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 84110834357638,
					size = { 0.1221, 0.2419, 0.5623 },
					at = { 0.0143, 0.2155, 0.7477 },
					anchor = { 0, 0.2, 0.485 },
					flap = { axis = { 0, 1, 0 }, degrees = 10, hz = 0.6 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/frost_swan/blue_white.glb (two crystal frills up the lower front sides,
		-- their feathers out past the outline, as the painting has them; the crest on the front under the top), uploaded
		-- as model 106684279429446
		FrostSwan = {
			texture = "rbxassetid://88808323037751",
			pieces = {
				{
					name = "FrillL",
					mesh = 85681272384829,
					size = { 0.4884, 0.6275, 0.529 },
					at = { -0.39, 0.41, -0.2457 },
					anchor = { -0.39, 0.41, -0.3444 },
				},
				{
					name = "FrillR",
					mesh = 133525621422716,
					size = { 0.4674, 0.6264, 0.5276 },
					at = { 0.39, 0.41, -0.2422 },
					anchor = { 0.39, 0.41, -0.3444 },
				},
				{
					name = "Crest",
					mesh = 74536228408578,
					size = { 0.348, 0.2149, 0.2976 },
					at = { -0.0015, 0.7416, -0.3234 },
					anchor = { 0, 0.76, -0.3086 },
				},
			},
		},
	} :: { [string]: WearKit },
}

-- ===== Gaits: how a slime moves along a leg =====
-- (the owner chose them in the movement lab, 2026-10-29: tools/slime/hop_lab_lanes.luau; docs/GAMEPLAY.md 10.1;
-- chosen by shared Gaits.choose, timed by VillagePath, played by SlimeActor / SlimeMotion).
-- A hop gait: HopHeight in body heights, HopStuds the distance of one hop at the starting speed stat, Rest the pause
-- after a landing before the next crouch, Ease = the hop's travel eases in and out of the air time (false = even),
-- HopLean the forward tip while airborne; the rest are the jelly's springs of Config.Slime with this gait's own values
-- (Gravity, CrouchSeconds, CrouchSquash, AirStretch, LandKick, SquashHz, SquashDamping, LeanHz, LeanDamping,
-- VolumeBulge). One hop takes CrouchSeconds + air time + Rest. A glide gait has no hops: GlideSpeed in studs a
-- second, GlideBob / GlideBobHz the squash wave while it slides, GlideLean the forward tip, GlideRampSeconds the
-- time to reach (and leave) full speed. The speed stat scales HopStuds and GlideSpeed (Config.Village.WalkPerSpeed).
Config.Gaits = {
	walk = { -- lab lane E "Big leaps": going to work, errands, carrying
		HopHeight = 0.8,
		HopStuds = 4.5,
		Rest = 0.4,
		Ease = false,
		HopLean = 0.12,
		Gravity = 12,
		CrouchSeconds = 0.22,
		CrouchSquash = -0.34,
		AirStretch = 0.2,
		LandKick = 3.5,
		SquashHz = 3.2,
		SquashDamping = 0.25,
		LeanHz = 2.2,
		LeanDamping = 0.35,
		VolumeBulge = 0.55,
	},
	stroll = { -- lab lane F "Slow and soft": wandering, sightseeing, courting
		HopHeight = 0.2,
		HopStuds = 1.4,
		Rest = 0.45,
		Ease = true,
		HopLean = 0.05,
		Gravity = 5,
		CrouchSeconds = 0.3,
		CrouchSquash = -0.2,
		AirStretch = 0.1,
		LandKick = 1.5,
		SquashHz = 2,
		SquashDamping = 0.3,
		LeanHz = 1.6,
		LeanDamping = 0.4,
		VolumeBulge = 0.55,
	},
	baby = { -- lab lane A "Gentle": babies walking
		HopHeight = 0.15,
		HopStuds = 1.2,
		Rest = 0.25,
		Ease = false,
		HopLean = 0.04,
		Gravity = 9,
		CrouchSeconds = 0.16,
		CrouchSquash = -0.18,
		AirStretch = 0.08,
		LandKick = 2,
		SquashHz = 2.8,
		SquashDamping = 0.35,
		LeanHz = 2.2,
		LeanDamping = 0.4,
		VolumeBulge = 0.55,
	},
	babyQuick = { -- lab lane D "Quick hops": babies hurrying (following an adult, playing)
		HopHeight = 0.12,
		HopStuds = 1,
		Rest = 0.02,
		Ease = false,
		HopLean = 0.05,
		Gravity = 18,
		CrouchSeconds = 0.06,
		CrouchSquash = -0.16,
		AirStretch = 0.1,
		LandKick = 1.8,
		SquashHz = 4.5,
		SquashDamping = 0.4,
		LeanHz = 3,
		LeanDamping = 0.45,
		VolumeBulge = 0.5,
	},
	glide = { -- lab lane G "Glide": tired or hungry slimes, sad feelings
		GlideSpeed = 2,
		GlideBob = 0.035,
		GlideBobHz = 2.2,
		GlideLean = 0.07,
		GlideRampSeconds = 0.4,
		SquashHz = 3,
		SquashDamping = 0.35,
		LeanHz = 2.2,
		LeanDamping = 0.4,
		VolumeBulge = 0.55,
	},
	bouncy = { -- lab lane B "Bouncy": kept, unused
		HopHeight = 0.45,
		HopStuds = 2.5,
		Rest = 0.1,
		Ease = false,
		HopLean = 0.08,
		Gravity = 14,
		CrouchSeconds = 0.1,
		CrouchSquash = -0.32,
		AirStretch = 0.18,
		LandKick = 3.5,
		SquashHz = 4,
		SquashDamping = 0.2,
		LeanHz = 2.6,
		LeanDamping = 0.35,
		VolumeBulge = 0.55,
	},
	heavy = { -- lab lane C "Heavy jelly": kept, unused
		HopHeight = 0.22,
		HopStuds = 1.6,
		Rest = 0.3,
		Ease = false,
		HopLean = 0.03,
		Gravity = 12,
		CrouchSeconds = 0.22,
		CrouchSquash = -0.38,
		AirStretch = 0.05,
		LandKick = 4.5,
		SquashHz = 2.2,
		SquashDamping = 0.22,
		LeanHz = 1.8,
		LeanDamping = 0.4,
		VolumeBulge = 0.7,
	},
}

-- ===== Player profiles and saving =====
-- (owned by ProfileLogic, server ProfileStore and PlayerData)
-- The owner's sharpest complaint about the web game was lost progress, and they also disliked
-- constant saving (docs/reference/05-owner-history-part1.md §2-3): save at key moments plus every
-- few minutes, on leave and on shutdown, and never load or write over data we are unsure of.

Config.Save = {
	-- DataStore name and key: one key a player, Save.KeyPrefix .. userId.
	StoreName = "GooLineage_Profiles_v1",
	KeyPrefix = "Player_",
	-- A test switch, off in anything committed: a Studio play test may use the real store only when on.
	StudioUsesRealStore = false,
	-- The data shape's version. Bump it with each change of shape and add a migration for it.
	-- 2: discoveries gained the material bucket (docs/MATERIALS.md).
	-- 3: appearance determines colour genes; the pattern gene is retired.
	-- 4: living-village needs, jobs, pantry, pairs and incubators replace legacy farm fields.
	-- 5: plot-by-plot growing vegetables with safe migration from the old timed output.
	-- 6: per-cook recipes and per-slime automatic dishes and buff sources.
	-- 7: the tutorial's step and the intros seen (`guide`).
	-- 8: the daily check-in, quests and online gifts (`rewards`), lifetime counts of slimes sold and meals eaten.
	-- 9: the Slime Dungeon's best level cleared (`dungeon`).
	-- 10: gear: the bag (`gear` on the farm) and what each slime wears (`gear` on the slime).
	-- 11: the Arena (`arena`: points, team, tickets, the match in flight, season rewards claimed, quests, shop).
	-- 12: the Lucky Wheel (`rewards.wheel`), weekly quests, goals, check-in totals and milestones, redraws of the day's quests,
	--     and lifetime counts of waves, Arena attacks, gear made, dishes, fish, crops, wheel spins and seconds played.
	-- 13: what Robux sells (docs/MONETIZATION.md): `boosts` (Gold and Hatch Potion end times), `robux` (receipts granted,
	--     the passes Roblox said the player owns, the Starter Pack flag, quest redraws and Streak Savers bought and not
	--     used yet), and six teams in place of four.
	SchemaVersion = 13,
	-- A stored envelope without a version is this one.
	FirstSchemaVersion = 1,

	-- Session lock: a lock not refreshed for LockStaleSeconds belongs to a dead server and may be
	-- taken over. A live server refreshes its locks every LockRefreshSeconds even when idle.
	-- (long enough to outlast a few minutes of DataStore trouble: a failed write also delays the lock's refresh)
	LockStaleSeconds = 300,
	LockRefreshSeconds = 60,
	-- Joining while another server still holds a fresh lock (a quick server hop): retry this many
	-- times, this far apart, then kick with a friendly "rejoin in a few minutes" instead of loading stale data.
	LoadLockRetries = 6,
	LoadLockWaitSeconds = 5,

	-- Each DataStore call: up to Retries tries, waiting RetryBase * 2^(try-1) seconds (at most RetryMax).
	Retries = 5,
	RetryBaseSeconds = 1,
	RetryMaxSeconds = 16,
	-- When the server's DataStore request budget is empty, wait for it in steps, up to a limit.
	BudgetPollSeconds = 1,
	BudgetMaxWaitSeconds = 20,
	-- Poll step while a profile's previous write is still in flight.
	BusyPollSeconds = 0.1,

	-- When to write: a changed (dirty) profile every AutosaveSeconds (the owner: "every 5 minutes is
	-- enough"); a key moment (hatch, breed, sell, buy, run end) KeyMomentDelaySeconds after the
	-- first one, so a burst of moments becomes one write; never two writes of one key closer than
	-- MinSecondsBetweenWrites (Roblox allows one write a key every 6 s).
	AutosaveSeconds = 300,
	KeyMomentDelaySeconds = 4,
	MinSecondsBetweenWrites = 7,
	-- After a write failed every retry, wait this long before the next try (the data stays dirty).
	FailedSaveRetrySeconds = 30,
	-- How often the server looks for profiles to write.
	TickSeconds = 1,
	-- BindToClose gives 30 s; flush every profile within this.
	ShutdownSeconds = 25,

	-- Size budget (characters of JSON; Roblox's limit is 4,194,304 a key). Warn at WarnBytes, keep
	-- the last-good copy only while the whole envelope stays under LastGoodMaxBytes, refuse to
	-- write above MaxBytes (the previous save stays intact).
	WarnBytes = 2_000_000,
	LastGoodMaxBytes = 3_000_000,
	MaxBytes = 4_000_000,
	-- The last-good copy is the previous save, refreshed at most this often, so it is minutes to
	-- half an hour old when a bad save needs it.
	LastGoodEverySeconds = 30 * 60,
}

-- ===== Village client only: images, animation update budget and compact touch UI =====
Config.VillageClient = {
	UpdateSeconds = 1 / 20,
	FarUpdateSeconds = 1 / 5,
	HopHeight = 0.18,
	SlimeSeparationStuds = 2.5,
	SeparationBlend = 0.3,
	FacingTurnSeconds = 0.2,
	SeparationMaxStuds = 0.65,
	SeparationSmoothSeconds = 0.15,
	CarryTopOffset = 0.1,
	-- Feet on the ground: the client measures the ground again after the slime moved this far.
	GroundRecastStuds = 0.25,
	GroundProbeUp = 2.5,
	-- (far enough to find the floor under a slime the server placed in the air: it then stands, not hovers)
	GroundProbeDown = 40,
	GroundProbeRadius = 0.6,
	-- A tossed or taken item meets the bin this high above the bin's foot.
	HandBinHeight = 1.6,
	-- The fishing rod (the owner, 2026-10-29: "far too small and facing the wrong way"): its size against
	-- the kit model (5.4 studs, nearly two slime heights), the grip in front of the body (studs for a full-size
	-- slime: up, forward) and its tilt forward from upright while fishing, walking, at the top of the
	-- cast's back swing and while reeling in.
	RodScale = 1,
	RodGripUp = 1.1,
	RodGripForward = 1.75,
	RodFishTilt = 55,
	RodWalkTilt = 12,
	RodBackTilt = -25,
	RodReelTilt = 30,
	-- The cast: the back swing takes this share of the cast, the bobber flies the rest; it lands this far
	-- in front of the slime, bobs this much, and dips this much when a fish bites.
	CastBackShare = 0.35,
	CastStuds = 7,
	BobberBobStuds = 0.08,
	BobberBobHz = 0.8,
	BobberBiteDip = 0.35,
	-- the bobber a little larger than the kit rod's, so it reads on the water from the game's camera
	BobberScale = 1.6,
	-- the bite takes this share of the reel; the rest pulls the bobber back to the tip
	BiteShare = 0.3,
	-- the jelly's lean into a toss (a take leans the other way) and the squash of the reach
	TossLeanKick = 2.5,
	TossSquashKick = 1.2,
	-- a slime popping into its work place on assignment
	PopSquashKick = -3,
	PopHop = 0.35,
	LineWidth = 0.07,
	LineColour = "#fff4dd",
	-- Hoe and watering can, held at a believable size for a 3-stud slime (kit models: 4.4 and about 2 studs).
	HoeScale = 0.85,
	HoeSwingDegrees = 50,
	HoeSwingHz = 1.3,
	CanScale = 0.8,
	-- The can over the head (the owner, 2026-10-29: it lay on the ground): its foot this high above the feet
	-- and this far forward (studs for a full-size slime), the spout (+X end of the kit can when 1, -X when -1)
	-- turned to the front and tipped down this many degrees, wobbling as it pours.
	CanUp = 3.2,
	CanForward = 0.3,
	CanSpoutSign = 1,
	CanPourDegrees = 30,
	CanPourWobble = 8,
	CanPourHz = 0.9,
	-- The cook's frying pan (src/client/WorkMoves.luau; the owner, 2026-11-04: cooks get a pan, trainees a dummy): its
	-- size against the built pan (about 2.4 studs long), its handle's end in front of the body (studs for a full-size
	-- slime: up, forward); one toss every TossSeconds, the pan flicking up this many degrees and the ingredient flying
	-- this high, turning over, for TossAirShare of the toss; the pan jiggles in between; the ingredient is this big.
	Cook = {
		PanScale = 1.25,
		PanUp = 0.6,
		PanForward = 1.35,
		TossSeconds = 1.6,
		FlickDegrees = 28,
		FlickShare = 0.12,
		TossAirShare = 0.55,
		TossStuds = 1.6,
		JiggleDegrees = 3,
		JiggleHz = 6,
		FoodStuds = 1,
		TossLeanKick = -1.4,
		TossSquashKick = 1,
		-- the steam off the pan (Roblox's own smoke picture), a few puffs a second
		SteamRate = 4,
	},
	-- The trainee at the training ground's dummy or punching bag (whichever stands nearest its spot): every BeatSeconds a
	-- windup, a lunge to the target's skin and back, a mark in the style of the stat it trains (FightFx, the battle art),
	-- every HeavyEvery-th blow a heavy one; the target rocks from its foot. A target farther than MaxLungeStuds (the
	-- archery target) is spat at with goo instead.
	Train = {
		BeatSeconds = 1.5,
		WindupShare = 0.3,
		ContactShare = 0.42,
		HoldShare = 0.52,
		BackShare = 0.85,
		WindupStuds = 0.4,
		WindupSquash = -2.2,
		LungeHop = 0.18,
		SlimeRadius = 1.3,
		MaxLungeStuds = 9,
		HeavyEvery = 4,
		-- the dummy: its pieces within this far of the post (flat) and this far above its foot rock with it
		DummyRadius = 3,
		DummyFootClear = 0.5,
		RockDegrees = 7,
		HeavyRock = 1.8,
		RockHz = 2.2,
		RockDamp = 3.5,
		RockSeconds = 1.6,
		-- the goo spat at a far target, and at the archery target's board: this share of its height above its box's middle,
		-- this deep from the face
		Shot = "gooBlob",
		BoardLift = 0.12,
		BoardDepth = 0.3,
	},
	GhostFloat = 0.35,
	GhostFloatHz = 0.35,
	-- A dungeon monster drawn by its pieces walks (its legs swing in full) while it moves faster than this, studs a second.
	CreatureWalkSpeed = 0.8,
	EggWobbleWindow = 8,
	EggWobbleDegrees = 10,
	EggWobbleHz = 4,
	EggHeight = 1.4,
	-- An egg stands on the bed found by a ray from this far above its marker down this far, this much above it.
	EggRestProbeUp = 1.2,
	EggRestProbeDown = 3,
	EggRestLift = 0.02,
	-- What the breeding sheet says when a set pair waits (Breeding.pairReady's reason, published on the Pairs attribute).
	PairWaiting = {
		PARENT_ON_COOLDOWN = "Resting",
		PARENT_NEEDS = "Hungry or tired",
		PARENT_TOO_YOUNG = "Too young",
		PARENT_FALLEN = "Ghost",
		EGG_CAP_REACHED = "Nests full",
		SLIME_CAP_REACHED = "Village full",
		MISSING_PARENT = "Pick two slimes",
	},
	-- an egg is drawn this many times its kit size, the same real size in a nest, an incubator and on a slime's head
	-- (the owner: 3x in the nest, then 30% smaller, 2026-10-30)
	EggScale = 2.1,
	-- The progress clock over a slime at work, a courting pair or an egg (owner, 2026-10-30). Sizes are fractions of
	-- the slime's own scale (about 3 studs), so the clock scales with the camera like the slime; it sits to the
	-- camera's right of the head so it never covers the emote above it.
	ClockSize = 0.62,
	ClockSideStuds = 0.7,
	ClockLiftStuds = 0.05,
	-- an egg's clock: its size, and how far above the egg's top it floats
	EggClockSize = 2,
	EggClockGap = 0.9,
	ClockMaxDistance = 90,
	-- ring and face (fractions of the clock's size; the ring's pixel thickness)
	ClockRingInset = 0.1,
	ClockRingPixels = 6,
	ClockIconShare = 0.44,
	-- appear (grows in), complete (a small pop) and leave (shrinks away); a clock never flickers
	ClockInSeconds = 0.2,
	ClockPopSeconds = 0.3,
	ClockPopGrow = 0.3,
	ClockOutSeconds = 0.2,
	-- a clock that leaves with at least this much done counts as finished and pops first
	ClockDoneFraction = 0.97,
	-- which owner icon (Config.Ui.Icons) sits in the middle of each kind of clock
	ClockIcons = {
		fishing = "fishing",
		garden = "garden",
		kitchen = "kitchen",
		training = "training",
		court = "breeding",
		egg = "slimes",
	},
	CarryHeight = 1.1,
	CarryScale = 0.42,
	SleepBillboardPixels = 32,
	SocialBillboardPixels = 38,
	BillboardDistance = 65,
	MaxDrawDistance = 400,
	-- A slime's body (and its face rig) exists only while the camera is within MaxDrawDistance of it, and is dropped again
	-- once it is MaxDrawDistance x BodyDropMargin away: the villages of a server of 8 cost nothing from across the valley.
	BodyDropMargin = 1.25,
	NearWorkDistance = 80,
	StandInSize = 1,
	BodyHeight = 3,
	ScaleRebuildThreshold = 0.06,
	BabyFollowStuds = 2,
	WorkShiftStuds = 0.65,
	WorkShiftHz = 0.6,
	FacingThreshold = 0.01,
	GhostTransparency = 0.55,
	GhostWhiten = 0.5,
	MinimumBodyScale = 0.1,
	EggSlotSpacing = 2,
	SheetWalkAwayStuds = 22,
	PromptDistance = 12,
	PromptHoldSeconds = 0,
	UiWidth = 430,
	UiHeight = 300,
	UiRowHeight = 54,
	UiButtonSize = 48,
	UiPadding = 12,
	ToastSeconds = 3,
	HudIconSize = 22,
	HudHeight = 40,
	FontTiny = 14,
	FontSmall = 15,
	FontNormal = 16,
	FontSub = 18,
	FontHeader = 20,
	-- The body and its skin use the owner's existing stage textures.
	WhiteMap = "rbxassetid://71688274727636",
	NormalMap = "rbxassetid://79029102102054",
	RoughMap = "rbxassetid://105770337560670",
	RoughMetalMap = "rbxassetid://135625603344269",
	MirrorMap = "rbxassetid://138184721337623",
	StandInColour = "#dedbd3",
	Parchment = "#fff4dd",
	Brown = "#69472a",
	Button = "#c98a3d",
	Cream = "#fffdf4",
	Card = "#f5e7c7",
}

-- ===== The dish buff on a slime (src/client/SlimeBuffs.client.luau) =====
-- The server publishes BuffStat / BuffPercent / BuffUntil / BuffRarity on each slime; the client draws a small badge
-- beside the emote and a few particles of the stat's own design while the buff lives. Sizes marked "body" are shares
-- of the slime's body height (studs); a rate is particles a second before the rarity and effects-tier multipliers.
Config.SlimeBuffFx = {
	-- master switch for the particles (the badge is a plain GUI and stays)
	Enabled = true,
	-- how often the live buffs are looked at (seconds); expiry, streaming and distance are checked here, never per frame
	PollSeconds = 0.5,
	-- Budget: particles only for the nearest MaxFx buffed slimes within FxStuds of the camera, badges within
	-- BadgeStuds (at most MaxBadges), at most MaxBursts start bursts alive at once. A slime keeps its place until it is
	-- ReleaseMargin x the distance away (no flapping at the edge).
	FxStuds = 60,
	MaxFx = 6,
	BadgeStuds = 65,
	MaxBadges = 16,
	MaxBursts = 4,
	ReleaseMargin = 1.2,
	-- Effects setting: the graphics quality level (1..21) at or below which particles are off, and at or below which
	-- they are the light version (rates and bursts times LightShare). Phones sit low, so the particles stay few.
	LowQualityMax = 2,
	LightQualityMax = 5,
	LightShare = 0.5,
	-- a buff that shows up within this long of the slime appearing is its first state, not a dish eaten: no burst
	AnnounceAfterSeconds = 2,
	-- a burst that could not be drawn (no body yet) is forgotten after this long
	BurstStaleSeconds = 3,
	BurstLifeSeconds = 1.6,
	-- The badge (pixels at a 900 px high screen, scaled with the screen between the two limits). It sits where the emote
	-- sits (1.25 body heights up) but on the other side: SideBody body heights toward the viewer's left.
	Badge = {
		Width = 84,
		Height = 30,
		TextSize = 19,
		StrokePixels = 2,
		ScaleReference = 900,
		ScaleMin = 0.8,
		ScaleMax = 1.3,
		LiftBody = 0.75,
		SideBody = 0.5,
		PopSeconds = 0.22,
		IconPixels = 22,
	},
	-- Rarity: rate / size multipliers, the faintest the particle gets at its peak (0 = solid; lower = brighter) and the
	-- burst multiplier. The badge frame takes the colour from Config.Food.Rarities.
	Rarity = {
		common = { rate = 1, size = 1, alpha = 0.3, burst = 1 },
		uncommon = { rate = 1.4, size = 1.1, alpha = 0.2, burst = 1.4 },
		rare = { rate = 1.9, size = 1.2, alpha = 0.1, burst = 1.9 },
		epic = { rate = 2.6, size = 1.35, alpha = 0, burst = 2.6 },
	},
	-- Every particle is the owner's icon of its stat (Config.Ui.Icons), untinted, each with its own motion: soft sparks,
	-- flames and smoke all vanished on the bright village ground in a play test. Sizes are shares of the body's height.
	-- ---- attack: stars spinning up from the body, fast ----
	Attack = {
		Rate = 4,
		Size = 0.2,
		LifeMin = 0.6,
		LifeMax = 0.9,
		SpeedMin = 0.9,
		SpeedMax = 1.5,
		Rise = 1,
		Spread = 14,
		BurstCount = 7,
		BurstSize = 0.3,
		BurstSpeedMin = 2.2,
		BurstSpeedMax = 3.6,
		BurstLife = 0.55,
	},
	-- ---- defence: a few of the owner's shields breathing in and out on the body's skin ----
	Defence = {
		Rate = 1.5,
		Size = 0.3,
		Life = 1.7,
		Drift = 0.25,
		Peak = 0.3,
		BurstCount = 3,
		BurstSize = 0.5,
		BurstSpeed = 1.1,
		BurstLife = 0.7,
	},
	-- ---- speed: bolts thrown back behind the body; fewer while it stands still ----
	Speed = {
		Rate = 5,
		IdleShare = 0.6,
		Size = 0.2,
		LifeMin = 0.35,
		LifeMax = 0.5,
		SpeedMin = 2.2,
		SpeedMax = 3.6,
		Alpha = 0.15,
		BurstCount = 7,
		BurstSize = 0.28,
		BurstSpeed = 5,
		BurstLife = 0.4,
	},
	-- ---- hp: small hearts that float up slowly and fade ----
	Hp = {
		Rate = 2.5,
		Size = 0.2,
		LifeMin = 1.3,
		LifeMax = 1.9,
		SpeedMin = 0.5,
		SpeedMax = 0.9,
		Spread = 28,
		BurstCount = 5,
		BurstSize = 0.26,
		BurstSpeedMin = 1.2,
		BurstSpeedMax = 2,
		BurstFall = 1.6,
		BurstLife = 1.1,
	},
}

-- ===== The hatch reveal (src/client/HatchReveal.luau, started by Village.client when a hatched egg leaves the nest) =====
-- A plain hatch is a small clean pop; a Dual, a Material and a Secret each have their OWN design, bigger with rarity:
-- anticipation (the egg shakes harder, a light builds) -> flash -> main picture -> secondary glitter -> decay. The
-- baby's body stays off until the flash. Everything is the owner's battle art or Roblox's own sparkles, never a code
-- shape; no camera effect, no white screen flash (docs/reference/04-vfx-animation.md §14, §15). Times are seconds from
-- the moment the egg leaves the nest; sizes are studs (the egg is about 3 studs tall); a count is particles.
Config.HatchFx = {
	Enabled = true,
	-- a hatch farther than this from the camera is not drawn (the baby just appears)
	ViewStuds = 220,
	-- at most this many reveals at once; one more only gets the small pop (and the baby shows at once)
	MaxLive = 3,
	-- another player's hatch (their village) is drawn with this share of the particles and no title
	OthersShare = 0.6,
	-- a removed egg counts as hatched when its HatchAt is at most this far ahead of the server clock; the baby's data may
	-- arrive a moment later than the egg's removal: wait this long for it before drawing a plain pop
	HatchSlackSeconds = 3,
	WaitSlimeSeconds = 1.5,
	-- 1 = real time. A play test sets it below 1 to slow a reveal down so a screenshot can catch it; 1 in anything committed
	TimeScale = 1,
	-- Effects setting (as Config.SlimeBuffFx): the graphics quality (1..21) at or below which the reveal has no particles
	-- and no light (a short shake and the title only), and at or below which it is the light version.
	LowQualityMax = 2,
	LightQualityMax = 5,
	LightShare = 0.5,
	LowAnticipationSeconds = 0.3,
	-- Where each picture comes from: Roblox's own sparkles, and the owner's battle art (Config.Zombies.View.Fx.Textures).
	Textures = {
		sparkle = "rbxasset://textures/particles/sparkles_main.dds",
		-- sparkStar, a silver four-point star: tinted, it is every glint and streak
		star = "rbxassetid://106004463491821",
		-- holyHit, a golden sunburst of rays: the Dual's picture
		sunburst = "rbxassetid://123273947779821",
		-- shockwave, a white spiked flash with a cool edge: the Material's picture
		prism = "rbxassetid://94188471939456",
		-- burstArcane, a violet star with lightning: the Secret's picture; moteArcane its small violet star
		arcane = "rbxassetid://75506448951291",
		arcaneStar = "rbxassetid://118302010408844",
	},
	-- ---- plain: a quick double shake, then the baby's own colour pops out in a few sparkles ----
	Plain = {
		Anticipation = 0.4,
		WobbleFrom = 5,
		WobbleTo = 9,
		HzFrom = 7,
		HzTo = 11,
		Swell = 0.04,
		Sparkles = 12,
		SparkleSize = 0.55,
		Stars = 5,
		StarSize = 0.6,
		SpeedMin = 5,
		SpeedMax = 9,
		LifeMin = 0.45,
		LifeMax = 0.8,
		-- how much white the baby's colour gets in its sparkles (0 = its colour, 1 = white)
		WhiteShare = 0.45,
		EndSeconds = 0.9,
	},
	-- ---- dual: a golden sunburst with a fountain of stars in the design's own two colours ----
	Dual = {
		Anticipation = 0.9,
		WobbleFrom = 6,
		WobbleTo = 15,
		HzFrom = 8,
		HzTo = 15,
		Swell = 0.1,
		-- the light that builds in the egg (brightness at the flash's start, range) and flares at the flash
		Glow = 1.2,
		GlowRange = 12,
		GlowColour = "#ffd75e",
		FlashLight = 2.4,
		LightSeconds = 0.7,
		-- the egg's tint (the glow colour): how see-through it still is at the end (1 = none)
		TintEnd = 0.72,
		-- stars gathering into the egg while it shakes (a second, at the start and at the end)
		GatherRateFrom = 10,
		GatherRateTo = 80,
		GatherSize = 0.9,
		GatherRadius = 3.2,
		-- the sunburst: the picture's size and seconds, its turn (degrees a second), and a smaller one turning back
		SunSize = 8,
		SunSeconds = 0.6,
		SunSpin = 45,
		SunBackSize = 5.5,
		SunBackDelay = 0.1,
		-- the fountain: stars in the two colours of the design (more white = brighter), and gold sparkles
		Stars = 18,
		StarSize = 0.85,
		StarSpeedMin = 9,
		StarSpeedMax = 15,
		StarGravity = 20,
		Sparkles = 24,
		SparkleSize = 0.6,
		Gold = "#ffd75e",
		Cream = "#fff6e0",
		-- the second and third showers (seconds after the flash) and how many stars each
		LaterAt = { 0.28, 0.6 },
		LaterStars = 9,
		-- the label over the egg: seconds shown and the size (pixels at a 900 px high screen)
		LabelSeconds = 1.6,
		EndSeconds = 2.2,
	},
	-- ---- material: the shell glints like polished stuff, then a prism flash and falling glitter in the material's colour ----
	Material = {
		Anticipation = 0.85,
		WobbleFrom = 4,
		WobbleTo = 11,
		HzFrom = 7,
		HzTo = 13,
		Swell = 0.08,
		Glow = 1,
		GlowRange = 11,
		FlashLight = 2,
		LightSeconds = 0.6,
		TintEnd = 0.6,
		-- glints on the shell: sparkles a second, rising (the shell is the sphere of GlintRadius)
		GlintRateFrom = 12,
		GlintRateTo = 80,
		GlintSize = 1.1,
		GlintRadius = 1.7,
		-- the prism flash and a second turned one
		PrismSize = 7,
		PrismSeconds = 0.42,
		PrismSpin = -70,
		PrismBackSize = 4.5,
		-- glitter: sparkles and tinted stars falling slowly, counted for a common material; rare x RareShare, precious x PreciousShare
		Glitter = 30,
		GlitterSize = 0.45,
		GlitterSpeedMin = 3,
		GlitterSpeedMax = 8,
		GlitterGravity = 5,
		GlitterLifeMin = 1,
		GlitterLifeMax = 1.7,
		Stars = 12,
		StarSize = 0.8,
		RareShare = 1.3,
		PreciousShare = 1.8,
		-- precious materials (Gold, Silver) add a second prism flash this long after the first
		PreciousPrismDelay = 0.16,
		LaterAt = { 0.4 },
		LaterGlitter = 14,
		LabelSeconds = 1.5,
		EndSeconds = 2.2,
	},
	-- ---- secret: the egg rises and shakes while violet stars pour into it and a column of light streaks goes up; the star bursts
	-- with lightning, rainbow glints rain down, and a title owns the middle for a moment ----
	Secret = {
		Anticipation = 1.5,
		WobbleFrom = 4,
		WobbleTo = 18,
		HzFrom = 6,
		HzTo = 17,
		Swell = 0.14,
		-- the egg floats up this many studs while it gathers power
		Rise = 0.7,
		Glow = 1.6,
		GlowRange = 14,
		GlowColour = "#b478ff",
		FlashLight = 2.2,
		LightSeconds = 1,
		TintEnd = 0.62,
		-- violet stars pour in from a sphere (a second at the start and at the end)
		GatherRateFrom = 12,
		GatherRateTo = 110,
		GatherSize = 2,
		GatherRadius = 6,
		-- the column of light: tall streaks of the star rising from the egg, from this share of the anticipation on
		ColumnFrom = 0.35,
		ColumnRateFrom = 5,
		ColumnRateTo = 34,
		ColumnSize = 1,
		ColumnSpeed = 30,
		ColumnLife = 0.7,
		ColumnBurst = 22,
		-- the burst: the lightning star, and a smaller one turning back
		StarSize = 12,
		StarSeconds = 0.75,
		StarSpin = 35,
		StarBackSize = 7.5,
		StarBackDelay = 0.12,
		-- rainbow glints and violet motes, and sparkles floating up
		Glints = 34,
		GlintSize = 0.95,
		GlintSpeedMin = 8,
		GlintSpeedMax = 16,
		GlintGravity = 9,
		Motes = 26,
		MoteSize = 0.9,
		Sparkles = 30,
		SparkleSize = 0.6,
		Violet = "#b478ff",
		-- the second wave (seconds after the flash) and how many glints it has
		LaterAt = { 0.35, 0.8 },
		LaterGlints = 16,
		-- the title: a delay after the flash, the pop-in, how long it holds, the fade, and how far it rises
		TitleDelay = 0.15,
		TitlePopSeconds = 0.4,
		TitleHoldSeconds = 1.5,
		TitleFadeSeconds = 0.45,
		EndSeconds = 3,
	},
	-- the rainbow of the Secret (the original's palette, docs/reference/04-vfx-animation.md §7)
	Rainbow = { "#ff6ad5", "#6ad5ff", "#ffe66a", "#8dff6a", "#c48dff", "#ffffff" },
	-- The title / label over the egg: pixels at a 900 px high screen (scaled with the screen between the limits), studs
	-- above the egg's top, how far it floats up while shown.
	Title = {
		Width = 460,
		Height = 120,
		SmallWidth = 240,
		SmallHeight = 64,
		ScaleReference = 900,
		ScaleMin = 0.8,
		ScaleMax = 1.4,
		Lift = 2.8,
		Rise = 1.2,
		Stroke = "#3a2466",
		Cream = "#fffdf4",
		DualText = "#ffd75e",
		SecretText = "#e8dcff",
		StrokePixels = 2,
	},
}

-- ===== The tutorial and the intros (docs/GAMEPLAY.md §12; rules in shared/Guide, server/Guide, client/UiGuide) =====
Config.Guide = {
	-- The first-time tutorial, in order; after the last step it is "done". Each step's line, target and check: shared/Guide.
	Steps = {
		"book",
		"fish",
		"garden",
		"food",
		"pair",
		"egg",
		"hatch",
		"market",
		"sell",
		"home",
		"pads",
		"team",
		"attack",
		"win",
	},
	-- The intros of later features, most urgent first: each opens once, when its feature starts to matter.
	Intros = {
		"ghost",
		"vault",
		"full",
		"upgrade",
		"repeat",
		"team2",
		"team3",
		"team4",
		"kitchen",
		"dish",
		"training",
		"recipes",
		"rewards",
		"index",
		"dungeon",
	},
	-- (a step or intro id a request may name is at most this long)
	IdMaxLength = 16,
	-- The server looks at every player's step this often.
	CheckSeconds = 1,
	-- "Home" and "at the Market": the character stands within this share of a plot's side of its plot's (or the Market's)
	-- centre.
	HomeShare = 0.55,
	-- The client. The line sits on a card at the top edge, under the topbar; buttons at its ends.
	CardWidth = 440,
	CardHeight = 52,
	-- The world pointer: the owner's gold arrow over the target, pointing down, bobbing; pixels and studs.
	PointerSize = 64,
	PointerLift = 5,
	PointerBobStuds = 0.8,
	PointerBobSeconds = 0.9,
	PointerMaxDistance = 2000,
	-- The arrow beside a button on the screen, and the button's slow pulse.
	HudPointerSize = 44,
	HudPointerGap = 2,
	HudPointerBobPixels = 8,
	PulseScale = 1.12,
	PulseSeconds = 0.6,
	-- The trail of arrows on the ground from the character's feet to the target, shown while farther than TrailMinStuds:
	-- at most TrailMaxArrows, TrailSpacing apart, creeping forward at TrailSpeed (studs, studs a second).
	TrailArrowStuds = 1.8,
	TrailMaxArrows = 20,
	TrailSpacing = 3,
	TrailSpeed = 3,
	TrailStartStuds = 2,
	TrailEndStuds = 3,
	TrailMinStuds = 14,
	TrailFootDrop = 2.6,
	TrailLift = 0.6,
	TrailTransparency = 0.1,
	-- A screen the server cannot see (the book, the food panel) is looked for this often while its step waits.
	SeenPollSeconds = 0.25,
}

-- ===== Rewards for coming back (docs/GAMEPLAY.md §13; rules in shared/Rewards, server/Rewards, client/UiRewards) =====
-- A day is the UTC day. Coins in a reward are `coins` times the price of the village's cheapest next upgrade (so a reward
-- keeps its worth as the farm grows), rounded to two figures, never under CoinFloor. `luck` is minutes of the luck
-- potion (Config.Luck.Potion): it adds to the time left, up to LuckMaxMinutes. Paid coins are not held by the vault.
-- A reward (docs/MONETIZATION.md §4) is { coins = share, luck = minutes, spins = n, items = { { kind, id, count } } }; an
-- item's kind is "food" (a raw food, into the storehouse), "dish" (into the fridge), "material" (farm.materials, an id of
-- Config.Dungeon.Materials) or "gear" (the gear bag, an id of Config.Smithy.Gear). Food and dishes that do not fit the
-- storehouse or the fridge are lost, as the Dungeon's food drop is.
type RewardItem = { kind: string, id: string, count: number }
type Reward = { coins: number?, luck: number?, spins: number?, items: { RewardItem }? }
type Gift = { minutes: number, coins: number?, luck: number?, spins: number?, items: { RewardItem }? }
type Milestone = { total: number, coins: number?, luck: number?, spins: number?, items: { RewardItem }? }
type Goal = {
	id: string,
	kind: string,
	need: number,
	coins: number?,
	luck: number?,
	spins: number?,
	items: { RewardItem }?,
}
type WeeklyQuest = { kind: string, need: number, reward: Reward }
type WheelSlice = { id: string, name: string, weight: number, reward: Reward }

local function food(id: string, count: number): RewardItem
	return { kind = "food", id = id, count = count }
end
local function material(id: string, count: number): RewardItem
	return { kind = "material", id = id, count = count }
end
-- The food basket: a few of the farm's ordinary foods.
local FoodBasket = { food("fish", 3), food("carrot", 3), food("cabbage", 3) }

Config.Rewards = {
	CoinFloor = 100,
	LuckMaxMinutes = 120,
	FoodBasket = FoodBasket,
	-- The daily check-in: day n of a run of days in a row, then day 1 again. A day missed starts the run over.
	Daily = {
		{ coins = 0.5, items = FoodBasket },
		{ coins = 0.75, spins = 1 },
		{ coins = 1, items = { material("ore", 5) } },
		{ luck = 30, items = { material("rare_part", 2) } },
		{ coins = 1.5, spins = 2 },
		{ coins = 2, items = { material("monster_core", 1) } },
		{ coins = 3, luck = 60, spins = 3, items = { material("monster_core", 2) } },
	} :: { Reward },
	-- Milestones of the total check-ins taken (a run broken does not lose them): each is claimed once, by hand.
	CheckinMilestones = {
		{ total = 14, coins = 4, spins = 3 },
		{ total = 30, coins = 6, spins = 5, items = { { kind = "gear", id = "charm-core", count = 1 } } },
		{ total = 60, coins = 10, spins = 8, items = { material("monster_core", 3) } },
		{ total = 100, coins = 16, spins = 12, luck = 60, items = { material("boss_essence", 2) } },
	} :: { Milestone },
	-- Daily quests: QuestCount a day (easy, medium, medium, hard), drawn from the kinds that fit the farm by a dice of the
	-- player and the day; quest n asks the n-th share of its kind's { least, most } and pays QuestRewards[n]. All of them
	-- claimed: QuestBonus once. FreeRerolls redraws a day are free; more come from Robux (Rewards.rerollQuest, paid).
	-- The kinds are measured by a lifetime count (shared/Rewards.count): wave = Slime Dungeon waves cleared, arena =
	-- Arena attacks settled, craft = gear made at the Smithy, cook = dishes cooked, fish = fish caught, harvest = crops
	-- harvested, find = kinds of slime found, spin = Lucky Wheel spins, play = minutes played.
	QuestCount = 4,
	QuestKinds = {
		"breed",
		"hatch",
		"sell",
		"feed",
		"win",
		"upgrade",
		"wave",
		"arena",
		"craft",
		"cook",
		"fish",
		"harvest",
		"find",
		"spin",
		"play",
	},
	QuestNeed = {
		breed = { 1, 3 },
		hatch = { 1, 3 },
		sell = { 1, 3 },
		feed = { 10, 30 },
		win = { 4, 12 },
		upgrade = { 1, 2 },
		wave = { 2, 6 },
		arena = { 1, 3 },
		craft = { 1, 2 },
		cook = { 2, 6 },
		fish = { 4, 12 },
		harvest = { 4, 12 },
		find = { 1, 2 },
		spin = { 1, 1 },
		play = { 5, 20 },
	},
	QuestRewards = {
		{ coins = 0.3, items = FoodBasket },
		{ coins = 0.5, items = { material("ore", 2) } },
		{ coins = 0.7, items = { material("rare_part", 1) } },
		{ coins = 1, items = { material("monster_core", 1) } },
	} :: { Reward },
	QuestBonus = { luck = 20, spins = 1 } :: Reward,
	FreeRerolls = 1,
	-- "sell" is drawn only for a village of at least this many slimes (the last ones cannot be sold).
	QuestSellMinSlimes = 6,
	-- These kinds are drawn only for a village of at least this level (the Dungeon's own door, Config.Dungeon.EnterMinVillageLevel,
	-- is 15: the waves, the Smithy's materials and a team for the Arena all come from there). cook, fish and harvest are drawn
	-- only while a slime works in that area.
	QuestMinVillage = { wave = 15, arena = 15, craft = 15 },
	QuestWorkArea = { cook = "kitchen", fish = "fishing", harvest = "garden" },
	-- Weekly quests (a UTC week from Monday 00:00, as the Arena's): these five every week, each measured from the week's
	-- start. All five claimed: the Weekly Chest, once. Kept to what any village can do.
	Weekly = {
		{ kind = "hatch", need = 15, reward = { spins = 2 } },
		{ kind = "feed", need = 150, reward = { coins = 2, items = { material("ore", 5) } } },
		{ kind = "win", need = 100, reward = { items = { material("monster_core", 1) } } },
		{ kind = "breed", need = 20, reward = { coins = 1.5, items = { material("rare_part", 3) } } },
		{ kind = "play", need = 120, reward = { spins = 3 } },
	} :: { WeeklyQuest },
	WeeklyChest = {
		coins = 8,
		spins = 5,
		items = { material("monster_core", 2), material("boss_essence", 1) },
	} :: Reward,
	-- Online gifts: minutes played this UTC day (earlier visits count); each taken once a day.
	Online = {
		{ minutes = 1, coins = 0.2 },
		{ minutes = 3, items = FoodBasket },
		{ minutes = 5, coins = 0.4 },
		{ minutes = 10, luck = 10 },
		{ minutes = 15, items = { material("ore", 3) } },
		{ minutes = 20, coins = 0.8 },
		{ minutes = 30, luck = 10, items = { material("rare_part", 1) } },
		{ minutes = 45, coins = 1, items = { { kind = "dish", id = "grilledFish", count = 1 } } },
		{ minutes = 60, coins = 1.5, spins = 1 },
	} :: { Gift },
	-- The server writes the minutes played into the save this often (and when the player leaves).
	OnlineFlushSeconds = 60,
	-- The server looks at every player's rewards this often.
	CheckSeconds = 1,
	-- The client: the rewards sheet, a tile of the check-in and online grids, a quest row, a card of the Index.
	SheetWidth = 520,
	SheetHeight = 440,
	-- (four check-in days a row, three online gifts a row)
	TileWidth = 108,
	OnlineTileWidth = 148,
	TileHeight = 112,
	-- a row of the Quests, Weekly and Goals lists: its height (a touch button inside), the one for a narrow screen where the
	-- buttons go on a second line, the reward's width, a picture in a tile and in a row, the Claim button's width, the red dot
	-- on a tab
	QuestRowHeight = 64,
	QuestRowHeightNarrow = 98,
	RewardWidth = 116,
	TilePartIcon = 22,
	RowPartIcon = 20,
	ClaimWidth = 76,
	TabDot = 14,
	IndexCell = 96,
	IndexCellHeight = 118,
	-- An Index card whose slime is not found yet shows the slime's own picture, darkened: the only light on it is this
	-- ambient colour (its textures still read, so the player sees what to look for). A found Secret has no art yet and
	-- stays a golden shadow (Ui.Colours.Gold).
	LockedAmbient = "#55463d",
	-- The Index builds its cards this many a frame, and the pictures of the cards in view this many a frame, so opening
	-- it (150 kinds) never stalls a phone for a frame.
	IndexCardsPerFrame = 10,
	IndexPicturesPerFrame = 2,
	-- The red dot on the Rewards button while something waits.
	BadgeSize = 18,
}

-- ===== Goals: permanent milestones, each paid once (shared/Rewards, the Goals tab of the Rewards sheet) =====
-- A goal is claimed by hand once its count (shared/Rewards.goalCount) reaches `need`; the reward is Config.Rewards' kind of
-- reward. kind: hatch (eggs hatched), find (kinds of slime found), village (the village level), sell (slimes sold), dungeon
-- (the best Slime Dungeon level cleared), arena (Arena attacks), craft (gear made), wave (Dungeon waves cleared). The list
-- order is the order the tab shows. An id is saved when claimed: never rename one.
Config.Goals = {
	List = {
		{ id = "hatch10", kind = "hatch", need = 10, coins = 1 },
		{ id = "hatch50", kind = "hatch", need = 50, coins = 2, spins = 1 },
		{ id = "hatch200", kind = "hatch", need = 200, coins = 4, spins = 2, items = { material("rare_part", 3) } },
		{
			id = "hatch1000",
			kind = "hatch",
			need = 1000,
			coins = 12,
			spins = 5,
			items = { material("monster_core", 2) },
		},
		{ id = "find10", kind = "find", need = 10, coins = 1 },
		{ id = "find25", kind = "find", need = 25, coins = 2, spins = 1 },
		{ id = "find50", kind = "find", need = 50, coins = 4, spins = 2 },
		{ id = "find100", kind = "find", need = 100, coins = 8, spins = 4, items = { material("monster_core", 1) } },
		{ id = "find150", kind = "find", need = 150, coins = 15, spins = 8, items = { material("boss_essence", 1) } },
		{ id = "village10", kind = "village", need = 10, coins = 2 },
		{ id = "village20", kind = "village", need = 20, coins = 4, spins = 2 },
		{
			id = "village30",
			kind = "village",
			need = 30,
			coins = 6,
			spins = 3,
			items = { material("monster_core", 1) },
		},
		{ id = "village40", kind = "village", need = 40, coins = 8, spins = 4 },
		{
			id = "village50",
			kind = "village",
			need = 50,
			coins = 12,
			spins = 6,
			items = { material("boss_essence", 1) },
		},
		{ id = "sell10", kind = "sell", need = 10, coins = 0.5 },
		{ id = "sell100", kind = "sell", need = 100, coins = 2, spins = 1 },
		{ id = "sell500", kind = "sell", need = 500, coins = 5, spins = 3 },
		{ id = "dungeon3", kind = "dungeon", need = 3, spins = 1, items = { material("ore", 5) } },
		{ id = "dungeon10", kind = "dungeon", need = 10, spins = 2, items = { material("rare_part", 5) } },
		{ id = "dungeon25", kind = "dungeon", need = 25, spins = 4, items = { material("monster_core", 2) } },
		{ id = "wave10", kind = "wave", need = 10, items = { material("ore", 3) } },
		{ id = "wave50", kind = "wave", need = 50, spins = 2 },
		{ id = "wave200", kind = "wave", need = 200, spins = 5, items = { material("monster_core", 1) } },
		{ id = "arena10", kind = "arena", need = 10, spins = 1 },
		{ id = "arena50", kind = "arena", need = 50, coins = 3, spins = 3 },
		{ id = "arena200", kind = "arena", need = 200, spins = 6, items = { material("monster_core", 2) } },
		{ id = "craft1", kind = "craft", need = 1, coins = 1, spins = 1 },
		{ id = "craft5", kind = "craft", need = 5, spins = 2, items = { material("rare_part", 3) } },
		{ id = "craft20", kind = "craft", need = 20, spins = 5, items = { material("boss_essence", 1) } },
	} :: { Goal },
}

-- ===== The Lucky Wheel (docs/MONETIZATION.md §3; rules in shared/Wheel, the screen in client) =====
-- Spins: FreePerDay a UTC day, lost if not used (VipFreePerDay more for a VIP), and a bank of spins that never expires (check-in
-- days, quests, the 60-minute online gift, the wheel itself and Robux fill it; BankCap is only a sanity ceiling for a damaged
-- save). The server rolls the slice by Weight (the odds are shown on the wheel's screen as Weight / the sum); `reward` is a
-- Config.Rewards reward (coins as a share of Rewards.coinBase). Never reorder the slices without the screen: the client draws
-- them in this order and turns the wheel to the index the server answers.
Config.Wheel = {
	FreePerDay = 1,
	VipFreePerDay = 1,
	BankCap = 9999,
	Slices = {
		{ id = "coinsSmall", name = "Coins", weight = 26, reward = { coins = 0.5 } },
		{ id = "coinsBig", name = "Big Coins", weight = 14, reward = { coins = 1.5 } },
		{ id = "food", name = "Food Basket", weight = 14, reward = { items = FoodBasket } },
		{ id = "luck", name = "Luck Potion", weight = 12, reward = { luck = 20 } },
		{ id = "ore", name = "Iron Ore", weight = 10, reward = { items = { material("ore", 5) } } },
		{ id = "fragment", name = "Core Fragments", weight = 9, reward = { items = { material("rare_part", 3) } } },
		{ id = "spin", name = "Free Spin", weight = 7, reward = { spins = 1 } },
		{ id = "core", name = "Monster Core", weight = 5, reward = { items = { material("monster_core", 1) } } },
		{
			id = "jackpot",
			name = "JACKPOT",
			weight = 3,
			reward = { coins = 5, luck = 60, items = { material("boss_essence", 1) } },
		},
	} :: { WheelSlice },
}

-- ===== The Index pays for finding (shared/Hatching, server/Rewards, client toast) =====
-- The first time a kind of slime is hatched on a farm it pays coins once, by how hard it is to find: a plain colour, a Dual,
-- a Material, a Secret. A camp-1 fight pays about 800 and a plain slime sells for 100 (Economy.SellBase), so a plain find is
-- a small thank-you and a Secret is a prize. Paid straight into the purse like a sale: the vault's ceiling does not hold it.
-- Kinds found before this paid nothing (they were never asked to).
Config.Index = {
	DiscoverCoins = { plain = 100, dual = 400, material = 800, secret = 2000 },
}

-- ===== The screen kit (src/client/Ui*.luau): the owner's art, palette, fonts and sizes =====
-- Every image is the owner's own art from reference/goo-lineage-web/assets, trimmed to its bounds only and uploaded
-- (art-pipeline). An id of 0 is a picture that does not exist yet: the client logs it once and shows a stand-in.
Config.Ui = if script then require(script.Parent.ConfigUi) else require("./ConfigUi")

-- Asynchronous Arena: a broad beginner ladder, with a small summit for established teams.
Config.Arena = if script then require(script.Parent.ConfigArena) else require("./ConfigArena")

return Config
