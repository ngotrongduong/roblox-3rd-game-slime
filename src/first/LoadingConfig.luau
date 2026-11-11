--!strict
-- The loading screen's numbers and words. They live beside the loader in ReplicatedFirst, not in Config: the screen
-- must be up before ReplicatedStorage (and Config with it) has arrived. The look is the original's
-- (docs/reference/03-shell-ui-world.md §3, 04-vfx-animation.md: gooLoadBounce).

return {
	Log = "[GooLineage]", -- (Config.LogPrefix, which has not arrived yet)
	DisplayOrder = 100, -- over every screen of the game (the HUD is 5)
	-- the owner's meadow (reference/goo-lineage-web/assets/scene.loading.png) and the real navy slime
	Backdrop = "rbxassetid://126250512441881",
	Slime = "rbxassetid://120929268236217",
	Title = "Goo Lineage V2",
	Font = "FredokaOne",
	Cream = Color3.fromRGB(255, 246, 224),
	Shade = Color3.fromRGB(46, 74, 36), -- the title's and the texts' dark-green outline
	BarFrom = Color3.fromRGB(255, 215, 94), -- #ffd75e
	BarTo = Color3.fromRGB(240, 138, 36), -- #f08a24
	BarBack = Color3.fromRGB(20, 30, 16),
	BarBackTransparency = 0.55,
	BarEase = 0.2, -- seconds the bar takes to reach a new width
	-- sizes as parts of the screen's height, so a phone and a monitor see the same picture
	TitleHeight = 0.13,
	SlimeHeight = 0.17,
	BarWidth = 0.42, -- of the screen's width
	BarMaxPixels = 420,
	BarHeight = 0.035,
	StatusHeight = 0.045,
	TipHeight = 0.04,
	-- the bounce: 1.1 s, up a quarter of its height at 30% (squeezed 0.94 x 1.06), landing at 60% (1.06 x 0.94)
	BounceSeconds = 1.1,
	BounceUp = 0.25,
	-- tapping the slime: a big hop, and a count of the taps
	BoopSeconds = 0.55,
	BoopUp = 0.9,
	BoopText = "Boing! x%d",
	BoopBeside = 0.16, -- the count's centre, right of the screen's middle (a share of the screen's width)
	TipSeconds = 4,
	Tips = {
		"Tip: happy slimes bounce higher.",
		"Tip: give your slimes jobs at the workstations.",
		"Tip: breeding two colours can reveal a rare Dual.",
		"Tip: a favourite slime can never be sold.",
		"Tip: luck makes Secret slimes more likely.",
		"Tip: upgrade your farm's areas to open new things.",
		"Tip: teams of slimes win gear in the Dungeon.",
		"Tip: come back every day for the check-in gift.",
		"Tip: tap the slime!",
	},
	-- the steps, in order: what the status line says, and where the bar stands when the step is done
	Steps = {
		{ text = "Waking up the pasture...", bar = 0.15 },
		{ text = "Finding your farm...", bar = 0.35 },
		{ text = "Growing the grass...", bar = 0.55 },
		{ text = "Loading pictures... %d/%d", bar = 0.9 },
		{ text = "Settling the slimes...", bar = 1 },
	},
	Ready = "Ready!",
	-- the longest each step may take, so a slow phone or a lost asset never keeps a player out
	FarmSeconds = 30,
	CharacterSeconds = 20,
	StreamSeconds = 10,
	PictureSeconds = 15,
	-- the start's hitches happen behind the screen: it waits for this many frames in a row faster than SteadyFps
	SteadyFrames = 15,
	SteadyFps = 30,
	SettleSeconds = 4,
	-- a Play button for whoever is still waiting after this long
	SkipSeconds = 20,
	SkipText = "Play",
	ReadyHold = 0.3,
	FadeSeconds = 0.4,
}
