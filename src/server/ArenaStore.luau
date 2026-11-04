--!strict
-- Everything the Arena reads or writes across servers, stores injected (the Lune tests and a Studio play test use
-- server/ArenaMemory and a memory DataStore; ArenaStore.open picks them):
--   DataStore  Ladder_<season>  the season's ladder (shared/ArenaLadder's Doc), written by ONE server only, the leader
--              Def_<userId>     a player's published defence team;  Log_<userId>  the last Config.Arena.LogKeep defences
--   Queue      every match result and ladder join, from any server, read in order by the leader
--   HashMap    the leader lease (Config.Arena.LeaseKey): { id = serverId, untilAt, next = the earliest next ladder write }
-- The leader applies each tick's items in order inside ONE UpdateAsync a season document and removes them from the queue
-- only after the write succeeded. A write that failed may still have happened: the items come back and the ladder's
-- apply reads them as "dup" (idempotent by the attacker's seq), so nothing is counted twice and nothing is lost.
-- Every call is in a pcall and logs a line starting [GooLineage]; a failed call changes nothing here.

local ArenaLadder = if script
	then require(game:GetService("ReplicatedStorage").Shared.ArenaLadder)
	else (require :: any)("../shared/ArenaLadder")
local ArenaSeason = if script
	then require(game:GetService("ReplicatedStorage").Shared.ArenaSeason)
	else (require :: any)("../shared/ArenaSeason")
local Config = if script
	then require(game:GetService("ReplicatedStorage").Shared.Config)
	else (require :: any)("../shared/Config")
local ProfileLogic = if script
	then require(game:GetService("ReplicatedStorage").Shared.ProfileLogic)
	else (require :: any)("../shared/ProfileLogic")
local ArenaMemory = if script then require(script.Parent.ArenaMemory) else (require :: any)("./ArenaMemory")

local A = Config.Arena

-- (the same shape as shared/ArenaLadder's Result, repeated because that type cannot be read through the Lune-friendly
-- require)
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
export type DataLike = {
	GetAsync: (self: any, key: string) -> any,
	SetAsync: (self: any, key: string, value: any, userIds: { number }?) -> ...any,
	UpdateAsync: (self: any, key: string, transform: (any, any) -> any) -> ...any,
}
export type QueueLike = {
	AddAsync: (self: any, value: any, expiration: number, priority: number?) -> ...any,
	ReadAsync: (self: any, count: number, allOrNothing: boolean, waitTimeout: number) -> (any, any),
	RemoveAsync: (self: any, readId: string) -> ...any,
}
export type HashMapLike = {
	UpdateAsync: (self: any, key: string, transform: (any) -> any, expiration: number) -> any,
	GetAsync: (self: any, key: string) -> any,
}
export type Deps = {
	data: DataLike,
	queue: QueueLike,
	lease: HashMapLike,
	serverId: string,
	clock: () -> number,
	log: ((message: string) -> ())?,
}
-- What one leader tick did.
export type TickInfo = {
	leader: boolean,
	read: number,
	applied: number,
	dup: number,
	void: number,
	joined: number,
	bad: number,
	writes: number,
	bytes: number,
	ok: boolean,
}
export type Store = {
	submit: (result: Result) -> boolean,
	join: (id: string, name: string, power: number, season: number?) -> boolean,
	readLadder: (season: number, maxAge: number) -> (any, string?),
	leaderTick: (now: number) -> TickInfo,
	isLeader: () -> boolean,
	writeSnapshot: (userId: number, snap: any) -> boolean,
	readSnapshot: (userId: number, maxAge: number) -> any,
	appendLog: (userId: number, entry: any) -> boolean,
	readLog: (userId: number) -> { any }?,
	-- bytes (ProfileLogic.estimateSize, about JSONEncode's length) and writes that succeeded, by key
	stats: { writes: { [string]: number }, bytes: { [string]: number } },
}

local ArenaStore = {}

function ArenaStore.ladderKey(season: number): string
	return "Ladder_" .. tostring(season)
end

local function isNum(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function validResult(r: any): boolean
	return type(r) == "table"
		and type(r.attacker) == "string"
		and string.match(r.attacker, "^%d+$") ~= nil
		and isNum(r.seq)
		and r.seq >= 1
		and type(r.defender) == "string"
		and r.defender ~= ""
		and type(r.won) == "boolean"
		and type(r.above) == "boolean"
		and isNum(r.season)
		and type(r.name) == "string"
		and isNum(r.power)
end

local function validJoin(item: any): boolean
	return type(item.id) == "string"
		and string.match(item.id, "^%d+$") ~= nil
		and type(item.n) == "string"
		and isNum(item.p)
		and isNum(item.s)
end

-- The season a queue item belongs to, nil for a malformed item.
local function seasonOfItem(item: any): number?
	if type(item) ~= "table" or not isNum(item.at) then
		return nil
	end
	if item.k == "m" and validResult(item.r) then
		return item.r.season
	elseif item.k == "j" and validJoin(item) then
		return item.s
	end
	return nil
end

-- A stored ladder this server may build on: its own season, a version it knows. Anything else is never written over.
local function usableDoc(doc: any, season: number): (boolean, string?)
	if type(doc) ~= "table" or type(doc.order) ~= "table" or type(doc.players) ~= "table" then
		return false, "unreadable"
	end
	if not isNum(doc.v) or doc.v > A.Version then
		return false, "written by a newer server (v" .. tostring(doc.v) .. ")"
	end
	if doc.season ~= season then
		return false, "holds season " .. tostring(doc.season)
	end
	return true, nil
end

function ArenaStore.new(deps: Deps): Store
	local log: (message: string) -> () = deps.log or print
	local clock = deps.clock
	local serverId = deps.serverId
	local leader = false
	-- the earliest time of the next ladder write (the write budget), carried in the lease to the next leader
	local nextWriteAt = 0
	local finalKnown: { [number]: boolean } = {}
	local ladders: { [number]: { doc: any, at: number } } = {}
	local snapshots: { [number]: { value: any, at: number } } = {}
	local store = {} :: Store
	store.stats = { writes = {}, bytes = {} }

	local function say(message: string)
		log(Config.LogPrefix .. " arena: " .. message)
	end

	local function count(key: string, value: any): number
		local size = ProfileLogic.estimateSize(value)
		store.stats.writes[key] = (store.stats.writes[key] or 0) + 1
		store.stats.bytes[key] = (store.stats.bytes[key] or 0) + size
		return size
	end

	local function push(item: any, what: string): boolean
		local ok, err = pcall(function()
			deps.queue:AddAsync(item, A.QueueItemSeconds)
		end)
		if not ok then
			say("could not send " .. what .. ": " .. tostring(err))
			return false
		end
		return true
	end

	function store.submit(result: Result): boolean
		if not validResult(result) then
			say("refused a malformed result")
			return false
		end
		return push({ k = "m", r = result, at = clock() }, "match " .. result.attacker .. ":" .. tostring(result.seq))
	end

	function store.join(id: string, name: string, power: number, season: number?): boolean
		local item =
			{ k = "j", id = id, n = name, p = power, s = season or ArenaSeason.seasonOf(clock()), at = clock() }
		if not validJoin(item) then
			say("refused a malformed join")
			return false
		end
		return push(item, "the join of " .. id)
	end

	-- The season's ladder, read at most every maxAge seconds (a missing one is a fresh ladder of bots, not written). Treat
	-- it as read-only. On a failed read: the copy held before (or nil) and why.
	function store.readLadder(season: number, maxAge: number): (any, string?)
		local now = clock()
		local held = ladders[season]
		if held and now - held.at < maxAge then
			return held.doc, nil
		end
		local key = ArenaStore.ladderKey(season)
		local ok, value = pcall(function(): any
			return deps.data:GetAsync(key)
		end)
		if not ok then
			say("could not read " .. key .. ": " .. tostring(value))
			return if held then held.doc else nil, tostring(value)
		end
		local doc = value
		if doc == nil then
			doc = ArenaLadder.new(season)
		else
			local usable, why = usableDoc(doc, season)
			if not usable then
				say(key .. " is " .. tostring(why) .. ", kept as it is")
				return if held then held.doc else nil, why
			end
		end
		ladders[season] = { doc = doc, at = now }
		return doc, nil
	end

	function store.isLeader(): boolean
		return leader
	end

	-- One UpdateAsync of one season's ladder with this tick's items for it, in order. Returns whether it succeeded.
	local function writeSeason(season: number, items: { any }, now: number, info: TickInfo): boolean
		local key = ArenaStore.ladderKey(season)
		local finalAt = ArenaSeason.finalAt(season)
		local counts = { applied = 0, dup = 0, void = 0, joined = 0 }
		local written: any = nil
		local refused: string? = nil
		local final = false
		-- (the transform may run more than once: it decides afresh each time and never yields)
		local ok, err = pcall(function()
			deps.data:UpdateAsync(key, function(old: any): any
				counts = { applied = 0, dup = 0, void = 0, joined = 0 }
				written, refused, final = nil, nil, false
				local doc = old
				if doc == nil and #items == 0 then
					-- (a season nobody played closes without a document: there is nothing to settle in it)
					final = true
					return nil
				elseif doc == nil then
					doc = ArenaLadder.new(season)
				else
					local usable, why = usableDoc(doc, season)
					if not usable then
						refused = why
						return nil
					end
				end
				local changed = false
				for _, item in items do
					if item.k == "m" then
						-- a result that reaches the leader after the season closed is void
						if not doc.final and item.at >= finalAt then
							doc.final, changed = true, true
						end
						local status: string = ArenaLadder.apply(doc, item.r)
						local tally: any = counts
						tally[status] += 1
						changed = changed or status == "applied"
					elseif not doc.final then
						local meta = doc.players[item.id]
						if not meta or meta.n ~= item.n or meta.p ~= item.p then
							ArenaLadder.join(doc, item.id, item.n, item.p)
							counts.joined += 1
							changed = true
						end
					end
				end
				if not doc.final and now >= finalAt then
					doc.final, changed = true, true
				end
				final = doc.final == true
				if not changed then
					return nil
				end
				written = doc
				return doc
			end)
		end)
		if not ok then
			say("could not write " .. key .. " (the items come back): " .. tostring(err))
			return false
		end
		if refused then
			say("WARNING: " .. key .. " is " .. refused .. ", left alone; its items wait in the queue")
			return false
		end
		info.applied += counts.applied
		info.dup += counts.dup
		info.void += counts.void
		info.joined += counts.joined
		if final then
			finalKnown[season] = true
		end
		if written then
			local size = count(key, written)
			info.writes += 1
			info.bytes += size
			ladders[season] = { doc = written, at = now }
			if size > A.WarnDocBytes then
				say(string.format("WARNING: %s is %d bytes, past %d", key, size, A.WarnDocBytes))
			end
			say(
				string.format(
					"%s written: %d applied, %d dup, %d void, %d joined, %d bytes%s",
					key,
					counts.applied,
					counts.dup,
					counts.void,
					counts.joined,
					size,
					if written.final then ", final" else ""
				)
			)
		end
		return true
	end

	-- Takes or renews the lease; the leader then drains the queue into the ladders (at most once a write budget allows),
	-- closes the season before this one at its finalAt, and removes what it read only after every write succeeded.
	function store.leaderTick(now: number): TickInfo
		local info: TickInfo = {
			leader = false,
			read = 0,
			applied = 0,
			dup = 0,
			void = 0,
			joined = 0,
			bad = 0,
			writes = 0,
			bytes = 0,
			ok = true,
		}
		local mine = false
		local carried = 0
		local ok, err = pcall(function()
			deps.lease:UpdateAsync(A.LeaseKey, function(old: any): any
				mine, carried = false, 0
				if type(old) == "table" and old.id ~= serverId and isNum(old.untilAt) and old.untilAt > now then
					return nil
				end
				if type(old) == "table" and isNum(old.next) then
					carried = old.next
				end
				mine = true
				return { id = serverId, untilAt = now + A.LeaseSeconds, next = math.max(nextWriteAt, carried) }
			end, A.LeaseSeconds)
		end)
		if not ok then
			say("could not renew the leader lease: " .. tostring(err))
			mine = false
		end
		if mine ~= leader then
			leader = mine
			say(
				if mine
					then "server " .. serverId .. " leads the ladder"
					else "server " .. serverId .. " no longer leads"
			)
		end
		info.leader = mine
		if not mine then
			return info
		end
		nextWriteAt = math.max(nextWriteAt, carried)
		if now < nextWriteAt then
			return info
		end

		local items: { any } = {}
		local readIds: { string } = {}
		for _ = 1, A.ReadsPerTick do
			local readOk, got, readId = pcall(function(): (any, any)
				return deps.queue:ReadAsync(A.ReadBatch, false, 0)
			end)
			if not readOk then
				say("could not read the results queue: " .. tostring(got))
				break
			end
			if type(got) ~= "table" or #got == 0 then
				break
			end
			for _, value in got do
				table.insert(items, value)
			end
			if type(readId) == "string" then
				table.insert(readIds, readId)
			end
			if #got < A.ReadBatch then
				break
			end
		end
		info.read = #items

		local bySeason: { [number]: { any } } = {}
		local seasons: { number } = {}
		local function bucket(season: number): { any }
			local list = bySeason[season]
			if not list then
				list = {}
				bySeason[season] = list
				table.insert(seasons, season)
			end
			return list
		end
		for _, item in items do
			local season = seasonOfItem(item)
			if season then
				table.insert(bucket(season), item)
			else
				info.bad += 1
			end
		end
		if info.bad > 0 then
			say(tostring(info.bad) .. " malformed queue item(s) dropped")
		end
		-- the season before this one closes at its finalAt, items or not
		local previous = ArenaSeason.previous(ArenaSeason.seasonOf(now))
		if now >= ArenaSeason.finalAt(previous) and not finalKnown[previous] then
			bucket(previous)
		end
		table.sort(seasons)

		for _, season in seasons do
			if not writeSeason(season, bySeason[season], now, info) then
				info.ok = false
			end
		end
		if info.ok then
			for _, readId in readIds do
				local removed, removeErr = pcall(function()
					deps.queue:RemoveAsync(readId)
				end)
				if not removed then
					-- (they come back and are read as "dup")
					say("could not remove read items: " .. tostring(removeErr))
				end
			end
		else
			-- what was read comes back after the invisibility window, in its order: read nothing new before then
			nextWriteAt = math.max(nextWriteAt, now + A.InvisibleSeconds)
		end
		if info.writes > 0 then
			-- the write budget: never more than WriteBytesPerMinute of ladder a minute (a document over a quarter of it
			-- is written less often than every tick), never one key twice within MinWriteSeconds
			nextWriteAt =
				math.max(nextWriteAt, now + math.max(A.MinWriteSeconds, 60 * info.bytes / A.WriteBytesPerMinute))
		end
		return info
	end

	function store.writeSnapshot(userId: number, snap: any): boolean
		local key = "Def_" .. tostring(userId)
		local ok, err = pcall(function()
			deps.data:SetAsync(key, snap, { userId })
		end)
		if not ok then
			say("could not write " .. key .. ": " .. tostring(err))
			return false
		end
		count(key, snap)
		snapshots[userId] = { value = snap, at = clock() }
		return true
	end

	-- A player's defence team, read at most every maxAge seconds; nil when there is none (or it cannot be read).
	function store.readSnapshot(userId: number, maxAge: number): any
		local now = clock()
		local held = snapshots[userId]
		if held and now - held.at < maxAge then
			return held.value
		end
		local key = "Def_" .. tostring(userId)
		local ok, value = pcall(function(): any
			return deps.data:GetAsync(key)
		end)
		if not ok then
			say("could not read " .. key .. ": " .. tostring(value))
			return if held then held.value else nil
		end
		snapshots[userId] = { value = value, at = now }
		return value
	end

	function store.appendLog(userId: number, entry: any): boolean
		local key = "Log_" .. tostring(userId)
		local written: any = nil
		local ok, err = pcall(function()
			deps.data:UpdateAsync(key, function(old: any): any
				local list = {}
				if type(old) == "table" then
					for _, e in old do
						table.insert(list, e)
					end
				end
				table.insert(list, entry)
				while #list > A.LogKeep do
					table.remove(list, 1)
				end
				written = list
				return list
			end)
		end)
		if not ok then
			say("could not write " .. key .. ": " .. tostring(err))
			return false
		end
		count(key, written)
		return true
	end

	function store.readLog(userId: number): { any }?
		local key = "Log_" .. tostring(userId)
		local ok, value = pcall(function(): any
			return deps.data:GetAsync(key)
		end)
		if not ok then
			say("could not read " .. key .. ": " .. tostring(value))
			return nil
		end
		return if type(value) == "table" then value else {}
	end

	return store
end

-- The stores of a live server, or memory ones in a Studio play test (unless Config.Arena.StudioUsesRealStore), an
-- unpublished place or when the real ones cannot be opened: never the real stores from Studio. Roblox only.
function ArenaStore.open(clock: () -> number, log: ((message: string) -> ())?): Store
	local RunService = game:GetService("RunService")
	local data: any, memory: any = nil, nil
	if RunService:IsStudio() and not A.StudioUsesRealStore then
		print(Config.LogPrefix, "arena: Studio test, the ladder is kept in memory and nothing is saved")
	elseif game.PlaceId == 0 then
		warn(Config.LogPrefix, "arena: unpublished place, the ladder is kept in memory")
	else
		local ok, d, m = pcall(function(): (any, any)
			return game:GetService("DataStoreService"):GetDataStore(A.StoreName), game:GetService("MemoryStoreService")
		end)
		if ok then
			data, memory = d, m
		else
			warn(Config.LogPrefix, "arena: the stores could not be opened, the ladder is kept in memory:", d)
		end
	end
	if data == nil then
		data, memory = ArenaMemory.dataStore(), ArenaMemory.new(clock)
	end
	local queue = memory:GetQueue(A.QueueName, A.InvisibleSeconds)
	local lease = memory:GetHashMap(A.LeaseMapName)
	return ArenaStore.new({
		data = data,
		queue = queue,
		lease = lease,
		serverId = if game.JobId ~= "" then game.JobId else "studio",
		clock = clock,
		log = log,
	})
end

return ArenaStore
