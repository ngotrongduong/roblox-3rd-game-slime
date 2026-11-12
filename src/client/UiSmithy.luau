--!strict
-- The Blacksmith (docs/SMITHY.md §6): its prompt in the Market and the Smithy sheet. Tabs Weapon / Head / Charm (the Weapon tab
-- one weapon family at a time), a card for each piece of the tab (its picture on the rarity colour, name, the points it adds, how many wait in the bag, the materials as
-- picture and have/need, the coins, and Craft). It reads what the server publishes (the root's Materials, GearBag and Coins
-- attributes) and asks through Remotes.Village (SmithyCraft); the server decides and checks the distance, so a button it
-- would refuse is greyed. This file also lends the gear pictures, the stat tags and the reason texts to UiGearSlots (the
-- slime card's three slots).
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local Layout = require(ReplicatedStorage.Shared.Layout)
local UiDungeon = require(script.Parent.UiDungeon)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui
local G = U.Gear
local S = Config.Smithy
local D = Config.Dungeon

-- What UiSquad lends: its one-sheet opener, its invisible prompt holder, the player's village and its remote.
type Context = {
	open: (id: string, height: number, tick: () -> (), point: Vector3?, range: number) -> UiKit.Modal,
	anchor: (position: Vector3, name: string) -> Part,
	own: () -> Folder?,
	ask: (data: { [string]: any }) -> (boolean, string?, number?),
}
type View = { materials: { [string]: number }, bag: { [string]: number }, coins: number }

local UiSmithy = {}
local asking: ((data: { [string]: any }) -> (boolean, string?, number?))? = nil

local reasons: { [string]: string } = {
	RECIPE_NOT_FOUND = "Not available.",
	INSUFFICIENT_MATERIALS = "Missing materials.",
	INSUFFICIENT_COINS = "Not enough coins.",
	MISSING_SLIME = "Slime not found.",
	GEAR_NOT_FOUND = "Not available.",
	NOT_IN_BAG = "None left.",
	INVALID_SLOT = "Not available.",
	EMPTY_SLOT = "Nothing to take off.",
	OUT = "Not while it is out.",
	FAR = "Come closer to the Blacksmith.",
	RATE_LIMIT = "One moment.",
	NOT_READY = "Village is loading.",
	INVALID_ARGUMENT = "Not available.",
}
-- The four stats in the order tags show them, with their short names.
local statOrder = { { "attack", "ATK" }, { "defence", "DEF" }, { "speed", "SPD" }, { "hp", "HP" } }

function UiSmithy.reasonText(reason: any): string
	return if type(reason) == "string" and reasons[reason] then reasons[reason] else "Please try again."
end

-- One request to the server (yields: callers run it in task.spawn).
function UiSmithy.ask(data: { [string]: any }): (boolean, string?, number?)
	local send = asking
	if not send then
		return false, "NOT_READY", nil
	end
	return send(data)
end

-- A JSON attribute as a table (an empty one when it is missing or broken).
function UiSmithy.decode(instance: Instance?, name: string): { [string]: any }
	local text = if instance then instance:GetAttribute(name) else nil
	if type(text) ~= "string" or text == "" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(text)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

-- A JSON attribute { [id] = count } with only the positive whole counts.
function UiSmithy.counts(instance: Instance?, name: string): { [string]: number }
	local found: { [string]: number } = {}
	for id, amount in UiSmithy.decode(instance, name) do
		if type(id) == "string" and type(amount) == "number" and amount > 0 then
			found[id] = amount
		end
	end
	return found
end

-- The piece's rarity colour (screens only), a neutral parchment colour for an id that is none.
function UiSmithy.tierColour(gearId: string?): Color3
	local def: any = Gear.get(gearId)
	local tier: any = if def then (S.Tiers :: any)[def.tier] else nil
	return if tier then Color3.fromHex(tier.colour) else UiKit.colour("CardDeep")
end

-- A piece's picture: its `icon` (an asset id or a link) on the rarity colour; with no icon yet only the colour square shows.
-- An id that is none gives an empty parchment tile.
function UiSmithy.pieceTile(parent: Instance?, gearId: string?, size: number, props: UiKit.Props?): Frame
	local def: any = Gear.get(gearId)
	local base: UiKit.Props = {
		Name = "Tile",
		BackgroundColor3 = UiSmithy.tierColour(gearId),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
	}
	if props then
		for key, value in props do
			base[key] = value
		end
	end
	local tile = UiKit.make("Frame", base, parent)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, tile)
	UiKit.make("UIStroke", { Name = "Stroke", Color = UiKit.colour("Wood"), Thickness = 2 }, tile)
	local icon: any = if def then def.icon else nil
	local image: string? = nil
	if type(icon) == "number" and icon > 0 then
		image = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and icon ~= "" then
		image = icon
	end
	if image then
		UiKit.make("ImageLabel", {
			Name = "Picture",
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
		}, tile)
	end
	return tile
end

-- A row of small tags "+2 ATK" for the stats given (all four are looked at, zero ones are left out). `colour` names the
-- text colour in Config.Ui.Colours. The row is empty (and 0 wide) when nothing is given.
function UiSmithy.statRow(parent: Instance?, stats: { [string]: number }, colour: string, props: UiKit.Props?): Frame
	local base: UiKit.Props = {
		Name = "Stats",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, G.PillHeight),
	}
	if props then
		for key, value in props do
			base[key] = value
		end
	end
	local row = UiKit.make("Frame", base, parent)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	for index, item in statOrder do
		local points = stats[item[1]] or 0
		if points > 0 then
			local pill = UiKit.make("Frame", {
				Name = item[1],
				BackgroundColor3 = UiKit.colour("CardDeep"),
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(0, G.PillHeight),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = index,
			}, row)
			UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
			UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, pill)
			UiKit.label(pill, "+" .. tostring(points) .. " " .. item[2], U.TextTiny, colour, {
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.None,
			})
		end
	end
	return row
end

-- ===== The sheet =====

local function setButtonText(button: TextButton, text: string, size: number)
	local label = button:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
		label.TextSize = size
	end
end

-- One cost on a card: the material's picture and "have/need" (red when short).
local function costChip(row: Frame, item: string, order: number): TextLabel
	local chip = UiKit.make("Frame", {
		Name = item,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, G.CostIcon),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = order,
	}, row)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, chip)
	if item == "coins" then
		UiKit.icon(chip, "coins", G.CostIcon, { LayoutOrder = 1 })
	else
		UiDungeon.dropIcon(chip, item, G.CostIcon, { LayoutOrder = 1 })
	end
	return UiKit.label(chip, "", U.TextSmall, "Brown", {
		Name = "Value",
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
	})
end

-- The card of one piece, made once; returns the function that brings it up to date with what the player holds.
local function pieceCard(list: Instance, gearId: string, order: number, refresh: () -> ()): (View) -> ()
	local def: any = Gear.get(gearId)
	local recipe: any = (S.Recipes :: any)[gearId]
	local _, body = UiKit.card(list, {
		Name = gearId,
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, G.CardHeight),
	})
	-- the rarity colour runs down the card's edge
	local stripe = UiKit.make("Frame", {
		Name = "Rarity",
		BackgroundColor3 = UiSmithy.tierColour(gearId),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
	}, body)
	UiKit.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, stripe)
	local inner = UiKit.make("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -10, 1, 0),
	}, body)
	UiSmithy.pieceTile(inner, gearId, G.Tile)
	local textLeft = G.Tile + 8
	UiKit.label(inner, def.name, U.TextNormal, "Brown", {
		Position = UDim2.fromOffset(textLeft, 0),
		Size = UDim2.new(1, -textLeft - 44, 0, U.TextNormal + 8),
	})
	local count = UiKit.label(inner, "", U.TextNormal, "BrownSoft", {
		AnchorPoint = Vector2.new(1, 0),
		-- (in from the edge: the list's scroll bar covers the card's last pixels)
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.fromOffset(44, U.TextNormal + 8),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	UiSmithy.statRow(inner, def.stats, "Brown", {
		Position = UDim2.fromOffset(textLeft, U.TextNormal + 14),
		Size = UDim2.new(1, -textLeft, 0, G.PillHeight),
	})

	-- the costs in the drop order, then the coins
	local costs = UiKit.make("Frame", {
		Name = "Costs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, G.Tile + 6),
		Size = UDim2.new(1, 0, 0, G.CostIcon + 4),
	}, inner)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, costs)
	local values: { [string]: TextLabel } = {}
	for index, item in D.DropOrder do
		if recipe.materials[item] then
			values[item] = costChip(costs, item, index)
		end
	end
	local coinValue: TextLabel? = nil
	if recipe.coins > 0 then
		coinValue = costChip(costs, "coins", #D.DropOrder + 1)
	end

	local crafting = false
	local button = UiKit.button(inner, {
		Name = "Craft",
		Text = "Craft",
		Style = "good",
		TextSize = U.TextSmall,
		Position = UDim2.fromOffset(0, G.Tile + G.CostIcon + 14),
		Size = UDim2.new(1, 0, 0, U.Touch),
		OnClick = function()
			if crafting then
				return
			end
			crafting = true
			task.spawn(function()
				local ok, why = UiSmithy.ask({ action = "SmithyCraft", recipeId = gearId })
				crafting = false
				UiKit.toast(if ok then "Crafted " .. def.name .. "!" else UiSmithy.reasonText(why))
				refresh()
			end)
		end,
	})

	return function(view: View)
		local held = view.bag[gearId] or 0
		count.Text = if held > 0 then "x" .. tostring(held) else ""
		for item, label in values do
			local have, need = view.materials[item] or 0, recipe.materials[item]
			label.Text = tostring(math.min(have, 999)) .. "/" .. tostring(need)
			label.TextColor3 = UiKit.colour(if have < need then "Red" else "Brown")
		end
		if coinValue then
			coinValue.Text = UiKit.money(recipe.coins)
			coinValue.TextColor3 = UiKit.colour(if view.coins < recipe.coins then "Red" else "Brown")
		end
		-- (the same rule the server runs, on a farm-shaped table of what the attributes say)
		local ok, why = Gear.canCraft({ materials = view.materials, coins = view.coins } :: any, gearId)
		if ok then
			UiKit.setStyle(button, "good")
			setButtonText(button, "Craft", U.TextSmall)
		else
			UiKit.setStyle(button, "secondary")
			setButtonText(
				button,
				if why == "INSUFFICIENT_COINS" then "Not enough coins" else "Missing materials",
				U.TextSmall
			)
		end
		UiKit.setEnabled(button, ok and not crafting)
	end
end

local function openSheet(context: Context, point: Vector3)
	local tab: string = S.Slots[1]
	local updates: { (View) -> () } = {}
	local tick: () -> () = function() end
	local modal = context.open("smithy", G.SheetHeight, function()
		tick()
	end, point, Config.Market.SmithyRangeStuds * 1.3)

	-- header: the title and the purse
	local head = UiKit.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, modal.header)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, head)
	UiKit.label(head, "Smithy", U.TextHeader, "Brown", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(88, U.Touch),
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	UiKit.icon(head, "coins", U.Touch - 20, { LayoutOrder = 2 })
	local coins = UiKit.label(head, "", U.TextNormal, "Brown", {
		LayoutOrder = 3,
		Size = UDim2.fromOffset(110, U.Touch),
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	-- the three tabs, each a third of the width
	local tabs = UiKit.make("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, modal.content)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabs)
	local tabButtons: { [string]: TextButton } = {}
	-- The Weapon tab has one row more: a picture a weapon family (sword, shield, bow, ...; docs/WEAPONS.md §4), in the order
	-- its pieces come in GearOrder, each shown by its first piece; the list then holds that family's tiers only.
	local families: { { family: string, icon: string } } = {}
	for _, gearId in S.GearOrder do
		local def: any = Gear.get(gearId)
		if def and def.slot == "hand" and type(def.family) == "string" then
			local seen = false
			for _, entry in families do
				seen = seen or entry.family == def.family
			end
			if not seen then
				table.insert(families, { family = def.family, icon = def.icon or "" })
			end
		end
	end
	local family: string? = if families[1] then families[1].family else nil
	local familyRow = UiKit.make("Frame", {
		Name = "Families",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, U.Touch + U.Gap),
		Size = UDim2.new(1, 0, 0, U.Touch),
	}, modal.content)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, familyRow)
	local familyButtons: { [string]: TextButton } = {}
	local list = UiKit.make("ScrollingFrame", {
		Name = "Pieces",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, U.Touch + U.Gap),
		Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
	}, modal.content)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	local function build()
		UiKit.clear(list)
		updates = {}
		local filtered = tab == "hand" and family ~= nil
		familyRow.Visible = filtered
		local top = if filtered then 2 * (U.Touch + U.Gap) else U.Touch + U.Gap
		list.Position = UDim2.fromOffset(0, top)
		list.Size = UDim2.new(1, 0, 1, -top)
		local order = 0
		for _, gearId in S.GearOrder do
			local def: any = Gear.get(gearId)
			if def and def.slot == tab and (not filtered or def.family == family) then
				order += 1
				table.insert(
					updates,
					pieceCard(list, gearId, order, function()
						tick()
					end)
				)
			end
		end
		list.CanvasPosition = Vector2.zero
	end

	for index, slot in S.Slots do
		tabButtons[slot] = UiKit.button(tabs, {
			Name = slot,
			Text = (S.SlotNames :: any)[slot],
			Style = if slot == tab then "primary" else "secondary",
			Size = UDim2.new(1 / 3, -4, 1, 0),
			LayoutOrder = index,
			OnClick = function()
				tab = slot
				for id, button in tabButtons do
					UiKit.setStyle(button, if id == slot then "primary" else "secondary")
				end
				build()
				tick()
			end,
		})
	end

	for index, entry in families do
		local button = UiKit.button(familyRow, {
			Name = entry.family,
			Style = if entry.family == family then "primary" else "secondary",
			Size = UDim2.fromOffset(U.Touch, U.Touch),
			LayoutOrder = index,
			OnClick = function()
				family = entry.family
				for id, other in familyButtons do
					UiKit.setStyle(other, if id == entry.family then "primary" else "secondary")
				end
				build()
				tick()
			end,
		})
		familyButtons[entry.family] = button
		local body = button:FindFirstChild("Visual") and (button :: any).Visual:FindFirstChild("Body")
		UiKit.make("ImageLabel", {
			Name = "Picture",
			BackgroundTransparency = 1,
			Image = entry.icon,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(U.Touch - 12, U.Touch - 12),
			LayoutOrder = 1,
		}, body)
	end

	tick = function()
		local own = context.own()
		local money = if own then own:GetAttribute("Coins") else nil
		local view: View = {
			materials = UiSmithy.counts(own, "Materials"),
			bag = UiSmithy.counts(own, "GearBag"),
			coins = if type(money) == "number" then money else 0,
		}
		coins.Text = UiKit.money(view.coins)
		for _, update in updates do
			update(view)
		end
	end
	build()
	tick()
end

-- Called once by UiSquad: the Blacksmith's prompt, at its Config spot (it works with or without the model in the world).
function UiSmithy.start(context: Context)
	asking = context.ask
	local spot = Layout.marketPoint(Config.Market.Smithy)
	local anchor =
		context.anchor(Vector3.new(spot.X, Config.Map.GroundY + Config.Zombies.View.AnchorLift, spot.Z), "SmithyPrompt")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Smithy"
	prompt.ActionText = "Blacksmith"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.Market.SmithyRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function()
		openSheet(context, anchor.Position)
	end)
end

return UiSmithy
