--!strict
-- The Market's leaderboard, the plain part (docs/MAP.md 1.3): the best slime of a farm, how a score is stored, how the top is
-- ranked and merged, and how a row travels to the clients. The server (Leaderboard, LeaderboardStore) reads the farms and
-- the DataStore; nothing here asks a client for anything.
local Config = if script then require(script.Parent.Config) else require("./Config")
local FarmState = if script then require(script.Parent.FarmState) else require("./FarmState")
local Stats = if script then require(script.Parent.Stats) else require("./Stats")

type Farm = typeof(FarmState.newFarm(0))

-- One line of the board: whose slime, its name, its level, and the second (server time) that level was first reached.
export type Entry = { userId: number, player: string, slime: string, level: number, at: number }
-- A farm's best living slime.
export type Best = { id: string, name: string, level: number }

local Leaderboard = {}

-- A name fit to print on the board: control characters turned to spaces, the ends trimmed, cut to the limit (never in the
-- middle of a letter); the fallback when nothing is left.
function Leaderboard.cleanName(text: any, fallback: string): string
	if type(text) ~= "string" or utf8.len(text) == nil then
		return fallback
	end
	local clean = string.gsub(text, "%c", " ")
	clean = string.match(clean, "^%s*(.-)%s*$") or ""
	local limit = Config.Leaderboard.MaxNameLength
	local length = utf8.len(clean) or 0
	if length > limit then
		clean = string.sub(clean, 1, (utf8.offset(clean, limit + 1) or #clean + 1) - 1)
		clean = string.match(clean, "^(.-)%s*$") or ""
	end
	return if clean == "" then fallback else clean
end

-- The name the board shows for a slime.
function Leaderboard.slimeName(slime: { name: any }): string
	return Leaderboard.cleanName(slime.name, Config.Leaderboard.FallbackSlime)
end

-- The farm's highest-level living slime (a fallen one, still a ghost at `now`, does not count). A tie goes to the older
-- slime, then to the smaller id, so the answer never depends on the order of the list. nil when no slime lives.
function Leaderboard.bestSlime(farm: Farm, now: number): Best?
	local best: any = nil
	local bestLevel = 0
	for _, slime in farm.slimes do
		if slime.ghostUntil ~= nil and slime.ghostUntil > now then
			continue
		end
		local level = Stats.level(slime.stats)
		local better = best == nil
			or level > bestLevel
			or (
				level == bestLevel
				and (slime.createdAt < best.createdAt or (slime.createdAt == best.createdAt and slime.id < best.id))
			)
		if better then
			best, bestLevel = slime, level
		end
	end
	if best == nil then
		return nil
	end
	return { id = best.id, name = Leaderboard.slimeName(best), level = bestLevel }
end

-- The number the OrderedDataStore keeps: the level first, then the earlier second first, so the store's own order is the
-- board's order. `at` is whole seconds from 0 up to TimeScale.
function Leaderboard.encode(level: number, at: number): number
	local scale = Config.Leaderboard.TimeScale
	local seconds = math.clamp(math.floor(at), 0, scale - 1)
	return math.max(0, math.floor(level)) * scale + (scale - 1 - seconds)
end

function Leaderboard.decode(score: number): (number, number)
	local scale = Config.Leaderboard.TimeScale
	return score // scale, scale - 1 - score % scale
end

-- Whether `a` stands above `b`: the higher level, then the earlier second, then the smaller user id.
local function above(a: Entry, b: Entry): boolean
	if a.level ~= b.level then
		return a.level > b.level
	elseif a.at ~= b.at then
		return a.at < b.at
	end
	return a.userId < b.userId
end

-- The best `count` entries in board order (a new list; the entries are shared).
function Leaderboard.rank(entries: { Entry }, count: number): { Entry }
	local sorted = table.clone(entries)
	table.sort(sorted, above)
	for i = #sorted, count + 1, -1 do
		sorted[i] = nil
	end
	return sorted
end

-- The stored top and the players here with their live bests, one line a player, ranked. A player's line is the better of
-- the two: what they reached before is not lost when they sell the slime, and a level reached a minute ago shows before
-- it has been stored. At the same level the live line wins (its names are fresh) but keeps the earlier second.
function Leaderboard.merge(stored: { Entry }, live: { Entry }, count: number): { Entry }
	local byUser: { [number]: Entry } = {}
	for _, entry in stored do
		local known = byUser[entry.userId]
		if known == nil or above(entry, known) then
			byUser[entry.userId] = entry
		end
	end
	for _, entry in live do
		local known = byUser[entry.userId]
		if known == nil or entry.level > known.level then
			byUser[entry.userId] = entry
		elseif entry.level == known.level then
			local merged = table.clone(entry)
			merged.at = math.min(entry.at, known.at)
			byUser[entry.userId] = merged
		end
	end
	local all: { Entry } = {}
	for _, entry in byUser do
		table.insert(all, entry)
	end
	return Leaderboard.rank(all, count)
end

-- Whether a player's best should be sent now: it is higher than the last one sent, and the last send was at least
-- WriteGapSeconds ago (or they are leaving, which is never made to wait). `sentAt` nil: nothing sent yet.
function Leaderboard.writeDue(sentLevel: number, sentAt: number?, level: number, now: number, leaving: boolean): boolean
	if level <= sentLevel then
		return false
	end
	return leaving or sentAt == nil or now - sentAt >= Config.Leaderboard.WriteGapSeconds
end

-- A line as one short text, "player<TAB>slime<TAB>level" (an attribute holds 200 characters). Names have no tabs.
function Leaderboard.encodeRow(entry: Entry): string
	return entry.player .. "\t" .. entry.slime .. "\t" .. tostring(entry.level)
end

-- player, slime and level of a published line; all nil when the text is not one.
function Leaderboard.decodeRow(text: any): (string?, string?, number?)
	if type(text) ~= "string" then
		return nil, nil, nil
	end
	local player, slime, level = string.match(text, "^([^\t]*)\t([^\t]*)\t(%d+)$")
	if player == nil or slime == nil or level == nil then
		return nil, nil, nil
	end
	return player, slime, tonumber(level)
end

return Leaderboard
