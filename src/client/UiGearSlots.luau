--!strict
-- The three gear slots of a slime's page in the book (UiSlimeSheet): Head above the slime, Weapon (the Hand slot) on its left and
-- Charm (the Tail slot) on its right. Each is a framed square under a small name plate; empty it shows the faint picture of its
-- kind, worn it shows the piece. Tapping one opens a short list beside it of the pieces of that slot waiting in the bag, and
-- "Take off" when one is worn; tapping outside the list closes it.
-- It reads the slime's `Gear` attribute and the root's `GearBag`, asks through UiSmithy.ask (GearEquip, GearUnequip); the server
-- decides, so a refusal only shows a short line. The points the gear adds are shown by the stats panel, not here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local UiKit = require(script.Parent.UiKit)
local UiSmithy = require(script.Parent.UiSmithy)

local U = Config.Ui
local G = U.Gear
local K = U.SlimeSheet
local S = Config.Smithy

-- choose: opens the list of a slot (nil closes it), as a tap on the slot does
export type Slots = { refresh: () -> (), choose: (slot: string?) -> () }

type Cell = { body: Frame, frame: ImageLabel, shown: string }

local UiGearSlots = {}

-- The faint picture of an empty slot, by slot.
local emptyIcons: { [string]: string } = { hand = "slotWeapon", head = "slotHead", tail = "slotCharm" }
local FADE = 0.55
local CELL_HEIGHT = K.PlateHeight + K.SlotHeight - K.PlateOverlap
local INSET: number = U.Kit.square.Inset
-- the slot frame's cream inside, as fractions of its picture (Config.Ui.Kit.slot: a wooden top band, thinner sides)
local INSIDE_LEFT, INSIDE_TOP, INSIDE_RIGHT, INSIDE_BOTTOM = 0.11, 0.22, 0.89, 0.91
local PICKED = Color3.fromRGB(255, 215, 120)
local STAT_TAGS = { { "attack", "ATK" }, { "defence", "DEF" }, { "speed", "SPD" }, { "hp", "HP" } }

-- The piece id worn in a slot, nil when empty or when the id is not a piece of that slot.
local function wornIn(worn: { [string]: any }, slot: string): string?
	local id = worn[slot]
	local def: any = Gear.get(id)
	return if def and def.slot == slot then id else nil
end

-- One slot: a button holding the framed square and, over its top edge, the name plate.
local function buildCell(parent: Instance, slot: string, centreX: number, top: number, onTap: () -> ()): Cell
	local button = UiKit.make("TextButton", {
		Name = slot,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(centreX, top),
		Size = UDim2.fromOffset(K.PlateWidth, CELL_HEIGHT),
		ZIndex = 3,
	}, parent)
	local frame = UiKit.kit(button, "slot", {
		Name = "Frame",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, K.PlateHeight - K.PlateOverlap),
		Size = UDim2.fromOffset(K.Slot, K.SlotHeight),
		ZIndex = 1,
	})
	local body = UiKit.make("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(INSIDE_LEFT, INSIDE_TOP),
		Size = UDim2.fromScale(INSIDE_RIGHT - INSIDE_LEFT, INSIDE_BOTTOM - INSIDE_TOP),
		ZIndex = 2,
	}, frame)
	local plate = UiKit.kit(button, "plate", {
		Name = "Plate",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(K.PlateWidth, K.PlateHeight),
		ZIndex = 3,
	})
	local name = UiKit.label(plate, (S.SlotNames :: any)[slot], U.TextSmall, "Brown", {
		Size = UDim2.new(1, 0, 1, -2),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 4,
	})
	UiKit.outline(name, true)
	button.Activated:Connect(onTap)
	return { body = body, frame = frame, shown = "?" }
end

-- A slime's three slots, drawn into `stage` (the sheet's left column, LeftWidth wide).
function UiGearSlots.new(stage: Instance, slime: Configuration): Slots
	local selected: string? = nil
	local busy = false
	local pickerKey = ""
	local refresh: () -> () = function() end

	local middle = K.LeftWidth / 2
	local cells: { [string]: Cell } = {}
	local layout = {
		head = { middle, 0 },
		hand = { middle - K.SideOffset, K.SideTop },
		tail = { middle + K.SideOffset, K.SideTop },
	}

	-- a tap outside the list closes it (under the slots, so another slot can still be tapped)
	local backdrop = UiKit.make("TextButton", {
		Name = "Backdrop",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 2,
	}, stage)
	backdrop.Activated:Connect(function()
		selected = nil
		refresh()
	end)

	for _, slot in S.Slots do
		local spot = layout[slot]
		cells[slot] = buildCell(stage, slot, spot[1], spot[2], function()
			selected = if selected == slot then nil else slot
			refresh()
		end)
	end

	-- the list of the chosen slot
	local popover, popoverBody = UiKit.card(stage, {
		Name = "Picker",
		AnchorPoint = Vector2.new(0.5, 0),
		Visible = false,
		ZIndex = 12,
	})
	local scroll = UiKit.make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
	}, popoverBody) :: ScrollingFrame
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, scroll)

	-- A request from the list: on success it closes; the attribute change brings the slots up to date.
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

	local function drawPicker(slot: string?, wornId: string?, bag: { [string]: number })
		UiKit.clear(scroll)
		popover.Visible = slot ~= nil
		if not slot then
			return
		end
		local order = 0
		if wornId then
			order += 1
			UiKit.button(scroll, {
				Name = "TakeOff",
				Text = "Take off",
				Style = "secondary",
				Size = UDim2.new(1, -8, 0, U.Touch),
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
				local row = UiKit.make("TextButton", {
					Name = gearId,
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, G.PickerRow),
					LayoutOrder = order,
				}, scroll)
				UiKit.kit(row, "row", { Size = UDim2.fromScale(1, 1), ZIndex = 0 })
				row.Activated:Connect(function()
					send({ action = "GearEquip", slimeId = slime.Name, gearId = gearId })
				end)
				UiSmithy.pieceTile(row, gearId, G.PickerTile, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 6, 0.5, 0),
				})
				local left = G.PickerTile + 12
				UiKit.label(row, def.name, U.TextSmall, "Brown", {
					Position = UDim2.fromOffset(left, 4),
					Size = UDim2.new(1, -left - 34, 0, 20),
				})
				local points: { string } = {}
				for _, item in STAT_TAGS do
					local value = def.stats[item[1]]
					if value then
						table.insert(points, "+" .. tostring(value) .. " " .. item[2])
					end
				end
				UiKit.label(row, table.concat(points, " "), U.TextTiny, "BrownSoft", {
					Position = UDim2.fromOffset(left, 24),
					Size = UDim2.new(1, -left - 34, 0, 18),
				})
				UiKit.label(row, "x" .. tostring(held), U.TextSmall, "BrownSoft", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					Size = UDim2.fromOffset(30, 20),
					TextXAlignment = Enum.TextXAlignment.Right,
				})
			end
		end
		if order == 0 then
			UiKit.label(scroll, "Nothing for this slot", U.TextSmall, "BrownSoft", {
				Size = UDim2.new(1, -8, 0, U.TextSmall + 10),
				TextWrapped = true,
			})
			order = 1
		end
		-- sized to its rows, never taller than the stage under its slot
		local top = if slot == "head" then CELL_HEIGHT + 4 else 0
		local height = order * (G.PickerRow + U.Gap) - U.Gap + 2 * INSET + 4
		popover.Position = UDim2.fromOffset(middle, top)
		popover.Size = UDim2.fromOffset(K.PopoverWidth, math.min(height, K.PopoverMaxHeight, K.DesignHeight - top))
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
				UiKit.clear(cell.body)
				local inner = math.floor(K.Slot * (INSIDE_RIGHT - INSIDE_LEFT)) - 2
				if id then
					UiSmithy.pieceTile(cell.body, id, inner, {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
					})
				else
					local icon = UiKit.icon(cell.body, emptyIcons[slot], inner - 6, {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
					})
					if icon:IsA("ImageLabel") then
						icon.ImageTransparency = FADE
					elseif icon:IsA("TextLabel") then
						icon.TextTransparency = FADE
					end
				end
			end
			cell.frame.ImageColor3 = if selected == slot then PICKED else Color3.new(1, 1, 1)
		end
		backdrop.Visible = selected ~= nil

		-- the list, redrawn only when what it shows changed
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
	return {
		refresh = refresh,
		choose = function(slot: string?)
			selected = slot
			refresh()
		end,
	}
end

return UiGearSlots
