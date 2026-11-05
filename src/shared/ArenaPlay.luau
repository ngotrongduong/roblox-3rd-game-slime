--!strict
-- The pure parts of the Arena's server service (server/Arena wires them to the remote, the farm and the stores): the
-- client's request id, the team that fights, the defence snapshot written to Def_<userId> and its check when it is read
-- back, the opponents offered, the summaries the state answer shows, the log entries and the defence counters. Nothing
-- here yields except the snapshot reader `offer` is given.
local ArenaBots = if script then require(script.Parent.ArenaBots) else require("./ArenaBots")
local ArenaFight = if script then require(script.Parent.ArenaFight) else require("./ArenaFight")
local ArenaRules = if script then require(script.Parent.ArenaRules) else require("./ArenaRules")
local ArenaSeason = if script then require(script.Parent.ArenaSeason) else require("./ArenaSeason")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")

type Farm = typeof(FarmState.newFarm(0))
type Fighter = typeof(ArenaFight.fighter(FarmState.newFarm(0).slimes[1], ""))
type Team = typeof(ArenaBots.team(0, "b1"))
export type Look = { Colour: string, Material: string?, DualId: string?, SecretId: string? }
-- A published defence (Def_<userId>): the team's fighters and looks in seat order, its power and the owner's name.
export type Snapshot = { v: number, name: string, fighters: { Fighter }, looks: { Look }, power: number }
-- An opponent the server offered: what the client sees, and the fighters it will meet (kept on the server).
export type Entry = {
	id: string,
	rank: number?,
	name: string,
	power: number,
	looks: { Look },
	above: boolean,
	fighters: { Fighter },
}
-- (the same shape as shared/ArenaLadder's Opponent)
type Pick = { id: string, rank: number?, above: boolean }

local A = Config.Arena
local ArenaPlay = {}

local function finite(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- A client's request id: a short plain string (letters, digits, - _ : .).
function ArenaPlay.validRequestId(id: any): boolean
	return type(id) == "string"
		and #id >= 1
		and #id <= A.RequestIdMaxLength
		and string.match(id, "^[%w%-_:%.]+$") ~= nil
end

-- A player's id on the ladder (tostring of a positive UserId); bots are "b<n>", champions "c<n>".
function ArenaPlay.isPlayerId(id: any): boolean
	return type(id) == "string" and string.match(id, "^%d+$") ~= nil
end

-- The team's slimes that can fight now: on the farm and not ghosts, in seat order.
function ArenaPlay.fightTeam(farm: Farm, now: number): { string }
	local out: { string } = {}
	for _, id in ArenaRules.team(farm) do
		local slime = FarmState.findSlime(farm, id)
		if slime and not (slime.ghostUntil and slime.ghostUntil > now) then
			table.insert(out, id)
		end
	end
	return out
end

function ArenaPlay.teamKey(ids: { string }): string
	return table.concat(ids, ",")
end

-- The TeamSize strongest slimes of the farm that are not ghosts (strongest first, ties by id).
function ArenaPlay.bestTeam(farm: Farm, now: number): { string }
	local rows: { { id: string, power: number } } = {}
	for _, slime in farm.slimes do
		if not (slime.ghostUntil and slime.ghostUntil > now) then
			table.insert(rows, { id = slime.id, power = ArenaFight.power({ ArenaFight.fighter(slime, "") }) })
		end
	end
	table.sort(rows, function(a, b)
		if a.power ~= b.power then
			return a.power > b.power
		end
		return a.id < b.id
	end)
	local out: { string } = {}
	for i = 1, math.min(A.TeamSize, #rows) do
		table.insert(out, rows[i].id)
	end
	return out
end

-- The defence snapshot of these slimes (nil when the list is empty, too long, repeats or names a slime not owned).
function ArenaPlay.snapshotDoc(farm: Farm, ids: { string }, name: string): Snapshot?
	local snap = ArenaFight.snapshot(farm, ids)
	if not snap then
		return nil
	end
	return { v = A.SnapshotVersion, name = name, fighters = snap.fighters, looks = snap.looks, power = snap.power }
end

-- A snapshot read back from the store, checked and copied field by field; nil when it cannot be fought (no fighters, too
-- many, a repeated id, a stat that is not a number). The power is worked out again, never read.
function ArenaPlay.cleanSnapshot(raw: any): Snapshot?
	if type(raw) ~= "table" or type(raw.fighters) ~= "table" or type(raw.looks) ~= "table" then
		return nil
	end
	local count = #raw.fighters
	if count < 1 or count > A.TeamSize or #raw.looks ~= count then
		return nil
	end
	local fighters: { Fighter } = {}
	local looks: { Look } = {}
	local seen: { [string]: boolean } = {}
	for i = 1, count do
		local f = raw.fighters[i]
		if type(f) ~= "table" or type(f.id) ~= "string" or f.id == "" or seen[f.id] then
			return nil
		end
		seen[f.id] = true
		for _, key in { "attack", "defence", "speed", "hp" } do
			if not finite(f[key]) or f[key] < 0 then
				return nil
			end
		end
		if f.hp <= 0 then
			return nil
		end
		table.insert(fighters, {
			id = f.id,
			attack = f.attack,
			defence = f.defence,
			speed = f.speed,
			hp = f.hp,
			maxHp = if finite(f.maxHp) and f.maxHp >= f.hp then f.maxHp else f.hp,
			role = if type(f.role) == "string" then f.role else nil,
		})
		local look = raw.looks[i]
		if type(look) ~= "table" or type(look.Colour) ~= "string" then
			return nil
		end
		table.insert(looks, {
			Colour = look.Colour,
			Material = if type(look.Material) == "string" then look.Material else nil,
			DualId = if type(look.DualId) == "string" then look.DualId else nil,
			SecretId = if type(look.SecretId) == "string" then look.SecretId else nil,
		})
	end
	return {
		v = if finite(raw.v) then raw.v else A.SnapshotVersion,
		name = if type(raw.name) == "string" then raw.name else "",
		fighters = fighters,
		looks = looks,
		power = ArenaFight.power(fighters),
	}
end

-- A bot's or champion's team for the season (worked out once a season and kept).
local npcSeason = -1
local npcTeams: { [string]: Team } = {}
function ArenaPlay.npc(season: number, id: string): Team
	if season ~= npcSeason then
		npcSeason, npcTeams = season, {}
	end
	local team = npcTeams[id]
	if not team then
		team = ArenaBots.team(season, id)
		npcTeams[id] = team
	end
	return team
end

local function npcEntry(season: number, id: string, rank: number?, above: boolean): Entry
	local team = ArenaPlay.npc(season, id)
	return {
		id = id,
		rank = rank,
		name = team.name,
		power = team.power,
		looks = team.looks,
		above = above,
		fighters = team.fighters,
	}
end

-- The opponents to offer for the ladder's picks (shared/ArenaLadder.opponents): a bot or champion fields its season team;
-- a player is offered only when `snapshotOf(userId)` gives a snapshot that can be fought, else the next champion takes the
-- place, so the list keeps its length.
function ArenaPlay.offer(
	doc: any,
	picks: { Pick },
	season: number,
	snapshotOf: (userId: number) -> Snapshot?
): { Entry }
	local out: { Entry } = {}
	local used: { [string]: boolean } = {}
	for _, pick in picks do
		local entry: Entry? = nil
		if ArenaBots.isBot(pick.id) or ArenaBots.isChampion(pick.id) then
			entry = npcEntry(season, pick.id, pick.rank, pick.above)
		elseif ArenaPlay.isPlayerId(pick.id) then
			local snap = snapshotOf(tonumber(pick.id) :: number)
			if snap then
				local meta = if type(doc) == "table" and type(doc.players) == "table" then doc.players[pick.id] else nil
				entry = {
					id = pick.id,
					rank = pick.rank,
					name = if type(meta) == "table" and type(meta.n) == "string" then meta.n else snap.name,
					power = snap.power,
					looks = snap.looks,
					above = pick.above,
					fighters = snap.fighters,
				}
			end
		end
		if entry then
			table.insert(out, entry)
			used[entry.id] = true
		end
	end
	local champion = 1
	while #out < #picks do
		local id = "c" .. champion
		if not used[id] then
			table.insert(out, npcEntry(season, id, nil, false))
			used[id] = true
		end
		champion += 1
	end
	return out
end

-- What the client is told of an offered opponent (its fighters stay on the server).
function ArenaPlay.public(entry: Entry): { [string]: any }
	return {
		id = entry.id,
		rank = entry.rank,
		name = entry.name,
		power = entry.power,
		looks = entry.looks,
		above = entry.above,
	}
end

function ArenaPlay.find(list: { Entry }, id: any): Entry?
	for _, entry in list do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- What shared/ArenaRules.beginAttack needs to know about a fight the server has just run against an offered opponent.
function ArenaPlay.attackInfo(
	userId: number,
	entry: Entry,
	won: boolean,
	power: number,
	seed: number,
	requestId: string
)
	return {
		userId = userId,
		defender = entry.id,
		defenderName = entry.name,
		defenderRank = entry.rank or 0,
		above = entry.above,
		stronger = entry.power > power,
		won = won,
		power = power,
		seed = seed,
		requestId = requestId,
	}
end

-- The match in flight as the client sees it (nil when none).
function ArenaPlay.pendingSummary(farm: Farm): { [string]: any }?
	local pending = farm.arena.pending
	if not pending then
		return nil
	end
	return {
		matchId = pending.matchId,
		won = pending.won,
		defenderName = pending.defenderName,
		status = "confirming",
	}
end

-- Each quest's progress as of `now` (a count of a day, week or season that is over reads 0).
function ArenaPlay.quests(farm: Farm, now: number): { { [string]: any } }
	local state = farm.arena.quests
	local over = {
		day = state.day ~= ArenaSeason.dayOf(now),
		week = state.week ~= ArenaSeason.weekOf(now),
		season = state.season ~= ArenaSeason.seasonOf(now),
	}
	local out = {}
	for _, quest in A.Quests do
		local live = not (over :: any)[quest.period]
		table.insert(out, {
			id = quest.id,
			period = quest.period,
			wins = quest.wins,
			points = quest.points,
			stronger = quest.stronger,
			count = if live then state.counts[quest.id] or 0 else 0,
			done = live and state.done[quest.id] == true,
		})
	end
	return out
end

-- The top `n` of a ladder: rank, id, name, power and season points (a bot's name and power from its season team).
function ArenaPlay.top(doc: any, n: number): { { [string]: any } }
	local out = {}
	for rank = 1, math.min(n, #doc.order) do
		local id = doc.order[rank]
		local meta = doc.players[id]
		if type(meta) == "table" then
			table.insert(out, { rank = rank, id = id, name = meta.n, power = meta.p, points = meta.sp })
		elseif ArenaBots.isBot(id) then
			local team = ArenaPlay.npc(doc.season, id)
			table.insert(out, { rank = rank, id = id, name = ArenaBots.name(id), power = team.power, points = 0 })
		end
	end
	return out
end

-- The log lines of a confirmed match: the attacker's, and the defender's when the defender is a player.
function ArenaPlay.logEntries(
	pending: any,
	out: any,
	attackerId: string,
	attackerName: string,
	granted: number,
	now: number
): ({ [string]: any }, { [string]: any }?)
	local won = out.won == true
	local mine = {
		kind = "attack",
		at = now,
		matchId = pending.matchId,
		vs = pending.defenderName,
		vsId = pending.defender,
		won = won,
		points = granted,
		rank = if type(out.rankAfter) == "number" then out.rankAfter else 0,
	}
	local theirs = if ArenaPlay.isPlayerId(pending.defender)
		then {
			kind = "defence",
			at = now,
			matchId = pending.matchId,
			vs = attackerName,
			vsId = attackerId,
			held = not won,
		}
		else nil
	return mine, theirs
end

-- The farm's defence counters from what the stores hold: `wins` is this season's defences won (the ladder's dw), the
-- streak the defences held in a row at the end of the log (Log_<userId>; a log with no loss in it never shortens a
-- streak counted before), `best` the longest streak seen. Either source may be nil. Returns whether anything changed.
function ArenaPlay.applyDefence(farm: Farm, dw: any, log: any): boolean
	local defense = farm.arena.defense
	local changed = false
	if finite(dw) and dw >= 0 and math.floor(dw) ~= defense.wins then
		defense.wins = math.floor(dw)
		changed = true
	end
	if type(log) == "table" then
		local streak, lost = 0, false
		for i = #log, 1, -1 do
			local entry = log[i]
			if type(entry) == "table" and entry.kind == "defence" then
				if entry.held == true then
					streak += 1
				else
					lost = true
					break
				end
			end
		end
		if not lost then
			streak = math.max(streak, defense.streak)
		end
		if streak ~= defense.streak then
			defense.streak = streak
			changed = true
		end
		if streak > defense.best then
			defense.best = streak
			changed = true
		end
	end
	return changed
end

return ArenaPlay
