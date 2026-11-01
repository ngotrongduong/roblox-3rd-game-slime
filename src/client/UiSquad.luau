--!strict
-- The screens of the zombie fights and the shop (docs/ECONOMY.md): the sheet that picks a squad for a group, the chip and
-- sheet for the dead (revive before they are lost for good) and the Market's sell sheet. They read what the server
-- publishes (slime attributes, Camps, Squads, Storehouse, Coins) and ask through Remotes.Village; the server decides, so a
-- button it would refuse is greyed or answered with a short friendly line.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local ZombieRules = require(ReplicatedStorage.Shared.Zombies)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)
local ZombieLook = require(script.Parent.ZombieLook)
local ZombieWorld = require(script.Parent.ZombieWorld)

local U = Config.Ui
local Z = Config.Zombies
local V = Z.View
local player = Players.LocalPlayer

type Sheet = {
	id: string,
	tick: () -> (),
	-- walking farther than range from point closes the sheet
	point: Vector3?,
	range: number,
}
type Dead = { slime: Configuration, left: number }

local UiSquad = {}
local ownOf: () -> Folder? = function()
	return nil
end
local sheet: Sheet? = nil
local chip: UiKit.Chip? = nil
local watchedFolder: Instance? = nil
local lostConnection: RBXScriptConnection? = nil

local reasons: { [string]: string } = {
	TOO_FAR = "Too far away.",
	TOO_MANY_SQUADS = "All squads are out.",
	NOT_WAITING = "Already fighting.",
	CANNOT_SEND = "Not ready to fight.",
	OUT = "Out fighting.",
	NO_FOOD = "Not enough food.",
	NOT_DEAD = "Already back.",
	FAVOURITE = "A favourite.",
	DEAD = "Fallen.",
	AT_WORK = "At work.",
	IN_PAIR = "In a pair.",
	LAST_SLIMES = "Keep the last two.",
	BAD_SIZE = "Pick one to four.",
	NO_SLIME = "Slime not found.",
	NO_GROUP = "Group is gone.",
	RATE_LIMIT = "One moment.",
	NOT_READY = "Village is loading.",
}

local function reasonText(reason: any): string
	return if type(reason) == "string" and reasons[reason] then reasons[reason] else "Please try again."
end

-- One request to the server; yields, so callers run it in task.spawn.
local function ask(data: { [string]: any }): (boolean, string?)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = if remotes then remotes:FindFirstChild("Village") else nil
	if not remote or not remote:IsA("RemoteFunction") then
		return false, "NOT_READY"
	end
	local ok, answer = pcall(function()
		return remote:InvokeServer(data)
	end)
	if ok and type(answer) == "table" then
		return answer.ok == true, answer.reason
	end
	return false, "SERVER_ERROR"
end

local function flatDistance(point: Vector3): number?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return nil
	end
	return Vector3.new(root.Position.X - point.X, 0, root.Position.Z - point.Z).Magnitude
end

local function squadsOut(): number
	local own = ownOf()
	local folder = if own then own:FindFirstChild("Squads") else nil
	return if folder then #folder:GetChildren() else 0
end

local function clock(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function list(parent: Instance): ScrollingFrame
	local scroller = UiKit.make("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroller)
	return scroller
end

-- Redraws a list when its members change, keeping the scroll place.
local function rebuild(scroller: ScrollingFrame, build: () -> ())
	local keep = scroller.CanvasPosition
	UiSlimes.releaseAll()
	UiKit.clear(scroller)
	build()
	task.defer(function()
		if scroller.Parent then
			scroller.CanvasPosition = keep
		end
	end)
end

local function setLabel(button: GuiButton, text: string)
	local label = button:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function openSheet(id: string, onClose: (() -> ())?): UiKit.Modal
	local modal = UiKit.openModal(id, {
		Width = U.SheetWidth,
		Height = U.SheetHeight,
		Bottom = true,
		Dim = 0.8,
		OnClose = function()
			UiSlimes.releaseAll()
			sheet = nil
			if onClose then
				onClose()
			end
		end,
	})
	return modal
end

-- ===== The squad sheet =====

-- A slime that can go: grown, alive, awake, not at work or in a pair, not already out.
local function canGo(slime: Configuration): boolean
	return UiSlimes.isFree(slime)
		and slime:GetAttribute("OutOnSquad") ~= true
		and slime:GetAttribute("Sleeping") ~= true
		and UiSlimes.number(slime, "Energy") > Config.Needs.Tired
end

local function candidates(): { Configuration }
	local found: { Configuration } = {}
	for _, slime in UiSlimes.slimes(ownOf()) do
		if canGo(slime) then
			table.insert(found, slime)
		end
	end
	table.sort(found, function(a, b)
		local left, right = UiSlimes.number(a, "Level"), UiSlimes.number(b, "Level")
		if left ~= right then
			return left > right
		end
		return a.Name < b.Name
	end)
	return found
end

local function openGroup(groupId: string)
	local group = ZombieWorld.group(groupId)
	if not group or group.state ~= "waiting" then
		UiKit.toast(reasonText("NOT_WAITING"))
		return
	end
	local modal = openSheet("squad", nil)
	local selected: { string } = {}
	local tiles: { [string]: Frame } = {}
	local order: { string } = {}
	local signature = ""

	-- the header: what the group holds, its level, and how many squads are out
	local head = UiKit.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, modal.header)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, head)
	local kinds: { Configuration } = {}
	for config in group.entries do
		table.insert(kinds, config)
	end
	table.sort(kinds, function(a, b)
		return a.Name < b.Name
	end)
	for index, config in kinds do
		local entry = group.entries[config]
		ZombieLook.icon(head, entry.kind, U.Touch - 12, { LayoutOrder = index })
	end
	UiKit.label(head, "Lv " .. tostring(group.level), U.TextNormal, "Brown", {
		LayoutOrder = 10,
		Size = UDim2.fromOffset(58, U.Touch),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local squadsLabel = UiKit.label(head, "", U.TextNormal, "BrownSoft", {
		LayoutOrder = 11,
		Size = UDim2.fromOffset(46, U.Touch),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local scroller = list(modal.content)
	scroller.Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap)
	UiKit.make("UIGridLayout", {
		CellPadding = UDim2.fromOffset(U.Gap, U.Gap),
		CellSize = UDim2.fromOffset(V.TileWidth, V.TileHeight),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroller)
	local bottom = UiKit.make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, modal.content)

	local go: TextButton
	local function paint()
		local chosen: { [string]: boolean } = {}
		for _, id in selected do
			chosen[id] = true
		end
		for id, fill in tiles do
			fill.BackgroundColor3 = UiKit.colour(if chosen[id] then "Portrait" else "Card")
		end
		UiKit.setEnabled(go, #selected > 0 and squadsOut() < Z.Teams)
	end
	UiKit.button(bottom, {
		Name = "Best",
		Icon = "attack",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch + 16, U.Touch),
		OnClick = function()
			selected = {}
			for index = 1, math.min(#order, Z.TeamSize) do
				table.insert(selected, order[index])
			end
			paint()
		end,
	})
	go = UiKit.button(bottom, {
		Name = "Go",
		Text = "Fight",
		Style = "primary",
		Size = UDim2.fromOffset(120, U.Touch),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Enabled = false,
		OnClick = function()
			local ids = table.clone(selected)
			UiKit.setEnabled(go, false)
			task.spawn(function()
				local ok, why = ask({ action = "SendSquad", groupId = groupId, slimeIds = ids })
				if ok then
					if UiKit.modalId() == "squad" then
						UiKit.closeModal()
					end
				else
					UiKit.toast(reasonText(why))
					paint()
				end
			end)
		end,
	})

	local function build(slimes: { Configuration })
		table.clear(tiles)
		table.clear(order)
		for index, slime in slimes do
			table.insert(order, slime.Name)
			local root = UiKit.make("TextButton", {
				Name = slime.Name,
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				LayoutOrder = index,
			}, scroller)
			local box, body = UiKit.card(root, { Size = UDim2.fromScale(1, 1) })
			local size = V.TileWidth - 24
			local _, show = UiSlimes.portrait(body, slime, size, { Position = UDim2.new(0.5, -size / 2, 0, 0) })
			show()
			UiKit.label(body, "Lv " .. tostring(UiSlimes.number(slime, "Level")), U.TextSmall, "Brown", {
				Position = UDim2.fromOffset(0, size + 2),
				Size = UDim2.new(1, 0, 0, U.TextSmall + 6),
				TextXAlignment = Enum.TextXAlignment.Center,
			})
			local fill = box:FindFirstChild("Fill")
			if fill and fill:IsA("Frame") then
				tiles[slime.Name] = fill
			end
			root.Activated:Connect(function()
				local at = table.find(selected, slime.Name)
				if at then
					table.remove(selected, at)
				elseif #selected < Z.TeamSize then
					table.insert(selected, slime.Name)
				end
				paint()
			end)
		end
	end

	local function tick()
		local live = ZombieWorld.group(groupId)
		if not live or live.state ~= "waiting" then
			UiKit.toast(reasonText("NOT_WAITING"))
			UiKit.closeModal()
			return
		end
		squadsLabel.Text = tostring(squadsOut()) .. "/" .. tostring(Z.Teams)
		local slimes = candidates()
		local names: { string } = {}
		for _, slime in slimes do
			table.insert(names, slime.Name)
		end
		local now = table.concat(names, "|")
		if now ~= signature then
			signature = now
			for index = #selected, 1, -1 do
				if not table.find(names, selected[index]) then
					table.remove(selected, index)
				end
			end
			rebuild(scroller, function()
				build(slimes)
			end)
		end
		paint()
	end
	sheet = { id = "squad", tick = tick, point = group.position, range = Z.SendRangeStuds * 1.25 }
	tick()
end

-- ===== The dead =====

local function deadSlimes(): { Dead }
	local found: { Dead } = {}
	local now = workspace:GetServerTimeNow()
	for _, slime in UiSlimes.slimes(ownOf()) do
		if UiSlimes.isGhost(slime) then
			local until_ = UiSlimes.number(slime, "GhostUntil")
			table.insert(found, {
				slime = slime,
				left = if until_ > 0 then math.max(0, until_ - now) else Config.Village.GhostSeconds,
			})
		end
	end
	table.sort(found, function(a, b)
		if a.left ~= b.left then
			return a.left < b.left
		end
		return a.slime.Name < b.slime.Name
	end)
	return found
end

-- The raw food in the storehouse: what a revive spends.
local function foodCount(): number
	local store = UiFood.read(ownOf())
	local total = 0
	for _, kind in Config.Food.RawOrder do
		total += store[kind] or 0
	end
	return total
end

local function timeColour(left: number): Color3
	return UiKit.colour(if left < V.ReviveWarnSeconds then "Red" else "Brown")
end

local function openRevive()
	local modal = openSheet("revive", nil)
	UiKit.icon(modal.header, "skull", U.Touch - 12, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	})
	local scroller = list(modal.content)
	UiKit.make("UIListLayout", {
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroller)
	local rows: { [string]: { time: TextLabel, button: TextButton, cost: number } } = {}
	local signature = ""

	local function build(dead: { Dead })
		table.clear(rows)
		for index, item in dead do
			local slime = item.slime
			local level = UiSlimes.number(slime, "Level")
			local cost = ZombieRules.reviveCost(level)
			local _, body = UiKit.card(scroller, { Size = UDim2.new(1, 0, 0, 64), LayoutOrder = index })
			local _, show = UiSlimes.portrait(body, slime, 48, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
			})
			show()
			UiKit.label(body, "Lv " .. tostring(level), U.TextSmall, "Brown", {
				Position = UDim2.fromOffset(56, 6),
				Size = UDim2.fromOffset(80, 20),
			})
			local time = UiKit.label(body, clock(item.left), U.TextNormal, "Brown", {
				Position = UDim2.fromOffset(56, 28),
				Size = UDim2.fromOffset(80, 24),
			})
			local button = UiKit.button(body, {
				Name = "Revive",
				Text = "Revive",
				Style = "good",
				Size = UDim2.fromOffset(92, 40),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				OnClick = function()
					UiKit.setEnabled(rows[slime.Name].button, false)
					task.spawn(function()
						local ok, why = ask({ action = "Revive", slimeId = slime.Name })
						if not ok then
							UiKit.toast(reasonText(why))
						end
					end)
				end,
			})
			local price = UiKit.make("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -100, 0.5, 0),
				Size = UDim2.fromOffset(64, 28),
			}, body)
			UiKit.make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, price)
			UiKit.label(price, tostring(cost), U.TextNormal, "Brown", {
				LayoutOrder = 1,
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
			})
			UiKit.icon(price, "food", U.IconNormal, { LayoutOrder = 2 })
			rows[slime.Name] = { time = time, button = button, cost = cost }
		end
	end

	local function tick()
		local dead = deadSlimes()
		if #dead == 0 then
			UiKit.closeModal()
			return
		end
		local names: { string } = {}
		for _, item in dead do
			table.insert(names, item.slime.Name)
		end
		local now = table.concat(names, "|")
		if now ~= signature then
			signature = now
			rebuild(scroller, function()
				build(dead)
			end)
		end
		local food = foodCount()
		for _, item in dead do
			local row = rows[item.slime.Name]
			if row then
				row.time.Text = clock(item.left)
				row.time.TextColor3 = timeColour(item.left)
				UiKit.setEnabled(row.button, food >= row.cost)
			end
		end
	end
	sheet = { id = "revive", tick = tick, point = nil, range = 0 }
	tick()
end

-- The small chip at the left edge: how many are dead and the shortest time left. A slime whose model vanishes while it
-- was a ghost is lost for good: a short toast says so.
local function refreshChip()
	local item = chip
	if not item then
		return
	end
	local own = ownOf()
	local dead = if own then deadSlimes() else {}
	item.root.Visible = #dead > 0
	if #dead > 0 then
		item.set(tostring(#dead) .. "  " .. clock(dead[1].left))
		local value = item.root:FindFirstChild("Value", true)
		if value and value:IsA("TextLabel") then
			value.TextColor3 = timeColour(dead[1].left)
		end
	end
	local folder = if own then own:FindFirstChild("Slimes") else nil
	if folder ~= watchedFolder then
		if lostConnection then
			lostConnection:Disconnect()
			lostConnection = nil
		end
		watchedFolder = folder
		if folder then
			lostConnection = folder.ChildRemoved:Connect(function(gone)
				if gone:GetAttribute("Ghost") == true then
					UiKit.toast(UiSlimes.name(gone) .. " is gone")
				end
			end)
		end
	end
end

-- ===== The shop =====

local function appearanceOf(slime: Configuration): { type: string, definitionId: string? }
	local secret, material, dual =
		slime:GetAttribute("SecretId"), slime:GetAttribute("Material"), slime:GetAttribute("DualId")
	if type(secret) == "string" and secret ~= "" then
		return { type = "secret", definitionId = secret }
	elseif type(material) == "string" and material ~= "" then
		return { type = "material", definitionId = material }
	elseif type(dual) == "string" and dual ~= "" then
		return { type = "dual", definitionId = dual }
	end
	return { type = "none" }
end

local function sellValue(slime: Configuration): number
	return Mutations.sellValue(appearanceOf(slime), UiSlimes.number(slime, "Level"))
end

-- Why the shop would refuse this slime, as far as the client can tell (the server has the last word).
local function blockedReason(slime: Configuration, count: number): string?
	if UiSlimes.isGhost(slime) then
		return "DEAD"
	elseif slime:GetAttribute("OutOnSquad") == true then
		return "OUT"
	elseif UiSlimes.job(slime) then
		return "AT_WORK"
	elseif UiSlimes.pair(slime) > 0 then
		return "IN_PAIR"
	elseif count <= Z.MinSlimes then
		return "LAST_SLIMES"
	end
	return nil
end

local function openShop(point: Vector3)
	local modal = openSheet("shop", nil)
	local head = UiKit.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, modal.header)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, head)
	UiKit.icon(head, "coins", U.Touch - 12, { LayoutOrder = 1 })
	local coins =
		UiKit.label(head, "", U.TextHeader, "Brown", { LayoutOrder = 2, Size = UDim2.fromOffset(200, U.Touch) })
	local scroller = list(modal.content)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, scroller)
	type Row = { slime: Configuration, button: TextButton, reason: TextLabel, confirmUntil: number }
	local rows: { [string]: Row } = {}
	local signature = ""

	local function build(slimes: { Configuration })
		table.clear(rows)
		for index, slime in slimes do
			local _, body = UiKit.card(scroller, { Size = UDim2.new(1, 0, 0, 64), LayoutOrder = index })
			local _, show = UiSlimes.portrait(body, slime, 48, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
			})
			show()
			UiKit.label(body, "Lv " .. tostring(UiSlimes.number(slime, "Level")), U.TextSmall, "Brown", {
				Position = UDim2.fromOffset(56, 6),
				Size = UDim2.fromOffset(80, 20),
			})
			local price = UiKit.make("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(56, 28),
				Size = UDim2.fromOffset(120, 26),
			}, body)
			UiKit.make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, price)
			UiKit.icon(price, "coins", U.IconNormal - 4, { LayoutOrder = 1 })
			UiKit.label(price, UiKit.money(sellValue(slime)), U.TextNormal, "Brown", {
				LayoutOrder = 2,
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
			})
			local reason = UiKit.label(body, "", U.TextSmall, "BrownSoft", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(112, 40),
				TextXAlignment = Enum.TextXAlignment.Right,
			})
			local row: Row = { slime = slime, button = nil :: any, reason = reason, confirmUntil = 0 }
			row.button = UiKit.button(body, {
				Name = "Sell",
				Text = "Sell",
				Style = "good",
				Size = UDim2.fromOffset(92, 40),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				OnClick = function()
					-- Dual, Secret and Material slimes ask first: a second press inside the window sells.
					local appearance = appearanceOf(slime)
					if Mutations.needsSellConfirm(appearance) and os.clock() > row.confirmUntil then
						row.confirmUntil = os.clock() + V.ConfirmSeconds
						return
					end
					row.confirmUntil = 0
					UiKit.setEnabled(row.button, false)
					local value = sellValue(slime)
					task.spawn(function()
						local ok, why = ask({ action = "Sell", slimeId = slime.Name })
						if ok then
							UiKit.toast("+" .. UiKit.money(value))
						else
							UiKit.toast(reasonText(why))
						end
					end)
				end,
			})
			rows[slime.Name] = row
		end
	end

	local function tick()
		local own = ownOf()
		local value = if own then own:GetAttribute("Coins") else nil
		coins.Text = UiKit.money(if type(value) == "number" then value else 0)
		local slimes = UiSlimes.slimes(own)
		local count = #slimes
		table.sort(slimes, function(a, b)
			local left, right = sellValue(a), sellValue(b)
			if left ~= right then
				return left > right
			end
			return a.Name < b.Name
		end)
		local names: { string } = {}
		for _, slime in slimes do
			table.insert(names, slime.Name)
		end
		local now = table.concat(names, "|")
		if now ~= signature then
			signature = now
			rebuild(scroller, function()
				build(slimes)
			end)
		end
		local clockNow = os.clock()
		for _, row in rows do
			local why = blockedReason(row.slime, count)
			local asking = clockNow <= row.confirmUntil
			row.button.Visible = why == nil
			row.reason.Text = if why then reasonText(why) else ""
			UiKit.setStyle(row.button, if asking then "danger" else "good")
			setLabel(row.button, if asking then "Sure?" else "Sell")
		end
	end
	sheet = { id = "shop", tick = tick, point = point, range = Z.ShopRangeStuds * 1.3 }
	tick()
end

-- ===== Start =====

local function anchorAt(position: Vector3, name: string): Part
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	return anchor
end

function UiSquad.start(own: () -> Folder?)
	ownOf = own
	ZombieWorld.setOpener(openGroup)

	-- the chip for the dead, at the left edge, middle of the screen
	local made = UiKit.chip(UiKit.root(), "skull", "0", 0)
	made.root.AnchorPoint = Vector2.new(0, 0.5)
	made.root.Position = UDim2.new(0, U.Edge, 0.5, 0)
	made.root.Visible = false
	UiKit.make("TextButton", {
		Name = "Open",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	}, made.root).Activated
		:Connect(function()
			openRevive()
		end)
	chip = made

	-- the Market: one prompt where the shop stands
	local market = Layout.marketFrame().Position
	local anchor = anchorAt(Vector3.new(market.X, Config.Map.GroundY + V.AnchorLift, market.Z), "MarketPrompt")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Shop"
	prompt.ActionText = "Sell"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Z.ShopRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function()
		openShop(anchor.Position)
	end)

	task.spawn(function()
		local warned = false
		while true do
			local ok, err = pcall(function(): any
				refreshChip()
				local open = sheet
				if open then
					local far = if open.point then flatDistance(open.point) else nil
					if far and far > open.range then
						UiKit.closeModal()
					else
						open.tick()
					end
				end
				return nil
			end)
			if not ok and not warned then
				warned = true
				warn(Config.LogPrefix, "squad screens error:", err)
			end
			task.wait(V.SheetRefreshSeconds)
		end
	end)
end

return UiSquad
