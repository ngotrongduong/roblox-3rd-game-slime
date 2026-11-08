--!strict
-- The Slime Dungeon's screens (the owner, 2026-11-04). The world is the menu: the portal beside the player's own gate takes
-- the prompt (the other players' portals are switched off for this client) and opens a bottom sheet to choose the teams and
-- the level; inside the arena the screen keeps a small plate at the top (wave, level, monsters left), the run's drops under
-- it, a Leave button at the right edge and a short banner at each wave; when the run ends a card at the top says Victory or
-- Defeated with the drops and the buttons for the next try. The middle of the screen stays empty. Everything is read from
-- what the server publishes (the player's Dungeon* attributes, the village folder) and asked through Remotes.Village; the
-- server decides, so a button it would refuse is greyed or answered with a short line.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DungeonRules = require(ReplicatedStorage.Shared.Dungeon)
local ZombieRules = require(ReplicatedStorage.Shared.Zombies)
local UiHud = require(script.Parent.UiHud)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)
local UiTeams = require(script.Parent.UiTeams)
local ZombieTeams = require(script.Parent.ZombieTeams)

local D = Config.Dungeon
local P = D.View
local U = Config.Ui
local Z = Config.Zombies
local V = Z.View
local FULL = UDim2.fromScale(1, 1)
local player = Players.LocalPlayer

type Context = UiTeams.Context
type Row = {
	root: Frame,
	portraits: Frame,
	key: string,
	body: Frame,
	mark: GuiObject,
	away: GuiObject?,
	awayState: string,
}

local UiDungeon = {}
local ctx: Context? = nil
local layer: Frame? = nil
local plateWave: TextLabel? = nil
local plateLevel: TextLabel? = nil
local plateLeft: TextLabel? = nil
local dropsHost: Frame? = nil
local leaveButton: TextButton? = nil
local endCard: Frame? = nil
local endTitle: TextLabel? = nil
local endDrops: Frame? = nil
local endButtons: Frame? = nil
local bannerGroup: CanvasGroup? = nil
local bannerLabel: TextLabel? = nil
local bannerScale: UIScale? = nil
local bannerToken = 0
local dropsText = ""
local endKey = ""
local shownPhase = ""
local busy = false
local leaveSureUntil = 0
local refreshPending = false
local bound: { [ProximityPrompt]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function context(): Context
	assert(ctx, "UiDungeon.start first")
	return ctx
end

local function merged(base: UiKit.Props, extra: UiKit.Props?): UiKit.Props
	if extra then
		for key, value in extra do
			base[key] = value
		end
	end
	return base
end

-- ===== What the server published =====

local function phase(): string
	local value = player:GetAttribute("DungeonPhase")
	return if type(value) == "string" then value else ""
end

local function numberAttribute(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if type(value) == "number" and value == value then value else default
end

-- The run's drops so far: item -> amount.
local function ledger(): { [string]: number }
	local text = player:GetAttribute("DungeonLedger")
	if type(text) ~= "string" or text == "" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(text)
	end)
	if not ok or type(decoded) ~= "table" then
		return {}
	end
	local found: { [string]: number } = {}
	for item, amount in decoded do
		if type(item) == "string" and type(amount) == "number" and amount > 0 then
			found[item] = amount
		end
	end
	return found
end

-- ===== Pictures of the drops =====

-- A drop as a picture: coins and food with the owner's pictures, a material with its own `icon` once it exists. A material
-- without one yet gets a plain rounded tile with its short name (a stand-in, never the final look).
function UiDungeon.dropIcon(parent: Instance?, item: string, size: number, props: UiKit.Props?): GuiObject
	if item == "coins" or item == "food" then
		return UiKit.icon(parent, item, size, props)
	end
	local entry: any = (D.Materials :: any)[item]
	local icon: any = if entry then entry.icon else nil
	local image: string? = nil
	if type(icon) == "number" and icon > 0 then
		image = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and icon ~= "" then
		image = icon
	end
	if image then
		return UiKit.make(
			"ImageLabel",
			merged({
				Name = item,
				BackgroundTransparency = 1,
				Image = image,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(size, size),
			}, props),
			parent
		)
	end
	local tile = UiKit.make(
		"Frame",
		merged({
			Name = item,
			BackgroundColor3 = UiKit.colour("CardDeep"),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(size, size),
		}, props),
		parent
	)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, tile)
	UiKit.make("UIStroke", { Color = UiKit.colour("BrownSoft"), Thickness = 1 }, tile)
	UiKit.make("UIPadding", {
		PaddingLeft = UDim.new(0, 1),
		PaddingRight = UDim.new(0, 1),
	}, tile)
	local name = UiKit.label(tile, if entry and entry.short then entry.short else item, U.TextTiny, "Brown", {
		Size = FULL,
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
	})
	UiKit.make("UITextSizeConstraint", { MaxTextSize = U.TextTiny, MinTextSize = 5 }, name)
	return tile
end

-- A drop and its number on a small wooden plate (a run's winnings, a range on the gate sheet).
local function dropChip(parent: Instance, item: string, text: string, order: number): Frame
	local height = P.DropChip
	local box, body = UiKit.skin(parent, "Wood", "Card", {
		Name = item,
		Size = UDim2.fromOffset(P.DropIcon + 22 + #text * 8, height),
		LayoutOrder = order,
	})
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)
	UiDungeon.dropIcon(body, item, P.DropIcon, { LayoutOrder = 1 })
	UiKit.label(body, text, U.TextSmall, "Brown", {
		Name = "Value",
		LayoutOrder = 2,
		Size = UDim2.new(1, -P.DropIcon - 4, 1, 0),
	})
	return box
end

-- Fills a wrapping row with the run's drops in their order (nothing when there are none).
local function fillDrops(host: Frame, drops: { [string]: number })
	UiKit.clear(host)
	for index, item in D.DropOrder do
		local amount = drops[item]
		if amount then
			dropChip(host, item, tostring(amount), index)
		end
	end
end

-- What a run of this map can drop, as a range for each item (from the drop lines of its monsters).
local function dropRanges(map: any): { [string]: string }
	local found: { [string]: { number } } = {}
	for _, def in map.monsters do
		for _, line in def.drops do
			local seen = found[line.item]
			if seen then
				seen[1], seen[2] = math.min(seen[1], line.min), math.max(seen[2], line.max)
			else
				found[line.item] = { line.min, line.max }
			end
		end
	end
	local out: { [string]: string } = {}
	for item, range in found do
		out[item] = if range[1] == range[2] then tostring(range[1]) else range[1] .. "-" .. range[2]
	end
	return out
end

-- ===== The gate sheet =====

local function teamsOpen(): number
	local own = context().own()
	local level = if own then own:GetAttribute("VillageLevel") else nil
	return ZombieRules.teamsOpen(if type(level) == "number" then level else 1, ZombieTeams.extra())
end

local function slimeById(id: string): Configuration?
	local own = context().own()
	local folder = if own then own:FindFirstChild("Slimes") else nil
	local found = if folder then folder:FindFirstChild(id) else nil
	return if found and found:IsA("Configuration") then found else nil
end

local function teamRow(scroll: Instance, index: number, onTap: () -> ()): Row
	local root, body = UiKit.card(scroll, { Size = UDim2.new(1, -8, 0, P.TeamRowHeight), LayoutOrder = 10 + index })
	UiKit.label(body, tostring(index), U.TextNormal, "Brown", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(16, U.Touch),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local portraits = UiKit.make("Frame", {
		Name = "Portraits",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(P.TeamPortrait * Z.TeamSize + 2 * (Z.TeamSize - 1), P.TeamPortrait),
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, portraits)
	-- the sword shows on the teams that will go
	local mark = UiKit.icon(body, "attack", U.IconNormal, {
		Name = "Going",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Visible = false,
	})
	UiKit.make("TextButton", {
		Name = "Tap",
		BackgroundTransparency = 1,
		Text = "",
		Size = FULL,
		ZIndex = 20,
	}, root).Activated
		:Connect(onTap)
	return { root = root, portraits = portraits, key = "", body = body, mark = mark, away = nil, awayState = "" }
end

local function openGate(point: Vector3)
	local c = context()
	if phase() ~= "" then
		return
	end
	local top = numberAttribute("DungeonBest", 0) + D.FirstLevel
	local level = top
	local selected: { [number]: boolean } = {}
	local picked = false
	local busyEnter = false
	local rows: { [number]: Row } = {}
	local tick: () -> () = function() end
	local modal = c.open("dungeon", P.GateSheetHeight, function()
		tick()
	end, point, D.Portal.PromptRangeStuds * 1.3)

	-- the map turns with the level (shared/Dungeon.mapForLevel: the same one the server builds), so the title and the list of
	-- what drops follow the stepper
	UiKit.icon(modal.header, "dungeon", U.Touch - 12, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	})
	local title = UiKit.label(modal.header, "", U.TextHeader, "Brown", {
		Position = UDim2.fromOffset(U.Touch + U.Gap - 6, 0),
		Size = UDim2.new(1, -U.Touch - U.Gap + 6, 0, U.Touch),
	})
	local shownMap = ""

	local scroll = UiKit.make("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, modal.content)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroll)

	-- what the dungeon gives, as a plain list in two columns: picture, name, how many (the owner, 2026-11-04: a list,
	-- not a framed plate each)
	local drops = UiKit.make("Frame", {
		Name = "Drops",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 0,
	}, scroll)
	UiKit.make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -U.Gap / 2, 0, P.DropRow),
		CellPadding = UDim2.fromOffset(U.Gap, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, drops)
	local function showMap(mapId: string)
		shownMap = mapId
		local map: any = (D.Maps :: any)[mapId]
		title.Text = map.name
		UiKit.clear(drops)
		local ranges = dropRanges(map)
		for order, item in D.DropOrder do
			if ranges[item] then
				local entry: any = (D.Materials :: any)[item]
				local line =
					UiKit.make("Frame", { Name = item, BackgroundTransparency = 1, LayoutOrder = order }, drops)
				UiDungeon.dropIcon(line, item, P.DropIcon, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
				})
				UiKit.label(line, if entry then entry.name else item, U.TextSmall, "Brown", {
					Position = UDim2.fromOffset(P.DropIcon + 6, 0),
					Size = UDim2.new(1, -P.DropIcon - 6 - P.DropRangeWidth, 1, 0),
				})
				UiKit.label(line, ranges[item], U.TextSmall, "BrownSoft", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.new(0, P.DropRangeWidth, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
				})
			end
		end
	end

	local function usable(index: number): boolean
		local team = ZombieTeams.get(index)
		return team ~= nil and #team.members > 0 and team.state == "home"
	end

	for index = 1, Z.Teams do
		rows[index] = teamRow(scroll, index, function()
			if usable(index) then
				if selected[index] then
					selected[index] = nil
				else
					selected[index] = true
				end
				tick()
			else
				local team = ZombieTeams.get(index)
				UiKit.toast(c.reason(if team and #team.members > 0 then "TEAM_OUT" else "NO_MEMBERS"))
			end
		end)
	end

	-- the bottom bar: the level stepper (arrows and "Lv n") and Enter
	local bar = UiKit.make("Frame", {
		Name = "Bar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, modal.content)
	local levelLabel: TextLabel
	local lower: TextButton
	local higher: TextButton
	local function setLevel(next: number)
		level = math.clamp(next, D.FirstLevel, top)
		tick()
	end
	lower = UiKit.button(bar, {
		Name = "Lower",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(P.StepperButton, U.Touch),
		OnClick = function()
			setLevel(level - 1)
		end,
	})
	levelLabel = UiKit.label(bar, "", U.TextHeader, "Brown", {
		Position = UDim2.fromOffset(P.StepperButton, 0),
		Size = UDim2.fromOffset(P.StepperLabel, U.Touch),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	higher = UiKit.button(bar, {
		Name = "Higher",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(P.StepperButton, U.Touch),
		Position = UDim2.fromOffset(P.StepperButton + P.StepperLabel, 0),
		OnClick = function()
			setLevel(level + 1)
		end,
	})
	-- (the one arrow picture points left; the right button turns it round. The turn goes on the button's Visual canvas
	-- group: an image inside a CanvasGroup is drawn unturned, whatever its own Rotation)
	local turned = higher:FindFirstChild("Visual")
	if turned and turned:IsA("GuiObject") then
		turned.Rotation = 180
	end
	local enter: TextButton
	enter = UiKit.button(bar, {
		Name = "Enter",
		Text = "Enter",
		Style = "primary",
		Size = UDim2.fromOffset(P.EnterWidth, U.Touch),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Enabled = false,
		OnClick = function()
			if busyEnter then
				return
			end
			local teams: { number } = {}
			for index in selected do
				table.insert(teams, index)
			end
			table.sort(teams)
			if #teams == 0 then
				return
			end
			busyEnter = true
			UiKit.setEnabled(enter, false)
			task.spawn(function()
				local ok, why = c.ask({ action = "DungeonEnter", level = level, teams = teams })
				busyEnter = false
				if ok then
					if UiKit.modalId() == "dungeon" then
						UiKit.closeModal()
					end
					-- the intro that pointed here is done with
					local own = c.own()
					if own and own:GetAttribute("GuideId") == "dungeon" then
						c.ask({ action = "GuideSkip" })
					end
				else
					UiKit.toast(c.reason(why))
				end
			end)
		end,
	})

	tick = function()
		if phase() ~= "" then
			UiKit.closeModal()
			return
		end
		local open = teamsOpen()
		for index, row in rows do
			local team = ZombieTeams.get(index)
			row.root.Visible = index <= open and team ~= nil
			if team and row.root.Visible then
				local key = table.concat(team.members, ",")
				if key ~= row.key then
					row.key = key
					for _, child in row.portraits:GetChildren() do
						if child:IsA("GuiObject") then
							UiSlimes.park(child)
						end
					end
					UiKit.clear(row.portraits)
					local order = 0
					for _, id in team.members do
						local slime = slimeById(id)
						if slime then
							order += 1
							local _, show = UiSlimes.portrait(
								row.portraits,
								slime,
								P.TeamPortrait,
								{ LayoutOrder = order },
								"card",
								true
							)
							show()
						end
					end
				end
				local ready = usable(index)
				if not ready then
					selected[index] = nil
				end
				-- the team's state shows when it is out (a team that is empty shows nothing)
				local away = team.state ~= "home" and #team.members > 0
				local state = if away then (V.StateIcons :: any)[team.state] or V.StateIcons.going else ""
				if state ~= row.awayState then
					row.awayState = state
					if row.away then
						row.away:Destroy()
						row.away = nil
					end
					if state ~= "" then
						row.away = UiKit.icon(row.body, state, U.IconNormal, {
							Name = "Away",
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.fromScale(1, 0.5),
						})
					end
				end
				row.mark.Visible = selected[index] == true
				UiKit.setFill(row.root, if selected[index] then "GoldLight" elseif ready then "Card" else "CardDeep")
			end
		end
		-- the first team that can go is chosen at the start
		if not picked then
			for index = 1, open do
				if usable(index) then
					selected[index] = true
					picked = true
					break
				end
			end
			if picked then
				tick()
				return
			end
		end
		top = numberAttribute("DungeonBest", 0) + D.FirstLevel
		level = math.clamp(level, D.FirstLevel, top)
		local mapId = DungeonRules.mapForLevel(player.UserId, level)
		if mapId ~= shownMap then
			showMap(mapId)
		end
		levelLabel.Text = "Lv " .. level
		UiKit.setEnabled(lower, level > D.FirstLevel)
		UiKit.setEnabled(higher, level < top)
		UiKit.setEnabled(enter, next(selected) ~= nil and not busyEnter)
	end
	tick()
end

-- ===== The portals =====

-- Why this player may not go in yet (Dungeon.entryBlock, read from what the village folder shows): "FEW_SLIMES",
-- "VILLAGE_LEVEL" or nil. The server checks the same.
local function entryBlock(): string?
	local own = context().own()
	local folder = if own then own:FindFirstChild("Slimes") else nil
	local level = if own then own:GetAttribute("VillageLevel") else nil
	if not folder or #folder:GetChildren() < D.EnterMinSlimes then
		return "FEW_SLIMES"
	elseif type(level) ~= "number" or level < D.EnterMinVillageLevel then
		return "VILLAGE_LEVEL"
	end
	return nil
end

-- The one portal in the Market (everyone's; each player goes to their own arena): its prompt opens the gate sheet, or says
-- in one line what is missing while a lock hangs over the ring. Called every GateWatchSeconds: the portal streams in with
-- the map.
local function watchPortals()
	local folder = workspace:FindFirstChild("DungeonPortals")
	if not folder then
		return
	end
	local free = phase() == ""
	local locked = entryBlock() ~= nil
	for _, portal in folder:GetChildren() do
		local trigger = portal:FindFirstChild("PortalTrigger")
		local prompt = if trigger then trigger:FindFirstChild("DungeonPrompt") else nil
		if trigger and trigger:IsA("BasePart") and prompt and prompt:IsA("ProximityPrompt") then
			if not bound[prompt] then
				bound[prompt] = true
				prompt.Triggered:Connect(function()
					local why = entryBlock()
					if why then
						UiKit.toast(context().reason(why))
					else
						openGate(trigger.Position)
					end
				end)
			end
			prompt.Enabled = free
			prompt.ActionText = if locked then "Locked" else "Enter"
			-- the lock: a picture over the ring, drawn for this player only (a client-made billboard)
			local lock = trigger:FindFirstChild("DungeonLock")
			if locked and not lock then
				local board = Instance.new("BillboardGui")
				board.Name = "DungeonLock"
				board.Size = UDim2.fromOffset(D.Portal.LockPixels, D.Portal.LockPixels)
				board.AlwaysOnTop = false
				board.LightInfluence = 0
				board.MaxDistance = D.Portal.LockShowStuds
				UiKit.icon(board, "lock", D.Portal.LockPixels, { Size = FULL })
				board.Parent = trigger
			elseif lock and not locked then
				lock:Destroy()
			end
		end
	end
end

-- ===== The arena screen =====

local function setLabel(button: GuiButton, text: string)
	local label = button:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- One request of a run (Leave, Next, Replay); a refusal is a short line.
local function request(action: string)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local c = context()
		local ok, why = c.ask({ action = action })
		busy = false
		if not ok then
			UiKit.toast(c.reason(why))
		end
	end)
end

local function endButton(
	parent: Instance,
	name: string,
	text: string,
	icon: string?,
	style: string,
	order: number,
	onClick: () -> ()
)
	return UiKit.button(parent, {
		Name = name,
		Text = text,
		Icon = icon,
		Style = style,
		Size = UDim2.fromScale(0, 1),
		LayoutOrder = order,
		OnClick = onClick,
	})
end

-- The end card: the title, the drops of the run and the buttons of the next try. Drawn again only when the end changes.
local function drawEnd(current: string)
	local card, title, dropsFrame, buttons = endCard, endTitle, endDrops, endButtons
	if not (card and title and dropsFrame and buttons) then
		return
	end
	local victory = current == "VICTORY"
	local key = current .. ":" .. tostring(numberAttribute("DungeonLevel", 0))
	if key ~= endKey then
		endKey = key
		title.Text = if victory then "Victory!" else "Defeated"
		title.TextColor3 = UiKit.colour(if victory then "Green" else "Red")
		UiKit.clear(buttons)
		local count = if victory then 3 else 2
		local order = 0
		local function add(name: string, text: string, icon: string?, style: string, action: string)
			order += 1
			local button = endButton(buttons, name, text, icon, style, order, function()
				request(action)
			end)
			button.Size = UDim2.new(1 / count, -U.Gap * (count - 1) / count, 1, 0)
		end
		if victory then
			add("Next", "Next Level", nil, "primary", "DungeonNext")
		end
		add("Replay", "Replay", "again", if victory then "secondary" else "primary", "DungeonReplay")
		add("Leave", "Leave", "back", "secondary", "DungeonLeave")
		dropsText = ""
	end
	local text = player:GetAttribute("DungeonLedger")
	local now = if type(text) == "string" then text else ""
	if now ~= dropsText then
		dropsText = now
		fillDrops(dropsFrame, ledger())
	end
end

local function refreshHud()
	refreshPending = false
	local host, wave, lvl, left = layer, plateWave, plateLevel, plateLeft
	local drops, leave = dropsHost, leaveButton
	if not (host and wave and lvl and left and drops and leave) then
		return
	end
	local current = phase()
	local running = current ~= ""
	local ended = current == "VICTORY" or current == "DEFEAT"
	if running ~= (shownPhase ~= "") then
		UiHud.setArena(running)
		if running and UiKit.modalId() == "dungeon" then
			UiKit.closeModal()
		end
	end
	shownPhase = current
	host.Visible = running and not ended
	if endCard then
		endCard.Visible = ended
	end
	if not running then
		endKey = ""
		dropsText = ""
		return
	end
	if ended then
		drawEnd(current)
		return
	end
	local total = numberAttribute("DungeonWaves", D.Waves)
	wave.Text = "Wave " .. math.max(1, numberAttribute("DungeonWave", 1)) .. "/" .. total
	lvl.Text = "Lv " .. numberAttribute("DungeonLevel", D.FirstLevel)
	left.Text = tostring(numberAttribute("DungeonLeft", 0))
	local text = player:GetAttribute("DungeonLedger")
	local now = if type(text) == "string" then text else ""
	if now ~= dropsText then
		dropsText = now
		fillDrops(drops, ledger())
	end
end

local function scheduleHud()
	if refreshPending then
		return
	end
	refreshPending = true
	task.defer(refreshHud)
end

local function buildHud()
	local root = UiKit.root()
	local host =
		UiKit.make("Frame", { Name = "DungeonHud", BackgroundTransparency = 1, Size = FULL, Visible = false }, root)
	layer = host

	-- the plate at the top: wave, level, monsters left
	local _, plateBody = UiKit.card(host, {
		Name = "Plate",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, U.Edge),
		Size = UDim2.fromOffset(P.PlateWidth, P.PlateHeight),
	})
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, plateBody)
	local height = P.PlateHeight - 12
	plateWave = UiKit.label(plateBody, "", U.TextNormal, "Brown", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(P.PlateWave, height),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	plateLevel = UiKit.label(plateBody, "", U.TextNormal, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromOffset(P.PlateLevel, height),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	UiKit.icon(plateBody, "skull", P.DropIcon, { LayoutOrder = 3 })
	plateLeft = UiKit.label(plateBody, "", U.TextNormal, "Brown", {
		LayoutOrder = 4,
		Size = UDim2.fromOffset(P.PlateLeft, height),
	})

	-- the run's drops under the plate
	local strip = UiKit.make("Frame", {
		Name = "Drops",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, U.Edge + P.PlateHeight + U.Gap),
		Size = UDim2.fromOffset(P.DropsWidth, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, host)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Wraps = true,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, strip)
	dropsHost = strip

	-- Leave at the right edge: a second press within a moment confirms (the wave in play gives nothing)
	local leave: TextButton
	leave = UiKit.button(host, {
		Name = "Leave",
		Text = "Leave",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(P.LeaveWidth, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -U.Edge, 0.5, 0),
		OnClick = function()
			if os.clock() > leaveSureUntil then
				leaveSureUntil = os.clock() + V.ConfirmSeconds
				UiKit.setStyle(leave, "danger")
				setLabel(leave, "Sure?")
				task.delay(V.ConfirmSeconds, function()
					if os.clock() >= leaveSureUntil then
						UiKit.setStyle(leave, "secondary")
						setLabel(leave, "Leave")
					end
				end)
				return
			end
			leaveSureUntil = 0
			UiKit.setStyle(leave, "secondary")
			setLabel(leave, "Leave")
			request("DungeonLeave")
		end,
	})
	leaveButton = leave

	-- the end card, at the top so the squad and the arena stay in view
	local card, body = UiKit.card(root, {
		Name = "DungeonEnd",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, U.Edge),
		Size = UDim2.new(1, -2 * U.Edge, 0, P.EndHeight),
		Visible = false,
	})
	UiKit.make("UISizeConstraint", { MaxSize = Vector2.new(P.EndWidth, P.EndHeight) }, card)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)
	endTitle = UiKit.label(body, "", U.TextHeader + 4, "Brown", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, P.EndTitle),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local wrap = UiKit.make("Frame", {
		Name = "Drops",
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Wraps = true,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, wrap)
	endDrops = wrap
	local row = UiKit.make("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	endButtons = row
	endCard = card

	-- the wave banner: a short word that pops in and fades, no camera effects
	local group = UiKit.make("CanvasGroup", {
		Name = "WaveBanner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, P.BannerTop),
		Size = UDim2.fromOffset(320, P.BannerSize + 16),
		GroupTransparency = 1,
		ZIndex = 15,
	}, root)
	bannerScale = UiKit.make("UIScale", { Scale = 1 }, group)
	bannerLabel = UiKit.make("TextLabel", {
		BackgroundTransparency = 1,
		Size = FULL,
		Font = Enum.Font.FredokaOne,
		Text = "",
		TextSize = P.BannerSize,
		TextColor3 = Color3.fromHex(P.BannerColours.normal),
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(40, 28, 20),
	}, group)
	bannerGroup = group
end

-- "Wave 3", "Mini-boss!" or "Boss!" for a moment; a new one replaces the last.
function UiDungeon.banner(waveKind: string, wave: number)
	local group, label, scale = bannerGroup, bannerLabel, bannerScale
	if not (group and label and scale) then
		return
	end
	label.Text = if waveKind == "boss" then "Boss!" elseif waveKind == "miniboss" then "Mini-boss!" else "Wave " .. wave
	label.TextColor3 = Color3.fromHex((P.BannerColours :: any)[waveKind] or P.BannerColours.normal)
	bannerToken += 1
	local mine = bannerToken
	scale.Scale = 0.6
	group.GroupTransparency = 1
	UiKit.tween(group, 0.15, { GroupTransparency = 0 })
	UiKit.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(P.BannerSeconds, function()
		if mine == bannerToken then
			UiKit.tween(group, 0.35, { GroupTransparency = 1 })
		end
	end)
end

function UiDungeon.start(context_: Context)
	ctx = context_
	buildHud()
	for _, name in { "DungeonPhase", "DungeonWave", "DungeonWaves", "DungeonLevel", "DungeonLeft", "DungeonLedger" } do
		player:GetAttributeChangedSignal(name):Connect(scheduleHud)
	end
	scheduleHud()
	task.spawn(function()
		local warned = false
		while true do
			local ok, err = pcall(function(): any
				watchPortals()
				return nil
			end)
			if not ok and not warned then
				warned = true
				warn(Config.LogPrefix, "dungeon portals error:", err)
			end
			task.wait(P.GateWatchSeconds)
		end
	end)
end

return UiDungeon
