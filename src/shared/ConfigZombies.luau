--!strict
-- Config.Zombies, in a file of its own: Studio refuses a script of 200000 characters or more, so Config's
-- biggest blocks live apart. Config.luau requires this file; the game reads it as Config.Zombies.

return {
	-- Teams a farm can ever have (docs/MONETIZATION.md §2): the village opens the first #TeamOpensAt of them, each Extra Team
	-- pass adds one on top (shared/Boosts.extraTeams), never above this.
	Teams = 6,
	-- The strongest slimes of this many teams (of TeamSize) set the zombies' level, so a team pass never changes the world.
	LevelTeams = 4,
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
	-- grows, 4 at most); team 5 and 6 come from the Extra Team passes only.
	TeamOpensAt = { 1, 10, 20, 30 },
	-- The longest group id a saved team may name as its target (ids look like "c3g4").
	TargetIdMaxLength = 16,
	ShopRangeStuds = 40,
	-- Most slimes one "SellMany" request may name (the shop ticks several slimes and sells them with one press; the server
	-- refuses a longer list outright, so one request cannot be made to loop over a huge table).
	SellManyMax = 12,
	-- A team marches from the gate to a spot MarchStandOffStuds short of its group (towards the village), in MarchGait,
	-- and back the same way; the slowest member sets the pace.
	MarchStandOffStuds = 11,
	MarchGait = "walk",
	-- A team that won stays on the field this long to cheer before it marches home.
	CheerSeconds = 2.2,
	-- A wound heals this share of a slime's health a minute while it is home (2: a full heal in 30 s). The owner,
	-- 2026-11-04: new players waited more than they fought. At 0.5 a 4 minute repeat cycle held 23 s of fighting and
	-- about 64 s of healing (tools/balance/early_game_sim.luau).
	HealPerMinute = 2,
	-- Every slime that fought loses this much energy and fullness when the fight ends (the brain rests and feeds it).
	-- On repeat a team fights about 25 times an hour. Measured (tools/balance/kitchen_sim.luau, real VillageSim, 0.55
	-- productive): at 5 the fighters ate more than the pond and garden make and slimes went hungry at levels 1-30; at 3 level
	-- 20 still did; at 2 nobody is hungry at any level. Energy at 8 sent the team to sleep for 14 minutes every 10 fights,
	-- the largest wait of all (37% of the cycle); at 2 a team fights about 35 times, an hour or more, before it naps.
	FightEnergy = 2,
	FightFullness = 2,
	-- HpShare on a slime's model is rounded to this step, so a healing wound does not rewrite it every frame.
	HpShareStep = 0.01,
	-- A zombie's stats against an even slime of the player's level, per camp. Five levels mean far more at level 4 than
	-- at level 60, so a camp's risk comes from this and stays the same all game; its level sets the reward.
	-- (camp 1 was 0.75: three slimes in four fell every fight there, each one a ghost to feed back to life; the owner,
	-- 2026-11-04, wants new players to keep playing)
	StatFactors = { 0.62, 0.9, 1.03 },
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
		-- the knock-back taken is divided by the body's size (Dungeon monsters' look size, 1 or more) to this power
		KnockWeight = 2,
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
				-- Ember Lava's two bosses, each its own (Config.Combat.Skills): the Bull's stomp lands on the Bull's own feet with a
				-- shock and a cracked ground; the Golem's eruption throws bursts down on every slime and rings each one. (The owner's
				-- battle art has no fire in it: these stand in until ChatGPT draws the fire set.)
				lavastomp = {
					leap = true,
					burst = "shockwave",
					bits = "sparkStar",
					ring = "groundCrack",
					ring2 = "ring",
				},
				eruption = {
					burst = "shockwave",
					bits = "moteShock",
					ring = "groundCrack",
					rain = "burstShock",
					rainRing = "ringShock",
				},
				-- Frozen Ice's two bosses, each its own: the Mammoth's charge leaps onto its target with a holy-white burst and a
				-- double ring (a ram, never a stomp's cracked ground); the Yeti's blizzard bursts over the whole field and lets
				-- sparks fall on every slime, ringed by a cold arcane ring. (Stand-ins from the owner's battle art until ChatGPT
				-- draws the frost set.)
				tuskcharge = {
					leap = true,
					onTarget = true,
					burst = "holyHit",
					bits = "sparkStar",
					ring = "ringShock",
					ring2 = "ring",
				},
				blizzard = {
					burst = "holyHit",
					bits = "moteArcane",
					ring = "ringArcane",
					rain = "sparkStar",
					rainRing = "ring",
				},
				-- The weapon classes' signature skills (Config.Classes.Skills; the weapon's own move is SlimeWeapon's): the
				-- Guardian's Taunt rings out from its shield and rings every foe it pulls (`mark`); the Mage's Arcane
				-- Barrage fires an orb from its focus at every foe it strikes (`fire`); the Alchemist's Acid Rain drops
				-- flasks out of the sky; the Healer's Mend blooms with healing light on the one it mends. (Dash Strike and
				-- Piercing Shot are one heavy blow each: the slash and the arrow, struck like a crit.)
				taunt = { burst = "shockwave", bits = "sparkStar", ring = "ringShock", mark = "ring" },
				arcane_barrage = { burst = "burstArcane", bits = "moteArcane", fire = "magicOrb" },
				acid_rain = { burst = "burstAcid", bits = "acidDrop", rain = "flask", rainRing = "ringAcid" },
				mend = { burst = "burstHeal", bits = "moteHeal", ring = "ringHeal" },
			},
			-- what a slime's weapon sends to the one it heals (client/ZombieFight onHeal)
			HealShot = "moteHeal",
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
			Stand = {
				attack = 0.6,
				defence = 0.5,
				speed = 1.6,
				hp = 0.8,
				rotten = 0.7,
				toxic = 2.6,
				plague = 0.6,
				lavastomp = 0.8,
				eruption = 0.8,
				tuskcharge = 0.7,
				blizzard = 1,
			},
			Spread = {
				attack = 35,
				defence = 20,
				speed = 85,
				hp = 30,
				rotten = 55,
				toxic = 40,
				plague = 30,
				lavastomp = 30,
				eruption = 30,
				tuskcharge = 25,
				blizzard = 35,
			},
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
				-- the weapon classes' shots and marks (uploaded 2026-11-12, the same owner's art)
				arrow = 82413238923480,
				magicOrb = 105805604631830,
				flask = 71171803781285,
				lightBolt = 71287933984411,
				pierceHit = 89533625695233,
				magicHit = 139805158816337,
				moteHeal = 96459906984856,
				burstHeal = 82104024519535,
				ringHeal = 136978294933550,
			},
			-- How a blow looks, by the attacker: a slime by its role (Config.Combat.Roles), a zombie by its kind. Every one
			-- its own art (the owner: never one effect recoloured). mark = the picture at the point of the hit (studs);
			-- bits = what flies off it; slash = the mark lies across the line of the blow (along = along it); shot = spat
			-- or shot from afar instead of a lunge; death / ring = a zombie's burst and the ring on the ground where it falls.
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
				-- the plain blows of Ember Lava's mini-boss and boss: a cracking stamp and a heaving shock
				lavastomp = {
					mark = "groundCrack",
					bits = "sparkStar",
					size = 4.4,
					death = "burstShock",
					ring = "ringShock",
				},
				eruption = {
					mark = "shockwave",
					bits = "moteShock",
					size = 4.8,
					death = "burstShock",
					ring = "groundCrack",
				},
				-- Frozen Ice's: the Mammoth's gouging tusks and the Yeti's freezing, spinning blows
				tuskcharge = {
					mark = "biteMarks",
					bits = "sparkStar",
					size = 4.6,
					death = "burstArcane",
					ring = "ringShock",
				},
				blizzard = {
					mark = "burstArcane",
					bits = "moteArcane",
					size = 4.8,
					death = "burstAcid",
					ring = "ringArcane",
				},
				-- The six weapon classes (Config.Classes, a squad slime fights by its weapon), as the original marks a blow
				-- by the attacker's weapon: the sword's slash, the shield's impact, the bow's arrow and pierce (lying along
				-- the shot), the focus's orb and magic hit, the staff's bolt of light and holy hit, the kit's flask and acid
				-- splash. Ranged marks at half size (the owner's veto: they piled up).
				warrior = { mark = "slashArc", bits = "moteShock", size = 3.6, slash = true },
				guardian = { mark = "burstShock", bits = "sparkStar", size = 3 },
				ranger = { mark = "pierceHit", bits = "sparkStar", size = 2.4, shot = "arrow", along = true },
				mage = { mark = "magicHit", bits = "moteArcane", size = 1.9, shot = "magicOrb" },
				healer = { mark = "holyHit", bits = "moteHeal", size = 1.7, shot = "lightBolt" },
				alchemist = { mark = "acidSplat", bits = "acidDrop", size = 1.9, shot = "flask" },
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
		StateIcons = { home = "slimes", going = "speed", fighting = "attack_order", returning = "back" },
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
