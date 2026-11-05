--!strict
-- The rewards sheet (docs/GAMEPLAY.md §13, docs/MONETIZATION.md §3-4), opened by the trophy at the right edge: the daily check-in
-- (with its milestones), today's quests, the weekly quests and chest, the goals, the online gifts and the Lucky Wheel, one icon
-- tab each. It draws what the server published on the village folder (Rewards, Wheel, WheelSpins, OnlineSince) and asks the server
-- to claim or spin; a reward is its pictures and short numbers, never how it is worked out. Also keeps the trophy's badge and the
-- luck chip on time.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiDungeon = require(script.Parent.UiDungeon)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)
local UiSmithy = require(script.Parent.UiSmithy)

local U = Config.Ui
local R = Config.Rewards
local W = U.Wheel

export type Context = {
	own: () -> Folder?,
	request: (data: { [string]: any }, onSuccess: (() -> ())?, onFail: (() -> ())?) -> (),
	-- like request, but the success callback gets what the server answered (the wheel's slice)
	ask: (data: { [string]: any }, onSuccess: (value: any) -> (), onFail: (() -> ())?) -> (),
}

type Item = { kind: string, id: string, count: number }
type Reward = { coins: number, luck: number, spins: number, items: { Item } }
-- One picture of a reward with its short number.
type Part = { picture: (parent: Instance, size: number) -> (), text: string }
-- One row of a list (a quest, a goal, a chest): state 0 not yet, 1 ready, 2 taken.
type RowSpec = {
	name: string,
	order: number,
	icon: string,
	text: string,
	have: number,
	need: number,
	reward: Reward,
	state: number,
	onClaim: () -> (),
	onReroll: (() -> ())?,
}

local UiRewards = {}
local ctx: Context? = nil
local tab = "daily"
local content: Frame? = nil
-- The tabs' row (in the header, or the first row of the page on a narrow screen).
local tabsFrame: Frame? = nil
local narrowSheet = false
-- Labels that count down while the sheet is open: redrawn every second.
local clocks: { { label: TextLabel, text: () -> string } } = {}
-- What the sheet was drawn from, so a second-by-second look redraws only when something changed.
local drawnFrom = ""
local drawnTab = ""
-- Online gifts that open while the sheet is open: drawn again the moment one opens.
local drawnReady = -1
-- The list on show and where each tab's list was scrolled to, so a redraw keeps the place.
local scrolling: ScrollingFrame? = nil
local scrolls: { [string]: number } = {}
-- The wheel: how far it is turned (degrees), a spin on its way, the odds list shown instead of the wheel.
local wheelAngle = 0
local spinning = false
local showOdds = false
local stage: Frame? = nil
local face: ImageLabel? = nil
local prizeCard: CanvasGroup? = nil
local prizeToken = 0

local TABS = {
	{ id = "daily", icon = "daily" },
	{ id = "quests", icon = "quests" },
	{ id = "weekly", icon = "weekly_chest" },
	{ id = "goals", icon = "goals" },
	{ id = "online", icon = "online" },
	{ id = "wheel", icon = "spin" },
}

-- The picture of each kind of quest.
local QUEST_ICON: { [string]: string } = {
	breed = "breeding",
	hatch = "slimes",
	sell = "market",
	feed = "food",
	win = "attack",
	upgrade = "level",
	wave = "dungeon",
	arena = "arena",
	craft = "training",
	cook = "kitchen",
	fish = "fishing",
	harvest = "garden",
	find = "collection",
	spin = "spin",
	play = "online",
}

-- The picture of each kind of goal.
local GOAL_ICON: { [string]: string } = {
	hatch = "slimes",
	find = "collection",
	village = "home",
	sell = "market",
	dungeon = "dungeon",
	wave = "attack",
	arena = "arena",
	craft = "training",
}

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function decode(name: string): { [string]: any }
	local own = if ctx then ctx.own() else nil
	local raw = if own then own:GetAttribute(name) else nil
	if type(raw) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

local function view(): { [string]: any }
	return decode("Rewards")
end

local function playedSeconds(): number
	local own = if ctx then ctx.own() else nil
	local since = if own then own:GetAttribute("OnlineSince") else nil
	return if type(since) == "number" then math.max(0, serverNow() - since) else 0
end

local function wheelSpins(): number
	local own = if ctx then ctx.own() else nil
	local spins = if own then own:GetAttribute("WheelSpins") else nil
	return if type(spins) == "number" then spins else 0
end

-- What the sheet is drawn from: the two JSON attributes the server publishes.
local function signature(): string
	local own = if ctx then ctx.own() else nil
	if not own then
		return ""
	end
	return tostring(own:GetAttribute("Rewards")) .. tostring(own:GetAttribute("Wheel"))
end

local function num(value: any): number
	return if type(value) == "number" then value else 0
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
	local d, h, m, s = seconds // 86400, seconds // 3600 % 24, seconds // 60 % 60, seconds % 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, s)
end

-- 26 -> "26%", 3.5 -> "3.5%"
local function percent(value: number): string
	local text = string.format("%.1f", value)
	return (string.gsub(text, "%.0$", "")) .. "%"
end

local function tickClocks()
	for _, item in clocks do
		item.label.Text = item.text()
	end
end

-- ===== rewards as pictures =====

local function itemsOf(raw: any): { Item }
	local list: { Item } = {}
	if type(raw) == "table" then
		for _, item in raw do
			if type(item) == "table" and type(item.id) == "string" then
				table.insert(list, { kind = tostring(item.kind), id = item.id, count = math.max(1, num(item.count)) })
			end
		end
	end
	return list
end

-- A reward from one of the server's array rows, whose columns sit in different places (old rows keep their order, the
-- new columns come last).
local function fromRow(row: { any }, coins: number, luck: number, spins: number, items: number): Reward
	return { coins = num(row[coins]), luck = num(row[luck]), spins = num(row[spins]), items = itemsOf(row[items]) }
end

-- A reward from one of the server's objects (a milestone, a goal, a wheel slice).
local function fromObject(object: { [string]: any }): Reward
	return {
		coins = num(object.coins),
		luck = num(object.luck),
		spins = num(object.spins),
		items = itemsOf(object.items),
	}
end

-- An item's own picture: a material's icon, a gear piece's tile, a food or dish as its 3D model.
local function itemPicture(parent: Instance, item: Item, size: number, props: UiKit.Props?): GuiObject
	if item.kind == "gear" then
		return UiSmithy.pieceTile(parent, item.id, size, props)
	elseif item.kind == "food" or item.kind == "dish" then
		return UiFood.icon(parent, item.id, size, props)
	end
	return UiDungeon.dropIcon(parent, item.id, size, props)
end

-- A reward's pictures in order: coins, luck minutes, spin tokens, then each item. Several kinds of food (the basket) are
-- one basket picture.
local function partsOf(reward: Reward): { Part }
	local parts: { Part } = {}
	local function add(text: string, picture: (parent: Instance, size: number) -> ())
		table.insert(parts, { picture = picture, text = text })
	end
	if reward.coins > 0 then
		add(short(reward.coins), function(parent, size)
			UiKit.icon(parent, "coins", size, { LayoutOrder = 1 })
		end)
	end
	if reward.luck > 0 then
		add(reward.luck .. "m", function(parent, size)
			UiKit.icon(parent, "luck", size, { LayoutOrder = 1 })
		end)
	end
	if reward.spins > 0 then
		add("x" .. reward.spins, function(parent, size)
			UiKit.icon(parent, "spin", size, { LayoutOrder = 1 })
		end)
	end
	local foods = 0
	for _, item in reward.items do
		if item.kind == "food" then
			foods += 1
		end
	end
	local basket = false
	for _, item in reward.items do
		if item.kind == "food" and foods > 1 then
			if not basket then
				basket = true
				add("", function(parent, size)
					UiKit.icon(parent, "food_basket", size, { LayoutOrder = 1 })
				end)
			end
		else
			add("x" .. item.count, function(parent, size)
				itemPicture(parent, item, size, { LayoutOrder = 1 })
			end)
		end
	end
	return parts
end

-- A reward as pictures and short numbers in a row (wrapping onto more lines when `wraps`).
local function pictures(parent: Instance, reward: Reward, size: number, props: UiKit.Props?, wraps: boolean?): Frame
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
		Wraps = wraps == true,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	for index, part in partsOf(reward) do
		local cell = UiKit.make("Frame", {
			Name = "Part" .. index,
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Size = UDim2.fromOffset(0, size),
			AutomaticSize = Enum.AutomaticSize.X,
		}, row)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, cell)
		part.picture(cell, size)
		if part.text ~= "" then
			UiKit.label(cell, part.text, U.TextSmall, "Brown", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(0, size),
				AutomaticSize = Enum.AutomaticSize.X,
				TextTruncate = Enum.TextTruncate.None,
			})
		end
	end
	return row
end

-- A short card at the top of the screen with what was just won or claimed. `big`: the jackpot's gold card, held longer.
local function showPrize(reward: Reward, big: boolean)
	local root = UiKit.root()
	if prizeCard then
		prizeCard:Destroy()
		prizeCard = nil
	end
	local width = 28
	for _, part in partsOf(reward) do
		width += U.IconNormal + 10 + #part.text * 9
	end
	local group = UiKit.make("CanvasGroup", {
		Name = "Prize",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, U.Edge + U.ChipHeight + U.Gap * 2),
		Size = UDim2.fromOffset(math.clamp(width, 120, UiKit.units(root).X - 2 * U.Edge), U.Touch),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 30,
	}, root) :: CanvasGroup
	prizeCard = group
	local _, body = UiKit.skin(group, "Wood", if big then "GoldLight" else "Card", { Size = UDim2.fromScale(1, 1) })
	pictures(body, reward, U.IconNormal, { Size = UDim2.fromScale(1, 1) })
	prizeToken += 1
	local mine = prizeToken
	UiKit.tween(group, 0.12, { GroupTransparency = 0 })
	task.delay(if big then W.PrizeSeconds else U.ToastSeconds, function()
		if mine ~= prizeToken or not group.Parent then
			return
		end
		UiKit.tween(group, 0.3, { GroupTransparency = 1 }).Completed:Once(function()
			group:Destroy()
			if prizeCard == group then
				prizeCard = nil
			end
		end)
	end)
end

local function claim(data: { [string]: any }, reward: Reward)
	local context = ctx
	if not context then
		return
	end
	context.request(data, function()
		showPrize(reward, false)
	end)
end

-- ===== tiles, rows and lists =====

-- The scrolling list of a page: `bottom` points are left under it (for the foot line). A redraw keeps the tab's old place.
local function scroller(parent: Instance, bottom: number): ScrollingFrame
	local area = UiKit.make("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -bottom),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent) :: ScrollingFrame
	scrolling = area
	local saved = scrolls[tab]
	if saved and saved > 0 then
		area:GetPropertyChangedSignal("AbsoluteCanvasSize"):Once(function()
			area.CanvasPosition = Vector2.new(0, saved)
		end)
	end
	return area
end

local function grid(parent: Instance, bottom: number, width: number): ScrollingFrame
	local area = scroller(parent, bottom)
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

local function tick(parent: Instance, props: UiKit.Props?)
	UiKit.icon(parent, "arenaQuest", U.IconNormal, props)
end

-- A small tile of a grid: a title on top, the reward in the middle, a state line or a Claim button at the foot.
local function tile(
	parent: Instance,
	order: number,
	title: string,
	reward: Reward,
	state: string,
	onClaim: (() -> ())?
): Frame
	local fill = if state == "ready" then "GoldLight" elseif state == "taken" then "CardDeep" else "Card"
	local box, body = UiKit.skin(parent, "Wood", fill, { Name = "Tile" .. order, LayoutOrder = order })
	UiKit.label(body, title, U.TextSmall, "Brown", {
		Size = UDim2.new(1, 0, 0, U.TextSmall + 4),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	-- the reward's pictures wrap into the space between the title and the foot
	local top = U.TextSmall + 6
	local foot = U.TextSmall + 10
	pictures(body, reward, R.TilePartIcon, {
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top - foot),
	}, true)
	local at = UDim2.new(0, 0, 1, -foot)
	if state == "ready" then
		UiKit.label(body, "Claim!", U.TextSmall, "GreenDark", {
			Name = "State",
			Position = at,
			Size = UDim2.new(1, 0, 0, U.TextSmall + 8),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	elseif state == "taken" then
		tick(body, { Name = "State", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2) })
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

-- One row of a list: picture, text, progress bar, the reward's pictures, a Reroll button when asked and the Claim button (a
-- green tick once taken). On a narrow screen the reward and buttons sit on a second line.
local function listRow(parent: Instance, spec: RowSpec): Frame
	local narrow = narrowSheet
	local box, body = UiKit.skin(
		parent,
		"Wood",
		if spec.state == 2 then "CardDeep" elseif spec.state == 1 then "GoldLight" else "Card",
		{
			Name = spec.name,
			LayoutOrder = spec.order,
			Size = UDim2.new(1, -8, 0, if narrow then R.QuestRowHeightNarrow else R.QuestRowHeight),
		}
	)
	local picture = if narrow then 32 else 38
	UiKit.icon(body, spec.icon, picture, {
		AnchorPoint = Vector2.new(0, if narrow then 0 else 0.5),
		Position = if narrow then UDim2.fromOffset(0, 2) else UDim2.fromScale(0, 0.5),
	})
	-- what sits at the right: reward, Reroll, Claim
	local sideWidth = R.RewardWidth + R.ClaimWidth + U.Gap * 2 + (if spec.onReroll then U.Touch + U.Gap else 0)
	local side = UiKit.make("Frame", {
		Name = "Side",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, if narrow then 1 else 0.5),
		Position = if narrow then UDim2.fromScale(1, 1) else UDim2.fromScale(1, 0.5),
		Size = if narrow then UDim2.new(1, 0, 0, U.Touch) else UDim2.new(0, sideWidth, 1, 0),
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, side)
	pictures(side, spec.reward, R.RowPartIcon, {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(R.RewardWidth, R.RowPartIcon * 2 + 4),
	}, true)
	if spec.onReroll then
		UiKit.button(side, {
			Name = "Reroll",
			Icon = "quest_reroll",
			IconSize = U.IconNormal + 4,
			Style = "secondary",
			LayoutOrder = 2,
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			OnClick = spec.onReroll,
		})
	end
	if spec.state == 2 then
		local holder = UiKit.make("Frame", {
			Name = "Taken",
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Size = UDim2.fromOffset(R.ClaimWidth, U.Touch),
		}, side)
		tick(holder, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	else
		UiKit.button(side, {
			Name = "Claim",
			Text = "Claim",
			Style = if spec.state == 1 then "good" else "secondary",
			Enabled = spec.state == 1,
			LayoutOrder = 3,
			Size = UDim2.fromOffset(R.ClaimWidth, U.Touch),
			OnClick = spec.onClaim,
		})
	end
	-- the text and the bar, between the picture and the side (on top of the second line when narrow)
	local left = picture + U.Gap
	local right = if narrow then 0 else sideWidth + U.Gap
	if spec.need > 0 then
		UiKit.label(body, spec.text, U.TextSmall, "Brown", {
			Position = UDim2.fromOffset(left, if narrow then 0 else 4),
			Size = UDim2.new(1, -left - right, 0, U.TextSmall + 4),
		})
		local countWidth = 52
		local bar = UiKit.bar(body, "", if spec.state > 0 then "Green" else "GoldLight", {
			Position = UDim2.fromOffset(left, if narrow then U.TextSmall + 8 else U.TextSmall + 10),
			Size = UDim2.new(1, -left - right - countWidth, 0, U.IconSmall),
		})
		bar.set(spec.have / math.max(1, spec.need), false)
		UiKit.label(body, short(spec.have) .. "/" .. short(spec.need), U.TextTiny, "BrownSoft", {
			Position = UDim2.new(1, -right - countWidth + 4, 0, if narrow then U.TextSmall + 8 else U.TextSmall + 10),
			Size = UDim2.fromOffset(countWidth - 4, U.IconSmall),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	else
		UiKit.label(body, spec.text, U.TextNormal, "Brown", {
			Position = UDim2.fromOffset(left, 0),
			Size = if narrow then UDim2.new(1, -left, 0, picture) else UDim2.new(1, -left - right, 1, 0),
		})
	end
	return box
end

-- A quest row from the server's array row: { text, progress, need, claimed, coins, kind, luck, spins, items }.
local function questRow(
	parent: Instance,
	order: number,
	row: { any },
	claimData: { [string]: any },
	reroll: (() -> ())?
)
	local have, need, claimed = num(row[2]), num(row[3]), row[4] == true
	local reward = fromRow(row, 5, 7, 8, 9)
	listRow(parent, {
		name = "Quest" .. order,
		order = order,
		icon = QUEST_ICON[tostring(row[6])] or "slimes",
		text = tostring(row[1]),
		have = have,
		need = need,
		reward = reward,
		state = if claimed then 2 elseif have >= need then 1 else 0,
		onClaim = function()
			claim(claimData, reward)
		end,
		onReroll = if claimed then nil else reroll,
	})
end

-- The row under a set of quests that pays once all are claimed (the day's bonus, the week's chest): { state, coins, luck,
-- spins, items }.
local function bonusRow(parent: Instance, order: number, icon: string, row: { any }, claimData: { [string]: any })
	local reward = fromRow(row, 2, 3, 4, 5)
	listRow(parent, {
		name = "Bonus",
		order = order,
		icon = icon,
		text = "",
		have = 0,
		need = 0,
		reward = reward,
		state = num(row[1]),
		onClaim = function()
			claim(claimData, reward)
		end,
	})
end

-- ===== the tabs =====

local function drawDaily(host: Frame, data: { [string]: any })
	local rows = data.daily or {}
	local today = data.day or 1
	local taken = data.taken == true
	local area = grid(host, U.TextSmall + 10, R.TileWidth)
	for day, row in rows do
		local state = if day < today or (day == today and taken)
			then "taken"
			elseif day == today then "ready"
			else "later"
		local reward = fromRow(row, 1, 2, 3, 4)
		tile(area, day, "Day " .. day, reward, state, function()
			claim({ action = "ClaimDaily" }, reward)
		end)
	end
	-- the cell after the seventh day: how many check-ins in all (the milestones below count them)
	local _, body = UiKit.skin(area, "Wood", "Card", { Name = "Checkins", LayoutOrder = #rows + 1 })
	UiKit.icon(body, "daily", R.TileHeight - 56, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
	})
	UiKit.label(body, tostring(num(data.checkins)), U.TextHeader, "Brown", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, U.TextHeader + 6),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	for index, milestone in data.milestones or {} do
		local reward = fromObject(milestone)
		local state = if milestone.state == 1 then "ready" elseif milestone.state == 2 then "taken" else "later"
		tile(area, #rows + 1 + index, num(milestone.total) .. " days", reward, state, function()
			claim({ action = "ClaimMilestone", index = index }, reward)
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
	local list = scroller(host, U.TextSmall + 10)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local quests = data.quests or {}
	if #quests == 0 then
		UiKit.label(list, "New quests come soon.", U.TextNormal, "BrownSoft", {
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	for index, row in quests do
		-- (the free redraw: the server says whether the day's one is still there; a quest already done keeps its claim)
		local reroll: (() -> ())? = nil
		if data.rerollFree == true and row[4] ~= true and (tonumber(row[2]) or 0) < (tonumber(row[3]) or 0) then
			reroll = function()
				if ctx then
					ctx.request({ action = "RerollQuest", index = index })
				end
			end
		end
		questRow(list, index, row, { action = "ClaimQuest", index = index }, reroll)
	end
	if #quests > 0 and data.bonus then
		bonusRow(list, 99, "rewards", data.bonus, { action = "ClaimQuestBonus" })
	end
	footLine(host, function()
		return "New quests in " .. clock((data.reset or 0) - serverNow())
	end)
end

local function drawWeekly(host: Frame, data: { [string]: any })
	local weekly = data.weekly or {}
	local list = scroller(host, U.TextSmall + 10)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local quests = weekly.quests or {}
	for index, row in quests do
		questRow(list, index, row, { action = "ClaimWeekly", index = index })
	end
	if #quests > 0 and weekly.chest then
		bonusRow(list, 99, "weekly_chest", weekly.chest, { action = "ClaimWeeklyChest" })
	end
	footLine(host, function()
		return "New week in " .. clock(num(weekly.reset) - serverNow())
	end)
end

local function drawGoals(host: Frame, data: { [string]: any })
	local list = scroller(host, 0)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	for index, goal in data.goals or {} do
		local reward = fromObject(goal)
		listRow(list, {
			name = "Goal" .. index,
			order = index,
			icon = GOAL_ICON[tostring(goal.kind)] or "slimes",
			text = tostring(goal.text),
			have = num(goal.progress),
			need = num(goal.need),
			reward = reward,
			state = num(goal.state),
			onClaim = function()
				claim({ action = "ClaimGoal", id = goal.id }, reward)
			end,
		})
	end
end

local function drawOnline(host: Frame, data: { [string]: any })
	local area = grid(host, U.TextSmall + 10, R.OnlineTileWidth)
	local played = playedSeconds()
	for step, row in data.online or {} do
		local minutes, taken = num(row[1]), row[4] == true
		local reward = fromRow(row, 2, 3, 5, 6)
		local state = if taken then "taken" elseif played >= minutes * 60 then "ready" else "later"
		local box = tile(area, step, minutes .. " min", reward, state, function()
			claim({ action = "ClaimOnline", step = step }, reward)
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

-- ===== the Lucky Wheel =====

-- A slice's prize picture: its own (a pouch, a basket, a potion) or its first item's, else what it pays.
local function slicePicture(parent: Instance, slice: { [string]: any }, size: number, props: UiKit.Props?): GuiObject
	local named = (W.SliceIcons :: any)[tostring(slice.id)]
	if named then
		return UiKit.icon(parent, named, size, props)
	end
	local reward = fromObject(slice)
	local item = reward.items[1]
	if item then
		return itemPicture(parent, item, size, props)
	elseif reward.spins > 0 then
		return UiKit.icon(parent, "spin", size, props)
	elseif reward.luck > 0 then
		return UiKit.icon(parent, "luck", size, props)
	end
	return UiKit.icon(parent, "coins", size, props)
end

-- A point of the screen's scaled root where the centre of a gui object is.
local function rootPoint(inst: GuiObject): Vector2
	local root = UiKit.root()
	local scale = root.AbsoluteSize.X / math.max(UiKit.units(root).X, 1)
	return (inst.AbsolutePosition + inst.AbsoluteSize / 2 - root.AbsolutePosition) / scale
end

-- The jackpot's celebration over the wheel: the hatch reveal's golden sunburst turns and fades, and its stars fly out. Pictures
-- of the owner's art only; a few of them and one tween each, so it is light on a phone.
local function celebrate(anchor: Frame?)
	if not anchor or not anchor.Parent then
		return
	end
	local root = UiKit.root()
	local scale = root.AbsoluteSize.X / math.max(UiKit.units(root).X, 1)
	local size = anchor.AbsoluteSize.X / scale
	local J = W.Jackpot
	local holder = UiKit.make("Frame", {
		Name = "Jackpot",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(rootPoint(anchor).X, rootPoint(anchor).Y),
		Size = UDim2.new(),
		ZIndex = 25,
	}, root)
	local textures = Config.HatchFx.Textures
	local sun = UiKit.make("ImageLabel", {
		Name = "Sunburst",
		BackgroundTransparency = 1,
		Image = textures.sunburst,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ImageColor3 = Color3.fromHex(U.Colours.GoldLight),
		Size = UDim2.fromOffset(size * 0.4, size * 0.4),
		ZIndex = 25,
	}, holder)
	UiKit.tween(sun, J.Seconds, {
		Size = UDim2.fromOffset(size * J.SunSize, size * J.SunSize),
		Rotation = J.SunTurn,
		ImageTransparency = 1,
	})
	for index = 1, J.Stars do
		local angle = (index - 1) / J.Stars * math.pi * 2 + math.random() * 0.4
		local reach = size * J.StarReach * (0.7 + math.random() * 0.3)
		local star = UiKit.make("ImageLabel", {
			Name = "Star",
			BackgroundTransparency = 1,
			Image = textures.star,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageColor3 = Color3.fromHex(U.Colours.GoldLight),
			Size = UDim2.fromOffset(J.StarSize * 0.5, J.StarSize * 0.5),
			ZIndex = 26,
		}, holder)
		UiKit.tween(star, J.Seconds, {
			Position = UDim2.fromOffset(math.cos(angle) * reach, math.sin(angle) * reach),
			Size = UDim2.fromOffset(J.StarSize, J.StarSize),
			Rotation = 90,
			ImageTransparency = 1,
		})
	end
	Debris:AddItem(holder, J.Seconds + 0.3)
end

-- Turns the wheel so slice `index` ends under the pointer (12 o'clock): W.SpinTurns full turns, slowing to a stop, landing a
-- little off the slice's middle as a real wheel does. The server has already rolled and paid; this is only the show.
local function turn(index: number, count: number, onDone: () -> ())
	local step = 360 / count
	local aim = (360 - (index - 1) * step) % 360 + (math.random() * 2 - 1) * step / 2 * W.Landing
	local from = wheelAngle
	local final = from + W.SpinTurns * 360 + (aim - from) % 360
	-- (a sheet drawn again during the spin shows the wheel where it will stop)
	wheelAngle = final % 360
	if face then
		UiKit.tween(face, W.SpinSeconds, { Rotation = final }, Enum.EasingStyle.Quart)
	end
	task.delay(W.SpinSeconds + 0.1, onDone)
end

local render: () -> ()

local function startSpin()
	local context = ctx
	if spinning or not context then
		return
	end
	local wheel = decode("Wheel")
	if num(wheel.free) + num(wheel.bank) <= 0 or type(wheel.slices) ~= "table" then
		return
	end
	-- (what the wheel looked like when it was asked: the prize is shown from this, not from the next look)
	local slices: { any } = wheel.slices
	spinning = true
	-- (drawn again at once: the hub greys, and `stage` and `face` are the ones that turn)
	if tab == "wheel" then
		render()
	end
	local anchor = stage
	local function over()
		spinning = false
		render()
	end
	context.ask({ action = "WheelSpin" }, function(value: any)
		local index = if type(value) == "number" then math.floor(value) else 0
		local slice = slices[index]
		if type(slice) ~= "table" then
			over()
			return
		end
		turn(index, #slices, function()
			local jackpot = slice.id == W.JackpotId
			spinning = false
			showPrize(fromObject(slice), jackpot)
			if jackpot then
				celebrate(anchor)
			end
			render()
		end)
	end, over)
end

-- The odds: each slice's prize and its chance, in the order of the wheel.
local function drawOdds(host: Frame, slices: { any })
	local top = U.Touch + U.Gap
	UiKit.button(host, {
		Name = "Back",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		OnClick = function()
			showOdds = false
			render()
		end,
	})
	UiKit.label(host, "Odds", U.TextHeader, "Brown", {
		Position = UDim2.fromOffset(U.Touch + U.Gap, 0),
		Size = UDim2.new(1, -U.Touch - U.Gap, 0, U.Touch),
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local holder = UiKit.make("Frame", {
		Name = "OddsList",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top),
	}, host)
	local list = scroller(holder, 0)
	UiKit.make("UIGridLayout", {
		CellSize = UDim2.new(if narrowSheet then 1 else 0.5, -8, 0, W.OddsRow),
		CellPadding = UDim2.fromOffset(U.Gap, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	for index, slice in slices do
		local _, body = UiKit.skin(list, "Wood", "Card", { Name = "Odd" .. index, LayoutOrder = index })
		local picture = W.OddsRow - 2 * U.Kit.square.Inset - 4
		slicePicture(body, slice, picture, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) })
		UiKit.label(body, percent(num(slice.chance)), U.TextNormal, "Brown", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(60, U.TextNormal + 6),
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		local left = picture + U.Gap
		pictures(body, fromObject(slice), R.RowPartIcon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, left, 0.5, 0),
			Size = UDim2.new(1, -left - 64, 1, 0),
		}, true)
	end
end

local function countRow(parent: Instance, text: string, order: number)
	local row = UiKit.make("Frame", {
		Name = "Count" .. order,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, U.IconNormal + 2),
	}, parent)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	UiKit.icon(row, "spin", U.IconNormal, { LayoutOrder = 1 })
	UiKit.label(row, text, U.TextNormal, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
	})
end

local function drawWheel(host: Frame)
	local wheel = decode("Wheel")
	local slices: { any } = if type(wheel.slices) == "table" then wheel.slices else {}
	if #slices == 0 then
		return
	end
	if showOdds then
		drawOdds(host, slices)
		return
	end
	local free, freeMax, bank = num(wheel.free), num(wheel.freeMax), num(wheel.bank)
	local usable = free + bank > 0 and not spinning
	local share = if narrowSheet then W.NarrowShare else W.Share
	local design = W.Design

	-- the wheel's stage: a fixed picture of Design points, scaled to the room
	local holder = UiKit.make("Frame", {
		Name = "Wheel",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(share, 1),
	}, host)
	local board = UiKit.make("Frame", {
		Name = "Stage",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(design, design),
	}, holder) :: Frame
	local scale = UiKit.make("UIScale", nil, board) :: UIScale
	local function fit()
		local room = UiKit.units(holder)
		if room.X > 0 and room.Y > 0 then
			scale.Scale = math.clamp(math.min(room.X, room.Y - 12) / design, 0.4, W.ScaleMax)
		end
	end
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	stage = board

	local picture = UiKit.icon(board, "wheel_face", design, {
		Name = "Face",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Rotation = wheelAngle,
		ZIndex = 1,
	}) :: ImageLabel
	face = picture
	-- each slice's prize on its slice: slice 1 at 12 o'clock, then clockwise, turned to point outward with the wheel
	local step = 360 / #slices
	for index, slice in slices do
		local angle = (index - 1) * step
		local radians = math.rad(angle)
		local cell = UiKit.make("Frame", {
			Name = "Slice" .. index,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(
				0.5 + W.SliceIconRadius * math.sin(radians),
				0.5 - W.SliceIconRadius * math.cos(radians)
			),
			Size = UDim2.fromScale(W.SliceIconSize, W.SliceIconSize),
			Rotation = angle,
			ZIndex = 2,
		}, picture)
		slicePicture(cell, slice, design * W.SliceIconSize, { Size = UDim2.fromScale(1, 1) })
	end
	UiKit.icon(board, "wheel_pointer", design * W.PointerSize, {
		Name = "Pointer",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, design * W.PointerTip),
		ZIndex = 4,
	})
	-- the hub is the SPIN button: "Free" while a free spin is there, else how many are banked
	local hubSize = design * W.HubSize
	local hubId = (U.Icons :: any).wheel_hub
	local hub = UiKit.make("ImageButton", {
		Name = "Spin",
		BackgroundTransparency = 1,
		Image = "rbxassetid://" .. tostring(hubId),
		ImageTransparency = if usable then 0 else U.DisabledTransparency,
		ScaleType = Enum.ScaleType.Fit,
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(hubSize, hubSize),
		ZIndex = 3,
	}, board) :: ImageButton
	local pop = UiKit.make("UIScale", nil, hub) :: UIScale
	hub.MouseButton1Down:Connect(function()
		if usable then
			UiKit.tween(pop, 0.06, { Scale = U.PressScale })
		end
	end)
	hub.MouseButton1Up:Connect(function()
		UiKit.tween(pop, 0.08, { Scale = 1 })
	end)
	hub.MouseLeave:Connect(function()
		UiKit.tween(pop, 0.08, { Scale = 1 })
	end)
	local word = UiKit.label(hub, if free > 0 then "Free" else tostring(bank), U.TextNormal, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 4,
	})
	UiKit.outline(word, true)
	hub.Activated:Connect(function()
		if usable then
			startSpin()
		end
	end)

	-- beside the wheel: the spins left, when the free ones come back, and the odds
	local side = UiKit.make("Frame", {
		Name = "Side",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(share, 0),
		Size = UDim2.fromScale(1 - share, 1),
	}, host)
	UiKit.make("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap + 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, side)
	countRow(side, "Free " .. free .. "/" .. freeMax, 1)
	countRow(side, "Bank " .. short(bank), 2)
	if free < freeMax then
		local reset = num(wheel.reset)
		local label = UiKit.label(side, "", U.TextSmall, "BrownSoft", {
			Name = "Clock",
			LayoutOrder = 3,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local function text(): string
			return "Free in " .. clock(reset - serverNow())
		end
		label.Text = text()
		table.insert(clocks, { label = label, text = text })
	end
	UiKit.button(side, {
		Name = "Odds",
		Text = "Odds",
		Style = "secondary",
		Enabled = not spinning,
		LayoutOrder = 4,
		Size = UDim2.fromOffset(W.OddsButtonWidth, U.Touch),
		OnClick = function()
			showOdds = true
			render()
		end,
	})
end

-- ===== the sheet =====

-- Which tabs have something to take (they get a red dot, and the sheet opens on the first of them).
local function readyTabs(data: { [string]: any }): { [string]: boolean }
	local ready: { [string]: boolean } = {}
	local function quests(rows: any): boolean
		for _, row in rows or {} do
			if row[4] ~= true and num(row[2]) >= num(row[3]) then
				return true
			end
		end
		return false
	end
	local milestone = false
	for _, entry in data.milestones or {} do
		if entry.state == 1 then
			milestone = true
		end
	end
	ready.daily = data.taken == false or milestone
	ready.quests = quests(data.quests) or (data.bonus ~= nil and data.bonus[1] == 1)
	local weekly = data.weekly or {}
	ready.weekly = quests(weekly.quests) or (weekly.chest ~= nil and weekly.chest[1] == 1)
	local goal = false
	for _, entry in data.goals or {} do
		if entry.state == 1 then
			goal = true
		end
	end
	ready.goals = goal
	local played = playedSeconds()
	for _, row in data.online or {} do
		if row[4] ~= true and played >= num(row[1]) * 60 then
			ready.online = true
		end
	end
	ready.wheel = wheelSpins() > 0
	return ready
end

-- The red dot on each tab that has something to take.
local function updateDots(data: { [string]: any })
	local frame = tabsFrame
	if not frame then
		return
	end
	local ready = readyTabs(data)
	for _, item in TABS do
		local button = frame:FindFirstChild(item.id)
		if button then
			local dot = button:FindFirstChild("Dot") :: Frame?
			if not dot then
				dot = UiKit.make("Frame", {
					Name = "Dot",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -2, 0, 2),
					Size = UDim2.fromOffset(R.TabDot, R.TabDot),
					BackgroundColor3 = UiKit.colour("Red"),
					BorderSizePixel = 0,
					ZIndex = 5,
				}, button) :: Frame
				UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
				UiKit.make("UIStroke", { Color = UiKit.colour("Cream"), Thickness = 2 }, dot)
			end
			if dot then
				dot.Visible = ready[item.id] == true
			end
		end
	end
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

render = function()
	local host = content
	if not host then
		return
	end
	if scrolling and scrolling.Parent then
		scrolls[drawnTab] = scrolling.CanvasPosition.Y
	end
	scrolling, stage, face = nil, nil, nil
	table.clear(clocks)
	UiKit.clear(host)
	local data = view()
	drawnFrom = signature()
	drawnReady = openGifts(data)
	drawnTab = tab
	updateDots(data)
	if tab == "quests" then
		drawQuests(host, data)
	elseif tab == "weekly" then
		drawWeekly(host, data)
	elseif tab == "goals" then
		drawGoals(host, data)
	elseif tab == "online" then
		drawOnline(host, data)
	elseif tab == "wheel" then
		drawWheel(host)
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
	-- the first tab with something to take comes first
	local ready = readyTabs(view())
	for _, item in TABS do
		if ready[item.id] then
			tab = item.id
			break
		end
	end
	showOdds = false
	narrowSheet = UiKit.units(UiKit.root()).X < R.SheetWidth + 2 * U.Edge
	local modal = UiKit.openModal("rewards", {
		Width = R.SheetWidth,
		Height = R.SheetHeight,
		OnClose = function()
			content, tabsFrame = nil, nil
			scrolling, stage, face = nil, nil, nil
			table.clear(clocks)
			table.clear(scrolls)
			drawnTab = ""
		end,
	})
	local items = {}
	for _, item in TABS do
		table.insert(items, { id = item.id, icon = item.icon })
	end
	local function choose(id: string)
		if id ~= tab then
			showOdds = false
		end
		tab = id
		render()
	end
	if narrowSheet then
		-- no room in the header: the tabs are the first row of the page, a little narrower than a touch square each
		local box = modal.content
		tabsFrame = UiKit.segmented(box, items, tab, choose, {
			Name = "Tabs",
			ItemWidth = 44,
			Size = UDim2.new(1, 0, 0, U.Touch),
		})
		local below = U.Touch + U.Gap
		content = UiKit.make("Frame", {
			Name = "Page",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, below),
			Size = UDim2.new(1, 0, 1, -below),
		}, box)
	else
		UiKit.icon(modal.header, "rewards", U.Touch - 8, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
		})
		tabsFrame = UiKit.segmented(modal.header, items, tab, choose, {
			Name = "Tabs",
			Position = UDim2.fromOffset(U.Touch, 0),
			Size = UDim2.new(1, -U.Touch, 1, 0),
		})
		content = modal.content
	end
	render()
end

-- Called when the village folder's rewards change, and once a second.
function UiRewards.refresh()
	if not UiRewards.isOpen() then
		return
	end
	-- (a wheel on its way is not drawn again: it would stop short, and the next look would give the prize away)
	if spinning and tab == "wheel" then
		tickClocks()
		return
	end
	local data = view()
	if signature() ~= drawnFrom or openGifts(data) ~= drawnReady then
		render()
	else
		updateDots(data)
		tickClocks()
	end
end

function UiRewards.start(context: Context)
	ctx = context
end

return UiRewards
