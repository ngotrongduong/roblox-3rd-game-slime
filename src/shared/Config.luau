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
	-- Incubation: max(Min, Base - min(MaxLevel, upgradeLevel) * Step) → 60 s, 35 s at level 5.
	IncubationSeconds = 60,
	-- An egg left in its nest hatches too, this many times slower than in an incubator (the owner, 2026-10-29).
	NestSlowFactor = 2,
	IncubationStepSeconds = 5,
	IncubationMinSeconds = 5,
	IncubationMaxLevel = 5,
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
	CourtshipSeconds = 60,
	LayEnergy = 30,
	IncubationPerBabyLevel = 1,
	IncubationLevelBase = 4,
	IncubationAreaFactor = 0.98,
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
	},
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
Config.Zombies = {
	Teams = 4,
	TeamSize = 4,
	-- A village never dies out: its last slimes come back by themselves when their time runs out.
	MinSlimes = 2,
	-- Food to revive: ceil(1 + level / this) items (the original's 20 food x ceil(1 + level / 5); an item is about 20).
	ReviveLevelsPerFood = 5,
	LevelOffsets = { 0, 3, 5 },
	-- A beaten group comes back RespawnSeconds later at the level of that moment.
	RespawnSeconds = 30,
	-- Where (docs/MAP.md, 1.4): every plot owns the slice of the valley in front of its gate. From the gate straight
	-- towards the centre, the first camp is CampFirstDistance out, each next one CampSpacing further; a camp's groups
	-- lie about there, either side of its trail. 9 places on the rim make a slice 40 degrees wide.
	CampFirstDistance = 90,
	CampSpacing = 70,
	-- Where the groups of a camp live (the owner, 2026-11-02: 4 in the easy ring, 3 in the next, 2 in the hardest), loose
	-- as in nature: degrees off the slice's middle, studs further out or in. Odd slices are mirrored and every home shifts a
	-- little by slice (HomeJitterDegrees), so no two slices read alike.
	Homes = {
		{ { -14, 10 }, { -4, -12 }, { 5, 14 }, { 14, -8 } },
		{ { -12, -8 }, { 2, 10 }, { 12, -6 } },
		{ { -10, 6 }, { 9, -8 } },
	},
	HomeJitterDegrees = 2.5,
	-- A group nobody attacked for this long takes its slice's level again (the owner, 2026-11-02).
	IdleResetSeconds = 5 * 60,
	-- The camps of the whole server (src/server/ZombieFights.luau) look at their groups this often (respawn, idle reset),
	-- and each player's level (the one the slices are filled by, published as PlayerLevel) is worked out this often.
	CampTickSeconds = 1,
	PlayerLevelSeconds = 2,
	-- How often the teams and the slimes' health shares are published to the clients.
	PublishSeconds = 0.25,
	-- The ground under a group is found by a ray from GroundProbeUp above the map's ground height down GroundProbeDown more.
	GroundProbeUp = 80,
	GroundProbeDown = 200,
	-- A fight runs in steps of this many seconds (at most MaxStepsPerFrame in one frame), and is called a draw after
	-- FightMaxSeconds.
	FightStepSeconds = 0.1,
	MaxStepsPerFrame = 5,
	FightMaxSeconds = 300,
	-- The player must stand this close to a group to order an attack on it, to the team banner inside the village gate to
	-- set a team's line-up (the owner, 2026-11-03: both worked from very far), and to the Market to sell a slime.
	SendRangeStuds = 16,
	GateRangeStuds = 10,
	-- The team banner (the waving flag, Config.Flag): MusterAcross studs to the side of the gate's middle and MusterIn
	-- studs into the village, MusterHeight tall (Layout.plotMuster), its cloth flying away from the path.
	MusterAcross = 8,
	MusterIn = 10,
	MusterHeight = 10,
	-- Team n can be set and sent from village level TeamOpensAt[n] (the owner, 2026-11-03: more teams as the village
	-- grows, 4 at most).
	TeamOpensAt = { 1, 10, 20, 30 },
	-- The longest group id a saved team may name as its target (ids look like "c3g4").
	TargetIdMaxLength = 16,
	ShopRangeStuds = 40,
	-- A team marches from the gate to a spot MarchStandOffStuds short of its group (towards the village), in MarchGait,
	-- and back the same way; the slowest member sets the pace.
	MarchStandOffStuds = 11,
	MarchGait = "walk",
	-- A team that won stays on the field this long to cheer before it marches home.
	CheerSeconds = 2.2,
	-- A wound heals this share of a slime's health a minute while it is home (0.5: a full heal in two minutes).
	HealPerMinute = 0.5,
	-- Every slime that fought loses this much energy and fullness when the fight ends (the brain rests and feeds it).
	-- On repeat a team fights about 25 times an hour. Measured (tools/balance/kitchen_sim.luau, real VillageSim, 0.55
	-- productive): at 5 the fighters ate more than the pond and garden make and slimes went hungry at levels 1-30; at 3 level
	-- 20 still did; at 2 nobody is hungry at any level.
	FightEnergy = 8,
	FightFullness = 2,
	-- HpShare on a slime's model is rounded to this step, so a healing wound does not rewrite it every frame.
	HpShareStep = 0.01,
	-- A zombie's stats against an even slime of the player's level, per camp. Five levels mean far more at level 4 than
	-- at level 60, so a camp's risk comes from this and stays the same all game; its level sets the reward.
	StatFactors = { 0.75, 0.9, 1.03 },
	-- base = coins at level 0, as Config.Economy.SellBase for slimes; weights = its chance in each camp: rarer zombies
	-- gather where it is more dangerous, which is what makes the harder camps worth the risk.
	Kinds = {
		rotten = { name = "Rotten Slime", base = 100, weights = { 90, 70, 50 } },
		toxic = { name = "Toxic Slime", base = 500, weights = { 9, 25, 35 } },
		plague = { name = "Plague Slime", base = 2500, weights = { 1, 5, 15 } },
	},
	KindOrder = { "rotten", "toxic", "plague" },
	-- ===== The client (src/client/ZombieWorld, ZombieFight, ZombieLook, UiSquad) =====
	-- Zombies are drawn only within DrawDistance of the camera (and at most View.MaxDrawnZombies at once).
	DrawDistance = 250,
	-- One look a kind, on the shared slime body: colour, outline colour, Roblox material, face (an Expressions id) and
	-- body size (a rarer kind is bigger, so it is seen from afar). A stand-in until the owner's own zombie art exists.
	Looks = {
		-- (faces with no emote: a bubble over each of 48 zombies is noise)
		rotten = { outline = "#3f4a28", burst = "#9bb053", face = "dare", size = 1 },
		toxic = { outline = "#2c6600", burst = "#a4ff0a", face = "dare", size = 1.18 },
		plague = { outline = "#8a0f1f", burst = "#8f0024", face = "dare", size = 1.4 },
	},
	View = {
		-- How often the world checks which groups are near enough to draw, and how much farther one may go before it goes.
		CheckSeconds = 0.5,
		HideMargin = 1.15,
		MaxDrawnZombies = 32,
		-- Zombies first stand on a ring this wide round their group's position, and look at the village; then they roam.
		SpreadStuds = 4.5,
		GroundProbeUp = 8,
		GroundProbeDown = 40,
		-- The level marker: lift above the group's anchor, size in screen pixels, how far it shows. Its colour follows how
		-- much stronger the group is than the player: up to Easy levels above is green, from Hard levels above red.
		MarkerLift = 4,
		MarkerWidth = 110,
		MarkerHeight = 38,
		MarkerDistance = 160,
		AnchorLift = 2.5,
		Danger = { Easy = 1, Hard = 4 },
		DangerColours = { Easy = "#60e270", Fair = "#ffd23c", Hard = "#f45448" },
		-- The fight: where the squad stands (towards the village from its group), how it lunges, flinches and leaves.
		FighterFace = "dare",
		LungeFraction = 0.5,
		LungeSeconds = 0.28,
		LungeHop = 0.3,
		FlinchSide = 2,
		FlinchSquash = -1.5,
		DodgeStuds = 2.2,
		DodgeSeconds = 0.3,
		PopSquash = -3,
		PopHop = 0.35,
		DeathSquash = -3,
		DeathDelay = 0.14,
		FadeSeconds = 0.6,
		FadeWhiten = 0.5,
		-- Thin health bars over the fighters (pixels), and the floating numbers (pixels, seconds, studs).
		BarWidth = 64,
		BarHeight = 9,
		BarLift = 0.9,
		BarDistance = 120,
		NumberSeconds = 0.8,
		NumberRise = 4,
		HitTextSize = 24,
		CritTextSize = 36,
		RewardTextSize = 32,
		MaxNumbers = 20,
		NumberColours = { Foe = "#fffdf4", Ours = "#ff6a5a", Crit = "#ffb02e", Coins = "#ffd23c" },
		-- Coins thrown out of a zombie that falls (the owner's coin picture): at most MaxBursts showers alive at once.
		MaxBursts = 6,
		CoinBurst = 6,
		BurstSeconds = 1.6,
		-- The fight keeps its bodies and bars in step with the group's distance this often.
		SyncSeconds = 0.25,
		-- A blow (src/client/ZombieFight + FightFx): the wind-up when it is announced (squash, the toxic puffs up), the lunge
		-- that reaches the target's skin after ContactShare of LungeSeconds and holds there HitStopSeconds (the bodies
		-- freeze for a beat: the weight of the hit, no camera), the knock-back of the one hit.
		WindupSquash = -1.6,
		WindupPuff = 1.2,
		ContactShare = 0.35,
		HitStopSeconds = 0.08,
		KnockStuds = 1.4,
		KnockSeconds = 0.32,
		CritKnock = 1.7,
		-- A skill (Config.Combat.Skills): its name called out once over the one who strikes it (TextSize, Colour), a deeper
		-- wind-up (Windup times the usual). Goo Slam and Belly Bounce leap (Leap studs) and their blows land when they come
		-- down (CastSeconds), as do those of a skill that strikes everyone; Dash Strike's blows come MultiGap apart; acid
		-- falls from RainHeight. Looks: where the skill's art plays (on its target or the one who strikes it), its burst
		-- (Burst studs) with bits, its rings on the ground (Ring studs across, the second smaller), the drop that rains
		-- on each foe and the ring it leaves there.
		Skill = {
			TextSize = 30,
			Colour = "#ffe066",
			Windup = 1.8,
			Leap = 1.1,
			CastSeconds = 0.38,
			MultiGap = 0.09,
			RainHeight = 10,
			Burst = 5,
			Ring = 11,
			Looks = {
				attack = {
					leap = true,
					onTarget = true,
					burst = "burstShock",
					bits = "moteShock",
					ring = "groundCrack",
					ring2 = "ringShock",
				},
				hp = { leap = true, burst = "shockwave", bits = "moteShock", ring = "ring" },
				defence = { burst = "holyHit", bits = "sparkStar", ring = "ring" },
				toxic = { burst = "burstAcid", bits = "acidDrop", rain = "acidDrop", rainRing = "ringAcid" },
				plague = { burst = "burstArcane", bits = "spore", ring = "ringArcane" },
			},
		},
		-- A winning team cheers (Config.Zombies.CheerSeconds): this many hops each, CheerGap apart, the next slime a bit
		-- later than the last.
		CheerHops = 3,
		CheerGap = 0.55,
		CheerStagger = 0.15,
		CheerHop = 0.55,
		-- A slime that falls twists (a kick into its turn spring) under rising stars (studs).
		FallTurn = 3,
		StarSize = 0.9,
		-- Health just lost stays white this long on a bar, then drains.
		BarLagSeconds = 0.25,
		BarDrainSeconds = 0.35,
		-- Fighters move about the field on their own (src/client/ZombieFight): after each blow each takes its place against
		-- its target, on its own side at its own angle (Spread, degrees either side), Stand body widths beyond touching
		-- (Gap studs between skins). A fast slime circles to a new flank each time; a guard steps in front of its most
		-- hurt team-mate; a toxic zombie keeps its distance and backs off when one comes closer than TooClose; one that
		-- cannot reach (Reach studs of gap) dashes in. Moves run at Speed studs/s within Min/MaxSeconds; a move as short as
		-- DashSeconds leaves after-images. A winning team gets back in line RegroupSeconds before it marches home.
		Moves = {
			Gap = 0.6,
			Speed = 24,
			MinSeconds = 0.18,
			MaxSeconds = 0.45,
			MinStuds = 0.6,
			DashSeconds = 0.26,
			Hop = 0.35,
			Reach = 5,
			TooClose = 3,
			RegroupSeconds = 0.45,
			-- rounds of stepping off other fighters when a place is chosen
			Passes = 4,
			Stand = { attack = 0.6, defence = 0.5, speed = 1.6, hp = 0.8, rotten = 0.7, toxic = 2.6, plague = 0.6 },
			Spread = { attack = 35, defence = 20, speed = 85, hp = 30, rotten = 55, toxic = 40, plague = 30 },
		},
		Fx = {
			-- The owner's own battle art from the original game (reference/goo-lineage-web/assets/battlefx-*.png), uploaded
			-- 2026-11-03, never recoloured.
			Textures = {
				burstShock = 133346055977942,
				moteShock = 138447116339479,
				slashArc = 95547681540742,
				sparkStar = 106004463491821,
				holyHit = 123273947779821,
				shockwave = 94188471939456,
				ring = 91239577409299,
				ringShock = 113076278171097,
				groundCrack = 77360860823212,
				biteMarks = 114773166164920,
				clawMarks = 103284846741774,
				gooBlob = 82520552927313,
				acidSplat = 108936202345260,
				acidDrop = 135178961338375,
				ringAcid = 117408949400540,
				burstAcid = 76291902623074,
				spore = 76735351216148,
				burstArcane = 75506448951291,
				ringArcane = 70489654789239,
				moteArcane = 118302010408844,
				healCross = 110992077814805,
			},
			-- How a blow looks, by the attacker: a slime by its role (Config.Combat.Roles), a zombie by its kind. Every one
			-- its own art (the owner: never one effect recoloured). mark = the picture at the point of the hit (studs);
			-- bits = what flies off it; slash = the mark lies across the line of the blow; shot = spat from afar instead of
			-- a lunge; death / ring = a zombie's burst and the ring on the ground where it falls.
			Styles = {
				attack = { mark = "burstShock", bits = "moteShock", size = 3.4 },
				defence = { mark = "holyHit", bits = "sparkStar", size = 3 },
				speed = { mark = "slashArc", bits = "sparkStar", size = 3.6, slash = true },
				hp = { mark = "shockwave", bits = "moteShock", size = 3.8 },
				rotten = { mark = "biteMarks", size = 3, death = "burstShock", ring = "ringShock" },
				toxic = {
					mark = "acidSplat",
					bits = "acidDrop",
					shot = "gooBlob",
					size = 3,
					death = "burstAcid",
					ring = "ringAcid",
				},
				plague = { mark = "clawMarks", bits = "spore", size = 3.8, death = "burstArcane", ring = "ringArcane" },
			},
			MarkSeconds = 0.34,
			MarkSwell = 1.35,
			CritScale = 1.35,
			CritSparks = 7,
			Bits = 5,
			-- A spit flies this long, this big (studs).
			ShotSeconds = 0.24,
			ShotSize = 1.8,
			ShotArc = 2.5,
			-- Goo knocked out of the one hit: glossy drops of its own body (count, studs, studs/s, seconds); more when it falls.
			Goo = { count = 5, size = 0.38, speedMin = 9, speedMax = 16, up = 11, gravity = 55, life = 0.6 },
			DeathGoo = 12,
			-- A fall: the burst over the body, the ring on the ground (studs, seconds).
			DeathBurst = 6,
			DeathRing = 9,
			RingSeconds = 0.65,
			-- A dodge leaves this many fading copies of the body along the side-step.
			AfterImages = 3,
			AfterImageSeconds = 0.32,
			AfterImageTransparency = 0.55,
			-- Stars over a slime that falls, and over a cheering one.
			Stars = 5,
			-- At most this many marks, goo drops and after-image copies alive at once (cheap phones).
			MaxMarks = 14,
			MaxGoo = 48,
			MaxImages = 12,
		},
		Coin = { size = 1.1, life = 1.1, speedMin = 14, speedMax = 22, gravity = 32 },
		-- The dead chip: when its time turns red (seconds left); the shop confirm window.
		ReviveWarnSeconds = 60,
		ConfirmSeconds = 3,
		SheetRefreshSeconds = 0.5,
		-- ===== Zombies that live: they roam round their group, never farther than RoamStuds from its position =====
		RoamStuds = 12,
		Roam = {
			-- How often the roaming looks at the drawn zombies, how many may walk at once, and how many may start something
			-- new in one look (so they never all act together).
			TickSeconds = 0.25,
			MaxMovers = 10,
			MaxPerTick = 3,
			-- A zombie that has nothing to do waits this long (seconds, random between), then picks something by chance:
			-- walk to a new spot, show a feeling, talk to a neighbour; otherwise it hops on the spot.
			PauseMin = 1.5,
			PauseMax = 6,
			MoveChance = 0.55,
			EmoteChance = 0.15,
			ChatChance = 0.12,
			HopHeight = 0.3,
			-- The way it goes: gait name and weight. A speed factor of 1 is the starter slime's (Gaits.factor).
			Gaits = { { name = "stroll", weight = 5 }, { name = "walk", weight = 3 }, { name = "bouncy", weight = 2 } },
			SpeedFactor = 1,
			MinGoalStuds = 3,
			-- A feeling shows this long, then the face goes back to the kind's own. The feelings are Expressions ids with a
			-- short pop-up icon; a chat is the first, a beat later the neighbour's answer.
			EmoteSeconds = 2.2,
			Emotions = { "happy", "curious", "wink", "surprise", "angry", "laughing", "bored", "sulking" },
			ChatAsk = { "curious", "happy", "wink" },
			ChatAnswer = { "happy", "laughing", "surprise", "angry" },
			ChatReplySeconds = 0.9,
			ChatRangeStuds = 9,
		},
		-- ===== The teams (UiTeams, ZombieMarch) =====
		-- The gate sheet and the attack sheet: heights, the slot and the small portrait sizes, the card height.
		TeamsSheetHeight = 500,
		AttackSheetHeight = 360,
		SlotSize = 52,
		CardPortrait = 24,
		CardHeight = 60,
		-- The notice when a team is home (right edge, above the book button): size, seconds, how many show at once.
		NoticeWidth = 150,
		NoticeHeight = 58,
		NoticeSeconds = 4.5,
		NoticeMax = 3,
		-- The team chips at the left edge: lift of the column above the middle and the thin progress bar.
		ChipLift = 34,
		ChipBarHeight = 4,
		-- A team's state as one of the owner's pictures, and why a repeating team waits (picture and a short word).
		StateIcons = { home = "slimes", going = "speed", fighting = "attack", returning = "back" },
		WaitingIcons = { health = "hp", hungry = "food", tired = "energy", group = "skull" },
		WaitingText = { health = "Healing", hungry = "Hungry", tired = "Tired", group = "Group busy" },
		-- ===== The march: real slime bodies hop along the published leg, spread side by side =====
		-- Bodies are built within DrawDistance of the camera and checked this often. A long leg is cut into pieces of
		-- SegmentHops hops, each measured against the ground again (the slime's own ground ray only looks a little way).
		MarchCheckSeconds = 0.25,
		-- Other players' teams are drawn too, nearest first, up to this many bodies at once besides the player's own.
		MaxOtherBodies = 12,
		SegmentHops = 3,
		FormationSpacing = 4.2,
		FormationStagger = 1.4,
	},
}

-- The Slime Dungeon (the owner, 2026-11-04): a private arena where the team fights monsters that come in waves; each wave
-- a set number of them, stronger from wave to wave and from dungeon level to dungeon level. The numbers are the original's
-- (docs/reference/02-battle.md §5 waves, §6 level ladder, §7 roster, §13 loot); the rules are shared/Dungeon.
Config.Dungeon = {
	-- The maps in the order they open; only the first so far. `material` is the map's own drop (a boss gives
	-- BossMapMaterial of it, a mini-boss or an elite MapMaterialChance of one). A monster: its budget `cost` (none for a
	-- mini-boss or boss, which come alone), its level-1 stats (the same kind of numbers a slime has), its `role`, and
	-- `kind`: the way it fights in Config.Combat (melee strikes anyone; ranged keeps its distance; hunter goes for the
	-- slime with the least health and stings it slow; healer mends its wounded team-mates; bloomshell and bramblehorn are
	-- the two bosses with a skill of their own).
	Maps = {
		meadow = {
			name = "Sunny Meadow",
			material = "boar_tusk",
			monsters = {
				{
					id = "green_sprout",
					name = "Sproutling",
					role = "swarmer",
					cost = 1,
					attack = 1,
					defence = 0,
					speed = 3,
					hp = 13,
					kind = "melee",
				},
				{
					id = "green_bee",
					name = "Honey Bee",
					role = "raider",
					cost = 2,
					attack = 3,
					defence = 0,
					speed = 5,
					hp = 18,
					kind = "hunter",
				},
				{
					id = "green_dandelion",
					name = "Puffdandy",
					role = "spitter",
					cost = 2,
					attack = 3,
					defence = 0,
					speed = 2,
					hp = 16,
					kind = "ranged",
				},
				{
					id = "green_moth",
					name = "Glowmoth",
					role = "shaman",
					cost = 2,
					attack = 1,
					defence = 0,
					speed = 2.5,
					hp = 20,
					kind = "healer",
				},
				{
					id = "green_snail",
					name = "Clover Snail",
					role = "armoured",
					cost = 3,
					attack = 3,
					defence = 8,
					speed = 0.7,
					hp = 38,
					kind = "melee",
				},
				{
					id = "green_turtle",
					name = "Bloomshell",
					role = "miniboss",
					attack = 5,
					defence = 7,
					speed = 1.5,
					hp = 140,
					kind = "bloomshell",
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
				},
			} :: { any },
		},
	},
	MapOrder = { "meadow" },

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

	-- ===== Loot (§13) =====
	-- One regular drop a monster: a roll r in [0, 1) lands in the first window whose `upTo` is above it. The first window of
	-- a row is scaled by the level's luck: `luck = "times"` (a rarer prize that luck makes likelier) or `"over"` (a window
	-- of nothing that luck makes smaller); a window without an `item` is nothing. The amount is min..max.
	-- LootClass: a monster's row by its role (any role left out is "normal").
	LootClass = { boss = "boss", miniboss = "miniboss", armoured = "elite" },
	Loot = {
		boss = {
			{ upTo = 0.05, item = "boss_essence", min = 1, max = 1, luck = "times" },
			{ upTo = 0.50, item = "coins", min = 12, max = 20 },
			{ upTo = 0.78, item = "ore", min = 2, max = 3 },
			{ upTo = 1, item = "rare_part", min = 1, max = 2 },
		} :: { any },
		miniboss = {
			{ upTo = 0.10, item = "monster_core", min = 1, max = 1, luck = "times" },
			{ upTo = 0.55, item = "coins", min = 6, max = 11 },
			{ upTo = 0.85, item = "ore", min = 1, max = 2 },
			{ upTo = 1, item = "rare_part", min = 1, max = 1 },
		} :: { any },
		elite = {
			{ upTo = 0.25, luck = "over" },
			{ upTo = 0.45, item = "rare_part", min = 1, max = 1 },
			{ upTo = 0.70, item = "ore", min = 1, max = 2 },
			{ upTo = 0.85, item = "wood", min = 1, max = 2 },
			{ upTo = 1, item = "food", min = 3, max = 5 },
		} :: { any },
		normal = {
			{ upTo = 0.40, luck = "over" },
			{ upTo = 0.55, item = "coins", min = 2, max = 5 },
			{ upTo = 0.75, item = "food", min = 3, max = 5 },
			{ upTo = 0.84, item = "common_part", min = 1, max = 1 },
			{ upTo = 0.91, item = "cloth", min = 1, max = 1 },
			{ upTo = 0.96, item = "wood", min = 1, max = 1 },
			{ upTo = 1, item = "ore", min = 1, max = 1 },
		} :: { any },
	},
	-- The map's own drop, a separate roll: these roles have MapMaterialChance of one; a boss always gives BossMapMaterial.
	MapMaterialRoles = { miniboss = true, armoured = true },
	MapMaterialChance = 0.18,
	BossMapMaterial = 2,
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
		cloth = { name = "Linen Cloth", short = "Cloth", kind = "material", icon = 128498997412713 },
		ore = { name = "Iron Ore", short = "Ore", kind = "material", icon = 107577459785586 },
		common_part = { name = "Slime Residue", short = "Residue", kind = "material", icon = 109902889353186 },
		rare_part = { name = "Gooey Core Fragment", short = "Fragment", kind = "material", icon = 104963871301466 },
		monster_core = { name = "Monster Core", short = "Core", kind = "material", icon = 118559273498942 },
		boss_essence = { name = "Boss Essence", short = "Essence", kind = "material", icon = 135452085949250 },
		boar_tusk = { name = "Boar Tusk", short = "Tusk", kind = "material", icon = 97935793546139 },
	},
	DropOrder = {
		"coins",
		"food",
		"wood",
		"cloth",
		"ore",
		"common_part",
		"rare_part",
		"monster_core",
		"boss_essence",
		"boar_tusk",
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
	Arena = {
		Seed = 20261104,
		-- The grass floor (a stud-look block, the village's look) reaches FloorHalf each way, past the backdrop, so the world
		-- never shows its edge; FloorColour is the village lawn's, a little brighter like the painting.
		FloorHalf = 150,
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
		-- The rim band that holds the scenery (outside the wall), and the far ring of trees that hides the floor's edge.
		RimInner = 71,
		RimOuter = 100,
		BackdropInner = 104,
		BackdropOuter = 132,
		BackdropCount = 30,
		BackdropBushes = 44,
		BushRowDepth = 6,
		-- Four dirt paths on the axes, from PathOuter in to PathInner: PathSegments overlapping flat blocks that narrow from
		-- PathWidthOuter to PathWidthInner and drift sideways by up to PathWobble; the colour fades PathFade of the way to the
		-- grass at the inner end. Each lies PathLift over the floor (so the two never flicker) and is PathThick thick.
		PathColour = "#b9894f",
		PathOuter = 118,
		PathInner = 28,
		PathSegments = 7,
		PathWidthOuter = 15,
		PathWidthInner = 6,
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
		PerCorner = { Trees = 3, RockPairs = 1, Rocks = 1, Bushes = 3, Clumps = 4 },
		-- The two trees past each path's outer end: how far past it, and how far apart from the path's line.
		MouthBehind = 6,
		MouthTreeApart = 7,
		Tries = 80,
		-- Heights (trees) or widths (the rest), studs: { low, high }. Backdrop trees are taller than the rim's.
		Round = { 22, 26 },
		Pine = { 22, 28 },
		BackdropRound = { 26, 32 },
		BackdropPine = { 28, 36 },
		RockBig = { 7, 9 },
		RockSmall = { 3.8, 5 },
		RockSingle = { 4.5, 8 },
		Bush = { 4.8, 6.4 },
		BackdropBush = { 10, 14 },
		Flower = { 3.6, 5 },
		Tuft = { 2.8, 4 },
		TinyFlower = { 1.3, 1.9 },
		TinyTuft = { 1.5, 2.1 },
		TinyPebble = { 1, 1.6 },
		-- Kit models (ServerStorage.Kit.WildKit) by kind, and the tints a kind may wear (a tint only multiplies, so these are
		-- the village's: it keeps the arena in the same world).
		Models = {
			round = { "QtCommonTree_1", "QtCommonTree_3", "QtCommonTree_5" },
			pine = { "QtPine_1", "QtPine_5" },
			rock = { "QtRock_Medium_1", "QtRock_Medium_2", "QtRock_Medium_3" },
			bush = { "QtBush_Common_Green", "QtBush_Common_Flowers" },
			flower = { "QtFlower_3_Group", "QtFlower_4_Group" },
			tuft = { "QtGrass_Common_Short", "QtGrass_Common_Tall" },
			pebble = { "QtPebble_Round_1", "QtPebble_Square_2" },
		},
		Tints = {
			round = { "#ffffff", "#f0ffc8", "#e1fabe" },
			pine = { "#ffffff", "#d2ebe1" },
			tuft = { "#f0ffc8", "#e1fabe" },
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
		},
		Sizes = { normal = 3, armoured = 4, miniboss = 7, boss = 10 },
	},
	-- Each monster's model (the owner's painting built in Blender as rigid pieces, art/models/monsters/MOTION.md, imported
	-- into ClientKit.Monsters) and how its pieces move (shared/MonsterMotion; client/MonsterLook, SlimeActor.dress).
	-- `height` the model's height in studs, `min` its lowest, rightmost (-X), frontmost corner from its ground spot (the
	-- Body's origin), `hover` how high a flyer floats with a `bob` at `bobHz`, `tilt` its pitch in degrees (negative: nose
	-- down) about the middle of its height. A piece: its `joint` from the ground spot
	-- (studs, Roblox axes: front -Z) and its swing (MonsterMotion); `transparency` for glassy wings. A left/right pair runs
	-- apart (phase 0.5) or mirrored (sign -1); legs go in diagonal pairs.
	Looks = {
		green_sprout = {
			model = "Sproutling",
			height = 4.37,
			min = { -2.13, -0.16, -1.40 },
			pieces = {
				Sprout = { joint = { -0.08, 2.79, 0 }, axis = "z", amp = 12, hz = 0.8 },
				EarL = { joint = { -1.18, 1.99, -0.17 }, axis = "z", amp = 10, hz = 1.5, hit = 20 },
				EarR = { joint = { 0.73, 1.80, -0.26 }, axis = "z", amp = 10, hz = 1.5, sign = -1, hit = 20 },
				FootL = { joint = { -1.04, 0.71, -0.52 }, axis = "x", amp = 25, hz = 2, walk = true },
				FootR = { joint = { 0.89, 0.69, -0.86 }, axis = "x", amp = 25, hz = 2, phase = 0.5, walk = true },
			},
		},
		green_bee = {
			model = "HoneyBee",
			height = 4.12,
			min = { -2.24, 0, -1.21 },
			-- the painting's bee dives: head down, the abdomen and its honey bud up behind
			tilt = -25,
			hover = 3.5,
			bob = 0.15,
			bobHz = 3,
			pieces = {
				Abdomen = { joint = { 0, 2.02, 0.53 }, axis = "x", amp = 8, hz = 1.2, hit = -20 },
				Bud = { joint = { 0, 3.11, 2.25 }, axis = "x", amp = 10, hz = 2, phase = 0.25 },
				WingL = { joint = { -0.57, 2.29, 0.02 }, axis = "z", amp = 35, hz = 16, transparency = 0.35 },
				WingR = { joint = { 0.57, 2.29, 0.02 }, axis = "z", amp = 35, hz = 16, sign = -1, transparency = 0.35 },
				AntennaL = { joint = { -0.27, 1.75, -0.91 }, axis = "x", amp = 12, hz = 1.6 },
				AntennaR = { joint = { 0.27, 1.75, -0.91 }, axis = "x", amp = 12, hz = 1.6, phase = 0.5 },
				LegsL = { joint = { -0.40, 1.30, 0.53 }, axis = "x", amp = 14, hz = 2 },
				LegsR = { joint = { 0.40, 1.30, 0.53 }, axis = "x", amp = 14, hz = 2, phase = 0.5 },
			},
		},
		green_dandelion = {
			model = "Puffdandy",
			height = 4.41,
			min = { -1.78, 0.12, -1.33 },
			hover = 2,
			bob = 0.25,
			bobHz = 1.2,
			pieces = {
				Puff = { joint = { 0.04, 1.86, 0.07 }, axis = "z", amp = 6, hz = 1 },
				ArmL = { joint = { -0.86, 1.45, -0.04 }, axis = "z", amp = 25, hz = 1.8, hit = 30 },
				ArmR = { joint = { 0.82, 1.32, -0.07 }, axis = "z", amp = 25, hz = 1.8, sign = -1, hit = 30 },
				Tail = { joint = { -0.27, 0.95, 0.04 }, axis = "y", amp = 18, hz = 1.5 },
			},
		},
		green_moth = {
			model = "Glowmoth",
			height = 3.98,
			min = { -2.56, -0.07, -1.32 },
			hover = 3,
			bob = 0.3,
			bobHz = 1.5,
			pieces = {
				WingL = { joint = { -1.07, 1.74, 0.25 }, axis = "z", amp = 30, hz = 3.5 },
				WingR = { joint = { 1.07, 1.74, 0.25 }, axis = "z", amp = 30, hz = 3.5, sign = -1 },
				AntennaL = { joint = { -0.33, 2.35, 0 }, axis = "x", amp = 10, hz = 1.2 },
				AntennaR = { joint = { 0.33, 2.35, 0 }, axis = "x", amp = 10, hz = 1.2, phase = 0.5 },
				FootL = { joint = { -0.39, 0.49, -0.16 }, axis = "x", amp = 10, hz = 1.5 },
				FootR = { joint = { 0.49, 0.64, -0.12 }, axis = "x", amp = 10, hz = 1.5, phase = 0.5 },
			},
		},
		green_snail = {
			model = "CloverSnail",
			height = 4.75,
			min = { -1.50, 0, -2.67 },
			pieces = {
				StalkL = { joint = { -0.55, 1.80, -1.27 }, axis = "z", amp = 14, hz = 1.1 },
				StalkR = { joint = { 0.55, 1.80, -1.27 }, axis = "z", amp = 14, hz = 1.1, phase = 0.5 },
				Shell = { joint = { 0, 0.55, 0.75 }, axis = "z", amp = 5, hz = 1, hit = 8 },
			},
		},
		green_turtle = {
			model = "Bloomshell",
			height = 7.98,
			min = { -4.25, -0.67, -5.87 },
			shadow = true,
			pieces = {
				Bud = { joint = { 0, 4.86, 0.86 }, axis = "z", amp = 6, hz = 0.7 },
				Head = { joint = { 0, 1.33, -2.74 }, axis = "y", amp = 15, hz = 0.3 },
				LegFL = { joint = { -2.81, 1.94, -2.02 }, axis = "x", amp = 20, hz = 1.1, walk = true, hit = 35 },
				LegFR = { joint = { 2.81, 1.94, -2.02 }, axis = "x", amp = 20, hz = 1.1, phase = 0.5, walk = true },
				LegBL = { joint = { -2.88, 1.87, 2.88 }, axis = "x", amp = 20, hz = 1.1, phase = 0.5, walk = true },
				LegBR = { joint = { 2.88, 1.87, 2.88 }, axis = "x", amp = 20, hz = 1.1, walk = true },
			},
		},
		green_boar = {
			model = "Bramblehorn",
			height = 10.96,
			min = { -4.83, 0, -9.82 },
			shadow = true,
			pieces = {
				-- a head-butt dips the head (a turn about X with the front going down)
				Head = { joint = { 0, 3.84, -3.17 }, axis = "x", amp = 4, hz = 0.6, hit = -20 },
				EarL = { joint = { -2.06, 5.28, -4.80 }, axis = "z", amp = 15, hz = 2.5 },
				EarR = { joint = { 2.06, 5.28, -4.80 }, axis = "z", amp = 15, hz = 2.5, sign = -1 },
				LegFL = { joint = { -2.59, 5.18, -1.92 }, axis = "x", amp = 22, hz = 1, walk = true },
				LegFR = { joint = { 2.59, 5.18, -1.92 }, axis = "x", amp = 22, hz = 1, phase = 0.5, walk = true },
				LegBL = { joint = { -2.69, 5.18, 5.38 }, axis = "x", amp = 22, hz = 1, phase = 0.5, walk = true },
				LegBR = { joint = { 2.69, 5.18, 5.38 }, axis = "x", amp = 22, hz = 1, walk = true },
				Tail = { joint = { 0, 6.24, 7.68 }, axis = "y", amp = 25, hz = 1.4 },
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
		},
		-- A monster's burst when it falls grows with its size, up to this many times a plain one's.
		DeathBigness = 2,
		-- A healer's mending: the picture over the one healed (studs across).
		HealBurst = 4,
		HealColour = "Green",
		-- How often the portal prompts are looked at.
		GateWatchSeconds = 1,
	},

	-- ===== The portal (server/DungeonPortal, Layout.plotPortal) =====
	-- Egg Heist's portal (the owner, 2026-11-04: "use the portal we have, near the village gate"), rebuilt from its kit
	-- meshes, which the owner's account published (InsertService ids). It stands Across studs to the side of the gate's
	-- middle and Out studs outside the fence, turned TurnDegrees so its opening faces the path out of the gate, at Scale of
	-- its full size (about 29 x 23 studs when scaled). The prompt that opens the Dungeon works from PromptRangeStuds.
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
		Across = -34,
		Out = 22,
		TurnDegrees = 150,
		Scale = 0.55,
		PromptRangeStuds = 14,
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
	-- New-player luck after the tutorial ends: ×First for one window, ×Second for the next, then ×1.
	WindowSeconds = 30 * 60,
	First = 5,
	Second = 3,
	ServerBonus = 1,
	-- Reserved for a future potion; not sold yet.
	Potion = 2,
	Vip = 1,
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
	-- Smooth capacity progression: interpolate between these checkpoints.
	-- Low levels grow slowly until the second fishing and gardening stations unlock at level 11;
	-- higher levels add 1 or 2 slimes, never a sudden 15-slime jump. Keep all old-save slimes.
	PopulationProgression = {
		{ level = 1, cap = 12 },
		{ level = 7, cap = 13 },
		{ level = 10, cap = 13 },
		{ level = 20, cap = 27 },
		{ level = 30, cap = 42 },
		{ level = 40, cap = 57 },
		{ level = 50, cap = 72 },
	},
	UpgradePrices = {
		{ level = 1, price = 310 },
		{ level = 5, price = 480 },
		{ level = 10, price = 1100 },
		{ level = 15, price = 2200 },
		{ level = 19, price = 3100 },
		{ level = 25, price = 7900 },
		{ level = 30, price = 14000 },
		{ level = 35, price = 24000 },
		{ level = 39, price = 37000 },
		{ level = 45, price = 67000 },
		{ level = 49, price = 99000 },
	},
	CoinCapMin = 2000,
	CoinCapPriceFactor = 3,
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
	SleepEnergyPerMinute = 5,
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
	MessageSeconds = 2.6,
	MessageHeightStuds = 5,
	MessageRiseStuds = 3,
	MessageWidthPixels = 310,
	MessageHeightPixels = 100,
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

-- ===== The Market (docs/MAP.md 1.3; the owner, 2026-11-02: one slime buyer, one VIP counter, one leaderboard) =====
-- Spots are local to Layout.marketFrame() (turn them into world positions with Layout.marketPoint): x across the square,
-- z along the radius. The frame looks at the valley centre, so -z is the front (the open side towards the valley) and +z the
-- back (towards the valley's edge); +x is the left of someone walking in from the valley. The prompts and the landing
-- stand at these spots whether or not the scene artist's models are there yet. The square is Map.MarketWidth x MarketDepth.
Config.Market = {
	-- Where quick travel lands: a clear spot at the front of the square, facing the back.
	Landing = { x = 0, z = -56 },
	-- The slime buyer's counter (left) and the VIP counter (right), a little in front of the middle.
	Buyer = { x = 55, z = -8 },
	Vip = { x = -55, z = -8 },
	-- The leaderboard, at the back in the middle.
	Board = { x = 0, z = 62 },
	-- What the scene artist names things in workspace.Map.Market (the board's picture goes on its part ScreenName).
	Model = "Market",
	BuyerModel = "SlimeBuyer",
	VipModel = "VipStall",
	BoardModel = "Leaderboard",
	ScreenName = "Screen",
	-- How close the VIP counter's prompt shows and its sheet stays open (the buyer's are Zombies.ShopRangeStuds).
	VipRangeStuds = 40,
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

-- Robux goods of the VIP counter. EMPTY on purpose: the owner approves the list and the prices first (skill
-- robux-products), and nothing is sold before he has. Later a product is { key, name, icon, price }: a short id for
-- the code, the name shown, a Config.Ui.Icons name, the price in Robux. No product ids, no purchase code yet.
Config.Robux = {
	Products = {} :: { { key: string, name: string, icon: string, price: number } },
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
	SchemaVersion = 9,
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
Config.Rewards = {
	CoinFloor = 100,
	LuckMaxMinutes = 120,
	-- The daily check-in: day n of a run of days in a row, then day 1 again. A day missed starts the run over.
	Daily = {
		{ coins = 0.5 },
		{ coins = 0.75 },
		{ coins = 1 },
		{ coins = 0.5, luck = 15 },
		{ coins = 1.5 },
		{ coins = 2 },
		{ coins = 3, luck = 30 },
	},
	-- Daily quests: QuestCount a day, drawn from the kinds that fit the farm by a dice of the player and the day; quest n
	-- asks the n-th share of its kind's { least, most } and pays QuestCoins[n]. All of them claimed: QuestBonus once.
	QuestCount = 3,
	QuestKinds = { "breed", "hatch", "sell", "feed", "win", "upgrade" },
	QuestNeed = {
		breed = { 1, 3 },
		hatch = { 1, 3 },
		sell = { 1, 3 },
		feed = { 10, 30 },
		win = { 4, 12 },
		upgrade = { 1, 2 },
	},
	QuestCoins = { 0.4, 0.7, 1 },
	QuestBonus = { luck = 20 },
	-- "sell" is drawn only for a village of at least this many slimes (the last ones cannot be sold).
	QuestSellMinSlimes = 6,
	-- Online gifts: minutes played this UTC day (earlier visits count); each taken once a day.
	Online = {
		{ minutes = 1, coins = 0.2 },
		{ minutes = 3, coins = 0.3 },
		{ minutes = 5, coins = 0.4 },
		{ minutes = 10, coins = 0, luck = 5 },
		{ minutes = 15, coins = 0.6 },
		{ minutes = 20, coins = 0.8 },
		{ minutes = 30, coins = 0.5, luck = 10 },
		{ minutes = 45, coins = 1 },
		{ minutes = 60, coins = 1.5, luck = 15 },
	},
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
	QuestRowHeight = 80,
	IndexCell = 96,
	IndexCellHeight = 118,
	-- How dark an Index card stays while its slime is not found (the 3D body drawn as a shadow).
	SilhouetteColour = "#3a2a1c",
	-- The red dot on the Rewards button while something waits.
	BadgeSize = 18,
}

-- ===== The screen kit (src/client/Ui*.luau): the owner's art, palette, fonts and sizes =====
-- Every image is the owner's own art from reference/goo-lineage-web/assets, trimmed to its bounds only and uploaded
-- (art-pipeline). An id of 0 is a picture that does not exist yet: the client logs it once and shows a stand-in.
Config.Ui = {
	Icons = {
		coins = 127025864156501, -- mat-coins.png
		food = 128780371839699, -- mat-food.png
		fullness = 128780371839699, -- mat-food.png (the sack stands for being fed)
		slimes = 120929268236217, -- slime.base.navy.png (the original's slime-count icon)
		attack = 99675585132127, -- equip-sword.png (the owner's sword; his star read as luck, the owner 2026-11-03)
		defence = 74089620499791, -- equip-shield.png
		speed = 96175650939419, -- stat-speed.png (the owner's bolt)
		hp = 113610467784918, -- stat-hp.png (the owner's heart)
		fishing = 126305761994889, -- prop.workstation.fishing-pond.png
		garden = 85177293898894, -- prop.workstation.farm-plot.png
		kitchen = 138156697526360, -- prop.workstation.cooking-kitchen.png
		pantry = 128780371839699, -- mat-food.png
		training = 70679228626362, -- ui.btn.upgrades.png
		breeding = 92923495054582, -- ui.btn.breeding.png
		-- Made by ChatGPT in the owner's style (art/icons/, tools/chatgpt/prepare_icons.py).
		skull = 83728682658724, -- the dead-slimes chip
		energy = 128325483797011,
		fun = 97285329726071,
		close = 103131383048931,
		cross = 103131383048931,
		back = 110115571347055,
		-- the tutorial's pointer: the same gold arrow (it points left; turned to point where it must)
		pointer = 110115571347055,
		plus = 115669941400247,
		again = 87479558872031, -- the Repeat toggle
		level = 99981918632333, -- the Level sort button
		order = 105007209294287, -- which way a list sorts (points down)
		-- The round travel buttons (home, market): not drawn yet, a short word stands in (UiKit glyphs).
		home = 129188593634951,
		market = 80845462069782,
		-- The rewards sheet's tabs and the luck potion (ChatGPT, 2026-11-04); the trophy and the Index are the owner's own
		-- ui.btn.trophy and ui.btn.collection, trimmed only (art/icons/btn-*.png).
		daily = 128691395639891,
		quests = 128098601387106,
		online = 115129814887456,
		luck = 76165751061122,
		rewards = 92181600961063,
		collection = 91176780566160,
		-- The Slime Dungeon's gate sheet header: a stone portal ring with a blue swirl (ChatGPT, 2026-11-04, art/icons/dg_dungeon.png).
		dungeon = 136488942687177,
		-- (drawn from the 3D items instead: docs/GAMEPLAY.md, the food chip)
		fish = 0,
		carrot = 0,
		cabbage = 0,
		grilledFish = 0,
		veggieStew = 0,
		fishVegSoup = 0,
	},
	-- The round edge buttons are the original's ui.btn.<id> art.
	Buttons = {
		slimes = 74629091770984,
		rewards = 92181600961063,
	},
	-- Nine-slice frames: the owner's ui-frame-gold (panels) and ui-frame-wood (buttons, cards). Slice numbers are
	-- pixels of the trimmed picture; Scale is how big its border draws on screen.
	Frames = {
		Panel = {
			Id = 109389746503451,
			MinX = 255,
			MinY = 260,
			MaxX = 495,
			MaxY = 505,
			Scale = 0.14,
			Inset = 10,
		},
		Wood = {
			Id = 72424466145847,
			MinX = 130,
			MinY = 130,
			MaxX = 630,
			MaxY = 640,
			Scale = 0.075,
			Inset = 6,
		},
	},
	-- The original's palette (docs/reference/03-shell-ui-world.md): parchment, cream, wood brown, orange-gold.
	Colours = {
		Parchment = "#fff4dd",
		Card = "#fffdf4",
		CardDeep = "#f5e7c7",
		Portrait = "#e8f5d8",
		Brown = "#69472a",
		BrownSoft = "#9a7650",
		Wood = "#7a5230",
		Gold = "#c98a3d",
		GoldLight = "#e2a94f",
		Cream = "#fffdf4",
		Green = "#54b848",
		GreenDark = "#3a6b2a",
		Red = "#b04030",
		Blue = "#2f9fd8",
		Fullness = "#e8a23a",
		Energy = "#4f9fd8",
		Fun = "#e8708f",
		Track = "#e7d6b0",
		Backdrop = "#2a1d10",
		HudText = "#ffe9a8",
		HudStroke = "#2e4a24",
	},
	Font = "FredokaOne",
	-- Layout. Touch targets are never below Touch; the screen scales up on big monitors only.
	Touch = 48,
	Pad = 10,
	Gap = 6,
	Edge = 10,
	-- The Home and Market buttons over the book button, in a column on the right edge.
	TravelButton = 48,
	BookButton = 52,
	IconSmall = 20,
	IconNormal = 28,
	-- A 3D item drawn as an icon (UiKit.modelIcon): the camera's field of view, how much room it leaves round the
	-- item (1 = touching the edges) and how far above the item it looks down from.
	ModelIconFov = 30,
	ModelIconPad = 1.05,
	ModelIconLift = 0.8,
	ChipHeight = 32,
	-- The village's level and progress, one more plate in the resource strip (a phone's screen is short).
	VillageBarWidth = 104,
	VillageBarFillSeconds = 0.35,
	TextTiny = 13,
	TextSmall = 15,
	TextNormal = 17,
	TextHeader = 22,
	ScaleBaseHeight = 720,
	ScaleMax = 1.35,
	SheetWidth = 460,
	-- (tall enough for the slime list under its sort row)
	SheetHeight = 440,
	-- The VIP sheet (UiMarket): short while it only says "Opening soon".
	VipSheetHeight = 260,
	BookWidth = 760,
	BookHeight = 560,
	CardWidth = 250,
	CardHeight = 124,
	PortraitSize = 72,
	PortraitDistance = 1.2,
	PortraitFov = 70,
	PortraitFaceZoom = 1.12,
	PortraitEye = 0.65,
	PortraitLook = 0.5,
	TagHeight = 26,
	-- World markers of the work positions: size in studs, lift above the marker, how far they show, prompt reach.
	SpotSize = 1.3,
	SpotLift = 2,
	SpotDistance = 45,
	SpotPromptDistance = 7,
	PendingSeconds = 4,
	RefreshSeconds = 0.1,
	StatCellIcon = 18,
	BarHeight = 10,
	SeatSize = 64,
	SeatReserveSize = 48,
	RowHeight = 76,
	ToastSeconds = 2.6,
	OpenSeconds = 0.18,
	OpenSlide = 28,
	PressScale = 0.94,
	BackdropTransparency = 0.55,
	DisabledTransparency = 0.5,
	-- The food panel (UiFood): row height, the model icon size, how wide the count column is.
	FoodWidth = 420,
	FoodHeight = 480,
	FoodRowHeight = 52,
	FoodIconSize = 44,
	FoodCountWidth = 56,
	-- The recipe picker of a kitchen position (UiRecipes): the bar, a row of the list, the dish picture, an ingredient picture.
	RecipeBarHeight = 56,
	RecipeRowHeight = 72,
	RecipeIcon = 52,
	IngredientIcon = 32,
	-- Over a cook that waits for an ingredient (UiSpots): the size of each missing ingredient's model and the gap between
	-- them (studs), the pixels of the cross on it, and how far above the work position they float (studs).
	MissingStuds = 1.6,
	MissingGap = 0.4,
	MissingCross = 22,
	MissingLift = 4.4,
	-- Slime book.
	BookFilters = { "all", "free", "working", "babies" },
	-- The one slime list (UiSlimeList): its sort buttons in order, the attribute each one sorts by, and the tile: width and
	-- height, the portrait inside it, the wound bar over the portrait's foot, the little arrow that shows the order and
	-- the size of the mark in a tile's corner.
	Sorts = { "level", "attack", "defence", "speed", "hp" },
	SortAttributes = { level = "Level", attack = "Attack", defence = "Defence", speed = "Speed", hp = "Hp" },
	Tile = { Width = 84, Height = 112, Portrait = 56, WoundHeight = 5, WoundLow = 0.35, SortArrow = 16, MarkSize = 22 },
}

return Config
