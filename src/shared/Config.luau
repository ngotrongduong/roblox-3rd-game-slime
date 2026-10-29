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
	-- The tutorial's first egg: a new homozygous colour, this many stats beat the parents, fast hatch.
	TutorialBoostedStats = 2,
	TutorialHatchSeconds = 20,
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
	SellBase = { common = 150, rare = 300, precious = 800 },
	-- The outline hull of a material slime is its drawn colour times this.
	HullShade = 0.6,
}

-- Selling a slime (docs/reference/01-core-farm.md §8.1): floor(base × (1 + level × SellLevelStep)).
-- Base by appearance; a material slime uses Config.Material.SellBase by its tier.
Config.Economy = {
	SellBase = { none = 10, dual = 100, secret = 1000 },
	SellLevelStep = 0.05,
}

Config.Growth = {
	-- Grow-up: round((Base + max(0, level - 1) * PerLevel) * Factor ^ min(MaxLevel, upgradeLevel)) → 303 s at level 4.
	GrowUpSeconds = 300,
	GrowUpPerLevelSeconds = 1,
	UpgradeFactor = 0.95,
	UpgradeMaxLevel = 20,
	-- A hatchling is drawn at BabyScale and eases to 1 while it grows.
	BabyScale = 0.62,
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
	StarterCount = 4,
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
	MaxLevel = 50,
	PopulationBase = 20,
	PopulationPerLevel = 4,
	UpgradeBase = 100,
	UpgradeMaxCost = 20000,
	UpgradeLastFromLevel = 49,
	CostRoundTo = 10,
	OfflineCapSeconds = 8 * 60 * 60,
	StepSeconds = 60,
	GhostSeconds = 24 * 60 * 60,
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
	CarryPromptHoldSeconds = 0,
	CarryReachStuds = 12,
	CarryModelScale = 0.42,
	CarryHeadOffset = 0.7,
	DevPlot = 5,
	DevFreeUpgrades = false,
	TickSeconds = 1,
	RequestsPerSecond = 4,
	SpotNames = {
		Work = { "WorkSpot1", "WorkSpot2", "WorkSpot3", "WorkSpot4" },
		Nest = { "Nest1", "Nest2", "Nest3", "Nest4", "Nest5", "Nest6" },
		Incubator = { "Incubator1", "Incubator2", "Incubator3", "Incubator4", "Incubator5", "Incubator6" },
		Storehouse = { "StorehouseDoor", "PantryDoor", "Entrance" },
		StorehouseModels = { "PantryDoor", "Door" },
		Box = { "FishBin", "VegBin", "CollectionBox", "FishBucket", "HarvestBox", "DishBox" },
		CounterModels = { "KitchenCounter", "Counter", "PrepCounter" },
		FridgeModels = { "Fridge", "Refrigerator" },
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
	IdleFullnessPerMinute = 2,
	WorkFullnessPerMinute = 3,
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

Config.Food = {
	Raw = { fish = 20, carrot = 15, cabbage = 15 },
	RawOrder = { "fish", "carrot", "cabbage" },
	Dishes = {
		grilledFish = { ingredients = { fish = 2 }, fullness = 60, stat = "attack", percent = 10 },
		veggieStew = { ingredients = { carrot = 2, cabbage = 1 }, fullness = 65, stat = "defence", percent = 10 },
		fishVegSoup = { ingredients = { fish = 1, carrot = 1, cabbage = 1 }, fullness = 90, stat = "hp", percent = 10 },
	},
	DishOrder = { "fishVegSoup", "veggieStew", "grilledFish" },
	BuffSeconds = 1200,
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
	GardenYield = 3,
	GardenCarrotChance = 0.5,
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

Config.Training = {
	Base = 0.60,
	Soft = 10,
	ChancePerLevel = 1 / 49,
	Gain = 1,
	HpGain = 10,
}

-- ===== Upgrade pads and work places (the owner, 2026-10-29, docs/GAMEPLAY.md §10) =====
Config.Pads = {
	-- The owner: leave every price at $0 for now. Turn this off and the real Village price returns.
	FreeUpgrades = true,
	Radius = 2.4, -- studs; the pad's disc
	StandHeight = 6, -- a player this far above the ground still stands on it
	CheckSeconds = 0.1,
	-- where each pad stands: x, z in the area's own frame, beside the path near the entrance
	Spots = {
		fishing = { -8.5, -17 },
		garden = { 8, -13.5 },
		pantry = { 6.5, -13.5 },
		kitchen = { 6.5, -12.5 },
		training = { 6.5, -15.5 },
		breeding = { 9, -17.5 },
	},
}

Config.WorkPlaces = {
	BinCapacity = 10, -- fish, or vegetables of any kind, a bin shows
	-- the bins outside the pond and the garden, beside the path: x, z in the area's frame, turn in degrees
	FishBin = { 9.5, -20.5, 0 },
	VegBin = { -5.8, -16.5, 0 },
	-- the fourth fishing place: a blue-grey boulder on the pond's bank (x, z in the pond's frame, its real
	-- height, the widest it may be); the kit model and its tint
	FishRock = { x = -19.5, z = 6, height = 3.4, width = 7, model = "WideBoulder", tint = { 112, 148, 200 } },
	-- the dock's first place stands this many studs in from its far end (the second is mid-dock); the pier's
	-- place, at its end (pond frame)
	DockEndInset = 1.0,
	-- the garden: how far the four places stand off the beds' edges, and the side ones shifted along the beds
	GardenGap = 2.2,
	GardenSideShift = 4,
	PierPlace = { x = 15.2, z = -0.5 },
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
	-- Distance from the centre to the middle of each rim slot.
	RimRadius = 360,
	-- A home plot is a square this wide (a 3x3 grid of areas).
	PlotSize = 160,
	-- The Market's footprint (across the rim, along the radius).
	MarketWidth = 200,
	MarketDepth = 160,
	-- The flat valley floor; hills rise beyond it.
	FloorRadius = 490,
	HillOuterRadius = 600,
	HillHeight = 70,
	-- The ring road joining every plot and the Market.
	RingRoadRadius = 258,
	RingRoadWidth = 18,
	-- The Wild Garden and its Heart (World Boss clearing) with two Duel Rings at its edge.
	WildRadius = 240,
	HeartRadius = 46,
	DuelRingRadius = 14,
	DuelRingDistance = 78,
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
	-- The data shape's version. Bump it with each change of shape and add a migration for it.
	-- 2: discoveries gained the material bucket (docs/MATERIALS.md).
	-- 3: appearance determines colour genes; the pattern gene is retired.
	-- 4: living-village needs, jobs, pantry, pairs and incubators replace legacy farm fields.
	-- 5: plot-by-plot growing vegetables with safe migration from the old timed output.
	SchemaVersion = 5,
	-- A stored envelope without a version is this one.
	FirstSchemaVersion = 1,

	-- Session lock: a lock not refreshed for LockStaleSeconds belongs to a dead server and may be
	-- taken over. A live server refreshes its locks every LockRefreshSeconds even when idle.
	LockStaleSeconds = 600,
	LockRefreshSeconds = 180,
	-- Joining while another server still holds a fresh lock (a quick server hop): retry this many
	-- times, this far apart, then kick with a friendly "rejoin in a minute" instead of loading stale data.
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
	EggWobbleWindow = 8,
	EggWobbleDegrees = 10,
	EggWobbleHz = 4,
	EggHeight = 1.4,
	-- An egg stands on the bed found by a ray from this far above its marker down this far, this much above it.
	EggRestProbeUp = 1.2,
	EggRestProbeDown = 3,
	EggRestLift = 0.02,
	CarryHeight = 1.1,
	CarryScale = 0.42,
	SleepBillboardPixels = 32,
	SocialBillboardPixels = 38,
	BillboardDistance = 65,
	MaxDrawDistance = 400,
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

-- ===== The screen kit (src/client/Ui*.luau): the owner's art, palette, fonts and sizes =====
-- Every image is the owner's own art from reference/goo-lineage-web/assets, trimmed to its bounds only and uploaded
-- (art-pipeline). An id of 0 is a picture that does not exist yet: the client logs it once and shows a stand-in.
Config.Ui = {
	Icons = {
		coins = 127025864156501, -- mat-coins.png
		food = 128780371839699, -- mat-food.png
		fullness = 128780371839699, -- mat-food.png (the sack stands for being fed)
		slimes = 120929268236217, -- slime.base.navy.png (the original's slime-count icon)
		attack = 85243818608247, -- stat-attack.png (the owner's star)
		defence = 74089620499791, -- equip-shield.png
		speed = 96175650939419, -- stat-speed.png (the owner's bolt)
		hp = 113610467784918, -- stat-hp.png (the owner's heart)
		fishing = 126305761994889, -- prop.workstation.fishing-pond.png
		garden = 85177293898894, -- prop.workstation.farm-plot.png
		kitchen = 138156697526360, -- prop.workstation.cooking-kitchen.png
		pantry = 128780371839699, -- mat-food.png
		training = 70679228626362, -- ui.btn.upgrades.png
		breeding = 92923495054582, -- ui.btn.breeding.png
		-- Missing pictures (asked of ChatGPT): food kinds, needs and controls.
		fish = 0,
		carrot = 0,
		cabbage = 0,
		grilledFish = 0,
		veggieStew = 0,
		fishVegSoup = 0,
		energy = 0,
		fun = 0,
		close = 0,
		back = 0,
		plus = 0,
		cross = 0,
	},
	-- The round edge buttons are the original's ui.btn.<id> art.
	Buttons = {
		slimes = 74629091770984,
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
	IconSmall = 20,
	IconNormal = 28,
	ChipHeight = 40,
	TextTiny = 13,
	TextSmall = 15,
	TextNormal = 17,
	TextHeader = 22,
	ScaleBaseHeight = 720,
	ScaleMax = 1.35,
	SheetWidth = 460,
	SheetHeight = 340,
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
	-- The strip: raw foods fold into one Food chip until each kind has its own picture.
	HudOrder = { "coins", "fish", "carrot", "cabbage", "grilledFish", "veggieStew", "fishVegSoup", "slimes" },
	-- Slime book.
	BookSorts = { "level", "speed", "newest" },
	BookFilters = { "all", "free", "working", "babies" },
}

return Config
