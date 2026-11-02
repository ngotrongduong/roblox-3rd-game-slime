--!strict
-- One throttled, validated command surface; all profile mutations go through PlayerData.update.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Breeding = require(ReplicatedStorage.Shared.Breeding)
local Config = require(ReplicatedStorage.Shared.Config)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Stations = require(ReplicatedStorage.Shared.Stations)
local VillageRules = require(ReplicatedStorage.Shared.Village)
local Zombies = require(ReplicatedStorage.Shared.Zombies)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Village = require(script.Parent.Village)
local ZombieFights = require(script.Parent.ZombieFights)

local VillageRemotes = {}
local limits: { [Player]: { number } } = {}
local areaChanged: BindableEvent? = nil

local function integer(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge and n % 1 == 0
end

-- A team number: a whole number from 1 to the number of teams.
local function teamNumber(n: any): boolean
	return integer(n) and n >= 1 and n <= Config.Zombies.Teams
end

-- A plain list of text ids no longer than a team.
local function idList(value: any): boolean
	if type(value) ~= "table" or #value > Config.Zombies.TeamSize then
		return false
	end
	local count = 0
	for key, id in value do
		if type(key) ~= "number" or type(id) ~= "string" then
			return false
		end
		count += 1
	end
	return count == #value
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
	elseif action == "Unassign" or action == "Revive" or action == "Sell" then
		valid = type(data.slimeId) == "string"
	elseif action == "SetTrainingStat" then
		valid = integer(data.slot) and type(data.stat) == "string"
	elseif action == "SetCookedAllowed" then
		valid = type(data.slimeId) == "string" and type(data.allowed) == "boolean"
	elseif action == "UpgradeArea" then
		valid = type(data.areaId) == "string"
			and table.find(Config.Village.Areas, data.areaId) ~= nil
			and Plots.of(player) ~= nil
	elseif action == "SetTeam" then
		valid = teamNumber(data.team) and idList(data.slimeIds) and Plots.of(player) ~= nil
	elseif action == "SetTeamRepeat" then
		valid = teamNumber(data.team) and type(data.on) == "boolean" and Plots.of(player) ~= nil
	elseif action == "AttackGroup" then
		valid = teamNumber(data.team)
			and type(data.groupId) == "string"
			and #data.groupId <= Config.Zombies.TargetIdMaxLength
			and Plots.of(player) ~= nil
	end
	if not valid then
		return { ok = false, reason = "INVALID_ARGUMENT" }
	end

	-- The slime buyer's counter in the Market: the player must stand at it (they walked or travelled there).
	local atMarket = action == "Sell"
		and ZombieFights.near(player, Layout.marketPoint(Config.Market.Buyer), Config.Zombies.ShopRangeStuds)

	local success, err = pcall(function()
		local updated = PlayerData.update(player, function(farm: any)
			if action == "SetPair" then
				if (data.a and Village.isOut(player, data.a)) or (data.b and Village.isOut(player, data.b)) then
					why = "OUT"
					return
				end
				ok, why = Breeding.setPair(farm, data.index, data.a, data.b, now)
			elseif action == "Assign" then
				if Village.isOut(player, data.slimeId) then
					why = "OUT"
					return
				end
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
			elseif action == "SetTeam" then
				-- the line-ups are set at the village gate, never while that team is out
				if not ZombieFights.nearGate(player) then
					why = "TOO_FAR"
					return
				elseif ZombieFights.teamOut(player, data.team) then
					why = "TEAM_OUT"
					return
				end
				ok, why = Zombies.setTeam(farm, data.team, data.slimeIds, now, function(id: string): boolean
					return Village.isOut(player, id)
				end)
				if ok then
					print(Config.LogPrefix, "zombies: team", data.team, "line-up", table.concat(data.slimeIds, ","))
				end
			elseif action == "SetTeamRepeat" then
				local team = farm.teams[data.team]
				if data.on and #team.members == 0 then
					why = "NO_MEMBERS"
					return
				end
				team.repeatOn = data.on
				ok = true
				print(Config.LogPrefix, "zombies: team", data.team, "repeat", if data.on then "on" else "off")
			elseif action == "AttackGroup" then
				ok, why = ZombieFights.attack(player, farm, data.team, data.groupId, now)
			elseif action == "Revive" then
				if Village.isOut(player, data.slimeId) then
					why = "OUT"
					return
				end
				ok, why = Zombies.revive(farm, data.slimeId, now)
				if ok then
					ZombieFights.clearWounds(player, data.slimeId)
				end
			elseif action == "Sell" then
				if not atMarket then
					why = "TOO_FAR"
					return
				elseif Village.isOut(player, data.slimeId) then
					why = "OUT"
					return
				end
				local value, reason = Shop.sell(farm, data.slimeId, now)
				ok, why = value ~= nil, reason
				if value then
					print(Config.LogPrefix, "shop: sold", data.slimeId, "for", value)
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
	-- The owner's rule (2026-10-29): an assigned worker appears at its work place at once and starts working.
	if ok and action == "Assign" and data.asReserve == false then
		Village.placeAtWork(player, data.slimeId, data.area, data.slot)
	end
	if ok and (action == "Revive" or action == "Sell") then
		if action == "Revive" then
			print(Config.LogPrefix, "zombies: revived", data.slimeId)
		end
		PlayerData.markKeyMoment(player, string.lower(action))
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
