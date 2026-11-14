--!strict
-- The screens of the zombie teams (the owner, 2026-11-02): at the team banner just inside the village gate a sheet sets up
-- the line-ups of the teams the village has opened (Config.Zombies.TeamOpensAt) from
-- the one slime list; at a zombie group a small sheet orders a team to attack it; a chip per team on the left edge shows
-- where it is; a notice at the right edge says who came back and what it earned. They read what the server publishes (the
-- Teams folder, slime attributes, workspace.ZombieCamps) and ask through UiSquad's context; the server decides, so a button it
-- would refuse is greyed or answered with a short friendly line. The gate is the one of the viewer's own plot.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Zombies = require(ReplicatedStorage.Shared.Zombies)
local WorldPacks = require(ReplicatedStorage.Shared.WorldPacks)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)
local UiSlimeList = require(script.Parent.UiSlimeList)
local UiSlimes = require(script.Parent.UiSlimes)
local ZombieTeams = require(script.Parent.ZombieTeams)
local ZombieWorld = require(script.Parent.ZombieWorld)

local U = Config.Ui
local W = U.Team
local Z = Config.Zombies
local V = Z.View
local Rows = Config.Classes.Rows
local Tactics = Config.Classes.Tactics

export type Context = {
	own: () -> Folder?,
	ask: (data: { [string]: any }) -> (boolean, string?),
	reason: (reason: any) -> string,
	-- opens the one sheet; `tick` runs about twice a second while it is open and closes it when the player walks off
	open: (id: string, height: number, tick: () -> (), point: Vector3?, range: number) -> UiKit.Modal,
}
type Notice = { team: number, dead: number, coins: number }
type TeamChip = { root: GuiObject, icon: ImageLabel, track: Frame, fill: Frame, key: string }

local UiTeams = {}
local ctx: Context? = nil
local tab = 1
local chipsHost: Frame? = nil
local chips: { [number]: TeamChip } = {}
local noticeHost: Frame? = nil
local pending: { Notice } = {}
local shown = 0
-- the prompt at the viewer's gate, made once the server has handed them a plot (and moved if the plot ever changes)
local gateAnchor: Part? = nil
local gatePlot = 0

local function context(): Context
	assert(ctx, "UiTeams.start first")
	return ctx
end

-- How many teams the village has opened (Config.Zombies.TeamOpensAt), by the level it publishes, and the Extra Team passes
-- (the Player attribute ExtraTeams): only those show.
local function teamsOpen(): number
	local own = context().own()
	local level = if own then own:GetAttribute("VillageLevel") else nil
	return Zombies.teamsOpen(if type(level) == "number" then level else 1, ZombieTeams.extra())
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

-- The words for a refusal on these sheets: the ones of the owner's own wording here, else the sheet's usual.
local function reason(why: any): string
	return (W.Reasons :: any)[why] or context().reason(why)
end

-- A team's job in words: Home, Marching, Fighting, Exploring Lv 1-20, Coming home.
local function jobText(team: ZombieTeams.Team): string
	if team.explore > 0 then
		return W.Exploring .. " " .. WorldPacks.bandName(team.explore)
	end
	return (W.Jobs :: any)[team.state] or W.Jobs.home
end

-- Starts a team exploring a band, or (band 0) calls it back; the server decides, the sheet redraws from what it publishes.
local function setExplore(index: number, band: number)
	task.spawn(function()
		local ok, why = context().ask({ action = "SetTeamExplore", team = index, band = band })
		if not ok then
			UiKit.toast(reason(why))
		end
	end)
end

local function stateIcon(team: ZombieTeams.Team): string
	if team.explore > 0 then
		return W.ExploreIcon
	end
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

-- At the team banner only (`point`: it closes when the player walks off): the line-up of each team, and where it explores.
-- A team's chip opens the small members sheet instead (openMembers).
local function openTeams(point: Vector3)
	local c = context()
	local busy = false
	local slotsKey = ""
	local planKey = ""
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
	-- six tabs: they narrow (never under U.TabMin) when the header is short, so all of them fit on a phone
	local function fitTabs()
		local room = UiKit.units(modal.header).X
		if room <= 0 then
			return
		end
		local width = math.clamp(math.floor((room - (Z.Teams - 1) * U.Gap) / Z.Teams), U.TabMin, U.Touch)
		for _, button in tabButtons do
			button.Size = UDim2.fromOffset(width, U.Touch)
		end
	end
	modal.header:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitTabs)
	fitTabs()

	-- the four slots, Best and Explore
	local bestWidth = U.Touch + 24
	local exploreWidth = 2 * U.Touch
	local buttonsWidth = bestWidth + exploreWidth + 2 * U.Gap
	local top = UiKit.make("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, V.SlotSize),
	}, modal.content)
	local slotRow = UiKit.make("Frame", {
		Name = "Slots",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -buttonsWidth, 1, 0),
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
		Size = UDim2.new(1, -buttonsWidth, 1, 0),
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
	-- Explore opens the bands to choose from; while the team explores it is Call back
	local choices: { { id: string, text: string } } = {}
	for band = 1, WorldPacks.bands() do
		table.insert(choices, { id = tostring(band), text = WorldPacks.bandName(band) })
	end
	local exploreButton: TextButton
	exploreButton = UiKit.button(top, {
		Name = "Explore",
		Text = W.Explore,
		Style = "secondary",
		Size = UDim2.fromOffset(exploreWidth, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		OnClick = function()
			local team = ZombieTeams.get(tab)
			if not team then
				return
			end
			if team.explore > 0 then
				setExplore(team.index, 0)
				return
			end
			UiKit.dropdown(exploreButton, choices, nil, function(id)
				setExplore(team.index, tonumber(id) or 0)
			end)
		end,
	})

	-- the fight plan under the slots: each member's row under its slot, the team's tactic under Best and Repeat
	local planTop = V.SlotSize + 4
	local plan = UiKit.make("Frame", {
		Name = "Plan",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, planTop),
		Size = UDim2.new(1, 0, 0, V.PlanHeight),
	}, modal.content)
	local rowPills = UiKit.make("Frame", {
		Name = "Rows",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -buttonsWidth, 1, 0),
	}, plan)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, rowPills)
	local tacticHost = UiKit.make("Frame", {
		Name = "Tactic",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, buttonsWidth - U.Gap, 1, 0),
	}, plan)
	local planBottom = planTop + V.PlanHeight

	-- why a repeating team waits: its picture and a short word
	local info = UiKit.make("Frame", {
		Name = "Info",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, planBottom + 4),
		Size = UDim2.new(1, 0, 0, U.IconSmall),
		Visible = false,
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
			UiKit.toast(reason(why))
		end
		return ok
	end

	-- The plan's buttons: a tap asks for the next row or tactic of the list, round to the first; the server's answer
	-- comes back in the team's attributes and redraws them.
	local function nextOf(order: { string }, value: string): string
		return order[(table.find(order, value) or 0) % #order + 1]
	end
	local function drawPlan(team: ZombieTeams.Team)
		UiKit.clear(rowPills)
		UiKit.clear(tacticHost)
		local function ask(data: { [string]: any })
			if team.state ~= "home" then
				UiKit.toast(c.reason("TEAM_OUT"))
				return
			end
			change(function()
				local ok, why = c.ask(data)
				if not ok then
					UiKit.toast(reason(why))
				end
			end)
		end
		-- (a pill stands under its member's slot: the slots hold the members that still exist, in the line-up's order)
		local at = 0
		for index, id in team.members do
			if slimeById(id) then
				at += 1
				local row = team.rows[index] or Rows.Brawler
				UiKit.button(rowPills, {
					Name = "Row" .. at,
					Text = (V.RowText :: any)[row] or row,
					TextSize = U.TextTiny,
					Style = (V.RowStyle :: any)[row] or "secondary",
					Size = UDim2.fromOffset(V.SlotSize, V.PlanHeight),
					LayoutOrder = at,
					OnClick = function()
						ask({ action = "SetTeamRow", team = team.index, slimeId = id, row = nextOf(Rows.Order, row) })
					end,
				})
			end
		end
		UiKit.button(tacticHost, {
			Name = "Tactic",
			Icon = (V.TacticIcons :: any)[team.tactic],
			IconSize = U.IconSmall,
			Text = (V.TacticText :: any)[team.tactic] or team.tactic,
			TextSize = U.TextTiny,
			Style = "secondary",
			Size = UDim2.fromScale(1, 1),
			OnClick = function()
				ask({ action = "SetTeamTactic", team = team.index, tactic = nextOf(Tactics.Order, team.tactic) })
			end,
		})
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
					entry.busy = not entry.selected
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
	-- the list sits under the slots, and under the waiting line only while that shows
	local function placeList()
		local listTop = planBottom + U.Gap + (if info.Visible then U.IconSmall + 4 else 0)
		list.root.Position = UDim2.fromOffset(0, listTop)
		list.root.Size = UDim2.new(1, 0, 1, -listTop)
	end
	info:GetPropertyChangedSignal("Visible"):Connect(placeList)
	placeList()

	-- Best (the owner, 2026-11-04): fills the team with the strongest slimes that may join it (not at work, not in a pair,
	-- not a baby or a ghost, not in another team), those ready to march first (awake, rested, unhurt), then by level and
	-- health. The server checks the line-up as for any other change.
	local function ready(slime: Configuration): boolean
		return slime:GetAttribute("Sleeping") ~= true
			and UiSlimes.number(slime, "Energy") > Config.Needs.Tired
			and UiSlimes.hpShare(slime) >= 1
	end
	local function stronger(a: Configuration, b: Configuration): boolean
		local readyA, readyB = ready(a), ready(b)
		if readyA ~= readyB then
			return readyA
		end
		local levelA, levelB = UiSlimes.number(a, "Level"), UiSlimes.number(b, "Level")
		if levelA ~= levelB then
			return levelA > levelB
		end
		local hpA, hpB = UiSlimes.number(a, "Hp"), UiSlimes.number(b, "Hp")
		if hpA ~= hpB then
			return hpA > hpB
		end
		return a.Name < b.Name
	end
	UiKit.button(top, {
		Name = "Best",
		Text = "Best",
		Style = "primary",
		Size = UDim2.fromOffset(bestWidth, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -exploreWidth - U.Gap, 0.5, 0),
		OnClick = function()
			local mine = teamsNow[tab]
			if not mine then
				return
			end
			if mine.state ~= "home" then
				UiKit.toast(c.reason("TEAM_OUT"))
				return
			end
			local pool: { Configuration } = {}
			for _, entry in entries(teamsNow) do
				local owner = ZombieTeams.teamOf(entry.slime.Name, teamsNow)
				if not entry.blocked and (owner == nil or owner == mine.index) then
					table.insert(pool, entry.slime)
				end
			end
			table.sort(pool, stronger)
			local ids: { string } = {}
			for index = 1, math.min(Z.TeamSize, #pool) do
				table.insert(ids, pool[index].Name)
			end
			if #ids == 0 then
				UiKit.toast(c.reason("NO_MEMBERS"))
				return
			end
			change(function()
				setTeam(mine.index, ids)
			end)
		end,
	})

	tick = function()
		teamsNow = ZombieTeams.all()
		local open = teamsOpen()
		if tab > open then
			tab = 1
		end
		local mine = teamsNow[tab]
		if not mine then
			return
		end
		for index, button in tabButtons do
			button.Visible = index <= open
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
		local planNow = table.concat({ key, table.concat(mine.rows, ","), mine.tactic }, "|")
		if planNow ~= planKey then
			planKey = planNow
			drawPlan(mine)
		end
		local out = mine.state ~= "home"
		lock.Visible = out
		if lockIcon:IsA("ImageLabel") then
			setImage(lockIcon, stateIcon(mine))
		end
		-- out: the slime list goes (the line-up changes at home only), the line says where the team is and why
		local exploring = mine.explore > 0
		local waiting = mine.repeatOn and not out and mine.waiting ~= ""
		info.Visible = out or waiting
		if out then
			setImage(infoIcon, stateIcon(mine))
			infoText.Text = if exploring then jobText(mine) else W.OutLine
		elseif waiting then
			setImage(infoIcon, stateIcon(mine))
			infoText.Text = (V.WaitingText :: any)[mine.waiting] or ""
		end
		list.root.Visible = not out
		UiKit.setEnabled(exploreButton, exploring or (not out and #mine.members > 0))
		local label = exploreButton:FindFirstChild("Label", true)
		if label and label:IsA("TextLabel") then
			label.Text = if exploring then W.CallBack else W.Explore
		end
		UiKit.setStyle(exploreButton, if exploring then "good" else "secondary")
		if not out then
			list.refresh()
		end
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

	-- the pack: its level and its monsters by name ("Lv 37   2 Leaf Sprout, Honey Bee")
	local counts: { [string]: number } = {}
	local names: { string } = {}
	for _, entry in group.entries do
		if entry.name ~= "" then
			if not counts[entry.name] then
				table.insert(names, entry.name)
			end
			counts[entry.name] = (counts[entry.name] or 0) + 1
		end
	end
	table.sort(names)
	for index, name in names do
		names[index] = if counts[name] > 1 then counts[name] .. " " .. name else name
	end
	UiKit.label(
		modal.header,
		"Lv " .. tostring(group.level) .. "   " .. table.concat(names, ", "),
		U.TextNormal,
		"Brown",
		{ Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true }
	)

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
		root: GuiObject,
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
		local root, body = UiKit.card(scroller, { Size = UDim2.new(1, 0, 0, V.CardHeight), LayoutOrder = index })
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
			Icon = "attack_order",
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
			root = root,
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
		local open = teamsOpen()
		for index, card in cards do
			local team = ZombieTeams.get(index)
			card.root.Visible = index <= open
			if team and index <= open then
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
							UiSlimes.portrait(card.portraits, slime, V.CardPortrait, { LayoutOrder = k }, "card", true)
						show()
					end
				end
				local out = team.state ~= "home"
				local empty = #members == 0
				-- an exploring team reads "Exploring Lv 1-20" where the power goes, and cannot be sent
				local exploring = team.explore > 0
				card.stateIcon.Visible = out and not exploring
				if out and not exploring then
					setImage(card.stateIcon, stateIcon(team))
				end
				card.powerLabel.Visible = not out or exploring
				card.powerLabel.Size = UDim2.fromOffset(if exploring then W.CardExploreWidth else 42, U.Touch)
				card.powerLabel.Text = if exploring
					then jobText(team)
					elseif empty then "Empty"
					else "Lv " .. tostring(power(members))
				card.powerLabel.TextSize = if empty or exploring then U.TextTiny else U.TextSmall
				UiKit.setStyle(card.repeatButton, if team.repeatOn then "good" else "secondary")
				UiKit.setEnabled(card.go, not out and not empty and not busy)
			end
		end
	end
	tick()
end

-- ===== The members sheet of a team's chip =====

type Member = {
	slime: Configuration,
	name: TextLabel,
	values: { [string]: TextLabel },
	bar: UiKit.Bar,
	mark: Frame,
	markKey: string,
	gear: Frame,
	gearKey: string,
}

-- Only this team's own members, with no list of other slimes and no way to change the line-up (the owner, 2026-11-14):
-- each with its portrait, name, level, fight stats, gear, health and state, and a dish button that opens the food sheet with
-- that slime chosen (UiFood). Over them the team's job and, while it explores, Call back. It stays open wherever the player is.
local function openMembers(index: number)
	local c = context()
	local tick: () -> () = function() end
	local modal = c.open("members", W.MembersSheetHeight, function()
		tick()
	end, nil, 0)

	local callWidth = 2 * U.Touch
	local jobIcon = UiKit.make("ImageLabel", {
		Name = "Job",
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(U.IconNormal, U.IconNormal),
	}, modal.header)
	local jobLabel = UiKit.label(modal.header, "", U.TextNormal, "Brown", {
		Position = UDim2.fromOffset(U.IconNormal + U.Gap, 0),
		Size = UDim2.new(1, -U.IconNormal - callWidth - 2 * U.Gap, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local callBack = UiKit.button(modal.header, {
		Name = "CallBack",
		Text = W.CallBack,
		Style = "good",
		Size = UDim2.fromOffset(callWidth, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		OnClick = function()
			setExplore(index, 0)
		end,
	})

	local scroller = UiKit.make("ScrollingFrame", {
		Name = "Members",
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

	local function line(parent: Instance, top: number, height: number): Frame
		local row = UiKit.make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, top),
			Size = UDim2.new(1, 0, 0, height),
		}, parent)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)
		return row
	end

	local members: { Member } = {}
	local function build(slimes: { Configuration })
		for _, child in scroller:GetChildren() do
			if child:IsA("GuiObject") then
				UiSlimes.park(child)
			end
		end
		UiKit.clear(scroller)
		table.clear(members)
		local T = U.Tile
		local left = W.MemberPortrait + U.Gap
		for order, slime in slimes do
			local _, body = UiKit.card(scroller, { Size = UDim2.new(1, 0, 0, W.MemberHeight), LayoutOrder = order })
			local _, show = UiSlimes.portrait(body, slime, W.MemberPortrait, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
			}, "member", true)
			show()
			UiKit.button(body, {
				Name = "Dish",
				Icon = "food",
				Style = "good",
				Size = UDim2.fromOffset(U.Touch, U.Touch),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				OnClick = function()
					UiFood.open(c.own(), slime.Name)
				end,
			})
			local info = UiKit.make("Frame", {
				Name = "Info",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(left, 0),
				Size = UDim2.new(1, -left - U.Touch - U.Gap, 1, 0),
			}, body)
			local name = UiKit.label(info, "", U.TextSmall, "Brown", {
				Size = UDim2.new(1, 0, 0, 20),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local stats = line(info, 22, T.StatRow)
			local values: { [string]: TextLabel } = {}
			for at, key in UiSlimeList.stats do
				UiKit.icon(stats, key, T.StatIcon, { LayoutOrder = at * 2 - 1 })
				values[key] = UiKit.label(stats, "", U.TextTiny, "Brown", {
					LayoutOrder = at * 2,
					Size = UDim2.fromScale(0, 1),
					AutomaticSize = Enum.AutomaticSize.X,
				})
			end
			local state = line(info, 42, T.GearIcon + 2)
			local bar = UiKit.bar(state, "hp", "Green", { Size = UDim2.fromOffset(90, T.GearIcon), LayoutOrder = 1 })
			local mark = UiKit.make("Frame", {
				Name = "Mark",
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Size = UDim2.fromOffset(T.GearIcon, T.GearIcon),
			}, state)
			local gear = UiKit.make("Frame", {
				Name = "Gear",
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				Size = UDim2.fromOffset(0, T.GearIcon),
				AutomaticSize = Enum.AutomaticSize.X,
			}, state)
			UiKit.make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, gear)
			table.insert(members, {
				slime = slime,
				name = name,
				values = values,
				bar = bar,
				mark = mark,
				markKey = "",
				gear = gear,
				gearKey = "",
			})
		end
	end

	local function update(member: Member)
		local slime = member.slime
		member.name.Text = UiSlimes.name(slime) .. "  Lv " .. tostring(UiSlimes.number(slime, "Level"))
		for stat, label in member.values do
			label.Text = UiSlimeList.short(UiSlimes.number(slime, (U.SortAttributes :: any)[stat]))
		end
		local share = UiSlimes.hpShare(slime)
		member.bar.set(share, share < U.Tile.WoundLow)
		local mark = UiSlimeList.stateMark(slime)
		local markKey = if mark and mark.icon then mark.icon else ""
		if markKey ~= member.markKey then
			member.markKey = markKey
			UiKit.clear(member.mark)
			if markKey ~= "" then
				UiKit.icon(member.mark, markKey, U.Tile.GearIcon)
			end
		end
		local gearKey = tostring(slime:GetAttribute("Gear"))
		if gearKey ~= member.gearKey then
			member.gearKey = gearKey
			UiSlimeList.drawGear(member.gear, slime, U.Tile.GearIcon)
		end
	end

	local key = ""
	tick = function()
		local team = ZombieTeams.get(index)
		if not team then
			return
		end
		setImage(jobIcon, stateIcon(team))
		jobLabel.Text = "Team " .. tostring(index) .. "  " .. jobText(team)
		callBack.Visible = team.explore > 0
		local slimes = membersOf(team)
		local ids: { string } = {}
		for _, slime in slimes do
			table.insert(ids, slime.Name)
		end
		if table.concat(ids, ",") ~= key then
			key = table.concat(ids, ",")
			build(slimes)
		end
		for _, member in members do
			update(member)
		end
	end
	tick()
end

-- ===== The team chips (left edge) =====

-- A team's chip: a square button with its number in the corner, its state's picture in the middle and, while it is out,
-- its march under it. A tap opens its team's members sheet wherever the player is (the owner, 2026-11-12, 2026-11-14).
local function chipFor(index: number): TeamChip
	local item = chips[index]
	if item then
		return item
	end
	local host = chipsHost
	assert(host, "UiTeams.start first")
	local box = UiKit.button(host, {
		Name = "Team" .. index,
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		LayoutOrder = index,
		OnClick = function()
			openMembers(index)
		end,
	})
	local body = box:FindFirstChild("Visual") :: Instance
	UiKit.label(body, tostring(index), U.TextSmall, "Brown", {
		Position = UDim2.fromOffset(5, 2),
		Size = UDim2.fromOffset(14, U.TextSmall),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	})
	local icon = UiKit.make("ImageLabel", {
		Name = "State",
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 3, 0.5, 1),
		Size = UDim2.fromOffset(U.IconNormal, U.IconNormal),
		ZIndex = 3,
	}, body)
	local track = UiKit.make("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -5),
		Size = UDim2.new(1, -12, 0, V.ChipBarHeight),
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 4,
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

-- The "Teams" prompt at the gate of the viewer's own plot: made when the server has handed them one (ZombieTeams.plot).
-- Only they have it; other players' gates have no prompt for them.
function UiTeams.placeGate()
	local plot = ZombieTeams.plot()
	if not plot or plot == gatePlot then
		return
	end
	gatePlot = plot
	-- on the team banner just inside the gate (ZombieFights.placeBanner stands it there)
	local at = Layout.plotMuster(plot) + Vector3.new(0, V.AnchorLift, 0)
	local old = gateAnchor
	if old then
		old.CFrame = at
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "TeamsPrompt"
	anchor.Size = Vector3.one
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = at
	anchor.Parent = workspace
	gateAnchor = anchor
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
end

-- Called about twice a second: a chip for each team that has members or is out, its state and its march progress.
function UiTeams.refresh()
	UiTeams.placeGate()
	if not chipsHost then
		return
	end
	local now = workspace:GetServerTimeNow()
	local open = teamsOpen()
	for _, team in ZombieTeams.all() do
		local show = (#team.members > 0 and team.index <= open) or team.state ~= "home"
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

	-- the gate: one prompt (F, "Teams"), put at the viewer's own gate as soon as their plot is known
	UiTeams.placeGate()

	-- the group prompt (F, "Attack") opens the attack sheet
	ZombieWorld.setOpener(openAttack)

	-- the chips: square buttons two to a row on the left edge, above the chip of the dead (six would not fit in one column
	-- above the middle of a phone)
	local rows = math.ceil(Z.Teams / U.TeamChipColumns)
	local column = UiKit.make("Frame", {
		Name = "TeamChips",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, U.Edge, 0.5, -V.ChipLift),
		Size = UDim2.fromOffset(
			U.Touch * U.TeamChipColumns + U.Gap * (U.TeamChipColumns - 1),
			(U.Touch + U.Gap) * rows
		),
	}, UiKit.root())
	UiKit.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(U.Touch, U.Touch),
		CellPadding = UDim2.fromOffset(U.Gap, U.Gap),
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = U.TeamChipColumns,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
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
