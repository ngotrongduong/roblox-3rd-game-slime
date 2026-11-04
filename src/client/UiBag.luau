--!strict
-- The Bag: what the player keeps, read-only, in a modal opened by its round edge button. Two tabs. Materials: a tile for each
-- material held (its picture, the count in the corner), in the drop order, coins and food left out (they are on the HUD).
-- Gear: the pieces grouped by slot (Weapon, Head, Charm), by tier inside a group; a piece counts the ones in the bag and the
-- ones slimes wear (a small slime badge says how many are worn). Tapping a tile opens a strip at the bottom: for a material the
-- pieces that need it, for a piece its points and how many are worn.
-- It reads the village folder's Materials and GearBag and each slime's Gear attribute; it asks the server for nothing.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local UiDungeon = require(script.Parent.UiDungeon)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)
local UiSmithy = require(script.Parent.UiSmithy)

local U = Config.Ui
local B = U.Bag
local G = U.Gear
local S = Config.Smithy
local D = Config.Dungeon

export type Context = { own: () -> Folder? }

type View = {
	materials: { [string]: number },
	bag: { [string]: number },
	worn: { [string]: number },
}

local UiBag = {}
local ctx: Context? = nil
local tab = "materials"
local selected: string? = nil
local scroll: ScrollingFrame? = nil
local strip: Frame? = nil
local stripBody: Frame? = nil
local drawnKey = ""

-- What the player holds: materials, the gear in the bag, and how many of each piece slimes wear.
local function look(): View
	local own = if ctx then ctx.own() else nil
	local worn: { [string]: number } = {}
	for _, slime in UiSlimes.slimes(own) do
		local wearing = UiSmithy.decode(slime, "Gear")
		for _, slot in S.Slots do
			local id = wearing[slot]
			local def: any = Gear.get(id)
			if def and def.slot == slot then
				worn[id] = (worn[id] or 0) + 1
			end
		end
	end
	return {
		materials = UiSmithy.counts(own, "Materials"),
		bag = UiSmithy.counts(own, "GearBag"),
		worn = worn,
	}
end

local function keyOf(view: View): string
	local parts: { string } = { tab, tostring(selected) }
	for _, item in D.DropOrder do
		table.insert(parts, item .. "=" .. tostring(view.materials[item] or 0))
	end
	for _, id in S.GearOrder do
		table.insert(parts, id .. "=" .. tostring(view.bag[id] or 0) .. "/" .. tostring(view.worn[id] or 0))
	end
	return table.concat(parts, ",")
end

-- The materials held, in the drop order (coins and food are not kept in the bag).
local function materialList(view: View): { string }
	local found: { string } = {}
	for _, item in D.DropOrder do
		local entry: any = (D.Materials :: any)[item]
		if entry and entry.kind == "material" and (view.materials[item] or 0) > 0 then
			table.insert(found, item)
		end
	end
	return found
end

-- The pieces of a slot held (in the bag or worn), weakest tier first.
local function pieceList(view: View, slot: string): { string }
	local found: { string } = {}
	for _, id in S.GearOrder do
		local def: any = Gear.get(id)
		if def and def.slot == slot and (view.bag[id] or 0) + (view.worn[id] or 0) > 0 then
			table.insert(found, id)
		end
	end
	return found
end

local function rounded(parent: Instance, props: UiKit.Props, radius: UDim): Frame
	local frame = UiKit.make("Frame", props, parent) :: Frame
	UiKit.make("UICorner", { CornerRadius = radius }, frame)
	return frame
end

-- A small cream plate with a short text, for a count in a tile's corner.
local function chip(parent: Instance, text: string, props: UiKit.Props): Frame
	local plate = rounded(parent, {
		Name = "Chip",
		Size = UDim2.fromOffset(0, B.WornIcon + 2),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = UiKit.colour("Cream"),
		BorderSizePixel = 0,
		ZIndex = 5,
	}, UDim.new(0.5, 0))
	for key, value in props do
		(plate :: any)[key] = value
	end
	UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, plate)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, plate)
	UiKit.label(plate, text, U.TextTiny, "Brown", {
		Name = "Text",
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		ZIndex = 6,
	})
	return plate
end

-- A wrapping row of tiles.
local function wrapRow(parent: Instance, name: string, order: number): Frame
	local row = UiKit.make("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	}, parent)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Wraps = true,
		Padding = UDim.new(0, B.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	return row
end

local function tileButton(parent: Instance, name: string, order: number, onTap: () -> ()): TextButton
	local button = UiKit.make("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(B.Tile, B.Tile),
		LayoutOrder = order,
	}, parent) :: TextButton
	button.Activated:Connect(onTap)
	return button
end

local render: () -> ()

local function choose(id: string)
	selected = if selected == id then nil else id
	render()
end

local function materialTile(parent: Instance, item: string, count: number, order: number)
	local button = tileButton(parent, item, order, function()
		choose(item)
	end)
	local box, body = UiKit.card(button, { Size = UDim2.fromScale(1, 1) })
	if selected == item then
		UiKit.make("UIStroke", { Color = UiKit.colour("Gold"), Thickness = 3 }, box:FindFirstChild("Fill"))
	end
	UiDungeon.dropIcon(body, item, B.MaterialIcon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	chip(button, UiKit.money(count), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2) })
end

local function pieceButton(parent: Instance, id: string, view: View, order: number)
	local button = tileButton(parent, id, order, function()
		choose(id)
	end)
	local tile = UiSmithy.pieceTile(button, id, B.Tile)
	if selected == id then
		local stroke = tile:FindFirstChild("Stroke")
		if stroke and stroke:IsA("UIStroke") then
			stroke.Color = UiKit.colour("Gold")
			stroke.Thickness = 4
		end
	end
	local total = (view.bag[id] or 0) + (view.worn[id] or 0)
	chip(button, "x" .. tostring(total), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2) })
	local worn = view.worn[id] or 0
	if worn > 0 then
		local badge = chip(button, tostring(worn), { Name = "Worn", Position = UDim2.fromOffset(2, 2) })
		UiKit.icon(badge, "slimes", B.WornIcon, { LayoutOrder = 1 })
	end
end

local function emptyLine(parent: Instance, text: string)
	UiKit.label(parent, text, U.TextNormal, "BrownSoft", {
		Name = "Empty",
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
	})
end

local function drawGrid(host: ScrollingFrame, view: View)
	UiKit.clear(host)
	if tab == "materials" then
		local items = materialList(view)
		if #items == 0 then
			emptyLine(host, "Nothing yet. Monsters in the Dungeon drop materials.")
			return
		end
		local row = wrapRow(host, "Materials", 1)
		for index, item in items do
			materialTile(row, item, view.materials[item], index)
		end
		for index = #items + 1, B.MaterialSlots do
			local slot = UiKit.make("Frame", {
				Name = "EmptySlot",
				BackgroundColor3 = UiKit.colour("BrownSoft"),
				BackgroundTransparency = 0.88,
				Size = UDim2.fromOffset(B.Tile, B.Tile),
				LayoutOrder = index,
			}, row)
			UiKit.make("UICorner", { CornerRadius = UDim.new(0, 8) }, slot)
			UiKit.make("UIStroke", { Color = UiKit.colour("BrownSoft"), Transparency = 0.6, Thickness = 2 }, slot)
		end
		return
	end
	local order = 0
	for _, slot in S.Slots do
		local pieces = pieceList(view, slot)
		if #pieces > 0 then
			order += 1
			UiKit.label(host, (S.SlotNames :: any)[slot], U.TextNormal, "Brown", {
				Name = slot .. "Header",
				Size = UDim2.new(1, -8, 0, B.HeaderHeight),
				LayoutOrder = order,
			})
			order += 1
			local row = wrapRow(host, slot, order)
			for index, id in pieces do
				pieceButton(row, id, view, index)
			end
		end
	end
	if order == 0 then
		emptyLine(host, "Nothing yet. Craft gear at the Blacksmith in the Market.")
	end
end

-- One line of the details strip: a row that lays its parts left to right.
local function line(parent: Instance, y: number, height: number): Frame
	local row = UiKit.make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, height),
	}, parent)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	return row
end

local function autoLabel(parent: Instance, text: string, size: number, colour: string, order: number): TextLabel
	return UiKit.label(parent, text, size, colour, {
		LayoutOrder = order,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
end

-- The strip: a material's name and the pieces that need it; a piece's name, rarity, points and how many are worn.
local function drawDetail(body: Frame, view: View, id: string)
	UiKit.clear(body)
	local pictureSize = B.DetailHeight - 2 * (U.Frames.Wood.Inset + 2)
	local left = pictureSize + 8
	local text = UiKit.make("Frame", {
		Name = "Text",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(left, 0),
		Size = UDim2.new(1, -left, 1, 0),
	}, body)
	local top = line(text, 0, U.TextNormal + 6)
	local second = line(text, U.TextNormal + 6, B.NeedTile)
	if tab == "materials" then
		local entry: any = (D.Materials :: any)[id]
		UiDungeon.dropIcon(
			body,
			id,
			pictureSize,
			{ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) }
		)
		autoLabel(top, if entry then entry.name else id, U.TextNormal, "Brown", 1)
		local used = 0
		for _, gearId in S.GearOrder do
			local need = (S.Recipes :: any)[gearId].materials[id]
			if need then
				used += 1
				local cell = UiKit.make("Frame", {
					Name = gearId,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(0, B.NeedTile),
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = used,
				}, second)
				UiKit.make("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, cell)
				UiSmithy.pieceTile(cell, gearId, B.NeedTile, { LayoutOrder = 1 })
				autoLabel(cell, "x" .. tostring(need), U.TextTiny, "BrownSoft", 2)
			end
		end
		if used == 0 then
			autoLabel(second, "Not used by any gear yet.", U.TextSmall, "BrownSoft", 1)
		end
		return
	end
	local def: any = Gear.get(id)
	if not def then
		return
	end
	UiSmithy.pieceTile(body, id, pictureSize, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5) })
	autoLabel(top, def.name, U.TextNormal, "Brown", 1)
	local tier: any = (S.Tiers :: any)[def.tier]
	local rarity = autoLabel(top, if tier then tier.rarity else "", U.TextSmall, "BrownSoft", 2)
	if tier then
		rarity.TextColor3 = Color3.fromHex(tier.colour)
	end
	UiSmithy.statRow(second, def.stats, "Brown", {
		Size = UDim2.fromOffset(0, G.PillHeight),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
	})
	local worn = view.worn[id] or 0
	if worn > 0 then
		local wornRow = UiKit.make("Frame", {
			Name = "Worn",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, B.NeedTile),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 2,
		}, second)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, wornRow)
		UiKit.icon(wornRow, "slimes", U.IconSmall, { LayoutOrder = 1 })
		autoLabel(wornRow, "x" .. tostring(worn) .. " worn", U.TextSmall, "BrownSoft", 2)
	end
end

render = function()
	local list, box, body = scroll, strip, stripBody
	if not (list and box and body) then
		return
	end
	local view = look()
	-- a choice that is gone (the last one used up, or the other tab) clears
	local pick = selected
	if pick then
		local held = if tab == "materials"
			then view.materials[pick] or 0
			else (view.bag[pick] or 0) + (view.worn[pick] or 0)
		if held <= 0 then
			selected = nil
			pick = nil
		end
	end
	drawnKey = keyOf(view)
	drawGrid(list, view)
	box.Visible = pick ~= nil
	list.Size = if pick then UDim2.new(1, 0, 1, -B.DetailHeight - U.Gap) else UDim2.fromScale(1, 1)
	if pick then
		drawDetail(body, view, pick)
	end
end

-- Called when what the player holds changes: redraws in place, keeping the scroll.
function UiBag.refresh()
	if UiKit.modalId() ~= "bag" or not scroll then
		return
	end
	if keyOf(look()) ~= drawnKey then
		render()
	end
end

function UiBag.isOpen(): boolean
	return UiKit.modalId() == "bag"
end

function UiBag.open(context: Context)
	if UiBag.isOpen() then
		UiKit.closeModal()
		return
	end
	ctx = context
	selected = nil
	drawnKey = ""
	local modal = UiKit.openModal("bag", {
		Width = B.Width,
		Height = B.Height,
		OnClose = function()
			scroll, strip, stripBody = nil, nil, nil
			selected = nil
		end,
	})
	local labels: { [string]: string } = { materials = "Materials", gear = "Gear" }
	UiKit.segmented(
		modal.header,
		{ { id = "materials", text = labels.materials }, { id = "gear", text = labels.gear } },
		tab,
		function(id)
			tab = id
			selected = nil
			if scroll then
				scroll.CanvasPosition = Vector2.zero
			end
			render()
		end,
		{ Name = "Tabs", ItemWidth = 128, Size = UDim2.fromOffset(2 * 128 + U.Gap, U.Touch) }
	)
	local list = UiKit.make("ScrollingFrame", {
		Name = "Items",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
	}, modal.content) :: ScrollingFrame
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	local box, body = UiKit.card(modal.content, {
		Name = "Details",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, B.DetailHeight),
		Visible = false,
	})
	scroll, strip, stripBody = list, box, body
	render()
end

return UiBag
