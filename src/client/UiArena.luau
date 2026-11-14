--!strict
-- The Arena sheet (docs/DESIGN.md, the PvP ladder): one modal with five tabs, icons first. Battle (your rank, tickets, five rivals to
-- attack), Team (the slimes that fight for you), Ranking (the season's top and you), Shop (what Arena points buy) and Records
-- (quests, defence, the log). It asks the server through Remotes.Arena (a RemoteFunction: { action = ... } -> { ok, reason?, ... })
-- and draws the answers; every rule is the server's, so a button it would refuse is greyed. An attack closes the sheet, plays the
-- fight (ArenaReplay) and shows a result card; the points and the new rank appear only when a later `state` shows the match
-- confirmed. Opened from the Arena round button on the HUD (UiHud) and from the debug menu (UiArena.open). The fight is
-- drawn on the Arena scene each client copies for itself (ArenaStage). Every word is English.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local ArenaReplay = require(script.Parent.ArenaReplay)
local ArenaStage = require(script.Parent.ArenaStage)
local UiDungeon = require(script.Parent.UiDungeon)
local UiKit = require(script.Parent.UiKit)
local UiSlimeList = require(script.Parent.UiSlimeList)
local UiSlimes = require(script.Parent.UiSlimes)
local UiSmithy = require(script.Parent.UiSmithy)
local ZombieTeams = require(script.Parent.ZombieTeams)

local U = Config.Ui
local A = Config.Arena
local W = A.View

type Json = { [string]: any }

local UiArena = {}
-- the last `state` the server gave, and when (os.clock) it came; the rivals offered, when they came
local state: Json? = nil
local stateAt = 0
local opp: Json? = nil
local oppAt = 0
local tab = "battle"
-- bumped when the sheet opens or closes and on every tab change: an answer that arrives after that is not drawn
local drawToken = 0
local sheetId = 0
local page: Frame? = nil
local cleanups: { () -> () } = {}
local ticks: { () -> () } = {}
local headerRank: TextLabel? = nil
local headerPoints: UiKit.Chip? = nil
local attacking = false
local buying = false
local resultToken = 0

local REASONS: { [string]: string } = {
	NOT_READY = "Still loading. Try again.",
	RATE_LIMIT = "Slow down a little.",
	BAD_REQUEST = "Something went wrong.",
	NO_ACCOUNT = "No account found.",
	BUSY = "The Arena is busy. Try again.",
	SERVER_ERROR = "Something went wrong.",
	NO_LADDER = "The ladder is not ready yet.",
	NO_LOG = "No fights yet.",
	IN_DUNGEON = "Finish your Dungeon run first.",
	NO_TEAM = "Pick an Arena team first.",
	NO_TICKETS = "No tickets left today.",
	SEASON_ENDING = "The season is ending.",
	NOT_OFFERED = "That rival is gone. Refresh.",
	PENDING = "A match is still confirming.",
	DONE = "That match is already done.",
	BAD_TEAM = "That team cannot fight.",
	TEAM_SIZE = "Pick 1 to " .. A.TeamSize .. " slimes.",
	DUPLICATE = "A slime is picked twice.",
	NOT_OWNED = "You do not own that slime.",
	GHOST = "A fallen slime cannot fight.",
	UNKNOWN_ITEM = "That item is gone.",
	SOLD_OUT = "Sold out this week.",
	NO_POINTS = "Not enough Arena points.",
	NO_ANSWER = "No answer from the server.",
	EXPLORING = "A fighter is out exploring",
}

local TABS = {
	{ id = "battle", icon = "attack" },
	{ id = "team", icon = "slimes" },
	{ id = "ranking", icon = "rewards" },
	{ id = "shop", icon = "market" },
	{ id = "records", icon = "quests" },
}

local function reasonText(reason: any): string
	return REASONS[if type(reason) == "string" then reason else ""] or "Something went wrong."
end

local function arr(value: any): { any }
	return if type(value) == "table" then value else {}
end

local function num(value: any, default: number): number
	return if type(value) == "number" and value == value then value else default
end

-- 1234 -> "1.2K"
local function short(amount: number): string
	if amount >= 1_000_000 then
		return string.format("%.1fM", amount / 1_000_000)
	elseif amount >= 100_000 then
		return string.format("%.0fK", amount / 1000)
	end
	return UiKit.money(amount)
end

-- 12d 4h, 5h 12m, 4:05
local function span(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local d, h, m = seconds // 86400, seconds // 3600 % 24, seconds // 60 % 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, seconds % 60)
end

local function rankText(rank: any): string
	return if type(rank) == "number" and rank >= 1 then "#" .. tostring(math.floor(rank)) else "-"
end

local function serverNow(): number
	local s = state
	if s and type(s.now) == "number" then
		return s.now + (os.clock() - stateAt)
	end
	return workspace:GetServerTimeNow()
end

local function live(token: number): boolean
	return token == drawToken and UiKit.modalId() == "arena"
end

-- ===== Asking the server =====

local function remote(): RemoteFunction?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild("Arena") else nil
	return if found and found:IsA("RemoteFunction") then found else nil
end

-- Blocks the thread it runs in (always inside task.spawn). A call that got no answer is sent once more with the same data, so
-- the same request id: the server answers a repeat with the first answer.
local function call(data: Json): Json
	for attempt = 1, 2 do
		local r = remote()
		if r then
			local ok, answer = pcall(function(): any
				return r:InvokeServer(data)
			end)
			if ok and type(answer) == "table" then
				return answer
			end
		end
		if attempt == 1 then
			task.wait(W.RetrySeconds)
		end
	end
	return { ok = false, reason = "NO_ANSWER" }
end

local function fetchState(onDone: ((Json) -> ())?)
	task.spawn(function()
		local answer = call({ action = "state" })
		if answer.ok == true then
			state = answer
			stateAt = os.clock()
		end
		if onDone then
			onDone(answer)
		end
	end)
end

-- ===== Small drawing helpers =====

-- A picture and a short number side by side.
local function stat(parent: Instance, icon: string, text: string, props: UiKit.Props?): (Frame, TextLabel)
	local row = UiKit.make("Frame", {
		Name = "Stat_" .. icon,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, U.IconSmall + 4),
		AutomaticSize = Enum.AutomaticSize.X,
	}, parent)
	if props then
		for key, value in props do
			(row :: any)[key] = value
		end
	end
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	UiKit.icon(row, icon, U.IconSmall, { LayoutOrder = 1 })
	local label = UiKit.label(row, text, U.TextSmall, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	return row, label
end

local function scroller(parent: Instance, props: UiKit.Props?): ScrollingFrame
	local frame = UiKit.make("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent)
	if props then
		for key, value in props do
			(frame :: any)[key] = value
		end
	end
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, frame)
	return frame
end

local function note(parent: Instance, text: string, order: number?): TextLabel
	return UiKit.label(parent, text, U.TextNormal, "BrownSoft", {
		LayoutOrder = order or 1,
		Size = UDim2.new(1, 0, 0, U.Touch),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
end

-- A line that counts on: `text` is looked at every second while the tab is on the screen.
local function clockLabel(label: TextLabel, text: () -> string)
	label.Text = text()
	table.insert(ticks, function()
		label.Text = text()
	end)
end

local function paintHeader()
	local s = state
	local rank = headerRank
	if rank and rank.Parent then
		rank.Text = rankText(if s then s.rank else nil)
	end
	local points = headerPoints
	if points and points.root.Parent then
		points.set(short(num(if s then s.points else nil, 0)))
	end
end

local showTab: (id: string) -> ()

-- ===== Battle =====

local function result(answer: Json, rankBefore: number?)
	resultToken += 1
	local token = resultToken
	local won = answer.won == true
	local matchId = answer.matchId
	local modal = UiKit.openModal("arena_result", {
		Width = W.ResultWidth,
		Height = W.ResultHeight,
		OnClose = function()
			resultToken += 1
		end,
	})
	UiKit.icon(modal.header, "arena", U.Touch - 8, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	})
	local column = UiKit.make(
		"Frame",
		{ Name = "Result", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) },
		modal.content
	)
	UiKit.make("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, U.Gap * 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, column)
	local title =
		UiKit.label(column, if won then "Victory!" else "Defeat", W.ResultTextSize, if won then "Green" else "Red", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, W.ResultTextSize + 10),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.fromHex(U.KitOutline)
	local detail = UiKit.make("Frame", {
		Name = "Detail",
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, U.Touch * 2),
	}, column)
	UiKit.make("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, detail)

	local function waiting(text: string, spinning: boolean)
		UiKit.clear(detail)
		local row = UiKit.make("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, U.IconNormal),
		}, detail)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, U.Gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)
		if spinning then
			UiKit.icon(row, "again", U.IconNormal, { LayoutOrder = 1 })
		end
		UiKit.label(row, text, U.TextNormal, "BrownSoft", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
		})
	end
	waiting("Confirming...", true)

	local function confirmed(entry: Json)
		UiKit.clear(detail)
		local newRank = num(entry.rank, 0)
		local rankRow = UiKit.make("Frame", {
			Name = "Rank",
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, U.IconNormal + 4),
		}, detail)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, U.Gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, rankRow)
		UiKit.icon(rankRow, "arena", U.IconNormal, { LayoutOrder = 1 })
		local changed = rankBefore ~= nil and rankBefore ~= newRank
		if changed then
			UiKit.label(rankRow, rankText(rankBefore), U.TextHeader, "BrownSoft", {
				LayoutOrder = 2,
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
			})
			UiKit.icon(rankRow, "pointer", U.IconNormal - 6, { LayoutOrder = 3, Rotation = 180 })
		end
		UiKit.label(
			rankRow,
			rankText(newRank),
			U.TextHeader,
			if changed and rankBefore and newRank > 0 and newRank < rankBefore then "Green" else "Brown",
			{
				LayoutOrder = 4,
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
			}
		)
		local points = num(entry.points, 0)
		local row, label = stat(detail, "arenaPoints", "+" .. UiKit.money(points), { LayoutOrder = 2 })
		label.TextSize = U.TextNormal
		row.Size = UDim2.fromOffset(0, U.IconNormal)
	end

	task.spawn(function()
		local started = os.clock()
		while token == resultToken and os.clock() - started < W.PollMaxSeconds do
			task.wait(W.PollSeconds)
			if token ~= resultToken then
				return
			end
			local looked = call({ action = "state" })
			if token ~= resultToken then
				return
			end
			if looked.ok == true then
				state = looked
				stateAt = os.clock()
				local pending = looked.pending
				local same = type(pending) == "table" and pending.matchId == matchId
				if not same then
					-- the match is settled: its line in the log says what it gave (the line may lag a moment behind the state)
					local entry: Json? = nil
					for _ = 1, 2 do
						local log = call({ action = "log" })
						local lines = arr(log.log)
						for index = #lines, 1, -1 do
							local line = lines[index]
							if type(line) == "table" and line.matchId == matchId then
								entry = line
								break
							end
						end
						if entry or token ~= resultToken then
							break
						end
						task.wait(W.RetrySeconds)
					end
					if token ~= resultToken then
						return
					end
					if entry then
						confirmed(entry)
					else
						waiting("Match cancelled", false)
					end
					return
				end
			end
		end
		if token == resultToken then
			waiting("Still confirming", true)
		end
	end)
	UiKit.button(modal.content, {
		Name = "ToArena",
		Icon = "arena",
		IconSize = U.IconNormal,
		Style = "primary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		OnClick = function()
			UiArena.open()
		end,
	})
end

local function startAttack(entry: Json)
	if attacking then
		return
	end
	attacking = true
	local s = state
	local rankBefore: number? = if s and type(s.rank) == "number" then s.rank else nil
	local requestId = HttpService:GenerateGUID(false)
	task.spawn(function()
		local answer = call({ action = "attack", target = entry.id, requestId = requestId })
		if answer.ok ~= true then
			attacking = false
			UiKit.toast(reasonText(answer.reason))
			if answer.reason == "PENDING" or answer.reason == "NOT_OFFERED" then
				opp = nil
				fetchState(function()
					if UiKit.modalId() == "arena" then
						paintHeader()
						showTab(tab)
					end
				end)
			end
			return
		end
		-- (the rivals on offer are new ones next time)
		opp = nil
		if UiKit.modalId() == "arena" then
			UiKit.closeModal()
		end
		ArenaReplay.play(answer, function()
			attacking = false
			result(answer, rankBefore)
		end)
	end)
end

local function drawOpponents(list: ScrollingFrame, token: number)
	UiKit.clear(list)
	local o = opp
	local s = state
	if not o then
		note(list, "...")
		return
	end
	local rivals = arr(o.list)
	if #rivals == 0 then
		note(list, "No rivals right now.")
		return
	end
	local mine = num(if s then s.power else nil, 0)
	local canFight = s ~= nil
		and num(s.tickets, 0) > 0
		and s.locked ~= true
		and s.pending == nil
		and mine > 0
		and not attacking
	local queue: { { box: Frame, look: Json } } = {}
	for index, entry in rivals do
		local _, body = UiKit.card(list, {
			Name = "Rival" .. index,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, W.CardHeight),
		})
		UiKit.label(body, rankText(entry.rank), U.TextNormal, "Brown", {
			Size = UDim2.new(0, W.RankWidth, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		UiKit.label(body, tostring(entry.name), U.TextSmall, "Brown", {
			Position = UDim2.fromOffset(W.RankWidth, 2),
			Size = UDim2.new(1, -W.RankWidth - U.Touch - U.Gap, 0, U.TextSmall + 4),
		})
		local faces = UiKit.make("Frame", {
			Name = "Faces",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(W.RankWidth, U.TextSmall + 8),
			Size = UDim2.new(1, -W.RankWidth - U.Touch - U.Gap, 0, W.Portrait),
		}, body)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, faces)
		for slot, look in arr(entry.looks) do
			if type(look) == "table" and slot <= A.TeamSize then
				local box = UiKit.make("Frame", {
					Name = "Face" .. slot,
					BackgroundTransparency = 1,
					LayoutOrder = slot,
					Size = UDim2.fromOffset(W.Portrait, W.Portrait),
				}, faces)
				table.insert(queue, { box = box, look = look })
			end
		end
		local power = num(entry.power, 0)
		stat(body, "arenaPower", short(power), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0) })
		local style = if mine <= 0
			then "primary"
			elseif power > mine * W.DangerRatio then "danger"
			elseif power < mine * W.FairRatio then "good"
			else "primary"
		UiKit.button(body, {
			Name = "Attack",
			Icon = "attack_order",
			IconSize = U.IconNormal,
			Style = style,
			Enabled = canFight,
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1, 1),
			OnClick = function()
				startAttack(entry)
			end,
		})
	end
	-- the small portraits are built one a frame, so the sheet opens at once
	task.spawn(function()
		for _, job in queue do
			if not live(token) then
				return
			end
			if job.box.Parent then
				local view = UiSlimes.lookView({
					Colour = job.look.Colour,
					Material = job.look.Material,
					DualId = job.look.DualId,
					SecretId = job.look.SecretId,
					Scale = 1,
				}, true)
				view.Parent = job.box
			end
			for _ = 1, W.PortraitsPerFrame do
				task.wait()
			end
		end
	end)
end

local function drawBattle(host: Frame, token: number)
	local s = state
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, host)
	local used = U.Touch + U.Gap
	local info = UiKit.make("Frame", {
		Name = "Info",
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, host)
	local left =
		UiKit.make("Frame", { Name = "Left", BackgroundTransparency = 1, Size = UDim2.fromScale(0.6, 1) }, info)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, left)
	local tickets = UiKit.chip(
		left,
		"arenaTicket",
		num(if s then s.tickets else nil, 0) .. "/" .. num(if s then s.ticketsPerDay else nil, A.TicketsPerDay),
		1
	)
	tickets.root.LayoutOrder = 1
	local reset = UiKit.label(left, "", U.TextSmall, "BrownSoft", {
		LayoutOrder = 2,
		Size = UDim2.new(0, 70, 1, 0),
	})
	clockLabel(reset, function()
		local day = W.DaySeconds
		local now = serverNow()
		return span((math.floor(now / day) + 1) * day - now)
	end)
	local right = UiKit.make("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.4, 1),
	}, info)
	local wait = UiKit.label(right, "", U.TextSmall, "BrownSoft", {
		Size = UDim2.new(1, -U.Touch - U.Gap, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local refresh: TextButton
	local function refreshLeft(): number
		local o = opp
		return if o then math.max(0, num(o.refreshIn, 0) - (os.clock() - oppAt)) else 0
	end
	local function paintRefresh()
		local remaining = refreshLeft()
		wait.Text = if remaining > 0 then span(remaining) else ""
		UiKit.setEnabled(refresh, remaining <= 0 and opp ~= nil)
	end
	refresh = UiKit.button(right, {
		Name = "Refresh",
		Icon = "again",
		IconSize = U.IconNormal,
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		OnClick = function()
			UiKit.setEnabled(refresh, false)
			task.spawn(function()
				local answer = call({ action = "opponents", refresh = true })
				if not live(token) then
					return
				end
				if answer.ok == true then
					opp, oppAt = answer, os.clock()
				else
					UiKit.toast(reasonText(answer.reason))
				end
				showTab("battle")
			end)
		end,
	})
	table.insert(ticks, paintRefresh)
	paintRefresh()
	if s and s.pending ~= nil then
		local row = UiKit.make("Frame", {
			Name = "Pending",
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, U.IconNormal),
		}, host)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, U.Gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)
		UiKit.icon(row, "again", U.IconNormal - 6, { LayoutOrder = 1 })
		UiKit.label(row, "Confirming...", U.TextSmall, "BrownSoft", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
		})
		used += U.IconNormal + U.Gap
	end
	local list = scroller(host, { LayoutOrder = 3, Size = UDim2.new(1, 0, 1, -used) })
	drawOpponents(list, token)
	if not opp then
		task.spawn(function()
			local answer = call({ action = "opponents" })
			if not live(token) then
				return
			end
			if answer.ok == true then
				opp, oppAt = answer, os.clock()
				paintRefresh()
				drawOpponents(list, token)
			else
				UiKit.clear(list)
				note(list, reasonText(answer.reason))
			end
		end)
	end
end

-- ===== Team =====

local function sameList(a: { any }, b: { any }): boolean
	if #a ~= #b then
		return false
	end
	for index, value in a do
		if b[index] ~= value then
			return false
		end
	end
	return true
end

local function drawTeam(host: Frame, token: number)
	local s = state
	local picked: { string } = {}
	for _, id in arr(if s then s.team else nil) do
		if type(id) == "string" then
			table.insert(picked, id)
		end
	end
	local strip = UiKit.make("Frame", {
		Name = "Strip",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, host)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap * 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, strip)
	local _, powerLabel = stat(strip, "arenaPower", short(num(if s then s.power else nil, 0)), { LayoutOrder = 1 })
	powerLabel.TextSize = U.TextNormal
	local count = UiKit.label(strip, "", U.TextNormal, "BrownSoft", {
		LayoutOrder = 2,
		Size = UDim2.new(0, 56, 1, 0),
	})
	local set: TextButton
	local listHost = UiKit.make("Frame", {
		Name = "Picker",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, U.Touch + U.Gap),
		Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
	}, host)
	local picker: UiSlimeList.List? = nil
	local function paint()
		count.Text = #picked .. "/" .. A.TeamSize
		local saved = arr(if state then state.team else nil)
		UiKit.setEnabled(set, #picked >= 1 and not sameList(picked, saved))
	end
	set = UiKit.button(strip, {
		Name = "SetTeam",
		Text = "Set",
		Style = "good",
		Size = UDim2.fromOffset(U.Touch * 2, U.Touch),
		LayoutOrder = 3,
		OnClick = function()
			UiKit.setEnabled(set, false)
			task.spawn(function()
				local answer = call({ action = "setTeam", ids = picked })
				if answer.ok == true then
					local current = state
					if current then
						current.team = answer.team
						current.power = answer.power
					end
					if live(token) then
						powerLabel.Text = short(num(answer.power, 0))
						paint()
					end
					UiKit.toast("Team ready!")
				else
					UiKit.toast(reasonText(answer.reason))
					if live(token) then
						paint()
					end
				end
			end)
		end,
	})
	local list = UiSlimeList.new(listHost, {
		entries = function()
			local out: { UiSlimeList.Entry } = {}
			-- (only slimes that can fight: no babies, no fallen ones)
			for _, slime in UiSlimes.slimes(ZombieTeams.root()) do
				if not UiSlimes.isBaby(slime) and not UiSlimes.isGhost(slime) then
					local place = table.find(picked, slime.Name)
					table.insert(out, {
						slime = slime,
						selected = place ~= nil,
						mark = if place
							then { text = tostring(place), colour = "Green" }
							else UiSlimeList.stateMark(slime),
					})
				end
			end
			return out
		end,
		onTap = function(slime)
			local place = table.find(picked, slime.Name)
			if place then
				table.remove(picked, place)
			elseif #picked >= A.TeamSize then
				UiKit.toast(reasonText("TEAM_SIZE"))
				return
			else
				table.insert(picked, slime.Name)
			end
			paint()
			if picker then
				picker.refresh()
			end
		end,
	})
	picker = list
	table.insert(cleanups, list.destroy)
	list.refresh()
	paint()
end

-- ===== Ranking =====

local function rankRow(
	parent: Instance,
	order: number,
	rank: any,
	name: string,
	power: any,
	points: any,
	mine: boolean
): Frame
	local box, body = UiKit.card(parent, {
		Name = "Row" .. order,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, W.RowHeight),
	})
	if mine then
		UiKit.setFill(box, "GoldLight")
	end
	local place = if type(rank) == "number" then rank else 0
	if place >= 1 and place <= 3 then
		-- ranks 1-3 are their medal's picture
		local size = math.min(W.BadgeWidth, W.RowHeight)
		UiKit.icon(body, "arenaMedal" .. place, size, {
			Name = "Badge",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, (W.BadgeWidth - size) / 2, 0.5, 0),
		})
	else
		local badge = UiKit.make("Frame", {
			Name = "Badge",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(W.BadgeWidth, W.BadgeHeight),
			BackgroundColor3 = UiKit.colour("CardDeep"),
			BorderSizePixel = 0,
		}, body)
		UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, badge)
		UiKit.label(badge, rankText(rank), U.TextSmall, "Brown", {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	local rightWidth = W.PowerWidth + W.PointsWidth + U.Gap
	UiKit.label(body, name, U.TextSmall, "Brown", {
		Position = UDim2.fromOffset(W.BadgeWidth + U.Gap, 0),
		Size = UDim2.new(1, -(W.BadgeWidth + U.Gap * 2 + rightWidth), 1, 0),
	})
	local group = UiKit.make("Frame", {
		Name = "Numbers",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, rightWidth, 1, 0),
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, group)
	stat(group, "arenaPower", short(num(power, 0)), { LayoutOrder = 1 })
	-- (rivals never earn season points: a column of zeros says nothing, so only a real score shows)
	if num(points, 0) > 0 then
		stat(group, "arenaPoints", short(num(points, 0)), { LayoutOrder = 2 })
	end
	return box
end

local function drawRanking(host: Frame, _token: number)
	local s = state
	if not s then
		note(host, "...")
		return
	end
	local foot = U.TextSmall + 10
	local pinned = W.RowHeight + U.Gap
	local list = scroller(host, { Size = UDim2.new(1, 0, 1, -pinned - foot) })
	local me = tostring(Players.LocalPlayer.UserId)
	local top = arr(s.top)
	if #top == 0 then
		note(list, "No ranking yet.")
	end
	for index, row in top do
		rankRow(list, index, row.rank, tostring(row.name), row.power, row.points, tostring(row.id) == me)
	end
	local own = rankRow(host, 1, s.rank, Players.LocalPlayer.DisplayName, s.power, nil, true)
	own.Position = UDim2.new(0, 0, 1, -foot - W.RowHeight)
	own.Size = UDim2.new(1, -8, 0, W.RowHeight)
	local line = UiKit.label(host, "", U.TextSmall, "BrownSoft", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, foot),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	clockLabel(line, function()
		local current = state
		if not current then
			return ""
		end
		return "Season ends in " .. span(num(current.seasonEndsAt, 0) - serverNow())
	end)
end

-- ===== Shop =====

local function drawShop(host: Frame, token: number)
	local s = state
	if not s then
		note(host, "...")
		return
	end
	local foot = U.TextSmall + 10
	local list = scroller(host, { Size = UDim2.new(1, 0, 1, -foot) })
	for index, row in arr(s.shop) do
		local left = num(row.left, 0)
		local affordable = row.affordable == true
		local _, body = UiKit.card(list, {
			Name = "Item" .. index,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, W.ShopCard),
		})
		local place = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) }
		local name = "?"
		if row.kind == "gear" then
			UiSmithy.pieceTile(body, row.item, W.ShopIcon, place)
			local def: any = Gear.get(row.item)
			name = if def then def.name else tostring(row.item)
		else
			UiDungeon.dropIcon(body, tostring(row.item), W.ShopIcon, place)
			local material: any = (Config.Dungeon.Materials :: any)[row.item]
			name = if material then material.name else tostring(row.item)
		end
		local count = num(row.count, 1)
		local textLeft = W.ShopIcon + U.Gap
		UiKit.label(body, if count > 1 then name .. " x" .. count else name, U.TextSmall, "Brown", {
			Position = UDim2.fromOffset(textLeft, 8),
			Size = UDim2.new(1, -textLeft - W.BuyWidth - U.Gap, 0, U.TextSmall + 4),
		})
		UiKit.label(
			body,
			left .. "/" .. num(row.weeklyLimit, 1) .. " left",
			U.TextSmall,
			if left > 0 then "BrownSoft" else "Red",
			{
				Position = UDim2.fromOffset(textLeft, U.TextSmall + 16),
				Size = UDim2.new(1, -textLeft - W.BuyWidth - U.Gap, 0, U.TextSmall + 4),
			}
		)
		UiKit.button(body, {
			Name = "Buy",
			Text = UiKit.money(num(row.price, 0)),
			Icon = "arenaPoints",
			IconSize = U.IconSmall,
			Style = "good",
			Enabled = affordable and left > 0,
			Size = UDim2.fromOffset(W.BuyWidth, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			OnClick = function()
				if buying then
					return
				end
				buying = true
				local requestId = HttpService:GenerateGUID(false)
				task.spawn(function()
					local answer = call({ action = "buy", itemId = row.id, requestId = requestId })
					buying = false
					if answer.ok ~= true then
						UiKit.toast(reasonText(answer.reason))
						return
					end
					local current = state
					if current then
						current.shop = answer.shop
						current.weekEndsAt = answer.weekEndsAt
						current.points = answer.points
					end
					UiKit.toast("Got " .. (if count > 1 then name .. " x" .. count else name) .. "!")
					if live(token) then
						paintHeader()
						showTab("shop")
					end
				end)
			end,
		})
	end
	local line = UiKit.label(host, "", U.TextSmall, "BrownSoft", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, foot),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	clockLabel(line, function()
		local current = state
		if not current then
			return ""
		end
		return "New stock in " .. span(num(current.weekEndsAt, 0) - serverNow())
	end)
end

-- ===== Records =====

local PERIODS: { [string]: string } = { day = "Day", week = "Week", season = "Season" }

local function drawRecords(host: Frame, token: number)
	local s = state
	if not s then
		note(host, "...")
		return
	end
	local list = scroller(host)
	-- defence: held, streak, best
	local block = UiKit.make("Frame", {
		Name = "Defence",
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, W.StatBlock),
	}, list)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, block)
	local defense: Json = if type(s.defense) == "table" then s.defense else {}
	local cells = {
		{ icon = "defence", value = num(defense.wins, 0), caption = "Held" },
		{ icon = "speed", value = num(defense.streak, 0), caption = "Streak" },
		{ icon = "rewards", value = num(defense.best, 0), caption = "Best" },
	}
	for index, cell in cells do
		local _, body = UiKit.card(block, {
			Name = cell.caption,
			LayoutOrder = index,
			Size = UDim2.new(1 / #cells, -U.Gap * (#cells - 1) / #cells, 1, 0),
		})
		local stack = UiKit.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, body)
		UiKit.make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, stack)
		local _, value = stat(stack, cell.icon, tostring(cell.value), { LayoutOrder = 1 })
		value.TextSize = U.TextNormal
		UiKit.label(stack, cell.caption, U.TextTiny, "BrownSoft", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, U.TextTiny + 4),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	-- quests
	for index, quest in arr(s.quests) do
		local done = quest.done == true
		local need = math.max(1, num(quest.wins, 1))
		local have = math.min(num(quest.count, 0), need)
		local _, body = UiKit.card(list, {
			Name = "Quest" .. index,
			LayoutOrder = 10 + index,
			Size = UDim2.new(1, 0, 0, W.QuestRow),
		})
		UiKit.icon(
			body,
			if done then "arenaQuest" else "attack",
			U.IconNormal,
			{ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) }
		)
		local textLeft = U.IconNormal + U.Gap
		local rightWidth = 70
		local words = if quest.stronger == true then "Win vs stronger" else "Win " .. need
		UiKit.label(body, words .. " - " .. (PERIODS[tostring(quest.period)] or ""), U.TextSmall, "Brown", {
			Position = UDim2.fromOffset(textLeft, 0),
			Size = UDim2.new(1, -textLeft - rightWidth, 0, U.TextSmall + 4),
		})
		local bar = UiKit.bar(body, "", if done then "Green" else "GoldLight", {
			Position = UDim2.fromOffset(textLeft, U.TextSmall + 8),
			Size = UDim2.new(1, -textLeft - rightWidth - 40, 0, U.IconSmall),
		})
		bar.set(have / need, false)
		UiKit.label(body, have .. "/" .. need, U.TextSmall, "BrownSoft", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -rightWidth, 0, U.TextSmall + 6),
			Size = UDim2.fromOffset(38, U.IconSmall + 4),
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		stat(
			body,
			"arenaPoints",
			"+" .. num(quest.points, 0),
			{ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0) }
		)
	end
	-- the log
	local logBox = UiKit.make("Frame", {
		Name = "Log",
		BackgroundTransparency = 1,
		LayoutOrder = 100,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, list)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, logBox)
	task.spawn(function()
		local answer = call({ action = "log" })
		if not live(token) then
			return
		end
		local lines = arr(answer.log)
		if #lines == 0 then
			note(logBox, reasonText(if answer.ok == true then "NO_LOG" else answer.reason))
			return
		end
		local shown = 0
		for index = #lines, 1, -1 do
			local line = lines[index]
			if type(line) == "table" then
				shown += 1
				if shown > W.LogShown then
					break
				end
				local attack = line.kind == "attack"
				local good = if attack then line.won == true else line.held == true
				local _, body = UiKit.card(logBox, {
					Name = "Line" .. shown,
					LayoutOrder = shown,
					Size = UDim2.new(1, 0, 0, W.LogRow),
				})
				UiKit.icon(body, if attack then "attack" else "defence", U.IconNormal, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
				})
				local textLeft = U.IconNormal + U.Gap
				local rightWidth = 112
				UiKit.label(body, tostring(line.vs), U.TextSmall, "Brown", {
					Position = UDim2.fromOffset(textLeft, 0),
					Size = UDim2.new(1, -textLeft - rightWidth, 1, 0),
				})
				local right = UiKit.make("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.new(0, rightWidth, 1, 0),
				}, body)
				UiKit.make("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, U.Gap),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, right)
				if attack and num(line.points, 0) > 0 then
					stat(right, "arenaPoints", "+" .. num(line.points, 0), { LayoutOrder = 1 })
				end
				UiKit.label(
					right,
					if attack then (if good then "Won" else "Lost") else (if good then "Held" else "Lost"),
					U.TextSmall,
					if good then "GreenDark" else "Red",
					{
						LayoutOrder = 2,
						Size = UDim2.fromScale(0, 1),
						AutomaticSize = Enum.AutomaticSize.X,
					}
				)
			end
		end
	end)
end

-- ===== The sheet =====

local DRAW: { [string]: (Frame, number) -> () } = {
	battle = drawBattle,
	team = drawTeam,
	ranking = drawRanking,
	shop = drawShop,
	records = drawRecords,
}

local function undo()
	for _, item in cleanups do
		item()
	end
	table.clear(cleanups)
	table.clear(ticks)
end

showTab = function(id: string)
	tab = id
	drawToken += 1
	undo()
	local host = page
	if not host or not host.Parent then
		return
	end
	UiKit.clear(host)
	local draw = DRAW[id]
	if draw then
		draw(host, drawToken)
	end
end

-- A tab chosen: it is drawn at once from the last state, and again when a fresher one arrives.
local function chooseTab(id: string)
	showTab(id)
	if os.clock() - stateAt > W.FreshSeconds then
		local token = drawToken
		fetchState(function()
			if live(token) then
				paintHeader()
				if id ~= "team" then
					showTab(id)
				end
			end
		end)
	end
end

function UiArena.open()
	if UiKit.modalId() == "arena" then
		UiKit.closeModal()
		return
	end
	-- (the stands' slimes are made in the background while the player picks a rival: once per session)
	ArenaStage.prepare()
	drawToken += 1
	local narrow = UiKit.units(UiKit.root()).X < W.SheetWidth + 2 * U.Edge
	local modal = UiKit.openModal("arena", {
		Width = W.SheetWidth,
		Height = W.SheetHeight,
		Bottom = narrow,
		OnClose = function()
			drawToken += 1
			undo()
			page, headerRank, headerPoints = nil, nil, nil
		end,
	})
	-- header: the emblem, your rank, your points
	local head =
		UiKit.make("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, modal.header)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, head)
	UiKit.icon(head, "arena", U.Touch - 8, { LayoutOrder = 1 })
	headerRank = UiKit.label(head, "-", U.TextHeader, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromOffset(W.RankWidth + 20, U.Touch),
	})
	headerPoints = UiKit.chip(head, "arenaPoints", "0", 3)
	local items = {}
	for _, item in TABS do
		table.insert(items, { id = item.id, icon = item.icon })
	end
	UiKit.segmented(modal.content, items, tab, chooseTab, {
		Name = "Tabs",
		Size = UDim2.new(1, 0, 0, U.Touch),
	})
	page = UiKit.make("Frame", {
		Name = "Page",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, U.Touch + U.Gap),
		Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
	}, modal.content)
	paintHeader()
	showTab(tab)
	local token = drawToken
	fetchState(function()
		if live(token) then
			paintHeader()
			if tab ~= "team" then
				showTab(tab)
			end
		end
	end)
	-- one clock for the sheet: the countdowns and, while a match waits to be confirmed, a look at the state
	sheetId += 1
	local mySheet = sheetId
	task.spawn(function()
		local polled = os.clock()
		while sheetId == mySheet and UiKit.modalId() == "arena" do
			for _, item in ticks do
				item()
			end
			local s = state
			if tab == "battle" and s and s.pending ~= nil and os.clock() - polled >= W.PollSeconds then
				polled = os.clock()
				local mine = drawToken
				fetchState(function()
					local current = state
					if live(mine) and tab == "battle" and current and current.pending == nil then
						paintHeader()
						opp = nil
						showTab("battle")
					end
				end)
			end
			task.wait(W.ClockSeconds)
		end
	end)
end

function UiArena.close()
	if UiKit.modalId() == "arena" then
		UiKit.closeModal()
	end
end

return UiArena
