--!strict
-- THE slime list of the whole game (the owner, 2026-11-02: one form everywhere): one sort button at the right of the header
-- ("Sort: Level"; its dropdown offers Level, Attack, Defence, Speed, HP, and choosing the chosen one again flips the order)
-- over a scrolling grid of tiles. A tile is the slime's portrait with its level, its four fight stats, the gear it wears
-- and, when it is wounded, a thin health bar. Each place passes only
-- what differs: which slimes, which of them are unavailable and why, a small mark in a tile's corner, and what a tap does.
-- The chosen sort is remembered for the session. Tiles are made once and updated in place; a refresh with the same slimes
-- touches only what changed, so a list of 72 stays cheap on a phone. Reads attributes; decides nothing.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)

local U = Config.Ui
local T = U.Tile
-- the fight stats a tile shows, in the order of the slime's page
local STATS = { "attack", "defence", "speed", "hp" }

-- A small picture and/or short text in the tile's top right corner; colour is a Config.Ui.Colours name for its plate.
export type Mark = { icon: string?, text: string?, colour: string? }
export type Entry = {
	slime: Configuration,
	-- greyed and not tappable; a tap shows `why` instead
	blocked: boolean?,
	why: string?,
	-- tappable but taken elsewhere (another team's member); like a blocked one it sorts after the free slimes (the owner,
	-- 2026-11-06: the slimes that can be used come first, the busy ones at the end)
	busy: boolean?,
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
	-- the caption row (the revive time) or, without a caption, the stats grid with its four numbers
	statRow: Frame,
	statValue: TextLabel,
	grid: Frame,
	values: { [string]: TextLabel },
	gear: Frame,
	woundTrack: Frame,
	woundFill: Frame,
	markHost: Frame,
	veil: Frame,
	show: () -> (),
	-- its picture has been asked for (the list shows pictures a few a frame)
	shown: boolean,
	entry: Entry,
	key: string,
	markKey: string,
}

local UiSlimeList = {}
UiSlimeList.stats = STATS

-- Remembered for the session, shared by every list.
local sortKey: string = U.Sorts[1]
local descending = true

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

-- A stat in a few characters: 1250 is "1.2k".
function UiSlimeList.short(amount: number): string
	if amount >= 10000 then
		return tostring(math.floor(amount / 1000)) .. "k"
	elseif amount >= 1000 then
		return string.format("%.1fk", amount / 1000)
	end
	return tostring(amount)
end

-- The pieces a slime wears (its `Gear` attribute), one small tile each in the colour of its tier, drawn into `host` (a row);
-- nothing for an empty slot. (UiSmithy draws the same tile, but it cannot be required from here: it needs UiTeams.)
function UiSlimeList.drawGear(host: Frame, slime: Instance, size: number)
	UiKit.clear(host)
	local text = slime:GetAttribute("Gear")
	local ok, worn = pcall(function()
		return HttpService:JSONDecode(text)
	end)
	if not ok or type(worn) ~= "table" then
		return
	end
	for order, slot in Config.Smithy.Slots do
		local def: any = Gear.get(worn[slot])
		if def and def.slot == slot then
			local tier: any = (Config.Smithy.Tiers :: any)[def.tier]
			local tile = UiKit.make("Frame", {
				Name = slot,
				BackgroundColor3 = if tier then Color3.fromHex(tier.colour) else UiKit.colour("CardDeep"),
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(size, size),
				LayoutOrder = order,
			}, host)
			UiKit.make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, tile)
			local icon = def.icon
			local image = if type(icon) == "number" and icon > 0
				then "rbxassetid://" .. tostring(icon)
				elseif type(icon) == "string" then icon
				else ""
			if image ~= "" then
				UiKit.make("ImageLabel", {
					BackgroundTransparency = 1,
					Image = image,
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
				}, tile)
			end
		end
	end
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
	-- the slime (no frame of its own inside the card), its level and the stat line, stacked and centred in the card; the
	-- stat line drops out of the stack while it is hidden
	local stack =
		UiKit.make("Frame", { Name = "Stack", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, stack)
	local portrait, show = UiSlimes.portrait(stack, slime, T.Portrait, { LayoutOrder = 1 }, nil, true)
	local track = UiKit.make("Frame", {
		Name = "Wound",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -2),
		Size = UDim2.fromOffset(T.Portrait - 12, T.WoundHeight),
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 6,
	}, portrait)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
	local woundFill = UiKit.make("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UiKit.colour("Green"),
		BorderSizePixel = 0,
	}, track)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, woundFill)
	local level = UiKit.label(stack, "", U.TextSmall, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, U.TextSmall + 4),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local statRow = UiKit.make("Frame", {
		Name = "Stat",
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, U.IconSmall - 2),
	}, stack)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, statRow)
	local statValue = UiKit.label(statRow, "", U.TextTiny, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	-- the four fight stats, two to a row: its picture and a short number
	local grid = UiKit.make("Frame", {
		Name = "Stats",
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 2 * T.StatRow),
	}, stack)
	UiKit.make("UIGridLayout", {
		CellSize = UDim2.new(0.5, 0, 0, T.StatRow),
		CellPadding = UDim2.new(),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	local values: { [string]: TextLabel } = {}
	for index, key in STATS do
		local cell = UiKit.make("Frame", { Name = key, BackgroundTransparency = 1, LayoutOrder = index }, grid)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, cell)
		UiKit.icon(cell, key, T.StatIcon, { LayoutOrder = 1 })
		values[key] = UiKit.label(cell, "", U.TextTiny, "Brown", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	-- what it wears
	local gear = UiKit.make("Frame", {
		Name = "Gear",
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, T.GearIcon),
	}, stack)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, gear)
	local markHost = UiKit.make("Frame", {
		Name = "Mark",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(T.Portrait, T.MarkSize),
		ZIndex = 7,
	}, portrait)
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
		statValue = statValue,
		grid = grid,
		values = values,
		gear = gear,
		woundTrack = track,
		woundFill = woundFill,
		markHost = markHost,
		veil = veil,
		show = show,
		shown = false,
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
	local share = UiSlimes.hpShare(slime)
	local mark = if entry.suggested then { text = "Best", colour = "Green" } else entry.mark
	local gearText = tostring(slime:GetAttribute("Gear"))
	local key = table.concat({
		tostring(level),
		UiSlimeList.short(UiSlimes.number(slime, "Attack")),
		UiSlimeList.short(UiSlimes.number(slime, "Defence")),
		UiSlimeList.short(UiSlimes.number(slime, "Speed")),
		UiSlimeList.short(UiSlimes.number(slime, "Hp")),
		gearText,
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
		tile.statRow.Visible = caption ~= nil
		tile.grid.Visible = caption == nil
		if caption then
			tile.statValue.Text = caption
			tile.statValue.TextColor3 = UiKit.colour(entry.captionColour or "Brown")
		end
		for stat, label in tile.values do
			label.Text = UiSlimeList.short(UiSlimes.number(slime, (U.SortAttributes :: any)[stat]))
		end
		UiSlimeList.drawGear(tile.gear, slime, T.GearIcon)
		tile.woundTrack.Visible = share < 1
		tile.woundFill.Size = UDim2.fromScale(share, 1)
		tile.woundFill.BackgroundColor3 = UiKit.colour(if share < T.WoundLow then "Red" else "Green")
		tile.veil.Visible = entry.blocked == true
		if tile.fill and tile.fill.Parent then
			UiKit.setFill(tile.fill.Parent, if entry.selected or entry.suggested then "Portrait" else "Card")
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
	local leftLate = left.blocked == true or left.busy == true
	if leftLate ~= (right.blocked == true or right.busy == true) then
		return not leftLate
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

	local function fit()
		local width = math.max(UiKit.units(scroller).X - 8 - 5, T.Width)
		local columns = math.max(1, math.floor((width + U.Gap) / (T.Width + U.Gap)))
		local cell = math.floor((width - U.Gap * (columns - 1)) / columns)
		grid.CellSize = UDim2.fromOffset(cell, T.Height)
	end
	local revealing = false
	-- Pictures for the tiles in view, T.PicturesPerFrame a frame until each has one (a picture that has to be built is a
	-- clone of the slime body; a screenful of them in one frame is a stall on a phone).
	local function reveal()
		if revealing then
			return
		end
		revealing = true
		task.spawn(function()
			while scroller.Parent do
				local top = scroller.AbsolutePosition.Y - T.Height
				local bottom = scroller.AbsolutePosition.Y + scroller.AbsoluteSize.Y + T.Height
				local made = 0
				for _, id in order do
					local tile = tiles[id]
					if
						tile
						and not tile.shown
						and tile.root.AbsolutePosition.Y >= top
						and tile.root.AbsolutePosition.Y <= bottom
					then
						tile.shown = true
						tile.show()
						made += 1
						if made >= T.PicturesPerFrame then
							break
						end
					end
				end
				if made < T.PicturesPerFrame then
					break
				end
				task.wait()
			end
			revealing = false
		end)
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		fit()
		task.defer(reveal)
	end)
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(reveal)

	local refresh: () -> ()
	-- A refresh of the rest of the tiles is already waiting for the next frame.
	local continuing = false
	-- One button at the right of the header shows the sort ("Sort: Level") and opens the choices; choosing the sort already
	-- in use flips its order, which the little arrow on the button shows.
	local choices: { { id: string, text: string } } = {}
	for _, id in U.Sorts do
		table.insert(choices, { id = id, text = (U.SortNames :: any)[id] })
	end
	local sortButton: TextButton
	local arrow: GuiObject
	local function paintSorts()
		local label = sortButton:FindFirstChild("Label", true)
		if label and label:IsA("TextLabel") then
			label.Text = "Sort: " .. (U.SortNames :: any)[sortKey]
		end
		arrow.Rotation = if descending then 0 else 180
	end
	sortButton = UiKit.button(row, {
		Name = "Sort",
		Text = "Sort",
		Style = "secondary",
		Size = UDim2.fromOffset(T.SortWidth, U.Touch),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		OnClick = function()
			UiKit.dropdown(sortButton, choices, sortKey, function(id)
				if sortKey == id then
					descending = not descending
				else
					sortKey, descending = id, true
				end
				paintSorts()
				refresh()
			end)
		end,
	})
	arrow = UiKit.icon(sortButton, "order", T.SortArrow, {
		Name = "Order",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		ZIndex = 8,
	})
	paintSorts()

	refresh = function()
		local list = options.entries()
		table.sort(list, before)
		local keep = scroller.CanvasPosition
		local fresh: { [string]: boolean } = {}
		local changed = false
		local previous = #order
		-- New tiles are made T.PerFrame at a time, the first of the sort first; the rest wait for the next frame, so
		-- opening a list of 70 slimes never makes 70 tiles (about 2000 instances) in one frame.
		local budget = T.PerFrame
		local built = 0
		local waiting = false
		for index, entry in list do
			local id = entry.slime.Name
			local tile = tiles[id]
			if not tile and budget > 0 then
				budget -= 1
				tile = makeTile(scroller, entry, options.onTap)
				tiles[id] = tile
				changed = true
			end
			if tile then
				update(tile, entry)
				if tile.root.LayoutOrder ~= index then
					tile.root.LayoutOrder = index
				end
				built += 1
				if order[built] ~= id then
					changed = true
				end
				order[built] = id
				fresh[id] = true
			else
				waiting = true
			end
		end
		for index = #order, built + 1, -1 do
			order[index] = nil
		end
		if previous ~= built then
			changed = true
		end
		if waiting and not continuing then
			continuing = true
			task.spawn(function()
				task.wait()
				continuing = false
				if root.Parent then
					refresh()
				end
			end)
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
