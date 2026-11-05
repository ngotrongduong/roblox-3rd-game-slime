--!strict
-- The Arena's server service (stage 2b): the remote, the loops and the joins that drive the farm's side (shared/ArenaRules)
-- against the ladder's stores (server/ArenaStore). The server runs every fight; a match is a transaction: beginAttack stores
-- it in flight, its result goes to the ladder's queue, and only the ladder's outcome for that match (settle -> confirm)
-- grants its points, so a re-sent request, a lost message or a second login never makes a second match or grants twice.
--
-- Remotes.Arena (RemoteFunction), { action = ... }; every answer is { ok, reason? (a short code), ... }:
--   "state"                       -> points, tickets, rank (nil off the ladder), season, the match in flight, quests, top
--   "setTeam"   { ids }           -> the Arena team (ArenaRules.setTeam); the defence snapshot follows
--   "opponents" { refresh? }      -> the opponents this server offers (a new list at most every Config.Arena.RefreshSeconds)
--   "attack"    { target, requestId } -> the fight's replay; the match stays "confirming" until the ladder holds it
--   "log"                         -> the player's own Log_<userId>
--   "buy"       { itemId, requestId } -> one Config.Arena.Shop buy: { itemId, points, shop, weekEndsAt }; the same requestId
--                                    again answers the first answer and buys nothing
-- ("state" also holds shop = ArenaRules.shop rows and weekEndsAt, the second the shop's week ends.)
-- Reason codes: NOT_READY, RATE_LIMIT, BAD_REQUEST, NO_ACCOUNT, BUSY, SERVER_ERROR, NO_LADDER, NO_LOG, IN_DUNGEON, NO_TEAM,
-- NO_TICKETS, SEASON_ENDING, NOT_OFFERED, PENDING, DONE, ArenaRules.setTeam's BAD_TEAM, TEAM_SIZE, DUPLICATE,
-- NOT_OWNED, GHOST, and ArenaRules.buy's UNKNOWN_ITEM, SOLD_OUT, NO_POINTS.
-- Player attribute ArenaRank: the rank on this season's ladder (0 = not on it), every Config.Arena.LadderRefreshSeconds.
-- Arena.debug is the Studio debug menu's way in (server/OwnerDebug); every one of its calls refuses outside Studio.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArenaFight = require(ReplicatedStorage.Shared.ArenaFight)
local ArenaLadder = require(ReplicatedStorage.Shared.ArenaLadder)
local ArenaPlay = require(ReplicatedStorage.Shared.ArenaPlay)
local ArenaRules = require(ReplicatedStorage.Shared.ArenaRules)
local ArenaSeason = require(ReplicatedStorage.Shared.ArenaSeason)
local Board = require(ReplicatedStorage.Shared.Leaderboard)
local Config = require(ReplicatedStorage.Shared.Config)
local Rng = require(ReplicatedStorage.Shared.Rng)
local ArenaStore = require(script.Parent.ArenaStore)
local Dungeon = require(script.Parent.Dungeon)
local PlayerData = require(script.Parent.PlayerData)

local A = Config.Arena
local PREFIX = Config.LogPrefix

type Reply = { [string]: any }
type Offered = { season: number, at: number, list: { ArenaPlay.Entry } }

local Arena = {}
local store: ArenaStore.Store? = nil
-- seconds the Studio debug tools add to os.time() (End season); 0 outside Studio, where nothing can change it
local offset = 0
local leaderPaused = false
local storeCount = 1
local random = Random.new()
local serverRng = Rng.fromSource(function(): number
	return random:NextNumber()
end)
-- per player: request times (rate limit), the Arena lock, the opponents offered, the last attack's answer, the request id
-- of the last match that settled, the defence last published, a publish in progress and the log last read
local limits: { [Player]: { number } } = {}
local busy: { [Player]: boolean } = {}
local offered: { [Player]: Offered } = {}
local lastReply: { [Player]: { requestId: string, reply: Reply } } = {}
local doneRequest: { [Player]: string } = {}
local published: { [Player]: { key: string, power: number } } = {}
local publishing: { [Player]: boolean } = {}
local logs: { [Player]: { at: number, list: { any } } } = {}
-- per player: the last shop buys' request ids with their answers (a re-sent buy answers again and buys nothing)
local buys: { [Player]: { { requestId: string, reply: Reply } } } = {}
local warned: { [string]: boolean } = {}

local function clock(): number
	return os.time() + offset
end

local function fail(reason: string): Reply
	return { ok = false, reason = reason }
end

-- (a loop that keeps failing warns once a kind, not every few seconds)
local function warnOnce(kind: string, err: any)
	if not warned[kind] then
		warned[kind] = true
		warn(PREFIX, "arena:", kind, "failed (warned once):", err)
	end
end

local function logLine(line: string)
	print(line)
end

local function nameOf(player: Player): string
	return Board.cleanName(player.DisplayName, Board.cleanName(player.Name, Config.Leaderboard.FallbackPlayer))
end

-- A Studio "Start server" test player has a UserId below 1, which the ladder cannot hold.
local function hasAccount(player: Player): boolean
	return player.UserId > 0
end

local function rateAllowed(player: Player): boolean
	-- (a rolling window, as server/VillageRemotes)
	local now = os.clock()
	local recent = limits[player]
	if not recent then
		recent = {}
		limits[player] = recent
	end
	for i = #recent, 1, -1 do
		if now - recent[i] >= 1 then
			table.remove(recent, i)
		end
	end
	if #recent >= A.RequestsPerSecond then
		return false
	end
	table.insert(recent, now)
	return true
end

-- Runs fn holding the player's Arena lock: set before anything yields, always released. nil (fn not run) while it is held.
local function withLock(player: Player, fn: () -> ...any): any
	if busy[player] then
		return nil
	end
	busy[player] = true
	local ok, result = pcall(fn :: any)
	busy[player] = nil
	if not ok then
		error(result, 0)
	end
	return result
end

-- In a task of its own; a failure warns once.
local function spawnGuarded(kind: string, fn: () -> ())
	task.spawn(function()
		local ok, err = pcall(fn :: any)
		if not ok then
			warnOnce(kind, err)
		end
	end)
end

-- ===== the defence snapshot =====

-- Writes a defence snapshot and the ladder join (yields). `player` is nil once they have left.
local function send(player: Player?, userId: number, doc: ArenaPlay.Snapshot, key: string)
	local s = store
	if not s or not s.writeSnapshot(userId, doc) then
		return
	end
	if player then
		published[player] = { key = key, power = doc.power }
	end
	s.join(tostring(userId), doc.name, doc.power, ArenaSeason.seasonOf(clock()))
	print(PREFIX, "arena: defence of", doc.name, "published:", key, "power", doc.power)
end

-- Publishes the player's defence (the team that can fight) now. Returns whether a snapshot was made.
local function publish(player: Player): boolean
	local farm = PlayerData.get(player)
	if not farm or not hasAccount(player) or publishing[player] then
		return false
	end
	local now = clock()
	local ids = ArenaPlay.fightTeam(farm, now)
	local doc = ArenaPlay.snapshotDoc(farm, ids, nameOf(player))
	if not doc then
		return false
	end
	publishing[player] = true
	PlayerData.update(player, function(live: any)
		live.arena.snapshotAt = now
	end)
	local ok, err = pcall(send :: any, player, player.UserId, doc, ArenaPlay.teamKey(ids))
	publishing[player] = nil
	if not ok then
		warnOnce("publish", err)
	end
	return ok
end

-- Whether the defence should go out again: a team that is not the published one (PublishGapSeconds after the last), or
-- the same team with another power (SnapshotDebounceSeconds after the last).
local function publishDue(player: Player, farm: any, now: number): boolean
	local ids = ArenaPlay.fightTeam(farm, now)
	if #ids == 0 or publishing[player] then
		return false
	end
	local age = now - farm.arena.snapshotAt
	-- (a clock set back by the debug tools reads as long ago)
	local longAgo = function(seconds: number): boolean
		return age < 0 or age >= seconds
	end
	local last = published[player]
	if not last or last.key ~= ArenaPlay.teamKey(ids) then
		return longAgo(A.PublishGapSeconds)
	end
	local doc = ArenaPlay.snapshotDoc(farm, ids, "")
	return doc ~= nil and doc.power ~= last.power and longAgo(A.SnapshotDebounceSeconds)
end

local function showRank(player: Player, doc: any)
	if doc and hasAccount(player) and player.Parent == Players then
		player:SetAttribute("ArenaRank", ArenaLadder.rankOf(doc, tostring(player.UserId)) or 0)
	end
end

-- ===== the match in flight, the season and its reward =====

-- Looks at the player's match in flight against its season's ladder: confirms it (grants, logs), voids it or sends it
-- again. The lock is held by the caller. Returns ArenaRules.settle's action.
local function settleOne(player: Player): string
	local s = store
	local farm = PlayerData.get(player)
	local pending = if farm then farm.arena.pending else nil
	if not s or not pending then
		return "none"
	end
	local doc = s.readLadder(pending.season, A.SettleReadSeconds)
	local now = clock()
	local userId = player.UserId
	local action = "none"
	local outcome: any = nil
	local granted = 0
	local quests = 0
	local back = false
	PlayerData.update(player, function(live: any)
		local p = live.arena.pending
		if not p or p.seq ~= pending.seq then
			return
		end
		local out
		action, out = ArenaRules.settle(live, doc, userId, now)
		if action == "confirm" then
			outcome = out
			if type(out) == "table" and out.void then
				-- (the ladder never keeps a void outcome; read as a void all the same)
				action = "void"
				back = select(2, ArenaRules.void(live, now))
			else
				local grants
				granted, grants = ArenaRules.confirm(live, now, out)
				quests = #grants
			end
		elseif action == "void" then
			back = select(2, ArenaRules.void(live, now))
		end
	end)
	if action == "confirm" and outcome then
		doneRequest[player] = pending.requestId
		lastReply[player] = nil
		print(
			PREFIX,
			string.format(
				"arena: %s match %s confirmed: %s vs %s, +%d points (%d quest%s), rank %d",
				player.Name,
				pending.matchId,
				if outcome.won then "won" else "lost",
				pending.defenderName,
				granted,
				quests,
				if quests == 1 then "" else "s",
				if type(outcome.rankAfter) == "number" then outcome.rankAfter else 0
			)
		)
		PlayerData.markKeyMoment(player, "arena match")
		local mine, theirs = ArenaPlay.logEntries(pending, outcome, tostring(userId), nameOf(player), granted, now)
		s.appendLog(userId, mine)
		-- (the cached log is dropped only now: a log asked for between the confirm and the append would miss this match)
		logs[player] = nil
		if theirs then
			s.appendLog(tonumber(pending.defender) :: number, theirs)
		end
	elseif action == "void" then
		doneRequest[player] = pending.requestId
		lastReply[player] = nil
		print(
			PREFIX,
			"arena:",
			player.Name,
			"match",
			pending.matchId,
			"void" .. (if back then ", its ticket given back" else "")
		)
		PlayerData.markKeyMoment(player, "arena void")
	elseif action == "resend" then
		local live = PlayerData.get(player)
		local result = if live then ArenaRules.result(live, userId, nameOf(player)) else nil
		if result and result.seq == pending.seq then
			-- (marked sent even when the queue refused it: the next try waits ResendSeconds, not one settle tick)
			local sent = s.submit(result)
			local sentAt = clock()
			PlayerData.update(player, function(l: any)
				ArenaRules.markSent(l, sentAt)
			end)
			if sent then
				print(PREFIX, "arena:", player.Name, "match", pending.matchId, "sent again")
			end
		end
	end
	return action
end

-- The farm follows the season it is in, once no match is in flight (a match begun in the old season counts there).
local function followSeason(player: Player, now: number)
	local farm = PlayerData.get(player)
	local season = ArenaSeason.seasonOf(now)
	-- (never backwards: a clock set back by the debug tools leaves the farm where it is)
	if not farm or farm.arena.pending or season <= farm.arena.season then
		return
	end
	PlayerData.update(player, function(live: any)
		if not live.arena.pending and season > live.arena.season then
			ArenaRules.newSeason(live, season)
		end
	end)
	print(PREFIX, "arena:", player.Name, "now in season", season)
end

-- Claims every past season whose ladder is final (the rank from that ladder), once. The lock is held by the caller.
local function claimAll(player: Player)
	local s = store
	local farm = PlayerData.get(player)
	if not s or not farm then
		return
	end
	local now = clock()
	local uid = tostring(player.UserId)
	for _, season in ArenaRules.unclaimed(farm, now) do
		-- (a match of that season still in flight settles first: its win belongs in the season's record)
		local pending = farm.arena.pending
		if pending and pending.season <= season then
			continue
		end
		local doc = s.readLadder(season, A.ClaimReadSeconds)
		if type(doc) ~= "table" then
			continue
		end
		-- (a season nobody played never has a ladder written: it closes with no reward after a grace)
		local unplayed = next(doc.players) == nil and now >= ArenaSeason.finalAt(season) + A.ClaimGraceSeconds
		if doc.final or unplayed then
			local rank = if doc.final then ArenaLadder.rankOf(doc, uid) else nil
			local points, badge = 0, nil
			PlayerData.update(player, function(live: any)
				points, badge = ArenaRules.claimSeason(live, season, rank)
			end)
			print(
				PREFIX,
				string.format(
					"arena: %s season %d closed: rank %d, +%d points%s",
					player.Name,
					season,
					rank or 0,
					points,
					if badge then ", badge " .. badge else ""
				)
			)
			if points > 0 then
				PlayerData.markKeyMoment(player, "arena season")
			end
		end
	end
end

-- A player whose farm has loaded: the match number follows the ladder's, a match in flight is settled, the season moves
-- on, past seasons are claimed, the defence counters come from the stores and the defence is published if it changed.
local function joined(player: Player)
	if not hasAccount(player) then
		player:SetAttribute("ArenaRank", 0)
		return
	end
	withLock(player, function()
		local s = store
		local farm = PlayerData.get(player)
		if not s or not farm then
			return
		end
		local now = clock()
		local season = ArenaSeason.seasonOf(now)
		local uid = tostring(player.UserId)
		local doc = s.readLadder(season, A.SettleReadSeconds)
		local pending = farm.arena.pending
		local older = if pending and pending.season ~= season
			then s.readLadder(pending.season, A.SettleReadSeconds)
			else nil
		PlayerData.update(player, function(live: any)
			for _, ladder in { doc or false, older or false } do
				local meta = if type(ladder) == "table" then ladder.players[uid] else nil
				if type(meta) == "table" then
					ArenaRules.syncSeq(live, meta.seq)
				end
			end
		end)
		settleOne(player)
		followSeason(player, clock())
		claimAll(player)
		local meta = if doc then doc.players[uid] else nil
		local dw = if doc then (if meta then meta.dw else 0) else nil
		local log = s.readLog(player.UserId)
		if log then
			logs[player] = { at = clock(), list = log }
		end
		PlayerData.update(player, function(live: any)
			ArenaPlay.applyDefence(live, dw, log)
		end)
		local mine = ArenaPlay.cleanSnapshot(s.readSnapshot(player.UserId, 0))
		if mine then
			local ids = {}
			for _, fighter in mine.fighters do
				table.insert(ids, fighter.id)
			end
			published[player] = { key = ArenaPlay.teamKey(ids), power = mine.power }
		end
		local live = PlayerData.get(player)
		if live and publishDue(player, live, clock()) then
			publish(player)
		end
		showRank(player, doc)
		live = PlayerData.get(player)
		if live then
			print(
				PREFIX,
				string.format(
					"arena: %s ready: rank %d, %d points, %d tickets%s",
					player.Name,
					if doc then ArenaLadder.rankOf(doc, uid) or 0 else 0,
					live.arena.points,
					ArenaRules.ticketsLeft(live, clock()),
					if live.arena.pending then ", match " .. live.arena.pending.matchId .. " in flight" else ""
				)
			)
		end
	end)
end

-- Leaving: the defence goes out if the team changed since the last one (the write finishes after they are gone).
local function left(player: Player, data: any)
	if not hasAccount(player) or type(data) ~= "table" or type(data.arena) ~= "table" or publishing[player] then
		return
	end
	local now = clock()
	local ids = ArenaPlay.fightTeam(data, now)
	local key = ArenaPlay.teamKey(ids)
	local last = published[player]
	if #ids == 0 or (last and last.key == key) then
		return
	end
	local doc = ArenaPlay.snapshotDoc(data, ids, nameOf(player))
	if not doc then
		return
	end
	PlayerData.update(player, function(live: any)
		live.arena.snapshotAt = now
	end)
	local userId = player.UserId
	spawnGuarded("publish on leaving", function()
		send(nil, userId, doc, key)
	end)
end

-- Every LadderRefreshSeconds: ranks, this season's defence wins, the season, rewards to claim, a defence to publish.
local function refreshAll()
	local s = store
	if not s then
		return
	end
	local now = clock()
	local season = ArenaSeason.seasonOf(now)
	local doc = s.readLadder(season, A.LadderRefreshSeconds)
	for _, player in Players:GetPlayers() do
		local farm = PlayerData.get(player)
		if not farm or not hasAccount(player) then
			continue
		end
		showRank(player, doc)
		if doc then
			local meta = doc.players[tostring(player.UserId)]
			local dw = if meta then meta.dw else 0
			if dw ~= farm.arena.defense.wins then
				PlayerData.update(player, function(live: any)
					ArenaPlay.applyDefence(live, dw, nil)
				end)
			end
		end
		followSeason(player, now)
		local claims = #ArenaRules.unclaimed(farm, now) > 0
		local due = publishDue(player, farm, now)
		if (claims or due) and not busy[player] then
			spawnGuarded("refresh of a player", function()
				withLock(player, function()
					if claims then
						claimAll(player)
					end
					if due then
						publish(player)
					end
				end)
			end)
		end
	end
end

-- ===== the remote's actions =====

-- What the shop screen draws: the points, the rows (ArenaRules.shop) and when the week's limits start over.
local function shopReply(farm: any, now: number): { [string]: any }
	return {
		points = farm.arena.points,
		shop = ArenaRules.shop(farm, now),
		weekEndsAt = ArenaSeason.weekEnd(ArenaSeason.weekOf(now)),
	}
end

local function stateOf(player: Player): Reply
	local s = store :: ArenaStore.Store
	local now = clock()
	local season = ArenaSeason.seasonOf(now)
	local doc = s.readLadder(season, A.LadderRefreshSeconds)
	local farm = PlayerData.get(player)
	if not farm then
		return fail("NOT_READY")
	end
	local mine = ArenaPlay.snapshotDoc(farm, ArenaPlay.fightTeam(farm, now), "")
	local defense = farm.arena.defense
	local shop = shopReply(farm, now)
	return {
		ok = true,
		now = now,
		points = farm.arena.points,
		shop = shop.shop,
		weekEndsAt = shop.weekEndsAt,
		tickets = ArenaRules.ticketsLeft(farm, now),
		ticketsPerDay = A.TicketsPerDay,
		rank = if doc then ArenaLadder.rankOf(doc, tostring(player.UserId)) else nil,
		season = season,
		seasonEndsAt = ArenaSeason.seasonEnd(season),
		locked = ArenaSeason.locked(now),
		team = ArenaRules.team(farm),
		power = if mine then mine.power else 0,
		pending = ArenaPlay.pendingSummary(farm),
		quests = ArenaPlay.quests(farm, now),
		defense = { wins = defense.wins, streak = defense.streak, best = defense.best },
		top = if doc then ArenaPlay.top(doc, A.TopCount) else {},
	}
end

local function setTeam(player: Player, data: any): Reply
	local now = clock()
	local ok, why = false, nil :: string?
	local updated = PlayerData.update(player, function(live: any)
		ok, why = ArenaRules.setTeam(live, data.ids, now)
	end)
	if not updated then
		return fail("NOT_READY")
	end
	if not ok then
		return fail(why or "BAD_TEAM")
	end
	local farm = PlayerData.get(player)
	local team = ArenaRules.team(farm)
	print(PREFIX, "arena:", player.Name, "team", table.concat(team, ","))
	PlayerData.markKeyMoment(player, "arena team")
	-- the defence follows at once, unless one went out moments ago (the refresh loop sends it then)
	if publishDue(player, farm, now) then
		spawnGuarded("publish", function()
			publish(player)
		end)
	end
	local mine = ArenaPlay.snapshotDoc(farm, ArenaPlay.fightTeam(farm, now), "")
	return { ok = true, team = team, power = if mine then mine.power else 0 }
end

local function listReply(held: Offered, now: number): Reply
	local list = {}
	for _, entry in held.list do
		table.insert(list, ArenaPlay.public(entry))
	end
	return { ok = true, list = list, refreshIn = math.max(0, held.at + A.RefreshSeconds - now) }
end

-- The lock is held by the caller.
local function opponents(player: Player, data: any): Reply
	local s = store :: ArenaStore.Store
	local now = clock()
	local season = ArenaSeason.seasonOf(now)
	local held = offered[player]
	if held and held.season == season and (data.refresh ~= true or now - held.at < A.RefreshSeconds) then
		return listReply(held, now)
	end
	local doc = s.readLadder(season, A.SettleReadSeconds)
	if not doc then
		return fail("NO_LADDER")
	end
	local picks = ArenaLadder.opponents(doc, tostring(player.UserId), serverRng, A.Opponents)
	local list = ArenaPlay.offer(doc, picks, season, function(userId: number): ArenaPlay.Snapshot?
		return ArenaPlay.cleanSnapshot(s.readSnapshot(userId, A.SnapshotReadSeconds))
	end)
	local fresh: Offered = { season = season, at = now, list = list }
	offered[player] = fresh
	return listReply(fresh, now)
end

-- The lock is held by the caller.
local function attack(player: Player, data: any): Reply
	local s = store :: ArenaStore.Store
	local requestId = data.requestId
	if not ArenaPlay.validRequestId(requestId) or type(data.target) ~= "string" then
		return fail("BAD_REQUEST")
	end
	local farm = PlayerData.get(player)
	if not farm then
		return fail("NOT_READY")
	end
	local pending = farm.arena.pending
	if pending then
		-- the same request sent again finds its own match; any other waits for it
		if pending.requestId == requestId then
			local last = lastReply[player]
			if last and last.requestId == requestId then
				return last.reply
			end
			return { ok = true, won = pending.won, matchId = pending.matchId, status = "confirming" }
		end
		return { ok = false, reason = "PENDING", pending = ArenaPlay.pendingSummary(farm) }
	end
	if doneRequest[player] == requestId then
		return fail("DONE")
	end
	if Dungeon.inRun(player) then
		return fail("IN_DUNGEON")
	end
	local now = clock()
	local name = nameOf(player)
	local mine = ArenaPlay.snapshotDoc(farm, ArenaPlay.fightTeam(farm, now), name)
	if not mine then
		return fail("NO_TEAM")
	end
	if ArenaRules.ticketsLeft(farm, now) <= 0 then
		return fail("NO_TICKETS")
	end
	if ArenaSeason.locked(now) then
		return fail("SEASON_ENDING")
	end
	local held = offered[player]
	local entry = if held and held.season == ArenaSeason.seasonOf(now)
		then ArenaPlay.find(held.list, data.target)
		else nil
	if not entry then
		return fail("NOT_OFFERED")
	end
	local seed = random:NextInteger(1, 2 ^ 31 - 2)
	local replay = ArenaFight.simulate(mine.fighters, entry.fighters, seed)
	local info = ArenaPlay.attackInfo(player.UserId, entry, replay.won, mine.power, seed, requestId)
	local began, why = false, nil :: string?
	local match: any = nil
	local updated = PlayerData.update(player, function(live: any)
		began, why, match = ArenaRules.beginAttack(live, now, info)
	end)
	if not updated then
		return fail("NOT_READY")
	end
	if not began or not match then
		return fail(why or "SERVER_ERROR")
	end
	-- (the next look offers a new list: the ranks have moved)
	offered[player] = nil
	print(
		PREFIX,
		string.format(
			"arena: %s attacked %s (%s, rank %d): %s, match %s",
			player.Name,
			entry.name,
			entry.id,
			entry.rank or 0,
			if replay.won then "won" else "lost",
			match.matchId
		)
	)
	PlayerData.markKeyMoment(player, "arena attack")
	local live = PlayerData.get(player)
	local result = if live then ArenaRules.result(live, player.UserId, name) else nil
	if result and s.submit(result) then
		local sentAt = clock()
		PlayerData.update(player, function(l: any)
			ArenaRules.markSent(l, sentAt)
		end)
	end
	local reply: Reply = {
		ok = true,
		won = replay.won,
		seconds = replay.seconds,
		steps = replay.steps,
		sides = {
			attacker = {
				name = name,
				power = mine.power,
				looks = mine.looks,
				fighters = ArenaFight.view(mine.fighters, "a:"),
			},
			defender = {
				name = entry.name,
				power = entry.power,
				looks = entry.looks,
				rank = entry.rank,
				fighters = ArenaFight.view(entry.fighters, "d:"),
			},
		},
		matchId = match.matchId,
		status = "confirming",
	}
	lastReply[player] = { requestId = requestId, reply = reply }
	return reply
end

-- The lock is held by the caller. One PlayerData.update runs ArenaRules.buy; the materials and the gear bag reach the
-- client the way every other purchase does (the village publishes the farm's Materials and GearBag each tick).
local function buy(player: Player, data: any): Reply
	local requestId = data.requestId
	if not ArenaPlay.validRequestId(requestId) or type(data.itemId) ~= "string" then
		return fail("BAD_REQUEST")
	end
	local kept = buys[player]
	if kept then
		for _, entry in kept do
			if entry.requestId == requestId then
				return entry.reply
			end
		end
	end
	local now = clock()
	local ok, why = false, nil :: string?
	local updated = PlayerData.update(player, function(live: any)
		ok, why = ArenaRules.buy(live, now, data.itemId)
	end)
	if not updated then
		return fail("NOT_READY")
	end
	local farm = PlayerData.get(player)
	if not farm then
		return fail("NOT_READY")
	end
	local reply: Reply
	if ok then
		reply = { ok = true, itemId = data.itemId }
		for key, value in shopReply(farm, now) do
			reply[key] = value
		end
		print(PREFIX, string.format("arena: %s bought %s, %d points left", player.Name, data.itemId, farm.arena.points))
		PlayerData.markKeyMoment(player, "arena buy")
	else
		reply = fail(why or "SERVER_ERROR")
		print(PREFIX, "arena:", player.Name, "buy of", data.itemId, "refused:", reply.reason)
	end
	if not kept then
		kept = {}
		buys[player] = kept
	end
	table.insert(kept, { requestId = requestId, reply = reply })
	while #kept > A.BuyRequestsKept do
		table.remove(kept, 1)
	end
	return reply
end

local function logOf(player: Player): Reply
	local s = store :: ArenaStore.Store
	local now = clock()
	local held = logs[player]
	if held and now >= held.at and now - held.at < A.LogReadSeconds then
		return { ok = true, log = held.list }
	end
	local list = s.readLog(player.UserId)
	if not list then
		return fail("NO_LOG")
	end
	logs[player] = { at = now, list = list }
	return { ok = true, log = list }
end

local function request(player: Player, data: any): Reply
	if type(data) ~= "table" or type(data.action) ~= "string" then
		return fail("BAD_REQUEST")
	end
	if not PlayerData.isReady(player) or not store then
		return fail("NOT_READY")
	end
	if not rateAllowed(player) then
		return fail("RATE_LIMIT")
	end
	if not hasAccount(player) then
		return fail("NO_ACCOUNT")
	end
	local action = data.action
	if action == "state" then
		return stateOf(player)
	elseif action == "setTeam" then
		return setTeam(player, data)
	elseif action == "opponents" then
		return withLock(player, function(): any
			return opponents(player, data)
		end) or fail("BUSY")
	elseif action == "attack" then
		return withLock(player, function(): any
			return attack(player, data)
		end) or fail("BUSY")
	elseif action == "buy" then
		return withLock(player, function(): any
			return buy(player, data)
		end) or fail("BUSY")
	elseif action == "log" then
		return logOf(player)
	end
	return fail("BAD_REQUEST")
end

-- Runs body every `seconds`, each run in a pcall (a failure warns once a kind and the loop goes on).
local function loop(seconds: number, kind: string, body: () -> ())
	task.spawn(function()
		while true do
			local ok, err = pcall(body :: any)
			if not ok then
				warnOnce(kind, err)
			end
			task.wait(seconds)
		end
	end)
end

function Arena.start()
	assert(store == nil, "Arena.start called twice")
	store = ArenaStore.open(clock, logLine)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local remote = remotes:FindFirstChild("Arena")
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "Arena"
		remote.Parent = remotes
	end
	assert(remote:IsA("RemoteFunction"), "Arena remote must be a RemoteFunction")
	remote.OnServerInvoke = function(player: Player, data: any)
		local ok, answer = pcall(request, player, data)
		if not ok then
			warn(PREFIX, "arena: request failed:", answer)
			return fail("SERVER_ERROR")
		end
		return answer
	end

	PlayerData.onReady(function(player: Player, _data: any)
		player:SetAttribute("ArenaRank", 0)
		joined(player)
	end)
	PlayerData.onLeaving(left)
	Players.PlayerRemoving:Connect(function(player: Player)
		limits[player] = nil
		-- (after the leaving callback has looked at what was published)
		task.delay(10, function()
			offered[player] = nil
			lastReply[player] = nil
			doneRequest[player] = nil
			published[player] = nil
			logs[player] = nil
			buys[player] = nil
		end)
	end)

	loop(A.TickSeconds, "leader tick", function()
		local s = store
		if s and not leaderPaused then
			s.leaderTick(clock())
		end
	end)
	loop(A.SettleSeconds, "settle", function()
		for _, player in Players:GetPlayers() do
			local farm = PlayerData.get(player)
			if farm and farm.arena.pending and hasAccount(player) and not busy[player] then
				spawnGuarded("settle", function()
					withLock(player, function()
						settleOne(player)
					end)
				end)
			end
		end
	end)
	loop(A.LadderRefreshSeconds, "ladder refresh", refreshAll)
	print(PREFIX, "arena: service started")
end

-- ===== the Studio debug tools' way in (server/OwnerDebug); every call refuses outside Studio =====

local function studio(): boolean
	return RunService:IsStudio()
end

local NOT_STUDIO = "Studio only"
local NO_ACCOUNT = "The Arena needs a player with a UserId (Play, not a Start server test)"

Arena.debug = {}

function Arena.debug.clock(): number
	return clock()
end

-- The Studio memory stores the ladder runs on (nil outside Studio or on the real stores).
function Arena.debug.memory(): { data: any, memory: any }?
	if not studio() then
		return nil
	end
	return ArenaStore.memoryStores()
end

local function ready(player: Player): string?
	if not studio() then
		return NOT_STUDIO
	end
	if not hasAccount(player) then
		return NO_ACCOUNT
	end
	if not store or not PlayerData.isReady(player) then
		return "Your farm is not loaded yet"
	end
	return nil
end

-- The Arena team becomes the four strongest slimes, through the remote's own setTeam.
function Arena.debug.team(player: Player): (boolean, string)
	local why = ready(player)
	if why then
		return false, why
	end
	local ids = ArenaPlay.bestTeam(PlayerData.get(player), clock())
	local answer = setTeam(player, { ids = ids })
	if not answer.ok then
		return false, "Team refused: " .. tostring(answer.reason)
	end
	return true, string.format("Arena team: %d slimes, power %d", #answer.team, answer.power)
end

local function listText(answer: Reply): string
	local parts = {}
	for _, entry in answer.list do
		table.insert(parts, string.format("%s #%s p%d", entry.name, tostring(entry.rank or "-"), entry.power))
	end
	local text = table.concat(parts, ", ")
	if answer.refreshIn > 0 and answer.refreshIn < A.RefreshSeconds then
		text = string.format("(new list in %ds) ", answer.refreshIn) .. text
	end
	return text
end

function Arena.debug.opponents(player: Player): (boolean, string)
	local why = ready(player)
	if why then
		return false, why
	end
	local answer = withLock(player, function(): any
		return opponents(player, { refresh = true })
	end) or fail("BUSY")
	if not answer.ok then
		return false, "Opponents refused: " .. tostring(answer.reason)
	end
	return true, listText(answer)
end

-- Attacks the first opponent offered (a list is asked for when none is held), through the remote's own attack.
function Arena.debug.attackFirst(player: Player): (boolean, string)
	local why = ready(player)
	if why then
		return false, why
	end
	local answer = withLock(player, function(): any
		local held = offered[player]
		if not held or held.season ~= ArenaSeason.seasonOf(clock()) then
			local got = opponents(player, {})
			if not got.ok then
				return got
			end
		end
		local list = offered[player]
		local first = if list then list.list[1] else nil
		if not first then
			return fail("NOT_OFFERED")
		end
		return attack(player, { target = first.id, requestId = string.format("dbg-%d", math.floor(os.clock() * 1000)) })
	end) or fail("BUSY")
	if not answer.ok then
		return false, "Attack refused: " .. tostring(answer.reason)
	end
	return true,
		string.format(
			"%s vs %s in %.1fs, match %s confirming",
			if answer.won then "Won" else "Lost",
			answer.sides.defender.name,
			answer.seconds,
			answer.matchId
		)
end

function Arena.debug.state(player: Player): (boolean, string)
	local why = ready(player)
	if why then
		return false, why
	end
	local answer = stateOf(player)
	if not answer.ok then
		return false, tostring(answer.reason)
	end
	local s = store :: ArenaStore.Store
	return true,
		string.format(
			"Rank %s, %d points, %d/%d tickets, %s%s%s",
			tostring(answer.rank or "-"),
			answer.points,
			answer.tickets,
			answer.ticketsPerDay,
			if answer.pending then "match " .. answer.pending.matchId .. " in flight" else "no match in flight",
			if leaderPaused then ", leader paused" elseif s.isLeader() then ", this server leads" else "",
			if offset ~= 0 then string.format(", clock +%dd", offset // 86400) else ""
		)
end

-- Today's tickets are all back.
function Arena.debug.tickets(player: Player): (boolean, string)
	local why = ready(player)
	if why then
		return false, why
	end
	local now = clock()
	PlayerData.update(player, function(live: any)
		live.arena.day, live.arena.used = ArenaSeason.dayOf(now), 0
	end)
	PlayerData.markKeyMoment(player, "debug")
	return true, "Tickets: " .. A.TicketsPerDay
end

function Arena.debug.points(player: Player, amount: number): (boolean, string)
	local why = ready(player)
	if why then
		return false, why
	end
	PlayerData.update(player, function(live: any)
		live.arena.points += math.max(0, math.floor(amount))
	end)
	PlayerData.markKeyMoment(player, "debug")
	return true, string.format("+%d Arena points", amount)
end

-- Moves the player to `rank` on this season's ladder in the Studio memory store (joined first when not on it).
function Arena.debug.rank(player: Player, rank: number): (boolean, string)
	local why = ready(player)
	if why then
		return false, why
	end
	local deps = ArenaStore.memoryStores()
	if not deps then
		return false, "Only on the Studio memory ladder"
	end
	local now = clock()
	local season = ArenaSeason.seasonOf(now)
	local uid = tostring(player.UserId)
	local farm = PlayerData.get(player)
	local mine = ArenaPlay.snapshotDoc(farm, ArenaPlay.fightTeam(farm, now), "")
	local power = if mine then mine.power else 0
	local name = nameOf(player)
	local placed = 0
	local final = false
	deps.data:UpdateAsync(ArenaStore.ladderKey(season), function(old: any): any
		local doc = old or ArenaLadder.new(season)
		if doc.final then
			final = true
			return nil
		end
		ArenaLadder.join(doc, uid, name, power)
		table.remove(doc.order, assert(table.find(doc.order, uid)))
		placed = math.clamp(math.floor(rank), 1, #doc.order + 1)
		table.insert(doc.order, placed, uid)
		return doc
	end)
	if final then
		return false, "This season's ladder is final"
	end
	local s = store :: ArenaStore.Store
	showRank(player, (s.readLadder(season, 0)))
	table.clear(offered)
	print(PREFIX, "arena: debug moved", player.Name, "to rank", placed)
	return true, "Rank " .. placed
end

-- The clock jumps past the current season's final time: the leader closes it and the rewards are claimed now.
function Arena.debug.endSeason(): (boolean, string)
	if not studio() then
		return false, NOT_STUDIO
	end
	-- (never on the real stores: it would close the live season's ladder for every player)
	if not ArenaStore.memoryStores() then
		return false, "Only on the Studio memory ladder"
	end
	local season = ArenaSeason.seasonOf(clock())
	local s = store
	-- (the results in flight reach the ladder first: their queue items would expire in the jump)
	if s and not leaderPaused then
		s.leaderTick(clock())
	end
	offset = ArenaSeason.finalAt(season) + 5 - os.time()
	table.clear(offered)
	print(PREFIX, "arena: debug clock moved", offset // 86400, "days on, season", season, "is over")
	spawnGuarded("debug season end", function()
		local current = store
		if current and not leaderPaused then
			current.leaderTick(clock())
		end
		refreshAll()
	end)
	return true, string.format("Season %d is over (clock +%dd); rewards are claimed now", season, offset // 86400)
end

-- The clock is real again. On the memory ladder the season it is now is opened again (End season closed it), the leader
-- lease is dropped and this server starts a new store, so the write budget set in the moved time does not hold it back.
function Arena.debug.clockReset(): (boolean, string)
	if not studio() then
		return false, NOT_STUDIO
	end
	local deps = ArenaStore.memoryStores()
	if not deps then
		return false, "Only on the Studio memory ladder"
	end
	if offset == 0 then
		return true, "The clock is already real"
	end
	offset = 0
	table.clear(offered)
	local season = ArenaSeason.seasonOf(clock())
	local lease = deps.memory:GetHashMap(A.LeaseMapName)
	pcall(function()
		lease:RemoveAsync(A.LeaseKey)
	end)
	pcall(function()
		deps.data:UpdateAsync(ArenaStore.ladderKey(season), function(doc: any): any
			if type(doc) == "table" and doc.final then
				doc.final = nil
				return doc
			end
			return nil
		end)
	end)
	storeCount += 1
	store = ArenaStore.new({
		data = deps.data,
		queue = deps.memory:GetQueue(A.QueueName, A.InvisibleSeconds),
		lease = lease,
		serverId = "studio-" .. storeCount,
		clock = clock,
		log = logLine,
	})
	print(PREFIX, "arena: debug clock reset, season", season, "open again")
	return true, string.format("Clock reset; season %d open again", season)
end

function Arena.debug.pauseLeader(): (boolean, string)
	if not studio() then
		return false, NOT_STUDIO
	end
	if not ArenaStore.memoryStores() then
		return false, "Only on the Studio memory ladder"
	end
	leaderPaused = not leaderPaused
	print(PREFIX, "arena: debug leader ticks", if leaderPaused then "paused" else "back on")
	return true,
		if leaderPaused
			then "Leader ticks paused here: another server takes over after the lease"
			else "Leader ticks back on"
end

return Arena
