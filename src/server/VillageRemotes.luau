--!strict
-- One throttled, validated command surface; all profile mutations go through PlayerData.update.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Breeding = require(ReplicatedStorage.Shared.Breeding)
local Config = require(ReplicatedStorage.Shared.Config)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Stations = require(ReplicatedStorage.Shared.Stations)
local VillageRules = require(ReplicatedStorage.Shared.Village)
local PlayerData = require(script.Parent.PlayerData)
local Village = require(script.Parent.Village)

local VillageRemotes = {}
local limits: { [Player]: { number } } = {}
local areaChanged: BindableEvent? = nil

local function integer(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge and n % 1 == 0
end

local function rateAllowed(player: Player): boolean
	-- A rolling window prevents a burst on either side of a whole-second boundary.
	local now = os.clock()
	local recent = limits[player]
	if not recent then
		recent = {}
		limits[player] = recent
	end
	for i = #recent, 1, -1 do
		if now - recent[i] >= Config.Village.TickSeconds then
			table.remove(recent, i)
		end
	end
	if #recent >= Config.Village.RequestsPerSecond then
		return false
	end
	table.insert(recent, now)
	return true
end

local function request(player: Player, data: any): { ok: boolean, reason: string? }
	if not PlayerData.isReady(player) then
		return { ok = false, reason = "NOT_READY" }
	end
	if not rateAllowed(player) then
		return { ok = false, reason = "RATE_LIMIT" }
	end
	if type(data) ~= "table" or type(data.action) ~= "string" then
		return { ok = false, reason = "BAD_REQUEST" }
	end
	local action = data.action
	local now = os.time()
	local ok = false
	local why: string? = "BAD_REQUEST"
	local upgradedLevel: number? = nil
	local areaId: string? = nil
	local valid = false

	if action == "SetPair" then
		valid = integer(data.index)
			and (data.a == nil or type(data.a) == "string")
			and (data.b == nil or type(data.b) == "string")
	elseif action == "Assign" then
		valid = type(data.area) == "string"
			and integer(data.slot)
			and type(data.slimeId) == "string"
			and type(data.asReserve) == "boolean"
	elseif action == "Unassign" then
		valid = type(data.slimeId) == "string"
	elseif action == "SetTrainingStat" then
		valid = integer(data.slot) and type(data.stat) == "string"
	elseif action == "SetCookedAllowed" then
		valid = type(data.slimeId) == "string" and type(data.allowed) == "boolean"
	elseif action == "UpgradeArea" then
		valid = type(data.areaId) == "string"
			and table.find(Config.Village.Areas, data.areaId) ~= nil
			and Village.ownsPlot(player)
	end
	if not valid then
		return { ok = false, reason = "INVALID_ARGUMENT" }
	end

	local success, err = pcall(function()
		local updated = PlayerData.update(player, function(farm: any)
			if action == "SetPair" then
				ok, why = Breeding.setPair(farm, data.index, data.a, data.b, now)
			elseif action == "Assign" then
				ok, why = Stations.assign(farm, data.slimeId, data.area, data.slot, data.asReserve, now)
			elseif action == "Unassign" then
				if not FarmState.findSlime(farm, data.slimeId) then
					why = "MISSING_SLIME"
					return
				end
				for _, area in Config.Work.Areas do
					for index, slot in (farm.work :: any)[area].slots do
						if slot.worker == data.slimeId then
							ok = Stations.unassign(farm, area, index, false)
						elseif slot.reserve == data.slimeId then
							ok = Stations.unassign(farm, area, index, true)
						end
						if ok then
							break
						end
					end
					if ok then
						break
					end
				end
				if not ok then
					why = "NOT_ASSIGNED"
				end
			elseif action == "SetTrainingStat" then
				ok = Stations.setTrainingStat(farm, data.slot, data.stat)
				if not ok then
					why = "INVALID_STAT_OR_SLOT"
				end
			elseif action == "SetCookedAllowed" then
				if not FarmState.findSlime(farm, data.slimeId) then
					why = "MISSING_SLIME"
					return
				end
				local index = table.find(farm.cookedAllowed, data.slimeId)
				if data.allowed and not index then
					table.insert(farm.cookedAllowed, data.slimeId)
				elseif not data.allowed and index then
					table.remove(farm.cookedAllowed, index)
				end
				ok = true
			elseif action == "UpgradeArea" then
				local free = Config.Pads.FreeUpgrades or (Config.Village.DevFreeUpgrades and RunService:IsStudio())
				ok, why = VillageRules.upgrade(farm, data.areaId, free)
				if ok then
					areaId = data.areaId
					upgradedLevel = (farm.areas :: any)[data.areaId].level
				end
			end
		end)
		if not updated then
			why = "NOT_READY"
			ok = false
		end
	end)
	if not success then
		warn(Config.LogPrefix, "village request failed:", err)
		return { ok = false, reason = "SERVER_ERROR" }
	end
	if ok and areaId and upgradedLevel then
		PlayerData.markKeyMoment(player, "village upgrade")
		local event = areaChanged
		if event then
			event:Fire(player, areaId, upgradedLevel)
		end
	end
	return { ok = ok, reason = if ok then nil else why }
end

-- E prompts use exactly the same saved, validated purchase as the remote.
function VillageRemotes.upgrade(player: Player, areaId: string): { ok: boolean, reason: string? }
	return request(player, { action = "UpgradeArea", areaId = areaId })
end

function VillageRemotes.start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local remote = remotes:FindFirstChild("Village")
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "Village"
		remote.Parent = remotes
	end
	assert(remote:IsA("RemoteFunction"), "Village remote must be a RemoteFunction")
	remote.OnServerInvoke = function(player: Player, data: any)
		return request(player, data)
	end
	local events = ServerStorage:FindFirstChild("VillageEvents")
	if not events then
		events = Instance.new("Folder")
		events.Name = "VillageEvents"
		events.Parent = ServerStorage
	end
	local changed = events:FindFirstChild("AreaLevelChanged")
	if not changed then
		changed = Instance.new("BindableEvent")
		changed.Name = "AreaLevelChanged"
		changed.Parent = events
	end
	assert(changed:IsA("BindableEvent"), "AreaLevelChanged must be a BindableEvent")
	areaChanged = changed
	Players.PlayerRemoving:Connect(function(player: Player)
		limits[player] = nil
	end)
end

return VillageRemotes
