--!strict
-- The leaderboard of the Market: the top Config.Leaderboard.Rows slimes of the whole game by level, one a player
-- (docs/MAP.md 1.3). The server reads each player's farm (a client can claim nothing), sends a player's best to the stores
-- when it improved (at most once a minute a player, and when they leave), reads the top every minute and merges the players
-- of THIS server in with their live bests, so the board works with no store at all. A Studio play test keeps it in memory.
-- Published: ReplicatedStorage.<Config.Leaderboard.Folder> with attributes Count and Row1..RowN, each
-- "player<TAB>slime<TAB>level" in board order (Leaderboard.decodeRow); the client's LeaderboardScreen draws them.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Board = require(ReplicatedStorage.Shared.Leaderboard)
local LeaderboardStore = require(script.Parent.LeaderboardStore)
local PlayerData = require(script.Parent.PlayerData)

local L = Config.Leaderboard
local PREFIX = Config.LogPrefix

-- What this server knows of a player's best: the last level sent to the stores (and when), and the live best with the
-- second it was first seen.
type Tracked = { sentLevel: number, sentAt: number?, level: number, slime: string, since: number }

local Leaderboard = {}
local tracked: { [Player]: Tracked } = {}
local store: LeaderboardStore.Store? = nil
local folder: Folder? = nil
local stored: { LeaderboardStore.Entry } = {}
local published = ""
-- sends in flight (shutdown waits for them)
local pending = 0

local function openStores(): (LeaderboardStore.OrderedLike, LeaderboardStore.NamesLike, boolean)
	if RunService:IsStudio() and not L.StudioUsesRealStore then
		print(PREFIX, "leaderboard: Studio test, the board is kept in memory and nothing is saved")
		local scores, names = LeaderboardStore.memory()
		return scores, names, false
	end
	if game.PlaceId == 0 then
		warn(PREFIX, "leaderboard: unpublished place, the board is kept in memory")
		local scores, names = LeaderboardStore.memory()
		return scores, names, false
	end
	local ok, scores, names = pcall(function(): (any, any)
		return DataStoreService:GetOrderedDataStore(L.ScoreStore), DataStoreService:GetDataStore(L.NameStore)
	end)
	if not ok then
		warn(PREFIX, "leaderboard: the stores could not be opened, the board shows this server only:", scores)
		local memoryScores, memoryNames = LeaderboardStore.memory()
		return memoryScores, memoryNames, false
	end
	return scores :: any, names :: any, true
end

local function nameOf(player: Player): string
	return Board.cleanName(player.DisplayName, Board.cleanName(player.Name, L.FallbackPlayer))
end

-- The players here with a farm and a living slime, as board lines at their live best. Also keeps each one's tracking.
local function liveEntries(): { LeaderboardStore.Entry }
	local now = os.time()
	local entries: { LeaderboardStore.Entry } = {}
	for _, player in Players:GetPlayers() do
		local farm = PlayerData.get(player)
		local best = if farm then Board.bestSlime(farm, now) else nil
		if not best then
			continue
		end
		local t = tracked[player]
		if not t then
			t = { sentLevel = 0, sentAt = nil, level = best.level, slime = best.name, since = now }
			tracked[player] = t
		elseif best.level > t.level then
			t.since = now
		end
		t.level, t.slime = best.level, best.name
		table.insert(entries, {
			userId = player.UserId,
			player = nameOf(player),
			slime = best.name,
			level = best.level,
			at = t.since,
		})
	end
	return entries
end

-- Draws the board for the clients: only when it changed.
local function publish()
	local target = folder
	if not target then
		return
	end
	local rows = Board.merge(stored, liveEntries(), L.Rows)
	local texts: { string } = {}
	for _, row in rows do
		table.insert(texts, Board.encodeRow(row))
	end
	local signature = table.concat(texts, "\n")
	if signature == published then
		return
	end
	published = signature
	target:SetAttribute("Count", #texts)
	for index = 1, L.Rows do
		target:SetAttribute("Row" .. index, texts[index])
	end
	local top = rows[1]
	print(
		PREFIX,
		"leaderboard:",
		#rows,
		"rows",
		if top then string.format("(first: %s, %s, level %d)", top.player, top.slime, top.level) else "(empty)"
	)
end

-- Sends one player's best (in the background). A failed send forgets that it was sent, so the next check tries again.
local function send(player: Player, entry: LeaderboardStore.Entry, t: Tracked)
	local s = store
	if not s then
		return
	end
	local before = t.sentLevel
	t.sentLevel, t.sentAt = entry.level, os.time()
	pending += 1
	task.spawn(function()
		local wrote, err = s.submit(entry)
		if err ~= nil then
			if tracked[player] == t then
				t.sentLevel = before
			end
		elseif wrote then
			-- what was just stored counts at once, without waiting for the next read
			stored = Board.merge(stored, { entry }, L.Rows)
			publish()
		end
		pending -= 1
	end)
end

-- Sends the bests that improved and are due. `leaving` skips the wait of WriteGapSeconds.
local function sendDue(player: Player, leaving: boolean)
	local t = tracked[player]
	local farm = PlayerData.get(player)
	local best = if farm then Board.bestSlime(farm, os.time()) else nil
	if not t or not best then
		return
	end
	if Board.writeDue(t.sentLevel, t.sentAt, best.level, os.time(), leaving) then
		send(player, {
			userId = player.UserId,
			player = nameOf(player),
			slime = best.name,
			level = best.level,
			at = t.since,
		}, t)
	end
end

local function refreshStored()
	local s = store
	if not s then
		return
	end
	local list = s.top(L.Rows)
	if list then
		stored = list
		publish()
	end
end

function Leaderboard.start()
	assert(store == nil, "Leaderboard.start called twice")
	local scores, names, isReal = openStores()
	store = LeaderboardStore.new({
		scores = scores,
		names = names,
		log = function(message: string)
			warn(message)
		end,
	})
	local made = ReplicatedStorage:FindFirstChild(L.Folder)
	if not made then
		made = Instance.new("Folder")
		made.Name = L.Folder
		made.Parent = ReplicatedStorage
	end
	folder = made :: Folder

	PlayerData.onLeaving(function(player: Player, data: any)
		-- (the last write must not hold the profile back: it runs in the background)
		local t = tracked[player]
		local best = Board.bestSlime(data, os.time())
		if t and best and Board.writeDue(t.sentLevel, t.sentAt, best.level, os.time(), true) then
			send(player, {
				userId = player.UserId,
				player = nameOf(player),
				slime = best.name,
				level = best.level,
				at = t.since,
			}, t)
		end
		tracked[player] = nil
	end)

	-- the live bests of the players here, redrawn only when the board changed
	task.spawn(function()
		while true do
			publish()
			task.wait(L.LiveSeconds)
		end
	end)
	-- the bests that improved are sent
	task.spawn(function()
		while true do
			task.wait(L.WriteCheckSeconds)
			for _, player in Players:GetPlayers() do
				sendDue(player, false)
			end
		end
	end)
	-- the stored top is read
	task.spawn(function()
		while true do
			refreshStored()
			task.wait(L.ReadSeconds)
		end
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			sendDue(player, true)
		end
		-- (PlayerData's own shutdown runs the leaving callbacks at the same time: give them a moment to begin their sends)
		task.wait(0.5)
		local waited = 0.5
		while pending > 0 and waited < L.ShutdownSeconds do
			task.wait(0.2)
			waited += 0.2
		end
	end)
	print(PREFIX, "leaderboard ready (" .. (if isReal then "DataStore" else "in-memory") .. ")")
end

return Leaderboard
