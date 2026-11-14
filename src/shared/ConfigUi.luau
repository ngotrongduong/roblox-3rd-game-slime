--!strict
-- Config.Ui, in a file of its own: Studio refuses a script of 200000 characters or more, so Config's
-- biggest blocks live apart. Config.luau requires this file; the game reads it as Config.Ui.

return {
	Icons = {
		coins = 127025864156501, -- mat-coins.png
		food = 128780371839699, -- mat-food.png
		fullness = 128780371839699, -- mat-food.png (the sack stands for being fed)
		slimes = 120929268236217, -- slime.base.navy.png (the original's slime-count icon)
		-- The attack stat is a flexed arm and the order to fight is two crossed swords (ChatGPT in the owner's style,
		-- 2026-11-08, art/icons/stat_strength.png, attack_order.png): the owner said a sword read wrong for both.
		attack = 79453032521763,
		attack_order = 131910550995231,
		sword = 99675585132127, -- equip-sword.png (the owner's sword: putting on gear)
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
		-- A team's tactic on the team sheet (ChatGPT in the owner's style, 2026-11-14, art/icons/tactic_*.png): a scale with a
		-- sword and a shield, three arrows in one bullseye, a slime safe behind a shield.
		tacticBalanced = 115541736148862,
		tacticFocus = 115118402947931,
		tacticProtect = 89281044598620,
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
		-- The Lucky Wheel, the Weekly and Goals tabs, the Robux shop's pictures and the wheel's three pieces (ChatGPT, 2026-11-06,
		-- art/icons/): the wheel's face has nine equal slices, slice 1 centred at 12 o'clock then clockwise
		spin = 113070167027120,
		food_basket = 112205796398834,
		jackpot = 103747008318854,
		weekly_chest = 97855134024590,
		goals = 90398853365240,
		vip = 113820035966136,
		gold_pouch = 133246189222197,
		gold_sack = 112351319056692,
		gold_chest = 132669366872117,
		gold_vault = 87274028358915,
		potion_luck = 125363840422006,
		potion_gold = 88033178692091,
		potion_hatch = 72802531338833,
		energy_drink = 136065314924947,
		team_slot = 97132569434412,
		ranch_slot = 129313087934866,
		hatch_now = 113945569456522,
		quest_reroll = 133105941736416,
		streak_saver = 123803458623825,
		starter_pack = 135427122864978,
		-- The Robux symbol on every price of the VIP Shop: NOT DRAWN YET (ChatGPT), a short stand-in shows until it is.
		robux = 0,
		wheel_face = 103726425683178,
		wheel_pointer = 107372263242685,
		wheel_hub = 113956074271568,
		luck = 76165751061122,
		rewards = 92181600961063,
		collection = 91176780566160,
		-- The community rewards (shared/Social): the favorite star and the group's banner. NOT DRAWN YET (ChatGPT).
		favorite = 0,
		community = 0,
		-- The Slime Dungeon's gate sheet header: a stone portal ring with a blue swirl (ChatGPT, 2026-11-04, art/icons/dg_dungeon.png).
		dungeon = 136488942687177,
		-- The lock over the Dungeon portal and the bag of the inventory (ChatGPT, 2026-11-04).
		lock = 91241912398933,
		bag = 124936043377188,
		-- the Arena's, made by ChatGPT in the owner's style (art/icons/arena*.png, arena_points.png, arena_ticket.png)
		arenaPoints = 115001232698763, -- the gold slime medal coin: the Arena points
		arenaTicket = 110984086281837, -- the attack ticket
		arena = 113759764912682, -- the emblem: shield, crown, crossed swords
		-- the Arena's ranks 1-3 (slime-face medals), a team's power (the jelly fist), a quest done (the green tick)
		arenaMedal1 = 137250655789281,
		arenaMedal2 = 105851393851815,
		arenaMedal3 = 75198332250507,
		arenaPower = 117470476798117,
		arenaQuest = 86809844247366,
		-- the faint pictures of an empty gear slot on the slime's page
		slotWeapon = 72608277069089,
		slotHead = 87341761427328,
		slotCharm = 129687119015421,
		-- The map (UiMap), drawn by ChatGPT 2026-11-14 (art/icons). map_player is a white arrow pointing up, map_pack a
		-- small white monster head; both are tinted by code.
		map = 111178071211374,
		waystone = 139707615352746,
		waystone_locked = 80302175896662,
		zone_mini = 119774594976594,
		zone_boss = 129992543467584,
		zone_heart = 81038888187455,
		map_player = 124427272471970,
		map_pack = 83728428397346,
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
	-- (The owner's ui-frame-gold 109389746503451 and ui-frame-wood 72424466145847 drew the frames until 2026-11-04.)
	-- The game's UI kit (the owner, 2026-11-04: every screen exactly in the style of ChatGPT's slime sheet,
	-- docs/ui/slime-sheet/concept.webp): pieces ChatGPT drew on magenta (art/inbox/kit-*.webp), cut by
	-- tools/chatgpt/prepare_ui_kit.py and made ready by tools/chatgpt/kit_slices.py (tools/chatgpt/ui_kit.json), art/ui/kit/.
	-- Width/Height are the picture's pixels; Slice the nine-slice centre { minX, minY, maxX, maxY } (a piece without it is
	-- drawn whole). A piece sliced only left and right is scaled so its height fills the box (its round ends stay round);
	-- the others are drawn at Scale. Inset: how far a frame's content sits inside its box, in points.
	Kit = {
		window = {
			Id = 83319470030702,
			Width = 200,
			Height = 200,
			Slice = { 96, 96, 104, 104 },
			Scale = 0.3,
			Inset = 15,
		},
		panel = {
			Id = 103359321971280,
			Width = 152,
			Height = 160,
			Slice = { 72, 80, 80, 88 },
			Scale = 0.28,
			Inset = 14,
		},
		slot = { Id = 81210065494197, Width = 225, Height = 233 },
		plate = { Id = 78306538497691, Width = 132, Height = 75, Slice = { 62, 0, 70, 75 } },
		square = { Id = 84612457545890, Width = 88, Height = 88, Slice = { 40, 40, 48, 48 }, Scale = 0.3, Inset = 7 },
		row = { Id = 81008255857827, Width = 88, Height = 68, Slice = { 40, 30, 48, 38 }, Scale = 0.45 },
		soft = { Id = 119025095153238, Width = 88, Height = 88, Slice = { 40, 40, 48, 48 }, Scale = 0.3, Inset = 6 },
		green = { Id = 98438118018822, Width = 200, Height = 185, Slice = { 96, 0, 104, 185 } },
		purple = { Id = 95952653032375, Width = 200, Height = 185, Slice = { 96, 0, 104, 185 } },
		gold = { Id = 130632152693674, Width = 200, Height = 185, Slice = { 96, 0, 104, 185 } },
		cream = { Id = 139658287172578, Width = 200, Height = 180, Slice = { 96, 0, 104, 180 } },
		red = { Id = 113159248515361, Width = 200, Height = 186, Slice = { 96, 0, 104, 186 } },
		bonus = { Id = 133796846693988, Width = 120, Height = 108, Slice = { 56, 0, 64, 108 } },
		level = { Id = 87264171926717, Width = 120, Height = 108, Slice = { 56, 0, 64, 108 } },
		track = { Id = 90211603666665, Width = 92, Height = 78, Slice = { 42, 0, 50, 78 } },
		barOrange = { Id = 130533140062342, Width = 92, Height = 77, Slice = { 42, 0, 50, 77 } },
		barBlue = { Id = 115049534015440, Width = 92, Height = 78, Slice = { 42, 0, 50, 78 } },
		barPink = { Id = 73235879796719, Width = 92, Height = 79, Slice = { 42, 0, 50, 79 } },
		portrait = { Id = 79472351597634, Width = 424, Height = 286 },
		ribbon = { Id = 107472306493164, Width = 340, Height = 216, Slice = { 100, 0, 108, 216 } },
		pedestal = { Id = 99303720716976, Width = 512, Height = 181 },
		scroll = { Id = 127635216154773, Width = 308, Height = 172, Slice = { 150, 0, 158, 172 } },
		accentLeft = { Id = 139409738038703, Width = 105, Height = 126 },
		accentRight = { Id = 126281894013539, Width = 105, Height = 126 },
		leavesLeft = { Id = 85680082265881, Width = 147, Height = 157 },
		leavesRight = { Id = 90512180302533, Width = 146, Height = 156 },
		diamond = { Id = 137886691459154, Width = 95, Height = 96 },
		counter = { Id = 132334214999463, Width = 200, Height = 151, Slice = { 140, 0, 148, 151 } },
	},
	-- The kit's text: white with a dark brown outline on the coloured buttons and the name ribbon (as in the concept),
	-- brown on cream.
	KitOutline = "#4a2c14",
	KitOutlineThickness = 1.5,
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
	-- The VIP Shop's sheet (UiMarket opens it at the counter, UiShop draws it): as tall as the other bottom sheets.
	VipSheetHeight = 440,
	-- The VIP Shop (UiShop), pixels: a good's card (its height, picture, the Buy button's size, the little picture in the
	-- effect line and its height) and the wheel's odds strip on the Spins tab (its height, a slice's picture).
	Shop = {
		RowHeight = 60,
		Icon = 40,
		ButtonWidth = 96,
		ButtonHeight = 44,
		-- the "Use (n)" button of a good bought while it could do nothing (an Energy Drink, a Hatch All Now), left of Buy
		UseWidth = 76,
		EffectIcon = 16,
		EffectHeight = 18,
		OddsHeight = 58,
		OddsIcon = 26,
		-- the pill that says "+14%" or "Save 21%": how wide a letter is, the room round the word, its height
		PillLetter = 7,
		PillPad = 16,
		PillHeight = 20,
		-- the Robux symbol on a Buy button
		PriceIcon = 18,
	},
	-- The small VIP crown (Icons.vip) over a VIP's head (client/VipBadge: the Arena title's budget, size and lift, see
	-- Config.Arena.View.Title) and in the resource strip (UiHud): the head crown's size and its gap to an Arena title, in
	-- pixels, and the strip's.
	VipBadge = { Size = 40, Gap = 8, HudSize = 30 },
	-- The team tabs of the gate sheet narrow to this when the header is short, so six fit (never under it), and the team
	-- chips on the left edge stand this many to a row.
	TabMin = 34,
	TeamChipColumns = 2,
	-- The Smithy sheet and the slime card's gear slots (UiSmithy, UiGearSlots), pixels: the sheet's height, a piece's card, its
	-- picture, a cost's picture, a stat tag, a worn slot's picture and cell, a row of the picker.
	Gear = {
		SheetHeight = 520,
		CardHeight = 150,
		Tile = 52,
		CostIcon = 24,
		PillHeight = 22,
		Slot = 56,
		SlotCell = 92,
		PickerRow = 48,
		PickerTile = 36,
	},
	-- The slime's page in the book (UiSlimeSheet, UiGearSlots), an RPG character sheet after docs/ui/slime-sheet/concept.webp.
	-- It is drawn from the UI kit (Config.Ui.Kit) on a fixed stage of DesignWidth x DesignHeight points laid out as the concept,
	-- shrunk to fit a smaller screen (a landscape phone's book content is about 728 x 244) and never grown past ScaleMax. The
	-- left column holds the slime on its pedestal, the three gear slots round it, the need bars and Feed; the right one the
	-- stats panel with the trait, Equip and, while it works, Stop work. Every number below is in points of the stage.
	SlimeSheet = {
		DesignWidth = 720,
		DesignHeight = 320,
		ScaleMax = 1.25,
		LeftWidth = 440,
		ColumnGap = 16,
		-- a gear slot: the kit's slot frame (SlotHeight keeps its picture's shape), the name plate over its wooden top (width,
		-- height, how far it sits down onto the frame), how far Weapon and Charm stand from the slime's centre and their top
		Slot = 78,
		SlotHeight = 81,
		PlateWidth = 96,
		PlateHeight = 26,
		PlateOverlap = 12,
		SideOffset = 140,
		SideTop = 84,
		-- the yellow strokes either side of the Head slot: size, distance of their centres from the middle, top
		AccentWidth = 34,
		AccentHeight = 40,
		AccentGap = 70,
		AccentTop = 26,
		-- the slime's picture (a square viewport; the body fills about 60% of it) and the pedestal under it (height from its
		-- picture)
		SlimeSize = 136,
		SlimeTop = 80,
		PedestalWidth = 220,
		PedestalTop = 168,
		-- the need bars' plate
		NeedsLeft = 136,
		NeedsTop = 244,
		NeedsWidth = 304,
		NeedsHeight = 74,
		NeedRow = 21,
		NeedIcon = 20,
		NeedNameWidth = 58,
		-- the round buttons at the bottom (Feed, Equip, Stop work): top, height, widths, the picture in them
		ButtonTop = 258,
		ButtonHeight = 54,
		FeedWidth = 126,
		EquipWidth = 156,
		StopWidth = 100,
		ButtonIcon = 30,
		-- the stats panel (the kit's panel, its gold diamond on top): top, height, the first row inside it, a row and the gap
		-- between rows, the stat's picture, the name's and value's widths, the green bonus pill
		PanelTop = 12,
		PanelHeight = 236,
		RowsTop = 12,
		StatRow = 32,
		StatGap = 5,
		StatIcon = 28,
		StatNameWidth = 90,
		StatValueWidth = 40,
		BonusWidth = 48,
		BonusHeight = 26,
		DiamondSize = 24,
		-- the trait scroll inside the panel's bottom, its leaves standing out past the panel's sides
		TraitTop = 186,
		TraitHeight = 42,
		TraitOverhang = 20,
		-- the header: the hexagon portrait (taller than the bar, it hangs over the frame), the slime's face in it, the name
		-- ribbon and the level pill on it
		HeaderPortrait = 62,
		HeaderFace = 40,
		RibbonHeight = 42,
		LevelPillHeight = 28,
		-- the list that opens beside a tapped slot, or over Feed
		PopoverWidth = 216,
		PopoverMaxHeight = 300,
	},
	-- The Bag (UiBag): a modal with a Materials tab and a Gear tab, read-only. Its size, a tile and the gap between tiles, a
	-- material's picture, a group header, the small worn badge, a "used in" piece's picture and the details strip's height.
	Bag = {
		Width = 560,
		Height = 440,
		Tile = 64,
		Gap = 8,
		MaterialIcon = 44,
		-- the Materials tab is drawn as a grid of at least this many slots, the empty ones faint, like an RPG bag
		MaterialSlots = 28,
		HeaderHeight = 24,
		WornIcon = 16,
		NeedTile = 28,
		DetailHeight = 64,
		-- the round edge button, a little under the book's
		Button = 48,
	},
	-- The Lucky Wheel tab of the rewards sheet (UiRewards): drawn on a stage of Design points that is scaled to fit (never past
	-- ScaleMax). Fractions are of the wheel's size: how far from the middle a slice's prize picture sits and how big it is, the
	-- hub (the SPIN button) and the pointer (its tip touches this far down from the top). The wheel takes Share of the sheet's
	-- width (NarrowShare on a narrow screen), the rest is the spin counts and the Odds button. A spin turns SpinTurns times in
	-- SpinSeconds and stops Landing (0..1) of half a slice off the slice's middle. SliceIcons: slices whose picture is not their
	-- first item's. The jackpot celebration (the hatch reveal's own sunburst and star pictures, Config.HatchFx.Textures): how
	-- many stars, how long, the sunburst's size and how far the stars fly (both in wheel sizes), a star's size in points.
	Wheel = {
		Design = 232,
		ScaleMax = 1.5,
		Share = 0.5,
		NarrowShare = 0.62,
		SliceIconRadius = 0.265,
		SliceIconSize = 0.165,
		HubSize = 0.34,
		PointerSize = 0.2,
		PointerTip = 0.155,
		SpinTurns = 4,
		SpinSeconds = 4,
		Landing = 0.7,
		PrizeSeconds = 3.2,
		OddsButtonWidth = 100,
		-- the "Get spins" button that opens the VIP Shop on its Spins tab
		ShopButtonWidth = 112,
		OddsRow = 48,
		SliceIcons = {
			coinsSmall = "gold_pouch",
			coinsBig = "gold_sack",
			food = "food_basket",
			luck = "potion_luck",
			spin = "spin",
			jackpot = "jackpot",
		},
		JackpotId = "jackpot",
		Jackpot = { Stars = 12, Seconds = 1.5, SunSize = 2, SunTurn = 80, StarSize = 28, StarReach = 1.3 },
	},
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
	-- The map (UiMap). Picture: the pixels of the map picture's side. The minimap is MiniSize square (MiniTall on a screen at
	-- least TallHeight points high; the team chips below it leave room for this much only) and shows MiniStuds across; it
	-- and the sheet are looked at again every RefreshSeconds. Mini / Sheet: the pixels of each marker. The sheet is Width x
	-- Height at most; Hit is a marker's press area; Legend the width of one band entry (a column beside a map on a screen
	-- WideRatio times wider than tall, rows under it otherwise); InnerPad what the sheet's frame takes from its width.
	Map = {
		Picture = 1024,
		RefreshSeconds = 0.25,
		MiniStuds = 700,
		MiniSize = 72,
		MiniTall = 104,
		TallHeight = 680,
		LabelHeight = 19,
		Mini = { Player = 14, Pack = 6, Zone = 14, Home = 16 },
		Sheet = {
			Width = 820,
			Height = 720,
			Footer = 56,
			Legend = 104,
			LegendRow = 22,
			LegendChip = 14,
			InnerPad = 44,
			WideRatio = 1.2,
			Player = 20,
			Pack = 8,
			Zone = 26,
			Home = 26,
			Stone = 14,
			Hit = 44,
			Icon = 28,
		},
		ZoneIcons = { mini = "zone_mini", boss = "zone_boss", mega = "zone_heart" },
	},
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
	-- A tile also shows the four fight stats (StatIcon, StatRow high) and the worn gear (GearIcon); the sort is one dropdown
	-- button (SortWidth wide) whose choices are named by SortNames.
	SortNames = { level = "Level", attack = "Attack", defence = "Defence", speed = "Speed", hp = "HP" },
	Tile = {
		Width = 96,
		Height = 152,
		StatIcon = 14,
		StatRow = 16,
		GearIcon = 18,
		SortWidth = 150,
		Portrait = 56,
		WoundHeight = 5,
		WoundLow = 0.35,
		SortArrow = 16,
		MarkSize = 22,
		-- A list opens by making this many tiles a frame (the first rows come first) and showing this many slime pictures a
		-- frame: 70 tiles made in one frame was the stall the owner saw on opening a slime list (2026-11-04).
		PerFrame = 8,
		PicturesPerFrame = 6,
	},
	-- The dropdown (UiKit.dropdown): its width.
	DropdownWidth = 160,
	-- The team sheets (UiTeams): a team's job in words, the Explore picture, the short words, the small members sheet of a
	-- team's chip (its height, one member's row) and the reasons the team sheets word themselves.
	Team = {
		Jobs = { home = "Home", going = "Marching", fighting = "Fighting", returning = "Coming home" },
		ExploreIcon = "map",
		Explore = "Explore",
		Exploring = "Exploring",
		CallBack = "Call back",
		OutLine = "Change the team at home",
		CardExploreWidth = 170,
		MembersSheetHeight = 428, -- (a full team of four shows without scrolling)
		MemberHeight = 78,
		MemberPortrait = 56,
		Reasons = { TOO_FAR = "Go to your team banner at home" },
	},
}
