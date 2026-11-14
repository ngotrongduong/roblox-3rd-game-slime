--!strict
-- Quick travel: the HUD's Home and Market buttons and the map's waystones. The client asks (Remotes.Travel, { action =
-- "Market" | "Home" }, or { action = "Zone", zone = id } for the waystone of a zone the player has won); the
-- server checks who asks, that their farm is loaded, that they are alive and that their last move was Travel's cooldown ago,
-- then moves the character (Travel.destination). It touches no player data, carried items or marching teams: they follow the
-- character or do not depend on where it stands. Answers { ok, reason }.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Travel = require(ReplicatedStorage.Shared.Travel)
local Dungeon = require(script.Parent.Dungeon)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local ZoneFights = require(ReplicatedStorage.Shared.ZoneFights)
local ZoneGuards = require(script.Parent.ZoneGuards)

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
	-- (the arena keeps its player in: a move out of a run was pulled back a moment later)
	if Dungeon.inRun(player) then
		return { ok = false, reason = "IN_DUNGEON" }
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
	local destination: CFrame?, why: string? = nil, nil
	if action == "Zone" then
		-- a zone's waystone, open once its guard is beaten
		local farm = PlayerData.get(player)
		why = if farm then ZoneFights.travelBlock(farm.world.beaten, data.zone) else "NOT_READY"
		if not why then
			destination = ZoneGuards.landing(data.zone, Config.Travel.LiftStuds)
			-- (the land there may not be with this player yet; the wait counts as the move, so a second press finds the
			-- cooldown)
			lastAt[player] = now
			pcall(player.RequestStreamAroundAsync, player, (destination :: CFrame).Position)
			if character.Parent == nil or humanoid.Health <= 0 then
				return { ok = false, reason = "DEAD" }
			end
		end
	else
		destination, why = Travel.destination(action, Plots.of(player))
	end
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
