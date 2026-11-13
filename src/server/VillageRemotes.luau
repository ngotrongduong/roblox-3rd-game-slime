--!strict
-- One throttled, validated command surface; all profile mutations go through PlayerData.update.
-- The rules themselves are in shared/VillageRequests, where the tests hold them.
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local VillageRequests = require(ReplicatedStorage.Shared.VillageRequests)
local Dungeon = require(script.Parent.Dungeon)
local Guide = require(script.Parent.Guide)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Purchases = require(script.Parent.Purchases)
local Rewards = require(script.Parent.Rewards)
local Village = require(script.Parent.Village)
local ZombieFights = require(script.Parent.ZombieFights)

local VillageRemotes = {}
local limits: { [Player]: { number } } = {}
local areaChanged: BindableEvent? = nil

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

-- Whether the player is in the owner's group (Config.Social.GroupId). The server may keep the answer it had when the player
-- came in, so a "no" is asked again from the player's list of groups (a join made a moment ago in Roblox's prompt shows
-- there).
local function inGroup(player: Player): boolean
	local id = Config.Social.GroupId
	if id <= 0 then
		return false
	end
	local ok, member = pcall(function(): boolean
		return player:IsInGroupAsync(id)
	end)
	if ok and member then
		return true
	end
	local listed, groups = pcall(function(): any
		return GroupService:GetGroupsAsync(player.UserId)
	end)
	if listed and type(groups) == "table" then
		for _, group in groups do
			if type(group) == "table" and group.Id == id then
				return true
			end
		end
	end
	return false
end

-- A community reward's claim asks Roblox's web services: once every CheckCooldownSeconds a player.
local socialAt: { [Player]: number } = {}

-- What the rules need to know about this player that only the server can see. `social`: the proof of a community reward,
-- found before the save is opened (asking Roblox yields).
local function envOf(player: Player, social: boolean?): VillageRequests.Env
	return {
		socialDone = function(): boolean
			return social == true
		end,
		isOut = function(slimeId: string): boolean
			return Village.isOut(player, slimeId)
		end,
		-- The slime buyer's counter in the Market: the player must stand at it (they walked or travelled there).
		atMarket = function(): boolean
			return ZombieFights.near(player, Layout.marketPoint(Config.Market.Buyer), Config.Zombies.ShopRangeStuds)
		end,
		-- The Blacksmith's stall in the Market: the sheet stays open within SmithyRangeStuds, a craft takes the slack too.
		atSmithy = function(): boolean
			return ZombieFights.near(
				player,
				Layout.marketPoint(Config.Market.Smithy),
				Config.Market.SmithyRangeStuds + Config.Market.SmithyRangeSlackStuds
			)
		end,
		teamOut = function(team: number): boolean
			return ZombieFights.teamOut(player, team)
		end,
		attack = function(farm: any, team: number, groupId: string, now: number): (boolean, string?)
			return ZombieFights.attack(player, farm, team, groupId, now)
		end,
		clearWounds = function(slimeId: string)
			ZombieFights.clearWounds(player, slimeId)
		end,
		freeUpgrades = Config.Pads.FreeUpgrades or (Config.Village.DevFreeUpgrades and RunService:IsStudio()),
		unsavedPlay = function(): number
			return Rewards.unsavedPlay(player)
		end,
		userId = player.UserId,
		-- (the wheel's roll: every spin its own random seed, rolled on the server)
		seed = function(): number
			return Random.new():NextInteger(1, 2147483646)
		end,
		-- (no VIP pass is on sale yet; the Robux code answers here later)
		isVip = function(): boolean
			return Rewards.isVip(player)
		end,
	}
end

local function request(player: Player, data: any): { ok: boolean, reason: string?, value: number? }
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
	if not VillageRequests.valid(data, Plots.of(player) ~= nil) then
		return { ok = false, reason = "INVALID_ARGUMENT" }
	end
	-- The Slime Dungeon's requests run the arena (server/Dungeon), which checks where the player stands, what they own and
	-- how often they ask.
	if string.sub(action, 1, 7) == "Dungeon" then
		local done, result = pcall(Dungeon.request, player, data)
		if not done then
			warn(Config.LogPrefix, "dungeon request failed:", result)
			return { ok = false, reason = "SERVER_ERROR" }
		end
		return { ok = result.ok, reason = result.reason, value = nil }
	end
	-- A community reward: the group is checked with Roblox here; a favorite cannot be seen by a server, the client's word
	-- is taken (shared/Social).
	local social: boolean? = nil
	if action == "ClaimSocial" then
		local last = socialAt[player]
		if last and os.clock() - last < Config.Social.CheckCooldownSeconds then
			return { ok = false, reason = "RATE_LIMIT" }
		end
		socialAt[player] = os.clock()
		social = if data.kind == "group" then inGroup(player) else true
	end
	local now = os.time()
	local ok = false
	local why: string? = "NOT_READY"
	local value: number? = nil
	local upgradedLevel: number? = nil

	local success, err = pcall(function()
		PlayerData.update(player, function(farm: any)
			ok, why, value = VillageRequests.run(farm, data, now, envOf(player, social))
			if ok and action == "UpgradeArea" then
				upgradedLevel = (farm.areas :: any)[data.areaId].level
			end
		end)
	end)
	if not success then
		warn(Config.LogPrefix, "village request failed:", err)
		return { ok = false, reason = "SERVER_ERROR" }
	end
	if not ok then
		return { ok = false, reason = why }
	end
	if action == "Sell" then
		print(Config.LogPrefix, "shop: sold", data.slimeId, "for", value)
	elseif action == "SellMany" then
		print(Config.LogPrefix, "shop: sold", #data.slimeIds, "slimes for", value)
	elseif action == "SellDish" then
		print(Config.LogPrefix, "shop: sold dish", data.dish, "for", value)
	elseif action == "SetTeam" then
		print(Config.LogPrefix, "zombies: team", data.team, "line-up", table.concat(data.slimeIds, ","))
	elseif action == "SetTeamRepeat" then
		print(Config.LogPrefix, "zombies: team", data.team, "repeat", if data.on then "on" else "off")
	elseif action == "Revive" then
		print(Config.LogPrefix, "zombies: revived", data.slimeId)
	elseif action == "SmithyCraft" then
		print(Config.LogPrefix, "smithy:", player.Name, "crafted", data.recipeId)
		PlayerData.markKeyMoment(player, "smithy craft")
	elseif action == "GearEquip" then
		print(Config.LogPrefix, "gear:", player.Name, "put", data.gearId, "on", data.slimeId)
		PlayerData.markKeyMoment(player, "gear equip")
	elseif action == "GearUnequip" then
		print(Config.LogPrefix, "gear:", player.Name, "took", data.slot, "off", data.slimeId)
		PlayerData.markKeyMoment(player, "gear unequip")
	elseif action == "GuideSkip" or action == "GuideSeen" or action == "GuideNext" then
		print(Config.LogPrefix, "guide:", player.Name, action, data.step or "")
		PlayerData.markKeyMoment(player, "guide")
	elseif action == "WheelSpin" then
		local slice = Config.Wheel.Slices[value or 0]
		print(Config.LogPrefix, "wheel:", player.Name, "spun, slice", value or 0, slice and slice.id or "?")
		PlayerData.markKeyMoment(player, "wheel spin")
		task.spawn(Rewards.refresh, player)
	elseif action == "UseBanked" then
		print(Config.LogPrefix, "purchases:", player.Name, "used a banked", data.key)
		PlayerData.markKeyMoment(player, "robux banked use")
		task.spawn(Purchases.refresh, player)
	elseif action == "RerollQuest" then
		print(Config.LogPrefix, "rewards:", player.Name, "redrew daily quest", data.index)
		PlayerData.markKeyMoment(player, "rewards")
		task.spawn(Rewards.refresh, player)
	elseif string.sub(action, 1, 5) == "Claim" or action == "IndexSeen" then
		print(
			Config.LogPrefix,
			"rewards:",
			player.Name,
			action,
			data.index or data.step or data.id or data.kind or "",
			"paid",
			value or 0
		)
		PlayerData.markKeyMoment(player, "rewards")
		task.spawn(Rewards.refresh, player)
	end
	-- The owner's rule (2026-10-29): an assigned worker appears at its work place at once and starts working.
	if action == "Assign" and data.asReserve == false then
		Village.placeAtWork(player, data.slimeId, data.area, data.slot)
	end
	if
		action == "Revive"
		or action == "Sell"
		or action == "SellMany"
		or action == "SellDish"
		or action == "FeedDish"
	then
		PlayerData.markKeyMoment(player, string.lower(action))
	end
	if upgradedLevel then
		PlayerData.markKeyMoment(player, "village upgrade")
		local event = areaChanged
		if event then
			event:Fire(player, data.areaId, upgradedLevel)
		end
	end
	-- (the tutorial's line moves on at once after what the player did, not at the next look)
	task.spawn(Guide.refresh, player)
	return { ok = true, value = value }
end

-- E prompts use exactly the same saved, validated purchase as the remote.
function VillageRemotes.upgrade(player: Player, areaId: string): { ok: boolean, reason: string?, value: number? }
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
		socialAt[player] = nil
	end)
end

return VillageRemotes
