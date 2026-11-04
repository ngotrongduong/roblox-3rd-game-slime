--!strict
-- THE OWNER'S DEBUG MENU, server side. Studio only: Main starts this module only when RunService:IsStudio(), the remote
-- handler checks it again, and tools/build_publish.luau strips this file from the published place (and fails if it stays).
-- The client asks (Remotes.Debug, { action, args }); the server changes ONLY the asker's own farm through PlayerData.update
-- (DebugPresets does the changing, in place, with the game's own rules), keeps one level of undo in memory, tells the world
-- (areas, village, guide, rewards) and saves soon. Answers { ok, text }.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DebugPresets = require(ReplicatedStorage.Shared.DebugPresets)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Layout = require(ReplicatedStorage.Shared.Layout)
local ProfileLogic = require(ReplicatedStorage.Shared.ProfileLogic)
local Travel = require(ReplicatedStorage.Shared.Travel)
local Dungeon = require(script.Parent.Dungeon)
local Guide = require(script.Parent.Guide)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Rewards = require(script.Parent.Rewards)
local ZombieFights = require(script.Parent.ZombieFights)

-- Debug numbers (the owner's Config belongs to others, so they live here).
local MIN_GAP = 0.25 -- seconds between two taps of one player (the menu is a person pressing buttons)

local OwnerDebug = {}
-- server time of each player's last tap
local lastAt: { [Player]: number } = {}
-- the farm as it was before the player's last preset or fresh farm: one level of undo
local snapshots: { [Player]: any } = {}

local function reply(ok: boolean, text: string): { ok: boolean, text: string }
	return { ok = ok, text = text }
end

-- Whether a squad of the farm is away from home (marching or fighting): changing the farm under it would strand it.
local function teamAway(player: Player, farm: any): boolean
	for index, team in farm.teams do
		if #team.members > 0 and ZombieFights.teamOut(player, index) then
			return true
		end
	end
	return false
end

-- The farm's area levels, to tell the world which ones changed.
local function areaLevels(farm: any): { [string]: number }
	local out: { [string]: number } = {}
	for _, id in Config.Village.Areas do
		out[id] = farm.areas[id].level
	end
	return out
end

-- Everything that has to look at the new farm: the area stages (with their reveal), the village's paths and spots, the guide's
-- line, the rewards' badge. The village sessions reconcile slimes and eggs on their own every tick.
local function worldFollows(player: Player, before: { [string]: number })
	local farm = PlayerData.get(player)
	if not farm then
		return
	end
	local events = game:GetService("ServerStorage"):FindFirstChild("VillageEvents")
	local changed = if events then events:FindFirstChild("AreaLevelChanged") else nil
	if changed and changed:IsA("BindableEvent") then
		for _, id in Config.Village.Areas do
			local level = farm.areas[id].level
			if level ~= before[id] then
				changed:Fire(player, id, level)
			end
		end
	end
	Guide.refresh(player)
	Rewards.refresh(player)
	PlayerData.markKeyMoment(player, "debug")
end

-- Puts `source` in place of the farm, in place (the table is the profile's own): old keys go, new ones come.
local function replaceFarm(data: any, source: any)
	for key in data do
		data[key] = nil
	end
	local copy = ProfileLogic.deepCopy(source)
	for key, value in copy do
		data[key] = value
	end
end

local function moveTo(player: Player, action: string): { ok: boolean, text: string }
	if Dungeon.inRun(player) then
		return reply(false, "Leave the Dungeon first")
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return reply(false, "Your character is not here")
	end
	local destination: CFrame?
	if action == "Portal" then
		destination = Layout.portalLanding()
	elseif Travel.isPlace(action) then
		destination = Travel.destination(action, Plots.of(player))
	end
	if not destination then
		return reply(false, "No such place")
	end
	humanoid.Sit = false
	character:PivotTo(destination)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return reply(true, "Moved to " .. action)
end

local function request(player: Player, data: any): { ok: boolean, text: string }
	if not RunService:IsStudio() then
		return reply(false, "Studio only")
	end
	if type(data) ~= "table" or type(data.action) ~= "string" then
		return reply(false, "Bad request")
	end
	if not PlayerData.isReady(player) then
		return reply(false, "Your farm is not loaded yet")
	end
	local nowClock = os.clock()
	local last = lastAt[player]
	if last and nowClock - last < MIN_GAP then
		return reply(false, "Too fast")
	end
	lastAt[player] = nowClock
	local action: string = data.action
	local kind: string? = nil
	for _, group in DebugPresets.Menu do
		for _, item in group.items do
			if item.id == action then
				kind = item.kind
			end
		end
	end
	if kind == nil then
		return reply(false, "Unknown action")
	end
	print(Config.LogPrefix, "debug:", action, "(" .. player.Name .. ")")
	if kind == "travel" then
		return moveTo(player, action)
	end
	-- Everything below changes the farm.
	if Dungeon.inRun(player) then
		return reply(false, "Leave the Dungeon first")
	end
	local farm = PlayerData.get(player)
	if teamAway(player, farm) then
		return reply(false, "Bring your teams home first")
	end
	local before = areaLevels(farm)
	local now = os.time()
	local text = ""
	local ok = true
	local flag = true
	if kind == "undo" then
		local snapshot = snapshots[player]
		if not snapshot then
			return reply(false, "Nothing to undo")
		end
		snapshots[player] = nil
		PlayerData.update(player, function(live: any)
			replaceFarm(live, snapshot)
		end)
		text = "Undone"
	elseif kind == "fresh" then
		local keep = ProfileLogic.deepCopy(farm)
		PlayerData.update(player, function(live: any)
			replaceFarm(live, FarmState.newFarm(now))
		end)
		snapshots[player] = keep
		text = "Fresh farm"
	else
		-- A change that may fail leaves the farm as it was; the snapshot is kept only when something changed.
		local keep = ProfileLogic.deepCopy(farm)
		PlayerData.update(player, function(live: any)
			ok, text = DebugPresets.run(live, action, now, data.args)
			flag = ok
		end)
		if flag then
			snapshots[player] = keep
			if action == "timers" then
				for _, slime in PlayerData.get(player).slimes do
					ZombieFights.clearWounds(player, slime.id)
				end
			end
		end
	end
	if ok then
		worldFollows(player, before)
	end
	return reply(ok, text)
end

function OwnerDebug.start()
	assert(RunService:IsStudio(), "OwnerDebug must only start in Studio")
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local remote = remotes:FindFirstChild("Debug")
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "Debug"
		remote.Parent = remotes
	end
	assert(remote:IsA("RemoteFunction"), "Debug remote must be a RemoteFunction")
	remote.OnServerInvoke = function(player: Player, data: any)
		local ok, answer = pcall(request, player, data)
		if not ok then
			warn(Config.LogPrefix, "debug failed:", answer)
			return reply(false, "Failed, see the output")
		end
		return answer
	end
	-- The client draws the menu's button only for players carrying this attribute.
	local function mark(player: Player)
		player:SetAttribute("DebugMenu", true)
	end
	Players.PlayerAdded:Connect(mark)
	for _, player in Players:GetPlayers() do
		mark(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		lastAt[player] = nil
		snapshots[player] = nil
	end)
	print(Config.LogPrefix, "debug menu on (Studio only)")
end

return OwnerDebug
