--!strict
-- The game-facing side of player profiles. Every system reads a player's data with get, changes it
-- only with update, and calls markKeyMoment after a hatch, breed, sell, buy or run end so it is
-- saved within seconds. Writes otherwise happen every Config.Save.AutosaveSeconds while something
-- changed, on leave and on shutdown: never constantly, never lost. Nothing can be sold or granted
-- before a player's data has loaded: get returns nil and update refuses until then.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local ProfileLogic = require(ReplicatedStorage.Shared.ProfileLogic)
local ProfileStore = require(script.Parent.ProfileStore)

local Save = Config.Save
local PREFIX = Config.LogPrefix

-- Shown when a player is kicked rather than given a farm we are unsure of.
local KICK_MESSAGES: { [string]: string } = {
	locked = "Your farm is still being saved by another server. Please rejoin in a minute - nothing is lost.",
	newerSchema = "Your farm was saved by a newer version of the game. Please rejoin to get a new server - nothing is lost.",
	corrupt = "Your farm's save could not be read, so we left it untouched. Please rejoin; if it keeps happening, tell us.",
	storeDown = "Roblox's save servers did not answer, so your farm was not loaded (to keep it safe). Please rejoin in a minute.",
	closing = "This server is shutting down. Please rejoin - your farm is safe.",
	lockLost = "Your farm was opened in another server.",
}

type ReadyCallback = (player: Player, data: any) -> ()
type LeavingCallback = (player: Player, data: any) -> ()

local PlayerData = {}

local store: ProfileStore.Store? = nil
local profiles: { [Player]: ProfileStore.Profile } = {}
local readyCallbacks: { ReadyCallback } = {}
local leavingCallbacks: { LeavingCallback } = {}

local function keyFor(player: Player): string
	return Save.KeyPrefix .. tostring(player.UserId)
end

local function runCallback(what: string, fn: (...any) -> ...any, ...: any)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn(PREFIX, what, "callback failed:", err)
	end
end

-- The real DataStore on live servers. In Studio without API access (or an unpublished place) an
-- in-memory store, loudly, so testing still works; a live server never falls back.
local function openDataStore(): (ProfileStore.DataStoreLike, boolean)
	local isStudio = RunService:IsStudio()
	if isStudio and game.PlaceId == 0 then
		warn(PREFIX, "unpublished place: using an in-memory store, progress in this test is NOT saved")
		return ProfileStore.memoryStore(), false
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Save.StoreName)
	end)
	if ok and isStudio then
		ok, result = pcall(function()
			result:GetAsync("__studio_probe")
			return result
		end)
	end
	if not ok then
		if isStudio then
			warn(
				PREFIX,
				"no DataStore access in Studio (turn on 'Enable Studio Access to API Services' to test real saves):",
				result,
				"- using an in-memory store, progress in this test is NOT saved"
			)
			return ProfileStore.memoryStore(), false
		end
		error(PREFIX .. " could not open the DataStore: " .. tostring(result))
	end
	return (result :: any) :: ProfileStore.DataStoreLike, true
end

local function budget(): number
	return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)
end

local function playerOf(profile: ProfileStore.Profile): Player?
	for player, p in profiles do
		if p == profile then
			return player
		end
	end
	return nil
end

local function onPlayerAdded(player: Player)
	local s = store
	if s == nil then
		return
	end
	local profile, reason = s.load(keyFor(player), { player.UserId })
	if profile == nil then
		local why = reason or "storeDown"
		warn(PREFIX, player.Name, "data not loaded:", why)
		if player.Parent == Players then
			player:Kick(KICK_MESSAGES[why] or KICK_MESSAGES.storeDown)
		end
		return
	end
	if player.Parent ~= Players then
		-- Left while the load waited: give the profile straight back.
		s.release(profile)
		return
	end
	profiles[player] = profile
	for _, callback in readyCallbacks do
		task.spawn(runCallback, "onReady", callback, player, profile.data)
	end
end

local function onPlayerRemoving(player: Player)
	local s = store
	local profile = profiles[player]
	if s == nil or profile == nil then
		return
	end
	-- Systems write their last state (through update) before the final write.
	for _, callback in leavingCallbacks do
		runCallback("onLeaving", callback, player, profile.data)
	end
	profiles[player] = nil
	-- A failed release stays in the store and is retried by its step (and by BindToClose).
	s.release(profile)
end

-- Called with (player, data) once a player's data has loaded (also for players already loaded).
function PlayerData.onReady(callback: ReadyCallback)
	table.insert(readyCallbacks, callback)
	for player, profile in profiles do
		task.spawn(runCallback, "onReady", callback, player, profile.data)
	end
end

-- Called with (player, data) when a loaded player leaves, before the final write.
function PlayerData.onLeaving(callback: LeavingCallback)
	table.insert(leavingCallbacks, callback)
end

-- The player's data, or nil while it is not loaded. Read only: change it with update.
function PlayerData.get(player: Player): any
	local profile = profiles[player]
	return if profile then profile.data else nil
end

function PlayerData.isReady(player: Player): boolean
	return profiles[player] ~= nil
end

-- The only way to change a player's data. fn changes the table it is given in place. Returns false
-- (and does nothing) while the data is not loaded, so nothing is granted before load.
function PlayerData.update(player: Player, fn: (data: any) -> ()): boolean
	local s = store
	local profile = profiles[player]
	if s == nil or profile == nil or profile.lost then
		return false
	end
	local ok, err = pcall(fn :: (any) -> ...any, profile.data)
	-- Even a failed change may have touched the data: it is saved like any other change.
	s.markDirty(profile)
	if not ok then
		error(err, 2)
	end
	return true
end

-- Something worth keeping happened (hatch, breed, sell, buy, run end): write within a few seconds,
-- one write for a burst of moments.
function PlayerData.markKeyMoment(player: Player, reason: string)
	local s = store
	local profile = profiles[player]
	if s and profile then
		s.markKeyMoment(profile, reason)
	end
end

-- Starts profiles with the farm rules' hooks. Called once by Main.
function PlayerData.start(hooks: ProfileLogic.Hooks)
	assert(store == nil, "PlayerData.start called twice")
	local dataStore, isReal = openDataStore()
	local s = ProfileStore.new({
		store = dataStore,
		hooks = hooks,
		jobId = if game.JobId ~= "" then game.JobId else "studio",
		placeId = game.PlaceId,
		now = os.time,
		wait = function(seconds: number)
			task.wait(seconds)
		end,
		spawn = function(fn: () -> ())
			task.spawn(fn)
		end,
		budget = if isReal then budget else nil,
		log = function(message: string)
			warn(message)
		end,
		onLost = function(profile: ProfileStore.Profile)
			local player = playerOf(profile)
			if player then
				profiles[player] = nil
				player:Kick(KICK_MESSAGES.lockLost)
			end
		end,
	})
	store = s

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(Save.TickSeconds)
			s.step()
		end
	end)

	game:BindToClose(function()
		-- Players still here get their leaving callbacks first, so their last state is in the write.
		for player, profile in profiles do
			for _, callback in leavingCallbacks do
				runCallback("onLeaving", callback, player, profile.data)
			end
			profiles[player] = nil
		end
		if not s.closeAll(Save.ShutdownSeconds) then
			warn(PREFIX, "some profiles were not saved before shutdown")
		end
	end)
	print(PREFIX, "player profiles ready (" .. (if isReal then "DataStore" else "in-memory") .. ")")
end

return PlayerData
