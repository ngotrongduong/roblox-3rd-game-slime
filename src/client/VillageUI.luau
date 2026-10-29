--!strict
-- The village screen: the Manage sheet of each area (opened with F at its entrance), the slime picker, the resource strip
-- and the slime book button. Built with UiKit from the owner's art. Server answers, not client guesses, decide what
-- changes: a seat the server would refuse is greyed in the picker, never hidden logic.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local UiBook = require(script.Parent.UiBook)
local UiHud = require(script.Parent.UiHud)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)
local UiSpots = require(script.Parent.UiSpots)

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

-- Requests go out one after another, never blocking the screen: the UI shows the player's choice first (optimistic),
-- and a refused one shows a short toast and puts things back (onFail).
local queue: { { data: { [string]: any }, onSuccess: (() -> ())?, onFail: (() -> ())? } } = {}

local function pump()
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		while #queue > 0 do
			local job = table.remove(queue, 1) :: any
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			local remote = if remotes then remotes:FindFirstChild("Village") else nil
			local ok, answer = false, nil :: any
			if remote and remote:IsA("RemoteFunction") then
				ok, answer = pcall(function()
					return remote:InvokeServer(job.data)
				end)
			end
			if ok and type(answer) == "table" and answer.ok then
				if job.onSuccess then
					job.onSuccess()
				end
			else
				UiKit.toast(if ok and type(answer) == "table" then failure(answer.reason) else "Please try again.")
				if job.onFail then
					job.onFail()
				end
			end
		end
		busy = false
	end)
end

local function request(data: { [string]: any }, onSuccess: (() -> ())?, onFail: (() -> ())?)
	table.insert(queue, { data = data, onSuccess = onSuccess, onFail = onFail })
	pump()
end

local function findSlime(id: string?): Configuration?
	local folder = if own then own:FindFirstChild("Slimes") else nil
	local found = if folder and id and id ~= "" then folder:FindFirstChild(id) else nil
	return if found and found:IsA("Configuration") then found else nil
end

local renderArea: (string) -> ()

-- Breeding places the player has just filled: shown at once, dropped when the server agrees, refuses, or time is up.
local pendingPairs: { [number]: { a: string, b: string, at: number } } = {}

local function pendingIds(): { [string]: boolean }
	local out: { [string]: boolean } = {}
	for _, item in pendingPairs do
		if os.clock() - item.at <= U.PendingSeconds then
			out[item.a] = true
			out[item.b] = true
		end
	end
	return out
end

-- The pair to show for a place: the pending one while it is still on its way.
local function effectivePair(index: number, real: { [string]: any }): { [string]: any }
	local item = pendingPairs[index]
	if item then
		if (real.a or "") == item.a and (real.b or "") == item.b or os.clock() - item.at > U.PendingSeconds then
			pendingPairs[index] = nil
		else
			return { a = item.a, b = item.b }
		end
	end
	return real
end

-- ===== Picker =====

-- Only slimes that can be used are listed: grown, alive, with no job and not in the breeding program.
local function available(slime: Configuration, spec: Pick, claimed: { [string]: boolean }): boolean
	return UiSlimes.isFree(slime) and slime.Name ~= spec.exclude and not claimed[slime.Name]
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
	local best: UiSlimes.Entry? = nil
	local bestScore = -math.huge
	local claimed = UiSpots.claimed()
	for id in pendingIds() do
		claimed[id] = true
	end
	for _, slime in UiSlimes.slimes(own) do
		if available(slime, spec, claimed) then
			local entry: UiSlimes.Entry = { slime = slime }
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
	-- Second step of a pair: the first slime chosen sits at the right of the header.
	local first = findSlime(spec.exclude)
	if first then
		local box, show = UiSlimes.portrait(bar, first, U.Touch - 4, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
		})
		box.Name = "First"
		show()
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
	UiSlimes.releaseAll()
	UiKit.clear(host)
	drawBackHeader(spec)
	local list = UiSlimes.view(host, pickEntries, spec.choose, true)
	pickView = list
	list.refresh()
end

local anchor: (inst: Instance) -> Instance?
local positionOf: (inst: Instance) -> Vector3?
local findSpot: (area: string, slot: number) -> Instance?

-- The list for one work position: opens at once from cached portraits, one tap assigns, and the marker shows the pick
-- before the server answers. A refusal toasts and puts the marker back.
local function openWorkPick(area: string, slot: number)
	local training = area == "training"
	local work: { [string]: any } = if own then parse(own:GetAttribute("Work")) else {}
	local saved: { [string]: any } = ((work[area] or {}) :: any)[slot] or {}
	local current = UiSpots.workerAt(area, slot)
	local spec: Pick = {
		area = area,
		kind = if training then "train" else "work",
		slot = slot,
		current = current,
		stat = if type(saved.stat) == "string" and saved.stat ~= "" then saved.stat else nil,
		choose = function(_) end,
	}
	local function revert()
		UiSpots.clearOverride(area, slot)
	end
	spec.choose = function(slime)
		local previous = UiSpots.workerAt(area, slot)
		UiKit.closeModal()
		UiSpots.override(area, slot, slime.Name)
		if previous ~= "" then
			request({ action = "Unassign", slimeId = previous }, nil, revert)
		end
		request({ action = "Assign", area = area, slot = slot, slimeId = slime.Name, asReserve = false }, nil, revert)
	end
	local modal = UiKit.openModal("pick", {
		Width = U.SheetWidth,
		Height = U.SheetHeight,
		Bottom = true,
		Dim = 0.8,
		OnClose = function()
			UiSlimes.releaseAll()
			activePoint, pick, pickView = nil, nil, nil
		end,
	})
	local marker = findSpot(area, slot)
	activePoint = if marker then positionOf(marker) else nil
	pick = spec
	UiKit.icon(
		modal.header,
		area,
		U.Touch - 4,
		{ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) }
	)
	UiKit.label(modal.header, areaTitles[area] .. " " .. tostring(slot), U.TextHeader, "Brown", {
		Position = UDim2.fromOffset(U.Touch + U.Gap, 0),
		Size = UDim2.new(1, -U.Touch - U.Gap - (if current ~= "" then U.Touch * 2 + U.Gap else 0), 0, U.Touch),
	})
	if current ~= "" then
		UiKit.button(modal.header, {
			Name = "Remove",
			Text = "Remove",
			Style = "secondary",
			Size = UDim2.fromOffset(U.Touch * 2, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			OnClick = function()
				UiKit.closeModal()
				UiSpots.override(area, slot, "")
				request({ action = "Unassign", slimeId = current }, nil, revert)
			end,
		})
	end
	local listHost = modal.content
	if training then
		local stats = UiKit.make("Frame", {
			Name = "Stats",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, U.Touch),
		}, modal.content)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, U.Gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, stats)
		local buttons: { [string]: TextButton } = {}
		for index, stat in { "attack", "defence", "speed", "hp" } do
			buttons[stat] = UiKit.button(stats, {
				Name = stat,
				Icon = stat,
				Style = if spec.stat == stat then "primary" else "secondary",
				Size = UDim2.fromOffset(U.Touch + 10, U.Touch),
				LayoutOrder = index,
				OnClick = function()
					spec.stat = stat
					for key, other in buttons do
						UiKit.setStyle(other, if key == stat then "primary" else "secondary")
					end
					request({ action = "SetTrainingStat", slot = slot, stat = stat }, nil, nil)
					if pickView then
						pickView.refresh()
					end
				end,
			})
		end
		listHost = UiKit.make("Frame", {
			Name = "List",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, U.Touch + U.Gap),
			Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
		}, modal.content)
	end
	local list = UiSlimes.view(listHost, pickEntries, spec.choose, true)
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

local function levelOf(area: string): number
	local levels = if own then parse(own:GetAttribute("Areas")) else {}
	local value = levels[area]
	return if type(value) == "number" then value else Config.Village.StartLevel
end

-- How many pairs the program holds at the breeding house's level.
local function breedingPlaces(): number
	return FarmState.breedingCount(levelOf("breeding"))
end

local function structureKey(area: string): string
	local parts: { string } = { area }
	local levels = if own then parse(own:GetAttribute("Areas")) else {}
	table.insert(parts, tostring(levels[area]))
	if area == "breeding" then
		local pairs: { any } = if own then parse(own:GetAttribute("Pairs")) :: any else {}
		for index = 1, math.max(breedingPlaces(), #pairs) do
			local pair = effectivePair(index, pairs[index] or {})
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

-- One breeding place: two seats and the heart between. A tap opens the list of free adults; the pick shows at once and
-- the server's answer only confirms it (a refusal toasts and puts the old pair back).
local function breedingRow(scroll: ScrollingFrame, area: string, index: number, pair: { [string]: any }): TextLabel
	local body = rowCard(scroll, U.RowHeight, index)
	local size = U.SeatSize
	local hasA = type(pair.a) == "string" and pair.a ~= ""
	local hasB = type(pair.b) == "string" and pair.b ~= ""
	local function set(a: string, b: string)
		pendingPairs[index] = { a = a, b = b, at = os.clock() }
		renderArea(area)
		request(
			{ action = "SetPair", index = index, a = a ~= "" and a or nil, b = b ~= "" and b or nil },
			nil,
			function()
				pendingPairs[index] = nil
				if activeArea == area then
					renderArea(area)
				end
			end
		)
	end
	local function choose(side: string)
		local has = hasA and hasB
		openPicker({
			area = area,
			kind = "pair",
			slot = index,
			current = if side == "a" then pair.a else pair.b,
			choose = function(slime)
				if has then
					set(if side == "a" then slime.Name else pair.a, if side == "a" then pair.b else slime.Name)
				else
					-- An empty place takes two slimes: the second step leaves out the first.
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
		})
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
	if hasA or hasB then
		UiKit.button(body, {
			Name = "Clear",
			Icon = "cross",
			Style = "secondary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			OnClick = function()
				set("", "")
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
	UiSlimes.releaseAll()
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
	local courting: { [number]: TextLabel } = {}
	local boxHost: Frame? = nil
	local order = 0
	UiKit.label(scroll, "Lv " .. tostring(levelOf(area)), U.TextNormal, "BrownSoft", { LayoutOrder = order })

	if area == "breeding" then
		local pairs: { any } = if own then parse(own:GetAttribute("Pairs")) :: any else {}
		for index = 1, math.max(breedingPlaces(), #pairs) do
			order += 1
			courting[index] = breedingRow(scroll, area, index, effectivePair(index, pairs[index] or {}))
		end
	elseif table.find(Config.Work.Areas, area) then
		-- The workers are picked at their positions in the world (UiSpots); here only what the box holds.
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
	UiSlimes.releaseAll()
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
	task.delay(U.RefreshSeconds, function()
		refreshPending = false
		UiSpots.refresh()
		if UiBook.isOpen() then
			UiBook.refresh()
		end
		local shown = UiKit.modalId()
		if pick and pickView and (shown == "pick" or shown == "sheet") then
			pickView.refresh()
			return
		end
		if shown ~= "sheet" or not activeArea then
			return
		end
		if structureKey(activeArea) ~= renderedKey then
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

function anchor(inst: Instance): Instance?
	if inst:IsA("Attachment") or inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

function positionOf(inst: Instance): Vector3?
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

-- The area's model on the player's plot (named "<Area>L<level>").
local function areaModel(area: string): Instance?
	local plotId = if own then own:GetAttribute("Plot") else nil
	local map = workspace:FindFirstChild("Map")
	local plot = if map and type(plotId) == "number" then map:FindFirstChild("Plot" .. tostring(plotId)) else nil
	if not plot then
		return nil
	end
	for _, child in plot:GetChildren() do
		if string.match(string.lower(child.Name), "^" .. string.lower(modelNames[area]) .. "l") then
			return child
		end
	end
	return nil
end

-- The marker of one work position (WorkSpot<slot>) inside the area's model.
function findSpot(area: string, slot: number): Instance?
	local model = areaModel(area)
	local found = if model then model:FindFirstChild("WorkSpot" .. tostring(slot), true) else nil
	return if found and (found:IsA("BasePart") or found:IsA("Attachment")) then found else nil
end

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
		UiSlimes.prewarm(inst.Parent)
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
	UiSpots.clear()
	table.clear(pendingPairs)
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
		table.insert(
			rootConnections,
			root:GetAttributeChangedSignal(attribute):Connect(function()
				if attribute == "Work" then
					UiSpots.refresh()
				end
				refreshAll()
			end)
		)
	end
	watchFolder(root)
	UiSlimes.prewarm(root)
	UiSpots.refresh()
	table.insert(
		rootConnections,
		root.ChildAdded:Connect(function(child)
			if child.Name == "Slimes" then
				watchFolder(root)
				UiSlimes.prewarm(root)
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

	UiSpots.start({
		own = function()
			return own
		end,
		find = findSpot,
		open = openWorkPick,
		title = function(area)
			return areaTitles[area]
		end,
	})

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
			-- Markers appear as the map streams in and as slots open.
			UiSpots.refresh()
			task.wait(C.FarUpdateSeconds)
		end
	end)
end

return VillageUI
