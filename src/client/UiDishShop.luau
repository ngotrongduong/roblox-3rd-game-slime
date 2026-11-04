--!strict
-- The Dishes tab of the Market's sell sheet: every dish the fridge holds, with its picture, how many there are and the price
-- of one, and two buttons: sell one, sell all. The price comes from the dish's rarity (Config.Food.DishRarities); the server
-- checks the range and the count and pays. The sheet (UiSquad) calls `tick` while it is open.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FoodRules = require(ReplicatedStorage.Shared.Food)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui

export type Context = {
	own: () -> Instance?,
	ask: (data: { [string]: any }) -> (boolean, string?, number?),
	reason: (why: any) -> string,
}
export type Shop = { root: Frame, tick: () -> () }

type Row = { root: Frame, count: TextLabel, held: number }

local UiDishShop = {}

local BUTTON_GAP = 6
-- the pill buttons are wide enough for their word to clear the round ends
local ONE_WIDTH = U.Touch + 12
local ALL_WIDTH = U.Touch + 24

local function priceOf(id: string): number
	local dish = (Config.Food.Dishes :: any)[id]
	return (Config.Food.DishRarities :: any)[dish.rarity].price
end

function UiDishShop.new(parent: Instance, context: Context): Shop
	local root = UiKit.make("Frame", {
		Name = "Dishes",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
	}, parent)
	local scroller = UiKit.make("ScrollingFrame", {
		Name = "Rows",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, root)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, scroller)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroller)
	-- nothing to sell: the owner's food sack, faint
	local empty = UiKit.icon(root, "food", 64, {
		Name = "Empty",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 40),
		Visible = false,
	})
	if empty:IsA("ImageLabel") then
		empty.ImageTransparency = 0.6
	end

	local rows: { [string]: Row } = {}
	local selling = false

	local function sell(id: string, count: number)
		if selling or count < 1 then
			return
		end
		selling = true
		task.spawn(function()
			local ok, why, paid = context.ask({ action = "SellDish", dish = id, count = count })
			selling = false
			if ok then
				UiKit.toast("+" .. UiKit.money(paid or 0))
			else
				UiKit.toast(context.reason(why))
			end
		end)
	end

	local function makeRow(id: string, order: number): Row
		local height = U.Touch + 8
		local card = UiKit.make("Frame", {
			Name = id,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			LayoutOrder = order,
		}, scroller)
		UiKit.rowBack(card)
		local icon = U.FoodIconSize
		UiFood.icon(card, id, icon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, U.Gap + 4, 0.5, 0),
		})
		local textLeft = U.Gap * 2 + 4 + icon
		local buttons = ONE_WIDTH + ALL_WIDTH + BUTTON_GAP + U.Gap
		local name = UiFood.describe(id)
		UiKit.label(card, name, U.TextSmall, "Brown", {
			Position = UDim2.fromOffset(textLeft, 5),
			Size = UDim2.new(1, -textLeft - buttons, 0, U.TextSmall + 4),
		})
		-- one price, then how many: a picture and short numbers
		local line = UiKit.make("Frame", {
			Name = "Line",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(textLeft, 8 + U.TextSmall),
			Size = UDim2.new(1, -textLeft - buttons, 0, U.IconSmall + 2),
		}, card)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, line)
		UiKit.icon(line, "coins", U.IconSmall, { LayoutOrder = 1 })
		UiKit.label(line, UiKit.money(priceOf(id)), U.TextSmall, "Brown", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
		})
		local count = UiKit.label(line, "", U.TextSmall, "BrownSoft", {
			LayoutOrder = 3,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
		})
		local row: Row = { root = card, count = count, held = 0 }
		UiKit.button(card, {
			Name = "SellOne",
			Text = "1",
			TextSize = U.TextNormal,
			Style = "good",
			Size = UDim2.fromOffset(ONE_WIDTH, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -U.Gap - ALL_WIDTH - BUTTON_GAP, 0.5, 0),
			OnClick = function()
				sell(id, 1)
			end,
		})
		UiKit.button(card, {
			Name = "SellAll",
			Text = "All",
			Style = "good",
			Size = UDim2.fromOffset(ALL_WIDTH, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -U.Gap, 0.5, 0),
			OnClick = function()
				-- (the server takes at most what the fridge of the highest level could hold in one go)
				sell(id, math.min(row.held, FoodRules.fridgeCapacity(Config.Village.MaxLevel)))
			end,
		})
		return row
	end

	local function tick()
		local _, fridge = UiFood.read(context.own())
		local any = false
		for order, id in Config.Food.DishOrder do
			local held = math.floor((fridge[id] or 0) + 0.5)
			local row = rows[id]
			if held > 0 and not row then
				row = makeRow(id, order)
				rows[id] = row
			end
			if row then
				row.held = held
				row.root.Visible = held > 0
				row.count.Text = "x" .. tostring(held)
			end
			any = any or held > 0
		end
		empty.Visible = not any
	end

	return { root = root, tick = tick }
end

return UiDishShop
