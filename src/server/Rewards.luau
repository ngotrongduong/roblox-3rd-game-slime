--!strict
-- Runs the rewards for coming back (rules in shared/Rewards): once a second it makes the day's quests when there are none,
-- writes the minutes played into the save every Config.Rewards.OnlineFlushSeconds (and when the player leaves), and
-- publishes on the player's village folder what the client draws: Rewards (JSON of Rewards.view), RewardsReady (how many
-- wait), RewardsOpen (after the tutorial), OnlineSince (the server time today's clock would have started), LuckUntil (the
-- luck potion's end, 0 for none), Found (JSON of the kinds of slime found, for the Index) and IndexGift (the coins the Index
-- just paid for a new find, for a toast). Claims come through the
-- Village remote (shared/VillageRequests).
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Hatching = require(ReplicatedStorage.Shared.Hatching)
local RewardRules = require(ReplicatedStorage.Shared.Rewards)
local PlayerData = require(script.Parent.PlayerData)
local Village = require(script.Parent.Village)

local Rewards = {}

-- The server time each player's play was last written into the save.
local flushedAt: { [Player]: number } = {}
-- The last Found count published, so the list is encoded only when it grows.
local foundCount: { [Player]: number } = {}
-- The kinds found at the last look, and how many gifts have been announced (announceFinds).
local foundSeen: { [Player]: { [string]: string } } = {}
local giftCount: { [Player]: number } = {}

local function set(inst: Instance, name: string, value: any)
	if inst:GetAttribute(name) ~= value then
		inst:SetAttribute(name, value)
	end
end

-- Seconds played since the last write; asking takes them (the caller adds them to the save).
function Rewards.unsavedPlay(player: Player): number
	local now = os.time()
	local last = flushedAt[player]
	flushedAt[player] = now
	return if last then math.max(0, now - last) else 0
end

-- Every kind found, as "bucket/id" keys.
local function foundKeys(farm: any): { [string]: string }
	local keys: { [string]: string } = {}
	for _, bucket in { "base", "dual", "secret", "material" } do
		for id in farm.discoveries[bucket] do
			keys[bucket .. "/" .. id] = if bucket == "base" then "plain" else bucket
		end
	end
	return keys
end

-- A find the player has just made (the Index already paid for it, in shared/Hatching): the toast's number goes out as the
-- village folder's IndexGift (JSON { n, coins }); n counts up so the client can tell a new gift from the old one. The first
-- look after joining only learns what is already found, so finds made while away are not announced again.
local function announceFinds(player: Player, root: Folder, farm: any)
	local keys = foundKeys(farm)
	local known = foundSeen[player]
	foundSeen[player] = keys
	if not known then
		return
	end
	local coins = 0
	for key, kind in keys do
		if not known[key] then
			coins += Hatching.discoveryCoins(kind)
		end
	end
	if coins > 0 then
		giftCount[player] = (giftCount[player] or 0) + 1
		set(root, "IndexGift", HttpService:JSONEncode({ n = giftCount[player], coins = coins }))
	end
end

local function foundList(farm: any): string
	local out = {}
	for _, kind in { "base", "dual", "secret", "material" } do
		local ids = {}
		for id in farm.discoveries[kind] do
			table.insert(ids, id)
		end
		table.sort(ids)
		out[kind] = ids
	end
	return HttpService:JSONEncode(out)
end

-- Makes today's quests, writes the play time when due, then publishes. Safe to call at any time.
function Rewards.refresh(player: Player)
	local root = Village.rootOf(player)
	local farm = PlayerData.get(player)
	if not root or not farm or not PlayerData.isReady(player) then
		return
	end
	local now = os.time()
	local due = now - (flushedAt[player] or now) >= Config.Rewards.OnlineFlushSeconds
	local fresh = farm.tutorialDone ~= false
		and (farm.rewards.quests.day ~= RewardRules.dayOf(now) or #farm.rewards.quests.list == 0)
	if due or fresh then
		PlayerData.update(player, function(live: any)
			if due then
				RewardRules.addPlayed(live, now, Rewards.unsavedPlay(player))
			end
			if RewardRules.ensureQuests(live, player.UserId, now) then
				print(Config.LogPrefix, "rewards:", player.Name, "has new quests")
			end
		end)
		farm = PlayerData.get(player)
		if not farm then
			return
		end
	end
	local unsaved = now - (flushedAt[player] or now)
	local played = RewardRules.played(farm, now) + unsaved
	set(root, "Rewards", HttpService:JSONEncode(RewardRules.view(farm, now)))
	set(root, "RewardsReady", RewardRules.ready(farm, now, unsaved))
	set(root, "RewardsOpen", farm.tutorialDone ~= false)
	set(root, "IndexSeen", farm.rewards.indexSeen)
	set(root, "OnlineSince", now - played)
	set(root, "LuckUntil", if farm.luckPotionUntil and farm.luckPotionUntil > now then farm.luckPotionUntil else 0)
	local count = RewardRules.found(farm)
	if foundCount[player] ~= count or root:GetAttribute("Found") == nil then
		foundCount[player] = count
		set(root, "Found", foundList(farm))
		announceFinds(player, root, farm)
	end
end

function Rewards.start()
	PlayerData.onReady(function(player: Player, _data: any)
		flushedAt[player] = os.time()
	end)
	PlayerData.onLeaving(function(player: Player, _data: any)
		PlayerData.update(player, function(live: any)
			RewardRules.addPlayed(live, os.time(), Rewards.unsavedPlay(player))
		end)
		flushedAt[player] = nil
		foundCount[player] = nil
		foundSeen[player] = nil
		giftCount[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Rewards.CheckSeconds)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(function(): any
					Rewards.refresh(player)
					return nil
				end)
				if not ok then
					warn(Config.LogPrefix, "rewards failed for", player.Name, err)
				end
			end
		end
	end)
end

return Rewards
