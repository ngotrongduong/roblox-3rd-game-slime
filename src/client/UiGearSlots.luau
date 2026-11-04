--!strict
-- The three gear slots of a slime (Hand, Head, Tail) on its card in the slime book: each shows the piece it wears (or an empty
-- slot); tapping one opens a short list of the pieces of that slot waiting in the bag, and "Take off" when one is worn.
-- Under the slots, the points all its gear adds. It reads the slime's `Gear` attribute and the root's `GearBag`, asks through
-- UiSmithy.ask (GearEquip, GearUnequip); the server decides, so a refusal only shows a short line.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local UiKit = require(script.Parent.UiKit)
local UiSmithy = require(script.Parent.UiSmithy)

local U = Config.Ui
local G = U.Gear
local S = Config.Smithy

export type Slots = { root: ScrollingFrame, refresh: () -> () }

type Cell = { button: TextButton, tile: Frame, name: TextLabel, shown: string }

local UiGearSlots = {}

-- The piece id worn in a slot, nil when empty or when the id is not a piece of that slot.
local function wornIn(worn: { [string]: any }, slot: string): string?
	local id = worn[slot]
	local def: any = Gear.get(id)
	return if def and def.slot == slot then id else nil
end

-- A slime's gear row. `parent` takes a scrolling frame placed by `props` (Position, Size).
function UiGearSlots.new(parent: Instance, slime: Configuration, props: UiKit.Props?): Slots
	local root = UiKit.make("ScrollingFrame", {
		Name = "GearSlots",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
	}, parent) :: ScrollingFrame
	if props then
		for key, value in props do
			(root :: any)[key] = value
		end
	end
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, root)

	local selected: string? = nil
	local busy = false
	local pickerKey = ""
	local bonusKey = ""
	local refresh: () -> () = function() end

	-- the three slots
	local row = UiKit.make("Frame", {
		Name = "Slots",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, G.Slot + 22),
		LayoutOrder = 1,
	}, root)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local cells: { [string]: Cell } = {}
	for index, slot in S.Slots do
		local button = UiKit.make("TextButton", {
			Name = slot,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(G.SlotCell, G.Slot + 22),
			LayoutOrder = index,
		}, row)
		local tile = UiSmithy.pieceTile(button, nil, G.Slot, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
		})
		local name = UiKit.label(button, "", U.TextTiny, "Brown", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		cells[slot] = { button = button, tile = tile, name = name, shown = "?" }
		button.Activated:Connect(function()
			selected = if selected == slot then nil else slot
			refresh()
		end)
	end

	-- the points all the worn gear adds
	local bonus = UiKit.make("Frame", {
		Name = "Bonus",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, G.PillHeight),
		LayoutOrder = 2,
		Visible = false,
	}, root)

	-- the picker of the chosen slot
	local picker = UiKit.make("Frame", {
		Name = "Picker",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
	}, root)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, picker)

	-- A request from the picker: on success the picker closes; the attribute change brings the slots up to date.
	local function send(data: { [string]: any })
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			local ok, why = UiSmithy.ask(data)
			busy = false
			if ok then
				selected = nil
			else
				UiKit.toast(UiSmithy.reasonText(why))
			end
			refresh()
		end)
	end

	local function pickerRow(host: Instance, order: number, onTap: () -> ()): (TextButton, Frame)
		local button = UiKit.make("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, G.PickerRow),
			LayoutOrder = order,
		}, host)
		local _, body = UiKit.card(button, { Size = UDim2.fromScale(1, 1) })
		button.Activated:Connect(onTap)
		return button, body
	end

	local function drawPicker(slot: string?, wornId: string?, bag: { [string]: number })
		UiKit.clear(picker)
		if not slot then
			return
		end
		local order = 0
		if wornId then
			order += 1
			UiKit.button(picker, {
				Name = "TakeOff",
				Text = "Take off",
				Style = "secondary",
				Size = UDim2.new(1, 0, 0, U.Touch),
				LayoutOrder = order,
				OnClick = function()
					send({ action = "GearUnequip", slimeId = slime.Name, slot = slot })
				end,
			})
		end
		for _, gearId in S.GearOrder do
			local def: any = Gear.get(gearId)
			local held = bag[gearId] or 0
			if def and def.slot == slot and held > 0 then
				order += 1
				local _, body = pickerRow(picker, order, function()
					send({ action = "GearEquip", slimeId = slime.Name, gearId = gearId })
				end)
				UiSmithy.pieceTile(body, gearId, G.PickerTile, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
				})
				local left = G.PickerTile + 8
				UiKit.label(body, def.name, U.TextSmall, "Brown", {
					Position = UDim2.fromOffset(left, 0),
					Size = UDim2.new(1, -left - 40, 0, 18),
				})
				local points: { string } = {}
				for _, item in { { "attack", "ATK" }, { "defence", "DEF" }, { "speed", "SPD" }, { "hp", "HP" } } do
					local value = def.stats[item[1]]
					if value then
						table.insert(points, "+" .. tostring(value) .. " " .. item[2])
					end
				end
				UiKit.label(body, table.concat(points, "  "), U.TextTiny, "BrownSoft", {
					Position = UDim2.fromOffset(left, 18),
					Size = UDim2.new(1, -left - 40, 0, 18),
				})
				UiKit.label(body, "x" .. tostring(held), U.TextSmall, "BrownSoft", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(40, 20),
					TextXAlignment = Enum.TextXAlignment.Right,
				})
			end
		end
		if order == 0 then
			UiKit.label(picker, "Nothing for this slot", U.TextSmall, "BrownSoft", {
				Size = UDim2.new(1, 0, 0, U.TextSmall + 10),
			})
		end
	end

	refresh = function()
		local worn = UiSmithy.decode(slime, "Gear")
		local village = if slime.Parent then slime.Parent.Parent else nil
		local bag = UiSmithy.counts(village, "GearBag")
		for _, slot in S.Slots do
			local cell = cells[slot]
			local id = wornIn(worn, slot)
			local key = id or ""
			if cell.shown ~= key then
				cell.shown = key
				local old = cell.tile
				cell.tile = UiSmithy.pieceTile(cell.button, id, G.Slot, {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0),
				})
				old:Destroy()
				if not id then
					UiKit.label(cell.tile, (S.SlotNames :: any)[slot], U.TextTiny, "BrownSoft", {
						Size = UDim2.fromScale(1, 1),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextTruncate = Enum.TextTruncate.None,
					})
				end
				local def: any = Gear.get(id)
				cell.name.Text = if def then def.name else ""
			end
			local stroke = cell.tile:FindFirstChild("Stroke")
			if stroke and stroke:IsA("UIStroke") then
				local chosen = selected == slot
				stroke.Color = UiKit.colour(if chosen then "Gold" else "Wood")
				stroke.Thickness = if chosen then 4 else 2
			end
		end

		-- the total the worn gear adds
		local total = Gear.bonus({ gear = worn } :: any)
		local nextBonus = table.concat({ total.attack, total.defence, total.speed, total.hp }, ",")
		if nextBonus ~= bonusKey then
			bonusKey = nextBonus
			UiKit.clear(bonus)
			UiSmithy.statRow(bonus, total, "GreenDark")
			bonus.Visible = total.attack + total.defence + total.speed + total.hp > 0
		end

		-- the picker, redrawn only when what it lists changed
		local slot = selected
		local wornId = if slot then wornIn(worn, slot) else nil
		local parts: { string } = { slot or "-", wornId or "-" }
		if slot then
			for _, gearId in S.GearOrder do
				local def: any = Gear.get(gearId)
				if def and def.slot == slot and (bag[gearId] or 0) > 0 then
					table.insert(parts, gearId .. "=" .. tostring(bag[gearId]))
				end
			end
		end
		local nextKey = table.concat(parts, "|")
		if nextKey ~= pickerKey then
			pickerKey = nextKey
			drawPicker(slot, wornId, bag)
		end
	end
	refresh()
	return { root = root, refresh = refresh }
end

return UiGearSlots
