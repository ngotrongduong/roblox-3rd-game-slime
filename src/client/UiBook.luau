--!strict
-- The slime book: every slime of the player's own village as a card, with sort and filter, and a detail page.
-- Opened by the round edge button. Reads published attributes; asks the server through ctx.request.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)

local U = Config.Ui

export type Context = {
	own: () -> Folder?,
	request: (data: { [string]: any }, onSuccess: () -> ()) -> (),
}

local UiBook = {}
local ctx: Context? = nil
local sort = U.BookSorts[1]
local filter = U.BookFilters[1]
local detail: string? = nil
local view: UiSlimes.View? = nil
local detailCard: UiSlimes.Card? = nil
local countLabel: TextLabel? = nil
local content: Frame? = nil
local header: Frame? = nil
local firstSeen: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local seen = 0

local sortLabels: { [string]: { text: string?, icon: string? } } = {
	level = { text = "Lv" },
	speed = { icon = "speed" },
	newest = { text = "New" },
}
local filterLabels: { [string]: string } = { all = "All", free = "Free", working = "Work", babies = "Baby" }

local function passes(slime: Configuration): boolean
	if filter == "free" then
		return UiSlimes.isFree(slime)
	elseif filter == "working" then
		return UiSlimes.job(slime) ~= nil
	elseif filter == "babies" then
		return UiSlimes.isBaby(slime)
	end
	return true
end

local function entries(): { UiSlimes.Entry }
	local list: { UiSlimes.Entry } = {}
	local own = if ctx then ctx.own() else nil
	for _, slime in UiSlimes.slimes(own) do
		if not firstSeen[slime] then
			seen += 1
			firstSeen[slime] = seen
		end
		if passes(slime) then
			table.insert(list, { slime = slime })
		end
	end
	table.sort(list, function(a, b)
		local left, right = a.slime, b.slime
		if sort == "speed" then
			local x, y = UiSlimes.number(left, "Speed"), UiSlimes.number(right, "Speed")
			if x ~= y then
				return x > y
			end
		elseif sort == "newest" then
			local x, y = firstSeen[left] or 0, firstSeen[right] or 0
			if x ~= y then
				return x > y
			end
		else
			local x, y = UiSlimes.number(left, "Level"), UiSlimes.number(right, "Level")
			if x ~= y then
				return x > y
			end
		end
		return left.Name < right.Name
	end)
	return list
end

local function clearDetail()
	detail = nil
	detailCard = nil
end

local render: () -> ()

local function drawDetail(id: string)
	local host, bar, context = content, header, ctx
	local own = if context then context.own() else nil
	local folder = if own then own:FindFirstChild("Slimes") else nil
	local slime = if folder then folder:FindFirstChild(id) else nil
	if not (host and bar and context and slime and slime:IsA("Configuration")) then
		clearDetail()
		render()
		return
	end
	local request = context.request
	UiSlimes.releaseAll()
	UiKit.clear(host)
	UiKit.clear(bar)
	view = nil
	UiKit.button(bar, {
		Name = "Back",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		OnClick = function()
			clearDetail()
			render()
		end,
	})
	local card = UiSlimes.card(host, { slime = slime }, nil)
	card.root.Size = UDim2.new(1, -8, 0, U.CardHeight)
	card.show()
	detailCard = card
	local trait = slime:GetAttribute("Trait")
	if type(trait) == "string" and trait ~= "" then
		UiKit.label(host, trait, U.TextNormal, "BrownSoft", {
			Position = UDim2.fromOffset(4, U.CardHeight + U.Gap),
			Size = UDim2.new(1, -8, 0, U.TextNormal + 6),
		})
	end
	local actions = UiKit.make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, U.CardHeight + U.Gap * 2 + U.TextNormal + 6),
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, host)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, actions)
	if UiSlimes.job(slime) then
		UiKit.button(actions, {
			Text = "Stop work",
			Style = "secondary",
			Size = UDim2.fromOffset(U.Touch * 2 + 20, U.Touch),
			LayoutOrder = 1,
			OnClick = function()
				request({ action = "Unassign", slimeId = id }, function() end)
			end,
		})
	end
	local allowed = slime:GetAttribute("CookedAllowed") == true
	UiKit.button(actions, {
		Icon = "food",
		Text = if allowed then "Cooked" else "Raw",
		Style = if allowed then "good" else "secondary",
		Size = UDim2.fromOffset(U.Touch * 2 + 20, U.Touch),
		LayoutOrder = 2,
		OnClick = function()
			request({ action = "SetCookedAllowed", slimeId = id, allowed = not allowed }, function() end)
		end,
	})
end

render = function()
	local host, bar = content, header
	if not (host and bar and ctx) then
		return
	end
	if detail then
		drawDetail(detail)
		return
	end
	UiSlimes.releaseAll()
	UiKit.clear(host)
	UiKit.clear(bar)
	detailCard = nil
	UiKit.icon(bar, "slimes", U.Touch - 8, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) })
	countLabel = UiKit.label(bar, "", U.TextNormal, "Brown", {
		Position = UDim2.fromOffset(U.Touch - 6, 0),
		Size = UDim2.fromOffset(56, U.Touch),
		TextTruncate = Enum.TextTruncate.None,
	})
	-- Sort buttons sit between the count and the close button.
	local sorts = UiKit.make("Frame", {
		Name = "Sorts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(U.Touch * 3 + U.Gap * 2, U.Touch),
	}, bar)
	local items = {}
	for _, id in U.BookSorts do
		table.insert(items, { id = id, text = sortLabels[id].text, icon = sortLabels[id].icon })
	end
	UiKit.segmented(sorts, items, sort, function(id)
		sort = id
		if view then
			view.refresh()
		end
	end, { ItemWidth = U.Touch })
	local filters = {}
	for _, id in U.BookFilters do
		table.insert(filters, { id = id, text = filterLabels[id] })
	end
	UiKit.segmented(host, filters, filter, function(id)
		filter = id
		if view then
			view.refresh()
		end
	end, { Name = "Filters" })
	local area = UiKit.make("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, U.Touch + U.Gap),
		Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
	}, host)
	local list = UiSlimes.view(area, entries, function(slime)
		detail = slime.Name
		render()
	end)
	view = list
	list.refresh()
	UiBook.refresh()
end

-- Called when a slime or the village changes: redraws in place.
function UiBook.refresh()
	if UiKit.modalId() ~= "book" then
		return
	end
	local own = if ctx then ctx.own() else nil
	if countLabel and own then
		countLabel.Text = tostring(own:GetAttribute("Population") or 0)
			.. "/"
			.. tostring(own:GetAttribute("Limit") or 0)
	end
	if detail then
		local folder = if own then own:FindFirstChild("Slimes") else nil
		if not (folder and folder:FindFirstChild(detail)) then
			clearDetail()
			render()
		elseif detailCard then
			detailCard.update({ slime = detailCard.slime })
		end
	elseif view then
		view.refresh()
	end
end

function UiBook.isOpen(): boolean
	return UiKit.modalId() == "book"
end

function UiBook.open(context: Context)
	if UiBook.isOpen() then
		UiKit.closeModal()
		return
	end
	ctx = context
	detail = nil
	local modal = UiKit.openModal("book", {
		Width = U.BookWidth,
		Height = U.BookHeight,
		OnClose = function()
			UiSlimes.releaseAll()
			view, detailCard, countLabel, content, header = nil, nil, nil, nil, nil
			detail = nil
		end,
	})
	content, header = modal.content, modal.header
	render()
end

return UiBook
