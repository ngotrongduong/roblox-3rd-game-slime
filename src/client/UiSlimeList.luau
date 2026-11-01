--!strict
-- THE slime list of the whole game (the owner, 2026-11-02: one form everywhere): a row of sort buttons (Level, Attack,
-- Defence, Speed, HP; tapping the chosen one again flips the order) over a scrolling grid of tiles. A tile is the slime's
-- portrait with its level, the stat the list is sorted by and, when it is wounded, a thin health bar. Each place passes only
-- what differs: which slimes, which of them are unavailable and why, a small mark in a tile's corner, and what a tap does.
-- The chosen sort is remembered for the session. Tiles are made once and updated in place; a refresh with the same slimes
-- touches only what changed, so a list of 72 stays cheap on a phone. Reads attributes; decides nothing.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)

local U = Config.Ui
local T = U.Tile

-- A small picture and/or short text in the tile's top right corner; colour is a Config.Ui.Colours name for its plate.
export type Mark = { icon: string?, text: string?, colour: string? }
export type Entry = {
	slime: Configuration,
	-- greyed and not tappable; a tap shows `why` instead
	blocked: boolean?,
	why: string?,
	mark: Mark?,
	-- the best free slime for the job: pinned first, marked
	suggested: boolean?,
	selected: boolean?,
	-- replaces the stat line (the revive time)
	caption: string?,
	captionColour: string?,
}
export type Options = {
	entries: () -> { Entry },
	onTap: (Configuration) -> (),
}
export type List = {
	root: Frame,
	refresh: () -> (),
	destroy: () -> (),
}

type Tile = {
	root: TextButton,
	fill: Frame?,
	level: TextLabel,
	statRow: Frame,
	statIcon: ImageLabel,
	statValue: TextLabel,
	woundTrack: Frame,
	woundFill: Frame,
	markHost: Frame,
	veil: Frame,
	show: () -> (),
	entry: Entry,
	key: string,
	markKey: string,
}

local UiSlimeList = {}

-- Remembered for the session, shared by every list.
local sortKey: string = U.Sorts[1]
local descending = true

local function imageOf(name: string): string
	local id = (U.Icons :: any)[name]
	return if type(id) == "number" and id > 0 then "rbxassetid://" .. tostring(id) else ""
end

-- The default mark for what a slime is doing: its job, its pair, out on a team, resting, baby, fallen.
function UiSlimeList.stateMark(slime: Configuration): Mark?
	if UiSlimes.isGhost(slime) then
		return { icon = "skull" }
	elseif UiSlimes.isBaby(slime) then
		return { text = "Baby", colour = "Blue" }
	elseif slime:GetAttribute("OutOnSquad") == true then
		return { icon = "attack" }
	end
	local job = UiSlimes.job(slime)
	if job then
		return { icon = job }
	elseif UiSlimes.pair(slime) > 0 then
		return { icon = "breeding" }
	elseif slime:GetAttribute("Sleeping") == true or UiSlimes.number(slime, "Energy") <= Config.Needs.Tired then
		return { icon = "energy" }
	end
	return nil
end

local function markKeyOf(mark: Mark?): string
	if not mark then
		return ""
	end
	return tostring(mark.icon) .. "|" .. tostring(mark.text) .. "|" .. tostring(mark.colour)
end

local function drawMark(host: Frame, mark: Mark?)
	UiKit.clear(host)
	if not mark then
		return
	end
	local pill = UiKit.make("Frame", {
		Name = "Pill",
		BackgroundColor3 = UiKit.colour(mark.colour or "CardDeep"),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, T.MarkSize),
		AutomaticSize = Enum.AutomaticSize.X,
	}, host)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
	UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, pill)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, pill)
	if mark.icon then
		UiKit.icon(pill, mark.icon, T.MarkSize - 4, { LayoutOrder = 1 })
	end
	if mark.text then
		local onPlate = mark.colour == "Blue" or mark.colour == "Green" or mark.colour == "Red"
		UiKit.label(pill, mark.text, U.TextTiny, if onPlate then "Cream" else "Brown", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
end

-- Makes one tile for a slime. The portrait is built only when the tile scrolls into view (show).
local function makeTile(parent: Instance, entry: Entry, onTap: (Configuration) -> ()): Tile
	local slime = entry.slime
	local root = UiKit.make("TextButton", {
		Name = slime.Name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
	}, parent)
	local box, body = UiKit.card(root, { Size = UDim2.fromScale(1, 1) })
	local _, show = UiSlimes.portrait(body, slime, T.Portrait, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
	})
	local track = UiKit.make("Frame", {
		Name = "Wound",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, T.Portrait - T.WoundHeight - 5),
		Size = UDim2.fromOffset(T.Portrait - 12, T.WoundHeight),
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 6,
	}, body)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
	local woundFill = UiKit.make("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour("Green"),
		BorderSizePixel = 0,
	}, track)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, woundFill)
	local level = UiKit.label(body, "", U.TextSmall, "Brown", {
		Position = UDim2.fromOffset(0, T.Portrait + 2),
		Size = UDim2.new(1, 0, 0, U.TextSmall + 4),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local statRow = UiKit.make("Frame", {
		Name = "Stat",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, T.Portrait + U.TextSmall + 6),
		Size = UDim2.new(1, 0, 0, U.IconSmall - 2),
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, statRow)
	local statIcon = UiKit.make("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(U.IconSmall - 4, U.IconSmall - 4),
		LayoutOrder = 1,
	}, statRow)
	local statValue = UiKit.label(statRow, "", U.TextTiny, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local markHost = UiKit.make("Frame", {
		Name = "Mark",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.5, T.Portrait / 2, 0, 0),
		Size = UDim2.fromOffset(T.Portrait, T.MarkSize),
		ZIndex = 7,
	}, body)
	local veil = UiKit.make("Frame", {
		Name = "Veil",
		BackgroundColor3 = UiKit.colour("Parchment"),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 5,
	}, body)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0, 8) }, veil)
	local fill = box:FindFirstChild("Fill")
	local tile: Tile = {
		root = root,
		fill = if fill and fill:IsA("Frame") then fill else nil,
		level = level,
		statRow = statRow,
		statIcon = statIcon,
		statValue = statValue,
		woundTrack = track,
		woundFill = woundFill,
		markHost = markHost,
		veil = veil,
		show = show,
		entry = entry,
		key = "",
		markKey = "",
	}
	root.Activated:Connect(function()
		local current = tile.entry
		if current.blocked then
			if current.why then
				UiKit.toast(current.why)
			end
		else
			onTap(current.slime)
		end
	end)
	return tile
end

local function update(tile: Tile, entry: Entry)
	tile.entry = entry
	local slime = entry.slime
	local level = UiSlimes.number(slime, "Level")
	local attribute = (U.SortAttributes :: any)[sortKey]
	local stat = if sortKey ~= "level" then UiSlimes.number(slime, attribute) else 0
	local share = UiSlimes.hpShare(slime)
	local mark = if entry.suggested then { text = "Best", colour = "Green" } else entry.mark
	local key = table.concat({
		tostring(level),
		sortKey,
		tostring(stat),
		tostring(math.floor(share * 100)),
		tostring(entry.blocked == true),
		tostring(entry.selected == true),
		tostring(entry.suggested == true),
		tostring(entry.caption),
		tostring(entry.captionColour),
	}, "|")
	if key ~= tile.key then
		tile.key = key
		tile.level.Text = "Lv " .. tostring(level)
		local caption = entry.caption
		tile.statRow.Visible = caption ~= nil or sortKey ~= "level"
		tile.statIcon.Visible = caption == nil
		if caption then
			tile.statValue.Text = caption
			tile.statValue.TextColor3 = UiKit.colour(entry.captionColour or "Brown")
		else
			tile.statIcon.Image = imageOf(sortKey)
			tile.statValue.Text = tostring(stat)
			tile.statValue.TextColor3 = UiKit.colour("Brown")
		end
		tile.woundTrack.Visible = share < 1
		tile.woundFill.Size = UDim2.fromScale(share, 1)
		tile.woundFill.BackgroundColor3 = UiKit.colour(if share < T.WoundLow then "Red" else "Green")
		tile.veil.Visible = entry.blocked == true
		if tile.fill then
			tile.fill.BackgroundColor3 = UiKit.colour(if entry.selected or entry.suggested then "Portrait" else "Card")
		end
	end
	local markKey = markKeyOf(mark)
	if markKey ~= tile.markKey then
		tile.markKey = markKey
		drawMark(tile.markHost, mark)
	end
end

local function before(left: Entry, right: Entry): boolean
	if (left.suggested == true) ~= (right.suggested == true) then
		return left.suggested == true
	end
	local attribute = (U.SortAttributes :: any)[sortKey]
	local x, y = UiSlimes.number(left.slime, attribute), UiSlimes.number(right.slime, attribute)
	if x ~= y then
		return if descending then x > y else x < y
	end
	-- (a tie falls back to the level, then the name, so the order never jumps)
	local a, b = UiSlimes.number(left.slime, "Level"), UiSlimes.number(right.slime, "Level")
	if a ~= b then
		return a > b
	end
	return left.slime.Name < right.slime.Name
end

function UiSlimeList.new(parent: Instance, options: Options): List
	local root =
		UiKit.make("Frame", { Name = "SlimeList", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, parent)
	local row = UiKit.make("Frame", {
		Name = "Sorts",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, root)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local scroller = UiKit.make("ScrollingFrame", {
		Name = "Tiles",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, U.Touch + U.Gap),
		Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, root)
	local grid = UiKit.make("UIGridLayout", {
		CellPadding = UDim2.fromOffset(U.Gap, U.Gap),
		CellSize = UDim2.fromOffset(T.Width, T.Height),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroller)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroller)

	local tiles: { [string]: Tile } = {}
	local order: { string } = {}
	local arrows: { [string]: GuiObject } = {}
	local buttons: { [string]: TextButton } = {}

	local function fit()
		local width = math.max(UiKit.units(scroller).X - 8 - 5, T.Width)
		local columns = math.max(1, math.floor((width + U.Gap) / (T.Width + U.Gap)))
		local cell = math.floor((width - U.Gap * (columns - 1)) / columns)
		grid.CellSize = UDim2.fromOffset(cell, T.Height)
	end
	local function reveal()
		local top = scroller.AbsolutePosition.Y - T.Height
		local bottom = scroller.AbsolutePosition.Y + scroller.AbsoluteSize.Y + T.Height
		for _, id in order do
			local tile = tiles[id]
			if tile and tile.root.AbsolutePosition.Y >= top and tile.root.AbsolutePosition.Y <= bottom then
				tile.show()
			end
		end
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		fit()
		task.defer(reveal)
	end)
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(reveal)

	local refresh: () -> ()
	local function paintSorts()
		for id, button in buttons do
			UiKit.setStyle(button, if id == sortKey then "primary" else "secondary")
			local arrow = arrows[id]
			arrow.Visible = id == sortKey
			arrow.Rotation = if descending then -90 else 90
		end
	end
	for index, id in U.Sorts do
		local button = UiKit.button(row, {
			Name = id,
			Text = if id == "level" then "Lv" else nil,
			Icon = if id == "level" then nil else id,
			Style = "secondary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			LayoutOrder = index,
			OnClick = function()
				if sortKey == id then
					descending = not descending
				else
					sortKey, descending = id, true
				end
				paintSorts()
				refresh()
			end,
		})
		-- the way it sorts: an arrow (the owner's back arrow turned) on the chosen button's corner
		arrows[id] = UiKit.icon(button, "back", T.SortArrow, {
			Name = "Order",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -2, 1, -2),
			ZIndex = 8,
			Visible = false,
		})
		buttons[id] = button
	end
	paintSorts()

	refresh = function()
		local list = options.entries()
		table.sort(list, before)
		local keep = scroller.CanvasPosition
		local fresh: { [string]: boolean } = {}
		local changed = #list ~= #order
		for index, entry in list do
			local id = entry.slime.Name
			local tile = tiles[id]
			if not tile then
				tile = makeTile(scroller, entry, options.onTap)
				tiles[id] = tile
				changed = true
			end
			update(tile, entry)
			if tile.root.LayoutOrder ~= index then
				tile.root.LayoutOrder = index
			end
			if order[index] ~= id then
				changed = true
			end
			order[index] = id
			fresh[id] = true
		end
		for index = #order, #list + 1, -1 do
			order[index] = nil
		end
		for id, tile in tiles do
			if not fresh[id] then
				UiSlimes.park(tile.root)
				tile.root:Destroy()
				tiles[id] = nil
				changed = true
			end
		end
		if changed then
			fit()
			task.defer(function()
				if scroller.Parent then
					scroller.CanvasPosition = keep
					reveal()
				end
			end)
		end
	end

	local function destroy()
		for _, tile in tiles do
			UiSlimes.park(tile.root)
		end
		table.clear(tiles)
		table.clear(order)
		root:Destroy()
	end
	return { root = root, refresh = refresh, destroy = destroy }
end

return UiSlimeList
