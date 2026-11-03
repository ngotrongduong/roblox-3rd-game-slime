--!strict
-- The rewards sheet (docs/GAMEPLAY.md §13), opened by the trophy at the right edge: the daily check-in, today's quests and
-- the online gifts, one tab each. It draws what the server published on the village folder (Rewards, OnlineSince) and asks
-- the server to claim; a reward is its picture and a short number. Also keeps the trophy's badge and the luck chip on time.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
local R = Config.Rewards

export type Context = {
	own: () -> Folder?,
	request: (data: { [string]: any }, onSuccess: (() -> ())?, onFail: (() -> ())?) -> (),
}

local UiRewards = {}
local ctx: Context? = nil
local tab = "daily"
local content: Frame? = nil
-- Labels that count down while the sheet is open: redrawn every second.
local clocks: { { label: TextLabel, text: () -> string } } = {}
-- What the sheet was drawn from, so a second-by-second look redraws only when something changed.
local drawnFrom = ""
-- Online gifts that open while the sheet is open: drawn again the moment one opens.
local drawnReady = -1

local TABS = {
	{ id = "daily", icon = "daily" },
	{ id = "quests", icon = "quests" },
	{ id = "online", icon = "online" },
}

-- The picture of each kind of quest.
local QUEST_ICON: { [string]: string } = {
	breed = "breeding",
	hatch = "slimes",
	sell = "market",
	feed = "food",
	win = "attack",
	upgrade = "level",
}

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function view(): { [string]: any }
	local own = if ctx then ctx.own() else nil
	local raw = if own then own:GetAttribute("Rewards") else nil
	if type(raw) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

local function playedSeconds(): number
	local own = if ctx then ctx.own() else nil
	local since = if own then own:GetAttribute("OnlineSince") else nil
	return if type(since) == "number" then math.max(0, serverNow() - since) else 0
end

-- 1234 -> "1.2K"; small numbers stay whole.
local function short(amount: number): string
	if amount >= 1_000_000 then
		return string.format("%.1fM", amount / 1_000_000)
	elseif amount >= 10_000 then
		return string.format("%.0fK", amount / 1000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(math.floor(amount))
end

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h, m, s = seconds // 3600, seconds // 60 % 60, seconds % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, s)
end

local function tickClocks()
	for _, item in clocks do
		item.label.Text = item.text()
	end
end

-- A reward as pictures and short numbers in a row: coins, then luck minutes.
local function rewardRow(parent: Instance, coins: number, luck: number, size: number, props: UiKit.Props?): Frame
	local row =
		UiKit.make("Frame", { Name = "Reward", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size) }, parent)
	if props then
		for key, value in props do
			(row :: any)[key] = value
		end
	end
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local function part(icon: string, text: string, order: number)
		UiKit.icon(row, icon, size, { LayoutOrder = order })
		UiKit.label(row, text, U.TextSmall, "Brown", {
			LayoutOrder = order + 1,
			Size = UDim2.fromOffset(0, size),
			AutomaticSize = Enum.AutomaticSize.X,
		})
	end
	if coins > 0 then
		part("coins", short(coins), 1)
	end
	if luck > 0 then
		part("luck", luck .. "m", 3)
	end
	return row
end

local function claim(data: { [string]: any }, coins: number, luck: number)
	local context = ctx
	if not context then
		return
	end
	context.request(data, function()
		local words = {}
		if coins > 0 then
			table.insert(words, "+" .. UiKit.money(coins) .. " coins")
		end
		if luck > 0 then
			table.insert(words, "Luck x" .. Config.Luck.Potion .. " +" .. luck .. "m")
		end
		UiKit.toast(table.concat(words, "  "))
	end)
end

-- A small tile of a grid: a title on top, the reward in the middle, a state line or a Claim button at the foot.
local function tile(
	parent: Instance,
	order: number,
	title: string,
	coins: number,
	luck: number,
	state: string,
	onClaim: (() -> ())?
): Frame
	local fill = if state == "ready" then "GoldLight" elseif state == "taken" then "CardDeep" else "Card"
	local box, body = UiKit.skin(parent, "Wood", fill, { Name = "Tile" .. order, LayoutOrder = order })
	UiKit.label(body, title, U.TextSmall, "Brown", {
		Size = UDim2.new(1, 0, 0, U.TextSmall + 4),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	-- coins and luck stack, one line each, so neither is cut on a narrow tile
	local top = U.TextSmall + 6
	if coins > 0 then
		rewardRow(body, coins, 0, U.IconNormal - 6, {
			Position = UDim2.fromOffset(0, top),
			Size = UDim2.new(1, 0, 0, U.IconNormal - 4),
		})
		top += U.IconNormal - 4
	end
	if luck > 0 then
		rewardRow(body, 0, luck, U.IconNormal - 6, {
			Position = UDim2.fromOffset(0, top),
			Size = UDim2.new(1, 0, 0, U.IconNormal - 4),
		})
	end
	local foot = UDim2.new(0, 0, 1, -(U.TextSmall + 10))
	if state == "ready" or state == "taken" then
		UiKit.label(body, if state == "ready" then "Claim!" else "Taken", U.TextSmall, "GreenDark", {
			Name = "State",
			Position = foot,
			Size = UDim2.new(1, 0, 0, U.TextSmall + 8),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	if state == "ready" and onClaim then
		-- the whole tile is the button (a touch target never smaller than the tile)
		local press = UiKit.make("TextButton", {
			Name = "Claim",
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 10,
		}, box)
		press.Activated:Connect(onClaim)
	end
	box:SetAttribute("State", state)
	return box
end

local function grid(parent: Instance, top: number, height: number, width: number): Frame
	local area = UiKit.make("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top - height),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent)
	UiKit.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(width, R.TileHeight),
		CellPadding = UDim2.fromOffset(U.Gap, U.Gap),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, area)
	return area
end

local function footLine(parent: Instance, text: () -> string)
	local label = UiKit.label(parent, text(), U.TextSmall, "BrownSoft", {
		Name = "Foot",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, U.TextSmall + 8),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	table.insert(clocks, { label = label, text = text })
end

local function drawDaily(host: Frame, data: { [string]: any })
	local rows = data.daily or {}
	local today = data.day or 1
	local taken = data.taken == true
	local area = grid(host, 0, U.TextSmall + 10, R.TileWidth)
	for day, row in rows do
		local state = if day < today or (day == today and taken)
			then "taken"
			elseif day == today then "ready"
			else "later"
		tile(area, day, "Day " .. day, row[1] or 0, row[2] or 0, state, function()
			claim({ action = "ClaimDaily" }, row[1] or 0, row[2] or 0)
		end)
	end
	footLine(host, function()
		if taken then
			return "Next gift in " .. clock((data.reset or 0) - serverNow())
		end
		return "Come back every day for a bigger gift!"
	end)
end

local function drawQuests(host: Frame, data: { [string]: any })
	local list = UiKit.make("Frame", {
		Name = "Quests",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -(U.TextSmall + 10)),
	}, host)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local quests = data.quests or {}
	if #quests == 0 then
		UiKit.label(list, "New quests come soon.", U.TextNormal, "BrownSoft", {
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	for index, row in quests do
		local text, have, need, claimed, coins, kind = row[1], row[2], row[3], row[4], row[5], row[6]
		local done = have >= need
		local _, body = UiKit.skin(list, "Wood", if claimed then "CardDeep" else "Card", {
			Name = "Quest" .. index,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, R.QuestRowHeight),
		})
		UiKit.icon(body, QUEST_ICON[kind] or "slimes", U.Touch - 4, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
		})
		local left = U.Touch + U.Gap
		local right = U.Touch * 2 + 24
		UiKit.label(body, tostring(text), U.TextNormal, "Brown", {
			Position = UDim2.fromOffset(left, 2),
			Size = UDim2.new(1, -left - right, 0, U.TextNormal + 4),
		})
		local bar = UiKit.bar(body, "", if done then "Green" else "GoldLight", {
			Position = UDim2.fromOffset(left, U.TextNormal + 10),
			Size = UDim2.new(1, -left - right - 52, 0, U.IconSmall),
		})
		bar.set(have / math.max(1, need), false)
		UiKit.label(body, have .. "/" .. need, U.TextSmall, "BrownSoft", {
			Position = UDim2.new(1, -right - 48, 0, U.TextNormal + 8),
			Size = UDim2.fromOffset(46, U.IconSmall + 4),
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		local side = UiKit.make("Frame", {
			Name = "Side",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, right - U.Gap, 1, 0),
		}, body)
		rewardRow(side, coins, 0, U.IconSmall, { Size = UDim2.new(1, 0, 0, U.IconSmall) })
		if claimed then
			UiKit.label(side, "Taken", U.TextSmall, "GreenDark", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, U.Touch),
				TextXAlignment = Enum.TextXAlignment.Center,
			})
		else
			UiKit.button(side, {
				Name = "Claim",
				Text = "Claim",
				Style = if done then "good" else "secondary",
				Enabled = done,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, U.Touch),
				OnClick = function()
					claim({ action = "ClaimQuest", index = index }, coins, 0)
				end,
			})
		end
	end
	local bonus = data.bonus or { 0, 0, 0 }
	if #quests > 0 then
		local _, body = UiKit.skin(list, "Wood", if bonus[1] == 1 then "GoldLight" else "Card", {
			Name = "Bonus",
			LayoutOrder = 99,
			Size = UDim2.new(1, 0, 0, U.Touch + 16),
		})
		UiKit.label(body, "All " .. #quests .. " done:", U.TextNormal, "Brown", {
			Position = UDim2.fromOffset(U.Gap, 0),
			Size = UDim2.new(0.4, -U.Gap, 1, 0),
		})
		rewardRow(body, bonus[2] or 0, bonus[3] or 0, U.IconNormal - 4, {
			Position = UDim2.fromScale(0.4, 0),
			Size = UDim2.fromScale(0.3, 1),
		})
		if bonus[1] == 2 then
			UiKit.label(body, "Taken", U.TextSmall, "GreenDark", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.28, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
			})
		else
			UiKit.button(body, {
				Name = "Claim",
				Text = "Claim",
				Style = if bonus[1] == 1 then "good" else "secondary",
				Enabled = bonus[1] == 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.new(0.28, 0, 0, U.Touch),
				OnClick = function()
					claim({ action = "ClaimQuestBonus" }, bonus[2] or 0, bonus[3] or 0)
				end,
			})
		end
	end
	footLine(host, function()
		return "New quests in " .. clock((data.reset or 0) - serverNow())
	end)
end

local function drawOnline(host: Frame, data: { [string]: any })
	local area = grid(host, 0, U.TextSmall + 10, R.OnlineTileWidth)
	local played = playedSeconds()
	for step, row in data.online or {} do
		local minutes, coins, luck, taken = row[1], row[2], row[3], row[4]
		local state = if taken then "taken" elseif played >= minutes * 60 then "ready" else "later"
		local box = tile(area, step, minutes .. " min", coins, luck, state, function()
			claim({ action = "ClaimOnline", step = step }, coins, luck)
		end)
		if state == "later" then
			local body = box:FindFirstChild("Body") :: Frame
			local label = UiKit.label(body, "", U.TextSmall, "BrownSoft", {
				Name = "Wait",
				Position = UDim2.new(0, 0, 1, -(U.TextSmall + 10)),
				Size = UDim2.new(1, 0, 0, U.TextSmall + 8),
				TextXAlignment = Enum.TextXAlignment.Center,
			})
			local function text(): string
				return clock(minutes * 60 - playedSeconds())
			end
			label.Text = text()
			table.insert(clocks, { label = label, text = text })
		end
	end
	footLine(host, function()
		return "Played today: " .. clock(playedSeconds())
	end)
end

-- How many online gifts are open by the client's clock (they open between the server's looks).
local function openGifts(data: { [string]: any }): number
	local played = playedSeconds()
	local count = 0
	for _, row in data.online or {} do
		if not row[4] and played >= row[1] * 60 then
			count += 1
		end
	end
	return count
end

local function render()
	local host = content
	if not host then
		return
	end
	table.clear(clocks)
	UiKit.clear(host)
	local data = view()
	local own = if ctx then ctx.own() else nil
	drawnFrom = tostring(if own then own:GetAttribute("Rewards") else "")
	drawnReady = openGifts(data)
	if tab == "quests" then
		drawQuests(host, data)
	elseif tab == "online" then
		drawOnline(host, data)
	else
		drawDaily(host, data)
	end
end

function UiRewards.isOpen(): boolean
	return UiKit.modalId() == "rewards"
end

function UiRewards.open()
	if UiRewards.isOpen() then
		UiKit.closeModal()
		return
	end
	-- the tab with something to take comes first
	local data = view()
	if data.taken == false then
		tab = "daily"
	elseif openGifts(data) > 0 then
		tab = "online"
	end
	local modal = UiKit.openModal("rewards", {
		Width = R.SheetWidth,
		Height = R.SheetHeight,
		OnClose = function()
			content = nil
			table.clear(clocks)
		end,
	})
	content = modal.content
	UiKit.icon(modal.header, "rewards", U.Touch - 8, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	})
	local items = {}
	for _, item in TABS do
		table.insert(
			items,
			{ id = item.id, icon = item.icon, text = string.upper(string.sub(item.id, 1, 1)) .. string.sub(item.id, 2) }
		)
	end
	UiKit.segmented(modal.header, items, tab, function(id)
		tab = id
		render()
	end, {
		Name = "Tabs",
		ItemWidth = 104,
		Position = UDim2.fromOffset(U.Touch, 0),
		Size = UDim2.new(1, -U.Touch, 1, 0),
	})
	render()
end

-- Called when the village folder's rewards change, and once a second.
function UiRewards.refresh()
	if not UiRewards.isOpen() then
		return
	end
	local own = if ctx then ctx.own() else nil
	local raw = tostring(if own then own:GetAttribute("Rewards") else "")
	if raw ~= drawnFrom or openGifts(view()) ~= drawnReady then
		render()
	else
		tickClocks()
	end
end

function UiRewards.start(context: Context)
	ctx = context
end

return UiRewards
