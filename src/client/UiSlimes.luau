--!strict
-- Slime cards for the screen: a live portrait (SlimeLook), name, level, the four stats and the three needs, the job or
-- state as a small tag. Shared by the slime book and the picker. Reads the attributes the server publishes; decides
-- nothing.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FaceArt = require(ReplicatedStorage.Shared.FaceArt)
local SlimeLook = require(script.Parent.SlimeLook)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
local C = Config.VillageClient

export type Entry = {
	slime: Configuration,
	suggested: boolean?,
	blocked: string?,
}
export type Card = {
	root: TextButton,
	slime: Configuration,
	update: (entry: Entry) -> (),
	show: () -> (),
}
export type View = {
	scroller: ScrollingFrame,
	refresh: () -> (),
}

local UiSlimes = {}

local statIcons = { { "attack", "Attack" }, { "defence", "Defence" }, { "speed", "Speed" }, { "hp", "Hp" } }

function UiSlimes.slimes(own: Instance?): { Configuration }
	local found: { Configuration } = {}
	local folder = if own then own:FindFirstChild("Slimes") else nil
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("Configuration") then
				table.insert(found, child)
			end
		end
	end
	table.sort(found, function(a, b)
		return a.Name < b.Name
	end)
	return found
end

function UiSlimes.number(slime: Instance, name: string): number
	local value = slime:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

function UiSlimes.name(slime: Instance): string
	local value = slime:GetAttribute("Name")
	return if type(value) == "string" and value ~= "" then value else slime.Name
end

function UiSlimes.isBaby(slime: Instance): boolean
	return slime:GetAttribute("Baby") ~= false
end

function UiSlimes.isGhost(slime: Instance): boolean
	return slime:GetAttribute("Ghost") == true
end

function UiSlimes.job(slime: Instance): string?
	local area = slime:GetAttribute("WorkArea")
	return if type(area) == "string" and area ~= "" then area else nil
end

function UiSlimes.pair(slime: Instance): number
	return UiSlimes.number(slime, "PairIndex")
end

-- Free to be given a task: a grown, living slime with no job and no pair.
function UiSlimes.isFree(slime: Instance): boolean
	return not UiSlimes.isBaby(slime)
		and not UiSlimes.isGhost(slime)
		and UiSlimes.job(slime) == nil
		and UiSlimes.pair(slime) == 0
end

-- A live portrait of the slime's own look. Returns the framed box and a function that builds the viewport (cheap
-- lists build it only when the card scrolls into view).
function UiSlimes.portrait(
	parent: Instance?,
	slime: Configuration,
	size: number,
	props: UiKit.Props?
): (Frame, () -> ())
	local box, body = UiKit.skin(parent, "Wood", "Portrait", props)
	box.Size = UDim2.fromOffset(size, size)
	local built = false
	local function build()
		if built or not body.Parent then
			return
		end
		built = true
		local view = UiKit.make("ViewportFrame", {
			Name = "Portrait",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Ambient = Color3.new(1, 1, 1),
			LightColor = Color3.new(1, 1, 1),
		}, body)
		local world = UiKit.make("WorldModel", nil, view)
		local model = SlimeLook.build({
			Colour = slime:GetAttribute("Colour"),
			Material = slime:GetAttribute("Material"),
			DualId = slime:GetAttribute("DualId"),
			SecretId = slime:GetAttribute("SecretId"),
			Scale = 1,
		})
		model:PivotTo(CFrame.Angles(0, math.pi, 0))
		model.Parent = world
		local camera = UiKit.make("Camera", nil, view)
		camera.CFrame = CFrame.lookAt(
			Vector3.new(0, C.BodyHeight * U.PortraitEye, C.BodyHeight * U.PortraitDistance),
			Vector3.new(0, C.BodyHeight * U.PortraitLook, 0)
		)
		view.CurrentCamera = camera
		-- The owner's own face pictures (the "normal" expression) laid over the body at its face height. One body height
		-- is `unit` of the portrait.
		local unit = U.PortraitFaceZoom / (2 * U.PortraitDistance * math.tan(math.rad(U.PortraitFov / 2)))
		for _, name in { "normal_eyeL", "normal_eyeR", "normal_mouth" } do
			local sprite = FaceArt.Sprites[name]
			UiKit.make("ImageLabel", {
				Name = name,
				BackgroundTransparency = 1,
				Image = "rbxassetid://" .. tostring(sprite.id),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(
					0.5 + sprite.cx * unit,
					0.5 - (FaceArt.FaceHeight - U.PortraitLook + sprite.cy) * unit
				),
				Size = UDim2.fromScale(sprite.w * unit, sprite.h * unit),
			}, view)
		end
	end
	return box, build
end

local function tagFill(kind: string): string
	if kind == "suggested" then
		return "Green"
	elseif kind == "baby" then
		return "Blue"
	elseif kind == "ghost" then
		return "BrownSoft"
	end
	return "CardDeep"
end

-- The small tag at the card's top right: an area picture, or one short word.
local function drawTag(host: Frame, slime: Configuration, entry: Entry)
	local kind, word, picture = "", nil :: string?, nil :: string?
	if entry.suggested then
		kind, word = "suggested", "Suggested"
	elseif entry.blocked then
		kind, word = "blocked", entry.blocked
	elseif UiSlimes.isGhost(slime) then
		kind, word = "ghost", "Ghost"
	elseif UiSlimes.isBaby(slime) then
		kind, word = "baby", "Baby"
	elseif UiSlimes.job(slime) then
		kind, picture = "job", UiSlimes.job(slime)
		if slime:GetAttribute("Reserve") == true then
			word = "Reserve"
		end
	elseif UiSlimes.pair(slime) > 0 then
		kind, picture, word = "pair", "breeding", "#" .. tostring(UiSlimes.pair(slime))
	elseif slime:GetAttribute("Sleeping") == true or UiSlimes.number(slime, "Energy") <= Config.Needs.Tired then
		kind, word = "rest", "Resting"
	end
	local key = kind .. tostring(word) .. tostring(picture)
	if host:GetAttribute("Key") == key then
		return
	end
	host:SetAttribute("Key", key)
	UiKit.clear(host)
	if kind == "" then
		return
	end
	local pill = UiKit.make("Frame", {
		Name = "Pill",
		BackgroundColor3 = UiKit.colour(tagFill(kind)),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, U.TagHeight),
		AutomaticSize = Enum.AutomaticSize.X,
	}, host)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
	UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, pill)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, pill)
	if picture then
		UiKit.icon(pill, picture, U.TagHeight - 2, { LayoutOrder = 1 })
	end
	if word then
		local onColour = if kind == "suggested" or kind == "baby" or kind == "ghost" then "Cream" else "Brown"
		UiKit.label(pill, word, U.TextTiny, onColour, {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
end

function UiSlimes.card(parent: Instance?, entry: Entry, onClick: ((Configuration) -> ())?): Card
	local slime = entry.slime
	local root = UiKit.make("TextButton", {
		Name = slime.Name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
	}, parent)
	local box, body = UiKit.card(root, { Size = UDim2.fromScale(1, 1) })
	local _, show = UiSlimes.portrait(body, slime, U.PortraitSize, { Position = UDim2.fromOffset(0, 0) })
	local level = UiKit.label(body, "", U.TextSmall, "Brown", {
		Position = UDim2.fromOffset(0, U.PortraitSize + 2),
		Size = UDim2.fromOffset(U.PortraitSize, U.TextSmall + 6),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local right = UiKit.make("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(U.PortraitSize + U.Gap, 0),
		Size = UDim2.new(1, -U.PortraitSize - U.Gap, 1, 0),
	}, body)
	local name = UiKit.label(right, "", U.TextNormal, "Brown", { Size = UDim2.new(1, -70, 0, U.TagHeight) })
	local tagHost = UiKit.make("Frame", {
		Name = "Tag",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(70, U.TagHeight),
	}, right)
	local values: { [string]: TextLabel } = {}
	for index, item in statIcons do
		local cell = UiKit.make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new((index - 1) / 4, 0, 0, U.TagHeight + 2),
			Size = UDim2.new(0.25, 0, 0, U.StatCellIcon),
		}, right)
		UiKit.icon(cell, item[1], U.StatCellIcon)
		values[item[2]] = UiKit.label(cell, "0", U.TextTiny, "Brown", {
			Position = UDim2.fromOffset(U.StatCellIcon + 2, 0),
			Size = UDim2.new(1, -U.StatCellIcon - 2, 1, 0),
		})
	end
	local bars = {}
	local top = U.TagHeight + U.StatCellIcon + 6
	for index, item in
		{ { "fullness", "Fullness", "Fullness" }, { "energy", "Energy", "Energy" }, { "fun", "Fun", "Fun" } }
	do
		bars[item[2]] = UiKit.bar(right, item[1], item[3], {
			Position = UDim2.fromOffset(0, top + (index - 1) * (U.IconSmall - 2)),
			Size = UDim2.new(1, 0, 0, U.IconSmall - 2),
		})
	end
	local veil = UiKit.make("Frame", {
		Name = "Veil",
		BackgroundColor3 = UiKit.colour("Parchment"),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 5,
	}, body)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0, 8) }, veil)
	local current = entry
	local function update(next: Entry)
		current = next
		level.Text = "Lv " .. tostring(UiSlimes.number(slime, "Level"))
		name.Text = UiSlimes.name(slime)
		for _, item in statIcons do
			values[item[2]].Text = tostring(UiSlimes.number(slime, item[2]))
		end
		bars.Fullness.set(
			UiSlimes.number(slime, "Fullness") / Config.Needs.Max,
			UiSlimes.number(slime, "Fullness") <= Config.Needs.Hungry
		)
		bars.Energy.set(
			UiSlimes.number(slime, "Energy") / Config.Needs.Max,
			UiSlimes.number(slime, "Energy") <= Config.Needs.Tired
		)
		bars.Fun.set(UiSlimes.number(slime, "Fun") / Config.Needs.Max, false)
		drawTag(tagHost, slime, next)
		veil.Visible = next.blocked ~= nil
		local fill = box:FindFirstChild("Fill")
		if fill and fill:IsA("Frame") then
			fill.BackgroundColor3 = UiKit.colour(if next.suggested then "Portrait" else "Card")
		end
	end
	update(entry)
	root.Activated:Connect(function()
		if onClick and not current.blocked then
			onClick(slime)
		end
	end)
	return { root = root, slime = slime, update = update, show = show }
end

-- A scrolling grid of cards. Entries decide who is shown and in which order; refresh redraws in place when the same
-- slimes are shown (so scroll and portraits stay), and rebuilds only when the list changes.
function UiSlimes.view(
	parent: Instance,
	entries: () -> { Entry },
	onClick: (Configuration) -> (),
	single: boolean?
): View
	local scroller = UiKit.make("ScrollingFrame", {
		Name = "Cards",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = UiKit.colour("BrownSoft"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent)
	local grid = UiKit.make("UIGridLayout", {
		CellPadding = UDim2.fromOffset(U.Gap, U.Gap),
		CellSize = UDim2.fromOffset(U.CardWidth, U.CardHeight),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroller)
	UiKit.make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, scroller)
	local cards: { [string]: Card } = {}
	local order: { string } = {}
	local signature = ""

	local function fit()
		local width = UiKit.units(scroller).X - 8 - 5
		local columns = if single then 1 else math.max(1, math.floor((width + U.Gap) / (U.CardWidth + U.Gap)))
		local cell = math.floor((width - U.Gap * (columns - 1)) / columns)
		grid.CellSize = UDim2.fromOffset(math.max(cell, U.CardWidth * 0.8), U.CardHeight)
	end
	local function reveal()
		local top = scroller.AbsolutePosition.Y - U.CardHeight
		local bottom = scroller.AbsolutePosition.Y + scroller.AbsoluteSize.Y + U.CardHeight
		for _, id in order do
			local card = cards[id]
			if card and card.root.AbsolutePosition.Y >= top and card.root.AbsolutePosition.Y <= bottom then
				card.show()
			end
		end
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		fit()
		task.defer(reveal)
	end)
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(reveal)

	local function refresh()
		local list = entries()
		local parts: { string } = {}
		for _, entry in list do
			table.insert(parts, entry.slime.Name .. (if entry.suggested then "!" else "") .. (entry.blocked or ""))
		end
		local nextSignature = table.concat(parts, "|")
		if nextSignature == signature then
			for _, entry in list do
				local card = cards[entry.slime.Name]
				if card then
					card.update(entry)
				end
			end
			return
		end
		local keep = scroller.CanvasPosition
		signature = nextSignature
		local fresh: { [string]: Card } = {}
		table.clear(order)
		for index, entry in list do
			local id = entry.slime.Name
			local card = cards[id]
			if card then
				card.update(entry)
			else
				card = UiSlimes.card(scroller, entry, onClick)
			end
			card.root.LayoutOrder = index
			fresh[id] = card
			table.insert(order, id)
		end
		for id, card in cards do
			if not fresh[id] then
				card.root:Destroy()
			end
		end
		cards = fresh
		fit()
		task.defer(function()
			if scroller.Parent then
				scroller.CanvasPosition = keep
				reveal()
			end
		end)
	end
	return { scroller = scroller, refresh = refresh }
end

return UiSlimes
