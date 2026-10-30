--!strict
-- What stays on the screen: a small resource strip at the top edge and the round slime-book button at the right edge.
-- The middle stays empty. All food is ONE button (the owner, 2026-10-30): a 3D bowl and the total; tapping it opens the
-- food panel (UiFood). Its picture is the 3D item itself (ClientKit.Items in a ViewportFrame).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
local FOOD_ICON = "veggieStew" -- the Items model on the food button

local UiHud = {}
local strip: ScrollingFrame? = nil
local edge: Frame? = nil
local chips: { [string]: UiKit.Chip } = {}
local lastOwn: Folder? = nil

local function short(amount: number): string
	if amount >= 1_000_000 then
		return string.format("%.1fM", amount / 1_000_000)
	elseif amount >= 100_000 then
		return string.format("%.0fK", amount / 1000)
	end
	return tostring(math.floor(amount))
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

function UiHud.start(root: Frame, onBook: () -> ())
	local bar = UiKit.make("ScrollingFrame", {
		Name = "Resources",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, U.Edge),
		Size = UDim2.new(1, -2 * U.Edge, 0, U.ChipHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Visible = false,
	}, root)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
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
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	}, chips.food.root).Activated
		:Connect(function()
			UiFood.open(lastOwn)
		end)
	add("slimes", "slimes")

	-- Round buttons hug the right edge, clear of the jump button and the thumbstick.
	local group = UiKit.make("Frame", {
		Name = "EdgeButtons",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -U.Edge, 0.5, 0),
		Size = UDim2.fromOffset(U.Touch + 16, U.Touch + 16),
		BackgroundTransparency = 1,
		Visible = false,
	}, root)
	UiKit.roundButton(group, "slimes", U.Touch + 16, onBook)
	edge = group
end

function UiHud.setVisible(visible: boolean)
	if strip then
		strip.Visible = visible
	end
	if edge then
		edge.Visible = visible
	end
end

function UiHud.refresh(own: Folder?)
	lastOwn = own
	if not strip or not own then
		return
	end
	local store, fridge = UiFood.read(own)
	local coins = own:GetAttribute("Coins")
	chips.coins.set(short(if type(coins) == "number" then coins else 0))
	local total = 0
	for _, kind in Config.Food.RawOrder do
		total += store[kind] or 0
	end
	for _, kind in Config.Food.DishOrder do
		total += fridge[kind] or 0
	end
	chips.food.set(short(total))
	UiFood.refresh(own)
	chips.slimes.set(tostring(own:GetAttribute("Population") or 0) .. "/" .. tostring(own:GetAttribute("Limit") or 0))
end

return UiHud
