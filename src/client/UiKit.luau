--!strict
-- The screen kit: the owner's frames and buttons as nine-slice pictures, the original's parchment palette and one
-- rounded font. Mobile first: nothing a finger can press is below Config.Ui.Touch. One modal at a time, tap outside to
-- close. Pure drawing: it never reads game state and never decides a rule.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local U = Config.Ui
local FONT = (Enum.Font :: any)[U.Font] :: Enum.Font
local FULL = UDim2.fromScale(1, 1)

export type Props = { [string]: any }
export type Bar = { root: Frame, set: (fraction: number, low: boolean) -> () }
export type Chip = { root: GuiObject, set: (text: string) -> () }
export type Modal = { header: Frame, content: Frame }

type ModalState = {
	id: string,
	backdrop: TextButton,
	panel: Frame,
	onClose: (() -> ())?,
	final: UDim2,
}

local UiKit = {}
local warned: { [string]: boolean } = {}
local rootFrame: Frame? = nil
local scaler: UIScale? = nil
local modal: ModalState? = nil
local toastGroup: CanvasGroup? = nil
local toastText: TextLabel? = nil
local toastToken = 0

-- A button's style is a kit pill (Config.Ui.Kit); an icon-only button is the small square frame, tinted for its style.
local stylePiece: { [string]: string } = {
	primary = "gold",
	secondary = "cream",
	good = "green",
	danger = "red",
	soft = "cream",
	special = "purple",
}
local styleTint: { [string]: Color3 } = {
	primary = Color3.fromRGB(255, 205, 110),
	good = Color3.fromRGB(170, 235, 140),
	danger = Color3.fromRGB(255, 150, 140),
	special = Color3.fromRGB(215, 165, 255),
}
-- Short stand-ins for pictures that do not exist yet; never a final look.
local glyphs: { [string]: string } = {
	energy = "Zz",
	fun = "Fun",
	close = "X",
	back = "<",
	plus = "+",
	cross = "x",
	again = "R",
}

local function merge(base: Props, extra: Props?): Props
	if extra then
		for key, value in extra do
			base[key] = value
		end
	end
	return base
end

local function make(className: string, props: Props?, parent: Instance?): any
	local inst = Instance.new(className)
	if props then
		for key, value in props do
			(inst :: any)[key] = value
		end
	end
	inst.Parent = parent
	return inst
end

-- 1234567 -> "1,234,567"
function UiKit.money(amount: number): string
	local digits = tostring(math.floor(amount))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

function UiKit.colour(name: string): Color3
	return Color3.fromHex((U.Colours :: any)[name])
end

function UiKit.make(className: string, props: Props?, parent: Instance?): any
	return make(className, props, parent)
end

function UiKit.tween(inst: Instance, seconds: number, goal: Props, style: Enum.EasingStyle?): Tween
	local item = TweenService:Create(
		inst,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		goal
	)
	item:Play()
	return item
end

function UiKit.label(parent: Instance?, text: string, size: number, colour: string?, props: Props?): TextLabel
	return make(
		"TextLabel",
		merge({
			Text = text,
			TextSize = size,
			TextColor3 = UiKit.colour(colour or "Brown"),
			Font = FONT,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, 0, 0, size + 6),
		}, props),
		parent
	)
end

function UiKit.clear(parent: Instance)
	for _, child in parent:GetChildren() do
		if not (child:IsA("UIListLayout") or child:IsA("UIGridLayout") or child:IsA("UIPadding")) then
			child:Destroy()
		end
	end
end

-- A picture the screen needs. id 0 = not drawn yet: logged once, a short stand-in shows.
function UiKit.icon(parent: Instance?, name: string, size: number, props: Props?): GuiObject
	local id = (U.Icons :: any)[name]
	if type(id) == "number" and id > 0 then
		return make(
			"ImageLabel",
			merge({
				Name = name,
				BackgroundTransparency = 1,
				Image = "rbxassetid://" .. tostring(id),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(size, size),
			}, props),
			parent
		)
	end
	if not warned[name] then
		warned[name] = true
		warn(Config.LogPrefix, "missing Config.Ui.Icons." .. name .. " (picture not made yet, stand-in shown)")
	end
	return make(
		"TextLabel",
		merge({
			Name = name,
			BackgroundTransparency = 1,
			Text = glyphs[name] or string.upper(string.sub(name, 1, 2)),
			TextColor3 = UiKit.colour("BrownSoft"),
			TextScaled = true,
			Font = FONT,
			Size = UDim2.fromOffset(size, size),
		}, props),
		parent
	)
end

-- A size in points: the drawn size with every UIScale above it taken back out (nine-slice edges are drawn in points).
local function points(inst: GuiObject): Vector2
	local scale = 1
	local node: Instance? = inst
	while node do
		local factor = node:FindFirstChildOfClass("UIScale")
		if factor then
			scale *= factor.Scale
		end
		node = node.Parent
	end
	return inst.AbsoluteSize / math.max(scale, 0.01)
end

-- Puts a kit piece on a picture: its image, its nine-slice centre and the scale of its edges.
local function wear(image: ImageLabel, name: string)
	local piece = (U.Kit :: any)[name]
	image.Image = "rbxassetid://" .. tostring(piece.Id)
	image:SetAttribute("Piece", name)
	local slice = piece.Slice
	if not slice then
		image.ScaleType = Enum.ScaleType.Fit
		return
	end
	image.ScaleType = Enum.ScaleType.Slice
	if slice[2] == 0 and slice[4] == piece.Height then
		-- sliced only left and right: the height fills the box, so the round ends stay round. (A centre as tall as the
		-- picture draws wrongly in Roblox, so the centre is a thin middle row.)
		local half = piece.Height / 2
		image.SliceCenter = Rect.new(slice[1], half - 1, slice[3], half + 1)
		local height = points(image).Y
		if height > 0 then
			image.SliceScale = height / piece.Height
		end
	else
		image.SliceCenter = Rect.new(slice[1], slice[2], slice[3], slice[4])
		image.SliceScale = piece.Scale or 1
	end
end

-- A piece of the UI kit (Config.Ui.Kit) as a picture, at its own size unless props say otherwise.
function UiKit.kit(parent: Instance?, name: string, props: Props?): ImageLabel
	local piece = (U.Kit :: any)[name]
	local image = make(
		"ImageLabel",
		merge({
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(piece.Width, piece.Height),
		}, props),
		parent
	) :: ImageLabel
	wear(image, name)
	if piece.Slice then
		image:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			wear(image, image:GetAttribute("Piece") :: string)
		end)
	end
	return image
end

-- Which kit frame a skin key draws: the modal's window, or the small wood frame of cards, tiles and buttons.
local skinPiece: { [string]: string } = { Panel = "window", Wood = "square" }

-- Tints the inside of a skin (UiKit.skin); the plain cream fills leave the frame's own painted inside showing.
function UiKit.setFill(box: Instance, fill: string)
	local panel = box:FindFirstChild("Fill")
	if panel and panel:IsA("Frame") then
		panel.BackgroundColor3 = UiKit.colour(fill)
		panel.BackgroundTransparency = if fill == "Card" or fill == "Parchment" then 1 else 0
	end
end

-- A kit frame with its cream inside and a Fill over it that UiKit.setFill tints. Returns the box and its content area.
function UiKit.skin(parent: Instance?, key: string, fill: string?, props: Props?): (Frame, Frame)
	local name = skinPiece[key] or key
	local inset: number = (U.Kit :: any)[name].Inset or 0
	local box = make("Frame", merge({ Name = key, BackgroundTransparency = 1 }, props), parent)
	UiKit.kit(box, name, { Name = "Border", Size = FULL, ZIndex = 1 })
	local panel = make("Frame", {
		Name = "Fill",
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.new(1, -2 * inset, 1, -2 * inset),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, box)
	make("UICorner", { CornerRadius = UDim.new(0, inset) }, panel)
	UiKit.setFill(box, fill or "Card")
	local body = make("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.new(1, -2 * inset, 1, -2 * inset),
		ZIndex = 3,
	}, box)
	return box, body
end

-- Text on a coloured kit piece: white with the concept's dark outline.
function UiKit.outline(label: TextLabel, on: boolean)
	local stroke = label:FindFirstChild("Outline") :: UIStroke?
	if on and not stroke then
		stroke = make("UIStroke", {
			Name = "Outline",
			Color = Color3.fromHex(U.KitOutline),
			Thickness = U.KitOutlineThickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}, label)
	end
	if stroke then
		stroke.Enabled = on
	end
	label.TextColor3 = if on then Color3.new(1, 1, 1) else UiKit.colour("Brown")
end

local function pressable(button: GuiButton, target: Instance)
	local scale = make("UIScale", nil, target)
	local function rest()
		UiKit.tween(scale, 0.08, { Scale = 1 })
	end
	button.MouseButton1Down:Connect(function()
		if button:GetAttribute("Enabled") ~= false then
			UiKit.tween(scale, 0.06, { Scale = U.PressScale })
		end
	end)
	button.MouseButton1Up:Connect(rest)
	button.MouseLeave:Connect(rest)
end

function UiKit.setStyle(button: GuiButton, style: string)
	local group = button:FindFirstChild("Visual")
	local face = if group then group:FindFirstChild("Face") else nil
	local body = if group then group:FindFirstChild("Body") else nil
	local label = if body then body:FindFirstChild("Label") else nil
	local piece = stylePiece[style] or "cream"
	if face and face:IsA("ImageLabel") then
		if face:GetAttribute("Piece") == "square" then
			face.ImageColor3 = styleTint[style] or Color3.new(1, 1, 1)
		else
			wear(face, piece)
		end
	end
	if label and label:IsA("TextLabel") then
		UiKit.outline(label, piece ~= "cream")
	end
	button:SetAttribute("Style", style)
end

function UiKit.setEnabled(button: GuiButton, enabled: boolean)
	button:SetAttribute("Enabled", enabled)
	local group = button:FindFirstChild("Visual")
	if group and group:IsA("CanvasGroup") then
		group.GroupTransparency = if enabled then 0 else U.DisabledTransparency
	end
end

-- A wooden button: text, an icon, or both. Props: Text, Icon, Style (primary, secondary, good, danger, soft),
-- Size, Position, AnchorPoint, LayoutOrder, OnClick, TextSize, Enabled.
function UiKit.button(parent: Instance?, props: Props): TextButton
	local style: string = props.Style or "primary"
	local button = make("TextButton", {
		Name = props.Name or "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(U.Touch * 2, U.Touch),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
	}, parent)
	local group = make("CanvasGroup", { Name = "Visual", BackgroundTransparency = 1, Size = FULL }, button)
	local square = props.Text == nil
	UiKit.kit(group, if square then "square" else stylePiece[style] or "cream", { Name = "Face", Size = FULL })
	local body = make("Frame", { Name = "Body", BackgroundTransparency = 1, Size = FULL, ZIndex = 2 }, group)
	if not square then
		-- (the pill's glossy rim is thicker at the bottom)
		make("UIPadding", {
			PaddingLeft = UDim.new(0, U.Gap),
			PaddingRight = UDim.new(0, U.Gap),
			PaddingBottom = UDim.new(0, 2),
		}, body)
	end
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)
	if props.Icon then
		UiKit.icon(body, props.Icon, props.IconSize or U.IconNormal, { LayoutOrder = 1 })
	end
	if props.Text then
		UiKit.label(body, props.Text, props.TextSize or U.TextSmall, "Brown", {
			Name = "Label",
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
	end
	pressable(button, group)
	UiKit.setStyle(button, style)
	UiKit.setEnabled(button, props.Enabled ~= false)
	local onClick = props.OnClick
	button.Activated:Connect(function()
		if button:GetAttribute("Enabled") ~= false and onClick then
			onClick()
		end
	end)
	return button
end

-- A round picture button on the screen edge: the owner's ui.btn art, never recoloured, kept in proportion.
function UiKit.roundButton(parent: Instance?, key: string, size: number, onClick: () -> (), props: Props?): ImageButton
	local id = (U.Buttons :: any)[key]
	local button = make(
		"ImageButton",
		merge({
			Name = key,
			BackgroundTransparency = 1,
			Image = if type(id) == "number" and id > 0 then "rbxassetid://" .. tostring(id) else "",
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size, size),
			AutoButtonColor = false,
		}, props),
		parent
	)
	if button.Image == "" then
		UiKit.icon(button, key, size)
	end
	pressable(button, button)
	button.Activated:Connect(onClick)
	return button
end

-- A 3D item shown as a picture (the owner's rule: food icons come from the 3D models, not drawings): a copy of the
-- model in a small ViewportFrame, framed by its own size, rendered once (nothing in it moves).
function UiKit.modelIcon(parent: Instance?, model: Instance, size: number, props: Props?): GuiObject
	local view = make(
		"ViewportFrame",
		merge({
			Name = model.Name,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
			Ambient = Color3.fromRGB(200, 200, 200),
			LightColor = Color3.new(1, 1, 1),
			LightDirection = Vector3.new(-1, -2, -1),
		}, props),
		parent
	) :: ViewportFrame
	local copy = model:Clone()
	local holder: Model
	if copy:IsA("Model") then
		holder = copy
	else
		holder = Instance.new("Model")
		copy.Parent = holder
	end
	holder.Parent = view
	local box, extents = holder:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = U.ModelIconFov
	local radius = extents.Magnitude / 2
	local distance = radius / math.tan(math.rad(U.ModelIconFov / 2)) * U.ModelIconPad
	local from = box.Position + Vector3.new(1, U.ModelIconLift, 1).Unit * distance
	camera.CFrame = CFrame.lookAt(from, box.Position)
	camera.Parent = view
	view.CurrentCamera = camera
	return view
end

-- A small count chip for the resource strip: picture and number on a wooden plate. `model`: show this 3D item
-- (ClientKit.Items) instead of the icon picture.
function UiKit.chip(parent: Instance?, icon: string, text: string, order: number, model: Instance?): Chip
	-- the kit's counter plate: the picture sits in its round socket at the left, the number on the cream part
	local height = U.ChipHeight
	local socket = height * 0.85
	local box = UiKit.kit(parent, "counter", {
		Name = icon,
		Size = UDim2.fromOffset(0, height),
		LayoutOrder = order,
	})
	local picture = {
		Name = "Picture",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, socket / 2 + 1, 0.5, 0),
		ZIndex = 2,
	}
	if model then
		UiKit.modelIcon(box, model, U.IconSmall, picture)
	else
		UiKit.icon(box, icon, U.IconSmall, picture)
	end
	local value = UiKit.label(box, text, U.TextSmall, "Brown", {
		Name = "Value",
		Position = UDim2.fromOffset(socket + 2, 0),
		Size = UDim2.new(1, -socket - 8, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
	})
	local function set(next: string)
		value.Text = next
		box.Size = UDim2.fromOffset(socket + 16 + #next * 9, height)
	end
	set(text)
	return { root = box, set = set }
end

-- A bar's colour name as a kit bar (Config.Ui.Kit), with a tint for colours the kit has no bar of; a low need turns red.
local barPiece: { [string]: string } = {
	Fullness = "barOrange",
	GoldLight = "barOrange",
	Energy = "barBlue",
	Fun = "barPink",
	Green = "barBlue",
}
local barTint: { [string]: Color3 } = { Green = Color3.fromRGB(120, 255, 110) }
local lowTint = Color3.fromRGB(255, 110, 100)

-- A need bar: a picture and a filling track. No numbers, no words.
function UiKit.bar(parent: Instance?, icon: string, colour: string, props: Props?): Bar
	local row = make(
		"Frame",
		merge({
			Name = (if icon == "" then "Progress" else icon) .. "Bar",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, U.IconSmall),
		}, props),
		parent
	)
	local lead = 0
	if icon ~= "" then
		UiKit.icon(row, icon, U.IconSmall, { Position = UDim2.fromOffset(0, 0) })
		lead = U.IconSmall + 4
	end
	local track = UiKit.kit(row, "track", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, lead, 0.5, 0),
		Size = UDim2.new(1, -lead, 0, U.BarHeight),
	})
	local fill = UiKit.kit(track, barPiece[colour] or "barOrange", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		ImageColor3 = barTint[colour] or Color3.new(1, 1, 1),
	})
	local function set(fraction: number, low: boolean)
		local part = math.clamp(fraction, 0, 1)
		fill.Size = UDim2.fromScale(part, 1)
		fill.Visible = part > 0
		fill.ImageColor3 = if low then lowTint else barTint[colour] or Color3.new(1, 1, 1)
	end
	-- (never narrower than tall while it shows, so its round ends stay round)
	make("UISizeConstraint", { Name = "Round", MinSize = Vector2.new(U.BarHeight, 0) }, fill)
	return { root = row, set = set }
end

-- A row of toggle buttons, one selected: sort and filter choices. Items: { id, text?, icon? }.
function UiKit.segmented(
	parent: Instance?,
	items: { { id: string, text: string?, icon: string? } },
	selected: string,
	onSelect: (string) -> (),
	props: Props?
): Frame
	local itemWidth = if props then props.ItemWidth else nil
	if props then
		props.ItemWidth = nil
	end
	local row = make(
		"Frame",
		merge({ Name = "Segmented", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, U.Touch) }, props),
		parent
	)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local buttons: { [string]: TextButton } = {}
	for index, item in items do
		local button = UiKit.button(row, {
			Name = item.id,
			Text = item.text,
			Icon = item.icon,
			Style = if item.id == selected then "primary" else "secondary",
			Size = UDim2.fromOffset(itemWidth or (if item.text then U.Touch + 8 else U.Touch), U.Touch),
			LayoutOrder = index,
			OnClick = function()
				for id, other in buttons do
					UiKit.setStyle(other, if id == item.id then "primary" else "secondary")
				end
				onSelect(item.id)
			end,
		})
		buttons[item.id] = button
	end
	return row
end

-- A list card: the owner's wood frame around a cream plate. Body is where the content goes.
function UiKit.card(parent: Instance?, props: Props?): (Frame, Frame)
	return UiKit.skin(parent, "Wood", "Card", props)
end

function UiKit.root(): Frame
	assert(rootFrame, "UiKit.mount first")
	return rootFrame
end

-- Pixels of the scaled screen: AbsoluteSize / UIScale.
function UiKit.units(inst: GuiObject): Vector2
	local scale = if scaler then scaler.Scale else 1
	return inst.AbsoluteSize / scale
end

function UiKit.mount(gui: ScreenGui): Frame
	local frame = make("Frame", { Name = "Root", BackgroundTransparency = 1, Size = FULL }, gui)
	local scale = make("UIScale", nil, frame)
	local function fit()
		local value = math.clamp(gui.AbsoluteSize.Y / U.ScaleBaseHeight, 1, U.ScaleMax)
		scale.Scale = value
		frame.Size = UDim2.fromScale(1 / value, 1 / value)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	rootFrame, scaler = frame, scale
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and modal then
			UiKit.closeModal()
		end
	end)
	return frame
end

function UiKit.modalId(): string?
	return if modal then modal.id else nil
end

function UiKit.closeModal(immediate: boolean?)
	local state = modal
	if not state then
		return
	end
	modal = nil
	if state.onClose then
		state.onClose()
	end
	if immediate then
		state.backdrop:Destroy()
		state.panel:Destroy()
		return
	end
	UiKit.tween(state.backdrop, U.OpenSeconds, { BackgroundTransparency = 1 })
	local out = UiKit.tween(state.panel, U.OpenSeconds, {
		Position = state.final + UDim2.fromOffset(0, U.OpenSlide),
	}, Enum.EasingStyle.Quad)
	out.Completed:Once(function()
		state.backdrop:Destroy()
		state.panel:Destroy()
	end)
end

-- Opens the one modal: a gold-framed parchment panel with a header (the close button sits at its right edge) and a
-- content area. Props: Width, Height (maximums), Bottom (a bottom sheet), Dim (backdrop transparency), OnClose.
function UiKit.openModal(id: string, props: Props): Modal
	UiKit.closeModal(true)
	local parent = UiKit.root()
	local backdrop = make("TextButton", {
		Name = "Backdrop",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = UiKit.colour("Backdrop"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = FULL,
		ZIndex = 10,
	}, parent)
	local bottom = props.Bottom == true
	local final = if bottom then UDim2.new(0.5, 0, 1, -U.Edge) else UDim2.fromScale(0.5, 0.5)
	local panel = make("Frame", {
		Name = "Modal_" .. id,
		AnchorPoint = Vector2.new(0.5, if bottom then 1 else 0.5),
		Position = final + UDim2.fromOffset(0, U.OpenSlide),
		Size = UDim2.new(1, -2 * U.Edge, 1, -2 * U.Edge),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = 11,
	}, parent)
	make("UISizeConstraint", {
		MaxSize = Vector2.new(props.Width or U.SheetWidth, props.Height or U.SheetHeight),
	}, panel)
	local _, body = UiKit.skin(panel, "Panel", "Parchment", { Size = FULL, ZIndex = 1 })
	local top = make("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2 * U.Gap, 0, U.Touch),
		Position = UDim2.fromOffset(U.Gap, U.Gap),
	}, body)
	-- The header is the free part of the top bar, left of the close button.
	local header = make("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -U.Touch - U.Gap, 1, 0),
	}, top)
	local content = make("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(U.Gap, U.Touch + 2 * U.Gap),
		Size = UDim2.new(1, -2 * U.Gap, 1, -U.Touch - 3 * U.Gap),
	}, body)
	UiKit.button(top, {
		Name = "Close",
		Icon = "close",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		OnClick = function()
			UiKit.closeModal()
		end,
	})
	backdrop.Activated:Connect(function()
		if modal and modal.backdrop == backdrop then
			UiKit.closeModal()
		end
	end)
	modal = { id = id, backdrop = backdrop, panel = panel, onClose = props.OnClose, final = final }
	UiKit.tween(backdrop, U.OpenSeconds, { BackgroundTransparency = props.Dim or U.BackdropTransparency })
	UiKit.tween(panel, U.OpenSeconds, { Position = final }, Enum.EasingStyle.Back)
	return { header = header, content = content }
end

-- The open modal's greatest height in points: `height` sets it, nil puts back the one it opened with (`props.Height`).
-- (A page that needs less room than its sheet, like the slime page on a wide screen, shrinks it to fit.)
function UiKit.setModalHeight(height: number?)
	local panel = if modal then modal.panel else nil
	local limit = if panel then panel:FindFirstChildOfClass("UISizeConstraint") else nil
	if not (panel and limit) then
		return
	end
	local opened = panel:GetAttribute("OpenedHeight")
	if type(opened) ~= "number" then
		opened = limit.MaxSize.Y
		panel:SetAttribute("OpenedHeight", opened)
	end
	local nextHeight = math.min(height or opened :: number, opened :: number)
	if math.abs(limit.MaxSize.Y - nextHeight) > 0.5 then
		limit.MaxSize = Vector2.new(limit.MaxSize.X, nextHeight)
	end
end

-- The open modal's height in points as it is drawn now (0 when none is open).
function UiKit.modalHeight(): number
	return if modal then UiKit.units(modal.panel).Y else 0
end

-- A short message under the resource strip; a new one replaces the old.
function UiKit.toast(text: string)
	local parent = UiKit.root()
	if not toastGroup or not toastText then
		local group = make("CanvasGroup", {
			Name = "Toast",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, U.Edge + U.ChipHeight + U.Gap * 2),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			ZIndex = 20,
		}, parent)
		local _, body = UiKit.skin(group, "Wood", "Card", { Size = FULL })
		toastText = UiKit.label(body, "", U.TextNormal, "Brown", {
			Size = FULL,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		toastGroup = group
	end
	local group, label = toastGroup, toastText
	if not group or not label then
		return
	end
	label.Text = text
	group.Size = UDim2.fromOffset(math.clamp(#text * 10 + 36, 140, 380), U.Touch)
	toastToken += 1
	local mine = toastToken
	UiKit.tween(group, 0.12, { GroupTransparency = 0 })
	task.delay(U.ToastSeconds, function()
		if mine == toastToken and group.Parent then
			UiKit.tween(group, 0.3, { GroupTransparency = 1 })
		end
	end)
end

return UiKit
