--!strict
-- The screens of the zombie fights that are not the teams (UiTeams): the chip and sheet for the dead (revive before they are
-- lost for good) and the Market's sell sheet, both on the one slime list (UiSlimeList). They read what the server publishes
-- (slime attributes, Storehouse, Coins) and ask through Remotes.Village; the server decides, so a button it would refuse is
-- greyed or answered with a short friendly line. This file also owns the one open sheet and the loop that keeps it fresh.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local ZombieRules = require(ReplicatedStorage.Shared.Zombies)
local UiDishShop = require(script.Parent.UiDishShop)
local UiDungeon = require(script.Parent.UiDungeon)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)
local UiMarket = require(script.Parent.UiMarket)
local UiSlimeList = require(script.Parent.UiSlimeList)
local UiSmithy = require(script.Parent.UiSmithy)
local UiSlimes = require(script.Parent.UiSlimes)
local UiTeams = require(script.Parent.UiTeams)

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
	NOT_WAITING = "Already fighting.",
	OUT = "Out fighting.",
	TEAM_OUT = "That team is out.",
	EXPLORING = "A fighter is out exploring",
	IN_TEAM = "In another team.",
	NO_MEMBERS = "Nobody can go.",
	BAD_TEAM = "No such team.",
	LOCKED = "Upgrade the village first.",
	NO_GROUP = "Group is gone.",
	NO_CAMPS = "No camps yet.",
	BUSY = "One moment.",
	NO_FOOD = "Not enough food.",
	NOT_DEAD = "Already back.",
	FAVOURITE = "A favourite.",
	DEAD = "Fallen.",
	BABY = "Too young.",
	DUPLICATE = "Already there.",
	AT_WORK = "At work.",
	IN_PAIR = "In a pair.",
	LAST_SLIMES = "Keep the last two.",
	BAD_SIZE = "A team holds four.",
	BAD_ROW = "Not available.",
	BAD_TACTIC = "Not available.",
	NO_SLIME = "Slime not found.",
	RATE_LIMIT = "One moment.",
	NOT_READY = "Village is loading.",
	NO_DISH = "None left.",
	UNKNOWN_DISH = "Not available.",
	INVALID_COUNT = "Not available.",
	INVALID_ARGUMENT = "Not available.",
	-- the Slime Dungeon
	IN_RUN = "Already in the Dungeon.",
	NO_PLOT = "Village is loading.",
	LEVEL_LOCKED = "Clear the level below first.",
	FEW_SLIMES = "Needs " .. Config.Dungeon.EnterMinSlimes .. " slimes.",
	VILLAGE_LEVEL = "Needs village level " .. Config.Dungeon.EnterMinVillageLevel .. ".",
	NO_FIT = "Nobody can go.",
	NO_RUN = "Not in the Dungeon.",
	-- the zones of the big world
	ZONE_LOCKED = "Defeat the three bosses first.",
	ZONE_RESTING = "The guard is not back yet.",
	ZONE_UNKNOWN = "Not available.",
	BAD_PHASE = "Not yet.",
}

local function reasonText(reason: any): string
	return if type(reason) == "string" and reasons[reason] then reasons[reason] else "Please try again."
end

-- One request to the server; yields, so callers run it in task.spawn.
local function ask(data: { [string]: any }): (boolean, string?, number?)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = if remotes then remotes:FindFirstChild("Village") else nil
	if not remote or not remote:IsA("RemoteFunction") then
		return false, "NOT_READY"
	end
	local ok, answer = pcall(function()
		return remote:InvokeServer(data)
	end)
	if ok and type(answer) == "table" then
		return answer.ok == true, answer.reason, answer.value
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

local function clock(seconds: number): string
	local whole = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function setLabel(button: GuiButton, text: string)
	local label = button:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- Opens the one sheet. `tick` runs twice a second while it is open; it closes when the player walks farther than `range`
-- from `point` (nil: it stays).
local function openSheet(id: string, height: number, tick: () -> (), point: Vector3?, range: number): UiKit.Modal
	local modal = UiKit.openModal(id, {
		Width = U.SheetWidth,
		Height = height,
		Bottom = true,
		Dim = 0.8,
		OnClose = function()
			UiSlimes.releaseAll()
			sheet = nil
		end,
	})
	sheet = { id = id, tick = tick, point = point, range = range }
	return modal
end

-- The bottom bar of a sheet with a list: the list takes the rest, and all of the sheet while the bar is hidden. Returns
-- the bar.
local function bottomBar(modal: UiKit.Modal, list: UiSlimeList.List): Frame
	local bar = UiKit.make("Frame", {
		Name = "Bar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, U.Touch),
		Visible = false,
	}, modal.content)
	local function fit()
		list.root.Size = if bar.Visible then UDim2.new(1, 0, 1, -U.Touch - U.Gap) else UDim2.fromScale(1, 1)
	end
	bar:GetPropertyChangedSignal("Visible"):Connect(fit)
	fit()
	return bar
end

-- A picture and a number on a bar: the price of a revive or a sale.
local function priceTag(bar: Frame, icon: string): TextLabel
	local price = UiKit.make("Frame", {
		Name = "Price",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -120, 1, 0),
	}, bar)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, price)
	UiKit.icon(price, icon, U.IconNormal, { LayoutOrder = 1 })
	local value = UiKit.label(price, "", U.TextHeader, "Brown", {
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	return value
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

local function timeColour(left: number): string
	return if left < V.ReviveWarnSeconds then "Red" else "Brown"
end

local function openRevive()
	local selected: string? = nil
	local tick: () -> () = function() end
	local modal = openSheet("revive", U.SheetHeight, function()
		tick()
	end, nil, 0)
	UiKit.icon(modal.header, "skull", U.Touch - 12, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	})
	local dead: { Dead } = {}
	local list = UiSlimeList.new(modal.content, {
		entries = function()
			local entries: { UiSlimeList.Entry } = {}
			for _, item in dead do
				table.insert(entries, {
					slime = item.slime,
					selected = item.slime.Name == selected,
					caption = clock(item.left),
					captionColour = timeColour(item.left),
					mark = { icon = "skull" },
				})
			end
			return entries
		end,
		onTap = function(slime)
			selected = slime.Name
			tick()
		end,
	})
	local bar = bottomBar(modal, list)
	local cost = priceTag(bar, "food")
	local button: TextButton
	button = UiKit.button(bar, {
		Name = "Revive",
		Text = "Revive",
		Style = "good",
		Size = UDim2.fromOffset(110, U.Touch),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		OnClick = function()
			local id = selected
			if not id then
				return
			end
			UiKit.setEnabled(button, false)
			task.spawn(function()
				local ok, why = ask({ action = "Revive", slimeId = id })
				if not ok then
					UiKit.toast(reasonText(why))
				end
			end)
		end,
	})

	tick = function()
		dead = deadSlimes()
		if #dead == 0 then
			UiKit.closeModal()
			return
		end
		-- (the one with the least time left is chosen at first)
		local chosen = dead[1]
		local found = false
		for _, item in dead do
			if item.slime.Name == selected then
				chosen, found = item, true
			end
		end
		if not found then
			selected = chosen.slime.Name
		end
		local price = ZombieRules.reviveCost(UiSlimes.number(chosen.slime, "Level"))
		bar.Visible = true
		cost.Text = tostring(price)
		UiKit.setEnabled(button, foodCount() >= price)
		list.refresh()
	end
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
	-- (not inside the Dungeon: the village's chips are put away for the run)
	local run = player:GetAttribute("DungeonPhase")
	item.root.Visible = #dead > 0 and not (type(run) == "string" and run ~= "")
	if #dead > 0 then
		item.set(tostring(#dead) .. "  " .. clock(dead[1].left))
		local value = item.root:FindFirstChild("Value", true)
		if value and value:IsA("TextLabel") then
			value.TextColor3 = UiKit.colour(timeColour(dead[1].left))
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
	-- The slimes ticked for sale (their ids): tap one to tick or untick it, one Sell button sells them all.
	local selected: { [string]: boolean } = {}
	local confirmUntil = 0
	local tick: () -> () = function() end
	local modal = openSheet("shop", U.SheetHeight, function()
		tick()
	end, point, Z.ShopRangeStuds * 1.3)
	local head = UiKit.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, modal.header)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, head)
	-- two tabs at the left, as in the book: the slimes and the dishes (pictures only); then the player's coins
	UiKit.icon(head, "coins", U.Touch - 12, { LayoutOrder = 3 })
	local coins = UiKit.label(head, "", U.TextNormal, "Brown", {
		LayoutOrder = 4,
		Size = UDim2.fromOffset(0, U.Touch),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	local tab = "slimes"
	local setTab: (name: string) -> () = function(_) end
	local tabButtons: { [string]: TextButton } = {}
	for index, item in { { id = "slimes", icon = "slimes" }, { id = "dishes", icon = "food" } } do
		tabButtons[item.id] = UiKit.button(head, {
			Name = item.id,
			Icon = item.icon,
			Style = if item.id == tab then "primary" else "secondary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			LayoutOrder = index,
			OnClick = function()
				setTab(item.id)
			end,
		})
	end

	local slimes: { Configuration } = {}
	-- The ticked slimes that are still there and could still be sold, in list order.
	local function ticked(): { Configuration }
		local out: { Configuration } = {}
		for _, slime in slimes do
			if selected[slime.Name] and blockedReason(slime, #slimes) == nil then
				table.insert(out, slime)
			end
		end
		return out
	end
	local list = UiSlimeList.new(modal.content, {
		entries = function()
			local entries: { UiSlimeList.Entry } = {}
			for _, slime in slimes do
				local why = blockedReason(slime, #slimes)
				table.insert(entries, {
					slime = slime,
					blocked = why ~= nil,
					why = if why then reasonText(why) else nil,
					selected = selected[slime.Name] == true,
					mark = UiSlimeList.stateMark(slime),
				})
			end
			return entries
		end,
		onTap = function(slime)
			if selected[slime.Name] then
				selected[slime.Name] = nil
			else
				local count = 0
				for _ in selected do
					count += 1
				end
				if count >= Z.SellManyMax then
					UiKit.toast("Up to " .. Z.SellManyMax .. " at a time.")
					return
				elseif #slimes - count - 1 < Z.MinSlimes then
					UiKit.toast(reasonText("LAST_SLIMES"))
					return
				end
				selected[slime.Name] = true
			end
			confirmUntil = 0
			tick()
		end,
	})
	local bar = bottomBar(modal, list)
	local value = priceTag(bar, "coins")
	local sell: TextButton
	sell = UiKit.button(bar, {
		Name = "Sell",
		Text = "Sell",
		Style = "good",
		Size = UDim2.fromOffset(110, U.Touch),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		OnClick = function()
			local chosen = ticked()
			if #chosen == 0 then
				return
			end
			-- Dual, Secret and Material slimes ask first: a second press inside the window sells.
			local rare = false
			local amount = 0
			local ids: { string } = {}
			for _, slime in chosen do
				rare = rare or Mutations.needsSellConfirm(appearanceOf(slime))
				amount += sellValue(slime)
				table.insert(ids, slime.Name)
			end
			if rare and os.clock() > confirmUntil then
				confirmUntil = os.clock() + V.ConfirmSeconds
				return
			end
			confirmUntil = 0
			UiKit.setEnabled(sell, false)
			task.spawn(function()
				-- (one slime goes as a plain sale, several as one request that sells all of them or none)
				local ok: boolean, why: string?, paid: number?
				if #ids == 1 then
					ok, why, paid = ask({ action = "Sell", slimeId = ids[1] })
				else
					ok, why, paid = ask({ action = "SellMany", slimeIds = ids })
				end
				if ok then
					selected = {}
					UiKit.toast("+" .. UiKit.money(paid or amount), "coins")
				else
					UiKit.toast(reasonText(why))
				end
			end)
		end,
	})

	-- The dishes tab sits over the slime list; the server checks the Market's range for both kinds of sale.
	local dishes = UiDishShop.new(modal.content, { own = ownOf, ask = ask, reason = reasonText })
	setTab = function(name)
		tab = name
		for id, button in tabButtons do
			UiKit.setStyle(button, if id == name then "primary" else "secondary")
		end
		list.root.Visible = name == "slimes"
		dishes.root.Visible = name == "dishes"
		bar.Visible = false
		tick()
	end

	tick = function()
		local own = ownOf()
		local money = if own then own:GetAttribute("Coins") else nil
		coins.Text = UiKit.money(if type(money) == "number" then money else 0)
		if tab == "dishes" then
			dishes.tick()
			return
		end
		slimes = UiSlimes.slimes(own)
		-- (a ticked slime that was sold, went to work or died drops out; so do ticks that would take the last ones)
		local chosen = ticked()
		local keep: { [string]: boolean } = {}
		local total, count = 0, 0
		for index, slime in chosen do
			if #slimes - index < Z.MinSlimes then
				break
			end
			keep[slime.Name] = true
			total += sellValue(slime)
			count += 1
		end
		selected = keep
		if count > 0 then
			bar.Visible = true
			-- the total, before the press that sells it
			value.Text = UiKit.money(total)
			local asking = os.clock() <= confirmUntil
			UiKit.setStyle(sell, if asking then "danger" else "good")
			setLabel(sell, if asking then "Sure?" elseif count > 1 then "Sell " .. count else "Sell")
			UiKit.setEnabled(sell, true)
		else
			bar.Visible = false
		end
		list.refresh()
	end
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

	-- the teams: the gate sheet, the attack sheet, the chips and the notice
	UiTeams.start({ own = own, ask = ask, reason = reasonText, open = openSheet })

	-- the Slime Dungeon: the portal's sheet, the arena's plate, the banner and the end card
	UiDungeon.start({ own = own, ask = ask, reason = reasonText, open = openSheet })

	-- the Market: the VIP counter's prompt and sheet (UiMarket), and one prompt where the slime buyer stands
	UiMarket.start({ open = openSheet, anchor = anchorAt })
	-- the Blacksmith's prompt and the Smithy sheet (UiSmithy); it also lends its request to the slime card's gear slots
	UiSmithy.start({ open = openSheet, anchor = anchorAt, own = own, ask = ask })
	local buyer = Layout.marketPoint(Config.Market.Buyer)
	local anchor = anchorAt(Vector3.new(buyer.X, Config.Map.GroundY + V.AnchorLift, buyer.Z), "BuyerPrompt")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Shop"
	prompt.ActionText = "Sell slimes"
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
		local warned: { [string]: boolean } = {}
		local function guarded(label: string, work: () -> ())
			local ok, err = pcall(function(): any
				work()
				return nil
			end)
			if not ok and not warned[label] then
				warned[label] = true
				warn(Config.LogPrefix, "squad screens error (" .. label .. "):", err)
			end
		end
		while true do
			guarded("chip", refreshChip)
			guarded("teams", UiTeams.refresh)
			guarded("sheet", function()
				local open = sheet
				if open then
					local far = if open.point then flatDistance(open.point) else nil
					if far and far > open.range then
						UiKit.closeModal()
					else
						open.tick()
					end
				end
			end)
			task.wait(V.SheetRefreshSeconds)
		end
	end)
end

return UiSquad
