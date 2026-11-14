--!strict
-- The map of the big world (docs/WORLD.md §7 "M5b"). A small square at the top-left corner shows the picture of the world
-- round the player (north up) with the packs, the zones and the player's own village; pressing it, or the prompt of a
-- waystone, opens the sheet: the whole picture with the Market, the villages' own door, every zone (a waystone beside it,
-- locked until its guard is beaten) and a Travel button for the place pressed. Everything is read from what the server
-- publishes (workspace.ZombieCamps, the player's Zone_<id> attributes, the village folder); travel is asked through
-- Remotes.Travel and the server decides.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MapView = require(ReplicatedStorage.Shared.MapView)
local WorldPacks = require(ReplicatedStorage.Shared.WorldPacks)
local WorldPlan = require(ReplicatedStorage.Shared.WorldPlan)
local UiKit = require(script.Parent.UiKit)

local C = Config.Ui.Map
local U = Config.Ui
local W = Config.World
local FULL = UDim2.fromScale(1, 1)
local CENTRE = Vector2.new(0.5, 0.5)
local WHITE = Color3.new(1, 1, 1)
local player = Players.LocalPlayer

type Mark = {
	id: string, -- a zone's id, "home" or "market"
	name: string,
	icon: string,
	x: number,
	z: number,
	root: GuiObject,
	ring: GuiObject?,
	stone: GuiObject?,
	lock: GuiObject?,
}
type Layer = { host: GuiObject, player: GuiObject, marks: { Mark }, packs: { GuiObject }, size: any }
-- plan point -> where it falls in the layer's host, 0..1 across
type Place = (number, number) -> (number, number)

local reasons: { [string]: string } = {
	ZONE_LOCKED = "Beat its guard to open",
	COOLDOWN = "One moment.",
	IN_DUNGEON = "Not in the Dungeon.",
	NOT_READY = "Village is loading.",
	DEAD = "Fallen.",
}

local UiMap = {}
local holder: Frame? = nil
local box: Frame? = nil
local label: TextLabel? = nil
local mapImage: ImageLabel? = nil
local mini: Layer? = nil
local shownSize = 0
-- bumped when the sheet opens or closes: its refresh loop ends when its own number is no longer the current one
local sheetToken = 0

-- ===== What the server published =====

local function village(): Folder?
	local world = workspace:FindFirstChild("Villages")
	local found = if world then world:FindFirstChild(tostring(player.UserId)) else nil
	return if found and found:IsA("Folder") then found else nil
end

-- The player's own plot number (the village of WorldPlan.Villages it stands in), once the server has given one.
local function plotOf(): number?
	local folder = village()
	local plot = if folder then folder:GetAttribute("Plot") else nil
	return if type(plot) == "number" and WorldPlan.Villages[plot] then plot else nil
end

local function rootPart(): BasePart?
	local character = player.Character
	local part = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if part and part:IsA("BasePart") then part else nil
end

local function won(zone: string): boolean
	local at = player:GetAttribute(W.Attribute .. zone)
	return type(at) == "number" and at > 0
end

local function bandColour(band: number): Color3
	local list = W.Packs.BandColours
	return Color3.fromHex(list[math.clamp(band, 1, #list)])
end

-- ===== Markers =====

-- A picture of the map tinted by code (the arrow, the monster dot). While its id is 0 (not drawn yet) a plain stand-in shows.
local function tinted(parent: Instance, key: string, size: number, colour: Color3, props: UiKit.Props): GuiObject
	local image = UiKit.icon(parent, key, size, props)
	if image:IsA("ImageLabel") then
		image.ImageColor3 = colour
	elseif image:IsA("TextLabel") then
		image.TextColor3 = colour
		if key == "map_pack" then
			image.Text = ""
			image.BackgroundTransparency = 0
			image.BackgroundColor3 = colour
			UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, image)
		else
			image.Text = "^"
		end
	end
	return image
end

local function paint(dot: GuiObject, colour: Color3)
	if dot:IsA("ImageLabel") then
		dot.ImageColor3 = colour
	else
		dot.BackgroundColor3 = colour
	end
end

-- The markers of one map: the player's arrow, every zone, the player's own village, and (when `onPick` is given, the sheet)
-- the Market; pack dots are added as they are needed. A marker is a picture; on the sheet it is also a press area.
local function newLayer(host: GuiObject, S: any, onPick: ((Mark) -> ())?): Layer
	local marks: { Mark } = {}
	local function add(id: string, name: string, icon: string, size: number, x: number, z: number, zone: boolean)
		local root = UiKit.make("Frame", {
			Name = id,
			BackgroundTransparency = 1,
			AnchorPoint = CENTRE,
			Size = UDim2.fromOffset(size, size),
			Visible = false,
			ZIndex = 2,
		}, host)
		UiKit.icon(root, icon, size, { Size = FULL, ZIndex = 2 })
		local item: Mark = { id = id, name = name, icon = icon, x = x, z = z, root = root }
		if onPick then
			local ring = UiKit.make("Frame", {
				Name = "Ring",
				BackgroundTransparency = 1,
				AnchorPoint = CENTRE,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 8, 1, 8),
				Visible = false,
				ZIndex = 3,
			}, root)
			UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
			UiKit.make("UIStroke", { Color = UiKit.colour("Brown"), Thickness = 2 }, ring)
			item.ring = ring
			if zone then
				local corner = { Position = UDim2.fromScale(0.6, 0.6), ZIndex = 4 }
				item.stone = UiKit.icon(root, "waystone", S.Stone, corner)
				item.lock = UiKit.icon(root, "waystone_locked", S.Stone, corner)
			end
			UiKit.make("TextButton", {
				Name = "Hit",
				Text = "",
				BackgroundTransparency = 1,
				AnchorPoint = CENTRE,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(S.Hit, S.Hit),
				ZIndex = 5,
			}, root).Activated
				:Connect(function()
					onPick(item)
				end)
		end
		table.insert(marks, item)
	end
	for _, zone in WorldPlan.Zones do
		add(zone.id, zone.name, (C.ZoneIcons :: any)[zone.kind], S.Zone, zone.x, zone.z, true)
	end
	add("home", "Home", "home", S.Home, 0, 0, false)
	if onPick then
		add("market", "Market", "market", S.Zone, WorldPlan.Hub.x, WorldPlan.Hub.z, false)
	end
	local arrow = tinted(host, "map_player", S.Player, WHITE, { Name = "Player", AnchorPoint = CENTRE, ZIndex = 6 })
	arrow.Visible = false
	return { host = host, player = arrow, marks = marks, packs = {}, size = S }
end

local function inside(fx: number, fy: number): boolean
	return fx >= 0 and fx <= 1 and fy >= 0 and fy <= 1
end

-- Puts every marker where `place` says; the dots of the packs that wait, are taken or fight (not the gone) in their band's colour.
local function update(layer: Layer, place: Place)
	local part = rootPart()
	if part then
		local fx, fy = place(MapView.plan(part.Position.X, part.Position.Z))
		layer.player.Visible = inside(fx, fy)
		layer.player.Position = UDim2.fromScale(fx, fy)
		local look = part.CFrame.LookVector
		layer.player.Rotation = math.deg(math.atan2(look.X, -look.Z))
	end
	local plot = plotOf()
	for _, item in layer.marks do
		local shown = true
		if item.id == "home" then
			local at = if plot then WorldPlan.Villages[plot] else nil
			shown = at ~= nil
			if at then
				item.x, item.z = at.x, at.z
			end
		end
		local fx, fy = place(item.x, item.z)
		item.root.Visible = shown and inside(fx, fy)
		item.root.Position = UDim2.fromScale(fx, fy)
		if item.stone and item.lock then
			local open = won(item.id)
			item.stone.Visible = open
			item.lock.Visible = not open
		end
	end
	local used = 0
	local camps = workspace:FindFirstChild("ZombieCamps")
	for _, folder in if camps then camps:GetChildren() else {} do
		for _, pack in folder:GetChildren() do
			local at = pack:GetAttribute("Position")
			local band = pack:GetAttribute("Band")
			if typeof(at) == "Vector3" and type(band) == "number" and pack:GetAttribute("State") ~= "gone" then
				local fx, fy = place(MapView.plan(at.X, at.Z))
				if inside(fx, fy) then
					used += 1
					local dot = layer.packs[used]
					if not dot then
						dot = tinted(layer.host, "map_pack", layer.size.Pack, WHITE, {
							Name = "Pack",
							AnchorPoint = CENTRE,
							ZIndex = 1,
						})
						layer.packs[used] = dot
					end
					dot.Position = UDim2.fromScale(fx, fy)
					paint(dot, bandColour(band))
					dot.Visible = true
				end
			end
		end
	end
	for index = used + 1, #layer.packs do
		layer.packs[index].Visible = false
	end
end

-- ===== The sheet =====

local function reasonText(reason: any): string
	return if type(reason) == "string" and reasons[reason] then reasons[reason] else "Please try again."
end

local function uvPlace(x: number, z: number): (number, number)
	return MapView.uv(x, z)
end

local function openSheet()
	local S = C.Sheet
	local rootSize = UiKit.units(UiKit.root())
	local wide = rootSize.X >= rootSize.Y * S.WideRatio
	local modal = UiKit.openModal("map", {
		Width = S.Width,
		Height = S.Height,
		OnClose = function()
			sheetToken += 1
		end,
	})
	local mine = sheetToken
	local content = modal.content
	UiKit.icon(modal.header, "map", U.Touch - 12, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	})

	-- the legend: a column beside the map on a wide screen, rows under it on a narrow one
	local bands = WorldPacks.bands()
	local perRow = math.max(1, math.floor((math.min(S.Width, rootSize.X - 2 * U.Edge) - S.InnerPad) / S.Legend))
	local legendHeight = math.ceil(bands / perRow) * S.LegendRow
	local area = UiKit.make("Frame", {
		Name = "Area",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -S.Footer - U.Gap),
	}, content)
	local map = UiKit.make("ImageLabel", {
		Name = "Map",
		Image = "rbxassetid://" .. tostring(W.Map.Image),
		BackgroundColor3 = UiKit.colour("CardDeep"),
		AnchorPoint = if wide then Vector2.new(0, 0.5) else Vector2.new(0.5, 0),
		Position = if wide then UDim2.fromScale(0, 0.5) else UDim2.fromScale(0.5, 0),
		Size = if wide then UDim2.new(1, -S.Legend - U.Gap, 1, 0) else UDim2.new(1, 0, 1, -legendHeight - U.Gap),
	}, area)
	-- (the largest square the room allows)
	UiKit.make("UIAspectRatioConstraint", {
		AspectRatio = 1,
		AspectType = Enum.AspectType.FitWithinMaxSize,
		DominantAxis = Enum.DominantAxis.Width,
	}, map)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0, 8) }, map)
	local legend = UiKit.make("Frame", {
		Name = "Legend",
		BackgroundTransparency = 1,
		AnchorPoint = if wide then Vector2.new(1, 0.5) else Vector2.new(0.5, 1),
		Position = if wide then UDim2.fromScale(1, 0.5) else UDim2.fromScale(0.5, 1),
		Size = if wide then UDim2.fromOffset(S.Legend, bands * S.LegendRow) else UDim2.new(1, 0, 0, legendHeight),
	}, area)
	UiKit.make("UIListLayout", {
		FillDirection = if wide then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Wraps = not wide,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, legend)
	for band = 1, bands do
		local entry = UiKit.make("Frame", {
			Name = "Band" .. band,
			BackgroundTransparency = 1,
			LayoutOrder = band,
			Size = UDim2.fromOffset(S.Legend, S.LegendRow),
		}, legend)
		local chip = UiKit.make("Frame", {
			Name = "Chip",
			BackgroundColor3 = bandColour(band),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(S.LegendChip, S.LegendChip),
		}, entry)
		UiKit.make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, chip)
		UiKit.label(entry, WorldPacks.bandName(band), U.TextTiny, "Brown", {
			Position = UDim2.fromOffset(S.LegendChip + U.Gap, 0),
			Size = UDim2.new(1, -S.LegendChip - U.Gap, 1, 0),
		})
	end

	-- the footer: the place pressed, and Travel
	local footer = UiKit.make("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, S.Footer),
	}, content)
	local picture = UiKit.make("Frame", {
		Name = "Picture",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(S.Icon, S.Icon),
	}, footer)
	local travelWidth = U.Touch * 2
	local words = UiKit.make("Frame", {
		Name = "Words",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(S.Icon + U.Gap, 0),
		Size = UDim2.new(1, -S.Icon - travelWidth - 2 * U.Gap, 1, 0),
	}, footer)
	UiKit.make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, words)
	local nameLabel = UiKit.label(words, "", U.TextNormal, "Brown", { LayoutOrder = 1 })
	local note = UiKit.label(words, "", U.TextTiny, "BrownSoft", { LayoutOrder = 2 })
	local picked: Mark? = nil
	local travelling = false
	local layer: Layer
	local go: TextButton
	local function refreshFooter()
		local item = picked
		local open = item ~= nil and (item.id == "home" or item.id == "market" or won(item.id))
		nameLabel.Text = if item then item.name else ""
		note.Text = if item and not open then reasons.ZONE_LOCKED else ""
		UiKit.setEnabled(go, open and not travelling)
	end
	go = UiKit.button(footer, {
		Name = "Travel",
		Text = "Travel",
		Style = "primary",
		Size = UDim2.fromOffset(travelWidth, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Enabled = false,
		OnClick = function()
			local item = picked
			if not item or travelling then
				return
			end
			travelling = true
			refreshFooter()
			task.spawn(function()
				local remotes = ReplicatedStorage:FindFirstChild("Remotes")
				local remote = if remotes then remotes:FindFirstChild("Travel") else nil
				local ok, answer = false, nil :: any
				if remote and remote:IsA("RemoteFunction") then
					ok, answer = pcall(function()
						return remote:InvokeServer(
							if item.id == "home"
								then { action = "Home" }
								elseif item.id == "market" then { action = "Market" }
								else { action = "Zone", zone = item.id }
						)
					end)
				end
				travelling = false
				if ok and type(answer) == "table" and answer.ok then
					if UiKit.modalId() == "map" then
						UiKit.closeModal()
					end
				else
					UiKit.toast(reasonText(if ok and type(answer) == "table" then answer.reason else nil))
					if sheetToken == mine then
						refreshFooter()
					end
				end
			end)
		end,
	})

	layer = newLayer(map, S, function(item: Mark)
		picked = item
		for _, other in layer.marks do
			if other.ring then
				other.ring.Visible = other == item
			end
		end
		UiKit.clear(picture)
		UiKit.icon(picture, item.icon, S.Icon)
		refreshFooter()
	end)
	task.spawn(function()
		while sheetToken == mine do
			update(layer, uvPlace)
			refreshFooter()
			task.wait(C.RefreshSeconds)
		end
	end)
end

-- ===== The minimap =====

local function refreshMini()
	local frame, view, tag, image, layer = holder, box, label, mapImage, mini
	if not (frame and view and tag and image and layer) then
		return
	end
	-- on the village's screen only (the arena and a village still loading have none), and only over the picture
	local phase = player:GetAttribute("DungeonPhase")
	local part = rootPart()
	local shown = plotOf() ~= nil and (phase == nil or phase == "") and part ~= nil
	local x, z = 0, 0
	if shown and part then
		x, z = MapView.plan(part.Position.X, part.Position.Z)
		local u, v = MapView.uv(x, z)
		shown = inside(u, v)
	end
	frame.Visible = shown
	if not shown then
		return
	end
	local side = if UiKit.units(UiKit.root()).Y >= C.TallHeight then C.MiniTall else C.MiniSize
	if side ~= shownSize then
		shownSize = side
		frame.Size = UDim2.fromOffset(side, side + 2 + C.LabelHeight)
		view.Size = UDim2.fromOffset(side, side)
		tag.Position = UDim2.fromOffset(0, side + 2)
		tag.Size = UDim2.fromOffset(side, C.LabelHeight)
	end
	local cropX, cropY, size = MapView.crop(x, z, C.MiniStuds, C.Picture)
	image.ImageRectOffset = Vector2.new(cropX, cropY)
	image.ImageRectSize = Vector2.new(size, size)
	update(layer, function(px: number, pz: number)
		return MapView.inCrop(px, pz, cropX, cropY, size, C.Picture)
	end)
	local band = WorldPacks.band(WorldPacks.levelAt(x, z))
	tag.Text = WorldPacks.bandName(band)
	tag.TextColor3 = bandColour(band)
end

local function buildMini()
	local frame = UiKit.make("Frame", {
		Name = "Minimap",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(U.Edge, U.Edge),
		Visible = false,
	}, UiKit.root())
	local panel, body = UiKit.card(frame, { Name = "Frame" })
	local image = UiKit.make("ImageLabel", {
		Name = "Map",
		Image = "rbxassetid://" .. tostring(W.Map.Image),
		BackgroundColor3 = UiKit.colour("CardDeep"),
		ClipsDescendants = true,
		Size = FULL,
	}, body)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0, 6) }, image)
	UiKit.make("TextButton", {
		Name = "Open",
		Text = "",
		BackgroundTransparency = 1,
		Size = FULL,
		ZIndex = 20,
	}, panel).Activated
		:Connect(openSheet)
	-- the band the player stands in, over the world's own colours: white with a dark outline, then tinted
	local tag =
		UiKit.label(frame, "", U.TextTiny, "Brown", { Name = "Band", TextXAlignment = Enum.TextXAlignment.Center })
	UiKit.outline(tag, true)
	holder, box, label, mapImage = frame, panel, tag, image
	mini = newLayer(image, C.Mini, nil)
end

function UiMap.start()
	buildMini()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
		if who == player and prompt.Name == "WaystonePrompt" then
			openSheet()
		end
	end)
	task.spawn(function()
		while true do
			refreshMini()
			task.wait(C.RefreshSeconds)
		end
	end)
end

return UiMap
