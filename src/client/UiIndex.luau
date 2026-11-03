--!strict
-- The Index (docs/GAMEPLAY.md §13): every kind of slime as a card, in four tabs (the 11 colours, the Duals, the Secrets, the
-- materials), lit when the player has found it and a dark shadow of the 3D body when not. Drawn inside the slime book
-- (UiBook); what was found comes from the village folder's Found attribute (server/Rewards). Secrets have no art of their
-- own yet: a found Secret stays a golden shadow with its name, so the Index never shows art that does not exist.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Colours = require(ReplicatedStorage.Shared.Colours)
local Config = require(ReplicatedStorage.Shared.Config)
local DualDesigns = require(ReplicatedStorage.Shared.DualDesigns)
local Materials = require(ReplicatedStorage.Shared.Materials)
local SecretRecipes = require(ReplicatedStorage.Shared.SecretRecipes)
local UiKit = require(script.Parent.UiKit)
local UiSlimes = require(script.Parent.UiSlimes)

local U = Config.Ui
local R = Config.Rewards

type Kind = { id: string, name: string, look: { [string]: any } }

local UiIndex = {}

local TABS = { "base", "dual", "secret", "material" }
local TAB_NAMES: { [string]: string } = { base = "Colours", dual = "Duals", secret = "Secrets", material = "Materials" }
local tab = "base"

-- Portraits are built once per look and parked when the book closes.
local cache: { [string]: ViewportFrame } = {}
local token = 0

local function kinds(bucket: string): { Kind }
	local out: { Kind } = {}
	if bucket == "base" then
		for _, colour in Colours.List do
			table.insert(out, { id = colour.id, name = colour.name, look = { Colour = colour.id } })
		end
	elseif bucket == "dual" then
		for _, design in DualDesigns.List do
			if design.enabled then
				table.insert(out, {
					id = design.id,
					name = design.name,
					look = { Colour = design.bodyColour, DualId = design.id },
				})
			end
		end
	elseif bucket == "secret" then
		for _, recipe in SecretRecipes.List do
			if recipe.enabled then
				-- (no Secret art yet: the plain body, only ever drawn as a shadow)
				table.insert(out, { id = recipe.id, name = recipe.name, look = { Colour = Colours.Fallback } })
			end
		end
	else
		for _, material in Materials.List do
			table.insert(out, {
				id = material.id,
				name = material.name,
				look = { Colour = Colours.Fallback, Material = material.id },
			})
		end
	end
	return out
end

-- The ids found, per bucket.
function UiIndex.found(own: Folder?): { [string]: { [string]: boolean } }
	local out: { [string]: { [string]: boolean } } = { base = {}, dual = {}, secret = {}, material = {} }
	local raw = if own then own:GetAttribute("Found") else nil
	if type(raw) ~= "string" then
		return out
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if ok and type(decoded) == "table" then
		for _, bucket in TABS do
			if type(decoded[bucket]) == "table" then
				for _, id in decoded[bucket] do
					if type(id) == "string" then
						out[bucket][id] = true
					end
				end
			end
		end
	end
	return out
end

-- Found and all kinds, every tab together (the book's header).
function UiIndex.totals(own: Folder?): (number, number)
	local found = UiIndex.found(own)
	local have, all = 0, 0
	for _, bucket in TABS do
		for _, kind in kinds(bucket) do
			all += 1
			if found[bucket][kind.id] then
				have += 1
			end
		end
	end
	return have, all
end

local function portrait(kind: Kind, shadow: string?): ViewportFrame
	local key = kind.id .. "|" .. tostring(shadow)
	local saved = cache[key]
	if saved then
		return saved
	end
	local look = table.clone(kind.look)
	look.Scale = 1
	local view = UiSlimes.lookView(look, shadow == nil)
	if shadow then
		-- the 3D body as a flat shadow: plain white parts lit by the shadow colour only
		for _, item in view:GetDescendants() do
			if item:IsA("BasePart") then
				item.Color = Color3.new(1, 1, 1)
				item.Material = Enum.Material.SmoothPlastic
				if item.Transparency < 1 then
					item.Transparency = 0
				end
				if item:IsA("MeshPart") then
					item.TextureID = ""
				end
			elseif item:IsA("Decal") or item:IsA("SurfaceAppearance") then
				item:Destroy()
			end
		end
		view.Ambient = Color3.fromHex(shadow)
		view.LightColor = Color3.new(0, 0, 0)
	end
	cache[key] = view
	return view
end

-- Puts every portrait back on the shelf (the book closes or redraws).
function UiIndex.release()
	token += 1
	for _, view in cache do
		pcall(function()
			view.Parent = nil
		end)
	end
end

function UiIndex.draw(host: Frame, own: Folder?)
	UiIndex.release()
	local found = UiIndex.found(own)
	local list = kinds(tab)
	local have = 0
	for _, kind in list do
		if found[tab][kind.id] then
			have += 1
		end
	end
	local items = {}
	for _, id in TABS do
		table.insert(items, { id = id, text = TAB_NAMES[id] })
	end
	UiKit.segmented(host, items, tab, function(id)
		tab = id
		UiKit.clear(host)
		UiIndex.draw(host, own)
	end, { Name = "IndexTabs", ItemWidth = 92 })
	UiKit.label(host, have .. "/" .. #list, U.TextNormal, "Brown", {
		Name = "TabCount",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(64, U.Touch),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local area = UiKit.make("ScrollingFrame", {
		Name = "Index",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, U.Touch + U.Gap),
		Size = UDim2.new(1, 0, 1, -U.Touch - U.Gap),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, host)
	UiKit.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(R.IndexCell, R.IndexCellHeight),
		CellPadding = UDim2.fromOffset(U.Gap, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, area)
	local slots: { { box: Frame, holder: Frame, kind: Kind, shadow: string? } } = {}
	for order, kind in list do
		local isFound = found[tab][kind.id] == true
		-- a Secret has no art: found, it is a golden shadow; any kind not found is a dark one
		local shadow: string? = if not isFound
			then R.SilhouetteColour
			elseif tab == "secret" then U.Colours.Gold
			else nil
		local box, body = UiKit.skin(area, "Wood", if isFound then "Card" else "CardDeep", {
			Name = kind.id,
			LayoutOrder = order,
		})
		box:SetAttribute("Found", isFound)
		local holder = UiKit.make("Frame", {
			Name = "Picture",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, -(U.TextTiny + 8)),
		}, body)
		UiKit.label(body, if isFound or tab == "base" then kind.name else "???", U.TextTiny, "Brown", {
			Name = "Name",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, U.TextTiny + 6),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		table.insert(slots, { box = box, holder = holder, kind = kind, shadow = shadow })
	end
	-- Portraits are built only for cards in view, a few a frame, so a long tab opens at once.
	token += 1
	local mine = token
	local function fill()
		local top = area.AbsolutePosition.Y
		local bottom = top + area.AbsoluteSize.Y
		for _, slot in slots do
			if mine ~= token then
				return
			end
			local y = slot.box.AbsolutePosition.Y
			if not slot.holder:FindFirstChild("Portrait") and y + slot.box.AbsoluteSize.Y >= top and y <= bottom then
				portrait(slot.kind, slot.shadow).Parent = slot.holder
				task.wait()
			end
		end
	end
	area:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		task.spawn(fill)
	end)
	task.defer(fill)
end

return UiIndex
