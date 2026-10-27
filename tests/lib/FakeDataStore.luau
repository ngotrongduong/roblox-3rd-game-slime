-- An in-memory DataStore for the Lune tests, with Roblox's GetAsync / SetAsync / UpdateAsync
-- semantics: values are copied in and out (as the JSON round trip would), and an UpdateAsync
-- transform that returns nil cancels the write. Two fakes made on the same backing act as two
-- servers sharing one DataStore. Failures can be injected per fake.
--   local backing = Fake.newBacking()
--   local serverA, serverB = Fake.new(backing), Fake.new(backing)
--   serverA.failNext(2)            -- the next two calls throw
local Fake = {}

export type Backing = { values: { [string]: any }, writes: number }

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		assert(type(v) ~= "function", "a DataStore cannot store functions")
		out[copy(k)] = copy(v)
	end
	return out
end

function Fake.newBacking(): Backing
	return { values = {}, writes = 0 }
end

function Fake.new(backing: Backing?)
	local shared = backing or Fake.newBacking()
	local store = {
		backing = shared,
		calls = 0,
		writes = 0,
		failures = 0,
		failMessage = "503: DataStore request was rejected (fake)",
	}

	local function maybeFail()
		store.calls += 1
		if store.failures > 0 then
			store.failures -= 1
			error(store.failMessage)
		end
	end

	-- The next n calls on this fake throw.
	function store.failNext(n: number, message: string?)
		store.failures = n
		store.failMessage = message or store.failMessage
	end

	-- What the shared table holds now (a copy).
	function store.peek(key: string): any
		return copy(shared.values[key])
	end

	-- Puts a value straight into the shared table (a save from "elsewhere").
	function store.put(key: string, value: any)
		shared.values[key] = copy(value)
	end

	function store.GetAsync(_self: any, key: string): any
		maybeFail()
		return copy(shared.values[key])
	end

	function store.SetAsync(_self: any, key: string, value: any)
		maybeFail()
		shared.values[key] = copy(value)
		shared.writes += 1
		store.writes += 1
	end

	function store.UpdateAsync(_self: any, key: string, transform: (any, any) -> ...any): any
		maybeFail()
		local current = copy(shared.values[key])
		local nextValue = transform(current, { Version = "fake" })
		if nextValue == nil then
			return current
		end
		shared.values[key] = copy(nextValue)
		shared.writes += 1
		store.writes += 1
		return copy(nextValue)
	end

	return store
end

return Fake
