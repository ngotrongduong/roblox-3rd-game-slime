--!strict
-- The VIP Shop's sheet (docs/MONETIZATION.md §2): one icon tab each for VIP and the passes, Gold, Spins and Boosts. Every good
-- is a card: its picture, its name, its effect in a short line of pictures and numbers, and a Buy button with the price in Robux
-- (a pass owned shows "Owned", a good not on Roblox yet shows SOON, one the server would refuse is greyed with a short reason).
-- It draws what the server publishes on the Player (Vip, Passes, GoldUntil, HatchUntil, StreakSavers, PaidRandomRestricted,
-- ShopRefused ...) and on the village folder (Areas, LuckUntil, Wheel), and asks Remotes.Purchase to open Roblox's own purchase
-- prompt; it decides nothing. UiMarket opens it at the VIP counter (inside the counter's range), UiShop.open opens it anywhere
-- (the Wheel's "Get spins"). The Gold packs show the coins THIS farm gets, worked out as the server does from the published
-- area levels (shared/Village.upgradeCost); the "+n%" and "Save n%" labels come from the real prices, never written by hand.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Luck = require(ReplicatedStorage.Shared.Luck)
local VillageRules = require(ReplicatedStorage.Shared.Village)
local UiDungeon = require(script.Parent.UiDungeon)
local UiKit = require(script.Parent.UiKit)
local UiRewards = require(script.Parent.UiRewards)
local ZombieTeams = require(script.Parent.ZombieTeams)

local U = Config.Ui
local S = U.Shop
local R = Config.Robux

type Product = typeof(Config.Robux.Products[1])
type Tab = { id: string, text: string?, icon: string? }
-- One piece of a good's effect line: a picture (nil for a plain word) and its short text.
-- `live`: the text is worked out again every second (a potion's time left).
type Part = { picture: ((parent: Instance, size: number) -> ())?, text: string, live: (() -> string)? }

local UiShop = {}
local player = Players.LocalPlayer
local tab = "pass"
local content: Frame? = nil
local scrolling: ScrollingFrame? = nil
-- Where each tab's list was scrolled to, so a redraw keeps the place.
local scrolls: { [string]: number } = {}
-- Labels that count down while the sheet is open (a potion's time left).
local clocks: { { label: TextLabel, text: () -> string } } = {}
-- What the sheet was drawn from, so the once-a-second look redraws only when something changed.
local drawnFrom = ""
local drawnTab = ""
local busy = false
local loopToken = 0

local TABS: { Tab } = {
	{ id = "pass", icon = "vip" },
	{ id = "gold", icon = "gold_sack" },
	{ id = "spins", icon = "spin" },
	{ id = "boost", icon = "potion_luck" },
}

-- Why a good cannot be bought now (the server's reasons), as the short line on its card and in a toast.
local WHY: { [string]: string } = {
	NEEDS_PASS = "Get the first team first",
	BETTER_OWNED = "You have a better one",
	NO_EGGS = "No eggs waiting",
	NOT_TIRED = "Everyone is rested",
	NO_QUEST = "No quest to redraw",
	NOT_BROKEN = "No missed day",
	OWNED = "You own it",
	STARTER_BOUGHT = "Already bought",
	RESTRICTED = "Not available",
	NOT_ON_SALE = "Coming soon",
	NONE = "None left",
	RATE_LIMIT = "One moment",
	NOT_READY = "Still loading",
	RATE = "One moment",
}

local function num(value: any): number
	return if type(value) == "number" then value else 0
end

local function decodeAttr(inst: Instance?, name: string): { [any]: any }
	local raw = if inst then inst:GetAttribute(name) else nil
	if type(raw) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(decoded) == "table" then decoded else {}
end

-- ===== what the server says =====

local function restricted(): boolean
	return player:GetAttribute("PaidRandomRestricted") ~= false
end

local function ownedPasses(): { [string]: boolean }
	local set: { [string]: boolean } = {}
	for _, key in decodeAttr(player, "Passes") do
		if type(key) == "string" then
			set[key] = true
		end
	end
	return set
end

local function refusedGoods(): { [string]: string }
	local found: { [string]: string } = {}
	for _, pair in decodeAttr(player, "ShopRefused") do
		if type(pair) == "table" and type(pair[1]) == "string" and type(pair[2]) == "string" then
			found[pair[1]] = pair[2]
		end
	end
	return found
end

-- The coins a "1 x" Gold pack is worth to this farm: the price of the cheapest upgrade the village can still buy, worked out
-- from the area levels the server publishes the way shared/Rewards.coinBase does. nil while they are not published.
local function coinBase(): number?
	local levels = decodeAttr(ZombieTeams.root(), "Areas")
	if next(levels) == nil then
		return nil
	end
	local best = math.huge
	for _, id in Config.Village.Areas do
		local level = if type(levels[id]) == "number" then levels[id] else Config.Village.StartLevel
		if level < Config.Village.MaxLevel then
			best = math.min(best, VillageRules.upgradeCost(level))
		end
	end
	return if best == math.huge then VillageRules.upgradeCost(Config.Village.MaxLevel - 1) else best
end

-- A Gold pack's coins as a short number, or "x2" while the farm's levels are not known yet.
local function coinsFor(multiple: number): string
	local base = coinBase()
	return if base then UiRewards.short(multiple * base) else "x" .. tostring(multiple)
end

-- Seconds left of a potion (0 when none runs): the luck potion's end is the village's, the others' the player's.
local function potionLeft(kind: string): number
	local ends: any
	if kind == "luck" then
		local village = ZombieTeams.root()
		ends = if village then village:GetAttribute("LuckUntil") else nil
	else
		ends = player:GetAttribute(if kind == "gold" then "GoldUntil" else "HatchUntil")
	end
	return if type(ends) == "number" then math.max(0, ends - workspace:GetServerTimeNow()) else 0
end

-- What the sheet is drawn from: the attributes that change a card.
local function signature(): string
	local parts: { string } = {}
	for _, name in
		{
			"Vip",
			"Passes",
			"LuckLabel",
			"GoldUntil",
			"HatchUntil",
			"ExtraTeams",
			"StreakSavers",
			"QuestRerolls",
			"BankedDrinks",
			"BankedHatchAlls",
			"PaidRandomRestricted",
			"ShopRefused",
		}
	do
		table.insert(parts, tostring(player:GetAttribute(name)))
	end
	local village = ZombieTeams.root()
	if village then
		table.insert(parts, tostring(village:GetAttribute("LuckUntil")))
		table.insert(parts, tostring(village:GetAttribute("Areas")))
		if tab == "spins" or tab == "gold" then
			table.insert(parts, tostring(village:GetAttribute("Wheel")))
		end
	end
	return table.concat(parts, "|")
end

-- ===== the goods =====

local function inTab(product: Product, id: string): boolean
	if id == "pass" then
		return product.kind == "pass"
	elseif id == "gold" then
		return product.gold ~= nil or product.starter ~= nil
	elseif id == "spins" then
		return product.spins ~= nil
	end
	return product.potion ~= nil or product.effect ~= nil
end

-- The Extra Team pass to offer: the first one not owned yet (the last one once they all are).
local function shownTeam(passes: { [string]: boolean }): string?
	local first: string?, last: string? = nil, nil
	for _, product in R.Products do
		if product.kind == "pass" and product.teams ~= nil then
			last = product.key
			if first == nil and not passes[product.key] then
				first = product.key
			end
		end
	end
	return first or last
end

-- "buy", "owned", "soon", "refused" (with its short reason) or "hidden" (a paid random item where the region forbids it, a
-- Starter Pack already bought).
local function stateOf(
	product: Product,
	passes: { [string]: boolean },
	refused: { [string]: string },
	noRandom: boolean
): (string, string?)
	local why = refused[product.key]
	local random = product.spins ~= nil or (product.starter ~= nil and product.starter.spins > 0)
	if (noRandom and random) or why == "STARTER_BOUGHT" then
		return "hidden", nil
	elseif passes[product.key] or why == "OWNED" then
		return "owned", nil
	end
	-- (a Studio test grant lets an id-0 good be bought, so the screens can be tried before the products exist on Roblox)
	if product.id == 0 and not (R.TestGrant and RunService:IsStudio()) then
		return "soon", nil
	elseif why ~= nil and why ~= "RESTRICTED" then
		return "refused", WHY[why] or "Not now"
	end
	return "buy", nil
end

-- A pack's bonus in whole percent against the smallest pack, from the real prices: Gold packs give that much more coins for
-- the Robux, Spin bundles cost that much less a spin. 0 for the smallest pack and for goods that are not packs.
local function bonusOf(product: Product): number
	local isGold = product.gold ~= nil
	local function unitsOf(good: Product): number?
		return if isGold then good.gold else good.spins
	end
	local units = unitsOf(product)
	if not units then
		return 0
	end
	local smallest, smallestUnits = product, units
	for _, other in R.Products do
		local count = unitsOf(other)
		if count and count < smallestUnits then
			smallest, smallestUnits = other, count
		end
	end
	if smallest == product then
		return 0
	end
	local rate = units / product.price
	local base = smallestUnits / smallest.price
	local gain = if isGold then rate / base - 1 else 1 - base / rate
	return math.floor(gain * 100 + 0.5)
end

-- ===== effect lines =====

local function iconPart(name: string, text: string): Part
	return {
		text = text,
		picture = function(parent, size)
			UiKit.icon(parent, name, size, { LayoutOrder = 1 })
		end,
	}
end

-- The effect of a good in a few pictures and numbers (a Luck pass: the real effect on rare babies, from Config.Luck).
local function effectOf(product: Product): { Part }
	if product.vip then
		return {
			iconPart("luck", "x" .. tostring(Config.Luck.Vip)),
			iconPart("coins", "x" .. tostring(R.CoinFactorVip)),
			iconPart("potion_hatch", "x" .. tostring(R.HatchFactorVip)),
			iconPart("spin", "+" .. tostring(Config.Wheel.VipFreePerDay)),
		}
	elseif product.luck then
		return { { text = string.format("Rare babies x%.1f", Luck.real(product.luck)) } }
	elseif product.teams then
		return { iconPart("team_slot", "+" .. product.teams .. (if product.teams == 1 then " team" else " teams")) }
	elseif product.slots then
		return { iconPart("slimes", "+" .. product.slots .. " slots") }
	elseif product.gold then
		return { iconPart("coins", coinsFor(product.gold)) }
	elseif product.spins then
		return { iconPart("spin", "x" .. product.spins) }
	elseif product.potion then
		local kind = product.potion
		local icon, factor = "potion_hatch", R.HatchFactorPotion
		if kind == "luck" then
			icon, factor = "luck", Config.Luck.Potion
		elseif kind == "gold" then
			icon, factor = "coins", R.CoinFactorPotion
		end
		return { iconPart(icon, "x" .. tostring(factor) .. " " .. num(product.minutes) .. " min") }
	elseif product.starter then
		local starter = product.starter
		local parts: { Part } = {
			iconPart("spin", "x" .. starter.spins),
			iconPart("coins", coinsFor(starter.gold)),
			iconPart("luck", starter.luckMinutes .. "m"),
		}
		for _, item in starter.items do
			table.insert(parts, {
				text = "x" .. item.count,
				picture = function(parent, size)
					UiDungeon.dropIcon(parent, item.id, size, { LayoutOrder = 1 })
				end,
			})
		end
		return parts
	elseif product.effect == "energy" then
		return { iconPart("energy", "All slimes full") }
	elseif product.effect == "hatchAll" then
		return { { text = "Hatch every egg now" } }
	elseif product.effect == "reroll" then
		return { iconPart("quest_reroll", "Redraw a quest") }
	end
	return { { text = "Mend a missed day" } }
end

-- The effect line: its parts side by side, each a little picture and a word.
local function effectRow(parent: Instance, parts: { Part }, colour: string, order: number)
	local row = UiKit.make("Frame", {
		Name = "Effect",
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, S.EffectHeight),
	}, parent)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	for index, part in parts do
		local cell = UiKit.make("Frame", {
			Name = "Part" .. index,
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Size = UDim2.fromOffset(0, S.EffectHeight),
			AutomaticSize = Enum.AutomaticSize.X,
		}, row)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, cell)
		if part.picture then
			part.picture(cell, S.EffectIcon)
		end
		local label = UiKit.label(cell, part.text, U.TextTiny, colour, {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(0, S.EffectHeight),
			AutomaticSize = Enum.AutomaticSize.X,
			TextTruncate = Enum.TextTruncate.None,
		})
		local live = part.live
		if live then
			label.Text = live()
			table.insert(clocks, { label = label, text = live })
		end
	end
end

-- ===== buying =====

-- Asks the server to open Roblox's purchase prompt for a good. A refusal gets a short toast; in Studio's test grant the good is
-- simply added and the answer says so.
local function buy(product: Product)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = if remotes then remotes:FindFirstChild("Purchase") else nil
		local ok: boolean, answer: any = false, nil
		if remote and remote:IsA("RemoteFunction") then
			ok, answer = pcall(function(): any
				return remote:InvokeServer({ key = product.key })
			end)
		end
		busy = false
		if ok and type(answer) == "table" then
			if answer.ok == true then
				if answer.test == true then
					UiKit.toast("Added", product.icon)
				end
			else
				UiKit.toast((if type(answer.reason) == "string" then WHY[answer.reason] else nil) or "Please try again")
			end
		else
			UiKit.toast("Please try again")
		end
	end)
end

-- How many of a good are banked (paid while it could do nothing; the server publishes the counts).
local function bankedOf(product: Product): number
	if product.effect == "energy" then
		return num(player:GetAttribute("BankedDrinks"))
	elseif product.effect == "hatchAll" then
		return num(player:GetAttribute("BankedHatchAlls"))
	end
	return 0
end

-- Spends one banked good through the village remote (the server checks it again); a refusal gets a short toast.
local function useBanked(product: Product)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = if remotes then remotes:FindFirstChild("Village") else nil
		local ok: boolean, answer: any = false, nil
		if remote and remote:IsA("RemoteFunction") then
			ok, answer = pcall(function(): any
				return remote:InvokeServer({ action = "UseBanked", key = product.key })
			end)
		end
		busy = false
		if ok and type(answer) == "table" and answer.ok == true then
			UiKit.toast("Used", product.icon)
		else
			local reason = if ok and type(answer) == "table" then answer.reason else nil
			UiKit.toast((if type(reason) == "string" then WHY[reason] else nil) or "Please try again")
		end
	end)
end

-- ===== the cards =====

local function pill(parent: Instance, text: string, order: number)
	local box = UiKit.kit(parent, "green", {
		Name = "Bonus",
		LayoutOrder = order,
		Size = UDim2.fromOffset(#text * S.PillLetter + S.PillPad, S.PillHeight),
	})
	local word = UiKit.label(box, text, U.TextTiny, "Cream", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
	})
	UiKit.outline(word, true)
end

local function card(list: Instance, order: number, product: Product, state: string, why: string?)
	local box, body = UiKit.card(list, {
		Name = product.key,
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, S.RowHeight),
	})
	if state == "owned" or state == "refused" then
		UiKit.setFill(box, "CardDeep")
	end
	local picture = UiKit.icon(body, product.icon, S.Icon, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
	})
	if state == "refused" and picture:IsA("ImageLabel") then
		picture.ImageTransparency = U.DisabledTransparency
	end

	-- the name (with its bonus) over the effect, between the picture and the price
	local left = S.Icon + U.Gap
	local banked = if state == "owned" then 0 else bankedOf(product)
	local useRoom = if banked > 0 then S.UseWidth + U.Gap else 0
	local info = UiKit.make("Frame", {
		Name = "Info",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(left, 0),
		Size = UDim2.new(1, -left - S.ButtonWidth - U.Gap - useRoom, 1, 0),
	}, body)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, info)
	local line = UiKit.make("Frame", {
		Name = "Name",
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, S.PillHeight + 2),
	}, info)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, line)
	UiKit.label(line, product.label or product.name, U.TextSmall, "Brown", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, S.PillHeight + 2),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
	})
	local bonus = bonusOf(product)
	if bonus > 0 and state ~= "owned" then
		pill(line, (if product.spins then "Save " else "+") .. bonus .. "%", 2)
	end
	local kind = product.potion
	if why then
		effectRow(info, { { text = why } }, "Red", 2)
	elseif kind and potionLeft(kind) > 0 then
		-- a potion that runs: the time it has left, counting down
		local running = iconPart(product.icon, "")
		running.live = function()
			return UiRewards.clock(potionLeft(kind))
		end
		effectRow(info, { running }, "GreenDark", 2)
	else
		effectRow(info, effectOf(product), "BrownSoft", 2)
	end

	-- the price, SOON, or "Owned"
	if state == "owned" then
		local holder = UiKit.make("Frame", {
			Name = "Owned",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(S.ButtonWidth, S.ButtonHeight),
		}, body)
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, holder)
		UiKit.icon(holder, "arenaQuest", U.IconNormal, { LayoutOrder = 1 })
		UiKit.label(holder, "Owned", U.TextSmall, "GreenDark", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextTruncate = Enum.TextTruncate.None,
		})
		return
	end
	if banked > 0 then
		UiKit.button(body, {
			Name = "Use",
			Text = "Use (" .. banked .. ")",
			Style = "primary",
			Enabled = why == nil,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -S.ButtonWidth - U.Gap, 0.5, 0),
			Size = UDim2.fromOffset(S.UseWidth, S.ButtonHeight),
			OnClick = function()
				useBanked(product)
			end,
		})
	end
	local soon = state == "soon"
	UiKit.button(body, {
		Name = "Buy",
		Text = if soon then "SOON" else tostring(product.price),
		Icon = if soon then nil else "robux",
		IconSize = S.PriceIcon,
		Style = if state == "buy" then "primary" else "secondary",
		Enabled = state == "buy",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(S.ButtonWidth, S.ButtonHeight),
		OnClick = function()
			buy(product)
		end,
	})
end

-- The wheel's odds above the spins: each slice's prize and its chance, in the order of the wheel (a paid random item shows
-- its odds before it is bought).
local function oddsStrip(list: Instance, order: number)
	local slices: { any } = {}
	local wheel = decodeAttr(ZombieTeams.root(), "Wheel")
	if type(wheel.slices) == "table" then
		slices = wheel.slices
	end
	if #slices == 0 then
		return
	end
	local _, body = UiKit.card(list, {
		Name = "Odds",
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, S.OddsHeight),
	})
	UiKit.make("UIGridLayout", {
		CellSize = UDim2.new(1 / #slices, -2, 1, 0),
		CellPadding = UDim2.fromOffset(2, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)
	for index, slice in slices do
		local cell =
			UiKit.make("Frame", { Name = "Slice" .. index, BackgroundTransparency = 1, LayoutOrder = index }, body)
		UiKit.make("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, cell)
		UiRewards.slicePicture(cell, slice, S.OddsIcon, { LayoutOrder = 1 })
		UiKit.label(cell, UiRewards.percent(num(slice.chance)), U.TextTiny, "Brown", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, U.TextTiny + 2),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.None,
		})
	end
end

-- ===== the sheet =====

local function render()
	local host = content
	if not host then
		return
	end
	if scrolling and scrolling.Parent then
		scrolls[drawnTab] = scrolling.CanvasPosition.Y
	end
	table.clear(clocks)
	UiKit.clear(host)
	drawnFrom = signature()
	drawnTab = tab
	local list = UiKit.make("ScrollingFrame", {
		Name = "Goods",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, host) :: ScrollingFrame
	UiKit.make("UIListLayout", { Padding = UDim.new(0, U.Gap), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	scrolling = list
	local saved = scrolls[tab]
	if saved and saved > 0 then
		list:GetPropertyChangedSignal("AbsoluteCanvasSize"):Once(function()
			list.CanvasPosition = Vector2.new(0, saved)
		end)
	end
	if tab == "spins" then
		oddsStrip(list, 0)
	end
	local passes, refused, noRandom = ownedPasses(), refusedGoods(), restricted()
	local team = shownTeam(passes)
	local order = 0
	-- (the Starter Pack first on the Gold tab: it is the best offer, and the catalog lists it last)
	for round = 1, 2 do
		for _, product in R.Products do
			local starter = product.starter ~= nil
			if inTab(product, tab) and starter == (round == 1) and (product.teams == nil or product.key == team) then
				local state, why = stateOf(product, passes, refused, noRandom)
				if state ~= "hidden" then
					order += 1
					card(list, order, product, state, why)
					-- (the Starter Pack holds wheel spins, a paid random item: the wheel's odds sit right under it)
					if product.starter ~= nil and product.starter.spins > 0 and state ~= "owned" then
						order += 1
						oddsStrip(list, order)
					end
				end
			end
		end
	end
end

-- Fills a modal the caller opened with the shop: the tabs in its header, the cards below, kept up to date once a second while
-- it is open. `startTab`: "pass", "gold", "spins" or "boost" (nil: the one it was left on).
function UiShop.fill(modal: UiKit.Modal, startTab: string?)
	if startTab then
		tab = startTab
	end
	local items: { Tab } = {}
	for _, item in TABS do
		-- (paid random items are not shown where the region forbids them: nothing to put under Spins)
		if item.id ~= "spins" or not restricted() then
			table.insert(items, item)
		end
	end
	if tab == "spins" and restricted() then
		tab = "pass"
	end
	table.clear(scrolls)
	local narrow = UiKit.units(UiKit.root()).X < U.SheetWidth + 2 * U.Edge
	local function choose(id: string)
		tab = id
		render()
	end
	if narrow then
		-- (no room for the crown beside the tabs, and each a little under a full touch square)
		UiKit.segmented(modal.header, items, tab, choose, {
			Name = "Tabs",
			ItemWidth = 44,
			Size = UDim2.new(1, 0, 0, U.Touch),
		})
	else
		UiKit.icon(modal.header, "vip", U.Touch - 8, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
		})
		UiKit.segmented(modal.header, items, tab, choose, {
			Name = "Tabs",
			Position = UDim2.fromOffset(U.Touch, 0),
			Size = UDim2.new(1, -U.Touch, 1, 0),
		})
	end
	content = modal.content
	loopToken += 1
	local mine = loopToken
	render()
	task.spawn(function()
		while loopToken == mine and UiKit.modalId() == "vip" do
			task.wait(1)
			if loopToken ~= mine or UiKit.modalId() ~= "vip" then
				break
			end
			if signature() ~= drawnFrom then
				render()
			else
				for _, item in clocks do
					item.label.Text = item.text()
				end
			end
		end
		-- (closed, or another shop opened over it: nothing is left running)
		if loopToken == mine then
			content, scrolling = nil, nil
			table.clear(clocks)
			table.clear(scrolls)
		end
	end)
end

-- Opens the shop as a bottom sheet wherever the player is (the counter's own sheet is tied to its range, UiMarket).
function UiShop.open(startTab: string?)
	local modal = UiKit.openModal("vip", {
		Width = U.SheetWidth,
		Height = U.VipSheetHeight,
		Bottom = true,
		Dim = 0.8,
	})
	UiShop.fill(modal, startTab)
end

return UiShop
