--!strict
-- A slime's page in the book, drawn as the RPG character sheet of docs/ui/slime-sheet/concept.webp from the UI kit
-- (Config.Ui.Kit): the header (Back, the hexagon portrait, the name ribbon with the level pill), the slime on its pedestal
-- with its three gear slots round it (UiGearSlots), the need bars and Feed under it, and on the right the stats panel (each
-- stat's own value, and the gear's bonus as a green "+n" pill) with the trait scroll, Equip and, while it works, Stop work.
-- It is drawn on a fixed stage (Config.Ui.SlimeSheet) that is shrunk to fit a smaller screen. It reads the slime's attributes
-- the server publishes and asks through the book's `request` for Stop work (Unassign) and Feed (FeedDish, a dish from the
-- fridge); gear goes through UiGearSlots.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local UiFood = require(script.Parent.UiFood)
local UiGearSlots = require(script.Parent.UiGearSlots)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)
local UiSmithy = require(script.Parent.UiSmithy)

local U = Config.Ui
local K = U.SlimeSheet
local Kit = U.Kit

export type Sheet = { refresh: () -> () }

local UiSlimeSheet = {}

-- stat: the picture's name, the name on screen, the slime's attribute, the key of Gear.bonus
local statRows = {
	{ icon = "attack", name = "Attack", attribute = "Attack", key = "attack" },
	{ icon = "defence", name = "Defence", attribute = "Defence", key = "defence" },
	{ icon = "speed", name = "Speed", attribute = "Speed", key = "speed" },
	{ icon = "hp", name = "HP", attribute = "Hp", key = "hp" },
}
-- need: the picture, the name on screen, the attribute, the bar's colour, the level at or under which the bar goes red (or nil)
local needRows = {
	{ icon = "fullness", name = "Food", attribute = "Fullness", colour = "Fullness", low = Config.Needs.Hungry },
	{ icon = "energy", name = "Energy", attribute = "Energy", colour = "Energy", low = Config.Needs.Tired },
	{ icon = "fun", name = "Fun", attribute = "Fun", colour = "Fun", low = -1 },
}

-- A kit piece at a width, its height kept to its picture's shape.
local function piece(parent: Instance, name: string, width: number, props: UiKit.Props): ImageLabel
	local def = (Kit :: any)[name]
	props.Size = UDim2.fromOffset(width, width * def.Height / def.Width)
	return UiKit.kit(parent, name, props)
end

-- The header: Back, the hexagon portrait hanging over the frame, and the ribbon with the name and the level pill.
local function drawHeader(header: Frame, slime: Configuration, onBack: () -> ()): (TextLabel, TextLabel)
	local bar =
		UiKit.make("Frame", { Name = "Title", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, header)
	UiKit.button(bar, {
		Name = "Back",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		OnClick = onBack,
	})
	local portrait = Kit.portrait
	local hexWidth = K.HeaderPortrait * portrait.Width / portrait.Height
	local left = U.Touch + U.Gap
	-- the ribbon starts behind the hexagon and grows with the name
	local ribbon = UiKit.kit(bar, "ribbon", {
		Name = "Ribbon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, left + hexWidth * 0.5, 0.5, 0),
		Size = UDim2.fromOffset(0, K.RibbonHeight),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 1,
	})
	local tail = K.RibbonHeight * (Kit.ribbon.Width - Kit.ribbon.Slice[3]) / Kit.ribbon.Height
	UiKit.make("UIPadding", {
		-- (the hexagon and its leaves cover the ribbon's start)
		PaddingLeft = UDim.new(0, hexWidth * 0.46),
		PaddingRight = UDim.new(0, tail * 0.75),
	}, ribbon)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap * 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, ribbon)
	local nameLabel = UiKit.label(ribbon, "", U.TextHeader + 2, "Brown", {
		Name = "Name",
		LayoutOrder = 1,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 2,
	})
	UiKit.outline(nameLabel, true)
	local pill = UiKit.kit(ribbon, "level", {
		Name = "Level",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, K.LevelPillHeight),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 2,
	})
	UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, pill)
	local levelLabel = UiKit.label(pill, "", U.TextNormal, "Brown", {
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 3,
	})
	local hexagon = UiKit.kit(bar, "portrait", {
		Name = "Portrait",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, left, 0.5, 0),
		Size = UDim2.fromOffset(hexWidth, K.HeaderPortrait),
		ZIndex = 3,
	})
	local face = UiKit.make("Frame", {
		Name = "Face",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(K.HeaderFace, K.HeaderFace),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, hexagon)
	UiSlimes.acquire(slime, "ui", face)
	return nameLabel, levelLabel
end

-- The slime on its pedestal, the yellow strokes round the Head slot.
local function drawSlime(column: Frame, slime: Configuration, middle: number)
	piece(column, "pedestal", K.PedestalWidth, {
		Name = "Pedestal",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(middle, K.PedestalTop),
		ZIndex = 1,
	})
	for side, name in { [-1] = "accentLeft", [1] = "accentRight" } do
		UiKit.kit(column, name, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset(middle + side * K.AccentGap, K.AccentTop),
			Size = UDim2.fromOffset(K.AccentWidth, K.AccentHeight),
			ZIndex = 1,
		})
	end
	local holder = UiKit.make("Frame", {
		Name = "Slime",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(middle, K.SlimeTop),
		Size = UDim2.fromOffset(K.SlimeSize, K.SlimeSize),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, column)
	UiSlimes.acquire(slime, "sheet", holder)
end

-- The three need bars on the soft plate; returns what updates them.
local function drawNeeds(column: Frame, slime: Configuration): () -> ()
	local plate = UiKit.kit(column, "soft", {
		Name = "Needs",
		Position = UDim2.fromOffset(K.NeedsLeft, K.NeedsTop),
		Size = UDim2.fromOffset(K.NeedsWidth, K.NeedsHeight),
	})
	local pad = (K.NeedsHeight - 3 * K.NeedRow) / 2
	local barLeft = 10 + K.NeedIcon + 6 + K.NeedNameWidth
	local bars: { UiKit.Bar } = {}
	for index, row in needRows do
		local top = pad + (index - 1) * K.NeedRow
		UiKit.icon(plate, row.icon, K.NeedIcon, { Position = UDim2.fromOffset(10, top + (K.NeedRow - K.NeedIcon) / 2) })
		UiKit.label(plate, row.name, U.TextSmall, "Brown", {
			Position = UDim2.fromOffset(10 + K.NeedIcon + 6, top),
			Size = UDim2.fromOffset(K.NeedNameWidth, K.NeedRow),
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		bars[index] = UiKit.bar(plate, "", row.colour, {
			Position = UDim2.fromOffset(barLeft, top),
			Size = UDim2.new(1, -barLeft - 12, 0, K.NeedRow),
		})
	end
	return function()
		for index, row in needRows do
			local value = UiSlimes.number(slime, row.attribute)
			bars[index].set(value / Config.Needs.Max, value <= row.low)
		end
	end
end

-- The stats panel with its diamond, the four stat rows and the trait scroll; returns what updates them.
local function drawStats(stage: Frame, slime: Configuration, left: number, width: number): () -> ()
	local panel = UiKit.kit(stage, "panel", {
		Name = "Stats",
		Position = UDim2.fromOffset(left, K.PanelTop),
		Size = UDim2.fromOffset(width, K.PanelHeight),
	})
	UiKit.kit(panel, "diamond", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(K.DiamondSize, K.DiamondSize),
		ZIndex = 2,
	})
	local inset: number = Kit.panel.Inset
	local rowWidth = width - 2 * inset
	local values: { TextLabel } = {}
	local pills: { ImageLabel } = {}
	local bonusLabels: { TextLabel } = {}
	local valueLeft = rowWidth - 8 - K.BonusWidth - 6 - K.StatValueWidth
	for index, row in statRows do
		local line = UiKit.kit(panel, "row", {
			Name = row.name,
			Position = UDim2.fromOffset(inset, inset + K.RowsTop + (index - 1) * (K.StatRow + K.StatGap)),
			Size = UDim2.fromOffset(rowWidth, K.StatRow),
			ZIndex = 2,
		})
		UiKit.icon(line, row.icon, K.StatIcon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			ZIndex = 3,
		})
		UiKit.label(line, row.name, U.TextNormal + 2, "Brown", {
			Position = UDim2.fromOffset(6 + K.StatIcon + 8, 0),
			Size = UDim2.fromOffset(K.StatNameWidth, K.StatRow),
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 3,
		})
		values[index] = UiKit.label(line, "0", U.TextHeader + 2, "Brown", {
			Position = UDim2.fromOffset(valueLeft, 0),
			Size = UDim2.fromOffset(K.StatValueWidth, K.StatRow),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 3,
		})
		local pill = UiKit.kit(line, "bonus", {
			Name = "Bonus",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(K.BonusWidth, K.BonusHeight),
			Visible = false,
			ZIndex = 3,
		})
		pills[index] = pill
		bonusLabels[index] = UiKit.label(pill, "", U.TextNormal, "GreenDark", {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.None,
			ZIndex = 4,
		})
	end
	return function()
		local bonus = Gear.bonus({ gear = UiSmithy.decode(slime, "Gear") } :: any)
		for index, row in statRows do
			values[index].Text = tostring(UiSlimes.number(slime, row.attribute))
			local extra: number = (bonus :: any)[row.key] or 0
			pills[index].Visible = extra > 0
			bonusLabels[index].Text = "+" .. tostring(extra)
		end
	end
end

-- A round kit button with a picture and a word (Feed, Equip).
local function bigButton(stage: Frame, props: UiKit.Props): TextButton
	props.TextSize = U.TextHeader + 2
	props.IconSize = K.ButtonIcon
	return UiKit.button(stage, props)
end

-- Draws the page of `slime` into `host` (the book's content) and `header` (its top bar), both already empty.
function UiSlimeSheet.new(
	host: Frame,
	header: Frame,
	slime: Configuration,
	request: (data: { [string]: any }, onSuccess: () -> ()) -> (),
	onBack: () -> ()
): Sheet
	-- ===== the header (in a frame of its own: the book clears the header but keeps list layouts) =====
	local nameLabel, levelLabel = drawHeader(header, slime, onBack)

	-- ===== the stage, shrunk to the room there is =====
	local area = UiKit.make("Frame", { Name = "Area", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, host)
	local stage = UiKit.make("Frame", {
		Name = "Stage",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(K.DesignWidth, K.DesignHeight),
		BackgroundTransparency = 1,
	}, area) :: Frame
	local scale = UiKit.make("UIScale", nil, stage) :: UIScale
	local function fit()
		local room = UiKit.units(area)
		if room.X > 0 and room.Y > 0 then
			-- a wide screen would leave bands above and below: the book takes the sheet's height instead (an absolute
			-- target, so a stale size read only overshoots once and the next resize settles it)
			local wide = math.min(room.X / K.DesignWidth, K.ScaleMax)
			UiKit.setModalHeight(UiKit.modalHeight() - room.Y + K.DesignHeight * wide)
			scale.Scale = math.clamp(math.min(wide, room.Y / K.DesignHeight), 0.4, K.ScaleMax)
		end
	end
	area:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()

	-- ===== left column: the slime, its slots, its needs, Feed =====
	local middle = K.LeftWidth / 2
	local column = UiKit.make("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(K.LeftWidth, K.DesignHeight),
	}, stage) :: Frame
	drawSlime(column, slime, middle)
	local gear = UiGearSlots.new(column, slime)
	local updateNeeds = drawNeeds(column, slime)

	-- Feed: a short list of the dishes in the fridge over the button; a tap feeds one
	local village = if slime.Parent then slime.Parent.Parent else nil
	local dishes, dishesBody = UiKit.card(stage, {
		Name = "Dishes",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromOffset(0, K.ButtonTop - 4),
		Size = UDim2.fromOffset(K.PopoverWidth, 0),
		Visible = false,
		ZIndex = 12,
	})
	local dishList = UiKit.make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
	}, dishesBody) :: ScrollingFrame
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, dishList)
	UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 4) }, dishList)
	local function showDishes(open: boolean)
		UiKit.clear(dishList)
		dishes.Visible = open
		if not open then
			return
		end
		local _, fridge = UiFood.read(village)
		local ids: { string } = {}
		for id, count in fridge do
			if count >= 1 and (Config.Food.Dishes :: any)[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return (UiFood.describe(a)) < (UiFood.describe(b))
		end)
		for order, id in ids do
			local row = UiKit.make("TextButton", {
				Name = id,
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -8, 0, U.Gear.PickerRow),
				LayoutOrder = order,
			}, dishList)
			UiKit.kit(row, "row", { Size = UDim2.fromScale(1, 1) })
			UiFood.icon(row, id, U.Gear.PickerTile, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 6, 0.5, 0),
				ZIndex = 2,
			})
			local left = U.Gear.PickerTile + 12
			UiKit.label(row, (UiFood.describe(id)), U.TextSmall, "Brown", {
				Position = UDim2.fromOffset(left, 0),
				Size = UDim2.new(1, -left - 34, 1, 0),
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 2,
			})
			UiKit.label(row, "x" .. tostring(math.floor(fridge[id])), U.TextSmall, "BrownSoft", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(30, 20),
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 2,
			})
			row.Activated:Connect(function()
				request({ action = "FeedDish", slimeId = slime.Name, dish = id }, function()
					showDishes(false)
				end)
			end)
		end
		if #ids == 0 then
			UiKit.label(dishList, "No dishes yet. Cook them in the kitchen.", U.TextSmall, "BrownSoft", {
				Size = UDim2.new(1, -8, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.None,
			})
		end
		local rows = math.max(#ids, 1)
		local inset: number = Kit.square.Inset
		dishes.Size = UDim2.fromOffset(
			K.PopoverWidth,
			math.min(rows * (U.Gear.PickerRow + U.Gap) - U.Gap + 2 * inset + 4, K.PopoverMaxHeight, K.ButtonTop - 4)
		)
	end
	bigButton(stage, {
		Name = "Feed",
		Text = "Feed",
		Icon = "fullness",
		Style = "good",
		Position = UDim2.fromOffset(0, K.ButtonTop),
		Size = UDim2.fromOffset(K.FeedWidth, K.ButtonHeight),
		OnClick = function()
			gear.choose(nil)
			showDishes(not dishes.Visible)
		end,
	})

	-- ===== right column: the stats with the trait, Equip, Stop work =====
	local left = K.LeftWidth + K.ColumnGap
	local width = K.DesignWidth - left
	local updateStats = drawStats(stage, slime, left, width)
	local trait = UiKit.kit(stage, "scroll", {
		Name = "Trait",
		Position = UDim2.fromOffset(left - K.TraitOverhang, K.TraitTop),
		Size = UDim2.fromOffset(width + 2 * K.TraitOverhang, K.TraitHeight),
		ZIndex = 2,
	})
	local traitLabel = UiKit.label(trait, "", U.TextNormal + 2, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 3,
	})
	bigButton(stage, {
		Name = "Equip",
		Text = "Equip",
		Icon = "sword",
		Style = "special",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(K.DesignWidth, K.ButtonTop),
		Size = UDim2.fromOffset(K.EquipWidth, K.ButtonHeight),
		OnClick = function()
			showDishes(false)
			-- the first empty slot, or the weapon's when every slot holds a piece
			local worn = UiSmithy.decode(slime, "Gear")
			local slot = "hand"
			for _, each in Config.Smithy.Slots do
				if not Gear.get(worn[each]) then
					slot = each
					break
				end
			end
			gear.choose(slot)
		end,
	})
	local stop = UiKit.button(stage, {
		Name = "StopWork",
		Text = "Stop work",
		Style = "secondary",
		Position = UDim2.fromOffset(left, K.ButtonTop),
		Size = UDim2.fromOffset(K.StopWidth, K.ButtonHeight),
		OnClick = function()
			request({ action = "Unassign", slimeId = slime.Name }, function() end)
		end,
	})

	local function refresh()
		nameLabel.Text = UiSlimes.name(slime)
		levelLabel.Text = "Lv " .. tostring(UiSlimes.number(slime, "Level"))
		local kind = slime:GetAttribute("Trait")
		local hasTrait = type(kind) == "string" and kind ~= ""
		trait.Visible = hasTrait
		traitLabel.Text = if hasTrait
			then "Trait: " .. string.upper(string.sub(kind :: string, 1, 1)) .. string.sub(kind :: string, 2)
			else ""
		stop.Visible = UiSlimes.job(slime) ~= nil
		updateStats()
		updateNeeds()
		gear.refresh()
	end
	refresh()
	return { refresh = refresh }
end

return UiSlimeSheet
