--!strict
-- The village screen: the Manage sheet of each area (opened with F at its entrance), the slime picker, the resource strip
-- and the slime book button. Built with UiKit from the owner's art. Server answers, not client guesses, decide what
-- changes: a seat the server would refuse is greyed in the picker, never hidden logic.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local UiBook = require(script.Parent.UiBook)
local UiHud = require(script.Parent.UiHud)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)

local C = Config.VillageClient
local U = Config.Ui
local player = Players.LocalPlayer
local VillageUI = {}

type Pick = {
	area: string,
	kind: string, -- "work", "train" or "pair"
	slot: number,
	current: string?, -- the slime now in that seat
	stat: string?, -- the chosen training stat
	exclude: string?, -- a slime already chosen in the first step of a pair
	partner: string?,
	choose: (Configuration) -> (),
}

local own: Folder? = nil
local prompts: { ProximityPrompt } = {}
local promptAreas: { [string]: boolean } = {}
local activePoint: Vector3? = nil
local activeArea: string? = nil
local sheetHeader: Frame? = nil
local sheetContent: Frame? = nil
local pick: Pick? = nil
local pickView: UiSlimes.View? = nil
local live: (() -> ())? = nil
local renderedKey = ""
local busy = false
local refreshPending = false
local rootConnections: { RBXScriptConnection } = {}
local slimeConnections: { [Instance]: RBXScriptConnection } = {}

-- Attributes whose change redraws a slime on screen (movement legs and the like are ignored).
local watched: { [string]: boolean } = {
	Name = true,
	Fullness = true,
	Energy = true,
	Fun = true,
	Level = true,
	Attack = true,
	Defence = true,
	Speed = true,
	Hp = true,
	Baby = true,
	Ghost = true,
	Sleeping = true,
	Trait = true,
	WorkArea = true,
	WorkSlot = true,
	Reserve = true,
	PairIndex = true,
	CookedAllowed = true,
}
local statAttributes: { [string]: string } = { attack = "Attack", defence = "Defence", speed = "Speed", hp = "Hp" }
local areaTitles: { [string]: string } = {
	fishing = "Fishing",
	garden = "Garden",
	kitchen = "Kitchen",
	pantry = "Pantry",
	training = "Training",
	breeding = "Breeding",
}

local reasons: { [string]: string } = {
	NOT_READY = "Village is loading.",
	RATE_LIMIT = "Too many requests.",
	BAD_REQUEST = "Try again.",
	INVALID_ARGUMENT = "Not available.",
	MISSING_SLIME = "Slime not found.",
	NOT_ASSIGNED = "Not assigned.",
	INVALID_STAT_OR_SLOT = "Choose a valid stat.",
	SERVER_ERROR = "Please try again.",
}

local function failure(reason: any): string
	if type(reason) ~= "string" then
		return "Action unavailable."
	end
	if reasons[reason] then
		return reasons[reason]
	end
	local words = string.lower((string.gsub(reason, "_", " ")))
	return string.upper(string.sub(words, 1, 1)) .. string.sub(words, 2)
end

local function parse(value: any): { [string]: any }
	if type(value) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(value)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

local function request(data: { [string]: any }, onSuccess: () -> ())
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = if remotes then remotes:FindFirstChild("Village") else nil
	if not remote or not remote:IsA("RemoteFunction") then
		UiKit.toast("Village is loading.")
		return
	end
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local ok, answer = pcall(function()
			return remote:InvokeServer(data)
		end)
		busy = false
		if not ok or type(answer) ~= "table" then
			UiKit.toast("Please try again.")
		elseif answer.ok then
			onSuccess()
		else
			UiKit.toast(failure(answer.reason))
		end
	end)
end

local function findSlime(id: string?): Configuration?
	local folder = if own then own:FindFirstChild("Slimes") else nil
	local found = if folder and id and id ~= "" then folder:FindFirstChild(id) else nil
	return if found and found:IsA("Configuration") then found else nil
end

local renderArea: (string) -> ()

-- ===== Picker =====

local function reasonBlocked(slime: Configuration, spec: Pick): string?
	if UiSlimes.isGhost(slime) then
		return "Ghost"
	elseif UiSlimes.isBaby(slime) then
		return "Baby"
	elseif spec.kind == "pair" then
		local index = UiSlimes.pair(slime)
		if slime.Name == spec.exclude then
			return "Chosen"
		elseif index ~= 0 then
			return "Paired"
		elseif UiSlimes.job(slime) then
			return "Working"
		end
	elseif UiSlimes.job(slime) then
		return "Working"
	elseif UiSlimes.pair(slime) ~= 0 then
		return "Paired"
	end
	return nil
end

-- Higher is better. Work: the fastest. Training: the weakest in the chosen stat. Pairing: the highest level, fed and rested.
local function score(slime: Configuration, spec: Pick): number?
	if spec.kind == "work" then
		return UiSlimes.number(slime, "Speed")
	elseif spec.kind == "train" then
		local attribute = if spec.stat then statAttributes[spec.stat] else nil
		return if attribute then -UiSlimes.number(slime, attribute) else nil
	end
	local fed = UiSlimes.number(slime, "Fullness") >= Config.Needs.PairFullness
	local rested = UiSlimes.number(slime, "Energy") > Config.Needs.Tired and slime:GetAttribute("Sleeping") ~= true
	return if fed and rested then UiSlimes.number(slime, "Level") else nil
end

local function pickEntries(): { UiSlimes.Entry }
	local spec = pick
	if not spec then
		return {}
	end
	local free: { UiSlimes.Entry } = {}
	local busyOnes: { UiSlimes.Entry } = {}
	local best: UiSlimes.Entry? = nil
	local bestScore = -math.huge
	for _, slime in UiSlimes.slimes(own) do
		local entry: UiSlimes.Entry = { slime = slime, blocked = reasonBlocked(slime, spec) }
		if entry.blocked then
			table.insert(busyOnes, entry)
		else
			table.insert(free, entry)
			local value = score(slime, spec)
			if value and value > bestScore then
				best, bestScore = entry, value
			end
		end
	end
	table.sort(free, function(a, b)
		local left, right = score(a.slime, spec) or -math.huge, score(b.slime, spec) or -math.huge
		if left ~= right then
			return left > right
		end
		return a.slime.Name < b.slime.Name
	end)
	if best then
		best.suggested = true
		table.remove(free, table.find(free, best) :: number)
		table.insert(free, 1, best)
	end
	for _, entry in busyOnes do
		table.insert(free, entry)
	end
	return free
end

local function drawBackHeader(spec: Pick)
	local bar = sheetHeader
	if not bar then
		return
	end
	UiKit.clear(bar)
	UiKit.button(bar, {
		Name = "Back",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		OnClick = function()
			renderArea(spec.area)
		end,
	})
	UiKit.icon(bar, spec.area, U.Touch - 12, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, U.Touch + U.Gap, 0.5, 0),
	})
	local current = spec.current
	if current and current ~= "" and spec.kind ~= "pair" then
		UiKit.button(bar, {
			Name = "Remove",
			Text = "Remove",
			Style = "secondary",
			Size = UDim2.fromOffset(U.Touch * 2, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			OnClick = function()
				request({ action = "Unassign", slimeId = current }, function()
					renderArea(spec.area)
				end)
			end,
		})
	end
end

local function openPicker(spec: Pick)
	local host = sheetContent
	if not host then
		return
	end
	pick = spec
	live = nil
	renderedKey = ""
	UiKit.clear(host)
	drawBackHeader(spec)
	local list = UiSlimes.view(host, pickEntries, spec.choose, true)
	pickView = list
	list.refresh()
end

-- ===== Sheet pieces =====

local function seat(parent: Instance, id: string?, size: number, position: UDim2, onClick: () -> ()): TextButton
	local button = UiKit.make("TextButton", {
		Name = "Seat",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Position = position,
	}, parent)
	local slime = findSlime(id)
	if slime then
		local _, show = UiSlimes.portrait(button, slime, size)
		show()
	else
		local _, body = UiKit.skin(button, "Wood", "CardDeep", { Size = UDim2.fromOffset(size, size) })
		UiKit.icon(body, "plus", math.floor(size / 2), {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
		})
	end
	button.Activated:Connect(onClick)
	return button
end

local function rowCard(parent: Instance, height: number, order: number): Frame
	local _, body = UiKit.card(parent, { Size = UDim2.new(1, -8, 0, height), LayoutOrder = order })
	return body
end

local function stockChips(parent: Instance, stock: { [string]: number }, order: { string }, start: number)
	local wrap = UiKit.make("Frame", {
		Name = "Stock",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = start,
	}, parent)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Wraps = true,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, wrap)
	for index, item in order do
		local amount = stock[item] or 0
		if amount > 0 then
			UiKit.chip(wrap, item, tostring(amount), index)
		end
	end
	return wrap
end

local function structureKey(area: string): string
	local parts: { string } = { area }
	local levels = if own then parse(own:GetAttribute("Areas")) else {}
	table.insert(parts, tostring(levels[area]))
	if table.find(Config.Work.Areas, area) then
		local work: { [string]: any } = if own then parse(own:GetAttribute("Work")) else {}
		for slot, saved in work[area] or {} do
			table.insert(
				parts,
				string.format("%d:%s:%s:%s", slot, saved.worker or "", saved.reserve or "", saved.stat or "")
			)
		end
	end
	if area == "breeding" then
		local pairs: { any } = if own then parse(own:GetAttribute("Pairs")) :: any else {}
		for index, pair in pairs do
			table.insert(parts, string.format("%d:%s:%s", index, pair.a or "", pair.b or ""))
		end
	end
	if area == "kitchen" then
		for _, slime in UiSlimes.slimes(own) do
			if not UiSlimes.isBaby(slime) and not UiSlimes.isGhost(slime) then
				table.insert(parts, slime.Name .. (if slime:GetAttribute("CookedAllowed") == true then "+" else "-"))
			end
		end
	end
	return table.concat(parts, "|")
end

local function drawTitle(area: string)
	local bar = sheetHeader
	if not bar then
		return
	end
	UiKit.clear(bar)
	UiKit.icon(bar, area, U.Touch - 4, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) })
	UiKit.label(bar, areaTitles[area] or area, U.TextHeader, "Brown", {
		Position = UDim2.fromOffset(U.Touch + U.Gap, 0),
		Size = UDim2.new(1, -U.Touch - U.Gap, 0, U.Touch),
	})
end

local function levelOf(area: string): number
	local levels = if own then parse(own:GetAttribute("Areas")) else {}
	local value = levels[area]
	return if type(value) == "number" then value else Config.Village.StartLevel
end

-- One slot of a work area: the worker's seat, the reserve's seat and the progress.
local function workRow(scroll: ScrollingFrame, area: string, slot: number, saved: { [string]: any }): (UiKit.Bar, Frame)
	local training = area == "training"
	local height = if training then U.RowHeight + U.Touch + U.Gap else U.RowHeight
	local body = rowCard(scroll, height, slot)
	local function choose(reserve: boolean)
		local current = if reserve then saved.reserve else saved.worker
		openPicker({
			area = area,
			kind = if training then "train" else "work",
			slot = slot,
			current = current,
			stat = saved.stat,
			choose = function(slime)
				local function assign()
					request(
						{ action = "Assign", area = area, slot = slot, slimeId = slime.Name, asReserve = reserve },
						function()
							renderArea(area)
						end
					)
				end
				if type(current) == "string" and current ~= "" then
					request({ action = "Unassign", slimeId = current }, assign)
				else
					assign()
				end
			end,
		})
	end
	local main = U.SeatSize
	seat(body, saved.worker, main, UDim2.fromOffset(0, 0), function()
		choose(false)
	end)
	seat(
		body,
		saved.reserve,
		U.SeatReserveSize,
		UDim2.fromOffset(main + U.Gap, (main - U.SeatReserveSize) / 2),
		function()
			choose(true)
		end
	)
	local lead = main + U.SeatReserveSize + U.Gap * 3
	local progress = UiKit.bar(body, "", "Gold", {
		Position = UDim2.fromOffset(lead, main / 2 - 8),
		Size = UDim2.new(1, -lead, 0, 16),
	})
	if training then
		local list = UiKit.make("Frame", {
			Name = "Stats",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, main + U.Gap),
			Size = UDim2.new(1, 0, 0, U.Touch),
		}, body)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, U.Gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, list)
		for index, stat in { "attack", "defence", "speed", "hp" } do
			UiKit.button(list, {
				Name = stat,
				Icon = stat,
				Style = if saved.stat == stat then "primary" else "secondary",
				Size = UDim2.fromOffset(U.Touch + 10, U.Touch),
				LayoutOrder = index,
				OnClick = function()
					request({ action = "SetTrainingStat", slot = slot, stat = stat }, function() end)
				end,
			})
		end
	end
	return progress, body
end

local function breedingRow(scroll: ScrollingFrame, area: string, index: number, pair: { [string]: any }): TextLabel
	local body = rowCard(scroll, U.RowHeight, index)
	local size = U.SeatSize
	local function choose(side: string)
		local partner = if side == "a" then pair.b else pair.a
		local has = type(pair.a) == "string" and pair.a ~= "" and type(pair.b) == "string" and pair.b ~= ""
		local function set(a: string, b: string)
			request({ action = "SetPair", index = index, a = a, b = b }, function()
				renderArea(area)
			end)
		end
		local spec: Pick = {
			area = area,
			kind = "pair",
			slot = index,
			current = if side == "a" then pair.a else pair.b,
			partner = partner,
			choose = function(slime)
				if has then
					set(if side == "a" then slime.Name else pair.a, if side == "a" then pair.b else slime.Name)
				else
					-- An empty place takes two slimes: the second step excludes the first.
					openPicker({
						area = area,
						kind = "pair",
						slot = index,
						exclude = slime.Name,
						choose = function(second)
							set(slime.Name, second.Name)
						end,
					})
				end
			end,
		}
		openPicker(spec)
	end
	seat(body, pair.a, size, UDim2.fromOffset(0, 0), function()
		choose("a")
	end)
	UiKit.icon(body, "breeding", U.IconNormal + 8, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, size + U.Gap + 24, 0.5, -6),
	})
	local courting = UiKit.label(body, "", U.TextTiny, "BrownSoft", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0, size + U.Gap + 24, 0.5, 14),
		Size = UDim2.fromOffset(60, U.TextTiny + 4),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	seat(body, pair.b, size, UDim2.fromOffset(size + 2 * U.Gap + 48, 0), function()
		choose("b")
	end)
	if type(pair.a) == "string" and pair.a ~= "" then
		UiKit.button(body, {
			Name = "Clear",
			Icon = "cross",
			Style = "secondary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			OnClick = function()
				request({ action = "SetPair", index = index }, function()
					renderArea(area)
				end)
			end,
		})
	end
	return courting
end

local function cookedList(scroll: ScrollingFrame, start: number)
	local order = start
	for _, slime in UiSlimes.slimes(own) do
		if not UiSlimes.isBaby(slime) and not UiSlimes.isGhost(slime) then
			order += 1
			local body = rowCard(scroll, U.SeatReserveSize + 12, order)
			local _, show = UiSlimes.portrait(body, slime, U.SeatReserveSize, { Position = UDim2.fromOffset(0, 0) })
			show()
			UiKit.label(body, UiSlimes.name(slime), U.TextNormal, "Brown", {
				Position = UDim2.fromOffset(U.SeatReserveSize + U.Gap, 0),
				Size = UDim2.new(1, -U.SeatReserveSize - U.Gap - 96, 0, U.SeatReserveSize),
			})
			local allowed = slime:GetAttribute("CookedAllowed") == true
			UiKit.button(body, {
				Name = "Cooked",
				Icon = "food",
				Text = if allowed then "Yes" else "No",
				Style = if allowed then "good" else "secondary",
				Size = UDim2.fromOffset(90, U.Touch),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				OnClick = function()
					request(
						{ action = "SetCookedAllowed", slimeId = slime.Name, allowed = not allowed },
						function() end
					)
				end,
			})
		end
	end
end

renderArea = function(area: string)
	local host = sheetContent
	if not host then
		return
	end
	pick, pickView = nil, nil
	UiKit.clear(host)
	drawTitle(area)
	local scroll = UiKit.make("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, host)
	UiKit.make("UIListLayout", {
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroll)
	renderedKey = structureKey(area)
	local bars: { [number]: UiKit.Bar } = {}
	local courting: { [number]: TextLabel } = {}
	local boxHost: Frame? = nil
	local order = 0
	UiKit.label(scroll, "Lv " .. tostring(levelOf(area)), U.TextNormal, "BrownSoft", { LayoutOrder = order })

	if area == "breeding" then
		local pairs: { any } = if own then parse(own:GetAttribute("Pairs")) :: any else {}
		for index = 1, math.max(Config.Breeding.BasePlaces, #pairs) do
			order += 1
			courting[index] = breedingRow(scroll, area, index, pairs[index] or {})
		end
	elseif table.find(Config.Work.Areas, area) then
		local work: { [string]: any } = if own then parse(own:GetAttribute("Work")) else {}
		local stations: { any } = work[area] or {}
		for slot = 1, math.max(#stations, Config.Work.BaseSlots) do
			order += 1
			local progress = workRow(scroll, area, slot, stations[slot] or {})
			bars[slot] = progress
		end
		order += 1
		boxHost = UiKit.make("Frame", {
			Name = "BoxHost",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 100,
		}, scroll)
		if area == "kitchen" then
			cookedList(scroll, 100)
		end
	elseif area == "pantry" then
		boxHost = UiKit.make("Frame", {
			Name = "BoxHost",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		}, scroll)
	end

	-- Everything that changes every second: progress, courtship and what the box holds. No portraits are rebuilt.
	local function update()
		if own then
			local work: { [string]: any } = parse(own:GetAttribute("Work"))
			local stations: { any } = work[area] or {}
			for slot, bar in bars do
				local saved = stations[slot] or {}
				bar.set(if type(saved.progress) == "number" then saved.progress else 0, false)
			end
			local pairs: { any } = parse(own:GetAttribute("Pairs")) :: any
			for index, label in courting do
				local pair = pairs[index] or {}
				label.Text = if type(pair.courtingUntil) == "number" and pair.courtingUntil > os.time()
					then "Courting"
					else ""
			end
			if boxHost then
				UiKit.clear(boxHost)
				local stock: { [string]: number }
				local kinds: { string }
				if area == "pantry" then
					stock = {}
					for key, value in parse(own:GetAttribute("Storehouse")) do
						stock[key] = value
					end
					for key, value in parse(own:GetAttribute("Fridge")) do
						stock[key] = value
					end
					kinds = {}
					for _, key in Config.Food.RawOrder do
						table.insert(kinds, key)
					end
					for _, key in Config.Food.DishOrder do
						table.insert(kinds, key)
					end
				else
					stock = (parse(own:GetAttribute("Box"))[area] or {}) :: any
					kinds = if area == "kitchen" then Config.Food.DishOrder else Config.Food.RawOrder
				end
				stockChips(boxHost, stock, kinds, 1)
			end
		end
	end
	update()
	live = update
end

-- ===== Opening and closing =====

local function onSheetClosed()
	activePoint, activeArea = nil, nil
	pick, pickView, live = nil, nil, nil
	sheetHeader, sheetContent = nil, nil
	renderedKey = ""
end

local function openSheet(area: string, position: Vector3)
	activePoint = position
	activeArea = area
	local modal = UiKit.openModal("sheet", {
		Width = U.SheetWidth,
		Height = U.SheetHeight,
		Bottom = true,
		Dim = 0.8,
		OnClose = onSheetClosed,
	})
	-- openModal closed any open modal (its OnClose cleared this state); set it again for the new one.
	activePoint, activeArea = position, area
	sheetHeader, sheetContent = modal.header, modal.content
	renderArea(area)
end

-- Replicated changes are coalesced; scroll position and the current picker step are kept.
local function refreshAll()
	if refreshPending then
		return
	end
	refreshPending = true
	task.delay(Config.Village.TickSeconds, function()
		refreshPending = false
		if UiBook.isOpen() then
			UiBook.refresh()
		end
		if UiKit.modalId() ~= "sheet" or not activeArea then
			return
		end
		if pick then
			if pickView then
				pickView.refresh()
			end
		elseif structureKey(activeArea) ~= renderedKey then
			local host = sheetContent
			local before = if host then host:FindFirstChild("Scroll") else nil
			local offset = if before and before:IsA("ScrollingFrame") then before.CanvasPosition else Vector2.zero
			renderArea(activeArea)
			local after = if host then host:FindFirstChild("Scroll") else nil
			if after and after:IsA("ScrollingFrame") then
				task.defer(function()
					after.CanvasPosition = offset
				end)
			end
		elseif live then
			live()
		end
	end)
end

-- ===== World prompts =====

local function anchor(inst: Instance): Instance?
	if inst:IsA("Attachment") or inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function positionOf(inst: Instance): Vector3?
	if inst:IsA("Attachment") then
		return inst.WorldPosition
	elseif inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

local modelNames: { [string]: string } = {
	fishing = "FishingPond",
	garden = "Garden",
	kitchen = "Kitchen",
	pantry = "Pantry",
	training = "Training",
	breeding = "Breeding",
}

local function createPrompts(root: Folder)
	local plotId = root:GetAttribute("Plot")
	if type(plotId) ~= "number" or plotId < 1 then
		return
	end
	local map = workspace:FindFirstChild("Map")
	local plot = if map then map:FindFirstChild("Plot" .. tostring(plotId)) else nil
	if not plot then
		return
	end
	for _, area in Config.Village.Areas do
		local model: Instance? = nil
		for _, child in plot:GetChildren() do
			if string.match(string.lower(child.Name), "^" .. string.lower(modelNames[area]) .. "l") then
				model = child
				break
			end
		end
		if model and not promptAreas[area] then
			local entrance = model:FindFirstChild("UpgradePoint", true)
				or model:FindFirstChild("Entrance", true)
				or model:FindFirstChild("Gate", true)
			local target = anchor(entrance or model)
			if target then
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "VillageManage"
				prompt.ActionText = "Manage"
				prompt.ObjectText = areaTitles[area]
				prompt.KeyboardKeyCode = Enum.KeyCode.F
				prompt.HoldDuration = C.PromptHoldSeconds
				prompt.MaxActivationDistance = C.PromptDistance
				prompt.RequiresLineOfSight = false
				prompt.Parent = target
				prompt.Triggered:Connect(function()
					local position = positionOf(target)
					if position then
						openSheet(area, position)
					end
				end)
				table.insert(prompts, prompt)
				promptAreas[area] = true
			end
		end
	end
end

-- ===== Binding to the player's village =====

local function watchSlime(inst: Instance)
	if inst:IsA("Configuration") and not slimeConnections[inst] then
		slimeConnections[inst] = inst.AttributeChanged:Connect(function(name)
			if watched[name] then
				refreshAll()
			end
		end)
		refreshAll()
	end
end

local function watchFolder(root: Folder)
	local folder = root:FindFirstChild("Slimes")
	if not folder or not folder:IsA("Folder") then
		return
	end
	for _, inst in folder:GetChildren() do
		watchSlime(inst)
	end
	table.insert(rootConnections, folder.ChildAdded:Connect(watchSlime))
	table.insert(
		rootConnections,
		folder.ChildRemoved:Connect(function(inst)
			local connection = slimeConnections[inst]
			if connection then
				connection:Disconnect()
				slimeConnections[inst] = nil
			end
			refreshAll()
		end)
	)
end

local function bind(root: Folder?)
	for _, prompt in prompts do
		prompt:Destroy()
	end
	table.clear(prompts)
	table.clear(promptAreas)
	for _, conn in rootConnections do
		conn:Disconnect()
	end
	table.clear(rootConnections)
	for _, conn in slimeConnections do
		conn:Disconnect()
	end
	table.clear(slimeConnections)
	own = root
	UiKit.closeModal(true)
	UiHud.refresh(root)
	if not root then
		UiHud.setVisible(false)
		return
	end
	-- The folder can arrive before its Plot attribute and Slimes folder.
	table.insert(
		rootConnections,
		root:GetAttributeChangedSignal("Plot"):Connect(function()
			if own == root then
				bind(root)
			end
		end)
	)
	if type(root:GetAttribute("Plot")) ~= "number" or (root:GetAttribute("Plot") :: number) < 1 then
		UiHud.setVisible(false)
		return
	end
	UiHud.setVisible(true)
	for _, attribute in { "Coins", "Storehouse", "Fridge", "Population", "Limit" } do
		table.insert(
			rootConnections,
			root:GetAttributeChangedSignal(attribute):Connect(function()
				if own == root then
					UiHud.refresh(root)
					refreshAll()
				end
			end)
		)
	end
	for _, attribute in { "Work", "Pairs", "Areas", "Box" } do
		table.insert(rootConnections, root:GetAttributeChangedSignal(attribute):Connect(refreshAll))
	end
	watchFolder(root)
	table.insert(
		rootConnections,
		root.ChildAdded:Connect(function(child)
			if child.Name == "Slimes" then
				watchFolder(root)
				refreshAll()
			end
		end)
	)
	createPrompts(root)
end

function VillageUI.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GooVillageUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 5
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local root = UiKit.mount(gui)

	UiHud.start(root, function()
		UiBook.open({
			own = function()
				return own
			end,
			request = request,
		})
	end)

	local world = workspace:WaitForChild("Villages")
	local id = tostring(player.UserId)
	local function changed(child: Instance)
		if child.Name == id and child:IsA("Folder") then
			bind(child)
		end
	end
	local existing = world:FindFirstChild(id)
	if existing and existing:IsA("Folder") then
		bind(existing)
	end
	world.ChildAdded:Connect(changed)
	world.ChildRemoved:Connect(function(child)
		if child == own then
			bind(nil)
		end
	end)
	task.spawn(function()
		while gui.Parent do
			if activePoint then
				local character = player.Character
				local part = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if part and part:IsA("BasePart") and (part.Position - activePoint).Magnitude > C.SheetWalkAwayStuds then
					UiKit.closeModal()
				end
			end
			if
				own
				and type(own:GetAttribute("Plot")) == "number"
				and (own:GetAttribute("Plot") :: number) > 0
				and #prompts < #Config.Village.Areas
			then
				createPrompts(own)
			end
			task.wait(C.FarUpdateSeconds)
		end
	end)
end

return VillageUI
