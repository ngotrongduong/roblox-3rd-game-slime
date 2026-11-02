--!strict
-- The recipe picker of a kitchen position (the owner: tell the cook what to make). A bar shows the chosen dish with its
-- ingredients as pictures, a lacking one crossed out and red (counted from the storehouse plus the counter), and the list
-- below it holds every dish: locked ones are veiled with the kitchen level they need. Pure drawing: the server refuses what
-- it refuses; the caller sends SetCookRecipe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FoodRules = require(ReplicatedStorage.Shared.Food)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
local FACTS_WIDTH = 64

export type Options = {
	own: () -> Instance?,
	-- the kitchen's level
	level: () -> number,
	-- the recipe now chosen for the position
	current: () -> string,
	choose: (id: string) -> (),
}
export type Bar = { root: Frame, refresh: () -> () }
export type List = { root: ScrollingFrame, refresh: () -> (), destroy: () -> () }

type Row = {
	root: TextButton,
	veil: Frame,
	level: TextLabel,
	strip: Frame?,
	key: string,
}

local UiRecipes = {}

local function neededLevel(id: string): number
	local dish = (Config.Food.Dishes :: any)[id]
	return (Config.Food.DishRarities :: any)[dish.rarity].kitchenLevel
end

-- The chosen dish over its ingredients; tapping it runs `onTap` (opens the list).
function UiRecipes.bar(parent: Instance, options: Options, onTap: () -> ()): Bar
	local box, body = UiKit.card(parent, { Name = "RecipeBar", Size = UDim2.new(1, 0, 0, U.RecipeBarHeight) })
	local key = ""
	local function refresh()
		local recipe = options.current()
		local have = UiFood.have(options.own())
		local lacking = UiFood.missing(recipe, have)
		local next = recipe .. "|" .. table.concat(lacking, ",")
		if next == key then
			return
		end
		key = next
		UiKit.clear(body)
		local size = U.RecipeBarHeight - 14
		UiFood.icon(body, recipe, size, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) })
		UiFood.ingredientStrip(body, recipe, have, U.IngredientIcon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, size + U.Gap, 0.5, 0),
		})
		UiFood.factsRow(body, recipe, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5) })
	end
	UiKit.make("TextButton", {
		Name = "Change",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
	}, box).Activated
		:Connect(onTap)
	refresh()
	return { root = box, refresh = refresh }
end

-- Every dish, in the order of Config.Food.DishOrder, in a scrolling list.
function UiRecipes.list(parent: Instance, options: Options): List
	local scroller = UiKit.make("ScrollingFrame", {
		Name = "Recipes",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent) :: ScrollingFrame
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, scroller)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroller)

	local rows: { [string]: Row } = {}
	for order, id in Config.Food.DishOrder do
		local name, _, colour = UiFood.describe(id)
		local root = UiKit.make("TextButton", {
			Name = id,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = UiKit.colour("Card"),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, U.RecipeRowHeight),
			LayoutOrder = order,
		}, scroller)
		UiKit.make("UICorner", { CornerRadius = UDim.new(0, 10) }, root)
		-- the rarity is the colour of the frame
		UiKit.make("UIStroke", { Color = Color3.fromHex(colour), Thickness = 2 }, root)
		local icon = U.RecipeIcon
		UiFood.icon(root, id, icon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, U.Gap, 0.5, 0),
		})
		local textLeft = U.Gap * 2 + icon
		UiKit.label(root, name, U.TextSmall, "Brown", {
			Position = UDim2.fromOffset(textLeft, 4),
			Size = UDim2.new(1, -textLeft - FACTS_WIDTH - U.Pad, 0, U.TextSmall + 4),
		})
		UiFood.factsRow(root, id, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -U.Pad, 0, 6),
		})
		local level = UiKit.label(root, "Lv " .. tostring(neededLevel(id)), U.TextSmall, "Red", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -U.Pad, 0, 8 + U.IconNormal),
			Size = UDim2.fromOffset(FACTS_WIDTH, U.TextSmall + 4),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 7,
			Visible = false,
		})
		local veil = UiKit.make("Frame", {
			Name = "Veil",
			BackgroundColor3 = UiKit.colour("Parchment"),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 6,
			Visible = false,
		}, root)
		UiKit.make("UICorner", { CornerRadius = UDim.new(0, 10) }, veil)
		root.Activated:Connect(function()
			if FoodRules.recipeUnlocked(id, options.level()) then
				options.choose(id)
			else
				UiKit.toast("Kitchen Lv " .. tostring(neededLevel(id)))
			end
		end)
		rows[id] = { root = root, veil = veil, level = level, strip = nil, key = "" }
	end

	local function refresh()
		local level = options.level()
		local have = UiFood.have(options.own())
		local current = options.current()
		for id, row in rows do
			local locked = not FoodRules.recipeUnlocked(id, level)
			local lacking = if locked then {} else UiFood.missing(id, have)
			local key = table.concat({ tostring(locked), tostring(id == current), table.concat(lacking, ",") }, "|")
			if key ~= row.key then
				row.key = key
				row.veil.Visible = locked
				row.level.Visible = locked
				row.root.BackgroundColor3 = UiKit.colour(if id == current then "Portrait" else "Card")
				if row.strip then
					row.strip:Destroy()
				end
				row.strip = UiFood.ingredientStrip(row.root, id, if locked then nil else have, U.IngredientIcon, {
					Position = UDim2.fromOffset(U.Gap * 2 + U.RecipeIcon, 8 + U.TextSmall),
				})
			end
		end
	end
	refresh()
	return {
		root = scroller,
		refresh = refresh,
		destroy = function()
			scroller:Destroy()
		end,
	}
end

return UiRecipes
