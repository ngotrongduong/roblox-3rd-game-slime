--!strict
-- THE OWNER'S DEBUG MENU, server side. Studio only: Main starts this module only when RunService:IsStudio(), the remote
-- handler checks it again, and tools/build_publish.luau strips this file from the published place (and fails if it stays).
-- The client asks (Remotes.Debug, { action, args }); the server changes ONLY the asker's own farm through PlayerData.update
-- (DebugPresets does the changing, in place, with the game's own rules), keeps one level of undo in memory, tells the world
-- (areas, village, guide, rewards) and saves soon. Answers { ok, text }. The Arena items go to server/Arena's Studio-only
-- debug calls (the same rules as its remote; only the points, tickets, rank and clock tools reach past them, and only on
-- the Studio memory ladder for the rank); "Fake servers" runs more ladder servers on that memory ladder.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArenaFight = require(ReplicatedStorage.Shared.ArenaFight)
local ArenaLadder = require(ReplicatedStorage.Shared.ArenaLadder)
local ArenaPlay = require(ReplicatedStorage.Shared.ArenaPlay)
local ArenaRules = require(ReplicatedStorage.Shared.ArenaRules)
local ArenaSeason = require(ReplicatedStorage.Shared.ArenaSeason)
local Config = require(ReplicatedStorage.Shared.Config)
local DebugPresets = require(ReplicatedStorage.Shared.DebugPresets)
local FarmState = require(ReplicatedStorage.Shared.FarmState)
local Layout = require(ReplicatedStorage.Shared.Layout)
local ProfileLogic = require(ReplicatedStorage.Shared.ProfileLogic)
local Rng = require(ReplicatedStorage.Shared.Rng)
local Travel = require(ReplicatedStorage.Shared.Travel)
local Arena = require(script.Parent.Arena)
local ArenaStore = require(script.Parent.ArenaStore)
local Dungeon = require(script.Parent.Dungeon)
local Guide = require(script.Parent.Guide)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Rewards = require(script.Parent.Rewards)
local ZombieFights = require(script.Parent.ZombieFights)

-- Debug numbers (the owner's Config belongs to others, so they live here).
local MIN_GAP = 0.25 -- seconds between two taps of one player (the menu is a person pressing buttons)
-- the Arena tools
local ARENA_POINTS = 1000 -- "+1000 Arena points"
local FAKE_SERVERS = 5 -- "Fake servers x5": extra ladder servers on the Studio memory stores
local FAKE_PLAYERS = 3 -- fake players a fake server
local FAKE_SECONDS = 180 -- how long the fake players attack
local FAKE_SETTLE_SECONDS = 90 -- then how long their matches in flight keep settling
local FAKE_STEP = 5 -- seconds between two steps of the fakes (a leader tick every third step, as TickSeconds)
local FAKE_GAP = { 15, 40 } -- seconds between two attacks of one fake player (random in this range)
local FAKE_LEVELS = { 8, 45 } -- the level of a fake player's slimes (random in this range)
local FAKE_ID = 7_000_000_000 -- fake players' UserIds are above this (a memory ladder only)

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

-- ===== the Arena: fake servers on the Studio memory ladder =====

local fakeRunning = false

-- One step of a fake player: its match in flight is settled as server/Arena does, or (while `attacking`) it attacks a
-- random opponent of its list once its next attack time has come.
local function fakeStep(p: any, now: number, attacking: boolean, random: Random, rng: any)
	local farm = p.farm
	local pending = farm.arena.pending
	if pending then
		local doc = p.store.readLadder(pending.season, Config.Arena.SettleReadSeconds)
		local action, out = ArenaRules.settle(farm, doc, p.userId, now)
		if action == "confirm" and out then
			local points = ArenaRules.confirm(farm, now, out)
			p.confirms += 1
			print(
				Config.LogPrefix,
				string.format(
					"arena: fake %s match %s confirmed: %s, +%d points, rank %d",
					p.name,
					pending.matchId,
					if out.won then "won" else "lost",
					points,
					out.rankAfter or 0
				)
			)
			local _, theirs = ArenaPlay.logEntries(pending, out, tostring(p.userId), p.name, points, now)
			if theirs then
				p.store.appendLog(tonumber(pending.defender) :: number, theirs)
			end
		elseif action == "void" then
			ArenaRules.void(farm, now)
			p.voids += 1
			print(Config.LogPrefix, "arena: fake", p.name, "match", pending.matchId, "void")
		elseif action == "resend" then
			local result = ArenaRules.result(farm, p.userId, p.name)
			if result and p.store.submit(result) then
				ArenaRules.markSent(farm, now)
				print(Config.LogPrefix, "arena: fake", p.name, "match", pending.matchId, "sent again")
			end
		end
		return
	end
	if not attacking or now < p.nextAt then
		return
	end
	p.nextAt = now + random:NextInteger(FAKE_GAP[1], FAKE_GAP[2])
	local season = ArenaSeason.seasonOf(now)
	local doc = p.store.readLadder(season, Config.Arena.SettleReadSeconds)
	local mine = ArenaPlay.snapshotDoc(farm, ArenaPlay.fightTeam(farm, now), p.name)
	if not doc or not mine then
		return
	end
	local picks = ArenaLadder.opponents(doc, tostring(p.userId), rng, Config.Arena.Opponents)
	local list = ArenaPlay.offer(doc, picks, season, function(userId: number): any
		return ArenaPlay.cleanSnapshot(p.store.readSnapshot(userId, 60))
	end)
	local target = list[random:NextInteger(1, #list)]
	local seed = random:NextInteger(1, 2 ^ 31 - 2)
	local replay = ArenaFight.simulate(mine.fighters, target.fighters, seed)
	local info = ArenaPlay.attackInfo(p.userId, target, replay.won, mine.power, seed, "fake-" .. (farm.arena.seq + 1))
	local began, why = ArenaRules.beginAttack(farm, now, info)
	if not began then
		print(Config.LogPrefix, "arena: fake", p.name, "attack refused:", why)
		return
	end
	p.attacks += 1
	local result = ArenaRules.result(farm, p.userId, p.name)
	if result then
		p.store.submit(result)
	end
	print(
		Config.LogPrefix,
		string.format(
			"arena: fake %s attacked %s (%s, rank %d): %s",
			p.name,
			target.name,
			target.id,
			target.rank or 0,
			if replay.won then "won" else "lost"
		)
	)
end

-- FAKE_SERVERS more ladder servers on the same memory stores, each with FAKE_PLAYERS fake players that set teams, publish
-- their defence and attack bots, champions, each other and the real players for FAKE_SECONDS, through the same rules and
-- stores as server/Arena: leader hand-over and contention show in the log.
local function fakeServers(): (boolean, string)
	if fakeRunning then
		return false, "Fake servers are already running"
	end
	local deps = Arena.debug.memory()
	if not deps then
		return false, "Only on the Studio memory ladder"
	end
	local A = Config.Arena
	local clock = Arena.debug.clock
	local random = Random.new()
	local rng = Rng.fromSource(function(): number
		return random:NextNumber()
	end)
	local queue = deps.memory:GetQueue(A.QueueName, A.InvisibleSeconds)
	local lease = deps.memory:GetHashMap(A.LeaseMapName)
	local start = clock()
	local servers = {}
	local fakes = {}
	for i = 1, FAKE_SERVERS do
		local id = "fake" .. i
		local store = ArenaStore.new({
			data = deps.data,
			queue = queue,
			lease = lease,
			serverId = id,
			clock = clock,
			log = function(line: string)
				print(line .. " [" .. id .. "]")
			end,
		})
		table.insert(servers, store)
		for j = 1, FAKE_PLAYERS do
			local farm = FarmState.newFarm(start)
			DebugPresets.addSlimes(farm, start, A.TeamSize, random:NextInteger(FAKE_LEVELS[1], FAKE_LEVELS[2]))
			ArenaRules.setTeam(farm, ArenaPlay.bestTeam(farm, start), start)
			table.insert(fakes, {
				userId = FAKE_ID + i * 10 + j,
				name = string.format("Fake %d-%d", i, j),
				farm = farm,
				store = store,
				nextAt = start + random:NextInteger(0, FAKE_GAP[2]),
				attacks = 0,
				confirms = 0,
				voids = 0,
			})
		end
	end
	fakeRunning = true
	task.spawn(function()
		local ok, err = pcall(function()
			for _, p in fakes do
				local doc = ArenaPlay.snapshotDoc(p.farm, ArenaRules.team(p.farm), p.name)
				if doc and p.store.writeSnapshot(p.userId, doc) then
					p.store.join(tostring(p.userId), p.name, doc.power)
				end
			end
			local step = 0
			while clock() - start < FAKE_SECONDS + FAKE_SETTLE_SECONDS do
				task.wait(FAKE_STEP)
				step += 1
				local now = clock()
				for i, store in servers do
					if (step + i) % 3 == 0 then
						store.leaderTick(now)
					end
				end
				for _, p in fakes do
					local stepped, why = pcall(fakeStep :: any, p, now, now - start < FAKE_SECONDS, random, rng)
					if not stepped then
						warn(Config.LogPrefix, "arena: fake", p.name, "step failed:", why)
					end
				end
			end
		end)
		fakeRunning = false
		if not ok then
			warn(Config.LogPrefix, "arena: fake servers failed:", err)
		end
		local attacks, confirms, voids, waiting = 0, 0, 0, 0
		for _, p in fakes do
			attacks += p.attacks
			confirms += p.confirms
			voids += p.voids
			waiting += if p.farm.arena.pending then 1 else 0
		end
		print(
			Config.LogPrefix,
			string.format(
				"arena: fake servers done: %d attacks, %d confirmed, %d void, %d still in flight",
				attacks,
				confirms,
				voids,
				waiting
			)
		)
	end)
	return true,
		string.format(
			"%d fake servers, %d fake players, %d s of attacks: watch the log",
			FAKE_SERVERS,
			#fakes,
			FAKE_SECONDS
		)
end

-- An "arena" item of the menu: server/Arena's Studio-only debug calls.
local function arenaDebug(player: Player, action: string, args: any): { ok: boolean, text: string }
	local D = Arena.debug
	local ok, text = false, "Unknown action"
	if action == "arena_team" then
		ok, text = D.team(player)
	elseif action == "arena_opponents" then
		ok, text = D.opponents(player)
	elseif action == "arena_attack" then
		ok, text = D.attackFirst(player)
	elseif action == "arena_state" then
		ok, text = D.state(player)
	elseif action == "arena_tickets" then
		ok, text = D.tickets(player)
	elseif action == "arena_rank" then
		local rank = if type(args) == "table"
				and type(args.rank) == "number"
				and args.rank == args.rank
			then args.rank
			else 1
		ok, text = D.rank(player, rank)
	elseif action == "arena_points" then
		ok, text = D.points(player, ARENA_POINTS)
	elseif action == "arena_end_season" or action == "arena_clock_reset" then
		if fakeRunning then
			return reply(false, "Wait for the fake servers to finish")
		end
		if action == "arena_end_season" then
			ok, text = D.endSeason()
		else
			ok, text = D.clockReset()
		end
	elseif action == "arena_fake" then
		ok, text = fakeServers()
	elseif action == "arena_pause" then
		ok, text = D.pauseLeader()
	end
	return reply(ok, text)
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
	elseif kind == "arena" then
		return arenaDebug(player, action, data.args)
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
