--!strict
-- The screens of the zombie teams (the owner, 2026-11-02): at the village gate a sheet sets up the four teams' line-ups from
-- the one slime list; at a zombie group a small sheet orders a team to attack it; a chip per team on the left edge shows
-- where it is; a notice at the right edge says who came back and what it earned. They read what the server publishes (the
-- Teams folder, slime attributes, Camps) and ask through UiSquad's context; the server decides, so a button it would refuse is
-- greyed or answered with a short friendly line.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local UiKit = require(script.Parent.UiKit)
local UiSlimeList = require(script.Parent.UiSlimeList)
local UiSlimes = require(script.Parent.UiSlimes)
local ZombieLook = require(script.Parent.ZombieLook)
local ZombieTeams = require(script.Parent.ZombieTeams)
local ZombieWorld = require(script.Parent.ZombieWorld)

local U = Config.Ui
local Z = Config.Zombies
local V = Z.View

export type Context = {
	own: () -> Folder?,
	ask: (data: { [string]: any }) -> (boolean, string?),
	reason: (reason: any) -> string,
	-- opens the one sheet; `tick` runs about twice a second while it is open and closes it when the player walks off
	open: (id: string, height: number, tick: () -> (), point: Vector3?, range: number) -> UiKit.Modal,
}
type Notice = { team: number, dead: number, coins: number }
type TeamChip = { root: Frame, icon: ImageLabel, track: Frame, fill: Frame, key: string }

local UiTeams = {}
local ctx: Context? = nil
local tab = 1
local chipsHost: Frame? = nil
local chips: { [number]: TeamChip } = {}
local noticeHost: Frame? = nil
local pending: { Notice } = {}
local shown = 0

local function context(): Context
	assert(ctx, "UiTeams.start first")
	return ctx
end

local function slimeById(id: string): Configuration?
	local own = context().own()
	local folder = if own then own:FindFirstChild("Slimes") else nil
	local found = if folder then folder:FindFirstChild(id) else nil
	return if found and found:IsA("Configuration") then found else nil
end

-- The slimes of a line-up that still exist.
local function membersOf(team: ZombieTeams.Team): { Configuration }
	local found: { Configuration } = {}
	for _, id in team.members do
		local slime = slimeById(id)
		if slime then
			table.insert(found, slime)
		end
	end
	return found
end

-- Team power: the average level of its members, rounded (0 for an empty team).
local function power(members: { Configuration }): number
	if #members == 0 then
		return 0
	end
	local sum = 0
	for _, slime in members do
		sum += UiSlimes.number(slime, "Level")
	end
	return math.floor(sum / #members + 0.5)
end

local function idsOf(members: { string }, without: string?, extra: string?): { string }
	local ids: { string } = {}
	for _, id in members do
		if id ~= without then
			table.insert(ids, id)
		end
	end
	if extra then
		table.insert(ids, extra)
	end
	return ids
end

local function stateIcon(team: ZombieTeams.Team): string
	if team.state == "home" and team.repeatOn and team.waiting ~= "" then
		return (V.WaitingIcons :: any)[team.waiting] or V.StateIcons.home
	end
	return (V.StateIcons :: any)[team.state] or V.StateIcons.home
end

local function setImage(icon: ImageLabel, name: string)
	local id = (U.Icons :: any)[name]
	icon.Image = if type(id) == "number" and id > 0 then "rbxassetid://" .. tostring(id) else ""
end

-- A small corner picture over a button (the team's state on its tab, as the sort arrow on the list's buttons).
local function cornerIcon(button: GuiObject, size: number): GuiObject
	return UiKit.icon(button, V.StateIcons.home, size, {
		Name = "State",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		ZIndex = 8,
		Visible = false,
	})
end

-- A small level plate over the foot of a portrait.
local function levelPlate(parent: Instance, level: number, width: number)
	local plate = UiKit.make("Frame", {
		Name = "Level",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -2),
		Size = UDim2.fromOffset(width, U.TextTiny + 2),
		BackgroundColor3 = UiKit.colour("Card"),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, parent)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, plate)
	UiKit.label(plate, tostring(level), U.TextTiny, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
	})
end

-- ===== The team sheet at the gate =====

local function openTeams(point: Vector3)
	local c = context()
	local busy = false
	local slotsKey = ""
	local tick: () -> () = function() end
	local modal = c.open("teams", V.TeamsSheetHeight, function()
		tick()
	end, point, Z.GateRangeStuds * 1.25)

	-- the four tabs, each with its state in the corner while it is out
	local tabButtons: { [number]: TextButton } = {}
	local tabStates: { [number]: GuiObject } = {}
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, modal.header)
	for index = 1, Z.Teams do
		local button = UiKit.button(modal.header, {
			Name = "Tab" .. index,
			Text = tostring(index),
			TextSize = U.TextHeader,
			Style = if index == tab then "primary" else "secondary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			LayoutOrder = index,
			OnClick = function()
				tab = index
				slotsKey = ""
				tick()
			end,
		})
		tabButtons[index] = button
		tabStates[index] = cornerIcon(button, 18)
	end

	-- the four slots and the Repeat toggle
	local top = UiKit.make("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, V.SlotSize),
	}, modal.content)
	local slotRow = UiKit.make("Frame", {
		Name = "Slots",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -U.Touch - U.Gap, 1, 0),
	}, top)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, slotRow)
	local lock = UiKit.make("Frame", {
		Name = "Lock",
		BackgroundColor3 = UiKit.colour("Parchment"),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -U.Touch - U.Gap, 1, 0),
		Active = true,
		Visible = false,
		ZIndex = 20,
	}, top)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0, 8) }, lock)
	local lockIcon = UiKit.icon(lock, V.StateIcons.home, U.Touch - 8, {
		Name = "State",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 21,
	})
	local repeatButton: TextButton
	repeatButton = UiKit.button(top, {
		Name = "Repeat",
		Icon = "again",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		OnClick = function()
			local team = ZombieTeams.get(tab)
			if not team or busy then
				return
			end
			busy = true
			local on = not team.repeatOn
			UiKit.setStyle(repeatButton, if on then "good" else "secondary")
			task.spawn(function()
				local ok, why = c.ask({ action = "SetTeamRepeat", team = team.index, on = on })
				if not ok then
					UiKit.toast(c.reason(why))
				end
				busy = false
				tick()
			end)
		end,
	})

	-- why a repeating team waits: its picture and a short word
	local info = UiKit.make("Frame", {
		Name = "Info",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, V.SlotSize + 4),
		Size = UDim2.new(1, 0, 0, U.IconSmall),
	}, modal.content)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, info)
	local infoIcon = UiKit.make("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(U.IconSmall, U.IconSmall),
		LayoutOrder = 1,
	}, info)
	local infoText = UiKit.label(info, "", U.TextSmall, "BrownSoft", {
		LayoutOrder = 2,
		Size = UDim2.new(1, -U.IconSmall - 4, 1, 0),
	})

	-- one change at a time: asks the server, then redraws from what it publishes
	local function change(work: () -> ())
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			local ok, err = pcall(function(): any
				work()
				return nil
			end)
			if not ok then
				warn(Config.LogPrefix, "team change error:", err)
			end
			busy = false
			tick()
		end)
	end
	local function setTeam(index: number, ids: { string }): boolean
		local ok, why = c.ask({ action = "SetTeam", team = index, slimeIds = ids })
		if not ok then
			UiKit.toast(c.reason(why))
		end
		return ok
	end

	local function drawSlots(team: ZombieTeams.Team)
		for _, child in slotRow:GetChildren() do
			if child:IsA("GuiButton") then
				UiSlimes.park(child)
			end
		end
		UiKit.clear(slotRow)
		local members = membersOf(team)
		for index = 1, Z.TeamSize do
			local slime = members[index]
			local button = UiKit.make("TextButton", {
				Name = "Slot" .. index,
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(V.SlotSize, V.SlotSize),
				LayoutOrder = index,
			}, slotRow)
			if slime then
				local box, show = UiSlimes.portrait(button, slime, V.SlotSize, nil, "slot")
				show()
				levelPlate(box, UiSlimes.number(slime, "Level"), V.SlotSize - 14)
				button.Activated:Connect(function()
					change(function()
						setTeam(team.index, idsOf(team.members, slime.Name))
					end)
				end)
			else
				local _, body = UiKit.skin(button, "Wood", "CardDeep", { Size = UDim2.fromScale(1, 1) })
				UiKit.icon(body, "plus", math.floor(V.SlotSize / 2), {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				})
			end
		end
	end

	local function entries(teams: { ZombieTeams.Team }): { UiSlimeList.Entry }
		local list: { UiSlimeList.Entry } = {}
		local mine = teams[tab]
		for _, slime in UiSlimes.slimes(c.own()) do
			if not UiSlimes.isBaby(slime) and not UiSlimes.isGhost(slime) then
				local entry: UiSlimeList.Entry = { slime = slime }
				local owner = ZombieTeams.teamOf(slime.Name, teams)
				local ownerTeam = if owner then teams[owner] else nil
				if UiSlimes.job(slime) then
					entry.blocked, entry.why, entry.mark = true, c.reason("AT_WORK"), { icon = UiSlimes.job(slime) }
				elseif UiSlimes.pair(slime) > 0 then
					entry.blocked, entry.why, entry.mark = true, c.reason("IN_PAIR"), { icon = "breeding" }
				elseif ownerTeam and ownerTeam.state ~= "home" then
					entry.blocked, entry.why, entry.mark =
						true, c.reason("OUT"), { text = tostring(owner), colour = "GoldLight" }
				elseif owner then
					entry.selected = mine ~= nil and owner == mine.index
					entry.mark = { text = tostring(owner), colour = if entry.selected then "Green" else "GoldLight" }
				else
					entry.mark = UiSlimeList.stateMark(slime)
				end
				table.insert(list, entry)
			end
		end
		return list
	end

	local teamsNow: { ZombieTeams.Team } = {}
	local list = UiSlimeList.new(modal.content, {
		entries = function()
			return entries(teamsNow)
		end,
		onTap = function(slime)
			local mine = teamsNow[tab]
			if not mine then
				return
			end
			if mine.state ~= "home" then
				UiKit.toast(c.reason("TEAM_OUT"))
				return
			end
			change(function()
				if table.find(mine.members, slime.Name) then
					setTeam(mine.index, idsOf(mine.members, slime.Name))
					return
				end
				if #membersOf(mine) >= Z.TeamSize then
					UiKit.toast(c.reason("BAD_SIZE"))
					return
				end
				-- a slime of another team moves here: it leaves that team first
				local owner = ZombieTeams.teamOf(slime.Name, teamsNow)
				local from = if owner then teamsNow[owner] else nil
				if from and from.index ~= mine.index then
					if not setTeam(from.index, idsOf(from.members, slime.Name)) then
						return
					end
				end
				setTeam(mine.index, idsOf(mine.members, nil, slime.Name))
			end)
		end,
	})
	local listTop = V.SlotSize + 4 + U.IconSmall + 4
	list.root.Position = UDim2.fromOffset(0, listTop)
	list.root.Size = UDim2.new(1, 0, 1, -listTop)

	tick = function()
		teamsNow = ZombieTeams.all()
		local mine = teamsNow[tab]
		if not mine then
			return
		end
		for index, button in tabButtons do
			UiKit.setStyle(button, if index == tab then "primary" else "secondary")
			local team = teamsNow[index]
			local state = tabStates[index]
			if team and state and state:IsA("ImageLabel") then
				state.Visible = team.state ~= "home"
				setImage(state, stateIcon(team))
			end
		end
		local key = table.concat({ tostring(tab), table.concat(mine.members, ",") }, "|")
		if key ~= slotsKey then
			slotsKey = key
			drawSlots(mine)
		end
		local out = mine.state ~= "home"
		lock.Visible = out
		if lockIcon:IsA("ImageLabel") then
			setImage(lockIcon, stateIcon(mine))
		end
		UiKit.setStyle(repeatButton, if mine.repeatOn then "good" else "secondary")
		local waiting = mine.repeatOn and not out and mine.waiting ~= ""
		info.Visible = waiting
		if waiting then
			setImage(infoIcon, stateIcon(mine))
			infoText.Text = (V.WaitingText :: any)[mine.waiting] or ""
		end
		list.refresh()
	end
	tick()
end

-- ===== The attack sheet at a zombie group =====

local function openAttack(groupId: string)
	local c = context()
	local group = ZombieWorld.group(groupId)
	if not group or group.state ~= "waiting" then
		UiKit.toast(c.reason("NOT_WAITING"))
		return
	end
	local tick: () -> () = function() end
	local modal = c.open("attack", V.AttackSheetHeight, function()
		tick()
	end, group.position, Z.SendRangeStuds * 1.25)

	-- the group: its kinds' pictures and level
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
		ZombieLook.icon(head, group.entries[config].kind, U.Touch - 12, { LayoutOrder = index })
	end
	UiKit.label(head, "Lv " .. tostring(group.level), U.TextNormal, "Brown", {
		LayoutOrder = 10,
		Size = UDim2.fromOffset(58, U.Touch),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local scroller = UiKit.make("ScrollingFrame", {
		Name = "Teams",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, modal.content)
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, scroller)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroller)

	type Card = {
		portraits: Frame,
		powerLabel: TextLabel,
		stateIcon: ImageLabel,
		repeatButton: TextButton,
		go: TextButton,
		key: string,
	}
	local cards: { [number]: Card } = {}
	local busy = false
	for index = 1, Z.Teams do
		local _, body = UiKit.card(scroller, { Size = UDim2.new(1, 0, 0, V.CardHeight), LayoutOrder = index })
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
			Size = UDim2.fromOffset(V.CardPortrait * Z.TeamSize + 2 * (Z.TeamSize - 1), V.CardPortrait),
		}, body)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, portraits)
		local powerX = 18 + V.CardPortrait * Z.TeamSize + 2 * (Z.TeamSize - 1) + 4
		local powerLabel = UiKit.label(body, "", U.TextSmall, "Brown", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, powerX, 0.5, 0),
			Size = UDim2.fromOffset(42, U.Touch),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local icon = UiKit.make("ImageLabel", {
			Name = "State",
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, powerX + 7, 0.5, 0),
			Size = UDim2.fromOffset(U.IconNormal, U.IconNormal),
			Visible = false,
		}, body)
		local go = UiKit.button(body, {
			Name = "Go",
			Icon = "attack",
			Style = "primary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Enabled = false,
			OnClick = function()
				if busy then
					return
				end
				busy = true
				UiKit.setEnabled(cards[index].go, false)
				task.spawn(function()
					local ok, why = c.ask({ action = "AttackGroup", team = index, groupId = groupId })
					busy = false
					if ok then
						if UiKit.modalId() == "attack" then
							UiKit.closeModal()
						end
					else
						UiKit.toast(c.reason(why))
					end
				end)
			end,
		})
		-- Repeat is decided here, where the player sends the team
		local again: TextButton
		again = UiKit.button(body, {
			Name = "Repeat",
			Icon = "again",
			Style = "secondary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -U.Touch - U.Gap, 0.5, 0),
			OnClick = function()
				local team = ZombieTeams.get(index)
				if not team then
					return
				end
				local on = not team.repeatOn
				UiKit.setStyle(again, if on then "good" else "secondary")
				task.spawn(function()
					local ok, why = c.ask({ action = "SetTeamRepeat", team = index, on = on })
					if not ok then
						UiKit.toast(c.reason(why))
					end
				end)
			end,
		})
		cards[index] = {
			portraits = portraits,
			powerLabel = powerLabel,
			stateIcon = icon,
			repeatButton = again,
			go = go,
			key = "",
		}
	end

	tick = function()
		local live = ZombieWorld.group(groupId)
		if not live or live.state ~= "waiting" then
			UiKit.toast(c.reason("NOT_WAITING"))
			UiKit.closeModal()
			return
		end
		for index, card in cards do
			local team = ZombieTeams.get(index)
			if team then
				local members = membersOf(team)
				if table.concat(team.members, ",") ~= card.key then
					card.key = table.concat(team.members, ",")
					for _, child in card.portraits:GetChildren() do
						if child:IsA("GuiObject") then
							UiSlimes.park(child)
						end
					end
					UiKit.clear(card.portraits)
					for k, slime in members do
						local _, show =
							UiSlimes.portrait(card.portraits, slime, V.CardPortrait, { LayoutOrder = k }, "card")
						show()
					end
				end
				local out = team.state ~= "home"
				local empty = #members == 0
				card.stateIcon.Visible = out
				if out then
					setImage(card.stateIcon, stateIcon(team))
				end
				card.powerLabel.Visible = not out
				card.powerLabel.Text = if empty then "Empty" else "Lv " .. tostring(power(members))
				card.powerLabel.TextSize = if empty then U.TextTiny else U.TextSmall
				UiKit.setStyle(card.repeatButton, if team.repeatOn then "good" else "secondary")
				UiKit.setEnabled(card.go, not out and not empty and not busy)
			end
		end
	end
	tick()
end

-- ===== The team chips (left edge) =====

local function chipFor(index: number): TeamChip
	local item = chips[index]
	if item then
		return item
	end
	local host = chipsHost
	assert(host, "UiTeams.start first")
	local box, body = UiKit.skin(host, "Wood", "Card", {
		Name = "Team" .. index,
		Size = UDim2.fromOffset(U.ChipHeight + 30, U.ChipHeight),
		LayoutOrder = index,
	})
	UiKit.label(body, tostring(index), U.TextNormal, "Brown", {
		Size = UDim2.new(0, 18, 1, -V.ChipBarHeight - 2),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local icon = UiKit.make("ImageLabel", {
		Name = "State",
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.fromOffset(U.IconNormal - 4, U.IconNormal - 4),
	}, body)
	local track = UiKit.make("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, V.ChipBarHeight),
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
		Visible = false,
	}, body)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
	local fill = UiKit.make("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = UiKit.colour("Green"),
		BorderSizePixel = 0,
	}, track)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	local made: TeamChip = { root = box, icon = icon, track = track, fill = fill, key = "" }
	chips[index] = made
	return made
end

-- Called about twice a second: a chip for each team that has members or is out, its state and its march progress.
function UiTeams.refresh()
	if not chipsHost then
		return
	end
	local now = workspace:GetServerTimeNow()
	for _, team in ZombieTeams.all() do
		local show = #team.members > 0 or team.state ~= "home"
		local item = chips[team.index]
		if show or item then
			item = chipFor(team.index)
			item.root.Visible = show
			if show then
				local icon = stateIcon(team)
				if icon ~= item.key then
					item.key = icon
					setImage(item.icon, icon)
				end
				local marching = team.state ~= "home"
				item.track.Visible = marching
				if marching then
					UiKit.tween(
						item.fill,
						V.SheetRefreshSeconds,
						{ Size = UDim2.fromScale(ZombieTeams.progress(team, now), 1) },
						Enum.EasingStyle.Linear
					)
					item.fill.BackgroundColor3 =
						UiKit.colour(if team.state == "returning" then "GoldLight" else "Green")
				end
			end
		end
	end
end

-- ===== The notice (right edge) =====

local showNext: () -> ()

local function showNotice(notice: Notice)
	local host = noticeHost
	if not host then
		return
	end
	shown += 1
	local group = UiKit.make("CanvasGroup", {
		Name = "Notice",
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Size = UDim2.fromOffset(V.NoticeWidth, V.NoticeHeight),
	}, host)
	local _, body = UiKit.skin(group, "Wood", "Card", { Size = UDim2.fromScale(1, 1) })
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)
	UiKit.label(body, "Team " .. tostring(notice.team) .. " is back", U.TextSmall, "Brown", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, U.TextSmall + 2),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local row = UiKit.make("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, U.IconSmall),
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local function part(order: number, icon: string, text: string)
		UiKit.icon(row, icon, U.IconSmall, { LayoutOrder = order * 2 - 1 })
		UiKit.label(row, text, U.TextSmall, "Brown", {
			LayoutOrder = order * 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
		})
	end
	part(1, "skull", tostring(notice.dead))
	part(2, "coins", UiKit.money(notice.coins))
	UiKit.tween(group, 0.2, { GroupTransparency = 0 })
	task.delay(V.NoticeSeconds, function()
		local out = UiKit.tween(group, 0.3, { GroupTransparency = 1 })
		out.Completed:Once(function()
			group:Destroy()
			shown -= 1
			showNext()
		end)
	end)
end

showNext = function()
	while shown < V.NoticeMax and #pending > 0 do
		showNotice(table.remove(pending, 1) :: Notice)
	end
end

-- A team is home: who it was, how many died, what it earned. Several may queue.
function UiTeams.notice(team: number, dead: number, coins: number)
	if not noticeHost then
		return
	end
	table.insert(pending, { team = team, dead = dead, coins = coins })
	showNext()
end

-- ===== Start =====

function UiTeams.start(context_: Context)
	ctx = context_

	-- the gate: one prompt (F, "Teams")
	local gate = Layout.plotGate(Config.Village.DevPlot).Position
	local anchor = Instance.new("Part")
	anchor.Name = "TeamsPrompt"
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = CFrame.new(gate.X, Config.Map.GroundY + V.AnchorLift, gate.Z)
	anchor.Parent = workspace
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Teams"
	prompt.ActionText = "Teams"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Z.GateRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function()
		openTeams(anchor.Position)
	end)

	-- the group prompt (F, "Attack") opens the attack sheet
	ZombieWorld.setOpener(openAttack)

	-- the chips: a column on the left edge, above the chip of the dead
	local column = UiKit.make("Frame", {
		Name = "TeamChips",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, U.Edge, 0.5, -V.ChipLift),
		Size = UDim2.fromOffset(U.ChipHeight + 30, (U.ChipHeight + U.Gap) * Z.Teams),
	}, UiKit.root())
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, column)
	chipsHost = column

	-- the notices: stacked upward from just above the book button on the right edge
	local stack = UiKit.make("Frame", {
		Name = "Notices",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -U.Edge, 0.5, -(U.Touch + 16) / 2 - U.Gap),
		Size = UDim2.fromOffset(V.NoticeWidth, (V.NoticeHeight + U.Gap) * V.NoticeMax),
	}, UiKit.root())
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, stack)
	noticeHost = stack
end

return UiTeams
