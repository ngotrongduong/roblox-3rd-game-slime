--!strict
-- The Market's screens that are not the sell sheet (UiSquad): the VIP counter's prompt and sheet, and the quick-travel ask
-- behind the HUD's Home and Market buttons. The VIP counter's sheet is the VIP Shop (UiShop); here it only opens it inside
-- the counter's range, as the other counters' sheets are.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local UiKit = require(script.Parent.UiKit)
local UiShop = require(script.Parent.UiShop)

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
	IN_DUNGEON = "Leave the Dungeon first.",
}
local travelling = false

-- ===== The VIP counter =====

local function openVip(context: Context, point: Vector3)
	local modal = context.open("vip", U.VipSheetHeight, function() end, point, Config.Market.VipRangeStuds * 1.3)
	UiShop.fill(modal, nil)
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
			-- the camera comes round behind the character, so a move opens on the view the landing faces
			local camera = workspace.CurrentCamera
			local character = game:GetService("Players").LocalPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if camera and root and root:IsA("BasePart") then
				local offset = camera.CFrame.Position - camera.Focus.Position
				local back = root.CFrame.LookVector * Vector3.new(1, 0, 1)
				local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
				camera.CFrame =
					CFrame.lookAt(root.Position - back.Unit * flat + Vector3.new(0, offset.Y, 0), root.Position)
			end
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
