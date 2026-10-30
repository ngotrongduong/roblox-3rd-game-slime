--!strict
-- What stays on the screen: a small resource strip at the top edge and the round slime-book button at the right edge.
-- The middle stays empty. Food shows by kind, as the stores keep it (the owner, 2026-10-30): fish, each vegetable,
-- and the cooked dishes together; their pictures are the 3D items themselves (ClientKit.Items in a ViewportFrame).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui

local UiHud = {}
local strip: ScrollingFrame? = nil
local edge: Frame? = nil
local chips: { [string]: UiKit.Chip } = {}
-- each food chip and the kinds it counts (raw kinds from the storehouse, dishes from the fridge)
local FOOD_CHIPS: { { key: string, kinds: { string }, model: string } } = {
	{ key = "fish", kinds = { "fish" }, model = "fish" },
	{ key = "carrot", kinds = { "carrot" }, model = "carrot" },
	{ key = "cabbage", kinds = { "cabbage" }, model = "cabbage" },
	{ key = "dishes", kinds = Config.Food.DishOrder, model = Config.Food.DishOrder[1] },
}

local function parse(value: any): { [string]: number }
	if type(value) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(value)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

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
	for _, food in FOOD_CHIPS do
		local model = item(food.model)
		add(food.key, if model then food.key else "food", model)
	end
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
	if not strip or not own then
		return
	end
	local store = parse(own:GetAttribute("Storehouse"))
	local fridge = parse(own:GetAttribute("Fridge"))
	local coins = own:GetAttribute("Coins")
	chips.coins.set(short(if type(coins) == "number" then coins else 0))
	for _, food in FOOD_CHIPS do
		local total = 0
		for _, kind in food.kinds do
			local source = if (Config.Food.Dishes :: any)[kind] ~= nil then fridge else store
			total += source[kind] or 0
		end
		chips[food.key].set(short(total))
	end
	chips.slimes.set(tostring(own:GetAttribute("Population") or 0) .. "/" .. tostring(own:GetAttribute("Limit") or 0))
end

return UiHud
