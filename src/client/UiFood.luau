--!strict
-- The food tab (the owner, 2026-10-30): one panel listing every food the player owns, raw fish, raw vegetables and
-- cooked dishes in sections, each row with its 3D model picture, name, rarity colour and count. It reads the published
-- Storehouse and Fridge attributes (no remote round trip, so it opens at once) and redraws in place as they change.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
local MODAL = "food"
local SECTION_STEP = 100

type Row = { root: Frame, count: TextLabel, id: string }
type Section = { title: string, ids: { string }, header: TextLabel? }

local UiFood = {}
local rows: { [string]: Row } = {}
local sections: { Section } = {}
local scroller: ScrollingFrame? = nil
local emptyLabel: TextLabel? = nil

local function parse(value: any): { [string]: number }
	if type(value) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(value)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

-- The raw food (storehouse) and the cooked dishes (fridge) a village holds, by item id.
function UiFood.read(own: Instance?): ({ [string]: number }, { [string]: number })
	if not own then
		return {}, {}
	end
	return parse(own:GetAttribute("Storehouse")), parse(own:GetAttribute("Fridge"))
end

-- The model of a food, or nil (the caller then falls back to a picture).
function UiFood.model(id: string): Instance?
	local kit = ReplicatedStorage:FindFirstChild("ClientKit")
	local items = if kit then kit:FindFirstChild("Items") else nil
	return if items then items:FindFirstChild(id) else nil
end

local function displayName(id: string): (string, string, string)
	local kind = (Config.Food.Kinds :: any)[id]
	if kind then
		local rarity = (Config.Food.Rarities :: any)[kind.rarity]
		return kind.name, rarity.name, rarity.colour
	end
	local dish = (Config.Food.Dishes :: any)[id]
	return dish.name, "Dish", U.Colours.BrownSoft
end

local function makeRow(parent: Instance, id: string, order: number): Row
	local height = U.FoodRowHeight
	local root = UiKit.make("Frame", {
		Name = id,
		BackgroundColor3 = UiKit.colour("Card"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -8, 0, height),
		LayoutOrder = order,
		Visible = false,
	}, parent)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0, 10) }, root)
	UiKit.make("UIStroke", { Color = UiKit.colour("Track"), Thickness = 1.5 }, root)
	local model = UiFood.model(id)
	local iconSize = U.FoodIconSize
	local holder = UiKit.make("Frame", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(U.Gap, (height - iconSize) / 2),
		Size = UDim2.fromOffset(iconSize, iconSize),
	}, root)
	if model then
		UiKit.modelIcon(holder, model, iconSize)
	else
		UiKit.icon(holder, "food", iconSize)
	end
	local name, rarityName, colour = displayName(id)
	local textLeft = U.Gap * 2 + iconSize
	UiKit.label(root, name, U.TextNormal, "Brown", {
		Name = "Name",
		Position = UDim2.fromOffset(textLeft, 6),
		Size = UDim2.new(1, -textLeft - U.FoodCountWidth, 0, U.TextNormal + 4),
	})
	UiKit.label(root, rarityName, U.TextSmall, nil, {
		Name = "Rarity",
		TextColor3 = Color3.fromHex(colour),
		Position = UDim2.fromOffset(textLeft, 8 + U.TextNormal),
		Size = UDim2.new(1, -textLeft - U.FoodCountWidth, 0, U.TextSmall + 4),
	})
	local count = UiKit.label(root, "", U.TextHeader, "Brown", {
		Name = "Count",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -U.Pad, 0.5, 0),
		Size = UDim2.fromOffset(U.FoodCountWidth, height),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	return { root = root, count = count, id = id }
end

-- Shows the counts as they are now; a row is made the first time its food is owned.
function UiFood.refresh(own: Instance?)
	local list = scroller
	if not list or UiKit.modalId() ~= MODAL then
		return
	end
	local store, fridge = UiFood.read(own)
	local anything = false
	for index, section in sections do
		local shown = false
		for position, id in section.ids do
			local amount = math.floor((store[id] or fridge[id] or 0) + 0.5)
			local row = rows[id]
			if amount > 0 and not row then
				row = makeRow(list, id, index * SECTION_STEP + position)
				rows[id] = row
			end
			if row then
				row.root.Visible = amount > 0
				row.count.Text = "x" .. tostring(amount)
			end
			shown = shown or amount > 0
		end
		if section.header then
			section.header.Visible = shown
		end
		anything = anything or shown
	end
	if emptyLabel then
		emptyLabel.Visible = not anything
	end
end

function UiFood.isOpen(): boolean
	return UiKit.modalId() == MODAL
end

function UiFood.open(own: Instance?)
	if UiFood.isOpen() then
		UiKit.closeModal()
		return
	end
	local modal = UiKit.openModal(MODAL, {
		Width = U.FoodWidth,
		Height = U.FoodHeight,
		OnClose = function()
			table.clear(rows)
			table.clear(sections)
			scroller, emptyLabel = nil, nil
		end,
	})
	UiKit.label(modal.header, "Food", U.TextHeader, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local list = UiKit.make("ScrollingFrame", {
		Name = "Food",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, modal.content)
	UiKit.make("UIListLayout", {
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	scroller = list
	emptyLabel = UiKit.label(modal.content, "No food yet", U.TextNormal, "BrownSoft", {
		Name = "Empty",
		Position = UDim2.fromOffset(0, U.Gap),
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
	})
	sections = {
		{ title = "Fish", ids = Config.Food.FishOrder },
		{ title = "Vegetables", ids = Config.Food.VegOrder },
		{ title = "Dishes", ids = Config.Food.DishOrder },
	}
	for index, section in sections do
		section.header = UiKit.label(list, section.title, U.TextNormal, "Gold", {
			Name = "Section" .. section.title,
			LayoutOrder = index * SECTION_STEP,
			Visible = false,
		})
	end
	UiFood.refresh(own)
end

return UiFood
