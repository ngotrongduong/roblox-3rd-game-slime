--!strict
-- The slime book: every slime of the player's own village as a card, with sort and filter, and a detail page.
-- Opened by the round edge button. Reads published attributes; asks the server through ctx.request.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiIndex = require(script.Parent.UiIndex)
local UiKit = require(script.Parent.UiKit)
local UiSlimeList = require(script.Parent.UiSlimeList)
local UiSlimes = require(script.Parent.UiSlimes)

local U = Config.Ui

export type Context = {
	own: () -> Folder?,
	request: (data: { [string]: any }, onSuccess: () -> ()) -> (),
}

local UiBook = {}
local ctx: Context? = nil
local filter = U.BookFilters[1]
-- "slimes" or "index"
local page = "slimes"
local detail: string? = nil
local view: UiSlimeList.List? = nil
local detailCard: UiSlimes.Card? = nil
local countLabel: TextLabel? = nil
local content: Frame? = nil
local header: Frame? = nil

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

local function entries(): { UiSlimeList.Entry }
	local list: { UiSlimeList.Entry } = {}
	local own = if ctx then ctx.own() else nil
	for _, slime in UiSlimes.slimes(own) do
		if passes(slime) then
			table.insert(list, { slime = slime, mark = UiSlimeList.stateMark(slime) })
		end
	end
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
	UiIndex.release()
	UiKit.clear(host)
	UiKit.clear(bar)
	detailCard = nil
	-- The two pages of the book: the player's own slimes, and the Index of every kind there is.
	UiKit.segmented(
		bar,
		{
			{ id = "slimes", icon = "slimes" },
			{ id = "index", icon = "collection" },
		},
		page,
		function(id)
			page = id
			render()
		end,
		{ Name = "Pages", ItemWidth = U.Touch, Size = UDim2.fromOffset(U.Touch * 2 + U.Gap, U.Touch) }
	)
	countLabel = UiKit.label(bar, "", U.TextNormal, "Brown", {
		Position = UDim2.fromOffset(U.Touch * 2 + U.Gap * 3, 0),
		Size = UDim2.fromOffset(120, U.Touch),
		TextTruncate = Enum.TextTruncate.None,
	})
	if page == "index" then
		local own = ctx.own()
		local have, all = UiIndex.totals(own)
		local label = countLabel :: TextLabel
		label.Text = "Index " .. have .. "/" .. all
		UiIndex.draw(host, own)
		-- (the Index's intro is done once the player has looked at it)
		if own and own:GetAttribute("IndexSeen") == false then
			ctx.request({ action = "IndexSeen" }, function() end)
		end
		return
	end
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
	local list = UiSlimeList.new(area, {
		entries = entries,
		onTap = function(slime)
			detail = slime.Name
			render()
		end,
	})
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
	if page == "index" then
		return
	end
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
	-- the Index's intro opens the book on the Index
	local own = context.own()
	if own and own:GetAttribute("GuideId") == "index" then
		page = "index"
	end
	local modal = UiKit.openModal("book", {
		Width = U.BookWidth,
		Height = U.BookHeight,
		OnClose = function()
			UiSlimes.releaseAll()
			UiIndex.release()
			view, detailCard, countLabel, content, header = nil, nil, nil, nil, nil
			detail = nil
		end,
	})
	content, header = modal.content, modal.header
	render()
end

return UiBook
