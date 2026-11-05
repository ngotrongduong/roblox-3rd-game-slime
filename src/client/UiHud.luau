--!strict
-- What stays on the screen: a small resource strip at the top edge and the round buttons at the right edge (the slime book,
-- and quick travel to the Market and Home).
-- The middle stays empty. All food is ONE button (the owner, 2026-10-30): a 3D bowl and the total; tapping it opens the
-- food panel (UiFood). Its picture is the 3D item itself (ClientKit.Items in a ViewportFrame).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
local FOOD_ICON = "veggieStew" -- the Items model on the food button

local UiHud = {}
local strip: ScrollingFrame? = nil
local edge: Frame? = nil
local villageLabel: TextLabel? = nil
local villageFill: Frame? = nil
local chips: { [string]: UiKit.Chip } = {}
local lastOwn: Folder? = nil
local rewardsButton: ImageButton? = nil
local bagButton: ImageButton? = nil
local arenaButton: ImageButton? = nil
local badge: TextLabel? = nil
-- Whether the coins were at the cap at the last look; nil until the vault's cap is known.
local coinsFull: boolean? = nil
-- Whether a Slime Dungeon run is on (the village's edge buttons stay put away).
local inArena = false

-- 2,000 up to 99,999 in full with commas, then 120K and 1.2M, so "amount/cap" stays short in a phone's strip.
local function short(amount: number): string
	if amount >= 1_000_000 then
		return string.format("%.1fM", amount / 1_000_000)
	elseif amount >= 100_000 then
		return string.format("%.0fK", amount / 1000)
	end
	return UiKit.money(amount)
end

-- Colours the number of a chip: red when what it holds has reached its cap.
local function paint(chip: UiKit.Chip, full: boolean)
	local value = chip.root:FindFirstChild("Value", true)
	if value and value:IsA("TextLabel") then
		value.TextColor3 = UiKit.colour(if full then "Red" else "Brown")
	end
end

local function item(name: string): Instance?
	local kit = ReplicatedStorage:FindFirstChild("ClientKit")
	local items = if kit then kit:FindFirstChild("Items") else nil
	local found = if items then items:FindFirstChild(name) else nil
	if not found then
		warn(Config.LogPrefix, "missing ClientKit/Items/" .. name .. " (resource strip)")
	end
	return found
end

function UiHud.start(
	root: Frame,
	onBook: () -> (),
	onTravel: (place: string) -> (),
	onRewards: () -> (),
	onBag: () -> (),
	onArena: () -> ()
)
	-- The strip shares the line of Roblox's own buttons: its own ScreenGui in the free space the engine leaves in the topbar.
	local host = root:FindFirstAncestorOfClass("ScreenGui") :: ScreenGui
	local top = UiKit.make("ScreenGui", {
		Name = "GooTopStrip",
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets,
		DisplayOrder = host.DisplayOrder,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, host.Parent)
	local bar = UiKit.make("ScrollingFrame", {
		Name = "Resources",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Visible = false,
	}, top)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, bar)
	strip = bar
	local order = 0
	local function add(key: string, icon: string, model: Instance?)
		order += 1
		chips[key] = UiKit.chip(bar, icon, "0", order, model)
	end
	add("coins", "coins")
	add("food", "food", item(FOOD_ICON))
	-- the whole food chip is a button: a transparent press area over it
	UiKit.make("TextButton", {
		Name = "Open",
		BackgroundTransparency = 1,
		Text = "",
		-- (taller than the plate: a touch target is never below U.Touch)
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, U.Touch),
		ZIndex = 20,
	}, chips.food.root).Activated
		:Connect(function()
			UiFood.open(lastOwn)
		end)
	add("slimes", "slimes")

	-- Round buttons hug the right edge above the jump button: Market and Home (quick travel) over the slime book, in one
	-- column, so the view stays open on a short phone screen.
	local group = UiKit.make("Frame", {
		Name = "EdgeButtons",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -U.Edge, 0.5, 0),
		Size = UDim2.fromOffset(U.BookButton, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
	}, root)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, group)
	local market = UiKit.roundButton(group, "market", U.TravelButton, function()
		onTravel("Market")
	end, { LayoutOrder = 1 })
	-- The Arena (UiArena, handed in as onArena: UiArena reaches UiHud through UiDungeon, so UiHud cannot require it) sits in
	-- the Market's row, just left of it (a child of the Market button, so the column stays as tall as it was). It opens the
	-- screen; the fight is shown on the Arena scene (ArenaStage). Shown with the trophy, once the tutorial is over.
	arenaButton = UiKit.roundButton(market, "arena", U.TravelButton, onArena, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0, -U.Gap, 0.5, 0),
		Visible = false,
	})
	UiKit.roundButton(group, "home", U.TravelButton, function()
		onTravel("Home")
	end, { LayoutOrder = 2 })
	-- The trophy: the daily check-in, quests and online gifts (UiRewards), with a red count while something waits. Shown once
	-- the tutorial is over.
	local trophy = UiKit.roundButton(group, "rewards", U.BookButton, onRewards, { LayoutOrder = 3, Visible = false })
	local dot = UiKit.make("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(Config.Rewards.BadgeSize, Config.Rewards.BadgeSize),
		BackgroundColor3 = UiKit.colour("Red"),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
	}, trophy)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
	UiKit.make("UIStroke", { Color = UiKit.colour("Cream"), Thickness = 2 }, dot)
	badge = UiKit.label(dot, "", U.TextTiny, "Cream", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
	})
	rewardsButton = trophy
	local book = UiKit.roundButton(group, "slimes", U.BookButton, onBook, { LayoutOrder = 4 })
	-- The bag (UiBag) sits in the book's row, just left of it (a child of the book button, so the column stays as tall as it
	-- was and the tutorial's pointer still finds the book). Shown with the trophy, once the tutorial is over.
	bagButton = UiKit.roundButton(book, "bag", U.Bag.Button, onBag, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0, -U.Gap, 0.5, 0),
		Visible = false,
	})
	edge = group
	-- The owner's debug menu button: Studio only. Found by name and not required at the top, because the publish build removes
	-- the module (tools/build_publish.luau) and the published game must start without it.
	if RunService:IsStudio() then
		local debugUi = script.Parent:FindFirstChild("UiDebug")
		if debugUi and debugUi:IsA("ModuleScript") then
			(require(debugUi) :: any).attach(group)
		end
	end

	-- Last in the strip: the village's level over a bar of the upgrades done towards the next one.
	local _, body = UiKit.skin(bar, "Wood", "Card", {
		Name = "VillageBar",
		LayoutOrder = order + 1,
		Size = UDim2.fromOffset(U.VillageBarWidth, U.ChipHeight),
	})
	local track = UiKit.make("Frame", {
		Name = "Track",
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	}, body)
	villageFill = UiKit.make("Frame", {
		Name = "Fill",
		BackgroundColor3 = UiKit.colour("GoldLight"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 2,
	}, track) :: Frame
	villageLabel = UiKit.label(body, "", U.TextTiny, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	})
	-- The luck potion's time left, only while one runs.
	chips.luck = UiKit.chip(bar, "luck", "", order + 2)
	chips.luck.root.Visible = false
end

-- The trophy button and the luck chip, from the village folder (called every second): the trophy shows once the tutorial is
-- over, its badge counts the rewards that wait; the chip counts the luck potion down.
function UiHud.rewards(own: Folder?)
	local button, label = rewardsButton, badge
	if not (button and label and own) then
		return
	end
	button.Visible = own:GetAttribute("RewardsOpen") == true
	if bagButton then
		bagButton.Visible = button.Visible
	end
	if arenaButton then
		arenaButton.Visible = button.Visible
	end
	local ready = own:GetAttribute("RewardsReady")
	local count = if type(ready) == "number" then ready else 0
	local dot = label.Parent :: GuiObject
	dot.Visible = count > 0
	label.Text = if count > 9 then "9+" else tostring(count)
	local luck = chips.luck
	local untilTime = own:GetAttribute("LuckUntil")
	local left = if type(untilTime) == "number" then untilTime - workspace:GetServerTimeNow() else 0
	if luck then
		luck.root.Visible = left > 0
		if left > 0 then
			local seconds = math.floor(left)
			luck.set(string.format("x%d %d:%02d", Config.Luck.Potion, seconds // 60, seconds % 60))
		end
	end
end

function UiHud.setVisible(visible: boolean)
	if strip then
		strip.Visible = visible
	end
	if edge then
		edge.Visible = visible and not inArena
	end
end

-- Inside the Slime Dungeon the village's round buttons, team chips and notices have nothing to do: they are put away for the
-- run (the resource strip stays; the drops are coins and food too). The dead chip is put away by UiSquad itself.
function UiHud.setArena(on: boolean)
	inArena = on
	if edge then
		edge.Visible = not on and (strip ~= nil and strip.Visible)
	end
	local root = if edge then edge.Parent else nil
	for _, name in { "TeamChips", "Notices" } do
		local found = if root then root:FindFirstChild(name) else nil
		if found and found:IsA("GuiObject") then
			found.Visible = not on
		end
	end
end

function UiHud.refresh(own: Folder?)
	if own ~= lastOwn then
		-- a new village: the first look at its vault is silent
		coinsFull = nil
	end
	lastOwn = own
	if not strip or not own then
		return
	end
	local store = UiFood.read(own)
	local coins = own:GetAttribute("Coins")
	local amount = if type(coins) == "number" then coins else 0
	-- The coins over what the vault holds ("100/2,000"; sales and gifts may go above it): the number turns red at the cap,
	-- and one toast the moment it fills.
	local cap = own:GetAttribute("CoinCap")
	chips.coins.set(if type(cap) == "number" then short(amount) .. "/" .. short(cap) else short(amount))
	local full = type(cap) == "number" and amount >= cap
	paint(chips.coins, full)
	if type(cap) == "number" then
		if coinsFull == false and full then
			UiKit.toast("Vault full")
		end
		coinsFull = full
	end
	-- The food in the storehouse over what it holds ("24/50"), so upgrading the pantry is felt; red when it is full. (The
	-- dishes in the fridge have a room of their own and are not counted here.)
	local total = 0
	for _, kind in Config.Food.RawOrder do
		total += store[kind] or 0
	end
	local room = own:GetAttribute("StorehouseCap")
	chips.food.set(if type(room) == "number" then short(total) .. "/" .. short(room) else short(total))
	paint(chips.food, type(room) == "number" and total >= room)
	UiFood.refresh(own)
	chips.slimes.set(tostring(own:GetAttribute("Population") or 0) .. "/" .. tostring(own:GetAttribute("Limit") or 0))

	local level = own:GetAttribute("VillageLevel")
	local done = own:GetAttribute("VillageUpgrades")
	if villageLabel and villageFill and type(level) == "number" and type(done) == "number" then
		local count = #Config.Village.Areas
		villageLabel.Text = "Village " .. level .. (if level >= Config.Village.MaxLevel then " MAX" else "")
		-- (a new level starts the bar again: it falls back at once, only a fill slides)
		local goal = UDim2.fromScale(done / count, 1)
		if goal.X.Scale < villageFill.Size.X.Scale then
			villageFill.Size = goal
		else
			UiKit.tween(villageFill, U.VillageBarFillSeconds, { Size = goal })
		end
	end
end

return UiHud
