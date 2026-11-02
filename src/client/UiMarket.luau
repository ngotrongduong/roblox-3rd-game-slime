--!strict
-- The Market's screens that are not the sell sheet (UiSquad): the VIP counter's prompt and sheet, and the quick-travel ask
-- behind the HUD's Home and Market buttons. The VIP sheet lists Config.Robux.Products, which stays empty until the owner
-- approves a list and prices: then it says "Opening soon". Nothing is bought here, there is no purchase code yet.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local UiKit = require(script.Parent.UiKit)

local U = Config.Ui

-- What UiSquad lends: its one-sheet opener and its invisible prompt holder.
type Context = {
	open: (id: string, height: number, tick: () -> (), point: Vector3?, range: number) -> UiKit.Modal,
	anchor: (position: Vector3, name: string) -> Part,
}

local UiMarket = {}

local travelReasons: { [string]: string } = {
	COOLDOWN = "One moment.",
	DEAD = "Not right now.",
	NOT_READY = "Village is loading.",
	NO_PLOT = "No home yet.",
}
local travelling = false

-- ===== The VIP counter =====

local function openVip(context: Context, point: Vector3)
	local modal = context.open("vip", U.VipSheetHeight, function() end, point, Config.Market.VipRangeStuds * 1.3)
	UiKit.label(modal.header, "VIP Shop", U.TextHeader, "Brown", {
		Size = UDim2.fromScale(1, 1),
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local products = Config.Robux.Products
	if #products == 0 then
		UiKit.label(modal.content, "Opening soon", U.TextHeader, "BrownSoft", {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
		return
	end
	local list = UiKit.make("ScrollingFrame", {
		Name = "Products",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
	}, modal.content)
	UiKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, U.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	for index, product in products do
		local _, body = UiKit.card(list, {
			Name = product.key,
			LayoutOrder = index,
			Size = UDim2.new(1, -8, 0, U.RowHeight),
		})
		UiKit.make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, U.Gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, body)
		UiKit.icon(body, product.icon, U.Touch - 12, { LayoutOrder = 1 })
		UiKit.label(body, product.name, U.TextNormal, "Brown", {
			LayoutOrder = 2,
			Size = UDim2.new(1, -(U.Touch + 100), 1, 0),
		})
		UiKit.label(body, tostring(product.price), U.TextHeader, "Brown", {
			LayoutOrder = 3,
			Size = UDim2.fromOffset(80, U.Touch),
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end
end

-- Called once by UiSquad: the VIP counter's prompt, at its Config spot (it works with or without the scene artist's model).
function UiMarket.start(context: Context)
	local spot = Layout.marketPoint(Config.Market.Vip)
	local anchor =
		context.anchor(Vector3.new(spot.X, Config.Map.GroundY + Config.Zombies.View.AnchorLift, spot.Z), "VipPrompt")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Vip"
	prompt.ActionText = "VIP Shop"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.Market.VipRangeStuds
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function()
		openVip(context, anchor.Position)
	end)
end

-- ===== Quick travel =====

-- Asks the server to move this player: place is "Market" or "Home". A refusal gets a short toast; success closes any sheet.
function UiMarket.travel(place: string)
	if travelling then
		return
	end
	travelling = true
	task.spawn(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = if remotes then remotes:FindFirstChild("Travel") else nil
		local ok: boolean, answer: any = false, nil
		if remote and remote:IsA("RemoteFunction") then
			ok, answer = pcall(function(): any
				return remote:InvokeServer({ action = place })
			end)
		end
		if ok and type(answer) == "table" and answer.ok == true then
			UiKit.closeModal(true)
		else
			local reason = if ok and type(answer) == "table" then answer.reason else nil
			UiKit.toast(
				if type(reason) == "string" and travelReasons[reason]
					then travelReasons[reason]
					else "Please try again."
			)
		end
		travelling = false
	end)
end

return UiMarket
