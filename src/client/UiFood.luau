--!strict
-- The food tab (the owner, 2026-10-30): one panel listing every food the player owns, raw fish, raw vegetables and
-- cooked dishes in sections, each row with its 3D model picture, name, rarity colour and count. It reads the published
-- Storehouse and Fridge attributes (no remote round trip, so it opens at once) and redraws in place as they change.
-- A dish row is tappable: the dish sheet shows what the dish gives and lists the slimes to feed it to now, or to set to
-- eat it by itself when hungry. The same module draws the small food pictures other screens need (a dish or an
-- ingredient with its count, a missing one crossed out).
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)
local UiSlimeList = require(script.Parent.UiSlimeList)
local UiSlimes = require(script.Parent.UiSlimes)

local U = Config.Ui
local MODAL = "food"
local DISH_MODAL = "dish"
local SECTION_STEP = 100
local FACTS_WIDTH = 64

type Row = { root: Frame, count: TextLabel, id: string }
type Section = { title: string, ids: { string }, header: TextLabel? }
export type Need = { id: string, need: number }

local reasons: { [string]: string } = {
	NO_DISH = "None left.",
	UNKNOWN_DISH = "Not available.",
	DEAD = "Fallen.",
	OUT = "Out fighting.",
	NO_SLIME = "Slime not found.",
	RATE_LIMIT = "One moment.",
	NOT_READY = "Village is loading.",
}

local UiFood = {}
local rows: { [string]: Row } = {}
local sections: { Section } = {}
local scroller: ScrollingFrame? = nil
local emptyLabel: TextLabel? = nil
local ownRef: Instance? = nil
local dishRefresh: (() -> ())? = nil
local openDishSheet: (own: Instance?, id: string) -> () = function() end

local function parse(value: any): { [string]: number }
	if type(value) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(value)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

local function ask(data: { [string]: any }): (boolean, string?)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = if remotes then remotes:FindFirstChild("Village") else nil
	if not remote or not remote:IsA("RemoteFunction") then
		return false, "NOT_READY"
	end
	local ok, answer = pcall(function()
		return remote:InvokeServer(data)
	end)
	if ok and type(answer) == "table" then
		return answer.ok == true, answer.reason
	end
	return false, "SERVER_ERROR"
end

-- The raw food (storehouse) and the cooked dishes (fridge) a village holds, by item id.
function UiFood.read(own: Instance?): ({ [string]: number }, { [string]: number })
	if not own then
		return {}, {}
	end
	return parse(own:GetAttribute("Storehouse")), parse(own:GetAttribute("Fridge"))
end

-- What a cook can reach: the storehouse and the kitchen counter together.
function UiFood.have(own: Instance?): { [string]: number }
	local have: { [string]: number } = {}
	if not own then
		return have
	end
	for _, attribute in { "Storehouse", "Counter" } do
		for id, amount in parse(own:GetAttribute(attribute)) do
			have[id] = (have[id] or 0) + amount
		end
	end
	return have
end

-- The model of a food, or nil (the caller then falls back to a picture).
function UiFood.model(id: string): Instance?
	local kit = ReplicatedStorage:FindFirstChild("ClientKit")
	local items = if kit then kit:FindFirstChild("Items") else nil
	return if items then items:FindFirstChild(id) else nil
end

-- A food's picture: its 3D model, or the owner's food sack while that model does not exist.
function UiFood.icon(parent: Instance?, id: string, size: number, props: UiKit.Props?): GuiObject
	local model = UiFood.model(id)
	if model then
		return UiKit.modelIcon(parent, model, size, props)
	end
	return UiKit.icon(parent, "food", size, props)
end

-- Name, rarity name and rarity colour (hex) of a raw food or a dish.
function UiFood.describe(id: string): (string, string, string)
	local kind = (Config.Food.Kinds :: any)[id]
	if kind then
		local rarity = (Config.Food.Rarities :: any)[kind.rarity]
		return kind.name, rarity.name, rarity.colour
	end
	local dish = (Config.Food.Dishes :: any)[id]
	local rarity = (Config.Food.Rarities :: any)[dish.rarity]
	return dish.name, rarity.name, rarity.colour
end

-- What a dish gives: the stat icon name, the percent and the minutes the buff lasts.
function UiFood.facts(id: string): (string, number, number)
	local dish = (Config.Food.Dishes :: any)[id]
	local rarity = (Config.Food.DishRarities :: any)[dish.rarity]
	return dish.stat, rarity.percent, math.floor(rarity.buffSeconds / 60 + 0.5)
end

-- The ingredients of a dish in the order of the raw food list.
function UiFood.ingredients(dishId: string): { Need }
	local list: { Need } = {}
	local dish = (Config.Food.Dishes :: any)[dishId]
	if dish then
		for _, id in Config.Food.RawOrder do
			local need = dish.ingredients[id]
			if need then
				table.insert(list, { id = id, need = need })
			end
		end
	end
	return list
end

-- The ingredients of a dish that the storehouse and the counter cannot cover (ids, in list order).
function UiFood.missing(dishId: string, have: { [string]: number }): { string }
	local out: { string } = {}
	for _, item in UiFood.ingredients(dishId) do
		if (have[item.id] or 0) < item.need then
			table.insert(out, item.id)
		end
	end
	return out
end

-- An ingredient's picture; a missing one carries the owner's cross in its corner.
function UiFood.ingredientIcon(
	parent: Instance?,
	id: string,
	size: number,
	lacking: boolean,
	props: UiKit.Props?
): Frame
	local holder = UiKit.make("Frame", {
		Name = id,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
	}, parent)
	if props then
		for key, value in props do
			holder[key] = value
		end
	end
	UiFood.icon(holder, id, size)
	if lacking then
		UiKit.icon(holder, "cross", math.floor(size * 0.65), {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1, 1),
			ZIndex = 5,
		})
	end
	return holder
end

-- A dish's ingredients as pictures with the count each needs. With `have` given, a lacking one is crossed and red.
function UiFood.ingredientStrip(
	parent: Instance?,
	dishId: string,
	have: { [string]: number }?,
	size: number,
	props: UiKit.Props?
): Frame
	local strip = UiKit.make("Frame", {
		Name = "Ingredients",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, size),
		AutomaticSize = Enum.AutomaticSize.X,
	}, parent)
	if props then
		for key, value in props do
			strip[key] = value
		end
	end
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, strip)
	for index, item in UiFood.ingredients(dishId) do
		local lacking = have ~= nil and (have[item.id] or 0) < item.need
		local cell = UiKit.make("Frame", {
			Name = item.id,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, size),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = index,
		}, strip)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, cell)
		UiFood.ingredientIcon(cell, item.id, size, lacking, { LayoutOrder = 1 })
		UiKit.label(cell, tostring(item.need), U.TextSmall, if lacking then "Red" else "Brown", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	return strip
end

-- The stat icon and the percent a dish gives, in one small row.
function UiFood.factsRow(parent: Instance?, id: string, props: UiKit.Props?): Frame
	local stat, percent = UiFood.facts(id)
	local row = UiKit.make("Frame", {
		Name = "Facts",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(FACTS_WIDTH, U.IconNormal),
	}, parent)
	if props then
		for key, value in props do
			row[key] = value
		end
	end
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	UiKit.icon(row, stat, U.IconSmall, { LayoutOrder = 1 })
	UiKit.label(row, "+" .. tostring(percent) .. "%", U.TextSmall, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	return row
end

local function makeRow(parent: Instance, id: string, order: number): Row
	local height = U.FoodRowHeight
	local isDish = (Config.Food.Dishes :: any)[id] ~= nil
	local right = U.FoodCountWidth + (if isDish then FACTS_WIDTH else 0)
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
	local iconSize = U.FoodIconSize
	local holder = UiKit.make("Frame", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(U.Gap, (height - iconSize) / 2),
		Size = UDim2.fromOffset(iconSize, iconSize),
	}, root)
	UiFood.icon(holder, id, iconSize)
	local name, rarityName, colour = UiFood.describe(id)
	local textLeft = U.Gap * 2 + iconSize
	UiKit.label(root, name, U.TextNormal, "Brown", {
		Name = "Name",
		Position = UDim2.fromOffset(textLeft, 6),
		Size = UDim2.new(1, -textLeft - right, 0, U.TextNormal + 4),
	})
	UiKit.label(root, rarityName, U.TextSmall, nil, {
		Name = "Rarity",
		TextColor3 = Color3.fromHex(colour),
		Position = UDim2.fromOffset(textLeft, 8 + U.TextNormal),
		Size = UDim2.new(1, -textLeft - right, 0, U.TextSmall + 4),
	})
	local count = UiKit.label(root, "", U.TextHeader, "Brown", {
		Name = "Count",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -U.Pad, 0.5, 0),
		Size = UDim2.fromOffset(U.FoodCountWidth, height),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	if isDish then
		UiFood.factsRow(root, id, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -U.Pad - U.FoodCountWidth, 0.5, 0),
		})
		-- the whole row is the button that opens the dish sheet
		UiKit.make("TextButton", {
			Name = "Open",
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
		}, root).Activated
			:Connect(function()
				openDishSheet(ownRef, id)
			end)
	end
	return { root = root, count = count, id = id }
end

-- Shows the counts as they are now; a row is made the first time its food is owned.
function UiFood.refresh(own: Instance?)
	ownRef = own
	if dishRefresh and UiKit.modalId() == DISH_MODAL then
		dishRefresh()
		return
	end
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
	ownRef = own
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

-- ===== The dish sheet =====

-- Called when a slime's AutoDish changes: redraws the open dish sheet in place.
function UiFood.refreshDish()
	if dishRefresh and UiKit.modalId() == DISH_MODAL then
		dishRefresh()
	end
end

function UiFood.openDish(own: Instance?, id: string)
	openDishSheet(own, id)
end

openDishSheet = function(own: Instance?, id: string)
	ownRef = own
	local name, rarityName, colour = UiFood.describe(id)
	local stat, percent, minutes = UiFood.facts(id)
	local selected: string? = nil
	local busy = false
	local refresh: () -> () = function() end
	local modal = UiKit.openModal(DISH_MODAL, {
		Width = U.SheetWidth,
		Height = U.SheetHeight,
		Bottom = true,
		Dim = 0.8,
		OnClose = function()
			UiSlimes.releaseAll()
			dishRefresh = nil
		end,
	})
	-- header: back to the food list, the dish's picture, its name over its rarity
	UiKit.button(modal.header, {
		Name = "Back",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		OnClick = function()
			UiFood.open(ownRef)
		end,
	})
	local picture = U.Touch - 8
	UiFood.icon(modal.header, id, picture, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, U.Touch + U.Gap, 0.5, 0),
	})
	local textLeft = U.Touch + U.Gap * 2 + picture
	UiKit.label(modal.header, name, U.TextNormal, "Brown", {
		Position = UDim2.fromOffset(textLeft, 2),
		Size = UDim2.new(1, -textLeft, 0, U.TextNormal + 4),
	})
	UiKit.label(modal.header, rarityName, U.TextSmall, nil, {
		TextColor3 = Color3.fromHex(colour),
		Position = UDim2.fromOffset(textLeft, 4 + U.TextNormal),
		Size = UDim2.new(1, -textLeft, 0, U.TextSmall + 4),
	})

	-- what the dish gives: the stat, the percent, the minutes, and how many are held
	local infoHeight = U.IconNormal + 4
	local info = UiKit.make("Frame", {
		Name = "Info",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, infoHeight),
	}, modal.content)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, info)
	UiKit.icon(info, stat, U.IconNormal, { LayoutOrder = 1 })
	UiKit.label(info, "+" .. tostring(percent) .. "%", U.TextNormal, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	UiKit.label(info, tostring(minutes) .. " min", U.TextNormal, "BrownSoft", {
		LayoutOrder = 3,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	local held = UiKit.label(modal.content, "", U.TextHeader, "Brown", {
		Name = "Held",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(U.FoodCountWidth + 20, infoHeight),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local host = UiKit.make("Frame", {
		Name = "Slimes",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, infoHeight + U.Gap),
		Size = UDim2.new(1, 0, 1, -infoHeight - U.Gap),
	}, modal.content)
	local list = UiSlimeList.new(host, {
		entries = function()
			local entries: { UiSlimeList.Entry } = {}
			for _, slime in UiSlimes.slimes(ownRef) do
				if not UiSlimes.isGhost(slime) then
					local auto = slime:GetAttribute("AutoDish")
					local mark: UiSlimeList.Mark? = nil
					if auto == id then
						mark = { text = "Auto", colour = "Green" }
					elseif type(auto) == "string" and auto ~= "" then
						mark = { text = "Auto" }
					else
						mark = UiSlimeList.stateMark(slime)
					end
					table.insert(entries, { slime = slime, selected = slime.Name == selected, mark = mark })
				end
			end
			return entries
		end,
		onTap = function(slime)
			selected = slime.Name
			refresh()
		end,
	})
	list.root.Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap)
	local bar = UiKit.make("Frame", {
		Name = "Bar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, U.Touch),
		Visible = false,
	}, host)
	local feed = UiKit.button(bar, {
		Name = "Feed",
		Text = "Feed",
		Style = "good",
		Size = UDim2.fromOffset(110, U.Touch),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		OnClick = function()
			local slimeId = selected
			if not slimeId or busy then
				return
			end
			busy = true
			refresh()
			task.spawn(function()
				local ok, why = ask({ action = "FeedDish", slimeId = slimeId, dish = id })
				busy = false
				if not ok then
					UiKit.toast(if why and reasons[why] then reasons[why] else "Please try again.")
				end
				refresh()
			end)
		end,
	})
	local auto = UiKit.button(bar, {
		Name = "WhenHungry",
		Text = "When hungry",
		Style = "secondary",
		Size = UDim2.fromOffset(150, U.Touch),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -110 - U.Gap, 0, 0),
		OnClick = function()
			local slimeId = selected
			if not slimeId or busy then
				return
			end
			local slime: Configuration? = nil
			for _, other in UiSlimes.slimes(ownRef) do
				if other.Name == slimeId then
					slime = other
				end
			end
			-- pressing it again on the dish already chosen clears it
			local clearing = slime ~= nil and slime:GetAttribute("AutoDish") == id
			busy = true
			task.spawn(function()
				local ok, why = ask({ action = "SetAutoDish", slimeId = slimeId, dish = if clearing then nil else id })
				busy = false
				if not ok then
					UiKit.toast(if why and reasons[why] then reasons[why] else "Please try again.")
				end
				refresh()
			end)
		end,
	})

	refresh = function()
		local _, fridge = UiFood.read(ownRef)
		local count = math.floor((fridge[id] or 0) + 0.5)
		held.Text = "x" .. tostring(count)
		local chosen: Configuration? = nil
		for _, slime in UiSlimes.slimes(ownRef) do
			if slime.Name == selected and not UiSlimes.isGhost(slime) then
				chosen = slime
			end
		end
		if chosen then
			bar.Visible = true
			-- the server refuses a slime out fighting or a dish none is left of: grey, not hidden logic
			UiKit.setEnabled(feed, count > 0 and chosen:GetAttribute("OutOnSquad") ~= true and not busy)
			UiKit.setEnabled(auto, not busy)
			UiKit.setStyle(auto, if chosen:GetAttribute("AutoDish") == id then "primary" else "secondary")
		else
			selected = nil
			bar.Visible = false
		end
		list.refresh()
	end
	dishRefresh = refresh
	refresh()
end

return UiFood
