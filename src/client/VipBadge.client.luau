--!strict
-- The small VIP crown over the head of a VIP (the Player attribute Vip, server/Purchases; docs/MONETIZATION.md §2): the owner's
-- Icons.vip picture, never a name. It is made the way the Arena titles are (ArenaTitles.client): a BillboardGui sized in pixels
-- and scaled with the screen, as high above the head as a title and shown as far, with no particles and no per-frame work, only a
-- look twice a second while a crown exists (a hat or wings that stand taller lift it). A player who also wears an Arena title
-- (the attribute ArenaRank) gets the crown beside the title's left end, the same line.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Config = require(ReplicatedStorage.Shared.Config)

local T = Config.Arena.View.Title
local B = Config.Ui.VipBadge

type Entry = {
	player: Player,
	head: BasePart?,
	gui: BillboardGui?,
	crown: ImageLabel?,
	connections: { RBXScriptConnection },
}

local entries: { [Player]: Entry } = {}
local looking = false
-- The billboard is wide enough for the title's width with a crown on each side.
local WIDTH = T.Width + 2 * (B.Size + B.Gap)

local function rankOf(player: Player): number
	local value = player:GetAttribute("ArenaRank")
	if type(value) == "number" and value >= 1 and value <= T.Top then
		return math.floor(value)
	end
	return 0
end

local function screenScale(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / T.ScaleReference, T.ScaleMin, T.ScaleMax) else 1
end

-- How far above the head the crown sits: the title's own lift, higher when a hat or wings stand taller.
local function liftOf(head: BasePart): number
	local character = head.Parent
	local top = head.Position.Y + head.Size.Y / 2
	if character then
		for _, child in character:GetChildren() do
			local handle = if child:IsA("Accessory") then child:FindFirstChild("Handle") else nil
			if handle and handle:IsA("BasePart") then
				top = math.max(top, handle.Position.Y + handle.Size.Y / 2)
			end
		end
	end
	return math.max(T.Lift, top - head.Position.Y + T.HatClearance)
end

-- Where the crown stands on the billboard: its middle, or left of the Arena title's text when the player wears one.
local function place(entry: Entry)
	local crown = entry.crown
	if not crown then
		return
	end
	local x = WIDTH / 2
	local rank = rankOf(entry.player)
	if rank > 0 then
		local style = if rank <= 3 then rank else 4
		local name: string = (T.Names :: any)[style]
		local size = TextService:GetTextSize(
			name,
			T.TextSize,
			(Enum.Font :: any)[Config.Ui.Font],
			Vector2.new(T.Width * 2, T.Height)
		)
		x = WIDTH / 2 - size.X / 2 - B.Gap - B.Size / 2
	end
	crown.Position = UDim2.fromOffset(x, T.Height / 2)
end

local function clearVisuals(entry: Entry)
	if entry.gui then
		entry.gui:Destroy()
	end
	entry.gui, entry.crown = nil, nil
end

local function build(entry: Entry)
	clearVisuals(entry)
	local head = entry.head
	if not head or not head.Parent then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VipBadge"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(WIDTH, T.Height)
	gui.StudsOffset = Vector3.new(0, liftOf(head), 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = T.MaxDistance
	gui.LightInfluence = 0
	gui.Parent = head
	local scale = Instance.new("UIScale")
	scale.Scale = screenScale()
	scale.Parent = gui
	local crown = Instance.new("ImageLabel")
	crown.Name = "Crown"
	crown.BackgroundTransparency = 1
	crown.Image = "rbxassetid://" .. tostring(Config.Ui.Icons.vip)
	crown.ScaleType = Enum.ScaleType.Fit
	crown.AnchorPoint = Vector2.new(0.5, 0.5)
	crown.Size = UDim2.fromOffset(B.Size, B.Size)
	crown.Parent = gui
	entry.gui, entry.crown = gui, crown
	place(entry)
end

local function attachHead(entry: Entry, character: Model)
	task.spawn(function()
		local head = character:WaitForChild("Head", 10)
		if entries[entry.player] ~= entry or entry.player.Character ~= character then
			return
		end
		if head and head:IsA("BasePart") then
			entry.head = head
			build(entry)
		end
	end)
end

local function remove(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	entries[player] = nil
	clearVisuals(entry)
	for _, connection in entry.connections do
		connection:Disconnect()
	end
end

-- Twice a second while any crown exists: a hat or wings that stand taller lift it. Ends when the last crown is gone.
local function look()
	if looking then
		return
	end
	looking = true
	task.spawn(function()
		while next(entries) ~= nil do
			for _, entry in entries do
				local head, gui = entry.head, entry.gui
				if head and head.Parent and gui then
					local lift = liftOf(head)
					if math.abs(gui.StudsOffset.Y - lift) > 0.1 then
						gui.StudsOffset = Vector3.new(0, lift, 0)
					end
				end
			end
			task.wait(T.CheckSeconds)
		end
		looking = false
	end)
end

local function apply(player: Player)
	if player:GetAttribute("Vip") ~= true then
		remove(player)
		return
	end
	if entries[player] then
		return
	end
	local fresh: Entry = { player = player, head = nil, gui = nil, crown = nil, connections = {} }
	entries[player] = fresh
	table.insert(
		fresh.connections,
		player.CharacterAdded:Connect(function(character)
			fresh.head = nil
			clearVisuals(fresh)
			attachHead(fresh, character)
		end)
	)
	table.insert(
		fresh.connections,
		player.CharacterRemoving:Connect(function()
			fresh.head = nil
			clearVisuals(fresh)
		end)
	)
	-- (an Arena title that comes or goes moves the crown beside it)
	table.insert(
		fresh.connections,
		player:GetAttributeChangedSignal("ArenaRank"):Connect(function()
			place(fresh)
		end)
	)
	if player.Character then
		attachHead(fresh, player.Character)
	end
	look()
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Vip"):Connect(function()
		apply(player)
	end)
	apply(player)
end

Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(remove)
for _, player in Players:GetPlayers() do
	watch(player)
end
