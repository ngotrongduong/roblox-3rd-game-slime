--!strict
-- A slime's page in the book, drawn as an RPG character sheet (docs/ui/slime-sheet/concept.webp): the header (Back, its portrait,
-- name and level), the slime on a pedestal with its three gear slots round it (UiGearSlots) and its three needs under it, and
-- on the right the four stats (its own value, and the gear's bonus as a green "+n"), its trait and, while it works, Stop work.
-- It is drawn on a fixed stage (Config.Ui.SlimeSheet) that is shrunk to fit a smaller screen. It reads the slime's attributes
-- the server publishes and asks through the book's `request` only for Stop work (Unassign); gear goes through UiGearSlots.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local UiGearSlots = require(script.Parent.UiGearSlots)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)
local UiSmithy = require(script.Parent.UiSmithy)

local U = Config.Ui
local K = U.SlimeSheet

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

local function rounded(parent: Instance, props: UiKit.Props, radius: number): Frame
	local frame = UiKit.make("Frame", props, parent) :: Frame
	UiKit.make("UICorner", { CornerRadius = UDim.new(0, radius) }, frame)
	return frame
end

-- The slime on its pedestal: a wooden plinth with a lighter stone top, the portrait standing on it.
local function drawSlime(column: Frame, slime: Configuration, middle: number)
	local plinth = rounded(column, {
		Name = "Pedestal",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(middle, K.PedestalTop),
		Size = UDim2.fromOffset(K.PedestalWidth, K.PedestalHeight),
		BackgroundColor3 = UiKit.colour("Wood"),
		BorderSizePixel = 0,
		ZIndex = 1,
	}, K.PedestalHeight / 2)
	UiKit.make("UIStroke", { Color = UiKit.colour("Gold"), Thickness = 2 }, plinth)
	rounded(plinth, {
		Name = "Top",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.84, 0.62),
		BackgroundColor3 = UiKit.colour("CardDeep"),
		BorderSizePixel = 0,
	}, K.PedestalHeight / 3)
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

-- The three need bars on a plate under the pedestal; returns what updates them.
local function drawNeeds(column: Frame, slime: Configuration, middle: number): () -> ()
	local plate = rounded(column, {
		Name = "Needs",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(middle, K.NeedsTop),
		Size = UDim2.fromOffset(K.NeedsWidth, K.NeedsHeight),
		BackgroundColor3 = UiKit.colour("CardDeep"),
		BorderSizePixel = 0,
	}, 10)
	UiKit.make("UIStroke", { Color = UiKit.colour("Track"), Thickness = 2 }, plate)
	local pad = (K.NeedsHeight - 3 * K.NeedRow) / 2
	local barLeft = 8 + K.NeedIcon + 4 + K.NeedNameWidth
	local bars: { UiKit.Bar } = {}
	for index, row in needRows do
		local top = pad + (index - 1) * K.NeedRow
		UiKit.icon(plate, row.icon, K.NeedIcon, { Position = UDim2.fromOffset(8, top + (K.NeedRow - K.NeedIcon) / 2) })
		UiKit.label(plate, row.name, U.TextTiny, "Brown", {
			Position = UDim2.fromOffset(8 + K.NeedIcon + 4, top),
			Size = UDim2.fromOffset(K.NeedNameWidth, K.NeedRow),
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		bars[index] = UiKit.bar(plate, "", row.colour, {
			Position = UDim2.fromOffset(barLeft, top),
			Size = UDim2.new(1, -barLeft - 10, 0, K.NeedRow),
		})
	end
	return function()
		for index, row in needRows do
			local value = UiSlimes.number(slime, row.attribute)
			bars[index].set(value / Config.Needs.Max, value <= row.low)
		end
	end
end

-- The stats panel; returns what updates the values and the green bonus pills.
local function drawStats(stage: Frame, slime: Configuration, left: number, width: number): () -> ()
	local _, body = UiKit.card(stage, {
		Name = "Stats",
		Position = UDim2.fromOffset(left, 0),
		Size = UDim2.fromOffset(width, K.StatsHeight),
	})
	local inset: number = U.Frames.Wood.Inset
	local rowWidth = width - 2 * inset
	local top = (K.StatsHeight - 2 * inset - (4 * K.StatRow + 3 * K.StatGap)) / 2
	local values: { TextLabel } = {}
	local pills: { Frame } = {}
	local bonusLabels: { TextLabel } = {}
	local valueLeft = rowWidth - 6 - K.BonusWidth - 4 - K.StatValueWidth
	for index, row in statRows do
		local line = rounded(body, {
			Name = row.name,
			Position = UDim2.fromOffset(0, top + (index - 1) * (K.StatRow + K.StatGap)),
			Size = UDim2.fromOffset(rowWidth, K.StatRow),
			BackgroundColor3 = UiKit.colour("CardDeep"),
			BorderSizePixel = 0,
		}, 8)
		UiKit.icon(line, row.icon, K.StatIcon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 4, 0.5, 0),
		})
		UiKit.label(line, row.name, U.TextNormal, "Brown", {
			Position = UDim2.fromOffset(4 + K.StatIcon + 6, 0),
			Size = UDim2.fromOffset(K.StatNameWidth, K.StatRow),
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		values[index] = UiKit.label(line, "0", U.TextHeader, "Brown", {
			Position = UDim2.fromOffset(valueLeft, 0),
			Size = UDim2.fromOffset(K.StatValueWidth, K.StatRow),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		local pill = rounded(line, {
			Name = "Bonus",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(K.BonusWidth, K.StatRow - 8),
			BackgroundColor3 = UiKit.colour("Portrait"),
			BorderSizePixel = 0,
			Visible = false,
		}, (K.StatRow - 8) / 2)
		pills[index] = pill
		bonusLabels[index] = UiKit.label(pill, "", U.TextSmall, "GreenDark", {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.None,
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

-- Draws the page of `slime` into `host` (the book's content) and `header` (its top bar), both already empty.
function UiSlimeSheet.new(
	host: Frame,
	header: Frame,
	slime: Configuration,
	request: (data: { [string]: any }, onSuccess: () -> ()) -> (),
	onBack: () -> ()
): Sheet
	-- ===== the header (in a frame of its own: the book clears the header but keeps list layouts) =====
	local bar =
		UiKit.make("Frame", { Name = "Title", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, header)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, bar)
	UiKit.button(bar, {
		Name = "Back",
		Icon = "back",
		Style = "secondary",
		Size = UDim2.fromOffset(U.Touch, U.Touch),
		LayoutOrder = 1,
		OnClick = onBack,
	})
	local face, buildFace = UiSlimes.portrait(bar, slime, K.HeaderPortrait, nil)
	face.LayoutOrder = 2
	buildFace()
	local nameLabel = UiKit.label(bar, "", U.TextHeader, "Brown", {
		LayoutOrder = 3,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
	})
	local pill = rounded(bar, {
		Name = "Level",
		LayoutOrder = 4,
		Size = UDim2.fromOffset(0, K.LevelPillHeight),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = UiKit.colour("Cream"),
		BorderSizePixel = 0,
	}, K.LevelPillHeight / 2)
	UiKit.make("UIStroke", { Color = UiKit.colour("Gold"), Thickness = 2 }, pill)
	UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, pill)
	local levelLabel = UiKit.label(pill, "", U.TextNormal, "Brown", {
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
	})

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

	-- ===== left column: the slime, its slots, its needs =====
	local middle = K.LeftWidth / 2
	local column = UiKit.make("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(K.LeftWidth, K.DesignHeight),
	}, stage) :: Frame
	drawSlime(column, slime, middle)
	local gear = UiGearSlots.new(column, slime)
	local updateNeeds = drawNeeds(column, slime, middle)

	-- ===== right column: the stats, the trait, Stop work =====
	local left = K.LeftWidth + K.ColumnGap
	local width = K.DesignWidth - left
	local updateStats = drawStats(stage, slime, left, width)
	local traitPlate = rounded(stage, {
		Name = "Trait",
		Position = UDim2.fromOffset(left, K.TraitTop),
		Size = UDim2.fromOffset(width, K.TraitHeight),
		BackgroundColor3 = UiKit.colour("CardDeep"),
		BorderSizePixel = 0,
	}, 8)
	UiKit.make("UIStroke", { Color = UiKit.colour("Gold"), Thickness = 2 }, traitPlate)
	local traitLabel = UiKit.label(traitPlate, "", U.TextSmall, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local stop = UiKit.button(stage, {
		Name = "StopWork",
		Text = "Stop work",
		Style = "secondary",
		Position = UDim2.fromOffset(left, K.ButtonTop),
		Size = UDim2.fromOffset(width, U.Touch),
		OnClick = function()
			request({ action = "Unassign", slimeId = slime.Name }, function() end)
		end,
	})

	local function refresh()
		nameLabel.Text = UiSlimes.name(slime)
		levelLabel.Text = "Lv " .. tostring(UiSlimes.number(slime, "Level"))
		local trait = slime:GetAttribute("Trait")
		local hasTrait = type(trait) == "string" and trait ~= ""
		traitPlate.Visible = hasTrait
		traitLabel.Text = if hasTrait then "Trait: " .. (trait :: string) else ""
		stop.Visible = UiSlimes.job(slime) ~= nil
		updateStats()
		updateNeeds()
		gear.refresh()
	end
	refresh()
	return { refresh = refresh }
end

return UiSlimeSheet
