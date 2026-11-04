--!strict
-- The Index (docs/GAMEPLAY.md §13): every kind of slime as a card, in four tabs (the 11 colours, the Duals, the Secrets, the
-- materials). A kind the player has found shows its own picture; one not found yet shows the same picture darkened (the only
-- light on it is Config.Rewards.LockedAmbient), so the player sees what to look for. Secrets have no art of their own yet: a
-- found Secret stays a golden shadow with its name, so the Index never shows art that does not exist. Drawn inside the slime
-- book (UiBook); what was found comes from the village folder's Found attribute (server/Rewards).
--
-- Opening is cheap on purpose: the cards are made a few a frame, and a card's picture (a ViewportFrame with a clone of the
-- slime body) only when it is in view, a couple a frame. Pictures are built once per kind and parked when the book closes or
-- changes tab (parked, never destroyed with their card: a destroyed one could not be put on a card again, which left the
-- Index without pictures after a tab change).
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
-- "lit": found, its own picture with the owner's face. "gold": a found Secret (no art yet). "dark": not found.
type Mode = "lit" | "gold" | "dark"
type Slot = { box: Frame, holder: Frame, kind: Kind, mode: Mode, drawn: boolean }

local UiIndex = {}

local TABS = { "base", "dual", "secret", "material" }
local TAB_NAMES: { [string]: string } = { base = "Colours", dual = "Duals", secret = "Secrets", material = "Materials" }
local tab = "base"

-- Portraits are built once per look and mode, and parked when the book closes.
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

-- A new portrait of a kind in the given mode.
local function build(kind: Kind, mode: Mode): ViewportFrame
	local look = table.clone(kind.look)
	look.Scale = 1
	local view = UiSlimes.lookView(look, mode == "lit")
	if mode == "gold" then
		-- the 3D body as a flat golden shadow: plain white parts lit by the shadow colour only
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
		view.Ambient = Color3.fromHex(U.Colours.Gold)
		view.LightColor = Color3.new(0, 0, 0)
	elseif mode == "dark" then
		-- the real picture (skin and all), lit by the locked ambient colour only
		view.Ambient = Color3.fromHex(R.LockedAmbient)
		view.LightColor = Color3.new(0, 0, 0)
	end
	return view
end

-- Puts the picture of a kind on its card, building it the first time.
local function portrait(kind: Kind, mode: Mode, holder: Frame)
	local key = kind.id .. "|" .. mode
	local saved = cache[key]
	if saved then
		local ok = pcall(function()
			saved.Parent = holder
		end)
		if ok then
			return
		end
		-- (one that was destroyed cannot be used again)
		cache[key] = nil
	end
	local view = build(kind, mode)
	cache[key] = view
	view.Parent = holder
end

-- Puts every portrait back on the shelf (the book closes, redraws or changes tab). Call it before the cards are cleared.
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
		-- (the pictures are parked first: clearing the cards would destroy them)
		UiIndex.release()
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

	token += 1
	local mine = token
	local slots: { Slot } = {}
	local pumping = false

	local function inView(slot: Slot): boolean
		local top = area.AbsolutePosition.Y
		local bottom = top + area.AbsoluteSize.Y
		local y, height = slot.box.AbsolutePosition.Y, slot.box.AbsoluteSize.Y
		-- (one row of margin, so a picture is ready as its card scrolls in)
		return height > 0 and y + height >= top - height and y <= bottom + height
	end
	-- Pictures for the cards in view, R.IndexPicturesPerFrame a frame, until every card in view has one. Starts one frame
	-- late so the cards have been laid out.
	local function pump()
		if pumping then
			return
		end
		pumping = true
		task.spawn(function()
			while mine == token and area.Parent do
				task.wait()
				if mine ~= token then
					break
				end
				local made = 0
				for _, slot in slots do
					if made >= R.IndexPicturesPerFrame then
						break
					end
					if not slot.drawn and inView(slot) then
						slot.drawn = true
						portrait(slot.kind, slot.mode, slot.holder)
						made += 1
					end
				end
				if made == 0 then
					break
				end
			end
			pumping = false
		end)
	end
	area:GetPropertyChangedSignal("CanvasPosition"):Connect(pump)
	area:GetPropertyChangedSignal("AbsoluteSize"):Connect(pump)

	-- The cards, R.IndexCardsPerFrame a frame (the first rows come first).
	task.spawn(function()
		for order, kind in list do
			if mine ~= token or not area.Parent then
				return
			end
			local isFound = found[tab][kind.id] == true
			-- a Secret has no art: found, it is a golden shadow; any kind not found is its picture, darkened
			local mode: Mode = if not isFound then "dark" elseif tab == "secret" then "gold" else "lit"
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
			table.insert(slots, { box = box, holder = holder, kind = kind, mode = mode, drawn = false })
			if order % R.IndexCardsPerFrame == 0 then
				pump()
				task.wait()
			end
		end
		pump()
	end)
end

return UiIndex
