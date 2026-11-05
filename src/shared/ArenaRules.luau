--!strict
-- The Arena on the farm (farm.arena, schema 11): tickets, the team, the one match in flight and what it grants. Pure:
-- every time is a parameter, nothing yields. The ladder lives elsewhere (shared/ArenaLadder, server/ArenaStore); a match
-- is a transaction: beginAttack stores it as `pending`, and only the ladder's outcome for the same seq (settle -> confirm)
-- grants its points and clears it, so a lost message, a retry or a second login never grants twice or loses a match.
local ArenaQuests = if script then require(script.Parent.ArenaQuests) else require("./ArenaQuests")
local ArenaSeason = if script then require(script.Parent.ArenaSeason) else require("./ArenaSeason")
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Gear = if script then require(script.Parent.Gear) else require("./Gear")

type Farm = typeof(FarmState.newFarm(0))
type Arena = typeof(FarmState.newArena(0))
-- (FarmState's ArenaPending, or nil)
type MaybePending = typeof(((nil :: any) :: Arena).pending)
-- (the same shapes as shared/ArenaLadder's Out, Doc and Result, repeated because those types cannot be read through the
-- Lune-friendly require)
export type Out = { seq: number, won: boolean, rankAfter: number, climbed: number, points: number, void: boolean? }
type DocLike = { season: number, final: boolean?, players: { [string]: any } }
export type Result = {
	attacker: string,
	seq: number,
	defender: string,
	won: boolean,
	above: boolean,
	season: number,
	name: string,
	power: number,
}
-- What the server knows when it begins an attack: the attacker, the defender it fought (rank 0 for a champion), the fight's
-- result and seed, the team's power and the client's request id.
export type AttackInfo = {
	userId: number | string,
	defender: string,
	defenderName: string,
	defenderRank: number,
	above: boolean,
	stronger: boolean,
	won: boolean,
	power: number,
	seed: number,
	requestId: string,
}
export type Grant = { id: string, points: number }

local A = Config.Arena
local ArenaRules = {}

function ArenaRules.ticketsLeft(farm: Farm, now: number): number
	local arena = farm.arena
	if arena.day ~= ArenaSeason.dayOf(now) then
		return A.TicketsPerDay
	end
	return math.max(0, A.TicketsPerDay - arena.used)
end

-- The team's slimes that are still on the farm, in order.
function ArenaRules.team(farm: Farm): { string }
	local out: { string } = {}
	for _, id in farm.arena.team do
		if FarmState.findSlime(farm, id) then
			table.insert(out, id)
		end
	end
	return out
end

-- Sets the Arena team: own slimes, 1..TeamSize of them, each once, none a ghost. (ok, reason?) with reason "BAD_TEAM",
-- "TEAM_SIZE", "DUPLICATE", "NOT_OWNED" or "GHOST".
function ArenaRules.setTeam(farm: Farm, ids: any, now: number): (boolean, string?)
	if type(ids) ~= "table" then
		return false, "BAD_TEAM"
	end
	local count = 0
	for key in ids do
		count += 1
		if type(key) ~= "number" or key ~= count then
			return false, "BAD_TEAM"
		end
	end
	if count < 1 or count > A.TeamSize then
		return false, "TEAM_SIZE"
	end
	local seen: { [string]: boolean } = {}
	local team: { string } = {}
	for _, id in ids do
		if type(id) ~= "string" then
			return false, "BAD_TEAM"
		end
		if seen[id] then
			return false, "DUPLICATE"
		end
		seen[id] = true
		local slime = FarmState.findSlime(farm, id)
		if not slime then
			return false, "NOT_OWNED"
		end
		if slime.ghostUntil and slime.ghostUntil > now then
			return false, "GHOST"
		end
		table.insert(team, id)
	end
	farm.arena.team = team
	return true, nil
end

-- The season counters follow the given season: a farm still on an older one closes it (its wins wait in the history
-- for the reward) and starts at zero. Returns whether it changed.
function ArenaRules.newSeason(farm: Farm, season: number): boolean
	local arena = farm.arena
	if arena.season == season then
		return false
	end
	local key = tostring(arena.season)
	if (arena.seasonWins > 0 or arena.bestRank > 0) and not arena.claimed[key] then
		local known = false
		for _, entry in arena.history do
			if entry.season == arena.season then
				known = true
			end
		end
		if not known then
			table.insert(arena.history, { season = arena.season, rank = 0, badge = nil, wins = arena.seasonWins })
			table.sort(arena.history, function(a, b)
				return a.season < b.season
			end)
			while #arena.history > A.KeepSeasons do
				table.remove(arena.history, 1)
			end
		end
	end
	arena.season, arena.seasonWins, arena.bestRank = season, 0, 0
	return true
end

-- Begins an attack whose fight the server has already run: uses a ticket, numbers the match and stores it in flight.
-- (false, "PENDING", the match in flight) while one is in flight: a re-sent request finds its own match by requestId.
-- Otherwise (false, "NO_TICKETS" | "SEASON_ENDING" | "NO_TEAM") or (true, nil, the new match).
function ArenaRules.beginAttack(farm: Farm, now: number, info: AttackInfo): (boolean, string?, MaybePending)
	local arena = farm.arena
	if arena.pending then
		return false, "PENDING", arena.pending
	end
	if ArenaRules.ticketsLeft(farm, now) <= 0 then
		return false, "NO_TICKETS", nil
	end
	if ArenaSeason.locked(now) then
		return false, "SEASON_ENDING", nil
	end
	if #ArenaRules.team(farm) == 0 then
		return false, "NO_TEAM", nil
	end
	local today = ArenaSeason.dayOf(now)
	if arena.day ~= today then
		arena.day, arena.used = today, 0
	end
	local season = ArenaSeason.seasonOf(now)
	ArenaRules.newSeason(farm, season)
	arena.used += 1
	arena.seq += 1
	local pending = {
		matchId = tostring(info.userId) .. ":" .. arena.seq,
		seq = arena.seq,
		season = season,
		defender = info.defender,
		defenderName = info.defenderName,
		defenderRank = info.defenderRank,
		above = info.above,
		stronger = info.stronger,
		won = info.won,
		power = info.power,
		seed = info.seed,
		at = now,
		sentAt = now,
		requestId = info.requestId,
	}
	arena.pending = pending
	return true, nil, pending
end

-- The ladder result to send for the match in flight (nil when none).
function ArenaRules.result(farm: Farm, userId: number | string, name: string): Result?
	local pending = farm.arena.pending
	if not pending then
		return nil
	end
	return {
		attacker = tostring(userId),
		seq = pending.seq,
		defender = pending.defender,
		won = pending.won,
		above = pending.above,
		season = pending.season,
		name = name,
		power = pending.power,
	}
end

-- The match in flight was sent again at `now`.
function ArenaRules.markSent(farm: Farm, now: number)
	local pending = farm.arena.pending
	if pending then
		pending.sentAt = now
	end
end

-- The farm's match number never falls behind the ladder's (a farm saved before its last match would otherwise send
-- numbers the ladder reads as old). Returns whether it moved.
function ArenaRules.syncSeq(farm: Farm, ladderSeq: number): boolean
	if type(ladderSeq) == "number" and ladderSeq > farm.arena.seq then
		farm.arena.seq = math.floor(ladderSeq)
		return true
	end
	return false
end

-- What to do with the match in flight, given the ladder of its season: "none" (no match), "wait", "confirm" (with the
-- outcome), "void" (the season closed without it, or the ladder has moved past it) or "resend" (nothing for ResendSeconds).
function ArenaRules.settle(farm: Farm, doc: DocLike?, userId: number | string, now: number): (string, Out?)
	local pending = farm.arena.pending
	if not pending then
		return "none", nil
	end
	if not doc or doc.season ~= pending.season then
		return "wait", nil
	end
	local meta = doc.players[tostring(userId)]
	local out = if type(meta) == "table" then meta.out else nil
	if type(out) == "table" and out.seq == pending.seq then
		return "confirm", out
	end
	if doc.final then
		return "void", nil
	end
	if type(meta) == "table" and type(meta.seq) == "number" and meta.seq >= pending.seq then
		return "void", nil
	end
	if now - pending.sentAt >= A.ResendSeconds then
		return "resend", nil
	end
	return "wait", nil
end

-- The ladder's outcome for the match in flight: grants its points and any quest it finished, counts the season win and
-- the best rank, and clears the match, all at once. Anything but the outcome of that very match grants nothing, so a
-- second call grants nothing. Returns the points granted and the quests finished.
function ArenaRules.confirm(farm: Farm, now: number, out: any): (number, { Grant })
	local arena = farm.arena
	local pending = arena.pending
	if not pending or type(out) ~= "table" or out.seq ~= pending.seq then
		return 0, {}
	end
	if out.void then
		ArenaRules.void(farm, now)
		return 0, {}
	end
	if pending.season > arena.season then
		ArenaRules.newSeason(farm, pending.season)
	end
	-- (the quests and goals of Rewards count the attacks the ladder settled)
	farm.lifetime.arenaAttacks += 1
	local points = if type(out.points) == "number" then math.max(0, math.floor(out.points)) else 0
	-- (the quests count the fight's own day, week and season)
	local grants = ArenaQuests.record(arena.quests, pending.at, { won = out.won == true, stronger = pending.stronger })
	for _, grant in grants do
		points += grant.points
	end
	arena.points += points
	if pending.season == arena.season then
		if out.won == true then
			arena.seasonWins += 1
		end
		local rank = if type(out.rankAfter) == "number" then out.rankAfter else 0
		if rank > 0 and (arena.bestRank == 0 or rank < arena.bestRank) then
			arena.bestRank = rank
		end
	end
	arena.pending = nil
	return points, grants
end

-- The match in flight counts for nothing: it is cleared, and its ticket comes back if it is still the UTC day it was
-- used. Returns (cleared, ticket given back).
function ArenaRules.void(farm: Farm, now: number): (boolean, boolean)
	local arena = farm.arena
	local pending = arena.pending
	if not pending then
		return false, false
	end
	arena.pending = nil
	local today = ArenaSeason.dayOf(now)
	if ArenaSeason.dayOf(pending.at) == today and arena.day == today and arena.used > 0 then
		arena.used -= 1
		return true, true
	end
	return true, false
end

-- The seasons a login should look at for a reward: the last ClaimLookback seasons that are final by now, unclaimed.
function ArenaRules.unclaimed(farm: Farm, now: number): { number }
	local out: { number } = {}
	local season = ArenaSeason.seasonOf(now)
	for _ = 1, A.ClaimLookback do
		season = ArenaSeason.previous(season)
		if now >= ArenaSeason.finalAt(season) and not farm.arena.claimed[tostring(season)] then
			table.insert(out, season)
		end
	end
	return out
end

-- A final season's reward, once: the points for the rank (nil or 0 for no rank) are added and the season is written in
-- the history. Returns the points and the badge (0, nil when already claimed).
function ArenaRules.claimSeason(farm: Farm, season: number, rank: number?): (number, string?)
	local arena = farm.arena
	local key = tostring(season)
	if arena.claimed[key] then
		return 0, nil
	end
	local points, badge = ArenaSeason.rewardFor(rank)
	arena.claimed[key] = true
	-- the claimed map keeps the newest KeepSeasons seasons
	local seasons: { number } = {}
	for k in arena.claimed do
		table.insert(seasons, tonumber(k) or 0)
	end
	table.sort(seasons)
	for i = 1, #seasons - A.KeepSeasons do
		arena.claimed[tostring(seasons[i])] = nil
	end
	local at: number? = nil
	for i, e in arena.history do
		if e.season == season then
			at = i
		end
	end
	local finalRank = if rank and rank > 0 then math.floor(rank) else 0
	if at then
		arena.history[at].rank, arena.history[at].badge = finalRank, badge
	elseif finalRank > 0 or (arena.season == season and arena.seasonWins > 0) then
		local wins = if arena.season == season then arena.seasonWins else 0
		table.insert(arena.history, { season = season, rank = finalRank, badge = badge, wins = wins })
		table.sort(arena.history, function(a, b)
			return a.season < b.season
		end)
		while #arena.history > A.KeepSeasons do
			table.remove(arena.history, 1)
		end
	end
	arena.points += points
	return points, badge
end

-- ===== the shop =====

export type ShopRow = {
	id: string,
	kind: string,
	item: string,
	count: number,
	price: number,
	weeklyLimit: number,
	left: number,
	affordable: boolean,
}

local function offerOf(itemId: any): any
	if type(itemId) ~= "string" then
		return nil
	end
	for _, offer in A.Shop do
		if offer.id == itemId then
			return offer
		end
	end
	return nil
end

-- What was bought of an item this UTC week (a farm still on an older week has bought nothing yet).
local function boughtThisWeek(farm: Farm, now: number, itemId: string): number
	local arena = farm.arena
	if arena.week ~= ArenaSeason.weekOf(now) then
		return 0
	end
	return arena.bought[itemId] or 0
end

-- The shop for the screen, in order: each row with how many buys are left this week and whether the points reach it.
function ArenaRules.shop(farm: Farm, now: number): { ShopRow }
	local rows: { ShopRow } = {}
	for _, offer in A.Shop do
		local left = math.max(0, offer.weeklyLimit - boughtThisWeek(farm, now, offer.id))
		table.insert(rows, {
			id = offer.id,
			kind = offer.kind,
			item = offer.item,
			count = offer.count,
			price = offer.price,
			weeklyLimit = offer.weeklyLimit,
			left = left,
			affordable = left > 0 and farm.arena.points >= offer.price,
		})
	end
	return rows
end

-- One buy: the points are taken and the item given in this one call. A new week first clears what was bought. (ok, reason?)
-- with reason "UNKNOWN_ITEM", "SOLD_OUT" (the week's limit is reached) or "NO_POINTS"; a refusal changes nothing but that
-- week reset.
function ArenaRules.buy(farm: Farm, now: number, itemId: any): (boolean, string?)
	local arena = farm.arena
	local week = ArenaSeason.weekOf(now)
	if arena.week ~= week then
		arena.week, arena.bought = week, {}
	end
	local offer = offerOf(itemId)
	if not offer then
		return false, "UNKNOWN_ITEM"
	end
	local bought = arena.bought[offer.id] or 0
	if bought >= offer.weeklyLimit then
		return false, "SOLD_OUT"
	end
	if arena.points < offer.price then
		return false, "NO_POINTS"
	end
	if offer.kind == "gear" then
		if not Gear.give(farm, offer.item, offer.count) then
			return false, "UNKNOWN_ITEM"
		end
	else
		farm.materials[offer.item] = (farm.materials[offer.item] or 0) + offer.count
	end
	arena.points -= offer.price
	arena.bought[offer.id] = bought + 1
	return true, nil
end

return ArenaRules
