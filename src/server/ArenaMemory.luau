--!strict
-- An in-memory MemoryStoreService for the Arena: a Studio play test, an unpublished place and the Lune tests use it, never
-- the real one. GetQueue / GetHashMap give objects with the same calls as Roblox's MemoryStoreQueue and MemoryStoreHashMap
-- (AddAsync, ReadAsync, RemoveAsync; UpdateAsync, GetAsync, SetAsync, RemoveAsync), so the real ones can be passed where
-- these are. Values are copied in and out (as the JSON round trip would). Several "servers" share one by holding the same
-- object; the same name gives the same queue or map. The clock is injected; test switches on each queue and map:
--   queue.failNext(n)   the next n calls throw
--   queue.dropNext(n)   the next n AddAsync calls "succeed" and lose the item (a message lost on the way)
--   map.failNext(n)
local ArenaMemory = {}

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		assert(type(v) ~= "function", "a MemoryStore cannot store functions")
		out[copy(k)] = copy(v)
	end
	return out
end

type Item = { value: any, expiresAt: number, invisibleUntil: number, readId: string? }

local function newQueue(clock: () -> number, invisibleSeconds: number): any
	local items: { Item } = {}
	local reads = 0
	local queue: any = { failures = 0, drops = 0, failMessage = "MemoryStore request failed (fake)" }

	local function maybeFail()
		if queue.failures > 0 then
			queue.failures -= 1
			error(queue.failMessage)
		end
	end

	local function purge(now: number)
		for i = #items, 1, -1 do
			if items[i].expiresAt <= now then
				table.remove(items, i)
			end
		end
	end

	function queue.failNext(n: number)
		queue.failures = n
	end

	function queue.dropNext(n: number)
		queue.drops = n
	end

	-- How many items it holds, visible or not.
	function queue.size(): number
		purge(clock())
		return #items
	end

	function queue.AddAsync(_self: any, value: any, expiration: number, _priority: number?)
		maybeFail()
		if queue.drops > 0 then
			queue.drops -= 1
			return
		end
		table.insert(items, { value = copy(value), expiresAt = clock() + expiration, invisibleUntil = 0 })
	end

	-- Up to `count` visible items, oldest first; they turn invisible for the queue's invisibility window under one read id.
	-- (waitTimeout is not waited for: the fake answers at once)
	function queue.ReadAsync(_self: any, count: number, allOrNothing: boolean, _waitTimeout: number): (any, any)
		maybeFail()
		local now = clock()
		purge(now)
		local picked: { Item } = {}
		for _, item in items do
			if #picked >= count then
				break
			end
			if item.invisibleUntil <= now then
				table.insert(picked, item)
			end
		end
		if #picked == 0 or (allOrNothing and #picked < count) then
			return {}, nil
		end
		reads += 1
		local readId = "read" .. reads
		local values = {}
		for _, item in picked do
			item.invisibleUntil = now + invisibleSeconds
			item.readId = readId
			table.insert(values, copy(item.value))
		end
		return values, readId
	end

	-- Removes the items of a read that are still invisible under it (an item that came back and was read again carries
	-- the newer read's id).
	function queue.RemoveAsync(_self: any, readId: string)
		maybeFail()
		local now = clock()
		for i = #items, 1, -1 do
			local item = items[i]
			if item.readId == readId and item.invisibleUntil > now then
				table.remove(items, i)
			end
		end
	end

	return queue
end

type Entry = { value: any, expiresAt: number }

local function newHashMap(clock: () -> number): any
	local entries: { [string]: Entry } = {}
	local map: any = { failures = 0, failMessage = "MemoryStore request failed (fake)" }

	local function maybeFail()
		if map.failures > 0 then
			map.failures -= 1
			error(map.failMessage)
		end
	end

	local function current(key: string): any
		local entry = entries[key]
		if entry and entry.expiresAt <= clock() then
			entries[key] = nil
			return nil
		end
		return if entry then copy(entry.value) else nil
	end

	function map.failNext(n: number)
		map.failures = n
	end

	function map.GetAsync(_self: any, key: string): any
		maybeFail()
		return current(key)
	end

	function map.SetAsync(_self: any, key: string, value: any, expiration: number): boolean
		maybeFail()
		entries[key] = { value = copy(value), expiresAt = clock() + expiration }
		return true
	end

	-- The transform sees the live value (nil when missing or expired); nil from it cancels the write (and is returned).
	function map.UpdateAsync(_self: any, key: string, transform: (any) -> any, expiration: number): any
		maybeFail()
		local nextValue = transform(current(key))
		if nextValue == nil then
			return nil
		end
		entries[key] = { value = copy(nextValue), expiresAt = clock() + expiration }
		return copy(nextValue)
	end

	function map.RemoveAsync(_self: any, key: string)
		maybeFail()
		entries[key] = nil
	end

	return map
end

-- A memory "MemoryStoreService" on the given clock (seconds).
function ArenaMemory.new(clock: () -> number): any
	local queues: { [string]: any } = {}
	local maps: { [string]: any } = {}
	local service: any = {}

	function service.GetQueue(_self: any, name: string, invisibilityTimeout: number?): any
		if not queues[name] then
			queues[name] = newQueue(clock, invisibilityTimeout or 30)
		end
		return queues[name]
	end

	function service.GetHashMap(_self: any, name: string): any
		if not maps[name] then
			maps[name] = newHashMap(clock)
		end
		return maps[name]
	end

	return service
end

-- A memory DataStore (GetAsync / SetAsync / UpdateAsync, values copied, nil from a transform cancels) for a Studio play
-- test or an unpublished place: the Arena's ladder then holds this server's players only, and nothing is saved.
function ArenaMemory.dataStore(): any
	local values: { [string]: any } = {}
	local store: any = {}
	function store.GetAsync(_self: any, key: string): any
		return copy(values[key])
	end
	function store.SetAsync(_self: any, key: string, value: any, _userIds: any)
		values[key] = copy(value)
	end
	function store.UpdateAsync(_self: any, key: string, transform: (any, any) -> any): any
		local nextValue = transform(copy(values[key]), nil)
		if nextValue == nil then
			return copy(values[key])
		end
		values[key] = copy(nextValue)
		return copy(nextValue)
	end
	return store
end

return ArenaMemory
