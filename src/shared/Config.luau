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
	SlotLevels = { 11, 21, 31, 41 },
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
	PathMinRadius = 1.5,
	PathRadiusPerScale = 1.2,
	PathHeightPerScale = 3,
	PathWaypointStuds = 3,
	PathStraightTolerance = 0.07,
	PathPointEpsilon = 0.08,
	PathCacheSeconds = 30,
	PathRefreshSeconds = 3,
	PathRefreshStuds = 3,
	PathWarningSeconds = 30,
	PathAvoidStuds = 2.5,
	PathWaitSeconds = 0.55,
	CarryPromptDistance = 10,
	CarryPromptHoldSeconds = 0,
	CarryReachStuds = 12,
	CarryModelScale = 0.42,
	CarryHeadOffset = 1.4,
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
		Box = { "CollectionBox", "FishBucket", "HarvestBox", "DishBox" },
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
		Pond = { "PondEdge", "WorkSpot1", "Dock" },
		Campfire = { "Campfire", "FirePit" },
	},
	SpotSearchStuds = 30,
	SpotDoorOffset = 2,
	SpotCounterOffsetX = -2,
	SpotFridgeOffsetX = 4,
	SpotBoxOffsetX = -4,
	SpotNapOffset = 5,
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
	KitchenYield = 1,
}

Config.Training = {
	Base = 0.60,
	Soft = 10,
	ChancePerLevel = 1 / 49,
	Gain = 1,
	HpGain = 10,
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

	-- Cost: every slime closer than FullStuds is drawn every frame, up to FarStuds at 10 Hz,
	-- beyond that only its physics runs (and not even that beyond SleepStuds).
	FullStuds = 70,
	FarStuds = 160,
	SleepStuds = 400,
	FarHz = 10,
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
	SchemaVersion = 4,
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
	FacingBlend = 0.22,
	CarryTopOffset = 0.1,
	GhostFloat = 0.35,
	GhostFloatHz = 0.35,
	EggWobbleWindow = 8,
	EggWobbleDegrees = 10,
	EggWobbleHz = 4,
	EggHeight = 1.4,
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

-- Image artists fill these placeholders. Every 0 is explicitly logged once by the client.
Config.Ui = {
	Icons = {
		coins = 0,
		fish = 0,
		carrot = 0,
		cabbage = 0,
		grilledFish = 0,
		veggieStew = 0,
		fishVegSoup = 0,
		slimes = 0,
		energy = 0,
		fullness = 0,
		attack = 0,
		defence = 0,
		speed = 0,
		hp = 0,
		worker = 0,
		reserve = 0,
		breeding = 0,
		close = 0,
	},
}

return Config
