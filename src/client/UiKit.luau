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
export type Chip = { root: Frame, set: (text: string) -> () }
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

local styleFill: { [string]: string } = {
	primary = "Gold",
	secondary = "Cream",
	good = "Green",
	danger = "Red",
	soft = "CardDeep",
}
local styleText: { [string]: string } = {
	primary = "Cream",
	secondary = "Brown",
	good = "Cream",
	danger = "Cream",
	soft = "Brown",
}
-- Short stand-ins for pictures that do not exist yet; never a final look.
local glyphs: { [string]: string } = { energy = "Zz", fun = "Fun", close = "X", back = "<", plus = "+", cross = "x" }

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

-- The owner's frame as a nine-slice border over a flat parchment fill. Returns the box and its content area.
function UiKit.skin(parent: Instance?, key: string, fill: string?, props: Props?): (Frame, Frame)
	local frame = (U.Frames :: any)[key]
	local inset: number = frame.Inset
	local box = make("Frame", merge({ Name = key, BackgroundTransparency = 1 }, props), parent)
	if fill then
		local panel = make("Frame", {
			Name = "Fill",
			Position = UDim2.fromOffset(inset, inset),
			Size = UDim2.new(1, -2 * inset, 1, -2 * inset),
			BackgroundColor3 = UiKit.colour(fill),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, box)
		make("UICorner", { CornerRadius = UDim.new(0, inset) }, panel)
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.95, 0.94, 0.92)),
		}, panel)
	end
	local body = make("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.new(1, -2 * inset, 1, -2 * inset),
		ZIndex = 2,
	}, box)
	make("ImageLabel", {
		Name = "Border",
		BackgroundTransparency = 1,
		Image = "rbxassetid://" .. tostring(frame.Id),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(frame.MinX, frame.MinY, frame.MaxX, frame.MaxY),
		SliceScale = frame.Scale,
		Size = FULL,
		ZIndex = 3,
	}, box)
	return box, body
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
	local wood = if group then group:FindFirstChild("Wood") else nil
	local fill = if wood then wood:FindFirstChild("Fill") else nil
	local body = if wood then wood:FindFirstChild("Body") else nil
	local label = if body then body:FindFirstChild("Label") else nil
	if fill and fill:IsA("Frame") then
		fill.BackgroundColor3 = UiKit.colour(styleFill[style] or "Cream")
	end
	if label and label:IsA("TextLabel") then
		label.TextColor3 = UiKit.colour(styleText[style] or "Brown")
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
	local _, body = UiKit.skin(group, "Wood", styleFill[style], { Size = FULL })
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
		UiKit.label(body, props.Text, props.TextSize or U.TextSmall, styleText[style], {
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

-- A small count chip for the resource strip: picture and number on a wooden plate.
function UiKit.chip(parent: Instance?, icon: string, text: string, order: number): Chip
	local box, body = UiKit.skin(parent, "Wood", "Card", {
		Name = icon,
		Size = UDim2.fromOffset(0, U.ChipHeight),
		LayoutOrder = order,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)
	UiKit.icon(body, icon, U.IconNormal, { LayoutOrder = 1 })
	local value = UiKit.label(body, text, U.TextSmall, "Brown", {
		Name = "Value",
		LayoutOrder = 2,
		Size = UDim2.new(1, -U.IconNormal - 4, 1, 0),
	})
	local function set(next: string)
		value.Text = next
		box.Size = UDim2.fromOffset(U.IconNormal + 24 + #next * 9, U.ChipHeight)
	end
	set(text)
	return { root = box, set = set }
end

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
	local track = make("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, lead, 0.5, 0),
		Size = UDim2.new(1, -lead, 0, U.BarHeight),
		BackgroundColor3 = UiKit.colour("Track"),
		BorderSizePixel = 0,
	}, row)
	make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
	local fill = make("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = UiKit.colour(colour),
		BorderSizePixel = 0,
	}, track)
	make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	local function set(fraction: number, low: boolean)
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		fill.BackgroundColor3 = UiKit.colour(if low then "Red" else colour)
	end
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
