--!strict
-- Draws the tutorial and the intros the server publishes on the player's village folder (server/Guide, rules in
-- shared/Guide): one short line on a card at the top edge (Next on a tip, Skip, or a close button on an intro), and the
-- owner's gold arrow at what the line is about. A thing in the world gets the arrow bobbing over it and a trail of arrows
-- on the ground from the character's feet; a button on the screen gets the arrow beside it and a slow pulse. The middle
-- of the screen stays empty. It decides nothing: a step finishes on the server, from the real farm.
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local UiBook = require(script.Parent.UiBook)
local UiFood = require(script.Parent.UiFood)
local UiKit = require(script.Parent.UiKit)

local G = Config.Guide
local U = Config.Ui
local player = Players.LocalPlayer
local ARROW = "rbxassetid://" .. tostring(U.Icons.pointer)
-- The arrow picture points left; these turn it (degrees, clockwise) to point right, up and down.
local POINT_RIGHT, POINT_UP, POINT_DOWN = 180, 90, -90

local UiGuide = {}

type Context = { own: () -> Folder? }

local ownOf: () -> Folder? = function()
	return nil
end
local card: Frame? = nil
local cardScale: UIScale? = nil
local lineLabel: TextLabel? = nil
local nextButton: TextButton? = nil
local skipButton: TextButton? = nil
local closeButton: TextButton? = nil
local anchor: Part? = nil
local billboard: BillboardGui? = nil
local trail: { BillboardGui } = {}
local hudLayers: { [ScreenGui]: Frame } = {}
local hudArrow: ImageLabel? = nil
local pulsed: { target: GuiObject, scale: UIScale, made: boolean }? = nil
local shown = ""
local shownKind = ""
local reported = ""
local skipped = false
local warned = false

local function attribute(name: string): any
	local own = ownOf()
	return if own then own:GetAttribute(name) else nil
end

local function text(name: string): string
	local value = attribute(name)
	return if type(value) == "string" then value else ""
end

-- Requests the guide sends are quiet: a refusal only means the step already moved on.
local function send(data: { [string]: any })
	task.spawn(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = if remotes then remotes:FindFirstChild("Village") else nil
		if remote and remote:IsA("RemoteFunction") then
			pcall(function()
				remote:InvokeServer(data)
			end)
		end
	end)
end

-- ===== where the arrow points =====

local function plotModel(): Instance?
	local plot = attribute("Plot")
	local map = workspace:FindFirstChild("Map")
	return if map and type(plot) == "number" then map:FindFirstChild("Plot" .. tostring(plot)) else nil
end

local function areaModel(area: string): Instance?
	local plot = plotModel()
	if not plot then
		return nil
	end
	local prefix = "^" .. string.lower(area) .. "l"
	for _, child in plot:GetChildren() do
		if string.match(string.lower(child.Name), prefix) then
			return child
		end
	end
	return nil
end

local areaModels: { [string]: string } = {
	fishing = "FishingPond",
	garden = "Garden",
	kitchen = "Kitchen",
	training = "Training",
	breeding = "Breeding",
}

local function positionOf(inst: Instance?): Vector3?
	if not inst then
		return nil
	elseif inst:IsA("Attachment") then
		return inst.WorldPosition
	elseif inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

-- The first work position of the area with nobody in it (else the first).
local function spotPosition(area: string): Vector3?
	local model = areaModel(areaModels[area] or area)
	if not model then
		return nil
	end
	local slots: { any } = {}
	local ok, work = pcall(function()
		return HttpService:JSONDecode(text("Work"))
	end)
	if ok and type(work) == "table" and type(work[area]) == "table" then
		slots = work[area]
	end
	local first: Vector3? = nil
	for index = 1, #Config.Village.SpotNames.Work do
		local at = positionOf(model:FindFirstChild("WorkSpot" .. index, true))
		if at then
			first = first or at
			local slot = slots[index]
			if type(slot) == "table" and slot.worker == "" then
				return at
			end
		end
	end
	return first
end

local function breedingPosition(): Vector3?
	local model = areaModel(areaModels.breeding)
	local prompt = if model then model:FindFirstChild("VillageManage", true) else nil
	return positionOf(if prompt then prompt.Parent else model)
end

local function characterPosition(): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- The nearest group of zombies that waits in the player's own slice of the valley.
local function groupPosition(): Vector3?
	local camps = workspace:FindFirstChild("ZombieCamps")
	local slice = if camps then camps:FindFirstChild(tostring(attribute("Plot"))) else nil
	if not slice then
		return nil
	end
	local from = characterPosition() or Vector3.zero
	local best: Vector3? = nil
	local bestDistance = math.huge
	for _, group in slice:GetChildren() do
		local at = group:GetAttribute("Position")
		if group:GetAttribute("State") == "waiting" and typeof(at) == "Vector3" then
			local distance = (at - from).Magnitude
			if distance < bestDistance then
				best, bestDistance = at, distance
			end
		end
	end
	return best
end

-- An upgrade pad of the player's plot: of that area, or the cheapest (then the nearest).
local function padPosition(area: string?): Vector3?
	local plot = attribute("Plot")
	local from = characterPosition() or Vector3.zero
	local best: Vector3? = nil
	local bestCost, bestDistance = math.huge, math.huge
	for _, pad in CollectionService:GetTagged("UpgradePad") do
		if
			pad:IsA("BasePart")
			and pad:GetAttribute("Plot") == plot
			and (area == nil or pad:GetAttribute("AreaId") == area)
		then
			local cost = pad:GetAttribute("Cost")
			local price = if type(cost) == "number" then cost else 0
			local distance = (pad.Position - from).Magnitude
			if price < bestCost or (price == bestCost and distance < bestDistance) then
				best, bestCost, bestDistance = pad.Position, price, distance
			end
		end
	end
	return best
end

local function worldTarget(target: string): Vector3?
	local kind, rest = string.match(target, "^(%a+):?(.*)$")
	local plot = attribute("Plot")
	if kind == "spot" then
		return spotPosition(rest :: string)
	elseif kind == "breeding" then
		return breedingPosition()
	elseif kind == "banner" and type(plot) == "number" then
		return Layout.plotMuster(plot).Position
	elseif kind == "market" then
		return Layout.marketPoint(Config.Market.Buyer)
	elseif kind == "group" then
		return groupPosition()
	elseif kind == "pad" then
		return padPosition(if rest ~= "" then rest else nil)
	end
	return nil
end

-- A button on the screen: the round edge buttons, the dead chip, the food chip of the top strip.
local function hudTarget(name: string): GuiObject?
	local found: Instance? = nil
	local ok, root = pcall(UiKit.root)
	if name == "food" then
		local gui = player:FindFirstChild("PlayerGui")
		local strip = if gui then gui:FindFirstChild("GooTopStrip") else nil
		local bar = if strip then strip:FindFirstChild("Resources") else nil
		found = if bar then bar:FindFirstChild("food") else nil
	elseif ok and root then
		local edge = root:FindFirstChild("EdgeButtons")
		found = if edge then edge:FindFirstChild(name) else nil
		found = found or root:FindFirstChild(name)
	end
	return if found and found:IsA("GuiObject") and found.Visible then found else nil
end

-- ===== drawing =====

local function makeWorld()
	local part = Instance.new("Part")
	part.Name = "GuideAnchor"
	part.Size = Vector3.one * 0.2
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	local gui = Instance.new("BillboardGui")
	gui.Name = "Pointer"
	gui.Size = UDim2.fromOffset(G.PointerSize, G.PointerSize)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = G.PointerMaxDistance
	gui.Enabled = false
	gui.Adornee = part
	gui.Parent = part
	UiKit.make("ImageLabel", {
		Name = "Arrow",
		BackgroundTransparency = 1,
		Image = ARROW,
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1, 1),
		Rotation = POINT_DOWN,
	}, gui)
	-- The trail: small arrows on the anchor, each placed along the way by its offset and turned on the screen every
	-- frame (a Beam lays its picture across the beam, so its arrows pointed sideways).
	for i = 1, G.TrailMaxArrows do
		local dot = Instance.new("BillboardGui")
		dot.Name = "Trail" .. i
		-- (a BillboardGui's scale size is in studs: the arrows shrink with distance like things on the ground)
		dot.Size = UDim2.fromScale(G.TrailArrowStuds, G.TrailArrowStuds)
		dot.LightInfluence = 0
		dot.MaxDistance = G.PointerMaxDistance
		dot.Enabled = false
		dot.Adornee = part
		dot.Parent = part
		UiKit.make("ImageLabel", {
			Name = "Arrow",
			BackgroundTransparency = 1,
			Image = ARROW,
			ImageTransparency = G.TrailTransparency,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
		}, dot)
		trail[i] = dot
	end
	part.Parent = workspace
	anchor, billboard = part, gui
end

-- Lays the trail from the character's feet towards `at`, the arrows creeping forward, each turned to point along the
-- way as the camera sees it.
local function drawTrail(at: Vector3, t: number)
	local from = characterPosition()
	local camera = workspace.CurrentCamera
	local lift = Vector3.new(0, G.TrailLift, 0)
	local start = if from then from - Vector3.new(0, G.TrailFootDrop, 0) + lift else nil
	local finish = at + lift
	local way = if start then finish - start else Vector3.zero
	local flat = Vector3.new(way.X, 0, way.Z).Magnitude
	local count = 0
	if start and camera and flat > G.TrailMinStuds then
		local dir = way.Unit
		local creep = (t * G.TrailSpeed) % G.TrailSpacing
		local d = G.TrailStartStuds + creep
		while count < #trail and d < way.Magnitude - G.TrailEndStuds do
			count += 1
			local point = start + dir * d
			local dot = trail[count]
			dot.StudsOffsetWorldSpace = point - at
			local a = camera:WorldToViewportPoint(point)
			local b = camera:WorldToViewportPoint(point + dir)
			local arrow = dot:FindFirstChild("Arrow") :: ImageLabel
			arrow.Rotation = math.deg(math.atan2(b.Y - a.Y, b.X - a.X)) + POINT_RIGHT
			dot.Enabled = true
			d += G.TrailSpacing
		end
	end
	for i = count + 1, #trail do
		trail[i].Enabled = false
	end
end

local function layerOf(target: GuiObject): Frame?
	local gui = target:FindFirstAncestorOfClass("ScreenGui")
	if not gui then
		return nil
	end
	local layer = hudLayers[gui]
	if layer and layer.Parent == gui then
		return layer
	end
	local made = UiKit.make("Frame", {
		Name = "GuideLayer",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	}, gui) :: Frame
	hudLayers[gui] = made
	return made
end

local function stopPulse()
	local item = pulsed
	if item then
		if item.made then
			item.scale:Destroy()
		else
			item.scale.Scale = 1
		end
	end
	pulsed = nil
end

local function pulse(target: GuiObject, t: number)
	local item = pulsed
	if not item or item.target ~= target then
		stopPulse()
		-- (a button that already has a press scale keeps it: two UIScales on one thing do not mix)
		local existing = target:FindFirstChildOfClass("UIScale")
		local scale = existing or UiKit.make("UIScale", { Name = "GuidePulse" }, target) :: UIScale
		item = { target = target, scale = scale, made = existing == nil }
		pulsed = item
	end
	assert(item, "pulse state")
	local wave = (1 - math.cos(t * 2 * math.pi / G.PulseSeconds)) / 2
	item.scale.Scale = 1 + (G.PulseScale - 1) * wave
end

-- Where the arrow stands by each screen button: left of the right edge's buttons, under the top strip's food chip, right
-- of the dead chip at the left edge. (The top strip's own ScreenGui is only the topbar's height: its size says nothing.)
local sides: { [string]: string } = {
	slimes = "left",
	market = "left",
	home = "left",
	food = "below",
	skull = "right",
}

-- The arrow beside a screen button, pointing at it and bobbing toward it.
local function drawHud(target: GuiObject, t: number)
	local layer = layerOf(target)
	if not layer then
		return
	end
	local arrow = hudArrow
	if not arrow or arrow.Parent ~= layer then
		if arrow then
			arrow:Destroy()
		end
		arrow = UiKit.make("ImageLabel", {
			Name = "GuideArrow",
			BackgroundTransparency = 1,
			Image = ARROW,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 50,
		}, layer) :: ImageLabel
		hudArrow = arrow
	end
	assert(arrow, "hud arrow")
	local camera = workspace.CurrentCamera
	local screenY = if camera then camera.ViewportSize.Y else U.ScaleBaseHeight
	local scale = math.clamp(screenY / U.ScaleBaseHeight, 1, U.ScaleMax)
	local size = G.HudPointerSize * scale
	arrow.Size = UDim2.fromOffset(size, size)
	local centre = target.AbsolutePosition - layer.AbsolutePosition + target.AbsoluteSize / 2
	local half = target.AbsoluteSize / 2
	local bob = math.sin(t * 2 * math.pi / G.PointerBobSeconds) * G.HudPointerBobPixels * scale
	local reach = size / 2 + G.HudPointerGap * scale
	local side = sides[target.Name] or "above"
	local at: Vector2
	if side == "left" then
		arrow.Rotation = POINT_RIGHT
		at = centre - Vector2.new(half.X + reach + bob, 0)
	elseif side == "below" then
		arrow.Rotation = POINT_UP
		at = centre + Vector2.new(0, half.Y + reach + bob)
	elseif side == "right" then
		arrow.Rotation = 0
		at = centre + Vector2.new(half.X + reach + bob, 0)
	else
		arrow.Rotation = POINT_DOWN
		at = centre - Vector2.new(0, half.Y + reach + bob)
	end
	arrow.Position = UDim2.fromOffset(at.X, at.Y)
	arrow.Visible = true
	pulse(target, t)
end

local function hideHud()
	if hudArrow then
		hudArrow.Visible = false
	end
	stopPulse()
end

local function hideWorld()
	if billboard then
		billboard.Enabled = false
	end
	for _, dot in trail do
		dot.Enabled = false
	end
end

local function drawWorld(at: Vector3, t: number)
	if not anchor then
		makeWorld()
	end
	local part, gui = anchor :: Part, billboard :: BillboardGui
	part.CFrame = CFrame.new(at)
	local bob = math.sin(t * 2 * math.pi / G.PointerBobSeconds) * G.PointerBobStuds
	gui.StudsOffsetWorldSpace = Vector3.new(0, G.PointerLift + bob, 0)
	gui.Enabled = true
	drawTrail(at, t)
end

local function makeCard()
	local root = UiKit.root()
	local box, body = UiKit.card(root, {
		Name = "GuideCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, U.Edge),
		Size = UDim2.fromOffset(G.CardWidth, G.CardHeight),
		Visible = false,
	})
	cardScale = UiKit.make("UIScale", nil, box) :: UIScale
	local buttonWidth = U.Touch * 1.5
	lineLabel = UiKit.label(body, "", U.TextSmall, "Brown", {
		Name = "Line",
		Position = UDim2.fromOffset(U.Gap, 0),
		Size = UDim2.new(1, -U.Gap, 1, 0),
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 4,
	})
	nextButton = UiKit.button(body, {
		Name = "Next",
		Text = "Next",
		Style = "primary",
		Size = UDim2.new(0, buttonWidth, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		OnClick = function()
			send({ action = "GuideNext", step = shown })
		end,
	})
	skipButton = UiKit.button(body, {
		Name = "Skip",
		Text = "Skip",
		Style = "secondary",
		Size = UDim2.new(0, buttonWidth, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		OnClick = function()
			skipped = true
			send({ action = "GuideSkip" })
		end,
	})
	closeButton = UiKit.button(body, {
		Name = "Close",
		Icon = "close",
		Style = "secondary",
		Size = UDim2.new(0, U.Touch, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		OnClick = function()
			send({ action = "GuideSkip" })
		end,
	})
	card = box
end

-- Lays the card out for the step on screen: its line and the buttons at its right end (Next left of Skip).
local function layoutCard(id: string, kind: string)
	local box, label = card, lineLabel
	local nextB, skipB, closeB = nextButton, skipButton, closeButton
	if not box or not label or not nextB or not skipB or not closeB then
		return
	end
	local root = UiKit.root()
	local room = UiKit.units(root).X - 2 * (U.BookButton + 2 * U.Edge)
	box.Size = UDim2.fromOffset(math.min(G.CardWidth, room), G.CardHeight)
	label.Text = text("GuideLine")
	local tutorial = kind == "tutorial"
	local hasNext = attribute("GuideNext") == true
	skipB.Visible = tutorial
	closeB.Visible = not tutorial
	nextB.Visible = hasNext
	local right = if tutorial then skipB.Size.X.Offset else closeB.Size.X.Offset
	nextB.Position = UDim2.new(1, -right - U.Gap, 0, 0)
	local used = right + U.Gap + (if hasNext then nextB.Size.X.Offset + U.Gap else 0)
	label.Size = UDim2.new(1, -used - U.Gap, 1, 0)
	if id ~= shown then
		-- the original's card pop: 0.92 -> 1
		local scale = cardScale
		if scale then
			scale.Scale = 0.92
			UiKit.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	box.Visible = true
end

local function hideAll()
	if card then
		card.Visible = false
	end
	hideHud()
	hideWorld()
end

-- One look at what the server publishes; draws it and reports a screen the player opened.
local function step(t: number)
	local id = text("GuideId")
	local kind = text("GuideKind")
	if id == "" then
		if shownKind == "tutorial" and not skipped then
			UiKit.toast("Tutorial complete. Happy breeding!")
		end
		shown, shownKind = "", ""
		hideAll()
		return
	end
	if id ~= shown or kind ~= shownKind or (lineLabel and lineLabel.Text ~= text("GuideLine")) then
		if shownKind == "tutorial" and kind ~= "tutorial" and not skipped then
			UiKit.toast("Tutorial complete. Happy breeding!")
		end
		layoutCard(id, kind)
		shown, shownKind = id, kind
	end
	if nextButton then
		nextButton.Visible = attribute("GuideNext") == true
	end
	local target = text("GuideTarget")
	local hudName = string.match(target, "^hud:(.+)$")
	if hudName then
		hideWorld()
		local button = hudTarget(hudName)
		if button then
			drawHud(button, t)
		else
			hideHud()
		end
	else
		hideHud()
		local at = worldTarget(target)
		if at then
			drawWorld(at, t)
		else
			hideWorld()
		end
	end
end

function UiGuide.start(context: Context)
	ownOf = context.own
	makeCard()
	local clock = 0
	local polled = 0
	RunService.RenderStepped:Connect(function(dt: number)
		clock += dt
		local ok, err = pcall(function(): any
			step(clock)
			return nil
		end)
		if not ok then
			-- (one bad look never stops the guide; say it once)
			if not warned then
				warn(Config.LogPrefix, "guide:", err)
			end
			warned = true
			return
		end
		polled += dt
		if polled < G.SeenPollSeconds then
			return
		end
		polled = 0
		-- the screens the server cannot see: the book and the food panel
		local open = (shown == "book" and UiBook.isOpen()) or (shown == "food" and UiFood.isOpen())
		if open and reported ~= shown then
			reported = shown
			send({ action = "GuideSeen", step = shown })
		end
	end)
end

return UiGuide
