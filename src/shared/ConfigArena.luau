--!strict
-- Config.Arena, in a file of its own: Studio refuses a script of 200000 characters or more, so Config's
-- biggest blocks live apart. Config.luau requires this file; the game reads it as Config.Arena.

return {
	-- Version the JSON ladder independently of farm saves; bots keep a fresh season populated.
	Version = 1,
	Bots = 1000,
	TeamSize = 4,
	-- Calibrated with tools/balance/arena_sim.luau (2026-11-05, a plain player at 1.5 h a day on ECONOMY.md's road). The
	-- bottom is a team of about an hour and a half's play (power 40: wins 55-70% of its first five rivals, a bare starter
	-- team wins none); the top is a month-3 team with a full set of Bramble gear and then some (power 480 settles near
	-- rank 30; rank 1 is power 600). The late levels past village 50 are assumed (0.5 a level an hour): move the top with them.
	BotLevelMin = 8.75,
	BotLevelMax = 150,
	-- A cubic curve leaves many approachable rivals and few near the summit.
	BotLevelExponent = 3,
	-- Small level variation and one favoured stat give teams different roles at the same bot strength.
	BotLevelSpread = 0.1,
	BotFavouriteWeight = 2,
	-- Champions offer a challenge beyond the ladder: a quarter above the rank 1 bot, a stretch even for a near-maxed team.
	ChampionLevel = function(_season: number): number
		return 190
	end,
	-- The upper quarter of the ranks above is reachable; one hard, two middle, the rest nearby.
	AboveShare = 0.75,
	OpponentBands = 3,
	HardOpponents = 1,
	MiddleOpponents = 2,
	-- One card is a team just below (beating it pays BelowShare and moves no rank): rivals above are all stronger, so a
	-- settled team would otherwise lose almost every fight (balance/arena_sim: 2-3% wins).
	BelowOpponents = 1,
	-- Bound replay size and resolve stalemates as successful defences.
	MaxFightSeconds = 120,
	-- Stop new attacks five minutes before rollover; allow fifteen minutes for results to settle.
	LockSeconds = 300,
	FinalizeSeconds = 900,
	-- Participation pays a little; climbing pays more, with a cap against very large rank gaps. A fight is nearly decided by
	-- power and every rival offered is stronger, so a player at their rank wins only a few a day: the loss pays enough that
	-- ten tickets make about 150-180 points a day (arena_sim).
	LossPoints = 12,
	WinPoints = 30,
	BelowShare = 0.6,
	ClimbBonusPerStep = 1,
	ClimbBonusCap = 20,
	-- Monthly awards favour the summit while giving every ranked participant a modest reward.
	SeasonRewards = {
		{ upTo = 1, points = 1000, badge = "Champion" },
		{ upTo = 3, points = 750, badge = "Podium" },
		{ upTo = 10, points = 500, badge = "Elite" },
		{ upTo = 50, points = 300, badge = "Contender" },
		{ upTo = 100, points = 200, badge = "Challenger" },
		{ upTo = 500, points = 100, badge = "Rival" },
		{ upTo = math.huge, points = 50, badge = "Participant" },
	},
	-- Short goals reward returning and improving without an uncapped grind bonus.
	Quests = {
		{ id = "daily_win", period = "day", wins = 1, points = 30, stronger = false },
		{ id = "weekly_wins", period = "week", wins = 5, points = 50, stronger = false },
		{ id = "weekly_stronger", period = "week", wins = 1, points = 40, stronger = true },
		{ id = "season_10", period = "season", wins = 10, points = 50, stronger = false },
		{ id = "season_25", period = "season", wins = 25, points = 100, stronger = false },
		{ id = "season_50", period = "season", wins = 50, points = 150, stronger = false },
	},
	NameStarts = { "Bram", "Clover", "Dew", "Fern", "Glim", "Moss", "Pebble", "Pip", "Sprout", "Willow" },
	NameEnds = { "bell", "brook", "bud", "drop", "leaf", "ling", "pool", "root", "shine", "wick" },

	-- The farm's side (shared/ArenaRules, farm.arena): attacks a UTC day; how many seasons the claimed map and the history
	-- keep; how many past seasons a login looks through for an unclaimed reward.
	TicketsPerDay = 10,
	KeepSeasons = 12,
	ClaimLookback = 3,
	-- An attack whose outcome has not shown in the ladder this long is sent again (safe: the ladder applies a seq once).
	ResendSeconds = 60,

	-- The global stores (server/ArenaStore). One DataStore holds Ladder_<season>, Def_<userId> and Log_<userId>; match
	-- results travel through one MemoryStore queue to the one server holding the leader lease, the only ladder writer.
	-- A test switch, off in anything committed: a Studio play test uses the real stores only when on.
	StudioUsesRealStore = false,
	StoreName = "GooLineage_Arena_v1",
	QueueName = "ArenaResults",
	LeaseMapName = "ArenaLeader",
	LeaseKey = "leader",
	-- The lease outlives two missed ticks; a leader renews it every tick.
	LeaseSeconds = 30,
	TickSeconds = 15,
	-- One leader tick reads up to ReadsPerTick batches of ReadBatch items (100 is MemoryStore's most a read).
	ReadBatch = 100,
	ReadsPerTick = 20,
	-- An item read and not removed comes back after this long (the leader then waits this long before reading again, so
	-- the items come back in their order).
	InvisibleSeconds = 30,
	-- A queued result is kept this long before MemoryStore drops it (short: a lost item is sent again after ResendSeconds,
	-- and a stalled leader must not let copies fill the MemoryStore quota the lease shares).
	QueueItemSeconds = 2 * 3600,
	-- Ladder writes stay within this many bytes a minute: a document over 250 KB (WriteBytesPerMinute / 4 writes a
	-- minute) is written less often than every tick. Never two writes of one key closer than MinWriteSeconds (DataStore's
	-- limit is one write a key every 6 s). A document past WarnDocBytes logs a warning (the DataStore limit is 4 MB).
	WriteBytesPerMinute = 1000000,
	MinWriteSeconds = 6,
	WarnDocBytes = 1000000,
	-- A defender's log (Log_<userId>) keeps its last LogKeep entries.
	LogKeep = 10,

	-- The server service (server/Arena, Remotes.Arena). Opponents offered at a time; a new list at most every RefreshSeconds;
	-- requests a second a player; a client's request id is at most RequestIdMaxLength characters; the state's top rows.
	Opponents = 5,
	RefreshSeconds = 30,
	RequestsPerSecond = 4,
	RequestIdMaxLength = 40,
	TopCount = 10,
	-- Matches in flight are looked at every SettleSeconds against a ladder at most SettleReadSeconds old; ranks follow the
	-- ladder every LadderRefreshSeconds; a past season's ladder is read for its reward at most every ClaimReadSeconds. A past
	-- season with no ladder written (nobody played it) is closed with no reward ClaimGraceSeconds after its final time.
	-- (SettleReadSeconds = TickSeconds: the leader writes no oftener, and every server reading the one ladder key every 5 s
	-- would reach DataStore's per-key read limit with a few busy servers)
	SettleSeconds = 5,
	SettleReadSeconds = 15,
	LadderRefreshSeconds = 60,
	ClaimReadSeconds = 300,
	ClaimGraceSeconds = 3600,
	-- The defence snapshot (Def_<userId>): its shape's version; sent again when the team changed (at most every
	-- PublishGapSeconds) or only its power did (at most every SnapshotDebounceSeconds); an opponent's is read at most every
	-- SnapshotReadSeconds. A player's own log is read at most every LogReadSeconds.
	SnapshotVersion = 1,
	PublishGapSeconds = 10,
	SnapshotDebounceSeconds = 300,
	SnapshotReadSeconds = 300,
	LogReadSeconds = 10,

	-- A player's last BuyRequestsKept shop buys are remembered by request id, so a re-sent one buys nothing twice.
	BuyRequestsKept = 8,

	-- The Arena scene (client/ArenaStage): a model in ReplicatedStorage that each client copies far from the map while its own
	-- fight is replayed; nobody else sees it. Sizes are studs, times seconds.
	Stage = {
		-- Where the copy's pivot (the Pit's centre) goes: 9000 studs out is far beyond the map's rim (under 1000), high up so
		-- no ground or farm roof is ever in view, and still small enough that single-precision positions stay exact.
		Origin = { x = 0, y = 500, z = 9000 },
		-- The screen goes the game's dark brown (Ui.KitOutline) and back; the cover sits over every other screen.
		FadeSeconds = 0.4,
		FadeOrder = 50,
		-- The seat's lens: at the default 70 the fighters were specks; 50 frames the sand with the stands and royal box round it.
		FieldOfView = 50,
		-- Only this many spectators move (a crowd of 60 hopping is a phone's cost for no gain).
		CrowdMax = 24,
		-- The stands hold the game's own slimes (SlimeLook), made ahead on this client with a budget: each frame at most
		-- CrowdPerFrame steps (one look built, or one spectator cloned and placed), so no frame stalls and a phone never
		-- sees a hitch; the stage copy itself is a step of its own frame. 6 keeps one frame near a millisecond.
		CrowdPerFrame = 6,
		-- A crowd slime is this many times the village's body height (3 studs): from the View seat the far stands are ~100
		-- studs off, and at 1.0 a slime is a dozen pixels tall on a phone held wide; 1.15 reads and still fits one row a tier.
		CrowdScale = 1.15,
		-- Each seat's slime is this much bigger or smaller (a share), and turns this far (radians) off straight at the pit,
		-- so the rows are not drilled. Seeded with CrowdSeed so a session always shows the same stands.
		CrowdScaleJitter = 0.08,
		CrowdYawJitter = 0.25,
		CrowdSeed = 20261105,
		-- The looks the crowd is cloned from (building every spectator on its own would cost a hundred times more): all 11
		-- base colours, CrowdDuals Dual designs picked at random, and the materials named here; a Dual counts for
		-- CrowdDualWeight of a plain look when a seat picks one, a material for CrowdMaterialWeight (they are the rarer ones in
		-- the game too). Only materials that read well far off and cost nothing extra (no Neon / Force Field glow).
		CrowdDuals = 4,
		CrowdMaterials = { "gold", "silver", "ice", "marble" },
		CrowdDualWeight = 0.5,
		CrowdMaterialWeight = 0.4,
		-- The faces a look may wear (Expressions ids, picked at random; "normal" twice because most slimes just look at you).
		CrowdFaces = { "normal", "normal", "happy", "exciting", "admiring", "loved", "wink" },
		-- A spectator now and then hops this high for this long, then waits a random time in IdleSeconds.
		HopHeight = 0.5,
		HopSeconds = 0.45,
		IdleSeconds = { 1.5, 6 },
		-- When the fight ends the crowd cheers: hops of this height and length, a new one after a short random wait, for this
		-- long. A win is louder and longer than a loss.
		CheerHopSeconds = 0.4,
		CheerGapSeconds = 0.5,
		CheerWin = { Height = 1.5, Seconds = 3 },
		CheerLoss = { Height = 0.6, Seconds = 1.5 },
		-- The ray that finds the Pit's top (studs up from its middle, and down past it).
		PitRayUp = 20,
	},

	-- The Arena shop (ArenaRules.buy / shop): points buy dungeon materials and one piece of gear (also a Smithy recipe; here a shortcut).
	-- In list order. `kind` "material" -> farm.materials[item] (an id of Config.Dungeon.Materials); "gear" -> the bag
	-- (farm.gear[item], an id of Config.Smithy.Gear). `count` is what one buy gives, `price` its Arena points, `weeklyLimit`
	-- how many buys a UTC week (Monday 00:00) allow. Cheap staples sell often and the rare drops sell rarely so the Arena
	-- eases the dungeon grind without replacing it. Calibrated with tools/balance/arena_sim.luau: a player makes about 1,100
	-- points a week; the rare rows at their limits are worth about 8 dungeon runs of drops a week (a quarter of what a player
	-- who spends a fifth of 1.5 h a day in the dungeon finds), the staples about 11.
	Shop = {
		{ id = "ore5", kind = "material", item = "ore", count = 5, price = 40, weeklyLimit = 10 },
		{ id = "fragment2", kind = "material", item = "rare_part", count = 2, price = 60, weeklyLimit = 10 },
		{ id = "core1", kind = "material", item = "monster_core", count = 1, price = 200, weeklyLimit = 2 },
		{ id = "horn2", kind = "material", item = "boar_tusk", count = 2, price = 250, weeklyLimit = 2 },
		{ id = "essence1", kind = "material", item = "boss_essence", count = 1, price = 600, weeklyLimit = 1 },
		{ id = "charm_core", kind = "gear", item = "charm-core", count = 1, price = 450, weeklyLimit = 1 },
	},

	-- The client's side (client/UiArena, ArenaReplay, ArenaTitles). Sizes are points / pixels, times are seconds.
	View = {
		-- the Arena sheet (a bottom sheet on a phone)
		SheetWidth = 520,
		SheetHeight = 480,
		ClockSeconds = 1,
		DaySeconds = 86400,
		-- a request that got no answer is sent again once, with the same request id, after RetrySeconds; the state is looked at
		-- again on a tab change when it is older than FreshSeconds
		RetrySeconds = 1.5,
		FreshSeconds = 5,
		-- Battle: a rival's card, its small portraits (one built a frame), and how a rival's power reads against yours
		-- (above DangerRatio times yours = danger, below FairRatio = easy, between = close)
		CardHeight = 92,
		Portrait = 38,
		PortraitsPerFrame = 1,
		DangerRatio = 1.15,
		FairRatio = 0.85,
		RankWidth = 44,
		PowerWidth = 62,
		-- a match is looked at every PollSeconds until the ladder holds it, for at most PollMaxSeconds
		PollSeconds = 3,
		PollMaxSeconds = 60,
		-- the result card
		ResultWidth = 340,
		ResultHeight = 300,
		ResultTextSize = 34,
		-- Team: a seat on the strip
		SlotSize = 52,
		-- Ranking: a row, the rank badge
		RowHeight = 46,
		BadgeWidth = 44,
		BadgeHeight = 28,
		PointsWidth = 72,
		-- Shop: a card and its picture
		ShopCard = 84,
		ShopIcon = 52,
		BuyWidth = 84,
		-- Records: a quest row, the log's rows and how many it shows
		QuestRow = 56,
		LogRow = 40,
		LogShown = 10,
		StatBlock = 76,
		-- The replay on the Arena scene's Pit (or, with no scene, in front of the player): the round field, how far each side
		-- stands from the middle, the spacing and stagger of a side (the Dungeon squad's), the distance in front of the player,
		-- the lead-in and the hold at the end, the speed of the x2 button, the ray that finds the ground, the side label
		-- (wider than the Dungeon squad's: on the stage camera, ~100 studs off, 4.2 and 6.5 piled eight slimes into one heap)
		Replay = {
			FieldRadius = 22,
			SideGap = 8,
			Spacing = 5.2,
			Stagger = 1.4,
			FrontStuds = 14,
			LeadSeconds = 1.2,
			EndHoldSeconds = 2.4,
			SkipHoldSeconds = 2,
			FastSpeed = 2,
			StepSeconds = 0.03,
			RayUp = 20,
			RayDown = 80,
			LabelWidth = 200,
			LabelHeight = 30,
			LabelLift = 6,
			LabelDistance = 150,
			ButtonWidth = 64,
			-- a body that fell is faded to this transparency
			FadeTransparency = 0.6,
			FadeSeconds = 0.5,
			-- hit points shown when the server does not say them: the share of the damage taken a survivor's full health is
			SurvivorShare = 1.6,
		},
		-- The title over the head of a player in the top 10 (client/ArenaTitles): size in pixels, studs above the head, how far
		-- it shows, text size, the ranks that sparkle and how (rate, studs the sparkle shows within, size), how often distances
		-- are looked at, the shimmer's period and share of it that sweeps, and the colours of gold / silver / bronze / top 10
		Title = {
			Width = 240,
			Height = 46,
			Lift = 3.4,
			-- studs kept clear above the tallest hat or wings
			HatClearance = 1.6,
			MaxDistance = 100,
			TextSize = 32,
			Top = 10,
			SparkleRanks = 3,
			SparkleRate = 3,
			SparkleStuds = 60,
			SparkleSize = 0.7,
			SparkleLife = 1.3,
			CheckSeconds = 0.5,
			ShimmerHz = 30,
			ScaleReference = 900,
			ScaleMin = 0.7,
			ScaleMax = 1.3,
			ShimmerSeconds = 2.8,
			ShimmerSweep = 0.55,
			ShimmerLift = 0.55,
			Colours = { "#ffd34e", "#e4ebf3", "#e0955a", "#5fbfff" },
			Names = { "No.1 Arena", "No.2 Arena", "No.3 Arena", "Top 10 Arena" },
		},
	},
}
