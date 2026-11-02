--!strict
-- Quick travel: the HUD's Home and Market buttons. The client asks (Remotes.Travel, { action = "Market" | "Home" }); the
-- server checks who asks, that their farm is loaded, that they are alive and that their last move was Travel's cooldown ago,
-- then moves the character (Travel.destination). It touches no player data, carried items or marching teams: they follow the
-- character or do not depend on where it stands. Answers { ok, reason }.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Travel = require(ReplicatedStorage.Shared.Travel)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)

local QuickTravel = {}
-- server time of each player's last move
local lastAt: { [Player]: number } = {}

local function request(player: Player, data: any): { ok: boolean, reason: string? }
	if type(data) ~= "table" or not Travel.isPlace(data.action) then
		return { ok = false, reason = "BAD_REQUEST" }
	end
	local action: string = data.action
	if not PlayerData.isReady(player) then
		return { ok = false, reason = "NOT_READY" }
	end
	local now = workspace:GetServerTimeNow()
	if Travel.cooldownLeft(lastAt[player], now) > 0 then
		return { ok = false, reason = "COOLDOWN" }
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return { ok = false, reason = "DEAD" }
	end
	local destination, why = Travel.destination(action, Plots.of(player))
	if not destination then
		return { ok = false, reason = why or "BAD_REQUEST" }
	end
	lastAt[player] = now
	humanoid.Sit = false
	character:PivotTo(destination)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	print(Config.LogPrefix, "travel:", player.Name, "->", action)
	return { ok = true, reason = nil }
end

function QuickTravel.start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local remote = remotes:FindFirstChild("Travel")
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "Travel"
		remote.Parent = remotes
	end
	assert(remote:IsA("RemoteFunction"), "Travel remote must be a RemoteFunction")
	remote.OnServerInvoke = function(player: Player, data: any)
		return request(player, data)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		lastAt[player] = nil
	end)
end

return QuickTravel
